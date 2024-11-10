library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Timing_block is
Port (
clk_in : in STD_LOGIC; 
reset : in STD_LOGIC; 
mux_select : out STD_LOGIC_VECTOR (1 downto 0);
anodes : out STD_LOGIC_VECTOR (3 downto 0)
);
end Timing_block;
architecture Behavioral of Timing_block is
constant N : integer := 100000;-- <need to select correct value>
signal counter: integer := 0;
signal new_clk : STD_LOGIC := '0';
signal mux_select1 : STD_LOGIC_VECTOR (1 downto 0);
begin

NEW_Ck: process(clk_in, reset)
begin
    if reset = '1' then 
       new_clk <= '0';
       counter <= 0;
    elsif rising_edge(clk_in) then 
       if counter = N then 
           counter <=0;
           new_clk <= not new_clk;
        else
            counter<=counter+1;
        end if;
    end if;
end process;

MUX_selectt: process(new_clk)
begin
   if rising_edge(new_clk)  then
        case mux_select1 is 
           when "00" => 
            mux_select1 <= "01";
           when "01" => 
            mux_select1 <= "10";
           when "10" => 
            mux_select1<= "11";
           when "11" => 
            mux_select1<= "00";
           when others =>
            mux_select1<="00";
        end case;
    end if;        
end process;

ANODE_select: process(mux_select1)
begin
    case mux_select1 is
        when "00" =>
            anodes<="0111";
        when "01" =>
            anodes<="1011";
        when "10" =>
            anodes<="1101";
        when "11" =>
            anodes<="1110";
        when others => 
            anodes <="1111";
      end case;
      
end process;
    mux_select <= mux_select1;
end Behavioral;
