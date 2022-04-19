library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity board is
	port (
		clk : in std_logic;

		sw       : in std_logic_vector(15 downto 0);
		btn      : in std_logic_vector(4 downto 0);
		leds     : out std_logic_vector (15 downto 0);
		sseg_ca  : out std_logic_vector (7 downto 0);
		sseg_an  : out std_logic_vector (3 downto 0);
		uart_txd : out std_logic;
		uart_rxd : in std_logic;

		vga_red   : out std_logic_vector (3 downto 0);
		vga_blue  : out std_logic_vector (3 downto 0);
		vga_green : out std_logic_vector (3 downto 0);
		vga_vs    : out std_logic;
		vga_hs    : out std_logic;

		ps2_clk  : inout std_logic;
		ps2_data : inout std_logic);
end entity;

architecture board of board is
	component cpu is
		port(
			gpio_signals_out : out std_logic_vector(28 downto 0);
			gpio_signals_in  : in std_logic_vector(9 downto 0);
			pixel_coord      : in  std_logic_vector(13 downto 0);
			pixel_color      : out std_logic_vector(11 downto 0);

			r   : in std_logic;
			clk : in std_logic);
	end component;
	component gpio_controller is
		port(
			gpio_signals_out : in std_logic_vector(28 downto 0);
			gpio_signals_in  : out std_logic_vector(9 downto 0);

			leds    : out std_logic_vector(15 downto 0);
			uart_tx : out std_logic;
			uart_rx : in std_logic;

			board_clk : in std_logic;
			cpu_clk   : in std_logic);
	end component;
	component vga_controller is
		port(
			vga_red   : out std_logic_vector(3 downto 0);
			vga_blue  : out std_logic_vector(3 downto 0);
			vga_green : out std_logic_vector(3 downto 0);

			vga_vs : out std_logic;
			vga_hs : out std_logic;

			pixel_coord : out std_logic_vector(13 downto 0);
			pixel_color : in std_logic_vector(11 downto 0);

			clk : in std_logic);
	end component;

	signal r : std_logic := '1';

	signal gpio_signals_out : std_logic_vector(28 downto 0);
	signal gpio_signals_in  : std_logic_vector(9 downto 0);
	signal pixel_coord      : std_logic_vector(13 downto 0);
	signal pixel_color      : std_logic_vector(11 downto 0);

	constant CPU_CLK_COUNTER_MAX : integer := 5;     -- 100 MHz / (5 * 2) = 10 MHz
	signal cpu_clk               : std_logic := '0';
	signal cpu_clk_counter       : integer := 0;
begin
	lcpu: cpu port map (
		gpio_signals_out => gpio_signals_out,
		gpio_signals_in => gpio_signals_in,
		pixel_coord => pixel_coord,
		pixel_color => pixel_color,
		r => r,
		clk => cpu_clk
	);

	lgpio_controller: gpio_controller port map (
		gpio_signals_out => gpio_signals_out,
		gpio_signals_in => gpio_signals_in,
		leds => leds,
		uart_tx => uart_txd,
		uart_rx => uart_rxd,
		board_clk => clk,
		cpu_clk => cpu_clk
	);

	lvga_controller: vga_controller port map (
		vga_red => vga_red,
		vga_blue => vga_blue,
		vga_green => vga_green,
		vga_vs => vga_vs,
		vga_hs => vga_hs,
		pixel_coord => pixel_coord,
		pixel_color => pixel_color,
		clk => cpu_clk
	);

	-- reset the cpu for one cpu clock cycle at startup
	process(cpu_clk) begin
		if(rising_edge(cpu_clk)) then
			r <= '0';
		end if;
	end process;

	process(clk) begin
		if(rising_edge(clk)) then
			cpu_clk_counter <= cpu_clk_counter + 1;
			if(cpu_clk_counter = CPU_CLK_COUNTER_MAX - 1) then
				cpu_clk <= not cpu_clk;
				cpu_clk_counter <= 0;
			end if;
		end if;
	end process;
end architecture;
