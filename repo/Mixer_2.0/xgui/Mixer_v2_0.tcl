# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  set C_S_AXIS_INPUT_TDATA_WIDTH [ipgui::add_param $IPINST -name "C_S_AXIS_INPUT_TDATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {AXI4Stream sink: Data Width} ${C_S_AXIS_INPUT_TDATA_WIDTH}
  ipgui::add_param $IPINST -name "g_NUM_CHANNELS" -parent ${Page_0}


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

proc update_PARAM_VALUE.C_S_AXIS_INPUT_TDATA_WIDTH { PARAM_VALUE.C_S_AXIS_INPUT_TDATA_WIDTH } {
	# Procedure called to update C_S_AXIS_INPUT_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXIS_INPUT_TDATA_WIDTH { PARAM_VALUE.C_S_AXIS_INPUT_TDATA_WIDTH } {
	# Procedure called to validate C_S_AXIS_INPUT_TDATA_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.C_S_AXIS_INPUT_TDATA_WIDTH { MODELPARAM_VALUE.C_S_AXIS_INPUT_TDATA_WIDTH PARAM_VALUE.C_S_AXIS_INPUT_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXIS_INPUT_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXIS_INPUT_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.g_NUM_CHANNELS { MODELPARAM_VALUE.g_NUM_CHANNELS PARAM_VALUE.g_NUM_CHANNELS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_NUM_CHANNELS}] ${MODELPARAM_VALUE.g_NUM_CHANNELS}
}

proc update_MODELPARAM_VALUE.g_DATA_WIDTH { MODELPARAM_VALUE.g_DATA_WIDTH PARAM_VALUE.g_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_DATA_WIDTH}] ${MODELPARAM_VALUE.g_DATA_WIDTH}
}

