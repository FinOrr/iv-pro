----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.04.2019 16:34:07
-- Design Name: 
-- Module Name: Filter_Init - Behavioral
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

entity Filter_Init is
    port (
        Clk     : in std_logic;
        Reset   : in std_logic;
        
        Filter_We  : out std_logic;
        Filter_Adr : out std_logic_vector(7 downto 0);
        Filter_Coef: out std_logic_vector(7 downto 0)
    );
end Filter_Init;

architecture Behavioral of Filter_Init is
    
    signal Adr  : unsigned(7 downto 0) := (others => '0');
    signal Coef : unsigned(7 downto 0) := (others => '0');
    signal Counter : natural range 0 to 255;
    signal Enable : std_logic := '1';
    
begin
    
    Filter_We <= Enable;
    Filter_Adr <= std_logic_vector(Adr);
    Filter_Coef <= std_logic_vector(Coef);
    
    Filter_Parameters_LUT: process (Clk)
    begin
        
        if (rising_edge(Clk)) then
            if (Reset = '1') then
                Counter <= 0;
            elsif (Enable = '1') then
                case Counter is
                    -- [0->9] : Sharpen filter
                    when 0 => Coef <= x"03";   -- Scaling factor  (1/8)
                    when 1 => Coef <= x"01";   -- Coeff[0]       
                    when 2 => Coef <= x"01";   -- Coeff[1]       
                    when 3 => Coef <= x"01";   -- Coeff[2]       
                    when 4 => Coef <= x"01";   -- Coeff[3]       
                    when 5 => Coef <= x"09";   -- Coeff[4]       
                    when 6 => Coef <= x"01";   -- Coeff[5]       
                    when 7 => Coef <= x"01";   -- Coeff[6]       
                    when 8 => Coef <= x"01";   -- Coeff[7]       
                    when 9 => Coef <= x"01";   -- Coeff[8]       
                    
                    -- [10 -> 19] : Sobel Horizontal Mask
                    when 10 => Coef <= x"00";   -- Scaling factor
                    when 11 => Coef <= x"FF";   -- Coeff[0]
                    when 12 => Coef <= x"00";   -- Coeff[1]
                    when 13 => Coef <= x"01";   -- Coeff[2]
                    when 14 => Coef <= x"FE";   -- Coeff[3]
                    when 15 => Coef <= x"00";   -- Coeff[4]
                    when 16 => Coef <= x"02";   -- Coeff[5]
                    when 17 => Coef <= x"FF";   -- Coeff[6]
                    when 18 => Coef <= x"00";   -- Coeff[7]
                    when 19 => Coef <= x"01";   -- Coeff[8]
                    
                    -- [20 -> 29] : Sobel Vertical Mask
                    when 20 => Coef <= x"00";   -- Scaling factor
                    when 21 => Coef <= x"01";   -- Coeff[0]
                    when 22 => Coef <= x"02";   -- Coeff[1]
                    when 23 => Coef <= x"01";   -- Coeff[2]
                    when 24 => Coef <= x"00";   -- Coeff[3]
                    when 25 => Coef <= x"00";   -- Coeff[4]
                    when 26 => Coef <= x"00";   -- Coeff[5]
                    when 27 => Coef <= x"FF";   -- Coeff[6]
                    when 28 => Coef <= x"FE";   -- Coeff[7]
                    when 29 => Coef <= x"FF";   -- Coeff[8]     
                                   
                    -- [30 -> 39] : Gaussian blur
                    when 30 => Coef <= x"04";   -- Scaling factor (1/16)
                    when 31 => Coef <= x"01";   -- Coeff[0]
                    when 32 => Coef <= x"02";   -- Coeff[1]
                    when 33 => Coef <= x"01";   -- Coeff[2]
                    when 34 => Coef <= x"02";   -- Coeff[3]
                    when 35 => Coef <= x"04";   -- Coeff[4]
                    when 36 => Coef <= x"02";   -- Coeff[5]
                    when 37 => Coef <= x"01";   -- Coeff[6]
                    when 38 => Coef <= x"02";   -- Coeff[7]
                    when 39 => Coef <= x"01";   -- Coeff[8]
                    
                    -- [40 -> 49] : Blur (mean)
                    when 40 => Coef <= x"03";   -- Scaling factor (1/8)
                    when 41 => Coef <= x"01";   -- Coeff[0]
                    when 42 => Coef <= x"01";   -- Coeff[1]
                    when 43 => Coef <= x"01";   -- Coeff[2]
                    when 44 => Coef <= x"01";   -- Coeff[3]
                    when 45 => Coef <= x"01";   -- Coeff[4]
                    when 46 => Coef <= x"01";   -- Coeff[5]
                    when 47 => Coef <= x"01";   -- Coeff[6]
                    when 48 => Coef <= x"01";   -- Coeff[7]
                    when 49 => Coef <= x"01";   -- Coeff[8]  
                    
                    when others => Coef <= (others => 'Z');
                end case;     
                
                if (Counter = 50) then
                    Enable <= '0';
                else
                    Counter <= Counter + 1;
                end if;
                
                Adr <= to_unsigned(Counter, 8);
            
            end if;
        end if;
    end process;

end Behavioral;
