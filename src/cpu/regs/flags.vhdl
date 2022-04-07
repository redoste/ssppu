library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity flags is
	port(
		zfd : in std_logic;
		cfd : in std_logic;

		zfq : out std_logic;
		cfq : out std_logic;

		e   : in std_logic;
		clk : in std_logic);
end entity;

architecture flags of flags is
begin
	process(clk) begin
		if(rising_edge(clk) and e = '1') then
			zfq <= zfd;
			cfq <= cfd;
		end if;
	end process;
end architecture;
