`ifndef PARAMS_IF
`define PARAMS_IF

class synapse_params;
	fp::fpType gl_jump;
	fp::fpType general_config;

	localparam logic[15:0] GL_JUMP_SCALE = 512;
	localparam logic[15:0] TAU_GL_SCALE = 32768;

	function new();
		general_config = 0;
		gl_jump = 0;
	endfunction

	function void set_bio(integer p, real value);
		if (p==0)
			gl_jump = shortint'(value*GL_JUMP_SCALE);
	endfunction

	function void set(integer p, fp::fpType value);
		if (p==0)
			gl_jump = value;
	endfunction

	function fp::fpType get(integer p);
		//$display("Getting parameter number %d of row %d, col %d",p,row,col);
		if (p==0) begin
			//$display("Value %d",gl_jump[row][col]);
			return gl_jump;
		end
		else if (p==1) begin
			return general_config;
		end
	endfunction

	function void set_address(logic[7:0] addr);
		general_config[7:0] = addr;
	endfunction

	function logic[7:0] get_address();
		return general_config[7:0];
	endfunction
endclass



`endif //PARAMS_IF
