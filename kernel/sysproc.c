#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"


uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// sys_flip_display: zero-copy page flip.
//
// Syscall argument 0: user virtual address of a page-aligned buffer
// that is exactly GPU_FB_PAGES (300) * PGSIZE bytes (i.e. 640x480x4 =
// 1,228,800 bytes).  The buffer must already be fully mapped in the
// calling process's address space.
//
// TODO: Students implement this syscall.
uint64
sys_flip_display(void)
{
  printf("sys_flip_display called\n");
  uint64 buf;
  argaddr(0, &buf);
  if (buf % 4096 != 0){
    printf("sys_flip_display: buffer not page-aligned\n");
    return -1;
  }
  for(int i = 0; i < GPU_FB_PAGES; i++){
    pte_t *pte = walk(myproc()->pagetable, buf + i*PGSIZE, 0);
    if(pte == 0 || (*pte & PTE_V) == 0){
      printf("sys_flip_display: buffer not fully mapped\n");
      return -1;
    }
    if((*pte & PTE_U) == 0 || (*pte & PTE_R) == 0 || (*pte & PTE_W) == 0){
      printf("sys_flip_display: buffer not mapped with PTE_U|PTE_R|PTE_W\n");
      return -1;
    }
  }
  printf("sys_flip_display: buffer looks good, flipping display\n");
  return virtio_gpu_flip(buf);
  // return 1;
}

// sys_map_display: map the GPU's kernel framebuffer pages (fb[]) directly
// into the calling process's address space with PTE_U|PTE_R|PTE_W.
//
// Syscall argument 0: desired user virtual address (must be page-aligned).
//   Pass 0 to let the kernel auto-select the next available VA above p->sz.
//
// Returns the mapped virtual address on success, (uint64)-1 on failure.
//
// TODO: Students implement this syscall.
uint64
sys_map_display(void)
{
  uint64 addr;
  argaddr(0, &addr);
  uint64 answer = (uint64)map_display((void*)addr);
  printf("sys_map_display: addr=0x%p, answer=0x%p\n", addr, answer);
  return answer;
  
}
