
interface system_if (input logic main_clk, config_clk);

    logic reset;

	modport nn (input main_clk, config_clk, reset);

endinterface
