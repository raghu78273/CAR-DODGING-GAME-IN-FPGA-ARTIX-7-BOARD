module bin_to_bcd5 (
    input  wire [15:0] binary,
    output reg  [19:0] bcd
);

    integer i;
    reg [35:0] shift_reg;

    always @* begin
        shift_reg = 36'd0;
        shift_reg[15:0] = binary;

        for (i = 0; i < 16; i = i + 1) begin
            if (shift_reg[19:16] >= 5) shift_reg[19:16] = shift_reg[19:16] + 3;
            if (shift_reg[23:20] >= 5) shift_reg[23:20] = shift_reg[23:20] + 3;
            if (shift_reg[27:24] >= 5) shift_reg[27:24] = shift_reg[27:24] + 3;
            if (shift_reg[31:28] >= 5) shift_reg[31:28] = shift_reg[31:28] + 3;
            if (shift_reg[35:32] >= 5) shift_reg[35:32] = shift_reg[35:32] + 3;
            shift_reg = shift_reg << 1;
        end

        bcd = shift_reg[35:16];
    end

endmodule
