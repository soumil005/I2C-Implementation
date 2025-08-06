`timescale 1ns / 1ps

module master(clk, reset, data_write, rw, target_address, scl_m, sda_m);
    parameter IDLE = 4'b0000, START = 4'b0001, ADDR = 4'b0010, READ_ACK = 4'b0011, READ_DATA = 4'b0100, WRITE_DATA = 4'b0101, 
    READ_ACK2 = 4'b0110, WRITE_ACK = 4'b0111, STOP = 4'b1000;
    
    
    input clk, reset;
    input [7:0] data_write;
    input rw;
    input [6:0] target_address;
    
    inout scl_m;
    inout sda_m;
    
    reg [3:0] state = IDLE;
    reg [3:0] addr_count;
    reg [3:0] data_count;
    reg [7:0] address;
    reg drive_scl = 0;
    reg enable = 0;
    reg [3:0] counter = 0;
    
    reg scl = 1;
    reg sda;
    
    assign scl_m = (drive_scl == 1) ? scl : 1;
    assign sda_m = (enable == 1) ? sda : 1'bz;
    
    always@(posedge clk) begin
        if(counter == 9) begin
            counter <= 0;
            scl <= ~scl;
        end
        else begin
            counter <= counter + 1;
        end
    end
    
    always@(posedge scl) begin
        if(reset == 0 && state == IDLE) begin
            state <= START;
        end
        else state <= IDLE;
    end
    
    always@(negedge scl) begin
        if(reset) drive_scl <= 0;
        else begin
            if(state == IDLE || state == START || state == STOP) drive_scl <= 0;
            else drive_scl <= 1;
        end
    end
    
    always@(negedge scl) begin            // SIGNAL CHANGES
            case(state)
                IDLE: begin
                    drive_scl <= 0;
                    enable <= 0;
                end
                
                START: begin
                    enable <= 1;
                    sda <= 0;
                end
                
                ADDR: begin
                    sda <= address[addr_count - 1];
                end
                
                READ_ACK: begin
                    enable <= 0;
                end
                
                WRITE_DATA: begin
                    enable <= 1;
                    sda <= data_write[data_count - 1];
                end
                
                READ_ACK2: begin
                    enable <= 0;
                end
                
                STOP: begin
                    enable <= 1;
                    sda <= 1;
                end
            endcase
    end
    
    always@(posedge scl) begin
        case(state)
            START: begin
                if(reset == 0) begin
                    addr_count <= 4'b1000;
                    address <= {target_address, rw};
                    state <= ADDR;
                end
                else state <= START;
            end
            ADDR: begin
                if(reset == 0 && addr_count == 4'b0000) begin
                    state <= READ_ACK;
                end
                else if(reset == 0 && addr_count != 4'b0000) begin
                    state <= ADDR;
                    addr_count <= addr_count - 1;
                end
                else state <= IDLE;
            end
            
            READ_ACK: begin
                if(reset == 0) begin
                    if(sda_m == 1'b0 && rw == 0) begin
                        data_count <= 4'b1000;
                        state <= WRITE_DATA;
                    end
                    else if(sda_m == 1'b0 && rw == 1) begin
                        data_count <= 4'b1000;
                        state <= READ_DATA;
                    end
                end
            end
            
            WRITE_DATA: begin
                if(reset == 0 && data_count == 4'b0000) begin
                    state <= READ_ACK2;
                end
                else if(reset == 0 && data_count != 4'b0000) begin
                    state <= WRITE_DATA;
                    data_count <= data_count - 1;
                end
                else state <= IDLE;
            end
            
            READ_ACK2: begin
                if(reset == 0) begin
                    if(sda_m == 1'b0) begin
                        state <= STOP;
                    end
                    else state <= IDLE;
                end
            end
            
            STOP: begin
                if(reset == 0) state <= START;
                else if(reset == 1) state <= IDLE;
            end
        endcase
    end
    

endmodule
