library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity ADSR_v2_0 is
	generic (
		-- Users to add parameters here
        g_NUM_CHANNELS : integer := 128;
        g_DATA_WIDTH   : integer := 24;

		-- Parameters of Axi Slave Bus Interface S_AXI_CTRL
		C_S_AXI_CTRL_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_CTRL_ADDR_WIDTH	: integer	:= 6;

		-- Parameters of Axi Master Bus Interface M_AXIS_OUTPUT
		C_M_AXIS_OUTPUT_TDATA_WIDTH	: integer	:= 32;
		C_M_AXIS_OUTPUT_START_COUNT	: integer	:= 32
	);
	port (
		-- Users to add ports here
        i_enable : in std_logic;
        o_active_channel_count : out std_logic_vector(6 downto 0);

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
end ADSR_v2_0;

architecture arch_imp of ADSR_v2_0 is

    signal w_note_on_off_array : std_logic_vector(g_NUM_CHANNELS-1 downto 0);          
    signal w_attack_cw         : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    signal w_decay_cw          : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    signal w_sustain_level     : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    signal w_release_cw        : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    signal w_channel_free_array   : std_logic_vector(g_NUM_CHANNELS-1 downto 0);
    -- envelope
    --signal w_envelope          : std_logic_vector(31 downto 0);

    signal w_output_fifo_wr_en   : std_logic;
	signal w_output_fifo_wr_data : std_logic_vector(g_DATA_WIDTH-1 downto 0);
	signal w_output_fifo_full    : std_logic;

begin

    -- Instantiation of Axi Bus Interface S_AXI_CTRL
    ADSR_v2_0_S_AXI_CTRL_inst : entity work.ADSR_v2_0_S_AXI_CTRL
	generic map (
	    g_NUM_CHANNELS      => g_NUM_CHANNELS,
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_CTRL_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_CTRL_ADDR_WIDTH
	)
	port map (
	    o_note_on_off_array  => w_note_on_off_array,
	    o_attack_cw          => w_attack_cw,
        o_decay_cw           => w_decay_cw,
        o_sustain_level      => w_sustain_level,
        o_release_cw         => w_release_cw,
        i_channel_free_array => w_channel_free_array,
		S_AXI_ACLK	    => s_axi_ctrl_aclk,
		S_AXI_ARESETN	=> s_axi_ctrl_aresetn,
		S_AXI_AWADDR	=> s_axi_ctrl_awaddr,
		S_AXI_AWPROT	=> s_axi_ctrl_awprot,
		S_AXI_AWVALID	=> s_axi_ctrl_awvalid,
		S_AXI_AWREADY	=> s_axi_ctrl_awready,
		S_AXI_WDATA	    => s_axi_ctrl_wdata,
		S_AXI_WSTRB	    => s_axi_ctrl_wstrb,
		S_AXI_WVALID	=> s_axi_ctrl_wvalid,
		S_AXI_WREADY	=> s_axi_ctrl_wready,
		S_AXI_BRESP	    => s_axi_ctrl_bresp,
		S_AXI_BVALID	=> s_axi_ctrl_bvalid,
		S_AXI_BREADY	=> s_axi_ctrl_bready,
		S_AXI_ARADDR	=> s_axi_ctrl_araddr,
		S_AXI_ARPROT	=> s_axi_ctrl_arprot,
		S_AXI_ARVALID	=> s_axi_ctrl_arvalid,
		S_AXI_ARREADY	=> s_axi_ctrl_arready,
		S_AXI_RDATA	    => s_axi_ctrl_rdata,
		S_AXI_RRESP	    => s_axi_ctrl_rresp,
		S_AXI_RVALID	=> s_axi_ctrl_rvalid,
		S_AXI_RREADY	=> s_axi_ctrl_rready
	);

    -- Instantiation of Axi Bus Interface M_AXIS_OUTPUT
    ADSR_v2_0_M_AXIS_OUTPUT_inst : entity work.ADSR_v2_0_M_AXIS_OUTPUT
	generic map (
	    g_NUM_CHANNELS        => g_NUM_CHANNELS,
        g_DATA_WIDTH          => g_DATA_WIDTH,
		C_M_AXIS_TDATA_WIDTH  => C_M_AXIS_OUTPUT_TDATA_WIDTH,
		C_M_START_COUNT	=> C_M_AXIS_OUTPUT_START_COUNT
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

    adsr_unit : entity work.adsr
    generic map(
        g_NUM_CHANNELS  => g_NUM_CHANNELS,
        g_DATA_WIDTH    => g_DATA_WIDTH
    )
    port map(
        i_clk                   => s_axi_ctrl_aclk,   
        i_en                    => i_enable, 
        -- ctrls 
        i_note_on_off_array     => w_note_on_off_array,      
        i_attack_cw             => w_attack_cw, 
        i_decay_cw              => w_decay_cw, 
        i_sustain_level         => w_sustain_level, 
        i_release_cw            => w_release_cw, 
        o_channel_free_array    => w_channel_free_array, 
        -- envelope
        o_envelope_fifo_wr_en   => w_output_fifo_wr_en, 
        o_envelope_fifo_wr_data => w_output_fifo_wr_data, 
        i_envelope_fifo_full    => w_output_fifo_full, 
        o_active_channel_count  => o_active_channel_count          
    );

end arch_imp;
