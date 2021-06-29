-- Module: I2S receiver/transmitter 
-- Author: Laura Regan
-- Data: 1/11/2020
-- Description: Receiver and transmitter module that implements the Phillips I2S
-- protocol. Capable of using different  master clock and sampling frequencies.
--
-- ToDo: Modify module to allow for 32 bit data width

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2s is
    generic(
        MCLK_LRCK_RATIO : integer := 384;   -- mclk to lrck ratio
        SCLK_LRCK_RATIO : integer := 48;    -- sclk to lrck ratio
        DBIT            : integer := 24     -- # of data bits
    );
    port(
        mclk      : in std_logic;       -- master clock: 384 * 48 kHz = 18.432 Mhz
        reset     : in std_logic;       -- async reset
        sclk      : out std_logic;      -- continuous serial clock: 48 kHz * 24 * 2 = 2.304 Mhz
        lrck      : out std_logic;      -- left/right clock: 48 kHz (Sample rate)
        sdata_tx  : out std_logic;      -- serial data out
        sdata_rx  : in std_logic;       -- serial data in
        data_tx_left  : in std_logic_vector(DBIT-1 downto 0);   -- left channel data in
        data_tx_right : in std_logic_vector(DBIT-1 downto 0);   -- right channel data in
        data_rx_left  : out std_logic_vector(DBIT-1 downto 0);  -- left channel data out
        data_rx_right : out std_logic_vector(DBIT-1 downto 0);  -- left channel data out
        ready         : out std_logic
    );
end i2s;

architecture arch of i2s is 
    -- # of mclk leading edges per slck and rlck half period
    constant SCLK_DIV        : integer := MCLK_LRCK_RATIO/SCLK_LRCK_RATIO/2 - 1;
    constant RLCK_DIV        : integer := MCLK_LRCK_RATIO/2 - 1;
    -- registered clock outputs
    signal sclk_reg          : std_logic;
    signal lrck_reg          : std_logic;
    -- counters for clock generation
    signal sclk_count_reg    : unsigned(9 downto 0);
    signal lrck_count_reg    : unsigned(9 downto 0);
    -- control signals
    signal sclk_rising_edge  : std_logic;
    signal sclk_falling_edge : std_logic;
    signal load_en_tx        : std_logic;
    signal load_en_rx        : std_logic;
    -- data shift registers
    signal tx_reg            : std_logic_vector(DBIT-1 downto 0);
    signal rx_reg            : std_logic_vector(DBIT-1 downto 0);
begin
    process(mclk, reset)
    begin
        if reset = '1' then
            sclk_count_reg <= (others => '0');
            lrck_count_reg <= (others => '0');
            tx_reg         <= (others => '0');
            sclk_reg <= '0';
            lrck_reg <= '0';
        elsif falling_edge(mclk) then
            -- sclk counter
            if sclk_count_reg = SCLK_DIV then
                sclk_count_reg <= (others => '0');
                sclk_reg       <= not sclk_reg;
            else
                sclk_count_reg <= sclk_count_reg + 1;
            end if;         
            
            -- lrck counter
            if lrck_count_reg = RLCK_DIV then
                lrck_count_reg <= (others => '0');
                lrck_reg       <= not lrck_reg;
            else
                lrck_count_reg <= lrck_count_reg + 1;
            end if;
            
            -- tx shift and load register
            if sclk_falling_edge = '1' then
                if load_en_tx = '1' then
                    if lrck_reg = '0' then
                        tx_reg <= data_tx_left;
                    else 
                        tx_reg <= data_tx_right;
                    end if;
                else
                    tx_reg <= tx_reg(DBIT-2 downto 0) & '0';
                end if;  
            end if;
            
            -- rx shift and load register
            if sclk_rising_edge = '1' then
                rx_reg <=  rx_reg(DBIT-2 downto 0) & sdata_rx; 
                if load_en_rx = '1' then
                    if lrck_reg = '1' then
                        data_rx_left <= rx_reg;
                    else 
                        data_rx_right <= rx_reg;
                    end if;
                end if; 
            end if;
        end if;
    end process;
    
    sclk_falling_edge <= '1' when (sclk_count_reg = SCLK_DIV and sclk_reg = '1') else '0';
    sclk_rising_edge  <= '1' when (sclk_count_reg = SCLK_DIV and sclk_reg = '0') else '0';
    load_en_tx  <= '1' when (lrck_count_reg = MCLK_LRCK_RATIO/SCLK_LRCK_RATIO - 1) else '0';
    load_en_rx  <= '1' when (lrck_count_reg = MCLK_LRCK_RATIO/SCLK_LRCK_RATIO*3/2 - 1) else '0';
    
    -- output clocks and serial data
    sclk  <= sclk_reg;
    lrck  <= lrck_reg;
    sdata_tx <= tx_reg(DBIT-1);
    ready <= '1' when load_en_tx = '1' and lrck_reg = '0' else '0';
    
end arch;