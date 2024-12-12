
// Mark W. Welker
// HDL 4321 Spring 2023
// Matrix addition assignment top module
//
// Main memory MUST be allocated in the mainmemory module as per teh next line.
//  logic [255:0]MainMemory[12]; // this is the physical memory
//



module top ();

wire [255:0] DataBus;
logic nRead,nWrite,nReset,Clk;
logic [15:0] address;

logic Fail;

InstructionMemory  U1(Clk,DataBus, address, nRead,nReset);

MainMemory  U2(Clk,DataBus, address, nRead,nWrite, nReset);

Execution  U3(Clk,DataBus, address, nRead,nWrite, nReset);

MatrixAlu  U4(Clk,DataBus, address, nRead,nWrite, nReset);

IntegerAlu  U5(Clk,DataBus, address, nRead,nWrite, nReset);

TestMatrix  UTest(Clk,nReset);

  initial begin //. setup to allow waveforms for edaplayground
   $dumpfile("dump.vcd");
   $dumpvars(1);
    Fail = 0; // SETUP TO PASS TO START 
 end

always @(DataBus) begin // this block checks to make certain the proper data is in the memory.
		if (DataBus[31:0] == 32'hff000000)
// we are about to execute the stop
begin 
// Print out the entire contents of main memory so I can copy and paste.
			$display ( "memory location 0 = %h", U2.MainMemory[0]);
			$display ( "memory location 1 = %h", U2.MainMemory[1]);
			$display ( "memory location 2 = %h", U2.MainMemory[2]);
			$display ( "memory location 3 = %h", U2.MainMemory[3]);
			$display ( "memory location 4 = %h", U2.MainMemory[4]);
			$display ( "memory location 5 = %h", U2.MainMemory[5]);
			$display ( "memory location 6 = %h", U2.MainMemory[6]);
			$display ( "memory location 7 = %h", U2.MainMemory[7]);
			$display ( "memory location 8 = %h", U2.MainMemory[8]);
			$display ( "memory location 9 = %h", U2.MainMemory[9]);
			$display ( "memory location 10 = %h", U2.MainMemory[10]);
			$display ( "memory location 11 = %h", U2.MainMemory[11]);
			$display ( "memory location 12 = %h", U2.MainMemory[12]);
			$display ( "memory location 13 = %h", U2.MainMemory[13]);

			$display ( "Imternal Reg location 0 = %h", U3.InternalReg[0]);
			$display ( "Internal reg location 1 = %h", U3.InternalReg[1]);
			$display ( "Internal reg location 2 = %h", U3.InternalReg[2]);
			$display ( "Internal reg location 3 = %h", U3.InternalReg[3]);
			
		if (U2.MainMemory[0] == 256'h0009000c00080007000c0010000d0009000b00090006000d000d0005000e0006)
			$display ( "memory location 0 is Correct");
		else begin Fail = 1; $display ( "memory location 0 is Wrong"); end
		if (U2.MainMemory[1] == 256'h0007000500110009000c0008000e000700100009000c000b000c000700090006)
			$display ( "memory location 1 is Correct");
		else begin Fail = 1;$display ( "memory location 1 is Wrong"); end
		if (U2.MainMemory[2] == 256'h001000110019001000180018001b0010001b0012001200180019000c0017000c)
			$display ( "memory location 2 is Correct");
		else begin Fail = 1;$display ( "memory location 2 is Wrong"); end
		if (U2.MainMemory[3] == 256'h0051006c0048003f006c00900075005100630051003600750075002d007e0036)
			$display ( "memory location 3 is Correct");
		else begin Fail = 1;$display ( "memory location 3 is Wrong"); end
		if (U2.MainMemory[4] == 256'h0048006000400038006000800068004800580048003000680068002800700030)
			$display ( "memory location 4 is Correct");
		else begin Fail = 1;$display ( "memory location 4 is Wrong"); end
		if (U2.MainMemory[5] == 256'h00100018001b0019001100180012000c0019001b00120017001000100018000c)
			$display ( "memory location 5 is Correct");
		else begin Fail = 1;$display ( "memory location 5 is Wrong"); end
		if (U2.MainMemory[6] == 256'h14a01a00181813e81d28247821301c1815781a901b78152817181c501a281858)
			$display ( "memory location 6 is Correct");
		else begin Fail = 1;$display ( "memory location 6 is Wrong"); end
		if (U2.MainMemory[7] == 256'h0239025b020a01f301ce01ea01a4019601dc01f401e001980141015301320117)
			$display ( "memory location 7 is Correct");
		else begin Fail = 1;$display ( "memory location 7 is Wrong"); end
		if (U2.MainMemory[8] == 256'h0000000000000000000000000000000000000000000000001ea818b014401400)
			$display ( "memory location 8 is Correct");
		else begin Fail = 1;$display ( "memory location 8 is Wrong"); end
		if (U2.MainMemory[9] == 256'h0000000000000000000000000000000000000000000000000000000000000000)
			$display ( "memory location 9 is Correct");
		else begin Fail = 1;$display ( "memory location 9 is Wrong"); end
		if (U2.MainMemory[10][15:0] == 16'h0024)
			$display ( "memory location 10 is Correct");
		else begin Fail = 1;$display ( "memory location 10 is Wrong"); end
		if (U2.MainMemory[11][15:0] == 16'h0000)
			$display ( "memory location 11 is Correct");
		else begin Fail = 1;$display ( "memory location 11 is Wrong"); end


		if (U3.InternalReg[0][15:0] == 16'h0013)
			$display ( "Interal reg location 0 is Correct");
		else begin Fail = 1; $display ( "Internal Register 0 is Wrong"); end
		if (U3.InternalReg[1] == 256'h02880360024001f80360048003a802880318028801b003a803a8016803f001b0)
			$display ( "Internal Reg location 1 is Correct");
		else begin Fail = 1; $display ( "Internal Register 1 is Wrong"); end
		if (U3.InternalReg[2][15:0] == 16'h001e)
			$display ( "Internal Reg location 2 is Correct");
		else begin Fail = 1; $display ( "Internal Register 2 is Wrong"); end

        if (Fail) begin
        $display("********************************************");
        $display(" Project did not return the proper values");
        $display("********************************************");
        end
        else begin
        $display("********************************************");
        $display(" Project PASSED memory check");
        $display("********************************************");
        end
        
        end

end


endmodule


	
	

