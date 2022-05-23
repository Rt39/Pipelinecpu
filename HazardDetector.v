module HazardDetector(
    input rst,
    input Branch,
    input Jump,
    input[4:0] RsAddr_id,
    input[4:0] RtAddr_id,
    input[4:0] RtAddr_ex,
    input MEM_MemRead_ex,
    input [4:0]RegWriteAddr_ex,
    
    output reg PCWrite,
    output reg IFIDWrite,
    output reg stall,
    output reg flush
);

    always @(posedge rst)begin
            PCWrite <= 1;
            IFIDWrite <= 1;
            stall <= 0;
            flush <= 0;
    end
    always @(*)
    begin
        if(MEM_MemRead_ex&&(RegWriteAddr_ex != 0)
		   &&((RtAddr_ex==RsAddr_id)||(RtAddr_ex==RtAddr_id)))
        begin
            PCWrite<=0;
            IFIDWrite<=0;
            stall<=1;
            flush <= 0;
        end
        else if(Branch||Jump) begin
            //let instr to 0
            flush <= 1;
        end
        else 
        begin
            PCWrite <= 1;
            IFIDWrite <= 1;
            stall <= 0;
            flush <= 0;
        end
    end
endmodule