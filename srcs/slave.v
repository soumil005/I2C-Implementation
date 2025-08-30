`timescale 1ns / 1ps

module slave(scl, sda);
    
    input scl;
    inout sda;
    
    parameter slave_addr = 7'b1100100;
    
    reg [7:0] address;
    reg [3:0] addrCounter;
    reg [3:0] dataCounter;
    reg [2:0] ps;
    reg start = 1'b0;
    
    reg [7:0] mdata;
    reg [7:0] sdata = 8'd170;
    
    reg enable = 1'b0;
    reg sda_s;
    
    assign sda = enable ? sda_s == 1'b0 ? 1'b0 : 1'bz : 1'bz;
    
    parameter RADDR = 3'd0, ACK = 3'd1, RDATA = 3'd2, WDATA = 3'd3, ACK2 = 3'd4;
    
    reg count;
    
    always@(negedge sda) begin
        if(scl == 1'b1 && start == 1'b0) begin
            start <= 1'b1;
            ps <= RADDR;
            addrCounter <= 4'd8;
            enable <= 1'b0;
            count <= 1'b0;
        end
    end
    
    always@(posedge sda) begin
        if(scl == 1'b1 && start == 1'b1) begin
            start <= 1'b0;
            ps <= RADDR;
            enable <= 1'b0;
        end
    end
    
    always@(posedge scl) begin
        if(start) begin
            case(ps)
                RADDR: begin
                    if(count == 1'b1) begin
                        if(addrCounter == 4'd0) begin
                            ps <= ACK;
                            
                        end 
                        else begin
                            address[addrCounter - 1] <= sda;
                            addrCounter <= addrCounter - 1;
                            ps <= RADDR;
                            
                        end
                    end
                    else count <= count + 1;
       
                end
                
                ACK: begin
                    if(address[7:1] == slave_addr) begin
                        dataCounter <= 4'd8;
                        if(address[0]) ps <= WDATA;
                        else ps <= RDATA;
                    end
                    else begin
                        ps <= RADDR; 
                    end
                end
                
                RDATA: begin
                    if(dataCounter == 4'd0) begin
                        ps <= ACK2;
                    end 
                    else begin
                        mdata[dataCounter - 1] <= sda;
                        dataCounter <= dataCounter - 1;
                        ps <= RDATA;
                    end
                end
                
                WDATA: begin
                    if(dataCounter == 4'd0) begin
                        ps <= ACK2;
                    end 
                    else begin
                        dataCounter <= dataCounter - 1;
                        ps <= WDATA;
                    end
                end
                
                ACK2: begin
                
                    if(address[0] && sda == 1'b0) begin
                        addrCounter <= 4'd8;
                        ps <= RADDR;
                    end
                    else if(!address[0]) begin
                        addrCounter <= 4'd8;
                        ps <= RADDR;
                    end
                    else ps <= ACK2;
                end
            endcase
        end
    end
    
    always@(negedge scl) begin
        if(start) begin
            case(ps)
                RADDR: begin
                    enable <= 1'b0;
                end
                
                ACK: begin
                    enable <= 1'b1;
                    if(address[7:1] == slave_addr) sda_s <= 1'b0;
                    
                end
                
                RDATA: begin
                    enable <= 1'b0;
                end
                
                WDATA: begin
                    if(dataCounter > 4'd0) begin
                        enable <= 1'b1;
                        sda_s <= sdata[dataCounter - 1];
                    end
                    else begin
                        enable <= 1'b0;
                    end
                end
                
                ACK2: begin
                    if(!address[0]) begin
                        enable <= 1'b1;
                        sda_s <= 1'b0;
                    end
                    else enable <= 1'b0;
                end
            endcase
        end
    end
    
endmodule
