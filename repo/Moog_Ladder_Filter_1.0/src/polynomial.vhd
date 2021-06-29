library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity polynomial is
    generic(
        g_DATA_WIDTH   : integer := 18   
    );
    port(
        i_clk    : in std_logic;
        i_input  : in std_logic_vector(g_DATA_WIDTH-1 downto 0); -- Q3.15
        o_output : out std_logic_vector(g_DATA_WIDTH-1 downto 0) -- Q3.15
    );
end polynomial;

architecture arch of polynomial is
    -- polynomial order
    constant c_POLY_ORDER : integer := 4;
    -- product and sum data widths                                                                     
    constant c_PROD_WIDTH : integer := 2*g_DATA_WIDTH;
    constant c_SUM_WIDTH  : integer := 2*g_DATA_WIDTH+1;
    -- types
    type t_input_array is array (1 to 2*c_POLY_ORDER-1) of signed(g_DATA_WIDTH-1 downto 0);
    type t_prod_array  is array (0 to c_POLY_ORDER-1) of signed(c_PROD_WIDTH-1 downto 0);
    type t_sum_array   is array (0 to c_POLY_ORDER-1) of signed(c_SUM_WIDTH-1 downto 0);
    type t_coef_array  is array (0 to c_POLY_ORDER)   of signed(g_DATA_WIDTH-1 downto 0);
    -- polynomial coefficients
    constant c_COEFFICIENTS : t_coef_array := ( to_signed( -661, g_DATA_WIDTH), 
                                                to_signed( 4525, g_DATA_WIDTH),
                                                to_signed(-14227, g_DATA_WIDTH),
                                                to_signed( 32414, g_DATA_WIDTH),
                                                to_signed(     0, g_DATA_WIDTH) );
    
    -- DSP slice product and sum registers                                             
    signal r_dsp_prod_reg : t_prod_array  := (others => (others => '0'));
    signal r_dsp_sum_reg  : t_sum_array   := (others => (others => '0'));
    signal r_input_reg    : t_input_array := (others => (others => '0'));
    -- data inputs should be scaled by 2^15
    constant c_SCALE_FACTOR : integer := 15;
    
begin
    
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- 1st stage
            r_dsp_prod_reg(0) <= signed(i_input) * c_COEFFICIENTS(0);
            r_dsp_sum_reg(0)  <= resize(r_dsp_prod_reg(0), c_SUM_WIDTH) + shift_left(resize(c_COEFFICIENTS(1), c_SUM_WIDTH), c_SCALE_FACTOR);
            
            -- nth stage
            for idx in 1 to c_POLY_ORDER-1 loop
                r_dsp_prod_reg(idx) <= r_input_reg(idx*2) * resize(shift_right(r_dsp_sum_reg(idx-1), c_SCALE_FACTOR), g_DATA_WIDTH);
                r_dsp_sum_reg(idx)  <= resize(r_dsp_prod_reg(idx), c_SUM_WIDTH) + shift_left(resize(c_COEFFICIENTS(idx+1), c_SUM_WIDTH), c_SCALE_FACTOR);
            end loop;  
            
            -- input value pipeline
            r_input_reg(1) <= signed(i_input);
            for idx in 1 to 2*c_POLY_ORDER-2 loop
                r_input_reg(idx+1) <= r_input_reg(idx); 
            end loop; 
        end if;
    end process;

    o_output <= std_logic_vector(resize(shift_right(r_dsp_sum_reg(c_POLY_ORDER-1), c_SCALE_FACTOR), g_DATA_WIDTH));

end arch;