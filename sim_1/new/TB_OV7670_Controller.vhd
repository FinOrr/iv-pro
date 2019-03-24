----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.03.2019 21:46:34
-- Design Name: 
-- Module Name: TB_OV7670_Controller - Behavioral
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

entity TB_OV7670_Controller is
--  Port ( );
end TB_OV7670_Controller;

architecture Behavioral of TB_OV7670_Controller is

    component OV7670_Controller is
        generic(
            System_Freq : natural range 0 to 400_000_000 := SYS_XTAL_FREQ;  -- Global system clock frequency, 100MHz default
            Bus_Freq    : natural range 0 to 400_000     := SCCB_SCL_FREQ  -- SCL bus frequency, 100KHz default
        );
        port (
            -- Inputs
            i_Clk     : in std_logic;    
            i_Reset   : in std_logic;
            -- Outputs
            SCL       : out std_logic;
            SDA       : out std_logic
        );
    end component;
    
    signal clk, reset, scl, sda : std_logic := '0';
    
begin

    clocking: process
    begin
        clk <= not clk;
        wait for 5 ns;
    end process;
    
    uut: OV7670_Controller
        generic map (
            System_Freq => 100_000_000,   -- Global system clock frequency, 100MHz default
            Bus_Freq    => 100_000        -- SCL bus frequency, 100KHz default
        )
        port map (
            -- Inputs
            i_Clk     => clk,
            i_Reset   => reset,
            -- Outputs
            SCL       => scl,
            SDA       => sda
        );

end Behavioral;
