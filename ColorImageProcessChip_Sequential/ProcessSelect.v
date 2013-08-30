`define	EnableAL		// Auto Level
`define	EnableWB		// White Balance
`define	EnableCC		// Color Correction
//`define	EnableSpace		// Color Space Transformation
`define	EnableSE		// Saturation Enhancement
//`define	EnableTR		// Tone Reproduction
`define	EnableGC		// Gamma Correction

// space transformation must be done before Saturation Enhancement 
`ifdef	EnableSE		// Saturation Enhancement
`define	EnableSpace
`endif

// space transformation must be done before Tone Reproduction 
`ifdef	EnableTR		// Tone Reproduction
`define	EnableSpace
`endif
