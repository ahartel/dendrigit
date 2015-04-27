
module dendrite(
	input logic clk,
	input logic reset,
	config_if.slave cfg_in,
	config_if.master cfg_out,
	dendrite_neuron_if neuron,
	synapse_dendrite_if synapse0,
	synapse_dendrite_if synapse1
);

	logic synadd_co;
	fp::fpType vmem, sub_result, new_vmem;

	assign cfg_out.data_clk = cfg_in.data_clk;
	always_ff @(posedge cfg_in.data_clk) begin
		cfg_out.data_in <= cfg_in.data_in;
	end

	DW01_add #(.width(fp::WORD_LENGTH)) add_synapses (.A(synapse0.output_current),.B(synapse1.output_current),.CI(1'b0),.CO(synadd_co),.SUM(sub_result));
	DW01_add #(.width(fp::WORD_LENGTH)) add_vmem     (.A(sub_result),.B(vmem),.CO(),.CI(synadd_co),.SUM(new_vmem));

	always_ff @(posedge clk) begin
		if (reset) begin
			vmem <= 0;
		end
		else begin
			if (vmem > 0 || synapse0.output_current || synapse1.output_current) begin
				vmem <= new_vmem;
			end
		end
	end

endmodule
