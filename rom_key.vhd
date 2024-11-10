----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.10.2024 00:54:07
-- Design Name: 
-- Module Name: rom_key - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rom_key is
Port ( clkin : in std_logic;
         en: std_logic;
         a : in std_logic_vector(7 downto 0);
         b : out std_logic_vector(7 downto 0)
         );
end rom_key;

architecture Behavioral of rom_key is
    component blk_mem_gen_3
        Port (
            clka  : in  std_logic;                 
            ena   : in  std_logic;                     
            addra : in  std_logic_vector(7 downto 0);
            douta : out std_logic_vector(7 downto 0)
        );
    end component;
begin
uut : blk_mem_gen_3
    port map (
         clka => clkin,
         ena => en,
         addra => a,
         douta => b );

end Behavioral;
