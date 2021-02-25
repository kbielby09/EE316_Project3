----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 02/25/2021 12:53:45 PM
-- Design Name:
-- Module Name: I2C_LCD_driver - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity I2C_LCD_driver is
 Port (
   I_RESET_N   : in std_logic;
   I_CLK_50MHZ : in std_logic;

   SDA : inout std_logic;
   SCL : inout std_logic;

   -- Data
   source : in std_logic_vector(2 downto 0)
);
end I2C_LCD_driver;

architecture Behavioral of I2C_LCD_driver is

  component i2c_master is
  GENERIC(
      input_clk : INTEGER := 100_000_000; --input clock speed from user logic in Hz
      bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
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
  END component i2c_master;

  signal Cont 		: unsigned(19 downto 0) := X"03FFF";

  type state_type is (start, write_data, repeat);
  signal state : state_type := start;

  signal i2c_addr : std_logic_vector(6 downto 0);
  signal regBusy, sigBusy, reset_n, i2c_ena, i2c_rw, ack_err : std_logic;
  signal data_wr: std_logic_vector(7 downto 0);
  signal byteSel : integer := 0;
  signal regData: std_logic_vector(15 downto 0);

begin

  inst_master : i2c_master
  generic map(
    input_clk => 50_000_000, -- TODO need to change this for Cora Z7-10
    bus_clk   => 100_000
  )
  port map(
  	clk => I_CLK_50MHZ,
  	reset_n => I_RESET_N,
  	ena => i2c_ena,
  	addr => i2c_addr,
  	rw => i2c_rw,
  	data_wr => data_wr,
  	busy => sigBusy,
  	data_rd => OPEN,      -- WHATS THIS?
  	ack_error => ack_err,
  	sda => oSDA,
  	scl => oSCL
  );

  process(clk)
  begin
  if(rising_edge(clk)) then
  	regData <= iData;
  	regBusy <= sigBusy;
  	case state is
  		when start =>
  			if Cont /= X"00000" then
  				Cont <= Cont -1;
  				reset_n <= '0';
  				state <= start;
  				i2c_ena <= '0';
  			else
  				reset_n <= '1';
  				i2c_ena <= '1';
  				i2c_addr <= "1110001"; -- TODO may need to change this
  				i2c_rw <= '0';
  				state <= write_data;
  			end if;
  		when write_data =>
  		if regBusy/=sigBusy and sigBusy='0' then
  			if byteSel /= 12 then
  				byteSel <= byteSel + 1;
  				state <= write_data;
  			else
  				byteSel <= 9;
  				i2c_ena <= '0';
  				state <= repeat;
  			end if;
  		end if;
  		when repeat => -- wait for new data
  			i2c_ena <= '0';
  			if regData /= iData then
  				Cont <= X"03FFF";
  				state <= start;
  			else
  				state <= repeat;
  			end if;
  		end case;
  end if;
  end process;

end Behavioral;
