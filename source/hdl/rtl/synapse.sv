
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

	fp::fpType El, gl, sub_result;
	fp::fpWideType end_result;

	assign cfg_out.data_clk = cfg_in.data_clk;
	always_ff @(posedge cfg_in.data_clk) begin
		El <= cfg_in.data_in;
		gl <= El;
		cfg_out.data_in <= gl;
	end

	//DW_fp_addsub #(.ieee_compliance(1)) U1(.a(El),.b(dendrite.vmem),.op(1'b1),.z(sub_result));
	DW01_addsub #(.width(fp::WORD_LENGTH)) U1(.A(El),.B(dendrite.vmem),.ADD_SUB(1'b1),.CI(1'b0),.SUM(sub_result));
	//DW_fp_mult   #(.ieee_compliance(1)) U2(.a(sub_result),.b(gl),.z(end_result),.rnd(3'b000));
	DW02_mult   #(.A_width(fp::WORD_LENGTH),.B_width(fp::WORD_LENGTH)) U2(.A(sub_result),.B(gl),.PRODUCT(end_result),.TC(1'b1));

	always_ff @(posedge clk) begin
		dendrite.output_current <= end_result[fp::WORD_LENGTH-1:fp::WORD_LENGTH/2];
	end

endmodule
