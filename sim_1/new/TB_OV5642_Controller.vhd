----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2019 12:25:18
-- Design Name: 
-- Module Name: TB_OV5642_Controller - Behavioral
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

entity TB_OV5642_Controller is
--  Port ( );
end TB_OV5642_Controller;

architecture Behavioral of TB_OV5642_Controller is
    
    component OV5642_Controller is
        generic (
            System_Freq : integer;
            Bus_Freq    : integer
        );
        port (
            i_Clk : in std_logic;
            i_Reset : in std_logic;
            SCL : out std_logic;
            SDA : out std_logic
        );
    end component;
    
    signal clk, reset, scl, sda : std_logic := '0';

begin

    uut: OV5642_Controller
        generic map (
            System_Freq => 100_000_000,
            Bus_Freq    => 100_000
        )
        port map (
            i_Clk   => Clk,
            i_Reset => reset,
            scl => scl,
            sda => sda
        );

    clocking: process
    begin
        clk <= not clk;
        wait for 5 ns;
    end process;
    
end Behavioral;
