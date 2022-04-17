-- BADFLATE : A Bad DEFLATE variant
-- Only block compressed with the fixed Huffman codes are supported
-- Thus it lacks the BTYPE and BFINAL fields

-- Reference : RFC 1951 : https://datatracker.ietf.org/doc/html/rfc1951

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity badflate is
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
end entity;

architecture badflate of badflate is
	component huffman is
		port(
			input : in std_logic;

			node_addr    : out std_logic_vector(8 downto 0);
			node_content : in std_logic_vector(31 downto 0);

			output_reg         : out std_logic_vector(14 downto 0);
			output_reg_changed : out std_logic;

			r   : in std_logic;
			clk : in std_logic);
	end component;

	type state_type is (READY, READ_CODE, WRITE_LIT, COPY_LEN_I, COPY_LEN_EB, COPY_DIST, COPY_DIST_I, COPY_DIST_EB, READ_COPY, WRITE_COPY);
	signal state_q : state_type := READY;
	signal state_d : state_type;
	signal state_s : std_logic_vector(15 downto 0);

	signal should_read : boolean;

	signal node_content                 : std_logic_vector(31 downto 0);
	signal huffman_output               : std_logic_vector(14 downto 0);
	signal huffman_output_change        : std_logic;
	signal huffman_last_output_change_q : std_logic := '0';
	signal huffman_output_changed       : std_logic;
	signal huffman_reset                : std_logic;

	signal addr_internal : std_logic_vector(15 downto 0) := (others => '0');
	signal addr_sub_dist : std_logic_vector(15 downto 0);
	signal addr_d        : std_logic_vector(15 downto 0);
	signal addr_e        : std_logic;

	signal copy_len_base_q : integer;
	signal copy_len_base_d : integer;
	signal copy_len_base_e : std_logic;

	signal copy_len_eb_q : std_logic_vector(4 downto 0);
	signal copy_len_eb_d : std_logic_vector(4 downto 0);
	signal copy_len_eb_u : std_logic_vector(4 downto 0);
	signal copy_len_eb_e : std_logic;

	signal copy_len_eb_shift_offset_q : integer := 0;
	signal copy_len_eb_shift_offset_d : integer;
	signal copy_len_eb_shift_offset_e : std_logic;

	signal copy_len_done_q : integer;
	signal copy_len_done_d : integer;
	signal copy_len_done_e : std_logic;

	signal copy_len_eb_remaining_bits_q   : integer;
	signal copy_len_eb_remaining_bits_d   : integer;
	signal copy_len_eb_remaining_bits_di  : integer;
	signal copy_len_eb_remaining_bits_dec : integer;
	signal copy_len_eb_remaining_bits_e   : std_logic;

	signal copy_dist_base_q : integer;
	signal copy_dist_base_d : integer;
	signal copy_dist_base_e : std_logic;

	signal copy_dist_eb_q : std_logic_vector(12 downto 0);
	signal copy_dist_eb_d : std_logic_vector(12 downto 0);
	signal copy_dist_eb_u : std_logic_vector(12 downto 0);
	signal copy_dist_eb_e : std_logic;

	signal copy_dist_eb_shift_offset_q : integer := 0;
	signal copy_dist_eb_shift_offset_d : integer;
	signal copy_dist_eb_shift_offset_e : std_logic;

	signal copy_dist_eb_remaining_q   : integer;
	signal copy_dist_eb_remaining_d   : integer;
	signal copy_dist_eb_remaining_di  : integer;
	signal copy_dist_eb_remaining_dec : integer;
	signal copy_dist_eb_remaining_e   : std_logic;

	signal copy_current_byte_q : std_logic_vector(7 downto 0);
	signal copy_current_byte_d : std_logic_vector(7 downto 0);
	signal copy_current_byte_e : std_logic;

	signal should_write_literal    : std_logic;
	signal should_write_copy       : std_logic;
	signal should_end              : std_logic;
	signal write_lit_finished      : std_logic;
	signal copy_len_i_finished     : std_logic;
	signal copy_len_bypass_eb      : std_logic;
	signal copy_len_eb_finished    : std_logic;
	signal copy_dist_finished      : std_logic;
	signal copy_dist_i_finished    : std_logic;
	signal copy_dist_bypass_eb     : std_logic;
	signal copy_dist_eb_finished   : std_logic;
	signal read_copy_finished      : std_logic;
	signal write_copy_finished     : std_logic;
	signal write_copy_all_finished : std_logic;
begin
	lhuffman: huffman port map (
		input => input,
		node_addr => node_addr,
		node_content => node_content,
		output_reg => huffman_output,
		output_reg_changed => huffman_output_change,
		r => huffman_reset,
		clk => clk
	);

	process(clk, addr_e, copy_len_base_e, copy_len_eb_remaining_bits_e, copy_len_eb_e, copy_len_eb_shift_offset_e,
		copy_len_done_e, copy_dist_base_e, copy_dist_eb_remaining_e, copy_dist_eb_e, copy_dist_eb_shift_offset_e,
		copy_current_byte_e, huffman_output_changed) begin
		if(rising_edge(clk)) then
			state_q <= state_d;
		end if;
		if(rising_edge(clk) and addr_e = '1') then
			addr_internal <= addr_d;
		end if;
		if(rising_edge(clk) and copy_len_base_e = '1') then
			copy_len_base_q <= copy_len_base_d;
		end if;
		if(rising_edge(clk) and copy_len_eb_remaining_bits_e = '1') then
			copy_len_eb_remaining_bits_q <= copy_len_eb_remaining_bits_d;
		end if;
		if(rising_edge(clk) and copy_len_eb_e = '1') then
			copy_len_eb_q <= copy_len_eb_d;
		end if;
		if(rising_edge(clk) and copy_len_eb_shift_offset_e = '1') then
			copy_len_eb_shift_offset_q <= copy_len_eb_shift_offset_d;
		end if;
		if(rising_edge(clk) and copy_len_done_e = '1') then
			copy_len_done_q <= copy_len_done_d;
		end if;
		if(rising_edge(clk) and copy_dist_base_e = '1') then
			copy_dist_base_q <= copy_dist_base_d;
		end if;
		if(rising_edge(clk) and copy_dist_eb_remaining_e = '1') then
			copy_dist_eb_remaining_q <= copy_dist_eb_remaining_d;
		end if;
		if(rising_edge(clk) and copy_dist_eb_e = '1') then
			copy_dist_eb_q <= copy_dist_eb_d;
		end if;
		if(rising_edge(clk) and copy_dist_eb_shift_offset_e = '1') then
			copy_dist_eb_shift_offset_q <= copy_dist_eb_shift_offset_d;
		end if;
		if(rising_edge(clk) and copy_current_byte_e = '1') then
			copy_current_byte_q <= copy_current_byte_d;
		end if;
		if(rising_edge(clk) and huffman_output_changed = '1') then
			huffman_last_output_change_q <= huffman_output_change;
		end if;
	end process;

	should_read <= (state_q = READ_CODE and huffman_output_changed = '0') or
		       (state_q = COPY_LEN_EB) or
		       (state_q = COPY_DIST and huffman_output_changed = '0') or
		       (state_q = COPY_DIST_EB);
	read <= '1' when should_read else '0';
	rdy <= '1' when (state_q = READY) else '0';

	with state_q select
		data_d <= huffman_output(7 downto 0) when WRITE_LIT,
			  copy_current_byte_q        when WRITE_COPY,
			  (others => '0')            when others;
	w <= '1' when (state_q = WRITE_LIT or state_q = WRITE_COPY) else '0';
	with state_q select
		addr <= addr_sub_dist when READ_COPY,
			addr_internal when others;
	with state_q select
		addr_d <= (others => '0')                               when READY,
			  std_logic_vector(unsigned(addr_internal) + 1) when others;
	addr_e <= '1' when (state_q = READY or state_q = WRITE_LIT or state_q = WRITE_COPY) else '0';
	addr_sub_dist <= std_logic_vector(unsigned(addr_internal) - (copy_dist_base_q + to_integer(unsigned(copy_dist_eb_u))));

	huffman_reset <= '0' when ((state_q = READ_CODE or state_q = COPY_DIST) and huffman_output_changed = '0') else '1';
	huffman_output_changed <= huffman_last_output_change_q xor huffman_output_change;
	with state_q select
		node_content <= node_content_dist   when COPY_DIST,
				node_content_litlen when others;

	copy_len_base_e <= '1' when (state_q = COPY_LEN_I) else '0';
	with to_integer(unsigned(huffman_output)) select
		copy_len_base_d <= 3 when 257,
				   4 when 258,
				   5 when 259,
				   6 when 260,
				   7 when 261,
				   8 when 262,
				   9 when 263,
				  10 when 264,
				  11 when 265,
				  13 when 266,
				  15 when 267,
				  17 when 268,
				  19 when 269,
				  23 when 270,
				  27 when 271,
				  31 when 272,
				  35 when 273,
				  43 when 274,
				  51 when 275,
				  59 when 276,
				  67 when 277,
				  83 when 278,
				  99 when 279,
				 115 when 280,
				 131 when 281,
				 163 when 282,
				 195 when 283,
				 227 when 284,
				 258 when 285,
				   0 when others;

	with state_q select
		copy_len_eb_remaining_bits_d <= copy_len_eb_remaining_bits_di  when COPY_LEN_I,
						copy_len_eb_remaining_bits_dec when others;
	copy_len_eb_remaining_bits_e <= '1' when (state_q = COPY_LEN_I or state_q = COPY_LEN_EB) else '0';
	copy_len_eb_remaining_bits_dec <= copy_len_eb_remaining_bits_q - 1;
	with to_integer(unsigned(huffman_output)) select
		copy_len_eb_remaining_bits_di <= 0 - 1 when 257,
						 0 - 1 when 258,
						 0 - 1 when 259,
						 0 - 1 when 260,
						 0 - 1 when 261,
						 0 - 1 when 262,
						 0 - 1 when 263,
						 0 - 1 when 264,
						 1 - 1 when 265,
						 1 - 1 when 266,
						 1 - 1 when 267,
						 1 - 1 when 268,
						 2 - 1 when 269,
						 2 - 1 when 270,
						 2 - 1 when 271,
						 2 - 1 when 272,
						 3 - 1 when 273,
						 3 - 1 when 274,
						 3 - 1 when 275,
						 3 - 1 when 276,
						 4 - 1 when 277,
						 4 - 1 when 278,
						 4 - 1 when 279,
						 4 - 1 when 280,
						 5 - 1 when 281,
						 5 - 1 when 282,
						 5 - 1 when 283,
						 5 - 1 when 284,
						 0 - 1 when 285,
						 0 - 1 when others;

	with state_q select
		copy_len_eb_d <= input & copy_len_eb_q(4 downto 1) when COPY_LEN_EB,
				 (others => '0')                   when others;
	copy_len_eb_e <= '1' when (state_q = COPY_LEN_I or state_q = COPY_LEN_EB) else '0';
	copy_len_eb_u <= std_logic_vector(shift_right(unsigned(copy_len_eb_q), copy_len_eb_shift_offset_q));

	copy_len_eb_shift_offset_d <= 5 - copy_len_eb_remaining_bits_di - 1;
	copy_len_eb_shift_offset_e <= '1' when (state_q = COPY_LEN_I) else '0';

	copy_dist_base_e <= '1' when (state_q = COPY_DIST_I) else '0';
	with to_integer(unsigned(huffman_output)) select
		copy_dist_base_d <= 1 when 0,
				    2 when 1,
				    3 when 2,
				    4 when 3,
				    5 when 4,
				    7 when 5,
				    9 when 6,
				   13 when 7,
				   17 when 8,
				   25 when 9,
				   33 when 10,
				   49 when 11,
				   65 when 12,
				   97 when 13,
				  129 when 14,
				  193 when 15,
				  257 when 16,
				  385 when 17,
				  513 when 18,
				  769 when 19,
				 1025 when 20,
				 1537 when 21,
				 2049 when 22,
				 3073 when 23,
				 4097 when 24,
				 6145 when 25,
				 8193 when 26,
				12289 when 27,
				16385 when 28,
				24577 when 29,
				    0 when others;

	with state_q select
		copy_dist_eb_remaining_d <= copy_dist_eb_remaining_di  when COPY_DIST_I,
					    copy_dist_eb_remaining_dec when others;
	copy_dist_eb_remaining_e <= '1' when (state_q = COPY_DIST_I or state_q = COPY_DIST_EB) else '0';
	copy_dist_eb_remaining_dec <= copy_dist_eb_remaining_q - 1;
	with to_integer(unsigned(huffman_output)) select
		copy_dist_eb_remaining_di <= 0 - 1 when 0,
					     0 - 1 when 1,
					     0 - 1 when 2,
					     0 - 1 when 3,
					     1 - 1 when 4,
					     1 - 1 when 5,
					     2 - 1 when 6,
					     2 - 1 when 7,
					     3 - 1 when 8,
					     3 - 1 when 9,
					     4 - 1 when 10,
					     4 - 1 when 11,
					     5 - 1 when 12,
					     5 - 1 when 13,
					     6 - 1 when 14,
					     6 - 1 when 15,
					     7 - 1 when 16,
					     7 - 1 when 17,
					     8 - 1 when 18,
					     8 - 1 when 19,
					     9 - 1 when 20,
					     9 - 1 when 21,
					    10 - 1 when 22,
					    10 - 1 when 23,
					    11 - 1 when 24,
					    11 - 1 when 25,
					    12 - 1 when 26,
					    12 - 1 when 27,
					    13 - 1 when 28,
					    13 - 1 when 29,
					     0 - 1 when others;

	with state_q select
		copy_dist_eb_d <= input & copy_dist_eb_q(12 downto 1) when COPY_DIST_EB,
				  (others => '0')                     when others;
	copy_dist_eb_e <= '1' when (state_q = COPY_DIST_I or state_q = COPY_DIST_EB) else '0';
	copy_dist_eb_u <= std_logic_vector(shift_right(unsigned(copy_dist_eb_q), copy_dist_eb_shift_offset_q));

	copy_dist_eb_shift_offset_d <= 13 - copy_dist_eb_remaining_di - 1;
	copy_dist_eb_shift_offset_e <= '1' when (state_q = COPY_DIST_I) else '0';

	copy_current_byte_d <= data_q;
	copy_current_byte_e <= '1' when (state_q = READ_COPY) else '0';

	copy_len_done_e <= '1' when (state_q = WRITE_COPY or state_q = COPY_LEN_I) else '0';
	with state_q select
		copy_len_done_d <= 0                   when COPY_LEN_I,
				   copy_len_done_q + 1 when others;

	should_write_literal <= '1' when (unsigned(huffman_output) < 256 and state_q = READ_CODE) else '0';
	should_write_copy <= '1' when (unsigned(huffman_output) > 256 and state_q = READ_CODE) else '0';
	should_end <= '1' when (unsigned(huffman_output) = 256 and state_q = READ_CODE) else '0';
	write_lit_finished <= '1' when (state_q = WRITE_LIT) else '0';
	copy_len_i_finished <= '1' when (state_q = COPY_LEN_I) else '0';
	copy_len_bypass_eb <= '1' when (state_q = COPY_LEN_I and copy_len_eb_remaining_bits_d = -1) else '0';
	copy_len_eb_finished <= '1' when (state_q = COPY_LEN_EB and copy_len_eb_remaining_bits_q = 0) else '0';
	copy_dist_finished <= '1' when (state_q = COPY_DIST) else '0';
	copy_dist_i_finished <= '1' when (state_q = COPY_DIST_I) else '0';
	copy_dist_bypass_eb <= '1' when (state_q = COPY_DIST_I and copy_dist_eb_remaining_d = -1) else '0';
	copy_dist_eb_finished <= '1' when (state_q = COPY_DIST_EB and copy_dist_eb_remaining_q = 0) else '0';
	read_copy_finished <= '1' when (state_q = READ_COPY) else '0';
	write_copy_finished <= '1' when (state_q = WRITE_COPY) else '0';
	write_copy_all_finished <= '1' when (state_q = WRITE_COPY and copy_len_done_q = (copy_len_base_q + to_integer(unsigned(copy_len_eb_u)) - 1)) else '0';

	-- TODO : Simplify and make clearer this logic
	state_s <= go &
		   huffman_output_changed & should_write_literal & should_write_copy & should_end &
		   write_lit_finished &
		   copy_len_i_finished & copy_len_bypass_eb & copy_len_eb_finished &
		   copy_dist_finished & copy_dist_i_finished & copy_dist_bypass_eb & copy_dist_eb_finished &
		   read_copy_finished & write_copy_finished & write_copy_all_finished;
	with state_s select
		state_d <= READ_CODE    when "1000000000000000",
			   WRITE_LIT    when "0110000000000000",
			   COPY_LEN_I   when "0101000000000000",
			   COPY_LEN_EB  when "0000001000000000",
			   COPY_DIST    when "0000001100000000",
			   COPY_DIST    when "0000000010000000",
			   COPY_DIST_I  when "0100000001000000",
			   COPY_DIST_EB when "0000000000100000",
			   READ_COPY    when "0000000000110000",
			   READ_COPY    when "0000000000001000",
			   WRITE_COPY   when "0000000000000100",
			   READ_COPY    when "0000000000000010",
			   READ_CODE    when "0000000000000011",
			   READY        when "0100100000000000",
			   READ_CODE    when "0000010000000000",
			   state_q      when others;
end architecture;
