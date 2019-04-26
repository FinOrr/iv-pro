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
            i_Enable            :   in  std_logic;
            i_Reset             :   in  std_logic;
            i_Kernel            :   in  kernel;
            i_Scaling_Factor    :   in  std_logic_vector(3 downto 0);
            i_Data              :   in  std_logic_vector(7 downto 0);
            i_Median_En         :   in  std_logic;
            -- OUTPUTS
            o_Data              :   out std_logic_vector(7 downto 0)
        );
    end component;

    type input_matrix is array (7 downto 0, 7 downto 0) of std_logic_vector(7 downto 0);
    signal Clk, reset       : std_logic                     := '0';
    signal i_kernel         : kernel                        := ( others => (others => x"01"));
    signal sf               : std_logic_vector(3 downto 0)  := x"3";             -- shift by 3 = divide by 8
    signal input_mat        : input_matrix                  := (others => (others => x"00"));
    signal input, output    : std_logic_vector(7 downto 0)  := x"00";
    signal median           : std_logic                     := '1';
    signal en               : std_logic                     := '1';
begin
    -- Input matrix has an average of 
    input_mat <=   ((x"21", x"29", x"33", x"33", x"17", x"23", x"06", x"04"),               
                    (x"07", x"18", x"06", x"33", x"27", x"09", x"2E", x"35"),
                    (x"05", x"3A", x"16", x"15", x"08", x"33", x"20", x"04"),
                    (x"07", x"3B", x"32", x"14", x"35", x"0B", x"18", x"32"),
                    (x"0E", x"1F", x"22", x"22", x"22", x"38", x"23", x"27"),
                    (x"22", x"0B", x"3F", x"11", x"36", x"2A", x"10", x"01"),
                    (x"2E", x"23", x"2C", x"39", x"31", x"3E", x"39", x"38"),
                    (x"3F", x"2D", x"1B", x"22", x"3B", x"1F", x"2F", x"35"));
    
    clocking: process
    begin
        Clk <= not Clk;
        wait for 5 ns;
        Clk <= not Clk;
        wait for 5 ns;
    end process;

    Stimulus: process 
    begin
        median <= '1';
        for row in 0 to 7 loop
            for col in 0 to 7 loop
                Input <= input_mat(row, col);
                wait for 10 ns;
            end loop;
        end loop;
    end process;

    uut: FIR_2D
        port map(
            Clk         => Clk,
            i_Reset     => Reset,
            i_Enable    => En,
            i_Kernel    => i_Kernel,
            i_Scaling_Factor => sf,
            i_Data      => Input,
            i_Median_En => median,
            o_Data      => Output
        );
        
    
end Behavioral;
