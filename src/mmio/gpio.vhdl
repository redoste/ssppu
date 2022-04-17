library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio_mmio is
	port(
		a : in std_logic_vector(7 downto 0);
		d : in std_logic_vector(7 downto 0);
		q : out std_logic_vector(7 downto 0);

		gpio_signals_out : out std_logic_vector(24 downto 0);
		gpio_signals_in  : in std_logic_vector(9 downto 0);

		w   : in std_logic;
		clk : in std_logic);
end entity;

architecture gpio_mmio of gpio_mmio is
	signal leds_qh : std_logic_vector(7 downto 0);
	signal leds_ql : std_logic_vector(7 downto 0);
	signal leds_wh : std_logic;
	signal leds_wl : std_logic;

	signal uart_tx_ready  : std_logic;
	signal uart_tx_status : std_logic;

	signal uart_tx_data_buffer_q  : std_logic_vector(7 downto 0);
	signal uart_tx_data_buffer_w  : std_logic;
	signal uart_tx_data_waiting_q : std_logic := '0';

	signal uart_rx_changed_byte : std_logic;

	signal uart_rx_last_changed_byte_q : std_logic := '0';
	signal uart_rx_changed             : std_logic;
	signal uart_rx_index_q             : std_logic_vector(7 downto 0) := (others => '0');
	signal uart_rx_index_d             : std_logic_vector(7 downto 0);
	signal uart_rx_index_z             : std_logic;

	type uart_rx_buffer_type is array(7 downto 0) of std_logic_vector(7 downto 0);
	signal uart_rx_buffer : uart_rx_buffer_type := (others => (others => '0'));
begin
	with a select
		q <= leds_qh                    when "00000000",
		     leds_ql                    when "00000001",
		     (others => uart_tx_status) when "10000000",
		     uart_rx_index_q            when "10000001",
		     uart_rx_buffer(0)          when "11000000",
		     uart_rx_buffer(1)          when "11000001",
		     uart_rx_buffer(2)          when "11000010",
		     uart_rx_buffer(3)          when "11000011",
		     uart_rx_buffer(4)          when "11000100",
		     uart_rx_buffer(5)          when "11000101",
		     uart_rx_buffer(6)          when "11000110",
		     uart_rx_buffer(7)          when "11000111",
		     (others => '0')            when others;

	-- LEDS
	process(clk, leds_wh, leds_wl) begin
		if(rising_edge(clk) and leds_wh = '1') then
			leds_qh <= d;
		end if;
		if(rising_edge(clk) and leds_wl = '1') then
			leds_ql <= d;
		end if;
	end process;
	with a select
		leds_wh <= w  when "00000000",
			  '0' when others;
	with a select
		leds_wl <= w  when "00000001",
			  '0' when others;
	gpio_signals_out(15 downto 0) <= leds_qh & leds_ql;

	-- UART TX
	process(clk, uart_tx_data_buffer_w) begin
		if(rising_edge(clk) and uart_tx_data_buffer_w = '1') then
			uart_tx_data_buffer_q <= d;
		end if;
		if(rising_edge(clk)) then
			uart_tx_data_waiting_q <= (uart_tx_data_waiting_q and uart_tx_ready) or uart_tx_data_buffer_w;
		end if;
	end process;
	with a select
		uart_tx_data_buffer_w <= w and uart_tx_ready when "10000000",
					 '0'                 when others;
	uart_tx_status <= uart_tx_ready and not uart_tx_data_waiting_q;
	uart_tx_ready <= gpio_signals_in(0);
	gpio_signals_out(23 downto 16) <= uart_tx_data_buffer_q; -- UART TX data
	gpio_signals_out(24) <= uart_tx_ready and uart_tx_data_waiting_q; -- UART TX go


	-- UART RX
	process(clk, uart_rx_changed, uart_rx_index_z) begin
		if(rising_edge(clk) and uart_rx_changed = '1') then
			uart_rx_last_changed_byte_q <= uart_rx_changed_byte;
			uart_rx_buffer(to_integer(unsigned(uart_rx_index_q(2 downto 0)))) <= gpio_signals_in(9 downto 2); -- UART RX data
		end if;
		if(rising_edge(clk) and (uart_rx_index_z or uart_rx_changed) = '1') then
			uart_rx_index_q <= uart_rx_index_d;
		end if;
	end process;
	with a select
		uart_rx_index_z <= w   when "10000001",
				   '0' when others;
	with uart_rx_index_z select
		uart_rx_index_d <= std_logic_vector(unsigned(uart_rx_index_q) + 1) when '0',
				   (others => '0')                                 when others;
	uart_rx_changed <= uart_rx_last_changed_byte_q xor uart_rx_changed_byte;
	uart_rx_changed_byte <= gpio_signals_in(1);
end architecture;
