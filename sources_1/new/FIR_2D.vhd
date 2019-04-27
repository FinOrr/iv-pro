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
        i_Enable            :   in  std_logic;
        i_Kernel            :   in  kernel;                         -- Input data
        i_Scaling_Factor    :   in  std_logic_vector(3 downto 0);
        i_Data              :   in  std_logic_vector(BPP-1 downto 0);
        -- OUTPUTS
        o_Data              :   out std_logic_vector(BPP-1 downto 0);
        o_Write_Adr         :   out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
        o_Write_En          :   out std_logic
    );
end FIR_2D;

architecture Behavioral of FIR_2D is

    signal Reset           : std_logic := '0';                                                 -- Reset input, buffered

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


       
    -- Linebuffer Control Signals
    signal LB0_Do                       : std_logic_vector(BPP-1 downto 0) := (others => '0');  -- Linebuffer 0 data out
    signal LB1_Do                       : std_logic_vector(BPP-1 downto 0) := (others => '0');  -- Line buffer 1 data out
    signal LB_Adr     : unsigned(LB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');               -- Linebuffer RAM address   

   
    -- Output Frame Buffer signals
    signal FB_Adr : unsigned(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal FB_We  : std_logic := '0';
    signal Output_En : std_logic := '0';
    
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
    
    component RAM_LB is
        port (
            -- CLOCK 
            Clk     : in std_logic;                         
            Adr   : in std_logic_vector(LB_ADR_BUS_WIDTH-1 downto 0);
            Di    : in std_logic_vector(BPP-1 downto 0);    
            We    : in std_logic;                     -- Port A Enable
            Do    : out std_logic_vector(BPP-1 downto 0)
        );
    end component;
    
begin
    
    ------------------------------------------
    ------      IO Connections          ------
    ------------------------------------------
    Reset           <= i_Reset;
    Filter_Kernel   <= i_Kernel;
    SF_Shift        <= i_Scaling_Factor;
    Input_Pixel     <= i_Data;
    o_Write_Adr     <= std_logic_vector(FB_Adr);
    o_Write_En      <= FB_We;


    ------------------------------------------
    ------          Line Buffers        ------
    ------------------------------------------
    Line_Buffer0: RAM_LB
        port map (
            Clk     => Clk,
            Adr   => std_logic_vector(LB_Adr),
            Di    => Input_Pixel,
            We    => '1',
            Do    => LB0_Do
        );
        
    Line_Buffer1: RAM_LB
        port map (       
            Clk     => Clk,
            Adr   => std_logic_vector(LB_Adr),
            Di    => LB0_Do,
            We    => '1',
            Do    => LB1_Do
        );
    
    
    --------------------------------------
    ------          1D FIR          ------
    --------------------------------------
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
        
        
    ------------------------------------------------------
    -------   LINE & FRAME BUFFER ADR CONTROLLER    ------
    ------------------------------------------------------
    Address_Control: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (i_Enable = '1') then
                -- LINE BUFFER CONTROL
                if (LB_Adr >= FRAME_WIDTH-1) then
                    LB_Adr <= (others => '0');
                else
                    LB_Adr <= LB_Adr + 1;
                end if;
                LB_Adr <= LB_Adr;    -- Write address is one clock cycle behind read address
                
                -- FRAME BUFFER CONTROL
                if (FB_Adr <= FRAME_PIXELS-1) then
                    FB_We <= '1';
                    FB_Adr <= FB_Adr + 1;
                else
                    FB_Adr <= (others => '0');
                    FB_We <= '0';
                end if;
            end if;
        end if;
    end process;
       
       
    ------------------------------------------------------
    -------          MACC SCALING FACTOR            ------
    ------------------------------------------------------
    MAC_SF: process(Clk)
    begin
        if(rising_edge(Clk)) then
            --FIR_Sum <= resize(std_logic_vector(unsigned(FIR0_Do) + unsigned(FIR1_Do) + unsigned(FIR2_Do)), 20);
            FIR_Sum <= std_logic_vector(unsigned(FIR0_Do) + unsigned(FIR1_Do) + unsigned(FIR2_Do));
            MAC     <= std_logic_vector(shift_right(unsigned(FIR_Sum), to_integer(unsigned(SF_Shift))));
        end if;
    end process;
    
    
    ------------------------------------------------------
    -------             OUTPUT CONTROLLER           ------
    ------------------------------------------------------
    Output_Control: process(Clk)
    begin   
        if(rising_edge(Clk)) then
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
        end if; -- rising edge
    end process;
        
end Behavioral;