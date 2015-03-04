
module nn(
	input logic clk, reset,
	input logic[1:0] input_spike,
	config_if.slave cfg_in,
	config_if.master cfg_out,
	output logic output_spike
);

	synapse_dendrite_if synapse_if[1:0]();
	dendrite_neuron_if dendrite_if();

	synapse synapses[1:0] (
		.clk, .reset,
		.input_spike(input_spike),
		.dendrite(synapse_if),
		.cfg_in//, .cfg_out
	);

	dendrite dendrite_i (
		.clk, .reset,
		.synapse0(synapse_if[0]),
		.synapse1(synapse_if[1]),
		.neuron(dendrite_if)
	);

	neuron neuron_i (
		.clk, .reset,
		.dendrite(dendrite_if),
		.output_spike
	);

endmodule
