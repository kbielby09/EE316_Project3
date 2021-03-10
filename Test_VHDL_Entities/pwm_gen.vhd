----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/09/2021 09:18:46 PM
-- Design Name:
-- Module Name: pwm_gen - Behavioral
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

entity pwm_gen is
  Port (
    I_CLK_50MHZ : in std_logic;
    I_RESET  : in std_logic;
    DATA_IN : in std_logic_vector(7 downto 0);
    PWM_OUT : out std_logic
  );
end pwm_gen;

architecture Behavioral of pwm_gen is

  signal pwm_count : unsigned(7 downto 0);

begin

  PWM_COUNTER : process(I_CLK_50MHZ, I_RESET)
  begin
    if (I_RESET = '1') then
      pwm_count <= (others => '0');
    elsif (rising_edge(I_CLK_50MHZ)) then
      pwm_count <= pwm_count + 1;

      if (pwm_count = unsigned(DATA_IN)) then -- check if pwm count
        PWM_OUT <= '1';
      elsif (pwm_count = X"FF") then          -- check if max count
        pwm_count <= (others => '0');
        PWM_OUT <= '0';
      end if;
    end if;
  end process PWM_COUNTER;


end Behavioral;
