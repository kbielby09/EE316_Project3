----------------------------------------------------------------------------------
-- Filename: clk_gen.vhd
-- Author: Chandler Kent
-- Date Created: 2/28/21
-- Last Modified: 3/4/21
-- Description: Clock generation code
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_gen is
  port (
    I_CLK_50MHz : in  std_logic;
    I_RESET_N   : in std_logic;
    Data_in     : in std_logic_vector(7 downto 0);
    Clock_out   : out std_logic
  );
end clk_gen;

architecture archclk_gen of clk_gen is

  signal eightBitCounter : unsigned(7 downto 0) := (others => '0');
  signal cnt_out : unsigned(7 downto 0) := (others => '0');
  signal cnt_in : unsigned(7 downto 0) := (others => '0');
  signal add_out : unsigned(7 downto 0) := (others => '0');
  signal reg_out : unsigned(7 downto 0) := (others => '0');
  signal comp_out : std_logic := '0';
  signal mux1_out : unsigned(7 downto 0) := (others => '0');
  signal mux2_out : unsigned(7 downto 0) := (others => '0');
  
begin
  cnt : process (I_CLK_50MHz, I_RESET_N)
    begin
        if(I_RESET_N = '1') then 
            cnt_out <= (others => '0');	--Not sure if this is correct syntax
    
        elsif(rising_edge(I_CLK_50MHz)) then
--             if (std_logic_vector(eightBitCounter) <= Data_in) then
                -- Clock_out <= '1';
                -- --add counter to register value

            -- else 
            cnt_out <= cnt_out + 1;
        end if;
     end if;
  end process cnt;
  
  add : process (Data_in) --need seperate process?
	begin
		if(I_RESET_N = '0') then
			if(comp_out = '1') then 
				mux2_out <= cnt_out + reg_out;
			else
				mux1_out <= reg_out;
			end if;
		else
			mux2_out <= Data_in;
		end if;
  end process add;
	
  comp : process ()
	begin
		if(cnt_out = reg_out) then
			comp_out <= '1';
			if(Clock_out = '0') then
				Clock_out <= '1';
			else 
				Clock_out <= '0';
			end if;
		else
			comp_out <= '0';
		end if;
  end process comp;

  reg : process (I_CLK_50MHz)
	begin
		if rising_edge(I_CLK_50MHz) then
			mux2_out <= reg_out;
		end if;
  end process reg;
  
end architecture;


