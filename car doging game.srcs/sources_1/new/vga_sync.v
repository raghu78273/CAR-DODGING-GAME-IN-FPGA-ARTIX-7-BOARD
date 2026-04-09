module vga_sync #(
    parameter integer H_DISPLAY = 640,
    parameter integer H_FRONT   = 16,
    parameter integer H_SYNC    = 96,
    parameter integer H_BACK    = 48,
    parameter integer V_DISPLAY = 480,
    parameter integer V_FRONT   = 10,
    parameter integer V_SYNC    = 2,
    parameter integer V_BACK    = 33
) (
    input  wire       clk,
    input  wire       pixel_tick,
    output reg        hsync    = 1'b1,
    output reg        vsync    = 1'b1,
    output wire       video_on,
    output reg [9:0]  pix_x    = 10'd0,
    output reg [9:0]  pix_y    = 10'd0,
    output reg        frame_tick = 1'b0
);

    localparam integer H_TOTAL = H_DISPLAY + H_FRONT + H_SYNC + H_BACK;
    localparam integer V_TOTAL = V_DISPLAY + V_FRONT + V_SYNC + V_BACK;

    reg [9:0] h_count = 10'd0;
    reg [9:0] v_count = 10'd0;

    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

    always @(posedge clk) begin
        frame_tick <= 1'b0;

        if (pixel_tick) begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 10'd0;
                    frame_tick <= 1'b1;
                end else begin
                    v_count <= v_count + 1'b1;
                end
            end else begin
                h_count <= h_count + 1'b1;
            end

            pix_x <= h_count;
            pix_y <= v_count;

            hsync <= ~((h_count >= (H_DISPLAY + H_FRONT)) &&
                       (h_count <  (H_DISPLAY + H_FRONT + H_SYNC)));
            vsync <= ~((v_count >= (V_DISPLAY + V_FRONT)) &&
                       (v_count <  (V_DISPLAY + V_FRONT + V_SYNC)));
        end
    end

endmodule
