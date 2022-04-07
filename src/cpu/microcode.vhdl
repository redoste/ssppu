library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity microcode is
	port(
		upc : in std_logic_vector(3 downto 0);
		irh : in std_logic_vector(7 downto 0);
		zf  : in std_logic;
		cf  : in std_logic;

		cs : out std_logic_vector(19 downto 0));
end entity;

architecture microcode of microcode is
	signal cs_alu    : std_logic_vector(19 downto 0);
	signal alu_flags : std_logic_vector(19 downto 0);
	signal alu_dest  : std_logic_vector(19 downto 0);

	signal cs_trans          : std_logic_vector(19 downto 0);
	signal trans_src         : std_logic_vector(19 downto 0);
	signal trans_dst         : std_logic_vector(19 downto 0);
	signal trans_final_write : std_logic_vector(19 downto 0);
	signal trans_trans       : std_logic_vector(19 downto 0);
	signal trans_imm         : std_logic_vector(19 downto 0);
	signal trans_abs         : std_logic_vector(19 downto 0);
	signal trans_rel_base    : std_logic_vector(19 downto 0);
	signal trans_rel         : std_logic_vector(19 downto 0);

	signal cs_st          : std_logic_vector(19 downto 0);
	signal st_final_write : std_logic_vector(19 downto 0);
	signal st_abs         : std_logic_vector(19 downto 0);
	signal st_rel_base    : std_logic_vector(19 downto 0);
	signal st_rel         : std_logic_vector(19 downto 0);

	signal cs_jmp       : std_logic_vector(19 downto 0);
	signal jmp_n        : std_logic;
	signal jmp_c        : std_logic;
	signal jmp_z        : std_logic;
	signal jmp_should   : std_logic;
	signal jmp_sel      : std_logic_vector(1 downto 0);
	signal jmp_lr_write : std_logic_vector(19 downto 0);
	signal jmp_nr       : std_logic_vector(19 downto 0);
	signal jmp_nr_skip  : std_logic_vector(19 downto 0);
	signal jmp_r        : std_logic_vector(19 downto 0);

	signal cs_internal : std_logic_vector(19 downto 0);

	constant CS_DB_RA   : std_logic_vector(19 downto 0) := "00000000000000000000";
	constant CS_DB_RB   : std_logic_vector(19 downto 0) := "00000000000000000001";
	constant CS_DB_MMU  : std_logic_vector(19 downto 0) := "00000000000000000010";
	constant CS_DB_ALU  : std_logic_vector(19 downto 0) := "00000000000000000011";
	constant CS_DB_IRL  : std_logic_vector(19 downto 0) := "00000000000000000100";
	constant CS_DB_LRH  : std_logic_vector(19 downto 0) := "00000000000000000101";
	constant CS_DB_LRL  : std_logic_vector(19 downto 0) := "00000000000000000110";

	constant CS_AB_AD   : std_logic_vector(19 downto 0) := "00000000000000000000";
	constant CS_AB_PC   : std_logic_vector(19 downto 0) := "00000000000000001000";

	constant CS_MMU_W   : std_logic_vector(19 downto 0) := "00000000000000010000";
	constant CS_RA_W    : std_logic_vector(19 downto 0) := "00000000000000100000";
	constant CS_RB_W    : std_logic_vector(19 downto 0) := "00000000000001000000";
	constant CS_IRH_W   : std_logic_vector(19 downto 0) := "00000000000010000000";
	constant CS_IRL_W   : std_logic_vector(19 downto 0) := "00000000000100000000";
	-- TODO deprecate these
     -- constant CS_PCH_W   : std_logic_vector(19 downto 0) := "00000000001000000000";
     -- constant CS_PCL_W   : std_logic_vector(19 downto 0) := "00000000010000000000";
	constant CS_PC_W    : std_logic_vector(19 downto 0) := "00000000001000000000";
	constant CS_ADH_W   : std_logic_vector(19 downto 0) := "00000000100000000000";
	constant CS_ADL_W   : std_logic_vector(19 downto 0) := "00000001000000000000";

	constant CS_ALU_ADD : std_logic_vector(19 downto 0) := "00000000000000000000";
	constant CS_ALU_SUB : std_logic_vector(19 downto 0) := "00000010000000000000";
	constant CS_ALU_SHL : std_logic_vector(19 downto 0) := "00000100000000000000";
	constant CS_ALU_SHR : std_logic_vector(19 downto 0) := "00000110000000000000";
	constant CS_ALU_AND : std_logic_vector(19 downto 0) := "00001000000000000000";
	constant CS_ALU_OR  : std_logic_vector(19 downto 0) := "00001010000000000000";
	constant CS_ALU_XOR : std_logic_vector(19 downto 0) := "00001100000000000000";
	constant CS_ALU_NOT : std_logic_vector(19 downto 0) := "00001110000000000000";

	constant CS_FLAGS_W : std_logic_vector(19 downto 0) := "00010000000000000000";
	constant CS_PC_I    : std_logic_vector(19 downto 0) := "00100000000000000000";
	constant CS_LR_W    : std_logic_vector(19 downto 0) := "01000000000000000000";
	constant CS_UPC_Z   : std_logic_vector(19 downto 0) := "10000000000000000000";
begin
	-- When UPC is zero we always update IRH with the current instruction
	with upc select
		cs <= CS_DB_MMU or CS_AB_PC or CS_IRH_W when "0000",
		      cs_internal                       when others;

	-- ALU  : 0ooodwf0
	-- oooo : Operation
	-- d    : Destination register
	-- w    : Write result to register
	-- f    : Write flags
	with irh(1) select
		alu_flags <= CS_FLAGS_W      when '1',
			     (others => '0') when others;
	with irh(3 downto 2) select
		alu_dest <= CS_DB_ALU or CS_RA_W when "01",
			    CS_DB_ALU or CS_RB_W when "11",
			    (others => '0')      when others;
	with upc select
		cs_alu <= alu_flags(19 downto 16) & irh(6 downto 4) & alu_dest(12 downto 0) when "0001",
			  CS_PC_I or CS_UPC_Z                                               when others;

	-- LD / TRANS : 1000dsss
	-- d          : Destination register
	-- sss        : Source
	-- Sources :
	--     000 Ra
	--     001 Rb
	--     010 LRh
	--     011 LRl
	--     100 immediate
	--     101 absolute addr
	--     110 relative addr from Ra
	--     111 relative addr from Rb
	with irh(2 downto 0) select
		trans_src <= CS_DB_RA              when "000",
			     CS_DB_RB              when "001",
			     CS_DB_LRH             when "010",
			     CS_DB_LRL             when "011",
			     CS_AB_PC or CS_DB_MMU when "100",
			     CS_AB_AD or CS_DB_MMU when others;
	with irh(0) select
		trans_rel_base <= CS_ADL_W or CS_DB_RA when '0',
				  CS_ADL_W or CS_DB_RB when others;
	with irh(3) select
		trans_dst <= CS_RA_W when '0',
			     CS_RB_W when others;
	trans_final_write <= trans_dst(19 downto 4) & trans_src(3 downto 0);

	with upc select
		trans_trans <= trans_final_write     when "0001",
			       CS_PC_I or CS_UPC_Z   when others;
	with upc select
		trans_imm <= CS_PC_I              when "0001",
			     trans_final_write    when "0010",
			     CS_PC_I or CS_UPC_Z  when others;
	with upc select
		trans_abs <= CS_PC_I                           when "0001",
			     CS_ADH_W or CS_AB_PC or CS_DB_MMU when "0010",
			     CS_PC_I                           when "0011",
			     CS_ADL_W or CS_AB_PC or CS_DB_MMU when "0100",
			     trans_final_write                 when "0101",
			     CS_PC_I or CS_UPC_Z               when others;
	with upc select
		trans_rel <= CS_PC_I                           when "0001",
			     CS_ADH_W or CS_AB_PC or CS_DB_MMU when "0010",
			     trans_rel_base                    when "0011",
			     trans_final_write                 when "0100",
			     CS_PC_I or CS_UPC_Z               when others;
	with irh(2 downto 0) select
		cs_trans <= trans_imm   when "100",
			    trans_abs   when "101",
			    trans_rel   when "110",
			    trans_rel   when "111",
			    trans_trans when others;

	-- ST : 1001ddss
	-- dd : Destination
	-- ss : Source register
	-- Destinations:
	--     00 absolute addr
	--     10 relative addr Ra
	--     11 relative addr Rb
	-- Sources :
	--     00 Ra
	--     01 Rb
	--     10 LRh
	--     11 LRl
	with irh(1 downto 0) select
		st_final_write <= CS_AB_AD or CS_MMU_W or CS_DB_RA  when "00",
				  CS_AB_AD or CS_MMU_W or CS_DB_RB  when "01",
				  CS_AB_AD or CS_MMU_W or CS_DB_LRH when "10",
				  CS_AB_AD or CS_MMU_W or CS_DB_LRL when others;
	with irh(2) select
		st_rel_base <= CS_ADL_W or CS_DB_RA when '0',
			       CS_ADL_W or CS_DB_RB when others;

	with upc select
		st_abs <= CS_PC_I                           when "0001",
			  CS_ADH_W or CS_AB_PC or CS_DB_MMU when "0010",
			  CS_PC_I                           when "0011",
			  CS_ADL_W or CS_AB_PC or CS_DB_MMU when "0100",
			  st_final_write                    when "0101",
			  CS_PC_I or CS_UPC_Z               when others;
	with upc select
		st_rel <= CS_PC_I                           when "0001",
			  CS_ADH_W or CS_AB_PC or CS_DB_MMU when "0010",
			  st_rel_base                       when "0011",
			  st_final_write                    when "0100",
			  CS_PC_I or CS_UPC_Z               when others;
	with irh(3) select
		cs_st <= st_abs when '0',
			 st_rel when others;

	-- JMP / CALL / RET : 110lrncz
	-- l                : Write PC + 1 to LR
	-- r                : Jump to LR
	-- n                : Inverse condition
	-- c                : Only jump if the carry flag is set
	-- z                : Only jump if the zero flag is set
	jmp_n <= irh(2);
	jmp_c <= irh(1);
	jmp_z <= irh(0);
	jmp_should <= (not jmp_c and not jmp_z) or
		      (not jmp_n and not jmp_c and jmp_z and zf) or
		      (not jmp_n and jmp_c and not jmp_z and cf) or
		      (not jmp_n and jmp_c and jmp_z and cf and zf) or
		      (jmp_n and not jmp_c and jmp_z and not zf) or
		      (jmp_n and jmp_c and not jmp_z and not cf) or
		      (jmp_n and jmp_c and jmp_z and not cf and not zf);
	with irh(4) select
		jmp_lr_write <= CS_LR_W         when '1',
				(others => '0') when others;

	with upc select
		jmp_nr <= CS_PC_I                           when "0001",
			  CS_ADH_W or CS_AB_PC or CS_DB_MMU when "0010",
			  CS_PC_I                           when "0011",
			  CS_ADL_W or CS_AB_PC or CS_DB_MMU when "0100",
			  CS_PC_I                           when "0101",
			  jmp_lr_write                      when "0110",
			  CS_PC_W or CS_UPC_Z               when others;
	with upc select
		jmp_nr_skip <= CS_PC_I             when "0001",
			       CS_PC_I             when "0010",
			       CS_PC_I or CS_UPC_Z when others;
	with upc select
		jmp_r <= CS_ADH_W or CS_DB_LRH when "0001",
			 CS_ADL_W or CS_DB_LRL when "0010",
			 CS_PC_W or CS_UPC_Z   when others;
	jmp_sel <= jmp_should & irh(3);
	with jmp_sel select
		cs_jmp <= jmp_nr              when "10",
			  jmp_r               when "11",
			  jmp_nr_skip         when "00",
			  CS_PC_I or CS_UPC_Z when others;

	-- TODO
	-- HLT : 11111111

	with irh(7 downto 4) select
		cs_internal <= cs_trans            when "1000",
			       cs_st               when "1001",
			       cs_jmp              when "1100",
			       cs_jmp              when "1101",
			       CS_PC_I or CS_UPC_Z when "1111",
			       CS_PC_I or CS_UPC_Z when "1010", -- NOP : 10101010
			       cs_alu              when others;
end architecture;
