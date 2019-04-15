----------------------------------------------------------------------------------
--          Horizontal Timing (per frame)
--  Display Component           Pixels     
--  Visible Area                1280         
--  Front Porch                  72
--  Sync Pulse                   80
--  Back Porch                  216
--  Whole Line                 1648
--  H-Sync pulse is positive                             
--   
--                               
--          Vertical Timing (per frame)
--  Frame Component             Pixels     
--  Visible Area                720
--  Front Porch                   3
--  Sync Pulse                    5
--  Back Porch                   22
--  Whole Frame                 750
--  V-Sync pulse is positive
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VGA_720 is
    port(
    -- Inputs
        i_Clk       : in    std_logic;
        i_Pixel_Clk : in    std_logic;
        i_Reset     : in    std_logic;
        i_Red       : in    std_logic_vector(3 downto 0);
        i_Green     : in    std_logic_vector(3 downto 0);
        i_Blue      : in    std_logic_vector(3 downto 0);
    -- Outputs
        o_HSync    : out   std_logic;
        o_VSync    : out   std_logic;
        o_VGA_Red   : out   std_logic_vector(3 downto 0);
        o_VGA_Green : out   std_logic_vector(3 downto 0);
        o_VGA_Blue  : out   std_logic_vector(3 downto 0)
    );
end VGA_720;

architecture Behavioral of VGA_720 is
    
    -- Register definitions
    signal r_Pixel_Clk    : std_logic;
    signal r_HCounter    : std_logic_vector(10 downto 0) := (others => '0');    -- log2(1648)-1
    signal r_VCounter    : std_logic_vector(9 downto 0) := (others => '0');     -- log2(750) - 1
    signal r_Clk_Divider  : integer range 0 to 2 := 0;

begin

    -- Feed through colour components
    o_VGA_Red   <= i_Red;
    o_VGA_Green <= i_Green;
    o_VGA_Blue  <= i_Blue;
	
    Clocking : process(r_Pixel_Clk)
    begin
        if (rising_edge(r_Pixel_Clk)) then
            if (i_Reset = '1') then
                r_VCounter <= (others => '0');
                r_HCounter <= (others => '0');
            else
                if (r_Clk_Divider < 2) then
                    r_Clk_Divider <= r_Clk_Divider + 1;
                else
                    r_Clk_Divider <= 0;
                    if (r_HCounter = 1647) then              -- if we've reached the end of a line
                        r_HCounter <= (others => '0');       -- reset the horizontal counter
                        if (r_VCounter = 749) then           -- if the we've reached the last line in the frame
                            r_VCounter <= (others => '0');   -- reset the vertical counter
                        else                            
                            r_VCounter <= r_VCounter + 1;     -- if not end of frame, move to the next line
                        end if;
                    else
                        r_HCounter <= r_HCounter + 1;         -- if not end of line, move to the next pixel in the row
                    end if;
                end if;
            end if;
        end if;
    end process;
        
    
    Syncing : process(r_HCounter, r_VCounter)
    begin
        o_HSync      <= '1';
        o_VSync      <= '0';
        
        -- h sync generator    
        if (r_HCounter > 1351) and (r_HCounter < 1432) then -- (Visible area + front porch - 1) and (visible area + front porch + sync pulse)
            o_HSync <= '0';
        end if;
        
        -- v sync generator
        if (r_VCounter > 720) and (r_VCounter < 728) then
            o_VSync <= '1';
        end if;
        
    end process;
    
end Behavioral;