module pc (
    input wire[15:0] addr_in,
    input wire clk,
    input wire en,
    output wire [15:0] addr_out
);

reg [15:0] pc;

initial pc = 16'h0200;

always @ (posedge clk) begin
    if(en === 1) pc = addr_in;
end

assign addr_out = pc;

endmodule