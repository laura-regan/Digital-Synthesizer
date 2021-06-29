-- Module: Sine Wavetable
-- Author: Laura Regan
-- Data: 21/12/2020
-- Description: Sine wavetable.

library ieee;
use ieee.std_logic_1164.all;

package sine_wavetable_package is   
    constant c_DATA_WIDTH  : integer := 24;  -- width of waveform data outputs
    constant c_ADDR_WDITH  : integer := 8;   -- width of wavetable address     
end package sine_wavetable_package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sine_wavetable_package.all;

entity sine_wavetable is
    port(
        i_clk     : in  std_logic;
        i_en      : in  std_logic;
        i_addr    : in  std_logic_vector(c_ADDR_WDITH-1 downto 0);
        i_octave  : in  std_logic_vector(3 downto 0);
        o_out     : out std_logic_vector(c_DATA_WIDTH-1 downto 0)
    );
end sine_wavetable;

architecture arch of sine_wavetable is

    type ram_type is array (0 to 2**c_ADDR_WDITH - 1) 
    of std_logic_vector(c_DATA_WIDTH-1 downto 0);
    
    constant SIN_LUT : ram_type := (
        x"000000", x"03242a", x"0647d9", x"096a90", x"0c8bd3", x"0fab27",
        x"12c810", x"15e214", x"18f8b8", x"1c0b82", x"1f19f9", x"2223a4",
        x"25280c", x"2826b8", x"2b1f34", x"2e110a", x"30fbc4", x"33def2",
        x"36ba1f", x"398cdc", x"3c56b9", x"3f1749", x"41ce1d", x"447acc",
        x"471cec", x"49b414", x"4c3fdf", x"4ebfe8", x"5133cb", x"539b2a",
        x"55f5a4", x"5842dc", x"5a8278", x"5cb420", x"5ed77b", x"60ec37",
        x"62f200", x"64e888", x"66cf80", x"68a69d", x"6a6d97", x"6c2428",
        x"6dca0c", x"6f5f01", x"70e2ca", x"72552b", x"73b5ea", x"7504d2",
        x"7641ae", x"776c4d", x"788483", x"798a22", x"7a7d04", x"7b5d02",
        x"7c29fa", x"7ce3cd", x"7d8a5e", x"7e1d92", x"7e9d54", x"7f0990",
        x"7f6235", x"7fa735", x"7fd886", x"7ff620", x"7fffff", x"7ff620",
        x"7fd886", x"7fa735", x"7f6235", x"7f0990", x"7e9d54", x"7e1d92",
        x"7d8a5e", x"7ce3cd", x"7c29fa", x"7b5d02", x"7a7d04", x"798a22",
        x"788483", x"776c4d", x"7641ae", x"7504d2", x"73b5ea", x"72552b",
        x"70e2ca", x"6f5f01", x"6dca0c", x"6c2428", x"6a6d97", x"68a69d",
        x"66cf80", x"64e888", x"62f200", x"60ec37", x"5ed77b", x"5cb420",
        x"5a8278", x"5842dc", x"55f5a4", x"539b2a", x"5133cb", x"4ebfe8",
        x"4c3fdf", x"49b414", x"471cec", x"447acc", x"41ce1d", x"3f1749",
        x"3c56b9", x"398cdc", x"36ba1f", x"33def2", x"30fbc4", x"2e110a",
        x"2b1f34", x"2826b8", x"25280c", x"2223a4", x"1f19f9", x"1c0b82",
        x"18f8b8", x"15e214", x"12c810", x"0fab27", x"0c8bd3", x"096a90",
        x"0647d9", x"03242a", x"000000", x"fcdbd6", x"f9b827", x"f69570",
        x"f3742d", x"f054d9", x"ed37f0", x"ea1dec", x"e70748", x"e3f47e",
        x"e0e607", x"dddc5c", x"dad7f4", x"d7d948", x"d4e0cc", x"d1eef6",
        x"cf043c", x"cc210e", x"c945e1", x"c67324", x"c3a947", x"c0e8b7",
        x"be31e3", x"bb8534", x"b8e314", x"b64bec", x"b3c021", x"b14018",
        x"aecc35", x"ac64d6", x"aa0a5c", x"a7bd24", x"a57d88", x"a34be0",
        x"a12885", x"9f13c9", x"9d0e00", x"9b1778", x"993080", x"975963",
        x"959269", x"93dbd8", x"9235f4", x"90a0ff", x"8f1d36", x"8daad5",
        x"8c4a16", x"8afb2e", x"89be52", x"8893b3", x"877b7d", x"8675de",
        x"8582fc", x"84a2fe", x"83d606", x"831c33", x"8275a2", x"81e26e",
        x"8162ac", x"80f670", x"809dcb", x"8058cb", x"80277a", x"8009e0",
        x"800001", x"8009e0", x"80277a", x"8058cb", x"809dcb", x"80f670",
        x"8162ac", x"81e26e", x"8275a2", x"831c33", x"83d606", x"84a2fe",
        x"8582fc", x"8675de", x"877b7d", x"8893b3", x"89be52", x"8afb2e",
        x"8c4a16", x"8daad5", x"8f1d36", x"90a0ff", x"9235f4", x"93dbd8",
        x"959269", x"975963", x"993080", x"9b1778", x"9d0e00", x"9f13c9",
        x"a12885", x"a34be0", x"a57d88", x"a7bd24", x"aa0a5c", x"ac64d6",
        x"aecc35", x"b14018", x"b3c021", x"b64bec", x"b8e314", x"bb8534",
        x"be31e3", x"c0e8b7", x"c3a947", x"c67324", x"c945e1", x"cc210e",
        x"cf043c", x"d1eef6", x"d4e0cc", x"d7d948", x"dad7f4", x"dddc5c",
        x"e0e607", x"e3f47e", x"e70748", x"ea1dec", x"ed37f0", x"f054d9",
        x"f3742d", x"f69570", x"f9b827", x"fcdbd6");   
      
      signal wavetable: ram_type := SIN_LUT;
      
begin
    -- read from wavetable
    process(i_Clk)
    begin
        if rising_edge(i_Clk) then       
            o_out <= wavetable(to_integer((unsigned(i_addr)))); 
        end if;
    end process;
    
end arch;