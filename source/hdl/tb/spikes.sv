`ifndef SPIKES_IF
`define SPIKES_IF

class spike_transactor #(NUM_SYNAPSE_ROWS=1);
	virtual spike_in_if spike_in[NUM_SYNAPSE_ROWS];
	virtual system_if sys_if;
	class spike_t;
		logic[NUM_SYNAPSE_ROWS-1:0] rows;
		integer t;

		function new (integer r, integer ti);
			rows = r;
			t = ti;
		endfunction
	endclass

	spike_t spikes[$];

	function new(virtual spike_in_if intf[NUM_SYNAPSE_ROWS], virtual system_if sysif);
		spike_in = intf;
		sys_if = sysif;
		for (integer r=0;r<NUM_SYNAPSE_ROWS;r++)
			spike_in[r].valid = 1'b0;
	endfunction

	function void append_spike (integer timestamp, logic[NUM_SYNAPSE_ROWS-1:0] input_rows);
		spike_t this_spike = new(input_rows,timestamp);
		spikes.push_back(this_spike);
	endfunction

	task send_spikes();
		spike_t this_spike;
		integer t = 0;
		for (integer i=0;i<spikes.size();i++) begin
			this_spike = spikes[i];
			while (t < this_spike.t) begin
				@(posedge sys_if.fast_clk);
				for (integer r=0;r<NUM_SYNAPSE_ROWS;r++)
					spike_in[r].valid = 1'b0;
				t = t + 1;
			end
			for (integer r=0;r<NUM_SYNAPSE_ROWS;r++) begin
				spike_in[r].valid = this_spike.rows[r];
			end
		end
		@(posedge sys_if.fast_clk);
		for (integer r=0;r<NUM_SYNAPSE_ROWS;r++)
			spike_in[r].valid = 1'b0;
	endtask

endclass

`endif //SPIKES_IF
