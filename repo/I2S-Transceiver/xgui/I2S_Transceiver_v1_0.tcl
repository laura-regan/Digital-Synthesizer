# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "DBIT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MCLK_LRCK_RATIO" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SCLK_LRCK_RATIO" -parent ${Page_0}


}

proc update_PARAM_VALUE.DBIT { PARAM_VALUE.DBIT } {
	# Procedure called to update DBIT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DBIT { PARAM_VALUE.DBIT } {
	# Procedure called to validate DBIT
	return true
}

proc update_PARAM_VALUE.MCLK_LRCK_RATIO { PARAM_VALUE.MCLK_LRCK_RATIO } {
	# Procedure called to update MCLK_LRCK_RATIO when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MCLK_LRCK_RATIO { PARAM_VALUE.MCLK_LRCK_RATIO } {
	# Procedure called to validate MCLK_LRCK_RATIO
	return true
}

proc update_PARAM_VALUE.SCLK_LRCK_RATIO { PARAM_VALUE.SCLK_LRCK_RATIO } {
	# Procedure called to update SCLK_LRCK_RATIO when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCLK_LRCK_RATIO { PARAM_VALUE.SCLK_LRCK_RATIO } {
	# Procedure called to validate SCLK_LRCK_RATIO
	return true
}


proc update_MODELPARAM_VALUE.MCLK_LRCK_RATIO { MODELPARAM_VALUE.MCLK_LRCK_RATIO PARAM_VALUE.MCLK_LRCK_RATIO } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MCLK_LRCK_RATIO}] ${MODELPARAM_VALUE.MCLK_LRCK_RATIO}
}

proc update_MODELPARAM_VALUE.SCLK_LRCK_RATIO { MODELPARAM_VALUE.SCLK_LRCK_RATIO PARAM_VALUE.SCLK_LRCK_RATIO } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCLK_LRCK_RATIO}] ${MODELPARAM_VALUE.SCLK_LRCK_RATIO}
}

proc update_MODELPARAM_VALUE.DBIT { MODELPARAM_VALUE.DBIT PARAM_VALUE.DBIT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DBIT}] ${MODELPARAM_VALUE.DBIT}
}

