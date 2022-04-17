library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wram is
	port(
		a : in std_logic_vector(14 downto 0);
		d : in std_logic_vector(7 downto 0);
		q : out std_logic_vector(7 downto 0);
		w   : in std_logic;

		dma_a : in std_logic_vector(14 downto 0);
		dma_d : in std_logic_vector(7 downto 0);
		dma_q : out std_logic_vector(7 downto 0);
		dma_w : in std_logic;

		clk : in std_logic);
end entity;

architecture wram of wram is
	type ram_type is array(16#7fff# downto 0) of std_logic_vector(7 downto 0);
	signal ram_data : ram_type := (others => (others => '0'));
begin
	-- TODO : Use real block RAM and not LUTRAM
	-- It is required for DMA because LUTRAM can't have 2 write ports
	-- However it adds an extra delay on the output
	q <= ram_data(to_integer(unsigned(a)));
	process(clk, w) begin
		if(rising_edge(clk) and w = '1') then
			ram_data(to_integer(unsigned(a))) <= d;
		end if;
	end process;
end architecture;
