// RAM module for final project
// Jake Helpinstill - 12/05/24
//
// Provides memory to store data for the processor during program execution
//
// Inputs
//      clk     : clock
//      nRead   : output data to bus on matching address (active low)
//      nWrite  : receive data from bus on matching address (active low)
//      nReset  : reset initial memory data (active low)
//      addr    : 16 bit address. bits [11:0] select data, bits [15:12] select peripheral
//              : (This module has peripheral address 0)
//
// Input/Outputs
//      bus: 256 bits

module MainMemory(clk, bus, addr, nRead, nWrite, nReset);

// recieve signals and commands from the execution unit and the test bench
input logic clk, nRead, nWrite, nReset;
input logic [15:0] addr;

// send or recieve data
inout logic [255:0] bus;

// internal regs
logic [255:0]MainMemory[12];

// tri-state buffered register for bus communication
logic [255:0] port;
logic on_bus;
assign bus = on_bus ? port : 'z;

always_ff @(negedge clk or negedge nReset)
begin
	if (~nReset) // reset asynchronously
	begin
	   on_bus <= 0;
       MainMemory[0] <= 256'h0009_000c_0008_0007_000c_0010_000d_0009_000B_0009_0006_000d_000d_0005_000e_0006;
       MainMemory[1] <= 256'h0007_0005_0011_0009_000c_0008_000e_0007_0010_0009_000c_000b_000c_0007_0009_0006;
       MainMemory[2] <= '0;
       MainMemory[3] <= '0;
       MainMemory[4] <= '0;
       MainMemory[5] <= '0;
       MainMemory[6] <= '0;
       MainMemory[7] <= '0;
       MainMemory[8] <= '0;
       MainMemory[9] <= '0;
       MainMemory[10] <= 256'h9;
       MainMemory[11] <= 256'ha;
       MainMemory[12] <= '0;
       MainMemory[13] <= '0;
	end
	
	else if(addr[15:12] == ram_en) // read/write if selected by address
	begin
	   if(~nWrite) begin
	       MainMemory[addr[11:0]] <= bus;
	       on_bus <= 0;
	   end
	   else if(~nRead) begin
	       port <= MainMemory[addr[11:0]];
	       on_bus <= 1;
	   end
	end
	
	else // release bus on next falling clock
	   on_bus <= 0;
end
endmodule


