`include	"Definition.v"
`include	"ProcessProperty.v"

// 1. input and output should be combined together into inout
// 2. look up table should be research more elaborate skill

module ColorImageProcess
(
	
	input Clock,
	input Reset,
	
	input[ `size_char - 1 : 0 ]R,
	input[ `size_char - 1 : 0 ]G,
	input[ `size_char - 1 : 0 ]B,
	
	output[ `size_char - 1 : 0 ]R_out,
	output[ `size_char - 1 : 0 ]G_out,
	output[ `size_char - 1 : 0 ]B_out
	
);
	
	// scale rgb
	reg[ `size_int - 1 : 0 ]ScaleR;
	reg[ `size_int - 1 : 0 ]ScaleG;
	reg[ `size_int - 1 : 0 ]ScaleB;
	reg[ `size_int - 1 : 0 ]ScaleRTemp;
	reg[ `size_int - 1 : 0 ]ScaleGTemp;
	reg[ `size_int - 1 : 0 ]ScaleBTemp;
	
	// counter
	integer PixelCount;
	
	// Auto Level
	reg[ `size_int - 1 : 0 ]ALR;
	reg[ `size_int - 1 : 0 ]ALG;
	reg[ `size_int - 1 : 0 ]ALB;
	
	// CTC
	reg[ `size_int - 1 : 0 ]WBR;
	reg[ `size_int - 1 : 0 ]WBG;
	reg[ `size_int - 1 : 0 ]WBB;
	reg[ `size_int - 1 : 0 ]RFactor;
	reg[ `size_int - 1 : 0 ]BFactor;
	reg[ `size_int + `size_int - 1 : 0 ]RLongTotal;
	reg[ `size_int + `size_int - 1 : 0 ]GLongTotal;
	reg[ `size_int + `size_int - 1 : 0 ]BLongTotal;
	reg[ `size_int - 1 : 0 ]RTotal;
	reg[ `size_int - 1 : 0 ]GTotal;
	reg[ `size_int - 1 : 0 ]BTotal;
	// divider usage
	reg[ `size_int - 1 : 0 ]GRIndex;
	reg[ `size_int - 1 : 0 ]GBIndex;
	
	// color correction
	reg[ `size_int - 1 : 0 ]CCR;
	reg[ `size_int - 1 : 0 ]CCG;
	reg[ `size_int - 1 : 0 ]CCB;
	
	// color space
	reg[ `size_int - 1 : 0 ]CIEL;
	// declaration is signed type, a or b maybe negative value
	reg signed[ `size_int - 1 : 0 ]CIEa;
	reg signed[ `size_int - 1 : 0 ]CIEb;
	reg signed[ `size_int - 1 : 0 ]CIEa_input;
	reg signed[ `size_int - 1 : 0 ]CIEb_input;
	reg[ `size_int - 1 : 0 ]X;
	reg[ `size_int - 1 : 0 ]Y;
	reg[ `size_int - 1 : 0 ]Z;
	reg[ `size_int - 1 : 0 ]fX;
	reg[ `size_int - 1 : 0 ]fY;
	reg[ `size_int - 1 : 0 ]fZ;
	
	// gamma correction
	reg[ `size_int - 1 : 0 ]GCR;
	reg[ `size_int - 1 : 0 ]GCG;
	reg[ `size_int - 1 : 0 ]GCB;
	
	reg[ 1 : 0 ]State;
	reg[ 1 : 0 ]NextState;
	
	// state declaration
	parameter InitialState = 0;	// initialization
	parameter WBFactorState = 1;	// calculate white balance factor
	parameter ProcessState = 2;	// implement all process
	parameter FinishState = 3;	// image process is complete
	
	// sequential state register
	always@( posedge Clock )
	begin
		
		if( Reset == 1 )
			State = InitialState;
		else
			State = NextState;
		
	end
	
	////////////////
	// read raw data
	always@( posedge Clock )
	begin
		
		ScaleR = R << `ScaleBit;
		ScaleG = G << `ScaleBit;
		ScaleB = B << `ScaleBit;
		
	end
	
	/////////////
	// auto level
	always@( posedge Clock )
	begin
		
		if( ( ScaleR > `LowThreshold ) && ( ScaleR < `HighThreshold ) )
			ALR = `ALFactor * ( ScaleR - `LowThreshold );
		else if( ScaleR <= `LowThreshold )
			ALR = `MinThreshold;
		else	// ScaleR >= `HighThreshold
			ALR = `MaxThreshold;
		
		if( ( ScaleG > `LowThreshold ) && ( ScaleG < `HighThreshold ) )
			ALG = `ALFactor * ( ScaleG - `LowThreshold );
		else if( ScaleG <= `LowThreshold )
			ALG = `MinThreshold;
		else	// ScaleG >= `HighThreshold
			ALG = `MaxThreshold;
		
		if( ( ScaleB > `LowThreshold ) && ( ScaleB < `HighThreshold ) )
			ALB = `ALFactor * ( ScaleB - `LowThreshold );
		else if( ScaleB <= `LowThreshold )
			ALB = `MinThreshold;
		else	// ScaleB >= `HighThreshold
			ALB = `MaxThreshold;
		
	end
	
	// next state and outputs, combinational always block
	always@( posedge Clock )
	begin
		
		case( State )
		
		/////////////////
		// initialization
		InitialState :
		begin
			
			RLongTotal = 0;
			GLongTotal = 0;
			BLongTotal = 0;
			
			PixelCount = 0;
			
			NextState = WBFactorState;
			
		end
		
		/////////////////////////////////
		// calculate white balance factor
		WBFactorState :
		begin
			
			if( PixelCount == `SumPixel )
			begin
				
				NextState = ProcessState;
				PixelCount = 0;
				
			end
			else
			begin
				
				PixelCount = PixelCount + 1;
				
				RLongTotal = RLongTotal + ALR;
				GLongTotal = GLongTotal + ALG;
				BLongTotal = BLongTotal + ALB;
				
				RTotal = RLongTotal >> `ScaleHalfBit;
				GTotal = GLongTotal >> `ScaleHalfBit;
				BTotal = BLongTotal >> `ScaleHalfBit;
				
				// GR ratio, scale = 16
				GRIndex = Divider( GTotal, RTotal >> `ScaleHalfBit );
				
				// GB ratio, scale = 16
				GBIndex = Divider( GTotal, BTotal >> `ScaleHalfBit );
				
				if( ( GRIndex >= 16 ) && ( GRIndex <= 40 ) )
					GRIndex = GRIndex - 16;
				else if( GRIndex < 16 )
					GRIndex = 0;
				else
					GRIndex = 23;
				
				if( ( GBIndex >= 16 ) && ( GBIndex <= 40 ) )
					GBIndex = GBIndex - 16;
				else if( GBIndex < 16 )
					GBIndex = 0;
				else
					GBIndex = 23;
				
				LUTCTCFactor( GRIndex * 24 + GBIndex, RFactor, BFactor );
				
			//	RFactor = ( RFactor * `WBRCorrection ) >> `ScaleBit;
			//	BFactor = ( BFactor * `WBBCorrection ) >> `ScaleBit;
				
			end
			
		end
		
		ProcessState :
		begin
			
			// delay twice total pixel count
			// wait for writing file into file during testbench simulation
			if( PixelCount == ( `SumPixel << 2 ) )
			begin
				
				NextState = FinishState;
				PixelCount = 0;
				
			end
			else
			begin
				
				PixelCount = PixelCount + 1;
				
				////////////////
				// white balance
				WBR = ( ALR * RFactor ) >> `ScaleBit;
				WBG = ALG;
				WBB = ( ALB * BFactor ) >> `ScaleBit;
				
				if( WBR[ 16 ] == 1 )
					WBR = `MaxThreshold;
				
				if( WBB[ 16 ] == 1 )
					WBB = `MaxThreshold;
				
				///////////////////
				// color correction
				CCR = (  WBR * `CC1 - WBG * `CC2 - WBB * `CC3 ) >> `ScaleBit;
				CCG = ( -WBR * `CC4 + WBG * `CC5 - WBB * `CC6 ) >> `ScaleBit;
				CCB = (  WBR * `CC7 - WBG * `CC8 + WBB * `CC9 ) >> `ScaleBit;
				
				CCR = ( CCR[ 17 : 16 ] == 2'b00 ) ? CCR : ( CCR[ 17 ] == 1'b1 ) ? `MinThreshold : `MaxThreshold;
				CCG = ( CCG[ 17 : 16 ] == 2'b00 ) ? CCG : ( CCG[ 17 ] == 1'b1 ) ? `MinThreshold : `MaxThreshold;
				CCB = ( CCB[ 17 : 16 ] == 2'b00 ) ? CCB : ( CCB[ 17 ] == 1'b1 ) ? `MinThreshold : `MaxThreshold;
				
				////////////////
				// forward space
				// 256 * 0.950456 * 256
				X = ( CCR * `RGB2XYZ1 + CCG * `RGB2XYZ2 + CCB * `RGB2XYZ3 ) >> ( `ScaleBit + `ScaleBit );
				X = ( X * 269 ) >> `ScaleBit;	// 256 / 0.950456 = 269.34439
				
				Y = ( CCR * `RGB2XYZ4 + CCG * `RGB2XYZ5 + CCB * `RGB2XYZ6 ) >> ( `ScaleBit + `ScaleBit );
				
				// 256 * 1.088754 * 256
				Z = ( CCR * `RGB2XYZ7 + CCG * `RGB2XYZ8 + CCB * `RGB2XYZ9 ) >> ( `ScaleBit + `ScaleBit );
				Z = ( Z * 235 ) >> `ScaleBit;	// 256 / 1.088754 = 235.13116
				
				// avoid extreme case of Y
				if( Y < `RGB2LabLimit )
					Y = `RGB2LabLimit;
				
				// avoid extreme case of X
				if( X < `RGB2LabLimit )
					X = `RGB2LabLimit;
				
				// avoid extreme case of Z
				if( Z < `RGB2LabLimit )
					Z = `RGB2LabLimit;
				
				fX = LUTPow033( X );
				fY = LUTPow033( Y );
				fZ = LUTPow033( Z );
				
				CIEL = 116 * fY - `pow_16_256_1_3;
				CIEa_input = 500 * ( fX - fY );
				CIEb_input = 200 * ( fY - fZ );
				
				/////////////////////////
				// saturation enhancement
				CIEa = ( CIEa_input * `SE_a ) >>> `ScaleBit;
				CIEb = ( CIEb_input * `SE_b ) >>> `ScaleBit;
				// operator <<<, >>>
				// If operand is signed, the right shift fills the vacated bit positions with the MSB.
				// If it is unsigned, the vacated bit positions are filled with zeros.
				// The left shift fills vacated positions with zeros.
				
				/////////////////
				// backward space
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
				Y = ( Y * 256 ) >> `ScaleBit;
				
				// in case of over-range of power 3 operation later
				// fX = fX >> `ScaleHalfBit;
				fX = fX >> ( `ScaleHalfBit + `ScaleBit + `ScaleBit );
				X = fX * fX * fX;
				X = ( X * 243 ) >> `ScaleBit;	// 256 * 0.950456 = 243.316736
				
				// in case of over-range of power 3 operation later
				// fZ = fZ >> `ScaleHalfBit;
				fZ = fZ >> ( `ScaleHalfBit + `ScaleBit + `ScaleBit );
				Z = fZ * fZ * fZ;
				Z = ( Z * 279 ) >> `ScaleBit;	// 256 * 1.088754 = 278.721024
				
				ScaleRTemp = (  `XYZ2RGB1 * X - `XYZ2RGB2 * Y - `XYZ2RGB3 * Z )
				>> ( `ScaleBit + `ScaleHalfBit );
				ScaleGTemp = ( -`XYZ2RGB4 * X + `XYZ2RGB5 * Y + `XYZ2RGB6 * Z )
				>> ( `ScaleBit + `ScaleHalfBit );
				ScaleBTemp = (  `XYZ2RGB7 * X - `XYZ2RGB8 * Y + `XYZ2RGB9 * Z )
				>> ( `ScaleBit + `ScaleHalfBit );
				
				ScaleRTemp = ( ScaleRTemp[ 17 : 16 ] == 2'b00 ) ? ScaleRTemp : ( ScaleRTemp[ 17 ] == 1'b1 ) ? `MinThreshold : `MaxThreshold;
				ScaleGTemp = ( ScaleGTemp[ 17 : 16 ] == 2'b00 ) ? ScaleGTemp : ( ScaleGTemp[ 17 ] == 1'b1 ) ? `MinThreshold : `MaxThreshold;
				ScaleBTemp = ( ScaleBTemp[ 17 : 16 ] == 2'b00 ) ? ScaleBTemp : ( ScaleBTemp[ 17 ] == 1'b1 ) ? `MinThreshold : `MaxThreshold;
				
				///////////////////
				// gamma correction
				GCR = LUTPow045( ScaleRTemp >> `ScaleBit );
				GCG = LUTPow045( ScaleGTemp >> `ScaleBit );
				GCB = LUTPow045( ScaleBTemp >> `ScaleBit );
				
			end
			
		end
		
		// finish the work
		FinishState :
		begin
			
			// nothing to do, usage in the future
			
		end
		
		endcase
		
	end
	
	assign R_out = GCR >> `ScaleBit;
	assign G_out = GCG >> `ScaleBit;
	assign B_out = GCB >> `ScaleBit;
	
	//////////////////////////////////////////////////////////////////
	
	function[ `size_int - 1 : 0 ]Divider
	(
		
		input[ `size_int - 1 : 0 ]Dividend,
		input[ `size_int - 1 : 0 ]Divisor
		
	);
	
	// counter
	integer i;
	
	reg[ `size_int - 1 : 0 ]Quotient;		// Quotient
	reg[ `size_int - 1 : 0 ]Remainder;		// Remainder
	reg[ `size_int : 0 ]Partial;
	reg[ `size_int - 1 : 0 ]div;
	
	begin
		
		Quotient = Dividend;
		div = Divisor;
		Partial = { `size_int'h00, 1'b0 };
		
		for( i = 0; i < `size_int; i = i + 1 )
		begin
			
			Partial = { Partial[ `size_int - 1 : 0 ], Quotient[ `size_int - 1 ] };
			Quotient = { Quotient[ `size_int - 2 : 0 ], 1'b0 };
			Partial = Partial + { ~{ 1'b0, div } + 1'b1 };	// subtraction
			
			if( Partial[ `size_int ] == 1'b0 )
				Quotient[ 0 ] = 1'b1;
			else
			begin
				
				Partial = Partial + div;
				Quotient[ 0 ] = 1'b0;
				
			end
			
		end
		
		Remainder = Partial[ `size_int - 1 : 0 ];
		
		//to round up or down
		if( Remainder * 10 >= Divisor * 5 )
			Divider = Quotient + 1;
		else
			Divider = Quotient;
		
	end
	
	endfunction
	
	// ratio = 1.0 ~ 2.5
	// scale = 16
	// ratio * 16 = 16 ~ 40
	// every layer size = 40 - 16 = 24
	// every step : ( 2.5 - 1.0 ) / 24 = 0.0625
	// it needed to be modified
	task LUTCTCFactor
	(
		
		input[ `size_int - 1 : 0 ]Index,
		output[ `size_int - 1 : 0 ]RFactor,
		output[ `size_int - 1 : 0 ]BFactor
		
	);
	
	begin
		
		case( Index )
		
		0 : begin RFactor = 417; BFactor = 414; end // GR = 1.00, GB = 1.00
		1 : begin RFactor = 405; BFactor = 427; end // GR = 1.00, GB = 1.06
		2 : begin RFactor = 394; BFactor = 440; end // GR = 1.00, GB = 1.12
		3 : begin RFactor = 383; BFactor = 452; end // GR = 1.00, GB = 1.19
		4 : begin RFactor = 373; BFactor = 464; end // GR = 1.00, GB = 1.25
		5 : begin RFactor = 364; BFactor = 476; end // GR = 1.00, GB = 1.31
		6 : begin RFactor = 356; BFactor = 487; end // GR = 1.00, GB = 1.38
		7 : begin RFactor = 348; BFactor = 498; end // GR = 1.00, GB = 1.44
		8 : begin RFactor = 341; BFactor = 509; end // GR = 1.00, GB = 1.50
		9 : begin RFactor = 334; BFactor = 520; end // GR = 1.00, GB = 1.56
		10 : begin RFactor = 327; BFactor = 530; end // GR = 1.00, GB = 1.62
		11 : begin RFactor = 321; BFactor = 540; end // GR = 1.00, GB = 1.69
		12 : begin RFactor = 315; BFactor = 551; end // GR = 1.00, GB = 1.75
		13 : begin RFactor = 310; BFactor = 560; end // GR = 1.00, GB = 1.81
		14 : begin RFactor = 305; BFactor = 570; end // GR = 1.00, GB = 1.88
		15 : begin RFactor = 300; BFactor = 580; end // GR = 1.00, GB = 1.94
		16 : begin RFactor = 295; BFactor = 589; end // GR = 1.00, GB = 2.00
		17 : begin RFactor = 291; BFactor = 599; end // GR = 1.00, GB = 2.06
		18 : begin RFactor = 286; BFactor = 608; end // GR = 1.00, GB = 2.12
		19 : begin RFactor = 282; BFactor = 617; end // GR = 1.00, GB = 2.19
		20 : begin RFactor = 278; BFactor = 626; end // GR = 1.00, GB = 2.25
		21 : begin RFactor = 274; BFactor = 634; end // GR = 1.00, GB = 2.31
		22 : begin RFactor = 271; BFactor = 643; end // GR = 1.00, GB = 2.38
		23 : begin RFactor = 267; BFactor = 652; end // GR = 1.00, GB = 2.44
		24 : begin RFactor = 430; BFactor = 402; end // GR = 1.06, GB = 1.00
		25 : begin RFactor = 417; BFactor = 414; end // GR = 1.06, GB = 1.06
		26 : begin RFactor = 405; BFactor = 427; end // GR = 1.06, GB = 1.12
		27 : begin RFactor = 395; BFactor = 438; end // GR = 1.06, GB = 1.19
		28 : begin RFactor = 385; BFactor = 450; end // GR = 1.06, GB = 1.25
		29 : begin RFactor = 375; BFactor = 461; end // GR = 1.06, GB = 1.31
		30 : begin RFactor = 367; BFactor = 472; end // GR = 1.06, GB = 1.38
		31 : begin RFactor = 359; BFactor = 483; end // GR = 1.06, GB = 1.44
		32 : begin RFactor = 351; BFactor = 494; end // GR = 1.06, GB = 1.50
		33 : begin RFactor = 344; BFactor = 504; end // GR = 1.06, GB = 1.56
		34 : begin RFactor = 337; BFactor = 514; end // GR = 1.06, GB = 1.62
		35 : begin RFactor = 331; BFactor = 524; end // GR = 1.06, GB = 1.69
		36 : begin RFactor = 325; BFactor = 534; end // GR = 1.06, GB = 1.75
		37 : begin RFactor = 319; BFactor = 544; end // GR = 1.06, GB = 1.81
		38 : begin RFactor = 314; BFactor = 553; end // GR = 1.06, GB = 1.88
		39 : begin RFactor = 309; BFactor = 562; end // GR = 1.06, GB = 1.94
		40 : begin RFactor = 304; BFactor = 572; end // GR = 1.06, GB = 2.00
		41 : begin RFactor = 299; BFactor = 581; end // GR = 1.06, GB = 2.06
		42 : begin RFactor = 295; BFactor = 590; end // GR = 1.06, GB = 2.12
		43 : begin RFactor = 291; BFactor = 598; end // GR = 1.06, GB = 2.19
		44 : begin RFactor = 287; BFactor = 607; end // GR = 1.06, GB = 2.25
		45 : begin RFactor = 283; BFactor = 615; end // GR = 1.06, GB = 2.31
		46 : begin RFactor = 279; BFactor = 624; end // GR = 1.06, GB = 2.38
		47 : begin RFactor = 275; BFactor = 632; end // GR = 1.06, GB = 2.44
		48 : begin RFactor = 442; BFactor = 390; end // GR = 1.12, GB = 1.00
		49 : begin RFactor = 429; BFactor = 403; end // GR = 1.12, GB = 1.06
		50 : begin RFactor = 417; BFactor = 415; end // GR = 1.12, GB = 1.12
		51 : begin RFactor = 406; BFactor = 426; end // GR = 1.12, GB = 1.19
		52 : begin RFactor = 396; BFactor = 437; end // GR = 1.12, GB = 1.25
		53 : begin RFactor = 386; BFactor = 448; end // GR = 1.12, GB = 1.31
		54 : begin RFactor = 377; BFactor = 459; end // GR = 1.12, GB = 1.38
		55 : begin RFactor = 369; BFactor = 470; end // GR = 1.12, GB = 1.44
		56 : begin RFactor = 361; BFactor = 480; end // GR = 1.12, GB = 1.50
		57 : begin RFactor = 354; BFactor = 490; end // GR = 1.12, GB = 1.56
		58 : begin RFactor = 347; BFactor = 500; end // GR = 1.12, GB = 1.62
		59 : begin RFactor = 340; BFactor = 510; end // GR = 1.12, GB = 1.69
		60 : begin RFactor = 334; BFactor = 519; end // GR = 1.12, GB = 1.75
		61 : begin RFactor = 328; BFactor = 528; end // GR = 1.12, GB = 1.81
		62 : begin RFactor = 323; BFactor = 538; end // GR = 1.12, GB = 1.88
		63 : begin RFactor = 318; BFactor = 547; end // GR = 1.12, GB = 1.94
		64 : begin RFactor = 313; BFactor = 555; end // GR = 1.12, GB = 2.00
		65 : begin RFactor = 308; BFactor = 564; end // GR = 1.12, GB = 2.06
		66 : begin RFactor = 303; BFactor = 573; end // GR = 1.12, GB = 2.12
		67 : begin RFactor = 299; BFactor = 581; end // GR = 1.12, GB = 2.19
		68 : begin RFactor = 295; BFactor = 590; end // GR = 1.12, GB = 2.25
		69 : begin RFactor = 291; BFactor = 598; end // GR = 1.12, GB = 2.31
		70 : begin RFactor = 287; BFactor = 606; end // GR = 1.12, GB = 2.38
		71 : begin RFactor = 283; BFactor = 614; end // GR = 1.12, GB = 2.44
		72 : begin RFactor = 454; BFactor = 380; end // GR = 1.19, GB = 1.00
		73 : begin RFactor = 441; BFactor = 392; end // GR = 1.19, GB = 1.06
		74 : begin RFactor = 428; BFactor = 403; end // GR = 1.19, GB = 1.12
		75 : begin RFactor = 417; BFactor = 415; end // GR = 1.19, GB = 1.19
		76 : begin RFactor = 406; BFactor = 426; end // GR = 1.19, GB = 1.25
		77 : begin RFactor = 396; BFactor = 436; end // GR = 1.19, GB = 1.31
		78 : begin RFactor = 387; BFactor = 447; end // GR = 1.19, GB = 1.38
		79 : begin RFactor = 379; BFactor = 457; end // GR = 1.19, GB = 1.44
		80 : begin RFactor = 371; BFactor = 467; end // GR = 1.19, GB = 1.50
		81 : begin RFactor = 363; BFactor = 477; end // GR = 1.19, GB = 1.56
		82 : begin RFactor = 356; BFactor = 486; end // GR = 1.19, GB = 1.62
		83 : begin RFactor = 350; BFactor = 496; end // GR = 1.19, GB = 1.69
		84 : begin RFactor = 343; BFactor = 505; end // GR = 1.19, GB = 1.75
		85 : begin RFactor = 337; BFactor = 514; end // GR = 1.19, GB = 1.81
		86 : begin RFactor = 332; BFactor = 523; end // GR = 1.19, GB = 1.88
		87 : begin RFactor = 326; BFactor = 532; end // GR = 1.19, GB = 1.94
		88 : begin RFactor = 321; BFactor = 541; end // GR = 1.19, GB = 2.00
		89 : begin RFactor = 316; BFactor = 549; end // GR = 1.19, GB = 2.06
		90 : begin RFactor = 312; BFactor = 558; end // GR = 1.19, GB = 2.12
		91 : begin RFactor = 307; BFactor = 566; end // GR = 1.19, GB = 2.19
		92 : begin RFactor = 303; BFactor = 574; end // GR = 1.19, GB = 2.25
		93 : begin RFactor = 299; BFactor = 582; end // GR = 1.19, GB = 2.31
		94 : begin RFactor = 295; BFactor = 590; end // GR = 1.19, GB = 2.38
		95 : begin RFactor = 291; BFactor = 598; end // GR = 1.19, GB = 2.44
		96 : begin RFactor = 466; BFactor = 370; end // GR = 1.25, GB = 1.00
		97 : begin RFactor = 452; BFactor = 382; end // GR = 1.25, GB = 1.06
		98 : begin RFactor = 439; BFactor = 393; end // GR = 1.25, GB = 1.12
		99 : begin RFactor = 428; BFactor = 404; end // GR = 1.25, GB = 1.19
		100 : begin RFactor = 417; BFactor = 415; end // GR = 1.25, GB = 1.25
		101 : begin RFactor = 407; BFactor = 425; end // GR = 1.25, GB = 1.31
		102 : begin RFactor = 397; BFactor = 436; end // GR = 1.25, GB = 1.38
		103 : begin RFactor = 389; BFactor = 445; end // GR = 1.25, GB = 1.44
		104 : begin RFactor = 380; BFactor = 455; end // GR = 1.25, GB = 1.50
		105 : begin RFactor = 373; BFactor = 465; end // GR = 1.25, GB = 1.56
		106 : begin RFactor = 365; BFactor = 474; end // GR = 1.25, GB = 1.62
		107 : begin RFactor = 359; BFactor = 483; end // GR = 1.25, GB = 1.69
		108 : begin RFactor = 352; BFactor = 492; end // GR = 1.25, GB = 1.75
		109 : begin RFactor = 346; BFactor = 501; end // GR = 1.25, GB = 1.81
		110 : begin RFactor = 340; BFactor = 510; end // GR = 1.25, GB = 1.88
		111 : begin RFactor = 335; BFactor = 519; end // GR = 1.25, GB = 1.94
		112 : begin RFactor = 329; BFactor = 527; end // GR = 1.25, GB = 2.00
		113 : begin RFactor = 324; BFactor = 535; end // GR = 1.25, GB = 2.06
		114 : begin RFactor = 319; BFactor = 543; end // GR = 1.25, GB = 2.12
		115 : begin RFactor = 315; BFactor = 552; end // GR = 1.25, GB = 2.19
		116 : begin RFactor = 310; BFactor = 559; end // GR = 1.25, GB = 2.25
		117 : begin RFactor = 306; BFactor = 567; end // GR = 1.25, GB = 2.31
		118 : begin RFactor = 302; BFactor = 575; end // GR = 1.25, GB = 2.38
		119 : begin RFactor = 298; BFactor = 583; end // GR = 1.25, GB = 2.44
		120 : begin RFactor = 477; BFactor = 361; end // GR = 1.31, GB = 1.00
		121 : begin RFactor = 463; BFactor = 373; end // GR = 1.31, GB = 1.06
		122 : begin RFactor = 450; BFactor = 384; end // GR = 1.31, GB = 1.12
		123 : begin RFactor = 438; BFactor = 394; end // GR = 1.31, GB = 1.19
		124 : begin RFactor = 427; BFactor = 405; end // GR = 1.31, GB = 1.25
		125 : begin RFactor = 417; BFactor = 415; end // GR = 1.31, GB = 1.31
		126 : begin RFactor = 407; BFactor = 425; end // GR = 1.31, GB = 1.38
		127 : begin RFactor = 398; BFactor = 435; end // GR = 1.31, GB = 1.44
		128 : begin RFactor = 390; BFactor = 444; end // GR = 1.31, GB = 1.50
		129 : begin RFactor = 382; BFactor = 454; end // GR = 1.31, GB = 1.56
		130 : begin RFactor = 374; BFactor = 463; end // GR = 1.31, GB = 1.62
		131 : begin RFactor = 367; BFactor = 472; end // GR = 1.31, GB = 1.69
		132 : begin RFactor = 361; BFactor = 480; end // GR = 1.31, GB = 1.75
		133 : begin RFactor = 354; BFactor = 489; end // GR = 1.31, GB = 1.81
		134 : begin RFactor = 348; BFactor = 498; end // GR = 1.31, GB = 1.88
		135 : begin RFactor = 343; BFactor = 506; end // GR = 1.31, GB = 1.94
		136 : begin RFactor = 337; BFactor = 514; end // GR = 1.31, GB = 2.00
		137 : begin RFactor = 332; BFactor = 522; end // GR = 1.31, GB = 2.06
		138 : begin RFactor = 327; BFactor = 530; end // GR = 1.31, GB = 2.12
		139 : begin RFactor = 323; BFactor = 538; end // GR = 1.31, GB = 2.19
		140 : begin RFactor = 318; BFactor = 546; end // GR = 1.31, GB = 2.25
		141 : begin RFactor = 314; BFactor = 554; end // GR = 1.31, GB = 2.31
		142 : begin RFactor = 310; BFactor = 561; end // GR = 1.31, GB = 2.38
		143 : begin RFactor = 306; BFactor = 569; end // GR = 1.31, GB = 2.44
		144 : begin RFactor = 488; BFactor = 353; end // GR = 1.38, GB = 1.00
		145 : begin RFactor = 474; BFactor = 364; end // GR = 1.38, GB = 1.06
		146 : begin RFactor = 460; BFactor = 375; end // GR = 1.38, GB = 1.12
		147 : begin RFactor = 448; BFactor = 385; end // GR = 1.38, GB = 1.19
		148 : begin RFactor = 437; BFactor = 396; end // GR = 1.38, GB = 1.25
		149 : begin RFactor = 426; BFactor = 406; end // GR = 1.38, GB = 1.31
		150 : begin RFactor = 416; BFactor = 415; end // GR = 1.38, GB = 1.38
		151 : begin RFactor = 407; BFactor = 425; end // GR = 1.38, GB = 1.44
		152 : begin RFactor = 399; BFactor = 434; end // GR = 1.38, GB = 1.50
		153 : begin RFactor = 391; BFactor = 443; end // GR = 1.38, GB = 1.56
		154 : begin RFactor = 383; BFactor = 452; end // GR = 1.38, GB = 1.62
		155 : begin RFactor = 376; BFactor = 461; end // GR = 1.38, GB = 1.69
		156 : begin RFactor = 369; BFactor = 469; end // GR = 1.38, GB = 1.75
		157 : begin RFactor = 363; BFactor = 478; end // GR = 1.38, GB = 1.81
		158 : begin RFactor = 356; BFactor = 486; end // GR = 1.38, GB = 1.88
		159 : begin RFactor = 351; BFactor = 494; end // GR = 1.38, GB = 1.94
		160 : begin RFactor = 345; BFactor = 502; end // GR = 1.38, GB = 2.00
		161 : begin RFactor = 340; BFactor = 510; end // GR = 1.38, GB = 2.06
		162 : begin RFactor = 335; BFactor = 518; end // GR = 1.38, GB = 2.12
		163 : begin RFactor = 330; BFactor = 526; end // GR = 1.38, GB = 2.19
		164 : begin RFactor = 325; BFactor = 533; end // GR = 1.38, GB = 2.25
		165 : begin RFactor = 321; BFactor = 541; end // GR = 1.38, GB = 2.31
		166 : begin RFactor = 317; BFactor = 548; end // GR = 1.38, GB = 2.38
		167 : begin RFactor = 313; BFactor = 556; end // GR = 1.38, GB = 2.44
		168 : begin RFactor = 499; BFactor = 345; end // GR = 1.44, GB = 1.00
		169 : begin RFactor = 484; BFactor = 356; end // GR = 1.44, GB = 1.06
		170 : begin RFactor = 471; BFactor = 367; end // GR = 1.44, GB = 1.12
		171 : begin RFactor = 458; BFactor = 377; end // GR = 1.44, GB = 1.19
		172 : begin RFactor = 446; BFactor = 387; end // GR = 1.44, GB = 1.25
		173 : begin RFactor = 436; BFactor = 397; end // GR = 1.44, GB = 1.31
		174 : begin RFactor = 426; BFactor = 406; end // GR = 1.44, GB = 1.38
		175 : begin RFactor = 416; BFactor = 415; end // GR = 1.44, GB = 1.44
		176 : begin RFactor = 407; BFactor = 424; end // GR = 1.44, GB = 1.50
		177 : begin RFactor = 399; BFactor = 433; end // GR = 1.44, GB = 1.56
		178 : begin RFactor = 391; BFactor = 442; end // GR = 1.44, GB = 1.62
		179 : begin RFactor = 384; BFactor = 451; end // GR = 1.44, GB = 1.69
		180 : begin RFactor = 377; BFactor = 459; end // GR = 1.44, GB = 1.75
		181 : begin RFactor = 371; BFactor = 467; end // GR = 1.44, GB = 1.81
		182 : begin RFactor = 364; BFactor = 476; end // GR = 1.44, GB = 1.88
		183 : begin RFactor = 358; BFactor = 484; end // GR = 1.44, GB = 1.94
		184 : begin RFactor = 353; BFactor = 491; end // GR = 1.44, GB = 2.00
		185 : begin RFactor = 347; BFactor = 499; end // GR = 1.44, GB = 2.06
		186 : begin RFactor = 342; BFactor = 507; end // GR = 1.44, GB = 2.12
		187 : begin RFactor = 337; BFactor = 514; end // GR = 1.44, GB = 2.19
		188 : begin RFactor = 333; BFactor = 522; end // GR = 1.44, GB = 2.25
		189 : begin RFactor = 328; BFactor = 529; end // GR = 1.44, GB = 2.31
		190 : begin RFactor = 324; BFactor = 536; end // GR = 1.44, GB = 2.38
		191 : begin RFactor = 320; BFactor = 543; end // GR = 1.44, GB = 2.44
		192 : begin RFactor = 510; BFactor = 338; end // GR = 1.50, GB = 1.00
		193 : begin RFactor = 494; BFactor = 349; end // GR = 1.50, GB = 1.06
		194 : begin RFactor = 481; BFactor = 359; end // GR = 1.50, GB = 1.12
		195 : begin RFactor = 468; BFactor = 369; end // GR = 1.50, GB = 1.19
		196 : begin RFactor = 456; BFactor = 379; end // GR = 1.50, GB = 1.25
		197 : begin RFactor = 445; BFactor = 388; end // GR = 1.50, GB = 1.31
		198 : begin RFactor = 435; BFactor = 398; end // GR = 1.50, GB = 1.38
		199 : begin RFactor = 425; BFactor = 407; end // GR = 1.50, GB = 1.44
		200 : begin RFactor = 416; BFactor = 416; end // GR = 1.50, GB = 1.50
		201 : begin RFactor = 408; BFactor = 424; end // GR = 1.50, GB = 1.56
		202 : begin RFactor = 400; BFactor = 433; end // GR = 1.50, GB = 1.62
		203 : begin RFactor = 392; BFactor = 441; end // GR = 1.50, GB = 1.69
		204 : begin RFactor = 385; BFactor = 449; end // GR = 1.50, GB = 1.75
		205 : begin RFactor = 378; BFactor = 458; end // GR = 1.50, GB = 1.81
		206 : begin RFactor = 372; BFactor = 465; end // GR = 1.50, GB = 1.88
		207 : begin RFactor = 366; BFactor = 473; end // GR = 1.50, GB = 1.94
		208 : begin RFactor = 360; BFactor = 481; end // GR = 1.50, GB = 2.00
		209 : begin RFactor = 355; BFactor = 489; end // GR = 1.50, GB = 2.06
		210 : begin RFactor = 350; BFactor = 496; end // GR = 1.50, GB = 2.12
		211 : begin RFactor = 344; BFactor = 503; end // GR = 1.50, GB = 2.19
		212 : begin RFactor = 340; BFactor = 511; end // GR = 1.50, GB = 2.25
		213 : begin RFactor = 335; BFactor = 518; end // GR = 1.50, GB = 2.31
		214 : begin RFactor = 331; BFactor = 525; end // GR = 1.50, GB = 2.38
		215 : begin RFactor = 326; BFactor = 532; end // GR = 1.50, GB = 2.44
		216 : begin RFactor = 520; BFactor = 331; end // GR = 1.56, GB = 1.00
		217 : begin RFactor = 505; BFactor = 342; end // GR = 1.56, GB = 1.06
		218 : begin RFactor = 490; BFactor = 352; end // GR = 1.56, GB = 1.12
		219 : begin RFactor = 477; BFactor = 362; end // GR = 1.56, GB = 1.19
		220 : begin RFactor = 465; BFactor = 371; end // GR = 1.56, GB = 1.25
		221 : begin RFactor = 454; BFactor = 380; end // GR = 1.56, GB = 1.31
		222 : begin RFactor = 443; BFactor = 390; end // GR = 1.56, GB = 1.38
		223 : begin RFactor = 434; BFactor = 398; end // GR = 1.56, GB = 1.44
		224 : begin RFactor = 425; BFactor = 407; end // GR = 1.56, GB = 1.50
		225 : begin RFactor = 416; BFactor = 416; end // GR = 1.56, GB = 1.56
		226 : begin RFactor = 408; BFactor = 424; end // GR = 1.56, GB = 1.62
		227 : begin RFactor = 400; BFactor = 432; end // GR = 1.56, GB = 1.69
		228 : begin RFactor = 393; BFactor = 440; end // GR = 1.56, GB = 1.75
		229 : begin RFactor = 386; BFactor = 448; end // GR = 1.56, GB = 1.81
		230 : begin RFactor = 380; BFactor = 456; end // GR = 1.56, GB = 1.88
		231 : begin RFactor = 373; BFactor = 464; end // GR = 1.56, GB = 1.94
		232 : begin RFactor = 368; BFactor = 471; end // GR = 1.56, GB = 2.00
		233 : begin RFactor = 362; BFactor = 479; end // GR = 1.56, GB = 2.06
		234 : begin RFactor = 357; BFactor = 486; end // GR = 1.56, GB = 2.12
		235 : begin RFactor = 351; BFactor = 493; end // GR = 1.56, GB = 2.19
		236 : begin RFactor = 347; BFactor = 500; end // GR = 1.56, GB = 2.25
		237 : begin RFactor = 342; BFactor = 507; end // GR = 1.56, GB = 2.31
		238 : begin RFactor = 337; BFactor = 514; end // GR = 1.56, GB = 2.38
		239 : begin RFactor = 333; BFactor = 521; end // GR = 1.56, GB = 2.44
		240 : begin RFactor = 530; BFactor = 325; end // GR = 1.62, GB = 1.00
		241 : begin RFactor = 514; BFactor = 335; end // GR = 1.62, GB = 1.06
		242 : begin RFactor = 500; BFactor = 345; end // GR = 1.62, GB = 1.12
		243 : begin RFactor = 486; BFactor = 354; end // GR = 1.62, GB = 1.19
		244 : begin RFactor = 474; BFactor = 364; end // GR = 1.62, GB = 1.25
		245 : begin RFactor = 463; BFactor = 373; end // GR = 1.62, GB = 1.31
		246 : begin RFactor = 452; BFactor = 382; end // GR = 1.62, GB = 1.38
		247 : begin RFactor = 442; BFactor = 391; end // GR = 1.62, GB = 1.44
		248 : begin RFactor = 433; BFactor = 399; end // GR = 1.62, GB = 1.50
		249 : begin RFactor = 424; BFactor = 408; end // GR = 1.62, GB = 1.56
		250 : begin RFactor = 416; BFactor = 416; end // GR = 1.62, GB = 1.62
		251 : begin RFactor = 408; BFactor = 424; end // GR = 1.62, GB = 1.69
		252 : begin RFactor = 401; BFactor = 432; end // GR = 1.62, GB = 1.75
		253 : begin RFactor = 394; BFactor = 440; end // GR = 1.62, GB = 1.81
		254 : begin RFactor = 387; BFactor = 447; end // GR = 1.62, GB = 1.88
		255 : begin RFactor = 381; BFactor = 455; end // GR = 1.62, GB = 1.94
		256 : begin RFactor = 375; BFactor = 462; end // GR = 1.62, GB = 2.00
		257 : begin RFactor = 369; BFactor = 469; end // GR = 1.62, GB = 2.06
		258 : begin RFactor = 364; BFactor = 477; end // GR = 1.62, GB = 2.12
		259 : begin RFactor = 358; BFactor = 484; end // GR = 1.62, GB = 2.19
		260 : begin RFactor = 353; BFactor = 491; end // GR = 1.62, GB = 2.25
		261 : begin RFactor = 348; BFactor = 498; end // GR = 1.62, GB = 2.31
		262 : begin RFactor = 344; BFactor = 504; end // GR = 1.62, GB = 2.38
		263 : begin RFactor = 339; BFactor = 511; end // GR = 1.62, GB = 2.44
		264 : begin RFactor = 540; BFactor = 319; end // GR = 1.69, GB = 1.00
		265 : begin RFactor = 524; BFactor = 329; end // GR = 1.69, GB = 1.06
		266 : begin RFactor = 509; BFactor = 338; end // GR = 1.69, GB = 1.12
		267 : begin RFactor = 496; BFactor = 348; end // GR = 1.69, GB = 1.19
		268 : begin RFactor = 483; BFactor = 357; end // GR = 1.69, GB = 1.25
		269 : begin RFactor = 471; BFactor = 366; end // GR = 1.69, GB = 1.31
		270 : begin RFactor = 461; BFactor = 375; end // GR = 1.69, GB = 1.38
		271 : begin RFactor = 450; BFactor = 383; end // GR = 1.69, GB = 1.44
		272 : begin RFactor = 441; BFactor = 392; end // GR = 1.69, GB = 1.50
		273 : begin RFactor = 432; BFactor = 400; end // GR = 1.69, GB = 1.56
		274 : begin RFactor = 424; BFactor = 408; end // GR = 1.69, GB = 1.62
		275 : begin RFactor = 416; BFactor = 416; end // GR = 1.69, GB = 1.69
		276 : begin RFactor = 408; BFactor = 424; end // GR = 1.69, GB = 1.75
		277 : begin RFactor = 401; BFactor = 431; end // GR = 1.69, GB = 1.81
		278 : begin RFactor = 394; BFactor = 439; end // GR = 1.69, GB = 1.88
		279 : begin RFactor = 388; BFactor = 446; end // GR = 1.69, GB = 1.94
		280 : begin RFactor = 382; BFactor = 453; end // GR = 1.69, GB = 2.00
		281 : begin RFactor = 376; BFactor = 461; end // GR = 1.69, GB = 2.06
		282 : begin RFactor = 370; BFactor = 468; end // GR = 1.69, GB = 2.12
		283 : begin RFactor = 365; BFactor = 475; end // GR = 1.69, GB = 2.19
		284 : begin RFactor = 360; BFactor = 481; end // GR = 1.69, GB = 2.25
		285 : begin RFactor = 355; BFactor = 488; end // GR = 1.69, GB = 2.31
		286 : begin RFactor = 350; BFactor = 495; end // GR = 1.69, GB = 2.38
		287 : begin RFactor = 346; BFactor = 501; end // GR = 1.69, GB = 2.44
		288 : begin RFactor = 550; BFactor = 313; end // GR = 1.75, GB = 1.00
		289 : begin RFactor = 533; BFactor = 323; end // GR = 1.75, GB = 1.06
		290 : begin RFactor = 518; BFactor = 332; end // GR = 1.75, GB = 1.12
		291 : begin RFactor = 505; BFactor = 342; end // GR = 1.75, GB = 1.19
		292 : begin RFactor = 492; BFactor = 351; end // GR = 1.75, GB = 1.25
		293 : begin RFactor = 480; BFactor = 359; end // GR = 1.75, GB = 1.31
		294 : begin RFactor = 469; BFactor = 368; end // GR = 1.75, GB = 1.38
		295 : begin RFactor = 459; BFactor = 376; end // GR = 1.75, GB = 1.44
		296 : begin RFactor = 449; BFactor = 385; end // GR = 1.75, GB = 1.50
		297 : begin RFactor = 440; BFactor = 393; end // GR = 1.75, GB = 1.56
		298 : begin RFactor = 431; BFactor = 401; end // GR = 1.75, GB = 1.62
		299 : begin RFactor = 423; BFactor = 408; end // GR = 1.75, GB = 1.69
		300 : begin RFactor = 416; BFactor = 416; end // GR = 1.75, GB = 1.75
		301 : begin RFactor = 408; BFactor = 424; end // GR = 1.75, GB = 1.81
		302 : begin RFactor = 401; BFactor = 431; end // GR = 1.75, GB = 1.88
		303 : begin RFactor = 395; BFactor = 438; end // GR = 1.75, GB = 1.94
		304 : begin RFactor = 389; BFactor = 445; end // GR = 1.75, GB = 2.00
		305 : begin RFactor = 383; BFactor = 452; end // GR = 1.75, GB = 2.06
		306 : begin RFactor = 377; BFactor = 459; end // GR = 1.75, GB = 2.12
		307 : begin RFactor = 372; BFactor = 466; end // GR = 1.75, GB = 2.19
		308 : begin RFactor = 366; BFactor = 473; end // GR = 1.75, GB = 2.25
		309 : begin RFactor = 361; BFactor = 479; end // GR = 1.75, GB = 2.31
		310 : begin RFactor = 357; BFactor = 486; end // GR = 1.75, GB = 2.38
		311 : begin RFactor = 352; BFactor = 492; end // GR = 1.75, GB = 2.44
		312 : begin RFactor = 559; BFactor = 308; end // GR = 1.81, GB = 1.00
		313 : begin RFactor = 543; BFactor = 317; end // GR = 1.81, GB = 1.06
		314 : begin RFactor = 527; BFactor = 327; end // GR = 1.81, GB = 1.12
		315 : begin RFactor = 513; BFactor = 336; end // GR = 1.81, GB = 1.19
		316 : begin RFactor = 500; BFactor = 344; end // GR = 1.81, GB = 1.25
		317 : begin RFactor = 488; BFactor = 353; end // GR = 1.81, GB = 1.31
		318 : begin RFactor = 477; BFactor = 362; end // GR = 1.81, GB = 1.38
		319 : begin RFactor = 467; BFactor = 370; end // GR = 1.81, GB = 1.44
		320 : begin RFactor = 457; BFactor = 378; end // GR = 1.81, GB = 1.50
		321 : begin RFactor = 447; BFactor = 386; end // GR = 1.81, GB = 1.56
		322 : begin RFactor = 439; BFactor = 394; end // GR = 1.81, GB = 1.62
		323 : begin RFactor = 431; BFactor = 401; end // GR = 1.81, GB = 1.69
		324 : begin RFactor = 423; BFactor = 409; end // GR = 1.81, GB = 1.75
		325 : begin RFactor = 415; BFactor = 416; end // GR = 1.81, GB = 1.81
		326 : begin RFactor = 408; BFactor = 423; end // GR = 1.81, GB = 1.88
		327 : begin RFactor = 402; BFactor = 431; end // GR = 1.81, GB = 1.94
		328 : begin RFactor = 395; BFactor = 438; end // GR = 1.81, GB = 2.00
		329 : begin RFactor = 389; BFactor = 444; end // GR = 1.81, GB = 2.06
		330 : begin RFactor = 384; BFactor = 451; end // GR = 1.81, GB = 2.12
		331 : begin RFactor = 378; BFactor = 458; end // GR = 1.81, GB = 2.19
		332 : begin RFactor = 373; BFactor = 465; end // GR = 1.81, GB = 2.25
		333 : begin RFactor = 368; BFactor = 471; end // GR = 1.81, GB = 2.31
		334 : begin RFactor = 363; BFactor = 478; end // GR = 1.81, GB = 2.38
		335 : begin RFactor = 358; BFactor = 484; end // GR = 1.81, GB = 2.44
		336 : begin RFactor = 569; BFactor = 302; end // GR = 1.88, GB = 1.00
		337 : begin RFactor = 552; BFactor = 312; end // GR = 1.88, GB = 1.06
		338 : begin RFactor = 536; BFactor = 321; end // GR = 1.88, GB = 1.12
		339 : begin RFactor = 522; BFactor = 330; end // GR = 1.88, GB = 1.19
		340 : begin RFactor = 509; BFactor = 339; end // GR = 1.88, GB = 1.25
		341 : begin RFactor = 497; BFactor = 347; end // GR = 1.88, GB = 1.31
		342 : begin RFactor = 485; BFactor = 356; end // GR = 1.88, GB = 1.38
		343 : begin RFactor = 474; BFactor = 364; end // GR = 1.88, GB = 1.44
		344 : begin RFactor = 464; BFactor = 372; end // GR = 1.88, GB = 1.50
		345 : begin RFactor = 455; BFactor = 379; end // GR = 1.88, GB = 1.56
		346 : begin RFactor = 446; BFactor = 387; end // GR = 1.88, GB = 1.62
		347 : begin RFactor = 438; BFactor = 395; end // GR = 1.88, GB = 1.69
		348 : begin RFactor = 430; BFactor = 402; end // GR = 1.88, GB = 1.75
		349 : begin RFactor = 422; BFactor = 409; end // GR = 1.88, GB = 1.81
		350 : begin RFactor = 415; BFactor = 416; end // GR = 1.88, GB = 1.88
		351 : begin RFactor = 409; BFactor = 423; end // GR = 1.88, GB = 1.94
		352 : begin RFactor = 402; BFactor = 430; end // GR = 1.88, GB = 2.00
		353 : begin RFactor = 396; BFactor = 437; end // GR = 1.88, GB = 2.06
		354 : begin RFactor = 390; BFactor = 444; end // GR = 1.88, GB = 2.12
		355 : begin RFactor = 384; BFactor = 450; end // GR = 1.88, GB = 2.19
		356 : begin RFactor = 379; BFactor = 457; end // GR = 1.88, GB = 2.25
		357 : begin RFactor = 374; BFactor = 463; end // GR = 1.88, GB = 2.31
		358 : begin RFactor = 369; BFactor = 469; end // GR = 1.88, GB = 2.38
		359 : begin RFactor = 364; BFactor = 476; end // GR = 1.88, GB = 2.44
		360 : begin RFactor = 578; BFactor = 297; end // GR = 1.94, GB = 1.00
		361 : begin RFactor = 561; BFactor = 307; end // GR = 1.94, GB = 1.06
		362 : begin RFactor = 545; BFactor = 316; end // GR = 1.94, GB = 1.12
		363 : begin RFactor = 531; BFactor = 325; end // GR = 1.94, GB = 1.19
		364 : begin RFactor = 517; BFactor = 333; end // GR = 1.94, GB = 1.25
		365 : begin RFactor = 505; BFactor = 342; end // GR = 1.94, GB = 1.31
		366 : begin RFactor = 493; BFactor = 350; end // GR = 1.94, GB = 1.38
		367 : begin RFactor = 482; BFactor = 358; end // GR = 1.94, GB = 1.44
		368 : begin RFactor = 472; BFactor = 366; end // GR = 1.94, GB = 1.50
		369 : begin RFactor = 462; BFactor = 373; end // GR = 1.94, GB = 1.56
		370 : begin RFactor = 453; BFactor = 381; end // GR = 1.94, GB = 1.62
		371 : begin RFactor = 445; BFactor = 388; end // GR = 1.94, GB = 1.69
		372 : begin RFactor = 437; BFactor = 395; end // GR = 1.94, GB = 1.75
		373 : begin RFactor = 429; BFactor = 403; end // GR = 1.94, GB = 1.81
		374 : begin RFactor = 422; BFactor = 410; end // GR = 1.94, GB = 1.88
		375 : begin RFactor = 415; BFactor = 416; end // GR = 1.94, GB = 1.94
		376 : begin RFactor = 409; BFactor = 423; end // GR = 1.94, GB = 2.00
		377 : begin RFactor = 402; BFactor = 430; end // GR = 1.94, GB = 2.06
		378 : begin RFactor = 396; BFactor = 436; end // GR = 1.94, GB = 2.12
		379 : begin RFactor = 391; BFactor = 443; end // GR = 1.94, GB = 2.19
		380 : begin RFactor = 385; BFactor = 449; end // GR = 1.94, GB = 2.25
		381 : begin RFactor = 380; BFactor = 456; end // GR = 1.94, GB = 2.31
		382 : begin RFactor = 375; BFactor = 462; end // GR = 1.94, GB = 2.38
		383 : begin RFactor = 370; BFactor = 468; end // GR = 1.94, GB = 2.44
		384 : begin RFactor = 587; BFactor = 293; end // GR = 2.00, GB = 1.00
		385 : begin RFactor = 570; BFactor = 302; end // GR = 2.00, GB = 1.06
		386 : begin RFactor = 554; BFactor = 311; end // GR = 2.00, GB = 1.12
		387 : begin RFactor = 539; BFactor = 319; end // GR = 2.00, GB = 1.19
		388 : begin RFactor = 525; BFactor = 328; end // GR = 2.00, GB = 1.25
		389 : begin RFactor = 513; BFactor = 336; end // GR = 2.00, GB = 1.31
		390 : begin RFactor = 501; BFactor = 344; end // GR = 2.00, GB = 1.38
		391 : begin RFactor = 490; BFactor = 352; end // GR = 2.00, GB = 1.44
		392 : begin RFactor = 479; BFactor = 360; end // GR = 2.00, GB = 1.50
		393 : begin RFactor = 470; BFactor = 367; end // GR = 2.00, GB = 1.56
		394 : begin RFactor = 461; BFactor = 375; end // GR = 2.00, GB = 1.62
		395 : begin RFactor = 452; BFactor = 382; end // GR = 2.00, GB = 1.69
		396 : begin RFactor = 444; BFactor = 389; end // GR = 2.00, GB = 1.75
		397 : begin RFactor = 436; BFactor = 396; end // GR = 2.00, GB = 1.81
		398 : begin RFactor = 429; BFactor = 403; end // GR = 2.00, GB = 1.88
		399 : begin RFactor = 422; BFactor = 410; end // GR = 2.00, GB = 1.94
		400 : begin RFactor = 415; BFactor = 417; end // GR = 2.00, GB = 2.00
		401 : begin RFactor = 409; BFactor = 423; end // GR = 2.00, GB = 2.06
		402 : begin RFactor = 403; BFactor = 430; end // GR = 2.00, GB = 2.12
		403 : begin RFactor = 397; BFactor = 436; end // GR = 2.00, GB = 2.19
		404 : begin RFactor = 391; BFactor = 442; end // GR = 2.00, GB = 2.25
		405 : begin RFactor = 386; BFactor = 448; end // GR = 2.00, GB = 2.31
		406 : begin RFactor = 381; BFactor = 455; end // GR = 2.00, GB = 2.38
		407 : begin RFactor = 376; BFactor = 461; end // GR = 2.00, GB = 2.44
		408 : begin RFactor = 596; BFactor = 288; end // GR = 2.06, GB = 1.00
		409 : begin RFactor = 578; BFactor = 297; end // GR = 2.06, GB = 1.06
		410 : begin RFactor = 562; BFactor = 306; end // GR = 2.06, GB = 1.12
		411 : begin RFactor = 547; BFactor = 315; end // GR = 2.06, GB = 1.19
		412 : begin RFactor = 533; BFactor = 323; end // GR = 2.06, GB = 1.25
		413 : begin RFactor = 520; BFactor = 331; end // GR = 2.06, GB = 1.31
		414 : begin RFactor = 508; BFactor = 339; end // GR = 2.06, GB = 1.38
		415 : begin RFactor = 497; BFactor = 347; end // GR = 2.06, GB = 1.44
		416 : begin RFactor = 487; BFactor = 354; end // GR = 2.06, GB = 1.50
		417 : begin RFactor = 477; BFactor = 362; end // GR = 2.06, GB = 1.56
		418 : begin RFactor = 468; BFactor = 369; end // GR = 2.06, GB = 1.62
		419 : begin RFactor = 459; BFactor = 376; end // GR = 2.06, GB = 1.69
		420 : begin RFactor = 451; BFactor = 383; end // GR = 2.06, GB = 1.75
		421 : begin RFactor = 443; BFactor = 390; end // GR = 2.06, GB = 1.81
		422 : begin RFactor = 435; BFactor = 397; end // GR = 2.06, GB = 1.88
		423 : begin RFactor = 428; BFactor = 404; end // GR = 2.06, GB = 1.94
		424 : begin RFactor = 421; BFactor = 410; end // GR = 2.06, GB = 2.00
		425 : begin RFactor = 415; BFactor = 417; end // GR = 2.06, GB = 2.06
		426 : begin RFactor = 409; BFactor = 423; end // GR = 2.06, GB = 2.12
		427 : begin RFactor = 403; BFactor = 429; end // GR = 2.06, GB = 2.19
		428 : begin RFactor = 397; BFactor = 435; end // GR = 2.06, GB = 2.25
		429 : begin RFactor = 392; BFactor = 442; end // GR = 2.06, GB = 2.31
		430 : begin RFactor = 387; BFactor = 448; end // GR = 2.06, GB = 2.38
		431 : begin RFactor = 382; BFactor = 454; end // GR = 2.06, GB = 2.44
		432 : begin RFactor = 605; BFactor = 284; end // GR = 2.12, GB = 1.00
		433 : begin RFactor = 587; BFactor = 293; end // GR = 2.12, GB = 1.06
		434 : begin RFactor = 570; BFactor = 302; end // GR = 2.12, GB = 1.12
		435 : begin RFactor = 555; BFactor = 310; end // GR = 2.12, GB = 1.19
		436 : begin RFactor = 541; BFactor = 318; end // GR = 2.12, GB = 1.25
		437 : begin RFactor = 528; BFactor = 326; end // GR = 2.12, GB = 1.31
		438 : begin RFactor = 516; BFactor = 334; end // GR = 2.12, GB = 1.38
		439 : begin RFactor = 505; BFactor = 342; end // GR = 2.12, GB = 1.44
		440 : begin RFactor = 494; BFactor = 349; end // GR = 2.12, GB = 1.50
		441 : begin RFactor = 484; BFactor = 356; end // GR = 2.12, GB = 1.56
		442 : begin RFactor = 475; BFactor = 364; end // GR = 2.12, GB = 1.62
		443 : begin RFactor = 466; BFactor = 371; end // GR = 2.12, GB = 1.69
		444 : begin RFactor = 457; BFactor = 378; end // GR = 2.12, GB = 1.75
		445 : begin RFactor = 449; BFactor = 384; end // GR = 2.12, GB = 1.81
		446 : begin RFactor = 442; BFactor = 391; end // GR = 2.12, GB = 1.88
		447 : begin RFactor = 435; BFactor = 398; end // GR = 2.12, GB = 1.94
		448 : begin RFactor = 428; BFactor = 404; end // GR = 2.12, GB = 2.00
		449 : begin RFactor = 421; BFactor = 410; end // GR = 2.12, GB = 2.06
		450 : begin RFactor = 415; BFactor = 417; end // GR = 2.12, GB = 2.12
		451 : begin RFactor = 409; BFactor = 423; end // GR = 2.12, GB = 2.19
		452 : begin RFactor = 403; BFactor = 429; end // GR = 2.12, GB = 2.25
		453 : begin RFactor = 398; BFactor = 435; end // GR = 2.12, GB = 2.31
		454 : begin RFactor = 392; BFactor = 441; end // GR = 2.12, GB = 2.38
		455 : begin RFactor = 387; BFactor = 447; end // GR = 2.12, GB = 2.44
		456 : begin RFactor = 614; BFactor = 280; end // GR = 2.19, GB = 1.00
		457 : begin RFactor = 595; BFactor = 289; end // GR = 2.19, GB = 1.06
		458 : begin RFactor = 579; BFactor = 297; end // GR = 2.19, GB = 1.12
		459 : begin RFactor = 563; BFactor = 305; end // GR = 2.19, GB = 1.19
		460 : begin RFactor = 549; BFactor = 314; end // GR = 2.19, GB = 1.25
		461 : begin RFactor = 536; BFactor = 321; end // GR = 2.19, GB = 1.31
		462 : begin RFactor = 523; BFactor = 329; end // GR = 2.19, GB = 1.38
		463 : begin RFactor = 512; BFactor = 337; end // GR = 2.19, GB = 1.44
		464 : begin RFactor = 501; BFactor = 344; end // GR = 2.19, GB = 1.50
		465 : begin RFactor = 491; BFactor = 351; end // GR = 2.19, GB = 1.56
		466 : begin RFactor = 481; BFactor = 358; end // GR = 2.19, GB = 1.62
		467 : begin RFactor = 472; BFactor = 365; end // GR = 2.19, GB = 1.69
		468 : begin RFactor = 464; BFactor = 372; end // GR = 2.19, GB = 1.75
		469 : begin RFactor = 456; BFactor = 379; end // GR = 2.19, GB = 1.81
		470 : begin RFactor = 448; BFactor = 385; end // GR = 2.19, GB = 1.88
		471 : begin RFactor = 441; BFactor = 392; end // GR = 2.19, GB = 1.94
		472 : begin RFactor = 434; BFactor = 398; end // GR = 2.19, GB = 2.00
		473 : begin RFactor = 427; BFactor = 405; end // GR = 2.19, GB = 2.06
		474 : begin RFactor = 421; BFactor = 411; end // GR = 2.19, GB = 2.12
		475 : begin RFactor = 415; BFactor = 417; end // GR = 2.19, GB = 2.19
		476 : begin RFactor = 409; BFactor = 423; end // GR = 2.19, GB = 2.25
		477 : begin RFactor = 403; BFactor = 429; end // GR = 2.19, GB = 2.31
		478 : begin RFactor = 398; BFactor = 435; end // GR = 2.19, GB = 2.38
		479 : begin RFactor = 393; BFactor = 440; end // GR = 2.19, GB = 2.44
		480 : begin RFactor = 622; BFactor = 276; end // GR = 2.25, GB = 1.00
		481 : begin RFactor = 604; BFactor = 285; end // GR = 2.25, GB = 1.06
		482 : begin RFactor = 587; BFactor = 293; end // GR = 2.25, GB = 1.12
		483 : begin RFactor = 571; BFactor = 301; end // GR = 2.25, GB = 1.19
		484 : begin RFactor = 557; BFactor = 309; end // GR = 2.25, GB = 1.25
		485 : begin RFactor = 543; BFactor = 317; end // GR = 2.25, GB = 1.31
		486 : begin RFactor = 531; BFactor = 325; end // GR = 2.25, GB = 1.38
		487 : begin RFactor = 519; BFactor = 332; end // GR = 2.25, GB = 1.44
		488 : begin RFactor = 508; BFactor = 339; end // GR = 2.25, GB = 1.50
		489 : begin RFactor = 498; BFactor = 346; end // GR = 2.25, GB = 1.56
		490 : begin RFactor = 488; BFactor = 353; end // GR = 2.25, GB = 1.62
		491 : begin RFactor = 479; BFactor = 360; end // GR = 2.25, GB = 1.69
		492 : begin RFactor = 470; BFactor = 367; end // GR = 2.25, GB = 1.75
		493 : begin RFactor = 462; BFactor = 373; end // GR = 2.25, GB = 1.81
		494 : begin RFactor = 454; BFactor = 380; end // GR = 2.25, GB = 1.88
		495 : begin RFactor = 447; BFactor = 386; end // GR = 2.25, GB = 1.94
		496 : begin RFactor = 440; BFactor = 393; end // GR = 2.25, GB = 2.00
		497 : begin RFactor = 433; BFactor = 399; end // GR = 2.25, GB = 2.06
		498 : begin RFactor = 427; BFactor = 405; end // GR = 2.25, GB = 2.12
		499 : begin RFactor = 421; BFactor = 411; end // GR = 2.25, GB = 2.19
		500 : begin RFactor = 415; BFactor = 417; end // GR = 2.25, GB = 2.25
		501 : begin RFactor = 409; BFactor = 423; end // GR = 2.25, GB = 2.31
		502 : begin RFactor = 404; BFactor = 429; end // GR = 2.25, GB = 2.38
		503 : begin RFactor = 398; BFactor = 434; end // GR = 2.25, GB = 2.44
		504 : begin RFactor = 631; BFactor = 272; end // GR = 2.31, GB = 1.00
		505 : begin RFactor = 612; BFactor = 281; end // GR = 2.31, GB = 1.06
		506 : begin RFactor = 595; BFactor = 289; end // GR = 2.31, GB = 1.12
		507 : begin RFactor = 579; BFactor = 297; end // GR = 2.31, GB = 1.19
		508 : begin RFactor = 564; BFactor = 305; end // GR = 2.31, GB = 1.25
		509 : begin RFactor = 551; BFactor = 313; end // GR = 2.31, GB = 1.31
		510 : begin RFactor = 538; BFactor = 320; end // GR = 2.31, GB = 1.38
		511 : begin RFactor = 526; BFactor = 327; end // GR = 2.31, GB = 1.44
		512 : begin RFactor = 515; BFactor = 335; end // GR = 2.31, GB = 1.50
		513 : begin RFactor = 505; BFactor = 342; end // GR = 2.31, GB = 1.56
		514 : begin RFactor = 495; BFactor = 348; end // GR = 2.31, GB = 1.62
		515 : begin RFactor = 485; BFactor = 355; end // GR = 2.31, GB = 1.69
		516 : begin RFactor = 477; BFactor = 362; end // GR = 2.31, GB = 1.75
		517 : begin RFactor = 468; BFactor = 368; end // GR = 2.31, GB = 1.81
		518 : begin RFactor = 461; BFactor = 375; end // GR = 2.31, GB = 1.88
		519 : begin RFactor = 453; BFactor = 381; end // GR = 2.31, GB = 1.94
		520 : begin RFactor = 446; BFactor = 387; end // GR = 2.31, GB = 2.00
		521 : begin RFactor = 439; BFactor = 393; end // GR = 2.31, GB = 2.06
		522 : begin RFactor = 433; BFactor = 399; end // GR = 2.31, GB = 2.12
		523 : begin RFactor = 426; BFactor = 405; end // GR = 2.31, GB = 2.19
		524 : begin RFactor = 420; BFactor = 411; end // GR = 2.31, GB = 2.25
		525 : begin RFactor = 415; BFactor = 417; end // GR = 2.31, GB = 2.31
		526 : begin RFactor = 409; BFactor = 423; end // GR = 2.31, GB = 2.38
		527 : begin RFactor = 404; BFactor = 428; end // GR = 2.31, GB = 2.44
		528 : begin RFactor = 639; BFactor = 269; end // GR = 2.38, GB = 1.00
		529 : begin RFactor = 620; BFactor = 277; end // GR = 2.38, GB = 1.06
		530 : begin RFactor = 603; BFactor = 285; end // GR = 2.38, GB = 1.12
		531 : begin RFactor = 586; BFactor = 293; end // GR = 2.38, GB = 1.19
		532 : begin RFactor = 572; BFactor = 301; end // GR = 2.38, GB = 1.25
		533 : begin RFactor = 558; BFactor = 308; end // GR = 2.38, GB = 1.31
		534 : begin RFactor = 545; BFactor = 316; end // GR = 2.38, GB = 1.38
		535 : begin RFactor = 533; BFactor = 323; end // GR = 2.38, GB = 1.44
		536 : begin RFactor = 522; BFactor = 330; end // GR = 2.38, GB = 1.50
		537 : begin RFactor = 511; BFactor = 337; end // GR = 2.38, GB = 1.56
		538 : begin RFactor = 501; BFactor = 344; end // GR = 2.38, GB = 1.62
		539 : begin RFactor = 492; BFactor = 351; end // GR = 2.38, GB = 1.69
		540 : begin RFactor = 483; BFactor = 357; end // GR = 2.38, GB = 1.75
		541 : begin RFactor = 475; BFactor = 364; end // GR = 2.38, GB = 1.81
		542 : begin RFactor = 467; BFactor = 370; end // GR = 2.38, GB = 1.88
		543 : begin RFactor = 459; BFactor = 376; end // GR = 2.38, GB = 1.94
		544 : begin RFactor = 452; BFactor = 382; end // GR = 2.38, GB = 2.00
		545 : begin RFactor = 445; BFactor = 388; end // GR = 2.38, GB = 2.06
		546 : begin RFactor = 438; BFactor = 394; end // GR = 2.38, GB = 2.12
		547 : begin RFactor = 432; BFactor = 400; end // GR = 2.38, GB = 2.19
		548 : begin RFactor = 426; BFactor = 406; end // GR = 2.38, GB = 2.25
		549 : begin RFactor = 420; BFactor = 411; end // GR = 2.38, GB = 2.31
		550 : begin RFactor = 415; BFactor = 417; end // GR = 2.38, GB = 2.38
		551 : begin RFactor = 409; BFactor = 423; end // GR = 2.38, GB = 2.44
		552 : begin RFactor = 647; BFactor = 265; end // GR = 2.44, GB = 1.00
		553 : begin RFactor = 628; BFactor = 273; end // GR = 2.44, GB = 1.06
		554 : begin RFactor = 610; BFactor = 281; end // GR = 2.44, GB = 1.12
		555 : begin RFactor = 594; BFactor = 289; end // GR = 2.44, GB = 1.19
		556 : begin RFactor = 579; BFactor = 297; end // GR = 2.44, GB = 1.25
		557 : begin RFactor = 565; BFactor = 304; end // GR = 2.44, GB = 1.31
		558 : begin RFactor = 552; BFactor = 312; end // GR = 2.44, GB = 1.38
		559 : begin RFactor = 540; BFactor = 319; end // GR = 2.44, GB = 1.44
		560 : begin RFactor = 528; BFactor = 326; end // GR = 2.44, GB = 1.50
		561 : begin RFactor = 518; BFactor = 333; end // GR = 2.44, GB = 1.56
		562 : begin RFactor = 508; BFactor = 339; end // GR = 2.44, GB = 1.62
		563 : begin RFactor = 498; BFactor = 346; end // GR = 2.44, GB = 1.69
		564 : begin RFactor = 489; BFactor = 352; end // GR = 2.44, GB = 1.75
		565 : begin RFactor = 481; BFactor = 359; end // GR = 2.44, GB = 1.81
		566 : begin RFactor = 473; BFactor = 365; end // GR = 2.44, GB = 1.88
		567 : begin RFactor = 465; BFactor = 371; end // GR = 2.44, GB = 1.94
		568 : begin RFactor = 458; BFactor = 377; end // GR = 2.44, GB = 2.00
		569 : begin RFactor = 451; BFactor = 383; end // GR = 2.44, GB = 2.06
		570 : begin RFactor = 444; BFactor = 389; end // GR = 2.44, GB = 2.12
		571 : begin RFactor = 438; BFactor = 395; end // GR = 2.44, GB = 2.19
		572 : begin RFactor = 431; BFactor = 401; end // GR = 2.44, GB = 2.25
		573 : begin RFactor = 426; BFactor = 406; end // GR = 2.44, GB = 2.31
		574 : begin RFactor = 420; BFactor = 412; end // GR = 2.44, GB = 2.38
		575 : begin RFactor = 414; BFactor = 417; end // GR = 2.44, GB = 2.44
		
		endcase
		
	end
	
	endtask
	
	function[ `size_int - 1 : 0 ]LUTPow033(	input[ `size_int - 1 : 0 ]Index );
	
	begin
		
		case( Index )
			
			0 : LUTPow033 = 0;
			1 : LUTPow033 = 256;
			2 : LUTPow033 = 322;
			3 : LUTPow033 = 369;
			4 : LUTPow033 = 406;
			5 : LUTPow033 = 437;
			6 : LUTPow033 = 465;
			7 : LUTPow033 = 489;
			8 : LUTPow033 = 511;
			9 : LUTPow033 = 532;
			10 : LUTPow033 = 551;
			11 : LUTPow033 = 569;
			12 : LUTPow033 = 586;
			13 : LUTPow033 = 601;
			14 : LUTPow033 = 616;
			15 : LUTPow033 = 631;
			16 : LUTPow033 = 645;
			17 : LUTPow033 = 658;
			18 : LUTPow033 = 670;
			19 : LUTPow033 = 683;
			20 : LUTPow033 = 694;
			21 : LUTPow033 = 706;
			22 : LUTPow033 = 717;
			23 : LUTPow033 = 728;
			24 : LUTPow033 = 738;
			25 : LUTPow033 = 748;
			26 : LUTPow033 = 758;
			27 : LUTPow033 = 767;
			28 : LUTPow033 = 777;
			29 : LUTPow033 = 786;
			30 : LUTPow033 = 795;
			31 : LUTPow033 = 804;
			32 : LUTPow033 = 812;
			33 : LUTPow033 = 821;
			34 : LUTPow033 = 829;
			35 : LUTPow033 = 837;
			36 : LUTPow033 = 845;
			37 : LUTPow033 = 853;
			38 : LUTPow033 = 860;
			39 : LUTPow033 = 868;
			40 : LUTPow033 = 875;
			41 : LUTPow033 = 882;
			42 : LUTPow033 = 889;
			43 : LUTPow033 = 896;
			44 : LUTPow033 = 903;
			45 : LUTPow033 = 910;
			46 : LUTPow033 = 917;
			47 : LUTPow033 = 923;
			48 : LUTPow033 = 930;
			49 : LUTPow033 = 936;
			50 : LUTPow033 = 943;
			51 : LUTPow033 = 949;
			52 : LUTPow033 = 955;
			53 : LUTPow033 = 961;
			54 : LUTPow033 = 967;
			55 : LUTPow033 = 973;
			56 : LUTPow033 = 979;
			57 : LUTPow033 = 985;
			58 : LUTPow033 = 990;
			59 : LUTPow033 = 996;
			60 : LUTPow033 = 1002;
			61 : LUTPow033 = 1007;
			62 : LUTPow033 = 1013;
			63 : LUTPow033 = 1018;
			64 : LUTPow033 = 1023;
			65 : LUTPow033 = 1029;
			66 : LUTPow033 = 1034;
			67 : LUTPow033 = 1039;
			68 : LUTPow033 = 1044;
			69 : LUTPow033 = 1050;
			70 : LUTPow033 = 1055;
			71 : LUTPow033 = 1060;
			72 : LUTPow033 = 1065;
			73 : LUTPow033 = 1069;
			74 : LUTPow033 = 1074;
			75 : LUTPow033 = 1079;
			76 : LUTPow033 = 1084;
			77 : LUTPow033 = 1089;
			78 : LUTPow033 = 1093;
			79 : LUTPow033 = 1098;
			80 : LUTPow033 = 1103;
			81 : LUTPow033 = 1107;
			82 : LUTPow033 = 1112;
			83 : LUTPow033 = 1116;
			84 : LUTPow033 = 1121;
			85 : LUTPow033 = 1125;
			86 : LUTPow033 = 1129;
			87 : LUTPow033 = 1134;
			88 : LUTPow033 = 1138;
			89 : LUTPow033 = 1142;
			90 : LUTPow033 = 1147;
			91 : LUTPow033 = 1151;
			92 : LUTPow033 = 1155;
			93 : LUTPow033 = 1159;
			94 : LUTPow033 = 1163;
			95 : LUTPow033 = 1168;
			96 : LUTPow033 = 1172;
			97 : LUTPow033 = 1176;
			98 : LUTPow033 = 1180;
			99 : LUTPow033 = 1184;
			100 : LUTPow033 = 1188;
			101 : LUTPow033 = 1192;
			102 : LUTPow033 = 1196;
			103 : LUTPow033 = 1200;
			104 : LUTPow033 = 1203;
			105 : LUTPow033 = 1207;
			106 : LUTPow033 = 1211;
			107 : LUTPow033 = 1215;
			108 : LUTPow033 = 1219;
			109 : LUTPow033 = 1222;
			110 : LUTPow033 = 1226;
			111 : LUTPow033 = 1230;
			112 : LUTPow033 = 1233;
			113 : LUTPow033 = 1237;
			114 : LUTPow033 = 1241;
			115 : LUTPow033 = 1244;
			116 : LUTPow033 = 1248;
			117 : LUTPow033 = 1252;
			118 : LUTPow033 = 1255;
			119 : LUTPow033 = 1259;
			120 : LUTPow033 = 1262;
			121 : LUTPow033 = 1266;
			122 : LUTPow033 = 1269;
			123 : LUTPow033 = 1273;
			124 : LUTPow033 = 1276;
			125 : LUTPow033 = 1279;
			126 : LUTPow033 = 1283;
			127 : LUTPow033 = 1286;
			128 : LUTPow033 = 1290;
			129 : LUTPow033 = 1293;
			130 : LUTPow033 = 1296;
			131 : LUTPow033 = 1300;
			132 : LUTPow033 = 1303;
			133 : LUTPow033 = 1306;
			134 : LUTPow033 = 1310;
			135 : LUTPow033 = 1313;
			136 : LUTPow033 = 1316;
			137 : LUTPow033 = 1319;
			138 : LUTPow033 = 1322;
			139 : LUTPow033 = 1326;
			140 : LUTPow033 = 1329;
			141 : LUTPow033 = 1332;
			142 : LUTPow033 = 1335;
			143 : LUTPow033 = 1338;
			144 : LUTPow033 = 1341;
			145 : LUTPow033 = 1344;
			146 : LUTPow033 = 1348;
			147 : LUTPow033 = 1351;
			148 : LUTPow033 = 1354;
			149 : LUTPow033 = 1357;
			150 : LUTPow033 = 1360;
			151 : LUTPow033 = 1363;
			152 : LUTPow033 = 1366;
			153 : LUTPow033 = 1369;
			154 : LUTPow033 = 1372;
			155 : LUTPow033 = 1375;
			156 : LUTPow033 = 1378;
			157 : LUTPow033 = 1381;
			158 : LUTPow033 = 1383;
			159 : LUTPow033 = 1386;
			160 : LUTPow033 = 1389;
			161 : LUTPow033 = 1392;
			162 : LUTPow033 = 1395;
			163 : LUTPow033 = 1398;
			164 : LUTPow033 = 1401;
			165 : LUTPow033 = 1404;
			166 : LUTPow033 = 1406;
			167 : LUTPow033 = 1409;
			168 : LUTPow033 = 1412;
			169 : LUTPow033 = 1415;
			170 : LUTPow033 = 1418;
			171 : LUTPow033 = 1420;
			172 : LUTPow033 = 1423;
			173 : LUTPow033 = 1426;
			174 : LUTPow033 = 1429;
			175 : LUTPow033 = 1431;
			176 : LUTPow033 = 1434;
			177 : LUTPow033 = 1437;
			178 : LUTPow033 = 1440;
			179 : LUTPow033 = 1442;
			180 : LUTPow033 = 1445;
			181 : LUTPow033 = 1448;
			182 : LUTPow033 = 1450;
			183 : LUTPow033 = 1453;
			184 : LUTPow033 = 1456;
			185 : LUTPow033 = 1458;
			186 : LUTPow033 = 1461;
			187 : LUTPow033 = 1463;
			188 : LUTPow033 = 1466;
			189 : LUTPow033 = 1469;
			190 : LUTPow033 = 1471;
			191 : LUTPow033 = 1474;
			192 : LUTPow033 = 1476;
			193 : LUTPow033 = 1479;
			194 : LUTPow033 = 1481;
			195 : LUTPow033 = 1484;
			196 : LUTPow033 = 1487;
			197 : LUTPow033 = 1489;
			198 : LUTPow033 = 1492;
			199 : LUTPow033 = 1494;
			200 : LUTPow033 = 1497;
			201 : LUTPow033 = 1499;
			202 : LUTPow033 = 1502;
			203 : LUTPow033 = 1504;
			204 : LUTPow033 = 1507;
			205 : LUTPow033 = 1509;
			206 : LUTPow033 = 1511;
			207 : LUTPow033 = 1514;
			208 : LUTPow033 = 1516;
			209 : LUTPow033 = 1519;
			210 : LUTPow033 = 1521;
			211 : LUTPow033 = 1524;
			212 : LUTPow033 = 1526;
			213 : LUTPow033 = 1528;
			214 : LUTPow033 = 1531;
			215 : LUTPow033 = 1533;
			216 : LUTPow033 = 1535;
			217 : LUTPow033 = 1538;
			218 : LUTPow033 = 1540;
			219 : LUTPow033 = 1543;
			220 : LUTPow033 = 1545;
			221 : LUTPow033 = 1547;
			222 : LUTPow033 = 1550;
			223 : LUTPow033 = 1552;
			224 : LUTPow033 = 1554;
			225 : LUTPow033 = 1557;
			226 : LUTPow033 = 1559;
			227 : LUTPow033 = 1561;
			228 : LUTPow033 = 1563;
			229 : LUTPow033 = 1566;
			230 : LUTPow033 = 1568;
			231 : LUTPow033 = 1570;
			232 : LUTPow033 = 1573;
			233 : LUTPow033 = 1575;
			234 : LUTPow033 = 1577;
			235 : LUTPow033 = 1579;
			236 : LUTPow033 = 1582;
			237 : LUTPow033 = 1584;
			238 : LUTPow033 = 1586;
			239 : LUTPow033 = 1588;
			240 : LUTPow033 = 1590;
			241 : LUTPow033 = 1593;
			242 : LUTPow033 = 1595;
			243 : LUTPow033 = 1597;
			244 : LUTPow033 = 1599;
			245 : LUTPow033 = 1601;
			246 : LUTPow033 = 1604;
			247 : LUTPow033 = 1606;
			248 : LUTPow033 = 1608;
			249 : LUTPow033 = 1610;
			250 : LUTPow033 = 1612;
			251 : LUTPow033 = 1614;
			252 : LUTPow033 = 1616;
			253 : LUTPow033 = 1619;
			254 : LUTPow033 = 1621;
			255 : LUTPow033 = 1623;
			256 : LUTPow033 = 1625;
			
		endcase
		
	end
	
	endfunction
	
	function[ `size_int - 1 : 0 ]LUTPow045(	input[ `size_int - 1 : 0 ]source );
	
	begin
		
		case( source )
			
			// ( ( RGB / 256 ) ^ 0.45 ) * 256 * 256
			0 : LUTPow045 = 0;
			1 : LUTPow045 = 5404;
			2 : LUTPow045 = 7383;
			3 : LUTPow045 = 8860;
			4 : LUTPow045 = 10085;
			5 : LUTPow045 = 11150;
			6 : LUTPow045 = 12104;
			7 : LUTPow045 = 12973;
			8 : LUTPow045 = 13777;
			9 : LUTPow045 = 14527;
			10 : LUTPow045 = 15232;
			11 : LUTPow045 = 15900;
			12 : LUTPow045 = 16534;
			13 : LUTPow045 = 17141;
			14 : LUTPow045 = 17722;
			15 : LUTPow045 = 18281;
			16 : LUTPow045 = 18820;
			17 : LUTPow045 = 19340;
			18 : LUTPow045 = 19844;
			19 : LUTPow045 = 20333;
			20 : LUTPow045 = 20808;
			21 : LUTPow045 = 21270;
			22 : LUTPow045 = 21720;
			23 : LUTPow045 = 22158;
			24 : LUTPow045 = 22587;
			25 : LUTPow045 = 23006;
			26 : LUTPow045 = 23415;
			27 : LUTPow045 = 23816;
			28 : LUTPow045 = 24209;
			29 : LUTPow045 = 24595;
			30 : LUTPow045 = 24973;
			31 : LUTPow045 = 25344;
			32 : LUTPow045 = 25709;
			33 : LUTPow045 = 26067;
			34 : LUTPow045 = 26420;
			35 : LUTPow045 = 26767;
			36 : LUTPow045 = 27108;
			37 : LUTPow045 = 27444;
			38 : LUTPow045 = 27776;
			39 : LUTPow045 = 28102;
			40 : LUTPow045 = 28424;
			41 : LUTPow045 = 28742;
			42 : LUTPow045 = 29055;
			43 : LUTPow045 = 29365;
			44 : LUTPow045 = 29670;
			45 : LUTPow045 = 29972;
			46 : LUTPow045 = 30270;
			47 : LUTPow045 = 30564;
			48 : LUTPow045 = 30855;
			49 : LUTPow045 = 31142;
			50 : LUTPow045 = 31427;
			51 : LUTPow045 = 31708;
			52 : LUTPow045 = 31986;
			53 : LUTPow045 = 32262;
			54 : LUTPow045 = 32534;
			55 : LUTPow045 = 32804;
			56 : LUTPow045 = 33071;
			57 : LUTPow045 = 33336;
			58 : LUTPow045 = 33598;
			59 : LUTPow045 = 33857;
			60 : LUTPow045 = 34114;
			61 : LUTPow045 = 34369;
			62 : LUTPow045 = 34621;
			63 : LUTPow045 = 34871;
			64 : LUTPow045 = 35119;
			65 : LUTPow045 = 35365;
			66 : LUTPow045 = 35609;
			67 : LUTPow045 = 35851;
			68 : LUTPow045 = 36091;
			69 : LUTPow045 = 36329;
			70 : LUTPow045 = 36565;
			71 : LUTPow045 = 36799;
			72 : LUTPow045 = 37031;
			73 : LUTPow045 = 37262;
			74 : LUTPow045 = 37490;
			75 : LUTPow045 = 37718;
			76 : LUTPow045 = 37943;
			77 : LUTPow045 = 38167;
			78 : LUTPow045 = 38389;
			79 : LUTPow045 = 38610;
			80 : LUTPow045 = 38829;
			81 : LUTPow045 = 39047;
			82 : LUTPow045 = 39263;
			83 : LUTPow045 = 39478;
			84 : LUTPow045 = 39691;
			85 : LUTPow045 = 39903;
			86 : LUTPow045 = 40114;
			87 : LUTPow045 = 40323;
			88 : LUTPow045 = 40531;
			89 : LUTPow045 = 40737;
			90 : LUTPow045 = 40943;
			91 : LUTPow045 = 41147;
			92 : LUTPow045 = 41350;
			93 : LUTPow045 = 41551;
			94 : LUTPow045 = 41752;
			95 : LUTPow045 = 41951;
			96 : LUTPow045 = 42149;
			97 : LUTPow045 = 42346;
			98 : LUTPow045 = 42542;
			99 : LUTPow045 = 42737;
			100 : LUTPow045 = 42931;
			101 : LUTPow045 = 43123;
			102 : LUTPow045 = 43315;
			103 : LUTPow045 = 43505;
			104 : LUTPow045 = 43695;
			105 : LUTPow045 = 43884;
			106 : LUTPow045 = 44071;
			107 : LUTPow045 = 44258;
			108 : LUTPow045 = 44443;
			109 : LUTPow045 = 44628;
			110 : LUTPow045 = 44812;
			111 : LUTPow045 = 44995;
			112 : LUTPow045 = 45177;
			113 : LUTPow045 = 45358;
			114 : LUTPow045 = 45538;
			115 : LUTPow045 = 45717;
			116 : LUTPow045 = 45896;
			117 : LUTPow045 = 46073;
			118 : LUTPow045 = 46250;
			119 : LUTPow045 = 46426;
			120 : LUTPow045 = 46601;
			121 : LUTPow045 = 46776;
			122 : LUTPow045 = 46949;
			123 : LUTPow045 = 47122;
			124 : LUTPow045 = 47294;
			125 : LUTPow045 = 47465;
			126 : LUTPow045 = 47636;
			127 : LUTPow045 = 47806;
			128 : LUTPow045 = 47975;
			129 : LUTPow045 = 48143;
			130 : LUTPow045 = 48311;
			131 : LUTPow045 = 48477;
			132 : LUTPow045 = 48644;
			133 : LUTPow045 = 48809;
			134 : LUTPow045 = 48974;
			135 : LUTPow045 = 49138;
			136 : LUTPow045 = 49301;
			137 : LUTPow045 = 49464;
			138 : LUTPow045 = 49626;
			139 : LUTPow045 = 49788;
			140 : LUTPow045 = 49949;
			141 : LUTPow045 = 50109;
			142 : LUTPow045 = 50269;
			143 : LUTPow045 = 50428;
			144 : LUTPow045 = 50586;
			145 : LUTPow045 = 50744;
			146 : LUTPow045 = 50901;
			147 : LUTPow045 = 51058;
			148 : LUTPow045 = 51214;
			149 : LUTPow045 = 51369;
			150 : LUTPow045 = 51524;
			151 : LUTPow045 = 51678;
			152 : LUTPow045 = 51832;
			153 : LUTPow045 = 51985;
			154 : LUTPow045 = 52138;
			155 : LUTPow045 = 52290;
			156 : LUTPow045 = 52441;
			157 : LUTPow045 = 52592;
			158 : LUTPow045 = 52743;
			159 : LUTPow045 = 52893;
			160 : LUTPow045 = 53042;
			161 : LUTPow045 = 53191;
			162 : LUTPow045 = 53340;
			163 : LUTPow045 = 53488;
			164 : LUTPow045 = 53635;
			165 : LUTPow045 = 53782;
			166 : LUTPow045 = 53928;
			167 : LUTPow045 = 54074;
			168 : LUTPow045 = 54220;
			169 : LUTPow045 = 54365;
			170 : LUTPow045 = 54509;
			171 : LUTPow045 = 54653;
			172 : LUTPow045 = 54797;
			173 : LUTPow045 = 54940;
			174 : LUTPow045 = 55083;
			175 : LUTPow045 = 55225;
			176 : LUTPow045 = 55367;
			177 : LUTPow045 = 55508;
			178 : LUTPow045 = 55649;
			179 : LUTPow045 = 55789;
			180 : LUTPow045 = 55929;
			181 : LUTPow045 = 56069;
			182 : LUTPow045 = 56208;
			183 : LUTPow045 = 56347;
			184 : LUTPow045 = 56485;
			185 : LUTPow045 = 56623;
			186 : LUTPow045 = 56761;
			187 : LUTPow045 = 56898;
			188 : LUTPow045 = 57035;
			189 : LUTPow045 = 57171;
			190 : LUTPow045 = 57307;
			191 : LUTPow045 = 57442;
			192 : LUTPow045 = 57578;
			193 : LUTPow045 = 57712;
			194 : LUTPow045 = 57847;
			195 : LUTPow045 = 57981;
			196 : LUTPow045 = 58114;
			197 : LUTPow045 = 58248;
			198 : LUTPow045 = 58380;
			199 : LUTPow045 = 58513;
			200 : LUTPow045 = 58645;
			201 : LUTPow045 = 58777;
			202 : LUTPow045 = 58908;
			203 : LUTPow045 = 59039;
			204 : LUTPow045 = 59170;
			205 : LUTPow045 = 59300;
			206 : LUTPow045 = 59430;
			207 : LUTPow045 = 59560;
			208 : LUTPow045 = 59689;
			209 : LUTPow045 = 59818;
			210 : LUTPow045 = 59947;
			211 : LUTPow045 = 60075;
			212 : LUTPow045 = 60203;
			213 : LUTPow045 = 60331;
			214 : LUTPow045 = 60458;
			215 : LUTPow045 = 60585;
			216 : LUTPow045 = 60712;
			217 : LUTPow045 = 60838;
			218 : LUTPow045 = 60964;
			219 : LUTPow045 = 61090;
			220 : LUTPow045 = 61215;
			221 : LUTPow045 = 61340;
			222 : LUTPow045 = 61465;
			223 : LUTPow045 = 61589;
			224 : LUTPow045 = 61713;
			225 : LUTPow045 = 61837;
			226 : LUTPow045 = 61961;
			227 : LUTPow045 = 62084;
			228 : LUTPow045 = 62207;
			229 : LUTPow045 = 62330;
			230 : LUTPow045 = 62452;
			231 : LUTPow045 = 62574;
			232 : LUTPow045 = 62696;
			233 : LUTPow045 = 62817;
			234 : LUTPow045 = 62938;
			235 : LUTPow045 = 63059;
			236 : LUTPow045 = 63180;
			237 : LUTPow045 = 63300;
			238 : LUTPow045 = 63420;
			239 : LUTPow045 = 63540;
			240 : LUTPow045 = 63660;
			241 : LUTPow045 = 63779;
			242 : LUTPow045 = 63898;
			243 : LUTPow045 = 64016;
			244 : LUTPow045 = 64135;
			245 : LUTPow045 = 64253;
			246 : LUTPow045 = 64371;
			247 : LUTPow045 = 64488;
			248 : LUTPow045 = 64606;
			249 : LUTPow045 = 64723;
			250 : LUTPow045 = 64840;
			251 : LUTPow045 = 64956;
			252 : LUTPow045 = 65073;
			253 : LUTPow045 = 65189;
			254 : LUTPow045 = 65305;
			255 : LUTPow045 = 65420;
			
		endcase
		
	end
	
	endfunction
	
endmodule

module ColorImageProcess_testbench;
	
	// Signal declaration
	reg Clock;
	reg Reset;
	
	reg[ `size_char - 1 : 0 ]R;
	reg[ `size_char - 1 : 0 ]G;
	reg[ `size_char - 1 : 0 ]B;
	
	wire[ `size_char - 1 : 0 ]R_out;
	wire[ `size_char - 1 : 0 ]G_out;
	wire[ `size_char - 1 : 0 ]B_out;
	
	integer i;
	
	integer InputFile;
	integer OutputFile;
	
	reg[ `size_char - 1 : 0 ]ImageDataBlock[ 0 : `SumPixel * 3 ];
	
	ColorImageProcess ColorImageProcess_test
	(
		
		Clock,
		Reset,
		
		R,
		G,
		B,
		
		R_out,
		G_out,
		B_out
		
	);
	
	initial
	begin
		
		#2
		begin
			
			Clock = 0;
			
			// open data for input file
			InputFile = $fopen( "data/IM000565_RAW_20x15.BMP", "rb" );
			//InputFile = $fopen( "data/IM000565_RAW_320x240.BMP", "rb" );
			
			// open data for output file
			OutputFile = $fopen( "data/TEST.BMP", "wb" );
			
		end
		
		//$fread( BitMapHeader, InputFile, 0, `BitMapHeaderLength );
		for( i = 0; i < `BitMapHeaderLength; i = i + 1 )
		#2	$fwriteb( OutputFile, "%c", $fgetc( InputFile ) );
		
		for( i = 0; i < `SumPixel * 3; i = i + 1 )
		#2	ImageDataBlock[ i ] = $fgetc( InputFile );
		
		#2	Reset = 1;
		
	//	#2	Reset = 0;
		
		// Apply Stimulus in order to 
		for( i = 0; i < `SumPixel * 3; i = i + 3 )
		begin
			
			#2
			begin
				
				Reset = 0;
				
				B = ImageDataBlock[ i + 0 ];
				G = ImageDataBlock[ i + 1 ];
				R = ImageDataBlock[ i + 2 ];
				
			end
			
		end
		
		for( i = 0; i < `SumPixel * 3; i = i + 3 )
		begin
			
			#2
			begin
				
				B = ImageDataBlock[ i + 0 ];
				G = ImageDataBlock[ i + 1 ];
				R = ImageDataBlock[ i + 2 ];
				
			end
			
			#4

			#2
			begin
				
				// display information on the screen
				//$display( "R = %X, G = %X, B = %X\t\tR = %X, G = %X, B = %X",
				//ImageDataBlock[ i + 2 ], ImageDataBlock[ i + 1 ], ImageDataBlock[ i + 0 ], R_out, G_out, B_out );
				$fwriteb( OutputFile, "%c", B_out );
				$fwriteb( OutputFile, "%c", G_out );
				$fwriteb( OutputFile, "%c", R_out );
				
			end
			
		end
		
		$fclose( InputFile );
		
		#100000	$stop;
		#100000	$finish;
		
	end
	
	always	#1 Clock = ~Clock;	//Toggle Clock
	
endmodule

