//It is not WRITE FIRST READ LAST so we have to forward the data we have beening writing to ID
module WBtoID(
	input [4:0]RsAddr_id,
	input [4:0]RtAddr_id,
	input [4:0]RegWriteAddr_wb,
	input RegWrite_wb,

	output reg Rs_sel,
	output reg Rt_sel
);
	always@(*)
	begin
		if(RegWrite_wb && (RegWriteAddr_wb != 0) && (RegWriteAddr_wb == RsAddr_id))
			Rs_sel <= 1;
		else
			Rs_sel = 0;

		if(RegWrite_wb && (RegWriteAddr_wb != 0) && (RegWriteAddr_wb == RtAddr_id))
			Rt_sel <= 1;
		else
			Rt_sel <= 0;
	end
endmodule