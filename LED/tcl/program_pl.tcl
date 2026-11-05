# Graba solo el bitstream (parte PL) con el Hardware Manager de Vivado, sin Vitis.
# Uso: vivado -mode batch -source program_pl.tcl -tclargs <archivo.bit>
set bit [lindex $argv 0]
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set dev [lindex [get_hw_devices xc7z020*] 0]
current_hw_device $dev
set_property PROGRAM.FILE $bit $dev
program_hw_devices $dev
puts "PL PROGRAMADA: LD2 parpadea y LD3 sigue a SW0"
close_hw_manager
