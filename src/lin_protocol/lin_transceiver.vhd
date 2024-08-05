library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lin_transceiver is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        tx_in : in STD_LOGIC;
        rx_out : out STD_LOGIC;
        lin_bus : inout STD_LOGIC
    );
end lin_transceiver;

architecture Behavioral of lin_transceiver is
    signal tx_buf : STD_LOGIC;
begin
    -- Transmit logic
    process(clk, rst)
    begin
        if rst = '1' then
            lin_bus <= 'H'; -- High-impedance state
            tx_buf <= '1';
        elsif rising_edge(clk) then
            tx_buf <= tx_in;
            if tx_buf = '0' then
                lin_bus <= '0';
            else
                lin_bus <= 'H'; -- Pull-up resistor will pull the bus high
            end if;
        end if;
    end process;

    -- Receive logic
    rx_out <= lin_bus;

end Behavioral;
