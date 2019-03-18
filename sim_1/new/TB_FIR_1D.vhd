----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2019 12:57:43
-- Design Name: 
-- Module Name: TB_FIR_1D - Behavioral
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

library WORK;
use WORK.FILTER_TYPES.ALL;


entity TB_FIR_1D is
--  Port ( );
end TB_FIR_1D;

architecture Behavioral of TB_FIR_1D is

    component FIR_1D is
         port (
             -- Inputs
            Clk     :   in  std_logic;
            i_Coeff :   in  coeff_array;
            i_Reset :   in  std_logic;
            i_Data  :   in  std_logic_vector(7 downto 0);
             
            -- Outputs
            o_Data  :   out std_logic_vector(17 downto 0)    -- Input(n bits) * filter(8 bits) + pipelines (2 bits) = n + 10 bit output bus
         );
    end component;
    
    signal Clk, Reset : std_logic := '0';
    signal Input : std_logic_vector(7 downto 0) := (others => '0');
    signal Output : std_logic_vector(17 downto 0) := (others => '0');
    
begin

    uut: FIR_1D
        port map (
            Clk     => Clk,
            i_Reset   => Reset,
            i_Coeff => (x"02", x"04", x"06"),
            i_Data  => Input,
            o_Data  => Output    
        );
        
    clocking: process
    begin
        Clk <= '1';
        wait for 5 ns;
        Clk <= '0';
        wait for 5 ns;
    end process;
    
    input_stimulus: process
    begin
        Input <= x"01";
        wait for 10ns;
        Input <= x"02";
        wait for 10ns;
        Input <= x"03";
        wait for 10 ns;
        Input <= x"00";
        wait;
    end process;
end Behavioral;
