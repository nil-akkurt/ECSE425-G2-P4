library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

-- instruction_memory.vhd
-- Read-only instruction memory for the RISC-V pipelined processor.
-- Holds up to 1024 instructions (32-bit words).
-- Initialized at elaboration from "program.txt" (one binary-encoded
-- 32-bit word per line, e.g. "00000000000000000000000000010011").
-- Combinational read: output available in the same cycle as address.

entity instruction_memory is
    port (
        address     : in  std_logic_vector(31 downto 0);
        instruction : out std_logic_vector(31 downto 0)
    );
end instruction_memory;

architecture behavioral of instruction_memory is

    -- 1024 words of 32 bits (supports up to 1024 instructions per spec)
    type mem_array is array (0 to 1023) of std_logic_vector(31 downto 0);

    -- NOP encoding: addi x0, x0, 0
    constant NOP : std_logic_vector(31 downto 0) := x"00000013";

    -- Load program from "program.txt" at elaboration time.
    -- Each line must contain exactly 32 characters of '0' or '1'.
    -- Unused entries are filled with NOPs.
    impure function load_program return mem_array is
        file     prog_file : text open read_mode is "program.txt";
        variable line_buf  : line;
        variable mem       : mem_array := (others => NOP);
        variable idx       : integer := 0;
        variable bit_char  : character;
        variable good      : boolean;
        variable word      : std_logic_vector(31 downto 0);
    begin
        while not endfile(prog_file) and idx < 1024 loop
            readline(prog_file, line_buf);
            word := (others => '0');
            for i in 31 downto 0 loop
                read(line_buf, bit_char, good);
                if good then
                    if bit_char = '1' then
                        word(i) := '1';
                    else
                        word(i) := '0';
                    end if;
                end if;
            end loop;
            mem(idx) := word;
            idx := idx + 1;
        end loop;
        return mem;
    end function;

    signal mem : mem_array := load_program;

begin

    -- Combinational read: word-aligned access
    -- Byte address -> word index by shifting right 2 (bits [11:2])
    process(address)
        variable word_index : integer;
    begin
        word_index := to_integer(unsigned(address(11 downto 2)));
        if word_index >= 0 and word_index < 1024 then
            instruction <= mem(word_index);
        else
            -- Out-of-range: return NOP
            instruction <= NOP;
        end if;
    end process;

end behavioral;
