
module synapse_to_dendrite_current(
	input fp::fpType vmem,
	input fp::fpType E_rev,
	input fp::fpType gsyn,
	output logic[fp::WORD_LENGTH*2+1-1:0] output_current
);
	fp::fpType E_rev_vmem_diff;

	DW01_sub #(.width(fp::WORD_LENGTH)) SUB_EREV_VMEM (
		.A(E_rev),
		.B(vmem),
		.CI(1'b0),
		.CO(),
		.DIFF(E_rev_vmem_diff)
	);
	DW02_mult   #(.A_width(fp::WORD_LENGTH),.B_width(fp::WORD_LENGTH+1)) U2(.A(E_rev_vmem_diff),.B({1'b0,gsyn}),.PRODUCT(output_current),.TC(1'b1));


endmodule
