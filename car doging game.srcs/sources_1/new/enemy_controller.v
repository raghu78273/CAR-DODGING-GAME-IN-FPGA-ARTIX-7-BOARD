module enemy_controller #(
    parameter integer ENEMY_COUNT     = 8,
    parameter integer SCREEN_H        = 480,
    parameter integer HUD_HEIGHT      = 48,
    parameter integer CAR_H           = 96,
    parameter integer SAFE_SPAWN_GAP  = 168,
    parameter integer SPAWN_ZONE_GAP  = 88,
    parameter integer DOUBLE_SPAWN_SCORE = 40,
    parameter integer PLAYER_LOOKAHEAD_Y = 220
) (
    input  wire       clk,
    input  wire       frame_tick,
    input  wire       enable,
    input  wire       clear_all,
    input  wire [3:0] speed,
    input  wire [6:0] spawn_interval,
    input  wire [15:0] score,
    input  wire [1:0] player_lane,
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
    reg [2:0] first_pick;
    reg [2:0] second_pick;
    reg [3:0] pass_counter;
    reg [3:0] first_forbidden;
    reg [3:0] second_forbidden;
    reg [3:0] danger_lane_mask;
    reg [10:0] y_advanced;
    reg [6:0] spawn_timer = 7'd24;
    reg       spawn_zone_busy;
    reg [1:0] spawn_cursor = 2'd0;
    reg [1:0] safe_lane;
    reg [3:0] active_count;

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

    function [3:0] lane_guard_mask;
        input [1:0] lane;
        begin
            case (lane)
                2'd0: lane_guard_mask = 4'b0001;
                2'd1: lane_guard_mask = 4'b0010;
                2'd2: lane_guard_mask = 4'b0100;
                default: lane_guard_mask = 4'b1000;
            endcase
        end
    endfunction

    function [3:0] pair_guard_mask;
        input [1:0] lane;
        begin
            case (lane)
                2'd0: pair_guard_mask = 4'b0011;
                2'd1: pair_guard_mask = 4'b0111;
                2'd2: pair_guard_mask = 4'b1110;
                default: pair_guard_mask = 4'b1100;
            endcase
        end
    endfunction

    function [3:0] lane_bit;
        input [1:0] lane;
        begin
            case (lane)
                2'd0: lane_bit = 4'b0001;
                2'd1: lane_bit = 4'b0010;
                2'd2: lane_bit = 4'b0100;
                default: lane_bit = 4'b1000;
            endcase
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
            spawn_timer <= 7'd24;
            spawn_cursor <= 2'd0;
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
                    first_forbidden = 4'b0000;
                    second_forbidden = 4'b0000;
                    danger_lane_mask = 4'b0000;
                    spawn_zone_busy = 1'b0;
                    slot_first = -1;
                    slot_second = -1;
                    active_count = 4'd0;
                    safe_lane = player_lane;

                    for (i = 0; i < ENEMY_COUNT; i = i + 1) begin
                        if (enemy_active[i] && (enemy_y[i] < (HUD_HEIGHT + SPAWN_ZONE_GAP))) begin
                            spawn_zone_busy = 1'b1;
                        end

                        if (enemy_active[i] && (enemy_y[i] < (HUD_HEIGHT + CAR_H + SAFE_SPAWN_GAP))) begin
                            lane_blocked = lane_blocked | lane_guard_mask(enemy_lane[i]);
                        end

                        if (enemy_active[i]) begin
                            active_count = active_count + 1'b1;
                        end

                        if (enemy_active[i] && (enemy_y[i] >= PLAYER_LOOKAHEAD_Y)) begin
                            danger_lane_mask = danger_lane_mask | lane_bit(enemy_lane[i]);
                        end

                        if (!enemy_active[i]) begin
                            if (slot_first < 0) begin
                                slot_first = i;
                            end else if (slot_second < 0) begin
                                slot_second = i;
                            end
                        end
                    end

                    if (!spawn_zone_busy) begin
                        if (danger_lane_mask[player_lane]) begin
                            if ((player_lane > 0) && !danger_lane_mask[player_lane - 1'b1]) begin
                                safe_lane = player_lane - 1'b1;
                            end else if ((player_lane < 2'd3) && !danger_lane_mask[player_lane + 1'b1]) begin
                                safe_lane = player_lane + 1'b1;
                            end else if (!danger_lane_mask[0]) begin
                                safe_lane = 2'd0;
                            end else if (!danger_lane_mask[1]) begin
                                safe_lane = 2'd1;
                            end else if (!danger_lane_mask[2]) begin
                                safe_lane = 2'd2;
                            end else begin
                                safe_lane = 2'd3;
                            end
                        end

                        first_forbidden = lane_bit(safe_lane);
                        first_pick = choose_lane(spawn_cursor, lane_blocked, first_forbidden);
                        if (first_pick[2] && (slot_first >= 0)) begin
                            enemy_active[slot_first] <= 1'b1;
                            enemy_lane[slot_first] <= first_pick[1:0];
                            enemy_y[slot_first] <= HUD_HEIGHT + 10'd4;
                            enemy_style[slot_first] <= rand_value[10:8] + slot_first[2:0];
                            second_forbidden = pair_guard_mask(first_pick[1:0]) | first_forbidden;
                            spawn_cursor <= first_pick[1:0] + 2'd1;
                        end else begin
                            spawn_cursor <= spawn_cursor + 2'd1;
                        end

                        if (first_pick[2] && (score >= DOUBLE_SPAWN_SCORE) && rand_value[6] && rand_value[5] &&
                            rand_value[9] && (slot_second >= 0) && (active_count < 4'd3)) begin
                            second_pick = choose_lane(
                                first_pick[2] ? (first_pick[1:0] + 2'd2) : (spawn_cursor + 2'd1),
                                lane_blocked,
                                second_forbidden
                            );
                            if (second_pick[2]) begin
                                enemy_active[slot_second] <= 1'b1;
                                enemy_lane[slot_second] <= second_pick[1:0];
                                enemy_y[slot_second] <= HUD_HEIGHT + 10'd52;
                                enemy_style[slot_second] <= rand_value[13:11] + slot_second[2:0];
                            end
                        end

                        spawn_timer <= spawn_interval;
                    end
                end else begin
                    spawn_timer <= spawn_timer - 1'b1;
                end
            end
        end
    end

endmodule
