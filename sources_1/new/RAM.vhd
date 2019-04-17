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


entity RAM_DP is
    port(
    -- Inputs 
        Reset   : in std_logic;                     -- Reset to clear output
        Clk_a   : in std_logic;                     -- RAM write port clock
        Clk_b   : in std_logic;                     -- RAM read port clock
    -- Port A (Write)
        En_a    : in std_logic;                     -- Port A Enable
        Adr_a   : in std_logic_vector(integer(ceil(log2(real(FRAME_WIDTH))))-1 downto 0); -- Port A (Write) Address
        Di      : in std_logic_vector(BPP -1 downto 0); -- Port A (Write) Data In
    -- Port B (Read)
        En_b    : in std_logic;                     -- Port B Enable
        Adr_b   : in std_logic_vector(integer(ceil(log2(real(FRAME_WIDTH))))-1 downto 0); -- Port B (Read) Address
        Do      : out std_logic_vector(BPP -1 downto 0) -- Port B (Read) Data Out
    );
end RAM_DP;
 
architecture Behavioral of RAM_DP is

    -- RAM Declaration
    type RAM_LB is array (FRAME_WIDTH-1 downto 0) of std_logic_vector(BPP-1 downto 0);  -- Currently testing 8 bits per pixel, 480p
    signal RAM : RAM_LB:= (others => (others => '0'));
    
    attribute ram_style: string;
    attribute ram_style of RAM : signal is "block";
    
begin
    Write_Control: process (Clk_a)
    begin
        if (rising_edge(Clk_a)) then                          -- Sync on rising edge
            if (En_a = '1') then                            -- Check PortA Enabled
                RAM(to_integer(unsigned(Adr_a))) <= Di; -- Store Data In at the address index
            end if;
            
            if (Reset = '1') then                           -- Check if reset pressed
                RAM <= (others => (others => '0'));         -- Clear RAM contents
            end if;
        end if;
    end process;
    
    Read_Control: process(Clk_b)
    begin
        if (rising_edge(Clk_b)) then
            if (En_b = '1') then                            -- Check PortB enabled
                Do <= RAM(to_integer(unsigned(Adr_b)));     -- Output the data from ram index Adr_b
            else
                Do <= (others => 'Z');                      -- If Port B not enabled, clear the output
            end if;
        end if;
    end process;
end Behavioral;
