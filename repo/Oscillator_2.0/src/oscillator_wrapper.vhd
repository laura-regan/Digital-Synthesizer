library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity oscillator_wrapper is
    generic(
        g_NUM_CHANNELS    : integer := 128;
        g_NUM_OSCILLATORS : integer := 2;
        g_DATA_WIDTH      : integer := 24
    );
    port(
        i_clk                     : in std_logic;
        i_en                      : in std_logic;
        -- filter parameters
        o_oscillator_select : out std_logic_vector(1 downto 0);
        o_channel_select    : out std_logic_vector(6 downto 0);
        i_wave_select             : in std_logic_vector(1 downto 0);
        i_fcw                     : in std_logic_vector(17 downto 0); -- depends on channel
        i_detune                  : in std_logic_vector(17 downto 0);     -- depends on oscillator
        i_amplitude               : in std_logic_vector(17 downto 0);  -- depends on 
        i_pulse_width             : in std_logic_vector(23 downto 0);     -- depends on oscillator
        -- frequency modulation 
        i_modulation_en           : in std_logic;
        o_modulation_fifo_rd_en   : out std_logic;
        i_modulation_fifo_rd_data : in std_logic_vector(17 downto 0); -- Q1.17
	    i_modulation_fifo_empty   : in std_logic; 
	    -- Pulse Width Modulation
	    i_pwm_en                  : in std_logic;
        o_pwm_fifo_rd_en         : out std_logic;
        i_pwm_fifo_rd_data       : in std_logic_vector(23 downto 0);
	    i_pwm_fifo_empty         : in std_logic;
        -- outputs
        o_output_fifo_wr_en       : out std_logic;
        o_output_fifo_wr_data     : out std_logic_vector(g_DATA_WIDTH-1 downto 0); -- Q1.23
	    i_output_fifo_full        : in std_logic 
    );
end oscillator_wrapper;

architecture arch of oscillator_wrapper is

    type t_state is (idle, running);
    signal r_state : t_state := idle;
    
    signal r_data_valid_in  : std_logic;
    signal w_data_valid_out : std_logic;
    
    signal w_output : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    
    signal r_pwm_fifo_empty : std_logic := '0';
    signal r_modulation_fifo_empty : std_logic := '0';
    
    signal w_wave_select : std_logic_vector(1 downto 0);                  -- waveform select (sine, saw, triangle, square)
    signal w_amplitude   : std_logic_vector(17 downto 0); 
    signal w_fcw         : std_logic_vector(17 downto 0);                 -- frequency control word input
    signal w_detune      : std_logic_vector(17 downto 0);
    signal w_freq_mod    : std_logic_vector(17 downto 0);                 -- frequency modulation input
    signal w_mod_en      : std_logic;                                     -- enable frequency modulation
    signal w_pulse_width : std_logic_vector(23 downto 0);     -- pulse width input
    signal w_pw_mod      : std_logic_vector(23 downto 0);                 -- pulse width modulation input
    signal w_pwm_en      : std_logic;                                     -- enable pulse width modulation
    
    signal r_output : signed(23 downto 0) := (others => '0');
    
    signal channel_index_output    : integer := 0;
    signal oscillator_index_output : integer := 0;
    
    signal channel_index_input    : integer := 0;
    signal oscillator_index_input : integer := 0;
    
begin

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            case r_state is
                when idle =>
                    if i_en = '1' then
                        r_state         <= running; 
                        channel_index_input <= 0;
                        oscillator_index_input <= 0;
                        r_pwm_fifo_empty        <= i_pwm_fifo_empty;  
                        r_modulation_fifo_empty <= i_modulation_fifo_empty; 
                    end if;
                    
                when running =>
                    if oscillator_index_input = g_NUM_OSCILLATORS-1 then
                        oscillator_index_input <= 0;
                        if channel_index_input = g_NUM_CHANNELS-1 then 
                            channel_index_input <= 0;
                            r_state <= idle;
                        else
                            channel_index_input    <= channel_index_input + 1;
                        end if;
                    else
                        oscillator_index_input <= oscillator_index_input + 1;
                    end if;

            end case;        
        end if;
    end process;

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- output
            o_output_fifo_wr_en <= '0';
            if w_data_valid_out = '1' then
                if oscillator_index_output = g_NUM_OSCILLATORS-1 then
                    oscillator_index_output <= 0;
                    if channel_index_output = g_NUM_CHANNELS-1 then
                        channel_index_output <= 0;
                    else 
                        channel_index_output <= channel_index_output + 1;
                    end if;
                else
                    oscillator_index_output <= oscillator_index_output + 1;
                end if;
                
                if oscillator_index_output = 0 then
                    r_output <= signed(w_output);
                else
                    r_output <= r_output + signed(w_output);
                end if;
                
                if oscillator_index_output = g_NUM_OSCILLATORS-1 then
                    o_output_fifo_wr_en <= '1';
                else
                    o_output_fifo_wr_en <= '0';
                end if;
                
            end if;
        end if;
    end process;

    --r_data_valid_in <= '1' when channel_index_input <= g_NUM_CHANNELS-1 and r_state = running else '0';

    r_data_valid_in <= '1' when r_state = running else '0';

    o_oscillator_select <= std_logic_vector(to_unsigned(oscillator_index_input, o_oscillator_select'length));
    o_channel_select    <= std_logic_vector(to_unsigned(channel_index_input, o_channel_select'length));

    o_pwm_fifo_rd_en        <= '1' when r_pwm_fifo_empty = '0' and oscillator_index_input = g_NUM_OSCILLATORS-1 and r_data_valid_in = '1' else '0';
    o_modulation_fifo_rd_en <= '1' when r_modulation_fifo_empty = '0' and oscillator_index_input = g_NUM_OSCILLATORS-1 and r_data_valid_in = '1' else '0';
    
    w_pw_mod   <= i_pwm_fifo_rd_data when r_pwm_fifo_empty = '0' else (others => '0');
    w_freq_mod <= i_modulation_fifo_rd_data when r_modulation_fifo_empty = '0' else (others => '0');
    
    o_output_fifo_wr_data <= std_logic_vector(r_output);


    
    oscillator : entity work.oscillator
    generic map(
        g_NUM_CHANNELS => g_NUM_CHANNELS*g_NUM_OSCILLATORS   
    )
    port map(
        i_clk         => i_clk,
        i_data_valid  => r_data_valid_in,
        -- ctrls 
        i_wave_select => i_wave_select,
        i_amplitude   => i_amplitude,
        i_fcw         => i_fcw,
        i_detune      => i_detune,
        i_freq_mod    => w_freq_mod,
        i_mod_en      => i_modulation_en,
        i_pulse_width => i_pulse_width,
        i_pw_mod      => w_pw_mod,
        i_pwm_en      => i_pwm_en,
        o_output      => w_output,
        o_data_valid  => w_data_valid_out
    );

end arch;