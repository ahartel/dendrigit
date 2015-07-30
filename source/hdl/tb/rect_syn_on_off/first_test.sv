`include "params.sv"
`include "shared_params.sv"
`include "spikes.sv"

module first_test();

localparam NUM_SYNAPSE_ROWS = 20;
localparam NUM_COLS = 2;
localparam WEIGHT_WIDTH = 6;

localparam time fast_period = 1us;
localparam time slow_period = 10us;
logic fast_clk, slow_clk, reset;
logic main_clk;
system_if sys_if(main_clk,slow_clk,reset);

tb_clk_if tb_clk(fast_clk,slow_clk,reset);

assign main_clk = tb_clk.start_fast_clock ? fast_clk : 1'b0;

spike_if spike_in[NUM_SYNAPSE_ROWS]();
spike_if router_spike_output[NUM_SYNAPSE_ROWS]();
spike_out_if nn_spike_output[NUM_COLS]();

config_if cfg_in[NUM_SYNAPSE_ROWS+1](),cfg_out[NUM_SYNAPSE_ROWS+1]();

neuron_params neuron_config[NUM_COLS];
dendrite_params dendrite_config[NUM_SYNAPSE_ROWS][NUM_COLS];
synapse_params synapse_config[NUM_SYNAPSE_ROWS][NUM_COLS*2];
row_params row_config[NUM_SYNAPSE_ROWS];
config_transactor #(
	.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),
	.NUM_COLS(NUM_COLS),
	.NUM_NEURON_PARAMS(4),
	.NUM_SYNAPSE_PARAMS(2),
	.NUM_DENDRITE_PARAMS(2),
	.NUM_ROW_PARAMS(3)
) cfg_trans = new(cfg_in);

spike_transactor #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS)) spike_trans = new(spike_in,tb_clk);

initial begin
	for (integer r=0; r<NUM_SYNAPSE_ROWS; r++) begin
		spike_trans.append_poisson(0ns,1000ns,100,1<<r,16'h0000);
	end
	//spike_trans.append_spike(50,1,0);
	//spike_trans.append_spike(55,1,1);
	//spike_trans.append_spike(60,1,2);
	//spike_trans.append_spike(65,1,3);
	//spike_trans.append_spike(70,1,4);
	//spike_trans.append_spike(75,1,5);
	//spike_trans.append_spike(100,2,0);
	//spike_trans.append_spike(150,3,1);
end

initial begin
	for (integer c=0; c<NUM_COLS; c++) begin
		neuron_config[c] = new();
		neuron_config[c].set_E_l(-60);
		neuron_config[c].set_tau_mem(20);
		neuron_config[c].set_v_thresh(-50);
		neuron_config[c].set(3,10);
		for (integer r=0; r<NUM_SYNAPSE_ROWS; r++) begin
			row_config[r] = new();
			row_config[r].set_bio(0,-60);
			row_config[r].set_bio(1,-10);

			synapse_config[r][c*2+0] = new();
			//synapse_config[r][c*2+0].set_bio(0,-10);
			synapse_config[r][c*2+0].set(0,32);
			synapse_config[r][c*2+0].set_address(c*2+0);

			synapse_config[r][c*2+1] = new();
			//synapse_config[r][c*2+1].set_bio(0,-10);
			synapse_config[r][c*2+1].set(0,32);
			synapse_config[r][c*2+1].set_address(c*2+1);

			dendrite_config[r][c] = new();
			//dendrite_config[r][c].set_bio(0,-60); // El
			dendrite_config[r][c].set_bio(0,20); // tau_mem
			dendrite_config[r][c].set_bio(1,0.1); // g_int
		end
	end
end

initial begin
	reset = 1'b1;
	tb_clk.start_fast_clock = 1'b1;
	#2us;
	tb_clk.start_fast_clock = 1'b0;
	#2us;
	reset = 1'b0;
	#2us;
	cfg_trans.write_neuron_config(neuron_config);
	cfg_trans.write_synapse_dendrite_config(row_config,dendrite_config,synapse_config);
	tb_clk.start_fast_clock = 1'b1;
	spike_trans.send_spikes();
	#10us;
	$finish();
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


external_spike_router #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS)) router(
	.sys_if(sys_if),
	.spike_input(nn_spike_output),
	.spike_output(router_spike_output),
	.external_stimulus(spike_in)
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
