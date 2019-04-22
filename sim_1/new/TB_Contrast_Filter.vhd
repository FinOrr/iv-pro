library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.SYS_PARAM.ALL;

entity TB_Contrast_Filter is
--  Port ( );
end TB_Contrast_Filter;

architecture Behavioral of TB_Contrast_Filter is

    component Contrast_Filter is
        port (
            Clk         : in std_logic;
            i_Enable    : in std_logic;
            i_Data      : in std_logic_vector(BPP-1 downto 0);
            o_Read_Adr  : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
            o_Write_Adr : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
            o_Write_En  : out std_logic;
            o_Data      : out std_logic_vector(BPP-1 downto 0)  
        );
    end component;

    signal Clk          : std_logic := '0';
    signal Enable       : std_logic := '0';
    signal Write_En     : std_Logic := '0';
    signal Di           : std_logic_vector(BPP-1 downto 0)  := (others => '0');
    signal Do           : std_logic_vector(BPP-1 downto 0)  := (others => '0');
    signal Read_Adr     : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal Write_Adr    : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');

begin
   
    UUT: Contrast_Filter
        port map (
            Clk         => Clk,
            i_Enable    => Enable,
            i_Data      => Di,
            o_Read_Adr  => Read_Adr,
            o_Write_Adr => Write_Adr,
            o_Data      => Do
        ); 

    Clocking: process
    begin
        Clk <= '1';
        wait for 5 ns;
        Clk <= '0';
        wait for 5 ns;
    end process;
        
    -- Test thesholding values between 0 -> 255, with a threshold at 100
    Data_Generator: process
    begin
    
        Enable <= '1';
        
        -- First pass reads the frame buffer values, and determines the upper and lower bounds
        for i in 0 to 2000-1 loop
            for j in 0 to 255 loop
                Di <= x"40";
                wait for 10 ns;
                Di <= x"70";
                wait for 10 ns;
                Di <= x"50";
                wait for 10 ns;
                Di <= x"A0";
                wait for 10 ns;
                Di <= x"80";
                wait for 10 ns;
            end loop;
        end loop;
        
        -- Second pass outputs new pixel values using values generated in the first pass
        for i in 0 to 2000-1 loop
            for j in 0 to 255 loop
                Di <= x"40";
                wait for 10 ns;
                Di <= x"70";
                wait for 10 ns;
                Di <= x"50";
                wait for 10 ns;
                Di <= x"A0";
                wait for 10 ns;
                Di <= x"80";
                wait for 10 ns;
            end loop;
        end loop;
        wait;
    end process;

        
end Behavioral;
