
interface synapse_dendrite_if();
	import fp::*;
	logic output_valid;
	fpType output_current;
	fpType vmem;

	modport synapse(output output_valid, output_current,input vmem);
	modport dendrite(input output_valid, output_current,output vmem);

endinterface
