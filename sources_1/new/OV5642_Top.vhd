library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity OV5642_Top is
    port (
        -- Inputs
        C100MHZ     :   in  std_logic;                      -- Basys 3 xtal freq
        RESET       :   in  std_logic;                      -- Reset button
        
        -- Outputs
        OV5642_SCL  :   out std_logic;
        OV5642_SDA  :   out std_logic;
        OV5642_XCLK :   out std_logic
    );
end OV5642_Top;

architecture Behavioral of OV5642_Top is
    
    component Clk_Manager is
        port ( 
            clk_in  : in  STD_LOGIC;
            reset   : in  STD_LOGIC;
            Clk_100 : out STD_LOGIC;
            Clk_75  : out STD_LOGIC;
            Clk_25  : out STD_LOGIC;
            locked  : out STD_LOGIC
        );
    end component;
    
    component OV5642_Controller is
        generic (
            System_Freq : natural;
            Bus_Freq    : natural
        );
        port (
            i_Clk   : in  std_logic;
            i_Reset : in  std_logic;
            SCL     : out std_logic;
            SDA     : out std_logic
        );
    end component;
    
    signal Clk_100, Clk_75, Clk_25 : std_logic := '0';
    
begin

    --OV5642_XCLK <= Clk_25; 

    DCM: Clk_Manager
        port map (
            clk_in  => C100MHZ,
            reset   => Reset,
            Clk_100 => Clk_100,
            Clk_75  => Clk_75,
            Clk_25  => Clk_25,
            locked  => open
        );
        
    OV5642_Control: OV5642_Controller
        generic map (
            System_Freq => 100_000_000,
            Bus_Freq    => 100_000   
        )
        port map (
            i_Clk       => Clk_100,
            i_Reset     => Reset,
            SCL         => OV5642_SCL,
            SDA         => OV5642_SDA
        );
    
end Behavioral;