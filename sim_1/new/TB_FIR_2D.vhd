----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.03.2019 09:54:02
-- Design Name: 
-- Module Name: TB_FIR_2D - Behavioral
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
use WORK.FILTER_TYPES.ALL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_FIR_2D is
--  Port ( );
end TB_FIR_2D;

architecture Behavioral of TB_FIR_2D is

    component FIR_2D is
        port (
            -- INPUTS
            Clk                 :   in  std_logic;
            i_Reset             :   in  std_logic;
            i_Kernel            :   in  kernel;
            i_Scaling_Factor    :   in  std_logic_vector(3 downto 0);
            i_Data              :   in  std_logic_vector(7 downto 0);
            -- OUTPUTS
            o_Data              :   out std_logic_vector(7 downto 0)
        );
    end component;

    signal Clk, reset : std_logic := '0';
    signal i_kernel : kernel := ( others => (others => x"01"));
    signal sf : std_logic_vector(3 downto 0) := x"3";             -- shift by 3 = divide by 8
    signal input, output : std_logic_vector(7 downto 0) := x"00";
    
begin

    clocking: process
    begin
        Clk <= not Clk;
        wait for 5 ns;
        Clk <= not Clk;
        wait for 5 ns;
    end process;

    Stimulus: process 
    begin
        --  Bottom row of filter window
        input <= x"1e";
        wait for 10 ns;
        input <= x"04";
        wait for 10 ns;
        input <= x"0a";
        wait for 10 ns;
        -- Middle row of filter window
        input <= x"28";
        wait for 10 ns;
        input <= x"1e";
        wait for 10 ns;
        input <= x"06";
        wait for 10 ns;
        -- Top row
        input <= x"1e";
        wait for 10 ns;
        input <= x"28";
        wait for 10 ns;
        input <= x"1e";
        wait for 10 ns;
        
    end process;

    uut: FIR_2D
        port map(
            Clk => Clk,
            i_Reset => Reset,
            i_Kernel => i_Kernel,
            i_Scaling_Factor => sf,
            i_Data  => Input,
            o_Data => Output
        );
        
    
end Behavioral;
