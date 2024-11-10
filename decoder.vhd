library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity decoder is
    Port (
        sel     : in  STD_LOGIC_VECTOR(7 downto 0);    
        dec_out : out STD_LOGIC_VECTOR(6 downto 0)   
    );
end decoder;

architecture Behavioral of decoder is
function hex_to_7seg(input : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable output : std_logic_vector(6 downto 0);
begin
    output(6) := ((not input(3) and not input(2) and not input(1) and input(0)) or
          (input(3) and input(2) and not input(1) and input(0)) or
          (not input(3) and input(2) and not input(1) and not input(0)) or
          (input(3) and not input(2) and input(1) and input(0)));

    output(5) := ((not input(3) and input(2) and not input(1) and input(0)) or
          (input(3) and input(2) and not input(1) and not input(0)) or
          (input(3) and input(1) and input(0)) or
          (input(2) and input(1) and not input(0)));

    output(4) := ((not input(3) and not input(2) and input(1) and not input(0)) or
          (input(3) and input(2) and not input(1) and not input(0)) or
          (input(3) and input(2) and input(1)));

    output(3) := ((not input(3) and not input(2) and not input(1) and input(0)) or
          (not input(3) and input(2) and not input(1) and not input(0)) or
          (input(3) and not input(2) and input(1) and not input(0)) or
          (input(2) and input(1) and input(0)));

    output(2) := ((not input(3) and input(2) and not input(1)) or
          (not input(2) and not input(1) and input(0)) or
          (not input(3) and input(0)));

    output(1) := ((input(3) and input(2) and not input(1) and input(0)) or
          (not input(3) and not input(2) and input(1)) or
          (not input(3) and not input(2) and input(0)) or
          (not input(3) and input(1) and input(0)));

    output(0) := ((not input(3) and not input(2) and not input(1)) or
          (not input(3) and input(2) and input(1) and input(0)) or
          (input(3) and input(2) and not input(1) and not input(0)));

    return output;
end function;
begin
    process (sel)
begin
    case sel is
        when x"00" | x"20" =>
            dec_out <= "1111111"; 
            
        when x"30" | x"31" | x"32" | x"33" | x"34" |
             x"35" | x"36" | x"37" | x"38" | x"39" =>
            dec_out <= hex_to_7seg(sel(3 downto 0)); 
            
        when x"41" | x"42" | x"43" | x"44" | x"45" | x"46" =>
            dec_out <= hex_to_7seg(std_logic_vector(to_unsigned(to_integer(unsigned(sel(2 downto 0))) +9, 4)));

        when x"61" | x"62" | x"63" | x"64" | x"65" | x"66" =>   
            dec_out <= hex_to_7seg(std_logic_vector(to_unsigned(to_integer(unsigned(sel(2 downto 0))) +9, 4)));

        when others =>
            dec_out <= "1111110";
    end case;
end process;

end Behavioral;