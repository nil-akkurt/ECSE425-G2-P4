library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- if_id_reg.vhd
-- Pipeline register between IF and ID stages.
-- Stores the fetched instruction and associated PC value
-- Behavior:
--  If reset: clears contents to NOP / zero
--  If flush : inserts NOP / zero
--  If if_id_write_enable = '1' then latches new IF-stage values (no stall)
--  If if_id_write_enable = '0'then holds current contents (stall)

entity if_id_reg is
	port (
		clk            : in  std_logic;
      reset          : in  std_logic;
      if_id_write_enable   : in  std_logic;
      flush          : in  std_logic;

      if_pc          : in  std_logic_vector(31 downto 0);
      if_pc_plus4    : in  std_logic_vector(31 downto 0);
      if_instruction : in  std_logic_vector(31 downto 0);

      id_pc          : out std_logic_vector(31 downto 0);
      id_pc_plus4    : out std_logic_vector(31 downto 0);
      id_instruction : out std_logic_vector(31 downto 0));
end if_id_reg;

architecture behavioral of if_id_reg is

	-- NOP = addi x0, x0, 0
   constant NOP : std_logic_vector(31 downto 0) := x"00000013";

   signal pc_reg          : std_logic_vector(31 downto 0) := (others => '0');
   signal pc_plus4_reg    : std_logic_vector(31 downto 0) := (others => '0');
   signal instruction_reg : std_logic_vector(31 downto 0) := NOP;

begin

   process(clk)
   begin
		if rising_edge(clk) then
			if reset = '1' then
				pc_reg          <= (others => '0');
            pc_plus4_reg    <= (others => '0');
            instruction_reg <= NOP;

			elsif flush = '1' then
				pc_reg          <= (others => '0');
            pc_plus4_reg    <= (others => '0');
            instruction_reg <= NOP;

         elsif if_id_write_enable = '1' then
				pc_reg          <= if_pc;
            pc_plus4_reg    <= if_pc_plus4;
            instruction_reg <= if_instruction;

         end if;
		end if;
	end process;

   id_pc          <= pc_reg;
   id_pc_plus4    <= pc_plus4_reg;
   id_instruction <= instruction_reg;

end behavioral;