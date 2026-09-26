/*
 * Tiny Tapeout UART Wrapper
 * Module name must start with tt_um_ and match top_module in info.yaml
 */

`default_nettype none

module tt_um_uart_test (
    input  wire [7:0] ui_in,    // Dedicated inputs: 8-bit TX data input
    output wire [7:0] uo_out,   // Dedicated outputs: uo_out[0] = TXD, uo_out[1] = tx_busy
    input  wire [7:0] uio_in,   // Bidirectional inputs: uio_in[0] = RXD
    output wire [7:0] uio_out,  // Bidirectional outputs: RX data received (lower 8 bits)
    output wire [7:0] uio_oe,   // Pin directions (1 = output, 0 = input)
    input  wire       ena,      // Tiny Tapeout enable signal (active high)
    input  wire       clk,      // System clock
    input  wire       rst_n     // Active-low reset
);

    // Set pin direction:
    // uio[0] is RX input (0), uio[7:1] are outputs (1) for received data bits
    assign uio_oe = 8'b1111_1110;

    // Output assignments
    wire txd_wire;
    wire tx_busy_wire;
    wire rx_busy_wire;
    wire rx_overrun;
    wire rx_frame_err;
    wire [7:0] rx_data;
    wire rx_valid;

    assign uo_out[0]   = txd_wire;
    assign uo_out[1]   = tx_busy_wire;
    assign uo_out[2]   = rx_valid;
    assign uo_out[3]   = rx_busy_wire;
    assign uo_out[4]   = rx_overrun;
    assign uo_out[5]   = rx_frame_err;
    assign uo_out[7:6] = 2'b00;

    // Output received data on bidirectional pins uio[7:1]
    assign uio_out[0]   = 1'b0;          // Pin 0 is used for RX input
    assign uio_out[7:1] = rx_data[7:1];

    // Instantiate Alex Forencich's UART
    uart #(
        .DATA_WIDTH(8)
    ) uart_inst (
        .clk(clk),
        .rst(~rst_n),              // Convert active-low rst_n to active-high reset

        // AXI-Stream Transmitter
        .s_axis_tdata(ui_in),      // Data to transmit fed from input pins
        .s_axis_tvalid(1'b0),      // Default tied low for area estimation
        .s_axis_tready(),

        // AXI-Stream Receiver
        .m_axis_tdata(rx_data),
        .m_axis_tvalid(rx_valid),
        .m_axis_tready(1'b1),      // Always ready to accept received data

        // Physical UART serial lines
        .rxd(uio_in[0]),           // Serial RX line connected to uio_in[0]
        .txd(txd_wire),            // Serial TX line connected to uo_out[0]

        // Status lines
        .tx_busy(tx_busy_wire),
        .rx_busy(rx_busy_wire),
        .rx_overrun_error(rx_overrun),
        .rx_frame_error(rx_frame_err),

        // Baud rate prescaler (fixed divider for synthesis testing)
        .prescale(16'd100)
    );

    // List unused signals to prevent synthesis warnings
    wire _unused = &{ena, ui_in, uio_in[7:1], rx_data[0], 1'b0};

endmodule
