library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- id_ex_reg.vhd
-- Pipeline register between ID and EX stages.
-- Stores:decoded control signals, register operands, immediate value, PC / PC+4, instruction fields needed later (rs1, rs2, rd, funct3, funct7)
-- Behavior:
--  On reset: clears everything
--  On insert_bubble = '1': clears control signals and datapath values so EX executes a NOP bubble
--  Otherwise: latches new ID-stage values on rising edge

entity id_ex_reg is
    port (
        clk : in std_logic;
        reset : in std_logic;
        insert_bubble : in std_logic;

        -- ID stage inputs - control
        id_alu_op      : in std_logic_vector(1 downto 0);
        id_alu_src     : in std_logic;
        id_alu_src_a   : in std_logic_vector(1 downto 0);

        id_mem_read    : in std_logic;
        id_mem_write   : in std_logic;
        id_branch      : in std_logic;
        id_jump        : in std_logic;
        id_jump_reg    : in std_logic;

        id_reg_write   : in std_logic;
        id_mem_to_reg  : in std_logic_vector(1 downto 0);

        -- ID stage inputs - datapath
        id_pc          : in std_logic_vector(31 downto 0);
        id_pc_plus4    : in std_logic_vector(31 downto 0);
        id_read_data_1 : in std_logic_vector(31 downto 0);
        id_read_data_2 : in std_logic_vector(31 downto 0);
        id_immediate   : in std_logic_vector(31 downto 0);

        -- instruction fields
        id_rs1         : in std_logic_vector(4 downto 0);
        id_rs2         : in std_logic_vector(4 downto 0);
        id_rd          : in std_logic_vector(4 downto 0);
        id_funct3      : in std_logic_vector(2 downto 0);
        id_funct7      : in std_logic_vector(6 downto 0);

        -- EX stage outputs - control
        ex_alu_op      : out std_logic_vector(1 downto 0);
        ex_alu_src     : out std_logic;
        ex_alu_src_a   : out std_logic_vector(1 downto 0);

        ex_mem_read    : out std_logic;
        ex_mem_write   : out std_logic;
        ex_branch      : out std_logic;
        ex_jump        : out std_logic;
        ex_jump_reg    : out std_logic;

        ex_reg_write   : out std_logic;
        ex_mem_to_reg  : out std_logic_vector(1 downto 0);

        -- EX stage outputs - datapath
        ex_pc          : out std_logic_vector(31 downto 0);
        ex_pc_plus4    : out std_logic_vector(31 downto 0);
        ex_read_data_1 : out std_logic_vector(31 downto 0);
        ex_read_data_2 : out std_logic_vector(31 downto 0);
        ex_immediate   : out std_logic_vector(31 downto 0);

        -- instruction fields
        ex_rs1         : out std_logic_vector(4 downto 0);
        ex_rs2         : out std_logic_vector(4 downto 0);
        ex_rd          : out std_logic_vector(4 downto 0);
        ex_funct3      : out std_logic_vector(2 downto 0);
        ex_funct7      : out std_logic_vector(6 downto 0)
    );
end id_ex_reg;

architecture behavioral of id_ex_reg is

    -- control registers
    signal alu_op_reg      : std_logic_vector(1 downto 0) := (others => '0');
    signal alu_src_reg     : std_logic := '0';
    signal alu_src_a_reg   : std_logic_vector(1 downto 0) := (others => '0');

    signal mem_read_reg    : std_logic := '0';
    signal mem_write_reg   : std_logic := '0';
    signal branch_reg      : std_logic := '0';
    signal jump_reg_reg    : std_logic := '0';
    signal jump_reg2_reg   : std_logic := '0';

    signal reg_write_reg   : std_logic := '0';
    signal mem_to_reg_reg  : std_logic_vector(1 downto 0) := (others => '0');

    -- datapath registers
    signal pc_reg          : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_plus4_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal read_data_1_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal read_data_2_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal immediate_reg   : std_logic_vector(31 downto 0) := (others => '0');

    signal rs1_reg         : std_logic_vector(4 downto 0) := (others => '0');
    signal rs2_reg         : std_logic_vector(4 downto 0) := (others => '0');
    signal rd_reg          : std_logic_vector(4 downto 0) := (others => '0');
    signal funct3_reg      : std_logic_vector(2 downto 0) := (others => '0');
    signal funct7_reg      : std_logic_vector(6 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                alu_op_reg      <= (others => '0');
                alu_src_reg     <= '0';
                alu_src_a_reg   <= (others => '0');

                mem_read_reg    <= '0';
                mem_write_reg   <= '0';
                branch_reg      <= '0';
                jump_reg_reg    <= '0';
                jump_reg2_reg   <= '0';

                reg_write_reg   <= '0';
                mem_to_reg_reg  <= (others => '0');

                pc_reg          <= (others => '0');
                pc_plus4_reg    <= (others => '0');
                read_data_1_reg <= (others => '0');
                read_data_2_reg <= (others => '0');
                immediate_reg   <= (others => '0');

                rs1_reg         <= (others => '0');
                rs2_reg         <= (others => '0');
                rd_reg          <= (others => '0');
                funct3_reg      <= (others => '0');
                funct7_reg      <= (others => '0');

            elsif insert_bubble = '1' then
                -- zero control signals so EX/MEM/WB do nothing
                alu_op_reg      <= (others => '0');
                alu_src_reg     <= '0';
                alu_src_a_reg   <= (others => '0');

                mem_read_reg    <= '0';
                mem_write_reg   <= '0';
                branch_reg      <= '0';
                jump_reg_reg    <= '0';
                jump_reg2_reg   <= '0';

                reg_write_reg   <= '0';
                mem_to_reg_reg  <= (others => '0');

                -- datapath values also cleared for safety
                pc_reg          <= (others => '0');
                pc_plus4_reg    <= (others => '0');
                read_data_1_reg <= (others => '0');
                read_data_2_reg <= (others => '0');
                immediate_reg   <= (others => '0');

                rs1_reg         <= (others => '0');
                rs2_reg         <= (others => '0');
                rd_reg          <= (others => '0');
                funct3_reg      <= (others => '0');
                funct7_reg      <= (others => '0');

            else
                alu_op_reg      <= id_alu_op;
                alu_src_reg     <= id_alu_src;
                alu_src_a_reg   <= id_alu_src_a;

                mem_read_reg    <= id_mem_read;
                mem_write_reg   <= id_mem_write;
                branch_reg      <= id_branch;
                jump_reg_reg    <= id_jump;
                jump_reg2_reg   <= id_jump_reg;

                reg_write_reg   <= id_reg_write;
                mem_to_reg_reg  <= id_mem_to_reg;

                pc_reg          <= id_pc;
                pc_plus4_reg    <= id_pc_plus4;
                read_data_1_reg <= id_read_data_1;
                read_data_2_reg <= id_read_data_2;
                immediate_reg   <= id_immediate;

                rs1_reg         <= id_rs1;
                rs2_reg         <= id_rs2;
                rd_reg          <= id_rd;
                funct3_reg      <= id_funct3;
                funct7_reg      <= id_funct7;
            end if;
        end if;
    end process;

    ex_alu_op      <= alu_op_reg;
    ex_alu_src     <= alu_src_reg;
    ex_alu_src_a   <= alu_src_a_reg;

    ex_mem_read    <= mem_read_reg;
    ex_mem_write   <= mem_write_reg;
    ex_branch      <= branch_reg;
    ex_jump        <= jump_reg_reg;
    ex_jump_reg    <= jump_reg2_reg;

    ex_reg_write   <= reg_write_reg;
    ex_mem_to_reg  <= mem_to_reg_reg;

    ex_pc          <= pc_reg;
    ex_pc_plus4    <= pc_plus4_reg;
    ex_read_data_1 <= read_data_1_reg;
    ex_read_data_2 <= read_data_2_reg;
    ex_immediate   <= immediate_reg;

    ex_rs1         <= rs1_reg;
    ex_rs2         <= rs2_reg;
    ex_rd          <= rd_reg;
    ex_funct3      <= funct3_reg;
    ex_funct7      <= funct7_reg;

end behavioral;