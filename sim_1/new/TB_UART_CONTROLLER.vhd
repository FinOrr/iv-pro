library WORK;
use WORK.SYS_PARAM.ALL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_UART_CONTROLLER is
--  Port ( );
end TB_UART_CONTROLLER;

architecture Behavioral of TB_UART_CONTROLLER is

    component UART_Controller is
        port (
            -- Inputs
            Clk             : in std_logic;                         -- System clock
            i_Reset         : in std_logic;                         -- Global reset input
            i_Send          : in std_logic;                         -- Trigger to start sending frame buffer
            i_RX            : in std_logic;
            i_Di            : in std_logic_vector(7 downto 0);
            o_Input_Mode    : out std_logic;
            o_Output_Mode   : out std_logic;
            o_Contrast_En   : out std_logic;
            o_Threshold_En  : out std_logic;
            o_Median_En     : out std_logic;
            o_Coef_En       : out std_logic;
            o_Coef_Adr      : out std_logic_vector(3 downto 0);
            o_Read_Adr      : out std_logic_vector(FB_ADR_BUS_WIDTH -1 downto 0); -- Address of pixel value in frame buffer
            o_Write_Adr     : out std_logic_vector(FB_ADR_BUS_WIDTH -1 downto 0); -- Address of pixel value in frame buffer
            o_Write_En      : out std_logic;                        -- Enable the frame buffer to write the data value
            o_Do            : out std_logic_vector(7 downto 0);
            o_Threshold     : out std_logic_vector(7 downto 0);     -- Threshold value for threshold function
            o_TX            : out std_logic                         -- Bit to be transmitted 
        );
    end component;
    
    signal Clk          : std_logic := '0';
    signal Send         : std_logic := '0';
    signal Reset        : std_logic := '0';
    signal RX           : std_logic := '1';
    signal Di           : std_logic_vector(7 downto 0) := x"00";
    signal Input_Mode   : std_logic := '0';
    signal Output_Mode  : std_logic := '0';
    signal Contrast_En  : std_logic := '0';
    signal Threshold_En : std_logic := '0';
    signal Median_En    : std_logic := '0';
    signal Coef_En      : std_logic := '0';
    signal Coef_Adr     : std_logic_vector(3 downto 0) := x"0";
    signal Read_Adr     : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal Write_Adr    : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal Write_En     : std_logic := '0';
    signal Do           : std_logic_vector(7 downto 0) := (others => '0');
    signal Threshold    : std_logic_vector(7 downto 0) := (others => '0');
    signal TX           : std_logic := '0';
    
    signal XNOR_Bit : std_logic := '0';
    signal LFSR : std_logic_vector(32 downto 0) := ("011010010110100101001011101001110");     -- random seed for pseudo random number generator 
    constant Sec : time := 1000 ms;
    constant Baud_Freq : natural := 115200;
    constant Clk_Period : time := 10 ns;
        
begin

    XNOR_Bit <= LFSR(32) XNOR LFSR(22) XNOR LFSR(2) XNOR LFSR(1);

    UUT: UART_Controller
        port map (
            Clk             => Clk,             -- Input
            i_Reset         => Send,            -- Input
            i_Send          => Reset,           -- Input
            i_RX            => RX,              -- Input
            i_Di            => Di,              -- Input
            o_Input_Mode    => Input_Mode,  
            o_Output_Mode   => Output_Mode, 
            o_Contrast_En   => Contrast_En, 
            o_Threshold_En  => Threshold_En,
            o_Median_En     => Median_En,   
            o_Coef_En       => Coef_En,     
            o_Coef_Adr      => Coef_Adr,    
            o_Read_Adr      => Read_Adr,    
            o_Write_Adr     => Write_Adr,   
            o_Write_En      => Write_En,    
            o_Do            => Do,          
            o_Threshold     => Threshold,   
            o_TX            => TX          
        );
        
    Clocking: process
    begin
        Clk <= '1';
        wait for 5 ns;
        Clk <= '0';
        wait for 5 ns;
    end process;
    
    PRNG: process
    begin
        LFSR <= LFSR(31 downto 0) & XNOR_Bit;
        wait for Sec / Baud_Freq;
    end process;
    
    RX_Test: process
    begin
        Send <= '0';
        Reset <= '0';
        Di <= (others => '0');
        -- UART is little endian, so LSB arrives first!
        -- TEST 1: Gaussian Blur Window Operation, using camera input and vga output
            ---- BYTE 0: FILTER TYPE  ----
            -- Bits 0 -> 3 : 0000. This command sets the UART RX as the input, UART TX as output
            -- Bits 4 -> 7 : 0000. This command enables window filtering
        -- Start bit pulls line low
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';                  -- Bit 0
        wait for sec / baud_freq;
        RX <= '0';                  
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';                  -- Bit 7
        wait for sec / baud_freq;
        -- Stop bit pulls line high
        RX <= '1';
        wait for sec / baud_freq;
        
            ---- BYTE 1 : ROM ADR ----
        -- Start bit pulls line low
        RX <= '0';
        wait for sec / baud_freq;
        -- Data begin
        RX <= '1';                  -- Bit 0
        wait for sec / baud_freq;
        RX <= '1';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';                  -- Bit 1
        wait for sec / baud_freq;
        -- Stop bit pulls line high
        RX <= '1';
        wait for sec / baud_freq; 
               
            ---- BYTE 2 : Threshold Value ----
        -- Start bit pulls line low
        RX <= '0';
        wait for sec / baud_freq;
        -- Data begin
        RX <= '0';                  -- Bit 0
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';
        wait for sec / baud_freq;
        RX <= '0';                  -- Bit 1
        wait for sec / baud_freq;
        -- Stop bit pulls line high
        RX <= '1';
        wait for sec / baud_freq;

        WAIT;
    end process;
end Behavioral;
