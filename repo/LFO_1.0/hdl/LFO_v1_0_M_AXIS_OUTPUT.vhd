library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LFO_v1_0_M_AXIS_OUTPUT is
	generic (
		-- Users to add parameters here
        g_NUM_CHANNELS : integer := 128;
        g_DATA_WIDTH   : integer := 24;
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		C_M_AXIS_TDATA_WIDTH	: integer	:= 32;
		-- Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
		C_M_START_COUNT	: integer	:= 32
	);
	port (
		-- Users to add ports here
        i_fifo_wr_en   : in  std_logic;
        i_fifo_wr_data : in std_logic_vector(g_DATA_WIDTH-1 downto 0);
	    o_fifo_full    : out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global ports
		M_AXIS_ACLK	: in std_logic;
		-- 
		M_AXIS_ARESETN	: in std_logic;
		-- Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		M_AXIS_TVALID	: out std_logic;
		-- TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		-- TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- TLAST indicates the boundary of a packet.
		M_AXIS_TLAST	: out std_logic;
		-- TREADY indicates that the slave can accept a transfer in the current cycle.
		M_AXIS_TREADY	: in std_logic
	);
end LFO_v1_0_M_AXIS_OUTPUT;

architecture implementation of LFO_v1_0_M_AXIS_OUTPUT is
  
    -- FIFO write interface signals
	signal w_fifo_rd_en   : std_logic;
	signal w_fifo_rd_data : std_logic_vector(g_DATA_WIDTH-1 downto 0);
	signal w_fifo_empty   : std_logic;
	
	signal w_reset : std_logic;

begin
	-- I/O Connections assignments
	M_AXIS_TLAST	<= '1';
	M_AXIS_TSTRB	<= (others => '1');                                               

	M_AXIS_TVALID <= not w_fifo_empty;
	w_fifo_rd_en  <= M_AXIS_TREADY;
	
	w_reset <= not M_AXIS_ARESETN;
	
	M_AXIS_TDATA  <= std_logic_vector(resize(unsigned(w_fifo_rd_data), M_AXIS_TDATA'length));
	
    fifo_unit : entity work.fifo
    generic map(
        g_WIDTH => g_DATA_WIDTH,
        g_DEPTH => g_NUM_CHANNELS
    )
    port map(
        i_clk       => M_AXIS_ACLK,
        i_reset     => w_reset,
        -- FIFO write interface
        i_wr_en     => i_fifo_wr_en,
        i_wr_data   => i_fifo_wr_data,
        o_full      => o_fifo_full,
        -- FIFO read interface
        i_rd_en     => w_fifo_rd_en,
        o_rd_data   => w_fifo_rd_data,
        o_empty     => w_fifo_empty
    );

end implementation;
