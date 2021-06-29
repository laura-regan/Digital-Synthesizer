library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_sim_package.all;
use work.synth_module_sim_package.all;

entity tb_oscillator_module is
end tb_oscillator_module;

architecture tb of tb_oscillator_module is
    
    -- simulation variables
    constant T : time := 10 ns;
    signal finished : std_logic := '0';
    
    -- oscillator module constants
    constant c_NUM_CHANNELS    : integer := 2;
    constant c_NUM_OSCILLATORS : integer := 3;
    constant c_DATA_WIDTH      : integer := 24;
    
    -- variables
    signal axi_aclk      : std_logic := '0';   
    signal axi_aresetn   : std_logic; 
    signal enable        : std_logic;
        
    type t_data_array is array (0 to C_NUM_CHANNELS-1) of std_logic_vector(c_DATA_WIDTH-1 downto 0);
    signal r_output_array : t_data_array := (others => (others => '0'));
    
    signal s_axi_ctrl_wr : t_axi_slave := C_INIT_AXI_SLAVE;
    
    signal m_axis_output : t_axi_stream_slave;
          
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
        osc_set_frequency(axi_aclk, s_axi_ctrl_wr, 0, 250.0);
        osc_set_frequency(axi_aclk, s_axi_ctrl_wr, 1, 500.0);
        osc_set_waveform(axi_aclk, s_axi_ctrl_wr, 0, SINE);
        osc_set_waveform(axi_aclk, s_axi_ctrl_wr, 1, SINE);
        osc_set_waveform(axi_aclk, s_axi_ctrl_wr, 2, SINE);
        osc_set_amplitude(axi_aclk, s_axi_ctrl_wr, 0, 1.0);
        osc_set_amplitude(axi_aclk, s_axi_ctrl_wr, 1, 0.0);
        osc_set_amplitude(axi_aclk, s_axi_ctrl_wr, 2, 0.0);
        osc_set_pulse_width(axi_aclk, s_axi_ctrl_wr, 0, 0.50);

        for i in 0 to 1000 loop
            wait until rising_edge(enable);
        end loop;                      

        osc_set_waveform(axi_aclk, s_axi_ctrl_wr, 0, SAW);

        for i in 0 to 1000 loop
            wait until rising_edge(enable);
        end loop;
        
        osc_set_waveform(axi_aclk, s_axi_ctrl_wr, 0, TRIANGLE);

        for i in 0 to 1000 loop
            wait until rising_edge(enable);
        end loop;
        
        osc_set_waveform(axi_aclk, s_axi_ctrl_wr, 0, SQUARE);
       osc_set_pulse_width(axi_aclk, s_axi_ctrl_wr, 0, 0.75);

        for i in 0 to 2000 loop
            wait until rising_edge(enable);
        end loop; 
        
        finished <= '1';
    end process;
    
    -- receive oscillator output process
    process(axi_aclk)
        variable index : integer := 0;
    begin
        m_axis_output.tready <= '1';
        if rising_edge(axi_aclk) then
            if m_axis_output.tvalid = '1' then
                r_output_array(index) <= m_axis_output.tdata(r_output_array(index)'range);
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
        i_en                => enable,

		-- Ports of Axi Slave Bus Interface S_AXI_CTRL
		s_axi_ctrl_aclk	    => axi_aclk,
		s_axi_ctrl_aresetn	=> axi_aresetn,
		s_axi_ctrl_awaddr	=> s_axi_ctrl_wr.awaddr,
		s_axi_ctrl_awprot	=> (others => '0'),
		s_axi_ctrl_awvalid	=> s_axi_ctrl_wr.awvalid,
		s_axi_ctrl_awready	=> s_axi_ctrl_wr.awready,
		s_axi_ctrl_wdata	=> s_axi_ctrl_wr.wdata,
		s_axi_ctrl_wstrb	=> (others => '1'),
		s_axi_ctrl_wvalid	=> s_axi_ctrl_wr.wvalid,
		s_axi_ctrl_wready	=> s_axi_ctrl_wr.wready,
		s_axi_ctrl_bresp	=> open,
		s_axi_ctrl_bvalid	=> s_axi_ctrl_wr.bvalid,
		s_axi_ctrl_bready	=> s_axi_ctrl_wr.bready,
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
		m_axis_output_tvalid	=> m_axis_output.tvalid,
		m_axis_output_tdata	    => m_axis_output.tdata,
		m_axis_output_tstrb	    => open,
		m_axis_output_tlast	    => open,
		m_axis_output_tready	=> m_axis_output.tready,

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


end tb;