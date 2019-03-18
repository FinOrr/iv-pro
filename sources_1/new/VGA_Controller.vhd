
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.std_logic_unsigned.all;
--use ieee.math_real.all;
use IEEE.NUMERIC_STD.ALL;

entity VGA_Controller is
    Port (
        -- Inputs
        Clk         : in std_logic;
        i_Red       : in std_logic_vector(3 downto 0);
        i_Green     : in std_logic_vector(3 downto 0);
        i_Blue      : in std_logic_vector(3 downto 0);
        -- Outputs
        o_HSync     : out std_logic;
        o_VSync     : out std_logic;
        o_RED       : out std_logic_vector(3 downto 0);
        o_BLUE      : out std_logic_vector(3 downto 0);
        o_GREEN     : out std_logic_vector(3 downto 0)
    );
end VGA_Controller;

architecture Behavioral of VGA_Controller is

    -- 640x480 @ 60Hz --
    constant FRAME_WIDTH  : natural := 640;
    constant FRAME_HEIGHT : natural := 480;
    
    constant H_FP     : natural := 16;    --H front porch width (pixels)
    constant H_SP   : natural := 96;      --H sync pulse width (pixels)
    constant H_MAX    : natural := 800;   --H total period (pixels)
    
    constant V_FP     : natural := 10;    --V front porch width (lines)
    constant V_SP   : natural := 2;       --V sync pulse width (lines)
    constant V_MAX    : natural := 525;   --V total period (lines)
    
    constant H_POL : std_logic := '0';
    constant V_POL : std_logic := '0';
    
    -- Pixel clock, in this case 108 MHz
    signal pixel_clk : std_logic;
    
    -- The active signal is used to signal the active region of the screen (when not blank)
    signal active  : std_logic_vector(3 downto 0) := x"0";
    
    -- Horizontal and Vertical counters
    signal h_cntr : unsigned(11 downto 0) := (others =>'0');
    signal v_cntr : unsigned(11 downto 0) := (others =>'0');
    
    -- Horizontal and Vertical Sync
    signal h_sync : std_logic := not(H_POL);
    signal v_sync : std_logic := not(V_POL);
    
    --The main VGA R, G and B signals, validated by active
    
    signal vga_red_ctrl   : std_logic_vector(3 downto 0);
    signal vga_green_ctrl : std_logic_vector(3 downto 0);
    signal vga_blue_ctrl  : std_logic_vector(3 downto 0);
    
    signal vga_red    : std_logic_vector(3 downto 0);
    signal vga_green  : std_logic_vector(3 downto 0);
    signal vga_blue   : std_logic_vector(3 downto 0);


begin

    pixel_clk <= clk;

    Horizontal_Counter: process (pixel_clk)
    begin
        if (rising_edge(pixel_clk)) then
            if (h_cntr = (H_MAX - 1)) then
                h_cntr <= (others =>'0');
            else
                h_cntr <= h_cntr + 1;
            end if;
        end if;
    end process;

    Vertical_Counter: process (pixel_clk)
    begin
        if (rising_edge(pixel_clk)) then
            if ((h_cntr = (H_MAX - 1)) and (v_cntr = (V_MAX - 1))) then
                v_cntr <= (others =>'0');
            elsif (h_cntr = (H_MAX - 1)) then
                v_cntr <= v_cntr + 1;
            end if;
        end if;
    end process;

     -- Horizontal sync
    HSync: process (pixel_clk)
    begin
        if (rising_edge(pixel_clk)) then
            if (h_cntr >= (H_FP + FRAME_WIDTH - 1)) and (h_cntr < (H_FP + FRAME_WIDTH + H_SP - 1)) then
                h_sync <= H_POL;
            else
                h_sync <= not(H_POL);
            end if;
        end if;
    end process;

    -- Vertical sync
    VSYNC: process (pixel_clk)
    begin
        if (rising_edge(pixel_clk)) then
            if (v_cntr >= (V_FP + FRAME_HEIGHT - 1)) and (v_cntr < (V_FP + FRAME_HEIGHT + V_SP - 1)) then
                v_sync <= V_POL;
            else
                v_sync <= not(V_POL);
            end if;
        end if;
    end process;
     
     
    -- active signal is high when drawing the active frame region
    active <= "1111" when h_cntr < FRAME_WIDTH and v_cntr < FRAME_HEIGHT else "0000";

    -- Buffer inputs
    vga_red <= i_Red;
    vga_green <= i_Green;
    vga_blue <= i_Blue;
    
    ------------------------------------------------------------
    -- Turn Off VGA RBG Signals if outside of the active screen
    -- Make a 4-bit AND logic with the R, G and B signals
    ------------------------------------------------------------
    vga_red_ctrl    <= active and vga_red;
    vga_green_ctrl  <= active and vga_green;
    vga_blue_ctrl   <= active and vga_blue;
    
    
     -- Assign outputs
    o_HSync <= h_sync;
    o_VSync <= v_sync;
    o_RED   <= vga_red_ctrl;
    o_BLUE  <= vga_blue_ctrl;
    o_GREEN <= vga_green_ctrl;

end Behavioral;