
interface synapse_dendrite_if();
	logic output_valid;
	fp::fpType output_current;
	fp::fpType vmem;

	modport synapse(output output_valid, output_current,input vmem);
	modport dendrite(input output_valid, output_current,output vmem);

endinterface
