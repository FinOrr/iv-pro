library WORK;
use WORK.SYS_PARAM.ALL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_Controller is
    port (
        -- Inputs
        Clk             : in std_logic;                         -- System clock
        i_Reset         : in std_logic;                         -- Global reset input
        i_TX_Active     : in std_logic;                         -- High while transmitting
        i_TX_Byte       : in std_logic_vector(7 downto 0);      -- Pixel value to be transmitted 
        i_TX_Finish     : in std_logic;                         -- High when TX byte has been sent
        i_TX_Ready      : in std_logic;                         -- External trigger to start transmitting
        i_RX_Byte       : in std_logic_vector(7 downto 0);      -- Byte received
        i_RX_Finish     : in std_logic;                         -- High when RX byte is received
        -- Outputs
        o_Adr           : out std_logic_vector(LB_ADR_BUS_WIDTH -1 downto 0); -- Address of pixel value in frame buffer
        o_Write_En      : out std_logic;                        -- Enable the frame buffer to write the data value
        o_Read_En       : out std_logic;                        -- Enable the read port on the frame buffer        
        o_TX_Ready      : out std_logic;                        -- Pulse high to send TX_Byte
        o_TX_Byte       : out std_logic_vector(7 downto 0);     -- Data byte to be transmitted  
        o_RX_Byte       : out std_logic_vector(7 downto 0);     -- Byte from UART RX
        o_Threshold     : out std_logic_vector(7 downto 0)      -- Threshold value for threshold function
    );
end UART_Controller;

architecture Behavioral of UART_CONTROLLER is

    signal Adr          : unsigned(LB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');     -- RAM address
    signal Byte_Count   : natural range 0 to FRAME_PIXELS := 0;                         -- Number of received bytes
    signal CMD_Sent     : std_logic := '0';                                             -- filter configured flag

begin 

    o_Adr <= std_logic_vector(to_unsigned(Byte_Count, LB_ADR_BUS_WIDTH));
    
    TX_Proc: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (i_TX_Active = '0') then
                if (i_RX_Finish = '1') then     -- If transmitter is sent
                    o_TX_Byte <= i_TX_Byte;     -- Load pixel value to transmitter
                    o_TX_Ready <= '1';          -- Stop transmitter
                else
                    o_TX_Ready <= '0';          -- Wait for byte to be sent before loading a new one
               end if; -- RX Finish check
            end if; -- TX Active check
        end if; -- clock edge check
    end process;
    
    RX_Proc: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (i_TX_Active = '0') then         -- If transmitter if inactive
                if (i_RX_Finish = '1') then     -- If byte has been received
                    if (CMD_Sent = '0') then    -- First command bytes haven't been received
                        case Byte_Count is
                            when 0 =>
                                -- Filter type   
                                Byte_Count <= Byte_Count + 1;
                            when 1 =>
                                -- Filter address (RAM)
                                Byte_Count <= Byte_Count + 1;
                            when 2 =>
                                o_Threshold <= i_RX_Byte;
                                CMD_Sent <= '1';
                                Byte_Count <= 0;
                            when others =>
                        end case;
                    else                            -- Receiving data byte
                        o_RX_Byte <= i_RX_Byte;     -- Load the received byte to frame buffer Data In bus
                        o_Write_En <= '1';          -- Enable writing to input frame buffer                       
                        if (Byte_Count = FRAME_PIXELS - 1) then     -- check if last pixel value in frame buffer
                            Byte_Count <= 0;                        -- reset byte counter
                            CMD_Sent <= '0';                        -- reset CMD_Sent flag
                        else                                        -- ELSE the frame buffer is not full yet
                            Byte_Count <= Byte_Count + 1;           -- Increment the byte counter
                        end if;                                     -- end of frame buffer check
                    end if;                                         -- end commands received check
                else
                    o_Write_En <= '0';      -- Disable write enable
                end if; -- Byte received check
            end if; -- transmitter active check
        end if; -- end clock edge check
    end process;
    
end Behavioral;
