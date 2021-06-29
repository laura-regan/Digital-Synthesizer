library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Mixer_v2_0 is
	generic (
        g_NUM_CHANNELS : integer := 128;
        g_DATA_WIDTH   : integer := 24;

		-- Parameters of Axi Slave Bus Interface S_AXIS_INPUT
		C_S_AXIS_INPUT_TDATA_WIDTH	: integer	:= 32
	);
	port (
		i_en                : in std_logic;
        i_active_channels   : in  std_logic_vector(6 downto 0);
        o_output            : out std_logic_vector(g_DATA_WIDTH-1 downto 0);

		-- Ports of Axi Slave Bus Interface S_AXIS_INPUT
		s_axis_input_aclk	: in std_logic;
		s_axis_input_aresetn	: in std_logic;
		s_axis_input_tready	: out std_logic;
		s_axis_input_tdata	: in std_logic_vector(C_S_AXIS_INPUT_TDATA_WIDTH-1 downto 0);
		s_axis_input_tstrb	: in std_logic_vector((C_S_AXIS_INPUT_TDATA_WIDTH/8)-1 downto 0);
		s_axis_input_tlast	: in std_logic;
		s_axis_input_tvalid	: in std_logic
	);
end Mixer_v2_0;

architecture arch_imp of Mixer_v2_0 is

    constant c_DATA_WIDTH : integer := 24;

    signal w_input_fifo_rd_en   : std_logic;
    signal w_input_fifo_rd_data : std_logic_vector(c_DATA_WIDTH-1 downto 0);
	signal w_input_fifo_empty   : std_logic;
    
begin

-- Instantiation of Axi Bus Interface S_AXIS_INPUT
    Mixer_v2_0_S_AXIS_INPUT_inst : entity work.Mixer_v2_0_S_AXIS_INPUT
	generic map (
        g_NUM_CHANNELS          => g_NUM_CHANNELS,
        g_DATA_WIDTH            => g_DATA_WIDTH,
        C_S_AXIS_TDATA_WIDTH	=> C_S_AXIS_INPUT_TDATA_WIDTH
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

    mixer_unit : entity work.mixer
    generic map(
        g_NUM_CHANNELS => g_NUM_CHANNELS,
        g_DATA_WIDTH   => g_DATA_WIDTH
    )
    port map(
        i_clk                => s_axis_input_aclk,
        i_en                 => i_en,
        i_active_channels    => i_active_channels,
        o_input_fifo_rd_en   => w_input_fifo_rd_en,
        i_input_fifo_rd_data => w_input_fifo_rd_data,
	    i_input_fifo_empty   => w_input_fifo_empty,
        o_output             => o_output
    );

end arch_imp;
