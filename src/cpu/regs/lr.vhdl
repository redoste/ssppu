library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lr is
	port(
		d  : in std_logic_vector(15 downto 0);
		ql : out std_logic_vector(7 downto 0);
		qh : out std_logic_vector(7 downto 0);

		e   : in std_logic;
		clk : in std_logic);
end entity;

architecture lr of lr is
begin
	process(clk, e) begin
		if(rising_edge(clk) and e = '1') then
			qh <= d(15 downto 8);
			ql <= d(7 downto 0);
		end if;
	end process;
end architecture;
