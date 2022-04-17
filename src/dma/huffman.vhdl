library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity huffman is
	port(
		input : in std_logic;

		node_addr    : out std_logic_vector(8 downto 0);
		node_content : in std_logic_vector(31 downto 0);

		output_reg         : out std_logic_vector(14 downto 0);
		output_reg_changed : out std_logic;

		r   : in std_logic;
		clk : in std_logic);
end entity;

architecture huffman of huffman is
	signal current_node_addr_q  : std_logic_vector(8 downto 0) := (others => '0');
	signal current_node_addr_d  : std_logic_vector(8 downto 0);

	signal selected_leaf : std_logic_vector(15 downto 0);

	signal output_reg_e               : std_logic;
	signal output_reg_changed_interal : std_logic := '0';
begin
	process(clk, output_reg_e) begin
		if(rising_edge(clk)) then
			current_node_addr_q <= current_node_addr_d;
		end if;
		if(rising_edge(clk) and output_reg_e = '1') then
			output_reg <= selected_leaf(14 downto 0);
			output_reg_changed_interal <= not output_reg_changed_interal;
		end if;
	end process;
	node_addr <= current_node_addr_q;
	output_reg_changed <= output_reg_changed_interal;

	with input select
		selected_leaf <= node_content(31 downto 16) when '1',
				 node_content(15 downto 0)  when others;
	output_reg_e <= selected_leaf(15) and not r;

	current_node_addr_d <= selected_leaf(8 downto 0) when (selected_leaf(15) = '0' and r = '0') else (others => '0');
end architecture;
