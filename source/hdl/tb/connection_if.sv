interface connection_if();
    parameter NUM_SYNAPSE_ROWS = 1;
    parameter NUM_COLS = 1;

	logic[7:0] weights[NUM_SYNAPSE_ROWS][NUM_COLS];

endinterface
