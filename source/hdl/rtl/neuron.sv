
module neuron
#(
	parameter WEIGHT_WIDTH = 6,
	parameter COUNTER_WIDTH = 8,
	parameter MEMBRANE_WIDTH = 16
)
(
	input logic clk,
	input logic reset,
	// spike_in_interface
	input logic input_spike_valid,
	input fp::fpType dendrite_current,
	input fp::fpType vmem,
	// write_interface
	config_if.slave cfg_in,
	config_if.master cfg_out,
	// spike_out_interface
	output logic output_spike
);

logic taumem_counter_wrap, tauref_counter_wrap;
logic [COUNTER_WIDTH-1:0] taumem_counter, tauref_counter;
fp::fpType tau_mem;
logic [MEMBRANE_WIDTH-1:0] membrane;
// have to be stored in local memory later
localparam taumem_scale = 8'h10;
localparam tauref_scale = 8'h10;
localparam v_threshold = 16'h1000;
localparam v_reset = 16'h0000;

assign cfg_out.data_clk = cfg_in.data_clk;
always_ff @(posedge cfg_in.data_clk) begin
	tau_mem <= cfg_in.data_in;
	cfg_out.data_in <= tau_mem;
end

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

// tauref_counter
always_ff @(posedge clk) begin
	if (reset) begin
		tauref_counter <= 0;
		tauref_counter_wrap <= 1'b0;
	end
	else begin
		if (tauref_counter == tauref_scale) begin
			tauref_counter <= 0;
		end
		else begin
			tauref_counter <= tauref_counter+1;
		end
		// check wrap
		if (tauref_counter == tauref_scale) begin
			tauref_counter_wrap <= 1'b1;
		end
		if (tauref_counter_wrap) begin
			tauref_counter_wrap <= 1'b0;
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

endmodule
