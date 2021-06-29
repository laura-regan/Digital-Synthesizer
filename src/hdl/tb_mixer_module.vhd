library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_sim_package.all;
use work.synth_module_sim_package.all;

entity tb_mixer_module is
end tb_mixer_module;

architecture tb of tb_mixer_module is
    
    -- simulation variables
    constant T : time := 10ns;--:= 27.12 ns;
    signal finished : std_logic := '0';
    
    -- constants
    constant C_NUM_CHANNELS    : integer := 4;
    constant C_NUM_OSCILLATORS : integer := 2;
    constant C_DATA_WIDTH      : integer := 24;
    
    -- types
    type t_data_array is array (0 to C_NUM_CHANNELS-1) of std_logic_vector(C_DATA_WIDTH-1 downto 0);

    -- signals
    -- module enable
    signal enable        : std_logic;
    -- axi signals
    signal axi_aclk      : std_logic := '0';   
    signal axi_aresetn   : std_logic; 
    -- axi lite interfaces
    signal s_axi_osc_ctrl  : t_axi_slave := C_INIT_AXI_SLAVE;
    signal s_axi_adsr_ctrl : t_axi_slave := C_INIT_AXI_SLAVE;
    -- axi stream interfaces
    signal m_axis_osc_output  : t_axi_stream_slave;
    signal m_axis_adsr_output : t_axi_stream_slave;
    signal m_axis_nca_output  : t_axi_stream_slave;
    -- output arrays
    signal r_osc_output_array  : t_data_array := (others => (others => '0'));
    signal r_adsr_output_array : t_data_array := (others => (others => '0'));
    signal r_nca_output_array  : t_data_array := (others => (others => '0'));
    --
    signal w_active_channels   : std_logic_vector(6 downto 0);
    signal w_mixer_output      : std_logic_vector(23 downto 0);
          
begin
    
    -- generate clk and resetn
    axi_aclk    <= not axi_aclk after T/2 when finished /= '1' else '0';
    axi_aresetn <= '0', '1' after T;
    
    -- generate module enable
    process
    begin
        enable <= '0';
        for i in 0 to 40 loop
            wait until rising_edge(axi_aclk);
        end loop;
        enable <= '1';
        wait until rising_edge(axi_aclk);
    end process;
    
    -- main process
    process
    begin
        -- configure oscillator
        osc_set_frequency(axi_aclk, s_axi_osc_ctrl, 0, 500.0);
        osc_set_frequency(axi_aclk, s_axi_osc_ctrl, 1, 500.0);
        osc_set_frequency(axi_aclk, s_axi_osc_ctrl, 2, 500.0);
        osc_set_frequency(axi_aclk, s_axi_osc_ctrl, 3, 500.0);
        osc_set_waveform(axi_aclk, s_axi_osc_ctrl, 0, SINE);
        osc_set_amplitude(axi_aclk, s_axi_osc_ctrl, 0, 1.0);
        osc_set_amplitude(axi_aclk, s_axi_osc_ctrl, 1, 0.0);

        -- configure adsr
        adsr_set_sustain_level(axi_aclk, s_axi_adsr_ctrl, 0.7);
        adsr_set_attack_time(axi_aclk, s_axi_adsr_ctrl, 0.01);
        adsr_set_decay_time(axi_aclk, s_axi_adsr_ctrl, 0.005);
        adsr_set_release_time(axi_aclk, s_axi_adsr_ctrl, 0.02);

        adsr_set_voice_on(axi_aclk, s_axi_adsr_ctrl, 0);

        for i in 0 to 1000 loop
            wait until rising_edge(enable);
        end loop; 

        adsr_set_voice_on(axi_aclk, s_axi_adsr_ctrl, 1);

        for i in 0 to 1000 loop
            wait until rising_edge(enable);
        end loop; 
        
--        adsr_set_voice_on(axi_aclk, s_axi_adsr_ctrl, 2);
--        --adsr_set_voice_off(axi_aclk, s_axi_adsr_ctrl, 0);

--        for i in 0 to 1000 loop
--            wait until rising_edge(enable);
--        end loop;

--        adsr_set_voice_on(axi_aclk, s_axi_adsr_ctrl, 3);
--        --adsr_set_voice_off(axi_aclk, s_axi_adsr_ctrl, 1);

--        for i in 0 to 3000 loop
--            wait until rising_edge(enable);
--        end loop;
        
        finished <= '1';
    end process;
    
    -- receive oscillator output process
    process(axi_aclk)
        variable index : integer := 0;
    begin
        m_axis_osc_output.tready <= '1';
        if rising_edge(axi_aclk) then
            if m_axis_osc_output.tvalid = '1' then
                r_osc_output_array(index) <= m_axis_osc_output.tdata(r_osc_output_array(index)'range);
                index := index + 1;
                if index = c_NUM_CHANNELS then
                    index := 0;
                end if;
            end if;
        end if;
    end process;

    -- receive adsr output process
    process(axi_aclk)
        variable index : integer := 0;
    begin
        m_axis_adsr_output.tready <= '1';
        if rising_edge(axi_aclk) then
            if m_axis_adsr_output.tvalid = '1' then
                r_adsr_output_array(index) <= m_axis_adsr_output.tdata(r_adsr_output_array(index)'range);
                index := index + 1;
                if index = c_NUM_CHANNELS then
                    index := 0;
                end if;
            end if;
        end if;
    end process;

    -- receive nca output process
    process(axi_aclk)
        variable index : integer := 0;
    begin
        m_axis_nca_output.tready <= '1';
        if rising_edge(axi_aclk) then
            if m_axis_nca_output.tvalid = '1' then
                r_nca_output_array(index) <= m_axis_nca_output.tdata(r_nca_output_array(index)'range);
                index := index + 1;
                if index = c_NUM_CHANNELS then
                    index := 0;
                end if;
            end if;
        end if;
    end process;

    -- instantiate oscillator module
    oscillator_module : entity work.Oscillator_v2_0
	generic map (
		-- Oscillator parameters
        g_NUM_CHANNELS    => c_NUM_CHANNELS,
        g_NUM_OSCILLATORS => c_NUM_OSCILLATORS
	)
	port map(
		-- Users to add ports here
        i_en                => enable,

		-- Ports of Axi Slave Bus Interface S_AXI_CTRL
		s_axi_ctrl_aclk	    => axi_aclk,
		s_axi_ctrl_aresetn	=> axi_aresetn,
		s_axi_ctrl_awaddr	=> s_axi_osc_ctrl.awaddr,
		s_axi_ctrl_awprot	=> (others => '0'),
		s_axi_ctrl_awvalid	=> s_axi_osc_ctrl.awvalid,
		s_axi_ctrl_awready	=> s_axi_osc_ctrl.awready,
		s_axi_ctrl_wdata	=> s_axi_osc_ctrl.wdata,
		s_axi_ctrl_wstrb	=> (others => '1'),
		s_axi_ctrl_wvalid	=> s_axi_osc_ctrl.wvalid,
		s_axi_ctrl_wready	=> s_axi_osc_ctrl.wready,
		s_axi_ctrl_bresp	=> open,
		s_axi_ctrl_bvalid	=> s_axi_osc_ctrl.bvalid,
		s_axi_ctrl_bready	=> s_axi_osc_ctrl.bready,
		s_axi_ctrl_araddr	=> (others => '0'),
		s_axi_ctrl_arprot	=> (others => '0'),
		s_axi_ctrl_arvalid	=> '0',
		s_axi_ctrl_arready	=> open,
		s_axi_ctrl_rdata	=> open,
		s_axi_ctrl_rresp	=> open,
		s_axi_ctrl_rvalid	=> open,
		s_axi_ctrl_rready	=> '0',

		-- Ports of Axi Master Bus Interface M_AXIS_OUTPUT
		m_axis_output_aclk	    => axi_aclk,
		m_axis_output_aresetn	=> axi_aresetn,
		m_axis_output_tvalid	=> m_axis_osc_output.tvalid,
		m_axis_output_tdata	    => m_axis_osc_output.tdata,
		m_axis_output_tstrb	    => open,
		m_axis_output_tlast	    => open,
		m_axis_output_tready	=> m_axis_osc_output.tready,

		-- Ports of Axi Slave Bus Interface S_AXIS_FREQ_MOD
		s_axis_freq_mod_aclk	=> axi_aclk,
		s_axis_freq_mod_aresetn	=> axi_aresetn,
		s_axis_freq_mod_tready	=> open,
		s_axis_freq_mod_tdata	=> (others => '0'),
		s_axis_freq_mod_tstrb	=> (others => '0'),
		s_axis_freq_mod_tlast	=> '0',
		s_axis_freq_mod_tvalid	=> '0',

		-- Ports of Axi Slave Bus Interface S_AXIS_PWM
		s_axis_pwm_aclk	    => axi_aclk,
		s_axis_pwm_aresetn	=> axi_aresetn,
		s_axis_pwm_tready	=> open,
		s_axis_pwm_tdata	=> (others => '0'),
		s_axis_pwm_tstrb	=> (others => '0'),
		s_axis_pwm_tlast	=> '0',
		s_axis_pwm_tvalid	=> '0'
	);

    -- instantiate adsr module
    adsr_module : entity work.ADSR_v2_0
    generic map(
        g_NUM_CHANNELS => C_NUM_CHANNELS
    )
    port map(
        -- Users to add ports here
        i_enable                => enable,
        o_active_channel_count  => w_active_channels,

        -- Ports of Axi Slave Bus Interface S_AXI_CTRL
        s_axi_ctrl_aclk	    => axi_aclk,
		s_axi_ctrl_aresetn	=> axi_aresetn,
		s_axi_ctrl_awaddr	=> s_axi_adsr_ctrl.awaddr,
		s_axi_ctrl_awprot	=> (others => '0'),
		s_axi_ctrl_awvalid	=> s_axi_adsr_ctrl.awvalid,
		s_axi_ctrl_awready	=> s_axi_adsr_ctrl.awready,
		s_axi_ctrl_wdata	=> s_axi_adsr_ctrl.wdata,
		s_axi_ctrl_wstrb	=> (others => '1'),
		s_axi_ctrl_wvalid	=> s_axi_adsr_ctrl.wvalid,
		s_axi_ctrl_wready	=> s_axi_adsr_ctrl.wready,
		s_axi_ctrl_bresp	=> open,
		s_axi_ctrl_bvalid	=> s_axi_adsr_ctrl.bvalid,
		s_axi_ctrl_bready	=> s_axi_adsr_ctrl.bready,
		s_axi_ctrl_araddr	=> s_axi_adsr_ctrl.araddr,
		s_axi_ctrl_arprot	=> (others => '0'),
		s_axi_ctrl_arvalid	=> s_axi_adsr_ctrl.arvalid,
		s_axi_ctrl_arready	=> s_axi_adsr_ctrl.arready,
		s_axi_ctrl_rdata	=> s_axi_adsr_ctrl.rdata,
		s_axi_ctrl_rresp	=> open,
		s_axi_ctrl_rvalid	=> s_axi_adsr_ctrl.rvalid,
		s_axi_ctrl_rready	=> s_axi_adsr_ctrl.rready,

        -- Ports of Axi Master Bus Interface M_AXIS_OUTPUT
        m_axis_output_aclk	    => axi_aclk,
		m_axis_output_aresetn	=> axi_aresetn,
		m_axis_output_tvalid	=> m_axis_adsr_output.tvalid,
		m_axis_output_tdata	    => m_axis_adsr_output.tdata,
		m_axis_output_tstrb	    => open,
		m_axis_output_tlast	    => open,
		m_axis_output_tready	=> m_axis_adsr_output.tready
    );

    nca_module : entity work.Multiplier_v2_0
        generic map(
            g_NUM_CHANNELS   => C_NUM_CHANNELS
        )
        port map(
            -- Users to add ports here
            i_enable => enable,
    
            -- Ports of Axi Slave Bus Interface S_AXIS_INPUT
            s_axis_input_aclk	    => axi_aclk,
            s_axis_input_aresetn	=> axi_aresetn,
            s_axis_input_tready	    => m_axis_osc_output.tready,
            s_axis_input_tdata	    => m_axis_osc_output.tdata,
            s_axis_input_tstrb	    => (others => '0'),
            s_axis_input_tlast	    => '0',
            s_axis_input_tvalid	    => m_axis_osc_output.tvalid,
    
            -- Ports of Axi Slave Bus Interface S_AXIS_ENVELOPE
            s_axis_envelope_aclk	    => axi_aclk,
            s_axis_envelope_aresetn	    => axi_aresetn,
            s_axis_envelope_tready	    => m_axis_adsr_output.tready,
            s_axis_envelope_tdata	    => m_axis_adsr_output.tdata,
            s_axis_envelope_tstrb	    => (others => '0'),
            s_axis_envelope_tlast	    => '0',
            s_axis_envelope_tvalid	    => m_axis_adsr_output.tvalid,
    
            -- Ports of Axi Master Bus Interface M_AXIS_OUTPUT
            m_axis_output_aclk	    => axi_aclk,
            m_axis_output_aresetn	=> axi_aresetn,
            m_axis_output_tvalid	=> m_axis_nca_output.tvalid,
            m_axis_output_tdata	    => m_axis_nca_output.tdata,
            m_axis_output_tstrb	    => open,
            m_axis_output_tlast	    => open,
            m_axis_output_tready	=> m_axis_nca_output.tready
        );


    mixer_module: entity work.Mixer_v2_0 
    generic map(
        g_NUM_CHANNELS      => C_NUM_CHANNELS
    )
    port map(
        i_en                => enable,
        i_active_channels   => w_active_channels,
        o_output            => w_mixer_output,

        -- Ports of Axi Slave Bus Interface S_AXIS_INPUT
        s_axis_input_aclk	    => axi_aclk,
        s_axis_input_aresetn	=> axi_aresetn,
        s_axis_input_tready	    => m_axis_nca_output.tready,
        s_axis_input_tdata	    => m_axis_nca_output.tdata,
        s_axis_input_tstrb	    => (others => '0'),
        s_axis_input_tlast	    => '0',
        s_axis_input_tvalid	    => m_axis_nca_output.tvalid
        );
end tb;