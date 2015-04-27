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

	fp::fpType El, gl, decay_gl, tau_gl, gl_jump, sub_result;
	fp::fpType dummy;
	fp::fpWideType end_result;

	assign cfg_out.data_clk = cfg_in.data_clk;
	always_ff @(posedge cfg_in.data_clk) begin
		El <= cfg_in.data_in;
		gl_jump <= El;
		tau_gl <= gl_jump;
		cfg_out.data_in <= tau_gl;
	end

	DW02_mult   #(.A_width(fp::WORD_LENGTH),.B_width(fp::WORD_LENGTH)) mult_decay_gl (.A(gl),.B(tau_gl),.PRODUCT({dummy,decay_gl}),.TC(1'b0));

	// gl
	always_ff @(posedge clk) begin
		if (reset) begin
			gl <= 0;
		end
		else begin
			if (input_spike) begin
				gl <= gl - decay_gl + gl_jump;
			end
			else if (gl>0) begin
				gl <= gl - decay_gl;
			end
		end
	end

	//DW_fp_addsub #(.ieee_compliance(1)) U1(.a(El),.b(dendrite.vmem),.op(1'b1),.z(sub_result));
	DW01_addsub #(.width(fp::WORD_LENGTH)) U1(.A(El),.B(dendrite.vmem),.ADD_SUB(1'b1),.CI(1'b0),.SUM(sub_result));
	//DW_fp_mult   #(.ieee_compliance(1)) U2(.a(sub_result),.b(gl),.z(end_result),.rnd(3'b000));
	DW02_mult   #(.A_width(fp::WORD_LENGTH),.B_width(fp::WORD_LENGTH)) U2(.A(sub_result),.B(gl),.PRODUCT(end_result),.TC(1'b0));

	always_ff @(posedge clk) begin
		if (reset) begin
			dendrite.output_current <= 0;
		end
		else begin
			if (gl > 0) begin
				dendrite.output_current <= end_result[fp::WORD_LENGTH-1:fp::WORD_LENGTH/2];
			end
			else begin
				dendrite.output_current <= 0;
			end
		end
	end

endmodule
