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
use IEEE.MATH_REAL.ALL;

library WORK;
use WORK.SYS_PARAM.ALL;


entity Contrast_Filter is
    port (
        -- Inputs
        Clk         : in std_logic;
        i_Enable    : in std_logic;
        i_Data      : in std_logic_vector(BPP-1 downto 0);
        -- Outputs
        o_Data      : out std_logic_vector(BPP-1 downto 0);
        o_Write_Adr : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
        o_Read_Adr  : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
        o_Write_En  : out std_logic
    );
end Contrast_Filter;

architecture Behavioral of Contrast_Filter is
    
    signal Data_Out : std_logic_vector((2*BPP)-1 downto 0) := (others => '0');
    
    signal Read_Adr : unsigned(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');    
    signal Adr_Delay1: unsigned(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal Adr_Delay2: unsigned(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal Write_Adr: unsigned(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');

    
    signal Write_En     : std_logic := '0';         -- Write enable status register
    signal Write_Delay1 : std_logic := '0';         -- Write enable delay by 1 clock cycle
    signal Write_Delay2 : std_logic := '0';         -- Write enable delayed by 2 clock cycles, to match pipelining and write to correct address
    signal Write_Delay3 : std_logic := '0';         -- Finaly write enable delay

    signal Min_Val          : unsigned(BPP-1 downto 0) := (others => '1');
    signal Max_Val          : unsigned(BPP-1 downto 0) := (others => '0');
    signal Shift_Down       : unsigned(BPP-1 downto 0) := (others => '0');
    signal Limits_Set       : std_logic := '0';
    signal Scaling_Factor   : unsigned(BPP-1 downto 0) := (others => '0');

begin
    -- Probably can just output (7 downto 0) as the scaling factor will never be big enough to cause overflow into upper 8 bits
    with Data_Out(15 downto 8) select
    o_Data <= std_logic_vector(Data_Out(7 downto 0)) when x"00",
              (others => '1')                        when others;
              
    o_Read_Adr <= std_logic_vector(Read_Adr);
    o_Write_Adr <= std_logic_vector(Write_Adr);
    o_Write_En <= std_logic(Write_Delay3);

    Boundary_Comparison: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (i_Enable = '1') then
                
                if (Limits_Set = '0') then
                    if (unsigned(i_Data) < Min_Val) then
                        Min_Val <= unsigned(i_Data);
                    elsif (unsigned(i_Data) > Max_Val) then
                        Max_Val <= unsigned(i_Data);
                    end if;
                end if;
                
                if (Limits_Set = '1') then
                    if (unsigned(i_Data) <= Min_Val) then
                        Data_Out <= (others => '0');
                    elsif (unsigned(i_Data) >= Max_Val) then
                        Data_Out <= (others => '1');
                    else
                        Shift_Down <= (unsigned(i_Data) - Min_Val);                 -- Pipeline contrast stetching,     STEP 1: shift the pixel range to start at 0
                        Data_Out <= std_logic_vector(Shift_Down * Scaling_Factor);  --  STEP 2: scale range of value to use all 256 values
                    end if;
                end if; -- end boundary set check
            end if; -- end enable input check
        end if; -- end clock edge check
    end process;
    
    Calc_Scaling_Factor: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (Min_Val > 0) then
                Scaling_Factor <= unsigned(Max_Val) / unsigned(Min_Val);
            end if;
        end if;
    end process;
    
    Address_Pointer_Control: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (i_Enable = '1') then
                if (Read_Adr < FRAME_PIXELS-1) then         -- Check pixel is not the last pixel in the frame buffer
                    Read_Adr <= Read_Adr + 1;               -- Increment the address to next pixel
                else
                    Write_Delay1 <= NOT Write_Delay1;                        -- Enable writing to FB
                    Limits_Set <= NOT Limits_Set;
                    Read_Adr <= (others => '0');            -- reset the address pointer to the beginning of the frame buffer
                end if;    
                
                Write_Delay2 <= Write_Delay1;                 -- Cascade write enable through 2 registers to match address delay
                Write_Delay3 <= Write_Delay2;                    
                Write_En     <= Write_Delay3;
                
                Adr_Delay1 <= Read_Adr;                 -- Delay read address by 1 clock cycle to match pipeline
                Adr_Delay2 <= Adr_Delay1;
                Write_Adr  <= Adr_Delay2;                -- To match the read and write addresses, delay the read address by 3 clock cycles
                
            else
                Write_En <= '0';                            -- disable writing to output frame buffer
                Read_Adr <= (others => '0');                -- reset the address pointer to the beginning of the frame buffer
            end if; -- end enable check
        end if; -- end rising edge clock
    end process;
    
end Behavioral;
