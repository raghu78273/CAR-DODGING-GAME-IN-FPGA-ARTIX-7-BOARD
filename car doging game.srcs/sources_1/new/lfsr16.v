module lfsr16 (
    input  wire       clk,
    input  wire       advance,
    output wire [15:0] value
);

    reg [15:0] lfsr = 16'h1ACE;
    wire feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];

    always @(posedge clk) begin
        if (advance) begin
            if (lfsr == 16'h0000) begin
                lfsr <= 16'h1ACE;
            end else begin
                lfsr <= {lfsr[14:0], feedback};
            end
        end
    end

    assign value = lfsr;

endmodule
