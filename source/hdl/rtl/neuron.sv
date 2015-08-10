
module neuron
#(
	parameter WEIGHT_WIDTH = 6,
	parameter COUNTER_WIDTH = 16,
	parameter MEMBRANE_WIDTH = 16
)
(
	input logic clk,
	input logic reset,
	input fp::fpType dendrite_current,
	output fp::fpType vmem,
	// write_interface
	config_if.slave cfg_in,
	config_if.master cfg_out,
	// spike_out_interface
	spike_out_if.master output_spike
);

	localparam right_shift_decay_vmem = 15;

	// parameter registers
	fp::fpType E_l, tau_mem, v_thresh, tau_ref, fixed_current;
	// intermediate results
	fp::fpType E_l_vmem_diff, decay_vmem_shifted, new_vmem, vmem_decay_leak, vmem_before_current;
	logic[fp::WORD_LENGTH*2+1-1:0] decay_vmem;
	// carries
	logic carry_add_upper,carry_add_leak;
	// refractory flag
	logic tauref_counter_hit, refractory, super_thresh;
	logic [COUNTER_WIDTH-1:0] tauref_counter;

	assign decay_vmem_shifted = (decay_vmem>>right_shift_decay_vmem)&16'hffff;

	assign cfg_out.data_clk = cfg_in.data_clk;
	always_ff @(posedge cfg_in.data_clk) begin
		E_l <= cfg_in.data_in;
		tau_mem <= E_l;
		v_thresh <= tau_mem;
		tau_ref <= v_thresh;
		fixed_current <= tau_ref;
		cfg_out.data_in <= fixed_current;
	end

	// TC
	DW01_sub #(.width(fp::WORD_LENGTH)) sub_El_vmem(
		.A(E_l),
		.B(vmem),
		.CI(1'b0),
		.CO(),
		.DIFF(E_l_vmem_diff)
	);
	// tau_mem implicitely converted to TC
	DW02_mult #(.A_width(fp::WORD_LENGTH),.B_width(fp::WORD_LENGTH+1)) mult_decay_mem (
		.A(E_l_vmem_diff),
		.B({1'b0,tau_mem}),
		.PRODUCT(decay_vmem),
		.TC(1'b1)
	);

	DW01_add #(.width(fp::WORD_LENGTH)) add_leak_current (
		.A(vmem),
		.B(decay_vmem_shifted),
		.CO(carry_add_leak),
		.CI(1'b0),
		.SUM(vmem_decay_leak)
	);

	DW01_add #(.width(fp::WORD_LENGTH)) add_upper (
		.A(vmem_decay_leak),
		.B(dendrite_current),
		.CO(carry_add_upper),
		.CI(carry_add_leak),
		.SUM(vmem_before_current)
	);

	DW01_add #(.width(fp::WORD_LENGTH)) add_current_source (
		.A(vmem_before_current),
		.B(fixed_current),
		.CI(carry_add_upper),
		.CO(),
		.SUM(new_vmem)
	);


	// store latest calculation result
	always_ff @(posedge clk) begin
		if (reset) begin
			vmem <= 0;
		end
		else begin
			if (decay_vmem != 0 || dendrite_current) begin
				vmem <= new_vmem;
			end
			//else begin
			//	vmem <= new_vmem;
			//end
		end
	end


	DW01_cmp2 #(.width(fp::WORD_LENGTH)) vt_cmp (
		.A(vmem),
		.B(v_thresh),
		.TC(1'b1),
		.LEQ(1'b0),
		.GE_GT(super_thresh),
		.LT_LE()
	);

	always_ff @(posedge clk) begin
		if (reset) begin
			output_spike.valid <= 1'b0;
		end
		else begin
			if (refractory && tauref_counter_hit) begin
				output_spike.valid <= 1'b1;
				output_spike.on_off <= 1'b0;
			end
			else if (!refractory && super_thresh) begin
				output_spike.valid <= 1'b1;
				output_spike.on_off <= 1'b1;
			end
			else begin
				output_spike.valid <= 1'b0;
			end
		end
	end

	assign tauref_counter_hit = (tau_ref-1==tauref_counter);
	assign refractory = ((output_spike.valid && output_spike.on_off) || tauref_counter_hit || (tauref_counter > 0));

	// tauref_counter
	always_ff @(posedge clk) begin
		if (reset) begin
			tauref_counter <= 0;
		end
		else begin
			if (tauref_counter == 0) begin
				if (output_spike.valid && output_spike.on_off == 1'b1)
					tauref_counter <= tauref_counter + 1;
			end
			else if (tauref_counter == tau_ref-1) begin
				tauref_counter <= 0;
			end
			else begin
				tauref_counter <= tauref_counter + 1;
			end

		end
	end

/*
logic taumem_counter_wrap, tauref_counter_wrap;
logic [COUNTER_WIDTH-1:0] taumem_counter, tauref_counter;
logic [MEMBRANE_WIDTH-1:0] membrane;

// taumem_counter
always_ff @(posedge clk) begin
	if (reset) begin
		taumem_counter <= 0;
		taumem_counter_wrap <= 1'b0;
	end
	else begin
		if (taumem_counter == taumem_scale) begin
			taumem_counter <= 0;
		end
		else begin
			taumem_counter <= taumem_counter+1;
		end
		// check wrap
		if (taumem_counter == taumem_scale) begin
			taumem_counter_wrap <= 1'b1;
		end
		if (taumem_counter_wrap) begin
			taumem_counter_wrap <= 1'b0;
		end
	end
end



always_ff @(posedge clk) begin
	if (reset) begin
		membrane <= v_reset;
	end
	else begin
		if (input_spike_valid) begin
			if (taumem_counter_wrap) begin
				if ((membrane<<1) + dendrite_current > v_threshold) begin
					membrane <= v_reset;
					output_spike <= 1'b1;
				end
				else begin
					membrane <= (membrane<<1) + dendrite_current;
				end
			end
			else begin
				membrane <= membrane + dendrite_current;
			end
		end
		else if (taumem_counter_wrap) begin
			membrane <= (membrane<<1);
		end
	end
end
*/
endmodule
