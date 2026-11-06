proc number_of_processor {} {
    global tcl_platform env
    switch ${tcl_platform(platform)} {
        "windows" { 
            return $env(NUMBER_OF_PROCESSORS)       
        }
        "unix" {
            if {![catch {open "/proc/cpuinfo"} f]} {
                set cores [regexp -all -line {^processor\s} [read $f]]
                close $f
                if {$cores > 0} {
                    return $cores
                }
            }
        }
        "Darwin" {
            if {![catch {exec {*}$sysctl -n "hw.ncpu"} cores]} {
                return $cores
            }
        }
        default {
            puts "Unknown System"
            return 1
        }
    }
}

set project_name fir
set project_dir [pwd]
set export_dir [file dirname $project_dir]
set n_cores [number_of_processor]
set n_cores [expr $n_cores - 2]
# Límite de trabajos paralelos: cada síntesis de IP usa unos 2 GB de RAM (agregado)
if {[info exists ::env(VIVADO_JOBS)]} {set n_cores $::env(VIVADO_JOBS)} elseif {$n_cores > 3} {set n_cores 3}

# default board to build a project
set board arty

# getting a FPGA part used in the project
set part xc7z020clg400-1
# creating a project
set_param board.repoPaths [list [file normalize [pwd]/../../../../boards]]  ;# board files incluidas (agregado)
create_project ${project_name} ${project_dir} -part ${part}
set_property board_part digilentinc.com:arty-z7-20:part0:1.1 [current_project]

# creating a block design
source fir_sys.tcl
# adding system wrapper
make_wrapper -files [get_files sys.bd] -top
add_files -norecurse [list "${project_dir}/${project_name}.gen/sources_1/bd/sys/hdl/sys_wrapper.v"]
set_property top sys_wrapper [current_fileset]

update_compile_order -fileset sources_1

launch_runs synth_1 -jobs $n_cores
wait_on_run synth_1

launch_runs impl_1 -jobs $n_cores
wait_on_run impl_1

launch_runs impl_1 -to_step write_bitstream -jobs $n_cores
wait_on_run impl_1 

# Reportes para el informe: potencia y recursos (agregado)
open_run impl_1
report_power -file ${export_dir}/power_fir.rpt
report_utilization -file ${export_dir}/utilization_fir.rpt
write_hw_platform -fixed -include_bit -force -file ${export_dir}/sys_wrapper.xsa

puts "Vivado project is ready"
