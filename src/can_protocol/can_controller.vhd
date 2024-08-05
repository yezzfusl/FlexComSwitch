library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity can_controller is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        rx : in STD_LOGIC;
        tx : out STD_LOGIC;
        data_in : in STD_LOGIC_VECTOR(63 downto 0);
        data_out : out STD_LOGIC_VECTOR(63 downto 0);
        data_valid : out STD_LOGIC;
        sync : in STD_LOGIC;
        bit_time : in STD_LOGIC_VECTOR(15 downto 0)
    );
end can_controller;

architecture Behavioral of can_controller is
    type can_state_type is (IDLE, ARBITRATION, CONTROL, DATA, CRC, ACK, EOF);
    signal state : can_state_type := IDLE;
    signal bit_counter : integer range 0 to 127 := 0;
    signal crc : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
    
    -- CAN frame components
    signal arbitration_field : STD_LOGIC_VECTOR(11 downto 0);
    signal control_field : STD_LOGIC_VECTOR(5 downto 0);
    signal data_field : STD_LOGIC_VECTOR(63 downto 0);
    
begin
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
            bit_counter <= 0;
            crc <= (others => '0');
            tx <= '1';
            data_valid <= '0';
        elsif rising_edge(clk) and sync = '1' then
            case state is
                when IDLE =>
                    if rx = '0' then  -- Start of Frame detected
                        state <= ARBITRATION;
                        bit_counter <= 0;
                    end if;
                
                when ARBITRATION =>
                    if bit_counter < 11 then
                        arbitration_field(11 - bit_counter) <= rx;
                        bit_counter <= bit_counter + 1;
                    else
                        state <= CONTROL;
                        bit_counter <= 0;
                    end if;
                
                when CONTROL =>
                    if bit_counter < 6 then
                        control_field(5 - bit_counter) <= rx;
                        bit_counter <= bit_counter + 1;
                    else
                        state <= DATA;
                        bit_counter <= 0;
                    end if;
                
                when DATA =>
                    if bit_counter < 64 then
                        data_field(63 - bit_counter) <= rx;
                        bit_counter <= bit_counter + 1;
                    else
                        state <= CRC;
                        bit_counter <= 0;
                    end if;
                
                when CRC =>
                    if bit_counter < 15 then
                        crc(14 - bit_counter) <= rx;
                        bit_counter <= bit_counter + 1;
                    else
                        state <= ACK;
                        bit_counter <= 0;
                    end if;
                
                when ACK =>
                    if bit_counter = 0 then
                        tx <= '0';  -- Send ACK
                        bit_counter <= bit_counter + 1;
                    elsif bit_counter = 1 then
                        tx <= '1';  -- ACK delimiter
                        bit_counter <= 0;
                        state <= EOF;
                    end if;
                
                when EOF =>
                    if bit_counter < 7 then
                        bit_counter <= bit_counter + 1;
                    else
                        state <= IDLE;
                        bit_counter <= 0;
                        data_out <= data_field;
                        data_valid <= '1';
                    end if;
            end case;
        end if;
    end process;

end Behavioral;
