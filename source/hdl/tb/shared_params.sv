class row_params;
	localparam logic[15:0] EL_SCALE = 128;
	fp::fpType El;
	fp::fpType Esyn;
	fp::fpType address;
	fp::fpType stdp_amplitude;
	fp::fpType stdp_timeconst;

	function new();
		El = 0;
		Esyn = 0;
		address = 0;
        stdp_amplitude = 0;
        stdp_timeconst = 0;
	endfunction

	function void set(integer p, real value);
		if (p==0)
			El = value;
		else if (p==1)
			Esyn = value;
		else if (p==3)
			stdp_amplitude = value;
		else if (p==4)
			stdp_timeconst = value;
    endfunction

	function void set_bio(integer p, real value);
		if (p==0)
			set(p,shortint'(value*EL_SCALE));
		else if (p==1)
			set(p,shortint'(value*EL_SCALE));
	endfunction

	function fp::fpType get(integer p);
		if (p==0)
			return El;
		else if (p==1)
			return Esyn;
		else if (p==2)
			return address;
		else if (p==3)
			return stdp_amplitude;
		else if (p==4)
			return stdp_timeconst;
	endfunction

	function void set_address(logic[7:0] addr);
		address[7:0] = addr;
	endfunction
endclass

class dendrite_params;
	fp::fpType tau_mem;
	fp::fpType g_int;

	localparam logic[15:0] TAU_MEM_SCALE = 32768;
	localparam logic[16:0] G_INT_SCALE = 512;

	function new();
		tau_mem = 0;
		g_int = 0;
	endfunction

	function void set_bio(integer p, real value);
		if (p==0) begin
			//$display("Setting tau_mem to %d with scale factor %d. %f,%f",shortint'(1.0/value*TAU_MEM_SCALE),TAU_MEM_SCALE,1.0/value*TAU_MEM_SCALE,value);
			tau_mem = shortint'(1.0/value*TAU_MEM_SCALE);
		end
		else if (p==1)
			g_int = shortint'(value*G_INT_SCALE);
	endfunction

	function fp::fpType get(integer p);
		if (p==0)
			return tau_mem;
		else if (p==1)
			return g_int;
	endfunction
endclass

class neuron_params;
	fp::fpType tau_mem, tau_ref, E_l, v_thresh,fixed_current;

	localparam logic[15:0] EL_SCALE = 128;
	localparam logic[15:0] CURRENT_SCALE = 128;
	localparam logic[15:0] VT_SCALE = 128;
	localparam logic[15:0] TAU_MEM_SCALE = 32768;
	localparam logic[15:0] TAU_REF_SCALE = 32768;

	function new();
		tau_mem = 0;
		tau_ref = 0;
		E_l = 0;
		v_thresh = 0;
		fixed_current = 0;
	endfunction

	function void set(integer p, fp::fpType value);
		if (p==0)
			E_l = value;
		else if (p==1)
			tau_mem = value;
		else if (p==2)
			v_thresh = value;
		else if (p==3)
			tau_ref = value;
		else if (p==4)
			fixed_current = value;
	endfunction

	function void set_bio(integer p, real value);
		if (p==0)
			E_l = shortint'(value*EL_SCALE);
		else if (p==1) begin
			//$display("Setting tau_mem to %d with scale factor %d. %f,%f",shortint'(1.0/value*TAU_MEM_SCALE),TAU_MEM_SCALE,1.0/value*TAU_MEM_SCALE,value);
			tau_mem = shortint'(1.0/value*TAU_MEM_SCALE);
		end
		else if (p==2)
			v_thresh = shortint'(value*VT_SCALE);
		else if (p==3)
			tau_ref = shortint'(value*TAU_REF_SCALE);
		else if (p==4)
			fixed_current = shortint'(value*CURRENT_SCALE);
	endfunction

	function fp::fpType get(integer p);
		if (p==0)
			return E_l;
		else if (p==1)
			return tau_mem;
		else if (p==2)
			return v_thresh;
		else if (p==3)
			return tau_ref;
		else if (p==4)
			return fixed_current;
	endfunction

	function void set_tau_mem(real value);
		set_bio(1,value);
	endfunction

	function void set_v_thresh(real value);
		set_bio(2,value);
	endfunction

	function void set_E_l(real value);
		set_bio(0,value);
	endfunction

	function void set_fixed_current(real value);
		set_bio(4,value);
	endfunction

	function fp::fpType get_tau_mem();
		return get(1);
	endfunction
endclass

class config_transactor #(
		NUM_SYNAPSE_ROWS=1,
		NUM_COLS=1,
		NUM_NEURON_PARAMS=5,
		NUM_SYNAPSE_PARAMS=2,
		NUM_DENDRITE_PARAMS=2,
		NUM_ROW_PARAMS=5
	);
	virtual config_if cfg_if[NUM_SYNAPSE_ROWS+1];

	function new (virtual config_if cfg[NUM_SYNAPSE_ROWS+1]);
		cfg_if = cfg;
	endfunction

	task write_neuron_config(neuron_params params[NUM_COLS]);
		for (integer n=0;n<NUM_COLS;n++) begin
			for (integer i=0;i<NUM_NEURON_PARAMS;i++) begin
				cfg_if[NUM_SYNAPSE_ROWS].data_clk = 1'b0;
				cfg_if[NUM_SYNAPSE_ROWS].data_in = params[NUM_COLS-n-1].get(NUM_NEURON_PARAMS-1-i);
				#2;
				cfg_if[NUM_SYNAPSE_ROWS].data_clk = 1'b1;
				#2;
			end
			if (n<NUM_COLS-1) begin
				cfg_if[NUM_SYNAPSE_ROWS].data_clk = 1'b0;
				#2;
				cfg_if[NUM_SYNAPSE_ROWS].data_clk = 1'b1;
				#2;
			end
		end
		//$display("Done configuring neurons @(%d)",$time);
	endtask

	task write_synapse_dendrite_config(row_params rows[NUM_SYNAPSE_ROWS], dendrite_params dendr[NUM_SYNAPSE_ROWS][NUM_COLS], synapse_params syn[NUM_SYNAPSE_ROWS][NUM_COLS*2]);
		for (integer col=0;col<NUM_COLS;col++) begin
			// synapse
			for (integer param=0;param<NUM_SYNAPSE_PARAMS;param++) begin
				for (integer row=0;row<NUM_SYNAPSE_ROWS;row++) begin
					cfg_if[row].data_clk = 1'b0;
					cfg_if[row].data_in = syn[row][NUM_COLS*2-col*2-1].get(NUM_SYNAPSE_PARAMS-1-param);
				end
				#2;
				for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
					cfg_if[row].data_clk = 1'b1;
				#2;
			end
			for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
				cfg_if[row].data_clk = 1'b0;
			#2;
			for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
				cfg_if[row].data_clk = 1'b1;
			#2;
			// dendrite
			for (integer param=0;param<NUM_DENDRITE_PARAMS;param++) begin
				for (integer row=0;row<NUM_SYNAPSE_ROWS;row++) begin
					cfg_if[row].data_clk = 1'b0;
					cfg_if[row].data_in = dendr[row][NUM_COLS-col-1].get(NUM_DENDRITE_PARAMS-1-param);
				end
				#2;
				for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
					cfg_if[row].data_clk = 1'b1;
				#2;
			end
			for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
				cfg_if[row].data_clk = 1'b0;
			#2;
			for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
				cfg_if[row].data_clk = 1'b1;
			#2;
			// synapse
			for (integer param=0;param<NUM_SYNAPSE_PARAMS;param++) begin
				for (integer row=0;row<NUM_SYNAPSE_ROWS;row++) begin
					cfg_if[row].data_clk = 1'b0;
					cfg_if[row].data_in = syn[row][NUM_COLS*2-col*2-2].get(NUM_SYNAPSE_PARAMS-1-param);
				end
				#2;
				for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
					cfg_if[row].data_clk = 1'b1;
				#2;
			end
			for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
				cfg_if[row].data_clk = 1'b0;
			#2;
			for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
				cfg_if[row].data_clk = 1'b1;
			#2;
		end
		// row global
		for (integer param=0;param<NUM_ROW_PARAMS;param++) begin
			for (integer row=0;row<NUM_SYNAPSE_ROWS;row++) begin
				cfg_if[row].data_clk = 1'b0;
				cfg_if[row].data_in = rows[row].get(NUM_ROW_PARAMS-1-param);
			end
			#2;
			for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
				cfg_if[row].data_clk = 1'b1;
			#2;
		end
		for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
			cfg_if[row].data_clk = 1'b0;
		#2;
		//for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
		//	cfg_if[row].data_clk = 1'b1;
		//#2;

	endtask

endclass

