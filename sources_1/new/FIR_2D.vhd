----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2019 14:48:28
-- Design Name: 
-- Module Name: FIR_2D - Behavioral
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
use IEEE.math_real.all;

library WORK;
use WORK.FILTER_TYPES.ALL;
use WORK.SYS_PARAM.ALL;

entity FIR_2D is
    port (
        -- INPUTS
        Clk                 :   in  std_logic;
        i_Reset             :   in  std_logic;
        i_Kernel            :   in  kernel;                         -- Input data
        i_Scaling_Factor    :   in  std_logic_vector(3 downto 0);
        i_Data              :   in  std_logic_vector(BPP-1 downto 0);
        i_Median_En         :   in  std_logic;
        -- OUTPUTS
        o_Data              :   out std_logic_vector(BPP-1 downto 0)
    );
end FIR_2D;

architecture Behavioral of FIR_2D is

    signal Reset        : std_logic := '0';                                                 -- Reset input, buffered
    signal Adr_Cntr     : natural range 0 to FRAME_WIDTH-1 := 0;                            -- Counter to cycle through memory addresses    
    signal Read_Adr     : std_logic_vector(integer(ceil(log2(real(FRAME_WIDTH))))-1 downto 0) := (others => '0');                  -- Linebuffer read address
    signal Write_Adr    : std_logic_vector(integer(ceil(log2(real(FRAME_WIDTH))))-1 downto 0) := (others => '0');                  -- Memory write address
         
    -- FIR Signals
    signal Pixel_Ready      : natural range 0 to 8          := 0;
    signal Filter_Kernel    : kernel;                                                       -- Filter kernel is read from memory
    signal Input_Pixel      : std_logic_vector(BPP-1 downto 0)  := (others => '0');             -- Pixel value, input
 --   signal Output_Pixel     : std_logic_vector(7 downto 0)  := (others => '0');             -- New pixel value determined by the filter
    signal FIR0_Do          : std_logic_vector((BPP+COEFF_WIDTH+2)-1 downto 0) := (others => '0');             -- Output of the first 1D FIR (bottom line)
    signal FIR1_Do          : std_logic_vector((BPP+COEFF_WIDTH+2)-1 downto 0) := (others => '0');             -- Output of the second 1D FIR (middle line)
    signal FIR2_Do          : std_logic_vector((BPP+COEFF_WIDTH+2)-1 downto 0) := (others => '0');             -- Output of the third 1D FIR (top line)
    signal FIR_Sum          : std_logic_vector((BPP+COEFF_WIDTH+2)-1 downto 0) := (others => '0');             -- Summing point for 3 FIR filters
    signal MAC              : std_logic_vector((BPP+COEFF_WIDTH+2)-1 downto 0) := (others => '0');             -- Sum of filters * scaling factor (scaling factor normally < 1)
    signal SF_Shift         : std_logic_vector(3 downto 0)  := (others => '0');
    signal MSB_Loc          : natural range 0 to (BPP+COEFF_WIDTH+2) := 0;

    -- Median sort signals
    signal Median_Pipe0 : Median_Array  := (others => (others => '0'));     -- Unsorted, weighted array of pixel values
    signal Median_Pipe1 : Median_Array  := (others => (others => '0'));     -- First pass bitonic sort (2 value packets)
    signal Median_Pipe2 : Median_Array  := (others => (others => '0'));     -- Second pass bitonic sort (4 value packets)
    signal Median_Pipe3 : Median_Array  := (others => (others => '0'));     -- Third pass bitonic sort (8 value packets) 
    signal Median_Pipe4 : Median_Array  := (others => (others => '0'));     -- Final pass bitonic sort (ascending order, [0] = lowest val, [15] = highest val, [7] = median value)
    signal Median_Pipe5 : Median_Array  := (others => (others => '0'));     -- Final pass bitonic sort (ascending order, [0] = lowest val, [15] = highest val, [7] = median value)
       
    -- Linebuffer 0 signals
    signal LB0_En_A,  LB0_En_B          : std_logic := '1';                                 -- Linebuffer 0, write enable, read enable
    signal LB0_Do                       : std_logic_vector(BPP-1 downto 0) := (others => '0');  -- Linebuffer 0 data out, read from RAM
--    signal LB0_Adr_A, LB0_Adr_B         : std_logic_vector(8 downto 0) := (others => '0');  -- Linebuffer 0 write (A) and read (B) addresses
    
    -- Linebuffer 1 connections
    signal LB1_En_A,  LB1_En_B          : std_logic := '0';                                 -- Write enable, read enable
    signal LB1_Do                       : std_logic_vector(BPP-1 downto 0) := (others => '0');  -- Data in, data out
--    signal LB1_Adr_A, LB1_Adr_B         : std_logic_vector(8 downto 0) := (others => '0');  -- Write address, read address
        
    -- 2D Filter uses 3 x 1D filters to create a 3x3 window
    component FIR_1D is
        port (
            -- Inputs
            Clk     :   in  std_logic;
            i_Reset :   in  std_logic;
            i_Data  :   in  std_logic_vector(BPP-1 downto 0);
            i_Coeff :   in  coeff_array;
            -- Outputs
            o_Data  :   out std_logic_vector((BPP+COEFF_WIDTH+2)-1 downto 0)    -- Input(n bits) * filter(8 bits) + pipelines (2 bits) = n + 10 bit output bus
        );
    end component;
    
    component RAM_DP is
        port (
            -- Inputs 
            Clk_a   : in std_logic;                         -- RAM write clock
            Clk_b   : in std_logic;                         -- RAM read clock
            Reset   : in std_logic;                         -- Reset to clear output
        -- Port A (Write)
            En_a    : in std_logic;                         -- Port A Enable
            Adr_a   : in std_logic_vector(LB_ADR_BUS_WIDTH-1 downto 0);      -- Port A (Write) Address
            Di      : in std_logic_vector(BPP-1 downto 0);      -- Port A (Write) Data In
        -- Port B (Read)
            En_b    : in std_logic;                         -- Port B Enable
            Adr_b   : in std_logic_vector(LB_ADR_BUS_WIDTH-1 downto 0);      -- Port B (Read) Address
            Do      : out std_logic_vector(BPP-1 downto 0)      -- Port B (Read) Data Out
        );
    end component;
    
begin

    Reset           <= i_Reset;
    Filter_Kernel   <= i_Kernel;
    SF_Shift        <= i_Scaling_Factor;
    Input_Pixel     <= i_Data;
    
    
    Line_Buffer0: RAM_DP
        port map (
            -- Inputs 
            Clk_a   => Clk,
            Clk_b   => Clk,
            Reset   => Reset,
            -- Port A (Write)
            En_a    => LB0_En_A,
            Adr_a   => Write_Adr,
            Di      => Input_Pixel,
            -- Port B (Read)
            En_b    => LB0_En_B,
            Adr_b   => Read_Adr,
            Do      => LB0_Do
        );
        
    Line_Buffer1: RAM_DP
        port map (
            -- Inputs 
            Clk_a   => Clk,
            Clk_b   => Clk,
            Reset   => Reset,
            -- Port A (Write)
            En_a    => LB1_En_A,
            Adr_a   => Write_Adr,
            Di      => LB0_Do,
            -- Port B (Read)
            En_b    => LB1_En_B,
            Adr_b   => Read_Adr,
            Do      => LB1_Do
        );
        
    FIR0: FIR_1D
        port map (
            -- Inputs
            Clk     => Clk, 
            i_Reset => Reset, 
            i_Data  => Input_Pixel,
            i_Coeff => Filter_Kernel(0),
            -- Outputs
            o_Data  => FIR0_Do
        );
    
    FIR1: FIR_1D
        port map (
            Clk     => Clk, 
            i_Reset => Reset, 
            i_Data  => LB0_Do,
            i_Coeff => Filter_Kernel(1),
            -- Outputs
            o_Data  => FIR1_Do
        );
        
    FIR2: FIR_1D
        port map (
            Clk     => Clk, 
            i_Reset => Reset, 
            i_Data  => LB1_Do,
            i_Coeff => Filter_Kernel(2),
            -- Outputs
            o_Data  => FIR2_Do
        );

    Write_Address_Counter: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (Adr_Cntr >= 319) then
                Adr_Cntr <= 0;    
                LB1_En_A <= '1';
                LB1_En_B <= '1';
            else
                Adr_Cntr <= Adr_Cntr + 1;
            end if;
            Write_Adr <= std_logic_vector(to_unsigned(Adr_Cntr, 9));
            if (Adr_Cntr = 0) then
                Read_Adr <= "100111111";
            else
                Read_Adr  <= std_logic_vector(to_unsigned(Adr_Cntr, 9) - 1);
            end if;
        end if;
    end process;
    
    Read_Address_Counter: process(Clk)
    begin
        if (rising_edge(Clk)) then
        
        end if;
    end process;
    
    MAC_SF: process(Clk)
    begin
        if(rising_edge(Clk)) then
            if (i_Median_En = '0') then
                --FIR_Sum <= resize(std_logic_vector(unsigned(FIR0_Do) + unsigned(FIR1_Do) + unsigned(FIR2_Do)), 20);
                FIR_Sum <= std_logic_vector(unsigned(FIR0_Do) + unsigned(FIR1_Do) + unsigned(FIR2_Do));
                MAC     <= std_logic_vector(shift_right(unsigned(FIR_Sum), to_integer(unsigned(SF_Shift))));
            end if;
        end if;
    end process;
    
    Output_Control: process(Clk)
    begin   
        if(rising_edge(Clk)) then
            if (i_Median_En = '0') then
--            if (Pixel_Ready = 8) then
                for i in MAC'high downto 7 loop
                    if MAC(i) = '1' then
                        MSB_Loc <= i;
                    end if;
                end loop;
                if(MSB_Loc >= 7) then
                    o_Data <= MAC(MSB_Loc downto MSB_Loc - 7);
                else
                    o_Data <= MAC(7 downto 0);
                end if;
--            else
--                Pixel_Ready <= Pixel_Ready + 1;
--                o_Data      <= (others => 'Z');
--            end if;
            else -- else median filter selected
                o_Data <= std_logic_vector( ((Median_Pipe4(7) + Median_Pipe4(8)) / 2));     -- output the median value, in the middle of point 7 and 8
            end if; -- median check
        end if; -- rising edge
    end process;
    
    -- Fully pipelined median sort using bitonic merge algorithm
    Median_Sort: process(Clk)
    begin
        if (rising_edge(Clk)) then      
                -- Shift data into weighted median array, stage 0 of the pipeline
                -- First row of window pixel values
                Median_Pipe0(0)  <= unsigned(i_Data);        -- Push new pixel data in
                Median_Pipe0(1)  <= Median_Pipe0(0);
                Median_Pipe0(2)  <= Median_Pipe0(0);
                Median_Pipe0(3)  <= Median_Pipe0(2);
                -- Second row of window values
                Median_Pipe0(4)  <= unsigned(LB0_Do);        -- Push new pixel value into row
                Median_Pipe0(5)  <= unsigned(LB0_Do);
                Median_Pipe0(6)  <= Median_Pipe0(5);
                Median_Pipe0(7)  <= Median_Pipe0(5);
                Median_Pipe0(8)  <= Median_Pipe0(5);
                Median_Pipe0(9)  <= Median_Pipe0(5);
                Median_Pipe0(10) <= Median_Pipe0(9);
                Median_Pipe0(11) <= Median_Pipe0(9);
                Median_Pipe0(12) <= unsigned(LB1_Do);
                Median_Pipe0(13) <= Median_Pipe0(12);
                Median_Pipe0(14) <= Median_Pipe0(12);
                Median_Pipe0(15) <= Median_Pipe0(14);
                
                -- Bitonic merge sort requires 2^N values, so force n(0) => 0
                -- Weighted median filter, corner pixels lowest weighting, centre pixel highest weighting                            
                                        
            -- SORT PIPELINE STEP 1
                -- STAGE 1
                for i in 0 to 7 loop
                    if (Median_Pipe0(i) > Median_Pipe0(i+8)) then
                        Median_Pipe1(i)   <= Median_Pipe0(i+8);
                        Median_Pipe1(i+8) <= Median_Pipe0(i);
                    else 
                        Median_Pipe1(i)   <= Median_Pipe0(i);
                        Median_Pipe1(i+8) <= Median_Pipe0(i+8);
                    end if;
                end loop;
                
            -- SORT PIPELINE STEP 2
                -- STAGE 1
                for i in 0 to 3 loop
                    if (Median_Pipe1(i) > Median_Pipe1(i+4)) then
                        Median_Pipe2(i)   <= Median_Pipe1(i+4);
                        Median_Pipe2(i+4) <= Median_Pipe1(i);
                    else
                        Median_Pipe2(i)   <= Median_Pipe1(i);
                        Median_Pipe2(i+4) <= Median_Pipe1(i+4);
                    end if;
                end loop;
                
                -- STAGE 2
                for i in 8 to 11 loop
                    if (Median_Pipe1(i) > Median_Pipe1(i+4)) then
                        Median_Pipe2(i)   <= Median_Pipe1(i+4);
                        Median_Pipe2(i+4) <= Median_Pipe1(i);
                    else
                        Median_Pipe2(i)   <= Median_Pipe1(i);
                        Median_Pipe2(i+4) <= Median_Pipe1(i+4);
                    end if;
                end loop;
                
            -- SORT PIPELINE STEP 3 
                -- STAGE 1
                for i in 0 to 1 loop
                    if (Median_Pipe2(i) > Median_Pipe2(i+2)) then
                        Median_Pipe3(i)   <= Median_Pipe2(i+2);
                        Median_Pipe3(i+2) <= Median_Pipe2(i);
                    else
                        Median_Pipe3(i)   <= Median_Pipe2(i);
                        Median_Pipe3(i+2) <= Median_Pipe2(i+2);
                    end if;
                end loop;
                -- STAGE 2
                for i in 4 to 5 loop
                    if (Median_Pipe2(i) > Median_Pipe2(i+2)) then
                        Median_Pipe3(i)   <= Median_Pipe2(i+2);
                        Median_Pipe3(i+2) <= Median_Pipe2(i);
                    else
                        Median_Pipe3(i)   <= Median_Pipe2(i);
                        Median_Pipe3(i+2) <= Median_Pipe2(i+2);
                    end if;
                end loop;
                -- STAGE 3
                for i in 8 to 9 loop
                    if (Median_Pipe2(i) > Median_Pipe2(i+2)) then
                        Median_Pipe3(i)   <= Median_Pipe2(i+2);
                        Median_Pipe3(i+2) <= Median_Pipe2(i);
                    else
                        Median_Pipe3(i)   <= Median_Pipe2(i);
                        Median_Pipe3(i+2) <= Median_Pipe2(i+2);
                    end if;
                end loop;
                -- STAGE 4
                for i in 12 to 13 loop
                    if (Median_Pipe2(i) > Median_Pipe2(i+2)) then
                        Median_Pipe3(i)   <= Median_Pipe2(i+2);
                        Median_Pipe3(i+2) <= Median_Pipe2(i);
                    else
                        Median_Pipe3(i)   <= Median_Pipe2(i);
                        Median_Pipe3(i+2) <= Median_Pipe2(i+2);
                    end if;
                end loop;
                                            
            -- SORT PIPELINE STEP 4
                -- STAGE 1
                for i in 0 to 7 loop
                    if (Median_Pipe3(2*i) > Median_Pipe3(2*i+1)) then
                        Median_Pipe4((2*i)+1) <= Median_Pipe3(2*i);
                        Median_Pipe4(2*i)     <= Median_Pipe3((2*i)+1);
                    else
                        Median_Pipe4(2*i)     <= Median_Pipe3(2*i);
                        Median_Pipe4((2*i)+1) <= Median_Pipe3((2*i)+1);
                    end if;
                end loop;    

            end if;     
        end process;
    
end Behavioral;
