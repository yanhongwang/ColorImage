`include	"./Definition.v"
`define		HighThreshold	( 250 << `ScaleBit )
`define		LowThreshold	( 5 << `ScaleBit )
`define		AutoLevelRange	( `HighThreshold - `LowThreshold )
`define		Scale		( 256 << `ScaleBit ) / `AutoLevelRange
// The priority of the combination of operator shift is lower than +-*/
// To avoid that, you may add parenthesis between the operation of operator shift

module AutoLevel( R, G, B, R_out, G_out, B_out );
	
	input[ `size_int - 1 : 0 ]R;
	input[ `size_int - 1 : 0 ]G;
	input[ `size_int - 1 : 0 ]B;
	
	output wire[ `size_int - 1 : 0 ]R_out;
	output wire[ `size_int - 1 : 0 ]G_out;
	output wire[ `size_int - 1 : 0 ]B_out;
	
	reg[ `size_int - 1 : 0 ]Rtemp;
	reg[ `size_int - 1 : 0 ]Gtemp;
	reg[ `size_int - 1 : 0 ]Btemp;
	
	always@( R )
	begin
		
		if( ( R > `LowThreshold ) && ( R < `HighThreshold ) )
			Rtemp = `Scale * ( R - `LowThreshold );
		else if( R <= `LowThreshold )
			Rtemp = `MinThreshold;
		else	// R >= `HighThreshold
			Rtemp = `MaxThreshold;
		
	end	
	
	always@( G )
	begin
		
		if( ( G > `LowThreshold ) && ( G < `HighThreshold ) )
			Gtemp = `Scale * ( G - `LowThreshold );
		else if( G <= `LowThreshold )
			Gtemp = `MinThreshold;
		else	// G >= `HighThreshold
			Gtemp = `MaxThreshold;
		
	end	
	
	always@( B )
	begin
		
		if( ( B > `LowThreshold ) && ( B < `HighThreshold ) )
			Btemp = `Scale * ( B - `LowThreshold );
		else if( B <= `LowThreshold )
			Btemp = `MinThreshold;
		else	// B >= `HighThreshold
			Btemp = `MaxThreshold;
		
	end
	
	
	assign R_out = Rtemp;
	assign G_out = Gtemp;
	assign B_out = Btemp;
	
endmodule

module AutoLevel_testbench;
	
	reg[ `size_int - 1 : 0 ]R;
	reg[ `size_int - 1 : 0 ]G;
	reg[ `size_int - 1 : 0 ]B;
	
	wire[ `size_int - 1 : 0 ]R_out;
	wire[ `size_int - 1 : 0 ]G_out;
	wire[ `size_int - 1 : 0 ]B_out;
	
	AutoLevel AutoLevel_test( R, G, B, R_out, G_out, B_out );
	
	initial
	begin
		
		#10	R = 2 << `ScaleBit;
		#10	$display( "old R = %d\tnew R = %d", R, R_out );
		
		#10	R = 50 << `ScaleBit;
		#10	$display( "old R = %d\tnew R = %d", R, R_out );
		
		#10	R = 252 << `ScaleBit;
		#10	$display( "old R = %d\tnew R = %d", R, R_out );
		
		#10	G = 1 << `ScaleBit;
		#10	$display( "old G = %d\tnew G = %d", G, G_out );
		
		#10	G = 140 << `ScaleBit;
		#10	$display( "old G = %d\tnew G = %d", G, G_out );
		
		#10	G = 254 << `ScaleBit;
		#10	$display( "old G = %d\tnew G = %d", G, G_out );
		
		#10	B = 4 << `ScaleBit;
		#10	$display( "old B = %d\tnew B = %d", B, B_out );
		
		#10	B = 70 << `ScaleBit;
		#10	$display( "old B = %d\tnew B = %d", B, B_out );
		
		#10	B = 251 << `ScaleBit;
		#10	$display( "old B = %d\tnew B = %d", B, B_out );
		
		#10	$stop;
		#10	$finish;
		
	end
	
endmodule

