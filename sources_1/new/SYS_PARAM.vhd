library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;

package SYS_PARAM is

-- Board specifics
    constant SYS_XTAL_FREQ : natural := 100_000_000; -- Board clock frequency in Hertz, 100MHz for Basys 3
    
-- Camera Parameters
    constant SCCB_SCL_FREQ   : natural := 100_000; -- Serial clock frequency (Hz) for camera communications bus
    constant CAMERA_WRITE_ID : std_logic_vector(7 downto 0) := x"42"; -- Camera's I2C write ID, can be found in datasheet - 0x42 for OV7670
    constant BPP  : natural := 8;  -- Number of bits per pixel
    
-- VGA Parameters -- 
    -- 640x480 @ 60Hz --
    constant FRAME_WIDTH  : natural := 320; -- Active region width (pixels)
    constant FRAME_HEIGHT : natural := 240; -- Active region height (pixels)
    constant FRAME_PIXELS : natural := FRAME_WIDTH * FRAME_HEIGHT;
    
    constant VGA_PXL_CLK_FREQ : natural := 25_000_000; -- Pixel clock frequency, VESA requirements recommend 25.175MHz
    
    constant H_FP   : natural := 16;    -- H front porch width (pixels)
    constant H_BP   : natural := 48;    -- H back porch width (pixels)
    constant H_SP   : natural := 96;    -- H sync pulse width (pixels)
    constant H_MAX  : natural := 800;   -- H total period (pixels)
    
    constant V_FP   : natural := 10;    -- V front porch width (lines)
    constant V_BP   : natural := 33;    -- V back porch width (lines)
    constant V_SP   : natural := 2;     -- V sync pulse width (lines)
    constant V_MAX  : natural := 525;   -- V total period (lines)
    
    constant H_POL : std_logic := '0';  -- Polarity of H Sync pulse (0 = -, 1 = +)
    constant V_POL : std_logic := '0';  -- Polarity of V sync pulse (0 = -, 1 = +)
       
    signal IMPL_FILTER_CNT : natural := 2;
   
-- Linebuffer RAM Parameters
    constant LB_ADR_BUS_WIDTH   : natural := integer(ceil(log2(real(FRAME_WIDTH - 1))));
    
end package;