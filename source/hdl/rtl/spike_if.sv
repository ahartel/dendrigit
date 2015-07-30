
interface spike_if();
	parameter ADDRESS_WIDTH = 16;

	logic valid;
	logic on_off;
	logic[ADDRESS_WIDTH-1:0] address;

	modport slave (input valid, on_off, address);
	modport master (output valid, on_off, address);

endinterface
