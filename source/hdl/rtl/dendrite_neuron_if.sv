
interface dendrite_neuron_if();
	parameter NUM_COLS = 1;

	logic input_spike_valid[NUM_COLS];
	fp::fpType current[NUM_COLS];
	fp::fpType vmem[NUM_COLS];

	modport dendrite( output input_spike_valid, current, input vmem);
	modport neuron( input input_spike_valid, current, output vmem);


endinterface
