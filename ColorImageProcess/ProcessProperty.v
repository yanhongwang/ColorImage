// auto level definition
`define		HighThreshold	( 250 << `ScaleBit )
`define		LowThreshold	( 5 << `ScaleBit )
`define		AutoLevelRange	( `HighThreshold - `LowThreshold )
`define		ALFactor	( 256 << `ScaleBit ) / `AutoLevelRange
// The priority of the combination of operator shift is lower than +-*/
// To avoid that, you may add parenthesis between the operation of operator shift

// auto white balance
`define		WBRCorrection	294	// 256 * 1.15 = 294.40
`define		WBBCorrection	223	// 256 / 1.15 = 222.60869

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

// RGB2XYZ
`define		RGB2XYZ1	106	// 0.412453 * `ScaleNumber = 105.587968
`define		RGB2XYZ2	92	// 0.357580 * `ScaleNumber = 91.54048
`define		RGB2XYZ3	46	// 0.180423 * `ScaleNumber = 46.188288
`define		RGB2XYZ4	54	// 0.212671 * `ScaleNumber = 54.443776
`define		RGB2XYZ5	183	// 0.715160 * `ScaleNumber = 183.08096
`define		RGB2XYZ6	18	// 0.072169 * `ScaleNumber = 18.475264
`define		RGB2XYZ7	5	// 0.019334 * `ScaleNumber = 4.949504
`define		RGB2XYZ8	31	// 0.119193 * `ScaleNumber = 30.513408
`define		RGB2XYZ9	243	// 0.950227 * `ScaleNumber = 243.258112
//16 * 6.3496042078727978990068225569719 * `ScaleNumber = 26007.978835446980194331945193353
`define		pow_16_256_1_3	26008

`define		RGB2LabLimit	2	// 0.008856 * ScaleNumber = 2.267136

// saturation enhancement
// amin =  -86, amax = 98
// bmin = -108, bmax = 94
// 86 + 98 + 1 = 185
// 108 + 94 + 1 = 203
`define		SE_a	282	// 1.1 * `ScaleNumber = 281.6
`define		SE_b	282	// 1.1 * `ScaleNumber = 281.6

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

// 0.206893 * ScaleNumber * 6.3496042078727978990068225569719 * ScaleNumber * ScaleNumber = 22040038.4622679329724248847846966558720
`define		Lab2RGBLimit	22040038
