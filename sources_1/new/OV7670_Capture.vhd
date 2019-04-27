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
    signal Adr          :   unsigned(FB_ADR_BUS_WIDTH - 1 downto 0) := to_unsigned(FRAME_WIDTH+3, FB_ADR_BUS_WIDTH);  -- RAM index to store pixel data
    signal Byte_Cache   :   std_logic_vector(BPP - 1 downto 0) := (others => '0');        -- 1px = 2B, so we need to store the last byte of input 
    -- I/O Buffers
    signal Pixel_Clk    :   std_logic;
    signal HRef         :   std_logic;
    signal Pixel_Data   :   std_logic_vector(BPP - 1 downto 0);
    signal Write_En     :   std_logic := '0';
    signal Sample_Col   :   std_logic := '0';
    signal Sample_Row   :   std_logic := '0';
    signal HREF_0       :   std_logic := '0';
    signal HREF_1       :   std_logic := '0';
    
begin
    
    -- Connect IO
    Pixel_Clk   <= i_Pixel_Clk; 
    HRef        <= i_HRef;
    Pixel_Data  <= i_Pixel_Data;
    o_We        <= Write_En;
    o_Adr       <= std_logic_vector(Adr);       -- Counter 'Addr' keeps count of the RAM address to write to (on PORT A) 
    o_Do        <= Byte_Cache;                  -- Byte Cache collects the RGB bits and sends them to output
    
    Capture: process(Pixel_Clk, i_VSync)
    begin
        if (rising_edge(Pixel_Clk)) then
            if(i_HRef = '1') then
                Sample_Col <= NOT Sample_Col;                       -- Sample alternate rows
                if (Sample_Col = '1' and Sample_Row = '1') then     -- Check for active pixel
                    Byte_Cache <= i_Pixel_Data;
                    Write_En <= '1';
                    if (Adr = FRAME_PIXELS-1) or (i_VSync = '1') then -- If end of frame
                        Adr <= (others => '0');    -- Reset to the start of frame                        
                    else
                        Adr <= Adr + 1;
                    end if;
                else
                    Write_En <= '0';
                end if;
            end if;
        end if;
                
        if (rising_edge(Pixel_Clk)) then
            HRef_0 <= i_HRef;
            HRef_1 <= HRef_0;
            if (HREF_0 = '1' and HREF_1= '0') then      -- On HREF rising edge
                Sample_Row <= not Sample_Row;           -- Sample alternating rows
            end if;
        end if;
    end process;
        
end Behavioral;