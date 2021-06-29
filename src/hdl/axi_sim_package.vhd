library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package axi_sim_package is

    type t_axi_slave is record
        -- write address channel
        awvalid : std_logic;
        awready : std_logic;
        awaddr  : std_logic_vector(5 downto 0);
        awprot  : std_logic_vector(2 downto 0);
        -- write data channel
        wvalid  : std_logic;
        wready  : std_logic;
        wdata   : std_logic_vector(31 downto 0);
        wstrb   : std_logic_vector(3 downto 0);
        -- write response channel
        bvalid  : std_logic;
        bready  : std_logic;
        bresp   : std_logic_vector(1 downto 0);
        -- read address channel
        arvalid : std_logic;
        arready : std_logic;
        araddr  : std_logic_vector(5 downto 0);
        arprot  : std_logic_vector(2 downto 0);
        -- read data channel
        rvalid  : std_logic;
        rready  : std_logic;
        rdata   : std_logic_vector(31 downto 0);
        rresp   : std_logic_vector(1 downto 0);
    end record t_axi_slave;

    constant C_INIT_AXI_SLAVE : t_axi_slave := ('Z', 'Z', (others => 'Z'), (others => 'Z'),
                                                'Z', 'Z', (others => 'Z'), (others => 'Z'),
                                                'Z', 'Z', (others => 'Z'),
                                                'Z', 'Z', (others => 'Z'), (others => 'Z'),
                                                'Z', 'Z', (others => 'Z'), (others => 'Z'));


    type t_axi_stream_slave is record
        tvalid  : std_logic;
        tdata  : std_logic_vector(31 downto 0);
        tready : std_logic;
    end record;

    procedure s_axi_write(signal axi_aclk     : in std_logic;
                          signal axi_slave        : inout t_axi_slave;
                          constant C_AXI_ADDR : in integer;
                          constant C_AXI_DATA : in std_logic_vector);

                                                
    procedure s_axi_read(signal axi_aclk     : in std_logic;
                         signal axi_slave     : inout t_axi_slave;
                         constant C_AXI_ADDR : in integer;
                         variable data : out std_logic_vector(31 downto 0));
                         
end package axi_sim_package;

package body axi_sim_package is   

    procedure s_axi_write(signal axi_aclk     : in std_logic;
                          signal axi_slave    : inout t_axi_slave;
                          constant C_AXI_ADDR : in integer;
                          constant C_AXI_DATA : in std_logic_vector) is
    begin
        axi_slave.awaddr  <= std_logic_vector(to_unsigned(C_AXI_ADDR*4, axi_slave.awaddr'length));
        axi_slave.awvalid <= '1';
        axi_slave.wdata   <= C_AXI_DATA;
        axi_slave.wvalid  <= '1';
        axi_slave.bready  <= '1';
        
        wait until axi_slave.awready = '1' or axi_slave.wready = '1';
        
        if axi_slave.awready = '1' and axi_slave.wready = '1' then
            wait until rising_edge(axi_aclk);
            axi_slave.awaddr  <= (others => '0');
            axi_slave.awvalid <= '0';
        elsif axi_slave.awready = '1' then
            wait until rising_edge(axi_aclk);
            axi_slave.awaddr  <= (others => '0');
            axi_slave.awvalid <= '0';
            wait until axi_slave.wready = '1';
            wait until rising_edge(axi_aclk);
            axi_slave.wdata  <= (others => '0');
            axi_slave.wvalid <= '0';
        elsif axi_slave.wready = '1' then
            wait until rising_edge(axi_aclk);
            axi_slave.wdata  <= (others => '0');
            axi_slave.wvalid <= '0';
            wait until axi_slave.awready = '1';
            wait until rising_edge(axi_aclk);
            axi_slave.awaddr  <= (others => '0');
            axi_slave.awvalid <= '0';
        end if;
        
        wait until axi_slave.bvalid = '1';
        wait until rising_edge(axi_aclk);
        axi_slave.bready  <= '0';
    end procedure; 

    
    procedure s_axi_read(signal axi_aclk     : in std_logic;
                         signal axi_slave     : inout t_axi_slave;
                         constant C_AXI_ADDR : in integer;
                         variable data : out std_logic_vector(31 downto 0)) is
    begin
        axi_slave.araddr  <= std_logic_vector(to_unsigned(C_AXI_ADDR*4, axi_slave.araddr'length));
        axi_slave.arvalid <= '1';
        
        wait until axi_slave.arready = '1';
        wait until rising_edge(axi_aclk);

        axi_slave.araddr  <= (others => '0');
        axi_slave.arvalid <= '0';
        axi_slave.rready  <= '1';

        wait until axi_slave.rvalid = '1';
        wait until rising_edge(axi_aclk);
        
        axi_slave.rready  <= '0';
        data := axi_slave.rdata;
    end procedure;

end package body axi_sim_package;