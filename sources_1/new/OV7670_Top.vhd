library WORK;
use WORK.SYS_PARAM.ALL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity OV7670_Top is
    port (
        -- Inputs
        Clk_100         :   in  std_logic;                      -- System clock
        Reset           :   in  std_logic;                      -- Reset button
        i_OV7670_PCLK   :   in  std_logic;                      -- System clock
        i_OV7670_HREF   :   in  std_logic;   
        i_OV7670_DATA   :   in  std_logic_vector(7 downto 0);
        i_PIXEL_ADR     :   in  std_logic_vector(RAM_ADR_BUS_WIDTH-1 downto 0);
        -- Outputs
        o_OV7670_SCL    :   out std_logic;
        o_OV7670_SDA    :   out std_logic;
        o_PIXEL_DATA    :   out std_logic_vector(BPP-1 downto 0)
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
            i_HRef        :   in  std_logic;
            i_Pixel_Data  :   in  std_logic_vector(7 downto 0);
            -- Outputs
            o_En_a        :   out std_logic;         
            o_Adr_a       :   out std_logic_vector(RAM_ADR_BUS_WIDTH-1 downto 0);        
            o_Do          :   out std_logic_vector(BPP-1 downto 0)
        );
    end component;
        
        
    component RAM_DP is
        port (
        -- Inputs
            Clk_a   : in std_logic;                     -- RAM driven by 1 clock
            Clk_b   : in std_logic;                     
            Reset   : in std_logic;                     -- Reset to clear output
        -- Port A (Write)
            En_a    : in std_logic;                     -- Port A Enable
            Adr_a   : in std_logic_vector(RAM_ADR_BUS_WIDTH-1 downto 0);  -- Port A (Write) Address
            Di      : in std_logic_vector(BPP-1 downto 0);  -- Port A (Write) Data In
        -- Port B (Read)
            En_b    : in std_logic;                     -- Port B Enable
            Adr_b   : in std_logic_vector(RAM_ADR_BUS_WIDTH-1 downto 0);  -- Port B (Read) Address
            Do      : out std_logic_vector(BPP-1 downto 0)  -- Port B (Read) Data Out
        );
    end component;
    
    signal RAM_PORT_A_EN : std_logic := '0';
    signal RAM_PORT_B_EN : std_logic := '1';
    signal RAM_ADR_A     : std_logic_vector(RAM_ADR_BUS_WIDTH - 1 downto 0) := (others => '0');
    signal RAM_DATA      : std_logic_vector(BPP-1 downto 0) := (others => '0');
    
begin
    
    -- 100KHz SCCB bus SCL
    OV7670_Control: OV7670_Controller
        generic map (
            System_Freq => SYS_XTAL_FREQ,
            Bus_Freq    => SCCB_SCL_FREQ
        )
        port map (
            i_Clk       => Clk_100,
            i_Reset     => Reset,
            SCL         => o_OV7670_SCL,
            SDA         => o_OV7670_SDA
        );
       
    
    Capture_Logic: OV7670_Capture
        port map (
            -- Inputs   
            i_Pixel_Clk  => i_OV7670_PCLK,
            i_HRef       => i_OV7670_HREF,
            i_Pixel_Data => i_OV7670_DATA,
            -- Outputs  
            o_En_a      => RAM_PORT_A_EN,
            o_Adr_a     => RAM_ADR_A,
            o_Do        => RAM_DATA
        );
        
    LineBuffer: RAM_DP
        port map (
        -- Inputs
            Clk_a   => i_OV7670_PCLK,
            Clk_b   => i_OV7670_PCLK,
            Reset   => Reset,
        -- Port A (Write Port)
            En_a    => RAM_PORT_A_EN,
            Adr_a   => RAM_ADR_A,
            Di      => RAM_DATA,
        -- Port B (Read Port)
            En_b    => RAM_PORT_B_EN,
            Adr_b   => i_Pixel_Adr,
            Do      => o_Pixel_Data
        );

end Behavioral;