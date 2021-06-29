library ieee;
use ieee.std_logic_1164.all;


entity moog_ladder_filter_wrapper is
    generic(
        g_NUM_CHANNELS : integer := 128;
        g_DATA_WIDTH   : integer := 24
    );
    port(
        i_clk                     : in std_logic;
        i_en                      : in std_logic;
        -- input
        o_input_fifo_rd_en        : out std_logic;
        i_input_fifo_rd_data      : in std_logic_vector(g_DATA_WIDTH-1 downto 0);
	    i_input_fifo_empty        : in std_logic;
        -- filter parameters
        i_resonance               : in std_logic_vector(17 downto 0);
        i_cutoff_frequency        : in std_logic_vector(17 downto 0); -- Q3.15
        -- ADSR Envelope
        o_adsr_fifo_rd_en         : out std_logic;
        i_adsr_fifo_rd_data       : in std_logic_vector(17 downto 0);
	    i_adsr_fifo_empty         : in std_logic;
        i_adsr_amount             : in std_logic_vector(17 downto 0); -- Q3.15
        -- modulation (LFO)
        i_modulation_en           : in std_logic;
        o_modulation_fifo_rd_en   : out std_logic;
        i_modulation_fifo_rd_data : in std_logic_vector(17 downto 0); -- Q1.17
	    i_modulation_fifo_empty   : in std_logic; 
        i_modulation_amount       : in std_logic_vector(17 downto 0); -- Q3.15
        -- filter type
        i_filter_type             : in std_logic_vector(1 downto 0);  -- {low pass, high pass, bandpass}
        i_filter_attenuation      : in std_logic;                     -- {12dB/Oct, 24dB/Oct}
        -- outputs
        o_output_fifo_wr_en       : out std_logic;
        o_output_fifo_wr_data     : out std_logic_vector(g_DATA_WIDTH-1 downto 0); -- Q1.23
	    i_output_fifo_full        : in std_logic 
    );
end moog_ladder_filter_wrapper;

architecture arch of moog_ladder_filter_wrapper is

    type t_state is (idle, running);
    signal r_state : t_state := idle;
    
    signal r_channel : integer range 0 to g_NUM_CHANNELS-1 := 0;
    
    signal w_data_valid_in  : std_logic;
    signal w_data_valid_out : std_logic;
    
    signal w_output : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    
    signal r_rd_input : std_logic;
    signal r_rd_adsr : std_logic;
    signal r_rd_modulation : std_logic;
    
    signal w_input : std_logic_vector(g_DATA_WIDTH-1 downto 0);
    signal w_adsr_envelope : std_logic_vector(17 downto 0);
    signal w_modulation : std_logic_vector(17 downto 0);
begin

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            case r_state is
                when idle =>
                    r_channel <= 0;
                    if i_en = '1' then
                        r_state   <= running;
                        r_rd_input <= not i_input_fifo_empty;  
                        r_rd_adsr <= not i_adsr_fifo_empty;  
                        r_rd_modulation <= not i_modulation_fifo_empty;  
                    end if;
                when running =>
                    r_channel <= r_channel + 1;
                    if r_channel = g_NUM_CHANNELS-1 then
                        r_state   <= idle;
                    end if;
            end case;        
        end if;
    end process;

    process(r_state, r_rd_input, r_rd_adsr, r_rd_modulation)
    begin
        case r_state is
            when idle =>
                o_input_fifo_rd_en <= '0';
                o_adsr_fifo_rd_en  <= '0';
                o_modulation_fifo_rd_en <= '0';
                w_data_valid_in <= '0';
            when running =>
                o_input_fifo_rd_en <= r_rd_input;
                o_adsr_fifo_rd_en  <= r_rd_adsr;
                o_modulation_fifo_rd_en <= r_rd_modulation;
                w_data_valid_in <= '1';
        end case;        
    end process;
    
    o_output_fifo_wr_data <= w_output;
    o_output_fifo_wr_en   <= w_data_valid_out;
    
    w_input         <= i_input_fifo_rd_data when r_rd_input = '1' else (others => '0');
    w_adsr_envelope <= i_adsr_fifo_rd_data when r_rd_adsr = '1' else (others => '0');
    w_modulation    <= i_modulation_fifo_rd_data when r_rd_modulation = '1' else (others => '0');
    
    ladder_filter : entity work.moog_ladder_filter
    generic map(
        g_NUM_CHANNELS => g_NUM_CHANNELS,
        g_DATA_WIDTH   => g_DATA_WIDTH   
    )
    port map(
        i_clk                => i_clk,
        i_data_valid         => w_data_valid_in,
        i_input              => w_input,
        i_resonance          => i_resonance,
        i_cutoff_frequency   => i_cutoff_frequency,
        i_adsr_envelope      => w_adsr_envelope,
        i_adsr_amount        => i_adsr_amount,
        i_modulation_en      => i_modulation_en,
        i_modulation         => w_modulation,
        i_modulation_amount  => i_modulation_amount,
        i_filter_type        => i_filter_type,
        i_filter_attenuation => i_filter_attenuation,
        o_output             => w_output,
        o_data_valid         => w_data_valid_out
    );

end arch;