`include "params.sv"
`include "spikes.sv"

module first_test();

localparam NUM_SYNAPSE_ROWS = 2;
localparam NUM_COLS = 2;
localparam WEIGHT_WIDTH = 6;

localparam time fast_period = 1us;
localparam time slow_period = 10us;
logic fast_clk, slow_clk, reset;
logic main_clk;
system_if sys_if(main_clk,slow_clk,reset);

tb_clk_if tb_clk(fast_clk,slow_clk,reset);

assign main_clk = tb_clk.start_fast_clock ? fast_clk : 1'b0;

spike_in_if spike_in[NUM_SYNAPSE_ROWS]();
//logic [WEIGHT_WIDTH-1:0] neuron_current [NUM_SYNAPSE_ROWS-1:0];

config_if cfg_in[NUM_SYNAPSE_ROWS+1](),cfg_out[NUM_SYNAPSE_ROWS+1]();

neuron_params   #(.NUM_COLS(NUM_COLS)) neuron_config = new();
dendrite_params #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS)) dendrite_config = new();
synapse_params  #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS)) synapse_config = new();
config_transactor #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS)) cfg_trans = new(cfg_in);
spike_transactor #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS)) spike_trans = new(spike_in,tb_clk);

initial begin
	spike_trans.append_spike(50,1);
	spike_trans.append_spike(60,1);
	spike_trans.append_spike(100,2);
	spike_trans.append_spike(150,3);
end

initial begin
	neuron_config.set(0,0,1);
	neuron_config.set(1,0,2);
	// first row, first column
	synapse_config.set_bio(0,0,0,-10); // El
	synapse_config.set(0,0,1,16);
	synapse_config.set_bio(0,0,2,2); // tau_syn
	synapse_config.set(0,1,0,4); // El
	synapse_config.set(0,1,1,16);
	synapse_config.set_bio(0,1,2,6); // tau_syn
	// first row, second column
	synapse_config.set(0,2,0,7); // El
	synapse_config.set(0,2,1,8);
	synapse_config.set_bio(0,2,2,9); // tau_syn
	synapse_config.set(0,3,0,10); // El
	synapse_config.set(0,3,1,11);
	synapse_config.set_bio(0,3,2,12); // tau_syn
	// second row, first column
	synapse_config.set(1,0,0,16); // El
	synapse_config.set(1,0,1,17);
	synapse_config.set_bio(1,0,2,15); // tau_syn
	synapse_config.set(1,1,0,19); // El
	synapse_config.set(1,1,1,20);
	synapse_config.set_bio(1,1,2,18); // tau_syn
	// second row, first column
	synapse_config.set(1,2,0,22); // El
	synapse_config.set(1,2,1,23);
	synapse_config.set_bio(1,2,2,21); // tau_syn
	synapse_config.set(1,3,0,25); // El
	synapse_config.set(1,3,1,26);
	synapse_config.set_bio(1,3,2,24); // tau_syn
	// denrites
	dendrite_config.set_bio(0,0,0,-60); // El
	dendrite_config.set_bio(0,0,1,10); // tau_mem
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
	cfg_trans.write_synapse_dendrite_config(dendrite_config,synapse_config);
	tb_clk.start_fast_clock = 1'b1;
	spike_trans.send_spikes();
	#100ns;
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



nn #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS))
nn_i(
	.sys_if(sys_if),
	.input_spike(spike_in),
	.cfg_in,
	.cfg_out
);

endmodule
