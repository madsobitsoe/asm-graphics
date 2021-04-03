#include <linux/fb.h>
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <string.h>

uint32_t pixel_color(uint8_t r, uint8_t g, uint8_t b, struct fb_var_screeninfo *vinfo)
{
  return (r<<vinfo->red.offset) | (g<<vinfo->green.offset) | (b<<vinfo->blue.offset);
}

int main()
{
  struct fb_fix_screeninfo finfo;
  struct fb_var_screeninfo vinfo;

  int fb_fd = open("/dev/fb0",O_RDWR);

  //Get variable screen information
  ioctl(fb_fd, FBIOGET_VSCREENINFO, &vinfo);
  vinfo.grayscale=0;
  vinfo.bits_per_pixel=32;
  ioctl(fb_fd, FBIOPUT_VSCREENINFO, &vinfo);
  ioctl(fb_fd, FBIOGET_VSCREENINFO, &vinfo);

  ioctl(fb_fd, FBIOGET_FSCREENINFO, &finfo);

  long screensize = vinfo.yres_virtual * finfo.line_length;

  //uint8_t *fbp = mmap(0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fb_fd, (off_t)0);
  uint8_t *fbp = mmap(0, finfo.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fb_fd, (off_t)0);


  printf("Screensize x,y: %d,%d\n", vinfo.xres,vinfo.yres);

  /* int x,y; */
  /* for (x=0;x<vinfo.xres;x++) */
  /*    { */
  /*      for (y=0;y<vinfo.yres;y++) */
  /*        { */
  /*          uint32_t location = (x+vinfo.xoffset) * (vinfo.bits_per_pixel/8) + (y+vinfo.yoffset) * finfo.line_length; */
  /*          printf("location: %x\n", location); */
  /*          printf("fbp: %p\n", fbp); */
  /*          printf("Val: %02x\n", fbp[location]); */
  /*          //\*((uint32_t*)p) = pixel_color(0xFF,0x00,0xFF, &vinfo); */
  /*        } */
  /*    } */
  memset(fbp, 128, finfo.smem_len);

  sleep(2);
               return 0;
               }
