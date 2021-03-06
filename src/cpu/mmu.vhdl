library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mmu is
	port(
		a : in std_logic_vector(15 downto 0);
		d : in std_logic_vector(7 downto 0);
		q : out std_logic_vector(7 downto 0);

		reading_slow_ram : out std_logic;

		gpio_signals_out : out std_logic_vector(28 downto 0);
		gpio_signals_in  : in std_logic_vector(9 downto 0);
		pixel_coord      : in  std_logic_vector(13 downto 0);
		pixel_color      : out std_logic_vector(11 downto 0);

		w   : in std_logic;
		clk : in std_logic);
end entity;

architecture mmu of mmu is
	component wram is
		port(
			a : in std_logic_vector(14 downto 0);
			d : in std_logic_vector(7 downto 0);
			q : out std_logic_vector(7 downto 0);
			w   : in std_logic;

			dma_a : in std_logic_vector(14 downto 0);
			dma_d : in std_logic_vector(7 downto 0);
			dma_q : out std_logic_vector(7 downto 0);
			dma_w : in std_logic;

			clk : in std_logic);
	end component;
	component vram is
		port(
			a : in std_logic_vector(13 downto 0);
			d : in std_logic_vector(7 downto 0);
			q : out std_logic_vector(7 downto 0);

			video_mode        : in  std_logic;
			pixel_coord       : in  std_logic_vector(13 downto 0);
			pixel_color_index : out std_logic_vector(3 downto 0);

			w   : in std_logic;
			clk : in std_logic);
	end component;
	component rom is
		port(
			a : in std_logic_vector(11 downto 0);
			q : out std_logic_vector(7 downto 0));
	end component;
	component gpio_mmio is
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
	end component;
	component dma is
		port(
			a : in std_logic_vector(11 downto 0);
			d : in std_logic_vector(7 downto 0);
			q : out std_logic_vector(7 downto 0);
			w   : in std_logic;

			gpio_signals_in : in std_logic_vector(9 downto 0);

			dma_a : out std_logic_vector(14 downto 0);
			dma_d : out std_logic_vector(7 downto 0);
			dma_q : in std_logic_vector(7 downto 0);
			dma_w : out std_logic;

			clk : in std_logic);
	end component;

	signal bank : std_logic_vector(3 downto 0);

	signal vram_video_mode  : std_logic;
	signal vram_color_index : std_logic_vector(3 downto 0);

	signal vram_q : std_logic_vector(7 downto 0);
	signal dma_q  : std_logic_vector(7 downto 0);
	signal gpio_q : std_logic_vector(7 downto 0);
	signal rom_q  : std_logic_vector(7 downto 0);
	signal wram_q : std_logic_vector(7 downto 0);

	signal vram_w : std_logic;
	signal dma_w  : std_logic;
	signal gpio_w : std_logic;
	signal wram_w : std_logic;

	signal dma_wram_a : std_logic_vector(14 downto 0);
	signal dma_wram_d : std_logic_vector(7 downto 0);
	signal dma_wram_q : std_logic_vector(7 downto 0);
	signal dma_wram_w : std_logic;
begin
	lwram: wram port map (
		a => a(14 downto 0),
		d => d,
		q => wram_q,
		w => wram_w,
		dma_a => dma_wram_a,
		dma_d => dma_wram_d,
		dma_q => dma_wram_q,
		dma_w => dma_wram_w,
		clk => clk
	);
	lvram: vram port map (
		a => a(13 downto 0),
		d => d,
		q => vram_q,
		video_mode => vram_video_mode,
		pixel_coord => pixel_coord,
		pixel_color_index => vram_color_index,
		w => vram_w,
		clk => clk
	);
	lrom: rom port map (
		a => a(11 downto 0),
		q => rom_q
	);
	lgpio_mmio: gpio_mmio port map (
		a => a(7 downto 0),
		d => d,
		q => gpio_q,
		gpio_signals_out => gpio_signals_out,
		gpio_signals_in => gpio_signals_in,
		video_mode => vram_video_mode,
		video_color => pixel_color,
		video_color_index => vram_color_index,
		w => gpio_w,
		clk => clk
	);
	ldma: dma port map (
		a => a(11 downto 0),
		d => d,
		q => dma_q,
		w => dma_w,
		gpio_signals_in => gpio_signals_in,
		dma_a => dma_wram_a,
		dma_d => dma_wram_d,
		dma_q => dma_wram_q,
		dma_w => dma_wram_w,
		clk => clk
	);

	-- Memory Map
	-- -----------
	-- 0000 - 7FFF WRAM
	-- 8000 - BFFF VRAM
	-- C000 - CFFF DMA controller
	-- D000 - EFFF GPIO
	-- F000 - FFFF ROM
	bank <= a(15 downto 12);
	with bank select
		q <= vram_q when "1000",
		     vram_q when "1001",
		     vram_q when "1010",
		     vram_q when "1011",
		     dma_q  when "1100",
		     gpio_q when "1101",
		     gpio_q when "1110",
		     rom_q  when "1111",
		     wram_q when others;

	with bank select
		reading_slow_ram <= '1' when "1000",
				    '1' when "1001",
				    '1' when "1010",
				    '1' when "1011",
				    '0' when "1100",
				    '0' when "1101",
				    '0' when "1110",
				    '0' when "1111",
				    '1' when others;

	with bank(3) select
		wram_w <= w   when '0',
		          '0' when others;
	with bank(3 downto 2) select
		vram_w <= w   when "10",
		          '0' when others;
	with bank select
		dma_w  <= w   when "1100",
		          '0' when others;
	with bank select
		gpio_w <= w   when "1101",
		          w   when "1110",
		          '0' when others;
end architecture;
