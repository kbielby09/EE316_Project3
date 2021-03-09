----------------------------------------------------------------------------------
-- Filename: clk_gen.vhd
-- Author: Chandler Kent
-- Date Created: 2/28/21
-- Last Modified: 3/8/21
-- Description: Clock generation code
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

entity clk_gen is
  port (
    I_CLK_125MHz : in std_logic;
    I_RESET_N    : in std_logic;
    Data_in      : in std_logic_vector(7 downto 0);
    Clock_out    : out std_logic
  );
end clk_gen;

architecture archclk_gen of clk_gen is

  signal eightBitCounter : unsigned(15 downto 0) := (others => '0');
  signal cnt_out : unsigned(15 downto 0) := (others => '0');
  signal cnt_in : unsigned(15 downto 0) := (others => '0');
  signal add_out : unsigned(15 downto 0) := (others => '0');
  signal reg_out : unsigned(15 downto 0) := (others => '0');
  signal comp_out : std_logic := '0';
  signal mux1_out : unsigned(15 downto 0) := (others => '0');
  signal mux2_out : integer; --unsigned(15 downto 0) := (others => '0');
  signal new_data : integer; --unsigned(15 downto 0) := (others => '0');
  signal tmp_a : unsigned(7 downto 0) := (others => '0');
  signal tmp_b : unsigned(15 downto 0) := (others => '0');
  --signal delta_1 : integer;   -- not sure if this is the data type we want
  --signal delta_2 : integer;	-- ^
  signal delta : integer;		-- ^
  
begin

	--changing 0-255 to 500 - 1500
	--tmp_a <= "11111111" - Data_in;
	--VHDL integers round down (https://www.nandland.com/vhdl/tips/tip-convert-numeric-std-logic-vector-to-integer.html#Numeric-Unsigned-To-Integer)
	constant tmp : integer := (1000/255);
	new_data <= to_integer(((256 - Data_in) * (tmp)) + 500);  --idk if this is how you do this
	
	--delta calculation
	constant delta_1 : integer := (1/1500) * (1/2);
	constant delta_2 : integer := (1/500) * (1/2);
	
	constant delta_tmp : integer := ((delta_2 - delta_1) / 255);
	delta <= delta_1 + (delta_tmp * Data_in)
	
	--change cnt_out
    cnt : process(I_CLK_125MHz, I_RESET_N)
    begin
        if(I_RESET_N = '1') then 
            cnt_out <= (others => '0');
        elsif(rising_edge(I_CLK_125MHz)) then
            cnt_out <= cnt_out + 1;
        end if;
     end if;
  end process cnt;
  
  --changing mux1_out and mux2_out
  add : process (I_CLK_125MHz, I_RESET_N) 
	begin
		if (rising_edge(I_CLK_125MHz)) then
			if(I_RESET_N = '0') then
				if(comp_out = '1') then 
					mux2_out <= cnt_out + reg_out;
				else
					mux1_out <= reg_out;
				end if;
			else
				mux2_out <= new_data;
			end if;
		end if;
  end process add;

--changing comp_out
  comp : process (I_CLK_125MHz)
	begin
		if (rising_edge(I_CLK_125MHz)) then
			if(cnt_out = reg_out) then
				comp_out <= '1';
				--toggling Clock_out
				if(Clock_out = '0') then
					Clock_out <= '1';
				else 
					Clock_out <= '0';
				end if;
			else
				comp_out <= '0';
			end if;
		end if;
  end process comp;

--changing reg_out
  reg : process (I_CLK_125MHz)
	begin
		if (rising_edge(I_CLK_125MHz)) then
			reg_out <= mux2_out;
		end if;
  end process reg;
  
end archclk_gen;
