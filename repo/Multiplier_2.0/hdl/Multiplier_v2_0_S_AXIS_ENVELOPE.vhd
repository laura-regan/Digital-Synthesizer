library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Multiplier_v2_0_S_AXIS_ENVELOPE is
	generic (
		-- Users to add parameters here
        g_NUM_CHANNELS : integer := 128;
        g_DATA_WIDTH   : integer := 24;
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- AXI4Stream sink: Data Width
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here
        i_fifo_rd_en   : in  std_logic;
        o_fifo_rd_data : out std_logic_vector(g_DATA_WIDTH-1 downto 0);
	    o_fifo_empty   : out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- AXI4Stream sink: Clock
		S_AXIS_ACLK	: in std_logic;
		-- AXI4Stream sink: Reset
		S_AXIS_ARESETN	: in std_logic;
		-- Ready to accept data in
		S_AXIS_TREADY	: out std_logic;
		-- Data in
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		-- Byte qualifier
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- Indicates boundary of last packet
		S_AXIS_TLAST	: in std_logic;
		-- Data is in valid
		S_AXIS_TVALID	: in std_logic
	);
end Multiplier_v2_0_S_AXIS_ENVELOPE;

architecture arch_imp of Multiplier_v2_0_S_AXIS_ENVELOPE is
		
	-- internal axi signal
	signal axis_tready	: std_logic;
	
	-- FIFO write interface signals
	signal w_fifo_wr_en   : std_logic;
	signal w_fifo_wr_data : std_logic_vector(g_DATA_WIDTH-1 downto 0);
	signal w_fifo_full    : std_logic;
	
	signal w_reset : std_logic;

begin

	S_AXIS_TREADY	<= axis_tready;

    w_reset <= not S_AXIS_ARESETN;

	axis_tready <= '1' when w_fifo_full = '0' else '0';
	
	w_fifo_wr_en   <= S_AXIS_TVALID and axis_tready;
	w_fifo_wr_data <= S_AXIS_TDATA(g_DATA_WIDTH-1 downto 0);
	
    fifo_unit : entity work.fifo
    generic map(
        g_WIDTH => g_DATA_WIDTH,
        g_DEPTH => g_NUM_CHANNELS
    )
    port map(
        i_clk       => S_AXIS_ACLK,
        i_reset     => w_reset,
        -- FIFO write interface
        i_wr_en     => w_fifo_wr_en,
        i_wr_data   => w_fifo_wr_data,
        o_full      => w_fifo_full,
        -- FIFO read interface
        i_rd_en     => i_fifo_rd_en,
        o_rd_data   => o_fifo_rd_data,
        o_empty     => o_fifo_empty
    );

end arch_imp;
