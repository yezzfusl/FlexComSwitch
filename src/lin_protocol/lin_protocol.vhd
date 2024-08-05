library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lin_controller is
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
end lin_controller;

architecture Behavioral of lin_controller is
    type lin_state_type is (IDLE, SYNC, IDENTIFIER, DATA, CHECKSUM);
    signal state : lin_state_type := IDLE;
    signal bit_counter : integer range 0 to 63 := 0;
    signal byte_counter : integer range 0 to 8 := 0;
    signal shift_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal identifier : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
    signal data_buffer : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
    signal checksum : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

    constant SYNC_BYTE : STD_LOGIC_VECTOR(7 downto 0) := x"55";
    
begin
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
            bit_counter <= 0;
            byte_counter <= 0;
            shift_reg <= (others => '0');
            identifier <= (others => '0');
            data_buffer <= (others => '0');
            checksum <= (others => '0');
            tx <= '1';
            data_valid <= '0';
        elsif rising_edge(clk) and sync = '1' then
            case state is
                when IDLE =>
                    tx <= '1';
                    if rx = '0' then -- Start bit detected
                        state <= SYNC;
                        bit_counter <= 0;
                    end if;

                when SYNC =>
                    if bit_counter < 8 then
                        shift_reg <= shift_reg(6 downto 0) & rx;
                        bit_counter <= bit_counter + 1;
                    else
                        if shift_reg = SYNC_BYTE then
                            state <= IDENTIFIER;
                            bit_counter <= 0;
                        else
                            state <= IDLE;
                        end if;
                    end if;

                when IDENTIFIER =>
                    if bit_counter < 6 then
                        identifier <= identifier(4 downto 0) & rx;
                        bit_counter <= bit_counter + 1;
                    else
                        state <= DATA;
                        bit_counter <= 0;
                        byte_counter <= 0;
                    end if;

                when DATA =>
                    if bit_counter < 8 then
                        shift_reg <= shift_reg(6 downto 0) & rx;
                        bit_counter <= bit_counter + 1;
                    else
                        data_buffer((7-byte_counter)*8+7 downto (7-byte_counter)*8) <= shift_reg;
                        byte_counter <= byte_counter + 1;
                        bit_counter <= 0;
                        if byte_counter = 7 then
                            state <= CHECKSUM;
                        end if;
                    end if;

                when CHECKSUM =>
                    if bit_counter < 8 then
                        checksum <= checksum(6 downto 0) & rx;
                        bit_counter <= bit_counter + 1;
                    else
                        -- Verify checksum (simplified)
                        if checksum = x"AA" then -- Example checksum
                            data_out <= data_buffer;
                            data_valid <= '1';
                        end if;
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;
