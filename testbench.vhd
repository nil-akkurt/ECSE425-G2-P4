library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 

entity testbench is
end testbench;
 
architecture behavioral of testbench is
 
    constant CLK_PERIOD : time := 1 ns;
 
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
 
begin
 
    uut : entity work.cpu
        port map (
            clk   => clk,
            reset => reset
        );
 
    process
    begin
    	clk <= '0';
   	wait for CLK_PERIOD / 2;
    	clk <= '1';
    	wait for CLK_PERIOD / 2;
    end process;
    process
    begin
        reset <= '1';
        wait for CLK_PERIOD * 2;
        reset <= '0';
        wait for CLK_PERIOD * 9998;
        wait;
    end process;
 
end behavioral;
 