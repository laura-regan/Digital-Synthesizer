library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity one_pole_filter is
    generic(
        g_NUM_CHANNELS : integer := 128;
        g_DATA_WIDTH   : integer := 24;
        g_COEF_WIDTH   : integer := 18
    );
    port(
        i_clk : in std_logic;
        i_en  : in std_logic;
        i_x   : in std_logic_vector(g_DATA_WIDTH-1 downto 0);
        i_g   : in std_logic_vector(g_COEF_WIDTH-1 downto 0);
        o_en  : out std_logic;
        o_y   : out std_logic_vector(g_DATA_WIDTH-1 downto 0);
        o_g   : out std_logic_vector(g_COEF_WIDTH-1 downto 0)
    );
end one_pole_filter;

architecture arch of one_pole_filter is

    type t_signed_array is array (natural range<>) of signed(g_DATA_WIDTH-1 downto 0);
    type t_slv_array is array (natural range<>) of std_logic_vector(g_DATA_WIDTH-1 downto 0);
    type t_sl_array is array (natural range<>) of std_logic;

    constant c_COEF_SCALE_FACTOR : integer := 15;
    constant c_COEF_WIDTH : integer := 18;
    constant c_coefA : signed(17 downto 0) := to_signed(integer(25206), c_COEF_WIDTH); -- 1/1.3 * 2^15
    constant c_coefB : signed(17 downto 0) := to_signed(integer(7561), c_COEF_WIDTH);  -- 0.3/1.3 * 2^15

    constant c_PROD_WIDTH : integer := g_DATA_WIDTH + c_COEF_WIDTH;
    constant c_SUM_WIDTH  : integer := c_PROD_WIDTH + 1;

    signal r_x_old : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');
    
    signal r_g_A, r_g_B, r_g_C, r_g_D, r_g_E : std_logic_vector(g_COEF_WIDTH-1 downto 0) := (others => '0'); 
    signal r_y_old, r_y_old_B, r_y_old_C, r_y_old_D, r_y_old_E : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');
    signal r_x_old_A : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');
    signal r_data_valid_A, r_data_valid_B, r_data_valid_C, r_data_valid_D, r_data_valid_E : std_logic := '0'; 
    
    signal w_shift_x : std_logic;                               -- shift out old y value
    signal w_x_new : std_logic_vector(g_DATA_WIDTH-1 downto 0); -- new y value to shift in
    
    signal w_shift_y : std_logic;                               -- shift out old y value
    signal w_y_new : std_logic_vector(g_DATA_WIDTH-1 downto 0); -- new y value to shift in
    
    -- stage A
    signal r_prodA : signed(c_PROD_WIDTH-1 downto 0) := (others => '0');
    -- stage B
    signal r_prodB : signed(c_PROD_WIDTH-1 downto 0) := (others => '0');
    signal r_sumB  : signed(c_SUM_WIDTH-1 downto 0)  := (others => '0');
    -- stage C
    signal r_sumC  : signed(c_SUM_WIDTH-1 downto 0)  := (others => '0');
    -- stage D 
    signal r_prodD : signed(c_PROD_WIDTH-1+1 downto 0) := (others => '0'); 
    -- stage E
    signal r_sumE   : signed(c_SUM_WIDTH-1+1 downto 0) := (others => '0');
    
    -- stage A
    signal test_prodA : signed(c_PROD_WIDTH-1 downto 0) := (others => '0');
    -- stage B
    signal test_prodB : signed(c_PROD_WIDTH-1 downto 0) := (others => '0');
    signal test_sumB  : signed(c_SUM_WIDTH-1 downto 0)  := (others => '0');
    -- stage C
    signal test_sumC  : signed(c_SUM_WIDTH-1 downto 0)  := (others => '0');
    -- stage D 
    signal test_prodD : signed(c_PROD_WIDTH-1+1 downto 0) := (others => '0'); 
    -- stage E
    signal test_sumE   : signed(c_SUM_WIDTH-1+1 downto 0) := (others => '0');
    
begin

    -- filter pipeline
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- stage A
            r_prodA <= signed(i_x) * c_coefA;
    
            -- stage B
            r_sumB  <= resize(r_prodA, c_SUM_WIDTH)  - shift_left(resize(signed(r_y_old), c_SUM_WIDTH), c_COEF_SCALE_FACTOR);
            r_prodB <= signed(r_x_old_A) * c_coefB;
        
            -- stage C
            r_sumC  <= resize(r_prodB, c_SUM_WIDTH) + resize(r_sumB, c_SUM_WIDTH);
    
            -- stage D
            r_prodD <= resize(shift_right(r_sumC, c_COEF_SCALE_FACTOR), g_DATA_WIDTH+1) * signed(r_g_C);
          
            -- stage E
            r_sumE <= resize(r_prodD, c_SUM_WIDTH+1) + shift_left(resize(signed(r_y_old_D), c_SUM_WIDTH+1), c_COEF_SCALE_FACTOR);
            
            r_g_A <= i_g;
            r_g_B <= r_g_A;
            r_g_C <= r_g_B;
            r_g_D <= r_g_C;
            r_g_E <= r_g_D;
            
            
            r_data_valid_A <= i_en;
            r_data_valid_B <= r_data_valid_A;
            r_data_valid_C <= r_data_valid_B;
            r_data_valid_D <= r_data_valid_C;
            r_data_valid_E <= r_data_valid_D;
            
            r_x_old_A <= r_x_old;
            
            r_y_old_B <= r_y_old;
            r_y_old_C <= r_y_old_B;
            r_y_old_D <= r_y_old_C;
        end if;
    end process;

    o_g  <= r_g_E;
    o_en <= r_data_valid_E;
    o_y  <= std_logic_vector(resize(shift_right(r_sumE, c_COEF_SCALE_FACTOR), g_DATA_WIDTH));
    
    w_shift_x <= '1' when r_data_valid_B = '1' else '0';
    w_x_new <= i_x;

    shift_reg_unit_x : entity work.shift_register
    generic map(
        g_LENGTH    => g_NUM_CHANNELS,
        g_DATA_SIZE => g_DATA_WIDTH
    )
    port map(
        i_clk  => i_clk,
        i_en   => i_en,
        i_in   => w_x_new,
        o_out  => r_x_old
    );
    
    w_shift_y <= '1' when r_data_valid_A = '1' or r_data_valid_E = '1' else '0';
    w_y_new   <= std_logic_vector(resize(shift_right(r_sumE, c_COEF_SCALE_FACTOR), g_DATA_WIDTH));
    
    shift_reg_unit_y : entity work.shift_register
    generic map(
        g_LENGTH    => g_NUM_CHANNELS,
        g_DATA_SIZE => g_DATA_WIDTH
    )
    port map(
        i_clk  => i_clk,
        i_en   => w_shift_y,
        i_in   => w_y_new,
        o_out  => r_y_old
    );
    
end arch;