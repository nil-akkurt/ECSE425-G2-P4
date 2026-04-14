library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_detection is
    port (
        if_id_rs1        : in  std_logic_vector(4 downto 0);
        if_id_rs2        : in  std_logic_vector(4 downto 0);
        id_ex_rd         : in  std_logic_vector(4 downto 0);
        id_ex_reg_write  : in  std_logic;
        ex_mem_rd        : in  std_logic_vector(4 downto 0);
        ex_mem_reg_write : in  std_logic;
        mem_wb_rd        : in  std_logic_vector(4 downto 0);
        mem_wb_reg_write : in  std_logic;
        stall            : out std_logic
    );
end hazard_detection;

architecture behavioral of hazard_detection is
begin

    process(if_id_rs1, if_id_rs2, id_ex_rd, id_ex_reg_write,
            ex_mem_rd, ex_mem_reg_write, mem_wb_rd, mem_wb_reg_write)

        variable ex_hazard  : boolean;
        variable mem_hazard : boolean;
        variable wb_hazard  : boolean;

    begin
        ex_hazard  := false;
        mem_hazard := false;
        wb_hazard  := false;

        -- Stall when instruction in EX will write a reg that ID needs
        if id_ex_reg_write = '1' and unsigned(id_ex_rd) /= 0 then
            if id_ex_rd = if_id_rs1 or id_ex_rd = if_id_rs2 then
                ex_hazard := true;
            end if;
        end if;

        -- Stall when instruction in MEM will write a reg that ID needs
        if ex_mem_reg_write = '1' and unsigned(ex_mem_rd) /= 0 then
            if ex_mem_rd = if_id_rs1 or ex_mem_rd = if_id_rs2 then
                mem_hazard := true;
            end if;
        end if;

        -- Stall when instruction in WB will write a reg that ID needs
        if mem_wb_reg_write = '1' and unsigned(mem_wb_rd) /= 0 then
            if mem_wb_rd = if_id_rs1 or mem_wb_rd = if_id_rs2 then
                wb_hazard := true;
            end if;
        end if;

        if ex_hazard or mem_hazard or wb_hazard then
            stall <= '1';
        else
            stall <= '0';
        end if;

    end process;

end behavioral;
