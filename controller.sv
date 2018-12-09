`default_nettype none

// Funcoes da ULA seguindo Apendix A RISC-thesis -- Pagina 113
// funct7  funct3         instruction
/* 0000000 0000 */ parameter ADD  = 'b0000; // operando +
/* 0100000 1000 */ parameter SUB  = 'b1000; // operando -
/* 0000000 0001 */ parameter SLL  = 'b0001; // operando <<
/* 0000000 0010 */ parameter SLT  = 'b0010; // operando < (argumentos numeros inteiros)
/* 0000000 0011 */ parameter SLTU = 'b0011; // operando < (argumentos numeros naturais c/ zero)
/* 0000000 0100 */ parameter XOR  = 'b0100; // operando ^
/* 0000000 0101 */ parameter SRL  = 'b0101; // operando >>
/* 0100000 1101 */ parameter SRA  = 'b1101; // operando >>>
/* 0000000 0110 */ parameter OR   = 'b0110; // operando |
/* 0000000 0111 */ parameter AND  = 'b0111; // operando &

// Funcoes no formato de instruçao seguindo Chapter 3 page 18 (pagina 31 do .pdf)
// e Apendix A RISC-thesis pagina 100 (pagina 113 do .pdf)
// Nao considera os dois bits menos significativos, sao sempre 11
                 // opcode
parameter RType  = 'b01100;
parameter IType  = 'b00100;  // tipo I exceto instrucoes de load e JALR
parameter LType  = 'b00000;  // tipo I, mas especificamente instrucoes de load
parameter IJalr  = 'b11001;  // tipo I, mas especificamente JALR
parameter SType  = 'b01000;
parameter SBType = 'b11000;
// UType nao precisa para implementacao de 8 bit
parameter UJType = 'b11011;
parameter EType  = 'b11100;  // instrucoes ECALL e EBREAK

//TODO: implementar na prova
// Branchs
parameter BEQ = 'b000;
parameter BNE = 'b001;
parameter BLT = 'b100;
parameter BGE = 'b101;
parameter BLTU = 'b110;
parameter BGEU = 'b111;
// Aritimeticas
parameter ADDSUB3 = 'b000
parameter OR3 = 'b110;
parameter AND3 = 'b111;
parameter XOR3 = 'b100;
parameter SLL3 = 'b001;
parameter SLT3 = 'b010;
parameter SLTU3 = 'b011;
parameter SLRSRA3 = 'b101;


//TODO: implementar na prova
parameter FIRST = 'b0000000;

module controller #(parameter NBITS=8, NREGS=32, WIDTH_ALUF=4) (
  input logic clock, reset,

  // Datapath
  output logic [$clog2(NREGS)-1:0] RS2, RS1, RD,
  output logic signed [NBITS-1:0] IMM,
  output logic ALUSrc,
  output logic [WIDTH_ALUF-1:0] ALUControl,
  output logic MemtoReg,
  output logic RegWrite,
  output logic link,   // valida pclink para ser salvo no registrador RD 
  output logic [NBITS-1:0] pclink, // valor proveniente do PC a ser salvo em registrador RD
  input  logic Zero,  // indica que a saida da ULA eh 0
  input  logic Neg,   // indica que a saida da ULA eh negativa
  input  logic Carry, // vai-um sendo gerado pela operacao de subtracao da ULA
  input  logic [NBITS-1:0] PCReg, // usado para transferir o valor do registrador RS1 para o PC

  // Memoria ou cache
  output logic MemWrite,
  output logic MemRead, // indica operação de leitura
  input  logic busy,    // indica que memoria ou cache eh ocupado,ou seja,vai demorar para responder

  // Interrupcao
  input  logic interrupt,

  zoi z);

logic [NBITS-1:0] pc;
logic [NBITS-1:0] pc_;  // PC' o proximo valor do PC considerando interrupcao e desvio
logic [NBITS-1:0] ppc;  // o proximo valor do PC, desconsiderando interrupcao mas considerando desvio
logic [NBITS-1:0] PCBranch; // o proximo valor do PC em caso de desvio
logic [NBITS-1:0] PCPlus; // o proximo valor do PC caso houver nem interrupcao nem desvio
logic [NBITS-1:0] sepc; // guarda o PC para o qual deve retornar da rotina de atendimento a interrupcao

logic [NINSTR_BITS-1:0] instruction;
logic [6:2] op; // opcode sendo que os dois bits menos significativos sao 11
logic [6:0] funct7;
logic [2:0] funct3;

logic Branch;
logic PCSrc;
logic ju;    // indica desvio immediato incondicional
logic jr;    // indica desvio para o valor de um registrador (retorno de subrotina)
logic csrr;  // indica execucao da instruction cssr com argumento sepc
logic eflag; // indica condicao escolhida para desvio condicional


// ***** circuito para gerar o program counter

always_ff @(posedge clock) pc <= pc_;   // NAO MEXE - para compensar o registrador dentro da memoria

// salvar o valor do PC para o qual se deve retornar depois do atendimento da interrupcao
always_ff @(posedge clock) begin
  if (reset)            sepc <= 0;
  // aqui falta codigo
end

always_comb begin
   case(op)
      default: IMM <= 0;
   endcase

   PCPlus <= pc + 4;
   PCBranch <= 0;  // alvo do desvio (condicional ou incondicional)
end
always_comb begin // este always_comb ficou dividido para agrador Icaro
   ppc <= PCPlus;

        if (reset)     pc_  <= 0;     // NAO MEXE neste linha
   else                pc_  <= ppc;

   pclink <= 0;
   link   <= 0;
end

// ***** instrucoes

inst i(pc_, clock, instruction);  // NAO MEXE - dentro da memoria a entrada eh registrada

always_comb begin
   RS2 <= 0;
   RS1 <= 0;
   RD <= 0;
   op <= 0;
   funct7 <= 0;
   funct3 <= 0;
end

// ***** sinais de controle para o datapath e para o proprio controller

always_comb begin
   MemtoReg <= (op == -1);
   MemWrite <= (op == -1);
   Branch   <= (op == -1);
   ju       <= (op == -1);
   jr       <= (op == -1);
   csrr     <= (op == -1);
   ALUSrc   <= (op == -1);
end

always_comb begin
   MemRead <= 0; // flag de leitura para uso de cache
   RegWrite <= 0;  // evita que lixo seja encaminhado para registradores

   //Table 6.13 Selected EFLAGS
   eflag <= 0;

   PCSrc <= 0;

   case(op)
      default: ALUControl <= ADD;
   endcase
end

// zoiada
always_comb begin
   z.pc <= pc;
   z.instruction <= instruction;
   z.Branch <= Branch;
   z.MemWrite <= MemWrite;
end

endmodule

