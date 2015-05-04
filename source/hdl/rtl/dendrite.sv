
module dendrite(
	input logic clk,
	input logic reset,
	config_if.slave cfg_in,
	config_if.master cfg_out,
	output fp::fpType upper_vmem,
	input fp::fpType upper_current,
	input fp::fpType lower_vmem,
	output fp::fpType lower_current,
	synapse_dendrite_if synapse0,
	synapse_dendrite_if synapse1
);

	localparam right_shift_decay_vmem = 15;

	logic synadd_co, carry_add_vmem;
	fp::fpType vmem, sum_syn_current, new_vmem, vmem_synin;
	logic[fp::WORD_LENGTH*2+1-1:0] decay_vmem;
	fp::fpType E_l, tau_mem, E_l_vmem_diff, decay_vmem_shifted;
	assign synapse0.vmem = vmem;
	assign synapse1.vmem = vmem;
	assign decay_vmem_shifted = (decay_vmem>>right_shift_decay_vmem)&16'hffff;

	assign cfg_out.data_clk = cfg_in.data_clk;
	always_ff @(posedge cfg_in.data_clk) begin
		E_l <= cfg_in.data_in;
		tau_mem <= E_l;
		cfg_out.data_in <= tau_mem;
	end

	// TC
	DW01_add #(.width(fp::WORD_LENGTH)) add_synapses (
		.A(synapse0.output_current),
		.B(synapse1.output_current),
		.CI(1'b0),
		.CO(synadd_co),
		.SUM(sum_syn_current)
	);
	DW01_add #(.width(fp::WORD_LENGTH)) add_vmem (
		.A(sum_syn_current),
		.B(vmem),
		.CO(carry_add_vmem),
		.CI(synadd_co),
		.SUM(vmem_synin)
	);

	// TC
	DW01_sub #(.width(fp::WORD_LENGTH)) sub_El_vmem(
		.A(E_l),
		.B(vmem),
		.CI(1'b0),
		.DIFF(E_l_vmem_diff)
	);
	// tau_mem implicitely converted to TC
	DW02_mult #(.A_width(fp::WORD_LENGTH),.B_width(fp::WORD_LENGTH+1)) mult_decay_mem (
		.A(E_l_vmem_diff),
		.B({1'b0,tau_mem}),
		.PRODUCT(decay_vmem),
		.TC(1'b1)
	);

	DW01_add #(.width(fp::WORD_LENGTH)) add_all (
		.A(vmem_synin),
		.B(decay_vmem_shifted),
		.CO(),
		.CI(carry_add_vmem),
		.SUM(new_vmem)
	);

	always_ff @(posedge clk) begin
		if (reset) begin
			vmem <= 0;
		end
		else begin
			if (decay_vmem != 0 || synapse0.output_current || synapse1.output_current) begin
				vmem <= new_vmem;
			end
			//else begin
			//	vmem <= new_vmem;
			//end
		end
	end

endmodule
