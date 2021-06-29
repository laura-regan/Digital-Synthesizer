library ieee;
use ieee.std_logic_1164.all;

entity shift_register is
    generic(
        g_LENGTH    : integer := 128;
        g_DATA_SIZE : integer := 24
        );
    port(
        i_clk  : in std_logic;
        i_en   : in std_logic;
        i_in   : in std_logic_vector(g_DATA_SIZE-1 downto 0);
        o_out  : out std_logic_vector(g_DATA_SIZE-1 downto 0)
    );
end shift_register;

architecture arch of shift_register is

    type t_slv_array is array (0 to g_LENGTH-1) of std_logic_vector(g_DATA_SIZE-1 downto 0);
    signal r_shift_register : t_slv_array := (others => (others => '0'));
    
begin
    
    process(i_clk)
    begin 
        if rising_edge(i_clk) then
            if i_en = '1' then
                r_shift_register(0) <= i_in;
                for idx in 0 to g_LENGTH-2 loop
                    r_shift_register(idx+1) <= r_shift_register(idx);
                end loop;
            end if;
        end if;
    end process;
    
    o_out <= r_shift_register(g_LENGTH-1);
    
end arch;