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
-- Dependencies: i2c master
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

------------
---Entity---
------------

entity adc_driver is
    Port ( adc_clk      : in std_logic;     --clock
           adc_rst      : in std_logic;     --reset
           --adc_en       : in std_logic;     --enables the adc
           adc_source   : in std_logic_vector(1 downto 0); -- 00 for LDR, 01 for TEMP, 10 for OP, 11 for POT
           adc_sda          : inout std_logic;  --the i2c data
           adc_scl          : inout std_logic;  --the i2c clock
           adc_data_out : out std_logic_vector(7 downto 0) --the digitized data
          -- adc_busy         : out std_logic  --for comminicating with i2c --probably not needed
    );
end adc_driver;

---------------
---Behaviour---
---------------

architecture Behavioral of adc_driver is

-------------
---Signals---
-------------

type state_type is  (init, standby, sample, read);
signal state : state_type := init;
signal m_ena, m_rw, m_busy, m_ack_error : std_logic;
signal to_store : std_logic_vector(7 downto 0);
signal adc_addr  : std_logic_vector(6 downto 0);

----------------
---Components---
----------------

component i2c_master is
  GENERIC(
    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
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
    
-- make component for ADC/DAC Register 

--component for flip flop??
    
begin

------------------
---Instantiation--
------------------

inst_i2c : i2c_master
  generic map(
    input_clk => 50_000_000, --input clock speed from user logic in Hz
    bus_clk   => 400_000)   --speed the i2c bus (scl) will run at in Hz !!NOTE THIS NEEDS TO BE CHANGED!!
  port map(
    clk       =>    adc_clk,                    --system clock
    reset_n   =>    adc_rst,                    --active low reset
    ena       =>    m_ena,                      --latch in command
    addr      =>    adc_addr,                   --address of target slave
    rw        =>    m_rw,                       --'0' is write, '1' is read
    data_wr   =>    to_store,                   --data to write to slave
    busy      =>    m_busy,                     --indicates transaction in progress
    data_rd   =>    adc_data_out,               --data read from slave--look at making a new signal for this sine out data cant be assigned
    ack_error =>    m_ack_error,                --flag if improper acknowledge from slave
    sda       =>    adc_sda,                    --serial data output of i2c bus
    scl       =>    adc_scl);                   --serial clock output of i2c bus

---------------
---Processes---
---------------

------------------
--State Machine---
------------------

process(adc_clk, adc_rst)
  begin

    if(adc_rst = '0') then              --asynchronous reset
        adc_addr <= "0000000";
        m_ena    <= '0';   
    else
        if(rising_edge(adc_clk)) then 
           
           case state is
                when init => adc_addr <= "1001000";
                             m_ena <= '1';
                             to_store <= "00000000";
                             m_busy <= '0';   
                             state <= standby;
                             
                when standby => adc_addr <= "10000" & adc_source;
                                m_busy <= '0';
                                if() then
                                    state <= sample;
                                else 
                                    state <= standby;
                                end if;
                                
                when sample => to_store <= "00000000"; -- some random value for right now
                               m_busy <= '1';
                               state <= standby;
                               
                when read => adc_addr <= "10010001";
                             m_busy <= '1';
                             adc_data_out <= to_store;
                             state <= standby;
                             
            end case;
       end if;
    end if;

--Do I need a counter here? Why?

end process;

end Behavioral;
