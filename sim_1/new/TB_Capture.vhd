library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_OV7670_Capture is

end TB_OV7670_Capture;

architecture Behavioral of TB_OV7670_Capture is
    
    component OV7670_Capture is
        port (
            -- Inputs
            i_Pixel_Clk   :   in  std_logic;
            i_HRef        :   in  std_logic;
            i_Pixel_Data  :   in  std_logic_vector(7  downto 0);
            -- Outputs
            o_En_a        :   out std_logic;        
            o_Adr_a       :   out std_logic_vector(9 downto 0);        
            o_Do          :   out std_logic_vector(7 downto 0)
        );
    end component;
    
    signal PCLK, HREF, EN_A : std_logic := '0';
    signal PXLDATA : std_logic_Vector(7 downto 0) := (others => '0');
    signal ADR_A    : std_logic_vector(9 downto 0) := (others => '0');
    signal DO       : std_logic_vector(7 downto 0) := (others => '0');
    
begin
    
    uut: OV7670_Capture
        port map (
            i_Pixel_Clk  => PCLK,
            i_HRef       => HREF,
            i_Pixel_Data => PXLDATA,
            -- Outputs   
            o_En_a       => EN_A, 
            o_Adr_a      => ADR_A,
            o_Do         => DO
        );
        
    clocking: process
    begin
        PCLK <= NOT PCLK;
        wait for 20 ns;        
    end process;
    
    href_driver: process
    begin
        wait for 40 ns;
        HREF <= '1';
        wait;
    end process;
    
    input_stimulus: process
    begin
        wait for 40 ns;
        
        PXLDATA <= x"01";
        wait for 40 ns;
        PXLDATA <= x"AB";
        wait for 40 ns;
        
        PXLDATA <= x"23";
        wait for 40 ns;
        PXLDATA <= x"CD";
        wait for 40 ns;
        
        PXLDATA <= x"45";
        wait for 40 ns;
        PXLDATA <= x"EF";
        
    end process;

end Behavioral;