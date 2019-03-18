----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2019 12:55:12
-- Design Name: 
-- Module Name: Memory_Controller - Behavioral
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

entity Memory_Controller is
port(
    -- Inputs
    i_Clk        : in std_logic;                        -- Should match 25MHz input pixel clock
    i_Pixel_Data : in std_logic_vector(11 downto 0);    -- Data from RAM
    i_CE         : in std_logic;
    -- Ouputs
    o_En_b       : out std_logic;
    o_Adr        : out std_logic_vector(10 downto 0);
    o_Red        : out std_logic_vector(3 downto 0);    -- Red component, output to vga controller
    o_Green      : out std_logic_vector(3 downto 0);    -- Green component, output to vga controller
    o_Blue       : out std_logic_vector(3 downto 0)     -- Blue component, output to vga controller
    
);
end Memory_Controller;

architecture Behavioral of Memory_Controller is
    signal r_Adr : integer range 0 to 1279 := 0;
begin

o_Adr <= std_logic_vector(to_unsigned(r_Adr, o_Adr'length));

Data_Fetch: process(i_Clk)
begin
    if (rising_edge(i_Clk)) then
        if(i_CE = '1') then
            o_En_b <= '1';
            if (r_Adr = 1279) then 
                r_Adr <= 0;
            else
                r_Adr <= r_Adr + 1;
            end if;
                        
            o_Red <= i_Pixel_Data(11 downto 8);
            o_Green <= i_Pixel_Data(7 downto 4);
            o_Blue <= i_Pixel_Data(3 downto 0);
           
        end if;
    end if;
end process;

end Behavioral;
