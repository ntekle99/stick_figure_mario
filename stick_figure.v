`timescale 1ns / 1ps//////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:15:38 12/14/2017 
// Design Name: 
// Module Name:    vgaBitChange 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
// Date: 04/04/2020
// Author: Yue (Julien) Niu
// Description: Port from NEXYS3 to NEXYS4
//////////////////////////////////////////////////////////////////////////////////
module vga_bitchange(
	input clk,
    input reset,
	input bright,
	input up,down,left,right,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [15:0] score
   );
	
	parameter BLACK = 12'b1111_1111_1111;
	parameter true_white = 12'b0000_0000_0000; 
	parameter WHITE = 12'b1110_1010_0111; //used
	parameter RED   = 12'b0111_0101_0000; //used
	parameter BLUE = 12'b0001_1001_0110; //used
	parameter CYAN = 12'b1001_1111_1010;
	parameter GREEN = 12'b0000_1111_0000;
	parameter FLOOR = 10'd350;

	parameter LVL1_PIT1_VISUAL_START = 10'd500;
    parameter LVL1_PIT1_VISUAL_END = 10'd550;

	parameter LVL1_PIT1_START = LVL1_PIT1_VISUAL_START - 10'd5;
    parameter LVL1_PIT1_END = LVL1_PIT1_VISUAL_END - 10'd12;
    
	parameter LVL2_PIT1_VISUAL_START = 10'd450;
    parameter LVL2_PIT1_VISUAL_END = 10'd500;

	parameter LVL2_PIT1_START = LVL2_PIT1_VISUAL_START - 10'd5;
    parameter LVL2_PIT1_END = LVL2_PIT1_VISUAL_END - 10'd12;
    
	parameter LVL2_PIT2_VISUAL_START = 10'd600;
    parameter LVL2_PIT2_VISUAL_END = 10'd650;

	parameter LVL2_PIT2_START = LVL2_PIT2_VISUAL_START - 10'd5;
    parameter LVL2_PIT2_END = LVL2_PIT2_VISUAL_END - 10'd12;
    
    parameter LVL3_PIT1_VISUAL_START= 10'd600;
    parameter LVL3_PIT1_VISUAL_END= 10'd650;
    
    parameter LVL3_PIT1_START = LVL3_PIT1_VISUAL_START - 10'd5;
    parameter LVL3_PIT1_END = LVL3_PIT1_VISUAL_END - 10'd12;
    
    parameter LVL4_PIT1_VISUAL_START= 10'd255; // olf 255
    parameter LVL4_PIT1_VISUAL_END= 10'd295; // old 295
    
    parameter LVL4_PIT1_END=LVL4_PIT1_VISUAL_END-10'd12;
    parameter LVL4_PIT1_START=LVL4_PIT1_VISUAL_START-10'd5;
    
    parameter LVL4_PIT2_VISUAL_START = 10'd500;
    parameter LVL4_PIT2_VISUAL_END = 10'd550;

    parameter LVL4_PIT2_END=LVL4_PIT2_VISUAL_END-10'd12;
    parameter LVL4_PIT2_START=LVL4_PIT2_VISUAL_START-10'd5;   
    



	//parameter BLUE = 12'b0000_0000_1111;

	wire whiteZone;
	wire Blue_zone;
	wire Cyan_zone;
	wire Cyan_zone_2;
	wire black_char;
	reg[9:0] black_char_y;
	reg[49:0] black_char_speed; 
	reg[9:0] black_char_x;
    reg[13:0] clock_counter;
    reg[9:0] pit_counter_1;
    reg[9:0] pit_counter_2;
    reg[9:0] spike_counter;
    reg[1:0] airborne;
    reg[5:0] animation_state;
    reg[1:0] facing_right;
    reg[9:0] door_counter;
    
    reg[1:0] about_to_land;

    // store as twos complement
    reg [3:0] y_speed;
    reg [1:0] walking_animation_cycle; 
    reg[31:0] blackout_timer;
    reg blackout_condition;
    
    reg[10:0] level_state;
    
    reg[1:0] in_a_pit;
    reg[9:0] spike_1_x;
    reg[9:0] spike_1_y;
    reg dead;
    reg spike_moving;
    
    
    localparam 
        LVL_START = 11'b00000000001,
        LVL_1 = 11'b00000000010,
        LVL_2 = 11'b00000000100,
        LVL_3 = 11'b00000001000,
        LVL_4 = 11'b00000010000,
        LVL_5 = 11'b00000100000,
        LVL_6 = 11'b00001000000,
        LVL_7 = 11'b00010000000,
        LVL_8 = 11'b00100000000,
        LVL_9 = 11'b01000000000,
        LVL_END = 11'b10000000000;
    

	initial begin
	    walking_animation_cycle <= 2'b00;
	    facing_right <= 1'd1;
	    animation_state <= 6'b000001;
		black_char_y <= 10'd350;
		score <= 15'd0;
		black_char_x <= 10'd300;
		y_speed <= 4'b0;
		airborne<= 1'b0;
		about_to_land <= 1'b1;
		
		pit_counter_1 <= 10'd0;
		pit_counter_2 <= 10'd0;
		
		level_state <= LVL_1;
        in_a_pit <= 0;
        spike_1_x <= 10'd400;
        spike_1_y <= FLOOR;
        
        door_counter <= 10'd0;
        blackout_condition <= 1'b0;

        dead <= 1'b0;
        spike_moving <= 1'b0;
        spike_counter <= 10'b0;
        end
	
	
	always@ (*) // paint a white box on a red background
	begin

    if (level_state == LVL_START)
		rgb = BLACK; // force black if not bright

 	else if (standing_animation == 1  && animation_state == 6'b000001)
	   rgb = BLACK;
	
	else if (walking_1_animation_right == 1  && animation_state == 6'b000010 && facing_right == 1)
	   rgb = BLACK;
	
 	else if (walking_1_animation_left == 1  && animation_state == 6'b000010 && facing_right == 0)
	   rgb = BLACK;
	
	else if (walking_2_animation_right == 1  && animation_state == 6'b000100 && facing_right == 1)
	   rgb = BLACK;
 	else if (walking_2_animation_left == 1  && animation_state == 6'b000100 && facing_right == 0)
	   rgb = BLACK;
	 
	else if (walking_3_animation_right == 1  && animation_state == 6'b001000 && facing_right == 1)
	   rgb = BLACK;
 	else if (walking_3_animation_left == 1  && animation_state == 6'b001000 && facing_right == 0)
	   rgb = BLACK;

	else if (jumping_animation_right == 1  && (animation_state == 6'b100000||animation_state == 6'b010000) && facing_right == 1)
	   rgb = BLACK;
	   
    else if (jumping_animation_left == 1  && (animation_state == 6'b100000||animation_state == 6'b010000) && facing_right == 0)
	   rgb = BLACK;
	   
	   
    else if(spike_1 && (level_state==LVL_3 || level_state==LVL_4))
          rgb = BLACK;

    else if (Cyan_zone == 1 && blackout_condition == 0) 
        rgb = CYAN;
    else if (Cyan_zone_2 == 1 && blackout_condition == 0) 
        rgb = CYAN;
    else if (whiteZone == 1 && blackout_condition == 0) 
        rgb = WHITE; // white box
    else if (All_Pits == 1 && blackout_condition == 0) 
        rgb = BLUE;
    else if (blackout_condition)
        rgb = BLACK;
    else
        rgb = RED; 
        
    end



	always@(posedge clk, posedge reset) 
		begin
		
			if(reset)
			begin 
                y_speed <= 4'b0; // Reset y_speed
                black_char_y <= 10'd350;
		        black_char_x <= 10'd300;
		        airborne <= 1'b0;
		        animation_state <= 6'b000001;
	            facing_right <= 1'd1;
	            walking_animation_cycle <= 2'b00;
                pit_counter_1<=0;
                pit_counter_2<=0;
                in_a_pit <= 0;
                level_state <= LVL_START;
                door_counter <= 0;
                dead <= 1'b0;
                spike_moving <= 1'b0;
                spike_counter <= 10'b0;
				//rough values for center of screen
			end
			else if (clk) begin 
			
                 if(level_state == LVL_START) begin
                        // if(left||right||up) begin
                        level_state <= LVL_1;
                         
                        y_speed <= 4'b0; // Reset y_speed
                        black_char_y <= 10'd350;
                        black_char_x <= 10'd300;
                        airborne <= 1'b0;
                        animation_state <= 6'b000001;
                        facing_right <= 1'd1;
                        walking_animation_cycle <= 2'b00;
                        pit_counter_1=0;
                        pit_counter_2=0;
                        in_a_pit <= 0;
                        dead <= 1'b0;
                        spike_counter <= 10'b0;

                       //  end
                 end
                 
                 if(blackout_timer >= 50) begin
                     if(level_state == LVL_1)begin
                        level_state <= LVL_2;
                        end
                     else if(level_state == LVL_2) begin
                        level_state <=LVL_3;
                        end
                     else if(level_state == LVL_3) begin
                         level_state <=LVL_4;
                       end
                       else if(level_state == LVL_4) begin
                         level_state <=LVL_START;
                       end
                            blackout_timer <= 0;
                            door_counter <= 0;
                            y_speed <= 4'b0; // Reset y_speed
                            black_char_y <= 10'd350;
                            black_char_x <= 10'd300;
                            airborne <= 1'b0;
                            animation_state <= 6'b000001;
                            facing_right <= 1'd1;
                            walking_animation_cycle <= 2'b00;
                            pit_counter_1=0;
                            pit_counter_2=0;
                            
                            in_a_pit <= 0;
                            dead <= 1'b0;
                            spike_moving <= 1'b0;
                            spike_counter <= 10'b0;


                            end
                 
                 if(level_state == LVL_1) begin
                 
                    
                     // Handle pits
                     if ((black_char_x > LVL1_PIT1_VISUAL_START-10'd55) && (clock_counter %3==0) && (pit_counter_1!=200)) begin
                            pit_counter_1 <= pit_counter_1 + 20;
                     end
                     
                     //Handle movement
                     if(right && (((black_char_x + 10'd3 >= LVL1_PIT1_END) && (black_char_y > FLOOR)) == 0) && (black_char_x < 10'd730) && door_counter == 0)
                        black_char_x<=black_char_x+10'd2; 
                     else if (left && (((black_char_x - 10'd3 <= LVL1_PIT1_START) && (black_char_y > FLOOR)) == 0) && (black_char_x > 10'd250) && door_counter == 0)
                        black_char_x<=black_char_x-10'd2; 
                        
                     //check if you're in a put for later logic
                     if((black_char_x > LVL1_PIT1_START) && (black_char_x < LVL1_PIT1_END))
                        in_a_pit <= 1;
                     else
                        in_a_pit <= 0;
                     // state transitoon including setting everyone up
                     
                  
                     //
                 end
                 
                 
                 if(level_state == LVL_2) begin
                        
                     // handle pits
                     if ((black_char_x > LVL2_PIT1_VISUAL_START-10'd40) && (clock_counter %3==0) && (pit_counter_1!=200)) begin
                            pit_counter_1 <= pit_counter_1 + 20;
                        end
                     else if ((black_char_x > LVL2_PIT2_VISUAL_START-10'd40) && (clock_counter %3==0) && (pit_counter_2!=200)) begin
                            pit_counter_2 <= pit_counter_2 + 20;
                     end
                     
                     //Handle movement
                     if(right && (((((black_char_x + 10'd3 >= LVL2_PIT1_END) && (black_char_x  < LVL2_PIT1_END + 10'd7) )||(black_char_x + 10'd3 >= LVL2_PIT2_END)) && (black_char_y > FLOOR)) == 0) && (black_char_x < 10'd730) && door_counter == 0)
                        black_char_x<=black_char_x+10'd2; 
                     else if (left && ((((black_char_x - 10'd3 <= LVL2_PIT1_START) || ((black_char_x - 10'd3 <= LVL2_PIT2_START) && (black_char_x - 10'd7 > LVL2_PIT2_START))) && (black_char_y > FLOOR)) == 0) && (black_char_x > 10'd250) && door_counter == 0)
                        black_char_x<=black_char_x-10'd2; 
                     
                     if(((black_char_x > LVL2_PIT1_START) && (black_char_x < LVL2_PIT1_END)) || ((black_char_x > LVL2_PIT2_START) && (black_char_x < LVL2_PIT2_END)))
                        in_a_pit <= 1;
                     else
                        in_a_pit <= 0;
                     
                          
                 end
                 
                 if(level_state == LVL_3) begin
                        if ((black_char_x > LVL3_PIT1_VISUAL_START-10'd40) && (clock_counter %3==0) && (pit_counter_1!=200)) begin
                            pit_counter_1 <= pit_counter_1 + 20;
                        end
                       if ((black_char_x < spike_1_x + 10'd34) && (black_char_x > spike_1_x - 10'd13) &&(black_char_y<=FLOOR && black_char_y >= FLOOR - 4'd4) ) begin
                            blackout_timer <= 0;
                            door_counter <= 0;
                            y_speed <= 4'b0; // Reset y_speed
                            black_char_y <= 10'd350;
                            black_char_x <= 10'd300;
                            airborne <= 1'b0;
                            animation_state <= 6'b000001;
                            facing_right <= 1'd1;
                            walking_animation_cycle <= 2'b00;
                            pit_counter_1=0;
                            pit_counter_2=0;
                            dead <= 1'b0;
                            spike_moving <= 1'b0;
                            spike_counter <= 10'b0;
                            
                        end
                     
                     //Handle movement
                     else if(right && (((black_char_x + 10'd3 >= LVL3_PIT1_END) && (black_char_y > FLOOR)) == 0) && (black_char_x < 10'd730) && door_counter == 0)
                        black_char_x<=black_char_x+10'd2; 
                     else if (left && (((black_char_x - 10'd3 <= LVL3_PIT1_START) && (black_char_y > FLOOR)) == 0) && (black_char_x > 10'd250) && door_counter == 0)
                        black_char_x<=black_char_x-10'd2; 
                        
                     //check if you're in a put for later logic
                     if((black_char_x > LVL3_PIT1_START) && (black_char_x < LVL3_PIT1_END))
                        in_a_pit <= 1;
                     else
                        in_a_pit <= 0;
                 
                      
                 
                 end
                 if(level_state == LVL_4) begin
                 
                        if ((black_char_x > LVL4_PIT1_VISUAL_START-10'd40) && (clock_counter %3==0) && (pit_counter_1!=200)) begin
                            pit_counter_1 <= pit_counter_1 + 20;
                        end
                        
                        if ((((black_char_x > spike_1_x -10'd42)||(spike_moving)) && (spike_counter < 12))) begin
                            spike_counter <= spike_counter + 1;
                            spike_1_x <= spike_1_x + 10'd2;
                            spike_moving <= 1;
                            if (spike_counter == 11)
                                spike_moving <= 0;
                        end
                        
                       if ((black_char_x < spike_1_x + 10'd34) && (black_char_x > spike_1_x - 10'd13) &&(black_char_y<=FLOOR && black_char_y >= FLOOR - 4'd4) ) begin
                            blackout_timer <= 0;
                            door_counter <= 0;
                            y_speed <= 4'b0; // Reset y_speed
                            black_char_y <= 10'd350;
                            black_char_x <= 10'd300;
                            airborne <= 1'b0;
                            animation_state <= 6'b000001;
                            facing_right <= 1'd1;
                            walking_animation_cycle <= 2'b00;
                            pit_counter_1=0;
                            pit_counter_2=0;
                            dead <= 1'b0;
                            spike_moving <= 1'b0; 
                            spike_1_x <= 10'd400;
                            spike_counter <= 10'b0;

                        end
                     
                     
                     //Handle movement
                     else if(right && (((black_char_x + 10'd3 >= LVL4_PIT1_END) && (black_char_y > FLOOR)) == 0) && (black_char_x < 10'd730) && door_counter == 0)
                        black_char_x<=black_char_x+10'd2; 
                     else if (left && (((black_char_x - 10'd3 <= LVL4_PIT1_START) && (black_char_y > FLOOR)) == 0) && (black_char_x > 10'd250) && door_counter == 0)
                        black_char_x<=black_char_x-10'd2; 
                        
                     //check if you're in a put for later logic
                     if((black_char_x > LVL4_PIT1_START) && (black_char_x < LVL4_PIT1_END))
                        in_a_pit <= 1;
                     else
                        in_a_pit <= 0;
                      
                 
                      
                 
                 end
                 
                 
                 
                 
                 
                 
                 
                 if ((black_char_x > 10'd645) && (black_char_x > 10'd670) && (door_counter!=50) && (clock_counter %3==0))  begin
                        door_counter <= door_counter + 5;
                 end
                 
                 if(door_counter==10'd50 && blackout_timer != 10'd50) begin
                     blackout_condition <= 1'b1;
                     blackout_timer <= blackout_timer + 1'b1;
                 end
                 else if (blackout_condition) begin
                        blackout_condition <= 1'b0;
                 end
                    
                    
 
                        
			
                clock_counter <= clock_counter+1;
                if(clock_counter % 6 == 0/*  && door_counter == 0*/)begin
                    walking_animation_cycle <= walking_animation_cycle + 1'b1;
                end/*
                else if(door_counter == 1)
                    walking_animation_cycle <= 2'b01;
                */
				if(right) begin
				    facing_right <= 1'd1;
				end
				
				else if(left) begin
                    facing_right <= 1'd0;
                end
                
                if(right == 0 && left == 0 && airborne == 0 && up == 0)
                    animation_state <= 6'b000001;
                    
                else if(up == 0 && airborne == 0 && (right || left)) begin
                    if(walking_animation_cycle == 2'b00)
                        animation_state <= 6'b000010;
                    else if(walking_animation_cycle == 2'b01)
                        animation_state <= 6'b010000;
                    else if(walking_animation_cycle == 2'b10)
                        animation_state <= 6'b000100;	
                    else if(walking_animation_cycle == 2'b11)
                        animation_state <= 6'b001000;
                end
                else
                    animation_state <= 6'b100000;

				if(up && airborne==0) begin
					black_char_y<=black_char_y-4'b0101;
                    y_speed <= 4'b0101;
                    airborne <= 1;
                    //animation_state <= 6'b100000;
				end
				
            else begin
                    
                    if(in_a_pit) begin
                        airborne <= 1;
                        if(y_speed != 4'b1010 && clock_counter % 3 == 0) begin
                            y_speed <= y_speed - 1;
                        end
                        // set next y position y =(y + speed)
                        if((black_char_y < 10'd600))
                            black_char_y <= (black_char_y - (y_speed & 4'b0111)) + (y_speed & 4'b1000);
                        else if(black_char_y >= 10'd600 || dead) begin
                            y_speed <= 4'b0; // Reset y_speed
                            black_char_y <= 10'd350;
                            black_char_x <= 10'd300;
                            airborne <= 1'b0;
                            animation_state <= 6'b000001;
                            facing_right <= 1'd1;
                            walking_animation_cycle <= 2'b00;
                            pit_counter_1=0;
                            pit_counter_2=0;
                            in_a_pit <= 0;
                            spike_counter <= 10'b0;

                       end 
                    end
                    else if(airborne)begin
                        //animation_state <= 6'b100000;
                        if (black_char_y >=  FLOOR) begin
                            if (in_a_pit==0)
                            begin
                                airborne <= 0;
                                y_speed <= 4'b0;
                                black_char_y <= FLOOR;
                            end
                        end
                        else if(y_speed != 4'b1010 && clock_counter % 3 == 0) begin
                            y_speed <= y_speed - 1;
                        end
                        if((black_char_y < FLOOR) && (black_char_y < 10'd600))
                            black_char_y <= (black_char_y - (y_speed & 4'b0111)) + (y_speed & 4'b1000);
                            

                           
                       
                    

      
                    
                    end
                    

                    


                    // idk if this is a good idea
                   // if(black_char_y + y_speed > 200 && clock_counter % 25 == 0 && black_char_x < 600 && black_char_x > 650) 

                   // else
                   //     black_char_y <= 200;
                   //     y_speed<= 6'b00;


				end



            end
		end




	
	assign whiteZone = (((hCount >= 10'd250) && (hCount <= 10'd750)) && ((vCount >= 10'd200) && (vCount <= FLOOR)) && (blackout_condition==0)) ? 1 : 0;

        
assign Cyan_zone = (
    ((hCount >= 10'd675) && (hCount <= 10'd715)) &&
    ((vCount >= (10'd300) + door_counter) && (vCount <= FLOOR))
) ? 1 : 0;        

assign Cyan_zone_2 = (
    ((hCount >= 10'd255) && (hCount <= 10'd295)) && (level_state==LVL_4) &&
    ((vCount >= (10'd300) + door_counter) && (vCount <= FLOOR))
) ? 1 : 0;  



        

    
    assign Lvl_1_Pit_1_Zone = ((level_state == LVL_1) && (((black_char_x > LVL1_PIT1_VISUAL_START - 10'd55) || (pit_counter_1 == 200)) &&
                    ((hCount >= LVL1_PIT1_VISUAL_START) && (hCount <= LVL1_PIT1_VISUAL_END)) && 
                    ((vCount >= FLOOR) && (vCount <= FLOOR + pit_counter_1)))) ? 1 : 0;
                    
    assign Lvl_2_Pit_1_Zone  = ((level_state == LVL_2) && (((black_char_x > LVL2_PIT1_VISUAL_START - 10'd40) || (pit_counter_1 == 200)) &&
                    ((hCount >= LVL2_PIT1_VISUAL_START) && (hCount <= LVL2_PIT1_VISUAL_END)) && 
                    ((vCount >= FLOOR) && (vCount <= FLOOR + pit_counter_1)))) ? 1 : 0;

    assign Lvl_2_Pit_2_Zone  = ((level_state == LVL_2) && (((black_char_x > LVL2_PIT2_VISUAL_START - 10'd40) || (pit_counter_2 == 200)) &&
                    ((hCount >= LVL2_PIT2_VISUAL_START) && (hCount <= LVL2_PIT2_VISUAL_END)) && 
                    ((vCount >= FLOOR) && (vCount <= FLOOR + pit_counter_2)))) ? 1 : 0;
                    
    assign Lvl_3_Pit_1_Zone = ((level_state == LVL_3) && (((black_char_x > LVL3_PIT1_VISUAL_START - 10'd40) || (pit_counter_1 == 200)) &&
                    ((hCount >= (LVL3_PIT1_VISUAL_START)) && (hCount <= LVL3_PIT1_VISUAL_END))) && 
                    ((vCount >= FLOOR) && (vCount <= FLOOR + pit_counter_1))) ? 1 : 0;
                    
     assign Lvl_4_Pit_1_Zone = ((level_state == LVL_4) && (((black_char_x > LVL4_PIT1_VISUAL_START - 10'd40) || (pit_counter_1 == 200)) &&
                    ((hCount >= (LVL4_PIT1_VISUAL_START)) && (hCount <= LVL4_PIT1_VISUAL_END))) && 
                    ((vCount >= FLOOR) && (vCount <= FLOOR + pit_counter_1))) ? 1 : 0;
                   
    /* assign Lvl_4_Pit_2_Zone = ((level_state == LVL_4) && (((black_char_x > LVL4_PIT2_VISUAL_START - 10'd40) || (pit_counter_2 == 200)) &&
                    ((hCount >= (LVL4_PIT2_VISUAL_START)) && (hCount <= LVL4_PIT2_VISUAL_END))) && 
                    ((vCount >= FLOOR) && (vCount <= FLOOR + pit_counter_2))) ? 1 : 0;
    */
    
    assign All_Pits = (Lvl_1_Pit_1_Zone || Lvl_2_Pit_1_Zone|| Lvl_3_Pit_1_Zone || Lvl_2_Pit_2_Zone /* || Lvl_4_Pit_1_Zone || Lvl_4_Pit_2_Zone*/ )? 1 : 0;

	//assign block_fill= vCount>=(black_char_y-10) && vCount<=(black_char_y+10) && hCount>=(black_char_x-10) && hCount<=(black_char_x+10) ? 1 : 0;
				   
    // assign black_char = ((hCount >= black_char_x) && (hCount < (black_char_x+10'd20))) &&
		//		   ((vCount <= black_char_y) &&(vCount >= (black_char_y - 10'd30))) ? 1 : 0;
				   
//    assign standing = ((hCount >= (black_char_x + 10'd7)) && (black_char_x+10'd13)) && 
  //                      ((vCount <= (black_char_y - 10'd23)) &&(vCount >= (black_char_y - 10'd30))) ? 1 : 0;
           
           
       assign bottom_hitbox = (((hCount >= (black_char_x + 10'd7)) && (hCount <= (black_char_x+10'd13))) &&
                              (vCount <= (black_char_y - (y_speed & 4'b0111)) + (y_speed & 4'b1000)) && vCount >= black_char_y) ? 1 : 0;
                        
       assign standing_animation = (((hCount >= (black_char_x + 10'd7)) && (hCount <= (black_char_x+10'd13))) && 
                    ((vCount <= (black_char_y - 10'd23)) &&(vCount >= (black_char_y - 10'd30)))) ||
                  (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x + 10'd16))) && 
                    ((vCount <= (black_char_y - 10'd7)) &&(vCount >= (black_char_y - 10'd23)))) || 
	          
	               (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x+10'd8))) && 
                    ((vCount <= (black_char_y)) &&(vCount >= (black_char_y - 10'd7)))) ||
                  (((hCount >= (black_char_x + 10'd12)) && (hCount <= (black_char_x + 10'd16))) && 
                    ((vCount <= (black_char_y)) &&(vCount >= (black_char_y - 10'd7)))) ? 1 : 0;
       
       
        assign jumping_animation_right = (((hCount >= (black_char_x + 10'd7)) && (hCount <= (black_char_x+10'd13))) && 
                        ((vCount <= (black_char_y - 10'd23)) &&(vCount >= (black_char_y - 10'd30)))) ||
                    (((hCount >= (black_char_x + 10'd2)) && (hCount <= (black_char_x+10'd16))) && 
                        ((vCount <= (black_char_y - 10'd14)) &&(vCount >= (black_char_y - 10'd23)))) ||
                        
                    (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x + 10'd16))) && 
                        ((vCount <= (black_char_y - 10'd7)) &&(vCount >= (black_char_y - 10'd14))))||
                    (((hCount >= (black_char_x)) && (hCount <= (black_char_x + 10'd8))) && 
                        ((vCount <= (black_char_y - 10'd4)) &&(vCount >= (black_char_y - 10'd8)))) ||
                    (((hCount >= (black_char_x + 10'd16)) && (hCount <= (black_char_x + 10'd20))) && 
                        ((vCount <= (black_char_y - 10'd4)) &&(vCount >= (black_char_y - 10'd8)))) ? 1 : 0;
                        
                        
        assign jumping_animation_left = (((hCount >= (black_char_x + 10'd7)) && (hCount <= (black_char_x+10'd13))) && 
                ((vCount <= (black_char_y - 10'd23)) &&(vCount >= (black_char_y - 10'd30)))) ||
            (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x+10'd18))) && 
                ((vCount <= (black_char_y - 10'd14)) &&(vCount >= (black_char_y - 10'd23)))) ||
                
            (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x + 10'd16))) && 
                ((vCount <= (black_char_y - 10'd7)) &&(vCount >= (black_char_y - 10'd14))))||
            (((hCount >= (black_char_x + 10'd12)) && (hCount <= (black_char_x + 10'd20))) && 
                ((vCount <= (black_char_y - 10'd4)) &&(vCount >= (black_char_y - 10'd8)))) ||
            (((hCount >= (black_char_x + 10'd0)) && (hCount <= (black_char_x + 10'd4))) && 
                ((vCount <= (black_char_y - 10'd4)) &&(vCount >= (black_char_y - 10'd8)))) ? 1 : 0;
                
                
    assign walking_1_animation_right = (((hCount >= (black_char_x + 10'd7)) && (hCount <= (black_char_x+10'd13))) && 
                ((vCount <= (black_char_y - 10'd23)) &&(vCount >= (black_char_y - 10'd30)))) ||
            
            (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x + 10'd16))) && 
                    ((vCount <= (black_char_y - 10'd7)) &&(vCount >= (black_char_y - 10'd23)))) || 
                
            (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x + 10'd8))) && 
                ((vCount <= (black_char_y - 10'd5)) &&(vCount >= (black_char_y - 10'd7))))||
                
            (((hCount >= (black_char_x + 10'd2)) && (hCount <= (black_char_x + 10'd7))) && 
                ((vCount <= (black_char_y)) &&(vCount >= (black_char_y - 10'd4)))) ||
                
            (((hCount >= (black_char_x + 10'd14)) && (hCount <= (black_char_x + 10'd18))) && 
                ((vCount <= (black_char_y - 10'd2)) &&(vCount >= (black_char_y - 10'd11)))) ? 1 : 0;
                
    assign walking_1_animation_left = (((hCount >= (black_char_x + 10'd7)) && (hCount <= (black_char_x+10'd13))) && 
            ((vCount <= (black_char_y - 10'd23)) &&(vCount >= (black_char_y - 10'd30)))) ||
        
        (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x + 10'd16))) && 
                ((vCount <= (black_char_y - 10'd7)) &&(vCount >= (black_char_y - 10'd23)))) || 
            
        (((hCount >= (black_char_x + 10'd12)) && (hCount <= (black_char_x + 10'd16))) && 
            ((vCount <= (black_char_y - 10'd5)) &&(vCount >= (black_char_y - 10'd7))))||
            
        (((hCount >= (black_char_x + 10'd13)) && (hCount <= (black_char_x + 10'd18))) && 
            ((vCount <= (black_char_y)) &&(vCount >= (black_char_y - 10'd4)))) ||
            
        (((hCount >= (black_char_x + 10'd2)) && (hCount <= (black_char_x + 10'd6))) && 
            ((vCount <= (black_char_y - 10'd2)) &&(vCount >= (black_char_y - 10'd11)))) ? 1 : 0;
           
     
     
     
     assign walking_2_animation_right = (((hCount >= (black_char_x + 10'd7)) && (hCount <= (black_char_x+10'd13))) && 
            ((vCount <= (black_char_y - 10'd25)) &&(vCount >= (black_char_y - 10'd32)))) ||
        
        (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x + 10'd16))) && 
                ((vCount <= (black_char_y - 10'd9)) &&(vCount >= (black_char_y - 10'd25)))) || 
            
         (((hCount >= (black_char_x + 10'd2)) && (hCount <= (black_char_x+10'd8))) && 
                    ((vCount <= (black_char_y - 10'd7)) &&(vCount >= (black_char_y - 10'd9)))) ||
         (((hCount >= (black_char_x)) && (hCount <= (black_char_x+10'd6))) && 
                    ((vCount <= (black_char_y - 10'd4)) &&(vCount >= (black_char_y - 10'd7)))) ||
         
        (((hCount >= (black_char_x + 10'd2)) && (hCount <= (black_char_x+10'd4))) && 
                    ((vCount <= (black_char_y - 10'd2)) &&(vCount >= (black_char_y - 10'd4)))) ||
          
        (((hCount >= (black_char_x + 10'd13)) && (hCount <= (black_char_x + 10'd18))) && 
            ((vCount <= (black_char_y)) &&(vCount >= (black_char_y - 10'd4)))) ||
            
        (((hCount >= (black_char_x + 10'd12)) && (hCount <= (black_char_x + 10'd16))) && 
                    ((vCount <= (black_char_y - 10'd2)) &&(vCount >= (black_char_y - 10'd9)))) ? 1 : 0;
       
          
          
          
               
     assign walking_2_animation_left = (((hCount >= (black_char_x + 10'd7)) && (hCount <= (black_char_x+10'd13))) && 
            ((vCount <= (black_char_y - 10'd25)) &&(vCount >= (black_char_y - 10'd32)))) ||
        
        (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x + 10'd16))) && 
                ((vCount <= (black_char_y - 10'd9)) &&(vCount >= (black_char_y - 10'd25)))) || 
            
         (((hCount >= (black_char_x + 10'd12)) && (hCount <= (black_char_x+10'd18))) && 
                    ((vCount <= (black_char_y - 10'd7)) &&(vCount >= (black_char_y - 10'd9)))) ||
         (((hCount >= (black_char_x+10'd14)) && (hCount <= (black_char_x+10'd20))) && 
                    ((vCount <= (black_char_y - 10'd4)) &&(vCount >= (black_char_y - 10'd7)))) ||
         
        (((hCount >= (black_char_x + 10'd16)) && (hCount <= (black_char_x+10'd18))) && 
                    ((vCount <= (black_char_y - 10'd2)) &&(vCount >= (black_char_y - 10'd4)))) ||
          
        (((hCount >= (black_char_x + 10'd2)) && (hCount <= (black_char_x + 10'd7))) && 
            ((vCount <= (black_char_y)) &&(vCount >= (black_char_y - 10'd4)))) ||
            
        (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x + 10'd8))) && 
                    ((vCount <= (black_char_y - 10'd2)) &&(vCount >= (black_char_y - 10'd9)))) ? 1 : 0;      
                
                
        assign walking_3_animation_right = (((hCount >= (black_char_x + 10'd7)) && (hCount <= (black_char_x+10'd13))) && 
            ((vCount <= (black_char_y - 10'd3)) &&(vCount >= (black_char_y - 10'd30)))) ||
          
          (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x + 10'd16))) && 
            ((vCount <= (black_char_y - 10'd10)) &&(vCount >= (black_char_y - 10'd23)))) || 
      
           (((hCount >= (black_char_x + 10'd13)) && (hCount <= (black_char_x+10'd16))) && 
            ((vCount <= (black_char_y - 10'd5)) &&(vCount >= (black_char_y - 10'd10)))) ||
          (((hCount >= (black_char_x + 10'd9)) && (hCount <= (black_char_x + 10'd13))) && 
            ((vCount <= (black_char_y)) &&(vCount >= (black_char_y - 10'd3)))) ? 1 : 0;
            
      assign walking_3_animation_left = (((hCount >= (black_char_x + 10'd7)) && (hCount <= (black_char_x+10'd13))) && 
            ((vCount <= (black_char_y - 10'd3)) &&(vCount >= (black_char_y - 10'd30)))) ||
          
          (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x + 10'd16))) && 
            ((vCount <= (black_char_y - 10'd10)) &&(vCount >= (black_char_y - 10'd23)))) || 
      
           (((hCount >= (black_char_x + 10'd4)) && (hCount <= (black_char_x+10'd7))) && 
            ((vCount <= (black_char_y - 10'd10)) &&(vCount >= (black_char_y - 10'd15)))) ||
          (((hCount >= (black_char_x + 10'd7)) && (hCount <= (black_char_x + 10'd11))) && 
            ((vCount <= (black_char_y)) &&(vCount >= (black_char_y - 10'd3)))) ? 1 : 0;
            
       
      assign spike_1 = (
      ((hCount >= (spike_1_x)) && (hCount <= (spike_1_x+10'd12))) &&((vCount <= spike_1_y) && (vCount >= spike_1_y - 10'd2)) ||
      ((hCount >= (spike_1_x+10'd2)) && (hCount <= (spike_1_x+10'd10))) &&((vCount <= spike_1_y-10'd2) && (vCount >= spike_1_y - 10'd5)) ||
    ((hCount >= (spike_1_x+10'd5)) && (hCount <= (spike_1_x+10'd7))) &&((vCount <= spike_1_y-10'd5) && (vCount >= spike_1_y - 10'd9)) ||
    
     ((hCount >= (spike_1_x + 10'd11)) && (hCount <= (spike_1_x+10'd12 + 10'd11))) &&((vCount <= spike_1_y) && (vCount >= spike_1_y - 10'd2)) ||
     ((hCount >= (spike_1_x+10'd2 + 10'd11)) && (hCount <= (spike_1_x+10'd10 + 10'd11))) &&((vCount <= spike_1_y-10'd2) && (vCount >= spike_1_y - 10'd5)) ||
     ((hCount >= (spike_1_x+10'd5 + 10'd11)) && (hCount <= (spike_1_x+10'd7 + 10'd11))) &&((vCount <= spike_1_y-10'd5) && (vCount >= spike_1_y - 10'd9)) ||
     
     ((hCount >= (spike_1_x + 10'd22)) && (hCount <= (spike_1_x+10'd12 + 10'd22))) &&((vCount <= spike_1_y) && (vCount >= spike_1_y - 10'd2)) ||
     ((hCount >= (spike_1_x+10'd2 + 10'd22)) && (hCount <= (spike_1_x+10'd10 + 10'd22))) &&((vCount <= spike_1_y-10'd2) && (vCount >= spike_1_y - 10'd5)) ||
     ((hCount >= (spike_1_x+10'd5 + 10'd22)) && (hCount <= (spike_1_x+10'd7 + 10'd22))) &&((vCount <= spike_1_y-10'd5) && (vCount >= spike_1_y - 10'd9))
      
      ) ? 1 : 0;
                
endmodule
