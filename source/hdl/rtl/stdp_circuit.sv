/* This module implements rectangular STDP */
module stdp_circuit(
	input logic clk,
	output logic change_weight,
	output fp::fpType delta_w,
	input fp::fpType weight,
	input fp::fpType stdp_amplitude,
	input fp::fpType stdp_timeconst,
	input logic pre,
	input logic post
);

	fp::fpType pre_state, post_state;
	fp::fpType new_pre_state, new_post_state;

	always @(posedge clk) begin
		if (pre) begin
			pre_state <= stdp_amplitude;
		end
		else begin
		end
	end

	always @(posedge clk) begin
		if (post) begin
			post_state <= stdp_amplitude;
		end
		else begin
		end
	end

endmodule
