-- Wrapper to connect the serial communication logic with the camera register addresses and values

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity OV5642_Controller is
    generic(
        System_Freq : natural range 0 to 400_000_000 := 100_000_000;   -- Global system clock frequency, 100MHz default
        Bus_Freq    : natural range 0 to 400_000     := 100_000        -- SCL bus frequency, 100KHz default
    );
    port (
        -- Inputs
        i_Clk     : in std_logic;    
        i_Reset   : in std_logic;
        -- Outputs
        SCL       : out std_logic;
        SDA       : out std_logic
    );
end OV5642_Controller;

architecture Behavioral of OV5642_Controller is

    component OV5642_Init is
        port(
            -- Inputs
            i_Clk       : in  std_logic;
            i_Reset     : in  std_logic;
            i_Next      : in  std_logic;
            -- Outputs
            o_Address   : out  std_logic_vector(15 downto 0);
            o_Data      : out  std_logic_vector(7 downto 0);
            o_Finished  : out  std_logic
        );
    end component;
    
    component SCCB_Master is
        port(
            -- Inputs
            i_Clk   : in    std_logic;
            i_Reset : in    std_logic;
            i_Start : in    std_logic;
            i_Address : in  std_logic_vector(15 downto 0);
            i_Data  : in    std_logic_vector(7 downto 0);
            -- Output
            o_Ready : out   std_logic;
            o_SDA   : out   std_logic;
            o_SCL   : out   std_logic
        );
    end component;
    
    -- Internal signal declaration
    signal r_Ready      : std_logic := '0';
    signal r_Next       : std_logic := '0';
    signal r_Address    : std_logic_vector(15 downto 0) := x"0000";
    signal r_Data       : std_logic_vector(7 downto 0) := x"00";
    signal r_Finished   : std_logic := '0';
    
    -- 100KHz SCCB Clock driver signals
    constant Max_CE_Count : integer := (System_Freq / Bus_Freq);
    signal CE_Count  : integer range 0 to Max_CE_Count := 0;
    signal SCCB_CLK : std_logic := '0';
    
begin
    
    SCCB_Ctrl: SCCB_Master
        port map(
            -- Inputs
            i_Clk       => i_Clk, 
            i_Reset     => i_Reset,
            i_Start     => r_Ready,
            i_Address   => r_Address,
            i_Data      => r_Data,
            -- Outputs 
            o_Ready     => r_Ready,
            o_SDA       => SDA,
            o_SCL       => SCL
        );

    Camera_Init: OV5642_Init
        port map(
            -- Inputs
            i_Clk       => i_Clk,  
            i_Reset     => i_Reset,
            i_Next      => r_Ready,
            -- Outputs 
            o_Address   => r_Address,
            o_Data      => r_Data,
            o_Finished  => r_Finished
        );
    
--    SCL_Divider: process(i_Clk)
--    begin
--        if (CE_Count = (Max_CE_Count - 1)) then
--            SCCB_CLK <= not (SCCB_CLK);
--            CE_Count <= 0;
--        else
--            CE_Count <= CE_Count + 1;
--        end if;
--    end process;
    
end Behavioral;