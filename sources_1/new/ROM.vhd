---------------------------------------------------------------------------------
library WORK;
use WORK.SYS_PARAM.ALL;
use WORK.FILTER_TYPES.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;


entity FILTER_ROM is
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
end FILTER_ROM;
 
architecture Behavioral of FILTER_ROM is

    -- Coefficient ROM
    signal COEFF_ROM : COEFF_ROM_ARRAY:= (
  
        -- Sharpen filter
        ((x"01", x"01", x"01"), (x"01", x"09", x"01"), (x"01", x"01", x"01")),
        -- Sobel X Horizontal Mask
        ((x"FF", x"00", x"01"), (x"FE", x"00", x"02"), (x"FF", x"00", x"01")),         
        -- Sobel Y Vertical Mask
        ((x"01", x"02", x"01"), (x"00", x"00", x"00"), (x"FF", x"FE", x"FF")),   
        -- Gaussian blur
        ((x"01", x"02", x"01"), (x"02", x"04", x"02"), (x"01", x"02", x"01")), 
        -- Blur (mean)
        ((x"01", x"01", x"01"), (x"01", x"01", x"01"), (x"01", x"01", x"01"))  
    );
    
    -- Scaling Factor ROM
    signal SF_ROM : SF_ROM_ARRAY := (
        0 => (x"3"),    -- Sharpen filter: * 1/8
        1 => (x"0"),    -- Sobel X = *1
        2 => (x"0"),    -- Sobel Y = *1
        3 => (x"4"),    -- Gaussian blur = *1/16
        4 => (x"3")     -- Mean blur = *1/8
    );
    
begin
    
    Read_Control: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (i_Reset = '1') then
                o_Coeff <= (others => (others => "0"));                     -- On reset clear kernel output
                o_SF    <= (others => '0');                                 -- On reset clear scaling factor output
            else
                if (i_En = '1') then                                        -- Check Port enabled
                    o_Coeff <= COEFF_ROM(to_integer(unsigned(i_Adr)));      -- Output the coefficients data from (index = Adr)
                    o_SF    <= SF_ROM(to_integer(unsigned(i_Adr)));         -- Output the scaling factor for the appropriate filter
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;