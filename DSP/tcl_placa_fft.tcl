# Graba la placa con el diseño de la FFT, ejecuta la aplicación del ARM y lee los buffers de la DDR.
# Uso: xsdb tcl_placa_fft.tcl <bit> <ps7_init.tcl> <elf> <carpeta_salida>
set bit  [lindex $argv 0]
set init [lindex $argv 1]
set elf  [lindex $argv 2]
set out  [lindex $argv 3]
connect
targets -set -nocase -filter {name =~ "APU*"}
rst -system
after 1000
targets -set -nocase -filter {name =~ "xc7z020*"}
fpga -file $bit
targets -set -nocase -filter {name =~ "APU*"}
source $init
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow $elf
con
after 3000
stop
# 2048 palabras de 32 bits por buffer (direcciones definidas en xfft_main.c)
mrd -bin -file $out/entrada.bin 0x10100000 2048
mrd -bin -file $out/fft.bin     0x10300000 2048
mrd -bin -file $out/ifft.bin    0x10500000 2048
puts "BUFFERS_LEIDOS"
