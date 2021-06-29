library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
    generic(
        g_WIDTH  : integer := 24;
        g_DEPTH : integer := 128
    );
    port(
        i_clk       : in  std_logic;
        i_reset     : in  std_logic;
        -- FIFO write interface
        i_wr_en     : in  std_logic;
        i_wr_data   : in  std_logic_vector(g_WIDTH-1 downto 0);
        o_full      : out std_logic;
        -- FIFO read interface
        i_rd_en     : in  std_logic;
        o_rd_data   : out std_logic_vector(g_WIDTH-1 downto 0);
        o_empty     : out std_logic
    );
end fifo;

architecture arch of fifo is
    
    type t_fifo_data is array (0 to g_DEPTH-1) of std_logic_vector(g_WIDTH-1 downto 0);
    signal r_fifo_data : t_fifo_data := (others => (others => '0'));
    
    signal r_wr_index : integer range 0 to g_DEPTH-1 := 0;
    signal r_rd_index : integer range 0 to g_DEPTH-1 := 0;
    
    signal w_rd_en : std_logic;
    signal w_wr_en : std_logic;
    
    signal r_fifo_count : integer range 0 to g_DEPTH := 0;
    
    signal w_full  : std_logic;
    signal w_empty : std_logic; 
    
    signal r_bypass_valid : std_logic := '0';
    signal r_bypass_data  : std_logic_vector(g_WIDTH-1 downto 0) := (others => '0');
    signal w_rd_next_index : integer range 0 to g_DEPTH-1 := 0;
    
    signal r_rd_data : std_logic_vector(g_WIDTH-1 downto 0) := (others => '0');
begin
    
    w_rd_next_index <= 0 when r_rd_index = g_DEPTH - 1 else
                       r_rd_index + 1;

    w_full  <= '1' when r_fifo_count = g_DEPTH else '0';
    w_empty <= '1' when r_fifo_count = 0       else '0';
    
    w_rd_en <= '1' when i_rd_en = '1' and w_empty = '0' else '0';
    w_wr_en <= '1' when i_wr_en = '1' and w_full = '0'  else '0';
    
    o_full  <= w_full;
    o_empty <= w_empty; 

    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                r_fifo_count <= 0;
                r_wr_index   <= 0;
                r_rd_index   <= 0;
            else
                -- update fifo count
                if (w_wr_en = '1' and w_rd_en = '0') then
                    r_fifo_count <= r_fifo_count + 1;
                elsif (w_wr_en = '0' and w_rd_en = '1') then  
                    r_fifo_count <= r_fifo_count - 1;
                end if;
                
                -- update write index
                if w_wr_en = '1' then
                    if r_wr_index = g_DEPTH-1 then
                        r_wr_index <= 0;
                    else
                        r_wr_index <= r_wr_index + 1;
                    end if;
                end if;
                
                -- update read index
                if w_rd_en = '1' then
                    if r_rd_index = g_DEPTH-1 then
                        r_rd_index <= 0;
                    else
                        r_rd_index <= r_rd_index + 1;
                    end if;
                end if;
                
                -- write data to fifo
                if w_wr_en = '1' then
                    r_fifo_data(r_wr_index) <= i_wr_data;
                end if;
                
                r_bypass_data <= i_wr_data;
                
                if w_rd_en = '1' then
                    r_rd_data <= r_fifo_data(w_rd_next_index);
                else
                    r_rd_data <= r_fifo_data(r_rd_index);
                end if;               
                
                r_bypass_valid <= '0';
                if w_wr_en = '0' then
                    r_bypass_valid <= '0';
                elsif (w_empty = '1' or (i_rd_en = '1' and r_fifo_count = 1)) then
                    r_bypass_valid <= '1';
                end if;
                
            end if;
        end if;
    end process;
    
    o_rd_data <= r_bypass_data when r_bypass_valid = '1' else r_rd_data;

end arch;