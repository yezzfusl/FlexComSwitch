library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity can_transceiver is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        tx_in : in STD_LOGIC;
        rx_out : out STD_LOGIC;
        can_high : inout STD_LOGIC;
        can_low : inout STD_LOGIC
    );
end can_transceiver;

architecture Behavioral of can_transceiver is
    signal differential : STD_LOGIC;
begin
    -- Transmit logic
    process(clk, rst)
    begin
        if rst = '1' then
            can_high <= 'Z';
            can_low <= 'Z';
        elsif rising_edge(clk) then
            if tx_in = '0' then
                can_high <= '1';
                can_low <= '0';
            else
                can_high <= 'Z';
                can_low <= 'Z';
            end if;
        end if;
    end process;

    -- Receive logic
    differential <= can_high xor can_low;
    rx_out <= differential;

end Behavioral;
