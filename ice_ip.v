`ifndef SYNTH_FPGA
module SB_SPRAM256KA (
    input [13:0] ADDRESS,
    input [15:0] DATAIN,
    input [3:0] MASKWREN,
    input WREN, CHIPSELECT, CLOCK, STANDBY, SLEEP, POWEROFF,
    output reg [15:0] DATAOUT
);
endmodule
`endif