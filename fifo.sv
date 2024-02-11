
module output_fifo (clk, reset, data_in, wr_en, capacity, AXIS_TDATA, AXIS_TVALID, AXIS_TREADY);
	parameter OUTW=28, DEPTH=8;
	localparam LOGDEPTH=$clog2(DEPTH);
	
	input clk, reset, wr_en, AXIS_TREADY;
	input [OUTW-1:0] data_in;
	output logic [OUTW-1:0] AXIS_TDATA;
	output logic AXIS_TVALID;
	output logic [($clog2(DEPTH+1))-1:0] capacity;
	
	logic clearhead, incrhead, cleartail, clearcap, incrcap, decrcap;
	logic incrtail;
	logic [LOGDEPTH-1:0] counthead;
	logic [LOGDEPTH-1:0] counttail, addr;
	logic rd_en;
	
	memory_dual_port #(OUTW, DEPTH) memdual(data_in, AXIS_TDATA, counthead, addr, clk, wr_en);
	
	head #(DEPTH) counterhead (clk, clearhead, incrhead, counthead);
	tail #(DEPTH) countertail (clk, cleartail, incrtail, counttail);
	capacity #(DEPTH) countercapacity (clk, clearcap, incrcap, decrcap, capacity);
	
	
	parameter START = 0, OPERATION = 1;
	logic state, nextState;
	
	always_ff @(posedge clk) begin
		if (reset == 1)
			state <= START;
		else
			state <= nextState;
	end
	
	always_comb begin
		if (state == START)
			nextState = OPERATION;
		else if (state == OPERATION)
			nextState = OPERATION;
		else 
			nextState = START;
	end
	
	always_comb begin
		if (rd_en)
			if (counttail==DEPTH-1)
				addr = 0;
			else 
				addr = counttail+1;
		else 
			addr = counttail;
	end
	
	
	assign AXIS_TVALID = ((state==OPERATION) && (capacity<DEPTH));
	assign rd_en = (AXIS_TREADY==1 && AXIS_TVALID==1);
	assign clearhead = (state==START);
	assign cleartail = (state==START);
	assign clearcap = (state==START);
	assign incrhead = (state==OPERATION && wr_en==1);
	assign incrtail = (state==OPERATION && rd_en==1);
	assign incrcap = (state==OPERATION && rd_en==1 && wr_en==0);
	assign decrcap = (state==OPERATION && wr_en==1 && rd_en==0);
	
	
endmodule 


module memory_dual_port #(
 parameter WIDTH=16, SIZE=64,
 localparam LOGSIZE=$clog2(SIZE)
 )(
 input [WIDTH-1:0] data_in,
 output logic [WIDTH-1:0] data_out,
 input [LOGSIZE-1:0] write_addr, read_addr,
 input clk, wr_en
 );

 logic [SIZE-1:0][WIDTH-1:0] mem;

 always_ff @(posedge clk) begin
 data_out <= mem[read_addr];
 if (wr_en) begin
 mem[write_addr] <= data_in;
 if (read_addr == write_addr)
 data_out <= data_in;
 end
 end
endmodule



module head(clk, clearhead, incrhead, counthead);
	parameter H = 8;
	localparam LOGSIZE = $clog2(H);
	
	input clk, clearhead, incrhead;
	output logic [LOGSIZE-1:0] counthead;
	
	always_ff @(posedge clk) begin
		if (clearhead == 1)
			counthead<=0;
		else if (incrhead==1) begin
			if (counthead==H-1)
				counthead<=0;
			else
				counthead<=counthead+1;
		end
	end
	
endmodule
	

module tail(clk, cleartail, incrtail, counttail);
	parameter T =8;
	localparam LOGSIZE = $clog2(T);
	
	input clk, cleartail, incrtail;
	output logic [LOGSIZE-1:0] counttail;
	
	always_ff @(posedge clk) begin
		if (cleartail == 1)
			counttail<=0;
		else if (incrtail==1) begin
			if (counttail==T-1)
				counttail<=0;
			else
				counttail<=counttail+1;
		end
	end

endmodule	
	

module capacity(clk, clearcap, incrcap, decrcap, countcap);
	parameter C =8;
	localparam LOGSIZE = $clog2(C);
	
	input clk, clearcap, incrcap, decrcap;
	output logic [($clog2(C+1))-1:0] countcap;
	
	always_ff @(posedge clk) begin
		if (clearcap == 1)
			countcap<=C;
		else if (incrcap==1)
			countcap<=countcap+1;
		else if (decrcap==1)
			countcap<=countcap-1;
	end
	
endmodule	






