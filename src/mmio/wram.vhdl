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
	shared variable ram_data : ram_type := (others => (others => '0'));

	attribute ram_style : string;
	attribute ram_style of ram_data : variable is "block";
begin
	-- Reference : https://docs.xilinx.com/v/u/2018.3-English/ug901-vivado-synthesis
	-- To make sure Vivado infers this to Block RAM : Chapter 4 > RAM HDL Coding Guidelines
	process(clk, w) begin
		if(rising_edge(clk)) then
			q <= ram_data(to_integer(unsigned(a)));
			if(w = '1') then
				ram_data(to_integer(unsigned(a))) := d;
			end if;
		end if;
	end process;
	process(clk, dma_w) begin
		if(rising_edge(clk)) then
			dma_q <= ram_data(to_integer(unsigned(dma_a)));
			if(dma_w = '1') then
				ram_data(to_integer(unsigned(dma_a))) := dma_d;
			end if;
		end if;
	end process;
end architecture;
