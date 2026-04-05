library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- data_memory.vhd
-- Byte-addressable data memory for the RISC-V pipelined processor.
-- 32768 bytes (32 KB), initialized to all zeros per spec.
-- Supports byte (lb/sb), halfword (lh/sh), and word (lw/sw) access
-- with sign-extension (lb, lh) or zero-extension (lbu, lhu) on reads.
-- Little-endian byte ordering (RISC-V convention).
--
-- Read:  combinational (data available in same MEM cycle)
-- Write: synchronous (rising clock edge when mem_write = '1')
--
-- funct3 encoding (matches RISC-V):
--   "000" = byte       (lb / sb)
--   "001" = halfword   (lh / sh)
--   "010" = word       (lw / sw)
--   "100" = byte (U)   (lbu)
--   "101" = halfword (U)(lhu)

entity data_memory is
    port (
        clk        : in  std_logic;
        address    : in  std_logic_vector(31 downto 0);
        write_data : in  std_logic_vector(31 downto 0);
        mem_read   : in  std_logic;
        mem_write  : in  std_logic;
        funct3     : in  std_logic_vector(2 downto 0);
        read_data  : out std_logic_vector(31 downto 0)
    );
end data_memory;

architecture behavioral of data_memory is

    -- 32768 bytes, each element is one byte
    type byte_array is array (0 to 32767) of std_logic_vector(7 downto 0);
    signal mem : byte_array := (others => (others => '0'));

begin

    -----------------------------------------------------------------------
    -- WRITE PROCESS (synchronous, rising edge)
    -----------------------------------------------------------------------
    process(clk)
        variable addr : integer;
    begin
        if rising_edge(clk) then
            if mem_write = '1' then
                addr := to_integer(unsigned(address(14 downto 0)));

                case funct3 is
                    -- sb: store byte
                    when "000" =>
                        mem(addr) <= write_data(7 downto 0);

                    -- sh: store halfword (2 bytes, little-endian)
                    when "001" =>
                        mem(addr)     <= write_data(7 downto 0);
                        mem(addr + 1) <= write_data(15 downto 8);

                    -- sw: store word (4 bytes, little-endian)
                    when "010" =>
                        mem(addr)     <= write_data(7 downto 0);
                        mem(addr + 1) <= write_data(15 downto 8);
                        mem(addr + 2) <= write_data(23 downto 16);
                        mem(addr + 3) <= write_data(31 downto 24);

                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    -----------------------------------------------------------------------
    -- READ LOGIC (combinational)
    -----------------------------------------------------------------------
    process(address, mem_read, funct3, mem)
        variable addr  : integer;
        variable byte0 : std_logic_vector(7 downto 0);
        variable byte1 : std_logic_vector(7 downto 0);
        variable byte2 : std_logic_vector(7 downto 0);
        variable byte3 : std_logic_vector(7 downto 0);
    begin
        read_data <= (others => '0');

        if mem_read = '1' then
            addr := to_integer(unsigned(address(14 downto 0)));

            byte0 := mem(addr);

            case funct3 is
                -- lb: load byte, sign-extend
                when "000" =>
                    read_data(7 downto 0) <= byte0;
                    read_data(31 downto 8) <= (others => byte0(7));

                -- lh: load halfword, sign-extend
                when "001" =>
                    byte1 := mem(addr + 1);
                    read_data(7 downto 0)   <= byte0;
                    read_data(15 downto 8)  <= byte1;
                    read_data(31 downto 16) <= (others => byte1(7));

                -- lw: load word
                when "010" =>
                    byte1 := mem(addr + 1);
                    byte2 := mem(addr + 2);
                    byte3 := mem(addr + 3);
                    read_data <= byte3 & byte2 & byte1 & byte0;

                -- lbu: load byte, zero-extend
                when "100" =>
                    read_data(7 downto 0) <= byte0;
                    read_data(31 downto 8) <= (others => '0');

                -- lhu: load halfword, zero-extend
                when "101" =>
                    byte1 := mem(addr + 1);
                    read_data(7 downto 0)   <= byte0;
                    read_data(15 downto 8)  <= byte1;
                    read_data(31 downto 16) <= (others => '0');

                when others =>
                    read_data <= (others => '0');
            end case;
        end if;
    end process;

end behavioral;
