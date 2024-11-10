library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Decrypt_Top is
  Port (
    clk          : in std_logic;
    reset        : in std_logic;
    start        : in std_logic;
    -- Output ports for observing results
--    state_done   : out std_logic;
--    -- Debug outputs
--    debug_out    : out std_logic_vector(31 downto 0);
--    debug_out2   : out std_logic_vector(31 downto 0);
--    counts       : out integer;
--    round_ctr    : out integer;
--    dout_bramm   : out std_logic_vector(7 downto 0);
--    ctr1         : out std_logic;
--    ctr2         : out std_logic;
--    ctr3         : out std_logic;
--    ctr4         : out std_logic;
    -- Display outputs
    anodes       : out std_logic_vector(3 downto 0);
    cathodes     : out std_logic_vector(6 downto 0)
  );
end Decrypt_Top;

architecture Behavioral of Decrypt_Top is

  -- Signals to connect between the modules
  signal done_op            : std_logic;
  signal round_counter      : integer;

  -- Control signals from Decrypt_FSM
  signal cntrl_inv_shift_rows : std_logic;
  signal cntrl_inv_sub_bytes  : std_logic;
  signal cntrl_add_round_key  : std_logic;
  signal cntrl_inv_mix_columns: std_logic;

  -- Control signals for compute_all
  signal cntrl_invmixcol    : std_logic;
  signal cntrl_invsubbyte   : std_logic;
  signal cntrl_xor          : std_logic;
  signal cntrl_invrow       : std_logic;

  -- Signals for compute_all outputs
  signal counts_internal    : integer;
  signal debug_out_internal : std_logic_vector(31 downto 0);
  signal debug_out2_internal: std_logic_vector(31 downto 0);
  signal dout_bramm_internal : std_logic_vector(7 downto 0);

  -- Address input
  signal addr_in            : std_logic_vector(10 downto 0) := (others => '0');

  -- Internal signals for multi-block processing
  signal reset_fsm_compute  : std_logic := '0';
  signal n                  : integer := 2;
  signal state_done_reg     : std_logic := '0';

begin

  -- Map control signals from Decrypt_FSM to compute_all
  cntrl_invmixcol  <= cntrl_inv_mix_columns;
  cntrl_invsubbyte <= cntrl_inv_sub_bytes;
  cntrl_xor        <= cntrl_add_round_key;
  cntrl_invrow     <= cntrl_inv_shift_rows;

  -- Instantiate Decrypt_FSM
  decrypt_fsm_inst : entity work.Decrypt_FSM
    port map (
      clk                  => clk,
      reset                => reset_fsm_compute,
      start                => start,
      done_op              => done_op, -- From compute_all
      round_counter        => round_counter,
      state_done           => state_done_reg,
      cntrl_inv_shift_rows => cntrl_inv_shift_rows,
      cntrl_inv_sub_bytes  => cntrl_inv_sub_bytes,
      cntrl_add_round_key  => cntrl_add_round_key,
      cntrl_inv_mix_columns=> cntrl_inv_mix_columns
    );

  -- Instantiate compute_all
  compute_all_inst : entity work.compute_all
    port map (
      clk             => clk,
      rst             => reset_fsm_compute,
      cntrl_invmixcol => cntrl_invmixcol,
      cntrl_invsubbyte=> cntrl_invsubbyte,
      cntrl_xor       => cntrl_xor,
      cntrl_invrow    => cntrl_invrow,
      addr_in         => addr_in,
      round_ctr       => round_counter,
      n               => n,
      done            => done_op,    -- To Decrypt_FSM
      counts          => counts_internal,
      debug_out       => debug_out_internal,
      debug_out2      => debug_out2_internal,
      dout_bramm      => dout_bramm_internal,
      anodes          => anodes,     -- Display outputs
      cathodes        => cathodes    -- Display outputs
    );

  -- Assign outputs
--  debug_out  <= debug_out_internal;
--  debug_out2 <= debug_out2_internal;
--  counts     <= counts_internal;
--  round_ctr  <= round_counter;
--  dout_bramm <= dout_bramm_internal;
--  ctr1       <= cntrl_xor;
--  ctr2       <= cntrl_invrow;
--  ctr3       <= cntrl_invmixcol;
--  ctr4       <= cntrl_invsubbyte;
--  state_done <= state_done_reg;

  -- Multi-block processing logic
  process(clk, reset)
  begin
    if reset = '1' then
      reset_fsm_compute <= '1';
      n <= 2; -- Set initial number of blocks
      addr_in <= (others => '0');
    elsif rising_edge(clk) then
      if state_done_reg = '1' and n > 1 then
        -- Reset FSM and compute unit for next block
        reset_fsm_compute <= '1';
        n <= n - 1; -- Decrement block count
        addr_in <= std_logic_vector(unsigned(addr_in) + 16); -- Increment address
      else
        reset_fsm_compute <= '0'; -- Keep FSM and compute unit active
      end if;
    end if;
  end process;

end Behavioral;
