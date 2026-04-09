module car_dodging_game_top (
    input  wire       clk100mhz,
    input  wire       btn_left,
    input  wire       btn_right,
    input  wire       btn_start,
    input  wire       btn_pause,
    input  wire       btn_restart,
    output wire       vga_hsync,
    output wire       vga_vsync,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b
);

    localparam integer ENEMY_COUNT = 8;
    localparam integer ROAD_X0     = 120;
    localparam integer ROAD_W      = 400;
    localparam integer LANE_W      = 100;
    localparam integer CAR_W       = 54;
    localparam integer CAR_H       = 96;
    localparam integer PLAYER_Y    = 372;

    reg [1:0] pixel_div = 2'd0;
    wire pixel_tick = (pixel_div == 2'd0);

    wire btn_left_level;
    wire btn_right_level;
    wire btn_start_level;
    wire btn_pause_level;
    wire btn_restart_level;

    wire btn_left_pulse;
    wire btn_right_pulse;
    wire btn_start_pulse;
    wire btn_pause_pulse;
    wire btn_restart_pulse;

    wire video_on;
    wire frame_tick;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    wire [2:0] game_state_code;
    wire [1:0] player_lane;
    wire [9:0] player_x;
    wire [9:0] player_y;
    wire [15:0] score;
    wire [15:0] high_score;
    wire [2:0] lives;
    wire [3:0] enemy_speed;
    wire [6:0] spawn_interval;
    wire [5:0] road_scroll;
    wire clear_enemies;
    wire player_visible;
    wire collision;

    wire [ENEMY_COUNT-1:0] enemy_active;
    wire [ENEMY_COUNT*2-1:0] enemy_lane_bus;
    wire [ENEMY_COUNT*10-1:0] enemy_y_bus;
    wire [ENEMY_COUNT*3-1:0] enemy_style_bus;
    wire [3:0] passed_count;

    wire [19:0] score_bcd;
    wire [19:0] high_score_bcd;
    wire [11:0] pixel_rgb;

    always @(posedge clk100mhz) begin
        pixel_div <= pixel_div + 1'b1;
    end

    button_conditioner btn_left_cond (
        .clk(clk100mhz),
        .button_in(btn_left),
        .level(btn_left_level),
        .pressed_pulse(btn_left_pulse)
    );

    button_conditioner btn_right_cond (
        .clk(clk100mhz),
        .button_in(btn_right),
        .level(btn_right_level),
        .pressed_pulse(btn_right_pulse)
    );

    button_conditioner btn_start_cond (
        .clk(clk100mhz),
        .button_in(btn_start),
        .level(btn_start_level),
        .pressed_pulse(btn_start_pulse)
    );

    button_conditioner btn_pause_cond (
        .clk(clk100mhz),
        .button_in(btn_pause),
        .level(btn_pause_level),
        .pressed_pulse(btn_pause_pulse)
    );

    button_conditioner btn_restart_cond (
        .clk(clk100mhz),
        .button_in(btn_restart),
        .level(btn_restart_level),
        .pressed_pulse(btn_restart_pulse)
    );

    vga_sync vga_timing (
        .clk(clk100mhz),
        .pixel_tick(pixel_tick),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .video_on(video_on),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .frame_tick(frame_tick)
    );

    game_state #(
        .LANE_COUNT(4),
        .ROAD_X0(ROAD_X0),
        .LANE_W(LANE_W),
        .CAR_W(CAR_W),
        .DEFAULT_LANE(1),
        .PLAYER_Y(PLAYER_Y)
    ) gameplay (
        .clk(clk100mhz),
        .frame_tick(frame_tick),
        .btn_left_pulse(btn_left_pulse),
        .btn_right_pulse(btn_right_pulse),
        .btn_start_pulse(btn_start_pulse),
        .btn_pause_pulse(btn_pause_pulse),
        .btn_restart_pulse(btn_restart_pulse),
        .passed_count(passed_count),
        .collision(collision),
        .state(game_state_code),
        .player_lane(player_lane),
        .player_x(player_x),
        .player_y(player_y),
        .score(score),
        .high_score(high_score),
        .lives(lives),
        .enemy_speed(enemy_speed),
        .spawn_interval(spawn_interval),
        .road_scroll(road_scroll),
        .clear_enemies(clear_enemies),
        .player_visible(player_visible)
    );

    enemy_controller #(
        .ENEMY_COUNT(ENEMY_COUNT),
        .SCREEN_H(480),
        .HUD_HEIGHT(48),
        .CAR_H(CAR_H)
    ) enemies (
        .clk(clk100mhz),
        .frame_tick(frame_tick),
        .enable(game_state_code == 3'd1),
        .clear_all(clear_enemies),
        .speed(enemy_speed),
        .spawn_interval(spawn_interval),
        .score(score),
        .enemy_active(enemy_active),
        .enemy_lane_bus(enemy_lane_bus),
        .enemy_y_bus(enemy_y_bus),
        .enemy_style_bus(enemy_style_bus),
        .passed_count(passed_count)
    );

    collision_detector #(
        .ENEMY_COUNT(ENEMY_COUNT),
        .ROAD_X0(ROAD_X0),
        .LANE_W(LANE_W),
        .CAR_W(CAR_W),
        .CAR_H(CAR_H),
        .PLAYER_Y(PLAYER_Y)
    ) collisions (
        .player_x(player_x),
        .enemy_active(enemy_active),
        .enemy_lane_bus(enemy_lane_bus),
        .enemy_y_bus(enemy_y_bus),
        .collision(collision)
    );

    bin_to_bcd5 score_conv (
        .binary(score),
        .bcd(score_bcd)
    );

    bin_to_bcd5 high_score_conv (
        .binary(high_score),
        .bcd(high_score_bcd)
    );

    game_renderer #(
        .SCREEN_W(640),
        .SCREEN_H(480),
        .HUD_HEIGHT(48),
        .ROAD_X0(ROAD_X0),
        .ROAD_W(ROAD_W),
        .LANE_W(LANE_W),
        .CAR_W(CAR_W),
        .CAR_H(CAR_H),
        .PLAYER_Y(PLAYER_Y),
        .ENEMY_COUNT(ENEMY_COUNT)
    ) renderer (
        .video_on(video_on),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .game_state(game_state_code),
        .road_scroll(road_scroll),
        .player_x(player_x),
        .player_visible(player_visible),
        .enemy_active(enemy_active),
        .enemy_lane_bus(enemy_lane_bus),
        .enemy_y_bus(enemy_y_bus),
        .enemy_style_bus(enemy_style_bus),
        .score_bcd(score_bcd),
        .high_score_bcd(high_score_bcd),
        .lives(lives),
        .rgb(pixel_rgb)
    );

    assign vga_r = pixel_rgb[11:8];
    assign vga_g = pixel_rgb[7:4];
    assign vga_b = pixel_rgb[3:0];

endmodule
