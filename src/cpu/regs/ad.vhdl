library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ad is
	port(
		d : in std_logic_vector(7 downto 0);
		q : out std_logic_vector(15 downto 0);

		el  : in std_logic;
		eh  : in std_logic;
		clk : in std_logic);
end entity;

architecture ad of ad is
	signal qh_internal : std_logic_vector(7 downto 0);
	signal ql_internal : std_logic_vector(7 downto 0);
begin
	process(clk, el, eh) begin
		if(rising_edge(clk) and el = '1') then
			ql_internal <= d;
		end if;
		if(rising_edge(clk) and eh = '1') then
			qh_internal <= d;
		end if;
	end process;

	q <= qh_internal & ql_internal;
end architecture;
