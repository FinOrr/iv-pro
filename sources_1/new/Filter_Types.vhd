library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sys_param.all;

package FILTER_TYPES is

--subtype pipeline is std_logic_vector(25 downto 0);
--type pipeline_array is array(1 downto 0) of pipeline;

--    subtype pixel_value is std_logic_vector(11 downto 0);
--    type tap_array is array (2 downto 0) of pixel_value;
    CONSTANT KERNEL_WIDTH : natural := 3;
    CONSTANT COEFF_WIDTH  : natural := 8;
     
    subtype coeff is signed(7 downto 0);    -- MUST BE (COEFF_WIDTH-1 downto 0)
    type coeff_array is array (KERNEL_WIDTH-1 downto 0) of coeff;
    
    type kernel is array (KERNEL_WIDTH-1 downto 0) of coeff_array;        

    type Median_Array is array(15 downto 0) of unsigned(BPP-1 downto 0);
    
end package;
