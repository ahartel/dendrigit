/*
  In this module, the following processes are necessary:
  The conductance g has to be increased and decayed whenever a spike comes in
  The output current has to be calculated according to the current conductance and membrane potential
*/

module synapse
#(
	parameter WEIGHT_WIDTH = 6,
	parameter WEIGHT = 128
)
(
	input logic clk, reset,
	input logic input_spike,
	synapse_dendrite_if.synapse dendrite,
	config_if.slave cfg_in,
	config_if.master cfg_out
);
	localparam right_shift_decay_gsyn = 15;
	localparam right_shift_output_current = 9;

	fp::fpType E_rev, gsyn, decay_gsyn_shifted, tau_syn, weight, E_rev_vmem_diff;
	fp::fpType gsyn_minus_decay, new_gsyn;
	fp::fpWideType decay_gsyn;
	logic[fp::WORD_LENGTH*2+1-1:0] output_current;
	logic carry_sub_gsyn_decay;

	assign cfg_out.data_clk = cfg_in.data_clk;
	always_ff @(posedge cfg_in.data_clk) begin
		E_rev <= cfg_in.data_in;
		weight <= E_rev;
		tau_syn <= weight;
		cfg_out.data_in <= tau_syn;
	end

	DW02_mult   #(.A_width(fp::WORD_LENGTH),.B_width(fp::WORD_LENGTH)) mult_decay_gsyn (.A(gsyn),.B(tau_syn),.PRODUCT(decay_gsyn),.TC(1'b0));
	assign decay_gsyn_shifted = (decay_gsyn>>right_shift_decay_gsyn)&16'hffff;
	DW01_sub #(
		.width(fp::WORD_LENGTH)
	) sub_gsyn_decay (
		.CI(1'b0),
		.CO(carry_sub_gsyn_decay),
		.A(gsyn),
		.B(decay_gsyn_shifted),
		.DIFF(gsyn_minus_decay)
	);
	DW01_add #(
		.width(fp::WORD_LENGTH)
	) add_gsyn_weight (
		.CI(carry_sub_gsyn_decay),
		.CO(),
		.A(gsyn_minus_decay),
		.B(weight),
		.SUM(new_gsyn)
	);

	// gsyn
	always_ff @(posedge clk) begin
		if (reset) begin
			gsyn <= 0;
		end
		else begin
			if (input_spike) begin
				gsyn <= new_gsyn;
			end
			else if (gsyn==1) begin
				gsyn <= 0;
			end
			else if (gsyn>0) begin
				if (decay_gsyn_shifted>0) begin
					gsyn <= gsyn_minus_decay;
				end
				else if (decay_gsyn_shifted==0) begin
					gsyn <= 0;
				end
			end
		end
	end

	DW01_sub #(.width(fp::WORD_LENGTH)) U1 (
		.A(E_rev),
		.B(dendrite.vmem),
		.CI(1'b0),
		.CO(),
		.DIFF(E_rev_vmem_diff)
	);
	DW02_mult   #(.A_width(fp::WORD_LENGTH),.B_width(fp::WORD_LENGTH+1)) U2(.A(E_rev_vmem_diff),.B({1'b0,gsyn}),.PRODUCT(output_current),.TC(1'b1));

	always_ff @(posedge clk) begin
		if (reset) begin
			dendrite.output_current <= 0;
		end
		else begin
			dendrite.output_current <= (output_current>>right_shift_output_current)&16'hffff;
		end
	end

endmodule
