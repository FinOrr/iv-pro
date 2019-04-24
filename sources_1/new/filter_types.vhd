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
     
    subtype coeff is signed(7 downto 0);    -- MUST BE (COEFF_WIDTH-1 downto 0)
    type coeff_array is array (KERNEL_WIDTH-1 downto 0) of coeff;           -- 
    
    type kernel is array (KERNEL_WIDTH-1 downto 0) of coeff_array;          -- Filter kernel for 2D neighborhood operations

    type Median_Array is array(15 downto 0) of unsigned(BPP-1 downto 0);    -- Weighted median array for median filter function
    
    type SF_ROM_ARRAY is array (4 downto 0) of std_logic_vector(3 downto 0);    -- Scaling factor array of neighborhood operations

    type COEFF_ROM_ARRAY is array (4 downto 0) of KERNEL;                    -- Coefficient array of kernel coefficients

end package;