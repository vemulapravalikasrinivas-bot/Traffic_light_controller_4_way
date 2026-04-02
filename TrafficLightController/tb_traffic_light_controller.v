// ============================================================
// Testbench: traffic_light_controller
// Covers  : reset, normal cycling, NS ped request, EW ped request
// Tool    : Icarus Verilog  →  iverilog + vvp
// ============================================================

`timescale 1ns/1ps

module tb_traffic_light_controller;

    reg  clk, reset;
    reg  ped_ns_req, ped_ew_req;

    wire ns_red, ns_yellow, ns_green, ns_ped_walk;
    wire ew_red, ew_yellow, ew_green, ew_ped_walk;

    
    traffic_light_controller #(
        .GREEN_TIME (6),    // shorter times for faster simulation
        .YELLOW_TIME(3),
        .PED_TIME   (4)
    ) dut (
        .clk        (clk),
        .reset      (reset),
        .ped_ns_req (ped_ns_req),
        .ped_ew_req (ped_ew_req),
        .ns_red     (ns_red),
        .ns_yellow  (ns_yellow),
        .ns_green   (ns_green),
        .ns_ped_walk(ns_ped_walk),
        .ew_red     (ew_red),
        .ew_yellow  (ew_yellow),
        .ew_green   (ew_green),
        .ew_ped_walk(ew_ped_walk)
    );

    // CLOCK GENERATION
    initial clk = 0;
    always #5 clk = ~clk;   // 10ns period = 100MHz

   

    task show_state;
        begin
            $write("T=%0t | NS: ", $time);
            if (ns_green)    $write("GREEN    ");
            if (ns_yellow)   $write("YELLOW   ");
            if (ns_red)      $write("RED      ");
            if (ns_ped_walk) $write("PED_WALK ");
            $write("| EW: ");
            if (ew_green)    $write("GREEN    ");
            if (ew_yellow)   $write("YELLOW   ");
            if (ew_red)      $write("RED      ");
            if (ew_ped_walk) $write("PED_WALK ");
            $display("");
        end
    endtask

    // NS and EW should NEVER both be green at the same time
    task check_safety;
        begin
            if (ns_green && ew_green) begin
                $display("SAFETY VIOLATION at T=%0t: NS and EW both GREEN!", $time);
                $finish;
            end
            if (ns_ped_walk && ew_green) begin
                $display("SAFETY VIOLATION at T=%0t: NS pedestrian while EW GREEN!", $time);
                $finish;
            end
            if (ew_ped_walk && ns_green) begin
                $display("SAFETY VIOLATION at T=%0t: EW pedestrian while NS GREEN!", $time);
                $finish;
            end
        end
    endtask


    always @(posedge clk) begin
        show_state;
        check_safety;
    end

  
    initial begin
        // Reset 
        $display("\n=== TEST 1: Reset ===");
        reset = 1; ped_ns_req = 0; ped_ew_req = 0;
        repeat(3) @(posedge clk);
        reset = 0;

        // Normal cycle (no pedestrian) 
        $display("\n=== TEST 2: Normal Cycle (no pedestrian requests) ===");
        ped_ns_req = 0; ped_ew_req = 0;
        repeat(40) @(posedge clk);

        // NS Pedestrian Request 
        $display("\n=== TEST 3: NS Pedestrian Request ===");
        ped_ns_req = 1;
        repeat(20) @(posedge clk);
        ped_ns_req = 0;
        repeat(20) @(posedge clk);

        // EW Pedestrian Request 
        $display("\n=== TEST 4: EW Pedestrian Request ===");
        ped_ew_req = 1;
        repeat(20) @(posedge clk);
        ped_ew_req = 0;
        repeat(20) @(posedge clk);

        // Both Pedestrian Requests simultaneously 
        $display("\n=== TEST 5: Both Pedestrian Requests ===");
        ped_ns_req = 1; ped_ew_req = 1;
        repeat(60) @(posedge clk);
        ped_ns_req = 0; ped_ew_req = 0;

        $display("\n=== ALL TESTS PASSED - No Safety Violations ===");
        $finish;
    end

endmodule
