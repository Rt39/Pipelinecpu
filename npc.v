`include "ctrl_encode_def.v"

module npc(
    input [31:0] IDRealRs,//outa Gpr[rs]
    input [31:0] oldPC,
    input [31:0] id_pc,
    input [31:0] Instr,
	input beq_zero,
    input [1:0] PC_sel,// next pc operation
    output reg [31:0] newPC
    );

	always @(oldPC or Instr or beq_zero or PC_sel or IDRealRs)
    begin
		case(PC_sel)
			2'b00: newPC = oldPC + 4;
			2'b01:
				if(beq_zero == 1) newPC = id_pc + 4 + {{14{Instr[15]}},Instr[15:0],2'b00};//beq bne
				else newPC = oldPC + 4;	
			2'b10:	 newPC = {id_pc[31:28], Instr[25:0], 2'b00};//j jal
            2'b11:   newPC = IDRealRs;// jr 直接从对应寄存器中读取指令,即跳转到由寄存器rs指定的指令
		endcase
        
	end	 

endmodule