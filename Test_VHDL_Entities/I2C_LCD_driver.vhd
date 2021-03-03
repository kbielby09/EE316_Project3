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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity I2C_LCD_driver is
 Port (
   I_RESET_N   : in std_logic;
   I_CLK_125MHZ : in std_logic;

   SDA : inout std_logic;
   SCL : inout std_logic;

   -- Data
   Generation : in std_logic;
   source : in std_logic_vector(2 downto 0)
);
end I2C_LCD_driver;

architecture Behavioral of I2C_LCD_driver is

  component ila_0 is
    port(
    clk : in std_logic;
    probe0 : in std_logic_vector(19 downto 0);
    probe1 : in std_logic_vector(7 downto 0);
    probe2 : in std_logic;
    probe3 : in std_logic_vector(20 downto 0)
    );

  end component;

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

  signal Cont 		: unsigned(23 downto 0) := (others => '0'); --X"1C9C38"; --X"02EB13";

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
      INIT7,
      INIT8,
      INIT9,
      INIT10
  );

  signal lcd_init_state : INIT_STATE := INIT0;

  signal i2c_addr : std_logic_vector(7 downto 0);
  signal regBusy, sigBusy, reset_n, i2c_ena, i2c_rw, ack_err : std_logic;
  signal data_wr: std_logic_vector(7 downto 0);
  signal byteSel : integer := 0;
  signal regData: std_logic_vector(15 downto 0);
  signal refresh : std_logic := '0';
  signal reset_p : std_logic := not(I_RESET_N);
  signal initial_wait : std_logic := '0';
  signal lcd_initialized : std_logic := '0';
  -- signal previous_source : std_logic_vector(2 downto 0);
  -- signal previous_generation : std_logic := '0';

begin

  inst_master : i2c_master
  generic map(
    input_clk => 125_000_000, -- TODO need to change this for Cora Z7-10
    bus_clk   => 100_000
  )
  port map(
  	clk => I_CLK_125MHZ,
  	reset_n => reset_p,
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

  ILA : ila_0
  port map(
    clk => I_CLK_125MHZ,
    probe0 => std_logic_vector(Cont(19 downto 0)),
    probe1 => data_wr,
    probe2 => i2c_ena,
    probe3 => std_logic_vector(to_unsigned(byteSeL, 21))
  );



  COMMAND_COUNT : process(I_CLK_125MHZ)
  begin
    if (I_RESET_N = '1') then
      byteSeL <= 0;
      -- Cont <=  X"02EB13";
      Cont <=  X"000000";
    elsif (rising_edge(I_CLK_125MHZ)) then
      Cont <= Cont + 1;
      if (Cont = X"02EB13" and initial_wait = '1') then
        if (state = write_data and byteSeL < 12) then
          byteSeL <= byteSeL + 1;
        elsif (state = write_data and byteSeL > 12 and byteSeL < 14) then
          if (regBusy/=sigBusy and sigBusy='0') then
            byteSeL <= byteSeL + 1;
          end if;
        -- else
        --   byteSeL <= 12;
        end if;
        Cont <= X"000000";
      end if;
    end if;
  end process;

  FIRST_WAIT : process(I_RESET_N)
  begin
    if (I_RESET_N = '1') then
      initial_wait <= '0';
    else
      if (initial_wait = '0' and Cont = X"1C9C38") then
        initial_wait <= '1';
      end if;
    end if;
  end process;

  SET_EN : process(I_CLK_125MHZ)
  begin
    if (rising_edge(I_CLK_125MHZ)) then
      if (I_RESET_N = '1') then
        i2c_ena <= '0';
      end if;
        if (initial_wait = '1') then
          case( state ) is
            when start =>
              i2c_ena <= '0';
            when write_data =>
              if (byteSeL < 14) then
                i2c_ena <= '1';
              else
                i2c_ena <= '0';
              end if;

            when repeat =>
              i2c_ena <= '0';
          end case;
        end if;
    end if;
  end process;

  process(I_CLK_125MHZ)
  begin
  if(rising_edge(I_CLK_125MHZ)) then
    if (initial_wait = '1') then
      regBusy <= sigBusy;
    	case state is
    		when start =>
    			if Cont /= X"02EB13" then
    				reset_n <= '0';
    				state <= start;
    			else
    				reset_n <= '1';
    				i2c_addr <= X"27";
    				i2c_rw <= '0';
    				state <= write_data;
    			end if;
    		when write_data =>
    		-- if regBusy/=sigBusy and sigBusy='0' then
    			if byteSel /= 13 then
    				state <= write_data;
    			else
    				state <= repeat;
    			end if;
    		-- end if;
    		when repeat => -- wait for new data
    			-- if refresh = '1' then
    				state <= start;
    			-- else
    				-- state <= repeat;
    			-- end if;
    		end case;
    end if;
  end if;
  end process;

  -- INIT_BYTES : process(I_CLK_125MHZ, I_RESET_N)
  -- begin
  --   if (I_RESET_N = '1') then
  --   elsif (rising_edge(I_CLK_125MHZ) then
  --     case( lcd_init_state ) is
  --       when INIT0 =>
  --         -- wait for 15ms
  --       when INIT1 =>
  --
  --       when INIT2 =>
  --         -- wait for 4.1ms
  --       when INIT3 =>
  --       when INIT4 =>
  --       when INIT5 =>
  --       when INIT6 =>
  --       when INIT7 =>
  --       when INIT8 =>
  --       when INIT9 =>
  --       when INIT10 =>
  --       when others =>
  --         -- DO NOTHING
  --     end case;
  --
  --   end if;
  -- end process;

  process(byteSel) -- TODO change lookup table for Initializing and operation
  begin
    if (initial_wait = '1') then
      case byteSel is
        -----------------------begin initialization sequence----------------------
    		when 0 =>
          if (Cont < X"00001D") then
            data_wr <= X"38";
          else
            data_wr <= X"3C";
          end if;

    		when 1 =>
          if (Cont < X"00001D") then
            data_wr <= X"38";
          else
            data_wr <= X"3C";
          end if;

    		when 2 =>
          if (Cont < X"00001D") then
            data_wr <= X"38";
          else
            data_wr <= X"3C";
          end if;

    		when 3 =>
          if (Cont < X"00001D") then
            data_wr <= X"28";
          else
            data_wr <= X"2C";
          end if;

    		when 4 =>
          if (Cont < X"00001D") then
            data_wr <= X"28";
          else
            data_wr <= X"2C";
          end if;

    		when 5 =>
          if (Cont < X"00001D") then
            data_wr <= X"C8";
          else
            data_wr <= X"CC";
          end if;

    		when 6 =>
          if (Cont < X"00001D") then
            data_wr <= X"08";
          else
            data_wr <= X"0C";
          end if;

    		when 7 =>
          if (Cont < X"00001D") then
            data_wr <= X"88";
          else
            data_wr <= X"8C";
          end if;

    		when 8 =>
          if (Cont < X"00001D") then
            data_wr <= X"08";
          else
            data_wr <= X"0C";
          end if;

    		when 9 =>
          if (Cont < X"00001D") then
            data_wr <= X"18";
          else
            data_wr <= X"1C";
          end if;

    		when 10 =>
          if (Cont < X"00001D") then
            data_wr <= X"08";
          else
            data_wr <= X"0C";
          end if;

    		when 11 =>
          if (Cont < X"00001D") then
            data_wr <= X"38";
          else
            data_wr <= X"3C";
          end if;

        ---------------------------end initialization-----------------------------

        ------------------------Begin lcd data write------------------------------
        when 12 =>
          if (Cont < X"00001D") then
            data_wr <= X"59";
          else
            data_wr <= X"5D";
          end if;
            -- T upper 4 bits
          -- if (source = "00") then
          --
          -- elsif (source = "01") then
          -- elsif (source = "10") then
          --
          -- end if;
        when 13 =>
          if (Cont < X"00001D") then
            data_wr <= X"49";
          else
            data_wr <= X"4D";
          end if;
           -- T lower 4 bits
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
        ---------------------------End lcd data write-----------------------------
    		when others =>
        -- data_wr <= X"76";
    	end case;
    end if;
  end process;

end Behavioral;
