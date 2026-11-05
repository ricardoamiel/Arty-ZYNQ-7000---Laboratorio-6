# Laboratorio 6 grupal: Arty Z7-20 con PS y PL, FFT, filtro FIR y potencia

**Integrantes:** Ricardo Amiel Acuña Villogas y Yanelit Picon Huaman

Curso de Señales Biológicas, semana 13. Herramientas: Vivado y Vitis 2025.2 sobre Ubuntu.

## Video y material

| Recurso | Enlace |
|---|---|
| Video de la placa funcionando | [Ver en Drive](https://drive.google.com/file/d/15j47dAb3DASq5ieea0aM342emI3dTVuM/view?usp=sharing) |
| Carpeta con todo el material | [Carpeta en Drive](https://drive.google.com/drive/folders/1psmLtL21YHwi7eiOAoLBj23YtwVGnrsq?usp=sharing) |

## Qué se hizo

1. **LED con la FPGA y el procesador:** LD0 y LD1 los controla el ARM Cortex A9 con un programa en C (AXI GPIO); LD2 parpadea a 1 Hz con un contador en Verilog y LD3 sigue al switch SW0, sin intervención del procesador.
2. **Simulación de la FFT y del filtro FIR:** núcleos xFFT 9.1 y FIR Compiler 7.2 simulados en xsim, con figuras vectoriales generadas en Python.
3. **Consumo de potencia:** estimación con report_power de Vivado para los tres diseños y análisis en el informe.

## Estructura

| Carpeta | Contenido |
|---|---|
| LED | Verilog, restricciones, programa en C y scripts de Vivado, Vitis y programación |
| DSP | Proyecto del curso con los núcleos DSP, simulación sin interfaz (sim_todo.sh) y figuras en resultados |
| informe | Informe en LaTeX: informe.tex (individual) e informe_grupal.tex (con ambos integrantes), figuras y reportes de potencia |
| evidencias | Foto de la placa y capturas de Vivado, Vitis y las terminales |
| boards | Board files de Digilent para la Arty Z7-20 |
| instalacion | Configuración de la instalación mínima de Vivado y Vitis (solo Zynq 7000) |

## Cómo reproducirlo

Ver GUIA.md para los comandos por terminal y GUIA_UI.md para el mismo flujo con la interfaz gráfica. En resumen:

```
source entorno.sh
cd DSP && ./sim_todo.sh
cd ../LED && ./run_led.sh todo
cd ../informe && python3 extraer_potencia.py && pdflatex informe_grupal.tex
```
