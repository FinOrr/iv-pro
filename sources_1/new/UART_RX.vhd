library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library WORK;
use WORK.SYS_PARAM.ALL;

entity UART_Receiver is
    generic (
        BAUD_RATE : natural := 115_200
    );
    port (
        Clk         : in std_logic;                         -- System clock
        i_RX        : in std_logic;                         -- Serial input port
        o_RX_Finish : out std_logic;                        -- Signal driven high when finished recieving data
        o_RX_Byte   : out std_logic_vector(7 downto 0)      -- Byte output
    );
end UART_Receiver;

architecture Behavioral of UART_Receiver is

    constant CLKS_PER_BIT : natural := (SYS_XTAL_FREQ / BAUD_RATE);     -- Number of system clock cycles per UART clock cycle
    
    type t_UART_SM is (IDLE, START_BIT, DATA_BIT, STOP_BIT, RESET);     -- UART modelled as FSM
    signal State : t_UART_SM := IDLE;                                   -- Active state stored in register 'STATE'
    
    signal RX_Data_Buffer   : std_logic := '0';                         -- Buffer the input RX bit
    signal RX_Data          : std_logic := '0';                         -- Register holds the double-flopped input bit
    
    signal Clk_Counter  : natural range 0 to CLKS_PER_BIT - 1 := 0;     -- Clock edge counter, used to find the middle of the data bit
    signal Bit_Index    : natural range 0 to 7 := 0;                    -- Little endian goes from LSB -> MSB
    signal RX_Byte      : std_logic_vector(7 downto 0) := x"00";        -- Output byte register
    signal RX_Finish    : std_logic := '0';                             -- Finish signal register
    
begin

    o_RX_Finish <= RX_Finish;       -- Connect finish register to output
    o_RX_Byte <= RX_Byte;           -- Connect built byte register to output

    Double_Flop: process(Clk)               -- Double flop RX input to prevent metastability
    begin
        if (rising_edge(Clk)) then
            RX_Data_Buffer <= i_RX;         -- Feed the input into a buffer flip-flop
            RX_Data <= RX_Data_Buffer;      -- Read buffer into active RX register
        end if;
    end process;
    
    RX: process(Clk)
    begin
        if (rising_edge(Clk)) then
            case State is
            
                when IDLE =>            -- Idle is waiting for the start bit
                    RX_Finish <= '0';   -- Finish signal is false
                    Clk_Counter <= 0;   -- Reset clock edge counter
                    Bit_Index <= 0;     -- Reset bit index counter
                    
                    if (RX_Data = '0') then     -- Check for line pulled low, this is the start bit
                        STATE <= START_BIT;     -- If start bit detected, change to start bit state
                    else
                        STATE <= IDLE;          -- If no start bit is detected, the line is still idle
                    end if;
                    
                when START_BIT =>                                       -- Sample start bit and confirm it is still low
                    if (Clk_Counter = (Clks_Per_Bit - 1) / 2) then      -- Wait until the middle of the bit
                        if (RX_Data = '0') then                         -- If the start bit is still low
                            Clk_Counter <= 0;                           -- Reset clock counter, now for each Clks_Per_Bit period, the middle of the data bit is sampled
                            STATE <= DATA_BIT;                          -- Start bit is detected, move to reading data bit
                        else
                            STATE <= IDLE;                              -- The stop bit was not steady, reset to idle state
                        end if;
                    else                                                -- If not in the middle of the bit yet
                        Clk_Counter <= Clk_Counter + 1;                 -- Increment the clock counter
                        STATE <= START_BIT;                             -- Stay in START_BIT state until middle of bit sample
                    end if;
                    
                when DATA_BIT =>
                    if (Clk_Counter < Clks_Per_Bit - 1) then            -- If the system is NOT in the middle of the data bit
                        Clk_Counter <= Clk_Counter + 1;                 -- Increment the clock edge counter
                        STATE <= DATA_BIT;                              -- Stay in the DATA BIT sampling state
                    else                                                -- ELSE the current clock cycle is in the middle of the data bit
                        Clk_Counter <= 0;                               -- Reset the clock counter
                        RX_Byte(Bit_Index) <= RX_Data;                  -- Sample the relevant bit into the RX_Byte register
                        if (Bit_Index = 7) then                         -- Check if whole byte HAS been sampled
                            Bit_Index <= 0;                             -- Reset bit counter
                            STATE <= STOP_BIT;                          -- Move to next state, STOP_BIT
                        else                                            -- If the whole byte HAS NOT been sampled
                            Bit_Index <= Bit_Index + 1;                 -- Move to next bit index
                            STATE <= DATA_BIT;                          -- Stay in DATA_BIT sampling state
                        end if;
                    end if;
                    
                when STOP_BIT =>
                    if (Clk_Counter < Clks_Per_Bit - 1) then            -- Check if whole bit period HAS NOT passed
                        Clk_Counter <= Clk_Counter + 1;                 -- Increment the clock counter
                        STATE <= STOP_BIT;                              -- Stay in the STOP_BIT state
                    else                                                -- If bit period is complete
                        RX_Finish <= '1';                               -- Signal end of byte, so RX_Byte can be read
                        Clk_Counter <= 0;                               -- Reset clock counter
                        STATE <= RESET;                                 -- Move to reset state
                    end if;
                    
                when RESET =>
                    RX_Finish <= '0';                                   -- Clear the FINISH output
                    STATE <= IDLE;                                      -- Move to the IDLE state

                when others =>                                          -- Catch errors
                    STATE <= IDLE;                                      -- Reset state to idle
            end case;
        end if;
    end process;
end Behavioral;
