library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpr is
	port(
		d : in std_logic_vector(7 downto 0);
		q : out std_logic_vector(7 downto 0);

		e   : in std_logic;
		clk : in std_logic);
end entity;

architecture gpr of gpr is
begin
	process(clk) begin
		if(rising_edge(clk) and e = '1') then
			q <= d;
		end if;
	end process;
end architecture;
