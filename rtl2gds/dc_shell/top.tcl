source ../../../rtl2gds/dc_shell/proc_time.tcl
proc_time STARTED_DC

#
# dc_shell script based on DC-ICPRO
#

# dc_shell_setup.tcl
source ../../../rtl2gds/dc_shell/top-setup.tcl

#########################################################################
# Setup Variables
#########################################################################
#set alib_library_analysis_path $ICPRO_DIR/tmp/dc_shell    ;    # Point to a central cache of analyzed libraries

set clock_gating_enabled 1

# make design read-in a bit more verbose...
#set hdlin_keep_signal_name user
set hdlin_report_floating_net_to_ground true

# Enables shortening of names as the concatenation of interface
# signals results in names > 1000s of characters
set hdlin_shorten_long_module_name true
# Specify minimum number of characters. Default: 256
set hdlin_module_name_limit 100

set DCT_IGNORED_ROUTING_LAYERS     ""     ;    # Enter the same ignored routing
                                               # layers as P&R
set REPORTS_DIR                 "$BRICK_RESULTS/reports"
set RESULTS_DIR                 "$BRICK_RESULTS/results"
set tool                        "dc"

set target_library $TARGET_LIBRARY_FILES
set synthetic_library dw_foundation.sldb
set link_library "* $target_library $ADDITIONAL_LINK_LIB_FILES $synthetic_library"

set search_path [concat  $search_path $ADDITIONAL_SEARCH_PATHS]
# add default icpro search path for global verilog sources
set user_search_path [list \
    "../../../../s2pp/rtl/include/" \
    "../../../units/top/source/hdl/include" \
]
set search_path [concat  $search_path $user_search_path]

# Set min libraries if they exist
foreach {max_library min_library} $MIN_LIBRARY_FILES {
	set_min_library $max_library -min_version $min_library
}

## set multicore usage
set_host_options -max_cores 6


echo "Information: Starting Synopsys Design Compiler synthesis run ... "
echo "Information: Filtered command line output. For details see 'logfiles/compile.log'! "

#################################################################################
# Setup for Formality verification
#################################################################################
set_svf $RESULTS_DIR/$DESIGN_NAME.svf


#################################################################################
# Read in the RTL Design
#
# Read in the RTL source files or read in the elaborated design (DDC).
#################################################################################
define_design_lib WORK -path ./worklib

# sourcelist
# the following file includes all RTL-Sources as ordered lists
source [getenv "DC_SHELL_SOURCE_TCL"]


echo "Information: Elaborating top-level '$DESIGN_NAME' ... "
elaborate $DESIGN_NAME

write -format ddc -hierarchy -output $RESULTS_DIR/${DESIGN_NAME}.elab.ddc

list_designs -show_file > $REPORTS_DIR/$DESIGN_NAME.elab.list_designs
report_reference -hier > $REPORTS_DIR/$DESIGN_NAME.elab.report_reference

current_design ${DESIGN_NAME}
echo "Information: Linking design ... "
link > $REPORTS_DIR/$DESIGN_NAME.link


############################################################################
# Apply Logical Design Constraints
############################################################################
echo "Information: Reading design constraints ... "
set constraints_file "../../../rtl2gds/constraints/top_hicdinn.sdc"
if {$constraints_file != 0} {
    source -echo -verbose ${constraints_file}
}

# Enable area optimization in all flows
#set_max_area 0

set_fix_multiple_port_nets -all -buffer_constants

############################################################################
# Create Default Path Groups
# Remove these path group settings if user path groups already defined
############################################################################
set ports_clock_root [get_ports [all_fanout -flat -clock_tree -level 0]]
group_path -name REGOUT -to [all_outputs]
group_path -name REGIN -from [remove_from_collection [all_inputs] $ports_clock_root]
group_path -name FEEDTHROUGH -from [remove_from_collection [all_inputs] $ports_clock_root] -to [all_outputs]

#################################################################################
# Power Optimization Section
#################################################################################

if ($clock_gating_enabled) {
	set_clock_gating_style -positive_edge_logic integrated -negative_edge_logic integrated -control_point before -minimum_bitwidth 4 -max_fanout 48
}

#############################################################################
# Apply Power Optimization Constraints
#############################################################################
# Include a SAIF file, if possible, for power optimization
# read_saif -auto_map_names -input ${DESIGN_NAME}.saif -instance < DESIGN_INSTANCE > -verbose
if {[shell_is_in_topographical_mode]} {
    # Enable power prediction for this DC-T session using clock tree estimation.
    set_power_prediction true
}

# set_max_leakage_power 0
# set_max_dynamic_power 0
#set_max_total_power 0


#
# check design
#
echo "Information: Checking design (see '$REPORTS_DIR/$DESIGN_NAME.check_design'). "

check_design > $REPORTS_DIR/$DESIGN_NAME.check_design

#############################
# Apply physical constraints
#############################

if {[shell_is_in_topographical_mode]} {
    set mw_logic1_net $MW_POWER_NET
    set mw_logic0_net $MW_GROUND_NET
    set mw_reference_library $MW_REFERENCE_LIB_DIRS
    set mw_design_library ${DESIGN_NAME}_LIB
    set mw_site_name_mapping [list CORE unit Core unit core unit]

    create_mw_lib     -technology $TECH_FILE  -mw_reference_library $mw_reference_library   $mw_design_library
    open_mw_lib       $mw_design_library
    set_tlu_plus_files     -max_tluplus $TLUPLUS_MAX_FILE -min_tluplus $TLUPLUS_MIN_FILE -tech2itf_map $MAP_FILE
    check_tlu_plus_files

    check_library

	#set_preferred_routing_direction -layer M1 -dir horizontal
	#set_preferred_routing_direction -layer M2 -dir vertical
	#set_preferred_routing_direction -layer M3 -dir horizontal
	#set_preferred_routing_direction -layer M4 -dir vertical
	#set_preferred_routing_direction -layer M5 -dir horizontal
	#set_preferred_routing_direction -layer M6 -dir vertical
	#set_preferred_routing_direction -layer M7 -dir horizontal
	#set_preferred_routing_direction -layer M8 -dir vertical
	#set_preferred_routing_direction -layer M9 -dir horizontal
	#set_preferred_routing_direction -layer AP -dir vertical

    # Specify ignored layers for routing to improve correlation
    # Use the same ignored layers that will be used during place and route
    if { $DCT_IGNORED_ROUTING_LAYERS != ""} {
        set_ignored_layers $DCT_IGNORED_ROUTING_LAYERS
    }
    report_ignored_layers

    # Apply Physical Design Constraints
    # set_fuzzy_query_options -hierarchical_separators {/ _ .}     # -bus_name_notations {[] __ ()}     # -class {cell pin port net}     # -show
    extract_physical_constraints -verbose $PROJECT_ROOT/hicann-dls/units/top_miniasic_0/rtl2gds/dc_shell/$DESIGN_NAME.def
    # OR
    # source -echo -verbose ${DESIGN_NAME}.physical_constraints.tcl

#	create_bounds \
#		-name "capmem_guide" \
#		-coordinate {600 300 1500 340} \
#		{top/capmem/glue}
#
#	create_bounds \
#		-name "slice1_guide" \
#		-coordinate {1250 1350 1520 1670} \
#		{top/ppu/pu/gen_fub_vector.fub_vector/gen_slice[1].slice}
#
#	create_bounds \
#		-name "slice0_guide" \
#		-coordinate {700 1350 1250 1670} \
#		{top/ppu/pu/gen_fub_vector.fub_vector/gen_slice[0].slice}
#
#	create_bounds \
#		-name "ppu_frontend_guide" \
#		-coordinate {420 1150 600 1400} \
#		{top/ppu/pu/frontend}
#
#	create_bounds \
#		-name "neurons_guide" \
#		-coordinate {680 716 1560 1010} \
#		{top/neurons}
#
#	create_bounds \
#		-name "serdes_guide" \
#		-coordinate {400 450 650 750} \
#		{top/serdes/distributor}
}

#########################################################
# Apply Additional Optimization Constraints
#########################################################

# Prevent assignment statements in the Verilog netlist.
set verilogout_no_tri true

# Uniquify design
uniquify -dont_skip_empty_designs

#########################################################
# Compile the Design
#
# Recommended Options:
#
# -scan
# -retime
# -timing_high_effort_script
# -area_high_effort_script
#
#########################################################
echo "Information: Starting top down compilation (compile_ultra) ... "

#
# set to true to enable
# enable scan insertion during compilation
#
if { 0 } {
    # compile design using scan ffs
    compile_ultra -scan

    #
    # modify insert_scan_script template for your DFT requirements
    #
    set insert_scan_script "./scripts/${DESIGN_NAME}.insert_scan.tcl"
    if { ! [file exists $insert_scan_script] } {
      echo "ERROR: Insert scan script '$insert_scan_script' not found. "
      exit 1
    } else {
      source $insert_scan_script
    }
} else {
    # compilation without scan insertion
	# added option to keep hierarchy

#    set_optimize_registers true -designs {Valu_simd_mult_add*} -check_design -print_critical_loop -justification_effort high -delay_threshold 1.8

    compile_ultra -retime
    report_timing -max_paths 10    > $REPORTS_DIR/${DESIGN_NAME}_1stpass.report_timing
    # does not give improvement anymore
	#optimize_registers -print_critical_loop -check_design -only_attributed_designs
	#report_timing -max_paths 10    > $REPORTS_DIR/${DESIGN_NAME}_2ndpass.report_timing
    compile_ultra -incremental -gate_clock
}

echo "Information: Finished top down compilation. "

#################################################################################
# Write Out Final Design
#################################################################################
remove_unconnected_ports [find cell -hierarchy *]
change_names -rules verilog -hierarchy

echo "Information: Writing results to '$RESULTS_DIR' ... "
write -format ddc -hierarchy -output $RESULTS_DIR/${DESIGN_NAME}.ddc
write -f verilog -hier -output $RESULTS_DIR/${DESIGN_NAME}.v

if {[shell_is_in_topographical_mode]} {
	# write_milkyway uses: mw_logic1_net, mw_logic0_net and mw_design_library variables from dc_setup.tcl
	#write_milkyway -overwrite -output ${DESIGN_NAME}_DCT

	write_physical_constraints -output ${RESULTS_DIR}/${DESIGN_NAME}.mapped.physical_constraints.tcl

	# Do not write out net RC info into SDC
	set write_sdc_output_lumped_net_capacitance false
	set write_sdc_output_net_resistance false
}

# Write SDF backannotation data
write_sdf $RESULTS_DIR/${DESIGN_NAME}.sdf

echo "Information: Writing reports to '$REPORTS_DIR' ... "
#
# check timing/contraints
#
report_design              > $REPORTS_DIR/$DESIGN_NAME.report_design
check_timing               > $REPORTS_DIR/$DESIGN_NAME.check_timing
report_port                > $REPORTS_DIR/$DESIGN_NAME.report_port
report_timing_requirements > $REPORTS_DIR/$DESIGN_NAME.report_timing_requirements
report_clock               > $REPORTS_DIR/$DESIGN_NAME.report_clock
report_clock_gating -gating_elements > $REPORTS_DIR/$DESIGN_NAME.report_clock_gating
report_constraint          > $REPORTS_DIR/$DESIGN_NAME.report_constraint

set timing_bidirectional_pin_max_transition_checks "driver"
report_constraint -max_transition  -all_vio       >> $REPORTS_DIR/$DESIGN_NAME.report_constraint

set timing_bidirectional_pin_max_transition_checks "load"
report_constraint -max_transition  -all_vio       >> $REPORTS_DIR/$DESIGN_NAME.report_constraint

report_constraints -all_violators > ${REPORTS_DIR}/${DESIGN_NAME}.report_constraints_all_violators

#
# report design
#
report_timing -max_paths 10    > $REPORTS_DIR/$DESIGN_NAME.report_timing
report_area -hier              > $REPORTS_DIR/$DESIGN_NAME.report_area
report_power                   > $REPORTS_DIR/$DESIGN_NAME.report_power
report_fsm                     > $REPORTS_DIR/$DESIGN_NAME.report_fsm

check_design                   > $REPORTS_DIR/$DESIGN_NAME.check_design_final

#remove_ideal_network [get_pins PD_CLK/C]
#remove_ideal_network [get_ports resetb]
#remove_ideal_network [get_pins top_clk_reset_reset_reg/Q]
#remove_ideal_network [filter_collection [all_connected [get_nets top_ppu/core_reset]] "@pin_direction==out"]
#remove_ideal_network [get_pins -hier *clock_gate_latch/Q]
#remove_ideal_network [get_pins -hier *scale_reg_0_/Q]
#remove_ideal_network [get_pins -hier *scale_reg_1_/Q]
#remove_ideal_network [get_pins -hier *scale_reg_2_/Q]
#remove_ideal_network [get_pins -hier *scale_reg_3_/Q]
#remove_ideal_network [get_pins -hier *scale_reg_4_/Q]
#remove_ideal_network [get_pins -hier *scale_reg_5_/Q]
#remove_ideal_network [get_pins -hier *scaled_clk_reg/Q]

write_sdc -nosplit $RESULTS_DIR/${DESIGN_NAME}.sdc

proc_time ENDED_DC
exit
