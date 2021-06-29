library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity mixer is
    generic(
        g_NUM_CHANNELS : integer := 128;
        g_DATA_WIDTH   : integer := 24
    );
    port(
        i_clk                : in std_logic;
        i_en                 : in std_logic;
        i_active_channels    : in std_logic_vector(6 downto 0);
        o_input_fifo_rd_en   : out std_logic;
        i_input_fifo_rd_data : in std_logic_vector(g_DATA_WIDTH-1 downto 0);
	    i_input_fifo_empty   : in std_logic; 
        o_output             : out std_logic_vector(g_DATA_WIDTH-1 downto 0)
    );
end entity mixer;

architecture arch of mixer is
    -- FSM states
    type t_state is (idle, processing, output);
    
    signal r_state : t_state := idle;
    
    -- Calculate the ceiled logarithm base 2 of an integer
    function clog2 (number : integer := 0) return integer is
        variable result : integer;
    begin   
        result := integer(ceil(log2(real(number))));
        return result;
    end function;
    
    type t_coef_array is array (0 to g_NUM_CHANNELS-1) of signed(15 downto 0);

    function coefficients (number : integer := 0) return t_coef_array is
        variable coefs : t_coef_array;    
    begin
        for Idx in 0 to number-1 loop
            coefs(Idx) := to_signed(integer((2.0**15.0-1.0)/real(Idx+1)), 16); 
        end loop;
        return coefs;
    end function;

    -- Accumulator width accounting for bit growth from addition of all channel samples 
    constant c_ACCUM_WIDTH : integer := clog2(g_NUM_CHANNELS) + g_DATA_WIDTH;
    
    -- Accumulator register
    signal r_accumulator : signed(c_ACCUM_WIDTH-1 downto 0) := (others => '0');

    constant C_COEFFICIENTS : t_coef_array := coefficients(g_NUM_CHANNELS);

    signal r_active_channels : integer;

    signal r_output : signed(g_DATA_WIDTH-1 downto 0);
begin

    process(i_clk)
        variable channel_index : integer;
    begin   
        if rising_edge(i_clk) then
            case r_state is
                when idle =>
                    
                    if i_en = '1' and i_input_fifo_empty = '0' then
                        r_state   <= processing;
                        r_accumulator <= (others => '0');
                        channel_index := 0;
                        r_active_channels <= to_integer(unsigned(i_active_channels));
                    end if;
                    
                when processing =>
                    r_accumulator <= r_accumulator + resize(signed(i_input_fifo_rd_data), r_accumulator'length);
                    
                    channel_index := channel_index + 1;
                    if channel_index = g_NUM_CHANNELS then
                        channel_index := 0;             
                        r_state  <= output;
                    end if;
                   
                when output =>
                    r_state  <= idle;
                    
                    if r_active_channels = 0 then
                        r_output <= resize(r_accumulator, g_DATA_WIDTH);
                    elsif r_active_channels <= 8 then
                        r_output <= resize(shift_right(r_accumulator, 3), g_DATA_WIDTH);
                    else
                        r_output <= resize(shift_right(r_accumulator * C_COEFFICIENTS(r_active_channels-1), 15), g_DATA_WIDTH);        
                    end if;                   
            end case;
        end if;
    end process;
    
    o_input_fifo_rd_en <= '1' when r_state = processing else '0';
    
    o_output <= std_logic_vector(r_output);

end arch;