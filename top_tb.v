//=========================================================================
// Name: Allan Knight
// Email: aknig007@ucr.edu
// Assignment name: Assignment 5
// Lab section: 23
// TA: Dipan Shawn 
// I hereby certify that I have not received assistance on this assignment,
// or used code, from ANY outside source other than the instruction team
// (apart from what was provided in the starter file).
//=========================================================================

`timescale 1ns / 1ps
`include "lc3_HDL.v"

module lc3_tb;
    // Inputs
    reg clk; 
    reg rst; 

    initial begin
        $dumpfile("lc3.vcd");
        $dumpvars(0);

        $readmemh("lc3_os.hex", lc3_uut.lc3_memory_HDL_i16.lc3_SPRAM_HDL_i1.SB_SPRAM256KA_i3.mem, 0, 12287);
        $readmemh("add.hex", lc3_uut.lc3_memory_HDL_i16.lc3_SPRAM_HDL_i1.SB_SPRAM256KA_i3.mem, 12288, 12294);
    end
    
    wire uart_rx;
    wire uart_tx;

    // ---------------------------------------------------
    // Instantiate the Unit Under Test (UUT)
    // --------------------------------------------------- 
    lc3_HDL lc3_uut (
      .RX(uart_rx), // input
      .SPI_MOSI(),  // input
      .Clock(clk),  // input
      .SPI_MISO(),  // output
      .SPI_SCK(),   // output
      .SPI_SS(),    // output
      .TX(uart_tx), // output
      .LED_B(),     // output
      .LED_G(),     // output
      .LED_R()      // output
    );
    
    reg tx_start = 1'b0;
    reg [7:0] tx_data;
    wire tx_busy;

    uart_tx #(12_000_000, 115_200) tb_tx_uart (
      .clk(clk),
	    .tx_start(tx_start),
	    .tx_data(tx_data),
	    .tx(uart_rx),
	    .tx_busy(tx_busy)
    );

    initial begin 
        clk = 0; rst = 1; #5; 
        clk = 1; rst = 1; #5; 
        clk = 0; rst = 0; #5; 
        clk = 1; rst = 0; #5; 
        forever begin 
            clk = ~clk; #5; 
        end 
    end
     
    integer failedTests = 0;
    integer totalTests = 0;
    initial begin
        // Reset
        @(negedge rst); // Wait for reset to be released (from another initial block)
        @(posedge clk); // Wait for first clock out of reset 
        #10; // Wait 

        // -------------------------------------------------------
        // Test group 1: Floating point to fixed point
        // -------------------------------------------------------
        $write("\tTest Case 1.1: Sending run command");
        tx_data = 8'h02;
        tx_start = 1'b1;

        totalTests = totalTests + 1;

        // --------------------------------------------------------------
        // End testing
        // --------------------------------------------------------------

        @(negedge tx_busy)

        #50000;

        $write("\n--------------------------------------------------------------");
        $write("\nTesting complete\nPassed %0d / %0d tests",totalTests-failedTests,totalTests);
        $write("\n--------------------------------------------------------------\n");
        $finish();
    end
endmodule
