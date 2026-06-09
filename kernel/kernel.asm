
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	2f013103          	ld	sp,752(sp) # 800092f0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	2fe70713          	addi	a4,a4,766 # 80009350 <timer_scratch>
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
    80000068:	dbc78793          	addi	a5,a5,-580 # 80005e20 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd8e27>
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
    80000130:	454080e7          	jalr	1108(ra) # 80002580 <either_copyin>
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
    8000018e:	30650513          	addi	a0,a0,774 # 80011490 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	2f648493          	addi	s1,s1,758 # 80011490 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	38690913          	addi	s2,s2,902 # 80011528 <cons+0x98>
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
    800001c4:	822080e7          	jalr	-2014(ra) # 800019e2 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	202080e7          	jalr	514(ra) # 800023ca <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	f4c080e7          	jalr	-180(ra) # 80002122 <sleep>
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
    80000216:	318080e7          	jalr	792(ra) # 8000252a <either_copyout>
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
    8000022a:	26a50513          	addi	a0,a0,618 # 80011490 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	25450513          	addi	a0,a0,596 # 80011490 <cons>
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
    80000276:	2af72b23          	sw	a5,694(a4) # 80011528 <cons+0x98>
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
    800002d0:	1c450513          	addi	a0,a0,452 # 80011490 <cons>
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
    800002f6:	2e4080e7          	jalr	740(ra) # 800025d6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	19650513          	addi	a0,a0,406 # 80011490 <cons>
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
    80000322:	17270713          	addi	a4,a4,370 # 80011490 <cons>
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
    8000034c:	14878793          	addi	a5,a5,328 # 80011490 <cons>
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
    8000037a:	1b27a783          	lw	a5,434(a5) # 80011528 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	10670713          	addi	a4,a4,262 # 80011490 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	0f648493          	addi	s1,s1,246 # 80011490 <cons>
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
    800003da:	0ba70713          	addi	a4,a4,186 # 80011490 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	14f72223          	sw	a5,324(a4) # 80011530 <cons+0xa0>
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
    80000416:	07e78793          	addi	a5,a5,126 # 80011490 <cons>
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
    8000043a:	0ec7ab23          	sw	a2,246(a5) # 8001152c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	0ea50513          	addi	a0,a0,234 # 80011528 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d40080e7          	jalr	-704(ra) # 80002186 <wakeup>
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
    80000464:	03050513          	addi	a0,a0,48 # 80011490 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	3b078793          	addi	a5,a5,944 # 80021828 <devsw>
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
    8000054e:	0007a323          	sw	zero,6(a5) # 80011550 <pr+0x18>
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
    80000570:	d8c50513          	addi	a0,a0,-628 # 800082f8 <digits+0x2b8>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	d8f72923          	sw	a5,-622(a4) # 80009310 <panicked>
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
    800005be:	f96dad83          	lw	s11,-106(s11) # 80011550 <pr+0x18>
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
    800005fc:	f4050513          	addi	a0,a0,-192 # 80011538 <pr>
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
    8000075a:	de250513          	addi	a0,a0,-542 # 80011538 <pr>
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
    80000776:	dc648493          	addi	s1,s1,-570 # 80011538 <pr>
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
    800007d6:	d8650513          	addi	a0,a0,-634 # 80011558 <uart_tx_lock>
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
    80000802:	b127a783          	lw	a5,-1262(a5) # 80009310 <panicked>
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
    8000083a:	ae27b783          	ld	a5,-1310(a5) # 80009318 <uart_tx_r>
    8000083e:	00009717          	auipc	a4,0x9
    80000842:	ae273703          	ld	a4,-1310(a4) # 80009320 <uart_tx_w>
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
    80000864:	cf8a0a13          	addi	s4,s4,-776 # 80011558 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00009497          	auipc	s1,0x9
    8000086c:	ab048493          	addi	s1,s1,-1360 # 80009318 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00009997          	auipc	s3,0x9
    80000874:	ab098993          	addi	s3,s3,-1360 # 80009320 <uart_tx_w>
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
    80000896:	8f4080e7          	jalr	-1804(ra) # 80002186 <wakeup>
    
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
    800008d2:	c8a50513          	addi	a0,a0,-886 # 80011558 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00009797          	auipc	a5,0x9
    800008e2:	a327a783          	lw	a5,-1486(a5) # 80009310 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00009717          	auipc	a4,0x9
    800008ec:	a3873703          	ld	a4,-1480(a4) # 80009320 <uart_tx_w>
    800008f0:	00009797          	auipc	a5,0x9
    800008f4:	a287b783          	ld	a5,-1496(a5) # 80009318 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00011997          	auipc	s3,0x11
    80000900:	c5c98993          	addi	s3,s3,-932 # 80011558 <uart_tx_lock>
    80000904:	00009497          	auipc	s1,0x9
    80000908:	a1448493          	addi	s1,s1,-1516 # 80009318 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00009917          	auipc	s2,0x9
    80000910:	a1490913          	addi	s2,s2,-1516 # 80009320 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	806080e7          	jalr	-2042(ra) # 80002122 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00011497          	auipc	s1,0x11
    80000936:	c2648493          	addi	s1,s1,-986 # 80011558 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00009797          	auipc	a5,0x9
    8000094a:	9ce7bd23          	sd	a4,-1574(a5) # 80009320 <uart_tx_w>
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
    800009c0:	b9c48493          	addi	s1,s1,-1124 # 80011558 <uart_tx_lock>
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
    80000a02:	fda78793          	addi	a5,a5,-38 # 800259d8 <end>
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
    80000a22:	b7290913          	addi	s2,s2,-1166 # 80011590 <kmem>
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
    80000abe:	ad650513          	addi	a0,a0,-1322 # 80011590 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00025517          	auipc	a0,0x25
    80000ad2:	f0a50513          	addi	a0,a0,-246 # 800259d8 <end>
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
    80000af4:	aa048493          	addi	s1,s1,-1376 # 80011590 <kmem>
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
    80000b0c:	a8850513          	addi	a0,a0,-1400 # 80011590 <kmem>
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
    80000b38:	a5c50513          	addi	a0,a0,-1444 # 80011590 <kmem>
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
    80000b74:	e56080e7          	jalr	-426(ra) # 800019c6 <mycpu>
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
    80000ba6:	e24080e7          	jalr	-476(ra) # 800019c6 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	e18080e7          	jalr	-488(ra) # 800019c6 <mycpu>
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
    80000bca:	e00080e7          	jalr	-512(ra) # 800019c6 <mycpu>
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
    80000c0a:	dc0080e7          	jalr	-576(ra) # 800019c6 <mycpu>
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
    80000c36:	d94080e7          	jalr	-620(ra) # 800019c6 <mycpu>
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
    80000e84:	b36080e7          	jalr	-1226(ra) # 800019b6 <cpuid>
    userinit();      // first user process
    kproc_create(display_daemon, "displaydaemon"); // GPU auto-commit daemon
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	4a070713          	addi	a4,a4,1184 # 80009328 <started>
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
    80000ea0:	b1a080e7          	jalr	-1254(ra) # 800019b6 <cpuid>
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
    80000ec2:	9c0080e7          	jalr	-1600(ra) # 8000287e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	f9a080e7          	jalr	-102(ra) # 80005e60 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	0a2080e7          	jalr	162(ra) # 80001f70 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	41250513          	addi	a0,a0,1042 # 800082f8 <digits+0x2b8>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	3f250513          	addi	a0,a0,1010 # 800082f8 <digits+0x2b8>
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
    80000f32:	9d4080e7          	jalr	-1580(ra) # 80001902 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	920080e7          	jalr	-1760(ra) # 80002856 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	940080e7          	jalr	-1728(ra) # 8000287e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	f04080e7          	jalr	-252(ra) # 80005e4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	f12080e7          	jalr	-238(ra) # 80005e60 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	0ba080e7          	jalr	186(ra) # 80003010 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	75e080e7          	jalr	1886(ra) # 800036bc <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	6fc080e7          	jalr	1788(ra) # 80004662 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	ffa080e7          	jalr	-6(ra) # 80005f68 <virtio_disk_init>
    virtio_gpu_init();  // virtio GPU display window
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	700080e7          	jalr	1792(ra) # 80006676 <virtio_gpu_init>
    userinit();      // first user process
    80000f7e:	00001097          	auipc	ra,0x1
    80000f82:	d6e080e7          	jalr	-658(ra) # 80001cec <userinit>
    kproc_create(display_daemon, "displaydaemon"); // GPU auto-commit daemon
    80000f86:	00007597          	auipc	a1,0x7
    80000f8a:	13258593          	addi	a1,a1,306 # 800080b8 <digits+0x78>
    80000f8e:	00006517          	auipc	a0,0x6
    80000f92:	b3a50513          	addi	a0,a0,-1222 # 80006ac8 <display_daemon>
    80000f96:	00001097          	auipc	ra,0x1
    80000f9a:	dd8080e7          	jalr	-552(ra) # 80001d6e <kproc_create>
    __sync_synchronize();
    80000f9e:	0ff0000f          	fence
    started = 1;
    80000fa2:	4785                	li	a5,1
    80000fa4:	00008717          	auipc	a4,0x8
    80000fa8:	38f72223          	sw	a5,900(a4) # 80009328 <started>
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
    80000fbc:	3787b783          	ld	a5,888(a5) # 80009330 <kernel_pagetable>
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
    80001268:	608080e7          	jalr	1544(ra) # 8000186c <proc_mapstacks>
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
    8000128e:	0aa7b323          	sd	a0,166(a5) # 80009330 <kernel_pagetable>
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
    8000129a:	715d                	addi	sp,sp,-80
    8000129c:	e486                	sd	ra,72(sp)
    8000129e:	e0a2                	sd	s0,64(sp)
    800012a0:	fc26                	sd	s1,56(sp)
    800012a2:	f84a                	sd	s2,48(sp)
    800012a4:	f44e                	sd	s3,40(sp)
    800012a6:	f052                	sd	s4,32(sp)
    800012a8:	ec56                	sd	s5,24(sp)
    800012aa:	e85a                	sd	s6,16(sp)
    800012ac:	e45e                	sd	s7,8(sp)
    800012ae:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012b0:	03459793          	slli	a5,a1,0x34
    800012b4:	e795                	bnez	a5,800012e0 <uvmunmap+0x46>
    800012b6:	8a2a                	mv	s4,a0
    800012b8:	892e                	mv	s2,a1
    800012ba:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012bc:	0632                	slli	a2,a2,0xc
    800012be:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012c2:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c4:	6b05                	lui	s6,0x1
    800012c6:	0735e263          	bltu	a1,s3,8000132a <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ca:	60a6                	ld	ra,72(sp)
    800012cc:	6406                	ld	s0,64(sp)
    800012ce:	74e2                	ld	s1,56(sp)
    800012d0:	7942                	ld	s2,48(sp)
    800012d2:	79a2                	ld	s3,40(sp)
    800012d4:	7a02                	ld	s4,32(sp)
    800012d6:	6ae2                	ld	s5,24(sp)
    800012d8:	6b42                	ld	s6,16(sp)
    800012da:	6ba2                	ld	s7,8(sp)
    800012dc:	6161                	addi	sp,sp,80
    800012de:	8082                	ret
    panic("uvmunmap: not aligned");
    800012e0:	00007517          	auipc	a0,0x7
    800012e4:	e3050513          	addi	a0,a0,-464 # 80008110 <digits+0xd0>
    800012e8:	fffff097          	auipc	ra,0xfffff
    800012ec:	256080e7          	jalr	598(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012f0:	00007517          	auipc	a0,0x7
    800012f4:	e3850513          	addi	a0,a0,-456 # 80008128 <digits+0xe8>
    800012f8:	fffff097          	auipc	ra,0xfffff
    800012fc:	246080e7          	jalr	582(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001300:	00007517          	auipc	a0,0x7
    80001304:	e3850513          	addi	a0,a0,-456 # 80008138 <digits+0xf8>
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	236080e7          	jalr	566(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001310:	00007517          	auipc	a0,0x7
    80001314:	e4050513          	addi	a0,a0,-448 # 80008150 <digits+0x110>
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	226080e7          	jalr	550(ra) # 8000053e <panic>
    *pte = 0;
    80001320:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001324:	995a                	add	s2,s2,s6
    80001326:	fb3972e3          	bgeu	s2,s3,800012ca <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000132a:	4601                	li	a2,0
    8000132c:	85ca                	mv	a1,s2
    8000132e:	8552                	mv	a0,s4
    80001330:	00000097          	auipc	ra,0x0
    80001334:	ca6080e7          	jalr	-858(ra) # 80000fd6 <walk>
    80001338:	84aa                	mv	s1,a0
    8000133a:	d95d                	beqz	a0,800012f0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000133c:	6108                	ld	a0,0(a0)
    8000133e:	00157793          	andi	a5,a0,1
    80001342:	dfdd                	beqz	a5,80001300 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001344:	3ff57793          	andi	a5,a0,1023
    80001348:	fd7784e3          	beq	a5,s7,80001310 <uvmunmap+0x76>
    if(do_free){
    8000134c:	fc0a8ae3          	beqz	s5,80001320 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001350:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001352:	0532                	slli	a0,a0,0xc
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	696080e7          	jalr	1686(ra) # 800009ea <kfree>
    8000135c:	b7d1                	j	80001320 <uvmunmap+0x86>

000000008000135e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000135e:	1101                	addi	sp,sp,-32
    80001360:	ec06                	sd	ra,24(sp)
    80001362:	e822                	sd	s0,16(sp)
    80001364:	e426                	sd	s1,8(sp)
    80001366:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	77e080e7          	jalr	1918(ra) # 80000ae6 <kalloc>
    80001370:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001372:	c519                	beqz	a0,80001380 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001374:	6605                	lui	a2,0x1
    80001376:	4581                	li	a1,0
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	95a080e7          	jalr	-1702(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001380:	8526                	mv	a0,s1
    80001382:	60e2                	ld	ra,24(sp)
    80001384:	6442                	ld	s0,16(sp)
    80001386:	64a2                	ld	s1,8(sp)
    80001388:	6105                	addi	sp,sp,32
    8000138a:	8082                	ret

000000008000138c <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000138c:	7179                	addi	sp,sp,-48
    8000138e:	f406                	sd	ra,40(sp)
    80001390:	f022                	sd	s0,32(sp)
    80001392:	ec26                	sd	s1,24(sp)
    80001394:	e84a                	sd	s2,16(sp)
    80001396:	e44e                	sd	s3,8(sp)
    80001398:	e052                	sd	s4,0(sp)
    8000139a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000139c:	6785                	lui	a5,0x1
    8000139e:	04f67863          	bgeu	a2,a5,800013ee <uvmfirst+0x62>
    800013a2:	8a2a                	mv	s4,a0
    800013a4:	89ae                	mv	s3,a1
    800013a6:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	73e080e7          	jalr	1854(ra) # 80000ae6 <kalloc>
    800013b0:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013b2:	6605                	lui	a2,0x1
    800013b4:	4581                	li	a1,0
    800013b6:	00000097          	auipc	ra,0x0
    800013ba:	91c080e7          	jalr	-1764(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013be:	4779                	li	a4,30
    800013c0:	86ca                	mv	a3,s2
    800013c2:	6605                	lui	a2,0x1
    800013c4:	4581                	li	a1,0
    800013c6:	8552                	mv	a0,s4
    800013c8:	00000097          	auipc	ra,0x0
    800013cc:	cf6080e7          	jalr	-778(ra) # 800010be <mappages>
  memmove(mem, src, sz);
    800013d0:	8626                	mv	a2,s1
    800013d2:	85ce                	mv	a1,s3
    800013d4:	854a                	mv	a0,s2
    800013d6:	00000097          	auipc	ra,0x0
    800013da:	958080e7          	jalr	-1704(ra) # 80000d2e <memmove>
}
    800013de:	70a2                	ld	ra,40(sp)
    800013e0:	7402                	ld	s0,32(sp)
    800013e2:	64e2                	ld	s1,24(sp)
    800013e4:	6942                	ld	s2,16(sp)
    800013e6:	69a2                	ld	s3,8(sp)
    800013e8:	6a02                	ld	s4,0(sp)
    800013ea:	6145                	addi	sp,sp,48
    800013ec:	8082                	ret
    panic("uvmfirst: more than a page");
    800013ee:	00007517          	auipc	a0,0x7
    800013f2:	d7a50513          	addi	a0,a0,-646 # 80008168 <digits+0x128>
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	148080e7          	jalr	328(ra) # 8000053e <panic>

00000000800013fe <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013fe:	1101                	addi	sp,sp,-32
    80001400:	ec06                	sd	ra,24(sp)
    80001402:	e822                	sd	s0,16(sp)
    80001404:	e426                	sd	s1,8(sp)
    80001406:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001408:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000140a:	00b67d63          	bgeu	a2,a1,80001424 <uvmdealloc+0x26>
    8000140e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001410:	6785                	lui	a5,0x1
    80001412:	17fd                	addi	a5,a5,-1
    80001414:	00f60733          	add	a4,a2,a5
    80001418:	767d                	lui	a2,0xfffff
    8000141a:	8f71                	and	a4,a4,a2
    8000141c:	97ae                	add	a5,a5,a1
    8000141e:	8ff1                	and	a5,a5,a2
    80001420:	00f76863          	bltu	a4,a5,80001430 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001424:	8526                	mv	a0,s1
    80001426:	60e2                	ld	ra,24(sp)
    80001428:	6442                	ld	s0,16(sp)
    8000142a:	64a2                	ld	s1,8(sp)
    8000142c:	6105                	addi	sp,sp,32
    8000142e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001430:	8f99                	sub	a5,a5,a4
    80001432:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001434:	4685                	li	a3,1
    80001436:	0007861b          	sext.w	a2,a5
    8000143a:	85ba                	mv	a1,a4
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	e5e080e7          	jalr	-418(ra) # 8000129a <uvmunmap>
    80001444:	b7c5                	j	80001424 <uvmdealloc+0x26>

0000000080001446 <uvmalloc>:
  if(newsz < oldsz)
    80001446:	0ab66563          	bltu	a2,a1,800014f0 <uvmalloc+0xaa>
{
    8000144a:	7139                	addi	sp,sp,-64
    8000144c:	fc06                	sd	ra,56(sp)
    8000144e:	f822                	sd	s0,48(sp)
    80001450:	f426                	sd	s1,40(sp)
    80001452:	f04a                	sd	s2,32(sp)
    80001454:	ec4e                	sd	s3,24(sp)
    80001456:	e852                	sd	s4,16(sp)
    80001458:	e456                	sd	s5,8(sp)
    8000145a:	e05a                	sd	s6,0(sp)
    8000145c:	0080                	addi	s0,sp,64
    8000145e:	8aaa                	mv	s5,a0
    80001460:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001462:	6985                	lui	s3,0x1
    80001464:	19fd                	addi	s3,s3,-1
    80001466:	95ce                	add	a1,a1,s3
    80001468:	79fd                	lui	s3,0xfffff
    8000146a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	08c9f363          	bgeu	s3,a2,800014f4 <uvmalloc+0xae>
    80001472:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001474:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001478:	fffff097          	auipc	ra,0xfffff
    8000147c:	66e080e7          	jalr	1646(ra) # 80000ae6 <kalloc>
    80001480:	84aa                	mv	s1,a0
    if(mem == 0){
    80001482:	c51d                	beqz	a0,800014b0 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001484:	6605                	lui	a2,0x1
    80001486:	4581                	li	a1,0
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	84a080e7          	jalr	-1974(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001490:	875a                	mv	a4,s6
    80001492:	86a6                	mv	a3,s1
    80001494:	6605                	lui	a2,0x1
    80001496:	85ca                	mv	a1,s2
    80001498:	8556                	mv	a0,s5
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	c24080e7          	jalr	-988(ra) # 800010be <mappages>
    800014a2:	e90d                	bnez	a0,800014d4 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a4:	6785                	lui	a5,0x1
    800014a6:	993e                	add	s2,s2,a5
    800014a8:	fd4968e3          	bltu	s2,s4,80001478 <uvmalloc+0x32>
  return newsz;
    800014ac:	8552                	mv	a0,s4
    800014ae:	a809                	j	800014c0 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014b0:	864e                	mv	a2,s3
    800014b2:	85ca                	mv	a1,s2
    800014b4:	8556                	mv	a0,s5
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	f48080e7          	jalr	-184(ra) # 800013fe <uvmdealloc>
      return 0;
    800014be:	4501                	li	a0,0
}
    800014c0:	70e2                	ld	ra,56(sp)
    800014c2:	7442                	ld	s0,48(sp)
    800014c4:	74a2                	ld	s1,40(sp)
    800014c6:	7902                	ld	s2,32(sp)
    800014c8:	69e2                	ld	s3,24(sp)
    800014ca:	6a42                	ld	s4,16(sp)
    800014cc:	6aa2                	ld	s5,8(sp)
    800014ce:	6b02                	ld	s6,0(sp)
    800014d0:	6121                	addi	sp,sp,64
    800014d2:	8082                	ret
      kfree(mem);
    800014d4:	8526                	mv	a0,s1
    800014d6:	fffff097          	auipc	ra,0xfffff
    800014da:	514080e7          	jalr	1300(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014de:	864e                	mv	a2,s3
    800014e0:	85ca                	mv	a1,s2
    800014e2:	8556                	mv	a0,s5
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	f1a080e7          	jalr	-230(ra) # 800013fe <uvmdealloc>
      return 0;
    800014ec:	4501                	li	a0,0
    800014ee:	bfc9                	j	800014c0 <uvmalloc+0x7a>
    return oldsz;
    800014f0:	852e                	mv	a0,a1
}
    800014f2:	8082                	ret
  return newsz;
    800014f4:	8532                	mv	a0,a2
    800014f6:	b7e9                	j	800014c0 <uvmalloc+0x7a>

00000000800014f8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014f8:	7179                	addi	sp,sp,-48
    800014fa:	f406                	sd	ra,40(sp)
    800014fc:	f022                	sd	s0,32(sp)
    800014fe:	ec26                	sd	s1,24(sp)
    80001500:	e84a                	sd	s2,16(sp)
    80001502:	e44e                	sd	s3,8(sp)
    80001504:	e052                	sd	s4,0(sp)
    80001506:	1800                	addi	s0,sp,48
    80001508:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000150a:	84aa                	mv	s1,a0
    8000150c:	6905                	lui	s2,0x1
    8000150e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001510:	4985                	li	s3,1
    80001512:	a821                	j	8000152a <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001514:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001516:	0532                	slli	a0,a0,0xc
    80001518:	00000097          	auipc	ra,0x0
    8000151c:	fe0080e7          	jalr	-32(ra) # 800014f8 <freewalk>
      pagetable[i] = 0;
    80001520:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001524:	04a1                	addi	s1,s1,8
    80001526:	03248163          	beq	s1,s2,80001548 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000152a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000152c:	00f57793          	andi	a5,a0,15
    80001530:	ff3782e3          	beq	a5,s3,80001514 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001534:	8905                	andi	a0,a0,1
    80001536:	d57d                	beqz	a0,80001524 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001538:	00007517          	auipc	a0,0x7
    8000153c:	c5050513          	addi	a0,a0,-944 # 80008188 <digits+0x148>
    80001540:	fffff097          	auipc	ra,0xfffff
    80001544:	ffe080e7          	jalr	-2(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001548:	8552                	mv	a0,s4
    8000154a:	fffff097          	auipc	ra,0xfffff
    8000154e:	4a0080e7          	jalr	1184(ra) # 800009ea <kfree>
}
    80001552:	70a2                	ld	ra,40(sp)
    80001554:	7402                	ld	s0,32(sp)
    80001556:	64e2                	ld	s1,24(sp)
    80001558:	6942                	ld	s2,16(sp)
    8000155a:	69a2                	ld	s3,8(sp)
    8000155c:	6a02                	ld	s4,0(sp)
    8000155e:	6145                	addi	sp,sp,48
    80001560:	8082                	ret

0000000080001562 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001562:	1101                	addi	sp,sp,-32
    80001564:	ec06                	sd	ra,24(sp)
    80001566:	e822                	sd	s0,16(sp)
    80001568:	e426                	sd	s1,8(sp)
    8000156a:	1000                	addi	s0,sp,32
    8000156c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000156e:	e999                	bnez	a1,80001584 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001570:	8526                	mv	a0,s1
    80001572:	00000097          	auipc	ra,0x0
    80001576:	f86080e7          	jalr	-122(ra) # 800014f8 <freewalk>
}
    8000157a:	60e2                	ld	ra,24(sp)
    8000157c:	6442                	ld	s0,16(sp)
    8000157e:	64a2                	ld	s1,8(sp)
    80001580:	6105                	addi	sp,sp,32
    80001582:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001584:	6605                	lui	a2,0x1
    80001586:	167d                	addi	a2,a2,-1
    80001588:	962e                	add	a2,a2,a1
    8000158a:	4685                	li	a3,1
    8000158c:	8231                	srli	a2,a2,0xc
    8000158e:	4581                	li	a1,0
    80001590:	00000097          	auipc	ra,0x0
    80001594:	d0a080e7          	jalr	-758(ra) # 8000129a <uvmunmap>
    80001598:	bfe1                	j	80001570 <uvmfree+0xe>

000000008000159a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000159a:	c679                	beqz	a2,80001668 <uvmcopy+0xce>
{
    8000159c:	715d                	addi	sp,sp,-80
    8000159e:	e486                	sd	ra,72(sp)
    800015a0:	e0a2                	sd	s0,64(sp)
    800015a2:	fc26                	sd	s1,56(sp)
    800015a4:	f84a                	sd	s2,48(sp)
    800015a6:	f44e                	sd	s3,40(sp)
    800015a8:	f052                	sd	s4,32(sp)
    800015aa:	ec56                	sd	s5,24(sp)
    800015ac:	e85a                	sd	s6,16(sp)
    800015ae:	e45e                	sd	s7,8(sp)
    800015b0:	0880                	addi	s0,sp,80
    800015b2:	8b2a                	mv	s6,a0
    800015b4:	8aae                	mv	s5,a1
    800015b6:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015b8:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015ba:	4601                	li	a2,0
    800015bc:	85ce                	mv	a1,s3
    800015be:	855a                	mv	a0,s6
    800015c0:	00000097          	auipc	ra,0x0
    800015c4:	a16080e7          	jalr	-1514(ra) # 80000fd6 <walk>
    800015c8:	c531                	beqz	a0,80001614 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015ca:	6118                	ld	a4,0(a0)
    800015cc:	00177793          	andi	a5,a4,1
    800015d0:	cbb1                	beqz	a5,80001624 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015d2:	00a75593          	srli	a1,a4,0xa
    800015d6:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015da:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015de:	fffff097          	auipc	ra,0xfffff
    800015e2:	508080e7          	jalr	1288(ra) # 80000ae6 <kalloc>
    800015e6:	892a                	mv	s2,a0
    800015e8:	c939                	beqz	a0,8000163e <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015ea:	6605                	lui	a2,0x1
    800015ec:	85de                	mv	a1,s7
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	740080e7          	jalr	1856(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015f6:	8726                	mv	a4,s1
    800015f8:	86ca                	mv	a3,s2
    800015fa:	6605                	lui	a2,0x1
    800015fc:	85ce                	mv	a1,s3
    800015fe:	8556                	mv	a0,s5
    80001600:	00000097          	auipc	ra,0x0
    80001604:	abe080e7          	jalr	-1346(ra) # 800010be <mappages>
    80001608:	e515                	bnez	a0,80001634 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000160a:	6785                	lui	a5,0x1
    8000160c:	99be                	add	s3,s3,a5
    8000160e:	fb49e6e3          	bltu	s3,s4,800015ba <uvmcopy+0x20>
    80001612:	a081                	j	80001652 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001614:	00007517          	auipc	a0,0x7
    80001618:	b8450513          	addi	a0,a0,-1148 # 80008198 <digits+0x158>
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	f22080e7          	jalr	-222(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001624:	00007517          	auipc	a0,0x7
    80001628:	b9450513          	addi	a0,a0,-1132 # 800081b8 <digits+0x178>
    8000162c:	fffff097          	auipc	ra,0xfffff
    80001630:	f12080e7          	jalr	-238(ra) # 8000053e <panic>
      kfree(mem);
    80001634:	854a                	mv	a0,s2
    80001636:	fffff097          	auipc	ra,0xfffff
    8000163a:	3b4080e7          	jalr	948(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000163e:	4685                	li	a3,1
    80001640:	00c9d613          	srli	a2,s3,0xc
    80001644:	4581                	li	a1,0
    80001646:	8556                	mv	a0,s5
    80001648:	00000097          	auipc	ra,0x0
    8000164c:	c52080e7          	jalr	-942(ra) # 8000129a <uvmunmap>
  return -1;
    80001650:	557d                	li	a0,-1
}
    80001652:	60a6                	ld	ra,72(sp)
    80001654:	6406                	ld	s0,64(sp)
    80001656:	74e2                	ld	s1,56(sp)
    80001658:	7942                	ld	s2,48(sp)
    8000165a:	79a2                	ld	s3,40(sp)
    8000165c:	7a02                	ld	s4,32(sp)
    8000165e:	6ae2                	ld	s5,24(sp)
    80001660:	6b42                	ld	s6,16(sp)
    80001662:	6ba2                	ld	s7,8(sp)
    80001664:	6161                	addi	sp,sp,80
    80001666:	8082                	ret
  return 0;
    80001668:	4501                	li	a0,0
}
    8000166a:	8082                	ret

000000008000166c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000166c:	1141                	addi	sp,sp,-16
    8000166e:	e406                	sd	ra,8(sp)
    80001670:	e022                	sd	s0,0(sp)
    80001672:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001674:	4601                	li	a2,0
    80001676:	00000097          	auipc	ra,0x0
    8000167a:	960080e7          	jalr	-1696(ra) # 80000fd6 <walk>
  if(pte == 0)
    8000167e:	c901                	beqz	a0,8000168e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001680:	611c                	ld	a5,0(a0)
    80001682:	9bbd                	andi	a5,a5,-17
    80001684:	e11c                	sd	a5,0(a0)
}
    80001686:	60a2                	ld	ra,8(sp)
    80001688:	6402                	ld	s0,0(sp)
    8000168a:	0141                	addi	sp,sp,16
    8000168c:	8082                	ret
    panic("uvmclear");
    8000168e:	00007517          	auipc	a0,0x7
    80001692:	b4a50513          	addi	a0,a0,-1206 # 800081d8 <digits+0x198>
    80001696:	fffff097          	auipc	ra,0xfffff
    8000169a:	ea8080e7          	jalr	-344(ra) # 8000053e <panic>

000000008000169e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000169e:	c6bd                	beqz	a3,8000170c <copyout+0x6e>
{
    800016a0:	715d                	addi	sp,sp,-80
    800016a2:	e486                	sd	ra,72(sp)
    800016a4:	e0a2                	sd	s0,64(sp)
    800016a6:	fc26                	sd	s1,56(sp)
    800016a8:	f84a                	sd	s2,48(sp)
    800016aa:	f44e                	sd	s3,40(sp)
    800016ac:	f052                	sd	s4,32(sp)
    800016ae:	ec56                	sd	s5,24(sp)
    800016b0:	e85a                	sd	s6,16(sp)
    800016b2:	e45e                	sd	s7,8(sp)
    800016b4:	e062                	sd	s8,0(sp)
    800016b6:	0880                	addi	s0,sp,80
    800016b8:	8b2a                	mv	s6,a0
    800016ba:	8c2e                	mv	s8,a1
    800016bc:	8a32                	mv	s4,a2
    800016be:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016c0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016c2:	6a85                	lui	s5,0x1
    800016c4:	a015                	j	800016e8 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016c6:	9562                	add	a0,a0,s8
    800016c8:	0004861b          	sext.w	a2,s1
    800016cc:	85d2                	mv	a1,s4
    800016ce:	41250533          	sub	a0,a0,s2
    800016d2:	fffff097          	auipc	ra,0xfffff
    800016d6:	65c080e7          	jalr	1628(ra) # 80000d2e <memmove>

    len -= n;
    800016da:	409989b3          	sub	s3,s3,s1
    src += n;
    800016de:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016e0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016e4:	02098263          	beqz	s3,80001708 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016e8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ec:	85ca                	mv	a1,s2
    800016ee:	855a                	mv	a0,s6
    800016f0:	00000097          	auipc	ra,0x0
    800016f4:	98c080e7          	jalr	-1652(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    800016f8:	cd01                	beqz	a0,80001710 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016fa:	418904b3          	sub	s1,s2,s8
    800016fe:	94d6                	add	s1,s1,s5
    if(n > len)
    80001700:	fc99f3e3          	bgeu	s3,s1,800016c6 <copyout+0x28>
    80001704:	84ce                	mv	s1,s3
    80001706:	b7c1                	j	800016c6 <copyout+0x28>
  }
  return 0;
    80001708:	4501                	li	a0,0
    8000170a:	a021                	j	80001712 <copyout+0x74>
    8000170c:	4501                	li	a0,0
}
    8000170e:	8082                	ret
      return -1;
    80001710:	557d                	li	a0,-1
}
    80001712:	60a6                	ld	ra,72(sp)
    80001714:	6406                	ld	s0,64(sp)
    80001716:	74e2                	ld	s1,56(sp)
    80001718:	7942                	ld	s2,48(sp)
    8000171a:	79a2                	ld	s3,40(sp)
    8000171c:	7a02                	ld	s4,32(sp)
    8000171e:	6ae2                	ld	s5,24(sp)
    80001720:	6b42                	ld	s6,16(sp)
    80001722:	6ba2                	ld	s7,8(sp)
    80001724:	6c02                	ld	s8,0(sp)
    80001726:	6161                	addi	sp,sp,80
    80001728:	8082                	ret

000000008000172a <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000172a:	caa5                	beqz	a3,8000179a <copyin+0x70>
{
    8000172c:	715d                	addi	sp,sp,-80
    8000172e:	e486                	sd	ra,72(sp)
    80001730:	e0a2                	sd	s0,64(sp)
    80001732:	fc26                	sd	s1,56(sp)
    80001734:	f84a                	sd	s2,48(sp)
    80001736:	f44e                	sd	s3,40(sp)
    80001738:	f052                	sd	s4,32(sp)
    8000173a:	ec56                	sd	s5,24(sp)
    8000173c:	e85a                	sd	s6,16(sp)
    8000173e:	e45e                	sd	s7,8(sp)
    80001740:	e062                	sd	s8,0(sp)
    80001742:	0880                	addi	s0,sp,80
    80001744:	8b2a                	mv	s6,a0
    80001746:	8a2e                	mv	s4,a1
    80001748:	8c32                	mv	s8,a2
    8000174a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000174c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000174e:	6a85                	lui	s5,0x1
    80001750:	a01d                	j	80001776 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001752:	018505b3          	add	a1,a0,s8
    80001756:	0004861b          	sext.w	a2,s1
    8000175a:	412585b3          	sub	a1,a1,s2
    8000175e:	8552                	mv	a0,s4
    80001760:	fffff097          	auipc	ra,0xfffff
    80001764:	5ce080e7          	jalr	1486(ra) # 80000d2e <memmove>

    len -= n;
    80001768:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000176c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000176e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001772:	02098263          	beqz	s3,80001796 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001776:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000177a:	85ca                	mv	a1,s2
    8000177c:	855a                	mv	a0,s6
    8000177e:	00000097          	auipc	ra,0x0
    80001782:	8fe080e7          	jalr	-1794(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    80001786:	cd01                	beqz	a0,8000179e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001788:	418904b3          	sub	s1,s2,s8
    8000178c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000178e:	fc99f2e3          	bgeu	s3,s1,80001752 <copyin+0x28>
    80001792:	84ce                	mv	s1,s3
    80001794:	bf7d                	j	80001752 <copyin+0x28>
  }
  return 0;
    80001796:	4501                	li	a0,0
    80001798:	a021                	j	800017a0 <copyin+0x76>
    8000179a:	4501                	li	a0,0
}
    8000179c:	8082                	ret
      return -1;
    8000179e:	557d                	li	a0,-1
}
    800017a0:	60a6                	ld	ra,72(sp)
    800017a2:	6406                	ld	s0,64(sp)
    800017a4:	74e2                	ld	s1,56(sp)
    800017a6:	7942                	ld	s2,48(sp)
    800017a8:	79a2                	ld	s3,40(sp)
    800017aa:	7a02                	ld	s4,32(sp)
    800017ac:	6ae2                	ld	s5,24(sp)
    800017ae:	6b42                	ld	s6,16(sp)
    800017b0:	6ba2                	ld	s7,8(sp)
    800017b2:	6c02                	ld	s8,0(sp)
    800017b4:	6161                	addi	sp,sp,80
    800017b6:	8082                	ret

00000000800017b8 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017b8:	c6c5                	beqz	a3,80001860 <copyinstr+0xa8>
{
    800017ba:	715d                	addi	sp,sp,-80
    800017bc:	e486                	sd	ra,72(sp)
    800017be:	e0a2                	sd	s0,64(sp)
    800017c0:	fc26                	sd	s1,56(sp)
    800017c2:	f84a                	sd	s2,48(sp)
    800017c4:	f44e                	sd	s3,40(sp)
    800017c6:	f052                	sd	s4,32(sp)
    800017c8:	ec56                	sd	s5,24(sp)
    800017ca:	e85a                	sd	s6,16(sp)
    800017cc:	e45e                	sd	s7,8(sp)
    800017ce:	0880                	addi	s0,sp,80
    800017d0:	8a2a                	mv	s4,a0
    800017d2:	8b2e                	mv	s6,a1
    800017d4:	8bb2                	mv	s7,a2
    800017d6:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017d8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017da:	6985                	lui	s3,0x1
    800017dc:	a035                	j	80001808 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017de:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017e2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017e4:	0017b793          	seqz	a5,a5
    800017e8:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017ec:	60a6                	ld	ra,72(sp)
    800017ee:	6406                	ld	s0,64(sp)
    800017f0:	74e2                	ld	s1,56(sp)
    800017f2:	7942                	ld	s2,48(sp)
    800017f4:	79a2                	ld	s3,40(sp)
    800017f6:	7a02                	ld	s4,32(sp)
    800017f8:	6ae2                	ld	s5,24(sp)
    800017fa:	6b42                	ld	s6,16(sp)
    800017fc:	6ba2                	ld	s7,8(sp)
    800017fe:	6161                	addi	sp,sp,80
    80001800:	8082                	ret
    srcva = va0 + PGSIZE;
    80001802:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001806:	c8a9                	beqz	s1,80001858 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001808:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000180c:	85ca                	mv	a1,s2
    8000180e:	8552                	mv	a0,s4
    80001810:	00000097          	auipc	ra,0x0
    80001814:	86c080e7          	jalr	-1940(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    80001818:	c131                	beqz	a0,8000185c <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000181a:	41790833          	sub	a6,s2,s7
    8000181e:	984e                	add	a6,a6,s3
    if(n > max)
    80001820:	0104f363          	bgeu	s1,a6,80001826 <copyinstr+0x6e>
    80001824:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001826:	955e                	add	a0,a0,s7
    80001828:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000182c:	fc080be3          	beqz	a6,80001802 <copyinstr+0x4a>
    80001830:	985a                	add	a6,a6,s6
    80001832:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001834:	41650633          	sub	a2,a0,s6
    80001838:	14fd                	addi	s1,s1,-1
    8000183a:	9b26                	add	s6,s6,s1
    8000183c:	00f60733          	add	a4,a2,a5
    80001840:	00074703          	lbu	a4,0(a4)
    80001844:	df49                	beqz	a4,800017de <copyinstr+0x26>
        *dst = *p;
    80001846:	00e78023          	sb	a4,0(a5)
      --max;
    8000184a:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000184e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001850:	ff0796e3          	bne	a5,a6,8000183c <copyinstr+0x84>
      dst++;
    80001854:	8b42                	mv	s6,a6
    80001856:	b775                	j	80001802 <copyinstr+0x4a>
    80001858:	4781                	li	a5,0
    8000185a:	b769                	j	800017e4 <copyinstr+0x2c>
      return -1;
    8000185c:	557d                	li	a0,-1
    8000185e:	b779                	j	800017ec <copyinstr+0x34>
  int got_null = 0;
    80001860:	4781                	li	a5,0
  if(got_null){
    80001862:	0017b793          	seqz	a5,a5
    80001866:	40f00533          	neg	a0,a5
}
    8000186a:	8082                	ret

000000008000186c <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000186c:	7139                	addi	sp,sp,-64
    8000186e:	fc06                	sd	ra,56(sp)
    80001870:	f822                	sd	s0,48(sp)
    80001872:	f426                	sd	s1,40(sp)
    80001874:	f04a                	sd	s2,32(sp)
    80001876:	ec4e                	sd	s3,24(sp)
    80001878:	e852                	sd	s4,16(sp)
    8000187a:	e456                	sd	s5,8(sp)
    8000187c:	e05a                	sd	s6,0(sp)
    8000187e:	0080                	addi	s0,sp,64
    80001880:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001882:	00010497          	auipc	s1,0x10
    80001886:	15e48493          	addi	s1,s1,350 # 800119e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000188a:	8b26                	mv	s6,s1
    8000188c:	00006a97          	auipc	s5,0x6
    80001890:	774a8a93          	addi	s5,s5,1908 # 80008000 <etext>
    80001894:	04000937          	lui	s2,0x4000
    80001898:	197d                	addi	s2,s2,-1
    8000189a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000189c:	00016a17          	auipc	s4,0x16
    800018a0:	d44a0a13          	addi	s4,s4,-700 # 800175e0 <tickslock>
    char *pa = kalloc();
    800018a4:	fffff097          	auipc	ra,0xfffff
    800018a8:	242080e7          	jalr	578(ra) # 80000ae6 <kalloc>
    800018ac:	862a                	mv	a2,a0
    if(pa == 0)
    800018ae:	c131                	beqz	a0,800018f2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018b0:	416485b3          	sub	a1,s1,s6
    800018b4:	8591                	srai	a1,a1,0x4
    800018b6:	000ab783          	ld	a5,0(s5)
    800018ba:	02f585b3          	mul	a1,a1,a5
    800018be:	2585                	addiw	a1,a1,1
    800018c0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018c4:	4719                	li	a4,6
    800018c6:	6685                	lui	a3,0x1
    800018c8:	40b905b3          	sub	a1,s2,a1
    800018cc:	854e                	mv	a0,s3
    800018ce:	00000097          	auipc	ra,0x0
    800018d2:	890080e7          	jalr	-1904(ra) # 8000115e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d6:	17048493          	addi	s1,s1,368
    800018da:	fd4495e3          	bne	s1,s4,800018a4 <proc_mapstacks+0x38>
  }
}
    800018de:	70e2                	ld	ra,56(sp)
    800018e0:	7442                	ld	s0,48(sp)
    800018e2:	74a2                	ld	s1,40(sp)
    800018e4:	7902                	ld	s2,32(sp)
    800018e6:	69e2                	ld	s3,24(sp)
    800018e8:	6a42                	ld	s4,16(sp)
    800018ea:	6aa2                	ld	s5,8(sp)
    800018ec:	6b02                	ld	s6,0(sp)
    800018ee:	6121                	addi	sp,sp,64
    800018f0:	8082                	ret
      panic("kalloc");
    800018f2:	00007517          	auipc	a0,0x7
    800018f6:	8f650513          	addi	a0,a0,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	fffff097          	auipc	ra,0xfffff
    800018fe:	c44080e7          	jalr	-956(ra) # 8000053e <panic>

0000000080001902 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001902:	7139                	addi	sp,sp,-64
    80001904:	fc06                	sd	ra,56(sp)
    80001906:	f822                	sd	s0,48(sp)
    80001908:	f426                	sd	s1,40(sp)
    8000190a:	f04a                	sd	s2,32(sp)
    8000190c:	ec4e                	sd	s3,24(sp)
    8000190e:	e852                	sd	s4,16(sp)
    80001910:	e456                	sd	s5,8(sp)
    80001912:	e05a                	sd	s6,0(sp)
    80001914:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001916:	00007597          	auipc	a1,0x7
    8000191a:	8da58593          	addi	a1,a1,-1830 # 800081f0 <digits+0x1b0>
    8000191e:	00010517          	auipc	a0,0x10
    80001922:	c9250513          	addi	a0,a0,-878 # 800115b0 <pid_lock>
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	220080e7          	jalr	544(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000192e:	00007597          	auipc	a1,0x7
    80001932:	8ca58593          	addi	a1,a1,-1846 # 800081f8 <digits+0x1b8>
    80001936:	00010517          	auipc	a0,0x10
    8000193a:	c9250513          	addi	a0,a0,-878 # 800115c8 <wait_lock>
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001946:	00010497          	auipc	s1,0x10
    8000194a:	09a48493          	addi	s1,s1,154 # 800119e0 <proc>
      initlock(&p->lock, "proc");
    8000194e:	00007b17          	auipc	s6,0x7
    80001952:	8bab0b13          	addi	s6,s6,-1862 # 80008208 <digits+0x1c8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001956:	8aa6                	mv	s5,s1
    80001958:	00006a17          	auipc	s4,0x6
    8000195c:	6a8a0a13          	addi	s4,s4,1704 # 80008000 <etext>
    80001960:	04000937          	lui	s2,0x4000
    80001964:	197d                	addi	s2,s2,-1
    80001966:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	00016997          	auipc	s3,0x16
    8000196c:	c7898993          	addi	s3,s3,-904 # 800175e0 <tickslock>
      initlock(&p->lock, "proc");
    80001970:	85da                	mv	a1,s6
    80001972:	8526                	mv	a0,s1
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	1d2080e7          	jalr	466(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    8000197c:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001980:	415487b3          	sub	a5,s1,s5
    80001984:	8791                	srai	a5,a5,0x4
    80001986:	000a3703          	ld	a4,0(s4)
    8000198a:	02e787b3          	mul	a5,a5,a4
    8000198e:	2785                	addiw	a5,a5,1
    80001990:	00d7979b          	slliw	a5,a5,0xd
    80001994:	40f907b3          	sub	a5,s2,a5
    80001998:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000199a:	17048493          	addi	s1,s1,368
    8000199e:	fd3499e3          	bne	s1,s3,80001970 <procinit+0x6e>
  }
}
    800019a2:	70e2                	ld	ra,56(sp)
    800019a4:	7442                	ld	s0,48(sp)
    800019a6:	74a2                	ld	s1,40(sp)
    800019a8:	7902                	ld	s2,32(sp)
    800019aa:	69e2                	ld	s3,24(sp)
    800019ac:	6a42                	ld	s4,16(sp)
    800019ae:	6aa2                	ld	s5,8(sp)
    800019b0:	6b02                	ld	s6,0(sp)
    800019b2:	6121                	addi	sp,sp,64
    800019b4:	8082                	ret

00000000800019b6 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019b6:	1141                	addi	sp,sp,-16
    800019b8:	e422                	sd	s0,8(sp)
    800019ba:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019bc:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019be:	2501                	sext.w	a0,a0
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019c6:	1141                	addi	sp,sp,-16
    800019c8:	e422                	sd	s0,8(sp)
    800019ca:	0800                	addi	s0,sp,16
    800019cc:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ce:	2781                	sext.w	a5,a5
    800019d0:	079e                	slli	a5,a5,0x7
  return c;
}
    800019d2:	00010517          	auipc	a0,0x10
    800019d6:	c0e50513          	addi	a0,a0,-1010 # 800115e0 <cpus>
    800019da:	953e                	add	a0,a0,a5
    800019dc:	6422                	ld	s0,8(sp)
    800019de:	0141                	addi	sp,sp,16
    800019e0:	8082                	ret

00000000800019e2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019e2:	1101                	addi	sp,sp,-32
    800019e4:	ec06                	sd	ra,24(sp)
    800019e6:	e822                	sd	s0,16(sp)
    800019e8:	e426                	sd	s1,8(sp)
    800019ea:	1000                	addi	s0,sp,32
  push_off();
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	19e080e7          	jalr	414(ra) # 80000b8a <push_off>
    800019f4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019f6:	2781                	sext.w	a5,a5
    800019f8:	079e                	slli	a5,a5,0x7
    800019fa:	00010717          	auipc	a4,0x10
    800019fe:	bb670713          	addi	a4,a4,-1098 # 800115b0 <pid_lock>
    80001a02:	97ba                	add	a5,a5,a4
    80001a04:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	224080e7          	jalr	548(ra) # 80000c2a <pop_off>
  return p;
}
    80001a0e:	8526                	mv	a0,s1
    80001a10:	60e2                	ld	ra,24(sp)
    80001a12:	6442                	ld	s0,16(sp)
    80001a14:	64a2                	ld	s1,8(sp)
    80001a16:	6105                	addi	sp,sp,32
    80001a18:	8082                	ret

0000000080001a1a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a1a:	1141                	addi	sp,sp,-16
    80001a1c:	e406                	sd	ra,8(sp)
    80001a1e:	e022                	sd	s0,0(sp)
    80001a20:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a22:	00000097          	auipc	ra,0x0
    80001a26:	fc0080e7          	jalr	-64(ra) # 800019e2 <myproc>
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	260080e7          	jalr	608(ra) # 80000c8a <release>

  if (first) {
    80001a32:	00008797          	auipc	a5,0x8
    80001a36:	86e7a783          	lw	a5,-1938(a5) # 800092a0 <first.1>
    80001a3a:	eb89                	bnez	a5,80001a4c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a3c:	00001097          	auipc	ra,0x1
    80001a40:	e5a080e7          	jalr	-422(ra) # 80002896 <usertrapret>
}
    80001a44:	60a2                	ld	ra,8(sp)
    80001a46:	6402                	ld	s0,0(sp)
    80001a48:	0141                	addi	sp,sp,16
    80001a4a:	8082                	ret
    first = 0;
    80001a4c:	00008797          	auipc	a5,0x8
    80001a50:	8407aa23          	sw	zero,-1964(a5) # 800092a0 <first.1>
    fsinit(ROOTDEV);
    80001a54:	4505                	li	a0,1
    80001a56:	00002097          	auipc	ra,0x2
    80001a5a:	be6080e7          	jalr	-1050(ra) # 8000363c <fsinit>
    80001a5e:	bff9                	j	80001a3c <forkret+0x22>

0000000080001a60 <allocpid>:
{
    80001a60:	1101                	addi	sp,sp,-32
    80001a62:	ec06                	sd	ra,24(sp)
    80001a64:	e822                	sd	s0,16(sp)
    80001a66:	e426                	sd	s1,8(sp)
    80001a68:	e04a                	sd	s2,0(sp)
    80001a6a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a6c:	00010917          	auipc	s2,0x10
    80001a70:	b4490913          	addi	s2,s2,-1212 # 800115b0 <pid_lock>
    80001a74:	854a                	mv	a0,s2
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	160080e7          	jalr	352(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a7e:	00008797          	auipc	a5,0x8
    80001a82:	82678793          	addi	a5,a5,-2010 # 800092a4 <nextpid>
    80001a86:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a88:	0014871b          	addiw	a4,s1,1
    80001a8c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a8e:	854a                	mv	a0,s2
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	1fa080e7          	jalr	506(ra) # 80000c8a <release>
}
    80001a98:	8526                	mv	a0,s1
    80001a9a:	60e2                	ld	ra,24(sp)
    80001a9c:	6442                	ld	s0,16(sp)
    80001a9e:	64a2                	ld	s1,8(sp)
    80001aa0:	6902                	ld	s2,0(sp)
    80001aa2:	6105                	addi	sp,sp,32
    80001aa4:	8082                	ret

0000000080001aa6 <proc_pagetable>:
{
    80001aa6:	1101                	addi	sp,sp,-32
    80001aa8:	ec06                	sd	ra,24(sp)
    80001aaa:	e822                	sd	s0,16(sp)
    80001aac:	e426                	sd	s1,8(sp)
    80001aae:	e04a                	sd	s2,0(sp)
    80001ab0:	1000                	addi	s0,sp,32
    80001ab2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ab4:	00000097          	auipc	ra,0x0
    80001ab8:	8aa080e7          	jalr	-1878(ra) # 8000135e <uvmcreate>
    80001abc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001abe:	c121                	beqz	a0,80001afe <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ac0:	4729                	li	a4,10
    80001ac2:	00005697          	auipc	a3,0x5
    80001ac6:	53e68693          	addi	a3,a3,1342 # 80007000 <_trampoline>
    80001aca:	6605                	lui	a2,0x1
    80001acc:	040005b7          	lui	a1,0x4000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b2                	slli	a1,a1,0xc
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	5ea080e7          	jalr	1514(ra) # 800010be <mappages>
    80001adc:	02054863          	bltz	a0,80001b0c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ae0:	4719                	li	a4,6
    80001ae2:	05893683          	ld	a3,88(s2)
    80001ae6:	6605                	lui	a2,0x1
    80001ae8:	020005b7          	lui	a1,0x2000
    80001aec:	15fd                	addi	a1,a1,-1
    80001aee:	05b6                	slli	a1,a1,0xd
    80001af0:	8526                	mv	a0,s1
    80001af2:	fffff097          	auipc	ra,0xfffff
    80001af6:	5cc080e7          	jalr	1484(ra) # 800010be <mappages>
    80001afa:	02054163          	bltz	a0,80001b1c <proc_pagetable+0x76>
}
    80001afe:	8526                	mv	a0,s1
    80001b00:	60e2                	ld	ra,24(sp)
    80001b02:	6442                	ld	s0,16(sp)
    80001b04:	64a2                	ld	s1,8(sp)
    80001b06:	6902                	ld	s2,0(sp)
    80001b08:	6105                	addi	sp,sp,32
    80001b0a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b0c:	4581                	li	a1,0
    80001b0e:	8526                	mv	a0,s1
    80001b10:	00000097          	auipc	ra,0x0
    80001b14:	a52080e7          	jalr	-1454(ra) # 80001562 <uvmfree>
    return 0;
    80001b18:	4481                	li	s1,0
    80001b1a:	b7d5                	j	80001afe <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	8526                	mv	a0,s1
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	770080e7          	jalr	1904(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80001b32:	4581                	li	a1,0
    80001b34:	8526                	mv	a0,s1
    80001b36:	00000097          	auipc	ra,0x0
    80001b3a:	a2c080e7          	jalr	-1492(ra) # 80001562 <uvmfree>
    return 0;
    80001b3e:	4481                	li	s1,0
    80001b40:	bf7d                	j	80001afe <proc_pagetable+0x58>

0000000080001b42 <proc_freepagetable>:
{
    80001b42:	1101                	addi	sp,sp,-32
    80001b44:	ec06                	sd	ra,24(sp)
    80001b46:	e822                	sd	s0,16(sp)
    80001b48:	e426                	sd	s1,8(sp)
    80001b4a:	e04a                	sd	s2,0(sp)
    80001b4c:	1000                	addi	s0,sp,32
    80001b4e:	84aa                	mv	s1,a0
    80001b50:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b52:	4681                	li	a3,0
    80001b54:	4605                	li	a2,1
    80001b56:	040005b7          	lui	a1,0x4000
    80001b5a:	15fd                	addi	a1,a1,-1
    80001b5c:	05b2                	slli	a1,a1,0xc
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	73c080e7          	jalr	1852(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b66:	4681                	li	a3,0
    80001b68:	4605                	li	a2,1
    80001b6a:	020005b7          	lui	a1,0x2000
    80001b6e:	15fd                	addi	a1,a1,-1
    80001b70:	05b6                	slli	a1,a1,0xd
    80001b72:	8526                	mv	a0,s1
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	726080e7          	jalr	1830(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b7c:	85ca                	mv	a1,s2
    80001b7e:	8526                	mv	a0,s1
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	9e2080e7          	jalr	-1566(ra) # 80001562 <uvmfree>
}
    80001b88:	60e2                	ld	ra,24(sp)
    80001b8a:	6442                	ld	s0,16(sp)
    80001b8c:	64a2                	ld	s1,8(sp)
    80001b8e:	6902                	ld	s2,0(sp)
    80001b90:	6105                	addi	sp,sp,32
    80001b92:	8082                	ret

0000000080001b94 <freeproc>:
{
    80001b94:	1101                	addi	sp,sp,-32
    80001b96:	ec06                	sd	ra,24(sp)
    80001b98:	e822                	sd	s0,16(sp)
    80001b9a:	e426                	sd	s1,8(sp)
    80001b9c:	1000                	addi	s0,sp,32
    80001b9e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ba0:	6d28                	ld	a0,88(a0)
    80001ba2:	c509                	beqz	a0,80001bac <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	e46080e7          	jalr	-442(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001bac:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable){
    80001bb0:	68bc                	ld	a5,80(s1)
    80001bb2:	cb91                	beqz	a5,80001bc6 <freeproc+0x32>
    if (p != 0 && p->va_loc != 0) {
    80001bb4:	1684b583          	ld	a1,360(s1)
    80001bb8:	ed95                	bnez	a1,80001bf4 <freeproc+0x60>
    proc_freepagetable(p->pagetable, p->sz);
    80001bba:	64ac                	ld	a1,72(s1)
    80001bbc:	68a8                	ld	a0,80(s1)
    80001bbe:	00000097          	auipc	ra,0x0
    80001bc2:	f84080e7          	jalr	-124(ra) # 80001b42 <proc_freepagetable>
  p->pagetable = 0;
    80001bc6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bca:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bce:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bd2:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bd6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bda:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bde:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001be2:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001be6:	0004ac23          	sw	zero,24(s1)
}
    80001bea:	60e2                	ld	ra,24(sp)
    80001bec:	6442                	ld	s0,16(sp)
    80001bee:	64a2                	ld	s1,8(sp)
    80001bf0:	6105                	addi	sp,sp,32
    80001bf2:	8082                	ret
      printf("line 164, unmapping display at va: %p\n", p->va_loc);
    80001bf4:	00006517          	auipc	a0,0x6
    80001bf8:	61c50513          	addi	a0,a0,1564 # 80008210 <digits+0x1d0>
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	98c080e7          	jalr	-1652(ra) # 80000588 <printf>
      uvmunmap(p->pagetable, p->va_loc, GPU_FB_PAGES, 0);
    80001c04:	4681                	li	a3,0
    80001c06:	12c00613          	li	a2,300
    80001c0a:	1684b583          	ld	a1,360(s1)
    80001c0e:	68a8                	ld	a0,80(s1)
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	68a080e7          	jalr	1674(ra) # 8000129a <uvmunmap>
      p->va_loc = 0;
    80001c18:	1604b423          	sd	zero,360(s1)
    80001c1c:	bf79                	j	80001bba <freeproc+0x26>

0000000080001c1e <allocproc>:
{
    80001c1e:	1101                	addi	sp,sp,-32
    80001c20:	ec06                	sd	ra,24(sp)
    80001c22:	e822                	sd	s0,16(sp)
    80001c24:	e426                	sd	s1,8(sp)
    80001c26:	e04a                	sd	s2,0(sp)
    80001c28:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c2a:	00010497          	auipc	s1,0x10
    80001c2e:	db648493          	addi	s1,s1,-586 # 800119e0 <proc>
    80001c32:	00016917          	auipc	s2,0x16
    80001c36:	9ae90913          	addi	s2,s2,-1618 # 800175e0 <tickslock>
    acquire(&p->lock);
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	f9a080e7          	jalr	-102(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001c44:	4c9c                	lw	a5,24(s1)
    80001c46:	cf81                	beqz	a5,80001c5e <allocproc+0x40>
      release(&p->lock);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	040080e7          	jalr	64(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c52:	17048493          	addi	s1,s1,368
    80001c56:	ff2492e3          	bne	s1,s2,80001c3a <allocproc+0x1c>
  return 0;
    80001c5a:	4481                	li	s1,0
    80001c5c:	a889                	j	80001cae <allocproc+0x90>
  p->pid = allocpid();
    80001c5e:	00000097          	auipc	ra,0x0
    80001c62:	e02080e7          	jalr	-510(ra) # 80001a60 <allocpid>
    80001c66:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c68:	4785                	li	a5,1
    80001c6a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	e7a080e7          	jalr	-390(ra) # 80000ae6 <kalloc>
    80001c74:	892a                	mv	s2,a0
    80001c76:	eca8                	sd	a0,88(s1)
    80001c78:	c131                	beqz	a0,80001cbc <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	e2a080e7          	jalr	-470(ra) # 80001aa6 <proc_pagetable>
    80001c84:	892a                	mv	s2,a0
    80001c86:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c88:	c531                	beqz	a0,80001cd4 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c8a:	07000613          	li	a2,112
    80001c8e:	4581                	li	a1,0
    80001c90:	06048513          	addi	a0,s1,96
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	03e080e7          	jalr	62(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c9c:	00000797          	auipc	a5,0x0
    80001ca0:	d7e78793          	addi	a5,a5,-642 # 80001a1a <forkret>
    80001ca4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ca6:	60bc                	ld	a5,64(s1)
    80001ca8:	6705                	lui	a4,0x1
    80001caa:	97ba                	add	a5,a5,a4
    80001cac:	f4bc                	sd	a5,104(s1)
}
    80001cae:	8526                	mv	a0,s1
    80001cb0:	60e2                	ld	ra,24(sp)
    80001cb2:	6442                	ld	s0,16(sp)
    80001cb4:	64a2                	ld	s1,8(sp)
    80001cb6:	6902                	ld	s2,0(sp)
    80001cb8:	6105                	addi	sp,sp,32
    80001cba:	8082                	ret
    freeproc(p);
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	ed6080e7          	jalr	-298(ra) # 80001b94 <freeproc>
    release(&p->lock);
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	fc2080e7          	jalr	-62(ra) # 80000c8a <release>
    return 0;
    80001cd0:	84ca                	mv	s1,s2
    80001cd2:	bff1                	j	80001cae <allocproc+0x90>
    freeproc(p);
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	ebe080e7          	jalr	-322(ra) # 80001b94 <freeproc>
    release(&p->lock);
    80001cde:	8526                	mv	a0,s1
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	faa080e7          	jalr	-86(ra) # 80000c8a <release>
    return 0;
    80001ce8:	84ca                	mv	s1,s2
    80001cea:	b7d1                	j	80001cae <allocproc+0x90>

0000000080001cec <userinit>:
{
    80001cec:	1101                	addi	sp,sp,-32
    80001cee:	ec06                	sd	ra,24(sp)
    80001cf0:	e822                	sd	s0,16(sp)
    80001cf2:	e426                	sd	s1,8(sp)
    80001cf4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	f28080e7          	jalr	-216(ra) # 80001c1e <allocproc>
    80001cfe:	84aa                	mv	s1,a0
  initproc = p;
    80001d00:	00007797          	auipc	a5,0x7
    80001d04:	62a7bc23          	sd	a0,1592(a5) # 80009338 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d08:	03400613          	li	a2,52
    80001d0c:	00007597          	auipc	a1,0x7
    80001d10:	5a458593          	addi	a1,a1,1444 # 800092b0 <initcode>
    80001d14:	6928                	ld	a0,80(a0)
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	676080e7          	jalr	1654(ra) # 8000138c <uvmfirst>
  p->sz = PGSIZE;
    80001d1e:	6785                	lui	a5,0x1
    80001d20:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d22:	6cb8                	ld	a4,88(s1)
    80001d24:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d28:	6cb8                	ld	a4,88(s1)
    80001d2a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d2c:	4641                	li	a2,16
    80001d2e:	00006597          	auipc	a1,0x6
    80001d32:	50a58593          	addi	a1,a1,1290 # 80008238 <digits+0x1f8>
    80001d36:	15848513          	addi	a0,s1,344
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	0e2080e7          	jalr	226(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d42:	00006517          	auipc	a0,0x6
    80001d46:	50650513          	addi	a0,a0,1286 # 80008248 <digits+0x208>
    80001d4a:	00002097          	auipc	ra,0x2
    80001d4e:	314080e7          	jalr	788(ra) # 8000405e <namei>
    80001d52:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d56:	478d                	li	a5,3
    80001d58:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d5a:	8526                	mv	a0,s1
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	f2e080e7          	jalr	-210(ra) # 80000c8a <release>
}
    80001d64:	60e2                	ld	ra,24(sp)
    80001d66:	6442                	ld	s0,16(sp)
    80001d68:	64a2                	ld	s1,8(sp)
    80001d6a:	6105                	addi	sp,sp,32
    80001d6c:	8082                	ret

0000000080001d6e <kproc_create>:
{
    80001d6e:	7179                	addi	sp,sp,-48
    80001d70:	f406                	sd	ra,40(sp)
    80001d72:	f022                	sd	s0,32(sp)
    80001d74:	ec26                	sd	s1,24(sp)
    80001d76:	e84a                	sd	s2,16(sp)
    80001d78:	e44e                	sd	s3,8(sp)
    80001d7a:	1800                	addi	s0,sp,48
    80001d7c:	89aa                	mv	s3,a0
    80001d7e:	892e                	mv	s2,a1
  struct proc *p = allocproc();
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	e9e080e7          	jalr	-354(ra) # 80001c1e <allocproc>
  if(p == 0)
    80001d88:	cd15                	beqz	a0,80001dc4 <kproc_create+0x56>
    80001d8a:	84aa                	mv	s1,a0
  p->context.ra = (uint64)fn;
    80001d8c:	07353023          	sd	s3,96(a0)
  p->context.sp = p->kstack + PGSIZE;
    80001d90:	613c                	ld	a5,64(a0)
    80001d92:	6705                	lui	a4,0x1
    80001d94:	97ba                	add	a5,a5,a4
    80001d96:	f53c                	sd	a5,104(a0)
  safestrcpy(p->name, name, sizeof(p->name));
    80001d98:	4641                	li	a2,16
    80001d9a:	85ca                	mv	a1,s2
    80001d9c:	15850513          	addi	a0,a0,344
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	07c080e7          	jalr	124(ra) # 80000e1c <safestrcpy>
  p->state = RUNNABLE;
    80001da8:	478d                	li	a5,3
    80001daa:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001dac:	8526                	mv	a0,s1
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	edc080e7          	jalr	-292(ra) # 80000c8a <release>
}
    80001db6:	70a2                	ld	ra,40(sp)
    80001db8:	7402                	ld	s0,32(sp)
    80001dba:	64e2                	ld	s1,24(sp)
    80001dbc:	6942                	ld	s2,16(sp)
    80001dbe:	69a2                	ld	s3,8(sp)
    80001dc0:	6145                	addi	sp,sp,48
    80001dc2:	8082                	ret
    panic("kproc_create");
    80001dc4:	00006517          	auipc	a0,0x6
    80001dc8:	48c50513          	addi	a0,a0,1164 # 80008250 <digits+0x210>
    80001dcc:	ffffe097          	auipc	ra,0xffffe
    80001dd0:	772080e7          	jalr	1906(ra) # 8000053e <panic>

0000000080001dd4 <growproc>:
{
    80001dd4:	1101                	addi	sp,sp,-32
    80001dd6:	ec06                	sd	ra,24(sp)
    80001dd8:	e822                	sd	s0,16(sp)
    80001dda:	e426                	sd	s1,8(sp)
    80001ddc:	e04a                	sd	s2,0(sp)
    80001dde:	1000                	addi	s0,sp,32
    80001de0:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	c00080e7          	jalr	-1024(ra) # 800019e2 <myproc>
    80001dea:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dec:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001dee:	01204c63          	bgtz	s2,80001e06 <growproc+0x32>
  } else if(n < 0){
    80001df2:	02094663          	bltz	s2,80001e1e <growproc+0x4a>
  p->sz = sz;
    80001df6:	e4ac                	sd	a1,72(s1)
  return 0;
    80001df8:	4501                	li	a0,0
}
    80001dfa:	60e2                	ld	ra,24(sp)
    80001dfc:	6442                	ld	s0,16(sp)
    80001dfe:	64a2                	ld	s1,8(sp)
    80001e00:	6902                	ld	s2,0(sp)
    80001e02:	6105                	addi	sp,sp,32
    80001e04:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001e06:	4691                	li	a3,4
    80001e08:	00b90633          	add	a2,s2,a1
    80001e0c:	6928                	ld	a0,80(a0)
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	638080e7          	jalr	1592(ra) # 80001446 <uvmalloc>
    80001e16:	85aa                	mv	a1,a0
    80001e18:	fd79                	bnez	a0,80001df6 <growproc+0x22>
      return -1;
    80001e1a:	557d                	li	a0,-1
    80001e1c:	bff9                	j	80001dfa <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e1e:	00b90633          	add	a2,s2,a1
    80001e22:	6928                	ld	a0,80(a0)
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	5da080e7          	jalr	1498(ra) # 800013fe <uvmdealloc>
    80001e2c:	85aa                	mv	a1,a0
    80001e2e:	b7e1                	j	80001df6 <growproc+0x22>

0000000080001e30 <fork>:
{
    80001e30:	7139                	addi	sp,sp,-64
    80001e32:	fc06                	sd	ra,56(sp)
    80001e34:	f822                	sd	s0,48(sp)
    80001e36:	f426                	sd	s1,40(sp)
    80001e38:	f04a                	sd	s2,32(sp)
    80001e3a:	ec4e                	sd	s3,24(sp)
    80001e3c:	e852                	sd	s4,16(sp)
    80001e3e:	e456                	sd	s5,8(sp)
    80001e40:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e42:	00000097          	auipc	ra,0x0
    80001e46:	ba0080e7          	jalr	-1120(ra) # 800019e2 <myproc>
    80001e4a:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	dd2080e7          	jalr	-558(ra) # 80001c1e <allocproc>
    80001e54:	10050c63          	beqz	a0,80001f6c <fork+0x13c>
    80001e58:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e5a:	048ab603          	ld	a2,72(s5)
    80001e5e:	692c                	ld	a1,80(a0)
    80001e60:	050ab503          	ld	a0,80(s5)
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	736080e7          	jalr	1846(ra) # 8000159a <uvmcopy>
    80001e6c:	04054863          	bltz	a0,80001ebc <fork+0x8c>
  np->sz = p->sz;
    80001e70:	048ab783          	ld	a5,72(s5)
    80001e74:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e78:	058ab683          	ld	a3,88(s5)
    80001e7c:	87b6                	mv	a5,a3
    80001e7e:	058a3703          	ld	a4,88(s4)
    80001e82:	12068693          	addi	a3,a3,288
    80001e86:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e8a:	6788                	ld	a0,8(a5)
    80001e8c:	6b8c                	ld	a1,16(a5)
    80001e8e:	6f90                	ld	a2,24(a5)
    80001e90:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001e94:	e708                	sd	a0,8(a4)
    80001e96:	eb0c                	sd	a1,16(a4)
    80001e98:	ef10                	sd	a2,24(a4)
    80001e9a:	02078793          	addi	a5,a5,32
    80001e9e:	02070713          	addi	a4,a4,32
    80001ea2:	fed792e3          	bne	a5,a3,80001e86 <fork+0x56>
  np->trapframe->a0 = 0;
    80001ea6:	058a3783          	ld	a5,88(s4)
    80001eaa:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001eae:	0d0a8493          	addi	s1,s5,208
    80001eb2:	0d0a0913          	addi	s2,s4,208
    80001eb6:	150a8993          	addi	s3,s5,336
    80001eba:	a00d                	j	80001edc <fork+0xac>
    freeproc(np);
    80001ebc:	8552                	mv	a0,s4
    80001ebe:	00000097          	auipc	ra,0x0
    80001ec2:	cd6080e7          	jalr	-810(ra) # 80001b94 <freeproc>
    release(&np->lock);
    80001ec6:	8552                	mv	a0,s4
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	dc2080e7          	jalr	-574(ra) # 80000c8a <release>
    return -1;
    80001ed0:	597d                	li	s2,-1
    80001ed2:	a059                	j	80001f58 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001ed4:	04a1                	addi	s1,s1,8
    80001ed6:	0921                	addi	s2,s2,8
    80001ed8:	01348b63          	beq	s1,s3,80001eee <fork+0xbe>
    if(p->ofile[i])
    80001edc:	6088                	ld	a0,0(s1)
    80001ede:	d97d                	beqz	a0,80001ed4 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ee0:	00003097          	auipc	ra,0x3
    80001ee4:	814080e7          	jalr	-2028(ra) # 800046f4 <filedup>
    80001ee8:	00a93023          	sd	a0,0(s2)
    80001eec:	b7e5                	j	80001ed4 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001eee:	150ab503          	ld	a0,336(s5)
    80001ef2:	00002097          	auipc	ra,0x2
    80001ef6:	988080e7          	jalr	-1656(ra) # 8000387a <idup>
    80001efa:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001efe:	4641                	li	a2,16
    80001f00:	158a8593          	addi	a1,s5,344
    80001f04:	158a0513          	addi	a0,s4,344
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	f14080e7          	jalr	-236(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001f10:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f14:	8552                	mv	a0,s4
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	d74080e7          	jalr	-652(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001f1e:	0000f497          	auipc	s1,0xf
    80001f22:	6aa48493          	addi	s1,s1,1706 # 800115c8 <wait_lock>
    80001f26:	8526                	mv	a0,s1
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	cae080e7          	jalr	-850(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001f30:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	d54080e7          	jalr	-684(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001f3e:	8552                	mv	a0,s4
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	c96080e7          	jalr	-874(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001f48:	478d                	li	a5,3
    80001f4a:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f4e:	8552                	mv	a0,s4
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	d3a080e7          	jalr	-710(ra) # 80000c8a <release>
}
    80001f58:	854a                	mv	a0,s2
    80001f5a:	70e2                	ld	ra,56(sp)
    80001f5c:	7442                	ld	s0,48(sp)
    80001f5e:	74a2                	ld	s1,40(sp)
    80001f60:	7902                	ld	s2,32(sp)
    80001f62:	69e2                	ld	s3,24(sp)
    80001f64:	6a42                	ld	s4,16(sp)
    80001f66:	6aa2                	ld	s5,8(sp)
    80001f68:	6121                	addi	sp,sp,64
    80001f6a:	8082                	ret
    return -1;
    80001f6c:	597d                	li	s2,-1
    80001f6e:	b7ed                	j	80001f58 <fork+0x128>

0000000080001f70 <scheduler>:
{
    80001f70:	7139                	addi	sp,sp,-64
    80001f72:	fc06                	sd	ra,56(sp)
    80001f74:	f822                	sd	s0,48(sp)
    80001f76:	f426                	sd	s1,40(sp)
    80001f78:	f04a                	sd	s2,32(sp)
    80001f7a:	ec4e                	sd	s3,24(sp)
    80001f7c:	e852                	sd	s4,16(sp)
    80001f7e:	e456                	sd	s5,8(sp)
    80001f80:	e05a                	sd	s6,0(sp)
    80001f82:	0080                	addi	s0,sp,64
    80001f84:	8792                	mv	a5,tp
  int id = r_tp();
    80001f86:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f88:	00779a93          	slli	s5,a5,0x7
    80001f8c:	0000f717          	auipc	a4,0xf
    80001f90:	62470713          	addi	a4,a4,1572 # 800115b0 <pid_lock>
    80001f94:	9756                	add	a4,a4,s5
    80001f96:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f9a:	0000f717          	auipc	a4,0xf
    80001f9e:	64e70713          	addi	a4,a4,1614 # 800115e8 <cpus+0x8>
    80001fa2:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001fa4:	498d                	li	s3,3
        p->state = RUNNING;
    80001fa6:	4b11                	li	s6,4
        c->proc = p;
    80001fa8:	079e                	slli	a5,a5,0x7
    80001faa:	0000fa17          	auipc	s4,0xf
    80001fae:	606a0a13          	addi	s4,s4,1542 # 800115b0 <pid_lock>
    80001fb2:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	00015917          	auipc	s2,0x15
    80001fb8:	62c90913          	addi	s2,s2,1580 # 800175e0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fc0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc4:	10079073          	csrw	sstatus,a5
    80001fc8:	00010497          	auipc	s1,0x10
    80001fcc:	a1848493          	addi	s1,s1,-1512 # 800119e0 <proc>
    80001fd0:	a811                	j	80001fe4 <scheduler+0x74>
      release(&p->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	cb6080e7          	jalr	-842(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fdc:	17048493          	addi	s1,s1,368
    80001fe0:	fd248ee3          	beq	s1,s2,80001fbc <scheduler+0x4c>
      acquire(&p->lock);
    80001fe4:	8526                	mv	a0,s1
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	bf0080e7          	jalr	-1040(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001fee:	4c9c                	lw	a5,24(s1)
    80001ff0:	ff3791e3          	bne	a5,s3,80001fd2 <scheduler+0x62>
        p->state = RUNNING;
    80001ff4:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001ff8:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001ffc:	06048593          	addi	a1,s1,96
    80002000:	8556                	mv	a0,s5
    80002002:	00000097          	auipc	ra,0x0
    80002006:	7ea080e7          	jalr	2026(ra) # 800027ec <swtch>
        c->proc = 0;
    8000200a:	020a3823          	sd	zero,48(s4)
    8000200e:	b7d1                	j	80001fd2 <scheduler+0x62>

0000000080002010 <sched>:
{
    80002010:	7179                	addi	sp,sp,-48
    80002012:	f406                	sd	ra,40(sp)
    80002014:	f022                	sd	s0,32(sp)
    80002016:	ec26                	sd	s1,24(sp)
    80002018:	e84a                	sd	s2,16(sp)
    8000201a:	e44e                	sd	s3,8(sp)
    8000201c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000201e:	00000097          	auipc	ra,0x0
    80002022:	9c4080e7          	jalr	-1596(ra) # 800019e2 <myproc>
    80002026:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	b34080e7          	jalr	-1228(ra) # 80000b5c <holding>
    80002030:	c93d                	beqz	a0,800020a6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002032:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002034:	2781                	sext.w	a5,a5
    80002036:	079e                	slli	a5,a5,0x7
    80002038:	0000f717          	auipc	a4,0xf
    8000203c:	57870713          	addi	a4,a4,1400 # 800115b0 <pid_lock>
    80002040:	97ba                	add	a5,a5,a4
    80002042:	0a87a703          	lw	a4,168(a5)
    80002046:	4785                	li	a5,1
    80002048:	06f71763          	bne	a4,a5,800020b6 <sched+0xa6>
  if(p->state == RUNNING)
    8000204c:	4c98                	lw	a4,24(s1)
    8000204e:	4791                	li	a5,4
    80002050:	06f70b63          	beq	a4,a5,800020c6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002054:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002058:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000205a:	efb5                	bnez	a5,800020d6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000205c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000205e:	0000f917          	auipc	s2,0xf
    80002062:	55290913          	addi	s2,s2,1362 # 800115b0 <pid_lock>
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	97ca                	add	a5,a5,s2
    8000206c:	0ac7a983          	lw	s3,172(a5)
    80002070:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002072:	2781                	sext.w	a5,a5
    80002074:	079e                	slli	a5,a5,0x7
    80002076:	0000f597          	auipc	a1,0xf
    8000207a:	57258593          	addi	a1,a1,1394 # 800115e8 <cpus+0x8>
    8000207e:	95be                	add	a1,a1,a5
    80002080:	06048513          	addi	a0,s1,96
    80002084:	00000097          	auipc	ra,0x0
    80002088:	768080e7          	jalr	1896(ra) # 800027ec <swtch>
    8000208c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000208e:	2781                	sext.w	a5,a5
    80002090:	079e                	slli	a5,a5,0x7
    80002092:	97ca                	add	a5,a5,s2
    80002094:	0b37a623          	sw	s3,172(a5)
}
    80002098:	70a2                	ld	ra,40(sp)
    8000209a:	7402                	ld	s0,32(sp)
    8000209c:	64e2                	ld	s1,24(sp)
    8000209e:	6942                	ld	s2,16(sp)
    800020a0:	69a2                	ld	s3,8(sp)
    800020a2:	6145                	addi	sp,sp,48
    800020a4:	8082                	ret
    panic("sched p->lock");
    800020a6:	00006517          	auipc	a0,0x6
    800020aa:	1ba50513          	addi	a0,a0,442 # 80008260 <digits+0x220>
    800020ae:	ffffe097          	auipc	ra,0xffffe
    800020b2:	490080e7          	jalr	1168(ra) # 8000053e <panic>
    panic("sched locks");
    800020b6:	00006517          	auipc	a0,0x6
    800020ba:	1ba50513          	addi	a0,a0,442 # 80008270 <digits+0x230>
    800020be:	ffffe097          	auipc	ra,0xffffe
    800020c2:	480080e7          	jalr	1152(ra) # 8000053e <panic>
    panic("sched running");
    800020c6:	00006517          	auipc	a0,0x6
    800020ca:	1ba50513          	addi	a0,a0,442 # 80008280 <digits+0x240>
    800020ce:	ffffe097          	auipc	ra,0xffffe
    800020d2:	470080e7          	jalr	1136(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020d6:	00006517          	auipc	a0,0x6
    800020da:	1ba50513          	addi	a0,a0,442 # 80008290 <digits+0x250>
    800020de:	ffffe097          	auipc	ra,0xffffe
    800020e2:	460080e7          	jalr	1120(ra) # 8000053e <panic>

00000000800020e6 <yield>:
{
    800020e6:	1101                	addi	sp,sp,-32
    800020e8:	ec06                	sd	ra,24(sp)
    800020ea:	e822                	sd	s0,16(sp)
    800020ec:	e426                	sd	s1,8(sp)
    800020ee:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020f0:	00000097          	auipc	ra,0x0
    800020f4:	8f2080e7          	jalr	-1806(ra) # 800019e2 <myproc>
    800020f8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	adc080e7          	jalr	-1316(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002102:	478d                	li	a5,3
    80002104:	cc9c                	sw	a5,24(s1)
  sched();
    80002106:	00000097          	auipc	ra,0x0
    8000210a:	f0a080e7          	jalr	-246(ra) # 80002010 <sched>
  release(&p->lock);
    8000210e:	8526                	mv	a0,s1
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	b7a080e7          	jalr	-1158(ra) # 80000c8a <release>
}
    80002118:	60e2                	ld	ra,24(sp)
    8000211a:	6442                	ld	s0,16(sp)
    8000211c:	64a2                	ld	s1,8(sp)
    8000211e:	6105                	addi	sp,sp,32
    80002120:	8082                	ret

0000000080002122 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002122:	7179                	addi	sp,sp,-48
    80002124:	f406                	sd	ra,40(sp)
    80002126:	f022                	sd	s0,32(sp)
    80002128:	ec26                	sd	s1,24(sp)
    8000212a:	e84a                	sd	s2,16(sp)
    8000212c:	e44e                	sd	s3,8(sp)
    8000212e:	1800                	addi	s0,sp,48
    80002130:	89aa                	mv	s3,a0
    80002132:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002134:	00000097          	auipc	ra,0x0
    80002138:	8ae080e7          	jalr	-1874(ra) # 800019e2 <myproc>
    8000213c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	a98080e7          	jalr	-1384(ra) # 80000bd6 <acquire>
  release(lk);
    80002146:	854a                	mv	a0,s2
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b42080e7          	jalr	-1214(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002150:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002154:	4789                	li	a5,2
    80002156:	cc9c                	sw	a5,24(s1)

  sched();
    80002158:	00000097          	auipc	ra,0x0
    8000215c:	eb8080e7          	jalr	-328(ra) # 80002010 <sched>

  // Tidy up.
  p->chan = 0;
    80002160:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002164:	8526                	mv	a0,s1
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	b24080e7          	jalr	-1244(ra) # 80000c8a <release>
  acquire(lk);
    8000216e:	854a                	mv	a0,s2
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	a66080e7          	jalr	-1434(ra) # 80000bd6 <acquire>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6145                	addi	sp,sp,48
    80002184:	8082                	ret

0000000080002186 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002186:	7139                	addi	sp,sp,-64
    80002188:	fc06                	sd	ra,56(sp)
    8000218a:	f822                	sd	s0,48(sp)
    8000218c:	f426                	sd	s1,40(sp)
    8000218e:	f04a                	sd	s2,32(sp)
    80002190:	ec4e                	sd	s3,24(sp)
    80002192:	e852                	sd	s4,16(sp)
    80002194:	e456                	sd	s5,8(sp)
    80002196:	0080                	addi	s0,sp,64
    80002198:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000219a:	00010497          	auipc	s1,0x10
    8000219e:	84648493          	addi	s1,s1,-1978 # 800119e0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021a2:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021a4:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021a6:	00015917          	auipc	s2,0x15
    800021aa:	43a90913          	addi	s2,s2,1082 # 800175e0 <tickslock>
    800021ae:	a811                	j	800021c2 <wakeup+0x3c>
      }
      release(&p->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	ad8080e7          	jalr	-1320(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021ba:	17048493          	addi	s1,s1,368
    800021be:	03248663          	beq	s1,s2,800021ea <wakeup+0x64>
    if(p != myproc()){
    800021c2:	00000097          	auipc	ra,0x0
    800021c6:	820080e7          	jalr	-2016(ra) # 800019e2 <myproc>
    800021ca:	fea488e3          	beq	s1,a0,800021ba <wakeup+0x34>
      acquire(&p->lock);
    800021ce:	8526                	mv	a0,s1
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	a06080e7          	jalr	-1530(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021d8:	4c9c                	lw	a5,24(s1)
    800021da:	fd379be3          	bne	a5,s3,800021b0 <wakeup+0x2a>
    800021de:	709c                	ld	a5,32(s1)
    800021e0:	fd4798e3          	bne	a5,s4,800021b0 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021e4:	0154ac23          	sw	s5,24(s1)
    800021e8:	b7e1                	j	800021b0 <wakeup+0x2a>
    }
  }
}
    800021ea:	70e2                	ld	ra,56(sp)
    800021ec:	7442                	ld	s0,48(sp)
    800021ee:	74a2                	ld	s1,40(sp)
    800021f0:	7902                	ld	s2,32(sp)
    800021f2:	69e2                	ld	s3,24(sp)
    800021f4:	6a42                	ld	s4,16(sp)
    800021f6:	6aa2                	ld	s5,8(sp)
    800021f8:	6121                	addi	sp,sp,64
    800021fa:	8082                	ret

00000000800021fc <reparent>:
{
    800021fc:	7179                	addi	sp,sp,-48
    800021fe:	f406                	sd	ra,40(sp)
    80002200:	f022                	sd	s0,32(sp)
    80002202:	ec26                	sd	s1,24(sp)
    80002204:	e84a                	sd	s2,16(sp)
    80002206:	e44e                	sd	s3,8(sp)
    80002208:	e052                	sd	s4,0(sp)
    8000220a:	1800                	addi	s0,sp,48
    8000220c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000220e:	0000f497          	auipc	s1,0xf
    80002212:	7d248493          	addi	s1,s1,2002 # 800119e0 <proc>
      pp->parent = initproc;
    80002216:	00007a17          	auipc	s4,0x7
    8000221a:	122a0a13          	addi	s4,s4,290 # 80009338 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000221e:	00015997          	auipc	s3,0x15
    80002222:	3c298993          	addi	s3,s3,962 # 800175e0 <tickslock>
    80002226:	a029                	j	80002230 <reparent+0x34>
    80002228:	17048493          	addi	s1,s1,368
    8000222c:	01348d63          	beq	s1,s3,80002246 <reparent+0x4a>
    if(pp->parent == p){
    80002230:	7c9c                	ld	a5,56(s1)
    80002232:	ff279be3          	bne	a5,s2,80002228 <reparent+0x2c>
      pp->parent = initproc;
    80002236:	000a3503          	ld	a0,0(s4)
    8000223a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000223c:	00000097          	auipc	ra,0x0
    80002240:	f4a080e7          	jalr	-182(ra) # 80002186 <wakeup>
    80002244:	b7d5                	j	80002228 <reparent+0x2c>
}
    80002246:	70a2                	ld	ra,40(sp)
    80002248:	7402                	ld	s0,32(sp)
    8000224a:	64e2                	ld	s1,24(sp)
    8000224c:	6942                	ld	s2,16(sp)
    8000224e:	69a2                	ld	s3,8(sp)
    80002250:	6a02                	ld	s4,0(sp)
    80002252:	6145                	addi	sp,sp,48
    80002254:	8082                	ret

0000000080002256 <exit>:
{
    80002256:	7179                	addi	sp,sp,-48
    80002258:	f406                	sd	ra,40(sp)
    8000225a:	f022                	sd	s0,32(sp)
    8000225c:	ec26                	sd	s1,24(sp)
    8000225e:	e84a                	sd	s2,16(sp)
    80002260:	e44e                	sd	s3,8(sp)
    80002262:	e052                	sd	s4,0(sp)
    80002264:	1800                	addi	s0,sp,48
    80002266:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	77a080e7          	jalr	1914(ra) # 800019e2 <myproc>
    80002270:	89aa                	mv	s3,a0
  if(p == initproc)
    80002272:	00007797          	auipc	a5,0x7
    80002276:	0c67b783          	ld	a5,198(a5) # 80009338 <initproc>
    8000227a:	0d050493          	addi	s1,a0,208
    8000227e:	15050913          	addi	s2,a0,336
    80002282:	02a79363          	bne	a5,a0,800022a8 <exit+0x52>
    panic("init exiting");
    80002286:	00006517          	auipc	a0,0x6
    8000228a:	02250513          	addi	a0,a0,34 # 800082a8 <digits+0x268>
    8000228e:	ffffe097          	auipc	ra,0xffffe
    80002292:	2b0080e7          	jalr	688(ra) # 8000053e <panic>
      fileclose(f);
    80002296:	00002097          	auipc	ra,0x2
    8000229a:	4b0080e7          	jalr	1200(ra) # 80004746 <fileclose>
      p->ofile[fd] = 0;
    8000229e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022a2:	04a1                	addi	s1,s1,8
    800022a4:	01248563          	beq	s1,s2,800022ae <exit+0x58>
    if(p->ofile[fd]){
    800022a8:	6088                	ld	a0,0(s1)
    800022aa:	f575                	bnez	a0,80002296 <exit+0x40>
    800022ac:	bfdd                	j	800022a2 <exit+0x4c>
  begin_op();
    800022ae:	00002097          	auipc	ra,0x2
    800022b2:	fcc080e7          	jalr	-52(ra) # 8000427a <begin_op>
  iput(p->cwd);
    800022b6:	1509b503          	ld	a0,336(s3)
    800022ba:	00001097          	auipc	ra,0x1
    800022be:	7b8080e7          	jalr	1976(ra) # 80003a72 <iput>
  end_op();
    800022c2:	00002097          	auipc	ra,0x2
    800022c6:	038080e7          	jalr	56(ra) # 800042fa <end_op>
  p->cwd = 0;
    800022ca:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022ce:	0000f497          	auipc	s1,0xf
    800022d2:	2fa48493          	addi	s1,s1,762 # 800115c8 <wait_lock>
    800022d6:	8526                	mv	a0,s1
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	8fe080e7          	jalr	-1794(ra) # 80000bd6 <acquire>
  reparent(p);
    800022e0:	854e                	mv	a0,s3
    800022e2:	00000097          	auipc	ra,0x0
    800022e6:	f1a080e7          	jalr	-230(ra) # 800021fc <reparent>
  wakeup(p->parent);
    800022ea:	0389b503          	ld	a0,56(s3)
    800022ee:	00000097          	auipc	ra,0x0
    800022f2:	e98080e7          	jalr	-360(ra) # 80002186 <wakeup>
  acquire(&p->lock);
    800022f6:	854e                	mv	a0,s3
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	8de080e7          	jalr	-1826(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002300:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002304:	4795                	li	a5,5
    80002306:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000230a:	8526                	mv	a0,s1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	97e080e7          	jalr	-1666(ra) # 80000c8a <release>
  sched();
    80002314:	00000097          	auipc	ra,0x0
    80002318:	cfc080e7          	jalr	-772(ra) # 80002010 <sched>
  panic("zombie exit");
    8000231c:	00006517          	auipc	a0,0x6
    80002320:	f9c50513          	addi	a0,a0,-100 # 800082b8 <digits+0x278>
    80002324:	ffffe097          	auipc	ra,0xffffe
    80002328:	21a080e7          	jalr	538(ra) # 8000053e <panic>

000000008000232c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000232c:	7179                	addi	sp,sp,-48
    8000232e:	f406                	sd	ra,40(sp)
    80002330:	f022                	sd	s0,32(sp)
    80002332:	ec26                	sd	s1,24(sp)
    80002334:	e84a                	sd	s2,16(sp)
    80002336:	e44e                	sd	s3,8(sp)
    80002338:	1800                	addi	s0,sp,48
    8000233a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000233c:	0000f497          	auipc	s1,0xf
    80002340:	6a448493          	addi	s1,s1,1700 # 800119e0 <proc>
    80002344:	00015997          	auipc	s3,0x15
    80002348:	29c98993          	addi	s3,s3,668 # 800175e0 <tickslock>
    acquire(&p->lock);
    8000234c:	8526                	mv	a0,s1
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	888080e7          	jalr	-1912(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002356:	589c                	lw	a5,48(s1)
    80002358:	01278d63          	beq	a5,s2,80002372 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000235c:	8526                	mv	a0,s1
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	92c080e7          	jalr	-1748(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002366:	17048493          	addi	s1,s1,368
    8000236a:	ff3491e3          	bne	s1,s3,8000234c <kill+0x20>
  }
  return -1;
    8000236e:	557d                	li	a0,-1
    80002370:	a829                	j	8000238a <kill+0x5e>
      p->killed = 1;
    80002372:	4785                	li	a5,1
    80002374:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002376:	4c98                	lw	a4,24(s1)
    80002378:	4789                	li	a5,2
    8000237a:	00f70f63          	beq	a4,a5,80002398 <kill+0x6c>
      release(&p->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	90a080e7          	jalr	-1782(ra) # 80000c8a <release>
      return 0;
    80002388:	4501                	li	a0,0
}
    8000238a:	70a2                	ld	ra,40(sp)
    8000238c:	7402                	ld	s0,32(sp)
    8000238e:	64e2                	ld	s1,24(sp)
    80002390:	6942                	ld	s2,16(sp)
    80002392:	69a2                	ld	s3,8(sp)
    80002394:	6145                	addi	sp,sp,48
    80002396:	8082                	ret
        p->state = RUNNABLE;
    80002398:	478d                	li	a5,3
    8000239a:	cc9c                	sw	a5,24(s1)
    8000239c:	b7cd                	j	8000237e <kill+0x52>

000000008000239e <setkilled>:

void
setkilled(struct proc *p)
{
    8000239e:	1101                	addi	sp,sp,-32
    800023a0:	ec06                	sd	ra,24(sp)
    800023a2:	e822                	sd	s0,16(sp)
    800023a4:	e426                	sd	s1,8(sp)
    800023a6:	1000                	addi	s0,sp,32
    800023a8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	82c080e7          	jalr	-2004(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800023b2:	4785                	li	a5,1
    800023b4:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	8d2080e7          	jalr	-1838(ra) # 80000c8a <release>
}
    800023c0:	60e2                	ld	ra,24(sp)
    800023c2:	6442                	ld	s0,16(sp)
    800023c4:	64a2                	ld	s1,8(sp)
    800023c6:	6105                	addi	sp,sp,32
    800023c8:	8082                	ret

00000000800023ca <killed>:

int
killed(struct proc *p)
{
    800023ca:	1101                	addi	sp,sp,-32
    800023cc:	ec06                	sd	ra,24(sp)
    800023ce:	e822                	sd	s0,16(sp)
    800023d0:	e426                	sd	s1,8(sp)
    800023d2:	e04a                	sd	s2,0(sp)
    800023d4:	1000                	addi	s0,sp,32
    800023d6:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023d8:	ffffe097          	auipc	ra,0xffffe
    800023dc:	7fe080e7          	jalr	2046(ra) # 80000bd6 <acquire>
  k = p->killed;
    800023e0:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	8a4080e7          	jalr	-1884(ra) # 80000c8a <release>
  return k;
}
    800023ee:	854a                	mv	a0,s2
    800023f0:	60e2                	ld	ra,24(sp)
    800023f2:	6442                	ld	s0,16(sp)
    800023f4:	64a2                	ld	s1,8(sp)
    800023f6:	6902                	ld	s2,0(sp)
    800023f8:	6105                	addi	sp,sp,32
    800023fa:	8082                	ret

00000000800023fc <wait>:
{
    800023fc:	715d                	addi	sp,sp,-80
    800023fe:	e486                	sd	ra,72(sp)
    80002400:	e0a2                	sd	s0,64(sp)
    80002402:	fc26                	sd	s1,56(sp)
    80002404:	f84a                	sd	s2,48(sp)
    80002406:	f44e                	sd	s3,40(sp)
    80002408:	f052                	sd	s4,32(sp)
    8000240a:	ec56                	sd	s5,24(sp)
    8000240c:	e85a                	sd	s6,16(sp)
    8000240e:	e45e                	sd	s7,8(sp)
    80002410:	e062                	sd	s8,0(sp)
    80002412:	0880                	addi	s0,sp,80
    80002414:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	5cc080e7          	jalr	1484(ra) # 800019e2 <myproc>
    8000241e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002420:	0000f517          	auipc	a0,0xf
    80002424:	1a850513          	addi	a0,a0,424 # 800115c8 <wait_lock>
    80002428:	ffffe097          	auipc	ra,0xffffe
    8000242c:	7ae080e7          	jalr	1966(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002430:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002432:	4a15                	li	s4,5
        havekids = 1;
    80002434:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002436:	00015997          	auipc	s3,0x15
    8000243a:	1aa98993          	addi	s3,s3,426 # 800175e0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000243e:	0000fc17          	auipc	s8,0xf
    80002442:	18ac0c13          	addi	s8,s8,394 # 800115c8 <wait_lock>
    havekids = 0;
    80002446:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002448:	0000f497          	auipc	s1,0xf
    8000244c:	59848493          	addi	s1,s1,1432 # 800119e0 <proc>
    80002450:	a0bd                	j	800024be <wait+0xc2>
          pid = pp->pid;
    80002452:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002456:	000b0e63          	beqz	s6,80002472 <wait+0x76>
    8000245a:	4691                	li	a3,4
    8000245c:	02c48613          	addi	a2,s1,44
    80002460:	85da                	mv	a1,s6
    80002462:	05093503          	ld	a0,80(s2)
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	238080e7          	jalr	568(ra) # 8000169e <copyout>
    8000246e:	02054563          	bltz	a0,80002498 <wait+0x9c>
          freeproc(pp);
    80002472:	8526                	mv	a0,s1
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	720080e7          	jalr	1824(ra) # 80001b94 <freeproc>
          release(&pp->lock);
    8000247c:	8526                	mv	a0,s1
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	80c080e7          	jalr	-2036(ra) # 80000c8a <release>
          release(&wait_lock);
    80002486:	0000f517          	auipc	a0,0xf
    8000248a:	14250513          	addi	a0,a0,322 # 800115c8 <wait_lock>
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	7fc080e7          	jalr	2044(ra) # 80000c8a <release>
          return pid;
    80002496:	a0b5                	j	80002502 <wait+0x106>
            release(&pp->lock);
    80002498:	8526                	mv	a0,s1
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	7f0080e7          	jalr	2032(ra) # 80000c8a <release>
            release(&wait_lock);
    800024a2:	0000f517          	auipc	a0,0xf
    800024a6:	12650513          	addi	a0,a0,294 # 800115c8 <wait_lock>
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	7e0080e7          	jalr	2016(ra) # 80000c8a <release>
            return -1;
    800024b2:	59fd                	li	s3,-1
    800024b4:	a0b9                	j	80002502 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024b6:	17048493          	addi	s1,s1,368
    800024ba:	03348463          	beq	s1,s3,800024e2 <wait+0xe6>
      if(pp->parent == p){
    800024be:	7c9c                	ld	a5,56(s1)
    800024c0:	ff279be3          	bne	a5,s2,800024b6 <wait+0xba>
        acquire(&pp->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	710080e7          	jalr	1808(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    800024ce:	4c9c                	lw	a5,24(s1)
    800024d0:	f94781e3          	beq	a5,s4,80002452 <wait+0x56>
        release(&pp->lock);
    800024d4:	8526                	mv	a0,s1
    800024d6:	ffffe097          	auipc	ra,0xffffe
    800024da:	7b4080e7          	jalr	1972(ra) # 80000c8a <release>
        havekids = 1;
    800024de:	8756                	mv	a4,s5
    800024e0:	bfd9                	j	800024b6 <wait+0xba>
    if(!havekids || killed(p)){
    800024e2:	c719                	beqz	a4,800024f0 <wait+0xf4>
    800024e4:	854a                	mv	a0,s2
    800024e6:	00000097          	auipc	ra,0x0
    800024ea:	ee4080e7          	jalr	-284(ra) # 800023ca <killed>
    800024ee:	c51d                	beqz	a0,8000251c <wait+0x120>
      release(&wait_lock);
    800024f0:	0000f517          	auipc	a0,0xf
    800024f4:	0d850513          	addi	a0,a0,216 # 800115c8 <wait_lock>
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	792080e7          	jalr	1938(ra) # 80000c8a <release>
      return -1;
    80002500:	59fd                	li	s3,-1
}
    80002502:	854e                	mv	a0,s3
    80002504:	60a6                	ld	ra,72(sp)
    80002506:	6406                	ld	s0,64(sp)
    80002508:	74e2                	ld	s1,56(sp)
    8000250a:	7942                	ld	s2,48(sp)
    8000250c:	79a2                	ld	s3,40(sp)
    8000250e:	7a02                	ld	s4,32(sp)
    80002510:	6ae2                	ld	s5,24(sp)
    80002512:	6b42                	ld	s6,16(sp)
    80002514:	6ba2                	ld	s7,8(sp)
    80002516:	6c02                	ld	s8,0(sp)
    80002518:	6161                	addi	sp,sp,80
    8000251a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000251c:	85e2                	mv	a1,s8
    8000251e:	854a                	mv	a0,s2
    80002520:	00000097          	auipc	ra,0x0
    80002524:	c02080e7          	jalr	-1022(ra) # 80002122 <sleep>
    havekids = 0;
    80002528:	bf39                	j	80002446 <wait+0x4a>

000000008000252a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000252a:	7179                	addi	sp,sp,-48
    8000252c:	f406                	sd	ra,40(sp)
    8000252e:	f022                	sd	s0,32(sp)
    80002530:	ec26                	sd	s1,24(sp)
    80002532:	e84a                	sd	s2,16(sp)
    80002534:	e44e                	sd	s3,8(sp)
    80002536:	e052                	sd	s4,0(sp)
    80002538:	1800                	addi	s0,sp,48
    8000253a:	84aa                	mv	s1,a0
    8000253c:	892e                	mv	s2,a1
    8000253e:	89b2                	mv	s3,a2
    80002540:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	4a0080e7          	jalr	1184(ra) # 800019e2 <myproc>
  if(user_dst){
    8000254a:	c08d                	beqz	s1,8000256c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000254c:	86d2                	mv	a3,s4
    8000254e:	864e                	mv	a2,s3
    80002550:	85ca                	mv	a1,s2
    80002552:	6928                	ld	a0,80(a0)
    80002554:	fffff097          	auipc	ra,0xfffff
    80002558:	14a080e7          	jalr	330(ra) # 8000169e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000255c:	70a2                	ld	ra,40(sp)
    8000255e:	7402                	ld	s0,32(sp)
    80002560:	64e2                	ld	s1,24(sp)
    80002562:	6942                	ld	s2,16(sp)
    80002564:	69a2                	ld	s3,8(sp)
    80002566:	6a02                	ld	s4,0(sp)
    80002568:	6145                	addi	sp,sp,48
    8000256a:	8082                	ret
    memmove((char *)dst, src, len);
    8000256c:	000a061b          	sext.w	a2,s4
    80002570:	85ce                	mv	a1,s3
    80002572:	854a                	mv	a0,s2
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	7ba080e7          	jalr	1978(ra) # 80000d2e <memmove>
    return 0;
    8000257c:	8526                	mv	a0,s1
    8000257e:	bff9                	j	8000255c <either_copyout+0x32>

0000000080002580 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002580:	7179                	addi	sp,sp,-48
    80002582:	f406                	sd	ra,40(sp)
    80002584:	f022                	sd	s0,32(sp)
    80002586:	ec26                	sd	s1,24(sp)
    80002588:	e84a                	sd	s2,16(sp)
    8000258a:	e44e                	sd	s3,8(sp)
    8000258c:	e052                	sd	s4,0(sp)
    8000258e:	1800                	addi	s0,sp,48
    80002590:	892a                	mv	s2,a0
    80002592:	84ae                	mv	s1,a1
    80002594:	89b2                	mv	s3,a2
    80002596:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002598:	fffff097          	auipc	ra,0xfffff
    8000259c:	44a080e7          	jalr	1098(ra) # 800019e2 <myproc>
  if(user_src){
    800025a0:	c08d                	beqz	s1,800025c2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025a2:	86d2                	mv	a3,s4
    800025a4:	864e                	mv	a2,s3
    800025a6:	85ca                	mv	a1,s2
    800025a8:	6928                	ld	a0,80(a0)
    800025aa:	fffff097          	auipc	ra,0xfffff
    800025ae:	180080e7          	jalr	384(ra) # 8000172a <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025b2:	70a2                	ld	ra,40(sp)
    800025b4:	7402                	ld	s0,32(sp)
    800025b6:	64e2                	ld	s1,24(sp)
    800025b8:	6942                	ld	s2,16(sp)
    800025ba:	69a2                	ld	s3,8(sp)
    800025bc:	6a02                	ld	s4,0(sp)
    800025be:	6145                	addi	sp,sp,48
    800025c0:	8082                	ret
    memmove(dst, (char*)src, len);
    800025c2:	000a061b          	sext.w	a2,s4
    800025c6:	85ce                	mv	a1,s3
    800025c8:	854a                	mv	a0,s2
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	764080e7          	jalr	1892(ra) # 80000d2e <memmove>
    return 0;
    800025d2:	8526                	mv	a0,s1
    800025d4:	bff9                	j	800025b2 <either_copyin+0x32>

00000000800025d6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025d6:	715d                	addi	sp,sp,-80
    800025d8:	e486                	sd	ra,72(sp)
    800025da:	e0a2                	sd	s0,64(sp)
    800025dc:	fc26                	sd	s1,56(sp)
    800025de:	f84a                	sd	s2,48(sp)
    800025e0:	f44e                	sd	s3,40(sp)
    800025e2:	f052                	sd	s4,32(sp)
    800025e4:	ec56                	sd	s5,24(sp)
    800025e6:	e85a                	sd	s6,16(sp)
    800025e8:	e45e                	sd	s7,8(sp)
    800025ea:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ec:	00006517          	auipc	a0,0x6
    800025f0:	d0c50513          	addi	a0,a0,-756 # 800082f8 <digits+0x2b8>
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	f94080e7          	jalr	-108(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025fc:	0000f497          	auipc	s1,0xf
    80002600:	53c48493          	addi	s1,s1,1340 # 80011b38 <proc+0x158>
    80002604:	00015917          	auipc	s2,0x15
    80002608:	13490913          	addi	s2,s2,308 # 80017738 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000260c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000260e:	00006997          	auipc	s3,0x6
    80002612:	cba98993          	addi	s3,s3,-838 # 800082c8 <digits+0x288>
    printf("%d %s %s", p->pid, state, p->name);
    80002616:	00006a97          	auipc	s5,0x6
    8000261a:	cbaa8a93          	addi	s5,s5,-838 # 800082d0 <digits+0x290>
    printf("\n");
    8000261e:	00006a17          	auipc	s4,0x6
    80002622:	cdaa0a13          	addi	s4,s4,-806 # 800082f8 <digits+0x2b8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002626:	00006b97          	auipc	s7,0x6
    8000262a:	d72b8b93          	addi	s7,s7,-654 # 80008398 <states.0>
    8000262e:	a00d                	j	80002650 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002630:	ed86a583          	lw	a1,-296(a3)
    80002634:	8556                	mv	a0,s5
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	f52080e7          	jalr	-174(ra) # 80000588 <printf>
    printf("\n");
    8000263e:	8552                	mv	a0,s4
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	f48080e7          	jalr	-184(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002648:	17048493          	addi	s1,s1,368
    8000264c:	03248163          	beq	s1,s2,8000266e <procdump+0x98>
    if(p->state == UNUSED)
    80002650:	86a6                	mv	a3,s1
    80002652:	ec04a783          	lw	a5,-320(s1)
    80002656:	dbed                	beqz	a5,80002648 <procdump+0x72>
      state = "???";
    80002658:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000265a:	fcfb6be3          	bltu	s6,a5,80002630 <procdump+0x5a>
    8000265e:	1782                	slli	a5,a5,0x20
    80002660:	9381                	srli	a5,a5,0x20
    80002662:	078e                	slli	a5,a5,0x3
    80002664:	97de                	add	a5,a5,s7
    80002666:	6390                	ld	a2,0(a5)
    80002668:	f661                	bnez	a2,80002630 <procdump+0x5a>
      state = "???";
    8000266a:	864e                	mv	a2,s3
    8000266c:	b7d1                	j	80002630 <procdump+0x5a>
  }
}
    8000266e:	60a6                	ld	ra,72(sp)
    80002670:	6406                	ld	s0,64(sp)
    80002672:	74e2                	ld	s1,56(sp)
    80002674:	7942                	ld	s2,48(sp)
    80002676:	79a2                	ld	s3,40(sp)
    80002678:	7a02                	ld	s4,32(sp)
    8000267a:	6ae2                	ld	s5,24(sp)
    8000267c:	6b42                	ld	s6,16(sp)
    8000267e:	6ba2                	ld	s7,8(sp)
    80002680:	6161                	addi	sp,sp,80
    80002682:	8082                	ret

0000000080002684 <map_display>:

void*
map_display(void* addr) {
    80002684:	7139                	addi	sp,sp,-64
    80002686:	fc06                	sd	ra,56(sp)
    80002688:	f822                	sd	s0,48(sp)
    8000268a:	f426                	sd	s1,40(sp)
    8000268c:	f04a                	sd	s2,32(sp)
    8000268e:	ec4e                	sd	s3,24(sp)
    80002690:	e852                	sd	s4,16(sp)
    80002692:	e456                	sd	s5,8(sp)
    80002694:	e05a                	sd	s6,0(sp)
    80002696:	0080                	addi	s0,sp,64
    80002698:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    8000269a:	fffff097          	auipc	ra,0xfffff
    8000269e:	348080e7          	jalr	840(ra) # 800019e2 <myproc>
    800026a2:	892a                	mv	s2,a0
  uint64 va = (uint64)addr;
  // uint64 fb_pa = (uint64)get_fb_addr();
  if(va == 0){
    800026a4:	020a8463          	beqz	s5,800026cc <map_display+0x48>
    printf("line 707\n");
    va = PGROUNDUP(p->sz);
  }
  if (va % PGSIZE != 0) {
    800026a8:	034a9793          	slli	a5,s5,0x34
    800026ac:	e3a9                	bnez	a5,800026ee <map_display+0x6a>
    printf("line 711\n");
    return (void*)-1; 
  }
  printf("line 713, va: %p\n", va);
    800026ae:	85d6                	mv	a1,s5
    800026b0:	00006517          	auipc	a0,0x6
    800026b4:	c5050513          	addi	a0,a0,-944 # 80008300 <digits+0x2c0>
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	ed0080e7          	jalr	-304(ra) # 80000588 <printf>
  for(int i = 0; i < GPU_FB_PAGES; i++){
    800026c0:	0012c9b7          	lui	s3,0x12c
    800026c4:	99d6                	add	s3,s3,s5
  printf("line 713, va: %p\n", va);
    800026c6:	84d6                	mv	s1,s5
  for(int i = 0; i < GPU_FB_PAGES; i++){
    800026c8:	6a05                	lui	s4,0x1
    800026ca:	a83d                	j	80002708 <map_display+0x84>
    printf("line 707\n");
    800026cc:	00006517          	auipc	a0,0x6
    800026d0:	c1450513          	addi	a0,a0,-1004 # 800082e0 <digits+0x2a0>
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	eb4080e7          	jalr	-332(ra) # 80000588 <printf>
    va = PGROUNDUP(p->sz);
    800026dc:	04893a83          	ld	s5,72(s2)
    800026e0:	6785                	lui	a5,0x1
    800026e2:	17fd                	addi	a5,a5,-1
    800026e4:	9abe                	add	s5,s5,a5
    800026e6:	77fd                	lui	a5,0xfffff
    800026e8:	00fafab3          	and	s5,s5,a5
    800026ec:	bf75                	j	800026a8 <map_display+0x24>
    printf("line 711\n");
    800026ee:	00006517          	auipc	a0,0x6
    800026f2:	c0250513          	addi	a0,a0,-1022 # 800082f0 <digits+0x2b0>
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	e92080e7          	jalr	-366(ra) # 80000588 <printf>
    return (void*)-1; 
    800026fe:	557d                	li	a0,-1
    80002700:	a00d                	j	80002722 <map_display+0x9e>
  for(int i = 0; i < GPU_FB_PAGES; i++){
    80002702:	94d2                	add	s1,s1,s4
    80002704:	02998963          	beq	s3,s1,80002736 <map_display+0xb2>
    pte_t *pte = walk(p->pagetable, va + (i * PGSIZE), 0);
    80002708:	4601                	li	a2,0
    8000270a:	85a6                	mv	a1,s1
    8000270c:	05093503          	ld	a0,80(s2)
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	8c6080e7          	jalr	-1850(ra) # 80000fd6 <walk>
    if(pte != 0 && (*pte & PTE_V) != 0){
    80002718:	d56d                	beqz	a0,80002702 <map_display+0x7e>
    8000271a:	611c                	ld	a5,0(a0)
    8000271c:	8b85                	andi	a5,a5,1
    8000271e:	d3f5                	beqz	a5,80002702 <map_display+0x7e>
      return (void*)-1;
    80002720:	557d                	li	a0,-1
  }
  else{
    printf("line 734\n");
    return (void*)-1;
  }
    80002722:	70e2                	ld	ra,56(sp)
    80002724:	7442                	ld	s0,48(sp)
    80002726:	74a2                	ld	s1,40(sp)
    80002728:	7902                	ld	s2,32(sp)
    8000272a:	69e2                	ld	s3,24(sp)
    8000272c:	6a42                	ld	s4,16(sp)
    8000272e:	6aa2                	ld	s5,8(sp)
    80002730:	6b02                	ld	s6,0(sp)
    80002732:	6121                	addi	sp,sp,64
    80002734:	8082                	ret
  printf("line 722\n");
    80002736:	00006517          	auipc	a0,0x6
    8000273a:	be250513          	addi	a0,a0,-1054 # 80008318 <digits+0x2d8>
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	e4a080e7          	jalr	-438(ra) # 80000588 <printf>
    80002746:	8a56                	mv	s4,s5
  for(int i = 0; i < GPU_FB_PAGES; i++) {
    80002748:	4481                	li	s1,0
    8000274a:	12c00b13          	li	s6,300
    uint64 current_pa = (uint64)get_fb_page(i); 
    8000274e:	8526                	mv	a0,s1
    80002750:	00004097          	auipc	ra,0x4
    80002754:	40a080e7          	jalr	1034(ra) # 80006b5a <get_fb_page>
    80002758:	86aa                	mv	a3,a0
    if (current_pa == 0) {
    8000275a:	c535                	beqz	a0,800027c6 <map_display+0x142>
    if (mappages(p->pagetable, current_va, PGSIZE, current_pa, PTE_U|PTE_R|PTE_W) != 0) {
    8000275c:	4759                	li	a4,22
    8000275e:	6605                	lui	a2,0x1
    80002760:	85d2                	mv	a1,s4
    80002762:	05093503          	ld	a0,80(s2)
    80002766:	fffff097          	auipc	ra,0xfffff
    8000276a:	958080e7          	jalr	-1704(ra) # 800010be <mappages>
    8000276e:	ed21                	bnez	a0,800027c6 <map_display+0x142>
  for(int i = 0; i < GPU_FB_PAGES; i++) {
    80002770:	2485                	addiw	s1,s1,1
    80002772:	6785                	lui	a5,0x1
    80002774:	9a3e                	add	s4,s4,a5
    80002776:	fd649ce3          	bne	s1,s6,8000274e <map_display+0xca>
  printf("line 726, suc: %d\n", suc);
    8000277a:	4581                	li	a1,0
    8000277c:	00006517          	auipc	a0,0x6
    80002780:	bc450513          	addi	a0,a0,-1084 # 80008340 <digits+0x300>
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	e04080e7          	jalr	-508(ra) # 80000588 <printf>
    if(va == PGROUNDUP(p->sz)) {
    8000278c:	04893783          	ld	a5,72(s2)
    80002790:	6705                	lui	a4,0x1
    80002792:	177d                	addi	a4,a4,-1
    80002794:	97ba                	add	a5,a5,a4
    80002796:	777d                	lui	a4,0xfffff
    80002798:	8ff9                	and	a5,a5,a4
    8000279a:	03578363          	beq	a5,s5,800027c0 <map_display+0x13c>
    printf("line 731, va: %p\n", va);
    8000279e:	85d6                	mv	a1,s5
    800027a0:	00006517          	auipc	a0,0x6
    800027a4:	b8850513          	addi	a0,a0,-1144 # 80008328 <digits+0x2e8>
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	de0080e7          	jalr	-544(ra) # 80000588 <printf>
    myproc()->va_loc = va;
    800027b0:	fffff097          	auipc	ra,0xfffff
    800027b4:	232080e7          	jalr	562(ra) # 800019e2 <myproc>
    800027b8:	17553423          	sd	s5,360(a0)
    return (void*)va;
    800027bc:	8556                	mv	a0,s5
    800027be:	b795                	j	80002722 <map_display+0x9e>
      p->sz = va + size;
    800027c0:	05393423          	sd	s3,72(s2)
    800027c4:	bfe9                	j	8000279e <map_display+0x11a>
  printf("line 726, suc: %d\n", suc);
    800027c6:	55fd                	li	a1,-1
    800027c8:	00006517          	auipc	a0,0x6
    800027cc:	b7850513          	addi	a0,a0,-1160 # 80008340 <digits+0x300>
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	db8080e7          	jalr	-584(ra) # 80000588 <printf>
    printf("line 734\n");
    800027d8:	00006517          	auipc	a0,0x6
    800027dc:	b8050513          	addi	a0,a0,-1152 # 80008358 <digits+0x318>
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	da8080e7          	jalr	-600(ra) # 80000588 <printf>
    return (void*)-1;
    800027e8:	557d                	li	a0,-1
    800027ea:	bf25                	j	80002722 <map_display+0x9e>

00000000800027ec <swtch>:
    800027ec:	00153023          	sd	ra,0(a0)
    800027f0:	00253423          	sd	sp,8(a0)
    800027f4:	e900                	sd	s0,16(a0)
    800027f6:	ed04                	sd	s1,24(a0)
    800027f8:	03253023          	sd	s2,32(a0)
    800027fc:	03353423          	sd	s3,40(a0)
    80002800:	03453823          	sd	s4,48(a0)
    80002804:	03553c23          	sd	s5,56(a0)
    80002808:	05653023          	sd	s6,64(a0)
    8000280c:	05753423          	sd	s7,72(a0)
    80002810:	05853823          	sd	s8,80(a0)
    80002814:	05953c23          	sd	s9,88(a0)
    80002818:	07a53023          	sd	s10,96(a0)
    8000281c:	07b53423          	sd	s11,104(a0)
    80002820:	0005b083          	ld	ra,0(a1)
    80002824:	0085b103          	ld	sp,8(a1)
    80002828:	6980                	ld	s0,16(a1)
    8000282a:	6d84                	ld	s1,24(a1)
    8000282c:	0205b903          	ld	s2,32(a1)
    80002830:	0285b983          	ld	s3,40(a1)
    80002834:	0305ba03          	ld	s4,48(a1)
    80002838:	0385ba83          	ld	s5,56(a1)
    8000283c:	0405bb03          	ld	s6,64(a1)
    80002840:	0485bb83          	ld	s7,72(a1)
    80002844:	0505bc03          	ld	s8,80(a1)
    80002848:	0585bc83          	ld	s9,88(a1)
    8000284c:	0605bd03          	ld	s10,96(a1)
    80002850:	0685bd83          	ld	s11,104(a1)
    80002854:	8082                	ret

0000000080002856 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002856:	1141                	addi	sp,sp,-16
    80002858:	e406                	sd	ra,8(sp)
    8000285a:	e022                	sd	s0,0(sp)
    8000285c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000285e:	00006597          	auipc	a1,0x6
    80002862:	b6a58593          	addi	a1,a1,-1174 # 800083c8 <states.0+0x30>
    80002866:	00015517          	auipc	a0,0x15
    8000286a:	d7a50513          	addi	a0,a0,-646 # 800175e0 <tickslock>
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	2d8080e7          	jalr	728(ra) # 80000b46 <initlock>
}
    80002876:	60a2                	ld	ra,8(sp)
    80002878:	6402                	ld	s0,0(sp)
    8000287a:	0141                	addi	sp,sp,16
    8000287c:	8082                	ret

000000008000287e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000287e:	1141                	addi	sp,sp,-16
    80002880:	e422                	sd	s0,8(sp)
    80002882:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002884:	00003797          	auipc	a5,0x3
    80002888:	50c78793          	addi	a5,a5,1292 # 80005d90 <kernelvec>
    8000288c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002890:	6422                	ld	s0,8(sp)
    80002892:	0141                	addi	sp,sp,16
    80002894:	8082                	ret

0000000080002896 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002896:	1141                	addi	sp,sp,-16
    80002898:	e406                	sd	ra,8(sp)
    8000289a:	e022                	sd	s0,0(sp)
    8000289c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000289e:	fffff097          	auipc	ra,0xfffff
    800028a2:	144080e7          	jalr	324(ra) # 800019e2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028aa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ac:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800028b0:	00004617          	auipc	a2,0x4
    800028b4:	75060613          	addi	a2,a2,1872 # 80007000 <_trampoline>
    800028b8:	00004697          	auipc	a3,0x4
    800028bc:	74868693          	addi	a3,a3,1864 # 80007000 <_trampoline>
    800028c0:	8e91                	sub	a3,a3,a2
    800028c2:	040007b7          	lui	a5,0x4000
    800028c6:	17fd                	addi	a5,a5,-1
    800028c8:	07b2                	slli	a5,a5,0xc
    800028ca:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028cc:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028d0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028d2:	180026f3          	csrr	a3,satp
    800028d6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028d8:	6d38                	ld	a4,88(a0)
    800028da:	6134                	ld	a3,64(a0)
    800028dc:	6585                	lui	a1,0x1
    800028de:	96ae                	add	a3,a3,a1
    800028e0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028e2:	6d38                	ld	a4,88(a0)
    800028e4:	00000697          	auipc	a3,0x0
    800028e8:	13068693          	addi	a3,a3,304 # 80002a14 <usertrap>
    800028ec:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028ee:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028f0:	8692                	mv	a3,tp
    800028f2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028f8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028fc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002900:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002904:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002906:	6f18                	ld	a4,24(a4)
    80002908:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000290c:	6928                	ld	a0,80(a0)
    8000290e:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002910:	00004717          	auipc	a4,0x4
    80002914:	78c70713          	addi	a4,a4,1932 # 8000709c <userret>
    80002918:	8f11                	sub	a4,a4,a2
    8000291a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000291c:	577d                	li	a4,-1
    8000291e:	177e                	slli	a4,a4,0x3f
    80002920:	8d59                	or	a0,a0,a4
    80002922:	9782                	jalr	a5
}
    80002924:	60a2                	ld	ra,8(sp)
    80002926:	6402                	ld	s0,0(sp)
    80002928:	0141                	addi	sp,sp,16
    8000292a:	8082                	ret

000000008000292c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000292c:	1101                	addi	sp,sp,-32
    8000292e:	ec06                	sd	ra,24(sp)
    80002930:	e822                	sd	s0,16(sp)
    80002932:	e426                	sd	s1,8(sp)
    80002934:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002936:	00015497          	auipc	s1,0x15
    8000293a:	caa48493          	addi	s1,s1,-854 # 800175e0 <tickslock>
    8000293e:	8526                	mv	a0,s1
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	296080e7          	jalr	662(ra) # 80000bd6 <acquire>
  ticks++;
    80002948:	00007517          	auipc	a0,0x7
    8000294c:	9f850513          	addi	a0,a0,-1544 # 80009340 <ticks>
    80002950:	411c                	lw	a5,0(a0)
    80002952:	2785                	addiw	a5,a5,1
    80002954:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002956:	00000097          	auipc	ra,0x0
    8000295a:	830080e7          	jalr	-2000(ra) # 80002186 <wakeup>
  release(&tickslock);
    8000295e:	8526                	mv	a0,s1
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	32a080e7          	jalr	810(ra) # 80000c8a <release>
}
    80002968:	60e2                	ld	ra,24(sp)
    8000296a:	6442                	ld	s0,16(sp)
    8000296c:	64a2                	ld	s1,8(sp)
    8000296e:	6105                	addi	sp,sp,32
    80002970:	8082                	ret

0000000080002972 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002972:	1101                	addi	sp,sp,-32
    80002974:	ec06                	sd	ra,24(sp)
    80002976:	e822                	sd	s0,16(sp)
    80002978:	e426                	sd	s1,8(sp)
    8000297a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000297c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002980:	00074d63          	bltz	a4,8000299a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002984:	57fd                	li	a5,-1
    80002986:	17fe                	slli	a5,a5,0x3f
    80002988:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000298a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000298c:	06f70363          	beq	a4,a5,800029f2 <devintr+0x80>
  }
}
    80002990:	60e2                	ld	ra,24(sp)
    80002992:	6442                	ld	s0,16(sp)
    80002994:	64a2                	ld	s1,8(sp)
    80002996:	6105                	addi	sp,sp,32
    80002998:	8082                	ret
     (scause & 0xff) == 9){
    8000299a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000299e:	46a5                	li	a3,9
    800029a0:	fed792e3          	bne	a5,a3,80002984 <devintr+0x12>
    int irq = plic_claim();
    800029a4:	00003097          	auipc	ra,0x3
    800029a8:	4f4080e7          	jalr	1268(ra) # 80005e98 <plic_claim>
    800029ac:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029ae:	47a9                	li	a5,10
    800029b0:	02f50763          	beq	a0,a5,800029de <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029b4:	4785                	li	a5,1
    800029b6:	02f50963          	beq	a0,a5,800029e8 <devintr+0x76>
    return 1;
    800029ba:	4505                	li	a0,1
    } else if(irq){
    800029bc:	d8f1                	beqz	s1,80002990 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029be:	85a6                	mv	a1,s1
    800029c0:	00006517          	auipc	a0,0x6
    800029c4:	a1050513          	addi	a0,a0,-1520 # 800083d0 <states.0+0x38>
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	bc0080e7          	jalr	-1088(ra) # 80000588 <printf>
      plic_complete(irq);
    800029d0:	8526                	mv	a0,s1
    800029d2:	00003097          	auipc	ra,0x3
    800029d6:	4ea080e7          	jalr	1258(ra) # 80005ebc <plic_complete>
    return 1;
    800029da:	4505                	li	a0,1
    800029dc:	bf55                	j	80002990 <devintr+0x1e>
      uartintr();
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	fbc080e7          	jalr	-68(ra) # 8000099a <uartintr>
    800029e6:	b7ed                	j	800029d0 <devintr+0x5e>
      virtio_disk_intr();
    800029e8:	00004097          	auipc	ra,0x4
    800029ec:	9a0080e7          	jalr	-1632(ra) # 80006388 <virtio_disk_intr>
    800029f0:	b7c5                	j	800029d0 <devintr+0x5e>
    if(cpuid() == 0){
    800029f2:	fffff097          	auipc	ra,0xfffff
    800029f6:	fc4080e7          	jalr	-60(ra) # 800019b6 <cpuid>
    800029fa:	c901                	beqz	a0,80002a0a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029fc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a00:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a02:	14479073          	csrw	sip,a5
    return 2;
    80002a06:	4509                	li	a0,2
    80002a08:	b761                	j	80002990 <devintr+0x1e>
      clockintr();
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	f22080e7          	jalr	-222(ra) # 8000292c <clockintr>
    80002a12:	b7ed                	j	800029fc <devintr+0x8a>

0000000080002a14 <usertrap>:
{
    80002a14:	1101                	addi	sp,sp,-32
    80002a16:	ec06                	sd	ra,24(sp)
    80002a18:	e822                	sd	s0,16(sp)
    80002a1a:	e426                	sd	s1,8(sp)
    80002a1c:	e04a                	sd	s2,0(sp)
    80002a1e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a20:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a24:	1007f793          	andi	a5,a5,256
    80002a28:	e3b1                	bnez	a5,80002a6c <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a2a:	00003797          	auipc	a5,0x3
    80002a2e:	36678793          	addi	a5,a5,870 # 80005d90 <kernelvec>
    80002a32:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a36:	fffff097          	auipc	ra,0xfffff
    80002a3a:	fac080e7          	jalr	-84(ra) # 800019e2 <myproc>
    80002a3e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a40:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a42:	14102773          	csrr	a4,sepc
    80002a46:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a48:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a4c:	47a1                	li	a5,8
    80002a4e:	02f70763          	beq	a4,a5,80002a7c <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002a52:	00000097          	auipc	ra,0x0
    80002a56:	f20080e7          	jalr	-224(ra) # 80002972 <devintr>
    80002a5a:	892a                	mv	s2,a0
    80002a5c:	c151                	beqz	a0,80002ae0 <usertrap+0xcc>
  if(killed(p))
    80002a5e:	8526                	mv	a0,s1
    80002a60:	00000097          	auipc	ra,0x0
    80002a64:	96a080e7          	jalr	-1686(ra) # 800023ca <killed>
    80002a68:	c929                	beqz	a0,80002aba <usertrap+0xa6>
    80002a6a:	a099                	j	80002ab0 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a6c:	00006517          	auipc	a0,0x6
    80002a70:	98450513          	addi	a0,a0,-1660 # 800083f0 <states.0+0x58>
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	aca080e7          	jalr	-1334(ra) # 8000053e <panic>
    if(killed(p))
    80002a7c:	00000097          	auipc	ra,0x0
    80002a80:	94e080e7          	jalr	-1714(ra) # 800023ca <killed>
    80002a84:	e921                	bnez	a0,80002ad4 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002a86:	6cb8                	ld	a4,88(s1)
    80002a88:	6f1c                	ld	a5,24(a4)
    80002a8a:	0791                	addi	a5,a5,4
    80002a8c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a8e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a92:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a96:	10079073          	csrw	sstatus,a5
    syscall();
    80002a9a:	00000097          	auipc	ra,0x0
    80002a9e:	2d4080e7          	jalr	724(ra) # 80002d6e <syscall>
  if(killed(p))
    80002aa2:	8526                	mv	a0,s1
    80002aa4:	00000097          	auipc	ra,0x0
    80002aa8:	926080e7          	jalr	-1754(ra) # 800023ca <killed>
    80002aac:	c911                	beqz	a0,80002ac0 <usertrap+0xac>
    80002aae:	4901                	li	s2,0
    exit(-1);
    80002ab0:	557d                	li	a0,-1
    80002ab2:	fffff097          	auipc	ra,0xfffff
    80002ab6:	7a4080e7          	jalr	1956(ra) # 80002256 <exit>
  if(which_dev == 2)
    80002aba:	4789                	li	a5,2
    80002abc:	04f90f63          	beq	s2,a5,80002b1a <usertrap+0x106>
  usertrapret();
    80002ac0:	00000097          	auipc	ra,0x0
    80002ac4:	dd6080e7          	jalr	-554(ra) # 80002896 <usertrapret>
}
    80002ac8:	60e2                	ld	ra,24(sp)
    80002aca:	6442                	ld	s0,16(sp)
    80002acc:	64a2                	ld	s1,8(sp)
    80002ace:	6902                	ld	s2,0(sp)
    80002ad0:	6105                	addi	sp,sp,32
    80002ad2:	8082                	ret
      exit(-1);
    80002ad4:	557d                	li	a0,-1
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	780080e7          	jalr	1920(ra) # 80002256 <exit>
    80002ade:	b765                	j	80002a86 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ae4:	5890                	lw	a2,48(s1)
    80002ae6:	00006517          	auipc	a0,0x6
    80002aea:	92a50513          	addi	a0,a0,-1750 # 80008410 <states.0+0x78>
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	a9a080e7          	jalr	-1382(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002afa:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002afe:	00006517          	auipc	a0,0x6
    80002b02:	94250513          	addi	a0,a0,-1726 # 80008440 <states.0+0xa8>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	a82080e7          	jalr	-1406(ra) # 80000588 <printf>
    setkilled(p);
    80002b0e:	8526                	mv	a0,s1
    80002b10:	00000097          	auipc	ra,0x0
    80002b14:	88e080e7          	jalr	-1906(ra) # 8000239e <setkilled>
    80002b18:	b769                	j	80002aa2 <usertrap+0x8e>
    yield();
    80002b1a:	fffff097          	auipc	ra,0xfffff
    80002b1e:	5cc080e7          	jalr	1484(ra) # 800020e6 <yield>
    80002b22:	bf79                	j	80002ac0 <usertrap+0xac>

0000000080002b24 <kerneltrap>:
{
    80002b24:	7179                	addi	sp,sp,-48
    80002b26:	f406                	sd	ra,40(sp)
    80002b28:	f022                	sd	s0,32(sp)
    80002b2a:	ec26                	sd	s1,24(sp)
    80002b2c:	e84a                	sd	s2,16(sp)
    80002b2e:	e44e                	sd	s3,8(sp)
    80002b30:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b32:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b36:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b3a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b3e:	1004f793          	andi	a5,s1,256
    80002b42:	cb85                	beqz	a5,80002b72 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b44:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b48:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b4a:	ef85                	bnez	a5,80002b82 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b4c:	00000097          	auipc	ra,0x0
    80002b50:	e26080e7          	jalr	-474(ra) # 80002972 <devintr>
    80002b54:	cd1d                	beqz	a0,80002b92 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b56:	4789                	li	a5,2
    80002b58:	06f50a63          	beq	a0,a5,80002bcc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b5c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b60:	10049073          	csrw	sstatus,s1
}
    80002b64:	70a2                	ld	ra,40(sp)
    80002b66:	7402                	ld	s0,32(sp)
    80002b68:	64e2                	ld	s1,24(sp)
    80002b6a:	6942                	ld	s2,16(sp)
    80002b6c:	69a2                	ld	s3,8(sp)
    80002b6e:	6145                	addi	sp,sp,48
    80002b70:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b72:	00006517          	auipc	a0,0x6
    80002b76:	8ee50513          	addi	a0,a0,-1810 # 80008460 <states.0+0xc8>
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	9c4080e7          	jalr	-1596(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b82:	00006517          	auipc	a0,0x6
    80002b86:	90650513          	addi	a0,a0,-1786 # 80008488 <states.0+0xf0>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	9b4080e7          	jalr	-1612(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b92:	85ce                	mv	a1,s3
    80002b94:	00006517          	auipc	a0,0x6
    80002b98:	91450513          	addi	a0,a0,-1772 # 800084a8 <states.0+0x110>
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	9ec080e7          	jalr	-1556(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ba8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bac:	00006517          	auipc	a0,0x6
    80002bb0:	90c50513          	addi	a0,a0,-1780 # 800084b8 <states.0+0x120>
    80002bb4:	ffffe097          	auipc	ra,0xffffe
    80002bb8:	9d4080e7          	jalr	-1580(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002bbc:	00006517          	auipc	a0,0x6
    80002bc0:	91450513          	addi	a0,a0,-1772 # 800084d0 <states.0+0x138>
    80002bc4:	ffffe097          	auipc	ra,0xffffe
    80002bc8:	97a080e7          	jalr	-1670(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bcc:	fffff097          	auipc	ra,0xfffff
    80002bd0:	e16080e7          	jalr	-490(ra) # 800019e2 <myproc>
    80002bd4:	d541                	beqz	a0,80002b5c <kerneltrap+0x38>
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	e0c080e7          	jalr	-500(ra) # 800019e2 <myproc>
    80002bde:	4d18                	lw	a4,24(a0)
    80002be0:	4791                	li	a5,4
    80002be2:	f6f71de3          	bne	a4,a5,80002b5c <kerneltrap+0x38>
    yield();
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	500080e7          	jalr	1280(ra) # 800020e6 <yield>
    80002bee:	b7bd                	j	80002b5c <kerneltrap+0x38>

0000000080002bf0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bf0:	1101                	addi	sp,sp,-32
    80002bf2:	ec06                	sd	ra,24(sp)
    80002bf4:	e822                	sd	s0,16(sp)
    80002bf6:	e426                	sd	s1,8(sp)
    80002bf8:	1000                	addi	s0,sp,32
    80002bfa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	de6080e7          	jalr	-538(ra) # 800019e2 <myproc>
  switch (n) {
    80002c04:	4795                	li	a5,5
    80002c06:	0497e163          	bltu	a5,s1,80002c48 <argraw+0x58>
    80002c0a:	048a                	slli	s1,s1,0x2
    80002c0c:	00006717          	auipc	a4,0x6
    80002c10:	8fc70713          	addi	a4,a4,-1796 # 80008508 <states.0+0x170>
    80002c14:	94ba                	add	s1,s1,a4
    80002c16:	409c                	lw	a5,0(s1)
    80002c18:	97ba                	add	a5,a5,a4
    80002c1a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c1c:	6d3c                	ld	a5,88(a0)
    80002c1e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c20:	60e2                	ld	ra,24(sp)
    80002c22:	6442                	ld	s0,16(sp)
    80002c24:	64a2                	ld	s1,8(sp)
    80002c26:	6105                	addi	sp,sp,32
    80002c28:	8082                	ret
    return p->trapframe->a1;
    80002c2a:	6d3c                	ld	a5,88(a0)
    80002c2c:	7fa8                	ld	a0,120(a5)
    80002c2e:	bfcd                	j	80002c20 <argraw+0x30>
    return p->trapframe->a2;
    80002c30:	6d3c                	ld	a5,88(a0)
    80002c32:	63c8                	ld	a0,128(a5)
    80002c34:	b7f5                	j	80002c20 <argraw+0x30>
    return p->trapframe->a3;
    80002c36:	6d3c                	ld	a5,88(a0)
    80002c38:	67c8                	ld	a0,136(a5)
    80002c3a:	b7dd                	j	80002c20 <argraw+0x30>
    return p->trapframe->a4;
    80002c3c:	6d3c                	ld	a5,88(a0)
    80002c3e:	6bc8                	ld	a0,144(a5)
    80002c40:	b7c5                	j	80002c20 <argraw+0x30>
    return p->trapframe->a5;
    80002c42:	6d3c                	ld	a5,88(a0)
    80002c44:	6fc8                	ld	a0,152(a5)
    80002c46:	bfe9                	j	80002c20 <argraw+0x30>
  panic("argraw");
    80002c48:	00006517          	auipc	a0,0x6
    80002c4c:	89850513          	addi	a0,a0,-1896 # 800084e0 <states.0+0x148>
    80002c50:	ffffe097          	auipc	ra,0xffffe
    80002c54:	8ee080e7          	jalr	-1810(ra) # 8000053e <panic>

0000000080002c58 <fetchaddr>:
{
    80002c58:	1101                	addi	sp,sp,-32
    80002c5a:	ec06                	sd	ra,24(sp)
    80002c5c:	e822                	sd	s0,16(sp)
    80002c5e:	e426                	sd	s1,8(sp)
    80002c60:	e04a                	sd	s2,0(sp)
    80002c62:	1000                	addi	s0,sp,32
    80002c64:	84aa                	mv	s1,a0
    80002c66:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	d7a080e7          	jalr	-646(ra) # 800019e2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c70:	653c                	ld	a5,72(a0)
    80002c72:	02f4f863          	bgeu	s1,a5,80002ca2 <fetchaddr+0x4a>
    80002c76:	00848713          	addi	a4,s1,8
    80002c7a:	02e7e663          	bltu	a5,a4,80002ca6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c7e:	46a1                	li	a3,8
    80002c80:	8626                	mv	a2,s1
    80002c82:	85ca                	mv	a1,s2
    80002c84:	6928                	ld	a0,80(a0)
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	aa4080e7          	jalr	-1372(ra) # 8000172a <copyin>
    80002c8e:	00a03533          	snez	a0,a0
    80002c92:	40a00533          	neg	a0,a0
}
    80002c96:	60e2                	ld	ra,24(sp)
    80002c98:	6442                	ld	s0,16(sp)
    80002c9a:	64a2                	ld	s1,8(sp)
    80002c9c:	6902                	ld	s2,0(sp)
    80002c9e:	6105                	addi	sp,sp,32
    80002ca0:	8082                	ret
    return -1;
    80002ca2:	557d                	li	a0,-1
    80002ca4:	bfcd                	j	80002c96 <fetchaddr+0x3e>
    80002ca6:	557d                	li	a0,-1
    80002ca8:	b7fd                	j	80002c96 <fetchaddr+0x3e>

0000000080002caa <fetchstr>:
{
    80002caa:	7179                	addi	sp,sp,-48
    80002cac:	f406                	sd	ra,40(sp)
    80002cae:	f022                	sd	s0,32(sp)
    80002cb0:	ec26                	sd	s1,24(sp)
    80002cb2:	e84a                	sd	s2,16(sp)
    80002cb4:	e44e                	sd	s3,8(sp)
    80002cb6:	1800                	addi	s0,sp,48
    80002cb8:	892a                	mv	s2,a0
    80002cba:	84ae                	mv	s1,a1
    80002cbc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	d24080e7          	jalr	-732(ra) # 800019e2 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002cc6:	86ce                	mv	a3,s3
    80002cc8:	864a                	mv	a2,s2
    80002cca:	85a6                	mv	a1,s1
    80002ccc:	6928                	ld	a0,80(a0)
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	aea080e7          	jalr	-1302(ra) # 800017b8 <copyinstr>
    80002cd6:	00054e63          	bltz	a0,80002cf2 <fetchstr+0x48>
  return strlen(buf);
    80002cda:	8526                	mv	a0,s1
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	172080e7          	jalr	370(ra) # 80000e4e <strlen>
}
    80002ce4:	70a2                	ld	ra,40(sp)
    80002ce6:	7402                	ld	s0,32(sp)
    80002ce8:	64e2                	ld	s1,24(sp)
    80002cea:	6942                	ld	s2,16(sp)
    80002cec:	69a2                	ld	s3,8(sp)
    80002cee:	6145                	addi	sp,sp,48
    80002cf0:	8082                	ret
    return -1;
    80002cf2:	557d                	li	a0,-1
    80002cf4:	bfc5                	j	80002ce4 <fetchstr+0x3a>

0000000080002cf6 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	e426                	sd	s1,8(sp)
    80002cfe:	1000                	addi	s0,sp,32
    80002d00:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d02:	00000097          	auipc	ra,0x0
    80002d06:	eee080e7          	jalr	-274(ra) # 80002bf0 <argraw>
    80002d0a:	c088                	sw	a0,0(s1)
}
    80002d0c:	60e2                	ld	ra,24(sp)
    80002d0e:	6442                	ld	s0,16(sp)
    80002d10:	64a2                	ld	s1,8(sp)
    80002d12:	6105                	addi	sp,sp,32
    80002d14:	8082                	ret

0000000080002d16 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002d16:	1101                	addi	sp,sp,-32
    80002d18:	ec06                	sd	ra,24(sp)
    80002d1a:	e822                	sd	s0,16(sp)
    80002d1c:	e426                	sd	s1,8(sp)
    80002d1e:	1000                	addi	s0,sp,32
    80002d20:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d22:	00000097          	auipc	ra,0x0
    80002d26:	ece080e7          	jalr	-306(ra) # 80002bf0 <argraw>
    80002d2a:	e088                	sd	a0,0(s1)
}
    80002d2c:	60e2                	ld	ra,24(sp)
    80002d2e:	6442                	ld	s0,16(sp)
    80002d30:	64a2                	ld	s1,8(sp)
    80002d32:	6105                	addi	sp,sp,32
    80002d34:	8082                	ret

0000000080002d36 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d36:	7179                	addi	sp,sp,-48
    80002d38:	f406                	sd	ra,40(sp)
    80002d3a:	f022                	sd	s0,32(sp)
    80002d3c:	ec26                	sd	s1,24(sp)
    80002d3e:	e84a                	sd	s2,16(sp)
    80002d40:	1800                	addi	s0,sp,48
    80002d42:	84ae                	mv	s1,a1
    80002d44:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d46:	fd840593          	addi	a1,s0,-40
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	fcc080e7          	jalr	-52(ra) # 80002d16 <argaddr>
  return fetchstr(addr, buf, max);
    80002d52:	864a                	mv	a2,s2
    80002d54:	85a6                	mv	a1,s1
    80002d56:	fd843503          	ld	a0,-40(s0)
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	f50080e7          	jalr	-176(ra) # 80002caa <fetchstr>
}
    80002d62:	70a2                	ld	ra,40(sp)
    80002d64:	7402                	ld	s0,32(sp)
    80002d66:	64e2                	ld	s1,24(sp)
    80002d68:	6942                	ld	s2,16(sp)
    80002d6a:	6145                	addi	sp,sp,48
    80002d6c:	8082                	ret

0000000080002d6e <syscall>:
[SYS_map_display]    sys_map_display,
};

void
syscall(void)
{
    80002d6e:	1101                	addi	sp,sp,-32
    80002d70:	ec06                	sd	ra,24(sp)
    80002d72:	e822                	sd	s0,16(sp)
    80002d74:	e426                	sd	s1,8(sp)
    80002d76:	e04a                	sd	s2,0(sp)
    80002d78:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	c68080e7          	jalr	-920(ra) # 800019e2 <myproc>
    80002d82:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d84:	05853903          	ld	s2,88(a0)
    80002d88:	0a893783          	ld	a5,168(s2)
    80002d8c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d90:	37fd                	addiw	a5,a5,-1
    80002d92:	4759                	li	a4,22
    80002d94:	00f76f63          	bltu	a4,a5,80002db2 <syscall+0x44>
    80002d98:	00369713          	slli	a4,a3,0x3
    80002d9c:	00005797          	auipc	a5,0x5
    80002da0:	78478793          	addi	a5,a5,1924 # 80008520 <syscalls>
    80002da4:	97ba                	add	a5,a5,a4
    80002da6:	639c                	ld	a5,0(a5)
    80002da8:	c789                	beqz	a5,80002db2 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002daa:	9782                	jalr	a5
    80002dac:	06a93823          	sd	a0,112(s2)
    80002db0:	a839                	j	80002dce <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002db2:	15848613          	addi	a2,s1,344
    80002db6:	588c                	lw	a1,48(s1)
    80002db8:	00005517          	auipc	a0,0x5
    80002dbc:	73050513          	addi	a0,a0,1840 # 800084e8 <states.0+0x150>
    80002dc0:	ffffd097          	auipc	ra,0xffffd
    80002dc4:	7c8080e7          	jalr	1992(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dc8:	6cbc                	ld	a5,88(s1)
    80002dca:	577d                	li	a4,-1
    80002dcc:	fbb8                	sd	a4,112(a5)
  }
}
    80002dce:	60e2                	ld	ra,24(sp)
    80002dd0:	6442                	ld	s0,16(sp)
    80002dd2:	64a2                	ld	s1,8(sp)
    80002dd4:	6902                	ld	s2,0(sp)
    80002dd6:	6105                	addi	sp,sp,32
    80002dd8:	8082                	ret

0000000080002dda <sys_exit>:
#include "proc.h"


uint64
sys_exit(void)
{
    80002dda:	1101                	addi	sp,sp,-32
    80002ddc:	ec06                	sd	ra,24(sp)
    80002dde:	e822                	sd	s0,16(sp)
    80002de0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002de2:	fec40593          	addi	a1,s0,-20
    80002de6:	4501                	li	a0,0
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	f0e080e7          	jalr	-242(ra) # 80002cf6 <argint>
  exit(n);
    80002df0:	fec42503          	lw	a0,-20(s0)
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	462080e7          	jalr	1122(ra) # 80002256 <exit>
  return 0;  // not reached
}
    80002dfc:	4501                	li	a0,0
    80002dfe:	60e2                	ld	ra,24(sp)
    80002e00:	6442                	ld	s0,16(sp)
    80002e02:	6105                	addi	sp,sp,32
    80002e04:	8082                	ret

0000000080002e06 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e06:	1141                	addi	sp,sp,-16
    80002e08:	e406                	sd	ra,8(sp)
    80002e0a:	e022                	sd	s0,0(sp)
    80002e0c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e0e:	fffff097          	auipc	ra,0xfffff
    80002e12:	bd4080e7          	jalr	-1068(ra) # 800019e2 <myproc>
}
    80002e16:	5908                	lw	a0,48(a0)
    80002e18:	60a2                	ld	ra,8(sp)
    80002e1a:	6402                	ld	s0,0(sp)
    80002e1c:	0141                	addi	sp,sp,16
    80002e1e:	8082                	ret

0000000080002e20 <sys_fork>:

uint64
sys_fork(void)
{
    80002e20:	1141                	addi	sp,sp,-16
    80002e22:	e406                	sd	ra,8(sp)
    80002e24:	e022                	sd	s0,0(sp)
    80002e26:	0800                	addi	s0,sp,16
  return fork();
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	008080e7          	jalr	8(ra) # 80001e30 <fork>
}
    80002e30:	60a2                	ld	ra,8(sp)
    80002e32:	6402                	ld	s0,0(sp)
    80002e34:	0141                	addi	sp,sp,16
    80002e36:	8082                	ret

0000000080002e38 <sys_wait>:

uint64
sys_wait(void)
{
    80002e38:	1101                	addi	sp,sp,-32
    80002e3a:	ec06                	sd	ra,24(sp)
    80002e3c:	e822                	sd	s0,16(sp)
    80002e3e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e40:	fe840593          	addi	a1,s0,-24
    80002e44:	4501                	li	a0,0
    80002e46:	00000097          	auipc	ra,0x0
    80002e4a:	ed0080e7          	jalr	-304(ra) # 80002d16 <argaddr>
  return wait(p);
    80002e4e:	fe843503          	ld	a0,-24(s0)
    80002e52:	fffff097          	auipc	ra,0xfffff
    80002e56:	5aa080e7          	jalr	1450(ra) # 800023fc <wait>
}
    80002e5a:	60e2                	ld	ra,24(sp)
    80002e5c:	6442                	ld	s0,16(sp)
    80002e5e:	6105                	addi	sp,sp,32
    80002e60:	8082                	ret

0000000080002e62 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e62:	7179                	addi	sp,sp,-48
    80002e64:	f406                	sd	ra,40(sp)
    80002e66:	f022                	sd	s0,32(sp)
    80002e68:	ec26                	sd	s1,24(sp)
    80002e6a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e6c:	fdc40593          	addi	a1,s0,-36
    80002e70:	4501                	li	a0,0
    80002e72:	00000097          	auipc	ra,0x0
    80002e76:	e84080e7          	jalr	-380(ra) # 80002cf6 <argint>
  addr = myproc()->sz;
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	b68080e7          	jalr	-1176(ra) # 800019e2 <myproc>
    80002e82:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e84:	fdc42503          	lw	a0,-36(s0)
    80002e88:	fffff097          	auipc	ra,0xfffff
    80002e8c:	f4c080e7          	jalr	-180(ra) # 80001dd4 <growproc>
    80002e90:	00054863          	bltz	a0,80002ea0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e94:	8526                	mv	a0,s1
    80002e96:	70a2                	ld	ra,40(sp)
    80002e98:	7402                	ld	s0,32(sp)
    80002e9a:	64e2                	ld	s1,24(sp)
    80002e9c:	6145                	addi	sp,sp,48
    80002e9e:	8082                	ret
    return -1;
    80002ea0:	54fd                	li	s1,-1
    80002ea2:	bfcd                	j	80002e94 <sys_sbrk+0x32>

0000000080002ea4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ea4:	7139                	addi	sp,sp,-64
    80002ea6:	fc06                	sd	ra,56(sp)
    80002ea8:	f822                	sd	s0,48(sp)
    80002eaa:	f426                	sd	s1,40(sp)
    80002eac:	f04a                	sd	s2,32(sp)
    80002eae:	ec4e                	sd	s3,24(sp)
    80002eb0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002eb2:	fcc40593          	addi	a1,s0,-52
    80002eb6:	4501                	li	a0,0
    80002eb8:	00000097          	auipc	ra,0x0
    80002ebc:	e3e080e7          	jalr	-450(ra) # 80002cf6 <argint>
  acquire(&tickslock);
    80002ec0:	00014517          	auipc	a0,0x14
    80002ec4:	72050513          	addi	a0,a0,1824 # 800175e0 <tickslock>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	d0e080e7          	jalr	-754(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002ed0:	00006917          	auipc	s2,0x6
    80002ed4:	47092903          	lw	s2,1136(s2) # 80009340 <ticks>
  while(ticks - ticks0 < n){
    80002ed8:	fcc42783          	lw	a5,-52(s0)
    80002edc:	cf9d                	beqz	a5,80002f1a <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ede:	00014997          	auipc	s3,0x14
    80002ee2:	70298993          	addi	s3,s3,1794 # 800175e0 <tickslock>
    80002ee6:	00006497          	auipc	s1,0x6
    80002eea:	45a48493          	addi	s1,s1,1114 # 80009340 <ticks>
    if(killed(myproc())){
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	af4080e7          	jalr	-1292(ra) # 800019e2 <myproc>
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	4d4080e7          	jalr	1236(ra) # 800023ca <killed>
    80002efe:	ed15                	bnez	a0,80002f3a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f00:	85ce                	mv	a1,s3
    80002f02:	8526                	mv	a0,s1
    80002f04:	fffff097          	auipc	ra,0xfffff
    80002f08:	21e080e7          	jalr	542(ra) # 80002122 <sleep>
  while(ticks - ticks0 < n){
    80002f0c:	409c                	lw	a5,0(s1)
    80002f0e:	412787bb          	subw	a5,a5,s2
    80002f12:	fcc42703          	lw	a4,-52(s0)
    80002f16:	fce7ece3          	bltu	a5,a4,80002eee <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f1a:	00014517          	auipc	a0,0x14
    80002f1e:	6c650513          	addi	a0,a0,1734 # 800175e0 <tickslock>
    80002f22:	ffffe097          	auipc	ra,0xffffe
    80002f26:	d68080e7          	jalr	-664(ra) # 80000c8a <release>
  return 0;
    80002f2a:	4501                	li	a0,0
}
    80002f2c:	70e2                	ld	ra,56(sp)
    80002f2e:	7442                	ld	s0,48(sp)
    80002f30:	74a2                	ld	s1,40(sp)
    80002f32:	7902                	ld	s2,32(sp)
    80002f34:	69e2                	ld	s3,24(sp)
    80002f36:	6121                	addi	sp,sp,64
    80002f38:	8082                	ret
      release(&tickslock);
    80002f3a:	00014517          	auipc	a0,0x14
    80002f3e:	6a650513          	addi	a0,a0,1702 # 800175e0 <tickslock>
    80002f42:	ffffe097          	auipc	ra,0xffffe
    80002f46:	d48080e7          	jalr	-696(ra) # 80000c8a <release>
      return -1;
    80002f4a:	557d                	li	a0,-1
    80002f4c:	b7c5                	j	80002f2c <sys_sleep+0x88>

0000000080002f4e <sys_kill>:

uint64
sys_kill(void)
{
    80002f4e:	1101                	addi	sp,sp,-32
    80002f50:	ec06                	sd	ra,24(sp)
    80002f52:	e822                	sd	s0,16(sp)
    80002f54:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f56:	fec40593          	addi	a1,s0,-20
    80002f5a:	4501                	li	a0,0
    80002f5c:	00000097          	auipc	ra,0x0
    80002f60:	d9a080e7          	jalr	-614(ra) # 80002cf6 <argint>
  return kill(pid);
    80002f64:	fec42503          	lw	a0,-20(s0)
    80002f68:	fffff097          	auipc	ra,0xfffff
    80002f6c:	3c4080e7          	jalr	964(ra) # 8000232c <kill>
}
    80002f70:	60e2                	ld	ra,24(sp)
    80002f72:	6442                	ld	s0,16(sp)
    80002f74:	6105                	addi	sp,sp,32
    80002f76:	8082                	ret

0000000080002f78 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f78:	1101                	addi	sp,sp,-32
    80002f7a:	ec06                	sd	ra,24(sp)
    80002f7c:	e822                	sd	s0,16(sp)
    80002f7e:	e426                	sd	s1,8(sp)
    80002f80:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f82:	00014517          	auipc	a0,0x14
    80002f86:	65e50513          	addi	a0,a0,1630 # 800175e0 <tickslock>
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	c4c080e7          	jalr	-948(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002f92:	00006497          	auipc	s1,0x6
    80002f96:	3ae4a483          	lw	s1,942(s1) # 80009340 <ticks>
  release(&tickslock);
    80002f9a:	00014517          	auipc	a0,0x14
    80002f9e:	64650513          	addi	a0,a0,1606 # 800175e0 <tickslock>
    80002fa2:	ffffe097          	auipc	ra,0xffffe
    80002fa6:	ce8080e7          	jalr	-792(ra) # 80000c8a <release>
  return xticks;
}
    80002faa:	02049513          	slli	a0,s1,0x20
    80002fae:	9101                	srli	a0,a0,0x20
    80002fb0:	60e2                	ld	ra,24(sp)
    80002fb2:	6442                	ld	s0,16(sp)
    80002fb4:	64a2                	ld	s1,8(sp)
    80002fb6:	6105                	addi	sp,sp,32
    80002fb8:	8082                	ret

0000000080002fba <sys_flip_display>:
// calling process's address space.
//
// TODO: Students implement this syscall.
uint64
sys_flip_display(void)
{
    80002fba:	1141                	addi	sp,sp,-16
    80002fbc:	e422                	sd	s0,8(sp)
    80002fbe:	0800                	addi	s0,sp,16
  return -1;
}
    80002fc0:	557d                	li	a0,-1
    80002fc2:	6422                	ld	s0,8(sp)
    80002fc4:	0141                	addi	sp,sp,16
    80002fc6:	8082                	ret

0000000080002fc8 <sys_map_display>:
// Returns the mapped virtual address on success, (uint64)-1 on failure.
//
// TODO: Students implement this syscall.
uint64
sys_map_display(void)
{
    80002fc8:	7179                	addi	sp,sp,-48
    80002fca:	f406                	sd	ra,40(sp)
    80002fcc:	f022                	sd	s0,32(sp)
    80002fce:	ec26                	sd	s1,24(sp)
    80002fd0:	1800                	addi	s0,sp,48
  uint64 addr;
  argaddr(0, &addr);
    80002fd2:	fd840593          	addi	a1,s0,-40
    80002fd6:	4501                	li	a0,0
    80002fd8:	00000097          	auipc	ra,0x0
    80002fdc:	d3e080e7          	jalr	-706(ra) # 80002d16 <argaddr>
  uint64 answer = (uint64)map_display((void*)addr);
    80002fe0:	fd843503          	ld	a0,-40(s0)
    80002fe4:	fffff097          	auipc	ra,0xfffff
    80002fe8:	6a0080e7          	jalr	1696(ra) # 80002684 <map_display>
    80002fec:	84aa                	mv	s1,a0
  printf("sys_map_display: addr=0x%p, answer=0x%p\n", addr, answer);
    80002fee:	862a                	mv	a2,a0
    80002ff0:	fd843583          	ld	a1,-40(s0)
    80002ff4:	00005517          	auipc	a0,0x5
    80002ff8:	5ec50513          	addi	a0,a0,1516 # 800085e0 <syscalls+0xc0>
    80002ffc:	ffffd097          	auipc	ra,0xffffd
    80003000:	58c080e7          	jalr	1420(ra) # 80000588 <printf>
  return answer;
  
}
    80003004:	8526                	mv	a0,s1
    80003006:	70a2                	ld	ra,40(sp)
    80003008:	7402                	ld	s0,32(sp)
    8000300a:	64e2                	ld	s1,24(sp)
    8000300c:	6145                	addi	sp,sp,48
    8000300e:	8082                	ret

0000000080003010 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003010:	7179                	addi	sp,sp,-48
    80003012:	f406                	sd	ra,40(sp)
    80003014:	f022                	sd	s0,32(sp)
    80003016:	ec26                	sd	s1,24(sp)
    80003018:	e84a                	sd	s2,16(sp)
    8000301a:	e44e                	sd	s3,8(sp)
    8000301c:	e052                	sd	s4,0(sp)
    8000301e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003020:	00005597          	auipc	a1,0x5
    80003024:	5f058593          	addi	a1,a1,1520 # 80008610 <syscalls+0xf0>
    80003028:	00014517          	auipc	a0,0x14
    8000302c:	5d050513          	addi	a0,a0,1488 # 800175f8 <bcache>
    80003030:	ffffe097          	auipc	ra,0xffffe
    80003034:	b16080e7          	jalr	-1258(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003038:	0001c797          	auipc	a5,0x1c
    8000303c:	5c078793          	addi	a5,a5,1472 # 8001f5f8 <bcache+0x8000>
    80003040:	0001d717          	auipc	a4,0x1d
    80003044:	82070713          	addi	a4,a4,-2016 # 8001f860 <bcache+0x8268>
    80003048:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000304c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003050:	00014497          	auipc	s1,0x14
    80003054:	5c048493          	addi	s1,s1,1472 # 80017610 <bcache+0x18>
    b->next = bcache.head.next;
    80003058:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000305a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000305c:	00005a17          	auipc	s4,0x5
    80003060:	5bca0a13          	addi	s4,s4,1468 # 80008618 <syscalls+0xf8>
    b->next = bcache.head.next;
    80003064:	2b893783          	ld	a5,696(s2)
    80003068:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000306a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000306e:	85d2                	mv	a1,s4
    80003070:	01048513          	addi	a0,s1,16
    80003074:	00001097          	auipc	ra,0x1
    80003078:	4c4080e7          	jalr	1220(ra) # 80004538 <initsleeplock>
    bcache.head.next->prev = b;
    8000307c:	2b893783          	ld	a5,696(s2)
    80003080:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003082:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003086:	45848493          	addi	s1,s1,1112
    8000308a:	fd349de3          	bne	s1,s3,80003064 <binit+0x54>
  }
}
    8000308e:	70a2                	ld	ra,40(sp)
    80003090:	7402                	ld	s0,32(sp)
    80003092:	64e2                	ld	s1,24(sp)
    80003094:	6942                	ld	s2,16(sp)
    80003096:	69a2                	ld	s3,8(sp)
    80003098:	6a02                	ld	s4,0(sp)
    8000309a:	6145                	addi	sp,sp,48
    8000309c:	8082                	ret

000000008000309e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000309e:	7179                	addi	sp,sp,-48
    800030a0:	f406                	sd	ra,40(sp)
    800030a2:	f022                	sd	s0,32(sp)
    800030a4:	ec26                	sd	s1,24(sp)
    800030a6:	e84a                	sd	s2,16(sp)
    800030a8:	e44e                	sd	s3,8(sp)
    800030aa:	1800                	addi	s0,sp,48
    800030ac:	892a                	mv	s2,a0
    800030ae:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030b0:	00014517          	auipc	a0,0x14
    800030b4:	54850513          	addi	a0,a0,1352 # 800175f8 <bcache>
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	b1e080e7          	jalr	-1250(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030c0:	0001c497          	auipc	s1,0x1c
    800030c4:	7f04b483          	ld	s1,2032(s1) # 8001f8b0 <bcache+0x82b8>
    800030c8:	0001c797          	auipc	a5,0x1c
    800030cc:	79878793          	addi	a5,a5,1944 # 8001f860 <bcache+0x8268>
    800030d0:	02f48f63          	beq	s1,a5,8000310e <bread+0x70>
    800030d4:	873e                	mv	a4,a5
    800030d6:	a021                	j	800030de <bread+0x40>
    800030d8:	68a4                	ld	s1,80(s1)
    800030da:	02e48a63          	beq	s1,a4,8000310e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030de:	449c                	lw	a5,8(s1)
    800030e0:	ff279ce3          	bne	a5,s2,800030d8 <bread+0x3a>
    800030e4:	44dc                	lw	a5,12(s1)
    800030e6:	ff3799e3          	bne	a5,s3,800030d8 <bread+0x3a>
      b->refcnt++;
    800030ea:	40bc                	lw	a5,64(s1)
    800030ec:	2785                	addiw	a5,a5,1
    800030ee:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030f0:	00014517          	auipc	a0,0x14
    800030f4:	50850513          	addi	a0,a0,1288 # 800175f8 <bcache>
    800030f8:	ffffe097          	auipc	ra,0xffffe
    800030fc:	b92080e7          	jalr	-1134(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003100:	01048513          	addi	a0,s1,16
    80003104:	00001097          	auipc	ra,0x1
    80003108:	46e080e7          	jalr	1134(ra) # 80004572 <acquiresleep>
      return b;
    8000310c:	a8b9                	j	8000316a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000310e:	0001c497          	auipc	s1,0x1c
    80003112:	79a4b483          	ld	s1,1946(s1) # 8001f8a8 <bcache+0x82b0>
    80003116:	0001c797          	auipc	a5,0x1c
    8000311a:	74a78793          	addi	a5,a5,1866 # 8001f860 <bcache+0x8268>
    8000311e:	00f48863          	beq	s1,a5,8000312e <bread+0x90>
    80003122:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003124:	40bc                	lw	a5,64(s1)
    80003126:	cf81                	beqz	a5,8000313e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003128:	64a4                	ld	s1,72(s1)
    8000312a:	fee49de3          	bne	s1,a4,80003124 <bread+0x86>
  panic("bget: no buffers");
    8000312e:	00005517          	auipc	a0,0x5
    80003132:	4f250513          	addi	a0,a0,1266 # 80008620 <syscalls+0x100>
    80003136:	ffffd097          	auipc	ra,0xffffd
    8000313a:	408080e7          	jalr	1032(ra) # 8000053e <panic>
      b->dev = dev;
    8000313e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003142:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003146:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000314a:	4785                	li	a5,1
    8000314c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000314e:	00014517          	auipc	a0,0x14
    80003152:	4aa50513          	addi	a0,a0,1194 # 800175f8 <bcache>
    80003156:	ffffe097          	auipc	ra,0xffffe
    8000315a:	b34080e7          	jalr	-1228(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000315e:	01048513          	addi	a0,s1,16
    80003162:	00001097          	auipc	ra,0x1
    80003166:	410080e7          	jalr	1040(ra) # 80004572 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000316a:	409c                	lw	a5,0(s1)
    8000316c:	cb89                	beqz	a5,8000317e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000316e:	8526                	mv	a0,s1
    80003170:	70a2                	ld	ra,40(sp)
    80003172:	7402                	ld	s0,32(sp)
    80003174:	64e2                	ld	s1,24(sp)
    80003176:	6942                	ld	s2,16(sp)
    80003178:	69a2                	ld	s3,8(sp)
    8000317a:	6145                	addi	sp,sp,48
    8000317c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000317e:	4581                	li	a1,0
    80003180:	8526                	mv	a0,s1
    80003182:	00003097          	auipc	ra,0x3
    80003186:	fd2080e7          	jalr	-46(ra) # 80006154 <virtio_disk_rw>
    b->valid = 1;
    8000318a:	4785                	li	a5,1
    8000318c:	c09c                	sw	a5,0(s1)
  return b;
    8000318e:	b7c5                	j	8000316e <bread+0xd0>

0000000080003190 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003190:	1101                	addi	sp,sp,-32
    80003192:	ec06                	sd	ra,24(sp)
    80003194:	e822                	sd	s0,16(sp)
    80003196:	e426                	sd	s1,8(sp)
    80003198:	1000                	addi	s0,sp,32
    8000319a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000319c:	0541                	addi	a0,a0,16
    8000319e:	00001097          	auipc	ra,0x1
    800031a2:	46e080e7          	jalr	1134(ra) # 8000460c <holdingsleep>
    800031a6:	cd01                	beqz	a0,800031be <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031a8:	4585                	li	a1,1
    800031aa:	8526                	mv	a0,s1
    800031ac:	00003097          	auipc	ra,0x3
    800031b0:	fa8080e7          	jalr	-88(ra) # 80006154 <virtio_disk_rw>
}
    800031b4:	60e2                	ld	ra,24(sp)
    800031b6:	6442                	ld	s0,16(sp)
    800031b8:	64a2                	ld	s1,8(sp)
    800031ba:	6105                	addi	sp,sp,32
    800031bc:	8082                	ret
    panic("bwrite");
    800031be:	00005517          	auipc	a0,0x5
    800031c2:	47a50513          	addi	a0,a0,1146 # 80008638 <syscalls+0x118>
    800031c6:	ffffd097          	auipc	ra,0xffffd
    800031ca:	378080e7          	jalr	888(ra) # 8000053e <panic>

00000000800031ce <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031ce:	1101                	addi	sp,sp,-32
    800031d0:	ec06                	sd	ra,24(sp)
    800031d2:	e822                	sd	s0,16(sp)
    800031d4:	e426                	sd	s1,8(sp)
    800031d6:	e04a                	sd	s2,0(sp)
    800031d8:	1000                	addi	s0,sp,32
    800031da:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031dc:	01050913          	addi	s2,a0,16
    800031e0:	854a                	mv	a0,s2
    800031e2:	00001097          	auipc	ra,0x1
    800031e6:	42a080e7          	jalr	1066(ra) # 8000460c <holdingsleep>
    800031ea:	c92d                	beqz	a0,8000325c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031ec:	854a                	mv	a0,s2
    800031ee:	00001097          	auipc	ra,0x1
    800031f2:	3da080e7          	jalr	986(ra) # 800045c8 <releasesleep>

  acquire(&bcache.lock);
    800031f6:	00014517          	auipc	a0,0x14
    800031fa:	40250513          	addi	a0,a0,1026 # 800175f8 <bcache>
    800031fe:	ffffe097          	auipc	ra,0xffffe
    80003202:	9d8080e7          	jalr	-1576(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003206:	40bc                	lw	a5,64(s1)
    80003208:	37fd                	addiw	a5,a5,-1
    8000320a:	0007871b          	sext.w	a4,a5
    8000320e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003210:	eb05                	bnez	a4,80003240 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003212:	68bc                	ld	a5,80(s1)
    80003214:	64b8                	ld	a4,72(s1)
    80003216:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003218:	64bc                	ld	a5,72(s1)
    8000321a:	68b8                	ld	a4,80(s1)
    8000321c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000321e:	0001c797          	auipc	a5,0x1c
    80003222:	3da78793          	addi	a5,a5,986 # 8001f5f8 <bcache+0x8000>
    80003226:	2b87b703          	ld	a4,696(a5)
    8000322a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000322c:	0001c717          	auipc	a4,0x1c
    80003230:	63470713          	addi	a4,a4,1588 # 8001f860 <bcache+0x8268>
    80003234:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003236:	2b87b703          	ld	a4,696(a5)
    8000323a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000323c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003240:	00014517          	auipc	a0,0x14
    80003244:	3b850513          	addi	a0,a0,952 # 800175f8 <bcache>
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	a42080e7          	jalr	-1470(ra) # 80000c8a <release>
}
    80003250:	60e2                	ld	ra,24(sp)
    80003252:	6442                	ld	s0,16(sp)
    80003254:	64a2                	ld	s1,8(sp)
    80003256:	6902                	ld	s2,0(sp)
    80003258:	6105                	addi	sp,sp,32
    8000325a:	8082                	ret
    panic("brelse");
    8000325c:	00005517          	auipc	a0,0x5
    80003260:	3e450513          	addi	a0,a0,996 # 80008640 <syscalls+0x120>
    80003264:	ffffd097          	auipc	ra,0xffffd
    80003268:	2da080e7          	jalr	730(ra) # 8000053e <panic>

000000008000326c <bpin>:

void
bpin(struct buf *b) {
    8000326c:	1101                	addi	sp,sp,-32
    8000326e:	ec06                	sd	ra,24(sp)
    80003270:	e822                	sd	s0,16(sp)
    80003272:	e426                	sd	s1,8(sp)
    80003274:	1000                	addi	s0,sp,32
    80003276:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003278:	00014517          	auipc	a0,0x14
    8000327c:	38050513          	addi	a0,a0,896 # 800175f8 <bcache>
    80003280:	ffffe097          	auipc	ra,0xffffe
    80003284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003288:	40bc                	lw	a5,64(s1)
    8000328a:	2785                	addiw	a5,a5,1
    8000328c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000328e:	00014517          	auipc	a0,0x14
    80003292:	36a50513          	addi	a0,a0,874 # 800175f8 <bcache>
    80003296:	ffffe097          	auipc	ra,0xffffe
    8000329a:	9f4080e7          	jalr	-1548(ra) # 80000c8a <release>
}
    8000329e:	60e2                	ld	ra,24(sp)
    800032a0:	6442                	ld	s0,16(sp)
    800032a2:	64a2                	ld	s1,8(sp)
    800032a4:	6105                	addi	sp,sp,32
    800032a6:	8082                	ret

00000000800032a8 <bunpin>:

void
bunpin(struct buf *b) {
    800032a8:	1101                	addi	sp,sp,-32
    800032aa:	ec06                	sd	ra,24(sp)
    800032ac:	e822                	sd	s0,16(sp)
    800032ae:	e426                	sd	s1,8(sp)
    800032b0:	1000                	addi	s0,sp,32
    800032b2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032b4:	00014517          	auipc	a0,0x14
    800032b8:	34450513          	addi	a0,a0,836 # 800175f8 <bcache>
    800032bc:	ffffe097          	auipc	ra,0xffffe
    800032c0:	91a080e7          	jalr	-1766(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800032c4:	40bc                	lw	a5,64(s1)
    800032c6:	37fd                	addiw	a5,a5,-1
    800032c8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032ca:	00014517          	auipc	a0,0x14
    800032ce:	32e50513          	addi	a0,a0,814 # 800175f8 <bcache>
    800032d2:	ffffe097          	auipc	ra,0xffffe
    800032d6:	9b8080e7          	jalr	-1608(ra) # 80000c8a <release>
}
    800032da:	60e2                	ld	ra,24(sp)
    800032dc:	6442                	ld	s0,16(sp)
    800032de:	64a2                	ld	s1,8(sp)
    800032e0:	6105                	addi	sp,sp,32
    800032e2:	8082                	ret

00000000800032e4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032e4:	1101                	addi	sp,sp,-32
    800032e6:	ec06                	sd	ra,24(sp)
    800032e8:	e822                	sd	s0,16(sp)
    800032ea:	e426                	sd	s1,8(sp)
    800032ec:	e04a                	sd	s2,0(sp)
    800032ee:	1000                	addi	s0,sp,32
    800032f0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032f2:	00d5d59b          	srliw	a1,a1,0xd
    800032f6:	0001d797          	auipc	a5,0x1d
    800032fa:	9de7a783          	lw	a5,-1570(a5) # 8001fcd4 <sb+0x1c>
    800032fe:	9dbd                	addw	a1,a1,a5
    80003300:	00000097          	auipc	ra,0x0
    80003304:	d9e080e7          	jalr	-610(ra) # 8000309e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003308:	0074f713          	andi	a4,s1,7
    8000330c:	4785                	li	a5,1
    8000330e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003312:	14ce                	slli	s1,s1,0x33
    80003314:	90d9                	srli	s1,s1,0x36
    80003316:	00950733          	add	a4,a0,s1
    8000331a:	05874703          	lbu	a4,88(a4)
    8000331e:	00e7f6b3          	and	a3,a5,a4
    80003322:	c69d                	beqz	a3,80003350 <bfree+0x6c>
    80003324:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003326:	94aa                	add	s1,s1,a0
    80003328:	fff7c793          	not	a5,a5
    8000332c:	8ff9                	and	a5,a5,a4
    8000332e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003332:	00001097          	auipc	ra,0x1
    80003336:	120080e7          	jalr	288(ra) # 80004452 <log_write>
  brelse(bp);
    8000333a:	854a                	mv	a0,s2
    8000333c:	00000097          	auipc	ra,0x0
    80003340:	e92080e7          	jalr	-366(ra) # 800031ce <brelse>
}
    80003344:	60e2                	ld	ra,24(sp)
    80003346:	6442                	ld	s0,16(sp)
    80003348:	64a2                	ld	s1,8(sp)
    8000334a:	6902                	ld	s2,0(sp)
    8000334c:	6105                	addi	sp,sp,32
    8000334e:	8082                	ret
    panic("freeing free block");
    80003350:	00005517          	auipc	a0,0x5
    80003354:	2f850513          	addi	a0,a0,760 # 80008648 <syscalls+0x128>
    80003358:	ffffd097          	auipc	ra,0xffffd
    8000335c:	1e6080e7          	jalr	486(ra) # 8000053e <panic>

0000000080003360 <balloc>:
{
    80003360:	711d                	addi	sp,sp,-96
    80003362:	ec86                	sd	ra,88(sp)
    80003364:	e8a2                	sd	s0,80(sp)
    80003366:	e4a6                	sd	s1,72(sp)
    80003368:	e0ca                	sd	s2,64(sp)
    8000336a:	fc4e                	sd	s3,56(sp)
    8000336c:	f852                	sd	s4,48(sp)
    8000336e:	f456                	sd	s5,40(sp)
    80003370:	f05a                	sd	s6,32(sp)
    80003372:	ec5e                	sd	s7,24(sp)
    80003374:	e862                	sd	s8,16(sp)
    80003376:	e466                	sd	s9,8(sp)
    80003378:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000337a:	0001d797          	auipc	a5,0x1d
    8000337e:	9427a783          	lw	a5,-1726(a5) # 8001fcbc <sb+0x4>
    80003382:	10078163          	beqz	a5,80003484 <balloc+0x124>
    80003386:	8baa                	mv	s7,a0
    80003388:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000338a:	0001db17          	auipc	s6,0x1d
    8000338e:	92eb0b13          	addi	s6,s6,-1746 # 8001fcb8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003392:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003394:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003396:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003398:	6c89                	lui	s9,0x2
    8000339a:	a061                	j	80003422 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000339c:	974a                	add	a4,a4,s2
    8000339e:	8fd5                	or	a5,a5,a3
    800033a0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033a4:	854a                	mv	a0,s2
    800033a6:	00001097          	auipc	ra,0x1
    800033aa:	0ac080e7          	jalr	172(ra) # 80004452 <log_write>
        brelse(bp);
    800033ae:	854a                	mv	a0,s2
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	e1e080e7          	jalr	-482(ra) # 800031ce <brelse>
  bp = bread(dev, bno);
    800033b8:	85a6                	mv	a1,s1
    800033ba:	855e                	mv	a0,s7
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	ce2080e7          	jalr	-798(ra) # 8000309e <bread>
    800033c4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033c6:	40000613          	li	a2,1024
    800033ca:	4581                	li	a1,0
    800033cc:	05850513          	addi	a0,a0,88
    800033d0:	ffffe097          	auipc	ra,0xffffe
    800033d4:	902080e7          	jalr	-1790(ra) # 80000cd2 <memset>
  log_write(bp);
    800033d8:	854a                	mv	a0,s2
    800033da:	00001097          	auipc	ra,0x1
    800033de:	078080e7          	jalr	120(ra) # 80004452 <log_write>
  brelse(bp);
    800033e2:	854a                	mv	a0,s2
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	dea080e7          	jalr	-534(ra) # 800031ce <brelse>
}
    800033ec:	8526                	mv	a0,s1
    800033ee:	60e6                	ld	ra,88(sp)
    800033f0:	6446                	ld	s0,80(sp)
    800033f2:	64a6                	ld	s1,72(sp)
    800033f4:	6906                	ld	s2,64(sp)
    800033f6:	79e2                	ld	s3,56(sp)
    800033f8:	7a42                	ld	s4,48(sp)
    800033fa:	7aa2                	ld	s5,40(sp)
    800033fc:	7b02                	ld	s6,32(sp)
    800033fe:	6be2                	ld	s7,24(sp)
    80003400:	6c42                	ld	s8,16(sp)
    80003402:	6ca2                	ld	s9,8(sp)
    80003404:	6125                	addi	sp,sp,96
    80003406:	8082                	ret
    brelse(bp);
    80003408:	854a                	mv	a0,s2
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	dc4080e7          	jalr	-572(ra) # 800031ce <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003412:	015c87bb          	addw	a5,s9,s5
    80003416:	00078a9b          	sext.w	s5,a5
    8000341a:	004b2703          	lw	a4,4(s6)
    8000341e:	06eaf363          	bgeu	s5,a4,80003484 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003422:	41fad79b          	sraiw	a5,s5,0x1f
    80003426:	0137d79b          	srliw	a5,a5,0x13
    8000342a:	015787bb          	addw	a5,a5,s5
    8000342e:	40d7d79b          	sraiw	a5,a5,0xd
    80003432:	01cb2583          	lw	a1,28(s6)
    80003436:	9dbd                	addw	a1,a1,a5
    80003438:	855e                	mv	a0,s7
    8000343a:	00000097          	auipc	ra,0x0
    8000343e:	c64080e7          	jalr	-924(ra) # 8000309e <bread>
    80003442:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003444:	004b2503          	lw	a0,4(s6)
    80003448:	000a849b          	sext.w	s1,s5
    8000344c:	8662                	mv	a2,s8
    8000344e:	faa4fde3          	bgeu	s1,a0,80003408 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003452:	41f6579b          	sraiw	a5,a2,0x1f
    80003456:	01d7d69b          	srliw	a3,a5,0x1d
    8000345a:	00c6873b          	addw	a4,a3,a2
    8000345e:	00777793          	andi	a5,a4,7
    80003462:	9f95                	subw	a5,a5,a3
    80003464:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003468:	4037571b          	sraiw	a4,a4,0x3
    8000346c:	00e906b3          	add	a3,s2,a4
    80003470:	0586c683          	lbu	a3,88(a3)
    80003474:	00d7f5b3          	and	a1,a5,a3
    80003478:	d195                	beqz	a1,8000339c <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000347a:	2605                	addiw	a2,a2,1
    8000347c:	2485                	addiw	s1,s1,1
    8000347e:	fd4618e3          	bne	a2,s4,8000344e <balloc+0xee>
    80003482:	b759                	j	80003408 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003484:	00005517          	auipc	a0,0x5
    80003488:	1dc50513          	addi	a0,a0,476 # 80008660 <syscalls+0x140>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	0fc080e7          	jalr	252(ra) # 80000588 <printf>
  return 0;
    80003494:	4481                	li	s1,0
    80003496:	bf99                	j	800033ec <balloc+0x8c>

0000000080003498 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003498:	7179                	addi	sp,sp,-48
    8000349a:	f406                	sd	ra,40(sp)
    8000349c:	f022                	sd	s0,32(sp)
    8000349e:	ec26                	sd	s1,24(sp)
    800034a0:	e84a                	sd	s2,16(sp)
    800034a2:	e44e                	sd	s3,8(sp)
    800034a4:	e052                	sd	s4,0(sp)
    800034a6:	1800                	addi	s0,sp,48
    800034a8:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034aa:	47ad                	li	a5,11
    800034ac:	02b7e763          	bltu	a5,a1,800034da <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800034b0:	02059493          	slli	s1,a1,0x20
    800034b4:	9081                	srli	s1,s1,0x20
    800034b6:	048a                	slli	s1,s1,0x2
    800034b8:	94aa                	add	s1,s1,a0
    800034ba:	0504a903          	lw	s2,80(s1)
    800034be:	06091e63          	bnez	s2,8000353a <bmap+0xa2>
      addr = balloc(ip->dev);
    800034c2:	4108                	lw	a0,0(a0)
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	e9c080e7          	jalr	-356(ra) # 80003360 <balloc>
    800034cc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034d0:	06090563          	beqz	s2,8000353a <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800034d4:	0524a823          	sw	s2,80(s1)
    800034d8:	a08d                	j	8000353a <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800034da:	ff45849b          	addiw	s1,a1,-12
    800034de:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034e2:	0ff00793          	li	a5,255
    800034e6:	08e7e563          	bltu	a5,a4,80003570 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800034ea:	08052903          	lw	s2,128(a0)
    800034ee:	00091d63          	bnez	s2,80003508 <bmap+0x70>
      addr = balloc(ip->dev);
    800034f2:	4108                	lw	a0,0(a0)
    800034f4:	00000097          	auipc	ra,0x0
    800034f8:	e6c080e7          	jalr	-404(ra) # 80003360 <balloc>
    800034fc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003500:	02090d63          	beqz	s2,8000353a <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003504:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003508:	85ca                	mv	a1,s2
    8000350a:	0009a503          	lw	a0,0(s3)
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	b90080e7          	jalr	-1136(ra) # 8000309e <bread>
    80003516:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003518:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000351c:	02049593          	slli	a1,s1,0x20
    80003520:	9181                	srli	a1,a1,0x20
    80003522:	058a                	slli	a1,a1,0x2
    80003524:	00b784b3          	add	s1,a5,a1
    80003528:	0004a903          	lw	s2,0(s1)
    8000352c:	02090063          	beqz	s2,8000354c <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003530:	8552                	mv	a0,s4
    80003532:	00000097          	auipc	ra,0x0
    80003536:	c9c080e7          	jalr	-868(ra) # 800031ce <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000353a:	854a                	mv	a0,s2
    8000353c:	70a2                	ld	ra,40(sp)
    8000353e:	7402                	ld	s0,32(sp)
    80003540:	64e2                	ld	s1,24(sp)
    80003542:	6942                	ld	s2,16(sp)
    80003544:	69a2                	ld	s3,8(sp)
    80003546:	6a02                	ld	s4,0(sp)
    80003548:	6145                	addi	sp,sp,48
    8000354a:	8082                	ret
      addr = balloc(ip->dev);
    8000354c:	0009a503          	lw	a0,0(s3)
    80003550:	00000097          	auipc	ra,0x0
    80003554:	e10080e7          	jalr	-496(ra) # 80003360 <balloc>
    80003558:	0005091b          	sext.w	s2,a0
      if(addr){
    8000355c:	fc090ae3          	beqz	s2,80003530 <bmap+0x98>
        a[bn] = addr;
    80003560:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003564:	8552                	mv	a0,s4
    80003566:	00001097          	auipc	ra,0x1
    8000356a:	eec080e7          	jalr	-276(ra) # 80004452 <log_write>
    8000356e:	b7c9                	j	80003530 <bmap+0x98>
  panic("bmap: out of range");
    80003570:	00005517          	auipc	a0,0x5
    80003574:	10850513          	addi	a0,a0,264 # 80008678 <syscalls+0x158>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	fc6080e7          	jalr	-58(ra) # 8000053e <panic>

0000000080003580 <iget>:
{
    80003580:	7179                	addi	sp,sp,-48
    80003582:	f406                	sd	ra,40(sp)
    80003584:	f022                	sd	s0,32(sp)
    80003586:	ec26                	sd	s1,24(sp)
    80003588:	e84a                	sd	s2,16(sp)
    8000358a:	e44e                	sd	s3,8(sp)
    8000358c:	e052                	sd	s4,0(sp)
    8000358e:	1800                	addi	s0,sp,48
    80003590:	89aa                	mv	s3,a0
    80003592:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003594:	0001c517          	auipc	a0,0x1c
    80003598:	74450513          	addi	a0,a0,1860 # 8001fcd8 <itable>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	63a080e7          	jalr	1594(ra) # 80000bd6 <acquire>
  empty = 0;
    800035a4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035a6:	0001c497          	auipc	s1,0x1c
    800035aa:	74a48493          	addi	s1,s1,1866 # 8001fcf0 <itable+0x18>
    800035ae:	0001e697          	auipc	a3,0x1e
    800035b2:	1d268693          	addi	a3,a3,466 # 80021780 <log>
    800035b6:	a039                	j	800035c4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035b8:	02090b63          	beqz	s2,800035ee <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035bc:	08848493          	addi	s1,s1,136
    800035c0:	02d48a63          	beq	s1,a3,800035f4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035c4:	449c                	lw	a5,8(s1)
    800035c6:	fef059e3          	blez	a5,800035b8 <iget+0x38>
    800035ca:	4098                	lw	a4,0(s1)
    800035cc:	ff3716e3          	bne	a4,s3,800035b8 <iget+0x38>
    800035d0:	40d8                	lw	a4,4(s1)
    800035d2:	ff4713e3          	bne	a4,s4,800035b8 <iget+0x38>
      ip->ref++;
    800035d6:	2785                	addiw	a5,a5,1
    800035d8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035da:	0001c517          	auipc	a0,0x1c
    800035de:	6fe50513          	addi	a0,a0,1790 # 8001fcd8 <itable>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	6a8080e7          	jalr	1704(ra) # 80000c8a <release>
      return ip;
    800035ea:	8926                	mv	s2,s1
    800035ec:	a03d                	j	8000361a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035ee:	f7f9                	bnez	a5,800035bc <iget+0x3c>
    800035f0:	8926                	mv	s2,s1
    800035f2:	b7e9                	j	800035bc <iget+0x3c>
  if(empty == 0)
    800035f4:	02090c63          	beqz	s2,8000362c <iget+0xac>
  ip->dev = dev;
    800035f8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035fc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003600:	4785                	li	a5,1
    80003602:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003606:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000360a:	0001c517          	auipc	a0,0x1c
    8000360e:	6ce50513          	addi	a0,a0,1742 # 8001fcd8 <itable>
    80003612:	ffffd097          	auipc	ra,0xffffd
    80003616:	678080e7          	jalr	1656(ra) # 80000c8a <release>
}
    8000361a:	854a                	mv	a0,s2
    8000361c:	70a2                	ld	ra,40(sp)
    8000361e:	7402                	ld	s0,32(sp)
    80003620:	64e2                	ld	s1,24(sp)
    80003622:	6942                	ld	s2,16(sp)
    80003624:	69a2                	ld	s3,8(sp)
    80003626:	6a02                	ld	s4,0(sp)
    80003628:	6145                	addi	sp,sp,48
    8000362a:	8082                	ret
    panic("iget: no inodes");
    8000362c:	00005517          	auipc	a0,0x5
    80003630:	06450513          	addi	a0,a0,100 # 80008690 <syscalls+0x170>
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	f0a080e7          	jalr	-246(ra) # 8000053e <panic>

000000008000363c <fsinit>:
fsinit(int dev) {
    8000363c:	7179                	addi	sp,sp,-48
    8000363e:	f406                	sd	ra,40(sp)
    80003640:	f022                	sd	s0,32(sp)
    80003642:	ec26                	sd	s1,24(sp)
    80003644:	e84a                	sd	s2,16(sp)
    80003646:	e44e                	sd	s3,8(sp)
    80003648:	1800                	addi	s0,sp,48
    8000364a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000364c:	4585                	li	a1,1
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	a50080e7          	jalr	-1456(ra) # 8000309e <bread>
    80003656:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003658:	0001c997          	auipc	s3,0x1c
    8000365c:	66098993          	addi	s3,s3,1632 # 8001fcb8 <sb>
    80003660:	02000613          	li	a2,32
    80003664:	05850593          	addi	a1,a0,88
    80003668:	854e                	mv	a0,s3
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	6c4080e7          	jalr	1732(ra) # 80000d2e <memmove>
  brelse(bp);
    80003672:	8526                	mv	a0,s1
    80003674:	00000097          	auipc	ra,0x0
    80003678:	b5a080e7          	jalr	-1190(ra) # 800031ce <brelse>
  if(sb.magic != FSMAGIC)
    8000367c:	0009a703          	lw	a4,0(s3)
    80003680:	102037b7          	lui	a5,0x10203
    80003684:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003688:	02f71263          	bne	a4,a5,800036ac <fsinit+0x70>
  initlog(dev, &sb);
    8000368c:	0001c597          	auipc	a1,0x1c
    80003690:	62c58593          	addi	a1,a1,1580 # 8001fcb8 <sb>
    80003694:	854a                	mv	a0,s2
    80003696:	00001097          	auipc	ra,0x1
    8000369a:	b40080e7          	jalr	-1216(ra) # 800041d6 <initlog>
}
    8000369e:	70a2                	ld	ra,40(sp)
    800036a0:	7402                	ld	s0,32(sp)
    800036a2:	64e2                	ld	s1,24(sp)
    800036a4:	6942                	ld	s2,16(sp)
    800036a6:	69a2                	ld	s3,8(sp)
    800036a8:	6145                	addi	sp,sp,48
    800036aa:	8082                	ret
    panic("invalid file system");
    800036ac:	00005517          	auipc	a0,0x5
    800036b0:	ff450513          	addi	a0,a0,-12 # 800086a0 <syscalls+0x180>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	e8a080e7          	jalr	-374(ra) # 8000053e <panic>

00000000800036bc <iinit>:
{
    800036bc:	7179                	addi	sp,sp,-48
    800036be:	f406                	sd	ra,40(sp)
    800036c0:	f022                	sd	s0,32(sp)
    800036c2:	ec26                	sd	s1,24(sp)
    800036c4:	e84a                	sd	s2,16(sp)
    800036c6:	e44e                	sd	s3,8(sp)
    800036c8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036ca:	00005597          	auipc	a1,0x5
    800036ce:	fee58593          	addi	a1,a1,-18 # 800086b8 <syscalls+0x198>
    800036d2:	0001c517          	auipc	a0,0x1c
    800036d6:	60650513          	addi	a0,a0,1542 # 8001fcd8 <itable>
    800036da:	ffffd097          	auipc	ra,0xffffd
    800036de:	46c080e7          	jalr	1132(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036e2:	0001c497          	auipc	s1,0x1c
    800036e6:	61e48493          	addi	s1,s1,1566 # 8001fd00 <itable+0x28>
    800036ea:	0001e997          	auipc	s3,0x1e
    800036ee:	0a698993          	addi	s3,s3,166 # 80021790 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036f2:	00005917          	auipc	s2,0x5
    800036f6:	fce90913          	addi	s2,s2,-50 # 800086c0 <syscalls+0x1a0>
    800036fa:	85ca                	mv	a1,s2
    800036fc:	8526                	mv	a0,s1
    800036fe:	00001097          	auipc	ra,0x1
    80003702:	e3a080e7          	jalr	-454(ra) # 80004538 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003706:	08848493          	addi	s1,s1,136
    8000370a:	ff3498e3          	bne	s1,s3,800036fa <iinit+0x3e>
}
    8000370e:	70a2                	ld	ra,40(sp)
    80003710:	7402                	ld	s0,32(sp)
    80003712:	64e2                	ld	s1,24(sp)
    80003714:	6942                	ld	s2,16(sp)
    80003716:	69a2                	ld	s3,8(sp)
    80003718:	6145                	addi	sp,sp,48
    8000371a:	8082                	ret

000000008000371c <ialloc>:
{
    8000371c:	715d                	addi	sp,sp,-80
    8000371e:	e486                	sd	ra,72(sp)
    80003720:	e0a2                	sd	s0,64(sp)
    80003722:	fc26                	sd	s1,56(sp)
    80003724:	f84a                	sd	s2,48(sp)
    80003726:	f44e                	sd	s3,40(sp)
    80003728:	f052                	sd	s4,32(sp)
    8000372a:	ec56                	sd	s5,24(sp)
    8000372c:	e85a                	sd	s6,16(sp)
    8000372e:	e45e                	sd	s7,8(sp)
    80003730:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003732:	0001c717          	auipc	a4,0x1c
    80003736:	59272703          	lw	a4,1426(a4) # 8001fcc4 <sb+0xc>
    8000373a:	4785                	li	a5,1
    8000373c:	04e7fa63          	bgeu	a5,a4,80003790 <ialloc+0x74>
    80003740:	8aaa                	mv	s5,a0
    80003742:	8bae                	mv	s7,a1
    80003744:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003746:	0001ca17          	auipc	s4,0x1c
    8000374a:	572a0a13          	addi	s4,s4,1394 # 8001fcb8 <sb>
    8000374e:	00048b1b          	sext.w	s6,s1
    80003752:	0044d793          	srli	a5,s1,0x4
    80003756:	018a2583          	lw	a1,24(s4)
    8000375a:	9dbd                	addw	a1,a1,a5
    8000375c:	8556                	mv	a0,s5
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	940080e7          	jalr	-1728(ra) # 8000309e <bread>
    80003766:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003768:	05850993          	addi	s3,a0,88
    8000376c:	00f4f793          	andi	a5,s1,15
    80003770:	079a                	slli	a5,a5,0x6
    80003772:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003774:	00099783          	lh	a5,0(s3)
    80003778:	c3a1                	beqz	a5,800037b8 <ialloc+0x9c>
    brelse(bp);
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	a54080e7          	jalr	-1452(ra) # 800031ce <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003782:	0485                	addi	s1,s1,1
    80003784:	00ca2703          	lw	a4,12(s4)
    80003788:	0004879b          	sext.w	a5,s1
    8000378c:	fce7e1e3          	bltu	a5,a4,8000374e <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003790:	00005517          	auipc	a0,0x5
    80003794:	f3850513          	addi	a0,a0,-200 # 800086c8 <syscalls+0x1a8>
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	df0080e7          	jalr	-528(ra) # 80000588 <printf>
  return 0;
    800037a0:	4501                	li	a0,0
}
    800037a2:	60a6                	ld	ra,72(sp)
    800037a4:	6406                	ld	s0,64(sp)
    800037a6:	74e2                	ld	s1,56(sp)
    800037a8:	7942                	ld	s2,48(sp)
    800037aa:	79a2                	ld	s3,40(sp)
    800037ac:	7a02                	ld	s4,32(sp)
    800037ae:	6ae2                	ld	s5,24(sp)
    800037b0:	6b42                	ld	s6,16(sp)
    800037b2:	6ba2                	ld	s7,8(sp)
    800037b4:	6161                	addi	sp,sp,80
    800037b6:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800037b8:	04000613          	li	a2,64
    800037bc:	4581                	li	a1,0
    800037be:	854e                	mv	a0,s3
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	512080e7          	jalr	1298(ra) # 80000cd2 <memset>
      dip->type = type;
    800037c8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037cc:	854a                	mv	a0,s2
    800037ce:	00001097          	auipc	ra,0x1
    800037d2:	c84080e7          	jalr	-892(ra) # 80004452 <log_write>
      brelse(bp);
    800037d6:	854a                	mv	a0,s2
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	9f6080e7          	jalr	-1546(ra) # 800031ce <brelse>
      return iget(dev, inum);
    800037e0:	85da                	mv	a1,s6
    800037e2:	8556                	mv	a0,s5
    800037e4:	00000097          	auipc	ra,0x0
    800037e8:	d9c080e7          	jalr	-612(ra) # 80003580 <iget>
    800037ec:	bf5d                	j	800037a2 <ialloc+0x86>

00000000800037ee <iupdate>:
{
    800037ee:	1101                	addi	sp,sp,-32
    800037f0:	ec06                	sd	ra,24(sp)
    800037f2:	e822                	sd	s0,16(sp)
    800037f4:	e426                	sd	s1,8(sp)
    800037f6:	e04a                	sd	s2,0(sp)
    800037f8:	1000                	addi	s0,sp,32
    800037fa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037fc:	415c                	lw	a5,4(a0)
    800037fe:	0047d79b          	srliw	a5,a5,0x4
    80003802:	0001c597          	auipc	a1,0x1c
    80003806:	4ce5a583          	lw	a1,1230(a1) # 8001fcd0 <sb+0x18>
    8000380a:	9dbd                	addw	a1,a1,a5
    8000380c:	4108                	lw	a0,0(a0)
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	890080e7          	jalr	-1904(ra) # 8000309e <bread>
    80003816:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003818:	05850793          	addi	a5,a0,88
    8000381c:	40c8                	lw	a0,4(s1)
    8000381e:	893d                	andi	a0,a0,15
    80003820:	051a                	slli	a0,a0,0x6
    80003822:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003824:	04449703          	lh	a4,68(s1)
    80003828:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000382c:	04649703          	lh	a4,70(s1)
    80003830:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003834:	04849703          	lh	a4,72(s1)
    80003838:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000383c:	04a49703          	lh	a4,74(s1)
    80003840:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003844:	44f8                	lw	a4,76(s1)
    80003846:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003848:	03400613          	li	a2,52
    8000384c:	05048593          	addi	a1,s1,80
    80003850:	0531                	addi	a0,a0,12
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	4dc080e7          	jalr	1244(ra) # 80000d2e <memmove>
  log_write(bp);
    8000385a:	854a                	mv	a0,s2
    8000385c:	00001097          	auipc	ra,0x1
    80003860:	bf6080e7          	jalr	-1034(ra) # 80004452 <log_write>
  brelse(bp);
    80003864:	854a                	mv	a0,s2
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	968080e7          	jalr	-1688(ra) # 800031ce <brelse>
}
    8000386e:	60e2                	ld	ra,24(sp)
    80003870:	6442                	ld	s0,16(sp)
    80003872:	64a2                	ld	s1,8(sp)
    80003874:	6902                	ld	s2,0(sp)
    80003876:	6105                	addi	sp,sp,32
    80003878:	8082                	ret

000000008000387a <idup>:
{
    8000387a:	1101                	addi	sp,sp,-32
    8000387c:	ec06                	sd	ra,24(sp)
    8000387e:	e822                	sd	s0,16(sp)
    80003880:	e426                	sd	s1,8(sp)
    80003882:	1000                	addi	s0,sp,32
    80003884:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003886:	0001c517          	auipc	a0,0x1c
    8000388a:	45250513          	addi	a0,a0,1106 # 8001fcd8 <itable>
    8000388e:	ffffd097          	auipc	ra,0xffffd
    80003892:	348080e7          	jalr	840(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003896:	449c                	lw	a5,8(s1)
    80003898:	2785                	addiw	a5,a5,1
    8000389a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000389c:	0001c517          	auipc	a0,0x1c
    800038a0:	43c50513          	addi	a0,a0,1084 # 8001fcd8 <itable>
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	3e6080e7          	jalr	998(ra) # 80000c8a <release>
}
    800038ac:	8526                	mv	a0,s1
    800038ae:	60e2                	ld	ra,24(sp)
    800038b0:	6442                	ld	s0,16(sp)
    800038b2:	64a2                	ld	s1,8(sp)
    800038b4:	6105                	addi	sp,sp,32
    800038b6:	8082                	ret

00000000800038b8 <ilock>:
{
    800038b8:	1101                	addi	sp,sp,-32
    800038ba:	ec06                	sd	ra,24(sp)
    800038bc:	e822                	sd	s0,16(sp)
    800038be:	e426                	sd	s1,8(sp)
    800038c0:	e04a                	sd	s2,0(sp)
    800038c2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038c4:	c115                	beqz	a0,800038e8 <ilock+0x30>
    800038c6:	84aa                	mv	s1,a0
    800038c8:	451c                	lw	a5,8(a0)
    800038ca:	00f05f63          	blez	a5,800038e8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038ce:	0541                	addi	a0,a0,16
    800038d0:	00001097          	auipc	ra,0x1
    800038d4:	ca2080e7          	jalr	-862(ra) # 80004572 <acquiresleep>
  if(ip->valid == 0){
    800038d8:	40bc                	lw	a5,64(s1)
    800038da:	cf99                	beqz	a5,800038f8 <ilock+0x40>
}
    800038dc:	60e2                	ld	ra,24(sp)
    800038de:	6442                	ld	s0,16(sp)
    800038e0:	64a2                	ld	s1,8(sp)
    800038e2:	6902                	ld	s2,0(sp)
    800038e4:	6105                	addi	sp,sp,32
    800038e6:	8082                	ret
    panic("ilock");
    800038e8:	00005517          	auipc	a0,0x5
    800038ec:	df850513          	addi	a0,a0,-520 # 800086e0 <syscalls+0x1c0>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	c4e080e7          	jalr	-946(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038f8:	40dc                	lw	a5,4(s1)
    800038fa:	0047d79b          	srliw	a5,a5,0x4
    800038fe:	0001c597          	auipc	a1,0x1c
    80003902:	3d25a583          	lw	a1,978(a1) # 8001fcd0 <sb+0x18>
    80003906:	9dbd                	addw	a1,a1,a5
    80003908:	4088                	lw	a0,0(s1)
    8000390a:	fffff097          	auipc	ra,0xfffff
    8000390e:	794080e7          	jalr	1940(ra) # 8000309e <bread>
    80003912:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003914:	05850593          	addi	a1,a0,88
    80003918:	40dc                	lw	a5,4(s1)
    8000391a:	8bbd                	andi	a5,a5,15
    8000391c:	079a                	slli	a5,a5,0x6
    8000391e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003920:	00059783          	lh	a5,0(a1)
    80003924:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003928:	00259783          	lh	a5,2(a1)
    8000392c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003930:	00459783          	lh	a5,4(a1)
    80003934:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003938:	00659783          	lh	a5,6(a1)
    8000393c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003940:	459c                	lw	a5,8(a1)
    80003942:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003944:	03400613          	li	a2,52
    80003948:	05b1                	addi	a1,a1,12
    8000394a:	05048513          	addi	a0,s1,80
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	3e0080e7          	jalr	992(ra) # 80000d2e <memmove>
    brelse(bp);
    80003956:	854a                	mv	a0,s2
    80003958:	00000097          	auipc	ra,0x0
    8000395c:	876080e7          	jalr	-1930(ra) # 800031ce <brelse>
    ip->valid = 1;
    80003960:	4785                	li	a5,1
    80003962:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003964:	04449783          	lh	a5,68(s1)
    80003968:	fbb5                	bnez	a5,800038dc <ilock+0x24>
      panic("ilock: no type");
    8000396a:	00005517          	auipc	a0,0x5
    8000396e:	d7e50513          	addi	a0,a0,-642 # 800086e8 <syscalls+0x1c8>
    80003972:	ffffd097          	auipc	ra,0xffffd
    80003976:	bcc080e7          	jalr	-1076(ra) # 8000053e <panic>

000000008000397a <iunlock>:
{
    8000397a:	1101                	addi	sp,sp,-32
    8000397c:	ec06                	sd	ra,24(sp)
    8000397e:	e822                	sd	s0,16(sp)
    80003980:	e426                	sd	s1,8(sp)
    80003982:	e04a                	sd	s2,0(sp)
    80003984:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003986:	c905                	beqz	a0,800039b6 <iunlock+0x3c>
    80003988:	84aa                	mv	s1,a0
    8000398a:	01050913          	addi	s2,a0,16
    8000398e:	854a                	mv	a0,s2
    80003990:	00001097          	auipc	ra,0x1
    80003994:	c7c080e7          	jalr	-900(ra) # 8000460c <holdingsleep>
    80003998:	cd19                	beqz	a0,800039b6 <iunlock+0x3c>
    8000399a:	449c                	lw	a5,8(s1)
    8000399c:	00f05d63          	blez	a5,800039b6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039a0:	854a                	mv	a0,s2
    800039a2:	00001097          	auipc	ra,0x1
    800039a6:	c26080e7          	jalr	-986(ra) # 800045c8 <releasesleep>
}
    800039aa:	60e2                	ld	ra,24(sp)
    800039ac:	6442                	ld	s0,16(sp)
    800039ae:	64a2                	ld	s1,8(sp)
    800039b0:	6902                	ld	s2,0(sp)
    800039b2:	6105                	addi	sp,sp,32
    800039b4:	8082                	ret
    panic("iunlock");
    800039b6:	00005517          	auipc	a0,0x5
    800039ba:	d4250513          	addi	a0,a0,-702 # 800086f8 <syscalls+0x1d8>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	b80080e7          	jalr	-1152(ra) # 8000053e <panic>

00000000800039c6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039c6:	7179                	addi	sp,sp,-48
    800039c8:	f406                	sd	ra,40(sp)
    800039ca:	f022                	sd	s0,32(sp)
    800039cc:	ec26                	sd	s1,24(sp)
    800039ce:	e84a                	sd	s2,16(sp)
    800039d0:	e44e                	sd	s3,8(sp)
    800039d2:	e052                	sd	s4,0(sp)
    800039d4:	1800                	addi	s0,sp,48
    800039d6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039d8:	05050493          	addi	s1,a0,80
    800039dc:	08050913          	addi	s2,a0,128
    800039e0:	a021                	j	800039e8 <itrunc+0x22>
    800039e2:	0491                	addi	s1,s1,4
    800039e4:	01248d63          	beq	s1,s2,800039fe <itrunc+0x38>
    if(ip->addrs[i]){
    800039e8:	408c                	lw	a1,0(s1)
    800039ea:	dde5                	beqz	a1,800039e2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039ec:	0009a503          	lw	a0,0(s3)
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	8f4080e7          	jalr	-1804(ra) # 800032e4 <bfree>
      ip->addrs[i] = 0;
    800039f8:	0004a023          	sw	zero,0(s1)
    800039fc:	b7dd                	j	800039e2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039fe:	0809a583          	lw	a1,128(s3)
    80003a02:	e185                	bnez	a1,80003a22 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a04:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a08:	854e                	mv	a0,s3
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	de4080e7          	jalr	-540(ra) # 800037ee <iupdate>
}
    80003a12:	70a2                	ld	ra,40(sp)
    80003a14:	7402                	ld	s0,32(sp)
    80003a16:	64e2                	ld	s1,24(sp)
    80003a18:	6942                	ld	s2,16(sp)
    80003a1a:	69a2                	ld	s3,8(sp)
    80003a1c:	6a02                	ld	s4,0(sp)
    80003a1e:	6145                	addi	sp,sp,48
    80003a20:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a22:	0009a503          	lw	a0,0(s3)
    80003a26:	fffff097          	auipc	ra,0xfffff
    80003a2a:	678080e7          	jalr	1656(ra) # 8000309e <bread>
    80003a2e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a30:	05850493          	addi	s1,a0,88
    80003a34:	45850913          	addi	s2,a0,1112
    80003a38:	a021                	j	80003a40 <itrunc+0x7a>
    80003a3a:	0491                	addi	s1,s1,4
    80003a3c:	01248b63          	beq	s1,s2,80003a52 <itrunc+0x8c>
      if(a[j])
    80003a40:	408c                	lw	a1,0(s1)
    80003a42:	dde5                	beqz	a1,80003a3a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a44:	0009a503          	lw	a0,0(s3)
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	89c080e7          	jalr	-1892(ra) # 800032e4 <bfree>
    80003a50:	b7ed                	j	80003a3a <itrunc+0x74>
    brelse(bp);
    80003a52:	8552                	mv	a0,s4
    80003a54:	fffff097          	auipc	ra,0xfffff
    80003a58:	77a080e7          	jalr	1914(ra) # 800031ce <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a5c:	0809a583          	lw	a1,128(s3)
    80003a60:	0009a503          	lw	a0,0(s3)
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	880080e7          	jalr	-1920(ra) # 800032e4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a6c:	0809a023          	sw	zero,128(s3)
    80003a70:	bf51                	j	80003a04 <itrunc+0x3e>

0000000080003a72 <iput>:
{
    80003a72:	1101                	addi	sp,sp,-32
    80003a74:	ec06                	sd	ra,24(sp)
    80003a76:	e822                	sd	s0,16(sp)
    80003a78:	e426                	sd	s1,8(sp)
    80003a7a:	e04a                	sd	s2,0(sp)
    80003a7c:	1000                	addi	s0,sp,32
    80003a7e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a80:	0001c517          	auipc	a0,0x1c
    80003a84:	25850513          	addi	a0,a0,600 # 8001fcd8 <itable>
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	14e080e7          	jalr	334(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a90:	4498                	lw	a4,8(s1)
    80003a92:	4785                	li	a5,1
    80003a94:	02f70363          	beq	a4,a5,80003aba <iput+0x48>
  ip->ref--;
    80003a98:	449c                	lw	a5,8(s1)
    80003a9a:	37fd                	addiw	a5,a5,-1
    80003a9c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a9e:	0001c517          	auipc	a0,0x1c
    80003aa2:	23a50513          	addi	a0,a0,570 # 8001fcd8 <itable>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	1e4080e7          	jalr	484(ra) # 80000c8a <release>
}
    80003aae:	60e2                	ld	ra,24(sp)
    80003ab0:	6442                	ld	s0,16(sp)
    80003ab2:	64a2                	ld	s1,8(sp)
    80003ab4:	6902                	ld	s2,0(sp)
    80003ab6:	6105                	addi	sp,sp,32
    80003ab8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aba:	40bc                	lw	a5,64(s1)
    80003abc:	dff1                	beqz	a5,80003a98 <iput+0x26>
    80003abe:	04a49783          	lh	a5,74(s1)
    80003ac2:	fbf9                	bnez	a5,80003a98 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ac4:	01048913          	addi	s2,s1,16
    80003ac8:	854a                	mv	a0,s2
    80003aca:	00001097          	auipc	ra,0x1
    80003ace:	aa8080e7          	jalr	-1368(ra) # 80004572 <acquiresleep>
    release(&itable.lock);
    80003ad2:	0001c517          	auipc	a0,0x1c
    80003ad6:	20650513          	addi	a0,a0,518 # 8001fcd8 <itable>
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	1b0080e7          	jalr	432(ra) # 80000c8a <release>
    itrunc(ip);
    80003ae2:	8526                	mv	a0,s1
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	ee2080e7          	jalr	-286(ra) # 800039c6 <itrunc>
    ip->type = 0;
    80003aec:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003af0:	8526                	mv	a0,s1
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	cfc080e7          	jalr	-772(ra) # 800037ee <iupdate>
    ip->valid = 0;
    80003afa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003afe:	854a                	mv	a0,s2
    80003b00:	00001097          	auipc	ra,0x1
    80003b04:	ac8080e7          	jalr	-1336(ra) # 800045c8 <releasesleep>
    acquire(&itable.lock);
    80003b08:	0001c517          	auipc	a0,0x1c
    80003b0c:	1d050513          	addi	a0,a0,464 # 8001fcd8 <itable>
    80003b10:	ffffd097          	auipc	ra,0xffffd
    80003b14:	0c6080e7          	jalr	198(ra) # 80000bd6 <acquire>
    80003b18:	b741                	j	80003a98 <iput+0x26>

0000000080003b1a <iunlockput>:
{
    80003b1a:	1101                	addi	sp,sp,-32
    80003b1c:	ec06                	sd	ra,24(sp)
    80003b1e:	e822                	sd	s0,16(sp)
    80003b20:	e426                	sd	s1,8(sp)
    80003b22:	1000                	addi	s0,sp,32
    80003b24:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	e54080e7          	jalr	-428(ra) # 8000397a <iunlock>
  iput(ip);
    80003b2e:	8526                	mv	a0,s1
    80003b30:	00000097          	auipc	ra,0x0
    80003b34:	f42080e7          	jalr	-190(ra) # 80003a72 <iput>
}
    80003b38:	60e2                	ld	ra,24(sp)
    80003b3a:	6442                	ld	s0,16(sp)
    80003b3c:	64a2                	ld	s1,8(sp)
    80003b3e:	6105                	addi	sp,sp,32
    80003b40:	8082                	ret

0000000080003b42 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b42:	1141                	addi	sp,sp,-16
    80003b44:	e422                	sd	s0,8(sp)
    80003b46:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b48:	411c                	lw	a5,0(a0)
    80003b4a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b4c:	415c                	lw	a5,4(a0)
    80003b4e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b50:	04451783          	lh	a5,68(a0)
    80003b54:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b58:	04a51783          	lh	a5,74(a0)
    80003b5c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b60:	04c56783          	lwu	a5,76(a0)
    80003b64:	e99c                	sd	a5,16(a1)
}
    80003b66:	6422                	ld	s0,8(sp)
    80003b68:	0141                	addi	sp,sp,16
    80003b6a:	8082                	ret

0000000080003b6c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b6c:	457c                	lw	a5,76(a0)
    80003b6e:	0ed7e963          	bltu	a5,a3,80003c60 <readi+0xf4>
{
    80003b72:	7159                	addi	sp,sp,-112
    80003b74:	f486                	sd	ra,104(sp)
    80003b76:	f0a2                	sd	s0,96(sp)
    80003b78:	eca6                	sd	s1,88(sp)
    80003b7a:	e8ca                	sd	s2,80(sp)
    80003b7c:	e4ce                	sd	s3,72(sp)
    80003b7e:	e0d2                	sd	s4,64(sp)
    80003b80:	fc56                	sd	s5,56(sp)
    80003b82:	f85a                	sd	s6,48(sp)
    80003b84:	f45e                	sd	s7,40(sp)
    80003b86:	f062                	sd	s8,32(sp)
    80003b88:	ec66                	sd	s9,24(sp)
    80003b8a:	e86a                	sd	s10,16(sp)
    80003b8c:	e46e                	sd	s11,8(sp)
    80003b8e:	1880                	addi	s0,sp,112
    80003b90:	8b2a                	mv	s6,a0
    80003b92:	8bae                	mv	s7,a1
    80003b94:	8a32                	mv	s4,a2
    80003b96:	84b6                	mv	s1,a3
    80003b98:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b9a:	9f35                	addw	a4,a4,a3
    return 0;
    80003b9c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b9e:	0ad76063          	bltu	a4,a3,80003c3e <readi+0xd2>
  if(off + n > ip->size)
    80003ba2:	00e7f463          	bgeu	a5,a4,80003baa <readi+0x3e>
    n = ip->size - off;
    80003ba6:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003baa:	0a0a8963          	beqz	s5,80003c5c <readi+0xf0>
    80003bae:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb0:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bb4:	5c7d                	li	s8,-1
    80003bb6:	a82d                	j	80003bf0 <readi+0x84>
    80003bb8:	020d1d93          	slli	s11,s10,0x20
    80003bbc:	020ddd93          	srli	s11,s11,0x20
    80003bc0:	05890793          	addi	a5,s2,88
    80003bc4:	86ee                	mv	a3,s11
    80003bc6:	963e                	add	a2,a2,a5
    80003bc8:	85d2                	mv	a1,s4
    80003bca:	855e                	mv	a0,s7
    80003bcc:	fffff097          	auipc	ra,0xfffff
    80003bd0:	95e080e7          	jalr	-1698(ra) # 8000252a <either_copyout>
    80003bd4:	05850d63          	beq	a0,s8,80003c2e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bd8:	854a                	mv	a0,s2
    80003bda:	fffff097          	auipc	ra,0xfffff
    80003bde:	5f4080e7          	jalr	1524(ra) # 800031ce <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003be2:	013d09bb          	addw	s3,s10,s3
    80003be6:	009d04bb          	addw	s1,s10,s1
    80003bea:	9a6e                	add	s4,s4,s11
    80003bec:	0559f763          	bgeu	s3,s5,80003c3a <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003bf0:	00a4d59b          	srliw	a1,s1,0xa
    80003bf4:	855a                	mv	a0,s6
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	8a2080e7          	jalr	-1886(ra) # 80003498 <bmap>
    80003bfe:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c02:	cd85                	beqz	a1,80003c3a <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c04:	000b2503          	lw	a0,0(s6)
    80003c08:	fffff097          	auipc	ra,0xfffff
    80003c0c:	496080e7          	jalr	1174(ra) # 8000309e <bread>
    80003c10:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c12:	3ff4f613          	andi	a2,s1,1023
    80003c16:	40cc87bb          	subw	a5,s9,a2
    80003c1a:	413a873b          	subw	a4,s5,s3
    80003c1e:	8d3e                	mv	s10,a5
    80003c20:	2781                	sext.w	a5,a5
    80003c22:	0007069b          	sext.w	a3,a4
    80003c26:	f8f6f9e3          	bgeu	a3,a5,80003bb8 <readi+0x4c>
    80003c2a:	8d3a                	mv	s10,a4
    80003c2c:	b771                	j	80003bb8 <readi+0x4c>
      brelse(bp);
    80003c2e:	854a                	mv	a0,s2
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	59e080e7          	jalr	1438(ra) # 800031ce <brelse>
      tot = -1;
    80003c38:	59fd                	li	s3,-1
  }
  return tot;
    80003c3a:	0009851b          	sext.w	a0,s3
}
    80003c3e:	70a6                	ld	ra,104(sp)
    80003c40:	7406                	ld	s0,96(sp)
    80003c42:	64e6                	ld	s1,88(sp)
    80003c44:	6946                	ld	s2,80(sp)
    80003c46:	69a6                	ld	s3,72(sp)
    80003c48:	6a06                	ld	s4,64(sp)
    80003c4a:	7ae2                	ld	s5,56(sp)
    80003c4c:	7b42                	ld	s6,48(sp)
    80003c4e:	7ba2                	ld	s7,40(sp)
    80003c50:	7c02                	ld	s8,32(sp)
    80003c52:	6ce2                	ld	s9,24(sp)
    80003c54:	6d42                	ld	s10,16(sp)
    80003c56:	6da2                	ld	s11,8(sp)
    80003c58:	6165                	addi	sp,sp,112
    80003c5a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c5c:	89d6                	mv	s3,s5
    80003c5e:	bff1                	j	80003c3a <readi+0xce>
    return 0;
    80003c60:	4501                	li	a0,0
}
    80003c62:	8082                	ret

0000000080003c64 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c64:	457c                	lw	a5,76(a0)
    80003c66:	10d7e863          	bltu	a5,a3,80003d76 <writei+0x112>
{
    80003c6a:	7159                	addi	sp,sp,-112
    80003c6c:	f486                	sd	ra,104(sp)
    80003c6e:	f0a2                	sd	s0,96(sp)
    80003c70:	eca6                	sd	s1,88(sp)
    80003c72:	e8ca                	sd	s2,80(sp)
    80003c74:	e4ce                	sd	s3,72(sp)
    80003c76:	e0d2                	sd	s4,64(sp)
    80003c78:	fc56                	sd	s5,56(sp)
    80003c7a:	f85a                	sd	s6,48(sp)
    80003c7c:	f45e                	sd	s7,40(sp)
    80003c7e:	f062                	sd	s8,32(sp)
    80003c80:	ec66                	sd	s9,24(sp)
    80003c82:	e86a                	sd	s10,16(sp)
    80003c84:	e46e                	sd	s11,8(sp)
    80003c86:	1880                	addi	s0,sp,112
    80003c88:	8aaa                	mv	s5,a0
    80003c8a:	8bae                	mv	s7,a1
    80003c8c:	8a32                	mv	s4,a2
    80003c8e:	8936                	mv	s2,a3
    80003c90:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c92:	00e687bb          	addw	a5,a3,a4
    80003c96:	0ed7e263          	bltu	a5,a3,80003d7a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c9a:	00043737          	lui	a4,0x43
    80003c9e:	0ef76063          	bltu	a4,a5,80003d7e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ca2:	0c0b0863          	beqz	s6,80003d72 <writei+0x10e>
    80003ca6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ca8:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cac:	5c7d                	li	s8,-1
    80003cae:	a091                	j	80003cf2 <writei+0x8e>
    80003cb0:	020d1d93          	slli	s11,s10,0x20
    80003cb4:	020ddd93          	srli	s11,s11,0x20
    80003cb8:	05848793          	addi	a5,s1,88
    80003cbc:	86ee                	mv	a3,s11
    80003cbe:	8652                	mv	a2,s4
    80003cc0:	85de                	mv	a1,s7
    80003cc2:	953e                	add	a0,a0,a5
    80003cc4:	fffff097          	auipc	ra,0xfffff
    80003cc8:	8bc080e7          	jalr	-1860(ra) # 80002580 <either_copyin>
    80003ccc:	07850263          	beq	a0,s8,80003d30 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cd0:	8526                	mv	a0,s1
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	780080e7          	jalr	1920(ra) # 80004452 <log_write>
    brelse(bp);
    80003cda:	8526                	mv	a0,s1
    80003cdc:	fffff097          	auipc	ra,0xfffff
    80003ce0:	4f2080e7          	jalr	1266(ra) # 800031ce <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ce4:	013d09bb          	addw	s3,s10,s3
    80003ce8:	012d093b          	addw	s2,s10,s2
    80003cec:	9a6e                	add	s4,s4,s11
    80003cee:	0569f663          	bgeu	s3,s6,80003d3a <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003cf2:	00a9559b          	srliw	a1,s2,0xa
    80003cf6:	8556                	mv	a0,s5
    80003cf8:	fffff097          	auipc	ra,0xfffff
    80003cfc:	7a0080e7          	jalr	1952(ra) # 80003498 <bmap>
    80003d00:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d04:	c99d                	beqz	a1,80003d3a <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d06:	000aa503          	lw	a0,0(s5)
    80003d0a:	fffff097          	auipc	ra,0xfffff
    80003d0e:	394080e7          	jalr	916(ra) # 8000309e <bread>
    80003d12:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d14:	3ff97513          	andi	a0,s2,1023
    80003d18:	40ac87bb          	subw	a5,s9,a0
    80003d1c:	413b073b          	subw	a4,s6,s3
    80003d20:	8d3e                	mv	s10,a5
    80003d22:	2781                	sext.w	a5,a5
    80003d24:	0007069b          	sext.w	a3,a4
    80003d28:	f8f6f4e3          	bgeu	a3,a5,80003cb0 <writei+0x4c>
    80003d2c:	8d3a                	mv	s10,a4
    80003d2e:	b749                	j	80003cb0 <writei+0x4c>
      brelse(bp);
    80003d30:	8526                	mv	a0,s1
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	49c080e7          	jalr	1180(ra) # 800031ce <brelse>
  }

  if(off > ip->size)
    80003d3a:	04caa783          	lw	a5,76(s5)
    80003d3e:	0127f463          	bgeu	a5,s2,80003d46 <writei+0xe2>
    ip->size = off;
    80003d42:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d46:	8556                	mv	a0,s5
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	aa6080e7          	jalr	-1370(ra) # 800037ee <iupdate>

  return tot;
    80003d50:	0009851b          	sext.w	a0,s3
}
    80003d54:	70a6                	ld	ra,104(sp)
    80003d56:	7406                	ld	s0,96(sp)
    80003d58:	64e6                	ld	s1,88(sp)
    80003d5a:	6946                	ld	s2,80(sp)
    80003d5c:	69a6                	ld	s3,72(sp)
    80003d5e:	6a06                	ld	s4,64(sp)
    80003d60:	7ae2                	ld	s5,56(sp)
    80003d62:	7b42                	ld	s6,48(sp)
    80003d64:	7ba2                	ld	s7,40(sp)
    80003d66:	7c02                	ld	s8,32(sp)
    80003d68:	6ce2                	ld	s9,24(sp)
    80003d6a:	6d42                	ld	s10,16(sp)
    80003d6c:	6da2                	ld	s11,8(sp)
    80003d6e:	6165                	addi	sp,sp,112
    80003d70:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d72:	89da                	mv	s3,s6
    80003d74:	bfc9                	j	80003d46 <writei+0xe2>
    return -1;
    80003d76:	557d                	li	a0,-1
}
    80003d78:	8082                	ret
    return -1;
    80003d7a:	557d                	li	a0,-1
    80003d7c:	bfe1                	j	80003d54 <writei+0xf0>
    return -1;
    80003d7e:	557d                	li	a0,-1
    80003d80:	bfd1                	j	80003d54 <writei+0xf0>

0000000080003d82 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d82:	1141                	addi	sp,sp,-16
    80003d84:	e406                	sd	ra,8(sp)
    80003d86:	e022                	sd	s0,0(sp)
    80003d88:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d8a:	4639                	li	a2,14
    80003d8c:	ffffd097          	auipc	ra,0xffffd
    80003d90:	016080e7          	jalr	22(ra) # 80000da2 <strncmp>
}
    80003d94:	60a2                	ld	ra,8(sp)
    80003d96:	6402                	ld	s0,0(sp)
    80003d98:	0141                	addi	sp,sp,16
    80003d9a:	8082                	ret

0000000080003d9c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d9c:	7139                	addi	sp,sp,-64
    80003d9e:	fc06                	sd	ra,56(sp)
    80003da0:	f822                	sd	s0,48(sp)
    80003da2:	f426                	sd	s1,40(sp)
    80003da4:	f04a                	sd	s2,32(sp)
    80003da6:	ec4e                	sd	s3,24(sp)
    80003da8:	e852                	sd	s4,16(sp)
    80003daa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dac:	04451703          	lh	a4,68(a0)
    80003db0:	4785                	li	a5,1
    80003db2:	00f71a63          	bne	a4,a5,80003dc6 <dirlookup+0x2a>
    80003db6:	892a                	mv	s2,a0
    80003db8:	89ae                	mv	s3,a1
    80003dba:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dbc:	457c                	lw	a5,76(a0)
    80003dbe:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dc0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc2:	e79d                	bnez	a5,80003df0 <dirlookup+0x54>
    80003dc4:	a8a5                	j	80003e3c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dc6:	00005517          	auipc	a0,0x5
    80003dca:	93a50513          	addi	a0,a0,-1734 # 80008700 <syscalls+0x1e0>
    80003dce:	ffffc097          	auipc	ra,0xffffc
    80003dd2:	770080e7          	jalr	1904(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003dd6:	00005517          	auipc	a0,0x5
    80003dda:	94250513          	addi	a0,a0,-1726 # 80008718 <syscalls+0x1f8>
    80003dde:	ffffc097          	auipc	ra,0xffffc
    80003de2:	760080e7          	jalr	1888(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de6:	24c1                	addiw	s1,s1,16
    80003de8:	04c92783          	lw	a5,76(s2)
    80003dec:	04f4f763          	bgeu	s1,a5,80003e3a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003df0:	4741                	li	a4,16
    80003df2:	86a6                	mv	a3,s1
    80003df4:	fc040613          	addi	a2,s0,-64
    80003df8:	4581                	li	a1,0
    80003dfa:	854a                	mv	a0,s2
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	d70080e7          	jalr	-656(ra) # 80003b6c <readi>
    80003e04:	47c1                	li	a5,16
    80003e06:	fcf518e3          	bne	a0,a5,80003dd6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e0a:	fc045783          	lhu	a5,-64(s0)
    80003e0e:	dfe1                	beqz	a5,80003de6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e10:	fc240593          	addi	a1,s0,-62
    80003e14:	854e                	mv	a0,s3
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	f6c080e7          	jalr	-148(ra) # 80003d82 <namecmp>
    80003e1e:	f561                	bnez	a0,80003de6 <dirlookup+0x4a>
      if(poff)
    80003e20:	000a0463          	beqz	s4,80003e28 <dirlookup+0x8c>
        *poff = off;
    80003e24:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e28:	fc045583          	lhu	a1,-64(s0)
    80003e2c:	00092503          	lw	a0,0(s2)
    80003e30:	fffff097          	auipc	ra,0xfffff
    80003e34:	750080e7          	jalr	1872(ra) # 80003580 <iget>
    80003e38:	a011                	j	80003e3c <dirlookup+0xa0>
  return 0;
    80003e3a:	4501                	li	a0,0
}
    80003e3c:	70e2                	ld	ra,56(sp)
    80003e3e:	7442                	ld	s0,48(sp)
    80003e40:	74a2                	ld	s1,40(sp)
    80003e42:	7902                	ld	s2,32(sp)
    80003e44:	69e2                	ld	s3,24(sp)
    80003e46:	6a42                	ld	s4,16(sp)
    80003e48:	6121                	addi	sp,sp,64
    80003e4a:	8082                	ret

0000000080003e4c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e4c:	711d                	addi	sp,sp,-96
    80003e4e:	ec86                	sd	ra,88(sp)
    80003e50:	e8a2                	sd	s0,80(sp)
    80003e52:	e4a6                	sd	s1,72(sp)
    80003e54:	e0ca                	sd	s2,64(sp)
    80003e56:	fc4e                	sd	s3,56(sp)
    80003e58:	f852                	sd	s4,48(sp)
    80003e5a:	f456                	sd	s5,40(sp)
    80003e5c:	f05a                	sd	s6,32(sp)
    80003e5e:	ec5e                	sd	s7,24(sp)
    80003e60:	e862                	sd	s8,16(sp)
    80003e62:	e466                	sd	s9,8(sp)
    80003e64:	1080                	addi	s0,sp,96
    80003e66:	84aa                	mv	s1,a0
    80003e68:	8aae                	mv	s5,a1
    80003e6a:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e6c:	00054703          	lbu	a4,0(a0)
    80003e70:	02f00793          	li	a5,47
    80003e74:	02f70363          	beq	a4,a5,80003e9a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e78:	ffffe097          	auipc	ra,0xffffe
    80003e7c:	b6a080e7          	jalr	-1174(ra) # 800019e2 <myproc>
    80003e80:	15053503          	ld	a0,336(a0)
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	9f6080e7          	jalr	-1546(ra) # 8000387a <idup>
    80003e8c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e8e:	02f00913          	li	s2,47
  len = path - s;
    80003e92:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e94:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e96:	4b85                	li	s7,1
    80003e98:	a865                	j	80003f50 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e9a:	4585                	li	a1,1
    80003e9c:	4505                	li	a0,1
    80003e9e:	fffff097          	auipc	ra,0xfffff
    80003ea2:	6e2080e7          	jalr	1762(ra) # 80003580 <iget>
    80003ea6:	89aa                	mv	s3,a0
    80003ea8:	b7dd                	j	80003e8e <namex+0x42>
      iunlockput(ip);
    80003eaa:	854e                	mv	a0,s3
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	c6e080e7          	jalr	-914(ra) # 80003b1a <iunlockput>
      return 0;
    80003eb4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003eb6:	854e                	mv	a0,s3
    80003eb8:	60e6                	ld	ra,88(sp)
    80003eba:	6446                	ld	s0,80(sp)
    80003ebc:	64a6                	ld	s1,72(sp)
    80003ebe:	6906                	ld	s2,64(sp)
    80003ec0:	79e2                	ld	s3,56(sp)
    80003ec2:	7a42                	ld	s4,48(sp)
    80003ec4:	7aa2                	ld	s5,40(sp)
    80003ec6:	7b02                	ld	s6,32(sp)
    80003ec8:	6be2                	ld	s7,24(sp)
    80003eca:	6c42                	ld	s8,16(sp)
    80003ecc:	6ca2                	ld	s9,8(sp)
    80003ece:	6125                	addi	sp,sp,96
    80003ed0:	8082                	ret
      iunlock(ip);
    80003ed2:	854e                	mv	a0,s3
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	aa6080e7          	jalr	-1370(ra) # 8000397a <iunlock>
      return ip;
    80003edc:	bfe9                	j	80003eb6 <namex+0x6a>
      iunlockput(ip);
    80003ede:	854e                	mv	a0,s3
    80003ee0:	00000097          	auipc	ra,0x0
    80003ee4:	c3a080e7          	jalr	-966(ra) # 80003b1a <iunlockput>
      return 0;
    80003ee8:	89e6                	mv	s3,s9
    80003eea:	b7f1                	j	80003eb6 <namex+0x6a>
  len = path - s;
    80003eec:	40b48633          	sub	a2,s1,a1
    80003ef0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003ef4:	099c5463          	bge	s8,s9,80003f7c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ef8:	4639                	li	a2,14
    80003efa:	8552                	mv	a0,s4
    80003efc:	ffffd097          	auipc	ra,0xffffd
    80003f00:	e32080e7          	jalr	-462(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003f04:	0004c783          	lbu	a5,0(s1)
    80003f08:	01279763          	bne	a5,s2,80003f16 <namex+0xca>
    path++;
    80003f0c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f0e:	0004c783          	lbu	a5,0(s1)
    80003f12:	ff278de3          	beq	a5,s2,80003f0c <namex+0xc0>
    ilock(ip);
    80003f16:	854e                	mv	a0,s3
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	9a0080e7          	jalr	-1632(ra) # 800038b8 <ilock>
    if(ip->type != T_DIR){
    80003f20:	04499783          	lh	a5,68(s3)
    80003f24:	f97793e3          	bne	a5,s7,80003eaa <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f28:	000a8563          	beqz	s5,80003f32 <namex+0xe6>
    80003f2c:	0004c783          	lbu	a5,0(s1)
    80003f30:	d3cd                	beqz	a5,80003ed2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f32:	865a                	mv	a2,s6
    80003f34:	85d2                	mv	a1,s4
    80003f36:	854e                	mv	a0,s3
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	e64080e7          	jalr	-412(ra) # 80003d9c <dirlookup>
    80003f40:	8caa                	mv	s9,a0
    80003f42:	dd51                	beqz	a0,80003ede <namex+0x92>
    iunlockput(ip);
    80003f44:	854e                	mv	a0,s3
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	bd4080e7          	jalr	-1068(ra) # 80003b1a <iunlockput>
    ip = next;
    80003f4e:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f50:	0004c783          	lbu	a5,0(s1)
    80003f54:	05279763          	bne	a5,s2,80003fa2 <namex+0x156>
    path++;
    80003f58:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f5a:	0004c783          	lbu	a5,0(s1)
    80003f5e:	ff278de3          	beq	a5,s2,80003f58 <namex+0x10c>
  if(*path == 0)
    80003f62:	c79d                	beqz	a5,80003f90 <namex+0x144>
    path++;
    80003f64:	85a6                	mv	a1,s1
  len = path - s;
    80003f66:	8cda                	mv	s9,s6
    80003f68:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f6a:	01278963          	beq	a5,s2,80003f7c <namex+0x130>
    80003f6e:	dfbd                	beqz	a5,80003eec <namex+0xa0>
    path++;
    80003f70:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f72:	0004c783          	lbu	a5,0(s1)
    80003f76:	ff279ce3          	bne	a5,s2,80003f6e <namex+0x122>
    80003f7a:	bf8d                	j	80003eec <namex+0xa0>
    memmove(name, s, len);
    80003f7c:	2601                	sext.w	a2,a2
    80003f7e:	8552                	mv	a0,s4
    80003f80:	ffffd097          	auipc	ra,0xffffd
    80003f84:	dae080e7          	jalr	-594(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003f88:	9cd2                	add	s9,s9,s4
    80003f8a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f8e:	bf9d                	j	80003f04 <namex+0xb8>
  if(nameiparent){
    80003f90:	f20a83e3          	beqz	s5,80003eb6 <namex+0x6a>
    iput(ip);
    80003f94:	854e                	mv	a0,s3
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	adc080e7          	jalr	-1316(ra) # 80003a72 <iput>
    return 0;
    80003f9e:	4981                	li	s3,0
    80003fa0:	bf19                	j	80003eb6 <namex+0x6a>
  if(*path == 0)
    80003fa2:	d7fd                	beqz	a5,80003f90 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fa4:	0004c783          	lbu	a5,0(s1)
    80003fa8:	85a6                	mv	a1,s1
    80003faa:	b7d1                	j	80003f6e <namex+0x122>

0000000080003fac <dirlink>:
{
    80003fac:	7139                	addi	sp,sp,-64
    80003fae:	fc06                	sd	ra,56(sp)
    80003fb0:	f822                	sd	s0,48(sp)
    80003fb2:	f426                	sd	s1,40(sp)
    80003fb4:	f04a                	sd	s2,32(sp)
    80003fb6:	ec4e                	sd	s3,24(sp)
    80003fb8:	e852                	sd	s4,16(sp)
    80003fba:	0080                	addi	s0,sp,64
    80003fbc:	892a                	mv	s2,a0
    80003fbe:	8a2e                	mv	s4,a1
    80003fc0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fc2:	4601                	li	a2,0
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	dd8080e7          	jalr	-552(ra) # 80003d9c <dirlookup>
    80003fcc:	e93d                	bnez	a0,80004042 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fce:	04c92483          	lw	s1,76(s2)
    80003fd2:	c49d                	beqz	s1,80004000 <dirlink+0x54>
    80003fd4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fd6:	4741                	li	a4,16
    80003fd8:	86a6                	mv	a3,s1
    80003fda:	fc040613          	addi	a2,s0,-64
    80003fde:	4581                	li	a1,0
    80003fe0:	854a                	mv	a0,s2
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	b8a080e7          	jalr	-1142(ra) # 80003b6c <readi>
    80003fea:	47c1                	li	a5,16
    80003fec:	06f51163          	bne	a0,a5,8000404e <dirlink+0xa2>
    if(de.inum == 0)
    80003ff0:	fc045783          	lhu	a5,-64(s0)
    80003ff4:	c791                	beqz	a5,80004000 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff6:	24c1                	addiw	s1,s1,16
    80003ff8:	04c92783          	lw	a5,76(s2)
    80003ffc:	fcf4ede3          	bltu	s1,a5,80003fd6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004000:	4639                	li	a2,14
    80004002:	85d2                	mv	a1,s4
    80004004:	fc240513          	addi	a0,s0,-62
    80004008:	ffffd097          	auipc	ra,0xffffd
    8000400c:	dd6080e7          	jalr	-554(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004010:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004014:	4741                	li	a4,16
    80004016:	86a6                	mv	a3,s1
    80004018:	fc040613          	addi	a2,s0,-64
    8000401c:	4581                	li	a1,0
    8000401e:	854a                	mv	a0,s2
    80004020:	00000097          	auipc	ra,0x0
    80004024:	c44080e7          	jalr	-956(ra) # 80003c64 <writei>
    80004028:	1541                	addi	a0,a0,-16
    8000402a:	00a03533          	snez	a0,a0
    8000402e:	40a00533          	neg	a0,a0
}
    80004032:	70e2                	ld	ra,56(sp)
    80004034:	7442                	ld	s0,48(sp)
    80004036:	74a2                	ld	s1,40(sp)
    80004038:	7902                	ld	s2,32(sp)
    8000403a:	69e2                	ld	s3,24(sp)
    8000403c:	6a42                	ld	s4,16(sp)
    8000403e:	6121                	addi	sp,sp,64
    80004040:	8082                	ret
    iput(ip);
    80004042:	00000097          	auipc	ra,0x0
    80004046:	a30080e7          	jalr	-1488(ra) # 80003a72 <iput>
    return -1;
    8000404a:	557d                	li	a0,-1
    8000404c:	b7dd                	j	80004032 <dirlink+0x86>
      panic("dirlink read");
    8000404e:	00004517          	auipc	a0,0x4
    80004052:	6da50513          	addi	a0,a0,1754 # 80008728 <syscalls+0x208>
    80004056:	ffffc097          	auipc	ra,0xffffc
    8000405a:	4e8080e7          	jalr	1256(ra) # 8000053e <panic>

000000008000405e <namei>:

struct inode*
namei(char *path)
{
    8000405e:	1101                	addi	sp,sp,-32
    80004060:	ec06                	sd	ra,24(sp)
    80004062:	e822                	sd	s0,16(sp)
    80004064:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004066:	fe040613          	addi	a2,s0,-32
    8000406a:	4581                	li	a1,0
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	de0080e7          	jalr	-544(ra) # 80003e4c <namex>
}
    80004074:	60e2                	ld	ra,24(sp)
    80004076:	6442                	ld	s0,16(sp)
    80004078:	6105                	addi	sp,sp,32
    8000407a:	8082                	ret

000000008000407c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000407c:	1141                	addi	sp,sp,-16
    8000407e:	e406                	sd	ra,8(sp)
    80004080:	e022                	sd	s0,0(sp)
    80004082:	0800                	addi	s0,sp,16
    80004084:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004086:	4585                	li	a1,1
    80004088:	00000097          	auipc	ra,0x0
    8000408c:	dc4080e7          	jalr	-572(ra) # 80003e4c <namex>
}
    80004090:	60a2                	ld	ra,8(sp)
    80004092:	6402                	ld	s0,0(sp)
    80004094:	0141                	addi	sp,sp,16
    80004096:	8082                	ret

0000000080004098 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004098:	1101                	addi	sp,sp,-32
    8000409a:	ec06                	sd	ra,24(sp)
    8000409c:	e822                	sd	s0,16(sp)
    8000409e:	e426                	sd	s1,8(sp)
    800040a0:	e04a                	sd	s2,0(sp)
    800040a2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040a4:	0001d917          	auipc	s2,0x1d
    800040a8:	6dc90913          	addi	s2,s2,1756 # 80021780 <log>
    800040ac:	01892583          	lw	a1,24(s2)
    800040b0:	02892503          	lw	a0,40(s2)
    800040b4:	fffff097          	auipc	ra,0xfffff
    800040b8:	fea080e7          	jalr	-22(ra) # 8000309e <bread>
    800040bc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040be:	02c92683          	lw	a3,44(s2)
    800040c2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040c4:	02d05763          	blez	a3,800040f2 <write_head+0x5a>
    800040c8:	0001d797          	auipc	a5,0x1d
    800040cc:	6e878793          	addi	a5,a5,1768 # 800217b0 <log+0x30>
    800040d0:	05c50713          	addi	a4,a0,92
    800040d4:	36fd                	addiw	a3,a3,-1
    800040d6:	1682                	slli	a3,a3,0x20
    800040d8:	9281                	srli	a3,a3,0x20
    800040da:	068a                	slli	a3,a3,0x2
    800040dc:	0001d617          	auipc	a2,0x1d
    800040e0:	6d860613          	addi	a2,a2,1752 # 800217b4 <log+0x34>
    800040e4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040e6:	4390                	lw	a2,0(a5)
    800040e8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040ea:	0791                	addi	a5,a5,4
    800040ec:	0711                	addi	a4,a4,4
    800040ee:	fed79ce3          	bne	a5,a3,800040e6 <write_head+0x4e>
  }
  bwrite(buf);
    800040f2:	8526                	mv	a0,s1
    800040f4:	fffff097          	auipc	ra,0xfffff
    800040f8:	09c080e7          	jalr	156(ra) # 80003190 <bwrite>
  brelse(buf);
    800040fc:	8526                	mv	a0,s1
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	0d0080e7          	jalr	208(ra) # 800031ce <brelse>
}
    80004106:	60e2                	ld	ra,24(sp)
    80004108:	6442                	ld	s0,16(sp)
    8000410a:	64a2                	ld	s1,8(sp)
    8000410c:	6902                	ld	s2,0(sp)
    8000410e:	6105                	addi	sp,sp,32
    80004110:	8082                	ret

0000000080004112 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004112:	0001d797          	auipc	a5,0x1d
    80004116:	69a7a783          	lw	a5,1690(a5) # 800217ac <log+0x2c>
    8000411a:	0af05d63          	blez	a5,800041d4 <install_trans+0xc2>
{
    8000411e:	7139                	addi	sp,sp,-64
    80004120:	fc06                	sd	ra,56(sp)
    80004122:	f822                	sd	s0,48(sp)
    80004124:	f426                	sd	s1,40(sp)
    80004126:	f04a                	sd	s2,32(sp)
    80004128:	ec4e                	sd	s3,24(sp)
    8000412a:	e852                	sd	s4,16(sp)
    8000412c:	e456                	sd	s5,8(sp)
    8000412e:	e05a                	sd	s6,0(sp)
    80004130:	0080                	addi	s0,sp,64
    80004132:	8b2a                	mv	s6,a0
    80004134:	0001da97          	auipc	s5,0x1d
    80004138:	67ca8a93          	addi	s5,s5,1660 # 800217b0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000413c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000413e:	0001d997          	auipc	s3,0x1d
    80004142:	64298993          	addi	s3,s3,1602 # 80021780 <log>
    80004146:	a00d                	j	80004168 <install_trans+0x56>
    brelse(lbuf);
    80004148:	854a                	mv	a0,s2
    8000414a:	fffff097          	auipc	ra,0xfffff
    8000414e:	084080e7          	jalr	132(ra) # 800031ce <brelse>
    brelse(dbuf);
    80004152:	8526                	mv	a0,s1
    80004154:	fffff097          	auipc	ra,0xfffff
    80004158:	07a080e7          	jalr	122(ra) # 800031ce <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000415c:	2a05                	addiw	s4,s4,1
    8000415e:	0a91                	addi	s5,s5,4
    80004160:	02c9a783          	lw	a5,44(s3)
    80004164:	04fa5e63          	bge	s4,a5,800041c0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004168:	0189a583          	lw	a1,24(s3)
    8000416c:	014585bb          	addw	a1,a1,s4
    80004170:	2585                	addiw	a1,a1,1
    80004172:	0289a503          	lw	a0,40(s3)
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	f28080e7          	jalr	-216(ra) # 8000309e <bread>
    8000417e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004180:	000aa583          	lw	a1,0(s5)
    80004184:	0289a503          	lw	a0,40(s3)
    80004188:	fffff097          	auipc	ra,0xfffff
    8000418c:	f16080e7          	jalr	-234(ra) # 8000309e <bread>
    80004190:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004192:	40000613          	li	a2,1024
    80004196:	05890593          	addi	a1,s2,88
    8000419a:	05850513          	addi	a0,a0,88
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	b90080e7          	jalr	-1136(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800041a6:	8526                	mv	a0,s1
    800041a8:	fffff097          	auipc	ra,0xfffff
    800041ac:	fe8080e7          	jalr	-24(ra) # 80003190 <bwrite>
    if(recovering == 0)
    800041b0:	f80b1ce3          	bnez	s6,80004148 <install_trans+0x36>
      bunpin(dbuf);
    800041b4:	8526                	mv	a0,s1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	0f2080e7          	jalr	242(ra) # 800032a8 <bunpin>
    800041be:	b769                	j	80004148 <install_trans+0x36>
}
    800041c0:	70e2                	ld	ra,56(sp)
    800041c2:	7442                	ld	s0,48(sp)
    800041c4:	74a2                	ld	s1,40(sp)
    800041c6:	7902                	ld	s2,32(sp)
    800041c8:	69e2                	ld	s3,24(sp)
    800041ca:	6a42                	ld	s4,16(sp)
    800041cc:	6aa2                	ld	s5,8(sp)
    800041ce:	6b02                	ld	s6,0(sp)
    800041d0:	6121                	addi	sp,sp,64
    800041d2:	8082                	ret
    800041d4:	8082                	ret

00000000800041d6 <initlog>:
{
    800041d6:	7179                	addi	sp,sp,-48
    800041d8:	f406                	sd	ra,40(sp)
    800041da:	f022                	sd	s0,32(sp)
    800041dc:	ec26                	sd	s1,24(sp)
    800041de:	e84a                	sd	s2,16(sp)
    800041e0:	e44e                	sd	s3,8(sp)
    800041e2:	1800                	addi	s0,sp,48
    800041e4:	892a                	mv	s2,a0
    800041e6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041e8:	0001d497          	auipc	s1,0x1d
    800041ec:	59848493          	addi	s1,s1,1432 # 80021780 <log>
    800041f0:	00004597          	auipc	a1,0x4
    800041f4:	54858593          	addi	a1,a1,1352 # 80008738 <syscalls+0x218>
    800041f8:	8526                	mv	a0,s1
    800041fa:	ffffd097          	auipc	ra,0xffffd
    800041fe:	94c080e7          	jalr	-1716(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004202:	0149a583          	lw	a1,20(s3)
    80004206:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004208:	0109a783          	lw	a5,16(s3)
    8000420c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000420e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004212:	854a                	mv	a0,s2
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	e8a080e7          	jalr	-374(ra) # 8000309e <bread>
  log.lh.n = lh->n;
    8000421c:	4d34                	lw	a3,88(a0)
    8000421e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004220:	02d05563          	blez	a3,8000424a <initlog+0x74>
    80004224:	05c50793          	addi	a5,a0,92
    80004228:	0001d717          	auipc	a4,0x1d
    8000422c:	58870713          	addi	a4,a4,1416 # 800217b0 <log+0x30>
    80004230:	36fd                	addiw	a3,a3,-1
    80004232:	1682                	slli	a3,a3,0x20
    80004234:	9281                	srli	a3,a3,0x20
    80004236:	068a                	slli	a3,a3,0x2
    80004238:	06050613          	addi	a2,a0,96
    8000423c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000423e:	4390                	lw	a2,0(a5)
    80004240:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004242:	0791                	addi	a5,a5,4
    80004244:	0711                	addi	a4,a4,4
    80004246:	fed79ce3          	bne	a5,a3,8000423e <initlog+0x68>
  brelse(buf);
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	f84080e7          	jalr	-124(ra) # 800031ce <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004252:	4505                	li	a0,1
    80004254:	00000097          	auipc	ra,0x0
    80004258:	ebe080e7          	jalr	-322(ra) # 80004112 <install_trans>
  log.lh.n = 0;
    8000425c:	0001d797          	auipc	a5,0x1d
    80004260:	5407a823          	sw	zero,1360(a5) # 800217ac <log+0x2c>
  write_head(); // clear the log
    80004264:	00000097          	auipc	ra,0x0
    80004268:	e34080e7          	jalr	-460(ra) # 80004098 <write_head>
}
    8000426c:	70a2                	ld	ra,40(sp)
    8000426e:	7402                	ld	s0,32(sp)
    80004270:	64e2                	ld	s1,24(sp)
    80004272:	6942                	ld	s2,16(sp)
    80004274:	69a2                	ld	s3,8(sp)
    80004276:	6145                	addi	sp,sp,48
    80004278:	8082                	ret

000000008000427a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000427a:	1101                	addi	sp,sp,-32
    8000427c:	ec06                	sd	ra,24(sp)
    8000427e:	e822                	sd	s0,16(sp)
    80004280:	e426                	sd	s1,8(sp)
    80004282:	e04a                	sd	s2,0(sp)
    80004284:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004286:	0001d517          	auipc	a0,0x1d
    8000428a:	4fa50513          	addi	a0,a0,1274 # 80021780 <log>
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	948080e7          	jalr	-1720(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004296:	0001d497          	auipc	s1,0x1d
    8000429a:	4ea48493          	addi	s1,s1,1258 # 80021780 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000429e:	4979                	li	s2,30
    800042a0:	a039                	j	800042ae <begin_op+0x34>
      sleep(&log, &log.lock);
    800042a2:	85a6                	mv	a1,s1
    800042a4:	8526                	mv	a0,s1
    800042a6:	ffffe097          	auipc	ra,0xffffe
    800042aa:	e7c080e7          	jalr	-388(ra) # 80002122 <sleep>
    if(log.committing){
    800042ae:	50dc                	lw	a5,36(s1)
    800042b0:	fbed                	bnez	a5,800042a2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042b2:	509c                	lw	a5,32(s1)
    800042b4:	0017871b          	addiw	a4,a5,1
    800042b8:	0007069b          	sext.w	a3,a4
    800042bc:	0027179b          	slliw	a5,a4,0x2
    800042c0:	9fb9                	addw	a5,a5,a4
    800042c2:	0017979b          	slliw	a5,a5,0x1
    800042c6:	54d8                	lw	a4,44(s1)
    800042c8:	9fb9                	addw	a5,a5,a4
    800042ca:	00f95963          	bge	s2,a5,800042dc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042ce:	85a6                	mv	a1,s1
    800042d0:	8526                	mv	a0,s1
    800042d2:	ffffe097          	auipc	ra,0xffffe
    800042d6:	e50080e7          	jalr	-432(ra) # 80002122 <sleep>
    800042da:	bfd1                	j	800042ae <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042dc:	0001d517          	auipc	a0,0x1d
    800042e0:	4a450513          	addi	a0,a0,1188 # 80021780 <log>
    800042e4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042e6:	ffffd097          	auipc	ra,0xffffd
    800042ea:	9a4080e7          	jalr	-1628(ra) # 80000c8a <release>
      break;
    }
  }
}
    800042ee:	60e2                	ld	ra,24(sp)
    800042f0:	6442                	ld	s0,16(sp)
    800042f2:	64a2                	ld	s1,8(sp)
    800042f4:	6902                	ld	s2,0(sp)
    800042f6:	6105                	addi	sp,sp,32
    800042f8:	8082                	ret

00000000800042fa <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042fa:	7139                	addi	sp,sp,-64
    800042fc:	fc06                	sd	ra,56(sp)
    800042fe:	f822                	sd	s0,48(sp)
    80004300:	f426                	sd	s1,40(sp)
    80004302:	f04a                	sd	s2,32(sp)
    80004304:	ec4e                	sd	s3,24(sp)
    80004306:	e852                	sd	s4,16(sp)
    80004308:	e456                	sd	s5,8(sp)
    8000430a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000430c:	0001d497          	auipc	s1,0x1d
    80004310:	47448493          	addi	s1,s1,1140 # 80021780 <log>
    80004314:	8526                	mv	a0,s1
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	8c0080e7          	jalr	-1856(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000431e:	509c                	lw	a5,32(s1)
    80004320:	37fd                	addiw	a5,a5,-1
    80004322:	0007891b          	sext.w	s2,a5
    80004326:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004328:	50dc                	lw	a5,36(s1)
    8000432a:	e7b9                	bnez	a5,80004378 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000432c:	04091e63          	bnez	s2,80004388 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004330:	0001d497          	auipc	s1,0x1d
    80004334:	45048493          	addi	s1,s1,1104 # 80021780 <log>
    80004338:	4785                	li	a5,1
    8000433a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000433c:	8526                	mv	a0,s1
    8000433e:	ffffd097          	auipc	ra,0xffffd
    80004342:	94c080e7          	jalr	-1716(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004346:	54dc                	lw	a5,44(s1)
    80004348:	06f04763          	bgtz	a5,800043b6 <end_op+0xbc>
    acquire(&log.lock);
    8000434c:	0001d497          	auipc	s1,0x1d
    80004350:	43448493          	addi	s1,s1,1076 # 80021780 <log>
    80004354:	8526                	mv	a0,s1
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	880080e7          	jalr	-1920(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000435e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004362:	8526                	mv	a0,s1
    80004364:	ffffe097          	auipc	ra,0xffffe
    80004368:	e22080e7          	jalr	-478(ra) # 80002186 <wakeup>
    release(&log.lock);
    8000436c:	8526                	mv	a0,s1
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	91c080e7          	jalr	-1764(ra) # 80000c8a <release>
}
    80004376:	a03d                	j	800043a4 <end_op+0xaa>
    panic("log.committing");
    80004378:	00004517          	auipc	a0,0x4
    8000437c:	3c850513          	addi	a0,a0,968 # 80008740 <syscalls+0x220>
    80004380:	ffffc097          	auipc	ra,0xffffc
    80004384:	1be080e7          	jalr	446(ra) # 8000053e <panic>
    wakeup(&log);
    80004388:	0001d497          	auipc	s1,0x1d
    8000438c:	3f848493          	addi	s1,s1,1016 # 80021780 <log>
    80004390:	8526                	mv	a0,s1
    80004392:	ffffe097          	auipc	ra,0xffffe
    80004396:	df4080e7          	jalr	-524(ra) # 80002186 <wakeup>
  release(&log.lock);
    8000439a:	8526                	mv	a0,s1
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	8ee080e7          	jalr	-1810(ra) # 80000c8a <release>
}
    800043a4:	70e2                	ld	ra,56(sp)
    800043a6:	7442                	ld	s0,48(sp)
    800043a8:	74a2                	ld	s1,40(sp)
    800043aa:	7902                	ld	s2,32(sp)
    800043ac:	69e2                	ld	s3,24(sp)
    800043ae:	6a42                	ld	s4,16(sp)
    800043b0:	6aa2                	ld	s5,8(sp)
    800043b2:	6121                	addi	sp,sp,64
    800043b4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b6:	0001da97          	auipc	s5,0x1d
    800043ba:	3faa8a93          	addi	s5,s5,1018 # 800217b0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043be:	0001da17          	auipc	s4,0x1d
    800043c2:	3c2a0a13          	addi	s4,s4,962 # 80021780 <log>
    800043c6:	018a2583          	lw	a1,24(s4)
    800043ca:	012585bb          	addw	a1,a1,s2
    800043ce:	2585                	addiw	a1,a1,1
    800043d0:	028a2503          	lw	a0,40(s4)
    800043d4:	fffff097          	auipc	ra,0xfffff
    800043d8:	cca080e7          	jalr	-822(ra) # 8000309e <bread>
    800043dc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043de:	000aa583          	lw	a1,0(s5)
    800043e2:	028a2503          	lw	a0,40(s4)
    800043e6:	fffff097          	auipc	ra,0xfffff
    800043ea:	cb8080e7          	jalr	-840(ra) # 8000309e <bread>
    800043ee:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043f0:	40000613          	li	a2,1024
    800043f4:	05850593          	addi	a1,a0,88
    800043f8:	05848513          	addi	a0,s1,88
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	932080e7          	jalr	-1742(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004404:	8526                	mv	a0,s1
    80004406:	fffff097          	auipc	ra,0xfffff
    8000440a:	d8a080e7          	jalr	-630(ra) # 80003190 <bwrite>
    brelse(from);
    8000440e:	854e                	mv	a0,s3
    80004410:	fffff097          	auipc	ra,0xfffff
    80004414:	dbe080e7          	jalr	-578(ra) # 800031ce <brelse>
    brelse(to);
    80004418:	8526                	mv	a0,s1
    8000441a:	fffff097          	auipc	ra,0xfffff
    8000441e:	db4080e7          	jalr	-588(ra) # 800031ce <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004422:	2905                	addiw	s2,s2,1
    80004424:	0a91                	addi	s5,s5,4
    80004426:	02ca2783          	lw	a5,44(s4)
    8000442a:	f8f94ee3          	blt	s2,a5,800043c6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000442e:	00000097          	auipc	ra,0x0
    80004432:	c6a080e7          	jalr	-918(ra) # 80004098 <write_head>
    install_trans(0); // Now install writes to home locations
    80004436:	4501                	li	a0,0
    80004438:	00000097          	auipc	ra,0x0
    8000443c:	cda080e7          	jalr	-806(ra) # 80004112 <install_trans>
    log.lh.n = 0;
    80004440:	0001d797          	auipc	a5,0x1d
    80004444:	3607a623          	sw	zero,876(a5) # 800217ac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004448:	00000097          	auipc	ra,0x0
    8000444c:	c50080e7          	jalr	-944(ra) # 80004098 <write_head>
    80004450:	bdf5                	j	8000434c <end_op+0x52>

0000000080004452 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004452:	1101                	addi	sp,sp,-32
    80004454:	ec06                	sd	ra,24(sp)
    80004456:	e822                	sd	s0,16(sp)
    80004458:	e426                	sd	s1,8(sp)
    8000445a:	e04a                	sd	s2,0(sp)
    8000445c:	1000                	addi	s0,sp,32
    8000445e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004460:	0001d917          	auipc	s2,0x1d
    80004464:	32090913          	addi	s2,s2,800 # 80021780 <log>
    80004468:	854a                	mv	a0,s2
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	76c080e7          	jalr	1900(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004472:	02c92603          	lw	a2,44(s2)
    80004476:	47f5                	li	a5,29
    80004478:	06c7c563          	blt	a5,a2,800044e2 <log_write+0x90>
    8000447c:	0001d797          	auipc	a5,0x1d
    80004480:	3207a783          	lw	a5,800(a5) # 8002179c <log+0x1c>
    80004484:	37fd                	addiw	a5,a5,-1
    80004486:	04f65e63          	bge	a2,a5,800044e2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000448a:	0001d797          	auipc	a5,0x1d
    8000448e:	3167a783          	lw	a5,790(a5) # 800217a0 <log+0x20>
    80004492:	06f05063          	blez	a5,800044f2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004496:	4781                	li	a5,0
    80004498:	06c05563          	blez	a2,80004502 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000449c:	44cc                	lw	a1,12(s1)
    8000449e:	0001d717          	auipc	a4,0x1d
    800044a2:	31270713          	addi	a4,a4,786 # 800217b0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044a6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044a8:	4314                	lw	a3,0(a4)
    800044aa:	04b68c63          	beq	a3,a1,80004502 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044ae:	2785                	addiw	a5,a5,1
    800044b0:	0711                	addi	a4,a4,4
    800044b2:	fef61be3          	bne	a2,a5,800044a8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044b6:	0621                	addi	a2,a2,8
    800044b8:	060a                	slli	a2,a2,0x2
    800044ba:	0001d797          	auipc	a5,0x1d
    800044be:	2c678793          	addi	a5,a5,710 # 80021780 <log>
    800044c2:	963e                	add	a2,a2,a5
    800044c4:	44dc                	lw	a5,12(s1)
    800044c6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044c8:	8526                	mv	a0,s1
    800044ca:	fffff097          	auipc	ra,0xfffff
    800044ce:	da2080e7          	jalr	-606(ra) # 8000326c <bpin>
    log.lh.n++;
    800044d2:	0001d717          	auipc	a4,0x1d
    800044d6:	2ae70713          	addi	a4,a4,686 # 80021780 <log>
    800044da:	575c                	lw	a5,44(a4)
    800044dc:	2785                	addiw	a5,a5,1
    800044de:	d75c                	sw	a5,44(a4)
    800044e0:	a835                	j	8000451c <log_write+0xca>
    panic("too big a transaction");
    800044e2:	00004517          	auipc	a0,0x4
    800044e6:	26e50513          	addi	a0,a0,622 # 80008750 <syscalls+0x230>
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	054080e7          	jalr	84(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800044f2:	00004517          	auipc	a0,0x4
    800044f6:	27650513          	addi	a0,a0,630 # 80008768 <syscalls+0x248>
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	044080e7          	jalr	68(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004502:	00878713          	addi	a4,a5,8
    80004506:	00271693          	slli	a3,a4,0x2
    8000450a:	0001d717          	auipc	a4,0x1d
    8000450e:	27670713          	addi	a4,a4,630 # 80021780 <log>
    80004512:	9736                	add	a4,a4,a3
    80004514:	44d4                	lw	a3,12(s1)
    80004516:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004518:	faf608e3          	beq	a2,a5,800044c8 <log_write+0x76>
  }
  release(&log.lock);
    8000451c:	0001d517          	auipc	a0,0x1d
    80004520:	26450513          	addi	a0,a0,612 # 80021780 <log>
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	766080e7          	jalr	1894(ra) # 80000c8a <release>
}
    8000452c:	60e2                	ld	ra,24(sp)
    8000452e:	6442                	ld	s0,16(sp)
    80004530:	64a2                	ld	s1,8(sp)
    80004532:	6902                	ld	s2,0(sp)
    80004534:	6105                	addi	sp,sp,32
    80004536:	8082                	ret

0000000080004538 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004538:	1101                	addi	sp,sp,-32
    8000453a:	ec06                	sd	ra,24(sp)
    8000453c:	e822                	sd	s0,16(sp)
    8000453e:	e426                	sd	s1,8(sp)
    80004540:	e04a                	sd	s2,0(sp)
    80004542:	1000                	addi	s0,sp,32
    80004544:	84aa                	mv	s1,a0
    80004546:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004548:	00004597          	auipc	a1,0x4
    8000454c:	24058593          	addi	a1,a1,576 # 80008788 <syscalls+0x268>
    80004550:	0521                	addi	a0,a0,8
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	5f4080e7          	jalr	1524(ra) # 80000b46 <initlock>
  lk->name = name;
    8000455a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000455e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004562:	0204a423          	sw	zero,40(s1)
}
    80004566:	60e2                	ld	ra,24(sp)
    80004568:	6442                	ld	s0,16(sp)
    8000456a:	64a2                	ld	s1,8(sp)
    8000456c:	6902                	ld	s2,0(sp)
    8000456e:	6105                	addi	sp,sp,32
    80004570:	8082                	ret

0000000080004572 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004572:	1101                	addi	sp,sp,-32
    80004574:	ec06                	sd	ra,24(sp)
    80004576:	e822                	sd	s0,16(sp)
    80004578:	e426                	sd	s1,8(sp)
    8000457a:	e04a                	sd	s2,0(sp)
    8000457c:	1000                	addi	s0,sp,32
    8000457e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004580:	00850913          	addi	s2,a0,8
    80004584:	854a                	mv	a0,s2
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	650080e7          	jalr	1616(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000458e:	409c                	lw	a5,0(s1)
    80004590:	cb89                	beqz	a5,800045a2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004592:	85ca                	mv	a1,s2
    80004594:	8526                	mv	a0,s1
    80004596:	ffffe097          	auipc	ra,0xffffe
    8000459a:	b8c080e7          	jalr	-1140(ra) # 80002122 <sleep>
  while (lk->locked) {
    8000459e:	409c                	lw	a5,0(s1)
    800045a0:	fbed                	bnez	a5,80004592 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045a2:	4785                	li	a5,1
    800045a4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045a6:	ffffd097          	auipc	ra,0xffffd
    800045aa:	43c080e7          	jalr	1084(ra) # 800019e2 <myproc>
    800045ae:	591c                	lw	a5,48(a0)
    800045b0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045b2:	854a                	mv	a0,s2
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	6d6080e7          	jalr	1750(ra) # 80000c8a <release>
}
    800045bc:	60e2                	ld	ra,24(sp)
    800045be:	6442                	ld	s0,16(sp)
    800045c0:	64a2                	ld	s1,8(sp)
    800045c2:	6902                	ld	s2,0(sp)
    800045c4:	6105                	addi	sp,sp,32
    800045c6:	8082                	ret

00000000800045c8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045c8:	1101                	addi	sp,sp,-32
    800045ca:	ec06                	sd	ra,24(sp)
    800045cc:	e822                	sd	s0,16(sp)
    800045ce:	e426                	sd	s1,8(sp)
    800045d0:	e04a                	sd	s2,0(sp)
    800045d2:	1000                	addi	s0,sp,32
    800045d4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045d6:	00850913          	addi	s2,a0,8
    800045da:	854a                	mv	a0,s2
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	5fa080e7          	jalr	1530(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800045e4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045e8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045ec:	8526                	mv	a0,s1
    800045ee:	ffffe097          	auipc	ra,0xffffe
    800045f2:	b98080e7          	jalr	-1128(ra) # 80002186 <wakeup>
  release(&lk->lk);
    800045f6:	854a                	mv	a0,s2
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	692080e7          	jalr	1682(ra) # 80000c8a <release>
}
    80004600:	60e2                	ld	ra,24(sp)
    80004602:	6442                	ld	s0,16(sp)
    80004604:	64a2                	ld	s1,8(sp)
    80004606:	6902                	ld	s2,0(sp)
    80004608:	6105                	addi	sp,sp,32
    8000460a:	8082                	ret

000000008000460c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000460c:	7179                	addi	sp,sp,-48
    8000460e:	f406                	sd	ra,40(sp)
    80004610:	f022                	sd	s0,32(sp)
    80004612:	ec26                	sd	s1,24(sp)
    80004614:	e84a                	sd	s2,16(sp)
    80004616:	e44e                	sd	s3,8(sp)
    80004618:	1800                	addi	s0,sp,48
    8000461a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000461c:	00850913          	addi	s2,a0,8
    80004620:	854a                	mv	a0,s2
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	5b4080e7          	jalr	1460(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000462a:	409c                	lw	a5,0(s1)
    8000462c:	ef99                	bnez	a5,8000464a <holdingsleep+0x3e>
    8000462e:	4481                	li	s1,0
  release(&lk->lk);
    80004630:	854a                	mv	a0,s2
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	658080e7          	jalr	1624(ra) # 80000c8a <release>
  return r;
}
    8000463a:	8526                	mv	a0,s1
    8000463c:	70a2                	ld	ra,40(sp)
    8000463e:	7402                	ld	s0,32(sp)
    80004640:	64e2                	ld	s1,24(sp)
    80004642:	6942                	ld	s2,16(sp)
    80004644:	69a2                	ld	s3,8(sp)
    80004646:	6145                	addi	sp,sp,48
    80004648:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000464a:	0284a983          	lw	s3,40(s1)
    8000464e:	ffffd097          	auipc	ra,0xffffd
    80004652:	394080e7          	jalr	916(ra) # 800019e2 <myproc>
    80004656:	5904                	lw	s1,48(a0)
    80004658:	413484b3          	sub	s1,s1,s3
    8000465c:	0014b493          	seqz	s1,s1
    80004660:	bfc1                	j	80004630 <holdingsleep+0x24>

0000000080004662 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004662:	1141                	addi	sp,sp,-16
    80004664:	e406                	sd	ra,8(sp)
    80004666:	e022                	sd	s0,0(sp)
    80004668:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000466a:	00004597          	auipc	a1,0x4
    8000466e:	12e58593          	addi	a1,a1,302 # 80008798 <syscalls+0x278>
    80004672:	0001d517          	auipc	a0,0x1d
    80004676:	25650513          	addi	a0,a0,598 # 800218c8 <ftable>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	4cc080e7          	jalr	1228(ra) # 80000b46 <initlock>
}
    80004682:	60a2                	ld	ra,8(sp)
    80004684:	6402                	ld	s0,0(sp)
    80004686:	0141                	addi	sp,sp,16
    80004688:	8082                	ret

000000008000468a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000468a:	1101                	addi	sp,sp,-32
    8000468c:	ec06                	sd	ra,24(sp)
    8000468e:	e822                	sd	s0,16(sp)
    80004690:	e426                	sd	s1,8(sp)
    80004692:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004694:	0001d517          	auipc	a0,0x1d
    80004698:	23450513          	addi	a0,a0,564 # 800218c8 <ftable>
    8000469c:	ffffc097          	auipc	ra,0xffffc
    800046a0:	53a080e7          	jalr	1338(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046a4:	0001d497          	auipc	s1,0x1d
    800046a8:	23c48493          	addi	s1,s1,572 # 800218e0 <ftable+0x18>
    800046ac:	0001e717          	auipc	a4,0x1e
    800046b0:	1d470713          	addi	a4,a4,468 # 80022880 <disk>
    if(f->ref == 0){
    800046b4:	40dc                	lw	a5,4(s1)
    800046b6:	cf99                	beqz	a5,800046d4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046b8:	02848493          	addi	s1,s1,40
    800046bc:	fee49ce3          	bne	s1,a4,800046b4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046c0:	0001d517          	auipc	a0,0x1d
    800046c4:	20850513          	addi	a0,a0,520 # 800218c8 <ftable>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	5c2080e7          	jalr	1474(ra) # 80000c8a <release>
  return 0;
    800046d0:	4481                	li	s1,0
    800046d2:	a819                	j	800046e8 <filealloc+0x5e>
      f->ref = 1;
    800046d4:	4785                	li	a5,1
    800046d6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046d8:	0001d517          	auipc	a0,0x1d
    800046dc:	1f050513          	addi	a0,a0,496 # 800218c8 <ftable>
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	5aa080e7          	jalr	1450(ra) # 80000c8a <release>
}
    800046e8:	8526                	mv	a0,s1
    800046ea:	60e2                	ld	ra,24(sp)
    800046ec:	6442                	ld	s0,16(sp)
    800046ee:	64a2                	ld	s1,8(sp)
    800046f0:	6105                	addi	sp,sp,32
    800046f2:	8082                	ret

00000000800046f4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046f4:	1101                	addi	sp,sp,-32
    800046f6:	ec06                	sd	ra,24(sp)
    800046f8:	e822                	sd	s0,16(sp)
    800046fa:	e426                	sd	s1,8(sp)
    800046fc:	1000                	addi	s0,sp,32
    800046fe:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004700:	0001d517          	auipc	a0,0x1d
    80004704:	1c850513          	addi	a0,a0,456 # 800218c8 <ftable>
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	4ce080e7          	jalr	1230(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004710:	40dc                	lw	a5,4(s1)
    80004712:	02f05263          	blez	a5,80004736 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004716:	2785                	addiw	a5,a5,1
    80004718:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000471a:	0001d517          	auipc	a0,0x1d
    8000471e:	1ae50513          	addi	a0,a0,430 # 800218c8 <ftable>
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	568080e7          	jalr	1384(ra) # 80000c8a <release>
  return f;
}
    8000472a:	8526                	mv	a0,s1
    8000472c:	60e2                	ld	ra,24(sp)
    8000472e:	6442                	ld	s0,16(sp)
    80004730:	64a2                	ld	s1,8(sp)
    80004732:	6105                	addi	sp,sp,32
    80004734:	8082                	ret
    panic("filedup");
    80004736:	00004517          	auipc	a0,0x4
    8000473a:	06a50513          	addi	a0,a0,106 # 800087a0 <syscalls+0x280>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	e00080e7          	jalr	-512(ra) # 8000053e <panic>

0000000080004746 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004746:	7139                	addi	sp,sp,-64
    80004748:	fc06                	sd	ra,56(sp)
    8000474a:	f822                	sd	s0,48(sp)
    8000474c:	f426                	sd	s1,40(sp)
    8000474e:	f04a                	sd	s2,32(sp)
    80004750:	ec4e                	sd	s3,24(sp)
    80004752:	e852                	sd	s4,16(sp)
    80004754:	e456                	sd	s5,8(sp)
    80004756:	0080                	addi	s0,sp,64
    80004758:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000475a:	0001d517          	auipc	a0,0x1d
    8000475e:	16e50513          	addi	a0,a0,366 # 800218c8 <ftable>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	474080e7          	jalr	1140(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000476a:	40dc                	lw	a5,4(s1)
    8000476c:	06f05163          	blez	a5,800047ce <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004770:	37fd                	addiw	a5,a5,-1
    80004772:	0007871b          	sext.w	a4,a5
    80004776:	c0dc                	sw	a5,4(s1)
    80004778:	06e04363          	bgtz	a4,800047de <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000477c:	0004a903          	lw	s2,0(s1)
    80004780:	0094ca83          	lbu	s5,9(s1)
    80004784:	0104ba03          	ld	s4,16(s1)
    80004788:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000478c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004790:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004794:	0001d517          	auipc	a0,0x1d
    80004798:	13450513          	addi	a0,a0,308 # 800218c8 <ftable>
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	4ee080e7          	jalr	1262(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800047a4:	4785                	li	a5,1
    800047a6:	04f90d63          	beq	s2,a5,80004800 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047aa:	3979                	addiw	s2,s2,-2
    800047ac:	4785                	li	a5,1
    800047ae:	0527e063          	bltu	a5,s2,800047ee <fileclose+0xa8>
    begin_op();
    800047b2:	00000097          	auipc	ra,0x0
    800047b6:	ac8080e7          	jalr	-1336(ra) # 8000427a <begin_op>
    iput(ff.ip);
    800047ba:	854e                	mv	a0,s3
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	2b6080e7          	jalr	694(ra) # 80003a72 <iput>
    end_op();
    800047c4:	00000097          	auipc	ra,0x0
    800047c8:	b36080e7          	jalr	-1226(ra) # 800042fa <end_op>
    800047cc:	a00d                	j	800047ee <fileclose+0xa8>
    panic("fileclose");
    800047ce:	00004517          	auipc	a0,0x4
    800047d2:	fda50513          	addi	a0,a0,-38 # 800087a8 <syscalls+0x288>
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	d68080e7          	jalr	-664(ra) # 8000053e <panic>
    release(&ftable.lock);
    800047de:	0001d517          	auipc	a0,0x1d
    800047e2:	0ea50513          	addi	a0,a0,234 # 800218c8 <ftable>
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	4a4080e7          	jalr	1188(ra) # 80000c8a <release>
  }
}
    800047ee:	70e2                	ld	ra,56(sp)
    800047f0:	7442                	ld	s0,48(sp)
    800047f2:	74a2                	ld	s1,40(sp)
    800047f4:	7902                	ld	s2,32(sp)
    800047f6:	69e2                	ld	s3,24(sp)
    800047f8:	6a42                	ld	s4,16(sp)
    800047fa:	6aa2                	ld	s5,8(sp)
    800047fc:	6121                	addi	sp,sp,64
    800047fe:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004800:	85d6                	mv	a1,s5
    80004802:	8552                	mv	a0,s4
    80004804:	00000097          	auipc	ra,0x0
    80004808:	34c080e7          	jalr	844(ra) # 80004b50 <pipeclose>
    8000480c:	b7cd                	j	800047ee <fileclose+0xa8>

000000008000480e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000480e:	715d                	addi	sp,sp,-80
    80004810:	e486                	sd	ra,72(sp)
    80004812:	e0a2                	sd	s0,64(sp)
    80004814:	fc26                	sd	s1,56(sp)
    80004816:	f84a                	sd	s2,48(sp)
    80004818:	f44e                	sd	s3,40(sp)
    8000481a:	0880                	addi	s0,sp,80
    8000481c:	84aa                	mv	s1,a0
    8000481e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004820:	ffffd097          	auipc	ra,0xffffd
    80004824:	1c2080e7          	jalr	450(ra) # 800019e2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004828:	409c                	lw	a5,0(s1)
    8000482a:	37f9                	addiw	a5,a5,-2
    8000482c:	4705                	li	a4,1
    8000482e:	04f76763          	bltu	a4,a5,8000487c <filestat+0x6e>
    80004832:	892a                	mv	s2,a0
    ilock(f->ip);
    80004834:	6c88                	ld	a0,24(s1)
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	082080e7          	jalr	130(ra) # 800038b8 <ilock>
    stati(f->ip, &st);
    8000483e:	fb840593          	addi	a1,s0,-72
    80004842:	6c88                	ld	a0,24(s1)
    80004844:	fffff097          	auipc	ra,0xfffff
    80004848:	2fe080e7          	jalr	766(ra) # 80003b42 <stati>
    iunlock(f->ip);
    8000484c:	6c88                	ld	a0,24(s1)
    8000484e:	fffff097          	auipc	ra,0xfffff
    80004852:	12c080e7          	jalr	300(ra) # 8000397a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004856:	46e1                	li	a3,24
    80004858:	fb840613          	addi	a2,s0,-72
    8000485c:	85ce                	mv	a1,s3
    8000485e:	05093503          	ld	a0,80(s2)
    80004862:	ffffd097          	auipc	ra,0xffffd
    80004866:	e3c080e7          	jalr	-452(ra) # 8000169e <copyout>
    8000486a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000486e:	60a6                	ld	ra,72(sp)
    80004870:	6406                	ld	s0,64(sp)
    80004872:	74e2                	ld	s1,56(sp)
    80004874:	7942                	ld	s2,48(sp)
    80004876:	79a2                	ld	s3,40(sp)
    80004878:	6161                	addi	sp,sp,80
    8000487a:	8082                	ret
  return -1;
    8000487c:	557d                	li	a0,-1
    8000487e:	bfc5                	j	8000486e <filestat+0x60>

0000000080004880 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004880:	7179                	addi	sp,sp,-48
    80004882:	f406                	sd	ra,40(sp)
    80004884:	f022                	sd	s0,32(sp)
    80004886:	ec26                	sd	s1,24(sp)
    80004888:	e84a                	sd	s2,16(sp)
    8000488a:	e44e                	sd	s3,8(sp)
    8000488c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000488e:	00854783          	lbu	a5,8(a0)
    80004892:	c3d5                	beqz	a5,80004936 <fileread+0xb6>
    80004894:	84aa                	mv	s1,a0
    80004896:	89ae                	mv	s3,a1
    80004898:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000489a:	411c                	lw	a5,0(a0)
    8000489c:	4705                	li	a4,1
    8000489e:	04e78963          	beq	a5,a4,800048f0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048a2:	470d                	li	a4,3
    800048a4:	04e78d63          	beq	a5,a4,800048fe <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048a8:	4709                	li	a4,2
    800048aa:	06e79e63          	bne	a5,a4,80004926 <fileread+0xa6>
    ilock(f->ip);
    800048ae:	6d08                	ld	a0,24(a0)
    800048b0:	fffff097          	auipc	ra,0xfffff
    800048b4:	008080e7          	jalr	8(ra) # 800038b8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048b8:	874a                	mv	a4,s2
    800048ba:	5094                	lw	a3,32(s1)
    800048bc:	864e                	mv	a2,s3
    800048be:	4585                	li	a1,1
    800048c0:	6c88                	ld	a0,24(s1)
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	2aa080e7          	jalr	682(ra) # 80003b6c <readi>
    800048ca:	892a                	mv	s2,a0
    800048cc:	00a05563          	blez	a0,800048d6 <fileread+0x56>
      f->off += r;
    800048d0:	509c                	lw	a5,32(s1)
    800048d2:	9fa9                	addw	a5,a5,a0
    800048d4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048d6:	6c88                	ld	a0,24(s1)
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	0a2080e7          	jalr	162(ra) # 8000397a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048e0:	854a                	mv	a0,s2
    800048e2:	70a2                	ld	ra,40(sp)
    800048e4:	7402                	ld	s0,32(sp)
    800048e6:	64e2                	ld	s1,24(sp)
    800048e8:	6942                	ld	s2,16(sp)
    800048ea:	69a2                	ld	s3,8(sp)
    800048ec:	6145                	addi	sp,sp,48
    800048ee:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048f0:	6908                	ld	a0,16(a0)
    800048f2:	00000097          	auipc	ra,0x0
    800048f6:	3c6080e7          	jalr	966(ra) # 80004cb8 <piperead>
    800048fa:	892a                	mv	s2,a0
    800048fc:	b7d5                	j	800048e0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048fe:	02451783          	lh	a5,36(a0)
    80004902:	03079693          	slli	a3,a5,0x30
    80004906:	92c1                	srli	a3,a3,0x30
    80004908:	4725                	li	a4,9
    8000490a:	02d76863          	bltu	a4,a3,8000493a <fileread+0xba>
    8000490e:	0792                	slli	a5,a5,0x4
    80004910:	0001d717          	auipc	a4,0x1d
    80004914:	f1870713          	addi	a4,a4,-232 # 80021828 <devsw>
    80004918:	97ba                	add	a5,a5,a4
    8000491a:	639c                	ld	a5,0(a5)
    8000491c:	c38d                	beqz	a5,8000493e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000491e:	4505                	li	a0,1
    80004920:	9782                	jalr	a5
    80004922:	892a                	mv	s2,a0
    80004924:	bf75                	j	800048e0 <fileread+0x60>
    panic("fileread");
    80004926:	00004517          	auipc	a0,0x4
    8000492a:	e9250513          	addi	a0,a0,-366 # 800087b8 <syscalls+0x298>
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	c10080e7          	jalr	-1008(ra) # 8000053e <panic>
    return -1;
    80004936:	597d                	li	s2,-1
    80004938:	b765                	j	800048e0 <fileread+0x60>
      return -1;
    8000493a:	597d                	li	s2,-1
    8000493c:	b755                	j	800048e0 <fileread+0x60>
    8000493e:	597d                	li	s2,-1
    80004940:	b745                	j	800048e0 <fileread+0x60>

0000000080004942 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004942:	715d                	addi	sp,sp,-80
    80004944:	e486                	sd	ra,72(sp)
    80004946:	e0a2                	sd	s0,64(sp)
    80004948:	fc26                	sd	s1,56(sp)
    8000494a:	f84a                	sd	s2,48(sp)
    8000494c:	f44e                	sd	s3,40(sp)
    8000494e:	f052                	sd	s4,32(sp)
    80004950:	ec56                	sd	s5,24(sp)
    80004952:	e85a                	sd	s6,16(sp)
    80004954:	e45e                	sd	s7,8(sp)
    80004956:	e062                	sd	s8,0(sp)
    80004958:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000495a:	00954783          	lbu	a5,9(a0)
    8000495e:	10078663          	beqz	a5,80004a6a <filewrite+0x128>
    80004962:	892a                	mv	s2,a0
    80004964:	8aae                	mv	s5,a1
    80004966:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004968:	411c                	lw	a5,0(a0)
    8000496a:	4705                	li	a4,1
    8000496c:	02e78263          	beq	a5,a4,80004990 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004970:	470d                	li	a4,3
    80004972:	02e78663          	beq	a5,a4,8000499e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004976:	4709                	li	a4,2
    80004978:	0ee79163          	bne	a5,a4,80004a5a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000497c:	0ac05d63          	blez	a2,80004a36 <filewrite+0xf4>
    int i = 0;
    80004980:	4981                	li	s3,0
    80004982:	6b05                	lui	s6,0x1
    80004984:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004988:	6b85                	lui	s7,0x1
    8000498a:	c00b8b9b          	addiw	s7,s7,-1024
    8000498e:	a861                	j	80004a26 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004990:	6908                	ld	a0,16(a0)
    80004992:	00000097          	auipc	ra,0x0
    80004996:	22e080e7          	jalr	558(ra) # 80004bc0 <pipewrite>
    8000499a:	8a2a                	mv	s4,a0
    8000499c:	a045                	j	80004a3c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000499e:	02451783          	lh	a5,36(a0)
    800049a2:	03079693          	slli	a3,a5,0x30
    800049a6:	92c1                	srli	a3,a3,0x30
    800049a8:	4725                	li	a4,9
    800049aa:	0cd76263          	bltu	a4,a3,80004a6e <filewrite+0x12c>
    800049ae:	0792                	slli	a5,a5,0x4
    800049b0:	0001d717          	auipc	a4,0x1d
    800049b4:	e7870713          	addi	a4,a4,-392 # 80021828 <devsw>
    800049b8:	97ba                	add	a5,a5,a4
    800049ba:	679c                	ld	a5,8(a5)
    800049bc:	cbdd                	beqz	a5,80004a72 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049be:	4505                	li	a0,1
    800049c0:	9782                	jalr	a5
    800049c2:	8a2a                	mv	s4,a0
    800049c4:	a8a5                	j	80004a3c <filewrite+0xfa>
    800049c6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	8b0080e7          	jalr	-1872(ra) # 8000427a <begin_op>
      ilock(f->ip);
    800049d2:	01893503          	ld	a0,24(s2)
    800049d6:	fffff097          	auipc	ra,0xfffff
    800049da:	ee2080e7          	jalr	-286(ra) # 800038b8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049de:	8762                	mv	a4,s8
    800049e0:	02092683          	lw	a3,32(s2)
    800049e4:	01598633          	add	a2,s3,s5
    800049e8:	4585                	li	a1,1
    800049ea:	01893503          	ld	a0,24(s2)
    800049ee:	fffff097          	auipc	ra,0xfffff
    800049f2:	276080e7          	jalr	630(ra) # 80003c64 <writei>
    800049f6:	84aa                	mv	s1,a0
    800049f8:	00a05763          	blez	a0,80004a06 <filewrite+0xc4>
        f->off += r;
    800049fc:	02092783          	lw	a5,32(s2)
    80004a00:	9fa9                	addw	a5,a5,a0
    80004a02:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a06:	01893503          	ld	a0,24(s2)
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	f70080e7          	jalr	-144(ra) # 8000397a <iunlock>
      end_op();
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	8e8080e7          	jalr	-1816(ra) # 800042fa <end_op>

      if(r != n1){
    80004a1a:	009c1f63          	bne	s8,s1,80004a38 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a1e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a22:	0149db63          	bge	s3,s4,80004a38 <filewrite+0xf6>
      int n1 = n - i;
    80004a26:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a2a:	84be                	mv	s1,a5
    80004a2c:	2781                	sext.w	a5,a5
    80004a2e:	f8fb5ce3          	bge	s6,a5,800049c6 <filewrite+0x84>
    80004a32:	84de                	mv	s1,s7
    80004a34:	bf49                	j	800049c6 <filewrite+0x84>
    int i = 0;
    80004a36:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a38:	013a1f63          	bne	s4,s3,80004a56 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a3c:	8552                	mv	a0,s4
    80004a3e:	60a6                	ld	ra,72(sp)
    80004a40:	6406                	ld	s0,64(sp)
    80004a42:	74e2                	ld	s1,56(sp)
    80004a44:	7942                	ld	s2,48(sp)
    80004a46:	79a2                	ld	s3,40(sp)
    80004a48:	7a02                	ld	s4,32(sp)
    80004a4a:	6ae2                	ld	s5,24(sp)
    80004a4c:	6b42                	ld	s6,16(sp)
    80004a4e:	6ba2                	ld	s7,8(sp)
    80004a50:	6c02                	ld	s8,0(sp)
    80004a52:	6161                	addi	sp,sp,80
    80004a54:	8082                	ret
    ret = (i == n ? n : -1);
    80004a56:	5a7d                	li	s4,-1
    80004a58:	b7d5                	j	80004a3c <filewrite+0xfa>
    panic("filewrite");
    80004a5a:	00004517          	auipc	a0,0x4
    80004a5e:	d6e50513          	addi	a0,a0,-658 # 800087c8 <syscalls+0x2a8>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	adc080e7          	jalr	-1316(ra) # 8000053e <panic>
    return -1;
    80004a6a:	5a7d                	li	s4,-1
    80004a6c:	bfc1                	j	80004a3c <filewrite+0xfa>
      return -1;
    80004a6e:	5a7d                	li	s4,-1
    80004a70:	b7f1                	j	80004a3c <filewrite+0xfa>
    80004a72:	5a7d                	li	s4,-1
    80004a74:	b7e1                	j	80004a3c <filewrite+0xfa>

0000000080004a76 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a76:	7179                	addi	sp,sp,-48
    80004a78:	f406                	sd	ra,40(sp)
    80004a7a:	f022                	sd	s0,32(sp)
    80004a7c:	ec26                	sd	s1,24(sp)
    80004a7e:	e84a                	sd	s2,16(sp)
    80004a80:	e44e                	sd	s3,8(sp)
    80004a82:	e052                	sd	s4,0(sp)
    80004a84:	1800                	addi	s0,sp,48
    80004a86:	84aa                	mv	s1,a0
    80004a88:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a8a:	0005b023          	sd	zero,0(a1)
    80004a8e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a92:	00000097          	auipc	ra,0x0
    80004a96:	bf8080e7          	jalr	-1032(ra) # 8000468a <filealloc>
    80004a9a:	e088                	sd	a0,0(s1)
    80004a9c:	c551                	beqz	a0,80004b28 <pipealloc+0xb2>
    80004a9e:	00000097          	auipc	ra,0x0
    80004aa2:	bec080e7          	jalr	-1044(ra) # 8000468a <filealloc>
    80004aa6:	00aa3023          	sd	a0,0(s4)
    80004aaa:	c92d                	beqz	a0,80004b1c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	03a080e7          	jalr	58(ra) # 80000ae6 <kalloc>
    80004ab4:	892a                	mv	s2,a0
    80004ab6:	c125                	beqz	a0,80004b16 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ab8:	4985                	li	s3,1
    80004aba:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004abe:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ac2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ac6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004aca:	00004597          	auipc	a1,0x4
    80004ace:	d0e58593          	addi	a1,a1,-754 # 800087d8 <syscalls+0x2b8>
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	074080e7          	jalr	116(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004ada:	609c                	ld	a5,0(s1)
    80004adc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ae0:	609c                	ld	a5,0(s1)
    80004ae2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ae6:	609c                	ld	a5,0(s1)
    80004ae8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004aec:	609c                	ld	a5,0(s1)
    80004aee:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004af2:	000a3783          	ld	a5,0(s4)
    80004af6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004afa:	000a3783          	ld	a5,0(s4)
    80004afe:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b02:	000a3783          	ld	a5,0(s4)
    80004b06:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b0a:	000a3783          	ld	a5,0(s4)
    80004b0e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b12:	4501                	li	a0,0
    80004b14:	a025                	j	80004b3c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b16:	6088                	ld	a0,0(s1)
    80004b18:	e501                	bnez	a0,80004b20 <pipealloc+0xaa>
    80004b1a:	a039                	j	80004b28 <pipealloc+0xb2>
    80004b1c:	6088                	ld	a0,0(s1)
    80004b1e:	c51d                	beqz	a0,80004b4c <pipealloc+0xd6>
    fileclose(*f0);
    80004b20:	00000097          	auipc	ra,0x0
    80004b24:	c26080e7          	jalr	-986(ra) # 80004746 <fileclose>
  if(*f1)
    80004b28:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b2c:	557d                	li	a0,-1
  if(*f1)
    80004b2e:	c799                	beqz	a5,80004b3c <pipealloc+0xc6>
    fileclose(*f1);
    80004b30:	853e                	mv	a0,a5
    80004b32:	00000097          	auipc	ra,0x0
    80004b36:	c14080e7          	jalr	-1004(ra) # 80004746 <fileclose>
  return -1;
    80004b3a:	557d                	li	a0,-1
}
    80004b3c:	70a2                	ld	ra,40(sp)
    80004b3e:	7402                	ld	s0,32(sp)
    80004b40:	64e2                	ld	s1,24(sp)
    80004b42:	6942                	ld	s2,16(sp)
    80004b44:	69a2                	ld	s3,8(sp)
    80004b46:	6a02                	ld	s4,0(sp)
    80004b48:	6145                	addi	sp,sp,48
    80004b4a:	8082                	ret
  return -1;
    80004b4c:	557d                	li	a0,-1
    80004b4e:	b7fd                	j	80004b3c <pipealloc+0xc6>

0000000080004b50 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b50:	1101                	addi	sp,sp,-32
    80004b52:	ec06                	sd	ra,24(sp)
    80004b54:	e822                	sd	s0,16(sp)
    80004b56:	e426                	sd	s1,8(sp)
    80004b58:	e04a                	sd	s2,0(sp)
    80004b5a:	1000                	addi	s0,sp,32
    80004b5c:	84aa                	mv	s1,a0
    80004b5e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	076080e7          	jalr	118(ra) # 80000bd6 <acquire>
  if(writable){
    80004b68:	02090d63          	beqz	s2,80004ba2 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b6c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b70:	21848513          	addi	a0,s1,536
    80004b74:	ffffd097          	auipc	ra,0xffffd
    80004b78:	612080e7          	jalr	1554(ra) # 80002186 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b7c:	2204b783          	ld	a5,544(s1)
    80004b80:	eb95                	bnez	a5,80004bb4 <pipeclose+0x64>
    release(&pi->lock);
    80004b82:	8526                	mv	a0,s1
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	106080e7          	jalr	262(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004b8c:	8526                	mv	a0,s1
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	e5c080e7          	jalr	-420(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004b96:	60e2                	ld	ra,24(sp)
    80004b98:	6442                	ld	s0,16(sp)
    80004b9a:	64a2                	ld	s1,8(sp)
    80004b9c:	6902                	ld	s2,0(sp)
    80004b9e:	6105                	addi	sp,sp,32
    80004ba0:	8082                	ret
    pi->readopen = 0;
    80004ba2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ba6:	21c48513          	addi	a0,s1,540
    80004baa:	ffffd097          	auipc	ra,0xffffd
    80004bae:	5dc080e7          	jalr	1500(ra) # 80002186 <wakeup>
    80004bb2:	b7e9                	j	80004b7c <pipeclose+0x2c>
    release(&pi->lock);
    80004bb4:	8526                	mv	a0,s1
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	0d4080e7          	jalr	212(ra) # 80000c8a <release>
}
    80004bbe:	bfe1                	j	80004b96 <pipeclose+0x46>

0000000080004bc0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bc0:	711d                	addi	sp,sp,-96
    80004bc2:	ec86                	sd	ra,88(sp)
    80004bc4:	e8a2                	sd	s0,80(sp)
    80004bc6:	e4a6                	sd	s1,72(sp)
    80004bc8:	e0ca                	sd	s2,64(sp)
    80004bca:	fc4e                	sd	s3,56(sp)
    80004bcc:	f852                	sd	s4,48(sp)
    80004bce:	f456                	sd	s5,40(sp)
    80004bd0:	f05a                	sd	s6,32(sp)
    80004bd2:	ec5e                	sd	s7,24(sp)
    80004bd4:	e862                	sd	s8,16(sp)
    80004bd6:	1080                	addi	s0,sp,96
    80004bd8:	84aa                	mv	s1,a0
    80004bda:	8aae                	mv	s5,a1
    80004bdc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	e04080e7          	jalr	-508(ra) # 800019e2 <myproc>
    80004be6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004be8:	8526                	mv	a0,s1
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	fec080e7          	jalr	-20(ra) # 80000bd6 <acquire>
  while(i < n){
    80004bf2:	0b405663          	blez	s4,80004c9e <pipewrite+0xde>
  int i = 0;
    80004bf6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bf8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bfa:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bfe:	21c48b93          	addi	s7,s1,540
    80004c02:	a089                	j	80004c44 <pipewrite+0x84>
      release(&pi->lock);
    80004c04:	8526                	mv	a0,s1
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	084080e7          	jalr	132(ra) # 80000c8a <release>
      return -1;
    80004c0e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c10:	854a                	mv	a0,s2
    80004c12:	60e6                	ld	ra,88(sp)
    80004c14:	6446                	ld	s0,80(sp)
    80004c16:	64a6                	ld	s1,72(sp)
    80004c18:	6906                	ld	s2,64(sp)
    80004c1a:	79e2                	ld	s3,56(sp)
    80004c1c:	7a42                	ld	s4,48(sp)
    80004c1e:	7aa2                	ld	s5,40(sp)
    80004c20:	7b02                	ld	s6,32(sp)
    80004c22:	6be2                	ld	s7,24(sp)
    80004c24:	6c42                	ld	s8,16(sp)
    80004c26:	6125                	addi	sp,sp,96
    80004c28:	8082                	ret
      wakeup(&pi->nread);
    80004c2a:	8562                	mv	a0,s8
    80004c2c:	ffffd097          	auipc	ra,0xffffd
    80004c30:	55a080e7          	jalr	1370(ra) # 80002186 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c34:	85a6                	mv	a1,s1
    80004c36:	855e                	mv	a0,s7
    80004c38:	ffffd097          	auipc	ra,0xffffd
    80004c3c:	4ea080e7          	jalr	1258(ra) # 80002122 <sleep>
  while(i < n){
    80004c40:	07495063          	bge	s2,s4,80004ca0 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004c44:	2204a783          	lw	a5,544(s1)
    80004c48:	dfd5                	beqz	a5,80004c04 <pipewrite+0x44>
    80004c4a:	854e                	mv	a0,s3
    80004c4c:	ffffd097          	auipc	ra,0xffffd
    80004c50:	77e080e7          	jalr	1918(ra) # 800023ca <killed>
    80004c54:	f945                	bnez	a0,80004c04 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c56:	2184a783          	lw	a5,536(s1)
    80004c5a:	21c4a703          	lw	a4,540(s1)
    80004c5e:	2007879b          	addiw	a5,a5,512
    80004c62:	fcf704e3          	beq	a4,a5,80004c2a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c66:	4685                	li	a3,1
    80004c68:	01590633          	add	a2,s2,s5
    80004c6c:	faf40593          	addi	a1,s0,-81
    80004c70:	0509b503          	ld	a0,80(s3)
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	ab6080e7          	jalr	-1354(ra) # 8000172a <copyin>
    80004c7c:	03650263          	beq	a0,s6,80004ca0 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c80:	21c4a783          	lw	a5,540(s1)
    80004c84:	0017871b          	addiw	a4,a5,1
    80004c88:	20e4ae23          	sw	a4,540(s1)
    80004c8c:	1ff7f793          	andi	a5,a5,511
    80004c90:	97a6                	add	a5,a5,s1
    80004c92:	faf44703          	lbu	a4,-81(s0)
    80004c96:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c9a:	2905                	addiw	s2,s2,1
    80004c9c:	b755                	j	80004c40 <pipewrite+0x80>
  int i = 0;
    80004c9e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ca0:	21848513          	addi	a0,s1,536
    80004ca4:	ffffd097          	auipc	ra,0xffffd
    80004ca8:	4e2080e7          	jalr	1250(ra) # 80002186 <wakeup>
  release(&pi->lock);
    80004cac:	8526                	mv	a0,s1
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	fdc080e7          	jalr	-36(ra) # 80000c8a <release>
  return i;
    80004cb6:	bfa9                	j	80004c10 <pipewrite+0x50>

0000000080004cb8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cb8:	715d                	addi	sp,sp,-80
    80004cba:	e486                	sd	ra,72(sp)
    80004cbc:	e0a2                	sd	s0,64(sp)
    80004cbe:	fc26                	sd	s1,56(sp)
    80004cc0:	f84a                	sd	s2,48(sp)
    80004cc2:	f44e                	sd	s3,40(sp)
    80004cc4:	f052                	sd	s4,32(sp)
    80004cc6:	ec56                	sd	s5,24(sp)
    80004cc8:	e85a                	sd	s6,16(sp)
    80004cca:	0880                	addi	s0,sp,80
    80004ccc:	84aa                	mv	s1,a0
    80004cce:	892e                	mv	s2,a1
    80004cd0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	d10080e7          	jalr	-752(ra) # 800019e2 <myproc>
    80004cda:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cdc:	8526                	mv	a0,s1
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	ef8080e7          	jalr	-264(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ce6:	2184a703          	lw	a4,536(s1)
    80004cea:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cee:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cf2:	02f71763          	bne	a4,a5,80004d20 <piperead+0x68>
    80004cf6:	2244a783          	lw	a5,548(s1)
    80004cfa:	c39d                	beqz	a5,80004d20 <piperead+0x68>
    if(killed(pr)){
    80004cfc:	8552                	mv	a0,s4
    80004cfe:	ffffd097          	auipc	ra,0xffffd
    80004d02:	6cc080e7          	jalr	1740(ra) # 800023ca <killed>
    80004d06:	e941                	bnez	a0,80004d96 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d08:	85a6                	mv	a1,s1
    80004d0a:	854e                	mv	a0,s3
    80004d0c:	ffffd097          	auipc	ra,0xffffd
    80004d10:	416080e7          	jalr	1046(ra) # 80002122 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d14:	2184a703          	lw	a4,536(s1)
    80004d18:	21c4a783          	lw	a5,540(s1)
    80004d1c:	fcf70de3          	beq	a4,a5,80004cf6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d20:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d22:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d24:	05505363          	blez	s5,80004d6a <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004d28:	2184a783          	lw	a5,536(s1)
    80004d2c:	21c4a703          	lw	a4,540(s1)
    80004d30:	02f70d63          	beq	a4,a5,80004d6a <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d34:	0017871b          	addiw	a4,a5,1
    80004d38:	20e4ac23          	sw	a4,536(s1)
    80004d3c:	1ff7f793          	andi	a5,a5,511
    80004d40:	97a6                	add	a5,a5,s1
    80004d42:	0187c783          	lbu	a5,24(a5)
    80004d46:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d4a:	4685                	li	a3,1
    80004d4c:	fbf40613          	addi	a2,s0,-65
    80004d50:	85ca                	mv	a1,s2
    80004d52:	050a3503          	ld	a0,80(s4)
    80004d56:	ffffd097          	auipc	ra,0xffffd
    80004d5a:	948080e7          	jalr	-1720(ra) # 8000169e <copyout>
    80004d5e:	01650663          	beq	a0,s6,80004d6a <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d62:	2985                	addiw	s3,s3,1
    80004d64:	0905                	addi	s2,s2,1
    80004d66:	fd3a91e3          	bne	s5,s3,80004d28 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d6a:	21c48513          	addi	a0,s1,540
    80004d6e:	ffffd097          	auipc	ra,0xffffd
    80004d72:	418080e7          	jalr	1048(ra) # 80002186 <wakeup>
  release(&pi->lock);
    80004d76:	8526                	mv	a0,s1
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	f12080e7          	jalr	-238(ra) # 80000c8a <release>
  return i;
}
    80004d80:	854e                	mv	a0,s3
    80004d82:	60a6                	ld	ra,72(sp)
    80004d84:	6406                	ld	s0,64(sp)
    80004d86:	74e2                	ld	s1,56(sp)
    80004d88:	7942                	ld	s2,48(sp)
    80004d8a:	79a2                	ld	s3,40(sp)
    80004d8c:	7a02                	ld	s4,32(sp)
    80004d8e:	6ae2                	ld	s5,24(sp)
    80004d90:	6b42                	ld	s6,16(sp)
    80004d92:	6161                	addi	sp,sp,80
    80004d94:	8082                	ret
      release(&pi->lock);
    80004d96:	8526                	mv	a0,s1
    80004d98:	ffffc097          	auipc	ra,0xffffc
    80004d9c:	ef2080e7          	jalr	-270(ra) # 80000c8a <release>
      return -1;
    80004da0:	59fd                	li	s3,-1
    80004da2:	bff9                	j	80004d80 <piperead+0xc8>

0000000080004da4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004da4:	1141                	addi	sp,sp,-16
    80004da6:	e422                	sd	s0,8(sp)
    80004da8:	0800                	addi	s0,sp,16
    80004daa:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004dac:	8905                	andi	a0,a0,1
    80004dae:	c111                	beqz	a0,80004db2 <flags2perm+0xe>
      perm = PTE_X;
    80004db0:	4521                	li	a0,8
    if(flags & 0x2)
    80004db2:	8b89                	andi	a5,a5,2
    80004db4:	c399                	beqz	a5,80004dba <flags2perm+0x16>
      perm |= PTE_W;
    80004db6:	00456513          	ori	a0,a0,4
    return perm;
}
    80004dba:	6422                	ld	s0,8(sp)
    80004dbc:	0141                	addi	sp,sp,16
    80004dbe:	8082                	ret

0000000080004dc0 <exec>:

int
exec(char *path, char **argv)
{
    80004dc0:	de010113          	addi	sp,sp,-544
    80004dc4:	20113c23          	sd	ra,536(sp)
    80004dc8:	20813823          	sd	s0,528(sp)
    80004dcc:	20913423          	sd	s1,520(sp)
    80004dd0:	21213023          	sd	s2,512(sp)
    80004dd4:	ffce                	sd	s3,504(sp)
    80004dd6:	fbd2                	sd	s4,496(sp)
    80004dd8:	f7d6                	sd	s5,488(sp)
    80004dda:	f3da                	sd	s6,480(sp)
    80004ddc:	efde                	sd	s7,472(sp)
    80004dde:	ebe2                	sd	s8,464(sp)
    80004de0:	e7e6                	sd	s9,456(sp)
    80004de2:	e3ea                	sd	s10,448(sp)
    80004de4:	ff6e                	sd	s11,440(sp)
    80004de6:	1400                	addi	s0,sp,544
    80004de8:	892a                	mv	s2,a0
    80004dea:	dea43423          	sd	a0,-536(s0)
    80004dee:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004df2:	ffffd097          	auipc	ra,0xffffd
    80004df6:	bf0080e7          	jalr	-1040(ra) # 800019e2 <myproc>
    80004dfa:	84aa                	mv	s1,a0

  begin_op();
    80004dfc:	fffff097          	auipc	ra,0xfffff
    80004e00:	47e080e7          	jalr	1150(ra) # 8000427a <begin_op>

  if((ip = namei(path)) == 0){
    80004e04:	854a                	mv	a0,s2
    80004e06:	fffff097          	auipc	ra,0xfffff
    80004e0a:	258080e7          	jalr	600(ra) # 8000405e <namei>
    80004e0e:	c93d                	beqz	a0,80004e84 <exec+0xc4>
    80004e10:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	aa6080e7          	jalr	-1370(ra) # 800038b8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e1a:	04000713          	li	a4,64
    80004e1e:	4681                	li	a3,0
    80004e20:	e5040613          	addi	a2,s0,-432
    80004e24:	4581                	li	a1,0
    80004e26:	8556                	mv	a0,s5
    80004e28:	fffff097          	auipc	ra,0xfffff
    80004e2c:	d44080e7          	jalr	-700(ra) # 80003b6c <readi>
    80004e30:	04000793          	li	a5,64
    80004e34:	00f51a63          	bne	a0,a5,80004e48 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e38:	e5042703          	lw	a4,-432(s0)
    80004e3c:	464c47b7          	lui	a5,0x464c4
    80004e40:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e44:	04f70663          	beq	a4,a5,80004e90 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e48:	8556                	mv	a0,s5
    80004e4a:	fffff097          	auipc	ra,0xfffff
    80004e4e:	cd0080e7          	jalr	-816(ra) # 80003b1a <iunlockput>
    end_op();
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	4a8080e7          	jalr	1192(ra) # 800042fa <end_op>
  }
  return -1;
    80004e5a:	557d                	li	a0,-1
}
    80004e5c:	21813083          	ld	ra,536(sp)
    80004e60:	21013403          	ld	s0,528(sp)
    80004e64:	20813483          	ld	s1,520(sp)
    80004e68:	20013903          	ld	s2,512(sp)
    80004e6c:	79fe                	ld	s3,504(sp)
    80004e6e:	7a5e                	ld	s4,496(sp)
    80004e70:	7abe                	ld	s5,488(sp)
    80004e72:	7b1e                	ld	s6,480(sp)
    80004e74:	6bfe                	ld	s7,472(sp)
    80004e76:	6c5e                	ld	s8,464(sp)
    80004e78:	6cbe                	ld	s9,456(sp)
    80004e7a:	6d1e                	ld	s10,448(sp)
    80004e7c:	7dfa                	ld	s11,440(sp)
    80004e7e:	22010113          	addi	sp,sp,544
    80004e82:	8082                	ret
    end_op();
    80004e84:	fffff097          	auipc	ra,0xfffff
    80004e88:	476080e7          	jalr	1142(ra) # 800042fa <end_op>
    return -1;
    80004e8c:	557d                	li	a0,-1
    80004e8e:	b7f9                	j	80004e5c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e90:	8526                	mv	a0,s1
    80004e92:	ffffd097          	auipc	ra,0xffffd
    80004e96:	c14080e7          	jalr	-1004(ra) # 80001aa6 <proc_pagetable>
    80004e9a:	8b2a                	mv	s6,a0
    80004e9c:	d555                	beqz	a0,80004e48 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e9e:	e7042783          	lw	a5,-400(s0)
    80004ea2:	e8845703          	lhu	a4,-376(s0)
    80004ea6:	c735                	beqz	a4,80004f12 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ea8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eaa:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004eae:	6a05                	lui	s4,0x1
    80004eb0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004eb4:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004eb8:	6d85                	lui	s11,0x1
    80004eba:	7d7d                	lui	s10,0xfffff
    80004ebc:	a481                	j	800050fc <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ebe:	00004517          	auipc	a0,0x4
    80004ec2:	92250513          	addi	a0,a0,-1758 # 800087e0 <syscalls+0x2c0>
    80004ec6:	ffffb097          	auipc	ra,0xffffb
    80004eca:	678080e7          	jalr	1656(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ece:	874a                	mv	a4,s2
    80004ed0:	009c86bb          	addw	a3,s9,s1
    80004ed4:	4581                	li	a1,0
    80004ed6:	8556                	mv	a0,s5
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	c94080e7          	jalr	-876(ra) # 80003b6c <readi>
    80004ee0:	2501                	sext.w	a0,a0
    80004ee2:	1aa91a63          	bne	s2,a0,80005096 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ee6:	009d84bb          	addw	s1,s11,s1
    80004eea:	013d09bb          	addw	s3,s10,s3
    80004eee:	1f74f763          	bgeu	s1,s7,800050dc <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004ef2:	02049593          	slli	a1,s1,0x20
    80004ef6:	9181                	srli	a1,a1,0x20
    80004ef8:	95e2                	add	a1,a1,s8
    80004efa:	855a                	mv	a0,s6
    80004efc:	ffffc097          	auipc	ra,0xffffc
    80004f00:	180080e7          	jalr	384(ra) # 8000107c <walkaddr>
    80004f04:	862a                	mv	a2,a0
    if(pa == 0)
    80004f06:	dd45                	beqz	a0,80004ebe <exec+0xfe>
      n = PGSIZE;
    80004f08:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f0a:	fd49f2e3          	bgeu	s3,s4,80004ece <exec+0x10e>
      n = sz - i;
    80004f0e:	894e                	mv	s2,s3
    80004f10:	bf7d                	j	80004ece <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f12:	4901                	li	s2,0
  iunlockput(ip);
    80004f14:	8556                	mv	a0,s5
    80004f16:	fffff097          	auipc	ra,0xfffff
    80004f1a:	c04080e7          	jalr	-1020(ra) # 80003b1a <iunlockput>
  end_op();
    80004f1e:	fffff097          	auipc	ra,0xfffff
    80004f22:	3dc080e7          	jalr	988(ra) # 800042fa <end_op>
  p = myproc();
    80004f26:	ffffd097          	auipc	ra,0xffffd
    80004f2a:	abc080e7          	jalr	-1348(ra) # 800019e2 <myproc>
    80004f2e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f30:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f34:	6785                	lui	a5,0x1
    80004f36:	17fd                	addi	a5,a5,-1
    80004f38:	993e                	add	s2,s2,a5
    80004f3a:	77fd                	lui	a5,0xfffff
    80004f3c:	00f977b3          	and	a5,s2,a5
    80004f40:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f44:	4691                	li	a3,4
    80004f46:	6609                	lui	a2,0x2
    80004f48:	963e                	add	a2,a2,a5
    80004f4a:	85be                	mv	a1,a5
    80004f4c:	855a                	mv	a0,s6
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	4f8080e7          	jalr	1272(ra) # 80001446 <uvmalloc>
    80004f56:	8c2a                	mv	s8,a0
  ip = 0;
    80004f58:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f5a:	12050e63          	beqz	a0,80005096 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f5e:	75f9                	lui	a1,0xffffe
    80004f60:	95aa                	add	a1,a1,a0
    80004f62:	855a                	mv	a0,s6
    80004f64:	ffffc097          	auipc	ra,0xffffc
    80004f68:	708080e7          	jalr	1800(ra) # 8000166c <uvmclear>
  stackbase = sp - PGSIZE;
    80004f6c:	7afd                	lui	s5,0xfffff
    80004f6e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f70:	df043783          	ld	a5,-528(s0)
    80004f74:	6388                	ld	a0,0(a5)
    80004f76:	c925                	beqz	a0,80004fe6 <exec+0x226>
    80004f78:	e9040993          	addi	s3,s0,-368
    80004f7c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f80:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f82:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	eca080e7          	jalr	-310(ra) # 80000e4e <strlen>
    80004f8c:	0015079b          	addiw	a5,a0,1
    80004f90:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f94:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f98:	13596663          	bltu	s2,s5,800050c4 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f9c:	df043d83          	ld	s11,-528(s0)
    80004fa0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004fa4:	8552                	mv	a0,s4
    80004fa6:	ffffc097          	auipc	ra,0xffffc
    80004faa:	ea8080e7          	jalr	-344(ra) # 80000e4e <strlen>
    80004fae:	0015069b          	addiw	a3,a0,1
    80004fb2:	8652                	mv	a2,s4
    80004fb4:	85ca                	mv	a1,s2
    80004fb6:	855a                	mv	a0,s6
    80004fb8:	ffffc097          	auipc	ra,0xffffc
    80004fbc:	6e6080e7          	jalr	1766(ra) # 8000169e <copyout>
    80004fc0:	10054663          	bltz	a0,800050cc <exec+0x30c>
    ustack[argc] = sp;
    80004fc4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fc8:	0485                	addi	s1,s1,1
    80004fca:	008d8793          	addi	a5,s11,8
    80004fce:	def43823          	sd	a5,-528(s0)
    80004fd2:	008db503          	ld	a0,8(s11)
    80004fd6:	c911                	beqz	a0,80004fea <exec+0x22a>
    if(argc >= MAXARG)
    80004fd8:	09a1                	addi	s3,s3,8
    80004fda:	fb3c95e3          	bne	s9,s3,80004f84 <exec+0x1c4>
  sz = sz1;
    80004fde:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fe2:	4a81                	li	s5,0
    80004fe4:	a84d                	j	80005096 <exec+0x2d6>
  sp = sz;
    80004fe6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fe8:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fea:	00349793          	slli	a5,s1,0x3
    80004fee:	f9040713          	addi	a4,s0,-112
    80004ff2:	97ba                	add	a5,a5,a4
    80004ff4:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd9528>
  sp -= (argc+1) * sizeof(uint64);
    80004ff8:	00148693          	addi	a3,s1,1
    80004ffc:	068e                	slli	a3,a3,0x3
    80004ffe:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005002:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005006:	01597663          	bgeu	s2,s5,80005012 <exec+0x252>
  sz = sz1;
    8000500a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000500e:	4a81                	li	s5,0
    80005010:	a059                	j	80005096 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005012:	e9040613          	addi	a2,s0,-368
    80005016:	85ca                	mv	a1,s2
    80005018:	855a                	mv	a0,s6
    8000501a:	ffffc097          	auipc	ra,0xffffc
    8000501e:	684080e7          	jalr	1668(ra) # 8000169e <copyout>
    80005022:	0a054963          	bltz	a0,800050d4 <exec+0x314>
  p->trapframe->a1 = sp;
    80005026:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000502a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000502e:	de843783          	ld	a5,-536(s0)
    80005032:	0007c703          	lbu	a4,0(a5)
    80005036:	cf11                	beqz	a4,80005052 <exec+0x292>
    80005038:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000503a:	02f00693          	li	a3,47
    8000503e:	a039                	j	8000504c <exec+0x28c>
      last = s+1;
    80005040:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005044:	0785                	addi	a5,a5,1
    80005046:	fff7c703          	lbu	a4,-1(a5)
    8000504a:	c701                	beqz	a4,80005052 <exec+0x292>
    if(*s == '/')
    8000504c:	fed71ce3          	bne	a4,a3,80005044 <exec+0x284>
    80005050:	bfc5                	j	80005040 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005052:	4641                	li	a2,16
    80005054:	de843583          	ld	a1,-536(s0)
    80005058:	158b8513          	addi	a0,s7,344
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	dc0080e7          	jalr	-576(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005064:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005068:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000506c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005070:	058bb783          	ld	a5,88(s7)
    80005074:	e6843703          	ld	a4,-408(s0)
    80005078:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000507a:	058bb783          	ld	a5,88(s7)
    8000507e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005082:	85ea                	mv	a1,s10
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	abe080e7          	jalr	-1346(ra) # 80001b42 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000508c:	0004851b          	sext.w	a0,s1
    80005090:	b3f1                	j	80004e5c <exec+0x9c>
    80005092:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005096:	df843583          	ld	a1,-520(s0)
    8000509a:	855a                	mv	a0,s6
    8000509c:	ffffd097          	auipc	ra,0xffffd
    800050a0:	aa6080e7          	jalr	-1370(ra) # 80001b42 <proc_freepagetable>
  if(ip){
    800050a4:	da0a92e3          	bnez	s5,80004e48 <exec+0x88>
  return -1;
    800050a8:	557d                	li	a0,-1
    800050aa:	bb4d                	j	80004e5c <exec+0x9c>
    800050ac:	df243c23          	sd	s2,-520(s0)
    800050b0:	b7dd                	j	80005096 <exec+0x2d6>
    800050b2:	df243c23          	sd	s2,-520(s0)
    800050b6:	b7c5                	j	80005096 <exec+0x2d6>
    800050b8:	df243c23          	sd	s2,-520(s0)
    800050bc:	bfe9                	j	80005096 <exec+0x2d6>
    800050be:	df243c23          	sd	s2,-520(s0)
    800050c2:	bfd1                	j	80005096 <exec+0x2d6>
  sz = sz1;
    800050c4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050c8:	4a81                	li	s5,0
    800050ca:	b7f1                	j	80005096 <exec+0x2d6>
  sz = sz1;
    800050cc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050d0:	4a81                	li	s5,0
    800050d2:	b7d1                	j	80005096 <exec+0x2d6>
  sz = sz1;
    800050d4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050d8:	4a81                	li	s5,0
    800050da:	bf75                	j	80005096 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050dc:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050e0:	e0843783          	ld	a5,-504(s0)
    800050e4:	0017869b          	addiw	a3,a5,1
    800050e8:	e0d43423          	sd	a3,-504(s0)
    800050ec:	e0043783          	ld	a5,-512(s0)
    800050f0:	0387879b          	addiw	a5,a5,56
    800050f4:	e8845703          	lhu	a4,-376(s0)
    800050f8:	e0e6dee3          	bge	a3,a4,80004f14 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050fc:	2781                	sext.w	a5,a5
    800050fe:	e0f43023          	sd	a5,-512(s0)
    80005102:	03800713          	li	a4,56
    80005106:	86be                	mv	a3,a5
    80005108:	e1840613          	addi	a2,s0,-488
    8000510c:	4581                	li	a1,0
    8000510e:	8556                	mv	a0,s5
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	a5c080e7          	jalr	-1444(ra) # 80003b6c <readi>
    80005118:	03800793          	li	a5,56
    8000511c:	f6f51be3          	bne	a0,a5,80005092 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005120:	e1842783          	lw	a5,-488(s0)
    80005124:	4705                	li	a4,1
    80005126:	fae79de3          	bne	a5,a4,800050e0 <exec+0x320>
    if(ph.memsz < ph.filesz)
    8000512a:	e4043483          	ld	s1,-448(s0)
    8000512e:	e3843783          	ld	a5,-456(s0)
    80005132:	f6f4ede3          	bltu	s1,a5,800050ac <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005136:	e2843783          	ld	a5,-472(s0)
    8000513a:	94be                	add	s1,s1,a5
    8000513c:	f6f4ebe3          	bltu	s1,a5,800050b2 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005140:	de043703          	ld	a4,-544(s0)
    80005144:	8ff9                	and	a5,a5,a4
    80005146:	fbad                	bnez	a5,800050b8 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005148:	e1c42503          	lw	a0,-484(s0)
    8000514c:	00000097          	auipc	ra,0x0
    80005150:	c58080e7          	jalr	-936(ra) # 80004da4 <flags2perm>
    80005154:	86aa                	mv	a3,a0
    80005156:	8626                	mv	a2,s1
    80005158:	85ca                	mv	a1,s2
    8000515a:	855a                	mv	a0,s6
    8000515c:	ffffc097          	auipc	ra,0xffffc
    80005160:	2ea080e7          	jalr	746(ra) # 80001446 <uvmalloc>
    80005164:	dea43c23          	sd	a0,-520(s0)
    80005168:	d939                	beqz	a0,800050be <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000516a:	e2843c03          	ld	s8,-472(s0)
    8000516e:	e2042c83          	lw	s9,-480(s0)
    80005172:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005176:	f60b83e3          	beqz	s7,800050dc <exec+0x31c>
    8000517a:	89de                	mv	s3,s7
    8000517c:	4481                	li	s1,0
    8000517e:	bb95                	j	80004ef2 <exec+0x132>

0000000080005180 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005180:	7179                	addi	sp,sp,-48
    80005182:	f406                	sd	ra,40(sp)
    80005184:	f022                	sd	s0,32(sp)
    80005186:	ec26                	sd	s1,24(sp)
    80005188:	e84a                	sd	s2,16(sp)
    8000518a:	1800                	addi	s0,sp,48
    8000518c:	892e                	mv	s2,a1
    8000518e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005190:	fdc40593          	addi	a1,s0,-36
    80005194:	ffffe097          	auipc	ra,0xffffe
    80005198:	b62080e7          	jalr	-1182(ra) # 80002cf6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000519c:	fdc42703          	lw	a4,-36(s0)
    800051a0:	47bd                	li	a5,15
    800051a2:	02e7eb63          	bltu	a5,a4,800051d8 <argfd+0x58>
    800051a6:	ffffd097          	auipc	ra,0xffffd
    800051aa:	83c080e7          	jalr	-1988(ra) # 800019e2 <myproc>
    800051ae:	fdc42703          	lw	a4,-36(s0)
    800051b2:	01a70793          	addi	a5,a4,26
    800051b6:	078e                	slli	a5,a5,0x3
    800051b8:	953e                	add	a0,a0,a5
    800051ba:	611c                	ld	a5,0(a0)
    800051bc:	c385                	beqz	a5,800051dc <argfd+0x5c>
    return -1;
  if(pfd)
    800051be:	00090463          	beqz	s2,800051c6 <argfd+0x46>
    *pfd = fd;
    800051c2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051c6:	4501                	li	a0,0
  if(pf)
    800051c8:	c091                	beqz	s1,800051cc <argfd+0x4c>
    *pf = f;
    800051ca:	e09c                	sd	a5,0(s1)
}
    800051cc:	70a2                	ld	ra,40(sp)
    800051ce:	7402                	ld	s0,32(sp)
    800051d0:	64e2                	ld	s1,24(sp)
    800051d2:	6942                	ld	s2,16(sp)
    800051d4:	6145                	addi	sp,sp,48
    800051d6:	8082                	ret
    return -1;
    800051d8:	557d                	li	a0,-1
    800051da:	bfcd                	j	800051cc <argfd+0x4c>
    800051dc:	557d                	li	a0,-1
    800051de:	b7fd                	j	800051cc <argfd+0x4c>

00000000800051e0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051e0:	1101                	addi	sp,sp,-32
    800051e2:	ec06                	sd	ra,24(sp)
    800051e4:	e822                	sd	s0,16(sp)
    800051e6:	e426                	sd	s1,8(sp)
    800051e8:	1000                	addi	s0,sp,32
    800051ea:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	7f6080e7          	jalr	2038(ra) # 800019e2 <myproc>
    800051f4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051f6:	0d050793          	addi	a5,a0,208
    800051fa:	4501                	li	a0,0
    800051fc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051fe:	6398                	ld	a4,0(a5)
    80005200:	cb19                	beqz	a4,80005216 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005202:	2505                	addiw	a0,a0,1
    80005204:	07a1                	addi	a5,a5,8
    80005206:	fed51ce3          	bne	a0,a3,800051fe <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000520a:	557d                	li	a0,-1
}
    8000520c:	60e2                	ld	ra,24(sp)
    8000520e:	6442                	ld	s0,16(sp)
    80005210:	64a2                	ld	s1,8(sp)
    80005212:	6105                	addi	sp,sp,32
    80005214:	8082                	ret
      p->ofile[fd] = f;
    80005216:	01a50793          	addi	a5,a0,26
    8000521a:	078e                	slli	a5,a5,0x3
    8000521c:	963e                	add	a2,a2,a5
    8000521e:	e204                	sd	s1,0(a2)
      return fd;
    80005220:	b7f5                	j	8000520c <fdalloc+0x2c>

0000000080005222 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005222:	715d                	addi	sp,sp,-80
    80005224:	e486                	sd	ra,72(sp)
    80005226:	e0a2                	sd	s0,64(sp)
    80005228:	fc26                	sd	s1,56(sp)
    8000522a:	f84a                	sd	s2,48(sp)
    8000522c:	f44e                	sd	s3,40(sp)
    8000522e:	f052                	sd	s4,32(sp)
    80005230:	ec56                	sd	s5,24(sp)
    80005232:	e85a                	sd	s6,16(sp)
    80005234:	0880                	addi	s0,sp,80
    80005236:	8b2e                	mv	s6,a1
    80005238:	89b2                	mv	s3,a2
    8000523a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000523c:	fb040593          	addi	a1,s0,-80
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	e3c080e7          	jalr	-452(ra) # 8000407c <nameiparent>
    80005248:	84aa                	mv	s1,a0
    8000524a:	14050f63          	beqz	a0,800053a8 <create+0x186>
    return 0;

  ilock(dp);
    8000524e:	ffffe097          	auipc	ra,0xffffe
    80005252:	66a080e7          	jalr	1642(ra) # 800038b8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005256:	4601                	li	a2,0
    80005258:	fb040593          	addi	a1,s0,-80
    8000525c:	8526                	mv	a0,s1
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	b3e080e7          	jalr	-1218(ra) # 80003d9c <dirlookup>
    80005266:	8aaa                	mv	s5,a0
    80005268:	c931                	beqz	a0,800052bc <create+0x9a>
    iunlockput(dp);
    8000526a:	8526                	mv	a0,s1
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	8ae080e7          	jalr	-1874(ra) # 80003b1a <iunlockput>
    ilock(ip);
    80005274:	8556                	mv	a0,s5
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	642080e7          	jalr	1602(ra) # 800038b8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000527e:	000b059b          	sext.w	a1,s6
    80005282:	4789                	li	a5,2
    80005284:	02f59563          	bne	a1,a5,800052ae <create+0x8c>
    80005288:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd966c>
    8000528c:	37f9                	addiw	a5,a5,-2
    8000528e:	17c2                	slli	a5,a5,0x30
    80005290:	93c1                	srli	a5,a5,0x30
    80005292:	4705                	li	a4,1
    80005294:	00f76d63          	bltu	a4,a5,800052ae <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005298:	8556                	mv	a0,s5
    8000529a:	60a6                	ld	ra,72(sp)
    8000529c:	6406                	ld	s0,64(sp)
    8000529e:	74e2                	ld	s1,56(sp)
    800052a0:	7942                	ld	s2,48(sp)
    800052a2:	79a2                	ld	s3,40(sp)
    800052a4:	7a02                	ld	s4,32(sp)
    800052a6:	6ae2                	ld	s5,24(sp)
    800052a8:	6b42                	ld	s6,16(sp)
    800052aa:	6161                	addi	sp,sp,80
    800052ac:	8082                	ret
    iunlockput(ip);
    800052ae:	8556                	mv	a0,s5
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	86a080e7          	jalr	-1942(ra) # 80003b1a <iunlockput>
    return 0;
    800052b8:	4a81                	li	s5,0
    800052ba:	bff9                	j	80005298 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800052bc:	85da                	mv	a1,s6
    800052be:	4088                	lw	a0,0(s1)
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	45c080e7          	jalr	1116(ra) # 8000371c <ialloc>
    800052c8:	8a2a                	mv	s4,a0
    800052ca:	c539                	beqz	a0,80005318 <create+0xf6>
  ilock(ip);
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	5ec080e7          	jalr	1516(ra) # 800038b8 <ilock>
  ip->major = major;
    800052d4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800052d8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800052dc:	4905                	li	s2,1
    800052de:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800052e2:	8552                	mv	a0,s4
    800052e4:	ffffe097          	auipc	ra,0xffffe
    800052e8:	50a080e7          	jalr	1290(ra) # 800037ee <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052ec:	000b059b          	sext.w	a1,s6
    800052f0:	03258b63          	beq	a1,s2,80005326 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800052f4:	004a2603          	lw	a2,4(s4)
    800052f8:	fb040593          	addi	a1,s0,-80
    800052fc:	8526                	mv	a0,s1
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	cae080e7          	jalr	-850(ra) # 80003fac <dirlink>
    80005306:	06054f63          	bltz	a0,80005384 <create+0x162>
  iunlockput(dp);
    8000530a:	8526                	mv	a0,s1
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	80e080e7          	jalr	-2034(ra) # 80003b1a <iunlockput>
  return ip;
    80005314:	8ad2                	mv	s5,s4
    80005316:	b749                	j	80005298 <create+0x76>
    iunlockput(dp);
    80005318:	8526                	mv	a0,s1
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	800080e7          	jalr	-2048(ra) # 80003b1a <iunlockput>
    return 0;
    80005322:	8ad2                	mv	s5,s4
    80005324:	bf95                	j	80005298 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005326:	004a2603          	lw	a2,4(s4)
    8000532a:	00003597          	auipc	a1,0x3
    8000532e:	4d658593          	addi	a1,a1,1238 # 80008800 <syscalls+0x2e0>
    80005332:	8552                	mv	a0,s4
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	c78080e7          	jalr	-904(ra) # 80003fac <dirlink>
    8000533c:	04054463          	bltz	a0,80005384 <create+0x162>
    80005340:	40d0                	lw	a2,4(s1)
    80005342:	00003597          	auipc	a1,0x3
    80005346:	4c658593          	addi	a1,a1,1222 # 80008808 <syscalls+0x2e8>
    8000534a:	8552                	mv	a0,s4
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	c60080e7          	jalr	-928(ra) # 80003fac <dirlink>
    80005354:	02054863          	bltz	a0,80005384 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005358:	004a2603          	lw	a2,4(s4)
    8000535c:	fb040593          	addi	a1,s0,-80
    80005360:	8526                	mv	a0,s1
    80005362:	fffff097          	auipc	ra,0xfffff
    80005366:	c4a080e7          	jalr	-950(ra) # 80003fac <dirlink>
    8000536a:	00054d63          	bltz	a0,80005384 <create+0x162>
    dp->nlink++;  // for ".."
    8000536e:	04a4d783          	lhu	a5,74(s1)
    80005372:	2785                	addiw	a5,a5,1
    80005374:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005378:	8526                	mv	a0,s1
    8000537a:	ffffe097          	auipc	ra,0xffffe
    8000537e:	474080e7          	jalr	1140(ra) # 800037ee <iupdate>
    80005382:	b761                	j	8000530a <create+0xe8>
  ip->nlink = 0;
    80005384:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005388:	8552                	mv	a0,s4
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	464080e7          	jalr	1124(ra) # 800037ee <iupdate>
  iunlockput(ip);
    80005392:	8552                	mv	a0,s4
    80005394:	ffffe097          	auipc	ra,0xffffe
    80005398:	786080e7          	jalr	1926(ra) # 80003b1a <iunlockput>
  iunlockput(dp);
    8000539c:	8526                	mv	a0,s1
    8000539e:	ffffe097          	auipc	ra,0xffffe
    800053a2:	77c080e7          	jalr	1916(ra) # 80003b1a <iunlockput>
  return 0;
    800053a6:	bdcd                	j	80005298 <create+0x76>
    return 0;
    800053a8:	8aaa                	mv	s5,a0
    800053aa:	b5fd                	j	80005298 <create+0x76>

00000000800053ac <sys_dup>:
{
    800053ac:	7179                	addi	sp,sp,-48
    800053ae:	f406                	sd	ra,40(sp)
    800053b0:	f022                	sd	s0,32(sp)
    800053b2:	ec26                	sd	s1,24(sp)
    800053b4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053b6:	fd840613          	addi	a2,s0,-40
    800053ba:	4581                	li	a1,0
    800053bc:	4501                	li	a0,0
    800053be:	00000097          	auipc	ra,0x0
    800053c2:	dc2080e7          	jalr	-574(ra) # 80005180 <argfd>
    return -1;
    800053c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053c8:	02054363          	bltz	a0,800053ee <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053cc:	fd843503          	ld	a0,-40(s0)
    800053d0:	00000097          	auipc	ra,0x0
    800053d4:	e10080e7          	jalr	-496(ra) # 800051e0 <fdalloc>
    800053d8:	84aa                	mv	s1,a0
    return -1;
    800053da:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053dc:	00054963          	bltz	a0,800053ee <sys_dup+0x42>
  filedup(f);
    800053e0:	fd843503          	ld	a0,-40(s0)
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	310080e7          	jalr	784(ra) # 800046f4 <filedup>
  return fd;
    800053ec:	87a6                	mv	a5,s1
}
    800053ee:	853e                	mv	a0,a5
    800053f0:	70a2                	ld	ra,40(sp)
    800053f2:	7402                	ld	s0,32(sp)
    800053f4:	64e2                	ld	s1,24(sp)
    800053f6:	6145                	addi	sp,sp,48
    800053f8:	8082                	ret

00000000800053fa <sys_read>:
{
    800053fa:	7179                	addi	sp,sp,-48
    800053fc:	f406                	sd	ra,40(sp)
    800053fe:	f022                	sd	s0,32(sp)
    80005400:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005402:	fd840593          	addi	a1,s0,-40
    80005406:	4505                	li	a0,1
    80005408:	ffffe097          	auipc	ra,0xffffe
    8000540c:	90e080e7          	jalr	-1778(ra) # 80002d16 <argaddr>
  argint(2, &n);
    80005410:	fe440593          	addi	a1,s0,-28
    80005414:	4509                	li	a0,2
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	8e0080e7          	jalr	-1824(ra) # 80002cf6 <argint>
  if(argfd(0, 0, &f) < 0)
    8000541e:	fe840613          	addi	a2,s0,-24
    80005422:	4581                	li	a1,0
    80005424:	4501                	li	a0,0
    80005426:	00000097          	auipc	ra,0x0
    8000542a:	d5a080e7          	jalr	-678(ra) # 80005180 <argfd>
    8000542e:	87aa                	mv	a5,a0
    return -1;
    80005430:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005432:	0007cc63          	bltz	a5,8000544a <sys_read+0x50>
  return fileread(f, p, n);
    80005436:	fe442603          	lw	a2,-28(s0)
    8000543a:	fd843583          	ld	a1,-40(s0)
    8000543e:	fe843503          	ld	a0,-24(s0)
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	43e080e7          	jalr	1086(ra) # 80004880 <fileread>
}
    8000544a:	70a2                	ld	ra,40(sp)
    8000544c:	7402                	ld	s0,32(sp)
    8000544e:	6145                	addi	sp,sp,48
    80005450:	8082                	ret

0000000080005452 <sys_write>:
{
    80005452:	7179                	addi	sp,sp,-48
    80005454:	f406                	sd	ra,40(sp)
    80005456:	f022                	sd	s0,32(sp)
    80005458:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000545a:	fd840593          	addi	a1,s0,-40
    8000545e:	4505                	li	a0,1
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	8b6080e7          	jalr	-1866(ra) # 80002d16 <argaddr>
  argint(2, &n);
    80005468:	fe440593          	addi	a1,s0,-28
    8000546c:	4509                	li	a0,2
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	888080e7          	jalr	-1912(ra) # 80002cf6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005476:	fe840613          	addi	a2,s0,-24
    8000547a:	4581                	li	a1,0
    8000547c:	4501                	li	a0,0
    8000547e:	00000097          	auipc	ra,0x0
    80005482:	d02080e7          	jalr	-766(ra) # 80005180 <argfd>
    80005486:	87aa                	mv	a5,a0
    return -1;
    80005488:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000548a:	0007cc63          	bltz	a5,800054a2 <sys_write+0x50>
  return filewrite(f, p, n);
    8000548e:	fe442603          	lw	a2,-28(s0)
    80005492:	fd843583          	ld	a1,-40(s0)
    80005496:	fe843503          	ld	a0,-24(s0)
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	4a8080e7          	jalr	1192(ra) # 80004942 <filewrite>
}
    800054a2:	70a2                	ld	ra,40(sp)
    800054a4:	7402                	ld	s0,32(sp)
    800054a6:	6145                	addi	sp,sp,48
    800054a8:	8082                	ret

00000000800054aa <sys_close>:
{
    800054aa:	1101                	addi	sp,sp,-32
    800054ac:	ec06                	sd	ra,24(sp)
    800054ae:	e822                	sd	s0,16(sp)
    800054b0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054b2:	fe040613          	addi	a2,s0,-32
    800054b6:	fec40593          	addi	a1,s0,-20
    800054ba:	4501                	li	a0,0
    800054bc:	00000097          	auipc	ra,0x0
    800054c0:	cc4080e7          	jalr	-828(ra) # 80005180 <argfd>
    return -1;
    800054c4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054c6:	02054463          	bltz	a0,800054ee <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054ca:	ffffc097          	auipc	ra,0xffffc
    800054ce:	518080e7          	jalr	1304(ra) # 800019e2 <myproc>
    800054d2:	fec42783          	lw	a5,-20(s0)
    800054d6:	07e9                	addi	a5,a5,26
    800054d8:	078e                	slli	a5,a5,0x3
    800054da:	97aa                	add	a5,a5,a0
    800054dc:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054e0:	fe043503          	ld	a0,-32(s0)
    800054e4:	fffff097          	auipc	ra,0xfffff
    800054e8:	262080e7          	jalr	610(ra) # 80004746 <fileclose>
  return 0;
    800054ec:	4781                	li	a5,0
}
    800054ee:	853e                	mv	a0,a5
    800054f0:	60e2                	ld	ra,24(sp)
    800054f2:	6442                	ld	s0,16(sp)
    800054f4:	6105                	addi	sp,sp,32
    800054f6:	8082                	ret

00000000800054f8 <sys_fstat>:
{
    800054f8:	1101                	addi	sp,sp,-32
    800054fa:	ec06                	sd	ra,24(sp)
    800054fc:	e822                	sd	s0,16(sp)
    800054fe:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005500:	fe040593          	addi	a1,s0,-32
    80005504:	4505                	li	a0,1
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	810080e7          	jalr	-2032(ra) # 80002d16 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000550e:	fe840613          	addi	a2,s0,-24
    80005512:	4581                	li	a1,0
    80005514:	4501                	li	a0,0
    80005516:	00000097          	auipc	ra,0x0
    8000551a:	c6a080e7          	jalr	-918(ra) # 80005180 <argfd>
    8000551e:	87aa                	mv	a5,a0
    return -1;
    80005520:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005522:	0007ca63          	bltz	a5,80005536 <sys_fstat+0x3e>
  return filestat(f, st);
    80005526:	fe043583          	ld	a1,-32(s0)
    8000552a:	fe843503          	ld	a0,-24(s0)
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	2e0080e7          	jalr	736(ra) # 8000480e <filestat>
}
    80005536:	60e2                	ld	ra,24(sp)
    80005538:	6442                	ld	s0,16(sp)
    8000553a:	6105                	addi	sp,sp,32
    8000553c:	8082                	ret

000000008000553e <sys_link>:
{
    8000553e:	7169                	addi	sp,sp,-304
    80005540:	f606                	sd	ra,296(sp)
    80005542:	f222                	sd	s0,288(sp)
    80005544:	ee26                	sd	s1,280(sp)
    80005546:	ea4a                	sd	s2,272(sp)
    80005548:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000554a:	08000613          	li	a2,128
    8000554e:	ed040593          	addi	a1,s0,-304
    80005552:	4501                	li	a0,0
    80005554:	ffffd097          	auipc	ra,0xffffd
    80005558:	7e2080e7          	jalr	2018(ra) # 80002d36 <argstr>
    return -1;
    8000555c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000555e:	10054e63          	bltz	a0,8000567a <sys_link+0x13c>
    80005562:	08000613          	li	a2,128
    80005566:	f5040593          	addi	a1,s0,-176
    8000556a:	4505                	li	a0,1
    8000556c:	ffffd097          	auipc	ra,0xffffd
    80005570:	7ca080e7          	jalr	1994(ra) # 80002d36 <argstr>
    return -1;
    80005574:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005576:	10054263          	bltz	a0,8000567a <sys_link+0x13c>
  begin_op();
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	d00080e7          	jalr	-768(ra) # 8000427a <begin_op>
  if((ip = namei(old)) == 0){
    80005582:	ed040513          	addi	a0,s0,-304
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	ad8080e7          	jalr	-1320(ra) # 8000405e <namei>
    8000558e:	84aa                	mv	s1,a0
    80005590:	c551                	beqz	a0,8000561c <sys_link+0xde>
  ilock(ip);
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	326080e7          	jalr	806(ra) # 800038b8 <ilock>
  if(ip->type == T_DIR){
    8000559a:	04449703          	lh	a4,68(s1)
    8000559e:	4785                	li	a5,1
    800055a0:	08f70463          	beq	a4,a5,80005628 <sys_link+0xea>
  ip->nlink++;
    800055a4:	04a4d783          	lhu	a5,74(s1)
    800055a8:	2785                	addiw	a5,a5,1
    800055aa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055ae:	8526                	mv	a0,s1
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	23e080e7          	jalr	574(ra) # 800037ee <iupdate>
  iunlock(ip);
    800055b8:	8526                	mv	a0,s1
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	3c0080e7          	jalr	960(ra) # 8000397a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055c2:	fd040593          	addi	a1,s0,-48
    800055c6:	f5040513          	addi	a0,s0,-176
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	ab2080e7          	jalr	-1358(ra) # 8000407c <nameiparent>
    800055d2:	892a                	mv	s2,a0
    800055d4:	c935                	beqz	a0,80005648 <sys_link+0x10a>
  ilock(dp);
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	2e2080e7          	jalr	738(ra) # 800038b8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055de:	00092703          	lw	a4,0(s2)
    800055e2:	409c                	lw	a5,0(s1)
    800055e4:	04f71d63          	bne	a4,a5,8000563e <sys_link+0x100>
    800055e8:	40d0                	lw	a2,4(s1)
    800055ea:	fd040593          	addi	a1,s0,-48
    800055ee:	854a                	mv	a0,s2
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	9bc080e7          	jalr	-1604(ra) # 80003fac <dirlink>
    800055f8:	04054363          	bltz	a0,8000563e <sys_link+0x100>
  iunlockput(dp);
    800055fc:	854a                	mv	a0,s2
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	51c080e7          	jalr	1308(ra) # 80003b1a <iunlockput>
  iput(ip);
    80005606:	8526                	mv	a0,s1
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	46a080e7          	jalr	1130(ra) # 80003a72 <iput>
  end_op();
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	cea080e7          	jalr	-790(ra) # 800042fa <end_op>
  return 0;
    80005618:	4781                	li	a5,0
    8000561a:	a085                	j	8000567a <sys_link+0x13c>
    end_op();
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	cde080e7          	jalr	-802(ra) # 800042fa <end_op>
    return -1;
    80005624:	57fd                	li	a5,-1
    80005626:	a891                	j	8000567a <sys_link+0x13c>
    iunlockput(ip);
    80005628:	8526                	mv	a0,s1
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	4f0080e7          	jalr	1264(ra) # 80003b1a <iunlockput>
    end_op();
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	cc8080e7          	jalr	-824(ra) # 800042fa <end_op>
    return -1;
    8000563a:	57fd                	li	a5,-1
    8000563c:	a83d                	j	8000567a <sys_link+0x13c>
    iunlockput(dp);
    8000563e:	854a                	mv	a0,s2
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	4da080e7          	jalr	1242(ra) # 80003b1a <iunlockput>
  ilock(ip);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	26e080e7          	jalr	622(ra) # 800038b8 <ilock>
  ip->nlink--;
    80005652:	04a4d783          	lhu	a5,74(s1)
    80005656:	37fd                	addiw	a5,a5,-1
    80005658:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000565c:	8526                	mv	a0,s1
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	190080e7          	jalr	400(ra) # 800037ee <iupdate>
  iunlockput(ip);
    80005666:	8526                	mv	a0,s1
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	4b2080e7          	jalr	1202(ra) # 80003b1a <iunlockput>
  end_op();
    80005670:	fffff097          	auipc	ra,0xfffff
    80005674:	c8a080e7          	jalr	-886(ra) # 800042fa <end_op>
  return -1;
    80005678:	57fd                	li	a5,-1
}
    8000567a:	853e                	mv	a0,a5
    8000567c:	70b2                	ld	ra,296(sp)
    8000567e:	7412                	ld	s0,288(sp)
    80005680:	64f2                	ld	s1,280(sp)
    80005682:	6952                	ld	s2,272(sp)
    80005684:	6155                	addi	sp,sp,304
    80005686:	8082                	ret

0000000080005688 <sys_unlink>:
{
    80005688:	7151                	addi	sp,sp,-240
    8000568a:	f586                	sd	ra,232(sp)
    8000568c:	f1a2                	sd	s0,224(sp)
    8000568e:	eda6                	sd	s1,216(sp)
    80005690:	e9ca                	sd	s2,208(sp)
    80005692:	e5ce                	sd	s3,200(sp)
    80005694:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005696:	08000613          	li	a2,128
    8000569a:	f3040593          	addi	a1,s0,-208
    8000569e:	4501                	li	a0,0
    800056a0:	ffffd097          	auipc	ra,0xffffd
    800056a4:	696080e7          	jalr	1686(ra) # 80002d36 <argstr>
    800056a8:	18054163          	bltz	a0,8000582a <sys_unlink+0x1a2>
  begin_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	bce080e7          	jalr	-1074(ra) # 8000427a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056b4:	fb040593          	addi	a1,s0,-80
    800056b8:	f3040513          	addi	a0,s0,-208
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	9c0080e7          	jalr	-1600(ra) # 8000407c <nameiparent>
    800056c4:	84aa                	mv	s1,a0
    800056c6:	c979                	beqz	a0,8000579c <sys_unlink+0x114>
  ilock(dp);
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	1f0080e7          	jalr	496(ra) # 800038b8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056d0:	00003597          	auipc	a1,0x3
    800056d4:	13058593          	addi	a1,a1,304 # 80008800 <syscalls+0x2e0>
    800056d8:	fb040513          	addi	a0,s0,-80
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	6a6080e7          	jalr	1702(ra) # 80003d82 <namecmp>
    800056e4:	14050a63          	beqz	a0,80005838 <sys_unlink+0x1b0>
    800056e8:	00003597          	auipc	a1,0x3
    800056ec:	12058593          	addi	a1,a1,288 # 80008808 <syscalls+0x2e8>
    800056f0:	fb040513          	addi	a0,s0,-80
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	68e080e7          	jalr	1678(ra) # 80003d82 <namecmp>
    800056fc:	12050e63          	beqz	a0,80005838 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005700:	f2c40613          	addi	a2,s0,-212
    80005704:	fb040593          	addi	a1,s0,-80
    80005708:	8526                	mv	a0,s1
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	692080e7          	jalr	1682(ra) # 80003d9c <dirlookup>
    80005712:	892a                	mv	s2,a0
    80005714:	12050263          	beqz	a0,80005838 <sys_unlink+0x1b0>
  ilock(ip);
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	1a0080e7          	jalr	416(ra) # 800038b8 <ilock>
  if(ip->nlink < 1)
    80005720:	04a91783          	lh	a5,74(s2)
    80005724:	08f05263          	blez	a5,800057a8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005728:	04491703          	lh	a4,68(s2)
    8000572c:	4785                	li	a5,1
    8000572e:	08f70563          	beq	a4,a5,800057b8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005732:	4641                	li	a2,16
    80005734:	4581                	li	a1,0
    80005736:	fc040513          	addi	a0,s0,-64
    8000573a:	ffffb097          	auipc	ra,0xffffb
    8000573e:	598080e7          	jalr	1432(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005742:	4741                	li	a4,16
    80005744:	f2c42683          	lw	a3,-212(s0)
    80005748:	fc040613          	addi	a2,s0,-64
    8000574c:	4581                	li	a1,0
    8000574e:	8526                	mv	a0,s1
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	514080e7          	jalr	1300(ra) # 80003c64 <writei>
    80005758:	47c1                	li	a5,16
    8000575a:	0af51563          	bne	a0,a5,80005804 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000575e:	04491703          	lh	a4,68(s2)
    80005762:	4785                	li	a5,1
    80005764:	0af70863          	beq	a4,a5,80005814 <sys_unlink+0x18c>
  iunlockput(dp);
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	3b0080e7          	jalr	944(ra) # 80003b1a <iunlockput>
  ip->nlink--;
    80005772:	04a95783          	lhu	a5,74(s2)
    80005776:	37fd                	addiw	a5,a5,-1
    80005778:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000577c:	854a                	mv	a0,s2
    8000577e:	ffffe097          	auipc	ra,0xffffe
    80005782:	070080e7          	jalr	112(ra) # 800037ee <iupdate>
  iunlockput(ip);
    80005786:	854a                	mv	a0,s2
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	392080e7          	jalr	914(ra) # 80003b1a <iunlockput>
  end_op();
    80005790:	fffff097          	auipc	ra,0xfffff
    80005794:	b6a080e7          	jalr	-1174(ra) # 800042fa <end_op>
  return 0;
    80005798:	4501                	li	a0,0
    8000579a:	a84d                	j	8000584c <sys_unlink+0x1c4>
    end_op();
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	b5e080e7          	jalr	-1186(ra) # 800042fa <end_op>
    return -1;
    800057a4:	557d                	li	a0,-1
    800057a6:	a05d                	j	8000584c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057a8:	00003517          	auipc	a0,0x3
    800057ac:	06850513          	addi	a0,a0,104 # 80008810 <syscalls+0x2f0>
    800057b0:	ffffb097          	auipc	ra,0xffffb
    800057b4:	d8e080e7          	jalr	-626(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057b8:	04c92703          	lw	a4,76(s2)
    800057bc:	02000793          	li	a5,32
    800057c0:	f6e7f9e3          	bgeu	a5,a4,80005732 <sys_unlink+0xaa>
    800057c4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057c8:	4741                	li	a4,16
    800057ca:	86ce                	mv	a3,s3
    800057cc:	f1840613          	addi	a2,s0,-232
    800057d0:	4581                	li	a1,0
    800057d2:	854a                	mv	a0,s2
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	398080e7          	jalr	920(ra) # 80003b6c <readi>
    800057dc:	47c1                	li	a5,16
    800057de:	00f51b63          	bne	a0,a5,800057f4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057e2:	f1845783          	lhu	a5,-232(s0)
    800057e6:	e7a1                	bnez	a5,8000582e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057e8:	29c1                	addiw	s3,s3,16
    800057ea:	04c92783          	lw	a5,76(s2)
    800057ee:	fcf9ede3          	bltu	s3,a5,800057c8 <sys_unlink+0x140>
    800057f2:	b781                	j	80005732 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057f4:	00003517          	auipc	a0,0x3
    800057f8:	03450513          	addi	a0,a0,52 # 80008828 <syscalls+0x308>
    800057fc:	ffffb097          	auipc	ra,0xffffb
    80005800:	d42080e7          	jalr	-702(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005804:	00003517          	auipc	a0,0x3
    80005808:	03c50513          	addi	a0,a0,60 # 80008840 <syscalls+0x320>
    8000580c:	ffffb097          	auipc	ra,0xffffb
    80005810:	d32080e7          	jalr	-718(ra) # 8000053e <panic>
    dp->nlink--;
    80005814:	04a4d783          	lhu	a5,74(s1)
    80005818:	37fd                	addiw	a5,a5,-1
    8000581a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000581e:	8526                	mv	a0,s1
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	fce080e7          	jalr	-50(ra) # 800037ee <iupdate>
    80005828:	b781                	j	80005768 <sys_unlink+0xe0>
    return -1;
    8000582a:	557d                	li	a0,-1
    8000582c:	a005                	j	8000584c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000582e:	854a                	mv	a0,s2
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	2ea080e7          	jalr	746(ra) # 80003b1a <iunlockput>
  iunlockput(dp);
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	2e0080e7          	jalr	736(ra) # 80003b1a <iunlockput>
  end_op();
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	ab8080e7          	jalr	-1352(ra) # 800042fa <end_op>
  return -1;
    8000584a:	557d                	li	a0,-1
}
    8000584c:	70ae                	ld	ra,232(sp)
    8000584e:	740e                	ld	s0,224(sp)
    80005850:	64ee                	ld	s1,216(sp)
    80005852:	694e                	ld	s2,208(sp)
    80005854:	69ae                	ld	s3,200(sp)
    80005856:	616d                	addi	sp,sp,240
    80005858:	8082                	ret

000000008000585a <sys_open>:

uint64
sys_open(void)
{
    8000585a:	7131                	addi	sp,sp,-192
    8000585c:	fd06                	sd	ra,184(sp)
    8000585e:	f922                	sd	s0,176(sp)
    80005860:	f526                	sd	s1,168(sp)
    80005862:	f14a                	sd	s2,160(sp)
    80005864:	ed4e                	sd	s3,152(sp)
    80005866:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005868:	f4c40593          	addi	a1,s0,-180
    8000586c:	4505                	li	a0,1
    8000586e:	ffffd097          	auipc	ra,0xffffd
    80005872:	488080e7          	jalr	1160(ra) # 80002cf6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005876:	08000613          	li	a2,128
    8000587a:	f5040593          	addi	a1,s0,-176
    8000587e:	4501                	li	a0,0
    80005880:	ffffd097          	auipc	ra,0xffffd
    80005884:	4b6080e7          	jalr	1206(ra) # 80002d36 <argstr>
    80005888:	87aa                	mv	a5,a0
    return -1;
    8000588a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000588c:	0a07c963          	bltz	a5,8000593e <sys_open+0xe4>

  begin_op();
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	9ea080e7          	jalr	-1558(ra) # 8000427a <begin_op>

  if(omode & O_CREATE){
    80005898:	f4c42783          	lw	a5,-180(s0)
    8000589c:	2007f793          	andi	a5,a5,512
    800058a0:	cfc5                	beqz	a5,80005958 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058a2:	4681                	li	a3,0
    800058a4:	4601                	li	a2,0
    800058a6:	4589                	li	a1,2
    800058a8:	f5040513          	addi	a0,s0,-176
    800058ac:	00000097          	auipc	ra,0x0
    800058b0:	976080e7          	jalr	-1674(ra) # 80005222 <create>
    800058b4:	84aa                	mv	s1,a0
    if(ip == 0){
    800058b6:	c959                	beqz	a0,8000594c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058b8:	04449703          	lh	a4,68(s1)
    800058bc:	478d                	li	a5,3
    800058be:	00f71763          	bne	a4,a5,800058cc <sys_open+0x72>
    800058c2:	0464d703          	lhu	a4,70(s1)
    800058c6:	47a5                	li	a5,9
    800058c8:	0ce7ed63          	bltu	a5,a4,800059a2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	dbe080e7          	jalr	-578(ra) # 8000468a <filealloc>
    800058d4:	89aa                	mv	s3,a0
    800058d6:	10050363          	beqz	a0,800059dc <sys_open+0x182>
    800058da:	00000097          	auipc	ra,0x0
    800058de:	906080e7          	jalr	-1786(ra) # 800051e0 <fdalloc>
    800058e2:	892a                	mv	s2,a0
    800058e4:	0e054763          	bltz	a0,800059d2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058e8:	04449703          	lh	a4,68(s1)
    800058ec:	478d                	li	a5,3
    800058ee:	0cf70563          	beq	a4,a5,800059b8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058f2:	4789                	li	a5,2
    800058f4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058f8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058fc:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005900:	f4c42783          	lw	a5,-180(s0)
    80005904:	0017c713          	xori	a4,a5,1
    80005908:	8b05                	andi	a4,a4,1
    8000590a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000590e:	0037f713          	andi	a4,a5,3
    80005912:	00e03733          	snez	a4,a4
    80005916:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000591a:	4007f793          	andi	a5,a5,1024
    8000591e:	c791                	beqz	a5,8000592a <sys_open+0xd0>
    80005920:	04449703          	lh	a4,68(s1)
    80005924:	4789                	li	a5,2
    80005926:	0af70063          	beq	a4,a5,800059c6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000592a:	8526                	mv	a0,s1
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	04e080e7          	jalr	78(ra) # 8000397a <iunlock>
  end_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	9c6080e7          	jalr	-1594(ra) # 800042fa <end_op>

  return fd;
    8000593c:	854a                	mv	a0,s2
}
    8000593e:	70ea                	ld	ra,184(sp)
    80005940:	744a                	ld	s0,176(sp)
    80005942:	74aa                	ld	s1,168(sp)
    80005944:	790a                	ld	s2,160(sp)
    80005946:	69ea                	ld	s3,152(sp)
    80005948:	6129                	addi	sp,sp,192
    8000594a:	8082                	ret
      end_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	9ae080e7          	jalr	-1618(ra) # 800042fa <end_op>
      return -1;
    80005954:	557d                	li	a0,-1
    80005956:	b7e5                	j	8000593e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005958:	f5040513          	addi	a0,s0,-176
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	702080e7          	jalr	1794(ra) # 8000405e <namei>
    80005964:	84aa                	mv	s1,a0
    80005966:	c905                	beqz	a0,80005996 <sys_open+0x13c>
    ilock(ip);
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	f50080e7          	jalr	-176(ra) # 800038b8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005970:	04449703          	lh	a4,68(s1)
    80005974:	4785                	li	a5,1
    80005976:	f4f711e3          	bne	a4,a5,800058b8 <sys_open+0x5e>
    8000597a:	f4c42783          	lw	a5,-180(s0)
    8000597e:	d7b9                	beqz	a5,800058cc <sys_open+0x72>
      iunlockput(ip);
    80005980:	8526                	mv	a0,s1
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	198080e7          	jalr	408(ra) # 80003b1a <iunlockput>
      end_op();
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	970080e7          	jalr	-1680(ra) # 800042fa <end_op>
      return -1;
    80005992:	557d                	li	a0,-1
    80005994:	b76d                	j	8000593e <sys_open+0xe4>
      end_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	964080e7          	jalr	-1692(ra) # 800042fa <end_op>
      return -1;
    8000599e:	557d                	li	a0,-1
    800059a0:	bf79                	j	8000593e <sys_open+0xe4>
    iunlockput(ip);
    800059a2:	8526                	mv	a0,s1
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	176080e7          	jalr	374(ra) # 80003b1a <iunlockput>
    end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	94e080e7          	jalr	-1714(ra) # 800042fa <end_op>
    return -1;
    800059b4:	557d                	li	a0,-1
    800059b6:	b761                	j	8000593e <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059b8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059bc:	04649783          	lh	a5,70(s1)
    800059c0:	02f99223          	sh	a5,36(s3)
    800059c4:	bf25                	j	800058fc <sys_open+0xa2>
    itrunc(ip);
    800059c6:	8526                	mv	a0,s1
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	ffe080e7          	jalr	-2(ra) # 800039c6 <itrunc>
    800059d0:	bfa9                	j	8000592a <sys_open+0xd0>
      fileclose(f);
    800059d2:	854e                	mv	a0,s3
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	d72080e7          	jalr	-654(ra) # 80004746 <fileclose>
    iunlockput(ip);
    800059dc:	8526                	mv	a0,s1
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	13c080e7          	jalr	316(ra) # 80003b1a <iunlockput>
    end_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	914080e7          	jalr	-1772(ra) # 800042fa <end_op>
    return -1;
    800059ee:	557d                	li	a0,-1
    800059f0:	b7b9                	j	8000593e <sys_open+0xe4>

00000000800059f2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059f2:	7175                	addi	sp,sp,-144
    800059f4:	e506                	sd	ra,136(sp)
    800059f6:	e122                	sd	s0,128(sp)
    800059f8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	880080e7          	jalr	-1920(ra) # 8000427a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a02:	08000613          	li	a2,128
    80005a06:	f7040593          	addi	a1,s0,-144
    80005a0a:	4501                	li	a0,0
    80005a0c:	ffffd097          	auipc	ra,0xffffd
    80005a10:	32a080e7          	jalr	810(ra) # 80002d36 <argstr>
    80005a14:	02054963          	bltz	a0,80005a46 <sys_mkdir+0x54>
    80005a18:	4681                	li	a3,0
    80005a1a:	4601                	li	a2,0
    80005a1c:	4585                	li	a1,1
    80005a1e:	f7040513          	addi	a0,s0,-144
    80005a22:	00000097          	auipc	ra,0x0
    80005a26:	800080e7          	jalr	-2048(ra) # 80005222 <create>
    80005a2a:	cd11                	beqz	a0,80005a46 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	0ee080e7          	jalr	238(ra) # 80003b1a <iunlockput>
  end_op();
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	8c6080e7          	jalr	-1850(ra) # 800042fa <end_op>
  return 0;
    80005a3c:	4501                	li	a0,0
}
    80005a3e:	60aa                	ld	ra,136(sp)
    80005a40:	640a                	ld	s0,128(sp)
    80005a42:	6149                	addi	sp,sp,144
    80005a44:	8082                	ret
    end_op();
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	8b4080e7          	jalr	-1868(ra) # 800042fa <end_op>
    return -1;
    80005a4e:	557d                	li	a0,-1
    80005a50:	b7fd                	j	80005a3e <sys_mkdir+0x4c>

0000000080005a52 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a52:	7135                	addi	sp,sp,-160
    80005a54:	ed06                	sd	ra,152(sp)
    80005a56:	e922                	sd	s0,144(sp)
    80005a58:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	820080e7          	jalr	-2016(ra) # 8000427a <begin_op>
  argint(1, &major);
    80005a62:	f6c40593          	addi	a1,s0,-148
    80005a66:	4505                	li	a0,1
    80005a68:	ffffd097          	auipc	ra,0xffffd
    80005a6c:	28e080e7          	jalr	654(ra) # 80002cf6 <argint>
  argint(2, &minor);
    80005a70:	f6840593          	addi	a1,s0,-152
    80005a74:	4509                	li	a0,2
    80005a76:	ffffd097          	auipc	ra,0xffffd
    80005a7a:	280080e7          	jalr	640(ra) # 80002cf6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a7e:	08000613          	li	a2,128
    80005a82:	f7040593          	addi	a1,s0,-144
    80005a86:	4501                	li	a0,0
    80005a88:	ffffd097          	auipc	ra,0xffffd
    80005a8c:	2ae080e7          	jalr	686(ra) # 80002d36 <argstr>
    80005a90:	02054b63          	bltz	a0,80005ac6 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a94:	f6841683          	lh	a3,-152(s0)
    80005a98:	f6c41603          	lh	a2,-148(s0)
    80005a9c:	458d                	li	a1,3
    80005a9e:	f7040513          	addi	a0,s0,-144
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	780080e7          	jalr	1920(ra) # 80005222 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aaa:	cd11                	beqz	a0,80005ac6 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	06e080e7          	jalr	110(ra) # 80003b1a <iunlockput>
  end_op();
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	846080e7          	jalr	-1978(ra) # 800042fa <end_op>
  return 0;
    80005abc:	4501                	li	a0,0
}
    80005abe:	60ea                	ld	ra,152(sp)
    80005ac0:	644a                	ld	s0,144(sp)
    80005ac2:	610d                	addi	sp,sp,160
    80005ac4:	8082                	ret
    end_op();
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	834080e7          	jalr	-1996(ra) # 800042fa <end_op>
    return -1;
    80005ace:	557d                	li	a0,-1
    80005ad0:	b7fd                	j	80005abe <sys_mknod+0x6c>

0000000080005ad2 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ad2:	7135                	addi	sp,sp,-160
    80005ad4:	ed06                	sd	ra,152(sp)
    80005ad6:	e922                	sd	s0,144(sp)
    80005ad8:	e526                	sd	s1,136(sp)
    80005ada:	e14a                	sd	s2,128(sp)
    80005adc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ade:	ffffc097          	auipc	ra,0xffffc
    80005ae2:	f04080e7          	jalr	-252(ra) # 800019e2 <myproc>
    80005ae6:	892a                	mv	s2,a0
  
  begin_op();
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	792080e7          	jalr	1938(ra) # 8000427a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005af0:	08000613          	li	a2,128
    80005af4:	f6040593          	addi	a1,s0,-160
    80005af8:	4501                	li	a0,0
    80005afa:	ffffd097          	auipc	ra,0xffffd
    80005afe:	23c080e7          	jalr	572(ra) # 80002d36 <argstr>
    80005b02:	04054b63          	bltz	a0,80005b58 <sys_chdir+0x86>
    80005b06:	f6040513          	addi	a0,s0,-160
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	554080e7          	jalr	1364(ra) # 8000405e <namei>
    80005b12:	84aa                	mv	s1,a0
    80005b14:	c131                	beqz	a0,80005b58 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	da2080e7          	jalr	-606(ra) # 800038b8 <ilock>
  if(ip->type != T_DIR){
    80005b1e:	04449703          	lh	a4,68(s1)
    80005b22:	4785                	li	a5,1
    80005b24:	04f71063          	bne	a4,a5,80005b64 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b28:	8526                	mv	a0,s1
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	e50080e7          	jalr	-432(ra) # 8000397a <iunlock>
  iput(p->cwd);
    80005b32:	15093503          	ld	a0,336(s2)
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	f3c080e7          	jalr	-196(ra) # 80003a72 <iput>
  end_op();
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	7bc080e7          	jalr	1980(ra) # 800042fa <end_op>
  p->cwd = ip;
    80005b46:	14993823          	sd	s1,336(s2)
  return 0;
    80005b4a:	4501                	li	a0,0
}
    80005b4c:	60ea                	ld	ra,152(sp)
    80005b4e:	644a                	ld	s0,144(sp)
    80005b50:	64aa                	ld	s1,136(sp)
    80005b52:	690a                	ld	s2,128(sp)
    80005b54:	610d                	addi	sp,sp,160
    80005b56:	8082                	ret
    end_op();
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	7a2080e7          	jalr	1954(ra) # 800042fa <end_op>
    return -1;
    80005b60:	557d                	li	a0,-1
    80005b62:	b7ed                	j	80005b4c <sys_chdir+0x7a>
    iunlockput(ip);
    80005b64:	8526                	mv	a0,s1
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	fb4080e7          	jalr	-76(ra) # 80003b1a <iunlockput>
    end_op();
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	78c080e7          	jalr	1932(ra) # 800042fa <end_op>
    return -1;
    80005b76:	557d                	li	a0,-1
    80005b78:	bfd1                	j	80005b4c <sys_chdir+0x7a>

0000000080005b7a <sys_exec>:

uint64
sys_exec(void)
{
    80005b7a:	7145                	addi	sp,sp,-464
    80005b7c:	e786                	sd	ra,456(sp)
    80005b7e:	e3a2                	sd	s0,448(sp)
    80005b80:	ff26                	sd	s1,440(sp)
    80005b82:	fb4a                	sd	s2,432(sp)
    80005b84:	f74e                	sd	s3,424(sp)
    80005b86:	f352                	sd	s4,416(sp)
    80005b88:	ef56                	sd	s5,408(sp)
    80005b8a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b8c:	e3840593          	addi	a1,s0,-456
    80005b90:	4505                	li	a0,1
    80005b92:	ffffd097          	auipc	ra,0xffffd
    80005b96:	184080e7          	jalr	388(ra) # 80002d16 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b9a:	08000613          	li	a2,128
    80005b9e:	f4040593          	addi	a1,s0,-192
    80005ba2:	4501                	li	a0,0
    80005ba4:	ffffd097          	auipc	ra,0xffffd
    80005ba8:	192080e7          	jalr	402(ra) # 80002d36 <argstr>
    80005bac:	87aa                	mv	a5,a0
    return -1;
    80005bae:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005bb0:	0c07c263          	bltz	a5,80005c74 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bb4:	10000613          	li	a2,256
    80005bb8:	4581                	li	a1,0
    80005bba:	e4040513          	addi	a0,s0,-448
    80005bbe:	ffffb097          	auipc	ra,0xffffb
    80005bc2:	114080e7          	jalr	276(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bc6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bca:	89a6                	mv	s3,s1
    80005bcc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bce:	02000a13          	li	s4,32
    80005bd2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bd6:	00391793          	slli	a5,s2,0x3
    80005bda:	e3040593          	addi	a1,s0,-464
    80005bde:	e3843503          	ld	a0,-456(s0)
    80005be2:	953e                	add	a0,a0,a5
    80005be4:	ffffd097          	auipc	ra,0xffffd
    80005be8:	074080e7          	jalr	116(ra) # 80002c58 <fetchaddr>
    80005bec:	02054a63          	bltz	a0,80005c20 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005bf0:	e3043783          	ld	a5,-464(s0)
    80005bf4:	c3b9                	beqz	a5,80005c3a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bf6:	ffffb097          	auipc	ra,0xffffb
    80005bfa:	ef0080e7          	jalr	-272(ra) # 80000ae6 <kalloc>
    80005bfe:	85aa                	mv	a1,a0
    80005c00:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c04:	cd11                	beqz	a0,80005c20 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c06:	6605                	lui	a2,0x1
    80005c08:	e3043503          	ld	a0,-464(s0)
    80005c0c:	ffffd097          	auipc	ra,0xffffd
    80005c10:	09e080e7          	jalr	158(ra) # 80002caa <fetchstr>
    80005c14:	00054663          	bltz	a0,80005c20 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c18:	0905                	addi	s2,s2,1
    80005c1a:	09a1                	addi	s3,s3,8
    80005c1c:	fb491be3          	bne	s2,s4,80005bd2 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c20:	10048913          	addi	s2,s1,256
    80005c24:	6088                	ld	a0,0(s1)
    80005c26:	c531                	beqz	a0,80005c72 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c28:	ffffb097          	auipc	ra,0xffffb
    80005c2c:	dc2080e7          	jalr	-574(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c30:	04a1                	addi	s1,s1,8
    80005c32:	ff2499e3          	bne	s1,s2,80005c24 <sys_exec+0xaa>
  return -1;
    80005c36:	557d                	li	a0,-1
    80005c38:	a835                	j	80005c74 <sys_exec+0xfa>
      argv[i] = 0;
    80005c3a:	0a8e                	slli	s5,s5,0x3
    80005c3c:	fc040793          	addi	a5,s0,-64
    80005c40:	9abe                	add	s5,s5,a5
    80005c42:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c46:	e4040593          	addi	a1,s0,-448
    80005c4a:	f4040513          	addi	a0,s0,-192
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	172080e7          	jalr	370(ra) # 80004dc0 <exec>
    80005c56:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c58:	10048993          	addi	s3,s1,256
    80005c5c:	6088                	ld	a0,0(s1)
    80005c5e:	c901                	beqz	a0,80005c6e <sys_exec+0xf4>
    kfree(argv[i]);
    80005c60:	ffffb097          	auipc	ra,0xffffb
    80005c64:	d8a080e7          	jalr	-630(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c68:	04a1                	addi	s1,s1,8
    80005c6a:	ff3499e3          	bne	s1,s3,80005c5c <sys_exec+0xe2>
  return ret;
    80005c6e:	854a                	mv	a0,s2
    80005c70:	a011                	j	80005c74 <sys_exec+0xfa>
  return -1;
    80005c72:	557d                	li	a0,-1
}
    80005c74:	60be                	ld	ra,456(sp)
    80005c76:	641e                	ld	s0,448(sp)
    80005c78:	74fa                	ld	s1,440(sp)
    80005c7a:	795a                	ld	s2,432(sp)
    80005c7c:	79ba                	ld	s3,424(sp)
    80005c7e:	7a1a                	ld	s4,416(sp)
    80005c80:	6afa                	ld	s5,408(sp)
    80005c82:	6179                	addi	sp,sp,464
    80005c84:	8082                	ret

0000000080005c86 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c86:	7139                	addi	sp,sp,-64
    80005c88:	fc06                	sd	ra,56(sp)
    80005c8a:	f822                	sd	s0,48(sp)
    80005c8c:	f426                	sd	s1,40(sp)
    80005c8e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c90:	ffffc097          	auipc	ra,0xffffc
    80005c94:	d52080e7          	jalr	-686(ra) # 800019e2 <myproc>
    80005c98:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c9a:	fd840593          	addi	a1,s0,-40
    80005c9e:	4501                	li	a0,0
    80005ca0:	ffffd097          	auipc	ra,0xffffd
    80005ca4:	076080e7          	jalr	118(ra) # 80002d16 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005ca8:	fc840593          	addi	a1,s0,-56
    80005cac:	fd040513          	addi	a0,s0,-48
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	dc6080e7          	jalr	-570(ra) # 80004a76 <pipealloc>
    return -1;
    80005cb8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cba:	0c054463          	bltz	a0,80005d82 <sys_pipe+0xfc>
  fd0 = -1;
    80005cbe:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cc2:	fd043503          	ld	a0,-48(s0)
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	51a080e7          	jalr	1306(ra) # 800051e0 <fdalloc>
    80005cce:	fca42223          	sw	a0,-60(s0)
    80005cd2:	08054b63          	bltz	a0,80005d68 <sys_pipe+0xe2>
    80005cd6:	fc843503          	ld	a0,-56(s0)
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	506080e7          	jalr	1286(ra) # 800051e0 <fdalloc>
    80005ce2:	fca42023          	sw	a0,-64(s0)
    80005ce6:	06054863          	bltz	a0,80005d56 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cea:	4691                	li	a3,4
    80005cec:	fc440613          	addi	a2,s0,-60
    80005cf0:	fd843583          	ld	a1,-40(s0)
    80005cf4:	68a8                	ld	a0,80(s1)
    80005cf6:	ffffc097          	auipc	ra,0xffffc
    80005cfa:	9a8080e7          	jalr	-1624(ra) # 8000169e <copyout>
    80005cfe:	02054063          	bltz	a0,80005d1e <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d02:	4691                	li	a3,4
    80005d04:	fc040613          	addi	a2,s0,-64
    80005d08:	fd843583          	ld	a1,-40(s0)
    80005d0c:	0591                	addi	a1,a1,4
    80005d0e:	68a8                	ld	a0,80(s1)
    80005d10:	ffffc097          	auipc	ra,0xffffc
    80005d14:	98e080e7          	jalr	-1650(ra) # 8000169e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d18:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d1a:	06055463          	bgez	a0,80005d82 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d1e:	fc442783          	lw	a5,-60(s0)
    80005d22:	07e9                	addi	a5,a5,26
    80005d24:	078e                	slli	a5,a5,0x3
    80005d26:	97a6                	add	a5,a5,s1
    80005d28:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d2c:	fc042503          	lw	a0,-64(s0)
    80005d30:	0569                	addi	a0,a0,26
    80005d32:	050e                	slli	a0,a0,0x3
    80005d34:	94aa                	add	s1,s1,a0
    80005d36:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d3a:	fd043503          	ld	a0,-48(s0)
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	a08080e7          	jalr	-1528(ra) # 80004746 <fileclose>
    fileclose(wf);
    80005d46:	fc843503          	ld	a0,-56(s0)
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	9fc080e7          	jalr	-1540(ra) # 80004746 <fileclose>
    return -1;
    80005d52:	57fd                	li	a5,-1
    80005d54:	a03d                	j	80005d82 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d56:	fc442783          	lw	a5,-60(s0)
    80005d5a:	0007c763          	bltz	a5,80005d68 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d5e:	07e9                	addi	a5,a5,26
    80005d60:	078e                	slli	a5,a5,0x3
    80005d62:	94be                	add	s1,s1,a5
    80005d64:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d68:	fd043503          	ld	a0,-48(s0)
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	9da080e7          	jalr	-1574(ra) # 80004746 <fileclose>
    fileclose(wf);
    80005d74:	fc843503          	ld	a0,-56(s0)
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	9ce080e7          	jalr	-1586(ra) # 80004746 <fileclose>
    return -1;
    80005d80:	57fd                	li	a5,-1
}
    80005d82:	853e                	mv	a0,a5
    80005d84:	70e2                	ld	ra,56(sp)
    80005d86:	7442                	ld	s0,48(sp)
    80005d88:	74a2                	ld	s1,40(sp)
    80005d8a:	6121                	addi	sp,sp,64
    80005d8c:	8082                	ret
	...

0000000080005d90 <kernelvec>:
    80005d90:	7111                	addi	sp,sp,-256
    80005d92:	e006                	sd	ra,0(sp)
    80005d94:	e40a                	sd	sp,8(sp)
    80005d96:	e80e                	sd	gp,16(sp)
    80005d98:	ec12                	sd	tp,24(sp)
    80005d9a:	f016                	sd	t0,32(sp)
    80005d9c:	f41a                	sd	t1,40(sp)
    80005d9e:	f81e                	sd	t2,48(sp)
    80005da0:	fc22                	sd	s0,56(sp)
    80005da2:	e0a6                	sd	s1,64(sp)
    80005da4:	e4aa                	sd	a0,72(sp)
    80005da6:	e8ae                	sd	a1,80(sp)
    80005da8:	ecb2                	sd	a2,88(sp)
    80005daa:	f0b6                	sd	a3,96(sp)
    80005dac:	f4ba                	sd	a4,104(sp)
    80005dae:	f8be                	sd	a5,112(sp)
    80005db0:	fcc2                	sd	a6,120(sp)
    80005db2:	e146                	sd	a7,128(sp)
    80005db4:	e54a                	sd	s2,136(sp)
    80005db6:	e94e                	sd	s3,144(sp)
    80005db8:	ed52                	sd	s4,152(sp)
    80005dba:	f156                	sd	s5,160(sp)
    80005dbc:	f55a                	sd	s6,168(sp)
    80005dbe:	f95e                	sd	s7,176(sp)
    80005dc0:	fd62                	sd	s8,184(sp)
    80005dc2:	e1e6                	sd	s9,192(sp)
    80005dc4:	e5ea                	sd	s10,200(sp)
    80005dc6:	e9ee                	sd	s11,208(sp)
    80005dc8:	edf2                	sd	t3,216(sp)
    80005dca:	f1f6                	sd	t4,224(sp)
    80005dcc:	f5fa                	sd	t5,232(sp)
    80005dce:	f9fe                	sd	t6,240(sp)
    80005dd0:	d55fc0ef          	jal	ra,80002b24 <kerneltrap>
    80005dd4:	6082                	ld	ra,0(sp)
    80005dd6:	6122                	ld	sp,8(sp)
    80005dd8:	61c2                	ld	gp,16(sp)
    80005dda:	7282                	ld	t0,32(sp)
    80005ddc:	7322                	ld	t1,40(sp)
    80005dde:	73c2                	ld	t2,48(sp)
    80005de0:	7462                	ld	s0,56(sp)
    80005de2:	6486                	ld	s1,64(sp)
    80005de4:	6526                	ld	a0,72(sp)
    80005de6:	65c6                	ld	a1,80(sp)
    80005de8:	6666                	ld	a2,88(sp)
    80005dea:	7686                	ld	a3,96(sp)
    80005dec:	7726                	ld	a4,104(sp)
    80005dee:	77c6                	ld	a5,112(sp)
    80005df0:	7866                	ld	a6,120(sp)
    80005df2:	688a                	ld	a7,128(sp)
    80005df4:	692a                	ld	s2,136(sp)
    80005df6:	69ca                	ld	s3,144(sp)
    80005df8:	6a6a                	ld	s4,152(sp)
    80005dfa:	7a8a                	ld	s5,160(sp)
    80005dfc:	7b2a                	ld	s6,168(sp)
    80005dfe:	7bca                	ld	s7,176(sp)
    80005e00:	7c6a                	ld	s8,184(sp)
    80005e02:	6c8e                	ld	s9,192(sp)
    80005e04:	6d2e                	ld	s10,200(sp)
    80005e06:	6dce                	ld	s11,208(sp)
    80005e08:	6e6e                	ld	t3,216(sp)
    80005e0a:	7e8e                	ld	t4,224(sp)
    80005e0c:	7f2e                	ld	t5,232(sp)
    80005e0e:	7fce                	ld	t6,240(sp)
    80005e10:	6111                	addi	sp,sp,256
    80005e12:	10200073          	sret
    80005e16:	00000013          	nop
    80005e1a:	00000013          	nop
    80005e1e:	0001                	nop

0000000080005e20 <timervec>:
    80005e20:	34051573          	csrrw	a0,mscratch,a0
    80005e24:	e10c                	sd	a1,0(a0)
    80005e26:	e510                	sd	a2,8(a0)
    80005e28:	e914                	sd	a3,16(a0)
    80005e2a:	6d0c                	ld	a1,24(a0)
    80005e2c:	7110                	ld	a2,32(a0)
    80005e2e:	6194                	ld	a3,0(a1)
    80005e30:	96b2                	add	a3,a3,a2
    80005e32:	e194                	sd	a3,0(a1)
    80005e34:	4589                	li	a1,2
    80005e36:	14459073          	csrw	sip,a1
    80005e3a:	6914                	ld	a3,16(a0)
    80005e3c:	6510                	ld	a2,8(a0)
    80005e3e:	610c                	ld	a1,0(a0)
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	30200073          	mret
	...

0000000080005e4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e4a:	1141                	addi	sp,sp,-16
    80005e4c:	e422                	sd	s0,8(sp)
    80005e4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e50:	0c0007b7          	lui	a5,0xc000
    80005e54:	4705                	li	a4,1
    80005e56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e58:	c3d8                	sw	a4,4(a5)
}
    80005e5a:	6422                	ld	s0,8(sp)
    80005e5c:	0141                	addi	sp,sp,16
    80005e5e:	8082                	ret

0000000080005e60 <plicinithart>:

void
plicinithart(void)
{
    80005e60:	1141                	addi	sp,sp,-16
    80005e62:	e406                	sd	ra,8(sp)
    80005e64:	e022                	sd	s0,0(sp)
    80005e66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	b4e080e7          	jalr	-1202(ra) # 800019b6 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e70:	0085171b          	slliw	a4,a0,0x8
    80005e74:	0c0027b7          	lui	a5,0xc002
    80005e78:	97ba                	add	a5,a5,a4
    80005e7a:	40200713          	li	a4,1026
    80005e7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e82:	00d5151b          	slliw	a0,a0,0xd
    80005e86:	0c2017b7          	lui	a5,0xc201
    80005e8a:	953e                	add	a0,a0,a5
    80005e8c:	00052023          	sw	zero,0(a0)
}
    80005e90:	60a2                	ld	ra,8(sp)
    80005e92:	6402                	ld	s0,0(sp)
    80005e94:	0141                	addi	sp,sp,16
    80005e96:	8082                	ret

0000000080005e98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e98:	1141                	addi	sp,sp,-16
    80005e9a:	e406                	sd	ra,8(sp)
    80005e9c:	e022                	sd	s0,0(sp)
    80005e9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ea0:	ffffc097          	auipc	ra,0xffffc
    80005ea4:	b16080e7          	jalr	-1258(ra) # 800019b6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ea8:	00d5179b          	slliw	a5,a0,0xd
    80005eac:	0c201537          	lui	a0,0xc201
    80005eb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005eb2:	4148                	lw	a0,4(a0)
    80005eb4:	60a2                	ld	ra,8(sp)
    80005eb6:	6402                	ld	s0,0(sp)
    80005eb8:	0141                	addi	sp,sp,16
    80005eba:	8082                	ret

0000000080005ebc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ebc:	1101                	addi	sp,sp,-32
    80005ebe:	ec06                	sd	ra,24(sp)
    80005ec0:	e822                	sd	s0,16(sp)
    80005ec2:	e426                	sd	s1,8(sp)
    80005ec4:	1000                	addi	s0,sp,32
    80005ec6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	aee080e7          	jalr	-1298(ra) # 800019b6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ed0:	00d5151b          	slliw	a0,a0,0xd
    80005ed4:	0c2017b7          	lui	a5,0xc201
    80005ed8:	97aa                	add	a5,a5,a0
    80005eda:	c3c4                	sw	s1,4(a5)
}
    80005edc:	60e2                	ld	ra,24(sp)
    80005ede:	6442                	ld	s0,16(sp)
    80005ee0:	64a2                	ld	s1,8(sp)
    80005ee2:	6105                	addi	sp,sp,32
    80005ee4:	8082                	ret

0000000080005ee6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ee6:	1141                	addi	sp,sp,-16
    80005ee8:	e406                	sd	ra,8(sp)
    80005eea:	e022                	sd	s0,0(sp)
    80005eec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eee:	479d                	li	a5,7
    80005ef0:	04a7cc63          	blt	a5,a0,80005f48 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005ef4:	0001d797          	auipc	a5,0x1d
    80005ef8:	98c78793          	addi	a5,a5,-1652 # 80022880 <disk>
    80005efc:	97aa                	add	a5,a5,a0
    80005efe:	0187c783          	lbu	a5,24(a5)
    80005f02:	ebb9                	bnez	a5,80005f58 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f04:	00451613          	slli	a2,a0,0x4
    80005f08:	0001d797          	auipc	a5,0x1d
    80005f0c:	97878793          	addi	a5,a5,-1672 # 80022880 <disk>
    80005f10:	6394                	ld	a3,0(a5)
    80005f12:	96b2                	add	a3,a3,a2
    80005f14:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f18:	6398                	ld	a4,0(a5)
    80005f1a:	9732                	add	a4,a4,a2
    80005f1c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f20:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f24:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f28:	953e                	add	a0,a0,a5
    80005f2a:	4785                	li	a5,1
    80005f2c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005f30:	0001d517          	auipc	a0,0x1d
    80005f34:	96850513          	addi	a0,a0,-1688 # 80022898 <disk+0x18>
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	24e080e7          	jalr	590(ra) # 80002186 <wakeup>
}
    80005f40:	60a2                	ld	ra,8(sp)
    80005f42:	6402                	ld	s0,0(sp)
    80005f44:	0141                	addi	sp,sp,16
    80005f46:	8082                	ret
    panic("free_desc 1");
    80005f48:	00003517          	auipc	a0,0x3
    80005f4c:	90850513          	addi	a0,a0,-1784 # 80008850 <syscalls+0x330>
    80005f50:	ffffa097          	auipc	ra,0xffffa
    80005f54:	5ee080e7          	jalr	1518(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f58:	00003517          	auipc	a0,0x3
    80005f5c:	90850513          	addi	a0,a0,-1784 # 80008860 <syscalls+0x340>
    80005f60:	ffffa097          	auipc	ra,0xffffa
    80005f64:	5de080e7          	jalr	1502(ra) # 8000053e <panic>

0000000080005f68 <virtio_disk_init>:
{
    80005f68:	1101                	addi	sp,sp,-32
    80005f6a:	ec06                	sd	ra,24(sp)
    80005f6c:	e822                	sd	s0,16(sp)
    80005f6e:	e426                	sd	s1,8(sp)
    80005f70:	e04a                	sd	s2,0(sp)
    80005f72:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f74:	00003597          	auipc	a1,0x3
    80005f78:	8fc58593          	addi	a1,a1,-1796 # 80008870 <syscalls+0x350>
    80005f7c:	0001d517          	auipc	a0,0x1d
    80005f80:	a2c50513          	addi	a0,a0,-1492 # 800229a8 <disk+0x128>
    80005f84:	ffffb097          	auipc	ra,0xffffb
    80005f88:	bc2080e7          	jalr	-1086(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f8c:	100017b7          	lui	a5,0x10001
    80005f90:	4398                	lw	a4,0(a5)
    80005f92:	2701                	sext.w	a4,a4
    80005f94:	747277b7          	lui	a5,0x74727
    80005f98:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f9c:	14f71c63          	bne	a4,a5,800060f4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fa0:	100017b7          	lui	a5,0x10001
    80005fa4:	43dc                	lw	a5,4(a5)
    80005fa6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa8:	4709                	li	a4,2
    80005faa:	14e79563          	bne	a5,a4,800060f4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fae:	100017b7          	lui	a5,0x10001
    80005fb2:	479c                	lw	a5,8(a5)
    80005fb4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fb6:	12e79f63          	bne	a5,a4,800060f4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fba:	100017b7          	lui	a5,0x10001
    80005fbe:	47d8                	lw	a4,12(a5)
    80005fc0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fc2:	554d47b7          	lui	a5,0x554d4
    80005fc6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fca:	12f71563          	bne	a4,a5,800060f4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fce:	100017b7          	lui	a5,0x10001
    80005fd2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd6:	4705                	li	a4,1
    80005fd8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fda:	470d                	li	a4,3
    80005fdc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fde:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fe0:	c7ffe737          	lui	a4,0xc7ffe
    80005fe4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd8d87>
    80005fe8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fea:	2701                	sext.w	a4,a4
    80005fec:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fee:	472d                	li	a4,11
    80005ff0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ff2:	5bbc                	lw	a5,112(a5)
    80005ff4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ff8:	8ba1                	andi	a5,a5,8
    80005ffa:	10078563          	beqz	a5,80006104 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ffe:	100017b7          	lui	a5,0x10001
    80006002:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006006:	43fc                	lw	a5,68(a5)
    80006008:	2781                	sext.w	a5,a5
    8000600a:	10079563          	bnez	a5,80006114 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000600e:	100017b7          	lui	a5,0x10001
    80006012:	5bdc                	lw	a5,52(a5)
    80006014:	2781                	sext.w	a5,a5
  if(max == 0)
    80006016:	10078763          	beqz	a5,80006124 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000601a:	471d                	li	a4,7
    8000601c:	10f77c63          	bgeu	a4,a5,80006134 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006020:	ffffb097          	auipc	ra,0xffffb
    80006024:	ac6080e7          	jalr	-1338(ra) # 80000ae6 <kalloc>
    80006028:	0001d497          	auipc	s1,0x1d
    8000602c:	85848493          	addi	s1,s1,-1960 # 80022880 <disk>
    80006030:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006032:	ffffb097          	auipc	ra,0xffffb
    80006036:	ab4080e7          	jalr	-1356(ra) # 80000ae6 <kalloc>
    8000603a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000603c:	ffffb097          	auipc	ra,0xffffb
    80006040:	aaa080e7          	jalr	-1366(ra) # 80000ae6 <kalloc>
    80006044:	87aa                	mv	a5,a0
    80006046:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006048:	6088                	ld	a0,0(s1)
    8000604a:	cd6d                	beqz	a0,80006144 <virtio_disk_init+0x1dc>
    8000604c:	0001d717          	auipc	a4,0x1d
    80006050:	83c73703          	ld	a4,-1988(a4) # 80022888 <disk+0x8>
    80006054:	cb65                	beqz	a4,80006144 <virtio_disk_init+0x1dc>
    80006056:	c7fd                	beqz	a5,80006144 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006058:	6605                	lui	a2,0x1
    8000605a:	4581                	li	a1,0
    8000605c:	ffffb097          	auipc	ra,0xffffb
    80006060:	c76080e7          	jalr	-906(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006064:	0001d497          	auipc	s1,0x1d
    80006068:	81c48493          	addi	s1,s1,-2020 # 80022880 <disk>
    8000606c:	6605                	lui	a2,0x1
    8000606e:	4581                	li	a1,0
    80006070:	6488                	ld	a0,8(s1)
    80006072:	ffffb097          	auipc	ra,0xffffb
    80006076:	c60080e7          	jalr	-928(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000607a:	6605                	lui	a2,0x1
    8000607c:	4581                	li	a1,0
    8000607e:	6888                	ld	a0,16(s1)
    80006080:	ffffb097          	auipc	ra,0xffffb
    80006084:	c52080e7          	jalr	-942(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006088:	100017b7          	lui	a5,0x10001
    8000608c:	4721                	li	a4,8
    8000608e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006090:	4098                	lw	a4,0(s1)
    80006092:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006096:	40d8                	lw	a4,4(s1)
    80006098:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000609c:	6498                	ld	a4,8(s1)
    8000609e:	0007069b          	sext.w	a3,a4
    800060a2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800060a6:	9701                	srai	a4,a4,0x20
    800060a8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800060ac:	6898                	ld	a4,16(s1)
    800060ae:	0007069b          	sext.w	a3,a4
    800060b2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800060b6:	9701                	srai	a4,a4,0x20
    800060b8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800060bc:	4705                	li	a4,1
    800060be:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800060c0:	00e48c23          	sb	a4,24(s1)
    800060c4:	00e48ca3          	sb	a4,25(s1)
    800060c8:	00e48d23          	sb	a4,26(s1)
    800060cc:	00e48da3          	sb	a4,27(s1)
    800060d0:	00e48e23          	sb	a4,28(s1)
    800060d4:	00e48ea3          	sb	a4,29(s1)
    800060d8:	00e48f23          	sb	a4,30(s1)
    800060dc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800060e0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800060e4:	0727a823          	sw	s2,112(a5)
}
    800060e8:	60e2                	ld	ra,24(sp)
    800060ea:	6442                	ld	s0,16(sp)
    800060ec:	64a2                	ld	s1,8(sp)
    800060ee:	6902                	ld	s2,0(sp)
    800060f0:	6105                	addi	sp,sp,32
    800060f2:	8082                	ret
    panic("could not find virtio disk");
    800060f4:	00002517          	auipc	a0,0x2
    800060f8:	78c50513          	addi	a0,a0,1932 # 80008880 <syscalls+0x360>
    800060fc:	ffffa097          	auipc	ra,0xffffa
    80006100:	442080e7          	jalr	1090(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006104:	00002517          	auipc	a0,0x2
    80006108:	79c50513          	addi	a0,a0,1948 # 800088a0 <syscalls+0x380>
    8000610c:	ffffa097          	auipc	ra,0xffffa
    80006110:	432080e7          	jalr	1074(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006114:	00002517          	auipc	a0,0x2
    80006118:	7ac50513          	addi	a0,a0,1964 # 800088c0 <syscalls+0x3a0>
    8000611c:	ffffa097          	auipc	ra,0xffffa
    80006120:	422080e7          	jalr	1058(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006124:	00002517          	auipc	a0,0x2
    80006128:	7bc50513          	addi	a0,a0,1980 # 800088e0 <syscalls+0x3c0>
    8000612c:	ffffa097          	auipc	ra,0xffffa
    80006130:	412080e7          	jalr	1042(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006134:	00002517          	auipc	a0,0x2
    80006138:	7cc50513          	addi	a0,a0,1996 # 80008900 <syscalls+0x3e0>
    8000613c:	ffffa097          	auipc	ra,0xffffa
    80006140:	402080e7          	jalr	1026(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006144:	00002517          	auipc	a0,0x2
    80006148:	7dc50513          	addi	a0,a0,2012 # 80008920 <syscalls+0x400>
    8000614c:	ffffa097          	auipc	ra,0xffffa
    80006150:	3f2080e7          	jalr	1010(ra) # 8000053e <panic>

0000000080006154 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006154:	7119                	addi	sp,sp,-128
    80006156:	fc86                	sd	ra,120(sp)
    80006158:	f8a2                	sd	s0,112(sp)
    8000615a:	f4a6                	sd	s1,104(sp)
    8000615c:	f0ca                	sd	s2,96(sp)
    8000615e:	ecce                	sd	s3,88(sp)
    80006160:	e8d2                	sd	s4,80(sp)
    80006162:	e4d6                	sd	s5,72(sp)
    80006164:	e0da                	sd	s6,64(sp)
    80006166:	fc5e                	sd	s7,56(sp)
    80006168:	f862                	sd	s8,48(sp)
    8000616a:	f466                	sd	s9,40(sp)
    8000616c:	f06a                	sd	s10,32(sp)
    8000616e:	ec6e                	sd	s11,24(sp)
    80006170:	0100                	addi	s0,sp,128
    80006172:	8aaa                	mv	s5,a0
    80006174:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006176:	00c52d03          	lw	s10,12(a0)
    8000617a:	001d1d1b          	slliw	s10,s10,0x1
    8000617e:	1d02                	slli	s10,s10,0x20
    80006180:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006184:	0001d517          	auipc	a0,0x1d
    80006188:	82450513          	addi	a0,a0,-2012 # 800229a8 <disk+0x128>
    8000618c:	ffffb097          	auipc	ra,0xffffb
    80006190:	a4a080e7          	jalr	-1462(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006194:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006196:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006198:	0001cb97          	auipc	s7,0x1c
    8000619c:	6e8b8b93          	addi	s7,s7,1768 # 80022880 <disk>
  for(int i = 0; i < 3; i++){
    800061a0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061a2:	0001dc97          	auipc	s9,0x1d
    800061a6:	806c8c93          	addi	s9,s9,-2042 # 800229a8 <disk+0x128>
    800061aa:	a08d                	j	8000620c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800061ac:	00fb8733          	add	a4,s7,a5
    800061b0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061b4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061b6:	0207c563          	bltz	a5,800061e0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800061ba:	2905                	addiw	s2,s2,1
    800061bc:	0611                	addi	a2,a2,4
    800061be:	05690c63          	beq	s2,s6,80006216 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800061c2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061c4:	0001c717          	auipc	a4,0x1c
    800061c8:	6bc70713          	addi	a4,a4,1724 # 80022880 <disk>
    800061cc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800061ce:	01874683          	lbu	a3,24(a4)
    800061d2:	fee9                	bnez	a3,800061ac <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800061d4:	2785                	addiw	a5,a5,1
    800061d6:	0705                	addi	a4,a4,1
    800061d8:	fe979be3          	bne	a5,s1,800061ce <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800061dc:	57fd                	li	a5,-1
    800061de:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800061e0:	01205d63          	blez	s2,800061fa <virtio_disk_rw+0xa6>
    800061e4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800061e6:	000a2503          	lw	a0,0(s4)
    800061ea:	00000097          	auipc	ra,0x0
    800061ee:	cfc080e7          	jalr	-772(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    800061f2:	2d85                	addiw	s11,s11,1
    800061f4:	0a11                	addi	s4,s4,4
    800061f6:	ffb918e3          	bne	s2,s11,800061e6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061fa:	85e6                	mv	a1,s9
    800061fc:	0001c517          	auipc	a0,0x1c
    80006200:	69c50513          	addi	a0,a0,1692 # 80022898 <disk+0x18>
    80006204:	ffffc097          	auipc	ra,0xffffc
    80006208:	f1e080e7          	jalr	-226(ra) # 80002122 <sleep>
  for(int i = 0; i < 3; i++){
    8000620c:	f8040a13          	addi	s4,s0,-128
{
    80006210:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006212:	894e                	mv	s2,s3
    80006214:	b77d                	j	800061c2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006216:	f8042583          	lw	a1,-128(s0)
    8000621a:	00a58793          	addi	a5,a1,10
    8000621e:	0792                	slli	a5,a5,0x4

  if(write)
    80006220:	0001c617          	auipc	a2,0x1c
    80006224:	66060613          	addi	a2,a2,1632 # 80022880 <disk>
    80006228:	00f60733          	add	a4,a2,a5
    8000622c:	018036b3          	snez	a3,s8
    80006230:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006232:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006236:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000623a:	f6078693          	addi	a3,a5,-160
    8000623e:	6218                	ld	a4,0(a2)
    80006240:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006242:	00878513          	addi	a0,a5,8
    80006246:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006248:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000624a:	6208                	ld	a0,0(a2)
    8000624c:	96aa                	add	a3,a3,a0
    8000624e:	4741                	li	a4,16
    80006250:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006252:	4705                	li	a4,1
    80006254:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006258:	f8442703          	lw	a4,-124(s0)
    8000625c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006260:	0712                	slli	a4,a4,0x4
    80006262:	953a                	add	a0,a0,a4
    80006264:	058a8693          	addi	a3,s5,88
    80006268:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000626a:	6208                	ld	a0,0(a2)
    8000626c:	972a                	add	a4,a4,a0
    8000626e:	40000693          	li	a3,1024
    80006272:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006274:	001c3c13          	seqz	s8,s8
    80006278:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000627a:	001c6c13          	ori	s8,s8,1
    8000627e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006282:	f8842603          	lw	a2,-120(s0)
    80006286:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000628a:	0001c697          	auipc	a3,0x1c
    8000628e:	5f668693          	addi	a3,a3,1526 # 80022880 <disk>
    80006292:	00258713          	addi	a4,a1,2
    80006296:	0712                	slli	a4,a4,0x4
    80006298:	9736                	add	a4,a4,a3
    8000629a:	587d                	li	a6,-1
    8000629c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062a0:	0612                	slli	a2,a2,0x4
    800062a2:	9532                	add	a0,a0,a2
    800062a4:	f9078793          	addi	a5,a5,-112
    800062a8:	97b6                	add	a5,a5,a3
    800062aa:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800062ac:	629c                	ld	a5,0(a3)
    800062ae:	97b2                	add	a5,a5,a2
    800062b0:	4605                	li	a2,1
    800062b2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062b4:	4509                	li	a0,2
    800062b6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800062ba:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062be:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800062c2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062c6:	6698                	ld	a4,8(a3)
    800062c8:	00275783          	lhu	a5,2(a4)
    800062cc:	8b9d                	andi	a5,a5,7
    800062ce:	0786                	slli	a5,a5,0x1
    800062d0:	97ba                	add	a5,a5,a4
    800062d2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800062d6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062da:	6698                	ld	a4,8(a3)
    800062dc:	00275783          	lhu	a5,2(a4)
    800062e0:	2785                	addiw	a5,a5,1
    800062e2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062e6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062ea:	100017b7          	lui	a5,0x10001
    800062ee:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062f2:	004aa783          	lw	a5,4(s5)
    800062f6:	02c79163          	bne	a5,a2,80006318 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800062fa:	0001c917          	auipc	s2,0x1c
    800062fe:	6ae90913          	addi	s2,s2,1710 # 800229a8 <disk+0x128>
  while(b->disk == 1) {
    80006302:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006304:	85ca                	mv	a1,s2
    80006306:	8556                	mv	a0,s5
    80006308:	ffffc097          	auipc	ra,0xffffc
    8000630c:	e1a080e7          	jalr	-486(ra) # 80002122 <sleep>
  while(b->disk == 1) {
    80006310:	004aa783          	lw	a5,4(s5)
    80006314:	fe9788e3          	beq	a5,s1,80006304 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006318:	f8042903          	lw	s2,-128(s0)
    8000631c:	00290793          	addi	a5,s2,2
    80006320:	00479713          	slli	a4,a5,0x4
    80006324:	0001c797          	auipc	a5,0x1c
    80006328:	55c78793          	addi	a5,a5,1372 # 80022880 <disk>
    8000632c:	97ba                	add	a5,a5,a4
    8000632e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006332:	0001c997          	auipc	s3,0x1c
    80006336:	54e98993          	addi	s3,s3,1358 # 80022880 <disk>
    8000633a:	00491713          	slli	a4,s2,0x4
    8000633e:	0009b783          	ld	a5,0(s3)
    80006342:	97ba                	add	a5,a5,a4
    80006344:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006348:	854a                	mv	a0,s2
    8000634a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000634e:	00000097          	auipc	ra,0x0
    80006352:	b98080e7          	jalr	-1128(ra) # 80005ee6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006356:	8885                	andi	s1,s1,1
    80006358:	f0ed                	bnez	s1,8000633a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000635a:	0001c517          	auipc	a0,0x1c
    8000635e:	64e50513          	addi	a0,a0,1614 # 800229a8 <disk+0x128>
    80006362:	ffffb097          	auipc	ra,0xffffb
    80006366:	928080e7          	jalr	-1752(ra) # 80000c8a <release>
}
    8000636a:	70e6                	ld	ra,120(sp)
    8000636c:	7446                	ld	s0,112(sp)
    8000636e:	74a6                	ld	s1,104(sp)
    80006370:	7906                	ld	s2,96(sp)
    80006372:	69e6                	ld	s3,88(sp)
    80006374:	6a46                	ld	s4,80(sp)
    80006376:	6aa6                	ld	s5,72(sp)
    80006378:	6b06                	ld	s6,64(sp)
    8000637a:	7be2                	ld	s7,56(sp)
    8000637c:	7c42                	ld	s8,48(sp)
    8000637e:	7ca2                	ld	s9,40(sp)
    80006380:	7d02                	ld	s10,32(sp)
    80006382:	6de2                	ld	s11,24(sp)
    80006384:	6109                	addi	sp,sp,128
    80006386:	8082                	ret

0000000080006388 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006388:	1101                	addi	sp,sp,-32
    8000638a:	ec06                	sd	ra,24(sp)
    8000638c:	e822                	sd	s0,16(sp)
    8000638e:	e426                	sd	s1,8(sp)
    80006390:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006392:	0001c497          	auipc	s1,0x1c
    80006396:	4ee48493          	addi	s1,s1,1262 # 80022880 <disk>
    8000639a:	0001c517          	auipc	a0,0x1c
    8000639e:	60e50513          	addi	a0,a0,1550 # 800229a8 <disk+0x128>
    800063a2:	ffffb097          	auipc	ra,0xffffb
    800063a6:	834080e7          	jalr	-1996(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063aa:	10001737          	lui	a4,0x10001
    800063ae:	533c                	lw	a5,96(a4)
    800063b0:	8b8d                	andi	a5,a5,3
    800063b2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063b4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063b8:	689c                	ld	a5,16(s1)
    800063ba:	0204d703          	lhu	a4,32(s1)
    800063be:	0027d783          	lhu	a5,2(a5)
    800063c2:	04f70863          	beq	a4,a5,80006412 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800063c6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063ca:	6898                	ld	a4,16(s1)
    800063cc:	0204d783          	lhu	a5,32(s1)
    800063d0:	8b9d                	andi	a5,a5,7
    800063d2:	078e                	slli	a5,a5,0x3
    800063d4:	97ba                	add	a5,a5,a4
    800063d6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063d8:	00278713          	addi	a4,a5,2
    800063dc:	0712                	slli	a4,a4,0x4
    800063de:	9726                	add	a4,a4,s1
    800063e0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800063e4:	e721                	bnez	a4,8000642c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063e6:	0789                	addi	a5,a5,2
    800063e8:	0792                	slli	a5,a5,0x4
    800063ea:	97a6                	add	a5,a5,s1
    800063ec:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800063ee:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063f2:	ffffc097          	auipc	ra,0xffffc
    800063f6:	d94080e7          	jalr	-620(ra) # 80002186 <wakeup>

    disk.used_idx += 1;
    800063fa:	0204d783          	lhu	a5,32(s1)
    800063fe:	2785                	addiw	a5,a5,1
    80006400:	17c2                	slli	a5,a5,0x30
    80006402:	93c1                	srli	a5,a5,0x30
    80006404:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006408:	6898                	ld	a4,16(s1)
    8000640a:	00275703          	lhu	a4,2(a4)
    8000640e:	faf71ce3          	bne	a4,a5,800063c6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006412:	0001c517          	auipc	a0,0x1c
    80006416:	59650513          	addi	a0,a0,1430 # 800229a8 <disk+0x128>
    8000641a:	ffffb097          	auipc	ra,0xffffb
    8000641e:	870080e7          	jalr	-1936(ra) # 80000c8a <release>
}
    80006422:	60e2                	ld	ra,24(sp)
    80006424:	6442                	ld	s0,16(sp)
    80006426:	64a2                	ld	s1,8(sp)
    80006428:	6105                	addi	sp,sp,32
    8000642a:	8082                	ret
      panic("virtio_disk_intr status");
    8000642c:	00002517          	auipc	a0,0x2
    80006430:	50c50513          	addi	a0,a0,1292 # 80008938 <syscalls+0x418>
    80006434:	ffffa097          	auipc	ra,0xffffa
    80006438:	10a080e7          	jalr	266(ra) # 8000053e <panic>

000000008000643c <free_desc>:
    panic("virtio_gpu: no free descriptors");
}

static void
free_desc(int i)
{
    8000643c:	1141                	addi	sp,sp,-16
    8000643e:	e422                	sd	s0,8(sp)
    80006440:	0800                	addi	s0,sp,16
    gq.desc[i].addr = 0;
    80006442:	0001c717          	auipc	a4,0x1c
    80006446:	57e70713          	addi	a4,a4,1406 # 800229c0 <gq>
    8000644a:	00451693          	slli	a3,a0,0x4
    8000644e:	631c                	ld	a5,0(a4)
    80006450:	97b6                	add	a5,a5,a3
    80006452:	0007b023          	sd	zero,0(a5)
    gq.desc[i].len = 0;
    80006456:	0007a423          	sw	zero,8(a5)
    gq.desc[i].flags = 0;
    8000645a:	00079623          	sh	zero,12(a5)
    gq.desc[i].next = 0;
    8000645e:	00079723          	sh	zero,14(a5)
    gq.free[i] = 1;
    80006462:	972a                	add	a4,a4,a0
    80006464:	4785                	li	a5,1
    80006466:	00f70c23          	sb	a5,24(a4)
}
    8000646a:	6422                	ld	s0,8(sp)
    8000646c:	0141                	addi	sp,sp,16
    8000646e:	8082                	ret

0000000080006470 <alloc_desc>:
    for (int i = 0; i < GPU_NUM; i++)
    80006470:	0001c797          	auipc	a5,0x1c
    80006474:	55078793          	addi	a5,a5,1360 # 800229c0 <gq>
    80006478:	4501                	li	a0,0
    8000647a:	46a1                	li	a3,8
        if (gq.free[i])
    8000647c:	0187c703          	lbu	a4,24(a5)
    80006480:	e30d                	bnez	a4,800064a2 <alloc_desc+0x32>
    for (int i = 0; i < GPU_NUM; i++)
    80006482:	2505                	addiw	a0,a0,1
    80006484:	0785                	addi	a5,a5,1
    80006486:	fed51be3          	bne	a0,a3,8000647c <alloc_desc+0xc>
{
    8000648a:	1141                	addi	sp,sp,-16
    8000648c:	e406                	sd	ra,8(sp)
    8000648e:	e022                	sd	s0,0(sp)
    80006490:	0800                	addi	s0,sp,16
    panic("virtio_gpu: no free descriptors");
    80006492:	00002517          	auipc	a0,0x2
    80006496:	4be50513          	addi	a0,a0,1214 # 80008950 <syscalls+0x430>
    8000649a:	ffffa097          	auipc	ra,0xffffa
    8000649e:	0a4080e7          	jalr	164(ra) # 8000053e <panic>
            gq.free[i] = 0;
    800064a2:	0001c797          	auipc	a5,0x1c
    800064a6:	51e78793          	addi	a5,a5,1310 # 800229c0 <gq>
    800064aa:	97aa                	add	a5,a5,a0
    800064ac:	00078c23          	sb	zero,24(a5)
}
    800064b0:	8082                	ret

00000000800064b2 <gpu_send>:

// Submit a 2-descriptor command (request + shared response) and block
// until the device completes it by advancing the used ring.
static void
gpu_send(void *req, int req_len)
{
    800064b2:	7139                	addi	sp,sp,-64
    800064b4:	fc06                	sd	ra,56(sp)
    800064b6:	f822                	sd	s0,48(sp)
    800064b8:	f426                	sd	s1,40(sp)
    800064ba:	f04a                	sd	s2,32(sp)
    800064bc:	ec4e                	sd	s3,24(sp)
    800064be:	e852                	sd	s4,16(sp)
    800064c0:	e456                	sd	s5,8(sp)
    800064c2:	0080                	addi	s0,sp,64
    800064c4:	8aaa                	mv	s5,a0
    800064c6:	8a2e                	mv	s4,a1
    acquire(&gpu_lock);
    800064c8:	0001c997          	auipc	s3,0x1c
    800064cc:	4f898993          	addi	s3,s3,1272 # 800229c0 <gq>
    800064d0:	0001c517          	auipc	a0,0x1c
    800064d4:	51850513          	addi	a0,a0,1304 # 800229e8 <gpu_lock>
    800064d8:	ffffa097          	auipc	ra,0xffffa
    800064dc:	6fe080e7          	jalr	1790(ra) # 80000bd6 <acquire>
    int d0 = alloc_desc();
    800064e0:	00000097          	auipc	ra,0x0
    800064e4:	f90080e7          	jalr	-112(ra) # 80006470 <alloc_desc>
    800064e8:	892a                	mv	s2,a0
    int d1 = alloc_desc();
    800064ea:	00000097          	auipc	ra,0x0
    800064ee:	f86080e7          	jalr	-122(ra) # 80006470 <alloc_desc>
    800064f2:	84aa                	mv	s1,a0

    gq.desc[d0].addr = (uint64)req;
    800064f4:	00491793          	slli	a5,s2,0x4
    800064f8:	0009b703          	ld	a4,0(s3)
    800064fc:	973e                	add	a4,a4,a5
    800064fe:	01573023          	sd	s5,0(a4)
    gq.desc[d0].len = (uint32)req_len;
    80006502:	0009b703          	ld	a4,0(s3)
    80006506:	97ba                	add	a5,a5,a4
    80006508:	0147a423          	sw	s4,8(a5)
    gq.desc[d0].flags = VRING_DESC_F_NEXT;
    8000650c:	4685                	li	a3,1
    8000650e:	00d79623          	sh	a3,12(a5)
    gq.desc[d0].next = d1;
    80006512:	00a79723          	sh	a0,14(a5)

    gq.desc[d1].addr = (uint64)&cmd_resp;
    80006516:	00451693          	slli	a3,a0,0x4
    8000651a:	9736                	add	a4,a4,a3
    8000651c:	0001c797          	auipc	a5,0x1c
    80006520:	4e478793          	addi	a5,a5,1252 # 80022a00 <cmd_resp>
    80006524:	e31c                	sd	a5,0(a4)
    gq.desc[d1].len = sizeof(cmd_resp);
    80006526:	0009b783          	ld	a5,0(s3)
    8000652a:	97b6                	add	a5,a5,a3
    8000652c:	4761                	li	a4,24
    8000652e:	c798                	sw	a4,8(a5)
    gq.desc[d1].flags = VRING_DESC_F_WRITE;
    80006530:	4709                	li	a4,2
    80006532:	00e79623          	sh	a4,12(a5)
    gq.desc[d1].next = 0;
    80006536:	00079723          	sh	zero,14(a5)

    // Place head descriptor index in the available ring.
    gq.avail->ring[gq.avail->idx % GPU_NUM] = d0;
    8000653a:	0089b703          	ld	a4,8(s3)
    8000653e:	00275783          	lhu	a5,2(a4)
    80006542:	8b9d                	andi	a5,a5,7
    80006544:	0786                	slli	a5,a5,0x1
    80006546:	97ba                	add	a5,a5,a4
    80006548:	01279223          	sh	s2,4(a5)
    __sync_synchronize();
    8000654c:	0ff0000f          	fence
    gq.avail->idx++;
    80006550:	0089b703          	ld	a4,8(s3)
    80006554:	00275783          	lhu	a5,2(a4)
    80006558:	2785                	addiw	a5,a5,1
    8000655a:	00f71123          	sh	a5,2(a4)
    __sync_synchronize();
    8000655e:	0ff0000f          	fence

    // Notify device (queue index 0 = controlq).
    *R1(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;
    80006562:	100027b7          	lui	a5,0x10002
    80006566:	0407a823          	sw	zero,80(a5) # 10002050 <_entry-0x6fffdfb0>

    // Poll until the device advances the used ring.
    while (1)
    {
        __sync_synchronize();
        if (gq.used->idx != gq.used_idx)
    8000656a:	874e                	mv	a4,s3
        __sync_synchronize();
    8000656c:	0ff0000f          	fence
        if (gq.used->idx != gq.used_idx)
    80006570:	02075783          	lhu	a5,32(a4)
    80006574:	6b14                	ld	a3,16(a4)
    80006576:	0026d683          	lhu	a3,2(a3)
    8000657a:	fef689e3          	beq	a3,a5,8000656c <gpu_send+0xba>
            break;
    }
    gq.used_idx++;
    8000657e:	2785                	addiw	a5,a5,1
    80006580:	0001c717          	auipc	a4,0x1c
    80006584:	46f71023          	sh	a5,1120(a4) # 800229e0 <gq+0x20>

    free_desc(d0);
    80006588:	854a                	mv	a0,s2
    8000658a:	00000097          	auipc	ra,0x0
    8000658e:	eb2080e7          	jalr	-334(ra) # 8000643c <free_desc>
    free_desc(d1);
    80006592:	8526                	mv	a0,s1
    80006594:	00000097          	auipc	ra,0x0
    80006598:	ea8080e7          	jalr	-344(ra) # 8000643c <free_desc>
    release(&gpu_lock);
    8000659c:	0001c517          	auipc	a0,0x1c
    800065a0:	44c50513          	addi	a0,a0,1100 # 800229e8 <gpu_lock>
    800065a4:	ffffa097          	auipc	ra,0xffffa
    800065a8:	6e6080e7          	jalr	1766(ra) # 80000c8a <release>
}
    800065ac:	70e2                	ld	ra,56(sp)
    800065ae:	7442                	ld	s0,48(sp)
    800065b0:	74a2                	ld	s1,40(sp)
    800065b2:	7902                	ld	s2,32(sp)
    800065b4:	69e2                	ld	s3,24(sp)
    800065b6:	6a42                	ld	s4,16(sp)
    800065b8:	6aa2                	ld	s5,8(sp)
    800065ba:	6121                	addi	sp,sp,64
    800065bc:	8082                	ret

00000000800065be <gpu_transfer_flush>:
{
    800065be:	7139                	addi	sp,sp,-64
    800065c0:	fc06                	sd	ra,56(sp)
    800065c2:	f822                	sd	s0,48(sp)
    800065c4:	f426                	sd	s1,40(sp)
    800065c6:	f04a                	sd	s2,32(sp)
    800065c8:	ec4e                	sd	s3,24(sp)
    800065ca:	e852                	sd	s4,16(sp)
    800065cc:	e456                	sd	s5,8(sp)
    800065ce:	0080                	addi	s0,sp,64
    memset(&xfer, 0, sizeof(xfer));
    800065d0:	0001c497          	auipc	s1,0x1c
    800065d4:	3f048493          	addi	s1,s1,1008 # 800229c0 <gq>
    800065d8:	0001c917          	auipc	s2,0x1c
    800065dc:	44090913          	addi	s2,s2,1088 # 80022a18 <xfer.1>
    800065e0:	03800613          	li	a2,56
    800065e4:	4581                	li	a1,0
    800065e6:	854a                	mv	a0,s2
    800065e8:	ffffa097          	auipc	ra,0xffffa
    800065ec:	6ea080e7          	jalr	1770(ra) # 80000cd2 <memset>
    xfer.hdr.type = VIRTIO_GPU_CMD_TRANSFER_TO_HOST_2D;
    800065f0:	10500793          	li	a5,261
    800065f4:	ccbc                	sw	a5,88(s1)
    xfer.r.x = 0;
    800065f6:	0604a823          	sw	zero,112(s1)
    xfer.r.y = 0;
    800065fa:	0604aa23          	sw	zero,116(s1)
    xfer.r.width = SCREEN_W;
    800065fe:	28000a93          	li	s5,640
    80006602:	0754ac23          	sw	s5,120(s1)
    xfer.r.height = SCREEN_H;
    80006606:	1e000a13          	li	s4,480
    8000660a:	0744ae23          	sw	s4,124(s1)
    xfer.resource_id = RESOURCE_ID;
    8000660e:	4985                	li	s3,1
    80006610:	0934a423          	sw	s3,136(s1)
    gpu_send(&xfer, sizeof(xfer));
    80006614:	03800593          	li	a1,56
    80006618:	854a                	mv	a0,s2
    8000661a:	00000097          	auipc	ra,0x0
    8000661e:	e98080e7          	jalr	-360(ra) # 800064b2 <gpu_send>
    memset(&flush, 0, sizeof(flush));
    80006622:	0001c917          	auipc	s2,0x1c
    80006626:	42e90913          	addi	s2,s2,1070 # 80022a50 <flush.0>
    8000662a:	03000613          	li	a2,48
    8000662e:	4581                	li	a1,0
    80006630:	854a                	mv	a0,s2
    80006632:	ffffa097          	auipc	ra,0xffffa
    80006636:	6a0080e7          	jalr	1696(ra) # 80000cd2 <memset>
    flush.hdr.type = VIRTIO_GPU_CMD_RESOURCE_FLUSH;
    8000663a:	10400793          	li	a5,260
    8000663e:	08f4a823          	sw	a5,144(s1)
    flush.r.x = 0;
    80006642:	0a04a423          	sw	zero,168(s1)
    flush.r.y = 0;
    80006646:	0a04a623          	sw	zero,172(s1)
    flush.r.width = SCREEN_W;
    8000664a:	0b54a823          	sw	s5,176(s1)
    flush.r.height = SCREEN_H;
    8000664e:	0b44aa23          	sw	s4,180(s1)
    flush.resource_id = RESOURCE_ID;
    80006652:	0b34ac23          	sw	s3,184(s1)
    gpu_send(&flush, sizeof(flush));
    80006656:	03000593          	li	a1,48
    8000665a:	854a                	mv	a0,s2
    8000665c:	00000097          	auipc	ra,0x0
    80006660:	e56080e7          	jalr	-426(ra) # 800064b2 <gpu_send>
}
    80006664:	70e2                	ld	ra,56(sp)
    80006666:	7442                	ld	s0,48(sp)
    80006668:	74a2                	ld	s1,40(sp)
    8000666a:	7902                	ld	s2,32(sp)
    8000666c:	69e2                	ld	s3,24(sp)
    8000666e:	6a42                	ld	s4,16(sp)
    80006670:	6aa2                	ld	s5,8(sp)
    80006672:	6121                	addi	sp,sp,64
    80006674:	8082                	ret

0000000080006676 <virtio_gpu_init>:

// ── Public init ───────────────────────────────────────────────────────

void virtio_gpu_init(void)
{
    80006676:	7159                	addi	sp,sp,-112
    80006678:	f486                	sd	ra,104(sp)
    8000667a:	f0a2                	sd	s0,96(sp)
    8000667c:	eca6                	sd	s1,88(sp)
    8000667e:	e8ca                	sd	s2,80(sp)
    80006680:	e4ce                	sd	s3,72(sp)
    80006682:	e0d2                	sd	s4,64(sp)
    80006684:	fc56                	sd	s5,56(sp)
    80006686:	f85a                	sd	s6,48(sp)
    80006688:	f45e                	sd	s7,40(sp)
    8000668a:	f062                	sd	s8,32(sp)
    8000668c:	ec66                	sd	s9,24(sp)
    8000668e:	e86a                	sd	s10,16(sp)
    80006690:	e46e                	sd	s11,8(sp)
    80006692:	1880                	addi	s0,sp,112
    uint32 status = 0;
    initlock(&gpu_lock, "vgpu");
    80006694:	00002597          	auipc	a1,0x2
    80006698:	2dc58593          	addi	a1,a1,732 # 80008970 <syscalls+0x450>
    8000669c:	0001c517          	auipc	a0,0x1c
    800066a0:	34c50513          	addi	a0,a0,844 # 800229e8 <gpu_lock>
    800066a4:	ffffa097          	auipc	ra,0xffffa
    800066a8:	4a2080e7          	jalr	1186(ra) # 80000b46 <initlock>

    // ── 1. VirtIO device handshake ──────────────────────────────────────
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066ac:	100027b7          	lui	a5,0x10002
    800066b0:	4398                	lw	a4,0(a5)
    800066b2:	2701                	sext.w	a4,a4
    800066b4:	747277b7          	lui	a5,0x74727
    800066b8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800066bc:	02f71a63          	bne	a4,a5,800066f0 <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    800066c0:	100027b7          	lui	a5,0x10002
    800066c4:	43dc                	lw	a5,4(a5)
    800066c6:	2781                	sext.w	a5,a5
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066c8:	4709                	li	a4,2
    800066ca:	02e79363          	bne	a5,a4,800066f0 <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    800066ce:	100027b7          	lui	a5,0x10002
    800066d2:	479c                	lw	a5,8(a5)
    800066d4:	2781                	sext.w	a5,a5
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    800066d6:	4741                	li	a4,16
    800066d8:	00e79c63          	bne	a5,a4,800066f0 <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551)
    800066dc:	100027b7          	lui	a5,0x10002
    800066e0:	47d8                	lw	a4,12(a5)
    800066e2:	2701                	sext.w	a4,a4
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    800066e4:	554d47b7          	lui	a5,0x554d4
    800066e8:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800066ec:	02f70963          	beq	a4,a5,8000671e <virtio_gpu_init+0xa8>
    {
        printf("virtio_gpu_init: GPU not found\n");
    800066f0:	00002517          	auipc	a0,0x2
    800066f4:	28850513          	addi	a0,a0,648 # 80008978 <syscalls+0x458>
    800066f8:	ffffa097          	auipc	ra,0xffffa
    800066fc:	e90080e7          	jalr	-368(ra) # 80000588 <printf>
    gpu_send(&scanout_req, sizeof(scanout_req));

    // ── 8. TRANSFER_TO_HOST_2D (upload guest memory -> host GPU) ─────────
    gpu_transfer_flush();
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
}
    80006700:	70a6                	ld	ra,104(sp)
    80006702:	7406                	ld	s0,96(sp)
    80006704:	64e6                	ld	s1,88(sp)
    80006706:	6946                	ld	s2,80(sp)
    80006708:	69a6                	ld	s3,72(sp)
    8000670a:	6a06                	ld	s4,64(sp)
    8000670c:	7ae2                	ld	s5,56(sp)
    8000670e:	7b42                	ld	s6,48(sp)
    80006710:	7ba2                	ld	s7,40(sp)
    80006712:	7c02                	ld	s8,32(sp)
    80006714:	6ce2                	ld	s9,24(sp)
    80006716:	6d42                	ld	s10,16(sp)
    80006718:	6da2                	ld	s11,8(sp)
    8000671a:	6165                	addi	sp,sp,112
    8000671c:	8082                	ret
    *R1(VIRTIO_MMIO_STATUS) = status;
    8000671e:	100027b7          	lui	a5,0x10002
    80006722:	0607a823          	sw	zero,112(a5) # 10002070 <_entry-0x6fffdf90>
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006726:	4705                	li	a4,1
    80006728:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    8000672a:	470d                	li	a4,3
    8000672c:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_DRIVER_FEATURES) = 0;
    8000672e:	0207a023          	sw	zero,32(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006732:	472d                	li	a4,11
    80006734:	dbb8                	sw	a4,112(a5)
    if (!(*R1(VIRTIO_MMIO_STATUS) & VIRTIO_CONFIG_S_FEATURES_OK))
    80006736:	5bbc                	lw	a5,112(a5)
    80006738:	8ba1                	andi	a5,a5,8
    8000673a:	22078363          	beqz	a5,80006960 <virtio_gpu_init+0x2ea>
    *R1(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000673e:	100027b7          	lui	a5,0x10002
    80006742:	0207a823          	sw	zero,48(a5) # 10002030 <_entry-0x6fffdfd0>
    if (*R1(VIRTIO_MMIO_QUEUE_READY))
    80006746:	43fc                	lw	a5,68(a5)
    80006748:	2781                	sext.w	a5,a5
    8000674a:	22079363          	bnez	a5,80006970 <virtio_gpu_init+0x2fa>
    if (*R1(VIRTIO_MMIO_QUEUE_NUM_MAX) < GPU_NUM)
    8000674e:	100027b7          	lui	a5,0x10002
    80006752:	5bdc                	lw	a5,52(a5)
    80006754:	2781                	sext.w	a5,a5
    80006756:	471d                	li	a4,7
    80006758:	22f77463          	bgeu	a4,a5,80006980 <virtio_gpu_init+0x30a>
    gq.desc = kalloc();
    8000675c:	ffffa097          	auipc	ra,0xffffa
    80006760:	38a080e7          	jalr	906(ra) # 80000ae6 <kalloc>
    80006764:	0001c497          	auipc	s1,0x1c
    80006768:	25c48493          	addi	s1,s1,604 # 800229c0 <gq>
    8000676c:	e088                	sd	a0,0(s1)
    gq.avail = kalloc();
    8000676e:	ffffa097          	auipc	ra,0xffffa
    80006772:	378080e7          	jalr	888(ra) # 80000ae6 <kalloc>
    80006776:	e488                	sd	a0,8(s1)
    gq.used = kalloc();
    80006778:	ffffa097          	auipc	ra,0xffffa
    8000677c:	36e080e7          	jalr	878(ra) # 80000ae6 <kalloc>
    80006780:	87aa                	mv	a5,a0
    80006782:	e888                	sd	a0,16(s1)
    if (!gq.desc || !gq.avail || !gq.used)
    80006784:	6088                	ld	a0,0(s1)
    80006786:	20050563          	beqz	a0,80006990 <virtio_gpu_init+0x31a>
    8000678a:	0001c717          	auipc	a4,0x1c
    8000678e:	23e73703          	ld	a4,574(a4) # 800229c8 <gq+0x8>
    80006792:	1e070f63          	beqz	a4,80006990 <virtio_gpu_init+0x31a>
    80006796:	1e078d63          	beqz	a5,80006990 <virtio_gpu_init+0x31a>
    memset(gq.desc, 0, PGSIZE);
    8000679a:	6605                	lui	a2,0x1
    8000679c:	4581                	li	a1,0
    8000679e:	ffffa097          	auipc	ra,0xffffa
    800067a2:	534080e7          	jalr	1332(ra) # 80000cd2 <memset>
    memset(gq.avail, 0, PGSIZE);
    800067a6:	0001c497          	auipc	s1,0x1c
    800067aa:	21a48493          	addi	s1,s1,538 # 800229c0 <gq>
    800067ae:	6605                	lui	a2,0x1
    800067b0:	4581                	li	a1,0
    800067b2:	6488                	ld	a0,8(s1)
    800067b4:	ffffa097          	auipc	ra,0xffffa
    800067b8:	51e080e7          	jalr	1310(ra) # 80000cd2 <memset>
    memset(gq.used, 0, PGSIZE);
    800067bc:	6605                	lui	a2,0x1
    800067be:	4581                	li	a1,0
    800067c0:	6888                	ld	a0,16(s1)
    800067c2:	ffffa097          	auipc	ra,0xffffa
    800067c6:	510080e7          	jalr	1296(ra) # 80000cd2 <memset>
    *R1(VIRTIO_MMIO_QUEUE_NUM) = GPU_NUM;
    800067ca:	100027b7          	lui	a5,0x10002
    800067ce:	4721                	li	a4,8
    800067d0:	df98                	sw	a4,56(a5)
    *R1(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)gq.desc;
    800067d2:	4098                	lw	a4,0(s1)
    800067d4:	08e7a023          	sw	a4,128(a5) # 10002080 <_entry-0x6fffdf80>
    *R1(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)gq.desc >> 32;
    800067d8:	40d8                	lw	a4,4(s1)
    800067da:	08e7a223          	sw	a4,132(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)gq.avail;
    800067de:	6498                	ld	a4,8(s1)
    800067e0:	0007069b          	sext.w	a3,a4
    800067e4:	08d7a823          	sw	a3,144(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)gq.avail >> 32;
    800067e8:	9701                	srai	a4,a4,0x20
    800067ea:	08e7aa23          	sw	a4,148(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)gq.used;
    800067ee:	6898                	ld	a4,16(s1)
    800067f0:	0007069b          	sext.w	a3,a4
    800067f4:	0ad7a023          	sw	a3,160(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)gq.used >> 32;
    800067f8:	9701                	srai	a4,a4,0x20
    800067fa:	0ae7a223          	sw	a4,164(a5)
    *R1(VIRTIO_MMIO_QUEUE_READY) = 1;
    800067fe:	4705                	li	a4,1
    80006800:	c3f8                	sw	a4,68(a5)
        gq.free[i] = 1;
    80006802:	00e48c23          	sb	a4,24(s1)
    80006806:	00e48ca3          	sb	a4,25(s1)
    8000680a:	00e48d23          	sb	a4,26(s1)
    8000680e:	00e48da3          	sb	a4,27(s1)
    80006812:	00e48e23          	sb	a4,28(s1)
    80006816:	00e48ea3          	sb	a4,29(s1)
    8000681a:	00e48f23          	sb	a4,30(s1)
    8000681e:	00e48fa3          	sb	a4,31(s1)
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006822:	473d                	li	a4,15
    80006824:	dbb8                	sw	a4,112(a5)
    for (int i = 0; i < FB_PAGES; i++)
    80006826:	0001f917          	auipc	s2,0x1f
    8000682a:	85290913          	addi	s2,s2,-1966 # 80025078 <fb>
    8000682e:	0001f997          	auipc	s3,0x1f
    80006832:	1aa98993          	addi	s3,s3,426 # 800259d8 <end>
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006836:	84ca                	mv	s1,s2
        fb[i] = kalloc();
    80006838:	ffffa097          	auipc	ra,0xffffa
    8000683c:	2ae080e7          	jalr	686(ra) # 80000ae6 <kalloc>
    80006840:	e088                	sd	a0,0(s1)
        if (!fb[i])
    80006842:	14050f63          	beqz	a0,800069a0 <virtio_gpu_init+0x32a>
        memset(fb[i], 0, PGSIZE); // fill with COLOR_BG (0 = black)
    80006846:	6605                	lui	a2,0x1
    80006848:	4581                	li	a1,0
    8000684a:	ffffa097          	auipc	ra,0xffffa
    8000684e:	488080e7          	jalr	1160(ra) # 80000cd2 <memset>
    for (int i = 0; i < FB_PAGES; i++)
    80006852:	04a1                	addi	s1,s1,8
    80006854:	ff3492e3          	bne	s1,s3,80006838 <virtio_gpu_init+0x1c2>
    memset(&create_req, 0, sizeof(create_req));
    80006858:	0001c497          	auipc	s1,0x1c
    8000685c:	16848493          	addi	s1,s1,360 # 800229c0 <gq>
    80006860:	0001c997          	auipc	s3,0x1c
    80006864:	22098993          	addi	s3,s3,544 # 80022a80 <create_req.4>
    80006868:	02800613          	li	a2,40
    8000686c:	4581                	li	a1,0
    8000686e:	854e                	mv	a0,s3
    80006870:	ffffa097          	auipc	ra,0xffffa
    80006874:	462080e7          	jalr	1122(ra) # 80000cd2 <memset>
    create_req.hdr.type = VIRTIO_GPU_CMD_RESOURCE_CREATE_2D;
    80006878:	10100793          	li	a5,257
    8000687c:	0cf4a023          	sw	a5,192(s1)
    create_req.resource_id = RESOURCE_ID;
    80006880:	4785                	li	a5,1
    80006882:	0cf4ac23          	sw	a5,216(s1)
    create_req.format = VIRTIO_GPU_FORMAT_B8G8R8X8_UNORM;
    80006886:	4789                	li	a5,2
    80006888:	0cf4ae23          	sw	a5,220(s1)
    create_req.width = SCREEN_W;
    8000688c:	28000793          	li	a5,640
    80006890:	0ef4a023          	sw	a5,224(s1)
    create_req.height = SCREEN_H;
    80006894:	1e000793          	li	a5,480
    80006898:	0ef4a223          	sw	a5,228(s1)
    gpu_send(&create_req, sizeof(create_req));
    8000689c:	02800593          	li	a1,40
    800068a0:	854e                	mv	a0,s3
    800068a2:	00000097          	auipc	ra,0x0
    800068a6:	c10080e7          	jalr	-1008(ra) # 800064b2 <gpu_send>
    for (int i = 0; i < FB_PAGES; i++) {
    800068aa:	0001c597          	auipc	a1,0x1c
    800068ae:	22e58593          	addi	a1,a1,558 # 80022ad8 <fb_entries.3>
    800068b2:	0001d697          	auipc	a3,0x1d
    800068b6:	4e668693          	addi	a3,a3,1254 # 80023d98 <attach_buf>
    gpu_send(&create_req, sizeof(create_req));
    800068ba:	87ae                	mv	a5,a1
        fb_entries[i].length = PGSIZE;
    800068bc:	6605                	lui	a2,0x1
        fb_entries[i].addr   = (uint64)fb[i];
    800068be:	00093703          	ld	a4,0(s2)
    800068c2:	e398                	sd	a4,0(a5)
        fb_entries[i].length = PGSIZE;
    800068c4:	c790                	sw	a2,8(a5)
    for (int i = 0; i < FB_PAGES; i++) {
    800068c6:	0921                	addi	s2,s2,8
    800068c8:	07c1                	addi	a5,a5,16
    800068ca:	fed79ae3          	bne	a5,a3,800068be <virtio_gpu_init+0x248>
    attach_buf.backing.hdr.type = VIRTIO_GPU_CMD_RESOURCE_ATTACH_BACKING;
    800068ce:	0001d797          	auipc	a5,0x1d
    800068d2:	4ca78793          	addi	a5,a5,1226 # 80023d98 <attach_buf>
    800068d6:	10600713          	li	a4,262
    800068da:	c398                	sw	a4,0(a5)
    attach_buf.backing.resource_id = RESOURCE_ID;
    800068dc:	4705                	li	a4,1
    800068de:	cf98                	sw	a4,24(a5)
    attach_buf.backing.nr_entries = n;
    800068e0:	12c00713          	li	a4,300
    800068e4:	cfd8                	sw	a4,28(a5)
    for (int i = 0; i < n; i++)
    800068e6:	0001d797          	auipc	a5,0x1d
    800068ea:	4d278793          	addi	a5,a5,1234 # 80023db8 <attach_buf+0x20>
        attach_buf.entries[i] = entries[i];
    800068ee:	6198                	ld	a4,0(a1)
    800068f0:	e398                	sd	a4,0(a5)
    800068f2:	6598                	ld	a4,8(a1)
    800068f4:	e798                	sd	a4,8(a5)
    for (int i = 0; i < n; i++)
    800068f6:	05c1                	addi	a1,a1,16
    800068f8:	07c1                	addi	a5,a5,16
    800068fa:	fed59ae3          	bne	a1,a3,800068ee <virtio_gpu_init+0x278>
    gpu_send(&attach_buf, sizeof(attach_buf));
    800068fe:	6585                	lui	a1,0x1
    80006900:	2e058593          	addi	a1,a1,736 # 12e0 <_entry-0x7fffed20>
    80006904:	0001d517          	auipc	a0,0x1d
    80006908:	49450513          	addi	a0,a0,1172 # 80023d98 <attach_buf>
    8000690c:	00000097          	auipc	ra,0x0
    80006910:	ba6080e7          	jalr	-1114(ra) # 800064b2 <gpu_send>
        for (int i = 0; msg[i]; i++)
    80006914:	00002c17          	auipc	s8,0x2
    80006918:	13cc0c13          	addi	s8,s8,316 # 80008a50 <syscalls+0x530>
    gpu_send(&attach_buf, sizeof(attach_buf));
    8000691c:	0008cbb7          	lui	s7,0x8c
    80006920:	250b8b93          	addi	s7,s7,592 # 8c250 <_entry-0x7ff73db0>
        for (int i = 0; msg[i]; i++)
    80006924:	04800793          	li	a5,72
    const uint8 *rows = font8x8[ch];
    80006928:	00002c97          	auipc	s9,0x2
    8000692c:	170c8c93          	addi	s9,s9,368 # 80008a98 <font8x8>
    80006930:	00024737          	lui	a4,0x24
    80006934:	a0070d93          	addi	s11,a4,-1536 # 23a00 <_entry-0x7ffdc600>
        for (int col = 0; col < 8; col++)
    80006938:	4d01                	li	s10,0
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    8000693a:	010004b7          	lui	s1,0x1000
    8000693e:	14fd                	addi	s1,s1,-1
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006940:	0001e897          	auipc	a7,0x1e
    80006944:	73888893          	addi	a7,a7,1848 # 80025078 <fb>
    int off = byte_off % PGSIZE;
    80006948:	6805                	lui	a6,0x1
    8000694a:	187d                	addi	a6,a6,-1
            for (int dy = 0; dy < SCALE; dy++)
    8000694c:	6e05                	lui	t3,0x1
    8000694e:	a00e0e1b          	addiw	t3,t3,-1536
        for (int col = 0; col < 8; col++)
    80006952:	40a1                	li	ra,8
    for (int row = 0; row < 8; row++)
    80006954:	6a8d                	lui	s5,0x3
    80006956:	800a8a9b          	addiw	s5,s5,-2048
    8000695a:	10000b13          	li	s6,256
    8000695e:	a0f1                	j	80006a2a <virtio_gpu_init+0x3b4>
        panic("virtio_gpu: FEATURES_OK not set");
    80006960:	00002517          	auipc	a0,0x2
    80006964:	03850513          	addi	a0,a0,56 # 80008998 <syscalls+0x478>
    80006968:	ffffa097          	auipc	ra,0xffffa
    8000696c:	bd6080e7          	jalr	-1066(ra) # 8000053e <panic>
        panic("virtio_gpu: queue already ready");
    80006970:	00002517          	auipc	a0,0x2
    80006974:	04850513          	addi	a0,a0,72 # 800089b8 <syscalls+0x498>
    80006978:	ffffa097          	auipc	ra,0xffffa
    8000697c:	bc6080e7          	jalr	-1082(ra) # 8000053e <panic>
        panic("virtio_gpu: queue too small");
    80006980:	00002517          	auipc	a0,0x2
    80006984:	05850513          	addi	a0,a0,88 # 800089d8 <syscalls+0x4b8>
    80006988:	ffffa097          	auipc	ra,0xffffa
    8000698c:	bb6080e7          	jalr	-1098(ra) # 8000053e <panic>
        panic("virtio_gpu: kalloc failed for queue");
    80006990:	00002517          	auipc	a0,0x2
    80006994:	06850513          	addi	a0,a0,104 # 800089f8 <syscalls+0x4d8>
    80006998:	ffffa097          	auipc	ra,0xffffa
    8000699c:	ba6080e7          	jalr	-1114(ra) # 8000053e <panic>
            panic("virtio_gpu: kalloc failed for framebuffer");
    800069a0:	00002517          	auipc	a0,0x2
    800069a4:	08050513          	addi	a0,a0,128 # 80008a20 <syscalls+0x500>
    800069a8:	ffffa097          	auipc	ra,0xffffa
    800069ac:	b96080e7          	jalr	-1130(ra) # 8000053e <panic>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    800069b0:	85fe                	mv	a1,t6
    800069b2:	831e                	mv	t1,t2
                for (int dx = 0; dx < SCALE; dx++)
    800069b4:	ff05869b          	addiw	a3,a1,-16
    int pg = byte_off / PGSIZE;
    800069b8:	43f6d613          	srai	a2,a3,0x3f
    800069bc:	0146561b          	srliw	a2,a2,0x14
    800069c0:	00d607bb          	addw	a5,a2,a3
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    800069c4:	40c7d71b          	sraiw	a4,a5,0xc
    800069c8:	070e                	slli	a4,a4,0x3
    800069ca:	9746                	add	a4,a4,a7
    int off = byte_off % PGSIZE;
    800069cc:	0107f7b3          	and	a5,a5,a6
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    800069d0:	9f91                	subw	a5,a5,a2
    *p = color;
    800069d2:	6310                	ld	a2,0(a4)
    800069d4:	97b2                	add	a5,a5,a2
    800069d6:	c388                	sw	a0,0(a5)
                for (int dx = 0; dx < SCALE; dx++)
    800069d8:	2691                	addiw	a3,a3,4
    800069da:	fcd59fe3          	bne	a1,a3,800069b8 <virtio_gpu_init+0x342>
            for (int dy = 0; dy < SCALE; dy++)
    800069de:	2803031b          	addiw	t1,t1,640
    800069e2:	00be05bb          	addw	a1,t3,a1
    800069e6:	fdd317e3          	bne	t1,t4,800069b4 <virtio_gpu_init+0x33e>
        for (int col = 0; col < 8; col++)
    800069ea:	2f05                	addiw	t5,t5,1
    800069ec:	2fc1                	addiw	t6,t6,16
    800069ee:	001f0a63          	beq	t5,ra,80006a02 <virtio_gpu_init+0x38c>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    800069f2:	0002c503          	lbu	a0,0(t0)
    800069f6:	01e5553b          	srlw	a0,a0,t5
    800069fa:	8905                	andi	a0,a0,1
    800069fc:	d955                	beqz	a0,800069b0 <virtio_gpu_init+0x33a>
    800069fe:	8526                	mv	a0,s1
    80006a00:	bf45                	j	800069b0 <virtio_gpu_init+0x33a>
    for (int row = 0; row < 8; row++)
    80006a02:	01de0ebb          	addw	t4,t3,t4
    80006a06:	012e093b          	addw	s2,t3,s2
    80006a0a:	2991                	addiw	s3,s3,4
    80006a0c:	014a8a3b          	addw	s4,s5,s4
    80006a10:	0285                	addi	t0,t0,1
    80006a12:	01698663          	beq	s3,s6,80006a1e <virtio_gpu_init+0x3a8>
        for (int i = 0; msg[i]; i++)
    80006a16:	8fd2                	mv	t6,s4
        for (int col = 0; col < 8; col++)
    80006a18:	8f6a                	mv	t5,s10
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006a1a:	83ca                	mv	t2,s2
    80006a1c:	bfd9                	j	800069f2 <virtio_gpu_init+0x37c>
        for (int i = 0; msg[i]; i++)
    80006a1e:	001c4783          	lbu	a5,1(s8)
    80006a22:	0c05                	addi	s8,s8,1
    80006a24:	080b8b9b          	addiw	s7,s7,128
    80006a28:	cb99                	beqz	a5,80006a3e <virtio_gpu_init+0x3c8>
    const uint8 *rows = font8x8[ch];
    80006a2a:	078e                	slli	a5,a5,0x3
    80006a2c:	019782b3          	add	t0,a5,s9
    80006a30:	8a5e                	mv	s4,s7
    80006a32:	0e000993          	li	s3,224
    80006a36:	00023937          	lui	s2,0x23
    80006a3a:	8eee                	mv	t4,s11
    80006a3c:	bfe9                	j	80006a16 <virtio_gpu_init+0x3a0>
    memset(&scanout_req, 0, sizeof(scanout_req));
    80006a3e:	0001c497          	auipc	s1,0x1c
    80006a42:	f8248493          	addi	s1,s1,-126 # 800229c0 <gq>
    80006a46:	0001c917          	auipc	s2,0x1c
    80006a4a:	06290913          	addi	s2,s2,98 # 80022aa8 <scanout_req.2>
    80006a4e:	03000613          	li	a2,48
    80006a52:	4581                	li	a1,0
    80006a54:	854a                	mv	a0,s2
    80006a56:	ffffa097          	auipc	ra,0xffffa
    80006a5a:	27c080e7          	jalr	636(ra) # 80000cd2 <memset>
    scanout_req.hdr.type = VIRTIO_GPU_CMD_SET_SCANOUT;
    80006a5e:	10300793          	li	a5,259
    80006a62:	0ef4a423          	sw	a5,232(s1)
    scanout_req.r.x = 0;
    80006a66:	1004a023          	sw	zero,256(s1)
    scanout_req.r.y = 0;
    80006a6a:	1004a223          	sw	zero,260(s1)
    scanout_req.r.width = SCREEN_W;
    80006a6e:	28000793          	li	a5,640
    80006a72:	10f4a423          	sw	a5,264(s1)
    scanout_req.r.height = SCREEN_H;
    80006a76:	1e000793          	li	a5,480
    80006a7a:	10f4a623          	sw	a5,268(s1)
    scanout_req.scanout_id = SCANOUT_ID;
    80006a7e:	1004a823          	sw	zero,272(s1)
    scanout_req.resource_id = RESOURCE_ID;
    80006a82:	4785                	li	a5,1
    80006a84:	10f4aa23          	sw	a5,276(s1)
    gpu_send(&scanout_req, sizeof(scanout_req));
    80006a88:	03000593          	li	a1,48
    80006a8c:	854a                	mv	a0,s2
    80006a8e:	00000097          	auipc	ra,0x0
    80006a92:	a24080e7          	jalr	-1500(ra) # 800064b2 <gpu_send>
    gpu_transfer_flush();
    80006a96:	00000097          	auipc	ra,0x0
    80006a9a:	b28080e7          	jalr	-1240(ra) # 800065be <gpu_transfer_flush>
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
    80006a9e:	00002517          	auipc	a0,0x2
    80006aa2:	fc250513          	addi	a0,a0,-62 # 80008a60 <syscalls+0x540>
    80006aa6:	ffffa097          	auipc	ra,0xffffa
    80006aaa:	ae2080e7          	jalr	-1310(ra) # 80000588 <printf>
    80006aae:	b989                	j	80006700 <virtio_gpu_init+0x8a>

0000000080006ab0 <virtio_gpu_commit>:

// ── Public: flush the kernel fb[] to the display ─────────────────────
// Called by display_daemon.  Sends TRANSFER_TO_HOST_2D + RESOURCE_FLUSH.
void virtio_gpu_commit(void)
{
    80006ab0:	1141                	addi	sp,sp,-16
    80006ab2:	e406                	sd	ra,8(sp)
    80006ab4:	e022                	sd	s0,0(sp)
    80006ab6:	0800                	addi	s0,sp,16
    gpu_transfer_flush();
    80006ab8:	00000097          	auipc	ra,0x0
    80006abc:	b06080e7          	jalr	-1274(ra) # 800065be <gpu_transfer_flush>
}
    80006ac0:	60a2                	ld	ra,8(sp)
    80006ac2:	6402                	ld	s0,0(sp)
    80006ac4:	0141                	addi	sp,sp,16
    80006ac6:	8082                	ret

0000000080006ac8 <display_daemon>:
// Commit period: DISPLAY_DAEMON_TICKS ticks.  xv6's timer fires every
// ~1/10th of a second at QEMU's default rate, giving ~10fps.
#define DISPLAY_DAEMON_TICKS 1

void display_daemon(void)
{
    80006ac8:	7179                	addi	sp,sp,-48
    80006aca:	f406                	sd	ra,40(sp)
    80006acc:	f022                	sd	s0,32(sp)
    80006ace:	ec26                	sd	s1,24(sp)
    80006ad0:	e84a                	sd	s2,16(sp)
    80006ad2:	e44e                	sd	s3,8(sp)
    80006ad4:	1800                	addi	s0,sp,48
    // The scheduler holds p->lock across swtch into a new process.
    // Release it here, just like forkret does for user processes.
    struct proc *p = myproc();
    80006ad6:	ffffb097          	auipc	ra,0xffffb
    80006ada:	f0c080e7          	jalr	-244(ra) # 800019e2 <myproc>
    release(&p->lock);
    80006ade:	ffffa097          	auipc	ra,0xffffa
    80006ae2:	1ac080e7          	jalr	428(ra) # 80000c8a <release>

    acquire(&tickslock);
    80006ae6:	00011517          	auipc	a0,0x11
    80006aea:	afa50513          	addi	a0,a0,-1286 # 800175e0 <tickslock>
    80006aee:	ffffa097          	auipc	ra,0xffffa
    80006af2:	0e8080e7          	jalr	232(ra) # 80000bd6 <acquire>
    for (;;)
    {
        // Sleep until DISPLAY_DAEMON_TICKS ticks have elapsed.
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006af6:	00003917          	auipc	s2,0x3
    80006afa:	84a90913          	addi	s2,s2,-1974 # 80009340 <ticks>
        while (ticks < deadline)
            sleep(&ticks, &tickslock);
    80006afe:	00011497          	auipc	s1,0x11
    80006b02:	ae248493          	addi	s1,s1,-1310 # 800175e0 <tickslock>
    80006b06:	a839                	j	80006b24 <display_daemon+0x5c>

        release(&tickslock);
    80006b08:	8526                	mv	a0,s1
    80006b0a:	ffffa097          	auipc	ra,0xffffa
    80006b0e:	180080e7          	jalr	384(ra) # 80000c8a <release>
    gpu_transfer_flush();
    80006b12:	00000097          	auipc	ra,0x0
    80006b16:	aac080e7          	jalr	-1364(ra) # 800065be <gpu_transfer_flush>
        virtio_gpu_commit();
        acquire(&tickslock);
    80006b1a:	8526                	mv	a0,s1
    80006b1c:	ffffa097          	auipc	ra,0xffffa
    80006b20:	0ba080e7          	jalr	186(ra) # 80000bd6 <acquire>
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006b24:	00092783          	lw	a5,0(s2)
    80006b28:	0017899b          	addiw	s3,a5,1
        while (ticks < deadline)
    80006b2c:	fd37fee3          	bgeu	a5,s3,80006b08 <display_daemon+0x40>
            sleep(&ticks, &tickslock);
    80006b30:	85a6                	mv	a1,s1
    80006b32:	854a                	mv	a0,s2
    80006b34:	ffffb097          	auipc	ra,0xffffb
    80006b38:	5ee080e7          	jalr	1518(ra) # 80002122 <sleep>
        while (ticks < deadline)
    80006b3c:	00092783          	lw	a5,0(s2)
    80006b40:	ff37e8e3          	bltu	a5,s3,80006b30 <display_daemon+0x68>
    80006b44:	b7d1                	j	80006b08 <display_daemon+0x40>

0000000080006b46 <get_fb_addr>:
    }
}

void*
get_fb_addr(void)
{
    80006b46:	1141                	addi	sp,sp,-16
    80006b48:	e422                	sd	s0,8(sp)
    80006b4a:	0800                	addi	s0,sp,16
  return (void*)fb;
}
    80006b4c:	0001e517          	auipc	a0,0x1e
    80006b50:	52c50513          	addi	a0,a0,1324 # 80025078 <fb>
    80006b54:	6422                	ld	s0,8(sp)
    80006b56:	0141                	addi	sp,sp,16
    80006b58:	8082                	ret

0000000080006b5a <get_fb_page>:
void*
get_fb_page(int page_index)
{
    80006b5a:	1141                	addi	sp,sp,-16
    80006b5c:	e422                	sd	s0,8(sp)
    80006b5e:	0800                	addi	s0,sp,16
  if (page_index < 0 || page_index >= FB_PAGES) {
    80006b60:	12b00713          	li	a4,299
    80006b64:	00a76d63          	bltu	a4,a0,80006b7e <get_fb_page+0x24>
    return 0;
  }
  return fb[page_index]; 
    80006b68:	00351793          	slli	a5,a0,0x3
    80006b6c:	0001e717          	auipc	a4,0x1e
    80006b70:	50c70713          	addi	a4,a4,1292 # 80025078 <fb>
    80006b74:	97ba                	add	a5,a5,a4
    80006b76:	6388                	ld	a0,0(a5)
}
    80006b78:	6422                	ld	s0,8(sp)
    80006b7a:	0141                	addi	sp,sp,16
    80006b7c:	8082                	ret
    return 0;
    80006b7e:	4501                	li	a0,0
    80006b80:	bfe5                	j	80006b78 <get_fb_page+0x1e>
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
