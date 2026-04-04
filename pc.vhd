library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- pc.vhd

-- Program Counter register
-- Stores the address of the current instruction
-- On reset the PC is initialized to 0
-- Rising clock edge -> PC loads updated_pc.

entity pc is
    port (
        clk : in  std_logic;
        reset : in  std_logic;
        updated_pc : in  std_logic_vector(31 downto 0);
        pc_value: out std_logic_vector(31 downto 0)
    );
end pc;

architecture behavioral of pc is

    --Register holding the current PC
    signal current_PC : std_logic_vector(31 downto 0) := (others => '0');

begin

    -- PC updated
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_PC <= (others => '0'); --Initialize PC to addr= 0

            else
                -- Loading next PC 
                current_PC <= updated_pc;
            end if;
        end if;
    end process;

    -- assign current PC value to pc_valu
    pc_value <= current_PC;

end behavioral;