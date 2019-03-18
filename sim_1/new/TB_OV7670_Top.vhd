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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_OV7670_Top is
--  Port ( );
end TB_OV7670_Top;

architecture Behavioral of TB_OV7670_Top is

    component OV7670_Top is
        port (
            -- Inputs
            C100MHZ     :   in  std_logic;                      -- Basys 3 xtal freq
            RESET       :   in  std_logic;                      -- Reset button
            OV7670_HREF :   in  std_logic;   
            OV7670_DATA :   in  std_logic_vector(7 downto 0);
            -- Outputs
            OV7670_SCL   :   out std_logic;
            OV7670_SDA   :   out std_logic;
            OV7670_XCLK  :   out std_logic;
            RAM_PORT_EN  :   out std_logic;
            RAM_WRITE_EN :   out std_logic;
            RAM_ADR_A    :   out std_logic_vector(9 downto 0);
            RAM_DATA     :   out std_logic_vector(11 downto 0)
        );
    end component;

    signal C100MHZ, RESET, OV7670_HREF, OV7670_SCL, OV7670_SDA, OV7670_XCLK, RAM_PORT_EN, RAM_WRITE_EN : std_logic := '0';
    signal OV7670_DATA : std_logic_vector(7 downto 0) := (others => '0');
    signal RAM_ADR_A : std_logic_vector(9 downto 0) := (others => '0');
    signal RAM_DATA : std_logic_vector(11 downto 0) := (others => '0');
    
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
        OV7670_DATA <= x"7B";
        wait for 40 ns;
        OV7670_DATA <= x"DE";
        wait for 40 ns;
        
    end process;
    
    Clocking: process
    begin
        C100MHZ <= '0';
        wait for 5 ns;
        C100MHZ <= '1';
        wait for 5 ns;
    end process;
    
    
    uut: OV7670_Top
        port map (
            C100MHZ         => C100MHZ,
            RESET           => Reset, 
            OV7670_HREF     => OV7670_HREF,
            OV7670_DATA     => OV7670_DATA,
            OV7670_SCL      => OV7670_SCL,
            OV7670_SDA      => OV7670_SDA,
            OV7670_XCLK     => OV7670_XCLK,
            RAM_PORT_EN     => RAM_PORT_EN,
            RAM_WRITE_EN    => RAM_WRITE_EN,
            RAM_ADR_A       => RAM_ADR_A,
            RAM_DATA        => RAM_DATA
        );

end Behavioral;
