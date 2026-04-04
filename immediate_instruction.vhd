library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- immediate_instruction.vhd
-- Extracts the immediate value from a 32-bit RISC-V instruction
-- Immediate format depends on the instruction type.

entity immediate_instruction is
    port (
        instruct : in std_logic_vector(31 downto 0);
        immediate_selector : in std_logic_vector(2 downto 0);
        immediate_value :out std_logic_vector(31 downto 0);
    );
end immediate_instruction;

architecture behavioral of immediate_instruction is
begin

    process(instruct, immediate_selector)
   -- Temp variable used to construct the immediate
        variable temporary_imm : std_logic_vector(31 downto 0);

    begin
        temporary_imm := (others => '0');
        case immediate_selector is
            --"000"= I-type
            -- I-type immediate (jalr, addi,lw)
              when "000" =>
                temporary_imm(11 downto 0) := instruct(31 downto 20);
                temporary_imm(31 downto 12) := (others => instruct(31));
            
            -- "001"= S-type
            -- S-type immediate (store)
              when "001" =>
              
                temporary_imm(4 downto 0):= instruct(11 downto 7);
                temporary_imm(11 downto 5) := instruct(31 downto 25);
                temporary_imm(31 downto 12) := (others => instruct(31));

            -- "010" = B-type
            -- B-type immediate (branch)
              when "010" =>
              
                temporary_imm(0) := '0';
                temporary_imm(4 downto 1) := instruct(11 downto 8);
                temporary_imm(10 downto 5):= instruct(30 downto 25);
                temporary_imm(11) := instruct(7);
                temporary_imm(12) := instruct(31);
                temporary_imm(31 downto 13):= (others => instruct(31));

            -- "011" = U-type
            -- U-type immediate (auipc, lui)
              when "011" =>
              
                temporary_imm(11 downto 0)  := (others => '0');
                temporary_imm(31 downto 12) := instruct(31 downto 12);

            -- "100" = J-type
            -- J-type immediate (jal)
              when "100" =>
              
                temporary_imm(0)  := '0';
                temporary_imm(10 downto 1) := instruct(30 downto 21);
                temporary_imm(11) := instruct(20);
                temporary_imm(19 downto 12) := instruct(19 downto 12);
                temporary_imm(20) := instruct(31);
                temporary_imm(31 downto 21) := (others => instruct(31));

            when others =>
                temporary_imm :=(others => '0');
        end case;
        immediate_value <= temporary_imm;
    end process;

end behavioral;