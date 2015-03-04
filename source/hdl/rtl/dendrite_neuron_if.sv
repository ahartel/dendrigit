
interface dendrite_neuron_if();
	parameter CURRENT_WIDTH = 8;

	logic input_spike_valid;
	logic [CURRENT_WIDTH-1:0] input_current;

	modport dendrite( output input_spike_valid, input_current);
	modport neuron( input input_spike_valid, input_current);


endinterface
