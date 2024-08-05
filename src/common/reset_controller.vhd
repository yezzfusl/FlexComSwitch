library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reset_controller is
    Port ( 
        clk : in STD_LOGIC;
        ext_rst : in STD_LOGIC;
        rst_out : out STD_LOGIC
    );
end reset_controller;

architecture Behavioral of reset_controller is
    signal reset_shift_reg : STD_LOGIC_VECTOR(3 downto 0) := (others => '1');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            reset_shift_reg <= reset_shift_reg(2 downto 0) & ext_rst;
        end if;
    end process;

    rst_out <= '1' when reset_shift_reg = "1111" else '0';

end Behavioral;
