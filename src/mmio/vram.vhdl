library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vram is
	port(
		a : in std_logic_vector(13 downto 0);
		d : in std_logic_vector(7 downto 0);
		q : out std_logic_vector(7 downto 0);

		video_mode  : in  std_logic;
		pixel_coord : in  std_logic_vector(13 downto 0);
		pixel_color : out std_logic_vector(11 downto 0);

		w   : in std_logic;
		clk : in std_logic);
end entity;

architecture vram of vram is
	type vram_type is array(16#3fff# downto 0) of std_logic_vector(7 downto 0);
	shared variable vram_data : vram_type := (others => (others => '0'));

	attribute ram_style : string;
	attribute ram_style of vram_data : variable is "block";

	signal byte_addr     : integer range 0 to 16#3fff#;
	signal selected_byte : std_logic_vector(7 downto 0);

	signal four_bit_indexed_color : std_logic_vector(3 downto 0);
	signal four_bit_real_color    : std_logic_vector(11 downto 0);

	signal one_bit_indexed_color : std_logic;
	signal one_bit_real_color    : std_logic_vector(11 downto 0);
begin
	process(clk, w) begin
		if(rising_edge(clk)) then
			selected_byte <= vram_data(byte_addr);
			q <= vram_data(to_integer(unsigned(a)));
			if(w = '1') then
				vram_data(to_integer(unsigned(a))) := d;
			end if;
		end if;
	end process;

	with video_mode select
		byte_addr <= to_integer(unsigned(pixel_coord(13 downto 1))) when '0',
			     to_integer(unsigned(pixel_coord(13 downto 3))) when others;
	with video_mode select
		pixel_color <= four_bit_real_color when '0',
			       one_bit_real_color  when others;

	with pixel_coord(0) select
		four_bit_indexed_color <= selected_byte(3 downto 0) when '0',
					  selected_byte(7 downto 4) when others;
	-- Uses the default EGA palette
	-- TODO : customizable palette
	with four_bit_indexed_color select
				      -- GBR
		four_bit_real_color <= x"000" when x"0",
				       x"0A0" when x"1",
				       x"A00" when x"2",
				       x"AA0" when x"3",
				       x"00A" when x"4",
				       x"0AA" when x"5",
				       x"50A" when x"6",
				       x"AAA" when x"7",
				       x"555" when x"8",
				       x"5F5" when x"9",
				       x"F55" when x"A",
				       x"FF5" when x"B",
				       x"55F" when x"C",
				       x"5FF" when x"D",
				       x"F5F" when x"E",
				       x"FFF" when x"F",
				       x"FFF" when others;

	one_bit_indexed_color <= selected_byte(to_integer(unsigned(not pixel_coord(2 downto 0))));
	one_bit_real_color <= x"FFF" when (one_bit_indexed_color = '1') else x"000";
end architecture;
