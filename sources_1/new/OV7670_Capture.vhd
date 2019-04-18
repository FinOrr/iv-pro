library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library WORK;
use WORK.SYS_PARAM.ALL;

entity OV7670_Capture is
    port (
        -- Inputs
        i_Pixel_Clk   :   in  std_logic;
        i_HRef        :   in  std_logic;
        i_Pixel_Data  :   in  std_logic_vector(BPP - 1  downto 0);
        i_VSync       :   in  std_logic;   
        -- Outputs
        o_We    :   out std_logic;        
        o_Adr   :   out std_logic_vector(FB_ADR_BUS_WIDTH - 1 downto 0);        
        o_Do    :   out std_logic_vector(BPP - 1 downto 0)
    );
end OV7670_Capture;

architecture Behavioral of OV7670_Capture is
    
    -- Internal signal declarations
    signal Adr          :   unsigned(FB_ADR_BUS_WIDTH - 1 downto 0) := (others => '0');  -- RAM index to store pixel data
    signal Byte_Cache   :   std_logic_vector(BPP - 1 downto 0) := (others => '0');        -- 1px = 2B, so we need to store the last byte of input 
    -- I/O Buffers
    signal Pixel_Clk    :   std_logic;
    signal HRef         :   std_logic;
    signal Pixel_Data   :   std_logic_vector(BPP - 1 downto 0);
    signal We           :   std_logic := '0';
    signal Sample       :   std_logic := '1';
    
begin
    
    -- Connect IO
    Pixel_Clk   <= i_Pixel_Clk; 
    HRef        <= i_HRef;
    Pixel_Data  <= i_Pixel_Data;
    o_We        <= We;
    o_Adr       <= std_logic_vector(Adr);        -- Counter 'Addr' keeps count of the RAM address to write to (on PORT A) 
    o_Do        <= Byte_Cache;  -- Byte Cache collects the RGB bits and sends them to output
    
    Capture: process(Pixel_Clk)
    begin
        if (rising_edge(Pixel_Clk)) then
            if(i_HRef = '1') then
                Adr <= Adr + 1;
                IF VSYNC THEN RESET ADR
                Sample <= not Sample;
                if (Sample = '1') then
                    Byte_Cache <= i_Pixel_Data;
                end if;
            end if;
        end if;        
    end process;
end Behavioral;