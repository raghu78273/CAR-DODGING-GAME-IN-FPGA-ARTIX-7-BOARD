module game_renderer #(
    parameter integer SCREEN_W    = 640,
    parameter integer SCREEN_H    = 480,
    parameter integer HUD_HEIGHT  = 48,
    parameter integer ROAD_X0     = 120,
    parameter integer ROAD_W      = 400,
    parameter integer LANE_W      = 100,
    parameter integer CAR_W       = 54,
    parameter integer CAR_H       = 96,
    parameter integer PLAYER_Y    = 372,
    parameter integer ENEMY_COUNT = 8
) (
    input  wire       video_on,
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire [2:0] game_state,
    input  wire [5:0] road_scroll,
    input  wire [9:0] player_x,
    input  wire       player_visible,
    input  wire [ENEMY_COUNT-1:0] enemy_active,
    input  wire [ENEMY_COUNT*2-1:0] enemy_lane_bus,
    input  wire [ENEMY_COUNT*10-1:0] enemy_y_bus,
    input  wire [ENEMY_COUNT*3-1:0] enemy_style_bus,
    input  wire [19:0] score_bcd,
    input  wire [19:0] high_score_bcd,
    input  wire [2:0] lives,
    output reg  [11:0] rgb
);

    localparam [2:0] STATE_START     = 3'd0;
    localparam [2:0] STATE_PLAY      = 3'd1;
    localparam [2:0] STATE_PAUSE     = 3'd2;
    localparam [2:0] STATE_HIT       = 3'd3;
    localparam [2:0] STATE_GAME_OVER = 3'd4;

    integer i;
    integer life_idx;

    reg [11:0] scene_rgb;
    reg [11:0] sprite_rgb;
    reg [11:0] panel_fill;
    reg [11:0] panel_border;
    reg [9:0]  road_right;
    reg [9:0]  road_center;
    reg [9:0]  dash_phase;
    reg [9:0]  enemy_x;
    reg [9:0]  enemy_y;
    reg [6:0]  local_x;
    reg [6:0]  local_y;
    reg [9:0]  icon_left;
    reg [4:0]  mini_x;
    reg [4:0]  mini_y;
    reg [9:0]  x_offset;
    reg [9:0]  y_offset;
    reg [5:0]  char_index;
    reg [7:0]  selected_char;
    reg [2:0]  selected_row;
    reg [2:0]  selected_col;
    reg [11:0] text_color;
    reg        text_candidate_valid;

    wire [7:0] font_bits;
    wire text_pixel = text_candidate_valid && font_bits[7 - selected_col];

    function [9:0] lane_to_x;
        input [1:0] lane;
        begin
            lane_to_x = ROAD_X0 + (lane * LANE_W) + ((LANE_W - CAR_W) >> 1);
        end
    endfunction

    function [11:0] shade_down;
        input [11:0] color_in;
        reg [3:0] r;
        reg [3:0] g;
        reg [3:0] b;
        begin
            r = color_in[11:8];
            g = color_in[7:4];
            b = color_in[3:0];
            shade_down = {(r > 4'd4) ? (r - 4'd4) : 4'd0,
                          (g > 4'd4) ? (g - 4'd4) : 4'd0,
                          (b > 4'd4) ? (b - 4'd4) : 4'd0};
        end
    endfunction

    function car_shape;
        input [6:0] lx;
        input [6:0] ly;
        begin
            car_shape = (((lx >= 7'd11) && (lx < 7'd43) && (ly >= 7'd4)  && (ly < 7'd92)) ||
                         ((lx >= 7'd7)  && (lx < 7'd47) && (ly >= 7'd16) && (ly < 7'd80)) ||
                         ((lx >= 7'd17) && (lx < 7'd37) && (ly < 7'd96)));
        end
    endfunction

    function car_tire;
        input [6:0] lx;
        input [6:0] ly;
        begin
            car_tire = ((((lx >= 7'd2) && (lx < 7'd8))  || ((lx >= 7'd46) && (lx < 7'd52))) &&
                        (((ly >= 7'd18) && (ly < 7'd34)) || ((ly >= 7'd62) && (ly < 7'd78))));
        end
    endfunction

    function car_glass;
        input [6:0] lx;
        input [6:0] ly;
        begin
            car_glass = (((lx >= 7'd18) && (lx < 7'd36) && (ly >= 7'd12) && (ly < 7'd34)) ||
                         ((lx >= 7'd18) && (lx < 7'd36) && (ly >= 7'd58) && (ly < 7'd80)));
        end
    endfunction

    function car_stripe;
        input [6:0] lx;
        input [6:0] ly;
        begin
            car_stripe = ((lx >= 7'd24) && (lx < 7'd30) && (ly >= 7'd14) && (ly < 7'd82));
        end
    endfunction

    function car_lamp;
        input [6:0] lx;
        input [6:0] ly;
        begin
            car_lamp = ((((ly < 7'd8) || (ly >= 7'd88)) &&
                         (((lx >= 7'd14) && (lx < 7'd21)) || ((lx >= 7'd33) && (lx < 7'd40)))));
        end
    endfunction

    function car_outline;
        input [6:0] lx;
        input [6:0] ly;
        begin
            car_outline = (((lx >= 7'd16) && (lx < 7'd38) && ((ly < 7'd5) || (ly >= 7'd91))) ||
                           ((ly >= 7'd16) && (ly < 7'd80) && ((lx < 7'd8) || (lx >= 7'd46))) ||
                           ((ly >= 7'd4)  && (ly < 7'd92) && ((lx < 7'd12) || (lx >= 7'd42))));
        end
    endfunction

    function mini_car_shape;
        input [4:0] lx;
        input [4:0] ly;
        begin
            mini_car_shape = (((lx >= 5'd5) && (lx < 5'd13) && (ly >= 5'd2) && (ly < 5'd22)) ||
                              ((lx >= 5'd3) && (lx < 5'd15) && (ly >= 5'd6) && (ly < 5'd18)));
        end
    endfunction

    function [11:0] enemy_body_color;
        input [2:0] style;
        begin
            case (style)
                3'd0: enemy_body_color = 12'hF54;
                3'd1: enemy_body_color = 12'hFC3;
                3'd2: enemy_body_color = 12'h4C8;
                3'd3: enemy_body_color = 12'hD5F;
                3'd4: enemy_body_color = 12'hF7A;
                3'd5: enemy_body_color = 12'h6EF;
                3'd6: enemy_body_color = 12'h8E5;
                default: enemy_body_color = 12'hF85;
            endcase
        end
    endfunction

    function [11:0] enemy_trim_color;
        input [2:0] style;
        begin
            case (style)
                3'd0: enemy_trim_color = 12'hFDB;
                3'd1: enemy_trim_color = 12'h842;
                3'd2: enemy_trim_color = 12'hCFE;
                3'd3: enemy_trim_color = 12'hFFD;
                3'd4: enemy_trim_color = 12'hA24;
                3'd5: enemy_trim_color = 12'h047;
                3'd6: enemy_trim_color = 12'hFEB;
                default: enemy_trim_color = 12'hB31;
            endcase
        end
    endfunction

    function [11:0] car_pixel_color;
        input        is_player;
        input [2:0]  style;
        input [6:0]  lx;
        input [6:0]  ly;
        reg [11:0] body_col;
        reg [11:0] trim_col;
        reg [11:0] glass_col;
        reg [11:0] light_col;
        reg [11:0] wheel_col;
        begin
            if (!car_shape(lx, ly)) begin
                car_pixel_color = 12'h000;
            end else begin
                if (is_player) begin
                    body_col  = 12'h19F;
                    trim_col  = 12'h8FF;
                    glass_col = 12'hBFF;
                    light_col = 12'hFE8;
                    wheel_col = 12'h111;
                end else begin
                    body_col  = enemy_body_color(style);
                    trim_col  = enemy_trim_color(style);
                    glass_col = 12'hDFF;
                    light_col = 12'hFD8;
                    wheel_col = 12'h111;
                end

                if (car_tire(lx, ly)) begin
                    car_pixel_color = wheel_col;
                end else if (car_glass(lx, ly)) begin
                    car_pixel_color = glass_col;
                end else if (car_lamp(lx, ly)) begin
                    car_pixel_color = light_col;
                end else if (car_stripe(lx, ly)) begin
                    car_pixel_color = trim_col;
                end else if (car_outline(lx, ly)) begin
                    car_pixel_color = shade_down(body_col);
                end else begin
                    car_pixel_color = body_col;
                end
            end
        end
    endfunction

    function [7:0] digit_char;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: digit_char = "0";
                4'd1: digit_char = "1";
                4'd2: digit_char = "2";
                4'd3: digit_char = "3";
                4'd4: digit_char = "4";
                4'd5: digit_char = "5";
                4'd6: digit_char = "6";
                4'd7: digit_char = "7";
                4'd8: digit_char = "8";
                4'd9: digit_char = "9";
                default: digit_char = " ";
            endcase
        end
    endfunction

    function [7:0] bcd_display_char;
        input [19:0] bcd_value;
        input [2:0]  digit_index;
        reg [3:0] d0;
        reg [3:0] d1;
        reg [3:0] d2;
        reg [3:0] d3;
        reg [3:0] d4;
        begin
            d0 = bcd_value[19:16];
            d1 = bcd_value[15:12];
            d2 = bcd_value[11:8];
            d3 = bcd_value[7:4];
            d4 = bcd_value[3:0];

            case (digit_index)
                3'd0: bcd_display_char = (d0 == 4'd0) ? " " : digit_char(d0);
                3'd1: bcd_display_char = ((d0 == 4'd0) && (d1 == 4'd0)) ? " " : digit_char(d1);
                3'd2: bcd_display_char = ((d0 == 4'd0) && (d1 == 4'd0) && (d2 == 4'd0)) ? " " : digit_char(d2);
                3'd3: bcd_display_char = ((d0 == 4'd0) && (d1 == 4'd0) && (d2 == 4'd0) && (d3 == 4'd0)) ? " " : digit_char(d3);
                default: bcd_display_char = digit_char(d4);
            endcase
        end
    endfunction

    function [7:0] hud_score_char;
        input [5:0] index;
        input [19:0] bcd_value;
        begin
            case (index)
                6'd0: hud_score_char = "S";
                6'd1: hud_score_char = "C";
                6'd2: hud_score_char = "O";
                6'd3: hud_score_char = "R";
                6'd4: hud_score_char = "E";
                6'd5: hud_score_char = " ";
                6'd6: hud_score_char = bcd_display_char(bcd_value, 3'd0);
                6'd7: hud_score_char = bcd_display_char(bcd_value, 3'd1);
                6'd8: hud_score_char = bcd_display_char(bcd_value, 3'd2);
                6'd9: hud_score_char = bcd_display_char(bcd_value, 3'd3);
                default: hud_score_char = bcd_display_char(bcd_value, 3'd4);
            endcase
        end
    endfunction

    function [7:0] hud_best_char;
        input [5:0] index;
        input [19:0] bcd_value;
        begin
            case (index)
                6'd0: hud_best_char = "B";
                6'd1: hud_best_char = "E";
                6'd2: hud_best_char = "S";
                6'd3: hud_best_char = "T";
                6'd4: hud_best_char = " ";
                6'd5: hud_best_char = bcd_display_char(bcd_value, 3'd0);
                6'd6: hud_best_char = bcd_display_char(bcd_value, 3'd1);
                6'd7: hud_best_char = bcd_display_char(bcd_value, 3'd2);
                6'd8: hud_best_char = bcd_display_char(bcd_value, 3'd3);
                default: hud_best_char = bcd_display_char(bcd_value, 3'd4);
            endcase
        end
    endfunction

    function [7:0] hud_lives_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: hud_lives_char = "L";
                6'd1: hud_lives_char = "I";
                6'd2: hud_lives_char = "V";
                6'd3: hud_lives_char = "E";
                default: hud_lives_char = "S";
            endcase
        end
    endfunction

    function [7:0] start_title_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: start_title_char = "C";
                6'd1: start_title_char = "A";
                6'd2: start_title_char = "R";
                6'd3: start_title_char = " ";
                6'd4: start_title_char = "D";
                6'd5: start_title_char = "O";
                6'd6: start_title_char = "D";
                6'd7: start_title_char = "G";
                6'd8: start_title_char = "E";
                default: start_title_char = "R";
            endcase
        end
    endfunction

    function [7:0] start_line1_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: start_line1_char = "D";
                6'd1: start_line1_char = "O";
                6'd2: start_line1_char = "D";
                6'd3: start_line1_char = "G";
                6'd4: start_line1_char = "E";
                6'd5: start_line1_char = " ";
                6'd6: start_line1_char = "T";
                6'd7: start_line1_char = "R";
                6'd8: start_line1_char = "A";
                6'd9: start_line1_char = "F";
                6'd10: start_line1_char = "F";
                6'd11: start_line1_char = "I";
                default: start_line1_char = "C";
            endcase
        end
    endfunction

    function [7:0] start_line2_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: start_line2_char = "L";
                6'd1: start_line2_char = "E";
                6'd2: start_line2_char = "F";
                6'd3: start_line2_char = "T";
                6'd4: start_line2_char = " ";
                6'd5: start_line2_char = "R";
                6'd6: start_line2_char = "I";
                6'd7: start_line2_char = "G";
                6'd8: start_line2_char = "H";
                6'd9: start_line2_char = "T";
                6'd10: start_line2_char = " ";
                6'd11: start_line2_char = "M";
                6'd12: start_line2_char = "O";
                6'd13: start_line2_char = "V";
                default: start_line2_char = "E";
            endcase
        end
    endfunction

    function [7:0] press_start_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: press_start_char = "P";
                6'd1: press_start_char = "R";
                6'd2: press_start_char = "E";
                6'd3: press_start_char = "S";
                6'd4: press_start_char = "S";
                6'd5: press_start_char = " ";
                6'd6: press_start_char = "S";
                6'd7: press_start_char = "T";
                6'd8: press_start_char = "A";
                6'd9: press_start_char = "R";
                default: press_start_char = "T";
            endcase
        end
    endfunction

    function [7:0] up_pause_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: up_pause_char = "U";
                6'd1: up_pause_char = "P";
                6'd2: up_pause_char = " ";
                6'd3: up_pause_char = "P";
                6'd4: up_pause_char = "A";
                6'd5: up_pause_char = "U";
                6'd6: up_pause_char = "S";
                default: up_pause_char = "E";
            endcase
        end
    endfunction

    function [7:0] up_resume_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: up_resume_char = "U";
                6'd1: up_resume_char = "P";
                6'd2: up_resume_char = " ";
                6'd3: up_resume_char = "R";
                6'd4: up_resume_char = "E";
                6'd5: up_resume_char = "S";
                6'd6: up_resume_char = "U";
                6'd7: up_resume_char = "M";
                default: up_resume_char = "E";
            endcase
        end
    endfunction

    function [7:0] down_restart_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: down_restart_char = "D";
                6'd1: down_restart_char = "O";
                6'd2: down_restart_char = "W";
                6'd3: down_restart_char = "N";
                6'd4: down_restart_char = " ";
                6'd5: down_restart_char = "R";
                6'd6: down_restart_char = "E";
                6'd7: down_restart_char = "S";
                6'd8: down_restart_char = "T";
                6'd9: down_restart_char = "A";
                6'd10: down_restart_char = "R";
                6'd11: down_restart_char = "T";
                default: down_restart_char = " ";
            endcase
        end
    endfunction

    function [7:0] paused_title_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: paused_title_char = "P";
                6'd1: paused_title_char = "A";
                6'd2: paused_title_char = "U";
                6'd3: paused_title_char = "S";
                6'd4: paused_title_char = "E";
                default: paused_title_char = "D";
            endcase
        end
    endfunction

    function [7:0] game_over_title_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: game_over_title_char = "G";
                6'd1: game_over_title_char = "A";
                6'd2: game_over_title_char = "M";
                6'd3: game_over_title_char = "E";
                6'd4: game_over_title_char = " ";
                6'd5: game_over_title_char = "O";
                6'd6: game_over_title_char = "V";
                6'd7: game_over_title_char = "E";
                default: game_over_title_char = "R";
            endcase
        end
    endfunction

    function [7:0] crash_title_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: crash_title_char = "C";
                6'd1: crash_title_char = "R";
                6'd2: crash_title_char = "A";
                6'd3: crash_title_char = "S";
                default: crash_title_char = "H";
            endcase
        end
    endfunction

    function [7:0] life_lost_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: life_lost_char = "L";
                6'd1: life_lost_char = "I";
                6'd2: life_lost_char = "F";
                6'd3: life_lost_char = "E";
                6'd4: life_lost_char = " ";
                6'd5: life_lost_char = "L";
                6'd6: life_lost_char = "O";
                6'd7: life_lost_char = "S";
                default: life_lost_char = "T";
            endcase
        end
    endfunction

    font8x8 font_rom (
        .char_code(selected_char),
        .row(selected_row),
        .bits(font_bits)
    );

    always @* begin
        road_right  = ROAD_X0 + ROAD_W;
        road_center = ROAD_X0 + (ROAD_W >> 1);
        dash_phase  = pix_y + {road_scroll, 2'b00};
        scene_rgb   = 12'h000;
        sprite_rgb  = 12'h000;
        panel_fill  = 12'h000;
        panel_border = 12'h000;

        if (video_on) begin
            if (pix_y < HUD_HEIGHT) begin
                if (pix_y < 10'd16) begin
                    scene_rgb = (pix_x[5] ^ pix_x[4]) ? 12'h034 : 12'h024;
                end else if (pix_y < 10'd32) begin
                    scene_rgb = (pix_x[5] ^ pix_y[3]) ? 12'h046 : 12'h036;
                end else begin
                    scene_rgb = (pix_x[4] ^ pix_y[4]) ? 12'h034 : 12'h024;
                end
            end else if ((pix_x < ROAD_X0) || (pix_x >= road_right)) begin
                scene_rgb = (pix_x[4] ^ pix_y[4]) ? 12'h173 : 12'h062;
                if (pix_x[5] && pix_y[5]) begin
                    scene_rgb = 12'h284;
                end
            end else begin
                scene_rgb = (pix_x[4] ^ pix_y[4]) ? 12'h444 : 12'h333;

                if (((pix_x >= ROAD_X0) && (pix_x < (ROAD_X0 + 10))) ||
                    ((pix_x >= (road_right - 10)) && (pix_x < road_right))) begin
                    scene_rgb = dash_phase[4] ? 12'hF42 : 12'hFEE;
                end

                if (((pix_x >= (ROAD_X0 + LANE_W - 3)) && (pix_x < (ROAD_X0 + LANE_W + 3))) ||
                    ((pix_x >= (ROAD_X0 + (LANE_W << 1) - 3)) && (pix_x < (ROAD_X0 + (LANE_W << 1) + 3))) ||
                    ((pix_x >= (ROAD_X0 + (LANE_W * 3) - 3)) && (pix_x < (ROAD_X0 + (LANE_W * 3) + 3)))) begin
                    if (dash_phase[4:0] < 5'd20) begin
                        scene_rgb = (pix_x >= road_center - 10'd3 && pix_x < road_center + 10'd3) ? 12'hFD8 : 12'hEEE;
                    end
                end

                if ((pix_x > (road_center - 10'd40)) && (pix_x < (road_center + 10'd40)) && pix_y[5]) begin
                    scene_rgb = (scene_rgb == 12'h333) ? 12'h3A3 : scene_rgb;
                end
            end

            for (life_idx = 0; life_idx < 3; life_idx = life_idx + 1) begin
                icon_left = 10'd500 + (life_idx * 10'd28);
                if ((pix_x >= icon_left) && (pix_x < (icon_left + 10'd18)) &&
                    (pix_y >= 10'd18) && (pix_y < 10'd42)) begin
                    mini_x = pix_x - icon_left;
                    mini_y = pix_y - 10'd18;
                    if (mini_car_shape(mini_x, mini_y)) begin
                        if (life_idx < lives) begin
                            scene_rgb = 12'h2CF;
                        end else begin
                            scene_rgb = 12'h234;
                        end
                    end
                end
            end

            for (i = 0; i < ENEMY_COUNT; i = i + 1) begin
                if (enemy_active[i]) begin
                    enemy_x = lane_to_x(enemy_lane_bus[(i * 2) +: 2]);
                    enemy_y = enemy_y_bus[(i * 10) +: 10];
                    if ((pix_x >= enemy_x) && (pix_x < (enemy_x + CAR_W)) &&
                        (pix_y >= enemy_y) && (pix_y < (enemy_y + CAR_H))) begin
                        local_x = pix_x - enemy_x;
                        local_y = pix_y - enemy_y;
                        sprite_rgb = car_pixel_color(1'b0, enemy_style_bus[(i * 3) +: 3], local_x, local_y);
                        if (sprite_rgb != 12'h000) begin
                            scene_rgb = sprite_rgb;
                        end
                    end
                end
            end

            if (player_visible &&
                (pix_x >= player_x) && (pix_x < (player_x + CAR_W)) &&
                (pix_y >= PLAYER_Y) && (pix_y < (PLAYER_Y + CAR_H))) begin
                local_x = pix_x - player_x;
                local_y = pix_y - PLAYER_Y;
                sprite_rgb = car_pixel_color(1'b1, 3'd0, local_x, local_y);
                if (sprite_rgb != 12'h000) begin
                    scene_rgb = sprite_rgb;
                end
            end

            if (game_state != STATE_PLAY) begin
                case (game_state)
                    STATE_START: begin
                        panel_fill = 12'h013;
                        panel_border = 12'h8EF;
                    end
                    STATE_PAUSE: begin
                        panel_fill = 12'h022;
                        panel_border = 12'h7FE;
                    end
                    STATE_HIT: begin
                        panel_fill = 12'h320;
                        panel_border = 12'hFA4;
                    end
                    default: begin
                        panel_fill = 12'h300;
                        panel_border = 12'hF54;
                    end
                endcase

                if ((pix_x >= 10'd96) && (pix_x < 10'd544) &&
                    (pix_y >= 10'd80) && (pix_y < 10'd352)) begin
                    if ((pix_x < 10'd100) || (pix_x >= 10'd540) ||
                        (pix_y < 10'd84)  || (pix_y >= 10'd348)) begin
                        scene_rgb = panel_border;
                    end else begin
                        scene_rgb = panel_fill;
                    end
                end
            end
        end
    end

    always @* begin
        text_candidate_valid = 1'b0;
        selected_char = " ";
        selected_row = 3'd0;
        selected_col = 3'd0;
        text_color = 12'hFFF;
        x_offset = 10'd0;
        y_offset = 10'd0;
        char_index = 6'd0;

        if (video_on) begin
            if (!text_candidate_valid &&
                (pix_y >= 10'd8) && (pix_y < 10'd24) &&
                (pix_x >= 10'd16) && (pix_x < 10'd192)) begin
                x_offset = pix_x - 10'd16;
                y_offset = pix_y - 10'd8;
                char_index = x_offset[9:4];
                selected_char = hud_score_char(char_index, score_bcd);
                if (selected_char != " ") begin
                    text_candidate_valid = 1'b1;
                    selected_row = y_offset[4:1];
                    selected_col = x_offset[3:1];
                    text_color = 12'hFFE;
                end
            end

            if (!text_candidate_valid &&
                (pix_y >= 10'd8) && (pix_y < 10'd24) &&
                (pix_x >= 10'd220) && (pix_x < 10'd380)) begin
                x_offset = pix_x - 10'd220;
                y_offset = pix_y - 10'd8;
                char_index = x_offset[9:4];
                selected_char = hud_best_char(char_index, high_score_bcd);
                if (selected_char != " ") begin
                    text_candidate_valid = 1'b1;
                    selected_row = y_offset[4:1];
                    selected_col = x_offset[3:1];
                    text_color = 12'hCFF;
                end
            end

            if (!text_candidate_valid &&
                (pix_y >= 10'd8) && (pix_y < 10'd24) &&
                (pix_x >= 10'd412) && (pix_x < 10'd492)) begin
                x_offset = pix_x - 10'd412;
                y_offset = pix_y - 10'd8;
                char_index = x_offset[9:4];
                selected_char = hud_lives_char(char_index);
                if (selected_char != " ") begin
                    text_candidate_valid = 1'b1;
                    selected_row = y_offset[4:1];
                    selected_col = x_offset[3:1];
                    text_color = 12'hAFC;
                end
            end

            if (game_state == STATE_START) begin
                if (!text_candidate_valid &&
                    (pix_y >= 10'd92) && (pix_y < 10'd124) &&
                    (pix_x >= 10'd160) && (pix_x < 10'd480)) begin
                    x_offset = pix_x - 10'd160;
                    y_offset = pix_y - 10'd92;
                    char_index = x_offset[9:5];
                    selected_char = start_title_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:2];
                        selected_col = x_offset[4:2];
                        text_color = 12'h8FF;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd170) && (pix_y < 10'd186) &&
                    (pix_x >= 10'd216) && (pix_x < 10'd424)) begin
                    x_offset = pix_x - 10'd216;
                    y_offset = pix_y - 10'd170;
                    char_index = x_offset[9:4];
                    selected_char = start_line1_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hFEC;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd200) && (pix_y < 10'd216) &&
                    (pix_x >= 10'd200) && (pix_x < 10'd440)) begin
                    x_offset = pix_x - 10'd200;
                    y_offset = pix_y - 10'd200;
                    char_index = x_offset[9:4];
                    selected_char = start_line2_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hFFF;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd230) && (pix_y < 10'd246) &&
                    (pix_x >= 10'd232) && (pix_x < 10'd408)) begin
                    x_offset = pix_x - 10'd232;
                    y_offset = pix_y - 10'd230;
                    char_index = x_offset[9:4];
                    selected_char = press_start_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hAFA;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd260) && (pix_y < 10'd276) &&
                    (pix_x >= 10'd264) && (pix_x < 10'd392)) begin
                    x_offset = pix_x - 10'd264;
                    y_offset = pix_y - 10'd260;
                    char_index = x_offset[9:4];
                    selected_char = up_pause_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hFED;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd290) && (pix_y < 10'd306) &&
                    (pix_x >= 10'd224) && (pix_x < 10'd416)) begin
                    x_offset = pix_x - 10'd224;
                    y_offset = pix_y - 10'd290;
                    char_index = x_offset[9:4];
                    selected_char = down_restart_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hFED;
                    end
                end
            end

            if (game_state == STATE_PAUSE) begin
                if (!text_candidate_valid &&
                    (pix_y >= 10'd140) && (pix_y < 10'd172) &&
                    (pix_x >= 10'd224) && (pix_x < 10'd416)) begin
                    x_offset = pix_x - 10'd224;
                    y_offset = pix_y - 10'd140;
                    char_index = x_offset[9:5];
                    selected_char = paused_title_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:2];
                        selected_col = x_offset[4:2];
                        text_color = 12'h8FF;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd220) && (pix_y < 10'd236) &&
                    (pix_x >= 10'd248) && (pix_x < 10'd392)) begin
                    x_offset = pix_x - 10'd248;
                    y_offset = pix_y - 10'd220;
                    char_index = x_offset[9:4];
                    selected_char = up_resume_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hCFF;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd250) && (pix_y < 10'd266) &&
                    (pix_x >= 10'd224) && (pix_x < 10'd416)) begin
                    x_offset = pix_x - 10'd224;
                    y_offset = pix_y - 10'd250;
                    char_index = x_offset[9:4];
                    selected_char = down_restart_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hFED;
                    end
                end
            end

            if (game_state == STATE_GAME_OVER) begin
                if (!text_candidate_valid &&
                    (pix_y >= 10'd140) && (pix_y < 10'd172) &&
                    (pix_x >= 10'd176) && (pix_x < 10'd464)) begin
                    x_offset = pix_x - 10'd176;
                    y_offset = pix_y - 10'd140;
                    char_index = x_offset[9:5];
                    selected_char = game_over_title_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:2];
                        selected_col = x_offset[4:2];
                        text_color = 12'hF98;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd220) && (pix_y < 10'd236) &&
                    (pix_x >= 10'd232) && (pix_x < 10'd408)) begin
                    x_offset = pix_x - 10'd232;
                    y_offset = pix_y - 10'd220;
                    char_index = x_offset[9:4];
                    selected_char = press_start_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hFEC;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd250) && (pix_y < 10'd266) &&
                    (pix_x >= 10'd224) && (pix_x < 10'd416)) begin
                    x_offset = pix_x - 10'd224;
                    y_offset = pix_y - 10'd250;
                    char_index = x_offset[9:4];
                    selected_char = down_restart_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hFED;
                    end
                end
            end

            if (game_state == STATE_HIT) begin
                if (!text_candidate_valid &&
                    (pix_y >= 10'd160) && (pix_y < 10'd192) &&
                    (pix_x >= 10'd240) && (pix_x < 10'd400)) begin
                    x_offset = pix_x - 10'd240;
                    y_offset = pix_y - 10'd160;
                    char_index = x_offset[9:5];
                    selected_char = crash_title_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:2];
                        selected_col = x_offset[4:2];
                        text_color = 12'hFCA;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd230) && (pix_y < 10'd246) &&
                    (pix_x >= 10'd248) && (pix_x < 10'd392)) begin
                    x_offset = pix_x - 10'd248;
                    y_offset = pix_y - 10'd230;
                    char_index = x_offset[9:4];
                    selected_char = life_lost_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hFFF;
                    end
                end
            end
        end
    end

    always @* begin
        if (!video_on) begin
            rgb = 12'h000;
        end else if (text_pixel) begin
            rgb = text_color;
        end else begin
            rgb = scene_rgb;
        end
    end

endmodule
