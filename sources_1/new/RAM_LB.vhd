----------------------------------------------------------------------------------
-- Company: University of Portsmouth
-- Engineer: Fin Orr
-- Design Name: Single Port Memory - Line Buffer
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


entity RAM_LB is
    port(
    -- Inputs 
        Clk     : in std_logic;                     -- RAM write port clock
        Reset   : in std_logic;                     -- Reset to clear output
        En      : in std_logic;                     -- Port A Enable
        Write_En: in std_logic;                     -- Port B Enable
        Adr     : in std_logic_vector(integer(ceil(log2(real(FRAME_WIDTH))))-1 downto 0); -- Port A (Write) Address
        Di      : in std_logic_vector(BPP -1 downto 0); -- Port A (Write) Data In
        Do      : out std_logic_vector(BPP -1 downto 0) -- Port B (Read) Data Out
    );
end RAM_LB;
 
architecture Behavioral of RAM_LB is

    -- RAM Declaration
    type RAM_LB is array (FRAME_WIDTH-1 downto 0) of std_logic_vector(BPP-1 downto 0);  -- Currently testing 8 bits per pixel, 480p    
    
begin

    RAM_Controller: process (Clk)
        variable MEM : RAM_LB:= (others => (others => '0'));
    begin
        if (rising_edge(Clk)) then                          -- Sync on rising edge
            if (Reset = '1') then                           -- Check if reset pressed
                MEM := (others => (others => '0'));         -- Clear RAM contents
            elsif (En = '1') then                            -- Check PortA Enabled
                if (Write_En = '1') then
                    MEM(to_integer(unsigned(Adr))) := Di; -- Store Data In at the address index
                else
                    Do <= MEM(to_integer(unsigned(Adr)));     -- Output the data from ram index Adr_b
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;