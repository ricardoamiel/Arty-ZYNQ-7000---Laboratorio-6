# Guía del Laboratorio 6 grupal: Arty Z7-20

**Alumno:** Ricardo Amiel Acuña Villogas

Esta carpeta funciona en cualquier Ubuntu que tenga Vivado y Vitis (versión 2024.2 o posterior). Los scripts buscan solos la instalación y las board files de la Arty Z7-20 ya vienen incluidas en la carpeta boards, así que no hace falta copiarlas a Vivado.

## Contenido

| Carpeta o archivo | Para qué sirve |
|---|---|
| entorno.sh | Encuentra Vivado y Vitis y los agrega al PATH |
| boards | Board files de Digilent para la Arty Z7-20 |
| LED | Parte 1: LEDs con la FPGA (PL) y con el procesador (PS) |
| DSP | Parte 2: simulación y hardware de la FFT y del filtro FIR |
| informe | Informe en LaTeX con tablas de potencia automáticas |

## 0. Preparación (una sola vez por máquina)

1. Copiar la carpeta Grupal a la máquina y abrir una terminal dentro de ella.
2. Dar permisos de ejecución a los scripts:

```
chmod +x entorno.sh LED/run_led.sh DSP/sim_todo.sh
```

3. Comprobar que se detectan las herramientas:

```
source entorno.sh
```

Debe mostrar la versión de Vivado y la ruta de Vitis. Si aparece un aviso, indicar la ruta a mano, por ejemplo:

```
export XIL_VIVADO=/tools/Xilinx/Vivado/2024.2/settings64.sh
export XIL_VITIS=/tools/Xilinx/Vitis/2024.2/settings64.sh
```

4. Verificar Python (numpy y matplotlib):

```
python3 -c "import numpy, matplotlib; print('ok')"
```

5. Placa: jumper JP4 en JTAG, jumper de alimentación en USB y cable conectado al puerto PROG UART. Al conectarla deben aparecer /dev/ttyUSB0 y /dev/ttyUSB1:

```
ls /dev/ttyUSB*
```

Si la máquina nunca programó una placa AMD, instalar los drivers del cable una vez (la ruta exacta depende de la versión):

```
sudo $(dirname $(dirname $(which vivado)))/data/xicom/cable_drivers/lin64/install_script/install_drivers/install_drivers
```

Luego desconectar y volver a conectar la placa.

## 1. Parte 1: LED con la FPGA y el procesador

Qué hace el diseño:

| LED | Lo controla | Comportamiento |
|---|---|---|
| LD0 | Procesador ARM (led_main.c) | Cambia cada 500 ms |
| LD1 | Procesador ARM (led_main.c) | Cambia cada 1 s (contador binario con LD0) |
| LD2 | FPGA (pl_blink.v) | Parpadea a 1 Hz con un contador |
| LD3 | FPGA (pl_blink.v) | Copia el switch SW0 |

Pasos, desde la carpeta LED:

```
cd LED
./run_led.sh hw      # Vivado: bitstream, .xsa y reportes de potencia (unos 10 a 15 min)
./run_led.sh sw      # Vitis: plataforma standalone y compilación de led_main.c (unos 3 a 5 min)
./run_led.sh prog    # Graba la placa por JTAG y ejecuta el programa
```

O todo de una vez:

```
./run_led.sh todo
```

Para ver los mensajes del procesador por la UART, en otra terminal:

```
screen /dev/ttyUSB1 115200
```

Se sale de screen con Ctrl+A y luego K. Resultado esperado: LD2 parpadea a 1 Hz, LD3 se enciende al subir SW0 y LD0 y LD1 cuentan en binario mientras la consola imprime cada ciclo.

Reportes generados en LED/build/vivado/reportes: power.rpt, utilization.rpt y timing.rpt.

## 2. Parte 2: simulación de la FFT y del filtro FIR

Desde la carpeta DSP:

```
cd DSP
./sim_todo.sh          # simula xfft y fir en xsim, sin interfaz gráfica
```

Tarda unos 5 a 10 minutos por núcleo. Las figuras quedan en DSP/resultados en formato vectorial (PDF y SVG):

| Archivo | Contenido |
|---|---|
| xfft_1.pdf | Entrada, FFT directa y FFT inversa |
| fir_compiler_1.pdf a fir_compiler_5.pdf | Entrada (ruido), pasabanda, interpolador, decimador y Hilbert |

Para ver las formas de onda en la interfaz de Vivado (opcional, como en el curso):

```
source ../entorno.sh
python3 auto/run_sim.py xfft
```

## 3. Potencia de la FFT y del FIR en hardware (opcional, enriquece el informe)

Desde la carpeta DSP (cada uno tarda unos 20 minutos):

```
source ../entorno.sh
python3 auto/run_vivado.py xfft
python3 auto/run_vivado.py fir
```

Generan power_xfft.rpt y power_fir.rpt en DSP/build/vivado. Para probarlos en la placa:

```
python3 auto/run_vitis.py xfft
```

## 3b. FFT con señal cuadrada (ARM hacia FPGA)

Desde la carpeta DSP:

```
./sim_todo.sh xfft_sq                 # simula con los mismos datos y configuración que el ARM
python3 py/xfft_cuadrada.py sim       # verificación frente a numpy y diagramas de tiempo
./fft_placa.sh hw && ./fft_placa.sh sw   # bitstream y programa del ARM con la cuadrada
./fft_placa.sh prog                   # con la placa conectada: ejecuta y lee la DDR
```

Capturas de la interfaz (sin abrir ventanas), desde la carpeta capturas; requiere python-xlib:

```
./capturar.sh bd ../DSP/build/vivado/xfft/xfft.xpr bd_xfft
./capturar.sh ondas ../DSP/build/sim/xfft_sq.xpr ondas_xfft_sq_completo ../DSP/ip_xfft/tb/xfft_square_tb_completo.wcfg
```

## 4. Informe

Desde la carpeta informe:

```
cd informe
python3 extraer_potencia.py     # llena potencia_auto.tex con los reportes que existan
pdflatex informe.tex && pdflatex informe.tex
```

Las figuras y tablas se insertan solas cuando existen. Lo que falta completar aparece en rojo con la marca Pendiente: fotos de la placa, interpretaciones y conclusiones.

## Problemas frecuentes

| Síntoma | Solución |
|---|---|
| no se encontró Vivado | Definir XIL_VIVADO y XIL_VITIS como en el paso 0 |
| libtinfo.so.5 no encontrada (Ubuntu 24.04) | sudo ln -sf /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5 |
| board part arty-z7-20 not found | Ejecutar los scripts desde su carpeta; la carpeta boards debe estar junto a LED y DSP |
| No hw targets / no detecta la placa | Revisar cable y JP4 en JTAG; instalar drivers del cable (paso 0) |
| La placa vuelve a mostrar la demo de colores | JP4 quedó en QSPI; moverlo a JTAG |
