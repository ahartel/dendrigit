`include "spikes.sv"

class basic_test_class;
	neuron_params neuron_config[NUM_COLS];
	dendrite_params dendrite_config[NUM_SYNAPSE_ROWS][NUM_COLS];
	synapse_params synapse_config[NUM_SYNAPSE_ROWS][NUM_COLS*2];
	row_params row_config[NUM_SYNAPSE_ROWS];
	virtual connection_if #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS)) connections;
    virtual system_if sys_if;
    virtual tb_clk_if tb_clk;

	config_transactor #(
		.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),
		.NUM_COLS(NUM_COLS),
		.NUM_SYNAPSE_PARAMS(2)
	) cfg_trans;
	spike_transactor #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS)) spike_trans;

	function new(virtual system_if sys_if,
				 virtual tb_clk_if tb_clk,
                 virtual config_if cfg_in[NUM_SYNAPSE_ROWS+1],
				 virtual spike_if spike_in[NUM_SYNAPSE_ROWS],
				 virtual connection_if #(.NUM_SYNAPSE_ROWS(NUM_SYNAPSE_ROWS),.NUM_COLS(NUM_COLS)) connect);
        this.sys_if = sys_if;
        this.tb_clk = tb_clk;
		cfg_trans = new(cfg_in);
		spike_trans = new(spike_in,tb_clk);
		connections = connect;
	endfunction

endclass
