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
            o_FBO_Adr   : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
            o_FBO_Data  : out std_logic_vector(BPP-1 downto 0)      -- Median value
        );
    end component;
    
    signal Clk      : std_logic := '0';
    signal Reset    : std_logic := '0';
    signal Data_In  : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal Enable   : std_logic := '1';
    signal FBO_Data : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal FBO_Adr  : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
        
    type input_matrix is array (7 downto 0, 7 downto 0) of std_logic_vector(7 downto 0);
    signal input_mat : input_matrix   := (others => (others => x"00"));

    
begin

    -- Input matrix has an average of 
    input_mat <=   ((x"21", x"29", x"33", x"33", x"17", x"23", x"06", x"04"),               
                    (x"07", x"18", x"06", x"33", x"27", x"09", x"2E", x"35"),
                    (x"05", x"3A", x"16", x"15", x"08", x"33", x"20", x"04"),
                    (x"07", x"3B", x"32", x"14", x"35", x"0B", x"18", x"32"),
                    (x"0E", x"1F", x"22", x"22", x"22", x"38", x"23", x"27"),
                    (x"22", x"0B", x"3F", x"11", x"36", x"2A", x"10", x"01"),
                    (x"2E", x"23", x"2C", x"39", x"31", x"3E", x"39", x"38"),
                    (x"3F", x"2D", x"1B", x"22", x"3B", x"1F", x"2F", x"35"));
    

    Clocking: process
    begin
        Clk <= '1';
        wait for 5 ns;
        Clk <= '0';
        wait for 5 ns;
    end process;
    
    Stimulus: process 
    begin
        for row in 0 to 7 loop
            for col in 0 to 7 loop
                Data_In <= input_mat(row, col);
                wait for 10 ns;
            end loop;
        end loop;
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
            o_FBO_Adr => FBO_Adr,
            o_FBO_Data => FBO_Data
        );
        
end Behavioral;
