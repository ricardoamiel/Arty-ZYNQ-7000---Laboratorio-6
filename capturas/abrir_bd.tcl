# Abre un proyecto, muestra su Block Design, lo exporta en SVG y avisa con un archivo marcador.
# Uso: vivado -mode gui -source abrir_bd.tcl -tclargs <proyecto.xpr> <salida_sin_extension>
set xpr  [lindex $argv 0]
set out  [lindex $argv 1]
open_project $xpr
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
write_bd_layout -force -format svg -file "${out}.svg"
set f [open "${out}.listo" w]; puts $f ok; close $f
