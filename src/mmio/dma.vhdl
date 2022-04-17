library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dma is
	port(
		a : in std_logic_vector(11 downto 0);
		d : in std_logic_vector(7 downto 0);
		q : out std_logic_vector(7 downto 0);
		w   : in std_logic;

		dma_a : out std_logic_vector(14 downto 0);
		dma_d : out std_logic_vector(7 downto 0);
		dma_q : in std_logic_vector(7 downto 0);
		dma_w : out std_logic;

		clk : in std_logic);
end entity;

architecture dma of dma is
	component badflate is
		port(
			input : in std_logic;
			read  : out std_logic;
			go    : in std_logic;
			rdy   : out std_logic;

			node_addr           : out std_logic_vector(8 downto 0);
			node_content_litlen : in std_logic_vector(31 downto 0);
			node_content_dist   : in std_logic_vector(31 downto 0);

			addr   : out std_logic_vector(15 downto 0);
			data_d : out std_logic_vector(7 downto 0);
			data_q : in std_logic_vector(7 downto 0);
			w      : out std_logic;

			clk : in std_logic);
	end component;

	signal select_bits  : std_logic_vector(1 downto 0);
	signal bf_control_q : std_logic_vector(7 downto 0);

	signal bf_out_addr_qh : std_logic_vector(7 downto 0);
	signal bf_out_addr_wh : std_logic;
	signal bf_out_addr_ql : std_logic_vector(7 downto 0);
	signal bf_out_addr_wl : std_logic;
	signal bf_out_addr_q  : unsigned(14 downto 0);

	signal bf_input : std_logic;
	signal bf_read  : std_logic;
	signal bf_go    : std_logic;
	signal bf_rdy   : std_logic;

	signal bf_byte_shift_reg_q      : std_logic_vector(7 downto 0);
	signal bf_byte_shift_reg_d      : std_logic_vector(7 downto 0);
	signal bf_next_byte_shift_reg_q : std_logic_vector(7 downto 0);
	signal bf_next_byte_shift_reg_d : std_logic_vector(7 downto 0);
	signal bf_byte_shift_regs_e     : std_logic;
	signal bf_should_load_next_byte : std_logic;
	signal bf_current_byte_addr_q   : unsigned(9 downto 0);
	signal bf_current_byte_addr_d   : unsigned(9 downto 0);

	signal bf_node_addr           : std_logic_vector(8 downto 0);
	signal bf_node_content_litlen : std_logic_vector(31 downto 0);
	signal bf_node_content_dist   : std_logic_vector(31 downto 0);

	signal bf_addr   : std_logic_vector(15 downto 0);
	signal bf_data_d : std_logic_vector(7 downto 0);
	signal bf_data_q : std_logic_vector(7 downto 0);
	signal bf_w      : std_logic;

	type bf_ram_type is array(16#3ff# downto 0) of std_logic_vector(7 downto 0);
	signal bf_ram   : bf_ram_type := (others => (others => '0'));
	signal bf_ram_w : std_logic;

	signal fake_dma_ram : bf_ram_type := (others => (others => '0'));
	signal fake_dma_a   : std_logic_vector(14 downto 0);
	signal fake_dma_d   : std_logic_vector(7 downto 0);
	signal fake_dma_q   : std_logic_vector(7 downto 0);
	signal fake_dma_w   : std_logic;
begin
	lbadflate: badflate port map (
		input => bf_input,
		read => bf_read,
		go => bf_go,
		rdy => bf_rdy,
		node_addr => bf_node_addr,
		node_content_litlen => bf_node_content_litlen,
		node_content_dist => bf_node_content_dist,
		addr => bf_addr,
		data_d => bf_data_d,
		data_q => bf_data_q,
		w => bf_w,
		clk => clk
	);

	process(clk, bf_byte_shift_regs_e, bf_should_load_next_byte, bf_out_addr_wh, bf_out_addr_wl, bf_ram_w) begin
		if(rising_edge(clk) and bf_byte_shift_regs_e = '1') then
			bf_byte_shift_reg_q <= bf_byte_shift_reg_d;
			bf_next_byte_shift_reg_q <= bf_next_byte_shift_reg_d;
		end if;
		if(rising_edge(clk) and bf_should_load_next_byte = '1') then
			bf_current_byte_addr_q <= bf_current_byte_addr_d;
		end if;
		if(rising_edge(clk) and bf_out_addr_wh = '1') then
			bf_out_addr_qh <= d;
		end if;
		if(rising_edge(clk) and bf_out_addr_wl = '1') then
			bf_out_addr_ql <= d;
		end if;
		if(rising_edge(clk) and bf_ram_w = '1') then
			bf_ram(to_integer(unsigned(a))) <= d;
		end if;
	end process;

	bf_byte_shift_regs_e <= bf_read or bf_go;
	with bf_should_load_next_byte select
		bf_byte_shift_reg_d <= '1' & bf_byte_shift_reg_q(7 downto 1)      when '0',
				       bf_ram(to_integer(bf_current_byte_addr_d)) when others;
	with bf_should_load_next_byte select
		bf_next_byte_shift_reg_d <= '0' & bf_next_byte_shift_reg_q(7 downto 1) when '0',
					    "10000000"                                 when others;
	with bf_go select
		bf_current_byte_addr_d <= bf_current_byte_addr_q + 1 when '0',
					  "0000000000"               when others;
	bf_should_load_next_byte <= (bf_next_byte_shift_reg_q(0) and bf_read) or bf_go;
	bf_input <= bf_byte_shift_reg_q(0);

	bf_go <= '1' when (bf_rdy = '1' and w = '1' and a = x"402") else '0';

	bf_out_addr_q <= unsigned(std_logic_vector'(bf_out_addr_qh(6 downto 0) & bf_out_addr_ql));

	-- TODO : Support real DMA : see src/mmio/wram.vhdl
	-- dma_a <= std_logic_vector(bf_out_addr_q + unsigned(bf_addr(14 downto 0)));
	-- dma_d <= bf_data_d;
	-- bf_data_q <= dma_q;
	-- dma_w <= bf_w;
	fake_dma_a <= std_logic_vector(bf_out_addr_q + unsigned(bf_addr(14 downto 0)));
	fake_dma_d <= bf_data_d;
	bf_data_q <= fake_dma_q;
	fake_dma_w <= bf_w;

	fake_dma_q <= fake_dma_ram(to_integer(unsigned(fake_dma_a(9 downto 0))));
	process(clk, fake_dma_w) begin
		if(rising_edge(clk) and fake_dma_w = '1') then
			fake_dma_ram(to_integer(unsigned(fake_dma_a(9 downto 0)))) <= fake_dma_d;
		end if;
	end process;

	with a select
		bf_control_q <= bf_out_addr_qh     when x"400",
				bf_out_addr_ql     when x"401",
				(others => bf_rdy) when others;
	bf_out_addr_wh <= w when (a = x"400") else '0';
	bf_out_addr_wl <= w when (a = x"401") else '0';

	select_bits <= a(11 downto 10);
	with select_bits select
		q <= bf_ram(to_integer(unsigned(a(9 downto 0))))       when "00",
		     fake_dma_ram(to_integer(unsigned(a(9 downto 0)))) when "11",
		     bf_control_q                                      when others;
	bf_ram_w <= w when (select_bits = "00") else '0';

	-- TODO : Support custom huffman codes
	-- These magic values implement the fixed Huffman codes described in RFC 1951
	with bf_node_addr select
		bf_node_content_litlen <=
			x"011E0067" when "000000000",
			x"81018100" when "000000001",
			x"81038102" when "000000010",
			x"00020001" when "000000011",
			x"81058104" when "000000100",
			x"81078106" when "000000101",
			x"00050004" when "000000110",
			x"00060003" when "000000111",
			x"81098108" when "000001000",
			x"810B810A" when "000001001",
			x"00090008" when "000001010",
			x"810D810C" when "000001011",
			x"810F810E" when "000001100",
			x"000C000B" when "000001101",
			x"000D000A" when "000001110",
			x"000E0007" when "000001111",
			x"81118110" when "000010000",
			x"81138112" when "000010001",
			x"00110010" when "000010010",
			x"81158114" when "000010011",
			x"81178116" when "000010100",
			x"00140013" when "000010101",
			x"00150012" when "000010110",
			x"80018000" when "000010111",
			x"80038002" when "000011000",
			x"00180017" when "000011001",
			x"80058004" when "000011010",
			x"80078006" when "000011011",
			x"001B001A" when "000011100",
			x"001C0019" when "000011101",
			x"80098008" when "000011110",
			x"800B800A" when "000011111",
			x"001F001E" when "000100000",
			x"800D800C" when "000100001",
			x"800F800E" when "000100010",
			x"00220021" when "000100011",
			x"00230020" when "000100100",
			x"0024001D" when "000100101",
			x"00250016" when "000100110",
			x"0026000F" when "000100111",
			x"80118010" when "000101000",
			x"80138012" when "000101001",
			x"00290028" when "000101010",
			x"80158014" when "000101011",
			x"80178016" when "000101100",
			x"002C002B" when "000101101",
			x"002D002A" when "000101110",
			x"80198018" when "000101111",
			x"801B801A" when "000110000",
			x"0030002F" when "000110001",
			x"801D801C" when "000110010",
			x"801F801E" when "000110011",
			x"00330032" when "000110100",
			x"00340031" when "000110101",
			x"0035002E" when "000110110",
			x"80218020" when "000110111",
			x"80238022" when "000111000",
			x"00380037" when "000111001",
			x"80258024" when "000111010",
			x"80278026" when "000111011",
			x"003B003A" when "000111100",
			x"003C0039" when "000111101",
			x"80298028" when "000111110",
			x"802B802A" when "000111111",
			x"003F003E" when "001000000",
			x"802D802C" when "001000001",
			x"802F802E" when "001000010",
			x"00420041" when "001000011",
			x"00430040" when "001000100",
			x"0044003D" when "001000101",
			x"00450036" when "001000110",
			x"80318030" when "001000111",
			x"80338032" when "001001000",
			x"00480047" when "001001001",
			x"80358034" when "001001010",
			x"80378036" when "001001011",
			x"004B004A" when "001001100",
			x"004C0049" when "001001101",
			x"80398038" when "001001110",
			x"803B803A" when "001001111",
			x"004F004E" when "001010000",
			x"803D803C" when "001010001",
			x"803F803E" when "001010010",
			x"00520051" when "001010011",
			x"00530050" when "001010100",
			x"0054004D" when "001010101",
			x"80418040" when "001010110",
			x"80438042" when "001010111",
			x"00570056" when "001011000",
			x"80458044" when "001011001",
			x"80478046" when "001011010",
			x"005A0059" when "001011011",
			x"005B0058" when "001011100",
			x"80498048" when "001011101",
			x"804B804A" when "001011110",
			x"005E005D" when "001011111",
			x"804D804C" when "001100000",
			x"804F804E" when "001100001",
			x"00610060" when "001100010",
			x"0062005F" when "001100011",
			x"0063005C" when "001100100",
			x"00640055" when "001100101",
			x"00650046" when "001100110",
			x"00660027" when "001100111",
			x"80518050" when "001101000",
			x"80538052" when "001101001",
			x"00690068" when "001101010",
			x"80558054" when "001101011",
			x"80578056" when "001101100",
			x"006C006B" when "001101101",
			x"006D006A" when "001101110",
			x"80598058" when "001101111",
			x"805B805A" when "001110000",
			x"0070006F" when "001110001",
			x"805D805C" when "001110010",
			x"805F805E" when "001110011",
			x"00730072" when "001110100",
			x"00740071" when "001110101",
			x"0075006E" when "001110110",
			x"80618060" when "001110111",
			x"80638062" when "001111000",
			x"00780077" when "001111001",
			x"80658064" when "001111010",
			x"80678066" when "001111011",
			x"007B007A" when "001111100",
			x"007C0079" when "001111101",
			x"80698068" when "001111110",
			x"806B806A" when "001111111",
			x"007F007E" when "010000000",
			x"806D806C" when "010000001",
			x"806F806E" when "010000010",
			x"00820081" when "010000011",
			x"00830080" when "010000100",
			x"0084007D" when "010000101",
			x"00850076" when "010000110",
			x"80718070" when "010000111",
			x"80738072" when "010001000",
			x"00880087" when "010001001",
			x"80758074" when "010001010",
			x"80778076" when "010001011",
			x"008B008A" when "010001100",
			x"008C0089" when "010001101",
			x"80798078" when "010001110",
			x"807B807A" when "010001111",
			x"008F008E" when "010010000",
			x"807D807C" when "010010001",
			x"807F807E" when "010010010",
			x"00920091" when "010010011",
			x"00930090" when "010010100",
			x"0094008D" when "010010101",
			x"80818080" when "010010110",
			x"80838082" when "010010111",
			x"00970096" when "010011000",
			x"80858084" when "010011001",
			x"80878086" when "010011010",
			x"009A0099" when "010011011",
			x"009B0098" when "010011100",
			x"80898088" when "010011101",
			x"808B808A" when "010011110",
			x"009E009D" when "010011111",
			x"808D808C" when "010100000",
			x"808F808E" when "010100001",
			x"00A100A0" when "010100010",
			x"00A2009F" when "010100011",
			x"00A3009C" when "010100100",
			x"00A40095" when "010100101",
			x"00A50086" when "010100110",
			x"81198118" when "010100111",
			x"811B811A" when "010101000",
			x"00A800A7" when "010101001",
			x"811D811C" when "010101010",
			x"811F811E" when "010101011",
			x"00AB00AA" when "010101100",
			x"00AC00A9" when "010101101",
			x"80918090" when "010101110",
			x"80938092" when "010101111",
			x"00AF00AE" when "010110000",
			x"80958094" when "010110001",
			x"80978096" when "010110010",
			x"00B200B1" when "010110011",
			x"00B300B0" when "010110100",
			x"80998098" when "010110101",
			x"809B809A" when "010110110",
			x"00B600B5" when "010110111",
			x"809D809C" when "010111000",
			x"809F809E" when "010111001",
			x"00B900B8" when "010111010",
			x"00BA00B7" when "010111011",
			x"00BB00B4" when "010111100",
			x"00BC00AD" when "010111101",
			x"80A180A0" when "010111110",
			x"80A380A2" when "010111111",
			x"00BF00BE" when "011000000",
			x"80A580A4" when "011000001",
			x"80A780A6" when "011000010",
			x"00C200C1" when "011000011",
			x"00C300C0" when "011000100",
			x"80A980A8" when "011000101",
			x"80AB80AA" when "011000110",
			x"00C600C5" when "011000111",
			x"80AD80AC" when "011001000",
			x"80AF80AE" when "011001001",
			x"00C900C8" when "011001010",
			x"00CA00C7" when "011001011",
			x"00CB00C4" when "011001100",
			x"80B180B0" when "011001101",
			x"80B380B2" when "011001110",
			x"00CE00CD" when "011001111",
			x"80B580B4" when "011010000",
			x"80B780B6" when "011010001",
			x"00D100D0" when "011010010",
			x"00D200CF" when "011010011",
			x"80B980B8" when "011010100",
			x"80BB80BA" when "011010101",
			x"00D500D4" when "011010110",
			x"80BD80BC" when "011010111",
			x"80BF80BE" when "011011000",
			x"00D800D7" when "011011001",
			x"00D900D6" when "011011010",
			x"00DA00D3" when "011011011",
			x"00DB00CC" when "011011100",
			x"00DC00BD" when "011011101",
			x"80C180C0" when "011011110",
			x"80C380C2" when "011011111",
			x"00DF00DE" when "011100000",
			x"80C580C4" when "011100001",
			x"80C780C6" when "011100010",
			x"00E200E1" when "011100011",
			x"00E300E0" when "011100100",
			x"80C980C8" when "011100101",
			x"80CB80CA" when "011100110",
			x"00E600E5" when "011100111",
			x"80CD80CC" when "011101000",
			x"80CF80CE" when "011101001",
			x"00E900E8" when "011101010",
			x"00EA00E7" when "011101011",
			x"00EB00E4" when "011101100",
			x"80D180D0" when "011101101",
			x"80D380D2" when "011101110",
			x"00EE00ED" when "011101111",
			x"80D580D4" when "011110000",
			x"80D780D6" when "011110001",
			x"00F100F0" when "011110010",
			x"00F200EF" when "011110011",
			x"80D980D8" when "011110100",
			x"80DB80DA" when "011110101",
			x"00F500F4" when "011110110",
			x"80DD80DC" when "011110111",
			x"80DF80DE" when "011111000",
			x"00F800F7" when "011111001",
			x"00F900F6" when "011111010",
			x"00FA00F3" when "011111011",
			x"00FB00EC" when "011111100",
			x"80E180E0" when "011111101",
			x"80E380E2" when "011111110",
			x"00FE00FD" when "011111111",
			x"80E580E4" when "100000000",
			x"80E780E6" when "100000001",
			x"01010100" when "100000010",
			x"010200FF" when "100000011",
			x"80E980E8" when "100000100",
			x"80EB80EA" when "100000101",
			x"01050104" when "100000110",
			x"80ED80EC" when "100000111",
			x"80EF80EE" when "100001000",
			x"01080107" when "100001001",
			x"01090106" when "100001010",
			x"010A0103" when "100001011",
			x"80F180F0" when "100001100",
			x"80F380F2" when "100001101",
			x"010D010C" when "100001110",
			x"80F580F4" when "100001111",
			x"80F780F6" when "100010000",
			x"0110010F" when "100010001",
			x"0111010E" when "100010010",
			x"80F980F8" when "100010011",
			x"80FB80FA" when "100010100",
			x"01140113" when "100010101",
			x"80FD80FC" when "100010110",
			x"80FF80FE" when "100010111",
			x"01170116" when "100011000",
			x"01180115" when "100011001",
			x"01190112" when "100011010",
			x"011A010B" when "100011011",
			x"011B00FC" when "100011100",
			x"011C00DD" when "100011101",
			x"011D00A6" when "100011110",
			x"7FFF7FFF" when others;
	with bf_node_addr select
		bf_node_content_dist <=
			x"001E000F" when "000000000",
			x"80018000" when "000000001",
			x"80038002" when "000000010",
			x"00020001" when "000000011",
			x"80058004" when "000000100",
			x"80078006" when "000000101",
			x"00050004" when "000000110",
			x"00060003" when "000000111",
			x"80098008" when "000001000",
			x"800B800A" when "000001001",
			x"00090008" when "000001010",
			x"800D800C" when "000001011",
			x"800F800E" when "000001100",
			x"000C000B" when "000001101",
			x"000D000A" when "000001110",
			x"000E0007" when "000001111",
			x"80118010" when "000010000",
			x"80138012" when "000010001",
			x"00110010" when "000010010",
			x"80158014" when "000010011",
			x"80178016" when "000010100",
			x"00140013" when "000010101",
			x"00150012" when "000010110",
			x"80198018" when "000010111",
			x"801B801A" when "000011000",
			x"00180017" when "000011001",
			x"801D801C" when "000011010",
			x"801F801E" when "000011011",
			x"001B001A" when "000011100",
			x"001C0019" when "000011101",
			x"001D0016" when "000011110",
			x"7FFF7FFF" when others;
end architecture;
