----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.03.2019 20:50:56
-- Design Name: 
-- Module Name: TB_OV7670_Top - Behavioral
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


entity TB_OV7670_Top is
--  Port ( );
end TB_OV7670_Top;

architecture Behavioral of TB_OV7670_Top is

    component OV7670_Top is
        port (
            -- Inputs
            Clk_100     :   in  std_logic;                      -- System clock
            RESET       :   in  std_logic;                      -- Reset button
            OV7670_PCLK :   in  std_logic;                      -- Camera PCLK
            OV7670_HREF :   in  std_logic;   
            OV7670_DATA :   in  std_logic_vector(7 downto 0);
            -- Outputs
            OV7670_SCL  :   out std_logic;
            OV7670_SDA  :   out std_logic;
            OV7670_XCLK :   out std_logic;
            OV7670_RESET:   out std_logic;
            OV7670_PWDN :   out std_logic;
            VGA_RED     :   out std_logic_vector(3 downto 0);
            VGA_GREEN   :   out std_logic_vector(3 downto 0);
            VGA_BLUE    :   out std_logic_vector(3 downto 0);
            VGA_HSYNC   :   out std_logic;
            VGA_VSYNC   :   out std_logic
        );
    end component;

    signal CLK, RESET, OV7670_PCLK, OV7670_HREF, OV7670_SCL, OV7670_SDA, OV7670_XCLK, OV7670_RESET, OV7670_PWDN, VGA_HSYNC, VGA_VSYNC : std_logic := '0';
    signal OV7670_DATA  : std_logic_vector(7 downto 0) := (others => '0');
    signal VGA_RED, VGA_GREEN, VGA_BLUE : std_logic_vector(3 downto 0) := (others => '0');
    
begin
    
    Reset <= '0';
    HREF_DRIVER: process
    begin
        OV7670_HREF <= '1';
        wait for 15 ms;
        OV7670_HREF <= '0';
        wait for 1 ms;
    end process;
    
    Input_Data : process
    begin
        -- A : IGNORED bits from camera 
        -- B : Red component
        -- C : Green component
        -- D : Blue component
        wait for 55 ns;
        OV7670_DATA <= x"0B";
        wait for 40 ns;
        OV7670_DATA <= x"CD";
        wait for 40 ns;
        
        -- TEST RED + GREEN
        OV7670_DATA <= x"01";
        wait for 40 ns;
        OV7670_DATA <= x"23";
        wait for 40 ns;
        
    end process;
    
    Clocking: process
    begin
        CLK <= '0';
        wait for 5 ns;
        CLK <= '1';
        wait for 5 ns;
    end process;
    
    
    uut: OV7670_Top
        port map (
            -- Inputs
            Clk_100     => Clk,
            RESET       => Reset,
            OV7670_PCLK => OV7670_PCLK,
            OV7670_HREF => OV7670_HREF,
            OV7670_DATA => OV7670_DATA,
            -- Outputs
            OV7670_SCL  => OV7670_SCL,
            OV7670_SDA  => OV7670_SDA,
            OV7670_XCLK => OV7670_XCLK,
            OV7670_RESET => OV7670_RESET,
            OV7670_PWDN => OV7670_PWDN,
            VGA_RED     => VGA_RED,
            VGA_GREEN   => VGA_GREEN,
            VGA_BLUE    => VGA_BLUE,
            VGA_HSYNC   => VGA_HSYNC,
            VGA_VSYNC   => VGA_VSYNC
    );                      

end Behavioral;
