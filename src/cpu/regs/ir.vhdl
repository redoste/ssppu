library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ir is
	port(
		d  : in std_logic_vector(7 downto 0);
		ql : out std_logic_vector(7 downto 0);
		qh : out std_logic_vector(7 downto 0);

		el  : in std_logic;
		eh  : in std_logic;
		clk : in std_logic);
end entity;

architecture ir of ir is
begin
	process(clk, el, eh) begin
		if(rising_edge(clk) and el = '1') then
			ql <= d;
		end if;
		if(rising_edge(clk) and eh = '1') then
			qh <= d;
		end if;
	end process;
end architecture;
