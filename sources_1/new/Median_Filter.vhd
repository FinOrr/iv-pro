----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.04.2019 13:55:04
-- Design Name: 
-- Module Name: Median_Filter - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
library WORK;
use WORK.SYS_PARAM.ALL;
use WORK.FILTER_TYPES.ALL;


entity Median_Filter is
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
end Median_Filter;

architecture Behavioral of Median_Filter is
    
    type t_Data_Array is array (8 downto 0) of unsigned(BPP-1 downto 0);
    signal Input_Array : t_Data_Array := (others => (others => '0'));
    
    type t_Median_Array is array (15 downto 0) of unsigned(BPP-1 downto 0);
    signal Median : t_Median_Array := (others => (others => '0'));
    
    signal Step_Counter : natural range 0 to 4 := 0;
begin

    with Step_Counter select o_Data <=
        std_logic_vector(Median(8)) when 0, (others => 'Z') when others;

    Sort: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (i_Enable = '1') then
                case Step_Counter is
                    when 0 =>
                        o_Finish <= '0';
                        -- LOAD MEDIAN ARRAY WITH VALUES
                        -- Bitonic merge sort requires 2^N values, so force n(0) => 0
                        -- Weighted median filter, corner pixels lowest weighting, centre pixel highest weighting
                        Median(0) <= (others => '0');       -- Padding value 
                        -- Shift new data into array
                        Median(1) <= unsigned(i_Data);      -- Z1            
                        -- Shift data according to k
                        Median(2) <= Median(1);             -- Z2            
                        Median(3) <= Median(1);             -- Z2            
                        Median(4) <= Median(3);             -- Z3            
                        Median(5) <= Median(4);             -- Z4            
                        Median(6) <= Median(4);             -- Z4            
                        Median(7) <= Median(6);             -- Z5            
                        Median(8) <= Median(6);             -- Z5            
                        Median(9) <= Median(6);             -- Z5            
                        Median(10) <= Median(9);            -- Z6            
                        Median(11) <= Median(9);            -- Z6            
                        Median(12) <= Median(11);           -- Z7            
                        Median(13) <= Median(12);           -- Z8            
                        Median(14) <= Median(12);           -- Z8            
                        Median(15) <= Median(14);           -- Z9            
                        Step_Counter <= Step_Counter + 1;
                        
                    when 1 =>
                    -- SORT STEP 1
                        -- STAGE 1
                        for i in 0 to 7 loop
                            if (Median(i) > Median(i+8)) then
                                Median(i) <= Median(i+8);
                                Median(i+8) <= Median(i);
                            end if;
                        end loop;
                        Step_Counter <= Step_Counter + 1;
                        
                    when 2 =>
                    -- SORT STEP 2
                        -- STAGE 1
                        for i in 0 to 3 loop
                            if (Median(i) > Median(i+4)) then
                                Median(i) <= Median(i+4);
                                Median(i+4) <= Median(i);
                            end if;
                        end loop;
                        -- STAGE 2
                        for i in 8 to 11 loop
                            if (Median(i) > Median (i+4)) then
                                Median(i) <= Median(i+4);
                                Median(i+4) <= Median(i);
                            end if;
                        end loop;
                        Step_Counter <= Step_Counter + 1;
                        
                    when 3 =>
                    -- SORT STEP 3: Stages could be nested within another FOR loop to reduce further
                        -- STAGE 1
                        for i in 0 to 1 loop
                            if (Median(i) > Median (i+2)) then
                                Median(i) <= Median(i+2);
                                Median(i+2) <= Median(i);
                            end if;
                        end loop;
                        -- STAGE 2
                        for i in 4 to 5 loop
                            if (Median(i) > Median (i+2)) then
                                Median(i) <= Median(i+2);
                                Median(i+2) <= Median(i);
                            end if;
                        end loop;
                        -- STAGE 3
                        for i in 8 to 9 loop
                            if (Median(i) > Median (i+2)) then
                                Median(i) <= Median(i+2);
                                Median(i+2) <= Median(i);
                            end if;
                        end loop;
                        -- STAGE 4
                        for i in 12 to 13 loop
                            if (Median(i) > Median (i+2)) then
                                Median(i) <= Median(i+2);
                                Median(i+2) <= Median(i);
                            end if;
                        end loop;
                        Step_Counter <= Step_Counter + 1;
                        
                    when 4 =>
                    -- SORT STEP 4
                        -- STAGE 1
                        for i in 0 to 7 loop
                            if (Median(2*i) > Median(2*i+1)) then
                                Median(2*i+1) <= Median(2*i);
                                Median(2*i) <= Median(2*i+1);
                            end if;
                        end loop;
                        Step_Counter <= 0;
                        o_Finish <= '1';
                        
                    when others =>
                        o_Finish <= 'Z';
                        Step_Counter <= 0;
                end case;
            end if;
        end if;     
    end process;

end Behavioral;
