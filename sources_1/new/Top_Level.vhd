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
        TX_SWITCH    :  in  std_logic;
        UART_RX      :  in  std_logic;
        -- Output
        OV7670_SCL   :  out std_logic;
        OV7670_SDA   :  out std_logic;
        OV7670_XCLK  :  out std_logic;
        OV7670_RESET :  out std_logic;
        OV7670_PWDN  :  out std_logic;
        UART_TX      :  out std_logic;
        VGA_RED      :  out std_logic_vector(3 downto 0);
        VGA_GREEN    :  out std_logic_vector(3 downto 0);
        VGA_BLUE     :  out std_logic_vector(3 downto 0);
        VGA_HSYNC    :  out std_logic;
        VGA_VSYNC    :  out std_logic;
        LED          :  out std_logic_vector(1 downto 0)
    );
end Top_Level;

architecture Behavioral of Top_Level is
    
    component UART_Receiver is
        generic (
            BAUD_RATE : natural := 115_200
        );
        port (
            Clk         : in std_logic;                         -- System clock
            i_RX        : in std_logic;                         -- Serial input port
            o_RX_Finish : out std_logic;                        -- Signal driven high when finished recieving data
            o_RX_Byte   : out std_logic_vector(7 downto 0)      -- Byte output
        );
    end component;
    
    component UART_Controller is
        port (
            -- Inputs
            Clk             : in std_logic;                         -- System clock
            i_Reset         : in std_logic;                         -- Global reset input
            i_Send          : in std_logic;                         -- External trigger to start transmitting
            i_TX_Active     : in std_logic;                         -- High while transmitting
            i_TX_Finish     : in std_logic;                         -- High when TX byte has been sent
            i_RX_Finish     : in std_logic;                         -- High when RX byte is received
            i_RX_Byte       : in std_logic_vector(7 downto 0);      -- Byte received
            i_Pixel_Data    : in std_logic_vector(7 downto 0);      -- Pixel value to be transmitted 
            -- Outputs
            o_Pixel_Data    : out std_logic_vector(7 downto 0);     -- Byte from UART RX
            o_Pixel_Adr     : out std_logic_vector(LB_ADR_BUS_WIDTH - 1 downto 0); -- Address of pixel value in frame buffer
            o_Write_En      : out std_logic;                        -- Enable the frame buffer to write the data value
            o_Read_En       : out std_logic;                        -- Enable the read port on the frame buffer
            o_TX_Ready      : out std_logic;                        -- Pulse high to send TX_Byte
            o_TX_Byte       : out std_logic_vector(7 downto 0)      -- Data byte to be transmitted  
        );
    end component;
    
    
    component UART_Transmitter is
        generic (
            BAUD_RATE : natural := 115_200
        );
        port (
            Clk         : in std_logic;                     -- System clock input
            i_TX_Ready  : in std_logic;                     -- High when data has been loaded to TX_Byte
            i_TX_Byte   : in std_logic_vector(7 downto 0);  -- Byte to be transmitted serially
            o_TX_Active : out std_logic;                    -- Active infers tri-state buffer, as communications only use 1 wire
            o_TX_Serial : out std_logic;                    -- Serial data output port
            o_TX_Finish : out std_logic                     -- Signal that byte has been transmitted
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
    
    -- BRAM components
    component RAM_DP is
        generic (
            RAM_WIDTH : natural;    -- Number of bits in RAM word
            RAM_DEPTH : natural     -- Number of unique RAM addresses
        );
        port(
        -- Inputs 
            Reset   : in std_logic;                     -- Reset to clear output
            Clk     : in std_logic;                     -- RAM write port clock
        -- Port A (Write)
            En_a    : in std_logic;                     -- Port A Enable
            Adr_a   : in std_logic_vector(integer(ceil(log2(real(RAM_DEPTH))))-1 downto 0); -- Port A (Write) Address
            Di      : in std_logic_vector(RAM_WIDTH -1 downto 0); -- Port A (Write) Data In
        -- Port B (Read)
            En_b    : in std_logic;                     -- Port B Enable
            Adr_b   : in std_logic_vector(integer(ceil(log2(real(RAM_DEPTH))))-1 downto 0); -- Port B (Read) Address
            Do      : out std_logic_vector(RAM_WIDTH -1 downto 0) -- Port B (Read) Data Out
        );
    end component;
    
    -- Camera interfacing
    component OV7670_Top is
        port (
            -- Inputs
            Clk_100         :   in  std_logic;                      -- System clock
            i_OV7670_PCLK   :   in  std_logic;
            RESET           :   in  std_logic;                      -- Reset button
            i_OV7670_HREF   :   in  std_logic;   
            i_OV7670_DATA   :   in  std_logic_vector(7 downto 0);
            i_OV7670_VSYNC  :   in  std_logic;
            i_PIXEL_ADR     :   in  std_logic_vector(LB_ADR_BUS_WIDTH -1 downto 0);
            -- Outputs
            o_OV7670_SCL    :   out std_logic;
            o_OV7670_SDA    :   out std_logic;
            o_PIXEL_DATA    :   out std_logic_vector(BPP-1 downto 0)
        );
    end component;
    
    -- VGA Controller
    component VGA_Controller is
        port (
            -- Inputs
            Clk          : in std_logic;
            i_Pixel_Data : in std_logic_vector(BPP-1 downto 0);
            -- Outputs
            o_HSync      : out std_logic;
            o_VSync      : out std_logic;
            o_RED        : out std_logic_vector(3 downto 0);
            o_BLUE       : out std_logic_vector(3 downto 0);
            o_GREEN      : out std_logic_vector(3 downto 0)
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
    
    signal Clk_25   :   std_logic := '0';       -- 25MHz clock, used to drive camera and VGA display
    
    -- Data captured by the camera is fed directly into the VGA display
    signal VGA_Fetch_Adr    : std_logic_vector(LB_ADR_BUS_WIDTH-1 downto 0);
    signal VGA_Fetch_Data   : std_logic_vector(BPP-1 downto 0);
    signal VGA_Fetch_Count  : unsigned(LB_ADR_BUS_WIDTH -1 downto 0) := to_unsigned(FRAME_WIDTH-1, LB_ADR_BUS_WIDTH);
    signal VGA_Clk_Div      : std_logic := '1';
    
    -- Reading filter parameters from block ram
    signal Read_Filter_En   : std_logic := '0';
    signal Read_Filter_Adr  : std_logic_vector(5 downto 0) := (others => '0');
    signal Read_Filter_Coef : std_logic_vector(7 downto 0) := (others => '0');
    
    -- UART Controller Signals
      -- [Input]
    signal UART_TX_Active   : std_logic := '0';
    signal UART_TX_Finish   : std_logic := '0';
    signal UART_RX_Finish   : std_logic := '0';
    signal UART_RX_Byte     : std_logic_vector(7 downto 0) := (others => '0');
      -- [Output]
    signal UART_TX_Ready    : std_logic := '0';
    signal UART_TX_Byte     : std_logic_vector(7 downto 0) := (others => '0');
    signal UART_Pixel_Out   : std_logic_vector(7 downto 0) := (others => '0');
    signal UART_Pixel_In    : std_logic_vector(7 downto 0) := (others => '0');
    signal UART_Pixel_Adr   : std_logic_vector(LB_ADR_BUS_WIDTH - 1 downto 0) := (others => '0');
    signal UART_WE          : std_logic := '0';
    signal UART_RE          : std_logic := '0';
    signal UART_Send        : std_logic := '0';

    -- Input Frame Buffer Signals
    signal Input_FB_Re      : std_logic := '0';
    signal Input_FB_Adr     : std_logic_vector(LB_ADR_BUS_WIDTH -1 downto 0) := (others => '0');
    signal Input_FB_Do      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    
begin
    
    OV7670_RESET <= not RESET;      -- Reset active low, normal mode high
    OV7670_PWDN  <= '0';            -- Power down device 
    OV7670_XCLK  <= Clk_25;
    
    LED(1) <= UART_Send;
    LED(0) <= UART_TX_Active;
    UART_Send <= TX_Switch;

    -- 25MHz Clock Gen
    Clock_Gen_25MHz: Signal_Generator
        generic map (
            Frequency   => 25_000_000
        )
        port map (
            i_Clk       => Clk_100,
            o_Signal    => Clk_25
        );
   
   Filter_Parameters: Filter_ROM
        port map (
        -- Inputs 
            Clk    => Clk_100, 
            Reset  => RESET,
         -- Port (Read)
            En     => Read_Filter_En,
            Adr    => Read_Filter_Adr,
            Do     => Read_Filter_Coef
        );
    
    Camera_Wrapper: OV7670_Top
        port map (
            -- Inputs     
            Clk_100         => Clk_100,
            i_OV7670_PCLK   => OV7670_PCLK,
            RESET           => Reset,
            i_OV7670_HREF   => OV7670_HREF,
            i_OV7670_DATA   => OV7670_DATA,
            i_OV7670_VSYNC  => OV7670_VSYNC,
            i_PIXEL_ADR     => VGA_Fetch_Adr,
            -- Outputs    
            o_OV7670_SCL    => OV7670_SCL,
            o_OV7670_SDA    => OV7670_SDA,
            o_PIXEL_DATA    => VGA_Fetch_Data
        );
        
    Input_Frame_Buffer: RAM_DP
        generic map (
            RAM_WIDTH => 8,              -- Number of bits in RAM word
            RAM_DEPTH => FRAME_PIXELS   -- Number of unique RAM addresses
        )
        port map (
        -- Inputs 
            Reset   => RESET,           -- Reset to clear output
            Clk     => Clk_100,         -- RAM clock
        -- Port A (Write)
            En_a    => UART_We,         -- Port A Enable
            Adr_a   => UART_Pixel_Adr,  -- Port A (Write) Address
            Di      => UART_Pixel_Out,  -- Port A (Write) Data In
        -- Port B (Read)
            En_b    => UART_Re,         -- Port B Enable
            Adr_b   => UART_Pixel_Adr,  -- Port B (Read) Address
            Do      => UART_Pixel_In    -- Port B (Read) Data Out
        );
        
--    Output_Frame_Buffer: RAM_DP
--        generic map (
--            RAM_WIDTH => 8,              -- Number of bits in RAM word
--            RAM_DEPTH => FRAME_PIXELS   -- Number of unique RAM addresses
--        )
--        port map (
--        -- Inputs 
--            Reset   => RESET,           -- Reset to clear output
--            Clk_a   => Clk_100,         -- RAM write port clock
--            Clk_b   => Clk_100,         -- RAM read port clock
--        -- Port A (Write)
--            En_a    => UART_We,         -- Port A Enable
--            Adr_a   => UART_Pixel_Adr,  -- Port A (Write) Address
--            Di      => UART_Pixel_Out,  -- Port A (Write) Data In
--        -- Port B (Read)
--            En_b    => Input_FB_Re,     -- Port B Enable
--            Adr_b   => Input_FB_Adr,     -- Port B (Read) Address
--            Do      => Input_FB_Do      -- Port B (Read) Data Out
--        );
        
    
    UART_OUT: UART_Transmitter
        generic  map(
            BAUD_RATE => 115_200
        )
        port map (
            Clk         => Clk_100,
            i_TX_Ready  => UART_TX_Ready,
            i_TX_Byte   => UART_TX_Byte,
            o_TX_Active => UART_TX_Active,
            o_TX_Serial => UART_TX,
            o_TX_Finish => UART_TX_Finish
        );
        
    UART_IN: UART_Receiver
        generic map (
            BAUD_RATE => 115_200
        )
        port map (
            Clk         => Clk_100,
            i_RX        => UART_RX,
            o_RX_Finish => UART_RX_Finish,
            o_RX_Byte   => UART_RX_Byte
        );
    
    UART_CTRL: UART_Controller
        port map (
            -- Inputs
            Clk             =>  Clk_100,        -- System clock
            i_Reset         =>  RESET,          -- Global reset input
            i_Send          =>  UART_Send,      -- External trigger to start transmitting
            i_TX_Active     =>  UART_TX_Active, -- High while transmitting
            i_TX_Finish     =>  UART_TX_Finish, -- High when TX byte has been sent
            i_RX_Finish     =>  UART_RX_Finish, -- High when RX byte is received
            i_RX_Byte       =>  UART_RX_Byte,   -- Byte received
            i_Pixel_Data    =>  UART_Pixel_In,  -- Pixel value to be transmitted 
            -- Outputs      => 
            o_Pixel_Data    =>  UART_Pixel_Out, -- Byte from UART RX
            o_Pixel_Adr     =>  UART_Pixel_Adr, -- Address of pixel value in frame buffer
            o_Write_En      =>  UART_We,        -- Enable the frame buffer to write the data value
            o_Read_En       =>  UART_Re,        -- Enable the read port on the frame buffer
            o_TX_Ready      =>  UART_TX_Ready,  -- Pulse high to send TX_Byte
            o_TX_Byte       =>  UART_TX_Byte    -- Data byte to be transmitted  
        );
    
    -- VGA Controller
    Display_Driver: VGA_Controller
        port map(
            -- Input
            Clk             => Clk_25, 
            i_Pixel_Data    => VGA_FETCH_DATA,
            -- Output
            o_HSync         => VGA_HSYNC,
            o_VSync         => VGA_VSYNC,
            o_RED           => VGA_RED,
            o_BLUE          => VGA_BLUE,
            o_GREEN         => VGA_GREEN
        );    
    
    
    FETCH_VGA_INPUT: process(CLK_25)
    begin
        if (rising_edge(CLK_25)) then
            -- 2 PCLK cycles per pixel write, as data is received as 2 bytes
            VGA_Clk_Div <= not VGA_Clk_Div;
        
            if (VGA_Clk_Div = '0') then 
                if (VGA_Fetch_Count = FRAME_WIDTH - 1) then
                    VGA_Fetch_Count <= (others => '0');
                else
                    VGA_Fetch_Count <= VGA_Fetch_Count + 1;
                end if;
                VGA_Fetch_Adr <= std_logic_vector(VGA_Fetch_Count);
            end if;
        end if;
    end process;
end Behavioral;
