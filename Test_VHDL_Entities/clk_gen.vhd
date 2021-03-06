----------------------------------------------------------------------------------
-- Filename: clk_gen.vhd
-- Authors: Chandler Kent and Kyle Bielby
-- Date Created: 2/28/21
-- Last Modified: 3/10/21
-- Description: Clock generation code
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_gen is
  port (
    I_CLK_125MHz 	: in std_logic;
    I_RESET_N   	: in std_logic;
    On_off      	: in std_logic;
    Data_in     	: in std_logic_vector(7 downto 0) := X"4D";
    Clock_out   	: out std_logic
  );
end clk_gen;

architecture archclk_gen of clk_gen is

  signal cnt_out 		: unsigned(19 downto 0) := (others => '0');
  signal counter 		: integer;
  signal increment 		: integer := 327; -- (delta 2 - delta 1) / 255
  signal delta_1 		: integer := 125000; -- delta 1 constant: ( .5 * ( 1/1500 ) ) / sys_period
  signal clock_toggler 	: std_logic := '0';

begin

  -- KAB not sure how to use what you have for processes so this is what I made
  KAB_COUNTER : process(I_CLK_125MHZ, I_RESET_N)
  begin
   if (rising_edge(I_CLK_125MHZ)) then
     if (On_off = '1') then
       counter <= (delta_1 + increment * to_integer(unsigned(Data_in))) / 2;  -- KAB get the value counted to
       cnt_out <= cnt_out + 1;
        if (cnt_out = to_unsigned(counter, 20)) then  -- KAB this comes from numeric_std library reference: nandland.com
         clock_toggler <= not(clock_toggler);  -- toggle clock output
         cnt_out <= (others => '0');
        end if;
     end if;
    end if;
  end process;

  Clock_out <= clock_toggler;

end archclk_gen;
