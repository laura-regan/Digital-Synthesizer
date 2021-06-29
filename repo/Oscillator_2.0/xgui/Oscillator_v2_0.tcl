# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  set C_S_AXI_CTRL_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S_AXI_CTRL_DATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {Width of S_AXI data bus} ${C_S_AXI_CTRL_DATA_WIDTH}
  set C_S_AXI_CTRL_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S_AXI_CTRL_ADDR_WIDTH" -parent ${Page_0}]
  set_property tooltip {Width of S_AXI address bus} ${C_S_AXI_CTRL_ADDR_WIDTH}
  ipgui::add_param $IPINST -name "C_S_AXI_CTRL_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_CTRL_HIGHADDR" -parent ${Page_0}
  set C_S_AXIS_FREQ_MOD_TDATA_WIDTH [ipgui::add_param $IPINST -name "C_S_AXIS_FREQ_MOD_TDATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {AXI4Stream sink: Data Width} ${C_S_AXIS_FREQ_MOD_TDATA_WIDTH}
  set C_M_AXIS_OUTPUT_TDATA_WIDTH [ipgui::add_param $IPINST -name "C_M_AXIS_OUTPUT_TDATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.} ${C_M_AXIS_OUTPUT_TDATA_WIDTH}
  set C_M_AXIS_OUTPUT_START_COUNT [ipgui::add_param $IPINST -name "C_M_AXIS_OUTPUT_START_COUNT" -parent ${Page_0}]
  set_property tooltip {Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.} ${C_M_AXIS_OUTPUT_START_COUNT}
  set C_S_AXIS_PWM_TDATA_WIDTH [ipgui::add_param $IPINST -name "C_S_AXIS_PWM_TDATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {AXI4Stream sink: Data Width} ${C_S_AXIS_PWM_TDATA_WIDTH}
  ipgui::add_param $IPINST -name "g_NUM_CHANNELS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "g_NUM_OSCILLATORS" -parent ${Page_0}


}

proc update_PARAM_VALUE.g_DATA_WIDTH { PARAM_VALUE.g_DATA_WIDTH } {
	# Procedure called to update g_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_DATA_WIDTH { PARAM_VALUE.g_DATA_WIDTH } {
	# Procedure called to validate g_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.g_NUM_CHANNELS { PARAM_VALUE.g_NUM_CHANNELS } {
	# Procedure called to update g_NUM_CHANNELS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_NUM_CHANNELS { PARAM_VALUE.g_NUM_CHANNELS } {
	# Procedure called to validate g_NUM_CHANNELS
	return true
}

proc update_PARAM_VALUE.g_NUM_OSCILLATORS { PARAM_VALUE.g_NUM_OSCILLATORS } {
	# Procedure called to update g_NUM_OSCILLATORS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_NUM_OSCILLATORS { PARAM_VALUE.g_NUM_OSCILLATORS } {
	# Procedure called to validate g_NUM_OSCILLATORS
	return true
}

proc update_PARAM_VALUE.C_S_AXI_CTRL_DATA_WIDTH { PARAM_VALUE.C_S_AXI_CTRL_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_CTRL_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_CTRL_DATA_WIDTH { PARAM_VALUE.C_S_AXI_CTRL_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_CTRL_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_CTRL_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_CTRL_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_CTRL_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_CTRL_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_CTRL_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_CTRL_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_CTRL_BASEADDR { PARAM_VALUE.C_S_AXI_CTRL_BASEADDR } {
	# Procedure called to update C_S_AXI_CTRL_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_CTRL_BASEADDR { PARAM_VALUE.C_S_AXI_CTRL_BASEADDR } {
	# Procedure called to validate C_S_AXI_CTRL_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_CTRL_HIGHADDR { PARAM_VALUE.C_S_AXI_CTRL_HIGHADDR } {
	# Procedure called to update C_S_AXI_CTRL_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_CTRL_HIGHADDR { PARAM_VALUE.C_S_AXI_CTRL_HIGHADDR } {
	# Procedure called to validate C_S_AXI_CTRL_HIGHADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXIS_FREQ_MOD_TDATA_WIDTH { PARAM_VALUE.C_S_AXIS_FREQ_MOD_TDATA_WIDTH } {
	# Procedure called to update C_S_AXIS_FREQ_MOD_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXIS_FREQ_MOD_TDATA_WIDTH { PARAM_VALUE.C_S_AXIS_FREQ_MOD_TDATA_WIDTH } {
	# Procedure called to validate C_S_AXIS_FREQ_MOD_TDATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXIS_OUTPUT_TDATA_WIDTH { PARAM_VALUE.C_M_AXIS_OUTPUT_TDATA_WIDTH } {
	# Procedure called to update C_M_AXIS_OUTPUT_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXIS_OUTPUT_TDATA_WIDTH { PARAM_VALUE.C_M_AXIS_OUTPUT_TDATA_WIDTH } {
	# Procedure called to validate C_M_AXIS_OUTPUT_TDATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXIS_OUTPUT_START_COUNT { PARAM_VALUE.C_M_AXIS_OUTPUT_START_COUNT } {
	# Procedure called to update C_M_AXIS_OUTPUT_START_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXIS_OUTPUT_START_COUNT { PARAM_VALUE.C_M_AXIS_OUTPUT_START_COUNT } {
	# Procedure called to validate C_M_AXIS_OUTPUT_START_COUNT
	return true
}

proc update_PARAM_VALUE.C_S_AXIS_PWM_TDATA_WIDTH { PARAM_VALUE.C_S_AXIS_PWM_TDATA_WIDTH } {
	# Procedure called to update C_S_AXIS_PWM_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXIS_PWM_TDATA_WIDTH { PARAM_VALUE.C_S_AXIS_PWM_TDATA_WIDTH } {
	# Procedure called to validate C_S_AXIS_PWM_TDATA_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.C_S_AXI_CTRL_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_CTRL_DATA_WIDTH PARAM_VALUE.C_S_AXI_CTRL_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_CTRL_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_CTRL_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_CTRL_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_CTRL_ADDR_WIDTH PARAM_VALUE.C_S_AXI_CTRL_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_CTRL_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_CTRL_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXIS_FREQ_MOD_TDATA_WIDTH { MODELPARAM_VALUE.C_S_AXIS_FREQ_MOD_TDATA_WIDTH PARAM_VALUE.C_S_AXIS_FREQ_MOD_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXIS_FREQ_MOD_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXIS_FREQ_MOD_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXIS_OUTPUT_TDATA_WIDTH { MODELPARAM_VALUE.C_M_AXIS_OUTPUT_TDATA_WIDTH PARAM_VALUE.C_M_AXIS_OUTPUT_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXIS_OUTPUT_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_M_AXIS_OUTPUT_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXIS_OUTPUT_START_COUNT { MODELPARAM_VALUE.C_M_AXIS_OUTPUT_START_COUNT PARAM_VALUE.C_M_AXIS_OUTPUT_START_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXIS_OUTPUT_START_COUNT}] ${MODELPARAM_VALUE.C_M_AXIS_OUTPUT_START_COUNT}
}

proc update_MODELPARAM_VALUE.C_S_AXIS_PWM_TDATA_WIDTH { MODELPARAM_VALUE.C_S_AXIS_PWM_TDATA_WIDTH PARAM_VALUE.C_S_AXIS_PWM_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXIS_PWM_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXIS_PWM_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.g_NUM_CHANNELS { MODELPARAM_VALUE.g_NUM_CHANNELS PARAM_VALUE.g_NUM_CHANNELS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_NUM_CHANNELS}] ${MODELPARAM_VALUE.g_NUM_CHANNELS}
}

proc update_MODELPARAM_VALUE.g_NUM_OSCILLATORS { MODELPARAM_VALUE.g_NUM_OSCILLATORS PARAM_VALUE.g_NUM_OSCILLATORS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_NUM_OSCILLATORS}] ${MODELPARAM_VALUE.g_NUM_OSCILLATORS}
}

proc update_MODELPARAM_VALUE.g_DATA_WIDTH { MODELPARAM_VALUE.g_DATA_WIDTH PARAM_VALUE.g_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_DATA_WIDTH}] ${MODELPARAM_VALUE.g_DATA_WIDTH}
}

