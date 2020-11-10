/*
* <p_int_acc.sv>
* 
* Copyright (c) 2020 Yosuke Ide
* 
* This software is released under the MIT License.
* https://opensource.org/licenses/mit-license.php
*/

`include "stddef.vh"

module p_int_acc #(
	parameter IN = 8,
	parameter dconf_t CONF = `DEF_DCONF_INT,
	// constant
	parameter PREC = CONF.prec 
)(
	input wire [IN-1:0][PREC-1:0]	in,
	output wire						ovf,
	output wire [PREC-1:0]			out
);

	//***** internal parameter
	localparam SIGN = CONF.sign;
	localparam STAGE = $clog2(IN);
	localparam EIN = 1 << STAGE;
	localparam NUM = EIN-1;

	//***** internal wires
	wire [NUM-1:0]					res_ovf;
	wire [NUM-1:0][PREC-1:0]		res;


	//***** assign output
	assign ovf = | res_ovf;
	assign out = res[NUM-1];



	//***** accumulate arrays (Binary tree of adders)
	generate
		genvar gi, gj;
		//*** input stage
		for ( gi = 0; gi < EIN/2; gi = gi + 1 ) begin : ST0
			if ( 2*gi+1 < IN ) begin : elm
				//* 2-1 Adder
				p_int_add #(
					.I1_CONF	( CONF ),
					.I2_CONF	( CONF ),
					.O_CONF		( CONF )
				) add (
					.in1		( in[gi*2] ),
					.in2		( in[gi*2+1] ),
					.ovf		( res_ovf[gi] ),
					.out		( res[gi] )
				);
			end else if ( 2*gi < IN ) begin : elmh
				assign res[gi] = in[gi*2];
				assign res_ovf[gi] = `Disable;
			end else begin : nv
				assign res[gi] = {PREC{1'b0}};
				assign res_ovf[gi] = `Disable;
			end
		end

		for ( gi = 2; gi <= STAGE; gi = gi + 1 ) begin : ST
			for ( gj = 0; gj < EIN >> gi; gj = gj + 1 ) begin : elm
				//* 2-1 Adder
				p_int_add #(
					.I1_CONF	( CONF ),
					.I2_CONF	( CONF ),
					.O_CONF		( CONF )
				) add (
					.in1		( res[(gj*2)+(EIN-(EIN>>(gi-2)))] ),
					.in2		( res[(gj*2+1)+(EIN-(EIN>>(gi-2)))] ),
					.ovf		( res_ovf[gj+(EIN-(EIN>>(gi-1)))] ),
					.out		( res[gj+(EIN-(EIN>>(gi-1)))] )
				);
			end
		end
	endgenerate

endmodule
