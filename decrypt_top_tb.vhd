library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_Decrypt_Top is
--  Port ( );
end tb_Decrypt_Top;

architecture Behavioral of tb_Decrypt_Top is

  -- Component declaration for Decrypt_Top
  component Decrypt_Top is
    Port (
      clk          : in std_logic;
      reset        : in std_logic;
      start        : in std_logic;
      -- Output ports for observing results
--      state_done   : out std_logic;
--      debug_out    : out std_logic_vector(31 downto 0);
--      debug_out2   : out std_logic_vector(31 downto 0);
--      counts       : out integer;
--      round_ctr : out integer;
--      dout_bramm : out std_logic_vector(7 downto 0);
--      ctr1 : out std_logic;
--    ctr2 : out std_logic;
--    ctr3 : out std_logic;
--    ctr4 : out std_logic;
    anodes       : out std_logic_vector(3 downto 0);
    cathodes     : out std_logic_vector(6 downto 0)
    );
  end component;

  -- Signals to connect to Decrypt_Top
  signal clk          : std_logic := '0';
  signal reset        : std_logic := '1';
  signal start        : std_logic := '0';
  signal state_done   : std_logic;
  signal debug_out    : std_logic_vector(31 downto 0);
  signal debug_out2   : std_logic_vector(31 downto 0);
  signal counts       : integer;
  signal round_ctr : integer;
  signal dout_bramm : std_logic_vector(7 downto 0);
  -- Clock period definition
  constant CLK_PERIOD : time :=10 ns;
  signal ctr1 :  std_logic;
    signal ctr2 :  std_logic;
    signal ctr3 :  std_logic;
    signal ctr4 :  std_logic;
    signal anodes       : std_logic_vector(3 downto 0);
    signal cathodes     :  std_logic_vector(6 downto 0);

begin

  -- Instantiate Decrypt_Top
  uut : Decrypt_Top
    Port map (
      clk          => clk,
      reset        => reset,
      start        => start,
--      state_done   => state_done,
--      debug_out    => debug_out,
--      debug_out2   => debug_out2,
--      counts       => counts,
--      round_ctr => round_ctr,
--      dout_bramm => dout_bramm,
--      ctr1 => ctr1,
--      ctr2 => ctr2,
--      ctr3 => ctr3,
--      ctr4 => ctr4,
      anodes => anodes,
      cathodes => cathodes
     
    );

  -- Clock generation
  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process clk_process;

  -- Stimulus process
  stim_proc: process
  begin
    -- Initialize Inputs
    reset <= '1';
    start <= '0';

    -- Wait for global reset to finish
    wait for 20 ns;

    reset <= '0'; -- De-assert reset
    wait for CLK_PERIOD * 2;

    -- Start the decryption process
    start <= '1';
    wait for CLK_PERIOD;
    start <= '0';

    -- Wait for the decryption to complete
    wait until state_done = '1';

    -- Wait for a few more clock cycles to observe the outputs
    wait for CLK_PERIOD * 10;

    -- Finish simulation
    wait;
  end process stim_proc;

end Behavioral;
