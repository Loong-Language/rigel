#include <verilated.h>
#include <iostream>
#include <stdio.h>
#include VERILATORFILE
#include <queue>

typedef struct{unsigned int addr; unsigned int burst;} Transaction;

float randf(){ return (float)rand()/(float)(RAND_MAX); }

unsigned int MEMBASE = 0x30008000;
unsigned int MEMSIZE = 8192*2;
unsigned char* memory;

const unsigned int PORTS = 4;
std::queue<Transaction> readQ[PORTS];
std::queue<Transaction> writeQ[PORTS];

#define S0LIST top->IP_CLK,top->IP_ARESET_N,top->SAXI0_ARADDR,top->SAXI0_ARVALID,top->SAXI0_ARREADY,top->SAXI0_AWADDR,top->SAXI0_AWVALID,top->SAXI0_AWREADY,top->SAXI0_RDATA,top->SAXI0_RVALID,top->SAXI0_RREADY

#define M0LIST 0,top->IP_CLK,top->IP_ARESET_N,top->MAXI0_ARADDR,top->MAXI0_ARVALID,top->MAXI0_ARREADY,top->MAXI0_RDATA,top->MAXI0_RVALID,top->MAXI0_RREADY

#define M0READLIST 0,top->MAXI0_ARADDR,top->MAXI0_ARVALID,top->MAXI0_ARREADY,top->MAXI0_RDATA,top->MAXI0_RVALID,top->MAXI0_RREADY,top->MAXI0_RRESP,top->MAXI0_RLAST,top->MAXI0_ARLEN,top->MAXI0_ARSIZE,top->MAXI0_ARBURST

#define M0WRITELIST 0,top->MAXI0_AWADDR,top->MAXI0_AWVALID,top->MAXI0_AWREADY,top->MAXI0_WDATA,top->MAXI0_WVALID,top->MAXI0_WREADY,top->MAXI0_BRESP,top->MAXI0_BVALID,top->MAXI0_BREADY,top->MAXI0_WSTRB,top->MAXI0_WLAST,top->MAXI0_AWLEN,top->MAXI0_AWSIZE,top->MAXI0_AWBURST

#define M1READLIST 1,top->MAXI1_ARADDR,top->MAXI1_ARVALID,top->MAXI1_ARREADY,top->MAXI1_RDATA,top->MAXI1_RVALID,top->MAXI1_RREADY,top->MAXI1_RRESP,top->MAXI1_RLAST,top->MAXI1_ARLEN,top->MAXI1_ARSIZE,top->MAXI1_ARBURST

#define M1WRITELIST 1,top->MAXI1_AWADDR,top->MAXI1_AWVALID,top->MAXI1_AWREADY,top->MAXI1_WDATA,top->MAXI1_WVALID,top->MAXI1_WREADY,top->MAXI1_BRESP,top->MAXI1_BVALID,top->MAXI1_BREADY,top->MAXI1_WSTRB,top->MAXI1_WLAST,top->MAXI1_AWLEN,top->MAXI1_AWSIZE,top->MAXI1_AWBURST

void printSlave(
  unsigned char& IP_CLK,
  unsigned char& IP_ARESET_N,
  unsigned int& ARADDR,
  unsigned char& ARVALID,
  unsigned char& ARREADY,
  unsigned int& AWADDR,
  unsigned char& AWVALID,
  unsigned char& AWREADY,
  unsigned int& RDATA,
  unsigned char& RVALID,
  unsigned char& RREADY){

  std::cout << "----------------------" << std::endl;
  std::cout << "IP_CLK(in): " << (int)IP_CLK << std::endl;
  std::cout << "IP_ARESET_N(in): " << (int)IP_ARESET_N << std::endl;
  std::cout << "S_ARADDR(in): " << ARADDR << std::endl;
  std::cout << "S_ARVALID(in): " << (int)ARVALID << std::endl;
  std::cout << "S_ARREADY(out): " << (int)ARREADY << std::endl;
  std::cout << "S_AWADDR(in): " << AWADDR << "/" << std::hex << AWADDR  << std::dec<< std::endl;
  std::cout << "S_AWVALID(in): " << (int)AWVALID << std::endl;
  std::cout << "S_AWREADY(out): " << (int)AWREADY << std::endl;
  std::cout << "S_RDATA(out): " << RDATA << std::endl;
  std::cout << "S_RVALID(out): " << (int)RVALID << std::endl;
  std::cout << "S_RREADY(in): " << (int)RREADY << std::endl;
}

void printMasterRead(
  int id,
  unsigned char& IP_CLK,
  unsigned char& IP_ARESET_N,
  unsigned int& ARADDR,
  unsigned char& ARVALID,
  unsigned char& ARREADY,
  unsigned long& RDATA,
  unsigned char& RVALID,
  unsigned char& RREADY){

  std::cout << "----------------------" << std::endl;
  std::cout << "IP_CLK(in): " << (int)IP_CLK << std::endl;
  std::cout << "IP_ARESET_N(in): " << (int)IP_ARESET_N << std::endl;
  std::cout << "M" << id << "_ARADDR(out): " << ARADDR << "/" << std::hex << ARADDR  << std::dec<< std::endl;
  std::cout << "M" << id << "_ARVALID(out): " << (int)ARVALID << std::endl;
  std::cout << "M" << id << "_ARREADY(in): " << (int)ARREADY << std::endl;
}

// return data to master
void masterReadData(
  bool verbose,
  int port,
  const unsigned int& ARADDR,
  const unsigned char& ARVALID,
  unsigned char& ARREADY,
  unsigned long& RDATA,
  unsigned char& RVALID,
  unsigned char& RREADY,
  unsigned char& RRESP,
  unsigned char& RLAST,
  unsigned char& ARLEN,
  unsigned char& ARSIZE,
  unsigned char& ARBURST){

  if(readQ[port].size()>0 && RREADY){
    if(false && randf()>0.2f){
      RVALID = false;
    }else{
      Transaction& t = readQ[port].front();
      
      RDATA = *(unsigned long*)(&memory[t.addr]);
      RVALID = true;
      
      if(verbose){
        std::cout << "MAXI" << port << " Service Read Addr: " << t.addr << " data: " << RDATA << " remaining_burst: " << t.burst << " outstanding_requests: " << readQ[port].size() << std::endl;
      }
      
      t.burst--;
      t.addr+=8;
      
      if(t.burst==0){
        readQ[port].pop();
      }
    }
  }else if(readQ[port].size()>0 && RREADY){
    std::cout << readQ[port].size() << " outstanding read requests, but IP isn't ready" << std::endl;
  }else{
    if(verbose){std::cout << "MAXI" << port << " no outstanding read requests" << std::endl;}
    RVALID = false;
  }
}

// service read requests from master
void masterReadReq(
  bool verbose,
  int port,
  const unsigned int& ARADDR,
  const unsigned char& ARVALID,
  unsigned char& ARREADY,
  unsigned long& RDATA,
  unsigned char& RVALID,
  unsigned char& RREADY,
  unsigned char& RRESP,
  unsigned char& RLAST,
  unsigned char& ARLEN,
  unsigned char& ARSIZE,
  unsigned char& ARBURST){

  if(ARVALID){
    // read request
    Transaction t;
    assert(ARSIZE==3);
    assert(ARBURST==1);
    t.addr = ARADDR;
    t.burst = ARLEN+1;

    if(verbose){
      std::cout << "MAXI" << port << "Read Request addr:" << t.addr << "/" << std::hex << t.addr << std::dec << " burst:" << t.burst << std::endl;
      std::cout << "MAXI" << port << "Read Request addr (base rel):" << (t.addr-MEMBASE) << "/" << std::hex << (t.addr-MEMBASE) << std::dec << " burst:" << t.burst << std::endl;
    }
    
    t.addr -= MEMBASE;

    if(t.addr>=MEMSIZE){
      std::cout << "Segmentation fault on read!" << std::endl;
      exit(1);
    }
    
    readQ[port].push(t);
  }else{
    if(verbose){std::cout << "MAXI" << port <<" no read request!" << std::endl;}
  }
}

// return data to master
void masterWriteData(
  bool verbose,
  int port,
  unsigned int& AWADDR,
  unsigned char& AWVALID,
  unsigned char& AWREADY,
  unsigned long& WDATA,
  unsigned char& WVALID,
  unsigned char& WREADY,
  unsigned char& BRESP,
  unsigned char& BVALID,
  unsigned char& BREADY,
  unsigned char& WSTRB,
  unsigned char& WLAST,
  unsigned char& AWLEN,
  unsigned char& AWSIZE,
  unsigned char& AWBURST){

  assert(WREADY); // we drive this... should always be true
  
  if( writeQ[port].size()>0 && WVALID ){
    Transaction& t = writeQ[port].front();

    *(unsigned long*)(&memory[t.addr]) = WDATA;

    if(verbose){
      std::cout << "MAXI" << port << " Accept Write, Addr: " << t.addr << " data: " << WDATA << " remaining_burst: " << t.burst << " outstanding_requests: " << writeQ[port].size() << std::endl;
    }
    
    t.burst--;
    t.addr+=8;
    
    if(t.burst==0){
      writeQ[port].pop();
    }
  }else if( writeQ[port].size()<=0 && WVALID ){
    std::cout << "Error: attempted to write data, but there was no outstanding write addresses!" << std::endl;
    exit(1);
  }else{
    if(verbose){std::cout << "MAXI" << port << " no write request" << std::endl;}
  }
}

void masterWriteReq(
  bool verbose,
  int port,
  unsigned int& AWADDR,
  unsigned char& AWVALID,
  unsigned char& AWREADY,
  unsigned long& WDATA,
  unsigned char& WVALID,
  unsigned char& WREADY,
  unsigned char& BRESP,
  unsigned char& BVALID,
  unsigned char& BREADY,
  unsigned char& WSTRB,
  unsigned char& WLAST,
  unsigned char& AWLEN,
  unsigned char& AWSIZE,
  unsigned char& AWBURST){

  if(AWVALID){
    assert(AWSIZE==3);
    assert(AWBURST==1);
    assert(WSTRB==255);
    
    Transaction t;
    t.addr = AWADDR;
    t.burst = AWLEN+1;

    if(verbose){
      std::cout << "MAXI" << port << " Write Request addr:" << t.addr << "/" << std::hex << t.addr << std::dec << " burst:" << t.burst << std::endl;
      std::cout << "MAXI" << port << " Write Request addr (base rel):" << (t.addr-MEMBASE) << "/" << std::hex << (t.addr-MEMBASE) << std::dec << " burst:" << t.burst << std::endl;
    }
    
    t.addr -= MEMBASE;

    if(t.addr>=MEMSIZE){
      std::cout << "MAXI" << port << " Segmentation fault on write!" << std::endl;
      exit(1);
    }

    writeQ[port].push(t);
  }
}

void step(VERILATORCLASS* top){
  top->IP_CLK = 0;
  top->eval();
  top->IP_CLK = 1;
  top->eval();
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv); 

  printf("Usage: XXX.verilator simCycles memStart memEnd [--verbose] --inputs file1.raw address1 file2.raw address2 --outputs ofile1.raw address w h bitsPerPixel\n");

  int simCycles = atoi(argv[1]);
  MEMBASE = strtol(argv[2],NULL,16);
  MEMSIZE = strtol(argv[3],NULL,16)-MEMBASE;

  std::cout << "SimCycles: " << simCycles << " MemBase: 0x" << std::hex << MEMBASE << std::dec << " MemSize: " << MEMSIZE << std::endl;

  bool verbose = false;
  int curArg = 4;

  if(strcmp(argv[curArg],"--verbose")==0){
    verbose = true;
    curArg++;
  }

  if(strcmp(argv[curArg],"--inputs")!=0){
    std::cout << "fourth argument should be '--inputs' but is " << argv[4] << std::endl;
  }else{
    curArg++;
  }

  int inputCount = 0;

  memory = (unsigned char*)malloc(MEMSIZE);
    
  while(strcmp(argv[curArg],"--outputs")!=0){
    unsigned int addr = strtol(argv[curArg+1],NULL,16);
    unsigned int addrOffset = addr-MEMBASE;
    
    FILE* infile = fopen(argv[curArg],"rb");
    if(infile==NULL){printf("could not open input '%s'\n", argv[curArg]);}
    fseek(infile, 0L, SEEK_END);
    unsigned long insize = ftell(infile);
    fseek(infile, 0L, SEEK_SET);
    fread( memory+addrOffset, insize, 1, infile );
    fclose( infile );
    
    std::cout << "Input File " << inputCount << ": filename=" << argv[curArg] << " address=0x" << std::hex << addr << " addressOffset=0x" << addrOffset << std::dec << " bytes=" << insize <<std::endl;
    inputCount++;
    curArg+=2;
  }
  
  VERILATORCLASS* top = new VERILATORCLASS;

  bool CLK = false;
  

  
  unsigned long totalCycles = 0;

  // NOTE: you'd think we could check for overflows (too many output packets), but actually we can't
  // some of our modules start producing data immediately for the next frame, which is valid behavior (ie pad)

  if(verbose){printSlave(S0LIST);}
  
  for(int i=0; i<100; i++){
    CLK = !CLK;

    top->IP_CLK = CLK;
    top->IP_ARESET_N = false;
    //top->SAXI0_ARREADY = true;
    //top->SAXI0_AWREADY = true;
    top->SAXI0_AWVALID = false;
    top->SAXI0_ARVALID = false;
    top->SAXI0_BREADY = true;
    top->SAXI0_RREADY = true;
    //top->SAXI0_WREADY = true;

    top->MAXI0_ARREADY = true;
    top->MAXI0_RREADY = true;
    top->MAXI0_AWREADY = true;
    top->MAXI0_WREADY = true;
    top->MAXI0_BREADY = true;

    top->MAXI1_ARREADY = true;
    top->MAXI1_RREADY = true;
    top->MAXI1_AWREADY = true;
    top->MAXI1_WREADY = true;
    top->MAXI1_BREADY = true;

    top->eval();
  }

  top->IP_ARESET_N=true;
  step(top);
  if(verbose){printSlave(S0LIST);}

  step(top);
  if(verbose){printSlave(S0LIST);}

  step(top);
  if(verbose){printSlave(S0LIST);}
  
  // send start cmd
  top->SAXI0_AWADDR = 0xA0000000;
  top->SAXI0_AWVALID = true;
  step(top);
  if(verbose){printSlave(S0LIST);}

  assert(top->SAXI0_WREADY==1);
  top->SAXI0_WDATA = 1;
  top->SAXI0_WVALID = 1;
  step(top);

  top->SAXI0_AWVALID = false;
  step(top);
    
  while (!Verilated::gotFinish() && totalCycles<simCycles ) {
    if(CLK){
      // feed data in
      masterReadData(verbose,M0READLIST);
      masterWriteData(verbose,M0WRITELIST);
      
      masterReadData(verbose,M1READLIST);
      masterWriteData(verbose,M1WRITELIST);

      // it's possible the pipeline has 0 cycle delay. in which case, we need to eval the async stuff here.
      top->eval();

      if(verbose){printMasterRead(M0LIST);}
  

      // get data out
      masterReadReq(verbose,M0READLIST);
      masterWriteReq(verbose,M0WRITELIST);

      masterReadReq(verbose,M1READLIST);
      masterWriteReq(verbose,M1WRITELIST);

      totalCycles++;
    }

    CLK = !CLK;

    top->IP_CLK = CLK;
    top->IP_ARESET_N = true;
    top->eval();
  }

  top->final();
  delete top;

  printf("Cycles: %d\n", (int)totalCycles);

  curArg++; // for "--outputs"
  unsigned int outputCount = 0;
  while(curArg<argc){
    unsigned int addr = strtol(argv[curArg+1],NULL,16);
    unsigned int addrOffset = addr-MEMBASE;

    unsigned int w = atoi(argv[curArg+2]);
    unsigned int h = atoi(argv[curArg+3]);
    unsigned int bitsPerPixel = atoi(argv[curArg+4]);

    if( bitsPerPixel%8!=0 ){
      std::cout << "Error, bits per pixel not byte aligned!" << std::endl;
      exit(1);
    }

    unsigned int bytes = w*h*(bitsPerPixel/8);

    std::string outFilename = std::string(argv[curArg])+std::string(".verilatorSOC.raw");
    
    std::cout << "Output File " << outputCount << ": filename=" << outFilename << " address=0x" << std::hex << addr << " addressOffset=0x" << addrOffset << std::dec << " W=" << w <<" H="<<h<<" bitsPerPixel="<<bitsPerPixel<<" bytes="<<bytes<<std::endl;
    
    FILE* outfile = fopen(outFilename.c_str(),"wb");
    if(outfile==NULL){printf("could not open output '%s'\n", outFilename.c_str());}
    fwrite( memory+addrOffset, bytes, 1, outfile);
    fclose(outfile);

    curArg+=5;
    outputCount++;
  }

  for(int port=0; port<PORTS; port++){
    if(readQ[port].size()>0){
      std::cout << "MAXI" << port << " Error, outstanding read requests at end of time! cnt:" << readQ[port].size() << std::endl;
      exit(1);
    }
    
    if(writeQ[port].size()>0){
      std::cout << "MAXI" << port << " Error, outstanding write requests at end of time! cnt:" << writeQ[port].size() << std::endl;
      exit(1);
    }
  }
}
