/**
 * WARNING: This code is not safe, it use the result that may has not been caculated
 */
module Forwarding(
    input RegWrite_mem,
    input RegWrite_wb,
    input RegWrite_ex,//!!!!!!!!NOT SAFE!!!!!!!!!!!
    input[4:0] RegWriteAddr_mem,
    input[4:0] RegWriteAddr_wb,
    input[4:0] RegWriteAddr_ex,//!!!!!!!!NOT SAFE!!!!!!!!!!!
    input[4:0] RsAddr_ex,
    input[4:0] RtAddr_ex,
    //Forwarding in ID
    input[4:0] RsAddr_id,
    input[4:0] RtAddr_id,

    output reg[1:0] ForwardA,
    output reg[1:0] ForwardB,
    //Forwarding in ID
    output reg[1:0] ForwardC,
    output reg[1:0] ForwardD
);

    

    always @(*)
    begin
        //Forwarding in EX
        if(RegWrite_mem&&(RegWriteAddr_mem!=0)&&(RegWriteAddr_mem==RsAddr_ex))
            ForwardA=2'b10;
        else if(RegWrite_wb&&(RegWriteAddr_wb!=0)&&(RegWriteAddr_wb==RsAddr_ex))
            ForwardA=2'b01;
        else
            ForwardA=2'b00;
        if(RegWrite_mem&&(RegWriteAddr_mem!=0)&&(RegWriteAddr_mem==RtAddr_ex))
            ForwardB=2'b10;
        else if(RegWrite_wb&&(RegWriteAddr_wb!=0)&&(RegWriteAddr_wb==RtAddr_ex))
            ForwardB=2'b01;
        else
            ForwardB=2'b00;

        //Forwarding in ID NOT SAFE!!!!!!!!!!
        if(RegWrite_ex&&(RegWriteAddr_ex!=0)&&(RegWriteAddr_ex==RsAddr_id))
            ForwardC=2'b10;
        else if(RegWrite_wb&&(RegWriteAddr_wb!=0)&&(RegWriteAddr_wb==RsAddr_id))
            ForwardC=2'b01;
        else
            ForwardC=2'b00;
        if(RegWrite_ex&&(RegWriteAddr_ex!=0)&&(RegWriteAddr_ex==RtAddr_id))
            ForwardD=2'b10;
        else if(RegWrite_wb&&(RegWriteAddr_wb!=0)&&(RegWriteAddr_wb==RtAddr_id))
            ForwardD=2'b01;
        else
            ForwardD=2'b00;
    end
endmodule