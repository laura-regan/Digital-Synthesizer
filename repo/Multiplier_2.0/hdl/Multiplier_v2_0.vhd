library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Multiplier_v2_0 is
	generic (
		-- Users to add parameters here
        g_NUM_CHANNELS   : integer := 128;
        g_DATA_WIDTH     : integer := 24;
        g_ENVELOPE_WIDTH : integer := 18;

		-- Parameters of Axi Slave Bus Interface S_AXIS_INPUT
		C_S_AXIS_INPUT_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Slave Bus Interface S_AXIS_ENVELOPE
		C_S_AXIS_ENVELOPE_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Master Bus Interface M_AXIS_OUTPUT
		C_M_AXIS_OUTPUT_TDATA_WIDTH	: integer	:= 32;
		C_M_AXIS_OUTPUT_START_COUNT	: integer	:= 32
	);
	port (
		-- Users to add ports here
        i_enable : in std_logic;

		-- Ports of Axi Slave Bus Interface S_AXIS_INPUT
		s_axis_input_aclk	: in std_logic;
		s_axis_input_aresetn	: in std_logic;
		s_axis_input_tready	: out std_logic;
		s_axis_input_tdata	: in std_logic_vector(C_S_AXIS_INPUT_TDATA_WIDTH-1 downto 0);
		s_axis_input_tstrb	: in std_logic_vector((C_S_AXIS_INPUT_TDATA_WIDTH/8)-1 downto 0);
		s_axis_input_tlast	: in std_logic;
		s_axis_input_tvalid	: in std_logic;

		-- Ports of Axi Slave Bus Interface S_AXIS_ENVELOPE
		s_axis_envelope_aclk	: in std_logic;
		s_axis_envelope_aresetn	: in std_logic;
		s_axis_envelope_tready	: out std_logic;
		s_axis_envelope_tdata	: in std_logic_vector(C_S_AXIS_ENVELOPE_TDATA_WIDTH-1 downto 0);
		s_axis_envelope_tstrb	: in std_logic_vector((C_S_AXIS_ENVELOPE_TDATA_WIDTH/8)-1 downto 0);
		s_axis_envelope_tlast	: in std_logic;
		s_axis_envelope_tvalid	: in std_logic;

		-- Ports of Axi Master Bus Interface M_AXIS_OUTPUT
		m_axis_output_aclk	: in std_logic;
		m_axis_output_aresetn	: in std_logic;
		m_axis_output_tvalid	: out std_logic;
		m_axis_output_tdata	: out std_logic_vector(C_M_AXIS_OUTPUT_TDATA_WIDTH-1 downto 0);
		m_axis_output_tstrb	: out std_logic_vector((C_M_AXIS_OUTPUT_TDATA_WIDTH/8)-1 downto 0);
		m_axis_output_tlast	: out std_logic;
		m_axis_output_tready	: in std_logic
	);
end Multiplier_v2_0;

architecture arch_imp of Multiplier_v2_0 is

    -- output fifo signals
	signal w_output_fifo_wr_en   : std_logic;
	signal w_output_fifo_wr_data : std_logic_vector(g_DATA_WIDTH-1 downto 0);
	signal w_output_fifo_full    : std_logic;
	-- pulse width modulation fifo signals
	signal w_input_fifo_rd_en   : std_logic;
    signal w_input_fifo_rd_data : std_logic_vector(g_DATA_WIDTH-1 downto 0);
	signal w_input_fifo_empty   : std_logic;
	-- frequency modulation fifo signals
	signal w_envelope_fifo_rd_en   : std_logic;
    signal w_envelope_fifo_rd_data : std_logic_vector(g_DATA_WIDTH-1 downto 0);
	signal w_envelope_fifo_empty   : std_logic;

begin

-- Instantiation of Axi Bus Interface S_AXIS_INPUT
    Multiplier_v2_0_S_AXIS_INPUT_inst : entity work.Multiplier_v2_0_S_AXIS_INPUT
	generic map (
	    g_NUM_CHANNELS        => g_NUM_CHANNELS,
        g_DATA_WIDTH          => g_DATA_WIDTH,
		C_S_AXIS_TDATA_WIDTH  => C_S_AXIS_INPUT_TDATA_WIDTH
	)
	port map (
	    i_fifo_rd_en    => w_input_fifo_rd_en,
        o_fifo_rd_data  => w_input_fifo_rd_data,
	    o_fifo_empty    => w_input_fifo_empty,
		S_AXIS_ACLK	    => s_axis_input_aclk,
		S_AXIS_ARESETN	=> s_axis_input_aresetn,
		S_AXIS_TREADY	=> s_axis_input_tready,
		S_AXIS_TDATA	=> s_axis_input_tdata,
		S_AXIS_TSTRB	=> s_axis_input_tstrb,
		S_AXIS_TLAST	=> s_axis_input_tlast,
		S_AXIS_TVALID	=> s_axis_input_tvalid
	);

    -- Instantiation of Axi Bus Interface S_AXIS_ENVELOPE
    Multiplier_v2_0_S_AXIS_ENVELOPE_inst : entity work.Multiplier_v2_0_S_AXIS_ENVELOPE
	generic map (
	    g_NUM_CHANNELS        => g_NUM_CHANNELS,
        g_DATA_WIDTH          => g_DATA_WIDTH,
		C_S_AXIS_TDATA_WIDTH  => C_S_AXIS_ENVELOPE_TDATA_WIDTH
	)
	port map (
	    i_fifo_rd_en    => w_envelope_fifo_rd_en,
        o_fifo_rd_data  => w_envelope_fifo_rd_data,
	    o_fifo_empty    => w_envelope_fifo_empty,
		S_AXIS_ACLK 	=> s_axis_envelope_aclk,
		S_AXIS_ARESETN	=> s_axis_envelope_aresetn,
		S_AXIS_TREADY	=> s_axis_envelope_tready,
		S_AXIS_TDATA	=> s_axis_envelope_tdata,
		S_AXIS_TSTRB	=> s_axis_envelope_tstrb,
		S_AXIS_TLAST	=> s_axis_envelope_tlast,
		S_AXIS_TVALID	=> s_axis_envelope_tvalid
	);

    -- Instantiation of Axi Bus Interface M_AXIS_OUTPUT
    Multiplier_v2_0_M_AXIS_OUTPUT_inst : entity work.Multiplier_v2_0_M_AXIS_OUTPUT
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
		M_AXIS_ACLK 	=> m_axis_output_aclk,
		M_AXIS_ARESETN	=> m_axis_output_aresetn,
		M_AXIS_TVALID	=> m_axis_output_tvalid,
		M_AXIS_TDATA	=> m_axis_output_tdata,
		M_AXIS_TSTRB	=> m_axis_output_tstrb,
		M_AXIS_TLAST	=> m_axis_output_tlast,
		M_AXIS_TREADY	=> m_axis_output_tready
	);

    multiplier_module : entity work.multiplier 
    generic map(
        g_NUM_CHANNELS   => g_NUM_CHANNELS,
        g_DATA_WIDTH     => g_DATA_WIDTH,
        g_ENVELOPE_WIDTH => g_ENVELOPE_WIDTH
    )
    port map(
        i_clk                    => s_axis_input_aclk,
        i_enable                 => i_enable,
        -- input fifo interface
        o_input_fifo_rd_en       => w_input_fifo_rd_en,
        i_input_fifo_rd_data     => w_input_fifo_rd_data,
	    i_input_fifo_empty       => w_input_fifo_empty,
        -- envelope fifo interface
        o_envelope_fifo_rd_en    => w_envelope_fifo_rd_en,
        i_envelope_fifo_rd_data  => w_envelope_fifo_rd_data(g_DATA_WIDTH-1 downto g_DATA_WIDTH-g_ENVELOPE_WIDTH),
	    i_envelope_fifo_empty    => w_envelope_fifo_empty,
        -- output fifo interface
        o_output_fifo_wr_en      => w_output_fifo_wr_en,
        o_output_fifo_wr_data    => w_output_fifo_wr_data,
	    i_output_fifo_full       => w_output_fifo_full
    );

end arch_imp;
