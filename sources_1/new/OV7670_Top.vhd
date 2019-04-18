library WORK;
use WORK.SYS_PARAM.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;

entity OV7670_Top is
    port (
        -- Inputs
        Clk_100         :   in  std_logic;                      -- System clock
        Reset           :   in  std_logic;                      -- Reset button
        i_OV7670_PCLK   :   in  std_logic;                      -- System clock
        i_OV7670_HREF   :   in  std_logic;   
        i_OV7670_DATA   :   in  std_logic_vector(7 downto 0);
        i_OV7670_VSYNC  :   in  std_logic;
        i_PIXEL_ADR     :   in  std_logic_vector(LB_ADR_BUS_WIDTH-1 downto 0);
        -- Outputs
        o_PIXEL_DATA    :   out std_logic_vector(BPP-1 downto 0)
    );
end OV7670_Top;

architecture Behavioral of OV7670_Top is
    
    component OV7670_Capture is
        port (
            -- Inputs
            i_Pixel_Clk     :   in  std_logic;
            i_HRef          :   in  std_logic;
            i_Pixel_Data    :   in  std_logic_vector(7 downto 0);
            i_VSync         :   in  std_logic;
            -- Outputs
            o_En_a          :   out std_logic;         
            o_Adr_a         :   out std_logic_vector(LB_ADR_BUS_WIDTH - 1 downto 0);        
            o_Do            :   out std_logic_vector(BPP-1 downto 0)
        );
    end component;
           
    signal RAM_PORT_A_EN : std_logic := '0';
    signal RAM_ADR_A     : std_logic_vector(LB_ADR_BUS_WIDTH - 1 downto 0) := (others => '0');
    signal RAM_DATA      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    
begin
      
    Capture_Logic: OV7670_Capture
        port map (
            -- Inputs   
            i_Pixel_Clk  => i_OV7670_PCLK,
            i_HRef       => i_OV7670_HREF,
            i_Pixel_Data => i_OV7670_DATA,
            i_VSync      => i_OV7670_VSYNC,
            -- Outputs  
            o_En_a      => RAM_PORT_A_EN,
            o_Adr_a     => RAM_ADR_A,
            o_Do        => RAM_DATA
        );
        
end Behavioral;