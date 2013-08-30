`include	"Definition.v"
`include	"ProcessProperty.v"

// 1. input and output should be combined together into inout
// 2. look up table should be research more elaborate skill

module CTC
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
	
	reg[ 1 : 0 ]State;
	reg[ 1 : 0 ]NextState;
	
	// state declaration
	parameter InitialState = 0;	// initialization
	parameter WBFactorState = 1;	// calculate white balance factor
	parameter ProcessState = 2;
	
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
				
				RLongTotal = RLongTotal + ScaleR;
				GLongTotal = GLongTotal + ScaleG;
				BLongTotal = BLongTotal + ScaleB;
				
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
		
		endcase
		
	end
	
	assign R_out = WBR >> `ScaleBit;
	assign G_out = WBG >> `ScaleBit;
	assign B_out = WBB >> `ScaleBit;
	
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
	
endmodule

module CTC_testbench;
	
	// Signal declaration
	reg Clock;
	reg Reset;
	
	reg[ `size_char - 1 : 0 ]R;
	reg[ `size_char - 1 : 0 ]G;
	reg[ `size_char - 1 : 0 ]B;
	
	wire[ `size_char - 1 : 0 ]R_out;
	wire[ `size_char - 1 : 0 ]G_out;
	wire[ `size_char - 1 : 0 ]B_out;
	
	reg[ `size_char - 1 : 0 ]RBlock[ 0 : `SumPixel - 1 ];
	reg[ `size_char - 1 : 0 ]GBlock[ 0 : `SumPixel - 1 ];
	reg[ `size_char - 1 : 0 ]BBlock[ 0 : `SumPixel - 1 ];
	
	integer i;
	
	integer RFile;
	integer GFile;
	integer BFile;
	
	CTC CTC_test
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
			
			// open test data file
			$readmemh( "data/IM000565_RAW_20x15R.dat", RBlock );
			$readmemh( "data/IM000565_RAW_20x15G.dat", GBlock );
			$readmemh( "data/IM000565_RAW_20x15B.dat", BBlock );
			
			RFile = $fopen( "data/R.dat" );
			GFile = $fopen( "data/G.dat" );
			BFile = $fopen( "data/B.dat" );
			
		//	$readmemh( "data/IM000565_RAW_320x240R.dat", RBlock );
		//	$readmemh( "data/IM000565_RAW_320x240G.dat", GBlock );
		//	$readmemh( "data/IM000565_RAW_320x240B.dat", BBlock );
			
			Reset = 1;
			
		end
		
		//#2	Reset = 0;
		
		// Apply Stimulus in order to 
		for( i = 0; i < `SumPixel; i = i + 1 )
		begin
			
			#2
			begin
				Reset = 0;
				R = RBlock[ i ];
				G = GBlock[ i ];
				B = BBlock[ i ];
				
			end
			
		end
		
		$fclose( RFile );
		$fclose( GFile );
		$fclose( BFile );
		
		#100000	$stop;
		#100000	$finish;
		
	end
	
	initial	Clock = 0;
	always	#1 Clock = ~Clock;	//Toggle Clock
	
endmodule
