-- Camera registers are reset when there is no power

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity OV7670_Init is
    Port ( 
        -- Inputs
        i_Clk       : in  std_logic;
        i_Reset     : in  std_logic;
        i_Next      : in  std_logic;
        -- Outputs
        o_Data      : out  std_logic_vector(15 downto 0);
        o_Finished  : out  std_logic
    );
end OV7670_Init;

architecture Behavioral of OV7670_Init is
    
    signal Reg_Adr  : std_logic_vector(7 downto 0) := x"00";     -- 8 bit value to be written to the register
    signal Reg_Val  : std_logic_vector(15 downto 0) := x"0000";  -- Address of the register we are updating

begin
    
    -- Register Reg_Val holds the 8 bit configuration value
    o_Data  <= Reg_Val;
    o_Finished  <= '1' when Reg_Val = x"FFFF" else '0';
    
    Address_Update: process(i_Clk)
    begin   
        if (rising_edge(i_Clk)) then
            if (i_Reset = '1') then
                Reg_Adr <= (others => '0');
            else
                if (i_Next = '1') then
                    Reg_Adr <= std_logic_vector(unsigned(Reg_Adr)+1);
                end if; -- next
            end if; -- reset
                
            case Reg_Adr is 
                when x"00" => Reg_Val <= x"1280"; -- COM7   Reset
                when x"01" => Reg_Val <= x"1280"; -- COM7   Reset
                when x"02" => Reg_Val <= x"1204"; -- COM7   Size & RGB output
                when x"03" => Reg_Val <= x"1100"; -- CLKRC  Prescaler - Fin/(1+1)
                when x"04" => Reg_Val <= x"0C00"; -- COM3   Lots of stuff, enable scaling, all others off
                when x"05" => Reg_Val <= x"3E00"; -- COM14  PCLK scaling off
                when x"06" => Reg_Val <= x"8C02"; -- RGB444 Set RGB format 8C00 ORIGINAL
                when x"07" => Reg_Val <= x"0400"; -- COM1   no CCIR601
                when x"08" => Reg_Val <= x"4010"; -- COM15  Full 0-255 output, RGB 565
                when x"09" => Reg_Val <= x"3a04"; -- TSLB   Set UV ordering,  do not auto-reset window
                when x"0A" => Reg_Val <= x"1438"; -- COM9  - AGC Celling
                when x"0B" => Reg_Val <= x"4f40"; --x"4fb3"; -- MTX1  - colour conversion matrix
                when x"0C" => Reg_Val <= x"5034"; --x"50b3"; -- MTX2  - colour conversion matrix
                when x"0D" => Reg_Val <= x"510C"; --x"5100"; -- MTX3  - colour conversion matrix
                when x"0E" => Reg_Val <= x"5217"; --x"523d"; -- MTX4  - colour conversion matrix
                when x"0F" => Reg_Val <= x"5329"; --x"53a7"; -- MTX5  - colour conversion matrix
                when x"10" => Reg_Val <= x"5440"; --x"54e4"; -- MTX6  - colour conversion matrix
                when x"11" => Reg_Val <= x"581e"; --x"589e"; -- MTXS  - Matrix sign and auto contrast
                when x"12" => Reg_Val <= x"3dc0"; -- COM13 - Turn on GAMMA and UV Auto adjust
                when x"13" => Reg_Val <= x"1100"; -- CLKRC  Prescaler - Fin/(1+1)
                when x"14" => Reg_Val <= x"1711"; -- HSTART HREF start (high 8 bits)
                when x"15" => Reg_Val <= x"1861"; -- HSTOP  HREF stop (high 8 bits)
                when x"16" => Reg_Val <= x"32A4"; -- HREF   Edge offset and low 3 bits of HSTART and HSTOP
                when x"17" => Reg_Val <= x"1903"; -- VSTART VSYNC start (high 8 bits)
                when x"18" => Reg_Val <= x"1A7b"; -- VSTOP  VSYNC stop (high 8 bits) 
                when x"19" => Reg_Val <= x"030a"; -- VREF   VSYNC low two bits
                when x"1A" => Reg_Val <= x"0e61"; -- COM5(0x0E) 0x61
                when x"1B" => Reg_Val <= x"0f4b"; -- COM6(0x0F) 0x4B 
                when x"1C" => Reg_Val <= x"1602"; --
                when x"1D" => Reg_Val <= x"1e37"; -- MVFP (0x1E) 0x07  -- FLIP AND MIRROR IMAGE 0x3x
                when x"1E" => Reg_Val <= x"2102";
                when x"1F" => Reg_Val <= x"2291";
                when x"20" => Reg_Val <= x"2907";
                when x"21" => Reg_Val <= x"330b";
                when x"22" => Reg_Val <= x"350b";
                when x"23" => Reg_Val <= x"371d";
                when x"24" => Reg_Val <= x"3871";
                when x"25" => Reg_Val <= x"392a";
                when x"26" => Reg_Val <= x"3c78"; -- COM12 (0x3C) 0x78
                when x"27" => Reg_Val <= x"4d40"; 
                when x"28" => Reg_Val <= x"4e20";
                when x"29" => Reg_Val <= x"6900"; -- GFIX (0x69) 0x00
                when x"2A" => Reg_Val <= x"6b4a";
                when x"2B" => Reg_Val <= x"7410";
                when x"2C" => Reg_Val <= x"8d4f";
                when x"2D" => Reg_Val <= x"8e00";
                when x"2E" => Reg_Val <= x"8f00";
                when x"2F" => Reg_Val <= x"9000";
                when x"30" => Reg_Val <= x"9100";
                when x"31" => Reg_Val <= x"9600";
                when x"32" => Reg_Val <= x"9a00";
                when x"33" => Reg_Val <= x"b084";
                when x"34" => Reg_Val <= x"b10c";
                when x"35" => Reg_Val <= x"b20e";
                when x"36" => Reg_Val <= x"b382";
                when x"37" => Reg_Val <= x"b80a";
                when others  => Reg_Val <= x"FFFF";
            end case;
        end if; -- rising edge
    end process;
end behavioral;