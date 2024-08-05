library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_generator is
    Port ( 
        clk_in : in STD_LOGIC;
        rst : in STD_LOGIC;
        clk_out : out STD_LOGIC
    );
end clock_generator;

architecture Behavioral of clock_generator is
    signal counter : unsigned(7 downto 0) := (others => '0');
    signal clk_internal : STD_LOGIC := '0';
begin
    process(clk_in, rst)
    begin
        if rst = '1' then
            counter <= (others => '0');
            clk_internal <= '0';
        elsif rising_edge(clk_in) then
            if counter = 49 then  -- Divide by 50 for 1MHz CAN clock (assuming 50MHz input)
                counter <= (others => '0');
                clk_internal <= not clk_internal;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    clk_out <= clk_internal;

end Behavioral;
