library WORK;
use WORK.FILTER_TYPES.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity FIR_1D is
    port (
        -- Inputs
        Clk     :   in  std_logic;
        i_Reset :   in  std_logic;
        i_Data  :   in  std_logic_vector(7 downto 0);
        i_Coeff :   in  coeff_array;
        -- Outputs
        o_Data  :   out std_logic_vector(17 downto 0)    -- Input(n bits) * filter(8 bits) + pipelines (2 bits) = n + 10 bit output bus
    );
end FIR_1D;

architecture Behavioral of FIR_1D is

    -- As filter coefficients are signed, we need to convert SLV input to signed
    signal Data_Signed : signed(7 downto 0);
    
    signal Pipeline_0 : signed(15 downto 0) := (others => '0');
    signal Pipeline_1 : signed(16 downto 0) := (others => '0');

    signal r_Coeff  : coeff_array;
    signal r_Output : signed(17 downto 0) := (others => '0');
    
begin
    r_Coeff <= i_Coeff;
    Data_Signed <= signed(i_Data);
    o_Data <= std_logic_vector(r_Output); 
    
    Filter: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (i_Reset = '1') then
                Pipeline_0 <= (others => '0');
                Pipeline_1 <= (others => '0');
            else
                --Pipeline(0) <= to_signed(i_Data_Signed * Filter_Coeff(0)); 
                Pipeline_0 <= resize((Data_Signed * r_Coeff(2)), 16);
                Pipeline_1 <= resize((Data_Signed * r_Coeff(1)) + Pipeline_0, 17);
                r_Output   <= resize((Data_Signed * r_Coeff(0)) + Pipeline_1, 18);
            end if;
        end if;
    end process;

end Behavioral;