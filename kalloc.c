// Physical memory allocator, intended to allocate
// memory for user processes, kernel stacks, page table pages,
// and pipe buffers. Allocates 4096-byte pages.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "spinlock.h"

int frames[16384];
int pids[16384];
int count = 0;
int init2Done = 0;
int curPID = 0;

void freerange(void *vstart, void *vend);
extern char end[]; // first address after kernel loaded from ELF file
                   // defined by the kernel linker script in kernel.ld
// pages
struct run {
  struct run *next;
};

struct {
  struct spinlock lock; // mutual exclusion lock
  int use_lock;         // whether or not we using the lock
  struct run *freelist; // linked list of free run* structs (free list)
} kmem;

// Initialization happens in two phases.
// 1. main() calls kinit1() while still using entrypgdir to place just
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
  // initialize the lock for the kernal
  initlock(&kmem.lock, "kmem");
  // relinquish lock
  kmem.use_lock = 0;
  freerange(vstart, vend);
}

void
kinit2(void *vstart, void *vend)
{
  freerange(vstart, vend);
  // acquire lock
  kmem.use_lock = 1;
  init2Done = 1;
}

// free all pages within the range vstart, vend and add to freelist
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  // for(; p + PGSIZE <= (char*)vend; p += PGSIZE*2) // free every OTHER page
  //   kfree(p);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE) // free every OTHER page
    kfree(p);
}
// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);

  if(kmem.use_lock)
    acquire(&kmem.lock);
  // insert new freed page at FRONT of freelist
  r = (struct run*)v;
  r->next = kmem.freelist;
  kmem.freelist = r;
  if(kmem.use_lock)
    release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(int pid) // care about process id
{
  // PARAM CHANGE: track pid of process calling kalloc
  struct run *r;
  char* v;
  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = kmem.freelist;  // save next free frame in memory
  
  // store frame number and pid

  if (init2Done) {
    // different process call
    if (pid != 0 && pid != curPID) {
      // v = (char*)PGROUNDUP((uint)(&frames[count]));
      // // should free frame we just made
      // kfree(v);  // FIXME: lmao does this work

      count++;  // leave a free frame
      pids[count] = pid;
      curPID = pid; // track current pid
    }
    else if (pid == -1) { // UNKNOWN process
      pids[count] = -2;
    }

    frames[count] = ((V2P(r)) & ~0xFFF) >> 12; // virtual >> physical and mask
    // cprintf("%d\n", frames[count]);
    count++;
  }
  // return the first free page available in the free list
  if(r)
    kmem.freelist = r->next;
  if(kmem.use_lock)
    release(&kmem.lock);
  return (char*)r;
}

int
dump_physmem(int* frame, int* pid, int numframes)
{
  if (frame == 0 || pid == 0 || numframes < 0) {
    return -1;
  }
  //  int frames[16384];
  //  int pids[16384];
  for (int i = 0; i < numframes; ++i) {
    //cprintf("%d\n", frames[i]);
    *(frame + i) = frames[i];
    *(pid + i) = pids[i];
    // set all pids without pids to -2
    if (frames[i] != 0 && pids[i] < 1) {
      *(pid + i) = -2;
    }
    else if (frames[i] == 0) {
      // set all unused frames and corresponding pids to -1
      *(frame + i) = -1;
      *(pid + i) = -1;
    }
  }
  return 0;
}

