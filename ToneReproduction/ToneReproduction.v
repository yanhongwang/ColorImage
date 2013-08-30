`include	"./Definition.v"

//float Lmin = 0, L1x = 5, L2x = 10, L3x = 50;
//float Lmax = 100, L1y = 10, L2y = 17.5, L3y = 55;
//float a1 = ( L1y - Lmin ) / ( L1x - Lmin ), a2 = ( L2y - L1y ) / ( L2x - L1x ), a3 = ( L3y - L2y ) / ( L3x - L2x ), a4 = ( Lmax - L3y ) / ( Lmax - L3x);
//float b1 = ( L1y - ( L1x * a1)), b2 = ( L1y - ( L1x * a2 )), b3 = ( L3y - ( L3x * a3 )), b4 = ( L3y - ( L3x * a4 ));

`define		Lmin	0
`define		L1x	8127
`define		L2x	16255
`define		L3x	81275
`define		Lmax	162550
`define		L1y	16255
`define		L2y	28446
`define		L3y	89402
`define		a1	   512
`define		a2	   384
`define		a3	   240
`define		a4	   230
`define		b1	   0
`define		b2	   640
`define		b3	   2080
`define		b4	   2560

module ToneReproduction
(
	
	input[ `size_int - 1 : 0 ]L,
	input[ `size_int - 1 : 0 ]IN_R,
	input[ `size_int - 1 : 0 ]IN_G,
	input[ `size_int - 1 : 0 ]IN_B,
	output reg[ `size_int - 1 : 0 ]OUT_R,
	output reg[ `size_int - 1 : 0 ]OUT_G,
	output reg[ `size_int - 1 : 0 ]OUT_B
	
);
	
	always@( L )
	begin
		
		if( L <= `L1x )
		begin
			
			OUT_R = ( ( IN_R * `a1 ) + `b1 );
			OUT_G = ( ( IN_G * `a1 ) + `b1 );
			OUT_B = ( ( IN_B * `a1 ) + `b1 );
			
		end
		else if( `L1x < L && L <= `L2x)
		begin
			
			OUT_R = ( ( IN_R * `a2 ) + `b2 );
			OUT_G = ( ( IN_G * `a2 ) + `b2 );
			OUT_B = ( ( IN_B * `a2 ) + `b2 );
			
		end
		else if( `L2x < L && L <= `L3x)
		begin
			
			OUT_R = ( ( IN_R * `a3 ) + `b3 );
			OUT_G = ( ( IN_G * `a3 ) + `b3 );
			OUT_B = ( ( IN_B * `a3 ) + `b3 );
			
		end
		else
		begin
			
			OUT_R = ( ( IN_R * `a4 ) + `b4 );
			OUT_G = ( ( IN_G * `a4 ) + `b4 );
			OUT_B = ( ( IN_B * `a4 ) + `b4 );
			
		end
		
	end
	
endmodule

module ToneReproduction_testbench;
	
	reg[ `size_int - 1 : 0 ]L;
	reg[ `size_int - 1 : 0 ]IN_R;
	reg[ `size_int - 1 : 0 ]IN_G;
	reg[ `size_int - 1 : 0 ]IN_B;
	wire[ `size_int - 1 : 0 ]OUT_R;
	wire[ `size_int - 1 : 0 ]OUT_G;
	wire[ `size_int - 1 : 0 ]OUT_B;
	
	ToneReproduction ToneReproduction_test( L, IN_R, IN_G, IN_B, OUT_R, OUT_G, OUT_B );
	
	initial
	begin
		
		//L = 58 * 256 * 6.3496042078727978990068225570775 = 94279
		//IN_R = 128 * 256 = 32768
		//IN_G = 90 * 256 = 23040
		//IN_B = 78 * 256 = 19968
		#10	
		begin
			L = 65019;
			IN_R = 32768;
			IN_G = 23040;
			IN_B = 19968;
		end
		
		#10     $display( "L = %d\tIN_R = %d\tIN_G = %d\tIN_B = %d", L, IN_R, IN_G, IN_B );
		#10     $display( "OUT_R = %d\tOUT_G = %d\tOUT_B = %d",OUT_R, OUT_G, OUT_B );
		#10     $stop;
		#10     $finish;
		
	end
	
endmodule

