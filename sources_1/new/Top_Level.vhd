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

entity Top_Level is
    port (
        -- Inputs
        Clk_100     :   in  std_logic;                      -- System clock
        RESET       :   in  std_logic;                      -- Reset button
        OV7670_PCLK :   in  std_logic;                      -- Camera PCLK
        OV7670_HREF :   in  std_logic;   
        OV7670_DATA :   in  std_logic_vector(7 downto 0);
        -- Outputs
        OV7670_SCL  :   out std_logic;
        OV7670_SDA  :   out std_logic;
        OV7670_XCLK :   out std_logic;
        OV7670_RESET:   out std_logic;
        OV7670_PWDN :   out std_logic;
        VGA_RED     :   out std_logic_vector(3 downto 0);
        VGA_GREEN   :   out std_logic_vector(3 downto 0);
        VGA_BLUE    :   out std_logic_vector(3 downto 0);
        VGA_HSYNC   :   out std_logic;
        VGA_VSYNC   :   out std_logic
    );
end Top_Level;


architecture Behavioral of Top_Level is

    -- Camera interfacing
    component OV7670_Top is
        port (
            -- Inputs
            Clk_100         :   in  std_logic;                      -- System clock
            i_OV7670_PCLK   :   in  std_logic;
            RESET           :   in  std_logic;                      -- Reset button
            i_OV7670_HREF   :   in  std_logic;   
            i_OV7670_DATA   :   in  std_logic_vector(7 downto 0);
            i_PIXEL_ADR     :   in  std_logic_vector(RAM_ADR_BUS_WIDTH-1 downto 0);
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
    signal VGA_Fetch_Adr    : std_logic_vector(9 downto 0) := (others => '0');
    signal VGA_Fetch_Cntr   : natural range 0 to 639 := 638;
    signal VGA_Fetch_Data   : std_logic_vector(11 downto 0) := (others => '0');
    
begin

    OV7670_RESET <= '1';    -- Reset active low, normal mode high
    OV7670_PWDN  <= '0';    -- Power on device 
    OV7670_XCLK  <= Clk_25;
    
    -- 25MHz Clock Gen
    Clock_Gen_25MHz: Signal_Generator
        generic map (
            Frequency   => 25_000_000
        )
        port map (
            i_Clk       => Clk_100,
            o_Signal    => Clk_25
        );
   
    
    Camera_Wrapper: OV7670_Top
        port map (
            -- Inputs     
            Clk_100         => Clk_100,
            i_OV7670_PCLK   => OV7670_PCLK,
            RESET           => Reset,
            i_OV7670_HREF   => OV7670_HREF,
            i_OV7670_DATA   => OV7670_DATA,
            i_PIXEL_ADR     => VGA_Fetch_Adr,
            -- Outputs    
            o_OV7670_SCL    => OV7670_SCL,
            o_OV7670_SDA    => OV7670_SDA,
            o_PIXEL_DATA    => VGA_Fetch_Data
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
    
    --VGA_Fetch_Adr <= std_logic_vector(to_unsigned(VGA_Fetch_Cntr, RAM_ADR_BUS_WIDTH-1));

    FETCH_VGA_INPUT: process(OV7670_PCLK)
    begin
        if (rising_edge(OV7670_PCLK)) then
            if (VGA_Fetch_Cntr = 639) then
                VGA_Fetch_Cntr <= 0;
            else
                VGA_Fetch_Cntr <= VGA_Fetch_Adr_Cntr + 1;
            end if;
            VGA_Fetch_Adr <= std_logic_vector(to_unsigned(VGA_Fetch_Cntr, 10));
        end if;
    end process;
end Behavioral;
