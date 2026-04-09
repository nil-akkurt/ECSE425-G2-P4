library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- cpu.vhd
-- 5-stage pipelined RISC-V CPU:
--   IF -> ID -> EX -> MEM -> WB
--
-- Uses:
--   - no forwarding
--   - hazard stalls
--   - branch resolved in EX, takes effect in MEM
--
-- Pipeline behavior on data hazard:
--   1. hold PC
--   2. hold IF/ID
--   3. insert bubble into ID/EX
--
-- Pipeline behavior on taken branch/jump:
--   1. PC updated from MEM-stage control transfer target
--   2. flush IF/ID
--   3. insert bubble into ID/EX

entity cpu is
    port (
        clk   : in std_logic;
        reset : in std_logic
    );
end cpu;

architecture behavioral of cpu is

    -- constants
    constant NOP : std_logic_vector(31 downto 0) := x"00000013";

    -- IF stage signals
    signal pc_current      : std_logic_vector(31 downto 0) := (others => '0') ;
    signal pc_next         : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_plus4_if     : std_logic_vector(31 downto 0) := (others => '0');
    signal if_instruction  : std_logic_vector(31 downto 0) := (others => '0');

    -- IF/ID signals
    signal if_id_write_enable : std_logic :='0';
    signal flush_if_id        : std_logic :='0';

    signal id_pc          : std_logic_vector(31 downto 0) := (others => '0');
    signal id_pc_plus4    : std_logic_vector(31 downto 0) := (others => '0');
    signal id_instruction : std_logic_vector(31 downto 0) := (others => '0');

    -- ID stage decoded fields
    signal id_opcode  : std_logic_vector(6 downto 0) := (others => '0');
    signal id_rd      : std_logic_vector(4 downto 0) := (others => '0');
    signal id_funct3  : std_logic_vector(2 downto 0) := (others => '0');
    signal id_rs1     : std_logic_vector(4 downto 0) := (others => '0');
    signal id_rs2     : std_logic_vector(4 downto 0) := (others => '0');
    signal id_funct7  : std_logic_vector(6 downto 0) := (others => '0');

    signal id_read_data_1 : std_logic_vector(31 downto 0) := (others => '0');
    signal id_read_data_2 : std_logic_vector(31 downto 0) := (others => '0');
    signal id_immediate   : std_logic_vector(31 downto 0) := (others => '0');

    -- ID stage control signals
    signal id_alu_op      : std_logic_vector(1 downto 0) := (others => '0');
    signal id_alu_src     : std_logic :='0';
    signal id_alu_src_a   : std_logic_vector(1 downto 0) := (others => '0');

    signal id_mem_read    : std_logic :='0';
    signal id_mem_write   : std_logic :='0';
    signal id_branch      : std_logic :='0';
    signal id_jump        : std_logic :='0';
    signal id_jump_reg    : std_logic :='0';

    signal id_reg_write   : std_logic :='0';
    signal id_mem_to_reg  : std_logic_vector(1 downto 0) := (others => '0');
    signal id_imm_type    : std_logic_vector(2 downto 0) := (others => '0');

    -- hazard detection support
    signal hazard_rs1 : std_logic_vector(4 downto 0) := (others => '0');
    signal hazard_rs2 : std_logic_vector(4 downto 0) := (others => '0');
    signal stall      : std_logic :='0';

    signal id_uses_rs1 : std_logic :='0';
    signal id_uses_rs2 : std_logic :='0';

    signal insert_bubble_id_ex : std_logic :='0';

    -- ID/EX signals
    signal ex_alu_op      : std_logic_vector(1 downto 0) := (others => '0');
    signal ex_alu_src     : std_logic :='0';
    signal ex_alu_src_a   : std_logic_vector(1 downto 0) := (others => '0');

    signal ex_mem_read    : std_logic :='0';
    signal ex_mem_write   : std_logic :='0';
    signal ex_branch      : std_logic :='0';
    signal ex_jump        : std_logic :='0';
    signal ex_jump_reg    : std_logic :='0';

    signal ex_reg_write   : std_logic :='0';
    signal ex_mem_to_reg  : std_logic_vector(1 downto 0) := (others => '0');

    signal ex_pc          : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_pc_plus4    : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_read_data_1 : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_read_data_2 : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_immediate   : std_logic_vector(31 downto 0) := (others => '0');

    signal ex_rs1         : std_logic_vector(4 downto 0) := (others => '0');
    signal ex_rs2         : std_logic_vector(4 downto 0) := (others => '0') ;
    signal ex_rd          : std_logic_vector(4 downto 0) := (others => '0');
    signal ex_funct3      : std_logic_vector(2 downto 0) := (others => '0');
    signal ex_funct7      : std_logic_vector(6 downto 0) := (others => '0');

    -- EX stage internal signals
    signal ex_alu_control_signal : std_logic_vector(3 downto 0):= (others => '0');
    signal ex_alu_input_a        : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_alu_input_b        : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_alu_result         : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_zero               : std_logic :='0';

    signal ex_branch_target : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_branch_taken  : std_logic :='0';
    signal ex_store_data    : std_logic_vector(31 downto 0) := (others => '0');

    -- EX/MEM signals
    signal insert_bubble_ex_mem : std_logic :='0';
    signal mem_mem_read   : std_logic :='0';
    signal mem_mem_write  : std_logic :='0';
    signal mem_branch     : std_logic :='0';
    signal mem_jump       : std_logic :='0';
    signal mem_jump_reg   : std_logic :='0';

    signal mem_reg_write  : std_logic :='0';
    signal mem_mem_to_reg : std_logic_vector(1 downto 0) := (others => '0');

    signal mem_pc_plus4      : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_alu_result    : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_write_data    : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_branch_target : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_branch_taken  : std_logic :='0';

    signal mem_rd            : std_logic_vector(4 downto 0) := (others => '0');
    signal mem_funct3        : std_logic_vector(2 downto 0) := (others => '0');

    -- MEM stage internal signals
    signal mem_read_data : std_logic_vector(31 downto 0) := (others => '0');

    signal mem_control_transfer_taken : std_logic :='0';

    -- MEM/WB signals
    signal wb_reg_write   : std_logic :='0';
    signal wb_mem_to_reg  : std_logic_vector(1 downto 0) := (others => '0');

    signal wb_read_data   : std_logic_vector(31 downto 0) := (others => '0');
    signal wb_alu_result  : std_logic_vector(31 downto 0) := (others => '0');
    signal wb_pc_plus4    : std_logic_vector(31 downto 0) := (others => '0');
    signal wb_rd          : std_logic_vector(4 downto 0) := (others => '0');

    -- WB stage internal signals
    signal wb_write_data : std_logic_vector(31 downto 0) := (others => '0');

begin

    -- IF stage --
    pc_plus4_if <= std_logic_vector(unsigned(pc_current) + 4) after 1 ps;

    -- PC select:
    -- default = sequential fetch
    -- if MEM-stage branch/jump/jalr takes effect, redirect PC there
    mem_control_transfer_taken <= ((mem_branch and mem_branch_taken) or mem_jump or mem_jump_reg) after 1 ps;

    pc_next <= mem_branch_target when mem_control_transfer_taken = '1' else
					pc_current       when stall = '1' else
					pc_plus4_if after 1 ps;
	 
	 pc_inst : entity work.pc
        port map (
            clk        => clk,
            reset      => reset,
            updated_pc => pc_next,
            pc_value   => pc_current
        );

    instr_mem_inst : entity work.instruction_memory
        port map (
            address     => pc_current,
            instruction => if_instruction
        );

    -- IF/ID pipeline register --
    flush_if_id <= mem_control_transfer_taken after 1 ps;
    if_id_write_enable <= not stall after 1 ps;

    if_id_reg_inst : entity work.if_id_reg
        port map (
            clk                => clk,
            reset              => reset,
            if_id_write_enable => if_id_write_enable,
            flush              => flush_if_id,
            if_pc              => pc_current,
            if_pc_plus4        => pc_plus4_if,
            if_instruction     => if_instruction,
            id_pc              => id_pc,
            id_pc_plus4        => id_pc_plus4,
            id_instruction     => id_instruction
        );

    -- ID stage: field extraction --
    id_opcode <= id_instruction(6 downto 0) after 1 ps;
    id_rd     <= id_instruction(11 downto 7) after 1 ps;
    id_funct3 <= id_instruction(14 downto 12) after 1 ps;
    id_rs1    <= id_instruction(19 downto 15) after 1 ps;
    id_rs2    <= id_instruction(24 downto 20) after 1 ps;
    id_funct7 <= id_instruction(31 downto 25) after 1 ps;

    -- ID stage: control + immediate + register file --
    control_unit_inst : entity work.control_unit
        port map (
            opcode     => id_opcode,
            alu_op     => id_alu_op,
            alu_src    => id_alu_src,
            alu_src_a  => id_alu_src_a,
            mem_read   => id_mem_read,
            mem_write  => id_mem_write,
            branch     => id_branch,
            jump       => id_jump,
            jump_reg   => id_jump_reg,
            reg_write  => id_reg_write,
            mem_to_reg => id_mem_to_reg,
            imm_type   => id_imm_type
        );

    imm_gen_inst : entity work.immediate_instruction
        port map (
            instruct           => id_instruction,
            immediate_selector => id_imm_type,
            immediate_value    => id_immediate
        );

    reg_file_inst : entity work.register_file
        port map (
            clk          => clk,
            reset        => reset,
            read_reg_1   => id_rs1,
            read_reg_2   => id_rs2,
            read_data_1  => id_read_data_1,
            read_data_2  => id_read_data_2,
            write_reg    => wb_rd,
            write_data   => wb_write_data,
            write_enable => wb_reg_write
        );

    -- Hazard detection input masking
    -- This avoids false stalls for instructions that do not really use rs1/rs2
    process(id_opcode)
    begin
        id_uses_rs1 <= '0';
        id_uses_rs2 <= '0';

        case id_opcode is
            -- R-type
            when "0110011" =>
                id_uses_rs1 <= '1';
                id_uses_rs2 <= '1';

            -- I-type ALU
            when "0010011" =>
                id_uses_rs1 <= '1';

            -- loads
            when "0000011" =>
                id_uses_rs1 <= '1';

            -- stores
            when "0100011" =>
                id_uses_rs1 <= '1';
                id_uses_rs2 <= '1';

            -- branches
            when "1100011" =>
                id_uses_rs1 <= '1';
                id_uses_rs2 <= '1';

            -- jal
            when "1101111" =>
                null;

            -- jalr
            when "1100111" =>
                id_uses_rs1 <= '1';

            -- lui
            when "0110111" =>
                null;

            -- auipc
            when "0010111" =>
                null;

            when others =>
                null;
        end case;
    end process;

    hazard_rs1 <= id_rs1 when id_uses_rs1 = '1' else (others => '0') after 1 ps;
    hazard_rs2 <= id_rs2 when id_uses_rs2 = '1' else (others => '0') after 1 ps;

    hazard_unit_inst : entity work.hazard_detection
        port map (
            if_id_rs1        => hazard_rs1,
            if_id_rs2        => hazard_rs2,
            id_ex_rd         => ex_rd,
            id_ex_reg_write  => ex_reg_write,
            ex_mem_rd        => mem_rd,
            ex_mem_reg_write => mem_reg_write,
            mem_wb_rd        => wb_rd,
            mem_wb_reg_write => wb_reg_write,
            stall            => stall
        );

    -- ID/EX pipeline register --
    -- Insert bubble on: data hazard stall/taken control transfer in MEM
    insert_bubble_id_ex <= stall or mem_control_transfer_taken after 1 ps;

    id_ex_reg_inst : entity work.id_ex_reg
        port map (
            clk            => clk,
            reset          => reset,
            insert_bubble  => insert_bubble_id_ex,

            id_alu_op      => id_alu_op,
            id_alu_src     => id_alu_src,
            id_alu_src_a   => id_alu_src_a,

            id_mem_read    => id_mem_read,
            id_mem_write   => id_mem_write,
            id_branch      => id_branch,
            id_jump        => id_jump,
            id_jump_reg    => id_jump_reg,

            id_reg_write   => id_reg_write,
            id_mem_to_reg  => id_mem_to_reg,

            id_pc          => id_pc,
            id_pc_plus4    => id_pc_plus4,
            id_read_data_1 => id_read_data_1,
            id_read_data_2 => id_read_data_2,
            id_immediate   => id_immediate,

            id_rs1         => id_rs1,
            id_rs2         => id_rs2,
            id_rd          => id_rd,
            id_funct3      => id_funct3,
            id_funct7      => id_funct7,

            ex_alu_op      => ex_alu_op,
            ex_alu_src     => ex_alu_src,
            ex_alu_src_a   => ex_alu_src_a,

            ex_mem_read    => ex_mem_read,
            ex_mem_write   => ex_mem_write,
            ex_branch      => ex_branch,
            ex_jump        => ex_jump,
            ex_jump_reg    => ex_jump_reg,

            ex_reg_write   => ex_reg_write,
            ex_mem_to_reg  => ex_mem_to_reg,

            ex_pc          => ex_pc,
            ex_pc_plus4    => ex_pc_plus4,
            ex_read_data_1 => ex_read_data_1,
            ex_read_data_2 => ex_read_data_2,
            ex_immediate   => ex_immediate,

            ex_rs1         => ex_rs1,
            ex_rs2         => ex_rs2,
            ex_rd          => ex_rd,
            ex_funct3      => ex_funct3,
            ex_funct7      => ex_funct7
        );

    -- EX stage --
    alu_control_inst : entity work.alu_control
        port map (
            alu_operation_type => ex_alu_op,
            instruction_funct3 => ex_funct3,
            instruction_funct7 => ex_funct7,
            alu_control_signal => ex_alu_control_signal
        );

    -- ALU operand A selection
    process(ex_alu_src_a, ex_read_data_1, ex_pc)
    begin
        case ex_alu_src_a is
            when "00" =>
                ex_alu_input_a <= ex_read_data_1;
            when "01" =>
                ex_alu_input_a <= ex_pc;
            when "10" =>
                ex_alu_input_a <= (others => '0');
            when others =>
                ex_alu_input_a <= ex_read_data_1;
        end case;
    end process;

    -- ALU operand B selection
    ex_alu_input_b <= ex_immediate when ex_alu_src = '1'
                      else ex_read_data_2 after 1 ps;

    alu_inst : entity work.alu
        port map (
            value_a  => ex_alu_input_a,
            value_b  => ex_alu_input_b,
            ALU_ctrl => ex_alu_control_signal,
            result   => ex_alu_result,
            zero     => ex_zero
        );

    ex_store_data <= ex_read_data_2 after 1 ps;

    -- branch/jump target computation
    process(ex_branch, ex_jump, ex_jump_reg, ex_pc, ex_read_data_1, ex_immediate)
    begin
        if ex_jump_reg = '1' then
            ex_branch_target <= std_logic_vector(unsigned(ex_read_data_1) + unsigned(ex_immediate));
        elsif ex_branch = '1' or ex_jump = '1' then
            ex_branch_target <= std_logic_vector(unsigned(ex_pc) + unsigned(ex_immediate));
        else
            ex_branch_target <= std_logic_vector(unsigned(ex_pc) + unsigned(ex_immediate));
        end if;
    end process;

    -- branch condition evaluation
    process(ex_branch, ex_funct3, ex_read_data_1, ex_read_data_2, ex_zero)
        variable a_signed   : signed(31 downto 0);
        variable b_signed   : signed(31 downto 0);
        variable a_unsigned : unsigned(31 downto 0);
        variable b_unsigned : unsigned(31 downto 0);
    begin
        a_signed   := signed(ex_read_data_1);
        b_signed   := signed(ex_read_data_2);
        a_unsigned := unsigned(ex_read_data_1);
        b_unsigned := unsigned(ex_read_data_2);

        ex_branch_taken <= '0';

        if ex_branch = '1' then
            case ex_funct3 is
                when "000" => -- beq
                    if ex_zero = '1' then
                        ex_branch_taken <= '1';
                    end if;

                when "001" => -- bne
                    if ex_zero = '0' then
                        ex_branch_taken <= '1';
                    end if;

                when "100" => -- blt
                    if a_signed < b_signed then
                        ex_branch_taken <= '1';
                    end if;

                when "101" => -- bge
                    if a_signed >= b_signed then
                        ex_branch_taken <= '1';
                    end if;

                when "110" => -- bltu
                    if a_unsigned < b_unsigned then
                        ex_branch_taken <= '1';
                    end if;

                when "111" => -- bgeu
                    if a_unsigned >= b_unsigned then
                        ex_branch_taken <= '1';
                    end if;

                when others =>
                    ex_branch_taken <= '0';
            end case;
        end if;
    end process;
	 
    -- EX/MEM pipeline register --
	 insert_bubble_ex_mem <= '0';
	 
    ex_mem_reg_inst : entity work.ex_mem_reg
        port map (
            clk              => clk,
            reset            => reset,
			insert_bubble    => insert_bubble_ex_mem,

            ex_mem_read      => ex_mem_read,
            ex_mem_write     => ex_mem_write,
            ex_branch        => ex_branch,
            ex_jump          => ex_jump,
            ex_jump_reg      => ex_jump_reg,

            ex_reg_write     => ex_reg_write,
            ex_mem_to_reg    => ex_mem_to_reg,

            ex_pc_plus4      => ex_pc_plus4,
            ex_alu_result    => ex_alu_result,
            ex_write_data    => ex_store_data,
            ex_branch_target => ex_branch_target,
            ex_branch_taken  => ex_branch_taken,

            ex_rd            => ex_rd,
            ex_funct3        => ex_funct3,

            mem_mem_read     => mem_mem_read,
            mem_mem_write    => mem_mem_write,
            mem_branch       => mem_branch,
            mem_jump         => mem_jump,
            mem_jump_reg     => mem_jump_reg,

            mem_reg_write    => mem_reg_write,
            mem_mem_to_reg   => mem_mem_to_reg,

            mem_pc_plus4     => mem_pc_plus4,
            mem_alu_result   => mem_alu_result,
            mem_write_data   => mem_write_data,
            mem_branch_target=> mem_branch_target,
            mem_branch_taken => mem_branch_taken,

            mem_rd           => mem_rd,
            mem_funct3       => mem_funct3
        );

    -- MEM stage --
    data_mem_inst : entity work.data_memory
        port map (
            clk        => clk,
            address    => mem_alu_result,
            write_data => mem_write_data,
            mem_read   => mem_mem_read,
            mem_write  => mem_mem_write,
            funct3     => mem_funct3,
            read_data  => mem_read_data
        );

    -- MEM/WB pipeline register --
    mem_wb_reg_inst : entity work.mem_wb_reg
        port map (
            clk           => clk,
            reset         => reset,

            mem_reg_write => mem_reg_write,
            mem_mem_to_reg=> mem_mem_to_reg,

            mem_read_data => mem_read_data,
            mem_alu_result=> mem_alu_result,
            mem_pc_plus4  => mem_pc_plus4,
            mem_rd        => mem_rd,

            wb_reg_write  => wb_reg_write,
            wb_mem_to_reg => wb_mem_to_reg,

            wb_read_data  => wb_read_data,
            wb_alu_result => wb_alu_result,
            wb_pc_plus4   => wb_pc_plus4,
            wb_rd         => wb_rd
        );

    -- WB stage --
    process(wb_mem_to_reg, wb_alu_result, wb_read_data, wb_pc_plus4)
    begin
        case wb_mem_to_reg is
            when "00" =>
                wb_write_data <= wb_alu_result;
            when "01" =>
                wb_write_data <= wb_read_data;
            when "10" =>
                wb_write_data <= wb_pc_plus4;
            when others =>
                wb_write_data <= wb_alu_result;
        end case;
    end process;

end behavioral;