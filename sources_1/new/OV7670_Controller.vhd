-- Wrapper to connect the serial communication logic with the camera register addresses and values
library WORK;
use WORK.SYS_PARAM.ALL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity OV7670_Controller is
    generic(
        System_Freq : natural range 0 to 400_000_000 := SYS_XTAL_FREQ;  -- Global system clock frequency, 100MHz default
        Bus_Freq    : natural range 0 to 400_000     := SCCB_SCL_FREQ   -- SCL bus frequency, 100KHz default
    );
    port (
        -- Inputs
        i_Clk     : in std_logic;    
        i_Reset   : in std_logic;
        -- Outputs
        SCL       : out std_logic;
        SDA       : out std_logic
    );
end OV7670_Controller;

architecture Behavioral of OV7670_Controller is
    
    component OV7670_Init is
        port(
            -- Inputs
            i_Clk       : in  std_logic;
            i_Reset     : in  std_logic;
            i_Next      : in  std_logic;
            -- Outputs
            o_Data      : out  std_logic_vector(15 downto 0);
            o_Finished  : out  std_logic
        );
    end component;
    
    component SCCB_Master is
        port(
            -- Inputs
            i_Clk       : in    std_logic;
            i_Reset     : in    std_logic;
            i_Enable    : in    std_logic;
            i_Start     : in    std_logic;
            i_Device_ID : in    std_logic_vector(7 downto 0);
            i_Address   : in    std_logic_vector(7 downto 0);
            i_Data      : in    std_logic_vector(7 downto 0);
            -- Output
            o_Ready : out   std_logic;
            o_SDA   : out   std_logic;
            o_SCL   : out   std_logic
        );
    end component;
    
    -- Internal signal declaration
    signal r_Ready      : std_logic := '0';
    signal r_Next       : std_logic := '0';
    signal r_Reg_Data   : std_logic_vector(15 downto 0) := x"0000";
    signal r_Finished   : std_logic := '0';
    signal r_Reset      : std_logic := '0';
    signal r_Start_SCCB : std_logic := '0';
    signal r_Enable     : std_logic := '1';
    
    -- 100KHz SCCB Clock driver signals
    constant Max_CE_Count : integer := (System_Freq / Bus_Freq);
    signal   CE_Count  : integer range 0 to Max_CE_Count := 0;
    signal   SCCB_CLK  : std_logic := '0';
    
begin
    -- Buffer reset input to register
    r_Reset <= i_Reset;
    
    -- If all the register values have been sent, then disable the SCCB bus
    r_Enable        <= not r_Finished;
    
    SCCB_Bus_Master: SCCB_Master
        port map(
            -- Inputs
            i_Clk       => SCCB_Clk, 
            i_Enable    => r_Enable,
            i_Reset     => r_Reset,
            i_Start     => r_Ready,
            i_Device_ID => CAMERA_WRITE_ID,
            i_Address   => r_Reg_Data(15 downto 8),
            i_Data      => r_Reg_Data( 7 downto 0),
            -- Outputs 
            o_Ready     => r_Ready,
            o_SDA       => SDA,
            o_SCL       => SCL
        );

    OV7670_Init_Registers: OV7670_Init
        port map(
            -- Inputs
            i_Clk       => SCCB_Clk, 
            i_Reset     => r_Reset,
            i_Next      => r_Ready,
            -- Outputs 
            o_Data      => r_Reg_Data,
            o_Finished  => r_Finished
        );
    
    SCL_Divider: process(i_Clk)
    begin
        if(rising_edge(i_Clk)) then
            if (CE_Count = Max_CE_Count - 1) then
                SCCB_CLK <= not (SCCB_CLK);
                CE_Count <= 0;
            else
                CE_Count <= CE_Count + 1;
            end if;
        end if;
    end process;
    
end Behavioral;