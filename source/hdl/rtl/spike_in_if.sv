
interface spike_in_if();
	logic valid;
	logic[7:0] address;

	modport slave (input valid, address);
	modport master (output valid, address);

endinterface
