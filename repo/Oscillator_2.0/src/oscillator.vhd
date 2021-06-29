library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity oscillator is
    generic(
        g_NUM_CHANNELS    : integer := 128
    );
    port(
        i_clk         : in std_logic;    
        i_data_valid  : in std_logic;                                   -- enable
        -- ctrls 
        i_wave_select : in std_logic_vector(1 downto 0);                  -- waveform select (sine, saw, triangle, square)
        i_amplitude   : in std_logic_vector(17 downto 0); 
        i_fcw         : in std_logic_vector(17 downto 0);                 -- frequency control word input
        i_detune      : in std_logic_vector(17 downto 0);
        i_freq_mod    : in std_logic_vector(17 downto 0);                 -- frequency modulation input
        i_mod_en      : in std_logic;                                     -- enable frequency modulation
        i_pulse_width : in std_logic_vector(23 downto 0);     -- pulse width input
        i_pw_mod      : in std_logic_vector(23 downto 0);                 -- pulse width modulation input
        i_pwm_en      : in std_logic;                                     -- enable pulse width modulation
        o_output      : out std_logic_vector(23 downto 0);    -- output waveform
        o_data_valid  : out std_logic
    );
end oscillator;

architecture arch of oscillator is
    
    constant c_DATA_WIDTH           : integer := 24;
    constant c_PHASE_WIDTH          : integer := 20;
    constant c_WAVETABLE_ADDR_WIDTH : integer := 11;
    
    --signal r_oscillator_index : integer range 0 to g_NUM_OSCILLATORS-1 := 0;
    signal r_channel_index    : integer range 0 to g_NUM_CHANNELS-1    := 0;
    
    signal r_data_valid_delay_line : std_logic_vector(0 to 7) := (others => '0');
    
    signal r_fcw              : signed(18 downto 0)                := (others => '0');
    signal r_fcw_detuned      : unsigned(35 downto 0) := (others => '0');
    signal r_fcw_detuned_z1   : unsigned(c_PHASE_WIDTH-1 downto 0) := (others => '0');
    signal r_fcw_total        : signed(c_PHASE_WIDTH-1 downto 0)   := (others => '0');
    signal r_fcw_total_z1     : signed(c_PHASE_WIDTH-1 downto 0)   := (others => '0');
    signal r_fcw_total_z2     : signed(c_PHASE_WIDTH-1 downto 0)   := (others => '0');
    signal r_freq_mod         : signed(17 downto 0)                := (others => '0');
    signal r_freq_mod_factor  : signed(37 downto 0)                := (others => '0');
    signal r_pw_total         : signed(24 downto 0)                := (others => '0');
    signal r_pw_saturated     : signed(23 downto 0)              := (others => '0');
    signal r_pw_saturated_z1  : signed(23 downto 0)              := (others => '0');
    signal r_pw_saturated_z2  : signed(23 downto 0)              := (others => '0');
    signal r_pw_saturated_z3  : signed(23 downto 0)              := (others => '0');
    signal r_pw_saturated_z4  : signed(23 downto 0)              := (others => '0');
    signal r_pw_saturated_z5  : signed(23 downto 0)              := (others => '0');
    signal w_phase_reg        : std_logic_vector(c_PHASE_WIDTH-1 downto 0);
    signal r_phase_reg_next   : unsigned(c_PHASE_WIDTH-1 downto 0) := (others => '0');
    
    signal r_addr_a      : unsigned(c_WAVETABLE_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal r_addr_b      : unsigned(c_WAVETABLE_ADDR_WIDTH-1 downto 0) := (others => '0');
    
    signal r_wavetable_output : signed(c_DATA_WIDTH downto 0) := (others => '0');
    
    signal r_wave : signed(c_DATA_WIDTH-1 downto 0) := (others => '0');
    
    signal r_output : signed(c_DATA_WIDTH+18-1 downto 0) := (others => '0');
    
    signal w_sine : std_logic_vector(c_DATA_WIDTH-1 downto 0);
    signal w_saw_a : std_logic_vector(c_DATA_WIDTH-1 downto 0);
    signal w_saw_b : std_logic_vector(c_DATA_WIDTH-1 downto 0);
    signal w_triangle : std_logic_vector(c_DATA_WIDTH-1 downto 0);
    
    type t_wave_select_delay_reg is array (0 to 7) of std_logic_vector(1 downto 0);
    signal r_wave_select_delay_reg : t_wave_select_delay_reg := (others => (others => '0'));
    
    type t_amplitude_delay_reg is array (0 to 7) of signed(17 downto 0);
    signal r_amplitude_delay_reg : t_amplitude_delay_reg := (others => (others => '0'));
    
    -- constants 
    constant c_NUM_OCTAVES   : integer := 10; -- # of octaves
    constant c_ADDR_WIDTH    : integer := 11;
    
    signal shift_reg : std_logic;
    
    signal w_octave : unsigned(3 downto 0);                               -- octave of current voice
    
begin
    
    phase_sr : entity work.shift_register
    generic map(
        g_LENGTH    => g_NUM_CHANNELS,
        g_DATA_SIZE => c_PHASE_WIDTH
        )
    port map(
        i_clk  => i_clk,
        i_en   => shift_reg,
        i_in   => std_logic_vector(r_phase_reg_next),
        o_out  => w_phase_reg
    );

    shift_reg <= r_data_valid_delay_line(2) or r_data_valid_delay_line(3);
    
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            
            -- stage 0
            -- add fcw and detune 
            -- add pulse width and pwm
            r_fcw_detuned <= unsigned(i_fcw) * unsigned(i_detune);
            
            --r_fcw      <= signed('0' & i_fcw);
            r_freq_mod <= signed(i_freq_mod);
            
            if i_pwm_en = '1' then
                r_pw_total <= resize(signed(i_pulse_width), r_pw_total'length) + resize(signed(i_pw_mod), r_pw_total'length);
            else
                r_pw_total <= resize(signed(i_pulse_width), r_pw_total'length);
            end if;
            
            -- stage 1
            -- multiply detuned fcw by modulation factor
            r_fcw_detuned_z1 <= resize(shift_right(r_fcw_detuned, 14), c_PHASE_WIDTH);
            
            if i_mod_en = '1' then
                r_freq_mod_factor <= signed(resize(shift_right(r_fcw_detuned, 14), c_PHASE_WIDTH)) * r_freq_mod;
            else
                r_freq_mod_factor <= (others => '0');
            end if;
            
            if r_pw_total(r_pw_total'high downto r_pw_total'high-1) = "01" then -- negative
                r_pw_saturated <= to_signed(2**23-1, 24);
            elsif r_pw_total(r_pw_total'high downto r_pw_total'high-1) = "10" then -- overflow
                r_pw_saturated <= to_signed(-2**23-1, 24);
            else
                r_pw_saturated <= signed(resize(r_pw_total, 24));
            end if;
            
            -- stage 2
            -- add detuned fcw and modulation fcw
            r_fcw_total <= signed(r_fcw_detuned_z1) + resize(shift_right(r_freq_mod_factor, 17), c_PHASE_WIDTH);
            
            r_pw_saturated_z1 <= r_pw_saturated;
            
            -- stage 3
            -- add total fcw to phase accumulator. Store result in shift register
            
            r_phase_reg_next <= unsigned(w_phase_reg) + unsigned(r_fcw_total);
            
            r_fcw_total_z1    <= r_fcw_total;
            
            r_pw_saturated_z2 <= r_pw_saturated_z1;
            
            -- stage 4
            -- address waveform register with phase register
            r_addr_a <= r_phase_reg_next(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-c_WAVETABLE_ADDR_WIDTH);
            r_addr_b <= r_phase_reg_next(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-c_WAVETABLE_ADDR_WIDTH) +
                        unsigned(r_pw_saturated_z2(r_pw_saturated_z2'high downto r_pw_saturated_z2'high-c_WAVETABLE_ADDR_WIDTH+1))+
                        to_unsigned(2**(c_WAVETABLE_ADDR_WIDTH-1), c_WAVETABLE_ADDR_WIDTH);
            
            r_fcw_total_z2 <= r_fcw_total_z1;   
            
            r_pw_saturated_z3 <= r_pw_saturated_z2;         
            -- stage 5
            r_pw_saturated_z4 <= r_pw_saturated_z3;
            
            -- stage 6
            case r_wave_select_delay_reg(5) is
                when "00" =>
                    r_wavetable_output <= resize(signed(w_sine), r_wavetable_output'length);
                when "01" =>
                    r_wavetable_output <= resize(signed(w_saw_a), r_wavetable_output'length);
                when "10" =>
                    r_wavetable_output <= resize(signed(w_triangle), r_wavetable_output'length);
                when others =>
                    r_wavetable_output <= resize(signed(w_saw_a), r_wavetable_output'length) - resize(signed(w_saw_b), r_wavetable_output'length);
            end case;    
            
            r_pw_saturated_z5 <= r_pw_saturated_z4;--resize(shift_right(r_pw_saturated_z4 * to_signed(7549746, 24), 17), 24);
            
            -- stage 7   
            if r_wave_select_delay_reg(6) = "11" then
                r_wave <= resize(r_wavetable_output + shift_right(r_pw_saturated_z5, 1), c_DATA_WIDTH); 
            else
                r_wave <= resize(r_wavetable_output, c_DATA_WIDTH);
            end if;     
            
            -- stage 8
            r_output <= r_wave * r_amplitude_delay_reg(7);
            
            o_data_valid <= r_data_valid_delay_line(7);
        end if;
    end process;
    
    o_output <= std_logic_vector(resize(shift_right(r_output, 17), c_DATA_WIDTH));
    
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            r_data_valid_delay_line(0) <= i_data_valid;
            for Idx in 0 to r_data_valid_delay_line'high-1 loop
                r_data_valid_delay_line(Idx+1) <= r_data_valid_delay_line(Idx);
            end loop;
            o_data_valid <= r_data_valid_delay_line(r_data_valid_delay_line'high);
            
            r_wave_select_delay_reg(0) <= i_wave_select;
            for Idx in 0 to r_data_valid_delay_line'high-1 loop
                r_wave_select_delay_reg(Idx+1) <= r_wave_select_delay_reg(Idx);
            end loop;
            
            r_amplitude_delay_reg(0) <= signed(i_amplitude);
            for Idx in 0 to r_amplitude_delay_reg'high-1 loop
                r_amplitude_delay_reg(Idx+1) <= r_amplitude_delay_reg(Idx);
            end loop;
            
        end if;
    end process;
    
    
    -- determine the octave from the frequency control word
    process(r_fcw_total_z2)
    begin
        if r_fcw_total_z2(16) = '1' then
            w_octave <= to_unsigned(9, 4);
        elsif r_fcw_total_z2(15) = '1' then
            w_octave <= to_unsigned(8, 4);
        elsif r_fcw_total_z2(14) = '1' then
            w_octave <= to_unsigned(7, 4);
        elsif r_fcw_total_z2(13) = '1' then
            w_octave <= to_unsigned(6, 4);
        elsif r_fcw_total_z2(12) = '1' then
            w_octave <= to_unsigned(5, 4);
        elsif r_fcw_total_z2(11) = '1' then
            w_octave <= to_unsigned(4, 4);
        elsif r_fcw_total_z2(10) = '1' then
            w_octave <= to_unsigned(3, 4);
        elsif r_fcw_total_z2(9) = '1' then
            w_octave <= to_unsigned(2, 4);
        elsif r_fcw_total_z2(8) = '1' then
            w_octave <= to_unsigned(1, 4);
        elsif r_fcw_total_z2(7) = '1' then
            w_octave <= to_unsigned(0, 4);
        else
            w_octave <= to_unsigned(0, 4);
        end if;
    end process;
    
    -- instantiate sine wavetable
    sine_wavetable_unit: entity work.sine_wavetable
    port map(
        i_clk    => i_clk,
        i_en     => '1',
        i_addr   => std_logic_vector(r_addr_a(r_addr_a'high downto r_addr_a'high-8+1)),
        i_octave => std_logic_vector(w_octave),
        o_out    => w_sine
    );
    
    -- instantiate sawtooth wavetable
    sawtooth_wavetable_unit: entity work.sawtooth_wavetable
    port map(
        i_clk    => i_clk,
        i_en     => '1',
        i_addr_a => std_logic_vector(r_addr_a),
        i_addr_b => std_logic_vector(r_addr_b),
        i_octave => std_logic_vector(w_octave),
        o_out_a  => w_saw_a,
        o_out_b  => w_saw_b
    );
    
    -- instantiate triangle wavetable
    triangle_wavetable_unit: entity work.triangle_wavetable
    port map(
        i_clk    => i_clk,
        i_en     => '1',
        i_addr   => std_logic_vector(r_addr_a),
        i_octave => std_logic_vector(w_octave),
        o_out    => w_triangle
    );
    
end arch;