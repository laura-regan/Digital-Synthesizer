-- Moog Ladder Filter Digital Implementation
-- Author: Laura Isabel Regan Williams 
-- Date: 28/02/2021
-- Description:
-- Digital implementation in VHDL of the famous Moog ladder filter based
-- on the discrete model by Valimaki and Huovilainen 2006. Designed to be
-- capable of processing multiple audio channels the design features multiple
-- filter configurations (Low pass, High pass and Bandpass) (12dB/Oct and 24dB/Oct slope)
-- and includes cutoff frequency modulation inputs.
--
-- Inputs:
-- i_clk: system clk
-- 1_input: input data
-- i_resonance: resonance control parameter
-- i_cutoff_freq: cutoff frequency control parameter
-- i_adsr: ADSR envelope input
-- i_adsr_amount: ADSR envelope amount
-- i_cutoff_mod: cutoff frequency modulation input (e.g. LFO)
-- i_filter_type: Low pass (00), High pass (01) and Bandpass (10) filter configuration
-- i_filter_attenuation: 12dB/Oct (0) and 24dB/Oct (1) slope
--
-- Outputs:
-- o_output: data output
-- o_data_valid: data valid output

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity moog_ladder_filter is
    generic(
        g_NUM_CHANNELS : integer := 128;
        g_DATA_WIDTH   : integer := 24   
    );
    port(
        i_clk                : in std_logic;
        i_data_valid         : in std_logic;
        i_input              : in std_logic_vector(g_DATA_WIDTH-1 downto 0);
        -- filter parameters
        i_resonance          : in std_logic_vector(17 downto 0);
        i_cutoff_frequency   : in std_logic_vector(17 downto 0); -- Q3.15
        -- ADSR Envelope
        i_adsr_envelope      : in std_logic_vector(17 downto 0); -- Q1.17
        i_adsr_amount        : in std_logic_vector(17 downto 0); -- Q3.15
        -- modulation (LFO)
        i_modulation_en      : in std_logic;
        i_modulation         : in std_logic_vector(17 downto 0); -- Q1.17
        i_modulation_amount  : in std_logic_vector(17 downto 0); -- Q3.15
        -- filter type
        i_filter_type        : in std_logic_vector(1 downto 0);  -- {low pass, high pass, bandpass}
        i_filter_attenuation : in std_logic;                     -- {12dB/Oct, 24dB/Oct}
        -- outputs
        o_output             : out std_logic_vector(g_DATA_WIDTH-1 downto 0); -- Q1.23
        o_data_valid         : out std_logic
    );
end moog_ladder_filter;

architecture arch of moog_ladder_filter is                                                                                                                                                                                                                                                                                                                                                                                                    
--|                                                Moog Ladder Filter Digital Model                                                       
--|                                                                                                                                       
--|                                                                                                                                       
--|                                    +---+                                                                                              
--|                                +---| A |--------------------------------------------------------------------------------+             
--|                                |   +---+             +---+                                                              |             
--|                                |                 +---| B |------------------------------------------------------------+ |             
--|                                |                 |   +---+            +---+                                           | |             
--|                                |                 |                +---| C |-----------------------------------------+ | |             
--|                                |                 |                |   +---+            +---+                        | | |             
--|                                |                 |                |                +---| D |----------------------+ | | |             
--|                                |                 |                |                |   +---+                      | | | |             
--|                                |                 |                |                |                              | | | |             
--|                                |   +----------+  |  +----------+  |  +----------+  |  +----------+                | | | |             
--|                        +---+   |   | one pole |  |  | one pole |  |  | one pole |  |  | one pole |     +---+     +-------+            
--|        input ----------| + |-------|  filter  |-----|  filter  |-----|  filter  |-----|  filter  |-----| E |-----|   +   |----- output
--|                  |     +---+       |          |     |          |     |          |     |          |  |  +---+     +-------+            
--|                  |       |         +----------+     +----------+     +----------+     +----------+  |                                 
--|                  |       |                                                                          |                                 
--|                  |       |    +---+   +---+   +---+                     +----+                      |                                 
--|                  |       +----| 4 |---| g |---| + |---------------------| z?�|----------------------+                                 
--|                  |            +---+   +---+   +---+                     +----+                                                        
--|                  |                              |                                                                                     
--|                  |    +-----+                   |                                                                                     
--|                  +----| 0.5 |-------------------+                                                                                     
--|                       +-----+                                                                                                                                                                          

    type t_data_array       is array (natural range<>) of std_logic_vector(g_DATA_WIDTH-1 downto 0);
    type t_parameter_array     is array (natural range<>) of std_logic_vector(17 downto 0);
    type t_sl_array         is array (natural range<>) of std_logic;
    
    -- input
    signal w_input : signed(g_DATA_WIDTH-1 downto 0);
    
    -- hyperbolic tangent function module input and output 
    signal w_tanh_input : std_logic_vector(g_DATA_WIDTH+3-1 downto 0);
    signal w_tanh_output : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    
    -- connections between one pole filter modules
    signal w_filter_output      : t_data_array(0 to 3);
    signal w_filter_cutoff_freq : t_parameter_array(0 to 3);
    signal w_filter_data_valid  : t_sl_array(0 to 3);
    
    -- feedback shift register output and shift enable
    signal w_feedback_sr_output : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');
    signal w_feedback_sr_en     : std_logic;
    
    
    
    signal r_feedback_sum_a : signed(g_DATA_WIDTH downto 0)    := (others => '0');
    signal r_feedback_prod  : signed(g_DATA_WIDTH+18 downto 0) := (others => '0');
    signal r_feedback_sum_b : signed(g_DATA_WIDTH+2 downto 0)  := (others => '0');
    signal r_feedback_input_z1, r_feedback_input_z2 : signed(g_DATA_WIDTH-1 downto 0) := (others => '0');
    
    signal w_feedforward_a : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    signal w_feedforward_b : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    signal w_feedforward_c : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    signal w_feedforward_d : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    signal w_feedforward_e : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    
    type t_integer_array is array (0 to 4) of integer range -8 to 6;
    
    
    constant c_TWO_POLE_LOW_PASS_COEF   : t_integer_array := (0, 0, 1, 0, 0);
    constant c_FOUR_POLE_LOW_PASS_COEF  : t_integer_array := (0, 0, 0, 0, 1);
    constant c_TWO_POLE_HIGH_PASS_COEF  : t_integer_array := (1,-2, 1, 0, 0);
    constant c_FOUR_POLE_HIGH_PASS_COEF : t_integer_array := (1,-4, 6,-4, 1);
    constant c_TWO_POLE_BAND_PASS_COEF  : t_integer_array := (0, 2,-2, 0, 0);
    constant c_FOUR_POLE_BAND_PASS_COEF : t_integer_array := (0, 0, 4,-8, 4);
    
    signal w_feedforward_coefficients   : t_integer_array;
    --signal r_feedforward_coefficients   : t_integer_array := (others => 0);
    
    signal r_sum_feedforward_a_b     : signed(g_DATA_WIDTH+3-1 downto 0) := (others => '0');
    signal r_sum_feedforward_d_e     : signed(g_DATA_WIDTH+3-1 downto 0) := (others => '0');
    signal r_product_feedforward_c   : signed(g_DATA_WIDTH+3-1 downto 0) := (others => '0');
    signal r_sum_feedforward_a_b_c   : signed(g_DATA_WIDTH+4-1 downto 0) := (others => '0');
    signal r_sum_feedforward_d_e_z1  : signed(g_DATA_WIDTH+3-1 downto 0) := (others => '0');
    signal r_sum_feedforward_total   : signed(g_DATA_WIDTH+5-1 downto 0) := (others => '0');
    
    signal r_data_valid_reg : t_sl_array(0 to 13) := (others => '0');
    signal r_data_valid_output_reg : t_sl_array(0 to 1) := (others => '0');
    
    -- cutoff frequency modulation and correction
    signal r_cutoff_freq           : std_logic_vector(17 downto 0) := (others => '0');
    signal r_adsr_factor           : signed(35 downto 0) := (others => '0');
    signal r_modulation            : signed(17 downto 0) := (others => '0');
    signal r_mod_factor            : signed(35 downto 0) := (others => '0');
    signal r_cutoff_freq_adsr      : signed(36 downto 0) := (others => '0');
    signal r_cutoff_freq_adsr_mod  : signed(37 downto 0) := (others => '0');
    signal r_cutoff_freq_saturated : signed(17 downto 0) := (others => '0');
    signal w_cutoff_freq_corrected : std_logic_vector(17 downto 0);
    
    --signal r_cutoff_freq_mod : std_logic_vector(17 downto 0) := (others => '0');
    
    signal r_output : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');
    
    signal r_freq_reg : t_parameter_array(0 to 1) := (others => (others => '0'));

begin

    w_input <= signed(i_input);

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            r_data_valid_reg(0) <= i_data_valid;
            for idx in 0 to r_data_valid_reg'right-1 loop
                r_data_valid_reg(idx+1) <= r_data_valid_reg(idx);
            end loop;
            
            r_freq_reg(0) <= w_cutoff_freq_corrected;
            r_freq_reg(1) <= r_freq_reg(0);
            
            r_data_valid_output_reg(0) <=  w_filter_data_valid(3);
            r_data_valid_output_reg(1) <= r_data_valid_output_reg(0);
            o_data_valid <= r_data_valid_output_reg(1);
        end if;
    end process;
    
    -- feedback (3 delays)
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- stage 1
            r_feedback_sum_a    <= resize(signed(w_feedback_sr_output), g_DATA_WIDTH+1) - resize(shift_right(w_input, 1), g_DATA_WIDTH+1);
            r_feedback_input_z1 <= w_input;
            -- stage 2 
            r_feedback_prod     <= signed(i_resonance) * r_feedback_sum_a; --2
            r_feedback_input_z2 <= r_feedback_input_z1;
            -- stage 3
            r_feedback_sum_b    <= resize(r_feedback_input_z2, g_DATA_WIDTH+3) - resize(shift_right(r_feedback_prod, 13), g_DATA_WIDTH+3); --15
        end if;
    end process;

    -- feedforward
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- stage 1
            r_sum_feedforward_a_b   <= resize(signed(w_feedforward_a) * w_feedforward_coefficients(0), g_DATA_WIDTH+3) +
                                       resize(signed(w_feedforward_b) * w_feedforward_coefficients(1), g_DATA_WIDTH+3);
                                     
            r_product_feedforward_c <= resize(signed(w_feedforward_c) * w_feedforward_coefficients(2), g_DATA_WIDTH+3);
                                     
            r_sum_feedforward_d_e   <= resize(signed(w_feedforward_d) * w_feedforward_coefficients(3), g_DATA_WIDTH+3) +
                                       resize(signed(w_feedforward_e) * w_feedforward_coefficients(4), g_DATA_WIDTH+3);
            -- stage 2
            r_sum_feedforward_a_b_c <= resize(r_sum_feedforward_a_b, g_DATA_WIDTH+4) + resize(r_product_feedforward_c, g_DATA_WIDTH+4);
            r_sum_feedforward_d_e_z1 <= r_sum_feedforward_d_e;
            
            -- stage 3                        
            r_sum_feedforward_total <= resize(r_sum_feedforward_a_b_c, g_DATA_WIDTH+5) + resize(r_sum_feedforward_d_e_z1, g_DATA_WIDTH+5);
            
        end if;
    end process;
    
    --r_output <= 
    
    process(i_filter_type, i_filter_attenuation)
    begin
        case i_filter_type & i_filter_attenuation is
            when "000"  => w_feedforward_coefficients <= c_TWO_POLE_LOW_PASS_COEF;
            when "001"  => w_feedforward_coefficients <= c_FOUR_POLE_LOW_PASS_COEF;
            when "010"  => w_feedforward_coefficients <= c_TWO_POLE_HIGH_PASS_COEF;
            when "011"  => w_feedforward_coefficients <= c_FOUR_POLE_HIGH_PASS_COEF;
            when "100"  => w_feedforward_coefficients <= c_TWO_POLE_BAND_PASS_COEF;
            when "101"  => w_feedforward_coefficients <= c_FOUR_POLE_BAND_PASS_COEF;
            when others => w_feedforward_coefficients <= c_FOUR_POLE_LOW_PASS_COEF;
        end case; 
    end process;
    
    o_output <= std_logic_vector(resize(r_sum_feedforward_total, g_DATA_WIDTH));

    -- cutoff frequency modulation (4 delays)
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- stage 1
            r_cutoff_freq <= i_cutoff_frequency;
            r_adsr_factor <= signed(i_adsr_envelope) * signed(i_adsr_amount);
            r_modulation  <= signed(i_modulation);
            
            -- stage 2
            r_cutoff_freq_adsr <= shift_left(resize(signed(r_cutoff_freq), 37), 17) + resize(r_adsr_factor, 37);
            if i_modulation_en = '1' then
                r_mod_factor  <= r_modulation * signed(i_modulation_amount);
            else
                r_mod_factor  <= r_modulation * to_signed(0, 18);
            end if;
            
            -- stage 3
            r_cutoff_freq_adsr_mod <= resize(r_mod_factor, 38) + resize(r_cutoff_freq_adsr, 38);
            
            -- stage 4
            if r_cutoff_freq_adsr_mod(37 downto 32) > 0 then        -- positive overflow
                r_cutoff_freq_saturated <= resize(shift_right(r_cutoff_freq_adsr_mod, 17), 18);
            elsif r_cutoff_freq_adsr_mod(37 downto 32) < 0 then  -- negative overflow
                r_cutoff_freq_saturated <= (others => '0');
            else
                r_cutoff_freq_saturated <= resize(shift_right(r_cutoff_freq_adsr_mod, 17), 18);
            end if;
        end if;
    end process;

    -- hyperbolic tangent function (11 delays)
    w_tanh_input <= std_logic_vector(resize(shift_right(r_feedback_sum_b, 0), g_DATA_WIDTH+3));
    tanh_function : entity work.tanh_function(arch_v2)
    port map(
        i_clk    => i_clk,
        i_input  => w_tanh_input,
        o_result => w_tanh_output
    );

    -- polynomial cutoff frequency correction (8 delays) 
    cutoff_freq_correction : entity work.polynomial
    generic map(
        g_DATA_WIDTH   => 18
    )
    port map(
        i_clk     => i_clk,
        i_input   => std_logic_vector(r_cutoff_freq_saturated),
        o_output  => w_cutoff_freq_corrected
    );

    -- one pole filter stage A (5 delays)
    one_pole_filter_a : entity work.one_pole_filter
    generic map(
        g_NUM_CHANNELS => g_NUM_CHANNELS,
        g_DATA_WIDTH   => g_DATA_WIDTH,
        g_COEF_WIDTH   => 18
    )
    port map(
        i_clk => i_clk,
        i_en  => r_data_valid_reg(13),
        i_x   => w_tanh_output,
        i_g   => r_freq_reg(1),
        o_en  => w_filter_data_valid(0),
        o_y   => w_filter_output(0),
        o_g   => w_filter_cutoff_freq(0)
    );
    
    -- one pole filter stage B (5 delays)
    one_pole_filter_b : entity work.one_pole_filter
    generic map(
        g_NUM_CHANNELS => g_NUM_CHANNELS,
        g_DATA_WIDTH   => g_DATA_WIDTH,
        g_COEF_WIDTH   => 18
    )
    port map(
        i_clk => i_clk,
        i_en  => w_filter_data_valid(0),
        i_x   => w_filter_output(0),
        i_g   => w_filter_cutoff_freq(0),
        o_en  => w_filter_data_valid(1),
        o_y   => w_filter_output(1),
        o_g   => w_filter_cutoff_freq(1)
    );
    
    -- one pole filter stage C (5 delays)
    one_pole_filter_c : entity work.one_pole_filter
    generic map(
        g_NUM_CHANNELS => g_NUM_CHANNELS,
        g_DATA_WIDTH   => g_DATA_WIDTH,
        g_COEF_WIDTH   => 18
    )
    port map(
        i_clk => i_clk,
        i_en  => w_filter_data_valid(1),
        i_x   => w_filter_output(1),
        i_g   => w_filter_cutoff_freq(1),
        o_en  => w_filter_data_valid(2),
        o_y   => w_filter_output(2),
        o_g   => w_filter_cutoff_freq(2)
    );
    
    -- one pole filter stage D (5 delays)
    one_pole_filter_d : entity work.one_pole_filter
    generic map(
        g_NUM_CHANNELS => g_NUM_CHANNELS,
        g_DATA_WIDTH   => g_DATA_WIDTH,
        g_COEF_WIDTH   => 18
    )
    port map(
        i_clk => i_clk,
        i_en  => w_filter_data_valid(2),
        i_x   => w_filter_output(2),
        i_g   => w_filter_cutoff_freq(2),
        o_en  => w_filter_data_valid(3),
        o_y   => w_filter_output(3),
        o_g   => open
    );
    
    -- output feedback shift register
    shift_reg_feedback : entity work.shift_register
    generic map(
        g_LENGTH    => g_NUM_CHANNELS,
        g_DATA_SIZE => g_DATA_WIDTH
    )
    port map(
        i_clk  => i_clk,
        i_en   => w_feedback_sr_en,
        i_in   => w_filter_output(3),
        o_out  => w_feedback_sr_output
    );
    
    w_feedback_sr_en <= w_filter_data_valid(3) or i_data_valid;
    
    -- one pole filter A output feedforward shift register
    shift_reg_feedforward_a : entity work.shift_register
    generic map(
        g_LENGTH    => 20,
        g_DATA_SIZE => g_DATA_WIDTH
    )
    port map(
        i_clk  => i_clk,
        i_en   => '1',
        i_in   => w_tanh_output,
        o_out  => w_feedforward_a
    );
    
    -- one pole filter B output feedforward shift register
    shift_reg_feedforward_b : entity work.shift_register
    generic map(
        g_LENGTH    => 15,
        g_DATA_SIZE => g_DATA_WIDTH
    )
    port map(
        i_clk  => i_clk,
        i_en   => '1',
        i_in   => w_filter_output(0),
        o_out  => w_feedforward_b
    );
    
    -- one pole filter C output feedforward shift register
    shift_reg_feedforward_c : entity work.shift_register
    generic map(
        g_LENGTH    => 10,
        g_DATA_SIZE => g_DATA_WIDTH
    )
    port map(
        i_clk  => i_clk,
        i_en   => '1',
        i_in   => w_filter_output(1),
        o_out  => w_feedforward_c
    );
    
    -- one pole filter D output feedforward shift register
    shift_reg_feedforward_d : entity work.shift_register
    generic map(
        g_LENGTH    => 5,
        g_DATA_SIZE => g_DATA_WIDTH
    )
    port map(
        i_clk  => i_clk,
        i_en   => '1',
        i_in   => w_filter_output(2),
        o_out  => w_feedforward_d
    );
    
    w_feedforward_e <= w_filter_output(3);

end arch;