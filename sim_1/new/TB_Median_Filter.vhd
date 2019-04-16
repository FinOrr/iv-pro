----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.04.2019 15:54:21
-- Design Name: 
-- Module Name: TB_Median_Filter - Behavioral
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
library work;
use WORK.FILTER_TYPES.ALL;
use WORK.SYS_PARAM.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity TB_Median_Filter is
--  Port ( );
end TB_Median_Filter;

architecture Behavioral of TB_Median_Filter is
    component Median_Filter is
        port (
            -- Inputs
            Clk         : in std_logic;                             -- System clock
            i_Reset     : in std_logic;                             -- Global reset
            i_Data      : in std_logic_vector(BPP-1 downto 0);      -- Input data, one pixel at a time
            i_Enable    : in std_logic;                             -- Sort enable toggle
            -- Output 
            o_Finish    : out std_logic;                            -- Pulses high when sort has finished.
            o_Data      : out std_logic_vector(BPP-1 downto 0)      -- Median value    
        );
    end component;
    
    signal Clk : std_logic := '0';
    signal Reset : std_logic := '0';
    signal Data_In : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal Enable : std_logic := '1';
    signal Finish : std_logic := '0';
    signal Data_Out : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal XNOR_BIT : std_logic := '0';
    signal LFSR : std_logic_vector(32 downto 0) := "001010011010110010100011001101110";
    
begin

    PRNG: process
    begin
        XNOR_BIT <= LFSR(32) XNOR LFSR(22) XNOR LFSR(2) XNOR LFSR(1);
        LFSR <= LFSR(LFSR'left-1 downto 0) & XNOR_BIT; 
        wait for 10 ns;
    end process;
    
    Clocking: process
    begin
        Clk <= '1';
        wait for 5 ns;
        Clk <= '0';
        wait for 5 ns;
    end process;
    
    Input_Stimulus: process
    begin
        Data_In <= LFSR(10 downto 3);
        wait for 10 ns;
    end process;
    
--    Enabler: process
--    begin
--        wait for 100 ns;
--        Enable <= '1';
--        wait;
--    end process;
    
    UUT: Median_Filter
        port map (
            Clk => Clk,
            i_Reset => Reset,
            i_Data => Data_In,
            i_Enable => Enable,
            o_Finish => Finish,
            o_Data => Data_Out
        );
        
end Behavioral;
