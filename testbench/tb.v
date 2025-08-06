`timescale 1ns / 1ps

module tb;
    reg clk, reset;
    wire scl, sda;

    // Master inputs
    reg [7:0] data_write;
    reg rw;
    reg [6:0] target_address;

    // Master instantiation
    master uut_master(
        .clk(clk),
        .reset(reset),
        .data_write(data_write),
        .rw(rw),
        .target_address(target_address),
        .scl_m(scl),
        .sda_m(sda)
    );

    // Slave instantiation
    slave uut_slave(
        .scl_s(scl),
        .sda_s(sda)
    );

    // Clock generation
    initial begin
        clk = 0;
        reset = 1;
        forever #1 clk = ~clk;
    end
    
    always @(uut_master.state) begin 
        if (uut_master.state == 4'b1000) begin
          $display("Stopping simulation: state reached %b at time %t", uut_master.state, $time);
          $finish; // Stops the simulation
        end
    end
    
    initial begin
        #10 reset = 0;
        rw = 0; // Write
        data_write = 8'b11001100;
        target_address = 7'b1101111;
    end
endmodule
