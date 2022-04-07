library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
	port(
		a  : in std_logic_vector(7 downto 0);
		b  : in std_logic_vector(7 downto 0);
		op : in std_logic_vector(2 downto 0);

		o  : out std_logic_vector(7 downto 0);
		cf : out std_logic;
		zf : out std_logic);
end entity;

architecture alu of alu is
	signal o_add : std_logic_vector(8 downto 0);
	signal o_sub : std_logic_vector(8 downto 0);

	signal o_shl : std_logic_vector(7 downto 0);
	signal o_shr : std_logic_vector(7 downto 0);

	signal o_and : std_logic_vector(7 downto 0);
	signal o_or  : std_logic_vector(7 downto 0);
	signal o_xor : std_logic_vector(7 downto 0);
	signal o_not : std_logic_vector(7 downto 0);

	signal o_internal : std_logic_vector(7 downto 0);
begin
	-- VHDL magic to keep the carry bit
	o_add <= std_logic_vector(('0' & unsigned(a)) + unsigned(b));
	o_sub <= std_logic_vector(('0' & unsigned(a)) - unsigned(b));

	o_shl <= a(6 downto 0) & '0';
	o_shr <= '0' & a(7 downto 1);

	o_and <= a and b;
	o_or  <= a or  b;
	o_xor <= a xor b;
	o_not <= not a;

	with op select
		o_internal <= o_add(7 downto 0) when "000",
			      o_sub(7 downto 0) when "001",
			      o_shl             when "010",
			      o_shr             when "011",
			      o_and             when "100",
			      o_or              when "101",
			      o_xor             when "110",
			      o_not             when others;

	with op select
		cf <= o_add(8) when "000",
		      o_sub(8) when "001",
		      a(7)     when "010",
		      a(0)     when "011",
		      '0'      when others;

	with o_internal select
		zf <= '1' when x"00",
		      '0' when others;

	o <= o_internal;
end architecture;
