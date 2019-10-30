
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 80 10 00       	mov    $0x108000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc d0 a5 10 80       	mov    $0x8010a5d0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 2c 2b 10 80       	mov    $0x80102b2c,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	57                   	push   %edi
80100038:	56                   	push   %esi
80100039:	53                   	push   %ebx
8010003a:	83 ec 18             	sub    $0x18,%esp
8010003d:	89 c6                	mov    %eax,%esi
8010003f:	89 d7                	mov    %edx,%edi
  struct buf *b;

  acquire(&bcache.lock);
80100041:	68 e0 a5 10 80       	push   $0x8010a5e0
80100046:	e8 12 3c 00 00       	call   80103c5d <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 30 ed 10 80    	mov    0x8010ed30,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb dc ec 10 80    	cmp    $0x8010ecdc,%ebx
8010005f:	74 30                	je     80100091 <bget+0x5d>
    if(b->dev == dev && b->blockno == blockno){
80100061:	39 73 04             	cmp    %esi,0x4(%ebx)
80100064:	75 f0                	jne    80100056 <bget+0x22>
80100066:	39 7b 08             	cmp    %edi,0x8(%ebx)
80100069:	75 eb                	jne    80100056 <bget+0x22>
      b->refcnt++;
8010006b:	8b 43 4c             	mov    0x4c(%ebx),%eax
8010006e:	83 c0 01             	add    $0x1,%eax
80100071:	89 43 4c             	mov    %eax,0x4c(%ebx)
      release(&bcache.lock);
80100074:	83 ec 0c             	sub    $0xc,%esp
80100077:	68 e0 a5 10 80       	push   $0x8010a5e0
8010007c:	e8 41 3c 00 00       	call   80103cc2 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 bd 39 00 00       	call   80103a49 <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 2c ed 10 80    	mov    0x8010ed2c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb dc ec 10 80    	cmp    $0x8010ecdc,%ebx
801000a2:	74 43                	je     801000e7 <bget+0xb3>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
801000a4:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801000a8:	75 ef                	jne    80100099 <bget+0x65>
801000aa:	f6 03 04             	testb  $0x4,(%ebx)
801000ad:	75 ea                	jne    80100099 <bget+0x65>
      b->dev = dev;
801000af:	89 73 04             	mov    %esi,0x4(%ebx)
      b->blockno = blockno;
801000b2:	89 7b 08             	mov    %edi,0x8(%ebx)
      b->flags = 0;
801000b5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
      b->refcnt = 1;
801000bb:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
      release(&bcache.lock);
801000c2:	83 ec 0c             	sub    $0xc,%esp
801000c5:	68 e0 a5 10 80       	push   $0x8010a5e0
801000ca:	e8 f3 3b 00 00       	call   80103cc2 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 6f 39 00 00       	call   80103a49 <acquiresleep>
      return b;
801000da:	83 c4 10             	add    $0x10,%esp
    }
  }
  panic("bget: no buffers");
}
801000dd:	89 d8                	mov    %ebx,%eax
801000df:	8d 65 f4             	lea    -0xc(%ebp),%esp
801000e2:	5b                   	pop    %ebx
801000e3:	5e                   	pop    %esi
801000e4:	5f                   	pop    %edi
801000e5:	5d                   	pop    %ebp
801000e6:	c3                   	ret    
  panic("bget: no buffers");
801000e7:	83 ec 0c             	sub    $0xc,%esp
801000ea:	68 80 65 10 80       	push   $0x80106580
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 91 65 10 80       	push   $0x80106591
80100100:	68 e0 a5 10 80       	push   $0x8010a5e0
80100105:	e8 17 3a 00 00       	call   80103b21 <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 2c ed 10 80 dc 	movl   $0x8010ecdc,0x8010ed2c
80100111:	ec 10 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 30 ed 10 80 dc 	movl   $0x8010ecdc,0x8010ed30
8010011b:	ec 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 30 ed 10 80       	mov    0x8010ed30,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 dc ec 10 80 	movl   $0x8010ecdc,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 98 65 10 80       	push   $0x80106598
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 ce 38 00 00       	call   80103a16 <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 30 ed 10 80       	mov    0x8010ed30,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 30 ed 10 80    	mov    %ebx,0x8010ed30
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb dc ec 10 80    	cmp    $0x8010ecdc,%ebx
80100165:	72 c1                	jb     80100128 <binit+0x34>
}
80100167:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010016a:	c9                   	leave  
8010016b:	c3                   	ret    

8010016c <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
8010016c:	55                   	push   %ebp
8010016d:	89 e5                	mov    %esp,%ebp
8010016f:	53                   	push   %ebx
80100170:	83 ec 04             	sub    $0x4,%esp
  struct buf *b;

  b = bget(dev, blockno);
80100173:	8b 55 0c             	mov    0xc(%ebp),%edx
80100176:	8b 45 08             	mov    0x8(%ebp),%eax
80100179:	e8 b6 fe ff ff       	call   80100034 <bget>
8010017e:	89 c3                	mov    %eax,%ebx
  if((b->flags & B_VALID) == 0) {
80100180:	f6 00 02             	testb  $0x2,(%eax)
80100183:	74 07                	je     8010018c <bread+0x20>
    iderw(b);
  }
  return b;
}
80100185:	89 d8                	mov    %ebx,%eax
80100187:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010018a:	c9                   	leave  
8010018b:	c3                   	ret    
    iderw(b);
8010018c:	83 ec 0c             	sub    $0xc,%esp
8010018f:	50                   	push   %eax
80100190:	e8 77 1c 00 00       	call   80101e0c <iderw>
80100195:	83 c4 10             	add    $0x10,%esp
  return b;
80100198:	eb eb                	jmp    80100185 <bread+0x19>

8010019a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
8010019a:	55                   	push   %ebp
8010019b:	89 e5                	mov    %esp,%ebp
8010019d:	53                   	push   %ebx
8010019e:	83 ec 10             	sub    $0x10,%esp
801001a1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001a4:	8d 43 0c             	lea    0xc(%ebx),%eax
801001a7:	50                   	push   %eax
801001a8:	e8 26 39 00 00       	call   80103ad3 <holdingsleep>
801001ad:	83 c4 10             	add    $0x10,%esp
801001b0:	85 c0                	test   %eax,%eax
801001b2:	74 14                	je     801001c8 <bwrite+0x2e>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001b4:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001b7:	83 ec 0c             	sub    $0xc,%esp
801001ba:	53                   	push   %ebx
801001bb:	e8 4c 1c 00 00       	call   80101e0c <iderw>
}
801001c0:	83 c4 10             	add    $0x10,%esp
801001c3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001c6:	c9                   	leave  
801001c7:	c3                   	ret    
    panic("bwrite");
801001c8:	83 ec 0c             	sub    $0xc,%esp
801001cb:	68 9f 65 10 80       	push   $0x8010659f
801001d0:	e8 73 01 00 00       	call   80100348 <panic>

801001d5 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
801001d5:	55                   	push   %ebp
801001d6:	89 e5                	mov    %esp,%ebp
801001d8:	56                   	push   %esi
801001d9:	53                   	push   %ebx
801001da:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001dd:	8d 73 0c             	lea    0xc(%ebx),%esi
801001e0:	83 ec 0c             	sub    $0xc,%esp
801001e3:	56                   	push   %esi
801001e4:	e8 ea 38 00 00       	call   80103ad3 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 9f 38 00 00       	call   80103a98 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80100200:	e8 58 3a 00 00       	call   80103c5d <acquire>
  b->refcnt--;
80100205:	8b 43 4c             	mov    0x4c(%ebx),%eax
80100208:	83 e8 01             	sub    $0x1,%eax
8010020b:	89 43 4c             	mov    %eax,0x4c(%ebx)
  if (b->refcnt == 0) {
8010020e:	83 c4 10             	add    $0x10,%esp
80100211:	85 c0                	test   %eax,%eax
80100213:	75 2f                	jne    80100244 <brelse+0x6f>
    // no one is waiting for it.
    b->next->prev = b->prev;
80100215:	8b 43 54             	mov    0x54(%ebx),%eax
80100218:	8b 53 50             	mov    0x50(%ebx),%edx
8010021b:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
8010021e:	8b 43 50             	mov    0x50(%ebx),%eax
80100221:	8b 53 54             	mov    0x54(%ebx),%edx
80100224:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
80100227:	a1 30 ed 10 80       	mov    0x8010ed30,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 dc ec 10 80 	movl   $0x8010ecdc,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 30 ed 10 80       	mov    0x8010ed30,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 30 ed 10 80    	mov    %ebx,0x8010ed30
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 e0 a5 10 80       	push   $0x8010a5e0
8010024c:	e8 71 3a 00 00       	call   80103cc2 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 a6 65 10 80       	push   $0x801065a6
80100263:	e8 e0 00 00 00       	call   80100348 <panic>

80100268 <consoleread>:
  }
}

int
consoleread(struct inode *ip, char *dst, int n)
{
80100268:	55                   	push   %ebp
80100269:	89 e5                	mov    %esp,%ebp
8010026b:	57                   	push   %edi
8010026c:	56                   	push   %esi
8010026d:	53                   	push   %ebx
8010026e:	83 ec 28             	sub    $0x28,%esp
80100271:	8b 7d 08             	mov    0x8(%ebp),%edi
80100274:	8b 75 0c             	mov    0xc(%ebp),%esi
80100277:	8b 5d 10             	mov    0x10(%ebp),%ebx
  uint target;
  int c;

  iunlock(ip);
8010027a:	57                   	push   %edi
8010027b:	e8 c3 13 00 00       	call   80101643 <iunlock>
  target = n;
80100280:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100283:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
8010028a:	e8 ce 39 00 00       	call   80103c5d <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 c0 ef 10 80       	mov    0x8010efc0,%eax
8010029f:	3b 05 c4 ef 10 80    	cmp    0x8010efc4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 12 30 00 00       	call   801032be <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 95 10 80       	push   $0x80109520
801002ba:	68 c0 ef 10 80       	push   $0x8010efc0
801002bf:	e8 9e 34 00 00       	call   80103762 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 95 10 80       	push   $0x80109520
801002d1:	e8 ec 39 00 00       	call   80103cc2 <release>
        ilock(ip);
801002d6:	89 3c 24             	mov    %edi,(%esp)
801002d9:	e8 a3 12 00 00       	call   80101581 <ilock>
        return -1;
801002de:	83 c4 10             	add    $0x10,%esp
801002e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  release(&cons.lock);
  ilock(ip);

  return target - n;
}
801002e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801002e9:	5b                   	pop    %ebx
801002ea:	5e                   	pop    %esi
801002eb:	5f                   	pop    %edi
801002ec:	5d                   	pop    %ebp
801002ed:	c3                   	ret    
    c = input.buf[input.r++ % INPUT_BUF];
801002ee:	8d 50 01             	lea    0x1(%eax),%edx
801002f1:	89 15 c0 ef 10 80    	mov    %edx,0x8010efc0
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 8a 40 ef 10 80 	movzbl -0x7fef10c0(%edx),%ecx
80100303:	0f be d1             	movsbl %cl,%edx
    if(c == C('D')){  // EOF
80100306:	83 fa 04             	cmp    $0x4,%edx
80100309:	74 14                	je     8010031f <consoleread+0xb7>
    *dst++ = c;
8010030b:	8d 46 01             	lea    0x1(%esi),%eax
8010030e:	88 0e                	mov    %cl,(%esi)
    --n;
80100310:	83 eb 01             	sub    $0x1,%ebx
    if(c == '\n')
80100313:	83 fa 0a             	cmp    $0xa,%edx
80100316:	74 11                	je     80100329 <consoleread+0xc1>
    *dst++ = c;
80100318:	89 c6                	mov    %eax,%esi
8010031a:	e9 73 ff ff ff       	jmp    80100292 <consoleread+0x2a>
      if(n < target){
8010031f:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
80100322:	73 05                	jae    80100329 <consoleread+0xc1>
        input.r--;
80100324:	a3 c0 ef 10 80       	mov    %eax,0x8010efc0
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 95 10 80       	push   $0x80109520
80100331:	e8 8c 39 00 00       	call   80103cc2 <release>
  ilock(ip);
80100336:	89 3c 24             	mov    %edi,(%esp)
80100339:	e8 43 12 00 00       	call   80101581 <ilock>
  return target - n;
8010033e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100341:	29 d8                	sub    %ebx,%eax
80100343:	83 c4 10             	add    $0x10,%esp
80100346:	eb 9e                	jmp    801002e6 <consoleread+0x7e>

80100348 <panic>:
{
80100348:	55                   	push   %ebp
80100349:	89 e5                	mov    %esp,%ebp
8010034b:	53                   	push   %ebx
8010034c:	83 ec 34             	sub    $0x34,%esp
}

static inline void
cli(void)
{
  asm volatile("cli");
8010034f:	fa                   	cli    
  cons.locking = 0;
80100350:	c7 05 54 95 10 80 00 	movl   $0x0,0x80109554
80100357:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
8010035a:	e8 e7 20 00 00       	call   80102446 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 ad 65 10 80       	push   $0x801065ad
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 fb 6e 10 80 	movl   $0x80106efb,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 a8 37 00 00       	call   80103b3c <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 c1 65 10 80       	push   $0x801065c1
801003aa:	e8 5c 02 00 00       	call   8010060b <cprintf>
  for(i=0; i<10; i++)
801003af:	83 c3 01             	add    $0x1,%ebx
801003b2:	83 c4 10             	add    $0x10,%esp
801003b5:	83 fb 09             	cmp    $0x9,%ebx
801003b8:	7e e4                	jle    8010039e <panic+0x56>
  panicked = 1; // freeze other CPU
801003ba:	c7 05 58 95 10 80 01 	movl   $0x1,0x80109558
801003c1:	00 00 00 
801003c4:	eb fe                	jmp    801003c4 <panic+0x7c>

801003c6 <cgaputc>:
{
801003c6:	55                   	push   %ebp
801003c7:	89 e5                	mov    %esp,%ebp
801003c9:	57                   	push   %edi
801003ca:	56                   	push   %esi
801003cb:	53                   	push   %ebx
801003cc:	83 ec 0c             	sub    $0xc,%esp
801003cf:	89 c6                	mov    %eax,%esi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003d1:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
801003d6:	b8 0e 00 00 00       	mov    $0xe,%eax
801003db:	89 ca                	mov    %ecx,%edx
801003dd:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003de:	bb d5 03 00 00       	mov    $0x3d5,%ebx
801003e3:	89 da                	mov    %ebx,%edx
801003e5:	ec                   	in     (%dx),%al
  pos = inb(CRTPORT+1) << 8;
801003e6:	0f b6 f8             	movzbl %al,%edi
801003e9:	c1 e7 08             	shl    $0x8,%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003ec:	b8 0f 00 00 00       	mov    $0xf,%eax
801003f1:	89 ca                	mov    %ecx,%edx
801003f3:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003f4:	89 da                	mov    %ebx,%edx
801003f6:	ec                   	in     (%dx),%al
  pos |= inb(CRTPORT+1);
801003f7:	0f b6 c8             	movzbl %al,%ecx
801003fa:	09 f9                	or     %edi,%ecx
  if(c == '\n')
801003fc:	83 fe 0a             	cmp    $0xa,%esi
801003ff:	74 6a                	je     8010046b <cgaputc+0xa5>
  else if(c == BACKSPACE){
80100401:	81 fe 00 01 00 00    	cmp    $0x100,%esi
80100407:	0f 84 81 00 00 00    	je     8010048e <cgaputc+0xc8>
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010040d:	89 f0                	mov    %esi,%eax
8010040f:	0f b6 f0             	movzbl %al,%esi
80100412:	8d 59 01             	lea    0x1(%ecx),%ebx
80100415:	66 81 ce 00 07       	or     $0x700,%si
8010041a:	66 89 b4 09 00 80 0b 	mov    %si,-0x7ff48000(%ecx,%ecx,1)
80100421:	80 
  if(pos < 0 || pos > 25*80)
80100422:	81 fb d0 07 00 00    	cmp    $0x7d0,%ebx
80100428:	77 71                	ja     8010049b <cgaputc+0xd5>
  if((pos/80) >= 24){  // Scroll up.
8010042a:	81 fb 7f 07 00 00    	cmp    $0x77f,%ebx
80100430:	7f 76                	jg     801004a8 <cgaputc+0xe2>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100432:	be d4 03 00 00       	mov    $0x3d4,%esi
80100437:	b8 0e 00 00 00       	mov    $0xe,%eax
8010043c:	89 f2                	mov    %esi,%edx
8010043e:	ee                   	out    %al,(%dx)
  outb(CRTPORT+1, pos>>8);
8010043f:	89 d8                	mov    %ebx,%eax
80100441:	c1 f8 08             	sar    $0x8,%eax
80100444:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
80100449:	89 ca                	mov    %ecx,%edx
8010044b:	ee                   	out    %al,(%dx)
8010044c:	b8 0f 00 00 00       	mov    $0xf,%eax
80100451:	89 f2                	mov    %esi,%edx
80100453:	ee                   	out    %al,(%dx)
80100454:	89 d8                	mov    %ebx,%eax
80100456:	89 ca                	mov    %ecx,%edx
80100458:	ee                   	out    %al,(%dx)
  crt[pos] = ' ' | 0x0700;
80100459:	66 c7 84 1b 00 80 0b 	movw   $0x720,-0x7ff48000(%ebx,%ebx,1)
80100460:	80 20 07 
}
80100463:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100466:	5b                   	pop    %ebx
80100467:	5e                   	pop    %esi
80100468:	5f                   	pop    %edi
80100469:	5d                   	pop    %ebp
8010046a:	c3                   	ret    
    pos += 80 - pos%80;
8010046b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100470:	89 c8                	mov    %ecx,%eax
80100472:	f7 ea                	imul   %edx
80100474:	c1 fa 05             	sar    $0x5,%edx
80100477:	8d 14 92             	lea    (%edx,%edx,4),%edx
8010047a:	89 d0                	mov    %edx,%eax
8010047c:	c1 e0 04             	shl    $0x4,%eax
8010047f:	89 ca                	mov    %ecx,%edx
80100481:	29 c2                	sub    %eax,%edx
80100483:	bb 50 00 00 00       	mov    $0x50,%ebx
80100488:	29 d3                	sub    %edx,%ebx
8010048a:	01 cb                	add    %ecx,%ebx
8010048c:	eb 94                	jmp    80100422 <cgaputc+0x5c>
    if(pos > 0) --pos;
8010048e:	85 c9                	test   %ecx,%ecx
80100490:	7e 05                	jle    80100497 <cgaputc+0xd1>
80100492:	8d 59 ff             	lea    -0x1(%ecx),%ebx
80100495:	eb 8b                	jmp    80100422 <cgaputc+0x5c>
  pos |= inb(CRTPORT+1);
80100497:	89 cb                	mov    %ecx,%ebx
80100499:	eb 87                	jmp    80100422 <cgaputc+0x5c>
    panic("pos under/overflow");
8010049b:	83 ec 0c             	sub    $0xc,%esp
8010049e:	68 c5 65 10 80       	push   $0x801065c5
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 c5 38 00 00       	call   80103d84 <memmove>
    pos -= 80;
801004bf:	83 eb 50             	sub    $0x50,%ebx
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801004c2:	b8 80 07 00 00       	mov    $0x780,%eax
801004c7:	29 d8                	sub    %ebx,%eax
801004c9:	8d 94 1b 00 80 0b 80 	lea    -0x7ff48000(%ebx,%ebx,1),%edx
801004d0:	83 c4 0c             	add    $0xc,%esp
801004d3:	01 c0                	add    %eax,%eax
801004d5:	50                   	push   %eax
801004d6:	6a 00                	push   $0x0
801004d8:	52                   	push   %edx
801004d9:	e8 2b 38 00 00       	call   80103d09 <memset>
801004de:	83 c4 10             	add    $0x10,%esp
801004e1:	e9 4c ff ff ff       	jmp    80100432 <cgaputc+0x6c>

801004e6 <consputc>:
  if(panicked){
801004e6:	83 3d 58 95 10 80 00 	cmpl   $0x0,0x80109558
801004ed:	74 03                	je     801004f2 <consputc+0xc>
  asm volatile("cli");
801004ef:	fa                   	cli    
801004f0:	eb fe                	jmp    801004f0 <consputc+0xa>
{
801004f2:	55                   	push   %ebp
801004f3:	89 e5                	mov    %esp,%ebp
801004f5:	53                   	push   %ebx
801004f6:	83 ec 04             	sub    $0x4,%esp
801004f9:	89 c3                	mov    %eax,%ebx
  if(c == BACKSPACE){
801004fb:	3d 00 01 00 00       	cmp    $0x100,%eax
80100500:	74 18                	je     8010051a <consputc+0x34>
    uartputc(c);
80100502:	83 ec 0c             	sub    $0xc,%esp
80100505:	50                   	push   %eax
80100506:	e8 50 4c 00 00       	call   8010515b <uartputc>
8010050b:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
8010050e:	89 d8                	mov    %ebx,%eax
80100510:	e8 b1 fe ff ff       	call   801003c6 <cgaputc>
}
80100515:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100518:	c9                   	leave  
80100519:	c3                   	ret    
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010051a:	83 ec 0c             	sub    $0xc,%esp
8010051d:	6a 08                	push   $0x8
8010051f:	e8 37 4c 00 00       	call   8010515b <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 2b 4c 00 00       	call   8010515b <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 1f 4c 00 00       	call   8010515b <uartputc>
8010053c:	83 c4 10             	add    $0x10,%esp
8010053f:	eb cd                	jmp    8010050e <consputc+0x28>

80100541 <printint>:
{
80100541:	55                   	push   %ebp
80100542:	89 e5                	mov    %esp,%ebp
80100544:	57                   	push   %edi
80100545:	56                   	push   %esi
80100546:	53                   	push   %ebx
80100547:	83 ec 1c             	sub    $0x1c,%esp
8010054a:	89 d7                	mov    %edx,%edi
  if(sign && (sign = xx < 0))
8010054c:	85 c9                	test   %ecx,%ecx
8010054e:	74 09                	je     80100559 <printint+0x18>
80100550:	89 c1                	mov    %eax,%ecx
80100552:	c1 e9 1f             	shr    $0x1f,%ecx
80100555:	85 c0                	test   %eax,%eax
80100557:	78 09                	js     80100562 <printint+0x21>
    x = xx;
80100559:	89 c2                	mov    %eax,%edx
  i = 0;
8010055b:	be 00 00 00 00       	mov    $0x0,%esi
80100560:	eb 08                	jmp    8010056a <printint+0x29>
    x = -xx;
80100562:	f7 d8                	neg    %eax
80100564:	89 c2                	mov    %eax,%edx
80100566:	eb f3                	jmp    8010055b <printint+0x1a>
    buf[i++] = digits[x % base];
80100568:	89 de                	mov    %ebx,%esi
8010056a:	89 d0                	mov    %edx,%eax
8010056c:	ba 00 00 00 00       	mov    $0x0,%edx
80100571:	f7 f7                	div    %edi
80100573:	8d 5e 01             	lea    0x1(%esi),%ebx
80100576:	0f b6 92 f0 65 10 80 	movzbl -0x7fef9a10(%edx),%edx
8010057d:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
80100581:	89 c2                	mov    %eax,%edx
80100583:	85 c0                	test   %eax,%eax
80100585:	75 e1                	jne    80100568 <printint+0x27>
  if(sign)
80100587:	85 c9                	test   %ecx,%ecx
80100589:	74 14                	je     8010059f <printint+0x5e>
    buf[i++] = '-';
8010058b:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
80100590:	8d 5e 02             	lea    0x2(%esi),%ebx
80100593:	eb 0a                	jmp    8010059f <printint+0x5e>
    consputc(buf[i]);
80100595:	0f be 44 1d d8       	movsbl -0x28(%ebp,%ebx,1),%eax
8010059a:	e8 47 ff ff ff       	call   801004e6 <consputc>
  while(--i >= 0)
8010059f:	83 eb 01             	sub    $0x1,%ebx
801005a2:	79 f1                	jns    80100595 <printint+0x54>
}
801005a4:	83 c4 1c             	add    $0x1c,%esp
801005a7:	5b                   	pop    %ebx
801005a8:	5e                   	pop    %esi
801005a9:	5f                   	pop    %edi
801005aa:	5d                   	pop    %ebp
801005ab:	c3                   	ret    

801005ac <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
801005ac:	55                   	push   %ebp
801005ad:	89 e5                	mov    %esp,%ebp
801005af:	57                   	push   %edi
801005b0:	56                   	push   %esi
801005b1:	53                   	push   %ebx
801005b2:	83 ec 18             	sub    $0x18,%esp
801005b5:	8b 7d 0c             	mov    0xc(%ebp),%edi
801005b8:	8b 75 10             	mov    0x10(%ebp),%esi
  int i;

  iunlock(ip);
801005bb:	ff 75 08             	pushl  0x8(%ebp)
801005be:	e8 80 10 00 00       	call   80101643 <iunlock>
  acquire(&cons.lock);
801005c3:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
801005ca:	e8 8e 36 00 00       	call   80103c5d <acquire>
  for(i = 0; i < n; i++)
801005cf:	83 c4 10             	add    $0x10,%esp
801005d2:	bb 00 00 00 00       	mov    $0x0,%ebx
801005d7:	eb 0c                	jmp    801005e5 <consolewrite+0x39>
    consputc(buf[i] & 0xff);
801005d9:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
801005dd:	e8 04 ff ff ff       	call   801004e6 <consputc>
  for(i = 0; i < n; i++)
801005e2:	83 c3 01             	add    $0x1,%ebx
801005e5:	39 f3                	cmp    %esi,%ebx
801005e7:	7c f0                	jl     801005d9 <consolewrite+0x2d>
  release(&cons.lock);
801005e9:	83 ec 0c             	sub    $0xc,%esp
801005ec:	68 20 95 10 80       	push   $0x80109520
801005f1:	e8 cc 36 00 00       	call   80103cc2 <release>
  ilock(ip);
801005f6:	83 c4 04             	add    $0x4,%esp
801005f9:	ff 75 08             	pushl  0x8(%ebp)
801005fc:	e8 80 0f 00 00       	call   80101581 <ilock>

  return n;
}
80100601:	89 f0                	mov    %esi,%eax
80100603:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100606:	5b                   	pop    %ebx
80100607:	5e                   	pop    %esi
80100608:	5f                   	pop    %edi
80100609:	5d                   	pop    %ebp
8010060a:	c3                   	ret    

8010060b <cprintf>:
{
8010060b:	55                   	push   %ebp
8010060c:	89 e5                	mov    %esp,%ebp
8010060e:	57                   	push   %edi
8010060f:	56                   	push   %esi
80100610:	53                   	push   %ebx
80100611:	83 ec 1c             	sub    $0x1c,%esp
  locking = cons.locking;
80100614:	a1 54 95 10 80       	mov    0x80109554,%eax
80100619:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  if(locking)
8010061c:	85 c0                	test   %eax,%eax
8010061e:	75 10                	jne    80100630 <cprintf+0x25>
  if (fmt == 0)
80100620:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80100624:	74 1c                	je     80100642 <cprintf+0x37>
  argp = (uint*)(void*)(&fmt + 1);
80100626:	8d 7d 0c             	lea    0xc(%ebp),%edi
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100629:	bb 00 00 00 00       	mov    $0x0,%ebx
8010062e:	eb 27                	jmp    80100657 <cprintf+0x4c>
    acquire(&cons.lock);
80100630:	83 ec 0c             	sub    $0xc,%esp
80100633:	68 20 95 10 80       	push   $0x80109520
80100638:	e8 20 36 00 00       	call   80103c5d <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 df 65 10 80       	push   $0x801065df
8010064a:	e8 f9 fc ff ff       	call   80100348 <panic>
      consputc(c);
8010064f:	e8 92 fe ff ff       	call   801004e6 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100654:	83 c3 01             	add    $0x1,%ebx
80100657:	8b 55 08             	mov    0x8(%ebp),%edx
8010065a:	0f b6 04 1a          	movzbl (%edx,%ebx,1),%eax
8010065e:	85 c0                	test   %eax,%eax
80100660:	0f 84 b8 00 00 00    	je     8010071e <cprintf+0x113>
    if(c != '%'){
80100666:	83 f8 25             	cmp    $0x25,%eax
80100669:	75 e4                	jne    8010064f <cprintf+0x44>
    c = fmt[++i] & 0xff;
8010066b:	83 c3 01             	add    $0x1,%ebx
8010066e:	0f b6 34 1a          	movzbl (%edx,%ebx,1),%esi
    if(c == 0)
80100672:	85 f6                	test   %esi,%esi
80100674:	0f 84 a4 00 00 00    	je     8010071e <cprintf+0x113>
    switch(c){
8010067a:	83 fe 70             	cmp    $0x70,%esi
8010067d:	74 48                	je     801006c7 <cprintf+0xbc>
8010067f:	83 fe 70             	cmp    $0x70,%esi
80100682:	7f 26                	jg     801006aa <cprintf+0x9f>
80100684:	83 fe 25             	cmp    $0x25,%esi
80100687:	0f 84 82 00 00 00    	je     8010070f <cprintf+0x104>
8010068d:	83 fe 64             	cmp    $0x64,%esi
80100690:	75 22                	jne    801006b4 <cprintf+0xa9>
      printint(*argp++, 10, 1);
80100692:	8d 77 04             	lea    0x4(%edi),%esi
80100695:	8b 07                	mov    (%edi),%eax
80100697:	b9 01 00 00 00       	mov    $0x1,%ecx
8010069c:	ba 0a 00 00 00       	mov    $0xa,%edx
801006a1:	e8 9b fe ff ff       	call   80100541 <printint>
801006a6:	89 f7                	mov    %esi,%edi
      break;
801006a8:	eb aa                	jmp    80100654 <cprintf+0x49>
    switch(c){
801006aa:	83 fe 73             	cmp    $0x73,%esi
801006ad:	74 33                	je     801006e2 <cprintf+0xd7>
801006af:	83 fe 78             	cmp    $0x78,%esi
801006b2:	74 13                	je     801006c7 <cprintf+0xbc>
      consputc('%');
801006b4:	b8 25 00 00 00       	mov    $0x25,%eax
801006b9:	e8 28 fe ff ff       	call   801004e6 <consputc>
      consputc(c);
801006be:	89 f0                	mov    %esi,%eax
801006c0:	e8 21 fe ff ff       	call   801004e6 <consputc>
      break;
801006c5:	eb 8d                	jmp    80100654 <cprintf+0x49>
      printint(*argp++, 16, 0);
801006c7:	8d 77 04             	lea    0x4(%edi),%esi
801006ca:	8b 07                	mov    (%edi),%eax
801006cc:	b9 00 00 00 00       	mov    $0x0,%ecx
801006d1:	ba 10 00 00 00       	mov    $0x10,%edx
801006d6:	e8 66 fe ff ff       	call   80100541 <printint>
801006db:	89 f7                	mov    %esi,%edi
      break;
801006dd:	e9 72 ff ff ff       	jmp    80100654 <cprintf+0x49>
      if((s = (char*)*argp++) == 0)
801006e2:	8d 47 04             	lea    0x4(%edi),%eax
801006e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
801006e8:	8b 37                	mov    (%edi),%esi
801006ea:	85 f6                	test   %esi,%esi
801006ec:	75 12                	jne    80100700 <cprintf+0xf5>
        s = "(null)";
801006ee:	be d8 65 10 80       	mov    $0x801065d8,%esi
801006f3:	eb 0b                	jmp    80100700 <cprintf+0xf5>
        consputc(*s);
801006f5:	0f be c0             	movsbl %al,%eax
801006f8:	e8 e9 fd ff ff       	call   801004e6 <consputc>
      for(; *s; s++)
801006fd:	83 c6 01             	add    $0x1,%esi
80100700:	0f b6 06             	movzbl (%esi),%eax
80100703:	84 c0                	test   %al,%al
80100705:	75 ee                	jne    801006f5 <cprintf+0xea>
      if((s = (char*)*argp++) == 0)
80100707:	8b 7d e0             	mov    -0x20(%ebp),%edi
8010070a:	e9 45 ff ff ff       	jmp    80100654 <cprintf+0x49>
      consputc('%');
8010070f:	b8 25 00 00 00       	mov    $0x25,%eax
80100714:	e8 cd fd ff ff       	call   801004e6 <consputc>
      break;
80100719:	e9 36 ff ff ff       	jmp    80100654 <cprintf+0x49>
  if(locking)
8010071e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100722:	75 08                	jne    8010072c <cprintf+0x121>
}
80100724:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100727:	5b                   	pop    %ebx
80100728:	5e                   	pop    %esi
80100729:	5f                   	pop    %edi
8010072a:	5d                   	pop    %ebp
8010072b:	c3                   	ret    
    release(&cons.lock);
8010072c:	83 ec 0c             	sub    $0xc,%esp
8010072f:	68 20 95 10 80       	push   $0x80109520
80100734:	e8 89 35 00 00       	call   80103cc2 <release>
80100739:	83 c4 10             	add    $0x10,%esp
}
8010073c:	eb e6                	jmp    80100724 <cprintf+0x119>

8010073e <consoleintr>:
{
8010073e:	55                   	push   %ebp
8010073f:	89 e5                	mov    %esp,%ebp
80100741:	57                   	push   %edi
80100742:	56                   	push   %esi
80100743:	53                   	push   %ebx
80100744:	83 ec 18             	sub    $0x18,%esp
80100747:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&cons.lock);
8010074a:	68 20 95 10 80       	push   $0x80109520
8010074f:	e8 09 35 00 00       	call   80103c5d <acquire>
  while((c = getc()) >= 0){
80100754:	83 c4 10             	add    $0x10,%esp
  int c, doprocdump = 0;
80100757:	be 00 00 00 00       	mov    $0x0,%esi
  while((c = getc()) >= 0){
8010075c:	e9 c5 00 00 00       	jmp    80100826 <consoleintr+0xe8>
    switch(c){
80100761:	83 ff 08             	cmp    $0x8,%edi
80100764:	0f 84 e0 00 00 00    	je     8010084a <consoleintr+0x10c>
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010076a:	85 ff                	test   %edi,%edi
8010076c:	0f 84 b4 00 00 00    	je     80100826 <consoleintr+0xe8>
80100772:	a1 c8 ef 10 80       	mov    0x8010efc8,%eax
80100777:	89 c2                	mov    %eax,%edx
80100779:	2b 15 c0 ef 10 80    	sub    0x8010efc0,%edx
8010077f:	83 fa 7f             	cmp    $0x7f,%edx
80100782:	0f 87 9e 00 00 00    	ja     80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100788:	83 ff 0d             	cmp    $0xd,%edi
8010078b:	0f 84 86 00 00 00    	je     80100817 <consoleintr+0xd9>
        input.buf[input.e++ % INPUT_BUF] = c;
80100791:	8d 50 01             	lea    0x1(%eax),%edx
80100794:	89 15 c8 ef 10 80    	mov    %edx,0x8010efc8
8010079a:	83 e0 7f             	and    $0x7f,%eax
8010079d:	89 f9                	mov    %edi,%ecx
8010079f:	88 88 40 ef 10 80    	mov    %cl,-0x7fef10c0(%eax)
        consputc(c);
801007a5:	89 f8                	mov    %edi,%eax
801007a7:	e8 3a fd ff ff       	call   801004e6 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801007ac:	83 ff 0a             	cmp    $0xa,%edi
801007af:	0f 94 c2             	sete   %dl
801007b2:	83 ff 04             	cmp    $0x4,%edi
801007b5:	0f 94 c0             	sete   %al
801007b8:	08 c2                	or     %al,%dl
801007ba:	75 10                	jne    801007cc <consoleintr+0x8e>
801007bc:	a1 c0 ef 10 80       	mov    0x8010efc0,%eax
801007c1:	83 e8 80             	sub    $0xffffff80,%eax
801007c4:	39 05 c8 ef 10 80    	cmp    %eax,0x8010efc8
801007ca:	75 5a                	jne    80100826 <consoleintr+0xe8>
          input.w = input.e;
801007cc:	a1 c8 ef 10 80       	mov    0x8010efc8,%eax
801007d1:	a3 c4 ef 10 80       	mov    %eax,0x8010efc4
          wakeup(&input.r);
801007d6:	83 ec 0c             	sub    $0xc,%esp
801007d9:	68 c0 ef 10 80       	push   $0x8010efc0
801007de:	e8 e4 30 00 00       	call   801038c7 <wakeup>
801007e3:	83 c4 10             	add    $0x10,%esp
801007e6:	eb 3e                	jmp    80100826 <consoleintr+0xe8>
        input.e--;
801007e8:	a3 c8 ef 10 80       	mov    %eax,0x8010efc8
        consputc(BACKSPACE);
801007ed:	b8 00 01 00 00       	mov    $0x100,%eax
801007f2:	e8 ef fc ff ff       	call   801004e6 <consputc>
      while(input.e != input.w &&
801007f7:	a1 c8 ef 10 80       	mov    0x8010efc8,%eax
801007fc:	3b 05 c4 ef 10 80    	cmp    0x8010efc4,%eax
80100802:	74 22                	je     80100826 <consoleintr+0xe8>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100804:	83 e8 01             	sub    $0x1,%eax
80100807:	89 c2                	mov    %eax,%edx
80100809:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010080c:	80 ba 40 ef 10 80 0a 	cmpb   $0xa,-0x7fef10c0(%edx)
80100813:	75 d3                	jne    801007e8 <consoleintr+0xaa>
80100815:	eb 0f                	jmp    80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100817:	bf 0a 00 00 00       	mov    $0xa,%edi
8010081c:	e9 70 ff ff ff       	jmp    80100791 <consoleintr+0x53>
      doprocdump = 1;
80100821:	be 01 00 00 00       	mov    $0x1,%esi
  while((c = getc()) >= 0){
80100826:	ff d3                	call   *%ebx
80100828:	89 c7                	mov    %eax,%edi
8010082a:	85 c0                	test   %eax,%eax
8010082c:	78 3d                	js     8010086b <consoleintr+0x12d>
    switch(c){
8010082e:	83 ff 10             	cmp    $0x10,%edi
80100831:	74 ee                	je     80100821 <consoleintr+0xe3>
80100833:	83 ff 10             	cmp    $0x10,%edi
80100836:	0f 8e 25 ff ff ff    	jle    80100761 <consoleintr+0x23>
8010083c:	83 ff 15             	cmp    $0x15,%edi
8010083f:	74 b6                	je     801007f7 <consoleintr+0xb9>
80100841:	83 ff 7f             	cmp    $0x7f,%edi
80100844:	0f 85 20 ff ff ff    	jne    8010076a <consoleintr+0x2c>
      if(input.e != input.w){
8010084a:	a1 c8 ef 10 80       	mov    0x8010efc8,%eax
8010084f:	3b 05 c4 ef 10 80    	cmp    0x8010efc4,%eax
80100855:	74 cf                	je     80100826 <consoleintr+0xe8>
        input.e--;
80100857:	83 e8 01             	sub    $0x1,%eax
8010085a:	a3 c8 ef 10 80       	mov    %eax,0x8010efc8
        consputc(BACKSPACE);
8010085f:	b8 00 01 00 00       	mov    $0x100,%eax
80100864:	e8 7d fc ff ff       	call   801004e6 <consputc>
80100869:	eb bb                	jmp    80100826 <consoleintr+0xe8>
  release(&cons.lock);
8010086b:	83 ec 0c             	sub    $0xc,%esp
8010086e:	68 20 95 10 80       	push   $0x80109520
80100873:	e8 4a 34 00 00       	call   80103cc2 <release>
  if(doprocdump) {
80100878:	83 c4 10             	add    $0x10,%esp
8010087b:	85 f6                	test   %esi,%esi
8010087d:	75 08                	jne    80100887 <consoleintr+0x149>
}
8010087f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100882:	5b                   	pop    %ebx
80100883:	5e                   	pop    %esi
80100884:	5f                   	pop    %edi
80100885:	5d                   	pop    %ebp
80100886:	c3                   	ret    
    procdump();  // now call procdump() wo. cons.lock held
80100887:	e8 d8 30 00 00       	call   80103964 <procdump>
}
8010088c:	eb f1                	jmp    8010087f <consoleintr+0x141>

8010088e <consoleinit>:

void
consoleinit(void)
{
8010088e:	55                   	push   %ebp
8010088f:	89 e5                	mov    %esp,%ebp
80100891:	83 ec 10             	sub    $0x10,%esp
  initlock(&cons.lock, "console");
80100894:	68 e8 65 10 80       	push   $0x801065e8
80100899:	68 20 95 10 80       	push   $0x80109520
8010089e:	e8 7e 32 00 00       	call   80103b21 <initlock>

  devsw[CONSOLE].write = consolewrite;
801008a3:	c7 05 8c f9 10 80 ac 	movl   $0x801005ac,0x8010f98c
801008aa:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008ad:	c7 05 88 f9 10 80 68 	movl   $0x80100268,0x8010f988
801008b4:	02 10 80 
  cons.locking = 1;
801008b7:	c7 05 54 95 10 80 01 	movl   $0x1,0x80109554
801008be:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
801008c1:	83 c4 08             	add    $0x8,%esp
801008c4:	6a 00                	push   $0x0
801008c6:	6a 01                	push   $0x1
801008c8:	e8 b1 16 00 00       	call   80101f7e <ioapicenable>
}
801008cd:	83 c4 10             	add    $0x10,%esp
801008d0:	c9                   	leave  
801008d1:	c3                   	ret    

801008d2 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
801008d2:	55                   	push   %ebp
801008d3:	89 e5                	mov    %esp,%ebp
801008d5:	57                   	push   %edi
801008d6:	56                   	push   %esi
801008d7:	53                   	push   %ebx
801008d8:	81 ec 0c 01 00 00    	sub    $0x10c,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
801008de:	e8 db 29 00 00       	call   801032be <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 88 1f 00 00       	call   80102876 <begin_op>

  if((ip = namei(path)) == 0){
801008ee:	83 ec 0c             	sub    $0xc,%esp
801008f1:	ff 75 08             	pushl  0x8(%ebp)
801008f4:	e8 e8 12 00 00       	call   80101be1 <namei>
801008f9:	83 c4 10             	add    $0x10,%esp
801008fc:	85 c0                	test   %eax,%eax
801008fe:	74 4a                	je     8010094a <exec+0x78>
80100900:	89 c3                	mov    %eax,%ebx
    end_op();
    cprintf("exec: fail\n");
    return -1;
  }
  ilock(ip);
80100902:	83 ec 0c             	sub    $0xc,%esp
80100905:	50                   	push   %eax
80100906:	e8 76 0c 00 00       	call   80101581 <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
8010090b:	6a 34                	push   $0x34
8010090d:	6a 00                	push   $0x0
8010090f:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100915:	50                   	push   %eax
80100916:	53                   	push   %ebx
80100917:	e8 57 0e 00 00       	call   80101773 <readi>
8010091c:	83 c4 20             	add    $0x20,%esp
8010091f:	83 f8 34             	cmp    $0x34,%eax
80100922:	74 42                	je     80100966 <exec+0x94>
  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
80100924:	85 db                	test   %ebx,%ebx
80100926:	0f 84 dd 02 00 00    	je     80100c09 <exec+0x337>
    iunlockput(ip);
8010092c:	83 ec 0c             	sub    $0xc,%esp
8010092f:	53                   	push   %ebx
80100930:	e8 f3 0d 00 00       	call   80101728 <iunlockput>
    end_op();
80100935:	e8 b6 1f 00 00       	call   801028f0 <end_op>
8010093a:	83 c4 10             	add    $0x10,%esp
  }
  return -1;
8010093d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100942:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100945:	5b                   	pop    %ebx
80100946:	5e                   	pop    %esi
80100947:	5f                   	pop    %edi
80100948:	5d                   	pop    %ebp
80100949:	c3                   	ret    
    end_op();
8010094a:	e8 a1 1f 00 00       	call   801028f0 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 01 66 10 80       	push   $0x80106601
80100957:	e8 af fc ff ff       	call   8010060b <cprintf>
    return -1;
8010095c:	83 c4 10             	add    $0x10,%esp
8010095f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100964:	eb dc                	jmp    80100942 <exec+0x70>
  if(elf.magic != ELF_MAGIC)
80100966:	81 bd 24 ff ff ff 7f 	cmpl   $0x464c457f,-0xdc(%ebp)
8010096d:	45 4c 46 
80100970:	75 b2                	jne    80100924 <exec+0x52>
  if((pgdir = setupkvm()) == 0)
80100972:	e8 a4 59 00 00       	call   8010631b <setupkvm>
80100977:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)
8010097d:	85 c0                	test   %eax,%eax
8010097f:	0f 84 06 01 00 00    	je     80100a8b <exec+0x1b9>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100985:	8b 85 40 ff ff ff    	mov    -0xc0(%ebp),%eax
  sz = 0;
8010098b:	bf 00 00 00 00       	mov    $0x0,%edi
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100990:	be 00 00 00 00       	mov    $0x0,%esi
80100995:	eb 0c                	jmp    801009a3 <exec+0xd1>
80100997:	83 c6 01             	add    $0x1,%esi
8010099a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
801009a0:	83 c0 20             	add    $0x20,%eax
801009a3:	0f b7 95 50 ff ff ff 	movzwl -0xb0(%ebp),%edx
801009aa:	39 f2                	cmp    %esi,%edx
801009ac:	0f 8e 98 00 00 00    	jle    80100a4a <exec+0x178>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
801009b2:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
801009b8:	6a 20                	push   $0x20
801009ba:	50                   	push   %eax
801009bb:	8d 85 04 ff ff ff    	lea    -0xfc(%ebp),%eax
801009c1:	50                   	push   %eax
801009c2:	53                   	push   %ebx
801009c3:	e8 ab 0d 00 00       	call   80101773 <readi>
801009c8:	83 c4 10             	add    $0x10,%esp
801009cb:	83 f8 20             	cmp    $0x20,%eax
801009ce:	0f 85 b7 00 00 00    	jne    80100a8b <exec+0x1b9>
    if(ph.type != ELF_PROG_LOAD)
801009d4:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
801009db:	75 ba                	jne    80100997 <exec+0xc5>
    if(ph.memsz < ph.filesz)
801009dd:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
801009e3:	3b 85 14 ff ff ff    	cmp    -0xec(%ebp),%eax
801009e9:	0f 82 9c 00 00 00    	jb     80100a8b <exec+0x1b9>
    if(ph.vaddr + ph.memsz < ph.vaddr)
801009ef:	03 85 0c ff ff ff    	add    -0xf4(%ebp),%eax
801009f5:	0f 82 90 00 00 00    	jb     80100a8b <exec+0x1b9>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
801009fb:	83 ec 04             	sub    $0x4,%esp
801009fe:	50                   	push   %eax
801009ff:	57                   	push   %edi
80100a00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a06:	e8 b6 57 00 00       	call   801061c1 <allocuvm>
80100a0b:	89 c7                	mov    %eax,%edi
80100a0d:	83 c4 10             	add    $0x10,%esp
80100a10:	85 c0                	test   %eax,%eax
80100a12:	74 77                	je     80100a8b <exec+0x1b9>
    if(ph.vaddr % PGSIZE != 0)
80100a14:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100a1a:	a9 ff 0f 00 00       	test   $0xfff,%eax
80100a1f:	75 6a                	jne    80100a8b <exec+0x1b9>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100a21:	83 ec 0c             	sub    $0xc,%esp
80100a24:	ff b5 14 ff ff ff    	pushl  -0xec(%ebp)
80100a2a:	ff b5 08 ff ff ff    	pushl  -0xf8(%ebp)
80100a30:	53                   	push   %ebx
80100a31:	50                   	push   %eax
80100a32:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a38:	e8 52 56 00 00       	call   8010608f <loaduvm>
80100a3d:	83 c4 20             	add    $0x20,%esp
80100a40:	85 c0                	test   %eax,%eax
80100a42:	0f 89 4f ff ff ff    	jns    80100997 <exec+0xc5>
 bad:
80100a48:	eb 41                	jmp    80100a8b <exec+0x1b9>
  iunlockput(ip);
80100a4a:	83 ec 0c             	sub    $0xc,%esp
80100a4d:	53                   	push   %ebx
80100a4e:	e8 d5 0c 00 00       	call   80101728 <iunlockput>
  end_op();
80100a53:	e8 98 1e 00 00       	call   801028f0 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 48 57 00 00       	call   801061c1 <allocuvm>
80100a79:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
80100a7f:	83 c4 10             	add    $0x10,%esp
80100a82:	85 c0                	test   %eax,%eax
80100a84:	75 24                	jne    80100aaa <exec+0x1d8>
  ip = 0;
80100a86:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(pgdir)
80100a8b:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100a91:	85 c0                	test   %eax,%eax
80100a93:	0f 84 8b fe ff ff    	je     80100924 <exec+0x52>
    freevm(pgdir);
80100a99:	83 ec 0c             	sub    $0xc,%esp
80100a9c:	50                   	push   %eax
80100a9d:	e8 09 58 00 00       	call   801062ab <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 df 58 00 00       	call   801063a0 <clearpteu>
  for(argc = 0; argv[argc]; argc++) {
80100ac1:	83 c4 10             	add    $0x10,%esp
80100ac4:	bb 00 00 00 00       	mov    $0x0,%ebx
80100ac9:	8b 45 0c             	mov    0xc(%ebp),%eax
80100acc:	8d 34 98             	lea    (%eax,%ebx,4),%esi
80100acf:	8b 06                	mov    (%esi),%eax
80100ad1:	85 c0                	test   %eax,%eax
80100ad3:	74 4d                	je     80100b22 <exec+0x250>
    if(argc >= MAXARG)
80100ad5:	83 fb 1f             	cmp    $0x1f,%ebx
80100ad8:	0f 87 0d 01 00 00    	ja     80100beb <exec+0x319>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100ade:	83 ec 0c             	sub    $0xc,%esp
80100ae1:	50                   	push   %eax
80100ae2:	e8 c4 33 00 00       	call   80103eab <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 b2 33 00 00       	call   80103eab <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 e3 59 00 00       	call   801064ee <copyout>
80100b0b:	83 c4 20             	add    $0x20,%esp
80100b0e:	85 c0                	test   %eax,%eax
80100b10:	0f 88 df 00 00 00    	js     80100bf5 <exec+0x323>
    ustack[3+argc] = sp;
80100b16:	89 bc 9d 64 ff ff ff 	mov    %edi,-0x9c(%ebp,%ebx,4)
  for(argc = 0; argv[argc]; argc++) {
80100b1d:	83 c3 01             	add    $0x1,%ebx
80100b20:	eb a7                	jmp    80100ac9 <exec+0x1f7>
  ustack[3+argc] = 0;
80100b22:	c7 84 9d 64 ff ff ff 	movl   $0x0,-0x9c(%ebp,%ebx,4)
80100b29:	00 00 00 00 
  ustack[0] = 0xffffffff;  // fake return PC
80100b2d:	c7 85 58 ff ff ff ff 	movl   $0xffffffff,-0xa8(%ebp)
80100b34:	ff ff ff 
  ustack[1] = argc;
80100b37:	89 9d 5c ff ff ff    	mov    %ebx,-0xa4(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100b3d:	8d 04 9d 04 00 00 00 	lea    0x4(,%ebx,4),%eax
80100b44:	89 f9                	mov    %edi,%ecx
80100b46:	29 c1                	sub    %eax,%ecx
80100b48:	89 8d 60 ff ff ff    	mov    %ecx,-0xa0(%ebp)
  sp -= (3+argc+1) * 4;
80100b4e:	8d 04 9d 10 00 00 00 	lea    0x10(,%ebx,4),%eax
80100b55:	29 c7                	sub    %eax,%edi
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100b57:	50                   	push   %eax
80100b58:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
80100b5e:	50                   	push   %eax
80100b5f:	57                   	push   %edi
80100b60:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b66:	e8 83 59 00 00       	call   801064ee <copyout>
80100b6b:	83 c4 10             	add    $0x10,%esp
80100b6e:	85 c0                	test   %eax,%eax
80100b70:	0f 88 89 00 00 00    	js     80100bff <exec+0x32d>
  for(last=s=path; *s; s++)
80100b76:	8b 55 08             	mov    0x8(%ebp),%edx
80100b79:	89 d0                	mov    %edx,%eax
80100b7b:	eb 03                	jmp    80100b80 <exec+0x2ae>
80100b7d:	83 c0 01             	add    $0x1,%eax
80100b80:	0f b6 08             	movzbl (%eax),%ecx
80100b83:	84 c9                	test   %cl,%cl
80100b85:	74 0a                	je     80100b91 <exec+0x2bf>
    if(*s == '/')
80100b87:	80 f9 2f             	cmp    $0x2f,%cl
80100b8a:	75 f1                	jne    80100b7d <exec+0x2ab>
      last = s+1;
80100b8c:	8d 50 01             	lea    0x1(%eax),%edx
80100b8f:	eb ec                	jmp    80100b7d <exec+0x2ab>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100b91:	8b b5 f4 fe ff ff    	mov    -0x10c(%ebp),%esi
80100b97:	89 f0                	mov    %esi,%eax
80100b99:	83 c0 6c             	add    $0x6c,%eax
80100b9c:	83 ec 04             	sub    $0x4,%esp
80100b9f:	6a 10                	push   $0x10
80100ba1:	52                   	push   %edx
80100ba2:	50                   	push   %eax
80100ba3:	e8 c8 32 00 00       	call   80103e70 <safestrcpy>
  oldpgdir = curproc->pgdir;
80100ba8:	8b 5e 04             	mov    0x4(%esi),%ebx
  curproc->pgdir = pgdir;
80100bab:	8b 8d ec fe ff ff    	mov    -0x114(%ebp),%ecx
80100bb1:	89 4e 04             	mov    %ecx,0x4(%esi)
  curproc->sz = sz;
80100bb4:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100bba:	89 0e                	mov    %ecx,(%esi)
  curproc->tf->eip = elf.entry;  // main
80100bbc:	8b 46 18             	mov    0x18(%esi),%eax
80100bbf:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100bc5:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100bc8:	8b 46 18             	mov    0x18(%esi),%eax
80100bcb:	89 78 44             	mov    %edi,0x44(%eax)
  switchuvm(curproc);
80100bce:	89 34 24             	mov    %esi,(%esp)
80100bd1:	e8 38 53 00 00       	call   80105f0e <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 cd 56 00 00       	call   801062ab <freevm>
  return 0;
80100bde:	83 c4 10             	add    $0x10,%esp
80100be1:	b8 00 00 00 00       	mov    $0x0,%eax
80100be6:	e9 57 fd ff ff       	jmp    80100942 <exec+0x70>
  ip = 0;
80100beb:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bf0:	e9 96 fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bf5:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bfa:	e9 8c fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bff:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c04:	e9 82 fe ff ff       	jmp    80100a8b <exec+0x1b9>
  return -1;
80100c09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c0e:	e9 2f fd ff ff       	jmp    80100942 <exec+0x70>

80100c13 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c13:	55                   	push   %ebp
80100c14:	89 e5                	mov    %esp,%ebp
80100c16:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c19:	68 0d 66 10 80       	push   $0x8010660d
80100c1e:	68 e0 ef 10 80       	push   $0x8010efe0
80100c23:	e8 f9 2e 00 00       	call   80103b21 <initlock>
}
80100c28:	83 c4 10             	add    $0x10,%esp
80100c2b:	c9                   	leave  
80100c2c:	c3                   	ret    

80100c2d <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c2d:	55                   	push   %ebp
80100c2e:	89 e5                	mov    %esp,%ebp
80100c30:	53                   	push   %ebx
80100c31:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c34:	68 e0 ef 10 80       	push   $0x8010efe0
80100c39:	e8 1f 30 00 00       	call   80103c5d <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c3e:	83 c4 10             	add    $0x10,%esp
80100c41:	bb 14 f0 10 80       	mov    $0x8010f014,%ebx
80100c46:	81 fb 74 f9 10 80    	cmp    $0x8010f974,%ebx
80100c4c:	73 29                	jae    80100c77 <filealloc+0x4a>
    if(f->ref == 0){
80100c4e:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100c52:	74 05                	je     80100c59 <filealloc+0x2c>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c54:	83 c3 18             	add    $0x18,%ebx
80100c57:	eb ed                	jmp    80100c46 <filealloc+0x19>
      f->ref = 1;
80100c59:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100c60:	83 ec 0c             	sub    $0xc,%esp
80100c63:	68 e0 ef 10 80       	push   $0x8010efe0
80100c68:	e8 55 30 00 00       	call   80103cc2 <release>
      return f;
80100c6d:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100c70:	89 d8                	mov    %ebx,%eax
80100c72:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100c75:	c9                   	leave  
80100c76:	c3                   	ret    
  release(&ftable.lock);
80100c77:	83 ec 0c             	sub    $0xc,%esp
80100c7a:	68 e0 ef 10 80       	push   $0x8010efe0
80100c7f:	e8 3e 30 00 00       	call   80103cc2 <release>
  return 0;
80100c84:	83 c4 10             	add    $0x10,%esp
80100c87:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c8c:	eb e2                	jmp    80100c70 <filealloc+0x43>

80100c8e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100c8e:	55                   	push   %ebp
80100c8f:	89 e5                	mov    %esp,%ebp
80100c91:	53                   	push   %ebx
80100c92:	83 ec 10             	sub    $0x10,%esp
80100c95:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100c98:	68 e0 ef 10 80       	push   $0x8010efe0
80100c9d:	e8 bb 2f 00 00       	call   80103c5d <acquire>
  if(f->ref < 1)
80100ca2:	8b 43 04             	mov    0x4(%ebx),%eax
80100ca5:	83 c4 10             	add    $0x10,%esp
80100ca8:	85 c0                	test   %eax,%eax
80100caa:	7e 1a                	jle    80100cc6 <filedup+0x38>
    panic("filedup");
  f->ref++;
80100cac:	83 c0 01             	add    $0x1,%eax
80100caf:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100cb2:	83 ec 0c             	sub    $0xc,%esp
80100cb5:	68 e0 ef 10 80       	push   $0x8010efe0
80100cba:	e8 03 30 00 00       	call   80103cc2 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 14 66 10 80       	push   $0x80106614
80100cce:	e8 75 f6 ff ff       	call   80100348 <panic>

80100cd3 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100cd3:	55                   	push   %ebp
80100cd4:	89 e5                	mov    %esp,%ebp
80100cd6:	53                   	push   %ebx
80100cd7:	83 ec 30             	sub    $0x30,%esp
80100cda:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100cdd:	68 e0 ef 10 80       	push   $0x8010efe0
80100ce2:	e8 76 2f 00 00       	call   80103c5d <acquire>
  if(f->ref < 1)
80100ce7:	8b 43 04             	mov    0x4(%ebx),%eax
80100cea:	83 c4 10             	add    $0x10,%esp
80100ced:	85 c0                	test   %eax,%eax
80100cef:	7e 1f                	jle    80100d10 <fileclose+0x3d>
    panic("fileclose");
  if(--f->ref > 0){
80100cf1:	83 e8 01             	sub    $0x1,%eax
80100cf4:	89 43 04             	mov    %eax,0x4(%ebx)
80100cf7:	85 c0                	test   %eax,%eax
80100cf9:	7e 22                	jle    80100d1d <fileclose+0x4a>
    release(&ftable.lock);
80100cfb:	83 ec 0c             	sub    $0xc,%esp
80100cfe:	68 e0 ef 10 80       	push   $0x8010efe0
80100d03:	e8 ba 2f 00 00       	call   80103cc2 <release>
    return;
80100d08:	83 c4 10             	add    $0x10,%esp
  else if(ff.type == FD_INODE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
80100d0b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d0e:	c9                   	leave  
80100d0f:	c3                   	ret    
    panic("fileclose");
80100d10:	83 ec 0c             	sub    $0xc,%esp
80100d13:	68 1c 66 10 80       	push   $0x8010661c
80100d18:	e8 2b f6 ff ff       	call   80100348 <panic>
  ff = *f;
80100d1d:	8b 03                	mov    (%ebx),%eax
80100d1f:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d22:	8b 43 08             	mov    0x8(%ebx),%eax
80100d25:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d28:	8b 43 0c             	mov    0xc(%ebx),%eax
80100d2b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d2e:	8b 43 10             	mov    0x10(%ebx),%eax
80100d31:	89 45 f0             	mov    %eax,-0x10(%ebp)
  f->ref = 0;
80100d34:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d3b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d41:	83 ec 0c             	sub    $0xc,%esp
80100d44:	68 e0 ef 10 80       	push   $0x8010efe0
80100d49:	e8 74 2f 00 00       	call   80103cc2 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 13 1b 00 00       	call   80102876 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 7d 1b 00 00       	call   801028f0 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 62 21 00 00       	call   80102eea <pipeclose>
80100d88:	83 c4 10             	add    $0x10,%esp
80100d8b:	e9 7b ff ff ff       	jmp    80100d0b <fileclose+0x38>

80100d90 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100d90:	55                   	push   %ebp
80100d91:	89 e5                	mov    %esp,%ebp
80100d93:	53                   	push   %ebx
80100d94:	83 ec 04             	sub    $0x4,%esp
80100d97:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100d9a:	83 3b 02             	cmpl   $0x2,(%ebx)
80100d9d:	75 31                	jne    80100dd0 <filestat+0x40>
    ilock(f->ip);
80100d9f:	83 ec 0c             	sub    $0xc,%esp
80100da2:	ff 73 10             	pushl  0x10(%ebx)
80100da5:	e8 d7 07 00 00       	call   80101581 <ilock>
    stati(f->ip, st);
80100daa:	83 c4 08             	add    $0x8,%esp
80100dad:	ff 75 0c             	pushl  0xc(%ebp)
80100db0:	ff 73 10             	pushl  0x10(%ebx)
80100db3:	e8 90 09 00 00       	call   80101748 <stati>
    iunlock(f->ip);
80100db8:	83 c4 04             	add    $0x4,%esp
80100dbb:	ff 73 10             	pushl  0x10(%ebx)
80100dbe:	e8 80 08 00 00       	call   80101643 <iunlock>
    return 0;
80100dc3:	83 c4 10             	add    $0x10,%esp
80100dc6:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100dcb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100dce:	c9                   	leave  
80100dcf:	c3                   	ret    
  return -1;
80100dd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100dd5:	eb f4                	jmp    80100dcb <filestat+0x3b>

80100dd7 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100dd7:	55                   	push   %ebp
80100dd8:	89 e5                	mov    %esp,%ebp
80100dda:	56                   	push   %esi
80100ddb:	53                   	push   %ebx
80100ddc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100ddf:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100de3:	74 70                	je     80100e55 <fileread+0x7e>
    return -1;
  if(f->type == FD_PIPE)
80100de5:	8b 03                	mov    (%ebx),%eax
80100de7:	83 f8 01             	cmp    $0x1,%eax
80100dea:	74 44                	je     80100e30 <fileread+0x59>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100dec:	83 f8 02             	cmp    $0x2,%eax
80100def:	75 57                	jne    80100e48 <fileread+0x71>
    ilock(f->ip);
80100df1:	83 ec 0c             	sub    $0xc,%esp
80100df4:	ff 73 10             	pushl  0x10(%ebx)
80100df7:	e8 85 07 00 00       	call   80101581 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100dfc:	ff 75 10             	pushl  0x10(%ebp)
80100dff:	ff 73 14             	pushl  0x14(%ebx)
80100e02:	ff 75 0c             	pushl  0xc(%ebp)
80100e05:	ff 73 10             	pushl  0x10(%ebx)
80100e08:	e8 66 09 00 00       	call   80101773 <readi>
80100e0d:	89 c6                	mov    %eax,%esi
80100e0f:	83 c4 20             	add    $0x20,%esp
80100e12:	85 c0                	test   %eax,%eax
80100e14:	7e 03                	jle    80100e19 <fileread+0x42>
      f->off += r;
80100e16:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e19:	83 ec 0c             	sub    $0xc,%esp
80100e1c:	ff 73 10             	pushl  0x10(%ebx)
80100e1f:	e8 1f 08 00 00       	call   80101643 <iunlock>
    return r;
80100e24:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e27:	89 f0                	mov    %esi,%eax
80100e29:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e2c:	5b                   	pop    %ebx
80100e2d:	5e                   	pop    %esi
80100e2e:	5d                   	pop    %ebp
80100e2f:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e30:	83 ec 04             	sub    $0x4,%esp
80100e33:	ff 75 10             	pushl  0x10(%ebp)
80100e36:	ff 75 0c             	pushl  0xc(%ebp)
80100e39:	ff 73 0c             	pushl  0xc(%ebx)
80100e3c:	e8 01 22 00 00       	call   80103042 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 26 66 10 80       	push   $0x80106626
80100e50:	e8 f3 f4 ff ff       	call   80100348 <panic>
    return -1;
80100e55:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100e5a:	eb cb                	jmp    80100e27 <fileread+0x50>

80100e5c <filewrite>:

// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100e5c:	55                   	push   %ebp
80100e5d:	89 e5                	mov    %esp,%ebp
80100e5f:	57                   	push   %edi
80100e60:	56                   	push   %esi
80100e61:	53                   	push   %ebx
80100e62:	83 ec 1c             	sub    $0x1c,%esp
80100e65:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->writable == 0)
80100e68:	80 7b 09 00          	cmpb   $0x0,0x9(%ebx)
80100e6c:	0f 84 c5 00 00 00    	je     80100f37 <filewrite+0xdb>
    return -1;
  if(f->type == FD_PIPE)
80100e72:	8b 03                	mov    (%ebx),%eax
80100e74:	83 f8 01             	cmp    $0x1,%eax
80100e77:	74 10                	je     80100e89 <filewrite+0x2d>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e79:	83 f8 02             	cmp    $0x2,%eax
80100e7c:	0f 85 a8 00 00 00    	jne    80100f2a <filewrite+0xce>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100e82:	bf 00 00 00 00       	mov    $0x0,%edi
80100e87:	eb 67                	jmp    80100ef0 <filewrite+0x94>
    return pipewrite(f->pipe, addr, n);
80100e89:	83 ec 04             	sub    $0x4,%esp
80100e8c:	ff 75 10             	pushl  0x10(%ebp)
80100e8f:	ff 75 0c             	pushl  0xc(%ebp)
80100e92:	ff 73 0c             	pushl  0xc(%ebx)
80100e95:	e8 dc 20 00 00       	call   80102f76 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 cf 19 00 00       	call   80102876 <begin_op>
      ilock(f->ip);
80100ea7:	83 ec 0c             	sub    $0xc,%esp
80100eaa:	ff 73 10             	pushl  0x10(%ebx)
80100ead:	e8 cf 06 00 00       	call   80101581 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100eb2:	89 f8                	mov    %edi,%eax
80100eb4:	03 45 0c             	add    0xc(%ebp),%eax
80100eb7:	ff 75 e4             	pushl  -0x1c(%ebp)
80100eba:	ff 73 14             	pushl  0x14(%ebx)
80100ebd:	50                   	push   %eax
80100ebe:	ff 73 10             	pushl  0x10(%ebx)
80100ec1:	e8 aa 09 00 00       	call   80101870 <writei>
80100ec6:	89 c6                	mov    %eax,%esi
80100ec8:	83 c4 20             	add    $0x20,%esp
80100ecb:	85 c0                	test   %eax,%eax
80100ecd:	7e 03                	jle    80100ed2 <filewrite+0x76>
        f->off += r;
80100ecf:	01 43 14             	add    %eax,0x14(%ebx)
      iunlock(f->ip);
80100ed2:	83 ec 0c             	sub    $0xc,%esp
80100ed5:	ff 73 10             	pushl  0x10(%ebx)
80100ed8:	e8 66 07 00 00       	call   80101643 <iunlock>
      end_op();
80100edd:	e8 0e 1a 00 00       	call   801028f0 <end_op>

      if(r < 0)
80100ee2:	83 c4 10             	add    $0x10,%esp
80100ee5:	85 f6                	test   %esi,%esi
80100ee7:	78 31                	js     80100f1a <filewrite+0xbe>
        break;
      if(r != n1)
80100ee9:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
80100eec:	75 1f                	jne    80100f0d <filewrite+0xb1>
        panic("short filewrite");
      i += r;
80100eee:	01 f7                	add    %esi,%edi
    while(i < n){
80100ef0:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100ef3:	7d 25                	jge    80100f1a <filewrite+0xbe>
      int n1 = n - i;
80100ef5:	8b 45 10             	mov    0x10(%ebp),%eax
80100ef8:	29 f8                	sub    %edi,%eax
80100efa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(n1 > max)
80100efd:	3d 00 06 00 00       	cmp    $0x600,%eax
80100f02:	7e 9e                	jle    80100ea2 <filewrite+0x46>
        n1 = max;
80100f04:	c7 45 e4 00 06 00 00 	movl   $0x600,-0x1c(%ebp)
80100f0b:	eb 95                	jmp    80100ea2 <filewrite+0x46>
        panic("short filewrite");
80100f0d:	83 ec 0c             	sub    $0xc,%esp
80100f10:	68 2f 66 10 80       	push   $0x8010662f
80100f15:	e8 2e f4 ff ff       	call   80100348 <panic>
    }
    return i == n ? n : -1;
80100f1a:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f1d:	75 1f                	jne    80100f3e <filewrite+0xe2>
80100f1f:	8b 45 10             	mov    0x10(%ebp),%eax
  }
  panic("filewrite");
}
80100f22:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f25:	5b                   	pop    %ebx
80100f26:	5e                   	pop    %esi
80100f27:	5f                   	pop    %edi
80100f28:	5d                   	pop    %ebp
80100f29:	c3                   	ret    
  panic("filewrite");
80100f2a:	83 ec 0c             	sub    $0xc,%esp
80100f2d:	68 35 66 10 80       	push   $0x80106635
80100f32:	e8 11 f4 ff ff       	call   80100348 <panic>
    return -1;
80100f37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f3c:	eb e4                	jmp    80100f22 <filewrite+0xc6>
    return i == n ? n : -1;
80100f3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f43:	eb dd                	jmp    80100f22 <filewrite+0xc6>

80100f45 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100f45:	55                   	push   %ebp
80100f46:	89 e5                	mov    %esp,%ebp
80100f48:	57                   	push   %edi
80100f49:	56                   	push   %esi
80100f4a:	53                   	push   %ebx
80100f4b:	83 ec 0c             	sub    $0xc,%esp
80100f4e:	89 d7                	mov    %edx,%edi
  char *s;
  int len;

  while(*path == '/')
80100f50:	eb 03                	jmp    80100f55 <skipelem+0x10>
    path++;
80100f52:	83 c0 01             	add    $0x1,%eax
  while(*path == '/')
80100f55:	0f b6 10             	movzbl (%eax),%edx
80100f58:	80 fa 2f             	cmp    $0x2f,%dl
80100f5b:	74 f5                	je     80100f52 <skipelem+0xd>
  if(*path == 0)
80100f5d:	84 d2                	test   %dl,%dl
80100f5f:	74 59                	je     80100fba <skipelem+0x75>
80100f61:	89 c3                	mov    %eax,%ebx
80100f63:	eb 03                	jmp    80100f68 <skipelem+0x23>
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
    path++;
80100f65:	83 c3 01             	add    $0x1,%ebx
  while(*path != '/' && *path != 0)
80100f68:	0f b6 13             	movzbl (%ebx),%edx
80100f6b:	80 fa 2f             	cmp    $0x2f,%dl
80100f6e:	0f 95 c1             	setne  %cl
80100f71:	84 d2                	test   %dl,%dl
80100f73:	0f 95 c2             	setne  %dl
80100f76:	84 d1                	test   %dl,%cl
80100f78:	75 eb                	jne    80100f65 <skipelem+0x20>
  len = path - s;
80100f7a:	89 de                	mov    %ebx,%esi
80100f7c:	29 c6                	sub    %eax,%esi
  if(len >= DIRSIZ)
80100f7e:	83 fe 0d             	cmp    $0xd,%esi
80100f81:	7e 11                	jle    80100f94 <skipelem+0x4f>
    memmove(name, s, DIRSIZ);
80100f83:	83 ec 04             	sub    $0x4,%esp
80100f86:	6a 0e                	push   $0xe
80100f88:	50                   	push   %eax
80100f89:	57                   	push   %edi
80100f8a:	e8 f5 2d 00 00       	call   80103d84 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 e5 2d 00 00       	call   80103d84 <memmove>
    name[len] = 0;
80100f9f:	c6 04 37 00          	movb   $0x0,(%edi,%esi,1)
80100fa3:	83 c4 10             	add    $0x10,%esp
80100fa6:	eb 03                	jmp    80100fab <skipelem+0x66>
  }
  while(*path == '/')
    path++;
80100fa8:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
80100fab:	80 3b 2f             	cmpb   $0x2f,(%ebx)
80100fae:	74 f8                	je     80100fa8 <skipelem+0x63>
  return path;
}
80100fb0:	89 d8                	mov    %ebx,%eax
80100fb2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100fb5:	5b                   	pop    %ebx
80100fb6:	5e                   	pop    %esi
80100fb7:	5f                   	pop    %edi
80100fb8:	5d                   	pop    %ebp
80100fb9:	c3                   	ret    
    return 0;
80100fba:	bb 00 00 00 00       	mov    $0x0,%ebx
80100fbf:	eb ef                	jmp    80100fb0 <skipelem+0x6b>

80100fc1 <bzero>:
{
80100fc1:	55                   	push   %ebp
80100fc2:	89 e5                	mov    %esp,%ebp
80100fc4:	53                   	push   %ebx
80100fc5:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80100fc8:	52                   	push   %edx
80100fc9:	50                   	push   %eax
80100fca:	e8 9d f1 ff ff       	call   8010016c <bread>
80100fcf:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
80100fd1:	8d 40 5c             	lea    0x5c(%eax),%eax
80100fd4:	83 c4 0c             	add    $0xc,%esp
80100fd7:	68 00 02 00 00       	push   $0x200
80100fdc:	6a 00                	push   $0x0
80100fde:	50                   	push   %eax
80100fdf:	e8 25 2d 00 00       	call   80103d09 <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 b3 19 00 00       	call   8010299f <log_write>
  brelse(bp);
80100fec:	89 1c 24             	mov    %ebx,(%esp)
80100fef:	e8 e1 f1 ff ff       	call   801001d5 <brelse>
}
80100ff4:	83 c4 10             	add    $0x10,%esp
80100ff7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100ffa:	c9                   	leave  
80100ffb:	c3                   	ret    

80100ffc <balloc>:
{
80100ffc:	55                   	push   %ebp
80100ffd:	89 e5                	mov    %esp,%ebp
80100fff:	57                   	push   %edi
80101000:	56                   	push   %esi
80101001:	53                   	push   %ebx
80101002:	83 ec 1c             	sub    $0x1c,%esp
80101005:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101008:	be 00 00 00 00       	mov    $0x0,%esi
8010100d:	eb 14                	jmp    80101023 <balloc+0x27>
    brelse(bp);
8010100f:	83 ec 0c             	sub    $0xc,%esp
80101012:	ff 75 e4             	pushl  -0x1c(%ebp)
80101015:	e8 bb f1 ff ff       	call   801001d5 <brelse>
  for(b = 0; b < sb.size; b += BPB){
8010101a:	81 c6 00 10 00 00    	add    $0x1000,%esi
80101020:	83 c4 10             	add    $0x10,%esp
80101023:	39 35 e0 f9 10 80    	cmp    %esi,0x8010f9e0
80101029:	76 75                	jbe    801010a0 <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
8010102b:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
80101031:	85 f6                	test   %esi,%esi
80101033:	0f 49 c6             	cmovns %esi,%eax
80101036:	c1 f8 0c             	sar    $0xc,%eax
80101039:	03 05 f8 f9 10 80    	add    0x8010f9f8,%eax
8010103f:	83 ec 08             	sub    $0x8,%esp
80101042:	50                   	push   %eax
80101043:	ff 75 d8             	pushl  -0x28(%ebp)
80101046:	e8 21 f1 ff ff       	call   8010016c <bread>
8010104b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010104e:	83 c4 10             	add    $0x10,%esp
80101051:	b8 00 00 00 00       	mov    $0x0,%eax
80101056:	3d ff 0f 00 00       	cmp    $0xfff,%eax
8010105b:	7f b2                	jg     8010100f <balloc+0x13>
8010105d:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
80101060:	89 5d e0             	mov    %ebx,-0x20(%ebp)
80101063:	3b 1d e0 f9 10 80    	cmp    0x8010f9e0,%ebx
80101069:	73 a4                	jae    8010100f <balloc+0x13>
      m = 1 << (bi % 8);
8010106b:	99                   	cltd   
8010106c:	c1 ea 1d             	shr    $0x1d,%edx
8010106f:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80101072:	83 e1 07             	and    $0x7,%ecx
80101075:	29 d1                	sub    %edx,%ecx
80101077:	ba 01 00 00 00       	mov    $0x1,%edx
8010107c:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010107e:	8d 48 07             	lea    0x7(%eax),%ecx
80101081:	85 c0                	test   %eax,%eax
80101083:	0f 49 c8             	cmovns %eax,%ecx
80101086:	c1 f9 03             	sar    $0x3,%ecx
80101089:	89 4d dc             	mov    %ecx,-0x24(%ebp)
8010108c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010108f:	0f b6 4c 0f 5c       	movzbl 0x5c(%edi,%ecx,1),%ecx
80101094:	0f b6 f9             	movzbl %cl,%edi
80101097:	85 d7                	test   %edx,%edi
80101099:	74 12                	je     801010ad <balloc+0xb1>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010109b:	83 c0 01             	add    $0x1,%eax
8010109e:	eb b6                	jmp    80101056 <balloc+0x5a>
  panic("balloc: out of blocks");
801010a0:	83 ec 0c             	sub    $0xc,%esp
801010a3:	68 3f 66 10 80       	push   $0x8010663f
801010a8:	e8 9b f2 ff ff       	call   80100348 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
801010ad:	09 ca                	or     %ecx,%edx
801010af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801010b2:	8b 75 dc             	mov    -0x24(%ebp),%esi
801010b5:	88 54 30 5c          	mov    %dl,0x5c(%eax,%esi,1)
        log_write(bp);
801010b9:	83 ec 0c             	sub    $0xc,%esp
801010bc:	89 c6                	mov    %eax,%esi
801010be:	50                   	push   %eax
801010bf:	e8 db 18 00 00       	call   8010299f <log_write>
        brelse(bp);
801010c4:	89 34 24             	mov    %esi,(%esp)
801010c7:	e8 09 f1 ff ff       	call   801001d5 <brelse>
        bzero(dev, b + bi);
801010cc:	89 da                	mov    %ebx,%edx
801010ce:	8b 45 d8             	mov    -0x28(%ebp),%eax
801010d1:	e8 eb fe ff ff       	call   80100fc1 <bzero>
}
801010d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010d9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801010dc:	5b                   	pop    %ebx
801010dd:	5e                   	pop    %esi
801010de:	5f                   	pop    %edi
801010df:	5d                   	pop    %ebp
801010e0:	c3                   	ret    

801010e1 <bmap>:
{
801010e1:	55                   	push   %ebp
801010e2:	89 e5                	mov    %esp,%ebp
801010e4:	57                   	push   %edi
801010e5:	56                   	push   %esi
801010e6:	53                   	push   %ebx
801010e7:	83 ec 1c             	sub    $0x1c,%esp
801010ea:	89 c6                	mov    %eax,%esi
801010ec:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
801010ee:	83 fa 0b             	cmp    $0xb,%edx
801010f1:	77 17                	ja     8010110a <bmap+0x29>
    if((addr = ip->addrs[bn]) == 0)
801010f3:	8b 5c 90 5c          	mov    0x5c(%eax,%edx,4),%ebx
801010f7:	85 db                	test   %ebx,%ebx
801010f9:	75 4a                	jne    80101145 <bmap+0x64>
      ip->addrs[bn] = addr = balloc(ip->dev);
801010fb:	8b 00                	mov    (%eax),%eax
801010fd:	e8 fa fe ff ff       	call   80100ffc <balloc>
80101102:	89 c3                	mov    %eax,%ebx
80101104:	89 44 be 5c          	mov    %eax,0x5c(%esi,%edi,4)
80101108:	eb 3b                	jmp    80101145 <bmap+0x64>
  bn -= NDIRECT;
8010110a:	8d 5a f4             	lea    -0xc(%edx),%ebx
  if(bn < NINDIRECT){
8010110d:	83 fb 7f             	cmp    $0x7f,%ebx
80101110:	77 68                	ja     8010117a <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
80101112:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101118:	85 c0                	test   %eax,%eax
8010111a:	74 33                	je     8010114f <bmap+0x6e>
    bp = bread(ip->dev, addr);
8010111c:	83 ec 08             	sub    $0x8,%esp
8010111f:	50                   	push   %eax
80101120:	ff 36                	pushl  (%esi)
80101122:	e8 45 f0 ff ff       	call   8010016c <bread>
80101127:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101129:	8d 44 98 5c          	lea    0x5c(%eax,%ebx,4),%eax
8010112d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101130:	8b 18                	mov    (%eax),%ebx
80101132:	83 c4 10             	add    $0x10,%esp
80101135:	85 db                	test   %ebx,%ebx
80101137:	74 25                	je     8010115e <bmap+0x7d>
    brelse(bp);
80101139:	83 ec 0c             	sub    $0xc,%esp
8010113c:	57                   	push   %edi
8010113d:	e8 93 f0 ff ff       	call   801001d5 <brelse>
    return addr;
80101142:	83 c4 10             	add    $0x10,%esp
}
80101145:	89 d8                	mov    %ebx,%eax
80101147:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010114a:	5b                   	pop    %ebx
8010114b:	5e                   	pop    %esi
8010114c:	5f                   	pop    %edi
8010114d:	5d                   	pop    %ebp
8010114e:	c3                   	ret    
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
8010114f:	8b 06                	mov    (%esi),%eax
80101151:	e8 a6 fe ff ff       	call   80100ffc <balloc>
80101156:	89 86 8c 00 00 00    	mov    %eax,0x8c(%esi)
8010115c:	eb be                	jmp    8010111c <bmap+0x3b>
      a[bn] = addr = balloc(ip->dev);
8010115e:	8b 06                	mov    (%esi),%eax
80101160:	e8 97 fe ff ff       	call   80100ffc <balloc>
80101165:	89 c3                	mov    %eax,%ebx
80101167:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010116a:	89 18                	mov    %ebx,(%eax)
      log_write(bp);
8010116c:	83 ec 0c             	sub    $0xc,%esp
8010116f:	57                   	push   %edi
80101170:	e8 2a 18 00 00       	call   8010299f <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 55 66 10 80       	push   $0x80106655
80101182:	e8 c1 f1 ff ff       	call   80100348 <panic>

80101187 <iget>:
{
80101187:	55                   	push   %ebp
80101188:	89 e5                	mov    %esp,%ebp
8010118a:	57                   	push   %edi
8010118b:	56                   	push   %esi
8010118c:	53                   	push   %ebx
8010118d:	83 ec 28             	sub    $0x28,%esp
80101190:	89 c7                	mov    %eax,%edi
80101192:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
80101195:	68 00 fa 10 80       	push   $0x8010fa00
8010119a:	e8 be 2a 00 00       	call   80103c5d <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010119f:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011a2:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011a7:	bb 34 fa 10 80       	mov    $0x8010fa34,%ebx
801011ac:	eb 0a                	jmp    801011b8 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ae:	85 f6                	test   %esi,%esi
801011b0:	74 3b                	je     801011ed <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b2:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011b8:	81 fb 54 16 11 80    	cmp    $0x80111654,%ebx
801011be:	73 35                	jae    801011f5 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801011c0:	8b 43 08             	mov    0x8(%ebx),%eax
801011c3:	85 c0                	test   %eax,%eax
801011c5:	7e e7                	jle    801011ae <iget+0x27>
801011c7:	39 3b                	cmp    %edi,(%ebx)
801011c9:	75 e3                	jne    801011ae <iget+0x27>
801011cb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801011ce:	39 4b 04             	cmp    %ecx,0x4(%ebx)
801011d1:	75 db                	jne    801011ae <iget+0x27>
      ip->ref++;
801011d3:	83 c0 01             	add    $0x1,%eax
801011d6:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
801011d9:	83 ec 0c             	sub    $0xc,%esp
801011dc:	68 00 fa 10 80       	push   $0x8010fa00
801011e1:	e8 dc 2a 00 00       	call   80103cc2 <release>
      return ip;
801011e6:	83 c4 10             	add    $0x10,%esp
801011e9:	89 de                	mov    %ebx,%esi
801011eb:	eb 32                	jmp    8010121f <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ed:	85 c0                	test   %eax,%eax
801011ef:	75 c1                	jne    801011b2 <iget+0x2b>
      empty = ip;
801011f1:	89 de                	mov    %ebx,%esi
801011f3:	eb bd                	jmp    801011b2 <iget+0x2b>
  if(empty == 0)
801011f5:	85 f6                	test   %esi,%esi
801011f7:	74 30                	je     80101229 <iget+0xa2>
  ip->dev = dev;
801011f9:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
801011fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011fe:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
80101201:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101208:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010120f:	83 ec 0c             	sub    $0xc,%esp
80101212:	68 00 fa 10 80       	push   $0x8010fa00
80101217:	e8 a6 2a 00 00       	call   80103cc2 <release>
  return ip;
8010121c:	83 c4 10             	add    $0x10,%esp
}
8010121f:	89 f0                	mov    %esi,%eax
80101221:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101224:	5b                   	pop    %ebx
80101225:	5e                   	pop    %esi
80101226:	5f                   	pop    %edi
80101227:	5d                   	pop    %ebp
80101228:	c3                   	ret    
    panic("iget: no inodes");
80101229:	83 ec 0c             	sub    $0xc,%esp
8010122c:	68 68 66 10 80       	push   $0x80106668
80101231:	e8 12 f1 ff ff       	call   80100348 <panic>

80101236 <readsb>:
{
80101236:	55                   	push   %ebp
80101237:	89 e5                	mov    %esp,%ebp
80101239:	53                   	push   %ebx
8010123a:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
8010123d:	6a 01                	push   $0x1
8010123f:	ff 75 08             	pushl  0x8(%ebp)
80101242:	e8 25 ef ff ff       	call   8010016c <bread>
80101247:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
80101249:	8d 40 5c             	lea    0x5c(%eax),%eax
8010124c:	83 c4 0c             	add    $0xc,%esp
8010124f:	6a 1c                	push   $0x1c
80101251:	50                   	push   %eax
80101252:	ff 75 0c             	pushl  0xc(%ebp)
80101255:	e8 2a 2b 00 00       	call   80103d84 <memmove>
  brelse(bp);
8010125a:	89 1c 24             	mov    %ebx,(%esp)
8010125d:	e8 73 ef ff ff       	call   801001d5 <brelse>
}
80101262:	83 c4 10             	add    $0x10,%esp
80101265:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101268:	c9                   	leave  
80101269:	c3                   	ret    

8010126a <bfree>:
{
8010126a:	55                   	push   %ebp
8010126b:	89 e5                	mov    %esp,%ebp
8010126d:	56                   	push   %esi
8010126e:	53                   	push   %ebx
8010126f:	89 c6                	mov    %eax,%esi
80101271:	89 d3                	mov    %edx,%ebx
  readsb(dev, &sb);
80101273:	83 ec 08             	sub    $0x8,%esp
80101276:	68 e0 f9 10 80       	push   $0x8010f9e0
8010127b:	50                   	push   %eax
8010127c:	e8 b5 ff ff ff       	call   80101236 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101281:	89 d8                	mov    %ebx,%eax
80101283:	c1 e8 0c             	shr    $0xc,%eax
80101286:	03 05 f8 f9 10 80    	add    0x8010f9f8,%eax
8010128c:	83 c4 08             	add    $0x8,%esp
8010128f:	50                   	push   %eax
80101290:	56                   	push   %esi
80101291:	e8 d6 ee ff ff       	call   8010016c <bread>
80101296:	89 c6                	mov    %eax,%esi
  m = 1 << (bi % 8);
80101298:	89 d9                	mov    %ebx,%ecx
8010129a:	83 e1 07             	and    $0x7,%ecx
8010129d:	b8 01 00 00 00       	mov    $0x1,%eax
801012a2:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
801012a4:	83 c4 10             	add    $0x10,%esp
801012a7:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801012ad:	c1 fb 03             	sar    $0x3,%ebx
801012b0:	0f b6 54 1e 5c       	movzbl 0x5c(%esi,%ebx,1),%edx
801012b5:	0f b6 ca             	movzbl %dl,%ecx
801012b8:	85 c1                	test   %eax,%ecx
801012ba:	74 23                	je     801012df <bfree+0x75>
  bp->data[bi/8] &= ~m;
801012bc:	f7 d0                	not    %eax
801012be:	21 d0                	and    %edx,%eax
801012c0:	88 44 1e 5c          	mov    %al,0x5c(%esi,%ebx,1)
  log_write(bp);
801012c4:	83 ec 0c             	sub    $0xc,%esp
801012c7:	56                   	push   %esi
801012c8:	e8 d2 16 00 00       	call   8010299f <log_write>
  brelse(bp);
801012cd:	89 34 24             	mov    %esi,(%esp)
801012d0:	e8 00 ef ff ff       	call   801001d5 <brelse>
}
801012d5:	83 c4 10             	add    $0x10,%esp
801012d8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801012db:	5b                   	pop    %ebx
801012dc:	5e                   	pop    %esi
801012dd:	5d                   	pop    %ebp
801012de:	c3                   	ret    
    panic("freeing free block");
801012df:	83 ec 0c             	sub    $0xc,%esp
801012e2:	68 78 66 10 80       	push   $0x80106678
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 8b 66 10 80       	push   $0x8010668b
801012f8:	68 00 fa 10 80       	push   $0x8010fa00
801012fd:	e8 1f 28 00 00       	call   80103b21 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 92 66 10 80       	push   $0x80106692
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 40 fa 10 80       	add    $0x8010fa40,%eax
80101321:	50                   	push   %eax
80101322:	e8 ef 26 00 00       	call   80103a16 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101327:	83 c3 01             	add    $0x1,%ebx
8010132a:	83 c4 10             	add    $0x10,%esp
8010132d:	83 fb 31             	cmp    $0x31,%ebx
80101330:	7e da                	jle    8010130c <iinit+0x20>
  readsb(dev, &sb);
80101332:	83 ec 08             	sub    $0x8,%esp
80101335:	68 e0 f9 10 80       	push   $0x8010f9e0
8010133a:	ff 75 08             	pushl  0x8(%ebp)
8010133d:	e8 f4 fe ff ff       	call   80101236 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101342:	ff 35 f8 f9 10 80    	pushl  0x8010f9f8
80101348:	ff 35 f4 f9 10 80    	pushl  0x8010f9f4
8010134e:	ff 35 f0 f9 10 80    	pushl  0x8010f9f0
80101354:	ff 35 ec f9 10 80    	pushl  0x8010f9ec
8010135a:	ff 35 e8 f9 10 80    	pushl  0x8010f9e8
80101360:	ff 35 e4 f9 10 80    	pushl  0x8010f9e4
80101366:	ff 35 e0 f9 10 80    	pushl  0x8010f9e0
8010136c:	68 f8 66 10 80       	push   $0x801066f8
80101371:	e8 95 f2 ff ff       	call   8010060b <cprintf>
}
80101376:	83 c4 30             	add    $0x30,%esp
80101379:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010137c:	c9                   	leave  
8010137d:	c3                   	ret    

8010137e <ialloc>:
{
8010137e:	55                   	push   %ebp
8010137f:	89 e5                	mov    %esp,%ebp
80101381:	57                   	push   %edi
80101382:	56                   	push   %esi
80101383:	53                   	push   %ebx
80101384:	83 ec 1c             	sub    $0x1c,%esp
80101387:	8b 45 0c             	mov    0xc(%ebp),%eax
8010138a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
8010138d:	bb 01 00 00 00       	mov    $0x1,%ebx
80101392:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
80101395:	39 1d e8 f9 10 80    	cmp    %ebx,0x8010f9e8
8010139b:	76 3f                	jbe    801013dc <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
8010139d:	89 d8                	mov    %ebx,%eax
8010139f:	c1 e8 03             	shr    $0x3,%eax
801013a2:	03 05 f4 f9 10 80    	add    0x8010f9f4,%eax
801013a8:	83 ec 08             	sub    $0x8,%esp
801013ab:	50                   	push   %eax
801013ac:	ff 75 08             	pushl  0x8(%ebp)
801013af:	e8 b8 ed ff ff       	call   8010016c <bread>
801013b4:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
801013b6:	89 d8                	mov    %ebx,%eax
801013b8:	83 e0 07             	and    $0x7,%eax
801013bb:	c1 e0 06             	shl    $0x6,%eax
801013be:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
801013c2:	83 c4 10             	add    $0x10,%esp
801013c5:	66 83 3f 00          	cmpw   $0x0,(%edi)
801013c9:	74 1e                	je     801013e9 <ialloc+0x6b>
    brelse(bp);
801013cb:	83 ec 0c             	sub    $0xc,%esp
801013ce:	56                   	push   %esi
801013cf:	e8 01 ee ff ff       	call   801001d5 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
801013d4:	83 c3 01             	add    $0x1,%ebx
801013d7:	83 c4 10             	add    $0x10,%esp
801013da:	eb b6                	jmp    80101392 <ialloc+0x14>
  panic("ialloc: no inodes");
801013dc:	83 ec 0c             	sub    $0xc,%esp
801013df:	68 98 66 10 80       	push   $0x80106698
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 13 29 00 00       	call   80103d09 <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 9a 15 00 00       	call   8010299f <log_write>
      brelse(bp);
80101405:	89 34 24             	mov    %esi,(%esp)
80101408:	e8 c8 ed ff ff       	call   801001d5 <brelse>
      return iget(dev, inum);
8010140d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101410:	8b 45 08             	mov    0x8(%ebp),%eax
80101413:	e8 6f fd ff ff       	call   80101187 <iget>
}
80101418:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010141b:	5b                   	pop    %ebx
8010141c:	5e                   	pop    %esi
8010141d:	5f                   	pop    %edi
8010141e:	5d                   	pop    %ebp
8010141f:	c3                   	ret    

80101420 <iupdate>:
{
80101420:	55                   	push   %ebp
80101421:	89 e5                	mov    %esp,%ebp
80101423:	56                   	push   %esi
80101424:	53                   	push   %ebx
80101425:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101428:	8b 43 04             	mov    0x4(%ebx),%eax
8010142b:	c1 e8 03             	shr    $0x3,%eax
8010142e:	03 05 f4 f9 10 80    	add    0x8010f9f4,%eax
80101434:	83 ec 08             	sub    $0x8,%esp
80101437:	50                   	push   %eax
80101438:	ff 33                	pushl  (%ebx)
8010143a:	e8 2d ed ff ff       	call   8010016c <bread>
8010143f:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101441:	8b 43 04             	mov    0x4(%ebx),%eax
80101444:	83 e0 07             	and    $0x7,%eax
80101447:	c1 e0 06             	shl    $0x6,%eax
8010144a:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
8010144e:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
80101452:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101455:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
80101459:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010145d:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
80101461:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101465:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
80101469:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010146d:	8b 53 58             	mov    0x58(%ebx),%edx
80101470:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101473:	83 c3 5c             	add    $0x5c,%ebx
80101476:	83 c0 0c             	add    $0xc,%eax
80101479:	83 c4 0c             	add    $0xc,%esp
8010147c:	6a 34                	push   $0x34
8010147e:	53                   	push   %ebx
8010147f:	50                   	push   %eax
80101480:	e8 ff 28 00 00       	call   80103d84 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 12 15 00 00       	call   8010299f <log_write>
  brelse(bp);
8010148d:	89 34 24             	mov    %esi,(%esp)
80101490:	e8 40 ed ff ff       	call   801001d5 <brelse>
}
80101495:	83 c4 10             	add    $0x10,%esp
80101498:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010149b:	5b                   	pop    %ebx
8010149c:	5e                   	pop    %esi
8010149d:	5d                   	pop    %ebp
8010149e:	c3                   	ret    

8010149f <itrunc>:
{
8010149f:	55                   	push   %ebp
801014a0:	89 e5                	mov    %esp,%ebp
801014a2:	57                   	push   %edi
801014a3:	56                   	push   %esi
801014a4:	53                   	push   %ebx
801014a5:	83 ec 1c             	sub    $0x1c,%esp
801014a8:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
801014aa:	bb 00 00 00 00       	mov    $0x0,%ebx
801014af:	eb 03                	jmp    801014b4 <itrunc+0x15>
801014b1:	83 c3 01             	add    $0x1,%ebx
801014b4:	83 fb 0b             	cmp    $0xb,%ebx
801014b7:	7f 19                	jg     801014d2 <itrunc+0x33>
    if(ip->addrs[i]){
801014b9:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
801014bd:	85 d2                	test   %edx,%edx
801014bf:	74 f0                	je     801014b1 <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
801014c1:	8b 06                	mov    (%esi),%eax
801014c3:	e8 a2 fd ff ff       	call   8010126a <bfree>
      ip->addrs[i] = 0;
801014c8:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
801014cf:	00 
801014d0:	eb df                	jmp    801014b1 <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
801014d2:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
801014d8:	85 c0                	test   %eax,%eax
801014da:	75 1b                	jne    801014f7 <itrunc+0x58>
  ip->size = 0;
801014dc:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
801014e3:	83 ec 0c             	sub    $0xc,%esp
801014e6:	56                   	push   %esi
801014e7:	e8 34 ff ff ff       	call   80101420 <iupdate>
}
801014ec:	83 c4 10             	add    $0x10,%esp
801014ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
801014f2:	5b                   	pop    %ebx
801014f3:	5e                   	pop    %esi
801014f4:	5f                   	pop    %edi
801014f5:	5d                   	pop    %ebp
801014f6:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801014f7:	83 ec 08             	sub    $0x8,%esp
801014fa:	50                   	push   %eax
801014fb:	ff 36                	pushl  (%esi)
801014fd:	e8 6a ec ff ff       	call   8010016c <bread>
80101502:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
80101505:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
80101508:	83 c4 10             	add    $0x10,%esp
8010150b:	bb 00 00 00 00       	mov    $0x0,%ebx
80101510:	eb 03                	jmp    80101515 <itrunc+0x76>
80101512:	83 c3 01             	add    $0x1,%ebx
80101515:	83 fb 7f             	cmp    $0x7f,%ebx
80101518:	77 10                	ja     8010152a <itrunc+0x8b>
      if(a[j])
8010151a:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
8010151d:	85 d2                	test   %edx,%edx
8010151f:	74 f1                	je     80101512 <itrunc+0x73>
        bfree(ip->dev, a[j]);
80101521:	8b 06                	mov    (%esi),%eax
80101523:	e8 42 fd ff ff       	call   8010126a <bfree>
80101528:	eb e8                	jmp    80101512 <itrunc+0x73>
    brelse(bp);
8010152a:	83 ec 0c             	sub    $0xc,%esp
8010152d:	ff 75 e4             	pushl  -0x1c(%ebp)
80101530:	e8 a0 ec ff ff       	call   801001d5 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101535:	8b 06                	mov    (%esi),%eax
80101537:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
8010153d:	e8 28 fd ff ff       	call   8010126a <bfree>
    ip->addrs[NDIRECT] = 0;
80101542:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
80101549:	00 00 00 
8010154c:	83 c4 10             	add    $0x10,%esp
8010154f:	eb 8b                	jmp    801014dc <itrunc+0x3d>

80101551 <idup>:
{
80101551:	55                   	push   %ebp
80101552:	89 e5                	mov    %esp,%ebp
80101554:	53                   	push   %ebx
80101555:	83 ec 10             	sub    $0x10,%esp
80101558:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
8010155b:	68 00 fa 10 80       	push   $0x8010fa00
80101560:	e8 f8 26 00 00       	call   80103c5d <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
80101575:	e8 48 27 00 00       	call   80103cc2 <release>
}
8010157a:	89 d8                	mov    %ebx,%eax
8010157c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010157f:	c9                   	leave  
80101580:	c3                   	ret    

80101581 <ilock>:
{
80101581:	55                   	push   %ebp
80101582:	89 e5                	mov    %esp,%ebp
80101584:	56                   	push   %esi
80101585:	53                   	push   %ebx
80101586:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101589:	85 db                	test   %ebx,%ebx
8010158b:	74 22                	je     801015af <ilock+0x2e>
8010158d:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101591:	7e 1c                	jle    801015af <ilock+0x2e>
  acquiresleep(&ip->lock);
80101593:	83 ec 0c             	sub    $0xc,%esp
80101596:	8d 43 0c             	lea    0xc(%ebx),%eax
80101599:	50                   	push   %eax
8010159a:	e8 aa 24 00 00       	call   80103a49 <acquiresleep>
  if(ip->valid == 0){
8010159f:	83 c4 10             	add    $0x10,%esp
801015a2:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801015a6:	74 14                	je     801015bc <ilock+0x3b>
}
801015a8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801015ab:	5b                   	pop    %ebx
801015ac:	5e                   	pop    %esi
801015ad:	5d                   	pop    %ebp
801015ae:	c3                   	ret    
    panic("ilock");
801015af:	83 ec 0c             	sub    $0xc,%esp
801015b2:	68 aa 66 10 80       	push   $0x801066aa
801015b7:	e8 8c ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015bc:	8b 43 04             	mov    0x4(%ebx),%eax
801015bf:	c1 e8 03             	shr    $0x3,%eax
801015c2:	03 05 f4 f9 10 80    	add    0x8010f9f4,%eax
801015c8:	83 ec 08             	sub    $0x8,%esp
801015cb:	50                   	push   %eax
801015cc:	ff 33                	pushl  (%ebx)
801015ce:	e8 99 eb ff ff       	call   8010016c <bread>
801015d3:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801015d5:	8b 43 04             	mov    0x4(%ebx),%eax
801015d8:	83 e0 07             	and    $0x7,%eax
801015db:	c1 e0 06             	shl    $0x6,%eax
801015de:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
801015e2:	0f b7 10             	movzwl (%eax),%edx
801015e5:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
801015e9:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801015ed:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
801015f1:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801015f5:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
801015f9:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801015fd:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
80101601:	8b 50 08             	mov    0x8(%eax),%edx
80101604:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101607:	83 c0 0c             	add    $0xc,%eax
8010160a:	8d 53 5c             	lea    0x5c(%ebx),%edx
8010160d:	83 c4 0c             	add    $0xc,%esp
80101610:	6a 34                	push   $0x34
80101612:	50                   	push   %eax
80101613:	52                   	push   %edx
80101614:	e8 6b 27 00 00       	call   80103d84 <memmove>
    brelse(bp);
80101619:	89 34 24             	mov    %esi,(%esp)
8010161c:	e8 b4 eb ff ff       	call   801001d5 <brelse>
    ip->valid = 1;
80101621:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
80101628:	83 c4 10             	add    $0x10,%esp
8010162b:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
80101630:	0f 85 72 ff ff ff    	jne    801015a8 <ilock+0x27>
      panic("ilock: no type");
80101636:	83 ec 0c             	sub    $0xc,%esp
80101639:	68 b0 66 10 80       	push   $0x801066b0
8010163e:	e8 05 ed ff ff       	call   80100348 <panic>

80101643 <iunlock>:
{
80101643:	55                   	push   %ebp
80101644:	89 e5                	mov    %esp,%ebp
80101646:	56                   	push   %esi
80101647:	53                   	push   %ebx
80101648:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
8010164b:	85 db                	test   %ebx,%ebx
8010164d:	74 2c                	je     8010167b <iunlock+0x38>
8010164f:	8d 73 0c             	lea    0xc(%ebx),%esi
80101652:	83 ec 0c             	sub    $0xc,%esp
80101655:	56                   	push   %esi
80101656:	e8 78 24 00 00       	call   80103ad3 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 27 24 00 00       	call   80103a98 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 bf 66 10 80       	push   $0x801066bf
80101683:	e8 c0 ec ff ff       	call   80100348 <panic>

80101688 <iput>:
{
80101688:	55                   	push   %ebp
80101689:	89 e5                	mov    %esp,%ebp
8010168b:	57                   	push   %edi
8010168c:	56                   	push   %esi
8010168d:	53                   	push   %ebx
8010168e:	83 ec 18             	sub    $0x18,%esp
80101691:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
80101694:	8d 73 0c             	lea    0xc(%ebx),%esi
80101697:	56                   	push   %esi
80101698:	e8 ac 23 00 00       	call   80103a49 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 e2 23 00 00       	call   80103a98 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016bd:	e8 9b 25 00 00       	call   80103c5d <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016d2:	e8 eb 25 00 00       	call   80103cc2 <release>
}
801016d7:	83 c4 10             	add    $0x10,%esp
801016da:	8d 65 f4             	lea    -0xc(%ebp),%esp
801016dd:	5b                   	pop    %ebx
801016de:	5e                   	pop    %esi
801016df:	5f                   	pop    %edi
801016e0:	5d                   	pop    %ebp
801016e1:	c3                   	ret    
    acquire(&icache.lock);
801016e2:	83 ec 0c             	sub    $0xc,%esp
801016e5:	68 00 fa 10 80       	push   $0x8010fa00
801016ea:	e8 6e 25 00 00       	call   80103c5d <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016f9:	e8 c4 25 00 00       	call   80103cc2 <release>
    if(r == 1){
801016fe:	83 c4 10             	add    $0x10,%esp
80101701:	83 ff 01             	cmp    $0x1,%edi
80101704:	75 a7                	jne    801016ad <iput+0x25>
      itrunc(ip);
80101706:	89 d8                	mov    %ebx,%eax
80101708:	e8 92 fd ff ff       	call   8010149f <itrunc>
      ip->type = 0;
8010170d:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
80101713:	83 ec 0c             	sub    $0xc,%esp
80101716:	53                   	push   %ebx
80101717:	e8 04 fd ff ff       	call   80101420 <iupdate>
      ip->valid = 0;
8010171c:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
80101723:	83 c4 10             	add    $0x10,%esp
80101726:	eb 85                	jmp    801016ad <iput+0x25>

80101728 <iunlockput>:
{
80101728:	55                   	push   %ebp
80101729:	89 e5                	mov    %esp,%ebp
8010172b:	53                   	push   %ebx
8010172c:	83 ec 10             	sub    $0x10,%esp
8010172f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
80101732:	53                   	push   %ebx
80101733:	e8 0b ff ff ff       	call   80101643 <iunlock>
  iput(ip);
80101738:	89 1c 24             	mov    %ebx,(%esp)
8010173b:	e8 48 ff ff ff       	call   80101688 <iput>
}
80101740:	83 c4 10             	add    $0x10,%esp
80101743:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101746:	c9                   	leave  
80101747:	c3                   	ret    

80101748 <stati>:
{
80101748:	55                   	push   %ebp
80101749:	89 e5                	mov    %esp,%ebp
8010174b:	8b 55 08             	mov    0x8(%ebp),%edx
8010174e:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
80101751:	8b 0a                	mov    (%edx),%ecx
80101753:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
80101756:	8b 4a 04             	mov    0x4(%edx),%ecx
80101759:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
8010175c:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
80101760:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
80101763:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101767:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
8010176b:	8b 52 58             	mov    0x58(%edx),%edx
8010176e:	89 50 10             	mov    %edx,0x10(%eax)
}
80101771:	5d                   	pop    %ebp
80101772:	c3                   	ret    

80101773 <readi>:
{
80101773:	55                   	push   %ebp
80101774:	89 e5                	mov    %esp,%ebp
80101776:	57                   	push   %edi
80101777:	56                   	push   %esi
80101778:	53                   	push   %ebx
80101779:	83 ec 1c             	sub    $0x1c,%esp
8010177c:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(ip->type == T_DEV){
8010177f:	8b 45 08             	mov    0x8(%ebp),%eax
80101782:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101787:	74 2c                	je     801017b5 <readi+0x42>
  if(off > ip->size || off + n < off)
80101789:	8b 45 08             	mov    0x8(%ebp),%eax
8010178c:	8b 40 58             	mov    0x58(%eax),%eax
8010178f:	39 f8                	cmp    %edi,%eax
80101791:	0f 82 cb 00 00 00    	jb     80101862 <readi+0xef>
80101797:	89 fa                	mov    %edi,%edx
80101799:	03 55 14             	add    0x14(%ebp),%edx
8010179c:	0f 82 c7 00 00 00    	jb     80101869 <readi+0xf6>
  if(off + n > ip->size)
801017a2:	39 d0                	cmp    %edx,%eax
801017a4:	73 05                	jae    801017ab <readi+0x38>
    n = ip->size - off;
801017a6:	29 f8                	sub    %edi,%eax
801017a8:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801017ab:	be 00 00 00 00       	mov    $0x0,%esi
801017b0:	e9 8f 00 00 00       	jmp    80101844 <readi+0xd1>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801017b5:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801017b9:	66 83 f8 09          	cmp    $0x9,%ax
801017bd:	0f 87 91 00 00 00    	ja     80101854 <readi+0xe1>
801017c3:	98                   	cwtl   
801017c4:	8b 04 c5 80 f9 10 80 	mov    -0x7fef0680(,%eax,8),%eax
801017cb:	85 c0                	test   %eax,%eax
801017cd:	0f 84 88 00 00 00    	je     8010185b <readi+0xe8>
    return devsw[ip->major].read(ip, dst, n);
801017d3:	83 ec 04             	sub    $0x4,%esp
801017d6:	ff 75 14             	pushl  0x14(%ebp)
801017d9:	ff 75 0c             	pushl  0xc(%ebp)
801017dc:	ff 75 08             	pushl  0x8(%ebp)
801017df:	ff d0                	call   *%eax
801017e1:	83 c4 10             	add    $0x10,%esp
801017e4:	eb 66                	jmp    8010184c <readi+0xd9>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801017e6:	89 fa                	mov    %edi,%edx
801017e8:	c1 ea 09             	shr    $0x9,%edx
801017eb:	8b 45 08             	mov    0x8(%ebp),%eax
801017ee:	e8 ee f8 ff ff       	call   801010e1 <bmap>
801017f3:	83 ec 08             	sub    $0x8,%esp
801017f6:	50                   	push   %eax
801017f7:	8b 45 08             	mov    0x8(%ebp),%eax
801017fa:	ff 30                	pushl  (%eax)
801017fc:	e8 6b e9 ff ff       	call   8010016c <bread>
80101801:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
80101803:	89 f8                	mov    %edi,%eax
80101805:	25 ff 01 00 00       	and    $0x1ff,%eax
8010180a:	bb 00 02 00 00       	mov    $0x200,%ebx
8010180f:	29 c3                	sub    %eax,%ebx
80101811:	8b 55 14             	mov    0x14(%ebp),%edx
80101814:	29 f2                	sub    %esi,%edx
80101816:	83 c4 0c             	add    $0xc,%esp
80101819:	39 d3                	cmp    %edx,%ebx
8010181b:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
8010181e:	53                   	push   %ebx
8010181f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
80101822:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
80101826:	50                   	push   %eax
80101827:	ff 75 0c             	pushl  0xc(%ebp)
8010182a:	e8 55 25 00 00       	call   80103d84 <memmove>
    brelse(bp);
8010182f:	83 c4 04             	add    $0x4,%esp
80101832:	ff 75 e4             	pushl  -0x1c(%ebp)
80101835:	e8 9b e9 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010183a:	01 de                	add    %ebx,%esi
8010183c:	01 df                	add    %ebx,%edi
8010183e:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101841:	83 c4 10             	add    $0x10,%esp
80101844:	39 75 14             	cmp    %esi,0x14(%ebp)
80101847:	77 9d                	ja     801017e6 <readi+0x73>
  return n;
80101849:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010184c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010184f:	5b                   	pop    %ebx
80101850:	5e                   	pop    %esi
80101851:	5f                   	pop    %edi
80101852:	5d                   	pop    %ebp
80101853:	c3                   	ret    
      return -1;
80101854:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101859:	eb f1                	jmp    8010184c <readi+0xd9>
8010185b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101860:	eb ea                	jmp    8010184c <readi+0xd9>
    return -1;
80101862:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101867:	eb e3                	jmp    8010184c <readi+0xd9>
80101869:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010186e:	eb dc                	jmp    8010184c <readi+0xd9>

80101870 <writei>:
{
80101870:	55                   	push   %ebp
80101871:	89 e5                	mov    %esp,%ebp
80101873:	57                   	push   %edi
80101874:	56                   	push   %esi
80101875:	53                   	push   %ebx
80101876:	83 ec 0c             	sub    $0xc,%esp
  if(ip->type == T_DEV){
80101879:	8b 45 08             	mov    0x8(%ebp),%eax
8010187c:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101881:	74 2f                	je     801018b2 <writei+0x42>
  if(off > ip->size || off + n < off)
80101883:	8b 45 08             	mov    0x8(%ebp),%eax
80101886:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101889:	39 48 58             	cmp    %ecx,0x58(%eax)
8010188c:	0f 82 f4 00 00 00    	jb     80101986 <writei+0x116>
80101892:	89 c8                	mov    %ecx,%eax
80101894:	03 45 14             	add    0x14(%ebp),%eax
80101897:	0f 82 f0 00 00 00    	jb     8010198d <writei+0x11d>
  if(off + n > MAXFILE*BSIZE)
8010189d:	3d 00 18 01 00       	cmp    $0x11800,%eax
801018a2:	0f 87 ec 00 00 00    	ja     80101994 <writei+0x124>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801018a8:	be 00 00 00 00       	mov    $0x0,%esi
801018ad:	e9 94 00 00 00       	jmp    80101946 <writei+0xd6>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801018b2:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801018b6:	66 83 f8 09          	cmp    $0x9,%ax
801018ba:	0f 87 b8 00 00 00    	ja     80101978 <writei+0x108>
801018c0:	98                   	cwtl   
801018c1:	8b 04 c5 84 f9 10 80 	mov    -0x7fef067c(,%eax,8),%eax
801018c8:	85 c0                	test   %eax,%eax
801018ca:	0f 84 af 00 00 00    	je     8010197f <writei+0x10f>
    return devsw[ip->major].write(ip, src, n);
801018d0:	83 ec 04             	sub    $0x4,%esp
801018d3:	ff 75 14             	pushl  0x14(%ebp)
801018d6:	ff 75 0c             	pushl  0xc(%ebp)
801018d9:	ff 75 08             	pushl  0x8(%ebp)
801018dc:	ff d0                	call   *%eax
801018de:	83 c4 10             	add    $0x10,%esp
801018e1:	eb 7c                	jmp    8010195f <writei+0xef>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801018e3:	8b 55 10             	mov    0x10(%ebp),%edx
801018e6:	c1 ea 09             	shr    $0x9,%edx
801018e9:	8b 45 08             	mov    0x8(%ebp),%eax
801018ec:	e8 f0 f7 ff ff       	call   801010e1 <bmap>
801018f1:	83 ec 08             	sub    $0x8,%esp
801018f4:	50                   	push   %eax
801018f5:	8b 45 08             	mov    0x8(%ebp),%eax
801018f8:	ff 30                	pushl  (%eax)
801018fa:	e8 6d e8 ff ff       	call   8010016c <bread>
801018ff:	89 c7                	mov    %eax,%edi
    m = min(n - tot, BSIZE - off%BSIZE);
80101901:	8b 45 10             	mov    0x10(%ebp),%eax
80101904:	25 ff 01 00 00       	and    $0x1ff,%eax
80101909:	bb 00 02 00 00       	mov    $0x200,%ebx
8010190e:	29 c3                	sub    %eax,%ebx
80101910:	8b 55 14             	mov    0x14(%ebp),%edx
80101913:	29 f2                	sub    %esi,%edx
80101915:	83 c4 0c             	add    $0xc,%esp
80101918:	39 d3                	cmp    %edx,%ebx
8010191a:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
8010191d:	53                   	push   %ebx
8010191e:	ff 75 0c             	pushl  0xc(%ebp)
80101921:	8d 44 07 5c          	lea    0x5c(%edi,%eax,1),%eax
80101925:	50                   	push   %eax
80101926:	e8 59 24 00 00       	call   80103d84 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 6c 10 00 00       	call   8010299f <log_write>
    brelse(bp);
80101933:	89 3c 24             	mov    %edi,(%esp)
80101936:	e8 9a e8 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010193b:	01 de                	add    %ebx,%esi
8010193d:	01 5d 10             	add    %ebx,0x10(%ebp)
80101940:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101943:	83 c4 10             	add    $0x10,%esp
80101946:	3b 75 14             	cmp    0x14(%ebp),%esi
80101949:	72 98                	jb     801018e3 <writei+0x73>
  if(n > 0 && off > ip->size){
8010194b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010194f:	74 0b                	je     8010195c <writei+0xec>
80101951:	8b 45 08             	mov    0x8(%ebp),%eax
80101954:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101957:	39 48 58             	cmp    %ecx,0x58(%eax)
8010195a:	72 0b                	jb     80101967 <writei+0xf7>
  return n;
8010195c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010195f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101962:	5b                   	pop    %ebx
80101963:	5e                   	pop    %esi
80101964:	5f                   	pop    %edi
80101965:	5d                   	pop    %ebp
80101966:	c3                   	ret    
    ip->size = off;
80101967:	89 48 58             	mov    %ecx,0x58(%eax)
    iupdate(ip);
8010196a:	83 ec 0c             	sub    $0xc,%esp
8010196d:	50                   	push   %eax
8010196e:	e8 ad fa ff ff       	call   80101420 <iupdate>
80101973:	83 c4 10             	add    $0x10,%esp
80101976:	eb e4                	jmp    8010195c <writei+0xec>
      return -1;
80101978:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010197d:	eb e0                	jmp    8010195f <writei+0xef>
8010197f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101984:	eb d9                	jmp    8010195f <writei+0xef>
    return -1;
80101986:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010198b:	eb d2                	jmp    8010195f <writei+0xef>
8010198d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101992:	eb cb                	jmp    8010195f <writei+0xef>
    return -1;
80101994:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101999:	eb c4                	jmp    8010195f <writei+0xef>

8010199b <namecmp>:
{
8010199b:	55                   	push   %ebp
8010199c:	89 e5                	mov    %esp,%ebp
8010199e:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
801019a1:	6a 0e                	push   $0xe
801019a3:	ff 75 0c             	pushl  0xc(%ebp)
801019a6:	ff 75 08             	pushl  0x8(%ebp)
801019a9:	e8 3d 24 00 00       	call   80103deb <strncmp>
}
801019ae:	c9                   	leave  
801019af:	c3                   	ret    

801019b0 <dirlookup>:
{
801019b0:	55                   	push   %ebp
801019b1:	89 e5                	mov    %esp,%ebp
801019b3:	57                   	push   %edi
801019b4:	56                   	push   %esi
801019b5:	53                   	push   %ebx
801019b6:	83 ec 1c             	sub    $0x1c,%esp
801019b9:	8b 75 08             	mov    0x8(%ebp),%esi
801019bc:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
801019bf:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801019c4:	75 07                	jne    801019cd <dirlookup+0x1d>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019c6:	bb 00 00 00 00       	mov    $0x0,%ebx
801019cb:	eb 1d                	jmp    801019ea <dirlookup+0x3a>
    panic("dirlookup not DIR");
801019cd:	83 ec 0c             	sub    $0xc,%esp
801019d0:	68 c7 66 10 80       	push   $0x801066c7
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 d9 66 10 80       	push   $0x801066d9
801019e2:	e8 61 e9 ff ff       	call   80100348 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019e7:	83 c3 10             	add    $0x10,%ebx
801019ea:	39 5e 58             	cmp    %ebx,0x58(%esi)
801019ed:	76 48                	jbe    80101a37 <dirlookup+0x87>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801019ef:	6a 10                	push   $0x10
801019f1:	53                   	push   %ebx
801019f2:	8d 45 d8             	lea    -0x28(%ebp),%eax
801019f5:	50                   	push   %eax
801019f6:	56                   	push   %esi
801019f7:	e8 77 fd ff ff       	call   80101773 <readi>
801019fc:	83 c4 10             	add    $0x10,%esp
801019ff:	83 f8 10             	cmp    $0x10,%eax
80101a02:	75 d6                	jne    801019da <dirlookup+0x2a>
    if(de.inum == 0)
80101a04:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101a09:	74 dc                	je     801019e7 <dirlookup+0x37>
    if(namecmp(name, de.name) == 0){
80101a0b:	83 ec 08             	sub    $0x8,%esp
80101a0e:	8d 45 da             	lea    -0x26(%ebp),%eax
80101a11:	50                   	push   %eax
80101a12:	57                   	push   %edi
80101a13:	e8 83 ff ff ff       	call   8010199b <namecmp>
80101a18:	83 c4 10             	add    $0x10,%esp
80101a1b:	85 c0                	test   %eax,%eax
80101a1d:	75 c8                	jne    801019e7 <dirlookup+0x37>
      if(poff)
80101a1f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101a23:	74 05                	je     80101a2a <dirlookup+0x7a>
        *poff = off;
80101a25:	8b 45 10             	mov    0x10(%ebp),%eax
80101a28:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101a2a:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101a2e:	8b 06                	mov    (%esi),%eax
80101a30:	e8 52 f7 ff ff       	call   80101187 <iget>
80101a35:	eb 05                	jmp    80101a3c <dirlookup+0x8c>
  return 0;
80101a37:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101a3c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a3f:	5b                   	pop    %ebx
80101a40:	5e                   	pop    %esi
80101a41:	5f                   	pop    %edi
80101a42:	5d                   	pop    %ebp
80101a43:	c3                   	ret    

80101a44 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101a44:	55                   	push   %ebp
80101a45:	89 e5                	mov    %esp,%ebp
80101a47:	57                   	push   %edi
80101a48:	56                   	push   %esi
80101a49:	53                   	push   %ebx
80101a4a:	83 ec 1c             	sub    $0x1c,%esp
80101a4d:	89 c6                	mov    %eax,%esi
80101a4f:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101a52:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101a55:	80 38 2f             	cmpb   $0x2f,(%eax)
80101a58:	74 17                	je     80101a71 <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101a5a:	e8 5f 18 00 00       	call   801032be <myproc>
80101a5f:	83 ec 0c             	sub    $0xc,%esp
80101a62:	ff 70 68             	pushl  0x68(%eax)
80101a65:	e8 e7 fa ff ff       	call   80101551 <idup>
80101a6a:	89 c3                	mov    %eax,%ebx
80101a6c:	83 c4 10             	add    $0x10,%esp
80101a6f:	eb 53                	jmp    80101ac4 <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101a71:	ba 01 00 00 00       	mov    $0x1,%edx
80101a76:	b8 01 00 00 00       	mov    $0x1,%eax
80101a7b:	e8 07 f7 ff ff       	call   80101187 <iget>
80101a80:	89 c3                	mov    %eax,%ebx
80101a82:	eb 40                	jmp    80101ac4 <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101a84:	83 ec 0c             	sub    $0xc,%esp
80101a87:	53                   	push   %ebx
80101a88:	e8 9b fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101a8d:	83 c4 10             	add    $0x10,%esp
80101a90:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101a95:	89 d8                	mov    %ebx,%eax
80101a97:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a9a:	5b                   	pop    %ebx
80101a9b:	5e                   	pop    %esi
80101a9c:	5f                   	pop    %edi
80101a9d:	5d                   	pop    %ebp
80101a9e:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101a9f:	83 ec 04             	sub    $0x4,%esp
80101aa2:	6a 00                	push   $0x0
80101aa4:	ff 75 e4             	pushl  -0x1c(%ebp)
80101aa7:	53                   	push   %ebx
80101aa8:	e8 03 ff ff ff       	call   801019b0 <dirlookup>
80101aad:	89 c7                	mov    %eax,%edi
80101aaf:	83 c4 10             	add    $0x10,%esp
80101ab2:	85 c0                	test   %eax,%eax
80101ab4:	74 4a                	je     80101b00 <namex+0xbc>
    iunlockput(ip);
80101ab6:	83 ec 0c             	sub    $0xc,%esp
80101ab9:	53                   	push   %ebx
80101aba:	e8 69 fc ff ff       	call   80101728 <iunlockput>
    ip = next;
80101abf:	83 c4 10             	add    $0x10,%esp
80101ac2:	89 fb                	mov    %edi,%ebx
  while((path = skipelem(path, name)) != 0){
80101ac4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101ac7:	89 f0                	mov    %esi,%eax
80101ac9:	e8 77 f4 ff ff       	call   80100f45 <skipelem>
80101ace:	89 c6                	mov    %eax,%esi
80101ad0:	85 c0                	test   %eax,%eax
80101ad2:	74 3c                	je     80101b10 <namex+0xcc>
    ilock(ip);
80101ad4:	83 ec 0c             	sub    $0xc,%esp
80101ad7:	53                   	push   %ebx
80101ad8:	e8 a4 fa ff ff       	call   80101581 <ilock>
    if(ip->type != T_DIR){
80101add:	83 c4 10             	add    $0x10,%esp
80101ae0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80101ae5:	75 9d                	jne    80101a84 <namex+0x40>
    if(nameiparent && *path == '\0'){
80101ae7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101aeb:	74 b2                	je     80101a9f <namex+0x5b>
80101aed:	80 3e 00             	cmpb   $0x0,(%esi)
80101af0:	75 ad                	jne    80101a9f <namex+0x5b>
      iunlock(ip);
80101af2:	83 ec 0c             	sub    $0xc,%esp
80101af5:	53                   	push   %ebx
80101af6:	e8 48 fb ff ff       	call   80101643 <iunlock>
      return ip;
80101afb:	83 c4 10             	add    $0x10,%esp
80101afe:	eb 95                	jmp    80101a95 <namex+0x51>
      iunlockput(ip);
80101b00:	83 ec 0c             	sub    $0xc,%esp
80101b03:	53                   	push   %ebx
80101b04:	e8 1f fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101b09:	83 c4 10             	add    $0x10,%esp
80101b0c:	89 fb                	mov    %edi,%ebx
80101b0e:	eb 85                	jmp    80101a95 <namex+0x51>
  if(nameiparent){
80101b10:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b14:	0f 84 7b ff ff ff    	je     80101a95 <namex+0x51>
    iput(ip);
80101b1a:	83 ec 0c             	sub    $0xc,%esp
80101b1d:	53                   	push   %ebx
80101b1e:	e8 65 fb ff ff       	call   80101688 <iput>
    return 0;
80101b23:	83 c4 10             	add    $0x10,%esp
80101b26:	bb 00 00 00 00       	mov    $0x0,%ebx
80101b2b:	e9 65 ff ff ff       	jmp    80101a95 <namex+0x51>

80101b30 <dirlink>:
{
80101b30:	55                   	push   %ebp
80101b31:	89 e5                	mov    %esp,%ebp
80101b33:	57                   	push   %edi
80101b34:	56                   	push   %esi
80101b35:	53                   	push   %ebx
80101b36:	83 ec 20             	sub    $0x20,%esp
80101b39:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101b3c:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101b3f:	6a 00                	push   $0x0
80101b41:	57                   	push   %edi
80101b42:	53                   	push   %ebx
80101b43:	e8 68 fe ff ff       	call   801019b0 <dirlookup>
80101b48:	83 c4 10             	add    $0x10,%esp
80101b4b:	85 c0                	test   %eax,%eax
80101b4d:	75 2d                	jne    80101b7c <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b4f:	b8 00 00 00 00       	mov    $0x0,%eax
80101b54:	89 c6                	mov    %eax,%esi
80101b56:	39 43 58             	cmp    %eax,0x58(%ebx)
80101b59:	76 41                	jbe    80101b9c <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101b5b:	6a 10                	push   $0x10
80101b5d:	50                   	push   %eax
80101b5e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101b61:	50                   	push   %eax
80101b62:	53                   	push   %ebx
80101b63:	e8 0b fc ff ff       	call   80101773 <readi>
80101b68:	83 c4 10             	add    $0x10,%esp
80101b6b:	83 f8 10             	cmp    $0x10,%eax
80101b6e:	75 1f                	jne    80101b8f <dirlink+0x5f>
    if(de.inum == 0)
80101b70:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101b75:	74 25                	je     80101b9c <dirlink+0x6c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b77:	8d 46 10             	lea    0x10(%esi),%eax
80101b7a:	eb d8                	jmp    80101b54 <dirlink+0x24>
    iput(ip);
80101b7c:	83 ec 0c             	sub    $0xc,%esp
80101b7f:	50                   	push   %eax
80101b80:	e8 03 fb ff ff       	call   80101688 <iput>
    return -1;
80101b85:	83 c4 10             	add    $0x10,%esp
80101b88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101b8d:	eb 3d                	jmp    80101bcc <dirlink+0x9c>
      panic("dirlink read");
80101b8f:	83 ec 0c             	sub    $0xc,%esp
80101b92:	68 e8 66 10 80       	push   $0x801066e8
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 7a 22 00 00       	call   80103e28 <strncpy>
  de.inum = inum;
80101bae:	8b 45 10             	mov    0x10(%ebp),%eax
80101bb1:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101bb5:	6a 10                	push   $0x10
80101bb7:	56                   	push   %esi
80101bb8:	57                   	push   %edi
80101bb9:	53                   	push   %ebx
80101bba:	e8 b1 fc ff ff       	call   80101870 <writei>
80101bbf:	83 c4 20             	add    $0x20,%esp
80101bc2:	83 f8 10             	cmp    $0x10,%eax
80101bc5:	75 0d                	jne    80101bd4 <dirlink+0xa4>
  return 0;
80101bc7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101bcc:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101bcf:	5b                   	pop    %ebx
80101bd0:	5e                   	pop    %esi
80101bd1:	5f                   	pop    %edi
80101bd2:	5d                   	pop    %ebp
80101bd3:	c3                   	ret    
    panic("dirlink");
80101bd4:	83 ec 0c             	sub    $0xc,%esp
80101bd7:	68 f4 6c 10 80       	push   $0x80106cf4
80101bdc:	e8 67 e7 ff ff       	call   80100348 <panic>

80101be1 <namei>:

struct inode*
namei(char *path)
{
80101be1:	55                   	push   %ebp
80101be2:	89 e5                	mov    %esp,%ebp
80101be4:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101be7:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101bea:	ba 00 00 00 00       	mov    $0x0,%edx
80101bef:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf2:	e8 4d fe ff ff       	call   80101a44 <namex>
}
80101bf7:	c9                   	leave  
80101bf8:	c3                   	ret    

80101bf9 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101bf9:	55                   	push   %ebp
80101bfa:	89 e5                	mov    %esp,%ebp
80101bfc:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101bff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101c02:	ba 01 00 00 00       	mov    $0x1,%edx
80101c07:	8b 45 08             	mov    0x8(%ebp),%eax
80101c0a:	e8 35 fe ff ff       	call   80101a44 <namex>
}
80101c0f:	c9                   	leave  
80101c10:	c3                   	ret    

80101c11 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101c11:	55                   	push   %ebp
80101c12:	89 e5                	mov    %esp,%ebp
80101c14:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101c16:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101c1b:	ec                   	in     (%dx),%al
80101c1c:	89 c2                	mov    %eax,%edx
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101c1e:	83 e0 c0             	and    $0xffffffc0,%eax
80101c21:	3c 40                	cmp    $0x40,%al
80101c23:	75 f1                	jne    80101c16 <idewait+0x5>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101c25:	85 c9                	test   %ecx,%ecx
80101c27:	74 0c                	je     80101c35 <idewait+0x24>
80101c29:	f6 c2 21             	test   $0x21,%dl
80101c2c:	75 0e                	jne    80101c3c <idewait+0x2b>
    return -1;
  return 0;
80101c2e:	b8 00 00 00 00       	mov    $0x0,%eax
80101c33:	eb 05                	jmp    80101c3a <idewait+0x29>
80101c35:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101c3a:	5d                   	pop    %ebp
80101c3b:	c3                   	ret    
    return -1;
80101c3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101c41:	eb f7                	jmp    80101c3a <idewait+0x29>

80101c43 <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101c43:	55                   	push   %ebp
80101c44:	89 e5                	mov    %esp,%ebp
80101c46:	56                   	push   %esi
80101c47:	53                   	push   %ebx
  if(b == 0)
80101c48:	85 c0                	test   %eax,%eax
80101c4a:	74 7d                	je     80101cc9 <idestart+0x86>
80101c4c:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101c4e:	8b 58 08             	mov    0x8(%eax),%ebx
80101c51:	81 fb e7 03 00 00    	cmp    $0x3e7,%ebx
80101c57:	77 7d                	ja     80101cd6 <idestart+0x93>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101c59:	b8 00 00 00 00       	mov    $0x0,%eax
80101c5e:	e8 ae ff ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101c63:	b8 00 00 00 00       	mov    $0x0,%eax
80101c68:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101c6d:	ee                   	out    %al,(%dx)
80101c6e:	b8 01 00 00 00       	mov    $0x1,%eax
80101c73:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101c78:	ee                   	out    %al,(%dx)
80101c79:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101c7e:	89 d8                	mov    %ebx,%eax
80101c80:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101c81:	89 d8                	mov    %ebx,%eax
80101c83:	c1 f8 08             	sar    $0x8,%eax
80101c86:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101c8b:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101c8c:	89 d8                	mov    %ebx,%eax
80101c8e:	c1 f8 10             	sar    $0x10,%eax
80101c91:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101c96:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101c97:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101c9b:	c1 e0 04             	shl    $0x4,%eax
80101c9e:	83 e0 10             	and    $0x10,%eax
80101ca1:	c1 fb 18             	sar    $0x18,%ebx
80101ca4:	83 e3 0f             	and    $0xf,%ebx
80101ca7:	09 d8                	or     %ebx,%eax
80101ca9:	83 c8 e0             	or     $0xffffffe0,%eax
80101cac:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101cb1:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101cb2:	f6 06 04             	testb  $0x4,(%esi)
80101cb5:	75 2c                	jne    80101ce3 <idestart+0xa0>
80101cb7:	b8 20 00 00 00       	mov    $0x20,%eax
80101cbc:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101cc1:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101cc2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101cc5:	5b                   	pop    %ebx
80101cc6:	5e                   	pop    %esi
80101cc7:	5d                   	pop    %ebp
80101cc8:	c3                   	ret    
    panic("idestart");
80101cc9:	83 ec 0c             	sub    $0xc,%esp
80101ccc:	68 4b 67 10 80       	push   $0x8010674b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 54 67 10 80       	push   $0x80106754
80101cde:	e8 65 e6 ff ff       	call   80100348 <panic>
80101ce3:	b8 30 00 00 00       	mov    $0x30,%eax
80101ce8:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ced:	ee                   	out    %al,(%dx)
    outsl(0x1f0, b->data, BSIZE/4);
80101cee:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101cf1:	b9 80 00 00 00       	mov    $0x80,%ecx
80101cf6:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101cfb:	fc                   	cld    
80101cfc:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80101cfe:	eb c2                	jmp    80101cc2 <idestart+0x7f>

80101d00 <ideinit>:
{
80101d00:	55                   	push   %ebp
80101d01:	89 e5                	mov    %esp,%ebp
80101d03:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101d06:	68 66 67 10 80       	push   $0x80106766
80101d0b:	68 80 95 10 80       	push   $0x80109580
80101d10:	e8 0c 1e 00 00       	call   80103b21 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 40 1d 13 80       	mov    0x80131d40,%eax
80101d1d:	83 e8 01             	sub    $0x1,%eax
80101d20:	50                   	push   %eax
80101d21:	6a 0e                	push   $0xe
80101d23:	e8 56 02 00 00       	call   80101f7e <ioapicenable>
  idewait(0);
80101d28:	b8 00 00 00 00       	mov    $0x0,%eax
80101d2d:	e8 df fe ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d32:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101d37:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d3c:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101d3d:	83 c4 10             	add    $0x10,%esp
80101d40:	b9 00 00 00 00       	mov    $0x0,%ecx
80101d45:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101d4b:	7f 19                	jg     80101d66 <ideinit+0x66>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101d4d:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d52:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101d53:	84 c0                	test   %al,%al
80101d55:	75 05                	jne    80101d5c <ideinit+0x5c>
  for(i=0; i<1000; i++){
80101d57:	83 c1 01             	add    $0x1,%ecx
80101d5a:	eb e9                	jmp    80101d45 <ideinit+0x45>
      havedisk1 = 1;
80101d5c:	c7 05 60 95 10 80 01 	movl   $0x1,0x80109560
80101d63:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d66:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101d6b:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d70:	ee                   	out    %al,(%dx)
}
80101d71:	c9                   	leave  
80101d72:	c3                   	ret    

80101d73 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101d73:	55                   	push   %ebp
80101d74:	89 e5                	mov    %esp,%ebp
80101d76:	57                   	push   %edi
80101d77:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101d78:	83 ec 0c             	sub    $0xc,%esp
80101d7b:	68 80 95 10 80       	push   $0x80109580
80101d80:	e8 d8 1e 00 00       	call   80103c5d <acquire>

  if((b = idequeue) == 0){
80101d85:	8b 1d 64 95 10 80    	mov    0x80109564,%ebx
80101d8b:	83 c4 10             	add    $0x10,%esp
80101d8e:	85 db                	test   %ebx,%ebx
80101d90:	74 48                	je     80101dda <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d92:	8b 43 58             	mov    0x58(%ebx),%eax
80101d95:	a3 64 95 10 80       	mov    %eax,0x80109564

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101d9a:	f6 03 04             	testb  $0x4,(%ebx)
80101d9d:	74 4d                	je     80101dec <ideintr+0x79>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101d9f:	8b 03                	mov    (%ebx),%eax
80101da1:	83 c8 02             	or     $0x2,%eax
  b->flags &= ~B_DIRTY;
80101da4:	83 e0 fb             	and    $0xfffffffb,%eax
80101da7:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101da9:	83 ec 0c             	sub    $0xc,%esp
80101dac:	53                   	push   %ebx
80101dad:	e8 15 1b 00 00       	call   801038c7 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101db2:	a1 64 95 10 80       	mov    0x80109564,%eax
80101db7:	83 c4 10             	add    $0x10,%esp
80101dba:	85 c0                	test   %eax,%eax
80101dbc:	74 05                	je     80101dc3 <ideintr+0x50>
    idestart(idequeue);
80101dbe:	e8 80 fe ff ff       	call   80101c43 <idestart>

  release(&idelock);
80101dc3:	83 ec 0c             	sub    $0xc,%esp
80101dc6:	68 80 95 10 80       	push   $0x80109580
80101dcb:	e8 f2 1e 00 00       	call   80103cc2 <release>
80101dd0:	83 c4 10             	add    $0x10,%esp
}
80101dd3:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101dd6:	5b                   	pop    %ebx
80101dd7:	5f                   	pop    %edi
80101dd8:	5d                   	pop    %ebp
80101dd9:	c3                   	ret    
    release(&idelock);
80101dda:	83 ec 0c             	sub    $0xc,%esp
80101ddd:	68 80 95 10 80       	push   $0x80109580
80101de2:	e8 db 1e 00 00       	call   80103cc2 <release>
    return;
80101de7:	83 c4 10             	add    $0x10,%esp
80101dea:	eb e7                	jmp    80101dd3 <ideintr+0x60>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101dec:	b8 01 00 00 00       	mov    $0x1,%eax
80101df1:	e8 1b fe ff ff       	call   80101c11 <idewait>
80101df6:	85 c0                	test   %eax,%eax
80101df8:	78 a5                	js     80101d9f <ideintr+0x2c>
    insl(0x1f0, b->data, BSIZE/4);
80101dfa:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101dfd:	b9 80 00 00 00       	mov    $0x80,%ecx
80101e02:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101e07:	fc                   	cld    
80101e08:	f3 6d                	rep insl (%dx),%es:(%edi)
80101e0a:	eb 93                	jmp    80101d9f <ideintr+0x2c>

80101e0c <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101e0c:	55                   	push   %ebp
80101e0d:	89 e5                	mov    %esp,%ebp
80101e0f:	53                   	push   %ebx
80101e10:	83 ec 10             	sub    $0x10,%esp
80101e13:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101e16:	8d 43 0c             	lea    0xc(%ebx),%eax
80101e19:	50                   	push   %eax
80101e1a:	e8 b4 1c 00 00       	call   80103ad3 <holdingsleep>
80101e1f:	83 c4 10             	add    $0x10,%esp
80101e22:	85 c0                	test   %eax,%eax
80101e24:	74 37                	je     80101e5d <iderw+0x51>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101e26:	8b 03                	mov    (%ebx),%eax
80101e28:	83 e0 06             	and    $0x6,%eax
80101e2b:	83 f8 02             	cmp    $0x2,%eax
80101e2e:	74 3a                	je     80101e6a <iderw+0x5e>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101e30:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101e34:	74 09                	je     80101e3f <iderw+0x33>
80101e36:	83 3d 60 95 10 80 00 	cmpl   $0x0,0x80109560
80101e3d:	74 38                	je     80101e77 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e3f:	83 ec 0c             	sub    $0xc,%esp
80101e42:	68 80 95 10 80       	push   $0x80109580
80101e47:	e8 11 1e 00 00       	call   80103c5d <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 95 10 80       	mov    $0x80109564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 6a 67 10 80       	push   $0x8010676a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 80 67 10 80       	push   $0x80106780
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 95 67 10 80       	push   $0x80106795
80101e7f:	e8 c4 e4 ff ff       	call   80100348 <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e84:	8d 50 58             	lea    0x58(%eax),%edx
80101e87:	8b 02                	mov    (%edx),%eax
80101e89:	85 c0                	test   %eax,%eax
80101e8b:	75 f7                	jne    80101e84 <iderw+0x78>
    ;
  *pp = b;
80101e8d:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101e8f:	39 1d 64 95 10 80    	cmp    %ebx,0x80109564
80101e95:	75 1a                	jne    80101eb1 <iderw+0xa5>
    idestart(b);
80101e97:	89 d8                	mov    %ebx,%eax
80101e99:	e8 a5 fd ff ff       	call   80101c43 <idestart>
80101e9e:	eb 11                	jmp    80101eb1 <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101ea0:	83 ec 08             	sub    $0x8,%esp
80101ea3:	68 80 95 10 80       	push   $0x80109580
80101ea8:	53                   	push   %ebx
80101ea9:	e8 b4 18 00 00       	call   80103762 <sleep>
80101eae:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101eb1:	8b 03                	mov    (%ebx),%eax
80101eb3:	83 e0 06             	and    $0x6,%eax
80101eb6:	83 f8 02             	cmp    $0x2,%eax
80101eb9:	75 e5                	jne    80101ea0 <iderw+0x94>
  }


  release(&idelock);
80101ebb:	83 ec 0c             	sub    $0xc,%esp
80101ebe:	68 80 95 10 80       	push   $0x80109580
80101ec3:	e8 fa 1d 00 00       	call   80103cc2 <release>
}
80101ec8:	83 c4 10             	add    $0x10,%esp
80101ecb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101ece:	c9                   	leave  
80101ecf:	c3                   	ret    

80101ed0 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80101ed0:	55                   	push   %ebp
80101ed1:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ed3:	8b 15 54 16 11 80    	mov    0x80111654,%edx
80101ed9:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101edb:	a1 54 16 11 80       	mov    0x80111654,%eax
80101ee0:	8b 40 10             	mov    0x10(%eax),%eax
}
80101ee3:	5d                   	pop    %ebp
80101ee4:	c3                   	ret    

80101ee5 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80101ee5:	55                   	push   %ebp
80101ee6:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ee8:	8b 0d 54 16 11 80    	mov    0x80111654,%ecx
80101eee:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101ef0:	a1 54 16 11 80       	mov    0x80111654,%eax
80101ef5:	89 50 10             	mov    %edx,0x10(%eax)
}
80101ef8:	5d                   	pop    %ebp
80101ef9:	c3                   	ret    

80101efa <ioapicinit>:

void
ioapicinit(void)
{
80101efa:	55                   	push   %ebp
80101efb:	89 e5                	mov    %esp,%ebp
80101efd:	57                   	push   %edi
80101efe:	56                   	push   %esi
80101eff:	53                   	push   %ebx
80101f00:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101f03:	c7 05 54 16 11 80 00 	movl   $0xfec00000,0x80111654
80101f0a:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101f0d:	b8 01 00 00 00       	mov    $0x1,%eax
80101f12:	e8 b9 ff ff ff       	call   80101ed0 <ioapicread>
80101f17:	c1 e8 10             	shr    $0x10,%eax
80101f1a:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101f1d:	b8 00 00 00 00       	mov    $0x0,%eax
80101f22:	e8 a9 ff ff ff       	call   80101ed0 <ioapicread>
80101f27:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101f2a:	0f b6 15 a0 17 13 80 	movzbl 0x801317a0,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 b4 67 10 80       	push   $0x801067b4
80101f44:	e8 c2 e6 ff ff       	call   8010060b <cprintf>
80101f49:	83 c4 10             	add    $0x10,%esp
80101f4c:	eb e7                	jmp    80101f35 <ioapicinit+0x3b>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101f4e:	8d 53 20             	lea    0x20(%ebx),%edx
80101f51:	81 ca 00 00 01 00    	or     $0x10000,%edx
80101f57:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80101f5b:	89 f0                	mov    %esi,%eax
80101f5d:	e8 83 ff ff ff       	call   80101ee5 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80101f62:	8d 46 01             	lea    0x1(%esi),%eax
80101f65:	ba 00 00 00 00       	mov    $0x0,%edx
80101f6a:	e8 76 ff ff ff       	call   80101ee5 <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80101f6f:	83 c3 01             	add    $0x1,%ebx
80101f72:	39 fb                	cmp    %edi,%ebx
80101f74:	7e d8                	jle    80101f4e <ioapicinit+0x54>
  }
}
80101f76:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101f79:	5b                   	pop    %ebx
80101f7a:	5e                   	pop    %esi
80101f7b:	5f                   	pop    %edi
80101f7c:	5d                   	pop    %ebp
80101f7d:	c3                   	ret    

80101f7e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80101f7e:	55                   	push   %ebp
80101f7f:	89 e5                	mov    %esp,%ebp
80101f81:	53                   	push   %ebx
80101f82:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80101f85:	8d 50 20             	lea    0x20(%eax),%edx
80101f88:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
80101f8c:	89 d8                	mov    %ebx,%eax
80101f8e:	e8 52 ff ff ff       	call   80101ee5 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80101f93:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f96:	c1 e2 18             	shl    $0x18,%edx
80101f99:	8d 43 01             	lea    0x1(%ebx),%eax
80101f9c:	e8 44 ff ff ff       	call   80101ee5 <ioapicwrite>
}
80101fa1:	5b                   	pop    %ebx
80101fa2:	5d                   	pop    %ebp
80101fa3:	c3                   	ret    

80101fa4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80101fa4:	55                   	push   %ebp
80101fa5:	89 e5                	mov    %esp,%ebp
80101fa7:	53                   	push   %ebx
80101fa8:	83 ec 04             	sub    $0x4,%esp
80101fab:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fae:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101fb4:	75 4c                	jne    80102002 <kfree+0x5e>
80101fb6:	81 fb e8 44 13 80    	cmp    $0x801344e8,%ebx
80101fbc:	72 44                	jb     80102002 <kfree+0x5e>
80101fbe:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80101fc4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80101fc9:	77 37                	ja     80102002 <kfree+0x5e>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fcb:	83 ec 04             	sub    $0x4,%esp
80101fce:	68 00 10 00 00       	push   $0x1000
80101fd3:	6a 01                	push   $0x1
80101fd5:	53                   	push   %ebx
80101fd6:	e8 2e 1d 00 00       	call   80103d09 <memset>

  if(kmem.use_lock)
80101fdb:	83 c4 10             	add    $0x10,%esp
80101fde:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
80101fe5:	75 28                	jne    8010200f <kfree+0x6b>
    acquire(&kmem.lock);
  // insert new freed page at FRONT of freelist
  r = (struct run*)v;
  r->next = kmem.freelist;
80101fe7:	a1 98 16 11 80       	mov    0x80111698,%eax
80101fec:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80101fee:	89 1d 98 16 11 80    	mov    %ebx,0x80111698
  if(kmem.use_lock)
80101ff4:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
80101ffb:	75 24                	jne    80102021 <kfree+0x7d>
    release(&kmem.lock);
}
80101ffd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102000:	c9                   	leave  
80102001:	c3                   	ret    
    panic("kfree");
80102002:	83 ec 0c             	sub    $0xc,%esp
80102005:	68 e6 67 10 80       	push   $0x801067e6
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 60 16 11 80       	push   $0x80111660
80102017:	e8 41 1c 00 00       	call   80103c5d <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 60 16 11 80       	push   $0x80111660
80102029:	e8 94 1c 00 00       	call   80103cc2 <release>
8010202e:	83 c4 10             	add    $0x10,%esp
}
80102031:	eb ca                	jmp    80101ffd <kfree+0x59>

80102033 <freerange>:
{
80102033:	55                   	push   %ebp
80102034:	89 e5                	mov    %esp,%ebp
80102036:	56                   	push   %esi
80102037:	53                   	push   %ebx
80102038:	8b 75 0c             	mov    0xc(%ebp),%esi
  p = (char*)PGROUNDUP((uint)vstart);
8010203b:	8b 45 08             	mov    0x8(%ebp),%eax
8010203e:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80102044:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE*2) // free every OTHER page
8010204a:	eb 12                	jmp    8010205e <freerange+0x2b>
    kfree(p);
8010204c:	83 ec 0c             	sub    $0xc,%esp
8010204f:	53                   	push   %ebx
80102050:	e8 4f ff ff ff       	call   80101fa4 <kfree>
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE*2) // free every OTHER page
80102055:	81 c3 00 20 00 00    	add    $0x2000,%ebx
8010205b:	83 c4 10             	add    $0x10,%esp
8010205e:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
80102064:	39 f0                	cmp    %esi,%eax
80102066:	76 e4                	jbe    8010204c <freerange+0x19>
}
80102068:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010206b:	5b                   	pop    %ebx
8010206c:	5e                   	pop    %esi
8010206d:	5d                   	pop    %ebp
8010206e:	c3                   	ret    

8010206f <kinit1>:
{
8010206f:	55                   	push   %ebp
80102070:	89 e5                	mov    %esp,%ebp
80102072:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
80102075:	68 ec 67 10 80       	push   $0x801067ec
8010207a:	68 60 16 11 80       	push   $0x80111660
8010207f:	e8 9d 1a 00 00       	call   80103b21 <initlock>
  kmem.use_lock = 0;
80102084:	c7 05 94 16 11 80 00 	movl   $0x0,0x80111694
8010208b:	00 00 00 
  freerange(vstart, vend);
8010208e:	83 c4 08             	add    $0x8,%esp
80102091:	ff 75 0c             	pushl  0xc(%ebp)
80102094:	ff 75 08             	pushl  0x8(%ebp)
80102097:	e8 97 ff ff ff       	call   80102033 <freerange>
}
8010209c:	83 c4 10             	add    $0x10,%esp
8010209f:	c9                   	leave  
801020a0:	c3                   	ret    

801020a1 <kinit2>:
{
801020a1:	55                   	push   %ebp
801020a2:	89 e5                	mov    %esp,%ebp
801020a4:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
801020a7:	ff 75 0c             	pushl  0xc(%ebp)
801020aa:	ff 75 08             	pushl  0x8(%ebp)
801020ad:	e8 81 ff ff ff       	call   80102033 <freerange>
  kmem.use_lock = 1;
801020b2:	c7 05 94 16 11 80 01 	movl   $0x1,0x80111694
801020b9:	00 00 00 
  init2Done = 1;
801020bc:	c7 05 b8 95 10 80 01 	movl   $0x1,0x801095b8
801020c3:	00 00 00 
}
801020c6:	83 c4 10             	add    $0x10,%esp
801020c9:	c9                   	leave  
801020ca:	c3                   	ret    

801020cb <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801020cb:	55                   	push   %ebp
801020cc:	89 e5                	mov    %esp,%ebp
801020ce:	53                   	push   %ebx
801020cf:	83 ec 04             	sub    $0x4,%esp
  // PARAM CHANGE: track pid of process calling kalloc
  struct run *r;
//  char* v;
  if(kmem.use_lock)
801020d2:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
801020d9:	75 47                	jne    80102122 <kalloc+0x57>
    acquire(&kmem.lock);
  r = kmem.freelist;  // save next free frame in memory
801020db:	8b 1d 98 16 11 80    	mov    0x80111698,%ebx
  //   // should free frame we just made
  //   kfree(v);  // FIXME: lmao does this work
  //   curPID = pid;
  // }

  if (init2Done) {
801020e1:	83 3d b8 95 10 80 00 	cmpl   $0x0,0x801095b8
801020e8:	74 1d                	je     80102107 <kalloc+0x3c>
    frames[count] = ((V2P(r)) & ~0xFFF) >> 12; // virtual >> physical and mask
801020ea:	8d 93 00 00 00 80    	lea    -0x80000000(%ebx),%edx
801020f0:	a1 bc 95 10 80       	mov    0x801095bc,%eax
801020f5:	c1 ea 0c             	shr    $0xc,%edx
801020f8:	89 14 85 a0 16 11 80 	mov    %edx,-0x7feee960(,%eax,4)
    // cprintf("%d\n", frames[count]);
    count++;
801020ff:	83 c0 01             	add    $0x1,%eax
80102102:	a3 bc 95 10 80       	mov    %eax,0x801095bc
  }
  // return the first free page available in the free list
  if(r)
80102107:	85 db                	test   %ebx,%ebx
80102109:	74 07                	je     80102112 <kalloc+0x47>
    kmem.freelist = r->next;
8010210b:	8b 03                	mov    (%ebx),%eax
8010210d:	a3 98 16 11 80       	mov    %eax,0x80111698
  if(kmem.use_lock)
80102112:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
80102119:	75 19                	jne    80102134 <kalloc+0x69>
    release(&kmem.lock);
  return (char*)r;
}
8010211b:	89 d8                	mov    %ebx,%eax
8010211d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102120:	c9                   	leave  
80102121:	c3                   	ret    
    acquire(&kmem.lock);
80102122:	83 ec 0c             	sub    $0xc,%esp
80102125:	68 60 16 11 80       	push   $0x80111660
8010212a:	e8 2e 1b 00 00       	call   80103c5d <acquire>
8010212f:	83 c4 10             	add    $0x10,%esp
80102132:	eb a7                	jmp    801020db <kalloc+0x10>
    release(&kmem.lock);
80102134:	83 ec 0c             	sub    $0xc,%esp
80102137:	68 60 16 11 80       	push   $0x80111660
8010213c:	e8 81 1b 00 00       	call   80103cc2 <release>
80102141:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
80102144:	eb d5                	jmp    8010211b <kalloc+0x50>

80102146 <dump_physmem>:

int
dump_physmem(int* frame, int* pid, int numframes)
{
80102146:	55                   	push   %ebp
80102147:	89 e5                	mov    %esp,%ebp
80102149:	57                   	push   %edi
8010214a:	56                   	push   %esi
8010214b:	53                   	push   %ebx
8010214c:	8b 7d 08             	mov    0x8(%ebp),%edi
8010214f:	8b 75 10             	mov    0x10(%ebp),%esi
  if (frame == 0 || pid == 0 || numframes < 0) {
80102152:	85 ff                	test   %edi,%edi
80102154:	0f 94 c2             	sete   %dl
80102157:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010215b:	0f 94 c0             	sete   %al
8010215e:	08 c2                	or     %al,%dl
80102160:	75 68                	jne    801021ca <dump_physmem+0x84>
80102162:	85 f6                	test   %esi,%esi
80102164:	78 6b                	js     801021d1 <dump_physmem+0x8b>
    return -1;
  }
  //  int frames[16384];
  //  int pids[16384];
  for (int i = 0; i < numframes; ++i) {
80102166:	b8 00 00 00 00       	mov    $0x0,%eax
8010216b:	eb 13                	jmp    80102180 <dump_physmem+0x3a>
    *(pid + i) = pids[i];
    // set all pids without pids to -2
    if (frames[i] != 0 && pids[i] < 1) {
      *(pid + i) = -2;
    }
    else if (frames[i] == 0) {
8010216d:	85 c9                	test   %ecx,%ecx
8010216f:	75 0c                	jne    8010217d <dump_physmem+0x37>
      // set all unused frames and corresponding pids to -1
      *(frame + i) = -1;
80102171:	c7 03 ff ff ff ff    	movl   $0xffffffff,(%ebx)
      *(pid + i) = -1;
80102177:	c7 02 ff ff ff ff    	movl   $0xffffffff,(%edx)
  for (int i = 0; i < numframes; ++i) {
8010217d:	83 c0 01             	add    $0x1,%eax
80102180:	39 f0                	cmp    %esi,%eax
80102182:	7d 3c                	jge    801021c0 <dump_physmem+0x7a>
    *(frame + i) = frames[i];
80102184:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010218b:	8d 1c 17             	lea    (%edi,%edx,1),%ebx
8010218e:	8b 0c 85 a0 16 11 80 	mov    -0x7feee960(,%eax,4),%ecx
80102195:	89 0b                	mov    %ecx,(%ebx)
    *(pid + i) = pids[i];
80102197:	03 55 0c             	add    0xc(%ebp),%edx
8010219a:	8b 0c 85 a0 16 12 80 	mov    -0x7fede960(,%eax,4),%ecx
801021a1:	89 0a                	mov    %ecx,(%edx)
    if (frames[i] != 0 && pids[i] < 1) {
801021a3:	8b 0c 85 a0 16 11 80 	mov    -0x7feee960(,%eax,4),%ecx
801021aa:	85 c9                	test   %ecx,%ecx
801021ac:	74 bf                	je     8010216d <dump_physmem+0x27>
801021ae:	83 3c 85 a0 16 12 80 	cmpl   $0x0,-0x7fede960(,%eax,4)
801021b5:	00 
801021b6:	7f b5                	jg     8010216d <dump_physmem+0x27>
      *(pid + i) = -2;
801021b8:	c7 02 fe ff ff ff    	movl   $0xfffffffe,(%edx)
801021be:	eb bd                	jmp    8010217d <dump_physmem+0x37>
    }
  }
  return 0;
801021c0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801021c5:	5b                   	pop    %ebx
801021c6:	5e                   	pop    %esi
801021c7:	5f                   	pop    %edi
801021c8:	5d                   	pop    %ebp
801021c9:	c3                   	ret    
    return -1;
801021ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021cf:	eb f4                	jmp    801021c5 <dump_physmem+0x7f>
801021d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021d6:	eb ed                	jmp    801021c5 <dump_physmem+0x7f>

801021d8 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801021d8:	55                   	push   %ebp
801021d9:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801021db:	ba 64 00 00 00       	mov    $0x64,%edx
801021e0:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
801021e1:	a8 01                	test   $0x1,%al
801021e3:	0f 84 b5 00 00 00    	je     8010229e <kbdgetc+0xc6>
801021e9:	ba 60 00 00 00       	mov    $0x60,%edx
801021ee:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
801021ef:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
801021f2:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
801021f8:	74 5c                	je     80102256 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
801021fa:	84 c0                	test   %al,%al
801021fc:	78 66                	js     80102264 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
801021fe:	8b 0d c0 95 10 80    	mov    0x801095c0,%ecx
80102204:	f6 c1 40             	test   $0x40,%cl
80102207:	74 0f                	je     80102218 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102209:	83 c8 80             	or     $0xffffff80,%eax
8010220c:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
8010220f:	83 e1 bf             	and    $0xffffffbf,%ecx
80102212:	89 0d c0 95 10 80    	mov    %ecx,0x801095c0
  }

  shift |= shiftcode[data];
80102218:	0f b6 8a 20 69 10 80 	movzbl -0x7fef96e0(%edx),%ecx
8010221f:	0b 0d c0 95 10 80    	or     0x801095c0,%ecx
  shift ^= togglecode[data];
80102225:	0f b6 82 20 68 10 80 	movzbl -0x7fef97e0(%edx),%eax
8010222c:	31 c1                	xor    %eax,%ecx
8010222e:	89 0d c0 95 10 80    	mov    %ecx,0x801095c0
  c = charcode[shift & (CTL | SHIFT)][data];
80102234:	89 c8                	mov    %ecx,%eax
80102236:	83 e0 03             	and    $0x3,%eax
80102239:	8b 04 85 00 68 10 80 	mov    -0x7fef9800(,%eax,4),%eax
80102240:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
80102244:	f6 c1 08             	test   $0x8,%cl
80102247:	74 19                	je     80102262 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
80102249:	8d 50 9f             	lea    -0x61(%eax),%edx
8010224c:	83 fa 19             	cmp    $0x19,%edx
8010224f:	77 40                	ja     80102291 <kbdgetc+0xb9>
      c += 'A' - 'a';
80102251:	83 e8 20             	sub    $0x20,%eax
80102254:	eb 0c                	jmp    80102262 <kbdgetc+0x8a>
    shift |= E0ESC;
80102256:	83 0d c0 95 10 80 40 	orl    $0x40,0x801095c0
    return 0;
8010225d:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
80102262:	5d                   	pop    %ebp
80102263:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
80102264:	8b 0d c0 95 10 80    	mov    0x801095c0,%ecx
8010226a:	f6 c1 40             	test   $0x40,%cl
8010226d:	75 05                	jne    80102274 <kbdgetc+0x9c>
8010226f:	89 c2                	mov    %eax,%edx
80102271:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
80102274:	0f b6 82 20 69 10 80 	movzbl -0x7fef96e0(%edx),%eax
8010227b:	83 c8 40             	or     $0x40,%eax
8010227e:	0f b6 c0             	movzbl %al,%eax
80102281:	f7 d0                	not    %eax
80102283:	21 c8                	and    %ecx,%eax
80102285:	a3 c0 95 10 80       	mov    %eax,0x801095c0
    return 0;
8010228a:	b8 00 00 00 00       	mov    $0x0,%eax
8010228f:	eb d1                	jmp    80102262 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
80102291:	8d 50 bf             	lea    -0x41(%eax),%edx
80102294:	83 fa 19             	cmp    $0x19,%edx
80102297:	77 c9                	ja     80102262 <kbdgetc+0x8a>
      c += 'a' - 'A';
80102299:	83 c0 20             	add    $0x20,%eax
  return c;
8010229c:	eb c4                	jmp    80102262 <kbdgetc+0x8a>
    return -1;
8010229e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801022a3:	eb bd                	jmp    80102262 <kbdgetc+0x8a>

801022a5 <kbdintr>:

void
kbdintr(void)
{
801022a5:	55                   	push   %ebp
801022a6:	89 e5                	mov    %esp,%ebp
801022a8:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
801022ab:	68 d8 21 10 80       	push   $0x801021d8
801022b0:	e8 89 e4 ff ff       	call   8010073e <consoleintr>
}
801022b5:	83 c4 10             	add    $0x10,%esp
801022b8:	c9                   	leave  
801022b9:	c3                   	ret    

801022ba <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801022ba:	55                   	push   %ebp
801022bb:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801022bd:	8b 0d a0 16 13 80    	mov    0x801316a0,%ecx
801022c3:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801022c6:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
801022c8:	a1 a0 16 13 80       	mov    0x801316a0,%eax
801022cd:	8b 40 20             	mov    0x20(%eax),%eax
}
801022d0:	5d                   	pop    %ebp
801022d1:	c3                   	ret    

801022d2 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
801022d2:	55                   	push   %ebp
801022d3:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801022d5:	ba 70 00 00 00       	mov    $0x70,%edx
801022da:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801022db:	ba 71 00 00 00       	mov    $0x71,%edx
801022e0:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
801022e1:	0f b6 c0             	movzbl %al,%eax
}
801022e4:	5d                   	pop    %ebp
801022e5:	c3                   	ret    

801022e6 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
801022e6:	55                   	push   %ebp
801022e7:	89 e5                	mov    %esp,%ebp
801022e9:	53                   	push   %ebx
801022ea:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
801022ec:	b8 00 00 00 00       	mov    $0x0,%eax
801022f1:	e8 dc ff ff ff       	call   801022d2 <cmos_read>
801022f6:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
801022f8:	b8 02 00 00 00       	mov    $0x2,%eax
801022fd:	e8 d0 ff ff ff       	call   801022d2 <cmos_read>
80102302:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
80102305:	b8 04 00 00 00       	mov    $0x4,%eax
8010230a:	e8 c3 ff ff ff       	call   801022d2 <cmos_read>
8010230f:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102312:	b8 07 00 00 00       	mov    $0x7,%eax
80102317:	e8 b6 ff ff ff       	call   801022d2 <cmos_read>
8010231c:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
8010231f:	b8 08 00 00 00       	mov    $0x8,%eax
80102324:	e8 a9 ff ff ff       	call   801022d2 <cmos_read>
80102329:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
8010232c:	b8 09 00 00 00       	mov    $0x9,%eax
80102331:	e8 9c ff ff ff       	call   801022d2 <cmos_read>
80102336:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102339:	5b                   	pop    %ebx
8010233a:	5d                   	pop    %ebp
8010233b:	c3                   	ret    

8010233c <lapicinit>:
  if(!lapic)
8010233c:	83 3d a0 16 13 80 00 	cmpl   $0x0,0x801316a0
80102343:	0f 84 fb 00 00 00    	je     80102444 <lapicinit+0x108>
{
80102349:	55                   	push   %ebp
8010234a:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010234c:	ba 3f 01 00 00       	mov    $0x13f,%edx
80102351:	b8 3c 00 00 00       	mov    $0x3c,%eax
80102356:	e8 5f ff ff ff       	call   801022ba <lapicw>
  lapicw(TDCR, X1);
8010235b:	ba 0b 00 00 00       	mov    $0xb,%edx
80102360:	b8 f8 00 00 00       	mov    $0xf8,%eax
80102365:	e8 50 ff ff ff       	call   801022ba <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010236a:	ba 20 00 02 00       	mov    $0x20020,%edx
8010236f:	b8 c8 00 00 00       	mov    $0xc8,%eax
80102374:	e8 41 ff ff ff       	call   801022ba <lapicw>
  lapicw(TICR, 10000000);
80102379:	ba 80 96 98 00       	mov    $0x989680,%edx
8010237e:	b8 e0 00 00 00       	mov    $0xe0,%eax
80102383:	e8 32 ff ff ff       	call   801022ba <lapicw>
  lapicw(LINT0, MASKED);
80102388:	ba 00 00 01 00       	mov    $0x10000,%edx
8010238d:	b8 d4 00 00 00       	mov    $0xd4,%eax
80102392:	e8 23 ff ff ff       	call   801022ba <lapicw>
  lapicw(LINT1, MASKED);
80102397:	ba 00 00 01 00       	mov    $0x10000,%edx
8010239c:	b8 d8 00 00 00       	mov    $0xd8,%eax
801023a1:	e8 14 ff ff ff       	call   801022ba <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801023a6:	a1 a0 16 13 80       	mov    0x801316a0,%eax
801023ab:	8b 40 30             	mov    0x30(%eax),%eax
801023ae:	c1 e8 10             	shr    $0x10,%eax
801023b1:	3c 03                	cmp    $0x3,%al
801023b3:	77 7b                	ja     80102430 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801023b5:	ba 33 00 00 00       	mov    $0x33,%edx
801023ba:	b8 dc 00 00 00       	mov    $0xdc,%eax
801023bf:	e8 f6 fe ff ff       	call   801022ba <lapicw>
  lapicw(ESR, 0);
801023c4:	ba 00 00 00 00       	mov    $0x0,%edx
801023c9:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023ce:	e8 e7 fe ff ff       	call   801022ba <lapicw>
  lapicw(ESR, 0);
801023d3:	ba 00 00 00 00       	mov    $0x0,%edx
801023d8:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023dd:	e8 d8 fe ff ff       	call   801022ba <lapicw>
  lapicw(EOI, 0);
801023e2:	ba 00 00 00 00       	mov    $0x0,%edx
801023e7:	b8 2c 00 00 00       	mov    $0x2c,%eax
801023ec:	e8 c9 fe ff ff       	call   801022ba <lapicw>
  lapicw(ICRHI, 0);
801023f1:	ba 00 00 00 00       	mov    $0x0,%edx
801023f6:	b8 c4 00 00 00       	mov    $0xc4,%eax
801023fb:	e8 ba fe ff ff       	call   801022ba <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102400:	ba 00 85 08 00       	mov    $0x88500,%edx
80102405:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010240a:	e8 ab fe ff ff       	call   801022ba <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010240f:	a1 a0 16 13 80       	mov    0x801316a0,%eax
80102414:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
8010241a:	f6 c4 10             	test   $0x10,%ah
8010241d:	75 f0                	jne    8010240f <lapicinit+0xd3>
  lapicw(TPR, 0);
8010241f:	ba 00 00 00 00       	mov    $0x0,%edx
80102424:	b8 20 00 00 00       	mov    $0x20,%eax
80102429:	e8 8c fe ff ff       	call   801022ba <lapicw>
}
8010242e:	5d                   	pop    %ebp
8010242f:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102430:	ba 00 00 01 00       	mov    $0x10000,%edx
80102435:	b8 d0 00 00 00       	mov    $0xd0,%eax
8010243a:	e8 7b fe ff ff       	call   801022ba <lapicw>
8010243f:	e9 71 ff ff ff       	jmp    801023b5 <lapicinit+0x79>
80102444:	f3 c3                	repz ret 

80102446 <lapicid>:
{
80102446:	55                   	push   %ebp
80102447:	89 e5                	mov    %esp,%ebp
  if (!lapic)
80102449:	a1 a0 16 13 80       	mov    0x801316a0,%eax
8010244e:	85 c0                	test   %eax,%eax
80102450:	74 08                	je     8010245a <lapicid+0x14>
  return lapic[ID] >> 24;
80102452:	8b 40 20             	mov    0x20(%eax),%eax
80102455:	c1 e8 18             	shr    $0x18,%eax
}
80102458:	5d                   	pop    %ebp
80102459:	c3                   	ret    
    return 0;
8010245a:	b8 00 00 00 00       	mov    $0x0,%eax
8010245f:	eb f7                	jmp    80102458 <lapicid+0x12>

80102461 <lapiceoi>:
  if(lapic)
80102461:	83 3d a0 16 13 80 00 	cmpl   $0x0,0x801316a0
80102468:	74 14                	je     8010247e <lapiceoi+0x1d>
{
8010246a:	55                   	push   %ebp
8010246b:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
8010246d:	ba 00 00 00 00       	mov    $0x0,%edx
80102472:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102477:	e8 3e fe ff ff       	call   801022ba <lapicw>
}
8010247c:	5d                   	pop    %ebp
8010247d:	c3                   	ret    
8010247e:	f3 c3                	repz ret 

80102480 <microdelay>:
{
80102480:	55                   	push   %ebp
80102481:	89 e5                	mov    %esp,%ebp
}
80102483:	5d                   	pop    %ebp
80102484:	c3                   	ret    

80102485 <lapicstartap>:
{
80102485:	55                   	push   %ebp
80102486:	89 e5                	mov    %esp,%ebp
80102488:	57                   	push   %edi
80102489:	56                   	push   %esi
8010248a:	53                   	push   %ebx
8010248b:	8b 75 08             	mov    0x8(%ebp),%esi
8010248e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102491:	b8 0f 00 00 00       	mov    $0xf,%eax
80102496:	ba 70 00 00 00       	mov    $0x70,%edx
8010249b:	ee                   	out    %al,(%dx)
8010249c:	b8 0a 00 00 00       	mov    $0xa,%eax
801024a1:	ba 71 00 00 00       	mov    $0x71,%edx
801024a6:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801024a7:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
801024ae:	00 00 
  wrv[1] = addr >> 4;
801024b0:	89 f8                	mov    %edi,%eax
801024b2:	c1 e8 04             	shr    $0x4,%eax
801024b5:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
801024bb:	c1 e6 18             	shl    $0x18,%esi
801024be:	89 f2                	mov    %esi,%edx
801024c0:	b8 c4 00 00 00       	mov    $0xc4,%eax
801024c5:	e8 f0 fd ff ff       	call   801022ba <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801024ca:	ba 00 c5 00 00       	mov    $0xc500,%edx
801024cf:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024d4:	e8 e1 fd ff ff       	call   801022ba <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
801024d9:	ba 00 85 00 00       	mov    $0x8500,%edx
801024de:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024e3:	e8 d2 fd ff ff       	call   801022ba <lapicw>
  for(i = 0; i < 2; i++){
801024e8:	bb 00 00 00 00       	mov    $0x0,%ebx
801024ed:	eb 21                	jmp    80102510 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
801024ef:	89 f2                	mov    %esi,%edx
801024f1:	b8 c4 00 00 00       	mov    $0xc4,%eax
801024f6:	e8 bf fd ff ff       	call   801022ba <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801024fb:	89 fa                	mov    %edi,%edx
801024fd:	c1 ea 0c             	shr    $0xc,%edx
80102500:	80 ce 06             	or     $0x6,%dh
80102503:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102508:	e8 ad fd ff ff       	call   801022ba <lapicw>
  for(i = 0; i < 2; i++){
8010250d:	83 c3 01             	add    $0x1,%ebx
80102510:	83 fb 01             	cmp    $0x1,%ebx
80102513:	7e da                	jle    801024ef <lapicstartap+0x6a>
}
80102515:	5b                   	pop    %ebx
80102516:	5e                   	pop    %esi
80102517:	5f                   	pop    %edi
80102518:	5d                   	pop    %ebp
80102519:	c3                   	ret    

8010251a <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
8010251a:	55                   	push   %ebp
8010251b:	89 e5                	mov    %esp,%ebp
8010251d:	57                   	push   %edi
8010251e:	56                   	push   %esi
8010251f:	53                   	push   %ebx
80102520:	83 ec 3c             	sub    $0x3c,%esp
80102523:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80102526:	b8 0b 00 00 00       	mov    $0xb,%eax
8010252b:	e8 a2 fd ff ff       	call   801022d2 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102530:	83 e0 04             	and    $0x4,%eax
80102533:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102535:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102538:	e8 a9 fd ff ff       	call   801022e6 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
8010253d:	b8 0a 00 00 00       	mov    $0xa,%eax
80102542:	e8 8b fd ff ff       	call   801022d2 <cmos_read>
80102547:	a8 80                	test   $0x80,%al
80102549:	75 ea                	jne    80102535 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
8010254b:	8d 5d b8             	lea    -0x48(%ebp),%ebx
8010254e:	89 d8                	mov    %ebx,%eax
80102550:	e8 91 fd ff ff       	call   801022e6 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
80102555:	83 ec 04             	sub    $0x4,%esp
80102558:	6a 18                	push   $0x18
8010255a:	53                   	push   %ebx
8010255b:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010255e:	50                   	push   %eax
8010255f:	e8 eb 17 00 00       	call   80103d4f <memcmp>
80102564:	83 c4 10             	add    $0x10,%esp
80102567:	85 c0                	test   %eax,%eax
80102569:	75 ca                	jne    80102535 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
8010256b:	85 ff                	test   %edi,%edi
8010256d:	0f 85 84 00 00 00    	jne    801025f7 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80102573:	8b 55 d0             	mov    -0x30(%ebp),%edx
80102576:	89 d0                	mov    %edx,%eax
80102578:	c1 e8 04             	shr    $0x4,%eax
8010257b:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010257e:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102581:	83 e2 0f             	and    $0xf,%edx
80102584:	01 d0                	add    %edx,%eax
80102586:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
80102589:	8b 55 d4             	mov    -0x2c(%ebp),%edx
8010258c:	89 d0                	mov    %edx,%eax
8010258e:	c1 e8 04             	shr    $0x4,%eax
80102591:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102594:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102597:	83 e2 0f             	and    $0xf,%edx
8010259a:	01 d0                	add    %edx,%eax
8010259c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
8010259f:	8b 55 d8             	mov    -0x28(%ebp),%edx
801025a2:	89 d0                	mov    %edx,%eax
801025a4:	c1 e8 04             	shr    $0x4,%eax
801025a7:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025aa:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025ad:	83 e2 0f             	and    $0xf,%edx
801025b0:	01 d0                	add    %edx,%eax
801025b2:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
801025b5:	8b 55 dc             	mov    -0x24(%ebp),%edx
801025b8:	89 d0                	mov    %edx,%eax
801025ba:	c1 e8 04             	shr    $0x4,%eax
801025bd:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025c0:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025c3:	83 e2 0f             	and    $0xf,%edx
801025c6:	01 d0                	add    %edx,%eax
801025c8:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
801025cb:	8b 55 e0             	mov    -0x20(%ebp),%edx
801025ce:	89 d0                	mov    %edx,%eax
801025d0:	c1 e8 04             	shr    $0x4,%eax
801025d3:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025d6:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025d9:	83 e2 0f             	and    $0xf,%edx
801025dc:	01 d0                	add    %edx,%eax
801025de:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
801025e1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801025e4:	89 d0                	mov    %edx,%eax
801025e6:	c1 e8 04             	shr    $0x4,%eax
801025e9:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025ec:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025ef:	83 e2 0f             	and    $0xf,%edx
801025f2:	01 d0                	add    %edx,%eax
801025f4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
801025f7:	8b 45 d0             	mov    -0x30(%ebp),%eax
801025fa:	89 06                	mov    %eax,(%esi)
801025fc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801025ff:	89 46 04             	mov    %eax,0x4(%esi)
80102602:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102605:	89 46 08             	mov    %eax,0x8(%esi)
80102608:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010260b:	89 46 0c             	mov    %eax,0xc(%esi)
8010260e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102611:	89 46 10             	mov    %eax,0x10(%esi)
80102614:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102617:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
8010261a:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102621:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102624:	5b                   	pop    %ebx
80102625:	5e                   	pop    %esi
80102626:	5f                   	pop    %edi
80102627:	5d                   	pop    %ebp
80102628:	c3                   	ret    

80102629 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80102629:	55                   	push   %ebp
8010262a:	89 e5                	mov    %esp,%ebp
8010262c:	53                   	push   %ebx
8010262d:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102630:	ff 35 f4 16 13 80    	pushl  0x801316f4
80102636:	ff 35 04 17 13 80    	pushl  0x80131704
8010263c:	e8 2b db ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102641:	8b 58 5c             	mov    0x5c(%eax),%ebx
80102644:	89 1d 08 17 13 80    	mov    %ebx,0x80131708
  for (i = 0; i < log.lh.n; i++) {
8010264a:	83 c4 10             	add    $0x10,%esp
8010264d:	ba 00 00 00 00       	mov    $0x0,%edx
80102652:	eb 0e                	jmp    80102662 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
80102654:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
80102658:	89 0c 95 0c 17 13 80 	mov    %ecx,-0x7fece8f4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
8010265f:	83 c2 01             	add    $0x1,%edx
80102662:	39 d3                	cmp    %edx,%ebx
80102664:	7f ee                	jg     80102654 <read_head+0x2b>
  }
  brelse(buf);
80102666:	83 ec 0c             	sub    $0xc,%esp
80102669:	50                   	push   %eax
8010266a:	e8 66 db ff ff       	call   801001d5 <brelse>
}
8010266f:	83 c4 10             	add    $0x10,%esp
80102672:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102675:	c9                   	leave  
80102676:	c3                   	ret    

80102677 <install_trans>:
{
80102677:	55                   	push   %ebp
80102678:	89 e5                	mov    %esp,%ebp
8010267a:	57                   	push   %edi
8010267b:	56                   	push   %esi
8010267c:	53                   	push   %ebx
8010267d:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102680:	bb 00 00 00 00       	mov    $0x0,%ebx
80102685:	eb 66                	jmp    801026ed <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80102687:	89 d8                	mov    %ebx,%eax
80102689:	03 05 f4 16 13 80    	add    0x801316f4,%eax
8010268f:	83 c0 01             	add    $0x1,%eax
80102692:	83 ec 08             	sub    $0x8,%esp
80102695:	50                   	push   %eax
80102696:	ff 35 04 17 13 80    	pushl  0x80131704
8010269c:	e8 cb da ff ff       	call   8010016c <bread>
801026a1:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801026a3:	83 c4 08             	add    $0x8,%esp
801026a6:	ff 34 9d 0c 17 13 80 	pushl  -0x7fece8f4(,%ebx,4)
801026ad:	ff 35 04 17 13 80    	pushl  0x80131704
801026b3:	e8 b4 da ff ff       	call   8010016c <bread>
801026b8:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801026ba:	8d 57 5c             	lea    0x5c(%edi),%edx
801026bd:	8d 40 5c             	lea    0x5c(%eax),%eax
801026c0:	83 c4 0c             	add    $0xc,%esp
801026c3:	68 00 02 00 00       	push   $0x200
801026c8:	52                   	push   %edx
801026c9:	50                   	push   %eax
801026ca:	e8 b5 16 00 00       	call   80103d84 <memmove>
    bwrite(dbuf);  // write dst to disk
801026cf:	89 34 24             	mov    %esi,(%esp)
801026d2:	e8 c3 da ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
801026d7:	89 3c 24             	mov    %edi,(%esp)
801026da:	e8 f6 da ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
801026df:	89 34 24             	mov    %esi,(%esp)
801026e2:	e8 ee da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801026e7:	83 c3 01             	add    $0x1,%ebx
801026ea:	83 c4 10             	add    $0x10,%esp
801026ed:	39 1d 08 17 13 80    	cmp    %ebx,0x80131708
801026f3:	7f 92                	jg     80102687 <install_trans+0x10>
}
801026f5:	8d 65 f4             	lea    -0xc(%ebp),%esp
801026f8:	5b                   	pop    %ebx
801026f9:	5e                   	pop    %esi
801026fa:	5f                   	pop    %edi
801026fb:	5d                   	pop    %ebp
801026fc:	c3                   	ret    

801026fd <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801026fd:	55                   	push   %ebp
801026fe:	89 e5                	mov    %esp,%ebp
80102700:	53                   	push   %ebx
80102701:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102704:	ff 35 f4 16 13 80    	pushl  0x801316f4
8010270a:	ff 35 04 17 13 80    	pushl  0x80131704
80102710:	e8 57 da ff ff       	call   8010016c <bread>
80102715:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
80102717:	8b 0d 08 17 13 80    	mov    0x80131708,%ecx
8010271d:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102720:	83 c4 10             	add    $0x10,%esp
80102723:	b8 00 00 00 00       	mov    $0x0,%eax
80102728:	eb 0e                	jmp    80102738 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
8010272a:	8b 14 85 0c 17 13 80 	mov    -0x7fece8f4(,%eax,4),%edx
80102731:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
80102735:	83 c0 01             	add    $0x1,%eax
80102738:	39 c1                	cmp    %eax,%ecx
8010273a:	7f ee                	jg     8010272a <write_head+0x2d>
  }
  bwrite(buf);
8010273c:	83 ec 0c             	sub    $0xc,%esp
8010273f:	53                   	push   %ebx
80102740:	e8 55 da ff ff       	call   8010019a <bwrite>
  brelse(buf);
80102745:	89 1c 24             	mov    %ebx,(%esp)
80102748:	e8 88 da ff ff       	call   801001d5 <brelse>
}
8010274d:	83 c4 10             	add    $0x10,%esp
80102750:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102753:	c9                   	leave  
80102754:	c3                   	ret    

80102755 <recover_from_log>:

static void
recover_from_log(void)
{
80102755:	55                   	push   %ebp
80102756:	89 e5                	mov    %esp,%ebp
80102758:	83 ec 08             	sub    $0x8,%esp
  read_head();
8010275b:	e8 c9 fe ff ff       	call   80102629 <read_head>
  install_trans(); // if committed, copy from log to disk
80102760:	e8 12 ff ff ff       	call   80102677 <install_trans>
  log.lh.n = 0;
80102765:	c7 05 08 17 13 80 00 	movl   $0x0,0x80131708
8010276c:	00 00 00 
  write_head(); // clear the log
8010276f:	e8 89 ff ff ff       	call   801026fd <write_head>
}
80102774:	c9                   	leave  
80102775:	c3                   	ret    

80102776 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80102776:	55                   	push   %ebp
80102777:	89 e5                	mov    %esp,%ebp
80102779:	57                   	push   %edi
8010277a:	56                   	push   %esi
8010277b:	53                   	push   %ebx
8010277c:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010277f:	bb 00 00 00 00       	mov    $0x0,%ebx
80102784:	eb 66                	jmp    801027ec <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80102786:	89 d8                	mov    %ebx,%eax
80102788:	03 05 f4 16 13 80    	add    0x801316f4,%eax
8010278e:	83 c0 01             	add    $0x1,%eax
80102791:	83 ec 08             	sub    $0x8,%esp
80102794:	50                   	push   %eax
80102795:	ff 35 04 17 13 80    	pushl  0x80131704
8010279b:	e8 cc d9 ff ff       	call   8010016c <bread>
801027a0:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801027a2:	83 c4 08             	add    $0x8,%esp
801027a5:	ff 34 9d 0c 17 13 80 	pushl  -0x7fece8f4(,%ebx,4)
801027ac:	ff 35 04 17 13 80    	pushl  0x80131704
801027b2:	e8 b5 d9 ff ff       	call   8010016c <bread>
801027b7:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
801027b9:	8d 50 5c             	lea    0x5c(%eax),%edx
801027bc:	8d 46 5c             	lea    0x5c(%esi),%eax
801027bf:	83 c4 0c             	add    $0xc,%esp
801027c2:	68 00 02 00 00       	push   $0x200
801027c7:	52                   	push   %edx
801027c8:	50                   	push   %eax
801027c9:	e8 b6 15 00 00       	call   80103d84 <memmove>
    bwrite(to);  // write the log
801027ce:	89 34 24             	mov    %esi,(%esp)
801027d1:	e8 c4 d9 ff ff       	call   8010019a <bwrite>
    brelse(from);
801027d6:	89 3c 24             	mov    %edi,(%esp)
801027d9:	e8 f7 d9 ff ff       	call   801001d5 <brelse>
    brelse(to);
801027de:	89 34 24             	mov    %esi,(%esp)
801027e1:	e8 ef d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801027e6:	83 c3 01             	add    $0x1,%ebx
801027e9:	83 c4 10             	add    $0x10,%esp
801027ec:	39 1d 08 17 13 80    	cmp    %ebx,0x80131708
801027f2:	7f 92                	jg     80102786 <write_log+0x10>
  }
}
801027f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
801027f7:	5b                   	pop    %ebx
801027f8:	5e                   	pop    %esi
801027f9:	5f                   	pop    %edi
801027fa:	5d                   	pop    %ebp
801027fb:	c3                   	ret    

801027fc <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
801027fc:	83 3d 08 17 13 80 00 	cmpl   $0x0,0x80131708
80102803:	7e 26                	jle    8010282b <commit+0x2f>
{
80102805:	55                   	push   %ebp
80102806:	89 e5                	mov    %esp,%ebp
80102808:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
8010280b:	e8 66 ff ff ff       	call   80102776 <write_log>
    write_head();    // Write header to disk -- the real commit
80102810:	e8 e8 fe ff ff       	call   801026fd <write_head>
    install_trans(); // Now install writes to home locations
80102815:	e8 5d fe ff ff       	call   80102677 <install_trans>
    log.lh.n = 0;
8010281a:	c7 05 08 17 13 80 00 	movl   $0x0,0x80131708
80102821:	00 00 00 
    write_head();    // Erase the transaction from the log
80102824:	e8 d4 fe ff ff       	call   801026fd <write_head>
  }
}
80102829:	c9                   	leave  
8010282a:	c3                   	ret    
8010282b:	f3 c3                	repz ret 

8010282d <initlog>:
{
8010282d:	55                   	push   %ebp
8010282e:	89 e5                	mov    %esp,%ebp
80102830:	53                   	push   %ebx
80102831:	83 ec 2c             	sub    $0x2c,%esp
80102834:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
80102837:	68 20 6a 10 80       	push   $0x80106a20
8010283c:	68 c0 16 13 80       	push   $0x801316c0
80102841:	e8 db 12 00 00       	call   80103b21 <initlock>
  readsb(dev, &sb);
80102846:	83 c4 08             	add    $0x8,%esp
80102849:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010284c:	50                   	push   %eax
8010284d:	53                   	push   %ebx
8010284e:	e8 e3 e9 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
80102853:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102856:	a3 f4 16 13 80       	mov    %eax,0x801316f4
  log.size = sb.nlog;
8010285b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010285e:	a3 f8 16 13 80       	mov    %eax,0x801316f8
  log.dev = dev;
80102863:	89 1d 04 17 13 80    	mov    %ebx,0x80131704
  recover_from_log();
80102869:	e8 e7 fe ff ff       	call   80102755 <recover_from_log>
}
8010286e:	83 c4 10             	add    $0x10,%esp
80102871:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102874:	c9                   	leave  
80102875:	c3                   	ret    

80102876 <begin_op>:
{
80102876:	55                   	push   %ebp
80102877:	89 e5                	mov    %esp,%ebp
80102879:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
8010287c:	68 c0 16 13 80       	push   $0x801316c0
80102881:	e8 d7 13 00 00       	call   80103c5d <acquire>
80102886:	83 c4 10             	add    $0x10,%esp
80102889:	eb 15                	jmp    801028a0 <begin_op+0x2a>
      sleep(&log, &log.lock);
8010288b:	83 ec 08             	sub    $0x8,%esp
8010288e:	68 c0 16 13 80       	push   $0x801316c0
80102893:	68 c0 16 13 80       	push   $0x801316c0
80102898:	e8 c5 0e 00 00       	call   80103762 <sleep>
8010289d:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
801028a0:	83 3d 00 17 13 80 00 	cmpl   $0x0,0x80131700
801028a7:	75 e2                	jne    8010288b <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
801028a9:	a1 fc 16 13 80       	mov    0x801316fc,%eax
801028ae:	83 c0 01             	add    $0x1,%eax
801028b1:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801028b4:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
801028b7:	03 15 08 17 13 80    	add    0x80131708,%edx
801028bd:	83 fa 1e             	cmp    $0x1e,%edx
801028c0:	7e 17                	jle    801028d9 <begin_op+0x63>
      sleep(&log, &log.lock);
801028c2:	83 ec 08             	sub    $0x8,%esp
801028c5:	68 c0 16 13 80       	push   $0x801316c0
801028ca:	68 c0 16 13 80       	push   $0x801316c0
801028cf:	e8 8e 0e 00 00       	call   80103762 <sleep>
801028d4:	83 c4 10             	add    $0x10,%esp
801028d7:	eb c7                	jmp    801028a0 <begin_op+0x2a>
      log.outstanding += 1;
801028d9:	a3 fc 16 13 80       	mov    %eax,0x801316fc
      release(&log.lock);
801028de:	83 ec 0c             	sub    $0xc,%esp
801028e1:	68 c0 16 13 80       	push   $0x801316c0
801028e6:	e8 d7 13 00 00       	call   80103cc2 <release>
}
801028eb:	83 c4 10             	add    $0x10,%esp
801028ee:	c9                   	leave  
801028ef:	c3                   	ret    

801028f0 <end_op>:
{
801028f0:	55                   	push   %ebp
801028f1:	89 e5                	mov    %esp,%ebp
801028f3:	53                   	push   %ebx
801028f4:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
801028f7:	68 c0 16 13 80       	push   $0x801316c0
801028fc:	e8 5c 13 00 00       	call   80103c5d <acquire>
  log.outstanding -= 1;
80102901:	a1 fc 16 13 80       	mov    0x801316fc,%eax
80102906:	83 e8 01             	sub    $0x1,%eax
80102909:	a3 fc 16 13 80       	mov    %eax,0x801316fc
  if(log.committing)
8010290e:	8b 1d 00 17 13 80    	mov    0x80131700,%ebx
80102914:	83 c4 10             	add    $0x10,%esp
80102917:	85 db                	test   %ebx,%ebx
80102919:	75 2c                	jne    80102947 <end_op+0x57>
  if(log.outstanding == 0){
8010291b:	85 c0                	test   %eax,%eax
8010291d:	75 35                	jne    80102954 <end_op+0x64>
    log.committing = 1;
8010291f:	c7 05 00 17 13 80 01 	movl   $0x1,0x80131700
80102926:	00 00 00 
    do_commit = 1;
80102929:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
8010292e:	83 ec 0c             	sub    $0xc,%esp
80102931:	68 c0 16 13 80       	push   $0x801316c0
80102936:	e8 87 13 00 00       	call   80103cc2 <release>
  if(do_commit){
8010293b:	83 c4 10             	add    $0x10,%esp
8010293e:	85 db                	test   %ebx,%ebx
80102940:	75 24                	jne    80102966 <end_op+0x76>
}
80102942:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102945:	c9                   	leave  
80102946:	c3                   	ret    
    panic("log.committing");
80102947:	83 ec 0c             	sub    $0xc,%esp
8010294a:	68 24 6a 10 80       	push   $0x80106a24
8010294f:	e8 f4 d9 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102954:	83 ec 0c             	sub    $0xc,%esp
80102957:	68 c0 16 13 80       	push   $0x801316c0
8010295c:	e8 66 0f 00 00       	call   801038c7 <wakeup>
80102961:	83 c4 10             	add    $0x10,%esp
80102964:	eb c8                	jmp    8010292e <end_op+0x3e>
    commit();
80102966:	e8 91 fe ff ff       	call   801027fc <commit>
    acquire(&log.lock);
8010296b:	83 ec 0c             	sub    $0xc,%esp
8010296e:	68 c0 16 13 80       	push   $0x801316c0
80102973:	e8 e5 12 00 00       	call   80103c5d <acquire>
    log.committing = 0;
80102978:	c7 05 00 17 13 80 00 	movl   $0x0,0x80131700
8010297f:	00 00 00 
    wakeup(&log);
80102982:	c7 04 24 c0 16 13 80 	movl   $0x801316c0,(%esp)
80102989:	e8 39 0f 00 00       	call   801038c7 <wakeup>
    release(&log.lock);
8010298e:	c7 04 24 c0 16 13 80 	movl   $0x801316c0,(%esp)
80102995:	e8 28 13 00 00       	call   80103cc2 <release>
8010299a:	83 c4 10             	add    $0x10,%esp
}
8010299d:	eb a3                	jmp    80102942 <end_op+0x52>

8010299f <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
8010299f:	55                   	push   %ebp
801029a0:	89 e5                	mov    %esp,%ebp
801029a2:	53                   	push   %ebx
801029a3:	83 ec 04             	sub    $0x4,%esp
801029a6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801029a9:	8b 15 08 17 13 80    	mov    0x80131708,%edx
801029af:	83 fa 1d             	cmp    $0x1d,%edx
801029b2:	7f 45                	jg     801029f9 <log_write+0x5a>
801029b4:	a1 f8 16 13 80       	mov    0x801316f8,%eax
801029b9:	83 e8 01             	sub    $0x1,%eax
801029bc:	39 c2                	cmp    %eax,%edx
801029be:	7d 39                	jge    801029f9 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
801029c0:	83 3d fc 16 13 80 00 	cmpl   $0x0,0x801316fc
801029c7:	7e 3d                	jle    80102a06 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
801029c9:	83 ec 0c             	sub    $0xc,%esp
801029cc:	68 c0 16 13 80       	push   $0x801316c0
801029d1:	e8 87 12 00 00       	call   80103c5d <acquire>
  for (i = 0; i < log.lh.n; i++) {
801029d6:	83 c4 10             	add    $0x10,%esp
801029d9:	b8 00 00 00 00       	mov    $0x0,%eax
801029de:	8b 15 08 17 13 80    	mov    0x80131708,%edx
801029e4:	39 c2                	cmp    %eax,%edx
801029e6:	7e 2b                	jle    80102a13 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
801029e8:	8b 4b 08             	mov    0x8(%ebx),%ecx
801029eb:	39 0c 85 0c 17 13 80 	cmp    %ecx,-0x7fece8f4(,%eax,4)
801029f2:	74 1f                	je     80102a13 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
801029f4:	83 c0 01             	add    $0x1,%eax
801029f7:	eb e5                	jmp    801029de <log_write+0x3f>
    panic("too big a transaction");
801029f9:	83 ec 0c             	sub    $0xc,%esp
801029fc:	68 33 6a 10 80       	push   $0x80106a33
80102a01:	e8 42 d9 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102a06:	83 ec 0c             	sub    $0xc,%esp
80102a09:	68 49 6a 10 80       	push   $0x80106a49
80102a0e:	e8 35 d9 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102a13:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a16:	89 0c 85 0c 17 13 80 	mov    %ecx,-0x7fece8f4(,%eax,4)
  if (i == log.lh.n)
80102a1d:	39 c2                	cmp    %eax,%edx
80102a1f:	74 18                	je     80102a39 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102a21:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102a24:	83 ec 0c             	sub    $0xc,%esp
80102a27:	68 c0 16 13 80       	push   $0x801316c0
80102a2c:	e8 91 12 00 00       	call   80103cc2 <release>
}
80102a31:	83 c4 10             	add    $0x10,%esp
80102a34:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a37:	c9                   	leave  
80102a38:	c3                   	ret    
    log.lh.n++;
80102a39:	83 c2 01             	add    $0x1,%edx
80102a3c:	89 15 08 17 13 80    	mov    %edx,0x80131708
80102a42:	eb dd                	jmp    80102a21 <log_write+0x82>

80102a44 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102a44:	55                   	push   %ebp
80102a45:	89 e5                	mov    %esp,%ebp
80102a47:	53                   	push   %ebx
80102a48:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102a4b:	68 8a 00 00 00       	push   $0x8a
80102a50:	68 8c 94 10 80       	push   $0x8010948c
80102a55:	68 00 70 00 80       	push   $0x80007000
80102a5a:	e8 25 13 00 00       	call   80103d84 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102a5f:	83 c4 10             	add    $0x10,%esp
80102a62:	bb c0 17 13 80       	mov    $0x801317c0,%ebx
80102a67:	eb 06                	jmp    80102a6f <startothers+0x2b>
80102a69:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102a6f:	69 05 40 1d 13 80 b0 	imul   $0xb0,0x80131d40,%eax
80102a76:	00 00 00 
80102a79:	05 c0 17 13 80       	add    $0x801317c0,%eax
80102a7e:	39 d8                	cmp    %ebx,%eax
80102a80:	76 4c                	jbe    80102ace <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102a82:	e8 c0 07 00 00       	call   80103247 <mycpu>
80102a87:	39 d8                	cmp    %ebx,%eax
80102a89:	74 de                	je     80102a69 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102a8b:	e8 3b f6 ff ff       	call   801020cb <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102a90:	05 00 10 00 00       	add    $0x1000,%eax
80102a95:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102a9a:	c7 05 f8 6f 00 80 12 	movl   $0x80102b12,0x80006ff8
80102aa1:	2b 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102aa4:	c7 05 f4 6f 00 80 00 	movl   $0x108000,0x80006ff4
80102aab:	80 10 00 

    lapicstartap(c->apicid, V2P(code));
80102aae:	83 ec 08             	sub    $0x8,%esp
80102ab1:	68 00 70 00 00       	push   $0x7000
80102ab6:	0f b6 03             	movzbl (%ebx),%eax
80102ab9:	50                   	push   %eax
80102aba:	e8 c6 f9 ff ff       	call   80102485 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102abf:	83 c4 10             	add    $0x10,%esp
80102ac2:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102ac8:	85 c0                	test   %eax,%eax
80102aca:	74 f6                	je     80102ac2 <startothers+0x7e>
80102acc:	eb 9b                	jmp    80102a69 <startothers+0x25>
      ;
  }
}
80102ace:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102ad1:	c9                   	leave  
80102ad2:	c3                   	ret    

80102ad3 <mpmain>:
{
80102ad3:	55                   	push   %ebp
80102ad4:	89 e5                	mov    %esp,%ebp
80102ad6:	53                   	push   %ebx
80102ad7:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102ada:	e8 c4 07 00 00       	call   801032a3 <cpuid>
80102adf:	89 c3                	mov    %eax,%ebx
80102ae1:	e8 bd 07 00 00       	call   801032a3 <cpuid>
80102ae6:	83 ec 04             	sub    $0x4,%esp
80102ae9:	53                   	push   %ebx
80102aea:	50                   	push   %eax
80102aeb:	68 64 6a 10 80       	push   $0x80106a64
80102af0:	e8 16 db ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102af5:	e8 f9 23 00 00       	call   80104ef3 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102afa:	e8 48 07 00 00       	call   80103247 <mycpu>
80102aff:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102b01:	b8 01 00 00 00       	mov    $0x1,%eax
80102b06:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102b0d:	e8 2b 0a 00 00       	call   8010353d <scheduler>

80102b12 <mpenter>:
{
80102b12:	55                   	push   %ebp
80102b13:	89 e5                	mov    %esp,%ebp
80102b15:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102b18:	e8 df 33 00 00       	call   80105efc <switchkvm>
  seginit();
80102b1d:	e8 8e 32 00 00       	call   80105db0 <seginit>
  lapicinit();
80102b22:	e8 15 f8 ff ff       	call   8010233c <lapicinit>
  mpmain();
80102b27:	e8 a7 ff ff ff       	call   80102ad3 <mpmain>

80102b2c <main>:
{
80102b2c:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102b30:	83 e4 f0             	and    $0xfffffff0,%esp
80102b33:	ff 71 fc             	pushl  -0x4(%ecx)
80102b36:	55                   	push   %ebp
80102b37:	89 e5                	mov    %esp,%ebp
80102b39:	51                   	push   %ecx
80102b3a:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102b3d:	68 00 00 40 80       	push   $0x80400000
80102b42:	68 e8 44 13 80       	push   $0x801344e8
80102b47:	e8 23 f5 ff ff       	call   8010206f <kinit1>
  kvmalloc();      // kernel page table
80102b4c:	e8 38 38 00 00       	call   80106389 <kvmalloc>
  mpinit();        // detect other processors
80102b51:	e8 c9 01 00 00       	call   80102d1f <mpinit>
  lapicinit();     // interrupt controller
80102b56:	e8 e1 f7 ff ff       	call   8010233c <lapicinit>
  seginit();       // segment descriptors
80102b5b:	e8 50 32 00 00       	call   80105db0 <seginit>
  picinit();       // disable pic
80102b60:	e8 82 02 00 00       	call   80102de7 <picinit>
  ioapicinit();    // another interrupt controller
80102b65:	e8 90 f3 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102b6a:	e8 1f dd ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102b6f:	e8 2d 26 00 00       	call   801051a1 <uartinit>
  pinit();         // process table
80102b74:	e8 b4 06 00 00       	call   8010322d <pinit>
  tvinit();        // trap vectors
80102b79:	e8 c4 22 00 00       	call   80104e42 <tvinit>
  binit();         // buffer cache
80102b7e:	e8 71 d5 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102b83:	e8 8b e0 ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102b88:	e8 73 f1 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102b8d:	e8 b2 fe ff ff       	call   80102a44 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102b92:	83 c4 08             	add    $0x8,%esp
80102b95:	68 00 00 00 8e       	push   $0x8e000000
80102b9a:	68 00 00 40 80       	push   $0x80400000
80102b9f:	e8 fd f4 ff ff       	call   801020a1 <kinit2>
  userinit();      // first user process
80102ba4:	e8 39 07 00 00       	call   801032e2 <userinit>
  mpmain();        // finish this processor's setup
80102ba9:	e8 25 ff ff ff       	call   80102ad3 <mpmain>

80102bae <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102bae:	55                   	push   %ebp
80102baf:	89 e5                	mov    %esp,%ebp
80102bb1:	56                   	push   %esi
80102bb2:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102bb3:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102bb8:	b9 00 00 00 00       	mov    $0x0,%ecx
80102bbd:	eb 09                	jmp    80102bc8 <sum+0x1a>
    sum += addr[i];
80102bbf:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102bc3:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102bc5:	83 c1 01             	add    $0x1,%ecx
80102bc8:	39 d1                	cmp    %edx,%ecx
80102bca:	7c f3                	jl     80102bbf <sum+0x11>
  return sum;
}
80102bcc:	89 d8                	mov    %ebx,%eax
80102bce:	5b                   	pop    %ebx
80102bcf:	5e                   	pop    %esi
80102bd0:	5d                   	pop    %ebp
80102bd1:	c3                   	ret    

80102bd2 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102bd2:	55                   	push   %ebp
80102bd3:	89 e5                	mov    %esp,%ebp
80102bd5:	56                   	push   %esi
80102bd6:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102bd7:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102bdd:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102bdf:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102be1:	eb 03                	jmp    80102be6 <mpsearch1+0x14>
80102be3:	83 c3 10             	add    $0x10,%ebx
80102be6:	39 f3                	cmp    %esi,%ebx
80102be8:	73 29                	jae    80102c13 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102bea:	83 ec 04             	sub    $0x4,%esp
80102bed:	6a 04                	push   $0x4
80102bef:	68 78 6a 10 80       	push   $0x80106a78
80102bf4:	53                   	push   %ebx
80102bf5:	e8 55 11 00 00       	call   80103d4f <memcmp>
80102bfa:	83 c4 10             	add    $0x10,%esp
80102bfd:	85 c0                	test   %eax,%eax
80102bff:	75 e2                	jne    80102be3 <mpsearch1+0x11>
80102c01:	ba 10 00 00 00       	mov    $0x10,%edx
80102c06:	89 d8                	mov    %ebx,%eax
80102c08:	e8 a1 ff ff ff       	call   80102bae <sum>
80102c0d:	84 c0                	test   %al,%al
80102c0f:	75 d2                	jne    80102be3 <mpsearch1+0x11>
80102c11:	eb 05                	jmp    80102c18 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102c13:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102c18:	89 d8                	mov    %ebx,%eax
80102c1a:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102c1d:	5b                   	pop    %ebx
80102c1e:	5e                   	pop    %esi
80102c1f:	5d                   	pop    %ebp
80102c20:	c3                   	ret    

80102c21 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102c21:	55                   	push   %ebp
80102c22:	89 e5                	mov    %esp,%ebp
80102c24:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102c27:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102c2e:	c1 e0 08             	shl    $0x8,%eax
80102c31:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102c38:	09 d0                	or     %edx,%eax
80102c3a:	c1 e0 04             	shl    $0x4,%eax
80102c3d:	85 c0                	test   %eax,%eax
80102c3f:	74 1f                	je     80102c60 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102c41:	ba 00 04 00 00       	mov    $0x400,%edx
80102c46:	e8 87 ff ff ff       	call   80102bd2 <mpsearch1>
80102c4b:	85 c0                	test   %eax,%eax
80102c4d:	75 0f                	jne    80102c5e <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102c4f:	ba 00 00 01 00       	mov    $0x10000,%edx
80102c54:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102c59:	e8 74 ff ff ff       	call   80102bd2 <mpsearch1>
}
80102c5e:	c9                   	leave  
80102c5f:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102c60:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102c67:	c1 e0 08             	shl    $0x8,%eax
80102c6a:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102c71:	09 d0                	or     %edx,%eax
80102c73:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102c76:	2d 00 04 00 00       	sub    $0x400,%eax
80102c7b:	ba 00 04 00 00       	mov    $0x400,%edx
80102c80:	e8 4d ff ff ff       	call   80102bd2 <mpsearch1>
80102c85:	85 c0                	test   %eax,%eax
80102c87:	75 d5                	jne    80102c5e <mpsearch+0x3d>
80102c89:	eb c4                	jmp    80102c4f <mpsearch+0x2e>

80102c8b <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102c8b:	55                   	push   %ebp
80102c8c:	89 e5                	mov    %esp,%ebp
80102c8e:	57                   	push   %edi
80102c8f:	56                   	push   %esi
80102c90:	53                   	push   %ebx
80102c91:	83 ec 1c             	sub    $0x1c,%esp
80102c94:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102c97:	e8 85 ff ff ff       	call   80102c21 <mpsearch>
80102c9c:	85 c0                	test   %eax,%eax
80102c9e:	74 5c                	je     80102cfc <mpconfig+0x71>
80102ca0:	89 c7                	mov    %eax,%edi
80102ca2:	8b 58 04             	mov    0x4(%eax),%ebx
80102ca5:	85 db                	test   %ebx,%ebx
80102ca7:	74 5a                	je     80102d03 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102ca9:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102caf:	83 ec 04             	sub    $0x4,%esp
80102cb2:	6a 04                	push   $0x4
80102cb4:	68 7d 6a 10 80       	push   $0x80106a7d
80102cb9:	56                   	push   %esi
80102cba:	e8 90 10 00 00       	call   80103d4f <memcmp>
80102cbf:	83 c4 10             	add    $0x10,%esp
80102cc2:	85 c0                	test   %eax,%eax
80102cc4:	75 44                	jne    80102d0a <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102cc6:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102ccd:	3c 01                	cmp    $0x1,%al
80102ccf:	0f 95 c2             	setne  %dl
80102cd2:	3c 04                	cmp    $0x4,%al
80102cd4:	0f 95 c0             	setne  %al
80102cd7:	84 c2                	test   %al,%dl
80102cd9:	75 36                	jne    80102d11 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102cdb:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102ce2:	89 f0                	mov    %esi,%eax
80102ce4:	e8 c5 fe ff ff       	call   80102bae <sum>
80102ce9:	84 c0                	test   %al,%al
80102ceb:	75 2b                	jne    80102d18 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102ced:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102cf0:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102cf2:	89 f0                	mov    %esi,%eax
80102cf4:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102cf7:	5b                   	pop    %ebx
80102cf8:	5e                   	pop    %esi
80102cf9:	5f                   	pop    %edi
80102cfa:	5d                   	pop    %ebp
80102cfb:	c3                   	ret    
    return 0;
80102cfc:	be 00 00 00 00       	mov    $0x0,%esi
80102d01:	eb ef                	jmp    80102cf2 <mpconfig+0x67>
80102d03:	be 00 00 00 00       	mov    $0x0,%esi
80102d08:	eb e8                	jmp    80102cf2 <mpconfig+0x67>
    return 0;
80102d0a:	be 00 00 00 00       	mov    $0x0,%esi
80102d0f:	eb e1                	jmp    80102cf2 <mpconfig+0x67>
    return 0;
80102d11:	be 00 00 00 00       	mov    $0x0,%esi
80102d16:	eb da                	jmp    80102cf2 <mpconfig+0x67>
    return 0;
80102d18:	be 00 00 00 00       	mov    $0x0,%esi
80102d1d:	eb d3                	jmp    80102cf2 <mpconfig+0x67>

80102d1f <mpinit>:

void
mpinit(void)
{
80102d1f:	55                   	push   %ebp
80102d20:	89 e5                	mov    %esp,%ebp
80102d22:	57                   	push   %edi
80102d23:	56                   	push   %esi
80102d24:	53                   	push   %ebx
80102d25:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102d28:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102d2b:	e8 5b ff ff ff       	call   80102c8b <mpconfig>
80102d30:	85 c0                	test   %eax,%eax
80102d32:	74 19                	je     80102d4d <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102d34:	8b 50 24             	mov    0x24(%eax),%edx
80102d37:	89 15 a0 16 13 80    	mov    %edx,0x801316a0
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d3d:	8d 50 2c             	lea    0x2c(%eax),%edx
80102d40:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102d44:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102d46:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d4b:	eb 34                	jmp    80102d81 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102d4d:	83 ec 0c             	sub    $0xc,%esp
80102d50:	68 82 6a 10 80       	push   $0x80106a82
80102d55:	e8 ee d5 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102d5a:	8b 35 40 1d 13 80    	mov    0x80131d40,%esi
80102d60:	83 fe 07             	cmp    $0x7,%esi
80102d63:	7f 19                	jg     80102d7e <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102d65:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102d69:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102d6f:	88 87 c0 17 13 80    	mov    %al,-0x7fece840(%edi)
        ncpu++;
80102d75:	83 c6 01             	add    $0x1,%esi
80102d78:	89 35 40 1d 13 80    	mov    %esi,0x80131d40
      }
      p += sizeof(struct mpproc);
80102d7e:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d81:	39 ca                	cmp    %ecx,%edx
80102d83:	73 2b                	jae    80102db0 <mpinit+0x91>
    switch(*p){
80102d85:	0f b6 02             	movzbl (%edx),%eax
80102d88:	3c 04                	cmp    $0x4,%al
80102d8a:	77 1d                	ja     80102da9 <mpinit+0x8a>
80102d8c:	0f b6 c0             	movzbl %al,%eax
80102d8f:	ff 24 85 bc 6a 10 80 	jmp    *-0x7fef9544(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102d96:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102d9a:	a2 a0 17 13 80       	mov    %al,0x801317a0
      p += sizeof(struct mpioapic);
80102d9f:	83 c2 08             	add    $0x8,%edx
      continue;
80102da2:	eb dd                	jmp    80102d81 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102da4:	83 c2 08             	add    $0x8,%edx
      continue;
80102da7:	eb d8                	jmp    80102d81 <mpinit+0x62>
    default:
      ismp = 0;
80102da9:	bb 00 00 00 00       	mov    $0x0,%ebx
80102dae:	eb d1                	jmp    80102d81 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102db0:	85 db                	test   %ebx,%ebx
80102db2:	74 26                	je     80102dda <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102db4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102db7:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102dbb:	74 15                	je     80102dd2 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102dbd:	b8 70 00 00 00       	mov    $0x70,%eax
80102dc2:	ba 22 00 00 00       	mov    $0x22,%edx
80102dc7:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102dc8:	ba 23 00 00 00       	mov    $0x23,%edx
80102dcd:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102dce:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102dd1:	ee                   	out    %al,(%dx)
  }
}
80102dd2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102dd5:	5b                   	pop    %ebx
80102dd6:	5e                   	pop    %esi
80102dd7:	5f                   	pop    %edi
80102dd8:	5d                   	pop    %ebp
80102dd9:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102dda:	83 ec 0c             	sub    $0xc,%esp
80102ddd:	68 9c 6a 10 80       	push   $0x80106a9c
80102de2:	e8 61 d5 ff ff       	call   80100348 <panic>

80102de7 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102de7:	55                   	push   %ebp
80102de8:	89 e5                	mov    %esp,%ebp
80102dea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102def:	ba 21 00 00 00       	mov    $0x21,%edx
80102df4:	ee                   	out    %al,(%dx)
80102df5:	ba a1 00 00 00       	mov    $0xa1,%edx
80102dfa:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102dfb:	5d                   	pop    %ebp
80102dfc:	c3                   	ret    

80102dfd <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102dfd:	55                   	push   %ebp
80102dfe:	89 e5                	mov    %esp,%ebp
80102e00:	57                   	push   %edi
80102e01:	56                   	push   %esi
80102e02:	53                   	push   %ebx
80102e03:	83 ec 0c             	sub    $0xc,%esp
80102e06:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102e09:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102e0c:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102e12:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102e18:	e8 10 de ff ff       	call   80100c2d <filealloc>
80102e1d:	89 03                	mov    %eax,(%ebx)
80102e1f:	85 c0                	test   %eax,%eax
80102e21:	74 16                	je     80102e39 <pipealloc+0x3c>
80102e23:	e8 05 de ff ff       	call   80100c2d <filealloc>
80102e28:	89 06                	mov    %eax,(%esi)
80102e2a:	85 c0                	test   %eax,%eax
80102e2c:	74 0b                	je     80102e39 <pipealloc+0x3c>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80102e2e:	e8 98 f2 ff ff       	call   801020cb <kalloc>
80102e33:	89 c7                	mov    %eax,%edi
80102e35:	85 c0                	test   %eax,%eax
80102e37:	75 35                	jne    80102e6e <pipealloc+0x71>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102e39:	8b 03                	mov    (%ebx),%eax
80102e3b:	85 c0                	test   %eax,%eax
80102e3d:	74 0c                	je     80102e4b <pipealloc+0x4e>
    fileclose(*f0);
80102e3f:	83 ec 0c             	sub    $0xc,%esp
80102e42:	50                   	push   %eax
80102e43:	e8 8b de ff ff       	call   80100cd3 <fileclose>
80102e48:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102e4b:	8b 06                	mov    (%esi),%eax
80102e4d:	85 c0                	test   %eax,%eax
80102e4f:	0f 84 8b 00 00 00    	je     80102ee0 <pipealloc+0xe3>
    fileclose(*f1);
80102e55:	83 ec 0c             	sub    $0xc,%esp
80102e58:	50                   	push   %eax
80102e59:	e8 75 de ff ff       	call   80100cd3 <fileclose>
80102e5e:	83 c4 10             	add    $0x10,%esp
  return -1;
80102e61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102e66:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e69:	5b                   	pop    %ebx
80102e6a:	5e                   	pop    %esi
80102e6b:	5f                   	pop    %edi
80102e6c:	5d                   	pop    %ebp
80102e6d:	c3                   	ret    
  p->readopen = 1;
80102e6e:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102e75:	00 00 00 
  p->writeopen = 1;
80102e78:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102e7f:	00 00 00 
  p->nwrite = 0;
80102e82:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102e89:	00 00 00 
  p->nread = 0;
80102e8c:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102e93:	00 00 00 
  initlock(&p->lock, "pipe");
80102e96:	83 ec 08             	sub    $0x8,%esp
80102e99:	68 d0 6a 10 80       	push   $0x80106ad0
80102e9e:	50                   	push   %eax
80102e9f:	e8 7d 0c 00 00       	call   80103b21 <initlock>
  (*f0)->type = FD_PIPE;
80102ea4:	8b 03                	mov    (%ebx),%eax
80102ea6:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102eac:	8b 03                	mov    (%ebx),%eax
80102eae:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102eb2:	8b 03                	mov    (%ebx),%eax
80102eb4:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102eb8:	8b 03                	mov    (%ebx),%eax
80102eba:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102ebd:	8b 06                	mov    (%esi),%eax
80102ebf:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102ec5:	8b 06                	mov    (%esi),%eax
80102ec7:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102ecb:	8b 06                	mov    (%esi),%eax
80102ecd:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102ed1:	8b 06                	mov    (%esi),%eax
80102ed3:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102ed6:	83 c4 10             	add    $0x10,%esp
80102ed9:	b8 00 00 00 00       	mov    $0x0,%eax
80102ede:	eb 86                	jmp    80102e66 <pipealloc+0x69>
  return -1;
80102ee0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102ee5:	e9 7c ff ff ff       	jmp    80102e66 <pipealloc+0x69>

80102eea <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102eea:	55                   	push   %ebp
80102eeb:	89 e5                	mov    %esp,%ebp
80102eed:	53                   	push   %ebx
80102eee:	83 ec 10             	sub    $0x10,%esp
80102ef1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102ef4:	53                   	push   %ebx
80102ef5:	e8 63 0d 00 00       	call   80103c5d <acquire>
  if(writable){
80102efa:	83 c4 10             	add    $0x10,%esp
80102efd:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102f01:	74 3f                	je     80102f42 <pipeclose+0x58>
    p->writeopen = 0;
80102f03:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102f0a:	00 00 00 
    wakeup(&p->nread);
80102f0d:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f13:	83 ec 0c             	sub    $0xc,%esp
80102f16:	50                   	push   %eax
80102f17:	e8 ab 09 00 00       	call   801038c7 <wakeup>
80102f1c:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102f1f:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f26:	75 09                	jne    80102f31 <pipeclose+0x47>
80102f28:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102f2f:	74 2f                	je     80102f60 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102f31:	83 ec 0c             	sub    $0xc,%esp
80102f34:	53                   	push   %ebx
80102f35:	e8 88 0d 00 00       	call   80103cc2 <release>
80102f3a:	83 c4 10             	add    $0x10,%esp
}
80102f3d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102f40:	c9                   	leave  
80102f41:	c3                   	ret    
    p->readopen = 0;
80102f42:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102f49:	00 00 00 
    wakeup(&p->nwrite);
80102f4c:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f52:	83 ec 0c             	sub    $0xc,%esp
80102f55:	50                   	push   %eax
80102f56:	e8 6c 09 00 00       	call   801038c7 <wakeup>
80102f5b:	83 c4 10             	add    $0x10,%esp
80102f5e:	eb bf                	jmp    80102f1f <pipeclose+0x35>
    release(&p->lock);
80102f60:	83 ec 0c             	sub    $0xc,%esp
80102f63:	53                   	push   %ebx
80102f64:	e8 59 0d 00 00       	call   80103cc2 <release>
    kfree((char*)p);
80102f69:	89 1c 24             	mov    %ebx,(%esp)
80102f6c:	e8 33 f0 ff ff       	call   80101fa4 <kfree>
80102f71:	83 c4 10             	add    $0x10,%esp
80102f74:	eb c7                	jmp    80102f3d <pipeclose+0x53>

80102f76 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80102f76:	55                   	push   %ebp
80102f77:	89 e5                	mov    %esp,%ebp
80102f79:	57                   	push   %edi
80102f7a:	56                   	push   %esi
80102f7b:	53                   	push   %ebx
80102f7c:	83 ec 18             	sub    $0x18,%esp
80102f7f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102f82:	89 de                	mov    %ebx,%esi
80102f84:	53                   	push   %ebx
80102f85:	e8 d3 0c 00 00       	call   80103c5d <acquire>
  for(i = 0; i < n; i++){
80102f8a:	83 c4 10             	add    $0x10,%esp
80102f8d:	bf 00 00 00 00       	mov    $0x0,%edi
80102f92:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102f95:	0f 8d 88 00 00 00    	jge    80103023 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80102f9b:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80102fa1:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80102fa7:	05 00 02 00 00       	add    $0x200,%eax
80102fac:	39 c2                	cmp    %eax,%edx
80102fae:	75 51                	jne    80103001 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80102fb0:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102fb7:	74 2f                	je     80102fe8 <pipewrite+0x72>
80102fb9:	e8 00 03 00 00       	call   801032be <myproc>
80102fbe:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102fc2:	75 24                	jne    80102fe8 <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80102fc4:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102fca:	83 ec 0c             	sub    $0xc,%esp
80102fcd:	50                   	push   %eax
80102fce:	e8 f4 08 00 00       	call   801038c7 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80102fd3:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102fd9:	83 c4 08             	add    $0x8,%esp
80102fdc:	56                   	push   %esi
80102fdd:	50                   	push   %eax
80102fde:	e8 7f 07 00 00       	call   80103762 <sleep>
80102fe3:	83 c4 10             	add    $0x10,%esp
80102fe6:	eb b3                	jmp    80102f9b <pipewrite+0x25>
        release(&p->lock);
80102fe8:	83 ec 0c             	sub    $0xc,%esp
80102feb:	53                   	push   %ebx
80102fec:	e8 d1 0c 00 00       	call   80103cc2 <release>
        return -1;
80102ff1:	83 c4 10             	add    $0x10,%esp
80102ff4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80102ff9:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102ffc:	5b                   	pop    %ebx
80102ffd:	5e                   	pop    %esi
80102ffe:	5f                   	pop    %edi
80102fff:	5d                   	pop    %ebp
80103000:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103001:	8d 42 01             	lea    0x1(%edx),%eax
80103004:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
8010300a:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80103010:	8b 45 0c             	mov    0xc(%ebp),%eax
80103013:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80103017:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
8010301b:	83 c7 01             	add    $0x1,%edi
8010301e:	e9 6f ff ff ff       	jmp    80102f92 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103023:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103029:	83 ec 0c             	sub    $0xc,%esp
8010302c:	50                   	push   %eax
8010302d:	e8 95 08 00 00       	call   801038c7 <wakeup>
  release(&p->lock);
80103032:	89 1c 24             	mov    %ebx,(%esp)
80103035:	e8 88 0c 00 00       	call   80103cc2 <release>
  return n;
8010303a:	83 c4 10             	add    $0x10,%esp
8010303d:	8b 45 10             	mov    0x10(%ebp),%eax
80103040:	eb b7                	jmp    80102ff9 <pipewrite+0x83>

80103042 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103042:	55                   	push   %ebp
80103043:	89 e5                	mov    %esp,%ebp
80103045:	57                   	push   %edi
80103046:	56                   	push   %esi
80103047:	53                   	push   %ebx
80103048:	83 ec 18             	sub    $0x18,%esp
8010304b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
8010304e:	89 df                	mov    %ebx,%edi
80103050:	53                   	push   %ebx
80103051:	e8 07 0c 00 00       	call   80103c5d <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103056:	83 c4 10             	add    $0x10,%esp
80103059:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
8010305f:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
80103065:	75 3d                	jne    801030a4 <piperead+0x62>
80103067:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
8010306d:	85 f6                	test   %esi,%esi
8010306f:	74 38                	je     801030a9 <piperead+0x67>
    if(myproc()->killed){
80103071:	e8 48 02 00 00       	call   801032be <myproc>
80103076:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010307a:	75 15                	jne    80103091 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010307c:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103082:	83 ec 08             	sub    $0x8,%esp
80103085:	57                   	push   %edi
80103086:	50                   	push   %eax
80103087:	e8 d6 06 00 00       	call   80103762 <sleep>
8010308c:	83 c4 10             	add    $0x10,%esp
8010308f:	eb c8                	jmp    80103059 <piperead+0x17>
      release(&p->lock);
80103091:	83 ec 0c             	sub    $0xc,%esp
80103094:	53                   	push   %ebx
80103095:	e8 28 0c 00 00       	call   80103cc2 <release>
      return -1;
8010309a:	83 c4 10             	add    $0x10,%esp
8010309d:	be ff ff ff ff       	mov    $0xffffffff,%esi
801030a2:	eb 50                	jmp    801030f4 <piperead+0xb2>
801030a4:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801030a9:	3b 75 10             	cmp    0x10(%ebp),%esi
801030ac:	7d 2c                	jge    801030da <piperead+0x98>
    if(p->nread == p->nwrite)
801030ae:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801030b4:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
801030ba:	74 1e                	je     801030da <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801030bc:	8d 50 01             	lea    0x1(%eax),%edx
801030bf:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
801030c5:	25 ff 01 00 00       	and    $0x1ff,%eax
801030ca:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
801030cf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801030d2:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801030d5:	83 c6 01             	add    $0x1,%esi
801030d8:	eb cf                	jmp    801030a9 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801030da:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801030e0:	83 ec 0c             	sub    $0xc,%esp
801030e3:	50                   	push   %eax
801030e4:	e8 de 07 00 00       	call   801038c7 <wakeup>
  release(&p->lock);
801030e9:	89 1c 24             	mov    %ebx,(%esp)
801030ec:	e8 d1 0b 00 00       	call   80103cc2 <release>
  return i;
801030f1:	83 c4 10             	add    $0x10,%esp
}
801030f4:	89 f0                	mov    %esi,%eax
801030f6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801030f9:	5b                   	pop    %ebx
801030fa:	5e                   	pop    %esi
801030fb:	5f                   	pop    %edi
801030fc:	5d                   	pop    %ebp
801030fd:	c3                   	ret    

801030fe <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801030fe:	55                   	push   %ebp
801030ff:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103101:	ba 94 1d 13 80       	mov    $0x80131d94,%edx
80103106:	eb 03                	jmp    8010310b <wakeup1+0xd>
80103108:	83 c2 7c             	add    $0x7c,%edx
8010310b:	81 fa 94 3c 13 80    	cmp    $0x80133c94,%edx
80103111:	73 14                	jae    80103127 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
80103113:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
80103117:	75 ef                	jne    80103108 <wakeup1+0xa>
80103119:	39 42 20             	cmp    %eax,0x20(%edx)
8010311c:	75 ea                	jne    80103108 <wakeup1+0xa>
      p->state = RUNNABLE;
8010311e:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
80103125:	eb e1                	jmp    80103108 <wakeup1+0xa>
}
80103127:	5d                   	pop    %ebp
80103128:	c3                   	ret    

80103129 <allocproc>:
{
80103129:	55                   	push   %ebp
8010312a:	89 e5                	mov    %esp,%ebp
8010312c:	53                   	push   %ebx
8010312d:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103130:	68 60 1d 13 80       	push   $0x80131d60
80103135:	e8 23 0b 00 00       	call   80103c5d <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010313a:	83 c4 10             	add    $0x10,%esp
8010313d:	bb 94 1d 13 80       	mov    $0x80131d94,%ebx
80103142:	81 fb 94 3c 13 80    	cmp    $0x80133c94,%ebx
80103148:	73 0b                	jae    80103155 <allocproc+0x2c>
    if(p->state == UNUSED)
8010314a:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
8010314e:	74 1c                	je     8010316c <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103150:	83 c3 7c             	add    $0x7c,%ebx
80103153:	eb ed                	jmp    80103142 <allocproc+0x19>
  release(&ptable.lock);
80103155:	83 ec 0c             	sub    $0xc,%esp
80103158:	68 60 1d 13 80       	push   $0x80131d60
8010315d:	e8 60 0b 00 00       	call   80103cc2 <release>
  return 0;
80103162:	83 c4 10             	add    $0x10,%esp
80103165:	bb 00 00 00 00       	mov    $0x0,%ebx
8010316a:	eb 69                	jmp    801031d5 <allocproc+0xac>
  p->state = EMBRYO;
8010316c:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
80103173:	a1 04 90 10 80       	mov    0x80109004,%eax
80103178:	8d 50 01             	lea    0x1(%eax),%edx
8010317b:	89 15 04 90 10 80    	mov    %edx,0x80109004
80103181:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
80103184:	83 ec 0c             	sub    $0xc,%esp
80103187:	68 60 1d 13 80       	push   $0x80131d60
8010318c:	e8 31 0b 00 00       	call   80103cc2 <release>
  if((p->kstack = kalloc()) == 0){
80103191:	e8 35 ef ff ff       	call   801020cb <kalloc>
80103196:	89 43 08             	mov    %eax,0x8(%ebx)
80103199:	83 c4 10             	add    $0x10,%esp
8010319c:	85 c0                	test   %eax,%eax
8010319e:	74 3c                	je     801031dc <allocproc+0xb3>
  sp -= sizeof *p->tf;
801031a0:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
801031a6:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
801031a9:	c7 80 b0 0f 00 00 37 	movl   $0x80104e37,0xfb0(%eax)
801031b0:	4e 10 80 
  sp -= sizeof *p->context;
801031b3:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
801031b8:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
801031bb:	83 ec 04             	sub    $0x4,%esp
801031be:	6a 14                	push   $0x14
801031c0:	6a 00                	push   $0x0
801031c2:	50                   	push   %eax
801031c3:	e8 41 0b 00 00       	call   80103d09 <memset>
  p->context->eip = (uint)forkret;
801031c8:	8b 43 1c             	mov    0x1c(%ebx),%eax
801031cb:	c7 40 10 ea 31 10 80 	movl   $0x801031ea,0x10(%eax)
  return p;
801031d2:	83 c4 10             	add    $0x10,%esp
}
801031d5:	89 d8                	mov    %ebx,%eax
801031d7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801031da:	c9                   	leave  
801031db:	c3                   	ret    
    p->state = UNUSED;
801031dc:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
801031e3:	bb 00 00 00 00       	mov    $0x0,%ebx
801031e8:	eb eb                	jmp    801031d5 <allocproc+0xac>

801031ea <forkret>:
{
801031ea:	55                   	push   %ebp
801031eb:	89 e5                	mov    %esp,%ebp
801031ed:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
801031f0:	68 60 1d 13 80       	push   $0x80131d60
801031f5:	e8 c8 0a 00 00       	call   80103cc2 <release>
  if (first) {
801031fa:	83 c4 10             	add    $0x10,%esp
801031fd:	83 3d 00 90 10 80 00 	cmpl   $0x0,0x80109000
80103204:	75 02                	jne    80103208 <forkret+0x1e>
}
80103206:	c9                   	leave  
80103207:	c3                   	ret    
    first = 0;
80103208:	c7 05 00 90 10 80 00 	movl   $0x0,0x80109000
8010320f:	00 00 00 
    iinit(ROOTDEV);
80103212:	83 ec 0c             	sub    $0xc,%esp
80103215:	6a 01                	push   $0x1
80103217:	e8 d0 e0 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
8010321c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103223:	e8 05 f6 ff ff       	call   8010282d <initlog>
80103228:	83 c4 10             	add    $0x10,%esp
}
8010322b:	eb d9                	jmp    80103206 <forkret+0x1c>

8010322d <pinit>:
{
8010322d:	55                   	push   %ebp
8010322e:	89 e5                	mov    %esp,%ebp
80103230:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
80103233:	68 d5 6a 10 80       	push   $0x80106ad5
80103238:	68 60 1d 13 80       	push   $0x80131d60
8010323d:	e8 df 08 00 00       	call   80103b21 <initlock>
}
80103242:	83 c4 10             	add    $0x10,%esp
80103245:	c9                   	leave  
80103246:	c3                   	ret    

80103247 <mycpu>:
{
80103247:	55                   	push   %ebp
80103248:	89 e5                	mov    %esp,%ebp
8010324a:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010324d:	9c                   	pushf  
8010324e:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010324f:	f6 c4 02             	test   $0x2,%ah
80103252:	75 28                	jne    8010327c <mycpu+0x35>
  apicid = lapicid();
80103254:	e8 ed f1 ff ff       	call   80102446 <lapicid>
  for (i = 0; i < ncpu; ++i) {
80103259:	ba 00 00 00 00       	mov    $0x0,%edx
8010325e:	39 15 40 1d 13 80    	cmp    %edx,0x80131d40
80103264:	7e 23                	jle    80103289 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
80103266:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
8010326c:	0f b6 89 c0 17 13 80 	movzbl -0x7fece840(%ecx),%ecx
80103273:	39 c1                	cmp    %eax,%ecx
80103275:	74 1f                	je     80103296 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
80103277:	83 c2 01             	add    $0x1,%edx
8010327a:	eb e2                	jmp    8010325e <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
8010327c:	83 ec 0c             	sub    $0xc,%esp
8010327f:	68 b8 6b 10 80       	push   $0x80106bb8
80103284:	e8 bf d0 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
80103289:	83 ec 0c             	sub    $0xc,%esp
8010328c:	68 dc 6a 10 80       	push   $0x80106adc
80103291:	e8 b2 d0 ff ff       	call   80100348 <panic>
      return &cpus[i];
80103296:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
8010329c:	05 c0 17 13 80       	add    $0x801317c0,%eax
}
801032a1:	c9                   	leave  
801032a2:	c3                   	ret    

801032a3 <cpuid>:
cpuid() {
801032a3:	55                   	push   %ebp
801032a4:	89 e5                	mov    %esp,%ebp
801032a6:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
801032a9:	e8 99 ff ff ff       	call   80103247 <mycpu>
801032ae:	2d c0 17 13 80       	sub    $0x801317c0,%eax
801032b3:	c1 f8 04             	sar    $0x4,%eax
801032b6:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
801032bc:	c9                   	leave  
801032bd:	c3                   	ret    

801032be <myproc>:
myproc(void) {
801032be:	55                   	push   %ebp
801032bf:	89 e5                	mov    %esp,%ebp
801032c1:	53                   	push   %ebx
801032c2:	83 ec 04             	sub    $0x4,%esp
  pushcli();
801032c5:	e8 b6 08 00 00       	call   80103b80 <pushcli>
  c = mycpu();
801032ca:	e8 78 ff ff ff       	call   80103247 <mycpu>
  p = c->proc;
801032cf:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
801032d5:	e8 e3 08 00 00       	call   80103bbd <popcli>
}
801032da:	89 d8                	mov    %ebx,%eax
801032dc:	83 c4 04             	add    $0x4,%esp
801032df:	5b                   	pop    %ebx
801032e0:	5d                   	pop    %ebp
801032e1:	c3                   	ret    

801032e2 <userinit>:
{
801032e2:	55                   	push   %ebp
801032e3:	89 e5                	mov    %esp,%ebp
801032e5:	53                   	push   %ebx
801032e6:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
801032e9:	e8 3b fe ff ff       	call   80103129 <allocproc>
801032ee:	89 c3                	mov    %eax,%ebx
  initproc = p;
801032f0:	a3 c4 95 10 80       	mov    %eax,0x801095c4
  if((p->pgdir = setupkvm()) == 0)
801032f5:	e8 21 30 00 00       	call   8010631b <setupkvm>
801032fa:	89 43 04             	mov    %eax,0x4(%ebx)
801032fd:	85 c0                	test   %eax,%eax
801032ff:	0f 84 b7 00 00 00    	je     801033bc <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103305:	83 ec 04             	sub    $0x4,%esp
80103308:	68 2c 00 00 00       	push   $0x2c
8010330d:	68 60 94 10 80       	push   $0x80109460
80103312:	50                   	push   %eax
80103313:	e8 0e 2d 00 00       	call   80106026 <inituvm>
  p->sz = PGSIZE;
80103318:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
8010331e:	83 c4 0c             	add    $0xc,%esp
80103321:	6a 4c                	push   $0x4c
80103323:	6a 00                	push   $0x0
80103325:	ff 73 18             	pushl  0x18(%ebx)
80103328:	e8 dc 09 00 00       	call   80103d09 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010332d:	8b 43 18             	mov    0x18(%ebx),%eax
80103330:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80103336:	8b 43 18             	mov    0x18(%ebx),%eax
80103339:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010333f:	8b 43 18             	mov    0x18(%ebx),%eax
80103342:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103346:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010334a:	8b 43 18             	mov    0x18(%ebx),%eax
8010334d:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103351:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80103355:	8b 43 18             	mov    0x18(%ebx),%eax
80103358:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010335f:	8b 43 18             	mov    0x18(%ebx),%eax
80103362:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80103369:	8b 43 18             	mov    0x18(%ebx),%eax
8010336c:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
80103373:	8d 43 6c             	lea    0x6c(%ebx),%eax
80103376:	83 c4 0c             	add    $0xc,%esp
80103379:	6a 10                	push   $0x10
8010337b:	68 05 6b 10 80       	push   $0x80106b05
80103380:	50                   	push   %eax
80103381:	e8 ea 0a 00 00       	call   80103e70 <safestrcpy>
  p->cwd = namei("/");
80103386:	c7 04 24 0e 6b 10 80 	movl   $0x80106b0e,(%esp)
8010338d:	e8 4f e8 ff ff       	call   80101be1 <namei>
80103392:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103395:	c7 04 24 60 1d 13 80 	movl   $0x80131d60,(%esp)
8010339c:	e8 bc 08 00 00       	call   80103c5d <acquire>
  p->state = RUNNABLE;
801033a1:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
801033a8:	c7 04 24 60 1d 13 80 	movl   $0x80131d60,(%esp)
801033af:	e8 0e 09 00 00       	call   80103cc2 <release>
}
801033b4:	83 c4 10             	add    $0x10,%esp
801033b7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801033ba:	c9                   	leave  
801033bb:	c3                   	ret    
    panic("userinit: out of memory?");
801033bc:	83 ec 0c             	sub    $0xc,%esp
801033bf:	68 ec 6a 10 80       	push   $0x80106aec
801033c4:	e8 7f cf ff ff       	call   80100348 <panic>

801033c9 <growproc>:
{
801033c9:	55                   	push   %ebp
801033ca:	89 e5                	mov    %esp,%ebp
801033cc:	56                   	push   %esi
801033cd:	53                   	push   %ebx
801033ce:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
801033d1:	e8 e8 fe ff ff       	call   801032be <myproc>
801033d6:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
801033d8:	8b 00                	mov    (%eax),%eax
  if(n > 0){
801033da:	85 f6                	test   %esi,%esi
801033dc:	7f 21                	jg     801033ff <growproc+0x36>
  } else if(n < 0){
801033de:	85 f6                	test   %esi,%esi
801033e0:	79 33                	jns    80103415 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
801033e2:	83 ec 04             	sub    $0x4,%esp
801033e5:	01 c6                	add    %eax,%esi
801033e7:	56                   	push   %esi
801033e8:	50                   	push   %eax
801033e9:	ff 73 04             	pushl  0x4(%ebx)
801033ec:	e8 3e 2d 00 00       	call   8010612f <deallocuvm>
801033f1:	83 c4 10             	add    $0x10,%esp
801033f4:	85 c0                	test   %eax,%eax
801033f6:	75 1d                	jne    80103415 <growproc+0x4c>
      return -1;
801033f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801033fd:	eb 29                	jmp    80103428 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
801033ff:	83 ec 04             	sub    $0x4,%esp
80103402:	01 c6                	add    %eax,%esi
80103404:	56                   	push   %esi
80103405:	50                   	push   %eax
80103406:	ff 73 04             	pushl  0x4(%ebx)
80103409:	e8 b3 2d 00 00       	call   801061c1 <allocuvm>
8010340e:	83 c4 10             	add    $0x10,%esp
80103411:	85 c0                	test   %eax,%eax
80103413:	74 1a                	je     8010342f <growproc+0x66>
  curproc->sz = sz;
80103415:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
80103417:	83 ec 0c             	sub    $0xc,%esp
8010341a:	53                   	push   %ebx
8010341b:	e8 ee 2a 00 00       	call   80105f0e <switchuvm>
  return 0;
80103420:	83 c4 10             	add    $0x10,%esp
80103423:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103428:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010342b:	5b                   	pop    %ebx
8010342c:	5e                   	pop    %esi
8010342d:	5d                   	pop    %ebp
8010342e:	c3                   	ret    
      return -1;
8010342f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103434:	eb f2                	jmp    80103428 <growproc+0x5f>

80103436 <fork>:
{
80103436:	55                   	push   %ebp
80103437:	89 e5                	mov    %esp,%ebp
80103439:	57                   	push   %edi
8010343a:	56                   	push   %esi
8010343b:	53                   	push   %ebx
8010343c:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
8010343f:	e8 7a fe ff ff       	call   801032be <myproc>
80103444:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
80103446:	e8 de fc ff ff       	call   80103129 <allocproc>
8010344b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010344e:	85 c0                	test   %eax,%eax
80103450:	0f 84 e0 00 00 00    	je     80103536 <fork+0x100>
80103456:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
80103458:	83 ec 08             	sub    $0x8,%esp
8010345b:	ff 33                	pushl  (%ebx)
8010345d:	ff 73 04             	pushl  0x4(%ebx)
80103460:	e8 67 2f 00 00       	call   801063cc <copyuvm>
80103465:	89 47 04             	mov    %eax,0x4(%edi)
80103468:	83 c4 10             	add    $0x10,%esp
8010346b:	85 c0                	test   %eax,%eax
8010346d:	74 2a                	je     80103499 <fork+0x63>
  np->sz = curproc->sz;
8010346f:	8b 03                	mov    (%ebx),%eax
80103471:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80103474:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
80103476:	89 c8                	mov    %ecx,%eax
80103478:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
8010347b:	8b 73 18             	mov    0x18(%ebx),%esi
8010347e:	8b 79 18             	mov    0x18(%ecx),%edi
80103481:	b9 13 00 00 00       	mov    $0x13,%ecx
80103486:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
80103488:	8b 40 18             	mov    0x18(%eax),%eax
8010348b:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
80103492:	be 00 00 00 00       	mov    $0x0,%esi
80103497:	eb 29                	jmp    801034c2 <fork+0x8c>
    kfree(np->kstack);
80103499:	83 ec 0c             	sub    $0xc,%esp
8010349c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010349f:	ff 73 08             	pushl  0x8(%ebx)
801034a2:	e8 fd ea ff ff       	call   80101fa4 <kfree>
    np->kstack = 0;
801034a7:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
801034ae:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
801034b5:	83 c4 10             	add    $0x10,%esp
801034b8:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801034bd:	eb 6d                	jmp    8010352c <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
801034bf:	83 c6 01             	add    $0x1,%esi
801034c2:	83 fe 0f             	cmp    $0xf,%esi
801034c5:	7f 1d                	jg     801034e4 <fork+0xae>
    if(curproc->ofile[i])
801034c7:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
801034cb:	85 c0                	test   %eax,%eax
801034cd:	74 f0                	je     801034bf <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
801034cf:	83 ec 0c             	sub    $0xc,%esp
801034d2:	50                   	push   %eax
801034d3:	e8 b6 d7 ff ff       	call   80100c8e <filedup>
801034d8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801034db:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
801034df:	83 c4 10             	add    $0x10,%esp
801034e2:	eb db                	jmp    801034bf <fork+0x89>
  np->cwd = idup(curproc->cwd);
801034e4:	83 ec 0c             	sub    $0xc,%esp
801034e7:	ff 73 68             	pushl  0x68(%ebx)
801034ea:	e8 62 e0 ff ff       	call   80101551 <idup>
801034ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
801034f2:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
801034f5:	83 c3 6c             	add    $0x6c,%ebx
801034f8:	8d 47 6c             	lea    0x6c(%edi),%eax
801034fb:	83 c4 0c             	add    $0xc,%esp
801034fe:	6a 10                	push   $0x10
80103500:	53                   	push   %ebx
80103501:	50                   	push   %eax
80103502:	e8 69 09 00 00       	call   80103e70 <safestrcpy>
  pid = np->pid;
80103507:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
8010350a:	c7 04 24 60 1d 13 80 	movl   $0x80131d60,(%esp)
80103511:	e8 47 07 00 00       	call   80103c5d <acquire>
  np->state = RUNNABLE;
80103516:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
8010351d:	c7 04 24 60 1d 13 80 	movl   $0x80131d60,(%esp)
80103524:	e8 99 07 00 00       	call   80103cc2 <release>
  return pid;
80103529:	83 c4 10             	add    $0x10,%esp
}
8010352c:	89 d8                	mov    %ebx,%eax
8010352e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103531:	5b                   	pop    %ebx
80103532:	5e                   	pop    %esi
80103533:	5f                   	pop    %edi
80103534:	5d                   	pop    %ebp
80103535:	c3                   	ret    
    return -1;
80103536:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010353b:	eb ef                	jmp    8010352c <fork+0xf6>

8010353d <scheduler>:
{
8010353d:	55                   	push   %ebp
8010353e:	89 e5                	mov    %esp,%ebp
80103540:	56                   	push   %esi
80103541:	53                   	push   %ebx
  struct cpu *c = mycpu();
80103542:	e8 00 fd ff ff       	call   80103247 <mycpu>
80103547:	89 c6                	mov    %eax,%esi
  c->proc = 0;
80103549:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80103550:	00 00 00 
80103553:	eb 5a                	jmp    801035af <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103555:	83 c3 7c             	add    $0x7c,%ebx
80103558:	81 fb 94 3c 13 80    	cmp    $0x80133c94,%ebx
8010355e:	73 3f                	jae    8010359f <scheduler+0x62>
      if(p->state != RUNNABLE)
80103560:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
80103564:	75 ef                	jne    80103555 <scheduler+0x18>
      c->proc = p;
80103566:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
8010356c:	83 ec 0c             	sub    $0xc,%esp
8010356f:	53                   	push   %ebx
80103570:	e8 99 29 00 00       	call   80105f0e <switchuvm>
      p->state = RUNNING;
80103575:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
8010357c:	83 c4 08             	add    $0x8,%esp
8010357f:	ff 73 1c             	pushl  0x1c(%ebx)
80103582:	8d 46 04             	lea    0x4(%esi),%eax
80103585:	50                   	push   %eax
80103586:	e8 38 09 00 00       	call   80103ec3 <swtch>
      switchkvm();
8010358b:	e8 6c 29 00 00       	call   80105efc <switchkvm>
      c->proc = 0;
80103590:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103597:	00 00 00 
8010359a:	83 c4 10             	add    $0x10,%esp
8010359d:	eb b6                	jmp    80103555 <scheduler+0x18>
    release(&ptable.lock);
8010359f:	83 ec 0c             	sub    $0xc,%esp
801035a2:	68 60 1d 13 80       	push   $0x80131d60
801035a7:	e8 16 07 00 00       	call   80103cc2 <release>
    sti();
801035ac:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
801035af:	fb                   	sti    
    acquire(&ptable.lock);
801035b0:	83 ec 0c             	sub    $0xc,%esp
801035b3:	68 60 1d 13 80       	push   $0x80131d60
801035b8:	e8 a0 06 00 00       	call   80103c5d <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801035bd:	83 c4 10             	add    $0x10,%esp
801035c0:	bb 94 1d 13 80       	mov    $0x80131d94,%ebx
801035c5:	eb 91                	jmp    80103558 <scheduler+0x1b>

801035c7 <sched>:
{
801035c7:	55                   	push   %ebp
801035c8:	89 e5                	mov    %esp,%ebp
801035ca:	56                   	push   %esi
801035cb:	53                   	push   %ebx
  struct proc *p = myproc();
801035cc:	e8 ed fc ff ff       	call   801032be <myproc>
801035d1:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
801035d3:	83 ec 0c             	sub    $0xc,%esp
801035d6:	68 60 1d 13 80       	push   $0x80131d60
801035db:	e8 3d 06 00 00       	call   80103c1d <holding>
801035e0:	83 c4 10             	add    $0x10,%esp
801035e3:	85 c0                	test   %eax,%eax
801035e5:	74 4f                	je     80103636 <sched+0x6f>
  if(mycpu()->ncli != 1)
801035e7:	e8 5b fc ff ff       	call   80103247 <mycpu>
801035ec:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
801035f3:	75 4e                	jne    80103643 <sched+0x7c>
  if(p->state == RUNNING)
801035f5:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
801035f9:	74 55                	je     80103650 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801035fb:	9c                   	pushf  
801035fc:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801035fd:	f6 c4 02             	test   $0x2,%ah
80103600:	75 5b                	jne    8010365d <sched+0x96>
  intena = mycpu()->intena;
80103602:	e8 40 fc ff ff       	call   80103247 <mycpu>
80103607:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
8010360d:	e8 35 fc ff ff       	call   80103247 <mycpu>
80103612:	83 ec 08             	sub    $0x8,%esp
80103615:	ff 70 04             	pushl  0x4(%eax)
80103618:	83 c3 1c             	add    $0x1c,%ebx
8010361b:	53                   	push   %ebx
8010361c:	e8 a2 08 00 00       	call   80103ec3 <swtch>
  mycpu()->intena = intena;
80103621:	e8 21 fc ff ff       	call   80103247 <mycpu>
80103626:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
8010362c:	83 c4 10             	add    $0x10,%esp
8010362f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103632:	5b                   	pop    %ebx
80103633:	5e                   	pop    %esi
80103634:	5d                   	pop    %ebp
80103635:	c3                   	ret    
    panic("sched ptable.lock");
80103636:	83 ec 0c             	sub    $0xc,%esp
80103639:	68 10 6b 10 80       	push   $0x80106b10
8010363e:	e8 05 cd ff ff       	call   80100348 <panic>
    panic("sched locks");
80103643:	83 ec 0c             	sub    $0xc,%esp
80103646:	68 22 6b 10 80       	push   $0x80106b22
8010364b:	e8 f8 cc ff ff       	call   80100348 <panic>
    panic("sched running");
80103650:	83 ec 0c             	sub    $0xc,%esp
80103653:	68 2e 6b 10 80       	push   $0x80106b2e
80103658:	e8 eb cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
8010365d:	83 ec 0c             	sub    $0xc,%esp
80103660:	68 3c 6b 10 80       	push   $0x80106b3c
80103665:	e8 de cc ff ff       	call   80100348 <panic>

8010366a <exit>:
{
8010366a:	55                   	push   %ebp
8010366b:	89 e5                	mov    %esp,%ebp
8010366d:	56                   	push   %esi
8010366e:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010366f:	e8 4a fc ff ff       	call   801032be <myproc>
  if(curproc == initproc)
80103674:	39 05 c4 95 10 80    	cmp    %eax,0x801095c4
8010367a:	74 09                	je     80103685 <exit+0x1b>
8010367c:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
8010367e:	bb 00 00 00 00       	mov    $0x0,%ebx
80103683:	eb 10                	jmp    80103695 <exit+0x2b>
    panic("init exiting");
80103685:	83 ec 0c             	sub    $0xc,%esp
80103688:	68 50 6b 10 80       	push   $0x80106b50
8010368d:	e8 b6 cc ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
80103692:	83 c3 01             	add    $0x1,%ebx
80103695:	83 fb 0f             	cmp    $0xf,%ebx
80103698:	7f 1e                	jg     801036b8 <exit+0x4e>
    if(curproc->ofile[fd]){
8010369a:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
8010369e:	85 c0                	test   %eax,%eax
801036a0:	74 f0                	je     80103692 <exit+0x28>
      fileclose(curproc->ofile[fd]);
801036a2:	83 ec 0c             	sub    $0xc,%esp
801036a5:	50                   	push   %eax
801036a6:	e8 28 d6 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
801036ab:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
801036b2:	00 
801036b3:	83 c4 10             	add    $0x10,%esp
801036b6:	eb da                	jmp    80103692 <exit+0x28>
  begin_op();
801036b8:	e8 b9 f1 ff ff       	call   80102876 <begin_op>
  iput(curproc->cwd);
801036bd:	83 ec 0c             	sub    $0xc,%esp
801036c0:	ff 76 68             	pushl  0x68(%esi)
801036c3:	e8 c0 df ff ff       	call   80101688 <iput>
  end_op();
801036c8:	e8 23 f2 ff ff       	call   801028f0 <end_op>
  curproc->cwd = 0;
801036cd:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
801036d4:	c7 04 24 60 1d 13 80 	movl   $0x80131d60,(%esp)
801036db:	e8 7d 05 00 00       	call   80103c5d <acquire>
  wakeup1(curproc->parent);
801036e0:	8b 46 14             	mov    0x14(%esi),%eax
801036e3:	e8 16 fa ff ff       	call   801030fe <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801036e8:	83 c4 10             	add    $0x10,%esp
801036eb:	bb 94 1d 13 80       	mov    $0x80131d94,%ebx
801036f0:	eb 03                	jmp    801036f5 <exit+0x8b>
801036f2:	83 c3 7c             	add    $0x7c,%ebx
801036f5:	81 fb 94 3c 13 80    	cmp    $0x80133c94,%ebx
801036fb:	73 1a                	jae    80103717 <exit+0xad>
    if(p->parent == curproc){
801036fd:	39 73 14             	cmp    %esi,0x14(%ebx)
80103700:	75 f0                	jne    801036f2 <exit+0x88>
      p->parent = initproc;
80103702:	a1 c4 95 10 80       	mov    0x801095c4,%eax
80103707:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
8010370a:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010370e:	75 e2                	jne    801036f2 <exit+0x88>
        wakeup1(initproc);
80103710:	e8 e9 f9 ff ff       	call   801030fe <wakeup1>
80103715:	eb db                	jmp    801036f2 <exit+0x88>
  curproc->state = ZOMBIE;
80103717:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
8010371e:	e8 a4 fe ff ff       	call   801035c7 <sched>
  panic("zombie exit");
80103723:	83 ec 0c             	sub    $0xc,%esp
80103726:	68 5d 6b 10 80       	push   $0x80106b5d
8010372b:	e8 18 cc ff ff       	call   80100348 <panic>

80103730 <yield>:
{
80103730:	55                   	push   %ebp
80103731:	89 e5                	mov    %esp,%ebp
80103733:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80103736:	68 60 1d 13 80       	push   $0x80131d60
8010373b:	e8 1d 05 00 00       	call   80103c5d <acquire>
  myproc()->state = RUNNABLE;
80103740:	e8 79 fb ff ff       	call   801032be <myproc>
80103745:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
8010374c:	e8 76 fe ff ff       	call   801035c7 <sched>
  release(&ptable.lock);
80103751:	c7 04 24 60 1d 13 80 	movl   $0x80131d60,(%esp)
80103758:	e8 65 05 00 00       	call   80103cc2 <release>
}
8010375d:	83 c4 10             	add    $0x10,%esp
80103760:	c9                   	leave  
80103761:	c3                   	ret    

80103762 <sleep>:
{
80103762:	55                   	push   %ebp
80103763:	89 e5                	mov    %esp,%ebp
80103765:	56                   	push   %esi
80103766:	53                   	push   %ebx
80103767:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
8010376a:	e8 4f fb ff ff       	call   801032be <myproc>
  if(p == 0)
8010376f:	85 c0                	test   %eax,%eax
80103771:	74 66                	je     801037d9 <sleep+0x77>
80103773:	89 c6                	mov    %eax,%esi
  if(lk == 0)
80103775:	85 db                	test   %ebx,%ebx
80103777:	74 6d                	je     801037e6 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
80103779:	81 fb 60 1d 13 80    	cmp    $0x80131d60,%ebx
8010377f:	74 18                	je     80103799 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
80103781:	83 ec 0c             	sub    $0xc,%esp
80103784:	68 60 1d 13 80       	push   $0x80131d60
80103789:	e8 cf 04 00 00       	call   80103c5d <acquire>
    release(lk);
8010378e:	89 1c 24             	mov    %ebx,(%esp)
80103791:	e8 2c 05 00 00       	call   80103cc2 <release>
80103796:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103799:	8b 45 08             	mov    0x8(%ebp),%eax
8010379c:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
8010379f:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
801037a6:	e8 1c fe ff ff       	call   801035c7 <sched>
  p->chan = 0;
801037ab:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
801037b2:	81 fb 60 1d 13 80    	cmp    $0x80131d60,%ebx
801037b8:	74 18                	je     801037d2 <sleep+0x70>
    release(&ptable.lock);
801037ba:	83 ec 0c             	sub    $0xc,%esp
801037bd:	68 60 1d 13 80       	push   $0x80131d60
801037c2:	e8 fb 04 00 00       	call   80103cc2 <release>
    acquire(lk);
801037c7:	89 1c 24             	mov    %ebx,(%esp)
801037ca:	e8 8e 04 00 00       	call   80103c5d <acquire>
801037cf:	83 c4 10             	add    $0x10,%esp
}
801037d2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801037d5:	5b                   	pop    %ebx
801037d6:	5e                   	pop    %esi
801037d7:	5d                   	pop    %ebp
801037d8:	c3                   	ret    
    panic("sleep");
801037d9:	83 ec 0c             	sub    $0xc,%esp
801037dc:	68 69 6b 10 80       	push   $0x80106b69
801037e1:	e8 62 cb ff ff       	call   80100348 <panic>
    panic("sleep without lk");
801037e6:	83 ec 0c             	sub    $0xc,%esp
801037e9:	68 6f 6b 10 80       	push   $0x80106b6f
801037ee:	e8 55 cb ff ff       	call   80100348 <panic>

801037f3 <wait>:
{
801037f3:	55                   	push   %ebp
801037f4:	89 e5                	mov    %esp,%ebp
801037f6:	56                   	push   %esi
801037f7:	53                   	push   %ebx
  struct proc *curproc = myproc();
801037f8:	e8 c1 fa ff ff       	call   801032be <myproc>
801037fd:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
801037ff:	83 ec 0c             	sub    $0xc,%esp
80103802:	68 60 1d 13 80       	push   $0x80131d60
80103807:	e8 51 04 00 00       	call   80103c5d <acquire>
8010380c:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
8010380f:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103814:	bb 94 1d 13 80       	mov    $0x80131d94,%ebx
80103819:	eb 5b                	jmp    80103876 <wait+0x83>
        pid = p->pid;
8010381b:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
8010381e:	83 ec 0c             	sub    $0xc,%esp
80103821:	ff 73 08             	pushl  0x8(%ebx)
80103824:	e8 7b e7 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
80103829:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103830:	83 c4 04             	add    $0x4,%esp
80103833:	ff 73 04             	pushl  0x4(%ebx)
80103836:	e8 70 2a 00 00       	call   801062ab <freevm>
        p->pid = 0;
8010383b:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103842:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103849:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
8010384d:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
80103854:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
8010385b:	c7 04 24 60 1d 13 80 	movl   $0x80131d60,(%esp)
80103862:	e8 5b 04 00 00       	call   80103cc2 <release>
        return pid;
80103867:	83 c4 10             	add    $0x10,%esp
}
8010386a:	89 f0                	mov    %esi,%eax
8010386c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010386f:	5b                   	pop    %ebx
80103870:	5e                   	pop    %esi
80103871:	5d                   	pop    %ebp
80103872:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103873:	83 c3 7c             	add    $0x7c,%ebx
80103876:	81 fb 94 3c 13 80    	cmp    $0x80133c94,%ebx
8010387c:	73 12                	jae    80103890 <wait+0x9d>
      if(p->parent != curproc)
8010387e:	39 73 14             	cmp    %esi,0x14(%ebx)
80103881:	75 f0                	jne    80103873 <wait+0x80>
      if(p->state == ZOMBIE){
80103883:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103887:	74 92                	je     8010381b <wait+0x28>
      havekids = 1;
80103889:	b8 01 00 00 00       	mov    $0x1,%eax
8010388e:	eb e3                	jmp    80103873 <wait+0x80>
    if(!havekids || curproc->killed){
80103890:	85 c0                	test   %eax,%eax
80103892:	74 06                	je     8010389a <wait+0xa7>
80103894:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103898:	74 17                	je     801038b1 <wait+0xbe>
      release(&ptable.lock);
8010389a:	83 ec 0c             	sub    $0xc,%esp
8010389d:	68 60 1d 13 80       	push   $0x80131d60
801038a2:	e8 1b 04 00 00       	call   80103cc2 <release>
      return -1;
801038a7:	83 c4 10             	add    $0x10,%esp
801038aa:	be ff ff ff ff       	mov    $0xffffffff,%esi
801038af:	eb b9                	jmp    8010386a <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
801038b1:	83 ec 08             	sub    $0x8,%esp
801038b4:	68 60 1d 13 80       	push   $0x80131d60
801038b9:	56                   	push   %esi
801038ba:	e8 a3 fe ff ff       	call   80103762 <sleep>
    havekids = 0;
801038bf:	83 c4 10             	add    $0x10,%esp
801038c2:	e9 48 ff ff ff       	jmp    8010380f <wait+0x1c>

801038c7 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
801038c7:	55                   	push   %ebp
801038c8:	89 e5                	mov    %esp,%ebp
801038ca:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
801038cd:	68 60 1d 13 80       	push   $0x80131d60
801038d2:	e8 86 03 00 00       	call   80103c5d <acquire>
  wakeup1(chan);
801038d7:	8b 45 08             	mov    0x8(%ebp),%eax
801038da:	e8 1f f8 ff ff       	call   801030fe <wakeup1>
  release(&ptable.lock);
801038df:	c7 04 24 60 1d 13 80 	movl   $0x80131d60,(%esp)
801038e6:	e8 d7 03 00 00       	call   80103cc2 <release>
}
801038eb:	83 c4 10             	add    $0x10,%esp
801038ee:	c9                   	leave  
801038ef:	c3                   	ret    

801038f0 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
801038f0:	55                   	push   %ebp
801038f1:	89 e5                	mov    %esp,%ebp
801038f3:	53                   	push   %ebx
801038f4:	83 ec 10             	sub    $0x10,%esp
801038f7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
801038fa:	68 60 1d 13 80       	push   $0x80131d60
801038ff:	e8 59 03 00 00       	call   80103c5d <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103904:	83 c4 10             	add    $0x10,%esp
80103907:	b8 94 1d 13 80       	mov    $0x80131d94,%eax
8010390c:	3d 94 3c 13 80       	cmp    $0x80133c94,%eax
80103911:	73 3a                	jae    8010394d <kill+0x5d>
    if(p->pid == pid){
80103913:	39 58 10             	cmp    %ebx,0x10(%eax)
80103916:	74 05                	je     8010391d <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103918:	83 c0 7c             	add    $0x7c,%eax
8010391b:	eb ef                	jmp    8010390c <kill+0x1c>
      p->killed = 1;
8010391d:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103924:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103928:	74 1a                	je     80103944 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
8010392a:	83 ec 0c             	sub    $0xc,%esp
8010392d:	68 60 1d 13 80       	push   $0x80131d60
80103932:	e8 8b 03 00 00       	call   80103cc2 <release>
      return 0;
80103937:	83 c4 10             	add    $0x10,%esp
8010393a:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
8010393f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103942:	c9                   	leave  
80103943:	c3                   	ret    
        p->state = RUNNABLE;
80103944:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
8010394b:	eb dd                	jmp    8010392a <kill+0x3a>
  release(&ptable.lock);
8010394d:	83 ec 0c             	sub    $0xc,%esp
80103950:	68 60 1d 13 80       	push   $0x80131d60
80103955:	e8 68 03 00 00       	call   80103cc2 <release>
  return -1;
8010395a:	83 c4 10             	add    $0x10,%esp
8010395d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103962:	eb db                	jmp    8010393f <kill+0x4f>

80103964 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103964:	55                   	push   %ebp
80103965:	89 e5                	mov    %esp,%ebp
80103967:	56                   	push   %esi
80103968:	53                   	push   %ebx
80103969:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010396c:	bb 94 1d 13 80       	mov    $0x80131d94,%ebx
80103971:	eb 33                	jmp    801039a6 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103973:	b8 80 6b 10 80       	mov    $0x80106b80,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103978:	8d 53 6c             	lea    0x6c(%ebx),%edx
8010397b:	52                   	push   %edx
8010397c:	50                   	push   %eax
8010397d:	ff 73 10             	pushl  0x10(%ebx)
80103980:	68 84 6b 10 80       	push   $0x80106b84
80103985:	e8 81 cc ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
8010398a:	83 c4 10             	add    $0x10,%esp
8010398d:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103991:	74 39                	je     801039cc <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103993:	83 ec 0c             	sub    $0xc,%esp
80103996:	68 fb 6e 10 80       	push   $0x80106efb
8010399b:	e8 6b cc ff ff       	call   8010060b <cprintf>
801039a0:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039a3:	83 c3 7c             	add    $0x7c,%ebx
801039a6:	81 fb 94 3c 13 80    	cmp    $0x80133c94,%ebx
801039ac:	73 61                	jae    80103a0f <procdump+0xab>
    if(p->state == UNUSED)
801039ae:	8b 43 0c             	mov    0xc(%ebx),%eax
801039b1:	85 c0                	test   %eax,%eax
801039b3:	74 ee                	je     801039a3 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801039b5:	83 f8 05             	cmp    $0x5,%eax
801039b8:	77 b9                	ja     80103973 <procdump+0xf>
801039ba:	8b 04 85 e0 6b 10 80 	mov    -0x7fef9420(,%eax,4),%eax
801039c1:	85 c0                	test   %eax,%eax
801039c3:	75 b3                	jne    80103978 <procdump+0x14>
      state = "???";
801039c5:	b8 80 6b 10 80       	mov    $0x80106b80,%eax
801039ca:	eb ac                	jmp    80103978 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
801039cc:	8b 43 1c             	mov    0x1c(%ebx),%eax
801039cf:	8b 40 0c             	mov    0xc(%eax),%eax
801039d2:	83 c0 08             	add    $0x8,%eax
801039d5:	83 ec 08             	sub    $0x8,%esp
801039d8:	8d 55 d0             	lea    -0x30(%ebp),%edx
801039db:	52                   	push   %edx
801039dc:	50                   	push   %eax
801039dd:	e8 5a 01 00 00       	call   80103b3c <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
801039e2:	83 c4 10             	add    $0x10,%esp
801039e5:	be 00 00 00 00       	mov    $0x0,%esi
801039ea:	eb 14                	jmp    80103a00 <procdump+0x9c>
        cprintf(" %p", pc[i]);
801039ec:	83 ec 08             	sub    $0x8,%esp
801039ef:	50                   	push   %eax
801039f0:	68 c1 65 10 80       	push   $0x801065c1
801039f5:	e8 11 cc ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
801039fa:	83 c6 01             	add    $0x1,%esi
801039fd:	83 c4 10             	add    $0x10,%esp
80103a00:	83 fe 09             	cmp    $0x9,%esi
80103a03:	7f 8e                	jg     80103993 <procdump+0x2f>
80103a05:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103a09:	85 c0                	test   %eax,%eax
80103a0b:	75 df                	jne    801039ec <procdump+0x88>
80103a0d:	eb 84                	jmp    80103993 <procdump+0x2f>
  }
}
80103a0f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a12:	5b                   	pop    %ebx
80103a13:	5e                   	pop    %esi
80103a14:	5d                   	pop    %ebp
80103a15:	c3                   	ret    

80103a16 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103a16:	55                   	push   %ebp
80103a17:	89 e5                	mov    %esp,%ebp
80103a19:	53                   	push   %ebx
80103a1a:	83 ec 0c             	sub    $0xc,%esp
80103a1d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103a20:	68 f8 6b 10 80       	push   $0x80106bf8
80103a25:	8d 43 04             	lea    0x4(%ebx),%eax
80103a28:	50                   	push   %eax
80103a29:	e8 f3 00 00 00       	call   80103b21 <initlock>
  lk->name = name;
80103a2e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a31:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103a34:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103a3a:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103a41:	83 c4 10             	add    $0x10,%esp
80103a44:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103a47:	c9                   	leave  
80103a48:	c3                   	ret    

80103a49 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103a49:	55                   	push   %ebp
80103a4a:	89 e5                	mov    %esp,%ebp
80103a4c:	56                   	push   %esi
80103a4d:	53                   	push   %ebx
80103a4e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103a51:	8d 73 04             	lea    0x4(%ebx),%esi
80103a54:	83 ec 0c             	sub    $0xc,%esp
80103a57:	56                   	push   %esi
80103a58:	e8 00 02 00 00       	call   80103c5d <acquire>
  while (lk->locked) {
80103a5d:	83 c4 10             	add    $0x10,%esp
80103a60:	eb 0d                	jmp    80103a6f <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103a62:	83 ec 08             	sub    $0x8,%esp
80103a65:	56                   	push   %esi
80103a66:	53                   	push   %ebx
80103a67:	e8 f6 fc ff ff       	call   80103762 <sleep>
80103a6c:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103a6f:	83 3b 00             	cmpl   $0x0,(%ebx)
80103a72:	75 ee                	jne    80103a62 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103a74:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103a7a:	e8 3f f8 ff ff       	call   801032be <myproc>
80103a7f:	8b 40 10             	mov    0x10(%eax),%eax
80103a82:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103a85:	83 ec 0c             	sub    $0xc,%esp
80103a88:	56                   	push   %esi
80103a89:	e8 34 02 00 00       	call   80103cc2 <release>
}
80103a8e:	83 c4 10             	add    $0x10,%esp
80103a91:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a94:	5b                   	pop    %ebx
80103a95:	5e                   	pop    %esi
80103a96:	5d                   	pop    %ebp
80103a97:	c3                   	ret    

80103a98 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103a98:	55                   	push   %ebp
80103a99:	89 e5                	mov    %esp,%ebp
80103a9b:	56                   	push   %esi
80103a9c:	53                   	push   %ebx
80103a9d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103aa0:	8d 73 04             	lea    0x4(%ebx),%esi
80103aa3:	83 ec 0c             	sub    $0xc,%esp
80103aa6:	56                   	push   %esi
80103aa7:	e8 b1 01 00 00       	call   80103c5d <acquire>
  lk->locked = 0;
80103aac:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103ab2:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103ab9:	89 1c 24             	mov    %ebx,(%esp)
80103abc:	e8 06 fe ff ff       	call   801038c7 <wakeup>
  release(&lk->lk);
80103ac1:	89 34 24             	mov    %esi,(%esp)
80103ac4:	e8 f9 01 00 00       	call   80103cc2 <release>
}
80103ac9:	83 c4 10             	add    $0x10,%esp
80103acc:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103acf:	5b                   	pop    %ebx
80103ad0:	5e                   	pop    %esi
80103ad1:	5d                   	pop    %ebp
80103ad2:	c3                   	ret    

80103ad3 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103ad3:	55                   	push   %ebp
80103ad4:	89 e5                	mov    %esp,%ebp
80103ad6:	56                   	push   %esi
80103ad7:	53                   	push   %ebx
80103ad8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103adb:	8d 73 04             	lea    0x4(%ebx),%esi
80103ade:	83 ec 0c             	sub    $0xc,%esp
80103ae1:	56                   	push   %esi
80103ae2:	e8 76 01 00 00       	call   80103c5d <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103ae7:	83 c4 10             	add    $0x10,%esp
80103aea:	83 3b 00             	cmpl   $0x0,(%ebx)
80103aed:	75 17                	jne    80103b06 <holdingsleep+0x33>
80103aef:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103af4:	83 ec 0c             	sub    $0xc,%esp
80103af7:	56                   	push   %esi
80103af8:	e8 c5 01 00 00       	call   80103cc2 <release>
  return r;
}
80103afd:	89 d8                	mov    %ebx,%eax
80103aff:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b02:	5b                   	pop    %ebx
80103b03:	5e                   	pop    %esi
80103b04:	5d                   	pop    %ebp
80103b05:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103b06:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103b09:	e8 b0 f7 ff ff       	call   801032be <myproc>
80103b0e:	3b 58 10             	cmp    0x10(%eax),%ebx
80103b11:	74 07                	je     80103b1a <holdingsleep+0x47>
80103b13:	bb 00 00 00 00       	mov    $0x0,%ebx
80103b18:	eb da                	jmp    80103af4 <holdingsleep+0x21>
80103b1a:	bb 01 00 00 00       	mov    $0x1,%ebx
80103b1f:	eb d3                	jmp    80103af4 <holdingsleep+0x21>

80103b21 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103b21:	55                   	push   %ebp
80103b22:	89 e5                	mov    %esp,%ebp
80103b24:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103b27:	8b 55 0c             	mov    0xc(%ebp),%edx
80103b2a:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103b2d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103b33:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103b3a:	5d                   	pop    %ebp
80103b3b:	c3                   	ret    

80103b3c <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103b3c:	55                   	push   %ebp
80103b3d:	89 e5                	mov    %esp,%ebp
80103b3f:	53                   	push   %ebx
80103b40:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103b43:	8b 45 08             	mov    0x8(%ebp),%eax
80103b46:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103b49:	b8 00 00 00 00       	mov    $0x0,%eax
80103b4e:	83 f8 09             	cmp    $0x9,%eax
80103b51:	7f 25                	jg     80103b78 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103b53:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103b59:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103b5f:	77 17                	ja     80103b78 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103b61:	8b 5a 04             	mov    0x4(%edx),%ebx
80103b64:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103b67:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103b69:	83 c0 01             	add    $0x1,%eax
80103b6c:	eb e0                	jmp    80103b4e <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103b6e:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103b75:	83 c0 01             	add    $0x1,%eax
80103b78:	83 f8 09             	cmp    $0x9,%eax
80103b7b:	7e f1                	jle    80103b6e <getcallerpcs+0x32>
}
80103b7d:	5b                   	pop    %ebx
80103b7e:	5d                   	pop    %ebp
80103b7f:	c3                   	ret    

80103b80 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103b80:	55                   	push   %ebp
80103b81:	89 e5                	mov    %esp,%ebp
80103b83:	53                   	push   %ebx
80103b84:	83 ec 04             	sub    $0x4,%esp
80103b87:	9c                   	pushf  
80103b88:	5b                   	pop    %ebx
  asm volatile("cli");
80103b89:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103b8a:	e8 b8 f6 ff ff       	call   80103247 <mycpu>
80103b8f:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103b96:	74 12                	je     80103baa <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103b98:	e8 aa f6 ff ff       	call   80103247 <mycpu>
80103b9d:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103ba4:	83 c4 04             	add    $0x4,%esp
80103ba7:	5b                   	pop    %ebx
80103ba8:	5d                   	pop    %ebp
80103ba9:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103baa:	e8 98 f6 ff ff       	call   80103247 <mycpu>
80103baf:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103bb5:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103bbb:	eb db                	jmp    80103b98 <pushcli+0x18>

80103bbd <popcli>:

void
popcli(void)
{
80103bbd:	55                   	push   %ebp
80103bbe:	89 e5                	mov    %esp,%ebp
80103bc0:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103bc3:	9c                   	pushf  
80103bc4:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103bc5:	f6 c4 02             	test   $0x2,%ah
80103bc8:	75 28                	jne    80103bf2 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103bca:	e8 78 f6 ff ff       	call   80103247 <mycpu>
80103bcf:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103bd5:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103bd8:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103bde:	85 d2                	test   %edx,%edx
80103be0:	78 1d                	js     80103bff <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103be2:	e8 60 f6 ff ff       	call   80103247 <mycpu>
80103be7:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103bee:	74 1c                	je     80103c0c <popcli+0x4f>
    sti();
}
80103bf0:	c9                   	leave  
80103bf1:	c3                   	ret    
    panic("popcli - interruptible");
80103bf2:	83 ec 0c             	sub    $0xc,%esp
80103bf5:	68 03 6c 10 80       	push   $0x80106c03
80103bfa:	e8 49 c7 ff ff       	call   80100348 <panic>
    panic("popcli");
80103bff:	83 ec 0c             	sub    $0xc,%esp
80103c02:	68 1a 6c 10 80       	push   $0x80106c1a
80103c07:	e8 3c c7 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c0c:	e8 36 f6 ff ff       	call   80103247 <mycpu>
80103c11:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103c18:	74 d6                	je     80103bf0 <popcli+0x33>
  asm volatile("sti");
80103c1a:	fb                   	sti    
}
80103c1b:	eb d3                	jmp    80103bf0 <popcli+0x33>

80103c1d <holding>:
{
80103c1d:	55                   	push   %ebp
80103c1e:	89 e5                	mov    %esp,%ebp
80103c20:	53                   	push   %ebx
80103c21:	83 ec 04             	sub    $0x4,%esp
80103c24:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103c27:	e8 54 ff ff ff       	call   80103b80 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103c2c:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c2f:	75 12                	jne    80103c43 <holding+0x26>
80103c31:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103c36:	e8 82 ff ff ff       	call   80103bbd <popcli>
}
80103c3b:	89 d8                	mov    %ebx,%eax
80103c3d:	83 c4 04             	add    $0x4,%esp
80103c40:	5b                   	pop    %ebx
80103c41:	5d                   	pop    %ebp
80103c42:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103c43:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103c46:	e8 fc f5 ff ff       	call   80103247 <mycpu>
80103c4b:	39 c3                	cmp    %eax,%ebx
80103c4d:	74 07                	je     80103c56 <holding+0x39>
80103c4f:	bb 00 00 00 00       	mov    $0x0,%ebx
80103c54:	eb e0                	jmp    80103c36 <holding+0x19>
80103c56:	bb 01 00 00 00       	mov    $0x1,%ebx
80103c5b:	eb d9                	jmp    80103c36 <holding+0x19>

80103c5d <acquire>:
{
80103c5d:	55                   	push   %ebp
80103c5e:	89 e5                	mov    %esp,%ebp
80103c60:	53                   	push   %ebx
80103c61:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103c64:	e8 17 ff ff ff       	call   80103b80 <pushcli>
  if(holding(lk))
80103c69:	83 ec 0c             	sub    $0xc,%esp
80103c6c:	ff 75 08             	pushl  0x8(%ebp)
80103c6f:	e8 a9 ff ff ff       	call   80103c1d <holding>
80103c74:	83 c4 10             	add    $0x10,%esp
80103c77:	85 c0                	test   %eax,%eax
80103c79:	75 3a                	jne    80103cb5 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103c7b:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103c7e:	b8 01 00 00 00       	mov    $0x1,%eax
80103c83:	f0 87 02             	lock xchg %eax,(%edx)
80103c86:	85 c0                	test   %eax,%eax
80103c88:	75 f1                	jne    80103c7b <acquire+0x1e>
  __sync_synchronize();
80103c8a:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103c8f:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103c92:	e8 b0 f5 ff ff       	call   80103247 <mycpu>
80103c97:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103c9a:	8b 45 08             	mov    0x8(%ebp),%eax
80103c9d:	83 c0 0c             	add    $0xc,%eax
80103ca0:	83 ec 08             	sub    $0x8,%esp
80103ca3:	50                   	push   %eax
80103ca4:	8d 45 08             	lea    0x8(%ebp),%eax
80103ca7:	50                   	push   %eax
80103ca8:	e8 8f fe ff ff       	call   80103b3c <getcallerpcs>
}
80103cad:	83 c4 10             	add    $0x10,%esp
80103cb0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103cb3:	c9                   	leave  
80103cb4:	c3                   	ret    
    panic("acquire");
80103cb5:	83 ec 0c             	sub    $0xc,%esp
80103cb8:	68 21 6c 10 80       	push   $0x80106c21
80103cbd:	e8 86 c6 ff ff       	call   80100348 <panic>

80103cc2 <release>:
{
80103cc2:	55                   	push   %ebp
80103cc3:	89 e5                	mov    %esp,%ebp
80103cc5:	53                   	push   %ebx
80103cc6:	83 ec 10             	sub    $0x10,%esp
80103cc9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103ccc:	53                   	push   %ebx
80103ccd:	e8 4b ff ff ff       	call   80103c1d <holding>
80103cd2:	83 c4 10             	add    $0x10,%esp
80103cd5:	85 c0                	test   %eax,%eax
80103cd7:	74 23                	je     80103cfc <release+0x3a>
  lk->pcs[0] = 0;
80103cd9:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103ce0:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103ce7:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103cec:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103cf2:	e8 c6 fe ff ff       	call   80103bbd <popcli>
}
80103cf7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103cfa:	c9                   	leave  
80103cfb:	c3                   	ret    
    panic("release");
80103cfc:	83 ec 0c             	sub    $0xc,%esp
80103cff:	68 29 6c 10 80       	push   $0x80106c29
80103d04:	e8 3f c6 ff ff       	call   80100348 <panic>

80103d09 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103d09:	55                   	push   %ebp
80103d0a:	89 e5                	mov    %esp,%ebp
80103d0c:	57                   	push   %edi
80103d0d:	53                   	push   %ebx
80103d0e:	8b 55 08             	mov    0x8(%ebp),%edx
80103d11:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103d14:	f6 c2 03             	test   $0x3,%dl
80103d17:	75 05                	jne    80103d1e <memset+0x15>
80103d19:	f6 c1 03             	test   $0x3,%cl
80103d1c:	74 0e                	je     80103d2c <memset+0x23>
  asm volatile("cld; rep stosb" :
80103d1e:	89 d7                	mov    %edx,%edi
80103d20:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d23:	fc                   	cld    
80103d24:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103d26:	89 d0                	mov    %edx,%eax
80103d28:	5b                   	pop    %ebx
80103d29:	5f                   	pop    %edi
80103d2a:	5d                   	pop    %ebp
80103d2b:	c3                   	ret    
    c &= 0xFF;
80103d2c:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103d30:	c1 e9 02             	shr    $0x2,%ecx
80103d33:	89 f8                	mov    %edi,%eax
80103d35:	c1 e0 18             	shl    $0x18,%eax
80103d38:	89 fb                	mov    %edi,%ebx
80103d3a:	c1 e3 10             	shl    $0x10,%ebx
80103d3d:	09 d8                	or     %ebx,%eax
80103d3f:	89 fb                	mov    %edi,%ebx
80103d41:	c1 e3 08             	shl    $0x8,%ebx
80103d44:	09 d8                	or     %ebx,%eax
80103d46:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103d48:	89 d7                	mov    %edx,%edi
80103d4a:	fc                   	cld    
80103d4b:	f3 ab                	rep stos %eax,%es:(%edi)
80103d4d:	eb d7                	jmp    80103d26 <memset+0x1d>

80103d4f <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103d4f:	55                   	push   %ebp
80103d50:	89 e5                	mov    %esp,%ebp
80103d52:	56                   	push   %esi
80103d53:	53                   	push   %ebx
80103d54:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103d57:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d5a:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103d5d:	8d 70 ff             	lea    -0x1(%eax),%esi
80103d60:	85 c0                	test   %eax,%eax
80103d62:	74 1c                	je     80103d80 <memcmp+0x31>
    if(*s1 != *s2)
80103d64:	0f b6 01             	movzbl (%ecx),%eax
80103d67:	0f b6 1a             	movzbl (%edx),%ebx
80103d6a:	38 d8                	cmp    %bl,%al
80103d6c:	75 0a                	jne    80103d78 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103d6e:	83 c1 01             	add    $0x1,%ecx
80103d71:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103d74:	89 f0                	mov    %esi,%eax
80103d76:	eb e5                	jmp    80103d5d <memcmp+0xe>
      return *s1 - *s2;
80103d78:	0f b6 c0             	movzbl %al,%eax
80103d7b:	0f b6 db             	movzbl %bl,%ebx
80103d7e:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103d80:	5b                   	pop    %ebx
80103d81:	5e                   	pop    %esi
80103d82:	5d                   	pop    %ebp
80103d83:	c3                   	ret    

80103d84 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103d84:	55                   	push   %ebp
80103d85:	89 e5                	mov    %esp,%ebp
80103d87:	56                   	push   %esi
80103d88:	53                   	push   %ebx
80103d89:	8b 45 08             	mov    0x8(%ebp),%eax
80103d8c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103d8f:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103d92:	39 c1                	cmp    %eax,%ecx
80103d94:	73 3a                	jae    80103dd0 <memmove+0x4c>
80103d96:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103d99:	39 c3                	cmp    %eax,%ebx
80103d9b:	76 37                	jbe    80103dd4 <memmove+0x50>
    s += n;
    d += n;
80103d9d:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103da0:	eb 0d                	jmp    80103daf <memmove+0x2b>
      *--d = *--s;
80103da2:	83 eb 01             	sub    $0x1,%ebx
80103da5:	83 e9 01             	sub    $0x1,%ecx
80103da8:	0f b6 13             	movzbl (%ebx),%edx
80103dab:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103dad:	89 f2                	mov    %esi,%edx
80103daf:	8d 72 ff             	lea    -0x1(%edx),%esi
80103db2:	85 d2                	test   %edx,%edx
80103db4:	75 ec                	jne    80103da2 <memmove+0x1e>
80103db6:	eb 14                	jmp    80103dcc <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103db8:	0f b6 11             	movzbl (%ecx),%edx
80103dbb:	88 13                	mov    %dl,(%ebx)
80103dbd:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103dc0:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103dc3:	89 f2                	mov    %esi,%edx
80103dc5:	8d 72 ff             	lea    -0x1(%edx),%esi
80103dc8:	85 d2                	test   %edx,%edx
80103dca:	75 ec                	jne    80103db8 <memmove+0x34>

  return dst;
}
80103dcc:	5b                   	pop    %ebx
80103dcd:	5e                   	pop    %esi
80103dce:	5d                   	pop    %ebp
80103dcf:	c3                   	ret    
80103dd0:	89 c3                	mov    %eax,%ebx
80103dd2:	eb f1                	jmp    80103dc5 <memmove+0x41>
80103dd4:	89 c3                	mov    %eax,%ebx
80103dd6:	eb ed                	jmp    80103dc5 <memmove+0x41>

80103dd8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103dd8:	55                   	push   %ebp
80103dd9:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103ddb:	ff 75 10             	pushl  0x10(%ebp)
80103dde:	ff 75 0c             	pushl  0xc(%ebp)
80103de1:	ff 75 08             	pushl  0x8(%ebp)
80103de4:	e8 9b ff ff ff       	call   80103d84 <memmove>
}
80103de9:	c9                   	leave  
80103dea:	c3                   	ret    

80103deb <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103deb:	55                   	push   %ebp
80103dec:	89 e5                	mov    %esp,%ebp
80103dee:	53                   	push   %ebx
80103def:	8b 55 08             	mov    0x8(%ebp),%edx
80103df2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103df5:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103df8:	eb 09                	jmp    80103e03 <strncmp+0x18>
    n--, p++, q++;
80103dfa:	83 e8 01             	sub    $0x1,%eax
80103dfd:	83 c2 01             	add    $0x1,%edx
80103e00:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103e03:	85 c0                	test   %eax,%eax
80103e05:	74 0b                	je     80103e12 <strncmp+0x27>
80103e07:	0f b6 1a             	movzbl (%edx),%ebx
80103e0a:	84 db                	test   %bl,%bl
80103e0c:	74 04                	je     80103e12 <strncmp+0x27>
80103e0e:	3a 19                	cmp    (%ecx),%bl
80103e10:	74 e8                	je     80103dfa <strncmp+0xf>
  if(n == 0)
80103e12:	85 c0                	test   %eax,%eax
80103e14:	74 0b                	je     80103e21 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103e16:	0f b6 02             	movzbl (%edx),%eax
80103e19:	0f b6 11             	movzbl (%ecx),%edx
80103e1c:	29 d0                	sub    %edx,%eax
}
80103e1e:	5b                   	pop    %ebx
80103e1f:	5d                   	pop    %ebp
80103e20:	c3                   	ret    
    return 0;
80103e21:	b8 00 00 00 00       	mov    $0x0,%eax
80103e26:	eb f6                	jmp    80103e1e <strncmp+0x33>

80103e28 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103e28:	55                   	push   %ebp
80103e29:	89 e5                	mov    %esp,%ebp
80103e2b:	57                   	push   %edi
80103e2c:	56                   	push   %esi
80103e2d:	53                   	push   %ebx
80103e2e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103e31:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103e34:	8b 45 08             	mov    0x8(%ebp),%eax
80103e37:	eb 04                	jmp    80103e3d <strncpy+0x15>
80103e39:	89 fb                	mov    %edi,%ebx
80103e3b:	89 f0                	mov    %esi,%eax
80103e3d:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103e40:	85 c9                	test   %ecx,%ecx
80103e42:	7e 1d                	jle    80103e61 <strncpy+0x39>
80103e44:	8d 7b 01             	lea    0x1(%ebx),%edi
80103e47:	8d 70 01             	lea    0x1(%eax),%esi
80103e4a:	0f b6 1b             	movzbl (%ebx),%ebx
80103e4d:	88 18                	mov    %bl,(%eax)
80103e4f:	89 d1                	mov    %edx,%ecx
80103e51:	84 db                	test   %bl,%bl
80103e53:	75 e4                	jne    80103e39 <strncpy+0x11>
80103e55:	89 f0                	mov    %esi,%eax
80103e57:	eb 08                	jmp    80103e61 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103e59:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103e5c:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103e5e:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103e61:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103e64:	85 d2                	test   %edx,%edx
80103e66:	7f f1                	jg     80103e59 <strncpy+0x31>
  return os;
}
80103e68:	8b 45 08             	mov    0x8(%ebp),%eax
80103e6b:	5b                   	pop    %ebx
80103e6c:	5e                   	pop    %esi
80103e6d:	5f                   	pop    %edi
80103e6e:	5d                   	pop    %ebp
80103e6f:	c3                   	ret    

80103e70 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103e70:	55                   	push   %ebp
80103e71:	89 e5                	mov    %esp,%ebp
80103e73:	57                   	push   %edi
80103e74:	56                   	push   %esi
80103e75:	53                   	push   %ebx
80103e76:	8b 45 08             	mov    0x8(%ebp),%eax
80103e79:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103e7c:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103e7f:	85 d2                	test   %edx,%edx
80103e81:	7e 23                	jle    80103ea6 <safestrcpy+0x36>
80103e83:	89 c1                	mov    %eax,%ecx
80103e85:	eb 04                	jmp    80103e8b <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103e87:	89 fb                	mov    %edi,%ebx
80103e89:	89 f1                	mov    %esi,%ecx
80103e8b:	83 ea 01             	sub    $0x1,%edx
80103e8e:	85 d2                	test   %edx,%edx
80103e90:	7e 11                	jle    80103ea3 <safestrcpy+0x33>
80103e92:	8d 7b 01             	lea    0x1(%ebx),%edi
80103e95:	8d 71 01             	lea    0x1(%ecx),%esi
80103e98:	0f b6 1b             	movzbl (%ebx),%ebx
80103e9b:	88 19                	mov    %bl,(%ecx)
80103e9d:	84 db                	test   %bl,%bl
80103e9f:	75 e6                	jne    80103e87 <safestrcpy+0x17>
80103ea1:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103ea3:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103ea6:	5b                   	pop    %ebx
80103ea7:	5e                   	pop    %esi
80103ea8:	5f                   	pop    %edi
80103ea9:	5d                   	pop    %ebp
80103eaa:	c3                   	ret    

80103eab <strlen>:

int
strlen(const char *s)
{
80103eab:	55                   	push   %ebp
80103eac:	89 e5                	mov    %esp,%ebp
80103eae:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103eb1:	b8 00 00 00 00       	mov    $0x0,%eax
80103eb6:	eb 03                	jmp    80103ebb <strlen+0x10>
80103eb8:	83 c0 01             	add    $0x1,%eax
80103ebb:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103ebf:	75 f7                	jne    80103eb8 <strlen+0xd>
    ;
  return n;
}
80103ec1:	5d                   	pop    %ebp
80103ec2:	c3                   	ret    

80103ec3 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103ec3:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103ec7:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103ecb:	55                   	push   %ebp
  pushl %ebx
80103ecc:	53                   	push   %ebx
  pushl %esi
80103ecd:	56                   	push   %esi
  pushl %edi
80103ece:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103ecf:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103ed1:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103ed3:	5f                   	pop    %edi
  popl %esi
80103ed4:	5e                   	pop    %esi
  popl %ebx
80103ed5:	5b                   	pop    %ebx
  popl %ebp
80103ed6:	5d                   	pop    %ebp
  ret
80103ed7:	c3                   	ret    

80103ed8 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103ed8:	55                   	push   %ebp
80103ed9:	89 e5                	mov    %esp,%ebp
80103edb:	53                   	push   %ebx
80103edc:	83 ec 04             	sub    $0x4,%esp
80103edf:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103ee2:	e8 d7 f3 ff ff       	call   801032be <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103ee7:	8b 00                	mov    (%eax),%eax
80103ee9:	39 d8                	cmp    %ebx,%eax
80103eeb:	76 19                	jbe    80103f06 <fetchint+0x2e>
80103eed:	8d 53 04             	lea    0x4(%ebx),%edx
80103ef0:	39 d0                	cmp    %edx,%eax
80103ef2:	72 19                	jb     80103f0d <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103ef4:	8b 13                	mov    (%ebx),%edx
80103ef6:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ef9:	89 10                	mov    %edx,(%eax)
  return 0;
80103efb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f00:	83 c4 04             	add    $0x4,%esp
80103f03:	5b                   	pop    %ebx
80103f04:	5d                   	pop    %ebp
80103f05:	c3                   	ret    
    return -1;
80103f06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f0b:	eb f3                	jmp    80103f00 <fetchint+0x28>
80103f0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f12:	eb ec                	jmp    80103f00 <fetchint+0x28>

80103f14 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103f14:	55                   	push   %ebp
80103f15:	89 e5                	mov    %esp,%ebp
80103f17:	53                   	push   %ebx
80103f18:	83 ec 04             	sub    $0x4,%esp
80103f1b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103f1e:	e8 9b f3 ff ff       	call   801032be <myproc>

  if(addr >= curproc->sz)
80103f23:	39 18                	cmp    %ebx,(%eax)
80103f25:	76 26                	jbe    80103f4d <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80103f27:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f2a:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103f2c:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103f2e:	89 d8                	mov    %ebx,%eax
80103f30:	39 d0                	cmp    %edx,%eax
80103f32:	73 0e                	jae    80103f42 <fetchstr+0x2e>
    if(*s == 0)
80103f34:	80 38 00             	cmpb   $0x0,(%eax)
80103f37:	74 05                	je     80103f3e <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80103f39:	83 c0 01             	add    $0x1,%eax
80103f3c:	eb f2                	jmp    80103f30 <fetchstr+0x1c>
      return s - *pp;
80103f3e:	29 d8                	sub    %ebx,%eax
80103f40:	eb 05                	jmp    80103f47 <fetchstr+0x33>
  }
  return -1;
80103f42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103f47:	83 c4 04             	add    $0x4,%esp
80103f4a:	5b                   	pop    %ebx
80103f4b:	5d                   	pop    %ebp
80103f4c:	c3                   	ret    
    return -1;
80103f4d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f52:	eb f3                	jmp    80103f47 <fetchstr+0x33>

80103f54 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80103f54:	55                   	push   %ebp
80103f55:	89 e5                	mov    %esp,%ebp
80103f57:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80103f5a:	e8 5f f3 ff ff       	call   801032be <myproc>
80103f5f:	8b 50 18             	mov    0x18(%eax),%edx
80103f62:	8b 45 08             	mov    0x8(%ebp),%eax
80103f65:	c1 e0 02             	shl    $0x2,%eax
80103f68:	03 42 44             	add    0x44(%edx),%eax
80103f6b:	83 ec 08             	sub    $0x8,%esp
80103f6e:	ff 75 0c             	pushl  0xc(%ebp)
80103f71:	83 c0 04             	add    $0x4,%eax
80103f74:	50                   	push   %eax
80103f75:	e8 5e ff ff ff       	call   80103ed8 <fetchint>
}
80103f7a:	c9                   	leave  
80103f7b:	c3                   	ret    

80103f7c <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80103f7c:	55                   	push   %ebp
80103f7d:	89 e5                	mov    %esp,%ebp
80103f7f:	56                   	push   %esi
80103f80:	53                   	push   %ebx
80103f81:	83 ec 10             	sub    $0x10,%esp
80103f84:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80103f87:	e8 32 f3 ff ff       	call   801032be <myproc>
80103f8c:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80103f8e:	83 ec 08             	sub    $0x8,%esp
80103f91:	8d 45 f4             	lea    -0xc(%ebp),%eax
80103f94:	50                   	push   %eax
80103f95:	ff 75 08             	pushl  0x8(%ebp)
80103f98:	e8 b7 ff ff ff       	call   80103f54 <argint>
80103f9d:	83 c4 10             	add    $0x10,%esp
80103fa0:	85 c0                	test   %eax,%eax
80103fa2:	78 24                	js     80103fc8 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80103fa4:	85 db                	test   %ebx,%ebx
80103fa6:	78 27                	js     80103fcf <argptr+0x53>
80103fa8:	8b 16                	mov    (%esi),%edx
80103faa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fad:	39 c2                	cmp    %eax,%edx
80103faf:	76 25                	jbe    80103fd6 <argptr+0x5a>
80103fb1:	01 c3                	add    %eax,%ebx
80103fb3:	39 da                	cmp    %ebx,%edx
80103fb5:	72 26                	jb     80103fdd <argptr+0x61>
    return -1;
  *pp = (char*)i;
80103fb7:	8b 55 0c             	mov    0xc(%ebp),%edx
80103fba:	89 02                	mov    %eax,(%edx)
  return 0;
80103fbc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103fc1:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103fc4:	5b                   	pop    %ebx
80103fc5:	5e                   	pop    %esi
80103fc6:	5d                   	pop    %ebp
80103fc7:	c3                   	ret    
    return -1;
80103fc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fcd:	eb f2                	jmp    80103fc1 <argptr+0x45>
    return -1;
80103fcf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fd4:	eb eb                	jmp    80103fc1 <argptr+0x45>
80103fd6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fdb:	eb e4                	jmp    80103fc1 <argptr+0x45>
80103fdd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fe2:	eb dd                	jmp    80103fc1 <argptr+0x45>

80103fe4 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80103fe4:	55                   	push   %ebp
80103fe5:	89 e5                	mov    %esp,%ebp
80103fe7:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80103fea:	8d 45 f4             	lea    -0xc(%ebp),%eax
80103fed:	50                   	push   %eax
80103fee:	ff 75 08             	pushl  0x8(%ebp)
80103ff1:	e8 5e ff ff ff       	call   80103f54 <argint>
80103ff6:	83 c4 10             	add    $0x10,%esp
80103ff9:	85 c0                	test   %eax,%eax
80103ffb:	78 13                	js     80104010 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
80103ffd:	83 ec 08             	sub    $0x8,%esp
80104000:	ff 75 0c             	pushl  0xc(%ebp)
80104003:	ff 75 f4             	pushl  -0xc(%ebp)
80104006:	e8 09 ff ff ff       	call   80103f14 <fetchstr>
8010400b:	83 c4 10             	add    $0x10,%esp
}
8010400e:	c9                   	leave  
8010400f:	c3                   	ret    
    return -1;
80104010:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104015:	eb f7                	jmp    8010400e <argstr+0x2a>

80104017 <syscall>:
[SYS_dump_physmem]  sys_dump_physmem,
};

void
syscall(void)
{
80104017:	55                   	push   %ebp
80104018:	89 e5                	mov    %esp,%ebp
8010401a:	53                   	push   %ebx
8010401b:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
8010401e:	e8 9b f2 ff ff       	call   801032be <myproc>
80104023:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104025:	8b 40 18             	mov    0x18(%eax),%eax
80104028:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010402b:	8d 50 ff             	lea    -0x1(%eax),%edx
8010402e:	83 fa 15             	cmp    $0x15,%edx
80104031:	77 18                	ja     8010404b <syscall+0x34>
80104033:	8b 14 85 60 6c 10 80 	mov    -0x7fef93a0(,%eax,4),%edx
8010403a:	85 d2                	test   %edx,%edx
8010403c:	74 0d                	je     8010404b <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
8010403e:	ff d2                	call   *%edx
80104040:	8b 53 18             	mov    0x18(%ebx),%edx
80104043:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
80104046:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104049:	c9                   	leave  
8010404a:	c3                   	ret    
            curproc->pid, curproc->name, num);
8010404b:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
8010404e:	50                   	push   %eax
8010404f:	52                   	push   %edx
80104050:	ff 73 10             	pushl  0x10(%ebx)
80104053:	68 31 6c 10 80       	push   $0x80106c31
80104058:	e8 ae c5 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
8010405d:	8b 43 18             	mov    0x18(%ebx),%eax
80104060:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
80104067:	83 c4 10             	add    $0x10,%esp
}
8010406a:	eb da                	jmp    80104046 <syscall+0x2f>

8010406c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010406c:	55                   	push   %ebp
8010406d:	89 e5                	mov    %esp,%ebp
8010406f:	56                   	push   %esi
80104070:	53                   	push   %ebx
80104071:	83 ec 18             	sub    $0x18,%esp
80104074:	89 d6                	mov    %edx,%esi
80104076:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80104078:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010407b:	52                   	push   %edx
8010407c:	50                   	push   %eax
8010407d:	e8 d2 fe ff ff       	call   80103f54 <argint>
80104082:	83 c4 10             	add    $0x10,%esp
80104085:	85 c0                	test   %eax,%eax
80104087:	78 2e                	js     801040b7 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80104089:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
8010408d:	77 2f                	ja     801040be <argfd+0x52>
8010408f:	e8 2a f2 ff ff       	call   801032be <myproc>
80104094:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104097:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
8010409b:	85 c0                	test   %eax,%eax
8010409d:	74 26                	je     801040c5 <argfd+0x59>
    return -1;
  if(pfd)
8010409f:	85 f6                	test   %esi,%esi
801040a1:	74 02                	je     801040a5 <argfd+0x39>
    *pfd = fd;
801040a3:	89 16                	mov    %edx,(%esi)
  if(pf)
801040a5:	85 db                	test   %ebx,%ebx
801040a7:	74 23                	je     801040cc <argfd+0x60>
    *pf = f;
801040a9:	89 03                	mov    %eax,(%ebx)
  return 0;
801040ab:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040b0:	8d 65 f8             	lea    -0x8(%ebp),%esp
801040b3:	5b                   	pop    %ebx
801040b4:	5e                   	pop    %esi
801040b5:	5d                   	pop    %ebp
801040b6:	c3                   	ret    
    return -1;
801040b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040bc:	eb f2                	jmp    801040b0 <argfd+0x44>
    return -1;
801040be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040c3:	eb eb                	jmp    801040b0 <argfd+0x44>
801040c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040ca:	eb e4                	jmp    801040b0 <argfd+0x44>
  return 0;
801040cc:	b8 00 00 00 00       	mov    $0x0,%eax
801040d1:	eb dd                	jmp    801040b0 <argfd+0x44>

801040d3 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801040d3:	55                   	push   %ebp
801040d4:	89 e5                	mov    %esp,%ebp
801040d6:	53                   	push   %ebx
801040d7:	83 ec 04             	sub    $0x4,%esp
801040da:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
801040dc:	e8 dd f1 ff ff       	call   801032be <myproc>

  for(fd = 0; fd < NOFILE; fd++){
801040e1:	ba 00 00 00 00       	mov    $0x0,%edx
801040e6:	83 fa 0f             	cmp    $0xf,%edx
801040e9:	7f 18                	jg     80104103 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
801040eb:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
801040f0:	74 05                	je     801040f7 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
801040f2:	83 c2 01             	add    $0x1,%edx
801040f5:	eb ef                	jmp    801040e6 <fdalloc+0x13>
      curproc->ofile[fd] = f;
801040f7:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
801040fb:	89 d0                	mov    %edx,%eax
801040fd:	83 c4 04             	add    $0x4,%esp
80104100:	5b                   	pop    %ebx
80104101:	5d                   	pop    %ebp
80104102:	c3                   	ret    
  return -1;
80104103:	ba ff ff ff ff       	mov    $0xffffffff,%edx
80104108:	eb f1                	jmp    801040fb <fdalloc+0x28>

8010410a <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
8010410a:	55                   	push   %ebp
8010410b:	89 e5                	mov    %esp,%ebp
8010410d:	56                   	push   %esi
8010410e:	53                   	push   %ebx
8010410f:	83 ec 10             	sub    $0x10,%esp
80104112:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104114:	b8 20 00 00 00       	mov    $0x20,%eax
80104119:	89 c6                	mov    %eax,%esi
8010411b:	39 43 58             	cmp    %eax,0x58(%ebx)
8010411e:	76 2e                	jbe    8010414e <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104120:	6a 10                	push   $0x10
80104122:	50                   	push   %eax
80104123:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104126:	50                   	push   %eax
80104127:	53                   	push   %ebx
80104128:	e8 46 d6 ff ff       	call   80101773 <readi>
8010412d:	83 c4 10             	add    $0x10,%esp
80104130:	83 f8 10             	cmp    $0x10,%eax
80104133:	75 0c                	jne    80104141 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
80104135:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
8010413a:	75 1e                	jne    8010415a <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010413c:	8d 46 10             	lea    0x10(%esi),%eax
8010413f:	eb d8                	jmp    80104119 <isdirempty+0xf>
      panic("isdirempty: readi");
80104141:	83 ec 0c             	sub    $0xc,%esp
80104144:	68 bc 6c 10 80       	push   $0x80106cbc
80104149:	e8 fa c1 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
8010414e:	b8 01 00 00 00       	mov    $0x1,%eax
}
80104153:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104156:	5b                   	pop    %ebx
80104157:	5e                   	pop    %esi
80104158:	5d                   	pop    %ebp
80104159:	c3                   	ret    
      return 0;
8010415a:	b8 00 00 00 00       	mov    $0x0,%eax
8010415f:	eb f2                	jmp    80104153 <isdirempty+0x49>

80104161 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104161:	55                   	push   %ebp
80104162:	89 e5                	mov    %esp,%ebp
80104164:	57                   	push   %edi
80104165:	56                   	push   %esi
80104166:	53                   	push   %ebx
80104167:	83 ec 44             	sub    $0x44,%esp
8010416a:	89 55 c4             	mov    %edx,-0x3c(%ebp)
8010416d:	89 4d c0             	mov    %ecx,-0x40(%ebp)
80104170:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104173:	8d 55 d6             	lea    -0x2a(%ebp),%edx
80104176:	52                   	push   %edx
80104177:	50                   	push   %eax
80104178:	e8 7c da ff ff       	call   80101bf9 <nameiparent>
8010417d:	89 c6                	mov    %eax,%esi
8010417f:	83 c4 10             	add    $0x10,%esp
80104182:	85 c0                	test   %eax,%eax
80104184:	0f 84 3a 01 00 00    	je     801042c4 <create+0x163>
    return 0;
  ilock(dp);
8010418a:	83 ec 0c             	sub    $0xc,%esp
8010418d:	50                   	push   %eax
8010418e:	e8 ee d3 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104193:	83 c4 0c             	add    $0xc,%esp
80104196:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104199:	50                   	push   %eax
8010419a:	8d 45 d6             	lea    -0x2a(%ebp),%eax
8010419d:	50                   	push   %eax
8010419e:	56                   	push   %esi
8010419f:	e8 0c d8 ff ff       	call   801019b0 <dirlookup>
801041a4:	89 c3                	mov    %eax,%ebx
801041a6:	83 c4 10             	add    $0x10,%esp
801041a9:	85 c0                	test   %eax,%eax
801041ab:	74 3f                	je     801041ec <create+0x8b>
    iunlockput(dp);
801041ad:	83 ec 0c             	sub    $0xc,%esp
801041b0:	56                   	push   %esi
801041b1:	e8 72 d5 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
801041b6:	89 1c 24             	mov    %ebx,(%esp)
801041b9:	e8 c3 d3 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801041be:	83 c4 10             	add    $0x10,%esp
801041c1:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
801041c6:	75 11                	jne    801041d9 <create+0x78>
801041c8:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
801041cd:	75 0a                	jne    801041d9 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
801041cf:	89 d8                	mov    %ebx,%eax
801041d1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801041d4:	5b                   	pop    %ebx
801041d5:	5e                   	pop    %esi
801041d6:	5f                   	pop    %edi
801041d7:	5d                   	pop    %ebp
801041d8:	c3                   	ret    
    iunlockput(ip);
801041d9:	83 ec 0c             	sub    $0xc,%esp
801041dc:	53                   	push   %ebx
801041dd:	e8 46 d5 ff ff       	call   80101728 <iunlockput>
    return 0;
801041e2:	83 c4 10             	add    $0x10,%esp
801041e5:	bb 00 00 00 00       	mov    $0x0,%ebx
801041ea:	eb e3                	jmp    801041cf <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
801041ec:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
801041f0:	83 ec 08             	sub    $0x8,%esp
801041f3:	50                   	push   %eax
801041f4:	ff 36                	pushl  (%esi)
801041f6:	e8 83 d1 ff ff       	call   8010137e <ialloc>
801041fb:	89 c3                	mov    %eax,%ebx
801041fd:	83 c4 10             	add    $0x10,%esp
80104200:	85 c0                	test   %eax,%eax
80104202:	74 55                	je     80104259 <create+0xf8>
  ilock(ip);
80104204:	83 ec 0c             	sub    $0xc,%esp
80104207:	50                   	push   %eax
80104208:	e8 74 d3 ff ff       	call   80101581 <ilock>
  ip->major = major;
8010420d:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104211:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104215:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104219:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
8010421f:	89 1c 24             	mov    %ebx,(%esp)
80104222:	e8 f9 d1 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80104227:	83 c4 10             	add    $0x10,%esp
8010422a:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
8010422f:	74 35                	je     80104266 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
80104231:	83 ec 04             	sub    $0x4,%esp
80104234:	ff 73 04             	pushl  0x4(%ebx)
80104237:	8d 45 d6             	lea    -0x2a(%ebp),%eax
8010423a:	50                   	push   %eax
8010423b:	56                   	push   %esi
8010423c:	e8 ef d8 ff ff       	call   80101b30 <dirlink>
80104241:	83 c4 10             	add    $0x10,%esp
80104244:	85 c0                	test   %eax,%eax
80104246:	78 6f                	js     801042b7 <create+0x156>
  iunlockput(dp);
80104248:	83 ec 0c             	sub    $0xc,%esp
8010424b:	56                   	push   %esi
8010424c:	e8 d7 d4 ff ff       	call   80101728 <iunlockput>
  return ip;
80104251:	83 c4 10             	add    $0x10,%esp
80104254:	e9 76 ff ff ff       	jmp    801041cf <create+0x6e>
    panic("create: ialloc");
80104259:	83 ec 0c             	sub    $0xc,%esp
8010425c:	68 ce 6c 10 80       	push   $0x80106cce
80104261:	e8 e2 c0 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104266:	0f b7 46 56          	movzwl 0x56(%esi),%eax
8010426a:	83 c0 01             	add    $0x1,%eax
8010426d:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104271:	83 ec 0c             	sub    $0xc,%esp
80104274:	56                   	push   %esi
80104275:	e8 a6 d1 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010427a:	83 c4 0c             	add    $0xc,%esp
8010427d:	ff 73 04             	pushl  0x4(%ebx)
80104280:	68 de 6c 10 80       	push   $0x80106cde
80104285:	53                   	push   %ebx
80104286:	e8 a5 d8 ff ff       	call   80101b30 <dirlink>
8010428b:	83 c4 10             	add    $0x10,%esp
8010428e:	85 c0                	test   %eax,%eax
80104290:	78 18                	js     801042aa <create+0x149>
80104292:	83 ec 04             	sub    $0x4,%esp
80104295:	ff 76 04             	pushl  0x4(%esi)
80104298:	68 dd 6c 10 80       	push   $0x80106cdd
8010429d:	53                   	push   %ebx
8010429e:	e8 8d d8 ff ff       	call   80101b30 <dirlink>
801042a3:	83 c4 10             	add    $0x10,%esp
801042a6:	85 c0                	test   %eax,%eax
801042a8:	79 87                	jns    80104231 <create+0xd0>
      panic("create dots");
801042aa:	83 ec 0c             	sub    $0xc,%esp
801042ad:	68 e0 6c 10 80       	push   $0x80106ce0
801042b2:	e8 91 c0 ff ff       	call   80100348 <panic>
    panic("create: dirlink");
801042b7:	83 ec 0c             	sub    $0xc,%esp
801042ba:	68 ec 6c 10 80       	push   $0x80106cec
801042bf:	e8 84 c0 ff ff       	call   80100348 <panic>
    return 0;
801042c4:	89 c3                	mov    %eax,%ebx
801042c6:	e9 04 ff ff ff       	jmp    801041cf <create+0x6e>

801042cb <sys_dup>:
{
801042cb:	55                   	push   %ebp
801042cc:	89 e5                	mov    %esp,%ebp
801042ce:	53                   	push   %ebx
801042cf:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
801042d2:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801042d5:	ba 00 00 00 00       	mov    $0x0,%edx
801042da:	b8 00 00 00 00       	mov    $0x0,%eax
801042df:	e8 88 fd ff ff       	call   8010406c <argfd>
801042e4:	85 c0                	test   %eax,%eax
801042e6:	78 23                	js     8010430b <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
801042e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042eb:	e8 e3 fd ff ff       	call   801040d3 <fdalloc>
801042f0:	89 c3                	mov    %eax,%ebx
801042f2:	85 c0                	test   %eax,%eax
801042f4:	78 1c                	js     80104312 <sys_dup+0x47>
  filedup(f);
801042f6:	83 ec 0c             	sub    $0xc,%esp
801042f9:	ff 75 f4             	pushl  -0xc(%ebp)
801042fc:	e8 8d c9 ff ff       	call   80100c8e <filedup>
  return fd;
80104301:	83 c4 10             	add    $0x10,%esp
}
80104304:	89 d8                	mov    %ebx,%eax
80104306:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104309:	c9                   	leave  
8010430a:	c3                   	ret    
    return -1;
8010430b:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104310:	eb f2                	jmp    80104304 <sys_dup+0x39>
    return -1;
80104312:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104317:	eb eb                	jmp    80104304 <sys_dup+0x39>

80104319 <sys_read>:
{
80104319:	55                   	push   %ebp
8010431a:	89 e5                	mov    %esp,%ebp
8010431c:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010431f:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104322:	ba 00 00 00 00       	mov    $0x0,%edx
80104327:	b8 00 00 00 00       	mov    $0x0,%eax
8010432c:	e8 3b fd ff ff       	call   8010406c <argfd>
80104331:	85 c0                	test   %eax,%eax
80104333:	78 43                	js     80104378 <sys_read+0x5f>
80104335:	83 ec 08             	sub    $0x8,%esp
80104338:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010433b:	50                   	push   %eax
8010433c:	6a 02                	push   $0x2
8010433e:	e8 11 fc ff ff       	call   80103f54 <argint>
80104343:	83 c4 10             	add    $0x10,%esp
80104346:	85 c0                	test   %eax,%eax
80104348:	78 35                	js     8010437f <sys_read+0x66>
8010434a:	83 ec 04             	sub    $0x4,%esp
8010434d:	ff 75 f0             	pushl  -0x10(%ebp)
80104350:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104353:	50                   	push   %eax
80104354:	6a 01                	push   $0x1
80104356:	e8 21 fc ff ff       	call   80103f7c <argptr>
8010435b:	83 c4 10             	add    $0x10,%esp
8010435e:	85 c0                	test   %eax,%eax
80104360:	78 24                	js     80104386 <sys_read+0x6d>
  return fileread(f, p, n);
80104362:	83 ec 04             	sub    $0x4,%esp
80104365:	ff 75 f0             	pushl  -0x10(%ebp)
80104368:	ff 75 ec             	pushl  -0x14(%ebp)
8010436b:	ff 75 f4             	pushl  -0xc(%ebp)
8010436e:	e8 64 ca ff ff       	call   80100dd7 <fileread>
80104373:	83 c4 10             	add    $0x10,%esp
}
80104376:	c9                   	leave  
80104377:	c3                   	ret    
    return -1;
80104378:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010437d:	eb f7                	jmp    80104376 <sys_read+0x5d>
8010437f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104384:	eb f0                	jmp    80104376 <sys_read+0x5d>
80104386:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010438b:	eb e9                	jmp    80104376 <sys_read+0x5d>

8010438d <sys_write>:
{
8010438d:	55                   	push   %ebp
8010438e:	89 e5                	mov    %esp,%ebp
80104390:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104393:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104396:	ba 00 00 00 00       	mov    $0x0,%edx
8010439b:	b8 00 00 00 00       	mov    $0x0,%eax
801043a0:	e8 c7 fc ff ff       	call   8010406c <argfd>
801043a5:	85 c0                	test   %eax,%eax
801043a7:	78 43                	js     801043ec <sys_write+0x5f>
801043a9:	83 ec 08             	sub    $0x8,%esp
801043ac:	8d 45 f0             	lea    -0x10(%ebp),%eax
801043af:	50                   	push   %eax
801043b0:	6a 02                	push   $0x2
801043b2:	e8 9d fb ff ff       	call   80103f54 <argint>
801043b7:	83 c4 10             	add    $0x10,%esp
801043ba:	85 c0                	test   %eax,%eax
801043bc:	78 35                	js     801043f3 <sys_write+0x66>
801043be:	83 ec 04             	sub    $0x4,%esp
801043c1:	ff 75 f0             	pushl  -0x10(%ebp)
801043c4:	8d 45 ec             	lea    -0x14(%ebp),%eax
801043c7:	50                   	push   %eax
801043c8:	6a 01                	push   $0x1
801043ca:	e8 ad fb ff ff       	call   80103f7c <argptr>
801043cf:	83 c4 10             	add    $0x10,%esp
801043d2:	85 c0                	test   %eax,%eax
801043d4:	78 24                	js     801043fa <sys_write+0x6d>
  return filewrite(f, p, n);
801043d6:	83 ec 04             	sub    $0x4,%esp
801043d9:	ff 75 f0             	pushl  -0x10(%ebp)
801043dc:	ff 75 ec             	pushl  -0x14(%ebp)
801043df:	ff 75 f4             	pushl  -0xc(%ebp)
801043e2:	e8 75 ca ff ff       	call   80100e5c <filewrite>
801043e7:	83 c4 10             	add    $0x10,%esp
}
801043ea:	c9                   	leave  
801043eb:	c3                   	ret    
    return -1;
801043ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043f1:	eb f7                	jmp    801043ea <sys_write+0x5d>
801043f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043f8:	eb f0                	jmp    801043ea <sys_write+0x5d>
801043fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043ff:	eb e9                	jmp    801043ea <sys_write+0x5d>

80104401 <sys_close>:
{
80104401:	55                   	push   %ebp
80104402:	89 e5                	mov    %esp,%ebp
80104404:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104407:	8d 4d f0             	lea    -0x10(%ebp),%ecx
8010440a:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010440d:	b8 00 00 00 00       	mov    $0x0,%eax
80104412:	e8 55 fc ff ff       	call   8010406c <argfd>
80104417:	85 c0                	test   %eax,%eax
80104419:	78 25                	js     80104440 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
8010441b:	e8 9e ee ff ff       	call   801032be <myproc>
80104420:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104423:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
8010442a:	00 
  fileclose(f);
8010442b:	83 ec 0c             	sub    $0xc,%esp
8010442e:	ff 75 f0             	pushl  -0x10(%ebp)
80104431:	e8 9d c8 ff ff       	call   80100cd3 <fileclose>
  return 0;
80104436:	83 c4 10             	add    $0x10,%esp
80104439:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010443e:	c9                   	leave  
8010443f:	c3                   	ret    
    return -1;
80104440:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104445:	eb f7                	jmp    8010443e <sys_close+0x3d>

80104447 <sys_fstat>:
{
80104447:	55                   	push   %ebp
80104448:	89 e5                	mov    %esp,%ebp
8010444a:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010444d:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104450:	ba 00 00 00 00       	mov    $0x0,%edx
80104455:	b8 00 00 00 00       	mov    $0x0,%eax
8010445a:	e8 0d fc ff ff       	call   8010406c <argfd>
8010445f:	85 c0                	test   %eax,%eax
80104461:	78 2a                	js     8010448d <sys_fstat+0x46>
80104463:	83 ec 04             	sub    $0x4,%esp
80104466:	6a 14                	push   $0x14
80104468:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010446b:	50                   	push   %eax
8010446c:	6a 01                	push   $0x1
8010446e:	e8 09 fb ff ff       	call   80103f7c <argptr>
80104473:	83 c4 10             	add    $0x10,%esp
80104476:	85 c0                	test   %eax,%eax
80104478:	78 1a                	js     80104494 <sys_fstat+0x4d>
  return filestat(f, st);
8010447a:	83 ec 08             	sub    $0x8,%esp
8010447d:	ff 75 f0             	pushl  -0x10(%ebp)
80104480:	ff 75 f4             	pushl  -0xc(%ebp)
80104483:	e8 08 c9 ff ff       	call   80100d90 <filestat>
80104488:	83 c4 10             	add    $0x10,%esp
}
8010448b:	c9                   	leave  
8010448c:	c3                   	ret    
    return -1;
8010448d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104492:	eb f7                	jmp    8010448b <sys_fstat+0x44>
80104494:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104499:	eb f0                	jmp    8010448b <sys_fstat+0x44>

8010449b <sys_link>:
{
8010449b:	55                   	push   %ebp
8010449c:	89 e5                	mov    %esp,%ebp
8010449e:	56                   	push   %esi
8010449f:	53                   	push   %ebx
801044a0:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801044a3:	8d 45 e0             	lea    -0x20(%ebp),%eax
801044a6:	50                   	push   %eax
801044a7:	6a 00                	push   $0x0
801044a9:	e8 36 fb ff ff       	call   80103fe4 <argstr>
801044ae:	83 c4 10             	add    $0x10,%esp
801044b1:	85 c0                	test   %eax,%eax
801044b3:	0f 88 32 01 00 00    	js     801045eb <sys_link+0x150>
801044b9:	83 ec 08             	sub    $0x8,%esp
801044bc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801044bf:	50                   	push   %eax
801044c0:	6a 01                	push   $0x1
801044c2:	e8 1d fb ff ff       	call   80103fe4 <argstr>
801044c7:	83 c4 10             	add    $0x10,%esp
801044ca:	85 c0                	test   %eax,%eax
801044cc:	0f 88 20 01 00 00    	js     801045f2 <sys_link+0x157>
  begin_op();
801044d2:	e8 9f e3 ff ff       	call   80102876 <begin_op>
  if((ip = namei(old)) == 0){
801044d7:	83 ec 0c             	sub    $0xc,%esp
801044da:	ff 75 e0             	pushl  -0x20(%ebp)
801044dd:	e8 ff d6 ff ff       	call   80101be1 <namei>
801044e2:	89 c3                	mov    %eax,%ebx
801044e4:	83 c4 10             	add    $0x10,%esp
801044e7:	85 c0                	test   %eax,%eax
801044e9:	0f 84 99 00 00 00    	je     80104588 <sys_link+0xed>
  ilock(ip);
801044ef:	83 ec 0c             	sub    $0xc,%esp
801044f2:	50                   	push   %eax
801044f3:	e8 89 d0 ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
801044f8:	83 c4 10             	add    $0x10,%esp
801044fb:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104500:	0f 84 8e 00 00 00    	je     80104594 <sys_link+0xf9>
  ip->nlink++;
80104506:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010450a:	83 c0 01             	add    $0x1,%eax
8010450d:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104511:	83 ec 0c             	sub    $0xc,%esp
80104514:	53                   	push   %ebx
80104515:	e8 06 cf ff ff       	call   80101420 <iupdate>
  iunlock(ip);
8010451a:	89 1c 24             	mov    %ebx,(%esp)
8010451d:	e8 21 d1 ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104522:	83 c4 08             	add    $0x8,%esp
80104525:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104528:	50                   	push   %eax
80104529:	ff 75 e4             	pushl  -0x1c(%ebp)
8010452c:	e8 c8 d6 ff ff       	call   80101bf9 <nameiparent>
80104531:	89 c6                	mov    %eax,%esi
80104533:	83 c4 10             	add    $0x10,%esp
80104536:	85 c0                	test   %eax,%eax
80104538:	74 7e                	je     801045b8 <sys_link+0x11d>
  ilock(dp);
8010453a:	83 ec 0c             	sub    $0xc,%esp
8010453d:	50                   	push   %eax
8010453e:	e8 3e d0 ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80104543:	83 c4 10             	add    $0x10,%esp
80104546:	8b 03                	mov    (%ebx),%eax
80104548:	39 06                	cmp    %eax,(%esi)
8010454a:	75 60                	jne    801045ac <sys_link+0x111>
8010454c:	83 ec 04             	sub    $0x4,%esp
8010454f:	ff 73 04             	pushl  0x4(%ebx)
80104552:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104555:	50                   	push   %eax
80104556:	56                   	push   %esi
80104557:	e8 d4 d5 ff ff       	call   80101b30 <dirlink>
8010455c:	83 c4 10             	add    $0x10,%esp
8010455f:	85 c0                	test   %eax,%eax
80104561:	78 49                	js     801045ac <sys_link+0x111>
  iunlockput(dp);
80104563:	83 ec 0c             	sub    $0xc,%esp
80104566:	56                   	push   %esi
80104567:	e8 bc d1 ff ff       	call   80101728 <iunlockput>
  iput(ip);
8010456c:	89 1c 24             	mov    %ebx,(%esp)
8010456f:	e8 14 d1 ff ff       	call   80101688 <iput>
  end_op();
80104574:	e8 77 e3 ff ff       	call   801028f0 <end_op>
  return 0;
80104579:	83 c4 10             	add    $0x10,%esp
8010457c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104581:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104584:	5b                   	pop    %ebx
80104585:	5e                   	pop    %esi
80104586:	5d                   	pop    %ebp
80104587:	c3                   	ret    
    end_op();
80104588:	e8 63 e3 ff ff       	call   801028f0 <end_op>
    return -1;
8010458d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104592:	eb ed                	jmp    80104581 <sys_link+0xe6>
    iunlockput(ip);
80104594:	83 ec 0c             	sub    $0xc,%esp
80104597:	53                   	push   %ebx
80104598:	e8 8b d1 ff ff       	call   80101728 <iunlockput>
    end_op();
8010459d:	e8 4e e3 ff ff       	call   801028f0 <end_op>
    return -1;
801045a2:	83 c4 10             	add    $0x10,%esp
801045a5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045aa:	eb d5                	jmp    80104581 <sys_link+0xe6>
    iunlockput(dp);
801045ac:	83 ec 0c             	sub    $0xc,%esp
801045af:	56                   	push   %esi
801045b0:	e8 73 d1 ff ff       	call   80101728 <iunlockput>
    goto bad;
801045b5:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
801045b8:	83 ec 0c             	sub    $0xc,%esp
801045bb:	53                   	push   %ebx
801045bc:	e8 c0 cf ff ff       	call   80101581 <ilock>
  ip->nlink--;
801045c1:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801045c5:	83 e8 01             	sub    $0x1,%eax
801045c8:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801045cc:	89 1c 24             	mov    %ebx,(%esp)
801045cf:	e8 4c ce ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
801045d4:	89 1c 24             	mov    %ebx,(%esp)
801045d7:	e8 4c d1 ff ff       	call   80101728 <iunlockput>
  end_op();
801045dc:	e8 0f e3 ff ff       	call   801028f0 <end_op>
  return -1;
801045e1:	83 c4 10             	add    $0x10,%esp
801045e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045e9:	eb 96                	jmp    80104581 <sys_link+0xe6>
    return -1;
801045eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045f0:	eb 8f                	jmp    80104581 <sys_link+0xe6>
801045f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045f7:	eb 88                	jmp    80104581 <sys_link+0xe6>

801045f9 <sys_unlink>:
{
801045f9:	55                   	push   %ebp
801045fa:	89 e5                	mov    %esp,%ebp
801045fc:	57                   	push   %edi
801045fd:	56                   	push   %esi
801045fe:	53                   	push   %ebx
801045ff:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104602:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104605:	50                   	push   %eax
80104606:	6a 00                	push   $0x0
80104608:	e8 d7 f9 ff ff       	call   80103fe4 <argstr>
8010460d:	83 c4 10             	add    $0x10,%esp
80104610:	85 c0                	test   %eax,%eax
80104612:	0f 88 83 01 00 00    	js     8010479b <sys_unlink+0x1a2>
  begin_op();
80104618:	e8 59 e2 ff ff       	call   80102876 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
8010461d:	83 ec 08             	sub    $0x8,%esp
80104620:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104623:	50                   	push   %eax
80104624:	ff 75 c4             	pushl  -0x3c(%ebp)
80104627:	e8 cd d5 ff ff       	call   80101bf9 <nameiparent>
8010462c:	89 c6                	mov    %eax,%esi
8010462e:	83 c4 10             	add    $0x10,%esp
80104631:	85 c0                	test   %eax,%eax
80104633:	0f 84 ed 00 00 00    	je     80104726 <sys_unlink+0x12d>
  ilock(dp);
80104639:	83 ec 0c             	sub    $0xc,%esp
8010463c:	50                   	push   %eax
8010463d:	e8 3f cf ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104642:	83 c4 08             	add    $0x8,%esp
80104645:	68 de 6c 10 80       	push   $0x80106cde
8010464a:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010464d:	50                   	push   %eax
8010464e:	e8 48 d3 ff ff       	call   8010199b <namecmp>
80104653:	83 c4 10             	add    $0x10,%esp
80104656:	85 c0                	test   %eax,%eax
80104658:	0f 84 fc 00 00 00    	je     8010475a <sys_unlink+0x161>
8010465e:	83 ec 08             	sub    $0x8,%esp
80104661:	68 dd 6c 10 80       	push   $0x80106cdd
80104666:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104669:	50                   	push   %eax
8010466a:	e8 2c d3 ff ff       	call   8010199b <namecmp>
8010466f:	83 c4 10             	add    $0x10,%esp
80104672:	85 c0                	test   %eax,%eax
80104674:	0f 84 e0 00 00 00    	je     8010475a <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
8010467a:	83 ec 04             	sub    $0x4,%esp
8010467d:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104680:	50                   	push   %eax
80104681:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104684:	50                   	push   %eax
80104685:	56                   	push   %esi
80104686:	e8 25 d3 ff ff       	call   801019b0 <dirlookup>
8010468b:	89 c3                	mov    %eax,%ebx
8010468d:	83 c4 10             	add    $0x10,%esp
80104690:	85 c0                	test   %eax,%eax
80104692:	0f 84 c2 00 00 00    	je     8010475a <sys_unlink+0x161>
  ilock(ip);
80104698:	83 ec 0c             	sub    $0xc,%esp
8010469b:	50                   	push   %eax
8010469c:	e8 e0 ce ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
801046a1:	83 c4 10             	add    $0x10,%esp
801046a4:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801046a9:	0f 8e 83 00 00 00    	jle    80104732 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
801046af:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801046b4:	0f 84 85 00 00 00    	je     8010473f <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
801046ba:	83 ec 04             	sub    $0x4,%esp
801046bd:	6a 10                	push   $0x10
801046bf:	6a 00                	push   $0x0
801046c1:	8d 7d d8             	lea    -0x28(%ebp),%edi
801046c4:	57                   	push   %edi
801046c5:	e8 3f f6 ff ff       	call   80103d09 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801046ca:	6a 10                	push   $0x10
801046cc:	ff 75 c0             	pushl  -0x40(%ebp)
801046cf:	57                   	push   %edi
801046d0:	56                   	push   %esi
801046d1:	e8 9a d1 ff ff       	call   80101870 <writei>
801046d6:	83 c4 20             	add    $0x20,%esp
801046d9:	83 f8 10             	cmp    $0x10,%eax
801046dc:	0f 85 90 00 00 00    	jne    80104772 <sys_unlink+0x179>
  if(ip->type == T_DIR){
801046e2:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801046e7:	0f 84 92 00 00 00    	je     8010477f <sys_unlink+0x186>
  iunlockput(dp);
801046ed:	83 ec 0c             	sub    $0xc,%esp
801046f0:	56                   	push   %esi
801046f1:	e8 32 d0 ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
801046f6:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801046fa:	83 e8 01             	sub    $0x1,%eax
801046fd:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104701:	89 1c 24             	mov    %ebx,(%esp)
80104704:	e8 17 cd ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104709:	89 1c 24             	mov    %ebx,(%esp)
8010470c:	e8 17 d0 ff ff       	call   80101728 <iunlockput>
  end_op();
80104711:	e8 da e1 ff ff       	call   801028f0 <end_op>
  return 0;
80104716:	83 c4 10             	add    $0x10,%esp
80104719:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010471e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104721:	5b                   	pop    %ebx
80104722:	5e                   	pop    %esi
80104723:	5f                   	pop    %edi
80104724:	5d                   	pop    %ebp
80104725:	c3                   	ret    
    end_op();
80104726:	e8 c5 e1 ff ff       	call   801028f0 <end_op>
    return -1;
8010472b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104730:	eb ec                	jmp    8010471e <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104732:	83 ec 0c             	sub    $0xc,%esp
80104735:	68 fc 6c 10 80       	push   $0x80106cfc
8010473a:	e8 09 bc ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010473f:	89 d8                	mov    %ebx,%eax
80104741:	e8 c4 f9 ff ff       	call   8010410a <isdirempty>
80104746:	85 c0                	test   %eax,%eax
80104748:	0f 85 6c ff ff ff    	jne    801046ba <sys_unlink+0xc1>
    iunlockput(ip);
8010474e:	83 ec 0c             	sub    $0xc,%esp
80104751:	53                   	push   %ebx
80104752:	e8 d1 cf ff ff       	call   80101728 <iunlockput>
    goto bad;
80104757:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
8010475a:	83 ec 0c             	sub    $0xc,%esp
8010475d:	56                   	push   %esi
8010475e:	e8 c5 cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104763:	e8 88 e1 ff ff       	call   801028f0 <end_op>
  return -1;
80104768:	83 c4 10             	add    $0x10,%esp
8010476b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104770:	eb ac                	jmp    8010471e <sys_unlink+0x125>
    panic("unlink: writei");
80104772:	83 ec 0c             	sub    $0xc,%esp
80104775:	68 0e 6d 10 80       	push   $0x80106d0e
8010477a:	e8 c9 bb ff ff       	call   80100348 <panic>
    dp->nlink--;
8010477f:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104783:	83 e8 01             	sub    $0x1,%eax
80104786:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
8010478a:	83 ec 0c             	sub    $0xc,%esp
8010478d:	56                   	push   %esi
8010478e:	e8 8d cc ff ff       	call   80101420 <iupdate>
80104793:	83 c4 10             	add    $0x10,%esp
80104796:	e9 52 ff ff ff       	jmp    801046ed <sys_unlink+0xf4>
    return -1;
8010479b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047a0:	e9 79 ff ff ff       	jmp    8010471e <sys_unlink+0x125>

801047a5 <sys_open>:

int
sys_open(void)
{
801047a5:	55                   	push   %ebp
801047a6:	89 e5                	mov    %esp,%ebp
801047a8:	57                   	push   %edi
801047a9:	56                   	push   %esi
801047aa:	53                   	push   %ebx
801047ab:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801047ae:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801047b1:	50                   	push   %eax
801047b2:	6a 00                	push   $0x0
801047b4:	e8 2b f8 ff ff       	call   80103fe4 <argstr>
801047b9:	83 c4 10             	add    $0x10,%esp
801047bc:	85 c0                	test   %eax,%eax
801047be:	0f 88 30 01 00 00    	js     801048f4 <sys_open+0x14f>
801047c4:	83 ec 08             	sub    $0x8,%esp
801047c7:	8d 45 e0             	lea    -0x20(%ebp),%eax
801047ca:	50                   	push   %eax
801047cb:	6a 01                	push   $0x1
801047cd:	e8 82 f7 ff ff       	call   80103f54 <argint>
801047d2:	83 c4 10             	add    $0x10,%esp
801047d5:	85 c0                	test   %eax,%eax
801047d7:	0f 88 21 01 00 00    	js     801048fe <sys_open+0x159>
    return -1;

  begin_op();
801047dd:	e8 94 e0 ff ff       	call   80102876 <begin_op>

  if(omode & O_CREATE){
801047e2:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
801047e6:	0f 84 84 00 00 00    	je     80104870 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
801047ec:	83 ec 0c             	sub    $0xc,%esp
801047ef:	6a 00                	push   $0x0
801047f1:	b9 00 00 00 00       	mov    $0x0,%ecx
801047f6:	ba 02 00 00 00       	mov    $0x2,%edx
801047fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801047fe:	e8 5e f9 ff ff       	call   80104161 <create>
80104803:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104805:	83 c4 10             	add    $0x10,%esp
80104808:	85 c0                	test   %eax,%eax
8010480a:	74 58                	je     80104864 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010480c:	e8 1c c4 ff ff       	call   80100c2d <filealloc>
80104811:	89 c3                	mov    %eax,%ebx
80104813:	85 c0                	test   %eax,%eax
80104815:	0f 84 ae 00 00 00    	je     801048c9 <sys_open+0x124>
8010481b:	e8 b3 f8 ff ff       	call   801040d3 <fdalloc>
80104820:	89 c7                	mov    %eax,%edi
80104822:	85 c0                	test   %eax,%eax
80104824:	0f 88 9f 00 00 00    	js     801048c9 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
8010482a:	83 ec 0c             	sub    $0xc,%esp
8010482d:	56                   	push   %esi
8010482e:	e8 10 ce ff ff       	call   80101643 <iunlock>
  end_op();
80104833:	e8 b8 e0 ff ff       	call   801028f0 <end_op>

  f->type = FD_INODE;
80104838:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
8010483e:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104841:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104848:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010484b:	83 c4 10             	add    $0x10,%esp
8010484e:	a8 01                	test   $0x1,%al
80104850:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104854:	a8 03                	test   $0x3,%al
80104856:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
8010485a:	89 f8                	mov    %edi,%eax
8010485c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010485f:	5b                   	pop    %ebx
80104860:	5e                   	pop    %esi
80104861:	5f                   	pop    %edi
80104862:	5d                   	pop    %ebp
80104863:	c3                   	ret    
      end_op();
80104864:	e8 87 e0 ff ff       	call   801028f0 <end_op>
      return -1;
80104869:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010486e:	eb ea                	jmp    8010485a <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104870:	83 ec 0c             	sub    $0xc,%esp
80104873:	ff 75 e4             	pushl  -0x1c(%ebp)
80104876:	e8 66 d3 ff ff       	call   80101be1 <namei>
8010487b:	89 c6                	mov    %eax,%esi
8010487d:	83 c4 10             	add    $0x10,%esp
80104880:	85 c0                	test   %eax,%eax
80104882:	74 39                	je     801048bd <sys_open+0x118>
    ilock(ip);
80104884:	83 ec 0c             	sub    $0xc,%esp
80104887:	50                   	push   %eax
80104888:	e8 f4 cc ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
8010488d:	83 c4 10             	add    $0x10,%esp
80104890:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104895:	0f 85 71 ff ff ff    	jne    8010480c <sys_open+0x67>
8010489b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010489f:	0f 84 67 ff ff ff    	je     8010480c <sys_open+0x67>
      iunlockput(ip);
801048a5:	83 ec 0c             	sub    $0xc,%esp
801048a8:	56                   	push   %esi
801048a9:	e8 7a ce ff ff       	call   80101728 <iunlockput>
      end_op();
801048ae:	e8 3d e0 ff ff       	call   801028f0 <end_op>
      return -1;
801048b3:	83 c4 10             	add    $0x10,%esp
801048b6:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048bb:	eb 9d                	jmp    8010485a <sys_open+0xb5>
      end_op();
801048bd:	e8 2e e0 ff ff       	call   801028f0 <end_op>
      return -1;
801048c2:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048c7:	eb 91                	jmp    8010485a <sys_open+0xb5>
    if(f)
801048c9:	85 db                	test   %ebx,%ebx
801048cb:	74 0c                	je     801048d9 <sys_open+0x134>
      fileclose(f);
801048cd:	83 ec 0c             	sub    $0xc,%esp
801048d0:	53                   	push   %ebx
801048d1:	e8 fd c3 ff ff       	call   80100cd3 <fileclose>
801048d6:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
801048d9:	83 ec 0c             	sub    $0xc,%esp
801048dc:	56                   	push   %esi
801048dd:	e8 46 ce ff ff       	call   80101728 <iunlockput>
    end_op();
801048e2:	e8 09 e0 ff ff       	call   801028f0 <end_op>
    return -1;
801048e7:	83 c4 10             	add    $0x10,%esp
801048ea:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048ef:	e9 66 ff ff ff       	jmp    8010485a <sys_open+0xb5>
    return -1;
801048f4:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048f9:	e9 5c ff ff ff       	jmp    8010485a <sys_open+0xb5>
801048fe:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104903:	e9 52 ff ff ff       	jmp    8010485a <sys_open+0xb5>

80104908 <sys_mkdir>:

int
sys_mkdir(void)
{
80104908:	55                   	push   %ebp
80104909:	89 e5                	mov    %esp,%ebp
8010490b:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010490e:	e8 63 df ff ff       	call   80102876 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104913:	83 ec 08             	sub    $0x8,%esp
80104916:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104919:	50                   	push   %eax
8010491a:	6a 00                	push   $0x0
8010491c:	e8 c3 f6 ff ff       	call   80103fe4 <argstr>
80104921:	83 c4 10             	add    $0x10,%esp
80104924:	85 c0                	test   %eax,%eax
80104926:	78 36                	js     8010495e <sys_mkdir+0x56>
80104928:	83 ec 0c             	sub    $0xc,%esp
8010492b:	6a 00                	push   $0x0
8010492d:	b9 00 00 00 00       	mov    $0x0,%ecx
80104932:	ba 01 00 00 00       	mov    $0x1,%edx
80104937:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010493a:	e8 22 f8 ff ff       	call   80104161 <create>
8010493f:	83 c4 10             	add    $0x10,%esp
80104942:	85 c0                	test   %eax,%eax
80104944:	74 18                	je     8010495e <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104946:	83 ec 0c             	sub    $0xc,%esp
80104949:	50                   	push   %eax
8010494a:	e8 d9 cd ff ff       	call   80101728 <iunlockput>
  end_op();
8010494f:	e8 9c df ff ff       	call   801028f0 <end_op>
  return 0;
80104954:	83 c4 10             	add    $0x10,%esp
80104957:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010495c:	c9                   	leave  
8010495d:	c3                   	ret    
    end_op();
8010495e:	e8 8d df ff ff       	call   801028f0 <end_op>
    return -1;
80104963:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104968:	eb f2                	jmp    8010495c <sys_mkdir+0x54>

8010496a <sys_mknod>:

int
sys_mknod(void)
{
8010496a:	55                   	push   %ebp
8010496b:	89 e5                	mov    %esp,%ebp
8010496d:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104970:	e8 01 df ff ff       	call   80102876 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104975:	83 ec 08             	sub    $0x8,%esp
80104978:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010497b:	50                   	push   %eax
8010497c:	6a 00                	push   $0x0
8010497e:	e8 61 f6 ff ff       	call   80103fe4 <argstr>
80104983:	83 c4 10             	add    $0x10,%esp
80104986:	85 c0                	test   %eax,%eax
80104988:	78 62                	js     801049ec <sys_mknod+0x82>
     argint(1, &major) < 0 ||
8010498a:	83 ec 08             	sub    $0x8,%esp
8010498d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104990:	50                   	push   %eax
80104991:	6a 01                	push   $0x1
80104993:	e8 bc f5 ff ff       	call   80103f54 <argint>
  if((argstr(0, &path)) < 0 ||
80104998:	83 c4 10             	add    $0x10,%esp
8010499b:	85 c0                	test   %eax,%eax
8010499d:	78 4d                	js     801049ec <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
8010499f:	83 ec 08             	sub    $0x8,%esp
801049a2:	8d 45 ec             	lea    -0x14(%ebp),%eax
801049a5:	50                   	push   %eax
801049a6:	6a 02                	push   $0x2
801049a8:	e8 a7 f5 ff ff       	call   80103f54 <argint>
     argint(1, &major) < 0 ||
801049ad:	83 c4 10             	add    $0x10,%esp
801049b0:	85 c0                	test   %eax,%eax
801049b2:	78 38                	js     801049ec <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
801049b4:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
801049b8:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
801049bc:	83 ec 0c             	sub    $0xc,%esp
801049bf:	50                   	push   %eax
801049c0:	ba 03 00 00 00       	mov    $0x3,%edx
801049c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049c8:	e8 94 f7 ff ff       	call   80104161 <create>
801049cd:	83 c4 10             	add    $0x10,%esp
801049d0:	85 c0                	test   %eax,%eax
801049d2:	74 18                	je     801049ec <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
801049d4:	83 ec 0c             	sub    $0xc,%esp
801049d7:	50                   	push   %eax
801049d8:	e8 4b cd ff ff       	call   80101728 <iunlockput>
  end_op();
801049dd:	e8 0e df ff ff       	call   801028f0 <end_op>
  return 0;
801049e2:	83 c4 10             	add    $0x10,%esp
801049e5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801049ea:	c9                   	leave  
801049eb:	c3                   	ret    
    end_op();
801049ec:	e8 ff de ff ff       	call   801028f0 <end_op>
    return -1;
801049f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049f6:	eb f2                	jmp    801049ea <sys_mknod+0x80>

801049f8 <sys_chdir>:

int
sys_chdir(void)
{
801049f8:	55                   	push   %ebp
801049f9:	89 e5                	mov    %esp,%ebp
801049fb:	56                   	push   %esi
801049fc:	53                   	push   %ebx
801049fd:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104a00:	e8 b9 e8 ff ff       	call   801032be <myproc>
80104a05:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104a07:	e8 6a de ff ff       	call   80102876 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104a0c:	83 ec 08             	sub    $0x8,%esp
80104a0f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a12:	50                   	push   %eax
80104a13:	6a 00                	push   $0x0
80104a15:	e8 ca f5 ff ff       	call   80103fe4 <argstr>
80104a1a:	83 c4 10             	add    $0x10,%esp
80104a1d:	85 c0                	test   %eax,%eax
80104a1f:	78 52                	js     80104a73 <sys_chdir+0x7b>
80104a21:	83 ec 0c             	sub    $0xc,%esp
80104a24:	ff 75 f4             	pushl  -0xc(%ebp)
80104a27:	e8 b5 d1 ff ff       	call   80101be1 <namei>
80104a2c:	89 c3                	mov    %eax,%ebx
80104a2e:	83 c4 10             	add    $0x10,%esp
80104a31:	85 c0                	test   %eax,%eax
80104a33:	74 3e                	je     80104a73 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104a35:	83 ec 0c             	sub    $0xc,%esp
80104a38:	50                   	push   %eax
80104a39:	e8 43 cb ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104a3e:	83 c4 10             	add    $0x10,%esp
80104a41:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104a46:	75 37                	jne    80104a7f <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104a48:	83 ec 0c             	sub    $0xc,%esp
80104a4b:	53                   	push   %ebx
80104a4c:	e8 f2 cb ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104a51:	83 c4 04             	add    $0x4,%esp
80104a54:	ff 76 68             	pushl  0x68(%esi)
80104a57:	e8 2c cc ff ff       	call   80101688 <iput>
  end_op();
80104a5c:	e8 8f de ff ff       	call   801028f0 <end_op>
  curproc->cwd = ip;
80104a61:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104a64:	83 c4 10             	add    $0x10,%esp
80104a67:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a6c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104a6f:	5b                   	pop    %ebx
80104a70:	5e                   	pop    %esi
80104a71:	5d                   	pop    %ebp
80104a72:	c3                   	ret    
    end_op();
80104a73:	e8 78 de ff ff       	call   801028f0 <end_op>
    return -1;
80104a78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a7d:	eb ed                	jmp    80104a6c <sys_chdir+0x74>
    iunlockput(ip);
80104a7f:	83 ec 0c             	sub    $0xc,%esp
80104a82:	53                   	push   %ebx
80104a83:	e8 a0 cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104a88:	e8 63 de ff ff       	call   801028f0 <end_op>
    return -1;
80104a8d:	83 c4 10             	add    $0x10,%esp
80104a90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a95:	eb d5                	jmp    80104a6c <sys_chdir+0x74>

80104a97 <sys_exec>:

int
sys_exec(void)
{
80104a97:	55                   	push   %ebp
80104a98:	89 e5                	mov    %esp,%ebp
80104a9a:	53                   	push   %ebx
80104a9b:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104aa1:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104aa4:	50                   	push   %eax
80104aa5:	6a 00                	push   $0x0
80104aa7:	e8 38 f5 ff ff       	call   80103fe4 <argstr>
80104aac:	83 c4 10             	add    $0x10,%esp
80104aaf:	85 c0                	test   %eax,%eax
80104ab1:	0f 88 a8 00 00 00    	js     80104b5f <sys_exec+0xc8>
80104ab7:	83 ec 08             	sub    $0x8,%esp
80104aba:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104ac0:	50                   	push   %eax
80104ac1:	6a 01                	push   $0x1
80104ac3:	e8 8c f4 ff ff       	call   80103f54 <argint>
80104ac8:	83 c4 10             	add    $0x10,%esp
80104acb:	85 c0                	test   %eax,%eax
80104acd:	0f 88 93 00 00 00    	js     80104b66 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104ad3:	83 ec 04             	sub    $0x4,%esp
80104ad6:	68 80 00 00 00       	push   $0x80
80104adb:	6a 00                	push   $0x0
80104add:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104ae3:	50                   	push   %eax
80104ae4:	e8 20 f2 ff ff       	call   80103d09 <memset>
80104ae9:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104aec:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104af1:	83 fb 1f             	cmp    $0x1f,%ebx
80104af4:	77 77                	ja     80104b6d <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104af6:	83 ec 08             	sub    $0x8,%esp
80104af9:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104aff:	50                   	push   %eax
80104b00:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104b06:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104b09:	50                   	push   %eax
80104b0a:	e8 c9 f3 ff ff       	call   80103ed8 <fetchint>
80104b0f:	83 c4 10             	add    $0x10,%esp
80104b12:	85 c0                	test   %eax,%eax
80104b14:	78 5e                	js     80104b74 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104b16:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104b1c:	85 c0                	test   %eax,%eax
80104b1e:	74 1d                	je     80104b3d <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104b20:	83 ec 08             	sub    $0x8,%esp
80104b23:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104b2a:	52                   	push   %edx
80104b2b:	50                   	push   %eax
80104b2c:	e8 e3 f3 ff ff       	call   80103f14 <fetchstr>
80104b31:	83 c4 10             	add    $0x10,%esp
80104b34:	85 c0                	test   %eax,%eax
80104b36:	78 46                	js     80104b7e <sys_exec+0xe7>
  for(i=0;; i++){
80104b38:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104b3b:	eb b4                	jmp    80104af1 <sys_exec+0x5a>
      argv[i] = 0;
80104b3d:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104b44:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104b48:	83 ec 08             	sub    $0x8,%esp
80104b4b:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104b51:	50                   	push   %eax
80104b52:	ff 75 f4             	pushl  -0xc(%ebp)
80104b55:	e8 78 bd ff ff       	call   801008d2 <exec>
80104b5a:	83 c4 10             	add    $0x10,%esp
80104b5d:	eb 1a                	jmp    80104b79 <sys_exec+0xe2>
    return -1;
80104b5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b64:	eb 13                	jmp    80104b79 <sys_exec+0xe2>
80104b66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b6b:	eb 0c                	jmp    80104b79 <sys_exec+0xe2>
      return -1;
80104b6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b72:	eb 05                	jmp    80104b79 <sys_exec+0xe2>
      return -1;
80104b74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104b79:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104b7c:	c9                   	leave  
80104b7d:	c3                   	ret    
      return -1;
80104b7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b83:	eb f4                	jmp    80104b79 <sys_exec+0xe2>

80104b85 <sys_pipe>:

int
sys_pipe(void)
{
80104b85:	55                   	push   %ebp
80104b86:	89 e5                	mov    %esp,%ebp
80104b88:	53                   	push   %ebx
80104b89:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104b8c:	6a 08                	push   $0x8
80104b8e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b91:	50                   	push   %eax
80104b92:	6a 00                	push   $0x0
80104b94:	e8 e3 f3 ff ff       	call   80103f7c <argptr>
80104b99:	83 c4 10             	add    $0x10,%esp
80104b9c:	85 c0                	test   %eax,%eax
80104b9e:	78 77                	js     80104c17 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104ba0:	83 ec 08             	sub    $0x8,%esp
80104ba3:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104ba6:	50                   	push   %eax
80104ba7:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104baa:	50                   	push   %eax
80104bab:	e8 4d e2 ff ff       	call   80102dfd <pipealloc>
80104bb0:	83 c4 10             	add    $0x10,%esp
80104bb3:	85 c0                	test   %eax,%eax
80104bb5:	78 67                	js     80104c1e <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104bb7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bba:	e8 14 f5 ff ff       	call   801040d3 <fdalloc>
80104bbf:	89 c3                	mov    %eax,%ebx
80104bc1:	85 c0                	test   %eax,%eax
80104bc3:	78 21                	js     80104be6 <sys_pipe+0x61>
80104bc5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104bc8:	e8 06 f5 ff ff       	call   801040d3 <fdalloc>
80104bcd:	85 c0                	test   %eax,%eax
80104bcf:	78 15                	js     80104be6 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104bd1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bd4:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104bd6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bd9:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104bdc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104be1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104be4:	c9                   	leave  
80104be5:	c3                   	ret    
    if(fd0 >= 0)
80104be6:	85 db                	test   %ebx,%ebx
80104be8:	78 0d                	js     80104bf7 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104bea:	e8 cf e6 ff ff       	call   801032be <myproc>
80104bef:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104bf6:	00 
    fileclose(rf);
80104bf7:	83 ec 0c             	sub    $0xc,%esp
80104bfa:	ff 75 f0             	pushl  -0x10(%ebp)
80104bfd:	e8 d1 c0 ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104c02:	83 c4 04             	add    $0x4,%esp
80104c05:	ff 75 ec             	pushl  -0x14(%ebp)
80104c08:	e8 c6 c0 ff ff       	call   80100cd3 <fileclose>
    return -1;
80104c0d:	83 c4 10             	add    $0x10,%esp
80104c10:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c15:	eb ca                	jmp    80104be1 <sys_pipe+0x5c>
    return -1;
80104c17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c1c:	eb c3                	jmp    80104be1 <sys_pipe+0x5c>
    return -1;
80104c1e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c23:	eb bc                	jmp    80104be1 <sys_pipe+0x5c>

80104c25 <sys_dump_physmem>:
#include "mmu.h"
#include "proc.h"

int
sys_dump_physmem(void)
{
80104c25:	55                   	push   %ebp
80104c26:	89 e5                	mov    %esp,%ebp
80104c28:	83 ec 1c             	sub    $0x1c,%esp
  int* frames;
  int* pids;
  int numframes;
  // invalid pointer
  if (argptr(0, (void*)&frames, sizeof(frames)) < 0)
80104c2b:	6a 04                	push   $0x4
80104c2d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c30:	50                   	push   %eax
80104c31:	6a 00                	push   $0x0
80104c33:	e8 44 f3 ff ff       	call   80103f7c <argptr>
80104c38:	83 c4 10             	add    $0x10,%esp
80104c3b:	85 c0                	test   %eax,%eax
80104c3d:	78 4c                	js     80104c8b <sys_dump_physmem+0x66>
    return -1;
  // invalid pointer
  if (argptr(1, (void*)&pids, sizeof(pids)) < 0)
80104c3f:	83 ec 04             	sub    $0x4,%esp
80104c42:	6a 04                	push   $0x4
80104c44:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104c47:	50                   	push   %eax
80104c48:	6a 01                	push   $0x1
80104c4a:	e8 2d f3 ff ff       	call   80103f7c <argptr>
80104c4f:	83 c4 10             	add    $0x10,%esp
80104c52:	85 c0                	test   %eax,%eax
80104c54:	78 3c                	js     80104c92 <sys_dump_physmem+0x6d>
    return -1;
  if (argint(2, &numframes) < 0) {
80104c56:	83 ec 08             	sub    $0x8,%esp
80104c59:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104c5c:	50                   	push   %eax
80104c5d:	6a 02                	push   $0x2
80104c5f:	e8 f0 f2 ff ff       	call   80103f54 <argint>
80104c64:	83 c4 10             	add    $0x10,%esp
80104c67:	85 c0                	test   %eax,%eax
80104c69:	78 2e                	js     80104c99 <sys_dump_physmem+0x74>
    return -1;
  }
  if (pids == 0 || frames == 0) {
80104c6b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c6e:	85 c0                	test   %eax,%eax
80104c70:	74 2e                	je     80104ca0 <sys_dump_physmem+0x7b>
80104c72:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c75:	85 d2                	test   %edx,%edx
80104c77:	74 2e                	je     80104ca7 <sys_dump_physmem+0x82>
    return -1;
  }
  return dump_physmem(frames, pids, numframes);
80104c79:	83 ec 04             	sub    $0x4,%esp
80104c7c:	ff 75 ec             	pushl  -0x14(%ebp)
80104c7f:	50                   	push   %eax
80104c80:	52                   	push   %edx
80104c81:	e8 c0 d4 ff ff       	call   80102146 <dump_physmem>
80104c86:	83 c4 10             	add    $0x10,%esp
}
80104c89:	c9                   	leave  
80104c8a:	c3                   	ret    
    return -1;
80104c8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c90:	eb f7                	jmp    80104c89 <sys_dump_physmem+0x64>
    return -1;
80104c92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c97:	eb f0                	jmp    80104c89 <sys_dump_physmem+0x64>
    return -1;
80104c99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c9e:	eb e9                	jmp    80104c89 <sys_dump_physmem+0x64>
    return -1;
80104ca0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ca5:	eb e2                	jmp    80104c89 <sys_dump_physmem+0x64>
80104ca7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cac:	eb db                	jmp    80104c89 <sys_dump_physmem+0x64>

80104cae <sys_fork>:

int
sys_fork(void)
{
80104cae:	55                   	push   %ebp
80104caf:	89 e5                	mov    %esp,%ebp
80104cb1:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104cb4:	e8 7d e7 ff ff       	call   80103436 <fork>
}
80104cb9:	c9                   	leave  
80104cba:	c3                   	ret    

80104cbb <sys_exit>:

int
sys_exit(void)
{
80104cbb:	55                   	push   %ebp
80104cbc:	89 e5                	mov    %esp,%ebp
80104cbe:	83 ec 08             	sub    $0x8,%esp
  exit();
80104cc1:	e8 a4 e9 ff ff       	call   8010366a <exit>
  return 0;  // not reached
}
80104cc6:	b8 00 00 00 00       	mov    $0x0,%eax
80104ccb:	c9                   	leave  
80104ccc:	c3                   	ret    

80104ccd <sys_wait>:

int
sys_wait(void)
{
80104ccd:	55                   	push   %ebp
80104cce:	89 e5                	mov    %esp,%ebp
80104cd0:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104cd3:	e8 1b eb ff ff       	call   801037f3 <wait>
}
80104cd8:	c9                   	leave  
80104cd9:	c3                   	ret    

80104cda <sys_kill>:

int
sys_kill(void)
{
80104cda:	55                   	push   %ebp
80104cdb:	89 e5                	mov    %esp,%ebp
80104cdd:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104ce0:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ce3:	50                   	push   %eax
80104ce4:	6a 00                	push   $0x0
80104ce6:	e8 69 f2 ff ff       	call   80103f54 <argint>
80104ceb:	83 c4 10             	add    $0x10,%esp
80104cee:	85 c0                	test   %eax,%eax
80104cf0:	78 10                	js     80104d02 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104cf2:	83 ec 0c             	sub    $0xc,%esp
80104cf5:	ff 75 f4             	pushl  -0xc(%ebp)
80104cf8:	e8 f3 eb ff ff       	call   801038f0 <kill>
80104cfd:	83 c4 10             	add    $0x10,%esp
}
80104d00:	c9                   	leave  
80104d01:	c3                   	ret    
    return -1;
80104d02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d07:	eb f7                	jmp    80104d00 <sys_kill+0x26>

80104d09 <sys_getpid>:

int
sys_getpid(void)
{
80104d09:	55                   	push   %ebp
80104d0a:	89 e5                	mov    %esp,%ebp
80104d0c:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104d0f:	e8 aa e5 ff ff       	call   801032be <myproc>
80104d14:	8b 40 10             	mov    0x10(%eax),%eax
}
80104d17:	c9                   	leave  
80104d18:	c3                   	ret    

80104d19 <sys_sbrk>:

int
sys_sbrk(void)
{
80104d19:	55                   	push   %ebp
80104d1a:	89 e5                	mov    %esp,%ebp
80104d1c:	53                   	push   %ebx
80104d1d:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104d20:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d23:	50                   	push   %eax
80104d24:	6a 00                	push   $0x0
80104d26:	e8 29 f2 ff ff       	call   80103f54 <argint>
80104d2b:	83 c4 10             	add    $0x10,%esp
80104d2e:	85 c0                	test   %eax,%eax
80104d30:	78 27                	js     80104d59 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104d32:	e8 87 e5 ff ff       	call   801032be <myproc>
80104d37:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104d39:	83 ec 0c             	sub    $0xc,%esp
80104d3c:	ff 75 f4             	pushl  -0xc(%ebp)
80104d3f:	e8 85 e6 ff ff       	call   801033c9 <growproc>
80104d44:	83 c4 10             	add    $0x10,%esp
80104d47:	85 c0                	test   %eax,%eax
80104d49:	78 07                	js     80104d52 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104d4b:	89 d8                	mov    %ebx,%eax
80104d4d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d50:	c9                   	leave  
80104d51:	c3                   	ret    
    return -1;
80104d52:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d57:	eb f2                	jmp    80104d4b <sys_sbrk+0x32>
    return -1;
80104d59:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d5e:	eb eb                	jmp    80104d4b <sys_sbrk+0x32>

80104d60 <sys_sleep>:

int
sys_sleep(void)
{
80104d60:	55                   	push   %ebp
80104d61:	89 e5                	mov    %esp,%ebp
80104d63:	53                   	push   %ebx
80104d64:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104d67:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d6a:	50                   	push   %eax
80104d6b:	6a 00                	push   $0x0
80104d6d:	e8 e2 f1 ff ff       	call   80103f54 <argint>
80104d72:	83 c4 10             	add    $0x10,%esp
80104d75:	85 c0                	test   %eax,%eax
80104d77:	78 75                	js     80104dee <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104d79:	83 ec 0c             	sub    $0xc,%esp
80104d7c:	68 a0 3c 13 80       	push   $0x80133ca0
80104d81:	e8 d7 ee ff ff       	call   80103c5d <acquire>
  ticks0 = ticks;
80104d86:	8b 1d e0 44 13 80    	mov    0x801344e0,%ebx
  while(ticks - ticks0 < n){
80104d8c:	83 c4 10             	add    $0x10,%esp
80104d8f:	a1 e0 44 13 80       	mov    0x801344e0,%eax
80104d94:	29 d8                	sub    %ebx,%eax
80104d96:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104d99:	73 39                	jae    80104dd4 <sys_sleep+0x74>
    if(myproc()->killed){
80104d9b:	e8 1e e5 ff ff       	call   801032be <myproc>
80104da0:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104da4:	75 17                	jne    80104dbd <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104da6:	83 ec 08             	sub    $0x8,%esp
80104da9:	68 a0 3c 13 80       	push   $0x80133ca0
80104dae:	68 e0 44 13 80       	push   $0x801344e0
80104db3:	e8 aa e9 ff ff       	call   80103762 <sleep>
80104db8:	83 c4 10             	add    $0x10,%esp
80104dbb:	eb d2                	jmp    80104d8f <sys_sleep+0x2f>
      release(&tickslock);
80104dbd:	83 ec 0c             	sub    $0xc,%esp
80104dc0:	68 a0 3c 13 80       	push   $0x80133ca0
80104dc5:	e8 f8 ee ff ff       	call   80103cc2 <release>
      return -1;
80104dca:	83 c4 10             	add    $0x10,%esp
80104dcd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dd2:	eb 15                	jmp    80104de9 <sys_sleep+0x89>
  }
  release(&tickslock);
80104dd4:	83 ec 0c             	sub    $0xc,%esp
80104dd7:	68 a0 3c 13 80       	push   $0x80133ca0
80104ddc:	e8 e1 ee ff ff       	call   80103cc2 <release>
  return 0;
80104de1:	83 c4 10             	add    $0x10,%esp
80104de4:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104de9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104dec:	c9                   	leave  
80104ded:	c3                   	ret    
    return -1;
80104dee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104df3:	eb f4                	jmp    80104de9 <sys_sleep+0x89>

80104df5 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104df5:	55                   	push   %ebp
80104df6:	89 e5                	mov    %esp,%ebp
80104df8:	53                   	push   %ebx
80104df9:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104dfc:	68 a0 3c 13 80       	push   $0x80133ca0
80104e01:	e8 57 ee ff ff       	call   80103c5d <acquire>
  xticks = ticks;
80104e06:	8b 1d e0 44 13 80    	mov    0x801344e0,%ebx
  release(&tickslock);
80104e0c:	c7 04 24 a0 3c 13 80 	movl   $0x80133ca0,(%esp)
80104e13:	e8 aa ee ff ff       	call   80103cc2 <release>
  return xticks;
}
80104e18:	89 d8                	mov    %ebx,%eax
80104e1a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e1d:	c9                   	leave  
80104e1e:	c3                   	ret    

80104e1f <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104e1f:	1e                   	push   %ds
  pushl %es
80104e20:	06                   	push   %es
  pushl %fs
80104e21:	0f a0                	push   %fs
  pushl %gs
80104e23:	0f a8                	push   %gs
  pushal
80104e25:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104e26:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104e2a:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104e2c:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104e2e:	54                   	push   %esp
  call trap
80104e2f:	e8 e3 00 00 00       	call   80104f17 <trap>
  addl $4, %esp
80104e34:	83 c4 04             	add    $0x4,%esp

80104e37 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104e37:	61                   	popa   
  popl %gs
80104e38:	0f a9                	pop    %gs
  popl %fs
80104e3a:	0f a1                	pop    %fs
  popl %es
80104e3c:	07                   	pop    %es
  popl %ds
80104e3d:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104e3e:	83 c4 08             	add    $0x8,%esp
  iret
80104e41:	cf                   	iret   

80104e42 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104e42:	55                   	push   %ebp
80104e43:	89 e5                	mov    %esp,%ebp
80104e45:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104e48:	b8 00 00 00 00       	mov    $0x0,%eax
80104e4d:	eb 4a                	jmp    80104e99 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104e4f:	8b 0c 85 08 90 10 80 	mov    -0x7fef6ff8(,%eax,4),%ecx
80104e56:	66 89 0c c5 e0 3c 13 	mov    %cx,-0x7fecc320(,%eax,8)
80104e5d:	80 
80104e5e:	66 c7 04 c5 e2 3c 13 	movw   $0x8,-0x7fecc31e(,%eax,8)
80104e65:	80 08 00 
80104e68:	c6 04 c5 e4 3c 13 80 	movb   $0x0,-0x7fecc31c(,%eax,8)
80104e6f:	00 
80104e70:	0f b6 14 c5 e5 3c 13 	movzbl -0x7fecc31b(,%eax,8),%edx
80104e77:	80 
80104e78:	83 e2 f0             	and    $0xfffffff0,%edx
80104e7b:	83 ca 0e             	or     $0xe,%edx
80104e7e:	83 e2 8f             	and    $0xffffff8f,%edx
80104e81:	83 ca 80             	or     $0xffffff80,%edx
80104e84:	88 14 c5 e5 3c 13 80 	mov    %dl,-0x7fecc31b(,%eax,8)
80104e8b:	c1 e9 10             	shr    $0x10,%ecx
80104e8e:	66 89 0c c5 e6 3c 13 	mov    %cx,-0x7fecc31a(,%eax,8)
80104e95:	80 
  for(i = 0; i < 256; i++)
80104e96:	83 c0 01             	add    $0x1,%eax
80104e99:	3d ff 00 00 00       	cmp    $0xff,%eax
80104e9e:	7e af                	jle    80104e4f <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104ea0:	8b 15 08 91 10 80    	mov    0x80109108,%edx
80104ea6:	66 89 15 e0 3e 13 80 	mov    %dx,0x80133ee0
80104ead:	66 c7 05 e2 3e 13 80 	movw   $0x8,0x80133ee2
80104eb4:	08 00 
80104eb6:	c6 05 e4 3e 13 80 00 	movb   $0x0,0x80133ee4
80104ebd:	0f b6 05 e5 3e 13 80 	movzbl 0x80133ee5,%eax
80104ec4:	83 c8 0f             	or     $0xf,%eax
80104ec7:	83 e0 ef             	and    $0xffffffef,%eax
80104eca:	83 c8 e0             	or     $0xffffffe0,%eax
80104ecd:	a2 e5 3e 13 80       	mov    %al,0x80133ee5
80104ed2:	c1 ea 10             	shr    $0x10,%edx
80104ed5:	66 89 15 e6 3e 13 80 	mov    %dx,0x80133ee6

  initlock(&tickslock, "time");
80104edc:	83 ec 08             	sub    $0x8,%esp
80104edf:	68 1d 6d 10 80       	push   $0x80106d1d
80104ee4:	68 a0 3c 13 80       	push   $0x80133ca0
80104ee9:	e8 33 ec ff ff       	call   80103b21 <initlock>
}
80104eee:	83 c4 10             	add    $0x10,%esp
80104ef1:	c9                   	leave  
80104ef2:	c3                   	ret    

80104ef3 <idtinit>:

void
idtinit(void)
{
80104ef3:	55                   	push   %ebp
80104ef4:	89 e5                	mov    %esp,%ebp
80104ef6:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104ef9:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104eff:	b8 e0 3c 13 80       	mov    $0x80133ce0,%eax
80104f04:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104f08:	c1 e8 10             	shr    $0x10,%eax
80104f0b:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104f0f:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104f12:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104f15:	c9                   	leave  
80104f16:	c3                   	ret    

80104f17 <trap>:

void
trap(struct trapframe *tf)
{
80104f17:	55                   	push   %ebp
80104f18:	89 e5                	mov    %esp,%ebp
80104f1a:	57                   	push   %edi
80104f1b:	56                   	push   %esi
80104f1c:	53                   	push   %ebx
80104f1d:	83 ec 1c             	sub    $0x1c,%esp
80104f20:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104f23:	8b 43 30             	mov    0x30(%ebx),%eax
80104f26:	83 f8 40             	cmp    $0x40,%eax
80104f29:	74 13                	je     80104f3e <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104f2b:	83 e8 20             	sub    $0x20,%eax
80104f2e:	83 f8 1f             	cmp    $0x1f,%eax
80104f31:	0f 87 3a 01 00 00    	ja     80105071 <trap+0x15a>
80104f37:	ff 24 85 c4 6d 10 80 	jmp    *-0x7fef923c(,%eax,4)
    if(myproc()->killed)
80104f3e:	e8 7b e3 ff ff       	call   801032be <myproc>
80104f43:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f47:	75 1f                	jne    80104f68 <trap+0x51>
    myproc()->tf = tf;
80104f49:	e8 70 e3 ff ff       	call   801032be <myproc>
80104f4e:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80104f51:	e8 c1 f0 ff ff       	call   80104017 <syscall>
    if(myproc()->killed)
80104f56:	e8 63 e3 ff ff       	call   801032be <myproc>
80104f5b:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f5f:	74 7e                	je     80104fdf <trap+0xc8>
      exit();
80104f61:	e8 04 e7 ff ff       	call   8010366a <exit>
80104f66:	eb 77                	jmp    80104fdf <trap+0xc8>
      exit();
80104f68:	e8 fd e6 ff ff       	call   8010366a <exit>
80104f6d:	eb da                	jmp    80104f49 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80104f6f:	e8 2f e3 ff ff       	call   801032a3 <cpuid>
80104f74:	85 c0                	test   %eax,%eax
80104f76:	74 6f                	je     80104fe7 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80104f78:	e8 e4 d4 ff ff       	call   80102461 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104f7d:	e8 3c e3 ff ff       	call   801032be <myproc>
80104f82:	85 c0                	test   %eax,%eax
80104f84:	74 1c                	je     80104fa2 <trap+0x8b>
80104f86:	e8 33 e3 ff ff       	call   801032be <myproc>
80104f8b:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f8f:	74 11                	je     80104fa2 <trap+0x8b>
80104f91:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104f95:	83 e0 03             	and    $0x3,%eax
80104f98:	66 83 f8 03          	cmp    $0x3,%ax
80104f9c:	0f 84 62 01 00 00    	je     80105104 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80104fa2:	e8 17 e3 ff ff       	call   801032be <myproc>
80104fa7:	85 c0                	test   %eax,%eax
80104fa9:	74 0f                	je     80104fba <trap+0xa3>
80104fab:	e8 0e e3 ff ff       	call   801032be <myproc>
80104fb0:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80104fb4:	0f 84 54 01 00 00    	je     8010510e <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104fba:	e8 ff e2 ff ff       	call   801032be <myproc>
80104fbf:	85 c0                	test   %eax,%eax
80104fc1:	74 1c                	je     80104fdf <trap+0xc8>
80104fc3:	e8 f6 e2 ff ff       	call   801032be <myproc>
80104fc8:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fcc:	74 11                	je     80104fdf <trap+0xc8>
80104fce:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104fd2:	83 e0 03             	and    $0x3,%eax
80104fd5:	66 83 f8 03          	cmp    $0x3,%ax
80104fd9:	0f 84 43 01 00 00    	je     80105122 <trap+0x20b>
    exit();
}
80104fdf:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104fe2:	5b                   	pop    %ebx
80104fe3:	5e                   	pop    %esi
80104fe4:	5f                   	pop    %edi
80104fe5:	5d                   	pop    %ebp
80104fe6:	c3                   	ret    
      acquire(&tickslock);
80104fe7:	83 ec 0c             	sub    $0xc,%esp
80104fea:	68 a0 3c 13 80       	push   $0x80133ca0
80104fef:	e8 69 ec ff ff       	call   80103c5d <acquire>
      ticks++;
80104ff4:	83 05 e0 44 13 80 01 	addl   $0x1,0x801344e0
      wakeup(&ticks);
80104ffb:	c7 04 24 e0 44 13 80 	movl   $0x801344e0,(%esp)
80105002:	e8 c0 e8 ff ff       	call   801038c7 <wakeup>
      release(&tickslock);
80105007:	c7 04 24 a0 3c 13 80 	movl   $0x80133ca0,(%esp)
8010500e:	e8 af ec ff ff       	call   80103cc2 <release>
80105013:	83 c4 10             	add    $0x10,%esp
80105016:	e9 5d ff ff ff       	jmp    80104f78 <trap+0x61>
    ideintr();
8010501b:	e8 53 cd ff ff       	call   80101d73 <ideintr>
    lapiceoi();
80105020:	e8 3c d4 ff ff       	call   80102461 <lapiceoi>
    break;
80105025:	e9 53 ff ff ff       	jmp    80104f7d <trap+0x66>
    kbdintr();
8010502a:	e8 76 d2 ff ff       	call   801022a5 <kbdintr>
    lapiceoi();
8010502f:	e8 2d d4 ff ff       	call   80102461 <lapiceoi>
    break;
80105034:	e9 44 ff ff ff       	jmp    80104f7d <trap+0x66>
    uartintr();
80105039:	e8 05 02 00 00       	call   80105243 <uartintr>
    lapiceoi();
8010503e:	e8 1e d4 ff ff       	call   80102461 <lapiceoi>
    break;
80105043:	e9 35 ff ff ff       	jmp    80104f7d <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105048:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
8010504b:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010504f:	e8 4f e2 ff ff       	call   801032a3 <cpuid>
80105054:	57                   	push   %edi
80105055:	0f b7 f6             	movzwl %si,%esi
80105058:	56                   	push   %esi
80105059:	50                   	push   %eax
8010505a:	68 28 6d 10 80       	push   $0x80106d28
8010505f:	e8 a7 b5 ff ff       	call   8010060b <cprintf>
    lapiceoi();
80105064:	e8 f8 d3 ff ff       	call   80102461 <lapiceoi>
    break;
80105069:	83 c4 10             	add    $0x10,%esp
8010506c:	e9 0c ff ff ff       	jmp    80104f7d <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105071:	e8 48 e2 ff ff       	call   801032be <myproc>
80105076:	85 c0                	test   %eax,%eax
80105078:	74 5f                	je     801050d9 <trap+0x1c2>
8010507a:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
8010507e:	74 59                	je     801050d9 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105080:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105083:	8b 43 38             	mov    0x38(%ebx),%eax
80105086:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105089:	e8 15 e2 ff ff       	call   801032a3 <cpuid>
8010508e:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105091:	8b 53 34             	mov    0x34(%ebx),%edx
80105094:	89 55 dc             	mov    %edx,-0x24(%ebp)
80105097:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
8010509a:	e8 1f e2 ff ff       	call   801032be <myproc>
8010509f:	8d 48 6c             	lea    0x6c(%eax),%ecx
801050a2:	89 4d d8             	mov    %ecx,-0x28(%ebp)
801050a5:	e8 14 e2 ff ff       	call   801032be <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801050aa:	57                   	push   %edi
801050ab:	ff 75 e4             	pushl  -0x1c(%ebp)
801050ae:	ff 75 e0             	pushl  -0x20(%ebp)
801050b1:	ff 75 dc             	pushl  -0x24(%ebp)
801050b4:	56                   	push   %esi
801050b5:	ff 75 d8             	pushl  -0x28(%ebp)
801050b8:	ff 70 10             	pushl  0x10(%eax)
801050bb:	68 80 6d 10 80       	push   $0x80106d80
801050c0:	e8 46 b5 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
801050c5:	83 c4 20             	add    $0x20,%esp
801050c8:	e8 f1 e1 ff ff       	call   801032be <myproc>
801050cd:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801050d4:	e9 a4 fe ff ff       	jmp    80104f7d <trap+0x66>
801050d9:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801050dc:	8b 73 38             	mov    0x38(%ebx),%esi
801050df:	e8 bf e1 ff ff       	call   801032a3 <cpuid>
801050e4:	83 ec 0c             	sub    $0xc,%esp
801050e7:	57                   	push   %edi
801050e8:	56                   	push   %esi
801050e9:	50                   	push   %eax
801050ea:	ff 73 30             	pushl  0x30(%ebx)
801050ed:	68 4c 6d 10 80       	push   $0x80106d4c
801050f2:	e8 14 b5 ff ff       	call   8010060b <cprintf>
      panic("trap");
801050f7:	83 c4 14             	add    $0x14,%esp
801050fa:	68 22 6d 10 80       	push   $0x80106d22
801050ff:	e8 44 b2 ff ff       	call   80100348 <panic>
    exit();
80105104:	e8 61 e5 ff ff       	call   8010366a <exit>
80105109:	e9 94 fe ff ff       	jmp    80104fa2 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
8010510e:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
80105112:	0f 85 a2 fe ff ff    	jne    80104fba <trap+0xa3>
    yield();
80105118:	e8 13 e6 ff ff       	call   80103730 <yield>
8010511d:	e9 98 fe ff ff       	jmp    80104fba <trap+0xa3>
    exit();
80105122:	e8 43 e5 ff ff       	call   8010366a <exit>
80105127:	e9 b3 fe ff ff       	jmp    80104fdf <trap+0xc8>

8010512c <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
8010512c:	55                   	push   %ebp
8010512d:	89 e5                	mov    %esp,%ebp
  if(!uart)
8010512f:	83 3d c8 95 10 80 00 	cmpl   $0x0,0x801095c8
80105136:	74 15                	je     8010514d <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105138:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010513d:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
8010513e:	a8 01                	test   $0x1,%al
80105140:	74 12                	je     80105154 <uartgetc+0x28>
80105142:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105147:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
80105148:	0f b6 c0             	movzbl %al,%eax
}
8010514b:	5d                   	pop    %ebp
8010514c:	c3                   	ret    
    return -1;
8010514d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105152:	eb f7                	jmp    8010514b <uartgetc+0x1f>
    return -1;
80105154:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105159:	eb f0                	jmp    8010514b <uartgetc+0x1f>

8010515b <uartputc>:
  if(!uart)
8010515b:	83 3d c8 95 10 80 00 	cmpl   $0x0,0x801095c8
80105162:	74 3b                	je     8010519f <uartputc+0x44>
{
80105164:	55                   	push   %ebp
80105165:	89 e5                	mov    %esp,%ebp
80105167:	53                   	push   %ebx
80105168:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010516b:	bb 00 00 00 00       	mov    $0x0,%ebx
80105170:	eb 10                	jmp    80105182 <uartputc+0x27>
    microdelay(10);
80105172:	83 ec 0c             	sub    $0xc,%esp
80105175:	6a 0a                	push   $0xa
80105177:	e8 04 d3 ff ff       	call   80102480 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010517c:	83 c3 01             	add    $0x1,%ebx
8010517f:	83 c4 10             	add    $0x10,%esp
80105182:	83 fb 7f             	cmp    $0x7f,%ebx
80105185:	7f 0a                	jg     80105191 <uartputc+0x36>
80105187:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010518c:	ec                   	in     (%dx),%al
8010518d:	a8 20                	test   $0x20,%al
8010518f:	74 e1                	je     80105172 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105191:	8b 45 08             	mov    0x8(%ebp),%eax
80105194:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105199:	ee                   	out    %al,(%dx)
}
8010519a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010519d:	c9                   	leave  
8010519e:	c3                   	ret    
8010519f:	f3 c3                	repz ret 

801051a1 <uartinit>:
{
801051a1:	55                   	push   %ebp
801051a2:	89 e5                	mov    %esp,%ebp
801051a4:	56                   	push   %esi
801051a5:	53                   	push   %ebx
801051a6:	b9 00 00 00 00       	mov    $0x0,%ecx
801051ab:	ba fa 03 00 00       	mov    $0x3fa,%edx
801051b0:	89 c8                	mov    %ecx,%eax
801051b2:	ee                   	out    %al,(%dx)
801051b3:	be fb 03 00 00       	mov    $0x3fb,%esi
801051b8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
801051bd:	89 f2                	mov    %esi,%edx
801051bf:	ee                   	out    %al,(%dx)
801051c0:	b8 0c 00 00 00       	mov    $0xc,%eax
801051c5:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051ca:	ee                   	out    %al,(%dx)
801051cb:	bb f9 03 00 00       	mov    $0x3f9,%ebx
801051d0:	89 c8                	mov    %ecx,%eax
801051d2:	89 da                	mov    %ebx,%edx
801051d4:	ee                   	out    %al,(%dx)
801051d5:	b8 03 00 00 00       	mov    $0x3,%eax
801051da:	89 f2                	mov    %esi,%edx
801051dc:	ee                   	out    %al,(%dx)
801051dd:	ba fc 03 00 00       	mov    $0x3fc,%edx
801051e2:	89 c8                	mov    %ecx,%eax
801051e4:	ee                   	out    %al,(%dx)
801051e5:	b8 01 00 00 00       	mov    $0x1,%eax
801051ea:	89 da                	mov    %ebx,%edx
801051ec:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801051ed:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051f2:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801051f3:	3c ff                	cmp    $0xff,%al
801051f5:	74 45                	je     8010523c <uartinit+0x9b>
  uart = 1;
801051f7:	c7 05 c8 95 10 80 01 	movl   $0x1,0x801095c8
801051fe:	00 00 00 
80105201:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105206:	ec                   	in     (%dx),%al
80105207:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010520c:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
8010520d:	83 ec 08             	sub    $0x8,%esp
80105210:	6a 00                	push   $0x0
80105212:	6a 04                	push   $0x4
80105214:	e8 65 cd ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
80105219:	83 c4 10             	add    $0x10,%esp
8010521c:	bb 44 6e 10 80       	mov    $0x80106e44,%ebx
80105221:	eb 12                	jmp    80105235 <uartinit+0x94>
    uartputc(*p);
80105223:	83 ec 0c             	sub    $0xc,%esp
80105226:	0f be c0             	movsbl %al,%eax
80105229:	50                   	push   %eax
8010522a:	e8 2c ff ff ff       	call   8010515b <uartputc>
  for(p="xv6...\n"; *p; p++)
8010522f:	83 c3 01             	add    $0x1,%ebx
80105232:	83 c4 10             	add    $0x10,%esp
80105235:	0f b6 03             	movzbl (%ebx),%eax
80105238:	84 c0                	test   %al,%al
8010523a:	75 e7                	jne    80105223 <uartinit+0x82>
}
8010523c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010523f:	5b                   	pop    %ebx
80105240:	5e                   	pop    %esi
80105241:	5d                   	pop    %ebp
80105242:	c3                   	ret    

80105243 <uartintr>:

void
uartintr(void)
{
80105243:	55                   	push   %ebp
80105244:	89 e5                	mov    %esp,%ebp
80105246:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
80105249:	68 2c 51 10 80       	push   $0x8010512c
8010524e:	e8 eb b4 ff ff       	call   8010073e <consoleintr>
}
80105253:	83 c4 10             	add    $0x10,%esp
80105256:	c9                   	leave  
80105257:	c3                   	ret    

80105258 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80105258:	6a 00                	push   $0x0
  pushl $0
8010525a:	6a 00                	push   $0x0
  jmp alltraps
8010525c:	e9 be fb ff ff       	jmp    80104e1f <alltraps>

80105261 <vector1>:
.globl vector1
vector1:
  pushl $0
80105261:	6a 00                	push   $0x0
  pushl $1
80105263:	6a 01                	push   $0x1
  jmp alltraps
80105265:	e9 b5 fb ff ff       	jmp    80104e1f <alltraps>

8010526a <vector2>:
.globl vector2
vector2:
  pushl $0
8010526a:	6a 00                	push   $0x0
  pushl $2
8010526c:	6a 02                	push   $0x2
  jmp alltraps
8010526e:	e9 ac fb ff ff       	jmp    80104e1f <alltraps>

80105273 <vector3>:
.globl vector3
vector3:
  pushl $0
80105273:	6a 00                	push   $0x0
  pushl $3
80105275:	6a 03                	push   $0x3
  jmp alltraps
80105277:	e9 a3 fb ff ff       	jmp    80104e1f <alltraps>

8010527c <vector4>:
.globl vector4
vector4:
  pushl $0
8010527c:	6a 00                	push   $0x0
  pushl $4
8010527e:	6a 04                	push   $0x4
  jmp alltraps
80105280:	e9 9a fb ff ff       	jmp    80104e1f <alltraps>

80105285 <vector5>:
.globl vector5
vector5:
  pushl $0
80105285:	6a 00                	push   $0x0
  pushl $5
80105287:	6a 05                	push   $0x5
  jmp alltraps
80105289:	e9 91 fb ff ff       	jmp    80104e1f <alltraps>

8010528e <vector6>:
.globl vector6
vector6:
  pushl $0
8010528e:	6a 00                	push   $0x0
  pushl $6
80105290:	6a 06                	push   $0x6
  jmp alltraps
80105292:	e9 88 fb ff ff       	jmp    80104e1f <alltraps>

80105297 <vector7>:
.globl vector7
vector7:
  pushl $0
80105297:	6a 00                	push   $0x0
  pushl $7
80105299:	6a 07                	push   $0x7
  jmp alltraps
8010529b:	e9 7f fb ff ff       	jmp    80104e1f <alltraps>

801052a0 <vector8>:
.globl vector8
vector8:
  pushl $8
801052a0:	6a 08                	push   $0x8
  jmp alltraps
801052a2:	e9 78 fb ff ff       	jmp    80104e1f <alltraps>

801052a7 <vector9>:
.globl vector9
vector9:
  pushl $0
801052a7:	6a 00                	push   $0x0
  pushl $9
801052a9:	6a 09                	push   $0x9
  jmp alltraps
801052ab:	e9 6f fb ff ff       	jmp    80104e1f <alltraps>

801052b0 <vector10>:
.globl vector10
vector10:
  pushl $10
801052b0:	6a 0a                	push   $0xa
  jmp alltraps
801052b2:	e9 68 fb ff ff       	jmp    80104e1f <alltraps>

801052b7 <vector11>:
.globl vector11
vector11:
  pushl $11
801052b7:	6a 0b                	push   $0xb
  jmp alltraps
801052b9:	e9 61 fb ff ff       	jmp    80104e1f <alltraps>

801052be <vector12>:
.globl vector12
vector12:
  pushl $12
801052be:	6a 0c                	push   $0xc
  jmp alltraps
801052c0:	e9 5a fb ff ff       	jmp    80104e1f <alltraps>

801052c5 <vector13>:
.globl vector13
vector13:
  pushl $13
801052c5:	6a 0d                	push   $0xd
  jmp alltraps
801052c7:	e9 53 fb ff ff       	jmp    80104e1f <alltraps>

801052cc <vector14>:
.globl vector14
vector14:
  pushl $14
801052cc:	6a 0e                	push   $0xe
  jmp alltraps
801052ce:	e9 4c fb ff ff       	jmp    80104e1f <alltraps>

801052d3 <vector15>:
.globl vector15
vector15:
  pushl $0
801052d3:	6a 00                	push   $0x0
  pushl $15
801052d5:	6a 0f                	push   $0xf
  jmp alltraps
801052d7:	e9 43 fb ff ff       	jmp    80104e1f <alltraps>

801052dc <vector16>:
.globl vector16
vector16:
  pushl $0
801052dc:	6a 00                	push   $0x0
  pushl $16
801052de:	6a 10                	push   $0x10
  jmp alltraps
801052e0:	e9 3a fb ff ff       	jmp    80104e1f <alltraps>

801052e5 <vector17>:
.globl vector17
vector17:
  pushl $17
801052e5:	6a 11                	push   $0x11
  jmp alltraps
801052e7:	e9 33 fb ff ff       	jmp    80104e1f <alltraps>

801052ec <vector18>:
.globl vector18
vector18:
  pushl $0
801052ec:	6a 00                	push   $0x0
  pushl $18
801052ee:	6a 12                	push   $0x12
  jmp alltraps
801052f0:	e9 2a fb ff ff       	jmp    80104e1f <alltraps>

801052f5 <vector19>:
.globl vector19
vector19:
  pushl $0
801052f5:	6a 00                	push   $0x0
  pushl $19
801052f7:	6a 13                	push   $0x13
  jmp alltraps
801052f9:	e9 21 fb ff ff       	jmp    80104e1f <alltraps>

801052fe <vector20>:
.globl vector20
vector20:
  pushl $0
801052fe:	6a 00                	push   $0x0
  pushl $20
80105300:	6a 14                	push   $0x14
  jmp alltraps
80105302:	e9 18 fb ff ff       	jmp    80104e1f <alltraps>

80105307 <vector21>:
.globl vector21
vector21:
  pushl $0
80105307:	6a 00                	push   $0x0
  pushl $21
80105309:	6a 15                	push   $0x15
  jmp alltraps
8010530b:	e9 0f fb ff ff       	jmp    80104e1f <alltraps>

80105310 <vector22>:
.globl vector22
vector22:
  pushl $0
80105310:	6a 00                	push   $0x0
  pushl $22
80105312:	6a 16                	push   $0x16
  jmp alltraps
80105314:	e9 06 fb ff ff       	jmp    80104e1f <alltraps>

80105319 <vector23>:
.globl vector23
vector23:
  pushl $0
80105319:	6a 00                	push   $0x0
  pushl $23
8010531b:	6a 17                	push   $0x17
  jmp alltraps
8010531d:	e9 fd fa ff ff       	jmp    80104e1f <alltraps>

80105322 <vector24>:
.globl vector24
vector24:
  pushl $0
80105322:	6a 00                	push   $0x0
  pushl $24
80105324:	6a 18                	push   $0x18
  jmp alltraps
80105326:	e9 f4 fa ff ff       	jmp    80104e1f <alltraps>

8010532b <vector25>:
.globl vector25
vector25:
  pushl $0
8010532b:	6a 00                	push   $0x0
  pushl $25
8010532d:	6a 19                	push   $0x19
  jmp alltraps
8010532f:	e9 eb fa ff ff       	jmp    80104e1f <alltraps>

80105334 <vector26>:
.globl vector26
vector26:
  pushl $0
80105334:	6a 00                	push   $0x0
  pushl $26
80105336:	6a 1a                	push   $0x1a
  jmp alltraps
80105338:	e9 e2 fa ff ff       	jmp    80104e1f <alltraps>

8010533d <vector27>:
.globl vector27
vector27:
  pushl $0
8010533d:	6a 00                	push   $0x0
  pushl $27
8010533f:	6a 1b                	push   $0x1b
  jmp alltraps
80105341:	e9 d9 fa ff ff       	jmp    80104e1f <alltraps>

80105346 <vector28>:
.globl vector28
vector28:
  pushl $0
80105346:	6a 00                	push   $0x0
  pushl $28
80105348:	6a 1c                	push   $0x1c
  jmp alltraps
8010534a:	e9 d0 fa ff ff       	jmp    80104e1f <alltraps>

8010534f <vector29>:
.globl vector29
vector29:
  pushl $0
8010534f:	6a 00                	push   $0x0
  pushl $29
80105351:	6a 1d                	push   $0x1d
  jmp alltraps
80105353:	e9 c7 fa ff ff       	jmp    80104e1f <alltraps>

80105358 <vector30>:
.globl vector30
vector30:
  pushl $0
80105358:	6a 00                	push   $0x0
  pushl $30
8010535a:	6a 1e                	push   $0x1e
  jmp alltraps
8010535c:	e9 be fa ff ff       	jmp    80104e1f <alltraps>

80105361 <vector31>:
.globl vector31
vector31:
  pushl $0
80105361:	6a 00                	push   $0x0
  pushl $31
80105363:	6a 1f                	push   $0x1f
  jmp alltraps
80105365:	e9 b5 fa ff ff       	jmp    80104e1f <alltraps>

8010536a <vector32>:
.globl vector32
vector32:
  pushl $0
8010536a:	6a 00                	push   $0x0
  pushl $32
8010536c:	6a 20                	push   $0x20
  jmp alltraps
8010536e:	e9 ac fa ff ff       	jmp    80104e1f <alltraps>

80105373 <vector33>:
.globl vector33
vector33:
  pushl $0
80105373:	6a 00                	push   $0x0
  pushl $33
80105375:	6a 21                	push   $0x21
  jmp alltraps
80105377:	e9 a3 fa ff ff       	jmp    80104e1f <alltraps>

8010537c <vector34>:
.globl vector34
vector34:
  pushl $0
8010537c:	6a 00                	push   $0x0
  pushl $34
8010537e:	6a 22                	push   $0x22
  jmp alltraps
80105380:	e9 9a fa ff ff       	jmp    80104e1f <alltraps>

80105385 <vector35>:
.globl vector35
vector35:
  pushl $0
80105385:	6a 00                	push   $0x0
  pushl $35
80105387:	6a 23                	push   $0x23
  jmp alltraps
80105389:	e9 91 fa ff ff       	jmp    80104e1f <alltraps>

8010538e <vector36>:
.globl vector36
vector36:
  pushl $0
8010538e:	6a 00                	push   $0x0
  pushl $36
80105390:	6a 24                	push   $0x24
  jmp alltraps
80105392:	e9 88 fa ff ff       	jmp    80104e1f <alltraps>

80105397 <vector37>:
.globl vector37
vector37:
  pushl $0
80105397:	6a 00                	push   $0x0
  pushl $37
80105399:	6a 25                	push   $0x25
  jmp alltraps
8010539b:	e9 7f fa ff ff       	jmp    80104e1f <alltraps>

801053a0 <vector38>:
.globl vector38
vector38:
  pushl $0
801053a0:	6a 00                	push   $0x0
  pushl $38
801053a2:	6a 26                	push   $0x26
  jmp alltraps
801053a4:	e9 76 fa ff ff       	jmp    80104e1f <alltraps>

801053a9 <vector39>:
.globl vector39
vector39:
  pushl $0
801053a9:	6a 00                	push   $0x0
  pushl $39
801053ab:	6a 27                	push   $0x27
  jmp alltraps
801053ad:	e9 6d fa ff ff       	jmp    80104e1f <alltraps>

801053b2 <vector40>:
.globl vector40
vector40:
  pushl $0
801053b2:	6a 00                	push   $0x0
  pushl $40
801053b4:	6a 28                	push   $0x28
  jmp alltraps
801053b6:	e9 64 fa ff ff       	jmp    80104e1f <alltraps>

801053bb <vector41>:
.globl vector41
vector41:
  pushl $0
801053bb:	6a 00                	push   $0x0
  pushl $41
801053bd:	6a 29                	push   $0x29
  jmp alltraps
801053bf:	e9 5b fa ff ff       	jmp    80104e1f <alltraps>

801053c4 <vector42>:
.globl vector42
vector42:
  pushl $0
801053c4:	6a 00                	push   $0x0
  pushl $42
801053c6:	6a 2a                	push   $0x2a
  jmp alltraps
801053c8:	e9 52 fa ff ff       	jmp    80104e1f <alltraps>

801053cd <vector43>:
.globl vector43
vector43:
  pushl $0
801053cd:	6a 00                	push   $0x0
  pushl $43
801053cf:	6a 2b                	push   $0x2b
  jmp alltraps
801053d1:	e9 49 fa ff ff       	jmp    80104e1f <alltraps>

801053d6 <vector44>:
.globl vector44
vector44:
  pushl $0
801053d6:	6a 00                	push   $0x0
  pushl $44
801053d8:	6a 2c                	push   $0x2c
  jmp alltraps
801053da:	e9 40 fa ff ff       	jmp    80104e1f <alltraps>

801053df <vector45>:
.globl vector45
vector45:
  pushl $0
801053df:	6a 00                	push   $0x0
  pushl $45
801053e1:	6a 2d                	push   $0x2d
  jmp alltraps
801053e3:	e9 37 fa ff ff       	jmp    80104e1f <alltraps>

801053e8 <vector46>:
.globl vector46
vector46:
  pushl $0
801053e8:	6a 00                	push   $0x0
  pushl $46
801053ea:	6a 2e                	push   $0x2e
  jmp alltraps
801053ec:	e9 2e fa ff ff       	jmp    80104e1f <alltraps>

801053f1 <vector47>:
.globl vector47
vector47:
  pushl $0
801053f1:	6a 00                	push   $0x0
  pushl $47
801053f3:	6a 2f                	push   $0x2f
  jmp alltraps
801053f5:	e9 25 fa ff ff       	jmp    80104e1f <alltraps>

801053fa <vector48>:
.globl vector48
vector48:
  pushl $0
801053fa:	6a 00                	push   $0x0
  pushl $48
801053fc:	6a 30                	push   $0x30
  jmp alltraps
801053fe:	e9 1c fa ff ff       	jmp    80104e1f <alltraps>

80105403 <vector49>:
.globl vector49
vector49:
  pushl $0
80105403:	6a 00                	push   $0x0
  pushl $49
80105405:	6a 31                	push   $0x31
  jmp alltraps
80105407:	e9 13 fa ff ff       	jmp    80104e1f <alltraps>

8010540c <vector50>:
.globl vector50
vector50:
  pushl $0
8010540c:	6a 00                	push   $0x0
  pushl $50
8010540e:	6a 32                	push   $0x32
  jmp alltraps
80105410:	e9 0a fa ff ff       	jmp    80104e1f <alltraps>

80105415 <vector51>:
.globl vector51
vector51:
  pushl $0
80105415:	6a 00                	push   $0x0
  pushl $51
80105417:	6a 33                	push   $0x33
  jmp alltraps
80105419:	e9 01 fa ff ff       	jmp    80104e1f <alltraps>

8010541e <vector52>:
.globl vector52
vector52:
  pushl $0
8010541e:	6a 00                	push   $0x0
  pushl $52
80105420:	6a 34                	push   $0x34
  jmp alltraps
80105422:	e9 f8 f9 ff ff       	jmp    80104e1f <alltraps>

80105427 <vector53>:
.globl vector53
vector53:
  pushl $0
80105427:	6a 00                	push   $0x0
  pushl $53
80105429:	6a 35                	push   $0x35
  jmp alltraps
8010542b:	e9 ef f9 ff ff       	jmp    80104e1f <alltraps>

80105430 <vector54>:
.globl vector54
vector54:
  pushl $0
80105430:	6a 00                	push   $0x0
  pushl $54
80105432:	6a 36                	push   $0x36
  jmp alltraps
80105434:	e9 e6 f9 ff ff       	jmp    80104e1f <alltraps>

80105439 <vector55>:
.globl vector55
vector55:
  pushl $0
80105439:	6a 00                	push   $0x0
  pushl $55
8010543b:	6a 37                	push   $0x37
  jmp alltraps
8010543d:	e9 dd f9 ff ff       	jmp    80104e1f <alltraps>

80105442 <vector56>:
.globl vector56
vector56:
  pushl $0
80105442:	6a 00                	push   $0x0
  pushl $56
80105444:	6a 38                	push   $0x38
  jmp alltraps
80105446:	e9 d4 f9 ff ff       	jmp    80104e1f <alltraps>

8010544b <vector57>:
.globl vector57
vector57:
  pushl $0
8010544b:	6a 00                	push   $0x0
  pushl $57
8010544d:	6a 39                	push   $0x39
  jmp alltraps
8010544f:	e9 cb f9 ff ff       	jmp    80104e1f <alltraps>

80105454 <vector58>:
.globl vector58
vector58:
  pushl $0
80105454:	6a 00                	push   $0x0
  pushl $58
80105456:	6a 3a                	push   $0x3a
  jmp alltraps
80105458:	e9 c2 f9 ff ff       	jmp    80104e1f <alltraps>

8010545d <vector59>:
.globl vector59
vector59:
  pushl $0
8010545d:	6a 00                	push   $0x0
  pushl $59
8010545f:	6a 3b                	push   $0x3b
  jmp alltraps
80105461:	e9 b9 f9 ff ff       	jmp    80104e1f <alltraps>

80105466 <vector60>:
.globl vector60
vector60:
  pushl $0
80105466:	6a 00                	push   $0x0
  pushl $60
80105468:	6a 3c                	push   $0x3c
  jmp alltraps
8010546a:	e9 b0 f9 ff ff       	jmp    80104e1f <alltraps>

8010546f <vector61>:
.globl vector61
vector61:
  pushl $0
8010546f:	6a 00                	push   $0x0
  pushl $61
80105471:	6a 3d                	push   $0x3d
  jmp alltraps
80105473:	e9 a7 f9 ff ff       	jmp    80104e1f <alltraps>

80105478 <vector62>:
.globl vector62
vector62:
  pushl $0
80105478:	6a 00                	push   $0x0
  pushl $62
8010547a:	6a 3e                	push   $0x3e
  jmp alltraps
8010547c:	e9 9e f9 ff ff       	jmp    80104e1f <alltraps>

80105481 <vector63>:
.globl vector63
vector63:
  pushl $0
80105481:	6a 00                	push   $0x0
  pushl $63
80105483:	6a 3f                	push   $0x3f
  jmp alltraps
80105485:	e9 95 f9 ff ff       	jmp    80104e1f <alltraps>

8010548a <vector64>:
.globl vector64
vector64:
  pushl $0
8010548a:	6a 00                	push   $0x0
  pushl $64
8010548c:	6a 40                	push   $0x40
  jmp alltraps
8010548e:	e9 8c f9 ff ff       	jmp    80104e1f <alltraps>

80105493 <vector65>:
.globl vector65
vector65:
  pushl $0
80105493:	6a 00                	push   $0x0
  pushl $65
80105495:	6a 41                	push   $0x41
  jmp alltraps
80105497:	e9 83 f9 ff ff       	jmp    80104e1f <alltraps>

8010549c <vector66>:
.globl vector66
vector66:
  pushl $0
8010549c:	6a 00                	push   $0x0
  pushl $66
8010549e:	6a 42                	push   $0x42
  jmp alltraps
801054a0:	e9 7a f9 ff ff       	jmp    80104e1f <alltraps>

801054a5 <vector67>:
.globl vector67
vector67:
  pushl $0
801054a5:	6a 00                	push   $0x0
  pushl $67
801054a7:	6a 43                	push   $0x43
  jmp alltraps
801054a9:	e9 71 f9 ff ff       	jmp    80104e1f <alltraps>

801054ae <vector68>:
.globl vector68
vector68:
  pushl $0
801054ae:	6a 00                	push   $0x0
  pushl $68
801054b0:	6a 44                	push   $0x44
  jmp alltraps
801054b2:	e9 68 f9 ff ff       	jmp    80104e1f <alltraps>

801054b7 <vector69>:
.globl vector69
vector69:
  pushl $0
801054b7:	6a 00                	push   $0x0
  pushl $69
801054b9:	6a 45                	push   $0x45
  jmp alltraps
801054bb:	e9 5f f9 ff ff       	jmp    80104e1f <alltraps>

801054c0 <vector70>:
.globl vector70
vector70:
  pushl $0
801054c0:	6a 00                	push   $0x0
  pushl $70
801054c2:	6a 46                	push   $0x46
  jmp alltraps
801054c4:	e9 56 f9 ff ff       	jmp    80104e1f <alltraps>

801054c9 <vector71>:
.globl vector71
vector71:
  pushl $0
801054c9:	6a 00                	push   $0x0
  pushl $71
801054cb:	6a 47                	push   $0x47
  jmp alltraps
801054cd:	e9 4d f9 ff ff       	jmp    80104e1f <alltraps>

801054d2 <vector72>:
.globl vector72
vector72:
  pushl $0
801054d2:	6a 00                	push   $0x0
  pushl $72
801054d4:	6a 48                	push   $0x48
  jmp alltraps
801054d6:	e9 44 f9 ff ff       	jmp    80104e1f <alltraps>

801054db <vector73>:
.globl vector73
vector73:
  pushl $0
801054db:	6a 00                	push   $0x0
  pushl $73
801054dd:	6a 49                	push   $0x49
  jmp alltraps
801054df:	e9 3b f9 ff ff       	jmp    80104e1f <alltraps>

801054e4 <vector74>:
.globl vector74
vector74:
  pushl $0
801054e4:	6a 00                	push   $0x0
  pushl $74
801054e6:	6a 4a                	push   $0x4a
  jmp alltraps
801054e8:	e9 32 f9 ff ff       	jmp    80104e1f <alltraps>

801054ed <vector75>:
.globl vector75
vector75:
  pushl $0
801054ed:	6a 00                	push   $0x0
  pushl $75
801054ef:	6a 4b                	push   $0x4b
  jmp alltraps
801054f1:	e9 29 f9 ff ff       	jmp    80104e1f <alltraps>

801054f6 <vector76>:
.globl vector76
vector76:
  pushl $0
801054f6:	6a 00                	push   $0x0
  pushl $76
801054f8:	6a 4c                	push   $0x4c
  jmp alltraps
801054fa:	e9 20 f9 ff ff       	jmp    80104e1f <alltraps>

801054ff <vector77>:
.globl vector77
vector77:
  pushl $0
801054ff:	6a 00                	push   $0x0
  pushl $77
80105501:	6a 4d                	push   $0x4d
  jmp alltraps
80105503:	e9 17 f9 ff ff       	jmp    80104e1f <alltraps>

80105508 <vector78>:
.globl vector78
vector78:
  pushl $0
80105508:	6a 00                	push   $0x0
  pushl $78
8010550a:	6a 4e                	push   $0x4e
  jmp alltraps
8010550c:	e9 0e f9 ff ff       	jmp    80104e1f <alltraps>

80105511 <vector79>:
.globl vector79
vector79:
  pushl $0
80105511:	6a 00                	push   $0x0
  pushl $79
80105513:	6a 4f                	push   $0x4f
  jmp alltraps
80105515:	e9 05 f9 ff ff       	jmp    80104e1f <alltraps>

8010551a <vector80>:
.globl vector80
vector80:
  pushl $0
8010551a:	6a 00                	push   $0x0
  pushl $80
8010551c:	6a 50                	push   $0x50
  jmp alltraps
8010551e:	e9 fc f8 ff ff       	jmp    80104e1f <alltraps>

80105523 <vector81>:
.globl vector81
vector81:
  pushl $0
80105523:	6a 00                	push   $0x0
  pushl $81
80105525:	6a 51                	push   $0x51
  jmp alltraps
80105527:	e9 f3 f8 ff ff       	jmp    80104e1f <alltraps>

8010552c <vector82>:
.globl vector82
vector82:
  pushl $0
8010552c:	6a 00                	push   $0x0
  pushl $82
8010552e:	6a 52                	push   $0x52
  jmp alltraps
80105530:	e9 ea f8 ff ff       	jmp    80104e1f <alltraps>

80105535 <vector83>:
.globl vector83
vector83:
  pushl $0
80105535:	6a 00                	push   $0x0
  pushl $83
80105537:	6a 53                	push   $0x53
  jmp alltraps
80105539:	e9 e1 f8 ff ff       	jmp    80104e1f <alltraps>

8010553e <vector84>:
.globl vector84
vector84:
  pushl $0
8010553e:	6a 00                	push   $0x0
  pushl $84
80105540:	6a 54                	push   $0x54
  jmp alltraps
80105542:	e9 d8 f8 ff ff       	jmp    80104e1f <alltraps>

80105547 <vector85>:
.globl vector85
vector85:
  pushl $0
80105547:	6a 00                	push   $0x0
  pushl $85
80105549:	6a 55                	push   $0x55
  jmp alltraps
8010554b:	e9 cf f8 ff ff       	jmp    80104e1f <alltraps>

80105550 <vector86>:
.globl vector86
vector86:
  pushl $0
80105550:	6a 00                	push   $0x0
  pushl $86
80105552:	6a 56                	push   $0x56
  jmp alltraps
80105554:	e9 c6 f8 ff ff       	jmp    80104e1f <alltraps>

80105559 <vector87>:
.globl vector87
vector87:
  pushl $0
80105559:	6a 00                	push   $0x0
  pushl $87
8010555b:	6a 57                	push   $0x57
  jmp alltraps
8010555d:	e9 bd f8 ff ff       	jmp    80104e1f <alltraps>

80105562 <vector88>:
.globl vector88
vector88:
  pushl $0
80105562:	6a 00                	push   $0x0
  pushl $88
80105564:	6a 58                	push   $0x58
  jmp alltraps
80105566:	e9 b4 f8 ff ff       	jmp    80104e1f <alltraps>

8010556b <vector89>:
.globl vector89
vector89:
  pushl $0
8010556b:	6a 00                	push   $0x0
  pushl $89
8010556d:	6a 59                	push   $0x59
  jmp alltraps
8010556f:	e9 ab f8 ff ff       	jmp    80104e1f <alltraps>

80105574 <vector90>:
.globl vector90
vector90:
  pushl $0
80105574:	6a 00                	push   $0x0
  pushl $90
80105576:	6a 5a                	push   $0x5a
  jmp alltraps
80105578:	e9 a2 f8 ff ff       	jmp    80104e1f <alltraps>

8010557d <vector91>:
.globl vector91
vector91:
  pushl $0
8010557d:	6a 00                	push   $0x0
  pushl $91
8010557f:	6a 5b                	push   $0x5b
  jmp alltraps
80105581:	e9 99 f8 ff ff       	jmp    80104e1f <alltraps>

80105586 <vector92>:
.globl vector92
vector92:
  pushl $0
80105586:	6a 00                	push   $0x0
  pushl $92
80105588:	6a 5c                	push   $0x5c
  jmp alltraps
8010558a:	e9 90 f8 ff ff       	jmp    80104e1f <alltraps>

8010558f <vector93>:
.globl vector93
vector93:
  pushl $0
8010558f:	6a 00                	push   $0x0
  pushl $93
80105591:	6a 5d                	push   $0x5d
  jmp alltraps
80105593:	e9 87 f8 ff ff       	jmp    80104e1f <alltraps>

80105598 <vector94>:
.globl vector94
vector94:
  pushl $0
80105598:	6a 00                	push   $0x0
  pushl $94
8010559a:	6a 5e                	push   $0x5e
  jmp alltraps
8010559c:	e9 7e f8 ff ff       	jmp    80104e1f <alltraps>

801055a1 <vector95>:
.globl vector95
vector95:
  pushl $0
801055a1:	6a 00                	push   $0x0
  pushl $95
801055a3:	6a 5f                	push   $0x5f
  jmp alltraps
801055a5:	e9 75 f8 ff ff       	jmp    80104e1f <alltraps>

801055aa <vector96>:
.globl vector96
vector96:
  pushl $0
801055aa:	6a 00                	push   $0x0
  pushl $96
801055ac:	6a 60                	push   $0x60
  jmp alltraps
801055ae:	e9 6c f8 ff ff       	jmp    80104e1f <alltraps>

801055b3 <vector97>:
.globl vector97
vector97:
  pushl $0
801055b3:	6a 00                	push   $0x0
  pushl $97
801055b5:	6a 61                	push   $0x61
  jmp alltraps
801055b7:	e9 63 f8 ff ff       	jmp    80104e1f <alltraps>

801055bc <vector98>:
.globl vector98
vector98:
  pushl $0
801055bc:	6a 00                	push   $0x0
  pushl $98
801055be:	6a 62                	push   $0x62
  jmp alltraps
801055c0:	e9 5a f8 ff ff       	jmp    80104e1f <alltraps>

801055c5 <vector99>:
.globl vector99
vector99:
  pushl $0
801055c5:	6a 00                	push   $0x0
  pushl $99
801055c7:	6a 63                	push   $0x63
  jmp alltraps
801055c9:	e9 51 f8 ff ff       	jmp    80104e1f <alltraps>

801055ce <vector100>:
.globl vector100
vector100:
  pushl $0
801055ce:	6a 00                	push   $0x0
  pushl $100
801055d0:	6a 64                	push   $0x64
  jmp alltraps
801055d2:	e9 48 f8 ff ff       	jmp    80104e1f <alltraps>

801055d7 <vector101>:
.globl vector101
vector101:
  pushl $0
801055d7:	6a 00                	push   $0x0
  pushl $101
801055d9:	6a 65                	push   $0x65
  jmp alltraps
801055db:	e9 3f f8 ff ff       	jmp    80104e1f <alltraps>

801055e0 <vector102>:
.globl vector102
vector102:
  pushl $0
801055e0:	6a 00                	push   $0x0
  pushl $102
801055e2:	6a 66                	push   $0x66
  jmp alltraps
801055e4:	e9 36 f8 ff ff       	jmp    80104e1f <alltraps>

801055e9 <vector103>:
.globl vector103
vector103:
  pushl $0
801055e9:	6a 00                	push   $0x0
  pushl $103
801055eb:	6a 67                	push   $0x67
  jmp alltraps
801055ed:	e9 2d f8 ff ff       	jmp    80104e1f <alltraps>

801055f2 <vector104>:
.globl vector104
vector104:
  pushl $0
801055f2:	6a 00                	push   $0x0
  pushl $104
801055f4:	6a 68                	push   $0x68
  jmp alltraps
801055f6:	e9 24 f8 ff ff       	jmp    80104e1f <alltraps>

801055fb <vector105>:
.globl vector105
vector105:
  pushl $0
801055fb:	6a 00                	push   $0x0
  pushl $105
801055fd:	6a 69                	push   $0x69
  jmp alltraps
801055ff:	e9 1b f8 ff ff       	jmp    80104e1f <alltraps>

80105604 <vector106>:
.globl vector106
vector106:
  pushl $0
80105604:	6a 00                	push   $0x0
  pushl $106
80105606:	6a 6a                	push   $0x6a
  jmp alltraps
80105608:	e9 12 f8 ff ff       	jmp    80104e1f <alltraps>

8010560d <vector107>:
.globl vector107
vector107:
  pushl $0
8010560d:	6a 00                	push   $0x0
  pushl $107
8010560f:	6a 6b                	push   $0x6b
  jmp alltraps
80105611:	e9 09 f8 ff ff       	jmp    80104e1f <alltraps>

80105616 <vector108>:
.globl vector108
vector108:
  pushl $0
80105616:	6a 00                	push   $0x0
  pushl $108
80105618:	6a 6c                	push   $0x6c
  jmp alltraps
8010561a:	e9 00 f8 ff ff       	jmp    80104e1f <alltraps>

8010561f <vector109>:
.globl vector109
vector109:
  pushl $0
8010561f:	6a 00                	push   $0x0
  pushl $109
80105621:	6a 6d                	push   $0x6d
  jmp alltraps
80105623:	e9 f7 f7 ff ff       	jmp    80104e1f <alltraps>

80105628 <vector110>:
.globl vector110
vector110:
  pushl $0
80105628:	6a 00                	push   $0x0
  pushl $110
8010562a:	6a 6e                	push   $0x6e
  jmp alltraps
8010562c:	e9 ee f7 ff ff       	jmp    80104e1f <alltraps>

80105631 <vector111>:
.globl vector111
vector111:
  pushl $0
80105631:	6a 00                	push   $0x0
  pushl $111
80105633:	6a 6f                	push   $0x6f
  jmp alltraps
80105635:	e9 e5 f7 ff ff       	jmp    80104e1f <alltraps>

8010563a <vector112>:
.globl vector112
vector112:
  pushl $0
8010563a:	6a 00                	push   $0x0
  pushl $112
8010563c:	6a 70                	push   $0x70
  jmp alltraps
8010563e:	e9 dc f7 ff ff       	jmp    80104e1f <alltraps>

80105643 <vector113>:
.globl vector113
vector113:
  pushl $0
80105643:	6a 00                	push   $0x0
  pushl $113
80105645:	6a 71                	push   $0x71
  jmp alltraps
80105647:	e9 d3 f7 ff ff       	jmp    80104e1f <alltraps>

8010564c <vector114>:
.globl vector114
vector114:
  pushl $0
8010564c:	6a 00                	push   $0x0
  pushl $114
8010564e:	6a 72                	push   $0x72
  jmp alltraps
80105650:	e9 ca f7 ff ff       	jmp    80104e1f <alltraps>

80105655 <vector115>:
.globl vector115
vector115:
  pushl $0
80105655:	6a 00                	push   $0x0
  pushl $115
80105657:	6a 73                	push   $0x73
  jmp alltraps
80105659:	e9 c1 f7 ff ff       	jmp    80104e1f <alltraps>

8010565e <vector116>:
.globl vector116
vector116:
  pushl $0
8010565e:	6a 00                	push   $0x0
  pushl $116
80105660:	6a 74                	push   $0x74
  jmp alltraps
80105662:	e9 b8 f7 ff ff       	jmp    80104e1f <alltraps>

80105667 <vector117>:
.globl vector117
vector117:
  pushl $0
80105667:	6a 00                	push   $0x0
  pushl $117
80105669:	6a 75                	push   $0x75
  jmp alltraps
8010566b:	e9 af f7 ff ff       	jmp    80104e1f <alltraps>

80105670 <vector118>:
.globl vector118
vector118:
  pushl $0
80105670:	6a 00                	push   $0x0
  pushl $118
80105672:	6a 76                	push   $0x76
  jmp alltraps
80105674:	e9 a6 f7 ff ff       	jmp    80104e1f <alltraps>

80105679 <vector119>:
.globl vector119
vector119:
  pushl $0
80105679:	6a 00                	push   $0x0
  pushl $119
8010567b:	6a 77                	push   $0x77
  jmp alltraps
8010567d:	e9 9d f7 ff ff       	jmp    80104e1f <alltraps>

80105682 <vector120>:
.globl vector120
vector120:
  pushl $0
80105682:	6a 00                	push   $0x0
  pushl $120
80105684:	6a 78                	push   $0x78
  jmp alltraps
80105686:	e9 94 f7 ff ff       	jmp    80104e1f <alltraps>

8010568b <vector121>:
.globl vector121
vector121:
  pushl $0
8010568b:	6a 00                	push   $0x0
  pushl $121
8010568d:	6a 79                	push   $0x79
  jmp alltraps
8010568f:	e9 8b f7 ff ff       	jmp    80104e1f <alltraps>

80105694 <vector122>:
.globl vector122
vector122:
  pushl $0
80105694:	6a 00                	push   $0x0
  pushl $122
80105696:	6a 7a                	push   $0x7a
  jmp alltraps
80105698:	e9 82 f7 ff ff       	jmp    80104e1f <alltraps>

8010569d <vector123>:
.globl vector123
vector123:
  pushl $0
8010569d:	6a 00                	push   $0x0
  pushl $123
8010569f:	6a 7b                	push   $0x7b
  jmp alltraps
801056a1:	e9 79 f7 ff ff       	jmp    80104e1f <alltraps>

801056a6 <vector124>:
.globl vector124
vector124:
  pushl $0
801056a6:	6a 00                	push   $0x0
  pushl $124
801056a8:	6a 7c                	push   $0x7c
  jmp alltraps
801056aa:	e9 70 f7 ff ff       	jmp    80104e1f <alltraps>

801056af <vector125>:
.globl vector125
vector125:
  pushl $0
801056af:	6a 00                	push   $0x0
  pushl $125
801056b1:	6a 7d                	push   $0x7d
  jmp alltraps
801056b3:	e9 67 f7 ff ff       	jmp    80104e1f <alltraps>

801056b8 <vector126>:
.globl vector126
vector126:
  pushl $0
801056b8:	6a 00                	push   $0x0
  pushl $126
801056ba:	6a 7e                	push   $0x7e
  jmp alltraps
801056bc:	e9 5e f7 ff ff       	jmp    80104e1f <alltraps>

801056c1 <vector127>:
.globl vector127
vector127:
  pushl $0
801056c1:	6a 00                	push   $0x0
  pushl $127
801056c3:	6a 7f                	push   $0x7f
  jmp alltraps
801056c5:	e9 55 f7 ff ff       	jmp    80104e1f <alltraps>

801056ca <vector128>:
.globl vector128
vector128:
  pushl $0
801056ca:	6a 00                	push   $0x0
  pushl $128
801056cc:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801056d1:	e9 49 f7 ff ff       	jmp    80104e1f <alltraps>

801056d6 <vector129>:
.globl vector129
vector129:
  pushl $0
801056d6:	6a 00                	push   $0x0
  pushl $129
801056d8:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801056dd:	e9 3d f7 ff ff       	jmp    80104e1f <alltraps>

801056e2 <vector130>:
.globl vector130
vector130:
  pushl $0
801056e2:	6a 00                	push   $0x0
  pushl $130
801056e4:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801056e9:	e9 31 f7 ff ff       	jmp    80104e1f <alltraps>

801056ee <vector131>:
.globl vector131
vector131:
  pushl $0
801056ee:	6a 00                	push   $0x0
  pushl $131
801056f0:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801056f5:	e9 25 f7 ff ff       	jmp    80104e1f <alltraps>

801056fa <vector132>:
.globl vector132
vector132:
  pushl $0
801056fa:	6a 00                	push   $0x0
  pushl $132
801056fc:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105701:	e9 19 f7 ff ff       	jmp    80104e1f <alltraps>

80105706 <vector133>:
.globl vector133
vector133:
  pushl $0
80105706:	6a 00                	push   $0x0
  pushl $133
80105708:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010570d:	e9 0d f7 ff ff       	jmp    80104e1f <alltraps>

80105712 <vector134>:
.globl vector134
vector134:
  pushl $0
80105712:	6a 00                	push   $0x0
  pushl $134
80105714:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105719:	e9 01 f7 ff ff       	jmp    80104e1f <alltraps>

8010571e <vector135>:
.globl vector135
vector135:
  pushl $0
8010571e:	6a 00                	push   $0x0
  pushl $135
80105720:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105725:	e9 f5 f6 ff ff       	jmp    80104e1f <alltraps>

8010572a <vector136>:
.globl vector136
vector136:
  pushl $0
8010572a:	6a 00                	push   $0x0
  pushl $136
8010572c:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105731:	e9 e9 f6 ff ff       	jmp    80104e1f <alltraps>

80105736 <vector137>:
.globl vector137
vector137:
  pushl $0
80105736:	6a 00                	push   $0x0
  pushl $137
80105738:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010573d:	e9 dd f6 ff ff       	jmp    80104e1f <alltraps>

80105742 <vector138>:
.globl vector138
vector138:
  pushl $0
80105742:	6a 00                	push   $0x0
  pushl $138
80105744:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105749:	e9 d1 f6 ff ff       	jmp    80104e1f <alltraps>

8010574e <vector139>:
.globl vector139
vector139:
  pushl $0
8010574e:	6a 00                	push   $0x0
  pushl $139
80105750:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105755:	e9 c5 f6 ff ff       	jmp    80104e1f <alltraps>

8010575a <vector140>:
.globl vector140
vector140:
  pushl $0
8010575a:	6a 00                	push   $0x0
  pushl $140
8010575c:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105761:	e9 b9 f6 ff ff       	jmp    80104e1f <alltraps>

80105766 <vector141>:
.globl vector141
vector141:
  pushl $0
80105766:	6a 00                	push   $0x0
  pushl $141
80105768:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
8010576d:	e9 ad f6 ff ff       	jmp    80104e1f <alltraps>

80105772 <vector142>:
.globl vector142
vector142:
  pushl $0
80105772:	6a 00                	push   $0x0
  pushl $142
80105774:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105779:	e9 a1 f6 ff ff       	jmp    80104e1f <alltraps>

8010577e <vector143>:
.globl vector143
vector143:
  pushl $0
8010577e:	6a 00                	push   $0x0
  pushl $143
80105780:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105785:	e9 95 f6 ff ff       	jmp    80104e1f <alltraps>

8010578a <vector144>:
.globl vector144
vector144:
  pushl $0
8010578a:	6a 00                	push   $0x0
  pushl $144
8010578c:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105791:	e9 89 f6 ff ff       	jmp    80104e1f <alltraps>

80105796 <vector145>:
.globl vector145
vector145:
  pushl $0
80105796:	6a 00                	push   $0x0
  pushl $145
80105798:	68 91 00 00 00       	push   $0x91
  jmp alltraps
8010579d:	e9 7d f6 ff ff       	jmp    80104e1f <alltraps>

801057a2 <vector146>:
.globl vector146
vector146:
  pushl $0
801057a2:	6a 00                	push   $0x0
  pushl $146
801057a4:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801057a9:	e9 71 f6 ff ff       	jmp    80104e1f <alltraps>

801057ae <vector147>:
.globl vector147
vector147:
  pushl $0
801057ae:	6a 00                	push   $0x0
  pushl $147
801057b0:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801057b5:	e9 65 f6 ff ff       	jmp    80104e1f <alltraps>

801057ba <vector148>:
.globl vector148
vector148:
  pushl $0
801057ba:	6a 00                	push   $0x0
  pushl $148
801057bc:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801057c1:	e9 59 f6 ff ff       	jmp    80104e1f <alltraps>

801057c6 <vector149>:
.globl vector149
vector149:
  pushl $0
801057c6:	6a 00                	push   $0x0
  pushl $149
801057c8:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801057cd:	e9 4d f6 ff ff       	jmp    80104e1f <alltraps>

801057d2 <vector150>:
.globl vector150
vector150:
  pushl $0
801057d2:	6a 00                	push   $0x0
  pushl $150
801057d4:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801057d9:	e9 41 f6 ff ff       	jmp    80104e1f <alltraps>

801057de <vector151>:
.globl vector151
vector151:
  pushl $0
801057de:	6a 00                	push   $0x0
  pushl $151
801057e0:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801057e5:	e9 35 f6 ff ff       	jmp    80104e1f <alltraps>

801057ea <vector152>:
.globl vector152
vector152:
  pushl $0
801057ea:	6a 00                	push   $0x0
  pushl $152
801057ec:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801057f1:	e9 29 f6 ff ff       	jmp    80104e1f <alltraps>

801057f6 <vector153>:
.globl vector153
vector153:
  pushl $0
801057f6:	6a 00                	push   $0x0
  pushl $153
801057f8:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801057fd:	e9 1d f6 ff ff       	jmp    80104e1f <alltraps>

80105802 <vector154>:
.globl vector154
vector154:
  pushl $0
80105802:	6a 00                	push   $0x0
  pushl $154
80105804:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105809:	e9 11 f6 ff ff       	jmp    80104e1f <alltraps>

8010580e <vector155>:
.globl vector155
vector155:
  pushl $0
8010580e:	6a 00                	push   $0x0
  pushl $155
80105810:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105815:	e9 05 f6 ff ff       	jmp    80104e1f <alltraps>

8010581a <vector156>:
.globl vector156
vector156:
  pushl $0
8010581a:	6a 00                	push   $0x0
  pushl $156
8010581c:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105821:	e9 f9 f5 ff ff       	jmp    80104e1f <alltraps>

80105826 <vector157>:
.globl vector157
vector157:
  pushl $0
80105826:	6a 00                	push   $0x0
  pushl $157
80105828:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010582d:	e9 ed f5 ff ff       	jmp    80104e1f <alltraps>

80105832 <vector158>:
.globl vector158
vector158:
  pushl $0
80105832:	6a 00                	push   $0x0
  pushl $158
80105834:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105839:	e9 e1 f5 ff ff       	jmp    80104e1f <alltraps>

8010583e <vector159>:
.globl vector159
vector159:
  pushl $0
8010583e:	6a 00                	push   $0x0
  pushl $159
80105840:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105845:	e9 d5 f5 ff ff       	jmp    80104e1f <alltraps>

8010584a <vector160>:
.globl vector160
vector160:
  pushl $0
8010584a:	6a 00                	push   $0x0
  pushl $160
8010584c:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105851:	e9 c9 f5 ff ff       	jmp    80104e1f <alltraps>

80105856 <vector161>:
.globl vector161
vector161:
  pushl $0
80105856:	6a 00                	push   $0x0
  pushl $161
80105858:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
8010585d:	e9 bd f5 ff ff       	jmp    80104e1f <alltraps>

80105862 <vector162>:
.globl vector162
vector162:
  pushl $0
80105862:	6a 00                	push   $0x0
  pushl $162
80105864:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105869:	e9 b1 f5 ff ff       	jmp    80104e1f <alltraps>

8010586e <vector163>:
.globl vector163
vector163:
  pushl $0
8010586e:	6a 00                	push   $0x0
  pushl $163
80105870:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105875:	e9 a5 f5 ff ff       	jmp    80104e1f <alltraps>

8010587a <vector164>:
.globl vector164
vector164:
  pushl $0
8010587a:	6a 00                	push   $0x0
  pushl $164
8010587c:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105881:	e9 99 f5 ff ff       	jmp    80104e1f <alltraps>

80105886 <vector165>:
.globl vector165
vector165:
  pushl $0
80105886:	6a 00                	push   $0x0
  pushl $165
80105888:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
8010588d:	e9 8d f5 ff ff       	jmp    80104e1f <alltraps>

80105892 <vector166>:
.globl vector166
vector166:
  pushl $0
80105892:	6a 00                	push   $0x0
  pushl $166
80105894:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105899:	e9 81 f5 ff ff       	jmp    80104e1f <alltraps>

8010589e <vector167>:
.globl vector167
vector167:
  pushl $0
8010589e:	6a 00                	push   $0x0
  pushl $167
801058a0:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801058a5:	e9 75 f5 ff ff       	jmp    80104e1f <alltraps>

801058aa <vector168>:
.globl vector168
vector168:
  pushl $0
801058aa:	6a 00                	push   $0x0
  pushl $168
801058ac:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801058b1:	e9 69 f5 ff ff       	jmp    80104e1f <alltraps>

801058b6 <vector169>:
.globl vector169
vector169:
  pushl $0
801058b6:	6a 00                	push   $0x0
  pushl $169
801058b8:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801058bd:	e9 5d f5 ff ff       	jmp    80104e1f <alltraps>

801058c2 <vector170>:
.globl vector170
vector170:
  pushl $0
801058c2:	6a 00                	push   $0x0
  pushl $170
801058c4:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801058c9:	e9 51 f5 ff ff       	jmp    80104e1f <alltraps>

801058ce <vector171>:
.globl vector171
vector171:
  pushl $0
801058ce:	6a 00                	push   $0x0
  pushl $171
801058d0:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801058d5:	e9 45 f5 ff ff       	jmp    80104e1f <alltraps>

801058da <vector172>:
.globl vector172
vector172:
  pushl $0
801058da:	6a 00                	push   $0x0
  pushl $172
801058dc:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801058e1:	e9 39 f5 ff ff       	jmp    80104e1f <alltraps>

801058e6 <vector173>:
.globl vector173
vector173:
  pushl $0
801058e6:	6a 00                	push   $0x0
  pushl $173
801058e8:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801058ed:	e9 2d f5 ff ff       	jmp    80104e1f <alltraps>

801058f2 <vector174>:
.globl vector174
vector174:
  pushl $0
801058f2:	6a 00                	push   $0x0
  pushl $174
801058f4:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801058f9:	e9 21 f5 ff ff       	jmp    80104e1f <alltraps>

801058fe <vector175>:
.globl vector175
vector175:
  pushl $0
801058fe:	6a 00                	push   $0x0
  pushl $175
80105900:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105905:	e9 15 f5 ff ff       	jmp    80104e1f <alltraps>

8010590a <vector176>:
.globl vector176
vector176:
  pushl $0
8010590a:	6a 00                	push   $0x0
  pushl $176
8010590c:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105911:	e9 09 f5 ff ff       	jmp    80104e1f <alltraps>

80105916 <vector177>:
.globl vector177
vector177:
  pushl $0
80105916:	6a 00                	push   $0x0
  pushl $177
80105918:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010591d:	e9 fd f4 ff ff       	jmp    80104e1f <alltraps>

80105922 <vector178>:
.globl vector178
vector178:
  pushl $0
80105922:	6a 00                	push   $0x0
  pushl $178
80105924:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105929:	e9 f1 f4 ff ff       	jmp    80104e1f <alltraps>

8010592e <vector179>:
.globl vector179
vector179:
  pushl $0
8010592e:	6a 00                	push   $0x0
  pushl $179
80105930:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105935:	e9 e5 f4 ff ff       	jmp    80104e1f <alltraps>

8010593a <vector180>:
.globl vector180
vector180:
  pushl $0
8010593a:	6a 00                	push   $0x0
  pushl $180
8010593c:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105941:	e9 d9 f4 ff ff       	jmp    80104e1f <alltraps>

80105946 <vector181>:
.globl vector181
vector181:
  pushl $0
80105946:	6a 00                	push   $0x0
  pushl $181
80105948:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
8010594d:	e9 cd f4 ff ff       	jmp    80104e1f <alltraps>

80105952 <vector182>:
.globl vector182
vector182:
  pushl $0
80105952:	6a 00                	push   $0x0
  pushl $182
80105954:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105959:	e9 c1 f4 ff ff       	jmp    80104e1f <alltraps>

8010595e <vector183>:
.globl vector183
vector183:
  pushl $0
8010595e:	6a 00                	push   $0x0
  pushl $183
80105960:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105965:	e9 b5 f4 ff ff       	jmp    80104e1f <alltraps>

8010596a <vector184>:
.globl vector184
vector184:
  pushl $0
8010596a:	6a 00                	push   $0x0
  pushl $184
8010596c:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105971:	e9 a9 f4 ff ff       	jmp    80104e1f <alltraps>

80105976 <vector185>:
.globl vector185
vector185:
  pushl $0
80105976:	6a 00                	push   $0x0
  pushl $185
80105978:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
8010597d:	e9 9d f4 ff ff       	jmp    80104e1f <alltraps>

80105982 <vector186>:
.globl vector186
vector186:
  pushl $0
80105982:	6a 00                	push   $0x0
  pushl $186
80105984:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105989:	e9 91 f4 ff ff       	jmp    80104e1f <alltraps>

8010598e <vector187>:
.globl vector187
vector187:
  pushl $0
8010598e:	6a 00                	push   $0x0
  pushl $187
80105990:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105995:	e9 85 f4 ff ff       	jmp    80104e1f <alltraps>

8010599a <vector188>:
.globl vector188
vector188:
  pushl $0
8010599a:	6a 00                	push   $0x0
  pushl $188
8010599c:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801059a1:	e9 79 f4 ff ff       	jmp    80104e1f <alltraps>

801059a6 <vector189>:
.globl vector189
vector189:
  pushl $0
801059a6:	6a 00                	push   $0x0
  pushl $189
801059a8:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801059ad:	e9 6d f4 ff ff       	jmp    80104e1f <alltraps>

801059b2 <vector190>:
.globl vector190
vector190:
  pushl $0
801059b2:	6a 00                	push   $0x0
  pushl $190
801059b4:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801059b9:	e9 61 f4 ff ff       	jmp    80104e1f <alltraps>

801059be <vector191>:
.globl vector191
vector191:
  pushl $0
801059be:	6a 00                	push   $0x0
  pushl $191
801059c0:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801059c5:	e9 55 f4 ff ff       	jmp    80104e1f <alltraps>

801059ca <vector192>:
.globl vector192
vector192:
  pushl $0
801059ca:	6a 00                	push   $0x0
  pushl $192
801059cc:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801059d1:	e9 49 f4 ff ff       	jmp    80104e1f <alltraps>

801059d6 <vector193>:
.globl vector193
vector193:
  pushl $0
801059d6:	6a 00                	push   $0x0
  pushl $193
801059d8:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801059dd:	e9 3d f4 ff ff       	jmp    80104e1f <alltraps>

801059e2 <vector194>:
.globl vector194
vector194:
  pushl $0
801059e2:	6a 00                	push   $0x0
  pushl $194
801059e4:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801059e9:	e9 31 f4 ff ff       	jmp    80104e1f <alltraps>

801059ee <vector195>:
.globl vector195
vector195:
  pushl $0
801059ee:	6a 00                	push   $0x0
  pushl $195
801059f0:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801059f5:	e9 25 f4 ff ff       	jmp    80104e1f <alltraps>

801059fa <vector196>:
.globl vector196
vector196:
  pushl $0
801059fa:	6a 00                	push   $0x0
  pushl $196
801059fc:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105a01:	e9 19 f4 ff ff       	jmp    80104e1f <alltraps>

80105a06 <vector197>:
.globl vector197
vector197:
  pushl $0
80105a06:	6a 00                	push   $0x0
  pushl $197
80105a08:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105a0d:	e9 0d f4 ff ff       	jmp    80104e1f <alltraps>

80105a12 <vector198>:
.globl vector198
vector198:
  pushl $0
80105a12:	6a 00                	push   $0x0
  pushl $198
80105a14:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105a19:	e9 01 f4 ff ff       	jmp    80104e1f <alltraps>

80105a1e <vector199>:
.globl vector199
vector199:
  pushl $0
80105a1e:	6a 00                	push   $0x0
  pushl $199
80105a20:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105a25:	e9 f5 f3 ff ff       	jmp    80104e1f <alltraps>

80105a2a <vector200>:
.globl vector200
vector200:
  pushl $0
80105a2a:	6a 00                	push   $0x0
  pushl $200
80105a2c:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105a31:	e9 e9 f3 ff ff       	jmp    80104e1f <alltraps>

80105a36 <vector201>:
.globl vector201
vector201:
  pushl $0
80105a36:	6a 00                	push   $0x0
  pushl $201
80105a38:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105a3d:	e9 dd f3 ff ff       	jmp    80104e1f <alltraps>

80105a42 <vector202>:
.globl vector202
vector202:
  pushl $0
80105a42:	6a 00                	push   $0x0
  pushl $202
80105a44:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105a49:	e9 d1 f3 ff ff       	jmp    80104e1f <alltraps>

80105a4e <vector203>:
.globl vector203
vector203:
  pushl $0
80105a4e:	6a 00                	push   $0x0
  pushl $203
80105a50:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105a55:	e9 c5 f3 ff ff       	jmp    80104e1f <alltraps>

80105a5a <vector204>:
.globl vector204
vector204:
  pushl $0
80105a5a:	6a 00                	push   $0x0
  pushl $204
80105a5c:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105a61:	e9 b9 f3 ff ff       	jmp    80104e1f <alltraps>

80105a66 <vector205>:
.globl vector205
vector205:
  pushl $0
80105a66:	6a 00                	push   $0x0
  pushl $205
80105a68:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105a6d:	e9 ad f3 ff ff       	jmp    80104e1f <alltraps>

80105a72 <vector206>:
.globl vector206
vector206:
  pushl $0
80105a72:	6a 00                	push   $0x0
  pushl $206
80105a74:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105a79:	e9 a1 f3 ff ff       	jmp    80104e1f <alltraps>

80105a7e <vector207>:
.globl vector207
vector207:
  pushl $0
80105a7e:	6a 00                	push   $0x0
  pushl $207
80105a80:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105a85:	e9 95 f3 ff ff       	jmp    80104e1f <alltraps>

80105a8a <vector208>:
.globl vector208
vector208:
  pushl $0
80105a8a:	6a 00                	push   $0x0
  pushl $208
80105a8c:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105a91:	e9 89 f3 ff ff       	jmp    80104e1f <alltraps>

80105a96 <vector209>:
.globl vector209
vector209:
  pushl $0
80105a96:	6a 00                	push   $0x0
  pushl $209
80105a98:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105a9d:	e9 7d f3 ff ff       	jmp    80104e1f <alltraps>

80105aa2 <vector210>:
.globl vector210
vector210:
  pushl $0
80105aa2:	6a 00                	push   $0x0
  pushl $210
80105aa4:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105aa9:	e9 71 f3 ff ff       	jmp    80104e1f <alltraps>

80105aae <vector211>:
.globl vector211
vector211:
  pushl $0
80105aae:	6a 00                	push   $0x0
  pushl $211
80105ab0:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105ab5:	e9 65 f3 ff ff       	jmp    80104e1f <alltraps>

80105aba <vector212>:
.globl vector212
vector212:
  pushl $0
80105aba:	6a 00                	push   $0x0
  pushl $212
80105abc:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105ac1:	e9 59 f3 ff ff       	jmp    80104e1f <alltraps>

80105ac6 <vector213>:
.globl vector213
vector213:
  pushl $0
80105ac6:	6a 00                	push   $0x0
  pushl $213
80105ac8:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105acd:	e9 4d f3 ff ff       	jmp    80104e1f <alltraps>

80105ad2 <vector214>:
.globl vector214
vector214:
  pushl $0
80105ad2:	6a 00                	push   $0x0
  pushl $214
80105ad4:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105ad9:	e9 41 f3 ff ff       	jmp    80104e1f <alltraps>

80105ade <vector215>:
.globl vector215
vector215:
  pushl $0
80105ade:	6a 00                	push   $0x0
  pushl $215
80105ae0:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105ae5:	e9 35 f3 ff ff       	jmp    80104e1f <alltraps>

80105aea <vector216>:
.globl vector216
vector216:
  pushl $0
80105aea:	6a 00                	push   $0x0
  pushl $216
80105aec:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105af1:	e9 29 f3 ff ff       	jmp    80104e1f <alltraps>

80105af6 <vector217>:
.globl vector217
vector217:
  pushl $0
80105af6:	6a 00                	push   $0x0
  pushl $217
80105af8:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105afd:	e9 1d f3 ff ff       	jmp    80104e1f <alltraps>

80105b02 <vector218>:
.globl vector218
vector218:
  pushl $0
80105b02:	6a 00                	push   $0x0
  pushl $218
80105b04:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105b09:	e9 11 f3 ff ff       	jmp    80104e1f <alltraps>

80105b0e <vector219>:
.globl vector219
vector219:
  pushl $0
80105b0e:	6a 00                	push   $0x0
  pushl $219
80105b10:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105b15:	e9 05 f3 ff ff       	jmp    80104e1f <alltraps>

80105b1a <vector220>:
.globl vector220
vector220:
  pushl $0
80105b1a:	6a 00                	push   $0x0
  pushl $220
80105b1c:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105b21:	e9 f9 f2 ff ff       	jmp    80104e1f <alltraps>

80105b26 <vector221>:
.globl vector221
vector221:
  pushl $0
80105b26:	6a 00                	push   $0x0
  pushl $221
80105b28:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105b2d:	e9 ed f2 ff ff       	jmp    80104e1f <alltraps>

80105b32 <vector222>:
.globl vector222
vector222:
  pushl $0
80105b32:	6a 00                	push   $0x0
  pushl $222
80105b34:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105b39:	e9 e1 f2 ff ff       	jmp    80104e1f <alltraps>

80105b3e <vector223>:
.globl vector223
vector223:
  pushl $0
80105b3e:	6a 00                	push   $0x0
  pushl $223
80105b40:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105b45:	e9 d5 f2 ff ff       	jmp    80104e1f <alltraps>

80105b4a <vector224>:
.globl vector224
vector224:
  pushl $0
80105b4a:	6a 00                	push   $0x0
  pushl $224
80105b4c:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105b51:	e9 c9 f2 ff ff       	jmp    80104e1f <alltraps>

80105b56 <vector225>:
.globl vector225
vector225:
  pushl $0
80105b56:	6a 00                	push   $0x0
  pushl $225
80105b58:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105b5d:	e9 bd f2 ff ff       	jmp    80104e1f <alltraps>

80105b62 <vector226>:
.globl vector226
vector226:
  pushl $0
80105b62:	6a 00                	push   $0x0
  pushl $226
80105b64:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105b69:	e9 b1 f2 ff ff       	jmp    80104e1f <alltraps>

80105b6e <vector227>:
.globl vector227
vector227:
  pushl $0
80105b6e:	6a 00                	push   $0x0
  pushl $227
80105b70:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105b75:	e9 a5 f2 ff ff       	jmp    80104e1f <alltraps>

80105b7a <vector228>:
.globl vector228
vector228:
  pushl $0
80105b7a:	6a 00                	push   $0x0
  pushl $228
80105b7c:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105b81:	e9 99 f2 ff ff       	jmp    80104e1f <alltraps>

80105b86 <vector229>:
.globl vector229
vector229:
  pushl $0
80105b86:	6a 00                	push   $0x0
  pushl $229
80105b88:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105b8d:	e9 8d f2 ff ff       	jmp    80104e1f <alltraps>

80105b92 <vector230>:
.globl vector230
vector230:
  pushl $0
80105b92:	6a 00                	push   $0x0
  pushl $230
80105b94:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105b99:	e9 81 f2 ff ff       	jmp    80104e1f <alltraps>

80105b9e <vector231>:
.globl vector231
vector231:
  pushl $0
80105b9e:	6a 00                	push   $0x0
  pushl $231
80105ba0:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105ba5:	e9 75 f2 ff ff       	jmp    80104e1f <alltraps>

80105baa <vector232>:
.globl vector232
vector232:
  pushl $0
80105baa:	6a 00                	push   $0x0
  pushl $232
80105bac:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105bb1:	e9 69 f2 ff ff       	jmp    80104e1f <alltraps>

80105bb6 <vector233>:
.globl vector233
vector233:
  pushl $0
80105bb6:	6a 00                	push   $0x0
  pushl $233
80105bb8:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105bbd:	e9 5d f2 ff ff       	jmp    80104e1f <alltraps>

80105bc2 <vector234>:
.globl vector234
vector234:
  pushl $0
80105bc2:	6a 00                	push   $0x0
  pushl $234
80105bc4:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105bc9:	e9 51 f2 ff ff       	jmp    80104e1f <alltraps>

80105bce <vector235>:
.globl vector235
vector235:
  pushl $0
80105bce:	6a 00                	push   $0x0
  pushl $235
80105bd0:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105bd5:	e9 45 f2 ff ff       	jmp    80104e1f <alltraps>

80105bda <vector236>:
.globl vector236
vector236:
  pushl $0
80105bda:	6a 00                	push   $0x0
  pushl $236
80105bdc:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105be1:	e9 39 f2 ff ff       	jmp    80104e1f <alltraps>

80105be6 <vector237>:
.globl vector237
vector237:
  pushl $0
80105be6:	6a 00                	push   $0x0
  pushl $237
80105be8:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105bed:	e9 2d f2 ff ff       	jmp    80104e1f <alltraps>

80105bf2 <vector238>:
.globl vector238
vector238:
  pushl $0
80105bf2:	6a 00                	push   $0x0
  pushl $238
80105bf4:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105bf9:	e9 21 f2 ff ff       	jmp    80104e1f <alltraps>

80105bfe <vector239>:
.globl vector239
vector239:
  pushl $0
80105bfe:	6a 00                	push   $0x0
  pushl $239
80105c00:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105c05:	e9 15 f2 ff ff       	jmp    80104e1f <alltraps>

80105c0a <vector240>:
.globl vector240
vector240:
  pushl $0
80105c0a:	6a 00                	push   $0x0
  pushl $240
80105c0c:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105c11:	e9 09 f2 ff ff       	jmp    80104e1f <alltraps>

80105c16 <vector241>:
.globl vector241
vector241:
  pushl $0
80105c16:	6a 00                	push   $0x0
  pushl $241
80105c18:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105c1d:	e9 fd f1 ff ff       	jmp    80104e1f <alltraps>

80105c22 <vector242>:
.globl vector242
vector242:
  pushl $0
80105c22:	6a 00                	push   $0x0
  pushl $242
80105c24:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105c29:	e9 f1 f1 ff ff       	jmp    80104e1f <alltraps>

80105c2e <vector243>:
.globl vector243
vector243:
  pushl $0
80105c2e:	6a 00                	push   $0x0
  pushl $243
80105c30:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105c35:	e9 e5 f1 ff ff       	jmp    80104e1f <alltraps>

80105c3a <vector244>:
.globl vector244
vector244:
  pushl $0
80105c3a:	6a 00                	push   $0x0
  pushl $244
80105c3c:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105c41:	e9 d9 f1 ff ff       	jmp    80104e1f <alltraps>

80105c46 <vector245>:
.globl vector245
vector245:
  pushl $0
80105c46:	6a 00                	push   $0x0
  pushl $245
80105c48:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105c4d:	e9 cd f1 ff ff       	jmp    80104e1f <alltraps>

80105c52 <vector246>:
.globl vector246
vector246:
  pushl $0
80105c52:	6a 00                	push   $0x0
  pushl $246
80105c54:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105c59:	e9 c1 f1 ff ff       	jmp    80104e1f <alltraps>

80105c5e <vector247>:
.globl vector247
vector247:
  pushl $0
80105c5e:	6a 00                	push   $0x0
  pushl $247
80105c60:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105c65:	e9 b5 f1 ff ff       	jmp    80104e1f <alltraps>

80105c6a <vector248>:
.globl vector248
vector248:
  pushl $0
80105c6a:	6a 00                	push   $0x0
  pushl $248
80105c6c:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105c71:	e9 a9 f1 ff ff       	jmp    80104e1f <alltraps>

80105c76 <vector249>:
.globl vector249
vector249:
  pushl $0
80105c76:	6a 00                	push   $0x0
  pushl $249
80105c78:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105c7d:	e9 9d f1 ff ff       	jmp    80104e1f <alltraps>

80105c82 <vector250>:
.globl vector250
vector250:
  pushl $0
80105c82:	6a 00                	push   $0x0
  pushl $250
80105c84:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105c89:	e9 91 f1 ff ff       	jmp    80104e1f <alltraps>

80105c8e <vector251>:
.globl vector251
vector251:
  pushl $0
80105c8e:	6a 00                	push   $0x0
  pushl $251
80105c90:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105c95:	e9 85 f1 ff ff       	jmp    80104e1f <alltraps>

80105c9a <vector252>:
.globl vector252
vector252:
  pushl $0
80105c9a:	6a 00                	push   $0x0
  pushl $252
80105c9c:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105ca1:	e9 79 f1 ff ff       	jmp    80104e1f <alltraps>

80105ca6 <vector253>:
.globl vector253
vector253:
  pushl $0
80105ca6:	6a 00                	push   $0x0
  pushl $253
80105ca8:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105cad:	e9 6d f1 ff ff       	jmp    80104e1f <alltraps>

80105cb2 <vector254>:
.globl vector254
vector254:
  pushl $0
80105cb2:	6a 00                	push   $0x0
  pushl $254
80105cb4:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105cb9:	e9 61 f1 ff ff       	jmp    80104e1f <alltraps>

80105cbe <vector255>:
.globl vector255
vector255:
  pushl $0
80105cbe:	6a 00                	push   $0x0
  pushl $255
80105cc0:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105cc5:	e9 55 f1 ff ff       	jmp    80104e1f <alltraps>

80105cca <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105cca:	55                   	push   %ebp
80105ccb:	89 e5                	mov    %esp,%ebp
80105ccd:	57                   	push   %edi
80105cce:	56                   	push   %esi
80105ccf:	53                   	push   %ebx
80105cd0:	83 ec 0c             	sub    $0xc,%esp
80105cd3:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105cd5:	c1 ea 16             	shr    $0x16,%edx
80105cd8:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105cdb:	8b 1f                	mov    (%edi),%ebx
80105cdd:	f6 c3 01             	test   $0x1,%bl
80105ce0:	74 22                	je     80105d04 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105ce2:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105ce8:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105cee:	c1 ee 0c             	shr    $0xc,%esi
80105cf1:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105cf7:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105cfa:	89 d8                	mov    %ebx,%eax
80105cfc:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105cff:	5b                   	pop    %ebx
80105d00:	5e                   	pop    %esi
80105d01:	5f                   	pop    %edi
80105d02:	5d                   	pop    %ebp
80105d03:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80105d04:	85 c9                	test   %ecx,%ecx
80105d06:	74 2b                	je     80105d33 <walkpgdir+0x69>
80105d08:	e8 be c3 ff ff       	call   801020cb <kalloc>
80105d0d:	89 c3                	mov    %eax,%ebx
80105d0f:	85 c0                	test   %eax,%eax
80105d11:	74 e7                	je     80105cfa <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105d13:	83 ec 04             	sub    $0x4,%esp
80105d16:	68 00 10 00 00       	push   $0x1000
80105d1b:	6a 00                	push   $0x0
80105d1d:	50                   	push   %eax
80105d1e:	e8 e6 df ff ff       	call   80103d09 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105d23:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105d29:	83 c8 07             	or     $0x7,%eax
80105d2c:	89 07                	mov    %eax,(%edi)
80105d2e:	83 c4 10             	add    $0x10,%esp
80105d31:	eb bb                	jmp    80105cee <walkpgdir+0x24>
      return 0;
80105d33:	bb 00 00 00 00       	mov    $0x0,%ebx
80105d38:	eb c0                	jmp    80105cfa <walkpgdir+0x30>

80105d3a <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105d3a:	55                   	push   %ebp
80105d3b:	89 e5                	mov    %esp,%ebp
80105d3d:	57                   	push   %edi
80105d3e:	56                   	push   %esi
80105d3f:	53                   	push   %ebx
80105d40:	83 ec 1c             	sub    $0x1c,%esp
80105d43:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105d46:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105d49:	89 d3                	mov    %edx,%ebx
80105d4b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105d51:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105d55:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105d5b:	b9 01 00 00 00       	mov    $0x1,%ecx
80105d60:	89 da                	mov    %ebx,%edx
80105d62:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d65:	e8 60 ff ff ff       	call   80105cca <walkpgdir>
80105d6a:	85 c0                	test   %eax,%eax
80105d6c:	74 2e                	je     80105d9c <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105d6e:	f6 00 01             	testb  $0x1,(%eax)
80105d71:	75 1c                	jne    80105d8f <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105d73:	89 f2                	mov    %esi,%edx
80105d75:	0b 55 0c             	or     0xc(%ebp),%edx
80105d78:	83 ca 01             	or     $0x1,%edx
80105d7b:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105d7d:	39 fb                	cmp    %edi,%ebx
80105d7f:	74 28                	je     80105da9 <mappages+0x6f>
      break;
    a += PGSIZE;
80105d81:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105d87:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105d8d:	eb cc                	jmp    80105d5b <mappages+0x21>
      panic("remap");
80105d8f:	83 ec 0c             	sub    $0xc,%esp
80105d92:	68 4c 6e 10 80       	push   $0x80106e4c
80105d97:	e8 ac a5 ff ff       	call   80100348 <panic>
      return -1;
80105d9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105da1:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105da4:	5b                   	pop    %ebx
80105da5:	5e                   	pop    %esi
80105da6:	5f                   	pop    %edi
80105da7:	5d                   	pop    %ebp
80105da8:	c3                   	ret    
  return 0;
80105da9:	b8 00 00 00 00       	mov    $0x0,%eax
80105dae:	eb f1                	jmp    80105da1 <mappages+0x67>

80105db0 <seginit>:
{
80105db0:	55                   	push   %ebp
80105db1:	89 e5                	mov    %esp,%ebp
80105db3:	53                   	push   %ebx
80105db4:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105db7:	e8 e7 d4 ff ff       	call   801032a3 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105dbc:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105dc2:	66 c7 80 38 18 13 80 	movw   $0xffff,-0x7fece7c8(%eax)
80105dc9:	ff ff 
80105dcb:	66 c7 80 3a 18 13 80 	movw   $0x0,-0x7fece7c6(%eax)
80105dd2:	00 00 
80105dd4:	c6 80 3c 18 13 80 00 	movb   $0x0,-0x7fece7c4(%eax)
80105ddb:	0f b6 88 3d 18 13 80 	movzbl -0x7fece7c3(%eax),%ecx
80105de2:	83 e1 f0             	and    $0xfffffff0,%ecx
80105de5:	83 c9 1a             	or     $0x1a,%ecx
80105de8:	83 e1 9f             	and    $0xffffff9f,%ecx
80105deb:	83 c9 80             	or     $0xffffff80,%ecx
80105dee:	88 88 3d 18 13 80    	mov    %cl,-0x7fece7c3(%eax)
80105df4:	0f b6 88 3e 18 13 80 	movzbl -0x7fece7c2(%eax),%ecx
80105dfb:	83 c9 0f             	or     $0xf,%ecx
80105dfe:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e01:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e04:	88 88 3e 18 13 80    	mov    %cl,-0x7fece7c2(%eax)
80105e0a:	c6 80 3f 18 13 80 00 	movb   $0x0,-0x7fece7c1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105e11:	66 c7 80 40 18 13 80 	movw   $0xffff,-0x7fece7c0(%eax)
80105e18:	ff ff 
80105e1a:	66 c7 80 42 18 13 80 	movw   $0x0,-0x7fece7be(%eax)
80105e21:	00 00 
80105e23:	c6 80 44 18 13 80 00 	movb   $0x0,-0x7fece7bc(%eax)
80105e2a:	0f b6 88 45 18 13 80 	movzbl -0x7fece7bb(%eax),%ecx
80105e31:	83 e1 f0             	and    $0xfffffff0,%ecx
80105e34:	83 c9 12             	or     $0x12,%ecx
80105e37:	83 e1 9f             	and    $0xffffff9f,%ecx
80105e3a:	83 c9 80             	or     $0xffffff80,%ecx
80105e3d:	88 88 45 18 13 80    	mov    %cl,-0x7fece7bb(%eax)
80105e43:	0f b6 88 46 18 13 80 	movzbl -0x7fece7ba(%eax),%ecx
80105e4a:	83 c9 0f             	or     $0xf,%ecx
80105e4d:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e50:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e53:	88 88 46 18 13 80    	mov    %cl,-0x7fece7ba(%eax)
80105e59:	c6 80 47 18 13 80 00 	movb   $0x0,-0x7fece7b9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105e60:	66 c7 80 48 18 13 80 	movw   $0xffff,-0x7fece7b8(%eax)
80105e67:	ff ff 
80105e69:	66 c7 80 4a 18 13 80 	movw   $0x0,-0x7fece7b6(%eax)
80105e70:	00 00 
80105e72:	c6 80 4c 18 13 80 00 	movb   $0x0,-0x7fece7b4(%eax)
80105e79:	c6 80 4d 18 13 80 fa 	movb   $0xfa,-0x7fece7b3(%eax)
80105e80:	0f b6 88 4e 18 13 80 	movzbl -0x7fece7b2(%eax),%ecx
80105e87:	83 c9 0f             	or     $0xf,%ecx
80105e8a:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e8d:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e90:	88 88 4e 18 13 80    	mov    %cl,-0x7fece7b2(%eax)
80105e96:	c6 80 4f 18 13 80 00 	movb   $0x0,-0x7fece7b1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105e9d:	66 c7 80 50 18 13 80 	movw   $0xffff,-0x7fece7b0(%eax)
80105ea4:	ff ff 
80105ea6:	66 c7 80 52 18 13 80 	movw   $0x0,-0x7fece7ae(%eax)
80105ead:	00 00 
80105eaf:	c6 80 54 18 13 80 00 	movb   $0x0,-0x7fece7ac(%eax)
80105eb6:	c6 80 55 18 13 80 f2 	movb   $0xf2,-0x7fece7ab(%eax)
80105ebd:	0f b6 88 56 18 13 80 	movzbl -0x7fece7aa(%eax),%ecx
80105ec4:	83 c9 0f             	or     $0xf,%ecx
80105ec7:	83 e1 cf             	and    $0xffffffcf,%ecx
80105eca:	83 c9 c0             	or     $0xffffffc0,%ecx
80105ecd:	88 88 56 18 13 80    	mov    %cl,-0x7fece7aa(%eax)
80105ed3:	c6 80 57 18 13 80 00 	movb   $0x0,-0x7fece7a9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105eda:	05 30 18 13 80       	add    $0x80131830,%eax
  pd[0] = size-1;
80105edf:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105ee5:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105ee9:	c1 e8 10             	shr    $0x10,%eax
80105eec:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105ef0:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105ef3:	0f 01 10             	lgdtl  (%eax)
}
80105ef6:	83 c4 14             	add    $0x14,%esp
80105ef9:	5b                   	pop    %ebx
80105efa:	5d                   	pop    %ebp
80105efb:	c3                   	ret    

80105efc <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105efc:	55                   	push   %ebp
80105efd:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105eff:	a1 e4 44 13 80       	mov    0x801344e4,%eax
80105f04:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105f09:	0f 22 d8             	mov    %eax,%cr3
}
80105f0c:	5d                   	pop    %ebp
80105f0d:	c3                   	ret    

80105f0e <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105f0e:	55                   	push   %ebp
80105f0f:	89 e5                	mov    %esp,%ebp
80105f11:	57                   	push   %edi
80105f12:	56                   	push   %esi
80105f13:	53                   	push   %ebx
80105f14:	83 ec 1c             	sub    $0x1c,%esp
80105f17:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80105f1a:	85 f6                	test   %esi,%esi
80105f1c:	0f 84 dd 00 00 00    	je     80105fff <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105f22:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105f26:	0f 84 e0 00 00 00    	je     8010600c <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80105f2c:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80105f30:	0f 84 e3 00 00 00    	je     80106019 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80105f36:	e8 45 dc ff ff       	call   80103b80 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80105f3b:	e8 07 d3 ff ff       	call   80103247 <mycpu>
80105f40:	89 c3                	mov    %eax,%ebx
80105f42:	e8 00 d3 ff ff       	call   80103247 <mycpu>
80105f47:	8d 78 08             	lea    0x8(%eax),%edi
80105f4a:	e8 f8 d2 ff ff       	call   80103247 <mycpu>
80105f4f:	83 c0 08             	add    $0x8,%eax
80105f52:	c1 e8 10             	shr    $0x10,%eax
80105f55:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105f58:	e8 ea d2 ff ff       	call   80103247 <mycpu>
80105f5d:	83 c0 08             	add    $0x8,%eax
80105f60:	c1 e8 18             	shr    $0x18,%eax
80105f63:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80105f6a:	67 00 
80105f6c:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80105f73:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80105f77:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80105f7d:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80105f84:	83 e2 f0             	and    $0xfffffff0,%edx
80105f87:	83 ca 19             	or     $0x19,%edx
80105f8a:	83 e2 9f             	and    $0xffffff9f,%edx
80105f8d:	83 ca 80             	or     $0xffffff80,%edx
80105f90:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80105f96:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80105f9d:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80105fa3:	e8 9f d2 ff ff       	call   80103247 <mycpu>
80105fa8:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80105faf:	83 e2 ef             	and    $0xffffffef,%edx
80105fb2:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80105fb8:	e8 8a d2 ff ff       	call   80103247 <mycpu>
80105fbd:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80105fc3:	8b 5e 08             	mov    0x8(%esi),%ebx
80105fc6:	e8 7c d2 ff ff       	call   80103247 <mycpu>
80105fcb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80105fd1:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80105fd4:	e8 6e d2 ff ff       	call   80103247 <mycpu>
80105fd9:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80105fdf:	b8 28 00 00 00       	mov    $0x28,%eax
80105fe4:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80105fe7:	8b 46 04             	mov    0x4(%esi),%eax
80105fea:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105fef:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80105ff2:	e8 c6 db ff ff       	call   80103bbd <popcli>
}
80105ff7:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105ffa:	5b                   	pop    %ebx
80105ffb:	5e                   	pop    %esi
80105ffc:	5f                   	pop    %edi
80105ffd:	5d                   	pop    %ebp
80105ffe:	c3                   	ret    
    panic("switchuvm: no process");
80105fff:	83 ec 0c             	sub    $0xc,%esp
80106002:	68 52 6e 10 80       	push   $0x80106e52
80106007:	e8 3c a3 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
8010600c:	83 ec 0c             	sub    $0xc,%esp
8010600f:	68 68 6e 10 80       	push   $0x80106e68
80106014:	e8 2f a3 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106019:	83 ec 0c             	sub    $0xc,%esp
8010601c:	68 7d 6e 10 80       	push   $0x80106e7d
80106021:	e8 22 a3 ff ff       	call   80100348 <panic>

80106026 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106026:	55                   	push   %ebp
80106027:	89 e5                	mov    %esp,%ebp
80106029:	56                   	push   %esi
8010602a:	53                   	push   %ebx
8010602b:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
8010602e:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106034:	77 4c                	ja     80106082 <inituvm+0x5c>
    panic("inituvm: more than a page");
  mem = kalloc();
80106036:	e8 90 c0 ff ff       	call   801020cb <kalloc>
8010603b:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
8010603d:	83 ec 04             	sub    $0x4,%esp
80106040:	68 00 10 00 00       	push   $0x1000
80106045:	6a 00                	push   $0x0
80106047:	50                   	push   %eax
80106048:	e8 bc dc ff ff       	call   80103d09 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
8010604d:	83 c4 08             	add    $0x8,%esp
80106050:	6a 06                	push   $0x6
80106052:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106058:	50                   	push   %eax
80106059:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010605e:	ba 00 00 00 00       	mov    $0x0,%edx
80106063:	8b 45 08             	mov    0x8(%ebp),%eax
80106066:	e8 cf fc ff ff       	call   80105d3a <mappages>
  memmove(mem, init, sz);
8010606b:	83 c4 0c             	add    $0xc,%esp
8010606e:	56                   	push   %esi
8010606f:	ff 75 0c             	pushl  0xc(%ebp)
80106072:	53                   	push   %ebx
80106073:	e8 0c dd ff ff       	call   80103d84 <memmove>
}
80106078:	83 c4 10             	add    $0x10,%esp
8010607b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010607e:	5b                   	pop    %ebx
8010607f:	5e                   	pop    %esi
80106080:	5d                   	pop    %ebp
80106081:	c3                   	ret    
    panic("inituvm: more than a page");
80106082:	83 ec 0c             	sub    $0xc,%esp
80106085:	68 91 6e 10 80       	push   $0x80106e91
8010608a:	e8 b9 a2 ff ff       	call   80100348 <panic>

8010608f <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010608f:	55                   	push   %ebp
80106090:	89 e5                	mov    %esp,%ebp
80106092:	57                   	push   %edi
80106093:	56                   	push   %esi
80106094:	53                   	push   %ebx
80106095:	83 ec 0c             	sub    $0xc,%esp
80106098:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010609b:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
801060a2:	75 07                	jne    801060ab <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801060a4:	bb 00 00 00 00       	mov    $0x0,%ebx
801060a9:	eb 3c                	jmp    801060e7 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
801060ab:	83 ec 0c             	sub    $0xc,%esp
801060ae:	68 4c 6f 10 80       	push   $0x80106f4c
801060b3:	e8 90 a2 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
801060b8:	83 ec 0c             	sub    $0xc,%esp
801060bb:	68 ab 6e 10 80       	push   $0x80106eab
801060c0:	e8 83 a2 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
801060c5:	05 00 00 00 80       	add    $0x80000000,%eax
801060ca:	56                   	push   %esi
801060cb:	89 da                	mov    %ebx,%edx
801060cd:	03 55 14             	add    0x14(%ebp),%edx
801060d0:	52                   	push   %edx
801060d1:	50                   	push   %eax
801060d2:	ff 75 10             	pushl  0x10(%ebp)
801060d5:	e8 99 b6 ff ff       	call   80101773 <readi>
801060da:	83 c4 10             	add    $0x10,%esp
801060dd:	39 f0                	cmp    %esi,%eax
801060df:	75 47                	jne    80106128 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
801060e1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801060e7:	39 fb                	cmp    %edi,%ebx
801060e9:	73 30                	jae    8010611b <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801060eb:	89 da                	mov    %ebx,%edx
801060ed:	03 55 0c             	add    0xc(%ebp),%edx
801060f0:	b9 00 00 00 00       	mov    $0x0,%ecx
801060f5:	8b 45 08             	mov    0x8(%ebp),%eax
801060f8:	e8 cd fb ff ff       	call   80105cca <walkpgdir>
801060fd:	85 c0                	test   %eax,%eax
801060ff:	74 b7                	je     801060b8 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
80106101:	8b 00                	mov    (%eax),%eax
80106103:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80106108:	89 fe                	mov    %edi,%esi
8010610a:	29 de                	sub    %ebx,%esi
8010610c:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106112:	76 b1                	jbe    801060c5 <loaduvm+0x36>
      n = PGSIZE;
80106114:	be 00 10 00 00       	mov    $0x1000,%esi
80106119:	eb aa                	jmp    801060c5 <loaduvm+0x36>
      return -1;
  }
  return 0;
8010611b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106120:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106123:	5b                   	pop    %ebx
80106124:	5e                   	pop    %esi
80106125:	5f                   	pop    %edi
80106126:	5d                   	pop    %ebp
80106127:	c3                   	ret    
      return -1;
80106128:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010612d:	eb f1                	jmp    80106120 <loaduvm+0x91>

8010612f <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010612f:	55                   	push   %ebp
80106130:	89 e5                	mov    %esp,%ebp
80106132:	57                   	push   %edi
80106133:	56                   	push   %esi
80106134:	53                   	push   %ebx
80106135:	83 ec 0c             	sub    $0xc,%esp
80106138:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010613b:	39 7d 10             	cmp    %edi,0x10(%ebp)
8010613e:	73 11                	jae    80106151 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
80106140:	8b 45 10             	mov    0x10(%ebp),%eax
80106143:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106149:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010614f:	eb 19                	jmp    8010616a <deallocuvm+0x3b>
    return oldsz;
80106151:	89 f8                	mov    %edi,%eax
80106153:	eb 64                	jmp    801061b9 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106155:	c1 eb 16             	shr    $0x16,%ebx
80106158:	83 c3 01             	add    $0x1,%ebx
8010615b:	c1 e3 16             	shl    $0x16,%ebx
8010615e:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106164:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010616a:	39 fb                	cmp    %edi,%ebx
8010616c:	73 48                	jae    801061b6 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
8010616e:	b9 00 00 00 00       	mov    $0x0,%ecx
80106173:	89 da                	mov    %ebx,%edx
80106175:	8b 45 08             	mov    0x8(%ebp),%eax
80106178:	e8 4d fb ff ff       	call   80105cca <walkpgdir>
8010617d:	89 c6                	mov    %eax,%esi
    if(!pte)
8010617f:	85 c0                	test   %eax,%eax
80106181:	74 d2                	je     80106155 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106183:	8b 00                	mov    (%eax),%eax
80106185:	a8 01                	test   $0x1,%al
80106187:	74 db                	je     80106164 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106189:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010618e:	74 19                	je     801061a9 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106190:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106195:	83 ec 0c             	sub    $0xc,%esp
80106198:	50                   	push   %eax
80106199:	e8 06 be ff ff       	call   80101fa4 <kfree>
      *pte = 0;
8010619e:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
801061a4:	83 c4 10             	add    $0x10,%esp
801061a7:	eb bb                	jmp    80106164 <deallocuvm+0x35>
        panic("kfree");
801061a9:	83 ec 0c             	sub    $0xc,%esp
801061ac:	68 e6 67 10 80       	push   $0x801067e6
801061b1:	e8 92 a1 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
801061b6:	8b 45 10             	mov    0x10(%ebp),%eax
}
801061b9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061bc:	5b                   	pop    %ebx
801061bd:	5e                   	pop    %esi
801061be:	5f                   	pop    %edi
801061bf:	5d                   	pop    %ebp
801061c0:	c3                   	ret    

801061c1 <allocuvm>:
{
801061c1:	55                   	push   %ebp
801061c2:	89 e5                	mov    %esp,%ebp
801061c4:	57                   	push   %edi
801061c5:	56                   	push   %esi
801061c6:	53                   	push   %ebx
801061c7:	83 ec 1c             	sub    $0x1c,%esp
801061ca:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801061cd:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801061d0:	85 ff                	test   %edi,%edi
801061d2:	0f 88 c1 00 00 00    	js     80106299 <allocuvm+0xd8>
  if(newsz < oldsz)
801061d8:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801061db:	72 5c                	jb     80106239 <allocuvm+0x78>
  a = PGROUNDUP(oldsz);
801061dd:	8b 45 0c             	mov    0xc(%ebp),%eax
801061e0:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801061e6:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
801061ec:	39 fb                	cmp    %edi,%ebx
801061ee:	0f 83 ac 00 00 00    	jae    801062a0 <allocuvm+0xdf>
    mem = kalloc();
801061f4:	e8 d2 be ff ff       	call   801020cb <kalloc>
801061f9:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801061fb:	85 c0                	test   %eax,%eax
801061fd:	74 42                	je     80106241 <allocuvm+0x80>
    memset(mem, 0, PGSIZE);
801061ff:	83 ec 04             	sub    $0x4,%esp
80106202:	68 00 10 00 00       	push   $0x1000
80106207:	6a 00                	push   $0x0
80106209:	50                   	push   %eax
8010620a:	e8 fa da ff ff       	call   80103d09 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
8010620f:	83 c4 08             	add    $0x8,%esp
80106212:	6a 06                	push   $0x6
80106214:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
8010621a:	50                   	push   %eax
8010621b:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106220:	89 da                	mov    %ebx,%edx
80106222:	8b 45 08             	mov    0x8(%ebp),%eax
80106225:	e8 10 fb ff ff       	call   80105d3a <mappages>
8010622a:	83 c4 10             	add    $0x10,%esp
8010622d:	85 c0                	test   %eax,%eax
8010622f:	78 38                	js     80106269 <allocuvm+0xa8>
  for(; a < newsz; a += PGSIZE){
80106231:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106237:	eb b3                	jmp    801061ec <allocuvm+0x2b>
    return oldsz;
80106239:	8b 45 0c             	mov    0xc(%ebp),%eax
8010623c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010623f:	eb 5f                	jmp    801062a0 <allocuvm+0xdf>
      cprintf("allocuvm out of memory\n");
80106241:	83 ec 0c             	sub    $0xc,%esp
80106244:	68 c9 6e 10 80       	push   $0x80106ec9
80106249:	e8 bd a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010624e:	83 c4 0c             	add    $0xc,%esp
80106251:	ff 75 0c             	pushl  0xc(%ebp)
80106254:	57                   	push   %edi
80106255:	ff 75 08             	pushl  0x8(%ebp)
80106258:	e8 d2 fe ff ff       	call   8010612f <deallocuvm>
      return 0;
8010625d:	83 c4 10             	add    $0x10,%esp
80106260:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106267:	eb 37                	jmp    801062a0 <allocuvm+0xdf>
      cprintf("allocuvm out of memory (2)\n");
80106269:	83 ec 0c             	sub    $0xc,%esp
8010626c:	68 e1 6e 10 80       	push   $0x80106ee1
80106271:	e8 95 a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106276:	83 c4 0c             	add    $0xc,%esp
80106279:	ff 75 0c             	pushl  0xc(%ebp)
8010627c:	57                   	push   %edi
8010627d:	ff 75 08             	pushl  0x8(%ebp)
80106280:	e8 aa fe ff ff       	call   8010612f <deallocuvm>
      kfree(mem);
80106285:	89 34 24             	mov    %esi,(%esp)
80106288:	e8 17 bd ff ff       	call   80101fa4 <kfree>
      return 0;
8010628d:	83 c4 10             	add    $0x10,%esp
80106290:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106297:	eb 07                	jmp    801062a0 <allocuvm+0xdf>
    return 0;
80106299:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
801062a0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801062a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801062a6:	5b                   	pop    %ebx
801062a7:	5e                   	pop    %esi
801062a8:	5f                   	pop    %edi
801062a9:	5d                   	pop    %ebp
801062aa:	c3                   	ret    

801062ab <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801062ab:	55                   	push   %ebp
801062ac:	89 e5                	mov    %esp,%ebp
801062ae:	56                   	push   %esi
801062af:	53                   	push   %ebx
801062b0:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
801062b3:	85 f6                	test   %esi,%esi
801062b5:	74 1a                	je     801062d1 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
801062b7:	83 ec 04             	sub    $0x4,%esp
801062ba:	6a 00                	push   $0x0
801062bc:	68 00 00 00 80       	push   $0x80000000
801062c1:	56                   	push   %esi
801062c2:	e8 68 fe ff ff       	call   8010612f <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801062c7:	83 c4 10             	add    $0x10,%esp
801062ca:	bb 00 00 00 00       	mov    $0x0,%ebx
801062cf:	eb 10                	jmp    801062e1 <freevm+0x36>
    panic("freevm: no pgdir");
801062d1:	83 ec 0c             	sub    $0xc,%esp
801062d4:	68 fd 6e 10 80       	push   $0x80106efd
801062d9:	e8 6a a0 ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
801062de:	83 c3 01             	add    $0x1,%ebx
801062e1:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
801062e7:	77 1f                	ja     80106308 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
801062e9:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
801062ec:	a8 01                	test   $0x1,%al
801062ee:	74 ee                	je     801062de <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801062f0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801062f5:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801062fa:	83 ec 0c             	sub    $0xc,%esp
801062fd:	50                   	push   %eax
801062fe:	e8 a1 bc ff ff       	call   80101fa4 <kfree>
80106303:	83 c4 10             	add    $0x10,%esp
80106306:	eb d6                	jmp    801062de <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
80106308:	83 ec 0c             	sub    $0xc,%esp
8010630b:	56                   	push   %esi
8010630c:	e8 93 bc ff ff       	call   80101fa4 <kfree>
}
80106311:	83 c4 10             	add    $0x10,%esp
80106314:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106317:	5b                   	pop    %ebx
80106318:	5e                   	pop    %esi
80106319:	5d                   	pop    %ebp
8010631a:	c3                   	ret    

8010631b <setupkvm>:
{
8010631b:	55                   	push   %ebp
8010631c:	89 e5                	mov    %esp,%ebp
8010631e:	56                   	push   %esi
8010631f:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
80106320:	e8 a6 bd ff ff       	call   801020cb <kalloc>
80106325:	89 c6                	mov    %eax,%esi
80106327:	85 c0                	test   %eax,%eax
80106329:	74 55                	je     80106380 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
8010632b:	83 ec 04             	sub    $0x4,%esp
8010632e:	68 00 10 00 00       	push   $0x1000
80106333:	6a 00                	push   $0x0
80106335:	50                   	push   %eax
80106336:	e8 ce d9 ff ff       	call   80103d09 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010633b:	83 c4 10             	add    $0x10,%esp
8010633e:	bb 20 94 10 80       	mov    $0x80109420,%ebx
80106343:	81 fb 60 94 10 80    	cmp    $0x80109460,%ebx
80106349:	73 35                	jae    80106380 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
8010634b:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
8010634e:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106351:	29 c1                	sub    %eax,%ecx
80106353:	83 ec 08             	sub    $0x8,%esp
80106356:	ff 73 0c             	pushl  0xc(%ebx)
80106359:	50                   	push   %eax
8010635a:	8b 13                	mov    (%ebx),%edx
8010635c:	89 f0                	mov    %esi,%eax
8010635e:	e8 d7 f9 ff ff       	call   80105d3a <mappages>
80106363:	83 c4 10             	add    $0x10,%esp
80106366:	85 c0                	test   %eax,%eax
80106368:	78 05                	js     8010636f <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010636a:	83 c3 10             	add    $0x10,%ebx
8010636d:	eb d4                	jmp    80106343 <setupkvm+0x28>
      freevm(pgdir);
8010636f:	83 ec 0c             	sub    $0xc,%esp
80106372:	56                   	push   %esi
80106373:	e8 33 ff ff ff       	call   801062ab <freevm>
      return 0;
80106378:	83 c4 10             	add    $0x10,%esp
8010637b:	be 00 00 00 00       	mov    $0x0,%esi
}
80106380:	89 f0                	mov    %esi,%eax
80106382:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106385:	5b                   	pop    %ebx
80106386:	5e                   	pop    %esi
80106387:	5d                   	pop    %ebp
80106388:	c3                   	ret    

80106389 <kvmalloc>:
{
80106389:	55                   	push   %ebp
8010638a:	89 e5                	mov    %esp,%ebp
8010638c:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
8010638f:	e8 87 ff ff ff       	call   8010631b <setupkvm>
80106394:	a3 e4 44 13 80       	mov    %eax,0x801344e4
  switchkvm();
80106399:	e8 5e fb ff ff       	call   80105efc <switchkvm>
}
8010639e:	c9                   	leave  
8010639f:	c3                   	ret    

801063a0 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801063a0:	55                   	push   %ebp
801063a1:	89 e5                	mov    %esp,%ebp
801063a3:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801063a6:	b9 00 00 00 00       	mov    $0x0,%ecx
801063ab:	8b 55 0c             	mov    0xc(%ebp),%edx
801063ae:	8b 45 08             	mov    0x8(%ebp),%eax
801063b1:	e8 14 f9 ff ff       	call   80105cca <walkpgdir>
  if(pte == 0)
801063b6:	85 c0                	test   %eax,%eax
801063b8:	74 05                	je     801063bf <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
801063ba:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
801063bd:	c9                   	leave  
801063be:	c3                   	ret    
    panic("clearpteu");
801063bf:	83 ec 0c             	sub    $0xc,%esp
801063c2:	68 0e 6f 10 80       	push   $0x80106f0e
801063c7:	e8 7c 9f ff ff       	call   80100348 <panic>

801063cc <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801063cc:	55                   	push   %ebp
801063cd:	89 e5                	mov    %esp,%ebp
801063cf:	57                   	push   %edi
801063d0:	56                   	push   %esi
801063d1:	53                   	push   %ebx
801063d2:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801063d5:	e8 41 ff ff ff       	call   8010631b <setupkvm>
801063da:	89 45 dc             	mov    %eax,-0x24(%ebp)
801063dd:	85 c0                	test   %eax,%eax
801063df:	0f 84 c4 00 00 00    	je     801064a9 <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801063e5:	bf 00 00 00 00       	mov    $0x0,%edi
801063ea:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801063ed:	0f 83 b6 00 00 00    	jae    801064a9 <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801063f3:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801063f6:	b9 00 00 00 00       	mov    $0x0,%ecx
801063fb:	89 fa                	mov    %edi,%edx
801063fd:	8b 45 08             	mov    0x8(%ebp),%eax
80106400:	e8 c5 f8 ff ff       	call   80105cca <walkpgdir>
80106405:	85 c0                	test   %eax,%eax
80106407:	74 65                	je     8010646e <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
80106409:	8b 00                	mov    (%eax),%eax
8010640b:	a8 01                	test   $0x1,%al
8010640d:	74 6c                	je     8010647b <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
8010640f:	89 c6                	mov    %eax,%esi
80106411:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
80106417:	25 ff 0f 00 00       	and    $0xfff,%eax
8010641c:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
8010641f:	e8 a7 bc ff ff       	call   801020cb <kalloc>
80106424:	89 c3                	mov    %eax,%ebx
80106426:	85 c0                	test   %eax,%eax
80106428:	74 6a                	je     80106494 <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
8010642a:	81 c6 00 00 00 80    	add    $0x80000000,%esi
80106430:	83 ec 04             	sub    $0x4,%esp
80106433:	68 00 10 00 00       	push   $0x1000
80106438:	56                   	push   %esi
80106439:	50                   	push   %eax
8010643a:	e8 45 d9 ff ff       	call   80103d84 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
8010643f:	83 c4 08             	add    $0x8,%esp
80106442:	ff 75 e0             	pushl  -0x20(%ebp)
80106445:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010644b:	50                   	push   %eax
8010644c:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106451:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106454:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106457:	e8 de f8 ff ff       	call   80105d3a <mappages>
8010645c:	83 c4 10             	add    $0x10,%esp
8010645f:	85 c0                	test   %eax,%eax
80106461:	78 25                	js     80106488 <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
80106463:	81 c7 00 10 00 00    	add    $0x1000,%edi
80106469:	e9 7c ff ff ff       	jmp    801063ea <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
8010646e:	83 ec 0c             	sub    $0xc,%esp
80106471:	68 18 6f 10 80       	push   $0x80106f18
80106476:	e8 cd 9e ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
8010647b:	83 ec 0c             	sub    $0xc,%esp
8010647e:	68 32 6f 10 80       	push   $0x80106f32
80106483:	e8 c0 9e ff ff       	call   80100348 <panic>
      kfree(mem);
80106488:	83 ec 0c             	sub    $0xc,%esp
8010648b:	53                   	push   %ebx
8010648c:	e8 13 bb ff ff       	call   80101fa4 <kfree>
      goto bad;
80106491:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106494:	83 ec 0c             	sub    $0xc,%esp
80106497:	ff 75 dc             	pushl  -0x24(%ebp)
8010649a:	e8 0c fe ff ff       	call   801062ab <freevm>
  return 0;
8010649f:	83 c4 10             	add    $0x10,%esp
801064a2:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
801064a9:	8b 45 dc             	mov    -0x24(%ebp),%eax
801064ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
801064af:	5b                   	pop    %ebx
801064b0:	5e                   	pop    %esi
801064b1:	5f                   	pop    %edi
801064b2:	5d                   	pop    %ebp
801064b3:	c3                   	ret    

801064b4 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801064b4:	55                   	push   %ebp
801064b5:	89 e5                	mov    %esp,%ebp
801064b7:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801064ba:	b9 00 00 00 00       	mov    $0x0,%ecx
801064bf:	8b 55 0c             	mov    0xc(%ebp),%edx
801064c2:	8b 45 08             	mov    0x8(%ebp),%eax
801064c5:	e8 00 f8 ff ff       	call   80105cca <walkpgdir>
  if((*pte & PTE_P) == 0)
801064ca:	8b 00                	mov    (%eax),%eax
801064cc:	a8 01                	test   $0x1,%al
801064ce:	74 10                	je     801064e0 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
801064d0:	a8 04                	test   $0x4,%al
801064d2:	74 13                	je     801064e7 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
801064d4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801064d9:	05 00 00 00 80       	add    $0x80000000,%eax
}
801064de:	c9                   	leave  
801064df:	c3                   	ret    
    return 0;
801064e0:	b8 00 00 00 00       	mov    $0x0,%eax
801064e5:	eb f7                	jmp    801064de <uva2ka+0x2a>
    return 0;
801064e7:	b8 00 00 00 00       	mov    $0x0,%eax
801064ec:	eb f0                	jmp    801064de <uva2ka+0x2a>

801064ee <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801064ee:	55                   	push   %ebp
801064ef:	89 e5                	mov    %esp,%ebp
801064f1:	57                   	push   %edi
801064f2:	56                   	push   %esi
801064f3:	53                   	push   %ebx
801064f4:	83 ec 0c             	sub    $0xc,%esp
801064f7:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801064fa:	eb 25                	jmp    80106521 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801064fc:	8b 55 0c             	mov    0xc(%ebp),%edx
801064ff:	29 f2                	sub    %esi,%edx
80106501:	01 d0                	add    %edx,%eax
80106503:	83 ec 04             	sub    $0x4,%esp
80106506:	53                   	push   %ebx
80106507:	ff 75 10             	pushl  0x10(%ebp)
8010650a:	50                   	push   %eax
8010650b:	e8 74 d8 ff ff       	call   80103d84 <memmove>
    len -= n;
80106510:	29 df                	sub    %ebx,%edi
    buf += n;
80106512:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
80106515:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
8010651b:	89 45 0c             	mov    %eax,0xc(%ebp)
8010651e:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106521:	85 ff                	test   %edi,%edi
80106523:	74 2f                	je     80106554 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
80106525:	8b 75 0c             	mov    0xc(%ebp),%esi
80106528:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
8010652e:	83 ec 08             	sub    $0x8,%esp
80106531:	56                   	push   %esi
80106532:	ff 75 08             	pushl  0x8(%ebp)
80106535:	e8 7a ff ff ff       	call   801064b4 <uva2ka>
    if(pa0 == 0)
8010653a:	83 c4 10             	add    $0x10,%esp
8010653d:	85 c0                	test   %eax,%eax
8010653f:	74 20                	je     80106561 <copyout+0x73>
    n = PGSIZE - (va - va0);
80106541:	89 f3                	mov    %esi,%ebx
80106543:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106546:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
8010654c:	39 df                	cmp    %ebx,%edi
8010654e:	73 ac                	jae    801064fc <copyout+0xe>
      n = len;
80106550:	89 fb                	mov    %edi,%ebx
80106552:	eb a8                	jmp    801064fc <copyout+0xe>
  }
  return 0;
80106554:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106559:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010655c:	5b                   	pop    %ebx
8010655d:	5e                   	pop    %esi
8010655e:	5f                   	pop    %edi
8010655f:	5d                   	pop    %ebp
80106560:	c3                   	ret    
      return -1;
80106561:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106566:	eb f1                	jmp    80106559 <copyout+0x6b>
