library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity OV7670_Top is
    port (
        -- Inputs
        C100MHZ     :   in  std_logic;                      -- Basys 3 xtal freq
        RESET       :   in  std_logic;                      -- Reset button
        OV7670_HREF :   in  std_logic;   
        OV7670_DATA :   in  std_logic_vector(7 downto 0);
        -- Outputs
        OV7670_SCL   :   out std_logic;
        OV7670_SDA   :   out std_logic;
        OV7670_XCLK  :   out std_logic;
        RAM_PORT_EN  :   out std_logic;
        RAM_WRITE_EN :   out std_logic;
        RAM_ADR_A    :   out std_logic_vector(9 downto 0);
        RAM_DATA     :   out std_logic_vector(11 downto 0)
    );
end OV7670_Top;

architecture Behavioral of OV7670_Top is
    
    component OV7670_Controller is
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
    
    component OV7670_Capture is
        port (
            -- Inputs
            i_Pixel_Clk   :   in  std_logic;
            i_H_Ref       :   in  std_logic;
            i_Pixel_Data  :   in  std_logic_vector(7 downto 0);
            -- Outputs
            o_En_a        :   out std_logic;        
            o_We          :   out std_logic;        
            o_Adr_a       :   out std_logic_vector(9 downto 0);        
            o_Do          :   out std_logic_vector(11 downto 0)
        );
    end component;
        
    component Signal_Generator is
        generic (
            Frequency : natural
        );
        port (
            i_Clk    : in  std_logic;
            o_Signal : out std_logic
        );
    end component;
    
    signal Clk_100,  Clk_25 : std_logic := '0';
    signal Camera_HRef      : std_logic := '0';
    signal Camera_Data      : std_logic_vector(7 downto 0) := (others => '0');
    signal r_En_a           : std_logic; 
    signal r_We             : std_logic;
    signal r_Adr_a          : std_logic_vector(9 downto 0) := (others => '0');  
    signal r_Do             : std_logic_vector(11 downto 0) := (others => '0');

begin
    
    
    Clk_100     <= C100MHZ;
    OV7670_XCLK <= Clk_25;
    
    OV7670_Control: OV7670_Controller
        generic map (
            System_Freq => 100_000_000,
            Bus_Freq    => 100_000   
        )
        port map (
            i_Clk       => Clk_100,
            i_Reset     => Reset,
            SCL         => OV7670_SCL,
            SDA         => OV7670_SDA
        );
        
    Clock_Gen_25MHz: Signal_Generator
        generic map (
            Frequency   => 25_000_000
        )
        port map (
            i_Clk       => Clk_100,
            o_Signal    => Clk_25
        );
    
    Capture_Logic: OV7670_Capture
        port map (
            -- Inputs   
            i_Pixel_Clk  => Clk_25,
            i_H_Ref      => OV7670_HREF,
            i_Pixel_Data => OV7670_DATA,
            -- Outputs  
            o_En_a      => RAM_PORT_EN,
            o_We        => RAM_WRITE_EN, 
            o_Adr_a     => RAM_ADR_A,
            o_Do        => RAM_DATA
        );
        
end Behavioral;