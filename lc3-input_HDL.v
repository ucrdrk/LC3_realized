module lc3_input (
    input clk,
    output [7:0] data,
    output status
);

assign status = 1'b1;
assign data = 8'b10101010;

endmodule