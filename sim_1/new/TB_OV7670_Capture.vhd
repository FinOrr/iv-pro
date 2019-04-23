----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.04.2019 18:44:52
-- Design Name: 
-- Module Name: TB_OV7670_Capture - Behavioral
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

entity TB_OV7670_Capture is
--  Port ( );
end TB_OV7670_Capture;

architecture Behavioral of TB_OV7670_Capture is

    component OV7670_Capture is
        port (
            -- Inputs
            i_Pixel_Clk   :   in  std_logic;
            i_HRef        :   in  std_logic;
            i_Pixel_Data  :   in  std_logic_vector(BPP- 1  downto 0);
            i_VSync       :   in  std_logic;   
            -- Outputs
            o_We    :   out std_logic;        
            o_Adr   :   out std_logic_vector(FB_ADR_BUS_WIDTH- 1 downto 0);        
            o_Do    :   out std_logic_vector(BPP- 1 downto 0)
        );
    end component;
    
    constant tp     : time := 80 ns;            -- each pixel takes 2 clock cycle
    constant tline  : time := 62720 ns;         -- each line takes 784*2 clock cycles

    signal XNOR_Bit : std_logic := '0';
    signal LFSR : std_logic_vector(32 downto 0) := ("011010010110100101001011101001110");     -- random seed for pseudo random number generator
    signal Clk  : std_logic := '0';
    signal HRef : std_logic := '0';
    signal Di   : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal VSync: std_logic := '0';
    signal We   : std_logic := '0';
    signal Adr  : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal Do   : std_logic_vector(BPP-1 downto 0) := (others => '0');
    
begin

    XNOR_Bit <= LFSR(32) XNOR LFSR(22) XNOR LFSR(2) XNOR LFSR(1);

    UUT: OV7670_Capture
        port map (
            i_Pixel_Clk  => Clk,
            i_HRef       => HRef,
            i_Pixel_Data => Di,
            i_VSync      => VSync,
            o_We         => We,
            o_Adr        => Adr,
            o_Do         => Do
        );

    Clocking: process
    begin
        Clk <= '1';
        wait for 40 ns;
        Clk <= '0';
        wait for 40 ns;   
    end process;

    Control_Drivers: process
    begin
        vsync <= '1';
        wait for 3 * tline;
        vsync <= '0';
        wait for 17 * tline;    -- 17xtline = Front porch
        for i in 0 to 479 loop  -- Loop through the rows
            href <= '1';        -- Set href high while sampling pixels
            wait for 640 * tp;  -- HREF high while pixels active
            href <= '0';        -- HREF low, new line starting
            wait for 144 * tp;  -- Retrace time
        end loop;
        wait for ((10 * tline) - (144*tp)); -- back porch
    end process;
    
    Data_Generator: process
    begin
        wait for 20 * tline;
        for i in 0 to 479 loop              -- loop through the rows
            for i in 0 to 639 loop          -- loop through the cols
                Di <= LFSR(30 downto 23);   -- Data input is random value representing (Y component)
                wait for tp;            -- Each pixel takes 2 clock cycles
                Di <= LFSR(29 downto 22);   -- Data input is random value (U / V component)
                wait for tp;            
            end loop;
        wait for 143.5 * tp;
        end loop;
        wait for 10 * tline;
    end process;
    
    PRNG: process
    begin
        LFSR <= LFSR(31 downto 0) & XNOR_Bit;
        wait for 160 ns;
    end process;
    
end Behavioral;