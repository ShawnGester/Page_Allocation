
_testDump:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:
#include "stat.h"
#include "user.h"

int
main(int argc, char **argv)
{
   0:	8d 4c 24 04          	lea    0x4(%esp),%ecx
   4:	83 e4 f0             	and    $0xfffffff0,%esp
   7:	ff 71 fc             	pushl  -0x4(%ecx)
   a:	55                   	push   %ebp
   b:	89 e5                	mov    %esp,%ebp
   d:	57                   	push   %edi
   e:	56                   	push   %esi
   f:	53                   	push   %ebx
  10:	51                   	push   %ecx
  11:	83 ec 14             	sub    $0x14,%esp
    // int* test1 = malloc(sizeof(int) * 5);
    // int* test2 = malloc(sizeof(int) * 5);
    int* frames = malloc(sizeof(int) * 20);
  14:	6a 50                	push   $0x50
  16:	e8 5f 05 00 00       	call   57a <malloc>
  1b:	89 c6                	mov    %eax,%esi
    int* pids = malloc(sizeof(int) * 20);
  1d:	c7 04 24 50 00 00 00 	movl   $0x50,(%esp)
  24:	e8 51 05 00 00       	call   57a <malloc>
  29:	89 c7                	mov    %eax,%edi
    int numframes = 20;
    /*for (int i = 0; i < 20; ++i) {
	frames[i] = 0;
	pids[i] = 0;
    }*/
    int parent = fork();
  2b:	e8 d7 01 00 00       	call   207 <fork>
    if (parent) { //parent process
  30:	83 c4 10             	add    $0x10,%esp
  33:	85 c0                	test   %eax,%eax
  35:	75 05                	jne    3c <main+0x3c>
        // nothing
    }

    // free(test1);
    // free(test2);
    exit();
  37:	e8 d3 01 00 00       	call   20f <exit>
        dump_physmem(frames, pids, 20);
  3c:	83 ec 04             	sub    $0x4,%esp
  3f:	6a 14                	push   $0x14
  41:	57                   	push   %edi
  42:	56                   	push   %esi
  43:	e8 67 02 00 00       	call   2af <dump_physmem>
        for (int i = 0; i < numframes; ++i) {
  48:	83 c4 10             	add    $0x10,%esp
  4b:	bb 00 00 00 00       	mov    $0x0,%ebx
  50:	eb 24                	jmp    76 <main+0x76>
	        printf(1, "frames[%d] = %d; pids[%d] = %d\n", i, *(frames+i), i, *(pids+i));
  52:	8d 04 9d 00 00 00 00 	lea    0x0(,%ebx,4),%eax
  59:	83 ec 08             	sub    $0x8,%esp
  5c:	ff 34 07             	pushl  (%edi,%eax,1)
  5f:	53                   	push   %ebx
  60:	ff 34 06             	pushl  (%esi,%eax,1)
  63:	53                   	push   %ebx
  64:	68 0c 06 00 00       	push   $0x60c
  69:	6a 01                	push   $0x1
  6b:	e8 e1 02 00 00       	call   351 <printf>
        for (int i = 0; i < numframes; ++i) {
  70:	83 c3 01             	add    $0x1,%ebx
  73:	83 c4 20             	add    $0x20,%esp
  76:	83 fb 13             	cmp    $0x13,%ebx
  79:	7e d7                	jle    52 <main+0x52>
        wait();
  7b:	e8 97 01 00 00       	call   217 <wait>
  80:	eb b5                	jmp    37 <main+0x37>

00000082 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, const char *t)
{
  82:	55                   	push   %ebp
  83:	89 e5                	mov    %esp,%ebp
  85:	53                   	push   %ebx
  86:	8b 45 08             	mov    0x8(%ebp),%eax
  89:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  8c:	89 c2                	mov    %eax,%edx
  8e:	0f b6 19             	movzbl (%ecx),%ebx
  91:	88 1a                	mov    %bl,(%edx)
  93:	8d 52 01             	lea    0x1(%edx),%edx
  96:	8d 49 01             	lea    0x1(%ecx),%ecx
  99:	84 db                	test   %bl,%bl
  9b:	75 f1                	jne    8e <strcpy+0xc>
    ;
  return os;
}
  9d:	5b                   	pop    %ebx
  9e:	5d                   	pop    %ebp
  9f:	c3                   	ret    

000000a0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  a0:	55                   	push   %ebp
  a1:	89 e5                	mov    %esp,%ebp
  a3:	8b 4d 08             	mov    0x8(%ebp),%ecx
  a6:	8b 55 0c             	mov    0xc(%ebp),%edx
  while(*p && *p == *q)
  a9:	eb 06                	jmp    b1 <strcmp+0x11>
    p++, q++;
  ab:	83 c1 01             	add    $0x1,%ecx
  ae:	83 c2 01             	add    $0x1,%edx
  while(*p && *p == *q)
  b1:	0f b6 01             	movzbl (%ecx),%eax
  b4:	84 c0                	test   %al,%al
  b6:	74 04                	je     bc <strcmp+0x1c>
  b8:	3a 02                	cmp    (%edx),%al
  ba:	74 ef                	je     ab <strcmp+0xb>
  return (uchar)*p - (uchar)*q;
  bc:	0f b6 c0             	movzbl %al,%eax
  bf:	0f b6 12             	movzbl (%edx),%edx
  c2:	29 d0                	sub    %edx,%eax
}
  c4:	5d                   	pop    %ebp
  c5:	c3                   	ret    

000000c6 <strlen>:

uint
strlen(const char *s)
{
  c6:	55                   	push   %ebp
  c7:	89 e5                	mov    %esp,%ebp
  c9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  for(n = 0; s[n]; n++)
  cc:	ba 00 00 00 00       	mov    $0x0,%edx
  d1:	eb 03                	jmp    d6 <strlen+0x10>
  d3:	83 c2 01             	add    $0x1,%edx
  d6:	89 d0                	mov    %edx,%eax
  d8:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  dc:	75 f5                	jne    d3 <strlen+0xd>
    ;
  return n;
}
  de:	5d                   	pop    %ebp
  df:	c3                   	ret    

000000e0 <memset>:

void*
memset(void *dst, int c, uint n)
{
  e0:	55                   	push   %ebp
  e1:	89 e5                	mov    %esp,%ebp
  e3:	57                   	push   %edi
  e4:	8b 55 08             	mov    0x8(%ebp),%edx
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
  e7:	89 d7                	mov    %edx,%edi
  e9:	8b 4d 10             	mov    0x10(%ebp),%ecx
  ec:	8b 45 0c             	mov    0xc(%ebp),%eax
  ef:	fc                   	cld    
  f0:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
  f2:	89 d0                	mov    %edx,%eax
  f4:	5f                   	pop    %edi
  f5:	5d                   	pop    %ebp
  f6:	c3                   	ret    

000000f7 <strchr>:

char*
strchr(const char *s, char c)
{
  f7:	55                   	push   %ebp
  f8:	89 e5                	mov    %esp,%ebp
  fa:	8b 45 08             	mov    0x8(%ebp),%eax
  fd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
  for(; *s; s++)
 101:	0f b6 10             	movzbl (%eax),%edx
 104:	84 d2                	test   %dl,%dl
 106:	74 09                	je     111 <strchr+0x1a>
    if(*s == c)
 108:	38 ca                	cmp    %cl,%dl
 10a:	74 0a                	je     116 <strchr+0x1f>
  for(; *s; s++)
 10c:	83 c0 01             	add    $0x1,%eax
 10f:	eb f0                	jmp    101 <strchr+0xa>
      return (char*)s;
  return 0;
 111:	b8 00 00 00 00       	mov    $0x0,%eax
}
 116:	5d                   	pop    %ebp
 117:	c3                   	ret    

00000118 <gets>:

char*
gets(char *buf, int max)
{
 118:	55                   	push   %ebp
 119:	89 e5                	mov    %esp,%ebp
 11b:	57                   	push   %edi
 11c:	56                   	push   %esi
 11d:	53                   	push   %ebx
 11e:	83 ec 1c             	sub    $0x1c,%esp
 121:	8b 7d 08             	mov    0x8(%ebp),%edi
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 124:	bb 00 00 00 00       	mov    $0x0,%ebx
 129:	8d 73 01             	lea    0x1(%ebx),%esi
 12c:	3b 75 0c             	cmp    0xc(%ebp),%esi
 12f:	7d 2e                	jge    15f <gets+0x47>
    cc = read(0, &c, 1);
 131:	83 ec 04             	sub    $0x4,%esp
 134:	6a 01                	push   $0x1
 136:	8d 45 e7             	lea    -0x19(%ebp),%eax
 139:	50                   	push   %eax
 13a:	6a 00                	push   $0x0
 13c:	e8 e6 00 00 00       	call   227 <read>
    if(cc < 1)
 141:	83 c4 10             	add    $0x10,%esp
 144:	85 c0                	test   %eax,%eax
 146:	7e 17                	jle    15f <gets+0x47>
      break;
    buf[i++] = c;
 148:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
 14c:	88 04 1f             	mov    %al,(%edi,%ebx,1)
    if(c == '\n' || c == '\r')
 14f:	3c 0a                	cmp    $0xa,%al
 151:	0f 94 c2             	sete   %dl
 154:	3c 0d                	cmp    $0xd,%al
 156:	0f 94 c0             	sete   %al
    buf[i++] = c;
 159:	89 f3                	mov    %esi,%ebx
    if(c == '\n' || c == '\r')
 15b:	08 c2                	or     %al,%dl
 15d:	74 ca                	je     129 <gets+0x11>
      break;
  }
  buf[i] = '\0';
 15f:	c6 04 1f 00          	movb   $0x0,(%edi,%ebx,1)
  return buf;
}
 163:	89 f8                	mov    %edi,%eax
 165:	8d 65 f4             	lea    -0xc(%ebp),%esp
 168:	5b                   	pop    %ebx
 169:	5e                   	pop    %esi
 16a:	5f                   	pop    %edi
 16b:	5d                   	pop    %ebp
 16c:	c3                   	ret    

0000016d <stat>:

int
stat(const char *n, struct stat *st)
{
 16d:	55                   	push   %ebp
 16e:	89 e5                	mov    %esp,%ebp
 170:	56                   	push   %esi
 171:	53                   	push   %ebx
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 172:	83 ec 08             	sub    $0x8,%esp
 175:	6a 00                	push   $0x0
 177:	ff 75 08             	pushl  0x8(%ebp)
 17a:	e8 d0 00 00 00       	call   24f <open>
  if(fd < 0)
 17f:	83 c4 10             	add    $0x10,%esp
 182:	85 c0                	test   %eax,%eax
 184:	78 24                	js     1aa <stat+0x3d>
 186:	89 c3                	mov    %eax,%ebx
    return -1;
  r = fstat(fd, st);
 188:	83 ec 08             	sub    $0x8,%esp
 18b:	ff 75 0c             	pushl  0xc(%ebp)
 18e:	50                   	push   %eax
 18f:	e8 d3 00 00 00       	call   267 <fstat>
 194:	89 c6                	mov    %eax,%esi
  close(fd);
 196:	89 1c 24             	mov    %ebx,(%esp)
 199:	e8 99 00 00 00       	call   237 <close>
  return r;
 19e:	83 c4 10             	add    $0x10,%esp
}
 1a1:	89 f0                	mov    %esi,%eax
 1a3:	8d 65 f8             	lea    -0x8(%ebp),%esp
 1a6:	5b                   	pop    %ebx
 1a7:	5e                   	pop    %esi
 1a8:	5d                   	pop    %ebp
 1a9:	c3                   	ret    
    return -1;
 1aa:	be ff ff ff ff       	mov    $0xffffffff,%esi
 1af:	eb f0                	jmp    1a1 <stat+0x34>

000001b1 <atoi>:

int
atoi(const char *s)
{
 1b1:	55                   	push   %ebp
 1b2:	89 e5                	mov    %esp,%ebp
 1b4:	53                   	push   %ebx
 1b5:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  n = 0;
 1b8:	b8 00 00 00 00       	mov    $0x0,%eax
  while('0' <= *s && *s <= '9')
 1bd:	eb 10                	jmp    1cf <atoi+0x1e>
    n = n*10 + *s++ - '0';
 1bf:	8d 1c 80             	lea    (%eax,%eax,4),%ebx
 1c2:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
 1c5:	83 c1 01             	add    $0x1,%ecx
 1c8:	0f be d2             	movsbl %dl,%edx
 1cb:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
  while('0' <= *s && *s <= '9')
 1cf:	0f b6 11             	movzbl (%ecx),%edx
 1d2:	8d 5a d0             	lea    -0x30(%edx),%ebx
 1d5:	80 fb 09             	cmp    $0x9,%bl
 1d8:	76 e5                	jbe    1bf <atoi+0xe>
  return n;
}
 1da:	5b                   	pop    %ebx
 1db:	5d                   	pop    %ebp
 1dc:	c3                   	ret    

000001dd <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1dd:	55                   	push   %ebp
 1de:	89 e5                	mov    %esp,%ebp
 1e0:	56                   	push   %esi
 1e1:	53                   	push   %ebx
 1e2:	8b 45 08             	mov    0x8(%ebp),%eax
 1e5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
 1e8:	8b 55 10             	mov    0x10(%ebp),%edx
  char *dst;
  const char *src;

  dst = vdst;
 1eb:	89 c1                	mov    %eax,%ecx
  src = vsrc;
  while(n-- > 0)
 1ed:	eb 0d                	jmp    1fc <memmove+0x1f>
    *dst++ = *src++;
 1ef:	0f b6 13             	movzbl (%ebx),%edx
 1f2:	88 11                	mov    %dl,(%ecx)
 1f4:	8d 5b 01             	lea    0x1(%ebx),%ebx
 1f7:	8d 49 01             	lea    0x1(%ecx),%ecx
  while(n-- > 0)
 1fa:	89 f2                	mov    %esi,%edx
 1fc:	8d 72 ff             	lea    -0x1(%edx),%esi
 1ff:	85 d2                	test   %edx,%edx
 201:	7f ec                	jg     1ef <memmove+0x12>
  return vdst;
}
 203:	5b                   	pop    %ebx
 204:	5e                   	pop    %esi
 205:	5d                   	pop    %ebp
 206:	c3                   	ret    

00000207 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 207:	b8 01 00 00 00       	mov    $0x1,%eax
 20c:	cd 40                	int    $0x40
 20e:	c3                   	ret    

0000020f <exit>:
SYSCALL(exit)
 20f:	b8 02 00 00 00       	mov    $0x2,%eax
 214:	cd 40                	int    $0x40
 216:	c3                   	ret    

00000217 <wait>:
SYSCALL(wait)
 217:	b8 03 00 00 00       	mov    $0x3,%eax
 21c:	cd 40                	int    $0x40
 21e:	c3                   	ret    

0000021f <pipe>:
SYSCALL(pipe)
 21f:	b8 04 00 00 00       	mov    $0x4,%eax
 224:	cd 40                	int    $0x40
 226:	c3                   	ret    

00000227 <read>:
SYSCALL(read)
 227:	b8 05 00 00 00       	mov    $0x5,%eax
 22c:	cd 40                	int    $0x40
 22e:	c3                   	ret    

0000022f <write>:
SYSCALL(write)
 22f:	b8 10 00 00 00       	mov    $0x10,%eax
 234:	cd 40                	int    $0x40
 236:	c3                   	ret    

00000237 <close>:
SYSCALL(close)
 237:	b8 15 00 00 00       	mov    $0x15,%eax
 23c:	cd 40                	int    $0x40
 23e:	c3                   	ret    

0000023f <kill>:
SYSCALL(kill)
 23f:	b8 06 00 00 00       	mov    $0x6,%eax
 244:	cd 40                	int    $0x40
 246:	c3                   	ret    

00000247 <exec>:
SYSCALL(exec)
 247:	b8 07 00 00 00       	mov    $0x7,%eax
 24c:	cd 40                	int    $0x40
 24e:	c3                   	ret    

0000024f <open>:
SYSCALL(open)
 24f:	b8 0f 00 00 00       	mov    $0xf,%eax
 254:	cd 40                	int    $0x40
 256:	c3                   	ret    

00000257 <mknod>:
SYSCALL(mknod)
 257:	b8 11 00 00 00       	mov    $0x11,%eax
 25c:	cd 40                	int    $0x40
 25e:	c3                   	ret    

0000025f <unlink>:
SYSCALL(unlink)
 25f:	b8 12 00 00 00       	mov    $0x12,%eax
 264:	cd 40                	int    $0x40
 266:	c3                   	ret    

00000267 <fstat>:
SYSCALL(fstat)
 267:	b8 08 00 00 00       	mov    $0x8,%eax
 26c:	cd 40                	int    $0x40
 26e:	c3                   	ret    

0000026f <link>:
SYSCALL(link)
 26f:	b8 13 00 00 00       	mov    $0x13,%eax
 274:	cd 40                	int    $0x40
 276:	c3                   	ret    

00000277 <mkdir>:
SYSCALL(mkdir)
 277:	b8 14 00 00 00       	mov    $0x14,%eax
 27c:	cd 40                	int    $0x40
 27e:	c3                   	ret    

0000027f <chdir>:
SYSCALL(chdir)
 27f:	b8 09 00 00 00       	mov    $0x9,%eax
 284:	cd 40                	int    $0x40
 286:	c3                   	ret    

00000287 <dup>:
SYSCALL(dup)
 287:	b8 0a 00 00 00       	mov    $0xa,%eax
 28c:	cd 40                	int    $0x40
 28e:	c3                   	ret    

0000028f <getpid>:
SYSCALL(getpid)
 28f:	b8 0b 00 00 00       	mov    $0xb,%eax
 294:	cd 40                	int    $0x40
 296:	c3                   	ret    

00000297 <sbrk>:
SYSCALL(sbrk)
 297:	b8 0c 00 00 00       	mov    $0xc,%eax
 29c:	cd 40                	int    $0x40
 29e:	c3                   	ret    

0000029f <sleep>:
SYSCALL(sleep)
 29f:	b8 0d 00 00 00       	mov    $0xd,%eax
 2a4:	cd 40                	int    $0x40
 2a6:	c3                   	ret    

000002a7 <uptime>:
SYSCALL(uptime)
 2a7:	b8 0e 00 00 00       	mov    $0xe,%eax
 2ac:	cd 40                	int    $0x40
 2ae:	c3                   	ret    

000002af <dump_physmem>:
SYSCALL(dump_physmem)
 2af:	b8 16 00 00 00       	mov    $0x16,%eax
 2b4:	cd 40                	int    $0x40
 2b6:	c3                   	ret    

000002b7 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 2b7:	55                   	push   %ebp
 2b8:	89 e5                	mov    %esp,%ebp
 2ba:	83 ec 1c             	sub    $0x1c,%esp
 2bd:	88 55 f4             	mov    %dl,-0xc(%ebp)
  write(fd, &c, 1);
 2c0:	6a 01                	push   $0x1
 2c2:	8d 55 f4             	lea    -0xc(%ebp),%edx
 2c5:	52                   	push   %edx
 2c6:	50                   	push   %eax
 2c7:	e8 63 ff ff ff       	call   22f <write>
}
 2cc:	83 c4 10             	add    $0x10,%esp
 2cf:	c9                   	leave  
 2d0:	c3                   	ret    

000002d1 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 2d1:	55                   	push   %ebp
 2d2:	89 e5                	mov    %esp,%ebp
 2d4:	57                   	push   %edi
 2d5:	56                   	push   %esi
 2d6:	53                   	push   %ebx
 2d7:	83 ec 2c             	sub    $0x2c,%esp
 2da:	89 c7                	mov    %eax,%edi
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 2dc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
 2e0:	0f 95 c3             	setne  %bl
 2e3:	89 d0                	mov    %edx,%eax
 2e5:	c1 e8 1f             	shr    $0x1f,%eax
 2e8:	84 c3                	test   %al,%bl
 2ea:	74 10                	je     2fc <printint+0x2b>
    neg = 1;
    x = -xx;
 2ec:	f7 da                	neg    %edx
    neg = 1;
 2ee:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  } else {
    x = xx;
  }

  i = 0;
 2f5:	be 00 00 00 00       	mov    $0x0,%esi
 2fa:	eb 0b                	jmp    307 <printint+0x36>
  neg = 0;
 2fc:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 303:	eb f0                	jmp    2f5 <printint+0x24>
  do{
    buf[i++] = digits[x % base];
 305:	89 c6                	mov    %eax,%esi
 307:	89 d0                	mov    %edx,%eax
 309:	ba 00 00 00 00       	mov    $0x0,%edx
 30e:	f7 f1                	div    %ecx
 310:	89 c3                	mov    %eax,%ebx
 312:	8d 46 01             	lea    0x1(%esi),%eax
 315:	0f b6 92 34 06 00 00 	movzbl 0x634(%edx),%edx
 31c:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
 320:	89 da                	mov    %ebx,%edx
 322:	85 db                	test   %ebx,%ebx
 324:	75 df                	jne    305 <printint+0x34>
 326:	89 c3                	mov    %eax,%ebx
  if(neg)
 328:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
 32c:	74 16                	je     344 <printint+0x73>
    buf[i++] = '-';
 32e:	c6 44 05 d8 2d       	movb   $0x2d,-0x28(%ebp,%eax,1)
 333:	8d 5e 02             	lea    0x2(%esi),%ebx
 336:	eb 0c                	jmp    344 <printint+0x73>

  while(--i >= 0)
    putc(fd, buf[i]);
 338:	0f be 54 1d d8       	movsbl -0x28(%ebp,%ebx,1),%edx
 33d:	89 f8                	mov    %edi,%eax
 33f:	e8 73 ff ff ff       	call   2b7 <putc>
  while(--i >= 0)
 344:	83 eb 01             	sub    $0x1,%ebx
 347:	79 ef                	jns    338 <printint+0x67>
}
 349:	83 c4 2c             	add    $0x2c,%esp
 34c:	5b                   	pop    %ebx
 34d:	5e                   	pop    %esi
 34e:	5f                   	pop    %edi
 34f:	5d                   	pop    %ebp
 350:	c3                   	ret    

00000351 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, const char *fmt, ...)
{
 351:	55                   	push   %ebp
 352:	89 e5                	mov    %esp,%ebp
 354:	57                   	push   %edi
 355:	56                   	push   %esi
 356:	53                   	push   %ebx
 357:	83 ec 1c             	sub    $0x1c,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
 35a:	8d 45 10             	lea    0x10(%ebp),%eax
 35d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  state = 0;
 360:	be 00 00 00 00       	mov    $0x0,%esi
  for(i = 0; fmt[i]; i++){
 365:	bb 00 00 00 00       	mov    $0x0,%ebx
 36a:	eb 14                	jmp    380 <printf+0x2f>
    c = fmt[i] & 0xff;
    if(state == 0){
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
 36c:	89 fa                	mov    %edi,%edx
 36e:	8b 45 08             	mov    0x8(%ebp),%eax
 371:	e8 41 ff ff ff       	call   2b7 <putc>
 376:	eb 05                	jmp    37d <printf+0x2c>
      }
    } else if(state == '%'){
 378:	83 fe 25             	cmp    $0x25,%esi
 37b:	74 25                	je     3a2 <printf+0x51>
  for(i = 0; fmt[i]; i++){
 37d:	83 c3 01             	add    $0x1,%ebx
 380:	8b 45 0c             	mov    0xc(%ebp),%eax
 383:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
 387:	84 c0                	test   %al,%al
 389:	0f 84 23 01 00 00    	je     4b2 <printf+0x161>
    c = fmt[i] & 0xff;
 38f:	0f be f8             	movsbl %al,%edi
 392:	0f b6 c0             	movzbl %al,%eax
    if(state == 0){
 395:	85 f6                	test   %esi,%esi
 397:	75 df                	jne    378 <printf+0x27>
      if(c == '%'){
 399:	83 f8 25             	cmp    $0x25,%eax
 39c:	75 ce                	jne    36c <printf+0x1b>
        state = '%';
 39e:	89 c6                	mov    %eax,%esi
 3a0:	eb db                	jmp    37d <printf+0x2c>
      if(c == 'd'){
 3a2:	83 f8 64             	cmp    $0x64,%eax
 3a5:	74 49                	je     3f0 <printf+0x9f>
        printint(fd, *ap, 10, 1);
        ap++;
      } else if(c == 'x' || c == 'p'){
 3a7:	83 f8 78             	cmp    $0x78,%eax
 3aa:	0f 94 c1             	sete   %cl
 3ad:	83 f8 70             	cmp    $0x70,%eax
 3b0:	0f 94 c2             	sete   %dl
 3b3:	08 d1                	or     %dl,%cl
 3b5:	75 63                	jne    41a <printf+0xc9>
        printint(fd, *ap, 16, 0);
        ap++;
      } else if(c == 's'){
 3b7:	83 f8 73             	cmp    $0x73,%eax
 3ba:	0f 84 84 00 00 00    	je     444 <printf+0xf3>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 3c0:	83 f8 63             	cmp    $0x63,%eax
 3c3:	0f 84 b7 00 00 00    	je     480 <printf+0x12f>
        putc(fd, *ap);
        ap++;
      } else if(c == '%'){
 3c9:	83 f8 25             	cmp    $0x25,%eax
 3cc:	0f 84 cc 00 00 00    	je     49e <printf+0x14d>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 3d2:	ba 25 00 00 00       	mov    $0x25,%edx
 3d7:	8b 45 08             	mov    0x8(%ebp),%eax
 3da:	e8 d8 fe ff ff       	call   2b7 <putc>
        putc(fd, c);
 3df:	89 fa                	mov    %edi,%edx
 3e1:	8b 45 08             	mov    0x8(%ebp),%eax
 3e4:	e8 ce fe ff ff       	call   2b7 <putc>
      }
      state = 0;
 3e9:	be 00 00 00 00       	mov    $0x0,%esi
 3ee:	eb 8d                	jmp    37d <printf+0x2c>
        printint(fd, *ap, 10, 1);
 3f0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 3f3:	8b 17                	mov    (%edi),%edx
 3f5:	83 ec 0c             	sub    $0xc,%esp
 3f8:	6a 01                	push   $0x1
 3fa:	b9 0a 00 00 00       	mov    $0xa,%ecx
 3ff:	8b 45 08             	mov    0x8(%ebp),%eax
 402:	e8 ca fe ff ff       	call   2d1 <printint>
        ap++;
 407:	83 c7 04             	add    $0x4,%edi
 40a:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 40d:	83 c4 10             	add    $0x10,%esp
      state = 0;
 410:	be 00 00 00 00       	mov    $0x0,%esi
 415:	e9 63 ff ff ff       	jmp    37d <printf+0x2c>
        printint(fd, *ap, 16, 0);
 41a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 41d:	8b 17                	mov    (%edi),%edx
 41f:	83 ec 0c             	sub    $0xc,%esp
 422:	6a 00                	push   $0x0
 424:	b9 10 00 00 00       	mov    $0x10,%ecx
 429:	8b 45 08             	mov    0x8(%ebp),%eax
 42c:	e8 a0 fe ff ff       	call   2d1 <printint>
        ap++;
 431:	83 c7 04             	add    $0x4,%edi
 434:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 437:	83 c4 10             	add    $0x10,%esp
      state = 0;
 43a:	be 00 00 00 00       	mov    $0x0,%esi
 43f:	e9 39 ff ff ff       	jmp    37d <printf+0x2c>
        s = (char*)*ap;
 444:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 447:	8b 30                	mov    (%eax),%esi
        ap++;
 449:	83 c0 04             	add    $0x4,%eax
 44c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if(s == 0)
 44f:	85 f6                	test   %esi,%esi
 451:	75 28                	jne    47b <printf+0x12a>
          s = "(null)";
 453:	be 2c 06 00 00       	mov    $0x62c,%esi
 458:	8b 7d 08             	mov    0x8(%ebp),%edi
 45b:	eb 0d                	jmp    46a <printf+0x119>
          putc(fd, *s);
 45d:	0f be d2             	movsbl %dl,%edx
 460:	89 f8                	mov    %edi,%eax
 462:	e8 50 fe ff ff       	call   2b7 <putc>
          s++;
 467:	83 c6 01             	add    $0x1,%esi
        while(*s != 0){
 46a:	0f b6 16             	movzbl (%esi),%edx
 46d:	84 d2                	test   %dl,%dl
 46f:	75 ec                	jne    45d <printf+0x10c>
      state = 0;
 471:	be 00 00 00 00       	mov    $0x0,%esi
 476:	e9 02 ff ff ff       	jmp    37d <printf+0x2c>
 47b:	8b 7d 08             	mov    0x8(%ebp),%edi
 47e:	eb ea                	jmp    46a <printf+0x119>
        putc(fd, *ap);
 480:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 483:	0f be 17             	movsbl (%edi),%edx
 486:	8b 45 08             	mov    0x8(%ebp),%eax
 489:	e8 29 fe ff ff       	call   2b7 <putc>
        ap++;
 48e:	83 c7 04             	add    $0x4,%edi
 491:	89 7d e4             	mov    %edi,-0x1c(%ebp)
      state = 0;
 494:	be 00 00 00 00       	mov    $0x0,%esi
 499:	e9 df fe ff ff       	jmp    37d <printf+0x2c>
        putc(fd, c);
 49e:	89 fa                	mov    %edi,%edx
 4a0:	8b 45 08             	mov    0x8(%ebp),%eax
 4a3:	e8 0f fe ff ff       	call   2b7 <putc>
      state = 0;
 4a8:	be 00 00 00 00       	mov    $0x0,%esi
 4ad:	e9 cb fe ff ff       	jmp    37d <printf+0x2c>
    }
  }
}
 4b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
 4b5:	5b                   	pop    %ebx
 4b6:	5e                   	pop    %esi
 4b7:	5f                   	pop    %edi
 4b8:	5d                   	pop    %ebp
 4b9:	c3                   	ret    

000004ba <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 4ba:	55                   	push   %ebp
 4bb:	89 e5                	mov    %esp,%ebp
 4bd:	57                   	push   %edi
 4be:	56                   	push   %esi
 4bf:	53                   	push   %ebx
 4c0:	8b 5d 08             	mov    0x8(%ebp),%ebx
  Header *bp, *p;

  bp = (Header*)ap - 1;
 4c3:	8d 4b f8             	lea    -0x8(%ebx),%ecx
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 4c6:	a1 d8 08 00 00       	mov    0x8d8,%eax
 4cb:	eb 02                	jmp    4cf <free+0x15>
 4cd:	89 d0                	mov    %edx,%eax
 4cf:	39 c8                	cmp    %ecx,%eax
 4d1:	73 04                	jae    4d7 <free+0x1d>
 4d3:	39 08                	cmp    %ecx,(%eax)
 4d5:	77 12                	ja     4e9 <free+0x2f>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 4d7:	8b 10                	mov    (%eax),%edx
 4d9:	39 c2                	cmp    %eax,%edx
 4db:	77 f0                	ja     4cd <free+0x13>
 4dd:	39 c8                	cmp    %ecx,%eax
 4df:	72 08                	jb     4e9 <free+0x2f>
 4e1:	39 ca                	cmp    %ecx,%edx
 4e3:	77 04                	ja     4e9 <free+0x2f>
 4e5:	89 d0                	mov    %edx,%eax
 4e7:	eb e6                	jmp    4cf <free+0x15>
      break;
  if(bp + bp->s.size == p->s.ptr){
 4e9:	8b 73 fc             	mov    -0x4(%ebx),%esi
 4ec:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
 4ef:	8b 10                	mov    (%eax),%edx
 4f1:	39 d7                	cmp    %edx,%edi
 4f3:	74 19                	je     50e <free+0x54>
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
 4f5:	89 53 f8             	mov    %edx,-0x8(%ebx)
  if(p + p->s.size == bp){
 4f8:	8b 50 04             	mov    0x4(%eax),%edx
 4fb:	8d 34 d0             	lea    (%eax,%edx,8),%esi
 4fe:	39 ce                	cmp    %ecx,%esi
 500:	74 1b                	je     51d <free+0x63>
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
 502:	89 08                	mov    %ecx,(%eax)
  freep = p;
 504:	a3 d8 08 00 00       	mov    %eax,0x8d8
}
 509:	5b                   	pop    %ebx
 50a:	5e                   	pop    %esi
 50b:	5f                   	pop    %edi
 50c:	5d                   	pop    %ebp
 50d:	c3                   	ret    
    bp->s.size += p->s.ptr->s.size;
 50e:	03 72 04             	add    0x4(%edx),%esi
 511:	89 73 fc             	mov    %esi,-0x4(%ebx)
    bp->s.ptr = p->s.ptr->s.ptr;
 514:	8b 10                	mov    (%eax),%edx
 516:	8b 12                	mov    (%edx),%edx
 518:	89 53 f8             	mov    %edx,-0x8(%ebx)
 51b:	eb db                	jmp    4f8 <free+0x3e>
    p->s.size += bp->s.size;
 51d:	03 53 fc             	add    -0x4(%ebx),%edx
 520:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 523:	8b 53 f8             	mov    -0x8(%ebx),%edx
 526:	89 10                	mov    %edx,(%eax)
 528:	eb da                	jmp    504 <free+0x4a>

0000052a <morecore>:

static Header*
morecore(uint nu)
{
 52a:	55                   	push   %ebp
 52b:	89 e5                	mov    %esp,%ebp
 52d:	53                   	push   %ebx
 52e:	83 ec 04             	sub    $0x4,%esp
 531:	89 c3                	mov    %eax,%ebx
  char *p;
  Header *hp;

  if(nu < 4096)
 533:	3d ff 0f 00 00       	cmp    $0xfff,%eax
 538:	77 05                	ja     53f <morecore+0x15>
    nu = 4096;
 53a:	bb 00 10 00 00       	mov    $0x1000,%ebx
  p = sbrk(nu * sizeof(Header));
 53f:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
 546:	83 ec 0c             	sub    $0xc,%esp
 549:	50                   	push   %eax
 54a:	e8 48 fd ff ff       	call   297 <sbrk>
  if(p == (char*)-1)
 54f:	83 c4 10             	add    $0x10,%esp
 552:	83 f8 ff             	cmp    $0xffffffff,%eax
 555:	74 1c                	je     573 <morecore+0x49>
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
 557:	89 58 04             	mov    %ebx,0x4(%eax)
  free((void*)(hp + 1));
 55a:	83 c0 08             	add    $0x8,%eax
 55d:	83 ec 0c             	sub    $0xc,%esp
 560:	50                   	push   %eax
 561:	e8 54 ff ff ff       	call   4ba <free>
  return freep;
 566:	a1 d8 08 00 00       	mov    0x8d8,%eax
 56b:	83 c4 10             	add    $0x10,%esp
}
 56e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 571:	c9                   	leave  
 572:	c3                   	ret    
    return 0;
 573:	b8 00 00 00 00       	mov    $0x0,%eax
 578:	eb f4                	jmp    56e <morecore+0x44>

0000057a <malloc>:

void*
malloc(uint nbytes)
{
 57a:	55                   	push   %ebp
 57b:	89 e5                	mov    %esp,%ebp
 57d:	53                   	push   %ebx
 57e:	83 ec 04             	sub    $0x4,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 581:	8b 45 08             	mov    0x8(%ebp),%eax
 584:	8d 58 07             	lea    0x7(%eax),%ebx
 587:	c1 eb 03             	shr    $0x3,%ebx
 58a:	83 c3 01             	add    $0x1,%ebx
  if((prevp = freep) == 0){
 58d:	8b 0d d8 08 00 00    	mov    0x8d8,%ecx
 593:	85 c9                	test   %ecx,%ecx
 595:	74 04                	je     59b <malloc+0x21>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 597:	8b 01                	mov    (%ecx),%eax
 599:	eb 4d                	jmp    5e8 <malloc+0x6e>
    base.s.ptr = freep = prevp = &base;
 59b:	c7 05 d8 08 00 00 dc 	movl   $0x8dc,0x8d8
 5a2:	08 00 00 
 5a5:	c7 05 dc 08 00 00 dc 	movl   $0x8dc,0x8dc
 5ac:	08 00 00 
    base.s.size = 0;
 5af:	c7 05 e0 08 00 00 00 	movl   $0x0,0x8e0
 5b6:	00 00 00 
    base.s.ptr = freep = prevp = &base;
 5b9:	b9 dc 08 00 00       	mov    $0x8dc,%ecx
 5be:	eb d7                	jmp    597 <malloc+0x1d>
    if(p->s.size >= nunits){
      if(p->s.size == nunits)
 5c0:	39 da                	cmp    %ebx,%edx
 5c2:	74 1a                	je     5de <malloc+0x64>
        prevp->s.ptr = p->s.ptr;
      else {
        p->s.size -= nunits;
 5c4:	29 da                	sub    %ebx,%edx
 5c6:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 5c9:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        p->s.size = nunits;
 5cc:	89 58 04             	mov    %ebx,0x4(%eax)
      }
      freep = prevp;
 5cf:	89 0d d8 08 00 00    	mov    %ecx,0x8d8
      return (void*)(p + 1);
 5d5:	83 c0 08             	add    $0x8,%eax
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 5d8:	83 c4 04             	add    $0x4,%esp
 5db:	5b                   	pop    %ebx
 5dc:	5d                   	pop    %ebp
 5dd:	c3                   	ret    
        prevp->s.ptr = p->s.ptr;
 5de:	8b 10                	mov    (%eax),%edx
 5e0:	89 11                	mov    %edx,(%ecx)
 5e2:	eb eb                	jmp    5cf <malloc+0x55>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 5e4:	89 c1                	mov    %eax,%ecx
 5e6:	8b 00                	mov    (%eax),%eax
    if(p->s.size >= nunits){
 5e8:	8b 50 04             	mov    0x4(%eax),%edx
 5eb:	39 da                	cmp    %ebx,%edx
 5ed:	73 d1                	jae    5c0 <malloc+0x46>
    if(p == freep)
 5ef:	39 05 d8 08 00 00    	cmp    %eax,0x8d8
 5f5:	75 ed                	jne    5e4 <malloc+0x6a>
      if((p = morecore(nunits)) == 0)
 5f7:	89 d8                	mov    %ebx,%eax
 5f9:	e8 2c ff ff ff       	call   52a <morecore>
 5fe:	85 c0                	test   %eax,%eax
 600:	75 e2                	jne    5e4 <malloc+0x6a>
        return 0;
 602:	b8 00 00 00 00       	mov    $0x0,%eax
 607:	eb cf                	jmp    5d8 <malloc+0x5e>
