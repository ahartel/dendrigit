
interface spike_out_if();
	logic valid;
	logic on_off;

	modport slave (input valid, on_off);
	modport master (output valid, on_off);

endinterface
