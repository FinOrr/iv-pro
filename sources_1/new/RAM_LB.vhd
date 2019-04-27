library WORK;
use WORK.SYS_PARAM.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity RAM_LB is
    port (
        -- CLOCK 
        Clk     : in std_logic;                     -- RAM write port clock
        -- PORT A
        Adr   : in std_logic_vector(LB_ADR_BUS_WIDTH-1 downto 0);
        Di    : in std_logic_vector(BPP-1 downto 0);                -- Data in
        We    : in std_logic;                                       -- Write Enable
        Do    : out std_logic_vector(BPP-1 downto 0)
    );
end RAM_LB;
 
architecture Behavioral of RAM_LB is

    -- RAM Declaration
    type t_RAM_LB is array (FRAME_WIDTH downto 0) of std_logic_vector(BPP-1 downto 0);  -- Currently testing 8 bits per pixel, 480p
    signal RAM : t_RAM_LB := (others => (others => '0'));
    
begin
    
    Port_Control: process(Clk)
    begin
        if (rising_edge(Clk)) then
            Do <= RAM(to_integer(unsigned(Adr)));
            if (We = '1') then                          -- Write After Read
                RAM(to_integer(unsigned(Adr))) <= Di;
            end if;
        end if;
    end process;
       
end Behavioral;