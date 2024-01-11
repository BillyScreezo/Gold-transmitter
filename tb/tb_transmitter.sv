/***********************************************************************************
 * Copyright (C) 2023 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains Gold code tx tb
 *
 ***********************************************************************************/


`timescale 1ns/1ps
module tb_transmitter (); 


	localparam int SYS_CLK 		= 100;	// MHz
	localparam int CLK_PERIOD 	= (1000/SYS_CLK); // ns 

	localparam int RST_DELAY 	= 60;


	bit  s_axis_aclk;
	bit  aresetn;

	
	initial begin
		s_axis_aclk = '0;
		forever #(CLK_PERIOD/2) s_axis_aclk = ~s_axis_aclk;
	end

	
	bit  strobe;
	axistream_if #(.DWIDTH(5)) s_axis (s_axis_aclk);
	logic  phase_out;

	transmitter #(.SYS_CLK(SYS_CLK)) inst_transmitter
		(
			.aresetn     (aresetn),
			.strobe      (strobe),
			.s_axis_aclk (s_axis_aclk),
			.s_axis      (s_axis),
			.phase_out   (phase_out)
		);

	

	initial begin

		aresetn 		<= '0;
		strobe			<= '0;
		s_axis.tvalid 	<= '0;

		repeat (RST_DELAY) @(negedge s_axis_aclk);

		aresetn <= '1;
		strobe	<= '1;

		@(posedge s_axis_aclk);

		s_axis.tvalid 	<= '1;
		s_axis.tdata 	<= 'd4;


	end

endmodule
