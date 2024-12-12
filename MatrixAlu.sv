// Matrix ALU for processor final project
// Jake Helpinstill - 12/05/24
//
// Inputs
//      clk     : clock
//      nRead   : output data to bus (active low)
//      nWrite  : receive data from bus (active low)
//      nReset  : reset to initial state (active low)
//      addr    : 16 bit address. bits [11:0] select data, bits [15:12] select peripheral
//              : (This module has peripheral address 3)
// 
// Input/Outputs
//      bus: 256 bits

module MatrixAlu(clk, bus, addr, nRead, nWrite, nReset);

// recieve signals and commands from the execution unit and the test bench
input logic clk, nRead, nWrite, nReset;
input logic [15:0] addr;

// send or recieve data
inout logic [255:0] bus;

// internal regs
logic [255:0] regs[3];

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
    
    else if(addr[15:12] == mat_en) // read/write on peripheral address match
    begin
        if(~nWrite)
        begin
            if(addr[11:0] == 3) // interpret bus data as command
            begin
                case(bus) // perform matrix operation
                    0: regs[2] <= matMult1(regs[0], regs[1]);   // 4x4 * 4x4 multiply
                    1: regs[2] <= matMult2(regs[0], regs[1]);   // 4x2 * 2x4 multiply
                    2: regs[2] <= matMult3(regs[0], regs[1]);   // 2x4 * 4x2 multiply
                    3: regs[2] <= matAdd(regs[0], regs[1]);     // add
                    4: regs[2] <= matSub(regs[0], regs[1]);     // subtract
                    5: regs[2] <= matTrans(regs[0]);            // transpose
                    6: regs[2] <= matScale(regs[0], regs[1]);   // scale
                    7: regs[2] <= matScale(regs[0], regs[1]);   // scale immediate
                endcase
            end
            else // write bus data to register
                regs[addr[11:0]] <= bus;
            on_bus <= 0;
        end
        else if(~nRead) // output result register on the bus
            on_bus <= 1;
    end
    else // release bus
        on_bus <= 0;
end

// return sum of two 4x4 matrices
function [255:0] matAdd;
    input logic [255:0] a, b; // input matrices a and b
    
    // add each 16 bit int from a to the corresponding int from b
    for(int i = 0; i < 16; i = i + 1)
        matAdd[16*i +: 16] = a[16*i +: 16] + b[16*i +: 16];
endfunction

// return difference between two 4x4 matrices
function [255:0] matSub;
    input logic [255:0] a, b; // input matrices a and b
    
    // subtract each 16 bit int from a to the corresponding int from b
    for(int i = 0; i < 16; i = i + 1)
        matSub[16*i +: 16] = a[16*i +: 16] - b[16*i +: 16];
endfunction

// return 4x4 product of two 4x4 matrices
function [255:0] matMult1;
    input logic [255:0] a, b; // input matrices a and b
    
    // product matrix element ij is the dot product of the jth row of b with the ith column of a
    for(int i = 0; i < 4; i = i + 1)
        for(int j = 0; j < 4; j = j + 1)
            matMult1[16*(4*i + j) +: 16] = 
                a[16*(4*i) +: 16] * b[16*(j) +: 16] + 
                a[16*(4*i+1) +: 16] * b[16*(j) + 64 +: 16] + 
                a[16*(4*i+2) +: 16] * b[16*(j) + 128 +: 16] + 
                a[16*(4*i+3) +: 16] * b[16*(j) + 192 +: 16];
endfunction

// return 4x4 product of a 4x2 matrix by a 2x4 matrix
function [255:0] matMult2;
    input logic [255:0] a, b; // input matrices a and b
    /*
    a (4x2)       b (2x4)       result (4x4)
    | 0 0 a b |   | 0 0 0 0 |   |         |
    | 0 0 c d | * | 0 0 0 0 | = |  (4x4)  |
    | 0 0 e f |   | i j k l |   |         |
    | 0 0 g h |   | m n o p |   |         |
    */    
    for(int i = 0; i < 4; i = i + 1)
        for(int j = 0; j < 4; j = j + 1)
            matMult2[16*(4*i + j) +: 16] = 
                a[16*(4*i+0) +: 16] * b[16*(j) + 0 +: 16] + 
                a[16*(4*i+1) +: 16] * b[16*(j) + 64 +: 16];
endfunction

// return 2x2 product of a 2x4 matrix by a 4x2 matrix
function [255:0] matMult3;
    input logic [255:0] a, b; // input matrices a and b
    /*
    a (2x4)       b (4x2)
    | 0 0 0 0 |   | 0 0 i h |   result (2x2)
    | 0 0 0 0 | * | 0 0 k l | = | q r |
    | a b c d |   | 0 0 m n |   | s t |
    | e f g h |   | 0 0 o p |
    */    
    for(int i = 0; i < 2; i = i + 1)
        for(int j = 0; j < 2; j = j + 1)
            matMult3[16*(2*i + j) +: 16] = 
                a[16*(4*i) +: 16] * b[16*(j) +: 16] + 
                a[16*(4*i+1) +: 16] * b[16*(j) + 64 +: 16] + 
                a[16*(4*i+2) +: 16] * b[16*(j) + 128 +: 16] + 
                a[16*(4*i+3) +: 16] * b[16*(j) + 192 +: 16];
    matMult3[255:64] = '0; // pad 2x2 matrix with zeros in the MSB side to fill 256 bits
endfunction

// return transpose of a 4x4 matrix
function [255:0] matTrans;
    input logic [255:0] a; // input matrix a
    
    // transpose matrix element ij is input matrix element ji 
    for(int i = 0; i < 4; i = i + 1)
        for(int j = 0; j < 4; j = j + 1)
            matTrans[16*(4*i + j) +: 16] = a[16*(4*j + i) +: 16];
endfunction

// return scalar product of a 4x4 matrix by an integer
function [255:0] matScale;
    input logic [255:0] a; // input matrix a
    input logic [31:0] s;  // input scalar s
    
    for(int i = 0; i < 16; i = i + 1)
        matScale[16*i +: 16] = a[16*i +: 16] * s;
endfunction

endmodule