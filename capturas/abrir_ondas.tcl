# Abre la simulación del testbench con la señal cuadrada en el visor de ondas y avisa con un marcador.
# Uso: vivado -mode gui -source abrir_ondas.tcl -tclargs <proyecto_sim.xpr> <salida_sin_extension>
set xpr [lindex $argv 0]
set out [lindex $argv 1]
open_project $xpr
launch_simulation
add_wave {{/xfft_square_tb/aclk}} {{/xfft_square_tb/aresetn}} {{/xfft_square_tb/s_config_fft_tvalid}} \
         {{/xfft_square_tb/s_axis_xfft_tvalid}} {{/xfft_square_tb/s_axis_xfft_tready}} {{/xfft_square_tb/s_axis_xfft_tlast}} \
         {{/xfft_square_tb/s_axis_xfft_tdata}} {{/xfft_square_tb/m_axis_fft_tvalid}} {{/xfft_square_tb/m_axis_fft_tlast}} \
         {{/xfft_square_tb/m_axis_fft_tdata}} {{/xfft_square_tb/m_axis_ifft_tvalid}} {{/xfft_square_tb/m_axis_ifft_tlast}} \
         {{/xfft_square_tb/m_axis_ifft_tdata}}
set_property radix signed [get_waves *tdata*]
run all
wave_zoom_full
set f [open "${out}.listo" w]; puts $f ok; close $f
