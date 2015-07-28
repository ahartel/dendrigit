`ifndef SPIKES_IF
`define SPIKES_IF

class spike_transactor #(NUM_SYNAPSE_ROWS=1,ADDR_WIDTH=8);
	virtual spike_in_if spike_in[NUM_SYNAPSE_ROWS];
	virtual tb_clk_if tb_clk;

	class spike_t;
		logic[NUM_SYNAPSE_ROWS-1:0] rows;
		logic[ADDR_WIDTH-1:0] address;
		integer t;
		integer width;

		function new (integer ti, logic[NUM_SYNAPSE_ROWS-1:0] r, logic[ADDR_WIDTH-1:0] a);
			t = ti;
			rows = r;
			address = a;
			width = 10;
		endfunction
	endclass

	class spike_send_event_t;
		logic[NUM_SYNAPSE_ROWS-1:0] rows;
		logic[ADDR_WIDTH-1:0] address;
		integer t;
		logic on_off;

		function new (integer ti, logic[NUM_SYNAPSE_ROWS-1:0] r, logic[ADDR_WIDTH-1:0] a, logic on);
			t = ti;
			rows = r;
			address = a;
			on_off = on;
		endfunction
	endclass

	spike_t spikes[$];
	spike_send_event_t start_times[$], stop_times[$];

	function new(virtual spike_in_if intf[NUM_SYNAPSE_ROWS], virtual tb_clk_if tbck);
		spike_in = intf;
		tb_clk = tbck;


		for (integer r=0;r<NUM_SYNAPSE_ROWS;r++) begin
			spike_in[r].valid = 1'b0;
			spike_in[r].on_off = 1'b1;
		end
	endfunction

	function void append_spike (integer timestamp, logic[NUM_SYNAPSE_ROWS-1:0] input_rows, logic[7:0] address);
		spike_t this_spike = new(timestamp,input_rows,address);
		spikes.push_back(this_spike);
	endfunction

	function void prepare_spikes();
		spike_send_event_t append_spike;

		foreach(spikes[i]) begin
			append_spike = new(spikes[i].t,spikes[i].rows,spikes[i].address,1'b1);
			start_times.push_back(append_spike);
			append_spike = new(spikes[i].t+spikes[i].width,spikes[i].rows,spikes[i].address,1'b0);
			stop_times.push_back(append_spike);
		end

	endfunction

	function void no_spike();
		for (integer r=0;r<NUM_SYNAPSE_ROWS;r++)
			spike_in[r].valid = 1'b0;
	endfunction

	function void send_spike(spike_send_event_t this_spike);
		for (integer r=0;r<NUM_SYNAPSE_ROWS;r++) begin
			spike_in[r].valid = this_spike.rows[r];
			spike_in[r].address = this_spike.address;
			spike_in[r].on_off = this_spike.on_off;
		end
	endfunction

	task send_spikes();
		spike_t this_spike;
		logic last_sent_start = 1'b0;
		integer t = 0;

		prepare_spikes();

		while(start_times.size() > 0 || stop_times.size() > 0) begin
			if (start_times.size() == 0) begin
				if (stop_times[0].t == t) begin
					// send stop spike
					send_spike(stop_times.pop_front());
				end
				else begin
					no_spike();
				end
			end
			else if (stop_times.size() == 0) begin
				if (start_times[0].t == t) begin
					// send start spike
					send_spike(start_times.pop_front());
				end
				else begin
					no_spike();
				end
			end
			else begin
				if (start_times[0].t <= t && stop_times[0].t > t) begin
					// send start spike
					send_spike(start_times.pop_front());
				end
				else if (start_times[0].t <= t && stop_times[0].t <= t && last_sent_start == 1'b0) begin
					// send start spike
					send_spike(start_times.pop_front());
				end
				else if (start_times[0].t > t && stop_times[0].t <= t) begin
					// send stop spike
					send_spike(stop_times.pop_front());
				end
				else if (start_times[0].t <= t && stop_times[0].t <= t && last_sent_start == 1'b1) begin
					// send stop spike
					send_spike(stop_times.pop_front());
				end
				else begin
					no_spike();
				end
			end
			@(posedge tb_clk.fast_clk);
			t = t + 1;
		end

		for (integer r=0;r<NUM_SYNAPSE_ROWS;r++)
			spike_in[r].valid = 1'b0;

		@(posedge tb_clk.fast_clk);
	endtask

endclass

`endif //SPIKES_IF
