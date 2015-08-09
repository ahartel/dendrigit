/*
  In this module, the following processes are necessary:
  The conductance has to be incremented by a fixed step size upon a positive event
  and decremented by the same amount upon a negative event. 
  The output current has to be calculated according to the current conductance and membrane potential
*/

module synapse
#(
	parameter WEIGHT_WIDTH = 6,
	parameter WEIGHT = 128
)
(
	input logic clk, reset,
	spike_if.slave input_spike,
	synapse_dendrite_if.synapse dendrite,
	config_if.slave cfg_in,
	config_if.master cfg_out,
	input fp::fpType E_rev
);
	localparam right_shift_output_current = 9;

	fp::fpType gsyn, weight, general_config;
	logic[fp::WORD_LENGTH*2+1-1:0] output_current;
	logic[7:0] address;

	assign address = general_config[7:0];

	// config process
	assign cfg_out.data_clk = cfg_in.data_clk;
	always_ff @(posedge cfg_in.data_clk) begin
		weight <= cfg_in.data_in;
		general_config <= weight;
		cfg_out.data_in <= general_config;
	end

	// gsyn
	always_ff @(posedge clk) begin
		if (reset) begin
			gsyn <= 0;
		end
		else begin
			if (input_spike.valid && input_spike.address == address && input_spike.on_off == 1'b1) begin
				gsyn <= gsyn + weight;
			end
			else if (input_spike.valid && input_spike.address == address && input_spike.on_off == 1'b0 && gsyn > 0) begin
				gsyn <= gsyn - weight;
			end
		end
	end

	synapse_to_dendrite_current syn_to_den(
		.E_rev(E_rev),
		.gsyn(gsyn),
		.vmem(dendrite.vmem),
		.output_current(output_current)
	);

	always_ff @(posedge clk) begin
		if (reset) begin
			dendrite.output_current <= 0;
		end
		else begin
			dendrite.output_current <= (output_current>>right_shift_output_current)&16'hffff;
		end
	end

endmodule
