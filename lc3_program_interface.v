`include "spi_master.v"
`include "uart_tx.v"
`include "uart_rx.v"
`include "lc3_HDL_dig.v"

`ifdef SIM_FPGA
`include "SB_SPRAM256KA.v"
`endif

module lc3_program_interface (
  input Clock,
  input running_in,
  input RX,
  output wire  SPI_MISO,
  output wire SPI_SCK,
  output wire SPI_SS,
  input wire  SPI_MOSI,
  output TX,
  output LED_B,
  output LED_G,
  output LED_R,
  output [15:0] mem_addr_out,
  output [15:0] mem_data_out,
  output mem_rw_out,
  output starting_out,
  output reset_out,
  input [15:0] mem_data_in
);

  reg [15:0] spram_addr;
  reg [15:0] spram_data_in;
  reg spram_wren;
  wire [15:0] spram_data_out;

  assign mem_addr_out = spram_addr;
  assign mem_data_out = spram_data_in;
  assign mem_rw_out   = spram_wren;
  assign spram_data_out = mem_data_in;

  localparam  INIT      = 0, 
              LOAD_OS   = INIT + 1, 
              LOAD_PROG = LOAD_OS + 1,
              READY     = LOAD_PROG + 1,
              RESETTING = READY + 1,
              DUMPING   = RESETTING + 1,
              STARTING  = DUMPING + 1,
              RUNNING   = STARTING + 1,
              DONE      = RUNNING + 1,
              STALLED   = DONE +1;

  localparam  FLASH_SEND_ADDR = 0,
              FLASH_WAIT_READ_FIRST = FLASH_SEND_ADDR + 1,
              FLASH_WAIT_READ_SECOND = FLASH_WAIT_READ_FIRST + 1,
              FLASH_READ_NEXT = FLASH_WAIT_READ_SECOND + 1;

  reg [21:0] led_counter = 0;
  reg [31:0] load_counter = 0;
  reg [3:0]  run_state = INIT;
  reg [3:0]  interuppted_state;
  reg [2:0]  led = 3'b000;
  reg        err = 0;

  reg [2:0] flash_read_state = FLASH_SEND_ADDR;

  reg [23:0] flash_addr;
  wire [31:0] flash_data;

  assign LED_B = ~led[0];
  assign LED_G = ~led[1];
  assign LED_R = ~led[2];

  reg spi_reset;
  wire spi_addr_buffer_free;
  reg spi_addr_en;
  wire spi_rd_data_available;
  reg spi_rd_ack;

  wire rx1_ready;
  wire [7:0] rx1_data;
  uart_rx #(12_000_000, 115_200) urx1 (
    .clk(Clock),
    .rx(RX),
    .rx_ready(rx1_ready),
    .rx_data(rx1_data)
  );

  reg tx1_start = 0;
  reg [7:0] tx1_data;
  wire tx1_busy;
  uart_tx #(12_000_000, 115_200) utx1 (
    .clk(Clock),
    .tx_start(tx1_start),
    .tx_data(tx1_data),
    .tx(TX),
    .tx_busy(tx1_busy)
  );

  spi_master spi_master_inst(
    .clk(Clock),
    .reset(spi_reset),
    .SPI_SCK(SPI_SCK),
    .SPI_SS(SPI_SS),
    .SPI_MOSI(SPI_MISO),
    .SPI_MISO(SPI_MOSI),
    .addr_buffer_free(spi_addr_buffer_free),
    .addr_en(spi_addr_en),
    .addr_data(flash_addr),
    .rd_data_available(spi_rd_data_available),
    .rd_ack(spi_rd_ack),
    .rd_data(flash_data)
  );

  task read_flash(input [3:0] next_run_state, input [15:0] limit);
  begin
    case (flash_read_state)
      FLASH_SEND_ADDR: begin
        spi_addr_en <= 1;
        flash_read_state <= FLASH_WAIT_READ_FIRST;
      end

      FLASH_WAIT_READ_FIRST: begin
        if (spi_rd_data_available == 1) begin
          spram_data_in <= flash_data[31:16];
          spram_wren <= 1;
          flash_read_state <= FLASH_WAIT_READ_SECOND;
        end
      end

      FLASH_WAIT_READ_SECOND: begin
          spram_addr <= spram_addr + 1;
          spram_data_in <= flash_data[15:0];
          spram_wren <= 1;
          spi_rd_ack <= 1;
          flash_read_state <= FLASH_READ_NEXT;
      end

      FLASH_READ_NEXT: begin
        if (spram_addr < limit - 1) begin
          flash_addr <= flash_addr + 4;
          spram_addr <= spram_addr + 1;
        end
        else begin
          run_state <= next_run_state;
        end
        flash_read_state <= FLASH_SEND_ADDR;
      end
      endcase
  end
  endtask
  
  localparam  UART_RX_WAIT_CMD = 0,
              UART_RX_WAIT_BYTE1 = UART_RX_WAIT_CMD + 1, 
              UART_RX_WAIT_BYTE2 = UART_RX_WAIT_BYTE1 + 1,
              UART_RX_WAIT_STOP = UART_RX_WAIT_BYTE2 + 1;

  localparam STATUS = 1, RUN = STATUS + 1, STOP = RUN + 1, LOAD = STOP + 1, DUMP = LOAD + 1, RESTART = DUMP + 1;

  localparam READING_MIN = 0, READING_MAX = READING_MIN + 1, SENDING = READING_MAX + 1, RECEIVING = SENDING + 1, INCREMENTING = RECEIVING + 1;

  localparam  UART_TX_IDLE = 0,
              UART_TX_WAIT_BYTE1 = UART_TX_IDLE + 1,
              UART_TX_WAIT_BYTE2 = UART_TX_WAIT_BYTE1 + 1;

  reg [2:0] uart_rx_state = UART_RX_WAIT_CMD;
  reg [7:0] uart_command = 0;
  reg [15:0] uart_command_arg;
  reg [15:0] uart_rx_short;
  reg uart_rx_short_ready;

  reg [3:0] dump_state;
  reg [3:0] load_state;
  reg [2:0] byte_count;
  reg [15:0] dump_max;
  reg [15:0] load_max;
  reg [3:0]  dump_clk_count;
  reg [1:0] starting;
  reg reset;

  assign starting_out = | starting;
  assign reset_out = reset;

  initial begin
    run_state = INIT;
    spi_reset = 0;
    spi_addr_en = 0;
    flash_addr = 24'h103000; //1MB offset
    spi_rd_ack = 0;
    spram_addr = 0;
    byte_count = 0;
    dump_clk_count = 0;
    uart_rx_short_ready = 0;
    starting = 0;
    reset = 0;
    tx1_start = 0;
  end

  // Handle incoming commands over UART
  always @(posedge Clock) begin
    spi_rd_ack <= 0;
    spi_addr_en <= 0;
    spram_wren <= 0;
    if (rx1_ready & ~tx1_start) begin
      if (uart_rx_state == UART_RX_WAIT_CMD) begin
        case(rx1_data)
          STATUS: begin
            tx1_data  <= run_state;
            tx1_start <= 1;
          end

          RUN: begin
            run_state <= STARTING;
            tx1_data <= 8'h00;
            tx1_start <= 1;
          end

          STOP: begin
            run_state <= DONE;
            reset <= 1;
            tx1_data <= 8'h00;
            tx1_start <= 1;
          end

          LOAD: begin
            run_state <= LOAD_PROG;
            load_state <= READING_MIN;
            uart_rx_state <= UART_RX_WAIT_BYTE1;
          end

          DUMP: begin
            interuppted_state <= run_state;
            run_state <= DUMPING;
            dump_state <= READING_MIN;
            uart_rx_state <= UART_RX_WAIT_BYTE1;
          end

          RESTART: begin
            run_state <= INIT;
            tx1_data <= 8'h00;
            tx1_start <= 1;
          end
          
        endcase 
      end else if (uart_rx_state == UART_RX_WAIT_BYTE1) begin
        uart_rx_short[15:8] <= rx1_data;
        uart_rx_state = UART_RX_WAIT_BYTE2;
      end else if (uart_rx_state == UART_RX_WAIT_BYTE2) begin
        uart_rx_short[7:0] <= rx1_data;
        uart_rx_short_ready <= 1;
        uart_rx_state = UART_RX_WAIT_CMD;
      end 
    end

    if (~tx1_busy & tx1_start) begin
      tx1_start <= 0;
    end

    spi_rd_ack <= 0;
    spi_addr_en <= 0;

    case (run_state)
    INIT: begin
      spi_reset  <= 1'b0;
      flash_addr <= 24'h100000;
      spram_addr <= 16'h0000;
      spram_wren <= 0;
      load_counter <= load_counter + 1;
      starting <= 0;

      if (load_counter == 32'h1000000) begin
        run_state  <= LOAD_OS;
        load_counter <= 0;
      end
    end

    LOAD_OS: begin
      reset <= 0;
      read_flash(RESETTING, 16'h3000);
    end

    RESETTING: begin
      if (spram_addr < 16'hFE00 - 1) begin
        spram_addr <= spram_addr + 1;
        spram_data_in <= 16'h0000;
        spram_wren <= 1;
      end else begin
        run_state <= READY;
      end
    end

    LOAD_PROG: begin
      case (load_state)
        READING_MIN: begin
          if (uart_rx_short_ready == 1) begin
            spram_addr <= uart_rx_short;
            load_state <= READING_MAX;
            uart_rx_short_ready <= 0;
            uart_rx_state <= UART_RX_WAIT_BYTE1;
          end
        end

        READING_MAX: begin
          if (uart_rx_short_ready == 1) begin
            load_max <= uart_rx_short;
            load_state <= RECEIVING;
            uart_rx_short_ready <= 0;
            uart_rx_state <= UART_RX_WAIT_BYTE1;
          end
        end

        RECEIVING: begin
          if (uart_rx_short_ready == 1) begin
            spram_data_in <= uart_rx_short;
            spram_wren <= 1;
            load_state <= INCREMENTING;
            uart_rx_short_ready <= 0;
            uart_rx_state <= UART_RX_WAIT_BYTE1;
          end
        end

        INCREMENTING: begin
          if (spram_addr < load_max) begin
            spram_addr <= spram_addr + 1;
            load_state <= RECEIVING;
          end else begin
            if (tx1_busy == 0) begin
              tx1_data <= 0;
              tx1_start <= 1;
              run_state <= READY;
              uart_rx_state <= UART_RX_WAIT_CMD;
            end
          end
        end
      endcase
    end

    DUMPING: begin
      case (dump_state)
        READING_MIN: begin
          if (uart_rx_short_ready == 1) begin
            spram_addr <= uart_rx_short;
            dump_state <= READING_MAX;
            uart_rx_short_ready <= 0;
            uart_rx_state <= UART_RX_WAIT_BYTE1;
          end
        end

        READING_MAX: begin
          if (uart_rx_short_ready == 1) begin
            dump_max <= uart_rx_short;
            dump_state <= SENDING;
            uart_rx_short_ready <= 0;
            uart_rx_state <= UART_RX_WAIT_CMD;
          end
        end

        SENDING:begin
          if (tx1_busy == 0) begin
            if (spram_addr <= dump_max) begin
              dump_clk_count <= dump_clk_count + 1;
              if (dump_clk_count > 4 && byte_count < 2) begin
                if (byte_count == 0) begin
                  tx1_data <= spram_data_out[15:8];
                end else begin
                  tx1_data <= spram_data_out[7:0];
                  spram_addr <= spram_addr + 1;
                end
                tx1_start <= 1;
                byte_count <= byte_count + 1;
              end else if (byte_count >= 2) begin
                byte_count <= 0;                
                dump_clk_count <= 0;
              end
            end else begin
              run_state <= interuppted_state;
            end
          end
        end
      endcase
    end

    STARTING:begin
      if (starting < 3) begin
        starting <= starting + 1;
      end else begin;
        starting <= 0;
        run_state <= RUNNING;
      end
    end

    RUNNING: begin
      if (running_in == 0) begin
        run_state <= DONE;
      end
    end

    endcase
  end

  // Blink LED passed on current run state of the system.
  always @(posedge Clock) begin
    led_counter <= led_counter + 1;

    case (run_state)
    INIT: begin // Solid Red
      led <= 3'b100;
    end
    LOAD_OS: begin // Red <-> Green
      led <= {~led_counter[21], led_counter[21], 1'b0};
    end
    LOAD_PROG: begin // Blink Green
      led <= {1'b0, led_counter[21], 1'b0};
    end
    READY: begin // Solid Green
      led <= 3'b010;
    end
    RUNNING: begin // Solid Blue
      led <= 3'b001;
    end
    DONE: begin // Blink Green on success, Blink Red on err
      led <= {~led_counter[21] & err, led_counter[21] & ~err, 1'b0};
    end
    STALLED: begin // Blink Blue
      led <= {1'b0, 1'b0, led_counter[21]};
    end
    default: begin // Solid White (should not get here)
      led <= 3'b111;
    end
    endcase
  end

endmodule
