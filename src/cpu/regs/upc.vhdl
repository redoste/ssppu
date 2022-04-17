library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity upc is
	port(
		q : out std_logic_vector(3 downto 0);

		slower : in std_logic;

		r   : in std_logic;
		clk : in std_logic);
end entity;

architecture upc of upc is
	signal q_internal : std_logic_vector(4 downto 0);
	signal d_internal : std_logic_vector(4 downto 0);

	signal d_inc      : std_logic_vector(4 downto 0);
	signal d_slow_inc : std_logic_vector(4 downto 0);
	signal d_s        : std_logic_vector(1 downto 0);
begin
	process(clk) begin
		if(rising_edge(clk)) then
			q_internal <= d_internal;
		end if;
	end process;

	d_inc <= std_logic_vector(unsigned(q_internal and "11110") + 2);
	d_slow_inc <= std_logic_vector(unsigned(q_internal) + 1);

	d_s <= r & slower;
	with d_s select
		d_internal <= "00000"    when "10",
			      "00000"    when "11",
			      d_slow_inc when "01",
			      d_inc      when others;

	q <= q_internal(4 downto 1);
end architecture;
