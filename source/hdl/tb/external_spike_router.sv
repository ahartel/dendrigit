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
	spike_out_if.slave spike_input[NUM_COLS],
	spike_if.master spike_output[NUM_SYNAPSE_ROWS],
	spike_if.slave external_stimulus[NUM_SYNAPSE_ROWS]
);

	logic[7:0] connections[NUM_SYNAPSE_ROWS][NUM_COLS];
	logic out_valids[NUM_COLS], out_on_offs[NUM_COLS];

	spike_if spike_feedback[NUM_SYNAPSE_ROWS]();


	generate
		for (genvar c=0;c<NUM_COLS;c++) begin
			assign out_valids[c] = spike_input[c].valid;
			assign out_on_offs[c] = spike_input[c].on_off;
		end
	endgenerate

	initial begin
		for (integer r=0;r<NUM_SYNAPSE_ROWS;r++) begin
			for (integer c=0; c<NUM_COLS; c++) begin
				connections[r][c] = 0;
			end
		end
		connections[0][1] = 1;
		connections[0][0] = 3;
	end


	generate
	for (genvar r=0;r<NUM_SYNAPSE_ROWS;r++) begin
		always_comb begin
			spike_feedback[r].valid = 1'b0;
			for (integer c=0; c<NUM_COLS; c++) begin
				if (out_valids[c] && connections[r][c] > 0) begin
					spike_feedback[r].valid = 1'b1;
					spike_feedback[r].on_off = out_on_offs[c];
					spike_feedback[r].address = connections[r][c];
					break;
				end
			end
		end

		assign spike_output[r].on_off = spike_feedback[r].valid ? spike_feedback[r].on_off : external_stimulus[r].on_off;
		assign spike_output[r].address = spike_feedback[r].valid ? spike_feedback[r].address : external_stimulus[r].address;
		assign spike_output[r].valid = spike_feedback[r].valid | external_stimulus[r].valid;
	end
	endgenerate

endmodule
