
module row_global_parameters(
	config_if.slave cfg_in,
	config_if.master cfg_out,
	output fp::fpType E_rev,
	output fp::fpType E_l
);

	assign cfg_out.data_clk = cfg_in.data_clk;
	always_ff @(posedge cfg_in.data_clk) begin
		E_l <= cfg_in.data_in;
		E_rev <= E_l;
		cfg_out.data_in <= E_rev;
	end

endmodule
