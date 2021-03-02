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
   Generation : in std_logic;
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

  type INIT_STATE is (
      INIT0,
      INIT1,
      INIT2,
      INIT3,
      INIT4,
      INIT5,
      INIT6,
      INIT7
  );

  signal lcd_init_state : INIT_STATE := INIT0;

  signal i2c_addr : std_logic_vector(7 downto 0);
  signal regBusy, sigBusy, reset_n, i2c_ena, i2c_rw, ack_err : std_logic;
  signal data_wr: std_logic_vector(7 downto 0);
  signal byteSel : integer := 0;
  signal regData: std_logic_vector(15 downto 0);
  signal refresh : std_logic := '0';
  signal previous_source : std_logic_vector(2 downto 0);
  signal previous_generation : std_logic := '0';

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
  	addr => i2c_addr(6 downto 0),
  	rw => i2c_rw,
  	data_wr => data_wr,
  	busy => sigBusy,
  	data_rd => OPEN,      -- WHATS THIS?
  	ack_error => ack_err,
  	sda => SDA,
  	scl => SCL
  );

  REFRESH_DISPLAY : process(I_RESET_N, I_CLK_50MHZ)
  begin
    if (I_RESET_N = '0') then
      refresh <= '0';
    elsif (rising_edge(I_CLK_50MHZ)) then
      previous_source <= source;
      previous_generation <= Generation;
      if (previous_source /= source or previous_generation /= Generation) then
        refresh <= '1';
      end if;
      refresh <= '0';
    end if;
  end process;

  -- INIT_COUNTER : process(I_CLK_50MHZ, I_RESET_N)
  --   begin
  --     if (rising_edge(I_CLK_50MHZ)) then
  --       if (lcd_initialized = '0') then
  --         sixteen_ms_count        <= sixteen_ms_count + 1;
  --         forty_four_micro_elapse <= '0';
  --
  --         if (sixteen_ms_count = "11000011010100000000"
  --             and lcd_init_state = INIT0) then
  --           sixteen_ms_elapse <= '1';
  --           sixteen_ms_count <= (others => '0');
  --
  --         elsif (sixteen_ms_count = "111101000010010000"
  --                and lcd_init_state = INIT1) then
  --           five_ms_elapse <= '1';
  --           sixteen_ms_count <= (others => '0');
  --
  --         elsif (sixteen_ms_count = "1001110111010"
  --                and lcd_init_state = INIT2) then
  --             one_hundred_micro_elapse <= '1';
  --             sixteen_ms_count <= (others => '0');
  --
  --         elsif (sixteen_ms_count = "100010011000"
  --                and (lcd_init_state = INIT3
  --                     or lcd_init_state = INIT4
  --                     or lcd_init_state = INIT5
  --                     or lcd_init_state = INIT6
  --                     or lcd_init_state = INIT7)) then
  --           forty_four_micro_elapse <= '1';
  --           sixteen_ms_count <= (others => '0');
  --         end if;
  --       end if;
  --     end if;
  -- end process INIT_COUNTER;

  -- DIGIT_STATE : process(I_CLK_50MHZ, I_RESET_N)
  --   begin
  --     -- if (I_RESET_N = '0') then
  --     --   current_digit <= DIGIT0;
  --     -- elsif (rising_edge(I_CLK_50MHZ)) then
  --     if (rising_edge(I_CLK_50MHZ)) then
  --       if (lcd_initialized = '1' and DATA_CHANGE = '1') then
  --         current_digit <= DIGIT0;
  --       end if;
  --
  --       if (I_RESET_N = '0' and previous_reset = '1') then
  --         current_digit <= DIGIT0;
  --       end if;
  --
  --       if (lcd_initialized = '1'
  --           and lcd_enable = '0'
  --           and previous_enable_value = '1') then
  --         -- if (DATA_CHANGE = '1') then
  --         --   current_digit <= DIGIT0;
  --         -- end if;
  --         case (current_digit) is
  --           when DIGIT0 =>
  --             current_digit <= DIGIT1;
  --           when DIGIT1 =>
  --             current_digit <= DIGIT2;
  --           when DIGIT2 =>
  --             current_digit <= DIGIT3;
  --           when DIGIT3 =>
  --             current_digit <= DIGIT4;
  --           when DIGIT4 =>
  --             current_digit <= DIGIT5;
  --           when DIGIT5 =>
  --             current_digit <= DIGIT6;
  --           when DIGIT6 =>
  --             current_digit <= DIGIT7;
  --           when DIGIT7 =>
  --             current_digit <= DIGIT8;
  --           when DIGIT8 =>
  --             current_digit <= DIGIT9;
  --           when DIGIT9 =>
  --             current_digit <= DIGIT10;
  --           when DIGIT10 =>
  --             current_digit <= DIGIT11;
  --           when DIGIT11 =>
  --             current_digit <= DIGIT12;
  --           when DIGIT12 =>
  --             current_digit <= DIGIT13;
  --           when DIGIT13 =>
  --             current_digit <= DIGIT14;
  --           when DIGIT14 =>
  --             current_digit <= DIGIT15;
  --           when DIGIT15 =>
  --             current_digit <= DIGIT16;
  --           when DIGIT16 =>
  --             current_digit <= DIGIT17;
  --           when DIGIT17 =>
  --             current_digit <= DIGIT18;
  --           when DIGIT18 =>
  --             current_digit <= DIGIT19;
  --           when DIGIT19 =>
  --             current_digit <= DIGIT20;
  --           when DIGIT20 =>
  --             current_digit <= DIGIT21;
  --           when DIGIT21 =>
  --             current_digit <= DIGIT22;
  --           when DIGIT22 =>
  --             current_digit <= DIGIT23;
  --           when DIGIT23 =>
  --             current_digit <= DIGIT24;
  --           when DIGIT24 =>
  --             current_digit <= DIGIT25;
  --           when DIGIT25 =>
  --             current_digit <= DIGIT26;
  --           when DIGIT26 =>
  --             current_digit <= DIGIT27;
  --           when DIGIT27 =>
  --             current_digit <= DIGIT28;
  --           when DIGIT28 =>
  --             current_digit <= DIGIT29;
  --           when DIGIT29 =>
  --             current_digit <= DIGIT30;
  --           when DIGIT30 =>
  --             current_digit <= DIGIT31;
  --           when DIGIT31 =>
  --             current_digit <= DIGIT32;
  --           when DIGIT32 =>
  --             -- wait for display data change
  --         end case;
  --       end if;
  --     end if;
  -- end process DIGIT_STATE;

  process(I_CLK_50MHZ)
  begin
  if(rising_edge(I_CLK_50MHZ)) then
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
  				i2c_addr <= X"27"; -- TODO may need to change this
  				i2c_rw <= '0';
  				state <= write_data;
  			end if;
  		when write_data =>
  		if regBusy/=sigBusy and sigBusy='0' then
  			if byteSel /= 11 then
  				byteSel <= byteSel + 1;
  				state <= write_data;
  			else
  				byteSel <= 0;
  				i2c_ena <= '0';
  				state <= repeat;
  			end if;
  		end if;
  		when repeat => -- wait for new data
  			i2c_ena <= '0';
  			-- if refresh = '1' then
  				Cont <= X"09FFE";
  				state <= start;
  			-- else
  				-- state <= repeat;
  			-- end if;
  		end case;
  end if;
  end process;

  process(byteSel) -- TODO change lookup table for Initializing and operation
  begin
  	case byteSel is
      -----------------------begin initialization sequence----------------------
  		when 0 =>
        data_wr <= X"34";
  		when 1 =>
        data_wr <= X"34";
  		when 2 =>
        data_wr <= X"34";
  		when 3 =>
        data_wr <= X"24";
  		when 4 =>
        data_wr <= X"24";
  		when 5 =>
        data_wr <= X"C4";
  		when 6 =>
        data_wr <= X"04";
  		when 7 =>
        data_wr <= X"84";
  		when 8 =>
        data_wr <= X"04";
  		when 9 =>
        data_wr <= X"14";
  		when 10 =>
        data_wr <= X"04";
  		when 11 =>
        data_wr <= X"34";
      ---------------------------end initialization-----------------------------
      -- when 12 =>
      --   if (source = "00") then
      --
      --   elsif (source = "01") then
      --   elsif (source = "10") then
      --
      --   end if;
      -- when 13 =>
      --   data_wr <= x"";
      -- when 14 =>
      --   data_wr <= x"";
      -- when 15 =>
      --   data_wr <= x"";
      -- when 16 =>
      --   data_wr <= x"";
      -- when 17 =>
      --   data_wr <= x"";
      -- when 18 =>
      --   data_wr <= x"";
      -- when 19 =>
      --   data_wr <= x"";
      -- when 20 =>
      --   data_wr <= x"";
  		when others =>
      -- data_wr <= X"76";
  	end case;
  end process;

end Behavioral;
