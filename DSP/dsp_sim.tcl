# Get the testbench name from the command-line argument
set tb_name [lindex $argv 0]

if {$tb_name == ""} {
    puts "Error: No testbench specified! Usage: vivado -mode batch -source dsp_sim.tcl -tclargs <testbench_name>"
    exit
}

start_gui

# Set project parameters
set ProjectName $tb_name
set PartDev xc7z020clg400-1
set TclPath [file dirname [file normalize [info script]]]
set ProjectPath $TclPath/sim
set RootDIR [file dirname $TclPath]

# Create Vivado project
create_project $ProjectName $ProjectPath -part $PartDev

add_files -fileset sim_1 -norecurse [list "$RootDIR/common/tb_util.vh"]
# Define testbench sources and waveform files based on the selected testbench
if {$tb_name == "fir"} {

    #########################################################
    #               FIR Compiler                            #
    #########################################################

    create_ip -name fir_compiler -vendor xilinx.com -library ip -version 7.2 -module_name fir_bandpass
    set_property -dict [list CONFIG.Component_Name {fir_bandpass} CONFIG.CoefficientSource {COE_File} CONFIG.Coefficient_File $RootDIR/ip_fir/coe/BPF.coe CONFIG.Sample_Frequency {100} CONFIG.DATA_Has_TLAST {Packet_Framing} CONFIG.M_DATA_Has_TREADY {true} CONFIG.Clock_Frequency {100} CONFIG.Has_ARESETn {true} CONFIG.Coefficient_Sets {1} CONFIG.Clock_Frequency {100} CONFIG.Coefficient_Sign {Signed} CONFIG.Quantization {Integer_Coefficients} CONFIG.Coefficient_Width {16} CONFIG.Coefficient_Fractional_Bits {0} CONFIG.Coefficient_Structure {Inferred} CONFIG.Data_Width {16} CONFIG.Output_Width {32} CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} CONFIG.ColumnConfig {16}] [get_ips fir_bandpass]
    generate_target {instantiation_template} [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/fir_bandpass/fir_bandpass.xci"]]
    generate_target all [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/fir_bandpass/fir_bandpass.xci"]]

    create_ip -name fir_compiler -vendor xilinx.com -library ip -version 7.2 -module_name fir_hilbert
    set_property -dict [list \
      CONFIG.Clock_Frequency {100} \
      CONFIG.CoefficientSource {COE_File} \
      CONFIG.Coefficient_File $RootDIR/ip_fir/coe/hilbert_0.coe \
      CONFIG.Coefficient_Fractional_Bits {0} \
      CONFIG.Coefficient_Sets {1} \
      CONFIG.Coefficient_Sign {Signed} \
      CONFIG.Coefficient_Structure {Hilbert} \
      CONFIG.Coefficient_Width {16} \
      CONFIG.DATA_Has_TLAST {Packet_Framing} \
      CONFIG.Data_Width {16} \
      CONFIG.Decimation_Rate {1} \
      CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
      CONFIG.Filter_Type {Hilbert} \
      CONFIG.Has_ARESETn {true} \
      CONFIG.Interpolation_Rate {1} \
      CONFIG.M_DATA_Has_TREADY {true} \
      CONFIG.Number_Channels {1} \
      CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
      CONFIG.Output_Width {16} \
      CONFIG.Quantization {Integer_Coefficients} \
      CONFIG.RateSpecification {Frequency_Specification} \
      CONFIG.Sample_Frequency {100} \
      CONFIG.Zero_Pack_Factor {1} \
    ] [get_ips fir_hilbert]
    generate_target {instantiation_template} [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/fir_hilbert/fir_hilbert.xci"]]
    generate_target all [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/fir_hilbert/fir_hilbert.xci"]]

    create_ip -name fir_compiler -vendor xilinx.com -library ip -version 7.2 -module_name fir_decim
    set_property -dict [list CONFIG.Component_Name {fir_decim} CONFIG.CoefficientSource {COE_File} CONFIG.Coefficient_File $RootDIR/ip_fir/coe/LPF_dec.coe CONFIG.Filter_Type {Decimation} CONFIG.M_DATA_Has_TREADY {true} CONFIG.DATA_Has_TLAST {Packet_Framing} CONFIG.Decimation_Rate {4} CONFIG.Sample_Frequency {100} CONFIG.Clock_Frequency {100} CONFIG.Has_ARESETn {true} CONFIG.Coefficient_Sets {1} CONFIG.Interpolation_Rate {1} CONFIG.Zero_Pack_Factor {1} CONFIG.Number_Channels {1} CONFIG.RateSpecification {Frequency_Specification} CONFIG.Coefficient_Sign {Signed} CONFIG.Quantization {Integer_Coefficients} CONFIG.Coefficient_Width {16} CONFIG.Coefficient_Fractional_Bits {0} CONFIG.Coefficient_Structure {Inferred} CONFIG.Data_Width {16} CONFIG.Output_Width {32} CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} CONFIG.ColumnConfig {4}] [get_ips fir_decim]
    generate_target {instantiation_template} [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/fir_decim/fir_decim.xci"]]
    generate_target all [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/fir_decim/fir_decim.xci"]]

    create_ip -name fir_compiler -vendor xilinx.com -library ip -version 7.2 -module_name fir_inter
    set_property -dict [list CONFIG.Component_Name {fir_inter} CONFIG.CoefficientSource {COE_File} CONFIG.Coefficient_File $RootDIR/ip_fir/coe/LPF_int.coe CONFIG.Filter_Type {Interpolation} CONFIG.M_DATA_Has_TREADY {true} CONFIG.DATA_Has_TLAST {Packet_Framing} CONFIG.Interpolation_Rate {4} CONFIG.Sample_Frequency {25} CONFIG.Clock_Frequency {100} CONFIG.Has_ARESETn {true} CONFIG.Coefficient_Sets {1} CONFIG.Decimation_Rate {1} CONFIG.Zero_Pack_Factor {1} CONFIG.Number_Channels {1} CONFIG.RateSpecification {Frequency_Specification} CONFIG.Clock_Frequency {100} CONFIG.Coefficient_Sign {Signed} CONFIG.Quantization {Integer_Coefficients} CONFIG.Coefficient_Width {16} CONFIG.Coefficient_Fractional_Bits {0} CONFIG.Coefficient_Structure {Inferred} CONFIG.Data_Width {16} CONFIG.Output_Width {30} CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} CONFIG.ColumnConfig {4}] [get_ips fir_inter]
    generate_target {instantiation_template} [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/fir_inter/fir_inter.xci"]]
    generate_target all [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/fir_inter/fir_inter.xci"]]

    set_property SOURCE_SET sources_1 [get_filesets sim_1]
    add_files -fileset sim_1 -norecurse [list "$RootDIR/ip_fir/tb/fir_compiler_tb.v"]
    add_files -fileset sim_1 -norecurse [list "$RootDIR/ip_fir/tb/fir_compiler_tb_behav.wcfg"]
    set sim_wcfg "$RootDIR/ip_fir/tb/fir_compiler_tb_behav.wcfg"
    update_compile_order -fileset sources_1
    set_property top fir_compiler_tb [get_filesets sim_1]
} elseif {$tb_name == "dds"} {

    #########################################################
    #               DDS Compiler                            #
    #########################################################

    create_ip -name dds_compiler -vendor xilinx.com -library ip -version 6.0 -module_name dds_compiler_0
    set_property -dict [list \
	  CONFIG.DATA_Has_TLAST {Not_Required} \
	  CONFIG.Has_ARESETn {true} \
	  CONFIG.Has_Phase_Out {false} \
	  CONFIG.Has_TREADY {true} \
	  CONFIG.Latency {13} \
	  CONFIG.M_DATA_Has_TUSER {Not_Required} \
	  CONFIG.Noise_Shaping {None} \
	  CONFIG.OUTPUT_FORM {Twos_Complement} \
	  CONFIG.Output_Frequency1 {0} \
	  CONFIG.Output_Width {16} \
	  CONFIG.PINC1 {0} \
	  CONFIG.Parameter_Entry {Hardware_Parameters} \
	  CONFIG.Phase_Increment {Streaming} \
	  CONFIG.Phase_Width {16} \
	  CONFIG.S_PHASE_Has_TUSER {Not_Required} \
	] [get_ips dds_compiler_0]
    update_compile_order -fileset sources_1
    generate_target all [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/dds_compiler_0/dds_compiler_0.xci"]]

    create_ip -name dds_compiler -vendor xilinx.com -library ip -version 6.0 -module_name dds_compiler_1
    set_property -dict [list \
	  CONFIG.DATA_Has_TLAST {Not_Required} \
	  CONFIG.Has_ARESETn {true} \
	  CONFIG.Has_Phase_Out {false} \
	  CONFIG.Has_TREADY {true} \
	  CONFIG.Latency {8} \
	  CONFIG.M_DATA_Has_TUSER {Not_Required} \
	  CONFIG.Noise_Shaping {None} \
	  CONFIG.OUTPUT_FORM {Twos_Complement} \
	  CONFIG.Output_Frequency1 {0} \
	  CONFIG.Output_Width {16} \
	  CONFIG.PINC1 {0} \
	  CONFIG.Parameter_Entry {Hardware_Parameters} \
	  CONFIG.PartsPresent {SIN_COS_LUT_only} \
	  CONFIG.Phase_Width {16} \
	  CONFIG.S_PHASE_Has_TUSER {Not_Required} \
	] [get_ips dds_compiler_1]
    update_compile_order -fileset sources_1
    generate_target all [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/dds_compiler_1/dds_compiler_1.xci"]]

    set_property SOURCE_SET sources_1 [get_filesets sim_1]
    add_files -fileset sim_1 -norecurse [list "$RootDIR/common/dds_axi_wrapper.v"]
    add_files -fileset sim_1 -norecurse [list "$RootDIR/ip_dds/tb/dds_compiler_tb.v"]
    add_files -fileset sim_1 -norecurse [list "$RootDIR/ip_dds/tb/dds_compiler_tb_behav.wcfg"]
    set sim_wcfg "$RootDIR/ip_dds/tb/dds_compiler_tb_behav.wcfg"
    update_compile_order -fileset sources_1
    set_property top dds_compiler_tb [get_filesets sim_1]
} elseif {$tb_name == "cic"} {

    #########################################################
    #               CIC Compiler                            #
    #########################################################

    create_ip -name cic_compiler -vendor xilinx.com -library ip -version 4.0 -module_name cic_decim
    set_property -dict [list \
      CONFIG.Clock_Frequency {100} \
      CONFIG.Filter_Type {Decimation} \
      CONFIG.Fixed_Or_Initial_Rate {16} \
      CONFIG.HAS_ARESETN {true} \
      CONFIG.Input_Data_Width {16} \
      CONFIG.Input_Sample_Frequency {100} \
      CONFIG.Maximum_Rate {16} \
      CONFIG.Minimum_Rate {16} \
      CONFIG.Output_Data_Width {16} \
      CONFIG.Quantization {Truncation} \
      CONFIG.SamplePeriod {1} \
    ] [get_ips cic_decim]
    generate_target {instantiation_template} [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/cic_decim/cic_decim.xci"]]
    generate_target all [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/cic_decim/cic_decim.xci"]]

    create_ip -name cic_compiler -vendor xilinx.com -library ip -version 4.0 -module_name cic_inter
    set_property -dict [list \
      CONFIG.Clock_Frequency {100} \
      CONFIG.Fixed_Or_Initial_Rate {16} \
      CONFIG.HAS_ARESETN {true} \
      CONFIG.Input_Data_Width {16} \
      CONFIG.Input_Sample_Frequency {6.25} \
      CONFIG.Maximum_Rate {16} \
      CONFIG.Minimum_Rate {16} \
      CONFIG.Output_Data_Width {16} \
      CONFIG.Quantization {Truncation} \
      CONFIG.SamplePeriod {16} \
    ] [get_ips cic_inter]
    generate_target {instantiation_template} [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/cic_inter/cic_inter.xci"]]
    generate_target all [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/cic_inter/cic_inter.xci"]]
    set_property SOURCE_SET sources_1 [get_filesets sim_1]
    add_files -fileset sim_1 -norecurse [list "$RootDIR/ip_cic/tb/cic_compiler_tb.v"]
    add_files -fileset sim_1 -norecurse [list "$RootDIR/ip_cic/tb/cic_compiler_tb_behav.wcfg"]
    set sim_wcfg "$RootDIR/ip_cic/tb/cic_compiler_tb_behav.wcfg"
    update_compile_order -fileset sources_1
    set_property top cic_compiler_tb [get_filesets sim_1]
} elseif {$tb_name == "xfft"} {

    #########################################################
    #               FFT Compiler                            #
    #########################################################

    create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name xfft_0
    set_property -dict [list CONFIG.Component_Name {xfft_0} CONFIG.transform_length {2048} CONFIG.target_clock_frequency {100} CONFIG.implementation_options {pipelined_streaming_io} CONFIG.target_data_throughput {100} CONFIG.run_time_configurable_transform_length {true} CONFIG.input_width {16} CONFIG.phase_factor_width {24} CONFIG.aresetn {true} CONFIG.output_ordering {natural_order} CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {4}] [get_ips xfft_0]
    generate_target {instantiation_template} [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/xfft_0/xfft_0.xci"]]
    generate_target all [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/xfft_0/xfft_0.xci"]]

    create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name xfft_1
    set_property -dict [list CONFIG.Component_Name {xfft_1} CONFIG.transform_length {2048} CONFIG.target_clock_frequency {100} CONFIG.implementation_options {pipelined_streaming_io} CONFIG.target_data_throughput {100} CONFIG.run_time_configurable_transform_length {true} CONFIG.input_width {16} CONFIG.phase_factor_width {24} CONFIG.aresetn {true} CONFIG.output_ordering {natural_order} CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {4}] [get_ips xfft_1]
    generate_target {instantiation_template} [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/xfft_1/xfft_1.xci"]]
    generate_target all [get_files [list "$ProjectPath/$ProjectName.srcs/sources_1/ip/xfft_1/xfft_1.xci"]]

    set_property SOURCE_SET sources_1 [get_filesets sim_1]
    add_files -fileset sim_1 -norecurse [list "$RootDIR/ip_xfft/tb/xfft_tb.v"]
    add_files -fileset sim_1 -norecurse [list "$RootDIR/ip_xfft/tb/xfft_tb_behav.wcfg"]
    set sim_wcfg "$RootDIR/ip_xfft/tb/xfft_tb_behav.wcfg"
    update_compile_order -fileset sources_1
    set_property top xfft_tb [get_filesets sim_1]
} else {
    puts "Error: Invalid testbench specified!"
    exit
}




# Launch simulation
launch_simulation

# Load waveform configuration if available
# if {[file exists $sim_wcfg]} {
#     open_wave_config $sim_wcfg
#     puts "Waveform configuration loaded: $sim_wcfg"
# } else {
#     puts "Warning: Waveform configuration not found!"
# }

# Run simulation for 1000us (adjust as needed)
run -all

# Save waveform database for future viewing
# save_wave_config "$RootDIR/build/fir_compiler_tb_behav.wcfg"

# Exit Vivado
# exit
