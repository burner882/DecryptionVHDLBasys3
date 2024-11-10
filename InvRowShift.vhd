library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity InvRowShift is
    Port (
        in_array : in std_logic_vector(31 downto 0);
        blk: in std_logic_vector(1 downto 0);
        out_array : out std_logic_vector(31 downto 0)
    );
end InvRowShift;

architecture Behavioral of InvRowShift is
    component mux4x1 is
        Port (
            sel     : in  STD_LOGIC_VECTOR(1 downto 0);
            in1x4  : in  STD_LOGIC_VECTOR(7 downto 0);
            in2x4  : in  STD_LOGIC_VECTOR(7 downto 0);
            in3x4  : in  STD_LOGIC_VECTOR(7 downto 0);
            in4x4  : in  STD_LOGIC_VECTOR(7 downto 0);
            mux_out : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    signal blk_int : integer range 0 to 3;
begin
    blk_int <= to_integer(unsigned(blk));
    generate_muxes : for counter in 0 to 3 generate
        mux4x1x : mux4x1
            port map (
                sel => std_logic_vector(to_unsigned(4+counter-blk_int - (((4+counter-blk_int)/4) * 4), 2)),
                in1x4 => in_array((31) downto (24)),
                in2x4 => in_array((23) downto (16)),
                in3x4 => in_array((15) downto (8)),
                in4x4 => in_array((7) downto (0)),
                mux_out => out_array(((3-counter)*8 + 7) downto ((3-counter)*8))  
            );
    end generate;

    -- Combine mux outputs into the final output array
    

end Behavioral;