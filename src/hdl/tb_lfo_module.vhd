library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_sim_package.all;
use work.synth_module_sim_package.all;

entity tb_lfo_module is
end tb_lfo_module;

architecture tb of tb_lfo_module is
    
    -- simulation variables
    constant T : time := 10 ns;
    signal finished : std_logic := '0';
    
    -- oscillator module constants
    constant c_NUM_CHANNELS    : integer := 2;
    constant c_NUM_OSCILLATORS : integer := 2;
    constant c_DATA_WIDTH      : integer := 24;
    
    -- signals
    signal axi_aclk      : std_logic := '0';   
    signal axi_aresetn   : std_logic; 
    signal enable        : std_logic;
        
    type t_data_array is array (0 to C_NUM_CHANNELS-1) of std_logic_vector(c_DATA_WIDTH-1 downto 0);
    signal r_osc_output_array : t_data_array := (others => (others => '0'));
    signal r_lfo1_output_array : t_data_array := (others => (others => '0'));
    signal r_lfo2_output_array : t_data_array := (others => (others => '0'));
    
    signal s_axi_osc_ctrl : t_axi_slave := C_INIT_AXI_SLAVE;
    signal s_axi_lfo1_ctrl : t_axi_slave := C_INIT_AXI_SLAVE;
    signal s_axi_lfo2_ctrl : t_axi_slave := C_INIT_AXI_SLAVE;
    
    signal m_axis_osc_output : t_axi_stream_slave;
    signal m_axis_lfo1_output : t_axi_stream_slave;
    signal m_axis_lfo2_output : t_axi_stream_slave;
          
begin
    
    -- generate clk and resetn
    axi_aclk    <= not axi_aclk after T/2 when finished /= '1' else '0';
    axi_aresetn <= '0', '1' after T;
    
    -- generate module enable
    process
    begin
        enable <= '0';
        for i in 0 to 19 loop
            wait until rising_edge(axi_aclk);
        end loop;
        enable <= '1';
        wait until rising_edge(axi_aclk);
    end process;
    
    -- main process
    process
    begin
        osc_set_frequency(axi_aclk, s_axi_osc_ctrl, 0, 500.0);
        osc_set_frequency(axi_aclk, s_axi_osc_ctrl, 1, 1000.0);
        osc_set_waveform(axi_aclk, s_axi_osc_ctrl, 0, SQUARE);
        osc_set_amplitude(axi_aclk, s_axi_osc_ctrl, 0, 1.0);
        osc_set_amplitude(axi_aclk, s_axi_osc_ctrl, 1, 0.0);
        osc_set_pulse_width(axi_aclk, s_axi_osc_ctrl, 0, 0.0);
        osc_pwm_enable(axi_aclk, s_axi_osc_ctrl, 0);

--        lfo_set_amount(axi_aclk, s_axi_lfo1_ctrl, 0.8);
--        lfo_set_rate(axi_aclk, s_axi_lfo1_ctrl, 0.02);
--        lfo_set_waveform(axi_aclk, s_axi_lfo1_ctrl, SAW);
--        lfo_set_voice_on(axi_aclk, s_axi_lfo1_ctrl, 0);
--        lfo_set_voice_on(axi_aclk, s_axi_lfo1_ctrl, 1);
        
        lfo_set_amount(axi_aclk, s_axi_lfo2_ctrl, 0.8);
        lfo_set_rate(axi_aclk, s_axi_lfo2_ctrl, 0.02);
        lfo_set_waveform(axi_aclk, s_axi_lfo2_ctrl, TRIANGLE);
        lfo_set_voice_on(axi_aclk, s_axi_lfo2_ctrl, 0);
        lfo_enable_polyphony(axi_aclk, s_axi_lfo2_ctrl, '0');
        
        for i in 0 to 3000 loop
            wait until rising_edge(enable);
        end loop;     
        
        lfo_set_voice_on(axi_aclk, s_axi_lfo2_ctrl, 1);
        
        for i in 0 to 3000 loop
            wait until rising_edge(enable);
        end loop;                    

--        osc_set_waveform(axi_aclk, s_axi_ctrl_wr, 0, SAW);

--        for i in 0 to 1000 loop
--            wait until rising_edge(enable);
--        end loop;
        
--        osc_set_waveform(axi_aclk, s_axi_ctrl_wr, 0, TRIANGLE);

--        for i in 0 to 1000 loop
--            wait until rising_edge(enable);
--        end loop;
        
--        osc_set_waveform(axi_aclk, s_axi_ctrl_wr, 0, SQUARE);
       --osc_set_pulse_width(axi_aclk, s_axi_ctrl_wr, 0, 0.75);

        for i in 0 to 2000 loop
            wait until rising_edge(enable);
        end loop; 
        
        finished <= '1';
    end process;
    
    -- receive lfo output process
    process(axi_aclk)
        variable index : integer := 0;
    begin
        if rising_edge(axi_aclk) then
            if m_axis_lfo1_output.tvalid = '1' then
                r_lfo1_output_array(index) <= m_axis_lfo1_output.tdata(r_lfo1_output_array(index)'range);
                index := index + 1;
                if index = c_NUM_CHANNELS then
                    index := 0;
                end if;
            end if;
        end if;
    end process;
    
    -- receive lfo output process
    process(axi_aclk)
        variable index : integer := 0;
    begin
        if rising_edge(axi_aclk) then
            if m_axis_lfo2_output.tvalid = '1' then
                r_lfo2_output_array(index) <= m_axis_lfo2_output.tdata(r_lfo2_output_array(index)'range);
                index := index + 1;
                if index = c_NUM_CHANNELS then
                    index := 0;
                end if;
            end if;
        end if;
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

    lfo_module1 : entity work.LFO_v1_0
        generic map(
            -- LFO parameters
            g_NUM_CHANNELS => c_NUM_CHANNELS
        )
        port map(
            -- Module enable
            i_enable            => enable,

            -- Ports of Axi Slave Bus Interface S_AXI_CTRL
            s_axi_ctrl_aclk	    => axi_aclk,
            s_axi_ctrl_aresetn	=> axi_aresetn,
            s_axi_ctrl_awaddr	=> s_axi_lfo1_ctrl.awaddr(4 downto 0),
            s_axi_ctrl_awprot	=> (others => '0'),
            s_axi_ctrl_awvalid	=> s_axi_lfo1_ctrl.awvalid,
            s_axi_ctrl_awready	=> s_axi_lfo1_ctrl.awready,
            s_axi_ctrl_wdata	=> s_axi_lfo1_ctrl.wdata,
            s_axi_ctrl_wstrb	=> (others => '1'),
            s_axi_ctrl_wvalid	=> s_axi_lfo1_ctrl.wvalid,
            s_axi_ctrl_wready	=> s_axi_lfo1_ctrl.wready,
            s_axi_ctrl_bresp	=> open,
            s_axi_ctrl_bvalid	=> s_axi_lfo1_ctrl.bvalid,
            s_axi_ctrl_bready	=> s_axi_lfo1_ctrl.bready,
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
            m_axis_output_tvalid	=> m_axis_lfo1_output.tvalid,
            m_axis_output_tdata	    => m_axis_lfo1_output.tdata,
            m_axis_output_tstrb	    => open,
            m_axis_output_tlast	    => open,
            m_axis_output_tready	=> m_axis_lfo1_output.tready
        );
    
    lfo_module2 : entity work.LFO_v1_0
        generic map(
            -- LFO parameters
            g_NUM_CHANNELS => c_NUM_CHANNELS
        )
        port map(
            -- Module enable
            i_enable            => enable,

            -- Ports of Axi Slave Bus Interface S_AXI_CTRL
            s_axi_ctrl_aclk	    => axi_aclk,
            s_axi_ctrl_aresetn	=> axi_aresetn,
            s_axi_ctrl_awaddr	=> s_axi_lfo2_ctrl.awaddr(4 downto 0),
            s_axi_ctrl_awprot	=> (others => '0'),
            s_axi_ctrl_awvalid	=> s_axi_lfo2_ctrl.awvalid,
            s_axi_ctrl_awready	=> s_axi_lfo2_ctrl.awready,
            s_axi_ctrl_wdata	=> s_axi_lfo2_ctrl.wdata,
            s_axi_ctrl_wstrb	=> (others => '1'),
            s_axi_ctrl_wvalid	=> s_axi_lfo2_ctrl.wvalid,
            s_axi_ctrl_wready	=> s_axi_lfo2_ctrl.wready,
            s_axi_ctrl_bresp	=> open,
            s_axi_ctrl_bvalid	=> s_axi_lfo2_ctrl.bvalid,
            s_axi_ctrl_bready	=> s_axi_lfo2_ctrl.bready,
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
            m_axis_output_tvalid	=> m_axis_lfo2_output.tvalid,
            m_axis_output_tdata	    => m_axis_lfo2_output.tdata,
            m_axis_output_tstrb	    => open,
            m_axis_output_tlast	    => open,
            m_axis_output_tready	=> m_axis_lfo2_output.tready
        );

    -- instantiate oscillator module
    oscillator_module : entity work.Oscillator_v2_0
	generic map (
		-- Oscillator parameters
        g_NUM_CHANNELS    => c_NUM_CHANNELS,
        g_NUM_OSCILLATORS => c_NUM_OSCILLATORS
	)
	port map(
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
		s_axis_freq_mod_tready	=> m_axis_lfo1_output.tready,
		s_axis_freq_mod_tdata	=> m_axis_lfo1_output.tdata,
		s_axis_freq_mod_tstrb	=> (others => '0'),
		s_axis_freq_mod_tlast	=> '0',
		s_axis_freq_mod_tvalid	=> m_axis_lfo1_output.tvalid,

		-- Ports of Axi Slave Bus Interface S_AXIS_PWM
		s_axis_pwm_aclk	    => axi_aclk,
		s_axis_pwm_aresetn	=> axi_aresetn,
		s_axis_pwm_tready	=> m_axis_lfo2_output.tready,
		s_axis_pwm_tdata	=> m_axis_lfo2_output.tdata,
		s_axis_pwm_tstrb	=> (others => '0'),
		s_axis_pwm_tlast	=> '0',
		s_axis_pwm_tvalid	=> m_axis_lfo2_output.tvalid
	);


end tb;