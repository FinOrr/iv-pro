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
        OV7670_PCLK  :  in  std_logic;                      -- Camera PCLK
        OV7670_HREF  :  in  std_logic;   
        OV7670_DATA  :  in  std_logic_vector(7 downto 0);
        OV7670_VSYNC :  in  std_logic;
        UART_RX      :  in  std_logic;
        -- Output
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
            i_Send          : in std_logic;                         -- Trigger to start sending
            i_RX            : in std_logic;                                                  
            i_Di            : in std_logic_vector(7 downto 0);                               
            -- Outputs                     
            o_Input_Mode    : out std_logic;                                                  
            o_Output_Mode   : out std_logic;                                                  
            o_Contrast_En   : out std_logic;                                                 
            o_Threshold_En  : out std_logic;                                                 
            o_Median_En     : out std_logic;                                                 
            o_Coef_En       : out std_logic;                                                 
            o_Coef_Adr      : out std_logic_vector(3 downto 0);                              
            o_Read_Adr      : out std_logic_vector(FB_ADR_BUS_WIDTH -1 downto 0); -- FBO read address 
            o_Write_Adr     : out std_logic_vector(FB_ADR_BUS_WIDTH -1 downto 0); -- FBI write address 
            o_Write_En      : out std_logic;                        -- Enable the frame buffer writing port
            o_Do            : out std_logic_vector(7 downto 0);                              
            o_Threshold     : out std_logic_vector(7 downto 0);     -- Threshold value for the threshold filter
            o_TX            : out std_logic                         -- Bit to be transmitted 
        );
    end component;
    
--    component OV7670_Controller is
--        port (
--            clk    : in    STD_LOGIC;
--            resend : in    STD_LOGIC;
--            config_finished : out std_logic;
--            sioc  : out   STD_LOGIC;
--            siod  : inout STD_LOGIC;
--            reset : out   STD_LOGIC;
--            pwdn  : out   STD_LOGIC;
--            xclk  : out   STD_LOGIC
--        );
--    end component;
    
    component Filter_ROM is
        port(
        -- Inputs 
            Clk       : in std_logic;                       -- System Clock
            i_Reset   : in std_logic;                     -- Reset to clear output
            i_En      : in std_logic;                     -- Read Enable
            i_Adr     : in std_logic_vector(3 downto 0);  -- Read Address
        -- Outputs
            o_Coeff   : out KERNEL; -- Kernel coefficients output
            o_SF      : out std_logic_vector(3 downto 0)  -- Scaling factor output
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
            i_HRef          :   in  std_logic;
            i_Pixel_Data    :   in  std_logic_vector(7 downto 0);
            i_VSync         :   in  std_logic;
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
            i_Enable            :   in  std_logic;
            i_Reset             :   in  std_logic;
            i_Kernel            :   in  kernel;                         -- Input data
            i_Scaling_Factor    :   in  std_logic_vector(3 downto 0);
            i_Data              :   in  std_logic_vector(BPP-1 downto 0);
            i_Median_En         :   in  std_logic;
            -- OUTPUTS
            o_Data              :   out std_logic_vector(BPP-1 downto 0);
            o_Write_Adr         :   out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
            o_Write_En          :   out std_logic
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
            o_Adr       : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
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
    
    -----------------------------------------------------------------------------------------
                        ----    Clocking signals    ----
    -----------------------------------------------------------------------------------------
    signal Clk_25   :   std_logic := '0';       -- 25MHz clock, used to drive VGA display
    signal Clk_50   :   std_logic := '0';       -- 50MHz clock, used to drive camera
    -----------------------------------------------------------------------------------------
                            ---- VGA Interfacing signals ----
    -----------------------------------------------------------------------------------------                            
    signal VGA_Adr  : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
    signal VGA_Di   : std_logic_vector(BPP-1 downto 0);
    -----------------------------------------------------------------------------------------
                            ---- FILTER COEFFICIENT ROM signals ----
    -----------------------------------------------------------------------------------------
    signal ROM_En        : std_logic := '0';
    signal ROM_Adr       : std_logic_vector(3 downto 0) := (others => '0');  
    signal ROM_SF        : std_logic_vector(3 downto 0) := (others => '0'); -- Scaling factor to apply to 2D_FIR
    signal ROM_Coeff     : KERNEL := (others => (others => "0"));           -- 3x3 kernel to apply to 2D FIR, read from filter ROM
    -----------------------------------------------------------------------------------------
                              ---- (FBI) Input Frame Buffer's Signals ----
    -----------------------------------------------------------------------------------------
    -- Port A --
    signal FBI_A_We      : std_logic := '0';
    signal FBI_A_Adr     : std_logic_vector(FB_ADR_BUS_WIDTH -1 downto 0) := (others => '0');
    signal FBI_A_Di      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal FBI_A_Do      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    -- Port B --
    signal FBI_B_We      : std_logic := '0';
    signal FBI_B_Adr     : std_logic_vector(FB_ADR_BUS_WIDTH -1 downto 0) := (others => '0');
    signal FBI_B_Di      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal FBI_B_Do      : std_logic_vector(BPP-1 downto 0) := (others => '0');    
    -----------------------------------------------------------------------------------------
                        ---- (FBO) FRAME BUFFER OUTPUT's control signal ----
    -----------------------------------------------------------------------------------------
    -- Port A --
    signal FBO_A_We      : std_logic := '0';
    signal FBO_A_Adr     : std_logic_vector(FB_ADR_BUS_WIDTH -1 downto 0) := (others => '0');
    signal FBO_A_Di      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal FBO_A_Do      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    -- Port B--
    signal FBO_B_We      : std_logic := '0';
    signal FBO_B_Adr     : std_logic_vector(FB_ADR_BUS_WIDTH -1 downto 0) := (others => '0');
    signal FBO_B_Di      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal FBO_B_Do      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    -----------------------------------------------------------------------------------------
                        ---- Contrast filter signals ----
    -----------------------------------------------------------------------------------------
    signal Contrast_En      : std_logic := '0';             -- Set active filter to Contrast Stretching when high
    signal Contrast_FBO_A_Di  : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal Contrast_FBO_A_Adr : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal Contrast_FBO_A_We  : std_logic := '0';
    signal Contrast_FBI_B_Adr : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    -----------------------------------------------------------------------------------------
                        ---- Threshold Filter signals ----
    -----------------------------------------------------------------------------------------
    signal Threshold_En     : std_logic := '0';             -- Set active filter to thresholding function
    signal Threshold_FBO_A_Adr : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal Threshold_FBO_A_Di  : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal Threshold_FBO_A_We  : std_logic := '0';
    signal Threshold_Value     : std_logic_vector(7 downto 0) := (others => '0');
    -----------------------------------------------------------------------------------------
                            ---- 2D FIR signals ----
    -----------------------------------------------------------------------------------------
    signal FIR_FBO_A_Di  : std_logic_vector(BPP-1 downto 0) := (others => '0');
    signal FIR_FBO_A_Adr : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    signal FIR_FBO_A_We  : std_logic := '0';
    signal Median_En     : std_logic := '0';             -- Set active filter to Median Filter (when 1)
    signal FIR_Enable       : std_logic := '0';             -- Enable signal to start the FIR filter
    -----------------------------------------------------------------------------------------
                            ---- Camera control signals ----
            -- Pixel data can come from the camera module OR from UART --
    -----------------------------------------------------------------------------------------
    signal CAM_We   : std_logic := '0';                                                     -- Camera frame buffer write enable
    signal CAM_Adr  : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');     -- Camera frame buffer write address            
    signal CAM_Do   : std_logic_vector(BPP-1 downto 0) := (others => '0');                  -- Camera pixel data
    -----------------------------------------------------------------------------------------
                            ---- UART control signals ----
            -- Pixel data can come from the camera module OR from UART --
    -----------------------------------------------------------------------------------------
    signal UART_Write_Adr   : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');    -- FB address to write received data to
    signal UART_Read_Adr    : std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');    -- FB address to read transmission data from
    signal UART_Di          : std_logic_vector(BPP-1 downto 0) := (others => '0');                 -- UART <= FB connection
    signal UART_Do          : std_logic_vector(BPP-1 downto 0) := (others => '0');                 -- UART => FB connection
    signal UART_Send        : std_logic := '0';        -- Pulses high to start UART byte transmission
    signal UART_We          : std_logic := '0';      -- FBI write enable
    signal Input_Mode       : std_logic := '0';      -- Set by UART command, [0: capture from camera]    [1 : use input from uart data]
    signal Output_Mode      : std_logic := '0';      -- Set by UART command, [0: output to VGA display]  [1 : send image over UART]
    
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
            Clk     => Clk_100,
            i_Reset => RESET,
            i_En    => ROM_En,
            i_Adr   => ROM_Adr,
        -- Outputs  => 
            o_Coeff => ROM_Coeff,
            o_SF    => ROM_SF
        );
       
    Filter_2D: FIR_2D
        port map (
            -- INPUTS       
            Clk                 => Clk_100, 
            i_Reset             => Reset,
            i_Enable            => FIR_Enable,
            i_Kernel            => ROM_Coeff,
            i_Scaling_Factor    => ROM_SF,
            i_Data              => FBI_B_Do,
            i_Median_En         => Median_En,
            -- OUTPUTS      
            o_Data              => FIR_FBO_A_Di,
            o_Write_En          => FIR_FBO_A_We,
            o_Write_Adr         => FIR_FBO_A_Adr
        );
        
    Contrast: Contrast_Filter
        port map (
            -- Inputs   
            Clk         => Clk_100,
            i_Enable    => Contrast_En,
            i_Data      => FBI_B_Do,
            -- Outputs  
            o_Data      => Contrast_FBO_A_Di,
            o_Write_Adr => Contrast_FBO_A_Adr,
            o_Write_En  => Contrast_FBO_A_We,
            o_Read_Adr  => Contrast_FBI_B_Adr
        );
        
    Threshold: Threshold_Filter
        port map (
            Clk         => Clk_100,
            i_Enable    => Threshold_En,
            i_Data      => FBI_B_Do,
            i_Threshold => Threshold_Value,
            o_Read_Adr  => FBI_B_Adr,
            o_Write_Adr => Threshold_FBO_A_Adr,
            o_Write_En  => Threshold_FBO_A_We,
            o_Data      => Threshold_FBO_A_Di
        );
       
    Camera_Capture: OV7670_Capture
        port map (
            -- Inputs
            i_Pixel_Clk     => OV7670_PCLK,
            i_HRef          => OV7670_HREF,
            i_Pixel_Data    => OV7670_DATA,
            i_VSync         => OV7670_VSYNC,
            -- Outputs
            o_We            => CAM_We,       
            o_Adr           => CAM_Adr,        
            o_Do            => CAM_Do
        );
    
    -- Frame buffer for input image (FBI) : holds the unprocessed image
    Frame_Buffer_IN : RAM_FB
        port map (         
           -- CLOCK 
           Clk     => Clk_100,
           -- PORT A
           A_Adr   => FBI_A_Adr,
           A_Di    => FBI_A_Di,    
           A_We    => FBI_A_We,                     -- Port A Enable
           A_Do    => FBI_A_Do,
       -- PORT B
           B_Adr   => FBI_B_Adr,
           B_Di    => FBI_B_Di,
           B_We    => FBI_B_We,
           B_Do    => FBI_B_Do
        );
        
    Frame_Buffer_OUT: RAM_FB
        port map (
           -- CLOCK 
            Clk     => Clk_100,
            -- PORT A
            A_Adr   => FBO_A_Adr,
            A_Di    => FBO_A_Di,    
            A_We    => FBO_A_We,                     -- Port A Enable
            A_Do    => FBO_A_Do,
        -- PORT B        
            B_Adr   => FBO_B_Adr,
            B_Di    => FBO_B_Di,
            B_We    => FBO_B_We,
            B_Do    => FBO_B_Do
        );
         

    -------------------------------------------------
    -----  Filters => Frame Buffer connections  -----
    -------------------------------------------------
    Filter_Controller: process(Clk_100)
    begin
        if (rising_edge(Clk_100)) then
            --------------------------------------
            --- Filter Output -> Frame Buffer  ---
            --------------------------------------
            if (Contrast_En = '1') then
                FBO_A_Di    <= Contrast_FBO_A_Di;
                FBO_A_Adr   <= Contrast_FBO_A_Adr;
                FBO_A_We    <= Contrast_FBO_A_We;
            elsif (Threshold_En = '1') then
                FBO_A_Di    <= Threshold_FBO_A_Di;
                FBO_A_Adr   <= Threshold_FBO_A_Adr;
                FBO_A_We    <= Threshold_FBO_A_We;
            else
                FBO_A_Di    <= FIR_FBO_A_Di; 
                FBO_A_Adr   <= FIR_FBO_A_Adr;
                FBO_A_We    <= FIR_FBO_A_We;
            end if;
            
            --------------------------------------
            ------  Data Input Controller   ------
            --------------------------------------
            if (Input_Mode = '0') then
                FBI_A_Adr   <= CAM_Adr;
                FBI_A_Di    <= CAM_Do;
                FBI_A_We    <= CAM_We;
            else
                FBI_A_Adr   <= UART_Write_Adr;
                FBI_A_Di    <= UART_Do;
                FBI_A_We    <= UART_We;
            end if;
            
            --------------------------------------
            ------  Data Output Controller  ------
            --------------------------------------
            if (Output_Mode = '0') then
                FBO_B_Adr   <= VGA_Adr;
                VGA_Di      <= FBO_B_Do;
            else
                FBO_B_Adr   <= UART_Read_Adr;
                UART_Di     <= FBO_B_Do;
            end if;
        end if; -- end clock edge check
    end process;          
  
    UART: UART_Controller
        port map (
            -- Inputs
            Clk             => Clk_100,
            i_Reset         => RESET,
            i_Send          => UART_Send,
            i_RX            => UART_RX,
            i_Di            => UART_Di,
            -- Outputs      
            o_Input_Mode    => Input_Mode,
            o_Output_Mode   => Output_Mode,
            o_Write_Adr     => UART_Write_Adr,
            o_Read_Adr      => UART_Read_Adr,
            o_Coef_En       => ROM_En,
            o_Coef_Adr      => ROM_Adr,
            o_Write_En      => UART_We,
            o_Do            => UART_Do,
            o_Contrast_En   => Contrast_En,
            o_Threshold_En  => Threshold_En,
            o_Median_En     => Median_En,
            o_Threshold     => Threshold_Value,        
            
            o_TX            => UART_TX 
        );
    
    -- VGA Controller
    VGA_DISPLAY: VGA_Controller
        port map(
            -- Input
            Clk             => Clk_25, 
            i_Pixel_Data    => VGA_Di,
            -- Output
            o_Adr           => VGA_Adr,
            o_HSync         => VGA_HSYNC,
            o_VSync         => VGA_VSYNC,
            o_RED           => VGA_RED,
            o_BLUE          => VGA_BLUE,
            o_GREEN         => VGA_GREEN
        );    
    
end Behavioral;