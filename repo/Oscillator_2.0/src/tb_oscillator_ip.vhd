library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity tb_oscillator_ip is
end tb_oscillator_ip;

architecture arch of tb_oscillator_ip is
    constant T : time := 10 ns;

    constant c_NUM_CHANNELS    : integer := 2;
    constant c_NUM_OSCILLATORS : integer := 2;
    constant c_DATA_WIDTH      : integer := 24;

    signal axi_aclk      : std_logic;   
    signal axi_aresetn   : std_logic; 
    signal enable        : std_logic;
    
    signal m_axis_output_tdata  : std_logic_vector(31 downto 0);
    signal m_axis_output_tvalid : std_logic;
    signal m_axis_output_tready	: std_logic;
    
    type t_output_array is array (0 to C_NUM_CHANNELS-1) of std_logic_vector(c_DATA_WIDTH-1 downto 0);
    signal r_output_array : t_output_array := (others => (others => '0'));
    
    signal w_output : std_logic_vector(c_DATA_WIDTH-1 downto 0);
       
	signal r_pwm_fifo_wr_en   : std_logic;
    signal r_pwm_fifo_wr_data : std_logic_vector(23 downto 0);
	signal w_pwm_fifo_full    : std_logic;
	signal w_pwm_fifo_rd_en   : std_logic;
    signal w_pwm_fifo_rd_data : std_logic_vector(31 downto 0);
	signal w_pwm_fifo_empty   : std_logic;
	
	signal r_modulation_fifo_wr_en   : std_logic;
    signal r_modulation_fifo_wr_data : std_logic_vector(23 downto 0);
	signal w_modulation_fifo_full   : std_logic;
	signal w_modulation_fifo_rd_en   : std_logic;
    signal w_modulation_fifo_rd_data : std_logic_vector(31 downto 0);
	signal w_modulation_fifo_empty   : std_logic;
        
    component Oscillator_v2_0 is
	generic (
		-- Users to add parameters here
        g_NUM_CHANNELS    : integer    := 128;
        g_NUM_OSCILLATORS : integer    := 2;
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
end component Oscillator_v2_0;

begin

    w_pwm_fifo_rd_data(31 downto 24) <= (others => '0');
    w_modulation_fifo_rd_data(31 downto 24) <= (others => '0');

    process
    begin
        axi_aclk <= '1';
        wait for T/2;
        axi_aclk <= '0';
        wait for T/2;
    end process;
    
    process
    begin
        enable <= '0';
        
        for Idx in 0 to 1000 loop
            enable <= '1';
            wait until rising_edge(axi_aclk);
            enable <= '0';
            for Kdx in 0 to 15 loop
                wait until rising_edge(axi_aclk);
            end loop;
        end loop;
        
        assert false
            report "Simulation completed"
            severity failure;
    end process;


    process(axi_aclk)
        variable channel_index : integer := 0;
    begin
        if rising_edge(axi_aclk) then
            if m_axis_output_tvalid = '1' then
                r_output_array(channel_index) <= m_axis_output_tdata(r_output_array(channel_index)'range);
                if channel_index = c_NUM_CHANNELS-1 then
                    channel_index := 0;
                else
                    channel_index := channel_index + 1;
                end if;
            end if;
        end if;
    end process;

    process(axi_aclk)
        variable theta  : real := 0.0;
        variable frequency : real := 500.0; 
        variable channel : integer := 0;
    begin
        if rising_edge(axi_aclk) then
            if enable = '1' then
                theta := theta + 2.0*MATH_PI/frequency;
                if theta >= 2.0*MATH_PI then 
                    theta := 0.0; 
                end if;
                r_modulation_fifo_wr_data <= std_logic_vector(to_signed(integer((2.0**23.0-1.0)*sin(theta)), 24));
                r_modulation_fifo_wr_en   <= '1';
            end if;
        end if;
    end process;
    

    r_pwm_fifo_wr_en    <= '0';
    r_pwm_fifo_wr_data  <= (others => '0');
    w_pwm_fifo_full     <= '0';

    osc_unit : Oscillator_v2_0
	generic map (
		-- Users to add parameters here
        g_NUM_CHANNELS    => c_NUM_CHANNELS,
        g_NUM_OSCILLATORS => c_NUM_OSCILLATORS,
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S_AXI_CTRL
		C_S_AXI_CTRL_DATA_WIDTH	=> 32,
		C_S_AXI_CTRL_ADDR_WIDTH	=> 6,

		-- Parameters of Axi Master Bus Interface M_AXIS_OUTPUT
		C_M_AXIS_OUTPUT_TDATA_WIDTH	   => 32,
		C_M_AXIS_OUTPUT_START_COUNT    => 0,

		-- Parameters of Axi Slave Bus Interface S_AXIS_FREQ_MOD
		C_S_AXIS_FREQ_MOD_TDATA_WIDTH  => 32,

		-- Parameters of Axi Slave Bus Interface S_AXIS_PWM
		C_S_AXIS_PWM_TDATA_WIDTH	   => 32
	)
	port map(
		-- Users to add ports here
        i_en                => enable,
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S_AXI_CTRL
		s_axi_ctrl_aclk	    => axi_aclk,
		s_axi_ctrl_aresetn	=> axi_aresetn,
		s_axi_ctrl_awaddr	=> (others => '0'),
		s_axi_ctrl_awprot	=> (others => '0'),
		s_axi_ctrl_awvalid	=> '0',
		s_axi_ctrl_awready	=> open,
		s_axi_ctrl_wdata	=> (others => '0'),
		s_axi_ctrl_wstrb	=> (others => '0'),
		s_axi_ctrl_wvalid	=> '0',
		s_axi_ctrl_wready	=> open,
		s_axi_ctrl_bresp	=> open,
		s_axi_ctrl_bvalid	=> open,
		s_axi_ctrl_bready	=> '0',
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
		m_axis_output_tvalid	=> m_axis_output_tvalid,
		m_axis_output_tdata	    => m_axis_output_tdata,
		m_axis_output_tstrb	    => open,
		m_axis_output_tlast	    => open,
		m_axis_output_tready	=> m_axis_output_tready,

		-- Ports of Axi Slave Bus Interface S_AXIS_FREQ_MOD
		s_axis_freq_mod_aclk	=> axi_aclk,
		s_axis_freq_mod_aresetn	=> axi_aresetn,
		s_axis_freq_mod_tready	=> w_modulation_fifo_rd_en,
		s_axis_freq_mod_tdata	=> w_modulation_fifo_rd_data,
		s_axis_freq_mod_tstrb	=> (others => '0'),
		s_axis_freq_mod_tlast	=> '0',
		s_axis_freq_mod_tvalid	=> w_modulation_fifo_empty,

		-- Ports of Axi Slave Bus Interface S_AXIS_PWM
		s_axis_pwm_aclk	    => axi_aclk,
		s_axis_pwm_aresetn	=> axi_aresetn,
		s_axis_pwm_tready	=> w_pwm_fifo_rd_en,
		s_axis_pwm_tdata	=> w_pwm_fifo_rd_data,
		s_axis_pwm_tstrb	=> (others => '0'),
		s_axis_pwm_tlast	=> '0',
		s_axis_pwm_tvalid	=> w_pwm_fifo_empty
	);

    mixer_unit : entity work.Mixer_v2_0
	generic map(
		-- Users to add parameters here
        g_NUM_CHANNELS => c_NUM_CHANNELS,
        g_DATA_WIDTH   => c_DATA_WIDTH,
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S_AXIS_INPUT
		C_S_AXIS_INPUT_TDATA_WIDTH	=> 32
	)
	port map(
		-- Users to add ports here
		i_en                => enable,
        i_active_channels   => (others => '0'),
        o_output            => w_output,
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S_AXIS_INPUT
		s_axis_input_aclk	 => axi_aclk,
		s_axis_input_aresetn => axi_aresetn,
		s_axis_input_tready	 => m_axis_output_tready,
		s_axis_input_tdata	 => m_axis_output_tdata,
		s_axis_input_tstrb	 => (others => '0'),
		s_axis_input_tlast	 => '0',
		s_axis_input_tvalid	 => m_axis_output_tvalid
	);



    mod_fifo_unit : entity work.fifo
    generic map(
        g_WIDTH => 24,
        g_DEPTH => C_NUM_CHANNELS
    )
    port map(
        i_clk       => axi_aclk,
        i_reset     => axi_aresetn,
        -- FIFO write interface
        i_wr_en     => r_modulation_fifo_wr_en,
        i_wr_data   => r_modulation_fifo_wr_data,
        o_full      => w_modulation_fifo_full,
        -- FIFO read interface
        i_rd_en     => w_modulation_fifo_rd_en,
        o_rd_data   => w_modulation_fifo_rd_data(23 downto 0),
        o_empty     => w_modulation_fifo_empty
    );
    
--    pwm_fifo_unit : entity work.fifo
--    generic map(
--        g_WIDTH => 24,
--        g_DEPTH => C_NUM_CHANNELS
--    )
--    port map(
--        i_clk       => axi_aclk,
--        i_reset     => axi_aresetn,
--        -- FIFO write interface
--        i_wr_en     => r_pwm_fifo_wr_en,
--        i_wr_data   => r_pwm_fifo_wr_data,
--        o_full      => w_pwm_fifo_full,
--        -- FIFO read interface
--        i_rd_en     => w_pwm_fifo_rd_en,
--        o_rd_data   => w_pwm_fifo_rd_data(23 downto 0),
--        o_empty     => w_pwm_fifo_empty
--    );


end arch;