----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/22/2024 07:58:42 PM
-- Design Name: 
-- Module Name: SBOX_INV - Behavioral
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

entity SBOX_INV is
  Port ( clkin : in std_logic;
         en: std_logic;
         a : in std_logic_vector(7 downto 0);
         b : out std_logic_vector(7 downto 0)
         );
    
end SBOX_INV;

architecture Behavioral of SBOX_INV is
    component blk_mem_gen_1
        Port (
            clka  : in  std_logic;                 
            ena   : in  std_logic;                     
            addra : in  std_logic_vector(7 downto 0);
            douta : out std_logic_vector(7 downto 0)
        );
    end component;
    begin 
    uut : blk_mem_gen_1
    port map (
         clka => clkin,
         ena => en,
         addra => a,
         douta => b );
     
end Behavioral;
