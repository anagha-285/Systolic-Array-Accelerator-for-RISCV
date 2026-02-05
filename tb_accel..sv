
`timescale 1ns/1ps

module tb_accel;

  parameter int N = 4;
  parameter int W = 32;

  logic clk, rst_n, start_req, done;
  logic [W-1:0] memA [0:N*N-1];
  logic [W-1:0] memB [0:N*N-1];
  logic [N*N*W-1:0] result_flat;
  logic [W-1:0] result [0:N*N-1];

  genvar g;
  generate
    for (g=0; g < N*N; g++)
      assign result[g] = result_flat[g*W +: W];
  endgenerate

  accel_pcpi_wrapper #(.N(N),.W(W)) dut (
    .clk(clk), .rst_n(rst_n), .start_req(start_req),
    .memA(memA), .memB(memB),
    .done(done), .result_flat(result_flat)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    integer i;

    rst_n = 0; start_req = 0;
    #20 rst_n = 1;
    repeat(5) @(posedge clk);

    for (i=0;i<N*N;i++)
      memA[i] = i + 1;

    for (i=0;i<N*N;i++)
      memB[i] = 0;
    for (i=0;i<N;i++)
      memB[i*N + i] = 1;

    repeat(2) @(posedge clk);
    start_req = 1;
    @(posedge clk);
    start_req = 0;

    wait(done);

    for (i=0;i<N*N;i++)
      $display("result[%0d] = %0d", i, result[i]);

    #20 $finish;
  end

endmodule
