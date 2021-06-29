library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Oscillator_v2_0 is
	generic (
		-- Users to add parameters here
        g_NUM_CHANNELS    : integer    := 128;
        g_NUM_OSCILLATORS : integer    := 2;
        g_DATA_WIDTH      : integer    := 24;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S_AXI_CTRL
		C_S_AXI_CTRL_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_CTRL_ADDR_WIDTH	: integer	:= 6;

		-- Parameters of Axi Master Bus Interface M_AXIS_OUTPUT
		C_M_AXIS_OUTPUT_TDATA_WIDTH	: integer	:= 32;
		C_M_AXIS_OUTPUT_START_COUNT	: integer	:= 32;

		-- Parameters of Axi Slave Bus Interface S_AXIS_FREQ_MOD
		C_S_AXIS_FREQ_MOD_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Slave Bus Interface S_AXIS_PWM
		C_S_AXIS_PWM_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here
        i_en : in std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S_AXI_CTRL
		s_axi_ctrl_aclk	: in std_logic;
		s_axi_ctrl_aresetn	: in std_logic;
		s_axi_ctrl_awaddr	: in std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
		s_axi_ctrl_awprot	: in std_logic_vector(2 downto 0);
		s_axi_ctrl_awvalid	: in std_logic;
		s_axi_ctrl_awready	: out std_logic;
		s_axi_ctrl_wdata	: in std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
		s_axi_ctrl_wstrb	: in std_logic_vector((C_S_AXI_CTRL_DATA_WIDTH/8)-1 downto 0);
		s_axi_ctrl_wvalid	: in std_logic;
		s_axi_ctrl_wready	: out std_logic;
		s_axi_ctrl_bresp	: out std_logic_vector(1 downto 0);
		s_axi_ctrl_bvalid	: out std_logic;
		s_axi_ctrl_bready	: in std_logic;
		s_axi_ctrl_araddr	: in std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
		s_axi_ctrl_arprot	: in std_logic_vector(2 downto 0);
		s_axi_ctrl_arvalid	: in std_logic;
		s_axi_ctrl_arready	: out std_logic;
		s_axi_ctrl_rdata	: out std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
		s_axi_ctrl_rresp	: out std_logic_vector(1 downto 0);
		s_axi_ctrl_rvalid	: out std_logic;
		s_axi_ctrl_rready	: in std_logic;

		-- Ports of Axi Master Bus Interface M_AXIS_OUTPUT
		m_axis_output_aclk	: in std_logic;
		m_axis_output_aresetn	: in std_logic;
		m_axis_output_tvalid	: out std_logic;
		m_axis_output_tdata	: out std_logic_vector(C_M_AXIS_OUTPUT_TDATA_WIDTH-1 downto 0);
		m_axis_output_tstrb	: out std_logic_vector((C_M_AXIS_OUTPUT_TDATA_WIDTH/8)-1 downto 0);
		m_axis_output_tlast	: out std_logic;
		m_axis_output_tready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S_AXIS_FREQ_MOD
		s_axis_freq_mod_aclk	: in std_logic;
		s_axis_freq_mod_aresetn	: in std_logic;
		s_axis_freq_mod_tready	: out std_logic;
		s_axis_freq_mod_tdata	: in std_logic_vector(C_S_AXIS_FREQ_MOD_TDATA_WIDTH-1 downto 0);
		s_axis_freq_mod_tstrb	: in std_logic_vector((C_S_AXIS_FREQ_MOD_TDATA_WIDTH/8)-1 downto 0);
		s_axis_freq_mod_tlast	: in std_logic;
		s_axis_freq_mod_tvalid	: in std_logic;

		-- Ports of Axi Slave Bus Interface S_AXIS_PWM
		s_axis_pwm_aclk	: in std_logic;
		s_axis_pwm_aresetn	: in std_logic;
		s_axis_pwm_tready	: out std_logic;
		s_axis_pwm_tdata	: in std_logic_vector(C_S_AXIS_PWM_TDATA_WIDTH-1 downto 0);
		s_axis_pwm_tstrb	: in std_logic_vector((C_S_AXIS_PWM_TDATA_WIDTH/8)-1 downto 0);
		s_axis_pwm_tlast	: in std_logic;
		s_axis_pwm_tvalid	: in std_logic
	);
end Oscillator_v2_0;

architecture arch_imp of Oscillator_v2_0 is
 
	-- output fifo signals
	signal w_output_fifo_wr_en   : std_logic;
	signal w_output_fifo_wr_data : std_logic_vector(g_DATA_WIDTH-1 downto 0);
	signal w_output_fifo_full    : std_logic;
	-- pulse width modulation fifo signals
	signal w_pwm_fifo_rd_en   : std_logic;
    signal w_pwm_fifo_rd_data : std_logic_vector(g_DATA_WIDTH-1 downto 0);
	signal w_pwm_fifo_empty   : std_logic;
	-- frequency modulation fifo signals
	signal w_modulation_fifo_rd_en   : std_logic;
    signal w_modulation_fifo_rd_data : std_logic_vector(g_DATA_WIDTH-1 downto 0);
	signal w_modulation_fifo_empty   : std_logic;
    -- oscillator control signals
    signal w_oscillator_select : std_logic_vector(1 downto 0);
    signal w_channel_select    : std_logic_vector(6 downto 0);
    signal w_mod_enable  : std_logic;
    signal w_pwm_enable  : std_logic;
    signal w_pulse_width : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    signal w_wave_select : std_logic_vector(1 downto 0);
    signal w_amplitude   : std_logic_vector(17 downto 0);
    signal w_fcw         : std_logic_vector(17 downto 0);
    signal w_detune      : std_logic_vector(17 downto 0);

begin

    -- Instantiation of Axi Bus Interface S_AXI_CTRL
    Oscillator_v2_0_S_AXI_CTRL_inst : entity work.Oscillator_v2_0_S_AXI_CTRL
	generic map (
	    g_NUM_CHANNELS      => g_NUM_CHANNELS,
		g_NUM_OSCILLATORS   => g_NUM_OSCILLATORS,
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_CTRL_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_CTRL_ADDR_WIDTH
	)
	port map (
	    i_oscillator_select => w_oscillator_select,
		i_channel_select    => w_channel_select,
		o_mod_enable    => w_mod_enable,
        o_pwm_enable    => w_pwm_enable,
        o_pulse_width   => w_pulse_width,
        o_wave_select   => w_wave_select,
        o_amplitude     => w_amplitude,
        o_fcw           => w_fcw,
        o_detune        => w_detune,
		S_AXI_ACLK  	=> s_axi_ctrl_aclk,
		S_AXI_ARESETN	=> s_axi_ctrl_aresetn,
		S_AXI_AWADDR	=> s_axi_ctrl_awaddr,
		S_AXI_AWPROT	=> s_axi_ctrl_awprot,
		S_AXI_AWVALID	=> s_axi_ctrl_awvalid,
		S_AXI_AWREADY	=> s_axi_ctrl_awready,
		S_AXI_WDATA	    => s_axi_ctrl_wdata,
		S_AXI_WSTRB  	=> s_axi_ctrl_wstrb,
		S_AXI_WVALID	=> s_axi_ctrl_wvalid,
		S_AXI_WREADY	=> s_axi_ctrl_wready,
		S_AXI_BRESP 	=> s_axi_ctrl_bresp,
		S_AXI_BVALID	=> s_axi_ctrl_bvalid,
		S_AXI_BREADY	=> s_axi_ctrl_bready,
		S_AXI_ARADDR	=> s_axi_ctrl_araddr,
		S_AXI_ARPROT	=> s_axi_ctrl_arprot,
		S_AXI_ARVALID	=> s_axi_ctrl_arvalid,
		S_AXI_ARREADY	=> s_axi_ctrl_arready,
		S_AXI_RDATA 	=> s_axi_ctrl_rdata,
		S_AXI_RRESP 	=> s_axi_ctrl_rresp,
		S_AXI_RVALID	=> s_axi_ctrl_rvalid,
		S_AXI_RREADY	=> s_axi_ctrl_rready
	);

    -- Instantiation of Axi Bus Interface M_AXIS_OUTPUT
    Oscillator_v2_0_M_AXIS_OUTPUT_inst : entity work.Oscillator_v2_0_M_AXIS_OUTPUT
	generic map (
	    g_NUM_CHANNELS        => g_NUM_CHANNELS,
	    g_DATA_WIDTH          => g_DATA_WIDTH,
		C_M_AXIS_TDATA_WIDTH  => C_M_AXIS_OUTPUT_TDATA_WIDTH,
		C_M_START_COUNT	      => C_M_AXIS_OUTPUT_START_COUNT
	)
	port map (
	    i_fifo_wr_en    => w_output_fifo_wr_en,
        i_fifo_wr_data  => w_output_fifo_wr_data,
	    o_fifo_full     => w_output_fifo_full,
		M_AXIS_ACLK	    => m_axis_output_aclk,
		M_AXIS_ARESETN	=> m_axis_output_aresetn,
		M_AXIS_TVALID	=> m_axis_output_tvalid,
		M_AXIS_TDATA	=> m_axis_output_tdata,
		M_AXIS_TSTRB	=> m_axis_output_tstrb,
		M_AXIS_TLAST	=> m_axis_output_tlast,
		M_AXIS_TREADY	=> m_axis_output_tready
	);

    -- Instantiation of Axi Bus Interface S_AXIS_FREQ_MOD
    Oscillator_v2_0_S_AXIS_FREQ_MOD_inst : entity work.Oscillator_v2_0_S_AXIS_FREQ_MOD
	generic map (
	    g_NUM_CHANNELS        => g_NUM_CHANNELS,
	    g_DATA_WIDTH          => g_DATA_WIDTH,
		C_S_AXIS_TDATA_WIDTH  => C_S_AXIS_FREQ_MOD_TDATA_WIDTH
	)
	port map (
	    i_fifo_rd_en    => w_modulation_fifo_rd_en,
        o_fifo_rd_data  => w_modulation_fifo_rd_data,
	    o_fifo_empty    => w_modulation_fifo_empty,
		S_AXIS_ACLK	    => s_axis_freq_mod_aclk,
		S_AXIS_ARESETN	=> s_axis_freq_mod_aresetn,
		S_AXIS_TREADY	=> s_axis_freq_mod_tready,
		S_AXIS_TDATA	=> s_axis_freq_mod_tdata,
		S_AXIS_TSTRB	=> s_axis_freq_mod_tstrb,
		S_AXIS_TLAST	=> s_axis_freq_mod_tlast,
		S_AXIS_TVALID	=> s_axis_freq_mod_tvalid
	);

    -- Instantiation of Axi Bus Interface S_AXIS_PWM
    Oscillator_v2_0_S_AXIS_PWM_inst : entity work.Oscillator_v2_0_S_AXIS_PWM
	generic map (
	    g_NUM_CHANNELS      => g_NUM_CHANNELS,
	    g_DATA_WIDTH        => g_DATA_WIDTH,
		C_S_AXIS_TDATA_WIDTH	=> C_S_AXIS_PWM_TDATA_WIDTH
	)
	port map (
	    i_fifo_rd_en    => w_pwm_fifo_rd_en,
        o_fifo_rd_data  => w_pwm_fifo_rd_data,
	    o_fifo_empty    => w_pwm_fifo_empty,
		S_AXIS_ACLK	    => s_axis_pwm_aclk,
		S_AXIS_ARESETN	=> s_axis_pwm_aresetn,
		S_AXIS_TREADY	=> s_axis_pwm_tready,
		S_AXIS_TDATA	=> s_axis_pwm_tdata,
		S_AXIS_TSTRB	=> s_axis_pwm_tstrb,
		S_AXIS_TLAST	=> s_axis_pwm_tlast,
		S_AXIS_TVALID	=> s_axis_pwm_tvalid
	);

	-- Instantiation of oscillator wrapper
    oscillator_unit : entity work.oscillator_wrapper
    generic map(
        g_NUM_CHANNELS    => g_NUM_CHANNELS,
        g_NUM_OSCILLATORS => g_NUM_OSCILLATORS,
        g_DATA_WIDTH      => g_DATA_WIDTH
    )
    port map(
        i_clk                     => m_axis_output_aclk,
        i_en                      => i_en,
        -- filter parameters
        o_oscillator_select       => w_oscillator_select,
        o_channel_select          => w_channel_select,
        i_wave_select             => w_wave_select,
        i_fcw                     => w_fcw,
        i_detune                  => w_detune,
        i_amplitude               => w_amplitude,
        i_pulse_width             => w_pulse_width,
        -- frequency modulation 
        i_modulation_en           => w_mod_enable,
        o_modulation_fifo_rd_en   => w_modulation_fifo_rd_en,
        i_modulation_fifo_rd_data => w_modulation_fifo_rd_data(23 downto 6),
	    i_modulation_fifo_empty   => w_modulation_fifo_empty,
	    -- Pulse Width Modulation
	    i_pwm_en                  => w_pwm_enable,
        o_pwm_fifo_rd_en          => w_pwm_fifo_rd_en,
        i_pwm_fifo_rd_data        => w_pwm_fifo_rd_data,
	    i_pwm_fifo_empty          => w_pwm_fifo_empty,
        -- outputs
        o_output_fifo_wr_en       => w_output_fifo_wr_en,
        o_output_fifo_wr_data     => w_output_fifo_wr_data,
	    i_output_fifo_full        => w_output_fifo_full
    );

end arch_imp;
