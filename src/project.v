/*
 * Tiny Tapeout I2C Master Wrapper
 * Wraps Alex Forencich's i2c_master.v for area estimation
 */

`default_nettype none

module tt_um_i2c_test (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // Bidirectional inputs
    output wire [7:0] uio_out,  // Bidirectional outputs
    output wire [7:0] uio_oe,   // Pin directions (1 = output, 0 = input)
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Internal I2C wires from the master core
    wire scl_i, scl_o, scl_t;
    wire sda_i, sda_o, sda_t;
    wire busy, bus_active, bus_control, missed_ack;

    // --- I2C Open-Drain Tri-State Logic ---
    // SCL mapped to uio[0]
    assign scl_i      = uio_in[0];
    assign uio_out[0] = scl_o;
    // In Alex's core, _t goes high when the line should float (input mode)
    // Tiny Tapeout uio_oe is 1 for output (driving), 0 for input (floating)
    assign uio_oe[0]  = ~scl_t; 

    // SDA mapped to uio[1]
    assign sda_i      = uio_in[1];
    assign uio_out[1] = sda_o;
    assign uio_oe[1]  = ~sda_t; 

    // Tie off unused bidir pins to 0
    assign uio_out[7:2] = 6'b0;
    assign uio_oe[7:2]  = 6'b0;

    // --- Core Outputs ---
    // Route status flags to the dedicated output pins
    assign uo_out[0] = busy;
    assign uo_out[1] = bus_active;
    assign uo_out[2] = bus_control;
    assign uo_out[3] = missed_ack;
    assign uo_out[7:4] = 4'b0;

    // Instantiate Alex Forencich's I2C Master
    i2c_master i2c_inst (
        .clk(clk),
        .rst(~rst_n),

        // Command AXI interface (driven by input pins for test)
        .s_axis_cmd_address(ui_in[6:0]),
        .s_axis_cmd_start(ui_in[7]),
        .s_axis_cmd_read(1'b0),
        .s_axis_cmd_write(1'b1),
        .s_axis_cmd_write_multiple(1'b0),
        .s_axis_cmd_stop(1'b0),
        .s_axis_cmd_valid(1'b1),
        .s_axis_cmd_ready(),

        // Data AXI interface (hardcoded to write 0xAA for synthesis)
        .s_axis_data_tdata(8'hAA),
        .s_axis_data_tvalid(1'b1),
        .s_axis_data_tready(),
        .s_axis_data_tlast(1'b1),

        .m_axis_data_tdata(),
        .m_axis_data_tvalid(),
        .m_axis_data_tready(1'b1),
        .m_axis_data_tlast(),

        // I2C Physical Interface
        .scl_i(scl_i),
        .scl_o(scl_o),
        .scl_t(scl_t),
        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_t(sda_t),

        // Status
        .busy(busy),
        .bus_control(bus_control),
        .bus_active(bus_active),
        .missed_ack(missed_ack),

        // Configuration
        .prescale(16'd100),
        .stop_on_idle(1'b1)
    );

    // Suppress synthesis warnings for unused signals
    wire _unused = &{ena, uio_in[7:2], 1'b0};

endmodule
