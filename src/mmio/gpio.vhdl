library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio_mmio is
	port(
		a : in std_logic_vector(7 downto 0);
		d : in std_logic_vector(7 downto 0);
		q : out std_logic_vector(7 downto 0);

		gpio_signals_out : out std_logic_vector(28 downto 0);
		gpio_signals_in  : in std_logic_vector(9 downto 0);

		video_mode        : out std_logic;
		video_color       : out std_logic_vector(11 downto 0);
		video_color_index : in std_logic_vector(3 downto 0);

		w   : in std_logic;
		clk : in std_logic);
end entity;

architecture gpio_mmio of gpio_mmio is
	signal leds_qh : std_logic_vector(7 downto 0);
	signal leds_ql : std_logic_vector(7 downto 0);
	signal leds_wh : std_logic;
	signal leds_wl : std_logic;

	signal uart_clk_selector_q : std_logic_vector(3 downto 0) := x"0";
	signal uart_clk_selector_w : std_logic;

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

	signal video_mode_q : std_logic;
	signal video_mode_w : std_logic;
	type video_palette_type is array(15 downto 0) of std_logic_vector(11 downto 0);
	-- Uses the default EGA palette
	signal video_palette : video_palette_type := (x"FFF", x"F5F", x"5FF", x"55F", x"FF5", x"F55", x"5F5", x"555", x"AAA", x"50A", x"0AA", x"00A", x"AA0", x"A00", x"0A0", x"000");

	signal video_palette_q      : std_logic_vector(7 downto 0);
	signal video_palette_q_full : std_logic_vector(11 downto 0);
	signal video_palette_d      : std_logic_vector(11 downto 0);
	signal video_palette_a      : std_logic_vector(3 downto 0);
	signal video_palette_w      : std_logic;
begin
	with a select
		q <= leds_qh                    when "00000000",
		     leds_ql                    when "00000001",
		     (others => uart_tx_status) when "10000000",
		     uart_rx_index_q            when "10000001",
		     x"0" & uart_clk_selector_q when "10000010",
		     uart_rx_buffer(0)          when "11000000",
		     uart_rx_buffer(1)          when "11000001",
		     uart_rx_buffer(2)          when "11000010",
		     uart_rx_buffer(3)          when "11000011",
		     uart_rx_buffer(4)          when "11000100",
		     uart_rx_buffer(5)          when "11000101",
		     uart_rx_buffer(6)          when "11000110",
		     uart_rx_buffer(7)          when "11000111",
		     (others => video_mode_q)   when "11100000",
		     video_palette_q            when others;

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

	-- UART clock
	process(clk, uart_clk_selector_w) begin
		if(rising_edge(clk) and uart_clk_selector_w = '1') then
			uart_clk_selector_q <= d(3 downto 0);
		end if;
	end process;
	gpio_signals_out(28 downto 25) <= uart_clk_selector_q;
	uart_clk_selector_w <= w when (a = "10000010") else '0';

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

	-- Video Mode
	process(clk, video_mode_w) begin
		if(rising_edge(clk) and video_mode_w = '1') then
			video_mode_q <= d(0);
		end if;
	end process;
	video_mode <= video_mode_q;
	video_mode_w <= w when (a = "11100000") else '0';

	-- Video Palette
	process(clk, video_palette_w) begin
		if(rising_edge(clk) and video_palette_w = '1') then
			video_palette(to_integer(unsigned(video_palette_a))) <= video_palette_d;
		end if;
	end process;

	video_color <= video_palette(to_integer(unsigned(video_color_index)));
	video_palette_a <= a(4 downto 1);
	video_palette_q_full <= video_palette(to_integer(unsigned(video_palette_a)));

	with a(0) select
		video_palette_q <= x"0" & video_palette_q_full(11 downto 8) when '0',
					  video_palette_q_full(7 downto 0)  when others;

	with a(0) select
		video_palette_d <= d(3 downto 0) & video_palette_q_full(7 downto 0) when '0',
				   video_palette_q_full(11 downto 8) & d            when others;

	video_palette_w <= w when (a(7 downto 5) = "101") else '0';
end architecture;
