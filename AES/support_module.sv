//############################################################# COUNTERS ####################################################
//Defining all the counter modules

//counter counts to 5
module count_to_5(input logic increment, clk, RESET, 
			  output logic [2:0] count_out);
					
		logic [2:0] next_count;
		
		always_ff @ (posedge clk)
		begin
			if(increment)
			    count_out<=next_count;  //if increment is high, then move the next count to count
			else if(RESET)
			    count_out<= 3'b00;  //if reset is high, reset
		end
		
		always_comb
		begin
		    if(count_out==3'b100)   //if the count is 4, then make the count 0 
			    next_count = 3'b000;
		    else
			    next_count = count_out+3'b001;  //increment the count
		end		
endmodule

//counter countrs to 11
module count_to_11(input logic increment, clk, RESET, 
			   output logic [3:0] count_out);

		logic [3:0] next_count;
		
		always_ff @ (posedge clk)
		begin
			if(increment)
				count_out<=next_count;  //if increment is high, then move the next count to count
			else if(RESET)
				count_out<= 4'b0000;    //if reset is high, reset
		end
		
		always_comb
		begin
		if(count_out==4'b1010)  //if the count is 10, then make the count 0
			next_count = 4'b0000;
		else
			next_count = count_out+4'b0001; //increment the count
		end		
endmodule

//counter counts to 30
module count_to_30(input logic increment, clk, RESET, 
					output logic [4:0] count_out);
					
		
		logic [4:0] next_count;
		
		always_ff @ (posedge clk)
		begin
			if(increment)
				count_out<=next_count;  //if increment is high, then move the next count to count
			else if(RESET)
				count_out<= 5'b00000;   //if reset is high, reset
		end
		
		always_comb
		begin
		if(count_out==5'b11101)     //if the count is 29, then make the count 0
			next_count = 5'b00000;
		else
			next_count = count_out+5'b00001;    //increment the count
		end		
endmodule

//############################################################# COUNTERS FINISHED ####################################################



//############################################################# MUXES ####################################################
//Defining all the MUX modules

//128 bit 4-1 mux
module mux_4_128(input logic [127:0] S0, S1, S2, S3,
				input logic [2:0] cs,
				output logic [127:0] mux_out);
				  
                always_comb
	            begin
                    case(cs)                    
                        3'b000:
                            mux_out = S0;
                    
                        3'b001:
                            mux_out = S1;
                        
                        3'b010:
                            mux_out = S2;
                    
                        3'b011:
                            mux_out =  S3;
                        default: mux_out = 128'h0;
                        endcase                  
                end
endmodule

//32bit 4-1 mux
module mux_4_32(input logic [31:0] S0, S1, S2, S3,
			    input logic [2:0] cs,
				output logic [31:0] mux_out);
                
                always_comb
                begin              
                    case(cs)                   
                        3'b000:
                            mux_out = S0;
                    
                        3'b001:
                            mux_out = S1;
                        
                        3'b010:
                            mux_out = S2;
                    
                        3'b011:
                            mux_out =  S3;
                        default: mux_out = 32'h0;
                        endcase
                end
endmodule


//32 to 128 bit feeder. puts the 32 bit in one of the 32 bit portion of 128 bit.
module feeder_32_128(input logic clk, RESET,
                    input logic [31:0] S0,
				    input logic [2:0] cs,
				    output logic [127:0] feeder_out);
				  
                    always_ff @ (posedge clk)
                    begin
                        if(RESET)
                        begin
                            feeder_out <= 128'h0 ;	  
                        end
                    
                        else
                        begin                   
                            case(cs)
                                3'b000:
                                begin
                                    feeder_out[127:96] <= S0;
                                end
                                
                                3'b001:
                                begin
                                    feeder_out[95:64] <= S0;
                                end
                                
                                3'b010:
                                begin
                                    feeder_out[63:32] <= S0;
                                end
                                
                                3'b011:
                                begin
                                    feeder_out[31:0] <= S0;
                                end
        
                                default:  ;
                            endcase       
                        end
                    end
endmodule


//############################################################# MUXES FINISHED ####################################################



//############################################################# Add Round and Inverse Subtract Module ####################################################

//Sorting key from keyschule for each round is done in this function
module Round_KeySchedule(input logic [1407:0] keyschedule,
                   input logic [127:0] message_state, 
				   input logic [3:0] Round_number,
                   output logic [127:0] round_add_out);
						 
	logic [127:0] Roundkey;
	
	always_comb
		begin
			case(Round_number)  //depending on the round number, the key is stored from different 4 bytes
				4'b0000:
					Roundkey = keyschedule[127:0];
				4'b0001:
					Roundkey = keyschedule[255:128];
				4'b0010:
					Roundkey = keyschedule[383:256];
				4'b0011:
					Roundkey = keyschedule[511:384];
				4'b0100:
					Roundkey = keyschedule[639:512];
				4'b0101:
					Roundkey = keyschedule[767:640];
				4'b0110:
					Roundkey = keyschedule[895:768];
				4'b0111:
					Roundkey = keyschedule[1023:896];
				4'b1000:
					Roundkey = keyschedule[1151:1024];
				4'b1001:
					Roundkey = keyschedule[1279:1152];
				4'b1010:
					Roundkey = keyschedule[1407:1280];
				default: Roundkey = 128'b0;
			endcase			
		end
	
	assign round_add_out = message_state ^ Roundkey;    //XOR to get the final output
endmodule


//Calls Inverse Subtract Bytes individually for each byte.
module InvSub16Bytes(input logic clk, 
					 input logic [127:0] in, 
					 output logic [127:0] out);
						
		InvSubBytes byte0 (.clk(clk), .in(in[7:0]), .out(out[7:0]));
		InvSubBytes byte1 (.clk(clk), .in(in[15:8]), .out(out[15:8]));
		InvSubBytes byte2 (.clk(clk), .in(in[23:16]), .out(out[23:16]));
		InvSubBytes byte3 (.clk(clk), .in(in[31:24]), .out(out[31:24]));
		InvSubBytes byte4 (.clk(clk), .in(in[39:32]), .out(out[39:32]));
		InvSubBytes byte5 (.clk(clk), .in(in[47:40]), .out(out[47:40]));
		InvSubBytes byte6 (.clk(clk), .in(in[55:48]), .out(out[55:48]));
		InvSubBytes byte7 (.clk(clk), .in(in[63:56]), .out(out[63:56]));
		InvSubBytes btye8 (.clk(clk), .in(in[71:64]), .out(out[71:64]));
		InvSubBytes byte9 (.clk(clk), .in(in[79:72]), .out(out[79:72]));
		InvSubBytes byte10 (.clk(clk), .in(in[87:80]), .out(out[87:80]));
		InvSubBytes byte11 (.clk(clk), .in(in[95:88]), .out(out[95:88]));
		InvSubBytes byte12 (.clk(clk), .in(in[103:96]), .out(out[103:96]));
		InvSubBytes byte13 (.clk(clk), .in(in[111:104]), .out(out[111:104]));
		InvSubBytes byte14 (.clk(clk), .in(in[119:112]), .out(out[119:112]));
		InvSubBytes byte15 (.clk(clk), .in(in[127:120]), .out(out[127:120]));
		
endmodule



//############################################################# Add Round and Inverse Subtract Module Finished####################################################


//############################################################# 128 bit REGISTER ####################################################


module reg128 (input  logic clk, RESET, LD1,LD2, 
               input  logic [127:0]  S1, S2,
               output logic [127:0]  register_out);

    logic [127:0] next_register;
	 
    always_ff @ (posedge clk)
    begin
	 	register_out<=next_register;
    end
	 
	always_comb
	begin
	    next_register = register_out;
	 	if(LD1) 
			next_register = S1;
        else if(LD2)
			next_register = S2;
		else if(RESET) 
		    next_register = 4'b0000;	  
    end
endmodule


//############################################################# 128 bit REGISTER Finished####################################################

//############################################################# AES State Machine ####################################################

module AES_SM(input logic clk, RESET, start,
            input logic [4:0] key_exp_count,
            input logic [3:0] round_number,
			input logic [2:0] count_op, count_Col,
		    output logic round_reset, key_exp_round, round_in, key_exp_in, Col_in, op_reset, Col_reset, op_in, load_state_message, Roundk_Add, AES_DONE);
            

	enum logic [3:0] {start_state, one, two, three, four, five, six, seven, eight, nine,
							ten, eleven, mixCols, key_exp, done}   curr_state, next_state;
								
		always_ff @ (posedge clk)
			begin
				if (RESET) 
					curr_state <= start_state;
				else 
					curr_state <= next_state;
			end
		
		always_comb
			begin   //setting deafult values
				load_state_message = 1'b0;
				AES_DONE = 1'b0;
				op_in = 1'b0; 
				op_reset = 1'b1;
				Col_in = 1'b0;
				Col_reset = 1'b1;
				key_exp_in = 1'b0;
				key_exp_round = 1'b1;
				round_in = 1'b0;
				round_reset = 1'b0;
				Roundk_Add = 1'b0;
				
				next_state = curr_state;
							
				unique case(curr_state)

					start_state:    //start state
						if(start)
							next_state = key_exp;
						else
							next_state = start_state;
		
					key_exp:
						if(key_exp_count==5'b11101) 
							next_state = one;   //go to state 1 after keyexpansion ends after 30 cycles
						else
							next_state = key_exp;
                    
                    mixCols:
					
		
						if(count_Col==3'b100)
							begin
								case(round_number)  //take the round key number and choose next state
									4'b0010:
										next_state = three;
									4'b0011:
										next_state = four;
									4'b0100:
										next_state = five;
									4'b0101:
										next_state = six;
									4'b0110:
										next_state = seven;
									4'b0111:
										next_state = eight;
									4'b1000:
										next_state = nine;
									4'b1001:
										next_state = ten;
									4'b1010:
										next_state = eleven;
									default : ;
								endcase
							end
							
						else
							next_state = mixCols;

					one:
						if(count_op==2'b10)
							next_state = two;
						else
							next_state = one;

					two:
						if(count_op<2'b11)
							next_state = two;
						else
							next_state = mixCols;
							
					three:
						if(count_op<2'b11)
							next_state = three;
						else
							next_state = mixCols;
							
					four:
						if(count_op<2'b11)
							next_state = four;
						else
							next_state = mixCols;
							
					five:
						if(count_op<2'b11)
							next_state = five;
						else
							next_state = mixCols;
							
					six:
						if(count_op<2'b11)
							next_state = six;
						else
							next_state = mixCols;
							
					seven:
						if(count_op<2'b11)
							next_state = seven;
						else
							next_state = mixCols;
							
					eight:
						if(count_op<2'b11)
							next_state = eight;
						else
							next_state = mixCols;
							
					nine:
						if(count_op<2'b11)
							next_state = nine;
						else
							next_state = mixCols;
							
					ten:
						if(count_op<2'b11)
							next_state = ten;
						else
							next_state = mixCols;
							
					eleven:
						if(count_op<2'b11)
							next_state = eleven;
						else
							next_state = done;
							
					done:
						if(!start)
							next_state = start_state;

					default : next_state = start_state;
					
				endcase
				
				case(curr_state)
					key_exp:
						begin

							if(key_exp_count<5'b11101)
							begin
								key_exp_in = 1'b1;
								Roundk_Add = 1'b1;
							end
							else
								key_exp_in = 1'b0;
						end

                    mixCols:
						begin
							if(count_Col<3'b100)
								begin
									load_state_message = 1'b0;
									Col_reset = 1'b0;
                                    round_in = 1'b0;
									round_reset = 1'b0;
									Col_in = 1'b1;
									op_reset = 1'b0;									
								end
							else
								begin
									load_state_message = 1'b1;
                                    Col_reset = 1'b1;
									Col_in = 1'b0;									
									round_reset = 1'b0;
									op_reset = 1'b1;
								end
						end
					
					one:
						begin

							if(count_op==3'b010)
								begin
									load_state_message = 1'b1;
                                    round_in = 1'b1;
									op_reset = 1'b1;
									op_in = 1'b0;									
								end
							else
								begin

									round_reset = 1'b1;
									load_state_message = 1'b0;									
									round_in = 1'b0;
                                    op_in = 1'b1;
									op_reset = 1'b0;
								end
						end
					two, three, four, five, six, seven, eight, nine, ten, eleven: 

						begin
							if(count_op<3'b011)
								begin
									load_state_message = 1'b1;
									op_reset = 1'b0;
                                    round_in = 1'b0;
									op_in = 1'b1;									
								end
							else
								begin
									load_state_message = 1'b0;
                                    op_reset = 1'b0;
									op_in = 1'b0;									
									round_in = 1'b1;
								end

						end

					done:
						begin
							AES_DONE = 1;
						end
						
                    start_state: ;
					default : ;
					
				endcase
				
		end				
		
endmodule



//############################################################# AES State Machine Finished####################################################