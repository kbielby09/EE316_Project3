----------------------------------------------------------------------------------
-- Company: Clarkson University
-- Engineer: Camilla Ketola
-- 
-- Create Date: 03/04/2021 02:57:51 AM
-- Design Name: adc_driver
-- Module Name: adc_driver - Behavioral
-- Project Name: EE316 Project 3
-- Target Devices: Cora Z7-10
-- Tool Versions: 
-- Description: Converts analog signals to digital
-- 
-- Dependencies: i2c_master
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

------------
---Entity---
------------

entity adc_driver is
    Port ( adc_clk      : in std_logic;     --clock
           adc_rst      : in std_logic;     --reset
           adc_en       : in std_logic;     --enables the adc
           adc_source   : in std_logic_vector(1 downto 0); -- 00 for LDR, 01 for TEMP, 10 for OP, 11 for POT
           adc_sda      : inout std_logic;  --the i2c data
           adc_scl      : inout std_logic;  --the i2c clock
           adc_data_out : out std_logic_vector(7 downto 0) --the digitized data
    );
end adc_driver;

---------------
---Behaviour---
---------------

architecture Behavioral of adc_driver is

-------------
---Signals---
-------------

type state_type is  (init, standby, sample, instruct);
signal state : state_type := init;
signal m_ena, m_rw, m_busy, m_ack_error : std_logic;
signal busy_prev    : std_logic;    --used to detect a change in the i2c busy state
signal analog_in : std_logic_vector(7 downto 0); --The data sampled
signal instructions : std_logic_vector(7 downto 0) := "000000" & adc_source; --The data for channel selection instructions
signal adc_addr  : std_logic_vector(6 downto 0) := "1001000"; --used to select this device

----------------
---Components---
----------------

component i2c_master is
  GENERIC(
    input_clk : INTEGER := 125_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 100_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
end component i2c_master;

--   component ila_0_0 is
--     port(
--     clk : in std_logic;
--     probe0 : in std_logic_vector(7 downto 0);
--     probe1 : in std_logic_vector(7 downto 0);
--     probe2 : in std_logic;
--     probe3 : in std_logic_vector(1 downto 0)
--     );
  
--   end component;
       
begin

-------------------
---Instantiation---
-------------------

inst_i2c : i2c_master
  generic map(
    input_clk => 125_000_000, --input clock speed from user logic in Hz
    bus_clk   => 100_000)   --speed the i2c bus (scl) will run at in Hz
  port map(
    clk       =>    adc_clk,                    --system clock
    reset_n   =>    adc_rst,                    --active low reset
    ena       =>    m_ena,                      --latch in command
    addr      =>    adc_addr,                   --address of target slave
    rw        =>    m_rw,                       --'0' is write, '1' is read
    data_wr   =>    instructions,               --data to write to slave
    busy      =>    m_busy,                     --indicates transaction in progress
    data_rd   =>    analog_in,                  --data read from slave--look at making a new signal for this sine out data cant be assigned
    ack_error =>    m_ack_error,                --flag if improper acknowledge from slave
    sda       =>    adc_sda,                    --serial data output of i2c bus
    scl       =>    adc_scl);                   --serial clock output of i2c bus
    
--ILA : ila_0_0
--   port map(
--     clk => adc_clk,
--     probe0 => analog_in,
--     probe1 => instructions,
--     probe2 => m_ena,
--     probe3 => adc_source
--   );

---------------
---Processes---
---------------

------------------
--State Machine---
------------------

process(adc_clk, adc_rst, adc_en)
  begin

    if(adc_rst = '0' or adc_en = '0') then              --asynchronous reset
        state <= init;
    else
        if(rising_edge(adc_clk)) then 
           
           case state is
                when init => state <= standby;  --resets and starts up the system
                             
                when standby =>     if(m_busy = '1') then                               --waits until slave is signaled for
                                        state <= standby;
                                    else 
                                        state <= instruct;                               --goes to instruction mode when not busy
                                    end if;
                                
                when sample =>      if(instructions(1 downto 0) = adc_source) then      --will sample as long as the channel is selected for
                                        state <= sample;
                                    else
                                        state <= standby;                               --goes back to standby mode when channel is changed
                                    end if;
                               
                when instruct =>    if(m_busy = '0' and busy_prev = '1') then           --only samples after aknowledgeent form the master
                                        state <= sample;
                                    else
                                        state <= instruct;                              --waits for instructions
                                    end if;
                                        
            end case;
       end if;
    end if;
       
end process;
       
---------------------
---State Behaviour---
---------------------
       
process(adc_clk)
  begin
       
    if(rising_edge(adc_clk)) then 
    
       instructions <= "000000" & adc_source;  --updates the instructions with the channel source
       
       if(state = init) then
          m_ena <= '0';
          analog_in <= "00000000";
          m_busy <= '1'; 
          m_rw <= '1';  
          --consider adding in a counter for timing purposes 
                             
       elsif(state = standby) then 
          m_ena <= '0';
          m_busy <= '0';
                                
       elsif(state = sample) then
          m_rw <= '1';  --changes to read mode
          adc_data_out <= analog_in;   --outputs the digitized analog signal
                               
       elsif(state = instruct) then
          m_ena <= '1'; --enables the I2C connection
          m_rw <= '0';  --changes to write mode
          m_busy <= '1';      
       
       else 
          state <= standby; --just incase something weird happens, it'll stay in standby mode
          
       end if;         
    end if;
end process;

------------------------
---Busy Signal Change---
------------------------

process(adc_clk)
begin
    if(rising_edge(adc_clk)) then 
        busy_prev <= m_busy;
    end if;
end process;

end Behavioral;
