
interface spike_in_if();
	logic valid;
	logic on_off;
	logic[7:0] address;

	modport slave (input valid, on_off, address);
	modport master (output valid, on_off, address);

endinterface
