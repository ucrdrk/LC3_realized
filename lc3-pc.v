module pc (
    input wire[15:0] D,
    input wire C,
    input wire en,
    output reg [15:0] Q
);

reg [15:0] pc;

initial pc = 16'h0200;

always @ (posedge C) begin
    if(en === 1) pc = D;
    Q <= pc;
end

endmodule