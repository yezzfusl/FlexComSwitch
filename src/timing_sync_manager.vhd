library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity timing_sync_manager is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        protocol_select : in STD_LOGIC_VECTOR(1 downto 0);
        can_sync : out STD_LOGIC;
        lin_sync : out STD_LOGIC;
        flexray_sync : out STD_LOGIC;
        can_bit_time : out STD_LOGIC_VECTOR(15 downto 0);
        lin_bit_time : out STD_LOGIC_VECTOR(15 downto 0);
        flexray_cycle_time : out STD_LOGIC_VECTOR(31 downto 0)
    );
end timing_sync_manager;

architecture Behavioral of timing_sync_manager is
    constant CAN_BIT_TIME : unsigned(15 downto 0) := to_unsigned(1000, 16); -- 1us for 1Mbps
    constant LIN_BIT_TIME : unsigned(15 downto 0) := to_unsigned(50000, 16); -- 50us for 20kbps
    constant FLEXRAY_CYCLE_TIME : unsigned(31 downto 0) := to_unsigned(5000000, 32); -- 5ms cycle time

    signal can_counter : unsigned(15 downto 0) := (others => '0');
    signal lin_counter : unsigned(15 downto 0) := (others => '0');
    signal flexray_counter : unsigned(31 downto 0) := (others => '0');

begin
    process(clk, rst)
    begin
        if rst = '1' then
            can_counter <= (others => '0');
            lin_counter <= (others => '0');
            flexray_counter <= (others => '0');
            can_sync <= '0';
            lin_sync <= '0';
            flexray_sync <= '0';
        elsif rising_edge(clk) then
            -- CAN timing
            if can_counter = CAN_BIT_TIME - 1 then
                can_counter <= (others => '0');
                can_sync <= '1';
            else
                can_counter <= can_counter + 1;
                can_sync <= '0';
            end if;

            -- LIN timing
            if lin_counter = LIN_BIT_TIME - 1 then
                lin_counter <= (others => '0');
                lin_sync <= '1';
            else
                lin_counter <= lin_counter + 1;
                lin_sync <= '0';
            end if;

            -- FlexRay timing
            if flexray_counter = FLEXRAY_CYCLE_TIME - 1 then
                flexray_counter <= (others => '0');
                flexray_sync <= '1';
            else
                flexray_counter <= flexray_counter + 1;
                flexray_sync <= '0';
            end if;
        end if;
    end process;

    can_bit_time <= std_logic_vector(CAN_BIT_TIME);
    lin_bit_time <= std_logic_vector(LIN_BIT_TIME);
    flexray_cycle_time <= std_logic_vector(FLEXRAY_CYCLE_TIME);

end Behavioral;
