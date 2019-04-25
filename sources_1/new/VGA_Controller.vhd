library WORK;
use WORK.SYS_PARAM.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_Controller is
    Port (
        -- Inputs
        Clk          : in std_logic;
        i_Pixel_Data : in std_logic_vector(BPP-1 downto 0);
        -- Outputs
        o_Adr        : out std_logic_vector(FB_ADR_BUS_WIDTH-1 downto 0);
        o_HSync      : out std_logic;
        o_VSync      : out std_logic;
        o_Red        : out std_logic_vector(3 downto 0);
        o_Blue       : out std_logic_vector(3 downto 0);
        o_Green      : out std_logic_vector(3 downto 0)
    );
end VGA_Controller;

architecture Behavioral of VGA_Controller is
    
    -- The active signal is used to signal the active region of the screen (when not blank)
    signal ACTIVE  : std_logic_vector(3 downto 0) := x"0";
    
    -- Horizontal and Vertical counters
    signal h_cntr : unsigned(11 downto 0) := (others =>'0');
    signal v_cntr : unsigned(11 downto 0) := (others =>'0');
    
    -- Horizontal and Vertical Sync
    signal HSync : std_logic := not(H_POL);
    signal VSync : std_logic := not(V_POL);
    
    --VGA RGB signals, enabled with 'active' signal when inside active region
    signal VGA_Red_Ctrl   : std_logic_vector(3 downto 0);
    signal VGA_Green_Ctrl : std_logic_vector(3 downto 0);
    signal VGA_Blue_Ctrl  : std_logic_vector(3 downto 0);
    
    -- Registers to hold input values
    signal VGA_Red    : std_logic_vector(3 downto 0);
    signal VGA_Green  : std_logic_vector(3 downto 0);
    signal VGA_Blue   : std_logic_vector(3 downto 0);

    -- Frame Buffer register address
    signal Adr : unsigned(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');
    
begin
    
    -- Connect IO
    o_HSync <= HSync;
    o_VSync <= VSync;
    o_RED   <= VGA_Red_Ctrl;
    o_BLUE  <= VGA_Blue_Ctrl;
    o_GREEN <= VGA_Green_Ctrl;
    o_Adr   <= std_logic_vector(Adr);
     
    -- Active signal is high when drawing inside the active frame region
    ACTIVE <= "1111" when (h_cntr < FRAME_WIDTH) and (v_cntr < FRAME_HEIGHT) else "0000";
    
    ------------------------------------------------------------
    -- Turn Off VGA RBG Signals if outside of the active screen
    -- Make a 4-bit AND logic with the R, G and B signals
    ------------------------------------------------------------
    VGA_Red_Ctrl    <= ACTIVE and VGA_Red;
    VGA_Green_Ctrl  <= ACTIVE and VGA_Green;
    VGA_Blue_Ctrl   <= ACTIVE and VGA_Blue;
       
    -- Buffer inputs
    VGA_Red     <= i_Pixel_Data(7 downto 4);
    VGA_Green   <= i_Pixel_Data(7 downto 4);
    VGA_Blue    <= i_Pixel_Data(7 downto 4);
    
    Address_Fetch: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (Adr = FRAME_PIXELS-1) then
                Adr <= (others => '0');
            else
                Adr <= Adr + 1;
            end if;
        end if;
    end process;
    
    Horizontal_Counter: process (Clk)
    begin
        if (rising_edge(Clk)) then
            if (h_cntr = (H_MAX - 1)) then
                h_cntr <= (others =>'0');
            else
                h_cntr <= h_cntr + 1;
            end if;
        end if;
    end process;

    Vertical_Counter: process (Clk)
    begin
        if (rising_edge(Clk)) then
            if ((h_cntr = (H_MAX - 1)) and (v_cntr = (V_MAX - 1))) then
                v_cntr <= (others =>'0');
            elsif (h_cntr = (H_MAX - 1)) then
                v_cntr <= v_cntr + 1;
            end if;
        end if;
    end process;

     -- Horizontal sync
    HSync_Generator: process (Clk)
    begin
        if (rising_edge(Clk)) then
            if (h_cntr >= (H_FP + FRAME_WIDTH - 1)) and (h_cntr < (H_FP + FRAME_WIDTH + H_SP - 1)) then
                HSync <= H_POL;
            else
                HSync <= not(H_POL);
            end if;
        end if;
    end process;

    -- Vertical sync
    VSync_Generator: process (Clk)
    begin
        if (rising_edge(Clk)) then
            if (v_cntr >= (V_FP + FRAME_HEIGHT - 1)) and (v_cntr < (V_FP + FRAME_HEIGHT + V_SP - 1)) then
                VSync <= V_POL;
            else
                VSync <= not(V_POL);
            end if;
        end if;
    end process;
     
end Behavioral;