`timescale 1ns/10ps

module exp_uart_tb();

    localparam CLOCK_FREQ = 12000000;
    localparam BAUD_RATE  = 115200;
    localparam NANO_SECS  = 1000000000;
    localparam CYCLE_PERIOD = NANO_SECS/CLOCK_FREQ;

    task UART_WRITE_BYTE(input [7:0] data);
        integer     ii;
        localparam BIT_PERIOD = NANO_SECS/BAUD_RATE;
        begin
        
        // Send Start Bit
        serial <= 1'b0;
        #(BIT_PERIOD);
        #1000;
        
        
        // Send Data Byte
        for (ii=0; ii<8; ii=ii+1) begin
            serial <= data[ii];
            #(BIT_PERIOD);
        end
        
        // Send Stop Bit
        serial <= 1'b1;
        #(BIT_PERIOD);
        end
    endtask // UART_WRITE_BYTE

    reg clk;

    wire ready;
    wire [7:0] data;

    // uart_rx #(CLOCK_FREQ, BAUD_RATE, 8) rx (
    //     .clk(clk),
    //     .rx(serial),
    //     .rx_ready(ready),
    //     .rx_data(data)
    // );

    reg tx_start;
    wire tx_serial;
    reg [7:0] data_reg;
    wire busy;

    uart_tx #(CLOCK_FREQ, BAUD_RATE) tx (
        .clk(clk),
        .tx_start(tx_start),
        .tx_data(data_reg),
        .tx(tx_serial),
        .tx_busy(busy)
    );

    initial begin
        $dumpfile("en_uart_tick.vcd");
        $dumpvars(0);
    end

    initial begin
        clk <=0; 
        forever begin
            #(CYCLE_PERIOD/2) clk = ~clk;            
        end
    end

    integer ticks = 0;
    reg serial = 1;

    initial begin
        // #(CYCLE_PERIOD * 250) UART_WRITE_BYTE(8'h41);
        // #(CYCLE_PERIOD * 500) UART_WRITE_BYTE(8'h61);
        tx_start <= 0;
        #(CYCLE_PERIOD * 250) data_reg <= 8'haa; tx_start <= 1;
        #(CYCLE_PERIOD) tx_start <= 0;

        @(negedge busy);
        #(CYCLE_PERIOD * 250) data_reg <= 8'hbb; tx_start <= 1;
        #(CYCLE_PERIOD) tx_start <= 0;
    end

    always @(posedge clk) begin
        ticks = ticks + 1;
        if (ticks >= NANO_SECS/1000) $finish();
    end


endmodule