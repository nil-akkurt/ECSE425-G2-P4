library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- mem_wb_reg.vhd
-- Pipeline register between MEM and WB stages.
-- Stores: WB-related control signals, memory read data, ALU result, PC+4, destination register
-- Behavior:
--  On reset: clears everything
--  Otherwise: latches new MEM-stage values on rising edge

entity mem_wb_reg is
    port (
        clk : in std_logic;
        reset : in std_logic;

        -- MEM stage inputs - control
        mem_reg_write  : in std_logic;
        mem_mem_to_reg : in std_logic_vector(1 downto 0);

        -- MEM stage inputs - datapath
        mem_read_data  : in std_logic_vector(31 downto 0);
        mem_alu_result : in std_logic_vector(31 downto 0);
        mem_pc_plus4   : in std_logic_vector(31 downto 0);
        mem_rd         : in std_logic_vector(4 downto 0);

        -- WB stage outputs - control
        wb_reg_write   : out std_logic;
        wb_mem_to_reg  : out std_logic_vector(1 downto 0);

        -- WB stage outputs - datapath
        wb_read_data   : out std_logic_vector(31 downto 0);
        wb_alu_result  : out std_logic_vector(31 downto 0);
        wb_pc_plus4    : out std_logic_vector(31 downto 0);
        wb_rd          : out std_logic_vector(4 downto 0)
    );
end mem_wb_reg;

architecture behavioral of mem_wb_reg is

    -- control registers
    signal reg_write_reg  : std_logic := '0';
    signal mem_to_reg_reg : std_logic_vector(1 downto 0) := (others => '0');

    -- datapath registers
    signal read_data_reg  : std_logic_vector(31 downto 0) := (others => '0');
    signal alu_result_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_plus4_reg   : std_logic_vector(31 downto 0) := (others => '0');
    signal rd_reg         : std_logic_vector(4 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                reg_write_reg  <= '0';
                mem_to_reg_reg <= (others => '0');

                read_data_reg  <= (others => '0');
                alu_result_reg <= (others => '0');
                pc_plus4_reg   <= (others => '0');
                rd_reg         <= (others => '0');

            else
                reg_write_reg  <= mem_reg_write;
                mem_to_reg_reg <= mem_mem_to_reg;

                read_data_reg  <= mem_read_data;
                alu_result_reg <= mem_alu_result;
                pc_plus4_reg   <= mem_pc_plus4;
                rd_reg         <= mem_rd;
            end if;
        end if;
    end process;

    wb_reg_write  <= reg_write_reg;
    wb_mem_to_reg <= mem_to_reg_reg;

    wb_read_data  <= read_data_reg;
    wb_alu_result <= alu_result_reg;
    wb_pc_plus4   <= pc_plus4_reg;
    wb_rd         <= rd_reg;

end behavioral;