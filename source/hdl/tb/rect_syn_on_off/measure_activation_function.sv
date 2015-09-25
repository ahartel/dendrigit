`include "basic_test_class.sv"
typedef real rates_queue[$];

class measure_activation_function extends basic_test_class;
	time start_times[$];

	function new(virtual system_if sys_if,
				 virtual tb_clk_if tb_clk,
	             virtual config_if cfg_in[NUM_SYNAPSE_ROWS+1],
				 virtual spike_if spike_in[NUM_SYNAPSE_ROWS],
				 virtual connection_if #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS)) connect);
		super.new(sys_if,tb_clk,cfg_in,spike_in,connect);
	endfunction


	function rates_queue count_and_print_spikes_and_rate(
		integer on_spikes[$],
		integer off_spikes[$]
	);
		real rates[$];
		time previous_start_time, start_time;
		integer spike_count;

		$display("Number of on-spikes : %d",on_spikes.size());
		$display("Number of off-spikes: %d",off_spikes.size());

		spike_count = 0;
		start_time = start_times.pop_front();
		previous_start_time = 0;
		for (integer i=0; i<on_spikes.size(); i++) begin
			// if we're beyond the next start_time
			if (on_spikes[i] >= start_times[0]) begin
				if (previous_start_time > 0) begin
					rates.push_back(real'(spike_count)*1000.0/
									real'(start_time-previous_start_time));
					$display("Spike rate: %f in delta-t: %d",
							 rates[$],start_time-previous_start_time);
				end
				if (start_times.size() == 0)
					break;
				previous_start_time = start_time;
				start_time = start_times.pop_front();
				spike_count = 0;
			end
			if (on_spikes[i] >= start_time) begin
				spike_count += 1;
			end
		end
		return rates;
	endfunction

	function void prepare();

		/*
		// Set up weights
		*/
		for (integer r=0;r<NUM_SYNAPSE_ROWS;r++) begin
			for (integer c=0; c<NUM_COLS; c++) begin
				connections.weights[r][c] = 0;
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
			neuron_config[c].set_E_l(-50);
			neuron_config[c].set_tau_mem(80);
			//neuron_config[c].set_v_thresh(-40);
			neuron_config[c].set(2,-1000); //thresh
			neuron_config[c].set(3,10); // tau_ref
			neuron_config[c].set_fixed_current(10);
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

	endfunction


	task test();
		/*
		// now the simulation time starts
		*/
		sys_if.reset = 1'b1;
		tb_clk.start_fast_clock = 1'b1;
		#2us;
		tb_clk.start_fast_clock = 1'b0;
		#2us;
		sys_if.reset = 1'b0;
		#2us;
		tb_clk.start_fast_clock = 1'b1;
		cfg_trans.write_synapse_dendrite_config(row_config,dendrite_config,synapse_config);
		/*
		// run the loop to measure the activation function
		*/
		for (real current=3.5; current<5.5; current=current+0.05) begin
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
				neuron_config[c].set_fixed_current(current);
			end
			cfg_trans.write_neuron_config(neuron_config);
			start_times.push_back($time);
			$display("Setting fixed current to %f, starting @%d",
					 current,start_times[$]);
			spike_trans.send_spikes();
			#10us;
		end

	endtask

	function void evaluate(integer on_spikes[$], integer off_spikes[$]);
		rates_queue rates;
		integer fh;
		rates = count_and_print_spikes_and_rate(on_spikes,off_spikes);
		fh = $fopen("rates.np");
		foreach (rates[i]) begin
			$fdisplay(fh,"%f",rates[i]);
		end
		$fclose(fh);
		$finish();
	endfunction
endclass
