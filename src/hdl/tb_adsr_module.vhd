library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_sim_package.all;
use work.synth_module_sim_package.all;

entity tb_adsr_module is
end tb_adsr_module;

architecture tb of tb_adsr_module is
    
    -- simulation variables
    constant T : time := 10 ns;
    signal finished : std_logic := '0';
    
    -- constants
    constant C_NUM_CHANNELS    : integer := 2;
    constant C_DATA_WIDTH      : integer := 24;
    
    -- types 
    type t_data_array is array (0 to C_NUM_CHANNELS-1) of std_logic_vector(C_DATA_WIDTH-1 downto 0);

    -- signals
    signal axi_aclk      : std_logic := '0';   
    signal axi_aresetn   : std_logic; 
    signal enable        : std_logic;
        
    signal r_output_array : t_data_array := (others => (others => '0'));
    
    signal s_axi_ctrl : t_axi_slave := C_INIT_AXI_SLAVE;
    
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
        adsr_set_sustain_level(axi_aclk, s_axi_ctrl, 0.8);
        adsr_set_attack_time(axi_aclk, s_axi_ctrl, 0.01);
        adsr_set_decay_time(axi_aclk, s_axi_ctrl, 0.005);
        adsr_set_release_time(axi_aclk, s_axi_ctrl, 0.02);

        adsr_set_voice_on(axi_aclk, s_axi_ctrl, 0);

        for i in 0 to 3000 loop
            wait until rising_edge(enable);
        end loop; 
        
        adsr_set_voice_off(axi_aclk, s_axi_ctrl, 0);

        for i in 0 to 2000 loop
            wait until rising_edge(enable);
        end loop;

        finished <= '1';
    end process;
    
    -- receive adsr output process
    process(axi_aclk)
        variable index : integer := 0;
    begin
        m_axis_output.tready <= '1';
        if rising_edge(axi_aclk) then
            if m_axis_output.tvalid = '1' then
                r_output_array(index) <= m_axis_output.tdata(r_output_array(index)'range);
                index := index + 1;
                if index = C_NUM_CHANNELS then
                    index := 0;
                end if;
            end if;
        end if;
    end process;

    -- instantiate adsr module
    adsr_module : entity work.ADSR_v2_0
    generic map(
        g_NUM_CHANNELS => C_NUM_CHANNELS
    )
    port map(
        -- Users to add ports here
        i_enable                => enable,
        o_active_channel_count  => open,

        -- Ports of Axi Slave Bus Interface S_AXI_CTRL
        s_axi_ctrl_aclk	    => axi_aclk,
		s_axi_ctrl_aresetn	=> axi_aresetn,
		s_axi_ctrl_awaddr	=> s_axi_ctrl.awaddr,
		s_axi_ctrl_awprot	=> (others => '0'),
		s_axi_ctrl_awvalid	=> s_axi_ctrl.awvalid,
		s_axi_ctrl_awready	=> s_axi_ctrl.awready,
		s_axi_ctrl_wdata	=> s_axi_ctrl.wdata,
		s_axi_ctrl_wstrb	=> (others => '1'),
		s_axi_ctrl_wvalid	=> s_axi_ctrl.wvalid,
		s_axi_ctrl_wready	=> s_axi_ctrl.wready,
		s_axi_ctrl_bresp	=> open,
		s_axi_ctrl_bvalid	=> s_axi_ctrl.bvalid,
		s_axi_ctrl_bready	=> s_axi_ctrl.bready,
		s_axi_ctrl_araddr	=> s_axi_ctrl.araddr,
		s_axi_ctrl_arprot	=> (others => '0'),
		s_axi_ctrl_arvalid	=> s_axi_ctrl.arvalid,
		s_axi_ctrl_arready	=> s_axi_ctrl.arready,
		s_axi_ctrl_rdata	=> s_axi_ctrl.rdata,
		s_axi_ctrl_rresp	=> open,
		s_axi_ctrl_rvalid	=> s_axi_ctrl.rvalid,
		s_axi_ctrl_rready	=> s_axi_ctrl.rready,

        -- Ports of Axi Master Bus Interface M_AXIS_OUTPUT
        m_axis_output_aclk	    => axi_aclk,
		m_axis_output_aresetn	=> axi_aresetn,
		m_axis_output_tvalid	=> m_axis_output.tvalid,
		m_axis_output_tdata	    => m_axis_output.tdata,
		m_axis_output_tstrb	    => open,
		m_axis_output_tlast	    => open,
		m_axis_output_tready	=> m_axis_output.tready
    );


end tb;