# Proyecto Vivado: PS7 + AXI GPIO (LEDs del procesador) + modulo RTL (LEDs de la FPGA)
# Uso: vivado -mode batch -source led_hw.tcl   (desde LED/build/vivado)
set root    [file normalize [file dirname [info script]]/..]
set out     [pwd]
set part    xc7z020clg400-1

# Board files de la Arty Z7-20 incluidas en el proyecto (no requiere copiarlas a Vivado)
set_param board.repoPaths [list [file normalize [file dirname [info script]]/../../boards]]

create_project led_sys $out/led_sys -part $part -force
set_property board_part digilentinc.com:arty-z7-20:part0:1.1 [current_project]
add_files -norecurse $root/hdl/pl_blink.v
add_files -fileset constrs_1 -norecurse $root/xdc/led.xdc
update_compile_order -fileset sources_1

create_bd_design sys
set ps [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} $ps
set_property CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} $ps

# LEDs controlados por el procesador
set gpio [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 gpio_ps]
set_property -dict [list CONFIG.C_GPIO_WIDTH {2} CONFIG.C_ALL_OUTPUTS {1}] $gpio
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/ps7/M_AXI_GP0} Slave {/gpio_ps/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}} \
    [get_bd_intf_pins gpio_ps/S_AXI]
create_bd_port -dir O -from 1 -to 0 led_ps
connect_bd_net [get_bd_pins gpio_ps/gpio_io_o] [get_bd_ports led_ps]

# LEDs controlados solo por la logica de la FPGA
create_bd_cell -type module -reference pl_blink pl_blink_0
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins pl_blink_0/clk]
create_bd_port -dir I sw0
connect_bd_net [get_bd_ports sw0] [get_bd_pins pl_blink_0/sw]
create_bd_port -dir O -from 1 -to 0 led_pl
connect_bd_net [get_bd_pins pl_blink_0/led] [get_bd_ports led_pl]

assign_bd_address
validate_bd_design
save_bd_design
set wrapper [make_wrapper -files [get_files sys.bd] -top]
add_files -norecurse $wrapper
set_property top sys_wrapper [current_fileset]
update_compile_order -fileset sources_1

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: la implementacion no termino"; exit 1
}

# Reportes para el informe (potencia, recursos, tiempos)
open_run impl_1
file mkdir $out/reportes
report_power             -file $out/reportes/power.rpt
report_power -format xml -file $out/reportes/power.xml
report_utilization       -file $out/reportes/utilization.rpt
report_timing_summary    -file $out/reportes/timing.rpt

write_hw_platform -fixed -include_bit -force -file $out/sys_wrapper.xsa
file copy -force [glob $out/led_sys/led_sys.runs/impl_1/*.bit] $out/sys_wrapper.bit
puts "LED_HW_OK"
