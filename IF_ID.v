module IF_ID(
    input clk,
    input rst,
    input flush,
    input ifid_write,
    input[31:0] PC_if,
    input[31:0] Inst_if,
    
    output reg[31:0] PC_id,
    output reg[31:0] Inst_id
);



always @ (posedge clk,posedge rst) begin
    if(rst||flush)
    begin
        PC_id <= 0;
        Inst_id<= 0;
    end
    else if( ifid_write )
    begin
        PC_id <= PC_if;
        Inst_id <= Inst_if;
    end
end
endmodule
