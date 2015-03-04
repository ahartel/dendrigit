
module dendrite(
	input logic clk,
	input logic reset,
	dendrite_neuron_if neuron,
	synapse_dendrite_if synapse0,
	synapse_dendrite_if synapse1
);

	logic synadd_co;
	fp::fpType vmem, sub_result, new_vmem;

	DW01_add #(.width(fp::WORD_LENGTH)) add_synapses (.A(synapse0.output_current),.B(synapse1.output_current),.CI(1'b0),.CO(synadd_co),.SUM(sub_result));
	DW01_add #(.width(fp::WORD_LENGTH)) add_vmem     (.A(sub_result),.B(vmem),.ADD_SUB(1'b0),.CI(synadd_co),.SUM(new_vmem));

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
