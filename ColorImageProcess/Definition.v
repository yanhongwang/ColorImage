`ifndef DEFINITION

`define DEFINITION

// 2 ^ 9, shift 9 bits is limitation
`define ScaleBit		8
`define ScaleHalfBit		( `ScaleBit >> 1 )
`define ScaleNumber		( 1 << `ScaleBit )
`define MaxThreshold		65535	// 2 ^ ( `BitMapBit + `ScaleBit ) - 1 = 65535
`define MinThreshold		0
`define size_char		8
`define size_int		32
`define	BitMapHeaderLength	14 + 40
`define SumPixel		20 * 15
//`define SumPixel		320 * 240

`endif
