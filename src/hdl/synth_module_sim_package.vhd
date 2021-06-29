library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

use work.axi_sim_package.all;

package synth_module_sim_package is

    type t_wavetype is (SINE, SAW, TRIANGLE, SQUARE);
    type t_filter_type is (LOW_PASS, HIGH_PASS, BAND_PASS);
    type t_filter_attenuation is (ATTENUATION_12DB_OCT, ATTENUATION_24DB_OCT);

    -- CONSTANTS
    constant AUDIO_FREQUENCY : real := 96000.0; -- 96 kHz

    -- OSCILLATOR MODULE REGISTERS
    constant OSC_FREQUENCY_REG     : integer := 0;
    constant OSC_WAVEFORM_REG      : integer := 1;
    constant OSC_PULSEWIDTH_REG    : integer := 2;
    constant OSC_PWM_ENABLE_REG    : integer := 3;
    constant OSC_MODULATION_ENABLE : integer := 4;
    constant OSC_DETUNE_REG        : integer := 5;
    constant OSC_AMPLITUDE_REG     : integer := 6;

    -- ADSR MODULE REGISTERS
    constant ADSR_ON_OFF_REG        : integer := 0;
    constant ADSR_ATTACK_CW_REG     : integer := 4;
    constant ADSR_DECAY_CW_REG      : integer := 5;
    constant ADSR_SUSTAIN_LEVEL_REG : integer := 6;
    constant ADSR_RELEASE_CW_REG    : integer := 7;

    constant ADSR_MAX_CW_VALUE : integer := 2**23-1;

    -- FILTER MODULE REGISTERS
    constant FILTER_CUTOFF_FREQUENCY_REG    : integer := 0;
    constant FILTER_RESONANCE_REG           : integer := 1;
    constant FILTER_ADSR_AMOUNT_REG         : integer := 2;
    constant FILTER_MODULATION_ENABLE_REG   : integer := 3;
    constant FILTER_MODULATION_AMOUNT_REG   : integer := 4;
    constant FILTER_TYPE_REG                : integer := 5;
    constant FILTER_ATTENUATION_REG         : integer := 6;
    
    -- LFO MODULE REGISTERS
    constant LFO_VOICE_ON_OFF_REG      : integer := 0;
    constant LFO_RATE_REG              : integer := 1;
    constant LFO_AMOUNT_REG            : integer := 2;
    constant LFO_WAVEFORM_REG          : integer := 3;
    constant LFO_POLYPHONY_ENABLE_REG  : integer := 4;

   ------------------ OSCILLATOR MODULE FUNCTIONS ------------------

    procedure osc_set_frequency(signal axi_aclk : in std_logic;
                                signal axi_slave    : inout t_axi_slave;
                                constant voice  : in integer;
                                constant freq   : in real);

    procedure osc_set_waveform( signal axi_aclk   : in std_logic;
                                signal axi_slave      : inout t_axi_slave;
                                constant osc      : in integer;
                                constant wavetype : in t_wavetype);   
                                
    procedure osc_set_pulse_width(signal axi_aclk   : in std_logic;
                                  signal axi_slave  : inout t_axi_slave;
                                  constant osc      : in integer;
                                  constant width    : in real); 
                                   
    procedure osc_set_amplitude(signal axi_aclk   : in std_logic;
                                signal axi_slave      : inout t_axi_slave;
                                constant osc      : in integer;
                                constant amp      : in real); 

    procedure osc_pwm_enable(signal axi_aclk   : in std_logic;
                             signal axi_slave : inout t_axi_slave;
                             constant osc     : in integer);

    procedure osc_pwm_disable(signal axi_aclk   : in std_logic;
                             signal axi_slave : inout t_axi_slave;
                             constant osc     : in integer);

    ------------------ ADSR MODULE FUNCTIONS ------------------    
    
    procedure adsr_set_voice_on(signal axi_aclk  : in std_logic;
                                signal axi_slave : inout t_axi_slave;
                                constant voice   : in integer);

    procedure adsr_set_voice_off(signal axi_aclk  : in std_logic;
                                 signal axi_slave : inout t_axi_slave;
                                 constant voice   : in integer);     
                                 
    procedure adsr_set_attack_time(signal axi_aclk  : in std_logic;
                                   signal axi_slave : inout t_axi_slave;
                                   constant time    : in real);  

    procedure adsr_set_decay_time(signal axi_aclk  : in std_logic;
                                  signal axi_slave : inout t_axi_slave;
                                  constant time    : in real);                               

    procedure adsr_set_sustain_level(signal axi_aclk  : in std_logic;
                                     signal axi_slave : inout t_axi_slave;
                                     constant level   : in real);
                                     
    procedure adsr_set_release_time(signal axi_aclk  : in std_logic;
                                    signal axi_slave : inout t_axi_slave;
                                    constant time    : in real);

    ------------------ FILTER MODULE FUNCTIONS ------------------ 

    procedure filter_set_cutoff_frequency(signal axi_aclk : in std_logic;
                                          signal axi_slave    : inout t_axi_slave;
                                          constant freq   : in real);
                                          
    procedure filter_set_resonance(signal axi_aclk : in std_logic;
                                   signal axi_slave    : inout t_axi_slave;
                                   constant res   : in real);    
                                   
    procedure filter_set_type(signal axi_aclk      : in std_logic;
                              signal axi_slave         : inout t_axi_slave;
                              constant filter_type : in t_filter_type);

    procedure filter_set_attenuation(signal axi_aclk      : in std_logic;
                                     signal axi_slave         : inout t_axi_slave;
                                     constant attenuation : in t_filter_attenuation);    
                                                          
    ------------------ LFO MODULE FUNCTIONS ------------------ 
    procedure lfo_set_voice_on(signal axi_aclk  : in std_logic;
                                signal axi_slave : inout t_axi_slave;
                                constant voice   : in integer);

    procedure lfo_set_voice_off(signal axi_aclk  : in std_logic;
                                 signal axi_slave : inout t_axi_slave;
                                 constant voice   : in integer);
                                 
    procedure lfo_set_rate(signal axi_aclk : in std_logic;
                                signal axi_slave    : inout t_axi_slave;
                                constant period   : in real);

    procedure lfo_set_amount(signal axi_aclk   : in std_logic;
                                 signal axi_slave      : inout t_axi_slave;
                                 constant amp      : in real);   
                                 
    procedure lfo_set_waveform(signal axi_aclk   : in std_logic;
                                signal axi_slave      : inout t_axi_slave;
                                constant wavetype : in t_wavetype);                               
    
    procedure lfo_enable_polyphony(signal axi_aclk   : in std_logic;
                                signal axi_slave      : inout t_axi_slave;
                                constant enable : in std_logic);                               


end package synth_module_sim_package;

package body synth_module_sim_package is

    ------------------ OSCILLATOR MODULE FUNCTIONS ------------------

    procedure osc_set_frequency(signal axi_aclk : in std_logic;
                                signal axi_slave    : inout t_axi_slave;
                                constant voice  : in integer;
                                constant freq   : in real) is
        variable fcw : integer;          
        variable msg : std_logic_vector(31 downto 0);                   
    begin
        fcw := integer(freq * (2.0**20.0) / AUDIO_FREQUENCY);
        msg := std_logic_vector(to_unsigned(voice * 2**25 + fcw, 32));
        s_axi_write(axi_aclk, axi_slave, OSC_FREQUENCY_REG, msg);
    end procedure;    

    procedure osc_set_waveform( signal axi_aclk   : in std_logic;
                                signal axi_slave      : inout t_axi_slave;
                                constant osc      : in integer;
                                constant wavetype : in t_wavetype) is
        variable wave : integer;
        variable msg : std_logic_vector(31 downto 0);                            
    begin
        case wavetype is
            when SINE     => wave := 0;
            when SAW      => wave := 1;    
            when TRIANGLE => wave := 2;
            when SQUARE   => wave := 3;
            when others   => wave := 0;
        end case;

        msg := std_logic_vector(to_unsigned(osc * 2**25 + wave, 32));
        s_axi_write(axi_aclk, axi_slave, OSC_WAVEFORM_REG, msg);
    end procedure;

    procedure osc_set_pulse_width( signal axi_aclk   : in std_logic;
                                   signal axi_slave      : inout t_axi_slave;
                                   constant osc      : in integer;
                                   constant width    : in real) is
        variable pw  : integer;          
        variable msg : std_logic_vector(31 downto 0);                   
    begin
        pw := integer(width * 2.0**23.0);
        msg := std_logic_vector(to_unsigned(osc * 2**25 + pw, 32));
        s_axi_write(axi_aclk, axi_slave, OSC_PULSEWIDTH_REG, msg);
    end procedure;    

    procedure osc_set_amplitude(signal axi_aclk   : in std_logic;
                                signal axi_slave      : inout t_axi_slave;
                                constant osc      : in integer;
                                constant amp      : in real) is 
        variable amplitude : integer;          
        variable msg : std_logic_vector(31 downto 0);                   
    begin
        amplitude := integer(amp * (2.0**17-1.0));
        msg := std_logic_vector(to_unsigned(osc * 2**25 + amplitude, 32));
        s_axi_write(axi_aclk, axi_slave, OSC_AMPLITUDE_REG, msg);
    end procedure;                            

    procedure osc_pwm_enable(signal axi_aclk   : in std_logic;
                             signal axi_slave : inout t_axi_slave;
                             constant osc     : in integer) is
        variable msg : std_logic_vector(31 downto 0);                   
    begin
        msg := std_logic_vector(to_unsigned(osc * 2**25 + 1, 32));
        s_axi_write(axi_aclk, axi_slave, OSC_PWM_ENABLE_REG, msg);
    end procedure;         

    procedure osc_pwm_disable(signal axi_aclk   : in std_logic;
                             signal axi_slave : inout t_axi_slave;
                             constant osc     : in integer) is
        variable msg : std_logic_vector(31 downto 0);                   
    begin
        msg := std_logic_vector(to_unsigned(osc * 2**25, 32));
        s_axi_write(axi_aclk, axi_slave, OSC_PWM_ENABLE_REG, msg);
    end procedure;     
    -- ------------------ ADSR MODULE FUNCTIONS ------------------    
    
    procedure adsr_set_voice_on(signal axi_aclk : in std_logic;
                                signal axi_slave    : inout t_axi_slave;
                                constant voice  : in integer) is
        variable msg : std_logic_vector(31 downto 0);                                 
    begin
        s_axi_read(axi_aclk, axi_slave, ADSR_ON_OFF_REG+voice/32, msg);
        msg := msg or std_logic_vector(shift_left(to_unsigned(1, 32), voice));
        s_axi_write(axi_aclk, axi_slave, ADSR_ON_OFF_REG+voice/32, msg);
    end procedure;

    procedure adsr_set_voice_off(signal axi_aclk : in std_logic;
                                signal axi_slave    : inout t_axi_slave;
                                constant voice  : in integer) is
        variable msg : std_logic_vector(31 downto 0);                                 
    begin
        s_axi_read(axi_aclk, axi_slave, ADSR_ON_OFF_REG+voice/32, msg);
        msg := msg and not std_logic_vector(shift_left(to_unsigned(1, 32), voice));
        s_axi_write(axi_aclk, axi_slave, ADSR_ON_OFF_REG+voice/32, msg);
    end procedure;

    procedure adsr_set_attack_time(signal axi_aclk  : in std_logic;
                                   signal axi_slave : inout t_axi_slave;
                                   constant time    : in real) is
        variable cw : integer;                            
        variable msg : std_logic_vector(31 downto 0);                                 
    begin
        if time = 0.0 then
            cw := ADSR_MAX_CW_VALUE;
        else
            cw := integer(real(ADSR_MAX_CW_VALUE)/(time*AUDIO_FREQUENCY));    
        end if;
        
        msg := std_logic_vector(to_unsigned(cw, 32));
        s_axi_write(axi_aclk, axi_slave, ADSR_ATTACK_CW_REG, msg);
    end procedure;                             

    procedure adsr_set_decay_time(signal axi_aclk  : in std_logic;
                                  signal axi_slave : inout t_axi_slave;
                                  constant time    : in real) is
        variable data : std_logic_vector(31 downto 0);                              
        variable cw : integer; 
        variable level : integer;                           
        variable msg : std_logic_vector(31 downto 0);                                 
    begin
        s_axi_read(axi_aclk, axi_slave, ADSR_SUSTAIN_LEVEL_REG, data);
        level := to_integer(unsigned(data));
        if time = 0.0 then
            cw := ADSR_MAX_CW_VALUE - level;
        else
            cw := integer(real(ADSR_MAX_CW_VALUE - level)/(time*AUDIO_FREQUENCY));    
        end if;
        
        msg := std_logic_vector(to_unsigned(cw, 32));
        s_axi_write(axi_aclk, axi_slave, ADSR_DECAY_CW_REG, msg);
    end procedure;

    procedure adsr_set_sustain_level(signal axi_aclk  : in std_logic;
                                     signal axi_slave : inout t_axi_slave;
                                     constant level   : in real) is                             
        variable cw : integer;                            
        variable msg : std_logic_vector(31 downto 0);                                 
    begin
        cw := integer(real(ADSR_MAX_CW_VALUE) * level);
        msg := std_logic_vector(to_unsigned(cw, 32));
        s_axi_write(axi_aclk, axi_slave, ADSR_SUSTAIN_LEVEL_REG, msg);
    end procedure;

    procedure adsr_set_release_time(signal axi_aclk  : in std_logic;
                                  signal axi_slave : inout t_axi_slave;
                                  constant time    : in real) is
        variable data : std_logic_vector(31 downto 0);                              
        variable cw : integer; 
        variable level : integer;                           
        variable msg : std_logic_vector(31 downto 0);                                 
    begin
        s_axi_read(axi_aclk, axi_slave, ADSR_SUSTAIN_LEVEL_REG, data);
        level := to_integer(unsigned(data));
        if time = 0.0 then
            cw := level;
        else
            cw := integer(real(level)/(time*AUDIO_FREQUENCY));    
        end if;
        
        msg := std_logic_vector(to_unsigned(cw, 32));
        s_axi_write(axi_aclk, axi_slave, ADSR_RELEASE_CW_REG, msg);
    end procedure;

    ------------------ FILTER MODULE FUNCTIONS ------------------ 

    procedure filter_set_cutoff_frequency(signal axi_aclk : in std_logic;
                                          signal axi_slave    : inout t_axi_slave;
                                          constant freq   : in real) is
        variable cutoff_freq : integer;
        variable msg : std_logic_vector(31 downto 0); 
    begin
        cutoff_freq := integer(freq * 32768.0/96000.0*2.0*MATH_PI);
        msg := std_logic_vector(to_unsigned(cutoff_freq, 32));
        s_axi_write(axi_aclk, axi_slave, FILTER_CUTOFF_FREQUENCY_REG, msg);
    end procedure;
                                          
    procedure filter_set_resonance(signal axi_aclk : in std_logic;
                                   signal axi_slave    : inout t_axi_slave;
                                   constant res    : in real) is
        variable resonance : integer;
        variable msg : std_logic_vector(31 downto 0); 
    begin
        resonance := integer(res * 32767.0);
        msg := std_logic_vector(to_unsigned(resonance, 32));
        s_axi_write(axi_aclk, axi_slave, FILTER_RESONANCE_REG, msg);
    end procedure;
                                   
    procedure filter_set_type(signal axi_aclk      : in std_logic;
                              signal axi_slave         : inout t_axi_slave;
                              constant filter_type : in t_filter_type) is
        variable msg : std_logic_vector(31 downto 0); 
    begin
        msg := std_logic_vector(to_unsigned(t_filter_type'pos(filter_type), 32));
        s_axi_write(axi_aclk, axi_slave, FILTER_TYPE_REG, msg);
    end procedure;

    procedure filter_set_attenuation(signal axi_aclk      : in std_logic;
                                     signal axi_slave         : inout t_axi_slave;
                                     constant attenuation : in t_filter_attenuation) is
        variable msg : std_logic_vector(31 downto 0); 
    begin
        msg := std_logic_vector(to_unsigned(t_filter_attenuation'pos(attenuation), 32));
        s_axi_write(axi_aclk, axi_slave, FILTER_ATTENUATION_REG, msg);
    end procedure;


    procedure lfo_set_voice_on(signal axi_aclk  : in std_logic;
                               signal axi_slave : inout t_axi_slave;
                               constant voice   : in integer) is
        variable msg : std_logic_vector(31 downto 0); 
    begin
        msg := std_logic_vector(to_unsigned(1*2**8+1*2**7+voice, 32));
        s_axi_write(axi_aclk, axi_slave, LFO_VOICE_ON_OFF_REG, msg);
    end procedure;

    procedure lfo_set_voice_off(signal axi_aclk  : in std_logic;
                                signal axi_slave : inout t_axi_slave;
                                constant voice   : in integer) is
        variable msg : std_logic_vector(31 downto 0); 
    begin
        msg := std_logic_vector(to_unsigned(1*2**7+voice, 32));
        s_axi_write(axi_aclk, axi_slave, LFO_VOICE_ON_OFF_REG, msg);
    end procedure;

    procedure lfo_set_rate(signal axi_aclk : in std_logic;
                                signal axi_slave    : inout t_axi_slave;
                                constant period   : in real) is 
        variable msg : std_logic_vector(31 downto 0); 
    begin
        msg := std_logic_vector(to_unsigned(integer((2.0**24.0-1.0)/AUDIO_FREQUENCY/period), 32));
        s_axi_write(axi_aclk, axi_slave, LFO_RATE_REG, msg);
    end procedure;   
                                
    
    procedure lfo_set_amount(signal axi_aclk   : in std_logic;
                                 signal axi_slave      : inout t_axi_slave;
                                 constant amp      : in real) is
        variable msg : std_logic_vector(31 downto 0); 
    begin
        msg := std_logic_vector(to_unsigned(integer(amp * 2.0**15.0), 32));
        s_axi_write(axi_aclk, axi_slave, LFO_AMOUNT_REG, msg);
    end procedure;                                     
                                 
    procedure lfo_set_waveform(signal axi_aclk   : in std_logic;
                                signal axi_slave      : inout t_axi_slave;
                                constant wavetype : in t_wavetype) is
        variable wave : integer;
        variable msg : std_logic_vector(31 downto 0);                            
    begin
        case wavetype is
            when SINE     => wave := 0;
            when SAW      => wave := 1;    
            when TRIANGLE => wave := 2;
            when SQUARE   => wave := 3;
            when others   => wave := 0;
        end case;

        msg := std_logic_vector(to_unsigned(wave, 32));
        s_axi_write(axi_aclk, axi_slave, LFO_WAVEFORM_REG, msg);
    end procedure;  
    
    procedure lfo_enable_polyphony(signal axi_aclk   : in std_logic;
                                signal axi_slave      : inout t_axi_slave;
                                constant enable : in std_logic) is
        variable msg : std_logic_vector(31 downto 0);                            
    begin
        msg(0) := enable;
        msg(31 downto 1) := (others => '0'); 
        s_axi_write(axi_aclk, axi_slave, LFO_POLYPHONY_ENABLE_REG, msg);
    end procedure;                              
                                                               
                              

end package body synth_module_sim_package;