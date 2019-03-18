----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.03.2019 22:42:51
-- Design Name: 
-- Module Name: TB_SCCB_Master - Behavioral
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


entity TB_SCCB_Master is
--  Port ( );
end TB_SCCB_Master;

architecture Behavioral of TB_SCCB_Master is

    component SCCB_Master is
        port (
            -- Inputs
            i_Clk       : in    std_logic;
            i_Reset     : in    std_logic;
            i_Enable    : in    std_logic;
            i_Start     : in    std_logic;
            i_Device_ID : in    std_logic_vector(7 downto 0);
            i_Address   : in    std_logic_vector(7 downto 0);
            i_Data      : in    std_logic_vector(7 downto 0);
            -- Output
            o_Ready     : out   std_logic;
            o_SDA       : out   std_logic;
            o_SCL       : out   std_logic
        );
    end component;

    signal clk, reset, enable, start, ready, sda, scl : std_logic := '0';
    signal id, adr, data : std_logic_vector(7 downto 0) := x"00";
    
begin

    clocking: process
    begin
        clk <= '0';
        wait for 5 us;
        clk <= '1';
        wait for 5 us;
    end process;
    
    uut: SCCB_Master
        port map (
            -- Inputs
            i_Clk       => clk,
            i_Reset     => reset,
            i_Enable    => enable,
            i_Start     => start,
            i_Device_ID => id,
            i_Address   => adr,
            i_Data      => data,
            -- Outpu
            o_Ready     => ready,
            o_SDA       => sda,
            o_SCL       => scl
        );

    stimulus: process
    begin
        enable  <= '1';
        start   <= '1';
        id      <= x"FF";
        adr     <= x"FF";
        data    <= x"FF";
        wait for 300 us;
        
        id      <= x"42";
        adr     <= x"77";
        data    <= x"C3";
        wait for 300 us;
    end process;
end Behavioral;
