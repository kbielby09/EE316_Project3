----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/05/2021 04:20:24 PM
-- Design Name:
-- Module Name: i2c_adc_top - Behavioral
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

entity i2c_adc_top is
 Port (
   I_CLK_125MHZ : in std_logic;
   I_RESET : in std_logic;
   I_LCD : out std_logic_vector(1 downto 0);

   BTN1 : in std_logic;
   PWM_OUT : out std_logic;
   Clock_out   : out std_logic;
   LCD_SDA : inout std_logic;
   LCD_SCL : inout std_logic;
   ADC_SDA : inout std_logic;
   ADC_SCL : inout std_logic
 );
end i2c_adc_top;

architecture Behavioral of i2c_adc_top is

  component I2C_LCD_driver is
  Port (
    I_RESET_N   : in std_logic;
    I_CLK_125MHZ : in std_logic;
    SDA : inout std_logic;
    SCL : inout std_logic;
    -- Data
    Generation : in std_logic;
    source : in std_logic_vector(1 downto 0)
  );
  end component I2C_LCD_driver;

  type control_state is (source1, source2, source3, source4, clockOff);
  signal control_sig : control_state;

  component kb_adc_driver is
   Port (
     I_CLK_125MHZ : in std_logic;
     I_RESET : in std_logic;

     source : in std_logic_vector(1 downto 0);
     data_out : out std_logic_vector(7 downto 0); -- TODO implement for data output
     data_ready : out std_logic;
     ADC_SCL : inout std_logic;
     ADC_SDA : inout std_logic
   );
 end component kb_adc_driver;

 component pwm_gen is
   Port (
     I_CLK_50MHZ : in std_logic;
     I_RESET  : in std_logic;
     DATA_IN : in std_logic_vector(7 downto 0);
     PWM_OUT : out std_logic
   );
 end component pwm_gen;

 component clk_gen is
   port (
     I_CLK_125MHz : in std_logic;
     I_RESET_N   : in std_logic;
     On_off      : in std_logic;
     Data_in     : in std_logic_vector(7 downto 0) := X"4D";
     Clock_out   : out std_logic
   );
 end component clk_gen;

  type MODE is (PWM, CLOCK);
  signal generation_state : MODE := PWM;

  signal previous_button1_value : std_logic := '0';

  signal pwm_enable : std_logic := '1';
  signal clock_enable : std_logic := '0';
  signal adc_source : std_logic_vector(1 downto 0) := "00";
  signal adc_data : std_logic_vector(7 downto 0);
  signal data_out : std_logic_vector(7 downto 0);
  signal data_ready : std_logic;
  signal previous_data_ready : std_logic;

begin

  LCD : I2C_LCD_driver
  port map(
  I_RESET_N    => I_RESET,
  I_CLK_125MHZ => I_CLK_125MHZ,
  SDA          => LCD_SDA,
  SCL          => LCD_SCL,
  Generation   => clock_enable,
  source       => adc_source
  );

  ADC : kb_adc_driver
  port map(
    I_CLK_125MHZ => I_CLK_125MHZ,
    I_RESET => I_RESET,
    source => adc_source,
    data_out => data_out,
    data_ready => data_ready,
    ADC_SCL => ADC_SCL,
    ADC_SDA => ADC_SDA
  );

  PWM_INST : pwm_gen
  port map(
    I_CLK_50MHZ => I_CLK_125MHZ,
    I_RESET => I_RESET,
    DATA_IN => adc_data,
    PWM_OUT => PWM_OUT
  );

  CLOCK_INST : clk_gen
  port map(
    I_CLK_125MHz => I_CLK_125MHZ,
    I_RESET_N    => I_RESET,
    On_off       => clock_enable,
    Data_in      => adc_data,
    Clock_out    => Clock_out
  );

  REG_DATA : process(I_CLK_125MHZ, I_RESET)
  begin
    if (rising_edge(I_CLK_125MHZ)) then
      previous_data_ready <= data_ready;
      if (previous_data_ready = '0' and data_ready = '1') then
        adc_data <= data_out;
      end if;
    end if;
  end process;

  CLOCK_TOGGLE : process(I_CLK_125MHZ, I_RESET)
  begin
    if (rising_edge(I_CLK_125MHZ)) then
      if (previous_button1_value = '0' and BTN1 = '1') then
        clock_enable <= not(clock_enable);
      end if;
    end if;
  end process;

  BTN_PRESS : process(I_CLK_125MHZ)
  begin
    if (rising_edge(I_CLK_125MHZ)) then
      previous_button1_value <= BTN1;
    end if;
  end process;

  SOURCE_SEL : process(I_CLK_125MHZ, I_RESET)
  begin
    if (rising_edge(I_CLK_125MHZ)) then

      case(generation_state) is
        when PWM =>
          if (previous_button1_value = '0' and BTN1 = '1') then
            -- case( control_sig ) is
            --
            --   when source1 =>
            --     control_sig <= source2;
            --     adc_source <= "01";
            --   when IDLE =>
            --   when IDLE =>
            --   when IDLE =>
            --   when IDLE =>

            -- end case;
            case(adc_source) is
              when "00" =>
                adc_source <= "01";  -- Change input to LDR
              when "01" =>
                adc_source <= "10"; -- Change input to TEMP
              when "10" =>
                adc_source <= "11"; -- Change input to POT
              when "11" =>
                adc_source <= "00"; -- Change to LDR
            end case;
          end if;
          -- generation_state <= PWM;
        when CLOCK =>
          -- if (previous_button1_value = '0' and BTN1 = '1') then
          --   clock_enable <= not(clock_enable);
          -- end if;
          generation_state <= PWM; -- TODO remove after
      end case;
    end if;
  end process;

  I_LCD <= adc_source;

end Behavioral;
