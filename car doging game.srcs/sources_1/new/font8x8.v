module font8x8 (
    input  wire [7:0] char_code,
    input  wire [2:0] row,
    output reg  [7:0] bits
);

    always @* begin
        bits = 8'h00;

        case (char_code)
            "0": case (row)
                3'd0: bits = 8'h3C;
                3'd1: bits = 8'h66;
                3'd2: bits = 8'h6E;
                3'd3: bits = 8'h76;
                3'd4: bits = 8'h66;
                3'd5: bits = 8'h66;
                3'd6: bits = 8'h3C;
                default: bits = 8'h00;
            endcase
            "1": case (row)
                3'd0: bits = 8'h18;
                3'd1: bits = 8'h38;
                3'd2: bits = 8'h18;
                3'd3: bits = 8'h18;
                3'd4: bits = 8'h18;
                3'd5: bits = 8'h18;
                3'd6: bits = 8'h3C;
                default: bits = 8'h00;
            endcase
            "2": case (row)
                3'd0: bits = 8'h3C;
                3'd1: bits = 8'h66;
                3'd2: bits = 8'h06;
                3'd3: bits = 8'h1C;
                3'd4: bits = 8'h30;
                3'd5: bits = 8'h60;
                3'd6: bits = 8'h7E;
                default: bits = 8'h00;
            endcase
            "3": case (row)
                3'd0: bits = 8'h3C;
                3'd1: bits = 8'h66;
                3'd2: bits = 8'h06;
                3'd3: bits = 8'h1C;
                3'd4: bits = 8'h06;
                3'd5: bits = 8'h66;
                3'd6: bits = 8'h3C;
                default: bits = 8'h00;
            endcase
            "4": case (row)
                3'd0: bits = 8'h0C;
                3'd1: bits = 8'h1C;
                3'd2: bits = 8'h3C;
                3'd3: bits = 8'h6C;
                3'd4: bits = 8'h7E;
                3'd5: bits = 8'h0C;
                3'd6: bits = 8'h0C;
                default: bits = 8'h00;
            endcase
            "5": case (row)
                3'd0: bits = 8'h7E;
                3'd1: bits = 8'h60;
                3'd2: bits = 8'h7C;
                3'd3: bits = 8'h06;
                3'd4: bits = 8'h06;
                3'd5: bits = 8'h66;
                3'd6: bits = 8'h3C;
                default: bits = 8'h00;
            endcase
            "6": case (row)
                3'd0: bits = 8'h1C;
                3'd1: bits = 8'h30;
                3'd2: bits = 8'h60;
                3'd3: bits = 8'h7C;
                3'd4: bits = 8'h66;
                3'd5: bits = 8'h66;
                3'd6: bits = 8'h3C;
                default: bits = 8'h00;
            endcase
            "7": case (row)
                3'd0: bits = 8'h7E;
                3'd1: bits = 8'h06;
                3'd2: bits = 8'h0C;
                3'd3: bits = 8'h18;
                3'd4: bits = 8'h30;
                3'd5: bits = 8'h30;
                3'd6: bits = 8'h30;
                default: bits = 8'h00;
            endcase
            "8": case (row)
                3'd0: bits = 8'h3C;
                3'd1: bits = 8'h66;
                3'd2: bits = 8'h66;
                3'd3: bits = 8'h3C;
                3'd4: bits = 8'h66;
                3'd5: bits = 8'h66;
                3'd6: bits = 8'h3C;
                default: bits = 8'h00;
            endcase
            "9": case (row)
                3'd0: bits = 8'h3C;
                3'd1: bits = 8'h66;
                3'd2: bits = 8'h66;
                3'd3: bits = 8'h3E;
                3'd4: bits = 8'h06;
                3'd5: bits = 8'h0C;
                3'd6: bits = 8'h38;
                default: bits = 8'h00;
            endcase
            "A": case (row)
                3'd0: bits = 8'h18;
                3'd1: bits = 8'h24;
                3'd2: bits = 8'h42;
                3'd3: bits = 8'h42;
                3'd4: bits = 8'h7E;
                3'd5: bits = 8'h42;
                3'd6: bits = 8'h42;
                default: bits = 8'h00;
            endcase
            "B": case (row)
                3'd0: bits = 8'h7C;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h42;
                3'd3: bits = 8'h7C;
                3'd4: bits = 8'h42;
                3'd5: bits = 8'h42;
                3'd6: bits = 8'h7C;
                default: bits = 8'h00;
            endcase
            "C": case (row)
                3'd0: bits = 8'h3C;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h40;
                3'd3: bits = 8'h40;
                3'd4: bits = 8'h40;
                3'd5: bits = 8'h42;
                3'd6: bits = 8'h3C;
                default: bits = 8'h00;
            endcase
            "D": case (row)
                3'd0: bits = 8'h78;
                3'd1: bits = 8'h44;
                3'd2: bits = 8'h42;
                3'd3: bits = 8'h42;
                3'd4: bits = 8'h42;
                3'd5: bits = 8'h44;
                3'd6: bits = 8'h78;
                default: bits = 8'h00;
            endcase
            "E": case (row)
                3'd0: bits = 8'h7E;
                3'd1: bits = 8'h40;
                3'd2: bits = 8'h40;
                3'd3: bits = 8'h7C;
                3'd4: bits = 8'h40;
                3'd5: bits = 8'h40;
                3'd6: bits = 8'h7E;
                default: bits = 8'h00;
            endcase
            "F": case (row)
                3'd0: bits = 8'h7E;
                3'd1: bits = 8'h40;
                3'd2: bits = 8'h40;
                3'd3: bits = 8'h7C;
                3'd4: bits = 8'h40;
                3'd5: bits = 8'h40;
                3'd6: bits = 8'h40;
                default: bits = 8'h00;
            endcase
            "G": case (row)
                3'd0: bits = 8'h3C;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h40;
                3'd3: bits = 8'h4E;
                3'd4: bits = 8'h42;
                3'd5: bits = 8'h42;
                3'd6: bits = 8'h3E;
                default: bits = 8'h00;
            endcase
            "H": case (row)
                3'd0: bits = 8'h42;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h42;
                3'd3: bits = 8'h7E;
                3'd4: bits = 8'h42;
                3'd5: bits = 8'h42;
                3'd6: bits = 8'h42;
                default: bits = 8'h00;
            endcase
            "I": case (row)
                3'd0: bits = 8'h3C;
                3'd1: bits = 8'h18;
                3'd2: bits = 8'h18;
                3'd3: bits = 8'h18;
                3'd4: bits = 8'h18;
                3'd5: bits = 8'h18;
                3'd6: bits = 8'h3C;
                default: bits = 8'h00;
            endcase
            "J": case (row)
                3'd0: bits = 8'h0E;
                3'd1: bits = 8'h04;
                3'd2: bits = 8'h04;
                3'd3: bits = 8'h04;
                3'd4: bits = 8'h44;
                3'd5: bits = 8'h44;
                3'd6: bits = 8'h38;
                default: bits = 8'h00;
            endcase
            "K": case (row)
                3'd0: bits = 8'h42;
                3'd1: bits = 8'h44;
                3'd2: bits = 8'h48;
                3'd3: bits = 8'h70;
                3'd4: bits = 8'h48;
                3'd5: bits = 8'h44;
                3'd6: bits = 8'h42;
                default: bits = 8'h00;
            endcase
            "L": case (row)
                3'd0: bits = 8'h40;
                3'd1: bits = 8'h40;
                3'd2: bits = 8'h40;
                3'd3: bits = 8'h40;
                3'd4: bits = 8'h40;
                3'd5: bits = 8'h40;
                3'd6: bits = 8'h7E;
                default: bits = 8'h00;
            endcase
            "M": case (row)
                3'd0: bits = 8'h42;
                3'd1: bits = 8'h66;
                3'd2: bits = 8'h5A;
                3'd3: bits = 8'h5A;
                3'd4: bits = 8'h42;
                3'd5: bits = 8'h42;
                3'd6: bits = 8'h42;
                default: bits = 8'h00;
            endcase
            "N": case (row)
                3'd0: bits = 8'h42;
                3'd1: bits = 8'h62;
                3'd2: bits = 8'h52;
                3'd3: bits = 8'h4A;
                3'd4: bits = 8'h46;
                3'd5: bits = 8'h42;
                3'd6: bits = 8'h42;
                default: bits = 8'h00;
            endcase
            "O": case (row)
                3'd0: bits = 8'h3C;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h42;
                3'd3: bits = 8'h42;
                3'd4: bits = 8'h42;
                3'd5: bits = 8'h42;
                3'd6: bits = 8'h3C;
                default: bits = 8'h00;
            endcase
            "P": case (row)
                3'd0: bits = 8'h7C;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h42;
                3'd3: bits = 8'h7C;
                3'd4: bits = 8'h40;
                3'd5: bits = 8'h40;
                3'd6: bits = 8'h40;
                default: bits = 8'h00;
            endcase
            "Q": case (row)
                3'd0: bits = 8'h3C;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h42;
                3'd3: bits = 8'h42;
                3'd4: bits = 8'h4A;
                3'd5: bits = 8'h44;
                3'd6: bits = 8'h3A;
                default: bits = 8'h00;
            endcase
            "R": case (row)
                3'd0: bits = 8'h7C;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h42;
                3'd3: bits = 8'h7C;
                3'd4: bits = 8'h48;
                3'd5: bits = 8'h44;
                3'd6: bits = 8'h42;
                default: bits = 8'h00;
            endcase
            "S": case (row)
                3'd0: bits = 8'h3C;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h40;
                3'd3: bits = 8'h3C;
                3'd4: bits = 8'h02;
                3'd5: bits = 8'h42;
                3'd6: bits = 8'h3C;
                default: bits = 8'h00;
            endcase
            "T": case (row)
                3'd0: bits = 8'h7E;
                3'd1: bits = 8'h18;
                3'd2: bits = 8'h18;
                3'd3: bits = 8'h18;
                3'd4: bits = 8'h18;
                3'd5: bits = 8'h18;
                3'd6: bits = 8'h18;
                default: bits = 8'h00;
            endcase
            "U": case (row)
                3'd0: bits = 8'h42;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h42;
                3'd3: bits = 8'h42;
                3'd4: bits = 8'h42;
                3'd5: bits = 8'h42;
                3'd6: bits = 8'h3C;
                default: bits = 8'h00;
            endcase
            "V": case (row)
                3'd0: bits = 8'h42;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h42;
                3'd3: bits = 8'h42;
                3'd4: bits = 8'h42;
                3'd5: bits = 8'h24;
                3'd6: bits = 8'h18;
                default: bits = 8'h00;
            endcase
            "W": case (row)
                3'd0: bits = 8'h42;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h42;
                3'd3: bits = 8'h5A;
                3'd4: bits = 8'h5A;
                3'd5: bits = 8'h66;
                3'd6: bits = 8'h42;
                default: bits = 8'h00;
            endcase
            "X": case (row)
                3'd0: bits = 8'h42;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h24;
                3'd3: bits = 8'h18;
                3'd4: bits = 8'h24;
                3'd5: bits = 8'h42;
                3'd6: bits = 8'h42;
                default: bits = 8'h00;
            endcase
            "Y": case (row)
                3'd0: bits = 8'h42;
                3'd1: bits = 8'h42;
                3'd2: bits = 8'h24;
                3'd3: bits = 8'h18;
                3'd4: bits = 8'h18;
                3'd5: bits = 8'h18;
                3'd6: bits = 8'h18;
                default: bits = 8'h00;
            endcase
            "Z": case (row)
                3'd0: bits = 8'h7E;
                3'd1: bits = 8'h02;
                3'd2: bits = 8'h04;
                3'd3: bits = 8'h18;
                3'd4: bits = 8'h20;
                3'd5: bits = 8'h40;
                3'd6: bits = 8'h7E;
                default: bits = 8'h00;
            endcase
            ":": case (row)
                3'd1: bits = 8'h18;
                3'd2: bits = 8'h18;
                3'd4: bits = 8'h18;
                3'd5: bits = 8'h18;
                default: bits = 8'h00;
            endcase
            "-": case (row)
                3'd3: bits = 8'h3C;
                default: bits = 8'h00;
            endcase
            default: bits = 8'h00;
        endcase
    end

endmodule
