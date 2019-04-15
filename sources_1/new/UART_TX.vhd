library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library WORK;
use WORK.SYS_PARAM.ALL;

entity UART_Transmitter is
    generic (
        BAUD_RATE : natural := 115_200
    );
    port (
        Clk         : in std_logic;                     -- System clock input
        i_TX_Ready  : in std_logic;                     -- High when data has been loaded to TX_Byte
        i_TX_Byte   : in std_logic_vector(7 downto 0);  -- Byte to be transmitted serially
        o_TX_Active : out std_logic;                    -- Active infers tri-state buffer, as communications only use 1 wire
        o_TX_Serial : out std_logic;                    -- Serial data output port
        o_TX_Finish : out std_logic                     -- Signal that byte has been transmitted
    );
end UART_Transmitter;

architecture Behavioral of UART_Transmitter is
    
    -- CONSTANTS
    constant CLKS_PER_BIT : natural := (SYS_XTAL_FREQ / BAUD_RATE);         -- Number of system clock cycles per UART clock
    
    -- STATE MACHINE
    type t_UART_SM is (IDLE, START_BIT, DATA_BIT, STOP_BIT, RESET);         -- UART TX modelled as FSM
    signal STATE : t_UART_SM := IDLE;                                       -- Register 'STATE' holds the current state of the FSM
    
    -- COUNTERS
    signal Clk_Counter : natural range 0 to CLKS_PER_BIT - 1 := 0;          -- Counter will rollover once per UART clock cycle
    signal Bit_Index : natural range 0 to 7 := 0;                           -- Little endian counter to cycle through bits in the byte
    
    -- IO REGISTERS
    signal TX_Data : std_logic_vector(7 downto 0) := (others => '0');       -- Byte to be transmitted, register stores i_TX_Byte
    signal TX_Finish : std_logic := '0';                                    -- Register signals to other components that the transmission is complete
    
begin

    o_TX_Finish <= TX_Finish;       -- Connect Finish signal to output port

    TX: process(Clk)
    begin
        if (rising_edge(Clk)) then
            case STATE is
            
                when IDLE =>
                    Clk_Counter <= 0;       -- Reset clock counter
                    Bit_Index <= 0;         -- Reset bit counter
                    o_TX_Finish <= '0';     -- Reset finish signal
                    o_TX_Active <= '0';     -- Disable transmitter
                    o_TX_Serial <= '1';     -- Hold line high while idle
                    
                    if (i_TX_Ready = '1') then      -- If data has been loaded to the input
                        TX_Data <= i_TX_Byte;       -- Register the input data
                        STATE <= START_BIT;         -- Move to START_BIT state
                    else                            -- If NO new data has been input
                        STATE <= IDLE;              -- Stay IDLE
                    end if;
                    
                when START_BIT =>                   
                    o_TX_Active <= '1';                         -- Enable transmitter
                    o_TX_Serial <= '0';                         -- Start bit pulls line low to signal start of byte
                    if (Clk_Counter = CLKS_PER_BIT - 1) then    -- If the process has waited for 1 UART clock period
                        Clk_Counter <= 0;                       -- Reset the clock counter
                        STATE <= DATA_BIT;                      -- Change states, and start transmitting data bits
                    else                                        -- If the process HAS NOT wait for 1 UART clock period
                        Clk_Counter <= Clk_Counter + 1;         -- Increment the clock counter
                        STATE <= START_BIT;                     -- Stay in START_BIT state
                    end if;
                                      
                when DATA_BIT =>
                    o_TX_Serial <= TX_Data(Bit_Index);          -- Output the relevant bit of the input byte
                    if (Clk_Counter = CLKS_PER_BIT - 1) then    -- If it is time to transmit a bit
                        Clk_Counter <= 0;                       -- Reset the clock counter
                        if (Bit_Index = 7) then                 -- If all bits in the byte have been sent
                            Bit_Index <= 0;                     -- Reset the Bit Index counter
                            STATE <= STOP_BIT;                  -- Move to STOP_BIT state
                        else                                    -- ELSE there are more bits to be transmitted
                            Bit_Index <= Bit_Index + 1;         -- Incremenet Bit Index to transmit the next bit in the byte
                            STATE <= DATA_BIT;                  -- Stay in DATA_BIT state to keep transmitting data
                        end if;                        
                    else                                        -- ELSE it has not been 1 UART clock period since last bit was transmitted
                        Clk_Counter <= Clk_Counter + 1;         -- Incremenet the system clock edge counter
                        STATE <= DATA_BIT;                      -- Stay in DATA_BIT state to keep transmitting data
                    end if;
                        
                when STOP_BIT =>
                    o_TX_Serial <= '1';                         -- Pull line high to signal for stop bit        
                    if (Clk_Counter = CLKS_PER_BIT - 1) then    -- If one UART clock period has passed
                        TX_Finish <= '1';                       -- Signal the transmission has ended
                        Clk_Counter <= 0;                       -- Reset the clock counter
                        STATE <= RESET;                         -- Move to reset state
                    else                                        -- If less than 1 UART clock period since started sending STOP_BIT
                        Clk_Counter <= Clk_Counter + 1;         -- Incremement the system clock counter
                        STATE <= STOP_BIT;                      -- Stay in the STOP_BIT state
                    end if;
                    
                when RESET =>   
                    o_TX_Active <= '0';                         -- Disable the transmitter
                    o_TX_Finish <= '0';                         -- Reset finish signal
                    STATE <= IDLE;                              -- Return to the IDLE state
                    
                when OTHERS =>                                  -- OTHER clause catches errors
                    STATE <= IDLE;                              -- In case of error, return to IDLE state
            end case;
        end if;
    end process;
    
end Behavioral;
