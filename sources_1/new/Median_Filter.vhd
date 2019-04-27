----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.04.2019 13:55:04
-- Design Name: 
-- Module Name: Median_Filter - Behavioral
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
use WORK.FILTER_TYPES.ALL;


entity Median_Filter is
    port (
        -- Inputs
        Clk         : in std_logic;                             -- System clock
        i_Reset     : in std_logic;                             -- Global reset
        i_Data      : in std_logic_vector(BPP-1 downto 0);      -- Input data, one pixel at a time
        i_Enable    : in std_logic;                             -- Sort enable toggle
        -- Output 
        o_FBO_Adr   : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);    -- Frame buffer address
        o_FBO_Data  : out std_logic_vector(BPP-1 downto 0);      -- Median value
        o_FBO_We    : out std_logic
    );
end Median_Filter;

architecture Behavioral of Median_Filter is
    
    component Bitonic_Sorter is
        port (
            -- Inputs
            Clk     : in std_logic;
            Value_A : in unsigned(BPP-1 downto 0);
            Value_B : in unsigned(BPP-1 downto 0);
            -- Outputs
            Lesser  : out unsigned(BPP-1 downto 0);
            Greater : out unsigned(BPP-1 downto 0)
        );
    end component;
        
    component RAM_LB is
        port (
            Clk   : in std_logic;                     -- RAM write port clock
            Adr   : in std_logic_vector(LB_ADR_BUS_WIDTH-1 downto 0);
            Di    : in std_logic_vector(BPP-1 downto 0);    
            We    : in std_logic;                     -- Port A Enable
            Do    : out std_logic_vector(BPP-1 downto 0)
        );
    end component;
    
    -- Internal linebuffer control signals
    signal LB_Adr : unsigned(LB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal LB0_Do       : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal LB1_Do       : std_logic_vector(BPP-1 downto 0) := (others => '0');
    
    -- Output frame buffer control signals
    signal FBO_Adr      : unsigned(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal FBO_We       : std_logic := '0';
    
    -- Median sort signals
    signal Median_Pipe0  : Median_Array := (others => (others => '0'));     -- Unsorted, weighted array of pixel values
    signal Median_Pipe1  : Median_Array := (others => (others => '0'));     -- First pass bitonic sort (2 value packets)
    signal Median_Pipe2  : Median_Array := (others => (others => '0'));     -- Second pass bitonic sort (4 value packets)
    signal Median_Pipe3  : Median_Array := (others => (others => '0'));     -- Third pass bitonic sort (8 value packets) 
    signal Median_Pipe4  : Median_Array := (others => (others => '0'));     -- Final pass bitonic sort (ascending order, [0] = lowest val, [15] = highest val, [7] = median value)
    signal Median_Pipe5  : Median_Array := (others => (others => '0'));     -- Final pass bitonic sort (ascending order, [0] = lowest val, [15] = highest val, [7] = median value)
    signal Median_Pipe6  : Median_Array := (others => (others => '0'));     -- Final pass bitonic sort (ascending order, [0] = lowest val, [15] = highest val, [7] = median value)
    signal Median_Pipe7  : Median_Array := (others => (others => '0'));     -- Final pass bitonic sort (ascending order, [0] = lowest val, [15] = highest val, [7] = median value)
    signal Median_Pipe8  : Median_Array := (others => (others => '0'));     -- Final pass bitonic sort (ascending order, [0] = lowest val, [15] = highest val, [7] = median value)
    signal Median_Pipe9  : Median_Array := (others => (others => '0'));     -- Final pass bitonic sort (ascending order, [0] = lowest val, [15] = highest val, [7] = median value)
    signal Median_Pipe10 : Median_Array := (others => (others => '0'));     -- Final pass bitonic sort (ascending order, [0] = lowest val, [15] = highest val, [7] = median value)
    
begin

    ----------------------------------------------
    ------         Lines Buffers            ------
    ----------------------------------------------
    Line_Buffer0: RAM_LB
        port map (
            Clk   => Clk,
            Adr   => std_logic_vector(LB_Adr),
            Di    => i_Data,
            We    => '1',
            Do    => LB0_Do
        );
        
    Line_Buffer1: RAM_LB
        port map (       
            -- CLOCK 
            Clk     => Clk,
            -- PORT A
            Adr   => std_logic_vector(LB_Adr),
            Di    => LB0_Do,
            We    => '1',
            Do    => LB1_Do
        );


    ----------------------------------------------
    ------          I/O Control             ------
    ----------------------------------------------
    o_FBO_Adr <= std_logic_vector(FBO_Adr);
    o_FBO_Data <= std_logic_vector(Median_Pipe10(8));

    
    ----------------------------------------------
    ----          Address Controller          ----
    ----------------------------------------------
    ADR_CTRL: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (i_Enable = '1') then
                if (LB_Adr < FRAME_WIDTH-1) then      -- If not end of line
                    LB_Adr <= LB_Adr + 1;         -- Move to next pixel   
                     
                else
                    LB_Adr <= (others => '0');         -- If end of line, reset LB address
                end if;
                
                if (FBO_Adr < FRAME_PIXELS-1) then
                    FBO_Adr <= FBO_Adr + 1;
                else
                    FBO_Adr <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    
    
    ---------------------------------------------------------------
    ----                                                       ----
    -- Fully pipelined median sort using bitonic merge algorithm --
    ----                                                       ----
    ---------------------------------------------------------------
    Sort: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (i_Enable = '1') then 
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
            end if;     
        end if;
    end process;
                    
    ----------------------------------------------
    --                  STAGE 1                 --
    ----------------------------------------------
    Generate_Pipeline1: for i in 0 to 7 generate
        Step1: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe0(2*i),
                Value_B => Median_Pipe0((2*i)+1),
                Lesser  => Median_Pipe1(2*i),
                Greater => Median_Pipe1((2*i)+1)
            );
    end generate;
    
    ----------------------------------------------
    --                  STAGE 2                 --
    ----------------------------------------------       
    Generate_Pipeline2: for i in 0 to 3 generate
        Step2: Bitonic_Sorter   -- Sort outer values of 4 samples
            port map (
                Clk     => Clk,                
                Value_A => Median_Pipe1(4*i),
                Value_B => Median_Pipe1((4*i)+3),
                Lesser  => Median_Pipe2(4*i),
                Greater => Median_Pipe2((4*i)+3)
            );
        Step3: Bitonic_Sorter   -- Sort inner values of 4 samples
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe1((4*i)+1),
                Value_B => Median_Pipe1((4*i)+2),
                Lesser  => Median_Pipe2((4*i)+1),
                Greater => Median_Pipe2((4*i)+2)
            );
    end generate;
    
    Generate_Pipeline3: for i in 0 to 7 generate    -- Compare by pairing values
        Step4: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe2(2*i),
                Value_B => Median_Pipe2((2*i)+1),
                Lesser  => Median_Pipe3(2*i),
                Greater => Median_Pipe3((2*i)+1)
            );
    end generate;
    
    ----------------------------------------------
    --                  STAGE 3                 --
    ----------------------------------------------
    Generate_Pipeline4: for i in 0 to 1 generate
        Step5: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe3(8*i),
                Value_B => Median_Pipe3((8*i)+7),
                Lesser  => Median_Pipe4(8*i),
                Greater => Median_Pipe4((8*i)+7)
            );
        Step6: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe3((8*i)+1),
                Value_B => Median_Pipe3((8*i)+6),
                Lesser  => Median_Pipe4((8*i)+1),
                Greater => Median_Pipe4((8*i)+6)
            );
        Step7: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe3((8*i)+2),
                Value_B => Median_Pipe3((8*i)+5),
                Lesser  => Median_Pipe4((8*i)+2),
                Greater => Median_Pipe4((8*i)+5)
            );
        Step8: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe3((8*i)+3),
                Value_B => Median_Pipe3((8*i)+4),
                Lesser  => Median_Pipe4((8*i)+3),
                Greater => Median_Pipe4((8*i)+4)
            );
    end generate;
    
    Generate_Pipeline5: for i in 0 to 3 generate
        Step9: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe4(4*i),
                Value_B => Median_Pipe4((4*i)+2),
                Lesser  => Median_Pipe5(4*i),
                Greater => Median_Pipe5((4*i)+2)
            );
        Step10: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe4((4*i)+1),
                Value_B => Median_Pipe4((4*i)+3),
                Lesser  => Median_Pipe5((4*i)+1),
                Greater => Median_Pipe5((4*i)+3)
            );
    end generate;
    
    Generate_Pipeline6: for i in 0 to 7 generate
        Step11: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe5(2*i),
                Value_B => Median_Pipe5((2*i)+1),
                Lesser  => Median_Pipe6(2*i),
                Greater => Median_Pipe6((2*i)+1)
            );
    end generate;
        
    
    ----------------------------------------------
    --                  STAGE 4                 --
    ----------------------------------------------
    Generate_Pipeline7: for i in 0 to 7 generate
        Step12: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe6(i),
                Value_B => Median_Pipe6((i+15)-(2*i)),
                Lesser  => Median_Pipe7(i),
                Greater => Median_Pipe7((i+15)-(2*i))
            );
    end generate;
    
    Generate_Pipeline8: for i in 0 to 3 generate
        Step13: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe7(i),
                Value_B => Median_Pipe7(i+4),
                Lesser  => Median_Pipe8(i),
                Greater => Median_Pipe8(i+4)
            );
        Step14: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe7(i+8),
                Value_B => Median_Pipe7(i+12),
                Lesser  => Median_Pipe8(i+8),
                Greater => Median_Pipe8(i+12)
            );
    end generate;
    
    Generate_Pipeline9: for i in 0 to 7 generate
        EVEN: if (i=0 or i=2 or i=4 or i=6) generate
            Step15: Bitonic_Sorter
                port map (
                    Clk     => Clk,
                    Value_A => Median_Pipe8(2*i),
                    Value_B => Median_Pipe8((2*i)+2),
                    Lesser  => Median_Pipe9(2*i),
                    Greater => Median_Pipe9((2*i)+2)
                );
        end generate EVEN;
        ODD: if (i=1 or i=3 or i=5 or i=7) generate
            Step16: Bitonic_Sorter
                port map (
                    Clk     => Clk,
                    Value_A => Median_Pipe8((2*i)-1),
                    Value_B => Median_Pipe8((2*i)+1),
                    Lesser  => Median_Pipe9((2*i)-1),
                    Greater => Median_Pipe9((2*i)+1)
                );
        end generate ODD;
    end generate;
    
    Generate_Pipeline10: for i in 0 to 7 generate
        Step17: Bitonic_Sorter
            port map (
                Clk     => Clk,
                Value_A => Median_Pipe9(2*i),
                Value_B => Median_Pipe9((2*i)+1),
                Lesser  => Median_Pipe10(2*i),
                Greater => Median_Pipe10((2*i)+1)
            );
    end generate;
end Behavioral;
