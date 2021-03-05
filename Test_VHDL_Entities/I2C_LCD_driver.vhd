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
   SCL : inout std_logic

   -- Data
   -- Generation : in std_logic;
   -- source : in std_logic_vector(2 downto 0)
);
end I2C_LCD_driver;

architecture Behavioral of I2C_LCD_driver is

  -- component ila_0 is
  --   port(
  --   clk : in std_logic;
  --   probe0 : in std_logic_vector(19 downto 0);
  --   probe1 : in std_logic_vector(7 downto 0);
  --   probe2 : in std_logic;
  --   probe3 : in std_logic_vector(20 downto 0)
  --   );
  --
  -- end component;

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
      INIT10,
      INIT11,
      INIT12,
      INIT13,
      INIT14
  );

  signal lcd_init_state : INIT_STATE := INIT0;

  signal i2c_addr : std_logic_vector(7 downto 0) := X"27";
  signal prevBusy, sigBusy, reset_n, i2c_ena, ack_err : std_logic;
  signal data_wr: std_logic_vector(7 downto 0);
  signal byteSel : integer := 1;
  signal regData: std_logic_vector(15 downto 0);
  signal refresh : std_logic := '0';
  signal reset_p : std_logic := not(I_RESET_N);
  signal initial_wait_done : std_logic := '0';
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
  	rw => '0',
  	data_wr => data_wr,
  	busy => sigBusy,
  	data_rd => OPEN,
  	ack_error => ack_err,
  	sda => SDA,
  	scl => SCL
  );

  -- ILA : ila_0
  -- port map(
  --   clk => I_CLK_125MHZ,
  --   probe0 => std_logic_vector(Cont(19 downto 0)),
  --   probe1 => data_wr,
  --   probe2 => i2c_ena,
  --   probe3 => std_logic_vector(to_unsigned(byteSeL, 21))
  -- );


  COMMAND_COUNT : process(I_CLK_125MHZ)
  begin
    if (I_RESET_N = '1') then
      -- byteSeL <= 0;
      -- Cont <=  X"000000";
    elsif (rising_edge(I_CLK_125MHZ)) then
      if (initial_wait_done = '0') then
        if (Cont < X"1C9C38") then
          Cont <= Cont + 1;
        else
          Cont <= (others => '0');
        end if;

      elsif (state = write_data) then

        if (Cont < X"07D1F5") then
          Cont <= Cont + 1;
        else
          Cont <= (others => '0');
        end if;
      end if;

      -- if (Cont = X"02EB13" and lcd_initialized = '1') then
        -- if (state = write_data and byteSeL < 12) then
        --   byteSeL <= byteSeL + 1;
        -- elsif (state = write_data and byteSeL > 12 and byteSeL < 14) then
        --   if (prevBusy/=sigBusy and sigBusy='0') then
        --     byteSeL <= byteSeL + 1;
        --   end if;
        -- -- else
        -- --   byteSeL <= 12;
        -- end if;
        -- Cont <= X"000000";
      -- end if;
    end if;
  end process;

  FIRST_WAIT : process(I_RESET_N, I_CLK_125MHZ)
  begin
    if (I_RESET_N = '1') then
      -- initial_wait_done <= '0';
    elsif (rising_edge(I_CLK_125MHZ)) then
      if (initial_wait_done = '0' and Cont = X"1C9C38") then
        initial_wait_done <= '1';
      end if;
    end if;
  end process;

  -- I2C_STATE : process(I_CLK_125MHZ, I_RESET_N)
  -- begin
  --   if (I_RESET_N = '1') then
  --     state <= start;
  --   elsif (rising_edge(I_CLK_125MHZ)) then
  --     case(state) is
  --       when start =>
  --         if (sigBusy = '0') then
  --           state <= write_data;
  --         end if;
  --       when write_data =>
  --         -- if (sigBusy = '1') then
  --         --   state <= repeat;
  --         -- end if;
  --         if (byteSel < 37) then
  --           state <= repeat;
  --         end if;
  --       when repeat =>
  --         -- if ((Cont = X"02EB13" or Cont = X"00001D")
  --         --   and lcd_init_state /= INIT0
  --         --   and lcd_init_state /= INIT2
  --         --   and lcd_init_state /= INIT4) then
  --         if (initial_wait_done = '1') then
  --           state <= start;
  --         end if;
  --     end case;
  --   end if;
  -- end process I2C_STATE;


  -- I2C_SIG_SET : process(I_CLK_125MHZ, I_RESET_N)
  -- begin
  --   if (I_RESET_N = '1') then
  --     i2c_ena <= '0';
  --   elsif (rising_edge(I_CLK_125MHZ)) then
  --
  --     if (initial_wait_done = '1') then
  --       case( state ) is
  --         when start =>
  --           if (sigBusy = '0') then
  --             if (byteSel < 37) then -- TODO remove after test
  --               i2c_ena <= '1'; -- set enable to 1
  --               byteSel <= byteSel + 1;
  --             end if;
  --
  --           end if;
  --         when write_data =>
  --           if (sigBusy = '1') then
  --             i2c_ena <= '0';
  --           end if;
  --         when repeat =>
  --           -- no signals to control in this state
  --       end case;
  --     end if;
  --   end if;
  -- end process;

  -- process(I_CLK_125MHZ)
  -- begin
  -- if(rising_edge(I_CLK_125MHZ)) then
  --   if (initial_wait_done = '1') then
  --     prevBusy <= sigBusy;
  --   	case state is
  --   		when start =>
  --           if (byteSel < 43) then
  --             i2c_ena <= '1';
  --           else
  --             i2c_ena <= '0';
  --           end if;
  --   				state <= write_data;
  --   		when write_data =>
  --         if byteSel < 43 then
  --
  --           if (Cont < X"02EB13") then  -- wait for 1.53ms
  --             i2c_ena <= '0';
  --             state <= write_data;
  --           else
  --             if prevBusy = '1' and sigBusy = '0' then
  --               byteSel <= byteSel + 1;
  --             end if;
  --             i2c_ena <= '1';
  --             state <= write_data;
  --           end if;
  --         else
  --           i2c_ena <= '0';
  --           state <= repeat;
  --         end if;
  --
  --   		when repeat => -- wait for new data
  --   			i2c_ena <= '0';
  --   				state <= start;
  --   		end case;
  --   end if;
  -- end if;
  -- end process;


  process(I_CLK_125MHZ)
  begin
  if(rising_edge(I_CLK_125MHZ)) then
    if (initial_wait_done = '1') then
      prevBusy <= sigBusy;
    	case state is
    		when start =>
          if (byteSel < 43) then
            if (prevBusy = '1' and sigBusy = '0') then
              i2c_ena <= '0';
              state <= write_data;
            else
              i2c_ena <= '1';
            end if;
          end if;

    		when write_data =>
          if byteSel < 43 then
            if (Cont = X"07D1F5") then  -- wait for 1.53ms
              byteSel <= byteSel + 1;
              state <= start;
            end if;
          end if;

    		when repeat => -- wait for new data
          -- DO NOTHING
    		end case;
    end if;
  end if;
  end process;

  -- INTI_STATE : process(I_CLK_125MHZ, I_RESET_N)
  -- begin
  --   if (I_RESET_N = '1') then
  --     lcd_init_state <= INIT0;
  --   elsif (rising_edge(I_CLK_125MHZ)) then
  --     case( lcd_init_state ) is
  --       when INIT0 =>
  --         if (initial_wait_done = '1') then
  --           lcd_init_state <= INIT1;
  --         end if;
  --       when INIT1 =>
  --         if (Cont = X"02EB13") then
  --           lcd_init_state <= INIT2;
  --         end if;
  --       when INIT2 =>
  --         if (Cont = X"07D1F4") then
  --           lcd_init_state <= INIT3;
  --         end if;
  --       when INIT3 =>
  --         if (Cont = X"02EB13") then
  --           lcd_init_state <= INIT4;
  --         end if;
  --       when INIT4 =>
  --         if (Cont = X"0030D4") then
  --           lcd_init_state <= INIT5;
  --         end if;
  --       when INIT5 =>
  --         if (Cont = X"02EB13") then
  --           lcd_init_state <= INIT6;
  --         end if;
  --       when INIT6 =>
  --         if (Cont = X"02EB13") then
  --           lcd_init_state <= INIT7;
  --         end if;
  --       when INIT7 =>
  --         if (Cont = X"02EB13") then
  --           lcd_init_state <= INIT8;
  --         end if;
  --       when INIT8 =>
  --         if (Cont = X"02EB13") then
  --           lcd_init_state <= INIT9;
  --         end if;
  --       when INIT9 =>
  --         if (Cont = X"02EB13") then
  --           lcd_init_state <= INIT10;
  --         end if;
  --       when INIT10 =>
  --         if (Cont = X"02EB13") then
  --           lcd_init_state <= INIT11;
  --         end if;
  --       when INIT11 =>
  --         if (Cont = X"02EB13") then
  --           lcd_init_state <= INIT12;
  --         end if;
  --       when INIT12 =>
  --         if (Cont = X"02EB13") then
  --           lcd_init_state <= INIT13;
  --         end if;
  --       when INIT13 =>
  --         if (Cont = X"02EB13") then
  --           lcd_init_state <= INIT14;
  --         end if;
  --       when INIT14 =>
  --         if (Cont = X"02EB13") then
  --           lcd_initialized <= '1';
  --         end if;
  --       when others =>
  --        -- DO NOTHING
  --     end case;
  --   end if;
  --
  -- end process;

  -- INIT_BYTES : process(I_CLK_125MHZ, I_RESET_N)
  -- begin
  --   if (I_RESET_N = '1') then
  --    -- do stuff
  --  elsif (rising_edge(I_CLK_125MHZ)) then
  --     if (lcd_initialized = '0') then
  --       case( lcd_init_state ) is
  --         when INIT0 =>
  --           -- wait for 15ms
  --         when INIT1 =>
  --           -- if (Cont < X"00001D") then
  --           --   data_wr <= X"38";
  --           -- else
  --           --   data_wr <= X"3C";
  --           -- end if;
  --           if (Cont < X"01757B") then
  --             data_wr <= X"38";
  --           elsif (Cont > X"1757B" and Cont < X"17598") then
  --             data_wr <= X"3C";
  --           elsif (Cont < X"01757B") then
  --             data_wr <= X"38";
  --           end if;
  --         when INIT2 =>
  --           -- wait for 4.1ms
  --         when INIT3 =>
  --           if (Cont < X"01757B") then
  --             data_wr <= X"38";
  --           elsif (Cont > X"1757B" and Cont < X"17598") then
  --             data_wr <= X"3C";
  --           elsif (Cont < X"01757B") then
  --             data_wr <= X"38";
  --           end if;
  --         when INIT4 =>
  --           -- wait for 100 microsecs
  --         when INIT5 =>
  --           -- if (Cont < X"00001D") then
  --           --   data_wr <= X"38";
  --           -- else
  --           --   data_wr <= X"3C";
  --           -- end if;
  --           if (Cont < X"01757B") then
  --             data_wr <= X"38";
  --           elsif (Cont > X"1757B" and Cont < X"17598") then
  --             data_wr <= X"3C";
  --           elsif (Cont < X"01757B") then
  --             data_wr <= X"38";
  --           end if;
  --         when INIT6 =>
  --           -- if (Cont < X"00001D") then
  --           --   data_wr <= X"28";
  --           -- else
  --           --   data_wr <= X"2C";
  --           -- end if;
  --           if (Cont < X"01757B") then
  --             data_wr <= X"28";
  --           elsif (Cont > X"1757B" and Cont < X"17598") then
  --             data_wr <= X"2C";
  --           elsif (Cont < X"01757B") then
  --             data_wr <= X"28";
  --           end if;
  --         when INIT7 =>
  --           -- if (Cont < X"00001D") then
  --           --   data_wr <= X"28";
  --           -- else
  --           --   data_wr <= X"2C";
  --           -- end if;
  --           if (Cont < X"01757B") then
  --             data_wr <= X"28";
  --           elsif (Cont > X"1757B" and Cont < X"17598") then
  --             data_wr <= X"2C";
  --           elsif (Cont < X"01757B") then
  --             data_wr <= X"28";
  --           end if;
  --         when INIT8 =>
  --           if (Cont < X"00001D") then
  --             data_wr <= X"C8";
  --           else
  --             data_wr <= X"CC";
  --           end if;
  --         when INIT9 =>
  --           if (Cont < X"00001D") then
  --             data_wr <= X"08";
  --           else
  --             data_wr <= X"0C";
  --           end if;
  --         when INIT10 =>
  --           if (Cont < X"00001D") then
  --             data_wr <= X"88";
  --           else
  --             data_wr <= X"8C";
  --           end if;
  --         when INIT11 =>
  --           if (Cont < X"00001D") then
  --             data_wr <= X"08";
  --           else
  --             data_wr <= X"0C";
  --           end if;
  --         when INIT12 =>
  --           if (Cont < X"00001D") then
  --             data_wr <= X"18";
  --           else
  --             data_wr <= X"1C";
  --           end if;
  --         when INIT13 =>
  --           if (Cont < X"00001D") then
  --             data_wr <= X"08";
  --           else
  --             data_wr <= X"0C";
  --           end if;
  --         when INIT14 =>
  --           if (Cont < X"00001D") then
  --             data_wr <= X"38";
  --           else
  --             data_wr <= X"3C";
  --           end if;
  --         when others =>
  --           -- DO NOTHING
  --       end case;
  --     end if;
  --   end if;
  -- end process;

  INIT_BYTE_COUNT : process(I_CLK_125MHZ, I_RESET_N)
  begin
    if (I_RESET_N = '1') then
    elsif (rising_edge(I_CLK_125MHZ)) then
      case( byteSel ) is
        when 1 =>
          data_wr <= X"38";
        when 2 =>
          data_wr <= X"3C";
        when 3 =>
          data_wr <= X"38";
        when 4 =>
          data_wr <= X"38";
        when 5 =>
          data_wr <= X"3C";
        when 6 =>
          data_wr <= X"38";
        when 7 =>
          data_wr <= X"38";
        when 8 =>
          data_wr <= X"3C";
        when 9 =>
          data_wr <= X"38";
        when 10 =>
          data_wr <= X"28";
        when 11 =>
          data_wr <= X"2C";
        when 12 =>
          data_wr <= X"28";
        when 13 =>
          data_wr <= X"28";
        when 14 =>
          data_wr <= X"2C";
        when 15 =>
          data_wr <= X"28";
        when 16 =>
          data_wr <= X"C8";
        when 17 =>
          data_wr <= X"CC";
        when 18 =>
          data_wr <= X"C8";
        when 19 =>
          data_wr <= X"08";
        when 20 =>
          data_wr <= X"0C";
        when 21 =>
          data_wr <= X"08";
        when 22 =>
          data_wr <= X"88";
        when 23 =>
          data_wr <= X"8C";
        when 24 =>
          data_wr <= X"88";
        when 25 =>
          data_wr <= X"08";
        when 26 =>
          data_wr <= X"0C";
        when 27 =>
          data_wr <= X"08";
        when 28 =>
          data_wr <= X"18";
        when 29 =>
          data_wr <= X"1C";
        when 30 =>
          data_wr <= X"18";
        when 31 =>
          data_wr <= X"08";
        when 32 =>
          data_wr <= X"0C";
        when 33 =>
          data_wr <= X"08";
        when 34 =>
          data_wr <= X"38";
        when 35 =>
          data_wr <= X"3C";
        when 36 =>
          data_wr <= X"38";
        when 37 =>
          data_wr <= X"59";
        when 38 =>
          data_wr <= X"5D";
        when 39 =>
          data_wr <= X"59";
        when 40 =>
          data_wr <= X"49";
        when 41 =>
          data_wr <= X"4D";
        when 42 =>
          data_wr <= X"49";
        when others =>
          -- DO NOTHING
      end case;
    end if;
  end process;

end Behavioral;
