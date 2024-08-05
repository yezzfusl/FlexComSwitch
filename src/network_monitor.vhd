library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity network_monitor is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        can_rx : in STD_LOGIC;
        lin_rx : in STD_LOGIC;
        flexray_rx : in STD_LOGIC;
        protocol_select : out STD_LOGIC_VECTOR(1 downto 0)
    );
end network_monitor;

architecture Behavioral of network_monitor is
    type monitor_state_type is (IDLE, CAN_DETECT, LIN_DETECT, FLEXRAY_DETECT);
    signal state : monitor_state_type := IDLE;
    signal counter : unsigned(15 downto 0) := (others => '0');
    signal can_activity, lin_activity, flexray_activity : STD_LOGIC := '0';
    
    constant TIMEOUT : unsigned(15 downto 0) := to_unsigned(10000, 16); -- Adjust as needed
begin
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
            counter <= (others => '0');
            can_activity <= '0';
            lin_activity <= '0';
            flexray_activity <= '0';
            protocol_select <= "00"; -- Default to CAN
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    counter <= (others => '0');
                    can_activity <= '0';
                    lin_activity <= '0';
                    flexray_activity <= '0';
                    state <= CAN_DETECT;
                
                when CAN_DETECT =>
                    if can_rx = '0' then
                        can_activity <= '1';
                    end if;
                    
                    if counter = TIMEOUT then
                        if can_activity = '1' then
                            protocol_select <= "00";
                            state <= IDLE;
                        else
                            state <= LIN_DETECT;
                            counter <= (others => '0');
                        end if;
                    else
                        counter <= counter + 1;
                    end if;
                
                when LIN_DETECT =>
                    if lin_rx = '0' then
                        lin_activity <= '1';
                    end if;
                    
                    if counter = TIMEOUT then
                        if lin_activity = '1' then
                            protocol_select <= "01";
                            state <= IDLE;
                        else
                            state <= FLEXRAY_DETECT;
                            counter <= (others => '0');
                        end if;
                    else
                        counter <= counter + 1;
                    end if;
                
                when FLEXRAY_DETECT =>
                    if flexray_rx = '0' then
                        flexray_activity <= '1';
                    end if;
                    
                    if counter = TIMEOUT then
                        if flexray_activity = '1' then
                            protocol_select <= "10";
                        else
                            protocol_select <= "00"; -- Default to CAN if no activity detected
                        end if;
                        state <= IDLE;
                    else
                        counter <= counter + 1;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;
