library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Decrypt_FSM is
    Port (
        clk                 : in STD_LOGIC;
        reset               : in STD_LOGIC;
        start               : in STD_LOGIC;
        done_op             : in STD_LOGIC; -- Signals completion of the current operation
        round_counter       : out INTEGER;  -- Counts the rounds from 1 to 9
        state_done          : out STD_LOGIC; -- Indicates completion of the decryption process
        cntrl_inv_shift_rows: out STD_LOGIC;
        cntrl_inv_sub_bytes : out STD_LOGIC;
        cntrl_add_round_key : out STD_LOGIC;
        cntrl_inv_mix_columns: out STD_LOGIC
    );
end Decrypt_FSM;

architecture Behavioral of Decrypt_FSM is
    -- State type declaration
    type state_type is (
        INV_SHIFT_ROWS, INV_SUB_BYTES, ADD_ROUND_KEY, INV_MIX_COLUMNS
    );

    signal cur_state, next_state : state_type := ADD_ROUND_KEY;
    signal round_ctr             : INTEGER := 0; -- Initialize round counter
    signal increment_round       : std_logic := '0'; -- Signal to increment round counter
--    signal ctr : integer;
begin
    -- Sequential block: State transition based on clock and reset
    process (clk, reset)
    begin
        if reset = '1' then
            cur_state <= ADD_ROUND_KEY;
            round_ctr <= 0;
        elsif rising_edge(clk) then
             
            cur_state <= next_state;
            -- Increment round counter when increment_round signal is set
            if increment_round = '1' then
                round_ctr <= round_ctr + 1;
            end if;
 
        end if;
    end process;

    -- Combinational block: State logic, control signals, and round counter increment logic
    process (cur_state, start, done_op, round_ctr)
    begin
        -- Default values for control signals and increment_round
        cntrl_inv_shift_rows <= '0';
        cntrl_inv_sub_bytes <= '0';
        cntrl_add_round_key <= '0';
        cntrl_inv_mix_columns <= '0';
        state_done <= '0';
        increment_round <= '0';

        -- Default next state is the current state
        next_state <= cur_state;

        -- Initial Round Logic
        if round_ctr = 0 then
            state_done <= '0';
            case cur_state is
                when ADD_ROUND_KEY =>
                    cntrl_add_round_key <= '1';
                    if done_op = '1' then
                        next_state <= INV_SHIFT_ROWS;
                        increment_round <= '1';
                    end if;
                when others => null;
            end case;

        -- Main Rounds (1 to 8): InvShiftRows, InvSubBytes, AddRoundKey, InvMixColumns
        elsif round_ctr <= 8 then
            case cur_state is
                when INV_SHIFT_ROWS =>
                    cntrl_inv_shift_rows <= '1';
                    if done_op = '1' then
                        next_state <= INV_SUB_BYTES;
                    end if;
                
                when INV_SUB_BYTES =>
                    cntrl_inv_sub_bytes <= '1';
                    if done_op = '1' then
                        next_state <= ADD_ROUND_KEY;
                    end if;

                when ADD_ROUND_KEY =>
                    cntrl_add_round_key <= '1';
                    if done_op = '1' then
                        next_state <= INV_MIX_COLUMNS;
                    end if;

                when INV_MIX_COLUMNS =>
                    cntrl_inv_mix_columns <= '1';
                    if done_op = '1' then
                        next_state <= INV_SHIFT_ROWS;
                        increment_round <= '1';
                    end if;
            end case;

        -- Final Round (Round 9): InvShiftRows, InvSubBytes, AddRoundKey (No InvMixColumns)
        elsif round_ctr = 9 then
            case cur_state is
                when INV_SHIFT_ROWS =>
                    cntrl_inv_shift_rows <= '1';
                    if done_op = '1' then
                        next_state <= INV_SUB_BYTES;
                    end if;

                when INV_SUB_BYTES =>
                    cntrl_inv_sub_bytes <= '1';
                    if done_op = '1' then
                        next_state <= ADD_ROUND_KEY;
                    end if;

                when ADD_ROUND_KEY =>
                    cntrl_add_round_key <= '1';
                    if done_op = '1' then
                        state_done <= '1'; -- Decryption complete
                        next_state <= ADD_ROUND_KEY; -- Hold in add_round_key state
                        increment_round <= '1'; -- Final increment
                    end if;
                
                when others => 
                state_done <= '1';
            end case;
        end if;
    end process;

    -- Output assignment
    round_counter <= round_ctr;

end Behavioral;
