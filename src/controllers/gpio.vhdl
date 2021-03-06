library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio_controller is
	port(
		gpio_signals_out : in std_logic_vector(28 downto 0);
		gpio_signals_in  : out std_logic_vector(9 downto 0);

		leds    : out std_logic_vector(15 downto 0);
		uart_tx : out std_logic;
		uart_rx : in std_logic;

		board_clk : in std_logic;
		cpu_clk   : in std_logic);
end entity;

architecture gpio_controller of gpio_controller is
	signal uart_tx_data : std_logic_vector(7 downto 0);
	signal uart_tx_go   : std_logic;

	signal uart_tx_shift_reg_q : std_logic_vector(9 downto 0) := (others => '1');
	signal uart_tx_shift_reg_d : std_logic_vector(9 downto 0);
	signal uart_tx_ready_reg_q : std_logic_vector(9 downto 0) := (others => '1');
	signal uart_tx_ready_reg_d : std_logic_vector(9 downto 0);

	signal uart_rx_shift_reg_q  : std_logic_vector(9 downto 0) := (others => '1');
	signal uart_rx_shift_reg_d  : std_logic_vector(9 downto 0);
	signal uart_rx_output       : std_logic_vector(7 downto 0);
	signal uart_rx_changed_byte : std_logic := '0';
	signal uart_rx_valid_byte   : std_logic;

	signal uart_clk_selector          : std_logic_vector(3 downto 0);
	signal uart_clk_counter_max       : integer range 434 to 5208;
	signal uart_tx_clk                : std_logic := '0';
	signal uart_tx_clk_counter        : integer := 0;
	signal uart_rx_clk                : std_logic := '0';
	signal uart_rx_clk_d              : std_logic;
	signal uart_rx_clk_counter        : integer := 0;
	signal uart_rx_clk_force          : std_logic;
	signal uart_rx_clk_force_last_bit : std_logic := '1';
begin
	-- LEDS
	leds <= gpio_signals_out(15 downto 0);

	-- UART clocks
	process(board_clk) begin
		if(rising_edge(board_clk)) then
			-- TX clock
			uart_tx_clk_counter <= uart_tx_clk_counter + 1;
			if(uart_tx_clk_counter >= uart_clk_counter_max - 1) then
				uart_tx_clk <= not uart_tx_clk;
				uart_tx_clk_counter <= 0;
			end if;
			-- RX clock
			-- It will intentionally drift to make sure that the rising edge is at the middle of a bit
			-- This will reduce transmission errors that might occur if the line isn't set completely yet
			uart_rx_clk_counter <= uart_rx_clk_counter + 1;
			if(uart_rx_clk_counter >= uart_clk_counter_max - 1 or uart_rx_clk_force = '1') then
				uart_rx_clk <= uart_rx_clk_d;
				uart_rx_clk_counter <= 0;
			end if;
			uart_rx_clk_force_last_bit <= uart_rx;
		end if;
	end process;
	uart_rx_clk_force <= uart_rx_clk_force_last_bit xor uart_rx;
	with uart_rx_clk_force select
		uart_rx_clk_d <= not uart_rx_clk when '0',
				 '0'             when others;
	uart_clk_selector <= gpio_signals_out(28 downto 25);
	with uart_clk_selector select
		uart_clk_counter_max <= 2604 when x"1",   -- 100MHz / (2604 * 2) ~  19201Hz :  19200bps : 0.01%
					1302 when x"2",   -- 100MHz / (1302 * 2) ~  38402Hz :  38400bps : 0.01%
					868  when x"3",   -- 100MHz / (868  * 2) ~  57604Hz :  57600bps : 0.01%
					434  when x"4",   -- 100MHz / (434  * 2) ~ 115207Hz : 115200bps : 0.01%
					5208 when others; -- 100MHz / (5208 * 2) ~   9601Hz :   9600bps : 0.01%

	-- UART TX
	uart_tx_data <= gpio_signals_out(23 downto 16);
	uart_tx_go <= gpio_signals_out(24);
	process(uart_tx_clk) begin
		if(rising_edge(uart_tx_clk)) then
			uart_tx_shift_reg_q <= uart_tx_shift_reg_d;
			uart_tx_ready_reg_q <= uart_tx_ready_reg_d;
		end if;
	end process;
	with uart_tx_go select
		uart_tx_shift_reg_d <= '1' & uart_tx_shift_reg_q(9 downto 1) when '0',
				       '1' & uart_tx_data & '0'              when others;
	with uart_tx_go select
		uart_tx_ready_reg_d <= '1' & uart_tx_ready_reg_q(9 downto 1) when '0',
				       (others => '0')                       when others;
	uart_tx <= uart_tx_shift_reg_q(0);
	gpio_signals_in(0) <= uart_tx_ready_reg_q(0);

	-- UART RX
	process(uart_rx_clk, uart_rx_valid_byte) begin
		if(rising_edge(uart_rx_clk)) then
			uart_rx_shift_reg_q <= uart_rx_shift_reg_d;
		end if;
		if(rising_edge(uart_rx_clk) and uart_rx_valid_byte = '1') then
			uart_rx_output <= uart_rx_shift_reg_q(8 downto 1);
			uart_rx_changed_byte <= not uart_rx_changed_byte;
		end if;
	end process;
	-- detect one start bit and one stop bit with 8 data bits in between
	uart_rx_valid_byte <= not uart_rx_shift_reg_q(0) and uart_rx_shift_reg_q(9);
	with uart_rx_valid_byte select
		uart_rx_shift_reg_d <= uart_rx & uart_rx_shift_reg_q(9 downto 1) when '0',
				       uart_rx & "111111111"                     when others;
	gpio_signals_in(1) <= uart_rx_changed_byte;
	gpio_signals_in(9 downto 2) <= uart_rx_output;
end architecture;
