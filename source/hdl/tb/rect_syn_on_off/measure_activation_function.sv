`include "params.sv"
`include "shared_params.sv"
`include "spikes.sv"

function real count_and_print_spikes_and_rate(time start_time, integer on_spikes[$], integer off_spikes[$]);
	real rate;
	$display("Number of on-spikes : %d",on_spikes.size());
	$display("Number of off-spikes: %d",off_spikes.size());
	rate = real'(on_spikes.size())*1000.0/real'($time-start_time);
	$display("Spike rate: %f in delta-t: %d",rate,$time-start_time);
	return rate;
endfunction

module measure_activation_function();

localparam NUM_SYNAPSE_ROWS = 2;
localparam NUM_COLS = 1;

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
	.NUM_SYNAPSE_PARAMS(2)
) cfg_trans = new(cfg_in);

spike_transactor #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS)) spike_trans = new(spike_in,tb_clk);
logic[7:0] connections[NUM_SYNAPSE_ROWS][NUM_COLS];
time start_time;
integer on_spikes[$], off_spikes[$];
real rates[$];
integer fh;

initial begin

	/*
	// Set up weights
	*/
	for (integer r=0;r<NUM_SYNAPSE_ROWS;r++) begin
		for (integer c=0; c<NUM_COLS; c++) begin
			connections[r][c] = 0;
		end
	end

	//spike_trans.append_spike(50,1,0);
	//spike_trans.append_spike(55,1,1);
	//spike_trans.append_spike(60,1,2);
	//spike_trans.append_spike(65,1,3);
	//spike_trans.append_spike(70,1,4);
	//spike_trans.append_spike(75,1,5);
	//spike_trans.append_spike(100,2,0);
	//spike_trans.append_spike(150,3,1);

	/*
	// Set up configuration of neurons and synapses
	*/
	for (integer c=0; c<NUM_COLS; c++) begin
		neuron_config[c] = new();
		neuron_config[c].set_E_l(-60);
		neuron_config[c].set_tau_mem(80);
		//neuron_config[c].set_v_thresh(-40);
		neuron_config[c].set(2,-1000);
		neuron_config[c].set(3,10); // tau_ref
		neuron_config[c].set_fixed_current(3);
		// even rows are excitatory
		for (integer r=0; r<NUM_SYNAPSE_ROWS; r=r+1) begin
			row_config[r] = new();
			row_config[r].set_bio(0,-50); // El
			row_config[r].set_bio(1,-30); // Esyn

			synapse_config[r][c*2+0] = new();
			//synapse_config[r][c*2+0].set_bio(0,-10);
			synapse_config[r][c*2+0].set(0,16); //weight
			synapse_config[r][c*2+0].set_address(c*2+0);

			synapse_config[r][c*2+1] = new();
			//synapse_config[r][c*2+1].set_bio(0,-10);
			synapse_config[r][c*2+1].set(0,16); //weight
			synapse_config[r][c*2+1].set_address(c*2+1);

			dendrite_config[r][c] = new();
			//dendrite_config[r][c].set_bio(0,-60); // El
			dendrite_config[r][c].set_bio(0,80); // tau_mem
			dendrite_config[r][c].set_bio(1,0.1); // g_int
		end
		// odd rows are inhibitory
		for (integer r=1; r<NUM_SYNAPSE_ROWS; r=r+2) begin
			row_config[r].set_bio(1,-70); // Esyn
		end

	end
	/*
	// now the simulation time starts
	*/
	reset = 1'b1;
	tb_clk.start_fast_clock = 1'b1;
	#2us;
	tb_clk.start_fast_clock = 1'b0;
	#2us;
	reset = 1'b0;
	#2us;
	tb_clk.start_fast_clock = 1'b1;
	cfg_trans.write_synapse_dendrite_config(row_config,dendrite_config,synapse_config);
	/*
	// run the loop to measure the activation function
	*/
	for (integer run=0; run<24; run++) begin
		/*
		// Generate input poisson spike train
		*/
		void'(spike_trans.clear_all());
		for (integer r=0; r<NUM_SYNAPSE_ROWS; r++) begin
			for (integer c=0; c<NUM_COLS; c++) begin
				spike_trans.append_poisson(0ns,100us,100,1<<r,c*2);
			end
		end

		for (integer c=0; c<NUM_COLS; c++) begin
			neuron_config[c].set_fixed_current(2.7+run*0.1);
		end
		cfg_trans.write_neuron_config(neuron_config);
		start_time = $time;
		$display("Setting fixed current to %f, starting @%d",2.7+run*0.1,start_time);
		spike_trans.send_spikes();
		rates.push_back(count_and_print_spikes_and_rate(start_time,on_spikes,off_spikes));
		on_spikes = {};
		off_spikes = {};
		#10us;
	end
	fh = $fopen("rates.np");
	foreach (rates[i]) begin
		$fdisplay(fh,"%f",rates[i]);
	end
	$fclose(fh);
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
