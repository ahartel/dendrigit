/*
 * This module merges the input stream external_stimulus
 * with the spikes coming from the neural network via the
 * bus spike_input and sends the resulting output spikes
 * to the interface array spike_output.
 * The translation is done via a lookup table.
*/

module external_spike_router #(
	parameter integer NUM_COLS = 1,
	parameter integer NUM_SYNAPSE_ROWS = 1
)
(
	system_if.nn sys_if,
	input logic spike_input[NUM_COLS],
	spike_in_if.master spike_output[NUM_SYNAPSE_ROWS],
	spike_in_if.slave external_stimulus[NUM_SYNAPSE_ROWS]
);

	// just feed through for now
	generate
		for (genvar r=0;r<NUM_SYNAPSE_ROWS;r++) begin
			assign spike_output[r].valid = external_stimulus[r].valid;
			assign spike_output[r].address = external_stimulus[r].address;
		end
	endgenerate


endmodule
