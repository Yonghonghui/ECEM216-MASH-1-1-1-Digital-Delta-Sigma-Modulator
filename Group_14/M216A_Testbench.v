`timescale 1ns / 1ps

module M216A_Testbench;

    // Inputs
    reg [3:0] in_i;
    reg [15:0] in_f;
    reg clk;
    reg rst_n;

    // Outputs
    wire [3:0] out;

    // Instantiate the Unit Under Test (UUT)
    M216A_TopModule uut (
        .in_i(in_i), 
        .in_f(in_f), 
        .clk(clk), 
        .rst_n(rst_n), 
        .out(out)
    );

    // Clock Generation: 500MHz -> Period = 2ns
    initial begin
        clk = 0;
        forever #1 clk = ~clk; // Toggle every 1ns
    end

    // Simulation Variables
    integer i;
    real sum_out;
    real average_out;
    real expected_val;

    initial begin
        // 1. Initialize Inputs
        in_i = 0;
        in_f = 0;
        rst_n = 0; // Assert Reset
        sum_out = 0;

        // 2. Apply Reset
        #10;
        rst_n = 1; // De-assert Reset
        #10;

        // 3. Apply Test Vectors (From Project Document)
        // in_i = 8, in_f = 32000
        // Expected Average = 8 + 32000/65535 = 8.488288
        in_i = 4'd8;
        in_f = 16'd32000;
        
        $display("--------------------------------------------------");
        $display("Starting Simulation: MASH-111 Delta-Sigma Modulator");
        $display("Input Integer: %d", in_i);
        $display("Input Fractional: %d", in_f);
        $display("Target Average: 8.488288");
        $display("--------------------------------------------------");

        // 4. Wait for pipeline to fill (a few cycles)
        #20;

        // 5. Collect Data for 2000 Clock Cycles
        for (i = 0; i < 2000; i = i + 1) begin
            @(posedge clk); 
            // Add current output to sum (Wait small delay to capture stable output after clock edge)
            #0.1 sum_out = sum_out + out;
            
            // Optional: Print first few samples to see the toggling
            if (i < 10) begin
                $display("Time: %t | Cycle: %d | Output: %d", $time, i, out);
            end
        end

        // 6. Calculate and Report Results
        average_out = sum_out / 2000.0;
        expected_val = 8.0 + (32000.0 / 65535.0);

        $display("--------------------------------------------------");
        $display("Simulation Complete (2000 Cycles)");
        $display("Average Output: %f", average_out);
        $display("Expected Value: %f", expected_val);
        $display("Error: %f", average_out - expected_val);
        $display("--------------------------------------------------");
        
        // Basic check for pass/fail (Allowing small error due to finite simulation time)
        if ((average_out > 8.48) && (average_out < 8.50))
            $display("TEST PASSED: Average is within expected range.");
        else
            $display("TEST FAILED: Average is off.");

        $finish;
    end
      
endmodule