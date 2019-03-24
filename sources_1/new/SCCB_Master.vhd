----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.02.2019 10:55:48
-- Design Name: 
-- Module Name: SCCB_I2C - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--  
----------------------------------------------------------------------------------
library WORK;
use WORK.SYS_PARAM.ALL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SCCB_Master is
    port (
        -- Inputs
        i_Clk       : in    std_logic;
        i_Reset     : in    std_logic;
        i_Enable    : in    std_logic;
        i_Start     : in    std_logic;
        i_Device_ID : in    std_logic_vector(7 downto 0);
        i_Address   : in    std_logic_vector(7 downto 0);
        i_Data      : in    std_logic_vector(7 downto 0);
        -- Output
        o_Ready     : out   std_logic;
        o_SDA       : out   std_logic;
        o_SCL       : out   std_logic
    );
end SCCB_Master;

architecture Behavioral of SCCB_Master is

    type t_SCCB_State is (IDLE, START, SLAVE_ADR, DC1, REG_ADR, DC2, DATA, DC3, STOP);
    signal state: t_SCCB_State := IDLE;
    
    signal r_Device_ID  : std_logic_vector(7 downto 0) := x"00";
    signal r_Address    : std_logic_vector(7 downto 0) := x"00";
    signal r_Data       : std_logic_vector(7 downto 0) := x"00";
    
    signal Bit_Count : integer := 0;
    signal r_SCL     : std_logic := '1';
    signal r_SCL_En  : std_logic := '0';
    
--    constant Max_CE_Count : integer := (System_Freq / Bus_Freq);
--    signal CE_Count  : integer range 0 to Max_CE_Count := 0;
    signal SCCB_Clk  : std_logic := '0';
    
begin
    SCCB_Clk <= i_Clk;
    o_SCL <= r_SCL;
    r_SCL <= '1' when (r_SCL_En = '0') else (not (SCCB_Clk));
    o_Ready <= '1' when (i_Reset = '0' and state = IDLE) else ('0');
    
--    SCL_Divider: process(i_Clk)
--    begin
--        if (rising_edge(i_Clk)) then
--            if (CE_Count = ((Max_CE_Count - 1) / 2)) then
--                SCCB_CLK <= not (SCCB_CLK);
--                CE_Count <= 0;
--            else
--                CE_Count <= CE_Count + 1;
--            end if;
--        end if;
--    end process;
    
    Serial_Clocking: process(SCCB_CLK)
    begin
        if (falling_edge(SCCB_CLK)) then
            if (i_Enable = '1') then
                if (i_Reset ='1') then -- Reset true
                    r_SCL_En <= '0';
                else
                    if ((state = IDLE) or (state = START) or (state = STOP)) then
                        r_SCL_En <= '0';
                    else
                        r_SCL_En <= '1';
                    end if; -- state check
                end if; -- reset / enable check
            end if;
        end if; -- falling clock edge
    end process;
    
    
    State_Control: process(SCCB_Clk)
    begin
        if (rising_edge(SCCB_Clk)) then
            if (i_Enable = '1') then 
                if (i_Reset ='1') then -- Reset true
                    state <= IDLE;
                    o_SDA <= '1';
                    Bit_Count <= 0;
                else                -- Reset not set
                    case state is
                    
                        when IDLE =>   -- IDLE state,
                            o_SDA <= '1';
                            if (i_Start = '1') then
                                state <= START;
                                r_Device_ID <= i_Device_ID;     -- Buffer device ID
                                r_Address   <= i_Address;       -- Save the memory address to a local register 
                                r_Data      <= i_Data;          -- Save te data to be written to a local reg 'r_DATA'
                            else
                                state <= IDLE;
                            end if;
                            
                        when START =>    -- START condition 
                            o_SDA <= '0';
                            state <= SLAVE_ADR;
                            Bit_Count <= 7;
                            
                        when SLAVE_ADR =>   -- Send addresses MSB->LSB
                            o_SDA <= r_Device_ID(Bit_Count);
                            if (Bit_Count = 0) then                            
                                state <= DC1;
                            else
                                Bit_Count <= Bit_Count - 1;
                            end if;
                      
                        when DC1 =>
                            state <= REG_ADR; 
                            Bit_Count <= 7;
                            
                        when REG_ADR =>
                            o_SDA <= r_Address(Bit_Count);
                            if (Bit_Count = 0) then
                                state <= DC2;
                            else 
                                Bit_Count <= Bit_Count - 1;
                            end if;
                            
                        when DC2 =>
                            state <= DATA;
                            Bit_Count <= 7;
                            
                        when DATA =>
                            o_SDA <= r_Data(Bit_Count);
                            if (Bit_Count = 0) then
                                state <= DC3;
                            else
                                Bit_Count <= Bit_Count - 1;
                            end if;
                        
                        when DC3 =>
                            state <= STOP;
                            
                        when STOP =>
                            o_SDA <= '1';
                            state <= IDLE;
                       
                       when OTHERS =>
                            state <= IDLE;
                            
                    end case; -- check state case
                end if; -- check reset
            end if; -- check enable
        end if; -- check rising clock edge
    end process;
end Behavioral;
