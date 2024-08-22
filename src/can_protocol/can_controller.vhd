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
        bit_time : in STD_LOGIC_VECTOR(15 downto 0);
        -- New ports
        tx_request : in STD_LOGIC;
        tx_done : out STD_LOGIC;
        rx_busy : out STD_LOGIC;
        error_flag : out STD_LOGIC;
        bus_off : out STD_LOGIC;
        extended_id : in STD_LOGIC;
        remote_frame : in STD_LOGIC;
        id_in : in STD_LOGIC_VECTOR(28 downto 0);
        id_out : out STD_LOGIC_VECTOR(28 downto 0);
        dlc_in : in STD_LOGIC_VECTOR(3 downto 0);
        dlc_out : out STD_LOGIC_VECTOR(3 downto 0)
    );
end can_controller;

architecture Behavioral of can_controller is
    type can_state_type is (IDLE, ARBITRATION, CONTROL, DATA, CRC, ACK, EOF, ERROR, BUS_OFF, TRANSMIT);
    signal state : can_state_type := IDLE;
    signal bit_counter : integer range 0 to 127 := 0;
    signal crc : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
    signal crc_calc : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
    
    -- CAN frame components
    signal arbitration_field : STD_LOGIC_VECTOR(28 downto 0);
    signal control_field : STD_LOGIC_VECTOR(5 downto 0);
    signal data_field : STD_LOGIC_VECTOR(63 downto 0);
    
    -- Additional signals
    signal error_counter : unsigned(7 downto 0) := (others => '0');
    signal bit_stuff_counter : unsigned(2 downto 0) := (others => '0');
    signal last_bit : STD_LOGIC := '0';
    signal stuff_error : STD_LOGIC := '0';
    signal crc_error : STD_LOGIC := '0';
    signal form_error : STD_LOGIC := '0';
    signal ack_error : STD_LOGIC := '0';
    signal tx_buffer : STD_LOGIC_VECTOR(127 downto 0);
    signal tx_bit_counter : integer range 0 to 127 := 0;
    signal is_transmitting : STD_LOGIC := '0';
    
    -- CRC calculation function
    function update_crc(crc_in : STD_LOGIC_VECTOR(14 downto 0); data_in : STD_LOGIC) return STD_LOGIC_VECTOR is
        variable crc_out : STD_LOGIC_VECTOR(14 downto 0);
    begin
        crc_out := crc_in(13 downto 0) & data_in;
        if crc_in(14) /= data_in then
            crc_out := crc_out xor "100010110011001";
        end if;
        return crc_out;
    end function;

begin
    process(clk, rst)
        variable next_bit : STD_LOGIC;
    begin
        if rst = '1' then
            state <= IDLE;
            bit_counter <= 0;
            crc <= (others => '0');
            tx <= '1';
            data_valid <= '0';
            error_flag <= '0';
            bus_off <= '0';
            error_counter <= (others => '0');
            rx_busy <= '0';
            tx_done <= '0';
            is_transmitting <= '0';
        elsif rising_edge(clk) then
            if sync = '1' then
                case state is
                    when IDLE =>
                        rx_busy <= '0';
                        if tx_request = '1' and is_transmitting = '0' then
                            state <= TRANSMIT;
                            is_transmitting <= '1';
                            tx_buffer <= id_in & dlc_in & data_in & x"00000000"; -- Prepare transmit buffer
                            tx_bit_counter <= 0;
                        elsif rx = '0' then  -- Start of Frame detected
                            state <= ARBITRATION;
                            bit_counter <= 0;
                            crc_calc <= (others => '0');
                            rx_busy <= '1';
                        end if;
                    
                    when ARBITRATION =>
                        if (extended_id = '0' and bit_counter < 11) or (extended_id = '1' and bit_counter < 29) then
                            arbitration_field(28 - bit_counter) <= rx;
                            bit_counter <= bit_counter + 1;
                            crc_calc <= update_crc(crc_calc, rx);
                        else
                            state <= CONTROL;
                            bit_counter <= 0;
                        end if;
                    
                    when CONTROL =>
                        if bit_counter < 6 then
                            control_field(5 - bit_counter) <= rx;
                            bit_counter <= bit_counter + 1;
                            crc_calc <= update_crc(crc_calc, rx);
                        else
                            state <= DATA;
                            bit_counter <= 0;
                        end if;
                    
                    when DATA =>
                        if bit_counter < to_integer(unsigned(control_field(3 downto 0))) * 8 then
                            data_field(63 - bit_counter) <= rx;
                            bit_counter <= bit_counter + 1;
                            crc_calc <= update_crc(crc_calc, rx);
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
                            if crc /= crc_calc then
                                crc_error <= '1';
                            end if;
                        end if;
                    
                    when ACK =>
                        if bit_counter = 0 then
                            tx <= '0';  -- Send ACK
                            bit_counter <= bit_counter + 1;
                        elsif bit_counter = 1 then
                            tx <= '1';  -- ACK delimiter
                            bit_counter <= 0;
                            state <= EOF;
                            if rx = '1' then
                                ack_error <= '1';
                            end if;
                        end if;
                    
                    when EOF =>
                        if bit_counter < 7 then
                            if rx /= '1' then
                                form_error <= '1';
                            end if;
                            bit_counter <= bit_counter + 1;
                        else
                            state <= IDLE;
                            bit_counter <= 0;
                            data_out <= data_field;
                            id_out <= arbitration_field;
                            dlc_out <= control_field(3 downto 0);
                            data_valid <= '1';
                        end if;
                    
                    when ERROR =>
                        if bit_counter < 6 then
                            tx <= '0';  -- Transmit error flag
                            bit_counter <= bit_counter + 1;
                        else
                            state <= IDLE;
                            bit_counter <= 0;
                            error_counter <= error_counter + 1;
                            if error_counter = 255 then
                                state <= BUS_OFF;
                            end if;
                        end if;
                    
                    when BUS_OFF =>
                        bus_off <= '1';
                        if error_counter = 0 then
                            state <= IDLE;
                            bus_off <= '0';
                        end if;
                    
                    when TRANSMIT =>
                        if tx_bit_counter < 128 then
                            tx <= tx_buffer(127 - tx_bit_counter);
                            tx_bit_counter <= tx_bit_counter + 1;
                        else
                            state <= IDLE;
                            is_transmitting <= '0';
                            tx_done <= '1';
                        end if;
                
                end case;

                -- Bit stuffing
                if state /= IDLE and state /= ERROR and state /= BUS_OFF and state /= TRANSMIT then
                    if rx = last_bit then
                        bit_stuff_counter <= bit_stuff_counter + 1;
                        if bit_stuff_counter = 5 then
                            stuff_error <= '1';
                        end if;
                    else
                        bit_stuff_counter <= (others => '0');
                    end if;
                    last_bit <= rx;
                end if;

                -- Error handling
                if stuff_error = '1' or crc_error = '1' or form_error = '1' or ack_error = '1' then
                    state <= ERROR;
                    error_flag <= '1';
                    stuff_error <= '0';
                    crc_error <= '0';
                    form_error <= '0';
                    ack_error <= '0';
                end if;

            end if;
        end if;
    end process;

    -- Error counter management
    process(clk, rst)
    begin
        if rst = '1' then
            error_counter <= (others => '0');
        elsif rising_edge(clk) then
            if state = ERROR then
                if error_counter < 255 then
                    error_counter <= error_counter + 1;
                end if;
            elsif state = IDLE and error_counter > 0 then
                error_counter <= error_counter - 1;
            end if;
        end if;
    end process;

end Behavioral;
