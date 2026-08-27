//00 strongly NT
//01 weak NT
//10 weakly taken
//11 strongly taken

module branch_predictor_2bit (
  input clk,
  input rst_n,
  input update, //1: commit the actual update this cycle
  input branch_taken, //actual outcome, used for "training"
  output predict_taken
);

  logic [1:0] state,
  assign predict_taken = state[1];

  always @(posedge clk) begin
    if (!rst_n) state <= 2'b01;
    else if (update) begin
      if (branch_taken) state <= (state == 2'b11) ? 2'b11 : state + 2'b1;
      else              state <= (state == 2'b00) ? 2'b00 : state - 2'b1;
    end
  end
endmodule
