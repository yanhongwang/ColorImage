`include	"./Definition.v"

// XYZ2RGB
`define		XYZ2RGB1	830	// 3.240479 * `ScaleNumber = 829.562624
`define		XYZ2RGB2	394	// 1.537150 * `ScaleNumber = 393.5104
`define		XYZ2RGB3	128	// 0.498535 * `ScaleNumber = 127.62496
`define		XYZ2RGB4	248	// 0.969256 * `ScaleNumber = 248.129536
`define		XYZ2RGB5	480	// 1.875992 * `ScaleNumber = 480.253952
`define		XYZ2RGB6	11	// 0.041556 * `ScaleNumber = 10.638336
`define		XYZ2RGB7	14	// 0.055648 * `ScaleNumber = 14.245888
`define		XYZ2RGB8	52	// 0.204043 * `ScaleNumber = 52.235008
`define		XYZ2RGB9	271	// 1.057311 * `ScaleNumber = 270.671616
//16 * 6.3496042078727978990068225569719 * `ScaleNumber = 26007.978835446980194331945193353
`define		pow_16_256_1_3	26008

`define		Lab2RGBLimit	53	// 0.206893 * ScaleNumber = 52.964608

module BackwardSpace//( CIEL, CIEa, CIEb, R, G, B );
(
	
	input[ `size_int - 1 : 0 ]CIEL,
	input signed[ `size_int - 1 : 0 ]CIEa,
	input signed[ `size_int - 1 : 0 ]CIEb,
	
	output reg[ `size_int - 1 : 0 ]R,
	output reg[ `size_int - 1 : 0 ]G,
	output reg[ `size_int - 1 : 0 ]B
	
);
	
	reg[ `size_int - 1 : 0 ]RR;
	reg[ `size_int - 1 : 0 ]GG;
	reg[ `size_int - 1 : 0 ]BB;
	
	reg[ `size_int - 1 : 0 ]X;
	reg[ `size_int - 1 : 0 ]Y;
	reg[ `size_int - 1 : 0 ]Z;
	
	reg[ `size_int - 1 : 0 ]fX;
	reg[ `size_int - 1 : 0 ]fY;
	reg[ `size_int - 1 : 0 ]fZ;
	
	always@( CIEL or CIEa or CIEb )
	begin
		
		// proto type formulation
		// fY = ( CIEL + pow_16_256_1_3 ) / 116;
		// fX = CIEa / 500 + fY;
		// fZ = fY - CIEb / 200;
		
		// fY = ( ( CIEL + pow_16_256_1_3 ) / 116 ) << ( `ScaleBit + `ScaleBit );
		// fX = ( ( CIEa / 500 ) << ( `ScaleBit + `ScaleBit ) ) + fY;
		// fZ = fY - ( CIEb / 200 ) << ( `ScaleBit + `ScaleBit );
		
		// avoid usage of the division
		fY = ( CIEL + `pow_16_256_1_3 ) * 565;
		fX = CIEa * 131 + fY;
		fZ = fY - CIEb * 328;
		
		// avoid extreme case of fY
		if( fY < `Lab2RGBLimit )
			fY = `Lab2RGBLimit;
		// avoid extreme case of fX
		if( fX < `Lab2RGBLimit )
			fX = `Lab2RGBLimit;
		
		// avoid extreme case of fZ
		if( fZ < `Lab2RGBLimit )
			fZ = `Lab2RGBLimit;
		
		// in case of over-range of power 3 operation later
		// fY = fY >> `ScaleHalfBit;
		fY = fY >> ( `ScaleHalfBit + `ScaleBit + `ScaleBit );
		Y = fY * fY * fY;
		Y = ( Y * 255 ) >> `ScaleBit;
		
		// in case of over-range of power 3 operation later
		// fX = fX >> `ScaleHalfBit;
		fX = fX >> ( `ScaleHalfBit + `ScaleBit + `ScaleBit );
		X = fX * fX * fX;
		X = ( X * 242 ) >> `ScaleBit;
		
		// in case of over-range of power 3 operation later
		// fZ = fZ >> `ScaleHalfBit;
		fZ = fZ >> ( `ScaleHalfBit + `ScaleBit + `ScaleBit );
		Z = fZ * fZ * fZ;
		Z = ( Z * 278 ) >> `ScaleBit;
		
		RR = (  `XYZ2RGB1 * X - `XYZ2RGB2 * Y - `XYZ2RGB3 * Z )
		>> ( `ScaleBit + `ScaleHalfBit );
		GG = ( -`XYZ2RGB4 * X + `XYZ2RGB5 * Y + `XYZ2RGB6 * Z )
		>> ( `ScaleBit + `ScaleHalfBit );
		BB = (  `XYZ2RGB7 * X - `XYZ2RGB8 * Y + `XYZ2RGB9 * Z )
		>> ( `ScaleBit + `ScaleHalfBit );
		
		R = ( RR[ 17 : 16 ] == 2'b00 ) ? RR : ( RR[ 17 ] == 1'b1 ) ? `MinThreshold : `MaxThreshold;
		G = ( GG[ 17 : 16 ] == 2'b00 ) ? GG : ( GG[ 17 ] == 1'b1 ) ? `MinThreshold : `MaxThreshold;
		B = ( BB[ 17 : 16 ] == 2'b00 ) ? BB : ( BB[ 17 ] == 1'b1 ) ? `MinThreshold : `MaxThreshold;
		
	end
	
endmodule

module BackwardSpace_testbench;
	
	reg[ `size_int - 1 : 0 ]CIEL;
	reg signed[ `size_int - 1 : 0 ]CIEa;
	reg signed[ `size_int - 1 : 0 ]CIEb;
	
	wire[ `size_int - 1 : 0 ]R;
	wire[ `size_int - 1 : 0 ]G;
	wire[ `size_int - 1 : 0 ]B;
	
	BackwardSpace BackwardSpace_test( CIEL, CIEa, CIEb, R, G, B );
	
	initial
	begin
		
		$monitor( "CIEL = %d, CIEa = %d, CIEb = %d, R = %d, G = %d, B = %d",
				CIEL, CIEa, CIEb, R, G, B );
		
		#100
		begin
		
		// proto formulation
		// CIEL = ( 80 << `ScaleBit ) * 6.3496042078727978990068225569719;	// 130040
		// CIEa = ( 20 << `ScaleBit ) * 6.3496042078727978990068225569719;	// 32509
		// CIEb = ( 30 << `ScaleBit ) * 6.3496042078727978990068225569719;	// 48765
		
		CIEL = 130040;
		CIEa = 32509;
		CIEb = 48765;
		
		end
		
		#100
		begin
		
		// proto formulation
		// CIEL = ( 50 << `ScaleBit ) * 6.3496042078727978990068225569719;	// 81275
		// CIEa = ( 10 << `ScaleBit ) * 6.3496042078727978990068225569719;	// 16255
		// CIEb = ( 20 << `ScaleBit ) * 6.3496042078727978990068225569719;	// 32510
		
		CIEL = 81275;
		CIEa = 16255;
		CIEb = 32510;
		
		end
		
		#100    $stop;
		#100    $finish;
		
	end
	
endmodule

