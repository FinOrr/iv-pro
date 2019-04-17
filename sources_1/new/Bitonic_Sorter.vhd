----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.04.2019 20:05:34
-- Design Name: 
-- Module Name: Bitonic_Sorter - Behavioral
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

library WORK;
use WORK.SYS_PARAM.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Bitonic_Sorter is
    port (
        -- Inputs
        Value_A : in unsigned(BPP-1 downto 0);      -- Argument value 1
        Value_B : in unsigned(BPP-1 downto 0);      -- Argument value 2
        -- Outputs
        Lesser  : out unsigned(BPP-1 downto 0);     -- The lesser of the two arg values
        Greater : out unsigned(BPP-1 downto 0)      -- The greater of the two arg values
    );
end Bitonic_Sorter;

architecture Behavioral of Bitonic_Sorter is

begin
    -- Compare values, swap if they're the wrong way around
    Comparator: process(Value_A, Value_B)
    begin
        if (Value_A < Value_B) then
            Lesser <= Value_A;
            Greater <= Value_B;
        else
            Lesser <= Value_B;
            Greater <= Value_A;
        end if;
    end process;
    
end Behavioral;
