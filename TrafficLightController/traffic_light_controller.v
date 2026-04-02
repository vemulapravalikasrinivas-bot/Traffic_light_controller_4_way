module traffic_light_controller #(
    parameter GREEN_TIME  = 10,   // clock cycles for GREEN
    parameter YELLOW_TIME = 3,    // clock cycles for YELLOW
    parameter PED_TIME    = 5     // clock cycles for PEDESTRIAN WALK
)(
    input  wire clk,
    input  wire reset,
    input  wire ped_ns_req,   // pedestrian crossing request on NS road
    input  wire ped_ew_req,   // pedestrian crossing request on EW road

    // NS road outputs (3-bit: RED, YELLOW, GREEN)
    output reg ns_red,
    output reg ns_yellow,
    output reg ns_green,
    output reg ns_ped_walk,   // pedestrian walk signal for NS

    // EW road outputs
    output reg ew_red,
    output reg ew_yellow,
    output reg ew_green,
    output reg ew_ped_walk    // pedestrian walk signal for EW
);

    
   parameter [3:0]
        NS_GREEN    = 4'd0,   // NS green,  EW red
        NS_YELLOW   = 4'd1,   // NS yellow, EW red
        NS_PED      = 4'd2,   // NS pedestrian walk, EW red
        EW_GREEN    = 4'd3,   // EW green,  NS red
        EW_YELLOW   = 4'd4,   // EW yellow, NS red
        EW_PED      = 4'd5;   // EW pedestrian walk, NS red

    reg [3:0] state, next_state;

     reg [5:0] timer;          // counts clock cycles in each state
    wire timer_done;

      reg [5:0] timer_limit;
    always @(*) begin
        case(state)
            NS_GREEN  : timer_limit = GREEN_TIME;
            NS_YELLOW : timer_limit = YELLOW_TIME;
            NS_PED    : timer_limit = PED_TIME;
            EW_GREEN  : timer_limit = GREEN_TIME;
            EW_YELLOW : timer_limit = YELLOW_TIME;
            EW_PED    : timer_limit = PED_TIME;
            default   : timer_limit = GREEN_TIME;
        endcase
    end

    assign timer_done = (timer >= timer_limit - 1);

      always @(posedge clk) begin
        if (reset)
            timer <= 0;
        else if (timer_done)
            timer <= 0;         // reset timer on state change
        else
            timer <= timer + 1;
    end

 
    always @(posedge clk) begin
        if (reset)
            state <= NS_GREEN;
        else if (timer_done)
            state <= next_state;
    end

    // NEXT STATE LOGIC 
    always @(*) begin
        case(state)
            NS_GREEN  : begin
                            // If pedestrian requests crossing on NS, go to NS_PED
                            // else go straight to NS_YELLOW
                            if (ped_ns_req)
                                next_state = NS_YELLOW; // yellow before ped
                            else
                                next_state = NS_YELLOW;
                        end
            NS_YELLOW : next_state = (ped_ns_req) ? NS_PED : EW_GREEN;
            NS_PED    : next_state = EW_GREEN;
            EW_GREEN  : next_state = EW_YELLOW;
            EW_YELLOW : next_state = (ped_ew_req) ? EW_PED : NS_GREEN;
            EW_PED    : next_state = NS_GREEN;
            default   : next_state = NS_GREEN;
        endcase
    end

    // OUTPUT LOGIC 
    always @(*) begin
        // Default all off
        ns_red = 0; ns_yellow = 0; ns_green = 0; ns_ped_walk = 0;
        ew_red = 0; ew_yellow = 0; ew_green = 0; ew_ped_walk = 0;

        case(state)
            NS_GREEN  : begin
                            ns_green  = 1;
                            ew_red    = 1;
                        end
            NS_YELLOW : begin
                            ns_yellow = 1;
                            ew_red    = 1;
                        end
            NS_PED    : begin
                            ns_ped_walk = 1;
                            ew_red      = 1;
                        end
            EW_GREEN  : begin
                            ew_green  = 1;
                            ns_red    = 1;
                        end
            EW_YELLOW : begin
                            ew_yellow = 1;
                            ns_red    = 1;
                        end
            EW_PED    : begin
                            ew_ped_walk = 1;
                            ns_red      = 1;
                        end
            default   : begin
                            ns_red = 1;
                            ew_red = 1;
                        end
        endcase
    end

endmodule
