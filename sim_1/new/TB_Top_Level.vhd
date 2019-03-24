----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.03.2019 09:40:58
-- Design Name: 
-- Module Name: TB_Top_Level - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_Top_Level is
--  Port ( );
end TB_Top_Level;

architecture Behavioral of TB_Top_Level is

    component Top_Level is
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
    
    constant Clk_Period  : time := 10 ns;
    constant PCLK_Period : time := 40 ns;
    
    signal Clk, Reset, PCLK, HREF, SCL, SDA, XCLK, OV_RESET, PWDN, HSYNC, VSYNC : std_logic := '0';
    signal DATA : std_logic_vector(7 downto 0) := (others => '0');
    signal RED, GREEN, BLUE : std_logic_vector(3 downto 0) := (others => '0');
       
begin
    
    -- Reset high by default
    OV_Reset <= '1';
    
    Clocking: process
    begin
        Clk <= '1';
        wait for Clk_Period / 2;
        Clk <= '0';
        wait for Clk_Period / 2;
    end process;

    PCLK_Clocking: process
    begin
        wait for 10 ns;
        loop
            PCLK <= '1';
            wait for PCLK_Period / 2;
            PCLK <= '0';
            wait for PCLK_Period / 2;
        end loop;
    end process;
    
    HREF_Driver: process
    begin
        for i in 1 to FRAME_WIDTH loop
            HREF <= '1';
            wait for PCLK_Period;
        end loop;
        for i in 1 to (H_FP + H_BP + H_SP) loop
            HREF <= '0';
            wait for PCLK_Period;
        end loop;
    end process;
    
    Data_Stimulus: process
    begin
        --[RED, R] [GREEN, G] [BLUE, B]:
        
        -- [R=A][G=B][B=C]
        DATA <= (others => 'Z');
        
        wait for PCLK_Period;
        DATA <= x"0A";
        wait for PCLK_Period;
        DATA <= x"BC";
        wait for PCLK_Period;
        
        -- [R=F][G=0][B=0]
        DATA <= x"0F";
        wait for PCLK_Period;
        DATA <= x"00";
        wait for PCLK_Period;
        
        -- [R=0][G=F][B=0]
        DATA <= x"F0";
        wait for PCLK_PERIOD;
        DATA <= x"F0";
        wait for PCLK_PERIOD;
        
        -- [R=0][G=0][B=F]
        DATA <= x"00";
        wait for PCLK_PERIOD;
        DATA <= x"0F";
        wait for PCLK_PERIOD;
        
        -- R,G,B = 0
        DATA <= x"00";
        wait;
    end process;
    
    UUT: Top_Level
        port map (
            Clk_100         => Clk,   
            RESET           => Reset,
            OV7670_PCLK     => PCLK,
            OV7670_HREF     => HREF,
            OV7670_DATA     => DATA,
            -- Outputs  
            OV7670_SCL      => SCL,
            OV7670_SDA      => SDA,
            OV7670_XCLK     => XCLK,
            OV7670_RESET    => OV_RESET,
            OV7670_PWDN     => PWDN,
            VGA_RED         => RED,
            VGA_GREEN       => GREEN,
            VGA_BLUE        => BLUE,
            VGA_HSYNC       => HSYNC,
            VGA_VSYNC       => VSYNC
        );
    
end Behavioral;
