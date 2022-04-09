library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_controller is
	port(
		vga_red   : out std_logic_vector(3 downto 0);
		vga_blue  : out std_logic_vector(3 downto 0);
		vga_green : out std_logic_vector(3 downto 0);

		vga_vs : out std_logic;
		vga_hs : out std_logic;

		pixel_coord : out std_logic_vector(13 downto 0);
		pixel_color : in std_logic_vector(11 downto 0);

		clk : in std_logic);
end entity;

architecture vga_controller of vga_controller is
	signal pixel_clk : std_logic := '0';

	signal pixel_col : integer := 0;
	signal pixel_row : integer := 0;

	signal pixel_x : std_logic_vector(6 downto 0);
	signal pixel_y : std_logic_vector(6 downto 0);

	signal vga_hs_b : boolean;
	signal vga_vs_b : boolean;
	signal visible  : boolean;
begin
	process(clk) begin
		if(rising_edge(clk)) then
			pixel_clk <= not pixel_clk;
		end if;
	end process;

	process(pixel_clk) begin
		if(rising_edge(pixel_clk)) then
			pixel_col <= pixel_col + 1;
			if(pixel_col = 160) then
				pixel_col <= 0;
				pixel_row <= pixel_row + 1;
			end if;
			if(pixel_row = 525) then
				pixel_row <= 0;
			end if;
		end if;
	end process;
	vga_hs_b <= pixel_col > 130 and pixel_col < 151;
	vga_hs <= '0' when vga_hs_b else '1';
	vga_vs_b <= pixel_row > 490 and pixel_row < 493;
	vga_vs <= '0' when vga_vs_b else '1';

	pixel_x <= std_logic_vector(to_unsigned(pixel_col, pixel_x'length));
	pixel_y <= std_logic_vector(to_unsigned(pixel_row / 5, pixel_y'length));

	pixel_coord <= pixel_y & pixel_x;

	visible <= pixel_col <= 128 and pixel_row <= 480;
	vga_red <= pixel_color(3 downto 0) when visible else "0000";
	vga_blue <= pixel_color(7 downto 4) when visible else "0000";
	vga_green <= pixel_color(11 downto 8) when visible else "0000";
end architecture;
