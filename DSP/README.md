# udm-dsp-xilinx
Udemy: Mastering Xilinx DSP IP cores (FIR compiler, CIC compiler, DDS compiler, xFFT)

## Requirements

### Required Packages (Windows, Linux)
```sh
Vitis 2024.2
Vivado 2024.2
python >= 3.8
matplotlib
NumPy
```

### Board files for Vivado 2024.2 from Digilent repository (for running Vivado examples for Arty z7-20 board)

```sh
git clone https://github.com/Digilent/vivado-boards.git
cd vivado-boards/
cp -r new/* /your/path/to/Xilinx/Vivado/2024.2/data/boards
```


# How to work

### To create project

use simple GUI

```sh
python auto/gui_launcher.py
```

or direct python scripts

```sh
python auto/run_sim.py name_ip
python auto/run_vivado.py name_ip
python auto/run_vitis.py name_ip

```
| target | description |
| ------ | ------ |
| run_sim.py | Testbench Simulation |
| run_vivado.py | Vivado project for .xsa file export |
| run_vitis.py | Vitis platform and Embedded Application components |

For each target corresponding directory in `build/` directory will be generated. 

| name_ip | description |
| ------ | ------ |
| fir | FIR compiler: single rate, Hilbert Transform, Decimation, Interpolation |
| cic | CIC compiler: Decimation, Interpolation |
| dds | DDS compiler: None phase correction, Truncated phase, Taylor series correction |
| xfft | Forward and Inverse Fast Fourier Transform |

### To clean project
```sh
python auto/clean.py
python auto/clean.py sim
python auto/clean.py vivado
python auto/clean.py vitis
```

## Workflow (Example for FIR compiler)
1. Run Testbench Simulation with Python script for IP cores output verification 
```sh
python auto/run_sim.py fir
python py/fir_compiler.py
```
Vivado project will be in `build/sim`. The project can be opened and modified. 

2. Run Vivado project for exporting .xsa file
```sh
python auto/run_vivado.py fir
```
In `build/vivado` directory `sys_wrapper.xsa` will be created. The Vivado project has System ILA for debugging using Jtag

3. Run Vitis project
```sh
python auto/run_vitis.py fir
```
In `build/vitis` directory Vitis workspace will be created with Embedded Application for corresponding IP core 







