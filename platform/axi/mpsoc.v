module stage
  (
    output [7:0] LED
  );

  wire [3:0] fclk;
  wire [3:0] fclkresetn;
  wire FCLK0;
  wire ARESETN;

  //AA change here: removed buffer for now
  BUFG_PS bufg(.I(fclk[0]),.O(FCLK0));
  //assign FCLK0 = fclk[0];  

  assign ARESETN = 1'b1; //fclkresetn[0];
  
  
    wire [31:0] PS7_ARADDR;
    wire [11:0] PS7_ARID;
    wire [2:0] PS7_ARPROT;
    wire PS7_ARREADY;
    wire PS7_ARVALID;
    wire [31:0] PS7_AWADDR;
    wire [11:0] PS7_AWID;
    wire [2:0] PS7_AWPROT;
    wire PS7_AWREADY;
    wire PS7_AWVALID;
    wire [11:0] PS7_BID;
    wire PS7_BREADY;
    wire [1:0] PS7_BRESP;
    wire PS7_BVALID;
    wire [31:0] PS7_RDATA;
    wire [11:0] PS7_RID;
    wire PS7_RLAST;
    wire PS7_RREADY;
    wire [1:0] PS7_RRESP;
    wire PS7_RVALID;
    wire [31:0] PS7_WDATA;
    wire PS7_WREADY;
    wire [3:0] PS7_WSTRB;
    wire PS7_WVALID;

    wire [31:0] M_AXI_ARADDR;
    wire M_AXI_ARREADY;
    wire  M_AXI_ARVALID;
    wire [31:0] M_AXI_AWADDR;
    wire M_AXI_AWREADY;
    wire  M_AXI_AWVALID;
    wire  M_AXI_BREADY;
    wire [1:0] M_AXI_BRESP;
    wire M_AXI_BVALID;
    wire [63:0] M_AXI_RDATA;
    wire M_AXI_RREADY;
    wire [1:0] M_AXI_RRESP;
    wire M_AXI_RVALID;
    wire [63:0] M_AXI_WDATA;
    wire M_AXI_WREADY;
    wire [7:0] M_AXI_WSTRB;
    wire M_AXI_WVALID;
    wire M_AXI_RLAST;
    wire M_AXI_WLAST;
    
    wire [3:0] M_AXI_ARLEN;
    wire [1:0] M_AXI_ARSIZE;
    wire [1:0] M_AXI_ARBURST;
    
    wire [3:0] M_AXI_AWLEN;
    wire [1:0] M_AXI_AWSIZE;
    wire [1:0] M_AXI_AWBURST;
    
    wire CONFIG_VALID;
   wire [___CONF_NREG*32-1:0] CONFIG_DATA;
   
    wire [31:0] CONFIG_CMD;
    wire [31:0] CONFIG_SRC;
    wire [31:0] CONFIG_DEST;
    wire [31:0] CONFIG_LEN;

   assign CONFIG_CMD = CONFIG_DATA[31:0];
   assign CONFIG_SRC = CONFIG_DATA[63:32];
   assign CONFIG_DEST = CONFIG_DATA[95:64];
   assign CONFIG_LEN = CONFIG_DATA[127:96];
   
    wire CONFIG_IRQ;
  
    wire READER_READY;
    wire WRITER_READY;
    
    assign CONFIG_READY = READER_READY && WRITER_READY;
    
    Conf #(.ADDR_BASE(32'hA0000000),.NREG(___CONF_NREG))  conf(
    .ACLK(FCLK0),
    .ARESETN(ARESETN),
    .S_AXI_ARADDR(PS7_ARADDR), 
    .S_AXI_ARID(PS7_ARID),  
    .S_AXI_ARREADY(PS7_ARREADY), 
    .S_AXI_ARVALID(PS7_ARVALID), 
    .S_AXI_AWADDR(PS7_AWADDR), 
    .S_AXI_AWID(PS7_AWID), 
    .S_AXI_AWREADY(PS7_AWREADY), 
    .S_AXI_AWVALID(PS7_AWVALID), 
    .S_AXI_BID(PS7_BID), 
    .S_AXI_BREADY(PS7_BREADY), 
    .S_AXI_BRESP(PS7_BRESP), 
    .S_AXI_BVALID(PS7_BVALID), 
    .S_AXI_RDATA(PS7_RDATA), 
    .S_AXI_RID(PS7_RID), 
    .S_AXI_RLAST(PS7_RLAST), 
    .S_AXI_RREADY(PS7_RREADY), 
    .S_AXI_RRESP(PS7_RRESP), 
    .S_AXI_RVALID(PS7_RVALID), 
    .S_AXI_WDATA(PS7_WDATA), 
    .S_AXI_WREADY(PS7_WREADY), 
    .S_AXI_WSTRB(PS7_WSTRB), 
    .S_AXI_WVALID(PS7_WVALID),
    .CONFIG_VALID(CONFIG_VALID),
    .CONFIG_READY(CONFIG_READY),
    .CONFIG_DATA(CONFIG_DATA),                                           
    .CONFIG_IRQ(CONFIG_IRQ));

   // lengthInput/lengthOutput are in bytes
   wire [31:0] lengthInput;
   assign lengthInput = {4'b0000,CONFIG_LEN[27:0]};
   wire [31:0] lengthOutput;
   assign lengthOutput = (CONFIG_LEN[27:0] << 8'd8) >> CONFIG_LEN[31:28];

   reg [31:0]  clkcnt = 0;
//   assign LED = clkcnt[20:13];
   assign  LED = CONFIG_SRC[15:8];//clkcnt[28:21];
   
  always @(posedge FCLK0) begin
     clkcnt <= clkcnt+1;
  end

  wire [63:0] pipelineInput;
  wire       pipelineInputValid;
   
  wire [64:0] pipelineOutputPacked;
  wire [63:0] pipelineOutput;
  assign pipelineOutput = pipelineOutputPacked[63:0];   
  wire pipelineOutputValid;
  assign pipelineOutputValid = pipelineOutputPacked[64];
   
  wire       pipelineReady;
  wire      downstreamReady;

  ___PIPELINE_MODULE_NAME pipeline(.CLK(FCLK0),.reset(CONFIG_READY),.ready(pipelineReady),.ready_downstream(downstreamReady),.process_input({pipelineInputValid,pipelineInput}),.process_output(pipelineOutputPacked) ___PIPELINE_TAPINPUT );

  DRAMReader reader(
    .ACLK(FCLK0),
    .ARESETN(ARESETN),
    .M_AXI_ARADDR(M_AXI_ARADDR),
    .M_AXI_ARREADY(M_AXI_ARREADY),
    .M_AXI_ARVALID(M_AXI_ARVALID),
    .M_AXI_RDATA(M_AXI_RDATA),
    .M_AXI_RREADY(M_AXI_RREADY),
    .M_AXI_RRESP(M_AXI_RRESP),
    .M_AXI_RVALID(M_AXI_RVALID),
    .M_AXI_RLAST(M_AXI_RLAST),
    .M_AXI_ARLEN(M_AXI_ARLEN),
    .M_AXI_ARSIZE(M_AXI_ARSIZE),
    .M_AXI_ARBURST(M_AXI_ARBURST),
    
    .CONFIG_VALID(CONFIG_VALID),
    .CONFIG_READY(READER_READY),
    .CONFIG_START_ADDR(CONFIG_SRC),
    .CONFIG_NBYTES(___PIPELINE_INPUT_BYTES),

    .DATA_READY_DOWNSTREAM(pipelineReady),
    .DATA_VALID(pipelineInputValid),
    .DATA(pipelineInput)
  );
  
  DRAMWriter writer(
    .ACLK(FCLK0),
    .ARESETN(ARESETN),
    .M_AXI_AWADDR(M_AXI_AWADDR),
    .M_AXI_AWREADY(M_AXI_AWREADY),
    .M_AXI_AWVALID(M_AXI_AWVALID),
    .M_AXI_WDATA(M_AXI_WDATA),
    .M_AXI_WREADY(M_AXI_WREADY),
    .M_AXI_WVALID(M_AXI_WVALID),
    .M_AXI_WLAST(M_AXI_WLAST),
    .M_AXI_WSTRB(M_AXI_WSTRB),
    
    .M_AXI_BRESP(M_AXI_BRESP),
    .M_AXI_BREADY(M_AXI_BREADY),
    .M_AXI_BVALID(M_AXI_BVALID),
    
    .M_AXI_AWLEN(M_AXI_AWLEN),
    .M_AXI_AWSIZE(M_AXI_AWSIZE),
    .M_AXI_AWBURST(M_AXI_AWBURST),
    
    .CONFIG_VALID(CONFIG_VALID),
    .CONFIG_READY(WRITER_READY),
    .CONFIG_START_ADDR(CONFIG_DEST),
    .CONFIG_NBYTES(___PIPELINE_OUTPUT_BYTES),

    .DATA_READY(downstreamReady),
    .DATA_VALID(pipelineOutputValid),
    .DATA(pipelineOutput)
  );

   PS8 PS8_i  (
.MAXIGP0ACLK (FCLK0),
.MAXIGP0AWID (PS7_AWID),
.MAXIGP0AWADDR (PS7_AWADDR),
.MAXIGP0AWLEN (),
.MAXIGP0AWSIZE (),
.MAXIGP0AWBURST (),
.MAXIGP0AWLOCK (),
.MAXIGP0AWCACHE (),
.MAXIGP0AWPROT (),
.MAXIGP0AWVALID (PS7_AWVALID),
.MAXIGP0AWUSER (),
.MAXIGP0AWREADY (PS7_AWREADY),
.MAXIGP0WDATA (PS7_WDATA),
.MAXIGP0WSTRB (PS7_WSTRB),
.MAXIGP0WLAST (),
.MAXIGP0WVALID (PS7_WVALID),
.MAXIGP0WREADY (PS7_WREADY),
.MAXIGP0BID (PS7_BID),
.MAXIGP0BRESP (PS7_BRESP),
.MAXIGP0BVALID (PS7_BVALID),
.MAXIGP0BREADY (PS7_BREADY),
.MAXIGP0ARID (PS7_ARID),
.MAXIGP0ARADDR (PS7_ARADDR),
.MAXIGP0ARLEN (),
.MAXIGP0ARSIZE (),
.MAXIGP0ARBURST (),
.MAXIGP0ARLOCK (),
.MAXIGP0ARCACHE (),
.MAXIGP0ARPROT (),
.MAXIGP0ARVALID (PS7_ARVALID),
.MAXIGP0ARUSER (),
.MAXIGP0ARREADY (PS7_ARREADY),
.MAXIGP0RID (PS7_RID),
.MAXIGP0RDATA (PS7_RDATA),
.MAXIGP0RRESP (PS7_RRESP),
.MAXIGP0RLAST (PS7_RLAST),
.MAXIGP0RVALID (PS7_RVALID),
.MAXIGP0RREADY (PS7_RREADY),
.MAXIGP0AWQOS (),
.MAXIGP0ARQOS (),
.MAXIGP1ACLK (),
.MAXIGP1AWID (),
.MAXIGP1AWADDR (),
.MAXIGP1AWLEN (),
.MAXIGP1AWSIZE (),
.MAXIGP1AWBURST (),
.MAXIGP1AWLOCK (),
.MAXIGP1AWCACHE (),
.MAXIGP1AWPROT (),
.MAXIGP1AWVALID (),
.MAXIGP1AWUSER (),
.MAXIGP1AWREADY (),
.MAXIGP1WDATA (),
.MAXIGP1WSTRB (),
.MAXIGP1WLAST (),
.MAXIGP1WVALID (),
.MAXIGP1WREADY (),
.MAXIGP1BID (),
.MAXIGP1BRESP (),
.MAXIGP1BVALID (),
.MAXIGP1BREADY (),
.MAXIGP1ARID (),
.MAXIGP1ARADDR (),
.MAXIGP1ARLEN (),
.MAXIGP1ARSIZE (),
.MAXIGP1ARBURST (),
.MAXIGP1ARLOCK (),
.MAXIGP1ARCACHE (),
.MAXIGP1ARPROT (),
.MAXIGP1ARVALID (),
.MAXIGP1ARUSER (),
.MAXIGP1ARREADY (),
.MAXIGP1RID (),
.MAXIGP1RDATA (),
.MAXIGP1RRESP (),
.MAXIGP1RLAST (),
.MAXIGP1RVALID (),
.MAXIGP1RREADY (),
.MAXIGP1AWQOS (),
.MAXIGP1ARQOS (),
.MAXIGP2ACLK (),
.MAXIGP2AWID (),
.MAXIGP2AWADDR (),
.MAXIGP2AWLEN (),
.MAXIGP2AWSIZE (),
.MAXIGP2AWBURST (),
.MAXIGP2AWLOCK (),
.MAXIGP2AWCACHE (),
.MAXIGP2AWPROT (),
.MAXIGP2AWVALID (),
.MAXIGP2AWUSER (),
.MAXIGP2AWREADY (),
.MAXIGP2WDATA (),
.MAXIGP2WSTRB (),
.MAXIGP2WLAST (),
.MAXIGP2WVALID (),
.MAXIGP2WREADY (),
.MAXIGP2BID (),
.MAXIGP2BRESP (),
.MAXIGP2BVALID (),
.MAXIGP2BREADY (),
.MAXIGP2ARID (),
.MAXIGP2ARADDR (),
.MAXIGP2ARLEN (),
.MAXIGP2ARSIZE (),
.MAXIGP2ARBURST (),
.MAXIGP2ARLOCK (),
.MAXIGP2ARCACHE (),
.MAXIGP2ARPROT (),
.MAXIGP2ARVALID (),
.MAXIGP2ARUSER (),
.MAXIGP2ARREADY (),
.MAXIGP2RID (),
.MAXIGP2RDATA (),
.MAXIGP2RRESP (),
.MAXIGP2RLAST (),
.MAXIGP2RVALID (),
.MAXIGP2RREADY (),
.MAXIGP2AWQOS (),
.MAXIGP2ARQOS (),

.SAXIGP0RCLK (FCLK0),
.SAXIGP0WCLK (FCLK0),
.SAXIGP0ARUSER (),
.SAXIGP0AWUSER (),
.SAXIGP0AWID (),
.SAXIGP0AWADDR (M_AXI_AWADDR),
.SAXIGP0AWLEN (M_AXI_AWLEN),
.SAXIGP0AWSIZE (M_AXI_AWSIZE),
.SAXIGP0AWBURST (M_AXI_AWBURST),
.SAXIGP0AWLOCK (),
.SAXIGP0AWCACHE (),
.SAXIGP0AWPROT (),
.SAXIGP0AWVALID (M_AXI_AWVALID),
.SAXIGP0AWREADY (M_AXI_AWREADY),
.SAXIGP0WDATA (M_AXI_WDATA),
.SAXIGP0WSTRB (M_AXI_WSTRB),
.SAXIGP0WLAST (M_AXI_WLAST),
.SAXIGP0WVALID (M_AXI_WVALID),
.SAXIGP0WREADY (M_AXI_WREADY),
.SAXIGP0BID (),
.SAXIGP0BRESP (M_AXI_BRESP),
.SAXIGP0BVALID (M_AXI_BVALID),
.SAXIGP0BREADY (M_AXI_BREADY),
.SAXIGP0ARID (),
.SAXIGP0ARADDR (M_AXI_ARADDR),
.SAXIGP0ARLEN (M_AXI_ARLEN),
.SAXIGP0ARSIZE (M_AXI_ARSIZE),
.SAXIGP0ARBURST (M_AXI_ARBURST),
.SAXIGP0ARLOCK (),
.SAXIGP0ARCACHE (),
.SAXIGP0ARPROT (),
.SAXIGP0ARVALID (M_AXI_ARVALID),
.SAXIGP0ARREADY (M_AXI_ARREADY),
.SAXIGP0RID (),
.SAXIGP0RDATA (M_AXI_RDATA),
.SAXIGP0RRESP (M_AXI_RRESP),
.SAXIGP0RLAST (M_AXI_RLAST),
.SAXIGP0RVALID (M_AXI_RVALID),
.SAXIGP0RREADY (M_AXI_RREADY),
.SAXIGP0AWQOS (),
.SAXIGP0ARQOS (),
.SAXIGP0RCOUNT (),
.SAXIGP0WCOUNT (),
.SAXIGP0RACOUNT (),
.SAXIGP0WACOUNT (),



.SAXIGP1RCLK (),
.SAXIGP1WCLK (),
.SAXIGP1ARUSER (),
.SAXIGP1AWUSER (),
.SAXIGP1AWID (),
.SAXIGP1AWADDR (),
.SAXIGP1AWLEN (),
.SAXIGP1AWSIZE (),
.SAXIGP1AWBURST (),
.SAXIGP1AWLOCK (),
.SAXIGP1AWCACHE (),
.SAXIGP1AWPROT (),
.SAXIGP1AWVALID (),
.SAXIGP1AWREADY (),
.SAXIGP1WDATA (),
.SAXIGP1WSTRB (),
.SAXIGP1WLAST (),
.SAXIGP1WVALID (),
.SAXIGP1WREADY (),
.SAXIGP1BID (),
.SAXIGP1BRESP (),
.SAXIGP1BVALID (),
.SAXIGP1BREADY (),
.SAXIGP1ARID (),
.SAXIGP1ARADDR (),
.SAXIGP1ARLEN (),
.SAXIGP1ARSIZE (),
.SAXIGP1ARBURST (),
.SAXIGP1ARLOCK (),
.SAXIGP1ARCACHE (),
.SAXIGP1ARPROT (),
.SAXIGP1ARVALID (),
.SAXIGP1ARREADY (),
.SAXIGP1RID (),
.SAXIGP1RDATA (),
.SAXIGP1RRESP (),
.SAXIGP1RLAST (),
.SAXIGP1RVALID (),
.SAXIGP1RREADY (),
.SAXIGP1AWQOS (),
.SAXIGP1ARQOS (),
.SAXIGP1RCOUNT (),
.SAXIGP1WCOUNT (),
.SAXIGP1RACOUNT (),
.SAXIGP1WACOUNT (),
.SAXIGP2RCLK (),
.SAXIGP2WCLK (),
.SAXIGP2ARUSER (),
.SAXIGP2AWUSER (),
.SAXIGP2AWID (),
.SAXIGP2AWADDR (),
.SAXIGP2AWLEN (),
.SAXIGP2AWSIZE (),
.SAXIGP2AWBURST (),
.SAXIGP2AWLOCK (),
.SAXIGP2AWCACHE (),
.SAXIGP2AWPROT (),
.SAXIGP2AWVALID (),
.SAXIGP2AWREADY (),
.SAXIGP2WDATA (),
.SAXIGP2WSTRB (),
.SAXIGP2WLAST (),
.SAXIGP2WVALID (),
.SAXIGP2WREADY (),
.SAXIGP2BID (),
.SAXIGP2BRESP (),
.SAXIGP2BVALID (),
.SAXIGP2BREADY (),
.SAXIGP2ARID (),
.SAXIGP2ARADDR (),
.SAXIGP2ARLEN (),
.SAXIGP2ARSIZE (),
.SAXIGP2ARBURST (),
.SAXIGP2ARLOCK (),
.SAXIGP2ARCACHE (),
.SAXIGP2ARPROT (),
.SAXIGP2ARVALID (),
.SAXIGP2ARREADY (),
.SAXIGP2RID (),
.SAXIGP2RDATA (),
.SAXIGP2RRESP (),
.SAXIGP2RLAST (),
.SAXIGP2RVALID (),
.SAXIGP2RREADY (),
.SAXIGP2AWQOS (),
.SAXIGP2ARQOS (),
.SAXIGP2RCOUNT (),
.SAXIGP2WCOUNT (),
.SAXIGP2RACOUNT (),
.SAXIGP2WACOUNT (),
.SAXIGP3RCLK (),
.SAXIGP3WCLK (),
.SAXIGP3ARUSER (),
.SAXIGP3AWUSER (),
.SAXIGP3AWID (),
.SAXIGP3AWADDR (),
.SAXIGP3AWLEN (),
.SAXIGP3AWSIZE (),
.SAXIGP3AWBURST (),
.SAXIGP3AWLOCK (),
.SAXIGP3AWCACHE (),
.SAXIGP3AWPROT (),
.SAXIGP3AWVALID (),
.SAXIGP3AWREADY (),
.SAXIGP3WDATA (),
.SAXIGP3WSTRB (),
.SAXIGP3WLAST (),
.SAXIGP3WVALID (),
.SAXIGP3WREADY (),
.SAXIGP3BID (),
.SAXIGP3BRESP (),
.SAXIGP3BVALID (),
.SAXIGP3BREADY (),
.SAXIGP3ARID (),
.SAXIGP3ARADDR (),
.SAXIGP3ARLEN (),
.SAXIGP3ARSIZE (),
.SAXIGP3ARBURST (),
.SAXIGP3ARLOCK (),
.SAXIGP3ARCACHE (),
.SAXIGP3ARPROT (),
.SAXIGP3ARVALID (),
.SAXIGP3ARREADY (),
.SAXIGP3RID (),
.SAXIGP3RDATA (),
.SAXIGP3RRESP (),
.SAXIGP3RLAST (),
.SAXIGP3RVALID (),
.SAXIGP3RREADY (),
.SAXIGP3AWQOS (),
.SAXIGP3ARQOS (),
.SAXIGP3RCOUNT (),
.SAXIGP3WCOUNT (),
.SAXIGP3RACOUNT (),
.SAXIGP3WACOUNT (),
.SAXIGP4RCLK (),
.SAXIGP4WCLK (),
.SAXIGP4ARUSER (),
.SAXIGP4AWUSER (),
.SAXIGP4AWID (),
.SAXIGP4AWADDR (),
.SAXIGP4AWLEN (),
.SAXIGP4AWSIZE (),
.SAXIGP4AWBURST (),
.SAXIGP4AWLOCK (),
.SAXIGP4AWCACHE (),
.SAXIGP4AWPROT (),
.SAXIGP4AWVALID (),
.SAXIGP4AWREADY (),
.SAXIGP4WDATA (),
.SAXIGP4WSTRB (),
.SAXIGP4WLAST (),
.SAXIGP4WVALID (),
.SAXIGP4WREADY (),
.SAXIGP4BID (),
.SAXIGP4BRESP (),
.SAXIGP4BVALID (),
.SAXIGP4BREADY (),
.SAXIGP4ARID (),
.SAXIGP4ARADDR (),
.SAXIGP4ARLEN (),
.SAXIGP4ARSIZE (),
.SAXIGP4ARBURST (),
.SAXIGP4ARLOCK (),
.SAXIGP4ARCACHE (),
.SAXIGP4ARPROT (),
.SAXIGP4ARVALID (),
.SAXIGP4ARREADY (),
.SAXIGP4RID (),
.SAXIGP4RDATA (),
.SAXIGP4RRESP (),
.SAXIGP4RLAST (),
.SAXIGP4RVALID (),
.SAXIGP4RREADY (),
.SAXIGP4AWQOS (),
.SAXIGP4ARQOS (),
.SAXIGP4RCOUNT (),
.SAXIGP4WCOUNT (),
.SAXIGP4RACOUNT (),
.SAXIGP4WACOUNT (),
.SAXIGP5RCLK (),
.SAXIGP5WCLK (),
.SAXIGP5ARUSER (),
.SAXIGP5AWUSER (),
.SAXIGP5AWID (),
.SAXIGP5AWADDR (),
.SAXIGP5AWLEN (),
.SAXIGP5AWSIZE (),
.SAXIGP5AWBURST (),
.SAXIGP5AWLOCK (),
.SAXIGP5AWCACHE (),
.SAXIGP5AWPROT (),
.SAXIGP5AWVALID (),
.SAXIGP5AWREADY (),
.SAXIGP5WDATA (),
.SAXIGP5WSTRB (),
.SAXIGP5WLAST (),
.SAXIGP5WVALID (),
.SAXIGP5WREADY (),
.SAXIGP5BID (),
.SAXIGP5BRESP (),
.SAXIGP5BVALID (),
.SAXIGP5BREADY (),
.SAXIGP5ARID (),
.SAXIGP5ARADDR (),
.SAXIGP5ARLEN (),
.SAXIGP5ARSIZE (),
.SAXIGP5ARBURST (),
.SAXIGP5ARLOCK (),
.SAXIGP5ARCACHE (),
.SAXIGP5ARPROT (),
.SAXIGP5ARVALID (),
.SAXIGP5ARREADY (),
.SAXIGP5RID (),
.SAXIGP5RDATA (),
.SAXIGP5RRESP (),
.SAXIGP5RLAST (),
.SAXIGP5RVALID (),
.SAXIGP5RREADY (),
.SAXIGP5AWQOS (),
.SAXIGP5ARQOS (),
.SAXIGP5RCOUNT (),
.SAXIGP5WCOUNT (),
.SAXIGP5RACOUNT (),
.SAXIGP5WACOUNT (),
.SAXIGP6RCLK (),
.SAXIGP6WCLK (),
.SAXIGP6ARUSER (),
.SAXIGP6AWUSER (),
.SAXIGP6AWID (),
.SAXIGP6AWADDR (),
.SAXIGP6AWLEN (),
.SAXIGP6AWSIZE (),
.SAXIGP6AWBURST (),
.SAXIGP6AWLOCK (),
.SAXIGP6AWCACHE (),
.SAXIGP6AWPROT (),
.SAXIGP6AWVALID (),
.SAXIGP6AWREADY (),
.SAXIGP6WDATA (),
.SAXIGP6WSTRB (),
.SAXIGP6WLAST (),
.SAXIGP6WVALID (),
.SAXIGP6WREADY (),
.SAXIGP6BID (),
.SAXIGP6BRESP (),
.SAXIGP6BVALID (),
.SAXIGP6BREADY (),
.SAXIGP6ARID (),
.SAXIGP6ARADDR (),
.SAXIGP6ARLEN (),
.SAXIGP6ARSIZE (),
.SAXIGP6ARBURST (),
.SAXIGP6ARLOCK (),
.SAXIGP6ARCACHE (),
.SAXIGP6ARPROT (),
.SAXIGP6ARVALID (),
.SAXIGP6ARREADY (),
.SAXIGP6RID (),
.SAXIGP6RDATA (),
.SAXIGP6RRESP (),
.SAXIGP6RLAST (),
.SAXIGP6RVALID (),
.SAXIGP6RREADY (),
.SAXIGP6AWQOS (),
.SAXIGP6ARQOS (),
.SAXIGP6RCOUNT (),
.SAXIGP6WCOUNT (),
.SAXIGP6RACOUNT (),
.SAXIGP6WACOUNT (),

.SAXIACPACLK (),
.SAXIACPAWADDR (),
.SAXIACPAWID (),
.SAXIACPAWLEN (),
.SAXIACPAWSIZE (),
.SAXIACPAWBURST (),
.SAXIACPAWLOCK (),
.SAXIACPAWCACHE (),
.SAXIACPAWPROT (),
.SAXIACPAWVALID (),
.SAXIACPAWREADY (),
.SAXIACPAWUSER (),
.SAXIACPAWQOS (),
.SAXIACPWLAST (),
.SAXIACPWDATA (),
.SAXIACPWSTRB (),
.SAXIACPWVALID (),
.SAXIACPWREADY (),
.SAXIACPBRESP (),
.SAXIACPBID (),
.SAXIACPBVALID (),
.SAXIACPBREADY (),
.SAXIACPARADDR (),
.SAXIACPARID (),
.SAXIACPARLEN (),
.SAXIACPARSIZE (),
.SAXIACPARBURST (),
.SAXIACPARLOCK (),
.SAXIACPARCACHE (),
.SAXIACPARPROT (),
.SAXIACPARVALID (),
.SAXIACPARREADY (),
.SAXIACPARUSER (),
.SAXIACPARQOS (),
.SAXIACPRID (),
.SAXIACPRLAST (),
.SAXIACPRDATA (),
.SAXIACPRRESP (),
.SAXIACPRVALID (),
.SAXIACPRREADY (),

.PLACECLK (),
.SACEFPDAWVALID (),
.SACEFPDAWREADY (),
.SACEFPDAWID (),
.SACEFPDAWADDR (),
.SACEFPDAWREGION (),
.SACEFPDAWLEN (),
.SACEFPDAWSIZE (),
.SACEFPDAWBURST (),
.SACEFPDAWLOCK (),
.SACEFPDAWCACHE (),
.SACEFPDAWPROT (),
.SACEFPDAWDOMAIN (),
.SACEFPDAWSNOOP (),
.SACEFPDAWBAR (),
.SACEFPDAWQOS (),
.SACEFPDAWUSER (),
.SACEFPDWVALID (),
.SACEFPDWREADY (),
.SACEFPDWDATA (),
.SACEFPDWSTRB (),
.SACEFPDWLAST (),
.SACEFPDWUSER (),
.SACEFPDBVALID (),
.SACEFPDBREADY (),
.SACEFPDBID (),
.SACEFPDBRESP (),
.SACEFPDBUSER (),
.SACEFPDARVALID (),
.SACEFPDARREADY (),
.SACEFPDARID (),
.SACEFPDARADDR (),
.SACEFPDARREGION (),
.SACEFPDARLEN (),
.SACEFPDARSIZE (),
.SACEFPDARBURST (),
.SACEFPDARLOCK (),
.SACEFPDARCACHE (),
.SACEFPDARPROT (),
.SACEFPDARDOMAIN (),
.SACEFPDARSNOOP (),
.SACEFPDARBAR (),
.SACEFPDARQOS (),
.SACEFPDARUSER (),
.SACEFPDRVALID (),
.SACEFPDRREADY (),
.SACEFPDRID (),
.SACEFPDRDATA (),
.SACEFPDRRESP (),
.SACEFPDRLAST (),
.SACEFPDRUSER (),
.SACEFPDACVALID (),
.SACEFPDACREADY (),
.SACEFPDACADDR (),
.SACEFPDACSNOOP (),
.SACEFPDACPROT (),
.SACEFPDCRVALID (),
.SACEFPDCRREADY (),
.SACEFPDCRRESP (),
.SACEFPDCDVALID (),
.SACEFPDCDREADY (),
.SACEFPDCDDATA (),
.SACEFPDCDLAST (),
.SACEFPDWACK (),
.SACEFPDRACK (),
.EMIOCAN0PHYTX (),
.EMIOCAN0PHYRX (),
.EMIOCAN1PHYTX (),
.EMIOCAN1PHYRX (),
.EMIOENET0GMIIRXCLK (),
.EMIOENET0SPEEDMODE (),
.EMIOENET0GMIICRS (),
.EMIOENET0GMIICOL (),
.EMIOENET0GMIIRXD (),
.EMIOENET0GMIIRXER (),
.EMIOENET0GMIIRXDV (),
.EMIOENET0GMIITXCLK (),
.EMIOENET0GMIITXD (),
.EMIOENET0GMIITXEN (),
.EMIOENET0GMIITXER (),
.EMIOENET0MDIOMDC (),
.EMIOENET0MDIOI (),
.EMIOENET0MDIOO (),
.EMIOENET0MDIOTN (),
.EMIOENET1GMIIRXCLK (),
.EMIOENET1SPEEDMODE (),
.EMIOENET1GMIICRS (),
.EMIOENET1GMIICOL (),
.EMIOENET1GMIIRXD (),
.EMIOENET1GMIIRXER (),
.EMIOENET1GMIIRXDV (),
.EMIOENET1GMIITXCLK (),
.EMIOENET1GMIITXD (),
.EMIOENET1GMIITXEN (),
.EMIOENET1GMIITXER (),
.EMIOENET1MDIOMDC (),
.EMIOENET1MDIOI (),
.EMIOENET1MDIOO (),
.EMIOENET1MDIOTN (),
.EMIOENET2GMIIRXCLK (),
.EMIOENET2SPEEDMODE (),
.EMIOENET2GMIICRS (),
.EMIOENET2GMIICOL (),
.EMIOENET2GMIIRXD (),
.EMIOENET2GMIIRXER (),
.EMIOENET2GMIIRXDV (),
.EMIOENET2GMIITXCLK (),
.EMIOENET2GMIITXD (),
.EMIOENET2GMIITXEN (),
.EMIOENET2GMIITXER (),
.EMIOENET2MDIOMDC (),
.EMIOENET2MDIOI (),
.EMIOENET2MDIOO (),
.EMIOENET2MDIOTN (),
.EMIOENET3GMIIRXCLK (),
.EMIOENET3SPEEDMODE (),
.EMIOENET3GMIICRS (),
.EMIOENET3GMIICOL (),
.EMIOENET3GMIIRXD (),
.EMIOENET3GMIIRXER (),
.EMIOENET3GMIIRXDV (),
.EMIOENET3GMIITXCLK (),
.EMIOENET3GMIITXD (),
.EMIOENET3GMIITXEN (),
.EMIOENET3GMIITXER (),
.EMIOENET3MDIOMDC (),
.EMIOENET3MDIOI (),
.EMIOENET3MDIOO (),
.EMIOENET3MDIOTN (),
.EMIOENET0TXRDATARDY (),
.EMIOENET0TXRRD (),
.EMIOENET0TXRVALID (),
.EMIOENET0TXRDATA (),
.EMIOENET0TXRSOP (),
.EMIOENET0TXREOP (),
.EMIOENET0TXRERR (),
.EMIOENET0TXRUNDERFLOW (),
.EMIOENET0TXRFLUSHED (),
.EMIOENET0TXRCONTROL (),
.EMIOENET0DMATXENDTOG (),
.EMIOENET0DMATXSTATUSTOG (),
.EMIOENET0TXRSTATUS (),
.EMIOENET0RXWWR (),
.EMIOENET0RXWDATA (),
.EMIOENET0RXWSOP (),
.EMIOENET0RXWEOP (),
.EMIOENET0RXWSTATUS (),
.EMIOENET0RXWERR (),
.EMIOENET0RXWOVERFLOW (),
.FMIOGEM0SIGNALDETECT (),
.EMIOENET0RXWFLUSH (),
.EMIOGEM0TXRFIXEDLAT (),
.FMIOGEM0FIFOTXCLKFROMPL (),
.FMIOGEM0FIFORXCLKFROMPL (),
.FMIOGEM0FIFOTXCLKTOPLBUFG (),
.FMIOGEM0FIFORXCLKTOPLBUFG (),
.EMIOENET1TXRDATARDY (),
.EMIOENET1TXRRD (),
.EMIOENET1TXRVALID (),
.EMIOENET1TXRDATA (),
.EMIOENET1TXRSOP (),
.EMIOENET1TXREOP (),
.EMIOENET1TXRERR (),
.EMIOENET1TXRUNDERFLOW (),
.EMIOENET1TXRFLUSHED (),
.EMIOENET1TXRCONTROL (),
.EMIOENET1DMATXENDTOG (),
.EMIOENET1DMATXSTATUSTOG (),
.EMIOENET1TXRSTATUS (),
.EMIOENET1RXWWR (),
.EMIOENET1RXWDATA (),
.EMIOENET1RXWSOP (),
.EMIOENET1RXWEOP (),
.EMIOENET1RXWSTATUS (),
.EMIOENET1RXWERR (),
.EMIOENET1RXWOVERFLOW (),
.FMIOGEM1SIGNALDETECT (),
.EMIOENET1RXWFLUSH (),
.EMIOGEM1TXRFIXEDLAT (),
.FMIOGEM1FIFOTXCLKFROMPL (),
.FMIOGEM1FIFORXCLKFROMPL (),
.FMIOGEM1FIFOTXCLKTOPLBUFG (),
.FMIOGEM1FIFORXCLKTOPLBUFG (),
.EMIOENET2TXRDATARDY (),
.EMIOENET2TXRRD (),
.EMIOENET2TXRVALID (),
.EMIOENET2TXRDATA (),
.EMIOENET2TXRSOP (),
.EMIOENET2TXREOP (),
.EMIOENET2TXRERR (),
.EMIOENET2TXRUNDERFLOW (),
.EMIOENET2TXRFLUSHED (),
.EMIOENET2TXRCONTROL (),
.EMIOENET2DMATXENDTOG (),
.EMIOENET2DMATXSTATUSTOG (),
.EMIOENET2TXRSTATUS (),
.EMIOENET2RXWWR (),
.EMIOENET2RXWDATA (),
.EMIOENET2RXWSOP (),
.EMIOENET2RXWEOP (),
.EMIOENET2RXWSTATUS (),
.EMIOENET2RXWERR (),
.EMIOENET2RXWOVERFLOW (),
.FMIOGEM2SIGNALDETECT (),
.EMIOENET2RXWFLUSH (),
.EMIOGEM2TXRFIXEDLAT (),
.FMIOGEM2FIFOTXCLKFROMPL (),
.FMIOGEM2FIFORXCLKFROMPL (),
.FMIOGEM2FIFOTXCLKTOPLBUFG (),
.FMIOGEM2FIFORXCLKTOPLBUFG (),
.EMIOENET3TXRDATARDY (),
.EMIOENET3TXRRD (),
.EMIOENET3TXRVALID (),
.EMIOENET3TXRDATA (),
.EMIOENET3TXRSOP (),
.EMIOENET3TXREOP (),
.EMIOENET3TXRERR (),
.EMIOENET3TXRUNDERFLOW (),
.EMIOENET3TXRFLUSHED (),
.EMIOENET3TXRCONTROL (),
.EMIOENET3DMATXENDTOG (),
.EMIOENET3DMATXSTATUSTOG (),
.EMIOENET3TXRSTATUS (),
.EMIOENET3RXWWR (),
.EMIOENET3RXWDATA (),
.EMIOENET3RXWSOP (),
.EMIOENET3RXWEOP (),
.EMIOENET3RXWSTATUS (),
.EMIOENET3RXWERR (),
.EMIOENET3RXWOVERFLOW (),
.FMIOGEM3SIGNALDETECT (),
.EMIOENET3RXWFLUSH (),
.EMIOGEM3TXRFIXEDLAT (),
.FMIOGEM3FIFOTXCLKFROMPL (),
.FMIOGEM3FIFORXCLKFROMPL (),
.FMIOGEM3FIFOTXCLKTOPLBUFG (),
.FMIOGEM3FIFORXCLKTOPLBUFG (),
.EMIOGEM0TXSOF (),
.EMIOGEM0SYNCFRAMETX (),
.EMIOGEM0DELAYREQTX (),
.EMIOGEM0PDELAYREQTX (),
.EMIOGEM0PDELAYRESPTX (),
.EMIOGEM0RXSOF (),
.EMIOGEM0SYNCFRAMERX (),
.EMIOGEM0DELAYREQRX (),
.EMIOGEM0PDELAYREQRX (),
.EMIOGEM0PDELAYRESPRX (),
.EMIOGEM0TSUINCCTRL (),
.EMIOGEM0TSUTIMERCMPVAL (),
.EMIOGEM1TXSOF (),
.EMIOGEM1SYNCFRAMETX (),
.EMIOGEM1DELAYREQTX (),
.EMIOGEM1PDELAYREQTX (),
.EMIOGEM1PDELAYRESPTX (),
.EMIOGEM1RXSOF (),
.EMIOGEM1SYNCFRAMERX (),
.EMIOGEM1DELAYREQRX (),
.EMIOGEM1PDELAYREQRX (),
.EMIOGEM1PDELAYRESPRX (),
.EMIOGEM1TSUINCCTRL (),
.EMIOGEM1TSUTIMERCMPVAL (),
.EMIOGEM2TXSOF (),
.EMIOGEM2SYNCFRAMETX (),
.EMIOGEM2DELAYREQTX (),
.EMIOGEM2PDELAYREQTX (),
.EMIOGEM2PDELAYRESPTX (),
.EMIOGEM2RXSOF (),
.EMIOGEM2SYNCFRAMERX (),
.EMIOGEM2DELAYREQRX (),
.EMIOGEM2PDELAYREQRX (),
.EMIOGEM2PDELAYRESPRX (),
.EMIOGEM2TSUINCCTRL (),
.EMIOGEM2TSUTIMERCMPVAL (),
.EMIOGEM3TXSOF (),
.EMIOGEM3SYNCFRAMETX (),
.EMIOGEM3DELAYREQTX (),
.EMIOGEM3PDELAYREQTX (),
.EMIOGEM3PDELAYRESPTX (),
.EMIOGEM3RXSOF (),
.EMIOGEM3SYNCFRAMERX (),
.EMIOGEM3DELAYREQRX (),
.EMIOGEM3PDELAYREQRX (),
.EMIOGEM3PDELAYRESPRX (),
.EMIOGEM3TSUINCCTRL (),
.EMIOGEM3TSUTIMERCMPVAL (),
.FMIOGEMTSUCLKFROMPL (),
.FMIOGEMTSUCLKTOPLBUFG (),
.EMIOENETTSUCLK (),
.EMIOENET0GEMTSUTIMERCNT (),
.EMIOENET0EXTINTIN (),
.EMIOENET1EXTINTIN (),
.EMIOENET2EXTINTIN (),
.EMIOENET3EXTINTIN (),
.EMIOENET0DMABUSWIDTH (),
.EMIOENET1DMABUSWIDTH (),
.EMIOENET2DMABUSWIDTH (),
.EMIOENET3DMABUSWIDTH (),
.EMIOGPIOI (),
.EMIOGPIOO (),
.EMIOGPIOTN (),
.EMIOI2C0SCLI (),
.EMIOI2C0SCLO (),
.EMIOI2C0SCLTN (),
.EMIOI2C0SDAI (),
.EMIOI2C0SDAO (),
.EMIOI2C0SDATN (),
.EMIOI2C1SCLI (),
.EMIOI2C1SCLO (),
.EMIOI2C1SCLTN (),
.EMIOI2C1SDAI (),
.EMIOI2C1SDAO (),
.EMIOI2C1SDATN (),
.EMIOUART0TX (),
.EMIOUART0RX (),
.EMIOUART0CTSN (),
.EMIOUART0RTSN (),
.EMIOUART0DSRN (),
.EMIOUART0DCDN (),
.EMIOUART0RIN (),
.EMIOUART0DTRN (),
.EMIOUART1TX (),
.EMIOUART1RX (),
.EMIOUART1CTSN (),
.EMIOUART1RTSN (),
.EMIOUART1DSRN (),
.EMIOUART1DCDN (),
.EMIOUART1RIN (),
.EMIOUART1DTRN (),
.EMIOSDIO0CLKOUT (),
.EMIOSDIO0FBCLKIN (),
.EMIOSDIO0CMDOUT (),
.EMIOSDIO0CMDIN (),
.EMIOSDIO0CMDENA (),
.EMIOSDIO0DATAIN (),
.EMIOSDIO0DATAOUT (),
.EMIOSDIO0DATAENA (),
.EMIOSDIO0CDN (),
.EMIOSDIO0WP (),
.EMIOSDIO0LEDCONTROL (),
.EMIOSDIO0BUSPOWER (),
.EMIOSDIO0BUSVOLT (),
.EMIOSDIO1CLKOUT (),
.EMIOSDIO1FBCLKIN (),
.EMIOSDIO1CMDOUT (),
.EMIOSDIO1CMDIN (),
.EMIOSDIO1CMDENA (),
.EMIOSDIO1DATAIN (),
.EMIOSDIO1DATAOUT (),
.EMIOSDIO1DATAENA (),
.EMIOSDIO1CDN (),
.EMIOSDIO1WP (),
.EMIOSDIO1LEDCONTROL (),
.EMIOSDIO1BUSPOWER (),
.EMIOSDIO1BUSVOLT (),
.EMIOSPI0SCLKI (),
.EMIOSPI0SCLKO (),
.EMIOSPI0SCLKTN (),
.EMIOSPI0MI (),
.EMIOSPI0MO (),
.EMIOSPI0MOTN (),
.EMIOSPI0SI (),
.EMIOSPI0SO (),
.EMIOSPI0STN (),
.EMIOSPI0SSIN (),
.EMIOSPI0SSON (),
.EMIOSPI0SSNTN (),
.EMIOSPI1SCLKI (),
.EMIOSPI1SCLKO (),
.EMIOSPI1SCLKTN (),
.EMIOSPI1MI (),
.EMIOSPI1MO (),
.EMIOSPI1MOTN (),
.EMIOSPI1SI (),
.EMIOSPI1SO (),
.EMIOSPI1STN (),
.EMIOSPI1SSIN (),
.EMIOSPI1SSON (),
.EMIOSPI1SSNTN (),
.PLPSTRACECLK (),
.PSPLTRACECTL (),
.PSPLTRACEDATA (),
.EMIOTTC0WAVEO (),
.EMIOTTC0CLKI (),
.EMIOTTC1WAVEO (),
.EMIOTTC1CLKI (),
.EMIOTTC2WAVEO (),
.EMIOTTC2CLKI (),
.EMIOTTC3WAVEO (),
.EMIOTTC3CLKI (),
.EMIOWDT0CLKI (),
.EMIOWDT0RSTO (),
.EMIOWDT1CLKI (),
.EMIOWDT1RSTO (),
.EMIOHUBPORTOVERCRNTUSB30 (),
.EMIOHUBPORTOVERCRNTUSB31 (),
.EMIOHUBPORTOVERCRNTUSB20 (),
.EMIOHUBPORTOVERCRNTUSB21 (),
.EMIOU2DSPORTVBUSCTRLUSB30 (),
.EMIOU2DSPORTVBUSCTRLUSB31 (),
.EMIOU3DSPORTVBUSCTRLUSB30 (),
.EMIOU3DSPORTVBUSCTRLUSB31 (),
.ADMAFCICLK (),
.PL2ADMACVLD (),
.PL2ADMATACK (),
.ADMA2PLCACK (),
.ADMA2PLTVLD (),
.GDMAFCICLK (),
.PL2GDMACVLD (),
.PL2GDMATACK (),
.GDMA2PLCACK (),
.GDMA2PLTVLD (),
.PLFPGASTOP (),
.PLLAUXREFCLKLPD (),
.PLLAUXREFCLKFPD (),
.DPSAXISAUDIOTDATA (),
.DPSAXISAUDIOTID (),
.DPSAXISAUDIOTVALID (),
.DPSAXISAUDIOTREADY (),
.DPMAXISMIXEDAUDIOTDATA (),
.DPMAXISMIXEDAUDIOTID (),
.DPMAXISMIXEDAUDIOTVALID (),
.DPMAXISMIXEDAUDIOTREADY (),
.DPSAXISAUDIOCLK (),
.DPLIVEVIDEOINVSYNC (),
.DPLIVEVIDEOINHSYNC (),
.DPLIVEVIDEOINDE (),
.DPLIVEVIDEOINPIXEL1 (),
.DPVIDEOINCLK (),
.DPVIDEOOUTHSYNC (),
.DPVIDEOOUTVSYNC (),
.DPVIDEOOUTPIXEL1 (),
.DPAUXDATAIN (),
.DPAUXDATAOUT (),
.DPAUXDATAOEN (),
.DPLIVEGFXALPHAIN (),
.DPLIVEGFXPIXEL1IN (),
.DPHOTPLUGDETECT (),
.DPEXTERNALCUSTOMEVENT1 (),
.DPEXTERNALCUSTOMEVENT2 (),
.DPEXTERNALVSYNCEVENT (),
.DPLIVEVIDEODEOUT (),
.PLPSEVENTI (),
.PSPLEVENTO (),
.PSPLSTANDBYWFE (),
.PSPLSTANDBYWFI (),
.PLPSAPUGICIRQ (),
.PLPSAPUGICFIQ (),
.RPUEVENTI0 (),
.RPUEVENTI1 (),
.RPUEVENTO0 (),
.RPUEVENTO1 (),
.NFIQ0LPDRPU (),
.NFIQ1LPDRPU (),
.NIRQ0LPDRPU (),
.NIRQ1LPDRPU (),
.STMEVENT (),
.PLPSTRIGACK (),
.PLPSTRIGGER (),
.PSPLTRIGACK (),
.PSPLTRIGGER (),
.FTMGPO (),
.FTMGPI (),
.PLPSIRQ0 (),
.PLPSIRQ1 (),
.PSPLIRQLPD (),
.PSPLIRQFPD (),
.OSCRTCCLK (),
.PLPMUGPI (),
.PMUPLGPO (),
.AIBPMUAFIFMFPDACK (),
.AIBPMUAFIFMLPDACK (),
.PMUAIBAFIFMFPDREQ (),
.PMUAIBAFIFMLPDREQ (),
.PMUERRORTOPL (),
.PMUERRORFROMPL (),
.DDRCEXTREFRESHRANK0REQ (),
.DDRCEXTREFRESHRANK1REQ (),
.DDRCREFRESHPLCLK (),
.PLACPINACT (),
.PLCLK (fclk),
.DPVIDEOREFCLK(),
.DPAUDIOREFCLK()
);


endmodule
