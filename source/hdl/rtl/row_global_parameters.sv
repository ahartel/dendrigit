
module row_global_parameters(
	config_if.slave cfg_in,
	config_if.master cfg_out,
	output fp::fpType E_rev,
	output fp::fpType E_l,
	spike_if.slave spike_in,
	spike_if.master spike_out
);

	fp::fpType address;

	assign cfg_out.data_clk = cfg_in.data_clk;
	always_ff @(posedge cfg_in.data_clk) begin
		E_l <= cfg_in.data_in;
		E_rev <= E_l;
		address <= E_rev;
		cfg_out.data_in <= address;
	end

	assign spike_out.on_off = spike_in.on_off;
	assign spike_out.address = spike_in.address;
	always_comb begin
		spike_out.valid = 1'b0;
		if (address[7:0]==spike_in.address[15:8]) begin
			spike_out.valid = spike_in.valid;
		end
	end

endmodule
