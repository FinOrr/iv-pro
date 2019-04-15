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
    
    signal Reg_Adr  : std_logic_vector(7 downto 0);     -- 8 bit value to be written to the register
    signal Reg_Val  : std_logic_vector(15 downto 0);  -- Address of the register we are updating

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
                    when x"06" => Reg_Val <= x"8C00"; -- RGB444 Set RGB format
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
                    when x"38" => Reg_Val <= x"FFFF";
--                when x"00" => Reg_Val <= x"1280"; 	-- COM7   Reset
--                when x"01" => Reg_Val <= x"1280";    -- REG_COM7 RESET
--                when x"02" => Reg_Val <= x"1101";
--                when x"03" => Reg_Val <= x"1200";
--                when x"04" => Reg_Val <= x"0C00";
--                when x"05" => Reg_Val <= x"3E00";
--                when x"06" => Reg_Val <= x"703A";
--                when x"08" => Reg_Val <= x"7135";
--                when x"09" => Reg_Val <= x"7211";
--                when x"0a" => Reg_Val <= x"73F0";
--                when x"0b" => Reg_Val <= x"A202";
--                when x"0c" => Reg_Val <= x"330B";
--                when x"0d" => Reg_Val <= x"350B";
--                when x"0e" => Reg_Val <= x"371D";
--                when x"0f" => Reg_Val <= x"3871";
--                when x"10" => Reg_Val <= x"392A";
--                when x"11" => Reg_Val <= x"3C78";
--                when x"12" => Reg_Val <= x"4D40";
--                when x"13" => Reg_Val <= x"4E20";
--                when x"14" => Reg_Val <= x"6900";
--                when x"15" => Reg_Val <= x"7410";
--                when x"16" => Reg_Val <= x"8D4F";
--                when x"17" => Reg_Val <= x"8E00";
--                when x"18" => Reg_Val <= x"8F00";
--                when x"19" => Reg_Val <= x"9000";
--                when x"1a" => Reg_Val <= x"9100";
--                when x"1b" => Reg_Val <= x"9600";
--                when x"1c" => Reg_Val <= x"9A00";
--                when x"1d" => Reg_Val <= x"B084";
--                when x"1e" => Reg_Val <= x"B10C";
--                when x"1f" => Reg_Val <= x"B20E";
--                when x"20" => Reg_Val <= x"B382";
--                when x"" => Reg_Val <= x"B80A";
--            when x"02" => Reg_Val <= x"1101";    -- OV: clock scale (30 fps)
--            when x"03" => Reg_Val <= x"3a04";    -- OV - lotsa stuff
--            when x"04" => Reg_Val <= x"1200";    --
--            --Set the hardware window.  These values from OV don't entirely make sense - hstop is less than hstart.  But they work...
--            when x"05" => Reg_Val <= x"1713";
--            when x"06" => Reg_Val <= x"1801";
--            when x"07" => Reg_Val <= x"32b6";
--            when x"08" => Reg_Val <= x"1902";
--            when x"09" => Reg_Val <= x"1a7a";
--            when x"0a" => Reg_Val <= x"030a";
--            when x"0b" => Reg_Val <= x"0c00";
--            when x"0c" => Reg_Val <= x"3e00";
--            -- Mystery scaling numbers
--            when x"0d" => Reg_Val <= x"703a";
--            when x"0e" => Reg_Val <= x"7135";
--            when x"0f" => Reg_Val <= x"7211";
--            when x"10" => Reg_Val <= x"73f0";
--            when x"11" => Reg_Val <= x"a202";
--            when x"12" => Reg_Val <= x"1500";
--            --Gamma curve values
--            when x"13" => Reg_Val <= x"7a20";
--            when x"14" => Reg_Val <= x"7b10";
--            when x"15" => Reg_Val <= x"7c1e";
--            when x"16" => Reg_Val <= x"7d35";
--            when x"17" => Reg_Val <= x"7e5a";
--            when x"18" => Reg_Val <= x"7f69";
--            when x"19" => Reg_Val <= x"8076";
--            when x"1a" => Reg_Val <= x"8180";
--            when x"1b" => Reg_Val <= x"8288";
--            when x"1c" => Reg_Val <= x"838f";
--            when x"1d" => Reg_Val <= x"8496";
--            when x"1e" => Reg_Val <= x"85a3";
--            when x"1f" => Reg_Val <= x"86af";
--            when x"20" => Reg_Val <= x"87c4";
--            when x"21" => Reg_Val <= x"88d7";
--            when x"22" => Reg_Val <= x"89e8";
            
--            --AGC and AEC parameters.  Note we start by disabling those features, then turn them only after tweaking the values. */
--            --REG_COM8, COM8_FASTAEC | COM8_AECSTEP | COM8_BFILT = x13E0
--            when x"23" => Reg_Val <= x"13E0";        -- Disable COM8
--            when x"24" => Reg_Val <= x"0000";        -- Turn off gain
--            when x"25" => Reg_Val <= x"1000";         -- Turn off aec high bits
--            when x"26" => Reg_Val <= x"0d40";        -- magic reserved bit
--            when x"27" => Reg_Val <= x"1418";        -- 4x gain + magic rsvd bit
--            when x"28" => Reg_Val <= x"a505";        -- 50hz banding step limit
--            when x"29" => Reg_Val <= x"ab07";        -- 60hz banding step limit
--            when x"2a" => Reg_Val <= x"2495";        -- AGC upper limit
--            when x"2b" => Reg_Val <= x"2533";        -- AGC lower limit
--            when x"2c" => Reg_Val <= x"26e3";        -- AGC/AEC fast mode
--            when x"2d" => Reg_Val <= x"9f78";        -- AEC/AGC hist
--            when x"2e" => Reg_Val <= x"a068";        -- AEC/AGC hist
--            when x"2f" => Reg_Val <= x"a103";        -- magic
--            when x"30" => Reg_Val <= x"a6d8";
--            when x"31" => Reg_Val <= x"a7d8";
--            when x"32" => Reg_Val <= x"a8f0";
--            when x"33" => Reg_Val <= x"a990";
--            when x"34" => Reg_Val <= x"aa94";
--            when x"35" => Reg_Val <= x"13E5"; --REG_COM8, COM8_FASTAEC|COM8_AECSTEP|COM8_BFILT|COM8_AGC|COM8_AEC"
            
--            -- Almost all of these are magic "reserved";values
--            when x"36" => Reg_Val <= x"0e61";
--            when x"37" => Reg_Val <= x"0f4b";
--            when x"38" => Reg_Val <= x"1602";
--            when x"39" => Reg_Val <= x"1e07";
--            when x"3a" => Reg_Val <= x"2102";
--            when x"3b" => Reg_Val <= x"2291";
--            when x"3c" => Reg_Val <= x"2907";
--            when x"3d" => Reg_Val <= x"330b";
--            when x"3e" => Reg_Val <= x"350b";
--            when x"3f" => Reg_Val <= x"371d";
--            when x"40" => Reg_Val <= x"3871";
--            when x"41" => Reg_Val <= x"392a";
--            when x"42" => Reg_Val <= x"3c78";
--            when x"43" => Reg_Val <= x"4d40";
--            when x"44" => Reg_Val <= x"4e20";
--            when x"45" => Reg_Val <= x"6900";
--            when x"46" => Reg_Val <= x"6b4a";
--            when x"47" => Reg_Val <= x"7410";
--            when x"48" => Reg_Val <= x"8d4f";
--            when x"49" => Reg_Val <= x"8e00";
--            when x"4a" => Reg_Val <= x"8f00";
--            when x"4b" => Reg_Val <= x"9000";
--            when x"4c" => Reg_Val <= x"9100";
--            when x"4d" => Reg_Val <= x"9600";
--            when x"4e" => Reg_Val <= x"9a00";
--            when x"4f" => Reg_Val <= x"b084";
--            when x"50" => Reg_Val <= x"b10c";
--            when x"51" => Reg_Val <= x"b20e";
--            when x"52" => Reg_Val <= x"b382";
--            when x"53" => Reg_Val <= x"b80a";
--            -- More reserved magic, some of which tweaks white balance
--            when x"54" => Reg_Val <= x"430a";
--            when x"55" => Reg_Val <= x"44f0";
--            when x"56" => Reg_Val <= x"4534";
--            when x"57" => Reg_Val <= x"4658";
--            when x"58" => Reg_Val <= x"4728";
--            when x"59" => Reg_Val <= x"483a";
--            when x"5a" => Reg_Val <= x"5988";
--            when x"5b" => Reg_Val <= x"5a88";
--            when x"5c" => Reg_Val <= x"5b44";
--            when x"5d" => Reg_Val <= x"5c67";
--            when x"5e" => Reg_Val <= x"5d49";
--            when x"5f" => Reg_Val <= x"5e0e";
--            when x"60" => Reg_Val <= x"6c0a";
--            when x"61" => Reg_Val <= x"6d55";
--            when x"62" => Reg_Val <= x"6e11";
--            when x"63" => Reg_Val <= x"6f9f";       -- "9e for advance AWB" */
--            when x"64" => Reg_Val <= x"6a40";
--            when x"65" => Reg_Val <= x"0140";
--            when x"66" => Reg_Val <= x"0260";
--            when x"67" => Reg_Val <= x"13E7";       -- REG_COM8, COM8_FASTAEC|COM8_AECSTEP|COM8_BFILT|COM8_AGC|COM8_AEC|COM8_AWB
            
--            --Matrix coefficients
--            when x"68" => Reg_Val <= x"4f80";
--            when x"69" => Reg_Val <= x"5080";
--            when x"6a" => Reg_Val <= x"5100";
--            when x"6b" => Reg_Val <= x"5222";
--            when x"6c" => Reg_Val <= x"535e";
--            when x"6d" => Reg_Val <= x"5480";
--            when x"6e" => Reg_Val <= x"589e";
--            when x"6f" => Reg_Val <= x"4108";
                
--            when x"70" => Reg_Val <= x"3f00";     -- edge enhancement
--            when x"71" => Reg_Val <= x"7505";
--            when x"72" => Reg_Val <= x"76e1";
--            when x"73" => Reg_Val <= x"4c00";
--            when x"74" => Reg_Val <= x"7701";
--            when x"75" => Reg_Val <= x"3dc3";
--            when x"76" => Reg_Val <= x"4b09";
--            when x"77" => Reg_Val <= x"c960";
--            when x"78" => Reg_Val <= x"4138";
--            when x"79" => Reg_Val <= x"5640";
--            when x"7a" => Reg_Val <= x"3411";
--            when x"7b" => Reg_Val <= x"3b12";        -- REG_COM11, COM11_EXP|COM11_HZAUTO"
            
--            when x"7c" => Reg_Val <= x"a488";
--            when x"7d" => Reg_Val <= x"9600";
--            when x"7e" => Reg_Val <= x"9730";
--            when x"7f" => Reg_Val <= x"9820";
--            when x"80" => Reg_Val <= x"9930";
--            when x"81" => Reg_Val <= x"9a84";
--            when x"82" => Reg_Val <= x"9b29";
--            when x"83" => Reg_Val <= x"9c03";
--            when x"84" => Reg_Val <= x"9d4c";
--            when x"85" => Reg_Val <= x"9e3f";
--            when x"86" => Reg_Val <= x"7804";
--            -- Extra-weird stuff.  Some sort of multiplexor register */
--            when x"87" => Reg_Val <= x"7901";
--            when x"88" => Reg_Val <= x"c8f0";
--            when x"89" => Reg_Val <= x"790f";
--            when x"8a" => Reg_Val <= x"c800";
--            when x"8b" => Reg_Val <= x"7910";
--            when x"8c" => Reg_Val <= x"c87e";
--            when x"8d" => Reg_Val <= x"790a";
--            when x"8e" => Reg_Val <= x"c880";
--            when x"8f" => Reg_Val <= x"790b";
--            when x"90" => Reg_Val <= x"c801";
--            when x"91" => Reg_Val <= x"790c";
--            when x"92" => Reg_Val <= x"c80f";
--            when x"93" => Reg_Val <= x"790d";
--            when x"94" => Reg_Val <= x"c820";
--            when x"95" => Reg_Val <= x"7909";
--            when x"96" => Reg_Val <= x"c880";
--            when x"97" => Reg_Val <= x"7902";
--            when x"98" => Reg_Val <= x"c8c0";
--            when x"99" => Reg_Val <= x"7903";
--            when x"9a" => Reg_Val <= x"c840";
--            when x"9b" => Reg_Val <= x"7905";
--            when x"9c" => Reg_Val <= x"c830";
--            when x"9d" => Reg_Val <= x"7926";
--            -- set rgb44 mode
--            when x"9e" => Reg_Val <= x"1204";       -- Selects RGB mode
--            when x"9f" => Reg_Val <= x"8c02";       -- Enable xxxxrrrr ggggbbbb
--            when x"a0" => Reg_Val <= x"0400";       -- CCIR601
--            when x"a1" => Reg_Val <= x"4090";       -- COM15 <- com13_gamma || com13_uvsat || 02
--            when x"a2" => Reg_Val <= x"1438";       -- 16x gain ceiling; 0x8 is reserved bit
--            when x"a3" => Reg_Val <= x"4fb3";       -- "matrix coefficient 1"
--            when x"a4" => Reg_Val <= x"50b3";       -- "matrix coefficient 2"
--            when x"a5" => Reg_Val <= x"5100";       -- vb
--            when x"a6" => Reg_Val <= x"523d";       -- "matrix coefficient 4"
--            when x"a7" => Reg_Val <= x"53a7";       -- "matrix coefficient 5"
--            when x"a8" => Reg_Val <= x"54e4";       -- "matrix coefficient 6"
--            when x"a9" => Reg_Val <= x"3de0";       -- Magic rsvd bit
--            when x"aa" => Reg_Val <= x"ffff";       -- end;
            when others => Reg_Val <= x"ffff";
            end case;
        end if; -- rising edge
    end process;
end behavioral;