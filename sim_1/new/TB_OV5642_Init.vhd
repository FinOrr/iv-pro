----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2019 13:20:34
-- Design Name: 
-- Module Name: TB_OV5642_Init - Behavioral
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

entity TB_OV5642_Init is
--  Port ( );
end TB_OV5642_Init;

architecture Behavioral of TB_OV5642_Init is
    component OV5642_Init is
        Port( 
            -- Inputs
            i_Clk       : in  std_logic;
            i_Reset     : in  std_logic;
            i_Next      : in  std_logic;
            -- Outputs
            o_Address   : out  std_logic_vector(15 downto 0);
            o_Data      : out  std_logic_vector(7 downto 0);
            o_Finished  : out  std_logic
        );
    end component;
    
    signal Clk, rst, nxt, fin : std_logic := '0';
    signal adr : std_logic_vector(15 downto 0) := (others => '0');
    signal data : std_logic_vector(7 downto 0) := (others => '0');
    
begin

    clocking: process
    begin
        clk <= not clk;
        wait for 5 ns;
    end process;
    
    uut: OV5642_Init
        port map (
            i_Clk => Clk,
            i_Reset => rst,
            i_Next => nxt,
            o_Address => adr,
            o_Finished => fin
        );
    
    Stimulus: process
    begin
        rst <= '0';
        nxt <= '0';
        wait for 50 ns;
        nxt <= '1';
        wait for 10 ns;
    end process;

end Behavioral;
