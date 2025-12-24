//// M216A_TopModule.v
//// Simple MASH-1-1-1 DDSM implementation (16-bit accumulators, 3-stage cascade).
//// Inputs: int_i[3:0], frac_i[15:0], clk, rst_n (active low).
//// Output: out[3:0]  (int_i + fractional correction in [-3..4])
//// Design choices described in accompanying README / lab doc.
//


`timescale 1ns / 1ps



module M216A_TopModule(

    input  wire [3:0]  in_i,    // Integer input (Range: 3-11)

    input  wire [15:0] in_f,    // Fractional input (Range: 0-65535)

    input  wire        clk,     // 500MHz Clock

    input  wire        rst_n,   // Active low reset

    output wire [3:0]  out      // 4-bit Output

);



    // ==========================================

    // Part 1: The Accumulators (MASH Stages)

    // ==========================================

    

    // Stage 1

    reg [16:0] acc1; // 17-bit to hold 16-bit sum + 1-bit carry

    wire       c1;

    wire [15:0] e1;

    

    assign c1 = acc1[16];      // Carry output

    assign e1 = acc1[15:0];    // Error (Sum) output fed to next stage



    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) 

            acc1 <= 17'd0;

        else 

            acc1 <= e1 + in_f; // Feedback e1 (accumulate) + new input

            // Note: In standard accumulator, next state = current sum + input

            // But here we use strictly registered output. 

            // Logic: acc1_next = acc1[15:0] + in_f

    end



    // Stage 2

    reg [16:0] acc2;

    wire       c2;

    wire [15:0] e2;



    assign c2 = acc2[16];

    assign e2 = acc2[15:0];



    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) 

            acc2 <= 17'd0;

        else 

            acc2 <= e2 + e1; // Input is e1 from Stage 1

    end



    // Stage 3

    reg [16:0] acc3;

    wire       c3;

    wire [15:0] e3;



    assign c3 = acc3[16];

    assign e3 = acc3[15:0]; // e3 connects back to input 'a' internally



    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) 

            acc3 <= 17'd0;

        else 

            acc3 <= e3 + e2; // Input is e2 from Stage 2

    end



    // ==========================================

    // Part 2: Delay Lines & Logic (For Alignment)

    // ==========================================



    // Delays for in_i (Integer input needs z^-2 to match c1 path)

    reg [3:0] in_i_d1, in_i_d2;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            in_i_d1 <= 4'd0;

            in_i_d2 <= 4'd0;

        end else begin

            in_i_d1 <= in_i;

            in_i_d2 <= in_i_d1;

        end

    end



    // Delays for c1 (Needs z^-2)

    reg c1_d1, c1_d2;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            c1_d1 <= 1'b0;

            c1_d2 <= 1'b0;

        end else begin

            c1_d1 <= c1;

            c1_d2 <= c1_d1;

        end

    end



    // Delays for c2 (Needs z^-1 for path, and history for differentiation)

    reg c2_d1, c2_d2;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            c2_d1 <= 1'b0;

            c2_d2 <= 1'b0;

        end else begin

            c2_d1 <= c2;

            c2_d2 <= c2_d1;

        end

    end



    // Delays for c3 (Needs history for double differentiation)

    reg c3_d1, c3_d2;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            c3_d1 <= 1'b0;

            c3_d2 <= 1'b0;

        end else begin

            c3_d1 <= c3;

            c3_d2 <= c3_d1;

        end

    end



    // ==========================================

    // Part 3: Noise Shaping Logic

    // ==========================================

    

    // We use 5-bit signed wires to handle the arithmetic safely.

    // Range needed: -3 to +4. 4-bit signed (-8 to +7) is sufficient,

    // but 5-bit is safer for intermediate carry overflows.

    

    wire signed [4:0] s_c1, s_c2, s_c3;

    

    // 1. Term 1: c1 * z^-2

    // Zero extend c1_d2 to signed

    assign s_c1 = {4'b0, c1_d2}; 



    // 2. Term 2: c2 * z^-1 * (1 - z^-1) = c2_d1 - c2_d2

    assign s_c2 = {4'b0, c2_d1} - {4'b0, c2_d2};



    // 3. Term 3: c3 * (1 - z^-1)^2 = c3 - 2*c3_d1 + c3_d2

    // Note: 2*c3_d1 is just a left shift

    assign s_c3 = {4'b0, c3} - ({4'b0, c3_d1} <<< 1) + {4'b0, c3_d2};



    // Calculate fractional output (out_f)

    wire signed [4:0] out_f;

    assign out_f = s_c1 + s_c2 + s_c3;



    // ==========================================

    // Part 4: Final Output Generation

    // ==========================================

    

    // Final Output = Integer Input (Delayed) + Fractional Output

    // Since in_i is unsigned and out_f is signed, we sign-extend both to prevent issues.

    wire signed [5:0] final_sum;

    assign final_sum = {2'b0, in_i_d2} + out_f; // Zero extend in_i, sign extend out_f logic handles itself

    

    // Assign to 4-bit output (Truncate)

    // Constraint check: 3 <= in_i <= 11. Range of out is safely within 0-15.

    assign out = final_sum[3:0];



endmodule

//module M216A_TopModule (
//    input  wire [3:0]  int_i,   // integer part (3..11 expected)
//    input  wire [15:0] frac_i,  // fractional part (0..65535)
//    input  wire        clk,
//    input  wire        rst_n,   // active low
//    output reg  [3:0]  out
//);
//
//    // 16-bit accumulator states
//    reg [15:0] acc1, acc2, acc3;
//
//    // Combinational sums (17 bits to capture carry)
//    wire [16:0] sum1 = {1'b0, acc1} + {1'b0, frac_i};        // acc1 + frac_i
//    wire [16:0] sum2 = {1'b0, acc2} + {1'b0, sum1[15:0]};    // acc2 + residual of stage1
//    wire [16:0] sum3 = {1'b0, acc3} + {1'b0, sum2[15:0]};    // acc3 + residual of stage2
//
//    // 1-bit quantizer outputs (carries)
//    wire c1 = sum1[16];
//    wire c2 = sum2[16];
//    wire c3 = sum3[16];
//
//    // fractional combiner:
//    // comb_val = 4*c3 + 2*c2 + 1*c1  (0..7)
//    wire [3:0] comb_val = (c3 << 2) + (c2 << 1) + (c1);
//
//    // out_f = comb_val - 3  (range -3 .. +4)
//    // use signed arithmetic for subtraction
//    wire signed [4:0] out_f_signed = $signed({1'b0, comb_val}) - 5'sd3;
//
//    // widen int_i to signed and add (safe because int_i in 3..11 per spec)
//    wire signed [5:0] sum_signed = $signed({2'b00, int_i}) + $signed({1'b0, out_f_signed});
//
//    // update accumulators and output on clock
//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            acc1 <= 16'd0;
//            acc2 <= 16'd0;
//            acc3 <= 16'd0;
//            out  <= 4'd0;
//        end else begin
//            // update accumulators with lower 16 bits (residuals)
//            acc1 <= sum1[15:0];
//            acc2 <= sum2[15:0];
//            acc3 <= sum3[15:0];
//
//            // final 4-bit output (we know the allowed range fits into 4 bits: 0..15)
//            out <= sum_signed[3:0];
//        end
//    end
//
//endmodule



