library ieee;
use ieee.std_logic_1164.all;

package adsr_package is   
    constant c_DATA_WIDTH       : integer := 24;  -- width of waveform data outputs  
end package adsr_package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.adsr_package.all;

entity adsr is
    generic(
        g_NUM_CHANNELS  : integer := 128;
        g_DATA_WIDTH    : integer := 24
    );
    port(
        i_clk                   : in  std_logic;    
        i_en                    : in  std_logic;   -- enable
        -- ctrls 
        i_note_on_off_array     : in  std_logic_vector(g_NUM_CHANNELS-1 downto 0);          
        i_attack_cw             : in  std_logic_vector(g_DATA_WIDTH-1 downto 0);
        i_decay_cw              : in  std_logic_vector(g_DATA_WIDTH-1 downto 0);
        i_sustain_level         : in  std_logic_vector(g_DATA_WIDTH-1 downto 0);
        i_release_cw            : in  std_logic_vector(g_DATA_WIDTH-1 downto 0);
        o_channel_free_array    : out std_logic_vector(g_NUM_CHANNELS-1 downto 0);
        -- envelope
        o_envelope_fifo_wr_en   : out std_logic;
        o_envelope_fifo_wr_data : out std_logic_vector(g_DATA_WIDTH-1 downto 0);
        i_envelope_fifo_full    : in  std_logic;   
        o_active_channel_count  : out std_logic_vector(6 downto 0)           
    );
end adsr;

architecture arch of adsr is
    -- constants
    constant c_PHASE_WIDTH      : integer := g_DATA_WIDTH;  -- width of phase register
 
    -- types 
    type t_adsr_state is (off, attack, decay, sustain, release);
    type t_adsr_state_array is array(0 to g_NUM_CHANNELS-1) of t_adsr_state;
    type t_fsm_state is (idle, output);
    type t_phase_array is array(0 to g_NUM_CHANNELS-1) of signed(c_PHASE_WIDTH-1 downto 0);
    
    -- signals 
    signal r_adsr_phase_array : t_phase_array := (others => (others => '0'));  -- array of phase accumulators (one per voice)
    signal r_adsr_state_array : t_adsr_state_array := (others => off);
    signal r_channel     : integer range 0 to g_NUM_CHANNELS-1  := 0;     -- counter to track current channel
    signal r_fsm_state       : t_fsm_state := idle;                         -- state machine current state
    
    signal r_adsr_state_next : t_adsr_state;
    signal r_adsr_state_last : t_adsr_state;
    
    signal r_adsr_phase_last : signed(c_PHASE_WIDTH-1 downto 0);
    signal r_adsr_phase_next : signed(c_PHASE_WIDTH-1 downto 0);
    signal r_adsr_phase_next_temp : signed(c_PHASE_WIDTH-1 downto 0);
    
    signal r_note_on_off_last : std_logic;
    
    signal r_active_channel_count : integer := 0;
    
begin
    r_adsr_state_last  <= r_adsr_state_array(r_channel);
    r_adsr_phase_last  <= r_adsr_phase_array(r_channel);
    r_note_on_off_last <= i_note_on_off_array(r_channel);

    -- calculate phase logic
    process(r_adsr_state_last, r_adsr_phase_last, i_attack_cw, i_decay_cw, i_release_cw)
    begin
        case r_adsr_state_last is
            when off =>
                r_adsr_phase_next_temp <= (others => '0');
            when attack =>
                r_adsr_phase_next_temp <= r_adsr_phase_last + signed(i_attack_cw);
            when decay =>
                r_adsr_phase_next_temp <= r_adsr_phase_last - signed(i_decay_cw);
            when sustain =>
                r_adsr_phase_next_temp <= r_adsr_phase_last;
            when release =>
                r_adsr_phase_next_temp <= r_adsr_phase_last - signed(i_release_cw);
        end case;
    end process;
    
    -- next phase and state logic
    process(r_adsr_state_last, r_adsr_phase_last, r_adsr_phase_next_temp, i_attack_cw, i_decay_cw, r_note_on_off_last)
    begin
        case r_adsr_state_last is
            when off =>
                r_adsr_phase_next <= (others => '0');
                if r_note_on_off_last = '1' then
                        -- next state decay
                        r_adsr_state_next <= attack;
                    else
                        -- next state release
                        r_adsr_state_next <= off;
                    end if;
            when attack =>
                -- if overflow
                if r_adsr_phase_next_temp(c_PHASE_WIDTH-1) = '1' then 
                    -- set to maximum value
                    r_adsr_phase_next(c_PHASE_WIDTH-1) <= '0';
                    r_adsr_phase_next(c_PHASE_WIDTH-2 downto 0) <=  (others => '1');
                    -- if note still on
                    if r_note_on_off_last = '1' then
                        -- next state decay
                        r_adsr_state_next <= decay;
                    else
                        -- next state release
                        r_adsr_state_next <= release;
                    end if;
                else
                    -- set to next value
                    r_adsr_phase_next <= r_adsr_phase_next_temp;
                    -- if note still on
                    if r_note_on_off_last = '1' then
                        -- maintain in state attack
                        r_adsr_state_next <= attack;
                    else
                        -- next state release
                        r_adsr_state_next <= release;
                    end if;
                end if;       
            when decay =>
                if r_adsr_phase_next_temp <= signed(i_sustain_level) or
                   r_adsr_phase_next_temp < 0 then 
                    -- set to sustain value 
                    r_adsr_phase_next <= signed(i_sustain_level);
                    -- if note still on
                    if r_note_on_off_last = '1' then
                        -- next state sustain
                        r_adsr_state_next <= sustain;
                    else
                        -- next state release
                        r_adsr_state_next <= release;
                    end if;
                else
                    -- set to next value
                    r_adsr_phase_next <= r_adsr_phase_next_temp;
                    -- if note still on
                    if r_note_on_off_last = '1' then
                        -- maintain in state decay
                        r_adsr_state_next <= decay;
                    else
                        -- next state release
                        r_adsr_state_next <= release;
                    end if;
                end if;      
            when sustain =>
                -- maintain sustain value
                r_adsr_phase_next <= r_adsr_phase_next_temp;
                if r_note_on_off_last = '1' then
                    -- maintain in state sustain
                    r_adsr_state_next <= sustain;
                else
                    -- next state release
                    r_adsr_state_next <= release;
                end if;
            when release =>
                -- if underflow
                if r_adsr_phase_next_temp(c_PHASE_WIDTH-1) = '1' then 
                    -- set to zero
                    r_adsr_phase_next <= (others => '0');
                    -- note off
                    r_adsr_state_next <= off;
                else
                    -- set to next value
                    r_adsr_phase_next <= r_adsr_phase_next_temp;
                    r_adsr_state_next <= release;
                end if;      
        end case;
    end process;
    
    
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            o_envelope_fifo_wr_en  <= '0';
            
            case r_fsm_state is
                when idle   =>
                    if i_en = '1' then
                        r_fsm_state <= output;
                        r_channel <= 0;
                        r_active_channel_count <= 0;
                    end if;
                when output   =>
                    -- update adsr channel with new values
                    r_adsr_state_array(r_channel) <= r_adsr_state_next;
                    r_adsr_phase_array(r_channel) <= r_adsr_phase_next;
                    -- output adsr channel value
                    o_envelope_fifo_wr_en   <= '1';
                    o_envelope_fifo_wr_data <= std_logic_vector(r_adsr_phase_next(c_DATA_WIDTH-1 downto 0));
                    -- next adsr channel
                    if r_channel < g_NUM_CHANNELS-1 then
                        r_fsm_state <= output;
                        r_channel <= r_channel + 1;
                    else
                        r_fsm_state <= idle;
                    end if;
                    -- 
                    if r_adsr_state_next /= off then
                        r_active_channel_count <= r_active_channel_count + 1;
                    end if;
            end case;
        end if;
    end process;
    
    o_active_channel_count <= std_logic_vector(to_unsigned(r_active_channel_count, o_active_channel_count'length));
    
    process(r_adsr_state_array)
    begin
        for i in 0 to g_NUM_CHANNELS-1 loop
            if r_adsr_state_array(i) = off then
                o_channel_free_array(i) <= '1';
            else 
                o_channel_free_array(i) <= '0';
            end if;
        end loop;
    end process;
    
end arch;
