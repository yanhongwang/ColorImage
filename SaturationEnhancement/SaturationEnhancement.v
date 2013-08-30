`include	"./Definition.v"

// amin =  -86, amax = 98
// bmin = -108, bmax = 94
// 86 + 98 + 1 = 185
// 108 + 94 + 1 = 203

`define		SE_a	282	// 1.1 * `ScaleNumber = 281.6
`define		SE_b	282	// 1.1 * `ScaleNumber = 281.6

module SaturationEnhancement
(
	
	input signed[ `size_int - 1 : 0 ]CIEa,
	input signed[ `size_int - 1 : 0 ]CIEb,
	
	output wire signed[ `size_int - 1 : 0 ]CIEa_out,
	output wire signed[ `size_int - 1 : 0 ]CIEb_out
	
);
	
	assign	CIEa_out = ( CIEa * `SE_a ) >> `ScaleBit;
	assign	CIEb_out = ( CIEb * `SE_b ) >> `ScaleBit;
	
endmodule

module SaturationEnhancement_testbench;
	
	reg signed[ `size_int - 1 : 0 ]CIEa;
	reg signed[ `size_int - 1 : 0 ]CIEb;
	
	wire signed[ `size_int - 1 : 0 ]CIEa_out;
	wire signed[ `size_int - 1 : 0 ]CIEb_out;
	
	SaturationEnhancement SaturationEnhancement_test( CIEa, CIEb, CIEa_out, CIEb_out );
	
	initial
	begin
		
		// CIEa = 32 * 256 * 6.3496042078727978990068225570775 = 52016
		#10	CIEa = 52016;
		#10     $display( "old CIEa = %d\tnew CIEa = %d", CIEa, CIEa_out );
		
		// CIEb = 17 * 256 * 6.3496042078727978990068225570775 = 27634
		#10	CIEb = 27634;
		#10	$display( "old CIEb = %d\tnew CIEb = %d", CIEb, CIEb_out );
		
		#10     $stop;
		#10     $finish;
		
	end
	
endmodule

