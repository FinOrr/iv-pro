----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.04.2019 15:35:13
-- Design Name: 
-- Module Name: TB_Threshold_Filter - Behavioral
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

entity TB_Threshold_Filter is
--  Port ( );
end TB_Threshold_Filter;

architecture Behavioral of TB_Threshold_Filter is

    component Threshold_Filter is
        port (
            Clk         : in std_logic;
            i_Enable    : in std_logic;
            i_Data      : in std_logic_vector(BPP-1 downto 0);
            i_Threshold : in std_logic_vector(7 downto 0);
            o_Read_Adr  : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
            o_Write_Adr : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
            o_Write_En  : out std_logic;
            o_Data      : out std_logic_vector(BPP-1 downto 0)  
        );
    end component;

    signal Clk          : std_logic := '0';
    signal Enable       : std_logic := '0';
    signal Write_En     : std_Logic := '0';
    signal Threshold    : std_logic_vector(7 downto 0)      := (others => '0');
    signal Di           : std_logic_vector(BPP-1 downto 0)  := (others => '0');
    signal Do           : std_logic_vector(BPP-1 downto 0)  := (others => '0');
    signal Read_Adr     : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal Write_Adr    : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');

begin

    Clocking: process
    begin
        Clk <= '1';
        wait for 5 ns;
        Clk <= '0';
        wait for 5 ns;
    end process;
        
    -- Test thesholding values between 0 -> 255, with a threshold at 100
    Data_Generator: process
    begin
        wait for 10 ns;
        Enable <= '1';
        for i in 0 to FRAME_PIXELS-1 loop
            for i in 0 to 255 loop
                Threshold <= x"64";
                Di <= std_logic_vector(to_unsigned(i, BPP));
                wait for 10 ns;
            end loop;
            for j in 0 to 255 loop
                Threshold <= x"C0";
                Di <= std_logic_vector(to_unsigned(j, BPP));
                wait for 10 ns;
            end loop;
        end loop;
        wait;
    end process;
   
    UUT: Threshold_Filter
        port map (
            Clk         => Clk,
            i_Enable    => Enable,
            i_Data      => Di,
            i_Threshold => Threshold,
            o_Read_Adr  => Read_Adr,
            o_Write_Adr => Write_Adr,
            o_Data      => Do
        );
        
end Behavioral;
