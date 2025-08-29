`timescale 1ns / 1ps

module tb;
    reg clk, reset;
    wire scl, sda;
    
    pullup(scl);
    pullup(sda);
    // Master inputs
    reg [7:0] writeData, readData;
    reg rw;
    reg [6:0] targetAddr;

    // Master instantiation
    master uut_master(
        .clk(clk),
        .writeData(writeData),
        .rw(rw),
        .targetAddr(targetAddr),
        .scl(scl),
        .sda(sda)
    );

//     Slave instantiation
    slave uut_slave(
        .scl(scl),
        .sda(sda)
    );
    
    // Clock generation
    always #1 clk = ~clk;
    initial begin
        clk = 0;
        uut_master.reset = 1'b1;
        uut_master.initiate = 1'b0;
        
    end

    
    initial begin
        #50 ;

        rw = 1'b1; // Read
//        rw = 1'b0; // Write
        writeData = 8'b11001100;
        targetAddr = 7'd100;// 1100100
        uut_master.reset = 1'b0;
        #2000;
        $finish;
    end
endmodule
