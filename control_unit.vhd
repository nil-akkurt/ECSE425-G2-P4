library ieee;
use ieee.std_logic_1164.all;

-- control_unit.vhd
-- Main control unit for the RISC-V pipelined processor.
-- Decodes the 7-bit opcode field of each instruction into
-- control signals used by every pipeline stage.
--
-- Signal semantics:
--   alu_op       -> fed to alu_control as alu_operation_type
--   alu_src      -> 0: ALU operand B = rs2,  1: ALU operand B = immediate
--   alu_src_a    -> "00": ALU operand A = rs1, "01": PC, "10": zero
--   mem_read     -> 1: read data memory in MEM stage
--   mem_write    -> 1: write data memory in MEM stage
--   branch       -> 1: instruction is a branch (beq, bne, blt, ...)
--   jump         -> 1: instruction is JAL
--   jump_reg     -> 1: instruction is JALR
--   reg_write    -> 1: write result back to register file in WB stage
--   mem_to_reg   -> "00": ALU result, "01": memory data, "10": PC+4
--   imm_type     -> fed to immediate_instruction as immediate_selector
--                   "000"=I, "001"=S, "010"=B, "011"=U, "100"=J

entity control_unit is
    port (
        opcode     : in  std_logic_vector(6 downto 0);
        -- EX stage controls
        alu_op     : out std_logic_vector(1 downto 0);
        alu_src    : out std_logic;
        alu_src_a  : out std_logic_vector(1 downto 0);
        -- MEM stage controls
        mem_read   : out std_logic;
        mem_write  : out std_logic;
        branch     : out std_logic;
        jump       : out std_logic;
        jump_reg   : out std_logic;
        -- WB stage controls
        reg_write  : out std_logic;
        mem_to_reg : out std_logic_vector(1 downto 0);
        -- ID stage (immediate format selection)
        imm_type   : out std_logic_vector(2 downto 0)
    );
end control_unit;

architecture behavioral of control_unit is
begin

    process(opcode)
    begin
        -- Safe defaults: everything disabled, ALU does ADD, operands from rs1/rs2
        alu_op    <= "00";
        alu_src   <= '0';
        alu_src_a <= "00";
        mem_read  <= '0';
        mem_write <= '0';
        branch    <= '0';
        jump      <= '0';
        jump_reg  <= '0';
        reg_write <= '0';
        mem_to_reg <= "00";
        imm_type  <= "000";

        case opcode is

            -- R-type (add, sub, mul, and, or, sll, srl, sra, slt, sltu)
            when "0110011" =>
                reg_write  <= '1';
                mem_to_reg <= "00";   -- ALU result
                alu_op     <= "10";   -- use funct3/funct7
                alu_src    <= '0';    -- operand B = rs2
                alu_src_a  <= "00";   -- operand A = rs1

            -- I-type ALU (addi, xori, ori, andi, slli, srli, srai, slti, sltiu)
            when "0010011" =>
                reg_write  <= '1';
                mem_to_reg <= "00";   -- ALU result
                alu_op     <= "10";   -- use funct3/funct7
                alu_src    <= '1';    -- operand B = immediate
                alu_src_a  <= "00";   -- operand A = rs1
                imm_type   <= "000";  -- I-type immediate

            -- Load (lb, lh, lw, lbu, lhu)
            when "0000011" =>
                reg_write  <= '1';
                mem_to_reg <= "01";   -- memory data
                mem_read   <= '1';
                alu_op     <= "00";   -- ADD (base + offset)
                alu_src    <= '1';    -- operand B = immediate
                alu_src_a  <= "00";   -- operand A = rs1
                imm_type   <= "000";  -- I-type immediate

            -- Store (sb, sh, sw)
            when "0100011" =>
                mem_write  <= '1';
                alu_op     <= "00";   -- ADD (base + offset)
                alu_src    <= '1';    -- operand B = immediate
                alu_src_a  <= "00";   -- operand A = rs1
                imm_type   <= "001";  -- S-type immediate

            -- Branch (beq, bne, blt, bge, bltu, bgeu)
            when "1100011" =>
                branch     <= '1';
                alu_op     <= "01";   -- SUB (for condition evaluation)
                alu_src    <= '0';    -- operand B = rs2
                alu_src_a  <= "00";   -- operand A = rs1
                imm_type   <= "010";  -- B-type immediate

            -- JAL (Jump and Link)
            when "1101111" =>
                reg_write  <= '1';
                mem_to_reg <= "10";   -- write-back PC+4
                jump       <= '1';
                alu_op     <= "00";   -- ADD (PC + immediate = jump target)
                alu_src    <= '1';    -- operand B = immediate
                alu_src_a  <= "01";   -- operand A = PC
                imm_type   <= "100";  -- J-type immediate

            -- JALR (Jump and Link Register)
            when "1100111" =>
                reg_write  <= '1';
                mem_to_reg <= "10";   -- write-back PC+4
                jump_reg   <= '1';
                alu_op     <= "00";   -- ADD (rs1 + immediate = jump target)
                alu_src    <= '1';    -- operand B = immediate
                alu_src_a  <= "00";   -- operand A = rs1
                imm_type   <= "000";  -- I-type immediate

            -- LUI (Load Upper Immediate)
            when "0110111" =>
                reg_write  <= '1';
                mem_to_reg <= "00";   -- ALU result
                alu_op     <= "00";   -- ADD (0 + immediate)
                alu_src    <= '1';    -- operand B = immediate
                alu_src_a  <= "10";   -- operand A = zero
                imm_type   <= "011";  -- U-type immediate

            -- AUIPC (Add Upper Immediate to PC)
            when "0010111" =>
                reg_write  <= '1';
                mem_to_reg <= "00";   -- ALU result
                alu_op     <= "00";   -- ADD (PC + immediate)
                alu_src    <= '1';    -- operand B = immediate
                alu_src_a  <= "01";   -- operand A = PC
                imm_type   <= "011";  -- U-type immediate

            -- Unknown opcode: all signals stay at safe defaults (NOP-like)
            when others =>
                null;

        end case;
    end process;

end behavioral;
