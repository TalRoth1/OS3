
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
  40:	a0458593          	addi	a1,a1,-1532 # a40 <malloc+0xf0>
  44:	4509                	li	a0,2
  46:	00001097          	auipc	ra,0x1
  4a:	81e080e7          	jalr	-2018(ra) # 864 <fprintf>
        exit(1);
  4e:	4505                	li	a0,1
  50:	00000097          	auipc	ra,0x0
  54:	4ba080e7          	jalr	1210(ra) # 50a <exit>
    for (int i = 1; i < argc && pos < (int)sizeof(text) - 1; i++)
  58:	2505                	addiw	a0,a0,1
  5a:	04a80063          	beq	a6,a0,9a <main+0x9a>
  5e:	0f38c263          	blt	a7,s3,142 <main+0x142>
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
    printf("show_flip: displaying \"%s\"\n", text);
  a4:	e9040593          	addi	a1,s0,-368
  a8:	00001517          	auipc	a0,0x1
  ac:	9b850513          	addi	a0,a0,-1608 # a60 <malloc+0x110>
  b0:	00000097          	auipc	ra,0x0
  b4:	7e2080e7          	jalr	2018(ra) # 892 <printf>
    int max_chars = SCREEN_W / char_w;
    if (pos > max_chars)
        pos = max_chars;

    // Allocate a page-aligned framebuffer (FB_BYTES = 300 × PGSIZE).
    uint32 *fb = (uint32 *)sbrk(FB_BYTES);
  b8:	0012c537          	lui	a0,0x12c
  bc:	00000097          	auipc	ra,0x0
  c0:	4d6080e7          	jalr	1238(ra) # 592 <sbrk>
  c4:	84aa                	mv	s1,a0
    if (fb == (uint32 *)-1)
  c6:	57fd                	li	a5,-1
  c8:	0af50663          	beq	a0,a5,174 <main+0x174>
  cc:	8a4e                	mv	s4,s3
  ce:	47d1                	li	a5,20
  d0:	0137d363          	bge	a5,s3,d6 <main+0xd6>
  d4:	4a51                	li	s4,20
  d6:	000a091b          	sext.w	s2,s4
        fprintf(2, "show_flip: sbrk failed\n");
        exit(1);
    }

    // Clear to background.
    memset(fb, 0, FB_BYTES);
  da:	0012c637          	lui	a2,0x12c
  de:	4581                	li	a1,0
  e0:	8526                	mv	a0,s1
  e2:	00000097          	auipc	ra,0x0
  e6:	22c080e7          	jalr	556(ra) # 30e <memset>

    // Render text centred on screen.
    int text_w = pos * char_w;
  ea:	005a179b          	slliw	a5,s4,0x5
    int x0 = (SCREEN_W - text_w) / 2;
  ee:	28000a13          	li	s4,640
  f2:	40fa0a3b          	subw	s4,s4,a5
  f6:	4789                	li	a5,2
  f8:	02fa4a3b          	divw	s4,s4,a5
    int y0 = (SCREEN_H - char_h) / 2;
    for (int i = 0; i < pos; i++)
  fc:	11305f63          	blez	s3,21a <main+0x21a>
 100:	e9040d13          	addi	s10,s0,-368
 104:	4c81                	li	s9,0
 106:	0008cc37          	lui	s8,0x8c
 10a:	9c26                	add	s8,s8,s1
    const uint8 *rows = font8x8[ch];
 10c:	00001d97          	auipc	s11,0x1
 110:	9acd8d93          	addi	s11,s11,-1620 # ab8 <font8x8>
 114:	000247b7          	lui	a5,0x24
 118:	a0078793          	addi	a5,a5,-1536 # 23a00 <base+0x229f0>
 11c:	e8f43423          	sd	a5,-376(s0)
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 120:	010002b7          	lui	t0,0x1000
 124:	12fd                	addi	t0,t0,-1
 126:	4311                	li	t1,4
            for (int dy = 0; dy < SCALE; dy++)
 128:	6805                	lui	a6,0x1
 12a:	a0080813          	addi	a6,a6,-1536 # a00 <malloc+0xb0>
        for (int col = 0; col < 8; col++)
 12e:	4fa1                	li	t6,8
    for (int row = 0; row < 8; row++)
 130:	6b05                	lui	s6,0x1
 132:	a00b0b1b          	addiw	s6,s6,-1536
 136:	6a8d                	lui	s5,0x3
 138:	800a8a93          	addi	s5,s5,-2048 # 2800 <base+0x17f0>
 13c:	10000b93          	li	s7,256
 140:	a845                	j	1f0 <main+0x1f0>
    text[pos] = '\0';
 142:	f9040793          	addi	a5,s0,-112
 146:	97ce                	add	a5,a5,s3
 148:	f0078023          	sb	zero,-256(a5)
    printf("show_flip: displaying \"%s\"\n", text);
 14c:	e9040593          	addi	a1,s0,-368
 150:	00001517          	auipc	a0,0x1
 154:	91050513          	addi	a0,a0,-1776 # a60 <malloc+0x110>
 158:	00000097          	auipc	ra,0x0
 15c:	73a080e7          	jalr	1850(ra) # 892 <printf>
    uint32 *fb = (uint32 *)sbrk(FB_BYTES);
 160:	0012c537          	lui	a0,0x12c
 164:	00000097          	auipc	ra,0x0
 168:	42e080e7          	jalr	1070(ra) # 592 <sbrk>
 16c:	84aa                	mv	s1,a0
    if (fb == (uint32 *)-1)
 16e:	57fd                	li	a5,-1
 170:	0ef51063          	bne	a0,a5,250 <main+0x250>
        fprintf(2, "show_flip: sbrk failed\n");
 174:	00001597          	auipc	a1,0x1
 178:	90c58593          	addi	a1,a1,-1780 # a80 <malloc+0x130>
 17c:	4509                	li	a0,2
 17e:	00000097          	auipc	ra,0x0
 182:	6e6080e7          	jalr	1766(ra) # 864 <fprintf>
        exit(1);
 186:	4505                	li	a0,1
 188:	00000097          	auipc	ra,0x0
 18c:	382080e7          	jalr	898(ra) # 50a <exit>
        ch = '?';
 190:	03f00793          	li	a5,63
 194:	a0b5                	j	200 <main+0x200>
            for (int dy = 0; dy < SCALE; dy++)
 196:	9642                	add	a2,a2,a6
 198:	2805859b          	addiw	a1,a1,640
 19c:	00a58963          	beq	a1,a0,1ae <main+0x1ae>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 1a0:	8732                	mv	a4,a2
 1a2:	879a                	mv	a5,t1
    fb[y * SCREEN_W + x] = color;
 1a4:	c314                	sw	a3,0(a4)
                for (int dx = 0; dx < SCALE; dx++)
 1a6:	37fd                	addiw	a5,a5,-1
 1a8:	0711                	addi	a4,a4,4
 1aa:	ffed                	bnez	a5,1a4 <main+0x1a4>
 1ac:	b7ed                	j	196 <main+0x196>
        for (int col = 0; col < 8; col++)
 1ae:	2885                	addiw	a7,a7,1
 1b0:	0e41                	addi	t3,t3,16
 1b2:	01f88c63          	beq	a7,t6,1ca <main+0x1ca>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 1b6:	000ec683          	lbu	a3,0(t4)
 1ba:	0116d6bb          	srlw	a3,a3,a7
 1be:	8a85                	andi	a3,a3,1
 1c0:	c291                	beqz	a3,1c4 <main+0x1c4>
 1c2:	8696                	mv	a3,t0
            for (int dy = 0; dy < SCALE; dy++)
 1c4:	85fa                	mv	a1,t5
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 1c6:	8672                	mv	a2,t3
 1c8:	bfe1                	j	1a0 <main+0x1a0>
    for (int row = 0; row < 8; row++)
 1ca:	00ab053b          	addw	a0,s6,a0
 1ce:	2091                	addiw	ra,ra,4
 1d0:	99c2                	add	s3,s3,a6
 1d2:	93d6                	add	t2,t2,s5
 1d4:	0e85                	addi	t4,t4,1
 1d6:	01708763          	beq	ra,s7,1e4 <main+0x1e4>
        ch = '?';
 1da:	8e1e                	mv	t3,t2
        for (int col = 0; col < 8; col++)
 1dc:	4881                	li	a7,0
 1de:	00098f1b          	sext.w	t5,s3
 1e2:	bfd1                	j	1b6 <main+0x1b6>
    for (int i = 0; i < pos; i++)
 1e4:	2c85                	addiw	s9,s9,1
 1e6:	0d05                	addi	s10,s10,1
 1e8:	020a0a13          	addi	s4,s4,32
 1ec:	032cd763          	bge	s9,s2,21a <main+0x21a>
        draw_char(fb, x0 + i * char_w, y0, (unsigned char)text[i]);
 1f0:	000d4783          	lbu	a5,0(s10)
    if (ch >= 128)
 1f4:	0187971b          	slliw	a4,a5,0x18
 1f8:	4187571b          	sraiw	a4,a4,0x18
 1fc:	f8074ae3          	bltz	a4,190 <main+0x190>
    for (int row = 0; row < 8; row++)
 200:	002a1393          	slli	t2,s4,0x2
 204:	93e2                	add	t2,t2,s8
    const uint8 *rows = font8x8[ch];
 206:	078e                	slli	a5,a5,0x3
 208:	00fd8eb3          	add	t4,s11,a5
 20c:	000239b7          	lui	s3,0x23
 210:	0e000093          	li	ra,224
 214:	e8843503          	ld	a0,-376(s0)
 218:	b7c9                	j	1da <main+0x1da>

    // Zero-copy flip: the kernel re-points the GPU resource's backing
    // pages to fb's physical pages; no pixel data is copied.
    if (flip_display(fb) < 0)
 21a:	8526                	mv	a0,s1
 21c:	00000097          	auipc	ra,0x0
 220:	38e080e7          	jalr	910(ra) # 5aa <flip_display>
 224:	00054863          	bltz	a0,234 <main+0x234>
    {
        fprintf(2, "show_flip: flip_display failed\n");
        exit(1);
    }
    for(;;) {
        sleep(10);
 228:	4529                	li	a0,10
 22a:	00000097          	auipc	ra,0x0
 22e:	370080e7          	jalr	880(ra) # 59a <sleep>
    for(;;) {
 232:	bfdd                	j	228 <main+0x228>
        fprintf(2, "show_flip: flip_display failed\n");
 234:	00001597          	auipc	a1,0x1
 238:	86458593          	addi	a1,a1,-1948 # a98 <malloc+0x148>
 23c:	4509                	li	a0,2
 23e:	00000097          	auipc	ra,0x0
 242:	626080e7          	jalr	1574(ra) # 864 <fprintf>
        exit(1);
 246:	4505                	li	a0,1
 248:	00000097          	auipc	ra,0x0
 24c:	2c2080e7          	jalr	706(ra) # 50a <exit>
 250:	8a4e                	mv	s4,s3
 252:	47d1                	li	a5,20
 254:	0137d363          	bge	a5,s3,25a <main+0x25a>
 258:	4a51                	li	s4,20
 25a:	000a091b          	sext.w	s2,s4
    memset(fb, 0, FB_BYTES);
 25e:	0012c637          	lui	a2,0x12c
 262:	4581                	li	a1,0
 264:	8526                	mv	a0,s1
 266:	00000097          	auipc	ra,0x0
 26a:	0a8080e7          	jalr	168(ra) # 30e <memset>
    int text_w = pos * char_w;
 26e:	005a179b          	slliw	a5,s4,0x5
    int x0 = (SCREEN_W - text_w) / 2;
 272:	28000a13          	li	s4,640
 276:	40fa0a3b          	subw	s4,s4,a5
 27a:	4789                	li	a5,2
 27c:	02fa4a3b          	divw	s4,s4,a5
    for (int i = 0; i < pos; i++)
 280:	b541                	j	100 <main+0x100>

0000000000000282 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 282:	1141                	addi	sp,sp,-16
 284:	e406                	sd	ra,8(sp)
 286:	e022                	sd	s0,0(sp)
 288:	0800                	addi	s0,sp,16
  extern int main();
  main();
 28a:	00000097          	auipc	ra,0x0
 28e:	d76080e7          	jalr	-650(ra) # 0 <main>
  exit(0);
 292:	4501                	li	a0,0
 294:	00000097          	auipc	ra,0x0
 298:	276080e7          	jalr	630(ra) # 50a <exit>

000000000000029c <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 29c:	1141                	addi	sp,sp,-16
 29e:	e422                	sd	s0,8(sp)
 2a0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2a2:	87aa                	mv	a5,a0
 2a4:	0585                	addi	a1,a1,1
 2a6:	0785                	addi	a5,a5,1
 2a8:	fff5c703          	lbu	a4,-1(a1)
 2ac:	fee78fa3          	sb	a4,-1(a5)
 2b0:	fb75                	bnez	a4,2a4 <strcpy+0x8>
    ;
  return os;
}
 2b2:	6422                	ld	s0,8(sp)
 2b4:	0141                	addi	sp,sp,16
 2b6:	8082                	ret

00000000000002b8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2b8:	1141                	addi	sp,sp,-16
 2ba:	e422                	sd	s0,8(sp)
 2bc:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2be:	00054783          	lbu	a5,0(a0) # 12c000 <base+0x12aff0>
 2c2:	cb91                	beqz	a5,2d6 <strcmp+0x1e>
 2c4:	0005c703          	lbu	a4,0(a1)
 2c8:	00f71763          	bne	a4,a5,2d6 <strcmp+0x1e>
    p++, q++;
 2cc:	0505                	addi	a0,a0,1
 2ce:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2d0:	00054783          	lbu	a5,0(a0)
 2d4:	fbe5                	bnez	a5,2c4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2d6:	0005c503          	lbu	a0,0(a1)
}
 2da:	40a7853b          	subw	a0,a5,a0
 2de:	6422                	ld	s0,8(sp)
 2e0:	0141                	addi	sp,sp,16
 2e2:	8082                	ret

00000000000002e4 <strlen>:

uint
strlen(const char *s)
{
 2e4:	1141                	addi	sp,sp,-16
 2e6:	e422                	sd	s0,8(sp)
 2e8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2ea:	00054783          	lbu	a5,0(a0)
 2ee:	cf91                	beqz	a5,30a <strlen+0x26>
 2f0:	0505                	addi	a0,a0,1
 2f2:	87aa                	mv	a5,a0
 2f4:	4685                	li	a3,1
 2f6:	9e89                	subw	a3,a3,a0
 2f8:	00f6853b          	addw	a0,a3,a5
 2fc:	0785                	addi	a5,a5,1
 2fe:	fff7c703          	lbu	a4,-1(a5)
 302:	fb7d                	bnez	a4,2f8 <strlen+0x14>
    ;
  return n;
}
 304:	6422                	ld	s0,8(sp)
 306:	0141                	addi	sp,sp,16
 308:	8082                	ret
  for(n = 0; s[n]; n++)
 30a:	4501                	li	a0,0
 30c:	bfe5                	j	304 <strlen+0x20>

000000000000030e <memset>:

void*
memset(void *dst, int c, uint n)
{
 30e:	1141                	addi	sp,sp,-16
 310:	e422                	sd	s0,8(sp)
 312:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 314:	ca19                	beqz	a2,32a <memset+0x1c>
 316:	87aa                	mv	a5,a0
 318:	1602                	slli	a2,a2,0x20
 31a:	9201                	srli	a2,a2,0x20
 31c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 320:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 324:	0785                	addi	a5,a5,1
 326:	fee79de3          	bne	a5,a4,320 <memset+0x12>
  }
  return dst;
}
 32a:	6422                	ld	s0,8(sp)
 32c:	0141                	addi	sp,sp,16
 32e:	8082                	ret

0000000000000330 <strchr>:

char*
strchr(const char *s, char c)
{
 330:	1141                	addi	sp,sp,-16
 332:	e422                	sd	s0,8(sp)
 334:	0800                	addi	s0,sp,16
  for(; *s; s++)
 336:	00054783          	lbu	a5,0(a0)
 33a:	cb99                	beqz	a5,350 <strchr+0x20>
    if(*s == c)
 33c:	00f58763          	beq	a1,a5,34a <strchr+0x1a>
  for(; *s; s++)
 340:	0505                	addi	a0,a0,1
 342:	00054783          	lbu	a5,0(a0)
 346:	fbfd                	bnez	a5,33c <strchr+0xc>
      return (char*)s;
  return 0;
 348:	4501                	li	a0,0
}
 34a:	6422                	ld	s0,8(sp)
 34c:	0141                	addi	sp,sp,16
 34e:	8082                	ret
  return 0;
 350:	4501                	li	a0,0
 352:	bfe5                	j	34a <strchr+0x1a>

0000000000000354 <gets>:

char*
gets(char *buf, int max)
{
 354:	711d                	addi	sp,sp,-96
 356:	ec86                	sd	ra,88(sp)
 358:	e8a2                	sd	s0,80(sp)
 35a:	e4a6                	sd	s1,72(sp)
 35c:	e0ca                	sd	s2,64(sp)
 35e:	fc4e                	sd	s3,56(sp)
 360:	f852                	sd	s4,48(sp)
 362:	f456                	sd	s5,40(sp)
 364:	f05a                	sd	s6,32(sp)
 366:	ec5e                	sd	s7,24(sp)
 368:	1080                	addi	s0,sp,96
 36a:	8baa                	mv	s7,a0
 36c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 36e:	892a                	mv	s2,a0
 370:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 372:	4aa9                	li	s5,10
 374:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 376:	89a6                	mv	s3,s1
 378:	2485                	addiw	s1,s1,1
 37a:	0344d863          	bge	s1,s4,3aa <gets+0x56>
    cc = read(0, &c, 1);
 37e:	4605                	li	a2,1
 380:	faf40593          	addi	a1,s0,-81
 384:	4501                	li	a0,0
 386:	00000097          	auipc	ra,0x0
 38a:	19c080e7          	jalr	412(ra) # 522 <read>
    if(cc < 1)
 38e:	00a05e63          	blez	a0,3aa <gets+0x56>
    buf[i++] = c;
 392:	faf44783          	lbu	a5,-81(s0)
 396:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 39a:	01578763          	beq	a5,s5,3a8 <gets+0x54>
 39e:	0905                	addi	s2,s2,1
 3a0:	fd679be3          	bne	a5,s6,376 <gets+0x22>
  for(i=0; i+1 < max; ){
 3a4:	89a6                	mv	s3,s1
 3a6:	a011                	j	3aa <gets+0x56>
 3a8:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3aa:	99de                	add	s3,s3,s7
 3ac:	00098023          	sb	zero,0(s3) # 23000 <base+0x21ff0>
  return buf;
}
 3b0:	855e                	mv	a0,s7
 3b2:	60e6                	ld	ra,88(sp)
 3b4:	6446                	ld	s0,80(sp)
 3b6:	64a6                	ld	s1,72(sp)
 3b8:	6906                	ld	s2,64(sp)
 3ba:	79e2                	ld	s3,56(sp)
 3bc:	7a42                	ld	s4,48(sp)
 3be:	7aa2                	ld	s5,40(sp)
 3c0:	7b02                	ld	s6,32(sp)
 3c2:	6be2                	ld	s7,24(sp)
 3c4:	6125                	addi	sp,sp,96
 3c6:	8082                	ret

00000000000003c8 <stat>:

int
stat(const char *n, struct stat *st)
{
 3c8:	1101                	addi	sp,sp,-32
 3ca:	ec06                	sd	ra,24(sp)
 3cc:	e822                	sd	s0,16(sp)
 3ce:	e426                	sd	s1,8(sp)
 3d0:	e04a                	sd	s2,0(sp)
 3d2:	1000                	addi	s0,sp,32
 3d4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3d6:	4581                	li	a1,0
 3d8:	00000097          	auipc	ra,0x0
 3dc:	172080e7          	jalr	370(ra) # 54a <open>
  if(fd < 0)
 3e0:	02054563          	bltz	a0,40a <stat+0x42>
 3e4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3e6:	85ca                	mv	a1,s2
 3e8:	00000097          	auipc	ra,0x0
 3ec:	17a080e7          	jalr	378(ra) # 562 <fstat>
 3f0:	892a                	mv	s2,a0
  close(fd);
 3f2:	8526                	mv	a0,s1
 3f4:	00000097          	auipc	ra,0x0
 3f8:	13e080e7          	jalr	318(ra) # 532 <close>
  return r;
}
 3fc:	854a                	mv	a0,s2
 3fe:	60e2                	ld	ra,24(sp)
 400:	6442                	ld	s0,16(sp)
 402:	64a2                	ld	s1,8(sp)
 404:	6902                	ld	s2,0(sp)
 406:	6105                	addi	sp,sp,32
 408:	8082                	ret
    return -1;
 40a:	597d                	li	s2,-1
 40c:	bfc5                	j	3fc <stat+0x34>

000000000000040e <atoi>:

int
atoi(const char *s)
{
 40e:	1141                	addi	sp,sp,-16
 410:	e422                	sd	s0,8(sp)
 412:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 414:	00054603          	lbu	a2,0(a0)
 418:	fd06079b          	addiw	a5,a2,-48
 41c:	0ff7f793          	andi	a5,a5,255
 420:	4725                	li	a4,9
 422:	02f76963          	bltu	a4,a5,454 <atoi+0x46>
 426:	86aa                	mv	a3,a0
  n = 0;
 428:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 42a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 42c:	0685                	addi	a3,a3,1
 42e:	0025179b          	slliw	a5,a0,0x2
 432:	9fa9                	addw	a5,a5,a0
 434:	0017979b          	slliw	a5,a5,0x1
 438:	9fb1                	addw	a5,a5,a2
 43a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 43e:	0006c603          	lbu	a2,0(a3)
 442:	fd06071b          	addiw	a4,a2,-48
 446:	0ff77713          	andi	a4,a4,255
 44a:	fee5f1e3          	bgeu	a1,a4,42c <atoi+0x1e>
  return n;
}
 44e:	6422                	ld	s0,8(sp)
 450:	0141                	addi	sp,sp,16
 452:	8082                	ret
  n = 0;
 454:	4501                	li	a0,0
 456:	bfe5                	j	44e <atoi+0x40>

0000000000000458 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 458:	1141                	addi	sp,sp,-16
 45a:	e422                	sd	s0,8(sp)
 45c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 45e:	02b57463          	bgeu	a0,a1,486 <memmove+0x2e>
    while(n-- > 0)
 462:	00c05f63          	blez	a2,480 <memmove+0x28>
 466:	1602                	slli	a2,a2,0x20
 468:	9201                	srli	a2,a2,0x20
 46a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 46e:	872a                	mv	a4,a0
      *dst++ = *src++;
 470:	0585                	addi	a1,a1,1
 472:	0705                	addi	a4,a4,1
 474:	fff5c683          	lbu	a3,-1(a1)
 478:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 47c:	fee79ae3          	bne	a5,a4,470 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 480:	6422                	ld	s0,8(sp)
 482:	0141                	addi	sp,sp,16
 484:	8082                	ret
    dst += n;
 486:	00c50733          	add	a4,a0,a2
    src += n;
 48a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 48c:	fec05ae3          	blez	a2,480 <memmove+0x28>
 490:	fff6079b          	addiw	a5,a2,-1
 494:	1782                	slli	a5,a5,0x20
 496:	9381                	srli	a5,a5,0x20
 498:	fff7c793          	not	a5,a5
 49c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 49e:	15fd                	addi	a1,a1,-1
 4a0:	177d                	addi	a4,a4,-1
 4a2:	0005c683          	lbu	a3,0(a1)
 4a6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4aa:	fee79ae3          	bne	a5,a4,49e <memmove+0x46>
 4ae:	bfc9                	j	480 <memmove+0x28>

00000000000004b0 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4b0:	1141                	addi	sp,sp,-16
 4b2:	e422                	sd	s0,8(sp)
 4b4:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4b6:	ca05                	beqz	a2,4e6 <memcmp+0x36>
 4b8:	fff6069b          	addiw	a3,a2,-1
 4bc:	1682                	slli	a3,a3,0x20
 4be:	9281                	srli	a3,a3,0x20
 4c0:	0685                	addi	a3,a3,1
 4c2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4c4:	00054783          	lbu	a5,0(a0)
 4c8:	0005c703          	lbu	a4,0(a1)
 4cc:	00e79863          	bne	a5,a4,4dc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4d0:	0505                	addi	a0,a0,1
    p2++;
 4d2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4d4:	fed518e3          	bne	a0,a3,4c4 <memcmp+0x14>
  }
  return 0;
 4d8:	4501                	li	a0,0
 4da:	a019                	j	4e0 <memcmp+0x30>
      return *p1 - *p2;
 4dc:	40e7853b          	subw	a0,a5,a4
}
 4e0:	6422                	ld	s0,8(sp)
 4e2:	0141                	addi	sp,sp,16
 4e4:	8082                	ret
  return 0;
 4e6:	4501                	li	a0,0
 4e8:	bfe5                	j	4e0 <memcmp+0x30>

00000000000004ea <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4ea:	1141                	addi	sp,sp,-16
 4ec:	e406                	sd	ra,8(sp)
 4ee:	e022                	sd	s0,0(sp)
 4f0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4f2:	00000097          	auipc	ra,0x0
 4f6:	f66080e7          	jalr	-154(ra) # 458 <memmove>
}
 4fa:	60a2                	ld	ra,8(sp)
 4fc:	6402                	ld	s0,0(sp)
 4fe:	0141                	addi	sp,sp,16
 500:	8082                	ret

0000000000000502 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 502:	4885                	li	a7,1
 ecall
 504:	00000073          	ecall
 ret
 508:	8082                	ret

000000000000050a <exit>:
.global exit
exit:
 li a7, SYS_exit
 50a:	4889                	li	a7,2
 ecall
 50c:	00000073          	ecall
 ret
 510:	8082                	ret

0000000000000512 <wait>:
.global wait
wait:
 li a7, SYS_wait
 512:	488d                	li	a7,3
 ecall
 514:	00000073          	ecall
 ret
 518:	8082                	ret

000000000000051a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 51a:	4891                	li	a7,4
 ecall
 51c:	00000073          	ecall
 ret
 520:	8082                	ret

0000000000000522 <read>:
.global read
read:
 li a7, SYS_read
 522:	4895                	li	a7,5
 ecall
 524:	00000073          	ecall
 ret
 528:	8082                	ret

000000000000052a <write>:
.global write
write:
 li a7, SYS_write
 52a:	48c1                	li	a7,16
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <close>:
.global close
close:
 li a7, SYS_close
 532:	48d5                	li	a7,21
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <kill>:
.global kill
kill:
 li a7, SYS_kill
 53a:	4899                	li	a7,6
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <exec>:
.global exec
exec:
 li a7, SYS_exec
 542:	489d                	li	a7,7
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <open>:
.global open
open:
 li a7, SYS_open
 54a:	48bd                	li	a7,15
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 552:	48c5                	li	a7,17
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 55a:	48c9                	li	a7,18
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 562:	48a1                	li	a7,8
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <link>:
.global link
link:
 li a7, SYS_link
 56a:	48cd                	li	a7,19
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 572:	48d1                	li	a7,20
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 57a:	48a5                	li	a7,9
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <dup>:
.global dup
dup:
 li a7, SYS_dup
 582:	48a9                	li	a7,10
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 58a:	48ad                	li	a7,11
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 592:	48b1                	li	a7,12
 ecall
 594:	00000073          	ecall
 ret
 598:	8082                	ret

000000000000059a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 59a:	48b5                	li	a7,13
 ecall
 59c:	00000073          	ecall
 ret
 5a0:	8082                	ret

00000000000005a2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5a2:	48b9                	li	a7,14
 ecall
 5a4:	00000073          	ecall
 ret
 5a8:	8082                	ret

00000000000005aa <flip_display>:
.global flip_display
flip_display:
 li a7, SYS_flip_display
 5aa:	48d9                	li	a7,22
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <map_display>:
.global map_display
map_display:
 li a7, SYS_map_display
 5b2:	48dd                	li	a7,23
 ecall
 5b4:	00000073          	ecall
 ret
 5b8:	8082                	ret

00000000000005ba <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5ba:	1101                	addi	sp,sp,-32
 5bc:	ec06                	sd	ra,24(sp)
 5be:	e822                	sd	s0,16(sp)
 5c0:	1000                	addi	s0,sp,32
 5c2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5c6:	4605                	li	a2,1
 5c8:	fef40593          	addi	a1,s0,-17
 5cc:	00000097          	auipc	ra,0x0
 5d0:	f5e080e7          	jalr	-162(ra) # 52a <write>
}
 5d4:	60e2                	ld	ra,24(sp)
 5d6:	6442                	ld	s0,16(sp)
 5d8:	6105                	addi	sp,sp,32
 5da:	8082                	ret

00000000000005dc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5dc:	7139                	addi	sp,sp,-64
 5de:	fc06                	sd	ra,56(sp)
 5e0:	f822                	sd	s0,48(sp)
 5e2:	f426                	sd	s1,40(sp)
 5e4:	f04a                	sd	s2,32(sp)
 5e6:	ec4e                	sd	s3,24(sp)
 5e8:	0080                	addi	s0,sp,64
 5ea:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5ec:	c299                	beqz	a3,5f2 <printint+0x16>
 5ee:	0805c863          	bltz	a1,67e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5f2:	2581                	sext.w	a1,a1
  neg = 0;
 5f4:	4881                	li	a7,0
 5f6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5fa:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5fc:	2601                	sext.w	a2,a2
 5fe:	00001517          	auipc	a0,0x1
 602:	8c250513          	addi	a0,a0,-1854 # ec0 <digits>
 606:	883a                	mv	a6,a4
 608:	2705                	addiw	a4,a4,1
 60a:	02c5f7bb          	remuw	a5,a1,a2
 60e:	1782                	slli	a5,a5,0x20
 610:	9381                	srli	a5,a5,0x20
 612:	97aa                	add	a5,a5,a0
 614:	0007c783          	lbu	a5,0(a5)
 618:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 61c:	0005879b          	sext.w	a5,a1
 620:	02c5d5bb          	divuw	a1,a1,a2
 624:	0685                	addi	a3,a3,1
 626:	fec7f0e3          	bgeu	a5,a2,606 <printint+0x2a>
  if(neg)
 62a:	00088b63          	beqz	a7,640 <printint+0x64>
    buf[i++] = '-';
 62e:	fd040793          	addi	a5,s0,-48
 632:	973e                	add	a4,a4,a5
 634:	02d00793          	li	a5,45
 638:	fef70823          	sb	a5,-16(a4)
 63c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 640:	02e05863          	blez	a4,670 <printint+0x94>
 644:	fc040793          	addi	a5,s0,-64
 648:	00e78933          	add	s2,a5,a4
 64c:	fff78993          	addi	s3,a5,-1
 650:	99ba                	add	s3,s3,a4
 652:	377d                	addiw	a4,a4,-1
 654:	1702                	slli	a4,a4,0x20
 656:	9301                	srli	a4,a4,0x20
 658:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 65c:	fff94583          	lbu	a1,-1(s2)
 660:	8526                	mv	a0,s1
 662:	00000097          	auipc	ra,0x0
 666:	f58080e7          	jalr	-168(ra) # 5ba <putc>
  while(--i >= 0)
 66a:	197d                	addi	s2,s2,-1
 66c:	ff3918e3          	bne	s2,s3,65c <printint+0x80>
}
 670:	70e2                	ld	ra,56(sp)
 672:	7442                	ld	s0,48(sp)
 674:	74a2                	ld	s1,40(sp)
 676:	7902                	ld	s2,32(sp)
 678:	69e2                	ld	s3,24(sp)
 67a:	6121                	addi	sp,sp,64
 67c:	8082                	ret
    x = -xx;
 67e:	40b005bb          	negw	a1,a1
    neg = 1;
 682:	4885                	li	a7,1
    x = -xx;
 684:	bf8d                	j	5f6 <printint+0x1a>

0000000000000686 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 686:	7119                	addi	sp,sp,-128
 688:	fc86                	sd	ra,120(sp)
 68a:	f8a2                	sd	s0,112(sp)
 68c:	f4a6                	sd	s1,104(sp)
 68e:	f0ca                	sd	s2,96(sp)
 690:	ecce                	sd	s3,88(sp)
 692:	e8d2                	sd	s4,80(sp)
 694:	e4d6                	sd	s5,72(sp)
 696:	e0da                	sd	s6,64(sp)
 698:	fc5e                	sd	s7,56(sp)
 69a:	f862                	sd	s8,48(sp)
 69c:	f466                	sd	s9,40(sp)
 69e:	f06a                	sd	s10,32(sp)
 6a0:	ec6e                	sd	s11,24(sp)
 6a2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6a4:	0005c903          	lbu	s2,0(a1)
 6a8:	18090f63          	beqz	s2,846 <vprintf+0x1c0>
 6ac:	8aaa                	mv	s5,a0
 6ae:	8b32                	mv	s6,a2
 6b0:	00158493          	addi	s1,a1,1
  state = 0;
 6b4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6b6:	02500a13          	li	s4,37
      if(c == 'd'){
 6ba:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6be:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6c2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6c6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6ca:	00000b97          	auipc	s7,0x0
 6ce:	7f6b8b93          	addi	s7,s7,2038 # ec0 <digits>
 6d2:	a839                	j	6f0 <vprintf+0x6a>
        putc(fd, c);
 6d4:	85ca                	mv	a1,s2
 6d6:	8556                	mv	a0,s5
 6d8:	00000097          	auipc	ra,0x0
 6dc:	ee2080e7          	jalr	-286(ra) # 5ba <putc>
 6e0:	a019                	j	6e6 <vprintf+0x60>
    } else if(state == '%'){
 6e2:	01498f63          	beq	s3,s4,700 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6e6:	0485                	addi	s1,s1,1
 6e8:	fff4c903          	lbu	s2,-1(s1)
 6ec:	14090d63          	beqz	s2,846 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6f0:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6f4:	fe0997e3          	bnez	s3,6e2 <vprintf+0x5c>
      if(c == '%'){
 6f8:	fd479ee3          	bne	a5,s4,6d4 <vprintf+0x4e>
        state = '%';
 6fc:	89be                	mv	s3,a5
 6fe:	b7e5                	j	6e6 <vprintf+0x60>
      if(c == 'd'){
 700:	05878063          	beq	a5,s8,740 <vprintf+0xba>
      } else if(c == 'l') {
 704:	05978c63          	beq	a5,s9,75c <vprintf+0xd6>
      } else if(c == 'x') {
 708:	07a78863          	beq	a5,s10,778 <vprintf+0xf2>
      } else if(c == 'p') {
 70c:	09b78463          	beq	a5,s11,794 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 710:	07300713          	li	a4,115
 714:	0ce78663          	beq	a5,a4,7e0 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 718:	06300713          	li	a4,99
 71c:	0ee78e63          	beq	a5,a4,818 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 720:	11478863          	beq	a5,s4,830 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 724:	85d2                	mv	a1,s4
 726:	8556                	mv	a0,s5
 728:	00000097          	auipc	ra,0x0
 72c:	e92080e7          	jalr	-366(ra) # 5ba <putc>
        putc(fd, c);
 730:	85ca                	mv	a1,s2
 732:	8556                	mv	a0,s5
 734:	00000097          	auipc	ra,0x0
 738:	e86080e7          	jalr	-378(ra) # 5ba <putc>
      }
      state = 0;
 73c:	4981                	li	s3,0
 73e:	b765                	j	6e6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 740:	008b0913          	addi	s2,s6,8 # 1008 <freep+0x8>
 744:	4685                	li	a3,1
 746:	4629                	li	a2,10
 748:	000b2583          	lw	a1,0(s6)
 74c:	8556                	mv	a0,s5
 74e:	00000097          	auipc	ra,0x0
 752:	e8e080e7          	jalr	-370(ra) # 5dc <printint>
 756:	8b4a                	mv	s6,s2
      state = 0;
 758:	4981                	li	s3,0
 75a:	b771                	j	6e6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 75c:	008b0913          	addi	s2,s6,8
 760:	4681                	li	a3,0
 762:	4629                	li	a2,10
 764:	000b2583          	lw	a1,0(s6)
 768:	8556                	mv	a0,s5
 76a:	00000097          	auipc	ra,0x0
 76e:	e72080e7          	jalr	-398(ra) # 5dc <printint>
 772:	8b4a                	mv	s6,s2
      state = 0;
 774:	4981                	li	s3,0
 776:	bf85                	j	6e6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 778:	008b0913          	addi	s2,s6,8
 77c:	4681                	li	a3,0
 77e:	4641                	li	a2,16
 780:	000b2583          	lw	a1,0(s6)
 784:	8556                	mv	a0,s5
 786:	00000097          	auipc	ra,0x0
 78a:	e56080e7          	jalr	-426(ra) # 5dc <printint>
 78e:	8b4a                	mv	s6,s2
      state = 0;
 790:	4981                	li	s3,0
 792:	bf91                	j	6e6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 794:	008b0793          	addi	a5,s6,8
 798:	f8f43423          	sd	a5,-120(s0)
 79c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7a0:	03000593          	li	a1,48
 7a4:	8556                	mv	a0,s5
 7a6:	00000097          	auipc	ra,0x0
 7aa:	e14080e7          	jalr	-492(ra) # 5ba <putc>
  putc(fd, 'x');
 7ae:	85ea                	mv	a1,s10
 7b0:	8556                	mv	a0,s5
 7b2:	00000097          	auipc	ra,0x0
 7b6:	e08080e7          	jalr	-504(ra) # 5ba <putc>
 7ba:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7bc:	03c9d793          	srli	a5,s3,0x3c
 7c0:	97de                	add	a5,a5,s7
 7c2:	0007c583          	lbu	a1,0(a5)
 7c6:	8556                	mv	a0,s5
 7c8:	00000097          	auipc	ra,0x0
 7cc:	df2080e7          	jalr	-526(ra) # 5ba <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7d0:	0992                	slli	s3,s3,0x4
 7d2:	397d                	addiw	s2,s2,-1
 7d4:	fe0914e3          	bnez	s2,7bc <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7d8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7dc:	4981                	li	s3,0
 7de:	b721                	j	6e6 <vprintf+0x60>
        s = va_arg(ap, char*);
 7e0:	008b0993          	addi	s3,s6,8
 7e4:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7e8:	02090163          	beqz	s2,80a <vprintf+0x184>
        while(*s != 0){
 7ec:	00094583          	lbu	a1,0(s2)
 7f0:	c9a1                	beqz	a1,840 <vprintf+0x1ba>
          putc(fd, *s);
 7f2:	8556                	mv	a0,s5
 7f4:	00000097          	auipc	ra,0x0
 7f8:	dc6080e7          	jalr	-570(ra) # 5ba <putc>
          s++;
 7fc:	0905                	addi	s2,s2,1
        while(*s != 0){
 7fe:	00094583          	lbu	a1,0(s2)
 802:	f9e5                	bnez	a1,7f2 <vprintf+0x16c>
        s = va_arg(ap, char*);
 804:	8b4e                	mv	s6,s3
      state = 0;
 806:	4981                	li	s3,0
 808:	bdf9                	j	6e6 <vprintf+0x60>
          s = "(null)";
 80a:	00000917          	auipc	s2,0x0
 80e:	6ae90913          	addi	s2,s2,1710 # eb8 <font8x8+0x400>
        while(*s != 0){
 812:	02800593          	li	a1,40
 816:	bff1                	j	7f2 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 818:	008b0913          	addi	s2,s6,8
 81c:	000b4583          	lbu	a1,0(s6)
 820:	8556                	mv	a0,s5
 822:	00000097          	auipc	ra,0x0
 826:	d98080e7          	jalr	-616(ra) # 5ba <putc>
 82a:	8b4a                	mv	s6,s2
      state = 0;
 82c:	4981                	li	s3,0
 82e:	bd65                	j	6e6 <vprintf+0x60>
        putc(fd, c);
 830:	85d2                	mv	a1,s4
 832:	8556                	mv	a0,s5
 834:	00000097          	auipc	ra,0x0
 838:	d86080e7          	jalr	-634(ra) # 5ba <putc>
      state = 0;
 83c:	4981                	li	s3,0
 83e:	b565                	j	6e6 <vprintf+0x60>
        s = va_arg(ap, char*);
 840:	8b4e                	mv	s6,s3
      state = 0;
 842:	4981                	li	s3,0
 844:	b54d                	j	6e6 <vprintf+0x60>
    }
  }
}
 846:	70e6                	ld	ra,120(sp)
 848:	7446                	ld	s0,112(sp)
 84a:	74a6                	ld	s1,104(sp)
 84c:	7906                	ld	s2,96(sp)
 84e:	69e6                	ld	s3,88(sp)
 850:	6a46                	ld	s4,80(sp)
 852:	6aa6                	ld	s5,72(sp)
 854:	6b06                	ld	s6,64(sp)
 856:	7be2                	ld	s7,56(sp)
 858:	7c42                	ld	s8,48(sp)
 85a:	7ca2                	ld	s9,40(sp)
 85c:	7d02                	ld	s10,32(sp)
 85e:	6de2                	ld	s11,24(sp)
 860:	6109                	addi	sp,sp,128
 862:	8082                	ret

0000000000000864 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 864:	715d                	addi	sp,sp,-80
 866:	ec06                	sd	ra,24(sp)
 868:	e822                	sd	s0,16(sp)
 86a:	1000                	addi	s0,sp,32
 86c:	e010                	sd	a2,0(s0)
 86e:	e414                	sd	a3,8(s0)
 870:	e818                	sd	a4,16(s0)
 872:	ec1c                	sd	a5,24(s0)
 874:	03043023          	sd	a6,32(s0)
 878:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 87c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 880:	8622                	mv	a2,s0
 882:	00000097          	auipc	ra,0x0
 886:	e04080e7          	jalr	-508(ra) # 686 <vprintf>
}
 88a:	60e2                	ld	ra,24(sp)
 88c:	6442                	ld	s0,16(sp)
 88e:	6161                	addi	sp,sp,80
 890:	8082                	ret

0000000000000892 <printf>:

void
printf(const char *fmt, ...)
{
 892:	711d                	addi	sp,sp,-96
 894:	ec06                	sd	ra,24(sp)
 896:	e822                	sd	s0,16(sp)
 898:	1000                	addi	s0,sp,32
 89a:	e40c                	sd	a1,8(s0)
 89c:	e810                	sd	a2,16(s0)
 89e:	ec14                	sd	a3,24(s0)
 8a0:	f018                	sd	a4,32(s0)
 8a2:	f41c                	sd	a5,40(s0)
 8a4:	03043823          	sd	a6,48(s0)
 8a8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8ac:	00840613          	addi	a2,s0,8
 8b0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8b4:	85aa                	mv	a1,a0
 8b6:	4505                	li	a0,1
 8b8:	00000097          	auipc	ra,0x0
 8bc:	dce080e7          	jalr	-562(ra) # 686 <vprintf>
}
 8c0:	60e2                	ld	ra,24(sp)
 8c2:	6442                	ld	s0,16(sp)
 8c4:	6125                	addi	sp,sp,96
 8c6:	8082                	ret

00000000000008c8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8c8:	1141                	addi	sp,sp,-16
 8ca:	e422                	sd	s0,8(sp)
 8cc:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8ce:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8d2:	00000797          	auipc	a5,0x0
 8d6:	72e7b783          	ld	a5,1838(a5) # 1000 <freep>
 8da:	a805                	j	90a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8dc:	4618                	lw	a4,8(a2)
 8de:	9db9                	addw	a1,a1,a4
 8e0:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8e4:	6398                	ld	a4,0(a5)
 8e6:	6318                	ld	a4,0(a4)
 8e8:	fee53823          	sd	a4,-16(a0)
 8ec:	a091                	j	930 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8ee:	ff852703          	lw	a4,-8(a0)
 8f2:	9e39                	addw	a2,a2,a4
 8f4:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8f6:	ff053703          	ld	a4,-16(a0)
 8fa:	e398                	sd	a4,0(a5)
 8fc:	a099                	j	942 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8fe:	6398                	ld	a4,0(a5)
 900:	00e7e463          	bltu	a5,a4,908 <free+0x40>
 904:	00e6ea63          	bltu	a3,a4,918 <free+0x50>
{
 908:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 90a:	fed7fae3          	bgeu	a5,a3,8fe <free+0x36>
 90e:	6398                	ld	a4,0(a5)
 910:	00e6e463          	bltu	a3,a4,918 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 914:	fee7eae3          	bltu	a5,a4,908 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 918:	ff852583          	lw	a1,-8(a0)
 91c:	6390                	ld	a2,0(a5)
 91e:	02059713          	slli	a4,a1,0x20
 922:	9301                	srli	a4,a4,0x20
 924:	0712                	slli	a4,a4,0x4
 926:	9736                	add	a4,a4,a3
 928:	fae60ae3          	beq	a2,a4,8dc <free+0x14>
    bp->s.ptr = p->s.ptr;
 92c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 930:	4790                	lw	a2,8(a5)
 932:	02061713          	slli	a4,a2,0x20
 936:	9301                	srli	a4,a4,0x20
 938:	0712                	slli	a4,a4,0x4
 93a:	973e                	add	a4,a4,a5
 93c:	fae689e3          	beq	a3,a4,8ee <free+0x26>
  } else
    p->s.ptr = bp;
 940:	e394                	sd	a3,0(a5)
  freep = p;
 942:	00000717          	auipc	a4,0x0
 946:	6af73f23          	sd	a5,1726(a4) # 1000 <freep>
}
 94a:	6422                	ld	s0,8(sp)
 94c:	0141                	addi	sp,sp,16
 94e:	8082                	ret

0000000000000950 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 950:	7139                	addi	sp,sp,-64
 952:	fc06                	sd	ra,56(sp)
 954:	f822                	sd	s0,48(sp)
 956:	f426                	sd	s1,40(sp)
 958:	f04a                	sd	s2,32(sp)
 95a:	ec4e                	sd	s3,24(sp)
 95c:	e852                	sd	s4,16(sp)
 95e:	e456                	sd	s5,8(sp)
 960:	e05a                	sd	s6,0(sp)
 962:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 964:	02051493          	slli	s1,a0,0x20
 968:	9081                	srli	s1,s1,0x20
 96a:	04bd                	addi	s1,s1,15
 96c:	8091                	srli	s1,s1,0x4
 96e:	0014899b          	addiw	s3,s1,1
 972:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 974:	00000517          	auipc	a0,0x0
 978:	68c53503          	ld	a0,1676(a0) # 1000 <freep>
 97c:	c515                	beqz	a0,9a8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 97e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 980:	4798                	lw	a4,8(a5)
 982:	02977f63          	bgeu	a4,s1,9c0 <malloc+0x70>
 986:	8a4e                	mv	s4,s3
 988:	0009871b          	sext.w	a4,s3
 98c:	6685                	lui	a3,0x1
 98e:	00d77363          	bgeu	a4,a3,994 <malloc+0x44>
 992:	6a05                	lui	s4,0x1
 994:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 998:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 99c:	00000917          	auipc	s2,0x0
 9a0:	66490913          	addi	s2,s2,1636 # 1000 <freep>
  if(p == (char*)-1)
 9a4:	5afd                	li	s5,-1
 9a6:	a88d                	j	a18 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9a8:	00000797          	auipc	a5,0x0
 9ac:	66878793          	addi	a5,a5,1640 # 1010 <base>
 9b0:	00000717          	auipc	a4,0x0
 9b4:	64f73823          	sd	a5,1616(a4) # 1000 <freep>
 9b8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9ba:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9be:	b7e1                	j	986 <malloc+0x36>
      if(p->s.size == nunits)
 9c0:	02e48b63          	beq	s1,a4,9f6 <malloc+0xa6>
        p->s.size -= nunits;
 9c4:	4137073b          	subw	a4,a4,s3
 9c8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9ca:	1702                	slli	a4,a4,0x20
 9cc:	9301                	srli	a4,a4,0x20
 9ce:	0712                	slli	a4,a4,0x4
 9d0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9d2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9d6:	00000717          	auipc	a4,0x0
 9da:	62a73523          	sd	a0,1578(a4) # 1000 <freep>
      return (void*)(p + 1);
 9de:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9e2:	70e2                	ld	ra,56(sp)
 9e4:	7442                	ld	s0,48(sp)
 9e6:	74a2                	ld	s1,40(sp)
 9e8:	7902                	ld	s2,32(sp)
 9ea:	69e2                	ld	s3,24(sp)
 9ec:	6a42                	ld	s4,16(sp)
 9ee:	6aa2                	ld	s5,8(sp)
 9f0:	6b02                	ld	s6,0(sp)
 9f2:	6121                	addi	sp,sp,64
 9f4:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9f6:	6398                	ld	a4,0(a5)
 9f8:	e118                	sd	a4,0(a0)
 9fa:	bff1                	j	9d6 <malloc+0x86>
  hp->s.size = nu;
 9fc:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a00:	0541                	addi	a0,a0,16
 a02:	00000097          	auipc	ra,0x0
 a06:	ec6080e7          	jalr	-314(ra) # 8c8 <free>
  return freep;
 a0a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a0e:	d971                	beqz	a0,9e2 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a10:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a12:	4798                	lw	a4,8(a5)
 a14:	fa9776e3          	bgeu	a4,s1,9c0 <malloc+0x70>
    if(p == freep)
 a18:	00093703          	ld	a4,0(s2)
 a1c:	853e                	mv	a0,a5
 a1e:	fef719e3          	bne	a4,a5,a10 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a22:	8552                	mv	a0,s4
 a24:	00000097          	auipc	ra,0x0
 a28:	b6e080e7          	jalr	-1170(ra) # 592 <sbrk>
  if(p == (char*)-1)
 a2c:	fd5518e3          	bne	a0,s5,9fc <malloc+0xac>
        return 0;
 a30:	4501                	li	a0,0
 a32:	bf45                	j	9e2 <malloc+0x92>
