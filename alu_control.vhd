library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- alu_control.vhd

-- Decodes instruction fields into the ALU control signal.
-- The main control unit provides alu_operation_type.
-- refines that into the exact operation the ALU must perform.

entity alu_control is
    port (
        alu_operation_type: in  std_logic_vector(1 downto 0);
        instruction_funct3 :in  std_logic_vector(2 downto 0);
        instruction_funct7 : in  std_logic_vector(6 downto 0);
        alu_control_signal: out std_logic_vector(3 downto 0)
    );
end alu_control;

architecture behavioral of alu_control is
begin
    process(alu_operation_type, instruction_funct3, instruction_funct7)
    begin


        -- by default we do ADD
        alu_control_signal <= "0000";

        case alu_operation_type is

            -- Used for loads/stores and immediate addrs
            when "00" =>
                alu_control_signal <= "0000";  -- ADD

            -- for branch comparings
            when "01" =>
                alu_control_signal <= "0001";  -- SUB

            -- Use of funct3 and funct7 in the RISC addr
            when "10" =>
                case instruction_funct3 is

                    when "000" =>
                        case instruction_funct7 is
                            when "0000000" =>
                                alu_control_signal <= "0000";-- addition
                            when "0100000" =>
                                alu_control_signal <= "0001";-- susbstraction
                            when "0000001" =>
                                alu_control_signal <= "1010";-- multiplcation
                            when others =>
                                alu_control_signal <= "0000";
                        end case;
                    when "001" =>
                        alu_control_signal <= "0101";-- Shift left logical 

                    when "010" =>
                        alu_control_signal <= "1000";-- if less than

                    when "011" =>
                        alu_control_signal <= "1001";-- if LT unsigned

                    when "100" =>
                        alu_control_signal <= "0100";-- XOR

                    when "101" =>
                        case instruction_funct7 is
                            when "0000000" =>
                                alu_control_signal <= "0110";  -- Shift right logical
                            when "0100000" =>
                                alu_control_signal <= "0111";  -- S-R Arithmetic
                            when others =>
                                alu_control_signal <= "0000";
                        end case;
                    when "110" =>
                        alu_control_signal <= "0011";-- OR

                    when "111" =>
                        alu_control_signal <= "0010"; -- AND

                    when others =>
                        alu_control_signal <= "0000";

                end case;
            when others =>
                alu_control_signal <= "0000";
        end case;
    end process;

end behavioral;