
module mips( );
    reg clk, reset;
         
    initial begin
        $readmemh( "Test_Instr.txt", IM.IMem ) ; 
        $monitor("PC = 0x%8X, IR = 0x%8X", PC.oldpc, IM.Out );   

        clk = 1 ;
        reset = 0 ;
        #5 reset = 1 ;
        #20 reset = 0 ;
    end
    
    always #50 clk = ~clk;

    //PC
    //input
    wire PCWrite;
    wire [1:0]  PC_sel;
    //output
    wire [31:0] old_PC;

    //npc
    wire [31:0] new_PC;
    wire branch;

    //im
    wire [31:0] Instrl;

    //IF_ID
    //input
    wire flush;
    wire ifid_write;
    //output
    wire [31:0] PC_id;
    wire [31:0] Inst_id;
    

    //extend
    wire ExtOp;
    wire [31:0] ext_out;

    //gpr
    wire [1:0]  MemtoReg;
    wire [31:0] Data_to_Reg;
    wire [1:0]  RegDst;
    wire [4:0]  RegWriteAddr_ex;
    wire RegWrite;
    wire [31:0] grf_out_A;
    wire [31:0] grf_out_B;

    //ctrl
    wire ALUSrcA;
    wire ALUSrcB;
    wire [4:0]  ALUCode;
    wire [31:0] ALU_out;
    wire Jump;

    //ID_EX
    wire stall;
    wire [1:0] WB_MemtoReg_ex;
    wire WB_RegWrite_ex;
    wire MEM_MemWrite_ex;
    wire MEM_MemRead_ex;
    wire EX_ALUSrcA_ex;
    wire EX_ALUSrcB_ex;
    wire [4:0] EX_ALUCode_ex;
    wire [1:0] EX_RegDst_ex;
    wire [31:0] PC_ex;
    wire [31:0] Imm_ex;
    wire [4:0] RsAddr_ex;
    wire [4:0] RtAddr_ex;
    wire [4:0] RdAddr_ex;
    wire [31:0] RsData_ex;
    wire [31:0] RtData_ex;

    //Forwarding
    wire [31:0] RealRs;
    wire [31:0] RealRt;

    //choose Immediate or Reaing from register
    wire [31:0] ALUDataInA;
    wire [31:0] ALUDataInB;


    
    //Forwarding
    wire[1:0] ForwardA;
    wire[1:0] ForwardB;
    //IDForwardUnit
    wire[1:0] ForwardC;
    wire[1:0] ForwardD;
    wire[31:0] IDRealRs;
    wire[31:0] IDRealRt;

    //EX_MEM
    wire [1:0] WB_MemtoReg_mem;
    wire WB_RegWrite_mem;
    wire MEM_MemWrite_mem;
    wire MEM_MemRead_mem;
    wire [4:0] RegWriteAddr_mem;
    wire [31:0] PC_mem;
    wire [31:0] ALUResult_mem;
    wire [31:0] MemWriteData_mem;

    //dm
    wire [31:0] dm_data_out;
    wire MemWrite;
    wire MemRead;

    //MEM_WB
    wire [1:0] WB_MemtoReg_wb;
    wire WB_RegWrite_wb;
    wire [4:0] RegWriteAddr_wb;
    wire [31:0] PC_wb;
    wire [31:0] ALUResult_wb;
    wire [31:0] MemOut_wb;

    //WBtoID
    wire Rs_sel,Rt_sel;
    wire [31:0] Pass_grf_out_A,Pass_grf_out_B;

    //decompose Instruction
    wire[5:0] op;
    wire[5:0] funct;
    wire [4:0] RsAddr_id;
    wire [4:0] RtAddr_id;
    wire [4:0] RdAddr_id;

    assign op = Inst_id[31:26];
    assign funct = Inst_id[5:0];
    assign RsAddr_id = Inst_id[25:21];
    assign RtAddr_id = Inst_id[20:16];
    assign RdAddr_id = Inst_id[15:11];
    
    /**
     * IF Stage
     */
    im  IM(old_PC[11:2],Instrl);
    npc NPC(IDRealRs,old_PC,PC_id,Inst_id,branch,PC_sel,new_PC);
    pc  PC(new_PC,clk,reset,PCWrite,old_PC);

    //IF to ID register, the Flush function being integrated
    IF_ID if_id(clk,reset,flush,ifid_write,old_PC,Instrl,/*output*/PC_id,Inst_id);

    /**
     * ID stage
     */
    //The gpr module is not FIRST WRITE THEN READ so we have to design a third forwaring unit to pass the data to write back to ID for further use
    WBtoID wbtoid(RsAddr_id,RtAddr_id,RegWriteAddr_wb,WB_RegWrite_wb,/*output*/Rs_sel,Rt_sel);

    //Read and write Registers
    gpr GRF(clk,reset,RsAddr_id,RtAddr_id,RegWriteAddr_wb,Data_to_Reg,WB_RegWrite_wb,grf_out_A,grf_out_B);
    //Produce the signals according to op and funct used in other elements
    ctrl CTRL(op,funct,RegDst,ALUSrcA,ALUSrcB,MemRead,RegWrite,MemWrite,MemtoReg,PC_sel,ExtOp,ALUCode,Jump);

    //Forward the data for ID to judge branch
    //WARNING: We actually use the result that may have not been calculated
    //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    Forward_3mux IDRealRS(grf_out_A,ALUResult_mem,ALU_out/*NOT SAFE*/,ForwardC,/*output*/IDRealRs);
    Forward_3mux IDRealRT(grf_out_B,ALUResult_mem,ALU_out/*NOT SAFE*/,ForwardD,/*output*/IDRealRt);
    //Extend the Immediate
    extend EXTEND(ExtOp,Inst_id[15:0],/*output*/ext_out);
    //Choose which register (rt, rd, $ra) is the real one to write back
    RegDst_mux REGDST(EX_RegDst_ex,RtAddr_ex,RdAddr_ex,/*output*/RegWriteAddr_ex);
    //Provide the real data in the Register
    mux2_32 writebackGrf_muxA(Rs_sel,grf_out_A,Data_to_Reg,/*output*/Pass_grf_out_A);
    mux2_32 writebackGrf_muxB(Rt_sel,grf_out_B,Data_to_Reg,/*output*/Pass_grf_out_B);
    
    //A small ALU to test whether the condition is satisfied to branch
    ZeroTest zeroTest(IDRealRs,IDRealRt,ALUCode,branch);

    //ID to EX register, with Stall function integrated
    ID_EX id_ex(clk,rst,stall,MemtoReg,RegWrite,MemWrite,MemRead,ALUCode,ALUSrcA,ALUSrcB,RegDst,RsAddr_id,RtAddr_id,RdAddr_id,PC_id,ext_out,Pass_grf_out_A,Pass_grf_out_B,/*output*/WB_MemtoReg_ex,WB_RegWrite_ex,MEM_MemWrite_ex,MEM_MemRead_ex,EX_ALUCode_ex,EX_ALUSrcA_ex,EX_ALUSrcB_ex,EX_RegDst_ex,RsAddr_ex,RtAddr_ex,RdAddr_ex,PC_ex,Imm_ex,RsData_ex,RtData_ex);

    /**
     * EX stage
     */
    //detect whether we should stall or flush the pipeline
    HazardDetector hazarddetector(reset,branch,Jump,RsAddr_id,RtAddr_id,RtAddr_ex,MEM_MemRead_ex,RegWriteAddr_ex,/*output*/PCWrite,ifid_write,stall,flush);
    
    //detect whether we should forward the data
    Forwarding forwarding(WB_RegWrite_mem,WB_RegWrite_wb,WB_RegWrite_ex/*NOT SAFE*/,RegWriteAddr_mem,RegWriteAddr_wb,RegWriteAddr_ex/*NOT SAFE*/,RsAddr_ex,RtAddr_ex,RsAddr_id,RtAddr_id,/*output*/ForwardA,ForwardB,ForwardC,ForwardD);

    //Choose from the data (Register, Memory, ALUResult)
    Forward_3mux alua(RsData_ex,Data_to_Reg,ALUResult_mem,ForwardA,/*output*/RealRs);//Forward choose A
    Forward_3mux alub(RtData_ex,Data_to_Reg,ALUResult_mem,ForwardB,/*output*/RealRt);//Forward choose B
    //Choose from data in Register or in Immediate
    mux2_32 aluSrcA(EX_ALUSrcA_ex,RealRs,{27'b0, Imm_ex[10:6]}/*Shamt*/,/*output*/ALUDataInA);
    mux2_32 aluSrcB(EX_ALUSrcB_ex,RealRt,Imm_ex,/*output*/ALUDataInB);
    //ALU
    alu ALU(ALUDataInA, ALUDataInB, EX_ALUCode_ex,/*output*/ALU_out,/*empty*/);

    //EX to MEM register
    EX_MEM ex_mem(clk,reset,WB_MemtoReg_ex,WB_RegWrite_ex,MEM_MemWrite_ex,MEM_MemRead_ex,RegWriteAddr_ex,PC_ex,ALU_out,RealRt,/*output*/WB_MemtoReg_mem,WB_RegWrite_mem,MEM_MemWrite_mem,MEM_MemRead_mem,RegWriteAddr_mem,PC_mem,ALUResult_mem,MemWriteData_mem);

    /**
     * MEM Stage
     */
    dm DM(ALUResult_mem,MemWriteData_mem,MEM_MemWrite_mem,MEM_MemRead_mem,clk,reset,/*output*/dm_data_out);
    
    //MEM to WB register
    MEM_WB mem_wb(clk,reset,WB_MemtoReg_mem,WB_RegWrite_mem,RegWriteAddr_mem,PC_mem,ALUResult_mem,dm_data_out,/*output*/WB_MemtoReg_wb,WB_RegWrite_wb,RegWriteAddr_wb,PC_wb,ALUResult_wb,MemOut_wb);

    /**
     * WB Stage
     */
    //Choose from the data (ALUResult, Memory, old_PC) to write to register
    DatatoReg_mux datatoreg(WB_MemtoReg_wb,ALUResult_wb,MemOut_wb,/*output*/PC_wb,Data_to_Reg);
endmodule