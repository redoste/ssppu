library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wram is
	port(
		a : in std_logic_vector(14 downto 0);
		d : in std_logic_vector(7 downto 0);
		q : out std_logic_vector(7 downto 0);

		w   : in std_logic;
		clk : in std_logic);
end entity;

architecture wram of wram is
	type ram_type is array(16#7fff# downto 0) of std_logic_vector(7 downto 0);
	signal ram_data : ram_type := (others => (others => '0'));
begin
	q <= ram_data(to_integer(unsigned(a)));
	process(clk) begin
		if(rising_edge(clk) and w = '1') then
			ram_data(to_integer(unsigned(a))) <= d;
		end if;
	end process;
end architecture;
