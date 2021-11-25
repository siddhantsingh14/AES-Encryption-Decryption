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

logic [15:0][31:0] regis;
logic [31:0] Dwrite;

logic AES_DONE;
logic [127:0] AES_KEY;
logic [127:0] AES_MSG_DEC;
logic AES_START;
logic [127:0] AES_MSG_ENC;

always_comb
begin

//assign AES start to LSB of register 14 or the 15th register that tells AES to start 
//decryption
	AES_START = regis[14][0];
//assign AES msg enc to registers 4-7
	AES_MSG_ENC = {regis[4],regis[5],regis[6],regis[7]};
//assign AES Key to regis 0-3
	AES_KEY = {regis[0],regis[1],regis[2],regis[3]};
	
end

AES aesfunc (.*);

		always_ff @ (posedge CLK)
		
			begin
//when aes says done, set 15th register to all 1's
			if(AES_DONE == 1'b1)			
				begin
				
					regis[15] <= 32'b1;
					
					regis[8] <= AES_MSG_DEC[31:0];
					regis[9] <= AES_MSG_DEC[63:32];
					regis[10] <= AES_MSG_DEC[95:64];
					regis[11] <= AES_MSG_DEC[127:96];
					
				end
	//load Dwrite with the parts of writedata indicated by BYTE_EN
				//write byte 0
				if(AVL_BYTE_EN[0] == 1)
					Dwrite[7:0] <= AVL_WRITEDATA[7:0];
					
				//write byte 1
				if(AVL_BYTE_EN[1] == 1)
					Dwrite[15:8] <= AVL_WRITEDATA[15:8];
				
				//write byte 2	
				if(AVL_BYTE_EN[2] == 1)
					Dwrite[23:16] <= AVL_WRITEDATA[23:16];
				
				//write byte 3
				if(AVL_BYTE_EN[3] == 1)
					Dwrite[31:24] <= AVL_WRITEDATA[31:24];
					
					if(RESET==1'b1)
						//reset R0-R31 to 0
						begin
						
							regis[0] <= 32'h0;
							regis[1] <= 32'h0;
							regis[2] <= 32'h0;
							regis[3] <= 32'h0;
							regis[4] <= 32'h0;
							regis[5] <= 32'h0;
							regis[6] <= 32'h0;
							regis[7] <= 32'h0;
							regis[8] <= 32'h0;
							regis[9] <= 32'h0;
							regis[10] <= 32'h0;
							regis[11] <= 32'h0;
							regis[12] <= 32'h0;
							regis[13] <= 32'h0;
							regis[14] <= 32'h0;
							regis[15] <= 32'h0;
	   
					
						end
						
					else if (AVL_WRITE ==1'b1 && AVL_CS==1'b1)
//send to registers parts of the read data we want to write 
//parts to send indicated through Byteenable and register to send to through AVL_ADDR
						begin
						
						regis[AVL_ADDR]<=Dwrite;
						
						end
		
		end
		

		always_comb
				
					begin
							
							
					if(AVL_READ ==1'b1 && AVL_CS==1'b1)
					begin
				//If read and Chip select on then send the data in register indicatedby
				//AVL_ADDR to output data readdata
						AVL_READDATA = regis[AVL_ADDR];
					end
					else
					begin
						AVL_READDATA = 32'b0;
					end	
				//assign the first 2 bytes and last 2 bytes of AES key - R0-R3 to export data
					EXPORT_DATA = { regis[0][31:16], regis[3][15:0]};
					
				end

endmodule
