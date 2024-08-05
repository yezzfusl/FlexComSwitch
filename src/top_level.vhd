library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_level is
    Port ( 
        clk_50m : in STD_LOGIC;
        ext_rst : in STD_LOGIC;
        can_rx : in STD_LOGIC;
        can_tx : out STD_LOGIC;
        lin_rx : in STD_LOGIC;
        lin_tx : out STD_LOGIC;
        data_in : in STD_LOGIC_VECTOR(63 downto 0);
        data_out : out STD_LOGIC_VECTOR(63 downto 0);
        data_valid : out STD_LOGIC;
        protocol_select : in STD_LOGIC -- '0' for CAN, '1' for LIN
    );
end top_level;

architecture Behavioral of top_level is
    signal clk_1m : STD_LOGIC;
    signal rst : STD_LOGIC;
    signal can_rx_internal, can_tx_internal : STD_LOGIC;
    signal lin_rx_internal, lin_tx_internal : STD_LOGIC;
    signal can_data_out, lin_data_out : STD_LOGIC_VECTOR(63 downto 0);
    signal can_data_valid, lin_data_valid : STD_LOGIC;

    component clock_generator
        Port ( 
            clk_in : in STD_LOGIC;
            rst : in STD_LOGIC;
            clk_out : out STD_LOGIC
        );
    end component;

    component reset_controller
        Port ( 
            clk : in STD_LOGIC;
            ext_rst : in STD_LOGIC;
            rst_out : out STD_LOGIC
        );
    end component;

    component can_controller
        Port ( 
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            rx : in STD_LOGIC;
            tx : out STD_LOGIC;
            data_in : in STD_LOGIC_VECTOR(63 downto 0);
            data_out : out STD_LOGIC_VECTOR(63 downto 0);
            data_valid : out STD_LOGIC
        );
    end component;

    component can_transceiver
        Port ( 
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            tx_in : in STD_LOGIC;
            rx_out : out STD_LOGIC;
            can_high : inout STD_LOGIC;
            can_low : inout STD_LOGIC
        );
    end component;

    component lin_controller
        Port ( 
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            rx : in STD_LOGIC;
            tx : out STD_LOGIC;
            data_in : in STD_LOGIC_VECTOR(63 downto 0);
            data_out : out STD_LOGIC_VECTOR(63 downto 0);
            data_valid : out STD_LOGIC
        );
    end component;

    component lin_transceiver
        Port ( 
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            tx_in : in STD_LOGIC;
            rx_out : out STD_LOGIC;
            lin_bus : inout STD_LOGIC
        );
    end component;

begin
    clock_gen: clock_generator
        port map (
            clk_in => clk_50m,
            rst => rst,
            clk_out => clk_1m
        );

    reset_ctrl: reset_controller
        port map (
            clk => clk_50m,
            ext_rst => ext_rst,
            rst_out => rst
        );

    can_ctrl: can_controller
        port map (
            clk => clk_1m,
            rst => rst,
            rx => can_rx_internal,
            tx => can_tx_internal,
            data_in => data_in,
            data_out => can_data_out,
            data_valid => can_data_valid
        );

    can_xcvr: can_transceiver
        port map (
            clk => clk_1m,
            rst => rst,
            tx_in => can_tx_internal,
            rx_out => can_rx_internal,
            can_high => can_rx,
            can_low => can_tx
        );

    lin_ctrl: lin_controller
        port map (
            clk => clk_1m,
            rst => rst,
            rx => lin_rx_internal,
            tx => lin_tx_internal,
            data_in => data_in,
            data_out => lin_data_out,
            data_valid => lin_data_valid
        );

    lin_xcvr: lin_transceiver
        port map (
            clk => clk_1m,
            rst => rst,
            tx_in => lin_tx_internal,
            rx_out => lin_rx_internal,
            lin_bus => lin_rx
        );

    -- Protocol selection mux
    process(protocol_select, can_data_out, lin_data_out, can_data_valid, lin_data_valid)
    begin
        if protocol_select = '0' then
            data_out <= can_data_out;
            data_valid <= can_data_valid;
        else
            data_out <= lin_data_out;
            data_valid <= lin_data_valid;
        end if;
    end process;

end Behavioral;
