

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "ADSR" "NUM_INSTANCES" "DEVICE_ID"  "C_S_AXI_CTRL_BASEADDR" "C_S_AXI_CTRL_HIGHADDR"
}
