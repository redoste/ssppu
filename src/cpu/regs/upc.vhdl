library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity upc is
	port(
		q : out std_logic_vector(3 downto 0);

		r   : in std_logic;
		clk : in std_logic);
end entity;

architecture upc of upc is
	signal q_internal : std_logic_vector(3 downto 0);
	signal d_internal : std_logic_vector(3 downto 0);

	signal d_inc      : std_logic_vector(3 downto 0);
begin
	process(clk) begin
		if(rising_edge(clk)) then
			q_internal <= d_internal;
		end if;
	end process;

	d_inc <= std_logic_vector(unsigned(q_internal) + 1);
	with r select
		d_internal <= "0000" when '1',
			      d_inc  when others;

	q <= q_internal;
end architecture;
