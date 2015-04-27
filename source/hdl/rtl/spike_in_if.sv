
interface spike_in_if();
	logic valid;

	modport slave (input valid);
	modport master (output valid);

endinterface
