---------------------------------------------------------------------------------
library WORK;
use WORK.SYS_PARAM.ALL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;


entity FILTER_ROM is
    port(
    -- Inputs 
        Clk     : in std_logic;                     -- System Clock
        Reset   : in std_logic;                     -- Reset to clear output
     -- Port (Read)
        En      : in std_logic;                     -- Port B Enable
        Adr     : in std_logic_vector(5 downto 0); -- Port B (Read) Address
        Do      : out std_logic_vector(7 downto 0) -- Port B (Read) Data Out
    );
end FILTER_ROM;
 
architecture Behavioral of FILTER_ROM is

    -- RAM Declaration
    type ROM_ARRAY is array (49 downto 0) of std_logic_vector(7 downto 0);
    signal ROM : ROM_ARRAY:= (
        -- [0->9] : Sharpen filter
        0 =>  x"03",   -- Scaling factor  (1/8)
        1 =>  x"01",   -- Coeff[0]       
        2 =>  x"01",   -- Coeff[1]       
        3 =>  x"01",   -- Coeff[2]       
        4 =>  x"01",   -- Coeff[3]       
        5 =>  x"09",   -- Coeff[4]       
        6 =>  x"01",   -- Coeff[5]       
        7 =>  x"01",   -- Coeff[6]       
        8 =>  x"01",   -- Coeff[7]       
        9 =>  x"01",   -- Coeff[8]       
                  
        -- [10->19] : Sobel X Horizontal Mask
        10 => x"00",   -- Scaling factor
        11 => x"FF",   -- Coeff[0]
        12 => x"00",   -- Coeff[1]
        13 => x"01",   -- Coeff[2]
        14 => x"FE",   -- Coeff[3]
        15 => x"00",   -- Coeff[4]
        16 => x"02",   -- Coeff[5]
        17 => x"FF",   -- Coeff[6]
        18 => x"00",   -- Coeff[7]
        19 => x"01",   -- Coeff[8]
                   
        -- [20 -> 29] : Sobel Y Vertical Mask
        20 => x"00",   -- Scaling factor
        21 => x"01",   -- Coeff[0]
        22 => x"02",   -- Coeff[1]
        23 => x"01",   -- Coeff[2]
        24 => x"00",   -- Coeff[3]
        25 => x"00",   -- Coeff[4]
        26 => x"00",   -- Coeff[5]
        27 => x"FF",   -- Coeff[6]
        28 => x"FE",   -- Coeff[7]
        29 => x"FF",   -- Coeff[8]     
                   
        -- [30 -> 39] : Gaussian blur
        30 => x"04",   -- Scaling factor (1/16)
        31 => x"01",   -- Coeff[0]
        32 => x"02",   -- Coeff[1]
        33 => x"01",   -- Coeff[2]
        34 => x"02",   -- Coeff[3]
        35 => x"04",   -- Coeff[4]
        36 => x"02",   -- Coeff[5]
        37 => x"01",   -- Coeff[6]
        38 => x"02",   -- Coeff[7]
        39 => x"01",   -- Coeff[8]
                   
        -- [40 -> 49] : Blur (mean)
        40 => x"03",   -- Scaling factor (1/8)
        41 => x"01",   -- Coeff[0]
        42 => x"01",   -- Coeff[1]
        43 => x"01",   -- Coeff[2]
        44 => x"01",   -- Coeff[3]
        45 => x"01",   -- Coeff[4]
        46 => x"01",   -- Coeff[5]
        47 => x"01",   -- Coeff[6]
        48 => x"01",   -- Coeff[7]
        49 => x"01"   -- Coeff[8]  
    );

begin
    
    Read_Control: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (En = '1') then                            -- Check Port enabled
                Do <= ROM(to_integer(unsigned(Adr)));     -- Output the data from (index = Adr)
            else
                Do <= (others => 'Z');                    -- If read port not enabled, clear the output
            end if;
        end if;
    end process;
    
end Behavioral;