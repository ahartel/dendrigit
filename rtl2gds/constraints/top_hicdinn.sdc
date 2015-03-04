set_operating_conditions -max WCCOM -max_lib tcbn65lpwc -min BCCOM -min_lib tcbn65lpbc

# Main 100 MHz clock
create_clock -period 10.0 -waveform { 0 5.0 } [get_ports clk] -name CLK

#set_input_delay 0.0 -clock [get_clocks CLK] [get_ports dendrite.vmem]

### NOT USED ####

#set_ideal_network [get_pins PD_CLK/C]
## ppu's clock divider
## according to synopsys docu (doc ID 021897), the ideal network property is not propagated through the gating cell
## because not all its inputs are connected to ideal networks (that's how set_ideal_network propagation works)
## solution is to set_ideal_network on the output of the gating cell
#set_ideal_network [get_pins "top/ppu/clock_gate/latch/Q"]
#
## dummy clock to generate output timing of neuron fireout lines:
#create_clock -period 10.0 -waveform { 0 5.0 } [get_pins top/neurons/neurons_i/dummy_clk] -name DUMMY_CLK
#set_false_path -from DUMMY_CLK -to CLK
#set_false_path -from CLK -to DUMMY_CLK
#
## disalble recovery checks on instruction SRAM between read-and write port (write-read still active!)
## port A: read-only port B: write-only
#set_false_path -from [get_pins top/ppu/cache_store/macro/CLKA] -to [get_pins top/ppu/cache_store/macro/CLKB]
#
## reset tree
#set_ideal_network [get_ports resetb]
##set_ideal_network [get_pins top/clk_reset/reset_reg/Q]
##set_ideal_network [filter_collection [all_connected [get_nets top/ppu/core_reset]] "@pin_direction==out"]
#
#set_false_path -from [get_ports resetb]
#set_false_path -from [get_ports serdes_loopback]
#
## identify and preserve manually instantiated clock gating cells
#identify_clock_gating
#set_preserve_clock_gate top/ppu/clock_gate/latch
#
## make checks a little more conservative
#set_clock_gating_check -low -setup 0.175 -hold 0.2 CLK
##set_clock_gating_check -low -setup 0.2 -hold 0.2 [filter_collection [all_connected [get_nets top/ppu/clock_gate/clk_en]] "@pin_direction==in"]
#
##remove_clock_gating_check [get_pins "top/capmem/glue/pausemux3_i/I*"]
##remove_clock_gating_check [get_pins "top/capmem/glue/pausemux5_i/I*"]
##remove_clock_gating_check [get_pins "top/serdes/ioclkmux_i/I*"]
##remove_clock_gating_check [get_cells "top/serdes/scaled_clk_reg"]
#
#
## disable setup/hold checks through the pst clock latches
##set_false_path -from [get_clocks CLK] -through [get_cells -hier *clk_en_reg]
#
## cap_mem static config bits
#set_max_delay 10.0 -from [get_pins top/capmem/cap_mem_top_i/c*] -to [get_cells top/capmem/glue/*SData*]
#set_max_delay 10.0 -to   [get_pins top/capmem/cap_mem_top_i/*]
#
#for {set i 0} {$i < 650} {incr i} {
#	set_data_check -from [get_pins top/capmem/cap_mem_top_i/cb[$i]] -to [get_pins top/capmem/cap_mem_top_i/c[$i]] -0.5 -clock CLK
#	set_data_check -from [get_pins top/capmem/cap_mem_top_i/c[$i]] -to [get_pins top/capmem/cap_mem_top_i/cb[$i]] -0.5 -clock CLK
#}
#
## static config bits of srams
#set_max_delay 5.0 -to [get_pins top/synarray/synapses_macro/pc_conf*]
#set_max_delay 5.0 -to [get_pins top/synarray/synapses_macro/w_conf*]
#
#set_max_delay 3.0 -to [get_pins top/synarray/synapses_macro/dacen*]
#set_max_delay 3.0 -to [get_pins top/synarray/synapses_macro/adren*]
#set_max_delay 3.0 -to [get_pins top/synarray/synapses_macro/adr*]
#set_max_delay 3.0 -to [get_pins top/synarray/synapses_macro/adrb*]
#
## special delay requirements on asynchronous pins to synapse array:
#for {set i 0} {$i < 32} {incr i} {
#	set_data_check -from [get_pins top/synarray/synapses_macro/dacen[$i]] -to [get_pins top/synarray/synapses_macro/adren[$i]] -0.2 -clock CLK
#	set_data_check -from [get_pins top/synarray/synapses_macro/adren[$i]] -to [get_pins top/synarray/synapses_macro/dacen[$i]] -0.2 -clock CLK
#	for {set j 0} {$j < 6} {incr j} {
#		set_data_check -from [get_pins top/synarray/synapses_macro/adren[$i]] -to [get_pins top/synarray/synapses_macro/adr${j}[$i]] -0.2 -clock CLK
#		set_data_check -from [get_pins top/synarray/synapses_macro/adren[$i]] -to [get_pins top/synarray/synapses_macro/adrb${j}[$i]] -0.2 -clock CLK
#	}
#}


## neuron's digital fire out lines
##set_max_delay 1.0 -to [get_cells -hier *async_state_reg]
#set_max_delay 3.0 -from [get_cells -hier *async_state_reg] -to [get_cells -hier *syn1_reg]
#
## disable timing to all analog pins
##foreach libcell [list "capacitive_memory_top_wc/capacitive_memory" "denmem_block_wc/denmem_block" "synapse_block_top_wc/synapse_block_top" "cadc_macro_tc/8_BIT_ADC"] {
##	foreach_in_collection anapin [get_attribute [get_lib_pins $libcell/*] is_analog true] {
##		set_false_path -to $anapin
##		set_false_path -from $anapin
##	}
##}
#
## dummy clock to generate output timing of cadc dout lines:
## timing follows...
#create_clock -period 10.0 -waveform { 0 5.0 } [get_pins top/cadc/cadc/macro/dummy_clk] -name DUMMY_CLK_CADC
#
## cadc data out signals are enabled well before signals are read (to be implemented in RTL by sfriedmann)
## therefore define rather relaxed timing, here:
#set_max_delay 5.0 -from [get_clocks DUMMY_CLK_CADC]
#set_false_path -hold -from [get_clocks DUMMY_CLK_CADC]
#
## reset timing checks
#set enable_recovery_removal_arcs true
#
## input/output timing checks
#set_input_delay 1.0 -clock [get_clocks CLK] [get_ports valid_in]
#set_input_delay 1.0 -clock [get_clocks CLK] [get_ports data_in*]
#
#set_output_delay 0.0 -clock [get_clocks CLK] [get_pins PD_VALID_OUT/I]
#set_output_delay 0.0 -clock [get_clocks CLK] [get_pins PD_DATA_OU*/I]
#
## capmem clock divider
#create_generated_clock -name CAPMEM_DIVIDE_02 -source [get_pins PD_CLK/C] -divide_by 2 [get_pins top/capmem/glue/clk_scale_reg_0_/Q]
#create_generated_clock -name CAPMEM_DIVIDE_04 -source [get_pins PD_CLK/C] -divide_by 4 [get_pins top/capmem/glue/clk_scale_reg_1_/Q]
#create_generated_clock -name CAPMEM_DIVIDE_08 -source [get_pins PD_CLK/C] -divide_by 8 [get_pins top/capmem/glue/clk_scale_reg_2_/Q]
#create_generated_clock -name CAPMEM_DIVIDE_16 -source [get_pins PD_CLK/C] -divide_by 16 [get_pins top/capmem/glue/clk_scale_reg_3_/Q]
#create_generated_clock -name CAPMEM_DIVIDE_32 -source [get_pins PD_CLK/C] -divide_by 32 [get_pins top/capmem/glue/clk_scale_reg_4_/Q ]
#create_generated_clock -name CAPMEM_DIVIDE_64 -source [get_pins PD_CLK/C] -divide_by 64 [get_pins top/capmem/glue/clk_scale_reg_5_/Q ]
##set_ideal_network [get_pins "top/capmem/glue/omnibus_if.Clk"]
#set_ideal_network [get_pins "top/capmem/glue/clk_scale_reg_0_/Q"]
#set_ideal_network [get_pins "top/capmem/glue/clk_scale_reg_1_/Q"]
#set_ideal_network [get_pins "top/capmem/glue/clk_scale_reg_2_/Q"]
#set_ideal_network [get_pins "top/capmem/glue/clk_scale_reg_3_/Q"]
#set_ideal_network [get_pins "top/capmem/glue/clk_scale_reg_4_/Q"]
#set_ideal_network [get_pins "top/capmem/glue/clk_scale_reg_5_/Q"]
#
## serdes clock divider
##set_clock_groups -logically_exclusive -name CAPMEM_GROUP \
## -group {CLK} \
## -group {CAPMEM_DIVIDE_02} \
## -group {CAPMEM_DIVIDE_04} \
## -group {CAPMEM_DIVIDE_08} \
## -group {CAPMEM_DIVIDE_16} \
## -group {CAPMEM_DIVIDE_32} \
## -group {CAPMEM_DIVIDE_64}
#
## make paths from generated clocks to counter inputs false:
##set_false_path -from [get_clocks CAPMEM_DIVIDE_*] -to [get_cells "top/capmem/glue/clk_scale_reg*"]
#
## make the clock multiplexers size only
#set_size_only [get_cells "top/capmem/glue/rampmux*"]
#set_size_only [get_cells "top/capmem/glue/pausemux*"]
#set_size_only [get_cells "top/capmem/glue/clk_scale_reg*"]
#
## false paths through clock mux select pins
#for {set i 0} {$i < 6} {incr i} {
#	set_false_path -through [get_pins "top/capmem/glue/rampmux${i}_i/S"]
#	set_false_path -through [get_pins "top/capmem/glue/pausemux${i}_i/S"]
#}
#set_false_path -through [get_pins "top/serdes/ioclkmux_i/S"]
#
#
## same procedure for the divided serdes clock:
#create_generated_clock -name SERDES_DIVIDE_02 -source [get_pins PD_CLK/C] -divide_by 2 [get_pins top/serdes/scaled_clk_reg/Q]
#set_ideal_network [get_pins "top/serdes/scaled_clk_reg/Q"]
##set_clock_groups -logically_exclusive -name SERDES_GROUP \
## -group {CLK} \
## -group {SERDES_DIVIDE_02}
##set_false_path -from [get_clocks SERDES_DIVIDE_02] -to [get_cells "top/serdes/scaled_clk_reg"]
#set_size_only [get_cells "top/serdes/ioclkmux_i"]
##set_case_analysis 0 [get_pins "top/serdes/ioclkmux_i/S"]
#
## make all analog paths false!
#foreach netpattern [list "aio_*" "top/capmem_neuron_if*" "top/syn_cadc_causal*" "top/syn_cadc_acausal*" "top/iouti*" "top/ioutx*" "top/synapse_post_signals*"] {
#	foreach_in_collection net [get_nets $netpattern] {
#		if {[sizeof_collection [all_connected -leaf [get_nets $net]]] > 1} {
#			set_ideal_network -no_propagate $net
#			set_dont_touch [get_nets $net] false
#		} else {
#			set netname [get_object_name $net]
#			puts "***WARNING: Net $netname has no/only one  pin connections!***"
#		}
#	}
#}
#
#
#set_dont_retime [get_cells top/ppu/pu/gen_fub_vector.fub_vector/gen_slice[0].slice/vrf/sram] true
#set_dont_retime [get_cells top/ppu/pu/gen_fub_vector.fub_vector/gen_slice[1].slice/vrf/sram] true
#set_dont_retime top/synarray/synapses_macro true
#set_dont_retime top/cadc/cadc/macro true
#set_dont_retime top/neurons/neurons_i true
#set_dont_retime top/capmem/cap_mem_top_i true
#set_dont_retime [get_cells PD_*] true
#set_dont_retime [get_cells CLAMP12A*] true
#set_dont_retime [get_cells CLAMP25A*] true
#set_dont_touch top/synarray/synapses_macro true
#set_dont_touch top/cadc/cadc/macro true
#set_dont_touch top/neurons/neurons_i true
#set_dont_touch top/capmem/cap_mem_top_i true
#set_dont_touch [get_cells PD_*] true
#set_dont_touch [get_cells CLAMP12A*] true
#set_dont_touch [get_cells CLAMP25A*] true
#set_dont_touch [get_cells top/ppu/pu/gen_fub_vector.fub_vector/gen_slice[0].slice/vrf/sram] true
#set_dont_touch [get_cells top/ppu/pu/gen_fub_vector.fub_vector/gen_slice[1].slice/vrf/sram] true
