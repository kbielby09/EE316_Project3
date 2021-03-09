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

   BTN1 : in std_logic;
   LCD_SDA : inout std_logic;
   LCD_SCL : inout std_logic
   -- ADC_SDA : inout std_logic;
   -- ADC_SCL : inout std_logic
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

  type MODE is (PWM, CLOCK);
  signal generation_state : MODE := PWM;

  signal previous_button1_value : std_logic := '0';

  signal pwm_enable : std_logic := '1';
  signal clock_enable : std_logic := '0';
  signal adc_source : std_logic_vector(1 downto 0) := "00";

begin

  LCD : I2C_LCD_driver
  port map(
  I_RESET_N    => I_RESET,
  I_CLK_125MHZ => I_CLK_125MHZ,
  SDA          => LCD_SDA,
  SCL          => LCD_SCL,  -- TODO add comma after created
  Generation   => clock_enable,
  source       => adc_source
  );

  SOURCE_SEL : process(I_CLK_125MHZ, I_RESET)
  begin
    if (I_RESET = '1') then
    elsif (rising_edge(I_CLK_125MHZ)) then
      previous_button1_value <= BTN1;
      case(generation_state) is
        when PWM =>
          if (previous_button1_value = '0' and BTN1 = '1') then
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
        when CLOCK =>
          if (previous_button1_value = '0' and BTN1 = '1') then
            clock_enable <= not(clock_enable);
          end if;
      end case;
    end if;
  end process;

end Behavioral;
