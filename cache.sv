module cache #(parameter NBITS=8, // data word size 
               NA=6,  // memory address size   
               CA=5)   // cache line address size
             ( input logic clock, reset,
               // processor interface
               input logic [NA-1:0] Address,
               input logic [NBITS-1:0] WriteData,
               output logic [NBITS-1:0] ReadData,
               input MemRead,  // read request from processor
               input MemWrite,  // write request from processor
               output logic busy,  // cache miss on read request
                                   // or unfinished write
               // memory interface
               output logic [NA-1:0] memAddress,
               output logic [NBITS-1:0] memWriteData,
               input logic [NBITS-1:0] memReadData,
               output logic memMemWrite); 
               
// direct mapping, write through, CA**2 cache lines, 1 word per line
               
   parameter CL = 1<<CA;  // number of cache lines
   logic [NBITS-1:0] data [CL-1:0];  
   logic [NA-CA-1:0] tag [CL-1:0];
   logic valid [CL-1:0];
   
   logic hit, miss; // cache has valid data for the given address
   
   logic [NA-CA-1:0] procTag, memTag;  // tag field of address
   logic [CA-1:0] procLine, memLine;   // line field of address
   always_comb begin
     {procTag, procLine} = Address;
     {memTag, memLine} = memAddress;
   end
      
   // cache read
   always_comb begin
      ReadData <= data[procLine];  // data may be valid or not
      hit <= tag[procLine] == procTag && valid[procLine] == 1;
      miss <= !hit && MemRead;
      busy <= miss || (MemWrite && state != start);
   end

   // memory access
   enum logic [2:0] { start, rwait1, rwait2, rend, wwait1, wwait2, wend } state;
   always_ff @(posedge clock)
    if(reset) begin
       for(int i=0; i<CL; i++) valid[i] <= 0;
       memAddress <= 0;
       memWriteData <= 0;
       memMemWrite <= 0;
       state <= start;
    end
    else case(state)
         start:  if(miss) begin // fill cache from memory
                    memAddress <= Address;
                    memWriteData <= WriteData;
                    state <= rwait1;
                 end
                 else if(MemWrite) begin // write to cache and memory
                    memAddress <= Address;
                    memWriteData <= WriteData;
                    memMemWrite <= 1;
                    data[procLine] <= WriteData;
                    tag[procLine] <= procTag;
                    valid[procLine] <= 1;
                    state <= wwait1;
                  end
                  
         rwait1: state <= rwait2;
         rwait2: state <= rend;
         rend:   begin  // complete memory read
                   data[memLine] <= memReadData;
                   tag[memLine] <= memTag;
                   valid[memLine] <= 1;
                   state <= start;
                 end
                  
         wwait1: state <= wwait2;
         wwait2: state <= wend;
         wend:   begin
                    memMemWrite <= 0;
                    state <= start;
                 end
      endcase
              
endmodule

