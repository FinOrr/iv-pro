----------------------------------------------------------------------------------
-- Company: University of Portsmouth
-- Engineer: Fin Orr
-- Design Name: Simple Dual Port Memory
-- Module Name: Ram_DP - Behavioral
-- Project Name: FPGA Image Processing 
-- Target Devices: xc7a35tcpg236-1 [Basys-3]
-- Tool Versions: Vivado 2018.1
-- Description: Simple dual port memory, with independent port clocks
--              Port A must be enabled to write, and Port B must be enabled to read
--              Intended to be called for line buffers in 2D convolution filter
-- Changes Required:
--  >> Generics should be used to dynamically size the depth of the RAM
--  >> Generics should set the size of each memory address
--  >> Signals should be used to buffer the input and output
--  >> Clean up comments
-- Revision 0.01
----------------------------------------------------------------------------------
library WORK;
use WORK.SYS_PARAM.ALL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;


entity Frame_Buffer is
    port (
        Clk         : in std_logic;
        Write_En    : in std_logic;
        En          : in std_logic;
        Adr         : in std_logic_vector(integer(ceil(log2(real((FRAME_PIXELS)))))-1 downto 0);
        Di          : in std_logic_vector(BPP-1 downto 0);
        Do          : out std_logic_vector(BPP-1 downto 0)
    );
end Frame_Buffer;

architecture Behavioral of Frame_Buffer is
    type t_RAM is array (FRAME_PIXELS - 1 downto 0) of std_logic_vector(BPP-1 downto 0);
    
    signal RAM : t_RAM := (others => (others => '0'));
begin
    
    RAM_Controller: process(clk)
    begin
        if (rising_edge(Clk)) then
            if(En = '1') then
                if (Write_En = '1') then
                    RAM(to_integer(unsigned(Adr))) <= Di;
                end if;
                Do <= RAM(to_integer(unsigned(Adr)));
            end if;
        end if;
    end process;
end Behavioral;