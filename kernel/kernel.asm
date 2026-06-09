
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	1e013103          	ld	sp,480(sp) # 800091e0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	1ee70713          	addi	a4,a4,494 # 80009240 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	cbc78793          	addi	a5,a5,-836 # 80005d20 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd9137>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	424080e7          	jalr	1060(ra) # 80002550 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	1f650513          	addi	a0,a0,502 # 80011380 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	1e648493          	addi	s1,s1,486 # 80011380 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	27690913          	addi	s2,s2,630 # 80011418 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	824080e7          	jalr	-2012(ra) # 800019e4 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	1d2080e7          	jalr	466(ra) # 8000239a <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	f1c080e7          	jalr	-228(ra) # 800020f2 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	2e8080e7          	jalr	744(ra) # 800024fa <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	15a50513          	addi	a0,a0,346 # 80011380 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	14450513          	addi	a0,a0,324 # 80011380 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	1af72323          	sw	a5,422(a4) # 80011418 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	0b450513          	addi	a0,a0,180 # 80011380 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2b4080e7          	jalr	692(ra) # 800025a6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	08650513          	addi	a0,a0,134 # 80011380 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	06270713          	addi	a4,a4,98 # 80011380 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	03878793          	addi	a5,a5,56 # 80011380 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	0a27a783          	lw	a5,162(a5) # 80011418 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	ff670713          	addi	a4,a4,-10 # 80011380 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	fe648493          	addi	s1,s1,-26 # 80011380 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	faa70713          	addi	a4,a4,-86 # 80011380 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	02f72a23          	sw	a5,52(a4) # 80011420 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	f6e78793          	addi	a5,a5,-146 # 80011380 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	fec7a323          	sw	a2,-26(a5) # 8001141c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	fda50513          	addi	a0,a0,-38 # 80011418 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d10080e7          	jalr	-752(ra) # 80002156 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	f2050513          	addi	a0,a0,-224 # 80011380 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	0a078793          	addi	a5,a5,160 # 80021518 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ee07ab23          	sw	zero,-266(a5) # 80011440 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b6c50513          	addi	a0,a0,-1172 # 800080d8 <digits+0x98>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	c8f72123          	sw	a5,-894(a4) # 80009200 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	e86dad83          	lw	s11,-378(s11) # 80011440 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	e3050513          	addi	a0,a0,-464 # 80011428 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00011517          	auipc	a0,0x11
    8000075a:	cd250513          	addi	a0,a0,-814 # 80011428 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00011497          	auipc	s1,0x11
    80000776:	cb648493          	addi	s1,s1,-842 # 80011428 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00011517          	auipc	a0,0x11
    800007d6:	c7650513          	addi	a0,a0,-906 # 80011448 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00009797          	auipc	a5,0x9
    80000802:	a027a783          	lw	a5,-1534(a5) # 80009200 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00009797          	auipc	a5,0x9
    8000083a:	9d27b783          	ld	a5,-1582(a5) # 80009208 <uart_tx_r>
    8000083e:	00009717          	auipc	a4,0x9
    80000842:	9d273703          	ld	a4,-1582(a4) # 80009210 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00011a17          	auipc	s4,0x11
    80000864:	be8a0a13          	addi	s4,s4,-1048 # 80011448 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00009497          	auipc	s1,0x9
    8000086c:	9a048493          	addi	s1,s1,-1632 # 80009208 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00009997          	auipc	s3,0x9
    80000874:	9a098993          	addi	s3,s3,-1632 # 80009210 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	8c4080e7          	jalr	-1852(ra) # 80002156 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	b7a50513          	addi	a0,a0,-1158 # 80011448 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00009797          	auipc	a5,0x9
    800008e2:	9227a783          	lw	a5,-1758(a5) # 80009200 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00009717          	auipc	a4,0x9
    800008ec:	92873703          	ld	a4,-1752(a4) # 80009210 <uart_tx_w>
    800008f0:	00009797          	auipc	a5,0x9
    800008f4:	9187b783          	ld	a5,-1768(a5) # 80009208 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00011997          	auipc	s3,0x11
    80000900:	b4c98993          	addi	s3,s3,-1204 # 80011448 <uart_tx_lock>
    80000904:	00009497          	auipc	s1,0x9
    80000908:	90448493          	addi	s1,s1,-1788 # 80009208 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00009917          	auipc	s2,0x9
    80000910:	90490913          	addi	s2,s2,-1788 # 80009210 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	7d6080e7          	jalr	2006(ra) # 800020f2 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00011497          	auipc	s1,0x11
    80000936:	b1648493          	addi	s1,s1,-1258 # 80011448 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00009797          	auipc	a5,0x9
    8000094a:	8ce7b523          	sd	a4,-1846(a5) # 80009210 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	a8c48493          	addi	s1,s1,-1396 # 80011448 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00025797          	auipc	a5,0x25
    80000a02:	cca78793          	addi	a5,a5,-822 # 800256c8 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00011917          	auipc	s2,0x11
    80000a22:	a6290913          	addi	s2,s2,-1438 # 80011480 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00011517          	auipc	a0,0x11
    80000abe:	9c650513          	addi	a0,a0,-1594 # 80011480 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00025517          	auipc	a0,0x25
    80000ad2:	bfa50513          	addi	a0,a0,-1030 # 800256c8 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00011497          	auipc	s1,0x11
    80000af4:	99048493          	addi	s1,s1,-1648 # 80011480 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00011517          	auipc	a0,0x11
    80000b0c:	97850513          	addi	a0,a0,-1672 # 80011480 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00011517          	auipc	a0,0x11
    80000b38:	94c50513          	addi	a0,a0,-1716 # 80011480 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e58080e7          	jalr	-424(ra) # 800019c8 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	e26080e7          	jalr	-474(ra) # 800019c8 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	e1a080e7          	jalr	-486(ra) # 800019c8 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	e02080e7          	jalr	-510(ra) # 800019c8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	dc2080e7          	jalr	-574(ra) # 800019c8 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d96080e7          	jalr	-618(ra) # 800019c8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b38080e7          	jalr	-1224(ra) # 800019b8 <cpuid>
    userinit();      // first user process
    kproc_create(display_daemon, "displaydaemon"); // GPU auto-commit daemon
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	39070713          	addi	a4,a4,912 # 80009218 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	b1c080e7          	jalr	-1252(ra) # 800019b8 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	22250513          	addi	a0,a0,546 # 800080c8 <digits+0x88>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0f8080e7          	jalr	248(ra) # 80000fae <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	8dc080e7          	jalr	-1828(ra) # 8000279a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	e9a080e7          	jalr	-358(ra) # 80005d60 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	072080e7          	jalr	114(ra) # 80001f40 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1f250513          	addi	a0,a0,498 # 800080d8 <digits+0x98>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1d250513          	addi	a0,a0,466 # 800080d8 <digits+0x98>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	35c080e7          	jalr	860(ra) # 8000127a <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	088080e7          	jalr	136(ra) # 80000fae <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	9d6080e7          	jalr	-1578(ra) # 80001904 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	83c080e7          	jalr	-1988(ra) # 80002772 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	85c080e7          	jalr	-1956(ra) # 8000279a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	e04080e7          	jalr	-508(ra) # 80005d4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	e12080e7          	jalr	-494(ra) # 80005d60 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	fb8080e7          	jalr	-72(ra) # 80002f0e <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	65c080e7          	jalr	1628(ra) # 800035ba <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	5fa080e7          	jalr	1530(ra) # 80004560 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	efa080e7          	jalr	-262(ra) # 80005e68 <virtio_disk_init>
    virtio_gpu_init();  // virtio GPU display window
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	600080e7          	jalr	1536(ra) # 80006576 <virtio_gpu_init>
    userinit();      // first user process
    80000f7e:	00001097          	auipc	ra,0x1
    80000f82:	d3e080e7          	jalr	-706(ra) # 80001cbc <userinit>
    kproc_create(display_daemon, "displaydaemon"); // GPU auto-commit daemon
    80000f86:	00007597          	auipc	a1,0x7
    80000f8a:	13258593          	addi	a1,a1,306 # 800080b8 <digits+0x78>
    80000f8e:	00006517          	auipc	a0,0x6
    80000f92:	a3a50513          	addi	a0,a0,-1478 # 800069c8 <display_daemon>
    80000f96:	00001097          	auipc	ra,0x1
    80000f9a:	da8080e7          	jalr	-600(ra) # 80001d3e <kproc_create>
    __sync_synchronize();
    80000f9e:	0ff0000f          	fence
    started = 1;
    80000fa2:	4785                	li	a5,1
    80000fa4:	00008717          	auipc	a4,0x8
    80000fa8:	26f72a23          	sw	a5,628(a4) # 80009218 <started>
    80000fac:	b70d                	j	80000ece <main+0x56>

0000000080000fae <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fae:	1141                	addi	sp,sp,-16
    80000fb0:	e422                	sd	s0,8(sp)
    80000fb2:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb8:	00008797          	auipc	a5,0x8
    80000fbc:	2687b783          	ld	a5,616(a5) # 80009220 <kernel_pagetable>
    80000fc0:	83b1                	srli	a5,a5,0xc
    80000fc2:	577d                	li	a4,-1
    80000fc4:	177e                	slli	a4,a4,0x3f
    80000fc6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fcc:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fd0:	6422                	ld	s0,8(sp)
    80000fd2:	0141                	addi	sp,sp,16
    80000fd4:	8082                	ret

0000000080000fd6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd6:	7139                	addi	sp,sp,-64
    80000fd8:	fc06                	sd	ra,56(sp)
    80000fda:	f822                	sd	s0,48(sp)
    80000fdc:	f426                	sd	s1,40(sp)
    80000fde:	f04a                	sd	s2,32(sp)
    80000fe0:	ec4e                	sd	s3,24(sp)
    80000fe2:	e852                	sd	s4,16(sp)
    80000fe4:	e456                	sd	s5,8(sp)
    80000fe6:	e05a                	sd	s6,0(sp)
    80000fe8:	0080                	addi	s0,sp,64
    80000fea:	84aa                	mv	s1,a0
    80000fec:	89ae                	mv	s3,a1
    80000fee:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ff0:	57fd                	li	a5,-1
    80000ff2:	83e9                	srli	a5,a5,0x1a
    80000ff4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff8:	04b7f263          	bgeu	a5,a1,8000103c <walk+0x66>
    panic("walk");
    80000ffc:	00007517          	auipc	a0,0x7
    80001000:	0e450513          	addi	a0,a0,228 # 800080e0 <digits+0xa0>
    80001004:	fffff097          	auipc	ra,0xfffff
    80001008:	53a080e7          	jalr	1338(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000100c:	060a8663          	beqz	s5,80001078 <walk+0xa2>
    80001010:	00000097          	auipc	ra,0x0
    80001014:	ad6080e7          	jalr	-1322(ra) # 80000ae6 <kalloc>
    80001018:	84aa                	mv	s1,a0
    8000101a:	c529                	beqz	a0,80001064 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000101c:	6605                	lui	a2,0x1
    8000101e:	4581                	li	a1,0
    80001020:	00000097          	auipc	ra,0x0
    80001024:	cb2080e7          	jalr	-846(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001028:	00c4d793          	srli	a5,s1,0xc
    8000102c:	07aa                	slli	a5,a5,0xa
    8000102e:	0017e793          	ori	a5,a5,1
    80001032:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001036:	3a5d                	addiw	s4,s4,-9
    80001038:	036a0063          	beq	s4,s6,80001058 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000103c:	0149d933          	srl	s2,s3,s4
    80001040:	1ff97913          	andi	s2,s2,511
    80001044:	090e                	slli	s2,s2,0x3
    80001046:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001048:	00093483          	ld	s1,0(s2)
    8000104c:	0014f793          	andi	a5,s1,1
    80001050:	dfd5                	beqz	a5,8000100c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001052:	80a9                	srli	s1,s1,0xa
    80001054:	04b2                	slli	s1,s1,0xc
    80001056:	b7c5                	j	80001036 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001058:	00c9d513          	srli	a0,s3,0xc
    8000105c:	1ff57513          	andi	a0,a0,511
    80001060:	050e                	slli	a0,a0,0x3
    80001062:	9526                	add	a0,a0,s1
}
    80001064:	70e2                	ld	ra,56(sp)
    80001066:	7442                	ld	s0,48(sp)
    80001068:	74a2                	ld	s1,40(sp)
    8000106a:	7902                	ld	s2,32(sp)
    8000106c:	69e2                	ld	s3,24(sp)
    8000106e:	6a42                	ld	s4,16(sp)
    80001070:	6aa2                	ld	s5,8(sp)
    80001072:	6b02                	ld	s6,0(sp)
    80001074:	6121                	addi	sp,sp,64
    80001076:	8082                	ret
        return 0;
    80001078:	4501                	li	a0,0
    8000107a:	b7ed                	j	80001064 <walk+0x8e>

000000008000107c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000107c:	57fd                	li	a5,-1
    8000107e:	83e9                	srli	a5,a5,0x1a
    80001080:	00b7f463          	bgeu	a5,a1,80001088 <walkaddr+0xc>
    return 0;
    80001084:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001086:	8082                	ret
{
    80001088:	1141                	addi	sp,sp,-16
    8000108a:	e406                	sd	ra,8(sp)
    8000108c:	e022                	sd	s0,0(sp)
    8000108e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001090:	4601                	li	a2,0
    80001092:	00000097          	auipc	ra,0x0
    80001096:	f44080e7          	jalr	-188(ra) # 80000fd6 <walk>
  if(pte == 0)
    8000109a:	c105                	beqz	a0,800010ba <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000109c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109e:	0117f693          	andi	a3,a5,17
    800010a2:	4745                	li	a4,17
    return 0;
    800010a4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a6:	00e68663          	beq	a3,a4,800010b2 <walkaddr+0x36>
}
    800010aa:	60a2                	ld	ra,8(sp)
    800010ac:	6402                	ld	s0,0(sp)
    800010ae:	0141                	addi	sp,sp,16
    800010b0:	8082                	ret
  pa = PTE2PA(*pte);
    800010b2:	00a7d513          	srli	a0,a5,0xa
    800010b6:	0532                	slli	a0,a0,0xc
  return pa;
    800010b8:	bfcd                	j	800010aa <walkaddr+0x2e>
    return 0;
    800010ba:	4501                	li	a0,0
    800010bc:	b7fd                	j	800010aa <walkaddr+0x2e>

00000000800010be <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010be:	715d                	addi	sp,sp,-80
    800010c0:	e486                	sd	ra,72(sp)
    800010c2:	e0a2                	sd	s0,64(sp)
    800010c4:	fc26                	sd	s1,56(sp)
    800010c6:	f84a                	sd	s2,48(sp)
    800010c8:	f44e                	sd	s3,40(sp)
    800010ca:	f052                	sd	s4,32(sp)
    800010cc:	ec56                	sd	s5,24(sp)
    800010ce:	e85a                	sd	s6,16(sp)
    800010d0:	e45e                	sd	s7,8(sp)
    800010d2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d4:	c639                	beqz	a2,80001122 <mappages+0x64>
    800010d6:	8aaa                	mv	s5,a0
    800010d8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010da:	77fd                	lui	a5,0xfffff
    800010dc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010e0:	15fd                	addi	a1,a1,-1
    800010e2:	00c589b3          	add	s3,a1,a2
    800010e6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ea:	8952                	mv	s2,s4
    800010ec:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010f0:	6b85                	lui	s7,0x1
    800010f2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	4605                	li	a2,1
    800010f8:	85ca                	mv	a1,s2
    800010fa:	8556                	mv	a0,s5
    800010fc:	00000097          	auipc	ra,0x0
    80001100:	eda080e7          	jalr	-294(ra) # 80000fd6 <walk>
    80001104:	cd1d                	beqz	a0,80001142 <mappages+0x84>
    if(*pte & PTE_V)
    80001106:	611c                	ld	a5,0(a0)
    80001108:	8b85                	andi	a5,a5,1
    8000110a:	e785                	bnez	a5,80001132 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000110c:	80b1                	srli	s1,s1,0xc
    8000110e:	04aa                	slli	s1,s1,0xa
    80001110:	0164e4b3          	or	s1,s1,s6
    80001114:	0014e493          	ori	s1,s1,1
    80001118:	e104                	sd	s1,0(a0)
    if(a == last)
    8000111a:	05390063          	beq	s2,s3,8000115a <mappages+0x9c>
    a += PGSIZE;
    8000111e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001120:	bfc9                	j	800010f2 <mappages+0x34>
    panic("mappages: size");
    80001122:	00007517          	auipc	a0,0x7
    80001126:	fc650513          	addi	a0,a0,-58 # 800080e8 <digits+0xa8>
    8000112a:	fffff097          	auipc	ra,0xfffff
    8000112e:	414080e7          	jalr	1044(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001132:	00007517          	auipc	a0,0x7
    80001136:	fc650513          	addi	a0,a0,-58 # 800080f8 <digits+0xb8>
    8000113a:	fffff097          	auipc	ra,0xfffff
    8000113e:	404080e7          	jalr	1028(ra) # 8000053e <panic>
      return -1;
    80001142:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret
  return 0;
    8000115a:	4501                	li	a0,0
    8000115c:	b7e5                	j	80001144 <mappages+0x86>

000000008000115e <kvmmap>:
{
    8000115e:	1141                	addi	sp,sp,-16
    80001160:	e406                	sd	ra,8(sp)
    80001162:	e022                	sd	s0,0(sp)
    80001164:	0800                	addi	s0,sp,16
    80001166:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001168:	86b2                	mv	a3,a2
    8000116a:	863e                	mv	a2,a5
    8000116c:	00000097          	auipc	ra,0x0
    80001170:	f52080e7          	jalr	-174(ra) # 800010be <mappages>
    80001174:	e509                	bnez	a0,8000117e <kvmmap+0x20>
}
    80001176:	60a2                	ld	ra,8(sp)
    80001178:	6402                	ld	s0,0(sp)
    8000117a:	0141                	addi	sp,sp,16
    8000117c:	8082                	ret
    panic("kvmmap");
    8000117e:	00007517          	auipc	a0,0x7
    80001182:	f8a50513          	addi	a0,a0,-118 # 80008108 <digits+0xc8>
    80001186:	fffff097          	auipc	ra,0xfffff
    8000118a:	3b8080e7          	jalr	952(ra) # 8000053e <panic>

000000008000118e <kvmmake>:
{
    8000118e:	1101                	addi	sp,sp,-32
    80001190:	ec06                	sd	ra,24(sp)
    80001192:	e822                	sd	s0,16(sp)
    80001194:	e426                	sd	s1,8(sp)
    80001196:	e04a                	sd	s2,0(sp)
    80001198:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	94c080e7          	jalr	-1716(ra) # 80000ae6 <kalloc>
    800011a2:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a4:	6605                	lui	a2,0x1
    800011a6:	4581                	li	a1,0
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	b2a080e7          	jalr	-1238(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b0:	4719                	li	a4,6
    800011b2:	6685                	lui	a3,0x1
    800011b4:	10000637          	lui	a2,0x10000
    800011b8:	100005b7          	lui	a1,0x10000
    800011bc:	8526                	mv	a0,s1
    800011be:	00000097          	auipc	ra,0x0
    800011c2:	fa0080e7          	jalr	-96(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c6:	4719                	li	a4,6
    800011c8:	6685                	lui	a3,0x1
    800011ca:	10001637          	lui	a2,0x10001
    800011ce:	100015b7          	lui	a1,0x10001
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	f8a080e7          	jalr	-118(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, VIRTIO1, VIRTIO1, PGSIZE, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	6685                	lui	a3,0x1
    800011e0:	10002637          	lui	a2,0x10002
    800011e4:	100025b7          	lui	a1,0x10002
    800011e8:	8526                	mv	a0,s1
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	f74080e7          	jalr	-140(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011f2:	4719                	li	a4,6
    800011f4:	004006b7          	lui	a3,0x400
    800011f8:	0c000637          	lui	a2,0xc000
    800011fc:	0c0005b7          	lui	a1,0xc000
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f5c080e7          	jalr	-164(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000120a:	00007917          	auipc	s2,0x7
    8000120e:	df690913          	addi	s2,s2,-522 # 80008000 <etext>
    80001212:	4729                	li	a4,10
    80001214:	80007697          	auipc	a3,0x80007
    80001218:	dec68693          	addi	a3,a3,-532 # 8000 <_entry-0x7fff8000>
    8000121c:	4605                	li	a2,1
    8000121e:	067e                	slli	a2,a2,0x1f
    80001220:	85b2                	mv	a1,a2
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f3a080e7          	jalr	-198(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000122c:	4719                	li	a4,6
    8000122e:	46c5                	li	a3,17
    80001230:	06ee                	slli	a3,a3,0x1b
    80001232:	412686b3          	sub	a3,a3,s2
    80001236:	864a                	mv	a2,s2
    80001238:	85ca                	mv	a1,s2
    8000123a:	8526                	mv	a0,s1
    8000123c:	00000097          	auipc	ra,0x0
    80001240:	f22080e7          	jalr	-222(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001244:	4729                	li	a4,10
    80001246:	6685                	lui	a3,0x1
    80001248:	00006617          	auipc	a2,0x6
    8000124c:	db860613          	addi	a2,a2,-584 # 80007000 <_trampoline>
    80001250:	040005b7          	lui	a1,0x4000
    80001254:	15fd                	addi	a1,a1,-1
    80001256:	05b2                	slli	a1,a1,0xc
    80001258:	8526                	mv	a0,s1
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f04080e7          	jalr	-252(ra) # 8000115e <kvmmap>
  proc_mapstacks(kpgtbl);
    80001262:	8526                	mv	a0,s1
    80001264:	00000097          	auipc	ra,0x0
    80001268:	60a080e7          	jalr	1546(ra) # 8000186e <proc_mapstacks>
}
    8000126c:	8526                	mv	a0,s1
    8000126e:	60e2                	ld	ra,24(sp)
    80001270:	6442                	ld	s0,16(sp)
    80001272:	64a2                	ld	s1,8(sp)
    80001274:	6902                	ld	s2,0(sp)
    80001276:	6105                	addi	sp,sp,32
    80001278:	8082                	ret

000000008000127a <kvminit>:
{
    8000127a:	1141                	addi	sp,sp,-16
    8000127c:	e406                	sd	ra,8(sp)
    8000127e:	e022                	sd	s0,0(sp)
    80001280:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f0c080e7          	jalr	-244(ra) # 8000118e <kvmmake>
    8000128a:	00008797          	auipc	a5,0x8
    8000128e:	f8a7bb23          	sd	a0,-106(a5) # 80009220 <kernel_pagetable>
}
    80001292:	60a2                	ld	ra,8(sp)
    80001294:	6402                	ld	s0,0(sp)
    80001296:	0141                	addi	sp,sp,16
    80001298:	8082                	ret

000000008000129a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000129a:	711d                	addi	sp,sp,-96
    8000129c:	ec86                	sd	ra,88(sp)
    8000129e:	e8a2                	sd	s0,80(sp)
    800012a0:	e4a6                	sd	s1,72(sp)
    800012a2:	e0ca                	sd	s2,64(sp)
    800012a4:	fc4e                	sd	s3,56(sp)
    800012a6:	f852                	sd	s4,48(sp)
    800012a8:	f456                	sd	s5,40(sp)
    800012aa:	f05a                	sd	s6,32(sp)
    800012ac:	ec5e                	sd	s7,24(sp)
    800012ae:	e862                	sd	s8,16(sp)
    800012b0:	e466                	sd	s9,8(sp)
    800012b2:	1080                	addi	s0,sp,96
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012b4:	03459793          	slli	a5,a1,0x34
    800012b8:	eb95                	bnez	a5,800012ec <uvmunmap+0x52>
    800012ba:	8aaa                	mv	s5,a0
    800012bc:	892e                	mv	s2,a1
    800012be:	8bb6                	mv	s7,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c0:	0632                	slli	a2,a2,0xc
    800012c2:	00b60a33          	add	s4,a2,a1
      continue; // Skip the gap if the page table page itself doesn't exist
    
    if((*pte & PTE_V) == 0)
      continue; // Skip the gap if the entry is not valid (avows "not mapped" panic)

    if(PTE_FLAGS(*pte) == PTE_V)
    800012c6:	4c05                	li	s8,1
      panic("uvmunmap: not a leaf");

    if(do_free){
      uint64 pa = PTE2PA(*pte);
      uint64 fb_start = (uint64)get_fb_addr();
      uint64 fb_end = fb_start + (300 * PGSIZE); // GPU_FB_PAGES = 300
    800012c8:	0012ccb7          	lui	s9,0x12c
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012cc:	6b05                	lui	s6,0x1
    800012ce:	0545e963          	bltu	a1,s4,80001320 <uvmunmap+0x86>
        kfree((void*)pa);
      }
    }
    *pte = 0;
  }
}
    800012d2:	60e6                	ld	ra,88(sp)
    800012d4:	6446                	ld	s0,80(sp)
    800012d6:	64a6                	ld	s1,72(sp)
    800012d8:	6906                	ld	s2,64(sp)
    800012da:	79e2                	ld	s3,56(sp)
    800012dc:	7a42                	ld	s4,48(sp)
    800012de:	7aa2                	ld	s5,40(sp)
    800012e0:	7b02                	ld	s6,32(sp)
    800012e2:	6be2                	ld	s7,24(sp)
    800012e4:	6c42                	ld	s8,16(sp)
    800012e6:	6ca2                	ld	s9,8(sp)
    800012e8:	6125                	addi	sp,sp,96
    800012ea:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e2450513          	addi	a0,a0,-476 # 80008110 <digits+0xd0>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012fc:	00007517          	auipc	a0,0x7
    80001300:	e2c50513          	addi	a0,a0,-468 # 80008128 <digits+0xe8>
    80001304:	fffff097          	auipc	ra,0xfffff
    80001308:	23a080e7          	jalr	570(ra) # 8000053e <panic>
        kfree((void*)pa);
    8000130c:	854e                	mv	a0,s3
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	6dc080e7          	jalr	1756(ra) # 800009ea <kfree>
    *pte = 0;
    80001316:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000131a:	995a                	add	s2,s2,s6
    8000131c:	fb497be3          	bgeu	s2,s4,800012d2 <uvmunmap+0x38>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001320:	4601                	li	a2,0
    80001322:	85ca                	mv	a1,s2
    80001324:	8556                	mv	a0,s5
    80001326:	00000097          	auipc	ra,0x0
    8000132a:	cb0080e7          	jalr	-848(ra) # 80000fd6 <walk>
    8000132e:	84aa                	mv	s1,a0
    80001330:	d56d                	beqz	a0,8000131a <uvmunmap+0x80>
    if((*pte & PTE_V) == 0)
    80001332:	611c                	ld	a5,0(a0)
    80001334:	0017f713          	andi	a4,a5,1
    80001338:	d36d                	beqz	a4,8000131a <uvmunmap+0x80>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000133a:	3ff7f713          	andi	a4,a5,1023
    8000133e:	fb870fe3          	beq	a4,s8,800012fc <uvmunmap+0x62>
    if(do_free){
    80001342:	fc0b8ae3          	beqz	s7,80001316 <uvmunmap+0x7c>
      uint64 pa = PTE2PA(*pte);
    80001346:	83a9                	srli	a5,a5,0xa
    80001348:	00c79993          	slli	s3,a5,0xc
      uint64 fb_start = (uint64)get_fb_addr();
    8000134c:	00005097          	auipc	ra,0x5
    80001350:	6fa080e7          	jalr	1786(ra) # 80006a46 <get_fb_addr>
      if (!(pa >= fb_start && pa < fb_end)) {
    80001354:	faa9ece3          	bltu	s3,a0,8000130c <uvmunmap+0x72>
      uint64 fb_end = fb_start + (300 * PGSIZE); // GPU_FB_PAGES = 300
    80001358:	9566                	add	a0,a0,s9
      if (!(pa >= fb_start && pa < fb_end)) {
    8000135a:	faa9eee3          	bltu	s3,a0,80001316 <uvmunmap+0x7c>
    8000135e:	b77d                	j	8000130c <uvmunmap+0x72>

0000000080001360 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001360:	1101                	addi	sp,sp,-32
    80001362:	ec06                	sd	ra,24(sp)
    80001364:	e822                	sd	s0,16(sp)
    80001366:	e426                	sd	s1,8(sp)
    80001368:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000136a:	fffff097          	auipc	ra,0xfffff
    8000136e:	77c080e7          	jalr	1916(ra) # 80000ae6 <kalloc>
    80001372:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001374:	c519                	beqz	a0,80001382 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001376:	6605                	lui	a2,0x1
    80001378:	4581                	li	a1,0
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	958080e7          	jalr	-1704(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001382:	8526                	mv	a0,s1
    80001384:	60e2                	ld	ra,24(sp)
    80001386:	6442                	ld	s0,16(sp)
    80001388:	64a2                	ld	s1,8(sp)
    8000138a:	6105                	addi	sp,sp,32
    8000138c:	8082                	ret

000000008000138e <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000138e:	7179                	addi	sp,sp,-48
    80001390:	f406                	sd	ra,40(sp)
    80001392:	f022                	sd	s0,32(sp)
    80001394:	ec26                	sd	s1,24(sp)
    80001396:	e84a                	sd	s2,16(sp)
    80001398:	e44e                	sd	s3,8(sp)
    8000139a:	e052                	sd	s4,0(sp)
    8000139c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000139e:	6785                	lui	a5,0x1
    800013a0:	04f67863          	bgeu	a2,a5,800013f0 <uvmfirst+0x62>
    800013a4:	8a2a                	mv	s4,a0
    800013a6:	89ae                	mv	s3,a1
    800013a8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	73c080e7          	jalr	1852(ra) # 80000ae6 <kalloc>
    800013b2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013b4:	6605                	lui	a2,0x1
    800013b6:	4581                	li	a1,0
    800013b8:	00000097          	auipc	ra,0x0
    800013bc:	91a080e7          	jalr	-1766(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013c0:	4779                	li	a4,30
    800013c2:	86ca                	mv	a3,s2
    800013c4:	6605                	lui	a2,0x1
    800013c6:	4581                	li	a1,0
    800013c8:	8552                	mv	a0,s4
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	cf4080e7          	jalr	-780(ra) # 800010be <mappages>
  memmove(mem, src, sz);
    800013d2:	8626                	mv	a2,s1
    800013d4:	85ce                	mv	a1,s3
    800013d6:	854a                	mv	a0,s2
    800013d8:	00000097          	auipc	ra,0x0
    800013dc:	956080e7          	jalr	-1706(ra) # 80000d2e <memmove>
}
    800013e0:	70a2                	ld	ra,40(sp)
    800013e2:	7402                	ld	s0,32(sp)
    800013e4:	64e2                	ld	s1,24(sp)
    800013e6:	6942                	ld	s2,16(sp)
    800013e8:	69a2                	ld	s3,8(sp)
    800013ea:	6a02                	ld	s4,0(sp)
    800013ec:	6145                	addi	sp,sp,48
    800013ee:	8082                	ret
    panic("uvmfirst: more than a page");
    800013f0:	00007517          	auipc	a0,0x7
    800013f4:	d5050513          	addi	a0,a0,-688 # 80008140 <digits+0x100>
    800013f8:	fffff097          	auipc	ra,0xfffff
    800013fc:	146080e7          	jalr	326(ra) # 8000053e <panic>

0000000080001400 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001400:	1101                	addi	sp,sp,-32
    80001402:	ec06                	sd	ra,24(sp)
    80001404:	e822                	sd	s0,16(sp)
    80001406:	e426                	sd	s1,8(sp)
    80001408:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000140a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000140c:	00b67d63          	bgeu	a2,a1,80001426 <uvmdealloc+0x26>
    80001410:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001412:	6785                	lui	a5,0x1
    80001414:	17fd                	addi	a5,a5,-1
    80001416:	00f60733          	add	a4,a2,a5
    8000141a:	767d                	lui	a2,0xfffff
    8000141c:	8f71                	and	a4,a4,a2
    8000141e:	97ae                	add	a5,a5,a1
    80001420:	8ff1                	and	a5,a5,a2
    80001422:	00f76863          	bltu	a4,a5,80001432 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001426:	8526                	mv	a0,s1
    80001428:	60e2                	ld	ra,24(sp)
    8000142a:	6442                	ld	s0,16(sp)
    8000142c:	64a2                	ld	s1,8(sp)
    8000142e:	6105                	addi	sp,sp,32
    80001430:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001432:	8f99                	sub	a5,a5,a4
    80001434:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001436:	4685                	li	a3,1
    80001438:	0007861b          	sext.w	a2,a5
    8000143c:	85ba                	mv	a1,a4
    8000143e:	00000097          	auipc	ra,0x0
    80001442:	e5c080e7          	jalr	-420(ra) # 8000129a <uvmunmap>
    80001446:	b7c5                	j	80001426 <uvmdealloc+0x26>

0000000080001448 <uvmalloc>:
  if(newsz < oldsz)
    80001448:	0ab66563          	bltu	a2,a1,800014f2 <uvmalloc+0xaa>
{
    8000144c:	7139                	addi	sp,sp,-64
    8000144e:	fc06                	sd	ra,56(sp)
    80001450:	f822                	sd	s0,48(sp)
    80001452:	f426                	sd	s1,40(sp)
    80001454:	f04a                	sd	s2,32(sp)
    80001456:	ec4e                	sd	s3,24(sp)
    80001458:	e852                	sd	s4,16(sp)
    8000145a:	e456                	sd	s5,8(sp)
    8000145c:	e05a                	sd	s6,0(sp)
    8000145e:	0080                	addi	s0,sp,64
    80001460:	8aaa                	mv	s5,a0
    80001462:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001464:	6985                	lui	s3,0x1
    80001466:	19fd                	addi	s3,s3,-1
    80001468:	95ce                	add	a1,a1,s3
    8000146a:	79fd                	lui	s3,0xfffff
    8000146c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001470:	08c9f363          	bgeu	s3,a2,800014f6 <uvmalloc+0xae>
    80001474:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000147a:	fffff097          	auipc	ra,0xfffff
    8000147e:	66c080e7          	jalr	1644(ra) # 80000ae6 <kalloc>
    80001482:	84aa                	mv	s1,a0
    if(mem == 0){
    80001484:	c51d                	beqz	a0,800014b2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001486:	6605                	lui	a2,0x1
    80001488:	4581                	li	a1,0
    8000148a:	00000097          	auipc	ra,0x0
    8000148e:	848080e7          	jalr	-1976(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001492:	875a                	mv	a4,s6
    80001494:	86a6                	mv	a3,s1
    80001496:	6605                	lui	a2,0x1
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	c22080e7          	jalr	-990(ra) # 800010be <mappages>
    800014a4:	e90d                	bnez	a0,800014d6 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a6:	6785                	lui	a5,0x1
    800014a8:	993e                	add	s2,s2,a5
    800014aa:	fd4968e3          	bltu	s2,s4,8000147a <uvmalloc+0x32>
  return newsz;
    800014ae:	8552                	mv	a0,s4
    800014b0:	a809                	j	800014c2 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f48080e7          	jalr	-184(ra) # 80001400 <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
}
    800014c2:	70e2                	ld	ra,56(sp)
    800014c4:	7442                	ld	s0,48(sp)
    800014c6:	74a2                	ld	s1,40(sp)
    800014c8:	7902                	ld	s2,32(sp)
    800014ca:	69e2                	ld	s3,24(sp)
    800014cc:	6a42                	ld	s4,16(sp)
    800014ce:	6aa2                	ld	s5,8(sp)
    800014d0:	6b02                	ld	s6,0(sp)
    800014d2:	6121                	addi	sp,sp,64
    800014d4:	8082                	ret
      kfree(mem);
    800014d6:	8526                	mv	a0,s1
    800014d8:	fffff097          	auipc	ra,0xfffff
    800014dc:	512080e7          	jalr	1298(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014e0:	864e                	mv	a2,s3
    800014e2:	85ca                	mv	a1,s2
    800014e4:	8556                	mv	a0,s5
    800014e6:	00000097          	auipc	ra,0x0
    800014ea:	f1a080e7          	jalr	-230(ra) # 80001400 <uvmdealloc>
      return 0;
    800014ee:	4501                	li	a0,0
    800014f0:	bfc9                	j	800014c2 <uvmalloc+0x7a>
    return oldsz;
    800014f2:	852e                	mv	a0,a1
}
    800014f4:	8082                	ret
  return newsz;
    800014f6:	8532                	mv	a0,a2
    800014f8:	b7e9                	j	800014c2 <uvmalloc+0x7a>

00000000800014fa <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014fa:	7179                	addi	sp,sp,-48
    800014fc:	f406                	sd	ra,40(sp)
    800014fe:	f022                	sd	s0,32(sp)
    80001500:	ec26                	sd	s1,24(sp)
    80001502:	e84a                	sd	s2,16(sp)
    80001504:	e44e                	sd	s3,8(sp)
    80001506:	e052                	sd	s4,0(sp)
    80001508:	1800                	addi	s0,sp,48
    8000150a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000150c:	84aa                	mv	s1,a0
    8000150e:	6905                	lui	s2,0x1
    80001510:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	4985                	li	s3,1
    80001514:	a821                	j	8000152c <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001516:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001518:	0532                	slli	a0,a0,0xc
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	fe0080e7          	jalr	-32(ra) # 800014fa <freewalk>
      pagetable[i] = 0;
    80001522:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001526:	04a1                	addi	s1,s1,8
    80001528:	03248163          	beq	s1,s2,8000154a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000152c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000152e:	00f57793          	andi	a5,a0,15
    80001532:	ff3782e3          	beq	a5,s3,80001516 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001536:	8905                	andi	a0,a0,1
    80001538:	d57d                	beqz	a0,80001526 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000153a:	00007517          	auipc	a0,0x7
    8000153e:	c2650513          	addi	a0,a0,-986 # 80008160 <digits+0x120>
    80001542:	fffff097          	auipc	ra,0xfffff
    80001546:	ffc080e7          	jalr	-4(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000154a:	8552                	mv	a0,s4
    8000154c:	fffff097          	auipc	ra,0xfffff
    80001550:	49e080e7          	jalr	1182(ra) # 800009ea <kfree>
}
    80001554:	70a2                	ld	ra,40(sp)
    80001556:	7402                	ld	s0,32(sp)
    80001558:	64e2                	ld	s1,24(sp)
    8000155a:	6942                	ld	s2,16(sp)
    8000155c:	69a2                	ld	s3,8(sp)
    8000155e:	6a02                	ld	s4,0(sp)
    80001560:	6145                	addi	sp,sp,48
    80001562:	8082                	ret

0000000080001564 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001564:	1101                	addi	sp,sp,-32
    80001566:	ec06                	sd	ra,24(sp)
    80001568:	e822                	sd	s0,16(sp)
    8000156a:	e426                	sd	s1,8(sp)
    8000156c:	1000                	addi	s0,sp,32
    8000156e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001570:	e999                	bnez	a1,80001586 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001572:	8526                	mv	a0,s1
    80001574:	00000097          	auipc	ra,0x0
    80001578:	f86080e7          	jalr	-122(ra) # 800014fa <freewalk>
}
    8000157c:	60e2                	ld	ra,24(sp)
    8000157e:	6442                	ld	s0,16(sp)
    80001580:	64a2                	ld	s1,8(sp)
    80001582:	6105                	addi	sp,sp,32
    80001584:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001586:	6605                	lui	a2,0x1
    80001588:	167d                	addi	a2,a2,-1
    8000158a:	962e                	add	a2,a2,a1
    8000158c:	4685                	li	a3,1
    8000158e:	8231                	srli	a2,a2,0xc
    80001590:	4581                	li	a1,0
    80001592:	00000097          	auipc	ra,0x0
    80001596:	d08080e7          	jalr	-760(ra) # 8000129a <uvmunmap>
    8000159a:	bfe1                	j	80001572 <uvmfree+0xe>

000000008000159c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000159c:	c679                	beqz	a2,8000166a <uvmcopy+0xce>
{
    8000159e:	715d                	addi	sp,sp,-80
    800015a0:	e486                	sd	ra,72(sp)
    800015a2:	e0a2                	sd	s0,64(sp)
    800015a4:	fc26                	sd	s1,56(sp)
    800015a6:	f84a                	sd	s2,48(sp)
    800015a8:	f44e                	sd	s3,40(sp)
    800015aa:	f052                	sd	s4,32(sp)
    800015ac:	ec56                	sd	s5,24(sp)
    800015ae:	e85a                	sd	s6,16(sp)
    800015b0:	e45e                	sd	s7,8(sp)
    800015b2:	0880                	addi	s0,sp,80
    800015b4:	8b2a                	mv	s6,a0
    800015b6:	8aae                	mv	s5,a1
    800015b8:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015ba:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015bc:	4601                	li	a2,0
    800015be:	85ce                	mv	a1,s3
    800015c0:	855a                	mv	a0,s6
    800015c2:	00000097          	auipc	ra,0x0
    800015c6:	a14080e7          	jalr	-1516(ra) # 80000fd6 <walk>
    800015ca:	c531                	beqz	a0,80001616 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015cc:	6118                	ld	a4,0(a0)
    800015ce:	00177793          	andi	a5,a4,1
    800015d2:	cbb1                	beqz	a5,80001626 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015d4:	00a75593          	srli	a1,a4,0xa
    800015d8:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015dc:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015e0:	fffff097          	auipc	ra,0xfffff
    800015e4:	506080e7          	jalr	1286(ra) # 80000ae6 <kalloc>
    800015e8:	892a                	mv	s2,a0
    800015ea:	c939                	beqz	a0,80001640 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015ec:	6605                	lui	a2,0x1
    800015ee:	85de                	mv	a1,s7
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	73e080e7          	jalr	1854(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015f8:	8726                	mv	a4,s1
    800015fa:	86ca                	mv	a3,s2
    800015fc:	6605                	lui	a2,0x1
    800015fe:	85ce                	mv	a1,s3
    80001600:	8556                	mv	a0,s5
    80001602:	00000097          	auipc	ra,0x0
    80001606:	abc080e7          	jalr	-1348(ra) # 800010be <mappages>
    8000160a:	e515                	bnez	a0,80001636 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000160c:	6785                	lui	a5,0x1
    8000160e:	99be                	add	s3,s3,a5
    80001610:	fb49e6e3          	bltu	s3,s4,800015bc <uvmcopy+0x20>
    80001614:	a081                	j	80001654 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001616:	00007517          	auipc	a0,0x7
    8000161a:	b5a50513          	addi	a0,a0,-1190 # 80008170 <digits+0x130>
    8000161e:	fffff097          	auipc	ra,0xfffff
    80001622:	f20080e7          	jalr	-224(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001626:	00007517          	auipc	a0,0x7
    8000162a:	b6a50513          	addi	a0,a0,-1174 # 80008190 <digits+0x150>
    8000162e:	fffff097          	auipc	ra,0xfffff
    80001632:	f10080e7          	jalr	-240(ra) # 8000053e <panic>
      kfree(mem);
    80001636:	854a                	mv	a0,s2
    80001638:	fffff097          	auipc	ra,0xfffff
    8000163c:	3b2080e7          	jalr	946(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001640:	4685                	li	a3,1
    80001642:	00c9d613          	srli	a2,s3,0xc
    80001646:	4581                	li	a1,0
    80001648:	8556                	mv	a0,s5
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	c50080e7          	jalr	-944(ra) # 8000129a <uvmunmap>
  return -1;
    80001652:	557d                	li	a0,-1
}
    80001654:	60a6                	ld	ra,72(sp)
    80001656:	6406                	ld	s0,64(sp)
    80001658:	74e2                	ld	s1,56(sp)
    8000165a:	7942                	ld	s2,48(sp)
    8000165c:	79a2                	ld	s3,40(sp)
    8000165e:	7a02                	ld	s4,32(sp)
    80001660:	6ae2                	ld	s5,24(sp)
    80001662:	6b42                	ld	s6,16(sp)
    80001664:	6ba2                	ld	s7,8(sp)
    80001666:	6161                	addi	sp,sp,80
    80001668:	8082                	ret
  return 0;
    8000166a:	4501                	li	a0,0
}
    8000166c:	8082                	ret

000000008000166e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000166e:	1141                	addi	sp,sp,-16
    80001670:	e406                	sd	ra,8(sp)
    80001672:	e022                	sd	s0,0(sp)
    80001674:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001676:	4601                	li	a2,0
    80001678:	00000097          	auipc	ra,0x0
    8000167c:	95e080e7          	jalr	-1698(ra) # 80000fd6 <walk>
  if(pte == 0)
    80001680:	c901                	beqz	a0,80001690 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001682:	611c                	ld	a5,0(a0)
    80001684:	9bbd                	andi	a5,a5,-17
    80001686:	e11c                	sd	a5,0(a0)
}
    80001688:	60a2                	ld	ra,8(sp)
    8000168a:	6402                	ld	s0,0(sp)
    8000168c:	0141                	addi	sp,sp,16
    8000168e:	8082                	ret
    panic("uvmclear");
    80001690:	00007517          	auipc	a0,0x7
    80001694:	b2050513          	addi	a0,a0,-1248 # 800081b0 <digits+0x170>
    80001698:	fffff097          	auipc	ra,0xfffff
    8000169c:	ea6080e7          	jalr	-346(ra) # 8000053e <panic>

00000000800016a0 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016a0:	c6bd                	beqz	a3,8000170e <copyout+0x6e>
{
    800016a2:	715d                	addi	sp,sp,-80
    800016a4:	e486                	sd	ra,72(sp)
    800016a6:	e0a2                	sd	s0,64(sp)
    800016a8:	fc26                	sd	s1,56(sp)
    800016aa:	f84a                	sd	s2,48(sp)
    800016ac:	f44e                	sd	s3,40(sp)
    800016ae:	f052                	sd	s4,32(sp)
    800016b0:	ec56                	sd	s5,24(sp)
    800016b2:	e85a                	sd	s6,16(sp)
    800016b4:	e45e                	sd	s7,8(sp)
    800016b6:	e062                	sd	s8,0(sp)
    800016b8:	0880                	addi	s0,sp,80
    800016ba:	8b2a                	mv	s6,a0
    800016bc:	8c2e                	mv	s8,a1
    800016be:	8a32                	mv	s4,a2
    800016c0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016c2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016c4:	6a85                	lui	s5,0x1
    800016c6:	a015                	j	800016ea <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016c8:	9562                	add	a0,a0,s8
    800016ca:	0004861b          	sext.w	a2,s1
    800016ce:	85d2                	mv	a1,s4
    800016d0:	41250533          	sub	a0,a0,s2
    800016d4:	fffff097          	auipc	ra,0xfffff
    800016d8:	65a080e7          	jalr	1626(ra) # 80000d2e <memmove>

    len -= n;
    800016dc:	409989b3          	sub	s3,s3,s1
    src += n;
    800016e0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016e2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016e6:	02098263          	beqz	s3,8000170a <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ea:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ee:	85ca                	mv	a1,s2
    800016f0:	855a                	mv	a0,s6
    800016f2:	00000097          	auipc	ra,0x0
    800016f6:	98a080e7          	jalr	-1654(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    800016fa:	cd01                	beqz	a0,80001712 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016fc:	418904b3          	sub	s1,s2,s8
    80001700:	94d6                	add	s1,s1,s5
    if(n > len)
    80001702:	fc99f3e3          	bgeu	s3,s1,800016c8 <copyout+0x28>
    80001706:	84ce                	mv	s1,s3
    80001708:	b7c1                	j	800016c8 <copyout+0x28>
  }
  return 0;
    8000170a:	4501                	li	a0,0
    8000170c:	a021                	j	80001714 <copyout+0x74>
    8000170e:	4501                	li	a0,0
}
    80001710:	8082                	ret
      return -1;
    80001712:	557d                	li	a0,-1
}
    80001714:	60a6                	ld	ra,72(sp)
    80001716:	6406                	ld	s0,64(sp)
    80001718:	74e2                	ld	s1,56(sp)
    8000171a:	7942                	ld	s2,48(sp)
    8000171c:	79a2                	ld	s3,40(sp)
    8000171e:	7a02                	ld	s4,32(sp)
    80001720:	6ae2                	ld	s5,24(sp)
    80001722:	6b42                	ld	s6,16(sp)
    80001724:	6ba2                	ld	s7,8(sp)
    80001726:	6c02                	ld	s8,0(sp)
    80001728:	6161                	addi	sp,sp,80
    8000172a:	8082                	ret

000000008000172c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000172c:	caa5                	beqz	a3,8000179c <copyin+0x70>
{
    8000172e:	715d                	addi	sp,sp,-80
    80001730:	e486                	sd	ra,72(sp)
    80001732:	e0a2                	sd	s0,64(sp)
    80001734:	fc26                	sd	s1,56(sp)
    80001736:	f84a                	sd	s2,48(sp)
    80001738:	f44e                	sd	s3,40(sp)
    8000173a:	f052                	sd	s4,32(sp)
    8000173c:	ec56                	sd	s5,24(sp)
    8000173e:	e85a                	sd	s6,16(sp)
    80001740:	e45e                	sd	s7,8(sp)
    80001742:	e062                	sd	s8,0(sp)
    80001744:	0880                	addi	s0,sp,80
    80001746:	8b2a                	mv	s6,a0
    80001748:	8a2e                	mv	s4,a1
    8000174a:	8c32                	mv	s8,a2
    8000174c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000174e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001750:	6a85                	lui	s5,0x1
    80001752:	a01d                	j	80001778 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001754:	018505b3          	add	a1,a0,s8
    80001758:	0004861b          	sext.w	a2,s1
    8000175c:	412585b3          	sub	a1,a1,s2
    80001760:	8552                	mv	a0,s4
    80001762:	fffff097          	auipc	ra,0xfffff
    80001766:	5cc080e7          	jalr	1484(ra) # 80000d2e <memmove>

    len -= n;
    8000176a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000176e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001770:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001774:	02098263          	beqz	s3,80001798 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001778:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000177c:	85ca                	mv	a1,s2
    8000177e:	855a                	mv	a0,s6
    80001780:	00000097          	auipc	ra,0x0
    80001784:	8fc080e7          	jalr	-1796(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    80001788:	cd01                	beqz	a0,800017a0 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000178a:	418904b3          	sub	s1,s2,s8
    8000178e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001790:	fc99f2e3          	bgeu	s3,s1,80001754 <copyin+0x28>
    80001794:	84ce                	mv	s1,s3
    80001796:	bf7d                	j	80001754 <copyin+0x28>
  }
  return 0;
    80001798:	4501                	li	a0,0
    8000179a:	a021                	j	800017a2 <copyin+0x76>
    8000179c:	4501                	li	a0,0
}
    8000179e:	8082                	ret
      return -1;
    800017a0:	557d                	li	a0,-1
}
    800017a2:	60a6                	ld	ra,72(sp)
    800017a4:	6406                	ld	s0,64(sp)
    800017a6:	74e2                	ld	s1,56(sp)
    800017a8:	7942                	ld	s2,48(sp)
    800017aa:	79a2                	ld	s3,40(sp)
    800017ac:	7a02                	ld	s4,32(sp)
    800017ae:	6ae2                	ld	s5,24(sp)
    800017b0:	6b42                	ld	s6,16(sp)
    800017b2:	6ba2                	ld	s7,8(sp)
    800017b4:	6c02                	ld	s8,0(sp)
    800017b6:	6161                	addi	sp,sp,80
    800017b8:	8082                	ret

00000000800017ba <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017ba:	c6c5                	beqz	a3,80001862 <copyinstr+0xa8>
{
    800017bc:	715d                	addi	sp,sp,-80
    800017be:	e486                	sd	ra,72(sp)
    800017c0:	e0a2                	sd	s0,64(sp)
    800017c2:	fc26                	sd	s1,56(sp)
    800017c4:	f84a                	sd	s2,48(sp)
    800017c6:	f44e                	sd	s3,40(sp)
    800017c8:	f052                	sd	s4,32(sp)
    800017ca:	ec56                	sd	s5,24(sp)
    800017cc:	e85a                	sd	s6,16(sp)
    800017ce:	e45e                	sd	s7,8(sp)
    800017d0:	0880                	addi	s0,sp,80
    800017d2:	8a2a                	mv	s4,a0
    800017d4:	8b2e                	mv	s6,a1
    800017d6:	8bb2                	mv	s7,a2
    800017d8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017da:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017dc:	6985                	lui	s3,0x1
    800017de:	a035                	j	8000180a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017e0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017e4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017e6:	0017b793          	seqz	a5,a5
    800017ea:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017ee:	60a6                	ld	ra,72(sp)
    800017f0:	6406                	ld	s0,64(sp)
    800017f2:	74e2                	ld	s1,56(sp)
    800017f4:	7942                	ld	s2,48(sp)
    800017f6:	79a2                	ld	s3,40(sp)
    800017f8:	7a02                	ld	s4,32(sp)
    800017fa:	6ae2                	ld	s5,24(sp)
    800017fc:	6b42                	ld	s6,16(sp)
    800017fe:	6ba2                	ld	s7,8(sp)
    80001800:	6161                	addi	sp,sp,80
    80001802:	8082                	ret
    srcva = va0 + PGSIZE;
    80001804:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001808:	c8a9                	beqz	s1,8000185a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000180a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000180e:	85ca                	mv	a1,s2
    80001810:	8552                	mv	a0,s4
    80001812:	00000097          	auipc	ra,0x0
    80001816:	86a080e7          	jalr	-1942(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    8000181a:	c131                	beqz	a0,8000185e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000181c:	41790833          	sub	a6,s2,s7
    80001820:	984e                	add	a6,a6,s3
    if(n > max)
    80001822:	0104f363          	bgeu	s1,a6,80001828 <copyinstr+0x6e>
    80001826:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001828:	955e                	add	a0,a0,s7
    8000182a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000182e:	fc080be3          	beqz	a6,80001804 <copyinstr+0x4a>
    80001832:	985a                	add	a6,a6,s6
    80001834:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001836:	41650633          	sub	a2,a0,s6
    8000183a:	14fd                	addi	s1,s1,-1
    8000183c:	9b26                	add	s6,s6,s1
    8000183e:	00f60733          	add	a4,a2,a5
    80001842:	00074703          	lbu	a4,0(a4)
    80001846:	df49                	beqz	a4,800017e0 <copyinstr+0x26>
        *dst = *p;
    80001848:	00e78023          	sb	a4,0(a5)
      --max;
    8000184c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001850:	0785                	addi	a5,a5,1
    while(n > 0){
    80001852:	ff0796e3          	bne	a5,a6,8000183e <copyinstr+0x84>
      dst++;
    80001856:	8b42                	mv	s6,a6
    80001858:	b775                	j	80001804 <copyinstr+0x4a>
    8000185a:	4781                	li	a5,0
    8000185c:	b769                	j	800017e6 <copyinstr+0x2c>
      return -1;
    8000185e:	557d                	li	a0,-1
    80001860:	b779                	j	800017ee <copyinstr+0x34>
  int got_null = 0;
    80001862:	4781                	li	a5,0
  if(got_null){
    80001864:	0017b793          	seqz	a5,a5
    80001868:	40f00533          	neg	a0,a5
}
    8000186c:	8082                	ret

000000008000186e <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000186e:	7139                	addi	sp,sp,-64
    80001870:	fc06                	sd	ra,56(sp)
    80001872:	f822                	sd	s0,48(sp)
    80001874:	f426                	sd	s1,40(sp)
    80001876:	f04a                	sd	s2,32(sp)
    80001878:	ec4e                	sd	s3,24(sp)
    8000187a:	e852                	sd	s4,16(sp)
    8000187c:	e456                	sd	s5,8(sp)
    8000187e:	e05a                	sd	s6,0(sp)
    80001880:	0080                	addi	s0,sp,64
    80001882:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001884:	00010497          	auipc	s1,0x10
    80001888:	04c48493          	addi	s1,s1,76 # 800118d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000188c:	8b26                	mv	s6,s1
    8000188e:	00006a97          	auipc	s5,0x6
    80001892:	772a8a93          	addi	s5,s5,1906 # 80008000 <etext>
    80001896:	04000937          	lui	s2,0x4000
    8000189a:	197d                	addi	s2,s2,-1
    8000189c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000189e:	00016a17          	auipc	s4,0x16
    800018a2:	a32a0a13          	addi	s4,s4,-1486 # 800172d0 <tickslock>
    char *pa = kalloc();
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	240080e7          	jalr	576(ra) # 80000ae6 <kalloc>
    800018ae:	862a                	mv	a2,a0
    if(pa == 0)
    800018b0:	c131                	beqz	a0,800018f4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018b2:	416485b3          	sub	a1,s1,s6
    800018b6:	858d                	srai	a1,a1,0x3
    800018b8:	000ab783          	ld	a5,0(s5)
    800018bc:	02f585b3          	mul	a1,a1,a5
    800018c0:	2585                	addiw	a1,a1,1
    800018c2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018c6:	4719                	li	a4,6
    800018c8:	6685                	lui	a3,0x1
    800018ca:	40b905b3          	sub	a1,s2,a1
    800018ce:	854e                	mv	a0,s3
    800018d0:	00000097          	auipc	ra,0x0
    800018d4:	88e080e7          	jalr	-1906(ra) # 8000115e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d8:	16848493          	addi	s1,s1,360
    800018dc:	fd4495e3          	bne	s1,s4,800018a6 <proc_mapstacks+0x38>
  }
}
    800018e0:	70e2                	ld	ra,56(sp)
    800018e2:	7442                	ld	s0,48(sp)
    800018e4:	74a2                	ld	s1,40(sp)
    800018e6:	7902                	ld	s2,32(sp)
    800018e8:	69e2                	ld	s3,24(sp)
    800018ea:	6a42                	ld	s4,16(sp)
    800018ec:	6aa2                	ld	s5,8(sp)
    800018ee:	6b02                	ld	s6,0(sp)
    800018f0:	6121                	addi	sp,sp,64
    800018f2:	8082                	ret
      panic("kalloc");
    800018f4:	00007517          	auipc	a0,0x7
    800018f8:	8cc50513          	addi	a0,a0,-1844 # 800081c0 <digits+0x180>
    800018fc:	fffff097          	auipc	ra,0xfffff
    80001900:	c42080e7          	jalr	-958(ra) # 8000053e <panic>

0000000080001904 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001904:	7139                	addi	sp,sp,-64
    80001906:	fc06                	sd	ra,56(sp)
    80001908:	f822                	sd	s0,48(sp)
    8000190a:	f426                	sd	s1,40(sp)
    8000190c:	f04a                	sd	s2,32(sp)
    8000190e:	ec4e                	sd	s3,24(sp)
    80001910:	e852                	sd	s4,16(sp)
    80001912:	e456                	sd	s5,8(sp)
    80001914:	e05a                	sd	s6,0(sp)
    80001916:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001918:	00007597          	auipc	a1,0x7
    8000191c:	8b058593          	addi	a1,a1,-1872 # 800081c8 <digits+0x188>
    80001920:	00010517          	auipc	a0,0x10
    80001924:	b8050513          	addi	a0,a0,-1152 # 800114a0 <pid_lock>
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	21e080e7          	jalr	542(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001930:	00007597          	auipc	a1,0x7
    80001934:	8a058593          	addi	a1,a1,-1888 # 800081d0 <digits+0x190>
    80001938:	00010517          	auipc	a0,0x10
    8000193c:	b8050513          	addi	a0,a0,-1152 # 800114b8 <wait_lock>
    80001940:	fffff097          	auipc	ra,0xfffff
    80001944:	206080e7          	jalr	518(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001948:	00010497          	auipc	s1,0x10
    8000194c:	f8848493          	addi	s1,s1,-120 # 800118d0 <proc>
      initlock(&p->lock, "proc");
    80001950:	00007b17          	auipc	s6,0x7
    80001954:	890b0b13          	addi	s6,s6,-1904 # 800081e0 <digits+0x1a0>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001958:	8aa6                	mv	s5,s1
    8000195a:	00006a17          	auipc	s4,0x6
    8000195e:	6a6a0a13          	addi	s4,s4,1702 # 80008000 <etext>
    80001962:	04000937          	lui	s2,0x4000
    80001966:	197d                	addi	s2,s2,-1
    80001968:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196a:	00016997          	auipc	s3,0x16
    8000196e:	96698993          	addi	s3,s3,-1690 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    80001972:	85da                	mv	a1,s6
    80001974:	8526                	mv	a0,s1
    80001976:	fffff097          	auipc	ra,0xfffff
    8000197a:	1d0080e7          	jalr	464(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    8000197e:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001982:	415487b3          	sub	a5,s1,s5
    80001986:	878d                	srai	a5,a5,0x3
    80001988:	000a3703          	ld	a4,0(s4)
    8000198c:	02e787b3          	mul	a5,a5,a4
    80001990:	2785                	addiw	a5,a5,1
    80001992:	00d7979b          	slliw	a5,a5,0xd
    80001996:	40f907b3          	sub	a5,s2,a5
    8000199a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000199c:	16848493          	addi	s1,s1,360
    800019a0:	fd3499e3          	bne	s1,s3,80001972 <procinit+0x6e>
  }
}
    800019a4:	70e2                	ld	ra,56(sp)
    800019a6:	7442                	ld	s0,48(sp)
    800019a8:	74a2                	ld	s1,40(sp)
    800019aa:	7902                	ld	s2,32(sp)
    800019ac:	69e2                	ld	s3,24(sp)
    800019ae:	6a42                	ld	s4,16(sp)
    800019b0:	6aa2                	ld	s5,8(sp)
    800019b2:	6b02                	ld	s6,0(sp)
    800019b4:	6121                	addi	sp,sp,64
    800019b6:	8082                	ret

00000000800019b8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019b8:	1141                	addi	sp,sp,-16
    800019ba:	e422                	sd	s0,8(sp)
    800019bc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019be:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019c0:	2501                	sext.w	a0,a0
    800019c2:	6422                	ld	s0,8(sp)
    800019c4:	0141                	addi	sp,sp,16
    800019c6:	8082                	ret

00000000800019c8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019c8:	1141                	addi	sp,sp,-16
    800019ca:	e422                	sd	s0,8(sp)
    800019cc:	0800                	addi	s0,sp,16
    800019ce:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019d0:	2781                	sext.w	a5,a5
    800019d2:	079e                	slli	a5,a5,0x7
  return c;
}
    800019d4:	00010517          	auipc	a0,0x10
    800019d8:	afc50513          	addi	a0,a0,-1284 # 800114d0 <cpus>
    800019dc:	953e                	add	a0,a0,a5
    800019de:	6422                	ld	s0,8(sp)
    800019e0:	0141                	addi	sp,sp,16
    800019e2:	8082                	ret

00000000800019e4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019e4:	1101                	addi	sp,sp,-32
    800019e6:	ec06                	sd	ra,24(sp)
    800019e8:	e822                	sd	s0,16(sp)
    800019ea:	e426                	sd	s1,8(sp)
    800019ec:	1000                	addi	s0,sp,32
  push_off();
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	19c080e7          	jalr	412(ra) # 80000b8a <push_off>
    800019f6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019f8:	2781                	sext.w	a5,a5
    800019fa:	079e                	slli	a5,a5,0x7
    800019fc:	00010717          	auipc	a4,0x10
    80001a00:	aa470713          	addi	a4,a4,-1372 # 800114a0 <pid_lock>
    80001a04:	97ba                	add	a5,a5,a4
    80001a06:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	222080e7          	jalr	546(ra) # 80000c2a <pop_off>
  return p;
}
    80001a10:	8526                	mv	a0,s1
    80001a12:	60e2                	ld	ra,24(sp)
    80001a14:	6442                	ld	s0,16(sp)
    80001a16:	64a2                	ld	s1,8(sp)
    80001a18:	6105                	addi	sp,sp,32
    80001a1a:	8082                	ret

0000000080001a1c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a1c:	1141                	addi	sp,sp,-16
    80001a1e:	e406                	sd	ra,8(sp)
    80001a20:	e022                	sd	s0,0(sp)
    80001a22:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a24:	00000097          	auipc	ra,0x0
    80001a28:	fc0080e7          	jalr	-64(ra) # 800019e4 <myproc>
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	25e080e7          	jalr	606(ra) # 80000c8a <release>

  if (first) {
    80001a34:	00007797          	auipc	a5,0x7
    80001a38:	75c7a783          	lw	a5,1884(a5) # 80009190 <first.1>
    80001a3c:	eb89                	bnez	a5,80001a4e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a3e:	00001097          	auipc	ra,0x1
    80001a42:	d74080e7          	jalr	-652(ra) # 800027b2 <usertrapret>
}
    80001a46:	60a2                	ld	ra,8(sp)
    80001a48:	6402                	ld	s0,0(sp)
    80001a4a:	0141                	addi	sp,sp,16
    80001a4c:	8082                	ret
    first = 0;
    80001a4e:	00007797          	auipc	a5,0x7
    80001a52:	7407a123          	sw	zero,1858(a5) # 80009190 <first.1>
    fsinit(ROOTDEV);
    80001a56:	4505                	li	a0,1
    80001a58:	00002097          	auipc	ra,0x2
    80001a5c:	ae2080e7          	jalr	-1310(ra) # 8000353a <fsinit>
    80001a60:	bff9                	j	80001a3e <forkret+0x22>

0000000080001a62 <allocpid>:
{
    80001a62:	1101                	addi	sp,sp,-32
    80001a64:	ec06                	sd	ra,24(sp)
    80001a66:	e822                	sd	s0,16(sp)
    80001a68:	e426                	sd	s1,8(sp)
    80001a6a:	e04a                	sd	s2,0(sp)
    80001a6c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a6e:	00010917          	auipc	s2,0x10
    80001a72:	a3290913          	addi	s2,s2,-1486 # 800114a0 <pid_lock>
    80001a76:	854a                	mv	a0,s2
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	15e080e7          	jalr	350(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a80:	00007797          	auipc	a5,0x7
    80001a84:	71478793          	addi	a5,a5,1812 # 80009194 <nextpid>
    80001a88:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a8a:	0014871b          	addiw	a4,s1,1
    80001a8e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a90:	854a                	mv	a0,s2
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	1f8080e7          	jalr	504(ra) # 80000c8a <release>
}
    80001a9a:	8526                	mv	a0,s1
    80001a9c:	60e2                	ld	ra,24(sp)
    80001a9e:	6442                	ld	s0,16(sp)
    80001aa0:	64a2                	ld	s1,8(sp)
    80001aa2:	6902                	ld	s2,0(sp)
    80001aa4:	6105                	addi	sp,sp,32
    80001aa6:	8082                	ret

0000000080001aa8 <proc_pagetable>:
{
    80001aa8:	1101                	addi	sp,sp,-32
    80001aaa:	ec06                	sd	ra,24(sp)
    80001aac:	e822                	sd	s0,16(sp)
    80001aae:	e426                	sd	s1,8(sp)
    80001ab0:	e04a                	sd	s2,0(sp)
    80001ab2:	1000                	addi	s0,sp,32
    80001ab4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ab6:	00000097          	auipc	ra,0x0
    80001aba:	8aa080e7          	jalr	-1878(ra) # 80001360 <uvmcreate>
    80001abe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ac0:	c121                	beqz	a0,80001b00 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ac2:	4729                	li	a4,10
    80001ac4:	00005697          	auipc	a3,0x5
    80001ac8:	53c68693          	addi	a3,a3,1340 # 80007000 <_trampoline>
    80001acc:	6605                	lui	a2,0x1
    80001ace:	040005b7          	lui	a1,0x4000
    80001ad2:	15fd                	addi	a1,a1,-1
    80001ad4:	05b2                	slli	a1,a1,0xc
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e8080e7          	jalr	1512(ra) # 800010be <mappages>
    80001ade:	02054863          	bltz	a0,80001b0e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ae2:	4719                	li	a4,6
    80001ae4:	05893683          	ld	a3,88(s2)
    80001ae8:	6605                	lui	a2,0x1
    80001aea:	020005b7          	lui	a1,0x2000
    80001aee:	15fd                	addi	a1,a1,-1
    80001af0:	05b6                	slli	a1,a1,0xd
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	5ca080e7          	jalr	1482(ra) # 800010be <mappages>
    80001afc:	02054163          	bltz	a0,80001b1e <proc_pagetable+0x76>
}
    80001b00:	8526                	mv	a0,s1
    80001b02:	60e2                	ld	ra,24(sp)
    80001b04:	6442                	ld	s0,16(sp)
    80001b06:	64a2                	ld	s1,8(sp)
    80001b08:	6902                	ld	s2,0(sp)
    80001b0a:	6105                	addi	sp,sp,32
    80001b0c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b0e:	4581                	li	a1,0
    80001b10:	8526                	mv	a0,s1
    80001b12:	00000097          	auipc	ra,0x0
    80001b16:	a52080e7          	jalr	-1454(ra) # 80001564 <uvmfree>
    return 0;
    80001b1a:	4481                	li	s1,0
    80001b1c:	b7d5                	j	80001b00 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1e:	4681                	li	a3,0
    80001b20:	4605                	li	a2,1
    80001b22:	040005b7          	lui	a1,0x4000
    80001b26:	15fd                	addi	a1,a1,-1
    80001b28:	05b2                	slli	a1,a1,0xc
    80001b2a:	8526                	mv	a0,s1
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	76e080e7          	jalr	1902(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80001b34:	4581                	li	a1,0
    80001b36:	8526                	mv	a0,s1
    80001b38:	00000097          	auipc	ra,0x0
    80001b3c:	a2c080e7          	jalr	-1492(ra) # 80001564 <uvmfree>
    return 0;
    80001b40:	4481                	li	s1,0
    80001b42:	bf7d                	j	80001b00 <proc_pagetable+0x58>

0000000080001b44 <proc_freepagetable>:
{
    80001b44:	1101                	addi	sp,sp,-32
    80001b46:	ec06                	sd	ra,24(sp)
    80001b48:	e822                	sd	s0,16(sp)
    80001b4a:	e426                	sd	s1,8(sp)
    80001b4c:	e04a                	sd	s2,0(sp)
    80001b4e:	1000                	addi	s0,sp,32
    80001b50:	84aa                	mv	s1,a0
    80001b52:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b54:	4681                	li	a3,0
    80001b56:	4605                	li	a2,1
    80001b58:	040005b7          	lui	a1,0x4000
    80001b5c:	15fd                	addi	a1,a1,-1
    80001b5e:	05b2                	slli	a1,a1,0xc
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	73a080e7          	jalr	1850(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b68:	4681                	li	a3,0
    80001b6a:	4605                	li	a2,1
    80001b6c:	020005b7          	lui	a1,0x2000
    80001b70:	15fd                	addi	a1,a1,-1
    80001b72:	05b6                	slli	a1,a1,0xd
    80001b74:	8526                	mv	a0,s1
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	724080e7          	jalr	1828(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b7e:	85ca                	mv	a1,s2
    80001b80:	8526                	mv	a0,s1
    80001b82:	00000097          	auipc	ra,0x0
    80001b86:	9e2080e7          	jalr	-1566(ra) # 80001564 <uvmfree>
}
    80001b8a:	60e2                	ld	ra,24(sp)
    80001b8c:	6442                	ld	s0,16(sp)
    80001b8e:	64a2                	ld	s1,8(sp)
    80001b90:	6902                	ld	s2,0(sp)
    80001b92:	6105                	addi	sp,sp,32
    80001b94:	8082                	ret

0000000080001b96 <freeproc>:
{
    80001b96:	1101                	addi	sp,sp,-32
    80001b98:	ec06                	sd	ra,24(sp)
    80001b9a:	e822                	sd	s0,16(sp)
    80001b9c:	e426                	sd	s1,8(sp)
    80001b9e:	1000                	addi	s0,sp,32
    80001ba0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ba2:	6d28                	ld	a0,88(a0)
    80001ba4:	c509                	beqz	a0,80001bae <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	e44080e7          	jalr	-444(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001bae:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bb2:	68a8                	ld	a0,80(s1)
    80001bb4:	c511                	beqz	a0,80001bc0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bb6:	64ac                	ld	a1,72(s1)
    80001bb8:	00000097          	auipc	ra,0x0
    80001bbc:	f8c080e7          	jalr	-116(ra) # 80001b44 <proc_freepagetable>
  p->pagetable = 0;
    80001bc0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bc4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bc8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bcc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bd0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bd4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bd8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bdc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001be0:	0004ac23          	sw	zero,24(s1)
}
    80001be4:	60e2                	ld	ra,24(sp)
    80001be6:	6442                	ld	s0,16(sp)
    80001be8:	64a2                	ld	s1,8(sp)
    80001bea:	6105                	addi	sp,sp,32
    80001bec:	8082                	ret

0000000080001bee <allocproc>:
{
    80001bee:	1101                	addi	sp,sp,-32
    80001bf0:	ec06                	sd	ra,24(sp)
    80001bf2:	e822                	sd	s0,16(sp)
    80001bf4:	e426                	sd	s1,8(sp)
    80001bf6:	e04a                	sd	s2,0(sp)
    80001bf8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfa:	00010497          	auipc	s1,0x10
    80001bfe:	cd648493          	addi	s1,s1,-810 # 800118d0 <proc>
    80001c02:	00015917          	auipc	s2,0x15
    80001c06:	6ce90913          	addi	s2,s2,1742 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	fca080e7          	jalr	-54(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001c14:	4c9c                	lw	a5,24(s1)
    80001c16:	cf81                	beqz	a5,80001c2e <allocproc+0x40>
      release(&p->lock);
    80001c18:	8526                	mv	a0,s1
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	070080e7          	jalr	112(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c22:	16848493          	addi	s1,s1,360
    80001c26:	ff2492e3          	bne	s1,s2,80001c0a <allocproc+0x1c>
  return 0;
    80001c2a:	4481                	li	s1,0
    80001c2c:	a889                	j	80001c7e <allocproc+0x90>
  p->pid = allocpid();
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	e34080e7          	jalr	-460(ra) # 80001a62 <allocpid>
    80001c36:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c38:	4785                	li	a5,1
    80001c3a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	eaa080e7          	jalr	-342(ra) # 80000ae6 <kalloc>
    80001c44:	892a                	mv	s2,a0
    80001c46:	eca8                	sd	a0,88(s1)
    80001c48:	c131                	beqz	a0,80001c8c <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	e5c080e7          	jalr	-420(ra) # 80001aa8 <proc_pagetable>
    80001c54:	892a                	mv	s2,a0
    80001c56:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c58:	c531                	beqz	a0,80001ca4 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c5a:	07000613          	li	a2,112
    80001c5e:	4581                	li	a1,0
    80001c60:	06048513          	addi	a0,s1,96
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	06e080e7          	jalr	110(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c6c:	00000797          	auipc	a5,0x0
    80001c70:	db078793          	addi	a5,a5,-592 # 80001a1c <forkret>
    80001c74:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c76:	60bc                	ld	a5,64(s1)
    80001c78:	6705                	lui	a4,0x1
    80001c7a:	97ba                	add	a5,a5,a4
    80001c7c:	f4bc                	sd	a5,104(s1)
}
    80001c7e:	8526                	mv	a0,s1
    80001c80:	60e2                	ld	ra,24(sp)
    80001c82:	6442                	ld	s0,16(sp)
    80001c84:	64a2                	ld	s1,8(sp)
    80001c86:	6902                	ld	s2,0(sp)
    80001c88:	6105                	addi	sp,sp,32
    80001c8a:	8082                	ret
    freeproc(p);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f08080e7          	jalr	-248(ra) # 80001b96 <freeproc>
    release(&p->lock);
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	ff2080e7          	jalr	-14(ra) # 80000c8a <release>
    return 0;
    80001ca0:	84ca                	mv	s1,s2
    80001ca2:	bff1                	j	80001c7e <allocproc+0x90>
    freeproc(p);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	ef0080e7          	jalr	-272(ra) # 80001b96 <freeproc>
    release(&p->lock);
    80001cae:	8526                	mv	a0,s1
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	fda080e7          	jalr	-38(ra) # 80000c8a <release>
    return 0;
    80001cb8:	84ca                	mv	s1,s2
    80001cba:	b7d1                	j	80001c7e <allocproc+0x90>

0000000080001cbc <userinit>:
{
    80001cbc:	1101                	addi	sp,sp,-32
    80001cbe:	ec06                	sd	ra,24(sp)
    80001cc0:	e822                	sd	s0,16(sp)
    80001cc2:	e426                	sd	s1,8(sp)
    80001cc4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	f28080e7          	jalr	-216(ra) # 80001bee <allocproc>
    80001cce:	84aa                	mv	s1,a0
  initproc = p;
    80001cd0:	00007797          	auipc	a5,0x7
    80001cd4:	54a7bc23          	sd	a0,1368(a5) # 80009228 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cd8:	03400613          	li	a2,52
    80001cdc:	00007597          	auipc	a1,0x7
    80001ce0:	4c458593          	addi	a1,a1,1220 # 800091a0 <initcode>
    80001ce4:	6928                	ld	a0,80(a0)
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	6a8080e7          	jalr	1704(ra) # 8000138e <uvmfirst>
  p->sz = PGSIZE;
    80001cee:	6785                	lui	a5,0x1
    80001cf0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cf2:	6cb8                	ld	a4,88(s1)
    80001cf4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf8:	6cb8                	ld	a4,88(s1)
    80001cfa:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cfc:	4641                	li	a2,16
    80001cfe:	00006597          	auipc	a1,0x6
    80001d02:	4ea58593          	addi	a1,a1,1258 # 800081e8 <digits+0x1a8>
    80001d06:	15848513          	addi	a0,s1,344
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	112080e7          	jalr	274(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d12:	00006517          	auipc	a0,0x6
    80001d16:	4e650513          	addi	a0,a0,1254 # 800081f8 <digits+0x1b8>
    80001d1a:	00002097          	auipc	ra,0x2
    80001d1e:	242080e7          	jalr	578(ra) # 80003f5c <namei>
    80001d22:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d26:	478d                	li	a5,3
    80001d28:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	f5e080e7          	jalr	-162(ra) # 80000c8a <release>
}
    80001d34:	60e2                	ld	ra,24(sp)
    80001d36:	6442                	ld	s0,16(sp)
    80001d38:	64a2                	ld	s1,8(sp)
    80001d3a:	6105                	addi	sp,sp,32
    80001d3c:	8082                	ret

0000000080001d3e <kproc_create>:
{
    80001d3e:	7179                	addi	sp,sp,-48
    80001d40:	f406                	sd	ra,40(sp)
    80001d42:	f022                	sd	s0,32(sp)
    80001d44:	ec26                	sd	s1,24(sp)
    80001d46:	e84a                	sd	s2,16(sp)
    80001d48:	e44e                	sd	s3,8(sp)
    80001d4a:	1800                	addi	s0,sp,48
    80001d4c:	89aa                	mv	s3,a0
    80001d4e:	892e                	mv	s2,a1
  struct proc *p = allocproc();
    80001d50:	00000097          	auipc	ra,0x0
    80001d54:	e9e080e7          	jalr	-354(ra) # 80001bee <allocproc>
  if(p == 0)
    80001d58:	cd15                	beqz	a0,80001d94 <kproc_create+0x56>
    80001d5a:	84aa                	mv	s1,a0
  p->context.ra = (uint64)fn;
    80001d5c:	07353023          	sd	s3,96(a0)
  p->context.sp = p->kstack + PGSIZE;
    80001d60:	613c                	ld	a5,64(a0)
    80001d62:	6705                	lui	a4,0x1
    80001d64:	97ba                	add	a5,a5,a4
    80001d66:	f53c                	sd	a5,104(a0)
  safestrcpy(p->name, name, sizeof(p->name));
    80001d68:	4641                	li	a2,16
    80001d6a:	85ca                	mv	a1,s2
    80001d6c:	15850513          	addi	a0,a0,344
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	0ac080e7          	jalr	172(ra) # 80000e1c <safestrcpy>
  p->state = RUNNABLE;
    80001d78:	478d                	li	a5,3
    80001d7a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	f0c080e7          	jalr	-244(ra) # 80000c8a <release>
}
    80001d86:	70a2                	ld	ra,40(sp)
    80001d88:	7402                	ld	s0,32(sp)
    80001d8a:	64e2                	ld	s1,24(sp)
    80001d8c:	6942                	ld	s2,16(sp)
    80001d8e:	69a2                	ld	s3,8(sp)
    80001d90:	6145                	addi	sp,sp,48
    80001d92:	8082                	ret
    panic("kproc_create");
    80001d94:	00006517          	auipc	a0,0x6
    80001d98:	46c50513          	addi	a0,a0,1132 # 80008200 <digits+0x1c0>
    80001d9c:	ffffe097          	auipc	ra,0xffffe
    80001da0:	7a2080e7          	jalr	1954(ra) # 8000053e <panic>

0000000080001da4 <growproc>:
{
    80001da4:	1101                	addi	sp,sp,-32
    80001da6:	ec06                	sd	ra,24(sp)
    80001da8:	e822                	sd	s0,16(sp)
    80001daa:	e426                	sd	s1,8(sp)
    80001dac:	e04a                	sd	s2,0(sp)
    80001dae:	1000                	addi	s0,sp,32
    80001db0:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	c32080e7          	jalr	-974(ra) # 800019e4 <myproc>
    80001dba:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dbc:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001dbe:	01204c63          	bgtz	s2,80001dd6 <growproc+0x32>
  } else if(n < 0){
    80001dc2:	02094663          	bltz	s2,80001dee <growproc+0x4a>
  p->sz = sz;
    80001dc6:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dc8:	4501                	li	a0,0
}
    80001dca:	60e2                	ld	ra,24(sp)
    80001dcc:	6442                	ld	s0,16(sp)
    80001dce:	64a2                	ld	s1,8(sp)
    80001dd0:	6902                	ld	s2,0(sp)
    80001dd2:	6105                	addi	sp,sp,32
    80001dd4:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001dd6:	4691                	li	a3,4
    80001dd8:	00b90633          	add	a2,s2,a1
    80001ddc:	6928                	ld	a0,80(a0)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	66a080e7          	jalr	1642(ra) # 80001448 <uvmalloc>
    80001de6:	85aa                	mv	a1,a0
    80001de8:	fd79                	bnez	a0,80001dc6 <growproc+0x22>
      return -1;
    80001dea:	557d                	li	a0,-1
    80001dec:	bff9                	j	80001dca <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dee:	00b90633          	add	a2,s2,a1
    80001df2:	6928                	ld	a0,80(a0)
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	60c080e7          	jalr	1548(ra) # 80001400 <uvmdealloc>
    80001dfc:	85aa                	mv	a1,a0
    80001dfe:	b7e1                	j	80001dc6 <growproc+0x22>

0000000080001e00 <fork>:
{
    80001e00:	7139                	addi	sp,sp,-64
    80001e02:	fc06                	sd	ra,56(sp)
    80001e04:	f822                	sd	s0,48(sp)
    80001e06:	f426                	sd	s1,40(sp)
    80001e08:	f04a                	sd	s2,32(sp)
    80001e0a:	ec4e                	sd	s3,24(sp)
    80001e0c:	e852                	sd	s4,16(sp)
    80001e0e:	e456                	sd	s5,8(sp)
    80001e10:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e12:	00000097          	auipc	ra,0x0
    80001e16:	bd2080e7          	jalr	-1070(ra) # 800019e4 <myproc>
    80001e1a:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e1c:	00000097          	auipc	ra,0x0
    80001e20:	dd2080e7          	jalr	-558(ra) # 80001bee <allocproc>
    80001e24:	10050c63          	beqz	a0,80001f3c <fork+0x13c>
    80001e28:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e2a:	048ab603          	ld	a2,72(s5)
    80001e2e:	692c                	ld	a1,80(a0)
    80001e30:	050ab503          	ld	a0,80(s5)
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	768080e7          	jalr	1896(ra) # 8000159c <uvmcopy>
    80001e3c:	04054863          	bltz	a0,80001e8c <fork+0x8c>
  np->sz = p->sz;
    80001e40:	048ab783          	ld	a5,72(s5)
    80001e44:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e48:	058ab683          	ld	a3,88(s5)
    80001e4c:	87b6                	mv	a5,a3
    80001e4e:	058a3703          	ld	a4,88(s4)
    80001e52:	12068693          	addi	a3,a3,288
    80001e56:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e5a:	6788                	ld	a0,8(a5)
    80001e5c:	6b8c                	ld	a1,16(a5)
    80001e5e:	6f90                	ld	a2,24(a5)
    80001e60:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001e64:	e708                	sd	a0,8(a4)
    80001e66:	eb0c                	sd	a1,16(a4)
    80001e68:	ef10                	sd	a2,24(a4)
    80001e6a:	02078793          	addi	a5,a5,32
    80001e6e:	02070713          	addi	a4,a4,32
    80001e72:	fed792e3          	bne	a5,a3,80001e56 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e76:	058a3783          	ld	a5,88(s4)
    80001e7a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e7e:	0d0a8493          	addi	s1,s5,208
    80001e82:	0d0a0913          	addi	s2,s4,208
    80001e86:	150a8993          	addi	s3,s5,336
    80001e8a:	a00d                	j	80001eac <fork+0xac>
    freeproc(np);
    80001e8c:	8552                	mv	a0,s4
    80001e8e:	00000097          	auipc	ra,0x0
    80001e92:	d08080e7          	jalr	-760(ra) # 80001b96 <freeproc>
    release(&np->lock);
    80001e96:	8552                	mv	a0,s4
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	df2080e7          	jalr	-526(ra) # 80000c8a <release>
    return -1;
    80001ea0:	597d                	li	s2,-1
    80001ea2:	a059                	j	80001f28 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001ea4:	04a1                	addi	s1,s1,8
    80001ea6:	0921                	addi	s2,s2,8
    80001ea8:	01348b63          	beq	s1,s3,80001ebe <fork+0xbe>
    if(p->ofile[i])
    80001eac:	6088                	ld	a0,0(s1)
    80001eae:	d97d                	beqz	a0,80001ea4 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb0:	00002097          	auipc	ra,0x2
    80001eb4:	742080e7          	jalr	1858(ra) # 800045f2 <filedup>
    80001eb8:	00a93023          	sd	a0,0(s2)
    80001ebc:	b7e5                	j	80001ea4 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ebe:	150ab503          	ld	a0,336(s5)
    80001ec2:	00002097          	auipc	ra,0x2
    80001ec6:	8b6080e7          	jalr	-1866(ra) # 80003778 <idup>
    80001eca:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ece:	4641                	li	a2,16
    80001ed0:	158a8593          	addi	a1,s5,344
    80001ed4:	158a0513          	addi	a0,s4,344
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	f44080e7          	jalr	-188(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001ee0:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001ee4:	8552                	mv	a0,s4
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	da4080e7          	jalr	-604(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001eee:	0000f497          	auipc	s1,0xf
    80001ef2:	5ca48493          	addi	s1,s1,1482 # 800114b8 <wait_lock>
    80001ef6:	8526                	mv	a0,s1
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	cde080e7          	jalr	-802(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001f00:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001f0e:	8552                	mv	a0,s4
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	cc6080e7          	jalr	-826(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001f18:	478d                	li	a5,3
    80001f1a:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f1e:	8552                	mv	a0,s4
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	d6a080e7          	jalr	-662(ra) # 80000c8a <release>
}
    80001f28:	854a                	mv	a0,s2
    80001f2a:	70e2                	ld	ra,56(sp)
    80001f2c:	7442                	ld	s0,48(sp)
    80001f2e:	74a2                	ld	s1,40(sp)
    80001f30:	7902                	ld	s2,32(sp)
    80001f32:	69e2                	ld	s3,24(sp)
    80001f34:	6a42                	ld	s4,16(sp)
    80001f36:	6aa2                	ld	s5,8(sp)
    80001f38:	6121                	addi	sp,sp,64
    80001f3a:	8082                	ret
    return -1;
    80001f3c:	597d                	li	s2,-1
    80001f3e:	b7ed                	j	80001f28 <fork+0x128>

0000000080001f40 <scheduler>:
{
    80001f40:	7139                	addi	sp,sp,-64
    80001f42:	fc06                	sd	ra,56(sp)
    80001f44:	f822                	sd	s0,48(sp)
    80001f46:	f426                	sd	s1,40(sp)
    80001f48:	f04a                	sd	s2,32(sp)
    80001f4a:	ec4e                	sd	s3,24(sp)
    80001f4c:	e852                	sd	s4,16(sp)
    80001f4e:	e456                	sd	s5,8(sp)
    80001f50:	e05a                	sd	s6,0(sp)
    80001f52:	0080                	addi	s0,sp,64
    80001f54:	8792                	mv	a5,tp
  int id = r_tp();
    80001f56:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f58:	00779a93          	slli	s5,a5,0x7
    80001f5c:	0000f717          	auipc	a4,0xf
    80001f60:	54470713          	addi	a4,a4,1348 # 800114a0 <pid_lock>
    80001f64:	9756                	add	a4,a4,s5
    80001f66:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	56e70713          	addi	a4,a4,1390 # 800114d8 <cpus+0x8>
    80001f72:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f74:	498d                	li	s3,3
        p->state = RUNNING;
    80001f76:	4b11                	li	s6,4
        c->proc = p;
    80001f78:	079e                	slli	a5,a5,0x7
    80001f7a:	0000fa17          	auipc	s4,0xf
    80001f7e:	526a0a13          	addi	s4,s4,1318 # 800114a0 <pid_lock>
    80001f82:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f84:	00015917          	auipc	s2,0x15
    80001f88:	34c90913          	addi	s2,s2,844 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f90:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f94:	10079073          	csrw	sstatus,a5
    80001f98:	00010497          	auipc	s1,0x10
    80001f9c:	93848493          	addi	s1,s1,-1736 # 800118d0 <proc>
    80001fa0:	a811                	j	80001fb4 <scheduler+0x74>
      release(&p->lock);
    80001fa2:	8526                	mv	a0,s1
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	ce6080e7          	jalr	-794(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fac:	16848493          	addi	s1,s1,360
    80001fb0:	fd248ee3          	beq	s1,s2,80001f8c <scheduler+0x4c>
      acquire(&p->lock);
    80001fb4:	8526                	mv	a0,s1
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	c20080e7          	jalr	-992(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001fbe:	4c9c                	lw	a5,24(s1)
    80001fc0:	ff3791e3          	bne	a5,s3,80001fa2 <scheduler+0x62>
        p->state = RUNNING;
    80001fc4:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fc8:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fcc:	06048593          	addi	a1,s1,96
    80001fd0:	8556                	mv	a0,s5
    80001fd2:	00000097          	auipc	ra,0x0
    80001fd6:	736080e7          	jalr	1846(ra) # 80002708 <swtch>
        c->proc = 0;
    80001fda:	020a3823          	sd	zero,48(s4)
    80001fde:	b7d1                	j	80001fa2 <scheduler+0x62>

0000000080001fe0 <sched>:
{
    80001fe0:	7179                	addi	sp,sp,-48
    80001fe2:	f406                	sd	ra,40(sp)
    80001fe4:	f022                	sd	s0,32(sp)
    80001fe6:	ec26                	sd	s1,24(sp)
    80001fe8:	e84a                	sd	s2,16(sp)
    80001fea:	e44e                	sd	s3,8(sp)
    80001fec:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fee:	00000097          	auipc	ra,0x0
    80001ff2:	9f6080e7          	jalr	-1546(ra) # 800019e4 <myproc>
    80001ff6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	b64080e7          	jalr	-1180(ra) # 80000b5c <holding>
    80002000:	c93d                	beqz	a0,80002076 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002002:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002004:	2781                	sext.w	a5,a5
    80002006:	079e                	slli	a5,a5,0x7
    80002008:	0000f717          	auipc	a4,0xf
    8000200c:	49870713          	addi	a4,a4,1176 # 800114a0 <pid_lock>
    80002010:	97ba                	add	a5,a5,a4
    80002012:	0a87a703          	lw	a4,168(a5)
    80002016:	4785                	li	a5,1
    80002018:	06f71763          	bne	a4,a5,80002086 <sched+0xa6>
  if(p->state == RUNNING)
    8000201c:	4c98                	lw	a4,24(s1)
    8000201e:	4791                	li	a5,4
    80002020:	06f70b63          	beq	a4,a5,80002096 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002024:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002028:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000202a:	efb5                	bnez	a5,800020a6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000202c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000202e:	0000f917          	auipc	s2,0xf
    80002032:	47290913          	addi	s2,s2,1138 # 800114a0 <pid_lock>
    80002036:	2781                	sext.w	a5,a5
    80002038:	079e                	slli	a5,a5,0x7
    8000203a:	97ca                	add	a5,a5,s2
    8000203c:	0ac7a983          	lw	s3,172(a5)
    80002040:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002042:	2781                	sext.w	a5,a5
    80002044:	079e                	slli	a5,a5,0x7
    80002046:	0000f597          	auipc	a1,0xf
    8000204a:	49258593          	addi	a1,a1,1170 # 800114d8 <cpus+0x8>
    8000204e:	95be                	add	a1,a1,a5
    80002050:	06048513          	addi	a0,s1,96
    80002054:	00000097          	auipc	ra,0x0
    80002058:	6b4080e7          	jalr	1716(ra) # 80002708 <swtch>
    8000205c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000205e:	2781                	sext.w	a5,a5
    80002060:	079e                	slli	a5,a5,0x7
    80002062:	97ca                	add	a5,a5,s2
    80002064:	0b37a623          	sw	s3,172(a5)
}
    80002068:	70a2                	ld	ra,40(sp)
    8000206a:	7402                	ld	s0,32(sp)
    8000206c:	64e2                	ld	s1,24(sp)
    8000206e:	6942                	ld	s2,16(sp)
    80002070:	69a2                	ld	s3,8(sp)
    80002072:	6145                	addi	sp,sp,48
    80002074:	8082                	ret
    panic("sched p->lock");
    80002076:	00006517          	auipc	a0,0x6
    8000207a:	19a50513          	addi	a0,a0,410 # 80008210 <digits+0x1d0>
    8000207e:	ffffe097          	auipc	ra,0xffffe
    80002082:	4c0080e7          	jalr	1216(ra) # 8000053e <panic>
    panic("sched locks");
    80002086:	00006517          	auipc	a0,0x6
    8000208a:	19a50513          	addi	a0,a0,410 # 80008220 <digits+0x1e0>
    8000208e:	ffffe097          	auipc	ra,0xffffe
    80002092:	4b0080e7          	jalr	1200(ra) # 8000053e <panic>
    panic("sched running");
    80002096:	00006517          	auipc	a0,0x6
    8000209a:	19a50513          	addi	a0,a0,410 # 80008230 <digits+0x1f0>
    8000209e:	ffffe097          	auipc	ra,0xffffe
    800020a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020a6:	00006517          	auipc	a0,0x6
    800020aa:	19a50513          	addi	a0,a0,410 # 80008240 <digits+0x200>
    800020ae:	ffffe097          	auipc	ra,0xffffe
    800020b2:	490080e7          	jalr	1168(ra) # 8000053e <panic>

00000000800020b6 <yield>:
{
    800020b6:	1101                	addi	sp,sp,-32
    800020b8:	ec06                	sd	ra,24(sp)
    800020ba:	e822                	sd	s0,16(sp)
    800020bc:	e426                	sd	s1,8(sp)
    800020be:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020c0:	00000097          	auipc	ra,0x0
    800020c4:	924080e7          	jalr	-1756(ra) # 800019e4 <myproc>
    800020c8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	b0c080e7          	jalr	-1268(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800020d2:	478d                	li	a5,3
    800020d4:	cc9c                	sw	a5,24(s1)
  sched();
    800020d6:	00000097          	auipc	ra,0x0
    800020da:	f0a080e7          	jalr	-246(ra) # 80001fe0 <sched>
  release(&p->lock);
    800020de:	8526                	mv	a0,s1
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	baa080e7          	jalr	-1110(ra) # 80000c8a <release>
}
    800020e8:	60e2                	ld	ra,24(sp)
    800020ea:	6442                	ld	s0,16(sp)
    800020ec:	64a2                	ld	s1,8(sp)
    800020ee:	6105                	addi	sp,sp,32
    800020f0:	8082                	ret

00000000800020f2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020f2:	7179                	addi	sp,sp,-48
    800020f4:	f406                	sd	ra,40(sp)
    800020f6:	f022                	sd	s0,32(sp)
    800020f8:	ec26                	sd	s1,24(sp)
    800020fa:	e84a                	sd	s2,16(sp)
    800020fc:	e44e                	sd	s3,8(sp)
    800020fe:	1800                	addi	s0,sp,48
    80002100:	89aa                	mv	s3,a0
    80002102:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002104:	00000097          	auipc	ra,0x0
    80002108:	8e0080e7          	jalr	-1824(ra) # 800019e4 <myproc>
    8000210c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	ac8080e7          	jalr	-1336(ra) # 80000bd6 <acquire>
  release(lk);
    80002116:	854a                	mv	a0,s2
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	b72080e7          	jalr	-1166(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002120:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002124:	4789                	li	a5,2
    80002126:	cc9c                	sw	a5,24(s1)

  sched();
    80002128:	00000097          	auipc	ra,0x0
    8000212c:	eb8080e7          	jalr	-328(ra) # 80001fe0 <sched>

  // Tidy up.
  p->chan = 0;
    80002130:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002134:	8526                	mv	a0,s1
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	b54080e7          	jalr	-1196(ra) # 80000c8a <release>
  acquire(lk);
    8000213e:	854a                	mv	a0,s2
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	a96080e7          	jalr	-1386(ra) # 80000bd6 <acquire>
}
    80002148:	70a2                	ld	ra,40(sp)
    8000214a:	7402                	ld	s0,32(sp)
    8000214c:	64e2                	ld	s1,24(sp)
    8000214e:	6942                	ld	s2,16(sp)
    80002150:	69a2                	ld	s3,8(sp)
    80002152:	6145                	addi	sp,sp,48
    80002154:	8082                	ret

0000000080002156 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002156:	7139                	addi	sp,sp,-64
    80002158:	fc06                	sd	ra,56(sp)
    8000215a:	f822                	sd	s0,48(sp)
    8000215c:	f426                	sd	s1,40(sp)
    8000215e:	f04a                	sd	s2,32(sp)
    80002160:	ec4e                	sd	s3,24(sp)
    80002162:	e852                	sd	s4,16(sp)
    80002164:	e456                	sd	s5,8(sp)
    80002166:	0080                	addi	s0,sp,64
    80002168:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000216a:	0000f497          	auipc	s1,0xf
    8000216e:	76648493          	addi	s1,s1,1894 # 800118d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002172:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002174:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002176:	00015917          	auipc	s2,0x15
    8000217a:	15a90913          	addi	s2,s2,346 # 800172d0 <tickslock>
    8000217e:	a811                	j	80002192 <wakeup+0x3c>
      }
      release(&p->lock);
    80002180:	8526                	mv	a0,s1
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	b08080e7          	jalr	-1272(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000218a:	16848493          	addi	s1,s1,360
    8000218e:	03248663          	beq	s1,s2,800021ba <wakeup+0x64>
    if(p != myproc()){
    80002192:	00000097          	auipc	ra,0x0
    80002196:	852080e7          	jalr	-1966(ra) # 800019e4 <myproc>
    8000219a:	fea488e3          	beq	s1,a0,8000218a <wakeup+0x34>
      acquire(&p->lock);
    8000219e:	8526                	mv	a0,s1
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	a36080e7          	jalr	-1482(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021a8:	4c9c                	lw	a5,24(s1)
    800021aa:	fd379be3          	bne	a5,s3,80002180 <wakeup+0x2a>
    800021ae:	709c                	ld	a5,32(s1)
    800021b0:	fd4798e3          	bne	a5,s4,80002180 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021b4:	0154ac23          	sw	s5,24(s1)
    800021b8:	b7e1                	j	80002180 <wakeup+0x2a>
    }
  }
}
    800021ba:	70e2                	ld	ra,56(sp)
    800021bc:	7442                	ld	s0,48(sp)
    800021be:	74a2                	ld	s1,40(sp)
    800021c0:	7902                	ld	s2,32(sp)
    800021c2:	69e2                	ld	s3,24(sp)
    800021c4:	6a42                	ld	s4,16(sp)
    800021c6:	6aa2                	ld	s5,8(sp)
    800021c8:	6121                	addi	sp,sp,64
    800021ca:	8082                	ret

00000000800021cc <reparent>:
{
    800021cc:	7179                	addi	sp,sp,-48
    800021ce:	f406                	sd	ra,40(sp)
    800021d0:	f022                	sd	s0,32(sp)
    800021d2:	ec26                	sd	s1,24(sp)
    800021d4:	e84a                	sd	s2,16(sp)
    800021d6:	e44e                	sd	s3,8(sp)
    800021d8:	e052                	sd	s4,0(sp)
    800021da:	1800                	addi	s0,sp,48
    800021dc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021de:	0000f497          	auipc	s1,0xf
    800021e2:	6f248493          	addi	s1,s1,1778 # 800118d0 <proc>
      pp->parent = initproc;
    800021e6:	00007a17          	auipc	s4,0x7
    800021ea:	042a0a13          	addi	s4,s4,66 # 80009228 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021ee:	00015997          	auipc	s3,0x15
    800021f2:	0e298993          	addi	s3,s3,226 # 800172d0 <tickslock>
    800021f6:	a029                	j	80002200 <reparent+0x34>
    800021f8:	16848493          	addi	s1,s1,360
    800021fc:	01348d63          	beq	s1,s3,80002216 <reparent+0x4a>
    if(pp->parent == p){
    80002200:	7c9c                	ld	a5,56(s1)
    80002202:	ff279be3          	bne	a5,s2,800021f8 <reparent+0x2c>
      pp->parent = initproc;
    80002206:	000a3503          	ld	a0,0(s4)
    8000220a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000220c:	00000097          	auipc	ra,0x0
    80002210:	f4a080e7          	jalr	-182(ra) # 80002156 <wakeup>
    80002214:	b7d5                	j	800021f8 <reparent+0x2c>
}
    80002216:	70a2                	ld	ra,40(sp)
    80002218:	7402                	ld	s0,32(sp)
    8000221a:	64e2                	ld	s1,24(sp)
    8000221c:	6942                	ld	s2,16(sp)
    8000221e:	69a2                	ld	s3,8(sp)
    80002220:	6a02                	ld	s4,0(sp)
    80002222:	6145                	addi	sp,sp,48
    80002224:	8082                	ret

0000000080002226 <exit>:
{
    80002226:	7179                	addi	sp,sp,-48
    80002228:	f406                	sd	ra,40(sp)
    8000222a:	f022                	sd	s0,32(sp)
    8000222c:	ec26                	sd	s1,24(sp)
    8000222e:	e84a                	sd	s2,16(sp)
    80002230:	e44e                	sd	s3,8(sp)
    80002232:	e052                	sd	s4,0(sp)
    80002234:	1800                	addi	s0,sp,48
    80002236:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	7ac080e7          	jalr	1964(ra) # 800019e4 <myproc>
    80002240:	89aa                	mv	s3,a0
  if(p == initproc)
    80002242:	00007797          	auipc	a5,0x7
    80002246:	fe67b783          	ld	a5,-26(a5) # 80009228 <initproc>
    8000224a:	0d050493          	addi	s1,a0,208
    8000224e:	15050913          	addi	s2,a0,336
    80002252:	02a79363          	bne	a5,a0,80002278 <exit+0x52>
    panic("init exiting");
    80002256:	00006517          	auipc	a0,0x6
    8000225a:	00250513          	addi	a0,a0,2 # 80008258 <digits+0x218>
    8000225e:	ffffe097          	auipc	ra,0xffffe
    80002262:	2e0080e7          	jalr	736(ra) # 8000053e <panic>
      fileclose(f);
    80002266:	00002097          	auipc	ra,0x2
    8000226a:	3de080e7          	jalr	990(ra) # 80004644 <fileclose>
      p->ofile[fd] = 0;
    8000226e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002272:	04a1                	addi	s1,s1,8
    80002274:	01248563          	beq	s1,s2,8000227e <exit+0x58>
    if(p->ofile[fd]){
    80002278:	6088                	ld	a0,0(s1)
    8000227a:	f575                	bnez	a0,80002266 <exit+0x40>
    8000227c:	bfdd                	j	80002272 <exit+0x4c>
  begin_op();
    8000227e:	00002097          	auipc	ra,0x2
    80002282:	efa080e7          	jalr	-262(ra) # 80004178 <begin_op>
  iput(p->cwd);
    80002286:	1509b503          	ld	a0,336(s3)
    8000228a:	00001097          	auipc	ra,0x1
    8000228e:	6e6080e7          	jalr	1766(ra) # 80003970 <iput>
  end_op();
    80002292:	00002097          	auipc	ra,0x2
    80002296:	f66080e7          	jalr	-154(ra) # 800041f8 <end_op>
  p->cwd = 0;
    8000229a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000229e:	0000f497          	auipc	s1,0xf
    800022a2:	21a48493          	addi	s1,s1,538 # 800114b8 <wait_lock>
    800022a6:	8526                	mv	a0,s1
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	92e080e7          	jalr	-1746(ra) # 80000bd6 <acquire>
  reparent(p);
    800022b0:	854e                	mv	a0,s3
    800022b2:	00000097          	auipc	ra,0x0
    800022b6:	f1a080e7          	jalr	-230(ra) # 800021cc <reparent>
  wakeup(p->parent);
    800022ba:	0389b503          	ld	a0,56(s3)
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	e98080e7          	jalr	-360(ra) # 80002156 <wakeup>
  acquire(&p->lock);
    800022c6:	854e                	mv	a0,s3
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	90e080e7          	jalr	-1778(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800022d0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022d4:	4795                	li	a5,5
    800022d6:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	9ae080e7          	jalr	-1618(ra) # 80000c8a <release>
  sched();
    800022e4:	00000097          	auipc	ra,0x0
    800022e8:	cfc080e7          	jalr	-772(ra) # 80001fe0 <sched>
  panic("zombie exit");
    800022ec:	00006517          	auipc	a0,0x6
    800022f0:	f7c50513          	addi	a0,a0,-132 # 80008268 <digits+0x228>
    800022f4:	ffffe097          	auipc	ra,0xffffe
    800022f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>

00000000800022fc <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022fc:	7179                	addi	sp,sp,-48
    800022fe:	f406                	sd	ra,40(sp)
    80002300:	f022                	sd	s0,32(sp)
    80002302:	ec26                	sd	s1,24(sp)
    80002304:	e84a                	sd	s2,16(sp)
    80002306:	e44e                	sd	s3,8(sp)
    80002308:	1800                	addi	s0,sp,48
    8000230a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000230c:	0000f497          	auipc	s1,0xf
    80002310:	5c448493          	addi	s1,s1,1476 # 800118d0 <proc>
    80002314:	00015997          	auipc	s3,0x15
    80002318:	fbc98993          	addi	s3,s3,-68 # 800172d0 <tickslock>
    acquire(&p->lock);
    8000231c:	8526                	mv	a0,s1
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	8b8080e7          	jalr	-1864(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002326:	589c                	lw	a5,48(s1)
    80002328:	01278d63          	beq	a5,s2,80002342 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	95c080e7          	jalr	-1700(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002336:	16848493          	addi	s1,s1,360
    8000233a:	ff3491e3          	bne	s1,s3,8000231c <kill+0x20>
  }
  return -1;
    8000233e:	557d                	li	a0,-1
    80002340:	a829                	j	8000235a <kill+0x5e>
      p->killed = 1;
    80002342:	4785                	li	a5,1
    80002344:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002346:	4c98                	lw	a4,24(s1)
    80002348:	4789                	li	a5,2
    8000234a:	00f70f63          	beq	a4,a5,80002368 <kill+0x6c>
      release(&p->lock);
    8000234e:	8526                	mv	a0,s1
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	93a080e7          	jalr	-1734(ra) # 80000c8a <release>
      return 0;
    80002358:	4501                	li	a0,0
}
    8000235a:	70a2                	ld	ra,40(sp)
    8000235c:	7402                	ld	s0,32(sp)
    8000235e:	64e2                	ld	s1,24(sp)
    80002360:	6942                	ld	s2,16(sp)
    80002362:	69a2                	ld	s3,8(sp)
    80002364:	6145                	addi	sp,sp,48
    80002366:	8082                	ret
        p->state = RUNNABLE;
    80002368:	478d                	li	a5,3
    8000236a:	cc9c                	sw	a5,24(s1)
    8000236c:	b7cd                	j	8000234e <kill+0x52>

000000008000236e <setkilled>:

void
setkilled(struct proc *p)
{
    8000236e:	1101                	addi	sp,sp,-32
    80002370:	ec06                	sd	ra,24(sp)
    80002372:	e822                	sd	s0,16(sp)
    80002374:	e426                	sd	s1,8(sp)
    80002376:	1000                	addi	s0,sp,32
    80002378:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	85c080e7          	jalr	-1956(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002382:	4785                	li	a5,1
    80002384:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	902080e7          	jalr	-1790(ra) # 80000c8a <release>
}
    80002390:	60e2                	ld	ra,24(sp)
    80002392:	6442                	ld	s0,16(sp)
    80002394:	64a2                	ld	s1,8(sp)
    80002396:	6105                	addi	sp,sp,32
    80002398:	8082                	ret

000000008000239a <killed>:

int
killed(struct proc *p)
{
    8000239a:	1101                	addi	sp,sp,-32
    8000239c:	ec06                	sd	ra,24(sp)
    8000239e:	e822                	sd	s0,16(sp)
    800023a0:	e426                	sd	s1,8(sp)
    800023a2:	e04a                	sd	s2,0(sp)
    800023a4:	1000                	addi	s0,sp,32
    800023a6:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	82e080e7          	jalr	-2002(ra) # 80000bd6 <acquire>
  k = p->killed;
    800023b0:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	8d4080e7          	jalr	-1836(ra) # 80000c8a <release>
  return k;
}
    800023be:	854a                	mv	a0,s2
    800023c0:	60e2                	ld	ra,24(sp)
    800023c2:	6442                	ld	s0,16(sp)
    800023c4:	64a2                	ld	s1,8(sp)
    800023c6:	6902                	ld	s2,0(sp)
    800023c8:	6105                	addi	sp,sp,32
    800023ca:	8082                	ret

00000000800023cc <wait>:
{
    800023cc:	715d                	addi	sp,sp,-80
    800023ce:	e486                	sd	ra,72(sp)
    800023d0:	e0a2                	sd	s0,64(sp)
    800023d2:	fc26                	sd	s1,56(sp)
    800023d4:	f84a                	sd	s2,48(sp)
    800023d6:	f44e                	sd	s3,40(sp)
    800023d8:	f052                	sd	s4,32(sp)
    800023da:	ec56                	sd	s5,24(sp)
    800023dc:	e85a                	sd	s6,16(sp)
    800023de:	e45e                	sd	s7,8(sp)
    800023e0:	e062                	sd	s8,0(sp)
    800023e2:	0880                	addi	s0,sp,80
    800023e4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	5fe080e7          	jalr	1534(ra) # 800019e4 <myproc>
    800023ee:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023f0:	0000f517          	auipc	a0,0xf
    800023f4:	0c850513          	addi	a0,a0,200 # 800114b8 <wait_lock>
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002400:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002402:	4a15                	li	s4,5
        havekids = 1;
    80002404:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002406:	00015997          	auipc	s3,0x15
    8000240a:	eca98993          	addi	s3,s3,-310 # 800172d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000240e:	0000fc17          	auipc	s8,0xf
    80002412:	0aac0c13          	addi	s8,s8,170 # 800114b8 <wait_lock>
    havekids = 0;
    80002416:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002418:	0000f497          	auipc	s1,0xf
    8000241c:	4b848493          	addi	s1,s1,1208 # 800118d0 <proc>
    80002420:	a0bd                	j	8000248e <wait+0xc2>
          pid = pp->pid;
    80002422:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002426:	000b0e63          	beqz	s6,80002442 <wait+0x76>
    8000242a:	4691                	li	a3,4
    8000242c:	02c48613          	addi	a2,s1,44
    80002430:	85da                	mv	a1,s6
    80002432:	05093503          	ld	a0,80(s2)
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	26a080e7          	jalr	618(ra) # 800016a0 <copyout>
    8000243e:	02054563          	bltz	a0,80002468 <wait+0x9c>
          freeproc(pp);
    80002442:	8526                	mv	a0,s1
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	752080e7          	jalr	1874(ra) # 80001b96 <freeproc>
          release(&pp->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	83c080e7          	jalr	-1988(ra) # 80000c8a <release>
          release(&wait_lock);
    80002456:	0000f517          	auipc	a0,0xf
    8000245a:	06250513          	addi	a0,a0,98 # 800114b8 <wait_lock>
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	82c080e7          	jalr	-2004(ra) # 80000c8a <release>
          return pid;
    80002466:	a0b5                	j	800024d2 <wait+0x106>
            release(&pp->lock);
    80002468:	8526                	mv	a0,s1
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	820080e7          	jalr	-2016(ra) # 80000c8a <release>
            release(&wait_lock);
    80002472:	0000f517          	auipc	a0,0xf
    80002476:	04650513          	addi	a0,a0,70 # 800114b8 <wait_lock>
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	810080e7          	jalr	-2032(ra) # 80000c8a <release>
            return -1;
    80002482:	59fd                	li	s3,-1
    80002484:	a0b9                	j	800024d2 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002486:	16848493          	addi	s1,s1,360
    8000248a:	03348463          	beq	s1,s3,800024b2 <wait+0xe6>
      if(pp->parent == p){
    8000248e:	7c9c                	ld	a5,56(s1)
    80002490:	ff279be3          	bne	a5,s2,80002486 <wait+0xba>
        acquire(&pp->lock);
    80002494:	8526                	mv	a0,s1
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	740080e7          	jalr	1856(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    8000249e:	4c9c                	lw	a5,24(s1)
    800024a0:	f94781e3          	beq	a5,s4,80002422 <wait+0x56>
        release(&pp->lock);
    800024a4:	8526                	mv	a0,s1
    800024a6:	ffffe097          	auipc	ra,0xffffe
    800024aa:	7e4080e7          	jalr	2020(ra) # 80000c8a <release>
        havekids = 1;
    800024ae:	8756                	mv	a4,s5
    800024b0:	bfd9                	j	80002486 <wait+0xba>
    if(!havekids || killed(p)){
    800024b2:	c719                	beqz	a4,800024c0 <wait+0xf4>
    800024b4:	854a                	mv	a0,s2
    800024b6:	00000097          	auipc	ra,0x0
    800024ba:	ee4080e7          	jalr	-284(ra) # 8000239a <killed>
    800024be:	c51d                	beqz	a0,800024ec <wait+0x120>
      release(&wait_lock);
    800024c0:	0000f517          	auipc	a0,0xf
    800024c4:	ff850513          	addi	a0,a0,-8 # 800114b8 <wait_lock>
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	7c2080e7          	jalr	1986(ra) # 80000c8a <release>
      return -1;
    800024d0:	59fd                	li	s3,-1
}
    800024d2:	854e                	mv	a0,s3
    800024d4:	60a6                	ld	ra,72(sp)
    800024d6:	6406                	ld	s0,64(sp)
    800024d8:	74e2                	ld	s1,56(sp)
    800024da:	7942                	ld	s2,48(sp)
    800024dc:	79a2                	ld	s3,40(sp)
    800024de:	7a02                	ld	s4,32(sp)
    800024e0:	6ae2                	ld	s5,24(sp)
    800024e2:	6b42                	ld	s6,16(sp)
    800024e4:	6ba2                	ld	s7,8(sp)
    800024e6:	6c02                	ld	s8,0(sp)
    800024e8:	6161                	addi	sp,sp,80
    800024ea:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024ec:	85e2                	mv	a1,s8
    800024ee:	854a                	mv	a0,s2
    800024f0:	00000097          	auipc	ra,0x0
    800024f4:	c02080e7          	jalr	-1022(ra) # 800020f2 <sleep>
    havekids = 0;
    800024f8:	bf39                	j	80002416 <wait+0x4a>

00000000800024fa <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024fa:	7179                	addi	sp,sp,-48
    800024fc:	f406                	sd	ra,40(sp)
    800024fe:	f022                	sd	s0,32(sp)
    80002500:	ec26                	sd	s1,24(sp)
    80002502:	e84a                	sd	s2,16(sp)
    80002504:	e44e                	sd	s3,8(sp)
    80002506:	e052                	sd	s4,0(sp)
    80002508:	1800                	addi	s0,sp,48
    8000250a:	84aa                	mv	s1,a0
    8000250c:	892e                	mv	s2,a1
    8000250e:	89b2                	mv	s3,a2
    80002510:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	4d2080e7          	jalr	1234(ra) # 800019e4 <myproc>
  if(user_dst){
    8000251a:	c08d                	beqz	s1,8000253c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000251c:	86d2                	mv	a3,s4
    8000251e:	864e                	mv	a2,s3
    80002520:	85ca                	mv	a1,s2
    80002522:	6928                	ld	a0,80(a0)
    80002524:	fffff097          	auipc	ra,0xfffff
    80002528:	17c080e7          	jalr	380(ra) # 800016a0 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000252c:	70a2                	ld	ra,40(sp)
    8000252e:	7402                	ld	s0,32(sp)
    80002530:	64e2                	ld	s1,24(sp)
    80002532:	6942                	ld	s2,16(sp)
    80002534:	69a2                	ld	s3,8(sp)
    80002536:	6a02                	ld	s4,0(sp)
    80002538:	6145                	addi	sp,sp,48
    8000253a:	8082                	ret
    memmove((char *)dst, src, len);
    8000253c:	000a061b          	sext.w	a2,s4
    80002540:	85ce                	mv	a1,s3
    80002542:	854a                	mv	a0,s2
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	7ea080e7          	jalr	2026(ra) # 80000d2e <memmove>
    return 0;
    8000254c:	8526                	mv	a0,s1
    8000254e:	bff9                	j	8000252c <either_copyout+0x32>

0000000080002550 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002550:	7179                	addi	sp,sp,-48
    80002552:	f406                	sd	ra,40(sp)
    80002554:	f022                	sd	s0,32(sp)
    80002556:	ec26                	sd	s1,24(sp)
    80002558:	e84a                	sd	s2,16(sp)
    8000255a:	e44e                	sd	s3,8(sp)
    8000255c:	e052                	sd	s4,0(sp)
    8000255e:	1800                	addi	s0,sp,48
    80002560:	892a                	mv	s2,a0
    80002562:	84ae                	mv	s1,a1
    80002564:	89b2                	mv	s3,a2
    80002566:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002568:	fffff097          	auipc	ra,0xfffff
    8000256c:	47c080e7          	jalr	1148(ra) # 800019e4 <myproc>
  if(user_src){
    80002570:	c08d                	beqz	s1,80002592 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002572:	86d2                	mv	a3,s4
    80002574:	864e                	mv	a2,s3
    80002576:	85ca                	mv	a1,s2
    80002578:	6928                	ld	a0,80(a0)
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	1b2080e7          	jalr	434(ra) # 8000172c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002582:	70a2                	ld	ra,40(sp)
    80002584:	7402                	ld	s0,32(sp)
    80002586:	64e2                	ld	s1,24(sp)
    80002588:	6942                	ld	s2,16(sp)
    8000258a:	69a2                	ld	s3,8(sp)
    8000258c:	6a02                	ld	s4,0(sp)
    8000258e:	6145                	addi	sp,sp,48
    80002590:	8082                	ret
    memmove(dst, (char*)src, len);
    80002592:	000a061b          	sext.w	a2,s4
    80002596:	85ce                	mv	a1,s3
    80002598:	854a                	mv	a0,s2
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	794080e7          	jalr	1940(ra) # 80000d2e <memmove>
    return 0;
    800025a2:	8526                	mv	a0,s1
    800025a4:	bff9                	j	80002582 <either_copyin+0x32>

00000000800025a6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025a6:	715d                	addi	sp,sp,-80
    800025a8:	e486                	sd	ra,72(sp)
    800025aa:	e0a2                	sd	s0,64(sp)
    800025ac:	fc26                	sd	s1,56(sp)
    800025ae:	f84a                	sd	s2,48(sp)
    800025b0:	f44e                	sd	s3,40(sp)
    800025b2:	f052                	sd	s4,32(sp)
    800025b4:	ec56                	sd	s5,24(sp)
    800025b6:	e85a                	sd	s6,16(sp)
    800025b8:	e45e                	sd	s7,8(sp)
    800025ba:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025bc:	00006517          	auipc	a0,0x6
    800025c0:	b1c50513          	addi	a0,a0,-1252 # 800080d8 <digits+0x98>
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	fc4080e7          	jalr	-60(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025cc:	0000f497          	auipc	s1,0xf
    800025d0:	45c48493          	addi	s1,s1,1116 # 80011a28 <proc+0x158>
    800025d4:	00015917          	auipc	s2,0x15
    800025d8:	e5490913          	addi	s2,s2,-428 # 80017428 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025dc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025de:	00006997          	auipc	s3,0x6
    800025e2:	c9a98993          	addi	s3,s3,-870 # 80008278 <digits+0x238>
    printf("%d %s %s", p->pid, state, p->name);
    800025e6:	00006a97          	auipc	s5,0x6
    800025ea:	c9aa8a93          	addi	s5,s5,-870 # 80008280 <digits+0x240>
    printf("\n");
    800025ee:	00006a17          	auipc	s4,0x6
    800025f2:	aeaa0a13          	addi	s4,s4,-1302 # 800080d8 <digits+0x98>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f6:	00006b97          	auipc	s7,0x6
    800025fa:	ccab8b93          	addi	s7,s7,-822 # 800082c0 <states.0>
    800025fe:	a00d                	j	80002620 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002600:	ed86a583          	lw	a1,-296(a3)
    80002604:	8556                	mv	a0,s5
    80002606:	ffffe097          	auipc	ra,0xffffe
    8000260a:	f82080e7          	jalr	-126(ra) # 80000588 <printf>
    printf("\n");
    8000260e:	8552                	mv	a0,s4
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	f78080e7          	jalr	-136(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002618:	16848493          	addi	s1,s1,360
    8000261c:	03248163          	beq	s1,s2,8000263e <procdump+0x98>
    if(p->state == UNUSED)
    80002620:	86a6                	mv	a3,s1
    80002622:	ec04a783          	lw	a5,-320(s1)
    80002626:	dbed                	beqz	a5,80002618 <procdump+0x72>
      state = "???";
    80002628:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000262a:	fcfb6be3          	bltu	s6,a5,80002600 <procdump+0x5a>
    8000262e:	1782                	slli	a5,a5,0x20
    80002630:	9381                	srli	a5,a5,0x20
    80002632:	078e                	slli	a5,a5,0x3
    80002634:	97de                	add	a5,a5,s7
    80002636:	6390                	ld	a2,0(a5)
    80002638:	f661                	bnez	a2,80002600 <procdump+0x5a>
      state = "???";
    8000263a:	864e                	mv	a2,s3
    8000263c:	b7d1                	j	80002600 <procdump+0x5a>
  }
}
    8000263e:	60a6                	ld	ra,72(sp)
    80002640:	6406                	ld	s0,64(sp)
    80002642:	74e2                	ld	s1,56(sp)
    80002644:	7942                	ld	s2,48(sp)
    80002646:	79a2                	ld	s3,40(sp)
    80002648:	7a02                	ld	s4,32(sp)
    8000264a:	6ae2                	ld	s5,24(sp)
    8000264c:	6b42                	ld	s6,16(sp)
    8000264e:	6ba2                	ld	s7,8(sp)
    80002650:	6161                	addi	sp,sp,80
    80002652:	8082                	ret

0000000080002654 <map_display>:

void*
map_display(void* addr) {
    80002654:	7139                	addi	sp,sp,-64
    80002656:	fc06                	sd	ra,56(sp)
    80002658:	f822                	sd	s0,48(sp)
    8000265a:	f426                	sd	s1,40(sp)
    8000265c:	f04a                	sd	s2,32(sp)
    8000265e:	ec4e                	sd	s3,24(sp)
    80002660:	e852                	sd	s4,16(sp)
    80002662:	e456                	sd	s5,8(sp)
    80002664:	e05a                	sd	s6,0(sp)
    80002666:	0080                	addi	s0,sp,64
    80002668:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    8000266a:	fffff097          	auipc	ra,0xfffff
    8000266e:	37a080e7          	jalr	890(ra) # 800019e4 <myproc>
    80002672:	892a                	mv	s2,a0
  uint64 va = (uint64)addr;
  uint64 fb_pa = (uint64)get_fb_addr();
    80002674:	00004097          	auipc	ra,0x4
    80002678:	3d2080e7          	jalr	978(ra) # 80006a46 <get_fb_addr>
    8000267c:	8b2a                	mv	s6,a0
  if(va == 0){
    8000267e:	000a8c63          	beqz	s5,80002696 <map_display+0x42>
    va = PGROUNDUP(p->sz);
  }
  if (va % PGSIZE != 0) {
    80002682:	034a9793          	slli	a5,s5,0x34
    return (void*)-1; 
    80002686:	557d                	li	a0,-1
  if (va % PGSIZE != 0) {
    80002688:	e3a1                	bnez	a5,800026c8 <map_display+0x74>
    8000268a:	0012c9b7          	lui	s3,0x12c
    8000268e:	99d6                	add	s3,s3,s5
    80002690:	84d6                	mv	s1,s5
  }

  for(int i = 0; i < GPU_FB_PAGES; i++){
    80002692:	6a05                	lui	s4,0x1
    80002694:	a829                	j	800026ae <map_display+0x5a>
    va = PGROUNDUP(p->sz);
    80002696:	04893a83          	ld	s5,72(s2)
    8000269a:	6785                	lui	a5,0x1
    8000269c:	17fd                	addi	a5,a5,-1
    8000269e:	9abe                	add	s5,s5,a5
    800026a0:	77fd                	lui	a5,0xfffff
    800026a2:	00fafab3          	and	s5,s5,a5
    800026a6:	bff1                	j	80002682 <map_display+0x2e>
  for(int i = 0; i < GPU_FB_PAGES; i++){
    800026a8:	94d2                	add	s1,s1,s4
    800026aa:	03348963          	beq	s1,s3,800026dc <map_display+0x88>
    pte_t *pte = walk(p->pagetable, va + (i * PGSIZE), 0);
    800026ae:	4601                	li	a2,0
    800026b0:	85a6                	mv	a1,s1
    800026b2:	05093503          	ld	a0,80(s2)
    800026b6:	fffff097          	auipc	ra,0xfffff
    800026ba:	920080e7          	jalr	-1760(ra) # 80000fd6 <walk>
    if(pte != 0 && (*pte & PTE_V) != 0){
    800026be:	d56d                	beqz	a0,800026a8 <map_display+0x54>
    800026c0:	611c                	ld	a5,0(a0)
    800026c2:	8b85                	andi	a5,a5,1
    800026c4:	d3f5                	beqz	a5,800026a8 <map_display+0x54>
      return (void*)-1;
    800026c6:	557d                	li	a0,-1
    return (void*)va;
  }
  else{
    return (void*)-1;
  }
    800026c8:	70e2                	ld	ra,56(sp)
    800026ca:	7442                	ld	s0,48(sp)
    800026cc:	74a2                	ld	s1,40(sp)
    800026ce:	7902                	ld	s2,32(sp)
    800026d0:	69e2                	ld	s3,24(sp)
    800026d2:	6a42                	ld	s4,16(sp)
    800026d4:	6aa2                	ld	s5,8(sp)
    800026d6:	6b02                	ld	s6,0(sp)
    800026d8:	6121                	addi	sp,sp,64
    800026da:	8082                	ret
  int suc = mappages(p->pagetable, va, size, fb_pa, PTE_U|PTE_R|PTE_W);
    800026dc:	4759                	li	a4,22
    800026de:	86da                	mv	a3,s6
    800026e0:	0012c637          	lui	a2,0x12c
    800026e4:	85d6                	mv	a1,s5
    800026e6:	05093503          	ld	a0,80(s2)
    800026ea:	fffff097          	auipc	ra,0xfffff
    800026ee:	9d4080e7          	jalr	-1580(ra) # 800010be <mappages>
    800026f2:	87aa                	mv	a5,a0
    return (void*)-1;
    800026f4:	557d                	li	a0,-1
  if(suc == 0){
    800026f6:	fbe9                	bnez	a5,800026c8 <map_display+0x74>
    if(va >= p->sz) {
    800026f8:	04893783          	ld	a5,72(s2)
    800026fc:	00fae463          	bltu	s5,a5,80002704 <map_display+0xb0>
      p->sz = va + size;
    80002700:	05393423          	sd	s3,72(s2)
    return (void*)va;
    80002704:	8556                	mv	a0,s5
    80002706:	b7c9                	j	800026c8 <map_display+0x74>

0000000080002708 <swtch>:
    80002708:	00153023          	sd	ra,0(a0)
    8000270c:	00253423          	sd	sp,8(a0)
    80002710:	e900                	sd	s0,16(a0)
    80002712:	ed04                	sd	s1,24(a0)
    80002714:	03253023          	sd	s2,32(a0)
    80002718:	03353423          	sd	s3,40(a0)
    8000271c:	03453823          	sd	s4,48(a0)
    80002720:	03553c23          	sd	s5,56(a0)
    80002724:	05653023          	sd	s6,64(a0)
    80002728:	05753423          	sd	s7,72(a0)
    8000272c:	05853823          	sd	s8,80(a0)
    80002730:	05953c23          	sd	s9,88(a0)
    80002734:	07a53023          	sd	s10,96(a0)
    80002738:	07b53423          	sd	s11,104(a0)
    8000273c:	0005b083          	ld	ra,0(a1)
    80002740:	0085b103          	ld	sp,8(a1)
    80002744:	6980                	ld	s0,16(a1)
    80002746:	6d84                	ld	s1,24(a1)
    80002748:	0205b903          	ld	s2,32(a1)
    8000274c:	0285b983          	ld	s3,40(a1)
    80002750:	0305ba03          	ld	s4,48(a1)
    80002754:	0385ba83          	ld	s5,56(a1)
    80002758:	0405bb03          	ld	s6,64(a1)
    8000275c:	0485bb83          	ld	s7,72(a1)
    80002760:	0505bc03          	ld	s8,80(a1)
    80002764:	0585bc83          	ld	s9,88(a1)
    80002768:	0605bd03          	ld	s10,96(a1)
    8000276c:	0685bd83          	ld	s11,104(a1)
    80002770:	8082                	ret

0000000080002772 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002772:	1141                	addi	sp,sp,-16
    80002774:	e406                	sd	ra,8(sp)
    80002776:	e022                	sd	s0,0(sp)
    80002778:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000277a:	00006597          	auipc	a1,0x6
    8000277e:	b7658593          	addi	a1,a1,-1162 # 800082f0 <states.0+0x30>
    80002782:	00015517          	auipc	a0,0x15
    80002786:	b4e50513          	addi	a0,a0,-1202 # 800172d0 <tickslock>
    8000278a:	ffffe097          	auipc	ra,0xffffe
    8000278e:	3bc080e7          	jalr	956(ra) # 80000b46 <initlock>
}
    80002792:	60a2                	ld	ra,8(sp)
    80002794:	6402                	ld	s0,0(sp)
    80002796:	0141                	addi	sp,sp,16
    80002798:	8082                	ret

000000008000279a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000279a:	1141                	addi	sp,sp,-16
    8000279c:	e422                	sd	s0,8(sp)
    8000279e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a0:	00003797          	auipc	a5,0x3
    800027a4:	4f078793          	addi	a5,a5,1264 # 80005c90 <kernelvec>
    800027a8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027ac:	6422                	ld	s0,8(sp)
    800027ae:	0141                	addi	sp,sp,16
    800027b0:	8082                	ret

00000000800027b2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027b2:	1141                	addi	sp,sp,-16
    800027b4:	e406                	sd	ra,8(sp)
    800027b6:	e022                	sd	s0,0(sp)
    800027b8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027ba:	fffff097          	auipc	ra,0xfffff
    800027be:	22a080e7          	jalr	554(ra) # 800019e4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027c6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027c8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027cc:	00005617          	auipc	a2,0x5
    800027d0:	83460613          	addi	a2,a2,-1996 # 80007000 <_trampoline>
    800027d4:	00005697          	auipc	a3,0x5
    800027d8:	82c68693          	addi	a3,a3,-2004 # 80007000 <_trampoline>
    800027dc:	8e91                	sub	a3,a3,a2
    800027de:	040007b7          	lui	a5,0x4000
    800027e2:	17fd                	addi	a5,a5,-1
    800027e4:	07b2                	slli	a5,a5,0xc
    800027e6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027e8:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027ec:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027ee:	180026f3          	csrr	a3,satp
    800027f2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027f4:	6d38                	ld	a4,88(a0)
    800027f6:	6134                	ld	a3,64(a0)
    800027f8:	6585                	lui	a1,0x1
    800027fa:	96ae                	add	a3,a3,a1
    800027fc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027fe:	6d38                	ld	a4,88(a0)
    80002800:	00000697          	auipc	a3,0x0
    80002804:	13068693          	addi	a3,a3,304 # 80002930 <usertrap>
    80002808:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000280a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000280c:	8692                	mv	a3,tp
    8000280e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002810:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002814:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002818:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000281c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002820:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002822:	6f18                	ld	a4,24(a4)
    80002824:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002828:	6928                	ld	a0,80(a0)
    8000282a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000282c:	00005717          	auipc	a4,0x5
    80002830:	87070713          	addi	a4,a4,-1936 # 8000709c <userret>
    80002834:	8f11                	sub	a4,a4,a2
    80002836:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002838:	577d                	li	a4,-1
    8000283a:	177e                	slli	a4,a4,0x3f
    8000283c:	8d59                	or	a0,a0,a4
    8000283e:	9782                	jalr	a5
}
    80002840:	60a2                	ld	ra,8(sp)
    80002842:	6402                	ld	s0,0(sp)
    80002844:	0141                	addi	sp,sp,16
    80002846:	8082                	ret

0000000080002848 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002848:	1101                	addi	sp,sp,-32
    8000284a:	ec06                	sd	ra,24(sp)
    8000284c:	e822                	sd	s0,16(sp)
    8000284e:	e426                	sd	s1,8(sp)
    80002850:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002852:	00015497          	auipc	s1,0x15
    80002856:	a7e48493          	addi	s1,s1,-1410 # 800172d0 <tickslock>
    8000285a:	8526                	mv	a0,s1
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	37a080e7          	jalr	890(ra) # 80000bd6 <acquire>
  ticks++;
    80002864:	00007517          	auipc	a0,0x7
    80002868:	9cc50513          	addi	a0,a0,-1588 # 80009230 <ticks>
    8000286c:	411c                	lw	a5,0(a0)
    8000286e:	2785                	addiw	a5,a5,1
    80002870:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002872:	00000097          	auipc	ra,0x0
    80002876:	8e4080e7          	jalr	-1820(ra) # 80002156 <wakeup>
  release(&tickslock);
    8000287a:	8526                	mv	a0,s1
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	40e080e7          	jalr	1038(ra) # 80000c8a <release>
}
    80002884:	60e2                	ld	ra,24(sp)
    80002886:	6442                	ld	s0,16(sp)
    80002888:	64a2                	ld	s1,8(sp)
    8000288a:	6105                	addi	sp,sp,32
    8000288c:	8082                	ret

000000008000288e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000288e:	1101                	addi	sp,sp,-32
    80002890:	ec06                	sd	ra,24(sp)
    80002892:	e822                	sd	s0,16(sp)
    80002894:	e426                	sd	s1,8(sp)
    80002896:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002898:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000289c:	00074d63          	bltz	a4,800028b6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028a0:	57fd                	li	a5,-1
    800028a2:	17fe                	slli	a5,a5,0x3f
    800028a4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028a6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028a8:	06f70363          	beq	a4,a5,8000290e <devintr+0x80>
  }
}
    800028ac:	60e2                	ld	ra,24(sp)
    800028ae:	6442                	ld	s0,16(sp)
    800028b0:	64a2                	ld	s1,8(sp)
    800028b2:	6105                	addi	sp,sp,32
    800028b4:	8082                	ret
     (scause & 0xff) == 9){
    800028b6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028ba:	46a5                	li	a3,9
    800028bc:	fed792e3          	bne	a5,a3,800028a0 <devintr+0x12>
    int irq = plic_claim();
    800028c0:	00003097          	auipc	ra,0x3
    800028c4:	4d8080e7          	jalr	1240(ra) # 80005d98 <plic_claim>
    800028c8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028ca:	47a9                	li	a5,10
    800028cc:	02f50763          	beq	a0,a5,800028fa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028d0:	4785                	li	a5,1
    800028d2:	02f50963          	beq	a0,a5,80002904 <devintr+0x76>
    return 1;
    800028d6:	4505                	li	a0,1
    } else if(irq){
    800028d8:	d8f1                	beqz	s1,800028ac <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028da:	85a6                	mv	a1,s1
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	a1c50513          	addi	a0,a0,-1508 # 800082f8 <states.0+0x38>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	ca4080e7          	jalr	-860(ra) # 80000588 <printf>
      plic_complete(irq);
    800028ec:	8526                	mv	a0,s1
    800028ee:	00003097          	auipc	ra,0x3
    800028f2:	4ce080e7          	jalr	1230(ra) # 80005dbc <plic_complete>
    return 1;
    800028f6:	4505                	li	a0,1
    800028f8:	bf55                	j	800028ac <devintr+0x1e>
      uartintr();
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	0a0080e7          	jalr	160(ra) # 8000099a <uartintr>
    80002902:	b7ed                	j	800028ec <devintr+0x5e>
      virtio_disk_intr();
    80002904:	00004097          	auipc	ra,0x4
    80002908:	984080e7          	jalr	-1660(ra) # 80006288 <virtio_disk_intr>
    8000290c:	b7c5                	j	800028ec <devintr+0x5e>
    if(cpuid() == 0){
    8000290e:	fffff097          	auipc	ra,0xfffff
    80002912:	0aa080e7          	jalr	170(ra) # 800019b8 <cpuid>
    80002916:	c901                	beqz	a0,80002926 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002918:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000291c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000291e:	14479073          	csrw	sip,a5
    return 2;
    80002922:	4509                	li	a0,2
    80002924:	b761                	j	800028ac <devintr+0x1e>
      clockintr();
    80002926:	00000097          	auipc	ra,0x0
    8000292a:	f22080e7          	jalr	-222(ra) # 80002848 <clockintr>
    8000292e:	b7ed                	j	80002918 <devintr+0x8a>

0000000080002930 <usertrap>:
{
    80002930:	1101                	addi	sp,sp,-32
    80002932:	ec06                	sd	ra,24(sp)
    80002934:	e822                	sd	s0,16(sp)
    80002936:	e426                	sd	s1,8(sp)
    80002938:	e04a                	sd	s2,0(sp)
    8000293a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000293c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002940:	1007f793          	andi	a5,a5,256
    80002944:	e3b1                	bnez	a5,80002988 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002946:	00003797          	auipc	a5,0x3
    8000294a:	34a78793          	addi	a5,a5,842 # 80005c90 <kernelvec>
    8000294e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002952:	fffff097          	auipc	ra,0xfffff
    80002956:	092080e7          	jalr	146(ra) # 800019e4 <myproc>
    8000295a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000295c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000295e:	14102773          	csrr	a4,sepc
    80002962:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002964:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002968:	47a1                	li	a5,8
    8000296a:	02f70763          	beq	a4,a5,80002998 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000296e:	00000097          	auipc	ra,0x0
    80002972:	f20080e7          	jalr	-224(ra) # 8000288e <devintr>
    80002976:	892a                	mv	s2,a0
    80002978:	c151                	beqz	a0,800029fc <usertrap+0xcc>
  if(killed(p))
    8000297a:	8526                	mv	a0,s1
    8000297c:	00000097          	auipc	ra,0x0
    80002980:	a1e080e7          	jalr	-1506(ra) # 8000239a <killed>
    80002984:	c929                	beqz	a0,800029d6 <usertrap+0xa6>
    80002986:	a099                	j	800029cc <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002988:	00006517          	auipc	a0,0x6
    8000298c:	99050513          	addi	a0,a0,-1648 # 80008318 <states.0+0x58>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	bae080e7          	jalr	-1106(ra) # 8000053e <panic>
    if(killed(p))
    80002998:	00000097          	auipc	ra,0x0
    8000299c:	a02080e7          	jalr	-1534(ra) # 8000239a <killed>
    800029a0:	e921                	bnez	a0,800029f0 <usertrap+0xc0>
    p->trapframe->epc += 4;
    800029a2:	6cb8                	ld	a4,88(s1)
    800029a4:	6f1c                	ld	a5,24(a4)
    800029a6:	0791                	addi	a5,a5,4
    800029a8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029aa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029ae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b2:	10079073          	csrw	sstatus,a5
    syscall();
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	2d4080e7          	jalr	724(ra) # 80002c8a <syscall>
  if(killed(p))
    800029be:	8526                	mv	a0,s1
    800029c0:	00000097          	auipc	ra,0x0
    800029c4:	9da080e7          	jalr	-1574(ra) # 8000239a <killed>
    800029c8:	c911                	beqz	a0,800029dc <usertrap+0xac>
    800029ca:	4901                	li	s2,0
    exit(-1);
    800029cc:	557d                	li	a0,-1
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	858080e7          	jalr	-1960(ra) # 80002226 <exit>
  if(which_dev == 2)
    800029d6:	4789                	li	a5,2
    800029d8:	04f90f63          	beq	s2,a5,80002a36 <usertrap+0x106>
  usertrapret();
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	dd6080e7          	jalr	-554(ra) # 800027b2 <usertrapret>
}
    800029e4:	60e2                	ld	ra,24(sp)
    800029e6:	6442                	ld	s0,16(sp)
    800029e8:	64a2                	ld	s1,8(sp)
    800029ea:	6902                	ld	s2,0(sp)
    800029ec:	6105                	addi	sp,sp,32
    800029ee:	8082                	ret
      exit(-1);
    800029f0:	557d                	li	a0,-1
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	834080e7          	jalr	-1996(ra) # 80002226 <exit>
    800029fa:	b765                	j	800029a2 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029fc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a00:	5890                	lw	a2,48(s1)
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	93650513          	addi	a0,a0,-1738 # 80008338 <states.0+0x78>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b7e080e7          	jalr	-1154(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a12:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a16:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a1a:	00006517          	auipc	a0,0x6
    80002a1e:	94e50513          	addi	a0,a0,-1714 # 80008368 <states.0+0xa8>
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	b66080e7          	jalr	-1178(ra) # 80000588 <printf>
    setkilled(p);
    80002a2a:	8526                	mv	a0,s1
    80002a2c:	00000097          	auipc	ra,0x0
    80002a30:	942080e7          	jalr	-1726(ra) # 8000236e <setkilled>
    80002a34:	b769                	j	800029be <usertrap+0x8e>
    yield();
    80002a36:	fffff097          	auipc	ra,0xfffff
    80002a3a:	680080e7          	jalr	1664(ra) # 800020b6 <yield>
    80002a3e:	bf79                	j	800029dc <usertrap+0xac>

0000000080002a40 <kerneltrap>:
{
    80002a40:	7179                	addi	sp,sp,-48
    80002a42:	f406                	sd	ra,40(sp)
    80002a44:	f022                	sd	s0,32(sp)
    80002a46:	ec26                	sd	s1,24(sp)
    80002a48:	e84a                	sd	s2,16(sp)
    80002a4a:	e44e                	sd	s3,8(sp)
    80002a4c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a4e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a52:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a56:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a5a:	1004f793          	andi	a5,s1,256
    80002a5e:	cb85                	beqz	a5,80002a8e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a60:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a64:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a66:	ef85                	bnez	a5,80002a9e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	e26080e7          	jalr	-474(ra) # 8000288e <devintr>
    80002a70:	cd1d                	beqz	a0,80002aae <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a72:	4789                	li	a5,2
    80002a74:	06f50a63          	beq	a0,a5,80002ae8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a78:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a7c:	10049073          	csrw	sstatus,s1
}
    80002a80:	70a2                	ld	ra,40(sp)
    80002a82:	7402                	ld	s0,32(sp)
    80002a84:	64e2                	ld	s1,24(sp)
    80002a86:	6942                	ld	s2,16(sp)
    80002a88:	69a2                	ld	s3,8(sp)
    80002a8a:	6145                	addi	sp,sp,48
    80002a8c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a8e:	00006517          	auipc	a0,0x6
    80002a92:	8fa50513          	addi	a0,a0,-1798 # 80008388 <states.0+0xc8>
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	aa8080e7          	jalr	-1368(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a9e:	00006517          	auipc	a0,0x6
    80002aa2:	91250513          	addi	a0,a0,-1774 # 800083b0 <states.0+0xf0>
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	a98080e7          	jalr	-1384(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002aae:	85ce                	mv	a1,s3
    80002ab0:	00006517          	auipc	a0,0x6
    80002ab4:	92050513          	addi	a0,a0,-1760 # 800083d0 <states.0+0x110>
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	ad0080e7          	jalr	-1328(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ac0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ac4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ac8:	00006517          	auipc	a0,0x6
    80002acc:	91850513          	addi	a0,a0,-1768 # 800083e0 <states.0+0x120>
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	ab8080e7          	jalr	-1352(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ad8:	00006517          	auipc	a0,0x6
    80002adc:	92050513          	addi	a0,a0,-1760 # 800083f8 <states.0+0x138>
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	a5e080e7          	jalr	-1442(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	efc080e7          	jalr	-260(ra) # 800019e4 <myproc>
    80002af0:	d541                	beqz	a0,80002a78 <kerneltrap+0x38>
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	ef2080e7          	jalr	-270(ra) # 800019e4 <myproc>
    80002afa:	4d18                	lw	a4,24(a0)
    80002afc:	4791                	li	a5,4
    80002afe:	f6f71de3          	bne	a4,a5,80002a78 <kerneltrap+0x38>
    yield();
    80002b02:	fffff097          	auipc	ra,0xfffff
    80002b06:	5b4080e7          	jalr	1460(ra) # 800020b6 <yield>
    80002b0a:	b7bd                	j	80002a78 <kerneltrap+0x38>

0000000080002b0c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b0c:	1101                	addi	sp,sp,-32
    80002b0e:	ec06                	sd	ra,24(sp)
    80002b10:	e822                	sd	s0,16(sp)
    80002b12:	e426                	sd	s1,8(sp)
    80002b14:	1000                	addi	s0,sp,32
    80002b16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b18:	fffff097          	auipc	ra,0xfffff
    80002b1c:	ecc080e7          	jalr	-308(ra) # 800019e4 <myproc>
  switch (n) {
    80002b20:	4795                	li	a5,5
    80002b22:	0497e163          	bltu	a5,s1,80002b64 <argraw+0x58>
    80002b26:	048a                	slli	s1,s1,0x2
    80002b28:	00006717          	auipc	a4,0x6
    80002b2c:	90870713          	addi	a4,a4,-1784 # 80008430 <states.0+0x170>
    80002b30:	94ba                	add	s1,s1,a4
    80002b32:	409c                	lw	a5,0(s1)
    80002b34:	97ba                	add	a5,a5,a4
    80002b36:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b38:	6d3c                	ld	a5,88(a0)
    80002b3a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b3c:	60e2                	ld	ra,24(sp)
    80002b3e:	6442                	ld	s0,16(sp)
    80002b40:	64a2                	ld	s1,8(sp)
    80002b42:	6105                	addi	sp,sp,32
    80002b44:	8082                	ret
    return p->trapframe->a1;
    80002b46:	6d3c                	ld	a5,88(a0)
    80002b48:	7fa8                	ld	a0,120(a5)
    80002b4a:	bfcd                	j	80002b3c <argraw+0x30>
    return p->trapframe->a2;
    80002b4c:	6d3c                	ld	a5,88(a0)
    80002b4e:	63c8                	ld	a0,128(a5)
    80002b50:	b7f5                	j	80002b3c <argraw+0x30>
    return p->trapframe->a3;
    80002b52:	6d3c                	ld	a5,88(a0)
    80002b54:	67c8                	ld	a0,136(a5)
    80002b56:	b7dd                	j	80002b3c <argraw+0x30>
    return p->trapframe->a4;
    80002b58:	6d3c                	ld	a5,88(a0)
    80002b5a:	6bc8                	ld	a0,144(a5)
    80002b5c:	b7c5                	j	80002b3c <argraw+0x30>
    return p->trapframe->a5;
    80002b5e:	6d3c                	ld	a5,88(a0)
    80002b60:	6fc8                	ld	a0,152(a5)
    80002b62:	bfe9                	j	80002b3c <argraw+0x30>
  panic("argraw");
    80002b64:	00006517          	auipc	a0,0x6
    80002b68:	8a450513          	addi	a0,a0,-1884 # 80008408 <states.0+0x148>
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	9d2080e7          	jalr	-1582(ra) # 8000053e <panic>

0000000080002b74 <fetchaddr>:
{
    80002b74:	1101                	addi	sp,sp,-32
    80002b76:	ec06                	sd	ra,24(sp)
    80002b78:	e822                	sd	s0,16(sp)
    80002b7a:	e426                	sd	s1,8(sp)
    80002b7c:	e04a                	sd	s2,0(sp)
    80002b7e:	1000                	addi	s0,sp,32
    80002b80:	84aa                	mv	s1,a0
    80002b82:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b84:	fffff097          	auipc	ra,0xfffff
    80002b88:	e60080e7          	jalr	-416(ra) # 800019e4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b8c:	653c                	ld	a5,72(a0)
    80002b8e:	02f4f863          	bgeu	s1,a5,80002bbe <fetchaddr+0x4a>
    80002b92:	00848713          	addi	a4,s1,8
    80002b96:	02e7e663          	bltu	a5,a4,80002bc2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b9a:	46a1                	li	a3,8
    80002b9c:	8626                	mv	a2,s1
    80002b9e:	85ca                	mv	a1,s2
    80002ba0:	6928                	ld	a0,80(a0)
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	b8a080e7          	jalr	-1142(ra) # 8000172c <copyin>
    80002baa:	00a03533          	snez	a0,a0
    80002bae:	40a00533          	neg	a0,a0
}
    80002bb2:	60e2                	ld	ra,24(sp)
    80002bb4:	6442                	ld	s0,16(sp)
    80002bb6:	64a2                	ld	s1,8(sp)
    80002bb8:	6902                	ld	s2,0(sp)
    80002bba:	6105                	addi	sp,sp,32
    80002bbc:	8082                	ret
    return -1;
    80002bbe:	557d                	li	a0,-1
    80002bc0:	bfcd                	j	80002bb2 <fetchaddr+0x3e>
    80002bc2:	557d                	li	a0,-1
    80002bc4:	b7fd                	j	80002bb2 <fetchaddr+0x3e>

0000000080002bc6 <fetchstr>:
{
    80002bc6:	7179                	addi	sp,sp,-48
    80002bc8:	f406                	sd	ra,40(sp)
    80002bca:	f022                	sd	s0,32(sp)
    80002bcc:	ec26                	sd	s1,24(sp)
    80002bce:	e84a                	sd	s2,16(sp)
    80002bd0:	e44e                	sd	s3,8(sp)
    80002bd2:	1800                	addi	s0,sp,48
    80002bd4:	892a                	mv	s2,a0
    80002bd6:	84ae                	mv	s1,a1
    80002bd8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bda:	fffff097          	auipc	ra,0xfffff
    80002bde:	e0a080e7          	jalr	-502(ra) # 800019e4 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002be2:	86ce                	mv	a3,s3
    80002be4:	864a                	mv	a2,s2
    80002be6:	85a6                	mv	a1,s1
    80002be8:	6928                	ld	a0,80(a0)
    80002bea:	fffff097          	auipc	ra,0xfffff
    80002bee:	bd0080e7          	jalr	-1072(ra) # 800017ba <copyinstr>
    80002bf2:	00054e63          	bltz	a0,80002c0e <fetchstr+0x48>
  return strlen(buf);
    80002bf6:	8526                	mv	a0,s1
    80002bf8:	ffffe097          	auipc	ra,0xffffe
    80002bfc:	256080e7          	jalr	598(ra) # 80000e4e <strlen>
}
    80002c00:	70a2                	ld	ra,40(sp)
    80002c02:	7402                	ld	s0,32(sp)
    80002c04:	64e2                	ld	s1,24(sp)
    80002c06:	6942                	ld	s2,16(sp)
    80002c08:	69a2                	ld	s3,8(sp)
    80002c0a:	6145                	addi	sp,sp,48
    80002c0c:	8082                	ret
    return -1;
    80002c0e:	557d                	li	a0,-1
    80002c10:	bfc5                	j	80002c00 <fetchstr+0x3a>

0000000080002c12 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c12:	1101                	addi	sp,sp,-32
    80002c14:	ec06                	sd	ra,24(sp)
    80002c16:	e822                	sd	s0,16(sp)
    80002c18:	e426                	sd	s1,8(sp)
    80002c1a:	1000                	addi	s0,sp,32
    80002c1c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c1e:	00000097          	auipc	ra,0x0
    80002c22:	eee080e7          	jalr	-274(ra) # 80002b0c <argraw>
    80002c26:	c088                	sw	a0,0(s1)
}
    80002c28:	60e2                	ld	ra,24(sp)
    80002c2a:	6442                	ld	s0,16(sp)
    80002c2c:	64a2                	ld	s1,8(sp)
    80002c2e:	6105                	addi	sp,sp,32
    80002c30:	8082                	ret

0000000080002c32 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c32:	1101                	addi	sp,sp,-32
    80002c34:	ec06                	sd	ra,24(sp)
    80002c36:	e822                	sd	s0,16(sp)
    80002c38:	e426                	sd	s1,8(sp)
    80002c3a:	1000                	addi	s0,sp,32
    80002c3c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	ece080e7          	jalr	-306(ra) # 80002b0c <argraw>
    80002c46:	e088                	sd	a0,0(s1)
}
    80002c48:	60e2                	ld	ra,24(sp)
    80002c4a:	6442                	ld	s0,16(sp)
    80002c4c:	64a2                	ld	s1,8(sp)
    80002c4e:	6105                	addi	sp,sp,32
    80002c50:	8082                	ret

0000000080002c52 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c52:	7179                	addi	sp,sp,-48
    80002c54:	f406                	sd	ra,40(sp)
    80002c56:	f022                	sd	s0,32(sp)
    80002c58:	ec26                	sd	s1,24(sp)
    80002c5a:	e84a                	sd	s2,16(sp)
    80002c5c:	1800                	addi	s0,sp,48
    80002c5e:	84ae                	mv	s1,a1
    80002c60:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c62:	fd840593          	addi	a1,s0,-40
    80002c66:	00000097          	auipc	ra,0x0
    80002c6a:	fcc080e7          	jalr	-52(ra) # 80002c32 <argaddr>
  return fetchstr(addr, buf, max);
    80002c6e:	864a                	mv	a2,s2
    80002c70:	85a6                	mv	a1,s1
    80002c72:	fd843503          	ld	a0,-40(s0)
    80002c76:	00000097          	auipc	ra,0x0
    80002c7a:	f50080e7          	jalr	-176(ra) # 80002bc6 <fetchstr>
}
    80002c7e:	70a2                	ld	ra,40(sp)
    80002c80:	7402                	ld	s0,32(sp)
    80002c82:	64e2                	ld	s1,24(sp)
    80002c84:	6942                	ld	s2,16(sp)
    80002c86:	6145                	addi	sp,sp,48
    80002c88:	8082                	ret

0000000080002c8a <syscall>:
[SYS_map_display]    sys_map_display,
};

void
syscall(void)
{
    80002c8a:	1101                	addi	sp,sp,-32
    80002c8c:	ec06                	sd	ra,24(sp)
    80002c8e:	e822                	sd	s0,16(sp)
    80002c90:	e426                	sd	s1,8(sp)
    80002c92:	e04a                	sd	s2,0(sp)
    80002c94:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c96:	fffff097          	auipc	ra,0xfffff
    80002c9a:	d4e080e7          	jalr	-690(ra) # 800019e4 <myproc>
    80002c9e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ca0:	05853903          	ld	s2,88(a0)
    80002ca4:	0a893783          	ld	a5,168(s2)
    80002ca8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cac:	37fd                	addiw	a5,a5,-1
    80002cae:	4759                	li	a4,22
    80002cb0:	00f76f63          	bltu	a4,a5,80002cce <syscall+0x44>
    80002cb4:	00369713          	slli	a4,a3,0x3
    80002cb8:	00005797          	auipc	a5,0x5
    80002cbc:	79078793          	addi	a5,a5,1936 # 80008448 <syscalls>
    80002cc0:	97ba                	add	a5,a5,a4
    80002cc2:	639c                	ld	a5,0(a5)
    80002cc4:	c789                	beqz	a5,80002cce <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002cc6:	9782                	jalr	a5
    80002cc8:	06a93823          	sd	a0,112(s2)
    80002ccc:	a839                	j	80002cea <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cce:	15848613          	addi	a2,s1,344
    80002cd2:	588c                	lw	a1,48(s1)
    80002cd4:	00005517          	auipc	a0,0x5
    80002cd8:	73c50513          	addi	a0,a0,1852 # 80008410 <states.0+0x150>
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	8ac080e7          	jalr	-1876(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ce4:	6cbc                	ld	a5,88(s1)
    80002ce6:	577d                	li	a4,-1
    80002ce8:	fbb8                	sd	a4,112(a5)
  }
}
    80002cea:	60e2                	ld	ra,24(sp)
    80002cec:	6442                	ld	s0,16(sp)
    80002cee:	64a2                	ld	s1,8(sp)
    80002cf0:	6902                	ld	s2,0(sp)
    80002cf2:	6105                	addi	sp,sp,32
    80002cf4:	8082                	ret

0000000080002cf6 <sys_exit>:
#include "proc.h"


uint64
sys_exit(void)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cfe:	fec40593          	addi	a1,s0,-20
    80002d02:	4501                	li	a0,0
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	f0e080e7          	jalr	-242(ra) # 80002c12 <argint>
  exit(n);
    80002d0c:	fec42503          	lw	a0,-20(s0)
    80002d10:	fffff097          	auipc	ra,0xfffff
    80002d14:	516080e7          	jalr	1302(ra) # 80002226 <exit>
  return 0;  // not reached
}
    80002d18:	4501                	li	a0,0
    80002d1a:	60e2                	ld	ra,24(sp)
    80002d1c:	6442                	ld	s0,16(sp)
    80002d1e:	6105                	addi	sp,sp,32
    80002d20:	8082                	ret

0000000080002d22 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d22:	1141                	addi	sp,sp,-16
    80002d24:	e406                	sd	ra,8(sp)
    80002d26:	e022                	sd	s0,0(sp)
    80002d28:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	cba080e7          	jalr	-838(ra) # 800019e4 <myproc>
}
    80002d32:	5908                	lw	a0,48(a0)
    80002d34:	60a2                	ld	ra,8(sp)
    80002d36:	6402                	ld	s0,0(sp)
    80002d38:	0141                	addi	sp,sp,16
    80002d3a:	8082                	ret

0000000080002d3c <sys_fork>:

uint64
sys_fork(void)
{
    80002d3c:	1141                	addi	sp,sp,-16
    80002d3e:	e406                	sd	ra,8(sp)
    80002d40:	e022                	sd	s0,0(sp)
    80002d42:	0800                	addi	s0,sp,16
  return fork();
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	0bc080e7          	jalr	188(ra) # 80001e00 <fork>
}
    80002d4c:	60a2                	ld	ra,8(sp)
    80002d4e:	6402                	ld	s0,0(sp)
    80002d50:	0141                	addi	sp,sp,16
    80002d52:	8082                	ret

0000000080002d54 <sys_wait>:

uint64
sys_wait(void)
{
    80002d54:	1101                	addi	sp,sp,-32
    80002d56:	ec06                	sd	ra,24(sp)
    80002d58:	e822                	sd	s0,16(sp)
    80002d5a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d5c:	fe840593          	addi	a1,s0,-24
    80002d60:	4501                	li	a0,0
    80002d62:	00000097          	auipc	ra,0x0
    80002d66:	ed0080e7          	jalr	-304(ra) # 80002c32 <argaddr>
  return wait(p);
    80002d6a:	fe843503          	ld	a0,-24(s0)
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	65e080e7          	jalr	1630(ra) # 800023cc <wait>
}
    80002d76:	60e2                	ld	ra,24(sp)
    80002d78:	6442                	ld	s0,16(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret

0000000080002d7e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d7e:	7179                	addi	sp,sp,-48
    80002d80:	f406                	sd	ra,40(sp)
    80002d82:	f022                	sd	s0,32(sp)
    80002d84:	ec26                	sd	s1,24(sp)
    80002d86:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d88:	fdc40593          	addi	a1,s0,-36
    80002d8c:	4501                	li	a0,0
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	e84080e7          	jalr	-380(ra) # 80002c12 <argint>
  addr = myproc()->sz;
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	c4e080e7          	jalr	-946(ra) # 800019e4 <myproc>
    80002d9e:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002da0:	fdc42503          	lw	a0,-36(s0)
    80002da4:	fffff097          	auipc	ra,0xfffff
    80002da8:	000080e7          	jalr	ra # 80001da4 <growproc>
    80002dac:	00054863          	bltz	a0,80002dbc <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002db0:	8526                	mv	a0,s1
    80002db2:	70a2                	ld	ra,40(sp)
    80002db4:	7402                	ld	s0,32(sp)
    80002db6:	64e2                	ld	s1,24(sp)
    80002db8:	6145                	addi	sp,sp,48
    80002dba:	8082                	ret
    return -1;
    80002dbc:	54fd                	li	s1,-1
    80002dbe:	bfcd                	j	80002db0 <sys_sbrk+0x32>

0000000080002dc0 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dc0:	7139                	addi	sp,sp,-64
    80002dc2:	fc06                	sd	ra,56(sp)
    80002dc4:	f822                	sd	s0,48(sp)
    80002dc6:	f426                	sd	s1,40(sp)
    80002dc8:	f04a                	sd	s2,32(sp)
    80002dca:	ec4e                	sd	s3,24(sp)
    80002dcc:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002dce:	fcc40593          	addi	a1,s0,-52
    80002dd2:	4501                	li	a0,0
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	e3e080e7          	jalr	-450(ra) # 80002c12 <argint>
  acquire(&tickslock);
    80002ddc:	00014517          	auipc	a0,0x14
    80002de0:	4f450513          	addi	a0,a0,1268 # 800172d0 <tickslock>
    80002de4:	ffffe097          	auipc	ra,0xffffe
    80002de8:	df2080e7          	jalr	-526(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002dec:	00006917          	auipc	s2,0x6
    80002df0:	44492903          	lw	s2,1092(s2) # 80009230 <ticks>
  while(ticks - ticks0 < n){
    80002df4:	fcc42783          	lw	a5,-52(s0)
    80002df8:	cf9d                	beqz	a5,80002e36 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dfa:	00014997          	auipc	s3,0x14
    80002dfe:	4d698993          	addi	s3,s3,1238 # 800172d0 <tickslock>
    80002e02:	00006497          	auipc	s1,0x6
    80002e06:	42e48493          	addi	s1,s1,1070 # 80009230 <ticks>
    if(killed(myproc())){
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	bda080e7          	jalr	-1062(ra) # 800019e4 <myproc>
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	588080e7          	jalr	1416(ra) # 8000239a <killed>
    80002e1a:	ed15                	bnez	a0,80002e56 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e1c:	85ce                	mv	a1,s3
    80002e1e:	8526                	mv	a0,s1
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	2d2080e7          	jalr	722(ra) # 800020f2 <sleep>
  while(ticks - ticks0 < n){
    80002e28:	409c                	lw	a5,0(s1)
    80002e2a:	412787bb          	subw	a5,a5,s2
    80002e2e:	fcc42703          	lw	a4,-52(s0)
    80002e32:	fce7ece3          	bltu	a5,a4,80002e0a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e36:	00014517          	auipc	a0,0x14
    80002e3a:	49a50513          	addi	a0,a0,1178 # 800172d0 <tickslock>
    80002e3e:	ffffe097          	auipc	ra,0xffffe
    80002e42:	e4c080e7          	jalr	-436(ra) # 80000c8a <release>
  return 0;
    80002e46:	4501                	li	a0,0
}
    80002e48:	70e2                	ld	ra,56(sp)
    80002e4a:	7442                	ld	s0,48(sp)
    80002e4c:	74a2                	ld	s1,40(sp)
    80002e4e:	7902                	ld	s2,32(sp)
    80002e50:	69e2                	ld	s3,24(sp)
    80002e52:	6121                	addi	sp,sp,64
    80002e54:	8082                	ret
      release(&tickslock);
    80002e56:	00014517          	auipc	a0,0x14
    80002e5a:	47a50513          	addi	a0,a0,1146 # 800172d0 <tickslock>
    80002e5e:	ffffe097          	auipc	ra,0xffffe
    80002e62:	e2c080e7          	jalr	-468(ra) # 80000c8a <release>
      return -1;
    80002e66:	557d                	li	a0,-1
    80002e68:	b7c5                	j	80002e48 <sys_sleep+0x88>

0000000080002e6a <sys_kill>:

uint64
sys_kill(void)
{
    80002e6a:	1101                	addi	sp,sp,-32
    80002e6c:	ec06                	sd	ra,24(sp)
    80002e6e:	e822                	sd	s0,16(sp)
    80002e70:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e72:	fec40593          	addi	a1,s0,-20
    80002e76:	4501                	li	a0,0
    80002e78:	00000097          	auipc	ra,0x0
    80002e7c:	d9a080e7          	jalr	-614(ra) # 80002c12 <argint>
  return kill(pid);
    80002e80:	fec42503          	lw	a0,-20(s0)
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	478080e7          	jalr	1144(ra) # 800022fc <kill>
}
    80002e8c:	60e2                	ld	ra,24(sp)
    80002e8e:	6442                	ld	s0,16(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret

0000000080002e94 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	e426                	sd	s1,8(sp)
    80002e9c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e9e:	00014517          	auipc	a0,0x14
    80002ea2:	43250513          	addi	a0,a0,1074 # 800172d0 <tickslock>
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	d30080e7          	jalr	-720(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002eae:	00006497          	auipc	s1,0x6
    80002eb2:	3824a483          	lw	s1,898(s1) # 80009230 <ticks>
  release(&tickslock);
    80002eb6:	00014517          	auipc	a0,0x14
    80002eba:	41a50513          	addi	a0,a0,1050 # 800172d0 <tickslock>
    80002ebe:	ffffe097          	auipc	ra,0xffffe
    80002ec2:	dcc080e7          	jalr	-564(ra) # 80000c8a <release>
  return xticks;
}
    80002ec6:	02049513          	slli	a0,s1,0x20
    80002eca:	9101                	srli	a0,a0,0x20
    80002ecc:	60e2                	ld	ra,24(sp)
    80002ece:	6442                	ld	s0,16(sp)
    80002ed0:	64a2                	ld	s1,8(sp)
    80002ed2:	6105                	addi	sp,sp,32
    80002ed4:	8082                	ret

0000000080002ed6 <sys_flip_display>:
// calling process's address space.
//
// TODO: Students implement this syscall.
uint64
sys_flip_display(void)
{
    80002ed6:	1141                	addi	sp,sp,-16
    80002ed8:	e422                	sd	s0,8(sp)
    80002eda:	0800                	addi	s0,sp,16
  return -1;
}
    80002edc:	557d                	li	a0,-1
    80002ede:	6422                	ld	s0,8(sp)
    80002ee0:	0141                	addi	sp,sp,16
    80002ee2:	8082                	ret

0000000080002ee4 <sys_map_display>:
// Returns the mapped virtual address on success, (uint64)-1 on failure.
//
// TODO: Students implement this syscall.
uint64
sys_map_display(void)
{
    80002ee4:	1101                	addi	sp,sp,-32
    80002ee6:	ec06                	sd	ra,24(sp)
    80002ee8:	e822                	sd	s0,16(sp)
    80002eea:	1000                	addi	s0,sp,32
  uint64 addr;
  argaddr(0, &addr);
    80002eec:	fe840593          	addi	a1,s0,-24
    80002ef0:	4501                	li	a0,0
    80002ef2:	00000097          	auipc	ra,0x0
    80002ef6:	d40080e7          	jalr	-704(ra) # 80002c32 <argaddr>
  return (uint64)map_display((void*)addr);
    80002efa:	fe843503          	ld	a0,-24(s0)
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	756080e7          	jalr	1878(ra) # 80002654 <map_display>
}
    80002f06:	60e2                	ld	ra,24(sp)
    80002f08:	6442                	ld	s0,16(sp)
    80002f0a:	6105                	addi	sp,sp,32
    80002f0c:	8082                	ret

0000000080002f0e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f0e:	7179                	addi	sp,sp,-48
    80002f10:	f406                	sd	ra,40(sp)
    80002f12:	f022                	sd	s0,32(sp)
    80002f14:	ec26                	sd	s1,24(sp)
    80002f16:	e84a                	sd	s2,16(sp)
    80002f18:	e44e                	sd	s3,8(sp)
    80002f1a:	e052                	sd	s4,0(sp)
    80002f1c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f1e:	00005597          	auipc	a1,0x5
    80002f22:	5ea58593          	addi	a1,a1,1514 # 80008508 <syscalls+0xc0>
    80002f26:	00014517          	auipc	a0,0x14
    80002f2a:	3c250513          	addi	a0,a0,962 # 800172e8 <bcache>
    80002f2e:	ffffe097          	auipc	ra,0xffffe
    80002f32:	c18080e7          	jalr	-1000(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f36:	0001c797          	auipc	a5,0x1c
    80002f3a:	3b278793          	addi	a5,a5,946 # 8001f2e8 <bcache+0x8000>
    80002f3e:	0001c717          	auipc	a4,0x1c
    80002f42:	61270713          	addi	a4,a4,1554 # 8001f550 <bcache+0x8268>
    80002f46:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f4a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f4e:	00014497          	auipc	s1,0x14
    80002f52:	3b248493          	addi	s1,s1,946 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80002f56:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f58:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f5a:	00005a17          	auipc	s4,0x5
    80002f5e:	5b6a0a13          	addi	s4,s4,1462 # 80008510 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f62:	2b893783          	ld	a5,696(s2)
    80002f66:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f68:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f6c:	85d2                	mv	a1,s4
    80002f6e:	01048513          	addi	a0,s1,16
    80002f72:	00001097          	auipc	ra,0x1
    80002f76:	4c4080e7          	jalr	1220(ra) # 80004436 <initsleeplock>
    bcache.head.next->prev = b;
    80002f7a:	2b893783          	ld	a5,696(s2)
    80002f7e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f80:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f84:	45848493          	addi	s1,s1,1112
    80002f88:	fd349de3          	bne	s1,s3,80002f62 <binit+0x54>
  }
}
    80002f8c:	70a2                	ld	ra,40(sp)
    80002f8e:	7402                	ld	s0,32(sp)
    80002f90:	64e2                	ld	s1,24(sp)
    80002f92:	6942                	ld	s2,16(sp)
    80002f94:	69a2                	ld	s3,8(sp)
    80002f96:	6a02                	ld	s4,0(sp)
    80002f98:	6145                	addi	sp,sp,48
    80002f9a:	8082                	ret

0000000080002f9c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f9c:	7179                	addi	sp,sp,-48
    80002f9e:	f406                	sd	ra,40(sp)
    80002fa0:	f022                	sd	s0,32(sp)
    80002fa2:	ec26                	sd	s1,24(sp)
    80002fa4:	e84a                	sd	s2,16(sp)
    80002fa6:	e44e                	sd	s3,8(sp)
    80002fa8:	1800                	addi	s0,sp,48
    80002faa:	892a                	mv	s2,a0
    80002fac:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002fae:	00014517          	auipc	a0,0x14
    80002fb2:	33a50513          	addi	a0,a0,826 # 800172e8 <bcache>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	c20080e7          	jalr	-992(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fbe:	0001c497          	auipc	s1,0x1c
    80002fc2:	5e24b483          	ld	s1,1506(s1) # 8001f5a0 <bcache+0x82b8>
    80002fc6:	0001c797          	auipc	a5,0x1c
    80002fca:	58a78793          	addi	a5,a5,1418 # 8001f550 <bcache+0x8268>
    80002fce:	02f48f63          	beq	s1,a5,8000300c <bread+0x70>
    80002fd2:	873e                	mv	a4,a5
    80002fd4:	a021                	j	80002fdc <bread+0x40>
    80002fd6:	68a4                	ld	s1,80(s1)
    80002fd8:	02e48a63          	beq	s1,a4,8000300c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fdc:	449c                	lw	a5,8(s1)
    80002fde:	ff279ce3          	bne	a5,s2,80002fd6 <bread+0x3a>
    80002fe2:	44dc                	lw	a5,12(s1)
    80002fe4:	ff3799e3          	bne	a5,s3,80002fd6 <bread+0x3a>
      b->refcnt++;
    80002fe8:	40bc                	lw	a5,64(s1)
    80002fea:	2785                	addiw	a5,a5,1
    80002fec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fee:	00014517          	auipc	a0,0x14
    80002ff2:	2fa50513          	addi	a0,a0,762 # 800172e8 <bcache>
    80002ff6:	ffffe097          	auipc	ra,0xffffe
    80002ffa:	c94080e7          	jalr	-876(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002ffe:	01048513          	addi	a0,s1,16
    80003002:	00001097          	auipc	ra,0x1
    80003006:	46e080e7          	jalr	1134(ra) # 80004470 <acquiresleep>
      return b;
    8000300a:	a8b9                	j	80003068 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000300c:	0001c497          	auipc	s1,0x1c
    80003010:	58c4b483          	ld	s1,1420(s1) # 8001f598 <bcache+0x82b0>
    80003014:	0001c797          	auipc	a5,0x1c
    80003018:	53c78793          	addi	a5,a5,1340 # 8001f550 <bcache+0x8268>
    8000301c:	00f48863          	beq	s1,a5,8000302c <bread+0x90>
    80003020:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003022:	40bc                	lw	a5,64(s1)
    80003024:	cf81                	beqz	a5,8000303c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003026:	64a4                	ld	s1,72(s1)
    80003028:	fee49de3          	bne	s1,a4,80003022 <bread+0x86>
  panic("bget: no buffers");
    8000302c:	00005517          	auipc	a0,0x5
    80003030:	4ec50513          	addi	a0,a0,1260 # 80008518 <syscalls+0xd0>
    80003034:	ffffd097          	auipc	ra,0xffffd
    80003038:	50a080e7          	jalr	1290(ra) # 8000053e <panic>
      b->dev = dev;
    8000303c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003040:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003044:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003048:	4785                	li	a5,1
    8000304a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000304c:	00014517          	auipc	a0,0x14
    80003050:	29c50513          	addi	a0,a0,668 # 800172e8 <bcache>
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	c36080e7          	jalr	-970(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000305c:	01048513          	addi	a0,s1,16
    80003060:	00001097          	auipc	ra,0x1
    80003064:	410080e7          	jalr	1040(ra) # 80004470 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003068:	409c                	lw	a5,0(s1)
    8000306a:	cb89                	beqz	a5,8000307c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000306c:	8526                	mv	a0,s1
    8000306e:	70a2                	ld	ra,40(sp)
    80003070:	7402                	ld	s0,32(sp)
    80003072:	64e2                	ld	s1,24(sp)
    80003074:	6942                	ld	s2,16(sp)
    80003076:	69a2                	ld	s3,8(sp)
    80003078:	6145                	addi	sp,sp,48
    8000307a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000307c:	4581                	li	a1,0
    8000307e:	8526                	mv	a0,s1
    80003080:	00003097          	auipc	ra,0x3
    80003084:	fd4080e7          	jalr	-44(ra) # 80006054 <virtio_disk_rw>
    b->valid = 1;
    80003088:	4785                	li	a5,1
    8000308a:	c09c                	sw	a5,0(s1)
  return b;
    8000308c:	b7c5                	j	8000306c <bread+0xd0>

000000008000308e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000308e:	1101                	addi	sp,sp,-32
    80003090:	ec06                	sd	ra,24(sp)
    80003092:	e822                	sd	s0,16(sp)
    80003094:	e426                	sd	s1,8(sp)
    80003096:	1000                	addi	s0,sp,32
    80003098:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000309a:	0541                	addi	a0,a0,16
    8000309c:	00001097          	auipc	ra,0x1
    800030a0:	46e080e7          	jalr	1134(ra) # 8000450a <holdingsleep>
    800030a4:	cd01                	beqz	a0,800030bc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030a6:	4585                	li	a1,1
    800030a8:	8526                	mv	a0,s1
    800030aa:	00003097          	auipc	ra,0x3
    800030ae:	faa080e7          	jalr	-86(ra) # 80006054 <virtio_disk_rw>
}
    800030b2:	60e2                	ld	ra,24(sp)
    800030b4:	6442                	ld	s0,16(sp)
    800030b6:	64a2                	ld	s1,8(sp)
    800030b8:	6105                	addi	sp,sp,32
    800030ba:	8082                	ret
    panic("bwrite");
    800030bc:	00005517          	auipc	a0,0x5
    800030c0:	47450513          	addi	a0,a0,1140 # 80008530 <syscalls+0xe8>
    800030c4:	ffffd097          	auipc	ra,0xffffd
    800030c8:	47a080e7          	jalr	1146(ra) # 8000053e <panic>

00000000800030cc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030cc:	1101                	addi	sp,sp,-32
    800030ce:	ec06                	sd	ra,24(sp)
    800030d0:	e822                	sd	s0,16(sp)
    800030d2:	e426                	sd	s1,8(sp)
    800030d4:	e04a                	sd	s2,0(sp)
    800030d6:	1000                	addi	s0,sp,32
    800030d8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030da:	01050913          	addi	s2,a0,16
    800030de:	854a                	mv	a0,s2
    800030e0:	00001097          	auipc	ra,0x1
    800030e4:	42a080e7          	jalr	1066(ra) # 8000450a <holdingsleep>
    800030e8:	c92d                	beqz	a0,8000315a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030ea:	854a                	mv	a0,s2
    800030ec:	00001097          	auipc	ra,0x1
    800030f0:	3da080e7          	jalr	986(ra) # 800044c6 <releasesleep>

  acquire(&bcache.lock);
    800030f4:	00014517          	auipc	a0,0x14
    800030f8:	1f450513          	addi	a0,a0,500 # 800172e8 <bcache>
    800030fc:	ffffe097          	auipc	ra,0xffffe
    80003100:	ada080e7          	jalr	-1318(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003104:	40bc                	lw	a5,64(s1)
    80003106:	37fd                	addiw	a5,a5,-1
    80003108:	0007871b          	sext.w	a4,a5
    8000310c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000310e:	eb05                	bnez	a4,8000313e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003110:	68bc                	ld	a5,80(s1)
    80003112:	64b8                	ld	a4,72(s1)
    80003114:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003116:	64bc                	ld	a5,72(s1)
    80003118:	68b8                	ld	a4,80(s1)
    8000311a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000311c:	0001c797          	auipc	a5,0x1c
    80003120:	1cc78793          	addi	a5,a5,460 # 8001f2e8 <bcache+0x8000>
    80003124:	2b87b703          	ld	a4,696(a5)
    80003128:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000312a:	0001c717          	auipc	a4,0x1c
    8000312e:	42670713          	addi	a4,a4,1062 # 8001f550 <bcache+0x8268>
    80003132:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003134:	2b87b703          	ld	a4,696(a5)
    80003138:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000313a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000313e:	00014517          	auipc	a0,0x14
    80003142:	1aa50513          	addi	a0,a0,426 # 800172e8 <bcache>
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	b44080e7          	jalr	-1212(ra) # 80000c8a <release>
}
    8000314e:	60e2                	ld	ra,24(sp)
    80003150:	6442                	ld	s0,16(sp)
    80003152:	64a2                	ld	s1,8(sp)
    80003154:	6902                	ld	s2,0(sp)
    80003156:	6105                	addi	sp,sp,32
    80003158:	8082                	ret
    panic("brelse");
    8000315a:	00005517          	auipc	a0,0x5
    8000315e:	3de50513          	addi	a0,a0,990 # 80008538 <syscalls+0xf0>
    80003162:	ffffd097          	auipc	ra,0xffffd
    80003166:	3dc080e7          	jalr	988(ra) # 8000053e <panic>

000000008000316a <bpin>:

void
bpin(struct buf *b) {
    8000316a:	1101                	addi	sp,sp,-32
    8000316c:	ec06                	sd	ra,24(sp)
    8000316e:	e822                	sd	s0,16(sp)
    80003170:	e426                	sd	s1,8(sp)
    80003172:	1000                	addi	s0,sp,32
    80003174:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003176:	00014517          	auipc	a0,0x14
    8000317a:	17250513          	addi	a0,a0,370 # 800172e8 <bcache>
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	a58080e7          	jalr	-1448(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003186:	40bc                	lw	a5,64(s1)
    80003188:	2785                	addiw	a5,a5,1
    8000318a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000318c:	00014517          	auipc	a0,0x14
    80003190:	15c50513          	addi	a0,a0,348 # 800172e8 <bcache>
    80003194:	ffffe097          	auipc	ra,0xffffe
    80003198:	af6080e7          	jalr	-1290(ra) # 80000c8a <release>
}
    8000319c:	60e2                	ld	ra,24(sp)
    8000319e:	6442                	ld	s0,16(sp)
    800031a0:	64a2                	ld	s1,8(sp)
    800031a2:	6105                	addi	sp,sp,32
    800031a4:	8082                	ret

00000000800031a6 <bunpin>:

void
bunpin(struct buf *b) {
    800031a6:	1101                	addi	sp,sp,-32
    800031a8:	ec06                	sd	ra,24(sp)
    800031aa:	e822                	sd	s0,16(sp)
    800031ac:	e426                	sd	s1,8(sp)
    800031ae:	1000                	addi	s0,sp,32
    800031b0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031b2:	00014517          	auipc	a0,0x14
    800031b6:	13650513          	addi	a0,a0,310 # 800172e8 <bcache>
    800031ba:	ffffe097          	auipc	ra,0xffffe
    800031be:	a1c080e7          	jalr	-1508(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031c2:	40bc                	lw	a5,64(s1)
    800031c4:	37fd                	addiw	a5,a5,-1
    800031c6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031c8:	00014517          	auipc	a0,0x14
    800031cc:	12050513          	addi	a0,a0,288 # 800172e8 <bcache>
    800031d0:	ffffe097          	auipc	ra,0xffffe
    800031d4:	aba080e7          	jalr	-1350(ra) # 80000c8a <release>
}
    800031d8:	60e2                	ld	ra,24(sp)
    800031da:	6442                	ld	s0,16(sp)
    800031dc:	64a2                	ld	s1,8(sp)
    800031de:	6105                	addi	sp,sp,32
    800031e0:	8082                	ret

00000000800031e2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031e2:	1101                	addi	sp,sp,-32
    800031e4:	ec06                	sd	ra,24(sp)
    800031e6:	e822                	sd	s0,16(sp)
    800031e8:	e426                	sd	s1,8(sp)
    800031ea:	e04a                	sd	s2,0(sp)
    800031ec:	1000                	addi	s0,sp,32
    800031ee:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031f0:	00d5d59b          	srliw	a1,a1,0xd
    800031f4:	0001c797          	auipc	a5,0x1c
    800031f8:	7d07a783          	lw	a5,2000(a5) # 8001f9c4 <sb+0x1c>
    800031fc:	9dbd                	addw	a1,a1,a5
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	d9e080e7          	jalr	-610(ra) # 80002f9c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003206:	0074f713          	andi	a4,s1,7
    8000320a:	4785                	li	a5,1
    8000320c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003210:	14ce                	slli	s1,s1,0x33
    80003212:	90d9                	srli	s1,s1,0x36
    80003214:	00950733          	add	a4,a0,s1
    80003218:	05874703          	lbu	a4,88(a4)
    8000321c:	00e7f6b3          	and	a3,a5,a4
    80003220:	c69d                	beqz	a3,8000324e <bfree+0x6c>
    80003222:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003224:	94aa                	add	s1,s1,a0
    80003226:	fff7c793          	not	a5,a5
    8000322a:	8ff9                	and	a5,a5,a4
    8000322c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003230:	00001097          	auipc	ra,0x1
    80003234:	120080e7          	jalr	288(ra) # 80004350 <log_write>
  brelse(bp);
    80003238:	854a                	mv	a0,s2
    8000323a:	00000097          	auipc	ra,0x0
    8000323e:	e92080e7          	jalr	-366(ra) # 800030cc <brelse>
}
    80003242:	60e2                	ld	ra,24(sp)
    80003244:	6442                	ld	s0,16(sp)
    80003246:	64a2                	ld	s1,8(sp)
    80003248:	6902                	ld	s2,0(sp)
    8000324a:	6105                	addi	sp,sp,32
    8000324c:	8082                	ret
    panic("freeing free block");
    8000324e:	00005517          	auipc	a0,0x5
    80003252:	2f250513          	addi	a0,a0,754 # 80008540 <syscalls+0xf8>
    80003256:	ffffd097          	auipc	ra,0xffffd
    8000325a:	2e8080e7          	jalr	744(ra) # 8000053e <panic>

000000008000325e <balloc>:
{
    8000325e:	711d                	addi	sp,sp,-96
    80003260:	ec86                	sd	ra,88(sp)
    80003262:	e8a2                	sd	s0,80(sp)
    80003264:	e4a6                	sd	s1,72(sp)
    80003266:	e0ca                	sd	s2,64(sp)
    80003268:	fc4e                	sd	s3,56(sp)
    8000326a:	f852                	sd	s4,48(sp)
    8000326c:	f456                	sd	s5,40(sp)
    8000326e:	f05a                	sd	s6,32(sp)
    80003270:	ec5e                	sd	s7,24(sp)
    80003272:	e862                	sd	s8,16(sp)
    80003274:	e466                	sd	s9,8(sp)
    80003276:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003278:	0001c797          	auipc	a5,0x1c
    8000327c:	7347a783          	lw	a5,1844(a5) # 8001f9ac <sb+0x4>
    80003280:	10078163          	beqz	a5,80003382 <balloc+0x124>
    80003284:	8baa                	mv	s7,a0
    80003286:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003288:	0001cb17          	auipc	s6,0x1c
    8000328c:	720b0b13          	addi	s6,s6,1824 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003290:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003292:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003294:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003296:	6c89                	lui	s9,0x2
    80003298:	a061                	j	80003320 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000329a:	974a                	add	a4,a4,s2
    8000329c:	8fd5                	or	a5,a5,a3
    8000329e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032a2:	854a                	mv	a0,s2
    800032a4:	00001097          	auipc	ra,0x1
    800032a8:	0ac080e7          	jalr	172(ra) # 80004350 <log_write>
        brelse(bp);
    800032ac:	854a                	mv	a0,s2
    800032ae:	00000097          	auipc	ra,0x0
    800032b2:	e1e080e7          	jalr	-482(ra) # 800030cc <brelse>
  bp = bread(dev, bno);
    800032b6:	85a6                	mv	a1,s1
    800032b8:	855e                	mv	a0,s7
    800032ba:	00000097          	auipc	ra,0x0
    800032be:	ce2080e7          	jalr	-798(ra) # 80002f9c <bread>
    800032c2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032c4:	40000613          	li	a2,1024
    800032c8:	4581                	li	a1,0
    800032ca:	05850513          	addi	a0,a0,88
    800032ce:	ffffe097          	auipc	ra,0xffffe
    800032d2:	a04080e7          	jalr	-1532(ra) # 80000cd2 <memset>
  log_write(bp);
    800032d6:	854a                	mv	a0,s2
    800032d8:	00001097          	auipc	ra,0x1
    800032dc:	078080e7          	jalr	120(ra) # 80004350 <log_write>
  brelse(bp);
    800032e0:	854a                	mv	a0,s2
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	dea080e7          	jalr	-534(ra) # 800030cc <brelse>
}
    800032ea:	8526                	mv	a0,s1
    800032ec:	60e6                	ld	ra,88(sp)
    800032ee:	6446                	ld	s0,80(sp)
    800032f0:	64a6                	ld	s1,72(sp)
    800032f2:	6906                	ld	s2,64(sp)
    800032f4:	79e2                	ld	s3,56(sp)
    800032f6:	7a42                	ld	s4,48(sp)
    800032f8:	7aa2                	ld	s5,40(sp)
    800032fa:	7b02                	ld	s6,32(sp)
    800032fc:	6be2                	ld	s7,24(sp)
    800032fe:	6c42                	ld	s8,16(sp)
    80003300:	6ca2                	ld	s9,8(sp)
    80003302:	6125                	addi	sp,sp,96
    80003304:	8082                	ret
    brelse(bp);
    80003306:	854a                	mv	a0,s2
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	dc4080e7          	jalr	-572(ra) # 800030cc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003310:	015c87bb          	addw	a5,s9,s5
    80003314:	00078a9b          	sext.w	s5,a5
    80003318:	004b2703          	lw	a4,4(s6)
    8000331c:	06eaf363          	bgeu	s5,a4,80003382 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003320:	41fad79b          	sraiw	a5,s5,0x1f
    80003324:	0137d79b          	srliw	a5,a5,0x13
    80003328:	015787bb          	addw	a5,a5,s5
    8000332c:	40d7d79b          	sraiw	a5,a5,0xd
    80003330:	01cb2583          	lw	a1,28(s6)
    80003334:	9dbd                	addw	a1,a1,a5
    80003336:	855e                	mv	a0,s7
    80003338:	00000097          	auipc	ra,0x0
    8000333c:	c64080e7          	jalr	-924(ra) # 80002f9c <bread>
    80003340:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003342:	004b2503          	lw	a0,4(s6)
    80003346:	000a849b          	sext.w	s1,s5
    8000334a:	8662                	mv	a2,s8
    8000334c:	faa4fde3          	bgeu	s1,a0,80003306 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003350:	41f6579b          	sraiw	a5,a2,0x1f
    80003354:	01d7d69b          	srliw	a3,a5,0x1d
    80003358:	00c6873b          	addw	a4,a3,a2
    8000335c:	00777793          	andi	a5,a4,7
    80003360:	9f95                	subw	a5,a5,a3
    80003362:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003366:	4037571b          	sraiw	a4,a4,0x3
    8000336a:	00e906b3          	add	a3,s2,a4
    8000336e:	0586c683          	lbu	a3,88(a3)
    80003372:	00d7f5b3          	and	a1,a5,a3
    80003376:	d195                	beqz	a1,8000329a <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003378:	2605                	addiw	a2,a2,1
    8000337a:	2485                	addiw	s1,s1,1
    8000337c:	fd4618e3          	bne	a2,s4,8000334c <balloc+0xee>
    80003380:	b759                	j	80003306 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003382:	00005517          	auipc	a0,0x5
    80003386:	1d650513          	addi	a0,a0,470 # 80008558 <syscalls+0x110>
    8000338a:	ffffd097          	auipc	ra,0xffffd
    8000338e:	1fe080e7          	jalr	510(ra) # 80000588 <printf>
  return 0;
    80003392:	4481                	li	s1,0
    80003394:	bf99                	j	800032ea <balloc+0x8c>

0000000080003396 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003396:	7179                	addi	sp,sp,-48
    80003398:	f406                	sd	ra,40(sp)
    8000339a:	f022                	sd	s0,32(sp)
    8000339c:	ec26                	sd	s1,24(sp)
    8000339e:	e84a                	sd	s2,16(sp)
    800033a0:	e44e                	sd	s3,8(sp)
    800033a2:	e052                	sd	s4,0(sp)
    800033a4:	1800                	addi	s0,sp,48
    800033a6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033a8:	47ad                	li	a5,11
    800033aa:	02b7e763          	bltu	a5,a1,800033d8 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033ae:	02059493          	slli	s1,a1,0x20
    800033b2:	9081                	srli	s1,s1,0x20
    800033b4:	048a                	slli	s1,s1,0x2
    800033b6:	94aa                	add	s1,s1,a0
    800033b8:	0504a903          	lw	s2,80(s1)
    800033bc:	06091e63          	bnez	s2,80003438 <bmap+0xa2>
      addr = balloc(ip->dev);
    800033c0:	4108                	lw	a0,0(a0)
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	e9c080e7          	jalr	-356(ra) # 8000325e <balloc>
    800033ca:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033ce:	06090563          	beqz	s2,80003438 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800033d2:	0524a823          	sw	s2,80(s1)
    800033d6:	a08d                	j	80003438 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033d8:	ff45849b          	addiw	s1,a1,-12
    800033dc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033e0:	0ff00793          	li	a5,255
    800033e4:	08e7e563          	bltu	a5,a4,8000346e <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033e8:	08052903          	lw	s2,128(a0)
    800033ec:	00091d63          	bnez	s2,80003406 <bmap+0x70>
      addr = balloc(ip->dev);
    800033f0:	4108                	lw	a0,0(a0)
    800033f2:	00000097          	auipc	ra,0x0
    800033f6:	e6c080e7          	jalr	-404(ra) # 8000325e <balloc>
    800033fa:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033fe:	02090d63          	beqz	s2,80003438 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003402:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003406:	85ca                	mv	a1,s2
    80003408:	0009a503          	lw	a0,0(s3)
    8000340c:	00000097          	auipc	ra,0x0
    80003410:	b90080e7          	jalr	-1136(ra) # 80002f9c <bread>
    80003414:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003416:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000341a:	02049593          	slli	a1,s1,0x20
    8000341e:	9181                	srli	a1,a1,0x20
    80003420:	058a                	slli	a1,a1,0x2
    80003422:	00b784b3          	add	s1,a5,a1
    80003426:	0004a903          	lw	s2,0(s1)
    8000342a:	02090063          	beqz	s2,8000344a <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000342e:	8552                	mv	a0,s4
    80003430:	00000097          	auipc	ra,0x0
    80003434:	c9c080e7          	jalr	-868(ra) # 800030cc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003438:	854a                	mv	a0,s2
    8000343a:	70a2                	ld	ra,40(sp)
    8000343c:	7402                	ld	s0,32(sp)
    8000343e:	64e2                	ld	s1,24(sp)
    80003440:	6942                	ld	s2,16(sp)
    80003442:	69a2                	ld	s3,8(sp)
    80003444:	6a02                	ld	s4,0(sp)
    80003446:	6145                	addi	sp,sp,48
    80003448:	8082                	ret
      addr = balloc(ip->dev);
    8000344a:	0009a503          	lw	a0,0(s3)
    8000344e:	00000097          	auipc	ra,0x0
    80003452:	e10080e7          	jalr	-496(ra) # 8000325e <balloc>
    80003456:	0005091b          	sext.w	s2,a0
      if(addr){
    8000345a:	fc090ae3          	beqz	s2,8000342e <bmap+0x98>
        a[bn] = addr;
    8000345e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003462:	8552                	mv	a0,s4
    80003464:	00001097          	auipc	ra,0x1
    80003468:	eec080e7          	jalr	-276(ra) # 80004350 <log_write>
    8000346c:	b7c9                	j	8000342e <bmap+0x98>
  panic("bmap: out of range");
    8000346e:	00005517          	auipc	a0,0x5
    80003472:	10250513          	addi	a0,a0,258 # 80008570 <syscalls+0x128>
    80003476:	ffffd097          	auipc	ra,0xffffd
    8000347a:	0c8080e7          	jalr	200(ra) # 8000053e <panic>

000000008000347e <iget>:
{
    8000347e:	7179                	addi	sp,sp,-48
    80003480:	f406                	sd	ra,40(sp)
    80003482:	f022                	sd	s0,32(sp)
    80003484:	ec26                	sd	s1,24(sp)
    80003486:	e84a                	sd	s2,16(sp)
    80003488:	e44e                	sd	s3,8(sp)
    8000348a:	e052                	sd	s4,0(sp)
    8000348c:	1800                	addi	s0,sp,48
    8000348e:	89aa                	mv	s3,a0
    80003490:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003492:	0001c517          	auipc	a0,0x1c
    80003496:	53650513          	addi	a0,a0,1334 # 8001f9c8 <itable>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	73c080e7          	jalr	1852(ra) # 80000bd6 <acquire>
  empty = 0;
    800034a2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034a4:	0001c497          	auipc	s1,0x1c
    800034a8:	53c48493          	addi	s1,s1,1340 # 8001f9e0 <itable+0x18>
    800034ac:	0001e697          	auipc	a3,0x1e
    800034b0:	fc468693          	addi	a3,a3,-60 # 80021470 <log>
    800034b4:	a039                	j	800034c2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034b6:	02090b63          	beqz	s2,800034ec <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034ba:	08848493          	addi	s1,s1,136
    800034be:	02d48a63          	beq	s1,a3,800034f2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034c2:	449c                	lw	a5,8(s1)
    800034c4:	fef059e3          	blez	a5,800034b6 <iget+0x38>
    800034c8:	4098                	lw	a4,0(s1)
    800034ca:	ff3716e3          	bne	a4,s3,800034b6 <iget+0x38>
    800034ce:	40d8                	lw	a4,4(s1)
    800034d0:	ff4713e3          	bne	a4,s4,800034b6 <iget+0x38>
      ip->ref++;
    800034d4:	2785                	addiw	a5,a5,1
    800034d6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034d8:	0001c517          	auipc	a0,0x1c
    800034dc:	4f050513          	addi	a0,a0,1264 # 8001f9c8 <itable>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	7aa080e7          	jalr	1962(ra) # 80000c8a <release>
      return ip;
    800034e8:	8926                	mv	s2,s1
    800034ea:	a03d                	j	80003518 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ec:	f7f9                	bnez	a5,800034ba <iget+0x3c>
    800034ee:	8926                	mv	s2,s1
    800034f0:	b7e9                	j	800034ba <iget+0x3c>
  if(empty == 0)
    800034f2:	02090c63          	beqz	s2,8000352a <iget+0xac>
  ip->dev = dev;
    800034f6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034fa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034fe:	4785                	li	a5,1
    80003500:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003504:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003508:	0001c517          	auipc	a0,0x1c
    8000350c:	4c050513          	addi	a0,a0,1216 # 8001f9c8 <itable>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	77a080e7          	jalr	1914(ra) # 80000c8a <release>
}
    80003518:	854a                	mv	a0,s2
    8000351a:	70a2                	ld	ra,40(sp)
    8000351c:	7402                	ld	s0,32(sp)
    8000351e:	64e2                	ld	s1,24(sp)
    80003520:	6942                	ld	s2,16(sp)
    80003522:	69a2                	ld	s3,8(sp)
    80003524:	6a02                	ld	s4,0(sp)
    80003526:	6145                	addi	sp,sp,48
    80003528:	8082                	ret
    panic("iget: no inodes");
    8000352a:	00005517          	auipc	a0,0x5
    8000352e:	05e50513          	addi	a0,a0,94 # 80008588 <syscalls+0x140>
    80003532:	ffffd097          	auipc	ra,0xffffd
    80003536:	00c080e7          	jalr	12(ra) # 8000053e <panic>

000000008000353a <fsinit>:
fsinit(int dev) {
    8000353a:	7179                	addi	sp,sp,-48
    8000353c:	f406                	sd	ra,40(sp)
    8000353e:	f022                	sd	s0,32(sp)
    80003540:	ec26                	sd	s1,24(sp)
    80003542:	e84a                	sd	s2,16(sp)
    80003544:	e44e                	sd	s3,8(sp)
    80003546:	1800                	addi	s0,sp,48
    80003548:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000354a:	4585                	li	a1,1
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	a50080e7          	jalr	-1456(ra) # 80002f9c <bread>
    80003554:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003556:	0001c997          	auipc	s3,0x1c
    8000355a:	45298993          	addi	s3,s3,1106 # 8001f9a8 <sb>
    8000355e:	02000613          	li	a2,32
    80003562:	05850593          	addi	a1,a0,88
    80003566:	854e                	mv	a0,s3
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	7c6080e7          	jalr	1990(ra) # 80000d2e <memmove>
  brelse(bp);
    80003570:	8526                	mv	a0,s1
    80003572:	00000097          	auipc	ra,0x0
    80003576:	b5a080e7          	jalr	-1190(ra) # 800030cc <brelse>
  if(sb.magic != FSMAGIC)
    8000357a:	0009a703          	lw	a4,0(s3)
    8000357e:	102037b7          	lui	a5,0x10203
    80003582:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003586:	02f71263          	bne	a4,a5,800035aa <fsinit+0x70>
  initlog(dev, &sb);
    8000358a:	0001c597          	auipc	a1,0x1c
    8000358e:	41e58593          	addi	a1,a1,1054 # 8001f9a8 <sb>
    80003592:	854a                	mv	a0,s2
    80003594:	00001097          	auipc	ra,0x1
    80003598:	b40080e7          	jalr	-1216(ra) # 800040d4 <initlog>
}
    8000359c:	70a2                	ld	ra,40(sp)
    8000359e:	7402                	ld	s0,32(sp)
    800035a0:	64e2                	ld	s1,24(sp)
    800035a2:	6942                	ld	s2,16(sp)
    800035a4:	69a2                	ld	s3,8(sp)
    800035a6:	6145                	addi	sp,sp,48
    800035a8:	8082                	ret
    panic("invalid file system");
    800035aa:	00005517          	auipc	a0,0x5
    800035ae:	fee50513          	addi	a0,a0,-18 # 80008598 <syscalls+0x150>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	f8c080e7          	jalr	-116(ra) # 8000053e <panic>

00000000800035ba <iinit>:
{
    800035ba:	7179                	addi	sp,sp,-48
    800035bc:	f406                	sd	ra,40(sp)
    800035be:	f022                	sd	s0,32(sp)
    800035c0:	ec26                	sd	s1,24(sp)
    800035c2:	e84a                	sd	s2,16(sp)
    800035c4:	e44e                	sd	s3,8(sp)
    800035c6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035c8:	00005597          	auipc	a1,0x5
    800035cc:	fe858593          	addi	a1,a1,-24 # 800085b0 <syscalls+0x168>
    800035d0:	0001c517          	auipc	a0,0x1c
    800035d4:	3f850513          	addi	a0,a0,1016 # 8001f9c8 <itable>
    800035d8:	ffffd097          	auipc	ra,0xffffd
    800035dc:	56e080e7          	jalr	1390(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035e0:	0001c497          	auipc	s1,0x1c
    800035e4:	41048493          	addi	s1,s1,1040 # 8001f9f0 <itable+0x28>
    800035e8:	0001e997          	auipc	s3,0x1e
    800035ec:	e9898993          	addi	s3,s3,-360 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035f0:	00005917          	auipc	s2,0x5
    800035f4:	fc890913          	addi	s2,s2,-56 # 800085b8 <syscalls+0x170>
    800035f8:	85ca                	mv	a1,s2
    800035fa:	8526                	mv	a0,s1
    800035fc:	00001097          	auipc	ra,0x1
    80003600:	e3a080e7          	jalr	-454(ra) # 80004436 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003604:	08848493          	addi	s1,s1,136
    80003608:	ff3498e3          	bne	s1,s3,800035f8 <iinit+0x3e>
}
    8000360c:	70a2                	ld	ra,40(sp)
    8000360e:	7402                	ld	s0,32(sp)
    80003610:	64e2                	ld	s1,24(sp)
    80003612:	6942                	ld	s2,16(sp)
    80003614:	69a2                	ld	s3,8(sp)
    80003616:	6145                	addi	sp,sp,48
    80003618:	8082                	ret

000000008000361a <ialloc>:
{
    8000361a:	715d                	addi	sp,sp,-80
    8000361c:	e486                	sd	ra,72(sp)
    8000361e:	e0a2                	sd	s0,64(sp)
    80003620:	fc26                	sd	s1,56(sp)
    80003622:	f84a                	sd	s2,48(sp)
    80003624:	f44e                	sd	s3,40(sp)
    80003626:	f052                	sd	s4,32(sp)
    80003628:	ec56                	sd	s5,24(sp)
    8000362a:	e85a                	sd	s6,16(sp)
    8000362c:	e45e                	sd	s7,8(sp)
    8000362e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003630:	0001c717          	auipc	a4,0x1c
    80003634:	38472703          	lw	a4,900(a4) # 8001f9b4 <sb+0xc>
    80003638:	4785                	li	a5,1
    8000363a:	04e7fa63          	bgeu	a5,a4,8000368e <ialloc+0x74>
    8000363e:	8aaa                	mv	s5,a0
    80003640:	8bae                	mv	s7,a1
    80003642:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003644:	0001ca17          	auipc	s4,0x1c
    80003648:	364a0a13          	addi	s4,s4,868 # 8001f9a8 <sb>
    8000364c:	00048b1b          	sext.w	s6,s1
    80003650:	0044d793          	srli	a5,s1,0x4
    80003654:	018a2583          	lw	a1,24(s4)
    80003658:	9dbd                	addw	a1,a1,a5
    8000365a:	8556                	mv	a0,s5
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	940080e7          	jalr	-1728(ra) # 80002f9c <bread>
    80003664:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003666:	05850993          	addi	s3,a0,88
    8000366a:	00f4f793          	andi	a5,s1,15
    8000366e:	079a                	slli	a5,a5,0x6
    80003670:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003672:	00099783          	lh	a5,0(s3)
    80003676:	c3a1                	beqz	a5,800036b6 <ialloc+0x9c>
    brelse(bp);
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	a54080e7          	jalr	-1452(ra) # 800030cc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003680:	0485                	addi	s1,s1,1
    80003682:	00ca2703          	lw	a4,12(s4)
    80003686:	0004879b          	sext.w	a5,s1
    8000368a:	fce7e1e3          	bltu	a5,a4,8000364c <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000368e:	00005517          	auipc	a0,0x5
    80003692:	f3250513          	addi	a0,a0,-206 # 800085c0 <syscalls+0x178>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	ef2080e7          	jalr	-270(ra) # 80000588 <printf>
  return 0;
    8000369e:	4501                	li	a0,0
}
    800036a0:	60a6                	ld	ra,72(sp)
    800036a2:	6406                	ld	s0,64(sp)
    800036a4:	74e2                	ld	s1,56(sp)
    800036a6:	7942                	ld	s2,48(sp)
    800036a8:	79a2                	ld	s3,40(sp)
    800036aa:	7a02                	ld	s4,32(sp)
    800036ac:	6ae2                	ld	s5,24(sp)
    800036ae:	6b42                	ld	s6,16(sp)
    800036b0:	6ba2                	ld	s7,8(sp)
    800036b2:	6161                	addi	sp,sp,80
    800036b4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036b6:	04000613          	li	a2,64
    800036ba:	4581                	li	a1,0
    800036bc:	854e                	mv	a0,s3
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	614080e7          	jalr	1556(ra) # 80000cd2 <memset>
      dip->type = type;
    800036c6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036ca:	854a                	mv	a0,s2
    800036cc:	00001097          	auipc	ra,0x1
    800036d0:	c84080e7          	jalr	-892(ra) # 80004350 <log_write>
      brelse(bp);
    800036d4:	854a                	mv	a0,s2
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	9f6080e7          	jalr	-1546(ra) # 800030cc <brelse>
      return iget(dev, inum);
    800036de:	85da                	mv	a1,s6
    800036e0:	8556                	mv	a0,s5
    800036e2:	00000097          	auipc	ra,0x0
    800036e6:	d9c080e7          	jalr	-612(ra) # 8000347e <iget>
    800036ea:	bf5d                	j	800036a0 <ialloc+0x86>

00000000800036ec <iupdate>:
{
    800036ec:	1101                	addi	sp,sp,-32
    800036ee:	ec06                	sd	ra,24(sp)
    800036f0:	e822                	sd	s0,16(sp)
    800036f2:	e426                	sd	s1,8(sp)
    800036f4:	e04a                	sd	s2,0(sp)
    800036f6:	1000                	addi	s0,sp,32
    800036f8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036fa:	415c                	lw	a5,4(a0)
    800036fc:	0047d79b          	srliw	a5,a5,0x4
    80003700:	0001c597          	auipc	a1,0x1c
    80003704:	2c05a583          	lw	a1,704(a1) # 8001f9c0 <sb+0x18>
    80003708:	9dbd                	addw	a1,a1,a5
    8000370a:	4108                	lw	a0,0(a0)
    8000370c:	00000097          	auipc	ra,0x0
    80003710:	890080e7          	jalr	-1904(ra) # 80002f9c <bread>
    80003714:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003716:	05850793          	addi	a5,a0,88
    8000371a:	40c8                	lw	a0,4(s1)
    8000371c:	893d                	andi	a0,a0,15
    8000371e:	051a                	slli	a0,a0,0x6
    80003720:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003722:	04449703          	lh	a4,68(s1)
    80003726:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000372a:	04649703          	lh	a4,70(s1)
    8000372e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003732:	04849703          	lh	a4,72(s1)
    80003736:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000373a:	04a49703          	lh	a4,74(s1)
    8000373e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003742:	44f8                	lw	a4,76(s1)
    80003744:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003746:	03400613          	li	a2,52
    8000374a:	05048593          	addi	a1,s1,80
    8000374e:	0531                	addi	a0,a0,12
    80003750:	ffffd097          	auipc	ra,0xffffd
    80003754:	5de080e7          	jalr	1502(ra) # 80000d2e <memmove>
  log_write(bp);
    80003758:	854a                	mv	a0,s2
    8000375a:	00001097          	auipc	ra,0x1
    8000375e:	bf6080e7          	jalr	-1034(ra) # 80004350 <log_write>
  brelse(bp);
    80003762:	854a                	mv	a0,s2
    80003764:	00000097          	auipc	ra,0x0
    80003768:	968080e7          	jalr	-1688(ra) # 800030cc <brelse>
}
    8000376c:	60e2                	ld	ra,24(sp)
    8000376e:	6442                	ld	s0,16(sp)
    80003770:	64a2                	ld	s1,8(sp)
    80003772:	6902                	ld	s2,0(sp)
    80003774:	6105                	addi	sp,sp,32
    80003776:	8082                	ret

0000000080003778 <idup>:
{
    80003778:	1101                	addi	sp,sp,-32
    8000377a:	ec06                	sd	ra,24(sp)
    8000377c:	e822                	sd	s0,16(sp)
    8000377e:	e426                	sd	s1,8(sp)
    80003780:	1000                	addi	s0,sp,32
    80003782:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003784:	0001c517          	auipc	a0,0x1c
    80003788:	24450513          	addi	a0,a0,580 # 8001f9c8 <itable>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	44a080e7          	jalr	1098(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003794:	449c                	lw	a5,8(s1)
    80003796:	2785                	addiw	a5,a5,1
    80003798:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000379a:	0001c517          	auipc	a0,0x1c
    8000379e:	22e50513          	addi	a0,a0,558 # 8001f9c8 <itable>
    800037a2:	ffffd097          	auipc	ra,0xffffd
    800037a6:	4e8080e7          	jalr	1256(ra) # 80000c8a <release>
}
    800037aa:	8526                	mv	a0,s1
    800037ac:	60e2                	ld	ra,24(sp)
    800037ae:	6442                	ld	s0,16(sp)
    800037b0:	64a2                	ld	s1,8(sp)
    800037b2:	6105                	addi	sp,sp,32
    800037b4:	8082                	ret

00000000800037b6 <ilock>:
{
    800037b6:	1101                	addi	sp,sp,-32
    800037b8:	ec06                	sd	ra,24(sp)
    800037ba:	e822                	sd	s0,16(sp)
    800037bc:	e426                	sd	s1,8(sp)
    800037be:	e04a                	sd	s2,0(sp)
    800037c0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037c2:	c115                	beqz	a0,800037e6 <ilock+0x30>
    800037c4:	84aa                	mv	s1,a0
    800037c6:	451c                	lw	a5,8(a0)
    800037c8:	00f05f63          	blez	a5,800037e6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037cc:	0541                	addi	a0,a0,16
    800037ce:	00001097          	auipc	ra,0x1
    800037d2:	ca2080e7          	jalr	-862(ra) # 80004470 <acquiresleep>
  if(ip->valid == 0){
    800037d6:	40bc                	lw	a5,64(s1)
    800037d8:	cf99                	beqz	a5,800037f6 <ilock+0x40>
}
    800037da:	60e2                	ld	ra,24(sp)
    800037dc:	6442                	ld	s0,16(sp)
    800037de:	64a2                	ld	s1,8(sp)
    800037e0:	6902                	ld	s2,0(sp)
    800037e2:	6105                	addi	sp,sp,32
    800037e4:	8082                	ret
    panic("ilock");
    800037e6:	00005517          	auipc	a0,0x5
    800037ea:	df250513          	addi	a0,a0,-526 # 800085d8 <syscalls+0x190>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	d50080e7          	jalr	-688(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037f6:	40dc                	lw	a5,4(s1)
    800037f8:	0047d79b          	srliw	a5,a5,0x4
    800037fc:	0001c597          	auipc	a1,0x1c
    80003800:	1c45a583          	lw	a1,452(a1) # 8001f9c0 <sb+0x18>
    80003804:	9dbd                	addw	a1,a1,a5
    80003806:	4088                	lw	a0,0(s1)
    80003808:	fffff097          	auipc	ra,0xfffff
    8000380c:	794080e7          	jalr	1940(ra) # 80002f9c <bread>
    80003810:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003812:	05850593          	addi	a1,a0,88
    80003816:	40dc                	lw	a5,4(s1)
    80003818:	8bbd                	andi	a5,a5,15
    8000381a:	079a                	slli	a5,a5,0x6
    8000381c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000381e:	00059783          	lh	a5,0(a1)
    80003822:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003826:	00259783          	lh	a5,2(a1)
    8000382a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000382e:	00459783          	lh	a5,4(a1)
    80003832:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003836:	00659783          	lh	a5,6(a1)
    8000383a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000383e:	459c                	lw	a5,8(a1)
    80003840:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003842:	03400613          	li	a2,52
    80003846:	05b1                	addi	a1,a1,12
    80003848:	05048513          	addi	a0,s1,80
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	4e2080e7          	jalr	1250(ra) # 80000d2e <memmove>
    brelse(bp);
    80003854:	854a                	mv	a0,s2
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	876080e7          	jalr	-1930(ra) # 800030cc <brelse>
    ip->valid = 1;
    8000385e:	4785                	li	a5,1
    80003860:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003862:	04449783          	lh	a5,68(s1)
    80003866:	fbb5                	bnez	a5,800037da <ilock+0x24>
      panic("ilock: no type");
    80003868:	00005517          	auipc	a0,0x5
    8000386c:	d7850513          	addi	a0,a0,-648 # 800085e0 <syscalls+0x198>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	cce080e7          	jalr	-818(ra) # 8000053e <panic>

0000000080003878 <iunlock>:
{
    80003878:	1101                	addi	sp,sp,-32
    8000387a:	ec06                	sd	ra,24(sp)
    8000387c:	e822                	sd	s0,16(sp)
    8000387e:	e426                	sd	s1,8(sp)
    80003880:	e04a                	sd	s2,0(sp)
    80003882:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003884:	c905                	beqz	a0,800038b4 <iunlock+0x3c>
    80003886:	84aa                	mv	s1,a0
    80003888:	01050913          	addi	s2,a0,16
    8000388c:	854a                	mv	a0,s2
    8000388e:	00001097          	auipc	ra,0x1
    80003892:	c7c080e7          	jalr	-900(ra) # 8000450a <holdingsleep>
    80003896:	cd19                	beqz	a0,800038b4 <iunlock+0x3c>
    80003898:	449c                	lw	a5,8(s1)
    8000389a:	00f05d63          	blez	a5,800038b4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000389e:	854a                	mv	a0,s2
    800038a0:	00001097          	auipc	ra,0x1
    800038a4:	c26080e7          	jalr	-986(ra) # 800044c6 <releasesleep>
}
    800038a8:	60e2                	ld	ra,24(sp)
    800038aa:	6442                	ld	s0,16(sp)
    800038ac:	64a2                	ld	s1,8(sp)
    800038ae:	6902                	ld	s2,0(sp)
    800038b0:	6105                	addi	sp,sp,32
    800038b2:	8082                	ret
    panic("iunlock");
    800038b4:	00005517          	auipc	a0,0x5
    800038b8:	d3c50513          	addi	a0,a0,-708 # 800085f0 <syscalls+0x1a8>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	c82080e7          	jalr	-894(ra) # 8000053e <panic>

00000000800038c4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038c4:	7179                	addi	sp,sp,-48
    800038c6:	f406                	sd	ra,40(sp)
    800038c8:	f022                	sd	s0,32(sp)
    800038ca:	ec26                	sd	s1,24(sp)
    800038cc:	e84a                	sd	s2,16(sp)
    800038ce:	e44e                	sd	s3,8(sp)
    800038d0:	e052                	sd	s4,0(sp)
    800038d2:	1800                	addi	s0,sp,48
    800038d4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038d6:	05050493          	addi	s1,a0,80
    800038da:	08050913          	addi	s2,a0,128
    800038de:	a021                	j	800038e6 <itrunc+0x22>
    800038e0:	0491                	addi	s1,s1,4
    800038e2:	01248d63          	beq	s1,s2,800038fc <itrunc+0x38>
    if(ip->addrs[i]){
    800038e6:	408c                	lw	a1,0(s1)
    800038e8:	dde5                	beqz	a1,800038e0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038ea:	0009a503          	lw	a0,0(s3)
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	8f4080e7          	jalr	-1804(ra) # 800031e2 <bfree>
      ip->addrs[i] = 0;
    800038f6:	0004a023          	sw	zero,0(s1)
    800038fa:	b7dd                	j	800038e0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038fc:	0809a583          	lw	a1,128(s3)
    80003900:	e185                	bnez	a1,80003920 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003902:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003906:	854e                	mv	a0,s3
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	de4080e7          	jalr	-540(ra) # 800036ec <iupdate>
}
    80003910:	70a2                	ld	ra,40(sp)
    80003912:	7402                	ld	s0,32(sp)
    80003914:	64e2                	ld	s1,24(sp)
    80003916:	6942                	ld	s2,16(sp)
    80003918:	69a2                	ld	s3,8(sp)
    8000391a:	6a02                	ld	s4,0(sp)
    8000391c:	6145                	addi	sp,sp,48
    8000391e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003920:	0009a503          	lw	a0,0(s3)
    80003924:	fffff097          	auipc	ra,0xfffff
    80003928:	678080e7          	jalr	1656(ra) # 80002f9c <bread>
    8000392c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000392e:	05850493          	addi	s1,a0,88
    80003932:	45850913          	addi	s2,a0,1112
    80003936:	a021                	j	8000393e <itrunc+0x7a>
    80003938:	0491                	addi	s1,s1,4
    8000393a:	01248b63          	beq	s1,s2,80003950 <itrunc+0x8c>
      if(a[j])
    8000393e:	408c                	lw	a1,0(s1)
    80003940:	dde5                	beqz	a1,80003938 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003942:	0009a503          	lw	a0,0(s3)
    80003946:	00000097          	auipc	ra,0x0
    8000394a:	89c080e7          	jalr	-1892(ra) # 800031e2 <bfree>
    8000394e:	b7ed                	j	80003938 <itrunc+0x74>
    brelse(bp);
    80003950:	8552                	mv	a0,s4
    80003952:	fffff097          	auipc	ra,0xfffff
    80003956:	77a080e7          	jalr	1914(ra) # 800030cc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000395a:	0809a583          	lw	a1,128(s3)
    8000395e:	0009a503          	lw	a0,0(s3)
    80003962:	00000097          	auipc	ra,0x0
    80003966:	880080e7          	jalr	-1920(ra) # 800031e2 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000396a:	0809a023          	sw	zero,128(s3)
    8000396e:	bf51                	j	80003902 <itrunc+0x3e>

0000000080003970 <iput>:
{
    80003970:	1101                	addi	sp,sp,-32
    80003972:	ec06                	sd	ra,24(sp)
    80003974:	e822                	sd	s0,16(sp)
    80003976:	e426                	sd	s1,8(sp)
    80003978:	e04a                	sd	s2,0(sp)
    8000397a:	1000                	addi	s0,sp,32
    8000397c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000397e:	0001c517          	auipc	a0,0x1c
    80003982:	04a50513          	addi	a0,a0,74 # 8001f9c8 <itable>
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	250080e7          	jalr	592(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000398e:	4498                	lw	a4,8(s1)
    80003990:	4785                	li	a5,1
    80003992:	02f70363          	beq	a4,a5,800039b8 <iput+0x48>
  ip->ref--;
    80003996:	449c                	lw	a5,8(s1)
    80003998:	37fd                	addiw	a5,a5,-1
    8000399a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000399c:	0001c517          	auipc	a0,0x1c
    800039a0:	02c50513          	addi	a0,a0,44 # 8001f9c8 <itable>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	2e6080e7          	jalr	742(ra) # 80000c8a <release>
}
    800039ac:	60e2                	ld	ra,24(sp)
    800039ae:	6442                	ld	s0,16(sp)
    800039b0:	64a2                	ld	s1,8(sp)
    800039b2:	6902                	ld	s2,0(sp)
    800039b4:	6105                	addi	sp,sp,32
    800039b6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039b8:	40bc                	lw	a5,64(s1)
    800039ba:	dff1                	beqz	a5,80003996 <iput+0x26>
    800039bc:	04a49783          	lh	a5,74(s1)
    800039c0:	fbf9                	bnez	a5,80003996 <iput+0x26>
    acquiresleep(&ip->lock);
    800039c2:	01048913          	addi	s2,s1,16
    800039c6:	854a                	mv	a0,s2
    800039c8:	00001097          	auipc	ra,0x1
    800039cc:	aa8080e7          	jalr	-1368(ra) # 80004470 <acquiresleep>
    release(&itable.lock);
    800039d0:	0001c517          	auipc	a0,0x1c
    800039d4:	ff850513          	addi	a0,a0,-8 # 8001f9c8 <itable>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
    itrunc(ip);
    800039e0:	8526                	mv	a0,s1
    800039e2:	00000097          	auipc	ra,0x0
    800039e6:	ee2080e7          	jalr	-286(ra) # 800038c4 <itrunc>
    ip->type = 0;
    800039ea:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039ee:	8526                	mv	a0,s1
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	cfc080e7          	jalr	-772(ra) # 800036ec <iupdate>
    ip->valid = 0;
    800039f8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039fc:	854a                	mv	a0,s2
    800039fe:	00001097          	auipc	ra,0x1
    80003a02:	ac8080e7          	jalr	-1336(ra) # 800044c6 <releasesleep>
    acquire(&itable.lock);
    80003a06:	0001c517          	auipc	a0,0x1c
    80003a0a:	fc250513          	addi	a0,a0,-62 # 8001f9c8 <itable>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	1c8080e7          	jalr	456(ra) # 80000bd6 <acquire>
    80003a16:	b741                	j	80003996 <iput+0x26>

0000000080003a18 <iunlockput>:
{
    80003a18:	1101                	addi	sp,sp,-32
    80003a1a:	ec06                	sd	ra,24(sp)
    80003a1c:	e822                	sd	s0,16(sp)
    80003a1e:	e426                	sd	s1,8(sp)
    80003a20:	1000                	addi	s0,sp,32
    80003a22:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	e54080e7          	jalr	-428(ra) # 80003878 <iunlock>
  iput(ip);
    80003a2c:	8526                	mv	a0,s1
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	f42080e7          	jalr	-190(ra) # 80003970 <iput>
}
    80003a36:	60e2                	ld	ra,24(sp)
    80003a38:	6442                	ld	s0,16(sp)
    80003a3a:	64a2                	ld	s1,8(sp)
    80003a3c:	6105                	addi	sp,sp,32
    80003a3e:	8082                	ret

0000000080003a40 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a40:	1141                	addi	sp,sp,-16
    80003a42:	e422                	sd	s0,8(sp)
    80003a44:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a46:	411c                	lw	a5,0(a0)
    80003a48:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a4a:	415c                	lw	a5,4(a0)
    80003a4c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a4e:	04451783          	lh	a5,68(a0)
    80003a52:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a56:	04a51783          	lh	a5,74(a0)
    80003a5a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a5e:	04c56783          	lwu	a5,76(a0)
    80003a62:	e99c                	sd	a5,16(a1)
}
    80003a64:	6422                	ld	s0,8(sp)
    80003a66:	0141                	addi	sp,sp,16
    80003a68:	8082                	ret

0000000080003a6a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a6a:	457c                	lw	a5,76(a0)
    80003a6c:	0ed7e963          	bltu	a5,a3,80003b5e <readi+0xf4>
{
    80003a70:	7159                	addi	sp,sp,-112
    80003a72:	f486                	sd	ra,104(sp)
    80003a74:	f0a2                	sd	s0,96(sp)
    80003a76:	eca6                	sd	s1,88(sp)
    80003a78:	e8ca                	sd	s2,80(sp)
    80003a7a:	e4ce                	sd	s3,72(sp)
    80003a7c:	e0d2                	sd	s4,64(sp)
    80003a7e:	fc56                	sd	s5,56(sp)
    80003a80:	f85a                	sd	s6,48(sp)
    80003a82:	f45e                	sd	s7,40(sp)
    80003a84:	f062                	sd	s8,32(sp)
    80003a86:	ec66                	sd	s9,24(sp)
    80003a88:	e86a                	sd	s10,16(sp)
    80003a8a:	e46e                	sd	s11,8(sp)
    80003a8c:	1880                	addi	s0,sp,112
    80003a8e:	8b2a                	mv	s6,a0
    80003a90:	8bae                	mv	s7,a1
    80003a92:	8a32                	mv	s4,a2
    80003a94:	84b6                	mv	s1,a3
    80003a96:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a98:	9f35                	addw	a4,a4,a3
    return 0;
    80003a9a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a9c:	0ad76063          	bltu	a4,a3,80003b3c <readi+0xd2>
  if(off + n > ip->size)
    80003aa0:	00e7f463          	bgeu	a5,a4,80003aa8 <readi+0x3e>
    n = ip->size - off;
    80003aa4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa8:	0a0a8963          	beqz	s5,80003b5a <readi+0xf0>
    80003aac:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aae:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ab2:	5c7d                	li	s8,-1
    80003ab4:	a82d                	j	80003aee <readi+0x84>
    80003ab6:	020d1d93          	slli	s11,s10,0x20
    80003aba:	020ddd93          	srli	s11,s11,0x20
    80003abe:	05890793          	addi	a5,s2,88
    80003ac2:	86ee                	mv	a3,s11
    80003ac4:	963e                	add	a2,a2,a5
    80003ac6:	85d2                	mv	a1,s4
    80003ac8:	855e                	mv	a0,s7
    80003aca:	fffff097          	auipc	ra,0xfffff
    80003ace:	a30080e7          	jalr	-1488(ra) # 800024fa <either_copyout>
    80003ad2:	05850d63          	beq	a0,s8,80003b2c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ad6:	854a                	mv	a0,s2
    80003ad8:	fffff097          	auipc	ra,0xfffff
    80003adc:	5f4080e7          	jalr	1524(ra) # 800030cc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ae0:	013d09bb          	addw	s3,s10,s3
    80003ae4:	009d04bb          	addw	s1,s10,s1
    80003ae8:	9a6e                	add	s4,s4,s11
    80003aea:	0559f763          	bgeu	s3,s5,80003b38 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003aee:	00a4d59b          	srliw	a1,s1,0xa
    80003af2:	855a                	mv	a0,s6
    80003af4:	00000097          	auipc	ra,0x0
    80003af8:	8a2080e7          	jalr	-1886(ra) # 80003396 <bmap>
    80003afc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b00:	cd85                	beqz	a1,80003b38 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b02:	000b2503          	lw	a0,0(s6)
    80003b06:	fffff097          	auipc	ra,0xfffff
    80003b0a:	496080e7          	jalr	1174(ra) # 80002f9c <bread>
    80003b0e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b10:	3ff4f613          	andi	a2,s1,1023
    80003b14:	40cc87bb          	subw	a5,s9,a2
    80003b18:	413a873b          	subw	a4,s5,s3
    80003b1c:	8d3e                	mv	s10,a5
    80003b1e:	2781                	sext.w	a5,a5
    80003b20:	0007069b          	sext.w	a3,a4
    80003b24:	f8f6f9e3          	bgeu	a3,a5,80003ab6 <readi+0x4c>
    80003b28:	8d3a                	mv	s10,a4
    80003b2a:	b771                	j	80003ab6 <readi+0x4c>
      brelse(bp);
    80003b2c:	854a                	mv	a0,s2
    80003b2e:	fffff097          	auipc	ra,0xfffff
    80003b32:	59e080e7          	jalr	1438(ra) # 800030cc <brelse>
      tot = -1;
    80003b36:	59fd                	li	s3,-1
  }
  return tot;
    80003b38:	0009851b          	sext.w	a0,s3
}
    80003b3c:	70a6                	ld	ra,104(sp)
    80003b3e:	7406                	ld	s0,96(sp)
    80003b40:	64e6                	ld	s1,88(sp)
    80003b42:	6946                	ld	s2,80(sp)
    80003b44:	69a6                	ld	s3,72(sp)
    80003b46:	6a06                	ld	s4,64(sp)
    80003b48:	7ae2                	ld	s5,56(sp)
    80003b4a:	7b42                	ld	s6,48(sp)
    80003b4c:	7ba2                	ld	s7,40(sp)
    80003b4e:	7c02                	ld	s8,32(sp)
    80003b50:	6ce2                	ld	s9,24(sp)
    80003b52:	6d42                	ld	s10,16(sp)
    80003b54:	6da2                	ld	s11,8(sp)
    80003b56:	6165                	addi	sp,sp,112
    80003b58:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b5a:	89d6                	mv	s3,s5
    80003b5c:	bff1                	j	80003b38 <readi+0xce>
    return 0;
    80003b5e:	4501                	li	a0,0
}
    80003b60:	8082                	ret

0000000080003b62 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b62:	457c                	lw	a5,76(a0)
    80003b64:	10d7e863          	bltu	a5,a3,80003c74 <writei+0x112>
{
    80003b68:	7159                	addi	sp,sp,-112
    80003b6a:	f486                	sd	ra,104(sp)
    80003b6c:	f0a2                	sd	s0,96(sp)
    80003b6e:	eca6                	sd	s1,88(sp)
    80003b70:	e8ca                	sd	s2,80(sp)
    80003b72:	e4ce                	sd	s3,72(sp)
    80003b74:	e0d2                	sd	s4,64(sp)
    80003b76:	fc56                	sd	s5,56(sp)
    80003b78:	f85a                	sd	s6,48(sp)
    80003b7a:	f45e                	sd	s7,40(sp)
    80003b7c:	f062                	sd	s8,32(sp)
    80003b7e:	ec66                	sd	s9,24(sp)
    80003b80:	e86a                	sd	s10,16(sp)
    80003b82:	e46e                	sd	s11,8(sp)
    80003b84:	1880                	addi	s0,sp,112
    80003b86:	8aaa                	mv	s5,a0
    80003b88:	8bae                	mv	s7,a1
    80003b8a:	8a32                	mv	s4,a2
    80003b8c:	8936                	mv	s2,a3
    80003b8e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b90:	00e687bb          	addw	a5,a3,a4
    80003b94:	0ed7e263          	bltu	a5,a3,80003c78 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b98:	00043737          	lui	a4,0x43
    80003b9c:	0ef76063          	bltu	a4,a5,80003c7c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba0:	0c0b0863          	beqz	s6,80003c70 <writei+0x10e>
    80003ba4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003baa:	5c7d                	li	s8,-1
    80003bac:	a091                	j	80003bf0 <writei+0x8e>
    80003bae:	020d1d93          	slli	s11,s10,0x20
    80003bb2:	020ddd93          	srli	s11,s11,0x20
    80003bb6:	05848793          	addi	a5,s1,88
    80003bba:	86ee                	mv	a3,s11
    80003bbc:	8652                	mv	a2,s4
    80003bbe:	85de                	mv	a1,s7
    80003bc0:	953e                	add	a0,a0,a5
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	98e080e7          	jalr	-1650(ra) # 80002550 <either_copyin>
    80003bca:	07850263          	beq	a0,s8,80003c2e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bce:	8526                	mv	a0,s1
    80003bd0:	00000097          	auipc	ra,0x0
    80003bd4:	780080e7          	jalr	1920(ra) # 80004350 <log_write>
    brelse(bp);
    80003bd8:	8526                	mv	a0,s1
    80003bda:	fffff097          	auipc	ra,0xfffff
    80003bde:	4f2080e7          	jalr	1266(ra) # 800030cc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003be2:	013d09bb          	addw	s3,s10,s3
    80003be6:	012d093b          	addw	s2,s10,s2
    80003bea:	9a6e                	add	s4,s4,s11
    80003bec:	0569f663          	bgeu	s3,s6,80003c38 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003bf0:	00a9559b          	srliw	a1,s2,0xa
    80003bf4:	8556                	mv	a0,s5
    80003bf6:	fffff097          	auipc	ra,0xfffff
    80003bfa:	7a0080e7          	jalr	1952(ra) # 80003396 <bmap>
    80003bfe:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c02:	c99d                	beqz	a1,80003c38 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c04:	000aa503          	lw	a0,0(s5)
    80003c08:	fffff097          	auipc	ra,0xfffff
    80003c0c:	394080e7          	jalr	916(ra) # 80002f9c <bread>
    80003c10:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c12:	3ff97513          	andi	a0,s2,1023
    80003c16:	40ac87bb          	subw	a5,s9,a0
    80003c1a:	413b073b          	subw	a4,s6,s3
    80003c1e:	8d3e                	mv	s10,a5
    80003c20:	2781                	sext.w	a5,a5
    80003c22:	0007069b          	sext.w	a3,a4
    80003c26:	f8f6f4e3          	bgeu	a3,a5,80003bae <writei+0x4c>
    80003c2a:	8d3a                	mv	s10,a4
    80003c2c:	b749                	j	80003bae <writei+0x4c>
      brelse(bp);
    80003c2e:	8526                	mv	a0,s1
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	49c080e7          	jalr	1180(ra) # 800030cc <brelse>
  }

  if(off > ip->size)
    80003c38:	04caa783          	lw	a5,76(s5)
    80003c3c:	0127f463          	bgeu	a5,s2,80003c44 <writei+0xe2>
    ip->size = off;
    80003c40:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c44:	8556                	mv	a0,s5
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	aa6080e7          	jalr	-1370(ra) # 800036ec <iupdate>

  return tot;
    80003c4e:	0009851b          	sext.w	a0,s3
}
    80003c52:	70a6                	ld	ra,104(sp)
    80003c54:	7406                	ld	s0,96(sp)
    80003c56:	64e6                	ld	s1,88(sp)
    80003c58:	6946                	ld	s2,80(sp)
    80003c5a:	69a6                	ld	s3,72(sp)
    80003c5c:	6a06                	ld	s4,64(sp)
    80003c5e:	7ae2                	ld	s5,56(sp)
    80003c60:	7b42                	ld	s6,48(sp)
    80003c62:	7ba2                	ld	s7,40(sp)
    80003c64:	7c02                	ld	s8,32(sp)
    80003c66:	6ce2                	ld	s9,24(sp)
    80003c68:	6d42                	ld	s10,16(sp)
    80003c6a:	6da2                	ld	s11,8(sp)
    80003c6c:	6165                	addi	sp,sp,112
    80003c6e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c70:	89da                	mv	s3,s6
    80003c72:	bfc9                	j	80003c44 <writei+0xe2>
    return -1;
    80003c74:	557d                	li	a0,-1
}
    80003c76:	8082                	ret
    return -1;
    80003c78:	557d                	li	a0,-1
    80003c7a:	bfe1                	j	80003c52 <writei+0xf0>
    return -1;
    80003c7c:	557d                	li	a0,-1
    80003c7e:	bfd1                	j	80003c52 <writei+0xf0>

0000000080003c80 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c80:	1141                	addi	sp,sp,-16
    80003c82:	e406                	sd	ra,8(sp)
    80003c84:	e022                	sd	s0,0(sp)
    80003c86:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c88:	4639                	li	a2,14
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	118080e7          	jalr	280(ra) # 80000da2 <strncmp>
}
    80003c92:	60a2                	ld	ra,8(sp)
    80003c94:	6402                	ld	s0,0(sp)
    80003c96:	0141                	addi	sp,sp,16
    80003c98:	8082                	ret

0000000080003c9a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c9a:	7139                	addi	sp,sp,-64
    80003c9c:	fc06                	sd	ra,56(sp)
    80003c9e:	f822                	sd	s0,48(sp)
    80003ca0:	f426                	sd	s1,40(sp)
    80003ca2:	f04a                	sd	s2,32(sp)
    80003ca4:	ec4e                	sd	s3,24(sp)
    80003ca6:	e852                	sd	s4,16(sp)
    80003ca8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003caa:	04451703          	lh	a4,68(a0)
    80003cae:	4785                	li	a5,1
    80003cb0:	00f71a63          	bne	a4,a5,80003cc4 <dirlookup+0x2a>
    80003cb4:	892a                	mv	s2,a0
    80003cb6:	89ae                	mv	s3,a1
    80003cb8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cba:	457c                	lw	a5,76(a0)
    80003cbc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cbe:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc0:	e79d                	bnez	a5,80003cee <dirlookup+0x54>
    80003cc2:	a8a5                	j	80003d3a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cc4:	00005517          	auipc	a0,0x5
    80003cc8:	93450513          	addi	a0,a0,-1740 # 800085f8 <syscalls+0x1b0>
    80003ccc:	ffffd097          	auipc	ra,0xffffd
    80003cd0:	872080e7          	jalr	-1934(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003cd4:	00005517          	auipc	a0,0x5
    80003cd8:	93c50513          	addi	a0,a0,-1732 # 80008610 <syscalls+0x1c8>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	862080e7          	jalr	-1950(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce4:	24c1                	addiw	s1,s1,16
    80003ce6:	04c92783          	lw	a5,76(s2)
    80003cea:	04f4f763          	bgeu	s1,a5,80003d38 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cee:	4741                	li	a4,16
    80003cf0:	86a6                	mv	a3,s1
    80003cf2:	fc040613          	addi	a2,s0,-64
    80003cf6:	4581                	li	a1,0
    80003cf8:	854a                	mv	a0,s2
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	d70080e7          	jalr	-656(ra) # 80003a6a <readi>
    80003d02:	47c1                	li	a5,16
    80003d04:	fcf518e3          	bne	a0,a5,80003cd4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d08:	fc045783          	lhu	a5,-64(s0)
    80003d0c:	dfe1                	beqz	a5,80003ce4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d0e:	fc240593          	addi	a1,s0,-62
    80003d12:	854e                	mv	a0,s3
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	f6c080e7          	jalr	-148(ra) # 80003c80 <namecmp>
    80003d1c:	f561                	bnez	a0,80003ce4 <dirlookup+0x4a>
      if(poff)
    80003d1e:	000a0463          	beqz	s4,80003d26 <dirlookup+0x8c>
        *poff = off;
    80003d22:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d26:	fc045583          	lhu	a1,-64(s0)
    80003d2a:	00092503          	lw	a0,0(s2)
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	750080e7          	jalr	1872(ra) # 8000347e <iget>
    80003d36:	a011                	j	80003d3a <dirlookup+0xa0>
  return 0;
    80003d38:	4501                	li	a0,0
}
    80003d3a:	70e2                	ld	ra,56(sp)
    80003d3c:	7442                	ld	s0,48(sp)
    80003d3e:	74a2                	ld	s1,40(sp)
    80003d40:	7902                	ld	s2,32(sp)
    80003d42:	69e2                	ld	s3,24(sp)
    80003d44:	6a42                	ld	s4,16(sp)
    80003d46:	6121                	addi	sp,sp,64
    80003d48:	8082                	ret

0000000080003d4a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d4a:	711d                	addi	sp,sp,-96
    80003d4c:	ec86                	sd	ra,88(sp)
    80003d4e:	e8a2                	sd	s0,80(sp)
    80003d50:	e4a6                	sd	s1,72(sp)
    80003d52:	e0ca                	sd	s2,64(sp)
    80003d54:	fc4e                	sd	s3,56(sp)
    80003d56:	f852                	sd	s4,48(sp)
    80003d58:	f456                	sd	s5,40(sp)
    80003d5a:	f05a                	sd	s6,32(sp)
    80003d5c:	ec5e                	sd	s7,24(sp)
    80003d5e:	e862                	sd	s8,16(sp)
    80003d60:	e466                	sd	s9,8(sp)
    80003d62:	1080                	addi	s0,sp,96
    80003d64:	84aa                	mv	s1,a0
    80003d66:	8aae                	mv	s5,a1
    80003d68:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d6a:	00054703          	lbu	a4,0(a0)
    80003d6e:	02f00793          	li	a5,47
    80003d72:	02f70363          	beq	a4,a5,80003d98 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d76:	ffffe097          	auipc	ra,0xffffe
    80003d7a:	c6e080e7          	jalr	-914(ra) # 800019e4 <myproc>
    80003d7e:	15053503          	ld	a0,336(a0)
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	9f6080e7          	jalr	-1546(ra) # 80003778 <idup>
    80003d8a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d8c:	02f00913          	li	s2,47
  len = path - s;
    80003d90:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d92:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d94:	4b85                	li	s7,1
    80003d96:	a865                	j	80003e4e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d98:	4585                	li	a1,1
    80003d9a:	4505                	li	a0,1
    80003d9c:	fffff097          	auipc	ra,0xfffff
    80003da0:	6e2080e7          	jalr	1762(ra) # 8000347e <iget>
    80003da4:	89aa                	mv	s3,a0
    80003da6:	b7dd                	j	80003d8c <namex+0x42>
      iunlockput(ip);
    80003da8:	854e                	mv	a0,s3
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	c6e080e7          	jalr	-914(ra) # 80003a18 <iunlockput>
      return 0;
    80003db2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003db4:	854e                	mv	a0,s3
    80003db6:	60e6                	ld	ra,88(sp)
    80003db8:	6446                	ld	s0,80(sp)
    80003dba:	64a6                	ld	s1,72(sp)
    80003dbc:	6906                	ld	s2,64(sp)
    80003dbe:	79e2                	ld	s3,56(sp)
    80003dc0:	7a42                	ld	s4,48(sp)
    80003dc2:	7aa2                	ld	s5,40(sp)
    80003dc4:	7b02                	ld	s6,32(sp)
    80003dc6:	6be2                	ld	s7,24(sp)
    80003dc8:	6c42                	ld	s8,16(sp)
    80003dca:	6ca2                	ld	s9,8(sp)
    80003dcc:	6125                	addi	sp,sp,96
    80003dce:	8082                	ret
      iunlock(ip);
    80003dd0:	854e                	mv	a0,s3
    80003dd2:	00000097          	auipc	ra,0x0
    80003dd6:	aa6080e7          	jalr	-1370(ra) # 80003878 <iunlock>
      return ip;
    80003dda:	bfe9                	j	80003db4 <namex+0x6a>
      iunlockput(ip);
    80003ddc:	854e                	mv	a0,s3
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	c3a080e7          	jalr	-966(ra) # 80003a18 <iunlockput>
      return 0;
    80003de6:	89e6                	mv	s3,s9
    80003de8:	b7f1                	j	80003db4 <namex+0x6a>
  len = path - s;
    80003dea:	40b48633          	sub	a2,s1,a1
    80003dee:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003df2:	099c5463          	bge	s8,s9,80003e7a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003df6:	4639                	li	a2,14
    80003df8:	8552                	mv	a0,s4
    80003dfa:	ffffd097          	auipc	ra,0xffffd
    80003dfe:	f34080e7          	jalr	-204(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003e02:	0004c783          	lbu	a5,0(s1)
    80003e06:	01279763          	bne	a5,s2,80003e14 <namex+0xca>
    path++;
    80003e0a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e0c:	0004c783          	lbu	a5,0(s1)
    80003e10:	ff278de3          	beq	a5,s2,80003e0a <namex+0xc0>
    ilock(ip);
    80003e14:	854e                	mv	a0,s3
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	9a0080e7          	jalr	-1632(ra) # 800037b6 <ilock>
    if(ip->type != T_DIR){
    80003e1e:	04499783          	lh	a5,68(s3)
    80003e22:	f97793e3          	bne	a5,s7,80003da8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e26:	000a8563          	beqz	s5,80003e30 <namex+0xe6>
    80003e2a:	0004c783          	lbu	a5,0(s1)
    80003e2e:	d3cd                	beqz	a5,80003dd0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e30:	865a                	mv	a2,s6
    80003e32:	85d2                	mv	a1,s4
    80003e34:	854e                	mv	a0,s3
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	e64080e7          	jalr	-412(ra) # 80003c9a <dirlookup>
    80003e3e:	8caa                	mv	s9,a0
    80003e40:	dd51                	beqz	a0,80003ddc <namex+0x92>
    iunlockput(ip);
    80003e42:	854e                	mv	a0,s3
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	bd4080e7          	jalr	-1068(ra) # 80003a18 <iunlockput>
    ip = next;
    80003e4c:	89e6                	mv	s3,s9
  while(*path == '/')
    80003e4e:	0004c783          	lbu	a5,0(s1)
    80003e52:	05279763          	bne	a5,s2,80003ea0 <namex+0x156>
    path++;
    80003e56:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e58:	0004c783          	lbu	a5,0(s1)
    80003e5c:	ff278de3          	beq	a5,s2,80003e56 <namex+0x10c>
  if(*path == 0)
    80003e60:	c79d                	beqz	a5,80003e8e <namex+0x144>
    path++;
    80003e62:	85a6                	mv	a1,s1
  len = path - s;
    80003e64:	8cda                	mv	s9,s6
    80003e66:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003e68:	01278963          	beq	a5,s2,80003e7a <namex+0x130>
    80003e6c:	dfbd                	beqz	a5,80003dea <namex+0xa0>
    path++;
    80003e6e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e70:	0004c783          	lbu	a5,0(s1)
    80003e74:	ff279ce3          	bne	a5,s2,80003e6c <namex+0x122>
    80003e78:	bf8d                	j	80003dea <namex+0xa0>
    memmove(name, s, len);
    80003e7a:	2601                	sext.w	a2,a2
    80003e7c:	8552                	mv	a0,s4
    80003e7e:	ffffd097          	auipc	ra,0xffffd
    80003e82:	eb0080e7          	jalr	-336(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003e86:	9cd2                	add	s9,s9,s4
    80003e88:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e8c:	bf9d                	j	80003e02 <namex+0xb8>
  if(nameiparent){
    80003e8e:	f20a83e3          	beqz	s5,80003db4 <namex+0x6a>
    iput(ip);
    80003e92:	854e                	mv	a0,s3
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	adc080e7          	jalr	-1316(ra) # 80003970 <iput>
    return 0;
    80003e9c:	4981                	li	s3,0
    80003e9e:	bf19                	j	80003db4 <namex+0x6a>
  if(*path == 0)
    80003ea0:	d7fd                	beqz	a5,80003e8e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ea2:	0004c783          	lbu	a5,0(s1)
    80003ea6:	85a6                	mv	a1,s1
    80003ea8:	b7d1                	j	80003e6c <namex+0x122>

0000000080003eaa <dirlink>:
{
    80003eaa:	7139                	addi	sp,sp,-64
    80003eac:	fc06                	sd	ra,56(sp)
    80003eae:	f822                	sd	s0,48(sp)
    80003eb0:	f426                	sd	s1,40(sp)
    80003eb2:	f04a                	sd	s2,32(sp)
    80003eb4:	ec4e                	sd	s3,24(sp)
    80003eb6:	e852                	sd	s4,16(sp)
    80003eb8:	0080                	addi	s0,sp,64
    80003eba:	892a                	mv	s2,a0
    80003ebc:	8a2e                	mv	s4,a1
    80003ebe:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ec0:	4601                	li	a2,0
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	dd8080e7          	jalr	-552(ra) # 80003c9a <dirlookup>
    80003eca:	e93d                	bnez	a0,80003f40 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ecc:	04c92483          	lw	s1,76(s2)
    80003ed0:	c49d                	beqz	s1,80003efe <dirlink+0x54>
    80003ed2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ed4:	4741                	li	a4,16
    80003ed6:	86a6                	mv	a3,s1
    80003ed8:	fc040613          	addi	a2,s0,-64
    80003edc:	4581                	li	a1,0
    80003ede:	854a                	mv	a0,s2
    80003ee0:	00000097          	auipc	ra,0x0
    80003ee4:	b8a080e7          	jalr	-1142(ra) # 80003a6a <readi>
    80003ee8:	47c1                	li	a5,16
    80003eea:	06f51163          	bne	a0,a5,80003f4c <dirlink+0xa2>
    if(de.inum == 0)
    80003eee:	fc045783          	lhu	a5,-64(s0)
    80003ef2:	c791                	beqz	a5,80003efe <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef4:	24c1                	addiw	s1,s1,16
    80003ef6:	04c92783          	lw	a5,76(s2)
    80003efa:	fcf4ede3          	bltu	s1,a5,80003ed4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003efe:	4639                	li	a2,14
    80003f00:	85d2                	mv	a1,s4
    80003f02:	fc240513          	addi	a0,s0,-62
    80003f06:	ffffd097          	auipc	ra,0xffffd
    80003f0a:	ed8080e7          	jalr	-296(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003f0e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f12:	4741                	li	a4,16
    80003f14:	86a6                	mv	a3,s1
    80003f16:	fc040613          	addi	a2,s0,-64
    80003f1a:	4581                	li	a1,0
    80003f1c:	854a                	mv	a0,s2
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	c44080e7          	jalr	-956(ra) # 80003b62 <writei>
    80003f26:	1541                	addi	a0,a0,-16
    80003f28:	00a03533          	snez	a0,a0
    80003f2c:	40a00533          	neg	a0,a0
}
    80003f30:	70e2                	ld	ra,56(sp)
    80003f32:	7442                	ld	s0,48(sp)
    80003f34:	74a2                	ld	s1,40(sp)
    80003f36:	7902                	ld	s2,32(sp)
    80003f38:	69e2                	ld	s3,24(sp)
    80003f3a:	6a42                	ld	s4,16(sp)
    80003f3c:	6121                	addi	sp,sp,64
    80003f3e:	8082                	ret
    iput(ip);
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	a30080e7          	jalr	-1488(ra) # 80003970 <iput>
    return -1;
    80003f48:	557d                	li	a0,-1
    80003f4a:	b7dd                	j	80003f30 <dirlink+0x86>
      panic("dirlink read");
    80003f4c:	00004517          	auipc	a0,0x4
    80003f50:	6d450513          	addi	a0,a0,1748 # 80008620 <syscalls+0x1d8>
    80003f54:	ffffc097          	auipc	ra,0xffffc
    80003f58:	5ea080e7          	jalr	1514(ra) # 8000053e <panic>

0000000080003f5c <namei>:

struct inode*
namei(char *path)
{
    80003f5c:	1101                	addi	sp,sp,-32
    80003f5e:	ec06                	sd	ra,24(sp)
    80003f60:	e822                	sd	s0,16(sp)
    80003f62:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f64:	fe040613          	addi	a2,s0,-32
    80003f68:	4581                	li	a1,0
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	de0080e7          	jalr	-544(ra) # 80003d4a <namex>
}
    80003f72:	60e2                	ld	ra,24(sp)
    80003f74:	6442                	ld	s0,16(sp)
    80003f76:	6105                	addi	sp,sp,32
    80003f78:	8082                	ret

0000000080003f7a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f7a:	1141                	addi	sp,sp,-16
    80003f7c:	e406                	sd	ra,8(sp)
    80003f7e:	e022                	sd	s0,0(sp)
    80003f80:	0800                	addi	s0,sp,16
    80003f82:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f84:	4585                	li	a1,1
    80003f86:	00000097          	auipc	ra,0x0
    80003f8a:	dc4080e7          	jalr	-572(ra) # 80003d4a <namex>
}
    80003f8e:	60a2                	ld	ra,8(sp)
    80003f90:	6402                	ld	s0,0(sp)
    80003f92:	0141                	addi	sp,sp,16
    80003f94:	8082                	ret

0000000080003f96 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f96:	1101                	addi	sp,sp,-32
    80003f98:	ec06                	sd	ra,24(sp)
    80003f9a:	e822                	sd	s0,16(sp)
    80003f9c:	e426                	sd	s1,8(sp)
    80003f9e:	e04a                	sd	s2,0(sp)
    80003fa0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fa2:	0001d917          	auipc	s2,0x1d
    80003fa6:	4ce90913          	addi	s2,s2,1230 # 80021470 <log>
    80003faa:	01892583          	lw	a1,24(s2)
    80003fae:	02892503          	lw	a0,40(s2)
    80003fb2:	fffff097          	auipc	ra,0xfffff
    80003fb6:	fea080e7          	jalr	-22(ra) # 80002f9c <bread>
    80003fba:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fbc:	02c92683          	lw	a3,44(s2)
    80003fc0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fc2:	02d05763          	blez	a3,80003ff0 <write_head+0x5a>
    80003fc6:	0001d797          	auipc	a5,0x1d
    80003fca:	4da78793          	addi	a5,a5,1242 # 800214a0 <log+0x30>
    80003fce:	05c50713          	addi	a4,a0,92
    80003fd2:	36fd                	addiw	a3,a3,-1
    80003fd4:	1682                	slli	a3,a3,0x20
    80003fd6:	9281                	srli	a3,a3,0x20
    80003fd8:	068a                	slli	a3,a3,0x2
    80003fda:	0001d617          	auipc	a2,0x1d
    80003fde:	4ca60613          	addi	a2,a2,1226 # 800214a4 <log+0x34>
    80003fe2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fe4:	4390                	lw	a2,0(a5)
    80003fe6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fe8:	0791                	addi	a5,a5,4
    80003fea:	0711                	addi	a4,a4,4
    80003fec:	fed79ce3          	bne	a5,a3,80003fe4 <write_head+0x4e>
  }
  bwrite(buf);
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	09c080e7          	jalr	156(ra) # 8000308e <bwrite>
  brelse(buf);
    80003ffa:	8526                	mv	a0,s1
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	0d0080e7          	jalr	208(ra) # 800030cc <brelse>
}
    80004004:	60e2                	ld	ra,24(sp)
    80004006:	6442                	ld	s0,16(sp)
    80004008:	64a2                	ld	s1,8(sp)
    8000400a:	6902                	ld	s2,0(sp)
    8000400c:	6105                	addi	sp,sp,32
    8000400e:	8082                	ret

0000000080004010 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004010:	0001d797          	auipc	a5,0x1d
    80004014:	48c7a783          	lw	a5,1164(a5) # 8002149c <log+0x2c>
    80004018:	0af05d63          	blez	a5,800040d2 <install_trans+0xc2>
{
    8000401c:	7139                	addi	sp,sp,-64
    8000401e:	fc06                	sd	ra,56(sp)
    80004020:	f822                	sd	s0,48(sp)
    80004022:	f426                	sd	s1,40(sp)
    80004024:	f04a                	sd	s2,32(sp)
    80004026:	ec4e                	sd	s3,24(sp)
    80004028:	e852                	sd	s4,16(sp)
    8000402a:	e456                	sd	s5,8(sp)
    8000402c:	e05a                	sd	s6,0(sp)
    8000402e:	0080                	addi	s0,sp,64
    80004030:	8b2a                	mv	s6,a0
    80004032:	0001da97          	auipc	s5,0x1d
    80004036:	46ea8a93          	addi	s5,s5,1134 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000403a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000403c:	0001d997          	auipc	s3,0x1d
    80004040:	43498993          	addi	s3,s3,1076 # 80021470 <log>
    80004044:	a00d                	j	80004066 <install_trans+0x56>
    brelse(lbuf);
    80004046:	854a                	mv	a0,s2
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	084080e7          	jalr	132(ra) # 800030cc <brelse>
    brelse(dbuf);
    80004050:	8526                	mv	a0,s1
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	07a080e7          	jalr	122(ra) # 800030cc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000405a:	2a05                	addiw	s4,s4,1
    8000405c:	0a91                	addi	s5,s5,4
    8000405e:	02c9a783          	lw	a5,44(s3)
    80004062:	04fa5e63          	bge	s4,a5,800040be <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004066:	0189a583          	lw	a1,24(s3)
    8000406a:	014585bb          	addw	a1,a1,s4
    8000406e:	2585                	addiw	a1,a1,1
    80004070:	0289a503          	lw	a0,40(s3)
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	f28080e7          	jalr	-216(ra) # 80002f9c <bread>
    8000407c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000407e:	000aa583          	lw	a1,0(s5)
    80004082:	0289a503          	lw	a0,40(s3)
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	f16080e7          	jalr	-234(ra) # 80002f9c <bread>
    8000408e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004090:	40000613          	li	a2,1024
    80004094:	05890593          	addi	a1,s2,88
    80004098:	05850513          	addi	a0,a0,88
    8000409c:	ffffd097          	auipc	ra,0xffffd
    800040a0:	c92080e7          	jalr	-878(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800040a4:	8526                	mv	a0,s1
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	fe8080e7          	jalr	-24(ra) # 8000308e <bwrite>
    if(recovering == 0)
    800040ae:	f80b1ce3          	bnez	s6,80004046 <install_trans+0x36>
      bunpin(dbuf);
    800040b2:	8526                	mv	a0,s1
    800040b4:	fffff097          	auipc	ra,0xfffff
    800040b8:	0f2080e7          	jalr	242(ra) # 800031a6 <bunpin>
    800040bc:	b769                	j	80004046 <install_trans+0x36>
}
    800040be:	70e2                	ld	ra,56(sp)
    800040c0:	7442                	ld	s0,48(sp)
    800040c2:	74a2                	ld	s1,40(sp)
    800040c4:	7902                	ld	s2,32(sp)
    800040c6:	69e2                	ld	s3,24(sp)
    800040c8:	6a42                	ld	s4,16(sp)
    800040ca:	6aa2                	ld	s5,8(sp)
    800040cc:	6b02                	ld	s6,0(sp)
    800040ce:	6121                	addi	sp,sp,64
    800040d0:	8082                	ret
    800040d2:	8082                	ret

00000000800040d4 <initlog>:
{
    800040d4:	7179                	addi	sp,sp,-48
    800040d6:	f406                	sd	ra,40(sp)
    800040d8:	f022                	sd	s0,32(sp)
    800040da:	ec26                	sd	s1,24(sp)
    800040dc:	e84a                	sd	s2,16(sp)
    800040de:	e44e                	sd	s3,8(sp)
    800040e0:	1800                	addi	s0,sp,48
    800040e2:	892a                	mv	s2,a0
    800040e4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040e6:	0001d497          	auipc	s1,0x1d
    800040ea:	38a48493          	addi	s1,s1,906 # 80021470 <log>
    800040ee:	00004597          	auipc	a1,0x4
    800040f2:	54258593          	addi	a1,a1,1346 # 80008630 <syscalls+0x1e8>
    800040f6:	8526                	mv	a0,s1
    800040f8:	ffffd097          	auipc	ra,0xffffd
    800040fc:	a4e080e7          	jalr	-1458(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004100:	0149a583          	lw	a1,20(s3)
    80004104:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004106:	0109a783          	lw	a5,16(s3)
    8000410a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000410c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004110:	854a                	mv	a0,s2
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	e8a080e7          	jalr	-374(ra) # 80002f9c <bread>
  log.lh.n = lh->n;
    8000411a:	4d34                	lw	a3,88(a0)
    8000411c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000411e:	02d05563          	blez	a3,80004148 <initlog+0x74>
    80004122:	05c50793          	addi	a5,a0,92
    80004126:	0001d717          	auipc	a4,0x1d
    8000412a:	37a70713          	addi	a4,a4,890 # 800214a0 <log+0x30>
    8000412e:	36fd                	addiw	a3,a3,-1
    80004130:	1682                	slli	a3,a3,0x20
    80004132:	9281                	srli	a3,a3,0x20
    80004134:	068a                	slli	a3,a3,0x2
    80004136:	06050613          	addi	a2,a0,96
    8000413a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000413c:	4390                	lw	a2,0(a5)
    8000413e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004140:	0791                	addi	a5,a5,4
    80004142:	0711                	addi	a4,a4,4
    80004144:	fed79ce3          	bne	a5,a3,8000413c <initlog+0x68>
  brelse(buf);
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	f84080e7          	jalr	-124(ra) # 800030cc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004150:	4505                	li	a0,1
    80004152:	00000097          	auipc	ra,0x0
    80004156:	ebe080e7          	jalr	-322(ra) # 80004010 <install_trans>
  log.lh.n = 0;
    8000415a:	0001d797          	auipc	a5,0x1d
    8000415e:	3407a123          	sw	zero,834(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    80004162:	00000097          	auipc	ra,0x0
    80004166:	e34080e7          	jalr	-460(ra) # 80003f96 <write_head>
}
    8000416a:	70a2                	ld	ra,40(sp)
    8000416c:	7402                	ld	s0,32(sp)
    8000416e:	64e2                	ld	s1,24(sp)
    80004170:	6942                	ld	s2,16(sp)
    80004172:	69a2                	ld	s3,8(sp)
    80004174:	6145                	addi	sp,sp,48
    80004176:	8082                	ret

0000000080004178 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004178:	1101                	addi	sp,sp,-32
    8000417a:	ec06                	sd	ra,24(sp)
    8000417c:	e822                	sd	s0,16(sp)
    8000417e:	e426                	sd	s1,8(sp)
    80004180:	e04a                	sd	s2,0(sp)
    80004182:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004184:	0001d517          	auipc	a0,0x1d
    80004188:	2ec50513          	addi	a0,a0,748 # 80021470 <log>
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	a4a080e7          	jalr	-1462(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004194:	0001d497          	auipc	s1,0x1d
    80004198:	2dc48493          	addi	s1,s1,732 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000419c:	4979                	li	s2,30
    8000419e:	a039                	j	800041ac <begin_op+0x34>
      sleep(&log, &log.lock);
    800041a0:	85a6                	mv	a1,s1
    800041a2:	8526                	mv	a0,s1
    800041a4:	ffffe097          	auipc	ra,0xffffe
    800041a8:	f4e080e7          	jalr	-178(ra) # 800020f2 <sleep>
    if(log.committing){
    800041ac:	50dc                	lw	a5,36(s1)
    800041ae:	fbed                	bnez	a5,800041a0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041b0:	509c                	lw	a5,32(s1)
    800041b2:	0017871b          	addiw	a4,a5,1
    800041b6:	0007069b          	sext.w	a3,a4
    800041ba:	0027179b          	slliw	a5,a4,0x2
    800041be:	9fb9                	addw	a5,a5,a4
    800041c0:	0017979b          	slliw	a5,a5,0x1
    800041c4:	54d8                	lw	a4,44(s1)
    800041c6:	9fb9                	addw	a5,a5,a4
    800041c8:	00f95963          	bge	s2,a5,800041da <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041cc:	85a6                	mv	a1,s1
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffe097          	auipc	ra,0xffffe
    800041d4:	f22080e7          	jalr	-222(ra) # 800020f2 <sleep>
    800041d8:	bfd1                	j	800041ac <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041da:	0001d517          	auipc	a0,0x1d
    800041de:	29650513          	addi	a0,a0,662 # 80021470 <log>
    800041e2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	aa6080e7          	jalr	-1370(ra) # 80000c8a <release>
      break;
    }
  }
}
    800041ec:	60e2                	ld	ra,24(sp)
    800041ee:	6442                	ld	s0,16(sp)
    800041f0:	64a2                	ld	s1,8(sp)
    800041f2:	6902                	ld	s2,0(sp)
    800041f4:	6105                	addi	sp,sp,32
    800041f6:	8082                	ret

00000000800041f8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041f8:	7139                	addi	sp,sp,-64
    800041fa:	fc06                	sd	ra,56(sp)
    800041fc:	f822                	sd	s0,48(sp)
    800041fe:	f426                	sd	s1,40(sp)
    80004200:	f04a                	sd	s2,32(sp)
    80004202:	ec4e                	sd	s3,24(sp)
    80004204:	e852                	sd	s4,16(sp)
    80004206:	e456                	sd	s5,8(sp)
    80004208:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000420a:	0001d497          	auipc	s1,0x1d
    8000420e:	26648493          	addi	s1,s1,614 # 80021470 <log>
    80004212:	8526                	mv	a0,s1
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	9c2080e7          	jalr	-1598(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000421c:	509c                	lw	a5,32(s1)
    8000421e:	37fd                	addiw	a5,a5,-1
    80004220:	0007891b          	sext.w	s2,a5
    80004224:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004226:	50dc                	lw	a5,36(s1)
    80004228:	e7b9                	bnez	a5,80004276 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000422a:	04091e63          	bnez	s2,80004286 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000422e:	0001d497          	auipc	s1,0x1d
    80004232:	24248493          	addi	s1,s1,578 # 80021470 <log>
    80004236:	4785                	li	a5,1
    80004238:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000423a:	8526                	mv	a0,s1
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	a4e080e7          	jalr	-1458(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004244:	54dc                	lw	a5,44(s1)
    80004246:	06f04763          	bgtz	a5,800042b4 <end_op+0xbc>
    acquire(&log.lock);
    8000424a:	0001d497          	auipc	s1,0x1d
    8000424e:	22648493          	addi	s1,s1,550 # 80021470 <log>
    80004252:	8526                	mv	a0,s1
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	982080e7          	jalr	-1662(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000425c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004260:	8526                	mv	a0,s1
    80004262:	ffffe097          	auipc	ra,0xffffe
    80004266:	ef4080e7          	jalr	-268(ra) # 80002156 <wakeup>
    release(&log.lock);
    8000426a:	8526                	mv	a0,s1
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	a1e080e7          	jalr	-1506(ra) # 80000c8a <release>
}
    80004274:	a03d                	j	800042a2 <end_op+0xaa>
    panic("log.committing");
    80004276:	00004517          	auipc	a0,0x4
    8000427a:	3c250513          	addi	a0,a0,962 # 80008638 <syscalls+0x1f0>
    8000427e:	ffffc097          	auipc	ra,0xffffc
    80004282:	2c0080e7          	jalr	704(ra) # 8000053e <panic>
    wakeup(&log);
    80004286:	0001d497          	auipc	s1,0x1d
    8000428a:	1ea48493          	addi	s1,s1,490 # 80021470 <log>
    8000428e:	8526                	mv	a0,s1
    80004290:	ffffe097          	auipc	ra,0xffffe
    80004294:	ec6080e7          	jalr	-314(ra) # 80002156 <wakeup>
  release(&log.lock);
    80004298:	8526                	mv	a0,s1
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	9f0080e7          	jalr	-1552(ra) # 80000c8a <release>
}
    800042a2:	70e2                	ld	ra,56(sp)
    800042a4:	7442                	ld	s0,48(sp)
    800042a6:	74a2                	ld	s1,40(sp)
    800042a8:	7902                	ld	s2,32(sp)
    800042aa:	69e2                	ld	s3,24(sp)
    800042ac:	6a42                	ld	s4,16(sp)
    800042ae:	6aa2                	ld	s5,8(sp)
    800042b0:	6121                	addi	sp,sp,64
    800042b2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b4:	0001da97          	auipc	s5,0x1d
    800042b8:	1eca8a93          	addi	s5,s5,492 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042bc:	0001da17          	auipc	s4,0x1d
    800042c0:	1b4a0a13          	addi	s4,s4,436 # 80021470 <log>
    800042c4:	018a2583          	lw	a1,24(s4)
    800042c8:	012585bb          	addw	a1,a1,s2
    800042cc:	2585                	addiw	a1,a1,1
    800042ce:	028a2503          	lw	a0,40(s4)
    800042d2:	fffff097          	auipc	ra,0xfffff
    800042d6:	cca080e7          	jalr	-822(ra) # 80002f9c <bread>
    800042da:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042dc:	000aa583          	lw	a1,0(s5)
    800042e0:	028a2503          	lw	a0,40(s4)
    800042e4:	fffff097          	auipc	ra,0xfffff
    800042e8:	cb8080e7          	jalr	-840(ra) # 80002f9c <bread>
    800042ec:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042ee:	40000613          	li	a2,1024
    800042f2:	05850593          	addi	a1,a0,88
    800042f6:	05848513          	addi	a0,s1,88
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	a34080e7          	jalr	-1484(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004302:	8526                	mv	a0,s1
    80004304:	fffff097          	auipc	ra,0xfffff
    80004308:	d8a080e7          	jalr	-630(ra) # 8000308e <bwrite>
    brelse(from);
    8000430c:	854e                	mv	a0,s3
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	dbe080e7          	jalr	-578(ra) # 800030cc <brelse>
    brelse(to);
    80004316:	8526                	mv	a0,s1
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	db4080e7          	jalr	-588(ra) # 800030cc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004320:	2905                	addiw	s2,s2,1
    80004322:	0a91                	addi	s5,s5,4
    80004324:	02ca2783          	lw	a5,44(s4)
    80004328:	f8f94ee3          	blt	s2,a5,800042c4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	c6a080e7          	jalr	-918(ra) # 80003f96 <write_head>
    install_trans(0); // Now install writes to home locations
    80004334:	4501                	li	a0,0
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	cda080e7          	jalr	-806(ra) # 80004010 <install_trans>
    log.lh.n = 0;
    8000433e:	0001d797          	auipc	a5,0x1d
    80004342:	1407af23          	sw	zero,350(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	c50080e7          	jalr	-944(ra) # 80003f96 <write_head>
    8000434e:	bdf5                	j	8000424a <end_op+0x52>

0000000080004350 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004350:	1101                	addi	sp,sp,-32
    80004352:	ec06                	sd	ra,24(sp)
    80004354:	e822                	sd	s0,16(sp)
    80004356:	e426                	sd	s1,8(sp)
    80004358:	e04a                	sd	s2,0(sp)
    8000435a:	1000                	addi	s0,sp,32
    8000435c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000435e:	0001d917          	auipc	s2,0x1d
    80004362:	11290913          	addi	s2,s2,274 # 80021470 <log>
    80004366:	854a                	mv	a0,s2
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	86e080e7          	jalr	-1938(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004370:	02c92603          	lw	a2,44(s2)
    80004374:	47f5                	li	a5,29
    80004376:	06c7c563          	blt	a5,a2,800043e0 <log_write+0x90>
    8000437a:	0001d797          	auipc	a5,0x1d
    8000437e:	1127a783          	lw	a5,274(a5) # 8002148c <log+0x1c>
    80004382:	37fd                	addiw	a5,a5,-1
    80004384:	04f65e63          	bge	a2,a5,800043e0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004388:	0001d797          	auipc	a5,0x1d
    8000438c:	1087a783          	lw	a5,264(a5) # 80021490 <log+0x20>
    80004390:	06f05063          	blez	a5,800043f0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004394:	4781                	li	a5,0
    80004396:	06c05563          	blez	a2,80004400 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000439a:	44cc                	lw	a1,12(s1)
    8000439c:	0001d717          	auipc	a4,0x1d
    800043a0:	10470713          	addi	a4,a4,260 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043a4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043a6:	4314                	lw	a3,0(a4)
    800043a8:	04b68c63          	beq	a3,a1,80004400 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043ac:	2785                	addiw	a5,a5,1
    800043ae:	0711                	addi	a4,a4,4
    800043b0:	fef61be3          	bne	a2,a5,800043a6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043b4:	0621                	addi	a2,a2,8
    800043b6:	060a                	slli	a2,a2,0x2
    800043b8:	0001d797          	auipc	a5,0x1d
    800043bc:	0b878793          	addi	a5,a5,184 # 80021470 <log>
    800043c0:	963e                	add	a2,a2,a5
    800043c2:	44dc                	lw	a5,12(s1)
    800043c4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043c6:	8526                	mv	a0,s1
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	da2080e7          	jalr	-606(ra) # 8000316a <bpin>
    log.lh.n++;
    800043d0:	0001d717          	auipc	a4,0x1d
    800043d4:	0a070713          	addi	a4,a4,160 # 80021470 <log>
    800043d8:	575c                	lw	a5,44(a4)
    800043da:	2785                	addiw	a5,a5,1
    800043dc:	d75c                	sw	a5,44(a4)
    800043de:	a835                	j	8000441a <log_write+0xca>
    panic("too big a transaction");
    800043e0:	00004517          	auipc	a0,0x4
    800043e4:	26850513          	addi	a0,a0,616 # 80008648 <syscalls+0x200>
    800043e8:	ffffc097          	auipc	ra,0xffffc
    800043ec:	156080e7          	jalr	342(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800043f0:	00004517          	auipc	a0,0x4
    800043f4:	27050513          	addi	a0,a0,624 # 80008660 <syscalls+0x218>
    800043f8:	ffffc097          	auipc	ra,0xffffc
    800043fc:	146080e7          	jalr	326(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004400:	00878713          	addi	a4,a5,8
    80004404:	00271693          	slli	a3,a4,0x2
    80004408:	0001d717          	auipc	a4,0x1d
    8000440c:	06870713          	addi	a4,a4,104 # 80021470 <log>
    80004410:	9736                	add	a4,a4,a3
    80004412:	44d4                	lw	a3,12(s1)
    80004414:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004416:	faf608e3          	beq	a2,a5,800043c6 <log_write+0x76>
  }
  release(&log.lock);
    8000441a:	0001d517          	auipc	a0,0x1d
    8000441e:	05650513          	addi	a0,a0,86 # 80021470 <log>
    80004422:	ffffd097          	auipc	ra,0xffffd
    80004426:	868080e7          	jalr	-1944(ra) # 80000c8a <release>
}
    8000442a:	60e2                	ld	ra,24(sp)
    8000442c:	6442                	ld	s0,16(sp)
    8000442e:	64a2                	ld	s1,8(sp)
    80004430:	6902                	ld	s2,0(sp)
    80004432:	6105                	addi	sp,sp,32
    80004434:	8082                	ret

0000000080004436 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004436:	1101                	addi	sp,sp,-32
    80004438:	ec06                	sd	ra,24(sp)
    8000443a:	e822                	sd	s0,16(sp)
    8000443c:	e426                	sd	s1,8(sp)
    8000443e:	e04a                	sd	s2,0(sp)
    80004440:	1000                	addi	s0,sp,32
    80004442:	84aa                	mv	s1,a0
    80004444:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004446:	00004597          	auipc	a1,0x4
    8000444a:	23a58593          	addi	a1,a1,570 # 80008680 <syscalls+0x238>
    8000444e:	0521                	addi	a0,a0,8
    80004450:	ffffc097          	auipc	ra,0xffffc
    80004454:	6f6080e7          	jalr	1782(ra) # 80000b46 <initlock>
  lk->name = name;
    80004458:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000445c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004460:	0204a423          	sw	zero,40(s1)
}
    80004464:	60e2                	ld	ra,24(sp)
    80004466:	6442                	ld	s0,16(sp)
    80004468:	64a2                	ld	s1,8(sp)
    8000446a:	6902                	ld	s2,0(sp)
    8000446c:	6105                	addi	sp,sp,32
    8000446e:	8082                	ret

0000000080004470 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004470:	1101                	addi	sp,sp,-32
    80004472:	ec06                	sd	ra,24(sp)
    80004474:	e822                	sd	s0,16(sp)
    80004476:	e426                	sd	s1,8(sp)
    80004478:	e04a                	sd	s2,0(sp)
    8000447a:	1000                	addi	s0,sp,32
    8000447c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000447e:	00850913          	addi	s2,a0,8
    80004482:	854a                	mv	a0,s2
    80004484:	ffffc097          	auipc	ra,0xffffc
    80004488:	752080e7          	jalr	1874(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000448c:	409c                	lw	a5,0(s1)
    8000448e:	cb89                	beqz	a5,800044a0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004490:	85ca                	mv	a1,s2
    80004492:	8526                	mv	a0,s1
    80004494:	ffffe097          	auipc	ra,0xffffe
    80004498:	c5e080e7          	jalr	-930(ra) # 800020f2 <sleep>
  while (lk->locked) {
    8000449c:	409c                	lw	a5,0(s1)
    8000449e:	fbed                	bnez	a5,80004490 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044a0:	4785                	li	a5,1
    800044a2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044a4:	ffffd097          	auipc	ra,0xffffd
    800044a8:	540080e7          	jalr	1344(ra) # 800019e4 <myproc>
    800044ac:	591c                	lw	a5,48(a0)
    800044ae:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044b0:	854a                	mv	a0,s2
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	7d8080e7          	jalr	2008(ra) # 80000c8a <release>
}
    800044ba:	60e2                	ld	ra,24(sp)
    800044bc:	6442                	ld	s0,16(sp)
    800044be:	64a2                	ld	s1,8(sp)
    800044c0:	6902                	ld	s2,0(sp)
    800044c2:	6105                	addi	sp,sp,32
    800044c4:	8082                	ret

00000000800044c6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044c6:	1101                	addi	sp,sp,-32
    800044c8:	ec06                	sd	ra,24(sp)
    800044ca:	e822                	sd	s0,16(sp)
    800044cc:	e426                	sd	s1,8(sp)
    800044ce:	e04a                	sd	s2,0(sp)
    800044d0:	1000                	addi	s0,sp,32
    800044d2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044d4:	00850913          	addi	s2,a0,8
    800044d8:	854a                	mv	a0,s2
    800044da:	ffffc097          	auipc	ra,0xffffc
    800044de:	6fc080e7          	jalr	1788(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800044e2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044e6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044ea:	8526                	mv	a0,s1
    800044ec:	ffffe097          	auipc	ra,0xffffe
    800044f0:	c6a080e7          	jalr	-918(ra) # 80002156 <wakeup>
  release(&lk->lk);
    800044f4:	854a                	mv	a0,s2
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	794080e7          	jalr	1940(ra) # 80000c8a <release>
}
    800044fe:	60e2                	ld	ra,24(sp)
    80004500:	6442                	ld	s0,16(sp)
    80004502:	64a2                	ld	s1,8(sp)
    80004504:	6902                	ld	s2,0(sp)
    80004506:	6105                	addi	sp,sp,32
    80004508:	8082                	ret

000000008000450a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000450a:	7179                	addi	sp,sp,-48
    8000450c:	f406                	sd	ra,40(sp)
    8000450e:	f022                	sd	s0,32(sp)
    80004510:	ec26                	sd	s1,24(sp)
    80004512:	e84a                	sd	s2,16(sp)
    80004514:	e44e                	sd	s3,8(sp)
    80004516:	1800                	addi	s0,sp,48
    80004518:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000451a:	00850913          	addi	s2,a0,8
    8000451e:	854a                	mv	a0,s2
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	6b6080e7          	jalr	1718(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004528:	409c                	lw	a5,0(s1)
    8000452a:	ef99                	bnez	a5,80004548 <holdingsleep+0x3e>
    8000452c:	4481                	li	s1,0
  release(&lk->lk);
    8000452e:	854a                	mv	a0,s2
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	75a080e7          	jalr	1882(ra) # 80000c8a <release>
  return r;
}
    80004538:	8526                	mv	a0,s1
    8000453a:	70a2                	ld	ra,40(sp)
    8000453c:	7402                	ld	s0,32(sp)
    8000453e:	64e2                	ld	s1,24(sp)
    80004540:	6942                	ld	s2,16(sp)
    80004542:	69a2                	ld	s3,8(sp)
    80004544:	6145                	addi	sp,sp,48
    80004546:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004548:	0284a983          	lw	s3,40(s1)
    8000454c:	ffffd097          	auipc	ra,0xffffd
    80004550:	498080e7          	jalr	1176(ra) # 800019e4 <myproc>
    80004554:	5904                	lw	s1,48(a0)
    80004556:	413484b3          	sub	s1,s1,s3
    8000455a:	0014b493          	seqz	s1,s1
    8000455e:	bfc1                	j	8000452e <holdingsleep+0x24>

0000000080004560 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004560:	1141                	addi	sp,sp,-16
    80004562:	e406                	sd	ra,8(sp)
    80004564:	e022                	sd	s0,0(sp)
    80004566:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004568:	00004597          	auipc	a1,0x4
    8000456c:	12858593          	addi	a1,a1,296 # 80008690 <syscalls+0x248>
    80004570:	0001d517          	auipc	a0,0x1d
    80004574:	04850513          	addi	a0,a0,72 # 800215b8 <ftable>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	5ce080e7          	jalr	1486(ra) # 80000b46 <initlock>
}
    80004580:	60a2                	ld	ra,8(sp)
    80004582:	6402                	ld	s0,0(sp)
    80004584:	0141                	addi	sp,sp,16
    80004586:	8082                	ret

0000000080004588 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004588:	1101                	addi	sp,sp,-32
    8000458a:	ec06                	sd	ra,24(sp)
    8000458c:	e822                	sd	s0,16(sp)
    8000458e:	e426                	sd	s1,8(sp)
    80004590:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004592:	0001d517          	auipc	a0,0x1d
    80004596:	02650513          	addi	a0,a0,38 # 800215b8 <ftable>
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	63c080e7          	jalr	1596(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a2:	0001d497          	auipc	s1,0x1d
    800045a6:	02e48493          	addi	s1,s1,46 # 800215d0 <ftable+0x18>
    800045aa:	0001e717          	auipc	a4,0x1e
    800045ae:	fc670713          	addi	a4,a4,-58 # 80022570 <disk>
    if(f->ref == 0){
    800045b2:	40dc                	lw	a5,4(s1)
    800045b4:	cf99                	beqz	a5,800045d2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045b6:	02848493          	addi	s1,s1,40
    800045ba:	fee49ce3          	bne	s1,a4,800045b2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045be:	0001d517          	auipc	a0,0x1d
    800045c2:	ffa50513          	addi	a0,a0,-6 # 800215b8 <ftable>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	6c4080e7          	jalr	1732(ra) # 80000c8a <release>
  return 0;
    800045ce:	4481                	li	s1,0
    800045d0:	a819                	j	800045e6 <filealloc+0x5e>
      f->ref = 1;
    800045d2:	4785                	li	a5,1
    800045d4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045d6:	0001d517          	auipc	a0,0x1d
    800045da:	fe250513          	addi	a0,a0,-30 # 800215b8 <ftable>
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	6ac080e7          	jalr	1708(ra) # 80000c8a <release>
}
    800045e6:	8526                	mv	a0,s1
    800045e8:	60e2                	ld	ra,24(sp)
    800045ea:	6442                	ld	s0,16(sp)
    800045ec:	64a2                	ld	s1,8(sp)
    800045ee:	6105                	addi	sp,sp,32
    800045f0:	8082                	ret

00000000800045f2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045f2:	1101                	addi	sp,sp,-32
    800045f4:	ec06                	sd	ra,24(sp)
    800045f6:	e822                	sd	s0,16(sp)
    800045f8:	e426                	sd	s1,8(sp)
    800045fa:	1000                	addi	s0,sp,32
    800045fc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045fe:	0001d517          	auipc	a0,0x1d
    80004602:	fba50513          	addi	a0,a0,-70 # 800215b8 <ftable>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	5d0080e7          	jalr	1488(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000460e:	40dc                	lw	a5,4(s1)
    80004610:	02f05263          	blez	a5,80004634 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004614:	2785                	addiw	a5,a5,1
    80004616:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004618:	0001d517          	auipc	a0,0x1d
    8000461c:	fa050513          	addi	a0,a0,-96 # 800215b8 <ftable>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	66a080e7          	jalr	1642(ra) # 80000c8a <release>
  return f;
}
    80004628:	8526                	mv	a0,s1
    8000462a:	60e2                	ld	ra,24(sp)
    8000462c:	6442                	ld	s0,16(sp)
    8000462e:	64a2                	ld	s1,8(sp)
    80004630:	6105                	addi	sp,sp,32
    80004632:	8082                	ret
    panic("filedup");
    80004634:	00004517          	auipc	a0,0x4
    80004638:	06450513          	addi	a0,a0,100 # 80008698 <syscalls+0x250>
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	f02080e7          	jalr	-254(ra) # 8000053e <panic>

0000000080004644 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004644:	7139                	addi	sp,sp,-64
    80004646:	fc06                	sd	ra,56(sp)
    80004648:	f822                	sd	s0,48(sp)
    8000464a:	f426                	sd	s1,40(sp)
    8000464c:	f04a                	sd	s2,32(sp)
    8000464e:	ec4e                	sd	s3,24(sp)
    80004650:	e852                	sd	s4,16(sp)
    80004652:	e456                	sd	s5,8(sp)
    80004654:	0080                	addi	s0,sp,64
    80004656:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004658:	0001d517          	auipc	a0,0x1d
    8000465c:	f6050513          	addi	a0,a0,-160 # 800215b8 <ftable>
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	576080e7          	jalr	1398(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004668:	40dc                	lw	a5,4(s1)
    8000466a:	06f05163          	blez	a5,800046cc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000466e:	37fd                	addiw	a5,a5,-1
    80004670:	0007871b          	sext.w	a4,a5
    80004674:	c0dc                	sw	a5,4(s1)
    80004676:	06e04363          	bgtz	a4,800046dc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000467a:	0004a903          	lw	s2,0(s1)
    8000467e:	0094ca83          	lbu	s5,9(s1)
    80004682:	0104ba03          	ld	s4,16(s1)
    80004686:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000468a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000468e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004692:	0001d517          	auipc	a0,0x1d
    80004696:	f2650513          	addi	a0,a0,-218 # 800215b8 <ftable>
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	5f0080e7          	jalr	1520(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800046a2:	4785                	li	a5,1
    800046a4:	04f90d63          	beq	s2,a5,800046fe <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046a8:	3979                	addiw	s2,s2,-2
    800046aa:	4785                	li	a5,1
    800046ac:	0527e063          	bltu	a5,s2,800046ec <fileclose+0xa8>
    begin_op();
    800046b0:	00000097          	auipc	ra,0x0
    800046b4:	ac8080e7          	jalr	-1336(ra) # 80004178 <begin_op>
    iput(ff.ip);
    800046b8:	854e                	mv	a0,s3
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	2b6080e7          	jalr	694(ra) # 80003970 <iput>
    end_op();
    800046c2:	00000097          	auipc	ra,0x0
    800046c6:	b36080e7          	jalr	-1226(ra) # 800041f8 <end_op>
    800046ca:	a00d                	j	800046ec <fileclose+0xa8>
    panic("fileclose");
    800046cc:	00004517          	auipc	a0,0x4
    800046d0:	fd450513          	addi	a0,a0,-44 # 800086a0 <syscalls+0x258>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	e6a080e7          	jalr	-406(ra) # 8000053e <panic>
    release(&ftable.lock);
    800046dc:	0001d517          	auipc	a0,0x1d
    800046e0:	edc50513          	addi	a0,a0,-292 # 800215b8 <ftable>
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	5a6080e7          	jalr	1446(ra) # 80000c8a <release>
  }
}
    800046ec:	70e2                	ld	ra,56(sp)
    800046ee:	7442                	ld	s0,48(sp)
    800046f0:	74a2                	ld	s1,40(sp)
    800046f2:	7902                	ld	s2,32(sp)
    800046f4:	69e2                	ld	s3,24(sp)
    800046f6:	6a42                	ld	s4,16(sp)
    800046f8:	6aa2                	ld	s5,8(sp)
    800046fa:	6121                	addi	sp,sp,64
    800046fc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046fe:	85d6                	mv	a1,s5
    80004700:	8552                	mv	a0,s4
    80004702:	00000097          	auipc	ra,0x0
    80004706:	34c080e7          	jalr	844(ra) # 80004a4e <pipeclose>
    8000470a:	b7cd                	j	800046ec <fileclose+0xa8>

000000008000470c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000470c:	715d                	addi	sp,sp,-80
    8000470e:	e486                	sd	ra,72(sp)
    80004710:	e0a2                	sd	s0,64(sp)
    80004712:	fc26                	sd	s1,56(sp)
    80004714:	f84a                	sd	s2,48(sp)
    80004716:	f44e                	sd	s3,40(sp)
    80004718:	0880                	addi	s0,sp,80
    8000471a:	84aa                	mv	s1,a0
    8000471c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000471e:	ffffd097          	auipc	ra,0xffffd
    80004722:	2c6080e7          	jalr	710(ra) # 800019e4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004726:	409c                	lw	a5,0(s1)
    80004728:	37f9                	addiw	a5,a5,-2
    8000472a:	4705                	li	a4,1
    8000472c:	04f76763          	bltu	a4,a5,8000477a <filestat+0x6e>
    80004730:	892a                	mv	s2,a0
    ilock(f->ip);
    80004732:	6c88                	ld	a0,24(s1)
    80004734:	fffff097          	auipc	ra,0xfffff
    80004738:	082080e7          	jalr	130(ra) # 800037b6 <ilock>
    stati(f->ip, &st);
    8000473c:	fb840593          	addi	a1,s0,-72
    80004740:	6c88                	ld	a0,24(s1)
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	2fe080e7          	jalr	766(ra) # 80003a40 <stati>
    iunlock(f->ip);
    8000474a:	6c88                	ld	a0,24(s1)
    8000474c:	fffff097          	auipc	ra,0xfffff
    80004750:	12c080e7          	jalr	300(ra) # 80003878 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004754:	46e1                	li	a3,24
    80004756:	fb840613          	addi	a2,s0,-72
    8000475a:	85ce                	mv	a1,s3
    8000475c:	05093503          	ld	a0,80(s2)
    80004760:	ffffd097          	auipc	ra,0xffffd
    80004764:	f40080e7          	jalr	-192(ra) # 800016a0 <copyout>
    80004768:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000476c:	60a6                	ld	ra,72(sp)
    8000476e:	6406                	ld	s0,64(sp)
    80004770:	74e2                	ld	s1,56(sp)
    80004772:	7942                	ld	s2,48(sp)
    80004774:	79a2                	ld	s3,40(sp)
    80004776:	6161                	addi	sp,sp,80
    80004778:	8082                	ret
  return -1;
    8000477a:	557d                	li	a0,-1
    8000477c:	bfc5                	j	8000476c <filestat+0x60>

000000008000477e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000477e:	7179                	addi	sp,sp,-48
    80004780:	f406                	sd	ra,40(sp)
    80004782:	f022                	sd	s0,32(sp)
    80004784:	ec26                	sd	s1,24(sp)
    80004786:	e84a                	sd	s2,16(sp)
    80004788:	e44e                	sd	s3,8(sp)
    8000478a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000478c:	00854783          	lbu	a5,8(a0)
    80004790:	c3d5                	beqz	a5,80004834 <fileread+0xb6>
    80004792:	84aa                	mv	s1,a0
    80004794:	89ae                	mv	s3,a1
    80004796:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004798:	411c                	lw	a5,0(a0)
    8000479a:	4705                	li	a4,1
    8000479c:	04e78963          	beq	a5,a4,800047ee <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047a0:	470d                	li	a4,3
    800047a2:	04e78d63          	beq	a5,a4,800047fc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047a6:	4709                	li	a4,2
    800047a8:	06e79e63          	bne	a5,a4,80004824 <fileread+0xa6>
    ilock(f->ip);
    800047ac:	6d08                	ld	a0,24(a0)
    800047ae:	fffff097          	auipc	ra,0xfffff
    800047b2:	008080e7          	jalr	8(ra) # 800037b6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047b6:	874a                	mv	a4,s2
    800047b8:	5094                	lw	a3,32(s1)
    800047ba:	864e                	mv	a2,s3
    800047bc:	4585                	li	a1,1
    800047be:	6c88                	ld	a0,24(s1)
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	2aa080e7          	jalr	682(ra) # 80003a6a <readi>
    800047c8:	892a                	mv	s2,a0
    800047ca:	00a05563          	blez	a0,800047d4 <fileread+0x56>
      f->off += r;
    800047ce:	509c                	lw	a5,32(s1)
    800047d0:	9fa9                	addw	a5,a5,a0
    800047d2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047d4:	6c88                	ld	a0,24(s1)
    800047d6:	fffff097          	auipc	ra,0xfffff
    800047da:	0a2080e7          	jalr	162(ra) # 80003878 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047de:	854a                	mv	a0,s2
    800047e0:	70a2                	ld	ra,40(sp)
    800047e2:	7402                	ld	s0,32(sp)
    800047e4:	64e2                	ld	s1,24(sp)
    800047e6:	6942                	ld	s2,16(sp)
    800047e8:	69a2                	ld	s3,8(sp)
    800047ea:	6145                	addi	sp,sp,48
    800047ec:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047ee:	6908                	ld	a0,16(a0)
    800047f0:	00000097          	auipc	ra,0x0
    800047f4:	3c6080e7          	jalr	966(ra) # 80004bb6 <piperead>
    800047f8:	892a                	mv	s2,a0
    800047fa:	b7d5                	j	800047de <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047fc:	02451783          	lh	a5,36(a0)
    80004800:	03079693          	slli	a3,a5,0x30
    80004804:	92c1                	srli	a3,a3,0x30
    80004806:	4725                	li	a4,9
    80004808:	02d76863          	bltu	a4,a3,80004838 <fileread+0xba>
    8000480c:	0792                	slli	a5,a5,0x4
    8000480e:	0001d717          	auipc	a4,0x1d
    80004812:	d0a70713          	addi	a4,a4,-758 # 80021518 <devsw>
    80004816:	97ba                	add	a5,a5,a4
    80004818:	639c                	ld	a5,0(a5)
    8000481a:	c38d                	beqz	a5,8000483c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000481c:	4505                	li	a0,1
    8000481e:	9782                	jalr	a5
    80004820:	892a                	mv	s2,a0
    80004822:	bf75                	j	800047de <fileread+0x60>
    panic("fileread");
    80004824:	00004517          	auipc	a0,0x4
    80004828:	e8c50513          	addi	a0,a0,-372 # 800086b0 <syscalls+0x268>
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	d12080e7          	jalr	-750(ra) # 8000053e <panic>
    return -1;
    80004834:	597d                	li	s2,-1
    80004836:	b765                	j	800047de <fileread+0x60>
      return -1;
    80004838:	597d                	li	s2,-1
    8000483a:	b755                	j	800047de <fileread+0x60>
    8000483c:	597d                	li	s2,-1
    8000483e:	b745                	j	800047de <fileread+0x60>

0000000080004840 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004840:	715d                	addi	sp,sp,-80
    80004842:	e486                	sd	ra,72(sp)
    80004844:	e0a2                	sd	s0,64(sp)
    80004846:	fc26                	sd	s1,56(sp)
    80004848:	f84a                	sd	s2,48(sp)
    8000484a:	f44e                	sd	s3,40(sp)
    8000484c:	f052                	sd	s4,32(sp)
    8000484e:	ec56                	sd	s5,24(sp)
    80004850:	e85a                	sd	s6,16(sp)
    80004852:	e45e                	sd	s7,8(sp)
    80004854:	e062                	sd	s8,0(sp)
    80004856:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004858:	00954783          	lbu	a5,9(a0)
    8000485c:	10078663          	beqz	a5,80004968 <filewrite+0x128>
    80004860:	892a                	mv	s2,a0
    80004862:	8aae                	mv	s5,a1
    80004864:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004866:	411c                	lw	a5,0(a0)
    80004868:	4705                	li	a4,1
    8000486a:	02e78263          	beq	a5,a4,8000488e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000486e:	470d                	li	a4,3
    80004870:	02e78663          	beq	a5,a4,8000489c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004874:	4709                	li	a4,2
    80004876:	0ee79163          	bne	a5,a4,80004958 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000487a:	0ac05d63          	blez	a2,80004934 <filewrite+0xf4>
    int i = 0;
    8000487e:	4981                	li	s3,0
    80004880:	6b05                	lui	s6,0x1
    80004882:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004886:	6b85                	lui	s7,0x1
    80004888:	c00b8b9b          	addiw	s7,s7,-1024
    8000488c:	a861                	j	80004924 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000488e:	6908                	ld	a0,16(a0)
    80004890:	00000097          	auipc	ra,0x0
    80004894:	22e080e7          	jalr	558(ra) # 80004abe <pipewrite>
    80004898:	8a2a                	mv	s4,a0
    8000489a:	a045                	j	8000493a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000489c:	02451783          	lh	a5,36(a0)
    800048a0:	03079693          	slli	a3,a5,0x30
    800048a4:	92c1                	srli	a3,a3,0x30
    800048a6:	4725                	li	a4,9
    800048a8:	0cd76263          	bltu	a4,a3,8000496c <filewrite+0x12c>
    800048ac:	0792                	slli	a5,a5,0x4
    800048ae:	0001d717          	auipc	a4,0x1d
    800048b2:	c6a70713          	addi	a4,a4,-918 # 80021518 <devsw>
    800048b6:	97ba                	add	a5,a5,a4
    800048b8:	679c                	ld	a5,8(a5)
    800048ba:	cbdd                	beqz	a5,80004970 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048bc:	4505                	li	a0,1
    800048be:	9782                	jalr	a5
    800048c0:	8a2a                	mv	s4,a0
    800048c2:	a8a5                	j	8000493a <filewrite+0xfa>
    800048c4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048c8:	00000097          	auipc	ra,0x0
    800048cc:	8b0080e7          	jalr	-1872(ra) # 80004178 <begin_op>
      ilock(f->ip);
    800048d0:	01893503          	ld	a0,24(s2)
    800048d4:	fffff097          	auipc	ra,0xfffff
    800048d8:	ee2080e7          	jalr	-286(ra) # 800037b6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048dc:	8762                	mv	a4,s8
    800048de:	02092683          	lw	a3,32(s2)
    800048e2:	01598633          	add	a2,s3,s5
    800048e6:	4585                	li	a1,1
    800048e8:	01893503          	ld	a0,24(s2)
    800048ec:	fffff097          	auipc	ra,0xfffff
    800048f0:	276080e7          	jalr	630(ra) # 80003b62 <writei>
    800048f4:	84aa                	mv	s1,a0
    800048f6:	00a05763          	blez	a0,80004904 <filewrite+0xc4>
        f->off += r;
    800048fa:	02092783          	lw	a5,32(s2)
    800048fe:	9fa9                	addw	a5,a5,a0
    80004900:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004904:	01893503          	ld	a0,24(s2)
    80004908:	fffff097          	auipc	ra,0xfffff
    8000490c:	f70080e7          	jalr	-144(ra) # 80003878 <iunlock>
      end_op();
    80004910:	00000097          	auipc	ra,0x0
    80004914:	8e8080e7          	jalr	-1816(ra) # 800041f8 <end_op>

      if(r != n1){
    80004918:	009c1f63          	bne	s8,s1,80004936 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000491c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004920:	0149db63          	bge	s3,s4,80004936 <filewrite+0xf6>
      int n1 = n - i;
    80004924:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004928:	84be                	mv	s1,a5
    8000492a:	2781                	sext.w	a5,a5
    8000492c:	f8fb5ce3          	bge	s6,a5,800048c4 <filewrite+0x84>
    80004930:	84de                	mv	s1,s7
    80004932:	bf49                	j	800048c4 <filewrite+0x84>
    int i = 0;
    80004934:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004936:	013a1f63          	bne	s4,s3,80004954 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000493a:	8552                	mv	a0,s4
    8000493c:	60a6                	ld	ra,72(sp)
    8000493e:	6406                	ld	s0,64(sp)
    80004940:	74e2                	ld	s1,56(sp)
    80004942:	7942                	ld	s2,48(sp)
    80004944:	79a2                	ld	s3,40(sp)
    80004946:	7a02                	ld	s4,32(sp)
    80004948:	6ae2                	ld	s5,24(sp)
    8000494a:	6b42                	ld	s6,16(sp)
    8000494c:	6ba2                	ld	s7,8(sp)
    8000494e:	6c02                	ld	s8,0(sp)
    80004950:	6161                	addi	sp,sp,80
    80004952:	8082                	ret
    ret = (i == n ? n : -1);
    80004954:	5a7d                	li	s4,-1
    80004956:	b7d5                	j	8000493a <filewrite+0xfa>
    panic("filewrite");
    80004958:	00004517          	auipc	a0,0x4
    8000495c:	d6850513          	addi	a0,a0,-664 # 800086c0 <syscalls+0x278>
    80004960:	ffffc097          	auipc	ra,0xffffc
    80004964:	bde080e7          	jalr	-1058(ra) # 8000053e <panic>
    return -1;
    80004968:	5a7d                	li	s4,-1
    8000496a:	bfc1                	j	8000493a <filewrite+0xfa>
      return -1;
    8000496c:	5a7d                	li	s4,-1
    8000496e:	b7f1                	j	8000493a <filewrite+0xfa>
    80004970:	5a7d                	li	s4,-1
    80004972:	b7e1                	j	8000493a <filewrite+0xfa>

0000000080004974 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004974:	7179                	addi	sp,sp,-48
    80004976:	f406                	sd	ra,40(sp)
    80004978:	f022                	sd	s0,32(sp)
    8000497a:	ec26                	sd	s1,24(sp)
    8000497c:	e84a                	sd	s2,16(sp)
    8000497e:	e44e                	sd	s3,8(sp)
    80004980:	e052                	sd	s4,0(sp)
    80004982:	1800                	addi	s0,sp,48
    80004984:	84aa                	mv	s1,a0
    80004986:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004988:	0005b023          	sd	zero,0(a1)
    8000498c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004990:	00000097          	auipc	ra,0x0
    80004994:	bf8080e7          	jalr	-1032(ra) # 80004588 <filealloc>
    80004998:	e088                	sd	a0,0(s1)
    8000499a:	c551                	beqz	a0,80004a26 <pipealloc+0xb2>
    8000499c:	00000097          	auipc	ra,0x0
    800049a0:	bec080e7          	jalr	-1044(ra) # 80004588 <filealloc>
    800049a4:	00aa3023          	sd	a0,0(s4)
    800049a8:	c92d                	beqz	a0,80004a1a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	13c080e7          	jalr	316(ra) # 80000ae6 <kalloc>
    800049b2:	892a                	mv	s2,a0
    800049b4:	c125                	beqz	a0,80004a14 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049b6:	4985                	li	s3,1
    800049b8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049bc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049c0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049c4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049c8:	00004597          	auipc	a1,0x4
    800049cc:	d0858593          	addi	a1,a1,-760 # 800086d0 <syscalls+0x288>
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	176080e7          	jalr	374(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800049d8:	609c                	ld	a5,0(s1)
    800049da:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049de:	609c                	ld	a5,0(s1)
    800049e0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049e4:	609c                	ld	a5,0(s1)
    800049e6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049ea:	609c                	ld	a5,0(s1)
    800049ec:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049f0:	000a3783          	ld	a5,0(s4)
    800049f4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049f8:	000a3783          	ld	a5,0(s4)
    800049fc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a00:	000a3783          	ld	a5,0(s4)
    80004a04:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a08:	000a3783          	ld	a5,0(s4)
    80004a0c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a10:	4501                	li	a0,0
    80004a12:	a025                	j	80004a3a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a14:	6088                	ld	a0,0(s1)
    80004a16:	e501                	bnez	a0,80004a1e <pipealloc+0xaa>
    80004a18:	a039                	j	80004a26 <pipealloc+0xb2>
    80004a1a:	6088                	ld	a0,0(s1)
    80004a1c:	c51d                	beqz	a0,80004a4a <pipealloc+0xd6>
    fileclose(*f0);
    80004a1e:	00000097          	auipc	ra,0x0
    80004a22:	c26080e7          	jalr	-986(ra) # 80004644 <fileclose>
  if(*f1)
    80004a26:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a2a:	557d                	li	a0,-1
  if(*f1)
    80004a2c:	c799                	beqz	a5,80004a3a <pipealloc+0xc6>
    fileclose(*f1);
    80004a2e:	853e                	mv	a0,a5
    80004a30:	00000097          	auipc	ra,0x0
    80004a34:	c14080e7          	jalr	-1004(ra) # 80004644 <fileclose>
  return -1;
    80004a38:	557d                	li	a0,-1
}
    80004a3a:	70a2                	ld	ra,40(sp)
    80004a3c:	7402                	ld	s0,32(sp)
    80004a3e:	64e2                	ld	s1,24(sp)
    80004a40:	6942                	ld	s2,16(sp)
    80004a42:	69a2                	ld	s3,8(sp)
    80004a44:	6a02                	ld	s4,0(sp)
    80004a46:	6145                	addi	sp,sp,48
    80004a48:	8082                	ret
  return -1;
    80004a4a:	557d                	li	a0,-1
    80004a4c:	b7fd                	j	80004a3a <pipealloc+0xc6>

0000000080004a4e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a4e:	1101                	addi	sp,sp,-32
    80004a50:	ec06                	sd	ra,24(sp)
    80004a52:	e822                	sd	s0,16(sp)
    80004a54:	e426                	sd	s1,8(sp)
    80004a56:	e04a                	sd	s2,0(sp)
    80004a58:	1000                	addi	s0,sp,32
    80004a5a:	84aa                	mv	s1,a0
    80004a5c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	178080e7          	jalr	376(ra) # 80000bd6 <acquire>
  if(writable){
    80004a66:	02090d63          	beqz	s2,80004aa0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a6a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a6e:	21848513          	addi	a0,s1,536
    80004a72:	ffffd097          	auipc	ra,0xffffd
    80004a76:	6e4080e7          	jalr	1764(ra) # 80002156 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a7a:	2204b783          	ld	a5,544(s1)
    80004a7e:	eb95                	bnez	a5,80004ab2 <pipeclose+0x64>
    release(&pi->lock);
    80004a80:	8526                	mv	a0,s1
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	208080e7          	jalr	520(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004a8a:	8526                	mv	a0,s1
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004a94:	60e2                	ld	ra,24(sp)
    80004a96:	6442                	ld	s0,16(sp)
    80004a98:	64a2                	ld	s1,8(sp)
    80004a9a:	6902                	ld	s2,0(sp)
    80004a9c:	6105                	addi	sp,sp,32
    80004a9e:	8082                	ret
    pi->readopen = 0;
    80004aa0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aa4:	21c48513          	addi	a0,s1,540
    80004aa8:	ffffd097          	auipc	ra,0xffffd
    80004aac:	6ae080e7          	jalr	1710(ra) # 80002156 <wakeup>
    80004ab0:	b7e9                	j	80004a7a <pipeclose+0x2c>
    release(&pi->lock);
    80004ab2:	8526                	mv	a0,s1
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	1d6080e7          	jalr	470(ra) # 80000c8a <release>
}
    80004abc:	bfe1                	j	80004a94 <pipeclose+0x46>

0000000080004abe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004abe:	711d                	addi	sp,sp,-96
    80004ac0:	ec86                	sd	ra,88(sp)
    80004ac2:	e8a2                	sd	s0,80(sp)
    80004ac4:	e4a6                	sd	s1,72(sp)
    80004ac6:	e0ca                	sd	s2,64(sp)
    80004ac8:	fc4e                	sd	s3,56(sp)
    80004aca:	f852                	sd	s4,48(sp)
    80004acc:	f456                	sd	s5,40(sp)
    80004ace:	f05a                	sd	s6,32(sp)
    80004ad0:	ec5e                	sd	s7,24(sp)
    80004ad2:	e862                	sd	s8,16(sp)
    80004ad4:	1080                	addi	s0,sp,96
    80004ad6:	84aa                	mv	s1,a0
    80004ad8:	8aae                	mv	s5,a1
    80004ada:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004adc:	ffffd097          	auipc	ra,0xffffd
    80004ae0:	f08080e7          	jalr	-248(ra) # 800019e4 <myproc>
    80004ae4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ae6:	8526                	mv	a0,s1
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	0ee080e7          	jalr	238(ra) # 80000bd6 <acquire>
  while(i < n){
    80004af0:	0b405663          	blez	s4,80004b9c <pipewrite+0xde>
  int i = 0;
    80004af4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004af6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004af8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004afc:	21c48b93          	addi	s7,s1,540
    80004b00:	a089                	j	80004b42 <pipewrite+0x84>
      release(&pi->lock);
    80004b02:	8526                	mv	a0,s1
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	186080e7          	jalr	390(ra) # 80000c8a <release>
      return -1;
    80004b0c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b0e:	854a                	mv	a0,s2
    80004b10:	60e6                	ld	ra,88(sp)
    80004b12:	6446                	ld	s0,80(sp)
    80004b14:	64a6                	ld	s1,72(sp)
    80004b16:	6906                	ld	s2,64(sp)
    80004b18:	79e2                	ld	s3,56(sp)
    80004b1a:	7a42                	ld	s4,48(sp)
    80004b1c:	7aa2                	ld	s5,40(sp)
    80004b1e:	7b02                	ld	s6,32(sp)
    80004b20:	6be2                	ld	s7,24(sp)
    80004b22:	6c42                	ld	s8,16(sp)
    80004b24:	6125                	addi	sp,sp,96
    80004b26:	8082                	ret
      wakeup(&pi->nread);
    80004b28:	8562                	mv	a0,s8
    80004b2a:	ffffd097          	auipc	ra,0xffffd
    80004b2e:	62c080e7          	jalr	1580(ra) # 80002156 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b32:	85a6                	mv	a1,s1
    80004b34:	855e                	mv	a0,s7
    80004b36:	ffffd097          	auipc	ra,0xffffd
    80004b3a:	5bc080e7          	jalr	1468(ra) # 800020f2 <sleep>
  while(i < n){
    80004b3e:	07495063          	bge	s2,s4,80004b9e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b42:	2204a783          	lw	a5,544(s1)
    80004b46:	dfd5                	beqz	a5,80004b02 <pipewrite+0x44>
    80004b48:	854e                	mv	a0,s3
    80004b4a:	ffffe097          	auipc	ra,0xffffe
    80004b4e:	850080e7          	jalr	-1968(ra) # 8000239a <killed>
    80004b52:	f945                	bnez	a0,80004b02 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b54:	2184a783          	lw	a5,536(s1)
    80004b58:	21c4a703          	lw	a4,540(s1)
    80004b5c:	2007879b          	addiw	a5,a5,512
    80004b60:	fcf704e3          	beq	a4,a5,80004b28 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b64:	4685                	li	a3,1
    80004b66:	01590633          	add	a2,s2,s5
    80004b6a:	faf40593          	addi	a1,s0,-81
    80004b6e:	0509b503          	ld	a0,80(s3)
    80004b72:	ffffd097          	auipc	ra,0xffffd
    80004b76:	bba080e7          	jalr	-1094(ra) # 8000172c <copyin>
    80004b7a:	03650263          	beq	a0,s6,80004b9e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b7e:	21c4a783          	lw	a5,540(s1)
    80004b82:	0017871b          	addiw	a4,a5,1
    80004b86:	20e4ae23          	sw	a4,540(s1)
    80004b8a:	1ff7f793          	andi	a5,a5,511
    80004b8e:	97a6                	add	a5,a5,s1
    80004b90:	faf44703          	lbu	a4,-81(s0)
    80004b94:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b98:	2905                	addiw	s2,s2,1
    80004b9a:	b755                	j	80004b3e <pipewrite+0x80>
  int i = 0;
    80004b9c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b9e:	21848513          	addi	a0,s1,536
    80004ba2:	ffffd097          	auipc	ra,0xffffd
    80004ba6:	5b4080e7          	jalr	1460(ra) # 80002156 <wakeup>
  release(&pi->lock);
    80004baa:	8526                	mv	a0,s1
    80004bac:	ffffc097          	auipc	ra,0xffffc
    80004bb0:	0de080e7          	jalr	222(ra) # 80000c8a <release>
  return i;
    80004bb4:	bfa9                	j	80004b0e <pipewrite+0x50>

0000000080004bb6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bb6:	715d                	addi	sp,sp,-80
    80004bb8:	e486                	sd	ra,72(sp)
    80004bba:	e0a2                	sd	s0,64(sp)
    80004bbc:	fc26                	sd	s1,56(sp)
    80004bbe:	f84a                	sd	s2,48(sp)
    80004bc0:	f44e                	sd	s3,40(sp)
    80004bc2:	f052                	sd	s4,32(sp)
    80004bc4:	ec56                	sd	s5,24(sp)
    80004bc6:	e85a                	sd	s6,16(sp)
    80004bc8:	0880                	addi	s0,sp,80
    80004bca:	84aa                	mv	s1,a0
    80004bcc:	892e                	mv	s2,a1
    80004bce:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bd0:	ffffd097          	auipc	ra,0xffffd
    80004bd4:	e14080e7          	jalr	-492(ra) # 800019e4 <myproc>
    80004bd8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bda:	8526                	mv	a0,s1
    80004bdc:	ffffc097          	auipc	ra,0xffffc
    80004be0:	ffa080e7          	jalr	-6(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be4:	2184a703          	lw	a4,536(s1)
    80004be8:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bec:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf0:	02f71763          	bne	a4,a5,80004c1e <piperead+0x68>
    80004bf4:	2244a783          	lw	a5,548(s1)
    80004bf8:	c39d                	beqz	a5,80004c1e <piperead+0x68>
    if(killed(pr)){
    80004bfa:	8552                	mv	a0,s4
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	79e080e7          	jalr	1950(ra) # 8000239a <killed>
    80004c04:	e941                	bnez	a0,80004c94 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c06:	85a6                	mv	a1,s1
    80004c08:	854e                	mv	a0,s3
    80004c0a:	ffffd097          	auipc	ra,0xffffd
    80004c0e:	4e8080e7          	jalr	1256(ra) # 800020f2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c12:	2184a703          	lw	a4,536(s1)
    80004c16:	21c4a783          	lw	a5,540(s1)
    80004c1a:	fcf70de3          	beq	a4,a5,80004bf4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c1e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c20:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c22:	05505363          	blez	s5,80004c68 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004c26:	2184a783          	lw	a5,536(s1)
    80004c2a:	21c4a703          	lw	a4,540(s1)
    80004c2e:	02f70d63          	beq	a4,a5,80004c68 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c32:	0017871b          	addiw	a4,a5,1
    80004c36:	20e4ac23          	sw	a4,536(s1)
    80004c3a:	1ff7f793          	andi	a5,a5,511
    80004c3e:	97a6                	add	a5,a5,s1
    80004c40:	0187c783          	lbu	a5,24(a5)
    80004c44:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c48:	4685                	li	a3,1
    80004c4a:	fbf40613          	addi	a2,s0,-65
    80004c4e:	85ca                	mv	a1,s2
    80004c50:	050a3503          	ld	a0,80(s4)
    80004c54:	ffffd097          	auipc	ra,0xffffd
    80004c58:	a4c080e7          	jalr	-1460(ra) # 800016a0 <copyout>
    80004c5c:	01650663          	beq	a0,s6,80004c68 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c60:	2985                	addiw	s3,s3,1
    80004c62:	0905                	addi	s2,s2,1
    80004c64:	fd3a91e3          	bne	s5,s3,80004c26 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c68:	21c48513          	addi	a0,s1,540
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	4ea080e7          	jalr	1258(ra) # 80002156 <wakeup>
  release(&pi->lock);
    80004c74:	8526                	mv	a0,s1
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	014080e7          	jalr	20(ra) # 80000c8a <release>
  return i;
}
    80004c7e:	854e                	mv	a0,s3
    80004c80:	60a6                	ld	ra,72(sp)
    80004c82:	6406                	ld	s0,64(sp)
    80004c84:	74e2                	ld	s1,56(sp)
    80004c86:	7942                	ld	s2,48(sp)
    80004c88:	79a2                	ld	s3,40(sp)
    80004c8a:	7a02                	ld	s4,32(sp)
    80004c8c:	6ae2                	ld	s5,24(sp)
    80004c8e:	6b42                	ld	s6,16(sp)
    80004c90:	6161                	addi	sp,sp,80
    80004c92:	8082                	ret
      release(&pi->lock);
    80004c94:	8526                	mv	a0,s1
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	ff4080e7          	jalr	-12(ra) # 80000c8a <release>
      return -1;
    80004c9e:	59fd                	li	s3,-1
    80004ca0:	bff9                	j	80004c7e <piperead+0xc8>

0000000080004ca2 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ca2:	1141                	addi	sp,sp,-16
    80004ca4:	e422                	sd	s0,8(sp)
    80004ca6:	0800                	addi	s0,sp,16
    80004ca8:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004caa:	8905                	andi	a0,a0,1
    80004cac:	c111                	beqz	a0,80004cb0 <flags2perm+0xe>
      perm = PTE_X;
    80004cae:	4521                	li	a0,8
    if(flags & 0x2)
    80004cb0:	8b89                	andi	a5,a5,2
    80004cb2:	c399                	beqz	a5,80004cb8 <flags2perm+0x16>
      perm |= PTE_W;
    80004cb4:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cb8:	6422                	ld	s0,8(sp)
    80004cba:	0141                	addi	sp,sp,16
    80004cbc:	8082                	ret

0000000080004cbe <exec>:

int
exec(char *path, char **argv)
{
    80004cbe:	de010113          	addi	sp,sp,-544
    80004cc2:	20113c23          	sd	ra,536(sp)
    80004cc6:	20813823          	sd	s0,528(sp)
    80004cca:	20913423          	sd	s1,520(sp)
    80004cce:	21213023          	sd	s2,512(sp)
    80004cd2:	ffce                	sd	s3,504(sp)
    80004cd4:	fbd2                	sd	s4,496(sp)
    80004cd6:	f7d6                	sd	s5,488(sp)
    80004cd8:	f3da                	sd	s6,480(sp)
    80004cda:	efde                	sd	s7,472(sp)
    80004cdc:	ebe2                	sd	s8,464(sp)
    80004cde:	e7e6                	sd	s9,456(sp)
    80004ce0:	e3ea                	sd	s10,448(sp)
    80004ce2:	ff6e                	sd	s11,440(sp)
    80004ce4:	1400                	addi	s0,sp,544
    80004ce6:	892a                	mv	s2,a0
    80004ce8:	dea43423          	sd	a0,-536(s0)
    80004cec:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	cf4080e7          	jalr	-780(ra) # 800019e4 <myproc>
    80004cf8:	84aa                	mv	s1,a0

  begin_op();
    80004cfa:	fffff097          	auipc	ra,0xfffff
    80004cfe:	47e080e7          	jalr	1150(ra) # 80004178 <begin_op>

  if((ip = namei(path)) == 0){
    80004d02:	854a                	mv	a0,s2
    80004d04:	fffff097          	auipc	ra,0xfffff
    80004d08:	258080e7          	jalr	600(ra) # 80003f5c <namei>
    80004d0c:	c93d                	beqz	a0,80004d82 <exec+0xc4>
    80004d0e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	aa6080e7          	jalr	-1370(ra) # 800037b6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d18:	04000713          	li	a4,64
    80004d1c:	4681                	li	a3,0
    80004d1e:	e5040613          	addi	a2,s0,-432
    80004d22:	4581                	li	a1,0
    80004d24:	8556                	mv	a0,s5
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	d44080e7          	jalr	-700(ra) # 80003a6a <readi>
    80004d2e:	04000793          	li	a5,64
    80004d32:	00f51a63          	bne	a0,a5,80004d46 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d36:	e5042703          	lw	a4,-432(s0)
    80004d3a:	464c47b7          	lui	a5,0x464c4
    80004d3e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d42:	04f70663          	beq	a4,a5,80004d8e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d46:	8556                	mv	a0,s5
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	cd0080e7          	jalr	-816(ra) # 80003a18 <iunlockput>
    end_op();
    80004d50:	fffff097          	auipc	ra,0xfffff
    80004d54:	4a8080e7          	jalr	1192(ra) # 800041f8 <end_op>
  }
  return -1;
    80004d58:	557d                	li	a0,-1
}
    80004d5a:	21813083          	ld	ra,536(sp)
    80004d5e:	21013403          	ld	s0,528(sp)
    80004d62:	20813483          	ld	s1,520(sp)
    80004d66:	20013903          	ld	s2,512(sp)
    80004d6a:	79fe                	ld	s3,504(sp)
    80004d6c:	7a5e                	ld	s4,496(sp)
    80004d6e:	7abe                	ld	s5,488(sp)
    80004d70:	7b1e                	ld	s6,480(sp)
    80004d72:	6bfe                	ld	s7,472(sp)
    80004d74:	6c5e                	ld	s8,464(sp)
    80004d76:	6cbe                	ld	s9,456(sp)
    80004d78:	6d1e                	ld	s10,448(sp)
    80004d7a:	7dfa                	ld	s11,440(sp)
    80004d7c:	22010113          	addi	sp,sp,544
    80004d80:	8082                	ret
    end_op();
    80004d82:	fffff097          	auipc	ra,0xfffff
    80004d86:	476080e7          	jalr	1142(ra) # 800041f8 <end_op>
    return -1;
    80004d8a:	557d                	li	a0,-1
    80004d8c:	b7f9                	j	80004d5a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d8e:	8526                	mv	a0,s1
    80004d90:	ffffd097          	auipc	ra,0xffffd
    80004d94:	d18080e7          	jalr	-744(ra) # 80001aa8 <proc_pagetable>
    80004d98:	8b2a                	mv	s6,a0
    80004d9a:	d555                	beqz	a0,80004d46 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d9c:	e7042783          	lw	a5,-400(s0)
    80004da0:	e8845703          	lhu	a4,-376(s0)
    80004da4:	c735                	beqz	a4,80004e10 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004da6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004dac:	6a05                	lui	s4,0x1
    80004dae:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004db2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004db6:	6d85                	lui	s11,0x1
    80004db8:	7d7d                	lui	s10,0xfffff
    80004dba:	a481                	j	80004ffa <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dbc:	00004517          	auipc	a0,0x4
    80004dc0:	91c50513          	addi	a0,a0,-1764 # 800086d8 <syscalls+0x290>
    80004dc4:	ffffb097          	auipc	ra,0xffffb
    80004dc8:	77a080e7          	jalr	1914(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dcc:	874a                	mv	a4,s2
    80004dce:	009c86bb          	addw	a3,s9,s1
    80004dd2:	4581                	li	a1,0
    80004dd4:	8556                	mv	a0,s5
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	c94080e7          	jalr	-876(ra) # 80003a6a <readi>
    80004dde:	2501                	sext.w	a0,a0
    80004de0:	1aa91a63          	bne	s2,a0,80004f94 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004de4:	009d84bb          	addw	s1,s11,s1
    80004de8:	013d09bb          	addw	s3,s10,s3
    80004dec:	1f74f763          	bgeu	s1,s7,80004fda <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004df0:	02049593          	slli	a1,s1,0x20
    80004df4:	9181                	srli	a1,a1,0x20
    80004df6:	95e2                	add	a1,a1,s8
    80004df8:	855a                	mv	a0,s6
    80004dfa:	ffffc097          	auipc	ra,0xffffc
    80004dfe:	282080e7          	jalr	642(ra) # 8000107c <walkaddr>
    80004e02:	862a                	mv	a2,a0
    if(pa == 0)
    80004e04:	dd45                	beqz	a0,80004dbc <exec+0xfe>
      n = PGSIZE;
    80004e06:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e08:	fd49f2e3          	bgeu	s3,s4,80004dcc <exec+0x10e>
      n = sz - i;
    80004e0c:	894e                	mv	s2,s3
    80004e0e:	bf7d                	j	80004dcc <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e10:	4901                	li	s2,0
  iunlockput(ip);
    80004e12:	8556                	mv	a0,s5
    80004e14:	fffff097          	auipc	ra,0xfffff
    80004e18:	c04080e7          	jalr	-1020(ra) # 80003a18 <iunlockput>
  end_op();
    80004e1c:	fffff097          	auipc	ra,0xfffff
    80004e20:	3dc080e7          	jalr	988(ra) # 800041f8 <end_op>
  p = myproc();
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	bc0080e7          	jalr	-1088(ra) # 800019e4 <myproc>
    80004e2c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e2e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e32:	6785                	lui	a5,0x1
    80004e34:	17fd                	addi	a5,a5,-1
    80004e36:	993e                	add	s2,s2,a5
    80004e38:	77fd                	lui	a5,0xfffff
    80004e3a:	00f977b3          	and	a5,s2,a5
    80004e3e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e42:	4691                	li	a3,4
    80004e44:	6609                	lui	a2,0x2
    80004e46:	963e                	add	a2,a2,a5
    80004e48:	85be                	mv	a1,a5
    80004e4a:	855a                	mv	a0,s6
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	5fc080e7          	jalr	1532(ra) # 80001448 <uvmalloc>
    80004e54:	8c2a                	mv	s8,a0
  ip = 0;
    80004e56:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e58:	12050e63          	beqz	a0,80004f94 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e5c:	75f9                	lui	a1,0xffffe
    80004e5e:	95aa                	add	a1,a1,a0
    80004e60:	855a                	mv	a0,s6
    80004e62:	ffffd097          	auipc	ra,0xffffd
    80004e66:	80c080e7          	jalr	-2036(ra) # 8000166e <uvmclear>
  stackbase = sp - PGSIZE;
    80004e6a:	7afd                	lui	s5,0xfffff
    80004e6c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e6e:	df043783          	ld	a5,-528(s0)
    80004e72:	6388                	ld	a0,0(a5)
    80004e74:	c925                	beqz	a0,80004ee4 <exec+0x226>
    80004e76:	e9040993          	addi	s3,s0,-368
    80004e7a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e7e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e80:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	fcc080e7          	jalr	-52(ra) # 80000e4e <strlen>
    80004e8a:	0015079b          	addiw	a5,a0,1
    80004e8e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e92:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e96:	13596663          	bltu	s2,s5,80004fc2 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e9a:	df043d83          	ld	s11,-528(s0)
    80004e9e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ea2:	8552                	mv	a0,s4
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	faa080e7          	jalr	-86(ra) # 80000e4e <strlen>
    80004eac:	0015069b          	addiw	a3,a0,1
    80004eb0:	8652                	mv	a2,s4
    80004eb2:	85ca                	mv	a1,s2
    80004eb4:	855a                	mv	a0,s6
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	7ea080e7          	jalr	2026(ra) # 800016a0 <copyout>
    80004ebe:	10054663          	bltz	a0,80004fca <exec+0x30c>
    ustack[argc] = sp;
    80004ec2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ec6:	0485                	addi	s1,s1,1
    80004ec8:	008d8793          	addi	a5,s11,8
    80004ecc:	def43823          	sd	a5,-528(s0)
    80004ed0:	008db503          	ld	a0,8(s11)
    80004ed4:	c911                	beqz	a0,80004ee8 <exec+0x22a>
    if(argc >= MAXARG)
    80004ed6:	09a1                	addi	s3,s3,8
    80004ed8:	fb3c95e3          	bne	s9,s3,80004e82 <exec+0x1c4>
  sz = sz1;
    80004edc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ee0:	4a81                	li	s5,0
    80004ee2:	a84d                	j	80004f94 <exec+0x2d6>
  sp = sz;
    80004ee4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ee6:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ee8:	00349793          	slli	a5,s1,0x3
    80004eec:	f9040713          	addi	a4,s0,-112
    80004ef0:	97ba                	add	a5,a5,a4
    80004ef2:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd9838>
  sp -= (argc+1) * sizeof(uint64);
    80004ef6:	00148693          	addi	a3,s1,1
    80004efa:	068e                	slli	a3,a3,0x3
    80004efc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f00:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f04:	01597663          	bgeu	s2,s5,80004f10 <exec+0x252>
  sz = sz1;
    80004f08:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f0c:	4a81                	li	s5,0
    80004f0e:	a059                	j	80004f94 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f10:	e9040613          	addi	a2,s0,-368
    80004f14:	85ca                	mv	a1,s2
    80004f16:	855a                	mv	a0,s6
    80004f18:	ffffc097          	auipc	ra,0xffffc
    80004f1c:	788080e7          	jalr	1928(ra) # 800016a0 <copyout>
    80004f20:	0a054963          	bltz	a0,80004fd2 <exec+0x314>
  p->trapframe->a1 = sp;
    80004f24:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f28:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f2c:	de843783          	ld	a5,-536(s0)
    80004f30:	0007c703          	lbu	a4,0(a5)
    80004f34:	cf11                	beqz	a4,80004f50 <exec+0x292>
    80004f36:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f38:	02f00693          	li	a3,47
    80004f3c:	a039                	j	80004f4a <exec+0x28c>
      last = s+1;
    80004f3e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f42:	0785                	addi	a5,a5,1
    80004f44:	fff7c703          	lbu	a4,-1(a5)
    80004f48:	c701                	beqz	a4,80004f50 <exec+0x292>
    if(*s == '/')
    80004f4a:	fed71ce3          	bne	a4,a3,80004f42 <exec+0x284>
    80004f4e:	bfc5                	j	80004f3e <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f50:	4641                	li	a2,16
    80004f52:	de843583          	ld	a1,-536(s0)
    80004f56:	158b8513          	addi	a0,s7,344
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	ec2080e7          	jalr	-318(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f62:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f66:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f6a:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f6e:	058bb783          	ld	a5,88(s7)
    80004f72:	e6843703          	ld	a4,-408(s0)
    80004f76:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f78:	058bb783          	ld	a5,88(s7)
    80004f7c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f80:	85ea                	mv	a1,s10
    80004f82:	ffffd097          	auipc	ra,0xffffd
    80004f86:	bc2080e7          	jalr	-1086(ra) # 80001b44 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f8a:	0004851b          	sext.w	a0,s1
    80004f8e:	b3f1                	j	80004d5a <exec+0x9c>
    80004f90:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f94:	df843583          	ld	a1,-520(s0)
    80004f98:	855a                	mv	a0,s6
    80004f9a:	ffffd097          	auipc	ra,0xffffd
    80004f9e:	baa080e7          	jalr	-1110(ra) # 80001b44 <proc_freepagetable>
  if(ip){
    80004fa2:	da0a92e3          	bnez	s5,80004d46 <exec+0x88>
  return -1;
    80004fa6:	557d                	li	a0,-1
    80004fa8:	bb4d                	j	80004d5a <exec+0x9c>
    80004faa:	df243c23          	sd	s2,-520(s0)
    80004fae:	b7dd                	j	80004f94 <exec+0x2d6>
    80004fb0:	df243c23          	sd	s2,-520(s0)
    80004fb4:	b7c5                	j	80004f94 <exec+0x2d6>
    80004fb6:	df243c23          	sd	s2,-520(s0)
    80004fba:	bfe9                	j	80004f94 <exec+0x2d6>
    80004fbc:	df243c23          	sd	s2,-520(s0)
    80004fc0:	bfd1                	j	80004f94 <exec+0x2d6>
  sz = sz1;
    80004fc2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fc6:	4a81                	li	s5,0
    80004fc8:	b7f1                	j	80004f94 <exec+0x2d6>
  sz = sz1;
    80004fca:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fce:	4a81                	li	s5,0
    80004fd0:	b7d1                	j	80004f94 <exec+0x2d6>
  sz = sz1;
    80004fd2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fd6:	4a81                	li	s5,0
    80004fd8:	bf75                	j	80004f94 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fda:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fde:	e0843783          	ld	a5,-504(s0)
    80004fe2:	0017869b          	addiw	a3,a5,1
    80004fe6:	e0d43423          	sd	a3,-504(s0)
    80004fea:	e0043783          	ld	a5,-512(s0)
    80004fee:	0387879b          	addiw	a5,a5,56
    80004ff2:	e8845703          	lhu	a4,-376(s0)
    80004ff6:	e0e6dee3          	bge	a3,a4,80004e12 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ffa:	2781                	sext.w	a5,a5
    80004ffc:	e0f43023          	sd	a5,-512(s0)
    80005000:	03800713          	li	a4,56
    80005004:	86be                	mv	a3,a5
    80005006:	e1840613          	addi	a2,s0,-488
    8000500a:	4581                	li	a1,0
    8000500c:	8556                	mv	a0,s5
    8000500e:	fffff097          	auipc	ra,0xfffff
    80005012:	a5c080e7          	jalr	-1444(ra) # 80003a6a <readi>
    80005016:	03800793          	li	a5,56
    8000501a:	f6f51be3          	bne	a0,a5,80004f90 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000501e:	e1842783          	lw	a5,-488(s0)
    80005022:	4705                	li	a4,1
    80005024:	fae79de3          	bne	a5,a4,80004fde <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005028:	e4043483          	ld	s1,-448(s0)
    8000502c:	e3843783          	ld	a5,-456(s0)
    80005030:	f6f4ede3          	bltu	s1,a5,80004faa <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005034:	e2843783          	ld	a5,-472(s0)
    80005038:	94be                	add	s1,s1,a5
    8000503a:	f6f4ebe3          	bltu	s1,a5,80004fb0 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000503e:	de043703          	ld	a4,-544(s0)
    80005042:	8ff9                	and	a5,a5,a4
    80005044:	fbad                	bnez	a5,80004fb6 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005046:	e1c42503          	lw	a0,-484(s0)
    8000504a:	00000097          	auipc	ra,0x0
    8000504e:	c58080e7          	jalr	-936(ra) # 80004ca2 <flags2perm>
    80005052:	86aa                	mv	a3,a0
    80005054:	8626                	mv	a2,s1
    80005056:	85ca                	mv	a1,s2
    80005058:	855a                	mv	a0,s6
    8000505a:	ffffc097          	auipc	ra,0xffffc
    8000505e:	3ee080e7          	jalr	1006(ra) # 80001448 <uvmalloc>
    80005062:	dea43c23          	sd	a0,-520(s0)
    80005066:	d939                	beqz	a0,80004fbc <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005068:	e2843c03          	ld	s8,-472(s0)
    8000506c:	e2042c83          	lw	s9,-480(s0)
    80005070:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005074:	f60b83e3          	beqz	s7,80004fda <exec+0x31c>
    80005078:	89de                	mv	s3,s7
    8000507a:	4481                	li	s1,0
    8000507c:	bb95                	j	80004df0 <exec+0x132>

000000008000507e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000507e:	7179                	addi	sp,sp,-48
    80005080:	f406                	sd	ra,40(sp)
    80005082:	f022                	sd	s0,32(sp)
    80005084:	ec26                	sd	s1,24(sp)
    80005086:	e84a                	sd	s2,16(sp)
    80005088:	1800                	addi	s0,sp,48
    8000508a:	892e                	mv	s2,a1
    8000508c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000508e:	fdc40593          	addi	a1,s0,-36
    80005092:	ffffe097          	auipc	ra,0xffffe
    80005096:	b80080e7          	jalr	-1152(ra) # 80002c12 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000509a:	fdc42703          	lw	a4,-36(s0)
    8000509e:	47bd                	li	a5,15
    800050a0:	02e7eb63          	bltu	a5,a4,800050d6 <argfd+0x58>
    800050a4:	ffffd097          	auipc	ra,0xffffd
    800050a8:	940080e7          	jalr	-1728(ra) # 800019e4 <myproc>
    800050ac:	fdc42703          	lw	a4,-36(s0)
    800050b0:	01a70793          	addi	a5,a4,26
    800050b4:	078e                	slli	a5,a5,0x3
    800050b6:	953e                	add	a0,a0,a5
    800050b8:	611c                	ld	a5,0(a0)
    800050ba:	c385                	beqz	a5,800050da <argfd+0x5c>
    return -1;
  if(pfd)
    800050bc:	00090463          	beqz	s2,800050c4 <argfd+0x46>
    *pfd = fd;
    800050c0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050c4:	4501                	li	a0,0
  if(pf)
    800050c6:	c091                	beqz	s1,800050ca <argfd+0x4c>
    *pf = f;
    800050c8:	e09c                	sd	a5,0(s1)
}
    800050ca:	70a2                	ld	ra,40(sp)
    800050cc:	7402                	ld	s0,32(sp)
    800050ce:	64e2                	ld	s1,24(sp)
    800050d0:	6942                	ld	s2,16(sp)
    800050d2:	6145                	addi	sp,sp,48
    800050d4:	8082                	ret
    return -1;
    800050d6:	557d                	li	a0,-1
    800050d8:	bfcd                	j	800050ca <argfd+0x4c>
    800050da:	557d                	li	a0,-1
    800050dc:	b7fd                	j	800050ca <argfd+0x4c>

00000000800050de <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050de:	1101                	addi	sp,sp,-32
    800050e0:	ec06                	sd	ra,24(sp)
    800050e2:	e822                	sd	s0,16(sp)
    800050e4:	e426                	sd	s1,8(sp)
    800050e6:	1000                	addi	s0,sp,32
    800050e8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050ea:	ffffd097          	auipc	ra,0xffffd
    800050ee:	8fa080e7          	jalr	-1798(ra) # 800019e4 <myproc>
    800050f2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050f4:	0d050793          	addi	a5,a0,208
    800050f8:	4501                	li	a0,0
    800050fa:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050fc:	6398                	ld	a4,0(a5)
    800050fe:	cb19                	beqz	a4,80005114 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005100:	2505                	addiw	a0,a0,1
    80005102:	07a1                	addi	a5,a5,8
    80005104:	fed51ce3          	bne	a0,a3,800050fc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005108:	557d                	li	a0,-1
}
    8000510a:	60e2                	ld	ra,24(sp)
    8000510c:	6442                	ld	s0,16(sp)
    8000510e:	64a2                	ld	s1,8(sp)
    80005110:	6105                	addi	sp,sp,32
    80005112:	8082                	ret
      p->ofile[fd] = f;
    80005114:	01a50793          	addi	a5,a0,26
    80005118:	078e                	slli	a5,a5,0x3
    8000511a:	963e                	add	a2,a2,a5
    8000511c:	e204                	sd	s1,0(a2)
      return fd;
    8000511e:	b7f5                	j	8000510a <fdalloc+0x2c>

0000000080005120 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005120:	715d                	addi	sp,sp,-80
    80005122:	e486                	sd	ra,72(sp)
    80005124:	e0a2                	sd	s0,64(sp)
    80005126:	fc26                	sd	s1,56(sp)
    80005128:	f84a                	sd	s2,48(sp)
    8000512a:	f44e                	sd	s3,40(sp)
    8000512c:	f052                	sd	s4,32(sp)
    8000512e:	ec56                	sd	s5,24(sp)
    80005130:	e85a                	sd	s6,16(sp)
    80005132:	0880                	addi	s0,sp,80
    80005134:	8b2e                	mv	s6,a1
    80005136:	89b2                	mv	s3,a2
    80005138:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000513a:	fb040593          	addi	a1,s0,-80
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	e3c080e7          	jalr	-452(ra) # 80003f7a <nameiparent>
    80005146:	84aa                	mv	s1,a0
    80005148:	14050f63          	beqz	a0,800052a6 <create+0x186>
    return 0;

  ilock(dp);
    8000514c:	ffffe097          	auipc	ra,0xffffe
    80005150:	66a080e7          	jalr	1642(ra) # 800037b6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005154:	4601                	li	a2,0
    80005156:	fb040593          	addi	a1,s0,-80
    8000515a:	8526                	mv	a0,s1
    8000515c:	fffff097          	auipc	ra,0xfffff
    80005160:	b3e080e7          	jalr	-1218(ra) # 80003c9a <dirlookup>
    80005164:	8aaa                	mv	s5,a0
    80005166:	c931                	beqz	a0,800051ba <create+0x9a>
    iunlockput(dp);
    80005168:	8526                	mv	a0,s1
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	8ae080e7          	jalr	-1874(ra) # 80003a18 <iunlockput>
    ilock(ip);
    80005172:	8556                	mv	a0,s5
    80005174:	ffffe097          	auipc	ra,0xffffe
    80005178:	642080e7          	jalr	1602(ra) # 800037b6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000517c:	000b059b          	sext.w	a1,s6
    80005180:	4789                	li	a5,2
    80005182:	02f59563          	bne	a1,a5,800051ac <create+0x8c>
    80005186:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd997c>
    8000518a:	37f9                	addiw	a5,a5,-2
    8000518c:	17c2                	slli	a5,a5,0x30
    8000518e:	93c1                	srli	a5,a5,0x30
    80005190:	4705                	li	a4,1
    80005192:	00f76d63          	bltu	a4,a5,800051ac <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005196:	8556                	mv	a0,s5
    80005198:	60a6                	ld	ra,72(sp)
    8000519a:	6406                	ld	s0,64(sp)
    8000519c:	74e2                	ld	s1,56(sp)
    8000519e:	7942                	ld	s2,48(sp)
    800051a0:	79a2                	ld	s3,40(sp)
    800051a2:	7a02                	ld	s4,32(sp)
    800051a4:	6ae2                	ld	s5,24(sp)
    800051a6:	6b42                	ld	s6,16(sp)
    800051a8:	6161                	addi	sp,sp,80
    800051aa:	8082                	ret
    iunlockput(ip);
    800051ac:	8556                	mv	a0,s5
    800051ae:	fffff097          	auipc	ra,0xfffff
    800051b2:	86a080e7          	jalr	-1942(ra) # 80003a18 <iunlockput>
    return 0;
    800051b6:	4a81                	li	s5,0
    800051b8:	bff9                	j	80005196 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051ba:	85da                	mv	a1,s6
    800051bc:	4088                	lw	a0,0(s1)
    800051be:	ffffe097          	auipc	ra,0xffffe
    800051c2:	45c080e7          	jalr	1116(ra) # 8000361a <ialloc>
    800051c6:	8a2a                	mv	s4,a0
    800051c8:	c539                	beqz	a0,80005216 <create+0xf6>
  ilock(ip);
    800051ca:	ffffe097          	auipc	ra,0xffffe
    800051ce:	5ec080e7          	jalr	1516(ra) # 800037b6 <ilock>
  ip->major = major;
    800051d2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051d6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051da:	4905                	li	s2,1
    800051dc:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800051e0:	8552                	mv	a0,s4
    800051e2:	ffffe097          	auipc	ra,0xffffe
    800051e6:	50a080e7          	jalr	1290(ra) # 800036ec <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051ea:	000b059b          	sext.w	a1,s6
    800051ee:	03258b63          	beq	a1,s2,80005224 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800051f2:	004a2603          	lw	a2,4(s4)
    800051f6:	fb040593          	addi	a1,s0,-80
    800051fa:	8526                	mv	a0,s1
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	cae080e7          	jalr	-850(ra) # 80003eaa <dirlink>
    80005204:	06054f63          	bltz	a0,80005282 <create+0x162>
  iunlockput(dp);
    80005208:	8526                	mv	a0,s1
    8000520a:	fffff097          	auipc	ra,0xfffff
    8000520e:	80e080e7          	jalr	-2034(ra) # 80003a18 <iunlockput>
  return ip;
    80005212:	8ad2                	mv	s5,s4
    80005214:	b749                	j	80005196 <create+0x76>
    iunlockput(dp);
    80005216:	8526                	mv	a0,s1
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	800080e7          	jalr	-2048(ra) # 80003a18 <iunlockput>
    return 0;
    80005220:	8ad2                	mv	s5,s4
    80005222:	bf95                	j	80005196 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005224:	004a2603          	lw	a2,4(s4)
    80005228:	00003597          	auipc	a1,0x3
    8000522c:	4d058593          	addi	a1,a1,1232 # 800086f8 <syscalls+0x2b0>
    80005230:	8552                	mv	a0,s4
    80005232:	fffff097          	auipc	ra,0xfffff
    80005236:	c78080e7          	jalr	-904(ra) # 80003eaa <dirlink>
    8000523a:	04054463          	bltz	a0,80005282 <create+0x162>
    8000523e:	40d0                	lw	a2,4(s1)
    80005240:	00003597          	auipc	a1,0x3
    80005244:	4c058593          	addi	a1,a1,1216 # 80008700 <syscalls+0x2b8>
    80005248:	8552                	mv	a0,s4
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	c60080e7          	jalr	-928(ra) # 80003eaa <dirlink>
    80005252:	02054863          	bltz	a0,80005282 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005256:	004a2603          	lw	a2,4(s4)
    8000525a:	fb040593          	addi	a1,s0,-80
    8000525e:	8526                	mv	a0,s1
    80005260:	fffff097          	auipc	ra,0xfffff
    80005264:	c4a080e7          	jalr	-950(ra) # 80003eaa <dirlink>
    80005268:	00054d63          	bltz	a0,80005282 <create+0x162>
    dp->nlink++;  // for ".."
    8000526c:	04a4d783          	lhu	a5,74(s1)
    80005270:	2785                	addiw	a5,a5,1
    80005272:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005276:	8526                	mv	a0,s1
    80005278:	ffffe097          	auipc	ra,0xffffe
    8000527c:	474080e7          	jalr	1140(ra) # 800036ec <iupdate>
    80005280:	b761                	j	80005208 <create+0xe8>
  ip->nlink = 0;
    80005282:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005286:	8552                	mv	a0,s4
    80005288:	ffffe097          	auipc	ra,0xffffe
    8000528c:	464080e7          	jalr	1124(ra) # 800036ec <iupdate>
  iunlockput(ip);
    80005290:	8552                	mv	a0,s4
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	786080e7          	jalr	1926(ra) # 80003a18 <iunlockput>
  iunlockput(dp);
    8000529a:	8526                	mv	a0,s1
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	77c080e7          	jalr	1916(ra) # 80003a18 <iunlockput>
  return 0;
    800052a4:	bdcd                	j	80005196 <create+0x76>
    return 0;
    800052a6:	8aaa                	mv	s5,a0
    800052a8:	b5fd                	j	80005196 <create+0x76>

00000000800052aa <sys_dup>:
{
    800052aa:	7179                	addi	sp,sp,-48
    800052ac:	f406                	sd	ra,40(sp)
    800052ae:	f022                	sd	s0,32(sp)
    800052b0:	ec26                	sd	s1,24(sp)
    800052b2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052b4:	fd840613          	addi	a2,s0,-40
    800052b8:	4581                	li	a1,0
    800052ba:	4501                	li	a0,0
    800052bc:	00000097          	auipc	ra,0x0
    800052c0:	dc2080e7          	jalr	-574(ra) # 8000507e <argfd>
    return -1;
    800052c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052c6:	02054363          	bltz	a0,800052ec <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052ca:	fd843503          	ld	a0,-40(s0)
    800052ce:	00000097          	auipc	ra,0x0
    800052d2:	e10080e7          	jalr	-496(ra) # 800050de <fdalloc>
    800052d6:	84aa                	mv	s1,a0
    return -1;
    800052d8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052da:	00054963          	bltz	a0,800052ec <sys_dup+0x42>
  filedup(f);
    800052de:	fd843503          	ld	a0,-40(s0)
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	310080e7          	jalr	784(ra) # 800045f2 <filedup>
  return fd;
    800052ea:	87a6                	mv	a5,s1
}
    800052ec:	853e                	mv	a0,a5
    800052ee:	70a2                	ld	ra,40(sp)
    800052f0:	7402                	ld	s0,32(sp)
    800052f2:	64e2                	ld	s1,24(sp)
    800052f4:	6145                	addi	sp,sp,48
    800052f6:	8082                	ret

00000000800052f8 <sys_read>:
{
    800052f8:	7179                	addi	sp,sp,-48
    800052fa:	f406                	sd	ra,40(sp)
    800052fc:	f022                	sd	s0,32(sp)
    800052fe:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005300:	fd840593          	addi	a1,s0,-40
    80005304:	4505                	li	a0,1
    80005306:	ffffe097          	auipc	ra,0xffffe
    8000530a:	92c080e7          	jalr	-1748(ra) # 80002c32 <argaddr>
  argint(2, &n);
    8000530e:	fe440593          	addi	a1,s0,-28
    80005312:	4509                	li	a0,2
    80005314:	ffffe097          	auipc	ra,0xffffe
    80005318:	8fe080e7          	jalr	-1794(ra) # 80002c12 <argint>
  if(argfd(0, 0, &f) < 0)
    8000531c:	fe840613          	addi	a2,s0,-24
    80005320:	4581                	li	a1,0
    80005322:	4501                	li	a0,0
    80005324:	00000097          	auipc	ra,0x0
    80005328:	d5a080e7          	jalr	-678(ra) # 8000507e <argfd>
    8000532c:	87aa                	mv	a5,a0
    return -1;
    8000532e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005330:	0007cc63          	bltz	a5,80005348 <sys_read+0x50>
  return fileread(f, p, n);
    80005334:	fe442603          	lw	a2,-28(s0)
    80005338:	fd843583          	ld	a1,-40(s0)
    8000533c:	fe843503          	ld	a0,-24(s0)
    80005340:	fffff097          	auipc	ra,0xfffff
    80005344:	43e080e7          	jalr	1086(ra) # 8000477e <fileread>
}
    80005348:	70a2                	ld	ra,40(sp)
    8000534a:	7402                	ld	s0,32(sp)
    8000534c:	6145                	addi	sp,sp,48
    8000534e:	8082                	ret

0000000080005350 <sys_write>:
{
    80005350:	7179                	addi	sp,sp,-48
    80005352:	f406                	sd	ra,40(sp)
    80005354:	f022                	sd	s0,32(sp)
    80005356:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005358:	fd840593          	addi	a1,s0,-40
    8000535c:	4505                	li	a0,1
    8000535e:	ffffe097          	auipc	ra,0xffffe
    80005362:	8d4080e7          	jalr	-1836(ra) # 80002c32 <argaddr>
  argint(2, &n);
    80005366:	fe440593          	addi	a1,s0,-28
    8000536a:	4509                	li	a0,2
    8000536c:	ffffe097          	auipc	ra,0xffffe
    80005370:	8a6080e7          	jalr	-1882(ra) # 80002c12 <argint>
  if(argfd(0, 0, &f) < 0)
    80005374:	fe840613          	addi	a2,s0,-24
    80005378:	4581                	li	a1,0
    8000537a:	4501                	li	a0,0
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	d02080e7          	jalr	-766(ra) # 8000507e <argfd>
    80005384:	87aa                	mv	a5,a0
    return -1;
    80005386:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005388:	0007cc63          	bltz	a5,800053a0 <sys_write+0x50>
  return filewrite(f, p, n);
    8000538c:	fe442603          	lw	a2,-28(s0)
    80005390:	fd843583          	ld	a1,-40(s0)
    80005394:	fe843503          	ld	a0,-24(s0)
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	4a8080e7          	jalr	1192(ra) # 80004840 <filewrite>
}
    800053a0:	70a2                	ld	ra,40(sp)
    800053a2:	7402                	ld	s0,32(sp)
    800053a4:	6145                	addi	sp,sp,48
    800053a6:	8082                	ret

00000000800053a8 <sys_close>:
{
    800053a8:	1101                	addi	sp,sp,-32
    800053aa:	ec06                	sd	ra,24(sp)
    800053ac:	e822                	sd	s0,16(sp)
    800053ae:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053b0:	fe040613          	addi	a2,s0,-32
    800053b4:	fec40593          	addi	a1,s0,-20
    800053b8:	4501                	li	a0,0
    800053ba:	00000097          	auipc	ra,0x0
    800053be:	cc4080e7          	jalr	-828(ra) # 8000507e <argfd>
    return -1;
    800053c2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053c4:	02054463          	bltz	a0,800053ec <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053c8:	ffffc097          	auipc	ra,0xffffc
    800053cc:	61c080e7          	jalr	1564(ra) # 800019e4 <myproc>
    800053d0:	fec42783          	lw	a5,-20(s0)
    800053d4:	07e9                	addi	a5,a5,26
    800053d6:	078e                	slli	a5,a5,0x3
    800053d8:	97aa                	add	a5,a5,a0
    800053da:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053de:	fe043503          	ld	a0,-32(s0)
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	262080e7          	jalr	610(ra) # 80004644 <fileclose>
  return 0;
    800053ea:	4781                	li	a5,0
}
    800053ec:	853e                	mv	a0,a5
    800053ee:	60e2                	ld	ra,24(sp)
    800053f0:	6442                	ld	s0,16(sp)
    800053f2:	6105                	addi	sp,sp,32
    800053f4:	8082                	ret

00000000800053f6 <sys_fstat>:
{
    800053f6:	1101                	addi	sp,sp,-32
    800053f8:	ec06                	sd	ra,24(sp)
    800053fa:	e822                	sd	s0,16(sp)
    800053fc:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053fe:	fe040593          	addi	a1,s0,-32
    80005402:	4505                	li	a0,1
    80005404:	ffffe097          	auipc	ra,0xffffe
    80005408:	82e080e7          	jalr	-2002(ra) # 80002c32 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000540c:	fe840613          	addi	a2,s0,-24
    80005410:	4581                	li	a1,0
    80005412:	4501                	li	a0,0
    80005414:	00000097          	auipc	ra,0x0
    80005418:	c6a080e7          	jalr	-918(ra) # 8000507e <argfd>
    8000541c:	87aa                	mv	a5,a0
    return -1;
    8000541e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005420:	0007ca63          	bltz	a5,80005434 <sys_fstat+0x3e>
  return filestat(f, st);
    80005424:	fe043583          	ld	a1,-32(s0)
    80005428:	fe843503          	ld	a0,-24(s0)
    8000542c:	fffff097          	auipc	ra,0xfffff
    80005430:	2e0080e7          	jalr	736(ra) # 8000470c <filestat>
}
    80005434:	60e2                	ld	ra,24(sp)
    80005436:	6442                	ld	s0,16(sp)
    80005438:	6105                	addi	sp,sp,32
    8000543a:	8082                	ret

000000008000543c <sys_link>:
{
    8000543c:	7169                	addi	sp,sp,-304
    8000543e:	f606                	sd	ra,296(sp)
    80005440:	f222                	sd	s0,288(sp)
    80005442:	ee26                	sd	s1,280(sp)
    80005444:	ea4a                	sd	s2,272(sp)
    80005446:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005448:	08000613          	li	a2,128
    8000544c:	ed040593          	addi	a1,s0,-304
    80005450:	4501                	li	a0,0
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	800080e7          	jalr	-2048(ra) # 80002c52 <argstr>
    return -1;
    8000545a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000545c:	10054e63          	bltz	a0,80005578 <sys_link+0x13c>
    80005460:	08000613          	li	a2,128
    80005464:	f5040593          	addi	a1,s0,-176
    80005468:	4505                	li	a0,1
    8000546a:	ffffd097          	auipc	ra,0xffffd
    8000546e:	7e8080e7          	jalr	2024(ra) # 80002c52 <argstr>
    return -1;
    80005472:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005474:	10054263          	bltz	a0,80005578 <sys_link+0x13c>
  begin_op();
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	d00080e7          	jalr	-768(ra) # 80004178 <begin_op>
  if((ip = namei(old)) == 0){
    80005480:	ed040513          	addi	a0,s0,-304
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	ad8080e7          	jalr	-1320(ra) # 80003f5c <namei>
    8000548c:	84aa                	mv	s1,a0
    8000548e:	c551                	beqz	a0,8000551a <sys_link+0xde>
  ilock(ip);
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	326080e7          	jalr	806(ra) # 800037b6 <ilock>
  if(ip->type == T_DIR){
    80005498:	04449703          	lh	a4,68(s1)
    8000549c:	4785                	li	a5,1
    8000549e:	08f70463          	beq	a4,a5,80005526 <sys_link+0xea>
  ip->nlink++;
    800054a2:	04a4d783          	lhu	a5,74(s1)
    800054a6:	2785                	addiw	a5,a5,1
    800054a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ac:	8526                	mv	a0,s1
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	23e080e7          	jalr	574(ra) # 800036ec <iupdate>
  iunlock(ip);
    800054b6:	8526                	mv	a0,s1
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	3c0080e7          	jalr	960(ra) # 80003878 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054c0:	fd040593          	addi	a1,s0,-48
    800054c4:	f5040513          	addi	a0,s0,-176
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	ab2080e7          	jalr	-1358(ra) # 80003f7a <nameiparent>
    800054d0:	892a                	mv	s2,a0
    800054d2:	c935                	beqz	a0,80005546 <sys_link+0x10a>
  ilock(dp);
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	2e2080e7          	jalr	738(ra) # 800037b6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054dc:	00092703          	lw	a4,0(s2)
    800054e0:	409c                	lw	a5,0(s1)
    800054e2:	04f71d63          	bne	a4,a5,8000553c <sys_link+0x100>
    800054e6:	40d0                	lw	a2,4(s1)
    800054e8:	fd040593          	addi	a1,s0,-48
    800054ec:	854a                	mv	a0,s2
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	9bc080e7          	jalr	-1604(ra) # 80003eaa <dirlink>
    800054f6:	04054363          	bltz	a0,8000553c <sys_link+0x100>
  iunlockput(dp);
    800054fa:	854a                	mv	a0,s2
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	51c080e7          	jalr	1308(ra) # 80003a18 <iunlockput>
  iput(ip);
    80005504:	8526                	mv	a0,s1
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	46a080e7          	jalr	1130(ra) # 80003970 <iput>
  end_op();
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	cea080e7          	jalr	-790(ra) # 800041f8 <end_op>
  return 0;
    80005516:	4781                	li	a5,0
    80005518:	a085                	j	80005578 <sys_link+0x13c>
    end_op();
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	cde080e7          	jalr	-802(ra) # 800041f8 <end_op>
    return -1;
    80005522:	57fd                	li	a5,-1
    80005524:	a891                	j	80005578 <sys_link+0x13c>
    iunlockput(ip);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	4f0080e7          	jalr	1264(ra) # 80003a18 <iunlockput>
    end_op();
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	cc8080e7          	jalr	-824(ra) # 800041f8 <end_op>
    return -1;
    80005538:	57fd                	li	a5,-1
    8000553a:	a83d                	j	80005578 <sys_link+0x13c>
    iunlockput(dp);
    8000553c:	854a                	mv	a0,s2
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	4da080e7          	jalr	1242(ra) # 80003a18 <iunlockput>
  ilock(ip);
    80005546:	8526                	mv	a0,s1
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	26e080e7          	jalr	622(ra) # 800037b6 <ilock>
  ip->nlink--;
    80005550:	04a4d783          	lhu	a5,74(s1)
    80005554:	37fd                	addiw	a5,a5,-1
    80005556:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000555a:	8526                	mv	a0,s1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	190080e7          	jalr	400(ra) # 800036ec <iupdate>
  iunlockput(ip);
    80005564:	8526                	mv	a0,s1
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	4b2080e7          	jalr	1202(ra) # 80003a18 <iunlockput>
  end_op();
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	c8a080e7          	jalr	-886(ra) # 800041f8 <end_op>
  return -1;
    80005576:	57fd                	li	a5,-1
}
    80005578:	853e                	mv	a0,a5
    8000557a:	70b2                	ld	ra,296(sp)
    8000557c:	7412                	ld	s0,288(sp)
    8000557e:	64f2                	ld	s1,280(sp)
    80005580:	6952                	ld	s2,272(sp)
    80005582:	6155                	addi	sp,sp,304
    80005584:	8082                	ret

0000000080005586 <sys_unlink>:
{
    80005586:	7151                	addi	sp,sp,-240
    80005588:	f586                	sd	ra,232(sp)
    8000558a:	f1a2                	sd	s0,224(sp)
    8000558c:	eda6                	sd	s1,216(sp)
    8000558e:	e9ca                	sd	s2,208(sp)
    80005590:	e5ce                	sd	s3,200(sp)
    80005592:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005594:	08000613          	li	a2,128
    80005598:	f3040593          	addi	a1,s0,-208
    8000559c:	4501                	li	a0,0
    8000559e:	ffffd097          	auipc	ra,0xffffd
    800055a2:	6b4080e7          	jalr	1716(ra) # 80002c52 <argstr>
    800055a6:	18054163          	bltz	a0,80005728 <sys_unlink+0x1a2>
  begin_op();
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	bce080e7          	jalr	-1074(ra) # 80004178 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055b2:	fb040593          	addi	a1,s0,-80
    800055b6:	f3040513          	addi	a0,s0,-208
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	9c0080e7          	jalr	-1600(ra) # 80003f7a <nameiparent>
    800055c2:	84aa                	mv	s1,a0
    800055c4:	c979                	beqz	a0,8000569a <sys_unlink+0x114>
  ilock(dp);
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	1f0080e7          	jalr	496(ra) # 800037b6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055ce:	00003597          	auipc	a1,0x3
    800055d2:	12a58593          	addi	a1,a1,298 # 800086f8 <syscalls+0x2b0>
    800055d6:	fb040513          	addi	a0,s0,-80
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	6a6080e7          	jalr	1702(ra) # 80003c80 <namecmp>
    800055e2:	14050a63          	beqz	a0,80005736 <sys_unlink+0x1b0>
    800055e6:	00003597          	auipc	a1,0x3
    800055ea:	11a58593          	addi	a1,a1,282 # 80008700 <syscalls+0x2b8>
    800055ee:	fb040513          	addi	a0,s0,-80
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	68e080e7          	jalr	1678(ra) # 80003c80 <namecmp>
    800055fa:	12050e63          	beqz	a0,80005736 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055fe:	f2c40613          	addi	a2,s0,-212
    80005602:	fb040593          	addi	a1,s0,-80
    80005606:	8526                	mv	a0,s1
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	692080e7          	jalr	1682(ra) # 80003c9a <dirlookup>
    80005610:	892a                	mv	s2,a0
    80005612:	12050263          	beqz	a0,80005736 <sys_unlink+0x1b0>
  ilock(ip);
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	1a0080e7          	jalr	416(ra) # 800037b6 <ilock>
  if(ip->nlink < 1)
    8000561e:	04a91783          	lh	a5,74(s2)
    80005622:	08f05263          	blez	a5,800056a6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005626:	04491703          	lh	a4,68(s2)
    8000562a:	4785                	li	a5,1
    8000562c:	08f70563          	beq	a4,a5,800056b6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005630:	4641                	li	a2,16
    80005632:	4581                	li	a1,0
    80005634:	fc040513          	addi	a0,s0,-64
    80005638:	ffffb097          	auipc	ra,0xffffb
    8000563c:	69a080e7          	jalr	1690(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005640:	4741                	li	a4,16
    80005642:	f2c42683          	lw	a3,-212(s0)
    80005646:	fc040613          	addi	a2,s0,-64
    8000564a:	4581                	li	a1,0
    8000564c:	8526                	mv	a0,s1
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	514080e7          	jalr	1300(ra) # 80003b62 <writei>
    80005656:	47c1                	li	a5,16
    80005658:	0af51563          	bne	a0,a5,80005702 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000565c:	04491703          	lh	a4,68(s2)
    80005660:	4785                	li	a5,1
    80005662:	0af70863          	beq	a4,a5,80005712 <sys_unlink+0x18c>
  iunlockput(dp);
    80005666:	8526                	mv	a0,s1
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	3b0080e7          	jalr	944(ra) # 80003a18 <iunlockput>
  ip->nlink--;
    80005670:	04a95783          	lhu	a5,74(s2)
    80005674:	37fd                	addiw	a5,a5,-1
    80005676:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000567a:	854a                	mv	a0,s2
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	070080e7          	jalr	112(ra) # 800036ec <iupdate>
  iunlockput(ip);
    80005684:	854a                	mv	a0,s2
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	392080e7          	jalr	914(ra) # 80003a18 <iunlockput>
  end_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	b6a080e7          	jalr	-1174(ra) # 800041f8 <end_op>
  return 0;
    80005696:	4501                	li	a0,0
    80005698:	a84d                	j	8000574a <sys_unlink+0x1c4>
    end_op();
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	b5e080e7          	jalr	-1186(ra) # 800041f8 <end_op>
    return -1;
    800056a2:	557d                	li	a0,-1
    800056a4:	a05d                	j	8000574a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056a6:	00003517          	auipc	a0,0x3
    800056aa:	06250513          	addi	a0,a0,98 # 80008708 <syscalls+0x2c0>
    800056ae:	ffffb097          	auipc	ra,0xffffb
    800056b2:	e90080e7          	jalr	-368(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b6:	04c92703          	lw	a4,76(s2)
    800056ba:	02000793          	li	a5,32
    800056be:	f6e7f9e3          	bgeu	a5,a4,80005630 <sys_unlink+0xaa>
    800056c2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056c6:	4741                	li	a4,16
    800056c8:	86ce                	mv	a3,s3
    800056ca:	f1840613          	addi	a2,s0,-232
    800056ce:	4581                	li	a1,0
    800056d0:	854a                	mv	a0,s2
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	398080e7          	jalr	920(ra) # 80003a6a <readi>
    800056da:	47c1                	li	a5,16
    800056dc:	00f51b63          	bne	a0,a5,800056f2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056e0:	f1845783          	lhu	a5,-232(s0)
    800056e4:	e7a1                	bnez	a5,8000572c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056e6:	29c1                	addiw	s3,s3,16
    800056e8:	04c92783          	lw	a5,76(s2)
    800056ec:	fcf9ede3          	bltu	s3,a5,800056c6 <sys_unlink+0x140>
    800056f0:	b781                	j	80005630 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056f2:	00003517          	auipc	a0,0x3
    800056f6:	02e50513          	addi	a0,a0,46 # 80008720 <syscalls+0x2d8>
    800056fa:	ffffb097          	auipc	ra,0xffffb
    800056fe:	e44080e7          	jalr	-444(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005702:	00003517          	auipc	a0,0x3
    80005706:	03650513          	addi	a0,a0,54 # 80008738 <syscalls+0x2f0>
    8000570a:	ffffb097          	auipc	ra,0xffffb
    8000570e:	e34080e7          	jalr	-460(ra) # 8000053e <panic>
    dp->nlink--;
    80005712:	04a4d783          	lhu	a5,74(s1)
    80005716:	37fd                	addiw	a5,a5,-1
    80005718:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000571c:	8526                	mv	a0,s1
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	fce080e7          	jalr	-50(ra) # 800036ec <iupdate>
    80005726:	b781                	j	80005666 <sys_unlink+0xe0>
    return -1;
    80005728:	557d                	li	a0,-1
    8000572a:	a005                	j	8000574a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000572c:	854a                	mv	a0,s2
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	2ea080e7          	jalr	746(ra) # 80003a18 <iunlockput>
  iunlockput(dp);
    80005736:	8526                	mv	a0,s1
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	2e0080e7          	jalr	736(ra) # 80003a18 <iunlockput>
  end_op();
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	ab8080e7          	jalr	-1352(ra) # 800041f8 <end_op>
  return -1;
    80005748:	557d                	li	a0,-1
}
    8000574a:	70ae                	ld	ra,232(sp)
    8000574c:	740e                	ld	s0,224(sp)
    8000574e:	64ee                	ld	s1,216(sp)
    80005750:	694e                	ld	s2,208(sp)
    80005752:	69ae                	ld	s3,200(sp)
    80005754:	616d                	addi	sp,sp,240
    80005756:	8082                	ret

0000000080005758 <sys_open>:

uint64
sys_open(void)
{
    80005758:	7131                	addi	sp,sp,-192
    8000575a:	fd06                	sd	ra,184(sp)
    8000575c:	f922                	sd	s0,176(sp)
    8000575e:	f526                	sd	s1,168(sp)
    80005760:	f14a                	sd	s2,160(sp)
    80005762:	ed4e                	sd	s3,152(sp)
    80005764:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005766:	f4c40593          	addi	a1,s0,-180
    8000576a:	4505                	li	a0,1
    8000576c:	ffffd097          	auipc	ra,0xffffd
    80005770:	4a6080e7          	jalr	1190(ra) # 80002c12 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005774:	08000613          	li	a2,128
    80005778:	f5040593          	addi	a1,s0,-176
    8000577c:	4501                	li	a0,0
    8000577e:	ffffd097          	auipc	ra,0xffffd
    80005782:	4d4080e7          	jalr	1236(ra) # 80002c52 <argstr>
    80005786:	87aa                	mv	a5,a0
    return -1;
    80005788:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000578a:	0a07c963          	bltz	a5,8000583c <sys_open+0xe4>

  begin_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	9ea080e7          	jalr	-1558(ra) # 80004178 <begin_op>

  if(omode & O_CREATE){
    80005796:	f4c42783          	lw	a5,-180(s0)
    8000579a:	2007f793          	andi	a5,a5,512
    8000579e:	cfc5                	beqz	a5,80005856 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057a0:	4681                	li	a3,0
    800057a2:	4601                	li	a2,0
    800057a4:	4589                	li	a1,2
    800057a6:	f5040513          	addi	a0,s0,-176
    800057aa:	00000097          	auipc	ra,0x0
    800057ae:	976080e7          	jalr	-1674(ra) # 80005120 <create>
    800057b2:	84aa                	mv	s1,a0
    if(ip == 0){
    800057b4:	c959                	beqz	a0,8000584a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057b6:	04449703          	lh	a4,68(s1)
    800057ba:	478d                	li	a5,3
    800057bc:	00f71763          	bne	a4,a5,800057ca <sys_open+0x72>
    800057c0:	0464d703          	lhu	a4,70(s1)
    800057c4:	47a5                	li	a5,9
    800057c6:	0ce7ed63          	bltu	a5,a4,800058a0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	dbe080e7          	jalr	-578(ra) # 80004588 <filealloc>
    800057d2:	89aa                	mv	s3,a0
    800057d4:	10050363          	beqz	a0,800058da <sys_open+0x182>
    800057d8:	00000097          	auipc	ra,0x0
    800057dc:	906080e7          	jalr	-1786(ra) # 800050de <fdalloc>
    800057e0:	892a                	mv	s2,a0
    800057e2:	0e054763          	bltz	a0,800058d0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057e6:	04449703          	lh	a4,68(s1)
    800057ea:	478d                	li	a5,3
    800057ec:	0cf70563          	beq	a4,a5,800058b6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057f0:	4789                	li	a5,2
    800057f2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057f6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057fa:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057fe:	f4c42783          	lw	a5,-180(s0)
    80005802:	0017c713          	xori	a4,a5,1
    80005806:	8b05                	andi	a4,a4,1
    80005808:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000580c:	0037f713          	andi	a4,a5,3
    80005810:	00e03733          	snez	a4,a4
    80005814:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005818:	4007f793          	andi	a5,a5,1024
    8000581c:	c791                	beqz	a5,80005828 <sys_open+0xd0>
    8000581e:	04449703          	lh	a4,68(s1)
    80005822:	4789                	li	a5,2
    80005824:	0af70063          	beq	a4,a5,800058c4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005828:	8526                	mv	a0,s1
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	04e080e7          	jalr	78(ra) # 80003878 <iunlock>
  end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	9c6080e7          	jalr	-1594(ra) # 800041f8 <end_op>

  return fd;
    8000583a:	854a                	mv	a0,s2
}
    8000583c:	70ea                	ld	ra,184(sp)
    8000583e:	744a                	ld	s0,176(sp)
    80005840:	74aa                	ld	s1,168(sp)
    80005842:	790a                	ld	s2,160(sp)
    80005844:	69ea                	ld	s3,152(sp)
    80005846:	6129                	addi	sp,sp,192
    80005848:	8082                	ret
      end_op();
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	9ae080e7          	jalr	-1618(ra) # 800041f8 <end_op>
      return -1;
    80005852:	557d                	li	a0,-1
    80005854:	b7e5                	j	8000583c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005856:	f5040513          	addi	a0,s0,-176
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	702080e7          	jalr	1794(ra) # 80003f5c <namei>
    80005862:	84aa                	mv	s1,a0
    80005864:	c905                	beqz	a0,80005894 <sys_open+0x13c>
    ilock(ip);
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	f50080e7          	jalr	-176(ra) # 800037b6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000586e:	04449703          	lh	a4,68(s1)
    80005872:	4785                	li	a5,1
    80005874:	f4f711e3          	bne	a4,a5,800057b6 <sys_open+0x5e>
    80005878:	f4c42783          	lw	a5,-180(s0)
    8000587c:	d7b9                	beqz	a5,800057ca <sys_open+0x72>
      iunlockput(ip);
    8000587e:	8526                	mv	a0,s1
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	198080e7          	jalr	408(ra) # 80003a18 <iunlockput>
      end_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	970080e7          	jalr	-1680(ra) # 800041f8 <end_op>
      return -1;
    80005890:	557d                	li	a0,-1
    80005892:	b76d                	j	8000583c <sys_open+0xe4>
      end_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	964080e7          	jalr	-1692(ra) # 800041f8 <end_op>
      return -1;
    8000589c:	557d                	li	a0,-1
    8000589e:	bf79                	j	8000583c <sys_open+0xe4>
    iunlockput(ip);
    800058a0:	8526                	mv	a0,s1
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	176080e7          	jalr	374(ra) # 80003a18 <iunlockput>
    end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	94e080e7          	jalr	-1714(ra) # 800041f8 <end_op>
    return -1;
    800058b2:	557d                	li	a0,-1
    800058b4:	b761                	j	8000583c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058b6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058ba:	04649783          	lh	a5,70(s1)
    800058be:	02f99223          	sh	a5,36(s3)
    800058c2:	bf25                	j	800057fa <sys_open+0xa2>
    itrunc(ip);
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	ffe080e7          	jalr	-2(ra) # 800038c4 <itrunc>
    800058ce:	bfa9                	j	80005828 <sys_open+0xd0>
      fileclose(f);
    800058d0:	854e                	mv	a0,s3
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	d72080e7          	jalr	-654(ra) # 80004644 <fileclose>
    iunlockput(ip);
    800058da:	8526                	mv	a0,s1
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	13c080e7          	jalr	316(ra) # 80003a18 <iunlockput>
    end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	914080e7          	jalr	-1772(ra) # 800041f8 <end_op>
    return -1;
    800058ec:	557d                	li	a0,-1
    800058ee:	b7b9                	j	8000583c <sys_open+0xe4>

00000000800058f0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058f0:	7175                	addi	sp,sp,-144
    800058f2:	e506                	sd	ra,136(sp)
    800058f4:	e122                	sd	s0,128(sp)
    800058f6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	880080e7          	jalr	-1920(ra) # 80004178 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005900:	08000613          	li	a2,128
    80005904:	f7040593          	addi	a1,s0,-144
    80005908:	4501                	li	a0,0
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	348080e7          	jalr	840(ra) # 80002c52 <argstr>
    80005912:	02054963          	bltz	a0,80005944 <sys_mkdir+0x54>
    80005916:	4681                	li	a3,0
    80005918:	4601                	li	a2,0
    8000591a:	4585                	li	a1,1
    8000591c:	f7040513          	addi	a0,s0,-144
    80005920:	00000097          	auipc	ra,0x0
    80005924:	800080e7          	jalr	-2048(ra) # 80005120 <create>
    80005928:	cd11                	beqz	a0,80005944 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	0ee080e7          	jalr	238(ra) # 80003a18 <iunlockput>
  end_op();
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	8c6080e7          	jalr	-1850(ra) # 800041f8 <end_op>
  return 0;
    8000593a:	4501                	li	a0,0
}
    8000593c:	60aa                	ld	ra,136(sp)
    8000593e:	640a                	ld	s0,128(sp)
    80005940:	6149                	addi	sp,sp,144
    80005942:	8082                	ret
    end_op();
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	8b4080e7          	jalr	-1868(ra) # 800041f8 <end_op>
    return -1;
    8000594c:	557d                	li	a0,-1
    8000594e:	b7fd                	j	8000593c <sys_mkdir+0x4c>

0000000080005950 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005950:	7135                	addi	sp,sp,-160
    80005952:	ed06                	sd	ra,152(sp)
    80005954:	e922                	sd	s0,144(sp)
    80005956:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	820080e7          	jalr	-2016(ra) # 80004178 <begin_op>
  argint(1, &major);
    80005960:	f6c40593          	addi	a1,s0,-148
    80005964:	4505                	li	a0,1
    80005966:	ffffd097          	auipc	ra,0xffffd
    8000596a:	2ac080e7          	jalr	684(ra) # 80002c12 <argint>
  argint(2, &minor);
    8000596e:	f6840593          	addi	a1,s0,-152
    80005972:	4509                	li	a0,2
    80005974:	ffffd097          	auipc	ra,0xffffd
    80005978:	29e080e7          	jalr	670(ra) # 80002c12 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000597c:	08000613          	li	a2,128
    80005980:	f7040593          	addi	a1,s0,-144
    80005984:	4501                	li	a0,0
    80005986:	ffffd097          	auipc	ra,0xffffd
    8000598a:	2cc080e7          	jalr	716(ra) # 80002c52 <argstr>
    8000598e:	02054b63          	bltz	a0,800059c4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005992:	f6841683          	lh	a3,-152(s0)
    80005996:	f6c41603          	lh	a2,-148(s0)
    8000599a:	458d                	li	a1,3
    8000599c:	f7040513          	addi	a0,s0,-144
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	780080e7          	jalr	1920(ra) # 80005120 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059a8:	cd11                	beqz	a0,800059c4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	06e080e7          	jalr	110(ra) # 80003a18 <iunlockput>
  end_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	846080e7          	jalr	-1978(ra) # 800041f8 <end_op>
  return 0;
    800059ba:	4501                	li	a0,0
}
    800059bc:	60ea                	ld	ra,152(sp)
    800059be:	644a                	ld	s0,144(sp)
    800059c0:	610d                	addi	sp,sp,160
    800059c2:	8082                	ret
    end_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	834080e7          	jalr	-1996(ra) # 800041f8 <end_op>
    return -1;
    800059cc:	557d                	li	a0,-1
    800059ce:	b7fd                	j	800059bc <sys_mknod+0x6c>

00000000800059d0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059d0:	7135                	addi	sp,sp,-160
    800059d2:	ed06                	sd	ra,152(sp)
    800059d4:	e922                	sd	s0,144(sp)
    800059d6:	e526                	sd	s1,136(sp)
    800059d8:	e14a                	sd	s2,128(sp)
    800059da:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059dc:	ffffc097          	auipc	ra,0xffffc
    800059e0:	008080e7          	jalr	8(ra) # 800019e4 <myproc>
    800059e4:	892a                	mv	s2,a0
  
  begin_op();
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	792080e7          	jalr	1938(ra) # 80004178 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059ee:	08000613          	li	a2,128
    800059f2:	f6040593          	addi	a1,s0,-160
    800059f6:	4501                	li	a0,0
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	25a080e7          	jalr	602(ra) # 80002c52 <argstr>
    80005a00:	04054b63          	bltz	a0,80005a56 <sys_chdir+0x86>
    80005a04:	f6040513          	addi	a0,s0,-160
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	554080e7          	jalr	1364(ra) # 80003f5c <namei>
    80005a10:	84aa                	mv	s1,a0
    80005a12:	c131                	beqz	a0,80005a56 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	da2080e7          	jalr	-606(ra) # 800037b6 <ilock>
  if(ip->type != T_DIR){
    80005a1c:	04449703          	lh	a4,68(s1)
    80005a20:	4785                	li	a5,1
    80005a22:	04f71063          	bne	a4,a5,80005a62 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a26:	8526                	mv	a0,s1
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	e50080e7          	jalr	-432(ra) # 80003878 <iunlock>
  iput(p->cwd);
    80005a30:	15093503          	ld	a0,336(s2)
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	f3c080e7          	jalr	-196(ra) # 80003970 <iput>
  end_op();
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	7bc080e7          	jalr	1980(ra) # 800041f8 <end_op>
  p->cwd = ip;
    80005a44:	14993823          	sd	s1,336(s2)
  return 0;
    80005a48:	4501                	li	a0,0
}
    80005a4a:	60ea                	ld	ra,152(sp)
    80005a4c:	644a                	ld	s0,144(sp)
    80005a4e:	64aa                	ld	s1,136(sp)
    80005a50:	690a                	ld	s2,128(sp)
    80005a52:	610d                	addi	sp,sp,160
    80005a54:	8082                	ret
    end_op();
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	7a2080e7          	jalr	1954(ra) # 800041f8 <end_op>
    return -1;
    80005a5e:	557d                	li	a0,-1
    80005a60:	b7ed                	j	80005a4a <sys_chdir+0x7a>
    iunlockput(ip);
    80005a62:	8526                	mv	a0,s1
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	fb4080e7          	jalr	-76(ra) # 80003a18 <iunlockput>
    end_op();
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	78c080e7          	jalr	1932(ra) # 800041f8 <end_op>
    return -1;
    80005a74:	557d                	li	a0,-1
    80005a76:	bfd1                	j	80005a4a <sys_chdir+0x7a>

0000000080005a78 <sys_exec>:

uint64
sys_exec(void)
{
    80005a78:	7145                	addi	sp,sp,-464
    80005a7a:	e786                	sd	ra,456(sp)
    80005a7c:	e3a2                	sd	s0,448(sp)
    80005a7e:	ff26                	sd	s1,440(sp)
    80005a80:	fb4a                	sd	s2,432(sp)
    80005a82:	f74e                	sd	s3,424(sp)
    80005a84:	f352                	sd	s4,416(sp)
    80005a86:	ef56                	sd	s5,408(sp)
    80005a88:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a8a:	e3840593          	addi	a1,s0,-456
    80005a8e:	4505                	li	a0,1
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	1a2080e7          	jalr	418(ra) # 80002c32 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a98:	08000613          	li	a2,128
    80005a9c:	f4040593          	addi	a1,s0,-192
    80005aa0:	4501                	li	a0,0
    80005aa2:	ffffd097          	auipc	ra,0xffffd
    80005aa6:	1b0080e7          	jalr	432(ra) # 80002c52 <argstr>
    80005aaa:	87aa                	mv	a5,a0
    return -1;
    80005aac:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005aae:	0c07c263          	bltz	a5,80005b72 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ab2:	10000613          	li	a2,256
    80005ab6:	4581                	li	a1,0
    80005ab8:	e4040513          	addi	a0,s0,-448
    80005abc:	ffffb097          	auipc	ra,0xffffb
    80005ac0:	216080e7          	jalr	534(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ac4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ac8:	89a6                	mv	s3,s1
    80005aca:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005acc:	02000a13          	li	s4,32
    80005ad0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ad4:	00391793          	slli	a5,s2,0x3
    80005ad8:	e3040593          	addi	a1,s0,-464
    80005adc:	e3843503          	ld	a0,-456(s0)
    80005ae0:	953e                	add	a0,a0,a5
    80005ae2:	ffffd097          	auipc	ra,0xffffd
    80005ae6:	092080e7          	jalr	146(ra) # 80002b74 <fetchaddr>
    80005aea:	02054a63          	bltz	a0,80005b1e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005aee:	e3043783          	ld	a5,-464(s0)
    80005af2:	c3b9                	beqz	a5,80005b38 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005af4:	ffffb097          	auipc	ra,0xffffb
    80005af8:	ff2080e7          	jalr	-14(ra) # 80000ae6 <kalloc>
    80005afc:	85aa                	mv	a1,a0
    80005afe:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b02:	cd11                	beqz	a0,80005b1e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b04:	6605                	lui	a2,0x1
    80005b06:	e3043503          	ld	a0,-464(s0)
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	0bc080e7          	jalr	188(ra) # 80002bc6 <fetchstr>
    80005b12:	00054663          	bltz	a0,80005b1e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b16:	0905                	addi	s2,s2,1
    80005b18:	09a1                	addi	s3,s3,8
    80005b1a:	fb491be3          	bne	s2,s4,80005ad0 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b1e:	10048913          	addi	s2,s1,256
    80005b22:	6088                	ld	a0,0(s1)
    80005b24:	c531                	beqz	a0,80005b70 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b26:	ffffb097          	auipc	ra,0xffffb
    80005b2a:	ec4080e7          	jalr	-316(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2e:	04a1                	addi	s1,s1,8
    80005b30:	ff2499e3          	bne	s1,s2,80005b22 <sys_exec+0xaa>
  return -1;
    80005b34:	557d                	li	a0,-1
    80005b36:	a835                	j	80005b72 <sys_exec+0xfa>
      argv[i] = 0;
    80005b38:	0a8e                	slli	s5,s5,0x3
    80005b3a:	fc040793          	addi	a5,s0,-64
    80005b3e:	9abe                	add	s5,s5,a5
    80005b40:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b44:	e4040593          	addi	a1,s0,-448
    80005b48:	f4040513          	addi	a0,s0,-192
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	172080e7          	jalr	370(ra) # 80004cbe <exec>
    80005b54:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b56:	10048993          	addi	s3,s1,256
    80005b5a:	6088                	ld	a0,0(s1)
    80005b5c:	c901                	beqz	a0,80005b6c <sys_exec+0xf4>
    kfree(argv[i]);
    80005b5e:	ffffb097          	auipc	ra,0xffffb
    80005b62:	e8c080e7          	jalr	-372(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b66:	04a1                	addi	s1,s1,8
    80005b68:	ff3499e3          	bne	s1,s3,80005b5a <sys_exec+0xe2>
  return ret;
    80005b6c:	854a                	mv	a0,s2
    80005b6e:	a011                	j	80005b72 <sys_exec+0xfa>
  return -1;
    80005b70:	557d                	li	a0,-1
}
    80005b72:	60be                	ld	ra,456(sp)
    80005b74:	641e                	ld	s0,448(sp)
    80005b76:	74fa                	ld	s1,440(sp)
    80005b78:	795a                	ld	s2,432(sp)
    80005b7a:	79ba                	ld	s3,424(sp)
    80005b7c:	7a1a                	ld	s4,416(sp)
    80005b7e:	6afa                	ld	s5,408(sp)
    80005b80:	6179                	addi	sp,sp,464
    80005b82:	8082                	ret

0000000080005b84 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b84:	7139                	addi	sp,sp,-64
    80005b86:	fc06                	sd	ra,56(sp)
    80005b88:	f822                	sd	s0,48(sp)
    80005b8a:	f426                	sd	s1,40(sp)
    80005b8c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b8e:	ffffc097          	auipc	ra,0xffffc
    80005b92:	e56080e7          	jalr	-426(ra) # 800019e4 <myproc>
    80005b96:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b98:	fd840593          	addi	a1,s0,-40
    80005b9c:	4501                	li	a0,0
    80005b9e:	ffffd097          	auipc	ra,0xffffd
    80005ba2:	094080e7          	jalr	148(ra) # 80002c32 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005ba6:	fc840593          	addi	a1,s0,-56
    80005baa:	fd040513          	addi	a0,s0,-48
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	dc6080e7          	jalr	-570(ra) # 80004974 <pipealloc>
    return -1;
    80005bb6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bb8:	0c054463          	bltz	a0,80005c80 <sys_pipe+0xfc>
  fd0 = -1;
    80005bbc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bc0:	fd043503          	ld	a0,-48(s0)
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	51a080e7          	jalr	1306(ra) # 800050de <fdalloc>
    80005bcc:	fca42223          	sw	a0,-60(s0)
    80005bd0:	08054b63          	bltz	a0,80005c66 <sys_pipe+0xe2>
    80005bd4:	fc843503          	ld	a0,-56(s0)
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	506080e7          	jalr	1286(ra) # 800050de <fdalloc>
    80005be0:	fca42023          	sw	a0,-64(s0)
    80005be4:	06054863          	bltz	a0,80005c54 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005be8:	4691                	li	a3,4
    80005bea:	fc440613          	addi	a2,s0,-60
    80005bee:	fd843583          	ld	a1,-40(s0)
    80005bf2:	68a8                	ld	a0,80(s1)
    80005bf4:	ffffc097          	auipc	ra,0xffffc
    80005bf8:	aac080e7          	jalr	-1364(ra) # 800016a0 <copyout>
    80005bfc:	02054063          	bltz	a0,80005c1c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c00:	4691                	li	a3,4
    80005c02:	fc040613          	addi	a2,s0,-64
    80005c06:	fd843583          	ld	a1,-40(s0)
    80005c0a:	0591                	addi	a1,a1,4
    80005c0c:	68a8                	ld	a0,80(s1)
    80005c0e:	ffffc097          	auipc	ra,0xffffc
    80005c12:	a92080e7          	jalr	-1390(ra) # 800016a0 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c16:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c18:	06055463          	bgez	a0,80005c80 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c1c:	fc442783          	lw	a5,-60(s0)
    80005c20:	07e9                	addi	a5,a5,26
    80005c22:	078e                	slli	a5,a5,0x3
    80005c24:	97a6                	add	a5,a5,s1
    80005c26:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c2a:	fc042503          	lw	a0,-64(s0)
    80005c2e:	0569                	addi	a0,a0,26
    80005c30:	050e                	slli	a0,a0,0x3
    80005c32:	94aa                	add	s1,s1,a0
    80005c34:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c38:	fd043503          	ld	a0,-48(s0)
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	a08080e7          	jalr	-1528(ra) # 80004644 <fileclose>
    fileclose(wf);
    80005c44:	fc843503          	ld	a0,-56(s0)
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	9fc080e7          	jalr	-1540(ra) # 80004644 <fileclose>
    return -1;
    80005c50:	57fd                	li	a5,-1
    80005c52:	a03d                	j	80005c80 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c54:	fc442783          	lw	a5,-60(s0)
    80005c58:	0007c763          	bltz	a5,80005c66 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c5c:	07e9                	addi	a5,a5,26
    80005c5e:	078e                	slli	a5,a5,0x3
    80005c60:	94be                	add	s1,s1,a5
    80005c62:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c66:	fd043503          	ld	a0,-48(s0)
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	9da080e7          	jalr	-1574(ra) # 80004644 <fileclose>
    fileclose(wf);
    80005c72:	fc843503          	ld	a0,-56(s0)
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	9ce080e7          	jalr	-1586(ra) # 80004644 <fileclose>
    return -1;
    80005c7e:	57fd                	li	a5,-1
}
    80005c80:	853e                	mv	a0,a5
    80005c82:	70e2                	ld	ra,56(sp)
    80005c84:	7442                	ld	s0,48(sp)
    80005c86:	74a2                	ld	s1,40(sp)
    80005c88:	6121                	addi	sp,sp,64
    80005c8a:	8082                	ret
    80005c8c:	0000                	unimp
	...

0000000080005c90 <kernelvec>:
    80005c90:	7111                	addi	sp,sp,-256
    80005c92:	e006                	sd	ra,0(sp)
    80005c94:	e40a                	sd	sp,8(sp)
    80005c96:	e80e                	sd	gp,16(sp)
    80005c98:	ec12                	sd	tp,24(sp)
    80005c9a:	f016                	sd	t0,32(sp)
    80005c9c:	f41a                	sd	t1,40(sp)
    80005c9e:	f81e                	sd	t2,48(sp)
    80005ca0:	fc22                	sd	s0,56(sp)
    80005ca2:	e0a6                	sd	s1,64(sp)
    80005ca4:	e4aa                	sd	a0,72(sp)
    80005ca6:	e8ae                	sd	a1,80(sp)
    80005ca8:	ecb2                	sd	a2,88(sp)
    80005caa:	f0b6                	sd	a3,96(sp)
    80005cac:	f4ba                	sd	a4,104(sp)
    80005cae:	f8be                	sd	a5,112(sp)
    80005cb0:	fcc2                	sd	a6,120(sp)
    80005cb2:	e146                	sd	a7,128(sp)
    80005cb4:	e54a                	sd	s2,136(sp)
    80005cb6:	e94e                	sd	s3,144(sp)
    80005cb8:	ed52                	sd	s4,152(sp)
    80005cba:	f156                	sd	s5,160(sp)
    80005cbc:	f55a                	sd	s6,168(sp)
    80005cbe:	f95e                	sd	s7,176(sp)
    80005cc0:	fd62                	sd	s8,184(sp)
    80005cc2:	e1e6                	sd	s9,192(sp)
    80005cc4:	e5ea                	sd	s10,200(sp)
    80005cc6:	e9ee                	sd	s11,208(sp)
    80005cc8:	edf2                	sd	t3,216(sp)
    80005cca:	f1f6                	sd	t4,224(sp)
    80005ccc:	f5fa                	sd	t5,232(sp)
    80005cce:	f9fe                	sd	t6,240(sp)
    80005cd0:	d71fc0ef          	jal	ra,80002a40 <kerneltrap>
    80005cd4:	6082                	ld	ra,0(sp)
    80005cd6:	6122                	ld	sp,8(sp)
    80005cd8:	61c2                	ld	gp,16(sp)
    80005cda:	7282                	ld	t0,32(sp)
    80005cdc:	7322                	ld	t1,40(sp)
    80005cde:	73c2                	ld	t2,48(sp)
    80005ce0:	7462                	ld	s0,56(sp)
    80005ce2:	6486                	ld	s1,64(sp)
    80005ce4:	6526                	ld	a0,72(sp)
    80005ce6:	65c6                	ld	a1,80(sp)
    80005ce8:	6666                	ld	a2,88(sp)
    80005cea:	7686                	ld	a3,96(sp)
    80005cec:	7726                	ld	a4,104(sp)
    80005cee:	77c6                	ld	a5,112(sp)
    80005cf0:	7866                	ld	a6,120(sp)
    80005cf2:	688a                	ld	a7,128(sp)
    80005cf4:	692a                	ld	s2,136(sp)
    80005cf6:	69ca                	ld	s3,144(sp)
    80005cf8:	6a6a                	ld	s4,152(sp)
    80005cfa:	7a8a                	ld	s5,160(sp)
    80005cfc:	7b2a                	ld	s6,168(sp)
    80005cfe:	7bca                	ld	s7,176(sp)
    80005d00:	7c6a                	ld	s8,184(sp)
    80005d02:	6c8e                	ld	s9,192(sp)
    80005d04:	6d2e                	ld	s10,200(sp)
    80005d06:	6dce                	ld	s11,208(sp)
    80005d08:	6e6e                	ld	t3,216(sp)
    80005d0a:	7e8e                	ld	t4,224(sp)
    80005d0c:	7f2e                	ld	t5,232(sp)
    80005d0e:	7fce                	ld	t6,240(sp)
    80005d10:	6111                	addi	sp,sp,256
    80005d12:	10200073          	sret
    80005d16:	00000013          	nop
    80005d1a:	00000013          	nop
    80005d1e:	0001                	nop

0000000080005d20 <timervec>:
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	e10c                	sd	a1,0(a0)
    80005d26:	e510                	sd	a2,8(a0)
    80005d28:	e914                	sd	a3,16(a0)
    80005d2a:	6d0c                	ld	a1,24(a0)
    80005d2c:	7110                	ld	a2,32(a0)
    80005d2e:	6194                	ld	a3,0(a1)
    80005d30:	96b2                	add	a3,a3,a2
    80005d32:	e194                	sd	a3,0(a1)
    80005d34:	4589                	li	a1,2
    80005d36:	14459073          	csrw	sip,a1
    80005d3a:	6914                	ld	a3,16(a0)
    80005d3c:	6510                	ld	a2,8(a0)
    80005d3e:	610c                	ld	a1,0(a0)
    80005d40:	34051573          	csrrw	a0,mscratch,a0
    80005d44:	30200073          	mret
	...

0000000080005d4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d4a:	1141                	addi	sp,sp,-16
    80005d4c:	e422                	sd	s0,8(sp)
    80005d4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d50:	0c0007b7          	lui	a5,0xc000
    80005d54:	4705                	li	a4,1
    80005d56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d58:	c3d8                	sw	a4,4(a5)
}
    80005d5a:	6422                	ld	s0,8(sp)
    80005d5c:	0141                	addi	sp,sp,16
    80005d5e:	8082                	ret

0000000080005d60 <plicinithart>:

void
plicinithart(void)
{
    80005d60:	1141                	addi	sp,sp,-16
    80005d62:	e406                	sd	ra,8(sp)
    80005d64:	e022                	sd	s0,0(sp)
    80005d66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	c50080e7          	jalr	-944(ra) # 800019b8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d70:	0085171b          	slliw	a4,a0,0x8
    80005d74:	0c0027b7          	lui	a5,0xc002
    80005d78:	97ba                	add	a5,a5,a4
    80005d7a:	40200713          	li	a4,1026
    80005d7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d82:	00d5151b          	slliw	a0,a0,0xd
    80005d86:	0c2017b7          	lui	a5,0xc201
    80005d8a:	953e                	add	a0,a0,a5
    80005d8c:	00052023          	sw	zero,0(a0)
}
    80005d90:	60a2                	ld	ra,8(sp)
    80005d92:	6402                	ld	s0,0(sp)
    80005d94:	0141                	addi	sp,sp,16
    80005d96:	8082                	ret

0000000080005d98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d98:	1141                	addi	sp,sp,-16
    80005d9a:	e406                	sd	ra,8(sp)
    80005d9c:	e022                	sd	s0,0(sp)
    80005d9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005da0:	ffffc097          	auipc	ra,0xffffc
    80005da4:	c18080e7          	jalr	-1000(ra) # 800019b8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005da8:	00d5179b          	slliw	a5,a0,0xd
    80005dac:	0c201537          	lui	a0,0xc201
    80005db0:	953e                	add	a0,a0,a5
  return irq;
}
    80005db2:	4148                	lw	a0,4(a0)
    80005db4:	60a2                	ld	ra,8(sp)
    80005db6:	6402                	ld	s0,0(sp)
    80005db8:	0141                	addi	sp,sp,16
    80005dba:	8082                	ret

0000000080005dbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dbc:	1101                	addi	sp,sp,-32
    80005dbe:	ec06                	sd	ra,24(sp)
    80005dc0:	e822                	sd	s0,16(sp)
    80005dc2:	e426                	sd	s1,8(sp)
    80005dc4:	1000                	addi	s0,sp,32
    80005dc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	bf0080e7          	jalr	-1040(ra) # 800019b8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005dd0:	00d5151b          	slliw	a0,a0,0xd
    80005dd4:	0c2017b7          	lui	a5,0xc201
    80005dd8:	97aa                	add	a5,a5,a0
    80005dda:	c3c4                	sw	s1,4(a5)
}
    80005ddc:	60e2                	ld	ra,24(sp)
    80005dde:	6442                	ld	s0,16(sp)
    80005de0:	64a2                	ld	s1,8(sp)
    80005de2:	6105                	addi	sp,sp,32
    80005de4:	8082                	ret

0000000080005de6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005de6:	1141                	addi	sp,sp,-16
    80005de8:	e406                	sd	ra,8(sp)
    80005dea:	e022                	sd	s0,0(sp)
    80005dec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dee:	479d                	li	a5,7
    80005df0:	04a7cc63          	blt	a5,a0,80005e48 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005df4:	0001c797          	auipc	a5,0x1c
    80005df8:	77c78793          	addi	a5,a5,1916 # 80022570 <disk>
    80005dfc:	97aa                	add	a5,a5,a0
    80005dfe:	0187c783          	lbu	a5,24(a5)
    80005e02:	ebb9                	bnez	a5,80005e58 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e04:	00451613          	slli	a2,a0,0x4
    80005e08:	0001c797          	auipc	a5,0x1c
    80005e0c:	76878793          	addi	a5,a5,1896 # 80022570 <disk>
    80005e10:	6394                	ld	a3,0(a5)
    80005e12:	96b2                	add	a3,a3,a2
    80005e14:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e18:	6398                	ld	a4,0(a5)
    80005e1a:	9732                	add	a4,a4,a2
    80005e1c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e20:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e24:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e28:	953e                	add	a0,a0,a5
    80005e2a:	4785                	li	a5,1
    80005e2c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005e30:	0001c517          	auipc	a0,0x1c
    80005e34:	75850513          	addi	a0,a0,1880 # 80022588 <disk+0x18>
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	31e080e7          	jalr	798(ra) # 80002156 <wakeup>
}
    80005e40:	60a2                	ld	ra,8(sp)
    80005e42:	6402                	ld	s0,0(sp)
    80005e44:	0141                	addi	sp,sp,16
    80005e46:	8082                	ret
    panic("free_desc 1");
    80005e48:	00003517          	auipc	a0,0x3
    80005e4c:	90050513          	addi	a0,a0,-1792 # 80008748 <syscalls+0x300>
    80005e50:	ffffa097          	auipc	ra,0xffffa
    80005e54:	6ee080e7          	jalr	1774(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e58:	00003517          	auipc	a0,0x3
    80005e5c:	90050513          	addi	a0,a0,-1792 # 80008758 <syscalls+0x310>
    80005e60:	ffffa097          	auipc	ra,0xffffa
    80005e64:	6de080e7          	jalr	1758(ra) # 8000053e <panic>

0000000080005e68 <virtio_disk_init>:
{
    80005e68:	1101                	addi	sp,sp,-32
    80005e6a:	ec06                	sd	ra,24(sp)
    80005e6c:	e822                	sd	s0,16(sp)
    80005e6e:	e426                	sd	s1,8(sp)
    80005e70:	e04a                	sd	s2,0(sp)
    80005e72:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e74:	00003597          	auipc	a1,0x3
    80005e78:	8f458593          	addi	a1,a1,-1804 # 80008768 <syscalls+0x320>
    80005e7c:	0001d517          	auipc	a0,0x1d
    80005e80:	81c50513          	addi	a0,a0,-2020 # 80022698 <disk+0x128>
    80005e84:	ffffb097          	auipc	ra,0xffffb
    80005e88:	cc2080e7          	jalr	-830(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	4398                	lw	a4,0(a5)
    80005e92:	2701                	sext.w	a4,a4
    80005e94:	747277b7          	lui	a5,0x74727
    80005e98:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e9c:	14f71c63          	bne	a4,a5,80005ff4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ea0:	100017b7          	lui	a5,0x10001
    80005ea4:	43dc                	lw	a5,4(a5)
    80005ea6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ea8:	4709                	li	a4,2
    80005eaa:	14e79563          	bne	a5,a4,80005ff4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	479c                	lw	a5,8(a5)
    80005eb4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005eb6:	12e79f63          	bne	a5,a4,80005ff4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eba:	100017b7          	lui	a5,0x10001
    80005ebe:	47d8                	lw	a4,12(a5)
    80005ec0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ec2:	554d47b7          	lui	a5,0x554d4
    80005ec6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eca:	12f71563          	bne	a4,a5,80005ff4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ece:	100017b7          	lui	a5,0x10001
    80005ed2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed6:	4705                	li	a4,1
    80005ed8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eda:	470d                	li	a4,3
    80005edc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ede:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ee0:	c7ffe737          	lui	a4,0xc7ffe
    80005ee4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd9097>
    80005ee8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005eea:	2701                	sext.w	a4,a4
    80005eec:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eee:	472d                	li	a4,11
    80005ef0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ef2:	5bbc                	lw	a5,112(a5)
    80005ef4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ef8:	8ba1                	andi	a5,a5,8
    80005efa:	10078563          	beqz	a5,80006004 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005efe:	100017b7          	lui	a5,0x10001
    80005f02:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f06:	43fc                	lw	a5,68(a5)
    80005f08:	2781                	sext.w	a5,a5
    80005f0a:	10079563          	bnez	a5,80006014 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f0e:	100017b7          	lui	a5,0x10001
    80005f12:	5bdc                	lw	a5,52(a5)
    80005f14:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f16:	10078763          	beqz	a5,80006024 <virtio_disk_init+0x1bc>
  if(max < NUM)
    80005f1a:	471d                	li	a4,7
    80005f1c:	10f77c63          	bgeu	a4,a5,80006034 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80005f20:	ffffb097          	auipc	ra,0xffffb
    80005f24:	bc6080e7          	jalr	-1082(ra) # 80000ae6 <kalloc>
    80005f28:	0001c497          	auipc	s1,0x1c
    80005f2c:	64848493          	addi	s1,s1,1608 # 80022570 <disk>
    80005f30:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f32:	ffffb097          	auipc	ra,0xffffb
    80005f36:	bb4080e7          	jalr	-1100(ra) # 80000ae6 <kalloc>
    80005f3a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f3c:	ffffb097          	auipc	ra,0xffffb
    80005f40:	baa080e7          	jalr	-1110(ra) # 80000ae6 <kalloc>
    80005f44:	87aa                	mv	a5,a0
    80005f46:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f48:	6088                	ld	a0,0(s1)
    80005f4a:	cd6d                	beqz	a0,80006044 <virtio_disk_init+0x1dc>
    80005f4c:	0001c717          	auipc	a4,0x1c
    80005f50:	62c73703          	ld	a4,1580(a4) # 80022578 <disk+0x8>
    80005f54:	cb65                	beqz	a4,80006044 <virtio_disk_init+0x1dc>
    80005f56:	c7fd                	beqz	a5,80006044 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80005f58:	6605                	lui	a2,0x1
    80005f5a:	4581                	li	a1,0
    80005f5c:	ffffb097          	auipc	ra,0xffffb
    80005f60:	d76080e7          	jalr	-650(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f64:	0001c497          	auipc	s1,0x1c
    80005f68:	60c48493          	addi	s1,s1,1548 # 80022570 <disk>
    80005f6c:	6605                	lui	a2,0x1
    80005f6e:	4581                	li	a1,0
    80005f70:	6488                	ld	a0,8(s1)
    80005f72:	ffffb097          	auipc	ra,0xffffb
    80005f76:	d60080e7          	jalr	-672(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f7a:	6605                	lui	a2,0x1
    80005f7c:	4581                	li	a1,0
    80005f7e:	6888                	ld	a0,16(s1)
    80005f80:	ffffb097          	auipc	ra,0xffffb
    80005f84:	d52080e7          	jalr	-686(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f88:	100017b7          	lui	a5,0x10001
    80005f8c:	4721                	li	a4,8
    80005f8e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f90:	4098                	lw	a4,0(s1)
    80005f92:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f96:	40d8                	lw	a4,4(s1)
    80005f98:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f9c:	6498                	ld	a4,8(s1)
    80005f9e:	0007069b          	sext.w	a3,a4
    80005fa2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fa6:	9701                	srai	a4,a4,0x20
    80005fa8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005fac:	6898                	ld	a4,16(s1)
    80005fae:	0007069b          	sext.w	a3,a4
    80005fb2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fb6:	9701                	srai	a4,a4,0x20
    80005fb8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fbc:	4705                	li	a4,1
    80005fbe:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005fc0:	00e48c23          	sb	a4,24(s1)
    80005fc4:	00e48ca3          	sb	a4,25(s1)
    80005fc8:	00e48d23          	sb	a4,26(s1)
    80005fcc:	00e48da3          	sb	a4,27(s1)
    80005fd0:	00e48e23          	sb	a4,28(s1)
    80005fd4:	00e48ea3          	sb	a4,29(s1)
    80005fd8:	00e48f23          	sb	a4,30(s1)
    80005fdc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fe0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe4:	0727a823          	sw	s2,112(a5)
}
    80005fe8:	60e2                	ld	ra,24(sp)
    80005fea:	6442                	ld	s0,16(sp)
    80005fec:	64a2                	ld	s1,8(sp)
    80005fee:	6902                	ld	s2,0(sp)
    80005ff0:	6105                	addi	sp,sp,32
    80005ff2:	8082                	ret
    panic("could not find virtio disk");
    80005ff4:	00002517          	auipc	a0,0x2
    80005ff8:	78450513          	addi	a0,a0,1924 # 80008778 <syscalls+0x330>
    80005ffc:	ffffa097          	auipc	ra,0xffffa
    80006000:	542080e7          	jalr	1346(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006004:	00002517          	auipc	a0,0x2
    80006008:	79450513          	addi	a0,a0,1940 # 80008798 <syscalls+0x350>
    8000600c:	ffffa097          	auipc	ra,0xffffa
    80006010:	532080e7          	jalr	1330(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006014:	00002517          	auipc	a0,0x2
    80006018:	7a450513          	addi	a0,a0,1956 # 800087b8 <syscalls+0x370>
    8000601c:	ffffa097          	auipc	ra,0xffffa
    80006020:	522080e7          	jalr	1314(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006024:	00002517          	auipc	a0,0x2
    80006028:	7b450513          	addi	a0,a0,1972 # 800087d8 <syscalls+0x390>
    8000602c:	ffffa097          	auipc	ra,0xffffa
    80006030:	512080e7          	jalr	1298(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006034:	00002517          	auipc	a0,0x2
    80006038:	7c450513          	addi	a0,a0,1988 # 800087f8 <syscalls+0x3b0>
    8000603c:	ffffa097          	auipc	ra,0xffffa
    80006040:	502080e7          	jalr	1282(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006044:	00002517          	auipc	a0,0x2
    80006048:	7d450513          	addi	a0,a0,2004 # 80008818 <syscalls+0x3d0>
    8000604c:	ffffa097          	auipc	ra,0xffffa
    80006050:	4f2080e7          	jalr	1266(ra) # 8000053e <panic>

0000000080006054 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006054:	7119                	addi	sp,sp,-128
    80006056:	fc86                	sd	ra,120(sp)
    80006058:	f8a2                	sd	s0,112(sp)
    8000605a:	f4a6                	sd	s1,104(sp)
    8000605c:	f0ca                	sd	s2,96(sp)
    8000605e:	ecce                	sd	s3,88(sp)
    80006060:	e8d2                	sd	s4,80(sp)
    80006062:	e4d6                	sd	s5,72(sp)
    80006064:	e0da                	sd	s6,64(sp)
    80006066:	fc5e                	sd	s7,56(sp)
    80006068:	f862                	sd	s8,48(sp)
    8000606a:	f466                	sd	s9,40(sp)
    8000606c:	f06a                	sd	s10,32(sp)
    8000606e:	ec6e                	sd	s11,24(sp)
    80006070:	0100                	addi	s0,sp,128
    80006072:	8aaa                	mv	s5,a0
    80006074:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006076:	00c52d03          	lw	s10,12(a0)
    8000607a:	001d1d1b          	slliw	s10,s10,0x1
    8000607e:	1d02                	slli	s10,s10,0x20
    80006080:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006084:	0001c517          	auipc	a0,0x1c
    80006088:	61450513          	addi	a0,a0,1556 # 80022698 <disk+0x128>
    8000608c:	ffffb097          	auipc	ra,0xffffb
    80006090:	b4a080e7          	jalr	-1206(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006094:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006096:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006098:	0001cb97          	auipc	s7,0x1c
    8000609c:	4d8b8b93          	addi	s7,s7,1240 # 80022570 <disk>
  for(int i = 0; i < 3; i++){
    800060a0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060a2:	0001cc97          	auipc	s9,0x1c
    800060a6:	5f6c8c93          	addi	s9,s9,1526 # 80022698 <disk+0x128>
    800060aa:	a08d                	j	8000610c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800060ac:	00fb8733          	add	a4,s7,a5
    800060b0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060b4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060b6:	0207c563          	bltz	a5,800060e0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060ba:	2905                	addiw	s2,s2,1
    800060bc:	0611                	addi	a2,a2,4
    800060be:	05690c63          	beq	s2,s6,80006116 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800060c2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060c4:	0001c717          	auipc	a4,0x1c
    800060c8:	4ac70713          	addi	a4,a4,1196 # 80022570 <disk>
    800060cc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060ce:	01874683          	lbu	a3,24(a4)
    800060d2:	fee9                	bnez	a3,800060ac <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060d4:	2785                	addiw	a5,a5,1
    800060d6:	0705                	addi	a4,a4,1
    800060d8:	fe979be3          	bne	a5,s1,800060ce <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060dc:	57fd                	li	a5,-1
    800060de:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060e0:	01205d63          	blez	s2,800060fa <virtio_disk_rw+0xa6>
    800060e4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060e6:	000a2503          	lw	a0,0(s4)
    800060ea:	00000097          	auipc	ra,0x0
    800060ee:	cfc080e7          	jalr	-772(ra) # 80005de6 <free_desc>
      for(int j = 0; j < i; j++)
    800060f2:	2d85                	addiw	s11,s11,1
    800060f4:	0a11                	addi	s4,s4,4
    800060f6:	ffb918e3          	bne	s2,s11,800060e6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060fa:	85e6                	mv	a1,s9
    800060fc:	0001c517          	auipc	a0,0x1c
    80006100:	48c50513          	addi	a0,a0,1164 # 80022588 <disk+0x18>
    80006104:	ffffc097          	auipc	ra,0xffffc
    80006108:	fee080e7          	jalr	-18(ra) # 800020f2 <sleep>
  for(int i = 0; i < 3; i++){
    8000610c:	f8040a13          	addi	s4,s0,-128
{
    80006110:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006112:	894e                	mv	s2,s3
    80006114:	b77d                	j	800060c2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006116:	f8042583          	lw	a1,-128(s0)
    8000611a:	00a58793          	addi	a5,a1,10
    8000611e:	0792                	slli	a5,a5,0x4

  if(write)
    80006120:	0001c617          	auipc	a2,0x1c
    80006124:	45060613          	addi	a2,a2,1104 # 80022570 <disk>
    80006128:	00f60733          	add	a4,a2,a5
    8000612c:	018036b3          	snez	a3,s8
    80006130:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006132:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006136:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000613a:	f6078693          	addi	a3,a5,-160
    8000613e:	6218                	ld	a4,0(a2)
    80006140:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006142:	00878513          	addi	a0,a5,8
    80006146:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006148:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000614a:	6208                	ld	a0,0(a2)
    8000614c:	96aa                	add	a3,a3,a0
    8000614e:	4741                	li	a4,16
    80006150:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006152:	4705                	li	a4,1
    80006154:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006158:	f8442703          	lw	a4,-124(s0)
    8000615c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006160:	0712                	slli	a4,a4,0x4
    80006162:	953a                	add	a0,a0,a4
    80006164:	058a8693          	addi	a3,s5,88
    80006168:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000616a:	6208                	ld	a0,0(a2)
    8000616c:	972a                	add	a4,a4,a0
    8000616e:	40000693          	li	a3,1024
    80006172:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006174:	001c3c13          	seqz	s8,s8
    80006178:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000617a:	001c6c13          	ori	s8,s8,1
    8000617e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006182:	f8842603          	lw	a2,-120(s0)
    80006186:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000618a:	0001c697          	auipc	a3,0x1c
    8000618e:	3e668693          	addi	a3,a3,998 # 80022570 <disk>
    80006192:	00258713          	addi	a4,a1,2
    80006196:	0712                	slli	a4,a4,0x4
    80006198:	9736                	add	a4,a4,a3
    8000619a:	587d                	li	a6,-1
    8000619c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061a0:	0612                	slli	a2,a2,0x4
    800061a2:	9532                	add	a0,a0,a2
    800061a4:	f9078793          	addi	a5,a5,-112
    800061a8:	97b6                	add	a5,a5,a3
    800061aa:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800061ac:	629c                	ld	a5,0(a3)
    800061ae:	97b2                	add	a5,a5,a2
    800061b0:	4605                	li	a2,1
    800061b2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061b4:	4509                	li	a0,2
    800061b6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800061ba:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061be:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800061c2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061c6:	6698                	ld	a4,8(a3)
    800061c8:	00275783          	lhu	a5,2(a4)
    800061cc:	8b9d                	andi	a5,a5,7
    800061ce:	0786                	slli	a5,a5,0x1
    800061d0:	97ba                	add	a5,a5,a4
    800061d2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800061d6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061da:	6698                	ld	a4,8(a3)
    800061dc:	00275783          	lhu	a5,2(a4)
    800061e0:	2785                	addiw	a5,a5,1
    800061e2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061e6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061ea:	100017b7          	lui	a5,0x10001
    800061ee:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061f2:	004aa783          	lw	a5,4(s5)
    800061f6:	02c79163          	bne	a5,a2,80006218 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800061fa:	0001c917          	auipc	s2,0x1c
    800061fe:	49e90913          	addi	s2,s2,1182 # 80022698 <disk+0x128>
  while(b->disk == 1) {
    80006202:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006204:	85ca                	mv	a1,s2
    80006206:	8556                	mv	a0,s5
    80006208:	ffffc097          	auipc	ra,0xffffc
    8000620c:	eea080e7          	jalr	-278(ra) # 800020f2 <sleep>
  while(b->disk == 1) {
    80006210:	004aa783          	lw	a5,4(s5)
    80006214:	fe9788e3          	beq	a5,s1,80006204 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006218:	f8042903          	lw	s2,-128(s0)
    8000621c:	00290793          	addi	a5,s2,2
    80006220:	00479713          	slli	a4,a5,0x4
    80006224:	0001c797          	auipc	a5,0x1c
    80006228:	34c78793          	addi	a5,a5,844 # 80022570 <disk>
    8000622c:	97ba                	add	a5,a5,a4
    8000622e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006232:	0001c997          	auipc	s3,0x1c
    80006236:	33e98993          	addi	s3,s3,830 # 80022570 <disk>
    8000623a:	00491713          	slli	a4,s2,0x4
    8000623e:	0009b783          	ld	a5,0(s3)
    80006242:	97ba                	add	a5,a5,a4
    80006244:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006248:	854a                	mv	a0,s2
    8000624a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000624e:	00000097          	auipc	ra,0x0
    80006252:	b98080e7          	jalr	-1128(ra) # 80005de6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006256:	8885                	andi	s1,s1,1
    80006258:	f0ed                	bnez	s1,8000623a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000625a:	0001c517          	auipc	a0,0x1c
    8000625e:	43e50513          	addi	a0,a0,1086 # 80022698 <disk+0x128>
    80006262:	ffffb097          	auipc	ra,0xffffb
    80006266:	a28080e7          	jalr	-1496(ra) # 80000c8a <release>
}
    8000626a:	70e6                	ld	ra,120(sp)
    8000626c:	7446                	ld	s0,112(sp)
    8000626e:	74a6                	ld	s1,104(sp)
    80006270:	7906                	ld	s2,96(sp)
    80006272:	69e6                	ld	s3,88(sp)
    80006274:	6a46                	ld	s4,80(sp)
    80006276:	6aa6                	ld	s5,72(sp)
    80006278:	6b06                	ld	s6,64(sp)
    8000627a:	7be2                	ld	s7,56(sp)
    8000627c:	7c42                	ld	s8,48(sp)
    8000627e:	7ca2                	ld	s9,40(sp)
    80006280:	7d02                	ld	s10,32(sp)
    80006282:	6de2                	ld	s11,24(sp)
    80006284:	6109                	addi	sp,sp,128
    80006286:	8082                	ret

0000000080006288 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006288:	1101                	addi	sp,sp,-32
    8000628a:	ec06                	sd	ra,24(sp)
    8000628c:	e822                	sd	s0,16(sp)
    8000628e:	e426                	sd	s1,8(sp)
    80006290:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006292:	0001c497          	auipc	s1,0x1c
    80006296:	2de48493          	addi	s1,s1,734 # 80022570 <disk>
    8000629a:	0001c517          	auipc	a0,0x1c
    8000629e:	3fe50513          	addi	a0,a0,1022 # 80022698 <disk+0x128>
    800062a2:	ffffb097          	auipc	ra,0xffffb
    800062a6:	934080e7          	jalr	-1740(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062aa:	10001737          	lui	a4,0x10001
    800062ae:	533c                	lw	a5,96(a4)
    800062b0:	8b8d                	andi	a5,a5,3
    800062b2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062b4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062b8:	689c                	ld	a5,16(s1)
    800062ba:	0204d703          	lhu	a4,32(s1)
    800062be:	0027d783          	lhu	a5,2(a5)
    800062c2:	04f70863          	beq	a4,a5,80006312 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062c6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062ca:	6898                	ld	a4,16(s1)
    800062cc:	0204d783          	lhu	a5,32(s1)
    800062d0:	8b9d                	andi	a5,a5,7
    800062d2:	078e                	slli	a5,a5,0x3
    800062d4:	97ba                	add	a5,a5,a4
    800062d6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062d8:	00278713          	addi	a4,a5,2
    800062dc:	0712                	slli	a4,a4,0x4
    800062de:	9726                	add	a4,a4,s1
    800062e0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062e4:	e721                	bnez	a4,8000632c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062e6:	0789                	addi	a5,a5,2
    800062e8:	0792                	slli	a5,a5,0x4
    800062ea:	97a6                	add	a5,a5,s1
    800062ec:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800062ee:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062f2:	ffffc097          	auipc	ra,0xffffc
    800062f6:	e64080e7          	jalr	-412(ra) # 80002156 <wakeup>

    disk.used_idx += 1;
    800062fa:	0204d783          	lhu	a5,32(s1)
    800062fe:	2785                	addiw	a5,a5,1
    80006300:	17c2                	slli	a5,a5,0x30
    80006302:	93c1                	srli	a5,a5,0x30
    80006304:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006308:	6898                	ld	a4,16(s1)
    8000630a:	00275703          	lhu	a4,2(a4)
    8000630e:	faf71ce3          	bne	a4,a5,800062c6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006312:	0001c517          	auipc	a0,0x1c
    80006316:	38650513          	addi	a0,a0,902 # 80022698 <disk+0x128>
    8000631a:	ffffb097          	auipc	ra,0xffffb
    8000631e:	970080e7          	jalr	-1680(ra) # 80000c8a <release>
}
    80006322:	60e2                	ld	ra,24(sp)
    80006324:	6442                	ld	s0,16(sp)
    80006326:	64a2                	ld	s1,8(sp)
    80006328:	6105                	addi	sp,sp,32
    8000632a:	8082                	ret
      panic("virtio_disk_intr status");
    8000632c:	00002517          	auipc	a0,0x2
    80006330:	50450513          	addi	a0,a0,1284 # 80008830 <syscalls+0x3e8>
    80006334:	ffffa097          	auipc	ra,0xffffa
    80006338:	20a080e7          	jalr	522(ra) # 8000053e <panic>

000000008000633c <free_desc>:
    panic("virtio_gpu: no free descriptors");
}

static void
free_desc(int i)
{
    8000633c:	1141                	addi	sp,sp,-16
    8000633e:	e422                	sd	s0,8(sp)
    80006340:	0800                	addi	s0,sp,16
    gq.desc[i].addr = 0;
    80006342:	0001c717          	auipc	a4,0x1c
    80006346:	36e70713          	addi	a4,a4,878 # 800226b0 <gq>
    8000634a:	00451693          	slli	a3,a0,0x4
    8000634e:	631c                	ld	a5,0(a4)
    80006350:	97b6                	add	a5,a5,a3
    80006352:	0007b023          	sd	zero,0(a5)
    gq.desc[i].len = 0;
    80006356:	0007a423          	sw	zero,8(a5)
    gq.desc[i].flags = 0;
    8000635a:	00079623          	sh	zero,12(a5)
    gq.desc[i].next = 0;
    8000635e:	00079723          	sh	zero,14(a5)
    gq.free[i] = 1;
    80006362:	972a                	add	a4,a4,a0
    80006364:	4785                	li	a5,1
    80006366:	00f70c23          	sb	a5,24(a4)
}
    8000636a:	6422                	ld	s0,8(sp)
    8000636c:	0141                	addi	sp,sp,16
    8000636e:	8082                	ret

0000000080006370 <alloc_desc>:
    for (int i = 0; i < GPU_NUM; i++)
    80006370:	0001c797          	auipc	a5,0x1c
    80006374:	34078793          	addi	a5,a5,832 # 800226b0 <gq>
    80006378:	4501                	li	a0,0
    8000637a:	46a1                	li	a3,8
        if (gq.free[i])
    8000637c:	0187c703          	lbu	a4,24(a5)
    80006380:	e30d                	bnez	a4,800063a2 <alloc_desc+0x32>
    for (int i = 0; i < GPU_NUM; i++)
    80006382:	2505                	addiw	a0,a0,1
    80006384:	0785                	addi	a5,a5,1
    80006386:	fed51be3          	bne	a0,a3,8000637c <alloc_desc+0xc>
{
    8000638a:	1141                	addi	sp,sp,-16
    8000638c:	e406                	sd	ra,8(sp)
    8000638e:	e022                	sd	s0,0(sp)
    80006390:	0800                	addi	s0,sp,16
    panic("virtio_gpu: no free descriptors");
    80006392:	00002517          	auipc	a0,0x2
    80006396:	4b650513          	addi	a0,a0,1206 # 80008848 <syscalls+0x400>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	1a4080e7          	jalr	420(ra) # 8000053e <panic>
            gq.free[i] = 0;
    800063a2:	0001c797          	auipc	a5,0x1c
    800063a6:	30e78793          	addi	a5,a5,782 # 800226b0 <gq>
    800063aa:	97aa                	add	a5,a5,a0
    800063ac:	00078c23          	sb	zero,24(a5)
}
    800063b0:	8082                	ret

00000000800063b2 <gpu_send>:

// Submit a 2-descriptor command (request + shared response) and block
// until the device completes it by advancing the used ring.
static void
gpu_send(void *req, int req_len)
{
    800063b2:	7139                	addi	sp,sp,-64
    800063b4:	fc06                	sd	ra,56(sp)
    800063b6:	f822                	sd	s0,48(sp)
    800063b8:	f426                	sd	s1,40(sp)
    800063ba:	f04a                	sd	s2,32(sp)
    800063bc:	ec4e                	sd	s3,24(sp)
    800063be:	e852                	sd	s4,16(sp)
    800063c0:	e456                	sd	s5,8(sp)
    800063c2:	0080                	addi	s0,sp,64
    800063c4:	8aaa                	mv	s5,a0
    800063c6:	8a2e                	mv	s4,a1
    acquire(&gpu_lock);
    800063c8:	0001c997          	auipc	s3,0x1c
    800063cc:	2e898993          	addi	s3,s3,744 # 800226b0 <gq>
    800063d0:	0001c517          	auipc	a0,0x1c
    800063d4:	30850513          	addi	a0,a0,776 # 800226d8 <gpu_lock>
    800063d8:	ffffa097          	auipc	ra,0xffffa
    800063dc:	7fe080e7          	jalr	2046(ra) # 80000bd6 <acquire>
    int d0 = alloc_desc();
    800063e0:	00000097          	auipc	ra,0x0
    800063e4:	f90080e7          	jalr	-112(ra) # 80006370 <alloc_desc>
    800063e8:	892a                	mv	s2,a0
    int d1 = alloc_desc();
    800063ea:	00000097          	auipc	ra,0x0
    800063ee:	f86080e7          	jalr	-122(ra) # 80006370 <alloc_desc>
    800063f2:	84aa                	mv	s1,a0

    gq.desc[d0].addr = (uint64)req;
    800063f4:	00491793          	slli	a5,s2,0x4
    800063f8:	0009b703          	ld	a4,0(s3)
    800063fc:	973e                	add	a4,a4,a5
    800063fe:	01573023          	sd	s5,0(a4)
    gq.desc[d0].len = (uint32)req_len;
    80006402:	0009b703          	ld	a4,0(s3)
    80006406:	97ba                	add	a5,a5,a4
    80006408:	0147a423          	sw	s4,8(a5)
    gq.desc[d0].flags = VRING_DESC_F_NEXT;
    8000640c:	4685                	li	a3,1
    8000640e:	00d79623          	sh	a3,12(a5)
    gq.desc[d0].next = d1;
    80006412:	00a79723          	sh	a0,14(a5)

    gq.desc[d1].addr = (uint64)&cmd_resp;
    80006416:	00451693          	slli	a3,a0,0x4
    8000641a:	9736                	add	a4,a4,a3
    8000641c:	0001c797          	auipc	a5,0x1c
    80006420:	2d478793          	addi	a5,a5,724 # 800226f0 <cmd_resp>
    80006424:	e31c                	sd	a5,0(a4)
    gq.desc[d1].len = sizeof(cmd_resp);
    80006426:	0009b783          	ld	a5,0(s3)
    8000642a:	97b6                	add	a5,a5,a3
    8000642c:	4761                	li	a4,24
    8000642e:	c798                	sw	a4,8(a5)
    gq.desc[d1].flags = VRING_DESC_F_WRITE;
    80006430:	4709                	li	a4,2
    80006432:	00e79623          	sh	a4,12(a5)
    gq.desc[d1].next = 0;
    80006436:	00079723          	sh	zero,14(a5)

    // Place head descriptor index in the available ring.
    gq.avail->ring[gq.avail->idx % GPU_NUM] = d0;
    8000643a:	0089b703          	ld	a4,8(s3)
    8000643e:	00275783          	lhu	a5,2(a4)
    80006442:	8b9d                	andi	a5,a5,7
    80006444:	0786                	slli	a5,a5,0x1
    80006446:	97ba                	add	a5,a5,a4
    80006448:	01279223          	sh	s2,4(a5)
    __sync_synchronize();
    8000644c:	0ff0000f          	fence
    gq.avail->idx++;
    80006450:	0089b703          	ld	a4,8(s3)
    80006454:	00275783          	lhu	a5,2(a4)
    80006458:	2785                	addiw	a5,a5,1
    8000645a:	00f71123          	sh	a5,2(a4)
    __sync_synchronize();
    8000645e:	0ff0000f          	fence

    // Notify device (queue index 0 = controlq).
    *R1(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;
    80006462:	100027b7          	lui	a5,0x10002
    80006466:	0407a823          	sw	zero,80(a5) # 10002050 <_entry-0x6fffdfb0>

    // Poll until the device advances the used ring.
    while (1)
    {
        __sync_synchronize();
        if (gq.used->idx != gq.used_idx)
    8000646a:	874e                	mv	a4,s3
        __sync_synchronize();
    8000646c:	0ff0000f          	fence
        if (gq.used->idx != gq.used_idx)
    80006470:	02075783          	lhu	a5,32(a4)
    80006474:	6b14                	ld	a3,16(a4)
    80006476:	0026d683          	lhu	a3,2(a3)
    8000647a:	fef689e3          	beq	a3,a5,8000646c <gpu_send+0xba>
            break;
    }
    gq.used_idx++;
    8000647e:	2785                	addiw	a5,a5,1
    80006480:	0001c717          	auipc	a4,0x1c
    80006484:	24f71823          	sh	a5,592(a4) # 800226d0 <gq+0x20>

    free_desc(d0);
    80006488:	854a                	mv	a0,s2
    8000648a:	00000097          	auipc	ra,0x0
    8000648e:	eb2080e7          	jalr	-334(ra) # 8000633c <free_desc>
    free_desc(d1);
    80006492:	8526                	mv	a0,s1
    80006494:	00000097          	auipc	ra,0x0
    80006498:	ea8080e7          	jalr	-344(ra) # 8000633c <free_desc>
    release(&gpu_lock);
    8000649c:	0001c517          	auipc	a0,0x1c
    800064a0:	23c50513          	addi	a0,a0,572 # 800226d8 <gpu_lock>
    800064a4:	ffffa097          	auipc	ra,0xffffa
    800064a8:	7e6080e7          	jalr	2022(ra) # 80000c8a <release>
}
    800064ac:	70e2                	ld	ra,56(sp)
    800064ae:	7442                	ld	s0,48(sp)
    800064b0:	74a2                	ld	s1,40(sp)
    800064b2:	7902                	ld	s2,32(sp)
    800064b4:	69e2                	ld	s3,24(sp)
    800064b6:	6a42                	ld	s4,16(sp)
    800064b8:	6aa2                	ld	s5,8(sp)
    800064ba:	6121                	addi	sp,sp,64
    800064bc:	8082                	ret

00000000800064be <gpu_transfer_flush>:
{
    800064be:	7139                	addi	sp,sp,-64
    800064c0:	fc06                	sd	ra,56(sp)
    800064c2:	f822                	sd	s0,48(sp)
    800064c4:	f426                	sd	s1,40(sp)
    800064c6:	f04a                	sd	s2,32(sp)
    800064c8:	ec4e                	sd	s3,24(sp)
    800064ca:	e852                	sd	s4,16(sp)
    800064cc:	e456                	sd	s5,8(sp)
    800064ce:	0080                	addi	s0,sp,64
    memset(&xfer, 0, sizeof(xfer));
    800064d0:	0001c497          	auipc	s1,0x1c
    800064d4:	1e048493          	addi	s1,s1,480 # 800226b0 <gq>
    800064d8:	0001c917          	auipc	s2,0x1c
    800064dc:	23090913          	addi	s2,s2,560 # 80022708 <xfer.1>
    800064e0:	03800613          	li	a2,56
    800064e4:	4581                	li	a1,0
    800064e6:	854a                	mv	a0,s2
    800064e8:	ffffa097          	auipc	ra,0xffffa
    800064ec:	7ea080e7          	jalr	2026(ra) # 80000cd2 <memset>
    xfer.hdr.type = VIRTIO_GPU_CMD_TRANSFER_TO_HOST_2D;
    800064f0:	10500793          	li	a5,261
    800064f4:	ccbc                	sw	a5,88(s1)
    xfer.r.x = 0;
    800064f6:	0604a823          	sw	zero,112(s1)
    xfer.r.y = 0;
    800064fa:	0604aa23          	sw	zero,116(s1)
    xfer.r.width = SCREEN_W;
    800064fe:	28000a93          	li	s5,640
    80006502:	0754ac23          	sw	s5,120(s1)
    xfer.r.height = SCREEN_H;
    80006506:	1e000a13          	li	s4,480
    8000650a:	0744ae23          	sw	s4,124(s1)
    xfer.resource_id = RESOURCE_ID;
    8000650e:	4985                	li	s3,1
    80006510:	0934a423          	sw	s3,136(s1)
    gpu_send(&xfer, sizeof(xfer));
    80006514:	03800593          	li	a1,56
    80006518:	854a                	mv	a0,s2
    8000651a:	00000097          	auipc	ra,0x0
    8000651e:	e98080e7          	jalr	-360(ra) # 800063b2 <gpu_send>
    memset(&flush, 0, sizeof(flush));
    80006522:	0001c917          	auipc	s2,0x1c
    80006526:	21e90913          	addi	s2,s2,542 # 80022740 <flush.0>
    8000652a:	03000613          	li	a2,48
    8000652e:	4581                	li	a1,0
    80006530:	854a                	mv	a0,s2
    80006532:	ffffa097          	auipc	ra,0xffffa
    80006536:	7a0080e7          	jalr	1952(ra) # 80000cd2 <memset>
    flush.hdr.type = VIRTIO_GPU_CMD_RESOURCE_FLUSH;
    8000653a:	10400793          	li	a5,260
    8000653e:	08f4a823          	sw	a5,144(s1)
    flush.r.x = 0;
    80006542:	0a04a423          	sw	zero,168(s1)
    flush.r.y = 0;
    80006546:	0a04a623          	sw	zero,172(s1)
    flush.r.width = SCREEN_W;
    8000654a:	0b54a823          	sw	s5,176(s1)
    flush.r.height = SCREEN_H;
    8000654e:	0b44aa23          	sw	s4,180(s1)
    flush.resource_id = RESOURCE_ID;
    80006552:	0b34ac23          	sw	s3,184(s1)
    gpu_send(&flush, sizeof(flush));
    80006556:	03000593          	li	a1,48
    8000655a:	854a                	mv	a0,s2
    8000655c:	00000097          	auipc	ra,0x0
    80006560:	e56080e7          	jalr	-426(ra) # 800063b2 <gpu_send>
}
    80006564:	70e2                	ld	ra,56(sp)
    80006566:	7442                	ld	s0,48(sp)
    80006568:	74a2                	ld	s1,40(sp)
    8000656a:	7902                	ld	s2,32(sp)
    8000656c:	69e2                	ld	s3,24(sp)
    8000656e:	6a42                	ld	s4,16(sp)
    80006570:	6aa2                	ld	s5,8(sp)
    80006572:	6121                	addi	sp,sp,64
    80006574:	8082                	ret

0000000080006576 <virtio_gpu_init>:

// ── Public init ───────────────────────────────────────────────────────

void virtio_gpu_init(void)
{
    80006576:	7159                	addi	sp,sp,-112
    80006578:	f486                	sd	ra,104(sp)
    8000657a:	f0a2                	sd	s0,96(sp)
    8000657c:	eca6                	sd	s1,88(sp)
    8000657e:	e8ca                	sd	s2,80(sp)
    80006580:	e4ce                	sd	s3,72(sp)
    80006582:	e0d2                	sd	s4,64(sp)
    80006584:	fc56                	sd	s5,56(sp)
    80006586:	f85a                	sd	s6,48(sp)
    80006588:	f45e                	sd	s7,40(sp)
    8000658a:	f062                	sd	s8,32(sp)
    8000658c:	ec66                	sd	s9,24(sp)
    8000658e:	e86a                	sd	s10,16(sp)
    80006590:	e46e                	sd	s11,8(sp)
    80006592:	1880                	addi	s0,sp,112
    uint32 status = 0;
    initlock(&gpu_lock, "vgpu");
    80006594:	00002597          	auipc	a1,0x2
    80006598:	2d458593          	addi	a1,a1,724 # 80008868 <syscalls+0x420>
    8000659c:	0001c517          	auipc	a0,0x1c
    800065a0:	13c50513          	addi	a0,a0,316 # 800226d8 <gpu_lock>
    800065a4:	ffffa097          	auipc	ra,0xffffa
    800065a8:	5a2080e7          	jalr	1442(ra) # 80000b46 <initlock>

    // ── 1. VirtIO device handshake ──────────────────────────────────────
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065ac:	100027b7          	lui	a5,0x10002
    800065b0:	4398                	lw	a4,0(a5)
    800065b2:	2701                	sext.w	a4,a4
    800065b4:	747277b7          	lui	a5,0x74727
    800065b8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065bc:	02f71a63          	bne	a4,a5,800065f0 <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    800065c0:	100027b7          	lui	a5,0x10002
    800065c4:	43dc                	lw	a5,4(a5)
    800065c6:	2781                	sext.w	a5,a5
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065c8:	4709                	li	a4,2
    800065ca:	02e79363          	bne	a5,a4,800065f0 <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    800065ce:	100027b7          	lui	a5,0x10002
    800065d2:	479c                	lw	a5,8(a5)
    800065d4:	2781                	sext.w	a5,a5
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    800065d6:	4741                	li	a4,16
    800065d8:	00e79c63          	bne	a5,a4,800065f0 <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551)
    800065dc:	100027b7          	lui	a5,0x10002
    800065e0:	47d8                	lw	a4,12(a5)
    800065e2:	2701                	sext.w	a4,a4
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    800065e4:	554d47b7          	lui	a5,0x554d4
    800065e8:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800065ec:	02f70963          	beq	a4,a5,8000661e <virtio_gpu_init+0xa8>
    {
        printf("virtio_gpu_init: GPU not found\n");
    800065f0:	00002517          	auipc	a0,0x2
    800065f4:	28050513          	addi	a0,a0,640 # 80008870 <syscalls+0x428>
    800065f8:	ffffa097          	auipc	ra,0xffffa
    800065fc:	f90080e7          	jalr	-112(ra) # 80000588 <printf>
    gpu_send(&scanout_req, sizeof(scanout_req));

    // ── 8. TRANSFER_TO_HOST_2D (upload guest memory -> host GPU) ─────────
    gpu_transfer_flush();
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
}
    80006600:	70a6                	ld	ra,104(sp)
    80006602:	7406                	ld	s0,96(sp)
    80006604:	64e6                	ld	s1,88(sp)
    80006606:	6946                	ld	s2,80(sp)
    80006608:	69a6                	ld	s3,72(sp)
    8000660a:	6a06                	ld	s4,64(sp)
    8000660c:	7ae2                	ld	s5,56(sp)
    8000660e:	7b42                	ld	s6,48(sp)
    80006610:	7ba2                	ld	s7,40(sp)
    80006612:	7c02                	ld	s8,32(sp)
    80006614:	6ce2                	ld	s9,24(sp)
    80006616:	6d42                	ld	s10,16(sp)
    80006618:	6da2                	ld	s11,8(sp)
    8000661a:	6165                	addi	sp,sp,112
    8000661c:	8082                	ret
    *R1(VIRTIO_MMIO_STATUS) = status;
    8000661e:	100027b7          	lui	a5,0x10002
    80006622:	0607a823          	sw	zero,112(a5) # 10002070 <_entry-0x6fffdf90>
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006626:	4705                	li	a4,1
    80006628:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    8000662a:	470d                	li	a4,3
    8000662c:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_DRIVER_FEATURES) = 0;
    8000662e:	0207a023          	sw	zero,32(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006632:	472d                	li	a4,11
    80006634:	dbb8                	sw	a4,112(a5)
    if (!(*R1(VIRTIO_MMIO_STATUS) & VIRTIO_CONFIG_S_FEATURES_OK))
    80006636:	5bbc                	lw	a5,112(a5)
    80006638:	8ba1                	andi	a5,a5,8
    8000663a:	22078363          	beqz	a5,80006860 <virtio_gpu_init+0x2ea>
    *R1(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000663e:	100027b7          	lui	a5,0x10002
    80006642:	0207a823          	sw	zero,48(a5) # 10002030 <_entry-0x6fffdfd0>
    if (*R1(VIRTIO_MMIO_QUEUE_READY))
    80006646:	43fc                	lw	a5,68(a5)
    80006648:	2781                	sext.w	a5,a5
    8000664a:	22079363          	bnez	a5,80006870 <virtio_gpu_init+0x2fa>
    if (*R1(VIRTIO_MMIO_QUEUE_NUM_MAX) < GPU_NUM)
    8000664e:	100027b7          	lui	a5,0x10002
    80006652:	5bdc                	lw	a5,52(a5)
    80006654:	2781                	sext.w	a5,a5
    80006656:	471d                	li	a4,7
    80006658:	22f77463          	bgeu	a4,a5,80006880 <virtio_gpu_init+0x30a>
    gq.desc = kalloc();
    8000665c:	ffffa097          	auipc	ra,0xffffa
    80006660:	48a080e7          	jalr	1162(ra) # 80000ae6 <kalloc>
    80006664:	0001c497          	auipc	s1,0x1c
    80006668:	04c48493          	addi	s1,s1,76 # 800226b0 <gq>
    8000666c:	e088                	sd	a0,0(s1)
    gq.avail = kalloc();
    8000666e:	ffffa097          	auipc	ra,0xffffa
    80006672:	478080e7          	jalr	1144(ra) # 80000ae6 <kalloc>
    80006676:	e488                	sd	a0,8(s1)
    gq.used = kalloc();
    80006678:	ffffa097          	auipc	ra,0xffffa
    8000667c:	46e080e7          	jalr	1134(ra) # 80000ae6 <kalloc>
    80006680:	87aa                	mv	a5,a0
    80006682:	e888                	sd	a0,16(s1)
    if (!gq.desc || !gq.avail || !gq.used)
    80006684:	6088                	ld	a0,0(s1)
    80006686:	20050563          	beqz	a0,80006890 <virtio_gpu_init+0x31a>
    8000668a:	0001c717          	auipc	a4,0x1c
    8000668e:	02e73703          	ld	a4,46(a4) # 800226b8 <gq+0x8>
    80006692:	1e070f63          	beqz	a4,80006890 <virtio_gpu_init+0x31a>
    80006696:	1e078d63          	beqz	a5,80006890 <virtio_gpu_init+0x31a>
    memset(gq.desc, 0, PGSIZE);
    8000669a:	6605                	lui	a2,0x1
    8000669c:	4581                	li	a1,0
    8000669e:	ffffa097          	auipc	ra,0xffffa
    800066a2:	634080e7          	jalr	1588(ra) # 80000cd2 <memset>
    memset(gq.avail, 0, PGSIZE);
    800066a6:	0001c497          	auipc	s1,0x1c
    800066aa:	00a48493          	addi	s1,s1,10 # 800226b0 <gq>
    800066ae:	6605                	lui	a2,0x1
    800066b0:	4581                	li	a1,0
    800066b2:	6488                	ld	a0,8(s1)
    800066b4:	ffffa097          	auipc	ra,0xffffa
    800066b8:	61e080e7          	jalr	1566(ra) # 80000cd2 <memset>
    memset(gq.used, 0, PGSIZE);
    800066bc:	6605                	lui	a2,0x1
    800066be:	4581                	li	a1,0
    800066c0:	6888                	ld	a0,16(s1)
    800066c2:	ffffa097          	auipc	ra,0xffffa
    800066c6:	610080e7          	jalr	1552(ra) # 80000cd2 <memset>
    *R1(VIRTIO_MMIO_QUEUE_NUM) = GPU_NUM;
    800066ca:	100027b7          	lui	a5,0x10002
    800066ce:	4721                	li	a4,8
    800066d0:	df98                	sw	a4,56(a5)
    *R1(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)gq.desc;
    800066d2:	4098                	lw	a4,0(s1)
    800066d4:	08e7a023          	sw	a4,128(a5) # 10002080 <_entry-0x6fffdf80>
    *R1(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)gq.desc >> 32;
    800066d8:	40d8                	lw	a4,4(s1)
    800066da:	08e7a223          	sw	a4,132(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)gq.avail;
    800066de:	6498                	ld	a4,8(s1)
    800066e0:	0007069b          	sext.w	a3,a4
    800066e4:	08d7a823          	sw	a3,144(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)gq.avail >> 32;
    800066e8:	9701                	srai	a4,a4,0x20
    800066ea:	08e7aa23          	sw	a4,148(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)gq.used;
    800066ee:	6898                	ld	a4,16(s1)
    800066f0:	0007069b          	sext.w	a3,a4
    800066f4:	0ad7a023          	sw	a3,160(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)gq.used >> 32;
    800066f8:	9701                	srai	a4,a4,0x20
    800066fa:	0ae7a223          	sw	a4,164(a5)
    *R1(VIRTIO_MMIO_QUEUE_READY) = 1;
    800066fe:	4705                	li	a4,1
    80006700:	c3f8                	sw	a4,68(a5)
        gq.free[i] = 1;
    80006702:	00e48c23          	sb	a4,24(s1)
    80006706:	00e48ca3          	sb	a4,25(s1)
    8000670a:	00e48d23          	sb	a4,26(s1)
    8000670e:	00e48da3          	sb	a4,27(s1)
    80006712:	00e48e23          	sb	a4,28(s1)
    80006716:	00e48ea3          	sb	a4,29(s1)
    8000671a:	00e48f23          	sb	a4,30(s1)
    8000671e:	00e48fa3          	sb	a4,31(s1)
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006722:	473d                	li	a4,15
    80006724:	dbb8                	sw	a4,112(a5)
    for (int i = 0; i < FB_PAGES; i++)
    80006726:	0001e917          	auipc	s2,0x1e
    8000672a:	64290913          	addi	s2,s2,1602 # 80024d68 <fb>
    8000672e:	0001f997          	auipc	s3,0x1f
    80006732:	f9a98993          	addi	s3,s3,-102 # 800256c8 <end>
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006736:	84ca                	mv	s1,s2
        fb[i] = kalloc();
    80006738:	ffffa097          	auipc	ra,0xffffa
    8000673c:	3ae080e7          	jalr	942(ra) # 80000ae6 <kalloc>
    80006740:	e088                	sd	a0,0(s1)
        if (!fb[i])
    80006742:	14050f63          	beqz	a0,800068a0 <virtio_gpu_init+0x32a>
        memset(fb[i], 0, PGSIZE); // fill with COLOR_BG (0 = black)
    80006746:	6605                	lui	a2,0x1
    80006748:	4581                	li	a1,0
    8000674a:	ffffa097          	auipc	ra,0xffffa
    8000674e:	588080e7          	jalr	1416(ra) # 80000cd2 <memset>
    for (int i = 0; i < FB_PAGES; i++)
    80006752:	04a1                	addi	s1,s1,8
    80006754:	ff3492e3          	bne	s1,s3,80006738 <virtio_gpu_init+0x1c2>
    memset(&create_req, 0, sizeof(create_req));
    80006758:	0001c497          	auipc	s1,0x1c
    8000675c:	f5848493          	addi	s1,s1,-168 # 800226b0 <gq>
    80006760:	0001c997          	auipc	s3,0x1c
    80006764:	01098993          	addi	s3,s3,16 # 80022770 <create_req.4>
    80006768:	02800613          	li	a2,40
    8000676c:	4581                	li	a1,0
    8000676e:	854e                	mv	a0,s3
    80006770:	ffffa097          	auipc	ra,0xffffa
    80006774:	562080e7          	jalr	1378(ra) # 80000cd2 <memset>
    create_req.hdr.type = VIRTIO_GPU_CMD_RESOURCE_CREATE_2D;
    80006778:	10100793          	li	a5,257
    8000677c:	0cf4a023          	sw	a5,192(s1)
    create_req.resource_id = RESOURCE_ID;
    80006780:	4785                	li	a5,1
    80006782:	0cf4ac23          	sw	a5,216(s1)
    create_req.format = VIRTIO_GPU_FORMAT_B8G8R8X8_UNORM;
    80006786:	4789                	li	a5,2
    80006788:	0cf4ae23          	sw	a5,220(s1)
    create_req.width = SCREEN_W;
    8000678c:	28000793          	li	a5,640
    80006790:	0ef4a023          	sw	a5,224(s1)
    create_req.height = SCREEN_H;
    80006794:	1e000793          	li	a5,480
    80006798:	0ef4a223          	sw	a5,228(s1)
    gpu_send(&create_req, sizeof(create_req));
    8000679c:	02800593          	li	a1,40
    800067a0:	854e                	mv	a0,s3
    800067a2:	00000097          	auipc	ra,0x0
    800067a6:	c10080e7          	jalr	-1008(ra) # 800063b2 <gpu_send>
    for (int i = 0; i < FB_PAGES; i++) {
    800067aa:	0001c597          	auipc	a1,0x1c
    800067ae:	01e58593          	addi	a1,a1,30 # 800227c8 <fb_entries.3>
    800067b2:	0001d697          	auipc	a3,0x1d
    800067b6:	2d668693          	addi	a3,a3,726 # 80023a88 <attach_buf>
    gpu_send(&create_req, sizeof(create_req));
    800067ba:	87ae                	mv	a5,a1
        fb_entries[i].length = PGSIZE;
    800067bc:	6605                	lui	a2,0x1
        fb_entries[i].addr   = (uint64)fb[i];
    800067be:	00093703          	ld	a4,0(s2)
    800067c2:	e398                	sd	a4,0(a5)
        fb_entries[i].length = PGSIZE;
    800067c4:	c790                	sw	a2,8(a5)
    for (int i = 0; i < FB_PAGES; i++) {
    800067c6:	0921                	addi	s2,s2,8
    800067c8:	07c1                	addi	a5,a5,16
    800067ca:	fed79ae3          	bne	a5,a3,800067be <virtio_gpu_init+0x248>
    attach_buf.backing.hdr.type = VIRTIO_GPU_CMD_RESOURCE_ATTACH_BACKING;
    800067ce:	0001d797          	auipc	a5,0x1d
    800067d2:	2ba78793          	addi	a5,a5,698 # 80023a88 <attach_buf>
    800067d6:	10600713          	li	a4,262
    800067da:	c398                	sw	a4,0(a5)
    attach_buf.backing.resource_id = RESOURCE_ID;
    800067dc:	4705                	li	a4,1
    800067de:	cf98                	sw	a4,24(a5)
    attach_buf.backing.nr_entries = n;
    800067e0:	12c00713          	li	a4,300
    800067e4:	cfd8                	sw	a4,28(a5)
    for (int i = 0; i < n; i++)
    800067e6:	0001d797          	auipc	a5,0x1d
    800067ea:	2c278793          	addi	a5,a5,706 # 80023aa8 <attach_buf+0x20>
        attach_buf.entries[i] = entries[i];
    800067ee:	6198                	ld	a4,0(a1)
    800067f0:	e398                	sd	a4,0(a5)
    800067f2:	6598                	ld	a4,8(a1)
    800067f4:	e798                	sd	a4,8(a5)
    for (int i = 0; i < n; i++)
    800067f6:	05c1                	addi	a1,a1,16
    800067f8:	07c1                	addi	a5,a5,16
    800067fa:	fed59ae3          	bne	a1,a3,800067ee <virtio_gpu_init+0x278>
    gpu_send(&attach_buf, sizeof(attach_buf));
    800067fe:	6585                	lui	a1,0x1
    80006800:	2e058593          	addi	a1,a1,736 # 12e0 <_entry-0x7fffed20>
    80006804:	0001d517          	auipc	a0,0x1d
    80006808:	28450513          	addi	a0,a0,644 # 80023a88 <attach_buf>
    8000680c:	00000097          	auipc	ra,0x0
    80006810:	ba6080e7          	jalr	-1114(ra) # 800063b2 <gpu_send>
        for (int i = 0; msg[i]; i++)
    80006814:	00002c17          	auipc	s8,0x2
    80006818:	134c0c13          	addi	s8,s8,308 # 80008948 <syscalls+0x500>
    gpu_send(&attach_buf, sizeof(attach_buf));
    8000681c:	0008cbb7          	lui	s7,0x8c
    80006820:	250b8b93          	addi	s7,s7,592 # 8c250 <_entry-0x7ff73db0>
        for (int i = 0; msg[i]; i++)
    80006824:	04800793          	li	a5,72
    const uint8 *rows = font8x8[ch];
    80006828:	00002c97          	auipc	s9,0x2
    8000682c:	168c8c93          	addi	s9,s9,360 # 80008990 <font8x8>
    80006830:	00024737          	lui	a4,0x24
    80006834:	a0070d93          	addi	s11,a4,-1536 # 23a00 <_entry-0x7ffdc600>
        for (int col = 0; col < 8; col++)
    80006838:	4d01                	li	s10,0
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    8000683a:	010004b7          	lui	s1,0x1000
    8000683e:	14fd                	addi	s1,s1,-1
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006840:	0001e897          	auipc	a7,0x1e
    80006844:	52888893          	addi	a7,a7,1320 # 80024d68 <fb>
    int off = byte_off % PGSIZE;
    80006848:	6805                	lui	a6,0x1
    8000684a:	187d                	addi	a6,a6,-1
            for (int dy = 0; dy < SCALE; dy++)
    8000684c:	6e05                	lui	t3,0x1
    8000684e:	a00e0e1b          	addiw	t3,t3,-1536
        for (int col = 0; col < 8; col++)
    80006852:	40a1                	li	ra,8
    for (int row = 0; row < 8; row++)
    80006854:	6a8d                	lui	s5,0x3
    80006856:	800a8a9b          	addiw	s5,s5,-2048
    8000685a:	10000b13          	li	s6,256
    8000685e:	a0f1                	j	8000692a <virtio_gpu_init+0x3b4>
        panic("virtio_gpu: FEATURES_OK not set");
    80006860:	00002517          	auipc	a0,0x2
    80006864:	03050513          	addi	a0,a0,48 # 80008890 <syscalls+0x448>
    80006868:	ffffa097          	auipc	ra,0xffffa
    8000686c:	cd6080e7          	jalr	-810(ra) # 8000053e <panic>
        panic("virtio_gpu: queue already ready");
    80006870:	00002517          	auipc	a0,0x2
    80006874:	04050513          	addi	a0,a0,64 # 800088b0 <syscalls+0x468>
    80006878:	ffffa097          	auipc	ra,0xffffa
    8000687c:	cc6080e7          	jalr	-826(ra) # 8000053e <panic>
        panic("virtio_gpu: queue too small");
    80006880:	00002517          	auipc	a0,0x2
    80006884:	05050513          	addi	a0,a0,80 # 800088d0 <syscalls+0x488>
    80006888:	ffffa097          	auipc	ra,0xffffa
    8000688c:	cb6080e7          	jalr	-842(ra) # 8000053e <panic>
        panic("virtio_gpu: kalloc failed for queue");
    80006890:	00002517          	auipc	a0,0x2
    80006894:	06050513          	addi	a0,a0,96 # 800088f0 <syscalls+0x4a8>
    80006898:	ffffa097          	auipc	ra,0xffffa
    8000689c:	ca6080e7          	jalr	-858(ra) # 8000053e <panic>
            panic("virtio_gpu: kalloc failed for framebuffer");
    800068a0:	00002517          	auipc	a0,0x2
    800068a4:	07850513          	addi	a0,a0,120 # 80008918 <syscalls+0x4d0>
    800068a8:	ffffa097          	auipc	ra,0xffffa
    800068ac:	c96080e7          	jalr	-874(ra) # 8000053e <panic>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    800068b0:	85fe                	mv	a1,t6
    800068b2:	831e                	mv	t1,t2
                for (int dx = 0; dx < SCALE; dx++)
    800068b4:	ff05869b          	addiw	a3,a1,-16
    int pg = byte_off / PGSIZE;
    800068b8:	43f6d613          	srai	a2,a3,0x3f
    800068bc:	0146561b          	srliw	a2,a2,0x14
    800068c0:	00d607bb          	addw	a5,a2,a3
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    800068c4:	40c7d71b          	sraiw	a4,a5,0xc
    800068c8:	070e                	slli	a4,a4,0x3
    800068ca:	9746                	add	a4,a4,a7
    int off = byte_off % PGSIZE;
    800068cc:	0107f7b3          	and	a5,a5,a6
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    800068d0:	9f91                	subw	a5,a5,a2
    *p = color;
    800068d2:	6310                	ld	a2,0(a4)
    800068d4:	97b2                	add	a5,a5,a2
    800068d6:	c388                	sw	a0,0(a5)
                for (int dx = 0; dx < SCALE; dx++)
    800068d8:	2691                	addiw	a3,a3,4
    800068da:	fcd59fe3          	bne	a1,a3,800068b8 <virtio_gpu_init+0x342>
            for (int dy = 0; dy < SCALE; dy++)
    800068de:	2803031b          	addiw	t1,t1,640
    800068e2:	00be05bb          	addw	a1,t3,a1
    800068e6:	fdd317e3          	bne	t1,t4,800068b4 <virtio_gpu_init+0x33e>
        for (int col = 0; col < 8; col++)
    800068ea:	2f05                	addiw	t5,t5,1
    800068ec:	2fc1                	addiw	t6,t6,16
    800068ee:	001f0a63          	beq	t5,ra,80006902 <virtio_gpu_init+0x38c>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    800068f2:	0002c503          	lbu	a0,0(t0)
    800068f6:	01e5553b          	srlw	a0,a0,t5
    800068fa:	8905                	andi	a0,a0,1
    800068fc:	d955                	beqz	a0,800068b0 <virtio_gpu_init+0x33a>
    800068fe:	8526                	mv	a0,s1
    80006900:	bf45                	j	800068b0 <virtio_gpu_init+0x33a>
    for (int row = 0; row < 8; row++)
    80006902:	01de0ebb          	addw	t4,t3,t4
    80006906:	012e093b          	addw	s2,t3,s2
    8000690a:	2991                	addiw	s3,s3,4
    8000690c:	014a8a3b          	addw	s4,s5,s4
    80006910:	0285                	addi	t0,t0,1
    80006912:	01698663          	beq	s3,s6,8000691e <virtio_gpu_init+0x3a8>
        for (int i = 0; msg[i]; i++)
    80006916:	8fd2                	mv	t6,s4
        for (int col = 0; col < 8; col++)
    80006918:	8f6a                	mv	t5,s10
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    8000691a:	83ca                	mv	t2,s2
    8000691c:	bfd9                	j	800068f2 <virtio_gpu_init+0x37c>
        for (int i = 0; msg[i]; i++)
    8000691e:	001c4783          	lbu	a5,1(s8)
    80006922:	0c05                	addi	s8,s8,1
    80006924:	080b8b9b          	addiw	s7,s7,128
    80006928:	cb99                	beqz	a5,8000693e <virtio_gpu_init+0x3c8>
    const uint8 *rows = font8x8[ch];
    8000692a:	078e                	slli	a5,a5,0x3
    8000692c:	019782b3          	add	t0,a5,s9
    80006930:	8a5e                	mv	s4,s7
    80006932:	0e000993          	li	s3,224
    80006936:	00023937          	lui	s2,0x23
    8000693a:	8eee                	mv	t4,s11
    8000693c:	bfe9                	j	80006916 <virtio_gpu_init+0x3a0>
    memset(&scanout_req, 0, sizeof(scanout_req));
    8000693e:	0001c497          	auipc	s1,0x1c
    80006942:	d7248493          	addi	s1,s1,-654 # 800226b0 <gq>
    80006946:	0001c917          	auipc	s2,0x1c
    8000694a:	e5290913          	addi	s2,s2,-430 # 80022798 <scanout_req.2>
    8000694e:	03000613          	li	a2,48
    80006952:	4581                	li	a1,0
    80006954:	854a                	mv	a0,s2
    80006956:	ffffa097          	auipc	ra,0xffffa
    8000695a:	37c080e7          	jalr	892(ra) # 80000cd2 <memset>
    scanout_req.hdr.type = VIRTIO_GPU_CMD_SET_SCANOUT;
    8000695e:	10300793          	li	a5,259
    80006962:	0ef4a423          	sw	a5,232(s1)
    scanout_req.r.x = 0;
    80006966:	1004a023          	sw	zero,256(s1)
    scanout_req.r.y = 0;
    8000696a:	1004a223          	sw	zero,260(s1)
    scanout_req.r.width = SCREEN_W;
    8000696e:	28000793          	li	a5,640
    80006972:	10f4a423          	sw	a5,264(s1)
    scanout_req.r.height = SCREEN_H;
    80006976:	1e000793          	li	a5,480
    8000697a:	10f4a623          	sw	a5,268(s1)
    scanout_req.scanout_id = SCANOUT_ID;
    8000697e:	1004a823          	sw	zero,272(s1)
    scanout_req.resource_id = RESOURCE_ID;
    80006982:	4785                	li	a5,1
    80006984:	10f4aa23          	sw	a5,276(s1)
    gpu_send(&scanout_req, sizeof(scanout_req));
    80006988:	03000593          	li	a1,48
    8000698c:	854a                	mv	a0,s2
    8000698e:	00000097          	auipc	ra,0x0
    80006992:	a24080e7          	jalr	-1500(ra) # 800063b2 <gpu_send>
    gpu_transfer_flush();
    80006996:	00000097          	auipc	ra,0x0
    8000699a:	b28080e7          	jalr	-1240(ra) # 800064be <gpu_transfer_flush>
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
    8000699e:	00002517          	auipc	a0,0x2
    800069a2:	fba50513          	addi	a0,a0,-70 # 80008958 <syscalls+0x510>
    800069a6:	ffffa097          	auipc	ra,0xffffa
    800069aa:	be2080e7          	jalr	-1054(ra) # 80000588 <printf>
    800069ae:	b989                	j	80006600 <virtio_gpu_init+0x8a>

00000000800069b0 <virtio_gpu_commit>:

// ── Public: flush the kernel fb[] to the display ─────────────────────
// Called by display_daemon.  Sends TRANSFER_TO_HOST_2D + RESOURCE_FLUSH.
void virtio_gpu_commit(void)
{
    800069b0:	1141                	addi	sp,sp,-16
    800069b2:	e406                	sd	ra,8(sp)
    800069b4:	e022                	sd	s0,0(sp)
    800069b6:	0800                	addi	s0,sp,16
    gpu_transfer_flush();
    800069b8:	00000097          	auipc	ra,0x0
    800069bc:	b06080e7          	jalr	-1274(ra) # 800064be <gpu_transfer_flush>
}
    800069c0:	60a2                	ld	ra,8(sp)
    800069c2:	6402                	ld	s0,0(sp)
    800069c4:	0141                	addi	sp,sp,16
    800069c6:	8082                	ret

00000000800069c8 <display_daemon>:
// Commit period: DISPLAY_DAEMON_TICKS ticks.  xv6's timer fires every
// ~1/10th of a second at QEMU's default rate, giving ~10fps.
#define DISPLAY_DAEMON_TICKS 1

void display_daemon(void)
{
    800069c8:	7179                	addi	sp,sp,-48
    800069ca:	f406                	sd	ra,40(sp)
    800069cc:	f022                	sd	s0,32(sp)
    800069ce:	ec26                	sd	s1,24(sp)
    800069d0:	e84a                	sd	s2,16(sp)
    800069d2:	e44e                	sd	s3,8(sp)
    800069d4:	1800                	addi	s0,sp,48
    // The scheduler holds p->lock across swtch into a new process.
    // Release it here, just like forkret does for user processes.
    struct proc *p = myproc();
    800069d6:	ffffb097          	auipc	ra,0xffffb
    800069da:	00e080e7          	jalr	14(ra) # 800019e4 <myproc>
    release(&p->lock);
    800069de:	ffffa097          	auipc	ra,0xffffa
    800069e2:	2ac080e7          	jalr	684(ra) # 80000c8a <release>

    acquire(&tickslock);
    800069e6:	00011517          	auipc	a0,0x11
    800069ea:	8ea50513          	addi	a0,a0,-1814 # 800172d0 <tickslock>
    800069ee:	ffffa097          	auipc	ra,0xffffa
    800069f2:	1e8080e7          	jalr	488(ra) # 80000bd6 <acquire>
    for (;;)
    {
        // Sleep until DISPLAY_DAEMON_TICKS ticks have elapsed.
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    800069f6:	00003917          	auipc	s2,0x3
    800069fa:	83a90913          	addi	s2,s2,-1990 # 80009230 <ticks>
        while (ticks < deadline)
            sleep(&ticks, &tickslock);
    800069fe:	00011497          	auipc	s1,0x11
    80006a02:	8d248493          	addi	s1,s1,-1838 # 800172d0 <tickslock>
    80006a06:	a839                	j	80006a24 <display_daemon+0x5c>

        release(&tickslock);
    80006a08:	8526                	mv	a0,s1
    80006a0a:	ffffa097          	auipc	ra,0xffffa
    80006a0e:	280080e7          	jalr	640(ra) # 80000c8a <release>
    gpu_transfer_flush();
    80006a12:	00000097          	auipc	ra,0x0
    80006a16:	aac080e7          	jalr	-1364(ra) # 800064be <gpu_transfer_flush>
        virtio_gpu_commit();
        acquire(&tickslock);
    80006a1a:	8526                	mv	a0,s1
    80006a1c:	ffffa097          	auipc	ra,0xffffa
    80006a20:	1ba080e7          	jalr	442(ra) # 80000bd6 <acquire>
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006a24:	00092783          	lw	a5,0(s2)
    80006a28:	0017899b          	addiw	s3,a5,1
        while (ticks < deadline)
    80006a2c:	fd37fee3          	bgeu	a5,s3,80006a08 <display_daemon+0x40>
            sleep(&ticks, &tickslock);
    80006a30:	85a6                	mv	a1,s1
    80006a32:	854a                	mv	a0,s2
    80006a34:	ffffb097          	auipc	ra,0xffffb
    80006a38:	6be080e7          	jalr	1726(ra) # 800020f2 <sleep>
        while (ticks < deadline)
    80006a3c:	00092783          	lw	a5,0(s2)
    80006a40:	ff37e8e3          	bltu	a5,s3,80006a30 <display_daemon+0x68>
    80006a44:	b7d1                	j	80006a08 <display_daemon+0x40>

0000000080006a46 <get_fb_addr>:
    }
}

void*
get_fb_addr(void)
{
    80006a46:	1141                	addi	sp,sp,-16
    80006a48:	e422                	sd	s0,8(sp)
    80006a4a:	0800                	addi	s0,sp,16
  return (void*)fb;
}
    80006a4c:	0001e517          	auipc	a0,0x1e
    80006a50:	31c50513          	addi	a0,a0,796 # 80024d68 <fb>
    80006a54:	6422                	ld	s0,8(sp)
    80006a56:	0141                	addi	sp,sp,16
    80006a58:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
