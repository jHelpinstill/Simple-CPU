// Execution module for processor final project
// Jake Helpinstill - 12/05/24
//
// Inputs
//      clk     : clock signal
//      nReset  : reset to initial state (active low)
//      addr    : 16 bit address: bits [11:0] select data, bits [15:12] select peripheral
//
// Outputs
//      nRead   : command selected peripheral to be read from (active low)
//      nWrite  : command selected peripheral to be written to (active low)
// 
// Input/Outputs
//      bus: 256 bits

//opcodes
parameter stop      = 8'hFF;
parameter MMult1    = 8'h00;
parameter MMult2    = 8'h01;
parameter MMult3    = 8'h02;
parameter Madd      = 8'h03;
parameter Msub      = 8'h04;
parameter Mtrans    = 8'h05;
parameter Mscale    = 8'h06;
parameter Mscalei   = 8'h07;
parameter Iadd      = 8'h10;
parameter Isub      = 8'h11;
parameter Imul      = 8'h12;
parameter Idiv      = 8'h13;

// peripheral module addresses (top four bits of address)
parameter ram_en = 4'h0;
parameter reg_en = 4'h1;
parameter rom_en = 4'h2;
parameter mat_en = 3'h3;
parameter int_en = 4'h5;

module Execution(clk, bus, addr, nRead, nWrite, nReset);

// single bit inputs
input logic clk, nReset;

// execution module controls the read, write, and address signals
output logic nRead, nWrite;
output logic [15:0] addr;

// 256 bit main bus
inout logic [255:0] bus;

logic [31:0] instruction, pc; // pc: program counter
logic [255:0] InternalReg[3]; // 3 full-width internal registers

// tri-state buffered register for bus communication
logic [255:0] port;
logic on_bus;
assign bus = on_bus ? port : 'z;

// executor states for sm
enum { fetch, load1, load2, load_reg1, load_reg2, alu1, alu2, alu_imm, alu_cmd, load_result, store, halt } state;
/*
    fetch:      read next instruction
    load1:      read first operand from memory
    load2:      read second operand from memory
    load_reg1:  read first operand from internal register
    load_reg2:  read second operand from internal register
    alu1:       write first operand to int or matrix ALU
    alu2:       write second operand to int or matrix ALU (for multi-operand instructions)
    alu_imm:    write immediate instruction operand to either ALU
    alu_cmd:    send instruction command to either ALU
    load_result: read ALU operation result from either ALU
    store:      store result either in RAM or an internal register
    halt:       stop the processor
*/

// state machine output logic
always_comb
begin
    case(state)
        fetch: begin
            on_bus = 0; // release bus
            nRead = 0; // read
            nWrite = 1;
            addr[15:12] = rom_en; // select instruction memory
            addr[11:0] = pc; // instruction location
            instruction = bus; // grab instruction
        end
        load1: begin
            on_bus = 0; // release bus
            nRead = 0; // read
            nWrite = 1;
            addr[15:12] = ram_en; // select memory
            addr[11:0] = instruction[15:8]; // source 1 address
            port = bus; // grab source 1 from bus
        end
        load_reg1: begin
            port = InternalReg[instruction[11:8]];
            nRead = 1;
            nWrite = 1; // don't read or write. must wait for instruction ROM to give up the bus
        end
        alu1: begin
            on_bus = 1; // take bus
            nRead = 1;
            nWrite = 0; // write
            addr[15:12] = instruction[28] ? int_en : mat_en; // select either int or mat ALU
            addr[11:0] = 0; // source 1 slot in ALU
        end
        load2: begin
            on_bus = 0; // release bus
            nRead = 0; // read
            nWrite = 1; 
            addr[15:12] = ram_en;
            addr[11:0] = instruction[7:0]; // source 2 address
            port = bus; // grab source 2 from bus
        end
        load_reg2: begin
            port = InternalReg[instruction[3:0]];
            on_bus = 1; // take bus
            nRead = 1;
            nWrite = 0; // write
            addr[15:12] = instruction[28] ? int_en : mat_en; // select either int or mat ALU
            addr[11:0] = 1; // source 1 slot in ALU
        end
        alu2: begin
            on_bus = 1; // take bus
            nRead = 1;
            nWrite = 0; // write
            addr[15:12] = instruction[28] ? int_en : mat_en; // select either int or mat ALU
            addr[11:0] = 1; // source 2 slot in ALU
        end
        alu_imm: begin
            on_bus = 1;
            nRead = 1;
            nWrite = 0; // write
            addr[15:12] = instruction[28] ? int_en : mat_en; // select either int or mat ALU
            addr[11:0] = 1; // source 2 slot in ALU
            port = instruction[7:0];
        end
        alu_cmd: begin
            addr[11:0] = 3; // command address for ALU
            port = instruction[27:24]; // command code
        end
        load_result: begin
            on_bus = 0;
            nRead = 0; // read
            nWrite = 1;
            addr[11:0] = 2; // result address for ALU
            port = bus; // store result in output register
        end
        store: begin
            if(instruction[20]) begin
                nRead = 1;
                nWrite = 1;
                InternalReg[instruction[19:16]] = port;
            end else begin
                on_bus = 1; // take bus
                nRead = 1;
                nWrite = 0; // write
                addr[15:12] = ram_en; // select ram
                addr[11:0] = instruction[19:16]; // destination address
            end
        end
        halt: $stop;
    endcase
end

// state machine sequential logic: trigger on positive clock edge (peripheral modules all trigger on negative clock edge)
always_ff @ (posedge clk or negedge nReset)
begin
    if(~nReset) // asynchronous reset
    begin
        state <= fetch;
        on_bus <= '0;
        instruction <= '0;
        pc <= '0;
        port <= '0;
        InternalReg[0] <= '0;
        InternalReg[1] <= '0;
        InternalReg[2] <= '0;
    end else
    begin 
        case(state)
            fetch: begin
                pc <= pc + 1; // increment program counter
                if(instruction[31:24] == stop) // opcode stop: go to halt
                    state <= halt;
                else state <= instruction[12] ? load_reg1 : load1; // load_reg1 if source 1 address is an internal register
                $display ( ">> fetched instruction: %h", instruction);
                case(instruction[31:24])
                    stop   : $display("opcode: stop   ");
                    MMult1 : $display("opcode: MMult1 ");
                    MMult2 : $display("opcode: MMult2 ");
                    MMult3 : $display("opcode: MMult3 ");
                    Madd   : $display("opcode: Madd   ");
                    Msub   : $display("opcode: Msub   ");
                    Mtrans : $display("opcode: Mtrans ");
                    Mscale : $display("opcode: Mscale ");
                    Mscalei: $display("opcode: Mscalei");
                    Iadd   : $display("opcode: Iadd   ");
                    Isub   : $display("opcode: Isub   ");
                    Imul   : $display("opcode: Imul   ");
                    Idiv   : $display("opcode: Idiv   ");
                endcase
            end
            load1: begin
                state <= alu1;
                $display ( "loaded value %h from ram address %h", port, instruction[15:8]);
            end
            load_reg1: begin
                state <= alu1;
                $display ( "loaded value %h from register address %h", port, instruction[11:8]);
            end
            alu1: begin
                case(instruction[31:24]) // switch on opcode:
                    Mtrans: state <= alu_cmd;   // matrix transpose: single operand operation, skip second load
                    Mscalei: state <= alu_imm;  // matrix scale immediate: go to ALU immediate load
                    default: state <= instruction[4] ? load_reg2 : load2; // load_reg2 if source 2 address is an internal register
                endcase
                $display( "stored value %h in %s ALU", port, instruction[28] ? "int" : "mat");
            end
            load2: begin
                state <= alu2;
                $display ( "loaded value %h from ram address %h", port, instruction[7:0]);
            end
            load_reg2: begin
                state <= alu_cmd;
                $display ( "loaded value %h from register address %h", port, instruction[3:0]);
            end
            alu2: begin
                state <= alu_cmd;
                $display( "stored value %h in %s ALU", port, instruction[28] ? "int" : "mat");
            end
            alu_imm: begin
                state <= alu_cmd;
                $display( "stored immediate value %h in %s ALU", port, instruction[28] ? "int" : "mat");
            end            
            alu_cmd: begin
                state <= load_result;
                $display( "sent command to %s ALU", instruction[28] ? "int" : "mat");
            end
            load_result: begin
                state <= store;
                $display( "loaded result %h from %s ALU", port, instruction[28] ? "int" : "mat");
            end
            store: begin
                state <= fetch;
                $display( "stored result %h in %s at address %h", port, instruction[20] ? "reg" : "ram",  instruction[19:16]);
            end
            halt: $stop;
        endcase
    end
            
end

endmodule