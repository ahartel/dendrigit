`ifndef SPIKES_IF
`define SPIKES_IF

class spike_transactor #(NUM_SYNAPSE_ROWS=1,ADDR_WIDTH=8);
	virtual spike_in_if spike_in[NUM_SYNAPSE_ROWS];
	virtual tb_clk_if tb_clk;

	class spike_t;
		logic[NUM_SYNAPSE_ROWS-1:0] rows;
		logic[ADDR_WIDTH-1:0] address;
		integer t;

		function new (integer ti, logic[NUM_SYNAPSE_ROWS-1:0] r, logic[ADDR_WIDTH-1:0] a);
			t = ti;
			rows = r;
			address = a;
		endfunction
	endclass

	spike_t spikes[$];

	function new(virtual spike_in_if intf[NUM_SYNAPSE_ROWS], virtual tb_clk_if tbck);
		spike_in = intf;
		tb_clk = tbck;


		for (integer r=0;r<NUM_SYNAPSE_ROWS;r++)
			spike_in[r].valid = 1'b0;
	endfunction

	function void append_spike (integer timestamp, logic[NUM_SYNAPSE_ROWS-1:0] input_rows, logic[7:0] address);
		spike_t this_spike = new(timestamp,input_rows,address);
		spikes.push_back(this_spike);
	endfunction

	task send_spikes();
		spike_t this_spike;
		integer t = 0;
		for (integer i=0;i<spikes.size();i++) begin
			this_spike = spikes[i];
			while (t < this_spike.t) begin
				@(posedge tb_clk.fast_clk);
				for (integer r=0;r<NUM_SYNAPSE_ROWS;r++)
					spike_in[r].valid = 1'b0;
				t = t + 1;
			end
			for (integer r=0;r<NUM_SYNAPSE_ROWS;r++) begin
				spike_in[r].valid = this_spike.rows[r];
				spike_in[r].address = this_spike.address;
			end
		end
		@(posedge tb_clk.fast_clk);
		for (integer r=0;r<NUM_SYNAPSE_ROWS;r++)
			spike_in[r].valid = 1'b0;
	endtask

endclass

`endif //SPIKES_IF
