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

entity clk_gen is
  port (
    I_CLK_125MHz : in std_logic;
    I_RESET_N   : in std_logic;
    Data_in     : in std_logic_vector(7 downto 0) := X"4D";
    Clock_out   : out std_logic
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
  signal mux2_out : unsigned(15 downto 0) := (others => '0');
  signal new_data : unsigned(15 downto 0) := (others => '0');
  signal tmp_a : unsigned(7 downto 0) := (others => '0');
  signal tmp_b : unsigned(15 downto 0) := (others => '0');

  -- Signals created by Kyle
  signal counter : integer;
  signal increment : integer := 327; -- (delta 2 - delta 1) / 255
  signal delta_1 : integer := 41667; -- delta 1 constant: ( .5 * ( 1/1500 ) ) / sys_period

begin

	--changing 0-255 to 500 - 1500
	--tmp_a <= "11111111" - Data_in;
	-- new_data <= ((256 - Data_in) * (1000 / 255)) + 500;  --idk if this is how you do this  -- KAB: NOTE: the equation I believe is correct, but I do not believe you can do integer arithmetic on an unsigned data type

-- KAB commented out for testing purposes
	--change cnt_out
  --   cnt : process(I_CLK_125MHz, I_RESET_N)
  --   begin
  --       if(I_RESET_N = '1') then
  --           cnt_out <= (others => '0');
  --
  --       elsif(rising_edge(I_CLK_125MHz)) then
  --
  --            --if (std_logic_vector(eightBitCounter) <= Data_in) then
  --               -- Clock_out <= '1';
  --               -- --add counter to register value
  --
  --           -- else
  --           cnt_out <= cnt_out + 1;
  --       -- end if;
  --    end if;
  -- end process cnt;

  -- KAB not sure how to use what you have for processes so this is what I made
  KAB_COUNTER : process(I_CLK_125MHZ, I_RESET_N)
  begin
    if (I_RESET_N) then
      counter <= 0;
      cnt_out <= (others => '0');
    elsif (rising_edge(I_CLK_125MHZ)) then
      counter <= delta_1 + increment * Data_in;  -- KAB get the value counted to
      cnt_out <= cnt_out + '1';
      if (cnt_out = to_unsigned(counter, 8)) then  -- KAB this comes from numeric_std library reference: nandland.com
        Clock_out <= not Clock_out;  -- toggle clock output
      end if;
    end if;
  end process;

  -- KAB commented out for testing purposes
  --changing mux1_out and mux2_out
  -- add : process (I_CLK_125MHz) --need seperate process?
	-- begin
	-- 	if (rising_edge(I_CLK_125MHz)) then
	-- 		if(I_RESET_N = '0') then
	-- 			if(comp_out = '1') then
	-- 				mux2_out <= cnt_out + reg_out;
	-- 			else
	-- 				mux1_out <= reg_out;
	-- 			end if;
	-- 		else
	-- 			mux2_out <= new_data;
	-- 		end if;
	-- 	end if;
  -- end process add;

-- KAB commented out for testing purposes
--changing comp_out
  -- comp : process (I_CLK_125MHz)
	-- begin
	-- 	if (rising_edge(I_CLK_125MHz)) then
	-- 		if(cnt_out = reg_out) then
	-- 			comp_out <= '1';
	-- 			--toggling Clock_out
	-- 			if(Clock_out = '0') then
	-- 				Clock_out <= '1';
	-- 			else
	-- 				Clock_out <= '0';
	-- 			end if;
	-- 		else
	-- 			comp_out <= '0';
	-- 		end if;
	-- 	end if;
  -- end process comp;

-- KAB commented out for testing purposes
--changing reg_out
  -- reg : process (I_CLK_125MHz)
	-- begin
	-- 	if (rising_edge(I_CLK_125MHz)) then
	-- 		reg_out <= mux2_out;
	-- 	end if;
  -- end process reg;

end archclk_gen;
