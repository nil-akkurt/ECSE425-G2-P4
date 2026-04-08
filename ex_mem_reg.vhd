library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ex_mem_reg.vhd
-- Pipeline register between EX and MEM stages
-- Stores: MEM/WB-related control signals, ALU result, write data for stores, PC+4, branch/jump target, branch decision, destination register and funct3
--
-- Behavior:
--  On reset: clears everything
--  Otherwise: latches new EX-stage values on rising edge

entity ex_mem_reg is
    port (
        clk : in std_logic;
        reset : in std_logic;
		  insert_bubble : in std_logic;

        -- EX stage inputs - control
        ex_mem_read   : in std_logic;
        ex_mem_write  : in std_logic;
        ex_branch     : in std_logic;
        ex_jump       : in std_logic;
        ex_jump_reg   : in std_logic;

        ex_reg_write  : in std_logic;
        ex_mem_to_reg : in std_logic_vector(1 downto 0);

        -- EX stage inputs - datapath
        ex_pc_plus4      : in std_logic_vector(31 downto 0);
        ex_alu_result    : in std_logic_vector(31 downto 0);
        ex_write_data    : in std_logic_vector(31 downto 0);
        ex_branch_target : in std_logic_vector(31 downto 0);
        ex_branch_taken  : in std_logic;

        -- instruction fields needed in MEM/WB
        ex_rd            : in std_logic_vector(4 downto 0);
        ex_funct3        : in std_logic_vector(2 downto 0);

        -- MEM stage outputs - control
        mem_mem_read   : out std_logic;
        mem_mem_write  : out std_logic;
        mem_branch     : out std_logic;
        mem_jump       : out std_logic;
        mem_jump_reg   : out std_logic;

        mem_reg_write  : out std_logic;
        mem_mem_to_reg : out std_logic_vector(1 downto 0);

        -- MEM stage outputs - datapath
        mem_pc_plus4      : out std_logic_vector(31 downto 0);
        mem_alu_result    : out std_logic_vector(31 downto 0);
        mem_write_data    : out std_logic_vector(31 downto 0);
        mem_branch_target : out std_logic_vector(31 downto 0);
        mem_branch_taken  : out std_logic;

        -- instruction fields needed in MEM/WB
        mem_rd            : out std_logic_vector(4 downto 0);
        mem_funct3        : out std_logic_vector(2 downto 0)
    );
end ex_mem_reg;

architecture behavioral of ex_mem_reg is

    -- control registers
    signal mem_read_reg    : std_logic := '0';
    signal mem_write_reg   : std_logic := '0';
    signal branch_reg      : std_logic := '0';
    signal jump_reg        : std_logic := '0';
    signal jump_reg_reg    : std_logic := '0';

    signal reg_write_reg   : std_logic := '0';
    signal mem_to_reg_reg  : std_logic_vector(1 downto 0) := (others => '0');

    -- datapath registers
    signal pc_plus4_reg      : std_logic_vector(31 downto 0) := (others => '0');
    signal alu_result_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal write_data_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal branch_target_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal branch_taken_reg  : std_logic := '0';

    signal rd_reg            : std_logic_vector(4 downto 0) := (others => '0');
    signal funct3_reg        : std_logic_vector(2 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mem_read_reg      <= '0';
                mem_write_reg     <= '0';
                branch_reg        <= '0';
                jump_reg          <= '0';
                jump_reg_reg      <= '0';

                reg_write_reg     <= '0';
                mem_to_reg_reg    <= (others => '0');

                pc_plus4_reg      <= (others => '0');
                alu_result_reg    <= (others => '0');
                write_data_reg    <= (others => '0');
                branch_target_reg <= (others => '0');
                branch_taken_reg  <= '0';

                rd_reg            <= (others => '0');
                funct3_reg        <= (others => '0');

            elsif insert_bubble = '1' then
					 mem_read_reg      <= '0';
					 mem_write_reg     <= '0';
					 branch_reg        <= '0';
					 jump_reg          <= '0';
					 jump_reg_reg      <= '0';

					 reg_write_reg     <= '0';
					 mem_to_reg_reg    <= (others => '0');

					 pc_plus4_reg      <= (others => '0');
					 alu_result_reg    <= (others => '0');
					 write_data_reg    <= (others => '0');
					 branch_target_reg <= (others => '0');
					 branch_taken_reg  <= '0';

					 rd_reg            <= (others => '0');
					 funct3_reg        <= (others => '0');
				
				else
                mem_read_reg      <= ex_mem_read;
                mem_write_reg     <= ex_mem_write;
                branch_reg        <= ex_branch;
                jump_reg          <= ex_jump;
                jump_reg_reg      <= ex_jump_reg;

                reg_write_reg     <= ex_reg_write;
                mem_to_reg_reg    <= ex_mem_to_reg;

                pc_plus4_reg      <= ex_pc_plus4;
                alu_result_reg    <= ex_alu_result;
                write_data_reg    <= ex_write_data;
                branch_target_reg <= ex_branch_target;
                branch_taken_reg  <= ex_branch_taken;

                rd_reg            <= ex_rd;
                funct3_reg        <= ex_funct3;
            end if;
        end if;
    end process;

    mem_mem_read      <= mem_read_reg;
    mem_mem_write     <= mem_write_reg;
    mem_branch        <= branch_reg;
    mem_jump          <= jump_reg;
    mem_jump_reg      <= jump_reg_reg;

    mem_reg_write     <= reg_write_reg;
    mem_mem_to_reg    <= mem_to_reg_reg;

    mem_pc_plus4      <= pc_plus4_reg;
    mem_alu_result    <= alu_result_reg;
    mem_write_data    <= write_data_reg;
    mem_branch_target <= branch_target_reg;
    mem_branch_taken  <= branch_taken_reg;

    mem_rd            <= rd_reg;
    mem_funct3        <= funct3_reg;

end behavioral;