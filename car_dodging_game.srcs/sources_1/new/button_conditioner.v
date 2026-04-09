module button_conditioner #(
    parameter integer DEBOUNCE_CLKS = 20'd500_000
) (
    input  wire clk,
    input  wire button_in,
    output reg  level        = 1'b0,
    output reg  pressed_pulse = 1'b0
);

    reg sync_ff0 = 1'b0;
    reg sync_ff1 = 1'b0;
    reg [19:0] debounce_count = 20'd0;

    always @(posedge clk) begin
        sync_ff0 <= button_in;
        sync_ff1 <= sync_ff0;
        pressed_pulse <= 1'b0;

        if (sync_ff1 == level) begin
            debounce_count <= 20'd0;
        end else begin
            if (debounce_count == (DEBOUNCE_CLKS - 1'b1)) begin
                level <= sync_ff1;
                debounce_count <= 20'd0;
                if (sync_ff1) begin
                    pressed_pulse <= 1'b1;
                end
            end else begin
                debounce_count <= debounce_count + 1'b1;
            end
        end
    end

endmodule
