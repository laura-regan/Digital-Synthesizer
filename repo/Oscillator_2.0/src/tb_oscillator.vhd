library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tb_oscillator is
end tb_oscillator;

architecture arch of tb_oscillator is

        constant c_NUM_CHANNELS : integer := 4;
        constant T : time := 10 ns;

        signal r_clk           : std_logic;    
        signal r_data_valid_in : std_logic;                                   
        -- ctrls 
        signal r_wave_select : std_logic_vector(1 downto 0);                  
        signal r_amplitude   : std_logic_vector(17 downto 0); 
        signal r_fcw         : std_logic_vector(17 downto 0);                
        signal r_detune      : std_logic_vector(17 downto 0);
        signal r_freq_mod    : std_logic_vector(17 downto 0);                 
        signal r_mod_en      : std_logic;                                     
        signal r_pulse_width : std_logic_vector(23 downto 0);     
        signal r_pw_mod      : std_logic_vector(23 downto 0);                 
        signal r_pwm_en      : std_logic;                                     
        signal r_output      : std_logic_vector(23 downto 0);    
        signal r_data_valid_out : std_logic;
        
        type t_output_array is array (0 to c_NUM_CHANNELS-1) of std_logic_vector(23 downto 0);
        signal r_output_array : t_output_array := (others => (others => '0'));
        signal index : integer := 0;
begin


    oscillator_unit: entity work.oscillator 
    generic map(
        g_NUM_CHANNELS    => c_NUM_CHANNELS
    )
    port map(
        i_clk         => r_clk,   
        i_data_valid  => r_data_valid_in,   
        -- ctrls 
        i_wave_select => r_wave_select,   
        i_amplitude   => r_amplitude,   
        i_fcw         => r_fcw,   
        i_detune      => r_detune,   
        i_freq_mod    => r_freq_mod,   
        i_mod_en      => r_mod_en,   
        i_pulse_width => r_pulse_width,   
        i_pw_mod      => r_pw_mod,   
        i_pwm_en      => r_pwm_en,   
        o_output      => r_output,   
        o_data_valid  => r_data_valid_out
    );

    process
    begin
        r_clk <= '1';
        wait for T/2;
        r_clk <= '0';
        wait for T/2;
    end process;
    
    process
    begin
        r_data_valid_in <= '0';
        r_wave_select   <= "11";
        r_amplitude     <= std_logic_vector(to_signed(2**(r_amplitude'length-1)-1, r_amplitude'length)); -- Max
        r_fcw           <= std_logic_vector(to_unsigned(1000, r_fcw'length));
        r_detune        <= std_logic_vector(to_unsigned(0, r_detune'length));
        r_freq_mod      <= std_logic_vector(to_unsigned(0, r_freq_mod'length));
        r_mod_en        <= '0';
        r_pulse_width   <= std_logic_vector(to_signed(2**21, r_pulse_width'length)); -- 50%
        r_pw_mod        <= std_logic_vector(to_signed(0, r_pw_mod'length));
        r_pwm_en        <= '0';
        
        wait until rising_edge(r_clk);
        
        r_data_valid_in <= '1';
        for Idx in 0 to 1048*5*c_NUM_CHANNELS loop
            wait until rising_edge(r_clk);
        end loop;
        
        assert false
            report "Simulation completed"
            severity failure;
        
    end process;
    
    process(r_clk)
    begin
        if rising_edge(r_clk) then
            if r_data_valid_out = '1' then
                r_output_array(index) <= r_output;
                
                if index = c_NUM_CHANNELS-1 then
                    index <= 0;
                else
                    index <= index + 1;
                end if;
            end if;
        end if;
    end process;


end arch;