library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tanh_function is
    port(
        i_clk    : in  std_logic;
        i_input  : in  std_logic_vector(26 downto 0);
        o_result : out std_logic_vector(23 downto 0)
    );
end tanh_function;

architecture arch of tanh_function is

    -- constants
    constant c_DATA_WIDTH   : integer := 24;
    constant c_COEF_WIDTH   : integer := 18;
    constant c_PROD_WIDTH   : integer := c_DATA_WIDTH+c_COEF_WIDTH;
    constant c_SUM_WIDTH    : integer := c_PROD_WIDTH+1;
    constant c_DTERM_WIDTH  : integer := c_COEF_WIDTH;
    constant c_DATA_SCALE   : integer := 23;
    constant c_COEF_SCALE   : integer := 16;

    -- coefficients  in Q2.16 fixed-point format 
    type t_coef_array is array(0 to 5) of signed(c_COEF_WIDTH-1 downto 0);
    
    constant c_COEFFICIENT : t_coef_array := (  to_signed(  54120, c_COEF_WIDTH),
                                                to_signed(   20978, c_COEF_WIDTH),
                                                to_signed(   -16253, c_COEF_WIDTH),
                                                to_signed(  10567, c_COEF_WIDTH),
                                                to_signed( -5674, c_COEF_WIDTH),
                                                to_signed(  2291, c_COEF_WIDTH) );

--    constant c_COEFFICIENT : t_coef_array := (  to_signed(  53157, c_COEF_WIDTH),
--                                                to_signed(  20605, c_COEF_WIDTH),
--                                                to_signed( -15964, c_COEF_WIDTH),
--                                                to_signed(  10379, c_COEF_WIDTH),
--                                                to_signed(  -5573, c_COEF_WIDTH),
--                                                to_signed(   2250, c_COEF_WIDTH) );
                                                  
    -- input normalize stage
    signal w_input_scaled         : signed(c_DATA_WIDTH downto 0);
    signal w_input_absolute_value : signed(c_DATA_WIDTH downto 0);
    signal w_input_shifted        : signed(c_DATA_WIDTH+1   downto 0);
    signal w_input_normalized     : signed(c_DATA_WIDTH-1 downto 0);
    
    -- d term shift registers
    type t_dterm_shift_reg is array(0 to 2) of signed(c_DTERM_WIDTH-1 downto 0);
    signal r_dterm4_shift_reg : t_dterm_shift_reg := (others => (others => '0'));
    signal r_dterm3_shift_reg : t_dterm_shift_reg := (others => (others => '0'));
    signal r_dterm2_shift_reg : t_dterm_shift_reg := (others => (others => '0'));
   
    -- normalized input shift register
    type t_input_normalized_shift_reg is array(0 to 7) of signed(c_DATA_WIDTH-1 downto 0);
    signal r_input_normalized_shift_reg : t_input_normalized_shift_reg := (others => (others => '0'));
    
    type t_input_shift_reg is array(0 to 9) of signed(26 downto 0);
    signal r_input_shift_reg : t_input_shift_reg := (others => (others => '0'));
    
    -- input sign bit shift register
    signal r_input_sign_shift_reg : std_logic_vector(0 to 9) := (others => '0');
    
    -- dsp slice product registers
    type t_dsp_product_array is array(0 to 4) of signed(c_PROD_WIDTH-1 downto 0);
    signal r_dsp_product_reg : t_dsp_product_array := (others => (others => '0'));
    
    -- dsp slice sum registers
    type t_dsp_sum_array is array(0 to 4) of signed(c_SUM_WIDTH-1 downto 0);
    signal r_dsp_sum_reg : t_dsp_sum_array := (others => (others => '0'));
    
    -- output arithmetic saturation
    signal w_output_pre_saturation  : signed(c_SUM_WIDTH-1 downto 0);                      
    signal w_output_post_saturation : signed(c_DATA_WIDTH-1 downto 0);                     
    signal w_output_guard_bits      : std_logic_vector(c_SUM_WIDTH-c_DATA_WIDTH downto 0);
    
     signal test  : signed(c_SUM_WIDTH-1 downto 0);   
begin

    -- normalize absolute value of input
    w_input_scaled          <= resize(shift_right(signed(i_input), 2), c_DATA_WIDTH+1);
    w_input_absolute_value  <= w_input_scaled when w_input_scaled >= 0 else resize(-1*w_input_scaled, c_DATA_WIDTH+1);
    w_input_shifted         <= resize(w_input_absolute_value, c_DATA_WIDTH+2) - to_signed(2**(c_DATA_WIDTH-1), c_DATA_WIDTH+2);
    w_input_normalized      <= resize(w_input_shifted, c_DATA_WIDTH);

    -- main pipeline
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- main pipeline
            -- stage 1
            r_dsp_product_reg(0) <= w_input_normalized * c_COEFFICIENT(5);
            
            -- stage 2
            r_dsp_sum_reg(0) <= resize(r_dsp_product_reg(0), c_SUM_WIDTH) + shift_left(resize(c_COEFFICIENT(4), c_SUM_WIDTH), c_DATA_SCALE-1);
            
            -- stage 3
            r_dsp_product_reg(1) <= resize(shift_right(r_dsp_sum_reg(0), c_DATA_SCALE-1), c_COEF_WIDTH) * signed(r_input_normalized_shift_reg(1));
        
            -- stage 4
            r_dsp_sum_reg(1) <= resize(r_dsp_product_reg(1), c_SUM_WIDTH) - shift_left(resize(c_COEFFICIENT(5)-c_COEFFICIENT(3), c_SUM_WIDTH), c_DATA_SCALE-1);
            
            -- stage 5
            r_dsp_product_reg(2) <= resize(shift_right(r_dsp_sum_reg(1), c_DATA_SCALE-1), c_COEF_WIDTH) * signed(r_input_normalized_shift_reg(3));
            
            -- stage 6
            r_dsp_sum_reg(2) <= resize(r_dsp_product_reg(2), c_SUM_WIDTH) - shift_left(resize(r_dterm4_shift_reg(2), c_SUM_WIDTH), c_DATA_SCALE-1);
            
            -- stage 7
            r_dsp_product_reg(3) <= resize(shift_right(r_dsp_sum_reg(2), c_DATA_SCALE-1), c_COEF_WIDTH) * signed(r_input_normalized_shift_reg(5));
            
            -- stage 8
            r_dsp_sum_reg(3) <= resize( r_dsp_product_reg(3), c_SUM_WIDTH) - shift_left(resize(r_dterm3_shift_reg(2), c_SUM_WIDTH), c_DATA_SCALE-1);
            
            -- stage 9
            r_dsp_product_reg(4) <= resize(shift_right(r_dsp_sum_reg(3), c_DATA_SCALE-1), c_COEF_WIDTH) * signed(r_input_normalized_shift_reg(7));
            
            -- stage 10
            r_dsp_sum_reg(4) <= resize(r_dsp_product_reg(4), c_SUM_WIDTH) - shift_left(resize(r_dterm2_shift_reg(2), c_SUM_WIDTH), c_DATA_SCALE);
            test <= shift_left(resize(r_dterm2_shift_reg(2), c_SUM_WIDTH), c_DATA_SCALE);
            
            -- output
            if r_input_sign_shift_reg(9) = '0' then
                o_result <= std_logic_vector(w_output_post_saturation);
            else
                o_result <= std_logic_vector(resize(-1*w_output_post_saturation, c_DATA_WIDTH));
            end if;
            
            --o_result <= std_logic_vector(to_signed(  integer( 2.0**23.0*TANH(real(to_integer(r_input_shift_reg(9)))/2.0**23.0) ) , 24));
            
            -- shift registers 
            r_input_shift_reg(0) <= signed(i_input);
            for I in 0 to 8 loop
                r_input_shift_reg(I+1) <= r_input_shift_reg(I);
            end loop;
            
            -- shift registers 
            r_input_normalized_shift_reg(0) <= w_input_normalized;
            for I in 0 to 6 loop
                r_input_normalized_shift_reg(I+1) <= r_input_normalized_shift_reg(I);
            end loop;
            
            -- input sign feedword pipeline registers
            r_input_sign_shift_reg(0) <= i_input(i_input'left);
            for I in 0 to 8 loop
                r_input_sign_shift_reg(I+1) <= r_input_sign_shift_reg(I);
            end loop;

            -- d term 4 feedforward pipeline registers
            r_dterm4_shift_reg(0) <= resize(shift_right(r_dsp_sum_reg(0), c_DATA_SCALE-1), c_COEF_WIDTH);
            r_dterm4_shift_reg(1) <= r_dterm4_shift_reg(0);
            r_dterm4_shift_reg(2) <= r_dterm4_shift_reg(1) - c_COEFFICIENT(2);
            
            -- d term 3 feedforward pipeline registers
            r_dterm3_shift_reg(0) <= resize(shift_right(r_dsp_sum_reg(1), c_DATA_SCALE-1), c_COEF_WIDTH);
            r_dterm3_shift_reg(1) <= r_dterm3_shift_reg(0);
            r_dterm3_shift_reg(2) <= r_dterm3_shift_reg(1) - c_COEFFICIENT(1);
            
            -- d term 2 feedforward pipeline registers
            r_dterm2_shift_reg(0) <= resize(shift_right(r_dsp_sum_reg(2), c_DATA_SCALE-1), c_COEF_WIDTH);
            r_dterm2_shift_reg(1) <= r_dterm2_shift_reg(0);
            r_dterm2_shift_reg(2) <= r_dterm2_shift_reg(1) - c_COEFFICIENT(0);
        end if;
    end process;
    
    -- output arithmetic saturation
    w_output_pre_saturation <= shift_right(r_dsp_sum_reg(4), c_COEF_SCALE);
    w_output_guard_bits <= std_logic_vector(w_output_pre_saturation(c_SUM_WIDTH-1 downto c_DATA_WIDTH-1));
    
    process(w_output_guard_bits, w_output_pre_saturation)
    begin
        if w_output_guard_bits = (w_output_guard_bits'range => '1') or 
           w_output_guard_bits = (w_output_guard_bits'range => '0') then
            -- no overflow/underflow 
            w_output_post_saturation <= resize(w_output_pre_saturation, c_DATA_WIDTH);
        else
            if w_output_guard_bits(w_output_guard_bits'left) = '0' then 
                -- overflow
                w_output_post_saturation <= to_signed(2**(c_DATA_WIDTH-1)-1, c_DATA_WIDTH);
            else
                -- underflow 
                w_output_post_saturation <= to_signed(-2**(c_DATA_WIDTH-1), c_DATA_WIDTH);
            end if;
        end if;
    end process;
    
end arch;

architecture arch_v2 of tanh_function is

    -- constants
    constant c_DATA_WIDTH   : integer := 24;
    constant c_COEF_WIDTH   : integer := 18;
    constant c_PROD_WIDTH   : integer := c_DATA_WIDTH+c_COEF_WIDTH;
    constant c_SUM_WIDTH    : integer := c_PROD_WIDTH+1;
    constant c_DTERM_WIDTH  : integer := c_COEF_WIDTH;
    constant c_DATA_SCALE   : integer := 23;
    constant c_COEF_SCALE   : integer := 16;

    -- coefficients  in Q2.16 fixed-point format 
    type t_coef_array is array(0 to 5) of signed(c_COEF_WIDTH-1 downto 0);

    constant c_COEFFICIENT : t_coef_array := (  to_signed(     0, c_COEF_WIDTH),
                                                to_signed( 73293, c_COEF_WIDTH),
                                                to_signed(     0, c_COEF_WIDTH),
                                                to_signed(-12523, c_COEF_WIDTH),
                                                to_signed(     0, c_COEF_WIDTH),
                                                to_signed(  3480, c_COEF_WIDTH) );
                                                  
    -- input normalize stage
    signal w_input_saturated     : signed(c_DATA_WIDTH-1 downto 0);
    
    -- d term shift registers
    type t_dterm_shift_reg is array(0 to 2) of signed(c_DTERM_WIDTH-1 downto 0);
    signal r_dterm4_shift_reg : t_dterm_shift_reg := (others => (others => '0'));
    signal r_dterm3_shift_reg : t_dterm_shift_reg := (others => (others => '0'));
    signal r_dterm2_shift_reg : t_dterm_shift_reg := (others => (others => '0'));
   
    -- normalized input shift register
    type t_input_saturated_shift_reg is array(0 to 7) of signed(c_DATA_WIDTH-1 downto 0);
    signal r_input_saturated_shift_reg : t_input_saturated_shift_reg := (others => (others => '0'));
    
    -- dsp slice product registers
    type t_dsp_product_array is array(0 to 4) of signed(c_PROD_WIDTH-1 downto 0);
    signal r_dsp_product_reg : t_dsp_product_array := (others => (others => '0'));
    
    -- dsp slice sum registers
    type t_dsp_sum_array is array(0 to 4) of signed(c_SUM_WIDTH-1 downto 0);
    signal r_dsp_sum_reg : t_dsp_sum_array := (others => (others => '0'));
    
    signal test : signed(17 downto 0);
  
begin
    process(i_input)
    begin
        if signed(i_input(26 downto 24)) >= 2 then
            w_input_saturated  <= to_signed(2**20-1, c_DATA_WIDTH);
        elsif signed(i_input(26 downto 24)) < -2 then
            w_input_saturated  <= to_signed(-2**20, c_DATA_WIDTH);
        else
            w_input_saturated  <= resize(shift_right(signed(i_input), 1), c_DATA_WIDTH);
        end if;
    end process;
    
    -- main pipeline
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- main pipeline
            -- stage 1
            r_dsp_product_reg(0) <= w_input_saturated * c_COEFFICIENT(5);
            
            -- stage 2
            r_dsp_sum_reg(0) <= resize(r_dsp_product_reg(0), c_SUM_WIDTH) + shift_left(resize(c_COEFFICIENT(4), c_SUM_WIDTH), c_DATA_SCALE-1);
            
            -- stage 3
            r_dsp_product_reg(1) <= resize(shift_right(r_dsp_sum_reg(0), c_DATA_SCALE-1), c_COEF_WIDTH) * signed(r_input_saturated_shift_reg(1));
        
            -- stage 4
            r_dsp_sum_reg(1) <= resize(r_dsp_product_reg(1), c_SUM_WIDTH) - shift_left(resize(c_COEFFICIENT(5)-c_COEFFICIENT(3), c_SUM_WIDTH), c_DATA_SCALE-1);
            
            -- stage 5
            r_dsp_product_reg(2) <= resize(shift_right(r_dsp_sum_reg(1), c_DATA_SCALE-1), c_COEF_WIDTH) * signed(r_input_saturated_shift_reg(3));
            
            -- stage 6
            r_dsp_sum_reg(2) <= resize(r_dsp_product_reg(2), c_SUM_WIDTH) - shift_left(resize(r_dterm4_shift_reg(2), c_SUM_WIDTH), c_DATA_SCALE-1);
            
            -- stage 7
            r_dsp_product_reg(3) <= (resize(shift_right(r_dsp_sum_reg(2), c_DATA_SCALE-1), c_COEF_WIDTH) + signed(resize(unsigned(resize(shift_right(r_dsp_sum_reg(2), c_DATA_SCALE-2), 1)), c_COEF_WIDTH))) * signed(r_input_saturated_shift_reg(5));
            --signed(to_unsigned(1, c_COEF_WIDTH))
            -- stage 8
            r_dsp_sum_reg(3) <= resize( r_dsp_product_reg(3), c_SUM_WIDTH) - shift_left(resize(r_dterm3_shift_reg(2), c_SUM_WIDTH), c_DATA_SCALE-1);
            
            -- stage 9
            r_dsp_product_reg(4) <= resize(shift_right(r_dsp_sum_reg(3), c_DATA_SCALE-1), c_COEF_WIDTH) * signed(r_input_saturated_shift_reg(7));
            
            -- stage 10
            r_dsp_sum_reg(4) <= resize(r_dsp_product_reg(4), c_SUM_WIDTH) - shift_left(resize(r_dterm2_shift_reg(2), c_SUM_WIDTH), c_DATA_SCALE);
            
            -- output
            o_result <= std_logic_vector(resize(shift_right(r_dsp_sum_reg(4), c_COEF_SCALE), c_DATA_WIDTH));
           
            
            -- shift registers 
            r_input_saturated_shift_reg(0) <= w_input_saturated;
            for I in 0 to 6 loop
                r_input_saturated_shift_reg(I+1) <= r_input_saturated_shift_reg(I);
            end loop;
       
            -- d term 4 feedforward pipeline registers
            r_dterm4_shift_reg(0) <= resize(shift_right(r_dsp_sum_reg(0), c_DATA_SCALE-1), c_COEF_WIDTH);
            r_dterm4_shift_reg(1) <= r_dterm4_shift_reg(0);
            r_dterm4_shift_reg(2) <= r_dterm4_shift_reg(1) - c_COEFFICIENT(2);
            
            -- d term 3 feedforward pipeline registers
            r_dterm3_shift_reg(0) <= resize(shift_right(r_dsp_sum_reg(1), c_DATA_SCALE-1), c_COEF_WIDTH);
            r_dterm3_shift_reg(1) <= r_dterm3_shift_reg(0);
            r_dterm3_shift_reg(2) <= r_dterm3_shift_reg(1) - c_COEFFICIENT(1);
            
            -- d term 2 feedforward pipeline registers
            r_dterm2_shift_reg(0) <= resize(shift_right(r_dsp_sum_reg(2), c_DATA_SCALE-1), c_COEF_WIDTH);
            r_dterm2_shift_reg(1) <= r_dterm2_shift_reg(0);
            r_dterm2_shift_reg(2) <= r_dterm2_shift_reg(1)+ signed(resize(unsigned(resize(shift_right(r_dterm2_shift_reg(1), c_DATA_SCALE-2), 1)), c_COEF_WIDTH)) - c_COEFFICIENT(0);
            
            --signed(to_unsigned(1, c_COEF_WIDTH))
        end if;
    end process;
    
    test <= resize(shift_right(r_dsp_sum_reg(2), c_DATA_SCALE-1), c_COEF_WIDTH);
    
end arch_v2;