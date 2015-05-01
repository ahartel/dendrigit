`ifndef PARAMS_IF
`define PARAMS_IF

class neuron_params #(int NUM_COLS=1);
	fp::fpType tau_mem[NUM_COLS];

	function new();
		for (integer n=0;n<NUM_COLS;n++) begin
			tau_mem[n] = 0;
		end
	endfunction

	function void set(integer col, integer p, logic[31:0] value);
		if (p==0) begin
			tau_mem[col] = value;
		end
	endfunction

	function fp::fpType get(integer col, integer p);
		if (p==0) begin
			return tau_mem[col];
		end
	endfunction
endclass

class synapse_params #(int NUM_SYNAPSE_ROWS=1,int NUM_COLS=1);
	fp::fpType El[NUM_SYNAPSE_ROWS][NUM_COLS*2];
	fp::fpType gl_jump[NUM_SYNAPSE_ROWS][NUM_COLS*2];
	fp::fpType tau_gl[NUM_SYNAPSE_ROWS][NUM_COLS*2];

	localparam logic[15:0] EL_SCALE = 64;
	localparam logic[15:0] GL_JUMP_SCALE = 1;
	localparam logic[15:0] TAU_GL_SCALE = 32768;

	function new();
		for (integer r=0;r<NUM_SYNAPSE_ROWS;r++) begin
			for (integer n=0;n<NUM_COLS*2;n++) begin
				El[r][n] = 0;
				gl_jump[r][n] = 0;
				tau_gl[r][n] = 0;
			end
		end
	endfunction

	function void set_bio(integer row, integer col, integer p, real value);
		if (p==0)
			El[row][col] = shortint'(value*EL_SCALE);
		else if (p==1)
			gl_jump[row][col] = shortint'(value*GL_JUMP_SCALE);
		else if (p==2)
			tau_gl[row][col] = shortint'(1.0/value*TAU_GL_SCALE);
	endfunction

	function void set(integer row, integer col, integer p, fp::fpType value);
		if (p==0)
			El[row][col] = value;
		else if (p==1)
			gl_jump[row][col] = value;
		else if (p==2)
			tau_gl[row][col] = value;
	endfunction

	function fp::fpType get(integer row, integer col, integer p);
		$display("Getting parameter number %d of row %d, col %d",p,row,col);
		if (p==0) begin
			$display("Value %d",El[row][col]);
			return El[row][col];
		end
		else if (p==1) begin
			$display("Value %d",gl_jump[row][col]);
			return gl_jump[row][col];
		end
		else if (p==2) begin
			$display("Value %d",tau_gl[row][col]);
			return tau_gl[row][col];
		end
	endfunction
endclass

class dendrite_params #(int NUM_SYNAPSE_ROWS=1,int NUM_COLS=1);
	fp::fpType El[NUM_SYNAPSE_ROWS][NUM_COLS];
	fp::fpType tau_mem[NUM_SYNAPSE_ROWS][NUM_COLS];

	localparam logic[15:0] EL_SCALE = 64;
	localparam logic[15:0] TAU_MEM_SCALE = 32768;

	function new();
		for (integer r=0;r<NUM_SYNAPSE_ROWS;r++) begin
			for (integer n=0;n<NUM_COLS;n++) begin
				El[r][n] = 0;
				tau_mem[r][n] = 0;
			end
		end
	endfunction

	function void set_bio(integer row, integer col, integer p, real value);
		if (p==0)
			El[row][col] = shortint'(value*EL_SCALE);
		else if (p==1)
			tau_mem[row][col] = shortint'(1.0/value*TAU_MEM_SCALE);
	endfunction

	function fp::fpType get(integer row, integer col, integer p);
		if (p==0) begin
			return El[row][col];
		end
		else if (p==1) begin
			return tau_mem[row][col];
		end
	endfunction
endclass

class config_transactor #(NUM_SYNAPSE_ROWS=1,NUM_COLS=1,NUM_NEURON_PARAMS=1,NUM_SYNAPSE_PARAMS=3,NUM_DENDRITE_PARAMS=2);
	virtual config_if cfg_if[NUM_SYNAPSE_ROWS+1];

	function new (virtual config_if cfg[NUM_SYNAPSE_ROWS+1]);
		cfg_if = cfg;
	endfunction

	task write_neuron_config(neuron_params #(.NUM_COLS(NUM_COLS)) params);
		for (integer n=0;n<NUM_COLS;n++) begin
			for (integer i=0;i<NUM_NEURON_PARAMS;i++) begin
				cfg_if[NUM_SYNAPSE_ROWS].data_clk = 1'b0;
				cfg_if[NUM_SYNAPSE_ROWS].data_in = params.get(NUM_COLS-n-1,NUM_NEURON_PARAMS-1-i);
				#2;
				cfg_if[NUM_SYNAPSE_ROWS].data_clk = 1'b1;
				#2;
			end
			cfg_if[NUM_SYNAPSE_ROWS].data_clk = 1'b0;
			#2;
			cfg_if[NUM_SYNAPSE_ROWS].data_clk = 1'b1;
			#2;
		end
		$display("Done configuring neurons @(%d)",$time);
	endtask

	task write_synapse_dendrite_config(dendrite_params#(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS)) dendr, synapse_params #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS)) syn);
		for (integer col=0;col<NUM_COLS;col++) begin
			// synapse
			for (integer param=0;param<NUM_SYNAPSE_PARAMS;param++) begin
				for (integer row=0;row<NUM_SYNAPSE_ROWS;row++) begin
					cfg_if[row].data_clk = 1'b0;
					cfg_if[row].data_in = syn.get(row,NUM_COLS*2-col*2-1,NUM_SYNAPSE_PARAMS-1-param);
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
					cfg_if[row].data_in = dendr.get(row,NUM_COLS-col-1,NUM_DENDRITE_PARAMS-1-param);
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
					cfg_if[row].data_in = syn.get(row,NUM_COLS*2-col*2-2,NUM_SYNAPSE_PARAMS-1-param);
				end
				#2;
				for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
					cfg_if[row].data_clk = 1'b1;
				#2;
			end
			if (col < NUM_COLS-1) begin
				for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
					cfg_if[row].data_clk = 1'b0;
				#2;
				for (integer row=0;row<NUM_SYNAPSE_ROWS;row++)
					cfg_if[row].data_clk = 1'b1;
				#2;
			end
		end
	endtask

endclass

`endif //PARAMS_IF
