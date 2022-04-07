library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
	port(
		gpio_signals_out : out std_logic_vector(24 downto 0);
		gpio_signals_in  : in std_logic_vector(9 downto 0);

		r   : in std_logic;
		clk : in std_logic);
end entity;

architecture cpu of cpu is
	component alu is
		port(
			a  : in std_logic_vector(7 downto 0);
			b  : in std_logic_vector(7 downto 0);
			op : in std_logic_vector(2 downto 0);

			o  : out std_logic_vector(7 downto 0);
			cf : out std_logic;
			zf : out std_logic);
	end component;
	component ad is
		port(
			d : in std_logic_vector(7 downto 0);
			q : out std_logic_vector(15 downto 0);

			el  : in std_logic;
			eh  : in std_logic;
			clk : in std_logic);
	end component;
	component flags is
		port(
			zfd : in std_logic;
			cfd : in std_logic;

			zfq : out std_logic;
			cfq : out std_logic;

			e   : in std_logic;
			clk : in std_logic);
	end component;
	component gpr is
		port(
			d : in std_logic_vector(7 downto 0);
			q : out std_logic_vector(7 downto 0);

			e   : in std_logic;
			clk : in std_logic);
	end component;
	component ir is
		port(
			d  : in std_logic_vector(7 downto 0);
			ql : out std_logic_vector(7 downto 0);
			qh : out std_logic_vector(7 downto 0);

			el  : in std_logic;
			eh  : in std_logic;
			clk : in std_logic);
	end component;
	component lr is
		port(
			d  : in std_logic_vector(15 downto 0);
			ql : out std_logic_vector(7 downto 0);
			qh : out std_logic_vector(7 downto 0);

			e   : in std_logic;
			clk : in std_logic);
	end component;
	component pc is
		port(
			d : in std_logic_vector(15 downto 0);
			q : out std_logic_vector(15 downto 0);
			
			r   : in std_logic;
			e   : in std_logic;
			inc : in std_logic;
			clk : in std_logic);
	end component;
	component upc is
		port(
			q : out std_logic_vector(3 downto 0);

			r   : in std_logic;
			clk : in std_logic);
	end component;
	component mmu is
		port(
			a : in std_logic_vector(15 downto 0);
			d : in std_logic_vector(7 downto 0);
			q : out std_logic_vector(7 downto 0);

			gpio_signals_out : out std_logic_vector(24 downto 0);
			gpio_signals_in  : in std_logic_vector(9 downto 0);

			w   : in std_logic;
			clk : in std_logic);
	end component;
	component microcode is
		port(
			upc : in std_logic_vector(3 downto 0);
			irh : in std_logic_vector(7 downto 0);
			zf  : in std_logic;
			cf  : in std_logic;

			cs : out std_logic_vector(19 downto 0));
	end component;


	signal data_bus : std_logic_vector(7 downto 0);
	signal addr_bus : std_logic_vector(15 downto 0);

	signal alu_o : std_logic_vector(7 downto 0);

	signal ra_q  : std_logic_vector(7 downto 0);
	signal rb_q  : std_logic_vector(7 downto 0);
	signal ad_q  : std_logic_vector(15 downto 0);
	signal pc_q  : std_logic_vector(15 downto 0);
	signal ir_ql : std_logic_vector(7 downto 0);
	signal ir_qh : std_logic_vector(7 downto 0);
	signal lr_ql : std_logic_vector(7 downto 0);
	signal lr_qh : std_logic_vector(7 downto 0);
	signal upc_q : std_logic_vector(3 downto 0);

	signal mmu_q : std_logic_vector(7 downto 0);

	signal flags_cfd : std_logic;
	signal flags_zfd : std_logic;
	signal flags_cfq : std_logic;
	signal flags_zfq : std_logic;

	signal cs         : std_logic_vector(19 downto 0);
	signal cs_db_sel  : std_logic_vector(2 downto 0);	-- data_bus selector
	signal cs_ab_sel  : std_logic;				-- addr_bus selector

	signal cs_mmu_w   : std_logic;				-- data_bus => mmu(addr_bus)
	signal cs_ra_w    : std_logic;				-- data_bus => ra
	signal cs_rb_w    : std_logic;				-- data_bus => rb
	signal cs_irh_w   : std_logic;				-- data_bus => irh
	signal cs_irl_w   : std_logic;				-- data_bus => irl
	-- TODO fully deprecate these
     -- signal cs_pch_w   : std_logic;				-- data_bus => pch
     -- signal cs_pcl_w   : std_logic;				-- data_bus => pcl
	signal cs_pc_w    : std_logic;				-- ad => pc
	signal cs_adh_w   : std_logic;				-- data_bus => adh
	signal cs_adl_w   : std_logic;				-- data_bus => adl

	signal cs_alu_op  : std_logic_vector(2 downto 0);	-- alu.op
	signal cs_flags_w : std_logic;				-- alu.flags => flags
	signal cs_pc_i    : std_logic;				-- pc + 1 => pc
	signal cs_lr_w    : std_logic;				-- pc => lr
	signal cs_upc_z   : std_logic;				-- 0 => upc
begin
	-- TODO : irq

	cs_db_sel <= cs(2 downto 0);
	cs_ab_sel <= cs(3);

	cs_mmu_w  <= cs( 4);
	cs_ra_w   <= cs( 5);
	cs_rb_w   <= cs( 6);
	cs_irh_w  <= cs( 7);
	cs_irl_w  <= cs( 8);
     -- cs_pch_w  <= cs( 9);
     -- cs_pcl_w  <= cs(10);
	cs_pc_w   <= cs( 9);
	cs_adh_w  <= cs(11);
	cs_adl_w  <= cs(12);

	cs_alu_op  <= cs(15 downto 13);
	cs_flags_w <= cs(16);
	cs_pc_i    <= cs(17);
	cs_lr_w    <= cs(18);
	cs_upc_z   <= cs(19);

	lalu: alu port map (
		a => ra_q,
		b => rb_q,
		op => cs_alu_op,
		o => alu_o,
		cf => flags_cfd,
		zf => flags_zfd
	);

	lra: gpr port map (
		d => data_bus,
		q => ra_q,
		e => cs_ra_w,
		clk => clk
	);

	lrb: gpr port map (
		d => data_bus,
		q => rb_q,
		e => cs_rb_w,
		clk => clk
	);

	lad: ad port map (
		d => data_bus,
		q => ad_q,
		el => cs_adl_w,
		eh => cs_adh_w,
		clk => clk
	);

	lflags: flags port map (
		zfd => flags_zfd,
		cfd => flags_cfd,
		zfq => flags_zfq,
		cfq => flags_cfq,
		e => cs_flags_w,
		clk => clk
	);

	lir: ir port map (
		d => data_bus,
		ql => ir_ql,
		qh => ir_qh,
		el => cs_irl_w,
		eh => cs_irh_w,
		clk => clk
	);

	llr: lr port map (
		d => pc_q,
		ql => lr_ql,
		qh => lr_qh,
		e => cs_lr_w,
		clk => clk
	);

	lpc: pc port map (
		d => ad_q,
		q => pc_q,
		r => r,
		e => cs_pc_w,
		inc => cs_pc_i,
		clk => clk
	);

	lupc: upc port map (
		q => upc_q,
		r => cs_upc_z or r,
		clk => clk
	);

	lmmu: mmu port map (
		a => addr_bus,
		d => data_bus,
		q => mmu_q,
		gpio_signals_out => gpio_signals_out,
		gpio_signals_in => gpio_signals_in,
		w => cs_mmu_w,
		clk => clk
	);

	lmicrocode: microcode port map (
		upc => upc_q,
		irh => ir_qh,
		zf => flags_zfq,
		cf => flags_cfq,
		cs => cs
	);

	with cs_db_sel select
		data_bus <= ra_q  when "000",
			    rb_q  when "001",
			    mmu_q when "010",
			    alu_o when "011",
			    ir_ql when "100",
			    lr_qh when "101",
			    lr_ql when others;

	with cs_ab_sel select
		addr_bus <= ad_q when '0',
			    pc_q when others;
end architecture;
