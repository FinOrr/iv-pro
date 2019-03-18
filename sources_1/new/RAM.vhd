----------------------------------------------------------------------------------
-- Company: University of Portsmouth
-- Engineer: Fin Orr
-- Design Name: Simple Dual Port Memory
-- Module Name: Ram_DP - Behavioral
-- Project Name: FPGA Image Processing 
-- Target Devices: xc7a35tcpg236-1 [Basys-3]
-- Tool Versions: Vivado 2018.1
-- Description: Simple dual port memory, with one clock shared by both ports
--              Port A must be enabled to write, and Port B must be enabled to read
--              Intended to be called for line buffers in 2D convolution filter
-- Changes Required:
--  >> Generics should be used to dynamically size the depth of the RAM
--  >> Generics should set the size of each memory address
--  >> Signals should be used to buffer the input and output
--  >> Clean up comments
-- Revision 0.01
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity RAM_DP is
    port(
    -- Inputs 
        Clk     : in std_logic;                     -- RAM driven by 1 clock
        Reset   : in std_logic;                     -- Reset to clear output
    -- Port A (Write)
        En_a    : in std_logic;                     -- Port A Enable
        Adr_a   : in std_logic_vector(9 downto 0);  -- Port A (Write) Address
        Di      : in std_logic_vector(7 downto 0);  -- Port A (Write) Data In
    -- Port B (Read)
        En_b    : in std_logic;                     -- Port B Enable
        Adr_b   : in std_logic_vector(9 downto 0);  -- Port B (Read) Address
        Do      : out std_logic_vector(7 downto 0)  -- Port B (Read) Data Out
    );
end RAM_DP;

architecture Behavioral of RAM_DP is

    -- RAM Declaration
    type ram641x8 is array (641 downto 0) of std_logic_vector(7 downto 0);  -- Currently testing 8 bits per pixel, 720p
    shared variable RAM : ram641x8 := (others => (others => '0'));
    
begin

    RAM_Control: process (Clk)
        begin
            if (rising_edge(Clk)) then                          -- Sync on rising edge
                if (En_a = '1') then                            -- Check PortA Enabled
                    RAM(to_integer(unsigned(Adr_a))) := Di; -- Store Data In at the address index
                end if;
                
                if (Reset = '1') then                           -- Check if reset pressed
                    RAM := (others => (others => '0'));         -- Clear RAM contents
                    Do <= (others => '0');                      -- If reset true, clear output
                end if;
                
                if (En_b = '1') then                            -- Check PortB enabled
                    Do <= RAM(to_integer(unsigned(Adr_b)));     -- Output the data from ram index Adr_b
                else
                    Do <= (others => 'Z');                      -- If Port B not enabled, clear the output
                end if;
            end if;
    end process;
end Behavioral;