module testbench();

timeunit 10ns;
timeprecision 1ns;

logic CLK, RESET, AES_START, AES_DONE;        

logic [127:0] AES_MSG_ENC = 128'hdaec3055df058e1c39e814ea76f6747e;
logic [127:0] AES_KEY = 128'h000102030405060708090a0b0c0d0e0f;

logic [127:0] AES_MSG_DEC;
		
AES aes_testbench_inst (.*);


always begin : CLOCK_GENERATION
#1 CLK = ~CLK;
end

initial begin: CLOCK_INITIALIZATION
    CLK = 0;
end 


initial begin: TEST_VECTORS

    RESET = 0;

    AES_START =1'b1;

end

endmodule