library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux4x1 is
    Port (
        sel     : in  STD_LOGIC_VECTOR(1 downto 0);  
        in1x4      : in  STD_LOGIC_VECTOR(7 downto 0);  
        in2x4      : in  STD_LOGIC_VECTOR(7 downto 0);  
        in3x4       : in  STD_LOGIC_VECTOR(7 downto 0);  
        in4x4       : in  STD_LOGIC_VECTOR(7 downto 0);  
        mux_out : out STD_LOGIC_VECTOR(7 downto 0)   
    );
end mux4x1;

architecture Behavioral of mux4x1 is
begin
    process (sel, in1x4, in2x4, in3x4, in4x4)
    begin
        case sel is
            when "00" =>
                mux_out <= in1x4; 
            when "01" =>
                mux_out <= in2x4;  
            when "10" =>
                mux_out <= in3x4;  
            when "11" =>
                mux_out <= in4x4;  
            when others =>
                mux_out <= in1x4;
        end case;
    end process;
end Behavioral;