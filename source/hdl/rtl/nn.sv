
module nn #(
	parameter integer NUM_SYNAPSE_ROWS=1,
	parameter integer NUM_COLS=1
)
(
	system_if.nn sys_if,
	spike_if.slave input_spike[NUM_SYNAPSE_ROWS],
	config_if.slave cfg_in[NUM_SYNAPSE_ROWS+1],
	config_if.master cfg_out[NUM_SYNAPSE_ROWS+1],
	spike_out_if.master output_spike[NUM_COLS]
);

	dendrite_neuron_if #(.NUM_COLS(NUM_COLS)) dendr_nrn_if[NUM_SYNAPSE_ROWS+1]();
	for (genvar j=0; j<NUM_COLS; j=j+1) begin
		assign dendr_nrn_if[0].current[j] = 0;
	end

	generate
		for (genvar j=0; j<NUM_SYNAPSE_ROWS; j=j+1) begin : synapse_rows
			synapse_row #(.NUM_COLS(NUM_COLS))
			synapse_row_i
			(
				.sys_if(sys_if),
				.cfg_in(cfg_in[j]),
				.upper(dendr_nrn_if[j]),
				.lower(dendr_nrn_if[j+1]),
				.spike_input(input_spike[j]),
				.post_spikes(output_spike.slave)
			);
		end
	endgenerate

	config_if cfg_nrn[NUM_COLS+1]();
	assign cfg_nrn[0].data_clk = cfg_in[NUM_SYNAPSE_ROWS].data_clk;
	assign cfg_nrn[0].data_in = cfg_in[NUM_SYNAPSE_ROWS].data_in;
	generate
		for (genvar j=0; j<NUM_COLS; j=j+1) begin : neuron_cols
			neuron neuron_j (
				.clk(sys_if.main_clk), .reset(sys_if.reset),
				.dendrite_current(dendr_nrn_if[NUM_SYNAPSE_ROWS].current[j]),
				.vmem(dendr_nrn_if[NUM_SYNAPSE_ROWS].vmem[j]),
				.output_spike(output_spike[j]),
				.cfg_in(cfg_nrn[j]),
				.cfg_out(cfg_nrn[j+1])
			);
		end
	endgenerate

endmodule

module synapse_row #(
	parameter NUM_COLS = 1
)
(
	system_if.nn sys_if,
	config_if cfg_in,
	dendrite_neuron_if upper,
	dendrite_neuron_if lower,
	spike_if spike_input,
	spike_out_if.slave post_spikes[NUM_COLS]
);

	fp::fpType E_rev, E_l, stdp_amplitude, stdp_timeconst;
	config_if cfg_syn[3*NUM_COLS+1]();
	config_if global_config_if();
	assign cfg_syn[0].data_in = global_config_if.data_in;
	assign cfg_syn[0].data_clk = global_config_if.data_clk;

	synapse_dendrite_if synapse_if[NUM_COLS*2]();
	spike_if spike_to_synapses();

	row_global_parameters global_params(
		.cfg_in(cfg_in),
		.cfg_out(global_config_if),
		.E_rev(E_rev),
		.E_l(E_l),
		.stdp_amplitude(stdp_amplitude),
		.stdp_timeconst(stdp_timeconst),
		.spike_in(spike_input),
		.spike_out(spike_to_synapses)
	);

	generate
		for (genvar j=0; j<NUM_COLS; j=j+1) begin : synapse_cols
			synapse synapse_0 (
				.clk(sys_if.main_clk), .reset(sys_if.reset),
				.input_spike(spike_to_synapses),
				.dendrite(synapse_if[2*j]),
				.cfg_in(cfg_syn[3*j]),
				.cfg_out(cfg_syn[3*j+1]),
				.E_rev,
				.stdp_amplitude,
				.stdp_timeconst,
				.post(post_spikes[j])
			);
			synapse synapse_1 (
				.clk(sys_if.main_clk), .reset(sys_if.reset),
				.input_spike(spike_to_synapses),
				.dendrite(synapse_if[2*j+1]),
				.cfg_in(cfg_syn[3*j+2]),
				.cfg_out(cfg_syn[3*j+3]),
				.E_rev,
				.stdp_amplitude,
				.stdp_timeconst,
				.post(post_spikes[j])
			);


			dendrite dendrite_i (
				.clk(sys_if.main_clk), .reset(sys_if.reset),
				.synapse0(synapse_if[2*j]),
				.synapse1(synapse_if[2*j+1]),
				.upper_vmem(upper.vmem[j]),
				.upper_current(upper.current[j]),
				.lower_vmem(lower.vmem[j]),
				.lower_current(lower.current[j]),
				.cfg_in(cfg_syn[3*j+1]),
				.cfg_out(cfg_syn[3*j+2]),
				.E_l
			);
		end
	endgenerate
endmodule
