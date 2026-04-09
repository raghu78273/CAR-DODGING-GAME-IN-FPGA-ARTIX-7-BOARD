module enemy_controller #(
    parameter integer ENEMY_COUNT     = 8,
    parameter integer SCREEN_H        = 480,
    parameter integer HUD_HEIGHT      = 48,
    parameter integer CAR_H           = 96,
    parameter integer SAFE_SPAWN_GAP  = 120
) (
    input  wire       clk,
    input  wire       frame_tick,
    input  wire       enable,
    input  wire       clear_all,
    input  wire [3:0] speed,
    input  wire [6:0] spawn_interval,
    input  wire [15:0] score,
    output reg  [ENEMY_COUNT-1:0] enemy_active = {ENEMY_COUNT{1'b0}},
    output wire [ENEMY_COUNT*2-1:0] enemy_lane_bus,
    output wire [ENEMY_COUNT*10-1:0] enemy_y_bus,
    output wire [ENEMY_COUNT*3-1:0] enemy_style_bus,
    output reg  [3:0] passed_count = 4'd0
);

    integer i;
    integer slot_first;
    integer slot_second;
    reg [3:0] lane_blocked;
    reg [3:0] lane_reserved;
    reg [2:0] first_pick;
    reg [2:0] second_pick;
    reg [3:0] pass_counter;
    reg [10:0] y_advanced;
    reg [6:0] spawn_timer = 7'd18;

    reg [1:0] enemy_lane [0:ENEMY_COUNT-1];
    reg [9:0] enemy_y    [0:ENEMY_COUNT-1];
    reg [2:0] enemy_style[0:ENEMY_COUNT-1];

    wire [15:0] rand_value;

    function [2:0] choose_lane;
        input [1:0] start_lane;
        input [3:0] blocked;
        input [3:0] forbidden;
        integer offset;
        reg [1:0] candidate;
        begin
            choose_lane = 3'b000;
            for (offset = 0; offset < 4; offset = offset + 1) begin
                candidate = (start_lane + offset) & 2'b11;
                if (!choose_lane[2] && !blocked[candidate] && !forbidden[candidate]) begin
                    choose_lane = {1'b1, candidate};
                end
            end
        end
    endfunction

    lfsr16 rand_gen (
        .clk(clk),
        .advance(frame_tick),
        .value(rand_value)
    );

    genvar g;
    generate
        for (g = 0; g < ENEMY_COUNT; g = g + 1) begin : pack_outputs
            assign enemy_lane_bus[(g * 2) +: 2]   = enemy_lane[g];
            assign enemy_y_bus[(g * 10) +: 10]    = enemy_y[g];
            assign enemy_style_bus[(g * 3) +: 3]  = enemy_style[g];
        end
    endgenerate

    always @(posedge clk) begin
        if (clear_all) begin
            passed_count <= 4'd0;
            spawn_timer <= 7'd18;
            for (i = 0; i < ENEMY_COUNT; i = i + 1) begin
                enemy_active[i] <= 1'b0;
                enemy_lane[i]   <= 2'd0;
                enemy_y[i]      <= 10'd0;
                enemy_style[i]  <= 3'd0;
            end
        end else if (frame_tick) begin
            passed_count <= 4'd0;

            if (enable) begin
                pass_counter = 4'd0;

                for (i = 0; i < ENEMY_COUNT; i = i + 1) begin
                    if (enemy_active[i]) begin
                        y_advanced = enemy_y[i] + speed;
                        if (y_advanced >= SCREEN_H) begin
                            enemy_active[i] <= 1'b0;
                            enemy_y[i] <= 10'd0;
                            pass_counter = pass_counter + 1'b1;
                        end else begin
                            enemy_y[i] <= y_advanced[9:0];
                        end
                    end
                end

                passed_count <= pass_counter;

                if (spawn_timer == 7'd0) begin
                    lane_blocked = 4'b0000;
                    lane_reserved = 4'b0000;
                    slot_first = -1;
                    slot_second = -1;

                    for (i = 0; i < ENEMY_COUNT; i = i + 1) begin
                        if (enemy_active[i] && (enemy_y[i] < (HUD_HEIGHT + CAR_H + SAFE_SPAWN_GAP))) begin
                            lane_blocked[enemy_lane[i]] = 1'b1;
                        end

                        if (!enemy_active[i]) begin
                            if (slot_first < 0) begin
                                slot_first = i;
                            end else if (slot_second < 0) begin
                                slot_second = i;
                            end
                        end
                    end

                    first_pick = choose_lane(rand_value[1:0], lane_blocked, 4'b0000);
                    if (first_pick[2] && (slot_first >= 0)) begin
                        enemy_active[slot_first] <= 1'b1;
                        enemy_lane[slot_first] <= first_pick[1:0];
                        enemy_y[slot_first] <= HUD_HEIGHT + 10'd4;
                        enemy_style[slot_first] <= rand_value[10:8] + slot_first[2:0];
                        lane_reserved = (4'b0001 << first_pick[1:0]);
                    end

                    if ((score >= 16'd16) && rand_value[6] && rand_value[5] && (slot_second >= 0)) begin
                        second_pick = choose_lane(rand_value[3:2], lane_blocked, lane_reserved);
                        if (second_pick[2]) begin
                            enemy_active[slot_second] <= 1'b1;
                            enemy_lane[slot_second] <= second_pick[1:0];
                            enemy_y[slot_second] <= HUD_HEIGHT + 10'd14;
                            enemy_style[slot_second] <= rand_value[13:11] + slot_second[2:0];
                        end
                    end

                    spawn_timer <= spawn_interval;
                end else begin
                    spawn_timer <= spawn_timer - 1'b1;
                end
            end
        end
    end

endmodule
