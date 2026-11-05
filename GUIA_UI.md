# Guía equivalente con la interfaz gráfica (Vivado y Vitis 2025.2)

**Alumno:** Ricardo Amiel Acuña Villogas

Los scripts hacen exactamente estos pasos. Esta guía sirve para tomar capturas para el informe o para repetir el procedimiento a mano. Antes de abrir las herramientas:

```
cd Grupal
source entorno.sh
```

## A. Ver la simulación de la FFT o del FIR con formas de onda

1. Desde la carpeta DSP ejecutar `vivado -source dsp_sim.tcl -tclargs xfft` (o fir). Es el script original del curso y abre la interfaz.
2. Vivado crea el proyecto, genera los núcleos y abre el simulador.
3. En la ventana de ondas: File, Open Waveform Configuration, y elegir ip_xfft/tb/xfft_tb_behav.wcfg (o la del FIR).
4. Pulsar Run All. Usar Zoom Fit para ver la señal completa.
5. Para ver una señal como onda analógica: clic derecho sobre ella, Waveform Style, Analog; y Radix, Signed Decimal.

## B. Parte 1, LED: diseño en Vivado

1. Abrir Vivado. Create Project, nombre led_sys, RTL Project, sin agregar fuentes por ahora.
2. En Default Part, pestaña Boards, buscar Arty Z7-20. Si no aparece: en la consola Tcl de Vivado ejecutar `set_param board.repoPaths [list <ruta>/Grupal/boards]` y volver a buscar.
3. Add Sources: agregar LED/hdl/pl_blink.v. Add Constraints: agregar LED/xdc/led.xdc.
4. IP Integrator, Create Block Design, nombre sys.
5. Agregar ZYNQ7 Processing System. Pulsar Run Block Automation (aplica el preajuste de la placa y saca DDR y FIXED_IO).
6. Doble clic en el PS7, Clock Configuration, PL Fabric Clocks: FCLK_CLK0 en 100 MHz.
7. Agregar AXI GPIO. Doble clic: GPIO Width 2, All Outputs activado. Pulsar Run Connection Automation solo para S_AXI (no para GPIO, porque usaremos pines propios).
8. Expandir el puerto GPIO del bloque, clic derecho sobre gpio_io_o, Make External, y renombrar el puerto a led_ps.
9. Arrastrar pl_blink.v desde Sources al diagrama (Add Module). Conectar clk a FCLK_CLK0. Clic derecho sobre sw, Make External, renombrar a sw0. Clic derecho sobre led, Make External, renombrar a led_pl.
10. Validate Design (F6). Luego en Sources: clic derecho sobre sys.bd, Create HDL Wrapper, dejar que Vivado lo administre.
11. Generate Bitstream (esperar síntesis, implementación y bitstream).
12. Open Implemented Design, Report Power: captura del resumen y del desglose para el informe. También Report Utilization.
13. File, Export, Export Hardware, Include bitstream, guardar sys_wrapper.xsa.

## C. Parte 1, LED: programa del procesador en Vitis

1. Abrir Vitis 2025.2 (comando `vitis`) y elegir una carpeta de workspace vacía.
2. File, New Component, Platform. Nombre artyZ720_led. Elegir el archivo sys_wrapper.xsa. Sistema operativo standalone, procesador ps7_cortexa9_0. Finish.
3. En la vista Flow, con la plataforma seleccionada, pulsar Build.
4. File, New Component, Application. Nombre app_led, plataforma artyZ720_led, dominio standalone_ps7_cortexa9_0.
5. En la aplicación, clic derecho sobre src, Import, Files, y elegir LED/src/led_main.c.
6. En la vista Flow, con app_led seleccionada, Build.

## D. Programar la placa y ver la consola

1. Conectar la placa (JP4 en JTAG). En Vitis, vista Flow, app_led, Run. Vitis programa el bitstream, inicializa el PS y ejecuta el programa.
2. Abrir la consola serial: en Vitis, View, Serial Monitor, puerto /dev/ttyUSB1 a 115200. También sirve `screen /dev/ttyUSB1 115200` en una terminal.
3. Solo la parte PL, sin Vitis: en Vivado, Open Hardware Manager, Open Target, Auto Connect, Program Device, elegir el .bit. LD2 parpadea y LD3 sigue a SW0; LD0 y LD1 quedan apagados porque falta el programa del procesador.

## E. Potencia de la FFT y del FIR en hardware

1. Ejecutar `python3 auto/run_vivado.py xfft` desde DSP, o abrir el proyecto que crea en DSP/build/vivado/xfft con Vivado.
2. Open Implemented Design, Report Power, y guardar las capturas.
