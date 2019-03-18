library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package FILTER_TYPES is

--subtype pipeline is std_logic_vector(25 downto 0);
--type pipeline_array is array(1 downto 0) of pipeline;

--    subtype pixel_value is std_logic_vector(11 downto 0);
--    type tap_array is array (2 downto 0) of pixel_value;
    
    subtype coeff is signed(7 downto 0);
    type coeff_array is array (2 downto 0) of coeff;
    
    type kernel is array (2 downto 0) of coeff_array;        

end package;