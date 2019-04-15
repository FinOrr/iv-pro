library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity OV5642_Capture is
    port (
        -- Inputs
        i_Pixel_Clk   :   in  std_logic;
        i_H_Ref       :   in  std_logic;
        i_Pixel_Data  :   in  std_logic_vector(7  downto 0);
        -- Outputs
        o_En_a        :   out std_logic;        
        o_We          :   out std_logic;        
        o_Adr_a       :   out std_logic_vector(10 downto 0);        
        o_Do          :   out std_logic_vector(11 downto 0)
    );
end OV5642_Capture;

architecture Behavioral of OV5642_Capture is
    
    -- Define the FSM states
    type t_Capture_State is (IDLE, CACHE, WRITE);
    signal State        :   t_Capture_State := IDLE;
    -- Internal signal declarations
    signal Addr         :   std_logic_vector(10 downto 0) := "00000000000";  -- RAM index to store pixel data
    signal Byte_Cache   :   std_logic_vector(11 downto 0) := x"000";        -- 1px = 2B, so we need to store the last byte of input 
    -- I/O Buffers
    signal Pixel_Clk    :   std_logic;
    signal H_Ref        :   std_logic;
    signal Pixel_Data   :   std_logic_vector(7 downto 0);
    signal En_a         :   std_logic := '1';
    signal We           :   std_logic;
    
begin
    
    -- Connect IO
    Pixel_Clk   <= i_Pixel_Clk; 
    H_Ref       <= i_H_Ref;
    Pixel_Data  <= i_Pixel_Data;
    o_En_a      <= En_a;
    o_We        <= We;
    o_Adr_a     <= Addr;        -- Counter 'Addr' keeps count of the RAM address to write to (on PORT A) 
    o_Do        <= Byte_Cache;  -- Byte Cache collects the RGB bits and sends them to output
    
    State_Control: process(Pixel_Clk)
    begin
        if (falling_edge(Pixel_Clk)) then
            
            -- FSM controls the camera capture behaviour
            case State is
                -- State machine is idle when in blanking periods
                when IDLE =>
                    if (H_Ref = '1') then
                        State <= CACHE;
                    else
                        State <= IDLE;
                    end if;
                    
                -- Byte 1 of 2 needs to be cached before writing RGB bits to memory
                when CACHE =>
                    if (H_Ref = '1') then
                        State <= WRITE;
                    else
                        State <= IDLE;
                    end if;
                
                -- Receive byte 2 of 2 and write it to memory. If it's the last pixel then go idle, otherwise cache the next byte.
                when WRITE =>
                    if (H_Ref = '1') then
                        State <= CACHE;
                    else
                        State <= IDLE;
                    end if;
            end case;
        end if;
    end process;
    
    
    Capture: process(Pixel_Clk)
    begin
        if (rising_edge(Pixel_Clk)) then
            case State is
            
                when IDLE =>
                    Addr    <= "00000000000";   -- Reset RAM pointer to 0 for new line
                    We      <= '0';
                    En_a    <= '0';
                    
                when CACHE =>
                    We      <= '0';     -- Disable Write_Enable
                    En_a    <= '0';     -- Disable PORT A
                    Byte_Cache(11 downto 5) <= Pixel_Data(7 downto 4) & Pixel_Data(2 downto 0);     -- Cache R[3:0] AND G[3:1] into data cache
                
                when WRITE =>
                    Byte_Cache(4 downto 0) <= Pixel_Data(7) & Pixel_Data(4 downto 1);   -- Load G[0] AND B[3:0] into cache
                    We      <= '1';     -- Enable RAM Write Enable
                    En_a    <= '1';     -- Enable RAM PORT A
                    Addr    <= std_logic_vector(unsigned(Addr) + 1);        -- Increment RAM pointer
                    
            end case;
        end if;
                    
    end process;
end Behavioral;