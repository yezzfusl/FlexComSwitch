library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity flexray_controller is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        rx : in STD_LOGIC;
        tx : out STD_LOGIC;
        data_in : in STD_LOGIC_VECTOR(63 downto 0);
        data_out : out STD_LOGIC_VECTOR(63 downto 0);
        data_valid : out STD_LOGIC
    );
end flexray_controller;

architecture Behavioral of flexray_controller is
    type flexray_state_type is (IDLE, HEADER, PAYLOAD, TRAILER);
    signal state : flexray_state_type := IDLE;
    signal bit_counter : integer range 0 to 255 := 0;
    signal byte_counter : integer range 0 to 254 := 0;
    signal shift_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal header : STD_LOGIC_VECTOR(39 downto 0) := (others => '0');
    signal payload : STD_LOGIC_VECTOR(2032 downto 0) := (others => '0');
    signal crc : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');

    constant TSS : STD_LOGIC_VECTOR(7 downto 0) := x"AA";
    constant FSS : STD_LOGIC_VECTOR(7 downto 0) := x"55";
    
begin
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
            bit_counter <= 0;
            byte_counter <= 0;
            shift_reg <= (others => '0');
            header <= (others => '0');
            payload <= (others => '0');
            crc <= (others => '0');
            tx <= '1';
            data_valid <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if rx = '0' then -- Start of frame detected
                        state <= HEADER;
                        bit_counter <= 0;
                        byte_counter <= 0;
                    end if;

                when HEADER =>
                    if bit_counter < 8 then
                        shift_reg <= shift_reg(6 downto 0) & rx;
                        bit_counter <= bit_counter + 1;
                    else
                        if byte_counter = 0 and shift_reg /= TSS then
                            state <= IDLE;
                        elsif byte_counter = 1 and shift_reg /= FSS then
                            state <= IDLE;
                        else
                            header((4-byte_counter)*8+7 downto (4-byte_counter)*8) <= shift_reg;
                            byte_counter <= byte_counter + 1;
                            bit_counter <= 0;
                            if byte_counter = 4 then
                                state <= PAYLOAD;
                                byte_counter <= 0;
                            end if;
                        end if;
                    end if;

                when PAYLOAD =>
                    if bit_counter < 8 then
                        shift_reg <= shift_reg(6 downto 0) & rx;
                        bit_counter <= bit_counter + 1;
                    else
                        payload((253-byte_counter)*8+7 downto (253-byte_counter)*8) <= shift_reg;
                        byte_counter <= byte_counter + 1;
                        bit_counter <= 0;
                        if byte_counter = 253 then
                            state <= TRAILER;
                            byte_counter <= 0;
                        end if;
                    end if;

                when TRAILER =>
                    if bit_counter < 8 then
                        shift_reg <= shift_reg(6 downto 0) & rx;
                        bit_counter <= bit_counter + 1;
                    else
                        if byte_counter < 3 then
                            crc((2-byte_counter)*8+7 downto (2-byte_counter)*8) <= shift_reg;
                            byte_counter <= byte_counter + 1;
                            bit_counter <= 0;
                        else
                            -- Verify CRC (simplified)
                            if crc = x"AAAAAA" then -- Example CRC
                                data_out <= payload(63 downto 0);
                                data_valid <= '1';
                            end if;
                            state <= IDLE;
                        end if;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;
