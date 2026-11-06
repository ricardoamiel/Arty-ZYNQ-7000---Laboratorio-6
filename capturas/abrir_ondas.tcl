# Abre la simulación del testbench con la señal cuadrada en el visor de ondas con una configuración
# (.wcfg) que define señales, formato analógico y rango de zoom; avisa con un archivo marcador.
# Uso: vivado -mode gui -source abrir_ondas.tcl -tclargs <proyecto_sim.xpr> <salida_sin_extension> <archivo.wcfg>
set xpr  [lindex $argv 0]
set out  [lindex $argv 1]
set wcfg [lindex $argv 2]
set lg [open "${out}.pasos" w]
proc paso {nombre cmd} {
    global lg
    if {[catch {uplevel #0 $cmd} e]} { puts $lg "FALLO $nombre: $e" } else { puts $lg "ok $nombre" }
    flush $lg
}
paso abrir    {open_project $xpr}
paso simular  {launch_simulation}
paso correr   {run 110 us}   ;# antes de $finish, para que la ventana de ondas quede al frente
paso cerrar   {close_wave_config [current_wave_config]}
# La ventana se redimensiona desde fuera antes de dibujar, para que el zoom se ajuste al panel grande
set f [open "${out}.esperando" w]; puts $f ok; close $f
while {![file exists "${out}.seguir"]} { after 500 }
paso wcfg     {open_wave_config $wcfg}
close $lg
set f [open "${out}.listo" w]; puts $f ok; close $f
