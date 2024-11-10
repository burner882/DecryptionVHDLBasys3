library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity compute_all is
  Port (
    clk           : in std_logic;
    rst           : in std_logic;
    -- Control signals for each operation
    cntrl_invmixcol    : in std_logic;
    cntrl_invsubbyte   : in std_logic;
    cntrl_xor          : in std_logic;
    cntrl_invrow       : in std_logic;
    -- Additional inputs
    addr_in            : in std_logic_vector(10 downto 0); -- Base address input
    round_ctr          : in integer; -- Round counter for compute_xor
    n : in integer;
    -- FSM state_done signal
--    state_done         : in std_logic; -- Indicates completion of the decryption process
    -- Outputs
    done               : out std_logic;
    counts             : out integer; -- For debug purposes
    -- Debug outputs
    debug_out          : out std_logic_vector(31 downto 0);
    debug_out2         : out std_logic_vector(31 downto 0);
    dout_bramm         : out std_logic_vector(7 downto 0);
    -- Display outputs
    anodes             : out std_logic_vector(3 downto 0);
    cathodes           : out std_logic_vector(6 downto 0)
  );
end compute_all;
architecture Behavioral of compute_all is

  -- Shared BRAM component
  component bram is
    Port (
      clk   : in std_logic;
      rst   : in std_logic;
      ena   : in std_logic;
      we    : in std_logic_vector(0 downto 0);
      addr  : in std_logic_vector(10 downto 0);
      din   : in std_logic_vector(7 downto 0);
      dout  : out std_logic_vector(7 downto 0)
    );
  end component;
  component mux4x1 is
    Port (
      sel     : in  STD_LOGIC_VECTOR(1 downto 0);
      in1x4   : in  STD_LOGIC_VECTOR(7 downto 0);
      in2x4   : in  STD_LOGIC_VECTOR(7 downto 0);
      in3x4   : in  STD_LOGIC_VECTOR(7 downto 0);
      in4x4   : in  STD_LOGIC_VECTOR(7 downto 0);
      mux_out : out STD_LOGIC_VECTOR(7 downto 0)
    );
  end component;

  component Timing_block is
    Port (
      clk_in      : in  STD_LOGIC;
      reset       : in  STD_LOGIC;
      mux_select  : out STD_LOGIC_VECTOR (1 downto 0);
      anodes      : out STD_LOGIC_VECTOR (3 downto 0)
    );
  end component;

  component decoder is
    Port (
      sel     : in  STD_LOGIC_VECTOR(7 downto 0);
      dec_out : out STD_LOGIC_VECTOR(6 downto 0)
    );
  end component;
  -- GF Multiplier component
  component gf_multiplier is
    Port (
      a      : in std_logic_vector(7 downto 0);
      b      : in std_logic_vector(7 downto 0);
      result : out std_logic_vector(7 downto 0)
    );
  end component;

  -- SBOX_INV component
  component SBOX_INV is
    Port (
      clkin : in std_logic;
      en    : in std_logic;
      a     : in std_logic_vector(7 downto 0);
      b     : out std_logic_vector(7 downto 0)
    );
  end component;

  -- ROM_KEY component
  component rom_key is
    Port (
      clkin : in std_logic;
      en    : in std_logic;
      a     : in std_logic_vector(7 downto 0);
      b     : out std_logic_vector(7 downto 0)
    );
  end component;

  -- InvRowShift component
  component InvRowShift is
    Port (
      in_array  : in std_logic_vector(31 downto 0);
      blk       : in std_logic_vector(1 downto 0);
      out_array : out std_logic_vector(31 downto 0)
    );
  end component;

  -- BRAM signals
  signal en_bram   : std_logic := '0';
  signal we_bram   : std_logic_vector(0 downto 0) := "0";
  signal addr_bram : std_logic_vector(10 downto 0) := (others => '0');
  signal din_bram  : std_logic_vector(7 downto 0) := (others => '0');
  signal dout_bram : std_logic_vector(7 downto 0);

  -- Control signal to select the active operation
  signal operation_select : std_logic_vector(1 downto 0);

  -- Address input as integer
  signal addr_in_int : integer := 0;

  -- Constants
  constant READ_LATENCY   : integer := 4; -- Adjust as needed
  constant WRITE_LATENCY  : integer := 6; -- Adjust as needed

  -- Internal signals for each operation

  -- Signals for compute_invmixcol
  signal current_column_invmixcol  : std_logic_vector(31 downto 0) := (others => '0');
  signal result_column_invmixcol   : std_logic_vector(31 downto 0) := (others => '0');
  signal column_count_invmixcol    : integer range 0 to 3 := 0;
  signal byte_count_invmixcol      : integer range 0 to 3 := 0;
  signal wait_counter_invmixcol    : integer := 0;
  signal operation_step_invmixcol  : integer range 0 to 6 := 0;
  signal gf_a_invmixcol            : std_logic_vector(7 downto 0) := (others => '0');
  signal gf_b_invmixcol            : std_logic_vector(7 downto 0) := (others => '0');
  signal gf_result_invmixcol       : std_logic_vector(7 downto 0) := (others => '0');
  type byte_array is array (0 to 3) of std_logic_vector(7 downto 0);
  signal temp_results_invmixcol    : byte_array := (others => (others => '0'));
  signal calc_index_invmixcol      : integer range 0 to 3 := 0;
  signal calc_state_invmixcol      : integer range 0 to 1 := 0;
  signal current_bytes_invmixcol   : byte_array;

  -- Constants for InvMixColumns
  type matrix_array is array (0 to 3, 0 to 3) of std_logic_vector(7 downto 0);
  constant inv_mix_matrix : matrix_array := (
    (x"0E", x"0B", x"0D", x"09"),
    (x"09", x"0E", x"0B", x"0D"),
    (x"0D", x"09", x"0E", x"0B"),
    (x"0B", x"0D", x"09", x"0E")
  );

  -- Signals for compute_invsubbyte
  signal current_invsubbyte         : std_logic_vector(7 downto 0);
  signal invsubbyte_value           : std_logic_vector(7 downto 0);
  signal en_invsubbyte              : std_logic := '0';
  signal count_invsubbyte           : integer range 0 to 15 := 0;
  signal wait_counter_invsubbyte    : integer := 0;
  signal operation_step_invsubbyte  : integer range 0 to 6 := 0;

  -- Signals for compute_xor
  signal current_xor          : std_logic_vector(7 downto 0);
  signal to_xor_xor           : std_logic_vector(7 downto 0);
  signal result_xor           : std_logic_vector(7 downto 0);
  signal en_rom_xor           : std_logic := '0';
  signal count_xor            : integer range 0 to 15 := 0;
  signal wait_counter_xor     : integer := 0;
  signal operation_step_xor   : integer range 0 to 6 := 0;
  signal addr_offset_xor      : integer := 0;
  signal addr_rom_xor         : std_logic_vector(7 downto 0);

  -- Signals for compute_invrow
  signal current_row_invrow    : std_logic_vector(31 downto 0) := (others => '0');
  signal rotated_row_invrow    : std_logic_vector(31 downto 0) := (others => '0');
  signal row_count_invrow      : integer range 0 to 3 := 0;
  signal byte_count_invrow     : integer range 0 to 3 := 0;
  signal wait_counter_invrow   : integer := 0;
  signal operation_step_invrow : integer range 0 to 6 := 0;
  signal blk_invrow            : std_logic_vector(1 downto 0);

  signal mux_select    : STD_LOGIC_VECTOR(1 downto 0);
  signal mux_out       : STD_LOGIC_VECTOR(7 downto 0);
  signal decoded_out   : STD_LOGIC_VECTOR(6 downto 0);
  signal in1x4, in2x4, in3x4, in4x4 : std_logic_vector(7 downto 0);
  signal enable_display : std_logic := '0';

---- One-second timer signals
  signal one_second_pulse : STD_LOGIC := '0';
  signal second_counter   : integer := 0;
  constant ONE_SECOND_COUNT : integer := 50000000; -- Adjust for your clock frequency

--  -- Display counter
  signal display_counter : integer  := 0;

begin
 timing_block_inst : entity work.Timing_block
    port map (
      clk_in     => clk,
      reset      => rst,
      mux_select => mux_select,
      anodes     => anodes
    );

--   Instantiate mux4x1
  mux4x1_inst : entity work.mux4x1
    port map (
      sel     => mux_select,
      in1x4   => in1x4,
      in2x4   => in2x4,
      in3x4   => in3x4,
      in4x4   => in4x4,
      mux_out => mux_out
    );

--  -- Instantiate decoder
  decoder_inst : entity work.decoder
    port map (
      sel     => mux_out,
      dec_out => decoded_out
    );

  -- Instantiate the shared BRAM
  shared_bram: bram
    port map (
      clk   => clk,
      rst   => rst,
      ena   => en_bram,
      we    => we_bram,
      addr  => addr_bram,
      din   => din_bram,
      dout  => dout_bram
    );

  -- Instantiate GF Multiplier
  gf_mult_inst: gf_multiplier
    port map (
      a      => gf_a_invmixcol,
      b      => gf_b_invmixcol,
      result => gf_result_invmixcol
    );

  -- Instantiate SBOX_INV
  sbox_inv_inst: SBOX_INV
    port map (
      clkin => clk,
      en    => en_invsubbyte,
      a     => current_invsubbyte,
      b     => invsubbyte_value
    );

  -- Instantiate ROM_KEY
  rom_key_inst: rom_key
    port map (
      clkin => clk,
      en    => en_rom_xor,
      a     => addr_rom_xor,
      b     => to_xor_xor
    );

  -- Instantiate InvRowShift
  invrowshift_inst: InvRowShift
    port map (
      in_array  => current_row_invrow,
      blk       => blk_invrow,
      out_array => rotated_row_invrow
    );

  -- Decode addr_in to integer
  addr_in_int <= to_integer(unsigned(addr_in));

  -- Control signal to select the active operation
  process(cntrl_invmixcol, cntrl_invsubbyte, cntrl_xor, cntrl_invrow)
  begin
    if cntrl_invmixcol = '1' then
      operation_select <= "00";
    elsif cntrl_invsubbyte = '1' then
      operation_select <= "01";
    elsif cntrl_xor = '1' then
      operation_select <= "10";
    elsif cntrl_invrow = '1' then
      operation_select <= "11";
    else
      operation_select <= "ZZ"; -- No operation selected
    end if;
    
  end process;

  -- Assign bytes of current_column_invmixcol to current_bytes_invmixcol for easier access
  current_bytes_invmixcol(0) <= current_column_invmixcol(31 downto 24);
  current_bytes_invmixcol(1) <= current_column_invmixcol(23 downto 16);
  current_bytes_invmixcol(2) <= current_column_invmixcol(15 downto 8);
  current_bytes_invmixcol(3) <= current_column_invmixcol(7 downto 0);

  -- Main process
  process(clk, rst)
  begin
    if rst = '1' then
      -- Reset all signals for all operations
      done <= '0';
      counts <= 0;
      en_bram <= '0';
      -- Reset signals for compute_invmixcol
      column_count_invmixcol   <= 0;
      byte_count_invmixcol     <= 0;
      wait_counter_invmixcol   <= 0;
      operation_step_invmixcol <= 0;
      temp_results_invmixcol   <= (others => (others => '0'));
      calc_index_invmixcol     <= 0;
      calc_state_invmixcol     <= 0;
      -- Reset signals for compute_invsubbyte
      count_invsubbyte          <= 0;
      wait_counter_invsubbyte   <= 0;
      operation_step_invsubbyte <= 0;
      en_invsubbyte             <= '0';
      -- Reset signals for compute_xor
      count_xor          <= 0;
      addr_offset_xor    <= 144;
      wait_counter_xor   <= 0;
      operation_step_xor <= 0;
      en_rom_xor         <= '0';
      -- Reset signals for compute_invrow
      row_count_invrow      <= 0;
      byte_count_invrow     <= 0;
      wait_counter_invrow   <= 0;
      operation_step_invrow <= 0;
    elsif rising_edge(clk) then
      -- Default BRAM signals
--      en_bram <= '0';
--      we_bram <= "0";
--      addr_bram <= (others => '0');
--      din_bram <= (others => '0');
      -- Depending on the operation_select, execute the corresponding code
      if round_ctr = 10 then 
      en_bram <= '1';
      case mux_select is
        when "00" => addr_bram <= std_logic_vector(to_unsigned(display_counter * 4, 11));
        when "01" => addr_bram <= std_logic_vector(to_unsigned(display_counter * 4 + 1, 11));
        when "10" => addr_bram <= std_logic_vector(to_unsigned(display_counter * 4 + 2, 11));
        when "11" => addr_bram <= std_logic_vector(to_unsigned(display_counter * 4 + 3, 11));
        when others => addr_bram <= (others => '0');
      end case;
      end if;
      case operation_select is
        when "00" =>  -- compute_invmixcol
          -- [Include the complete code for compute_invmixcol here]
          -- Compute InvMixColumns operation
          if operation_step_invmixcol = 0 then
            -- Initialization
            if cntrl_invmixcol = '1' then
              column_count_invmixcol   <= 0;
              byte_count_invmixcol     <= 0;
              wait_counter_invmixcol   <= 0;
              operation_step_invmixcol <= 1; -- Move to READ step
              done <= '0';
            end if;
          else
            -- Include the state machine of compute_invmixcol
            case operation_step_invmixcol is
              -- Implement all steps as per the full code for compute_invmixcol
              -- [The code for compute_invmixcol has been fully included here, as requested]
              
              -- READ Step
              when 1 =>
                en_bram <= '1';
                we_bram <= "0"; -- Read mode
                addr_bram <= std_logic_vector(to_unsigned(addr_in_int + column_count_invmixcol + byte_count_invmixcol * 4, addr_bram'length));
                operation_step_invmixcol <= 2; -- Move to WAIT_READ step

              -- WAIT_READ Step
              when 2 =>
                if wait_counter_invmixcol < READ_LATENCY - 1 then
                  wait_counter_invmixcol <= wait_counter_invmixcol + 1;
                else
                  wait_counter_invmixcol <= 0;
                  en_bram <= '0';
                  -- Store byte in current_column
                  case byte_count_invmixcol is
                    when 0 => current_column_invmixcol(31 downto 24) <= dout_bram;
                    when 1 => current_column_invmixcol(23 downto 16) <= dout_bram;
                    when 2 => current_column_invmixcol(15 downto 8)  <= dout_bram;
                    when 3 => current_column_invmixcol(7 downto 0)   <= dout_bram;
                  end case;
                  if byte_count_invmixcol < 3 then
                    byte_count_invmixcol <= byte_count_invmixcol + 1;
                    operation_step_invmixcol <= 1; -- Continue reading
                  else
                    byte_count_invmixcol <= 0; -- Reset byte_count for calculation
                    calc_index_invmixcol <= 0;
                    temp_results_invmixcol <= (others => (others => '0')); -- Reset temp_results
                    calc_state_invmixcol <= 0;
                    operation_step_invmixcol <= 3; -- Move to CALCULATE step
                  end if;
                end if;

              -- CALCULATE Step
              when 3 =>
                if byte_count_invmixcol < 4 then
                  if calc_index_invmixcol < 4 then
                    if calc_state_invmixcol = 0 then
                      -- Set up multiplication
                      gf_a_invmixcol <= inv_mix_matrix(byte_count_invmixcol, calc_index_invmixcol);
                      gf_b_invmixcol <= current_bytes_invmixcol(calc_index_invmixcol);
                      calc_state_invmixcol <= 1;
                    else
                      -- Accumulate result after multiplication
                      temp_results_invmixcol(byte_count_invmixcol) <= temp_results_invmixcol(byte_count_invmixcol) xor gf_result_invmixcol;
                      calc_index_invmixcol <= calc_index_invmixcol + 1;
                      calc_state_invmixcol <= 0;
                    end if;
                  else
                    -- Move to next byte
                    calc_index_invmixcol <= 0;
                    if byte_count_invmixcol < 3 then
                      byte_count_invmixcol <= byte_count_invmixcol + 1;
                      operation_step_invmixcol <= 3;
                    else
                      byte_count_invmixcol <= 0;
                      operation_step_invmixcol <= 4; -- Move to WRITE step
                    end if;
                  end if;
                end if;

              -- WRITE Step
              when 4 =>
                en_bram <= '1';
                we_bram <= "1"; -- Write mode
                addr_bram <= std_logic_vector(to_unsigned(addr_in_int + column_count_invmixcol + byte_count_invmixcol * 4, addr_bram'length));
                case byte_count_invmixcol is
                  when 0 => din_bram <= temp_results_invmixcol(0);
                  when 1 => din_bram <= temp_results_invmixcol(1);
                  when 2 => din_bram <= temp_results_invmixcol(2);
                  when 3 => din_bram <= temp_results_invmixcol(3);
                end case;
                operation_step_invmixcol <= 5; -- Move to WAIT_WRITE step

              -- WAIT_WRITE Step
              when 5 =>
                if wait_counter_invmixcol < WRITE_LATENCY - 1 then
                  wait_counter_invmixcol <= wait_counter_invmixcol + 1;
                else
                en_bram <= '0';
                we_bram <= "0";
                  wait_counter_invmixcol <= 0;
                  if byte_count_invmixcol < 3 then
                    byte_count_invmixcol <= byte_count_invmixcol + 1;
                    operation_step_invmixcol <= 4; -- Continue writing
                  else
                    byte_count_invmixcol <= 0;
                    if column_count_invmixcol < 3 then
                      column_count_invmixcol <= column_count_invmixcol + 1;
                      operation_step_invmixcol <= 1; -- Back to READ step
                    else
                      operation_step_invmixcol <= 6; -- Move to DONE step
                    end if;
                  end if;
                end if;

              -- DONE Step
              when 6 =>
                -- Operation complete
                -- Remain in done state
                done <= '1';
               operation_step_invmixcol <= 0;
              when others =>
                operation_step_invmixcol <= 0;
            end case;
          end if;
          -- Set debug outputs
          debug_out <= temp_results_invmixcol(0) & temp_results_invmixcol(1) & temp_results_invmixcol(2) & temp_results_invmixcol(3);
          debug_out2 <= current_column_invmixcol;
          counts <= column_count_invmixcol; -- For debug purposes

when "01" => -- compute_invsubbyte
          -- Compute InvSubByte operation
          if operation_step_invsubbyte = 0 then
            if cntrl_invsubbyte = '1' then
              count_invsubbyte          <= 0;
              operation_step_invsubbyte <= 1; -- Move to read step
              done <= '0';
            end if;
          else
            case operation_step_invsubbyte is
              when 1 => -- Enable read from BRAM
                addr_bram <= std_logic_vector(to_unsigned(addr_in_int + count_invsubbyte, addr_bram'length));
                en_bram <= '1';
                we_bram <= "0"; -- Read mode
                wait_counter_invsubbyte <= 0;
                operation_step_invsubbyte <= 2; -- Move to wait for read data
              when 2 => -- Wait for BRAM read data
                if wait_counter_invsubbyte < (READ_LATENCY - 1) then
                  wait_counter_invsubbyte <= wait_counter_invsubbyte + 1;
                else
                 en_bram <= '0';
                  wait_counter_invsubbyte <= 0;
                  current_invsubbyte <= dout_bram;
                  en_invsubbyte <= '1'; -- Enable invsubbyte operation
                  operation_step_invsubbyte <= 3; -- Move to wait for invsubbyte data
                end if;
              when 3 => -- Wait for invsubbyte result
                 if wait_counter_invsubbyte < (READ_LATENCY - 1) then
                  wait_counter_invsubbyte <= wait_counter_invsubbyte + 1;
                else
                 en_invsubbyte <= '0';
                  wait_counter_invsubbyte <= 0;
                operation_step_invsubbyte <= 4; -- Move to write step
              end if;
              when 4 => -- Write invsubbyte value to BRAM
                addr_bram <= std_logic_vector(to_unsigned(addr_in_int + count_invsubbyte, addr_bram'length));
                din_bram <= invsubbyte_value;
                en_bram <= '1';
                we_bram <= "1"; -- Write mode
                wait_counter_invsubbyte <= 0;
                operation_step_invsubbyte <= 5; -- Move to wait for write
              when 5 => -- Wait for write to complete
                if wait_counter_invsubbyte < (WRITE_LATENCY - 1) then
                  wait_counter_invsubbyte <= wait_counter_invsubbyte + 1;
                else
                en_bram <= '0';
                we_bram <= "0";
                  wait_counter_invsubbyte <= 0;
                  if count_invsubbyte < 15 then
                    count_invsubbyte <= count_invsubbyte + 1;
                    operation_step_invsubbyte <= 1; -- Next address
                  else
                    done <= '1'; -- Set done signal
                    operation_step_invsubbyte <= 0; -- Move to done step
                  end if;
                end if;
              when others => -- Done step
                operation_step_invsubbyte <= 0; 
            end case;
          end if;
          -- Set debug outputs
          debug_out <= std_logic_vector(resize(unsigned(invsubbyte_value), 32));
          debug_out2 <= std_logic_vector(resize(unsigned(current_invsubbyte), 32));
          counts <= count_invsubbyte;
        when "10" => -- compute_xor
          -- Compute XOR operation
          if operation_step_xor = 0 then
            if cntrl_xor = '1' then
              count_xor          <= 0;
              operation_step_xor <= 1; -- Move to read step
              done <= '0';
--              addr_offset_xor    <= (9 - round_ctr) * 16;
            end if;
          else
            case operation_step_xor is
              when 1 => -- Read from BRAM and ROM
                addr_offset_xor    <= (9 - round_ctr) * 16;
                en_bram <= '1';
                en_rom_xor <= '1';
                we_bram <= "0";
                addr_bram <= std_logic_vector(to_unsigned(addr_in_int + count_xor, addr_bram'length));
                addr_rom_xor <= std_logic_vector(to_unsigned(addr_offset_xor + count_xor, addr_rom_xor'length));
                wait_counter_xor <= 0;
                operation_step_xor <= 2; -- Move to wait for read data
              when 2 => -- Wait for read data
                if wait_counter_xor < (READ_LATENCY - 1) then
                  wait_counter_xor <= wait_counter_xor + 1;
                else
                en_bram <= '0';
                  wait_counter_xor <= 0;
                  current_xor <= dout_bram;
                  en_rom_xor <= '0';
                  operation_step_xor <= 3; -- Move to XOR step
                end if;
              when 3 => -- Perform XOR operation
                result_xor <= current_xor xor to_xor_xor;
                operation_step_xor <= 4; -- Move to write step
              when 4 => -- Write to BRAM
                en_bram <= '1';
                we_bram <= "1";
                addr_bram <= std_logic_vector(to_unsigned(addr_in_int + count_xor, addr_bram'length));
                din_bram <= result_xor;
                wait_counter_xor <= 0;
                operation_step_xor <= 5; -- Move to wait for write
              when 5 => -- Wait for write to complete
                if wait_counter_xor < (WRITE_LATENCY - 1) then
                  wait_counter_xor <= wait_counter_xor + 1;
                else
                  en_bram <= '0';
                we_bram <= "0";
                  wait_counter_xor <= 0;
                  if count_xor < 15 then
                    count_xor <= count_xor + 1;
                    operation_step_xor <= 1; -- Next address
                  else
                    done <= '1'; -- Set done signal
                    operation_step_xor <= 0; -- Move to done step
                     addr_offset_xor    <= (8 - round_ctr) * 16;
                  end if;
                end if;
              when others => -- Done step
                operation_step_xor <= 0;
            end case;
          end if;
          -- Set debug outputs
          debug_out <= std_logic_vector(resize(unsigned(result_xor), 32));
          debug_out2 <= std_logic_vector(resize(unsigned(current_xor), 32));
          counts <= count_xor;
        when "11" => -- compute_invrow
          -- Compute InvRowShift operation
          if operation_step_invrow = 0 then
            if cntrl_invrow = '1' then
              row_count_invrow      <= 0;
              byte_count_invrow     <= 0;
              wait_counter_invrow   <= 0;
              operation_step_invrow <= 1; -- Move to READ step
              done <= '0';
            end if;
          else
            case operation_step_invrow is
              when 1 =>
                en_bram <= '1';
                we_bram <= "0"; -- Read mode
                addr_bram <= std_logic_vector(to_unsigned(addr_in_int + row_count_invrow * 4 + byte_count_invrow, addr_bram'length));
                operation_step_invrow <= 2; -- Move to WAIT_READ step
              when 2 =>
                if wait_counter_invrow < READ_LATENCY - 1 then
                  wait_counter_invrow <= wait_counter_invrow + 1;
                else
                  wait_counter_invrow <= 0;
                   en_bram <= '0';
                  -- Store byte in current_row
                  case byte_count_invrow is
                    when 0 => current_row_invrow(31 downto 24) <= dout_bram;
                    when 1 => current_row_invrow(23 downto 16) <= dout_bram;
                    when 2 => current_row_invrow(15 downto 8)  <= dout_bram;
                    when 3 => current_row_invrow(7 downto 0)   <= dout_bram;
                  end case;
                  if byte_count_invrow < 3 then
                    byte_count_invrow <= byte_count_invrow + 1;
                    operation_step_invrow <= 1; -- Continue reading
                  else
                    byte_count_invrow <= 0; -- Reset byte_count for writing
                    operation_step_invrow <= 3; -- Move to ROTATE step
                  end if;
                end if;
              when 3 =>
                blk_invrow <= std_logic_vector(to_unsigned(row_count_invrow, blk_invrow'length));
                operation_step_invrow <= 4; -- Move to WRITE step
              when 4 =>
                en_bram <= '1';
                we_bram <= "1"; -- Write mode
                addr_bram <= std_logic_vector(to_unsigned(addr_in_int + row_count_invrow * 4 + byte_count_invrow, addr_bram'length));
                case byte_count_invrow is
                  when 0 => din_bram <= rotated_row_invrow(31 downto 24);
                  when 1 => din_bram <= rotated_row_invrow(23 downto 16);
                  when 2 => din_bram <= rotated_row_invrow(15 downto 8);
                  when 3 => din_bram <= rotated_row_invrow(7 downto 0);
                end case;
                operation_step_invrow <= 5; -- Move to WAIT_WRITE step
              when 5 =>
                if wait_counter_invrow < WRITE_LATENCY - 1 then
                  wait_counter_invrow <= wait_counter_invrow + 1;
                else
                en_bram <= '0';
                we_bram <= "0";
                  wait_counter_invrow <= 0;
                  if byte_count_invrow < 3 then
                    byte_count_invrow <= byte_count_invrow + 1;
                    operation_step_invrow <= 4; -- Continue writing
                  else
                    byte_count_invrow <= 0; -- Reset byte_count for next row
                    if row_count_invrow < 3 then
                      row_count_invrow <= row_count_invrow + 1;
                      operation_step_invrow <= 1; -- Move to READ step for next row
                    else
                      operation_step_invrow <= 0; -- Move to DONE step
                      done <= '1'; -- Operation complete
                    end if;
                  end if;
                end if;
              when others =>
               operation_step_invrow <= 0;
            end case;
          end if;
          -- Set debug outputs
          debug_out <= rotated_row_invrow;
          debug_out2 <= current_row_invrow;
          counts <= row_count_invrow;
        when others =>
          -- No operation selected
          done <= '0';
          counts <= 0;
          debug_out <= (others => '0');
          debug_out2 <= (others => '0');
      end case;
    end if;
  end process;
  
   -- One-second timer process
  process(clk, rst)
  begin
    if rst = '1' then
      second_counter <= 0;
      one_second_pulse <= '0';
    elsif rising_edge(clk) then
      if round_ctr = 10 then
        if second_counter = ONE_SECOND_COUNT - 1 then
          second_counter <= 0;
          one_second_pulse <= '1';
        else
          second_counter <= second_counter + 1;
          one_second_pulse <= '0';
        end if;
      else
        second_counter <= 0;
        one_second_pulse <= '0';
      end if;
    end if;
  end process;
--  -- Display counter update process
  process(clk, rst)
  begin
    if rst = '1' then
      display_counter <= 0;
    elsif rising_edge(clk) then
      if round_ctr = 10 then
        if one_second_pulse = '1' then
          if display_counter = 4*n-1 then
            display_counter <= 0;
          else
            display_counter <= display_counter + 1;
          end if;
        end if;
      else
        display_counter <= 0;
      end if;
    end if;
  end process;

--  -- Address assignment for each display within the group of four
--  process(mux_select, display_counter)
--  begin
--    if round_ctr = 10 then
--      case mux_select is
--        when "00" => addr_bram <= std_logic_vector(to_unsigned(display_counter * 4, 11));
--        when "01" => addr_bram <= std_logic_vector(to_unsigned(display_counter * 4 + 1, 11));
--        when "10" => addr_bram <= std_logic_vector(to_unsigned(display_counter * 4 + 2, 11));
--        when "11" => addr_bram <= std_logic_vector(to_unsigned(display_counter * 4 + 3, 11));
--        when others => addr_bram <= (others => '0');
--      end case;
--    end if;
--  end process;


--  -- Assign BRAM output to appropriate mux inputs
  process(clk)
  begin
    if rising_edge(clk) then
      if round_ctr = 10 then
        case mux_select is
          when "00" => in1x4 <= dout_bram;
          when "01" => in2x4 <= dout_bram;
          when "10" => in3x4 <= dout_bram;
          when "11" => in4x4 <= dout_bram;
          when others =>
            in1x4 <= (others => '0');
            in2x4 <= (others => '0');
            in3x4 <= (others => '0');
            in4x4 <= (others => '0');
        end case;
      else
        in1x4 <= (others => '0');
        in2x4 <= (others => '0');
        in3x4 <= (others => '0');
        in4x4 <= (others => '0');
      end if;
    end if;
  end process;

dout_bramm <= dout_bram;
  cathodes <= decoded_out;

end Behavioral;
