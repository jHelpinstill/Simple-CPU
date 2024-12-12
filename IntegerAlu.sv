// Integer ALU for processor final project
// Jake Helpinstill - 12/05/24
//
// Inputs
//      clk     : clock
//      nRead   : output data to bus on matching address (active low)
//      nWrite  : receive data from bus on matching address (active low)
//      nReset  : reset to initial state (active low)
//      addr    : 16 bit address. bits [11:0] select data, bits [15:12] select peripheral
//              : (This module has peripheral address 5)
// 
// Input/Outputs
//      bus: 256 bits

module IntegerAlu(clk, bus, addr, nRead, nWrite, nReset);

// recieve signals and commands from the execution unit and the test bench
input logic clk, nRead, nWrite, nReset;
input logic [15:0] addr;

// send or recieve data
inout logic [255:0] bus;

// internal regs
logic [15:0] regs[3];
// 0 : source 1
// 1 : source 2
// 2 : result

// register 3 is tri-state buffered for writing to bus
logic on_bus;
assign bus = on_bus ? regs[2] : 'z;

always_ff @ (negedge clk or negedge nReset)
begin
    if(~nReset) // reset asynchronously
    begin
        regs[0] <= '0;
        regs[1] <= '0;
        regs[2] <= '0;
    end
    
    else if(addr[15:12] == int_en) // read/write
    begin
        if(~nWrite)
        begin
            if(addr[11:0] == 3) // interpret bus data as command
            begin
                case(bus) // perform arithmetic
                    0: regs[2] <= regs[0] + regs[1]; // add
                    1: regs[2] <= regs[0] - regs[1]; // sub
                    2: regs[2] <= regs[0] * regs[1]; // mul
                    3: regs[2] <= regs[0] / regs[1]; // div
                endcase
            end
            else // write bus data to register
                regs[addr[11:0]] <= bus;
            on_bus <= 0;
        end
        else if(~nRead) // output result register on the bus
            on_bus <= 1;
    end
    else
        on_bus <= 0;
end

endmodule