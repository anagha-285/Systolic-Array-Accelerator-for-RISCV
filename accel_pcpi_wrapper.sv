`timescale 1ns/1ps

module accel_pcpi_wrapper #(
  parameter int N = 4,
  parameter int W = 32
)(
  input  logic clk,
  input  logic rst_n,
  input  logic start_req,
  input  logic [W-1:0] memA [0:N*N-1],
  input  logic [W-1:0] memB [0:N*N-1],
  output logic done,
  output logic [N*N*W-1:0] result_flat
);

  typedef enum logic [1:0] {IDLE, STREAM, WAIT} state_t;
  state_t state;

  logic [W-1:0] a_in, b_in;
  logic valid_in, acc_done, start_pulse;

  integer ptr, row, col, bidx;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      ptr <= 0;
      valid_in <= 0;
      start_pulse <= 0;
    end else begin
      start_pulse <= 0;

      case(state)

        IDLE: begin
          valid_in <= 0;
          ptr <= 0;
          if (start_req) begin
            state <= STREAM;
            start_pulse <= 1;
          end
        end

        STREAM: begin
          if (ptr < N*N) begin
            a_in <= memA[ptr];

            row = ptr / N;
            col = ptr % N;
            bidx = row*N + col;

            b_in <= memB[bidx];
            valid_in <= 1;
            ptr <= ptr + 1;
          end else begin
            valid_in <= 0;
            state <= WAIT;
          end
        end

        WAIT: begin
          if (acc_done)
            state <= IDLE;
        end

      endcase
    end
  end

  accel_top #(.N(N),.W(W)) core (
    .clk(clk), .rst_n(rst_n),
    .start(start_pulse),
    .in_valid(valid_in),
    .a_in(a_in), .b_in(b_in),
    .done(acc_done),
    .result_flat(result_flat)
  );

  assign done = acc_done;

endmodule
