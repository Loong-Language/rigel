/*
 * This test application is to read/write data directly from/to the device 
 * from userspace. 
 * 
 */
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <assert.h>
#include <stdbool.h>

#define MMIO_SIZE 16
#define MMIO_CMD 0
#define MMIO_STREAMBUF_NBYTES 1
#define MMIO_STREAMBUF_ADDR 2
#define MMIO_STATUS 3
#define MMIO_DEBUG0 4
#define MMIO_DEBUG1 5
#define MMIO_DEBUG2 6
#define MMIO_DEBUG3 7
#define MMIO_CAM_CMD 8
#define MMIO_CAM_RESP 9
#define MMIO_CAM_RESP_CNT 10

#define CAM_DELAY 0xF0F0
#define CAM_RESET 0x1280

typedef struct {
    uint32_t mmio[MMIO_SIZE];
} Conf;


void write_mmio(volatile Conf* conf, int offset, uint32_t data, int verbose) {
    if(verbose) {
        printf("MMIO WRITE: 0x%x to offset %x\n",data,offset);
    }
    conf->mmio[offset] = data;
}

uint32_t read_mmio(volatile Conf* conf, int offset, int verbose) {
    uint32_t data = conf->mmio[offset];
    if (verbose) {
        printf("MMIO READ: 0x%x from addr %x\n",data,offset);
    }
    return data;
}

void poll_mmio(volatile Conf* conf, int offset, uint32_t val) {
    uint32_t data;
    do {
        data = read_mmio(conf,offset,0);
    } while (data != val);
}

void print_debug_regs(volatile Conf* conf) {
    read_mmio(conf, MMIO_DEBUG0,1);
    read_mmio(conf, MMIO_DEBUG1,1);
    read_mmio(conf, MMIO_DEBUG2,1);
    read_mmio(conf, MMIO_DEBUG3,1);
}

// cam_data should contain the cam addr in the lowest byte
uint32_t read_cam_reg(volatile Conf* conf, uint32_t cam_data) {

    //cam data should only contain 8 bits
    if (cam_data & 0xFFFFFF00) {
        printf("ERROR: Bad cam addr! needs to be 1 byte\n");
        exit(1);
    }
    cam_data = (cam_data<<8); //bit 16 needs to be 0
    uint32_t cam_resp_cnt = read_mmio(conf, MMIO_CAM_RESP_CNT,0);
    //printf("cam_resp_cnt=%d\n",cam_resp_cnt);
    write_mmio(conf,MMIO_CAM_CMD, cam_data,0);
    // Wait for response (CAM_RESP_CNT will increment
    //poll_mmio(conf, MMIO_CAM_RESP_CNT, cam_resp_cnt+1);
    uint32_t cnt = 0;
    do {
        cnt = read_mmio(conf, MMIO_CAM_RESP_CNT,0);
    } while (cnt != cam_resp_cnt+1);
    read_mmio(conf, MMIO_DEBUG0,0);
    
    uint32_t cam_resp = read_mmio(conf, MMIO_CAM_RESP,0);
    printf("RD: Addr 0x%02x, data 0x%02x\n",cam_data>>8,(cam_resp)&0x000000FF);
    //Error checking
    // first 16:8 bits should be the same as cam_data;
    if ((cam_data & 0x0001FF00)!=(cam_resp & 0x0001FF00)) {
        printf("ERROR: cam response is not the same as cam_data!!\n");
        //exit(1);
    }
    //check that the error is not set
    if ((cam_data & 0x00020000) != (cam_resp & 0x00020000) ) {
        printf("ERROR: Cam response reports an error! Did you write before checking the response??\n");
        //exit(1);
    }
    return (cam_resp & 0x000000FF);
}

void write_cam_reg(volatile Conf* conf, uint32_t cam_data) {
    //cam data should only contain 16 bits
    if (cam_data & 0xFFFF0000) {
        printf("ERROR:Bad cam reg data! %x should be 1byte addr, 1byte data\n",cam_data);
        exit(1);
    }
    cam_data |= 0x10000; //bit 16 is the write cmd
    uint32_t cam_resp_cnt = read_mmio(conf, MMIO_CAM_RESP_CNT,0);
    //printf("cam_resp_cnt=%d\n",cam_resp_cnt);
    write_mmio(conf,MMIO_CAM_CMD, cam_data,0);
    // Wait for response (CAM_RESP_CNT will increment
    uint32_t cnt = 0;
    do {
        cnt = read_mmio(conf, MMIO_CAM_RESP_CNT,0);
    } while (cnt != cam_resp_cnt+1);
    read_mmio(conf, MMIO_DEBUG0,0);
    uint32_t cam_resp = read_mmio(conf, MMIO_CAM_RESP,0);
    printf("WR: Addr 0x%02x, data 0x%02x\n",(cam_data>>8)&0x000000FF,(cam_resp)&0x000000FF);
    //Error checking
    // first 16 bits should be the same as cam_data;
    if ((cam_data & 0x0001FFFF)!=(cam_resp & 0x0001FFFF)) {
        printf("ERROR: cam response is not the same as cam_data!!\n");
        //exit(1);
    }
    //check that the error is not set
    if ((cam_data & 0x00020000) != (cam_resp & 0x00020000) ) {
        printf("ERROR:Cam response reports an error! Did you write before checking the response??\n");
        //exit(1);
    }
}

FILE* openImage(char* filename, int* numbytes){
  FILE* infile = fopen(filename, "rb");
  if(infile==NULL){
    printf("File not found %s\n",filename);
    exit(1);
  }
  fseek(infile, 0L, SEEK_END);
  *numbytes = ftell(infile);
  fseek(infile, 0L, SEEK_SET);

  return infile;
}

void loadImage(FILE* infile,  volatile void* address, int numbytes){
  int outlen = fread(address, sizeof(char), numbytes, infile);
  if(outlen!=numbytes){
    printf("ERROR READING\n");
  }

  fclose(infile);
}

bool isPowerOf2(unsigned int x) {
  return x && !(x & (x - 1));
}

// we don't have a standard library... so reimplement this badly
unsigned int mylog2(unsigned int x){
  printf("mylog2\n");
  unsigned int res = 0;
  // find highest true bit
  while(x=x>>1){printf("H%d\n",x);res++;}
  return res;
}

int saveImage(char* filename,  volatile void* address, int numbytes){
    FILE* outfile = fopen(filename, "wb");
    if(outfile==NULL){
        printf("could not open for writing %s\n",filename);
        exit(1);
    }
    int outlen = fwrite(address,1,numbytes,outfile);
    if(outlen!=numbytes){
        printf("ERROR WRITING\n");
    }
    printf("Saving image %s, at address %p, with numbytes %d, bytes written %d\n",filename,address, numbytes,outlen);
    fclose(outfile);
}
void write_cam_safe(volatile Conf* conf, uint32_t cam_data) {
    write_cam_reg(conf,cam_data);
    uint32_t cam_a = 0x000000FF & (cam_data>>8);
    uint32_t cam_d = 0x000000FF & (cam_data);
    uint32_t rd = read_cam_reg(conf,cam_a);
    if(cam_d != rd) {
        printf("ERROR:\nExpt: %08x\nRead:%08x\n",cam_data,rd);
    }
}

void init_camera(volatile Conf* conf) {
    int x = 0;
    write_cam_reg(conf, 0xF0F0); // delay
    write_cam_reg(conf, 0x1280); // Reset
    write_cam_reg(conf, 0xF0F0); // delay
    write_cam_reg(conf, 0xF0F0); // delay
    printf("\n\n");
    write_cam_safe(conf,0x1140);
    write_cam_safe(conf,0x1205);
    write_cam_safe(conf,0x1500);
    
    /*
    for(x=0; x<256; x++) {
        read_cam_reg(conf, x);
        write_cam_reg(conf, (x<<8)|0xAA); 
        read_cam_reg(conf, x);
        write_cam_reg(conf, (x<<8)|0x55); 
        read_cam_reg(conf, x);
        printf("--------------------\n");
    }
    */
    write_cam_reg(conf, 0xF0F0); // delay
    write_cam_reg(conf, 0xF0F0); // delay
}

int main(int argc, char *argv[]) {
    unsigned gpio_addr = 0x70000000;
    unsigned stream_addr = 0x30008000;
    uint32_t frame_size = 640*480;
    int streambuf_size = frame_size * 8;
    unsigned page_size = sysconf(_SC_PAGESIZE);
    
    char* raw_name= "/tmp/out.raw";
    char* ppm_name = "out.ppm";
    
    printf("GPIO access through /dev/mem. %d\n", page_size);

    int fd = open ("/dev/mem", O_RDWR);
    if (fd < 1) {
        perror(argv[0]);
        return -1;
    }

    printf("mapping %08x\n",stream_addr);
    void * stream_ptr = mmap(NULL, streambuf_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, stream_addr);
    if (stream_ptr == MAP_FAILED) {
        printf("FAILED mmap for streamaddr %x\n",stream_addr);
        exit(1);
    }
    
    // mmap the device into memory 
    // This mmaps the control region (the MMIO for the control registers).
    void * gpioptr = mmap(NULL, page_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, gpio_addr);
    if (gpioptr == MAP_FAILED) {
        printf("FAILED mmap for gpio_addr %x\n",gpio_addr);
        exit(1);
    }
   
    volatile Conf * conf = (Conf*) gpioptr;
    
    // writes camera registers
    init_camera(conf);
    printf("Camera programmed!s\n");
    write_mmio(conf, MMIO_STREAMBUF_ADDR, stream_addr,1);
    write_mmio(conf, MMIO_STREAMBUF_NBYTES, frame_size*4,1);
    print_debug_regs(conf);
    printf("WAIT 1s\n");
    sleep(1);
    // Start stream
    printf("START STREAM\n");
    write_mmio(conf, MMIO_CMD, 0x5,1);
    printf("WAIT 5s\n");
    sleep(5);
    print_debug_regs(conf);
    
    saveImage(raw_name,stream_ptr,frame_size);

  return 0;
}



