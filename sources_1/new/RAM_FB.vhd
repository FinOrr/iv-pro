----------------------------------------------------------------------------------
-- Company: University of Portsmouth
-- Engineer: Fin Orr
-- Design Name: Simple Frame Buffer
-- Module Name: Ram_DP - Behavioral
-- Project Name: FPGA Image Processing 
-- Target Devices: xc7a35tcpg236-1 [Basys-3]
-- Tool Versions: Vivado 2018.1
-- Description: 
--              
--              
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


entity RAM_FB is
    port(
    -- CLOCK 
        Clk     : in std_logic;                     -- RAM write port clock
    -- PORT A
        A_Adr   : in std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
        A_Di    : in std_logic_vector(BPP-1 downto 0);    
        A_We    : in std_logic;                     -- Port A Enable
        A_Do    : out std_logic_vector(BPP-1 downto 0);
    -- PORT B
        B_Adr   : in std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
        B_Di    : in std_logic_vector(BPP-1 downto 0);
        B_We    : in std_logic;
        B_Do    : out std_logic_vector(BPP-1 downto 0)
    );
end RAM_FB;
 
architecture Behavioral of RAM_FB is

    -- RAM Declaration
    type t_RAM_FB is array (FRAME_PIXELS - 1 downto 0) of std_logic_vector(BPP-1 downto 0);  -- Currently testing 8 bits per pixel, 480p
    signal RAM : t_RAM_FB := (others => (others => '0'));
    
begin
    
    Port_A_Controller: process(Clk)
    begin
        if (rising_edge(Clk)) then
            A_Do <= RAM(to_integer(unsigned(A_Adr)));
            if (A_We = '1') then
                RAM(to_integer(unsigned(A_Adr))) <= A_Di;
            end if;
        end if;
    end process;
    
    Port_B_Controller: process(Clk)
    begin
        if (rising_edge(Clk)) then
            B_Do <= RAM(to_integer(unsigned(B_Adr)));
            if (B_We = '1') then
                RAM(to_integer(unsigned(B_Adr))) <= B_Di;
            end if;
        end if;
    end process;
    
end Behavioral;