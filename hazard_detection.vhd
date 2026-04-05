library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- hazard_detection.vhd
-- Detects data hazards in the RISC-V pipelined processor and
-- generates a stall signal when a required operand is not yet
-- available from a preceding instruction.
--
-- Since forwarding is NOT implemented (per spec), the unit must
-- stall whenever the instruction in ID reads a register that is
-- still being produced by an instruction in EX or MEM.
--
-- When stall = '1', cpu.vhd must:
--   1. Hold the PC (do not update)
--   2. Hold the IF/ID register (do not latch new instruction)
--   3. Insert a NOP bubble into the ID/EX register
--      (zero all control signals = addi x0, x0, 0)
--   4. EX/MEM and MEM/WB continue advancing normally so the
--      producing instruction moves toward WB.
--
-- The stall naturally resolves after the producing instruction
-- clears MEM and its result is written back in WB.

entity hazard_detection is
    port (
        -- Source register addresses from the instruction in ID (IF/ID)
        if_id_rs1        : in  std_logic_vector(4 downto 0);
        if_id_rs2        : in  std_logic_vector(4 downto 0);
        -- Destination register and write-enable from instruction in EX (ID/EX)
        id_ex_rd         : in  std_logic_vector(4 downto 0);
        id_ex_reg_write  : in  std_logic;
        -- Destination register and write-enable from instruction in MEM (EX/MEM)
        ex_mem_rd        : in  std_logic_vector(4 downto 0);
        ex_mem_reg_write : in  std_logic;
        -- Stall output: '1' = stall the pipeline (hold PC, hold IF/ID, bubble ID/EX)
        stall            : out std_logic
    );
end hazard_detection;

architecture behavioral of hazard_detection is
begin

    process(if_id_rs1, if_id_rs2, id_ex_rd, id_ex_reg_write,
            ex_mem_rd, ex_mem_reg_write)

        variable ex_hazard  : boolean;
        variable mem_hazard : boolean;

    begin
        ex_hazard  := false;
        mem_hazard := false;

        -- Check for EX-stage hazard:
        -- The instruction in EX will produce a result that ID needs.
        if id_ex_reg_write = '1' and unsigned(id_ex_rd) /= 0 then
            if id_ex_rd = if_id_rs1 or id_ex_rd = if_id_rs2 then
                ex_hazard := true;
            end if;
        end if;

        -- Check for MEM-stage hazard:
        -- The instruction in MEM will produce a result that ID needs.
        if ex_mem_reg_write = '1' and unsigned(ex_mem_rd) /= 0 then
            if ex_mem_rd = if_id_rs1 or ex_mem_rd = if_id_rs2 then
                mem_hazard := true;
            end if;
        end if;

        -- Stall when either hazard exists
        if ex_hazard or mem_hazard then
            stall <= '1';
        else
            stall <= '0';
        end if;

    end process;

end behavioral;
