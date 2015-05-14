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
	localparam right_shift_decay_gl = 15;
	localparam right_shift_output_current = 9;

	fp::fpType E_rev, gl, decay_gl_shifted, tau_syn, weight, E_rev_vmem_diff;
	fp::fpWideType decay_gl;
	logic[fp::WORD_LENGTH*2+1-1:0] output_current;

	assign cfg_out.data_clk = cfg_in.data_clk;
	always_ff @(posedge cfg_in.data_clk) begin
		E_rev <= cfg_in.data_in;
		weight <= E_rev;
		tau_syn <= weight;
		cfg_out.data_in <= tau_syn;
	end

	DW02_mult   #(.A_width(fp::WORD_LENGTH),.B_width(fp::WORD_LENGTH)) mult_decay_gl (.A(gl),.B(tau_syn),.PRODUCT(decay_gl),.TC(1'b0));
	assign decay_gl_shifted = (decay_gl>>right_shift_decay_gl)&16'hffff;

	// gl
	always_ff @(posedge clk) begin
		if (reset) begin
			gl <= 0;
		end
		else begin
			if (input_spike) begin
				gl <= gl - decay_gl_shifted + weight;
			end
			else if (gl==1) begin
				gl <= 0;
			end
			else if (gl>0) begin
				if (decay_gl_shifted>0) begin
					gl <= gl - decay_gl_shifted;
				end
				else if (decay_gl_shifted==0) begin
					gl <= 0;
				end
			end
		end
	end

	DW01_sub #(.width(fp::WORD_LENGTH)) U1(.A(E_rev),.B(dendrite.vmem),.CI(1'b0),.DIFF(E_rev_vmem_diff));
	DW02_mult   #(.A_width(fp::WORD_LENGTH),.B_width(fp::WORD_LENGTH+1)) U2(.A(E_rev_vmem_diff),.B({1'b0,gl}),.PRODUCT(output_current),.TC(1'b1));

	always_ff @(posedge clk) begin
		if (reset) begin
			dendrite.output_current <= 0;
		end
		else begin
			dendrite.output_current <= (output_current>>right_shift_output_current)&16'hffff;
		end
	end

endmodule
