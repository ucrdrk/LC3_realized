module pc (
    input wire[15:0] a_in,
    input wire clk,
    input wire en,
    output reg [15:0] a_out
);

reg [15:0] pc;

initial pc = 16'h0200;

always @ (posedge clk) begin
    if(en === 1) pc = a_in;
    a_out <= pc;
end

endmodule