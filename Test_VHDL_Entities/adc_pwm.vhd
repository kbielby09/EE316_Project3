----------------------------------------------------------------------------------
-- Company: Clarkson University
-- Engineer: Camilla Ketola
-- 
-- Create Date: 03/07/2021 05:01:26 PM
-- Design Name: 
-- Module Name: adc_pwm - Behavioral
-- Project Name: EE316 Project 3
-- Target Devices: Cora-z7 10
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: none
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: Creates a pwm output for each of the four souces os the adc
-- 
----------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.std_logic_unsigned.all;
	
------------
---Entity---
------------

entity adc_pwm is
	generic(
		  clk_freq	: integer := 125; --the 125MHz input clock
		  data_res	: integer := 8	  --the data resolution
	);

	port(
		  pwm_clk				: in std_logic;							--pwm clock
		  pwm_rst				: in std_logic;							--reset (active low)
		  pwm_en				: in std_logic;							--pwm enable
		  pwm_datain	    : in std_logic_vector((data_res - 1) downto 0);	--input data for pwm generator
		  pwm_out	        : out std_logic 							--the output signal
		  );

end entity adc_pwm;

---------------
---Behaviour---
---------------

architecture rtl of adc_pwm is

-------------
---Signals---
-------------

	signal count : integer:= 0;

begin

---------------
---Processes---
---------------

process(pwm_clk, pwm_rst) begin

	if(pwm_en = '1') then          --pwm only operates when enabled
		if(pwm_rst = '0') then        --asynchronous reset
			pwm_out <= '0';
			count <= 0;

		elsif(pwm_clk'event and pwm_clk = '1') then

			if (count < (2 ** data_res)) then	--when count is less than counter
				count <= count + 1;		--increments counter
			else
				count <= 0;				--resets counter
			end if;

			if(count < to_integer(unsigned(pwm_datain))) then	--stays on for duty cycle
				pwm_out <= '1';
			else
				pwm_out <= '0';
			end if;
		end if;
	else
		pwm_out <= '0';
	end if;

	end process;

end rtl;
