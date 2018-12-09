`default_nettype none
`include "controller.sv"
`include "datapath.sv"
//`include "cache.sv"  // opcional

module processador #(parameter NBITS = 8, NREGS=32) (
  input logic clock, reset,

  // interface de memoria
  output logic [NBITS-1:2] memAddress,
  output logic [NBITS-1:0] memWriteData, // dados que o processador quer escrever
  input  logic [NBITS-1:0] memReadData,  // dados que o processador esta lendo
  output logic             memMemWrite,  // comando para escrever

  input logic interrupt,

  zoi z);

localparam WIDTH_ALUF=4; // largura da palavra que controla a funcao da ULA

// sinais indo do controller para o datapath
logic [$clog2(NREGS)-1:0] RS2, RS1, RD;
logic signed [NBITS-1:0] IMM;
logic MemtoReg, RegWrite;
logic [WIDTH_ALUF-1:0] ALUControl;
logic ALUSrc;
logic link; // valida pclink para ser salvo no registrador RD 
logic [NBITS-1:0] pclink; // valor proveniente do PC a ser salvo em registrador RD

// sinais indo do datapath para o controller
logic [NBITS-1:0] PCReg;
logic Zero, Neg, Carry;

// sinais conectandos a cache
logic [NBITS-1:0] ReadData;  // indo para o datapath
logic [NBITS-1:0] WriteData; // vindo do datapath
logic [NBITS-1:2] Address;   // vindo do datapath
logic             MemRead, MemWrite;  // vindo do controller
logic             busy;      // indo para o controller

controller #(.NBITS(NBITS), .NREGS(NREGS), .WIDTH_ALUF(WIDTH_ALUF)) c(.*);
datapath #(.NBITS(NBITS), .NREGS(NREGS), .WIDTH_ALUF(WIDTH_ALUF)) d(.*);
// cache #(.NBITS(NBITS)) (.*);

// se nao houver cache

logic read;

always_comb begin 
   memAddress   <= Address;
   memWriteData <= WriteData;
   ReadData     <= memReadData;
   memMemWrite  <= MemWrite;
   busy <= MemRead & ~read;  // ativo exatamente durante o primeiro ciclo de clock da leitura
end 

always_ff @(posedge clock)
   if(reset) read <=0;
   else
      if (read) read <= 0; // so fica ativo durante 1 ciclo de clock
      else if (MemRead) read <= 1;

endmodule
