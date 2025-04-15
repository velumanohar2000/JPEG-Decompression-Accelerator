###############################
#                             #
# Create By Yufan Yue 2023.10 #
#                             #
###############################


set COURSE_NAME $::env(MK_COURSE_NAME)
puts "\[$COURSE_NAME\] Running script [info script]\n"

set PDK_PATH $::env(SAED32_PATH)
puts "PDK path at $PDK_PATH"

set DESIGN_NAME $::env(MK_DESIGN_NAME)
set RTL_SOURCE_FILES  [glob -nocomplain src/*.v	src/*.sv src/*.vh src/*.svh]
set NETLIST_FILES ""
set DESIGN_DEFINES ""
set DESIGN_PATH          "[pwd]"
set REPORTS_DIR "${DESIGN_PATH}/reports"
set RESULTS_DIR "${DESIGN_PATH}/results"
set CONSTRAINTS_FILE "${DESIGN_PATH}/scripts/constraints.tcl"
set USE_NUM_CORES $::env(MK_USE_NUM_CORES)
set ADDITIONAL_SEARCH_PATH ""
set MEM_SUFFIX $::env(MK_MEM_SUFFIX)

##########################################################################################
# Library Setup Variables
##########################################################################################
#  Target technology logical libraries

# set MAX_LIBRARY_SET               [glob -nocomplain "${PDK_PATH}/lib/stdcell_rvt/db_ccs/saed32rvt_ss0p95v125c.db"]
set TYP_LIBRARY_SET               [glob -nocomplain "${PDK_PATH}/lib/stdcell_rvt/db_ccs/saed32rvt_tt1p05v25c.db"]
# set MIN_LIBRARY_SET               [glob -nocomplain "${PDK_PATH}/lib/stdcell_rvt/db_ccs/saed32rvt_ff1p16vn40c.db"]

set corner_case "typ"
set TARGET_LIBRARY_FILES        ${TYP_LIBRARY_SET}
set ADDITIONAL_LINK_LIB_FILES   "[glob -nocomplain ${DESIGN_PATH}/memory/db/*_${MEM_SUFFIX}_ccs.db]
                                   [glob -nocomplain ${DESIGN_PATH}/blocks/*/export/*.db]"

set_app_var sh_new_variable_message false
#################################################################################
# Design Compiler Setup Variables
#################################################################################
set_host_options -max_cores [expr min(6, ${USE_NUM_CORES})]

if { ! [file exists $REPORTS_DIR] } { file mkdir ${REPORTS_DIR} }
if { ! [file exists $RESULTS_DIR] } { file mkdir ${RESULTS_DIR} }

#################################################################################
# Search Path Setup
#
# Set up the search path to find the libraries and design files.
#################################################################################

set_app_var search_path ". ${ADDITIONAL_SEARCH_PATH} $search_path"

#################################################################################
# Library Setup
#
# This section is designed to work with the settings from common_setup.tcl
# without any additional modification.
#################################################################################

set_app_var target_library ${TARGET_LIBRARY_FILES}
set_app_var synthetic_library dw_foundation.sldb
set_app_var link_library "* $target_library $ADDITIONAL_LINK_LIB_FILES $synthetic_library"


check_library > ${REPORTS_DIR}/${DESIGN_NAME}.check_library.rpt



#################################################################################
# Read in the RTL Design
#
# Read in the RTL source files or read in the elaborated design (.ddc).
#################################################################################
if { ! [file exists ${DESIGN_NAME}_dclib] } { file mkdir ${DESIGN_NAME}_dclib }
define_design_lib WORK -path ${DESIGN_PATH}/${DESIGN_NAME}_dclib

if { [llength $NETLIST_FILES] > 0} { read_verilog -netlist $NETLIST_FILES }
if { ![analyze -define ${DESIGN_DEFINES} -f sverilog $RTL_SOURCE_FILES] } { exit 1 }
elaborate ${DESIGN_NAME}

check_design -multiple_designs

current_design ${DESIGN_NAME}
link

puts "\[$COURSE_NAME\] Sourcing script file [which ${CONSTRAINTS_FILE}]\n"
source -echo -verbose ${CONSTRAINTS_FILE}

redirect -tee ${REPORTS_DIR}/${DESIGN_NAME}.check_timing.rpt {check_timing}

#################################################################################
# Create Default Path Groups
#
# Separating these paths can help improve optimization.
# Remove these path group settings if user path groups have already been defined.
#################################################################################

set ports_clock_root [filter_collection [get_attribute [get_clocks] sources] object_class==port]
group_path -name REGOUT -to [all_outputs]
group_path -name REGIN -from [remove_from_collection [all_inputs] ${ports_clock_root}]
group_path -name FEEDTHROUGH -from [remove_from_collection [all_inputs] ${ports_clock_root}] -to [all_outputs]

#################################################################################
# Apply Additional Optimization Constraints
#################################################################################
# Replace special characters with non-special ones before writing out the synthesized netlist.
# For example \bus[5] -> bus_5_
set_app_var verilogout_no_tri true

# Prevent assignment statements in the Verilog netlist.
set_fix_multiple_port_nets -all -buffer_constants

#################################################################################
# Check for Design Problems
#################################################################################

check_design -summary
check_design > ${REPORTS_DIR}/${DESIGN_NAME}.check_design.rpt

set_app_var compile_ultra_ungroup_dw true
ungroup -all -flatten
# append compile_ultra_options " -no_autoungroup"
# puts "Information: Starting compile_ultra with the following flags: $compile_ultra_options"
# compile_ultra $compile_ultra_options
compile_ultra
optimize_netlist -area

#################################################################################
# Write Out Final Design and Reports
#
#        .ddc:   Recommended binary format used for subsequent Design Compiler sessions
#        .v  :   Verilog netlist for ASCII flow (Formality, PrimeTime, VCS)
#       .spef:   Topographical mode parasitics for PrimeTime
#        .sdf:   SDF backannotated topographical mode timing for PrimeTime
#        .sdc:   SDC constraints for ASCII flow
#
#################################################################################

# If this will be a sub-block in a hierarchical design, uniquify the block
# unique names to avoid name collisions when integrating the design at the
# toplevel
set uniquify_naming_style "${DESIGN_NAME}_%s_%d"
uniquify -force

# Use naming rules to preserve structs

define_name_rules verilog -preserve_struct_ports -case_insensitive
report_names -rules verilog > ${REPORTS_DIR}/${DESIGN_NAME}.name_change.rpt
change_names -rules verilog -hierarchy

#################################################################################
# Write out Design
#################################################################################
write -format verilog -hierarchy -output ${RESULTS_DIR}/${DESIGN_NAME}.mapped.v
write -format svsim              -output ${RESULTS_DIR}/${DESIGN_NAME}.mapped.svsim
write -format ddc     -hierarchy -output ${RESULTS_DIR}/${DESIGN_NAME}.mapped.ddc

#################################################################################
# Write out Design Data
#################################################################################
# Write SDF backannotation data from Design Compiler Topographical placement for static timing analysis
write_parasitics -output ${RESULTS_DIR}/${DESIGN_NAME}.mapped.spef
write_sdf ${RESULTS_DIR}/${DESIGN_NAME}.mapped.sdf

# Do not write out net RC info into SDC
set_app_var write_sdc_output_lumped_net_capacitance false
set_app_var write_sdc_output_net_resistance false
write_sdc -nosplit ${RESULTS_DIR}/${DESIGN_NAME}.mapped.sdc

#################################################################################
# Generate Final Reports
#################################################################################

redirect -tee ${REPORTS_DIR}/${DESIGN_NAME}.units.rpt {report_units}
redirect -tee ${REPORTS_DIR}/${DESIGN_NAME}.fanout.rpt {report_net_fanout -high_fanout}
redirect -tee ${REPORTS_DIR}/${DESIGN_NAME}.qor.rpt {report_qor}

report_timing -transition_time -nets -attributes -nosplit > ${REPORTS_DIR}/${DESIGN_NAME}.timing.rpt
report_clock_timing -type summary > ${REPORTS_DIR}/${DESIGN_NAME}.clock_timing.rpt
report_timing -delay_type max -path_type full_clock -max_paths 30 -transition_time -nets -attributes -nosplit > ${REPORTS_DIR}/${DESIGN_NAME}.max_timing.rpt
report_timing -delay_type min -path_type full_clock -max_paths 30 -transition_time -nets -attributes -nosplit > ${REPORTS_DIR}/${DESIGN_NAME}.min_timing.rpt
report_area -nosplit > ${REPORTS_DIR}/${DESIGN_NAME}.area.rpt
report_power -nosplit > ${REPORTS_DIR}/${DESIGN_NAME}.power.rpt

puts "\[$COURSE_NAME\] Completed script [info script]\n"
exit
