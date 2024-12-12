// Instruction memory ROM module for final project
// Jake Helpinstill - 12/05/24
//
// Stores the instructions to be read by the processor
//
// Inputs
//      clk     : clock
//      nRead   : output data to bus on matching address (active low)
//      nReset  : reset initial memory data (active low)
//      addr    : 16 bit address. bits [11:0] select data, bits [15:12] select peripheral
//              : (This module has peripheral address 2)
//
// Input/Outputs
//      bus: 256 bits

//*****************************************
// Instructions provided by: Prof. Mark Welker
//*****************************************
// instruction: OPcode :: dest :: src1 :: src2 Each section is 8 bits.
//Stop::FFh::00::00::00
//MMult1::00h::Reg/mem::Reg/mem::Reg/mem
//MMult2::01h::Reg/mem::Reg/mem::Reg/mem
//MMult3::02h::Reg/mem::Reg/mem::Reg/mem
//Madd::03h::Reg/mem::Reg/mem::Reg/mem
//Msub::04h::Reg/mem::Reg/mem::Reg/mem
//Mtranspose::05h::Reg/mem::Reg/mem::Reg/mem
//MScale::06h::Reg/mem::Reg/mem::Reg/mem
//MScaleImm::07h:Reg/mem::Reg/mem::Immediate
//IntAdd::10h::Reg/mem::Reg/mem::Reg/mem
//IntSub::11h::Reg/mem::Reg/mem::Reg/mem
//IntMult::12h::Reg/mem::Reg/mem::Reg/mem
//IntDiv::13h::Reg/mem::Reg/mem::Reg/mem

//*****************************************
// Program provided by: Prof. Mark Welker
//*****************************************
// add the data at location 0 to the data at location 1 and place result in location 2
parameter Instruct1 = 32'h 03_02_00_01; // add first matrix to second matrix store in memory
parameter Instruct2 = 32'h 06_03_00_0a; // scale matrix 1 by whats in location A store in memory
parameter Instruct3 = 32'h 10_10_0a_0b; // add 16 bit numbers in location a to b store in temp register
parameter Instruct4 = 32'h 04_04_03_00; //Subtract the first matrix from the result in step 2 and store the result somewhere else in memory. 
parameter Instruct5 = 32'h 05_05_02_00; //Transpose the result from step 1 store in memory
parameter Instruct6 = 32'h 07_11_03_08; //ScaleImm the result in step 2 by the result from step 3 store in a matrix register
parameter Instruct7 = 32'h 00_06_04_05; //Multiply the result from step 4 by the result in step 5, store in memory. 4x4 * 4x4
parameter Instruct8 = 32'h 01_07_11_05; //Multiply the result from step 6 by the result in step 5, store in memory. 4x2 * 2x4
parameter Instruct9 = 32'h 02_08_05_04; //Multiply the result from step 5 by the result in step 4, store in memory. 2x4 * 4x2

parameter Instruct10 = 32'h 12_0a_01_00;//Multiply the integer value in memory location 0 to location 1. Store it in memory location 0x0A
parameter Instruct11 = 32'h 11_12_0a_01;//Subtract the integer value in memory location 01 from memory location 0x0A and store it in a register
parameter Instruct12 = 32'h 13_0b_07_08;//Divide the result from step 8 by the result in step 9  and store it in location 0x0B
parameter Instruct13 = 32'h FF_00_00_00; // stop

module InstructionMemory(clk, bus, addr, nRead, nReset);
// NOTE the lack of datain and write. This is because this is a ROM model

input logic clk, nRead, nReset;
input logic [15:0] addr;

inout logic [255:0] bus; // 1 - 32 it instructions at a time.

logic [31:0]InstructMemory[13];

// tri-state buffered register for bus communication
logic [255:0] port;
logic on_bus;
assign bus = on_bus ? port : 'z;

always_ff @(negedge clk or negedge nReset)
begin
    if (~nReset) // reset asynchronously
    begin
        port <= 0;
        on_bus <= 0;
        InstructMemory[0] <= Instruct1;  	
        InstructMemory[1] <= Instruct2;  	
        InstructMemory[2] <= Instruct3;
        InstructMemory[3] <= Instruct4;	
        InstructMemory[4] <= Instruct5;
        InstructMemory[5] <= Instruct6;
        InstructMemory[6] <= Instruct7;
        InstructMemory[7] <= Instruct8;
        InstructMemory[8] <= Instruct9;
        InstructMemory[9] <= Instruct10;
        InstructMemory[10] <= Instruct11;
        InstructMemory[11] <= Instruct12;
        InstructMemory[12] <= Instruct13;
    end
    else if(addr[15:12] == rom_en) // read/write if selected by address
    begin
        if(~nRead) begin
            port <= InstructMemory[addr[11:0]];
            on_bus <= 1; // only grab bus on a read
        end else
            on_bus <= 0; // release bus if read signal is high even when selected
    end
    else // release bus on next falling clock
       on_bus <= 0;
end
endmodule


