library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_level is
    Port ( 
        clk_50m : in STD_LOGIC;
        ext_rst : in STD_LOGIC;
        can_rx : in STD_LOGIC;
        can_tx : out STD_LOGIC;
        data_in : in STD_LOGIC_VECTOR(63 downto 0);
        data_out : out STD_LOGIC_VECTOR(63 downto 0);
        data_valid : out STD_LOGIC
    );
end top_level;

architecture Behavioral of top_level is
    signal clk_1m : STD_LOGIC;
    signal rst : STD_LOGIC;
    signal can_rx_internal, can_tx_internal : STD_LOGIC;

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
            data_out => data_out,
            data_valid => data_valid
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

end Behavioral;
