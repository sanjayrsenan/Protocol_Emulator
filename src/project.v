/*
 * Tiny Tapeout SPI Master Wrapper
 * Wraps Nandland SPI_Master_With_Single_CS for area estimation
 */

`default_nettype none

module tt_um_spi_test (
    input  wire [7:0] ui_in,    // Dedicated inputs: TX Byte to transmit[cite: 22]
    output wire [7:0] uo_out,   // Dedicated outputs: SPI lines and status
    input  wire [7:0] uio_in,   // Bidirectional inputs: uio[0]=MISO, uio[1]=TX_DV[cite: 22]
    output wire [7:0] uio_out,  // Bidirectional outputs: RX data bits [7:2][cite: 22]
    output wire [7:0] uio_oe,   // Pin directions (1 = output, 0 = input)
    input  wire       ena,      // Tiny Tapeout enable signal
    input  wire       clk,      // System clock[cite: 22]
    input  wire       rst_n     // Active-low reset[cite: 22]
);

    // Direction configuration:
    // uio[0] = input (MISO)
    // uio[1] = input (TX Data Valid pulse)
    // uio[7:2] = outputs (RX Byte bits 7 to 2)
    assign uio_oe = 8'b1111_1100;

    wire tx_ready;
    wire rx_dv;
    wire [7:0] rx_byte;
    wire [0:0] rx_count;

    // Output assignments for dedicated pins
    assign uo_out[0] = 1'b0; // Driven by SPI Clk inside instance
    assign uo_out[1] = 1'b0; // Driven by MOSI inside instance
    assign uo_out[2] = 1'b0; // Driven by CS_n inside instance
    assign uo_out[3] = tx_ready;
    assign uo_out[4] = rx_dv;
    assign uo_out[5] = rx_byte[0]; // Lower RX bits placed on dedicated outputs
    assign uo_out[6] = rx_byte[1];
    assign uo_out[7] = rx_count[0];

    // Output assignments for bidirectional pins
    assign uio_out[1:0] = 2'b00;
    assign uio_out[7:2] = rx_byte[7:2];

    // Instantiate Nandland SPI Master with Chip Select
    SPI_Master_With_Single_CS #(
        .SPI_MODE(0),              // Mode 0 (CPOL=0, CPHA=0)[cite: 22]
        .CLKS_PER_HALF_BIT(2),     // SPI clock = clk / 4[cite: 22]
        .MAX_BYTES_PER_CS(1),      // Transfer 1 byte per CS assertion[cite: 22]
        .CS_INACTIVE_CLKS(1)       // 1 cycle CS idle time[cite: 22]
    ) spi_inst (
        .i_Rst_L(rst_n),           // Active-low reset matches Tiny Tapeout rst_n[cite: 22]
        .i_Clk(clk),               // System clock[cite: 22]

        // TX signals
        .i_TX_Count(1'b1),         // 1 byte per transfer[cite: 22]
        .i_TX_Byte(ui_in),         // Input byte fed from ui_in[cite: 22]
        .i_TX_DV(uio_in[1]),       // Start trigger pulse from uio_in[1][cite: 22]
        .o_TX_Ready(tx_ready),     // Ready flag[cite: 22]

        // RX signals
        .o_RX_Count(rx_count),     // Byte index[cite: 22]
        .o_RX_DV(rx_dv),           // Data valid flag[cite: 22]
        .o_RX_Byte(rx_byte),       // Received byte[cite: 22]

        // SPI Physical Interface
        .o_SPI_Clk(uo_out[0]),     // SPI clock line[cite: 22]
        .i_SPI_MISO(uio_in[0]),    // SPI master-in slave-out[cite: 22]
        .o_SPI_MOSI(uo_out[1]),    // SPI master-out slave-in[cite: 22]
        .o_SPI_CS_n(uo_out[2])     // Active-low chip select[cite: 22]
    );

    // Suppress unused warnings
    wire _unused = &{ena, uio_in[7:2], 1'b0};

endmodule
