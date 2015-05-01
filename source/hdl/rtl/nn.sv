
module nn #(
	parameter integer NUM_SYNAPSE_ROWS=1,
	parameter integer NUM_COLS=1
)
(
	system_if.nn sys_if,
	spike_in_if.slave input_spike[NUM_SYNAPSE_ROWS],
	config_if.slave cfg_in[NUM_SYNAPSE_ROWS+1],
	config_if.master cfg_out[NUM_SYNAPSE_ROWS+1],
	output logic output_spike[NUM_COLS]
);

	dendrite_neuron_if dendr_nrn_if[NUM_COLS]();


	generate
		for (genvar i=0; i<NUM_SYNAPSE_ROWS; i=i+1) begin : synapse_rows
			config_if cfg_syn[3*NUM_COLS+1]();

			assign cfg_syn[0].data_in = cfg_in[i].data_in;
			assign cfg_syn[0].data_clk = cfg_in[i].data_clk;

			for (genvar j=0; j<NUM_COLS; j=j+1) begin : synapse_cols
				synapse_dendrite_if synapse_if[2]();

				synapse synapse_0 (
					.clk(sys_if.main_clk), .reset(sys_if.reset),
					.input_spike(input_spike[i].valid),
					.dendrite(synapse_if[0]),
					.cfg_in(cfg_syn[3*j]),
					.cfg_out(cfg_syn[3*j+1])
				);
				synapse synapse_1 (
					.clk(sys_if.main_clk), .reset(sys_if.reset),
					.input_spike(input_spike[i].valid),
					.dendrite(synapse_if[1]),
					.cfg_in(cfg_syn[3*j+2]),
					.cfg_out(cfg_syn[3*j+3])
				);


				if (i==NUM_SYNAPSE_ROWS-1) begin : dendrite_last_row
					dendrite dendrite_i (
						.clk(sys_if.main_clk), .reset(sys_if.reset),
						.synapse0(synapse_if[0]),
						.synapse1(synapse_if[1]),
						.neuron(dendr_nrn_if[j]),
						//.dendrite(dendr_nrn_if[]),
						.cfg_in(cfg_syn[3*j+1]),
						.cfg_out(cfg_syn[3*j+2])
					);
				end
				else begin : dendrite
					dendrite dendrite_i (
						.clk(sys_if.main_clk), .reset(sys_if.reset),
						.synapse0(synapse_if[0]),
						.synapse1(synapse_if[1]),
						.neuron(dendr_nrn_if[j]),
						//.dendrite(dendr_nrn_if[]),
						.cfg_in(cfg_syn[3*j+1]),
						.cfg_out(cfg_syn[3*j+2])
					);
				end
			end
		end
	endgenerate

	config_if cfg_nrn[NUM_COLS+1]();
	assign cfg_nrn[0].data_clk = cfg_in[NUM_SYNAPSE_ROWS].data_clk;
	assign cfg_nrn[0].data_in = cfg_in[NUM_SYNAPSE_ROWS].data_in;
	generate
		for (genvar j=0; j<NUM_COLS; j=j+1) begin : neuron_cols
			neuron neuron_j (
				.clk(sys_if.main_clk), .reset(sys_if.reset),
				.dendrite(dendr_nrn_if[j]),
				.output_spike(output_spike[j]),
				.cfg_in(cfg_nrn[j]),
				.cfg_out(cfg_nrn[j+1])
			);
		end
	endgenerate

endmodule
