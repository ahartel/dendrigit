
interface config_if();
	parameter DATA_WIDTH = 32;
	logic [DATA_WIDTH-1:0] data_in, data_out;
	logic data_clk;

	modport master(output data_in, input data_out, output data_clk);
	modport slave(input data_in, output data_out, input data_clk);

endinterface
