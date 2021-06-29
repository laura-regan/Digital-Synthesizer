library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplier is
    generic(
        g_NUM_CHANNELS   : integer := 128;
        g_DATA_WIDTH     : integer := 24;
        g_ENVELOPE_WIDTH : integer := 18
    );
    port(
        i_clk                    : in std_logic;
        i_enable                 : in std_logic;
        -- input fifo interface
        o_input_fifo_rd_en       : out std_logic;
        i_input_fifo_rd_data     : in std_logic_vector(g_DATA_WIDTH-1 downto 0);
	    i_input_fifo_empty       : in std_logic;
        -- envelope fifo interface
        o_envelope_fifo_rd_en    : out std_logic;
        i_envelope_fifo_rd_data  : in std_logic_vector(g_ENVELOPE_WIDTH-1 downto 0);
	    i_envelope_fifo_empty    : in std_logic;
        -- output fifo interface
        o_output_fifo_wr_en      : out std_logic;
        o_output_fifo_wr_data    : out std_logic_vector(g_DATA_WIDTH-1 downto 0); -- Q1.23
	    i_output_fifo_full       : in std_logic
    );
end multiplier;

architecture arch of multiplier is
    -- constants
    constant c_PROD_WIDTH : integer := g_DATA_WIDTH + g_ENVELOPE_WIDTH;
    
    -- types
    type t_state is (idle, processing);
    
    -- signals
    signal r_state : t_state := idle;
    signal r_product : signed(c_PROD_WIDTH-1 downto 0) := (others => '0');
    
    signal r_input_fifo_empty    : std_logic := '0';
    signal r_envelope_fifo_empty : std_logic := '0';
    
    signal r_channel_index : integer := 0;
    
    signal w_input    : signed(g_DATA_WIDTH-1 downto 0);
    signal w_envelope : signed(g_ENVELOPE_WIDTH-1 downto 0);
begin
    -- read input from fifo if fifo is not empty 
    w_input    <= signed(i_input_fifo_rd_data)    when r_input_fifo_empty = '0'    else (others => '0');
    w_envelope <= signed(i_envelope_fifo_rd_data) when r_envelope_fifo_empty = '0' else (others => '0');
    
    -- only read from the fifo if processing and the fifo is initially not empty
    o_input_fifo_rd_en     <= '1' when r_state = processing and r_input_fifo_empty = '0'    else '0';
    o_envelope_fifo_rd_en  <= '1' when r_state = processing and r_envelope_fifo_empty = '0' else '0';
    
    process(i_clk)
        variable channel_index : integer := 0;
    begin
        if rising_edge(i_clk) then
            case r_state is
                when idle =>
                    o_output_fifo_wr_en <= '0';
                    if i_enable = '1' then
                        r_state <= processing;
                        r_input_fifo_empty    <= i_input_fifo_empty;
                        r_envelope_fifo_empty <= i_envelope_fifo_empty;
                    end if;
                    
                when processing =>
                    r_product <= w_input * w_envelope;
                    o_output_fifo_wr_en <= '1';
                    channel_index := channel_index + 1;
                    if channel_index = g_NUM_CHANNELS then
                        channel_index := 0;
                        r_state <= idle;
                    end if;
            end case;
        end if;
    end process;

    o_output_fifo_wr_data <= std_logic_vector(resize(shift_right(r_product, g_ENVELOPE_WIDTH-1), g_DATA_WIDTH));

end arch;
