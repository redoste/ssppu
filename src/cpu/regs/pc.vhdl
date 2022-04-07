library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pc is
	port(
		d : in std_logic_vector(15 downto 0);
		q : out std_logic_vector(15 downto 0);

		r   : in std_logic;
		e   : in std_logic;
		inc : in std_logic;
		clk : in std_logic);
end entity;

architecture pc of pc is
	signal q_internal : std_logic_vector(15 downto 0);
	signal e_internal : std_logic;
	signal d_internal : std_logic_vector(15 downto 0);

	signal inputs : std_logic_vector(2 downto 0);
	signal d_inc  : std_logic_vector(15 downto 0);
begin
	process(clk) begin
		if(rising_edge(clk) and e_internal = '1') then
			q_internal <= d_internal;
		end if;
	end process;

	d_inc <= std_logic_vector(unsigned(q_internal) + 1);
	inputs <= r & e & inc;
	with inputs select
		d_internal <= d       when "010",
			      d_inc   when "001",
			      x"FFFC" when others;
	-- reset takes precedence
	e_internal <= (e xor inc) or r;

	q <= q_internal;
end architecture;
