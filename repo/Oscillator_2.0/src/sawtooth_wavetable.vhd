-- Module: Sawtooth Wavetable
-- Author: Laura Regan
-- Data: 21/12/2020
-- Description: Array of bandlimited saw wavetables to avoid antialising. There is one wavetable 
-- per octave. Each table is stored as a bram with two synchronous read ports.

library ieee;
use ieee.std_logic_1164.all;

package sawtooth_wavetable_package is   
    constant c_DATA_WIDTH  : integer := 24;  -- width of waveform data outputs
    constant c_ADDR_WDITH  : integer := 11;  -- width of wavetable address     
end package sawtooth_wavetable_package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library work;
use work.sawtooth_wavetable_package.all;

entity sawtooth_wavetable is
    port(
        i_clk     : in  std_logic;
        i_en      : in  std_logic;
        i_addr_a  : in  std_logic_vector(c_ADDR_WDITH-1 downto 0);
        i_addr_b  : in  std_logic_vector(c_ADDR_WDITH-1 downto 0);
        i_octave  : in  std_logic_vector(3 downto 0);
        o_out_a   : out std_logic_vector(c_DATA_WIDTH-1 downto 0);
        o_out_b   : out std_logic_vector(c_DATA_WIDTH-1 downto 0)
    );
end sawtooth_wavetable;

architecture arch of sawtooth_wavetable is
    -- constants
    constant c_NUM_OCTAVES   : integer := 10; -- # of octaves
    constant c_ADDR_WIDTH    : integer := 11;
    constant c_DATA_WIDTH    : integer := 24;
    
    -- types
    type t_wavetable is array(0 to 2**c_ADDR_WIDTH-1) of std_logic_vector(c_DATA_WIDTH-1 downto 0);
    type t_wavetable_array is array(0 to c_NUM_OCTAVES-1) of t_wavetable;
    type t_slv_array is array(0 to 9) of std_logic_vector(c_DATA_WIDTH-1 downto 0);
    
    -- bram initilization function
    impure function read_wavetable(i_directory : in string) return t_wavetable is
        file     v_file     : text is in i_directory;
        variable v_line      : line;
        variable v_data_read  : bit_vector(c_DATA_WIDTH-1 downto 0);
        variable v_wavetable : t_wavetable := (others => (others => '0'));
    begin
        for I in v_Wavetable'range loop
            readline (v_file, v_line);
            read(v_line, v_data_read);
            v_wavetable(I) := to_stdlogicvector(v_data_read);
        end loop;
        return v_wavetable;
    end function;

    -- wavetable binary file directory
    constant directory  : string := "F:\HDL\Synthesizer\repo\Oscillator_2.0\src\";
    
    -- array of triangle wavetables (one per octave) each stored as a bram
    constant wavetables : t_wavetable_array := (   read_wavetable(directory & "sawtooth0.txt"),
                                                   read_wavetable(directory & "sawtooth1.txt"),
                                                   read_wavetable(directory & "sawtooth2.txt"),
                                                   read_wavetable(directory & "sawtooth3.txt"),
                                                   read_wavetable(directory & "sawtooth4.txt"),
                                                   read_wavetable(directory & "sawtooth5.txt"),
                                                   read_wavetable(directory & "sawtooth6.txt"),
                                                   read_wavetable(directory & "sawtooth7.txt"),
                                                   read_wavetable(directory & "sawtooth8.txt"),
                                                   read_wavetable(directory & "sawtooth9.txt") );
                                                   
    -- synchronous outputs of wavetable bram 
    signal r_output_array_a : t_slv_array;
    signal r_output_array_b : t_slv_array;
    
begin
    -- read from all wavetables
    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            for i in 0 to c_NUM_OCTAVES-1 loop
                r_output_array_a(i) <= wavetables(i)(to_integer((unsigned(i_addr_a))));
                r_output_array_b(i) <= wavetables(i)(to_integer((unsigned(i_addr_b)))); 
            end loop;
        end if;
    end process;
    
    -- output data from selected octave
    o_out_a <= r_output_array_a(to_integer(unsigned(i_octave)));
    o_out_b <= r_output_array_b(to_integer(unsigned(i_octave)));
    
end arch;