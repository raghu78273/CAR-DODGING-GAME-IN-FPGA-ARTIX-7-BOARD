module bin_to_bcd5 (
    input  wire [15:0] binary,
    output reg  [19:0] bcd
);

    reg [15:0] remainder;
    reg [3:0] ten_thousands;
    reg [3:0] thousands;
    reg [3:0] hundreds;
    reg [3:0] tens;
    reg [3:0] ones;

    always @* begin
        remainder = binary;

        ten_thousands = remainder / 16'd10000;
        remainder = remainder % 16'd10000;

        thousands = remainder / 16'd1000;
        remainder = remainder % 16'd1000;

        hundreds = remainder / 16'd100;
        remainder = remainder % 16'd100;

        tens = remainder / 16'd10;
        ones = remainder % 16'd10;

        bcd = {ten_thousands, thousands, hundreds, tens, ones};
    end

endmodule
