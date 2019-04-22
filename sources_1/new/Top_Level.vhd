----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2019 10:55:17
-- Design Name: 
-- Module Name: Top_Level - Behavioral
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

library WORK;
use WORK.SYS_PARAM.ALL;
use WORK.FILTER_TYPES.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity Top_Level is
    port (
        -- Inputs
        Clk_100      :  in  std_logic;                      -- System clock
        RESET        :  in  std_logic;                      -- Reset button
        RESEND       :  in  std_logic;
        OV7670_PCLK  :  in  std_logic;                      -- Camera PCLK
        OV7670_HREF  :  in  std_logic;   
        OV7670_DATA  :  in  std_logic_vector(7 downto 0);
        OV7670_VSYNC :  in  std_logic;
        UART_RX      :  in  std_logic;
        -- Output
        CONFIG_LED   :  out std_logic;
        OV7670_XCLK  :  out std_logic;
        OV7670_RESET :  out std_logic;
        OV7670_PWDN  :  out std_logic;
        OV7670_SCL   :  out std_logic;
        OV7670_SDA   :  inout std_logic;        
        UART_TX      :  out std_logic;
        VGA_RED      :  out std_logic_vector(3 downto 0);
        VGA_GREEN    :  out std_logic_vector(3 downto 0);
        VGA_BLUE     :  out std_logic_vector(3 downto 0);
        VGA_HSYNC    :  out std_logic;
        VGA_VSYNC    :  out std_logic
    );
end Top_Level;

architecture Behavioral of Top_Level is
    
    component UART_Controller is
        port (
            -- Inputs                                                                        
            Clk             : in std_logic;                         -- System clock          
            i_Reset         : in std_logic;                         -- Global reset input    
            i_Send          : in std_logic;                         -- Trigger to start sendi
            i_RX            : in std_logic;                                                  
            i_FB_Byte       : in std_logic_vector(7 downto 0);                               
            -- Outputs                     
            o_Input_Mode    : out std_logic;                                                  
            o_Contrast_En   : out std_logic;                                                 
            o_Threshold_En  : out std_logic;                                                 
            o_Median_En     : out std_logic;                                                 
            o_Coef_En       : out std_logic;                                                 
            o_Coef_Adr      : out std_logic_vector(7 downto 0);                              
            o_Adr           : out std_logic_vector(FB_ADR_BUS_WIDTH -1 downto 0); -- Address 
            o_Write_En      : out std_logic;                        -- Enable the frame buffe
            o_Read_En       : out std_logic;                        -- Enable the read port o
            o_FB_Byte       : out std_logic_vector(7 downto 0);                              
            o_Threshold     : out std_logic_vector(7 downto 0);     -- Threshold value for th
            o_TX            : out std_logic                         -- Bit to be transmitted 
        );
    end component;
    
    component OV7670_Controller is
        port (
            clk    : in    STD_LOGIC;
            resend : in    STD_LOGIC;
            config_finished : out std_logic;
            sioc  : out   STD_LOGIC;
            siod  : inout STD_LOGIC;
            reset : out   STD_LOGIC;
            pwdn  : out   STD_LOGIC;
            xclk  : out   STD_LOGIC
        );
    end component;
    
    component Filter_ROM is
        port(
            -- Inputs 
            Clk     : in std_logic;                     -- System Clock
            Reset   : in std_logic;                     -- Reset to clear output
            -- Port (Read)
            En      : in std_logic;                     -- Port B Enable
            Adr     : in std_logic_vector(5 downto 0); -- Port B (Read) Address
            Do      : out std_logic_vector(7 downto 0) -- Port B (Read) Data Out
        );
    end component;
    
    -- Frame Buffer
    component RAM_FB is                                                                                                    
        port (
            -- CLOCK 
            Clk     : in std_logic;                     -- RAM write port clock
            -- PORT A
            A_Adr   : in std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
            A_Di    : in std_logic_vector(BPP-1 downto 0);    
            A_We    : in std_logic;                     -- Port A Enable
            A_Do    : out std_logic_vector(BPP-1 downto 0);
            -- PORT B
            B_Adr   : in std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
            B_Di    : in std_logic_vector(BPP-1 downto 0);
            B_We    : in std_logic;
            B_Do    : out std_logic_vector(BPP-1 downto 0)
        );                                                                                                        
    end component;                                                                                                         
    
    component OV7670_Capture is
        port (
            -- Inputs
            i_Pixel_Clk     :   in  std_logic;
            i_Clk_25        :   in  std_logic;
            i_HRef          :   in  std_logic;
            i_Pixel_Data    :   in  std_logic_vector(7 downto 0);
            i_VSync         :   in  std_logic;
            i_Active        :   in  std_logic;
            -- Outputs
            o_We            :   out std_logic;       
            o_Adr           :   out std_logic_vector(FB_ADR_BUS_WIDTH - 1 downto 0);        
            o_Do            :   out std_logic_vector(BPP-1 downto 0)
        );
    end component;
       
    -- 2D Filter
    component FIR_2D is
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
    end component;
    
    -- Contrast Stretching filter
    component Contrast_Filter is
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
    end component;
    
    component Threshold_Filter is
        port (
            Clk         : in std_logic;
            i_Enable    : in std_logic;
            i_Data      : in std_logic_vector(BPP-1 downto 0);
            i_Threshold : in std_logic_vector(7 downto 0);
            o_Read_Adr  : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
            o_Write_Adr : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
            o_Write_En  : out std_logic;
            o_Data      : out std_logic_vector(BPP-1 downto 0)
        );
    end component;
       
    -- VGA Controller
    component VGA_Controller is
        port (
            -- Inputs
            Clk          : in std_logic;
            i_Pixel_Data : in std_logic_vector(BPP-1 downto 0);
            -- Outputs
            o_Active    : out std_logic; 
            o_HSync     : out std_logic;
            o_VSync     : out std_logic;
            o_RED       : out std_logic_vector(3 downto 0);
            o_BLUE      : out std_logic_vector(3 downto 0);
            o_GREEN     : out std_logic_vector(3 downto 0)
        );
    end component;
    
    -- Signal generator used to generate clocks
    component Signal_Generator is
        generic (
            Frequency : natural
        );
        port (
            i_Clk    : in  std_logic;
            o_Signal : out std_logic
        );
    end component;  
      
    -- Clock signals
    signal Clk_25   :   std_logic := '0';       -- 25MHz clock, used to drive VGA display
    signal Clk_50   :   std_logic := '0';       -- 50MHz clock, used to drive camera
    
    -- Data captured by the camera is fed directly into the VGA display
    signal VGA_Fetch_Adr    : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
    signal VGA_Fetch_Data   : std_logic_vector(BPP-1 downto 0);
    signal VGA_Fetch_Count  : unsigned(LB_ADR_BUS_WIDTH -1 downto 0) := to_unsigned(FRAME_WIDTH-1, LB_ADR_BUS_WIDTH);
    signal VGA_Clk_Div      : std_logic := '1';
    signal VGA_Active       : std_logic := '0';
    
    -- Reading filter parameters from block ram
    signal Read_Filter_En   : std_logic := '0';
    signal Read_Filter_Adr  : std_logic_vector(5 downto 0) := (others => '0');
    signal Read_Filter_Coef : std_logic_vector(7 downto 0) := (others => '0');

    -- Input Frame Buffer Signals
    -- Port A --
    signal FB0_A_We      : std_logic := '0';
    signal FB0_A_Adr     : std_logic_vector(FB_ADR_BUS_WIDTH -1 downto 0) := (others => '0');
    signal FB0_A_Di      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal FB0_A_Do      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    -- Port B --
    signal FB0_B_We      : std_logic := '0';
    signal FB0_B_Adr     : std_logic_vector(FB_ADR_BUS_WIDTH -1 downto 0) := (others => '0');
    signal FB0_B_Di      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal FB0_B_Do      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    
    
    signal UART_Send        : std_logic := '0';
    signal Output_FB_Data   : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal Threshold        : std_logic_vector(7 downto 0) := (others => '0');
    
    signal ROM_EN           : std_logic := '0';
    signal ROM_ADR          : std_logic_vector(BPP-1 downto 0) := (others => '0');        
    signal Contrast_En      : std_logic := '0';
    signal Threshold_En     : std_logic := '0';
    signal Median_En        : std_logic := '0';  
    
    -- Pixel data can come from the camera module OR from UART
    -- CAMERA --
    signal CAM_We   : std_logic := '0';
    signal CAM_Adr  : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal CAM_Do   : std_logic_vector(BPP-1 downto 0) := (others => '0');
    -- UART --
    signal UART_We   : std_logic := '0';
    signal UART_Adr  : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal UART_Do   : std_logic_vector(BPP-1 downto 0) := (others => '0');
    
    signal Input_Mode : std_logic := '0';
begin
    
    OV7670_RESET <= not RESET;      -- Reset active low, normal mode high
    OV7670_PWDN  <= '0';            -- Power down device 
    OV7670_XCLK  <= Clk_50;

    -- 25MHz Clock Gen
    Clock_25MHz: Signal_Generator
        generic map (
            Frequency   => 25_000_000
        )
        port map (
            i_Clk       => Clk_100,
            o_Signal    => Clk_25
        );

    -- 50MHz Clock generator
    Clock_50MHz: Signal_Generator
        generic map (
            Frequency   => 50_000_000
        )
        port map (
            i_Clk       => Clk_100,
            o_Signal    => Clk_50
        );
   
   ROM: Filter_ROM
        port map (
        -- Inputs 
            Clk    => Clk_100, 
            Reset  => RESET,
         -- Port (Read)
            En     => Read_Filter_En,
            Adr    => Read_Filter_Adr,
            Do     => Read_Filter_Coef
        );
       
    Filter_2D: FIR_2D
        port map (
            -- INPUTS       
            Clk                 => Clk_100, 
            i_Reset             => Reset,
            i_Kernel            => OPEN,
            i_Scaling_Factor    => Filter_SF,
            i_Data              => 
            i_Median_En     
            -- OUTPUTS      
            o_Data          
        );
        
    Contrast: Contrast_Filter
        port map (
            -- Inputs   
            Clk         =>
            i_Enable    =>
            i_Data      =>
            -- Outputs  
            o_Data      =>
            o_Write_Adr =>
            o_Read_Adr  =>
            o_Write_En  =>
        );
        
    Threshold: Threshold_Filter
        port map (
            Clk         =>
            i_Enable    =>
            i_Data      =>
            i_Threshold =>
            o_Read_Adr  =>
            o_Write_Adr =>
            o_Write_En  =>
            o_Data      =>
        );
       
    Camera_Capture: OV7670_Capture
        port map (
            -- Inputs
            i_Pixel_Clk     => OV7670_PCLK,
            i_Clk_25        => Clk_25,
            i_HRef          => OV7670_HREF,
            i_Pixel_Data    => OV7670_DATA,
            i_VSync         => OV7670_VSYNC,
            i_Active        => VGA_Active,
            -- Outputs
            o_We            => CAM_We,       
            o_Adr           => CAM_Adr,        
            o_Do            => CAM_Do
        );
    
    -- Frame buffer 0 : holds the unprocessed image
    Frame_Buffer_IN : RAM_FB
        port map (         
           -- CLOCK 
           Clk     => OV7670_PCLK,
           -- PORT A
           A_Adr   => FB0_A_Adr,
           A_Di    => FB0_A_Di,    
           A_We    => FB0_A_We,                     -- Port A Enable
           A_Do    => FB0_A_Do,
       -- PORT B
           B_Adr   => FB0_B_Adr,
           B_Di    => FB0_B_Di,
           B_We    => FB0_B_We,
           B_Do    => FB0_B_Do
        );
        
    with Input_Mode select
        FB0_A_Adr <= CAM_Adr when '0',
                     UART_Adr when '1';
    with Input_Mode select
        FB0_A_Di <= CAM_Do when '0',
                    UART_Do when '1';
    with Input_Mode select
        FB0_A_We <= CAM_We when '0',
                    UART_We when '1';
        
    
    
    UART: UART_Controller
        port map (
            -- Inputs
            Clk             => Clk_100,
            i_Reset         => RESET,
            i_Send          => UART_Send,
            i_RX            => UART_RX,
            i_FB_Byte       => Output_FB_Data,
            -- Outputs      
            o_Input_Mode    => Input_Mode,
            o_Adr           => UART_Adr,
            o_Coef_En       => ROM_En,
            o_Coef_Adr      => ROM_Adr,
            o_Write_En      => UART_We,
            o_FB_Byte       => UART_Do,
            o_Contrast_En   => Contrast_En,
            o_Threshold_En  => Threshold_En,
            o_Median_En     => Median_En,
            o_Threshold     => Threshold,        

            o_TX            => UART_TX 
        );
    
    -- VGA Controller
    VGA_DISPLAY: VGA_Controller
        port map(
            -- Input
            Clk             => Clk_25, 
            i_Pixel_Data    => FB0_B_Do,
            -- Output
            o_Active        => VGA_Active,
            o_HSync         => VGA_HSYNC,
            o_VSync         => VGA_VSYNC,
            o_RED           => VGA_RED,
            o_BLUE          => VGA_BLUE,
            o_GREEN         => VGA_GREEN
        );    
    
end Behavioral;