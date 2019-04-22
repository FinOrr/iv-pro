----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.04.2019 15:02:12
-- Design Name: 
-- Module Name: Contrast_Filter - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.SYS_PARAM.ALL;

entity Threshold_Filter is
    port (
        Clk         : in std_logic;
        i_Enable    : in std_logic;
        i_Data      : in std_logic_vector(BPP-1 downto 0);
        i_Threshold : in std_logic_vector(7 downto 0);
        o_Read_Adr  : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
        o_Write_Adr : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
        o_Write_En  : out std_logic;
        o_Data      : out std_logic_vector(BPP-1 downto 0)
    );  
end Threshold_Filter;

architecture Behavioral of Threshold_Filter is
    
    signal Read_Adr  : unsigned(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal Write_Adr : unsigned(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal Write_En  : std_logic := '0';
    
begin
    
    o_Read_Adr <= std_logic_vector(Read_Adr);
    o_Write_Adr <= std_logic_vector(Write_Adr);
    o_Write_En  <= Write_En;
    
    Thresholding: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (i_Enable = '1') then
                Write_En  <= '1';                           -- Enable writing to the frame buffer while processing pixels
                for i in 0 to FRAME_PIXELS-1 loop           -- Loop through frame buffer pixels
                    if (i_Data > i_Threshold) then          -- If the current pixel value is greater than the threshold
                        o_Data <= (others => '1');          -- Force it to max value
                    else                                    -- ELSE the pixel is below the threshold limit
                        o_Data <= (others => '0');          -- so set the corresponding pixel in the output image to minimum value
                    end if; -- end threshold check
                end loop; -- end image pixel loop
                
                -- Address pointer control --
                if (Read_Adr < FRAME_PIXELS-1) then         -- Check pixel is not the last pixel in the frame buffer
                    Read_Adr <= Read_Adr + 1;               -- Increment the address to next pixel
                    Write_En <= '1';                        -- Enable writing to FB
                else
                    Read_Adr <= (others => '0');            -- reset the address pointer to the beginning of the frame buffer
                end if;
                
                Write_Adr <= Read_Adr;                      -- To match the read and write addresses, delay the read address by 1 clock cycle 
            else
                Write_En <= '0';                            -- disable writing to output frame buffer
                Read_Adr <= (others => '0');                -- reset the address pointer to the beginning of the frame buffer
            end if; -- end enable check
        end if; -- end clock edge check
    end process;
    
end Behavioral;
