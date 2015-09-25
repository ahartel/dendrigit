parameter NUM_SYNAPSE_ROWS = 2;
parameter NUM_COLS = 1;

`include "params.sv"
`include "shared_params.sv"
`include "measure_activation_function.sv"


module basic_testbench();

	localparam time fast_period = 1us;
	localparam time slow_period = 10us;
	logic fast_clk, slow_clk;
	logic main_clk;
	system_if sys_if(main_clk,slow_clk);

	tb_clk_if tb_clk(fast_clk,slow_clk);

	assign main_clk = tb_clk.start_fast_clock ? fast_clk : 1'b0;

	spike_if spike_in[NUM_SYNAPSE_ROWS]();
	spike_if router_spike_output[NUM_SYNAPSE_ROWS]();
	spike_out_if nn_spike_output[NUM_COLS]();
	connection_if #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS)) connections();
	config_if cfg_in[NUM_SYNAPSE_ROWS+1](),cfg_out[NUM_SYNAPSE_ROWS+1]();

	measure_activation_function testclass = new(sys_if,
                                                tb_clk,
												cfg_in,
												spike_in,
												connections);

	integer on_spikes[$], off_spikes[$];

	initial begin
		testclass.prepare();
		testclass.test();
        testclass.evaluate(on_spikes,off_spikes);
	end

	always begin
		slow_clk = 1'b0;
		#(slow_period/2.0);
		slow_clk = 1'b1;
		#(slow_period/2.0);
	end

	always begin
		fast_clk = 1'b0;
		#(fast_period/2.0);
		fast_clk = 1'b1;
		#(fast_period/2.0);
	end

	always @(posedge fast_clk) begin
		if (nn_spike_output[0].valid) begin
			if (nn_spike_output[0].on_off == 1'b1) begin
				on_spikes.push_back($time);
			end
			else begin
				off_spikes.push_back($time);
			end
		end
	end

	external_spike_router #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS)) router(
		.sys_if(sys_if),
		.spike_input(nn_spike_output),
		.spike_output(router_spike_output),
		.external_stimulus(spike_in),
		.connections(connections)
	);

	nn #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS))
	nn_i(
		.sys_if(sys_if),
		.input_spike(router_spike_output),
		.cfg_in,
		.cfg_out,
		.output_spike(nn_spike_output)
	);

endmodule
