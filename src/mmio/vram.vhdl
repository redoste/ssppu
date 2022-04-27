library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vram is
	port(
		a : in std_logic_vector(13 downto 0);
		d : in std_logic_vector(7 downto 0);
		q : out std_logic_vector(7 downto 0);

		video_mode        : in  std_logic;
		pixel_coord       : in  std_logic_vector(13 downto 0);
		pixel_color_index : out std_logic_vector(3 downto 0);

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
	signal one_bit_indexed_color : std_logic_vector(3 downto 0);
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
		pixel_color_index <= four_bit_indexed_color when '0',
				     one_bit_indexed_color  when others;

	with pixel_coord(0) select
		four_bit_indexed_color <= selected_byte(3 downto 0) when '0',
					  selected_byte(7 downto 4) when others;

	one_bit_indexed_color <= (others => selected_byte(to_integer(unsigned(not pixel_coord(2 downto 0)))));
end architecture;
