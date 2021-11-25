/************************************************************************
AES Decryption Core Logic

Dong Kai Wang, Fall 2017

For use with ECE 385 Experiment 9
University of Illinois ECE Department
************************************************************************/

module AES (
	input	 logic CLK,
	input  logic RESET,
	input  logic AES_START,
	output logic AES_DONE,
	input  logic [127:0] AES_KEY,
	input  logic [127:0] AES_MSG_ENC,
	output logic [127:0] AES_MSG_DEC
);

    logic [1407:0] key_schedule;
    logic [127:0] state_message, row_shiftout,invSubtractout, Roundk_Addout, mixCol_128out, op_out;   
    logic [31:0] mixCol_32in, mixCol_32out;
    logic [4:0] key_exp_count;
    logic [3:0] rnum_out;
    logic [2:0] op_count, Col_count;
    logic round_reset, key_exp_round, round_in, key_exp_in, Col_in, op_reset, Col_reset, op_in, load_state_message, Roundk_Add;    

    //instantiating all the modules for the AES standard

    count_to_30 inst_key_exp_count(.*,.increment(key_exp_in),.RESET(key_exp_round),.count_out(key_exp_count), .clk(CLK));

    KeyExpansion inst_key_exp(.clk(CLK), .Cipherkey(AES_KEY), .KeySchedule(key_schedule));
    
    feeder_32_128 inst_Colfeed_mod (.*, .S0(mixCol_32out), .feeder_out(mixCol_128out), .cs(Col_count), .clk(CLK));

    InvShiftRows inst_shiftrow_mod(.data_in(state_message), .data_out(row_shiftout));
    
    reg128 inst_message_state(.*,.LD1(Roundk_Add), .S1(AES_MSG_ENC),.LD2(load_state_message), .S2(op_out),.register_out(state_message), .clk(CLK));

    mux_4_128 inst_op_modmux (.S0(row_shiftout),.S1(invSubtractout),.S2(Roundk_Addout), .S3(mixCol_128out),.cs(op_count),.mux_out(op_out));

    count_to_11 inst_count_round_mod (.*,.increment(round_in),.RESET(round_reset),.count_out(rnum_out), .clk(CLK));

    Round_KeySchedule inst_AddKeyR_mod(.*, .keyschedule(key_schedule), .message_state(state_message), .Round_number(rnum_out), .round_add_out(Roundk_Addout));

    count_to_5 inst_Col_count_mod(.*,.increment(Col_in),.RESET(Col_reset),.count_out(Col_count), .clk(CLK));
    
    mux_4_32 inst_mixCol_muxmod (.*, .S0(state_message[127:96]),.S1(state_message[95:64]), .S2(state_message[63:32]),.S3(state_message[31:0]),.cs(Col_count),.mux_out(mixCol_32in));
    
    InvSub16Bytes inst_subtractbyte_mod (.*,.in(state_message),.out(invSubtractout), .clk(CLK));
    
    InvMixColumns inst_invmixCol_mod (.in(mixCol_32in), .out(mixCol_32out));

    count_to_5 inst_opcount_mod(.*,.increment(op_in),.RESET(op_reset),.count_out(op_count), .clk(CLK));
    
    AES_SM inst_AEDstatemachine (.*, .start(AES_START), .AES_DONE(AES_DONE), .clk(CLK), .round_number(rnum_out), .count_op(op_count), .count_Col(Col_count));
                        
                        
    assign AES_MSG_DEC=state_message;

endmodule
