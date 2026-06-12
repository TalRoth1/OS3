
user/_show_flip:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
}

// ── main ──────────────────────────────────────────────────────────────

int main(int argc, char *argv[])
{
   0:	7109                	addi	sp,sp,-384
   2:	fe86                	sd	ra,376(sp)
   4:	faa2                	sd	s0,368(sp)
   6:	f6a6                	sd	s1,360(sp)
   8:	f2ca                	sd	s2,352(sp)
   a:	eece                	sd	s3,344(sp)
   c:	ead2                	sd	s4,336(sp)
   e:	e6d6                	sd	s5,328(sp)
  10:	e2da                	sd	s6,320(sp)
  12:	fe5e                	sd	s7,312(sp)
  14:	fa62                	sd	s8,304(sp)
  16:	f666                	sd	s9,296(sp)
  18:	f26a                	sd	s10,288(sp)
  1a:	ee6e                	sd	s11,280(sp)
  1c:	0300                	addi	s0,sp,384
    if (argc < 2)
  1e:	4785                	li	a5,1
  20:	00a7de63          	bge	a5,a0,3c <main+0x3c>
  24:	882a                	mv	a6,a0
  26:	05a1                	addi	a1,a1,8
    }

    // Join all arguments with spaces.
    char text[256];
    int pos = 0;
    for (int i = 1; i < argc && pos < (int)sizeof(text) - 1; i++)
  28:	4505                	li	a0,1
    int pos = 0;
  2a:	4981                	li	s3,0
    {
        if (i > 1 && pos < (int)sizeof(text) - 1)
            text[pos++] = ' ';
        for (char *s = argv[i]; *s && pos < (int)sizeof(text) - 1; s++)
  2c:	0fe00893          	li	a7,254
  30:	0ff00613          	li	a2,255
        if (i > 1 && pos < (int)sizeof(text) - 1)
  34:	4e05                	li	t3,1
            text[pos++] = ' ';
  36:	02000313          	li	t1,32
  3a:	a82d                	j	74 <main+0x74>
        fprintf(2, "Usage: show_flip <text>\n");
  3c:	00001597          	auipc	a1,0x1
  40:	9d458593          	addi	a1,a1,-1580 # a10 <malloc+0xe8>
  44:	4509                	li	a0,2
  46:	00000097          	auipc	ra,0x0
  4a:	7f6080e7          	jalr	2038(ra) # 83c <fprintf>
        exit(1);
  4e:	4505                	li	a0,1
  50:	00000097          	auipc	ra,0x0
  54:	492080e7          	jalr	1170(ra) # 4e2 <exit>
    for (int i = 1; i < argc && pos < (int)sizeof(text) - 1; i++)
  58:	2505                	addiw	a0,a0,1
  5a:	04a80063          	beq	a6,a0,9a <main+0x9a>
  5e:	0d38c863          	blt	a7,s3,12e <main+0x12e>
        if (i > 1 && pos < (int)sizeof(text) - 1)
  62:	00ae5863          	bge	t3,a0,72 <main+0x72>
            text[pos++] = ' ';
  66:	f9040793          	addi	a5,s0,-112
  6a:	97ce                	add	a5,a5,s3
  6c:	f0678023          	sb	t1,-256(a5)
  70:	2985                	addiw	s3,s3,1
  72:	05a1                	addi	a1,a1,8
        for (char *s = argv[i]; *s && pos < (int)sizeof(text) - 1; s++)
  74:	6198                	ld	a4,0(a1)
  76:	00074783          	lbu	a5,0(a4)
  7a:	dff9                	beqz	a5,58 <main+0x58>
  7c:	0138cf63          	blt	a7,s3,9a <main+0x9a>
  80:	e9040693          	addi	a3,s0,-368
  84:	96ce                	add	a3,a3,s3
            text[pos++] = *s;
  86:	2985                	addiw	s3,s3,1
  88:	00f68023          	sb	a5,0(a3)
        for (char *s = argv[i]; *s && pos < (int)sizeof(text) - 1; s++)
  8c:	0705                	addi	a4,a4,1
  8e:	00074783          	lbu	a5,0(a4)
  92:	d3f9                	beqz	a5,58 <main+0x58>
  94:	0685                	addi	a3,a3,1
  96:	fec998e3          	bne	s3,a2,86 <main+0x86>
    }
    text[pos] = '\0';
  9a:	f9040793          	addi	a5,s0,-112
  9e:	97ce                	add	a5,a5,s3
  a0:	f0078023          	sb	zero,-256(a5)
    int max_chars = SCREEN_W / char_w;
    if (pos > max_chars)
        pos = max_chars;

    // Allocate a page-aligned framebuffer (FB_BYTES = 300 × PGSIZE).
    uint32 *fb = (uint32 *)sbrk(FB_BYTES);
  a4:	0012c537          	lui	a0,0x12c
  a8:	00000097          	auipc	ra,0x0
  ac:	4c2080e7          	jalr	1218(ra) # 56a <sbrk>
  b0:	84aa                	mv	s1,a0
    if (fb == (uint32 *)-1)
  b2:	57fd                	li	a5,-1
  b4:	08f50c63          	beq	a0,a5,14c <main+0x14c>
  b8:	8a4e                	mv	s4,s3
  ba:	47d1                	li	a5,20
  bc:	0137d363          	bge	a5,s3,c2 <main+0xc2>
  c0:	4a51                	li	s4,20
  c2:	000a091b          	sext.w	s2,s4
        fprintf(2, "show_flip: sbrk failed\n");
        exit(1);
    }

    // Clear to background.
    memset(fb, 0, FB_BYTES);
  c6:	0012c637          	lui	a2,0x12c
  ca:	4581                	li	a1,0
  cc:	8526                	mv	a0,s1
  ce:	00000097          	auipc	ra,0x0
  d2:	218080e7          	jalr	536(ra) # 2e6 <memset>

    // Render text centred on screen.
    int text_w = pos * char_w;
  d6:	005a179b          	slliw	a5,s4,0x5
    int x0 = (SCREEN_W - text_w) / 2;
  da:	28000a13          	li	s4,640
  de:	40fa0a3b          	subw	s4,s4,a5
  e2:	4789                	li	a5,2
  e4:	02fa4a3b          	divw	s4,s4,a5
    int y0 = (SCREEN_H - char_h) / 2;
    for (int i = 0; i < pos; i++)
  e8:	11305563          	blez	s3,1f2 <main+0x1f2>
  ec:	e9040d13          	addi	s10,s0,-368
  f0:	4c81                	li	s9,0
  f2:	0008cc37          	lui	s8,0x8c
  f6:	9c26                	add	s8,s8,s1
    const uint8 *rows = font8x8[ch];
  f8:	00001d97          	auipc	s11,0x1
  fc:	970d8d93          	addi	s11,s11,-1680 # a68 <font8x8>
 100:	000247b7          	lui	a5,0x24
 104:	a0078793          	addi	a5,a5,-1536 # 23a00 <base+0x229f0>
 108:	e8f43423          	sd	a5,-376(s0)
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 10c:	010002b7          	lui	t0,0x1000
 110:	12fd                	addi	t0,t0,-1
 112:	4311                	li	t1,4
            for (int dy = 0; dy < SCALE; dy++)
 114:	6805                	lui	a6,0x1
 116:	a0080813          	addi	a6,a6,-1536 # a00 <malloc+0xd8>
        for (int col = 0; col < 8; col++)
 11a:	4fa1                	li	t6,8
    for (int row = 0; row < 8; row++)
 11c:	6b05                	lui	s6,0x1
 11e:	a00b0b1b          	addiw	s6,s6,-1536
 122:	6a8d                	lui	s5,0x3
 124:	800a8a93          	addi	s5,s5,-2048 # 2800 <base+0x17f0>
 128:	10000b93          	li	s7,256
 12c:	a871                	j	1c8 <main+0x1c8>
    text[pos] = '\0';
 12e:	f9040793          	addi	a5,s0,-112
 132:	97ce                	add	a5,a5,s3
 134:	f0078023          	sb	zero,-256(a5)
    uint32 *fb = (uint32 *)sbrk(FB_BYTES);
 138:	0012c537          	lui	a0,0x12c
 13c:	00000097          	auipc	ra,0x0
 140:	42e080e7          	jalr	1070(ra) # 56a <sbrk>
 144:	84aa                	mv	s1,a0
    if (fb == (uint32 *)-1)
 146:	57fd                	li	a5,-1
 148:	0ef51063          	bne	a0,a5,228 <main+0x228>
        fprintf(2, "show_flip: sbrk failed\n");
 14c:	00001597          	auipc	a1,0x1
 150:	8e458593          	addi	a1,a1,-1820 # a30 <malloc+0x108>
 154:	4509                	li	a0,2
 156:	00000097          	auipc	ra,0x0
 15a:	6e6080e7          	jalr	1766(ra) # 83c <fprintf>
        exit(1);
 15e:	4505                	li	a0,1
 160:	00000097          	auipc	ra,0x0
 164:	382080e7          	jalr	898(ra) # 4e2 <exit>
        ch = '?';
 168:	03f00793          	li	a5,63
 16c:	a0b5                	j	1d8 <main+0x1d8>
            for (int dy = 0; dy < SCALE; dy++)
 16e:	9642                	add	a2,a2,a6
 170:	2805859b          	addiw	a1,a1,640
 174:	00a58963          	beq	a1,a0,186 <main+0x186>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 178:	8732                	mv	a4,a2
 17a:	879a                	mv	a5,t1
    fb[y * SCREEN_W + x] = color;
 17c:	c314                	sw	a3,0(a4)
                for (int dx = 0; dx < SCALE; dx++)
 17e:	37fd                	addiw	a5,a5,-1
 180:	0711                	addi	a4,a4,4
 182:	ffed                	bnez	a5,17c <main+0x17c>
 184:	b7ed                	j	16e <main+0x16e>
        for (int col = 0; col < 8; col++)
 186:	2885                	addiw	a7,a7,1
 188:	0e41                	addi	t3,t3,16
 18a:	01f88c63          	beq	a7,t6,1a2 <main+0x1a2>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 18e:	000ec683          	lbu	a3,0(t4)
 192:	0116d6bb          	srlw	a3,a3,a7
 196:	8a85                	andi	a3,a3,1
 198:	c291                	beqz	a3,19c <main+0x19c>
 19a:	8696                	mv	a3,t0
            for (int dy = 0; dy < SCALE; dy++)
 19c:	85fa                	mv	a1,t5
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 19e:	8672                	mv	a2,t3
 1a0:	bfe1                	j	178 <main+0x178>
    for (int row = 0; row < 8; row++)
 1a2:	00ab053b          	addw	a0,s6,a0
 1a6:	2091                	addiw	ra,ra,4
 1a8:	99c2                	add	s3,s3,a6
 1aa:	93d6                	add	t2,t2,s5
 1ac:	0e85                	addi	t4,t4,1
 1ae:	01708763          	beq	ra,s7,1bc <main+0x1bc>
        ch = '?';
 1b2:	8e1e                	mv	t3,t2
        for (int col = 0; col < 8; col++)
 1b4:	4881                	li	a7,0
 1b6:	00098f1b          	sext.w	t5,s3
 1ba:	bfd1                	j	18e <main+0x18e>
    for (int i = 0; i < pos; i++)
 1bc:	2c85                	addiw	s9,s9,1
 1be:	0d05                	addi	s10,s10,1
 1c0:	020a0a13          	addi	s4,s4,32
 1c4:	032cd763          	bge	s9,s2,1f2 <main+0x1f2>
        draw_char(fb, x0 + i * char_w, y0, (unsigned char)text[i]);
 1c8:	000d4783          	lbu	a5,0(s10)
    if (ch >= 128)
 1cc:	0187971b          	slliw	a4,a5,0x18
 1d0:	4187571b          	sraiw	a4,a4,0x18
 1d4:	f8074ae3          	bltz	a4,168 <main+0x168>
    for (int row = 0; row < 8; row++)
 1d8:	002a1393          	slli	t2,s4,0x2
 1dc:	93e2                	add	t2,t2,s8
    const uint8 *rows = font8x8[ch];
 1de:	078e                	slli	a5,a5,0x3
 1e0:	00fd8eb3          	add	t4,s11,a5
 1e4:	000239b7          	lui	s3,0x23
 1e8:	0e000093          	li	ra,224
 1ec:	e8843503          	ld	a0,-376(s0)
 1f0:	b7c9                	j	1b2 <main+0x1b2>

    // Zero-copy flip: the kernel re-points the GPU resource's backing
    // pages to fb's physical pages; no pixel data is copied.
    if (flip_display(fb) < 0)
 1f2:	8526                	mv	a0,s1
 1f4:	00000097          	auipc	ra,0x0
 1f8:	38e080e7          	jalr	910(ra) # 582 <flip_display>
 1fc:	00054863          	bltz	a0,20c <main+0x20c>
    {
        fprintf(2, "show_flip: flip_display failed\n");
        exit(1);
    }
    for(;;) {
        sleep(10);
 200:	4529                	li	a0,10
 202:	00000097          	auipc	ra,0x0
 206:	370080e7          	jalr	880(ra) # 572 <sleep>
    for(;;) {
 20a:	bfdd                	j	200 <main+0x200>
        fprintf(2, "show_flip: flip_display failed\n");
 20c:	00001597          	auipc	a1,0x1
 210:	83c58593          	addi	a1,a1,-1988 # a48 <malloc+0x120>
 214:	4509                	li	a0,2
 216:	00000097          	auipc	ra,0x0
 21a:	626080e7          	jalr	1574(ra) # 83c <fprintf>
        exit(1);
 21e:	4505                	li	a0,1
 220:	00000097          	auipc	ra,0x0
 224:	2c2080e7          	jalr	706(ra) # 4e2 <exit>
 228:	8a4e                	mv	s4,s3
 22a:	47d1                	li	a5,20
 22c:	0137d363          	bge	a5,s3,232 <main+0x232>
 230:	4a51                	li	s4,20
 232:	000a091b          	sext.w	s2,s4
    memset(fb, 0, FB_BYTES);
 236:	0012c637          	lui	a2,0x12c
 23a:	4581                	li	a1,0
 23c:	8526                	mv	a0,s1
 23e:	00000097          	auipc	ra,0x0
 242:	0a8080e7          	jalr	168(ra) # 2e6 <memset>
    int text_w = pos * char_w;
 246:	005a179b          	slliw	a5,s4,0x5
    int x0 = (SCREEN_W - text_w) / 2;
 24a:	28000a13          	li	s4,640
 24e:	40fa0a3b          	subw	s4,s4,a5
 252:	4789                	li	a5,2
 254:	02fa4a3b          	divw	s4,s4,a5
    for (int i = 0; i < pos; i++)
 258:	bd51                	j	ec <main+0xec>

000000000000025a <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 25a:	1141                	addi	sp,sp,-16
 25c:	e406                	sd	ra,8(sp)
 25e:	e022                	sd	s0,0(sp)
 260:	0800                	addi	s0,sp,16
  extern int main();
  main();
 262:	00000097          	auipc	ra,0x0
 266:	d9e080e7          	jalr	-610(ra) # 0 <main>
  exit(0);
 26a:	4501                	li	a0,0
 26c:	00000097          	auipc	ra,0x0
 270:	276080e7          	jalr	630(ra) # 4e2 <exit>

0000000000000274 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 274:	1141                	addi	sp,sp,-16
 276:	e422                	sd	s0,8(sp)
 278:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 27a:	87aa                	mv	a5,a0
 27c:	0585                	addi	a1,a1,1
 27e:	0785                	addi	a5,a5,1
 280:	fff5c703          	lbu	a4,-1(a1)
 284:	fee78fa3          	sb	a4,-1(a5)
 288:	fb75                	bnez	a4,27c <strcpy+0x8>
    ;
  return os;
}
 28a:	6422                	ld	s0,8(sp)
 28c:	0141                	addi	sp,sp,16
 28e:	8082                	ret

0000000000000290 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 290:	1141                	addi	sp,sp,-16
 292:	e422                	sd	s0,8(sp)
 294:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 296:	00054783          	lbu	a5,0(a0) # 12c000 <base+0x12aff0>
 29a:	cb91                	beqz	a5,2ae <strcmp+0x1e>
 29c:	0005c703          	lbu	a4,0(a1)
 2a0:	00f71763          	bne	a4,a5,2ae <strcmp+0x1e>
    p++, q++;
 2a4:	0505                	addi	a0,a0,1
 2a6:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2a8:	00054783          	lbu	a5,0(a0)
 2ac:	fbe5                	bnez	a5,29c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2ae:	0005c503          	lbu	a0,0(a1)
}
 2b2:	40a7853b          	subw	a0,a5,a0
 2b6:	6422                	ld	s0,8(sp)
 2b8:	0141                	addi	sp,sp,16
 2ba:	8082                	ret

00000000000002bc <strlen>:

uint
strlen(const char *s)
{
 2bc:	1141                	addi	sp,sp,-16
 2be:	e422                	sd	s0,8(sp)
 2c0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2c2:	00054783          	lbu	a5,0(a0)
 2c6:	cf91                	beqz	a5,2e2 <strlen+0x26>
 2c8:	0505                	addi	a0,a0,1
 2ca:	87aa                	mv	a5,a0
 2cc:	4685                	li	a3,1
 2ce:	9e89                	subw	a3,a3,a0
 2d0:	00f6853b          	addw	a0,a3,a5
 2d4:	0785                	addi	a5,a5,1
 2d6:	fff7c703          	lbu	a4,-1(a5)
 2da:	fb7d                	bnez	a4,2d0 <strlen+0x14>
    ;
  return n;
}
 2dc:	6422                	ld	s0,8(sp)
 2de:	0141                	addi	sp,sp,16
 2e0:	8082                	ret
  for(n = 0; s[n]; n++)
 2e2:	4501                	li	a0,0
 2e4:	bfe5                	j	2dc <strlen+0x20>

00000000000002e6 <memset>:

void*
memset(void *dst, int c, uint n)
{
 2e6:	1141                	addi	sp,sp,-16
 2e8:	e422                	sd	s0,8(sp)
 2ea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2ec:	ca19                	beqz	a2,302 <memset+0x1c>
 2ee:	87aa                	mv	a5,a0
 2f0:	1602                	slli	a2,a2,0x20
 2f2:	9201                	srli	a2,a2,0x20
 2f4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 2f8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 2fc:	0785                	addi	a5,a5,1
 2fe:	fee79de3          	bne	a5,a4,2f8 <memset+0x12>
  }
  return dst;
}
 302:	6422                	ld	s0,8(sp)
 304:	0141                	addi	sp,sp,16
 306:	8082                	ret

0000000000000308 <strchr>:

char*
strchr(const char *s, char c)
{
 308:	1141                	addi	sp,sp,-16
 30a:	e422                	sd	s0,8(sp)
 30c:	0800                	addi	s0,sp,16
  for(; *s; s++)
 30e:	00054783          	lbu	a5,0(a0)
 312:	cb99                	beqz	a5,328 <strchr+0x20>
    if(*s == c)
 314:	00f58763          	beq	a1,a5,322 <strchr+0x1a>
  for(; *s; s++)
 318:	0505                	addi	a0,a0,1
 31a:	00054783          	lbu	a5,0(a0)
 31e:	fbfd                	bnez	a5,314 <strchr+0xc>
      return (char*)s;
  return 0;
 320:	4501                	li	a0,0
}
 322:	6422                	ld	s0,8(sp)
 324:	0141                	addi	sp,sp,16
 326:	8082                	ret
  return 0;
 328:	4501                	li	a0,0
 32a:	bfe5                	j	322 <strchr+0x1a>

000000000000032c <gets>:

char*
gets(char *buf, int max)
{
 32c:	711d                	addi	sp,sp,-96
 32e:	ec86                	sd	ra,88(sp)
 330:	e8a2                	sd	s0,80(sp)
 332:	e4a6                	sd	s1,72(sp)
 334:	e0ca                	sd	s2,64(sp)
 336:	fc4e                	sd	s3,56(sp)
 338:	f852                	sd	s4,48(sp)
 33a:	f456                	sd	s5,40(sp)
 33c:	f05a                	sd	s6,32(sp)
 33e:	ec5e                	sd	s7,24(sp)
 340:	1080                	addi	s0,sp,96
 342:	8baa                	mv	s7,a0
 344:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 346:	892a                	mv	s2,a0
 348:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 34a:	4aa9                	li	s5,10
 34c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 34e:	89a6                	mv	s3,s1
 350:	2485                	addiw	s1,s1,1
 352:	0344d863          	bge	s1,s4,382 <gets+0x56>
    cc = read(0, &c, 1);
 356:	4605                	li	a2,1
 358:	faf40593          	addi	a1,s0,-81
 35c:	4501                	li	a0,0
 35e:	00000097          	auipc	ra,0x0
 362:	19c080e7          	jalr	412(ra) # 4fa <read>
    if(cc < 1)
 366:	00a05e63          	blez	a0,382 <gets+0x56>
    buf[i++] = c;
 36a:	faf44783          	lbu	a5,-81(s0)
 36e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 372:	01578763          	beq	a5,s5,380 <gets+0x54>
 376:	0905                	addi	s2,s2,1
 378:	fd679be3          	bne	a5,s6,34e <gets+0x22>
  for(i=0; i+1 < max; ){
 37c:	89a6                	mv	s3,s1
 37e:	a011                	j	382 <gets+0x56>
 380:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 382:	99de                	add	s3,s3,s7
 384:	00098023          	sb	zero,0(s3) # 23000 <base+0x21ff0>
  return buf;
}
 388:	855e                	mv	a0,s7
 38a:	60e6                	ld	ra,88(sp)
 38c:	6446                	ld	s0,80(sp)
 38e:	64a6                	ld	s1,72(sp)
 390:	6906                	ld	s2,64(sp)
 392:	79e2                	ld	s3,56(sp)
 394:	7a42                	ld	s4,48(sp)
 396:	7aa2                	ld	s5,40(sp)
 398:	7b02                	ld	s6,32(sp)
 39a:	6be2                	ld	s7,24(sp)
 39c:	6125                	addi	sp,sp,96
 39e:	8082                	ret

00000000000003a0 <stat>:

int
stat(const char *n, struct stat *st)
{
 3a0:	1101                	addi	sp,sp,-32
 3a2:	ec06                	sd	ra,24(sp)
 3a4:	e822                	sd	s0,16(sp)
 3a6:	e426                	sd	s1,8(sp)
 3a8:	e04a                	sd	s2,0(sp)
 3aa:	1000                	addi	s0,sp,32
 3ac:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3ae:	4581                	li	a1,0
 3b0:	00000097          	auipc	ra,0x0
 3b4:	172080e7          	jalr	370(ra) # 522 <open>
  if(fd < 0)
 3b8:	02054563          	bltz	a0,3e2 <stat+0x42>
 3bc:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3be:	85ca                	mv	a1,s2
 3c0:	00000097          	auipc	ra,0x0
 3c4:	17a080e7          	jalr	378(ra) # 53a <fstat>
 3c8:	892a                	mv	s2,a0
  close(fd);
 3ca:	8526                	mv	a0,s1
 3cc:	00000097          	auipc	ra,0x0
 3d0:	13e080e7          	jalr	318(ra) # 50a <close>
  return r;
}
 3d4:	854a                	mv	a0,s2
 3d6:	60e2                	ld	ra,24(sp)
 3d8:	6442                	ld	s0,16(sp)
 3da:	64a2                	ld	s1,8(sp)
 3dc:	6902                	ld	s2,0(sp)
 3de:	6105                	addi	sp,sp,32
 3e0:	8082                	ret
    return -1;
 3e2:	597d                	li	s2,-1
 3e4:	bfc5                	j	3d4 <stat+0x34>

00000000000003e6 <atoi>:

int
atoi(const char *s)
{
 3e6:	1141                	addi	sp,sp,-16
 3e8:	e422                	sd	s0,8(sp)
 3ea:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3ec:	00054603          	lbu	a2,0(a0)
 3f0:	fd06079b          	addiw	a5,a2,-48
 3f4:	0ff7f793          	andi	a5,a5,255
 3f8:	4725                	li	a4,9
 3fa:	02f76963          	bltu	a4,a5,42c <atoi+0x46>
 3fe:	86aa                	mv	a3,a0
  n = 0;
 400:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 402:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 404:	0685                	addi	a3,a3,1
 406:	0025179b          	slliw	a5,a0,0x2
 40a:	9fa9                	addw	a5,a5,a0
 40c:	0017979b          	slliw	a5,a5,0x1
 410:	9fb1                	addw	a5,a5,a2
 412:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 416:	0006c603          	lbu	a2,0(a3)
 41a:	fd06071b          	addiw	a4,a2,-48
 41e:	0ff77713          	andi	a4,a4,255
 422:	fee5f1e3          	bgeu	a1,a4,404 <atoi+0x1e>
  return n;
}
 426:	6422                	ld	s0,8(sp)
 428:	0141                	addi	sp,sp,16
 42a:	8082                	ret
  n = 0;
 42c:	4501                	li	a0,0
 42e:	bfe5                	j	426 <atoi+0x40>

0000000000000430 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 430:	1141                	addi	sp,sp,-16
 432:	e422                	sd	s0,8(sp)
 434:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 436:	02b57463          	bgeu	a0,a1,45e <memmove+0x2e>
    while(n-- > 0)
 43a:	00c05f63          	blez	a2,458 <memmove+0x28>
 43e:	1602                	slli	a2,a2,0x20
 440:	9201                	srli	a2,a2,0x20
 442:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 446:	872a                	mv	a4,a0
      *dst++ = *src++;
 448:	0585                	addi	a1,a1,1
 44a:	0705                	addi	a4,a4,1
 44c:	fff5c683          	lbu	a3,-1(a1)
 450:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 454:	fee79ae3          	bne	a5,a4,448 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 458:	6422                	ld	s0,8(sp)
 45a:	0141                	addi	sp,sp,16
 45c:	8082                	ret
    dst += n;
 45e:	00c50733          	add	a4,a0,a2
    src += n;
 462:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 464:	fec05ae3          	blez	a2,458 <memmove+0x28>
 468:	fff6079b          	addiw	a5,a2,-1
 46c:	1782                	slli	a5,a5,0x20
 46e:	9381                	srli	a5,a5,0x20
 470:	fff7c793          	not	a5,a5
 474:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 476:	15fd                	addi	a1,a1,-1
 478:	177d                	addi	a4,a4,-1
 47a:	0005c683          	lbu	a3,0(a1)
 47e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 482:	fee79ae3          	bne	a5,a4,476 <memmove+0x46>
 486:	bfc9                	j	458 <memmove+0x28>

0000000000000488 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 488:	1141                	addi	sp,sp,-16
 48a:	e422                	sd	s0,8(sp)
 48c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 48e:	ca05                	beqz	a2,4be <memcmp+0x36>
 490:	fff6069b          	addiw	a3,a2,-1
 494:	1682                	slli	a3,a3,0x20
 496:	9281                	srli	a3,a3,0x20
 498:	0685                	addi	a3,a3,1
 49a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 49c:	00054783          	lbu	a5,0(a0)
 4a0:	0005c703          	lbu	a4,0(a1)
 4a4:	00e79863          	bne	a5,a4,4b4 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4a8:	0505                	addi	a0,a0,1
    p2++;
 4aa:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4ac:	fed518e3          	bne	a0,a3,49c <memcmp+0x14>
  }
  return 0;
 4b0:	4501                	li	a0,0
 4b2:	a019                	j	4b8 <memcmp+0x30>
      return *p1 - *p2;
 4b4:	40e7853b          	subw	a0,a5,a4
}
 4b8:	6422                	ld	s0,8(sp)
 4ba:	0141                	addi	sp,sp,16
 4bc:	8082                	ret
  return 0;
 4be:	4501                	li	a0,0
 4c0:	bfe5                	j	4b8 <memcmp+0x30>

00000000000004c2 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4c2:	1141                	addi	sp,sp,-16
 4c4:	e406                	sd	ra,8(sp)
 4c6:	e022                	sd	s0,0(sp)
 4c8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4ca:	00000097          	auipc	ra,0x0
 4ce:	f66080e7          	jalr	-154(ra) # 430 <memmove>
}
 4d2:	60a2                	ld	ra,8(sp)
 4d4:	6402                	ld	s0,0(sp)
 4d6:	0141                	addi	sp,sp,16
 4d8:	8082                	ret

00000000000004da <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4da:	4885                	li	a7,1
 ecall
 4dc:	00000073          	ecall
 ret
 4e0:	8082                	ret

00000000000004e2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 4e2:	4889                	li	a7,2
 ecall
 4e4:	00000073          	ecall
 ret
 4e8:	8082                	ret

00000000000004ea <wait>:
.global wait
wait:
 li a7, SYS_wait
 4ea:	488d                	li	a7,3
 ecall
 4ec:	00000073          	ecall
 ret
 4f0:	8082                	ret

00000000000004f2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4f2:	4891                	li	a7,4
 ecall
 4f4:	00000073          	ecall
 ret
 4f8:	8082                	ret

00000000000004fa <read>:
.global read
read:
 li a7, SYS_read
 4fa:	4895                	li	a7,5
 ecall
 4fc:	00000073          	ecall
 ret
 500:	8082                	ret

0000000000000502 <write>:
.global write
write:
 li a7, SYS_write
 502:	48c1                	li	a7,16
 ecall
 504:	00000073          	ecall
 ret
 508:	8082                	ret

000000000000050a <close>:
.global close
close:
 li a7, SYS_close
 50a:	48d5                	li	a7,21
 ecall
 50c:	00000073          	ecall
 ret
 510:	8082                	ret

0000000000000512 <kill>:
.global kill
kill:
 li a7, SYS_kill
 512:	4899                	li	a7,6
 ecall
 514:	00000073          	ecall
 ret
 518:	8082                	ret

000000000000051a <exec>:
.global exec
exec:
 li a7, SYS_exec
 51a:	489d                	li	a7,7
 ecall
 51c:	00000073          	ecall
 ret
 520:	8082                	ret

0000000000000522 <open>:
.global open
open:
 li a7, SYS_open
 522:	48bd                	li	a7,15
 ecall
 524:	00000073          	ecall
 ret
 528:	8082                	ret

000000000000052a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 52a:	48c5                	li	a7,17
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 532:	48c9                	li	a7,18
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 53a:	48a1                	li	a7,8
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <link>:
.global link
link:
 li a7, SYS_link
 542:	48cd                	li	a7,19
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 54a:	48d1                	li	a7,20
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 552:	48a5                	li	a7,9
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <dup>:
.global dup
dup:
 li a7, SYS_dup
 55a:	48a9                	li	a7,10
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 562:	48ad                	li	a7,11
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 56a:	48b1                	li	a7,12
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 572:	48b5                	li	a7,13
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 57a:	48b9                	li	a7,14
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <flip_display>:
.global flip_display
flip_display:
 li a7, SYS_flip_display
 582:	48d9                	li	a7,22
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <map_display>:
.global map_display
map_display:
 li a7, SYS_map_display
 58a:	48dd                	li	a7,23
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 592:	1101                	addi	sp,sp,-32
 594:	ec06                	sd	ra,24(sp)
 596:	e822                	sd	s0,16(sp)
 598:	1000                	addi	s0,sp,32
 59a:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 59e:	4605                	li	a2,1
 5a0:	fef40593          	addi	a1,s0,-17
 5a4:	00000097          	auipc	ra,0x0
 5a8:	f5e080e7          	jalr	-162(ra) # 502 <write>
}
 5ac:	60e2                	ld	ra,24(sp)
 5ae:	6442                	ld	s0,16(sp)
 5b0:	6105                	addi	sp,sp,32
 5b2:	8082                	ret

00000000000005b4 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5b4:	7139                	addi	sp,sp,-64
 5b6:	fc06                	sd	ra,56(sp)
 5b8:	f822                	sd	s0,48(sp)
 5ba:	f426                	sd	s1,40(sp)
 5bc:	f04a                	sd	s2,32(sp)
 5be:	ec4e                	sd	s3,24(sp)
 5c0:	0080                	addi	s0,sp,64
 5c2:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5c4:	c299                	beqz	a3,5ca <printint+0x16>
 5c6:	0805c863          	bltz	a1,656 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5ca:	2581                	sext.w	a1,a1
  neg = 0;
 5cc:	4881                	li	a7,0
 5ce:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5d2:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5d4:	2601                	sext.w	a2,a2
 5d6:	00001517          	auipc	a0,0x1
 5da:	89a50513          	addi	a0,a0,-1894 # e70 <digits>
 5de:	883a                	mv	a6,a4
 5e0:	2705                	addiw	a4,a4,1
 5e2:	02c5f7bb          	remuw	a5,a1,a2
 5e6:	1782                	slli	a5,a5,0x20
 5e8:	9381                	srli	a5,a5,0x20
 5ea:	97aa                	add	a5,a5,a0
 5ec:	0007c783          	lbu	a5,0(a5)
 5f0:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5f4:	0005879b          	sext.w	a5,a1
 5f8:	02c5d5bb          	divuw	a1,a1,a2
 5fc:	0685                	addi	a3,a3,1
 5fe:	fec7f0e3          	bgeu	a5,a2,5de <printint+0x2a>
  if(neg)
 602:	00088b63          	beqz	a7,618 <printint+0x64>
    buf[i++] = '-';
 606:	fd040793          	addi	a5,s0,-48
 60a:	973e                	add	a4,a4,a5
 60c:	02d00793          	li	a5,45
 610:	fef70823          	sb	a5,-16(a4)
 614:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 618:	02e05863          	blez	a4,648 <printint+0x94>
 61c:	fc040793          	addi	a5,s0,-64
 620:	00e78933          	add	s2,a5,a4
 624:	fff78993          	addi	s3,a5,-1
 628:	99ba                	add	s3,s3,a4
 62a:	377d                	addiw	a4,a4,-1
 62c:	1702                	slli	a4,a4,0x20
 62e:	9301                	srli	a4,a4,0x20
 630:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 634:	fff94583          	lbu	a1,-1(s2)
 638:	8526                	mv	a0,s1
 63a:	00000097          	auipc	ra,0x0
 63e:	f58080e7          	jalr	-168(ra) # 592 <putc>
  while(--i >= 0)
 642:	197d                	addi	s2,s2,-1
 644:	ff3918e3          	bne	s2,s3,634 <printint+0x80>
}
 648:	70e2                	ld	ra,56(sp)
 64a:	7442                	ld	s0,48(sp)
 64c:	74a2                	ld	s1,40(sp)
 64e:	7902                	ld	s2,32(sp)
 650:	69e2                	ld	s3,24(sp)
 652:	6121                	addi	sp,sp,64
 654:	8082                	ret
    x = -xx;
 656:	40b005bb          	negw	a1,a1
    neg = 1;
 65a:	4885                	li	a7,1
    x = -xx;
 65c:	bf8d                	j	5ce <printint+0x1a>

000000000000065e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 65e:	7119                	addi	sp,sp,-128
 660:	fc86                	sd	ra,120(sp)
 662:	f8a2                	sd	s0,112(sp)
 664:	f4a6                	sd	s1,104(sp)
 666:	f0ca                	sd	s2,96(sp)
 668:	ecce                	sd	s3,88(sp)
 66a:	e8d2                	sd	s4,80(sp)
 66c:	e4d6                	sd	s5,72(sp)
 66e:	e0da                	sd	s6,64(sp)
 670:	fc5e                	sd	s7,56(sp)
 672:	f862                	sd	s8,48(sp)
 674:	f466                	sd	s9,40(sp)
 676:	f06a                	sd	s10,32(sp)
 678:	ec6e                	sd	s11,24(sp)
 67a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 67c:	0005c903          	lbu	s2,0(a1)
 680:	18090f63          	beqz	s2,81e <vprintf+0x1c0>
 684:	8aaa                	mv	s5,a0
 686:	8b32                	mv	s6,a2
 688:	00158493          	addi	s1,a1,1
  state = 0;
 68c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 68e:	02500a13          	li	s4,37
      if(c == 'd'){
 692:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 696:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 69a:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 69e:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6a2:	00000b97          	auipc	s7,0x0
 6a6:	7ceb8b93          	addi	s7,s7,1998 # e70 <digits>
 6aa:	a839                	j	6c8 <vprintf+0x6a>
        putc(fd, c);
 6ac:	85ca                	mv	a1,s2
 6ae:	8556                	mv	a0,s5
 6b0:	00000097          	auipc	ra,0x0
 6b4:	ee2080e7          	jalr	-286(ra) # 592 <putc>
 6b8:	a019                	j	6be <vprintf+0x60>
    } else if(state == '%'){
 6ba:	01498f63          	beq	s3,s4,6d8 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6be:	0485                	addi	s1,s1,1
 6c0:	fff4c903          	lbu	s2,-1(s1)
 6c4:	14090d63          	beqz	s2,81e <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6c8:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6cc:	fe0997e3          	bnez	s3,6ba <vprintf+0x5c>
      if(c == '%'){
 6d0:	fd479ee3          	bne	a5,s4,6ac <vprintf+0x4e>
        state = '%';
 6d4:	89be                	mv	s3,a5
 6d6:	b7e5                	j	6be <vprintf+0x60>
      if(c == 'd'){
 6d8:	05878063          	beq	a5,s8,718 <vprintf+0xba>
      } else if(c == 'l') {
 6dc:	05978c63          	beq	a5,s9,734 <vprintf+0xd6>
      } else if(c == 'x') {
 6e0:	07a78863          	beq	a5,s10,750 <vprintf+0xf2>
      } else if(c == 'p') {
 6e4:	09b78463          	beq	a5,s11,76c <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6e8:	07300713          	li	a4,115
 6ec:	0ce78663          	beq	a5,a4,7b8 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6f0:	06300713          	li	a4,99
 6f4:	0ee78e63          	beq	a5,a4,7f0 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 6f8:	11478863          	beq	a5,s4,808 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6fc:	85d2                	mv	a1,s4
 6fe:	8556                	mv	a0,s5
 700:	00000097          	auipc	ra,0x0
 704:	e92080e7          	jalr	-366(ra) # 592 <putc>
        putc(fd, c);
 708:	85ca                	mv	a1,s2
 70a:	8556                	mv	a0,s5
 70c:	00000097          	auipc	ra,0x0
 710:	e86080e7          	jalr	-378(ra) # 592 <putc>
      }
      state = 0;
 714:	4981                	li	s3,0
 716:	b765                	j	6be <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 718:	008b0913          	addi	s2,s6,8 # 1008 <freep+0x8>
 71c:	4685                	li	a3,1
 71e:	4629                	li	a2,10
 720:	000b2583          	lw	a1,0(s6)
 724:	8556                	mv	a0,s5
 726:	00000097          	auipc	ra,0x0
 72a:	e8e080e7          	jalr	-370(ra) # 5b4 <printint>
 72e:	8b4a                	mv	s6,s2
      state = 0;
 730:	4981                	li	s3,0
 732:	b771                	j	6be <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 734:	008b0913          	addi	s2,s6,8
 738:	4681                	li	a3,0
 73a:	4629                	li	a2,10
 73c:	000b2583          	lw	a1,0(s6)
 740:	8556                	mv	a0,s5
 742:	00000097          	auipc	ra,0x0
 746:	e72080e7          	jalr	-398(ra) # 5b4 <printint>
 74a:	8b4a                	mv	s6,s2
      state = 0;
 74c:	4981                	li	s3,0
 74e:	bf85                	j	6be <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 750:	008b0913          	addi	s2,s6,8
 754:	4681                	li	a3,0
 756:	4641                	li	a2,16
 758:	000b2583          	lw	a1,0(s6)
 75c:	8556                	mv	a0,s5
 75e:	00000097          	auipc	ra,0x0
 762:	e56080e7          	jalr	-426(ra) # 5b4 <printint>
 766:	8b4a                	mv	s6,s2
      state = 0;
 768:	4981                	li	s3,0
 76a:	bf91                	j	6be <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 76c:	008b0793          	addi	a5,s6,8
 770:	f8f43423          	sd	a5,-120(s0)
 774:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 778:	03000593          	li	a1,48
 77c:	8556                	mv	a0,s5
 77e:	00000097          	auipc	ra,0x0
 782:	e14080e7          	jalr	-492(ra) # 592 <putc>
  putc(fd, 'x');
 786:	85ea                	mv	a1,s10
 788:	8556                	mv	a0,s5
 78a:	00000097          	auipc	ra,0x0
 78e:	e08080e7          	jalr	-504(ra) # 592 <putc>
 792:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 794:	03c9d793          	srli	a5,s3,0x3c
 798:	97de                	add	a5,a5,s7
 79a:	0007c583          	lbu	a1,0(a5)
 79e:	8556                	mv	a0,s5
 7a0:	00000097          	auipc	ra,0x0
 7a4:	df2080e7          	jalr	-526(ra) # 592 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7a8:	0992                	slli	s3,s3,0x4
 7aa:	397d                	addiw	s2,s2,-1
 7ac:	fe0914e3          	bnez	s2,794 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7b0:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7b4:	4981                	li	s3,0
 7b6:	b721                	j	6be <vprintf+0x60>
        s = va_arg(ap, char*);
 7b8:	008b0993          	addi	s3,s6,8
 7bc:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7c0:	02090163          	beqz	s2,7e2 <vprintf+0x184>
        while(*s != 0){
 7c4:	00094583          	lbu	a1,0(s2)
 7c8:	c9a1                	beqz	a1,818 <vprintf+0x1ba>
          putc(fd, *s);
 7ca:	8556                	mv	a0,s5
 7cc:	00000097          	auipc	ra,0x0
 7d0:	dc6080e7          	jalr	-570(ra) # 592 <putc>
          s++;
 7d4:	0905                	addi	s2,s2,1
        while(*s != 0){
 7d6:	00094583          	lbu	a1,0(s2)
 7da:	f9e5                	bnez	a1,7ca <vprintf+0x16c>
        s = va_arg(ap, char*);
 7dc:	8b4e                	mv	s6,s3
      state = 0;
 7de:	4981                	li	s3,0
 7e0:	bdf9                	j	6be <vprintf+0x60>
          s = "(null)";
 7e2:	00000917          	auipc	s2,0x0
 7e6:	68690913          	addi	s2,s2,1670 # e68 <font8x8+0x400>
        while(*s != 0){
 7ea:	02800593          	li	a1,40
 7ee:	bff1                	j	7ca <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7f0:	008b0913          	addi	s2,s6,8
 7f4:	000b4583          	lbu	a1,0(s6)
 7f8:	8556                	mv	a0,s5
 7fa:	00000097          	auipc	ra,0x0
 7fe:	d98080e7          	jalr	-616(ra) # 592 <putc>
 802:	8b4a                	mv	s6,s2
      state = 0;
 804:	4981                	li	s3,0
 806:	bd65                	j	6be <vprintf+0x60>
        putc(fd, c);
 808:	85d2                	mv	a1,s4
 80a:	8556                	mv	a0,s5
 80c:	00000097          	auipc	ra,0x0
 810:	d86080e7          	jalr	-634(ra) # 592 <putc>
      state = 0;
 814:	4981                	li	s3,0
 816:	b565                	j	6be <vprintf+0x60>
        s = va_arg(ap, char*);
 818:	8b4e                	mv	s6,s3
      state = 0;
 81a:	4981                	li	s3,0
 81c:	b54d                	j	6be <vprintf+0x60>
    }
  }
}
 81e:	70e6                	ld	ra,120(sp)
 820:	7446                	ld	s0,112(sp)
 822:	74a6                	ld	s1,104(sp)
 824:	7906                	ld	s2,96(sp)
 826:	69e6                	ld	s3,88(sp)
 828:	6a46                	ld	s4,80(sp)
 82a:	6aa6                	ld	s5,72(sp)
 82c:	6b06                	ld	s6,64(sp)
 82e:	7be2                	ld	s7,56(sp)
 830:	7c42                	ld	s8,48(sp)
 832:	7ca2                	ld	s9,40(sp)
 834:	7d02                	ld	s10,32(sp)
 836:	6de2                	ld	s11,24(sp)
 838:	6109                	addi	sp,sp,128
 83a:	8082                	ret

000000000000083c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 83c:	715d                	addi	sp,sp,-80
 83e:	ec06                	sd	ra,24(sp)
 840:	e822                	sd	s0,16(sp)
 842:	1000                	addi	s0,sp,32
 844:	e010                	sd	a2,0(s0)
 846:	e414                	sd	a3,8(s0)
 848:	e818                	sd	a4,16(s0)
 84a:	ec1c                	sd	a5,24(s0)
 84c:	03043023          	sd	a6,32(s0)
 850:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 854:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 858:	8622                	mv	a2,s0
 85a:	00000097          	auipc	ra,0x0
 85e:	e04080e7          	jalr	-508(ra) # 65e <vprintf>
}
 862:	60e2                	ld	ra,24(sp)
 864:	6442                	ld	s0,16(sp)
 866:	6161                	addi	sp,sp,80
 868:	8082                	ret

000000000000086a <printf>:

void
printf(const char *fmt, ...)
{
 86a:	711d                	addi	sp,sp,-96
 86c:	ec06                	sd	ra,24(sp)
 86e:	e822                	sd	s0,16(sp)
 870:	1000                	addi	s0,sp,32
 872:	e40c                	sd	a1,8(s0)
 874:	e810                	sd	a2,16(s0)
 876:	ec14                	sd	a3,24(s0)
 878:	f018                	sd	a4,32(s0)
 87a:	f41c                	sd	a5,40(s0)
 87c:	03043823          	sd	a6,48(s0)
 880:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 884:	00840613          	addi	a2,s0,8
 888:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 88c:	85aa                	mv	a1,a0
 88e:	4505                	li	a0,1
 890:	00000097          	auipc	ra,0x0
 894:	dce080e7          	jalr	-562(ra) # 65e <vprintf>
}
 898:	60e2                	ld	ra,24(sp)
 89a:	6442                	ld	s0,16(sp)
 89c:	6125                	addi	sp,sp,96
 89e:	8082                	ret

00000000000008a0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8a0:	1141                	addi	sp,sp,-16
 8a2:	e422                	sd	s0,8(sp)
 8a4:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8a6:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8aa:	00000797          	auipc	a5,0x0
 8ae:	7567b783          	ld	a5,1878(a5) # 1000 <freep>
 8b2:	a805                	j	8e2 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8b4:	4618                	lw	a4,8(a2)
 8b6:	9db9                	addw	a1,a1,a4
 8b8:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8bc:	6398                	ld	a4,0(a5)
 8be:	6318                	ld	a4,0(a4)
 8c0:	fee53823          	sd	a4,-16(a0)
 8c4:	a091                	j	908 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8c6:	ff852703          	lw	a4,-8(a0)
 8ca:	9e39                	addw	a2,a2,a4
 8cc:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8ce:	ff053703          	ld	a4,-16(a0)
 8d2:	e398                	sd	a4,0(a5)
 8d4:	a099                	j	91a <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8d6:	6398                	ld	a4,0(a5)
 8d8:	00e7e463          	bltu	a5,a4,8e0 <free+0x40>
 8dc:	00e6ea63          	bltu	a3,a4,8f0 <free+0x50>
{
 8e0:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8e2:	fed7fae3          	bgeu	a5,a3,8d6 <free+0x36>
 8e6:	6398                	ld	a4,0(a5)
 8e8:	00e6e463          	bltu	a3,a4,8f0 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8ec:	fee7eae3          	bltu	a5,a4,8e0 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8f0:	ff852583          	lw	a1,-8(a0)
 8f4:	6390                	ld	a2,0(a5)
 8f6:	02059713          	slli	a4,a1,0x20
 8fa:	9301                	srli	a4,a4,0x20
 8fc:	0712                	slli	a4,a4,0x4
 8fe:	9736                	add	a4,a4,a3
 900:	fae60ae3          	beq	a2,a4,8b4 <free+0x14>
    bp->s.ptr = p->s.ptr;
 904:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 908:	4790                	lw	a2,8(a5)
 90a:	02061713          	slli	a4,a2,0x20
 90e:	9301                	srli	a4,a4,0x20
 910:	0712                	slli	a4,a4,0x4
 912:	973e                	add	a4,a4,a5
 914:	fae689e3          	beq	a3,a4,8c6 <free+0x26>
  } else
    p->s.ptr = bp;
 918:	e394                	sd	a3,0(a5)
  freep = p;
 91a:	00000717          	auipc	a4,0x0
 91e:	6ef73323          	sd	a5,1766(a4) # 1000 <freep>
}
 922:	6422                	ld	s0,8(sp)
 924:	0141                	addi	sp,sp,16
 926:	8082                	ret

0000000000000928 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 928:	7139                	addi	sp,sp,-64
 92a:	fc06                	sd	ra,56(sp)
 92c:	f822                	sd	s0,48(sp)
 92e:	f426                	sd	s1,40(sp)
 930:	f04a                	sd	s2,32(sp)
 932:	ec4e                	sd	s3,24(sp)
 934:	e852                	sd	s4,16(sp)
 936:	e456                	sd	s5,8(sp)
 938:	e05a                	sd	s6,0(sp)
 93a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 93c:	02051493          	slli	s1,a0,0x20
 940:	9081                	srli	s1,s1,0x20
 942:	04bd                	addi	s1,s1,15
 944:	8091                	srli	s1,s1,0x4
 946:	0014899b          	addiw	s3,s1,1
 94a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 94c:	00000517          	auipc	a0,0x0
 950:	6b453503          	ld	a0,1716(a0) # 1000 <freep>
 954:	c515                	beqz	a0,980 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 956:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 958:	4798                	lw	a4,8(a5)
 95a:	02977f63          	bgeu	a4,s1,998 <malloc+0x70>
 95e:	8a4e                	mv	s4,s3
 960:	0009871b          	sext.w	a4,s3
 964:	6685                	lui	a3,0x1
 966:	00d77363          	bgeu	a4,a3,96c <malloc+0x44>
 96a:	6a05                	lui	s4,0x1
 96c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 970:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 974:	00000917          	auipc	s2,0x0
 978:	68c90913          	addi	s2,s2,1676 # 1000 <freep>
  if(p == (char*)-1)
 97c:	5afd                	li	s5,-1
 97e:	a88d                	j	9f0 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 980:	00000797          	auipc	a5,0x0
 984:	69078793          	addi	a5,a5,1680 # 1010 <base>
 988:	00000717          	auipc	a4,0x0
 98c:	66f73c23          	sd	a5,1656(a4) # 1000 <freep>
 990:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 992:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 996:	b7e1                	j	95e <malloc+0x36>
      if(p->s.size == nunits)
 998:	02e48b63          	beq	s1,a4,9ce <malloc+0xa6>
        p->s.size -= nunits;
 99c:	4137073b          	subw	a4,a4,s3
 9a0:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9a2:	1702                	slli	a4,a4,0x20
 9a4:	9301                	srli	a4,a4,0x20
 9a6:	0712                	slli	a4,a4,0x4
 9a8:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9aa:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9ae:	00000717          	auipc	a4,0x0
 9b2:	64a73923          	sd	a0,1618(a4) # 1000 <freep>
      return (void*)(p + 1);
 9b6:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9ba:	70e2                	ld	ra,56(sp)
 9bc:	7442                	ld	s0,48(sp)
 9be:	74a2                	ld	s1,40(sp)
 9c0:	7902                	ld	s2,32(sp)
 9c2:	69e2                	ld	s3,24(sp)
 9c4:	6a42                	ld	s4,16(sp)
 9c6:	6aa2                	ld	s5,8(sp)
 9c8:	6b02                	ld	s6,0(sp)
 9ca:	6121                	addi	sp,sp,64
 9cc:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9ce:	6398                	ld	a4,0(a5)
 9d0:	e118                	sd	a4,0(a0)
 9d2:	bff1                	j	9ae <malloc+0x86>
  hp->s.size = nu;
 9d4:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9d8:	0541                	addi	a0,a0,16
 9da:	00000097          	auipc	ra,0x0
 9de:	ec6080e7          	jalr	-314(ra) # 8a0 <free>
  return freep;
 9e2:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9e6:	d971                	beqz	a0,9ba <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9e8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9ea:	4798                	lw	a4,8(a5)
 9ec:	fa9776e3          	bgeu	a4,s1,998 <malloc+0x70>
    if(p == freep)
 9f0:	00093703          	ld	a4,0(s2)
 9f4:	853e                	mv	a0,a5
 9f6:	fef719e3          	bne	a4,a5,9e8 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 9fa:	8552                	mv	a0,s4
 9fc:	00000097          	auipc	ra,0x0
 a00:	b6e080e7          	jalr	-1170(ra) # 56a <sbrk>
  if(p == (char*)-1)
 a04:	fd5518e3          	bne	a0,s5,9d4 <malloc+0xac>
        return 0;
 a08:	4501                	li	a0,0
 a0a:	bf45                	j	9ba <malloc+0x92>
