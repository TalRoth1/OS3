
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	41013103          	ld	sp,1040(sp) # 80009410 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	41e70713          	addi	a4,a4,1054 # 80009470 <timer_scratch>
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
    80000068:	e8c78793          	addi	a5,a5,-372 # 80005ef0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd7a27>
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
    8000018e:	42650513          	addi	a0,a0,1062 # 800115b0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	41648493          	addi	s1,s1,1046 # 800115b0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	4a690913          	addi	s2,s2,1190 # 80011648 <cons+0x98>
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
    8000022a:	38a50513          	addi	a0,a0,906 # 800115b0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	37450513          	addi	a0,a0,884 # 800115b0 <cons>
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
    80000276:	3cf72b23          	sw	a5,982(a4) # 80011648 <cons+0x98>
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
    800002d0:	2e450513          	addi	a0,a0,740 # 800115b0 <cons>
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
    800002fe:	2b650513          	addi	a0,a0,694 # 800115b0 <cons>
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
    80000322:	29270713          	addi	a4,a4,658 # 800115b0 <cons>
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
    8000034c:	26878793          	addi	a5,a5,616 # 800115b0 <cons>
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
    8000037a:	2d27a783          	lw	a5,722(a5) # 80011648 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	22670713          	addi	a4,a4,550 # 800115b0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	21648493          	addi	s1,s1,534 # 800115b0 <cons>
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
    800003da:	1da70713          	addi	a4,a4,474 # 800115b0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	26f72223          	sw	a5,612(a4) # 80011650 <cons+0xa0>
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
    80000416:	19e78793          	addi	a5,a5,414 # 800115b0 <cons>
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
    8000043a:	20c7ab23          	sw	a2,534(a5) # 8001164c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	20a50513          	addi	a0,a0,522 # 80011648 <cons+0x98>
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
    80000464:	15050513          	addi	a0,a0,336 # 800115b0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	4d078793          	addi	a5,a5,1232 # 80021948 <devsw>
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
    8000054e:	1207a323          	sw	zero,294(a5) # 80011670 <pr+0x18>
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
    80000582:	eaf72923          	sw	a5,-334(a4) # 80009430 <panicked>
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
    800005be:	0b6dad83          	lw	s11,182(s11) # 80011670 <pr+0x18>
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
    800005fc:	06050513          	addi	a0,a0,96 # 80011658 <pr>
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
    8000075a:	f0250513          	addi	a0,a0,-254 # 80011658 <pr>
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
    80000776:	ee648493          	addi	s1,s1,-282 # 80011658 <pr>
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
    800007d6:	ea650513          	addi	a0,a0,-346 # 80011678 <uart_tx_lock>
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
    80000802:	c327a783          	lw	a5,-974(a5) # 80009430 <panicked>
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
    8000083a:	c027b783          	ld	a5,-1022(a5) # 80009438 <uart_tx_r>
    8000083e:	00009717          	auipc	a4,0x9
    80000842:	c0273703          	ld	a4,-1022(a4) # 80009440 <uart_tx_w>
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
    80000864:	e18a0a13          	addi	s4,s4,-488 # 80011678 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00009497          	auipc	s1,0x9
    8000086c:	bd048493          	addi	s1,s1,-1072 # 80009438 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00009997          	auipc	s3,0x9
    80000874:	bd098993          	addi	s3,s3,-1072 # 80009440 <uart_tx_w>
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
    800008d2:	daa50513          	addi	a0,a0,-598 # 80011678 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00009797          	auipc	a5,0x9
    800008e2:	b527a783          	lw	a5,-1198(a5) # 80009430 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00009717          	auipc	a4,0x9
    800008ec:	b5873703          	ld	a4,-1192(a4) # 80009440 <uart_tx_w>
    800008f0:	00009797          	auipc	a5,0x9
    800008f4:	b487b783          	ld	a5,-1208(a5) # 80009438 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00011997          	auipc	s3,0x11
    80000900:	d7c98993          	addi	s3,s3,-644 # 80011678 <uart_tx_lock>
    80000904:	00009497          	auipc	s1,0x9
    80000908:	b3448493          	addi	s1,s1,-1228 # 80009438 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00009917          	auipc	s2,0x9
    80000910:	b3490913          	addi	s2,s2,-1228 # 80009440 <uart_tx_w>
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
    80000936:	d4648493          	addi	s1,s1,-698 # 80011678 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00009797          	auipc	a5,0x9
    8000094a:	aee7bd23          	sd	a4,-1286(a5) # 80009440 <uart_tx_w>
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
    800009c0:	cbc48493          	addi	s1,s1,-836 # 80011678 <uart_tx_lock>
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
    800009fe:	00026797          	auipc	a5,0x26
    80000a02:	3da78793          	addi	a5,a5,986 # 80026dd8 <end>
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
    80000a22:	c9290913          	addi	s2,s2,-878 # 800116b0 <kmem>
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
    80000abe:	bf650513          	addi	a0,a0,-1034 # 800116b0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00026517          	auipc	a0,0x26
    80000ad2:	30a50513          	addi	a0,a0,778 # 80026dd8 <end>
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
    80000af4:	bc048493          	addi	s1,s1,-1088 # 800116b0 <kmem>
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
    80000b0c:	ba850513          	addi	a0,a0,-1112 # 800116b0 <kmem>
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
    80000b38:	b7c50513          	addi	a0,a0,-1156 # 800116b0 <kmem>
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
    80000e8c:	5c070713          	addi	a4,a4,1472 # 80009448 <started>
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
    80000eca:	06a080e7          	jalr	106(ra) # 80005f30 <plicinithart>
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
    80000f4a:	fd4080e7          	jalr	-44(ra) # 80005f1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	fe2080e7          	jalr	-30(ra) # 80005f30 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	186080e7          	jalr	390(ra) # 800030dc <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	82a080e7          	jalr	-2006(ra) # 80003788 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	7c8080e7          	jalr	1992(ra) # 8000472e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	0ca080e7          	jalr	202(ra) # 80006038 <virtio_disk_init>
    virtio_gpu_init();  // virtio GPU display window
    80000f76:	00006097          	auipc	ra,0x6
    80000f7a:	83a080e7          	jalr	-1990(ra) # 800067b0 <virtio_gpu_init>
    userinit();      // first user process
    80000f7e:	00001097          	auipc	ra,0x1
    80000f82:	d6e080e7          	jalr	-658(ra) # 80001cec <userinit>
    kproc_create(display_daemon, "displaydaemon"); // GPU auto-commit daemon
    80000f86:	00007597          	auipc	a1,0x7
    80000f8a:	13258593          	addi	a1,a1,306 # 800080b8 <digits+0x78>
    80000f8e:	00006517          	auipc	a0,0x6
    80000f92:	c4050513          	addi	a0,a0,-960 # 80006bce <display_daemon>
    80000f96:	00001097          	auipc	ra,0x1
    80000f9a:	dd8080e7          	jalr	-552(ra) # 80001d6e <kproc_create>
    __sync_synchronize();
    80000f9e:	0ff0000f          	fence
    started = 1;
    80000fa2:	4785                	li	a5,1
    80000fa4:	00008717          	auipc	a4,0x8
    80000fa8:	4af72223          	sw	a5,1188(a4) # 80009448 <started>
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
    80000fbc:	4987b783          	ld	a5,1176(a5) # 80009450 <kernel_pagetable>
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
    8000128e:	1ca7b323          	sd	a0,454(a5) # 80009450 <kernel_pagetable>
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
    80001886:	27e48493          	addi	s1,s1,638 # 80011b00 <proc>
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
    800018a0:	e64a0a13          	addi	s4,s4,-412 # 80017700 <tickslock>
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
    80001922:	db250513          	addi	a0,a0,-590 # 800116d0 <pid_lock>
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	220080e7          	jalr	544(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000192e:	00007597          	auipc	a1,0x7
    80001932:	8ca58593          	addi	a1,a1,-1846 # 800081f8 <digits+0x1b8>
    80001936:	00010517          	auipc	a0,0x10
    8000193a:	db250513          	addi	a0,a0,-590 # 800116e8 <wait_lock>
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001946:	00010497          	auipc	s1,0x10
    8000194a:	1ba48493          	addi	s1,s1,442 # 80011b00 <proc>
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
    8000196c:	d9898993          	addi	s3,s3,-616 # 80017700 <tickslock>
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
    800019d6:	d2e50513          	addi	a0,a0,-722 # 80011700 <cpus>
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
    800019fe:	cd670713          	addi	a4,a4,-810 # 800116d0 <pid_lock>
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
    80001a36:	98e7a783          	lw	a5,-1650(a5) # 800093c0 <first.1>
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
    80001a50:	9607aa23          	sw	zero,-1676(a5) # 800093c0 <first.1>
    fsinit(ROOTDEV);
    80001a54:	4505                	li	a0,1
    80001a56:	00002097          	auipc	ra,0x2
    80001a5a:	cb2080e7          	jalr	-846(ra) # 80003708 <fsinit>
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
    80001a70:	c6490913          	addi	s2,s2,-924 # 800116d0 <pid_lock>
    80001a74:	854a                	mv	a0,s2
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	160080e7          	jalr	352(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a7e:	00008797          	auipc	a5,0x8
    80001a82:	94678793          	addi	a5,a5,-1722 # 800093c4 <nextpid>
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
    80001c2e:	ed648493          	addi	s1,s1,-298 # 80011b00 <proc>
    80001c32:	00016917          	auipc	s2,0x16
    80001c36:	ace90913          	addi	s2,s2,-1330 # 80017700 <tickslock>
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
    80001d04:	74a7bc23          	sd	a0,1880(a5) # 80009458 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d08:	03400613          	li	a2,52
    80001d0c:	00007597          	auipc	a1,0x7
    80001d10:	6c458593          	addi	a1,a1,1732 # 800093d0 <initcode>
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
    80001d4e:	3e0080e7          	jalr	992(ra) # 8000412a <namei>
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
    80001ee4:	8e0080e7          	jalr	-1824(ra) # 800047c0 <filedup>
    80001ee8:	00a93023          	sd	a0,0(s2)
    80001eec:	b7e5                	j	80001ed4 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001eee:	150ab503          	ld	a0,336(s5)
    80001ef2:	00002097          	auipc	ra,0x2
    80001ef6:	a54080e7          	jalr	-1452(ra) # 80003946 <idup>
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
    80001f22:	7ca48493          	addi	s1,s1,1994 # 800116e8 <wait_lock>
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
    80001f90:	74470713          	addi	a4,a4,1860 # 800116d0 <pid_lock>
    80001f94:	9756                	add	a4,a4,s5
    80001f96:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f9a:	0000f717          	auipc	a4,0xf
    80001f9e:	76e70713          	addi	a4,a4,1902 # 80011708 <cpus+0x8>
    80001fa2:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001fa4:	498d                	li	s3,3
        p->state = RUNNING;
    80001fa6:	4b11                	li	s6,4
        c->proc = p;
    80001fa8:	079e                	slli	a5,a5,0x7
    80001faa:	0000fa17          	auipc	s4,0xf
    80001fae:	726a0a13          	addi	s4,s4,1830 # 800116d0 <pid_lock>
    80001fb2:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	00015917          	auipc	s2,0x15
    80001fb8:	74c90913          	addi	s2,s2,1868 # 80017700 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fc0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc4:	10079073          	csrw	sstatus,a5
    80001fc8:	00010497          	auipc	s1,0x10
    80001fcc:	b3848493          	addi	s1,s1,-1224 # 80011b00 <proc>
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
    8000203c:	69870713          	addi	a4,a4,1688 # 800116d0 <pid_lock>
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
    80002062:	67290913          	addi	s2,s2,1650 # 800116d0 <pid_lock>
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	97ca                	add	a5,a5,s2
    8000206c:	0ac7a983          	lw	s3,172(a5)
    80002070:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002072:	2781                	sext.w	a5,a5
    80002074:	079e                	slli	a5,a5,0x7
    80002076:	0000f597          	auipc	a1,0xf
    8000207a:	69258593          	addi	a1,a1,1682 # 80011708 <cpus+0x8>
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
    8000219e:	96648493          	addi	s1,s1,-1690 # 80011b00 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021a2:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021a4:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021a6:	00015917          	auipc	s2,0x15
    800021aa:	55a90913          	addi	s2,s2,1370 # 80017700 <tickslock>
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
    8000220e:	00010497          	auipc	s1,0x10
    80002212:	8f248493          	addi	s1,s1,-1806 # 80011b00 <proc>
      pp->parent = initproc;
    80002216:	00007a17          	auipc	s4,0x7
    8000221a:	242a0a13          	addi	s4,s4,578 # 80009458 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000221e:	00015997          	auipc	s3,0x15
    80002222:	4e298993          	addi	s3,s3,1250 # 80017700 <tickslock>
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
    80002276:	1e67b783          	ld	a5,486(a5) # 80009458 <initproc>
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
    8000229a:	57c080e7          	jalr	1404(ra) # 80004812 <fileclose>
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
    800022b2:	098080e7          	jalr	152(ra) # 80004346 <begin_op>
  iput(p->cwd);
    800022b6:	1509b503          	ld	a0,336(s3)
    800022ba:	00002097          	auipc	ra,0x2
    800022be:	884080e7          	jalr	-1916(ra) # 80003b3e <iput>
  end_op();
    800022c2:	00002097          	auipc	ra,0x2
    800022c6:	104080e7          	jalr	260(ra) # 800043c6 <end_op>
  p->cwd = 0;
    800022ca:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022ce:	0000f497          	auipc	s1,0xf
    800022d2:	41a48493          	addi	s1,s1,1050 # 800116e8 <wait_lock>
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
    80002340:	7c448493          	addi	s1,s1,1988 # 80011b00 <proc>
    80002344:	00015997          	auipc	s3,0x15
    80002348:	3bc98993          	addi	s3,s3,956 # 80017700 <tickslock>
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
    80002424:	2c850513          	addi	a0,a0,712 # 800116e8 <wait_lock>
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
    8000243a:	2ca98993          	addi	s3,s3,714 # 80017700 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000243e:	0000fc17          	auipc	s8,0xf
    80002442:	2aac0c13          	addi	s8,s8,682 # 800116e8 <wait_lock>
    havekids = 0;
    80002446:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002448:	0000f497          	auipc	s1,0xf
    8000244c:	6b848493          	addi	s1,s1,1720 # 80011b00 <proc>
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
    8000248a:	26250513          	addi	a0,a0,610 # 800116e8 <wait_lock>
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
    800024a6:	24650513          	addi	a0,a0,582 # 800116e8 <wait_lock>
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
    800024f4:	1f850513          	addi	a0,a0,504 # 800116e8 <wait_lock>
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
    80002600:	65c48493          	addi	s1,s1,1628 # 80011c58 <proc+0x158>
    80002604:	00015917          	auipc	s2,0x15
    80002608:	25490913          	addi	s2,s2,596 # 80017858 <bcache+0x140>
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
    80002754:	510080e7          	jalr	1296(ra) # 80006c60 <get_fb_page>
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
    8000286a:	e9a50513          	addi	a0,a0,-358 # 80017700 <tickslock>
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
    80002888:	5dc78793          	addi	a5,a5,1500 # 80005e60 <kernelvec>
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
    8000293a:	dca48493          	addi	s1,s1,-566 # 80017700 <tickslock>
    8000293e:	8526                	mv	a0,s1
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	296080e7          	jalr	662(ra) # 80000bd6 <acquire>
  ticks++;
    80002948:	00007517          	auipc	a0,0x7
    8000294c:	b1850513          	addi	a0,a0,-1256 # 80009460 <ticks>
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
    800029a8:	5c4080e7          	jalr	1476(ra) # 80005f68 <plic_claim>
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
    800029d6:	5ba080e7          	jalr	1466(ra) # 80005f8c <plic_complete>
    return 1;
    800029da:	4505                	li	a0,1
    800029dc:	bf55                	j	80002990 <devintr+0x1e>
      uartintr();
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	fbc080e7          	jalr	-68(ra) # 8000099a <uartintr>
    800029e6:	b7ed                	j	800029d0 <devintr+0x5e>
      virtio_disk_intr();
    800029e8:	00004097          	auipc	ra,0x4
    800029ec:	a70080e7          	jalr	-1424(ra) # 80006458 <virtio_disk_intr>
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
    80002a2e:	43678793          	addi	a5,a5,1078 # 80005e60 <kernelvec>
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
    80002ec0:	00015517          	auipc	a0,0x15
    80002ec4:	84050513          	addi	a0,a0,-1984 # 80017700 <tickslock>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	d0e080e7          	jalr	-754(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002ed0:	00006917          	auipc	s2,0x6
    80002ed4:	59092903          	lw	s2,1424(s2) # 80009460 <ticks>
  while(ticks - ticks0 < n){
    80002ed8:	fcc42783          	lw	a5,-52(s0)
    80002edc:	cf9d                	beqz	a5,80002f1a <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ede:	00015997          	auipc	s3,0x15
    80002ee2:	82298993          	addi	s3,s3,-2014 # 80017700 <tickslock>
    80002ee6:	00006497          	auipc	s1,0x6
    80002eea:	57a48493          	addi	s1,s1,1402 # 80009460 <ticks>
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
    80002f1e:	7e650513          	addi	a0,a0,2022 # 80017700 <tickslock>
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
    80002f3e:	7c650513          	addi	a0,a0,1990 # 80017700 <tickslock>
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
    80002f86:	77e50513          	addi	a0,a0,1918 # 80017700 <tickslock>
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	c4c080e7          	jalr	-948(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002f92:	00006497          	auipc	s1,0x6
    80002f96:	4ce4a483          	lw	s1,1230(s1) # 80009460 <ticks>
  release(&tickslock);
    80002f9a:	00014517          	auipc	a0,0x14
    80002f9e:	76650513          	addi	a0,a0,1894 # 80017700 <tickslock>
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
    80002fba:	7139                	addi	sp,sp,-64
    80002fbc:	fc06                	sd	ra,56(sp)
    80002fbe:	f822                	sd	s0,48(sp)
    80002fc0:	f426                	sd	s1,40(sp)
    80002fc2:	f04a                	sd	s2,32(sp)
    80002fc4:	ec4e                	sd	s3,24(sp)
    80002fc6:	e852                	sd	s4,16(sp)
    80002fc8:	0080                	addi	s0,sp,64
  printf("sys_flip_display called\n");
    80002fca:	00005517          	auipc	a0,0x5
    80002fce:	61650513          	addi	a0,a0,1558 # 800085e0 <syscalls+0xc0>
    80002fd2:	ffffd097          	auipc	ra,0xffffd
    80002fd6:	5b6080e7          	jalr	1462(ra) # 80000588 <printf>
  uint64 buf;
  argaddr(0, &buf);
    80002fda:	fc840593          	addi	a1,s0,-56
    80002fde:	4501                	li	a0,0
    80002fe0:	00000097          	auipc	ra,0x0
    80002fe4:	d36080e7          	jalr	-714(ra) # 80002d16 <argaddr>
  if (buf % 4096 != 0){
    80002fe8:	fc843783          	ld	a5,-56(s0)
    80002fec:	17d2                	slli	a5,a5,0x34
    80002fee:	0347d493          	srli	s1,a5,0x34
    pte_t *pte = walk(myproc()->pagetable, buf + i*PGSIZE, 0);
    if(pte == 0 || (*pte & PTE_V) == 0){
      printf("sys_flip_display: buffer not fully mapped\n");
      return -1;
    }
    if((*pte & PTE_U) == 0 || (*pte & PTE_R) == 0 || (*pte & PTE_W) == 0){
    80002ff2:	4959                	li	s2,22
  for(int i = 0; i < GPU_FB_PAGES; i++){
    80002ff4:	6a05                	lui	s4,0x1
    80002ff6:	0012c9b7          	lui	s3,0x12c
  if (buf % 4096 != 0){
    80002ffa:	eba1                	bnez	a5,8000304a <sys_flip_display+0x90>
    pte_t *pte = walk(myproc()->pagetable, buf + i*PGSIZE, 0);
    80002ffc:	fffff097          	auipc	ra,0xfffff
    80003000:	9e6080e7          	jalr	-1562(ra) # 800019e2 <myproc>
    80003004:	4601                	li	a2,0
    80003006:	fc843583          	ld	a1,-56(s0)
    8000300a:	95a6                	add	a1,a1,s1
    8000300c:	6928                	ld	a0,80(a0)
    8000300e:	ffffe097          	auipc	ra,0xffffe
    80003012:	fc8080e7          	jalr	-56(ra) # 80000fd6 <walk>
    if(pte == 0 || (*pte & PTE_V) == 0){
    80003016:	c521                	beqz	a0,8000305e <sys_flip_display+0xa4>
    80003018:	611c                	ld	a5,0(a0)
    8000301a:	0017f713          	andi	a4,a5,1
    8000301e:	c321                	beqz	a4,8000305e <sys_flip_display+0xa4>
    if((*pte & PTE_U) == 0 || (*pte & PTE_R) == 0 || (*pte & PTE_W) == 0){
    80003020:	8bd9                	andi	a5,a5,22
    80003022:	05279f63          	bne	a5,s2,80003080 <sys_flip_display+0xc6>
  for(int i = 0; i < GPU_FB_PAGES; i++){
    80003026:	94d2                	add	s1,s1,s4
    80003028:	fd349ae3          	bne	s1,s3,80002ffc <sys_flip_display+0x42>
      printf("sys_flip_display: buffer not mapped with PTE_U|PTE_R|PTE_W\n");
      return -1;
    }
  }
  printf("sys_flip_display: buffer looks good, flipping display\n");
    8000302c:	00005517          	auipc	a0,0x5
    80003030:	67450513          	addi	a0,a0,1652 # 800086a0 <syscalls+0x180>
    80003034:	ffffd097          	auipc	ra,0xffffd
    80003038:	554080e7          	jalr	1364(ra) # 80000588 <printf>
  return virtio_gpu_flip(buf);
    8000303c:	fc843503          	ld	a0,-56(s0)
    80003040:	00004097          	auipc	ra,0x4
    80003044:	cc8080e7          	jalr	-824(ra) # 80006d08 <virtio_gpu_flip>
    80003048:	a025                	j	80003070 <sys_flip_display+0xb6>
    printf("sys_flip_display: buffer not page-aligned\n");
    8000304a:	00005517          	auipc	a0,0x5
    8000304e:	5b650513          	addi	a0,a0,1462 # 80008600 <syscalls+0xe0>
    80003052:	ffffd097          	auipc	ra,0xffffd
    80003056:	536080e7          	jalr	1334(ra) # 80000588 <printf>
    return -1;
    8000305a:	557d                	li	a0,-1
    8000305c:	a811                	j	80003070 <sys_flip_display+0xb6>
      printf("sys_flip_display: buffer not fully mapped\n");
    8000305e:	00005517          	auipc	a0,0x5
    80003062:	5d250513          	addi	a0,a0,1490 # 80008630 <syscalls+0x110>
    80003066:	ffffd097          	auipc	ra,0xffffd
    8000306a:	522080e7          	jalr	1314(ra) # 80000588 <printf>
      return -1;
    8000306e:	557d                	li	a0,-1
  // return 1;
}
    80003070:	70e2                	ld	ra,56(sp)
    80003072:	7442                	ld	s0,48(sp)
    80003074:	74a2                	ld	s1,40(sp)
    80003076:	7902                	ld	s2,32(sp)
    80003078:	69e2                	ld	s3,24(sp)
    8000307a:	6a42                	ld	s4,16(sp)
    8000307c:	6121                	addi	sp,sp,64
    8000307e:	8082                	ret
      printf("sys_flip_display: buffer not mapped with PTE_U|PTE_R|PTE_W\n");
    80003080:	00005517          	auipc	a0,0x5
    80003084:	5e050513          	addi	a0,a0,1504 # 80008660 <syscalls+0x140>
    80003088:	ffffd097          	auipc	ra,0xffffd
    8000308c:	500080e7          	jalr	1280(ra) # 80000588 <printf>
      return -1;
    80003090:	557d                	li	a0,-1
    80003092:	bff9                	j	80003070 <sys_flip_display+0xb6>

0000000080003094 <sys_map_display>:
// Returns the mapped virtual address on success, (uint64)-1 on failure.
//
// TODO: Students implement this syscall.
uint64
sys_map_display(void)
{
    80003094:	7179                	addi	sp,sp,-48
    80003096:	f406                	sd	ra,40(sp)
    80003098:	f022                	sd	s0,32(sp)
    8000309a:	ec26                	sd	s1,24(sp)
    8000309c:	1800                	addi	s0,sp,48
  uint64 addr;
  argaddr(0, &addr);
    8000309e:	fd840593          	addi	a1,s0,-40
    800030a2:	4501                	li	a0,0
    800030a4:	00000097          	auipc	ra,0x0
    800030a8:	c72080e7          	jalr	-910(ra) # 80002d16 <argaddr>
  uint64 answer = (uint64)map_display((void*)addr);
    800030ac:	fd843503          	ld	a0,-40(s0)
    800030b0:	fffff097          	auipc	ra,0xfffff
    800030b4:	5d4080e7          	jalr	1492(ra) # 80002684 <map_display>
    800030b8:	84aa                	mv	s1,a0
  printf("sys_map_display: addr=0x%p, answer=0x%p\n", addr, answer);
    800030ba:	862a                	mv	a2,a0
    800030bc:	fd843583          	ld	a1,-40(s0)
    800030c0:	00005517          	auipc	a0,0x5
    800030c4:	61850513          	addi	a0,a0,1560 # 800086d8 <syscalls+0x1b8>
    800030c8:	ffffd097          	auipc	ra,0xffffd
    800030cc:	4c0080e7          	jalr	1216(ra) # 80000588 <printf>
  return answer;
  
}
    800030d0:	8526                	mv	a0,s1
    800030d2:	70a2                	ld	ra,40(sp)
    800030d4:	7402                	ld	s0,32(sp)
    800030d6:	64e2                	ld	s1,24(sp)
    800030d8:	6145                	addi	sp,sp,48
    800030da:	8082                	ret

00000000800030dc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030dc:	7179                	addi	sp,sp,-48
    800030de:	f406                	sd	ra,40(sp)
    800030e0:	f022                	sd	s0,32(sp)
    800030e2:	ec26                	sd	s1,24(sp)
    800030e4:	e84a                	sd	s2,16(sp)
    800030e6:	e44e                	sd	s3,8(sp)
    800030e8:	e052                	sd	s4,0(sp)
    800030ea:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030ec:	00005597          	auipc	a1,0x5
    800030f0:	61c58593          	addi	a1,a1,1564 # 80008708 <syscalls+0x1e8>
    800030f4:	00014517          	auipc	a0,0x14
    800030f8:	62450513          	addi	a0,a0,1572 # 80017718 <bcache>
    800030fc:	ffffe097          	auipc	ra,0xffffe
    80003100:	a4a080e7          	jalr	-1462(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003104:	0001c797          	auipc	a5,0x1c
    80003108:	61478793          	addi	a5,a5,1556 # 8001f718 <bcache+0x8000>
    8000310c:	0001d717          	auipc	a4,0x1d
    80003110:	87470713          	addi	a4,a4,-1932 # 8001f980 <bcache+0x8268>
    80003114:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003118:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000311c:	00014497          	auipc	s1,0x14
    80003120:	61448493          	addi	s1,s1,1556 # 80017730 <bcache+0x18>
    b->next = bcache.head.next;
    80003124:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003126:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003128:	00005a17          	auipc	s4,0x5
    8000312c:	5e8a0a13          	addi	s4,s4,1512 # 80008710 <syscalls+0x1f0>
    b->next = bcache.head.next;
    80003130:	2b893783          	ld	a5,696(s2)
    80003134:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003136:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000313a:	85d2                	mv	a1,s4
    8000313c:	01048513          	addi	a0,s1,16
    80003140:	00001097          	auipc	ra,0x1
    80003144:	4c4080e7          	jalr	1220(ra) # 80004604 <initsleeplock>
    bcache.head.next->prev = b;
    80003148:	2b893783          	ld	a5,696(s2)
    8000314c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000314e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003152:	45848493          	addi	s1,s1,1112
    80003156:	fd349de3          	bne	s1,s3,80003130 <binit+0x54>
  }
}
    8000315a:	70a2                	ld	ra,40(sp)
    8000315c:	7402                	ld	s0,32(sp)
    8000315e:	64e2                	ld	s1,24(sp)
    80003160:	6942                	ld	s2,16(sp)
    80003162:	69a2                	ld	s3,8(sp)
    80003164:	6a02                	ld	s4,0(sp)
    80003166:	6145                	addi	sp,sp,48
    80003168:	8082                	ret

000000008000316a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000316a:	7179                	addi	sp,sp,-48
    8000316c:	f406                	sd	ra,40(sp)
    8000316e:	f022                	sd	s0,32(sp)
    80003170:	ec26                	sd	s1,24(sp)
    80003172:	e84a                	sd	s2,16(sp)
    80003174:	e44e                	sd	s3,8(sp)
    80003176:	1800                	addi	s0,sp,48
    80003178:	892a                	mv	s2,a0
    8000317a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000317c:	00014517          	auipc	a0,0x14
    80003180:	59c50513          	addi	a0,a0,1436 # 80017718 <bcache>
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	a52080e7          	jalr	-1454(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000318c:	0001d497          	auipc	s1,0x1d
    80003190:	8444b483          	ld	s1,-1980(s1) # 8001f9d0 <bcache+0x82b8>
    80003194:	0001c797          	auipc	a5,0x1c
    80003198:	7ec78793          	addi	a5,a5,2028 # 8001f980 <bcache+0x8268>
    8000319c:	02f48f63          	beq	s1,a5,800031da <bread+0x70>
    800031a0:	873e                	mv	a4,a5
    800031a2:	a021                	j	800031aa <bread+0x40>
    800031a4:	68a4                	ld	s1,80(s1)
    800031a6:	02e48a63          	beq	s1,a4,800031da <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031aa:	449c                	lw	a5,8(s1)
    800031ac:	ff279ce3          	bne	a5,s2,800031a4 <bread+0x3a>
    800031b0:	44dc                	lw	a5,12(s1)
    800031b2:	ff3799e3          	bne	a5,s3,800031a4 <bread+0x3a>
      b->refcnt++;
    800031b6:	40bc                	lw	a5,64(s1)
    800031b8:	2785                	addiw	a5,a5,1
    800031ba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031bc:	00014517          	auipc	a0,0x14
    800031c0:	55c50513          	addi	a0,a0,1372 # 80017718 <bcache>
    800031c4:	ffffe097          	auipc	ra,0xffffe
    800031c8:	ac6080e7          	jalr	-1338(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800031cc:	01048513          	addi	a0,s1,16
    800031d0:	00001097          	auipc	ra,0x1
    800031d4:	46e080e7          	jalr	1134(ra) # 8000463e <acquiresleep>
      return b;
    800031d8:	a8b9                	j	80003236 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031da:	0001c497          	auipc	s1,0x1c
    800031de:	7ee4b483          	ld	s1,2030(s1) # 8001f9c8 <bcache+0x82b0>
    800031e2:	0001c797          	auipc	a5,0x1c
    800031e6:	79e78793          	addi	a5,a5,1950 # 8001f980 <bcache+0x8268>
    800031ea:	00f48863          	beq	s1,a5,800031fa <bread+0x90>
    800031ee:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031f0:	40bc                	lw	a5,64(s1)
    800031f2:	cf81                	beqz	a5,8000320a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031f4:	64a4                	ld	s1,72(s1)
    800031f6:	fee49de3          	bne	s1,a4,800031f0 <bread+0x86>
  panic("bget: no buffers");
    800031fa:	00005517          	auipc	a0,0x5
    800031fe:	51e50513          	addi	a0,a0,1310 # 80008718 <syscalls+0x1f8>
    80003202:	ffffd097          	auipc	ra,0xffffd
    80003206:	33c080e7          	jalr	828(ra) # 8000053e <panic>
      b->dev = dev;
    8000320a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000320e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003212:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003216:	4785                	li	a5,1
    80003218:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000321a:	00014517          	auipc	a0,0x14
    8000321e:	4fe50513          	addi	a0,a0,1278 # 80017718 <bcache>
    80003222:	ffffe097          	auipc	ra,0xffffe
    80003226:	a68080e7          	jalr	-1432(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000322a:	01048513          	addi	a0,s1,16
    8000322e:	00001097          	auipc	ra,0x1
    80003232:	410080e7          	jalr	1040(ra) # 8000463e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003236:	409c                	lw	a5,0(s1)
    80003238:	cb89                	beqz	a5,8000324a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000323a:	8526                	mv	a0,s1
    8000323c:	70a2                	ld	ra,40(sp)
    8000323e:	7402                	ld	s0,32(sp)
    80003240:	64e2                	ld	s1,24(sp)
    80003242:	6942                	ld	s2,16(sp)
    80003244:	69a2                	ld	s3,8(sp)
    80003246:	6145                	addi	sp,sp,48
    80003248:	8082                	ret
    virtio_disk_rw(b, 0);
    8000324a:	4581                	li	a1,0
    8000324c:	8526                	mv	a0,s1
    8000324e:	00003097          	auipc	ra,0x3
    80003252:	fd6080e7          	jalr	-42(ra) # 80006224 <virtio_disk_rw>
    b->valid = 1;
    80003256:	4785                	li	a5,1
    80003258:	c09c                	sw	a5,0(s1)
  return b;
    8000325a:	b7c5                	j	8000323a <bread+0xd0>

000000008000325c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000325c:	1101                	addi	sp,sp,-32
    8000325e:	ec06                	sd	ra,24(sp)
    80003260:	e822                	sd	s0,16(sp)
    80003262:	e426                	sd	s1,8(sp)
    80003264:	1000                	addi	s0,sp,32
    80003266:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003268:	0541                	addi	a0,a0,16
    8000326a:	00001097          	auipc	ra,0x1
    8000326e:	46e080e7          	jalr	1134(ra) # 800046d8 <holdingsleep>
    80003272:	cd01                	beqz	a0,8000328a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003274:	4585                	li	a1,1
    80003276:	8526                	mv	a0,s1
    80003278:	00003097          	auipc	ra,0x3
    8000327c:	fac080e7          	jalr	-84(ra) # 80006224 <virtio_disk_rw>
}
    80003280:	60e2                	ld	ra,24(sp)
    80003282:	6442                	ld	s0,16(sp)
    80003284:	64a2                	ld	s1,8(sp)
    80003286:	6105                	addi	sp,sp,32
    80003288:	8082                	ret
    panic("bwrite");
    8000328a:	00005517          	auipc	a0,0x5
    8000328e:	4a650513          	addi	a0,a0,1190 # 80008730 <syscalls+0x210>
    80003292:	ffffd097          	auipc	ra,0xffffd
    80003296:	2ac080e7          	jalr	684(ra) # 8000053e <panic>

000000008000329a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000329a:	1101                	addi	sp,sp,-32
    8000329c:	ec06                	sd	ra,24(sp)
    8000329e:	e822                	sd	s0,16(sp)
    800032a0:	e426                	sd	s1,8(sp)
    800032a2:	e04a                	sd	s2,0(sp)
    800032a4:	1000                	addi	s0,sp,32
    800032a6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032a8:	01050913          	addi	s2,a0,16
    800032ac:	854a                	mv	a0,s2
    800032ae:	00001097          	auipc	ra,0x1
    800032b2:	42a080e7          	jalr	1066(ra) # 800046d8 <holdingsleep>
    800032b6:	c92d                	beqz	a0,80003328 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032b8:	854a                	mv	a0,s2
    800032ba:	00001097          	auipc	ra,0x1
    800032be:	3da080e7          	jalr	986(ra) # 80004694 <releasesleep>

  acquire(&bcache.lock);
    800032c2:	00014517          	auipc	a0,0x14
    800032c6:	45650513          	addi	a0,a0,1110 # 80017718 <bcache>
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	90c080e7          	jalr	-1780(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800032d2:	40bc                	lw	a5,64(s1)
    800032d4:	37fd                	addiw	a5,a5,-1
    800032d6:	0007871b          	sext.w	a4,a5
    800032da:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032dc:	eb05                	bnez	a4,8000330c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032de:	68bc                	ld	a5,80(s1)
    800032e0:	64b8                	ld	a4,72(s1)
    800032e2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032e4:	64bc                	ld	a5,72(s1)
    800032e6:	68b8                	ld	a4,80(s1)
    800032e8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032ea:	0001c797          	auipc	a5,0x1c
    800032ee:	42e78793          	addi	a5,a5,1070 # 8001f718 <bcache+0x8000>
    800032f2:	2b87b703          	ld	a4,696(a5)
    800032f6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032f8:	0001c717          	auipc	a4,0x1c
    800032fc:	68870713          	addi	a4,a4,1672 # 8001f980 <bcache+0x8268>
    80003300:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003302:	2b87b703          	ld	a4,696(a5)
    80003306:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003308:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000330c:	00014517          	auipc	a0,0x14
    80003310:	40c50513          	addi	a0,a0,1036 # 80017718 <bcache>
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	976080e7          	jalr	-1674(ra) # 80000c8a <release>
}
    8000331c:	60e2                	ld	ra,24(sp)
    8000331e:	6442                	ld	s0,16(sp)
    80003320:	64a2                	ld	s1,8(sp)
    80003322:	6902                	ld	s2,0(sp)
    80003324:	6105                	addi	sp,sp,32
    80003326:	8082                	ret
    panic("brelse");
    80003328:	00005517          	auipc	a0,0x5
    8000332c:	41050513          	addi	a0,a0,1040 # 80008738 <syscalls+0x218>
    80003330:	ffffd097          	auipc	ra,0xffffd
    80003334:	20e080e7          	jalr	526(ra) # 8000053e <panic>

0000000080003338 <bpin>:

void
bpin(struct buf *b) {
    80003338:	1101                	addi	sp,sp,-32
    8000333a:	ec06                	sd	ra,24(sp)
    8000333c:	e822                	sd	s0,16(sp)
    8000333e:	e426                	sd	s1,8(sp)
    80003340:	1000                	addi	s0,sp,32
    80003342:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003344:	00014517          	auipc	a0,0x14
    80003348:	3d450513          	addi	a0,a0,980 # 80017718 <bcache>
    8000334c:	ffffe097          	auipc	ra,0xffffe
    80003350:	88a080e7          	jalr	-1910(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003354:	40bc                	lw	a5,64(s1)
    80003356:	2785                	addiw	a5,a5,1
    80003358:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000335a:	00014517          	auipc	a0,0x14
    8000335e:	3be50513          	addi	a0,a0,958 # 80017718 <bcache>
    80003362:	ffffe097          	auipc	ra,0xffffe
    80003366:	928080e7          	jalr	-1752(ra) # 80000c8a <release>
}
    8000336a:	60e2                	ld	ra,24(sp)
    8000336c:	6442                	ld	s0,16(sp)
    8000336e:	64a2                	ld	s1,8(sp)
    80003370:	6105                	addi	sp,sp,32
    80003372:	8082                	ret

0000000080003374 <bunpin>:

void
bunpin(struct buf *b) {
    80003374:	1101                	addi	sp,sp,-32
    80003376:	ec06                	sd	ra,24(sp)
    80003378:	e822                	sd	s0,16(sp)
    8000337a:	e426                	sd	s1,8(sp)
    8000337c:	1000                	addi	s0,sp,32
    8000337e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003380:	00014517          	auipc	a0,0x14
    80003384:	39850513          	addi	a0,a0,920 # 80017718 <bcache>
    80003388:	ffffe097          	auipc	ra,0xffffe
    8000338c:	84e080e7          	jalr	-1970(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003390:	40bc                	lw	a5,64(s1)
    80003392:	37fd                	addiw	a5,a5,-1
    80003394:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003396:	00014517          	auipc	a0,0x14
    8000339a:	38250513          	addi	a0,a0,898 # 80017718 <bcache>
    8000339e:	ffffe097          	auipc	ra,0xffffe
    800033a2:	8ec080e7          	jalr	-1812(ra) # 80000c8a <release>
}
    800033a6:	60e2                	ld	ra,24(sp)
    800033a8:	6442                	ld	s0,16(sp)
    800033aa:	64a2                	ld	s1,8(sp)
    800033ac:	6105                	addi	sp,sp,32
    800033ae:	8082                	ret

00000000800033b0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033b0:	1101                	addi	sp,sp,-32
    800033b2:	ec06                	sd	ra,24(sp)
    800033b4:	e822                	sd	s0,16(sp)
    800033b6:	e426                	sd	s1,8(sp)
    800033b8:	e04a                	sd	s2,0(sp)
    800033ba:	1000                	addi	s0,sp,32
    800033bc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033be:	00d5d59b          	srliw	a1,a1,0xd
    800033c2:	0001d797          	auipc	a5,0x1d
    800033c6:	a327a783          	lw	a5,-1486(a5) # 8001fdf4 <sb+0x1c>
    800033ca:	9dbd                	addw	a1,a1,a5
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	d9e080e7          	jalr	-610(ra) # 8000316a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033d4:	0074f713          	andi	a4,s1,7
    800033d8:	4785                	li	a5,1
    800033da:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033de:	14ce                	slli	s1,s1,0x33
    800033e0:	90d9                	srli	s1,s1,0x36
    800033e2:	00950733          	add	a4,a0,s1
    800033e6:	05874703          	lbu	a4,88(a4)
    800033ea:	00e7f6b3          	and	a3,a5,a4
    800033ee:	c69d                	beqz	a3,8000341c <bfree+0x6c>
    800033f0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033f2:	94aa                	add	s1,s1,a0
    800033f4:	fff7c793          	not	a5,a5
    800033f8:	8ff9                	and	a5,a5,a4
    800033fa:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033fe:	00001097          	auipc	ra,0x1
    80003402:	120080e7          	jalr	288(ra) # 8000451e <log_write>
  brelse(bp);
    80003406:	854a                	mv	a0,s2
    80003408:	00000097          	auipc	ra,0x0
    8000340c:	e92080e7          	jalr	-366(ra) # 8000329a <brelse>
}
    80003410:	60e2                	ld	ra,24(sp)
    80003412:	6442                	ld	s0,16(sp)
    80003414:	64a2                	ld	s1,8(sp)
    80003416:	6902                	ld	s2,0(sp)
    80003418:	6105                	addi	sp,sp,32
    8000341a:	8082                	ret
    panic("freeing free block");
    8000341c:	00005517          	auipc	a0,0x5
    80003420:	32450513          	addi	a0,a0,804 # 80008740 <syscalls+0x220>
    80003424:	ffffd097          	auipc	ra,0xffffd
    80003428:	11a080e7          	jalr	282(ra) # 8000053e <panic>

000000008000342c <balloc>:
{
    8000342c:	711d                	addi	sp,sp,-96
    8000342e:	ec86                	sd	ra,88(sp)
    80003430:	e8a2                	sd	s0,80(sp)
    80003432:	e4a6                	sd	s1,72(sp)
    80003434:	e0ca                	sd	s2,64(sp)
    80003436:	fc4e                	sd	s3,56(sp)
    80003438:	f852                	sd	s4,48(sp)
    8000343a:	f456                	sd	s5,40(sp)
    8000343c:	f05a                	sd	s6,32(sp)
    8000343e:	ec5e                	sd	s7,24(sp)
    80003440:	e862                	sd	s8,16(sp)
    80003442:	e466                	sd	s9,8(sp)
    80003444:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003446:	0001d797          	auipc	a5,0x1d
    8000344a:	9967a783          	lw	a5,-1642(a5) # 8001fddc <sb+0x4>
    8000344e:	10078163          	beqz	a5,80003550 <balloc+0x124>
    80003452:	8baa                	mv	s7,a0
    80003454:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003456:	0001db17          	auipc	s6,0x1d
    8000345a:	982b0b13          	addi	s6,s6,-1662 # 8001fdd8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003460:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003462:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003464:	6c89                	lui	s9,0x2
    80003466:	a061                	j	800034ee <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003468:	974a                	add	a4,a4,s2
    8000346a:	8fd5                	or	a5,a5,a3
    8000346c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003470:	854a                	mv	a0,s2
    80003472:	00001097          	auipc	ra,0x1
    80003476:	0ac080e7          	jalr	172(ra) # 8000451e <log_write>
        brelse(bp);
    8000347a:	854a                	mv	a0,s2
    8000347c:	00000097          	auipc	ra,0x0
    80003480:	e1e080e7          	jalr	-482(ra) # 8000329a <brelse>
  bp = bread(dev, bno);
    80003484:	85a6                	mv	a1,s1
    80003486:	855e                	mv	a0,s7
    80003488:	00000097          	auipc	ra,0x0
    8000348c:	ce2080e7          	jalr	-798(ra) # 8000316a <bread>
    80003490:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003492:	40000613          	li	a2,1024
    80003496:	4581                	li	a1,0
    80003498:	05850513          	addi	a0,a0,88
    8000349c:	ffffe097          	auipc	ra,0xffffe
    800034a0:	836080e7          	jalr	-1994(ra) # 80000cd2 <memset>
  log_write(bp);
    800034a4:	854a                	mv	a0,s2
    800034a6:	00001097          	auipc	ra,0x1
    800034aa:	078080e7          	jalr	120(ra) # 8000451e <log_write>
  brelse(bp);
    800034ae:	854a                	mv	a0,s2
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	dea080e7          	jalr	-534(ra) # 8000329a <brelse>
}
    800034b8:	8526                	mv	a0,s1
    800034ba:	60e6                	ld	ra,88(sp)
    800034bc:	6446                	ld	s0,80(sp)
    800034be:	64a6                	ld	s1,72(sp)
    800034c0:	6906                	ld	s2,64(sp)
    800034c2:	79e2                	ld	s3,56(sp)
    800034c4:	7a42                	ld	s4,48(sp)
    800034c6:	7aa2                	ld	s5,40(sp)
    800034c8:	7b02                	ld	s6,32(sp)
    800034ca:	6be2                	ld	s7,24(sp)
    800034cc:	6c42                	ld	s8,16(sp)
    800034ce:	6ca2                	ld	s9,8(sp)
    800034d0:	6125                	addi	sp,sp,96
    800034d2:	8082                	ret
    brelse(bp);
    800034d4:	854a                	mv	a0,s2
    800034d6:	00000097          	auipc	ra,0x0
    800034da:	dc4080e7          	jalr	-572(ra) # 8000329a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034de:	015c87bb          	addw	a5,s9,s5
    800034e2:	00078a9b          	sext.w	s5,a5
    800034e6:	004b2703          	lw	a4,4(s6)
    800034ea:	06eaf363          	bgeu	s5,a4,80003550 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800034ee:	41fad79b          	sraiw	a5,s5,0x1f
    800034f2:	0137d79b          	srliw	a5,a5,0x13
    800034f6:	015787bb          	addw	a5,a5,s5
    800034fa:	40d7d79b          	sraiw	a5,a5,0xd
    800034fe:	01cb2583          	lw	a1,28(s6)
    80003502:	9dbd                	addw	a1,a1,a5
    80003504:	855e                	mv	a0,s7
    80003506:	00000097          	auipc	ra,0x0
    8000350a:	c64080e7          	jalr	-924(ra) # 8000316a <bread>
    8000350e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003510:	004b2503          	lw	a0,4(s6)
    80003514:	000a849b          	sext.w	s1,s5
    80003518:	8662                	mv	a2,s8
    8000351a:	faa4fde3          	bgeu	s1,a0,800034d4 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000351e:	41f6579b          	sraiw	a5,a2,0x1f
    80003522:	01d7d69b          	srliw	a3,a5,0x1d
    80003526:	00c6873b          	addw	a4,a3,a2
    8000352a:	00777793          	andi	a5,a4,7
    8000352e:	9f95                	subw	a5,a5,a3
    80003530:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003534:	4037571b          	sraiw	a4,a4,0x3
    80003538:	00e906b3          	add	a3,s2,a4
    8000353c:	0586c683          	lbu	a3,88(a3)
    80003540:	00d7f5b3          	and	a1,a5,a3
    80003544:	d195                	beqz	a1,80003468 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003546:	2605                	addiw	a2,a2,1
    80003548:	2485                	addiw	s1,s1,1
    8000354a:	fd4618e3          	bne	a2,s4,8000351a <balloc+0xee>
    8000354e:	b759                	j	800034d4 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003550:	00005517          	auipc	a0,0x5
    80003554:	20850513          	addi	a0,a0,520 # 80008758 <syscalls+0x238>
    80003558:	ffffd097          	auipc	ra,0xffffd
    8000355c:	030080e7          	jalr	48(ra) # 80000588 <printf>
  return 0;
    80003560:	4481                	li	s1,0
    80003562:	bf99                	j	800034b8 <balloc+0x8c>

0000000080003564 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003564:	7179                	addi	sp,sp,-48
    80003566:	f406                	sd	ra,40(sp)
    80003568:	f022                	sd	s0,32(sp)
    8000356a:	ec26                	sd	s1,24(sp)
    8000356c:	e84a                	sd	s2,16(sp)
    8000356e:	e44e                	sd	s3,8(sp)
    80003570:	e052                	sd	s4,0(sp)
    80003572:	1800                	addi	s0,sp,48
    80003574:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003576:	47ad                	li	a5,11
    80003578:	02b7e763          	bltu	a5,a1,800035a6 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000357c:	02059493          	slli	s1,a1,0x20
    80003580:	9081                	srli	s1,s1,0x20
    80003582:	048a                	slli	s1,s1,0x2
    80003584:	94aa                	add	s1,s1,a0
    80003586:	0504a903          	lw	s2,80(s1)
    8000358a:	06091e63          	bnez	s2,80003606 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000358e:	4108                	lw	a0,0(a0)
    80003590:	00000097          	auipc	ra,0x0
    80003594:	e9c080e7          	jalr	-356(ra) # 8000342c <balloc>
    80003598:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000359c:	06090563          	beqz	s2,80003606 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800035a0:	0524a823          	sw	s2,80(s1)
    800035a4:	a08d                	j	80003606 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800035a6:	ff45849b          	addiw	s1,a1,-12
    800035aa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035ae:	0ff00793          	li	a5,255
    800035b2:	08e7e563          	bltu	a5,a4,8000363c <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800035b6:	08052903          	lw	s2,128(a0)
    800035ba:	00091d63          	bnez	s2,800035d4 <bmap+0x70>
      addr = balloc(ip->dev);
    800035be:	4108                	lw	a0,0(a0)
    800035c0:	00000097          	auipc	ra,0x0
    800035c4:	e6c080e7          	jalr	-404(ra) # 8000342c <balloc>
    800035c8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800035cc:	02090d63          	beqz	s2,80003606 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800035d0:	0929a023          	sw	s2,128(s3) # 12c080 <_entry-0x7fed3f80>
    }
    bp = bread(ip->dev, addr);
    800035d4:	85ca                	mv	a1,s2
    800035d6:	0009a503          	lw	a0,0(s3)
    800035da:	00000097          	auipc	ra,0x0
    800035de:	b90080e7          	jalr	-1136(ra) # 8000316a <bread>
    800035e2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035e4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035e8:	02049593          	slli	a1,s1,0x20
    800035ec:	9181                	srli	a1,a1,0x20
    800035ee:	058a                	slli	a1,a1,0x2
    800035f0:	00b784b3          	add	s1,a5,a1
    800035f4:	0004a903          	lw	s2,0(s1)
    800035f8:	02090063          	beqz	s2,80003618 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800035fc:	8552                	mv	a0,s4
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	c9c080e7          	jalr	-868(ra) # 8000329a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003606:	854a                	mv	a0,s2
    80003608:	70a2                	ld	ra,40(sp)
    8000360a:	7402                	ld	s0,32(sp)
    8000360c:	64e2                	ld	s1,24(sp)
    8000360e:	6942                	ld	s2,16(sp)
    80003610:	69a2                	ld	s3,8(sp)
    80003612:	6a02                	ld	s4,0(sp)
    80003614:	6145                	addi	sp,sp,48
    80003616:	8082                	ret
      addr = balloc(ip->dev);
    80003618:	0009a503          	lw	a0,0(s3)
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	e10080e7          	jalr	-496(ra) # 8000342c <balloc>
    80003624:	0005091b          	sext.w	s2,a0
      if(addr){
    80003628:	fc090ae3          	beqz	s2,800035fc <bmap+0x98>
        a[bn] = addr;
    8000362c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003630:	8552                	mv	a0,s4
    80003632:	00001097          	auipc	ra,0x1
    80003636:	eec080e7          	jalr	-276(ra) # 8000451e <log_write>
    8000363a:	b7c9                	j	800035fc <bmap+0x98>
  panic("bmap: out of range");
    8000363c:	00005517          	auipc	a0,0x5
    80003640:	13450513          	addi	a0,a0,308 # 80008770 <syscalls+0x250>
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	efa080e7          	jalr	-262(ra) # 8000053e <panic>

000000008000364c <iget>:
{
    8000364c:	7179                	addi	sp,sp,-48
    8000364e:	f406                	sd	ra,40(sp)
    80003650:	f022                	sd	s0,32(sp)
    80003652:	ec26                	sd	s1,24(sp)
    80003654:	e84a                	sd	s2,16(sp)
    80003656:	e44e                	sd	s3,8(sp)
    80003658:	e052                	sd	s4,0(sp)
    8000365a:	1800                	addi	s0,sp,48
    8000365c:	89aa                	mv	s3,a0
    8000365e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003660:	0001c517          	auipc	a0,0x1c
    80003664:	79850513          	addi	a0,a0,1944 # 8001fdf8 <itable>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	56e080e7          	jalr	1390(ra) # 80000bd6 <acquire>
  empty = 0;
    80003670:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003672:	0001c497          	auipc	s1,0x1c
    80003676:	79e48493          	addi	s1,s1,1950 # 8001fe10 <itable+0x18>
    8000367a:	0001e697          	auipc	a3,0x1e
    8000367e:	22668693          	addi	a3,a3,550 # 800218a0 <log>
    80003682:	a039                	j	80003690 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003684:	02090b63          	beqz	s2,800036ba <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003688:	08848493          	addi	s1,s1,136
    8000368c:	02d48a63          	beq	s1,a3,800036c0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003690:	449c                	lw	a5,8(s1)
    80003692:	fef059e3          	blez	a5,80003684 <iget+0x38>
    80003696:	4098                	lw	a4,0(s1)
    80003698:	ff3716e3          	bne	a4,s3,80003684 <iget+0x38>
    8000369c:	40d8                	lw	a4,4(s1)
    8000369e:	ff4713e3          	bne	a4,s4,80003684 <iget+0x38>
      ip->ref++;
    800036a2:	2785                	addiw	a5,a5,1
    800036a4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036a6:	0001c517          	auipc	a0,0x1c
    800036aa:	75250513          	addi	a0,a0,1874 # 8001fdf8 <itable>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	5dc080e7          	jalr	1500(ra) # 80000c8a <release>
      return ip;
    800036b6:	8926                	mv	s2,s1
    800036b8:	a03d                	j	800036e6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036ba:	f7f9                	bnez	a5,80003688 <iget+0x3c>
    800036bc:	8926                	mv	s2,s1
    800036be:	b7e9                	j	80003688 <iget+0x3c>
  if(empty == 0)
    800036c0:	02090c63          	beqz	s2,800036f8 <iget+0xac>
  ip->dev = dev;
    800036c4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036c8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036cc:	4785                	li	a5,1
    800036ce:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036d2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036d6:	0001c517          	auipc	a0,0x1c
    800036da:	72250513          	addi	a0,a0,1826 # 8001fdf8 <itable>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	5ac080e7          	jalr	1452(ra) # 80000c8a <release>
}
    800036e6:	854a                	mv	a0,s2
    800036e8:	70a2                	ld	ra,40(sp)
    800036ea:	7402                	ld	s0,32(sp)
    800036ec:	64e2                	ld	s1,24(sp)
    800036ee:	6942                	ld	s2,16(sp)
    800036f0:	69a2                	ld	s3,8(sp)
    800036f2:	6a02                	ld	s4,0(sp)
    800036f4:	6145                	addi	sp,sp,48
    800036f6:	8082                	ret
    panic("iget: no inodes");
    800036f8:	00005517          	auipc	a0,0x5
    800036fc:	09050513          	addi	a0,a0,144 # 80008788 <syscalls+0x268>
    80003700:	ffffd097          	auipc	ra,0xffffd
    80003704:	e3e080e7          	jalr	-450(ra) # 8000053e <panic>

0000000080003708 <fsinit>:
fsinit(int dev) {
    80003708:	7179                	addi	sp,sp,-48
    8000370a:	f406                	sd	ra,40(sp)
    8000370c:	f022                	sd	s0,32(sp)
    8000370e:	ec26                	sd	s1,24(sp)
    80003710:	e84a                	sd	s2,16(sp)
    80003712:	e44e                	sd	s3,8(sp)
    80003714:	1800                	addi	s0,sp,48
    80003716:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003718:	4585                	li	a1,1
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	a50080e7          	jalr	-1456(ra) # 8000316a <bread>
    80003722:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003724:	0001c997          	auipc	s3,0x1c
    80003728:	6b498993          	addi	s3,s3,1716 # 8001fdd8 <sb>
    8000372c:	02000613          	li	a2,32
    80003730:	05850593          	addi	a1,a0,88
    80003734:	854e                	mv	a0,s3
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	5f8080e7          	jalr	1528(ra) # 80000d2e <memmove>
  brelse(bp);
    8000373e:	8526                	mv	a0,s1
    80003740:	00000097          	auipc	ra,0x0
    80003744:	b5a080e7          	jalr	-1190(ra) # 8000329a <brelse>
  if(sb.magic != FSMAGIC)
    80003748:	0009a703          	lw	a4,0(s3)
    8000374c:	102037b7          	lui	a5,0x10203
    80003750:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003754:	02f71263          	bne	a4,a5,80003778 <fsinit+0x70>
  initlog(dev, &sb);
    80003758:	0001c597          	auipc	a1,0x1c
    8000375c:	68058593          	addi	a1,a1,1664 # 8001fdd8 <sb>
    80003760:	854a                	mv	a0,s2
    80003762:	00001097          	auipc	ra,0x1
    80003766:	b40080e7          	jalr	-1216(ra) # 800042a2 <initlog>
}
    8000376a:	70a2                	ld	ra,40(sp)
    8000376c:	7402                	ld	s0,32(sp)
    8000376e:	64e2                	ld	s1,24(sp)
    80003770:	6942                	ld	s2,16(sp)
    80003772:	69a2                	ld	s3,8(sp)
    80003774:	6145                	addi	sp,sp,48
    80003776:	8082                	ret
    panic("invalid file system");
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	02050513          	addi	a0,a0,32 # 80008798 <syscalls+0x278>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	dbe080e7          	jalr	-578(ra) # 8000053e <panic>

0000000080003788 <iinit>:
{
    80003788:	7179                	addi	sp,sp,-48
    8000378a:	f406                	sd	ra,40(sp)
    8000378c:	f022                	sd	s0,32(sp)
    8000378e:	ec26                	sd	s1,24(sp)
    80003790:	e84a                	sd	s2,16(sp)
    80003792:	e44e                	sd	s3,8(sp)
    80003794:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003796:	00005597          	auipc	a1,0x5
    8000379a:	01a58593          	addi	a1,a1,26 # 800087b0 <syscalls+0x290>
    8000379e:	0001c517          	auipc	a0,0x1c
    800037a2:	65a50513          	addi	a0,a0,1626 # 8001fdf8 <itable>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	3a0080e7          	jalr	928(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037ae:	0001c497          	auipc	s1,0x1c
    800037b2:	67248493          	addi	s1,s1,1650 # 8001fe20 <itable+0x28>
    800037b6:	0001e997          	auipc	s3,0x1e
    800037ba:	0fa98993          	addi	s3,s3,250 # 800218b0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037be:	00005917          	auipc	s2,0x5
    800037c2:	ffa90913          	addi	s2,s2,-6 # 800087b8 <syscalls+0x298>
    800037c6:	85ca                	mv	a1,s2
    800037c8:	8526                	mv	a0,s1
    800037ca:	00001097          	auipc	ra,0x1
    800037ce:	e3a080e7          	jalr	-454(ra) # 80004604 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037d2:	08848493          	addi	s1,s1,136
    800037d6:	ff3498e3          	bne	s1,s3,800037c6 <iinit+0x3e>
}
    800037da:	70a2                	ld	ra,40(sp)
    800037dc:	7402                	ld	s0,32(sp)
    800037de:	64e2                	ld	s1,24(sp)
    800037e0:	6942                	ld	s2,16(sp)
    800037e2:	69a2                	ld	s3,8(sp)
    800037e4:	6145                	addi	sp,sp,48
    800037e6:	8082                	ret

00000000800037e8 <ialloc>:
{
    800037e8:	715d                	addi	sp,sp,-80
    800037ea:	e486                	sd	ra,72(sp)
    800037ec:	e0a2                	sd	s0,64(sp)
    800037ee:	fc26                	sd	s1,56(sp)
    800037f0:	f84a                	sd	s2,48(sp)
    800037f2:	f44e                	sd	s3,40(sp)
    800037f4:	f052                	sd	s4,32(sp)
    800037f6:	ec56                	sd	s5,24(sp)
    800037f8:	e85a                	sd	s6,16(sp)
    800037fa:	e45e                	sd	s7,8(sp)
    800037fc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037fe:	0001c717          	auipc	a4,0x1c
    80003802:	5e672703          	lw	a4,1510(a4) # 8001fde4 <sb+0xc>
    80003806:	4785                	li	a5,1
    80003808:	04e7fa63          	bgeu	a5,a4,8000385c <ialloc+0x74>
    8000380c:	8aaa                	mv	s5,a0
    8000380e:	8bae                	mv	s7,a1
    80003810:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003812:	0001ca17          	auipc	s4,0x1c
    80003816:	5c6a0a13          	addi	s4,s4,1478 # 8001fdd8 <sb>
    8000381a:	00048b1b          	sext.w	s6,s1
    8000381e:	0044d793          	srli	a5,s1,0x4
    80003822:	018a2583          	lw	a1,24(s4)
    80003826:	9dbd                	addw	a1,a1,a5
    80003828:	8556                	mv	a0,s5
    8000382a:	00000097          	auipc	ra,0x0
    8000382e:	940080e7          	jalr	-1728(ra) # 8000316a <bread>
    80003832:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003834:	05850993          	addi	s3,a0,88
    80003838:	00f4f793          	andi	a5,s1,15
    8000383c:	079a                	slli	a5,a5,0x6
    8000383e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003840:	00099783          	lh	a5,0(s3)
    80003844:	c3a1                	beqz	a5,80003884 <ialloc+0x9c>
    brelse(bp);
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	a54080e7          	jalr	-1452(ra) # 8000329a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000384e:	0485                	addi	s1,s1,1
    80003850:	00ca2703          	lw	a4,12(s4)
    80003854:	0004879b          	sext.w	a5,s1
    80003858:	fce7e1e3          	bltu	a5,a4,8000381a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000385c:	00005517          	auipc	a0,0x5
    80003860:	f6450513          	addi	a0,a0,-156 # 800087c0 <syscalls+0x2a0>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	d24080e7          	jalr	-732(ra) # 80000588 <printf>
  return 0;
    8000386c:	4501                	li	a0,0
}
    8000386e:	60a6                	ld	ra,72(sp)
    80003870:	6406                	ld	s0,64(sp)
    80003872:	74e2                	ld	s1,56(sp)
    80003874:	7942                	ld	s2,48(sp)
    80003876:	79a2                	ld	s3,40(sp)
    80003878:	7a02                	ld	s4,32(sp)
    8000387a:	6ae2                	ld	s5,24(sp)
    8000387c:	6b42                	ld	s6,16(sp)
    8000387e:	6ba2                	ld	s7,8(sp)
    80003880:	6161                	addi	sp,sp,80
    80003882:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003884:	04000613          	li	a2,64
    80003888:	4581                	li	a1,0
    8000388a:	854e                	mv	a0,s3
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	446080e7          	jalr	1094(ra) # 80000cd2 <memset>
      dip->type = type;
    80003894:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003898:	854a                	mv	a0,s2
    8000389a:	00001097          	auipc	ra,0x1
    8000389e:	c84080e7          	jalr	-892(ra) # 8000451e <log_write>
      brelse(bp);
    800038a2:	854a                	mv	a0,s2
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	9f6080e7          	jalr	-1546(ra) # 8000329a <brelse>
      return iget(dev, inum);
    800038ac:	85da                	mv	a1,s6
    800038ae:	8556                	mv	a0,s5
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	d9c080e7          	jalr	-612(ra) # 8000364c <iget>
    800038b8:	bf5d                	j	8000386e <ialloc+0x86>

00000000800038ba <iupdate>:
{
    800038ba:	1101                	addi	sp,sp,-32
    800038bc:	ec06                	sd	ra,24(sp)
    800038be:	e822                	sd	s0,16(sp)
    800038c0:	e426                	sd	s1,8(sp)
    800038c2:	e04a                	sd	s2,0(sp)
    800038c4:	1000                	addi	s0,sp,32
    800038c6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038c8:	415c                	lw	a5,4(a0)
    800038ca:	0047d79b          	srliw	a5,a5,0x4
    800038ce:	0001c597          	auipc	a1,0x1c
    800038d2:	5225a583          	lw	a1,1314(a1) # 8001fdf0 <sb+0x18>
    800038d6:	9dbd                	addw	a1,a1,a5
    800038d8:	4108                	lw	a0,0(a0)
    800038da:	00000097          	auipc	ra,0x0
    800038de:	890080e7          	jalr	-1904(ra) # 8000316a <bread>
    800038e2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038e4:	05850793          	addi	a5,a0,88
    800038e8:	40c8                	lw	a0,4(s1)
    800038ea:	893d                	andi	a0,a0,15
    800038ec:	051a                	slli	a0,a0,0x6
    800038ee:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038f0:	04449703          	lh	a4,68(s1)
    800038f4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038f8:	04649703          	lh	a4,70(s1)
    800038fc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003900:	04849703          	lh	a4,72(s1)
    80003904:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003908:	04a49703          	lh	a4,74(s1)
    8000390c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003910:	44f8                	lw	a4,76(s1)
    80003912:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003914:	03400613          	li	a2,52
    80003918:	05048593          	addi	a1,s1,80
    8000391c:	0531                	addi	a0,a0,12
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	410080e7          	jalr	1040(ra) # 80000d2e <memmove>
  log_write(bp);
    80003926:	854a                	mv	a0,s2
    80003928:	00001097          	auipc	ra,0x1
    8000392c:	bf6080e7          	jalr	-1034(ra) # 8000451e <log_write>
  brelse(bp);
    80003930:	854a                	mv	a0,s2
    80003932:	00000097          	auipc	ra,0x0
    80003936:	968080e7          	jalr	-1688(ra) # 8000329a <brelse>
}
    8000393a:	60e2                	ld	ra,24(sp)
    8000393c:	6442                	ld	s0,16(sp)
    8000393e:	64a2                	ld	s1,8(sp)
    80003940:	6902                	ld	s2,0(sp)
    80003942:	6105                	addi	sp,sp,32
    80003944:	8082                	ret

0000000080003946 <idup>:
{
    80003946:	1101                	addi	sp,sp,-32
    80003948:	ec06                	sd	ra,24(sp)
    8000394a:	e822                	sd	s0,16(sp)
    8000394c:	e426                	sd	s1,8(sp)
    8000394e:	1000                	addi	s0,sp,32
    80003950:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003952:	0001c517          	auipc	a0,0x1c
    80003956:	4a650513          	addi	a0,a0,1190 # 8001fdf8 <itable>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	27c080e7          	jalr	636(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003962:	449c                	lw	a5,8(s1)
    80003964:	2785                	addiw	a5,a5,1
    80003966:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003968:	0001c517          	auipc	a0,0x1c
    8000396c:	49050513          	addi	a0,a0,1168 # 8001fdf8 <itable>
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	31a080e7          	jalr	794(ra) # 80000c8a <release>
}
    80003978:	8526                	mv	a0,s1
    8000397a:	60e2                	ld	ra,24(sp)
    8000397c:	6442                	ld	s0,16(sp)
    8000397e:	64a2                	ld	s1,8(sp)
    80003980:	6105                	addi	sp,sp,32
    80003982:	8082                	ret

0000000080003984 <ilock>:
{
    80003984:	1101                	addi	sp,sp,-32
    80003986:	ec06                	sd	ra,24(sp)
    80003988:	e822                	sd	s0,16(sp)
    8000398a:	e426                	sd	s1,8(sp)
    8000398c:	e04a                	sd	s2,0(sp)
    8000398e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003990:	c115                	beqz	a0,800039b4 <ilock+0x30>
    80003992:	84aa                	mv	s1,a0
    80003994:	451c                	lw	a5,8(a0)
    80003996:	00f05f63          	blez	a5,800039b4 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000399a:	0541                	addi	a0,a0,16
    8000399c:	00001097          	auipc	ra,0x1
    800039a0:	ca2080e7          	jalr	-862(ra) # 8000463e <acquiresleep>
  if(ip->valid == 0){
    800039a4:	40bc                	lw	a5,64(s1)
    800039a6:	cf99                	beqz	a5,800039c4 <ilock+0x40>
}
    800039a8:	60e2                	ld	ra,24(sp)
    800039aa:	6442                	ld	s0,16(sp)
    800039ac:	64a2                	ld	s1,8(sp)
    800039ae:	6902                	ld	s2,0(sp)
    800039b0:	6105                	addi	sp,sp,32
    800039b2:	8082                	ret
    panic("ilock");
    800039b4:	00005517          	auipc	a0,0x5
    800039b8:	e2450513          	addi	a0,a0,-476 # 800087d8 <syscalls+0x2b8>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	b82080e7          	jalr	-1150(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039c4:	40dc                	lw	a5,4(s1)
    800039c6:	0047d79b          	srliw	a5,a5,0x4
    800039ca:	0001c597          	auipc	a1,0x1c
    800039ce:	4265a583          	lw	a1,1062(a1) # 8001fdf0 <sb+0x18>
    800039d2:	9dbd                	addw	a1,a1,a5
    800039d4:	4088                	lw	a0,0(s1)
    800039d6:	fffff097          	auipc	ra,0xfffff
    800039da:	794080e7          	jalr	1940(ra) # 8000316a <bread>
    800039de:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039e0:	05850593          	addi	a1,a0,88
    800039e4:	40dc                	lw	a5,4(s1)
    800039e6:	8bbd                	andi	a5,a5,15
    800039e8:	079a                	slli	a5,a5,0x6
    800039ea:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039ec:	00059783          	lh	a5,0(a1)
    800039f0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039f4:	00259783          	lh	a5,2(a1)
    800039f8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039fc:	00459783          	lh	a5,4(a1)
    80003a00:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a04:	00659783          	lh	a5,6(a1)
    80003a08:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a0c:	459c                	lw	a5,8(a1)
    80003a0e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a10:	03400613          	li	a2,52
    80003a14:	05b1                	addi	a1,a1,12
    80003a16:	05048513          	addi	a0,s1,80
    80003a1a:	ffffd097          	auipc	ra,0xffffd
    80003a1e:	314080e7          	jalr	788(ra) # 80000d2e <memmove>
    brelse(bp);
    80003a22:	854a                	mv	a0,s2
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	876080e7          	jalr	-1930(ra) # 8000329a <brelse>
    ip->valid = 1;
    80003a2c:	4785                	li	a5,1
    80003a2e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a30:	04449783          	lh	a5,68(s1)
    80003a34:	fbb5                	bnez	a5,800039a8 <ilock+0x24>
      panic("ilock: no type");
    80003a36:	00005517          	auipc	a0,0x5
    80003a3a:	daa50513          	addi	a0,a0,-598 # 800087e0 <syscalls+0x2c0>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	b00080e7          	jalr	-1280(ra) # 8000053e <panic>

0000000080003a46 <iunlock>:
{
    80003a46:	1101                	addi	sp,sp,-32
    80003a48:	ec06                	sd	ra,24(sp)
    80003a4a:	e822                	sd	s0,16(sp)
    80003a4c:	e426                	sd	s1,8(sp)
    80003a4e:	e04a                	sd	s2,0(sp)
    80003a50:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a52:	c905                	beqz	a0,80003a82 <iunlock+0x3c>
    80003a54:	84aa                	mv	s1,a0
    80003a56:	01050913          	addi	s2,a0,16
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	00001097          	auipc	ra,0x1
    80003a60:	c7c080e7          	jalr	-900(ra) # 800046d8 <holdingsleep>
    80003a64:	cd19                	beqz	a0,80003a82 <iunlock+0x3c>
    80003a66:	449c                	lw	a5,8(s1)
    80003a68:	00f05d63          	blez	a5,80003a82 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a6c:	854a                	mv	a0,s2
    80003a6e:	00001097          	auipc	ra,0x1
    80003a72:	c26080e7          	jalr	-986(ra) # 80004694 <releasesleep>
}
    80003a76:	60e2                	ld	ra,24(sp)
    80003a78:	6442                	ld	s0,16(sp)
    80003a7a:	64a2                	ld	s1,8(sp)
    80003a7c:	6902                	ld	s2,0(sp)
    80003a7e:	6105                	addi	sp,sp,32
    80003a80:	8082                	ret
    panic("iunlock");
    80003a82:	00005517          	auipc	a0,0x5
    80003a86:	d6e50513          	addi	a0,a0,-658 # 800087f0 <syscalls+0x2d0>
    80003a8a:	ffffd097          	auipc	ra,0xffffd
    80003a8e:	ab4080e7          	jalr	-1356(ra) # 8000053e <panic>

0000000080003a92 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a92:	7179                	addi	sp,sp,-48
    80003a94:	f406                	sd	ra,40(sp)
    80003a96:	f022                	sd	s0,32(sp)
    80003a98:	ec26                	sd	s1,24(sp)
    80003a9a:	e84a                	sd	s2,16(sp)
    80003a9c:	e44e                	sd	s3,8(sp)
    80003a9e:	e052                	sd	s4,0(sp)
    80003aa0:	1800                	addi	s0,sp,48
    80003aa2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003aa4:	05050493          	addi	s1,a0,80
    80003aa8:	08050913          	addi	s2,a0,128
    80003aac:	a021                	j	80003ab4 <itrunc+0x22>
    80003aae:	0491                	addi	s1,s1,4
    80003ab0:	01248d63          	beq	s1,s2,80003aca <itrunc+0x38>
    if(ip->addrs[i]){
    80003ab4:	408c                	lw	a1,0(s1)
    80003ab6:	dde5                	beqz	a1,80003aae <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ab8:	0009a503          	lw	a0,0(s3)
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	8f4080e7          	jalr	-1804(ra) # 800033b0 <bfree>
      ip->addrs[i] = 0;
    80003ac4:	0004a023          	sw	zero,0(s1)
    80003ac8:	b7dd                	j	80003aae <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003aca:	0809a583          	lw	a1,128(s3)
    80003ace:	e185                	bnez	a1,80003aee <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ad0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ad4:	854e                	mv	a0,s3
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	de4080e7          	jalr	-540(ra) # 800038ba <iupdate>
}
    80003ade:	70a2                	ld	ra,40(sp)
    80003ae0:	7402                	ld	s0,32(sp)
    80003ae2:	64e2                	ld	s1,24(sp)
    80003ae4:	6942                	ld	s2,16(sp)
    80003ae6:	69a2                	ld	s3,8(sp)
    80003ae8:	6a02                	ld	s4,0(sp)
    80003aea:	6145                	addi	sp,sp,48
    80003aec:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003aee:	0009a503          	lw	a0,0(s3)
    80003af2:	fffff097          	auipc	ra,0xfffff
    80003af6:	678080e7          	jalr	1656(ra) # 8000316a <bread>
    80003afa:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003afc:	05850493          	addi	s1,a0,88
    80003b00:	45850913          	addi	s2,a0,1112
    80003b04:	a021                	j	80003b0c <itrunc+0x7a>
    80003b06:	0491                	addi	s1,s1,4
    80003b08:	01248b63          	beq	s1,s2,80003b1e <itrunc+0x8c>
      if(a[j])
    80003b0c:	408c                	lw	a1,0(s1)
    80003b0e:	dde5                	beqz	a1,80003b06 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b10:	0009a503          	lw	a0,0(s3)
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	89c080e7          	jalr	-1892(ra) # 800033b0 <bfree>
    80003b1c:	b7ed                	j	80003b06 <itrunc+0x74>
    brelse(bp);
    80003b1e:	8552                	mv	a0,s4
    80003b20:	fffff097          	auipc	ra,0xfffff
    80003b24:	77a080e7          	jalr	1914(ra) # 8000329a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b28:	0809a583          	lw	a1,128(s3)
    80003b2c:	0009a503          	lw	a0,0(s3)
    80003b30:	00000097          	auipc	ra,0x0
    80003b34:	880080e7          	jalr	-1920(ra) # 800033b0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b38:	0809a023          	sw	zero,128(s3)
    80003b3c:	bf51                	j	80003ad0 <itrunc+0x3e>

0000000080003b3e <iput>:
{
    80003b3e:	1101                	addi	sp,sp,-32
    80003b40:	ec06                	sd	ra,24(sp)
    80003b42:	e822                	sd	s0,16(sp)
    80003b44:	e426                	sd	s1,8(sp)
    80003b46:	e04a                	sd	s2,0(sp)
    80003b48:	1000                	addi	s0,sp,32
    80003b4a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b4c:	0001c517          	auipc	a0,0x1c
    80003b50:	2ac50513          	addi	a0,a0,684 # 8001fdf8 <itable>
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	082080e7          	jalr	130(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b5c:	4498                	lw	a4,8(s1)
    80003b5e:	4785                	li	a5,1
    80003b60:	02f70363          	beq	a4,a5,80003b86 <iput+0x48>
  ip->ref--;
    80003b64:	449c                	lw	a5,8(s1)
    80003b66:	37fd                	addiw	a5,a5,-1
    80003b68:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b6a:	0001c517          	auipc	a0,0x1c
    80003b6e:	28e50513          	addi	a0,a0,654 # 8001fdf8 <itable>
    80003b72:	ffffd097          	auipc	ra,0xffffd
    80003b76:	118080e7          	jalr	280(ra) # 80000c8a <release>
}
    80003b7a:	60e2                	ld	ra,24(sp)
    80003b7c:	6442                	ld	s0,16(sp)
    80003b7e:	64a2                	ld	s1,8(sp)
    80003b80:	6902                	ld	s2,0(sp)
    80003b82:	6105                	addi	sp,sp,32
    80003b84:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b86:	40bc                	lw	a5,64(s1)
    80003b88:	dff1                	beqz	a5,80003b64 <iput+0x26>
    80003b8a:	04a49783          	lh	a5,74(s1)
    80003b8e:	fbf9                	bnez	a5,80003b64 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b90:	01048913          	addi	s2,s1,16
    80003b94:	854a                	mv	a0,s2
    80003b96:	00001097          	auipc	ra,0x1
    80003b9a:	aa8080e7          	jalr	-1368(ra) # 8000463e <acquiresleep>
    release(&itable.lock);
    80003b9e:	0001c517          	auipc	a0,0x1c
    80003ba2:	25a50513          	addi	a0,a0,602 # 8001fdf8 <itable>
    80003ba6:	ffffd097          	auipc	ra,0xffffd
    80003baa:	0e4080e7          	jalr	228(ra) # 80000c8a <release>
    itrunc(ip);
    80003bae:	8526                	mv	a0,s1
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	ee2080e7          	jalr	-286(ra) # 80003a92 <itrunc>
    ip->type = 0;
    80003bb8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bbc:	8526                	mv	a0,s1
    80003bbe:	00000097          	auipc	ra,0x0
    80003bc2:	cfc080e7          	jalr	-772(ra) # 800038ba <iupdate>
    ip->valid = 0;
    80003bc6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bca:	854a                	mv	a0,s2
    80003bcc:	00001097          	auipc	ra,0x1
    80003bd0:	ac8080e7          	jalr	-1336(ra) # 80004694 <releasesleep>
    acquire(&itable.lock);
    80003bd4:	0001c517          	auipc	a0,0x1c
    80003bd8:	22450513          	addi	a0,a0,548 # 8001fdf8 <itable>
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	ffa080e7          	jalr	-6(ra) # 80000bd6 <acquire>
    80003be4:	b741                	j	80003b64 <iput+0x26>

0000000080003be6 <iunlockput>:
{
    80003be6:	1101                	addi	sp,sp,-32
    80003be8:	ec06                	sd	ra,24(sp)
    80003bea:	e822                	sd	s0,16(sp)
    80003bec:	e426                	sd	s1,8(sp)
    80003bee:	1000                	addi	s0,sp,32
    80003bf0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	e54080e7          	jalr	-428(ra) # 80003a46 <iunlock>
  iput(ip);
    80003bfa:	8526                	mv	a0,s1
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	f42080e7          	jalr	-190(ra) # 80003b3e <iput>
}
    80003c04:	60e2                	ld	ra,24(sp)
    80003c06:	6442                	ld	s0,16(sp)
    80003c08:	64a2                	ld	s1,8(sp)
    80003c0a:	6105                	addi	sp,sp,32
    80003c0c:	8082                	ret

0000000080003c0e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c0e:	1141                	addi	sp,sp,-16
    80003c10:	e422                	sd	s0,8(sp)
    80003c12:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c14:	411c                	lw	a5,0(a0)
    80003c16:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c18:	415c                	lw	a5,4(a0)
    80003c1a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c1c:	04451783          	lh	a5,68(a0)
    80003c20:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c24:	04a51783          	lh	a5,74(a0)
    80003c28:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c2c:	04c56783          	lwu	a5,76(a0)
    80003c30:	e99c                	sd	a5,16(a1)
}
    80003c32:	6422                	ld	s0,8(sp)
    80003c34:	0141                	addi	sp,sp,16
    80003c36:	8082                	ret

0000000080003c38 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c38:	457c                	lw	a5,76(a0)
    80003c3a:	0ed7e963          	bltu	a5,a3,80003d2c <readi+0xf4>
{
    80003c3e:	7159                	addi	sp,sp,-112
    80003c40:	f486                	sd	ra,104(sp)
    80003c42:	f0a2                	sd	s0,96(sp)
    80003c44:	eca6                	sd	s1,88(sp)
    80003c46:	e8ca                	sd	s2,80(sp)
    80003c48:	e4ce                	sd	s3,72(sp)
    80003c4a:	e0d2                	sd	s4,64(sp)
    80003c4c:	fc56                	sd	s5,56(sp)
    80003c4e:	f85a                	sd	s6,48(sp)
    80003c50:	f45e                	sd	s7,40(sp)
    80003c52:	f062                	sd	s8,32(sp)
    80003c54:	ec66                	sd	s9,24(sp)
    80003c56:	e86a                	sd	s10,16(sp)
    80003c58:	e46e                	sd	s11,8(sp)
    80003c5a:	1880                	addi	s0,sp,112
    80003c5c:	8b2a                	mv	s6,a0
    80003c5e:	8bae                	mv	s7,a1
    80003c60:	8a32                	mv	s4,a2
    80003c62:	84b6                	mv	s1,a3
    80003c64:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c66:	9f35                	addw	a4,a4,a3
    return 0;
    80003c68:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c6a:	0ad76063          	bltu	a4,a3,80003d0a <readi+0xd2>
  if(off + n > ip->size)
    80003c6e:	00e7f463          	bgeu	a5,a4,80003c76 <readi+0x3e>
    n = ip->size - off;
    80003c72:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c76:	0a0a8963          	beqz	s5,80003d28 <readi+0xf0>
    80003c7a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c7c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c80:	5c7d                	li	s8,-1
    80003c82:	a82d                	j	80003cbc <readi+0x84>
    80003c84:	020d1d93          	slli	s11,s10,0x20
    80003c88:	020ddd93          	srli	s11,s11,0x20
    80003c8c:	05890793          	addi	a5,s2,88
    80003c90:	86ee                	mv	a3,s11
    80003c92:	963e                	add	a2,a2,a5
    80003c94:	85d2                	mv	a1,s4
    80003c96:	855e                	mv	a0,s7
    80003c98:	fffff097          	auipc	ra,0xfffff
    80003c9c:	892080e7          	jalr	-1902(ra) # 8000252a <either_copyout>
    80003ca0:	05850d63          	beq	a0,s8,80003cfa <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ca4:	854a                	mv	a0,s2
    80003ca6:	fffff097          	auipc	ra,0xfffff
    80003caa:	5f4080e7          	jalr	1524(ra) # 8000329a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cae:	013d09bb          	addw	s3,s10,s3
    80003cb2:	009d04bb          	addw	s1,s10,s1
    80003cb6:	9a6e                	add	s4,s4,s11
    80003cb8:	0559f763          	bgeu	s3,s5,80003d06 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003cbc:	00a4d59b          	srliw	a1,s1,0xa
    80003cc0:	855a                	mv	a0,s6
    80003cc2:	00000097          	auipc	ra,0x0
    80003cc6:	8a2080e7          	jalr	-1886(ra) # 80003564 <bmap>
    80003cca:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003cce:	cd85                	beqz	a1,80003d06 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003cd0:	000b2503          	lw	a0,0(s6)
    80003cd4:	fffff097          	auipc	ra,0xfffff
    80003cd8:	496080e7          	jalr	1174(ra) # 8000316a <bread>
    80003cdc:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cde:	3ff4f613          	andi	a2,s1,1023
    80003ce2:	40cc87bb          	subw	a5,s9,a2
    80003ce6:	413a873b          	subw	a4,s5,s3
    80003cea:	8d3e                	mv	s10,a5
    80003cec:	2781                	sext.w	a5,a5
    80003cee:	0007069b          	sext.w	a3,a4
    80003cf2:	f8f6f9e3          	bgeu	a3,a5,80003c84 <readi+0x4c>
    80003cf6:	8d3a                	mv	s10,a4
    80003cf8:	b771                	j	80003c84 <readi+0x4c>
      brelse(bp);
    80003cfa:	854a                	mv	a0,s2
    80003cfc:	fffff097          	auipc	ra,0xfffff
    80003d00:	59e080e7          	jalr	1438(ra) # 8000329a <brelse>
      tot = -1;
    80003d04:	59fd                	li	s3,-1
  }
  return tot;
    80003d06:	0009851b          	sext.w	a0,s3
}
    80003d0a:	70a6                	ld	ra,104(sp)
    80003d0c:	7406                	ld	s0,96(sp)
    80003d0e:	64e6                	ld	s1,88(sp)
    80003d10:	6946                	ld	s2,80(sp)
    80003d12:	69a6                	ld	s3,72(sp)
    80003d14:	6a06                	ld	s4,64(sp)
    80003d16:	7ae2                	ld	s5,56(sp)
    80003d18:	7b42                	ld	s6,48(sp)
    80003d1a:	7ba2                	ld	s7,40(sp)
    80003d1c:	7c02                	ld	s8,32(sp)
    80003d1e:	6ce2                	ld	s9,24(sp)
    80003d20:	6d42                	ld	s10,16(sp)
    80003d22:	6da2                	ld	s11,8(sp)
    80003d24:	6165                	addi	sp,sp,112
    80003d26:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d28:	89d6                	mv	s3,s5
    80003d2a:	bff1                	j	80003d06 <readi+0xce>
    return 0;
    80003d2c:	4501                	li	a0,0
}
    80003d2e:	8082                	ret

0000000080003d30 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d30:	457c                	lw	a5,76(a0)
    80003d32:	10d7e863          	bltu	a5,a3,80003e42 <writei+0x112>
{
    80003d36:	7159                	addi	sp,sp,-112
    80003d38:	f486                	sd	ra,104(sp)
    80003d3a:	f0a2                	sd	s0,96(sp)
    80003d3c:	eca6                	sd	s1,88(sp)
    80003d3e:	e8ca                	sd	s2,80(sp)
    80003d40:	e4ce                	sd	s3,72(sp)
    80003d42:	e0d2                	sd	s4,64(sp)
    80003d44:	fc56                	sd	s5,56(sp)
    80003d46:	f85a                	sd	s6,48(sp)
    80003d48:	f45e                	sd	s7,40(sp)
    80003d4a:	f062                	sd	s8,32(sp)
    80003d4c:	ec66                	sd	s9,24(sp)
    80003d4e:	e86a                	sd	s10,16(sp)
    80003d50:	e46e                	sd	s11,8(sp)
    80003d52:	1880                	addi	s0,sp,112
    80003d54:	8aaa                	mv	s5,a0
    80003d56:	8bae                	mv	s7,a1
    80003d58:	8a32                	mv	s4,a2
    80003d5a:	8936                	mv	s2,a3
    80003d5c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d5e:	00e687bb          	addw	a5,a3,a4
    80003d62:	0ed7e263          	bltu	a5,a3,80003e46 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d66:	00043737          	lui	a4,0x43
    80003d6a:	0ef76063          	bltu	a4,a5,80003e4a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d6e:	0c0b0863          	beqz	s6,80003e3e <writei+0x10e>
    80003d72:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d74:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d78:	5c7d                	li	s8,-1
    80003d7a:	a091                	j	80003dbe <writei+0x8e>
    80003d7c:	020d1d93          	slli	s11,s10,0x20
    80003d80:	020ddd93          	srli	s11,s11,0x20
    80003d84:	05848793          	addi	a5,s1,88
    80003d88:	86ee                	mv	a3,s11
    80003d8a:	8652                	mv	a2,s4
    80003d8c:	85de                	mv	a1,s7
    80003d8e:	953e                	add	a0,a0,a5
    80003d90:	ffffe097          	auipc	ra,0xffffe
    80003d94:	7f0080e7          	jalr	2032(ra) # 80002580 <either_copyin>
    80003d98:	07850263          	beq	a0,s8,80003dfc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d9c:	8526                	mv	a0,s1
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	780080e7          	jalr	1920(ra) # 8000451e <log_write>
    brelse(bp);
    80003da6:	8526                	mv	a0,s1
    80003da8:	fffff097          	auipc	ra,0xfffff
    80003dac:	4f2080e7          	jalr	1266(ra) # 8000329a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003db0:	013d09bb          	addw	s3,s10,s3
    80003db4:	012d093b          	addw	s2,s10,s2
    80003db8:	9a6e                	add	s4,s4,s11
    80003dba:	0569f663          	bgeu	s3,s6,80003e06 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003dbe:	00a9559b          	srliw	a1,s2,0xa
    80003dc2:	8556                	mv	a0,s5
    80003dc4:	fffff097          	auipc	ra,0xfffff
    80003dc8:	7a0080e7          	jalr	1952(ra) # 80003564 <bmap>
    80003dcc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003dd0:	c99d                	beqz	a1,80003e06 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003dd2:	000aa503          	lw	a0,0(s5)
    80003dd6:	fffff097          	auipc	ra,0xfffff
    80003dda:	394080e7          	jalr	916(ra) # 8000316a <bread>
    80003dde:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003de0:	3ff97513          	andi	a0,s2,1023
    80003de4:	40ac87bb          	subw	a5,s9,a0
    80003de8:	413b073b          	subw	a4,s6,s3
    80003dec:	8d3e                	mv	s10,a5
    80003dee:	2781                	sext.w	a5,a5
    80003df0:	0007069b          	sext.w	a3,a4
    80003df4:	f8f6f4e3          	bgeu	a3,a5,80003d7c <writei+0x4c>
    80003df8:	8d3a                	mv	s10,a4
    80003dfa:	b749                	j	80003d7c <writei+0x4c>
      brelse(bp);
    80003dfc:	8526                	mv	a0,s1
    80003dfe:	fffff097          	auipc	ra,0xfffff
    80003e02:	49c080e7          	jalr	1180(ra) # 8000329a <brelse>
  }

  if(off > ip->size)
    80003e06:	04caa783          	lw	a5,76(s5)
    80003e0a:	0127f463          	bgeu	a5,s2,80003e12 <writei+0xe2>
    ip->size = off;
    80003e0e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e12:	8556                	mv	a0,s5
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	aa6080e7          	jalr	-1370(ra) # 800038ba <iupdate>

  return tot;
    80003e1c:	0009851b          	sext.w	a0,s3
}
    80003e20:	70a6                	ld	ra,104(sp)
    80003e22:	7406                	ld	s0,96(sp)
    80003e24:	64e6                	ld	s1,88(sp)
    80003e26:	6946                	ld	s2,80(sp)
    80003e28:	69a6                	ld	s3,72(sp)
    80003e2a:	6a06                	ld	s4,64(sp)
    80003e2c:	7ae2                	ld	s5,56(sp)
    80003e2e:	7b42                	ld	s6,48(sp)
    80003e30:	7ba2                	ld	s7,40(sp)
    80003e32:	7c02                	ld	s8,32(sp)
    80003e34:	6ce2                	ld	s9,24(sp)
    80003e36:	6d42                	ld	s10,16(sp)
    80003e38:	6da2                	ld	s11,8(sp)
    80003e3a:	6165                	addi	sp,sp,112
    80003e3c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e3e:	89da                	mv	s3,s6
    80003e40:	bfc9                	j	80003e12 <writei+0xe2>
    return -1;
    80003e42:	557d                	li	a0,-1
}
    80003e44:	8082                	ret
    return -1;
    80003e46:	557d                	li	a0,-1
    80003e48:	bfe1                	j	80003e20 <writei+0xf0>
    return -1;
    80003e4a:	557d                	li	a0,-1
    80003e4c:	bfd1                	j	80003e20 <writei+0xf0>

0000000080003e4e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e4e:	1141                	addi	sp,sp,-16
    80003e50:	e406                	sd	ra,8(sp)
    80003e52:	e022                	sd	s0,0(sp)
    80003e54:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e56:	4639                	li	a2,14
    80003e58:	ffffd097          	auipc	ra,0xffffd
    80003e5c:	f4a080e7          	jalr	-182(ra) # 80000da2 <strncmp>
}
    80003e60:	60a2                	ld	ra,8(sp)
    80003e62:	6402                	ld	s0,0(sp)
    80003e64:	0141                	addi	sp,sp,16
    80003e66:	8082                	ret

0000000080003e68 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e68:	7139                	addi	sp,sp,-64
    80003e6a:	fc06                	sd	ra,56(sp)
    80003e6c:	f822                	sd	s0,48(sp)
    80003e6e:	f426                	sd	s1,40(sp)
    80003e70:	f04a                	sd	s2,32(sp)
    80003e72:	ec4e                	sd	s3,24(sp)
    80003e74:	e852                	sd	s4,16(sp)
    80003e76:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e78:	04451703          	lh	a4,68(a0)
    80003e7c:	4785                	li	a5,1
    80003e7e:	00f71a63          	bne	a4,a5,80003e92 <dirlookup+0x2a>
    80003e82:	892a                	mv	s2,a0
    80003e84:	89ae                	mv	s3,a1
    80003e86:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e88:	457c                	lw	a5,76(a0)
    80003e8a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e8c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e8e:	e79d                	bnez	a5,80003ebc <dirlookup+0x54>
    80003e90:	a8a5                	j	80003f08 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e92:	00005517          	auipc	a0,0x5
    80003e96:	96650513          	addi	a0,a0,-1690 # 800087f8 <syscalls+0x2d8>
    80003e9a:	ffffc097          	auipc	ra,0xffffc
    80003e9e:	6a4080e7          	jalr	1700(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003ea2:	00005517          	auipc	a0,0x5
    80003ea6:	96e50513          	addi	a0,a0,-1682 # 80008810 <syscalls+0x2f0>
    80003eaa:	ffffc097          	auipc	ra,0xffffc
    80003eae:	694080e7          	jalr	1684(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb2:	24c1                	addiw	s1,s1,16
    80003eb4:	04c92783          	lw	a5,76(s2)
    80003eb8:	04f4f763          	bgeu	s1,a5,80003f06 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ebc:	4741                	li	a4,16
    80003ebe:	86a6                	mv	a3,s1
    80003ec0:	fc040613          	addi	a2,s0,-64
    80003ec4:	4581                	li	a1,0
    80003ec6:	854a                	mv	a0,s2
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	d70080e7          	jalr	-656(ra) # 80003c38 <readi>
    80003ed0:	47c1                	li	a5,16
    80003ed2:	fcf518e3          	bne	a0,a5,80003ea2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ed6:	fc045783          	lhu	a5,-64(s0)
    80003eda:	dfe1                	beqz	a5,80003eb2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003edc:	fc240593          	addi	a1,s0,-62
    80003ee0:	854e                	mv	a0,s3
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	f6c080e7          	jalr	-148(ra) # 80003e4e <namecmp>
    80003eea:	f561                	bnez	a0,80003eb2 <dirlookup+0x4a>
      if(poff)
    80003eec:	000a0463          	beqz	s4,80003ef4 <dirlookup+0x8c>
        *poff = off;
    80003ef0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ef4:	fc045583          	lhu	a1,-64(s0)
    80003ef8:	00092503          	lw	a0,0(s2)
    80003efc:	fffff097          	auipc	ra,0xfffff
    80003f00:	750080e7          	jalr	1872(ra) # 8000364c <iget>
    80003f04:	a011                	j	80003f08 <dirlookup+0xa0>
  return 0;
    80003f06:	4501                	li	a0,0
}
    80003f08:	70e2                	ld	ra,56(sp)
    80003f0a:	7442                	ld	s0,48(sp)
    80003f0c:	74a2                	ld	s1,40(sp)
    80003f0e:	7902                	ld	s2,32(sp)
    80003f10:	69e2                	ld	s3,24(sp)
    80003f12:	6a42                	ld	s4,16(sp)
    80003f14:	6121                	addi	sp,sp,64
    80003f16:	8082                	ret

0000000080003f18 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f18:	711d                	addi	sp,sp,-96
    80003f1a:	ec86                	sd	ra,88(sp)
    80003f1c:	e8a2                	sd	s0,80(sp)
    80003f1e:	e4a6                	sd	s1,72(sp)
    80003f20:	e0ca                	sd	s2,64(sp)
    80003f22:	fc4e                	sd	s3,56(sp)
    80003f24:	f852                	sd	s4,48(sp)
    80003f26:	f456                	sd	s5,40(sp)
    80003f28:	f05a                	sd	s6,32(sp)
    80003f2a:	ec5e                	sd	s7,24(sp)
    80003f2c:	e862                	sd	s8,16(sp)
    80003f2e:	e466                	sd	s9,8(sp)
    80003f30:	1080                	addi	s0,sp,96
    80003f32:	84aa                	mv	s1,a0
    80003f34:	8aae                	mv	s5,a1
    80003f36:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f38:	00054703          	lbu	a4,0(a0)
    80003f3c:	02f00793          	li	a5,47
    80003f40:	02f70363          	beq	a4,a5,80003f66 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f44:	ffffe097          	auipc	ra,0xffffe
    80003f48:	a9e080e7          	jalr	-1378(ra) # 800019e2 <myproc>
    80003f4c:	15053503          	ld	a0,336(a0)
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	9f6080e7          	jalr	-1546(ra) # 80003946 <idup>
    80003f58:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f5a:	02f00913          	li	s2,47
  len = path - s;
    80003f5e:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f60:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f62:	4b85                	li	s7,1
    80003f64:	a865                	j	8000401c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f66:	4585                	li	a1,1
    80003f68:	4505                	li	a0,1
    80003f6a:	fffff097          	auipc	ra,0xfffff
    80003f6e:	6e2080e7          	jalr	1762(ra) # 8000364c <iget>
    80003f72:	89aa                	mv	s3,a0
    80003f74:	b7dd                	j	80003f5a <namex+0x42>
      iunlockput(ip);
    80003f76:	854e                	mv	a0,s3
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	c6e080e7          	jalr	-914(ra) # 80003be6 <iunlockput>
      return 0;
    80003f80:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f82:	854e                	mv	a0,s3
    80003f84:	60e6                	ld	ra,88(sp)
    80003f86:	6446                	ld	s0,80(sp)
    80003f88:	64a6                	ld	s1,72(sp)
    80003f8a:	6906                	ld	s2,64(sp)
    80003f8c:	79e2                	ld	s3,56(sp)
    80003f8e:	7a42                	ld	s4,48(sp)
    80003f90:	7aa2                	ld	s5,40(sp)
    80003f92:	7b02                	ld	s6,32(sp)
    80003f94:	6be2                	ld	s7,24(sp)
    80003f96:	6c42                	ld	s8,16(sp)
    80003f98:	6ca2                	ld	s9,8(sp)
    80003f9a:	6125                	addi	sp,sp,96
    80003f9c:	8082                	ret
      iunlock(ip);
    80003f9e:	854e                	mv	a0,s3
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	aa6080e7          	jalr	-1370(ra) # 80003a46 <iunlock>
      return ip;
    80003fa8:	bfe9                	j	80003f82 <namex+0x6a>
      iunlockput(ip);
    80003faa:	854e                	mv	a0,s3
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	c3a080e7          	jalr	-966(ra) # 80003be6 <iunlockput>
      return 0;
    80003fb4:	89e6                	mv	s3,s9
    80003fb6:	b7f1                	j	80003f82 <namex+0x6a>
  len = path - s;
    80003fb8:	40b48633          	sub	a2,s1,a1
    80003fbc:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003fc0:	099c5463          	bge	s8,s9,80004048 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fc4:	4639                	li	a2,14
    80003fc6:	8552                	mv	a0,s4
    80003fc8:	ffffd097          	auipc	ra,0xffffd
    80003fcc:	d66080e7          	jalr	-666(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003fd0:	0004c783          	lbu	a5,0(s1)
    80003fd4:	01279763          	bne	a5,s2,80003fe2 <namex+0xca>
    path++;
    80003fd8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fda:	0004c783          	lbu	a5,0(s1)
    80003fde:	ff278de3          	beq	a5,s2,80003fd8 <namex+0xc0>
    ilock(ip);
    80003fe2:	854e                	mv	a0,s3
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	9a0080e7          	jalr	-1632(ra) # 80003984 <ilock>
    if(ip->type != T_DIR){
    80003fec:	04499783          	lh	a5,68(s3)
    80003ff0:	f97793e3          	bne	a5,s7,80003f76 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ff4:	000a8563          	beqz	s5,80003ffe <namex+0xe6>
    80003ff8:	0004c783          	lbu	a5,0(s1)
    80003ffc:	d3cd                	beqz	a5,80003f9e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ffe:	865a                	mv	a2,s6
    80004000:	85d2                	mv	a1,s4
    80004002:	854e                	mv	a0,s3
    80004004:	00000097          	auipc	ra,0x0
    80004008:	e64080e7          	jalr	-412(ra) # 80003e68 <dirlookup>
    8000400c:	8caa                	mv	s9,a0
    8000400e:	dd51                	beqz	a0,80003faa <namex+0x92>
    iunlockput(ip);
    80004010:	854e                	mv	a0,s3
    80004012:	00000097          	auipc	ra,0x0
    80004016:	bd4080e7          	jalr	-1068(ra) # 80003be6 <iunlockput>
    ip = next;
    8000401a:	89e6                	mv	s3,s9
  while(*path == '/')
    8000401c:	0004c783          	lbu	a5,0(s1)
    80004020:	05279763          	bne	a5,s2,8000406e <namex+0x156>
    path++;
    80004024:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004026:	0004c783          	lbu	a5,0(s1)
    8000402a:	ff278de3          	beq	a5,s2,80004024 <namex+0x10c>
  if(*path == 0)
    8000402e:	c79d                	beqz	a5,8000405c <namex+0x144>
    path++;
    80004030:	85a6                	mv	a1,s1
  len = path - s;
    80004032:	8cda                	mv	s9,s6
    80004034:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004036:	01278963          	beq	a5,s2,80004048 <namex+0x130>
    8000403a:	dfbd                	beqz	a5,80003fb8 <namex+0xa0>
    path++;
    8000403c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000403e:	0004c783          	lbu	a5,0(s1)
    80004042:	ff279ce3          	bne	a5,s2,8000403a <namex+0x122>
    80004046:	bf8d                	j	80003fb8 <namex+0xa0>
    memmove(name, s, len);
    80004048:	2601                	sext.w	a2,a2
    8000404a:	8552                	mv	a0,s4
    8000404c:	ffffd097          	auipc	ra,0xffffd
    80004050:	ce2080e7          	jalr	-798(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004054:	9cd2                	add	s9,s9,s4
    80004056:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000405a:	bf9d                	j	80003fd0 <namex+0xb8>
  if(nameiparent){
    8000405c:	f20a83e3          	beqz	s5,80003f82 <namex+0x6a>
    iput(ip);
    80004060:	854e                	mv	a0,s3
    80004062:	00000097          	auipc	ra,0x0
    80004066:	adc080e7          	jalr	-1316(ra) # 80003b3e <iput>
    return 0;
    8000406a:	4981                	li	s3,0
    8000406c:	bf19                	j	80003f82 <namex+0x6a>
  if(*path == 0)
    8000406e:	d7fd                	beqz	a5,8000405c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004070:	0004c783          	lbu	a5,0(s1)
    80004074:	85a6                	mv	a1,s1
    80004076:	b7d1                	j	8000403a <namex+0x122>

0000000080004078 <dirlink>:
{
    80004078:	7139                	addi	sp,sp,-64
    8000407a:	fc06                	sd	ra,56(sp)
    8000407c:	f822                	sd	s0,48(sp)
    8000407e:	f426                	sd	s1,40(sp)
    80004080:	f04a                	sd	s2,32(sp)
    80004082:	ec4e                	sd	s3,24(sp)
    80004084:	e852                	sd	s4,16(sp)
    80004086:	0080                	addi	s0,sp,64
    80004088:	892a                	mv	s2,a0
    8000408a:	8a2e                	mv	s4,a1
    8000408c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000408e:	4601                	li	a2,0
    80004090:	00000097          	auipc	ra,0x0
    80004094:	dd8080e7          	jalr	-552(ra) # 80003e68 <dirlookup>
    80004098:	e93d                	bnez	a0,8000410e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000409a:	04c92483          	lw	s1,76(s2)
    8000409e:	c49d                	beqz	s1,800040cc <dirlink+0x54>
    800040a0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040a2:	4741                	li	a4,16
    800040a4:	86a6                	mv	a3,s1
    800040a6:	fc040613          	addi	a2,s0,-64
    800040aa:	4581                	li	a1,0
    800040ac:	854a                	mv	a0,s2
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	b8a080e7          	jalr	-1142(ra) # 80003c38 <readi>
    800040b6:	47c1                	li	a5,16
    800040b8:	06f51163          	bne	a0,a5,8000411a <dirlink+0xa2>
    if(de.inum == 0)
    800040bc:	fc045783          	lhu	a5,-64(s0)
    800040c0:	c791                	beqz	a5,800040cc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c2:	24c1                	addiw	s1,s1,16
    800040c4:	04c92783          	lw	a5,76(s2)
    800040c8:	fcf4ede3          	bltu	s1,a5,800040a2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040cc:	4639                	li	a2,14
    800040ce:	85d2                	mv	a1,s4
    800040d0:	fc240513          	addi	a0,s0,-62
    800040d4:	ffffd097          	auipc	ra,0xffffd
    800040d8:	d0a080e7          	jalr	-758(ra) # 80000dde <strncpy>
  de.inum = inum;
    800040dc:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040e0:	4741                	li	a4,16
    800040e2:	86a6                	mv	a3,s1
    800040e4:	fc040613          	addi	a2,s0,-64
    800040e8:	4581                	li	a1,0
    800040ea:	854a                	mv	a0,s2
    800040ec:	00000097          	auipc	ra,0x0
    800040f0:	c44080e7          	jalr	-956(ra) # 80003d30 <writei>
    800040f4:	1541                	addi	a0,a0,-16
    800040f6:	00a03533          	snez	a0,a0
    800040fa:	40a00533          	neg	a0,a0
}
    800040fe:	70e2                	ld	ra,56(sp)
    80004100:	7442                	ld	s0,48(sp)
    80004102:	74a2                	ld	s1,40(sp)
    80004104:	7902                	ld	s2,32(sp)
    80004106:	69e2                	ld	s3,24(sp)
    80004108:	6a42                	ld	s4,16(sp)
    8000410a:	6121                	addi	sp,sp,64
    8000410c:	8082                	ret
    iput(ip);
    8000410e:	00000097          	auipc	ra,0x0
    80004112:	a30080e7          	jalr	-1488(ra) # 80003b3e <iput>
    return -1;
    80004116:	557d                	li	a0,-1
    80004118:	b7dd                	j	800040fe <dirlink+0x86>
      panic("dirlink read");
    8000411a:	00004517          	auipc	a0,0x4
    8000411e:	70650513          	addi	a0,a0,1798 # 80008820 <syscalls+0x300>
    80004122:	ffffc097          	auipc	ra,0xffffc
    80004126:	41c080e7          	jalr	1052(ra) # 8000053e <panic>

000000008000412a <namei>:

struct inode*
namei(char *path)
{
    8000412a:	1101                	addi	sp,sp,-32
    8000412c:	ec06                	sd	ra,24(sp)
    8000412e:	e822                	sd	s0,16(sp)
    80004130:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004132:	fe040613          	addi	a2,s0,-32
    80004136:	4581                	li	a1,0
    80004138:	00000097          	auipc	ra,0x0
    8000413c:	de0080e7          	jalr	-544(ra) # 80003f18 <namex>
}
    80004140:	60e2                	ld	ra,24(sp)
    80004142:	6442                	ld	s0,16(sp)
    80004144:	6105                	addi	sp,sp,32
    80004146:	8082                	ret

0000000080004148 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004148:	1141                	addi	sp,sp,-16
    8000414a:	e406                	sd	ra,8(sp)
    8000414c:	e022                	sd	s0,0(sp)
    8000414e:	0800                	addi	s0,sp,16
    80004150:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004152:	4585                	li	a1,1
    80004154:	00000097          	auipc	ra,0x0
    80004158:	dc4080e7          	jalr	-572(ra) # 80003f18 <namex>
}
    8000415c:	60a2                	ld	ra,8(sp)
    8000415e:	6402                	ld	s0,0(sp)
    80004160:	0141                	addi	sp,sp,16
    80004162:	8082                	ret

0000000080004164 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004164:	1101                	addi	sp,sp,-32
    80004166:	ec06                	sd	ra,24(sp)
    80004168:	e822                	sd	s0,16(sp)
    8000416a:	e426                	sd	s1,8(sp)
    8000416c:	e04a                	sd	s2,0(sp)
    8000416e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004170:	0001d917          	auipc	s2,0x1d
    80004174:	73090913          	addi	s2,s2,1840 # 800218a0 <log>
    80004178:	01892583          	lw	a1,24(s2)
    8000417c:	02892503          	lw	a0,40(s2)
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	fea080e7          	jalr	-22(ra) # 8000316a <bread>
    80004188:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000418a:	02c92683          	lw	a3,44(s2)
    8000418e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004190:	02d05763          	blez	a3,800041be <write_head+0x5a>
    80004194:	0001d797          	auipc	a5,0x1d
    80004198:	73c78793          	addi	a5,a5,1852 # 800218d0 <log+0x30>
    8000419c:	05c50713          	addi	a4,a0,92
    800041a0:	36fd                	addiw	a3,a3,-1
    800041a2:	1682                	slli	a3,a3,0x20
    800041a4:	9281                	srli	a3,a3,0x20
    800041a6:	068a                	slli	a3,a3,0x2
    800041a8:	0001d617          	auipc	a2,0x1d
    800041ac:	72c60613          	addi	a2,a2,1836 # 800218d4 <log+0x34>
    800041b0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041b2:	4390                	lw	a2,0(a5)
    800041b4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041b6:	0791                	addi	a5,a5,4
    800041b8:	0711                	addi	a4,a4,4
    800041ba:	fed79ce3          	bne	a5,a3,800041b2 <write_head+0x4e>
  }
  bwrite(buf);
    800041be:	8526                	mv	a0,s1
    800041c0:	fffff097          	auipc	ra,0xfffff
    800041c4:	09c080e7          	jalr	156(ra) # 8000325c <bwrite>
  brelse(buf);
    800041c8:	8526                	mv	a0,s1
    800041ca:	fffff097          	auipc	ra,0xfffff
    800041ce:	0d0080e7          	jalr	208(ra) # 8000329a <brelse>
}
    800041d2:	60e2                	ld	ra,24(sp)
    800041d4:	6442                	ld	s0,16(sp)
    800041d6:	64a2                	ld	s1,8(sp)
    800041d8:	6902                	ld	s2,0(sp)
    800041da:	6105                	addi	sp,sp,32
    800041dc:	8082                	ret

00000000800041de <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041de:	0001d797          	auipc	a5,0x1d
    800041e2:	6ee7a783          	lw	a5,1774(a5) # 800218cc <log+0x2c>
    800041e6:	0af05d63          	blez	a5,800042a0 <install_trans+0xc2>
{
    800041ea:	7139                	addi	sp,sp,-64
    800041ec:	fc06                	sd	ra,56(sp)
    800041ee:	f822                	sd	s0,48(sp)
    800041f0:	f426                	sd	s1,40(sp)
    800041f2:	f04a                	sd	s2,32(sp)
    800041f4:	ec4e                	sd	s3,24(sp)
    800041f6:	e852                	sd	s4,16(sp)
    800041f8:	e456                	sd	s5,8(sp)
    800041fa:	e05a                	sd	s6,0(sp)
    800041fc:	0080                	addi	s0,sp,64
    800041fe:	8b2a                	mv	s6,a0
    80004200:	0001da97          	auipc	s5,0x1d
    80004204:	6d0a8a93          	addi	s5,s5,1744 # 800218d0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004208:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000420a:	0001d997          	auipc	s3,0x1d
    8000420e:	69698993          	addi	s3,s3,1686 # 800218a0 <log>
    80004212:	a00d                	j	80004234 <install_trans+0x56>
    brelse(lbuf);
    80004214:	854a                	mv	a0,s2
    80004216:	fffff097          	auipc	ra,0xfffff
    8000421a:	084080e7          	jalr	132(ra) # 8000329a <brelse>
    brelse(dbuf);
    8000421e:	8526                	mv	a0,s1
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	07a080e7          	jalr	122(ra) # 8000329a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004228:	2a05                	addiw	s4,s4,1
    8000422a:	0a91                	addi	s5,s5,4
    8000422c:	02c9a783          	lw	a5,44(s3)
    80004230:	04fa5e63          	bge	s4,a5,8000428c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004234:	0189a583          	lw	a1,24(s3)
    80004238:	014585bb          	addw	a1,a1,s4
    8000423c:	2585                	addiw	a1,a1,1
    8000423e:	0289a503          	lw	a0,40(s3)
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	f28080e7          	jalr	-216(ra) # 8000316a <bread>
    8000424a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000424c:	000aa583          	lw	a1,0(s5)
    80004250:	0289a503          	lw	a0,40(s3)
    80004254:	fffff097          	auipc	ra,0xfffff
    80004258:	f16080e7          	jalr	-234(ra) # 8000316a <bread>
    8000425c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000425e:	40000613          	li	a2,1024
    80004262:	05890593          	addi	a1,s2,88
    80004266:	05850513          	addi	a0,a0,88
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	ac4080e7          	jalr	-1340(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004272:	8526                	mv	a0,s1
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	fe8080e7          	jalr	-24(ra) # 8000325c <bwrite>
    if(recovering == 0)
    8000427c:	f80b1ce3          	bnez	s6,80004214 <install_trans+0x36>
      bunpin(dbuf);
    80004280:	8526                	mv	a0,s1
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	0f2080e7          	jalr	242(ra) # 80003374 <bunpin>
    8000428a:	b769                	j	80004214 <install_trans+0x36>
}
    8000428c:	70e2                	ld	ra,56(sp)
    8000428e:	7442                	ld	s0,48(sp)
    80004290:	74a2                	ld	s1,40(sp)
    80004292:	7902                	ld	s2,32(sp)
    80004294:	69e2                	ld	s3,24(sp)
    80004296:	6a42                	ld	s4,16(sp)
    80004298:	6aa2                	ld	s5,8(sp)
    8000429a:	6b02                	ld	s6,0(sp)
    8000429c:	6121                	addi	sp,sp,64
    8000429e:	8082                	ret
    800042a0:	8082                	ret

00000000800042a2 <initlog>:
{
    800042a2:	7179                	addi	sp,sp,-48
    800042a4:	f406                	sd	ra,40(sp)
    800042a6:	f022                	sd	s0,32(sp)
    800042a8:	ec26                	sd	s1,24(sp)
    800042aa:	e84a                	sd	s2,16(sp)
    800042ac:	e44e                	sd	s3,8(sp)
    800042ae:	1800                	addi	s0,sp,48
    800042b0:	892a                	mv	s2,a0
    800042b2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042b4:	0001d497          	auipc	s1,0x1d
    800042b8:	5ec48493          	addi	s1,s1,1516 # 800218a0 <log>
    800042bc:	00004597          	auipc	a1,0x4
    800042c0:	57458593          	addi	a1,a1,1396 # 80008830 <syscalls+0x310>
    800042c4:	8526                	mv	a0,s1
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	880080e7          	jalr	-1920(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800042ce:	0149a583          	lw	a1,20(s3)
    800042d2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042d4:	0109a783          	lw	a5,16(s3)
    800042d8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042da:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042de:	854a                	mv	a0,s2
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	e8a080e7          	jalr	-374(ra) # 8000316a <bread>
  log.lh.n = lh->n;
    800042e8:	4d34                	lw	a3,88(a0)
    800042ea:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042ec:	02d05563          	blez	a3,80004316 <initlog+0x74>
    800042f0:	05c50793          	addi	a5,a0,92
    800042f4:	0001d717          	auipc	a4,0x1d
    800042f8:	5dc70713          	addi	a4,a4,1500 # 800218d0 <log+0x30>
    800042fc:	36fd                	addiw	a3,a3,-1
    800042fe:	1682                	slli	a3,a3,0x20
    80004300:	9281                	srli	a3,a3,0x20
    80004302:	068a                	slli	a3,a3,0x2
    80004304:	06050613          	addi	a2,a0,96
    80004308:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000430a:	4390                	lw	a2,0(a5)
    8000430c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000430e:	0791                	addi	a5,a5,4
    80004310:	0711                	addi	a4,a4,4
    80004312:	fed79ce3          	bne	a5,a3,8000430a <initlog+0x68>
  brelse(buf);
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	f84080e7          	jalr	-124(ra) # 8000329a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000431e:	4505                	li	a0,1
    80004320:	00000097          	auipc	ra,0x0
    80004324:	ebe080e7          	jalr	-322(ra) # 800041de <install_trans>
  log.lh.n = 0;
    80004328:	0001d797          	auipc	a5,0x1d
    8000432c:	5a07a223          	sw	zero,1444(a5) # 800218cc <log+0x2c>
  write_head(); // clear the log
    80004330:	00000097          	auipc	ra,0x0
    80004334:	e34080e7          	jalr	-460(ra) # 80004164 <write_head>
}
    80004338:	70a2                	ld	ra,40(sp)
    8000433a:	7402                	ld	s0,32(sp)
    8000433c:	64e2                	ld	s1,24(sp)
    8000433e:	6942                	ld	s2,16(sp)
    80004340:	69a2                	ld	s3,8(sp)
    80004342:	6145                	addi	sp,sp,48
    80004344:	8082                	ret

0000000080004346 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004346:	1101                	addi	sp,sp,-32
    80004348:	ec06                	sd	ra,24(sp)
    8000434a:	e822                	sd	s0,16(sp)
    8000434c:	e426                	sd	s1,8(sp)
    8000434e:	e04a                	sd	s2,0(sp)
    80004350:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004352:	0001d517          	auipc	a0,0x1d
    80004356:	54e50513          	addi	a0,a0,1358 # 800218a0 <log>
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004362:	0001d497          	auipc	s1,0x1d
    80004366:	53e48493          	addi	s1,s1,1342 # 800218a0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000436a:	4979                	li	s2,30
    8000436c:	a039                	j	8000437a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000436e:	85a6                	mv	a1,s1
    80004370:	8526                	mv	a0,s1
    80004372:	ffffe097          	auipc	ra,0xffffe
    80004376:	db0080e7          	jalr	-592(ra) # 80002122 <sleep>
    if(log.committing){
    8000437a:	50dc                	lw	a5,36(s1)
    8000437c:	fbed                	bnez	a5,8000436e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000437e:	509c                	lw	a5,32(s1)
    80004380:	0017871b          	addiw	a4,a5,1
    80004384:	0007069b          	sext.w	a3,a4
    80004388:	0027179b          	slliw	a5,a4,0x2
    8000438c:	9fb9                	addw	a5,a5,a4
    8000438e:	0017979b          	slliw	a5,a5,0x1
    80004392:	54d8                	lw	a4,44(s1)
    80004394:	9fb9                	addw	a5,a5,a4
    80004396:	00f95963          	bge	s2,a5,800043a8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000439a:	85a6                	mv	a1,s1
    8000439c:	8526                	mv	a0,s1
    8000439e:	ffffe097          	auipc	ra,0xffffe
    800043a2:	d84080e7          	jalr	-636(ra) # 80002122 <sleep>
    800043a6:	bfd1                	j	8000437a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043a8:	0001d517          	auipc	a0,0x1d
    800043ac:	4f850513          	addi	a0,a0,1272 # 800218a0 <log>
    800043b0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	8d8080e7          	jalr	-1832(ra) # 80000c8a <release>
      break;
    }
  }
}
    800043ba:	60e2                	ld	ra,24(sp)
    800043bc:	6442                	ld	s0,16(sp)
    800043be:	64a2                	ld	s1,8(sp)
    800043c0:	6902                	ld	s2,0(sp)
    800043c2:	6105                	addi	sp,sp,32
    800043c4:	8082                	ret

00000000800043c6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043c6:	7139                	addi	sp,sp,-64
    800043c8:	fc06                	sd	ra,56(sp)
    800043ca:	f822                	sd	s0,48(sp)
    800043cc:	f426                	sd	s1,40(sp)
    800043ce:	f04a                	sd	s2,32(sp)
    800043d0:	ec4e                	sd	s3,24(sp)
    800043d2:	e852                	sd	s4,16(sp)
    800043d4:	e456                	sd	s5,8(sp)
    800043d6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043d8:	0001d497          	auipc	s1,0x1d
    800043dc:	4c848493          	addi	s1,s1,1224 # 800218a0 <log>
    800043e0:	8526                	mv	a0,s1
    800043e2:	ffffc097          	auipc	ra,0xffffc
    800043e6:	7f4080e7          	jalr	2036(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800043ea:	509c                	lw	a5,32(s1)
    800043ec:	37fd                	addiw	a5,a5,-1
    800043ee:	0007891b          	sext.w	s2,a5
    800043f2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043f4:	50dc                	lw	a5,36(s1)
    800043f6:	e7b9                	bnez	a5,80004444 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043f8:	04091e63          	bnez	s2,80004454 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043fc:	0001d497          	auipc	s1,0x1d
    80004400:	4a448493          	addi	s1,s1,1188 # 800218a0 <log>
    80004404:	4785                	li	a5,1
    80004406:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004408:	8526                	mv	a0,s1
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	880080e7          	jalr	-1920(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004412:	54dc                	lw	a5,44(s1)
    80004414:	06f04763          	bgtz	a5,80004482 <end_op+0xbc>
    acquire(&log.lock);
    80004418:	0001d497          	auipc	s1,0x1d
    8000441c:	48848493          	addi	s1,s1,1160 # 800218a0 <log>
    80004420:	8526                	mv	a0,s1
    80004422:	ffffc097          	auipc	ra,0xffffc
    80004426:	7b4080e7          	jalr	1972(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000442a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000442e:	8526                	mv	a0,s1
    80004430:	ffffe097          	auipc	ra,0xffffe
    80004434:	d56080e7          	jalr	-682(ra) # 80002186 <wakeup>
    release(&log.lock);
    80004438:	8526                	mv	a0,s1
    8000443a:	ffffd097          	auipc	ra,0xffffd
    8000443e:	850080e7          	jalr	-1968(ra) # 80000c8a <release>
}
    80004442:	a03d                	j	80004470 <end_op+0xaa>
    panic("log.committing");
    80004444:	00004517          	auipc	a0,0x4
    80004448:	3f450513          	addi	a0,a0,1012 # 80008838 <syscalls+0x318>
    8000444c:	ffffc097          	auipc	ra,0xffffc
    80004450:	0f2080e7          	jalr	242(ra) # 8000053e <panic>
    wakeup(&log);
    80004454:	0001d497          	auipc	s1,0x1d
    80004458:	44c48493          	addi	s1,s1,1100 # 800218a0 <log>
    8000445c:	8526                	mv	a0,s1
    8000445e:	ffffe097          	auipc	ra,0xffffe
    80004462:	d28080e7          	jalr	-728(ra) # 80002186 <wakeup>
  release(&log.lock);
    80004466:	8526                	mv	a0,s1
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	822080e7          	jalr	-2014(ra) # 80000c8a <release>
}
    80004470:	70e2                	ld	ra,56(sp)
    80004472:	7442                	ld	s0,48(sp)
    80004474:	74a2                	ld	s1,40(sp)
    80004476:	7902                	ld	s2,32(sp)
    80004478:	69e2                	ld	s3,24(sp)
    8000447a:	6a42                	ld	s4,16(sp)
    8000447c:	6aa2                	ld	s5,8(sp)
    8000447e:	6121                	addi	sp,sp,64
    80004480:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004482:	0001da97          	auipc	s5,0x1d
    80004486:	44ea8a93          	addi	s5,s5,1102 # 800218d0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000448a:	0001da17          	auipc	s4,0x1d
    8000448e:	416a0a13          	addi	s4,s4,1046 # 800218a0 <log>
    80004492:	018a2583          	lw	a1,24(s4)
    80004496:	012585bb          	addw	a1,a1,s2
    8000449a:	2585                	addiw	a1,a1,1
    8000449c:	028a2503          	lw	a0,40(s4)
    800044a0:	fffff097          	auipc	ra,0xfffff
    800044a4:	cca080e7          	jalr	-822(ra) # 8000316a <bread>
    800044a8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044aa:	000aa583          	lw	a1,0(s5)
    800044ae:	028a2503          	lw	a0,40(s4)
    800044b2:	fffff097          	auipc	ra,0xfffff
    800044b6:	cb8080e7          	jalr	-840(ra) # 8000316a <bread>
    800044ba:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044bc:	40000613          	li	a2,1024
    800044c0:	05850593          	addi	a1,a0,88
    800044c4:	05848513          	addi	a0,s1,88
    800044c8:	ffffd097          	auipc	ra,0xffffd
    800044cc:	866080e7          	jalr	-1946(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800044d0:	8526                	mv	a0,s1
    800044d2:	fffff097          	auipc	ra,0xfffff
    800044d6:	d8a080e7          	jalr	-630(ra) # 8000325c <bwrite>
    brelse(from);
    800044da:	854e                	mv	a0,s3
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	dbe080e7          	jalr	-578(ra) # 8000329a <brelse>
    brelse(to);
    800044e4:	8526                	mv	a0,s1
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	db4080e7          	jalr	-588(ra) # 8000329a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ee:	2905                	addiw	s2,s2,1
    800044f0:	0a91                	addi	s5,s5,4
    800044f2:	02ca2783          	lw	a5,44(s4)
    800044f6:	f8f94ee3          	blt	s2,a5,80004492 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	c6a080e7          	jalr	-918(ra) # 80004164 <write_head>
    install_trans(0); // Now install writes to home locations
    80004502:	4501                	li	a0,0
    80004504:	00000097          	auipc	ra,0x0
    80004508:	cda080e7          	jalr	-806(ra) # 800041de <install_trans>
    log.lh.n = 0;
    8000450c:	0001d797          	auipc	a5,0x1d
    80004510:	3c07a023          	sw	zero,960(a5) # 800218cc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004514:	00000097          	auipc	ra,0x0
    80004518:	c50080e7          	jalr	-944(ra) # 80004164 <write_head>
    8000451c:	bdf5                	j	80004418 <end_op+0x52>

000000008000451e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000451e:	1101                	addi	sp,sp,-32
    80004520:	ec06                	sd	ra,24(sp)
    80004522:	e822                	sd	s0,16(sp)
    80004524:	e426                	sd	s1,8(sp)
    80004526:	e04a                	sd	s2,0(sp)
    80004528:	1000                	addi	s0,sp,32
    8000452a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000452c:	0001d917          	auipc	s2,0x1d
    80004530:	37490913          	addi	s2,s2,884 # 800218a0 <log>
    80004534:	854a                	mv	a0,s2
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	6a0080e7          	jalr	1696(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000453e:	02c92603          	lw	a2,44(s2)
    80004542:	47f5                	li	a5,29
    80004544:	06c7c563          	blt	a5,a2,800045ae <log_write+0x90>
    80004548:	0001d797          	auipc	a5,0x1d
    8000454c:	3747a783          	lw	a5,884(a5) # 800218bc <log+0x1c>
    80004550:	37fd                	addiw	a5,a5,-1
    80004552:	04f65e63          	bge	a2,a5,800045ae <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004556:	0001d797          	auipc	a5,0x1d
    8000455a:	36a7a783          	lw	a5,874(a5) # 800218c0 <log+0x20>
    8000455e:	06f05063          	blez	a5,800045be <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004562:	4781                	li	a5,0
    80004564:	06c05563          	blez	a2,800045ce <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004568:	44cc                	lw	a1,12(s1)
    8000456a:	0001d717          	auipc	a4,0x1d
    8000456e:	36670713          	addi	a4,a4,870 # 800218d0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004572:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004574:	4314                	lw	a3,0(a4)
    80004576:	04b68c63          	beq	a3,a1,800045ce <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000457a:	2785                	addiw	a5,a5,1
    8000457c:	0711                	addi	a4,a4,4
    8000457e:	fef61be3          	bne	a2,a5,80004574 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004582:	0621                	addi	a2,a2,8
    80004584:	060a                	slli	a2,a2,0x2
    80004586:	0001d797          	auipc	a5,0x1d
    8000458a:	31a78793          	addi	a5,a5,794 # 800218a0 <log>
    8000458e:	963e                	add	a2,a2,a5
    80004590:	44dc                	lw	a5,12(s1)
    80004592:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004594:	8526                	mv	a0,s1
    80004596:	fffff097          	auipc	ra,0xfffff
    8000459a:	da2080e7          	jalr	-606(ra) # 80003338 <bpin>
    log.lh.n++;
    8000459e:	0001d717          	auipc	a4,0x1d
    800045a2:	30270713          	addi	a4,a4,770 # 800218a0 <log>
    800045a6:	575c                	lw	a5,44(a4)
    800045a8:	2785                	addiw	a5,a5,1
    800045aa:	d75c                	sw	a5,44(a4)
    800045ac:	a835                	j	800045e8 <log_write+0xca>
    panic("too big a transaction");
    800045ae:	00004517          	auipc	a0,0x4
    800045b2:	29a50513          	addi	a0,a0,666 # 80008848 <syscalls+0x328>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	f88080e7          	jalr	-120(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800045be:	00004517          	auipc	a0,0x4
    800045c2:	2a250513          	addi	a0,a0,674 # 80008860 <syscalls+0x340>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	f78080e7          	jalr	-136(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800045ce:	00878713          	addi	a4,a5,8
    800045d2:	00271693          	slli	a3,a4,0x2
    800045d6:	0001d717          	auipc	a4,0x1d
    800045da:	2ca70713          	addi	a4,a4,714 # 800218a0 <log>
    800045de:	9736                	add	a4,a4,a3
    800045e0:	44d4                	lw	a3,12(s1)
    800045e2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045e4:	faf608e3          	beq	a2,a5,80004594 <log_write+0x76>
  }
  release(&log.lock);
    800045e8:	0001d517          	auipc	a0,0x1d
    800045ec:	2b850513          	addi	a0,a0,696 # 800218a0 <log>
    800045f0:	ffffc097          	auipc	ra,0xffffc
    800045f4:	69a080e7          	jalr	1690(ra) # 80000c8a <release>
}
    800045f8:	60e2                	ld	ra,24(sp)
    800045fa:	6442                	ld	s0,16(sp)
    800045fc:	64a2                	ld	s1,8(sp)
    800045fe:	6902                	ld	s2,0(sp)
    80004600:	6105                	addi	sp,sp,32
    80004602:	8082                	ret

0000000080004604 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004604:	1101                	addi	sp,sp,-32
    80004606:	ec06                	sd	ra,24(sp)
    80004608:	e822                	sd	s0,16(sp)
    8000460a:	e426                	sd	s1,8(sp)
    8000460c:	e04a                	sd	s2,0(sp)
    8000460e:	1000                	addi	s0,sp,32
    80004610:	84aa                	mv	s1,a0
    80004612:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004614:	00004597          	auipc	a1,0x4
    80004618:	26c58593          	addi	a1,a1,620 # 80008880 <syscalls+0x360>
    8000461c:	0521                	addi	a0,a0,8
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	528080e7          	jalr	1320(ra) # 80000b46 <initlock>
  lk->name = name;
    80004626:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000462a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000462e:	0204a423          	sw	zero,40(s1)
}
    80004632:	60e2                	ld	ra,24(sp)
    80004634:	6442                	ld	s0,16(sp)
    80004636:	64a2                	ld	s1,8(sp)
    80004638:	6902                	ld	s2,0(sp)
    8000463a:	6105                	addi	sp,sp,32
    8000463c:	8082                	ret

000000008000463e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000463e:	1101                	addi	sp,sp,-32
    80004640:	ec06                	sd	ra,24(sp)
    80004642:	e822                	sd	s0,16(sp)
    80004644:	e426                	sd	s1,8(sp)
    80004646:	e04a                	sd	s2,0(sp)
    80004648:	1000                	addi	s0,sp,32
    8000464a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000464c:	00850913          	addi	s2,a0,8
    80004650:	854a                	mv	a0,s2
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	584080e7          	jalr	1412(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000465a:	409c                	lw	a5,0(s1)
    8000465c:	cb89                	beqz	a5,8000466e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000465e:	85ca                	mv	a1,s2
    80004660:	8526                	mv	a0,s1
    80004662:	ffffe097          	auipc	ra,0xffffe
    80004666:	ac0080e7          	jalr	-1344(ra) # 80002122 <sleep>
  while (lk->locked) {
    8000466a:	409c                	lw	a5,0(s1)
    8000466c:	fbed                	bnez	a5,8000465e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000466e:	4785                	li	a5,1
    80004670:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004672:	ffffd097          	auipc	ra,0xffffd
    80004676:	370080e7          	jalr	880(ra) # 800019e2 <myproc>
    8000467a:	591c                	lw	a5,48(a0)
    8000467c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000467e:	854a                	mv	a0,s2
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	60a080e7          	jalr	1546(ra) # 80000c8a <release>
}
    80004688:	60e2                	ld	ra,24(sp)
    8000468a:	6442                	ld	s0,16(sp)
    8000468c:	64a2                	ld	s1,8(sp)
    8000468e:	6902                	ld	s2,0(sp)
    80004690:	6105                	addi	sp,sp,32
    80004692:	8082                	ret

0000000080004694 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004694:	1101                	addi	sp,sp,-32
    80004696:	ec06                	sd	ra,24(sp)
    80004698:	e822                	sd	s0,16(sp)
    8000469a:	e426                	sd	s1,8(sp)
    8000469c:	e04a                	sd	s2,0(sp)
    8000469e:	1000                	addi	s0,sp,32
    800046a0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046a2:	00850913          	addi	s2,a0,8
    800046a6:	854a                	mv	a0,s2
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	52e080e7          	jalr	1326(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800046b0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046b4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046b8:	8526                	mv	a0,s1
    800046ba:	ffffe097          	auipc	ra,0xffffe
    800046be:	acc080e7          	jalr	-1332(ra) # 80002186 <wakeup>
  release(&lk->lk);
    800046c2:	854a                	mv	a0,s2
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	5c6080e7          	jalr	1478(ra) # 80000c8a <release>
}
    800046cc:	60e2                	ld	ra,24(sp)
    800046ce:	6442                	ld	s0,16(sp)
    800046d0:	64a2                	ld	s1,8(sp)
    800046d2:	6902                	ld	s2,0(sp)
    800046d4:	6105                	addi	sp,sp,32
    800046d6:	8082                	ret

00000000800046d8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046d8:	7179                	addi	sp,sp,-48
    800046da:	f406                	sd	ra,40(sp)
    800046dc:	f022                	sd	s0,32(sp)
    800046de:	ec26                	sd	s1,24(sp)
    800046e0:	e84a                	sd	s2,16(sp)
    800046e2:	e44e                	sd	s3,8(sp)
    800046e4:	1800                	addi	s0,sp,48
    800046e6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046e8:	00850913          	addi	s2,a0,8
    800046ec:	854a                	mv	a0,s2
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	4e8080e7          	jalr	1256(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046f6:	409c                	lw	a5,0(s1)
    800046f8:	ef99                	bnez	a5,80004716 <holdingsleep+0x3e>
    800046fa:	4481                	li	s1,0
  release(&lk->lk);
    800046fc:	854a                	mv	a0,s2
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	58c080e7          	jalr	1420(ra) # 80000c8a <release>
  return r;
}
    80004706:	8526                	mv	a0,s1
    80004708:	70a2                	ld	ra,40(sp)
    8000470a:	7402                	ld	s0,32(sp)
    8000470c:	64e2                	ld	s1,24(sp)
    8000470e:	6942                	ld	s2,16(sp)
    80004710:	69a2                	ld	s3,8(sp)
    80004712:	6145                	addi	sp,sp,48
    80004714:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004716:	0284a983          	lw	s3,40(s1)
    8000471a:	ffffd097          	auipc	ra,0xffffd
    8000471e:	2c8080e7          	jalr	712(ra) # 800019e2 <myproc>
    80004722:	5904                	lw	s1,48(a0)
    80004724:	413484b3          	sub	s1,s1,s3
    80004728:	0014b493          	seqz	s1,s1
    8000472c:	bfc1                	j	800046fc <holdingsleep+0x24>

000000008000472e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000472e:	1141                	addi	sp,sp,-16
    80004730:	e406                	sd	ra,8(sp)
    80004732:	e022                	sd	s0,0(sp)
    80004734:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004736:	00004597          	auipc	a1,0x4
    8000473a:	15a58593          	addi	a1,a1,346 # 80008890 <syscalls+0x370>
    8000473e:	0001d517          	auipc	a0,0x1d
    80004742:	2aa50513          	addi	a0,a0,682 # 800219e8 <ftable>
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	400080e7          	jalr	1024(ra) # 80000b46 <initlock>
}
    8000474e:	60a2                	ld	ra,8(sp)
    80004750:	6402                	ld	s0,0(sp)
    80004752:	0141                	addi	sp,sp,16
    80004754:	8082                	ret

0000000080004756 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004756:	1101                	addi	sp,sp,-32
    80004758:	ec06                	sd	ra,24(sp)
    8000475a:	e822                	sd	s0,16(sp)
    8000475c:	e426                	sd	s1,8(sp)
    8000475e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004760:	0001d517          	auipc	a0,0x1d
    80004764:	28850513          	addi	a0,a0,648 # 800219e8 <ftable>
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	46e080e7          	jalr	1134(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004770:	0001d497          	auipc	s1,0x1d
    80004774:	29048493          	addi	s1,s1,656 # 80021a00 <ftable+0x18>
    80004778:	0001e717          	auipc	a4,0x1e
    8000477c:	22870713          	addi	a4,a4,552 # 800229a0 <disk>
    if(f->ref == 0){
    80004780:	40dc                	lw	a5,4(s1)
    80004782:	cf99                	beqz	a5,800047a0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004784:	02848493          	addi	s1,s1,40
    80004788:	fee49ce3          	bne	s1,a4,80004780 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000478c:	0001d517          	auipc	a0,0x1d
    80004790:	25c50513          	addi	a0,a0,604 # 800219e8 <ftable>
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	4f6080e7          	jalr	1270(ra) # 80000c8a <release>
  return 0;
    8000479c:	4481                	li	s1,0
    8000479e:	a819                	j	800047b4 <filealloc+0x5e>
      f->ref = 1;
    800047a0:	4785                	li	a5,1
    800047a2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047a4:	0001d517          	auipc	a0,0x1d
    800047a8:	24450513          	addi	a0,a0,580 # 800219e8 <ftable>
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	4de080e7          	jalr	1246(ra) # 80000c8a <release>
}
    800047b4:	8526                	mv	a0,s1
    800047b6:	60e2                	ld	ra,24(sp)
    800047b8:	6442                	ld	s0,16(sp)
    800047ba:	64a2                	ld	s1,8(sp)
    800047bc:	6105                	addi	sp,sp,32
    800047be:	8082                	ret

00000000800047c0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047c0:	1101                	addi	sp,sp,-32
    800047c2:	ec06                	sd	ra,24(sp)
    800047c4:	e822                	sd	s0,16(sp)
    800047c6:	e426                	sd	s1,8(sp)
    800047c8:	1000                	addi	s0,sp,32
    800047ca:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047cc:	0001d517          	auipc	a0,0x1d
    800047d0:	21c50513          	addi	a0,a0,540 # 800219e8 <ftable>
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	402080e7          	jalr	1026(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800047dc:	40dc                	lw	a5,4(s1)
    800047de:	02f05263          	blez	a5,80004802 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047e2:	2785                	addiw	a5,a5,1
    800047e4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047e6:	0001d517          	auipc	a0,0x1d
    800047ea:	20250513          	addi	a0,a0,514 # 800219e8 <ftable>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	49c080e7          	jalr	1180(ra) # 80000c8a <release>
  return f;
}
    800047f6:	8526                	mv	a0,s1
    800047f8:	60e2                	ld	ra,24(sp)
    800047fa:	6442                	ld	s0,16(sp)
    800047fc:	64a2                	ld	s1,8(sp)
    800047fe:	6105                	addi	sp,sp,32
    80004800:	8082                	ret
    panic("filedup");
    80004802:	00004517          	auipc	a0,0x4
    80004806:	09650513          	addi	a0,a0,150 # 80008898 <syscalls+0x378>
    8000480a:	ffffc097          	auipc	ra,0xffffc
    8000480e:	d34080e7          	jalr	-716(ra) # 8000053e <panic>

0000000080004812 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004812:	7139                	addi	sp,sp,-64
    80004814:	fc06                	sd	ra,56(sp)
    80004816:	f822                	sd	s0,48(sp)
    80004818:	f426                	sd	s1,40(sp)
    8000481a:	f04a                	sd	s2,32(sp)
    8000481c:	ec4e                	sd	s3,24(sp)
    8000481e:	e852                	sd	s4,16(sp)
    80004820:	e456                	sd	s5,8(sp)
    80004822:	0080                	addi	s0,sp,64
    80004824:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004826:	0001d517          	auipc	a0,0x1d
    8000482a:	1c250513          	addi	a0,a0,450 # 800219e8 <ftable>
    8000482e:	ffffc097          	auipc	ra,0xffffc
    80004832:	3a8080e7          	jalr	936(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004836:	40dc                	lw	a5,4(s1)
    80004838:	06f05163          	blez	a5,8000489a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000483c:	37fd                	addiw	a5,a5,-1
    8000483e:	0007871b          	sext.w	a4,a5
    80004842:	c0dc                	sw	a5,4(s1)
    80004844:	06e04363          	bgtz	a4,800048aa <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004848:	0004a903          	lw	s2,0(s1)
    8000484c:	0094ca83          	lbu	s5,9(s1)
    80004850:	0104ba03          	ld	s4,16(s1)
    80004854:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004858:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000485c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004860:	0001d517          	auipc	a0,0x1d
    80004864:	18850513          	addi	a0,a0,392 # 800219e8 <ftable>
    80004868:	ffffc097          	auipc	ra,0xffffc
    8000486c:	422080e7          	jalr	1058(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004870:	4785                	li	a5,1
    80004872:	04f90d63          	beq	s2,a5,800048cc <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004876:	3979                	addiw	s2,s2,-2
    80004878:	4785                	li	a5,1
    8000487a:	0527e063          	bltu	a5,s2,800048ba <fileclose+0xa8>
    begin_op();
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	ac8080e7          	jalr	-1336(ra) # 80004346 <begin_op>
    iput(ff.ip);
    80004886:	854e                	mv	a0,s3
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	2b6080e7          	jalr	694(ra) # 80003b3e <iput>
    end_op();
    80004890:	00000097          	auipc	ra,0x0
    80004894:	b36080e7          	jalr	-1226(ra) # 800043c6 <end_op>
    80004898:	a00d                	j	800048ba <fileclose+0xa8>
    panic("fileclose");
    8000489a:	00004517          	auipc	a0,0x4
    8000489e:	00650513          	addi	a0,a0,6 # 800088a0 <syscalls+0x380>
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	c9c080e7          	jalr	-868(ra) # 8000053e <panic>
    release(&ftable.lock);
    800048aa:	0001d517          	auipc	a0,0x1d
    800048ae:	13e50513          	addi	a0,a0,318 # 800219e8 <ftable>
    800048b2:	ffffc097          	auipc	ra,0xffffc
    800048b6:	3d8080e7          	jalr	984(ra) # 80000c8a <release>
  }
}
    800048ba:	70e2                	ld	ra,56(sp)
    800048bc:	7442                	ld	s0,48(sp)
    800048be:	74a2                	ld	s1,40(sp)
    800048c0:	7902                	ld	s2,32(sp)
    800048c2:	69e2                	ld	s3,24(sp)
    800048c4:	6a42                	ld	s4,16(sp)
    800048c6:	6aa2                	ld	s5,8(sp)
    800048c8:	6121                	addi	sp,sp,64
    800048ca:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048cc:	85d6                	mv	a1,s5
    800048ce:	8552                	mv	a0,s4
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	34c080e7          	jalr	844(ra) # 80004c1c <pipeclose>
    800048d8:	b7cd                	j	800048ba <fileclose+0xa8>

00000000800048da <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048da:	715d                	addi	sp,sp,-80
    800048dc:	e486                	sd	ra,72(sp)
    800048de:	e0a2                	sd	s0,64(sp)
    800048e0:	fc26                	sd	s1,56(sp)
    800048e2:	f84a                	sd	s2,48(sp)
    800048e4:	f44e                	sd	s3,40(sp)
    800048e6:	0880                	addi	s0,sp,80
    800048e8:	84aa                	mv	s1,a0
    800048ea:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048ec:	ffffd097          	auipc	ra,0xffffd
    800048f0:	0f6080e7          	jalr	246(ra) # 800019e2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048f4:	409c                	lw	a5,0(s1)
    800048f6:	37f9                	addiw	a5,a5,-2
    800048f8:	4705                	li	a4,1
    800048fa:	04f76763          	bltu	a4,a5,80004948 <filestat+0x6e>
    800048fe:	892a                	mv	s2,a0
    ilock(f->ip);
    80004900:	6c88                	ld	a0,24(s1)
    80004902:	fffff097          	auipc	ra,0xfffff
    80004906:	082080e7          	jalr	130(ra) # 80003984 <ilock>
    stati(f->ip, &st);
    8000490a:	fb840593          	addi	a1,s0,-72
    8000490e:	6c88                	ld	a0,24(s1)
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	2fe080e7          	jalr	766(ra) # 80003c0e <stati>
    iunlock(f->ip);
    80004918:	6c88                	ld	a0,24(s1)
    8000491a:	fffff097          	auipc	ra,0xfffff
    8000491e:	12c080e7          	jalr	300(ra) # 80003a46 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004922:	46e1                	li	a3,24
    80004924:	fb840613          	addi	a2,s0,-72
    80004928:	85ce                	mv	a1,s3
    8000492a:	05093503          	ld	a0,80(s2)
    8000492e:	ffffd097          	auipc	ra,0xffffd
    80004932:	d70080e7          	jalr	-656(ra) # 8000169e <copyout>
    80004936:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000493a:	60a6                	ld	ra,72(sp)
    8000493c:	6406                	ld	s0,64(sp)
    8000493e:	74e2                	ld	s1,56(sp)
    80004940:	7942                	ld	s2,48(sp)
    80004942:	79a2                	ld	s3,40(sp)
    80004944:	6161                	addi	sp,sp,80
    80004946:	8082                	ret
  return -1;
    80004948:	557d                	li	a0,-1
    8000494a:	bfc5                	j	8000493a <filestat+0x60>

000000008000494c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000494c:	7179                	addi	sp,sp,-48
    8000494e:	f406                	sd	ra,40(sp)
    80004950:	f022                	sd	s0,32(sp)
    80004952:	ec26                	sd	s1,24(sp)
    80004954:	e84a                	sd	s2,16(sp)
    80004956:	e44e                	sd	s3,8(sp)
    80004958:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000495a:	00854783          	lbu	a5,8(a0)
    8000495e:	c3d5                	beqz	a5,80004a02 <fileread+0xb6>
    80004960:	84aa                	mv	s1,a0
    80004962:	89ae                	mv	s3,a1
    80004964:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004966:	411c                	lw	a5,0(a0)
    80004968:	4705                	li	a4,1
    8000496a:	04e78963          	beq	a5,a4,800049bc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000496e:	470d                	li	a4,3
    80004970:	04e78d63          	beq	a5,a4,800049ca <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004974:	4709                	li	a4,2
    80004976:	06e79e63          	bne	a5,a4,800049f2 <fileread+0xa6>
    ilock(f->ip);
    8000497a:	6d08                	ld	a0,24(a0)
    8000497c:	fffff097          	auipc	ra,0xfffff
    80004980:	008080e7          	jalr	8(ra) # 80003984 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004984:	874a                	mv	a4,s2
    80004986:	5094                	lw	a3,32(s1)
    80004988:	864e                	mv	a2,s3
    8000498a:	4585                	li	a1,1
    8000498c:	6c88                	ld	a0,24(s1)
    8000498e:	fffff097          	auipc	ra,0xfffff
    80004992:	2aa080e7          	jalr	682(ra) # 80003c38 <readi>
    80004996:	892a                	mv	s2,a0
    80004998:	00a05563          	blez	a0,800049a2 <fileread+0x56>
      f->off += r;
    8000499c:	509c                	lw	a5,32(s1)
    8000499e:	9fa9                	addw	a5,a5,a0
    800049a0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049a2:	6c88                	ld	a0,24(s1)
    800049a4:	fffff097          	auipc	ra,0xfffff
    800049a8:	0a2080e7          	jalr	162(ra) # 80003a46 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049ac:	854a                	mv	a0,s2
    800049ae:	70a2                	ld	ra,40(sp)
    800049b0:	7402                	ld	s0,32(sp)
    800049b2:	64e2                	ld	s1,24(sp)
    800049b4:	6942                	ld	s2,16(sp)
    800049b6:	69a2                	ld	s3,8(sp)
    800049b8:	6145                	addi	sp,sp,48
    800049ba:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049bc:	6908                	ld	a0,16(a0)
    800049be:	00000097          	auipc	ra,0x0
    800049c2:	3c6080e7          	jalr	966(ra) # 80004d84 <piperead>
    800049c6:	892a                	mv	s2,a0
    800049c8:	b7d5                	j	800049ac <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049ca:	02451783          	lh	a5,36(a0)
    800049ce:	03079693          	slli	a3,a5,0x30
    800049d2:	92c1                	srli	a3,a3,0x30
    800049d4:	4725                	li	a4,9
    800049d6:	02d76863          	bltu	a4,a3,80004a06 <fileread+0xba>
    800049da:	0792                	slli	a5,a5,0x4
    800049dc:	0001d717          	auipc	a4,0x1d
    800049e0:	f6c70713          	addi	a4,a4,-148 # 80021948 <devsw>
    800049e4:	97ba                	add	a5,a5,a4
    800049e6:	639c                	ld	a5,0(a5)
    800049e8:	c38d                	beqz	a5,80004a0a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049ea:	4505                	li	a0,1
    800049ec:	9782                	jalr	a5
    800049ee:	892a                	mv	s2,a0
    800049f0:	bf75                	j	800049ac <fileread+0x60>
    panic("fileread");
    800049f2:	00004517          	auipc	a0,0x4
    800049f6:	ebe50513          	addi	a0,a0,-322 # 800088b0 <syscalls+0x390>
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	b44080e7          	jalr	-1212(ra) # 8000053e <panic>
    return -1;
    80004a02:	597d                	li	s2,-1
    80004a04:	b765                	j	800049ac <fileread+0x60>
      return -1;
    80004a06:	597d                	li	s2,-1
    80004a08:	b755                	j	800049ac <fileread+0x60>
    80004a0a:	597d                	li	s2,-1
    80004a0c:	b745                	j	800049ac <fileread+0x60>

0000000080004a0e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a0e:	715d                	addi	sp,sp,-80
    80004a10:	e486                	sd	ra,72(sp)
    80004a12:	e0a2                	sd	s0,64(sp)
    80004a14:	fc26                	sd	s1,56(sp)
    80004a16:	f84a                	sd	s2,48(sp)
    80004a18:	f44e                	sd	s3,40(sp)
    80004a1a:	f052                	sd	s4,32(sp)
    80004a1c:	ec56                	sd	s5,24(sp)
    80004a1e:	e85a                	sd	s6,16(sp)
    80004a20:	e45e                	sd	s7,8(sp)
    80004a22:	e062                	sd	s8,0(sp)
    80004a24:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a26:	00954783          	lbu	a5,9(a0)
    80004a2a:	10078663          	beqz	a5,80004b36 <filewrite+0x128>
    80004a2e:	892a                	mv	s2,a0
    80004a30:	8aae                	mv	s5,a1
    80004a32:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a34:	411c                	lw	a5,0(a0)
    80004a36:	4705                	li	a4,1
    80004a38:	02e78263          	beq	a5,a4,80004a5c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a3c:	470d                	li	a4,3
    80004a3e:	02e78663          	beq	a5,a4,80004a6a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a42:	4709                	li	a4,2
    80004a44:	0ee79163          	bne	a5,a4,80004b26 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a48:	0ac05d63          	blez	a2,80004b02 <filewrite+0xf4>
    int i = 0;
    80004a4c:	4981                	li	s3,0
    80004a4e:	6b05                	lui	s6,0x1
    80004a50:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a54:	6b85                	lui	s7,0x1
    80004a56:	c00b8b9b          	addiw	s7,s7,-1024
    80004a5a:	a861                	j	80004af2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a5c:	6908                	ld	a0,16(a0)
    80004a5e:	00000097          	auipc	ra,0x0
    80004a62:	22e080e7          	jalr	558(ra) # 80004c8c <pipewrite>
    80004a66:	8a2a                	mv	s4,a0
    80004a68:	a045                	j	80004b08 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a6a:	02451783          	lh	a5,36(a0)
    80004a6e:	03079693          	slli	a3,a5,0x30
    80004a72:	92c1                	srli	a3,a3,0x30
    80004a74:	4725                	li	a4,9
    80004a76:	0cd76263          	bltu	a4,a3,80004b3a <filewrite+0x12c>
    80004a7a:	0792                	slli	a5,a5,0x4
    80004a7c:	0001d717          	auipc	a4,0x1d
    80004a80:	ecc70713          	addi	a4,a4,-308 # 80021948 <devsw>
    80004a84:	97ba                	add	a5,a5,a4
    80004a86:	679c                	ld	a5,8(a5)
    80004a88:	cbdd                	beqz	a5,80004b3e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a8a:	4505                	li	a0,1
    80004a8c:	9782                	jalr	a5
    80004a8e:	8a2a                	mv	s4,a0
    80004a90:	a8a5                	j	80004b08 <filewrite+0xfa>
    80004a92:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a96:	00000097          	auipc	ra,0x0
    80004a9a:	8b0080e7          	jalr	-1872(ra) # 80004346 <begin_op>
      ilock(f->ip);
    80004a9e:	01893503          	ld	a0,24(s2)
    80004aa2:	fffff097          	auipc	ra,0xfffff
    80004aa6:	ee2080e7          	jalr	-286(ra) # 80003984 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aaa:	8762                	mv	a4,s8
    80004aac:	02092683          	lw	a3,32(s2)
    80004ab0:	01598633          	add	a2,s3,s5
    80004ab4:	4585                	li	a1,1
    80004ab6:	01893503          	ld	a0,24(s2)
    80004aba:	fffff097          	auipc	ra,0xfffff
    80004abe:	276080e7          	jalr	630(ra) # 80003d30 <writei>
    80004ac2:	84aa                	mv	s1,a0
    80004ac4:	00a05763          	blez	a0,80004ad2 <filewrite+0xc4>
        f->off += r;
    80004ac8:	02092783          	lw	a5,32(s2)
    80004acc:	9fa9                	addw	a5,a5,a0
    80004ace:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ad2:	01893503          	ld	a0,24(s2)
    80004ad6:	fffff097          	auipc	ra,0xfffff
    80004ada:	f70080e7          	jalr	-144(ra) # 80003a46 <iunlock>
      end_op();
    80004ade:	00000097          	auipc	ra,0x0
    80004ae2:	8e8080e7          	jalr	-1816(ra) # 800043c6 <end_op>

      if(r != n1){
    80004ae6:	009c1f63          	bne	s8,s1,80004b04 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004aea:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004aee:	0149db63          	bge	s3,s4,80004b04 <filewrite+0xf6>
      int n1 = n - i;
    80004af2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004af6:	84be                	mv	s1,a5
    80004af8:	2781                	sext.w	a5,a5
    80004afa:	f8fb5ce3          	bge	s6,a5,80004a92 <filewrite+0x84>
    80004afe:	84de                	mv	s1,s7
    80004b00:	bf49                	j	80004a92 <filewrite+0x84>
    int i = 0;
    80004b02:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b04:	013a1f63          	bne	s4,s3,80004b22 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b08:	8552                	mv	a0,s4
    80004b0a:	60a6                	ld	ra,72(sp)
    80004b0c:	6406                	ld	s0,64(sp)
    80004b0e:	74e2                	ld	s1,56(sp)
    80004b10:	7942                	ld	s2,48(sp)
    80004b12:	79a2                	ld	s3,40(sp)
    80004b14:	7a02                	ld	s4,32(sp)
    80004b16:	6ae2                	ld	s5,24(sp)
    80004b18:	6b42                	ld	s6,16(sp)
    80004b1a:	6ba2                	ld	s7,8(sp)
    80004b1c:	6c02                	ld	s8,0(sp)
    80004b1e:	6161                	addi	sp,sp,80
    80004b20:	8082                	ret
    ret = (i == n ? n : -1);
    80004b22:	5a7d                	li	s4,-1
    80004b24:	b7d5                	j	80004b08 <filewrite+0xfa>
    panic("filewrite");
    80004b26:	00004517          	auipc	a0,0x4
    80004b2a:	d9a50513          	addi	a0,a0,-614 # 800088c0 <syscalls+0x3a0>
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	a10080e7          	jalr	-1520(ra) # 8000053e <panic>
    return -1;
    80004b36:	5a7d                	li	s4,-1
    80004b38:	bfc1                	j	80004b08 <filewrite+0xfa>
      return -1;
    80004b3a:	5a7d                	li	s4,-1
    80004b3c:	b7f1                	j	80004b08 <filewrite+0xfa>
    80004b3e:	5a7d                	li	s4,-1
    80004b40:	b7e1                	j	80004b08 <filewrite+0xfa>

0000000080004b42 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b42:	7179                	addi	sp,sp,-48
    80004b44:	f406                	sd	ra,40(sp)
    80004b46:	f022                	sd	s0,32(sp)
    80004b48:	ec26                	sd	s1,24(sp)
    80004b4a:	e84a                	sd	s2,16(sp)
    80004b4c:	e44e                	sd	s3,8(sp)
    80004b4e:	e052                	sd	s4,0(sp)
    80004b50:	1800                	addi	s0,sp,48
    80004b52:	84aa                	mv	s1,a0
    80004b54:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b56:	0005b023          	sd	zero,0(a1)
    80004b5a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b5e:	00000097          	auipc	ra,0x0
    80004b62:	bf8080e7          	jalr	-1032(ra) # 80004756 <filealloc>
    80004b66:	e088                	sd	a0,0(s1)
    80004b68:	c551                	beqz	a0,80004bf4 <pipealloc+0xb2>
    80004b6a:	00000097          	auipc	ra,0x0
    80004b6e:	bec080e7          	jalr	-1044(ra) # 80004756 <filealloc>
    80004b72:	00aa3023          	sd	a0,0(s4)
    80004b76:	c92d                	beqz	a0,80004be8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b78:	ffffc097          	auipc	ra,0xffffc
    80004b7c:	f6e080e7          	jalr	-146(ra) # 80000ae6 <kalloc>
    80004b80:	892a                	mv	s2,a0
    80004b82:	c125                	beqz	a0,80004be2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b84:	4985                	li	s3,1
    80004b86:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b8a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b8e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b92:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b96:	00004597          	auipc	a1,0x4
    80004b9a:	d3a58593          	addi	a1,a1,-710 # 800088d0 <syscalls+0x3b0>
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	fa8080e7          	jalr	-88(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004ba6:	609c                	ld	a5,0(s1)
    80004ba8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bac:	609c                	ld	a5,0(s1)
    80004bae:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bb2:	609c                	ld	a5,0(s1)
    80004bb4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bb8:	609c                	ld	a5,0(s1)
    80004bba:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bbe:	000a3783          	ld	a5,0(s4)
    80004bc2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bc6:	000a3783          	ld	a5,0(s4)
    80004bca:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bce:	000a3783          	ld	a5,0(s4)
    80004bd2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bd6:	000a3783          	ld	a5,0(s4)
    80004bda:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bde:	4501                	li	a0,0
    80004be0:	a025                	j	80004c08 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004be2:	6088                	ld	a0,0(s1)
    80004be4:	e501                	bnez	a0,80004bec <pipealloc+0xaa>
    80004be6:	a039                	j	80004bf4 <pipealloc+0xb2>
    80004be8:	6088                	ld	a0,0(s1)
    80004bea:	c51d                	beqz	a0,80004c18 <pipealloc+0xd6>
    fileclose(*f0);
    80004bec:	00000097          	auipc	ra,0x0
    80004bf0:	c26080e7          	jalr	-986(ra) # 80004812 <fileclose>
  if(*f1)
    80004bf4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bf8:	557d                	li	a0,-1
  if(*f1)
    80004bfa:	c799                	beqz	a5,80004c08 <pipealloc+0xc6>
    fileclose(*f1);
    80004bfc:	853e                	mv	a0,a5
    80004bfe:	00000097          	auipc	ra,0x0
    80004c02:	c14080e7          	jalr	-1004(ra) # 80004812 <fileclose>
  return -1;
    80004c06:	557d                	li	a0,-1
}
    80004c08:	70a2                	ld	ra,40(sp)
    80004c0a:	7402                	ld	s0,32(sp)
    80004c0c:	64e2                	ld	s1,24(sp)
    80004c0e:	6942                	ld	s2,16(sp)
    80004c10:	69a2                	ld	s3,8(sp)
    80004c12:	6a02                	ld	s4,0(sp)
    80004c14:	6145                	addi	sp,sp,48
    80004c16:	8082                	ret
  return -1;
    80004c18:	557d                	li	a0,-1
    80004c1a:	b7fd                	j	80004c08 <pipealloc+0xc6>

0000000080004c1c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c1c:	1101                	addi	sp,sp,-32
    80004c1e:	ec06                	sd	ra,24(sp)
    80004c20:	e822                	sd	s0,16(sp)
    80004c22:	e426                	sd	s1,8(sp)
    80004c24:	e04a                	sd	s2,0(sp)
    80004c26:	1000                	addi	s0,sp,32
    80004c28:	84aa                	mv	s1,a0
    80004c2a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c2c:	ffffc097          	auipc	ra,0xffffc
    80004c30:	faa080e7          	jalr	-86(ra) # 80000bd6 <acquire>
  if(writable){
    80004c34:	02090d63          	beqz	s2,80004c6e <pipeclose+0x52>
    pi->writeopen = 0;
    80004c38:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c3c:	21848513          	addi	a0,s1,536
    80004c40:	ffffd097          	auipc	ra,0xffffd
    80004c44:	546080e7          	jalr	1350(ra) # 80002186 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c48:	2204b783          	ld	a5,544(s1)
    80004c4c:	eb95                	bnez	a5,80004c80 <pipeclose+0x64>
    release(&pi->lock);
    80004c4e:	8526                	mv	a0,s1
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	03a080e7          	jalr	58(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004c58:	8526                	mv	a0,s1
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	d90080e7          	jalr	-624(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004c62:	60e2                	ld	ra,24(sp)
    80004c64:	6442                	ld	s0,16(sp)
    80004c66:	64a2                	ld	s1,8(sp)
    80004c68:	6902                	ld	s2,0(sp)
    80004c6a:	6105                	addi	sp,sp,32
    80004c6c:	8082                	ret
    pi->readopen = 0;
    80004c6e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c72:	21c48513          	addi	a0,s1,540
    80004c76:	ffffd097          	auipc	ra,0xffffd
    80004c7a:	510080e7          	jalr	1296(ra) # 80002186 <wakeup>
    80004c7e:	b7e9                	j	80004c48 <pipeclose+0x2c>
    release(&pi->lock);
    80004c80:	8526                	mv	a0,s1
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	008080e7          	jalr	8(ra) # 80000c8a <release>
}
    80004c8a:	bfe1                	j	80004c62 <pipeclose+0x46>

0000000080004c8c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c8c:	711d                	addi	sp,sp,-96
    80004c8e:	ec86                	sd	ra,88(sp)
    80004c90:	e8a2                	sd	s0,80(sp)
    80004c92:	e4a6                	sd	s1,72(sp)
    80004c94:	e0ca                	sd	s2,64(sp)
    80004c96:	fc4e                	sd	s3,56(sp)
    80004c98:	f852                	sd	s4,48(sp)
    80004c9a:	f456                	sd	s5,40(sp)
    80004c9c:	f05a                	sd	s6,32(sp)
    80004c9e:	ec5e                	sd	s7,24(sp)
    80004ca0:	e862                	sd	s8,16(sp)
    80004ca2:	1080                	addi	s0,sp,96
    80004ca4:	84aa                	mv	s1,a0
    80004ca6:	8aae                	mv	s5,a1
    80004ca8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004caa:	ffffd097          	auipc	ra,0xffffd
    80004cae:	d38080e7          	jalr	-712(ra) # 800019e2 <myproc>
    80004cb2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	f20080e7          	jalr	-224(ra) # 80000bd6 <acquire>
  while(i < n){
    80004cbe:	0b405663          	blez	s4,80004d6a <pipewrite+0xde>
  int i = 0;
    80004cc2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cc4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cc6:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cca:	21c48b93          	addi	s7,s1,540
    80004cce:	a089                	j	80004d10 <pipewrite+0x84>
      release(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	fb8080e7          	jalr	-72(ra) # 80000c8a <release>
      return -1;
    80004cda:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cdc:	854a                	mv	a0,s2
    80004cde:	60e6                	ld	ra,88(sp)
    80004ce0:	6446                	ld	s0,80(sp)
    80004ce2:	64a6                	ld	s1,72(sp)
    80004ce4:	6906                	ld	s2,64(sp)
    80004ce6:	79e2                	ld	s3,56(sp)
    80004ce8:	7a42                	ld	s4,48(sp)
    80004cea:	7aa2                	ld	s5,40(sp)
    80004cec:	7b02                	ld	s6,32(sp)
    80004cee:	6be2                	ld	s7,24(sp)
    80004cf0:	6c42                	ld	s8,16(sp)
    80004cf2:	6125                	addi	sp,sp,96
    80004cf4:	8082                	ret
      wakeup(&pi->nread);
    80004cf6:	8562                	mv	a0,s8
    80004cf8:	ffffd097          	auipc	ra,0xffffd
    80004cfc:	48e080e7          	jalr	1166(ra) # 80002186 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d00:	85a6                	mv	a1,s1
    80004d02:	855e                	mv	a0,s7
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	41e080e7          	jalr	1054(ra) # 80002122 <sleep>
  while(i < n){
    80004d0c:	07495063          	bge	s2,s4,80004d6c <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004d10:	2204a783          	lw	a5,544(s1)
    80004d14:	dfd5                	beqz	a5,80004cd0 <pipewrite+0x44>
    80004d16:	854e                	mv	a0,s3
    80004d18:	ffffd097          	auipc	ra,0xffffd
    80004d1c:	6b2080e7          	jalr	1714(ra) # 800023ca <killed>
    80004d20:	f945                	bnez	a0,80004cd0 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d22:	2184a783          	lw	a5,536(s1)
    80004d26:	21c4a703          	lw	a4,540(s1)
    80004d2a:	2007879b          	addiw	a5,a5,512
    80004d2e:	fcf704e3          	beq	a4,a5,80004cf6 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d32:	4685                	li	a3,1
    80004d34:	01590633          	add	a2,s2,s5
    80004d38:	faf40593          	addi	a1,s0,-81
    80004d3c:	0509b503          	ld	a0,80(s3)
    80004d40:	ffffd097          	auipc	ra,0xffffd
    80004d44:	9ea080e7          	jalr	-1558(ra) # 8000172a <copyin>
    80004d48:	03650263          	beq	a0,s6,80004d6c <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d4c:	21c4a783          	lw	a5,540(s1)
    80004d50:	0017871b          	addiw	a4,a5,1
    80004d54:	20e4ae23          	sw	a4,540(s1)
    80004d58:	1ff7f793          	andi	a5,a5,511
    80004d5c:	97a6                	add	a5,a5,s1
    80004d5e:	faf44703          	lbu	a4,-81(s0)
    80004d62:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d66:	2905                	addiw	s2,s2,1
    80004d68:	b755                	j	80004d0c <pipewrite+0x80>
  int i = 0;
    80004d6a:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004d6c:	21848513          	addi	a0,s1,536
    80004d70:	ffffd097          	auipc	ra,0xffffd
    80004d74:	416080e7          	jalr	1046(ra) # 80002186 <wakeup>
  release(&pi->lock);
    80004d78:	8526                	mv	a0,s1
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	f10080e7          	jalr	-240(ra) # 80000c8a <release>
  return i;
    80004d82:	bfa9                	j	80004cdc <pipewrite+0x50>

0000000080004d84 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d84:	715d                	addi	sp,sp,-80
    80004d86:	e486                	sd	ra,72(sp)
    80004d88:	e0a2                	sd	s0,64(sp)
    80004d8a:	fc26                	sd	s1,56(sp)
    80004d8c:	f84a                	sd	s2,48(sp)
    80004d8e:	f44e                	sd	s3,40(sp)
    80004d90:	f052                	sd	s4,32(sp)
    80004d92:	ec56                	sd	s5,24(sp)
    80004d94:	e85a                	sd	s6,16(sp)
    80004d96:	0880                	addi	s0,sp,80
    80004d98:	84aa                	mv	s1,a0
    80004d9a:	892e                	mv	s2,a1
    80004d9c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d9e:	ffffd097          	auipc	ra,0xffffd
    80004da2:	c44080e7          	jalr	-956(ra) # 800019e2 <myproc>
    80004da6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004da8:	8526                	mv	a0,s1
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	e2c080e7          	jalr	-468(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004db2:	2184a703          	lw	a4,536(s1)
    80004db6:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dba:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dbe:	02f71763          	bne	a4,a5,80004dec <piperead+0x68>
    80004dc2:	2244a783          	lw	a5,548(s1)
    80004dc6:	c39d                	beqz	a5,80004dec <piperead+0x68>
    if(killed(pr)){
    80004dc8:	8552                	mv	a0,s4
    80004dca:	ffffd097          	auipc	ra,0xffffd
    80004dce:	600080e7          	jalr	1536(ra) # 800023ca <killed>
    80004dd2:	e941                	bnez	a0,80004e62 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dd4:	85a6                	mv	a1,s1
    80004dd6:	854e                	mv	a0,s3
    80004dd8:	ffffd097          	auipc	ra,0xffffd
    80004ddc:	34a080e7          	jalr	842(ra) # 80002122 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004de0:	2184a703          	lw	a4,536(s1)
    80004de4:	21c4a783          	lw	a5,540(s1)
    80004de8:	fcf70de3          	beq	a4,a5,80004dc2 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dec:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dee:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004df0:	05505363          	blez	s5,80004e36 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004df4:	2184a783          	lw	a5,536(s1)
    80004df8:	21c4a703          	lw	a4,540(s1)
    80004dfc:	02f70d63          	beq	a4,a5,80004e36 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e00:	0017871b          	addiw	a4,a5,1
    80004e04:	20e4ac23          	sw	a4,536(s1)
    80004e08:	1ff7f793          	andi	a5,a5,511
    80004e0c:	97a6                	add	a5,a5,s1
    80004e0e:	0187c783          	lbu	a5,24(a5)
    80004e12:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e16:	4685                	li	a3,1
    80004e18:	fbf40613          	addi	a2,s0,-65
    80004e1c:	85ca                	mv	a1,s2
    80004e1e:	050a3503          	ld	a0,80(s4)
    80004e22:	ffffd097          	auipc	ra,0xffffd
    80004e26:	87c080e7          	jalr	-1924(ra) # 8000169e <copyout>
    80004e2a:	01650663          	beq	a0,s6,80004e36 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e2e:	2985                	addiw	s3,s3,1
    80004e30:	0905                	addi	s2,s2,1
    80004e32:	fd3a91e3          	bne	s5,s3,80004df4 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e36:	21c48513          	addi	a0,s1,540
    80004e3a:	ffffd097          	auipc	ra,0xffffd
    80004e3e:	34c080e7          	jalr	844(ra) # 80002186 <wakeup>
  release(&pi->lock);
    80004e42:	8526                	mv	a0,s1
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	e46080e7          	jalr	-442(ra) # 80000c8a <release>
  return i;
}
    80004e4c:	854e                	mv	a0,s3
    80004e4e:	60a6                	ld	ra,72(sp)
    80004e50:	6406                	ld	s0,64(sp)
    80004e52:	74e2                	ld	s1,56(sp)
    80004e54:	7942                	ld	s2,48(sp)
    80004e56:	79a2                	ld	s3,40(sp)
    80004e58:	7a02                	ld	s4,32(sp)
    80004e5a:	6ae2                	ld	s5,24(sp)
    80004e5c:	6b42                	ld	s6,16(sp)
    80004e5e:	6161                	addi	sp,sp,80
    80004e60:	8082                	ret
      release(&pi->lock);
    80004e62:	8526                	mv	a0,s1
    80004e64:	ffffc097          	auipc	ra,0xffffc
    80004e68:	e26080e7          	jalr	-474(ra) # 80000c8a <release>
      return -1;
    80004e6c:	59fd                	li	s3,-1
    80004e6e:	bff9                	j	80004e4c <piperead+0xc8>

0000000080004e70 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e70:	1141                	addi	sp,sp,-16
    80004e72:	e422                	sd	s0,8(sp)
    80004e74:	0800                	addi	s0,sp,16
    80004e76:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e78:	8905                	andi	a0,a0,1
    80004e7a:	c111                	beqz	a0,80004e7e <flags2perm+0xe>
      perm = PTE_X;
    80004e7c:	4521                	li	a0,8
    if(flags & 0x2)
    80004e7e:	8b89                	andi	a5,a5,2
    80004e80:	c399                	beqz	a5,80004e86 <flags2perm+0x16>
      perm |= PTE_W;
    80004e82:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e86:	6422                	ld	s0,8(sp)
    80004e88:	0141                	addi	sp,sp,16
    80004e8a:	8082                	ret

0000000080004e8c <exec>:

int
exec(char *path, char **argv)
{
    80004e8c:	de010113          	addi	sp,sp,-544
    80004e90:	20113c23          	sd	ra,536(sp)
    80004e94:	20813823          	sd	s0,528(sp)
    80004e98:	20913423          	sd	s1,520(sp)
    80004e9c:	21213023          	sd	s2,512(sp)
    80004ea0:	ffce                	sd	s3,504(sp)
    80004ea2:	fbd2                	sd	s4,496(sp)
    80004ea4:	f7d6                	sd	s5,488(sp)
    80004ea6:	f3da                	sd	s6,480(sp)
    80004ea8:	efde                	sd	s7,472(sp)
    80004eaa:	ebe2                	sd	s8,464(sp)
    80004eac:	e7e6                	sd	s9,456(sp)
    80004eae:	e3ea                	sd	s10,448(sp)
    80004eb0:	ff6e                	sd	s11,440(sp)
    80004eb2:	1400                	addi	s0,sp,544
    80004eb4:	892a                	mv	s2,a0
    80004eb6:	dea43423          	sd	a0,-536(s0)
    80004eba:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ebe:	ffffd097          	auipc	ra,0xffffd
    80004ec2:	b24080e7          	jalr	-1244(ra) # 800019e2 <myproc>
    80004ec6:	84aa                	mv	s1,a0

  begin_op();
    80004ec8:	fffff097          	auipc	ra,0xfffff
    80004ecc:	47e080e7          	jalr	1150(ra) # 80004346 <begin_op>

  if((ip = namei(path)) == 0){
    80004ed0:	854a                	mv	a0,s2
    80004ed2:	fffff097          	auipc	ra,0xfffff
    80004ed6:	258080e7          	jalr	600(ra) # 8000412a <namei>
    80004eda:	c93d                	beqz	a0,80004f50 <exec+0xc4>
    80004edc:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ede:	fffff097          	auipc	ra,0xfffff
    80004ee2:	aa6080e7          	jalr	-1370(ra) # 80003984 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ee6:	04000713          	li	a4,64
    80004eea:	4681                	li	a3,0
    80004eec:	e5040613          	addi	a2,s0,-432
    80004ef0:	4581                	li	a1,0
    80004ef2:	8556                	mv	a0,s5
    80004ef4:	fffff097          	auipc	ra,0xfffff
    80004ef8:	d44080e7          	jalr	-700(ra) # 80003c38 <readi>
    80004efc:	04000793          	li	a5,64
    80004f00:	00f51a63          	bne	a0,a5,80004f14 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f04:	e5042703          	lw	a4,-432(s0)
    80004f08:	464c47b7          	lui	a5,0x464c4
    80004f0c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f10:	04f70663          	beq	a4,a5,80004f5c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f14:	8556                	mv	a0,s5
    80004f16:	fffff097          	auipc	ra,0xfffff
    80004f1a:	cd0080e7          	jalr	-816(ra) # 80003be6 <iunlockput>
    end_op();
    80004f1e:	fffff097          	auipc	ra,0xfffff
    80004f22:	4a8080e7          	jalr	1192(ra) # 800043c6 <end_op>
  }
  return -1;
    80004f26:	557d                	li	a0,-1
}
    80004f28:	21813083          	ld	ra,536(sp)
    80004f2c:	21013403          	ld	s0,528(sp)
    80004f30:	20813483          	ld	s1,520(sp)
    80004f34:	20013903          	ld	s2,512(sp)
    80004f38:	79fe                	ld	s3,504(sp)
    80004f3a:	7a5e                	ld	s4,496(sp)
    80004f3c:	7abe                	ld	s5,488(sp)
    80004f3e:	7b1e                	ld	s6,480(sp)
    80004f40:	6bfe                	ld	s7,472(sp)
    80004f42:	6c5e                	ld	s8,464(sp)
    80004f44:	6cbe                	ld	s9,456(sp)
    80004f46:	6d1e                	ld	s10,448(sp)
    80004f48:	7dfa                	ld	s11,440(sp)
    80004f4a:	22010113          	addi	sp,sp,544
    80004f4e:	8082                	ret
    end_op();
    80004f50:	fffff097          	auipc	ra,0xfffff
    80004f54:	476080e7          	jalr	1142(ra) # 800043c6 <end_op>
    return -1;
    80004f58:	557d                	li	a0,-1
    80004f5a:	b7f9                	j	80004f28 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f5c:	8526                	mv	a0,s1
    80004f5e:	ffffd097          	auipc	ra,0xffffd
    80004f62:	b48080e7          	jalr	-1208(ra) # 80001aa6 <proc_pagetable>
    80004f66:	8b2a                	mv	s6,a0
    80004f68:	d555                	beqz	a0,80004f14 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f6a:	e7042783          	lw	a5,-400(s0)
    80004f6e:	e8845703          	lhu	a4,-376(s0)
    80004f72:	c735                	beqz	a4,80004fde <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f74:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f76:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f7a:	6a05                	lui	s4,0x1
    80004f7c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f80:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004f84:	6d85                	lui	s11,0x1
    80004f86:	7d7d                	lui	s10,0xfffff
    80004f88:	a481                	j	800051c8 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f8a:	00004517          	auipc	a0,0x4
    80004f8e:	94e50513          	addi	a0,a0,-1714 # 800088d8 <syscalls+0x3b8>
    80004f92:	ffffb097          	auipc	ra,0xffffb
    80004f96:	5ac080e7          	jalr	1452(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f9a:	874a                	mv	a4,s2
    80004f9c:	009c86bb          	addw	a3,s9,s1
    80004fa0:	4581                	li	a1,0
    80004fa2:	8556                	mv	a0,s5
    80004fa4:	fffff097          	auipc	ra,0xfffff
    80004fa8:	c94080e7          	jalr	-876(ra) # 80003c38 <readi>
    80004fac:	2501                	sext.w	a0,a0
    80004fae:	1aa91a63          	bne	s2,a0,80005162 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004fb2:	009d84bb          	addw	s1,s11,s1
    80004fb6:	013d09bb          	addw	s3,s10,s3
    80004fba:	1f74f763          	bgeu	s1,s7,800051a8 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004fbe:	02049593          	slli	a1,s1,0x20
    80004fc2:	9181                	srli	a1,a1,0x20
    80004fc4:	95e2                	add	a1,a1,s8
    80004fc6:	855a                	mv	a0,s6
    80004fc8:	ffffc097          	auipc	ra,0xffffc
    80004fcc:	0b4080e7          	jalr	180(ra) # 8000107c <walkaddr>
    80004fd0:	862a                	mv	a2,a0
    if(pa == 0)
    80004fd2:	dd45                	beqz	a0,80004f8a <exec+0xfe>
      n = PGSIZE;
    80004fd4:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004fd6:	fd49f2e3          	bgeu	s3,s4,80004f9a <exec+0x10e>
      n = sz - i;
    80004fda:	894e                	mv	s2,s3
    80004fdc:	bf7d                	j	80004f9a <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fde:	4901                	li	s2,0
  iunlockput(ip);
    80004fe0:	8556                	mv	a0,s5
    80004fe2:	fffff097          	auipc	ra,0xfffff
    80004fe6:	c04080e7          	jalr	-1020(ra) # 80003be6 <iunlockput>
  end_op();
    80004fea:	fffff097          	auipc	ra,0xfffff
    80004fee:	3dc080e7          	jalr	988(ra) # 800043c6 <end_op>
  p = myproc();
    80004ff2:	ffffd097          	auipc	ra,0xffffd
    80004ff6:	9f0080e7          	jalr	-1552(ra) # 800019e2 <myproc>
    80004ffa:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004ffc:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005000:	6785                	lui	a5,0x1
    80005002:	17fd                	addi	a5,a5,-1
    80005004:	993e                	add	s2,s2,a5
    80005006:	77fd                	lui	a5,0xfffff
    80005008:	00f977b3          	and	a5,s2,a5
    8000500c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005010:	4691                	li	a3,4
    80005012:	6609                	lui	a2,0x2
    80005014:	963e                	add	a2,a2,a5
    80005016:	85be                	mv	a1,a5
    80005018:	855a                	mv	a0,s6
    8000501a:	ffffc097          	auipc	ra,0xffffc
    8000501e:	42c080e7          	jalr	1068(ra) # 80001446 <uvmalloc>
    80005022:	8c2a                	mv	s8,a0
  ip = 0;
    80005024:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005026:	12050e63          	beqz	a0,80005162 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000502a:	75f9                	lui	a1,0xffffe
    8000502c:	95aa                	add	a1,a1,a0
    8000502e:	855a                	mv	a0,s6
    80005030:	ffffc097          	auipc	ra,0xffffc
    80005034:	63c080e7          	jalr	1596(ra) # 8000166c <uvmclear>
  stackbase = sp - PGSIZE;
    80005038:	7afd                	lui	s5,0xfffff
    8000503a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000503c:	df043783          	ld	a5,-528(s0)
    80005040:	6388                	ld	a0,0(a5)
    80005042:	c925                	beqz	a0,800050b2 <exec+0x226>
    80005044:	e9040993          	addi	s3,s0,-368
    80005048:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000504c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000504e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	dfe080e7          	jalr	-514(ra) # 80000e4e <strlen>
    80005058:	0015079b          	addiw	a5,a0,1
    8000505c:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005060:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005064:	13596663          	bltu	s2,s5,80005190 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005068:	df043d83          	ld	s11,-528(s0)
    8000506c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005070:	8552                	mv	a0,s4
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	ddc080e7          	jalr	-548(ra) # 80000e4e <strlen>
    8000507a:	0015069b          	addiw	a3,a0,1
    8000507e:	8652                	mv	a2,s4
    80005080:	85ca                	mv	a1,s2
    80005082:	855a                	mv	a0,s6
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	61a080e7          	jalr	1562(ra) # 8000169e <copyout>
    8000508c:	10054663          	bltz	a0,80005198 <exec+0x30c>
    ustack[argc] = sp;
    80005090:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005094:	0485                	addi	s1,s1,1
    80005096:	008d8793          	addi	a5,s11,8
    8000509a:	def43823          	sd	a5,-528(s0)
    8000509e:	008db503          	ld	a0,8(s11)
    800050a2:	c911                	beqz	a0,800050b6 <exec+0x22a>
    if(argc >= MAXARG)
    800050a4:	09a1                	addi	s3,s3,8
    800050a6:	fb3c95e3          	bne	s9,s3,80005050 <exec+0x1c4>
  sz = sz1;
    800050aa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ae:	4a81                	li	s5,0
    800050b0:	a84d                	j	80005162 <exec+0x2d6>
  sp = sz;
    800050b2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050b4:	4481                	li	s1,0
  ustack[argc] = 0;
    800050b6:	00349793          	slli	a5,s1,0x3
    800050ba:	f9040713          	addi	a4,s0,-112
    800050be:	97ba                	add	a5,a5,a4
    800050c0:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd8128>
  sp -= (argc+1) * sizeof(uint64);
    800050c4:	00148693          	addi	a3,s1,1
    800050c8:	068e                	slli	a3,a3,0x3
    800050ca:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050ce:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050d2:	01597663          	bgeu	s2,s5,800050de <exec+0x252>
  sz = sz1;
    800050d6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050da:	4a81                	li	s5,0
    800050dc:	a059                	j	80005162 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050de:	e9040613          	addi	a2,s0,-368
    800050e2:	85ca                	mv	a1,s2
    800050e4:	855a                	mv	a0,s6
    800050e6:	ffffc097          	auipc	ra,0xffffc
    800050ea:	5b8080e7          	jalr	1464(ra) # 8000169e <copyout>
    800050ee:	0a054963          	bltz	a0,800051a0 <exec+0x314>
  p->trapframe->a1 = sp;
    800050f2:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800050f6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050fa:	de843783          	ld	a5,-536(s0)
    800050fe:	0007c703          	lbu	a4,0(a5)
    80005102:	cf11                	beqz	a4,8000511e <exec+0x292>
    80005104:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005106:	02f00693          	li	a3,47
    8000510a:	a039                	j	80005118 <exec+0x28c>
      last = s+1;
    8000510c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005110:	0785                	addi	a5,a5,1
    80005112:	fff7c703          	lbu	a4,-1(a5)
    80005116:	c701                	beqz	a4,8000511e <exec+0x292>
    if(*s == '/')
    80005118:	fed71ce3          	bne	a4,a3,80005110 <exec+0x284>
    8000511c:	bfc5                	j	8000510c <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    8000511e:	4641                	li	a2,16
    80005120:	de843583          	ld	a1,-536(s0)
    80005124:	158b8513          	addi	a0,s7,344
    80005128:	ffffc097          	auipc	ra,0xffffc
    8000512c:	cf4080e7          	jalr	-780(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005130:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005134:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005138:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000513c:	058bb783          	ld	a5,88(s7)
    80005140:	e6843703          	ld	a4,-408(s0)
    80005144:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005146:	058bb783          	ld	a5,88(s7)
    8000514a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000514e:	85ea                	mv	a1,s10
    80005150:	ffffd097          	auipc	ra,0xffffd
    80005154:	9f2080e7          	jalr	-1550(ra) # 80001b42 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005158:	0004851b          	sext.w	a0,s1
    8000515c:	b3f1                	j	80004f28 <exec+0x9c>
    8000515e:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005162:	df843583          	ld	a1,-520(s0)
    80005166:	855a                	mv	a0,s6
    80005168:	ffffd097          	auipc	ra,0xffffd
    8000516c:	9da080e7          	jalr	-1574(ra) # 80001b42 <proc_freepagetable>
  if(ip){
    80005170:	da0a92e3          	bnez	s5,80004f14 <exec+0x88>
  return -1;
    80005174:	557d                	li	a0,-1
    80005176:	bb4d                	j	80004f28 <exec+0x9c>
    80005178:	df243c23          	sd	s2,-520(s0)
    8000517c:	b7dd                	j	80005162 <exec+0x2d6>
    8000517e:	df243c23          	sd	s2,-520(s0)
    80005182:	b7c5                	j	80005162 <exec+0x2d6>
    80005184:	df243c23          	sd	s2,-520(s0)
    80005188:	bfe9                	j	80005162 <exec+0x2d6>
    8000518a:	df243c23          	sd	s2,-520(s0)
    8000518e:	bfd1                	j	80005162 <exec+0x2d6>
  sz = sz1;
    80005190:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005194:	4a81                	li	s5,0
    80005196:	b7f1                	j	80005162 <exec+0x2d6>
  sz = sz1;
    80005198:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000519c:	4a81                	li	s5,0
    8000519e:	b7d1                	j	80005162 <exec+0x2d6>
  sz = sz1;
    800051a0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051a4:	4a81                	li	s5,0
    800051a6:	bf75                	j	80005162 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051a8:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051ac:	e0843783          	ld	a5,-504(s0)
    800051b0:	0017869b          	addiw	a3,a5,1
    800051b4:	e0d43423          	sd	a3,-504(s0)
    800051b8:	e0043783          	ld	a5,-512(s0)
    800051bc:	0387879b          	addiw	a5,a5,56
    800051c0:	e8845703          	lhu	a4,-376(s0)
    800051c4:	e0e6dee3          	bge	a3,a4,80004fe0 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051c8:	2781                	sext.w	a5,a5
    800051ca:	e0f43023          	sd	a5,-512(s0)
    800051ce:	03800713          	li	a4,56
    800051d2:	86be                	mv	a3,a5
    800051d4:	e1840613          	addi	a2,s0,-488
    800051d8:	4581                	li	a1,0
    800051da:	8556                	mv	a0,s5
    800051dc:	fffff097          	auipc	ra,0xfffff
    800051e0:	a5c080e7          	jalr	-1444(ra) # 80003c38 <readi>
    800051e4:	03800793          	li	a5,56
    800051e8:	f6f51be3          	bne	a0,a5,8000515e <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    800051ec:	e1842783          	lw	a5,-488(s0)
    800051f0:	4705                	li	a4,1
    800051f2:	fae79de3          	bne	a5,a4,800051ac <exec+0x320>
    if(ph.memsz < ph.filesz)
    800051f6:	e4043483          	ld	s1,-448(s0)
    800051fa:	e3843783          	ld	a5,-456(s0)
    800051fe:	f6f4ede3          	bltu	s1,a5,80005178 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005202:	e2843783          	ld	a5,-472(s0)
    80005206:	94be                	add	s1,s1,a5
    80005208:	f6f4ebe3          	bltu	s1,a5,8000517e <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000520c:	de043703          	ld	a4,-544(s0)
    80005210:	8ff9                	and	a5,a5,a4
    80005212:	fbad                	bnez	a5,80005184 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005214:	e1c42503          	lw	a0,-484(s0)
    80005218:	00000097          	auipc	ra,0x0
    8000521c:	c58080e7          	jalr	-936(ra) # 80004e70 <flags2perm>
    80005220:	86aa                	mv	a3,a0
    80005222:	8626                	mv	a2,s1
    80005224:	85ca                	mv	a1,s2
    80005226:	855a                	mv	a0,s6
    80005228:	ffffc097          	auipc	ra,0xffffc
    8000522c:	21e080e7          	jalr	542(ra) # 80001446 <uvmalloc>
    80005230:	dea43c23          	sd	a0,-520(s0)
    80005234:	d939                	beqz	a0,8000518a <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005236:	e2843c03          	ld	s8,-472(s0)
    8000523a:	e2042c83          	lw	s9,-480(s0)
    8000523e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005242:	f60b83e3          	beqz	s7,800051a8 <exec+0x31c>
    80005246:	89de                	mv	s3,s7
    80005248:	4481                	li	s1,0
    8000524a:	bb95                	j	80004fbe <exec+0x132>

000000008000524c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000524c:	7179                	addi	sp,sp,-48
    8000524e:	f406                	sd	ra,40(sp)
    80005250:	f022                	sd	s0,32(sp)
    80005252:	ec26                	sd	s1,24(sp)
    80005254:	e84a                	sd	s2,16(sp)
    80005256:	1800                	addi	s0,sp,48
    80005258:	892e                	mv	s2,a1
    8000525a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000525c:	fdc40593          	addi	a1,s0,-36
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	a96080e7          	jalr	-1386(ra) # 80002cf6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005268:	fdc42703          	lw	a4,-36(s0)
    8000526c:	47bd                	li	a5,15
    8000526e:	02e7eb63          	bltu	a5,a4,800052a4 <argfd+0x58>
    80005272:	ffffc097          	auipc	ra,0xffffc
    80005276:	770080e7          	jalr	1904(ra) # 800019e2 <myproc>
    8000527a:	fdc42703          	lw	a4,-36(s0)
    8000527e:	01a70793          	addi	a5,a4,26
    80005282:	078e                	slli	a5,a5,0x3
    80005284:	953e                	add	a0,a0,a5
    80005286:	611c                	ld	a5,0(a0)
    80005288:	c385                	beqz	a5,800052a8 <argfd+0x5c>
    return -1;
  if(pfd)
    8000528a:	00090463          	beqz	s2,80005292 <argfd+0x46>
    *pfd = fd;
    8000528e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005292:	4501                	li	a0,0
  if(pf)
    80005294:	c091                	beqz	s1,80005298 <argfd+0x4c>
    *pf = f;
    80005296:	e09c                	sd	a5,0(s1)
}
    80005298:	70a2                	ld	ra,40(sp)
    8000529a:	7402                	ld	s0,32(sp)
    8000529c:	64e2                	ld	s1,24(sp)
    8000529e:	6942                	ld	s2,16(sp)
    800052a0:	6145                	addi	sp,sp,48
    800052a2:	8082                	ret
    return -1;
    800052a4:	557d                	li	a0,-1
    800052a6:	bfcd                	j	80005298 <argfd+0x4c>
    800052a8:	557d                	li	a0,-1
    800052aa:	b7fd                	j	80005298 <argfd+0x4c>

00000000800052ac <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052ac:	1101                	addi	sp,sp,-32
    800052ae:	ec06                	sd	ra,24(sp)
    800052b0:	e822                	sd	s0,16(sp)
    800052b2:	e426                	sd	s1,8(sp)
    800052b4:	1000                	addi	s0,sp,32
    800052b6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	72a080e7          	jalr	1834(ra) # 800019e2 <myproc>
    800052c0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052c2:	0d050793          	addi	a5,a0,208
    800052c6:	4501                	li	a0,0
    800052c8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052ca:	6398                	ld	a4,0(a5)
    800052cc:	cb19                	beqz	a4,800052e2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052ce:	2505                	addiw	a0,a0,1
    800052d0:	07a1                	addi	a5,a5,8
    800052d2:	fed51ce3          	bne	a0,a3,800052ca <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052d6:	557d                	li	a0,-1
}
    800052d8:	60e2                	ld	ra,24(sp)
    800052da:	6442                	ld	s0,16(sp)
    800052dc:	64a2                	ld	s1,8(sp)
    800052de:	6105                	addi	sp,sp,32
    800052e0:	8082                	ret
      p->ofile[fd] = f;
    800052e2:	01a50793          	addi	a5,a0,26
    800052e6:	078e                	slli	a5,a5,0x3
    800052e8:	963e                	add	a2,a2,a5
    800052ea:	e204                	sd	s1,0(a2)
      return fd;
    800052ec:	b7f5                	j	800052d8 <fdalloc+0x2c>

00000000800052ee <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052ee:	715d                	addi	sp,sp,-80
    800052f0:	e486                	sd	ra,72(sp)
    800052f2:	e0a2                	sd	s0,64(sp)
    800052f4:	fc26                	sd	s1,56(sp)
    800052f6:	f84a                	sd	s2,48(sp)
    800052f8:	f44e                	sd	s3,40(sp)
    800052fa:	f052                	sd	s4,32(sp)
    800052fc:	ec56                	sd	s5,24(sp)
    800052fe:	e85a                	sd	s6,16(sp)
    80005300:	0880                	addi	s0,sp,80
    80005302:	8b2e                	mv	s6,a1
    80005304:	89b2                	mv	s3,a2
    80005306:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005308:	fb040593          	addi	a1,s0,-80
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	e3c080e7          	jalr	-452(ra) # 80004148 <nameiparent>
    80005314:	84aa                	mv	s1,a0
    80005316:	14050f63          	beqz	a0,80005474 <create+0x186>
    return 0;

  ilock(dp);
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	66a080e7          	jalr	1642(ra) # 80003984 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005322:	4601                	li	a2,0
    80005324:	fb040593          	addi	a1,s0,-80
    80005328:	8526                	mv	a0,s1
    8000532a:	fffff097          	auipc	ra,0xfffff
    8000532e:	b3e080e7          	jalr	-1218(ra) # 80003e68 <dirlookup>
    80005332:	8aaa                	mv	s5,a0
    80005334:	c931                	beqz	a0,80005388 <create+0x9a>
    iunlockput(dp);
    80005336:	8526                	mv	a0,s1
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	8ae080e7          	jalr	-1874(ra) # 80003be6 <iunlockput>
    ilock(ip);
    80005340:	8556                	mv	a0,s5
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	642080e7          	jalr	1602(ra) # 80003984 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000534a:	000b059b          	sext.w	a1,s6
    8000534e:	4789                	li	a5,2
    80005350:	02f59563          	bne	a1,a5,8000537a <create+0x8c>
    80005354:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd826c>
    80005358:	37f9                	addiw	a5,a5,-2
    8000535a:	17c2                	slli	a5,a5,0x30
    8000535c:	93c1                	srli	a5,a5,0x30
    8000535e:	4705                	li	a4,1
    80005360:	00f76d63          	bltu	a4,a5,8000537a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005364:	8556                	mv	a0,s5
    80005366:	60a6                	ld	ra,72(sp)
    80005368:	6406                	ld	s0,64(sp)
    8000536a:	74e2                	ld	s1,56(sp)
    8000536c:	7942                	ld	s2,48(sp)
    8000536e:	79a2                	ld	s3,40(sp)
    80005370:	7a02                	ld	s4,32(sp)
    80005372:	6ae2                	ld	s5,24(sp)
    80005374:	6b42                	ld	s6,16(sp)
    80005376:	6161                	addi	sp,sp,80
    80005378:	8082                	ret
    iunlockput(ip);
    8000537a:	8556                	mv	a0,s5
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	86a080e7          	jalr	-1942(ra) # 80003be6 <iunlockput>
    return 0;
    80005384:	4a81                	li	s5,0
    80005386:	bff9                	j	80005364 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005388:	85da                	mv	a1,s6
    8000538a:	4088                	lw	a0,0(s1)
    8000538c:	ffffe097          	auipc	ra,0xffffe
    80005390:	45c080e7          	jalr	1116(ra) # 800037e8 <ialloc>
    80005394:	8a2a                	mv	s4,a0
    80005396:	c539                	beqz	a0,800053e4 <create+0xf6>
  ilock(ip);
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	5ec080e7          	jalr	1516(ra) # 80003984 <ilock>
  ip->major = major;
    800053a0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800053a4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800053a8:	4905                	li	s2,1
    800053aa:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800053ae:	8552                	mv	a0,s4
    800053b0:	ffffe097          	auipc	ra,0xffffe
    800053b4:	50a080e7          	jalr	1290(ra) # 800038ba <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053b8:	000b059b          	sext.w	a1,s6
    800053bc:	03258b63          	beq	a1,s2,800053f2 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800053c0:	004a2603          	lw	a2,4(s4)
    800053c4:	fb040593          	addi	a1,s0,-80
    800053c8:	8526                	mv	a0,s1
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	cae080e7          	jalr	-850(ra) # 80004078 <dirlink>
    800053d2:	06054f63          	bltz	a0,80005450 <create+0x162>
  iunlockput(dp);
    800053d6:	8526                	mv	a0,s1
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	80e080e7          	jalr	-2034(ra) # 80003be6 <iunlockput>
  return ip;
    800053e0:	8ad2                	mv	s5,s4
    800053e2:	b749                	j	80005364 <create+0x76>
    iunlockput(dp);
    800053e4:	8526                	mv	a0,s1
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	800080e7          	jalr	-2048(ra) # 80003be6 <iunlockput>
    return 0;
    800053ee:	8ad2                	mv	s5,s4
    800053f0:	bf95                	j	80005364 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053f2:	004a2603          	lw	a2,4(s4)
    800053f6:	00003597          	auipc	a1,0x3
    800053fa:	50258593          	addi	a1,a1,1282 # 800088f8 <syscalls+0x3d8>
    800053fe:	8552                	mv	a0,s4
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	c78080e7          	jalr	-904(ra) # 80004078 <dirlink>
    80005408:	04054463          	bltz	a0,80005450 <create+0x162>
    8000540c:	40d0                	lw	a2,4(s1)
    8000540e:	00003597          	auipc	a1,0x3
    80005412:	4f258593          	addi	a1,a1,1266 # 80008900 <syscalls+0x3e0>
    80005416:	8552                	mv	a0,s4
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	c60080e7          	jalr	-928(ra) # 80004078 <dirlink>
    80005420:	02054863          	bltz	a0,80005450 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005424:	004a2603          	lw	a2,4(s4)
    80005428:	fb040593          	addi	a1,s0,-80
    8000542c:	8526                	mv	a0,s1
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	c4a080e7          	jalr	-950(ra) # 80004078 <dirlink>
    80005436:	00054d63          	bltz	a0,80005450 <create+0x162>
    dp->nlink++;  // for ".."
    8000543a:	04a4d783          	lhu	a5,74(s1)
    8000543e:	2785                	addiw	a5,a5,1
    80005440:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005444:	8526                	mv	a0,s1
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	474080e7          	jalr	1140(ra) # 800038ba <iupdate>
    8000544e:	b761                	j	800053d6 <create+0xe8>
  ip->nlink = 0;
    80005450:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005454:	8552                	mv	a0,s4
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	464080e7          	jalr	1124(ra) # 800038ba <iupdate>
  iunlockput(ip);
    8000545e:	8552                	mv	a0,s4
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	786080e7          	jalr	1926(ra) # 80003be6 <iunlockput>
  iunlockput(dp);
    80005468:	8526                	mv	a0,s1
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	77c080e7          	jalr	1916(ra) # 80003be6 <iunlockput>
  return 0;
    80005472:	bdcd                	j	80005364 <create+0x76>
    return 0;
    80005474:	8aaa                	mv	s5,a0
    80005476:	b5fd                	j	80005364 <create+0x76>

0000000080005478 <sys_dup>:
{
    80005478:	7179                	addi	sp,sp,-48
    8000547a:	f406                	sd	ra,40(sp)
    8000547c:	f022                	sd	s0,32(sp)
    8000547e:	ec26                	sd	s1,24(sp)
    80005480:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005482:	fd840613          	addi	a2,s0,-40
    80005486:	4581                	li	a1,0
    80005488:	4501                	li	a0,0
    8000548a:	00000097          	auipc	ra,0x0
    8000548e:	dc2080e7          	jalr	-574(ra) # 8000524c <argfd>
    return -1;
    80005492:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005494:	02054363          	bltz	a0,800054ba <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005498:	fd843503          	ld	a0,-40(s0)
    8000549c:	00000097          	auipc	ra,0x0
    800054a0:	e10080e7          	jalr	-496(ra) # 800052ac <fdalloc>
    800054a4:	84aa                	mv	s1,a0
    return -1;
    800054a6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054a8:	00054963          	bltz	a0,800054ba <sys_dup+0x42>
  filedup(f);
    800054ac:	fd843503          	ld	a0,-40(s0)
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	310080e7          	jalr	784(ra) # 800047c0 <filedup>
  return fd;
    800054b8:	87a6                	mv	a5,s1
}
    800054ba:	853e                	mv	a0,a5
    800054bc:	70a2                	ld	ra,40(sp)
    800054be:	7402                	ld	s0,32(sp)
    800054c0:	64e2                	ld	s1,24(sp)
    800054c2:	6145                	addi	sp,sp,48
    800054c4:	8082                	ret

00000000800054c6 <sys_read>:
{
    800054c6:	7179                	addi	sp,sp,-48
    800054c8:	f406                	sd	ra,40(sp)
    800054ca:	f022                	sd	s0,32(sp)
    800054cc:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054ce:	fd840593          	addi	a1,s0,-40
    800054d2:	4505                	li	a0,1
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	842080e7          	jalr	-1982(ra) # 80002d16 <argaddr>
  argint(2, &n);
    800054dc:	fe440593          	addi	a1,s0,-28
    800054e0:	4509                	li	a0,2
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	814080e7          	jalr	-2028(ra) # 80002cf6 <argint>
  if(argfd(0, 0, &f) < 0)
    800054ea:	fe840613          	addi	a2,s0,-24
    800054ee:	4581                	li	a1,0
    800054f0:	4501                	li	a0,0
    800054f2:	00000097          	auipc	ra,0x0
    800054f6:	d5a080e7          	jalr	-678(ra) # 8000524c <argfd>
    800054fa:	87aa                	mv	a5,a0
    return -1;
    800054fc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054fe:	0007cc63          	bltz	a5,80005516 <sys_read+0x50>
  return fileread(f, p, n);
    80005502:	fe442603          	lw	a2,-28(s0)
    80005506:	fd843583          	ld	a1,-40(s0)
    8000550a:	fe843503          	ld	a0,-24(s0)
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	43e080e7          	jalr	1086(ra) # 8000494c <fileread>
}
    80005516:	70a2                	ld	ra,40(sp)
    80005518:	7402                	ld	s0,32(sp)
    8000551a:	6145                	addi	sp,sp,48
    8000551c:	8082                	ret

000000008000551e <sys_write>:
{
    8000551e:	7179                	addi	sp,sp,-48
    80005520:	f406                	sd	ra,40(sp)
    80005522:	f022                	sd	s0,32(sp)
    80005524:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005526:	fd840593          	addi	a1,s0,-40
    8000552a:	4505                	li	a0,1
    8000552c:	ffffd097          	auipc	ra,0xffffd
    80005530:	7ea080e7          	jalr	2026(ra) # 80002d16 <argaddr>
  argint(2, &n);
    80005534:	fe440593          	addi	a1,s0,-28
    80005538:	4509                	li	a0,2
    8000553a:	ffffd097          	auipc	ra,0xffffd
    8000553e:	7bc080e7          	jalr	1980(ra) # 80002cf6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005542:	fe840613          	addi	a2,s0,-24
    80005546:	4581                	li	a1,0
    80005548:	4501                	li	a0,0
    8000554a:	00000097          	auipc	ra,0x0
    8000554e:	d02080e7          	jalr	-766(ra) # 8000524c <argfd>
    80005552:	87aa                	mv	a5,a0
    return -1;
    80005554:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005556:	0007cc63          	bltz	a5,8000556e <sys_write+0x50>
  return filewrite(f, p, n);
    8000555a:	fe442603          	lw	a2,-28(s0)
    8000555e:	fd843583          	ld	a1,-40(s0)
    80005562:	fe843503          	ld	a0,-24(s0)
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	4a8080e7          	jalr	1192(ra) # 80004a0e <filewrite>
}
    8000556e:	70a2                	ld	ra,40(sp)
    80005570:	7402                	ld	s0,32(sp)
    80005572:	6145                	addi	sp,sp,48
    80005574:	8082                	ret

0000000080005576 <sys_close>:
{
    80005576:	1101                	addi	sp,sp,-32
    80005578:	ec06                	sd	ra,24(sp)
    8000557a:	e822                	sd	s0,16(sp)
    8000557c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000557e:	fe040613          	addi	a2,s0,-32
    80005582:	fec40593          	addi	a1,s0,-20
    80005586:	4501                	li	a0,0
    80005588:	00000097          	auipc	ra,0x0
    8000558c:	cc4080e7          	jalr	-828(ra) # 8000524c <argfd>
    return -1;
    80005590:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005592:	02054463          	bltz	a0,800055ba <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005596:	ffffc097          	auipc	ra,0xffffc
    8000559a:	44c080e7          	jalr	1100(ra) # 800019e2 <myproc>
    8000559e:	fec42783          	lw	a5,-20(s0)
    800055a2:	07e9                	addi	a5,a5,26
    800055a4:	078e                	slli	a5,a5,0x3
    800055a6:	97aa                	add	a5,a5,a0
    800055a8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055ac:	fe043503          	ld	a0,-32(s0)
    800055b0:	fffff097          	auipc	ra,0xfffff
    800055b4:	262080e7          	jalr	610(ra) # 80004812 <fileclose>
  return 0;
    800055b8:	4781                	li	a5,0
}
    800055ba:	853e                	mv	a0,a5
    800055bc:	60e2                	ld	ra,24(sp)
    800055be:	6442                	ld	s0,16(sp)
    800055c0:	6105                	addi	sp,sp,32
    800055c2:	8082                	ret

00000000800055c4 <sys_fstat>:
{
    800055c4:	1101                	addi	sp,sp,-32
    800055c6:	ec06                	sd	ra,24(sp)
    800055c8:	e822                	sd	s0,16(sp)
    800055ca:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800055cc:	fe040593          	addi	a1,s0,-32
    800055d0:	4505                	li	a0,1
    800055d2:	ffffd097          	auipc	ra,0xffffd
    800055d6:	744080e7          	jalr	1860(ra) # 80002d16 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800055da:	fe840613          	addi	a2,s0,-24
    800055de:	4581                	li	a1,0
    800055e0:	4501                	li	a0,0
    800055e2:	00000097          	auipc	ra,0x0
    800055e6:	c6a080e7          	jalr	-918(ra) # 8000524c <argfd>
    800055ea:	87aa                	mv	a5,a0
    return -1;
    800055ec:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055ee:	0007ca63          	bltz	a5,80005602 <sys_fstat+0x3e>
  return filestat(f, st);
    800055f2:	fe043583          	ld	a1,-32(s0)
    800055f6:	fe843503          	ld	a0,-24(s0)
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	2e0080e7          	jalr	736(ra) # 800048da <filestat>
}
    80005602:	60e2                	ld	ra,24(sp)
    80005604:	6442                	ld	s0,16(sp)
    80005606:	6105                	addi	sp,sp,32
    80005608:	8082                	ret

000000008000560a <sys_link>:
{
    8000560a:	7169                	addi	sp,sp,-304
    8000560c:	f606                	sd	ra,296(sp)
    8000560e:	f222                	sd	s0,288(sp)
    80005610:	ee26                	sd	s1,280(sp)
    80005612:	ea4a                	sd	s2,272(sp)
    80005614:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005616:	08000613          	li	a2,128
    8000561a:	ed040593          	addi	a1,s0,-304
    8000561e:	4501                	li	a0,0
    80005620:	ffffd097          	auipc	ra,0xffffd
    80005624:	716080e7          	jalr	1814(ra) # 80002d36 <argstr>
    return -1;
    80005628:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000562a:	10054e63          	bltz	a0,80005746 <sys_link+0x13c>
    8000562e:	08000613          	li	a2,128
    80005632:	f5040593          	addi	a1,s0,-176
    80005636:	4505                	li	a0,1
    80005638:	ffffd097          	auipc	ra,0xffffd
    8000563c:	6fe080e7          	jalr	1790(ra) # 80002d36 <argstr>
    return -1;
    80005640:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005642:	10054263          	bltz	a0,80005746 <sys_link+0x13c>
  begin_op();
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	d00080e7          	jalr	-768(ra) # 80004346 <begin_op>
  if((ip = namei(old)) == 0){
    8000564e:	ed040513          	addi	a0,s0,-304
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	ad8080e7          	jalr	-1320(ra) # 8000412a <namei>
    8000565a:	84aa                	mv	s1,a0
    8000565c:	c551                	beqz	a0,800056e8 <sys_link+0xde>
  ilock(ip);
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	326080e7          	jalr	806(ra) # 80003984 <ilock>
  if(ip->type == T_DIR){
    80005666:	04449703          	lh	a4,68(s1)
    8000566a:	4785                	li	a5,1
    8000566c:	08f70463          	beq	a4,a5,800056f4 <sys_link+0xea>
  ip->nlink++;
    80005670:	04a4d783          	lhu	a5,74(s1)
    80005674:	2785                	addiw	a5,a5,1
    80005676:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000567a:	8526                	mv	a0,s1
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	23e080e7          	jalr	574(ra) # 800038ba <iupdate>
  iunlock(ip);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	3c0080e7          	jalr	960(ra) # 80003a46 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000568e:	fd040593          	addi	a1,s0,-48
    80005692:	f5040513          	addi	a0,s0,-176
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	ab2080e7          	jalr	-1358(ra) # 80004148 <nameiparent>
    8000569e:	892a                	mv	s2,a0
    800056a0:	c935                	beqz	a0,80005714 <sys_link+0x10a>
  ilock(dp);
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	2e2080e7          	jalr	738(ra) # 80003984 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056aa:	00092703          	lw	a4,0(s2)
    800056ae:	409c                	lw	a5,0(s1)
    800056b0:	04f71d63          	bne	a4,a5,8000570a <sys_link+0x100>
    800056b4:	40d0                	lw	a2,4(s1)
    800056b6:	fd040593          	addi	a1,s0,-48
    800056ba:	854a                	mv	a0,s2
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	9bc080e7          	jalr	-1604(ra) # 80004078 <dirlink>
    800056c4:	04054363          	bltz	a0,8000570a <sys_link+0x100>
  iunlockput(dp);
    800056c8:	854a                	mv	a0,s2
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	51c080e7          	jalr	1308(ra) # 80003be6 <iunlockput>
  iput(ip);
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	46a080e7          	jalr	1130(ra) # 80003b3e <iput>
  end_op();
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	cea080e7          	jalr	-790(ra) # 800043c6 <end_op>
  return 0;
    800056e4:	4781                	li	a5,0
    800056e6:	a085                	j	80005746 <sys_link+0x13c>
    end_op();
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	cde080e7          	jalr	-802(ra) # 800043c6 <end_op>
    return -1;
    800056f0:	57fd                	li	a5,-1
    800056f2:	a891                	j	80005746 <sys_link+0x13c>
    iunlockput(ip);
    800056f4:	8526                	mv	a0,s1
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	4f0080e7          	jalr	1264(ra) # 80003be6 <iunlockput>
    end_op();
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	cc8080e7          	jalr	-824(ra) # 800043c6 <end_op>
    return -1;
    80005706:	57fd                	li	a5,-1
    80005708:	a83d                	j	80005746 <sys_link+0x13c>
    iunlockput(dp);
    8000570a:	854a                	mv	a0,s2
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	4da080e7          	jalr	1242(ra) # 80003be6 <iunlockput>
  ilock(ip);
    80005714:	8526                	mv	a0,s1
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	26e080e7          	jalr	622(ra) # 80003984 <ilock>
  ip->nlink--;
    8000571e:	04a4d783          	lhu	a5,74(s1)
    80005722:	37fd                	addiw	a5,a5,-1
    80005724:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	190080e7          	jalr	400(ra) # 800038ba <iupdate>
  iunlockput(ip);
    80005732:	8526                	mv	a0,s1
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	4b2080e7          	jalr	1202(ra) # 80003be6 <iunlockput>
  end_op();
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	c8a080e7          	jalr	-886(ra) # 800043c6 <end_op>
  return -1;
    80005744:	57fd                	li	a5,-1
}
    80005746:	853e                	mv	a0,a5
    80005748:	70b2                	ld	ra,296(sp)
    8000574a:	7412                	ld	s0,288(sp)
    8000574c:	64f2                	ld	s1,280(sp)
    8000574e:	6952                	ld	s2,272(sp)
    80005750:	6155                	addi	sp,sp,304
    80005752:	8082                	ret

0000000080005754 <sys_unlink>:
{
    80005754:	7151                	addi	sp,sp,-240
    80005756:	f586                	sd	ra,232(sp)
    80005758:	f1a2                	sd	s0,224(sp)
    8000575a:	eda6                	sd	s1,216(sp)
    8000575c:	e9ca                	sd	s2,208(sp)
    8000575e:	e5ce                	sd	s3,200(sp)
    80005760:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005762:	08000613          	li	a2,128
    80005766:	f3040593          	addi	a1,s0,-208
    8000576a:	4501                	li	a0,0
    8000576c:	ffffd097          	auipc	ra,0xffffd
    80005770:	5ca080e7          	jalr	1482(ra) # 80002d36 <argstr>
    80005774:	18054163          	bltz	a0,800058f6 <sys_unlink+0x1a2>
  begin_op();
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	bce080e7          	jalr	-1074(ra) # 80004346 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005780:	fb040593          	addi	a1,s0,-80
    80005784:	f3040513          	addi	a0,s0,-208
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	9c0080e7          	jalr	-1600(ra) # 80004148 <nameiparent>
    80005790:	84aa                	mv	s1,a0
    80005792:	c979                	beqz	a0,80005868 <sys_unlink+0x114>
  ilock(dp);
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	1f0080e7          	jalr	496(ra) # 80003984 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000579c:	00003597          	auipc	a1,0x3
    800057a0:	15c58593          	addi	a1,a1,348 # 800088f8 <syscalls+0x3d8>
    800057a4:	fb040513          	addi	a0,s0,-80
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	6a6080e7          	jalr	1702(ra) # 80003e4e <namecmp>
    800057b0:	14050a63          	beqz	a0,80005904 <sys_unlink+0x1b0>
    800057b4:	00003597          	auipc	a1,0x3
    800057b8:	14c58593          	addi	a1,a1,332 # 80008900 <syscalls+0x3e0>
    800057bc:	fb040513          	addi	a0,s0,-80
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	68e080e7          	jalr	1678(ra) # 80003e4e <namecmp>
    800057c8:	12050e63          	beqz	a0,80005904 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057cc:	f2c40613          	addi	a2,s0,-212
    800057d0:	fb040593          	addi	a1,s0,-80
    800057d4:	8526                	mv	a0,s1
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	692080e7          	jalr	1682(ra) # 80003e68 <dirlookup>
    800057de:	892a                	mv	s2,a0
    800057e0:	12050263          	beqz	a0,80005904 <sys_unlink+0x1b0>
  ilock(ip);
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	1a0080e7          	jalr	416(ra) # 80003984 <ilock>
  if(ip->nlink < 1)
    800057ec:	04a91783          	lh	a5,74(s2)
    800057f0:	08f05263          	blez	a5,80005874 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057f4:	04491703          	lh	a4,68(s2)
    800057f8:	4785                	li	a5,1
    800057fa:	08f70563          	beq	a4,a5,80005884 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057fe:	4641                	li	a2,16
    80005800:	4581                	li	a1,0
    80005802:	fc040513          	addi	a0,s0,-64
    80005806:	ffffb097          	auipc	ra,0xffffb
    8000580a:	4cc080e7          	jalr	1228(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000580e:	4741                	li	a4,16
    80005810:	f2c42683          	lw	a3,-212(s0)
    80005814:	fc040613          	addi	a2,s0,-64
    80005818:	4581                	li	a1,0
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	514080e7          	jalr	1300(ra) # 80003d30 <writei>
    80005824:	47c1                	li	a5,16
    80005826:	0af51563          	bne	a0,a5,800058d0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000582a:	04491703          	lh	a4,68(s2)
    8000582e:	4785                	li	a5,1
    80005830:	0af70863          	beq	a4,a5,800058e0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005834:	8526                	mv	a0,s1
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	3b0080e7          	jalr	944(ra) # 80003be6 <iunlockput>
  ip->nlink--;
    8000583e:	04a95783          	lhu	a5,74(s2)
    80005842:	37fd                	addiw	a5,a5,-1
    80005844:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	070080e7          	jalr	112(ra) # 800038ba <iupdate>
  iunlockput(ip);
    80005852:	854a                	mv	a0,s2
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	392080e7          	jalr	914(ra) # 80003be6 <iunlockput>
  end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	b6a080e7          	jalr	-1174(ra) # 800043c6 <end_op>
  return 0;
    80005864:	4501                	li	a0,0
    80005866:	a84d                	j	80005918 <sys_unlink+0x1c4>
    end_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	b5e080e7          	jalr	-1186(ra) # 800043c6 <end_op>
    return -1;
    80005870:	557d                	li	a0,-1
    80005872:	a05d                	j	80005918 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005874:	00003517          	auipc	a0,0x3
    80005878:	09450513          	addi	a0,a0,148 # 80008908 <syscalls+0x3e8>
    8000587c:	ffffb097          	auipc	ra,0xffffb
    80005880:	cc2080e7          	jalr	-830(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005884:	04c92703          	lw	a4,76(s2)
    80005888:	02000793          	li	a5,32
    8000588c:	f6e7f9e3          	bgeu	a5,a4,800057fe <sys_unlink+0xaa>
    80005890:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005894:	4741                	li	a4,16
    80005896:	86ce                	mv	a3,s3
    80005898:	f1840613          	addi	a2,s0,-232
    8000589c:	4581                	li	a1,0
    8000589e:	854a                	mv	a0,s2
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	398080e7          	jalr	920(ra) # 80003c38 <readi>
    800058a8:	47c1                	li	a5,16
    800058aa:	00f51b63          	bne	a0,a5,800058c0 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058ae:	f1845783          	lhu	a5,-232(s0)
    800058b2:	e7a1                	bnez	a5,800058fa <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058b4:	29c1                	addiw	s3,s3,16
    800058b6:	04c92783          	lw	a5,76(s2)
    800058ba:	fcf9ede3          	bltu	s3,a5,80005894 <sys_unlink+0x140>
    800058be:	b781                	j	800057fe <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058c0:	00003517          	auipc	a0,0x3
    800058c4:	06050513          	addi	a0,a0,96 # 80008920 <syscalls+0x400>
    800058c8:	ffffb097          	auipc	ra,0xffffb
    800058cc:	c76080e7          	jalr	-906(ra) # 8000053e <panic>
    panic("unlink: writei");
    800058d0:	00003517          	auipc	a0,0x3
    800058d4:	06850513          	addi	a0,a0,104 # 80008938 <syscalls+0x418>
    800058d8:	ffffb097          	auipc	ra,0xffffb
    800058dc:	c66080e7          	jalr	-922(ra) # 8000053e <panic>
    dp->nlink--;
    800058e0:	04a4d783          	lhu	a5,74(s1)
    800058e4:	37fd                	addiw	a5,a5,-1
    800058e6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058ea:	8526                	mv	a0,s1
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	fce080e7          	jalr	-50(ra) # 800038ba <iupdate>
    800058f4:	b781                	j	80005834 <sys_unlink+0xe0>
    return -1;
    800058f6:	557d                	li	a0,-1
    800058f8:	a005                	j	80005918 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058fa:	854a                	mv	a0,s2
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	2ea080e7          	jalr	746(ra) # 80003be6 <iunlockput>
  iunlockput(dp);
    80005904:	8526                	mv	a0,s1
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	2e0080e7          	jalr	736(ra) # 80003be6 <iunlockput>
  end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	ab8080e7          	jalr	-1352(ra) # 800043c6 <end_op>
  return -1;
    80005916:	557d                	li	a0,-1
}
    80005918:	70ae                	ld	ra,232(sp)
    8000591a:	740e                	ld	s0,224(sp)
    8000591c:	64ee                	ld	s1,216(sp)
    8000591e:	694e                	ld	s2,208(sp)
    80005920:	69ae                	ld	s3,200(sp)
    80005922:	616d                	addi	sp,sp,240
    80005924:	8082                	ret

0000000080005926 <sys_open>:

uint64
sys_open(void)
{
    80005926:	7131                	addi	sp,sp,-192
    80005928:	fd06                	sd	ra,184(sp)
    8000592a:	f922                	sd	s0,176(sp)
    8000592c:	f526                	sd	s1,168(sp)
    8000592e:	f14a                	sd	s2,160(sp)
    80005930:	ed4e                	sd	s3,152(sp)
    80005932:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005934:	f4c40593          	addi	a1,s0,-180
    80005938:	4505                	li	a0,1
    8000593a:	ffffd097          	auipc	ra,0xffffd
    8000593e:	3bc080e7          	jalr	956(ra) # 80002cf6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005942:	08000613          	li	a2,128
    80005946:	f5040593          	addi	a1,s0,-176
    8000594a:	4501                	li	a0,0
    8000594c:	ffffd097          	auipc	ra,0xffffd
    80005950:	3ea080e7          	jalr	1002(ra) # 80002d36 <argstr>
    80005954:	87aa                	mv	a5,a0
    return -1;
    80005956:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005958:	0a07c963          	bltz	a5,80005a0a <sys_open+0xe4>

  begin_op();
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	9ea080e7          	jalr	-1558(ra) # 80004346 <begin_op>

  if(omode & O_CREATE){
    80005964:	f4c42783          	lw	a5,-180(s0)
    80005968:	2007f793          	andi	a5,a5,512
    8000596c:	cfc5                	beqz	a5,80005a24 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000596e:	4681                	li	a3,0
    80005970:	4601                	li	a2,0
    80005972:	4589                	li	a1,2
    80005974:	f5040513          	addi	a0,s0,-176
    80005978:	00000097          	auipc	ra,0x0
    8000597c:	976080e7          	jalr	-1674(ra) # 800052ee <create>
    80005980:	84aa                	mv	s1,a0
    if(ip == 0){
    80005982:	c959                	beqz	a0,80005a18 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005984:	04449703          	lh	a4,68(s1)
    80005988:	478d                	li	a5,3
    8000598a:	00f71763          	bne	a4,a5,80005998 <sys_open+0x72>
    8000598e:	0464d703          	lhu	a4,70(s1)
    80005992:	47a5                	li	a5,9
    80005994:	0ce7ed63          	bltu	a5,a4,80005a6e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	dbe080e7          	jalr	-578(ra) # 80004756 <filealloc>
    800059a0:	89aa                	mv	s3,a0
    800059a2:	10050363          	beqz	a0,80005aa8 <sys_open+0x182>
    800059a6:	00000097          	auipc	ra,0x0
    800059aa:	906080e7          	jalr	-1786(ra) # 800052ac <fdalloc>
    800059ae:	892a                	mv	s2,a0
    800059b0:	0e054763          	bltz	a0,80005a9e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059b4:	04449703          	lh	a4,68(s1)
    800059b8:	478d                	li	a5,3
    800059ba:	0cf70563          	beq	a4,a5,80005a84 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059be:	4789                	li	a5,2
    800059c0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059c4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059c8:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059cc:	f4c42783          	lw	a5,-180(s0)
    800059d0:	0017c713          	xori	a4,a5,1
    800059d4:	8b05                	andi	a4,a4,1
    800059d6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059da:	0037f713          	andi	a4,a5,3
    800059de:	00e03733          	snez	a4,a4
    800059e2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059e6:	4007f793          	andi	a5,a5,1024
    800059ea:	c791                	beqz	a5,800059f6 <sys_open+0xd0>
    800059ec:	04449703          	lh	a4,68(s1)
    800059f0:	4789                	li	a5,2
    800059f2:	0af70063          	beq	a4,a5,80005a92 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059f6:	8526                	mv	a0,s1
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	04e080e7          	jalr	78(ra) # 80003a46 <iunlock>
  end_op();
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	9c6080e7          	jalr	-1594(ra) # 800043c6 <end_op>

  return fd;
    80005a08:	854a                	mv	a0,s2
}
    80005a0a:	70ea                	ld	ra,184(sp)
    80005a0c:	744a                	ld	s0,176(sp)
    80005a0e:	74aa                	ld	s1,168(sp)
    80005a10:	790a                	ld	s2,160(sp)
    80005a12:	69ea                	ld	s3,152(sp)
    80005a14:	6129                	addi	sp,sp,192
    80005a16:	8082                	ret
      end_op();
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	9ae080e7          	jalr	-1618(ra) # 800043c6 <end_op>
      return -1;
    80005a20:	557d                	li	a0,-1
    80005a22:	b7e5                	j	80005a0a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a24:	f5040513          	addi	a0,s0,-176
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	702080e7          	jalr	1794(ra) # 8000412a <namei>
    80005a30:	84aa                	mv	s1,a0
    80005a32:	c905                	beqz	a0,80005a62 <sys_open+0x13c>
    ilock(ip);
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	f50080e7          	jalr	-176(ra) # 80003984 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a3c:	04449703          	lh	a4,68(s1)
    80005a40:	4785                	li	a5,1
    80005a42:	f4f711e3          	bne	a4,a5,80005984 <sys_open+0x5e>
    80005a46:	f4c42783          	lw	a5,-180(s0)
    80005a4a:	d7b9                	beqz	a5,80005998 <sys_open+0x72>
      iunlockput(ip);
    80005a4c:	8526                	mv	a0,s1
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	198080e7          	jalr	408(ra) # 80003be6 <iunlockput>
      end_op();
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	970080e7          	jalr	-1680(ra) # 800043c6 <end_op>
      return -1;
    80005a5e:	557d                	li	a0,-1
    80005a60:	b76d                	j	80005a0a <sys_open+0xe4>
      end_op();
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	964080e7          	jalr	-1692(ra) # 800043c6 <end_op>
      return -1;
    80005a6a:	557d                	li	a0,-1
    80005a6c:	bf79                	j	80005a0a <sys_open+0xe4>
    iunlockput(ip);
    80005a6e:	8526                	mv	a0,s1
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	176080e7          	jalr	374(ra) # 80003be6 <iunlockput>
    end_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	94e080e7          	jalr	-1714(ra) # 800043c6 <end_op>
    return -1;
    80005a80:	557d                	li	a0,-1
    80005a82:	b761                	j	80005a0a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a84:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a88:	04649783          	lh	a5,70(s1)
    80005a8c:	02f99223          	sh	a5,36(s3)
    80005a90:	bf25                	j	800059c8 <sys_open+0xa2>
    itrunc(ip);
    80005a92:	8526                	mv	a0,s1
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	ffe080e7          	jalr	-2(ra) # 80003a92 <itrunc>
    80005a9c:	bfa9                	j	800059f6 <sys_open+0xd0>
      fileclose(f);
    80005a9e:	854e                	mv	a0,s3
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	d72080e7          	jalr	-654(ra) # 80004812 <fileclose>
    iunlockput(ip);
    80005aa8:	8526                	mv	a0,s1
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	13c080e7          	jalr	316(ra) # 80003be6 <iunlockput>
    end_op();
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	914080e7          	jalr	-1772(ra) # 800043c6 <end_op>
    return -1;
    80005aba:	557d                	li	a0,-1
    80005abc:	b7b9                	j	80005a0a <sys_open+0xe4>

0000000080005abe <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005abe:	7175                	addi	sp,sp,-144
    80005ac0:	e506                	sd	ra,136(sp)
    80005ac2:	e122                	sd	s0,128(sp)
    80005ac4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	880080e7          	jalr	-1920(ra) # 80004346 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ace:	08000613          	li	a2,128
    80005ad2:	f7040593          	addi	a1,s0,-144
    80005ad6:	4501                	li	a0,0
    80005ad8:	ffffd097          	auipc	ra,0xffffd
    80005adc:	25e080e7          	jalr	606(ra) # 80002d36 <argstr>
    80005ae0:	02054963          	bltz	a0,80005b12 <sys_mkdir+0x54>
    80005ae4:	4681                	li	a3,0
    80005ae6:	4601                	li	a2,0
    80005ae8:	4585                	li	a1,1
    80005aea:	f7040513          	addi	a0,s0,-144
    80005aee:	00000097          	auipc	ra,0x0
    80005af2:	800080e7          	jalr	-2048(ra) # 800052ee <create>
    80005af6:	cd11                	beqz	a0,80005b12 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	0ee080e7          	jalr	238(ra) # 80003be6 <iunlockput>
  end_op();
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	8c6080e7          	jalr	-1850(ra) # 800043c6 <end_op>
  return 0;
    80005b08:	4501                	li	a0,0
}
    80005b0a:	60aa                	ld	ra,136(sp)
    80005b0c:	640a                	ld	s0,128(sp)
    80005b0e:	6149                	addi	sp,sp,144
    80005b10:	8082                	ret
    end_op();
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	8b4080e7          	jalr	-1868(ra) # 800043c6 <end_op>
    return -1;
    80005b1a:	557d                	li	a0,-1
    80005b1c:	b7fd                	j	80005b0a <sys_mkdir+0x4c>

0000000080005b1e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b1e:	7135                	addi	sp,sp,-160
    80005b20:	ed06                	sd	ra,152(sp)
    80005b22:	e922                	sd	s0,144(sp)
    80005b24:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	820080e7          	jalr	-2016(ra) # 80004346 <begin_op>
  argint(1, &major);
    80005b2e:	f6c40593          	addi	a1,s0,-148
    80005b32:	4505                	li	a0,1
    80005b34:	ffffd097          	auipc	ra,0xffffd
    80005b38:	1c2080e7          	jalr	450(ra) # 80002cf6 <argint>
  argint(2, &minor);
    80005b3c:	f6840593          	addi	a1,s0,-152
    80005b40:	4509                	li	a0,2
    80005b42:	ffffd097          	auipc	ra,0xffffd
    80005b46:	1b4080e7          	jalr	436(ra) # 80002cf6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b4a:	08000613          	li	a2,128
    80005b4e:	f7040593          	addi	a1,s0,-144
    80005b52:	4501                	li	a0,0
    80005b54:	ffffd097          	auipc	ra,0xffffd
    80005b58:	1e2080e7          	jalr	482(ra) # 80002d36 <argstr>
    80005b5c:	02054b63          	bltz	a0,80005b92 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b60:	f6841683          	lh	a3,-152(s0)
    80005b64:	f6c41603          	lh	a2,-148(s0)
    80005b68:	458d                	li	a1,3
    80005b6a:	f7040513          	addi	a0,s0,-144
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	780080e7          	jalr	1920(ra) # 800052ee <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b76:	cd11                	beqz	a0,80005b92 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	06e080e7          	jalr	110(ra) # 80003be6 <iunlockput>
  end_op();
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	846080e7          	jalr	-1978(ra) # 800043c6 <end_op>
  return 0;
    80005b88:	4501                	li	a0,0
}
    80005b8a:	60ea                	ld	ra,152(sp)
    80005b8c:	644a                	ld	s0,144(sp)
    80005b8e:	610d                	addi	sp,sp,160
    80005b90:	8082                	ret
    end_op();
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	834080e7          	jalr	-1996(ra) # 800043c6 <end_op>
    return -1;
    80005b9a:	557d                	li	a0,-1
    80005b9c:	b7fd                	j	80005b8a <sys_mknod+0x6c>

0000000080005b9e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b9e:	7135                	addi	sp,sp,-160
    80005ba0:	ed06                	sd	ra,152(sp)
    80005ba2:	e922                	sd	s0,144(sp)
    80005ba4:	e526                	sd	s1,136(sp)
    80005ba6:	e14a                	sd	s2,128(sp)
    80005ba8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005baa:	ffffc097          	auipc	ra,0xffffc
    80005bae:	e38080e7          	jalr	-456(ra) # 800019e2 <myproc>
    80005bb2:	892a                	mv	s2,a0
  
  begin_op();
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	792080e7          	jalr	1938(ra) # 80004346 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bbc:	08000613          	li	a2,128
    80005bc0:	f6040593          	addi	a1,s0,-160
    80005bc4:	4501                	li	a0,0
    80005bc6:	ffffd097          	auipc	ra,0xffffd
    80005bca:	170080e7          	jalr	368(ra) # 80002d36 <argstr>
    80005bce:	04054b63          	bltz	a0,80005c24 <sys_chdir+0x86>
    80005bd2:	f6040513          	addi	a0,s0,-160
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	554080e7          	jalr	1364(ra) # 8000412a <namei>
    80005bde:	84aa                	mv	s1,a0
    80005be0:	c131                	beqz	a0,80005c24 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	da2080e7          	jalr	-606(ra) # 80003984 <ilock>
  if(ip->type != T_DIR){
    80005bea:	04449703          	lh	a4,68(s1)
    80005bee:	4785                	li	a5,1
    80005bf0:	04f71063          	bne	a4,a5,80005c30 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bf4:	8526                	mv	a0,s1
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	e50080e7          	jalr	-432(ra) # 80003a46 <iunlock>
  iput(p->cwd);
    80005bfe:	15093503          	ld	a0,336(s2)
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	f3c080e7          	jalr	-196(ra) # 80003b3e <iput>
  end_op();
    80005c0a:	ffffe097          	auipc	ra,0xffffe
    80005c0e:	7bc080e7          	jalr	1980(ra) # 800043c6 <end_op>
  p->cwd = ip;
    80005c12:	14993823          	sd	s1,336(s2)
  return 0;
    80005c16:	4501                	li	a0,0
}
    80005c18:	60ea                	ld	ra,152(sp)
    80005c1a:	644a                	ld	s0,144(sp)
    80005c1c:	64aa                	ld	s1,136(sp)
    80005c1e:	690a                	ld	s2,128(sp)
    80005c20:	610d                	addi	sp,sp,160
    80005c22:	8082                	ret
    end_op();
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	7a2080e7          	jalr	1954(ra) # 800043c6 <end_op>
    return -1;
    80005c2c:	557d                	li	a0,-1
    80005c2e:	b7ed                	j	80005c18 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c30:	8526                	mv	a0,s1
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	fb4080e7          	jalr	-76(ra) # 80003be6 <iunlockput>
    end_op();
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	78c080e7          	jalr	1932(ra) # 800043c6 <end_op>
    return -1;
    80005c42:	557d                	li	a0,-1
    80005c44:	bfd1                	j	80005c18 <sys_chdir+0x7a>

0000000080005c46 <sys_exec>:

uint64
sys_exec(void)
{
    80005c46:	7145                	addi	sp,sp,-464
    80005c48:	e786                	sd	ra,456(sp)
    80005c4a:	e3a2                	sd	s0,448(sp)
    80005c4c:	ff26                	sd	s1,440(sp)
    80005c4e:	fb4a                	sd	s2,432(sp)
    80005c50:	f74e                	sd	s3,424(sp)
    80005c52:	f352                	sd	s4,416(sp)
    80005c54:	ef56                	sd	s5,408(sp)
    80005c56:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c58:	e3840593          	addi	a1,s0,-456
    80005c5c:	4505                	li	a0,1
    80005c5e:	ffffd097          	auipc	ra,0xffffd
    80005c62:	0b8080e7          	jalr	184(ra) # 80002d16 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c66:	08000613          	li	a2,128
    80005c6a:	f4040593          	addi	a1,s0,-192
    80005c6e:	4501                	li	a0,0
    80005c70:	ffffd097          	auipc	ra,0xffffd
    80005c74:	0c6080e7          	jalr	198(ra) # 80002d36 <argstr>
    80005c78:	87aa                	mv	a5,a0
    return -1;
    80005c7a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c7c:	0c07c263          	bltz	a5,80005d40 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c80:	10000613          	li	a2,256
    80005c84:	4581                	li	a1,0
    80005c86:	e4040513          	addi	a0,s0,-448
    80005c8a:	ffffb097          	auipc	ra,0xffffb
    80005c8e:	048080e7          	jalr	72(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c92:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c96:	89a6                	mv	s3,s1
    80005c98:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c9a:	02000a13          	li	s4,32
    80005c9e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ca2:	00391793          	slli	a5,s2,0x3
    80005ca6:	e3040593          	addi	a1,s0,-464
    80005caa:	e3843503          	ld	a0,-456(s0)
    80005cae:	953e                	add	a0,a0,a5
    80005cb0:	ffffd097          	auipc	ra,0xffffd
    80005cb4:	fa8080e7          	jalr	-88(ra) # 80002c58 <fetchaddr>
    80005cb8:	02054a63          	bltz	a0,80005cec <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005cbc:	e3043783          	ld	a5,-464(s0)
    80005cc0:	c3b9                	beqz	a5,80005d06 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cc2:	ffffb097          	auipc	ra,0xffffb
    80005cc6:	e24080e7          	jalr	-476(ra) # 80000ae6 <kalloc>
    80005cca:	85aa                	mv	a1,a0
    80005ccc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cd0:	cd11                	beqz	a0,80005cec <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cd2:	6605                	lui	a2,0x1
    80005cd4:	e3043503          	ld	a0,-464(s0)
    80005cd8:	ffffd097          	auipc	ra,0xffffd
    80005cdc:	fd2080e7          	jalr	-46(ra) # 80002caa <fetchstr>
    80005ce0:	00054663          	bltz	a0,80005cec <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005ce4:	0905                	addi	s2,s2,1
    80005ce6:	09a1                	addi	s3,s3,8
    80005ce8:	fb491be3          	bne	s2,s4,80005c9e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cec:	10048913          	addi	s2,s1,256
    80005cf0:	6088                	ld	a0,0(s1)
    80005cf2:	c531                	beqz	a0,80005d3e <sys_exec+0xf8>
    kfree(argv[i]);
    80005cf4:	ffffb097          	auipc	ra,0xffffb
    80005cf8:	cf6080e7          	jalr	-778(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cfc:	04a1                	addi	s1,s1,8
    80005cfe:	ff2499e3          	bne	s1,s2,80005cf0 <sys_exec+0xaa>
  return -1;
    80005d02:	557d                	li	a0,-1
    80005d04:	a835                	j	80005d40 <sys_exec+0xfa>
      argv[i] = 0;
    80005d06:	0a8e                	slli	s5,s5,0x3
    80005d08:	fc040793          	addi	a5,s0,-64
    80005d0c:	9abe                	add	s5,s5,a5
    80005d0e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d12:	e4040593          	addi	a1,s0,-448
    80005d16:	f4040513          	addi	a0,s0,-192
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	172080e7          	jalr	370(ra) # 80004e8c <exec>
    80005d22:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d24:	10048993          	addi	s3,s1,256
    80005d28:	6088                	ld	a0,0(s1)
    80005d2a:	c901                	beqz	a0,80005d3a <sys_exec+0xf4>
    kfree(argv[i]);
    80005d2c:	ffffb097          	auipc	ra,0xffffb
    80005d30:	cbe080e7          	jalr	-834(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d34:	04a1                	addi	s1,s1,8
    80005d36:	ff3499e3          	bne	s1,s3,80005d28 <sys_exec+0xe2>
  return ret;
    80005d3a:	854a                	mv	a0,s2
    80005d3c:	a011                	j	80005d40 <sys_exec+0xfa>
  return -1;
    80005d3e:	557d                	li	a0,-1
}
    80005d40:	60be                	ld	ra,456(sp)
    80005d42:	641e                	ld	s0,448(sp)
    80005d44:	74fa                	ld	s1,440(sp)
    80005d46:	795a                	ld	s2,432(sp)
    80005d48:	79ba                	ld	s3,424(sp)
    80005d4a:	7a1a                	ld	s4,416(sp)
    80005d4c:	6afa                	ld	s5,408(sp)
    80005d4e:	6179                	addi	sp,sp,464
    80005d50:	8082                	ret

0000000080005d52 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d52:	7139                	addi	sp,sp,-64
    80005d54:	fc06                	sd	ra,56(sp)
    80005d56:	f822                	sd	s0,48(sp)
    80005d58:	f426                	sd	s1,40(sp)
    80005d5a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d5c:	ffffc097          	auipc	ra,0xffffc
    80005d60:	c86080e7          	jalr	-890(ra) # 800019e2 <myproc>
    80005d64:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d66:	fd840593          	addi	a1,s0,-40
    80005d6a:	4501                	li	a0,0
    80005d6c:	ffffd097          	auipc	ra,0xffffd
    80005d70:	faa080e7          	jalr	-86(ra) # 80002d16 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d74:	fc840593          	addi	a1,s0,-56
    80005d78:	fd040513          	addi	a0,s0,-48
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	dc6080e7          	jalr	-570(ra) # 80004b42 <pipealloc>
    return -1;
    80005d84:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d86:	0c054463          	bltz	a0,80005e4e <sys_pipe+0xfc>
  fd0 = -1;
    80005d8a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d8e:	fd043503          	ld	a0,-48(s0)
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	51a080e7          	jalr	1306(ra) # 800052ac <fdalloc>
    80005d9a:	fca42223          	sw	a0,-60(s0)
    80005d9e:	08054b63          	bltz	a0,80005e34 <sys_pipe+0xe2>
    80005da2:	fc843503          	ld	a0,-56(s0)
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	506080e7          	jalr	1286(ra) # 800052ac <fdalloc>
    80005dae:	fca42023          	sw	a0,-64(s0)
    80005db2:	06054863          	bltz	a0,80005e22 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005db6:	4691                	li	a3,4
    80005db8:	fc440613          	addi	a2,s0,-60
    80005dbc:	fd843583          	ld	a1,-40(s0)
    80005dc0:	68a8                	ld	a0,80(s1)
    80005dc2:	ffffc097          	auipc	ra,0xffffc
    80005dc6:	8dc080e7          	jalr	-1828(ra) # 8000169e <copyout>
    80005dca:	02054063          	bltz	a0,80005dea <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005dce:	4691                	li	a3,4
    80005dd0:	fc040613          	addi	a2,s0,-64
    80005dd4:	fd843583          	ld	a1,-40(s0)
    80005dd8:	0591                	addi	a1,a1,4
    80005dda:	68a8                	ld	a0,80(s1)
    80005ddc:	ffffc097          	auipc	ra,0xffffc
    80005de0:	8c2080e7          	jalr	-1854(ra) # 8000169e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005de4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005de6:	06055463          	bgez	a0,80005e4e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005dea:	fc442783          	lw	a5,-60(s0)
    80005dee:	07e9                	addi	a5,a5,26
    80005df0:	078e                	slli	a5,a5,0x3
    80005df2:	97a6                	add	a5,a5,s1
    80005df4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005df8:	fc042503          	lw	a0,-64(s0)
    80005dfc:	0569                	addi	a0,a0,26
    80005dfe:	050e                	slli	a0,a0,0x3
    80005e00:	94aa                	add	s1,s1,a0
    80005e02:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e06:	fd043503          	ld	a0,-48(s0)
    80005e0a:	fffff097          	auipc	ra,0xfffff
    80005e0e:	a08080e7          	jalr	-1528(ra) # 80004812 <fileclose>
    fileclose(wf);
    80005e12:	fc843503          	ld	a0,-56(s0)
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	9fc080e7          	jalr	-1540(ra) # 80004812 <fileclose>
    return -1;
    80005e1e:	57fd                	li	a5,-1
    80005e20:	a03d                	j	80005e4e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e22:	fc442783          	lw	a5,-60(s0)
    80005e26:	0007c763          	bltz	a5,80005e34 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e2a:	07e9                	addi	a5,a5,26
    80005e2c:	078e                	slli	a5,a5,0x3
    80005e2e:	94be                	add	s1,s1,a5
    80005e30:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e34:	fd043503          	ld	a0,-48(s0)
    80005e38:	fffff097          	auipc	ra,0xfffff
    80005e3c:	9da080e7          	jalr	-1574(ra) # 80004812 <fileclose>
    fileclose(wf);
    80005e40:	fc843503          	ld	a0,-56(s0)
    80005e44:	fffff097          	auipc	ra,0xfffff
    80005e48:	9ce080e7          	jalr	-1586(ra) # 80004812 <fileclose>
    return -1;
    80005e4c:	57fd                	li	a5,-1
}
    80005e4e:	853e                	mv	a0,a5
    80005e50:	70e2                	ld	ra,56(sp)
    80005e52:	7442                	ld	s0,48(sp)
    80005e54:	74a2                	ld	s1,40(sp)
    80005e56:	6121                	addi	sp,sp,64
    80005e58:	8082                	ret
    80005e5a:	0000                	unimp
    80005e5c:	0000                	unimp
	...

0000000080005e60 <kernelvec>:
    80005e60:	7111                	addi	sp,sp,-256
    80005e62:	e006                	sd	ra,0(sp)
    80005e64:	e40a                	sd	sp,8(sp)
    80005e66:	e80e                	sd	gp,16(sp)
    80005e68:	ec12                	sd	tp,24(sp)
    80005e6a:	f016                	sd	t0,32(sp)
    80005e6c:	f41a                	sd	t1,40(sp)
    80005e6e:	f81e                	sd	t2,48(sp)
    80005e70:	fc22                	sd	s0,56(sp)
    80005e72:	e0a6                	sd	s1,64(sp)
    80005e74:	e4aa                	sd	a0,72(sp)
    80005e76:	e8ae                	sd	a1,80(sp)
    80005e78:	ecb2                	sd	a2,88(sp)
    80005e7a:	f0b6                	sd	a3,96(sp)
    80005e7c:	f4ba                	sd	a4,104(sp)
    80005e7e:	f8be                	sd	a5,112(sp)
    80005e80:	fcc2                	sd	a6,120(sp)
    80005e82:	e146                	sd	a7,128(sp)
    80005e84:	e54a                	sd	s2,136(sp)
    80005e86:	e94e                	sd	s3,144(sp)
    80005e88:	ed52                	sd	s4,152(sp)
    80005e8a:	f156                	sd	s5,160(sp)
    80005e8c:	f55a                	sd	s6,168(sp)
    80005e8e:	f95e                	sd	s7,176(sp)
    80005e90:	fd62                	sd	s8,184(sp)
    80005e92:	e1e6                	sd	s9,192(sp)
    80005e94:	e5ea                	sd	s10,200(sp)
    80005e96:	e9ee                	sd	s11,208(sp)
    80005e98:	edf2                	sd	t3,216(sp)
    80005e9a:	f1f6                	sd	t4,224(sp)
    80005e9c:	f5fa                	sd	t5,232(sp)
    80005e9e:	f9fe                	sd	t6,240(sp)
    80005ea0:	c85fc0ef          	jal	ra,80002b24 <kerneltrap>
    80005ea4:	6082                	ld	ra,0(sp)
    80005ea6:	6122                	ld	sp,8(sp)
    80005ea8:	61c2                	ld	gp,16(sp)
    80005eaa:	7282                	ld	t0,32(sp)
    80005eac:	7322                	ld	t1,40(sp)
    80005eae:	73c2                	ld	t2,48(sp)
    80005eb0:	7462                	ld	s0,56(sp)
    80005eb2:	6486                	ld	s1,64(sp)
    80005eb4:	6526                	ld	a0,72(sp)
    80005eb6:	65c6                	ld	a1,80(sp)
    80005eb8:	6666                	ld	a2,88(sp)
    80005eba:	7686                	ld	a3,96(sp)
    80005ebc:	7726                	ld	a4,104(sp)
    80005ebe:	77c6                	ld	a5,112(sp)
    80005ec0:	7866                	ld	a6,120(sp)
    80005ec2:	688a                	ld	a7,128(sp)
    80005ec4:	692a                	ld	s2,136(sp)
    80005ec6:	69ca                	ld	s3,144(sp)
    80005ec8:	6a6a                	ld	s4,152(sp)
    80005eca:	7a8a                	ld	s5,160(sp)
    80005ecc:	7b2a                	ld	s6,168(sp)
    80005ece:	7bca                	ld	s7,176(sp)
    80005ed0:	7c6a                	ld	s8,184(sp)
    80005ed2:	6c8e                	ld	s9,192(sp)
    80005ed4:	6d2e                	ld	s10,200(sp)
    80005ed6:	6dce                	ld	s11,208(sp)
    80005ed8:	6e6e                	ld	t3,216(sp)
    80005eda:	7e8e                	ld	t4,224(sp)
    80005edc:	7f2e                	ld	t5,232(sp)
    80005ede:	7fce                	ld	t6,240(sp)
    80005ee0:	6111                	addi	sp,sp,256
    80005ee2:	10200073          	sret
    80005ee6:	00000013          	nop
    80005eea:	00000013          	nop
    80005eee:	0001                	nop

0000000080005ef0 <timervec>:
    80005ef0:	34051573          	csrrw	a0,mscratch,a0
    80005ef4:	e10c                	sd	a1,0(a0)
    80005ef6:	e510                	sd	a2,8(a0)
    80005ef8:	e914                	sd	a3,16(a0)
    80005efa:	6d0c                	ld	a1,24(a0)
    80005efc:	7110                	ld	a2,32(a0)
    80005efe:	6194                	ld	a3,0(a1)
    80005f00:	96b2                	add	a3,a3,a2
    80005f02:	e194                	sd	a3,0(a1)
    80005f04:	4589                	li	a1,2
    80005f06:	14459073          	csrw	sip,a1
    80005f0a:	6914                	ld	a3,16(a0)
    80005f0c:	6510                	ld	a2,8(a0)
    80005f0e:	610c                	ld	a1,0(a0)
    80005f10:	34051573          	csrrw	a0,mscratch,a0
    80005f14:	30200073          	mret
	...

0000000080005f1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f1a:	1141                	addi	sp,sp,-16
    80005f1c:	e422                	sd	s0,8(sp)
    80005f1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f20:	0c0007b7          	lui	a5,0xc000
    80005f24:	4705                	li	a4,1
    80005f26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f28:	c3d8                	sw	a4,4(a5)
}
    80005f2a:	6422                	ld	s0,8(sp)
    80005f2c:	0141                	addi	sp,sp,16
    80005f2e:	8082                	ret

0000000080005f30 <plicinithart>:

void
plicinithart(void)
{
    80005f30:	1141                	addi	sp,sp,-16
    80005f32:	e406                	sd	ra,8(sp)
    80005f34:	e022                	sd	s0,0(sp)
    80005f36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	a7e080e7          	jalr	-1410(ra) # 800019b6 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f40:	0085171b          	slliw	a4,a0,0x8
    80005f44:	0c0027b7          	lui	a5,0xc002
    80005f48:	97ba                	add	a5,a5,a4
    80005f4a:	40200713          	li	a4,1026
    80005f4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f52:	00d5151b          	slliw	a0,a0,0xd
    80005f56:	0c2017b7          	lui	a5,0xc201
    80005f5a:	953e                	add	a0,a0,a5
    80005f5c:	00052023          	sw	zero,0(a0)
}
    80005f60:	60a2                	ld	ra,8(sp)
    80005f62:	6402                	ld	s0,0(sp)
    80005f64:	0141                	addi	sp,sp,16
    80005f66:	8082                	ret

0000000080005f68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f68:	1141                	addi	sp,sp,-16
    80005f6a:	e406                	sd	ra,8(sp)
    80005f6c:	e022                	sd	s0,0(sp)
    80005f6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f70:	ffffc097          	auipc	ra,0xffffc
    80005f74:	a46080e7          	jalr	-1466(ra) # 800019b6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f78:	00d5179b          	slliw	a5,a0,0xd
    80005f7c:	0c201537          	lui	a0,0xc201
    80005f80:	953e                	add	a0,a0,a5
  return irq;
}
    80005f82:	4148                	lw	a0,4(a0)
    80005f84:	60a2                	ld	ra,8(sp)
    80005f86:	6402                	ld	s0,0(sp)
    80005f88:	0141                	addi	sp,sp,16
    80005f8a:	8082                	ret

0000000080005f8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f8c:	1101                	addi	sp,sp,-32
    80005f8e:	ec06                	sd	ra,24(sp)
    80005f90:	e822                	sd	s0,16(sp)
    80005f92:	e426                	sd	s1,8(sp)
    80005f94:	1000                	addi	s0,sp,32
    80005f96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f98:	ffffc097          	auipc	ra,0xffffc
    80005f9c:	a1e080e7          	jalr	-1506(ra) # 800019b6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fa0:	00d5151b          	slliw	a0,a0,0xd
    80005fa4:	0c2017b7          	lui	a5,0xc201
    80005fa8:	97aa                	add	a5,a5,a0
    80005faa:	c3c4                	sw	s1,4(a5)
}
    80005fac:	60e2                	ld	ra,24(sp)
    80005fae:	6442                	ld	s0,16(sp)
    80005fb0:	64a2                	ld	s1,8(sp)
    80005fb2:	6105                	addi	sp,sp,32
    80005fb4:	8082                	ret

0000000080005fb6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fb6:	1141                	addi	sp,sp,-16
    80005fb8:	e406                	sd	ra,8(sp)
    80005fba:	e022                	sd	s0,0(sp)
    80005fbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fbe:	479d                	li	a5,7
    80005fc0:	04a7cc63          	blt	a5,a0,80006018 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005fc4:	0001d797          	auipc	a5,0x1d
    80005fc8:	9dc78793          	addi	a5,a5,-1572 # 800229a0 <disk>
    80005fcc:	97aa                	add	a5,a5,a0
    80005fce:	0187c783          	lbu	a5,24(a5)
    80005fd2:	ebb9                	bnez	a5,80006028 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005fd4:	00451613          	slli	a2,a0,0x4
    80005fd8:	0001d797          	auipc	a5,0x1d
    80005fdc:	9c878793          	addi	a5,a5,-1592 # 800229a0 <disk>
    80005fe0:	6394                	ld	a3,0(a5)
    80005fe2:	96b2                	add	a3,a3,a2
    80005fe4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fe8:	6398                	ld	a4,0(a5)
    80005fea:	9732                	add	a4,a4,a2
    80005fec:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005ff0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005ff4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005ff8:	953e                	add	a0,a0,a5
    80005ffa:	4785                	li	a5,1
    80005ffc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006000:	0001d517          	auipc	a0,0x1d
    80006004:	9b850513          	addi	a0,a0,-1608 # 800229b8 <disk+0x18>
    80006008:	ffffc097          	auipc	ra,0xffffc
    8000600c:	17e080e7          	jalr	382(ra) # 80002186 <wakeup>
}
    80006010:	60a2                	ld	ra,8(sp)
    80006012:	6402                	ld	s0,0(sp)
    80006014:	0141                	addi	sp,sp,16
    80006016:	8082                	ret
    panic("free_desc 1");
    80006018:	00003517          	auipc	a0,0x3
    8000601c:	93050513          	addi	a0,a0,-1744 # 80008948 <syscalls+0x428>
    80006020:	ffffa097          	auipc	ra,0xffffa
    80006024:	51e080e7          	jalr	1310(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006028:	00003517          	auipc	a0,0x3
    8000602c:	93050513          	addi	a0,a0,-1744 # 80008958 <syscalls+0x438>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	50e080e7          	jalr	1294(ra) # 8000053e <panic>

0000000080006038 <virtio_disk_init>:
{
    80006038:	1101                	addi	sp,sp,-32
    8000603a:	ec06                	sd	ra,24(sp)
    8000603c:	e822                	sd	s0,16(sp)
    8000603e:	e426                	sd	s1,8(sp)
    80006040:	e04a                	sd	s2,0(sp)
    80006042:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006044:	00003597          	auipc	a1,0x3
    80006048:	92458593          	addi	a1,a1,-1756 # 80008968 <syscalls+0x448>
    8000604c:	0001d517          	auipc	a0,0x1d
    80006050:	a7c50513          	addi	a0,a0,-1412 # 80022ac8 <disk+0x128>
    80006054:	ffffb097          	auipc	ra,0xffffb
    80006058:	af2080e7          	jalr	-1294(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000605c:	100017b7          	lui	a5,0x10001
    80006060:	4398                	lw	a4,0(a5)
    80006062:	2701                	sext.w	a4,a4
    80006064:	747277b7          	lui	a5,0x74727
    80006068:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000606c:	14f71c63          	bne	a4,a5,800061c4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006070:	100017b7          	lui	a5,0x10001
    80006074:	43dc                	lw	a5,4(a5)
    80006076:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006078:	4709                	li	a4,2
    8000607a:	14e79563          	bne	a5,a4,800061c4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000607e:	100017b7          	lui	a5,0x10001
    80006082:	479c                	lw	a5,8(a5)
    80006084:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006086:	12e79f63          	bne	a5,a4,800061c4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000608a:	100017b7          	lui	a5,0x10001
    8000608e:	47d8                	lw	a4,12(a5)
    80006090:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006092:	554d47b7          	lui	a5,0x554d4
    80006096:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000609a:	12f71563          	bne	a4,a5,800061c4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000609e:	100017b7          	lui	a5,0x10001
    800060a2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a6:	4705                	li	a4,1
    800060a8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060aa:	470d                	li	a4,3
    800060ac:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060ae:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060b0:	c7ffe737          	lui	a4,0xc7ffe
    800060b4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd7987>
    800060b8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060ba:	2701                	sext.w	a4,a4
    800060bc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060be:	472d                	li	a4,11
    800060c0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800060c2:	5bbc                	lw	a5,112(a5)
    800060c4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800060c8:	8ba1                	andi	a5,a5,8
    800060ca:	10078563          	beqz	a5,800061d4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060ce:	100017b7          	lui	a5,0x10001
    800060d2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800060d6:	43fc                	lw	a5,68(a5)
    800060d8:	2781                	sext.w	a5,a5
    800060da:	10079563          	bnez	a5,800061e4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060de:	100017b7          	lui	a5,0x10001
    800060e2:	5bdc                	lw	a5,52(a5)
    800060e4:	2781                	sext.w	a5,a5
  if(max == 0)
    800060e6:	10078763          	beqz	a5,800061f4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800060ea:	471d                	li	a4,7
    800060ec:	10f77c63          	bgeu	a4,a5,80006204 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800060f0:	ffffb097          	auipc	ra,0xffffb
    800060f4:	9f6080e7          	jalr	-1546(ra) # 80000ae6 <kalloc>
    800060f8:	0001d497          	auipc	s1,0x1d
    800060fc:	8a848493          	addi	s1,s1,-1880 # 800229a0 <disk>
    80006100:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006102:	ffffb097          	auipc	ra,0xffffb
    80006106:	9e4080e7          	jalr	-1564(ra) # 80000ae6 <kalloc>
    8000610a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000610c:	ffffb097          	auipc	ra,0xffffb
    80006110:	9da080e7          	jalr	-1574(ra) # 80000ae6 <kalloc>
    80006114:	87aa                	mv	a5,a0
    80006116:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006118:	6088                	ld	a0,0(s1)
    8000611a:	cd6d                	beqz	a0,80006214 <virtio_disk_init+0x1dc>
    8000611c:	0001d717          	auipc	a4,0x1d
    80006120:	88c73703          	ld	a4,-1908(a4) # 800229a8 <disk+0x8>
    80006124:	cb65                	beqz	a4,80006214 <virtio_disk_init+0x1dc>
    80006126:	c7fd                	beqz	a5,80006214 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006128:	6605                	lui	a2,0x1
    8000612a:	4581                	li	a1,0
    8000612c:	ffffb097          	auipc	ra,0xffffb
    80006130:	ba6080e7          	jalr	-1114(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006134:	0001d497          	auipc	s1,0x1d
    80006138:	86c48493          	addi	s1,s1,-1940 # 800229a0 <disk>
    8000613c:	6605                	lui	a2,0x1
    8000613e:	4581                	li	a1,0
    80006140:	6488                	ld	a0,8(s1)
    80006142:	ffffb097          	auipc	ra,0xffffb
    80006146:	b90080e7          	jalr	-1136(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000614a:	6605                	lui	a2,0x1
    8000614c:	4581                	li	a1,0
    8000614e:	6888                	ld	a0,16(s1)
    80006150:	ffffb097          	auipc	ra,0xffffb
    80006154:	b82080e7          	jalr	-1150(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006158:	100017b7          	lui	a5,0x10001
    8000615c:	4721                	li	a4,8
    8000615e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006160:	4098                	lw	a4,0(s1)
    80006162:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006166:	40d8                	lw	a4,4(s1)
    80006168:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000616c:	6498                	ld	a4,8(s1)
    8000616e:	0007069b          	sext.w	a3,a4
    80006172:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006176:	9701                	srai	a4,a4,0x20
    80006178:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000617c:	6898                	ld	a4,16(s1)
    8000617e:	0007069b          	sext.w	a3,a4
    80006182:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006186:	9701                	srai	a4,a4,0x20
    80006188:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000618c:	4705                	li	a4,1
    8000618e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006190:	00e48c23          	sb	a4,24(s1)
    80006194:	00e48ca3          	sb	a4,25(s1)
    80006198:	00e48d23          	sb	a4,26(s1)
    8000619c:	00e48da3          	sb	a4,27(s1)
    800061a0:	00e48e23          	sb	a4,28(s1)
    800061a4:	00e48ea3          	sb	a4,29(s1)
    800061a8:	00e48f23          	sb	a4,30(s1)
    800061ac:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800061b0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800061b4:	0727a823          	sw	s2,112(a5)
}
    800061b8:	60e2                	ld	ra,24(sp)
    800061ba:	6442                	ld	s0,16(sp)
    800061bc:	64a2                	ld	s1,8(sp)
    800061be:	6902                	ld	s2,0(sp)
    800061c0:	6105                	addi	sp,sp,32
    800061c2:	8082                	ret
    panic("could not find virtio disk");
    800061c4:	00002517          	auipc	a0,0x2
    800061c8:	7b450513          	addi	a0,a0,1972 # 80008978 <syscalls+0x458>
    800061cc:	ffffa097          	auipc	ra,0xffffa
    800061d0:	372080e7          	jalr	882(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    800061d4:	00002517          	auipc	a0,0x2
    800061d8:	7c450513          	addi	a0,a0,1988 # 80008998 <syscalls+0x478>
    800061dc:	ffffa097          	auipc	ra,0xffffa
    800061e0:	362080e7          	jalr	866(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    800061e4:	00002517          	auipc	a0,0x2
    800061e8:	7d450513          	addi	a0,a0,2004 # 800089b8 <syscalls+0x498>
    800061ec:	ffffa097          	auipc	ra,0xffffa
    800061f0:	352080e7          	jalr	850(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800061f4:	00002517          	auipc	a0,0x2
    800061f8:	7e450513          	addi	a0,a0,2020 # 800089d8 <syscalls+0x4b8>
    800061fc:	ffffa097          	auipc	ra,0xffffa
    80006200:	342080e7          	jalr	834(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006204:	00002517          	auipc	a0,0x2
    80006208:	7f450513          	addi	a0,a0,2036 # 800089f8 <syscalls+0x4d8>
    8000620c:	ffffa097          	auipc	ra,0xffffa
    80006210:	332080e7          	jalr	818(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006214:	00003517          	auipc	a0,0x3
    80006218:	80450513          	addi	a0,a0,-2044 # 80008a18 <syscalls+0x4f8>
    8000621c:	ffffa097          	auipc	ra,0xffffa
    80006220:	322080e7          	jalr	802(ra) # 8000053e <panic>

0000000080006224 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006224:	7119                	addi	sp,sp,-128
    80006226:	fc86                	sd	ra,120(sp)
    80006228:	f8a2                	sd	s0,112(sp)
    8000622a:	f4a6                	sd	s1,104(sp)
    8000622c:	f0ca                	sd	s2,96(sp)
    8000622e:	ecce                	sd	s3,88(sp)
    80006230:	e8d2                	sd	s4,80(sp)
    80006232:	e4d6                	sd	s5,72(sp)
    80006234:	e0da                	sd	s6,64(sp)
    80006236:	fc5e                	sd	s7,56(sp)
    80006238:	f862                	sd	s8,48(sp)
    8000623a:	f466                	sd	s9,40(sp)
    8000623c:	f06a                	sd	s10,32(sp)
    8000623e:	ec6e                	sd	s11,24(sp)
    80006240:	0100                	addi	s0,sp,128
    80006242:	8aaa                	mv	s5,a0
    80006244:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006246:	00c52d03          	lw	s10,12(a0)
    8000624a:	001d1d1b          	slliw	s10,s10,0x1
    8000624e:	1d02                	slli	s10,s10,0x20
    80006250:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006254:	0001d517          	auipc	a0,0x1d
    80006258:	87450513          	addi	a0,a0,-1932 # 80022ac8 <disk+0x128>
    8000625c:	ffffb097          	auipc	ra,0xffffb
    80006260:	97a080e7          	jalr	-1670(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006264:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006266:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006268:	0001cb97          	auipc	s7,0x1c
    8000626c:	738b8b93          	addi	s7,s7,1848 # 800229a0 <disk>
  for(int i = 0; i < 3; i++){
    80006270:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006272:	0001dc97          	auipc	s9,0x1d
    80006276:	856c8c93          	addi	s9,s9,-1962 # 80022ac8 <disk+0x128>
    8000627a:	a08d                	j	800062dc <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000627c:	00fb8733          	add	a4,s7,a5
    80006280:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006284:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006286:	0207c563          	bltz	a5,800062b0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000628a:	2905                	addiw	s2,s2,1
    8000628c:	0611                	addi	a2,a2,4
    8000628e:	05690c63          	beq	s2,s6,800062e6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006292:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006294:	0001c717          	auipc	a4,0x1c
    80006298:	70c70713          	addi	a4,a4,1804 # 800229a0 <disk>
    8000629c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000629e:	01874683          	lbu	a3,24(a4)
    800062a2:	fee9                	bnez	a3,8000627c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800062a4:	2785                	addiw	a5,a5,1
    800062a6:	0705                	addi	a4,a4,1
    800062a8:	fe979be3          	bne	a5,s1,8000629e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800062ac:	57fd                	li	a5,-1
    800062ae:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800062b0:	01205d63          	blez	s2,800062ca <virtio_disk_rw+0xa6>
    800062b4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800062b6:	000a2503          	lw	a0,0(s4)
    800062ba:	00000097          	auipc	ra,0x0
    800062be:	cfc080e7          	jalr	-772(ra) # 80005fb6 <free_desc>
      for(int j = 0; j < i; j++)
    800062c2:	2d85                	addiw	s11,s11,1
    800062c4:	0a11                	addi	s4,s4,4
    800062c6:	ffb918e3          	bne	s2,s11,800062b6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062ca:	85e6                	mv	a1,s9
    800062cc:	0001c517          	auipc	a0,0x1c
    800062d0:	6ec50513          	addi	a0,a0,1772 # 800229b8 <disk+0x18>
    800062d4:	ffffc097          	auipc	ra,0xffffc
    800062d8:	e4e080e7          	jalr	-434(ra) # 80002122 <sleep>
  for(int i = 0; i < 3; i++){
    800062dc:	f8040a13          	addi	s4,s0,-128
{
    800062e0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800062e2:	894e                	mv	s2,s3
    800062e4:	b77d                	j	80006292 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062e6:	f8042583          	lw	a1,-128(s0)
    800062ea:	00a58793          	addi	a5,a1,10
    800062ee:	0792                	slli	a5,a5,0x4

  if(write)
    800062f0:	0001c617          	auipc	a2,0x1c
    800062f4:	6b060613          	addi	a2,a2,1712 # 800229a0 <disk>
    800062f8:	00f60733          	add	a4,a2,a5
    800062fc:	018036b3          	snez	a3,s8
    80006300:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006302:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006306:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000630a:	f6078693          	addi	a3,a5,-160
    8000630e:	6218                	ld	a4,0(a2)
    80006310:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006312:	00878513          	addi	a0,a5,8
    80006316:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006318:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000631a:	6208                	ld	a0,0(a2)
    8000631c:	96aa                	add	a3,a3,a0
    8000631e:	4741                	li	a4,16
    80006320:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006322:	4705                	li	a4,1
    80006324:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006328:	f8442703          	lw	a4,-124(s0)
    8000632c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006330:	0712                	slli	a4,a4,0x4
    80006332:	953a                	add	a0,a0,a4
    80006334:	058a8693          	addi	a3,s5,88
    80006338:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000633a:	6208                	ld	a0,0(a2)
    8000633c:	972a                	add	a4,a4,a0
    8000633e:	40000693          	li	a3,1024
    80006342:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006344:	001c3c13          	seqz	s8,s8
    80006348:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000634a:	001c6c13          	ori	s8,s8,1
    8000634e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006352:	f8842603          	lw	a2,-120(s0)
    80006356:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000635a:	0001c697          	auipc	a3,0x1c
    8000635e:	64668693          	addi	a3,a3,1606 # 800229a0 <disk>
    80006362:	00258713          	addi	a4,a1,2
    80006366:	0712                	slli	a4,a4,0x4
    80006368:	9736                	add	a4,a4,a3
    8000636a:	587d                	li	a6,-1
    8000636c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006370:	0612                	slli	a2,a2,0x4
    80006372:	9532                	add	a0,a0,a2
    80006374:	f9078793          	addi	a5,a5,-112
    80006378:	97b6                	add	a5,a5,a3
    8000637a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000637c:	629c                	ld	a5,0(a3)
    8000637e:	97b2                	add	a5,a5,a2
    80006380:	4605                	li	a2,1
    80006382:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006384:	4509                	li	a0,2
    80006386:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000638a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000638e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006392:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006396:	6698                	ld	a4,8(a3)
    80006398:	00275783          	lhu	a5,2(a4)
    8000639c:	8b9d                	andi	a5,a5,7
    8000639e:	0786                	slli	a5,a5,0x1
    800063a0:	97ba                	add	a5,a5,a4
    800063a2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800063a6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800063aa:	6698                	ld	a4,8(a3)
    800063ac:	00275783          	lhu	a5,2(a4)
    800063b0:	2785                	addiw	a5,a5,1
    800063b2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800063b6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063ba:	100017b7          	lui	a5,0x10001
    800063be:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063c2:	004aa783          	lw	a5,4(s5)
    800063c6:	02c79163          	bne	a5,a2,800063e8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800063ca:	0001c917          	auipc	s2,0x1c
    800063ce:	6fe90913          	addi	s2,s2,1790 # 80022ac8 <disk+0x128>
  while(b->disk == 1) {
    800063d2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063d4:	85ca                	mv	a1,s2
    800063d6:	8556                	mv	a0,s5
    800063d8:	ffffc097          	auipc	ra,0xffffc
    800063dc:	d4a080e7          	jalr	-694(ra) # 80002122 <sleep>
  while(b->disk == 1) {
    800063e0:	004aa783          	lw	a5,4(s5)
    800063e4:	fe9788e3          	beq	a5,s1,800063d4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800063e8:	f8042903          	lw	s2,-128(s0)
    800063ec:	00290793          	addi	a5,s2,2
    800063f0:	00479713          	slli	a4,a5,0x4
    800063f4:	0001c797          	auipc	a5,0x1c
    800063f8:	5ac78793          	addi	a5,a5,1452 # 800229a0 <disk>
    800063fc:	97ba                	add	a5,a5,a4
    800063fe:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006402:	0001c997          	auipc	s3,0x1c
    80006406:	59e98993          	addi	s3,s3,1438 # 800229a0 <disk>
    8000640a:	00491713          	slli	a4,s2,0x4
    8000640e:	0009b783          	ld	a5,0(s3)
    80006412:	97ba                	add	a5,a5,a4
    80006414:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006418:	854a                	mv	a0,s2
    8000641a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000641e:	00000097          	auipc	ra,0x0
    80006422:	b98080e7          	jalr	-1128(ra) # 80005fb6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006426:	8885                	andi	s1,s1,1
    80006428:	f0ed                	bnez	s1,8000640a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000642a:	0001c517          	auipc	a0,0x1c
    8000642e:	69e50513          	addi	a0,a0,1694 # 80022ac8 <disk+0x128>
    80006432:	ffffb097          	auipc	ra,0xffffb
    80006436:	858080e7          	jalr	-1960(ra) # 80000c8a <release>
}
    8000643a:	70e6                	ld	ra,120(sp)
    8000643c:	7446                	ld	s0,112(sp)
    8000643e:	74a6                	ld	s1,104(sp)
    80006440:	7906                	ld	s2,96(sp)
    80006442:	69e6                	ld	s3,88(sp)
    80006444:	6a46                	ld	s4,80(sp)
    80006446:	6aa6                	ld	s5,72(sp)
    80006448:	6b06                	ld	s6,64(sp)
    8000644a:	7be2                	ld	s7,56(sp)
    8000644c:	7c42                	ld	s8,48(sp)
    8000644e:	7ca2                	ld	s9,40(sp)
    80006450:	7d02                	ld	s10,32(sp)
    80006452:	6de2                	ld	s11,24(sp)
    80006454:	6109                	addi	sp,sp,128
    80006456:	8082                	ret

0000000080006458 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006458:	1101                	addi	sp,sp,-32
    8000645a:	ec06                	sd	ra,24(sp)
    8000645c:	e822                	sd	s0,16(sp)
    8000645e:	e426                	sd	s1,8(sp)
    80006460:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006462:	0001c497          	auipc	s1,0x1c
    80006466:	53e48493          	addi	s1,s1,1342 # 800229a0 <disk>
    8000646a:	0001c517          	auipc	a0,0x1c
    8000646e:	65e50513          	addi	a0,a0,1630 # 80022ac8 <disk+0x128>
    80006472:	ffffa097          	auipc	ra,0xffffa
    80006476:	764080e7          	jalr	1892(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000647a:	10001737          	lui	a4,0x10001
    8000647e:	533c                	lw	a5,96(a4)
    80006480:	8b8d                	andi	a5,a5,3
    80006482:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006484:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006488:	689c                	ld	a5,16(s1)
    8000648a:	0204d703          	lhu	a4,32(s1)
    8000648e:	0027d783          	lhu	a5,2(a5)
    80006492:	04f70863          	beq	a4,a5,800064e2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006496:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000649a:	6898                	ld	a4,16(s1)
    8000649c:	0204d783          	lhu	a5,32(s1)
    800064a0:	8b9d                	andi	a5,a5,7
    800064a2:	078e                	slli	a5,a5,0x3
    800064a4:	97ba                	add	a5,a5,a4
    800064a6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064a8:	00278713          	addi	a4,a5,2
    800064ac:	0712                	slli	a4,a4,0x4
    800064ae:	9726                	add	a4,a4,s1
    800064b0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800064b4:	e721                	bnez	a4,800064fc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064b6:	0789                	addi	a5,a5,2
    800064b8:	0792                	slli	a5,a5,0x4
    800064ba:	97a6                	add	a5,a5,s1
    800064bc:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800064be:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064c2:	ffffc097          	auipc	ra,0xffffc
    800064c6:	cc4080e7          	jalr	-828(ra) # 80002186 <wakeup>

    disk.used_idx += 1;
    800064ca:	0204d783          	lhu	a5,32(s1)
    800064ce:	2785                	addiw	a5,a5,1
    800064d0:	17c2                	slli	a5,a5,0x30
    800064d2:	93c1                	srli	a5,a5,0x30
    800064d4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064d8:	6898                	ld	a4,16(s1)
    800064da:	00275703          	lhu	a4,2(a4)
    800064de:	faf71ce3          	bne	a4,a5,80006496 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800064e2:	0001c517          	auipc	a0,0x1c
    800064e6:	5e650513          	addi	a0,a0,1510 # 80022ac8 <disk+0x128>
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	7a0080e7          	jalr	1952(ra) # 80000c8a <release>
}
    800064f2:	60e2                	ld	ra,24(sp)
    800064f4:	6442                	ld	s0,16(sp)
    800064f6:	64a2                	ld	s1,8(sp)
    800064f8:	6105                	addi	sp,sp,32
    800064fa:	8082                	ret
      panic("virtio_disk_intr status");
    800064fc:	00002517          	auipc	a0,0x2
    80006500:	53450513          	addi	a0,a0,1332 # 80008a30 <syscalls+0x510>
    80006504:	ffffa097          	auipc	ra,0xffffa
    80006508:	03a080e7          	jalr	58(ra) # 8000053e <panic>

000000008000650c <free_desc>:
    panic("virtio_gpu: no free descriptors");
}

static void
free_desc(int i)
{
    8000650c:	1141                	addi	sp,sp,-16
    8000650e:	e422                	sd	s0,8(sp)
    80006510:	0800                	addi	s0,sp,16
    gq.desc[i].addr = 0;
    80006512:	0001c717          	auipc	a4,0x1c
    80006516:	5ce70713          	addi	a4,a4,1486 # 80022ae0 <gq>
    8000651a:	00451693          	slli	a3,a0,0x4
    8000651e:	631c                	ld	a5,0(a4)
    80006520:	97b6                	add	a5,a5,a3
    80006522:	0007b023          	sd	zero,0(a5)
    gq.desc[i].len = 0;
    80006526:	0007a423          	sw	zero,8(a5)
    gq.desc[i].flags = 0;
    8000652a:	00079623          	sh	zero,12(a5)
    gq.desc[i].next = 0;
    8000652e:	00079723          	sh	zero,14(a5)
    gq.free[i] = 1;
    80006532:	972a                	add	a4,a4,a0
    80006534:	4785                	li	a5,1
    80006536:	00f70c23          	sb	a5,24(a4)
}
    8000653a:	6422                	ld	s0,8(sp)
    8000653c:	0141                	addi	sp,sp,16
    8000653e:	8082                	ret

0000000080006540 <alloc_desc>:
    for (int i = 0; i < GPU_NUM; i++)
    80006540:	0001c797          	auipc	a5,0x1c
    80006544:	5a078793          	addi	a5,a5,1440 # 80022ae0 <gq>
    80006548:	4501                	li	a0,0
    8000654a:	46a1                	li	a3,8
        if (gq.free[i])
    8000654c:	0187c703          	lbu	a4,24(a5)
    80006550:	e30d                	bnez	a4,80006572 <alloc_desc+0x32>
    for (int i = 0; i < GPU_NUM; i++)
    80006552:	2505                	addiw	a0,a0,1
    80006554:	0785                	addi	a5,a5,1
    80006556:	fed51be3          	bne	a0,a3,8000654c <alloc_desc+0xc>
{
    8000655a:	1141                	addi	sp,sp,-16
    8000655c:	e406                	sd	ra,8(sp)
    8000655e:	e022                	sd	s0,0(sp)
    80006560:	0800                	addi	s0,sp,16
    panic("virtio_gpu: no free descriptors");
    80006562:	00002517          	auipc	a0,0x2
    80006566:	4e650513          	addi	a0,a0,1254 # 80008a48 <syscalls+0x528>
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	fd4080e7          	jalr	-44(ra) # 8000053e <panic>
            gq.free[i] = 0;
    80006572:	0001c797          	auipc	a5,0x1c
    80006576:	56e78793          	addi	a5,a5,1390 # 80022ae0 <gq>
    8000657a:	97aa                	add	a5,a5,a0
    8000657c:	00078c23          	sb	zero,24(a5)
}
    80006580:	8082                	ret

0000000080006582 <gpu_send>:

// Submit a 2-descriptor command (request + shared response) and block
// until the device completes it by advancing the used ring.
static void
gpu_send(void *req, int req_len)
{
    80006582:	7139                	addi	sp,sp,-64
    80006584:	fc06                	sd	ra,56(sp)
    80006586:	f822                	sd	s0,48(sp)
    80006588:	f426                	sd	s1,40(sp)
    8000658a:	f04a                	sd	s2,32(sp)
    8000658c:	ec4e                	sd	s3,24(sp)
    8000658e:	e852                	sd	s4,16(sp)
    80006590:	e456                	sd	s5,8(sp)
    80006592:	0080                	addi	s0,sp,64
    80006594:	8aaa                	mv	s5,a0
    80006596:	8a2e                	mv	s4,a1
    acquire(&gpu_lock);
    80006598:	0001c997          	auipc	s3,0x1c
    8000659c:	54898993          	addi	s3,s3,1352 # 80022ae0 <gq>
    800065a0:	0001c517          	auipc	a0,0x1c
    800065a4:	56850513          	addi	a0,a0,1384 # 80022b08 <gpu_lock>
    800065a8:	ffffa097          	auipc	ra,0xffffa
    800065ac:	62e080e7          	jalr	1582(ra) # 80000bd6 <acquire>
    int d0 = alloc_desc();
    800065b0:	00000097          	auipc	ra,0x0
    800065b4:	f90080e7          	jalr	-112(ra) # 80006540 <alloc_desc>
    800065b8:	892a                	mv	s2,a0
    int d1 = alloc_desc();
    800065ba:	00000097          	auipc	ra,0x0
    800065be:	f86080e7          	jalr	-122(ra) # 80006540 <alloc_desc>
    800065c2:	84aa                	mv	s1,a0

    gq.desc[d0].addr = (uint64)req;
    800065c4:	00491793          	slli	a5,s2,0x4
    800065c8:	0009b703          	ld	a4,0(s3)
    800065cc:	973e                	add	a4,a4,a5
    800065ce:	01573023          	sd	s5,0(a4)
    gq.desc[d0].len = (uint32)req_len;
    800065d2:	0009b703          	ld	a4,0(s3)
    800065d6:	97ba                	add	a5,a5,a4
    800065d8:	0147a423          	sw	s4,8(a5)
    gq.desc[d0].flags = VRING_DESC_F_NEXT;
    800065dc:	4685                	li	a3,1
    800065de:	00d79623          	sh	a3,12(a5)
    gq.desc[d0].next = d1;
    800065e2:	00a79723          	sh	a0,14(a5)

    gq.desc[d1].addr = (uint64)&cmd_resp;
    800065e6:	00451693          	slli	a3,a0,0x4
    800065ea:	9736                	add	a4,a4,a3
    800065ec:	0001c797          	auipc	a5,0x1c
    800065f0:	53478793          	addi	a5,a5,1332 # 80022b20 <cmd_resp>
    800065f4:	e31c                	sd	a5,0(a4)
    gq.desc[d1].len = sizeof(cmd_resp);
    800065f6:	0009b783          	ld	a5,0(s3)
    800065fa:	97b6                	add	a5,a5,a3
    800065fc:	4761                	li	a4,24
    800065fe:	c798                	sw	a4,8(a5)
    gq.desc[d1].flags = VRING_DESC_F_WRITE;
    80006600:	4709                	li	a4,2
    80006602:	00e79623          	sh	a4,12(a5)
    gq.desc[d1].next = 0;
    80006606:	00079723          	sh	zero,14(a5)

    // Place head descriptor index in the available ring.
    gq.avail->ring[gq.avail->idx % GPU_NUM] = d0;
    8000660a:	0089b703          	ld	a4,8(s3)
    8000660e:	00275783          	lhu	a5,2(a4)
    80006612:	8b9d                	andi	a5,a5,7
    80006614:	0786                	slli	a5,a5,0x1
    80006616:	97ba                	add	a5,a5,a4
    80006618:	01279223          	sh	s2,4(a5)
    __sync_synchronize();
    8000661c:	0ff0000f          	fence
    gq.avail->idx++;
    80006620:	0089b703          	ld	a4,8(s3)
    80006624:	00275783          	lhu	a5,2(a4)
    80006628:	2785                	addiw	a5,a5,1
    8000662a:	00f71123          	sh	a5,2(a4)
    __sync_synchronize();
    8000662e:	0ff0000f          	fence

    // Notify device (queue index 0 = controlq).
    *R1(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;
    80006632:	100027b7          	lui	a5,0x10002
    80006636:	0407a823          	sw	zero,80(a5) # 10002050 <_entry-0x6fffdfb0>

    // Poll until the device advances the used ring.
    while (1)
    {
        __sync_synchronize();
        if (gq.used->idx != gq.used_idx)
    8000663a:	874e                	mv	a4,s3
        __sync_synchronize();
    8000663c:	0ff0000f          	fence
        if (gq.used->idx != gq.used_idx)
    80006640:	02075783          	lhu	a5,32(a4)
    80006644:	6b14                	ld	a3,16(a4)
    80006646:	0026d683          	lhu	a3,2(a3)
    8000664a:	fef689e3          	beq	a3,a5,8000663c <gpu_send+0xba>
            break;
    }
    gq.used_idx++;
    8000664e:	2785                	addiw	a5,a5,1
    80006650:	0001c717          	auipc	a4,0x1c
    80006654:	4af71823          	sh	a5,1200(a4) # 80022b00 <gq+0x20>

    free_desc(d0);
    80006658:	854a                	mv	a0,s2
    8000665a:	00000097          	auipc	ra,0x0
    8000665e:	eb2080e7          	jalr	-334(ra) # 8000650c <free_desc>
    free_desc(d1);
    80006662:	8526                	mv	a0,s1
    80006664:	00000097          	auipc	ra,0x0
    80006668:	ea8080e7          	jalr	-344(ra) # 8000650c <free_desc>
    release(&gpu_lock);
    8000666c:	0001c517          	auipc	a0,0x1c
    80006670:	49c50513          	addi	a0,a0,1180 # 80022b08 <gpu_lock>
    80006674:	ffffa097          	auipc	ra,0xffffa
    80006678:	616080e7          	jalr	1558(ra) # 80000c8a <release>
}
    8000667c:	70e2                	ld	ra,56(sp)
    8000667e:	7442                	ld	s0,48(sp)
    80006680:	74a2                	ld	s1,40(sp)
    80006682:	7902                	ld	s2,32(sp)
    80006684:	69e2                	ld	s3,24(sp)
    80006686:	6a42                	ld	s4,16(sp)
    80006688:	6aa2                	ld	s5,8(sp)
    8000668a:	6121                	addi	sp,sp,64
    8000668c:	8082                	ret

000000008000668e <gpu_cmd_attach>:
{
    8000668e:	1141                	addi	sp,sp,-16
    80006690:	e406                	sd	ra,8(sp)
    80006692:	e022                	sd	s0,0(sp)
    80006694:	0800                	addi	s0,sp,16
    attach_buf.backing.hdr.type = VIRTIO_GPU_CMD_RESOURCE_ATTACH_BACKING;
    80006696:	0001f797          	auipc	a5,0x1f
    8000669a:	b0278793          	addi	a5,a5,-1278 # 80025198 <attach_buf>
    8000669e:	10600713          	li	a4,262
    800066a2:	c398                	sw	a4,0(a5)
    attach_buf.backing.resource_id = RESOURCE_ID;
    800066a4:	4705                	li	a4,1
    800066a6:	cf98                	sw	a4,24(a5)
    attach_buf.backing.nr_entries = n;
    800066a8:	0005861b          	sext.w	a2,a1
    800066ac:	cfd0                	sw	a2,28(a5)
    for (int i = 0; i < n; i++)
    800066ae:	02b05663          	blez	a1,800066da <gpu_cmd_attach+0x4c>
    800066b2:	87aa                	mv	a5,a0
    800066b4:	0001f717          	auipc	a4,0x1f
    800066b8:	b0470713          	addi	a4,a4,-1276 # 800251b8 <attach_buf+0x20>
    800066bc:	fff6069b          	addiw	a3,a2,-1
    800066c0:	1682                	slli	a3,a3,0x20
    800066c2:	9281                	srli	a3,a3,0x20
    800066c4:	0692                	slli	a3,a3,0x4
    800066c6:	0541                	addi	a0,a0,16
    800066c8:	96aa                	add	a3,a3,a0
        attach_buf.entries[i] = entries[i];
    800066ca:	6390                	ld	a2,0(a5)
    800066cc:	e310                	sd	a2,0(a4)
    800066ce:	6790                	ld	a2,8(a5)
    800066d0:	e710                	sd	a2,8(a4)
    for (int i = 0; i < n; i++)
    800066d2:	07c1                	addi	a5,a5,16
    800066d4:	0741                	addi	a4,a4,16
    800066d6:	fed79ae3          	bne	a5,a3,800066ca <gpu_cmd_attach+0x3c>
    gpu_send(&attach_buf, sizeof(attach_buf));
    800066da:	6585                	lui	a1,0x1
    800066dc:	2e058593          	addi	a1,a1,736 # 12e0 <_entry-0x7fffed20>
    800066e0:	0001f517          	auipc	a0,0x1f
    800066e4:	ab850513          	addi	a0,a0,-1352 # 80025198 <attach_buf>
    800066e8:	00000097          	auipc	ra,0x0
    800066ec:	e9a080e7          	jalr	-358(ra) # 80006582 <gpu_send>
}
    800066f0:	60a2                	ld	ra,8(sp)
    800066f2:	6402                	ld	s0,0(sp)
    800066f4:	0141                	addi	sp,sp,16
    800066f6:	8082                	ret

00000000800066f8 <gpu_transfer_flush>:
{
    800066f8:	7139                	addi	sp,sp,-64
    800066fa:	fc06                	sd	ra,56(sp)
    800066fc:	f822                	sd	s0,48(sp)
    800066fe:	f426                	sd	s1,40(sp)
    80006700:	f04a                	sd	s2,32(sp)
    80006702:	ec4e                	sd	s3,24(sp)
    80006704:	e852                	sd	s4,16(sp)
    80006706:	e456                	sd	s5,8(sp)
    80006708:	0080                	addi	s0,sp,64
    memset(&xfer, 0, sizeof(xfer));
    8000670a:	0001c497          	auipc	s1,0x1c
    8000670e:	3d648493          	addi	s1,s1,982 # 80022ae0 <gq>
    80006712:	0001c917          	auipc	s2,0x1c
    80006716:	42690913          	addi	s2,s2,1062 # 80022b38 <xfer.3>
    8000671a:	03800613          	li	a2,56
    8000671e:	4581                	li	a1,0
    80006720:	854a                	mv	a0,s2
    80006722:	ffffa097          	auipc	ra,0xffffa
    80006726:	5b0080e7          	jalr	1456(ra) # 80000cd2 <memset>
    xfer.hdr.type = VIRTIO_GPU_CMD_TRANSFER_TO_HOST_2D;
    8000672a:	10500793          	li	a5,261
    8000672e:	ccbc                	sw	a5,88(s1)
    xfer.r.x = 0;
    80006730:	0604a823          	sw	zero,112(s1)
    xfer.r.y = 0;
    80006734:	0604aa23          	sw	zero,116(s1)
    xfer.r.width = SCREEN_W;
    80006738:	28000a93          	li	s5,640
    8000673c:	0754ac23          	sw	s5,120(s1)
    xfer.r.height = SCREEN_H;
    80006740:	1e000a13          	li	s4,480
    80006744:	0744ae23          	sw	s4,124(s1)
    xfer.resource_id = RESOURCE_ID;
    80006748:	4985                	li	s3,1
    8000674a:	0934a423          	sw	s3,136(s1)
    gpu_send(&xfer, sizeof(xfer));
    8000674e:	03800593          	li	a1,56
    80006752:	854a                	mv	a0,s2
    80006754:	00000097          	auipc	ra,0x0
    80006758:	e2e080e7          	jalr	-466(ra) # 80006582 <gpu_send>
    memset(&flush, 0, sizeof(flush));
    8000675c:	0001c917          	auipc	s2,0x1c
    80006760:	41490913          	addi	s2,s2,1044 # 80022b70 <flush.2>
    80006764:	03000613          	li	a2,48
    80006768:	4581                	li	a1,0
    8000676a:	854a                	mv	a0,s2
    8000676c:	ffffa097          	auipc	ra,0xffffa
    80006770:	566080e7          	jalr	1382(ra) # 80000cd2 <memset>
    flush.hdr.type = VIRTIO_GPU_CMD_RESOURCE_FLUSH;
    80006774:	10400793          	li	a5,260
    80006778:	08f4a823          	sw	a5,144(s1)
    flush.r.x = 0;
    8000677c:	0a04a423          	sw	zero,168(s1)
    flush.r.y = 0;
    80006780:	0a04a623          	sw	zero,172(s1)
    flush.r.width = SCREEN_W;
    80006784:	0b54a823          	sw	s5,176(s1)
    flush.r.height = SCREEN_H;
    80006788:	0b44aa23          	sw	s4,180(s1)
    flush.resource_id = RESOURCE_ID;
    8000678c:	0b34ac23          	sw	s3,184(s1)
    gpu_send(&flush, sizeof(flush));
    80006790:	03000593          	li	a1,48
    80006794:	854a                	mv	a0,s2
    80006796:	00000097          	auipc	ra,0x0
    8000679a:	dec080e7          	jalr	-532(ra) # 80006582 <gpu_send>
}
    8000679e:	70e2                	ld	ra,56(sp)
    800067a0:	7442                	ld	s0,48(sp)
    800067a2:	74a2                	ld	s1,40(sp)
    800067a4:	7902                	ld	s2,32(sp)
    800067a6:	69e2                	ld	s3,24(sp)
    800067a8:	6a42                	ld	s4,16(sp)
    800067aa:	6aa2                	ld	s5,8(sp)
    800067ac:	6121                	addi	sp,sp,64
    800067ae:	8082                	ret

00000000800067b0 <virtio_gpu_init>:

// ── Public init ───────────────────────────────────────────────────────

void virtio_gpu_init(void)
{
    800067b0:	7159                	addi	sp,sp,-112
    800067b2:	f486                	sd	ra,104(sp)
    800067b4:	f0a2                	sd	s0,96(sp)
    800067b6:	eca6                	sd	s1,88(sp)
    800067b8:	e8ca                	sd	s2,80(sp)
    800067ba:	e4ce                	sd	s3,72(sp)
    800067bc:	e0d2                	sd	s4,64(sp)
    800067be:	fc56                	sd	s5,56(sp)
    800067c0:	f85a                	sd	s6,48(sp)
    800067c2:	f45e                	sd	s7,40(sp)
    800067c4:	f062                	sd	s8,32(sp)
    800067c6:	ec66                	sd	s9,24(sp)
    800067c8:	e86a                	sd	s10,16(sp)
    800067ca:	e46e                	sd	s11,8(sp)
    800067cc:	1880                	addi	s0,sp,112
    uint32 status = 0;
    initlock(&gpu_lock, "vgpu");
    800067ce:	00002597          	auipc	a1,0x2
    800067d2:	29a58593          	addi	a1,a1,666 # 80008a68 <syscalls+0x548>
    800067d6:	0001c517          	auipc	a0,0x1c
    800067da:	33250513          	addi	a0,a0,818 # 80022b08 <gpu_lock>
    800067de:	ffffa097          	auipc	ra,0xffffa
    800067e2:	368080e7          	jalr	872(ra) # 80000b46 <initlock>

    // ── 1. VirtIO device handshake ──────────────────────────────────────
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067e6:	100027b7          	lui	a5,0x10002
    800067ea:	4398                	lw	a4,0(a5)
    800067ec:	2701                	sext.w	a4,a4
    800067ee:	747277b7          	lui	a5,0x74727
    800067f2:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800067f6:	02f71a63          	bne	a4,a5,8000682a <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    800067fa:	100027b7          	lui	a5,0x10002
    800067fe:	43dc                	lw	a5,4(a5)
    80006800:	2781                	sext.w	a5,a5
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006802:	4709                	li	a4,2
    80006804:	02e79363          	bne	a5,a4,8000682a <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    80006808:	100027b7          	lui	a5,0x10002
    8000680c:	479c                	lw	a5,8(a5)
    8000680e:	2781                	sext.w	a5,a5
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    80006810:	4741                	li	a4,16
    80006812:	00e79c63          	bne	a5,a4,8000682a <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551)
    80006816:	100027b7          	lui	a5,0x10002
    8000681a:	47d8                	lw	a4,12(a5)
    8000681c:	2701                	sext.w	a4,a4
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    8000681e:	554d47b7          	lui	a5,0x554d4
    80006822:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006826:	02f70963          	beq	a4,a5,80006858 <virtio_gpu_init+0xa8>
    {
        printf("virtio_gpu_init: GPU not found\n");
    8000682a:	00002517          	auipc	a0,0x2
    8000682e:	24650513          	addi	a0,a0,582 # 80008a70 <syscalls+0x550>
    80006832:	ffffa097          	auipc	ra,0xffffa
    80006836:	d56080e7          	jalr	-682(ra) # 80000588 <printf>
    gpu_send(&scanout_req, sizeof(scanout_req));

    // ── 8. TRANSFER_TO_HOST_2D (upload guest memory -> host GPU) ─────────
    gpu_transfer_flush();
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
}
    8000683a:	70a6                	ld	ra,104(sp)
    8000683c:	7406                	ld	s0,96(sp)
    8000683e:	64e6                	ld	s1,88(sp)
    80006840:	6946                	ld	s2,80(sp)
    80006842:	69a6                	ld	s3,72(sp)
    80006844:	6a06                	ld	s4,64(sp)
    80006846:	7ae2                	ld	s5,56(sp)
    80006848:	7b42                	ld	s6,48(sp)
    8000684a:	7ba2                	ld	s7,40(sp)
    8000684c:	7c02                	ld	s8,32(sp)
    8000684e:	6ce2                	ld	s9,24(sp)
    80006850:	6d42                	ld	s10,16(sp)
    80006852:	6da2                	ld	s11,8(sp)
    80006854:	6165                	addi	sp,sp,112
    80006856:	8082                	ret
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006858:	100027b7          	lui	a5,0x10002
    8000685c:	0607a823          	sw	zero,112(a5) # 10002070 <_entry-0x6fffdf90>
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006860:	4705                	li	a4,1
    80006862:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006864:	470d                	li	a4,3
    80006866:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_DRIVER_FEATURES) = 0;
    80006868:	0207a023          	sw	zero,32(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    8000686c:	472d                	li	a4,11
    8000686e:	dbb8                	sw	a4,112(a5)
    if (!(*R1(VIRTIO_MMIO_STATUS) & VIRTIO_CONFIG_S_FEATURES_OK))
    80006870:	5bbc                	lw	a5,112(a5)
    80006872:	8ba1                	andi	a5,a5,8
    80006874:	1e078963          	beqz	a5,80006a66 <virtio_gpu_init+0x2b6>
    *R1(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006878:	100027b7          	lui	a5,0x10002
    8000687c:	0207a823          	sw	zero,48(a5) # 10002030 <_entry-0x6fffdfd0>
    if (*R1(VIRTIO_MMIO_QUEUE_READY))
    80006880:	43fc                	lw	a5,68(a5)
    80006882:	2781                	sext.w	a5,a5
    80006884:	1e079963          	bnez	a5,80006a76 <virtio_gpu_init+0x2c6>
    if (*R1(VIRTIO_MMIO_QUEUE_NUM_MAX) < GPU_NUM)
    80006888:	100027b7          	lui	a5,0x10002
    8000688c:	5bdc                	lw	a5,52(a5)
    8000688e:	2781                	sext.w	a5,a5
    80006890:	471d                	li	a4,7
    80006892:	1ef77a63          	bgeu	a4,a5,80006a86 <virtio_gpu_init+0x2d6>
    gq.desc = kalloc();
    80006896:	ffffa097          	auipc	ra,0xffffa
    8000689a:	250080e7          	jalr	592(ra) # 80000ae6 <kalloc>
    8000689e:	0001c497          	auipc	s1,0x1c
    800068a2:	24248493          	addi	s1,s1,578 # 80022ae0 <gq>
    800068a6:	e088                	sd	a0,0(s1)
    gq.avail = kalloc();
    800068a8:	ffffa097          	auipc	ra,0xffffa
    800068ac:	23e080e7          	jalr	574(ra) # 80000ae6 <kalloc>
    800068b0:	e488                	sd	a0,8(s1)
    gq.used = kalloc();
    800068b2:	ffffa097          	auipc	ra,0xffffa
    800068b6:	234080e7          	jalr	564(ra) # 80000ae6 <kalloc>
    800068ba:	87aa                	mv	a5,a0
    800068bc:	e888                	sd	a0,16(s1)
    if (!gq.desc || !gq.avail || !gq.used)
    800068be:	6088                	ld	a0,0(s1)
    800068c0:	1c050b63          	beqz	a0,80006a96 <virtio_gpu_init+0x2e6>
    800068c4:	0001c717          	auipc	a4,0x1c
    800068c8:	22473703          	ld	a4,548(a4) # 80022ae8 <gq+0x8>
    800068cc:	1c070563          	beqz	a4,80006a96 <virtio_gpu_init+0x2e6>
    800068d0:	1c078363          	beqz	a5,80006a96 <virtio_gpu_init+0x2e6>
    memset(gq.desc, 0, PGSIZE);
    800068d4:	6605                	lui	a2,0x1
    800068d6:	4581                	li	a1,0
    800068d8:	ffffa097          	auipc	ra,0xffffa
    800068dc:	3fa080e7          	jalr	1018(ra) # 80000cd2 <memset>
    memset(gq.avail, 0, PGSIZE);
    800068e0:	0001c497          	auipc	s1,0x1c
    800068e4:	20048493          	addi	s1,s1,512 # 80022ae0 <gq>
    800068e8:	6605                	lui	a2,0x1
    800068ea:	4581                	li	a1,0
    800068ec:	6488                	ld	a0,8(s1)
    800068ee:	ffffa097          	auipc	ra,0xffffa
    800068f2:	3e4080e7          	jalr	996(ra) # 80000cd2 <memset>
    memset(gq.used, 0, PGSIZE);
    800068f6:	6605                	lui	a2,0x1
    800068f8:	4581                	li	a1,0
    800068fa:	6888                	ld	a0,16(s1)
    800068fc:	ffffa097          	auipc	ra,0xffffa
    80006900:	3d6080e7          	jalr	982(ra) # 80000cd2 <memset>
    *R1(VIRTIO_MMIO_QUEUE_NUM) = GPU_NUM;
    80006904:	100027b7          	lui	a5,0x10002
    80006908:	4721                	li	a4,8
    8000690a:	df98                	sw	a4,56(a5)
    *R1(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)gq.desc;
    8000690c:	4098                	lw	a4,0(s1)
    8000690e:	08e7a023          	sw	a4,128(a5) # 10002080 <_entry-0x6fffdf80>
    *R1(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)gq.desc >> 32;
    80006912:	40d8                	lw	a4,4(s1)
    80006914:	08e7a223          	sw	a4,132(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)gq.avail;
    80006918:	6498                	ld	a4,8(s1)
    8000691a:	0007069b          	sext.w	a3,a4
    8000691e:	08d7a823          	sw	a3,144(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)gq.avail >> 32;
    80006922:	9701                	srai	a4,a4,0x20
    80006924:	08e7aa23          	sw	a4,148(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)gq.used;
    80006928:	6898                	ld	a4,16(s1)
    8000692a:	0007069b          	sext.w	a3,a4
    8000692e:	0ad7a023          	sw	a3,160(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)gq.used >> 32;
    80006932:	9701                	srai	a4,a4,0x20
    80006934:	0ae7a223          	sw	a4,164(a5)
    *R1(VIRTIO_MMIO_QUEUE_READY) = 1;
    80006938:	4705                	li	a4,1
    8000693a:	c3f8                	sw	a4,68(a5)
        gq.free[i] = 1;
    8000693c:	00e48c23          	sb	a4,24(s1)
    80006940:	00e48ca3          	sb	a4,25(s1)
    80006944:	00e48d23          	sb	a4,26(s1)
    80006948:	00e48da3          	sb	a4,27(s1)
    8000694c:	00e48e23          	sb	a4,28(s1)
    80006950:	00e48ea3          	sb	a4,29(s1)
    80006954:	00e48f23          	sb	a4,30(s1)
    80006958:	00e48fa3          	sb	a4,31(s1)
    *R1(VIRTIO_MMIO_STATUS) = status;
    8000695c:	473d                	li	a4,15
    8000695e:	dbb8                	sw	a4,112(a5)
    for (int i = 0; i < FB_PAGES; i++)
    80006960:	00020917          	auipc	s2,0x20
    80006964:	b1890913          	addi	s2,s2,-1256 # 80026478 <fb>
    80006968:	00020997          	auipc	s3,0x20
    8000696c:	47098993          	addi	s3,s3,1136 # 80026dd8 <end>
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006970:	84ca                	mv	s1,s2
        fb[i] = kalloc();
    80006972:	ffffa097          	auipc	ra,0xffffa
    80006976:	174080e7          	jalr	372(ra) # 80000ae6 <kalloc>
    8000697a:	e088                	sd	a0,0(s1)
        if (!fb[i])
    8000697c:	12050563          	beqz	a0,80006aa6 <virtio_gpu_init+0x2f6>
        memset(fb[i], 0, PGSIZE); // fill with COLOR_BG (0 = black)
    80006980:	6605                	lui	a2,0x1
    80006982:	4581                	li	a1,0
    80006984:	ffffa097          	auipc	ra,0xffffa
    80006988:	34e080e7          	jalr	846(ra) # 80000cd2 <memset>
    for (int i = 0; i < FB_PAGES; i++)
    8000698c:	04a1                	addi	s1,s1,8
    8000698e:	ff3492e3          	bne	s1,s3,80006972 <virtio_gpu_init+0x1c2>
    memset(&create_req, 0, sizeof(create_req));
    80006992:	0001c497          	auipc	s1,0x1c
    80006996:	14e48493          	addi	s1,s1,334 # 80022ae0 <gq>
    8000699a:	0001c997          	auipc	s3,0x1c
    8000699e:	20698993          	addi	s3,s3,518 # 80022ba0 <create_req.6>
    800069a2:	02800613          	li	a2,40
    800069a6:	4581                	li	a1,0
    800069a8:	854e                	mv	a0,s3
    800069aa:	ffffa097          	auipc	ra,0xffffa
    800069ae:	328080e7          	jalr	808(ra) # 80000cd2 <memset>
    create_req.hdr.type = VIRTIO_GPU_CMD_RESOURCE_CREATE_2D;
    800069b2:	10100793          	li	a5,257
    800069b6:	0cf4a023          	sw	a5,192(s1)
    create_req.resource_id = RESOURCE_ID;
    800069ba:	4785                	li	a5,1
    800069bc:	0cf4ac23          	sw	a5,216(s1)
    create_req.format = VIRTIO_GPU_FORMAT_B8G8R8X8_UNORM;
    800069c0:	4789                	li	a5,2
    800069c2:	0cf4ae23          	sw	a5,220(s1)
    create_req.width = SCREEN_W;
    800069c6:	28000793          	li	a5,640
    800069ca:	0ef4a023          	sw	a5,224(s1)
    create_req.height = SCREEN_H;
    800069ce:	1e000793          	li	a5,480
    800069d2:	0ef4a223          	sw	a5,228(s1)
    gpu_send(&create_req, sizeof(create_req));
    800069d6:	02800593          	li	a1,40
    800069da:	854e                	mv	a0,s3
    800069dc:	00000097          	auipc	ra,0x0
    800069e0:	ba6080e7          	jalr	-1114(ra) # 80006582 <gpu_send>
    for (int i = 0; i < FB_PAGES; i++) {
    800069e4:	0001d797          	auipc	a5,0x1d
    800069e8:	4f478793          	addi	a5,a5,1268 # 80023ed8 <fb_entries.5>
    800069ec:	0001e617          	auipc	a2,0x1e
    800069f0:	7ac60613          	addi	a2,a2,1964 # 80025198 <attach_buf>
        fb_entries[i].length = PGSIZE;
    800069f4:	6685                	lui	a3,0x1
        fb_entries[i].addr   = (uint64)fb[i];
    800069f6:	00093703          	ld	a4,0(s2)
    800069fa:	e398                	sd	a4,0(a5)
        fb_entries[i].length = PGSIZE;
    800069fc:	c794                	sw	a3,8(a5)
    for (int i = 0; i < FB_PAGES; i++) {
    800069fe:	0921                	addi	s2,s2,8
    80006a00:	07c1                	addi	a5,a5,16
    80006a02:	fec79ae3          	bne	a5,a2,800069f6 <virtio_gpu_init+0x246>
    gpu_cmd_attach(fb_entries, FB_PAGES);
    80006a06:	12c00593          	li	a1,300
    80006a0a:	0001d517          	auipc	a0,0x1d
    80006a0e:	4ce50513          	addi	a0,a0,1230 # 80023ed8 <fb_entries.5>
    80006a12:	00000097          	auipc	ra,0x0
    80006a16:	c7c080e7          	jalr	-900(ra) # 8000668e <gpu_cmd_attach>
        for (int i = 0; msg[i]; i++)
    80006a1a:	00002c17          	auipc	s8,0x2
    80006a1e:	12ec0c13          	addi	s8,s8,302 # 80008b48 <syscalls+0x628>
    gpu_cmd_attach(fb_entries, FB_PAGES);
    80006a22:	0008cbb7          	lui	s7,0x8c
    80006a26:	250b8b93          	addi	s7,s7,592 # 8c250 <_entry-0x7ff73db0>
        for (int i = 0; msg[i]; i++)
    80006a2a:	04800793          	li	a5,72
    const uint8 *rows = font8x8[ch];
    80006a2e:	00002c97          	auipc	s9,0x2
    80006a32:	192c8c93          	addi	s9,s9,402 # 80008bc0 <font8x8>
    80006a36:	00024737          	lui	a4,0x24
    80006a3a:	a0070d93          	addi	s11,a4,-1536 # 23a00 <_entry-0x7ffdc600>
        for (int col = 0; col < 8; col++)
    80006a3e:	4d01                	li	s10,0
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006a40:	010004b7          	lui	s1,0x1000
    80006a44:	14fd                	addi	s1,s1,-1
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006a46:	00020897          	auipc	a7,0x20
    80006a4a:	a3288893          	addi	a7,a7,-1486 # 80026478 <fb>
    int off = byte_off % PGSIZE;
    80006a4e:	6805                	lui	a6,0x1
    80006a50:	187d                	addi	a6,a6,-1
            for (int dy = 0; dy < SCALE; dy++)
    80006a52:	6e05                	lui	t3,0x1
    80006a54:	a00e0e1b          	addiw	t3,t3,-1536
        for (int col = 0; col < 8; col++)
    80006a58:	40a1                	li	ra,8
    for (int row = 0; row < 8; row++)
    80006a5a:	6a8d                	lui	s5,0x3
    80006a5c:	800a8a9b          	addiw	s5,s5,-2048
    80006a60:	10000b13          	li	s6,256
    80006a64:	a0f1                	j	80006b30 <virtio_gpu_init+0x380>
        panic("virtio_gpu: FEATURES_OK not set");
    80006a66:	00002517          	auipc	a0,0x2
    80006a6a:	02a50513          	addi	a0,a0,42 # 80008a90 <syscalls+0x570>
    80006a6e:	ffffa097          	auipc	ra,0xffffa
    80006a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>
        panic("virtio_gpu: queue already ready");
    80006a76:	00002517          	auipc	a0,0x2
    80006a7a:	03a50513          	addi	a0,a0,58 # 80008ab0 <syscalls+0x590>
    80006a7e:	ffffa097          	auipc	ra,0xffffa
    80006a82:	ac0080e7          	jalr	-1344(ra) # 8000053e <panic>
        panic("virtio_gpu: queue too small");
    80006a86:	00002517          	auipc	a0,0x2
    80006a8a:	04a50513          	addi	a0,a0,74 # 80008ad0 <syscalls+0x5b0>
    80006a8e:	ffffa097          	auipc	ra,0xffffa
    80006a92:	ab0080e7          	jalr	-1360(ra) # 8000053e <panic>
        panic("virtio_gpu: kalloc failed for queue");
    80006a96:	00002517          	auipc	a0,0x2
    80006a9a:	05a50513          	addi	a0,a0,90 # 80008af0 <syscalls+0x5d0>
    80006a9e:	ffffa097          	auipc	ra,0xffffa
    80006aa2:	aa0080e7          	jalr	-1376(ra) # 8000053e <panic>
            panic("virtio_gpu: kalloc failed for framebuffer");
    80006aa6:	00002517          	auipc	a0,0x2
    80006aaa:	07250513          	addi	a0,a0,114 # 80008b18 <syscalls+0x5f8>
    80006aae:	ffffa097          	auipc	ra,0xffffa
    80006ab2:	a90080e7          	jalr	-1392(ra) # 8000053e <panic>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006ab6:	85fe                	mv	a1,t6
    80006ab8:	831e                	mv	t1,t2
                for (int dx = 0; dx < SCALE; dx++)
    80006aba:	ff05869b          	addiw	a3,a1,-16
    int pg = byte_off / PGSIZE;
    80006abe:	43f6d613          	srai	a2,a3,0x3f
    80006ac2:	0146561b          	srliw	a2,a2,0x14
    80006ac6:	00d607bb          	addw	a5,a2,a3
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006aca:	40c7d71b          	sraiw	a4,a5,0xc
    80006ace:	070e                	slli	a4,a4,0x3
    80006ad0:	9746                	add	a4,a4,a7
    int off = byte_off % PGSIZE;
    80006ad2:	0107f7b3          	and	a5,a5,a6
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006ad6:	9f91                	subw	a5,a5,a2
    *p = color;
    80006ad8:	6310                	ld	a2,0(a4)
    80006ada:	97b2                	add	a5,a5,a2
    80006adc:	c388                	sw	a0,0(a5)
                for (int dx = 0; dx < SCALE; dx++)
    80006ade:	2691                	addiw	a3,a3,4
    80006ae0:	fcd59fe3          	bne	a1,a3,80006abe <virtio_gpu_init+0x30e>
            for (int dy = 0; dy < SCALE; dy++)
    80006ae4:	2803031b          	addiw	t1,t1,640
    80006ae8:	00be05bb          	addw	a1,t3,a1
    80006aec:	fdd317e3          	bne	t1,t4,80006aba <virtio_gpu_init+0x30a>
        for (int col = 0; col < 8; col++)
    80006af0:	2f05                	addiw	t5,t5,1
    80006af2:	2fc1                	addiw	t6,t6,16
    80006af4:	001f0a63          	beq	t5,ra,80006b08 <virtio_gpu_init+0x358>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006af8:	0002c503          	lbu	a0,0(t0)
    80006afc:	01e5553b          	srlw	a0,a0,t5
    80006b00:	8905                	andi	a0,a0,1
    80006b02:	d955                	beqz	a0,80006ab6 <virtio_gpu_init+0x306>
    80006b04:	8526                	mv	a0,s1
    80006b06:	bf45                	j	80006ab6 <virtio_gpu_init+0x306>
    for (int row = 0; row < 8; row++)
    80006b08:	01de0ebb          	addw	t4,t3,t4
    80006b0c:	012e093b          	addw	s2,t3,s2
    80006b10:	2991                	addiw	s3,s3,4
    80006b12:	014a8a3b          	addw	s4,s5,s4
    80006b16:	0285                	addi	t0,t0,1
    80006b18:	01698663          	beq	s3,s6,80006b24 <virtio_gpu_init+0x374>
        for (int i = 0; msg[i]; i++)
    80006b1c:	8fd2                	mv	t6,s4
        for (int col = 0; col < 8; col++)
    80006b1e:	8f6a                	mv	t5,s10
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006b20:	83ca                	mv	t2,s2
    80006b22:	bfd9                	j	80006af8 <virtio_gpu_init+0x348>
        for (int i = 0; msg[i]; i++)
    80006b24:	001c4783          	lbu	a5,1(s8)
    80006b28:	0c05                	addi	s8,s8,1
    80006b2a:	080b8b9b          	addiw	s7,s7,128
    80006b2e:	cb99                	beqz	a5,80006b44 <virtio_gpu_init+0x394>
    const uint8 *rows = font8x8[ch];
    80006b30:	078e                	slli	a5,a5,0x3
    80006b32:	019782b3          	add	t0,a5,s9
    80006b36:	8a5e                	mv	s4,s7
    80006b38:	0e000993          	li	s3,224
    80006b3c:	00023937          	lui	s2,0x23
    80006b40:	8eee                	mv	t4,s11
    80006b42:	bfe9                	j	80006b1c <virtio_gpu_init+0x36c>
    memset(&scanout_req, 0, sizeof(scanout_req));
    80006b44:	0001c497          	auipc	s1,0x1c
    80006b48:	f9c48493          	addi	s1,s1,-100 # 80022ae0 <gq>
    80006b4c:	0001c917          	auipc	s2,0x1c
    80006b50:	07c90913          	addi	s2,s2,124 # 80022bc8 <scanout_req.4>
    80006b54:	03000613          	li	a2,48
    80006b58:	4581                	li	a1,0
    80006b5a:	854a                	mv	a0,s2
    80006b5c:	ffffa097          	auipc	ra,0xffffa
    80006b60:	176080e7          	jalr	374(ra) # 80000cd2 <memset>
    scanout_req.hdr.type = VIRTIO_GPU_CMD_SET_SCANOUT;
    80006b64:	10300793          	li	a5,259
    80006b68:	0ef4a423          	sw	a5,232(s1)
    scanout_req.r.x = 0;
    80006b6c:	1004a023          	sw	zero,256(s1)
    scanout_req.r.y = 0;
    80006b70:	1004a223          	sw	zero,260(s1)
    scanout_req.r.width = SCREEN_W;
    80006b74:	28000793          	li	a5,640
    80006b78:	10f4a423          	sw	a5,264(s1)
    scanout_req.r.height = SCREEN_H;
    80006b7c:	1e000793          	li	a5,480
    80006b80:	10f4a623          	sw	a5,268(s1)
    scanout_req.scanout_id = SCANOUT_ID;
    80006b84:	1004a823          	sw	zero,272(s1)
    scanout_req.resource_id = RESOURCE_ID;
    80006b88:	4785                	li	a5,1
    80006b8a:	10f4aa23          	sw	a5,276(s1)
    gpu_send(&scanout_req, sizeof(scanout_req));
    80006b8e:	03000593          	li	a1,48
    80006b92:	854a                	mv	a0,s2
    80006b94:	00000097          	auipc	ra,0x0
    80006b98:	9ee080e7          	jalr	-1554(ra) # 80006582 <gpu_send>
    gpu_transfer_flush();
    80006b9c:	00000097          	auipc	ra,0x0
    80006ba0:	b5c080e7          	jalr	-1188(ra) # 800066f8 <gpu_transfer_flush>
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
    80006ba4:	00002517          	auipc	a0,0x2
    80006ba8:	fb450513          	addi	a0,a0,-76 # 80008b58 <syscalls+0x638>
    80006bac:	ffffa097          	auipc	ra,0xffffa
    80006bb0:	9dc080e7          	jalr	-1572(ra) # 80000588 <printf>
    80006bb4:	b159                	j	8000683a <virtio_gpu_init+0x8a>

0000000080006bb6 <virtio_gpu_commit>:

// ── Public: flush the kernel fb[] to the display ─────────────────────
// Called by display_daemon.  Sends TRANSFER_TO_HOST_2D + RESOURCE_FLUSH.
void virtio_gpu_commit(void)
{
    80006bb6:	1141                	addi	sp,sp,-16
    80006bb8:	e406                	sd	ra,8(sp)
    80006bba:	e022                	sd	s0,0(sp)
    80006bbc:	0800                	addi	s0,sp,16
    gpu_transfer_flush();
    80006bbe:	00000097          	auipc	ra,0x0
    80006bc2:	b3a080e7          	jalr	-1222(ra) # 800066f8 <gpu_transfer_flush>
}
    80006bc6:	60a2                	ld	ra,8(sp)
    80006bc8:	6402                	ld	s0,0(sp)
    80006bca:	0141                	addi	sp,sp,16
    80006bcc:	8082                	ret

0000000080006bce <display_daemon>:
// Commit period: DISPLAY_DAEMON_TICKS ticks.  xv6's timer fires every
// ~1/10th of a second at QEMU's default rate, giving ~10fps.
#define DISPLAY_DAEMON_TICKS 1

void display_daemon(void)
{
    80006bce:	7179                	addi	sp,sp,-48
    80006bd0:	f406                	sd	ra,40(sp)
    80006bd2:	f022                	sd	s0,32(sp)
    80006bd4:	ec26                	sd	s1,24(sp)
    80006bd6:	e84a                	sd	s2,16(sp)
    80006bd8:	e44e                	sd	s3,8(sp)
    80006bda:	1800                	addi	s0,sp,48
    // The scheduler holds p->lock across swtch into a new process.
    // Release it here, just like forkret does for user processes.
    struct proc *p = myproc();
    80006bdc:	ffffb097          	auipc	ra,0xffffb
    80006be0:	e06080e7          	jalr	-506(ra) # 800019e2 <myproc>
    release(&p->lock);
    80006be4:	ffffa097          	auipc	ra,0xffffa
    80006be8:	0a6080e7          	jalr	166(ra) # 80000c8a <release>

    acquire(&tickslock);
    80006bec:	00011517          	auipc	a0,0x11
    80006bf0:	b1450513          	addi	a0,a0,-1260 # 80017700 <tickslock>
    80006bf4:	ffffa097          	auipc	ra,0xffffa
    80006bf8:	fe2080e7          	jalr	-30(ra) # 80000bd6 <acquire>
    for (;;)
    {
        // Sleep until DISPLAY_DAEMON_TICKS ticks have elapsed.
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006bfc:	00003917          	auipc	s2,0x3
    80006c00:	86490913          	addi	s2,s2,-1948 # 80009460 <ticks>
        while (ticks < deadline)
            sleep(&ticks, &tickslock);
    80006c04:	00011497          	auipc	s1,0x11
    80006c08:	afc48493          	addi	s1,s1,-1284 # 80017700 <tickslock>
    80006c0c:	a839                	j	80006c2a <display_daemon+0x5c>

        release(&tickslock);
    80006c0e:	8526                	mv	a0,s1
    80006c10:	ffffa097          	auipc	ra,0xffffa
    80006c14:	07a080e7          	jalr	122(ra) # 80000c8a <release>
    gpu_transfer_flush();
    80006c18:	00000097          	auipc	ra,0x0
    80006c1c:	ae0080e7          	jalr	-1312(ra) # 800066f8 <gpu_transfer_flush>
        virtio_gpu_commit();
        acquire(&tickslock);
    80006c20:	8526                	mv	a0,s1
    80006c22:	ffffa097          	auipc	ra,0xffffa
    80006c26:	fb4080e7          	jalr	-76(ra) # 80000bd6 <acquire>
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006c2a:	00092783          	lw	a5,0(s2)
    80006c2e:	0017899b          	addiw	s3,a5,1
        while (ticks < deadline)
    80006c32:	fd37fee3          	bgeu	a5,s3,80006c0e <display_daemon+0x40>
            sleep(&ticks, &tickslock);
    80006c36:	85a6                	mv	a1,s1
    80006c38:	854a                	mv	a0,s2
    80006c3a:	ffffb097          	auipc	ra,0xffffb
    80006c3e:	4e8080e7          	jalr	1256(ra) # 80002122 <sleep>
        while (ticks < deadline)
    80006c42:	00092783          	lw	a5,0(s2)
    80006c46:	ff37e8e3          	bltu	a5,s3,80006c36 <display_daemon+0x68>
    80006c4a:	b7d1                	j	80006c0e <display_daemon+0x40>

0000000080006c4c <get_fb_addr>:
    }
}

void*
get_fb_addr(void)
{
    80006c4c:	1141                	addi	sp,sp,-16
    80006c4e:	e422                	sd	s0,8(sp)
    80006c50:	0800                	addi	s0,sp,16
  return (void*)fb;
}
    80006c52:	00020517          	auipc	a0,0x20
    80006c56:	82650513          	addi	a0,a0,-2010 # 80026478 <fb>
    80006c5a:	6422                	ld	s0,8(sp)
    80006c5c:	0141                	addi	sp,sp,16
    80006c5e:	8082                	ret

0000000080006c60 <get_fb_page>:
void*
get_fb_page(int page_index)
{
    80006c60:	1141                	addi	sp,sp,-16
    80006c62:	e422                	sd	s0,8(sp)
    80006c64:	0800                	addi	s0,sp,16
  if (page_index < 0 || page_index >= FB_PAGES) {
    80006c66:	12b00713          	li	a4,299
    80006c6a:	00a76d63          	bltu	a4,a0,80006c84 <get_fb_page+0x24>
    return 0;
  }
  return fb[page_index]; 
    80006c6e:	00351793          	slli	a5,a0,0x3
    80006c72:	00020717          	auipc	a4,0x20
    80006c76:	80670713          	addi	a4,a4,-2042 # 80026478 <fb>
    80006c7a:	97ba                	add	a5,a5,a4
    80006c7c:	6388                	ld	a0,0(a5)
}
    80006c7e:	6422                	ld	s0,8(sp)
    80006c80:	0141                	addi	sp,sp,16
    80006c82:	8082                	ret
    return 0;
    80006c84:	4501                	li	a0,0
    80006c86:	bfe5                	j	80006c7e <get_fb_page+0x1e>

0000000080006c88 <get_entries_from_buf>:


void
get_entries_from_buf(uint64 buf, int n, struct virtio_gpu_mem_entry* entries)
{
    80006c88:	7139                	addi	sp,sp,-64
    80006c8a:	fc06                	sd	ra,56(sp)
    80006c8c:	f822                	sd	s0,48(sp)
    80006c8e:	f426                	sd	s1,40(sp)
    80006c90:	f04a                	sd	s2,32(sp)
    80006c92:	ec4e                	sd	s3,24(sp)
    80006c94:	e852                	sd	s4,16(sp)
    80006c96:	e456                	sd	s5,8(sp)
    80006c98:	e05a                	sd	s6,0(sp)
    80006c9a:	0080                	addi	s0,sp,64
    80006c9c:	892a                	mv	s2,a0
    80006c9e:	8a2e                	mv	s4,a1
    80006ca0:	8b32                	mv	s6,a2
    struct proc *p = myproc();
    80006ca2:	ffffb097          	auipc	ra,0xffffb
    80006ca6:	d40080e7          	jalr	-704(ra) # 800019e2 <myproc>
    for(int i = 0; i < n; i++){
    80006caa:	03405d63          	blez	s4,80006ce4 <get_entries_from_buf+0x5c>
    80006cae:	8aaa                	mv	s5,a0
    80006cb0:	84da                	mv	s1,s6
    80006cb2:	3a7d                	addiw	s4,s4,-1
    80006cb4:	1a02                	slli	s4,s4,0x20
    80006cb6:	020a5a13          	srli	s4,s4,0x20
    80006cba:	0a12                	slli	s4,s4,0x4
    80006cbc:	0b41                	addi	s6,s6,16
    80006cbe:	9a5a                	add	s4,s4,s6
        uint64 pa = walkaddr(p->pagetable, va);
        if(pa == 0){
            panic("get_entries_from_buf: walkaddr failed for va ");
        }
        entries[i].addr = pa;
        entries[i].length = PGSIZE;
    80006cc0:	6985                	lui	s3,0x1
        uint64 pa = walkaddr(p->pagetable, va);
    80006cc2:	85ca                	mv	a1,s2
    80006cc4:	050ab503          	ld	a0,80(s5) # 3050 <_entry-0x7fffcfb0>
    80006cc8:	ffffa097          	auipc	ra,0xffffa
    80006ccc:	3b4080e7          	jalr	948(ra) # 8000107c <walkaddr>
        if(pa == 0){
    80006cd0:	c505                	beqz	a0,80006cf8 <get_entries_from_buf+0x70>
        entries[i].addr = pa;
    80006cd2:	e088                	sd	a0,0(s1)
        entries[i].length = PGSIZE;
    80006cd4:	0134a423          	sw	s3,8(s1)
        entries[i].padding = 0;
    80006cd8:	0004a623          	sw	zero,12(s1)
    for(int i = 0; i < n; i++){
    80006cdc:	994e                	add	s2,s2,s3
    80006cde:	04c1                	addi	s1,s1,16
    80006ce0:	ff4491e3          	bne	s1,s4,80006cc2 <get_entries_from_buf+0x3a>
    }
}
    80006ce4:	70e2                	ld	ra,56(sp)
    80006ce6:	7442                	ld	s0,48(sp)
    80006ce8:	74a2                	ld	s1,40(sp)
    80006cea:	7902                	ld	s2,32(sp)
    80006cec:	69e2                	ld	s3,24(sp)
    80006cee:	6a42                	ld	s4,16(sp)
    80006cf0:	6aa2                	ld	s5,8(sp)
    80006cf2:	6b02                	ld	s6,0(sp)
    80006cf4:	6121                	addi	sp,sp,64
    80006cf6:	8082                	ret
            panic("get_entries_from_buf: walkaddr failed for va ");
    80006cf8:	00002517          	auipc	a0,0x2
    80006cfc:	e9850513          	addi	a0,a0,-360 # 80008b90 <syscalls+0x670>
    80006d00:	ffffa097          	auipc	ra,0xffffa
    80006d04:	83e080e7          	jalr	-1986(ra) # 8000053e <panic>

0000000080006d08 <virtio_gpu_flip>:
uint64
virtio_gpu_flip(uint64 buf)
{
    80006d08:	7179                	addi	sp,sp,-48
    80006d0a:	f406                	sd	ra,40(sp)
    80006d0c:	f022                	sd	s0,32(sp)
    80006d0e:	ec26                	sd	s1,24(sp)
    80006d10:	e84a                	sd	s2,16(sp)
    80006d12:	e44e                	sd	s3,8(sp)
    80006d14:	1800                	addi	s0,sp,48
    80006d16:	84aa                	mv	s1,a0
    memset(&detach, 0, sizeof(detach));
    80006d18:	0001c997          	auipc	s3,0x1c
    80006d1c:	dc898993          	addi	s3,s3,-568 # 80022ae0 <gq>
    80006d20:	0001c917          	auipc	s2,0x1c
    80006d24:	ed890913          	addi	s2,s2,-296 # 80022bf8 <detach.0>
    80006d28:	02000613          	li	a2,32
    80006d2c:	4581                	li	a1,0
    80006d2e:	854a                	mv	a0,s2
    80006d30:	ffffa097          	auipc	ra,0xffffa
    80006d34:	fa2080e7          	jalr	-94(ra) # 80000cd2 <memset>
    detach.hdr.type = VIRTIO_GPU_CMD_RESOURCE_DETACH_BACKING;
    80006d38:	10700793          	li	a5,263
    80006d3c:	10f9ac23          	sw	a5,280(s3)
    detach.resource_id = RESOURCE_ID;
    80006d40:	4785                	li	a5,1
    80006d42:	12f9a823          	sw	a5,304(s3)
    gpu_send(&detach, sizeof(detach));
    80006d46:	02000593          	li	a1,32
    80006d4a:	854a                	mv	a0,s2
    80006d4c:	00000097          	auipc	ra,0x0
    80006d50:	836080e7          	jalr	-1994(ra) # 80006582 <gpu_send>
    static struct virtio_gpu_mem_entry entries[FB_PAGES];
    gpu_cmd_detach();
    
    get_entries_from_buf(buf, FB_PAGES, entries);
    80006d54:	0001c617          	auipc	a2,0x1c
    80006d58:	ec460613          	addi	a2,a2,-316 # 80022c18 <entries.1>
    80006d5c:	12c00593          	li	a1,300
    80006d60:	8526                	mv	a0,s1
    80006d62:	00000097          	auipc	ra,0x0
    80006d66:	f26080e7          	jalr	-218(ra) # 80006c88 <get_entries_from_buf>
    
    gpu_cmd_attach(entries, FB_PAGES);
    80006d6a:	12c00593          	li	a1,300
    80006d6e:	0001c517          	auipc	a0,0x1c
    80006d72:	eaa50513          	addi	a0,a0,-342 # 80022c18 <entries.1>
    80006d76:	00000097          	auipc	ra,0x0
    80006d7a:	918080e7          	jalr	-1768(ra) # 8000668e <gpu_cmd_attach>
            
    return 0;
}
    80006d7e:	4501                	li	a0,0
    80006d80:	70a2                	ld	ra,40(sp)
    80006d82:	7402                	ld	s0,32(sp)
    80006d84:	64e2                	ld	s1,24(sp)
    80006d86:	6942                	ld	s2,16(sp)
    80006d88:	69a2                	ld	s3,8(sp)
    80006d8a:	6145                	addi	sp,sp,48
    80006d8c:	8082                	ret
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
