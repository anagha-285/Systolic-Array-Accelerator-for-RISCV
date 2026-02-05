`timescale 1ns/1ps

module accel_top #(
  parameter int N = 4,
  parameter int W = 32
)(
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic in_valid,
  input  logic [W-1:0] a_in,
  input  logic [W-1:0] b_in,
  output logic done,
  output logic [N*N*W-1:0] result_flat
);

  // -------------------------
  // Split 32-bit inputs into 4×8-bit chunks (byte0..byte3)
  // -------------------------
  logic [7:0] a_byte [0:3];
  logic [7:0] b_byte [0:3];

  assign a_byte[0] = a_in[7:0];
  assign a_byte[1] = a_in[15:8];
  assign a_byte[2] = a_in[23:16];
  assign a_byte[3] = a_in[31:24];

  assign b_byte[0] = b_in[7:0];
  assign b_byte[1] = b_in[15:8];
  assign b_byte[2] = b_in[23:16];
  assign b_byte[3] = b_in[31:24];

  // These 8-bit slices are now available inside the design
  // (We still compute using full 32-bit values like before)

  // -------------------------
  // Systolic MAC internal arrays
  // -------------------------
  logic [W-1:0] A_right [0:N-1][0:N-1];
  logic [W-1:0] B_down  [0:N-1][0:N-1];
  logic signed [W-1:0] acc [0:N-1][0:N-1];
  logic validA [0:N-1][0:N-1];
  logic validB [0:N-1][0:N-1];

  integer i, j;
  integer a_row, b_col;
  integer cycle_count;
  localparam int LAT = 2*N;
  logic running;

  // -------------------------
  // Main systolic processing
  // -------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      running <= 0;
      done <= 0;
      cycle_count <= 0;

      for (i=0;i<N;i++)
        for (j=0;j<N;j++) begin
          A_right[i][j] <= 0;
          B_down[i][j]  <= 0;
          acc[i][j]     <= 0;
          validA[i][j]  <= 0;
          validB[i][j]  <= 0;
        end

    end else begin
      done <= 0;

      if (start && !running) begin
        running <= 1;
        cycle_count <= 0;

        for (i=0;i<N;i++)
          for (j=0;j<N;j++)
            acc[i][j] <= 0;
      end

      if (running) begin

        if (in_valid) begin
          a_row = cycle_count % N;
          b_col = cycle_count % N;

          A_right[a_row][0] <= a_in;
          validA[a_row][0]  <= 1;

          B_down[0][b_col] <= b_in;
          validB[0][b_col] <= 1;
        end

        for (i=0;i<N;i++)
          for (j=0;j<N;j++)
            if (validA[i][j] && validB[i][j])
              acc[i][j] <= acc[i][j] +
                            $signed(A_right[i][j]) *
                            $signed(B_down[i][j]);

        for (i=0;i<N;i++)
          for (j=N-1;j>0;j--) begin
            A_right[i][j] <= A_right[i][j-1];
            validA[i][j]  <= validA[i][j-1];
          end

        for (j=0;j<N;j++)
          for (i=N-1;i>0;i--) begin
            B_down[i][j] <= B_down[i-1][j];
            validB[i][j] <= validB[i-1][j];
          end

        cycle_count <= cycle_count + 1;

        if (cycle_count >= (N*N + LAT)) begin
          running <= 0;
          done <= 1;
        end
      end
    end
  end

  // -------------------------
  // Flatten result with generate
  // -------------------------
  genvar gi, gj;
  generate
    for (gi=0; gi<N; gi++)
      for (gj=0; gj<N; gj++) begin
        localparam int IDX = gi*N + gj;
        assign result_flat[IDX*W +: W] = acc[gi][gj];
      end
  endgenerate

endmodule
