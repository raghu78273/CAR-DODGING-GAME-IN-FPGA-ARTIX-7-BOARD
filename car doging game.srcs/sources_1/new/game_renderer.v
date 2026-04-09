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
    input  wire       player_style,
    input  wire       player_visible,
    input  wire [ENEMY_COUNT-1:0] enemy_active,
    input  wire [ENEMY_COUNT*2-1:0] enemy_lane_bus,
    input  wire [ENEMY_COUNT*10-1:0] enemy_y_bus,
    input  wire [ENEMY_COUNT*3-1:0] enemy_style_bus,
    input  wire [19:0] score_bcd,
    input  wire [19:0] player1_score_bcd,
    input  wire [19:0] player2_score_bcd,
    input  wire [19:0] high_score_bcd,
    input  wire [1:0]  winner,
    input  wire [2:0] lives,
    output reg  [11:0] rgb
);

    localparam [2:0] STATE_START     = 3'd0;
    localparam [2:0] STATE_PLAY      = 3'd1;
    localparam [2:0] STATE_PAUSE     = 3'd2;
    localparam [2:0] STATE_HIT       = 3'd3;
    localparam [2:0] STATE_TURN_OVER = 3'd4;
    localparam [2:0] STATE_GAME_OVER = 3'd5;

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

    function [11:0] shade_up;
        input [11:0] color_in;
        reg [3:0] r;
        reg [3:0] g;
        reg [3:0] b;
        begin
            r = color_in[11:8];
            g = color_in[7:4];
            b = color_in[3:0];
            shade_up = {(r < 4'd11) ? (r + 4'd4) : 4'd15,
                        (g < 4'd11) ? (g + 4'd4) : 4'd15,
                        (b < 4'd11) ? (b + 4'd4) : 4'd15};
        end
    endfunction

    function car_shape;
        input [6:0] lx;
        input [6:0] ly;
        begin
            car_shape = (
                ((ly >= 7'd4)  && (ly < 7'd16) && (lx >= (7'd26 - (ly >> 1))) && (lx < (7'd28 + (ly >> 1)))) ||
                ((ly >= 7'd16) && (ly < 7'd30) && (lx >= 7'd18) && (lx < 7'd36)) ||
                ((ly >= 7'd30) && (ly < 7'd72) && (lx >= 7'd10) && (lx < 7'd44)) ||
                ((ly >= 7'd72) && (ly < 7'd90) && (lx >= 7'd14) && (lx < 7'd40)) ||
                ((ly >= 7'd90) && (ly < 7'd96) && (lx >= 7'd18) && (lx < 7'd36)) ||
                ((ly >= 7'd34) && (ly < 7'd66) &&
                 (((lx >= 7'd5) && (lx < 7'd12)) || ((lx >= 7'd42) && (lx < 7'd49))))
            );
        end
    endfunction

    function car_tire;
        input [6:0] lx;
        input [6:0] ly;
        begin
            car_tire = (
                ((((lx >= 7'd2) && (lx < 7'd8)) || ((lx >= 7'd46) && (lx < 7'd52))) &&
                 (((ly >= 7'd18) && (ly < 7'd34)) || ((ly >= 7'd60) && (ly < 7'd78)))) ||
                ((((lx >= 7'd4) && (lx < 7'd9)) || ((lx >= 7'd45) && (lx < 7'd50))) &&
                 ((ly >= 7'd38) && (ly < 7'd58)))
            );
        end
    endfunction

    function car_glass;
        input [6:0] lx;
        input [6:0] ly;
        begin
            car_glass = (
                ((lx >= 7'd20) && (lx < 7'd34) && (ly >= 7'd18) && (ly < 7'd44)) ||
                ((lx >= 7'd22) && (lx < 7'd32) && (ly >= 7'd44) && (ly < 7'd58))
            );
        end
    endfunction

    function car_stripe;
        input [6:0] lx;
        input [6:0] ly;
        begin
            car_stripe = (
                (((lx >= 7'd18) && (lx < 7'd22)) || ((lx >= 7'd32) && (lx < 7'd36))) &&
                (ly >= 7'd12) && (ly < 7'd84)
            );
        end
    endfunction

    function car_lamp;
        input [6:0] lx;
        input [6:0] ly;
        begin
            car_lamp = (
                (((ly >= 7'd4) && (ly < 7'd10)) &&
                 (((lx >= 7'd22) && (lx < 7'd26)) || ((lx >= 7'd28) && (lx < 7'd32)))) ||
                (((ly >= 7'd84) && (ly < 7'd92)) &&
                 (((lx >= 7'd15) && (lx < 7'd21)) || ((lx >= 7'd33) && (lx < 7'd39))))
            );
        end
    endfunction

    function car_outline;
        input [6:0] lx;
        input [6:0] ly;
        begin
            car_outline = car_shape(lx, ly) && (
                (ly < 7'd6) || (ly >= 7'd92) ||
                (((ly >= 7'd16) && (ly < 7'd30)) && ((lx < 7'd20) || (lx >= 7'd34))) ||
                (((ly >= 7'd30) && (ly < 7'd72)) && ((lx < 7'd12) || (lx >= 7'd42))) ||
                (((ly >= 7'd72) && (ly < 7'd90)) && ((lx < 7'd16) || (lx >= 7'd38))) ||
                (((ly >= 7'd34) && (ly < 7'd66)) &&
                 (((lx >= 7'd5) && (lx < 7'd8)) || ((lx >= 7'd46) && (lx < 7'd49))))
            );
        end
    endfunction

    function mini_car_shape;
        input [4:0] lx;
        input [4:0] ly;
        begin
            mini_car_shape = (
                ((ly >= 5'd1) && (ly < 5'd5)  && (lx >= 5'd7) && (lx < 5'd11)) ||
                ((ly >= 5'd5) && (ly < 5'd14) && (lx >= 5'd4) && (lx < 5'd14)) ||
                ((ly >= 5'd14) && (ly < 5'd21) && (lx >= 5'd6) && (lx < 5'd12))
            );
        end
    endfunction

    function [11:0] enemy_body_color;
        input [2:0] style;
        begin
            case (style)
                3'd0: enemy_body_color = 12'hA55;
                3'd1: enemy_body_color = 12'hB96;
                3'd2: enemy_body_color = 12'h5A7;
                3'd3: enemy_body_color = 12'h756;
                3'd4: enemy_body_color = 12'hB77;
                3'd5: enemy_body_color = 12'h579;
                3'd6: enemy_body_color = 12'h7A6;
                default: enemy_body_color = 12'hA74;
            endcase
        end
    endfunction

    function [11:0] enemy_trim_color;
        input [2:0] style;
        begin
            case (style)
                3'd0: enemy_trim_color = 12'hEDC;
                3'd1: enemy_trim_color = 12'h654;
                3'd2: enemy_trim_color = 12'hCFE;
                3'd3: enemy_trim_color = 12'hDCC;
                3'd4: enemy_trim_color = 12'h843;
                3'd5: enemy_trim_color = 12'h9BD;
                3'd6: enemy_trim_color = 12'hEEC;
                default: enemy_trim_color = 12'hCBA;
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
                    if (!style[0]) begin
                        body_col  = 12'h2AA;
                        trim_col  = 12'hCFE;
                        glass_col = 12'hEFA;
                    end else begin
                        body_col  = 12'hD75;
                        trim_col  = 12'hFDB;
                        glass_col = 12'hFEE;
                    end
                    light_col = 12'hFDD;
                    wheel_col = 12'h111;
                end else begin
                    body_col  = enemy_body_color(style);
                    trim_col  = enemy_trim_color(style);
                    glass_col = 12'hCDE;
                    light_col = 12'hFCD;
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
                6'd10: hud_score_char = bcd_display_char(bcd_value, 3'd4);
                default: hud_score_char = " ";
            endcase
        end
    endfunction

    function [7:0] hud_player1_char;
        input [5:0] index;
        input [19:0] bcd_value;
        begin
            case (index)
                6'd0: hud_player1_char = "P";
                6'd1: hud_player1_char = "1";
                6'd2: hud_player1_char = " ";
                6'd3: hud_player1_char = bcd_display_char(bcd_value, 3'd0);
                6'd4: hud_player1_char = bcd_display_char(bcd_value, 3'd1);
                6'd5: hud_player1_char = bcd_display_char(bcd_value, 3'd2);
                6'd6: hud_player1_char = bcd_display_char(bcd_value, 3'd3);
                6'd7: hud_player1_char = bcd_display_char(bcd_value, 3'd4);
                default: hud_player1_char = " ";
            endcase
        end
    endfunction

    function [7:0] hud_player2_char;
        input [5:0] index;
        input [19:0] bcd_value;
        begin
            case (index)
                6'd0: hud_player2_char = "P";
                6'd1: hud_player2_char = "2";
                6'd2: hud_player2_char = " ";
                6'd3: hud_player2_char = bcd_display_char(bcd_value, 3'd0);
                6'd4: hud_player2_char = bcd_display_char(bcd_value, 3'd1);
                6'd5: hud_player2_char = bcd_display_char(bcd_value, 3'd2);
                6'd6: hud_player2_char = bcd_display_char(bcd_value, 3'd3);
                6'd7: hud_player2_char = bcd_display_char(bcd_value, 3'd4);
                default: hud_player2_char = " ";
            endcase
        end
    endfunction

    function [7:0] hud_hi_char;
        input [5:0] index;
        input [19:0] bcd_value;
        begin
            case (index)
                6'd0: hud_hi_char = "H";
                6'd1: hud_hi_char = "I";
                6'd2: hud_hi_char = " ";
                6'd3: hud_hi_char = bcd_display_char(bcd_value, 3'd0);
                6'd4: hud_hi_char = bcd_display_char(bcd_value, 3'd1);
                6'd5: hud_hi_char = bcd_display_char(bcd_value, 3'd2);
                6'd6: hud_hi_char = bcd_display_char(bcd_value, 3'd3);
                6'd7: hud_hi_char = bcd_display_char(bcd_value, 3'd4);
                default: hud_hi_char = " ";
            endcase
        end
    endfunction

    function [7:0] hud_turn_char;
        input [5:0] index;
        input       style;
        begin
            case (index)
                6'd0: hud_turn_char = "T";
                6'd1: hud_turn_char = "U";
                6'd2: hud_turn_char = "R";
                6'd3: hud_turn_char = "N";
                6'd4: hud_turn_char = " ";
                default: hud_turn_char = style ? "B" : "A";
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
                6'd9: hud_best_char = bcd_display_char(bcd_value, 3'd4);
                default: hud_best_char = " ";
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
                6'd0: start_title_char = "M";
                6'd1: start_title_char = "E";
                6'd2: start_title_char = "T";
                6'd3: start_title_char = "R";
                6'd4: start_title_char = "O";
                6'd5: start_title_char = " ";
                6'd6: start_title_char = "R";
                6'd7: start_title_char = "U";
                6'd8: start_title_char = "S";
                default: start_title_char = "H";
            endcase
        end
    endfunction

    function [7:0] start_line1_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: start_line1_char = "P";
                6'd1: start_line1_char = "L";
                6'd2: start_line1_char = "A";
                6'd3: start_line1_char = "Y";
                6'd4: start_line1_char = "E";
                6'd5: start_line1_char = "R";
                6'd6: start_line1_char = " ";
                6'd7: start_line1_char = "A";
                6'd8: start_line1_char = " ";
                6'd9: start_line1_char = "F";
                6'd10: start_line1_char = "I";
                6'd11: start_line1_char = "R";
                default: start_line1_char = "S";
            endcase
        end
    endfunction

    function [7:0] start_line2_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: start_line2_char = "T";
                6'd1: start_line2_char = "H";
                6'd2: start_line2_char = "E";
                6'd3: start_line2_char = "N";
                6'd4: start_line2_char = " ";
                6'd5: start_line2_char = "P";
                6'd6: start_line2_char = "L";
                6'd7: start_line2_char = "A";
                6'd8: start_line2_char = "Y";
                6'd9: start_line2_char = "E";
                6'd10: start_line2_char = "R";
                6'd11: start_line2_char = " ";
                6'd12: start_line2_char = "B";
                default: start_line2_char = " ";
            endcase
        end
    endfunction

    function [7:0] three_lives_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: three_lives_char = "3";
                6'd1: three_lives_char = " ";
                6'd2: three_lives_char = "L";
                6'd3: three_lives_char = "I";
                6'd4: three_lives_char = "V";
                6'd5: three_lives_char = "E";
                6'd6: three_lives_char = "S";
                6'd7: three_lives_char = " ";
                6'd8: three_lives_char = "E";
                6'd9: three_lives_char = "A";
                6'd10: three_lives_char = "C";
                default: three_lives_char = "H";
            endcase
        end
    endfunction

    function [7:0] turn_banner_char;
        input [5:0] index;
        input       style;
        begin
            case (index)
                6'd0: turn_banner_char = " ";
                6'd1: turn_banner_char = style ? "B" : "A";
                6'd2: turn_banner_char = " ";
                6'd3: turn_banner_char = "T";
                6'd4: turn_banner_char = "U";
                6'd5: turn_banner_char = "R";
                6'd6: turn_banner_char = "N";
                default: turn_banner_char = " ";
            endcase
        end
    endfunction

    function [7:0] winner_banner_char;
        input [5:0] index;
        input [1:0] who_won;
        begin
            case (who_won)
                2'd1: begin
                    case (index)
                        6'd0: winner_banner_char = " ";
                        6'd1: winner_banner_char = "A";
                        6'd2: winner_banner_char = " ";
                        6'd3: winner_banner_char = "W";
                        6'd4: winner_banner_char = "I";
                        6'd5: winner_banner_char = "N";
                        6'd6: winner_banner_char = "S";
                        default: winner_banner_char = " ";
                    endcase
                end
                2'd2: begin
                    case (index)
                        6'd0: winner_banner_char = " ";
                        6'd1: winner_banner_char = "B";
                        6'd2: winner_banner_char = " ";
                        6'd3: winner_banner_char = "W";
                        6'd4: winner_banner_char = "I";
                        6'd5: winner_banner_char = "N";
                        6'd6: winner_banner_char = "S";
                        default: winner_banner_char = " ";
                    endcase
                end
                default: begin
                    case (index)
                        6'd0: winner_banner_char = "T";
                        6'd1: winner_banner_char = "I";
                        6'd2: winner_banner_char = "E";
                        6'd3: winner_banner_char = " ";
                        6'd4: winner_banner_char = "G";
                        6'd5: winner_banner_char = "A";
                        6'd6: winner_banner_char = "M";
                        6'd7: winner_banner_char = "E";
                        default: winner_banner_char = " ";
                    endcase
                end
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

    function [7:0] get_ready_char;
        input [5:0] index;
        begin
            case (index)
                6'd0: get_ready_char = "G";
                6'd1: get_ready_char = "E";
                6'd2: get_ready_char = "T";
                6'd3: get_ready_char = " ";
                6'd4: get_ready_char = "R";
                6'd5: get_ready_char = "E";
                6'd6: get_ready_char = "A";
                6'd7: get_ready_char = "D";
                default: get_ready_char = "Y";
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
                if (pix_y < 10'd8) begin
                    scene_rgb = 12'h112;
                end else if (pix_y < 10'd22) begin
                    scene_rgb = 12'h223;
                end else if (pix_y < 10'd34) begin
                    scene_rgb = 12'h345;
                end else begin
                    scene_rgb = 12'h223;
                end

                if ((pix_y >= 10'd34) && (pix_y < 10'd40)) begin
                    if ((((pix_x + {road_scroll, 2'b00}) >> 5) & 10'h0001) == 10'd0) begin
                        scene_rgb = 12'hCCB;
                    end else begin
                        scene_rgb = 12'h556;
                    end
                end
            end else if ((pix_x < ROAD_X0) || (pix_x >= road_right)) begin
                if (pix_y < (HUD_HEIGHT + 10'd96)) begin
                    scene_rgb = 12'h8A9;
                end else if (pix_y < (HUD_HEIGHT + 10'd224)) begin
                    scene_rgb = 12'h7A8;
                end else begin
                    scene_rgb = 12'h697;
                end

                if (((pix_x >= (ROAD_X0 - 10'd16)) && (pix_x < ROAD_X0)) ||
                    ((pix_x >= road_right) && (pix_x < (road_right + 10'd16)))) begin
                    scene_rgb = 12'h99A;
                end

                if ((((dash_phase >> 5) & 10'h0001) == 10'd0) &&
                    ((((pix_x >= (ROAD_X0 - 10'd28)) && (pix_x < (ROAD_X0 - 10'd22))) ||
                      ((pix_x >= (road_right + 10'd22)) && (pix_x < (road_right + 10'd28)))))) begin
                    scene_rgb = 12'hFDD;
                end

                if ((((dash_phase >> 6) & 10'h0001) == 10'd0) &&
                    (((pix_x >= (ROAD_X0 - 10'd44)) && (pix_x < (ROAD_X0 - 10'd40))) ||
                     ((pix_x >= (road_right + 10'd40)) && (pix_x < (road_right + 10'd44))))) begin
                    scene_rgb = 12'hBCD;
                end
            end else begin
                if (pix_y < (HUD_HEIGHT + 10'd84)) begin
                    scene_rgb = 12'h667;
                end else if (pix_y < (HUD_HEIGHT + 10'd220)) begin
                    scene_rgb = 12'h445;
                end else begin
                    scene_rgb = 12'h556;
                end

                if (((pix_x >= ROAD_X0) && (pix_x < (ROAD_X0 + 10'd14))) ||
                    ((pix_x >= (road_right - 10'd14)) && (pix_x < road_right))) begin
                    scene_rgb = 12'hDCC;
                end else if (((pix_x >= (ROAD_X0 + 10'd14)) && (pix_x < (ROAD_X0 + 10'd24))) ||
                             ((pix_x >= (road_right - 10'd24)) && (pix_x < (road_right - 10'd14)))) begin
                    scene_rgb = 12'h788;
                end

                if ((((pix_x >= (ROAD_X0 + LANE_W - 10'd1)) && (pix_x < (ROAD_X0 + LANE_W + 10'd1))) ||
                     ((pix_x >= (ROAD_X0 + (LANE_W << 1) - 10'd1)) && (pix_x < (ROAD_X0 + (LANE_W << 1) + 10'd1))) ||
                     ((pix_x >= (ROAD_X0 + (LANE_W * 3) - 10'd1)) && (pix_x < (ROAD_X0 + (LANE_W * 3) + 10'd1)))) &&
                    (dash_phase[5:0] < 6'd24)) begin
                    scene_rgb = 12'hEED;
                end

                if ((((pix_x >= (ROAD_X0 + 10'd18)) && (pix_x < (ROAD_X0 + 10'd22))) ||
                     ((pix_x >= (road_right - 10'd22)) && (pix_x < (road_right - 10'd18)))) &&
                    (dash_phase[6:0] < 7'd10)) begin
                    scene_rgb = 12'hFDD;
                end

                if ((pix_x > (road_center - 10'd52)) && (pix_x < (road_center + 10'd52)) &&
                    (pix_y[6:5] == 2'b01) && (scene_rgb == 12'h445)) begin
                    scene_rgb = 12'h556;
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
                            scene_rgb = player_style ? 12'hD86 : 12'h4BC;
                        end else begin
                            scene_rgb = 12'h456;
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
                sprite_rgb = car_pixel_color(1'b1, {2'b00, player_style}, local_x, local_y);
                if (sprite_rgb != 12'h000) begin
                    scene_rgb = sprite_rgb;
                end
            end

            if (game_state != STATE_PLAY) begin
                case (game_state)
                    STATE_START: begin
                        panel_fill = 12'h112;
                        panel_border = 12'h7AD;
                    end
                    STATE_PAUSE: begin
                        panel_fill = 12'h223;
                        panel_border = 12'h8BC;
                    end
                    STATE_HIT: begin
                        panel_fill = 12'h421;
                        panel_border = 12'hD97;
                    end
                    STATE_TURN_OVER: begin
                        panel_fill = 12'h132;
                        panel_border = player_style ? 12'hDA8 : 12'h8BD;
                    end
                    default: begin
                        panel_fill = 12'h311;
                        panel_border = 12'hC86;
                    end
                endcase

                if ((pix_x >= 10'd92) && (pix_x < 10'd548) &&
                    (pix_y >= 10'd76) && (pix_y < 10'd356)) begin
                    if ((pix_x < 10'd98) || (pix_x >= 10'd542) ||
                        (pix_y < 10'd82)  || (pix_y >= 10'd350)) begin
                        scene_rgb = panel_border;
                    end else begin
                        scene_rgb = panel_fill;

                        if ((game_state != STATE_START) &&
                            (pix_y >= 10'd96) && (pix_y < 10'd108)) begin
                            scene_rgb = panel_border;
                            if (((((pix_x + {road_scroll, 2'b00}) >> 4) & 10'h0003) == 10'd0) &&
                                (pix_x >= 10'd120) && (pix_x < 10'd520)) begin
                                scene_rgb = shade_up(panel_border);
                            end
                        end

                        if ((pix_x >= 10'd116) && (pix_x < 10'd524) &&
                            (pix_y >= 10'd132) && (pix_y < 10'd134)) begin
                            scene_rgb = shade_down(panel_border);
                        end
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
        text_color = 12'hEDE;
        x_offset = 10'd0;
        y_offset = 10'd0;
        char_index = 6'd0;

        if (video_on) begin
            if (!text_candidate_valid &&
                (pix_y >= 10'd8) && (pix_y < 10'd24) &&
                (pix_x >= 10'd16) && (pix_x < 10'd144)) begin
                x_offset = pix_x - 10'd16;
                y_offset = pix_y - 10'd8;
                char_index = x_offset[9:4];
                selected_char = hud_player1_char(char_index, player1_score_bcd);
                if (selected_char != " ") begin
                    text_candidate_valid = 1'b1;
                    selected_row = y_offset[4:1];
                    selected_col = x_offset[3:1];
                    text_color = 12'h9BC;
                end
            end

            if (!text_candidate_valid &&
                (pix_y >= 10'd8) && (pix_y < 10'd24) &&
                (pix_x >= 10'd176) && (pix_x < 10'd304)) begin
                x_offset = pix_x - 10'd176;
                y_offset = pix_y - 10'd8;
                char_index = x_offset[9:4];
                selected_char = hud_player2_char(char_index, player2_score_bcd);
                if (selected_char != " ") begin
                    text_candidate_valid = 1'b1;
                    selected_row = y_offset[4:1];
                    selected_col = x_offset[3:1];
                    text_color = 12'hDB7;
                end
            end

            if (!text_candidate_valid &&
                (pix_y >= 10'd8) && (pix_y < 10'd24) &&
                (pix_x >= 10'd336) && (pix_x < 10'd464)) begin
                x_offset = pix_x - 10'd336;
                y_offset = pix_y - 10'd8;
                char_index = x_offset[9:4];
                selected_char = hud_hi_char(char_index, high_score_bcd);
                if (selected_char != " ") begin
                    text_candidate_valid = 1'b1;
                    selected_row = y_offset[4:1];
                    selected_col = x_offset[3:1];
                    text_color = 12'hFDD;
                end
            end

            if (!text_candidate_valid &&
                (pix_y >= 10'd24) && (pix_y < 10'd40) &&
                (pix_x >= 10'd16) && (pix_x < 10'd112)) begin
                x_offset = pix_x - 10'd16;
                y_offset = pix_y - 10'd24;
                char_index = x_offset[9:4];
                selected_char = hud_turn_char(char_index, player_style);
                if (selected_char != " ") begin
                    text_candidate_valid = 1'b1;
                    selected_row = y_offset[4:1];
                    selected_col = x_offset[3:1];
                    text_color = player_style ? 12'hDB7 : 12'h9BC;
                end
            end

            if (!text_candidate_valid &&
                (pix_y >= 10'd24) && (pix_y < 10'd40) &&
                (pix_x >= 10'd412) && (pix_x < 10'd492)) begin
                x_offset = pix_x - 10'd412;
                y_offset = pix_y - 10'd24;
                char_index = x_offset[9:4];
                selected_char = hud_lives_char(char_index);
                if (selected_char != " ") begin
                    text_candidate_valid = 1'b1;
                    selected_row = y_offset[4:1];
                    selected_col = x_offset[3:1];
                    text_color = 12'hBDA;
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
                        text_color = 12'h9BC;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd170) && (pix_y < 10'd186) &&
                    (pix_x >= 10'd208) && (pix_x < 10'd432)) begin
                    x_offset = pix_x - 10'd208;
                    y_offset = pix_y - 10'd170;
                    char_index = x_offset[9:4];
                    selected_char = start_line1_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hECD;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd200) && (pix_y < 10'd216) &&
                    (pix_x >= 10'd216) && (pix_x < 10'd424)) begin
                    x_offset = pix_x - 10'd216;
                    y_offset = pix_y - 10'd200;
                    char_index = x_offset[9:4];
                    selected_char = start_line2_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hEDE;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd230) && (pix_y < 10'd246) &&
                    (pix_x >= 10'd224) && (pix_x < 10'd416)) begin
                    x_offset = pix_x - 10'd224;
                    y_offset = pix_y - 10'd230;
                    char_index = x_offset[9:4];
                    selected_char = three_lives_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hECD;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd260) && (pix_y < 10'd276) &&
                    (pix_x >= 10'd232) && (pix_x < 10'd408)) begin
                    x_offset = pix_x - 10'd232;
                    y_offset = pix_y - 10'd260;
                    char_index = x_offset[9:4];
                    selected_char = press_start_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hBDA;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd290) && (pix_y < 10'd306) &&
                    (pix_x >= 10'd264) && (pix_x < 10'd392)) begin
                    x_offset = pix_x - 10'd264;
                    y_offset = pix_y - 10'd290;
                    char_index = x_offset[9:4];
                    selected_char = up_pause_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hDCC;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd320) && (pix_y < 10'd336) &&
                    (pix_x >= 10'd224) && (pix_x < 10'd416)) begin
                    x_offset = pix_x - 10'd224;
                    y_offset = pix_y - 10'd320;
                    char_index = x_offset[9:4];
                    selected_char = down_restart_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hDCC;
                    end
                end
            end

            if (game_state == STATE_TURN_OVER) begin
                if (!text_candidate_valid &&
                    (pix_y >= 10'd140) && (pix_y < 10'd172) &&
                    (pix_x >= 10'd176) && (pix_x < 10'd464)) begin
                    x_offset = pix_x - 10'd176;
                    y_offset = pix_y - 10'd140;
                    char_index = x_offset[9:5];
                    selected_char = turn_banner_char(char_index, player_style);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:2];
                        selected_col = x_offset[4:2];
                        text_color = player_style ? 12'hDB7 : 12'h9BC;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd220) && (pix_y < 10'd236) &&
                    (pix_x >= 10'd224) && (pix_x < 10'd416)) begin
                    x_offset = pix_x - 10'd224;
                    y_offset = pix_y - 10'd220;
                    char_index = x_offset[9:4];
                    selected_char = three_lives_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hECD;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd250) && (pix_y < 10'd266) &&
                    (pix_x >= 10'd232) && (pix_x < 10'd408)) begin
                    x_offset = pix_x - 10'd232;
                    y_offset = pix_y - 10'd250;
                    char_index = x_offset[9:4];
                    selected_char = get_ready_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hBDA;
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
                        text_color = 12'h9BC;
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
                        text_color = 12'hBCD;
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
                        text_color = 12'hDCC;
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
                    selected_char = winner_banner_char(char_index, winner);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:2];
                        selected_col = x_offset[4:2];
                        if (winner == 2'd1) begin
                            text_color = 12'h9BC;
                        end else if (winner == 2'd2) begin
                            text_color = 12'hDB7;
                        end else begin
                            text_color = 12'hFDD;
                        end
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd200) && (pix_y < 10'd216) &&
                    (pix_x >= 10'd256) && (pix_x < 10'd384)) begin
                    x_offset = pix_x - 10'd256;
                    y_offset = pix_y - 10'd200;
                    char_index = x_offset[9:4];
                    selected_char = hud_player1_char(char_index, player1_score_bcd);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'h9BC;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd230) && (pix_y < 10'd246) &&
                    (pix_x >= 10'd256) && (pix_x < 10'd384)) begin
                    x_offset = pix_x - 10'd256;
                    y_offset = pix_y - 10'd230;
                    char_index = x_offset[9:4];
                    selected_char = hud_player2_char(char_index, player2_score_bcd);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hDB7;
                    end
                end

                if (!text_candidate_valid &&
                    (pix_y >= 10'd260) && (pix_y < 10'd276) &&
                    (pix_x >= 10'd232) && (pix_x < 10'd408)) begin
                    x_offset = pix_x - 10'd232;
                    y_offset = pix_y - 10'd260;
                    char_index = x_offset[9:4];
                    selected_char = press_start_char(char_index);
                    if (selected_char != " ") begin
                        text_candidate_valid = 1'b1;
                        selected_row = y_offset[4:1];
                        selected_col = x_offset[3:1];
                        text_color = 12'hECD;
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
                        text_color = 12'hDCC;
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
                        text_color = 12'hD98;
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
                        text_color = 12'hEDE;
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
