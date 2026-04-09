module game_state #(
    parameter integer LANE_COUNT    = 4,
    parameter integer ROAD_X0       = 120,
    parameter integer LANE_W        = 100,
    parameter integer CAR_W         = 54,
    parameter integer DEFAULT_LANE  = 1,
    parameter integer PLAYER_Y      = 372,
    parameter integer HIT_HOLD_FRAMES = 40
) (
    input  wire       clk,
    input  wire       frame_tick,
    input  wire       btn_left_pulse,
    input  wire       btn_right_pulse,
    input  wire       btn_start_pulse,
    input  wire       btn_pause_pulse,
    input  wire       btn_restart_pulse,
    input  wire [3:0] passed_count,
    input  wire       collision,
    output reg  [2:0] state         = 3'd0,
    output reg  [1:0] player_lane   = DEFAULT_LANE,
    output reg  [9:0] player_x      = 10'd0,
    output wire [9:0] player_y,
    output reg  [15:0] score        = 16'd0,
    output reg  [15:0] high_score   = 16'd0,
    output reg  [2:0] lives         = 3'd3,
    output reg  [3:0] enemy_speed   = 4'd4,
    output reg  [6:0] spawn_interval = 7'd34,
    output reg  [5:0] road_scroll   = 6'd0,
    output reg        clear_enemies = 1'b0,
    output reg        player_visible = 1'b1
);

    localparam [2:0] STATE_START     = 3'd0;
    localparam [2:0] STATE_PLAY      = 3'd1;
    localparam [2:0] STATE_PAUSE     = 3'd2;
    localparam [2:0] STATE_HIT       = 3'd3;
    localparam [2:0] STATE_GAME_OVER = 3'd4;
    localparam [1:0] DEFAULT_LANE_VALUE = DEFAULT_LANE;
    localparam [9:0] PLAYER_Y_VALUE = PLAYER_Y;
    localparam [5:0] HIT_HOLD_VALUE = HIT_HOLD_FRAMES;

    reg [5:0] hit_timer = 6'd0;
    reg [1:0] lane_candidate;
    reg [9:0] target_x;
    reg [15:0] score_candidate;

    function [9:0] lane_to_x;
        input [1:0] lane;
        begin
            lane_to_x = ROAD_X0 + (lane * LANE_W) + ((LANE_W - CAR_W) >> 1);
        end
    endfunction

    function [3:0] speed_from_score;
        input [15:0] score_value;
        begin
            if (score_value < 16'd6) begin
                speed_from_score = 4'd4;
            end else if (score_value < 16'd12) begin
                speed_from_score = 4'd5;
            end else if (score_value < 16'd20) begin
                speed_from_score = 4'd6;
            end else if (score_value < 16'd30) begin
                speed_from_score = 4'd7;
            end else if (score_value < 16'd42) begin
                speed_from_score = 4'd8;
            end else if (score_value < 16'd56) begin
                speed_from_score = 4'd9;
            end else begin
                speed_from_score = 4'd10;
            end
        end
    endfunction

    function [6:0] interval_from_score;
        input [15:0] score_value;
        begin
            if (score_value < 16'd6) begin
                interval_from_score = 7'd34;
            end else if (score_value < 16'd12) begin
                interval_from_score = 7'd31;
            end else if (score_value < 16'd20) begin
                interval_from_score = 7'd28;
            end else if (score_value < 16'd30) begin
                interval_from_score = 7'd25;
            end else if (score_value < 16'd42) begin
                interval_from_score = 7'd22;
            end else if (score_value < 16'd56) begin
                interval_from_score = 7'd20;
            end else begin
                interval_from_score = 7'd18;
            end
        end
    endfunction

    assign player_y = PLAYER_Y_VALUE;

    always @(posedge clk) begin
        clear_enemies <= 1'b0;

        if (frame_tick) begin
            score_candidate = score;
            if (passed_count != 4'd0) begin
                score_candidate = score + passed_count;
            end

            case (state)
                STATE_START: begin
                    player_visible <= 1'b1;
                    player_lane <= DEFAULT_LANE_VALUE;
                    player_x <= lane_to_x(DEFAULT_LANE_VALUE);
                    road_scroll <= 6'd0;

                    if (btn_start_pulse || btn_restart_pulse) begin
                        state <= STATE_PLAY;
                        score <= 16'd0;
                        lives <= 3'd3;
                        player_lane <= DEFAULT_LANE_VALUE;
                        player_x <= lane_to_x(DEFAULT_LANE_VALUE);
                        road_scroll <= 6'd0;
                        enemy_speed <= 4'd4;
                        spawn_interval <= 7'd34;
                        clear_enemies <= 1'b1;
                    end
                end

                STATE_PLAY: begin
                    player_visible <= 1'b1;
                    road_scroll <= road_scroll + enemy_speed;

                    lane_candidate = player_lane;
                    if (btn_left_pulse && !btn_right_pulse && (player_lane > 0)) begin
                        lane_candidate = player_lane - 1'b1;
                    end else if (btn_right_pulse && !btn_left_pulse && (player_lane < (LANE_COUNT - 1))) begin
                        lane_candidate = player_lane + 1'b1;
                    end

                    player_lane <= lane_candidate;
                    target_x = lane_to_x(lane_candidate);
                    if (player_x < target_x) begin
                        if ((target_x - player_x) > 10'd12) begin
                            player_x <= player_x + 10'd12;
                        end else begin
                            player_x <= target_x;
                        end
                    end else if (player_x > target_x) begin
                        if ((player_x - target_x) > 10'd12) begin
                            player_x <= player_x - 10'd12;
                        end else begin
                            player_x <= target_x;
                        end
                    end

                    if (passed_count != 4'd0) begin
                        score <= score_candidate;
                        if (score_candidate > high_score) begin
                            high_score <= score_candidate;
                        end
                    end

                    enemy_speed <= speed_from_score(score_candidate);
                    spawn_interval <= interval_from_score(score_candidate);

                    if (btn_restart_pulse) begin
                        state <= STATE_PLAY;
                        score <= 16'd0;
                        lives <= 3'd3;
                        player_lane <= DEFAULT_LANE_VALUE;
                        player_x <= lane_to_x(DEFAULT_LANE_VALUE);
                        road_scroll <= 6'd0;
                        enemy_speed <= 4'd4;
                        spawn_interval <= 7'd34;
                        clear_enemies <= 1'b1;
                    end else if (btn_pause_pulse) begin
                        state <= STATE_PAUSE;
                    end else if (collision) begin
                        clear_enemies <= 1'b1;
                        player_lane <= DEFAULT_LANE_VALUE;
                        player_x <= lane_to_x(DEFAULT_LANE_VALUE);
                        if (lives > 3'd1) begin
                            lives <= lives - 1'b1;
                            state <= STATE_HIT;
                            hit_timer <= HIT_HOLD_VALUE;
                        end else begin
                            lives <= 3'd0;
                            state <= STATE_GAME_OVER;
                        end
                    end
                end

                STATE_PAUSE: begin
                    player_visible <= 1'b1;
                    if (btn_restart_pulse) begin
                        state <= STATE_PLAY;
                        score <= 16'd0;
                        lives <= 3'd3;
                        player_lane <= DEFAULT_LANE_VALUE;
                        player_x <= lane_to_x(DEFAULT_LANE_VALUE);
                        road_scroll <= 6'd0;
                        enemy_speed <= 4'd4;
                        spawn_interval <= 7'd34;
                        clear_enemies <= 1'b1;
                    end else if (btn_pause_pulse || btn_start_pulse) begin
                        state <= STATE_PLAY;
                    end
                end

                STATE_HIT: begin
                    player_visible <= hit_timer[2];
                    if (btn_restart_pulse) begin
                        state <= STATE_PLAY;
                        score <= 16'd0;
                        lives <= 3'd3;
                        player_lane <= DEFAULT_LANE_VALUE;
                        player_x <= lane_to_x(DEFAULT_LANE_VALUE);
                        road_scroll <= 6'd0;
                        enemy_speed <= 4'd4;
                        spawn_interval <= 7'd34;
                        clear_enemies <= 1'b1;
                        player_visible <= 1'b1;
                    end else if (hit_timer == 6'd0) begin
                        state <= STATE_PLAY;
                        player_visible <= 1'b1;
                    end else begin
                        hit_timer <= hit_timer - 1'b1;
                    end
                end

                default: begin
                    player_visible <= 1'b1;
                    if (btn_start_pulse || btn_restart_pulse) begin
                        state <= STATE_PLAY;
                        score <= 16'd0;
                        lives <= 3'd3;
                        player_lane <= DEFAULT_LANE_VALUE;
                        player_x <= lane_to_x(DEFAULT_LANE_VALUE);
                        road_scroll <= 6'd0;
                        enemy_speed <= 4'd4;
                        spawn_interval <= 7'd34;
                        clear_enemies <= 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
