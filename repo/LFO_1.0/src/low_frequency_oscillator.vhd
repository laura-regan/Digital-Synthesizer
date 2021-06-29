library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity low_frequency_oscillator is
    generic (
        g_DATA_WIDTH   : integer := 24;
        g_NUM_CHANNELS : integer := 128
    );
    port (
        i_clk    : in std_logic;
        i_enable : in std_logic;
        i_channel_on     : in std_logic_vector(0 to g_NUM_CHANNELS-1);
        i_channel_fcw    : in std_logic_vector(23 downto 0);
        i_amount         : in std_logic_vector(15 downto 0);
        i_waveform       : in std_logic_vector(1 downto 0);
        i_polyphonic     : in std_logic;
        o_output_fifo_wr_en   : out std_logic;
        o_output_fifo_wr_data : out std_logic_vector(g_DATA_WIDTH-1 downto 0);
        i_output_fifo_full    : in std_logic
    );
end low_frequency_oscillator;

architecture arch of low_frequency_oscillator is

    type t_state is (idle, accumulate, sine, saw, triangle, square, scale);
    
    signal r_state, r_state_last : t_state := idle;
    signal w_phase_accumulator : std_logic_vector(23 downto 0);
    signal r_phase_accumulator_next : unsigned(23 downto 0) := (others => '0');
    signal r_phase_accumulator_monophonic : unsigned(23 downto 0) := (others => '0');
    signal w_accumulator : unsigned(23 downto 0);
    signal shift_enable : std_logic;
    
    signal r_output : signed(g_DATA_WIDTH-1 downto 0) := (others => '0');
    
    signal r_channel_index, r_channel_index_last : integer := 0;
    
    signal r_waveform : std_logic_vector(1 downto 0);
    signal r_wave : signed(g_DATA_WIDTH-1 downto 0);
    
    signal w_saw : signed(g_DATA_WIDTH-1 downto 0);
    signal w_sine : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    signal w_square : signed(g_DATA_WIDTH-1 downto 0);
    signal w_saw_abs : signed(g_DATA_WIDTH-1 downto 0);
    signal w_triangle : signed(g_DATA_WIDTH-1 downto 0);
    
begin

    phase_sr : entity work.shift_register
    generic map(
        g_LENGTH    => g_NUM_CHANNELS,
        g_DATA_SIZE => 24
        )
    port map(
        i_clk  => i_clk,
        i_en   => shift_enable,
        i_in   => std_logic_vector(r_phase_accumulator_next),
        o_out  => w_phase_accumulator
    );

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            r_state_last <= r_state;
            r_channel_index_last <= r_channel_index;
            
        
            case r_state is
                when idle =>
                    if i_enable = '1' then
                        r_state <= accumulate;
                        r_waveform <= i_waveform;
                        r_channel_index <= 0;
                        r_phase_accumulator_monophonic <= r_phase_accumulator_monophonic + unsigned(i_channel_fcw);
                    end if;
                    
                when accumulate =>
                    if i_channel_on(r_channel_index) = '1' then
                        r_phase_accumulator_next <= unsigned(w_phase_accumulator) + unsigned(i_channel_fcw);
                    else
                        r_phase_accumulator_next <= (others => '0');
                    end if;
                    if r_waveform = "00" then
                        r_state <= sine;
                    elsif r_waveform = "01" then
                        r_state <= saw;
                    elsif r_waveform = "10" then
                        r_state <= triangle;
                    else 
                        r_state <= square;
                    end if;
                    
                when sine =>
                    r_wave  <= signed(w_sine);
                    r_state <= scale;
                    
                when saw =>
                    r_wave  <= w_saw;
                    r_state <= scale;
                
                when triangle =>
                    r_wave <= w_triangle;
                    r_state <= scale;
                
                when square =>
                    r_wave <= w_square;
                    r_state <= scale;
                    
                when scale =>   
                    r_output <= resize(shift_right(r_wave * signed(i_amount), 15), 24);

                    if r_channel_index = g_NUM_CHANNELS-1 then
                        r_channel_index <= 0;
                        r_state <= idle;
                    else
                        r_channel_index <= r_channel_index + 1;
                        r_state <= accumulate;
                    end if;
                    
            end case;
        end if;
    end process;    
    
    shift_enable <= '1' when r_state = scale else '0';
    
    o_output_fifo_wr_en <= '1' when r_state_last = scale else '0';
    
    o_output_fifo_wr_data <= std_logic_vector(r_output) when i_channel_on(r_channel_index_last) = '1' else (others => '0');
    
    w_accumulator <= r_phase_accumulator_next when i_polyphonic = '1' else r_phase_accumulator_monophonic;
    
    w_saw <= signed(w_accumulator);
    w_saw_abs <= w_saw  when w_saw > 0 else -w_saw;
    w_triangle <= shift_left(w_saw_abs - to_signed(2**(g_DATA_WIDTH-2), g_DATA_WIDTH), 1);
    w_square <= to_signed(2**(g_DATA_WIDTH-1)-1, 24) when w_saw > 0 else to_signed(-1*2**(g_DATA_WIDTH-1)-1, 24);
    
    -- instantiate sine wavetable
    sine_wavetable_unit: entity work.sine_wavetable
    port map(
        i_clk    => i_clk,
        i_en     => '1',
        i_addr   => std_logic_vector(w_accumulator(w_accumulator'high downto w_accumulator'high-8+1)),
        i_octave => (others => '0'),
        o_out    => w_sine
    );

end arch;