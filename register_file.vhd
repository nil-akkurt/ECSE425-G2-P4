library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- register_file.vhd
-- Implements the 32 general-purpose registers of the RISC-V processor.
-- Provides two asynchronous read ports and one synchronous write port.
-- Register x0 is hardwired to 0 as required by the ISA.

entity register_file is
    port (
        clk  : in  std_logic;
        reset  : in  std_logic;
        -- Register addresses for read ports
        read_reg_1  : in  std_logic_vector(4 downto 0);
        read_reg_2  : in  std_logic_vector(4 downto 0);
        -- Data outputs from the selected registers
        read_data_1 : out std_logic_vector(31 downto 0);
        read_data_2 : out std_logic_vector(31 downto 0);
        -- Register write port
        write_reg   : in  std_logic_vector(4 downto 0);
        write_data  : in  std_logic_vector(31 downto 0);
        write_enable: in  std_logic
    );
end register_file;

architecture behavioral of register_file is
    -- Storage for the 32 registers
    type register_arr is array (0 to 31) of std_logic_vector(31 downto 0);
    signal registers : register_arr;

begin
    -- Writing process
    -- Registers are updated on the rising edge of the clock.
    -- Writes to x0 are ignored so that x0 always remains 0.
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                registers <= (others => (others => '0'));
            else
                if write_enable = '1' then
                    if unsigned(write_reg) /= 0 then
                        registers(to_integer(unsigned(write_reg))) <= write_data;
                    end if;
                end if;

                -- Ensure register x0 always stays zero
                registers(0) <= (others => '0');
            end if;
        end if;
    end process;

    -- Asynchronous read ports
    -- If register 0 is selected, return zero.
    process(read_reg_1, read_reg_2)
    begin
    if unsigned(read_reg_1) = 0 then
        read_data_1 <= (others => '0');
    else
        read_data_1 <= registers(to_integer(unsigned(read_reg_1)));
    end if;

    if unsigned(read_reg_2) = 0 then
        read_data_2 <= (others => '0');
    else
        read_data_2 <= registers(to_integer(unsigned(read_reg_2)));
    end if;
    end process;
end behavioral;