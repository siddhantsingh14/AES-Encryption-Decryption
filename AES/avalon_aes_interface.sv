/************************************************************************
Avalon-MM Interface for AES Decryption IP Core

Dong Kai Wang, Fall 2017

For use with ECE 385 Experiment 9
University of Illinois ECE Department

Register Map:

 0-3 : 4x 32bit AES Key
 4-7 : 4x 32bit AES Encrypted Message
 8-11: 4x 32bit AES Decrypted Message
   12: Not Used
	13: Not Used
   14: 32bit Start Register
   15: 32bit Done Register

************************************************************************/

module avalon_aes_interface (
	// Avalon Clock Input
	input logic CLK,
	
	// Avalon Reset Input
	input logic RESET,
	
	// Avalon-MM Slave Signals
	input  logic AVL_READ,					// Avalon-MM Read
	input  logic AVL_WRITE,					// Avalon-MM Write
	input  logic AVL_CS,						// Avalon-MM Chip Select
	input  logic [3:0] AVL_BYTE_EN,		// Avalon-MM Byte Enable
	input  logic [3:0] AVL_ADDR,			// Avalon-MM Address
	input  logic [31:0] AVL_WRITEDATA,	// Avalon-MM Write Data
	output logic [31:0] AVL_READDATA,	// Avalon-MM Read Data
	
	// Exported Conduit
	output logic [31:0] EXPORT_DATA		// Exported Conduit Signal to LEDs
);

logic [15:0][31:0] register;
logic [31:0] write_data;


logic [127:0] AES_KEY;
logic [127:0] AES_MSG_DEC;
logic [127:0] AES_MSG_ENC;
logic AES_START, AES_DONE;


always_comb
    begin


	    AES_START = register[14][0]; //assigning register14 to signal start of decryption
	    AES_MSG_ENC = {register[4],register[5],register[6],register[7]};    //register4-7 are assigned to the encryp_message
	    AES_KEY = {register[0],register[1],register[2],register[3]};    //register 0-3 are assigned to the key
	
    end

AES aes_instantition_mod (.*);

		always_ff @ (posedge CLK)
		
			begin
			if(AES_DONE)    //if the AES_DONE flag is high, then set register15 to 1 and store the decrypted message to the registers			
				begin
					register[15] <= 32'b1;
					
					register[8] <= AES_MSG_DEC[31:0];
					register[9] <= AES_MSG_DEC[63:32];
					register[10] <= AES_MSG_DEC[95:64];
					register[11] <= AES_MSG_DEC[127:96];
					
				end

                //if the byte_en is high for the bytes, then start writing data to the specific bytes, starting from byte 0
				if(AVL_BYTE_EN[0])
					write_data[7:0] <= AVL_WRITEDATA[7:0];
					
				if(AVL_BYTE_EN[1])
					write_data[15:8] <= AVL_WRITEDATA[15:8];
				
				if(AVL_BYTE_EN[2])
					write_data[23:16] <= AVL_WRITEDATA[23:16];
				
				if(AVL_BYTE_EN[3])
					write_data[31:24] <= AVL_WRITEDATA[31:24];
					
				if(RESET)   //if reset is high, then reset all the registers
					begin
						register[0] <= 32'h0;
						register[1] <= 32'h0;
						register[2] <= 32'h0;
						register[3] <= 32'h0;
						register[4] <= 32'h0;
						register[5] <= 32'h0;
						register[6] <= 32'h0;
						register[7] <= 32'h0;
						register[8] <= 32'h0;
						register[9] <= 32'h0;
						register[10] <= 32'h0;
						register[11] <= 32'h0;
						register[12] <= 32'h0;
						register[13] <= 32'h0;
						register[14] <= 32'h0;
						register[15] <= 32'h0;
					end
						
                else if (AVL_WRITE && AVL_CS)   //if the write and the cs signals are both high, then set the register values with the write data
                    begin
                        register[AVL_ADDR]<=write_data;
                    end
		
		end
		

		always_comb
				
            begin
                if(AVL_READ && AVL_CS)  //if read and cs are high then
                    begin
                        AVL_READDATA = register[AVL_ADDR];   //output data being stored
                    end
                else
                    begin
                        AVL_READDATA = 32'b0;   //reset the readdata register
                    end	
                
                EXPORT_DATA = { register[0][31:16], register[3][15:0]};   //export data is used to store the key vals and display them on the hex of fpga
            
            end

endmodule
