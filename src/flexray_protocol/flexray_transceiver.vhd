library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flexray_transceiver is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        tx_in : in STD_LOGIC;
        rx_out : out STD_LOGIC;
        bus_plus : inout STD_LOGIC;
        bus_minus : inout STD_LOGIC
    );
end flexray_transceiver;

architecture Behavioral of flexray_transceiver is
    signal tx_buf : STD_LOGIC;
begin
    -- Transmit logic
    process(clk, rst)
    begin
        if rst = '1' then
            bus_plus <= 'Z';
            bus_minus <= 'Z';
            tx_buf <= '1';
        elsif rising_edge(clk) then
            tx_buf <= tx_in;
            if tx_buf = '0' then
                bus_plus <= '0';
                bus_minus <= '1';
            else
                bus_plus <= '1';
                bus_minus <= '0';
            end if;
        end if;
    end process;

    -- Receive logic
    rx_out <= '0' when bus_plus = '0' and bus_minus = '1' else '1';

end Behavioral;
