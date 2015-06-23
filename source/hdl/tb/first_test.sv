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

neuron_params neuron_config[NUM_COLS];
dendrite_params dendrite_config[NUM_SYNAPSE_ROWS][NUM_COLS];
synapse_params synapse_config[NUM_SYNAPSE_ROWS][NUM_COLS*2];
config_transactor #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS)) cfg_trans = new(cfg_in);
spike_transactor #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS)) spike_trans = new(spike_in,tb_clk);

initial begin
	spike_trans.append_spike(50,1);
	spike_trans.append_spike(60,1);
	spike_trans.append_spike(100,2);
	spike_trans.append_spike(150,3);
end

initial begin
	for (integer c=0; c<NUM_COLS; c++) begin
		neuron_config[c] = new();
		neuron_config[c].set_tau_mem(1);
		for (integer r=0; r<NUM_SYNAPSE_ROWS; r++) begin
			synapse_config[r][c*2+0] = new();
			synapse_config[r][c*2+0].set_bio(0,-10);
			synapse_config[r][c*2+0].set(1,16);
			synapse_config[r][c*2+0].set_bio(2,2);
			synapse_config[r][c*2+1] = new();
			synapse_config[r][c*2+1].set_bio(0,-10);
			synapse_config[r][c*2+1].set(1,16);
			synapse_config[r][c*2+1].set_bio(2,2);

			dendrite_config[r][c] = new();
			dendrite_config[r][c].set_bio(0,-60); // El
			dendrite_config[r][c].set_bio(1,10); // tau_mem
			dendrite_config[r][c].set_bio(2,0.001); // tau_mem
		end
	end
	synapse_config[0][3].set(2,3);
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
