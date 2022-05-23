module pc(
    input [31:0] newpc,
    input clk,
    input reset,
    input PCWrite,
    output [31:0] oldpc
    );
	reg [31:0] _pc;
	
	always@(posedge clk or posedge reset)
	begin
		if(reset) _pc <= 32'h00003000;
		else if(PCWrite==1)
			_pc  <= newpc;
	end
	
	assign oldpc = _pc;
	
endmodule
