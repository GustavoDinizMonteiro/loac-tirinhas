`default_nettype none
`include "processador.sv"

module cpu #(parameter NBITS = 8, NREGS=32) (
  input logic clock, reset,

  output logic [NBITS-1:0] saida,
  input logic [NBITS-1:0] entrada,

  zoi z);

// interface com o processador
logic [NBITS-1:2] memAddress;
logic [NBITS-1:0] memWriteData; // dados que o processador quer escrever
logic [NBITS-1:0] memReadData;  // dados que o processador esta lendo
logic             memMemWrite;  // comando vindo do processador para escrever
logic interrupt; // requisicao de interrupcao indo para o processador

logic [NBITS-1:0] ReadData; // saida da memoria
logic [NBITS-1:0] guarda_ent; // guardar entrada do pulso de clock anterior

logic io; // saida do decodificador de enderecos, indica que endereco e de I/O
always_comb io = 0;

// saida de dados
always_ff @(posedge clock)
  if (reset) saida <= 0;
  // aqui falta codigo

// entrada de dados
always_comb
  memReadData <= 0;

memo m(.address(memAddress), .clock(clock), .data(memWriteData), .wren(memMemWrite), .q(ReadData));

// logica para guardar entrada do pulso de clock anterior e no proximo compara-la com nova entrada

// gerar o sinal de interrupcao, ativo quando houver mudanca na entrada

processador #(.NBITS(NBITS), .NREGS(NREGS)) p(.*);

endmodule

