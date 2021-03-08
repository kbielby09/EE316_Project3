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
   Generation : in std_logic := '1';
   source : in std_logic_vector(1 downto 0) := "00"
);
end I2C_LCD_driver;

architecture Behavioral of I2C_LCD_driver is

  component i2c_master is
  GENERIC(
      input_clk : INTEGER := 125_000_000;
      bus_clk   : INTEGER := 100_000);
    PORT(
      clk       : IN     STD_LOGIC;
      reset_n   : IN     STD_LOGIC;
      ena       : IN     STD_LOGIC;
      addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0);
      rw        : IN     STD_LOGIC;
      data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0);
      busy      : OUT    STD_LOGIC;
      data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0);
      ack_error : BUFFER STD_LOGIC;
      sda       : INOUT  STD_LOGIC;
      scl       : INOUT  STD_LOGIC);
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
  signal reset_p : std_logic := not(I_RESET_N);
  signal initial_wait_done : std_logic := '0';
  signal lcd_initialized : std_logic := '0';
  signal previous_source : std_logic_vector(2 downto 0);
  signal previous_generation : std_logic := '0';
  signal active_byte : std_logic_vector(3 downto 0);

begin

  inst_master : i2c_master
  generic map(
    input_clk => 125_000_000,
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


  COMMAND_COUNT : process(I_CLK_125MHZ)
  begin
    if (I_RESET_N = '1') then
      Cont <=  X"000000";
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
    end if;
  end process;

  FIRST_WAIT : process(I_RESET_N, I_CLK_125MHZ)
  begin
    if (I_RESET_N = '1') then
      initial_wait_done <= '0';
    elsif (rising_edge(I_CLK_125MHZ)) then
      if (initial_wait_done = '0' and Cont = X"1C9C38") then
        initial_wait_done <= '1';
      end if;
    end if;
  end process;

  process(I_CLK_125MHZ)
  begin
  if(rising_edge(I_CLK_125MHZ)) then
    if (initial_wait_done = '1') then
      prevBusy <= sigBusy;
      previous_generation <= Generation;
      previous_source <= source;

      if (previous_generation /= Generation
          or previous_source /= source) then
        byteSel <= 1;
      end if;

    	case state is
    		when start =>
          if (byteSel < 163) then
            if (prevBusy = '1' and sigBusy = '0') then
              i2c_ena <= '0';
              state <= write_data;
            else
              i2c_ena <= '1';
            end if;
          end if;

    		when write_data =>
          if (byteSel < 163) then
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

  WRTIE_BYTE : process(I_CLK_125MHZ, I_RESET_N)
  begin
    if (rising_edge(I_CLK_125MHZ)) then
      if (byteSel mod 3 = 1) then
        if (lcd_initialized = '0'
          or byteSel = 61
          or byteSel = 63
          or byteSel = 64
          or byteSel = 66) then
          data_wr <= active_byte & X"8";
        else
          data_wr <= active_byte & X"9";
        end if;
      elsif (byteSel mod 3 = 2) then
        if (lcd_initialized = '0'
          or byteSel = 62
          or byteSel = 65) then
          data_wr <= active_byte & X"C";
        else
          data_wr <= active_byte & X"D";
        end if;
      elsif (byteSel mod 3 = 0) then
        if (lcd_initialized = '0'
          or byteSel = 61
          or byteSel = 63
          or byteSel = 64
          or byteSel = 66) then
          data_wr <= active_byte & X"8";
        else
          data_wr <= active_byte & X"9";
        end if;
      end if;
    end if;
  end process;

  SELECT_BYTE : process(I_CLK_125MHZ, I_RESET_N)
  begin
    if (I_RESET_N = '1') then
    elsif (rising_edge(I_CLK_125MHZ)) then
      case( byteSel ) is
        when 1 =>
          active_byte <= X"3";
        when 4 =>
          active_byte <= X"3";
        when 7 =>
          active_byte <= X"3";
        when 10 =>
          active_byte <= X"2";
        when 13 =>
          active_byte <= X"2";
        when 16 =>
          active_byte <= X"C";
        when 19 =>
          active_byte <= X"0";
        when 22 =>
          active_byte <= X"8";
        when 25 =>
          active_byte <= X"0";
        when 28 =>
          active_byte <= X"1";
        when 31 =>
          active_byte <= X"0";
        when 34 =>
          active_byte <= X"3";
        when 37 =>
          active_byte <= X"0";
        when 40 =>
          active_byte <= x"F";
        when 42 =>
          lcd_initialized <= '1';
        when 43 =>
          if (source = "00") then
            active_byte <= X"4";  -- L upper nibble
          elsif (source = "01") then
            active_byte <= X"5";  -- T upper nibble
          elsif (source = "10") then
            active_byte <= X"4";  -- A upper nibble
          elsif (source ="11") then
            active_byte <= X"5";  -- P upper nibble
          end if;
        when 46 =>
          if (source = "00") then
            active_byte <= X"C"; -- L lower nibble
          elsif (source = "01") then
            active_byte <= X"4"; -- T lower nibble
          elsif (source = "10") then
            active_byte <= X"1"; -- A lower nibble
          elsif (source ="11") then
            active_byte <= X"0"; -- P lower nibble
          end if;
        when 49 =>
          if (source = "00") then
            active_byte <= X"4";  -- D upper nibble
          elsif (source = "01") then
            active_byte <= X"4";  -- M upper nibble
          elsif (source = "10") then
            active_byte <= X"4";  -- N upper nibble
          elsif (source ="11") then
            active_byte <= X"4";  -- O upper nibble
          end if;
        when 52 =>
          if (source = "00") then
            active_byte <= X"4";  -- D lower nibble
          elsif (source = "01") then
            active_byte <= X"D";  -- M lower nibble
          elsif (source = "10") then
            active_byte <= X"E";  -- N lower nibble
          elsif (source ="11") then
            active_byte <= X"F";  -- O lower nibble
          end if;
        when 55 =>
          if (source = "00") then
            active_byte <= X"5";  -- R upper nibble
          elsif (source = "01") then
            active_byte <= X"5";  -- P upper nibble
          elsif (source = "10") then
            active_byte <= X"4";  -- A upper nibble
          elsif (source ="11") then
            active_byte <= X"5";  -- T upper nibble
          end if;
        when 58 =>
          if (source = "00") then
            active_byte <= X"2";  -- R lower nibble
          elsif (source = "01") then
            active_byte <= X"0";  -- P lower nibble
          elsif (source = "10") then
            active_byte <= X"1";  -- A lower nibble
          elsif (source ="11") then
            active_byte <= X"4";  -- T lower nibble
          end if;
        when 61 =>
          active_byte <= X"C"; -- Change line upper nibble
        when 64 =>
          active_byte <= X"0"; -- Change line lower nibble
        when 67 =>
          active_byte <= X"4"; -- C upper nibble
        when 70 =>
          active_byte <= X"3"; -- C lower nibble
        when 73 =>
          active_byte <= X"6"; -- l upper nibble
        when 76 =>
          active_byte <= X"C"; -- l lower nibble
        when 79 =>
          active_byte <= X"6"; -- o upper nibble
        when 82 =>
          active_byte <= X"F"; -- o lower nibble
        when 85 =>
          active_byte <= X"6"; -- c upper nibble
        when 88 =>
          active_byte <= X"3"; -- c lower nibble
        when 91 =>
          active_byte <= X"6"; -- k upper nibble
        when 94 =>
          active_byte <= X"B"; -- k lower nibble
        when 97 =>
          active_byte <= X"2"; -- <Space> upper nibble
        when 100 =>
          active_byte <= X"0"; -- <Space> lower nibble
        when 103 =>
          active_byte <= X"4"; -- O upper nibble
        when 106 =>
          active_byte <= X"F"; -- O lower nibble
        when 109 =>
          active_byte <= X"7"; -- u upper nibble
        when 112 =>
          active_byte <= X"5"; -- u lower nibble
        when 115 =>
          active_byte <= X"7"; -- t upper nibble
        when 118 =>
          active_byte <= X"4"; -- t lower nibble
        when 121 =>
          active_byte <= X"7"; -- p upper nibble
        when 124 =>
          active_byte <= X"0"; -- p lower nibble
        when 127 =>
          active_byte <= X"7"; -- u upper nibble
        when 130 =>
          active_byte <= X"5"; -- u lower nibble
        when 133 =>
          active_byte <= X"7"; -- t upper nibble
        when 136 =>
          active_byte <= X"4"; -- t lower nibble
        when 139 =>
          active_byte <= X"3"; -- : upper nibble
        when 142 =>
          active_byte <= X"A"; -- : lower nibble
        when 145 =>
          active_byte <= X"4"; -- O upper nibble
        when 147 =>
          active_byte <= X"F"; -- O upper nibble
        when 151 =>
          if (Generation = '1') then
            active_byte <= X"6";        -- n upper nibble
          elsif (Generation = '0') then
            active_byte <= X"6";        -- f upper nibble
          end if;
        when 154 =>
          if (Generation = '1') then
            active_byte <= X"E";        -- n lower nibble
          elsif (Generation = '0') then
            active_byte <= X"6";        -- f lower nibble
          end if;
        when 157 =>
          if (Generation = '1') then
            active_byte <= X"2"; -- <Space> upper nibble
          elsif (Generation = '0') then
            active_byte <= X"6";        -- f upper nibble
          end if;
        when 160 =>
          if (Generation = '1') then
            active_byte <= X"0";      -- <Space> lower nibble
          elsif (Generation = '0') then
            active_byte <= X"6";        -- f lower nibble
          end if;

        when others =>
          -- DO NOTHING
      end case;
    end if;
  end process;

end Behavioral;
