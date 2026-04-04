library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- alu.vhd
-- Executes arithmetic and logical operations for the processor.
-- The operation performed depends on ALU_ctrl.

entity alu is
    port (
        value_a : in std_logic_vector(31 downto 0);
        value_b : in std_logic_vector(31 downto 0);
        ALU_ctrl : in std_logic_vector(3 downto 0);
        result : out std_logic_vector(31 downto 0);
        zero : out std_logic
    );
end alu;

architecture behavioral of alu is
begin

    process(value_a, value_b, ALU_ctrl)
        -- Signed && unsigned interpretation of the input
        variable value_a_signed : signed(31 downto 0);
        variable value_a_unsigned : unsigned(31 downto 0);
        variable value_b_signed   : signed(31 downto 0);
        variable value_b_unsigned : unsigned(31 downto 0);
        -- Temporary variable with the ALU result
        variable temporary_result : std_logic_vector(31 downto 0);
        -- Shift value -> lower 5 bits of value_b
        variable shift_amt : integer range 0 to 31;

    begin
        value_a_signed := signed(value_a);
        value_a_unsigned := unsigned(value_a);
        
        value_b_signed:= signed(value_b);
        value_b_unsigned := unsigned(value_b);

        shift_amt:= to_integer(unsigned(value_b(4 downto 0)));

        temporary_result := (others => '0');

        case ALU_ctrl is
            -- ADD
            when "0000" => 
                temporary_result :=
                    std_logic_vector(value_a_signed+value_b_signed);
            -- SUB
            when "0001" => 
                temporary_result :=
                    std_logic_vector(value_a_signed-value_b_signed);
            -- AND
            when "0010" => 
                temporary_result := value_a and value_b;
            -- OR
            when "0011" => 
                temporary_result := value_a or value_b;
            -- XOR
            when "0100" => 
                temporary_result := value_a xor value_b;
            -- SLL
            when "0101" => 
                temporary_result :=
                    std_logic_vector(shift_left(value_a_unsigned, shift_amt));
            -- SRL
            when "0110" => 
                temporary_result :=
                    std_logic_vector(shift_right(value_a_unsigned, shift_amt));
            -- SRA
            when "0111" => 
                temporary_result :=
                    std_logic_vector(shift_right(value_a_signed, shift_amt));
          -- SLT (signed comparing)
            when "1000" => 
                if value_a_signed < value_b_signed then
                    temporary_result := x"00000001";
                else
                    temporary_result := x"00000000";
                end if;
            -- SLTU (unsigned compare)
            when "1001" => 
                if value_a_unsigned < value_b_unsigned then
                    temporary_result := x"00000001";
                else
                    temporary_result := x"00000000";
                end if;
           -- MUL
            when "1010" => 
                temporary_result :=
                    std_logic_vector(resize(value_a_signed * value_b_signed, 32));

            when others =>
                temporary_result := (others => '0');

        end case;

        result <= temporary_result;

        -- Zero flag for branch comparisons
        if temporary_result = x"00000000" then
            zero <= '1';
        else
            zero <= '0';
        end if;

    end process;

end behavioral;