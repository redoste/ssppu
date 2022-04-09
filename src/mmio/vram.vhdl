library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vram is
	port(
		a : in std_logic_vector(13 downto 0);
		d : in std_logic_vector(7 downto 0);
		q : out std_logic_vector(7 downto 0);

		pixel_coord : in  std_logic_vector(13 downto 0);
		pixel_color : out std_logic_vector(11 downto 0);

		w   : in std_logic;
		clk : in std_logic);
end entity;

architecture vram of vram is
	type vram_type is array(16#3fff# downto 0) of std_logic_vector(7 downto 0);
	signal vram_data : vram_type := (others => (others => '0'));

	signal selected_byte : std_logic_vector(7 downto 0);
	signal indexed_color : std_logic_vector(3 downto 0);
begin
	q <= vram_data(to_integer(unsigned(a)));
	process(clk) begin
		if(rising_edge(clk) and w = '1') then
			vram_data(to_integer(unsigned(a))) <= d;
		end if;
	end process;

	selected_byte <= vram_data(to_integer(unsigned(pixel_coord(13 downto 1))));
	with pixel_coord(0) select
		indexed_color <= selected_byte(3 downto 0) when '0',
				 selected_byte(7 downto 4) when others;

	-- Uses the default EGA palette
	-- TODO : customizable palette
	with indexed_color select
			      -- GBR
		pixel_color <= x"000" when x"0",
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
end architecture;
