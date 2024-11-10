
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gf_multiplier is
    Port (
        a : in std_logic_vector(7 downto 0);
        b : in std_logic_vector(7 downto 0);
        result : out std_logic_vector(7 downto 0) 
    );
end gf_multiplier;

architecture Behavioral of gf_multiplier is
    constant IRREDUCIBLE_POLY : std_logic_vector(7 downto 0) := x"1B"; 
begin
    process(a, b)
        variable temp_a : std_logic_vector(7 downto 0);
        variable temp_b : std_logic_vector(7 downto 0);
        variable p : std_logic_vector(7 downto 0); 
        variable high_bit : std_logic;
    begin
        temp_a := a;
        temp_b := b;
        p := (others => '0'); 
        
        for i in 0 to 7 loop
            if temp_b(0) = '1' then
                p := p xor temp_a;
            end if;
            temp_b := temp_b(7) & temp_b(7 downto 1); 
            
            high_bit := temp_a(7); 
            temp_a := temp_a(6 downto 0) & '0'; 

            if high_bit = '1' then
                temp_a := temp_a xor IRREDUCIBLE_POLY;
            end if;
        end loop;

        result <= p;
    end process;
end Behavioral;

