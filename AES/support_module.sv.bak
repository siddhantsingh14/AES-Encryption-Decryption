module datapath(
	input logic	Clk, Reset_ah,
	input logic [15:0] S, MDR_In,
	input logic GateMDR, GateALU, GatePC, GateMARMUX,
	input logic LD_MAR, LD_MDR, LD_IR, LD_PC, LD_CC, LD_BEN, LD_REG, LD_LED, 
	input logic [1:0] PCMUX, ADDR2MUX, ALUK,
	input logic DRMUX, ADDR1MUX, MIO_EN, SR1MUX, SR2MUX,
	output logic [15:0] IR, PC, MAR, MDR,
	output logic BEN,
	output logic [9:0] LED
);
	
	logic[15:0] BUS, PCMUX_out, SR2MUX_out, MDRMUX_out, SR1_out, SR2_out, ADDR2MUX_out, ADDR1MUX_out, ALU_out;
	
	logic [2:0] DRMUX_out, SR1MUX_out;
//	, NZP, NZP_temp;
//	logic BEN_temp;
//	assign ADDR12_out = ADDR1MUX_out + ADDR2MUX_out;
//	assign BEN_temp = (NZP[0]&IR[9])||(NZP[1]&IR[10])||(NZP[2]&IR[11]);
//	
//	always_comb
//		begin
//			if(BUS[15]== 1'b1)
//				NZP_temp=3'b100;
//			else if(BUS== 16'b0)
//				NZP_temp=3'b010;
//			else
//				NZP_temp = 3'b001;
//		end
	
	gatemux GateMux(.S0(ADDR2MUX_out + ADDR1MUX_out), .S1(PC), .S2(ALU_out), .S3(MDR), .cs({GateMARMUX, GatePC, GateALU, GateMDR}), .mux_out(BUS));
	
	
	register PC_register(.Clk(Clk), .Reset(Reset_ah), .Load(LD_PC), .D(PCMUX_out), .Data_Out(PC));
	
	mux_DR_SR1 DRMUX_mod(.S0(IR[11:9]), .S1(3'b111), .cs(DRMUX), .mux_out(DRMUX_out));


	registerFile reg_control(.Clk(Clk), .Reset_ah(Reset_ah), .LD_REG(LD_REG), .SR1(SR1MUX_out), .SR2(IR[2:0]), .DR(DRMUX_out), .D(BUS), .SR1_out(SR1_out), .SR2_out(SR2_out));
	
	pcmux PC_MUX(.S0(PC+16'b1), .S1(ADDR2MUX_out + ADDR1MUX_out), .S2(BUS), .cs(PCMUX), .mux_out(PCMUX_out));
//	pcmux PC_MUX(.S0(BUS), .S1(ADDR2MUX_out + ADDR1MUX_out), .S2(PC_out + 1), .cs(PCMUX), .mux_out(PCMUX_out));
	
	mux_DR_SR1 SR1MUX_mod(.S0(IR[11:9]), .S1(IR[8:6]), .cs(SR1MUX), .mux_out(SR1MUX_out));
	
//	mux_4 ADDR2MUX_mod(.S0(16'b0), .S1({{10{IR[5]}}, IR[5:0]}), .S2({{7{IR[8]}}, IR[8:0]}), .S3({{5{IR[10]}}, IR[10:0]}), .cs(ADDR2MUX), .mux_out(ADDR2MUX_out));
	mux_4 ADDR2MUX_mod(.S0({{5{IR[10]}}, IR[10:0]}), .S1({{7{IR[8]}}, IR[8:0]}), .S2({{10{IR[5]}}, IR[5:0]}), .S3(16'b0), .cs(ADDR2MUX), .mux_out(ADDR2MUX_out));
	
	mux_2 ADDR1MUX_mod(.S0(PC), .S1(SR1_out), .cs(ADDR1MUX), .mux_out(ADDR1MUX_out));
	
	mux_2 SR2MUX_mod(.S0({{11{IR[4]}}, IR[4:0]}), .S1(SR2_out), .cs(SR2MUX), .mux_out(SR2MUX_out));
	

	ALUmux ALU_mod(.S0(SR1_out), .S1(SR2MUX_out), .cs(ALUK), .mux_out(ALU_out));
	
	register IR_register(.Clk(Clk), .Reset(Reset_ah), .Load(LD_IR), .D(BUS), .Data_Out(IR));
	
//	register #(3) NZP_register(.Clk(Clk), .Reset(Reset_ah), .Load(LD_CC), .D(NZP_temp), .Data_Out(NZP));
//	
//	register #(1) BEN_register(.Clk(Clk), .Reset(Reset_ah), .Load(LD_BEN), .D(BEN_temp), .Data_Out(BEN));
	BENNZP BENNZP_mod( .BUS(BUS), .IR(IR), .LD_CC(LD_CC), .LD_BEN(LD_BEN), .Clk(Clk), .BEN(BEN));
	
	register MDR_register(.Clk(Clk), .Reset(Reset_ah), .Load(LD_MDR), .D(MDRMUX_out), .Data_Out(MDR));
	
	register MAR_register(.Clk(Clk), .Reset(Reset_ah), .Load(LD_MAR), .D(BUS), .Data_Out(MAR));
	
	miomux MIO_MUX(.S0(BUS), .S1(MDR_In), .cs(MIO_EN), .mux_out(MDRMUX_out));

	LED_control LED_control_mod(.D_in(IR[11:0]), .Clk(Clk), .Reset(Reset_ah), .LD_LED(LD_LED), .LED(LED));
endmodule



module register
				 (input  logic Clk, Reset, Load,
              input  logic [15:0]  D,
              output logic [15:0]  Data_Out);

    always_ff @ (posedge Clk)
    begin
	 	 if (Reset) //notice, this is a sycnrhonous reset, which is recommended on the FPGA
			  Data_Out <= 16'b0;
		 else if (Load)
			  Data_Out <= D;
//		 else
//			  Data_Out <= Data_Out;
		 
    end
	

endmodule


module pcmux (
		input logic [15:0] S0, S1, S2,
		input logic  [1:0] cs,
		output logic [15:0] mux_out
);

	always_comb
		begin
			unique case(cs)
				2'b00: mux_out = S0;
				2'b01: mux_out = S1;
				2'b10: mux_out = S2;		//using a 4:1 mux as a 3:1 mux for lab 1
			endcase
		end
		
endmodule

module miomux (
		input logic [15:0] S0, S1,
		input logic  cs,
		output logic [15:0] mux_out
);
//	logic [15:0] mux_next;
	always_comb
		begin
//			mux_out = mux_next;
			unique case(cs)
				1'b1: mux_out = S1;
				1'b0: mux_out = S0;
//				default: mux_next = mux_out;
			endcase
		end
		
endmodule

module gatemux (
		input logic [15:0] S0, S1, S2, S3,
		input logic  [3:0] cs,
		output logic [15:0] mux_out
);
	always_comb
		begin
			unique case(cs)
				4'b1000: mux_out = S0;
				4'b0100: mux_out = S1;
				4'b0010: mux_out = S2;
				4'b0001: mux_out = S3;
				default: mux_out = 16'b0;
			endcase
		end
		
endmodule



module ALUmux (
		input logic [15:0] S0, S1,
		input logic  [3:0] cs,
		output logic [15:0] mux_out
);
	always_comb
		begin
			unique case(cs)
				4'b00: mux_out = S0 + S1;
				4'b01: mux_out = S0 & S1;
				4'b10: mux_out = ~S0;
				4'b11: mux_out = S0;
			endcase
		end
		
endmodule

module mux_DR_SR1 (						// this is a 2, 3 bit, input mux for SR1 mux and DRmux
		input logic [2:0] S0, S1,
		input logic cs,
		output logic [2:0] mux_out
);
	always_comb
		begin
			unique case(cs)
				1'b1: mux_out = S1;
				1'b0: mux_out = S0;
			endcase
		end
		
endmodule


module mux_4 (
		input logic [15:0] S0, S1, S2, S3,
		input logic  [1:0] cs,
		output logic [15:0] mux_out
);

	always_comb
		begin
			unique case(cs)
				2'b00: mux_out = S0;
				2'b01: mux_out = S1;
				2'b10: mux_out = S2;		//using a 4:1 mux as a 3:1 mux for lab 1
				2'b11: mux_out = S3;
			endcase
		end
		
endmodule

module mux_2 (
		input logic [15:0] S0, S1,
		input logic cs,
		output logic [15:0] mux_out
);

	always_comb
		begin
			unique case(cs)
				1'b0: mux_out = S0;
				1'b1: mux_out = S1;
			endcase
		end
		
endmodule



module registerFile(
	input logic	Clk, Reset_ah, LD_REG,
	input logic [2:0] SR1, SR2, DR,
	input logic [15:0] D,
	output logic [15:0] SR1_out, SR2_out
);

	logic [15:0] Reg [7:0];	//assigning 8 registers of 16 bits
	always_ff @(posedge Clk)
	begin
		if(Reset_ah)		//If reset is high, then reset all the registers
		begin
			Reg[0]<=16'b0;
			Reg[1]<=16'b0;
			Reg[2]<=16'b0;
			Reg[3]<=16'b0;
			Reg[4]<=16'b0;
			Reg[5]<=16'b0;
			Reg[6]<=16'b0;
			Reg[7]<=16'b0;
		end
		if(LD_REG)		//if load register is high, then move into switch case to load the appropriate register
		begin
			unique case(DR)
			3'b000:Reg[0]<=D;
			3'b001:Reg[1]<=D;
			3'b010:Reg[2]<=D;
			3'b011:Reg[3]<=D;
			3'b100:Reg[4]<=D;
			3'b101:Reg[5]<=D;
			3'b110:Reg[6]<=D;
			3'b111:Reg[7]<=D;
			endcase
		end
	end
	
	always_comb
	begin
		unique case(SR1)	//if SR1 is high, then store result in SR1_out
			3'b000:SR1_out=Reg[0];
			3'b001:SR1_out=Reg[1];
			3'b010:SR1_out=Reg[2];
			3'b011:SR1_out=Reg[3];
			3'b100:SR1_out=Reg[4];
			3'b101:SR1_out=Reg[5];
			3'b110:SR1_out=Reg[6];
			3'b111:SR1_out=Reg[7];
		endcase
		unique case(SR2)	//if SR2 is high, then store result in SR2_out
			3'b000:SR2_out=Reg[0];
			3'b001:SR2_out=Reg[1];
			3'b010:SR2_out=Reg[2];
			3'b011:SR2_out=Reg[3];
			3'b100:SR2_out=Reg[4];
			3'b101:SR2_out=Reg[5];
			3'b110:SR2_out=Reg[6];
			3'b111:SR2_out=Reg[7];
		endcase
	end

endmodule


module BENNZP(input logic [15:0] BUS, IR,
					  input logic LD_CC, LD_BEN, Clk,
					  output logic BEN
);

	logic N_set, Z_set, P_set;
	logic N, Z, P;
	logic BEN_temp;
	
	
	always_ff @ (posedge Clk) 
    begin
	
		if(LD_CC) 
        begin
			N_set <= N;
			Z_set <= Z;
			P_set <= P;
		end
		
		if(LD_BEN) 
        begin
			BEN <= BEN_temp;
		end
	
	end
	
	always_comb begin
	
		if(BUS[15] == 1) 
        begin
			N = 1'b1;
			Z = 1'b0;
			P = 1'b0;
		end
		
		else if(BUS == 16'h0000) 
        begin
			N = 1'b0;
			Z = 1'b1;
			P = 1'b0;
		end
		
		else 
        begin
			N = 1'b0;
			Z = 1'b0;
			P = 1'b1;
		end
		
		BEN_temp = (IR[11] & N_set) | (IR[10] & Z_set) | (IR[9] & P_set);
		
	end

endmodule 


module LED_control(input logic [11:0] D_in,
						 input logic Clk, Reset, LD_LED,
						 output logic [11:0] LED
);

	always_ff @ (posedge Clk) 
    begin
	
	if(Reset)
		LED <= 12'h000;
	else if (LD_LED)
		LED <= D_in;
	
	end

endmodule
