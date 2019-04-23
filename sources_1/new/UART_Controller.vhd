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
        i_Send          : in std_logic;                         -- Trigger to start sending frame buffer
        i_RX            : in std_logic;
        i_FB_Byte       : in std_logic_vector(7 downto 0);
        -- Outputs
        o_Input_Mode    : out std_logic;
        o_Contrast_En   : out std_logic;
        o_Threshold_En  : out std_logic;
        o_Median_En     : out std_logic;
        o_Coef_En       : out std_logic;
        o_Coef_Adr      : out std_logic_vector(7 downto 0);
        o_Adr           : out std_logic_vector(FB_ADR_BUS_WIDTH -1 downto 0); -- Address of pixel value in frame buffer
        o_Write_En      : out std_logic;                        -- Enable the frame buffer to write the data value
        o_FB_Byte       : out std_logic_vector(7 downto 0);
        o_Threshold     : out std_logic_vector(7 downto 0);     -- Threshold value for threshold function
        o_TX            : out std_logic                         -- Bit to be transmitted 
    );
end UART_Controller;

architecture Behavioral of UART_CONTROLLER is

    component UART_Receiver
        generic (
            BAUD_RATE : natural := 115_200
        );
        port (
            Clk         : in std_logic;                         -- System clock
            i_RX        : in std_logic;                         -- Serial input port
            o_RX_Finish : out std_logic;                        -- Signal driven high when finished recieving data
            o_RX_Byte   : out std_logic_vector(7 downto 0)      -- Byte output
        );
    end component;
    
    component UART_Transmitter
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
    end component;
    signal Coef_Adr     : std_logic_vector(7 downto 0) := (others => '0');
    signal Coef_En      : std_logic := '0';
    signal Adr          : unsigned(FB_ADR_BUS_WIDTH-1 downto 0) := (others => '0');     -- RAM address
    signal Byte_Count   : natural range 0 to FRAME_PIXELS := 0;                         -- Number of received bytes
    signal CMD_Sent     : std_logic := '0';                                             -- filter configured flag
    
    signal RX_Finish    : std_logic := '0';
    signal RX_Byte      : std_logic_vector(7 downto 0) := (others => '0');
    
    signal TX_Ready     : std_logic := '0';
    signal TX_Active    : std_logic := '0';
    signal TX_Serial    : std_logic := '0';
    signal TX_Finish    : std_logic := '0';
    signal TX_Byte      : std_logic_vector(7 downto 0) := (others => '0');
    
begin 

    o_Adr <= std_logic_vector(to_unsigned((Byte_Count), FB_ADR_BUS_WIDTH));
   
    UART_RX: UART_Receiver
        generic map (
            BAUD_RATE => 115200
        )
        port map (
            Clk         => Clk,
            i_RX        => i_RX,
            o_RX_Finish => RX_Finish,
            o_RX_Byte   => RX_Byte
        );
        
    UART_TX: UART_Transmitter
        generic map (
            BAUD_RATE => 115_200
        )
        port map (
            Clk         => Clk,
            i_TX_Ready  => TX_Ready,
            i_TX_Byte   => TX_Byte,
            o_TX_Active => TX_Active,
            o_TX_Serial => o_TX,
            o_TX_Finish => TX_Finish
        );
    
    TX_Proc: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (TX_Active = '0') then
                if (RX_Finish = '1') then     -- If transmitter is sent
                    TX_Byte <= i_FB_Byte;     -- Load pixel value to transmitter
                    TX_Ready <= '1';          -- Stop transmitter
                else
                    TX_Ready <= '0';          -- Wait for byte to be sent before loading a new one
               end if; -- RX Finish check
            end if; -- TX Active check
        end if; -- clock edge check
    end process;
    
    RX_Proc: process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (TX_Active = '0') then         -- If transmitter if inactive
                if (RX_Finish = '1') then     -- If byte has been received
                    if (CMD_Sent = '0') then    -- First command bytes haven't been received
                        Byte_Count <= Byte_Count + 1;
                        case Byte_Count is
                            when 0 =>                           -- Filter type CMD byte
                                o_Input_Mode <= RX_Byte(7);     -- [7] = '0': use camera input.     [7] = '1': use UART values
                                if (RX_Byte(3 downto 0) = x"0") then   -- WINDOW OPERATION
                                    o_Contrast_En <= '0';       -- Disable Contrast stretching filter
                                    o_Threshold_En <= '0';      -- Disable thresholding filter
                                    o_Median_En <= '0';         -- Disable median filter
                                elsif (RX_Byte(3 downto 0) = x"1") then -- CONTRAST STRETCH OPERATION
                                    o_Contrast_En <= '1';       -- Enable constrast stretching filter
                                    o_Threshold_En <= '0';      -- Disable thresholding filter
                                    o_Median_En <= '0';         -- Disable median filter
                                elsif (RX_Byte(3 downto 0) = x"2") then -- THRESHOLDING OPERATION
                                    o_Contrast_En <= '0';       -- Disable contrast stretching filter
                                    o_Threshold_En <= '1';      -- Enable thresholding filter
                                    o_Median_En <= '0';         -- Disable median filter
                                elsif (RX_Byte(3 downto 0) = x"3") then -- MEDIAN FILTER
                                    o_Contrast_En <= '0';       -- Disable constrast stretching
                                    o_Threshold_En <= '0';      -- Disbale thresholding
                                    o_Median_En <= '1';         -- Enable median filtering
                                else                        -- In case of error, WINDOW OPERATION by default
                                    o_Contrast_En <= '0';       -- Disable Contrast stretching filter
                                    o_Threshold_En <= '0';      -- Disable thresholding filter
                                    o_Median_En <= '0';         -- Disable median filter
                                end if;
                            when 1 =>       -- Filter ROM adr
                                o_Coef_Adr <= RX_Byte;
                                o_Coef_En  <= '1';
                                Byte_Count <= Byte_Count + 1;
                            when 2 =>
                                o_Threshold <= RX_Byte;
                                o_Coef_En <= '0';
                                CMD_Sent <= '1';
                                Byte_Count <= 0;
                            when others =>
                        end case;
                    else                            -- Receiving data byte
                        o_FB_Byte <= RX_Byte;     -- Load the received byte to frame buffer Data In bus
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