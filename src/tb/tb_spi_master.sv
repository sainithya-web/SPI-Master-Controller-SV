`timescale 1ns/1ps

module tb_spi_master;
    logic clk, rst_n, start;
    logic [7:0] tx_data, rx_data;
    logic sclk, mosi, miso, cs_n, ready;

    // 1. Instantiate the SPI Master
    spi_master uut (.*);

    // 2. Simple Slave Model (Loopback with a twist)
    // The slave will send back 0xAC when it receives data
    logic [7:0] slave_shift_reg = 8'hAC; 
    always_ff @(posedge sclk or posedge cs_n) begin
        if (cs_n) begin
            slave_shift_reg <= 8'hAC; // Reset slave data when not selected
            miso <= 1'bz;             // High-impedance when not selected
        end else begin
            miso <= slave_shift_reg[7];
            slave_shift_reg <= {slave_shift_reg[6:0], mosi};
        end
    end

    // 3. Clock Generation (50MHz)
    always #10 clk = (clk === 1'b0);

    // 4. Stimulus
    initial begin
        clk = 0; rst_n = 0; start = 0; tx_data = 8'h00;
        #100 rst_n = 1;

        // Test Case 1: Send 0x55
        @(posedge clk);
        tx_data = 8'h55; 
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait for ready signal
        wait(ready);
        $display("[TIME: %0t] Sent: 0x55, Received from Slave: %h", $time, rx_data);

        #1000;
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_spi_master);
    end
endmodule
