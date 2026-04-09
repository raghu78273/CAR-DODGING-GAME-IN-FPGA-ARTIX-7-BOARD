module collision_detector #(
    parameter integer ENEMY_COUNT = 8,
    parameter integer ROAD_X0     = 120,
    parameter integer LANE_W      = 100,
    parameter integer CAR_W       = 54,
    parameter integer CAR_H       = 96,
    parameter integer PLAYER_Y    = 372
) (
    input  wire [9:0] player_x,
    input  wire [ENEMY_COUNT-1:0] enemy_active,
    input  wire [ENEMY_COUNT*2-1:0] enemy_lane_bus,
    input  wire [ENEMY_COUNT*10-1:0] enemy_y_bus,
    output reg  collision
);

    integer i;
    reg [9:0] enemy_x;
    reg [9:0] enemy_y;
    reg [9:0] player_left;
    reg [9:0] player_right;
    reg [9:0] player_top;
    reg [9:0] player_bottom;
    reg [9:0] enemy_left;
    reg [9:0] enemy_right;
    reg [9:0] enemy_top;
    reg [9:0] enemy_bottom;

    function [9:0] lane_to_x;
        input [1:0] lane;
        begin
            lane_to_x = ROAD_X0 + (lane * LANE_W) + ((LANE_W - CAR_W) >> 1);
        end
    endfunction

    always @* begin
        collision    = 1'b0;
        player_left  = player_x + 10'd6;
        player_right = player_x + CAR_W - 10'd7;
        player_top   = PLAYER_Y + 10'd10;
        player_bottom = PLAYER_Y + CAR_H - 10'd10;

        for (i = 0; i < ENEMY_COUNT; i = i + 1) begin
            enemy_y = enemy_y_bus[(i * 10) +: 10];
            enemy_x = lane_to_x(enemy_lane_bus[(i * 2) +: 2]);

            enemy_left   = enemy_x + 10'd6;
            enemy_right  = enemy_x + CAR_W - 10'd7;
            enemy_top    = enemy_y + 10'd10;
            enemy_bottom = enemy_y + CAR_H - 10'd10;

            if (enemy_active[i] &&
                (player_left <= enemy_right) &&
                (player_right >= enemy_left) &&
                (player_top <= enemy_bottom) &&
                (player_bottom >= enemy_top)) begin
                collision = 1'b1;
            end
        end
    end

endmodule
