# Programa la placa por JTAG: bitstream (PL) + inicializacion del PS + aplicacion (ELF)
# Uso: xsdb program.tcl <hw_dir> <elf>
set hw  [lindex $argv 0]
set elf [lindex $argv 1]
connect
targets -set -nocase -filter {name =~ "APU*"}
rst -system
after 1000
targets -set -nocase -filter {name =~ "xc7z020*"}
fpga -file $hw/sys_wrapper.bit
targets -set -nocase -filter {name =~ "APU*"}
source $hw/ps7_init.tcl
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow $elf
con
puts "PROGRAMADO"
