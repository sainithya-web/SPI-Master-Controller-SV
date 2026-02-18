module spi_master (
    input  logic       clk,      // 50MHz System Clock
    input  logic       rst_n,    // Active-low Reset
    input  logic [7:0] tx_data,  // Data to send to Slave
    input  logic       start,    // Trigger to begin transfer
    output logic [7:0] rx_data,  // Data received from Slave
    output logic       sclk,     // SPI Clock
    output logic       mosi,     // Master Out Slave In
    input  logic       miso,     // Master In Slave Out
    output logic       cs_n,     // Chip Select (Active Low)
    output logic       ready     // High when transfer is done
);

    // --- 1. Clock Divider for SCLK ---
    // Goal: 1MHz SCLK from 50MHz clk
    // We need a tick every 50 cycles, but SCLK has 2 edges per bit.
    // So we need a tick every 25 cycles to toggle SCLK.
    logic [4:0] count;
    logic       clk_tick;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count    <= 0;
            clk_tick <= 0;
        end else if (count == 24) begin
            count    <= 0;
            clk_tick <= 1;
        end else begin
            count    <= count + 1;
            clk_tick <= 0;
        end
    end

    // --- 2. FSM and Shift Logic ---
    typedef enum logic [1:0] {IDLE, TRANSFER, DONE} state_t;
    state_t state;

    logic [7:0] shift_reg;
    logic [4:0] edge_count; // Counts 16 edges (8 clock cycles)

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            sclk       <= 0;
            mosi       <= 0;
            cs_n       <= 1;
            ready      <= 0;
            rx_data    <= 8'h00;
            shift_reg  <= 8'h00;
            edge_count <= 0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 0;
                    cs_n  <= 1;
                    sclk  <= 0; // Mode 0: Idle clock is Low
                    if (start) begin
                        shift_reg  <= tx_data;
                        edge_count <= 0;
                        cs_n       <= 0; // Activate Slave
                        state      <= TRANSFER;
                    end
                end

                TRANSFER: begin
                    if (clk_tick) begin
                        edge_count <= edge_count + 1;
                        
                        if (edge_count == 16) begin
                            state <= DONE;
                        end else begin
                            sclk <= ~sclk; // Toggle SCLK

                            if (sclk == 0) begin
                                // RISING EDGE: Sample MISO
                                shift_reg <= {shift_reg[6:0], miso};
                            end else begin
                                // FALLING EDGE: Shift out next MOSI bit
                                mosi <= shift_reg[7];
                            end
                        end
                    end
                end

                DONE: begin
                    cs_n    <= 1;
                    ready   <= 1;
                    rx_data <= shift_reg;
                    state   <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
