`include	"./Definition.v"

module Divider
(
	
	input[ `size_int - 1 : 0 ]Dividend,
	input[ `size_int - 1 : 0 ]Divisor,
	output reg[ `size_int - 1 : 0 ]Q,			// Quotient
	output reg[ `size_int - 1 : 0 ]Remainder		// Remainder
	
);
	
	// counter
	integer i;
	
	reg[ `size_int - 1 : 0 ]Quotient;			// Quotient
	reg[ `size_int : 0 ]Partial;
	reg[ `size_int - 1 : 0 ]div;
	
	always@( Dividend or Divisor )
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
			Q = Quotient + 1;
		else
			Q = Quotient;
		
	end
	
endmodule

module Divider_testbench;
	
	// Signal declaration
	reg[ `size_int - 1 : 0 ]Dividend;
	reg[ `size_int - 1 : 0 ]Divisor;
	
	wire[ `size_int - 1 : 0 ]Q;
	wire[ `size_int - 1 : 0 ]Remainder;
	
	Divider Divider_test( Dividend, Divisor, Q, Remainder );
	
	initial
	begin
		
		#2
		begin
			
			Dividend = 100;
			Divisor = 3;
			
		end
		
		#2	$display( "Dividend = %d\tDivisor = %d\tQuotient = %d\tRemainder = %d",
				Dividend, Divisor, Q, Remainder );
		
		#2
		begin
			
			Dividend = 200;
			Divisor = 7;
			
		end
		
		#2	$display( "Dividend = %d\tDivisor = %d\tQuotient = %d\tRemainder = %d",
				Dividend, Divisor, Q, Remainder );
		
		#2
		begin
			
			Dividend = 400;
			Divisor = 5;
			
		end
		
		#2	$display( "Dividend = %d\tDivisor = %d\tQuotient = %d\tRemainder = %d",
				Dividend, Divisor, Q, Remainder );
		
		#2	$stop;
		#2	$finish;
		
	end
	
endmodule
