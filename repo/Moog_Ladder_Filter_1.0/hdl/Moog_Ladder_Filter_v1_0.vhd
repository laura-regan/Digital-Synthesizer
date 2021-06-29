library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Moog_Ladder_Filter_v1_0 is
	generic (
		-- Filter module parameters 
        g_NUM_CHANNELS : integer := 128;
        g_DATA_WIDTH   : integer := 24;

		-- Parameters of Axi Slave Bus Interface S_AXI_CTRL
		C_S_AXI_CTRL_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_CTRL_ADDR_WIDTH	: integer	:= 6;

		-- Parameters of Axi Master Bus Interface M_AXIS_OUTPUT
		C_M_AXIS_OUTPUT_TDATA_WIDTH	: integer	:= 32;
		C_M_AXIS_OUTPUT_START_COUNT	: integer	:= 32;

		-- Parameters of Axi Slave Bus Interface S_AXIS_INPUT
		C_S_AXIS_INPUT_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Slave Bus Interface S_AXIS_ADSR
		C_S_AXIS_ADSR_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Slave Bus Interface S_AXI_MODULATION
		C_S_AXI_MODULATION_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here
        i_enable : in std_logic;

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

		-- Ports of Axi Slave Bus Interface S_AXIS_INPUT
		s_axis_input_aclk	: in std_logic;
		s_axis_input_aresetn	: in std_logic;
		s_axis_input_tready	: out std_logic;
		s_axis_input_tdata	: in std_logic_vector(C_S_AXIS_INPUT_TDATA_WIDTH-1 downto 0);
		s_axis_input_tstrb	: in std_logic_vector((C_S_AXIS_INPUT_TDATA_WIDTH/8)-1 downto 0);
		s_axis_input_tlast	: in std_logic;
		s_axis_input_tvalid	: in std_logic;

		-- Ports of Axi Slave Bus Interface S_AXIS_ADSR
		s_axis_adsr_aclk	: in std_logic;
		s_axis_adsr_aresetn	: in std_logic;
		s_axis_adsr_tready	: out std_logic;
		s_axis_adsr_tdata	: in std_logic_vector(C_S_AXIS_ADSR_TDATA_WIDTH-1 downto 0);
		s_axis_adsr_tstrb	: in std_logic_vector((C_S_AXIS_ADSR_TDATA_WIDTH/8)-1 downto 0);
		s_axis_adsr_tlast	: in std_logic;
		s_axis_adsr_tvalid	: in std_logic;

		-- Ports of Axi Slave Bus Interface S_AXI_MODULATION
		s_axi_modulation_aclk	: in std_logic;
		s_axi_modulation_aresetn	: in std_logic;
		s_axi_modulation_tready	: out std_logic;
		s_axi_modulation_tdata	: in std_logic_vector(C_S_AXI_MODULATION_TDATA_WIDTH-1 downto 0);
		s_axi_modulation_tstrb	: in std_logic_vector((C_S_AXI_MODULATION_TDATA_WIDTH/8)-1 downto 0);
		s_axi_modulation_tlast	: in std_logic;
		s_axi_modulation_tvalid	: in std_logic
	);
end Moog_Ladder_Filter_v1_0;

architecture arch_imp of Moog_Ladder_Filter_v1_0 is

    signal w_input_fifo_rd_en   : std_logic;
    signal w_input_fifo_rd_data : std_logic_vector(23 downto 0);
	signal w_input_fifo_empty   : std_logic;
	
	signal w_output_fifo_wr_en   : std_logic;
	signal w_output_fifo_wr_data : std_logic_vector(g_DATA_WIDTH-1 downto 0);
	signal w_output_fifo_full    : std_logic;
	
	signal w_adsr_fifo_rd_en   : std_logic;
    signal w_adsr_fifo_rd_data : std_logic_vector(g_DATA_WIDTH-1 downto 0);
	signal w_adsr_fifo_empty   : std_logic;
	
	signal w_modulation_fifo_rd_en   : std_logic;
    signal w_modulation_fifo_rd_data : std_logic_vector(g_DATA_WIDTH-1 downto 0);
	signal w_modulation_fifo_empty   : std_logic;

    signal w_cutoff_frequency   : std_logic_vector(17 downto 0);
    signal w_resonance          : std_logic_vector(17 downto 0);
    signal w_adsr_amount        : std_logic_vector(17 downto 0);
    signal w_modulation_en      : std_logic;
    signal w_modulation_amount  : std_logic_vector(17 downto 0);
    signal w_filter_type        : std_logic_vector(1 downto 0);
    signal w_filter_attenuation : std_logic;

begin

    -- Instantiation of Axi Bus Interface S_AXI_CTRL
    Moog_Ladder_Filter_v1_0_S_AXI_CTRL_inst : entity work.Moog_Ladder_Filter_v1_0_S_AXI_CTRL
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_CTRL_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_CTRL_ADDR_WIDTH
	)
	port map (
	    o_cutoff_frequency   => w_cutoff_frequency,
        o_resonance          => w_resonance,
        o_adsr_amount        => w_adsr_amount,
        o_modulation_en      => w_modulation_en,
        o_modulation_amount  => w_modulation_amount,
        o_filter_type        => w_filter_type,
        o_filter_attenuation => w_filter_attenuation,
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
		S_AXI_BRESP  	=> s_axi_ctrl_bresp,
		S_AXI_BVALID	=> s_axi_ctrl_bvalid,
		S_AXI_BREADY	=> s_axi_ctrl_bready,
		S_AXI_ARADDR	=> s_axi_ctrl_araddr,
		S_AXI_ARPROT	=> s_axi_ctrl_arprot,
		S_AXI_ARVALID	=> s_axi_ctrl_arvalid,
		S_AXI_ARREADY	=> s_axi_ctrl_arready,
		S_AXI_RDATA   	=> s_axi_ctrl_rdata,
		S_AXI_RRESP	    => s_axi_ctrl_rresp,
		S_AXI_RVALID	=> s_axi_ctrl_rvalid,
		S_AXI_RREADY	=> s_axi_ctrl_rready
	);

    -- Instantiation of Axi Bus Interface M_AXIS_OUTPUT
    Moog_Ladder_Filter_v1_0_M_AXIS_OUTPUT_inst : entity work.Moog_Ladder_Filter_v1_0_M_AXIS_OUTPUT
	generic map (
	    g_NUM_CHANNELS       => g_NUM_CHANNELS,
	    g_DATA_WIDTH         => g_DATA_WIDTH,
		C_M_AXIS_TDATA_WIDTH => C_M_AXIS_OUTPUT_TDATA_WIDTH,
		C_M_START_COUNT	     => C_M_AXIS_OUTPUT_START_COUNT
	)
	port map (
	    -- fifo output write interface 
	    i_fifo_wr_en    => w_output_fifo_wr_en,
        i_fifo_wr_data  => w_output_fifo_wr_data,
	    o_fifo_full     => w_output_fifo_full,
	    -- axi stream master
		M_AXIS_ACLK  	=> m_axis_output_aclk,
		M_AXIS_ARESETN	=> m_axis_output_aresetn,
		M_AXIS_TVALID	=> m_axis_output_tvalid,
		M_AXIS_TDATA	=> m_axis_output_tdata,
		M_AXIS_TSTRB	=> m_axis_output_tstrb,
		M_AXIS_TLAST	=> m_axis_output_tlast,
		M_AXIS_TREADY	=> m_axis_output_tready
	);

    -- Instantiation of Axi Bus Interface S_AXIS_INPUT
    Moog_Ladder_Filter_v1_0_S_AXIS_INPUT_inst : entity work.Moog_Ladder_Filter_v1_0_S_AXIS_INPUT
	generic map (
	    g_NUM_CHANNELS       => g_NUM_CHANNELS,
	    g_DATA_WIDTH         => g_DATA_WIDTH,
		C_S_AXIS_TDATA_WIDTH => C_S_AXIS_INPUT_TDATA_WIDTH
	)
	port map (
	    -- fifo input read interface
	    i_fifo_rd_en    => w_input_fifo_rd_en,
        o_fifo_rd_data  => w_input_fifo_rd_data,
	    o_fifo_empty    => w_input_fifo_empty,
	    -- axi stream slave
		S_AXIS_ACLK	    => s_axis_input_aclk,
		S_AXIS_ARESETN	=> s_axis_input_aresetn,
		S_AXIS_TREADY	=> s_axis_input_tready,
		S_AXIS_TDATA	=> s_axis_input_tdata,
		S_AXIS_TSTRB	=> s_axis_input_tstrb,
		S_AXIS_TLAST	=> s_axis_input_tlast,
		S_AXIS_TVALID	=> s_axis_input_tvalid
	);

    -- Instantiation of Axi Bus Interface S_AXIS_ADSR
    Moog_Ladder_Filter_v1_0_S_AXIS_ADSR_inst : entity work.Moog_Ladder_Filter_v1_0_S_AXIS_ADSR
	generic map (
        g_NUM_CHANNELS       => g_NUM_CHANNELS,
        g_DATA_WIDTH         => g_DATA_WIDTH,
        C_S_AXIS_TDATA_WIDTH => C_S_AXIS_ADSR_TDATA_WIDTH
	)
	port map (
	    -- fifo adsr read interface
	    i_fifo_rd_en    => w_adsr_fifo_rd_en,
        o_fifo_rd_data  => w_adsr_fifo_rd_data,
	    o_fifo_empty    => w_adsr_fifo_empty,
	    -- axi stream slave
		S_AXIS_ACLK	    => s_axis_adsr_aclk,
		S_AXIS_ARESETN	=> s_axis_adsr_aresetn,
		S_AXIS_TREADY	=> s_axis_adsr_tready,
		S_AXIS_TDATA	=> s_axis_adsr_tdata,
		S_AXIS_TSTRB	=> s_axis_adsr_tstrb,
		S_AXIS_TLAST	=> s_axis_adsr_tlast,
		S_AXIS_TVALID	=> s_axis_adsr_tvalid
	);

    -- Instantiation of Axi Bus Interface S_AXI_MODULATION
    Moog_Ladder_Filter_v1_0_S_AXI_MODULATION_inst : entity work.Moog_Ladder_Filter_v1_0_S_AXI_MODULATION
	generic map (
	    g_NUM_CHANNELS       => g_NUM_CHANNELS,
	    g_DATA_WIDTH         => g_DATA_WIDTH,
		C_S_AXIS_TDATA_WIDTH => C_S_AXI_MODULATION_TDATA_WIDTH
	)
	port map (
	    -- fifo freq modulation read interface
	    i_fifo_rd_en    => w_modulation_fifo_rd_en,
        o_fifo_rd_data  => w_modulation_fifo_rd_data,
	    o_fifo_empty    => w_modulation_fifo_empty,
	    -- axi stream slave
		S_AXIS_ACLK	    => s_axi_modulation_aclk,
		S_AXIS_ARESETN	=> s_axi_modulation_aresetn,
		S_AXIS_TREADY	=> s_axi_modulation_tready,
		S_AXIS_TDATA	=> s_axi_modulation_tdata,
		S_AXIS_TSTRB	=> s_axi_modulation_tstrb,
		S_AXIS_TLAST	=> s_axi_modulation_tlast,
		S_AXIS_TVALID	=> s_axi_modulation_tvalid
	);

    -- Instantiation of Moog ladder filter
    ladder_filter: entity work.moog_ladder_filter_wrapper
    generic map(
        g_NUM_CHANNELS => g_NUM_CHANNELS,
        g_DATA_WIDTH   => g_DATA_WIDTH
    )
    port map(
        i_clk                     => s_axis_input_aclk,
        i_en                      => i_enable,
        -- input
        o_input_fifo_rd_en        => w_input_fifo_rd_en,
        i_input_fifo_rd_data      => w_input_fifo_rd_data,
	    i_input_fifo_empty        => w_input_fifo_empty,
        -- filter parameters
        i_resonance               => w_resonance,
        i_cutoff_frequency        => w_cutoff_frequency,
        -- ADSR Envelope
        o_adsr_fifo_rd_en         => w_adsr_fifo_rd_en,
        i_adsr_fifo_rd_data       => w_adsr_fifo_rd_data(23 downto 6),
	    i_adsr_fifo_empty         => w_adsr_fifo_empty,
        i_adsr_amount             => w_adsr_amount,
        -- modulation (LFO)
        i_modulation_en           => w_modulation_en,
        o_modulation_fifo_rd_en   => w_modulation_fifo_rd_en,
        i_modulation_fifo_rd_data => w_modulation_fifo_rd_data(23 downto 6),
	    i_modulation_fifo_empty   => w_modulation_fifo_empty,
        i_modulation_amount       => w_modulation_amount,
        -- filter type
        i_filter_type             => w_filter_type,
        i_filter_attenuation      => w_filter_attenuation,
        -- outputs
        o_output_fifo_wr_en       => w_output_fifo_wr_en,
        o_output_fifo_wr_data     => w_output_fifo_wr_data,
	    i_output_fifo_full        => w_output_fifo_full
    );

end arch_imp;
