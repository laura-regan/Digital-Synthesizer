library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LFO_v1_0 is
	generic (
		-- Users to add parameters here
        g_NUM_CHANNELS : integer := 128;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S_AXI_CTRL
		C_S_AXI_CTRL_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_CTRL_ADDR_WIDTH	: integer	:= 5;

		-- Parameters of Axi Master Bus Interface M_AXIS_OUTPUT
		C_M_AXIS_OUTPUT_TDATA_WIDTH	: integer	:= 32;
		C_M_AXIS_OUTPUT_START_COUNT	: integer	:= 32
	);
	port (
		-- Users to add ports here
        i_enable : in std_logic;
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
		m_axis_output_tready	: in std_logic
	);
end LFO_v1_0;

architecture arch_imp of LFO_v1_0 is

	constant c_DATA_WIDTH : integer := 24;

    -- output fifo signals
	signal w_output_fifo_wr_en   : std_logic;
	signal w_output_fifo_wr_data : std_logic_vector(c_DATA_WIDTH-1 downto 0);
	signal w_output_fifo_full    : std_logic;
	
    signal w_channel_on  : std_logic_vector(0 to g_NUM_CHANNELS-1);
    signal w_channel_fcw : std_logic_vector(23 downto 0);
    signal w_amount      : std_logic_vector(15 downto 0);
    signal w_waveform    : std_logic_vector(1 downto 0);
    signal w_polyphonic  : std_logic;
	
begin

-- Instantiation of Axi Bus Interface S_AXI_CTRL
LFO_v1_0_S_AXI_CTRL_inst : entity work.LFO_v1_0_S_AXI_CTRL
	generic map (
	    g_NUM_CHANNELS      => g_NUM_CHANNELS,
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_CTRL_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_CTRL_ADDR_WIDTH
	)
	port map (
	    o_channel_on    => w_channel_on,
        o_channel_fcw   => w_channel_fcw,
        o_amount        => w_amount,
        o_waveform      => w_waveform,
        o_polyphonic    => w_polyphonic,
		S_AXI_ACLK	    => s_axi_ctrl_aclk,
		S_AXI_ARESETN	=> s_axi_ctrl_aresetn,
		S_AXI_AWADDR	=> s_axi_ctrl_awaddr,
		S_AXI_AWPROT	=> s_axi_ctrl_awprot,
		S_AXI_AWVALID	=> s_axi_ctrl_awvalid,
		S_AXI_AWREADY	=> s_axi_ctrl_awready,
		S_AXI_WDATA	=> s_axi_ctrl_wdata,
		S_AXI_WSTRB	=> s_axi_ctrl_wstrb,
		S_AXI_WVALID	=> s_axi_ctrl_wvalid,
		S_AXI_WREADY	=> s_axi_ctrl_wready,
		S_AXI_BRESP	=> s_axi_ctrl_bresp,
		S_AXI_BVALID	=> s_axi_ctrl_bvalid,
		S_AXI_BREADY	=> s_axi_ctrl_bready,
		S_AXI_ARADDR	=> s_axi_ctrl_araddr,
		S_AXI_ARPROT	=> s_axi_ctrl_arprot,
		S_AXI_ARVALID	=> s_axi_ctrl_arvalid,
		S_AXI_ARREADY	=> s_axi_ctrl_arready,
		S_AXI_RDATA	=> s_axi_ctrl_rdata,
		S_AXI_RRESP	=> s_axi_ctrl_rresp,
		S_AXI_RVALID	=> s_axi_ctrl_rvalid,
		S_AXI_RREADY	=> s_axi_ctrl_rready
	);

-- Instantiation of Axi Bus Interface M_AXIS_OUTPUT
LFO_v1_0_M_AXIS_OUTPUT_inst : entity work.LFO_v1_0_M_AXIS_OUTPUT
	generic map (
        g_NUM_CHANNELS        => g_NUM_CHANNELS,
        g_DATA_WIDTH          => c_DATA_WIDTH,
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

    lfo_module : entity work.low_frequency_oscillator
    generic map(
        g_DATA_WIDTH   => c_DATA_WIDTH,
        g_NUM_CHANNELS => g_NUM_CHANNELS
    )
    port map(
        i_clk                 => s_axi_ctrl_aclk,
        i_enable              => i_enable,
        i_channel_on          => w_channel_on,
        i_channel_fcw         => w_channel_fcw,
        i_amount              => w_amount,
        i_waveform            => w_waveform,
        i_polyphonic          => w_polyphonic,
        o_output_fifo_wr_en   => w_output_fifo_wr_en,
        o_output_fifo_wr_data => w_output_fifo_wr_data,
        i_output_fifo_full    => w_output_fifo_full
    );

end arch_imp;
