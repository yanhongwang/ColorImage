`include	"./Definition.v"

// color correction registering constants
`define	CC1	430	// 860.0 / 512 * 256 = 10'b 0110101110
`define	CC2	127	// 253.0 / 512 * 256 = 10'b 0001111111
`define	CC3	48	//  95.0 / 512 * 256 = 10'b 0000110000
`define	CC4	55	// 109.0 / 512 * 256 = 10'b 0000110111
`define	CC5	464	// 928.0 / 512 * 256 = 10'b 0111010000
`define	CC6	154	// 307.0 / 512 * 256 = 10'b 0010011010
`define	CC7	10	//  20.0 / 512 * 256 = 10'b 0000001010
`define	CC8	145	// 290.0 / 512 * 256 = 10'b 0010010001
`define	CC9	391	// 782.0 / 512 * 256 = 10'b 0110000111

module ColorCorrection
(
	
	input[ `size_int - 1 : 0 ]R,
	input[ `size_int - 1 : 0 ]G,
	input[ `size_int - 1 : 0 ]B,
	
	output wire[ `size_int - 1 : 0 ]R_out,
	output wire[ `size_int - 1 : 0 ]G_out,
	output wire[ `size_int - 1 : 0 ]B_out
	
);
	
	reg[ `size_int : 0 ]R_int;
	reg[ `size_int : 0 ]G_int;
	reg[ `size_int : 0 ]B_int;
	
	always@( R or G or B )
	begin
		
		R_int = (  R * `CC1 - G * `CC2 - B * `CC3 ) >> `ScaleBit;
		G_int = ( -R * `CC4 + G * `CC5 - B * `CC6 ) >> `ScaleBit;
		B_int = (  R * `CC7 - G * `CC8 + B * `CC9 ) >> `ScaleBit;
		
	end
	
	assign R_out = ( R_int[ 17 : 16 ] == 2'b00 ) ? R_int : ( R_int[ 17 ] == 1'b1 ) ? `MinThreshold : `MaxThreshold;
	assign G_out = ( G_int[ 17 : 16 ] == 2'b00 ) ? G_int : ( G_int[ 17 ] == 1'b1 ) ? `MinThreshold : `MaxThreshold;
	assign B_out = ( B_int[ 17 : 16 ] == 2'b00 ) ? B_int : ( B_int[ 17 ] == 1'b1 ) ? `MinThreshold : `MaxThreshold;
	
endmodule

module ColorCorrection_testbench;
	
	reg[ `size_int - 1 : 0 ]R;
	reg[ `size_int - 1 : 0 ]G;
	reg[ `size_int - 1 : 0 ]B;
	
	wire[ `size_int - 1 : 0 ]R_out;
	wire[ `size_int - 1 : 0 ]G_out;
	wire[ `size_int - 1 : 0 ]B_out;
	
	ColorCorrection ColorCorrection_test( R, G, B, R_out, G_out, B_out );
	
	initial
	begin
		
		#100
		begin
			
			R = 200 << `ScaleBit;
			G = 0 << `ScaleBit;
			B = 0 << `ScaleBit;
			
		end
		
	//X=(200*( 860.0/512)+0*(-253.0/512)+0*( -95.0/512))*256=86000
	//Y=(200*(-109.0/512)+0*( 928.0/512)+0*(-307.0/512))*256=-10900
	//Z=(200*(  20.0/512)+0*(-290.0/512)+0*( 782.0/512))*256=2000
		
		#100	$display( "R_out = %d", R_out );
		#100	$display( "G_out = %d", G_out );
		#100	$display( "B_out = %d", B_out );
		
		#100
		begin
			
			R = 200 << `ScaleBit;
			G = 180 << `ScaleBit;
			B = 160 << `ScaleBit;
			
		end
		
	//X=(200*( 860.0/512)+180*(-253.0/512)+160*( -95.0/512))*256=55630
	//Y=(200*(-109.0/512)+180*( 928.0/512)+160*(-307.0/512))*256=48060
	//Z=(200*(  20.0/512)+180*(-290.0/512)+160*( 782.0/512))*256=38460
		
		#100	$display( "R_out = %d", R_out );
		#100	$display( "G_out = %d", G_out );
		#100	$display( "B_out = %d", B_out );
		
		#100    $stop;
		#100    $finish;
		
	end
	
endmodule
