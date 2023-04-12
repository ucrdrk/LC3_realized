module pc (
    input wire[15:0] addr_in,
    input wire clk,
    input wire en,
    output reg [15:0] addr_out
);

reg [15:0] pc;

initial pc = 16'h0200;

always @ (posedge clk) begin
    if(en === 1) pc = addr_in;
    addr_out <= pc;
end

endmodule