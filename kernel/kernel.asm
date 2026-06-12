
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	40013103          	ld	sp,1024(sp) # 80009400 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	40e70713          	addi	a4,a4,1038 # 80009460 <timer_scratch>
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
    80000068:	e6c78793          	addi	a5,a5,-404 # 80005ed0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd7a37>
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
    8000018e:	41650513          	addi	a0,a0,1046 # 800115a0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	40648493          	addi	s1,s1,1030 # 800115a0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	49690913          	addi	s2,s2,1174 # 80011638 <cons+0x98>
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
    8000022a:	37a50513          	addi	a0,a0,890 # 800115a0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	36450513          	addi	a0,a0,868 # 800115a0 <cons>
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
    80000276:	3cf72323          	sw	a5,966(a4) # 80011638 <cons+0x98>
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
    800002d0:	2d450513          	addi	a0,a0,724 # 800115a0 <cons>
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
    800002fe:	2a650513          	addi	a0,a0,678 # 800115a0 <cons>
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
    80000322:	28270713          	addi	a4,a4,642 # 800115a0 <cons>
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
    8000034c:	25878793          	addi	a5,a5,600 # 800115a0 <cons>
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
    8000037a:	2c27a783          	lw	a5,706(a5) # 80011638 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	21670713          	addi	a4,a4,534 # 800115a0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	20648493          	addi	s1,s1,518 # 800115a0 <cons>
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
    800003da:	1ca70713          	addi	a4,a4,458 # 800115a0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	24f72a23          	sw	a5,596(a4) # 80011640 <cons+0xa0>
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
    80000416:	18e78793          	addi	a5,a5,398 # 800115a0 <cons>
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
    8000043a:	20c7a323          	sw	a2,518(a5) # 8001163c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	1fa50513          	addi	a0,a0,506 # 80011638 <cons+0x98>
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
    80000464:	14050513          	addi	a0,a0,320 # 800115a0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	4c078793          	addi	a5,a5,1216 # 80021938 <devsw>
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
    8000054e:	1007ab23          	sw	zero,278(a5) # 80011660 <pr+0x18>
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
    80000570:	df450513          	addi	a0,a0,-524 # 80008360 <digits+0x320>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	eaf72123          	sw	a5,-350(a4) # 80009420 <panicked>
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
    800005be:	0a6dad83          	lw	s11,166(s11) # 80011660 <pr+0x18>
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
    800005fc:	05050513          	addi	a0,a0,80 # 80011648 <pr>
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
    8000075a:	ef250513          	addi	a0,a0,-270 # 80011648 <pr>
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
    80000776:	ed648493          	addi	s1,s1,-298 # 80011648 <pr>
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
    800007d6:	e9650513          	addi	a0,a0,-362 # 80011668 <uart_tx_lock>
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
    80000802:	c227a783          	lw	a5,-990(a5) # 80009420 <panicked>
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
    8000083a:	bf27b783          	ld	a5,-1038(a5) # 80009428 <uart_tx_r>
    8000083e:	00009717          	auipc	a4,0x9
    80000842:	bf273703          	ld	a4,-1038(a4) # 80009430 <uart_tx_w>
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
    80000864:	e08a0a13          	addi	s4,s4,-504 # 80011668 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00009497          	auipc	s1,0x9
    8000086c:	bc048493          	addi	s1,s1,-1088 # 80009428 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00009997          	auipc	s3,0x9
    80000874:	bc098993          	addi	s3,s3,-1088 # 80009430 <uart_tx_w>
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
    800008d2:	d9a50513          	addi	a0,a0,-614 # 80011668 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00009797          	auipc	a5,0x9
    800008e2:	b427a783          	lw	a5,-1214(a5) # 80009420 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00009717          	auipc	a4,0x9
    800008ec:	b4873703          	ld	a4,-1208(a4) # 80009430 <uart_tx_w>
    800008f0:	00009797          	auipc	a5,0x9
    800008f4:	b387b783          	ld	a5,-1224(a5) # 80009428 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00011997          	auipc	s3,0x11
    80000900:	d6c98993          	addi	s3,s3,-660 # 80011668 <uart_tx_lock>
    80000904:	00009497          	auipc	s1,0x9
    80000908:	b2448493          	addi	s1,s1,-1244 # 80009428 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00009917          	auipc	s2,0x9
    80000910:	b2490913          	addi	s2,s2,-1244 # 80009430 <uart_tx_w>
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
    80000936:	d3648493          	addi	s1,s1,-714 # 80011668 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00009797          	auipc	a5,0x9
    8000094a:	aee7b523          	sd	a4,-1302(a5) # 80009430 <uart_tx_w>
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
    800009c0:	cac48493          	addi	s1,s1,-852 # 80011668 <uart_tx_lock>
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
    80000a02:	3ca78793          	addi	a5,a5,970 # 80026dc8 <end>
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
    80000a22:	c8290913          	addi	s2,s2,-894 # 800116a0 <kmem>
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
    80000abe:	be650513          	addi	a0,a0,-1050 # 800116a0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00026517          	auipc	a0,0x26
    80000ad2:	2fa50513          	addi	a0,a0,762 # 80026dc8 <end>
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
    80000af4:	bb048493          	addi	s1,s1,-1104 # 800116a0 <kmem>
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
    80000b0c:	b9850513          	addi	a0,a0,-1128 # 800116a0 <kmem>
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
    80000b38:	b6c50513          	addi	a0,a0,-1172 # 800116a0 <kmem>
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
    80000e8c:	5b070713          	addi	a4,a4,1456 # 80009438 <started>
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
    80000ec2:	9a4080e7          	jalr	-1628(ra) # 80002862 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	04a080e7          	jalr	74(ra) # 80005f10 <plicinithart>
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
    80000eea:	47a50513          	addi	a0,a0,1146 # 80008360 <digits+0x320>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	45a50513          	addi	a0,a0,1114 # 80008360 <digits+0x320>
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
    80000f3a:	904080e7          	jalr	-1788(ra) # 8000283a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	924080e7          	jalr	-1756(ra) # 80002862 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	fb4080e7          	jalr	-76(ra) # 80005efa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	fc2080e7          	jalr	-62(ra) # 80005f10 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	16a080e7          	jalr	362(ra) # 800030c0 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	80e080e7          	jalr	-2034(ra) # 8000376c <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	7ac080e7          	jalr	1964(ra) # 80004712 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	0aa080e7          	jalr	170(ra) # 80006018 <virtio_disk_init>
    virtio_gpu_init();  // virtio GPU display window
    80000f76:	00006097          	auipc	ra,0x6
    80000f7a:	81a080e7          	jalr	-2022(ra) # 80006790 <virtio_gpu_init>
    userinit();      // first user process
    80000f7e:	00001097          	auipc	ra,0x1
    80000f82:	d6e080e7          	jalr	-658(ra) # 80001cec <userinit>
    kproc_create(display_daemon, "displaydaemon"); // GPU auto-commit daemon
    80000f86:	00007597          	auipc	a1,0x7
    80000f8a:	13258593          	addi	a1,a1,306 # 800080b8 <digits+0x78>
    80000f8e:	00006517          	auipc	a0,0x6
    80000f92:	c2050513          	addi	a0,a0,-992 # 80006bae <display_daemon>
    80000f96:	00001097          	auipc	ra,0x1
    80000f9a:	dd8080e7          	jalr	-552(ra) # 80001d6e <kproc_create>
    __sync_synchronize();
    80000f9e:	0ff0000f          	fence
    started = 1;
    80000fa2:	4785                	li	a5,1
    80000fa4:	00008717          	auipc	a4,0x8
    80000fa8:	48f72a23          	sw	a5,1172(a4) # 80009438 <started>
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
    80000fbc:	4887b783          	ld	a5,1160(a5) # 80009440 <kernel_pagetable>
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
    8000128e:	1aa7bb23          	sd	a0,438(a5) # 80009440 <kernel_pagetable>
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
    80001886:	26e48493          	addi	s1,s1,622 # 80011af0 <proc>
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
    800018a0:	e54a0a13          	addi	s4,s4,-428 # 800176f0 <tickslock>
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
    80001922:	da250513          	addi	a0,a0,-606 # 800116c0 <pid_lock>
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	220080e7          	jalr	544(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000192e:	00007597          	auipc	a1,0x7
    80001932:	8ca58593          	addi	a1,a1,-1846 # 800081f8 <digits+0x1b8>
    80001936:	00010517          	auipc	a0,0x10
    8000193a:	da250513          	addi	a0,a0,-606 # 800116d8 <wait_lock>
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001946:	00010497          	auipc	s1,0x10
    8000194a:	1aa48493          	addi	s1,s1,426 # 80011af0 <proc>
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
    8000196c:	d8898993          	addi	s3,s3,-632 # 800176f0 <tickslock>
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
    800019d6:	d1e50513          	addi	a0,a0,-738 # 800116f0 <cpus>
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
    800019fe:	cc670713          	addi	a4,a4,-826 # 800116c0 <pid_lock>
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
    80001a36:	97e7a783          	lw	a5,-1666(a5) # 800093b0 <first.1>
    80001a3a:	eb89                	bnez	a5,80001a4c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a3c:	00001097          	auipc	ra,0x1
    80001a40:	e3e080e7          	jalr	-450(ra) # 8000287a <usertrapret>
}
    80001a44:	60a2                	ld	ra,8(sp)
    80001a46:	6402                	ld	s0,0(sp)
    80001a48:	0141                	addi	sp,sp,16
    80001a4a:	8082                	ret
    first = 0;
    80001a4c:	00008797          	auipc	a5,0x8
    80001a50:	9607a223          	sw	zero,-1692(a5) # 800093b0 <first.1>
    fsinit(ROOTDEV);
    80001a54:	4505                	li	a0,1
    80001a56:	00002097          	auipc	ra,0x2
    80001a5a:	c96080e7          	jalr	-874(ra) # 800036ec <fsinit>
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
    80001a70:	c5490913          	addi	s2,s2,-940 # 800116c0 <pid_lock>
    80001a74:	854a                	mv	a0,s2
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	160080e7          	jalr	352(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a7e:	00008797          	auipc	a5,0x8
    80001a82:	93678793          	addi	a5,a5,-1738 # 800093b4 <nextpid>
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
    80001c2e:	ec648493          	addi	s1,s1,-314 # 80011af0 <proc>
    80001c32:	00016917          	auipc	s2,0x16
    80001c36:	abe90913          	addi	s2,s2,-1346 # 800176f0 <tickslock>
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
    80001d04:	74a7b423          	sd	a0,1864(a5) # 80009448 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d08:	03400613          	li	a2,52
    80001d0c:	00007597          	auipc	a1,0x7
    80001d10:	6b458593          	addi	a1,a1,1716 # 800093c0 <initcode>
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
    80001d4e:	3c4080e7          	jalr	964(ra) # 8000410e <namei>
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
    80001ee4:	8c4080e7          	jalr	-1852(ra) # 800047a4 <filedup>
    80001ee8:	00a93023          	sd	a0,0(s2)
    80001eec:	b7e5                	j	80001ed4 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001eee:	150ab503          	ld	a0,336(s5)
    80001ef2:	00002097          	auipc	ra,0x2
    80001ef6:	a38080e7          	jalr	-1480(ra) # 8000392a <idup>
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
    80001f22:	7ba48493          	addi	s1,s1,1978 # 800116d8 <wait_lock>
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
    80001f90:	73470713          	addi	a4,a4,1844 # 800116c0 <pid_lock>
    80001f94:	9756                	add	a4,a4,s5
    80001f96:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f9a:	0000f717          	auipc	a4,0xf
    80001f9e:	75e70713          	addi	a4,a4,1886 # 800116f8 <cpus+0x8>
    80001fa2:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001fa4:	498d                	li	s3,3
        p->state = RUNNING;
    80001fa6:	4b11                	li	s6,4
        c->proc = p;
    80001fa8:	079e                	slli	a5,a5,0x7
    80001faa:	0000fa17          	auipc	s4,0xf
    80001fae:	716a0a13          	addi	s4,s4,1814 # 800116c0 <pid_lock>
    80001fb2:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	00015917          	auipc	s2,0x15
    80001fb8:	73c90913          	addi	s2,s2,1852 # 800176f0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fc0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc4:	10079073          	csrw	sstatus,a5
    80001fc8:	00010497          	auipc	s1,0x10
    80001fcc:	b2848493          	addi	s1,s1,-1240 # 80011af0 <proc>
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
    80002006:	7ce080e7          	jalr	1998(ra) # 800027d0 <swtch>
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
    8000203c:	68870713          	addi	a4,a4,1672 # 800116c0 <pid_lock>
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
    80002062:	66290913          	addi	s2,s2,1634 # 800116c0 <pid_lock>
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	97ca                	add	a5,a5,s2
    8000206c:	0ac7a983          	lw	s3,172(a5)
    80002070:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002072:	2781                	sext.w	a5,a5
    80002074:	079e                	slli	a5,a5,0x7
    80002076:	0000f597          	auipc	a1,0xf
    8000207a:	68258593          	addi	a1,a1,1666 # 800116f8 <cpus+0x8>
    8000207e:	95be                	add	a1,a1,a5
    80002080:	06048513          	addi	a0,s1,96
    80002084:	00000097          	auipc	ra,0x0
    80002088:	74c080e7          	jalr	1868(ra) # 800027d0 <swtch>
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
    8000219e:	95648493          	addi	s1,s1,-1706 # 80011af0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021a2:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021a4:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021a6:	00015917          	auipc	s2,0x15
    800021aa:	54a90913          	addi	s2,s2,1354 # 800176f0 <tickslock>
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
    80002212:	8e248493          	addi	s1,s1,-1822 # 80011af0 <proc>
      pp->parent = initproc;
    80002216:	00007a17          	auipc	s4,0x7
    8000221a:	232a0a13          	addi	s4,s4,562 # 80009448 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000221e:	00015997          	auipc	s3,0x15
    80002222:	4d298993          	addi	s3,s3,1234 # 800176f0 <tickslock>
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
    80002276:	1d67b783          	ld	a5,470(a5) # 80009448 <initproc>
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
    8000229a:	560080e7          	jalr	1376(ra) # 800047f6 <fileclose>
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
    800022b2:	07c080e7          	jalr	124(ra) # 8000432a <begin_op>
  iput(p->cwd);
    800022b6:	1509b503          	ld	a0,336(s3)
    800022ba:	00002097          	auipc	ra,0x2
    800022be:	868080e7          	jalr	-1944(ra) # 80003b22 <iput>
  end_op();
    800022c2:	00002097          	auipc	ra,0x2
    800022c6:	0e8080e7          	jalr	232(ra) # 800043aa <end_op>
  p->cwd = 0;
    800022ca:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022ce:	0000f497          	auipc	s1,0xf
    800022d2:	40a48493          	addi	s1,s1,1034 # 800116d8 <wait_lock>
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
    80002340:	7b448493          	addi	s1,s1,1972 # 80011af0 <proc>
    80002344:	00015997          	auipc	s3,0x15
    80002348:	3ac98993          	addi	s3,s3,940 # 800176f0 <tickslock>
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
    80002424:	2b850513          	addi	a0,a0,696 # 800116d8 <wait_lock>
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
    8000243a:	2ba98993          	addi	s3,s3,698 # 800176f0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000243e:	0000fc17          	auipc	s8,0xf
    80002442:	29ac0c13          	addi	s8,s8,666 # 800116d8 <wait_lock>
    havekids = 0;
    80002446:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002448:	0000f497          	auipc	s1,0xf
    8000244c:	6a848493          	addi	s1,s1,1704 # 80011af0 <proc>
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
    8000248a:	25250513          	addi	a0,a0,594 # 800116d8 <wait_lock>
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
    800024a6:	23650513          	addi	a0,a0,566 # 800116d8 <wait_lock>
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
    800024f4:	1e850513          	addi	a0,a0,488 # 800116d8 <wait_lock>
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
    800025f0:	d7450513          	addi	a0,a0,-652 # 80008360 <digits+0x320>
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	f94080e7          	jalr	-108(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025fc:	0000f497          	auipc	s1,0xf
    80002600:	64c48493          	addi	s1,s1,1612 # 80011c48 <proc+0x158>
    80002604:	00015917          	auipc	s2,0x15
    80002608:	24490913          	addi	s2,s2,580 # 80017848 <bcache+0x140>
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
    80002622:	d42a0a13          	addi	s4,s4,-702 # 80008360 <digits+0x320>
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
    80002694:	0080                	addi	s0,sp,64
    80002696:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    80002698:	fffff097          	auipc	ra,0xfffff
    8000269c:	34a080e7          	jalr	842(ra) # 800019e2 <myproc>
    800026a0:	892a                	mv	s2,a0
  uint64 va = (uint64)addr;
  // uint64 fb_pa = (uint64)get_fb_addr();
  if(va == 0){
    800026a2:	020a8463          	beqz	s5,800026ca <map_display+0x46>
    printf("line 714\n");
    va = PGROUNDUP(p->sz);
  }
  if (va % PGSIZE != 0) {
    800026a6:	034a9793          	slli	a5,s5,0x34
    800026aa:	e3a9                	bnez	a5,800026ec <map_display+0x68>
    printf("line 718\n");
    return (void*)-1; 
  }
  printf("line 721, va: %p\n", va);
    800026ac:	85d6                	mv	a1,s5
    800026ae:	00006517          	auipc	a0,0x6
    800026b2:	c5250513          	addi	a0,a0,-942 # 80008300 <digits+0x2c0>
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	ed2080e7          	jalr	-302(ra) # 80000588 <printf>
  for(int i = 0; i < GPU_FB_PAGES; i++){
    800026be:	0012c9b7          	lui	s3,0x12c
    800026c2:	99d6                	add	s3,s3,s5
  printf("line 721, va: %p\n", va);
    800026c4:	84d6                	mv	s1,s5
  for(int i = 0; i < GPU_FB_PAGES; i++){
    800026c6:	6a05                	lui	s4,0x1
    800026c8:	a83d                	j	80002706 <map_display+0x82>
    printf("line 714\n");
    800026ca:	00006517          	auipc	a0,0x6
    800026ce:	c1650513          	addi	a0,a0,-1002 # 800082e0 <digits+0x2a0>
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	eb6080e7          	jalr	-330(ra) # 80000588 <printf>
    va = PGROUNDUP(p->sz);
    800026da:	04893a83          	ld	s5,72(s2)
    800026de:	6785                	lui	a5,0x1
    800026e0:	17fd                	addi	a5,a5,-1
    800026e2:	9abe                	add	s5,s5,a5
    800026e4:	77fd                	lui	a5,0xfffff
    800026e6:	00fafab3          	and	s5,s5,a5
    800026ea:	bf75                	j	800026a6 <map_display+0x22>
    printf("line 718\n");
    800026ec:	00006517          	auipc	a0,0x6
    800026f0:	c0450513          	addi	a0,a0,-1020 # 800082f0 <digits+0x2b0>
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	e94080e7          	jalr	-364(ra) # 80000588 <printf>
    return (void*)-1; 
    800026fc:	557d                	li	a0,-1
    800026fe:	a00d                	j	80002720 <map_display+0x9c>
  for(int i = 0; i < GPU_FB_PAGES; i++){
    80002700:	94d2                	add	s1,s1,s4
    80002702:	02998863          	beq	s3,s1,80002732 <map_display+0xae>
    pte_t *pte = walk(p->pagetable, va + (i * PGSIZE), 0);
    80002706:	4601                	li	a2,0
    80002708:	85a6                	mv	a1,s1
    8000270a:	05093503          	ld	a0,80(s2)
    8000270e:	fffff097          	auipc	ra,0xfffff
    80002712:	8c8080e7          	jalr	-1848(ra) # 80000fd6 <walk>
    if(pte != 0 && (*pte & PTE_V) != 0){
    80002716:	d56d                	beqz	a0,80002700 <map_display+0x7c>
    80002718:	611c                	ld	a5,0(a0)
    8000271a:	8b85                	andi	a5,a5,1
    8000271c:	d3f5                	beqz	a5,80002700 <map_display+0x7c>
      return (void*)-1;
    8000271e:	557d                	li	a0,-1
  }
  else{
    printf("line 753\n");
    return (void*)-1;
  }
    80002720:	70e2                	ld	ra,56(sp)
    80002722:	7442                	ld	s0,48(sp)
    80002724:	74a2                	ld	s1,40(sp)
    80002726:	7902                	ld	s2,32(sp)
    80002728:	69e2                	ld	s3,24(sp)
    8000272a:	6a42                	ld	s4,16(sp)
    8000272c:	6aa2                	ld	s5,8(sp)
    8000272e:	6121                	addi	sp,sp,64
    80002730:	8082                	ret
  printf("line 728\n");
    80002732:	00006517          	auipc	a0,0x6
    80002736:	be650513          	addi	a0,a0,-1050 # 80008318 <digits+0x2d8>
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	e4e080e7          	jalr	-434(ra) # 80000588 <printf>
    80002742:	89d6                	mv	s3,s5
  for(int i = 0; i < GPU_FB_PAGES; i++) {
    80002744:	4481                	li	s1,0
    80002746:	12c00a13          	li	s4,300
    uint64 current_pa = (uint64)get_fb_page(i); 
    8000274a:	8526                	mv	a0,s1
    8000274c:	00004097          	auipc	ra,0x4
    80002750:	4f4080e7          	jalr	1268(ra) # 80006c40 <get_fb_page>
    80002754:	86aa                	mv	a3,a0
    if (current_pa == 0) {
    80002756:	c931                	beqz	a0,800027aa <map_display+0x126>
    if (mappages(p->pagetable, current_va, PGSIZE, current_pa, PTE_U|PTE_R|PTE_W) != 0) {
    80002758:	4759                	li	a4,22
    8000275a:	6605                	lui	a2,0x1
    8000275c:	85ce                	mv	a1,s3
    8000275e:	05093503          	ld	a0,80(s2)
    80002762:	fffff097          	auipc	ra,0xfffff
    80002766:	95c080e7          	jalr	-1700(ra) # 800010be <mappages>
    8000276a:	e121                	bnez	a0,800027aa <map_display+0x126>
  for(int i = 0; i < GPU_FB_PAGES; i++) {
    8000276c:	2485                	addiw	s1,s1,1
    8000276e:	6785                	lui	a5,0x1
    80002770:	99be                	add	s3,s3,a5
    80002772:	fd449ce3          	bne	s1,s4,8000274a <map_display+0xc6>
  printf("line 743, suc: %d\n", suc);
    80002776:	4581                	li	a1,0
    80002778:	00006517          	auipc	a0,0x6
    8000277c:	bb050513          	addi	a0,a0,-1104 # 80008328 <digits+0x2e8>
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	e08080e7          	jalr	-504(ra) # 80000588 <printf>
    printf("line 748, va: %p\n", va);
    80002788:	85d6                	mv	a1,s5
    8000278a:	00006517          	auipc	a0,0x6
    8000278e:	bb650513          	addi	a0,a0,-1098 # 80008340 <digits+0x300>
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	df6080e7          	jalr	-522(ra) # 80000588 <printf>
    myproc()->va_loc = va;
    8000279a:	fffff097          	auipc	ra,0xfffff
    8000279e:	248080e7          	jalr	584(ra) # 800019e2 <myproc>
    800027a2:	17553423          	sd	s5,360(a0)
    return (void*)va;
    800027a6:	8556                	mv	a0,s5
    800027a8:	bfa5                	j	80002720 <map_display+0x9c>
  printf("line 743, suc: %d\n", suc);
    800027aa:	55fd                	li	a1,-1
    800027ac:	00006517          	auipc	a0,0x6
    800027b0:	b7c50513          	addi	a0,a0,-1156 # 80008328 <digits+0x2e8>
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	dd4080e7          	jalr	-556(ra) # 80000588 <printf>
    printf("line 753\n");
    800027bc:	00006517          	auipc	a0,0x6
    800027c0:	b9c50513          	addi	a0,a0,-1124 # 80008358 <digits+0x318>
    800027c4:	ffffe097          	auipc	ra,0xffffe
    800027c8:	dc4080e7          	jalr	-572(ra) # 80000588 <printf>
    return (void*)-1;
    800027cc:	557d                	li	a0,-1
    800027ce:	bf89                	j	80002720 <map_display+0x9c>

00000000800027d0 <swtch>:
    800027d0:	00153023          	sd	ra,0(a0)
    800027d4:	00253423          	sd	sp,8(a0)
    800027d8:	e900                	sd	s0,16(a0)
    800027da:	ed04                	sd	s1,24(a0)
    800027dc:	03253023          	sd	s2,32(a0)
    800027e0:	03353423          	sd	s3,40(a0)
    800027e4:	03453823          	sd	s4,48(a0)
    800027e8:	03553c23          	sd	s5,56(a0)
    800027ec:	05653023          	sd	s6,64(a0)
    800027f0:	05753423          	sd	s7,72(a0)
    800027f4:	05853823          	sd	s8,80(a0)
    800027f8:	05953c23          	sd	s9,88(a0)
    800027fc:	07a53023          	sd	s10,96(a0)
    80002800:	07b53423          	sd	s11,104(a0)
    80002804:	0005b083          	ld	ra,0(a1)
    80002808:	0085b103          	ld	sp,8(a1)
    8000280c:	6980                	ld	s0,16(a1)
    8000280e:	6d84                	ld	s1,24(a1)
    80002810:	0205b903          	ld	s2,32(a1)
    80002814:	0285b983          	ld	s3,40(a1)
    80002818:	0305ba03          	ld	s4,48(a1)
    8000281c:	0385ba83          	ld	s5,56(a1)
    80002820:	0405bb03          	ld	s6,64(a1)
    80002824:	0485bb83          	ld	s7,72(a1)
    80002828:	0505bc03          	ld	s8,80(a1)
    8000282c:	0585bc83          	ld	s9,88(a1)
    80002830:	0605bd03          	ld	s10,96(a1)
    80002834:	0685bd83          	ld	s11,104(a1)
    80002838:	8082                	ret

000000008000283a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000283a:	1141                	addi	sp,sp,-16
    8000283c:	e406                	sd	ra,8(sp)
    8000283e:	e022                	sd	s0,0(sp)
    80002840:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002842:	00006597          	auipc	a1,0x6
    80002846:	b8658593          	addi	a1,a1,-1146 # 800083c8 <states.0+0x30>
    8000284a:	00015517          	auipc	a0,0x15
    8000284e:	ea650513          	addi	a0,a0,-346 # 800176f0 <tickslock>
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	2f4080e7          	jalr	756(ra) # 80000b46 <initlock>
}
    8000285a:	60a2                	ld	ra,8(sp)
    8000285c:	6402                	ld	s0,0(sp)
    8000285e:	0141                	addi	sp,sp,16
    80002860:	8082                	ret

0000000080002862 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002862:	1141                	addi	sp,sp,-16
    80002864:	e422                	sd	s0,8(sp)
    80002866:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002868:	00003797          	auipc	a5,0x3
    8000286c:	5d878793          	addi	a5,a5,1496 # 80005e40 <kernelvec>
    80002870:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002874:	6422                	ld	s0,8(sp)
    80002876:	0141                	addi	sp,sp,16
    80002878:	8082                	ret

000000008000287a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000287a:	1141                	addi	sp,sp,-16
    8000287c:	e406                	sd	ra,8(sp)
    8000287e:	e022                	sd	s0,0(sp)
    80002880:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002882:	fffff097          	auipc	ra,0xfffff
    80002886:	160080e7          	jalr	352(ra) # 800019e2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000288e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002890:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002894:	00004617          	auipc	a2,0x4
    80002898:	76c60613          	addi	a2,a2,1900 # 80007000 <_trampoline>
    8000289c:	00004697          	auipc	a3,0x4
    800028a0:	76468693          	addi	a3,a3,1892 # 80007000 <_trampoline>
    800028a4:	8e91                	sub	a3,a3,a2
    800028a6:	040007b7          	lui	a5,0x4000
    800028aa:	17fd                	addi	a5,a5,-1
    800028ac:	07b2                	slli	a5,a5,0xc
    800028ae:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028b0:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028b4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028b6:	180026f3          	csrr	a3,satp
    800028ba:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028bc:	6d38                	ld	a4,88(a0)
    800028be:	6134                	ld	a3,64(a0)
    800028c0:	6585                	lui	a1,0x1
    800028c2:	96ae                	add	a3,a3,a1
    800028c4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028c6:	6d38                	ld	a4,88(a0)
    800028c8:	00000697          	auipc	a3,0x0
    800028cc:	13068693          	addi	a3,a3,304 # 800029f8 <usertrap>
    800028d0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028d2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028d4:	8692                	mv	a3,tp
    800028d6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028dc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028e0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028e8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ea:	6f18                	ld	a4,24(a4)
    800028ec:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028f0:	6928                	ld	a0,80(a0)
    800028f2:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028f4:	00004717          	auipc	a4,0x4
    800028f8:	7a870713          	addi	a4,a4,1960 # 8000709c <userret>
    800028fc:	8f11                	sub	a4,a4,a2
    800028fe:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002900:	577d                	li	a4,-1
    80002902:	177e                	slli	a4,a4,0x3f
    80002904:	8d59                	or	a0,a0,a4
    80002906:	9782                	jalr	a5
}
    80002908:	60a2                	ld	ra,8(sp)
    8000290a:	6402                	ld	s0,0(sp)
    8000290c:	0141                	addi	sp,sp,16
    8000290e:	8082                	ret

0000000080002910 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002910:	1101                	addi	sp,sp,-32
    80002912:	ec06                	sd	ra,24(sp)
    80002914:	e822                	sd	s0,16(sp)
    80002916:	e426                	sd	s1,8(sp)
    80002918:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000291a:	00015497          	auipc	s1,0x15
    8000291e:	dd648493          	addi	s1,s1,-554 # 800176f0 <tickslock>
    80002922:	8526                	mv	a0,s1
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	2b2080e7          	jalr	690(ra) # 80000bd6 <acquire>
  ticks++;
    8000292c:	00007517          	auipc	a0,0x7
    80002930:	b2450513          	addi	a0,a0,-1244 # 80009450 <ticks>
    80002934:	411c                	lw	a5,0(a0)
    80002936:	2785                	addiw	a5,a5,1
    80002938:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000293a:	00000097          	auipc	ra,0x0
    8000293e:	84c080e7          	jalr	-1972(ra) # 80002186 <wakeup>
  release(&tickslock);
    80002942:	8526                	mv	a0,s1
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	346080e7          	jalr	838(ra) # 80000c8a <release>
}
    8000294c:	60e2                	ld	ra,24(sp)
    8000294e:	6442                	ld	s0,16(sp)
    80002950:	64a2                	ld	s1,8(sp)
    80002952:	6105                	addi	sp,sp,32
    80002954:	8082                	ret

0000000080002956 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002956:	1101                	addi	sp,sp,-32
    80002958:	ec06                	sd	ra,24(sp)
    8000295a:	e822                	sd	s0,16(sp)
    8000295c:	e426                	sd	s1,8(sp)
    8000295e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002960:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002964:	00074d63          	bltz	a4,8000297e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002968:	57fd                	li	a5,-1
    8000296a:	17fe                	slli	a5,a5,0x3f
    8000296c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000296e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002970:	06f70363          	beq	a4,a5,800029d6 <devintr+0x80>
  }
}
    80002974:	60e2                	ld	ra,24(sp)
    80002976:	6442                	ld	s0,16(sp)
    80002978:	64a2                	ld	s1,8(sp)
    8000297a:	6105                	addi	sp,sp,32
    8000297c:	8082                	ret
     (scause & 0xff) == 9){
    8000297e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002982:	46a5                	li	a3,9
    80002984:	fed792e3          	bne	a5,a3,80002968 <devintr+0x12>
    int irq = plic_claim();
    80002988:	00003097          	auipc	ra,0x3
    8000298c:	5c0080e7          	jalr	1472(ra) # 80005f48 <plic_claim>
    80002990:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002992:	47a9                	li	a5,10
    80002994:	02f50763          	beq	a0,a5,800029c2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002998:	4785                	li	a5,1
    8000299a:	02f50963          	beq	a0,a5,800029cc <devintr+0x76>
    return 1;
    8000299e:	4505                	li	a0,1
    } else if(irq){
    800029a0:	d8f1                	beqz	s1,80002974 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029a2:	85a6                	mv	a1,s1
    800029a4:	00006517          	auipc	a0,0x6
    800029a8:	a2c50513          	addi	a0,a0,-1492 # 800083d0 <states.0+0x38>
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	bdc080e7          	jalr	-1060(ra) # 80000588 <printf>
      plic_complete(irq);
    800029b4:	8526                	mv	a0,s1
    800029b6:	00003097          	auipc	ra,0x3
    800029ba:	5b6080e7          	jalr	1462(ra) # 80005f6c <plic_complete>
    return 1;
    800029be:	4505                	li	a0,1
    800029c0:	bf55                	j	80002974 <devintr+0x1e>
      uartintr();
    800029c2:	ffffe097          	auipc	ra,0xffffe
    800029c6:	fd8080e7          	jalr	-40(ra) # 8000099a <uartintr>
    800029ca:	b7ed                	j	800029b4 <devintr+0x5e>
      virtio_disk_intr();
    800029cc:	00004097          	auipc	ra,0x4
    800029d0:	a6c080e7          	jalr	-1428(ra) # 80006438 <virtio_disk_intr>
    800029d4:	b7c5                	j	800029b4 <devintr+0x5e>
    if(cpuid() == 0){
    800029d6:	fffff097          	auipc	ra,0xfffff
    800029da:	fe0080e7          	jalr	-32(ra) # 800019b6 <cpuid>
    800029de:	c901                	beqz	a0,800029ee <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029e0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029e4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029e6:	14479073          	csrw	sip,a5
    return 2;
    800029ea:	4509                	li	a0,2
    800029ec:	b761                	j	80002974 <devintr+0x1e>
      clockintr();
    800029ee:	00000097          	auipc	ra,0x0
    800029f2:	f22080e7          	jalr	-222(ra) # 80002910 <clockintr>
    800029f6:	b7ed                	j	800029e0 <devintr+0x8a>

00000000800029f8 <usertrap>:
{
    800029f8:	1101                	addi	sp,sp,-32
    800029fa:	ec06                	sd	ra,24(sp)
    800029fc:	e822                	sd	s0,16(sp)
    800029fe:	e426                	sd	s1,8(sp)
    80002a00:	e04a                	sd	s2,0(sp)
    80002a02:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a04:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a08:	1007f793          	andi	a5,a5,256
    80002a0c:	e3b1                	bnez	a5,80002a50 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a0e:	00003797          	auipc	a5,0x3
    80002a12:	43278793          	addi	a5,a5,1074 # 80005e40 <kernelvec>
    80002a16:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	fc8080e7          	jalr	-56(ra) # 800019e2 <myproc>
    80002a22:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a24:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a26:	14102773          	csrr	a4,sepc
    80002a2a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a2c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a30:	47a1                	li	a5,8
    80002a32:	02f70763          	beq	a4,a5,80002a60 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002a36:	00000097          	auipc	ra,0x0
    80002a3a:	f20080e7          	jalr	-224(ra) # 80002956 <devintr>
    80002a3e:	892a                	mv	s2,a0
    80002a40:	c151                	beqz	a0,80002ac4 <usertrap+0xcc>
  if(killed(p))
    80002a42:	8526                	mv	a0,s1
    80002a44:	00000097          	auipc	ra,0x0
    80002a48:	986080e7          	jalr	-1658(ra) # 800023ca <killed>
    80002a4c:	c929                	beqz	a0,80002a9e <usertrap+0xa6>
    80002a4e:	a099                	j	80002a94 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a50:	00006517          	auipc	a0,0x6
    80002a54:	9a050513          	addi	a0,a0,-1632 # 800083f0 <states.0+0x58>
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>
    if(killed(p))
    80002a60:	00000097          	auipc	ra,0x0
    80002a64:	96a080e7          	jalr	-1686(ra) # 800023ca <killed>
    80002a68:	e921                	bnez	a0,80002ab8 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002a6a:	6cb8                	ld	a4,88(s1)
    80002a6c:	6f1c                	ld	a5,24(a4)
    80002a6e:	0791                	addi	a5,a5,4
    80002a70:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a72:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a76:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a7a:	10079073          	csrw	sstatus,a5
    syscall();
    80002a7e:	00000097          	auipc	ra,0x0
    80002a82:	2d4080e7          	jalr	724(ra) # 80002d52 <syscall>
  if(killed(p))
    80002a86:	8526                	mv	a0,s1
    80002a88:	00000097          	auipc	ra,0x0
    80002a8c:	942080e7          	jalr	-1726(ra) # 800023ca <killed>
    80002a90:	c911                	beqz	a0,80002aa4 <usertrap+0xac>
    80002a92:	4901                	li	s2,0
    exit(-1);
    80002a94:	557d                	li	a0,-1
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	7c0080e7          	jalr	1984(ra) # 80002256 <exit>
  if(which_dev == 2)
    80002a9e:	4789                	li	a5,2
    80002aa0:	04f90f63          	beq	s2,a5,80002afe <usertrap+0x106>
  usertrapret();
    80002aa4:	00000097          	auipc	ra,0x0
    80002aa8:	dd6080e7          	jalr	-554(ra) # 8000287a <usertrapret>
}
    80002aac:	60e2                	ld	ra,24(sp)
    80002aae:	6442                	ld	s0,16(sp)
    80002ab0:	64a2                	ld	s1,8(sp)
    80002ab2:	6902                	ld	s2,0(sp)
    80002ab4:	6105                	addi	sp,sp,32
    80002ab6:	8082                	ret
      exit(-1);
    80002ab8:	557d                	li	a0,-1
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	79c080e7          	jalr	1948(ra) # 80002256 <exit>
    80002ac2:	b765                	j	80002a6a <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ac4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ac8:	5890                	lw	a2,48(s1)
    80002aca:	00006517          	auipc	a0,0x6
    80002ace:	94650513          	addi	a0,a0,-1722 # 80008410 <states.0+0x78>
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	ab6080e7          	jalr	-1354(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ada:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ade:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ae2:	00006517          	auipc	a0,0x6
    80002ae6:	95e50513          	addi	a0,a0,-1698 # 80008440 <states.0+0xa8>
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	a9e080e7          	jalr	-1378(ra) # 80000588 <printf>
    setkilled(p);
    80002af2:	8526                	mv	a0,s1
    80002af4:	00000097          	auipc	ra,0x0
    80002af8:	8aa080e7          	jalr	-1878(ra) # 8000239e <setkilled>
    80002afc:	b769                	j	80002a86 <usertrap+0x8e>
    yield();
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	5e8080e7          	jalr	1512(ra) # 800020e6 <yield>
    80002b06:	bf79                	j	80002aa4 <usertrap+0xac>

0000000080002b08 <kerneltrap>:
{
    80002b08:	7179                	addi	sp,sp,-48
    80002b0a:	f406                	sd	ra,40(sp)
    80002b0c:	f022                	sd	s0,32(sp)
    80002b0e:	ec26                	sd	s1,24(sp)
    80002b10:	e84a                	sd	s2,16(sp)
    80002b12:	e44e                	sd	s3,8(sp)
    80002b14:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b16:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b1a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b1e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b22:	1004f793          	andi	a5,s1,256
    80002b26:	cb85                	beqz	a5,80002b56 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b28:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b2c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b2e:	ef85                	bnez	a5,80002b66 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b30:	00000097          	auipc	ra,0x0
    80002b34:	e26080e7          	jalr	-474(ra) # 80002956 <devintr>
    80002b38:	cd1d                	beqz	a0,80002b76 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b3a:	4789                	li	a5,2
    80002b3c:	06f50a63          	beq	a0,a5,80002bb0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b40:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b44:	10049073          	csrw	sstatus,s1
}
    80002b48:	70a2                	ld	ra,40(sp)
    80002b4a:	7402                	ld	s0,32(sp)
    80002b4c:	64e2                	ld	s1,24(sp)
    80002b4e:	6942                	ld	s2,16(sp)
    80002b50:	69a2                	ld	s3,8(sp)
    80002b52:	6145                	addi	sp,sp,48
    80002b54:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b56:	00006517          	auipc	a0,0x6
    80002b5a:	90a50513          	addi	a0,a0,-1782 # 80008460 <states.0+0xc8>
    80002b5e:	ffffe097          	auipc	ra,0xffffe
    80002b62:	9e0080e7          	jalr	-1568(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b66:	00006517          	auipc	a0,0x6
    80002b6a:	92250513          	addi	a0,a0,-1758 # 80008488 <states.0+0xf0>
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	9d0080e7          	jalr	-1584(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b76:	85ce                	mv	a1,s3
    80002b78:	00006517          	auipc	a0,0x6
    80002b7c:	93050513          	addi	a0,a0,-1744 # 800084a8 <states.0+0x110>
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	a08080e7          	jalr	-1528(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b88:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b8c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b90:	00006517          	auipc	a0,0x6
    80002b94:	92850513          	addi	a0,a0,-1752 # 800084b8 <states.0+0x120>
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	9f0080e7          	jalr	-1552(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ba0:	00006517          	auipc	a0,0x6
    80002ba4:	93050513          	addi	a0,a0,-1744 # 800084d0 <states.0+0x138>
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	996080e7          	jalr	-1642(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bb0:	fffff097          	auipc	ra,0xfffff
    80002bb4:	e32080e7          	jalr	-462(ra) # 800019e2 <myproc>
    80002bb8:	d541                	beqz	a0,80002b40 <kerneltrap+0x38>
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	e28080e7          	jalr	-472(ra) # 800019e2 <myproc>
    80002bc2:	4d18                	lw	a4,24(a0)
    80002bc4:	4791                	li	a5,4
    80002bc6:	f6f71de3          	bne	a4,a5,80002b40 <kerneltrap+0x38>
    yield();
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	51c080e7          	jalr	1308(ra) # 800020e6 <yield>
    80002bd2:	b7bd                	j	80002b40 <kerneltrap+0x38>

0000000080002bd4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bd4:	1101                	addi	sp,sp,-32
    80002bd6:	ec06                	sd	ra,24(sp)
    80002bd8:	e822                	sd	s0,16(sp)
    80002bda:	e426                	sd	s1,8(sp)
    80002bdc:	1000                	addi	s0,sp,32
    80002bde:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	e02080e7          	jalr	-510(ra) # 800019e2 <myproc>
  switch (n) {
    80002be8:	4795                	li	a5,5
    80002bea:	0497e163          	bltu	a5,s1,80002c2c <argraw+0x58>
    80002bee:	048a                	slli	s1,s1,0x2
    80002bf0:	00006717          	auipc	a4,0x6
    80002bf4:	91870713          	addi	a4,a4,-1768 # 80008508 <states.0+0x170>
    80002bf8:	94ba                	add	s1,s1,a4
    80002bfa:	409c                	lw	a5,0(s1)
    80002bfc:	97ba                	add	a5,a5,a4
    80002bfe:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c00:	6d3c                	ld	a5,88(a0)
    80002c02:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c04:	60e2                	ld	ra,24(sp)
    80002c06:	6442                	ld	s0,16(sp)
    80002c08:	64a2                	ld	s1,8(sp)
    80002c0a:	6105                	addi	sp,sp,32
    80002c0c:	8082                	ret
    return p->trapframe->a1;
    80002c0e:	6d3c                	ld	a5,88(a0)
    80002c10:	7fa8                	ld	a0,120(a5)
    80002c12:	bfcd                	j	80002c04 <argraw+0x30>
    return p->trapframe->a2;
    80002c14:	6d3c                	ld	a5,88(a0)
    80002c16:	63c8                	ld	a0,128(a5)
    80002c18:	b7f5                	j	80002c04 <argraw+0x30>
    return p->trapframe->a3;
    80002c1a:	6d3c                	ld	a5,88(a0)
    80002c1c:	67c8                	ld	a0,136(a5)
    80002c1e:	b7dd                	j	80002c04 <argraw+0x30>
    return p->trapframe->a4;
    80002c20:	6d3c                	ld	a5,88(a0)
    80002c22:	6bc8                	ld	a0,144(a5)
    80002c24:	b7c5                	j	80002c04 <argraw+0x30>
    return p->trapframe->a5;
    80002c26:	6d3c                	ld	a5,88(a0)
    80002c28:	6fc8                	ld	a0,152(a5)
    80002c2a:	bfe9                	j	80002c04 <argraw+0x30>
  panic("argraw");
    80002c2c:	00006517          	auipc	a0,0x6
    80002c30:	8b450513          	addi	a0,a0,-1868 # 800084e0 <states.0+0x148>
    80002c34:	ffffe097          	auipc	ra,0xffffe
    80002c38:	90a080e7          	jalr	-1782(ra) # 8000053e <panic>

0000000080002c3c <fetchaddr>:
{
    80002c3c:	1101                	addi	sp,sp,-32
    80002c3e:	ec06                	sd	ra,24(sp)
    80002c40:	e822                	sd	s0,16(sp)
    80002c42:	e426                	sd	s1,8(sp)
    80002c44:	e04a                	sd	s2,0(sp)
    80002c46:	1000                	addi	s0,sp,32
    80002c48:	84aa                	mv	s1,a0
    80002c4a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	d96080e7          	jalr	-618(ra) # 800019e2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c54:	653c                	ld	a5,72(a0)
    80002c56:	02f4f863          	bgeu	s1,a5,80002c86 <fetchaddr+0x4a>
    80002c5a:	00848713          	addi	a4,s1,8
    80002c5e:	02e7e663          	bltu	a5,a4,80002c8a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c62:	46a1                	li	a3,8
    80002c64:	8626                	mv	a2,s1
    80002c66:	85ca                	mv	a1,s2
    80002c68:	6928                	ld	a0,80(a0)
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	ac0080e7          	jalr	-1344(ra) # 8000172a <copyin>
    80002c72:	00a03533          	snez	a0,a0
    80002c76:	40a00533          	neg	a0,a0
}
    80002c7a:	60e2                	ld	ra,24(sp)
    80002c7c:	6442                	ld	s0,16(sp)
    80002c7e:	64a2                	ld	s1,8(sp)
    80002c80:	6902                	ld	s2,0(sp)
    80002c82:	6105                	addi	sp,sp,32
    80002c84:	8082                	ret
    return -1;
    80002c86:	557d                	li	a0,-1
    80002c88:	bfcd                	j	80002c7a <fetchaddr+0x3e>
    80002c8a:	557d                	li	a0,-1
    80002c8c:	b7fd                	j	80002c7a <fetchaddr+0x3e>

0000000080002c8e <fetchstr>:
{
    80002c8e:	7179                	addi	sp,sp,-48
    80002c90:	f406                	sd	ra,40(sp)
    80002c92:	f022                	sd	s0,32(sp)
    80002c94:	ec26                	sd	s1,24(sp)
    80002c96:	e84a                	sd	s2,16(sp)
    80002c98:	e44e                	sd	s3,8(sp)
    80002c9a:	1800                	addi	s0,sp,48
    80002c9c:	892a                	mv	s2,a0
    80002c9e:	84ae                	mv	s1,a1
    80002ca0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	d40080e7          	jalr	-704(ra) # 800019e2 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002caa:	86ce                	mv	a3,s3
    80002cac:	864a                	mv	a2,s2
    80002cae:	85a6                	mv	a1,s1
    80002cb0:	6928                	ld	a0,80(a0)
    80002cb2:	fffff097          	auipc	ra,0xfffff
    80002cb6:	b06080e7          	jalr	-1274(ra) # 800017b8 <copyinstr>
    80002cba:	00054e63          	bltz	a0,80002cd6 <fetchstr+0x48>
  return strlen(buf);
    80002cbe:	8526                	mv	a0,s1
    80002cc0:	ffffe097          	auipc	ra,0xffffe
    80002cc4:	18e080e7          	jalr	398(ra) # 80000e4e <strlen>
}
    80002cc8:	70a2                	ld	ra,40(sp)
    80002cca:	7402                	ld	s0,32(sp)
    80002ccc:	64e2                	ld	s1,24(sp)
    80002cce:	6942                	ld	s2,16(sp)
    80002cd0:	69a2                	ld	s3,8(sp)
    80002cd2:	6145                	addi	sp,sp,48
    80002cd4:	8082                	ret
    return -1;
    80002cd6:	557d                	li	a0,-1
    80002cd8:	bfc5                	j	80002cc8 <fetchstr+0x3a>

0000000080002cda <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002cda:	1101                	addi	sp,sp,-32
    80002cdc:	ec06                	sd	ra,24(sp)
    80002cde:	e822                	sd	s0,16(sp)
    80002ce0:	e426                	sd	s1,8(sp)
    80002ce2:	1000                	addi	s0,sp,32
    80002ce4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ce6:	00000097          	auipc	ra,0x0
    80002cea:	eee080e7          	jalr	-274(ra) # 80002bd4 <argraw>
    80002cee:	c088                	sw	a0,0(s1)
}
    80002cf0:	60e2                	ld	ra,24(sp)
    80002cf2:	6442                	ld	s0,16(sp)
    80002cf4:	64a2                	ld	s1,8(sp)
    80002cf6:	6105                	addi	sp,sp,32
    80002cf8:	8082                	ret

0000000080002cfa <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002cfa:	1101                	addi	sp,sp,-32
    80002cfc:	ec06                	sd	ra,24(sp)
    80002cfe:	e822                	sd	s0,16(sp)
    80002d00:	e426                	sd	s1,8(sp)
    80002d02:	1000                	addi	s0,sp,32
    80002d04:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d06:	00000097          	auipc	ra,0x0
    80002d0a:	ece080e7          	jalr	-306(ra) # 80002bd4 <argraw>
    80002d0e:	e088                	sd	a0,0(s1)
}
    80002d10:	60e2                	ld	ra,24(sp)
    80002d12:	6442                	ld	s0,16(sp)
    80002d14:	64a2                	ld	s1,8(sp)
    80002d16:	6105                	addi	sp,sp,32
    80002d18:	8082                	ret

0000000080002d1a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d1a:	7179                	addi	sp,sp,-48
    80002d1c:	f406                	sd	ra,40(sp)
    80002d1e:	f022                	sd	s0,32(sp)
    80002d20:	ec26                	sd	s1,24(sp)
    80002d22:	e84a                	sd	s2,16(sp)
    80002d24:	1800                	addi	s0,sp,48
    80002d26:	84ae                	mv	s1,a1
    80002d28:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d2a:	fd840593          	addi	a1,s0,-40
    80002d2e:	00000097          	auipc	ra,0x0
    80002d32:	fcc080e7          	jalr	-52(ra) # 80002cfa <argaddr>
  return fetchstr(addr, buf, max);
    80002d36:	864a                	mv	a2,s2
    80002d38:	85a6                	mv	a1,s1
    80002d3a:	fd843503          	ld	a0,-40(s0)
    80002d3e:	00000097          	auipc	ra,0x0
    80002d42:	f50080e7          	jalr	-176(ra) # 80002c8e <fetchstr>
}
    80002d46:	70a2                	ld	ra,40(sp)
    80002d48:	7402                	ld	s0,32(sp)
    80002d4a:	64e2                	ld	s1,24(sp)
    80002d4c:	6942                	ld	s2,16(sp)
    80002d4e:	6145                	addi	sp,sp,48
    80002d50:	8082                	ret

0000000080002d52 <syscall>:
[SYS_map_display]    sys_map_display,
};

void
syscall(void)
{
    80002d52:	1101                	addi	sp,sp,-32
    80002d54:	ec06                	sd	ra,24(sp)
    80002d56:	e822                	sd	s0,16(sp)
    80002d58:	e426                	sd	s1,8(sp)
    80002d5a:	e04a                	sd	s2,0(sp)
    80002d5c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	c84080e7          	jalr	-892(ra) # 800019e2 <myproc>
    80002d66:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d68:	05853903          	ld	s2,88(a0)
    80002d6c:	0a893783          	ld	a5,168(s2)
    80002d70:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d74:	37fd                	addiw	a5,a5,-1
    80002d76:	4759                	li	a4,22
    80002d78:	00f76f63          	bltu	a4,a5,80002d96 <syscall+0x44>
    80002d7c:	00369713          	slli	a4,a3,0x3
    80002d80:	00005797          	auipc	a5,0x5
    80002d84:	7a078793          	addi	a5,a5,1952 # 80008520 <syscalls>
    80002d88:	97ba                	add	a5,a5,a4
    80002d8a:	639c                	ld	a5,0(a5)
    80002d8c:	c789                	beqz	a5,80002d96 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d8e:	9782                	jalr	a5
    80002d90:	06a93823          	sd	a0,112(s2)
    80002d94:	a839                	j	80002db2 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d96:	15848613          	addi	a2,s1,344
    80002d9a:	588c                	lw	a1,48(s1)
    80002d9c:	00005517          	auipc	a0,0x5
    80002da0:	74c50513          	addi	a0,a0,1868 # 800084e8 <states.0+0x150>
    80002da4:	ffffd097          	auipc	ra,0xffffd
    80002da8:	7e4080e7          	jalr	2020(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dac:	6cbc                	ld	a5,88(s1)
    80002dae:	577d                	li	a4,-1
    80002db0:	fbb8                	sd	a4,112(a5)
  }
}
    80002db2:	60e2                	ld	ra,24(sp)
    80002db4:	6442                	ld	s0,16(sp)
    80002db6:	64a2                	ld	s1,8(sp)
    80002db8:	6902                	ld	s2,0(sp)
    80002dba:	6105                	addi	sp,sp,32
    80002dbc:	8082                	ret

0000000080002dbe <sys_exit>:
#include "proc.h"


uint64
sys_exit(void)
{
    80002dbe:	1101                	addi	sp,sp,-32
    80002dc0:	ec06                	sd	ra,24(sp)
    80002dc2:	e822                	sd	s0,16(sp)
    80002dc4:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002dc6:	fec40593          	addi	a1,s0,-20
    80002dca:	4501                	li	a0,0
    80002dcc:	00000097          	auipc	ra,0x0
    80002dd0:	f0e080e7          	jalr	-242(ra) # 80002cda <argint>
  exit(n);
    80002dd4:	fec42503          	lw	a0,-20(s0)
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	47e080e7          	jalr	1150(ra) # 80002256 <exit>
  return 0;  // not reached
}
    80002de0:	4501                	li	a0,0
    80002de2:	60e2                	ld	ra,24(sp)
    80002de4:	6442                	ld	s0,16(sp)
    80002de6:	6105                	addi	sp,sp,32
    80002de8:	8082                	ret

0000000080002dea <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dea:	1141                	addi	sp,sp,-16
    80002dec:	e406                	sd	ra,8(sp)
    80002dee:	e022                	sd	s0,0(sp)
    80002df0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	bf0080e7          	jalr	-1040(ra) # 800019e2 <myproc>
}
    80002dfa:	5908                	lw	a0,48(a0)
    80002dfc:	60a2                	ld	ra,8(sp)
    80002dfe:	6402                	ld	s0,0(sp)
    80002e00:	0141                	addi	sp,sp,16
    80002e02:	8082                	ret

0000000080002e04 <sys_fork>:

uint64
sys_fork(void)
{
    80002e04:	1141                	addi	sp,sp,-16
    80002e06:	e406                	sd	ra,8(sp)
    80002e08:	e022                	sd	s0,0(sp)
    80002e0a:	0800                	addi	s0,sp,16
  return fork();
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	024080e7          	jalr	36(ra) # 80001e30 <fork>
}
    80002e14:	60a2                	ld	ra,8(sp)
    80002e16:	6402                	ld	s0,0(sp)
    80002e18:	0141                	addi	sp,sp,16
    80002e1a:	8082                	ret

0000000080002e1c <sys_wait>:

uint64
sys_wait(void)
{
    80002e1c:	1101                	addi	sp,sp,-32
    80002e1e:	ec06                	sd	ra,24(sp)
    80002e20:	e822                	sd	s0,16(sp)
    80002e22:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e24:	fe840593          	addi	a1,s0,-24
    80002e28:	4501                	li	a0,0
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	ed0080e7          	jalr	-304(ra) # 80002cfa <argaddr>
  return wait(p);
    80002e32:	fe843503          	ld	a0,-24(s0)
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	5c6080e7          	jalr	1478(ra) # 800023fc <wait>
}
    80002e3e:	60e2                	ld	ra,24(sp)
    80002e40:	6442                	ld	s0,16(sp)
    80002e42:	6105                	addi	sp,sp,32
    80002e44:	8082                	ret

0000000080002e46 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e46:	7179                	addi	sp,sp,-48
    80002e48:	f406                	sd	ra,40(sp)
    80002e4a:	f022                	sd	s0,32(sp)
    80002e4c:	ec26                	sd	s1,24(sp)
    80002e4e:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e50:	fdc40593          	addi	a1,s0,-36
    80002e54:	4501                	li	a0,0
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	e84080e7          	jalr	-380(ra) # 80002cda <argint>
  addr = myproc()->sz;
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	b84080e7          	jalr	-1148(ra) # 800019e2 <myproc>
    80002e66:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e68:	fdc42503          	lw	a0,-36(s0)
    80002e6c:	fffff097          	auipc	ra,0xfffff
    80002e70:	f68080e7          	jalr	-152(ra) # 80001dd4 <growproc>
    80002e74:	00054863          	bltz	a0,80002e84 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e78:	8526                	mv	a0,s1
    80002e7a:	70a2                	ld	ra,40(sp)
    80002e7c:	7402                	ld	s0,32(sp)
    80002e7e:	64e2                	ld	s1,24(sp)
    80002e80:	6145                	addi	sp,sp,48
    80002e82:	8082                	ret
    return -1;
    80002e84:	54fd                	li	s1,-1
    80002e86:	bfcd                	j	80002e78 <sys_sbrk+0x32>

0000000080002e88 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e88:	7139                	addi	sp,sp,-64
    80002e8a:	fc06                	sd	ra,56(sp)
    80002e8c:	f822                	sd	s0,48(sp)
    80002e8e:	f426                	sd	s1,40(sp)
    80002e90:	f04a                	sd	s2,32(sp)
    80002e92:	ec4e                	sd	s3,24(sp)
    80002e94:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e96:	fcc40593          	addi	a1,s0,-52
    80002e9a:	4501                	li	a0,0
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	e3e080e7          	jalr	-450(ra) # 80002cda <argint>
  acquire(&tickslock);
    80002ea4:	00015517          	auipc	a0,0x15
    80002ea8:	84c50513          	addi	a0,a0,-1972 # 800176f0 <tickslock>
    80002eac:	ffffe097          	auipc	ra,0xffffe
    80002eb0:	d2a080e7          	jalr	-726(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002eb4:	00006917          	auipc	s2,0x6
    80002eb8:	59c92903          	lw	s2,1436(s2) # 80009450 <ticks>
  while(ticks - ticks0 < n){
    80002ebc:	fcc42783          	lw	a5,-52(s0)
    80002ec0:	cf9d                	beqz	a5,80002efe <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ec2:	00015997          	auipc	s3,0x15
    80002ec6:	82e98993          	addi	s3,s3,-2002 # 800176f0 <tickslock>
    80002eca:	00006497          	auipc	s1,0x6
    80002ece:	58648493          	addi	s1,s1,1414 # 80009450 <ticks>
    if(killed(myproc())){
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	b10080e7          	jalr	-1264(ra) # 800019e2 <myproc>
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	4f0080e7          	jalr	1264(ra) # 800023ca <killed>
    80002ee2:	ed15                	bnez	a0,80002f1e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ee4:	85ce                	mv	a1,s3
    80002ee6:	8526                	mv	a0,s1
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	23a080e7          	jalr	570(ra) # 80002122 <sleep>
  while(ticks - ticks0 < n){
    80002ef0:	409c                	lw	a5,0(s1)
    80002ef2:	412787bb          	subw	a5,a5,s2
    80002ef6:	fcc42703          	lw	a4,-52(s0)
    80002efa:	fce7ece3          	bltu	a5,a4,80002ed2 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002efe:	00014517          	auipc	a0,0x14
    80002f02:	7f250513          	addi	a0,a0,2034 # 800176f0 <tickslock>
    80002f06:	ffffe097          	auipc	ra,0xffffe
    80002f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
  return 0;
    80002f0e:	4501                	li	a0,0
}
    80002f10:	70e2                	ld	ra,56(sp)
    80002f12:	7442                	ld	s0,48(sp)
    80002f14:	74a2                	ld	s1,40(sp)
    80002f16:	7902                	ld	s2,32(sp)
    80002f18:	69e2                	ld	s3,24(sp)
    80002f1a:	6121                	addi	sp,sp,64
    80002f1c:	8082                	ret
      release(&tickslock);
    80002f1e:	00014517          	auipc	a0,0x14
    80002f22:	7d250513          	addi	a0,a0,2002 # 800176f0 <tickslock>
    80002f26:	ffffe097          	auipc	ra,0xffffe
    80002f2a:	d64080e7          	jalr	-668(ra) # 80000c8a <release>
      return -1;
    80002f2e:	557d                	li	a0,-1
    80002f30:	b7c5                	j	80002f10 <sys_sleep+0x88>

0000000080002f32 <sys_kill>:

uint64
sys_kill(void)
{
    80002f32:	1101                	addi	sp,sp,-32
    80002f34:	ec06                	sd	ra,24(sp)
    80002f36:	e822                	sd	s0,16(sp)
    80002f38:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f3a:	fec40593          	addi	a1,s0,-20
    80002f3e:	4501                	li	a0,0
    80002f40:	00000097          	auipc	ra,0x0
    80002f44:	d9a080e7          	jalr	-614(ra) # 80002cda <argint>
  return kill(pid);
    80002f48:	fec42503          	lw	a0,-20(s0)
    80002f4c:	fffff097          	auipc	ra,0xfffff
    80002f50:	3e0080e7          	jalr	992(ra) # 8000232c <kill>
}
    80002f54:	60e2                	ld	ra,24(sp)
    80002f56:	6442                	ld	s0,16(sp)
    80002f58:	6105                	addi	sp,sp,32
    80002f5a:	8082                	ret

0000000080002f5c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f5c:	1101                	addi	sp,sp,-32
    80002f5e:	ec06                	sd	ra,24(sp)
    80002f60:	e822                	sd	s0,16(sp)
    80002f62:	e426                	sd	s1,8(sp)
    80002f64:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f66:	00014517          	auipc	a0,0x14
    80002f6a:	78a50513          	addi	a0,a0,1930 # 800176f0 <tickslock>
    80002f6e:	ffffe097          	auipc	ra,0xffffe
    80002f72:	c68080e7          	jalr	-920(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002f76:	00006497          	auipc	s1,0x6
    80002f7a:	4da4a483          	lw	s1,1242(s1) # 80009450 <ticks>
  release(&tickslock);
    80002f7e:	00014517          	auipc	a0,0x14
    80002f82:	77250513          	addi	a0,a0,1906 # 800176f0 <tickslock>
    80002f86:	ffffe097          	auipc	ra,0xffffe
    80002f8a:	d04080e7          	jalr	-764(ra) # 80000c8a <release>
  return xticks;
}
    80002f8e:	02049513          	slli	a0,s1,0x20
    80002f92:	9101                	srli	a0,a0,0x20
    80002f94:	60e2                	ld	ra,24(sp)
    80002f96:	6442                	ld	s0,16(sp)
    80002f98:	64a2                	ld	s1,8(sp)
    80002f9a:	6105                	addi	sp,sp,32
    80002f9c:	8082                	ret

0000000080002f9e <sys_flip_display>:
// calling process's address space.
//
// TODO: Students implement this syscall.
uint64
sys_flip_display(void)
{
    80002f9e:	7139                	addi	sp,sp,-64
    80002fa0:	fc06                	sd	ra,56(sp)
    80002fa2:	f822                	sd	s0,48(sp)
    80002fa4:	f426                	sd	s1,40(sp)
    80002fa6:	f04a                	sd	s2,32(sp)
    80002fa8:	ec4e                	sd	s3,24(sp)
    80002faa:	e852                	sd	s4,16(sp)
    80002fac:	0080                	addi	s0,sp,64
  printf("sys_flip_display called\n");
    80002fae:	00005517          	auipc	a0,0x5
    80002fb2:	63250513          	addi	a0,a0,1586 # 800085e0 <syscalls+0xc0>
    80002fb6:	ffffd097          	auipc	ra,0xffffd
    80002fba:	5d2080e7          	jalr	1490(ra) # 80000588 <printf>
  uint64 buf;
  argaddr(0, &buf);
    80002fbe:	fc840593          	addi	a1,s0,-56
    80002fc2:	4501                	li	a0,0
    80002fc4:	00000097          	auipc	ra,0x0
    80002fc8:	d36080e7          	jalr	-714(ra) # 80002cfa <argaddr>
  if (buf % 4096 != 0){
    80002fcc:	fc843783          	ld	a5,-56(s0)
    80002fd0:	17d2                	slli	a5,a5,0x34
    80002fd2:	0347d493          	srli	s1,a5,0x34
    pte_t *pte = walk(myproc()->pagetable, buf + i*PGSIZE, 0);
    if(pte == 0 || (*pte & PTE_V) == 0){
      printf("sys_flip_display: buffer not fully mapped\n");
      return -1;
    }
    if((*pte & PTE_U) == 0 || (*pte & PTE_R) == 0 || (*pte & PTE_W) == 0){
    80002fd6:	4959                	li	s2,22
  for(int i = 0; i < GPU_FB_PAGES; i++){
    80002fd8:	6a05                	lui	s4,0x1
    80002fda:	0012c9b7          	lui	s3,0x12c
  if (buf % 4096 != 0){
    80002fde:	eba1                	bnez	a5,8000302e <sys_flip_display+0x90>
    pte_t *pte = walk(myproc()->pagetable, buf + i*PGSIZE, 0);
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	a02080e7          	jalr	-1534(ra) # 800019e2 <myproc>
    80002fe8:	4601                	li	a2,0
    80002fea:	fc843583          	ld	a1,-56(s0)
    80002fee:	95a6                	add	a1,a1,s1
    80002ff0:	6928                	ld	a0,80(a0)
    80002ff2:	ffffe097          	auipc	ra,0xffffe
    80002ff6:	fe4080e7          	jalr	-28(ra) # 80000fd6 <walk>
    if(pte == 0 || (*pte & PTE_V) == 0){
    80002ffa:	c521                	beqz	a0,80003042 <sys_flip_display+0xa4>
    80002ffc:	611c                	ld	a5,0(a0)
    80002ffe:	0017f713          	andi	a4,a5,1
    80003002:	c321                	beqz	a4,80003042 <sys_flip_display+0xa4>
    if((*pte & PTE_U) == 0 || (*pte & PTE_R) == 0 || (*pte & PTE_W) == 0){
    80003004:	8bd9                	andi	a5,a5,22
    80003006:	05279f63          	bne	a5,s2,80003064 <sys_flip_display+0xc6>
  for(int i = 0; i < GPU_FB_PAGES; i++){
    8000300a:	94d2                	add	s1,s1,s4
    8000300c:	fd349ae3          	bne	s1,s3,80002fe0 <sys_flip_display+0x42>
      printf("sys_flip_display: buffer not mapped with PTE_U|PTE_R|PTE_W\n");
      return -1;
    }
  }
  printf("sys_flip_display: buffer looks good, flipping display\n");
    80003010:	00005517          	auipc	a0,0x5
    80003014:	69050513          	addi	a0,a0,1680 # 800086a0 <syscalls+0x180>
    80003018:	ffffd097          	auipc	ra,0xffffd
    8000301c:	570080e7          	jalr	1392(ra) # 80000588 <printf>
  return virtio_gpu_flip(buf);
    80003020:	fc843503          	ld	a0,-56(s0)
    80003024:	00004097          	auipc	ra,0x4
    80003028:	cc4080e7          	jalr	-828(ra) # 80006ce8 <virtio_gpu_flip>
    8000302c:	a025                	j	80003054 <sys_flip_display+0xb6>
    printf("sys_flip_display: buffer not page-aligned\n");
    8000302e:	00005517          	auipc	a0,0x5
    80003032:	5d250513          	addi	a0,a0,1490 # 80008600 <syscalls+0xe0>
    80003036:	ffffd097          	auipc	ra,0xffffd
    8000303a:	552080e7          	jalr	1362(ra) # 80000588 <printf>
    return -1;
    8000303e:	557d                	li	a0,-1
    80003040:	a811                	j	80003054 <sys_flip_display+0xb6>
      printf("sys_flip_display: buffer not fully mapped\n");
    80003042:	00005517          	auipc	a0,0x5
    80003046:	5ee50513          	addi	a0,a0,1518 # 80008630 <syscalls+0x110>
    8000304a:	ffffd097          	auipc	ra,0xffffd
    8000304e:	53e080e7          	jalr	1342(ra) # 80000588 <printf>
      return -1;
    80003052:	557d                	li	a0,-1
  // return 1;
}
    80003054:	70e2                	ld	ra,56(sp)
    80003056:	7442                	ld	s0,48(sp)
    80003058:	74a2                	ld	s1,40(sp)
    8000305a:	7902                	ld	s2,32(sp)
    8000305c:	69e2                	ld	s3,24(sp)
    8000305e:	6a42                	ld	s4,16(sp)
    80003060:	6121                	addi	sp,sp,64
    80003062:	8082                	ret
      printf("sys_flip_display: buffer not mapped with PTE_U|PTE_R|PTE_W\n");
    80003064:	00005517          	auipc	a0,0x5
    80003068:	5fc50513          	addi	a0,a0,1532 # 80008660 <syscalls+0x140>
    8000306c:	ffffd097          	auipc	ra,0xffffd
    80003070:	51c080e7          	jalr	1308(ra) # 80000588 <printf>
      return -1;
    80003074:	557d                	li	a0,-1
    80003076:	bff9                	j	80003054 <sys_flip_display+0xb6>

0000000080003078 <sys_map_display>:
// Returns the mapped virtual address on success, (uint64)-1 on failure.
//
// TODO: Students implement this syscall.
uint64
sys_map_display(void)
{
    80003078:	7179                	addi	sp,sp,-48
    8000307a:	f406                	sd	ra,40(sp)
    8000307c:	f022                	sd	s0,32(sp)
    8000307e:	ec26                	sd	s1,24(sp)
    80003080:	1800                	addi	s0,sp,48
  uint64 addr;
  argaddr(0, &addr);
    80003082:	fd840593          	addi	a1,s0,-40
    80003086:	4501                	li	a0,0
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	c72080e7          	jalr	-910(ra) # 80002cfa <argaddr>
  uint64 answer = (uint64)map_display((void*)addr);
    80003090:	fd843503          	ld	a0,-40(s0)
    80003094:	fffff097          	auipc	ra,0xfffff
    80003098:	5f0080e7          	jalr	1520(ra) # 80002684 <map_display>
    8000309c:	84aa                	mv	s1,a0
  printf("sys_map_display: addr=0x%p, answer=0x%p\n", addr, answer);
    8000309e:	862a                	mv	a2,a0
    800030a0:	fd843583          	ld	a1,-40(s0)
    800030a4:	00005517          	auipc	a0,0x5
    800030a8:	63450513          	addi	a0,a0,1588 # 800086d8 <syscalls+0x1b8>
    800030ac:	ffffd097          	auipc	ra,0xffffd
    800030b0:	4dc080e7          	jalr	1244(ra) # 80000588 <printf>
  return answer;
  
}
    800030b4:	8526                	mv	a0,s1
    800030b6:	70a2                	ld	ra,40(sp)
    800030b8:	7402                	ld	s0,32(sp)
    800030ba:	64e2                	ld	s1,24(sp)
    800030bc:	6145                	addi	sp,sp,48
    800030be:	8082                	ret

00000000800030c0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030c0:	7179                	addi	sp,sp,-48
    800030c2:	f406                	sd	ra,40(sp)
    800030c4:	f022                	sd	s0,32(sp)
    800030c6:	ec26                	sd	s1,24(sp)
    800030c8:	e84a                	sd	s2,16(sp)
    800030ca:	e44e                	sd	s3,8(sp)
    800030cc:	e052                	sd	s4,0(sp)
    800030ce:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030d0:	00005597          	auipc	a1,0x5
    800030d4:	63858593          	addi	a1,a1,1592 # 80008708 <syscalls+0x1e8>
    800030d8:	00014517          	auipc	a0,0x14
    800030dc:	63050513          	addi	a0,a0,1584 # 80017708 <bcache>
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	a66080e7          	jalr	-1434(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030e8:	0001c797          	auipc	a5,0x1c
    800030ec:	62078793          	addi	a5,a5,1568 # 8001f708 <bcache+0x8000>
    800030f0:	0001d717          	auipc	a4,0x1d
    800030f4:	88070713          	addi	a4,a4,-1920 # 8001f970 <bcache+0x8268>
    800030f8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030fc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003100:	00014497          	auipc	s1,0x14
    80003104:	62048493          	addi	s1,s1,1568 # 80017720 <bcache+0x18>
    b->next = bcache.head.next;
    80003108:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000310a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000310c:	00005a17          	auipc	s4,0x5
    80003110:	604a0a13          	addi	s4,s4,1540 # 80008710 <syscalls+0x1f0>
    b->next = bcache.head.next;
    80003114:	2b893783          	ld	a5,696(s2)
    80003118:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000311a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000311e:	85d2                	mv	a1,s4
    80003120:	01048513          	addi	a0,s1,16
    80003124:	00001097          	auipc	ra,0x1
    80003128:	4c4080e7          	jalr	1220(ra) # 800045e8 <initsleeplock>
    bcache.head.next->prev = b;
    8000312c:	2b893783          	ld	a5,696(s2)
    80003130:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003132:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003136:	45848493          	addi	s1,s1,1112
    8000313a:	fd349de3          	bne	s1,s3,80003114 <binit+0x54>
  }
}
    8000313e:	70a2                	ld	ra,40(sp)
    80003140:	7402                	ld	s0,32(sp)
    80003142:	64e2                	ld	s1,24(sp)
    80003144:	6942                	ld	s2,16(sp)
    80003146:	69a2                	ld	s3,8(sp)
    80003148:	6a02                	ld	s4,0(sp)
    8000314a:	6145                	addi	sp,sp,48
    8000314c:	8082                	ret

000000008000314e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000314e:	7179                	addi	sp,sp,-48
    80003150:	f406                	sd	ra,40(sp)
    80003152:	f022                	sd	s0,32(sp)
    80003154:	ec26                	sd	s1,24(sp)
    80003156:	e84a                	sd	s2,16(sp)
    80003158:	e44e                	sd	s3,8(sp)
    8000315a:	1800                	addi	s0,sp,48
    8000315c:	892a                	mv	s2,a0
    8000315e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003160:	00014517          	auipc	a0,0x14
    80003164:	5a850513          	addi	a0,a0,1448 # 80017708 <bcache>
    80003168:	ffffe097          	auipc	ra,0xffffe
    8000316c:	a6e080e7          	jalr	-1426(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003170:	0001d497          	auipc	s1,0x1d
    80003174:	8504b483          	ld	s1,-1968(s1) # 8001f9c0 <bcache+0x82b8>
    80003178:	0001c797          	auipc	a5,0x1c
    8000317c:	7f878793          	addi	a5,a5,2040 # 8001f970 <bcache+0x8268>
    80003180:	02f48f63          	beq	s1,a5,800031be <bread+0x70>
    80003184:	873e                	mv	a4,a5
    80003186:	a021                	j	8000318e <bread+0x40>
    80003188:	68a4                	ld	s1,80(s1)
    8000318a:	02e48a63          	beq	s1,a4,800031be <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000318e:	449c                	lw	a5,8(s1)
    80003190:	ff279ce3          	bne	a5,s2,80003188 <bread+0x3a>
    80003194:	44dc                	lw	a5,12(s1)
    80003196:	ff3799e3          	bne	a5,s3,80003188 <bread+0x3a>
      b->refcnt++;
    8000319a:	40bc                	lw	a5,64(s1)
    8000319c:	2785                	addiw	a5,a5,1
    8000319e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031a0:	00014517          	auipc	a0,0x14
    800031a4:	56850513          	addi	a0,a0,1384 # 80017708 <bcache>
    800031a8:	ffffe097          	auipc	ra,0xffffe
    800031ac:	ae2080e7          	jalr	-1310(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800031b0:	01048513          	addi	a0,s1,16
    800031b4:	00001097          	auipc	ra,0x1
    800031b8:	46e080e7          	jalr	1134(ra) # 80004622 <acquiresleep>
      return b;
    800031bc:	a8b9                	j	8000321a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031be:	0001c497          	auipc	s1,0x1c
    800031c2:	7fa4b483          	ld	s1,2042(s1) # 8001f9b8 <bcache+0x82b0>
    800031c6:	0001c797          	auipc	a5,0x1c
    800031ca:	7aa78793          	addi	a5,a5,1962 # 8001f970 <bcache+0x8268>
    800031ce:	00f48863          	beq	s1,a5,800031de <bread+0x90>
    800031d2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031d4:	40bc                	lw	a5,64(s1)
    800031d6:	cf81                	beqz	a5,800031ee <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031d8:	64a4                	ld	s1,72(s1)
    800031da:	fee49de3          	bne	s1,a4,800031d4 <bread+0x86>
  panic("bget: no buffers");
    800031de:	00005517          	auipc	a0,0x5
    800031e2:	53a50513          	addi	a0,a0,1338 # 80008718 <syscalls+0x1f8>
    800031e6:	ffffd097          	auipc	ra,0xffffd
    800031ea:	358080e7          	jalr	856(ra) # 8000053e <panic>
      b->dev = dev;
    800031ee:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800031f2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031f6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031fa:	4785                	li	a5,1
    800031fc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031fe:	00014517          	auipc	a0,0x14
    80003202:	50a50513          	addi	a0,a0,1290 # 80017708 <bcache>
    80003206:	ffffe097          	auipc	ra,0xffffe
    8000320a:	a84080e7          	jalr	-1404(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000320e:	01048513          	addi	a0,s1,16
    80003212:	00001097          	auipc	ra,0x1
    80003216:	410080e7          	jalr	1040(ra) # 80004622 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000321a:	409c                	lw	a5,0(s1)
    8000321c:	cb89                	beqz	a5,8000322e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000321e:	8526                	mv	a0,s1
    80003220:	70a2                	ld	ra,40(sp)
    80003222:	7402                	ld	s0,32(sp)
    80003224:	64e2                	ld	s1,24(sp)
    80003226:	6942                	ld	s2,16(sp)
    80003228:	69a2                	ld	s3,8(sp)
    8000322a:	6145                	addi	sp,sp,48
    8000322c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000322e:	4581                	li	a1,0
    80003230:	8526                	mv	a0,s1
    80003232:	00003097          	auipc	ra,0x3
    80003236:	fd2080e7          	jalr	-46(ra) # 80006204 <virtio_disk_rw>
    b->valid = 1;
    8000323a:	4785                	li	a5,1
    8000323c:	c09c                	sw	a5,0(s1)
  return b;
    8000323e:	b7c5                	j	8000321e <bread+0xd0>

0000000080003240 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003240:	1101                	addi	sp,sp,-32
    80003242:	ec06                	sd	ra,24(sp)
    80003244:	e822                	sd	s0,16(sp)
    80003246:	e426                	sd	s1,8(sp)
    80003248:	1000                	addi	s0,sp,32
    8000324a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000324c:	0541                	addi	a0,a0,16
    8000324e:	00001097          	auipc	ra,0x1
    80003252:	46e080e7          	jalr	1134(ra) # 800046bc <holdingsleep>
    80003256:	cd01                	beqz	a0,8000326e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003258:	4585                	li	a1,1
    8000325a:	8526                	mv	a0,s1
    8000325c:	00003097          	auipc	ra,0x3
    80003260:	fa8080e7          	jalr	-88(ra) # 80006204 <virtio_disk_rw>
}
    80003264:	60e2                	ld	ra,24(sp)
    80003266:	6442                	ld	s0,16(sp)
    80003268:	64a2                	ld	s1,8(sp)
    8000326a:	6105                	addi	sp,sp,32
    8000326c:	8082                	ret
    panic("bwrite");
    8000326e:	00005517          	auipc	a0,0x5
    80003272:	4c250513          	addi	a0,a0,1218 # 80008730 <syscalls+0x210>
    80003276:	ffffd097          	auipc	ra,0xffffd
    8000327a:	2c8080e7          	jalr	712(ra) # 8000053e <panic>

000000008000327e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000327e:	1101                	addi	sp,sp,-32
    80003280:	ec06                	sd	ra,24(sp)
    80003282:	e822                	sd	s0,16(sp)
    80003284:	e426                	sd	s1,8(sp)
    80003286:	e04a                	sd	s2,0(sp)
    80003288:	1000                	addi	s0,sp,32
    8000328a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000328c:	01050913          	addi	s2,a0,16
    80003290:	854a                	mv	a0,s2
    80003292:	00001097          	auipc	ra,0x1
    80003296:	42a080e7          	jalr	1066(ra) # 800046bc <holdingsleep>
    8000329a:	c92d                	beqz	a0,8000330c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000329c:	854a                	mv	a0,s2
    8000329e:	00001097          	auipc	ra,0x1
    800032a2:	3da080e7          	jalr	986(ra) # 80004678 <releasesleep>

  acquire(&bcache.lock);
    800032a6:	00014517          	auipc	a0,0x14
    800032aa:	46250513          	addi	a0,a0,1122 # 80017708 <bcache>
    800032ae:	ffffe097          	auipc	ra,0xffffe
    800032b2:	928080e7          	jalr	-1752(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800032b6:	40bc                	lw	a5,64(s1)
    800032b8:	37fd                	addiw	a5,a5,-1
    800032ba:	0007871b          	sext.w	a4,a5
    800032be:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032c0:	eb05                	bnez	a4,800032f0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032c2:	68bc                	ld	a5,80(s1)
    800032c4:	64b8                	ld	a4,72(s1)
    800032c6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032c8:	64bc                	ld	a5,72(s1)
    800032ca:	68b8                	ld	a4,80(s1)
    800032cc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032ce:	0001c797          	auipc	a5,0x1c
    800032d2:	43a78793          	addi	a5,a5,1082 # 8001f708 <bcache+0x8000>
    800032d6:	2b87b703          	ld	a4,696(a5)
    800032da:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032dc:	0001c717          	auipc	a4,0x1c
    800032e0:	69470713          	addi	a4,a4,1684 # 8001f970 <bcache+0x8268>
    800032e4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032e6:	2b87b703          	ld	a4,696(a5)
    800032ea:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032ec:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032f0:	00014517          	auipc	a0,0x14
    800032f4:	41850513          	addi	a0,a0,1048 # 80017708 <bcache>
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	992080e7          	jalr	-1646(ra) # 80000c8a <release>
}
    80003300:	60e2                	ld	ra,24(sp)
    80003302:	6442                	ld	s0,16(sp)
    80003304:	64a2                	ld	s1,8(sp)
    80003306:	6902                	ld	s2,0(sp)
    80003308:	6105                	addi	sp,sp,32
    8000330a:	8082                	ret
    panic("brelse");
    8000330c:	00005517          	auipc	a0,0x5
    80003310:	42c50513          	addi	a0,a0,1068 # 80008738 <syscalls+0x218>
    80003314:	ffffd097          	auipc	ra,0xffffd
    80003318:	22a080e7          	jalr	554(ra) # 8000053e <panic>

000000008000331c <bpin>:

void
bpin(struct buf *b) {
    8000331c:	1101                	addi	sp,sp,-32
    8000331e:	ec06                	sd	ra,24(sp)
    80003320:	e822                	sd	s0,16(sp)
    80003322:	e426                	sd	s1,8(sp)
    80003324:	1000                	addi	s0,sp,32
    80003326:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003328:	00014517          	auipc	a0,0x14
    8000332c:	3e050513          	addi	a0,a0,992 # 80017708 <bcache>
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	8a6080e7          	jalr	-1882(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003338:	40bc                	lw	a5,64(s1)
    8000333a:	2785                	addiw	a5,a5,1
    8000333c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000333e:	00014517          	auipc	a0,0x14
    80003342:	3ca50513          	addi	a0,a0,970 # 80017708 <bcache>
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	944080e7          	jalr	-1724(ra) # 80000c8a <release>
}
    8000334e:	60e2                	ld	ra,24(sp)
    80003350:	6442                	ld	s0,16(sp)
    80003352:	64a2                	ld	s1,8(sp)
    80003354:	6105                	addi	sp,sp,32
    80003356:	8082                	ret

0000000080003358 <bunpin>:

void
bunpin(struct buf *b) {
    80003358:	1101                	addi	sp,sp,-32
    8000335a:	ec06                	sd	ra,24(sp)
    8000335c:	e822                	sd	s0,16(sp)
    8000335e:	e426                	sd	s1,8(sp)
    80003360:	1000                	addi	s0,sp,32
    80003362:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003364:	00014517          	auipc	a0,0x14
    80003368:	3a450513          	addi	a0,a0,932 # 80017708 <bcache>
    8000336c:	ffffe097          	auipc	ra,0xffffe
    80003370:	86a080e7          	jalr	-1942(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003374:	40bc                	lw	a5,64(s1)
    80003376:	37fd                	addiw	a5,a5,-1
    80003378:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000337a:	00014517          	auipc	a0,0x14
    8000337e:	38e50513          	addi	a0,a0,910 # 80017708 <bcache>
    80003382:	ffffe097          	auipc	ra,0xffffe
    80003386:	908080e7          	jalr	-1784(ra) # 80000c8a <release>
}
    8000338a:	60e2                	ld	ra,24(sp)
    8000338c:	6442                	ld	s0,16(sp)
    8000338e:	64a2                	ld	s1,8(sp)
    80003390:	6105                	addi	sp,sp,32
    80003392:	8082                	ret

0000000080003394 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003394:	1101                	addi	sp,sp,-32
    80003396:	ec06                	sd	ra,24(sp)
    80003398:	e822                	sd	s0,16(sp)
    8000339a:	e426                	sd	s1,8(sp)
    8000339c:	e04a                	sd	s2,0(sp)
    8000339e:	1000                	addi	s0,sp,32
    800033a0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033a2:	00d5d59b          	srliw	a1,a1,0xd
    800033a6:	0001d797          	auipc	a5,0x1d
    800033aa:	a3e7a783          	lw	a5,-1474(a5) # 8001fde4 <sb+0x1c>
    800033ae:	9dbd                	addw	a1,a1,a5
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	d9e080e7          	jalr	-610(ra) # 8000314e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033b8:	0074f713          	andi	a4,s1,7
    800033bc:	4785                	li	a5,1
    800033be:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033c2:	14ce                	slli	s1,s1,0x33
    800033c4:	90d9                	srli	s1,s1,0x36
    800033c6:	00950733          	add	a4,a0,s1
    800033ca:	05874703          	lbu	a4,88(a4)
    800033ce:	00e7f6b3          	and	a3,a5,a4
    800033d2:	c69d                	beqz	a3,80003400 <bfree+0x6c>
    800033d4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033d6:	94aa                	add	s1,s1,a0
    800033d8:	fff7c793          	not	a5,a5
    800033dc:	8ff9                	and	a5,a5,a4
    800033de:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033e2:	00001097          	auipc	ra,0x1
    800033e6:	120080e7          	jalr	288(ra) # 80004502 <log_write>
  brelse(bp);
    800033ea:	854a                	mv	a0,s2
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	e92080e7          	jalr	-366(ra) # 8000327e <brelse>
}
    800033f4:	60e2                	ld	ra,24(sp)
    800033f6:	6442                	ld	s0,16(sp)
    800033f8:	64a2                	ld	s1,8(sp)
    800033fa:	6902                	ld	s2,0(sp)
    800033fc:	6105                	addi	sp,sp,32
    800033fe:	8082                	ret
    panic("freeing free block");
    80003400:	00005517          	auipc	a0,0x5
    80003404:	34050513          	addi	a0,a0,832 # 80008740 <syscalls+0x220>
    80003408:	ffffd097          	auipc	ra,0xffffd
    8000340c:	136080e7          	jalr	310(ra) # 8000053e <panic>

0000000080003410 <balloc>:
{
    80003410:	711d                	addi	sp,sp,-96
    80003412:	ec86                	sd	ra,88(sp)
    80003414:	e8a2                	sd	s0,80(sp)
    80003416:	e4a6                	sd	s1,72(sp)
    80003418:	e0ca                	sd	s2,64(sp)
    8000341a:	fc4e                	sd	s3,56(sp)
    8000341c:	f852                	sd	s4,48(sp)
    8000341e:	f456                	sd	s5,40(sp)
    80003420:	f05a                	sd	s6,32(sp)
    80003422:	ec5e                	sd	s7,24(sp)
    80003424:	e862                	sd	s8,16(sp)
    80003426:	e466                	sd	s9,8(sp)
    80003428:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000342a:	0001d797          	auipc	a5,0x1d
    8000342e:	9a27a783          	lw	a5,-1630(a5) # 8001fdcc <sb+0x4>
    80003432:	10078163          	beqz	a5,80003534 <balloc+0x124>
    80003436:	8baa                	mv	s7,a0
    80003438:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000343a:	0001db17          	auipc	s6,0x1d
    8000343e:	98eb0b13          	addi	s6,s6,-1650 # 8001fdc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003442:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003444:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003446:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003448:	6c89                	lui	s9,0x2
    8000344a:	a061                	j	800034d2 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000344c:	974a                	add	a4,a4,s2
    8000344e:	8fd5                	or	a5,a5,a3
    80003450:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003454:	854a                	mv	a0,s2
    80003456:	00001097          	auipc	ra,0x1
    8000345a:	0ac080e7          	jalr	172(ra) # 80004502 <log_write>
        brelse(bp);
    8000345e:	854a                	mv	a0,s2
    80003460:	00000097          	auipc	ra,0x0
    80003464:	e1e080e7          	jalr	-482(ra) # 8000327e <brelse>
  bp = bread(dev, bno);
    80003468:	85a6                	mv	a1,s1
    8000346a:	855e                	mv	a0,s7
    8000346c:	00000097          	auipc	ra,0x0
    80003470:	ce2080e7          	jalr	-798(ra) # 8000314e <bread>
    80003474:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003476:	40000613          	li	a2,1024
    8000347a:	4581                	li	a1,0
    8000347c:	05850513          	addi	a0,a0,88
    80003480:	ffffe097          	auipc	ra,0xffffe
    80003484:	852080e7          	jalr	-1966(ra) # 80000cd2 <memset>
  log_write(bp);
    80003488:	854a                	mv	a0,s2
    8000348a:	00001097          	auipc	ra,0x1
    8000348e:	078080e7          	jalr	120(ra) # 80004502 <log_write>
  brelse(bp);
    80003492:	854a                	mv	a0,s2
    80003494:	00000097          	auipc	ra,0x0
    80003498:	dea080e7          	jalr	-534(ra) # 8000327e <brelse>
}
    8000349c:	8526                	mv	a0,s1
    8000349e:	60e6                	ld	ra,88(sp)
    800034a0:	6446                	ld	s0,80(sp)
    800034a2:	64a6                	ld	s1,72(sp)
    800034a4:	6906                	ld	s2,64(sp)
    800034a6:	79e2                	ld	s3,56(sp)
    800034a8:	7a42                	ld	s4,48(sp)
    800034aa:	7aa2                	ld	s5,40(sp)
    800034ac:	7b02                	ld	s6,32(sp)
    800034ae:	6be2                	ld	s7,24(sp)
    800034b0:	6c42                	ld	s8,16(sp)
    800034b2:	6ca2                	ld	s9,8(sp)
    800034b4:	6125                	addi	sp,sp,96
    800034b6:	8082                	ret
    brelse(bp);
    800034b8:	854a                	mv	a0,s2
    800034ba:	00000097          	auipc	ra,0x0
    800034be:	dc4080e7          	jalr	-572(ra) # 8000327e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034c2:	015c87bb          	addw	a5,s9,s5
    800034c6:	00078a9b          	sext.w	s5,a5
    800034ca:	004b2703          	lw	a4,4(s6)
    800034ce:	06eaf363          	bgeu	s5,a4,80003534 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800034d2:	41fad79b          	sraiw	a5,s5,0x1f
    800034d6:	0137d79b          	srliw	a5,a5,0x13
    800034da:	015787bb          	addw	a5,a5,s5
    800034de:	40d7d79b          	sraiw	a5,a5,0xd
    800034e2:	01cb2583          	lw	a1,28(s6)
    800034e6:	9dbd                	addw	a1,a1,a5
    800034e8:	855e                	mv	a0,s7
    800034ea:	00000097          	auipc	ra,0x0
    800034ee:	c64080e7          	jalr	-924(ra) # 8000314e <bread>
    800034f2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034f4:	004b2503          	lw	a0,4(s6)
    800034f8:	000a849b          	sext.w	s1,s5
    800034fc:	8662                	mv	a2,s8
    800034fe:	faa4fde3          	bgeu	s1,a0,800034b8 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003502:	41f6579b          	sraiw	a5,a2,0x1f
    80003506:	01d7d69b          	srliw	a3,a5,0x1d
    8000350a:	00c6873b          	addw	a4,a3,a2
    8000350e:	00777793          	andi	a5,a4,7
    80003512:	9f95                	subw	a5,a5,a3
    80003514:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003518:	4037571b          	sraiw	a4,a4,0x3
    8000351c:	00e906b3          	add	a3,s2,a4
    80003520:	0586c683          	lbu	a3,88(a3)
    80003524:	00d7f5b3          	and	a1,a5,a3
    80003528:	d195                	beqz	a1,8000344c <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000352a:	2605                	addiw	a2,a2,1
    8000352c:	2485                	addiw	s1,s1,1
    8000352e:	fd4618e3          	bne	a2,s4,800034fe <balloc+0xee>
    80003532:	b759                	j	800034b8 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003534:	00005517          	auipc	a0,0x5
    80003538:	22450513          	addi	a0,a0,548 # 80008758 <syscalls+0x238>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	04c080e7          	jalr	76(ra) # 80000588 <printf>
  return 0;
    80003544:	4481                	li	s1,0
    80003546:	bf99                	j	8000349c <balloc+0x8c>

0000000080003548 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003548:	7179                	addi	sp,sp,-48
    8000354a:	f406                	sd	ra,40(sp)
    8000354c:	f022                	sd	s0,32(sp)
    8000354e:	ec26                	sd	s1,24(sp)
    80003550:	e84a                	sd	s2,16(sp)
    80003552:	e44e                	sd	s3,8(sp)
    80003554:	e052                	sd	s4,0(sp)
    80003556:	1800                	addi	s0,sp,48
    80003558:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000355a:	47ad                	li	a5,11
    8000355c:	02b7e763          	bltu	a5,a1,8000358a <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003560:	02059493          	slli	s1,a1,0x20
    80003564:	9081                	srli	s1,s1,0x20
    80003566:	048a                	slli	s1,s1,0x2
    80003568:	94aa                	add	s1,s1,a0
    8000356a:	0504a903          	lw	s2,80(s1)
    8000356e:	06091e63          	bnez	s2,800035ea <bmap+0xa2>
      addr = balloc(ip->dev);
    80003572:	4108                	lw	a0,0(a0)
    80003574:	00000097          	auipc	ra,0x0
    80003578:	e9c080e7          	jalr	-356(ra) # 80003410 <balloc>
    8000357c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003580:	06090563          	beqz	s2,800035ea <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003584:	0524a823          	sw	s2,80(s1)
    80003588:	a08d                	j	800035ea <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000358a:	ff45849b          	addiw	s1,a1,-12
    8000358e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003592:	0ff00793          	li	a5,255
    80003596:	08e7e563          	bltu	a5,a4,80003620 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000359a:	08052903          	lw	s2,128(a0)
    8000359e:	00091d63          	bnez	s2,800035b8 <bmap+0x70>
      addr = balloc(ip->dev);
    800035a2:	4108                	lw	a0,0(a0)
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	e6c080e7          	jalr	-404(ra) # 80003410 <balloc>
    800035ac:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800035b0:	02090d63          	beqz	s2,800035ea <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800035b4:	0929a023          	sw	s2,128(s3) # 12c080 <_entry-0x7fed3f80>
    }
    bp = bread(ip->dev, addr);
    800035b8:	85ca                	mv	a1,s2
    800035ba:	0009a503          	lw	a0,0(s3)
    800035be:	00000097          	auipc	ra,0x0
    800035c2:	b90080e7          	jalr	-1136(ra) # 8000314e <bread>
    800035c6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035c8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035cc:	02049593          	slli	a1,s1,0x20
    800035d0:	9181                	srli	a1,a1,0x20
    800035d2:	058a                	slli	a1,a1,0x2
    800035d4:	00b784b3          	add	s1,a5,a1
    800035d8:	0004a903          	lw	s2,0(s1)
    800035dc:	02090063          	beqz	s2,800035fc <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800035e0:	8552                	mv	a0,s4
    800035e2:	00000097          	auipc	ra,0x0
    800035e6:	c9c080e7          	jalr	-868(ra) # 8000327e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035ea:	854a                	mv	a0,s2
    800035ec:	70a2                	ld	ra,40(sp)
    800035ee:	7402                	ld	s0,32(sp)
    800035f0:	64e2                	ld	s1,24(sp)
    800035f2:	6942                	ld	s2,16(sp)
    800035f4:	69a2                	ld	s3,8(sp)
    800035f6:	6a02                	ld	s4,0(sp)
    800035f8:	6145                	addi	sp,sp,48
    800035fa:	8082                	ret
      addr = balloc(ip->dev);
    800035fc:	0009a503          	lw	a0,0(s3)
    80003600:	00000097          	auipc	ra,0x0
    80003604:	e10080e7          	jalr	-496(ra) # 80003410 <balloc>
    80003608:	0005091b          	sext.w	s2,a0
      if(addr){
    8000360c:	fc090ae3          	beqz	s2,800035e0 <bmap+0x98>
        a[bn] = addr;
    80003610:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003614:	8552                	mv	a0,s4
    80003616:	00001097          	auipc	ra,0x1
    8000361a:	eec080e7          	jalr	-276(ra) # 80004502 <log_write>
    8000361e:	b7c9                	j	800035e0 <bmap+0x98>
  panic("bmap: out of range");
    80003620:	00005517          	auipc	a0,0x5
    80003624:	15050513          	addi	a0,a0,336 # 80008770 <syscalls+0x250>
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	f16080e7          	jalr	-234(ra) # 8000053e <panic>

0000000080003630 <iget>:
{
    80003630:	7179                	addi	sp,sp,-48
    80003632:	f406                	sd	ra,40(sp)
    80003634:	f022                	sd	s0,32(sp)
    80003636:	ec26                	sd	s1,24(sp)
    80003638:	e84a                	sd	s2,16(sp)
    8000363a:	e44e                	sd	s3,8(sp)
    8000363c:	e052                	sd	s4,0(sp)
    8000363e:	1800                	addi	s0,sp,48
    80003640:	89aa                	mv	s3,a0
    80003642:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003644:	0001c517          	auipc	a0,0x1c
    80003648:	7a450513          	addi	a0,a0,1956 # 8001fde8 <itable>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	58a080e7          	jalr	1418(ra) # 80000bd6 <acquire>
  empty = 0;
    80003654:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003656:	0001c497          	auipc	s1,0x1c
    8000365a:	7aa48493          	addi	s1,s1,1962 # 8001fe00 <itable+0x18>
    8000365e:	0001e697          	auipc	a3,0x1e
    80003662:	23268693          	addi	a3,a3,562 # 80021890 <log>
    80003666:	a039                	j	80003674 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003668:	02090b63          	beqz	s2,8000369e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000366c:	08848493          	addi	s1,s1,136
    80003670:	02d48a63          	beq	s1,a3,800036a4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003674:	449c                	lw	a5,8(s1)
    80003676:	fef059e3          	blez	a5,80003668 <iget+0x38>
    8000367a:	4098                	lw	a4,0(s1)
    8000367c:	ff3716e3          	bne	a4,s3,80003668 <iget+0x38>
    80003680:	40d8                	lw	a4,4(s1)
    80003682:	ff4713e3          	bne	a4,s4,80003668 <iget+0x38>
      ip->ref++;
    80003686:	2785                	addiw	a5,a5,1
    80003688:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000368a:	0001c517          	auipc	a0,0x1c
    8000368e:	75e50513          	addi	a0,a0,1886 # 8001fde8 <itable>
    80003692:	ffffd097          	auipc	ra,0xffffd
    80003696:	5f8080e7          	jalr	1528(ra) # 80000c8a <release>
      return ip;
    8000369a:	8926                	mv	s2,s1
    8000369c:	a03d                	j	800036ca <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000369e:	f7f9                	bnez	a5,8000366c <iget+0x3c>
    800036a0:	8926                	mv	s2,s1
    800036a2:	b7e9                	j	8000366c <iget+0x3c>
  if(empty == 0)
    800036a4:	02090c63          	beqz	s2,800036dc <iget+0xac>
  ip->dev = dev;
    800036a8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036ac:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036b0:	4785                	li	a5,1
    800036b2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036b6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036ba:	0001c517          	auipc	a0,0x1c
    800036be:	72e50513          	addi	a0,a0,1838 # 8001fde8 <itable>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	5c8080e7          	jalr	1480(ra) # 80000c8a <release>
}
    800036ca:	854a                	mv	a0,s2
    800036cc:	70a2                	ld	ra,40(sp)
    800036ce:	7402                	ld	s0,32(sp)
    800036d0:	64e2                	ld	s1,24(sp)
    800036d2:	6942                	ld	s2,16(sp)
    800036d4:	69a2                	ld	s3,8(sp)
    800036d6:	6a02                	ld	s4,0(sp)
    800036d8:	6145                	addi	sp,sp,48
    800036da:	8082                	ret
    panic("iget: no inodes");
    800036dc:	00005517          	auipc	a0,0x5
    800036e0:	0ac50513          	addi	a0,a0,172 # 80008788 <syscalls+0x268>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	e5a080e7          	jalr	-422(ra) # 8000053e <panic>

00000000800036ec <fsinit>:
fsinit(int dev) {
    800036ec:	7179                	addi	sp,sp,-48
    800036ee:	f406                	sd	ra,40(sp)
    800036f0:	f022                	sd	s0,32(sp)
    800036f2:	ec26                	sd	s1,24(sp)
    800036f4:	e84a                	sd	s2,16(sp)
    800036f6:	e44e                	sd	s3,8(sp)
    800036f8:	1800                	addi	s0,sp,48
    800036fa:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036fc:	4585                	li	a1,1
    800036fe:	00000097          	auipc	ra,0x0
    80003702:	a50080e7          	jalr	-1456(ra) # 8000314e <bread>
    80003706:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003708:	0001c997          	auipc	s3,0x1c
    8000370c:	6c098993          	addi	s3,s3,1728 # 8001fdc8 <sb>
    80003710:	02000613          	li	a2,32
    80003714:	05850593          	addi	a1,a0,88
    80003718:	854e                	mv	a0,s3
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	614080e7          	jalr	1556(ra) # 80000d2e <memmove>
  brelse(bp);
    80003722:	8526                	mv	a0,s1
    80003724:	00000097          	auipc	ra,0x0
    80003728:	b5a080e7          	jalr	-1190(ra) # 8000327e <brelse>
  if(sb.magic != FSMAGIC)
    8000372c:	0009a703          	lw	a4,0(s3)
    80003730:	102037b7          	lui	a5,0x10203
    80003734:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003738:	02f71263          	bne	a4,a5,8000375c <fsinit+0x70>
  initlog(dev, &sb);
    8000373c:	0001c597          	auipc	a1,0x1c
    80003740:	68c58593          	addi	a1,a1,1676 # 8001fdc8 <sb>
    80003744:	854a                	mv	a0,s2
    80003746:	00001097          	auipc	ra,0x1
    8000374a:	b40080e7          	jalr	-1216(ra) # 80004286 <initlog>
}
    8000374e:	70a2                	ld	ra,40(sp)
    80003750:	7402                	ld	s0,32(sp)
    80003752:	64e2                	ld	s1,24(sp)
    80003754:	6942                	ld	s2,16(sp)
    80003756:	69a2                	ld	s3,8(sp)
    80003758:	6145                	addi	sp,sp,48
    8000375a:	8082                	ret
    panic("invalid file system");
    8000375c:	00005517          	auipc	a0,0x5
    80003760:	03c50513          	addi	a0,a0,60 # 80008798 <syscalls+0x278>
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	dda080e7          	jalr	-550(ra) # 8000053e <panic>

000000008000376c <iinit>:
{
    8000376c:	7179                	addi	sp,sp,-48
    8000376e:	f406                	sd	ra,40(sp)
    80003770:	f022                	sd	s0,32(sp)
    80003772:	ec26                	sd	s1,24(sp)
    80003774:	e84a                	sd	s2,16(sp)
    80003776:	e44e                	sd	s3,8(sp)
    80003778:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000377a:	00005597          	auipc	a1,0x5
    8000377e:	03658593          	addi	a1,a1,54 # 800087b0 <syscalls+0x290>
    80003782:	0001c517          	auipc	a0,0x1c
    80003786:	66650513          	addi	a0,a0,1638 # 8001fde8 <itable>
    8000378a:	ffffd097          	auipc	ra,0xffffd
    8000378e:	3bc080e7          	jalr	956(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003792:	0001c497          	auipc	s1,0x1c
    80003796:	67e48493          	addi	s1,s1,1662 # 8001fe10 <itable+0x28>
    8000379a:	0001e997          	auipc	s3,0x1e
    8000379e:	10698993          	addi	s3,s3,262 # 800218a0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037a2:	00005917          	auipc	s2,0x5
    800037a6:	01690913          	addi	s2,s2,22 # 800087b8 <syscalls+0x298>
    800037aa:	85ca                	mv	a1,s2
    800037ac:	8526                	mv	a0,s1
    800037ae:	00001097          	auipc	ra,0x1
    800037b2:	e3a080e7          	jalr	-454(ra) # 800045e8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037b6:	08848493          	addi	s1,s1,136
    800037ba:	ff3498e3          	bne	s1,s3,800037aa <iinit+0x3e>
}
    800037be:	70a2                	ld	ra,40(sp)
    800037c0:	7402                	ld	s0,32(sp)
    800037c2:	64e2                	ld	s1,24(sp)
    800037c4:	6942                	ld	s2,16(sp)
    800037c6:	69a2                	ld	s3,8(sp)
    800037c8:	6145                	addi	sp,sp,48
    800037ca:	8082                	ret

00000000800037cc <ialloc>:
{
    800037cc:	715d                	addi	sp,sp,-80
    800037ce:	e486                	sd	ra,72(sp)
    800037d0:	e0a2                	sd	s0,64(sp)
    800037d2:	fc26                	sd	s1,56(sp)
    800037d4:	f84a                	sd	s2,48(sp)
    800037d6:	f44e                	sd	s3,40(sp)
    800037d8:	f052                	sd	s4,32(sp)
    800037da:	ec56                	sd	s5,24(sp)
    800037dc:	e85a                	sd	s6,16(sp)
    800037de:	e45e                	sd	s7,8(sp)
    800037e0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037e2:	0001c717          	auipc	a4,0x1c
    800037e6:	5f272703          	lw	a4,1522(a4) # 8001fdd4 <sb+0xc>
    800037ea:	4785                	li	a5,1
    800037ec:	04e7fa63          	bgeu	a5,a4,80003840 <ialloc+0x74>
    800037f0:	8aaa                	mv	s5,a0
    800037f2:	8bae                	mv	s7,a1
    800037f4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037f6:	0001ca17          	auipc	s4,0x1c
    800037fa:	5d2a0a13          	addi	s4,s4,1490 # 8001fdc8 <sb>
    800037fe:	00048b1b          	sext.w	s6,s1
    80003802:	0044d793          	srli	a5,s1,0x4
    80003806:	018a2583          	lw	a1,24(s4)
    8000380a:	9dbd                	addw	a1,a1,a5
    8000380c:	8556                	mv	a0,s5
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	940080e7          	jalr	-1728(ra) # 8000314e <bread>
    80003816:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003818:	05850993          	addi	s3,a0,88
    8000381c:	00f4f793          	andi	a5,s1,15
    80003820:	079a                	slli	a5,a5,0x6
    80003822:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003824:	00099783          	lh	a5,0(s3)
    80003828:	c3a1                	beqz	a5,80003868 <ialloc+0x9c>
    brelse(bp);
    8000382a:	00000097          	auipc	ra,0x0
    8000382e:	a54080e7          	jalr	-1452(ra) # 8000327e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003832:	0485                	addi	s1,s1,1
    80003834:	00ca2703          	lw	a4,12(s4)
    80003838:	0004879b          	sext.w	a5,s1
    8000383c:	fce7e1e3          	bltu	a5,a4,800037fe <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003840:	00005517          	auipc	a0,0x5
    80003844:	f8050513          	addi	a0,a0,-128 # 800087c0 <syscalls+0x2a0>
    80003848:	ffffd097          	auipc	ra,0xffffd
    8000384c:	d40080e7          	jalr	-704(ra) # 80000588 <printf>
  return 0;
    80003850:	4501                	li	a0,0
}
    80003852:	60a6                	ld	ra,72(sp)
    80003854:	6406                	ld	s0,64(sp)
    80003856:	74e2                	ld	s1,56(sp)
    80003858:	7942                	ld	s2,48(sp)
    8000385a:	79a2                	ld	s3,40(sp)
    8000385c:	7a02                	ld	s4,32(sp)
    8000385e:	6ae2                	ld	s5,24(sp)
    80003860:	6b42                	ld	s6,16(sp)
    80003862:	6ba2                	ld	s7,8(sp)
    80003864:	6161                	addi	sp,sp,80
    80003866:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003868:	04000613          	li	a2,64
    8000386c:	4581                	li	a1,0
    8000386e:	854e                	mv	a0,s3
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	462080e7          	jalr	1122(ra) # 80000cd2 <memset>
      dip->type = type;
    80003878:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000387c:	854a                	mv	a0,s2
    8000387e:	00001097          	auipc	ra,0x1
    80003882:	c84080e7          	jalr	-892(ra) # 80004502 <log_write>
      brelse(bp);
    80003886:	854a                	mv	a0,s2
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	9f6080e7          	jalr	-1546(ra) # 8000327e <brelse>
      return iget(dev, inum);
    80003890:	85da                	mv	a1,s6
    80003892:	8556                	mv	a0,s5
    80003894:	00000097          	auipc	ra,0x0
    80003898:	d9c080e7          	jalr	-612(ra) # 80003630 <iget>
    8000389c:	bf5d                	j	80003852 <ialloc+0x86>

000000008000389e <iupdate>:
{
    8000389e:	1101                	addi	sp,sp,-32
    800038a0:	ec06                	sd	ra,24(sp)
    800038a2:	e822                	sd	s0,16(sp)
    800038a4:	e426                	sd	s1,8(sp)
    800038a6:	e04a                	sd	s2,0(sp)
    800038a8:	1000                	addi	s0,sp,32
    800038aa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038ac:	415c                	lw	a5,4(a0)
    800038ae:	0047d79b          	srliw	a5,a5,0x4
    800038b2:	0001c597          	auipc	a1,0x1c
    800038b6:	52e5a583          	lw	a1,1326(a1) # 8001fde0 <sb+0x18>
    800038ba:	9dbd                	addw	a1,a1,a5
    800038bc:	4108                	lw	a0,0(a0)
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	890080e7          	jalr	-1904(ra) # 8000314e <bread>
    800038c6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038c8:	05850793          	addi	a5,a0,88
    800038cc:	40c8                	lw	a0,4(s1)
    800038ce:	893d                	andi	a0,a0,15
    800038d0:	051a                	slli	a0,a0,0x6
    800038d2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038d4:	04449703          	lh	a4,68(s1)
    800038d8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038dc:	04649703          	lh	a4,70(s1)
    800038e0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038e4:	04849703          	lh	a4,72(s1)
    800038e8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038ec:	04a49703          	lh	a4,74(s1)
    800038f0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038f4:	44f8                	lw	a4,76(s1)
    800038f6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038f8:	03400613          	li	a2,52
    800038fc:	05048593          	addi	a1,s1,80
    80003900:	0531                	addi	a0,a0,12
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	42c080e7          	jalr	1068(ra) # 80000d2e <memmove>
  log_write(bp);
    8000390a:	854a                	mv	a0,s2
    8000390c:	00001097          	auipc	ra,0x1
    80003910:	bf6080e7          	jalr	-1034(ra) # 80004502 <log_write>
  brelse(bp);
    80003914:	854a                	mv	a0,s2
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	968080e7          	jalr	-1688(ra) # 8000327e <brelse>
}
    8000391e:	60e2                	ld	ra,24(sp)
    80003920:	6442                	ld	s0,16(sp)
    80003922:	64a2                	ld	s1,8(sp)
    80003924:	6902                	ld	s2,0(sp)
    80003926:	6105                	addi	sp,sp,32
    80003928:	8082                	ret

000000008000392a <idup>:
{
    8000392a:	1101                	addi	sp,sp,-32
    8000392c:	ec06                	sd	ra,24(sp)
    8000392e:	e822                	sd	s0,16(sp)
    80003930:	e426                	sd	s1,8(sp)
    80003932:	1000                	addi	s0,sp,32
    80003934:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003936:	0001c517          	auipc	a0,0x1c
    8000393a:	4b250513          	addi	a0,a0,1202 # 8001fde8 <itable>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	298080e7          	jalr	664(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003946:	449c                	lw	a5,8(s1)
    80003948:	2785                	addiw	a5,a5,1
    8000394a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000394c:	0001c517          	auipc	a0,0x1c
    80003950:	49c50513          	addi	a0,a0,1180 # 8001fde8 <itable>
    80003954:	ffffd097          	auipc	ra,0xffffd
    80003958:	336080e7          	jalr	822(ra) # 80000c8a <release>
}
    8000395c:	8526                	mv	a0,s1
    8000395e:	60e2                	ld	ra,24(sp)
    80003960:	6442                	ld	s0,16(sp)
    80003962:	64a2                	ld	s1,8(sp)
    80003964:	6105                	addi	sp,sp,32
    80003966:	8082                	ret

0000000080003968 <ilock>:
{
    80003968:	1101                	addi	sp,sp,-32
    8000396a:	ec06                	sd	ra,24(sp)
    8000396c:	e822                	sd	s0,16(sp)
    8000396e:	e426                	sd	s1,8(sp)
    80003970:	e04a                	sd	s2,0(sp)
    80003972:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003974:	c115                	beqz	a0,80003998 <ilock+0x30>
    80003976:	84aa                	mv	s1,a0
    80003978:	451c                	lw	a5,8(a0)
    8000397a:	00f05f63          	blez	a5,80003998 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000397e:	0541                	addi	a0,a0,16
    80003980:	00001097          	auipc	ra,0x1
    80003984:	ca2080e7          	jalr	-862(ra) # 80004622 <acquiresleep>
  if(ip->valid == 0){
    80003988:	40bc                	lw	a5,64(s1)
    8000398a:	cf99                	beqz	a5,800039a8 <ilock+0x40>
}
    8000398c:	60e2                	ld	ra,24(sp)
    8000398e:	6442                	ld	s0,16(sp)
    80003990:	64a2                	ld	s1,8(sp)
    80003992:	6902                	ld	s2,0(sp)
    80003994:	6105                	addi	sp,sp,32
    80003996:	8082                	ret
    panic("ilock");
    80003998:	00005517          	auipc	a0,0x5
    8000399c:	e4050513          	addi	a0,a0,-448 # 800087d8 <syscalls+0x2b8>
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	b9e080e7          	jalr	-1122(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039a8:	40dc                	lw	a5,4(s1)
    800039aa:	0047d79b          	srliw	a5,a5,0x4
    800039ae:	0001c597          	auipc	a1,0x1c
    800039b2:	4325a583          	lw	a1,1074(a1) # 8001fde0 <sb+0x18>
    800039b6:	9dbd                	addw	a1,a1,a5
    800039b8:	4088                	lw	a0,0(s1)
    800039ba:	fffff097          	auipc	ra,0xfffff
    800039be:	794080e7          	jalr	1940(ra) # 8000314e <bread>
    800039c2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039c4:	05850593          	addi	a1,a0,88
    800039c8:	40dc                	lw	a5,4(s1)
    800039ca:	8bbd                	andi	a5,a5,15
    800039cc:	079a                	slli	a5,a5,0x6
    800039ce:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039d0:	00059783          	lh	a5,0(a1)
    800039d4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039d8:	00259783          	lh	a5,2(a1)
    800039dc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039e0:	00459783          	lh	a5,4(a1)
    800039e4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039e8:	00659783          	lh	a5,6(a1)
    800039ec:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039f0:	459c                	lw	a5,8(a1)
    800039f2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039f4:	03400613          	li	a2,52
    800039f8:	05b1                	addi	a1,a1,12
    800039fa:	05048513          	addi	a0,s1,80
    800039fe:	ffffd097          	auipc	ra,0xffffd
    80003a02:	330080e7          	jalr	816(ra) # 80000d2e <memmove>
    brelse(bp);
    80003a06:	854a                	mv	a0,s2
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	876080e7          	jalr	-1930(ra) # 8000327e <brelse>
    ip->valid = 1;
    80003a10:	4785                	li	a5,1
    80003a12:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a14:	04449783          	lh	a5,68(s1)
    80003a18:	fbb5                	bnez	a5,8000398c <ilock+0x24>
      panic("ilock: no type");
    80003a1a:	00005517          	auipc	a0,0x5
    80003a1e:	dc650513          	addi	a0,a0,-570 # 800087e0 <syscalls+0x2c0>
    80003a22:	ffffd097          	auipc	ra,0xffffd
    80003a26:	b1c080e7          	jalr	-1252(ra) # 8000053e <panic>

0000000080003a2a <iunlock>:
{
    80003a2a:	1101                	addi	sp,sp,-32
    80003a2c:	ec06                	sd	ra,24(sp)
    80003a2e:	e822                	sd	s0,16(sp)
    80003a30:	e426                	sd	s1,8(sp)
    80003a32:	e04a                	sd	s2,0(sp)
    80003a34:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a36:	c905                	beqz	a0,80003a66 <iunlock+0x3c>
    80003a38:	84aa                	mv	s1,a0
    80003a3a:	01050913          	addi	s2,a0,16
    80003a3e:	854a                	mv	a0,s2
    80003a40:	00001097          	auipc	ra,0x1
    80003a44:	c7c080e7          	jalr	-900(ra) # 800046bc <holdingsleep>
    80003a48:	cd19                	beqz	a0,80003a66 <iunlock+0x3c>
    80003a4a:	449c                	lw	a5,8(s1)
    80003a4c:	00f05d63          	blez	a5,80003a66 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a50:	854a                	mv	a0,s2
    80003a52:	00001097          	auipc	ra,0x1
    80003a56:	c26080e7          	jalr	-986(ra) # 80004678 <releasesleep>
}
    80003a5a:	60e2                	ld	ra,24(sp)
    80003a5c:	6442                	ld	s0,16(sp)
    80003a5e:	64a2                	ld	s1,8(sp)
    80003a60:	6902                	ld	s2,0(sp)
    80003a62:	6105                	addi	sp,sp,32
    80003a64:	8082                	ret
    panic("iunlock");
    80003a66:	00005517          	auipc	a0,0x5
    80003a6a:	d8a50513          	addi	a0,a0,-630 # 800087f0 <syscalls+0x2d0>
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>

0000000080003a76 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a76:	7179                	addi	sp,sp,-48
    80003a78:	f406                	sd	ra,40(sp)
    80003a7a:	f022                	sd	s0,32(sp)
    80003a7c:	ec26                	sd	s1,24(sp)
    80003a7e:	e84a                	sd	s2,16(sp)
    80003a80:	e44e                	sd	s3,8(sp)
    80003a82:	e052                	sd	s4,0(sp)
    80003a84:	1800                	addi	s0,sp,48
    80003a86:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a88:	05050493          	addi	s1,a0,80
    80003a8c:	08050913          	addi	s2,a0,128
    80003a90:	a021                	j	80003a98 <itrunc+0x22>
    80003a92:	0491                	addi	s1,s1,4
    80003a94:	01248d63          	beq	s1,s2,80003aae <itrunc+0x38>
    if(ip->addrs[i]){
    80003a98:	408c                	lw	a1,0(s1)
    80003a9a:	dde5                	beqz	a1,80003a92 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a9c:	0009a503          	lw	a0,0(s3)
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	8f4080e7          	jalr	-1804(ra) # 80003394 <bfree>
      ip->addrs[i] = 0;
    80003aa8:	0004a023          	sw	zero,0(s1)
    80003aac:	b7dd                	j	80003a92 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003aae:	0809a583          	lw	a1,128(s3)
    80003ab2:	e185                	bnez	a1,80003ad2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ab4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ab8:	854e                	mv	a0,s3
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	de4080e7          	jalr	-540(ra) # 8000389e <iupdate>
}
    80003ac2:	70a2                	ld	ra,40(sp)
    80003ac4:	7402                	ld	s0,32(sp)
    80003ac6:	64e2                	ld	s1,24(sp)
    80003ac8:	6942                	ld	s2,16(sp)
    80003aca:	69a2                	ld	s3,8(sp)
    80003acc:	6a02                	ld	s4,0(sp)
    80003ace:	6145                	addi	sp,sp,48
    80003ad0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ad2:	0009a503          	lw	a0,0(s3)
    80003ad6:	fffff097          	auipc	ra,0xfffff
    80003ada:	678080e7          	jalr	1656(ra) # 8000314e <bread>
    80003ade:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ae0:	05850493          	addi	s1,a0,88
    80003ae4:	45850913          	addi	s2,a0,1112
    80003ae8:	a021                	j	80003af0 <itrunc+0x7a>
    80003aea:	0491                	addi	s1,s1,4
    80003aec:	01248b63          	beq	s1,s2,80003b02 <itrunc+0x8c>
      if(a[j])
    80003af0:	408c                	lw	a1,0(s1)
    80003af2:	dde5                	beqz	a1,80003aea <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003af4:	0009a503          	lw	a0,0(s3)
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	89c080e7          	jalr	-1892(ra) # 80003394 <bfree>
    80003b00:	b7ed                	j	80003aea <itrunc+0x74>
    brelse(bp);
    80003b02:	8552                	mv	a0,s4
    80003b04:	fffff097          	auipc	ra,0xfffff
    80003b08:	77a080e7          	jalr	1914(ra) # 8000327e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b0c:	0809a583          	lw	a1,128(s3)
    80003b10:	0009a503          	lw	a0,0(s3)
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	880080e7          	jalr	-1920(ra) # 80003394 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b1c:	0809a023          	sw	zero,128(s3)
    80003b20:	bf51                	j	80003ab4 <itrunc+0x3e>

0000000080003b22 <iput>:
{
    80003b22:	1101                	addi	sp,sp,-32
    80003b24:	ec06                	sd	ra,24(sp)
    80003b26:	e822                	sd	s0,16(sp)
    80003b28:	e426                	sd	s1,8(sp)
    80003b2a:	e04a                	sd	s2,0(sp)
    80003b2c:	1000                	addi	s0,sp,32
    80003b2e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b30:	0001c517          	auipc	a0,0x1c
    80003b34:	2b850513          	addi	a0,a0,696 # 8001fde8 <itable>
    80003b38:	ffffd097          	auipc	ra,0xffffd
    80003b3c:	09e080e7          	jalr	158(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b40:	4498                	lw	a4,8(s1)
    80003b42:	4785                	li	a5,1
    80003b44:	02f70363          	beq	a4,a5,80003b6a <iput+0x48>
  ip->ref--;
    80003b48:	449c                	lw	a5,8(s1)
    80003b4a:	37fd                	addiw	a5,a5,-1
    80003b4c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b4e:	0001c517          	auipc	a0,0x1c
    80003b52:	29a50513          	addi	a0,a0,666 # 8001fde8 <itable>
    80003b56:	ffffd097          	auipc	ra,0xffffd
    80003b5a:	134080e7          	jalr	308(ra) # 80000c8a <release>
}
    80003b5e:	60e2                	ld	ra,24(sp)
    80003b60:	6442                	ld	s0,16(sp)
    80003b62:	64a2                	ld	s1,8(sp)
    80003b64:	6902                	ld	s2,0(sp)
    80003b66:	6105                	addi	sp,sp,32
    80003b68:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b6a:	40bc                	lw	a5,64(s1)
    80003b6c:	dff1                	beqz	a5,80003b48 <iput+0x26>
    80003b6e:	04a49783          	lh	a5,74(s1)
    80003b72:	fbf9                	bnez	a5,80003b48 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b74:	01048913          	addi	s2,s1,16
    80003b78:	854a                	mv	a0,s2
    80003b7a:	00001097          	auipc	ra,0x1
    80003b7e:	aa8080e7          	jalr	-1368(ra) # 80004622 <acquiresleep>
    release(&itable.lock);
    80003b82:	0001c517          	auipc	a0,0x1c
    80003b86:	26650513          	addi	a0,a0,614 # 8001fde8 <itable>
    80003b8a:	ffffd097          	auipc	ra,0xffffd
    80003b8e:	100080e7          	jalr	256(ra) # 80000c8a <release>
    itrunc(ip);
    80003b92:	8526                	mv	a0,s1
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	ee2080e7          	jalr	-286(ra) # 80003a76 <itrunc>
    ip->type = 0;
    80003b9c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ba0:	8526                	mv	a0,s1
    80003ba2:	00000097          	auipc	ra,0x0
    80003ba6:	cfc080e7          	jalr	-772(ra) # 8000389e <iupdate>
    ip->valid = 0;
    80003baa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bae:	854a                	mv	a0,s2
    80003bb0:	00001097          	auipc	ra,0x1
    80003bb4:	ac8080e7          	jalr	-1336(ra) # 80004678 <releasesleep>
    acquire(&itable.lock);
    80003bb8:	0001c517          	auipc	a0,0x1c
    80003bbc:	23050513          	addi	a0,a0,560 # 8001fde8 <itable>
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	016080e7          	jalr	22(ra) # 80000bd6 <acquire>
    80003bc8:	b741                	j	80003b48 <iput+0x26>

0000000080003bca <iunlockput>:
{
    80003bca:	1101                	addi	sp,sp,-32
    80003bcc:	ec06                	sd	ra,24(sp)
    80003bce:	e822                	sd	s0,16(sp)
    80003bd0:	e426                	sd	s1,8(sp)
    80003bd2:	1000                	addi	s0,sp,32
    80003bd4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bd6:	00000097          	auipc	ra,0x0
    80003bda:	e54080e7          	jalr	-428(ra) # 80003a2a <iunlock>
  iput(ip);
    80003bde:	8526                	mv	a0,s1
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	f42080e7          	jalr	-190(ra) # 80003b22 <iput>
}
    80003be8:	60e2                	ld	ra,24(sp)
    80003bea:	6442                	ld	s0,16(sp)
    80003bec:	64a2                	ld	s1,8(sp)
    80003bee:	6105                	addi	sp,sp,32
    80003bf0:	8082                	ret

0000000080003bf2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bf2:	1141                	addi	sp,sp,-16
    80003bf4:	e422                	sd	s0,8(sp)
    80003bf6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bf8:	411c                	lw	a5,0(a0)
    80003bfa:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bfc:	415c                	lw	a5,4(a0)
    80003bfe:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c00:	04451783          	lh	a5,68(a0)
    80003c04:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c08:	04a51783          	lh	a5,74(a0)
    80003c0c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c10:	04c56783          	lwu	a5,76(a0)
    80003c14:	e99c                	sd	a5,16(a1)
}
    80003c16:	6422                	ld	s0,8(sp)
    80003c18:	0141                	addi	sp,sp,16
    80003c1a:	8082                	ret

0000000080003c1c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c1c:	457c                	lw	a5,76(a0)
    80003c1e:	0ed7e963          	bltu	a5,a3,80003d10 <readi+0xf4>
{
    80003c22:	7159                	addi	sp,sp,-112
    80003c24:	f486                	sd	ra,104(sp)
    80003c26:	f0a2                	sd	s0,96(sp)
    80003c28:	eca6                	sd	s1,88(sp)
    80003c2a:	e8ca                	sd	s2,80(sp)
    80003c2c:	e4ce                	sd	s3,72(sp)
    80003c2e:	e0d2                	sd	s4,64(sp)
    80003c30:	fc56                	sd	s5,56(sp)
    80003c32:	f85a                	sd	s6,48(sp)
    80003c34:	f45e                	sd	s7,40(sp)
    80003c36:	f062                	sd	s8,32(sp)
    80003c38:	ec66                	sd	s9,24(sp)
    80003c3a:	e86a                	sd	s10,16(sp)
    80003c3c:	e46e                	sd	s11,8(sp)
    80003c3e:	1880                	addi	s0,sp,112
    80003c40:	8b2a                	mv	s6,a0
    80003c42:	8bae                	mv	s7,a1
    80003c44:	8a32                	mv	s4,a2
    80003c46:	84b6                	mv	s1,a3
    80003c48:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c4a:	9f35                	addw	a4,a4,a3
    return 0;
    80003c4c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c4e:	0ad76063          	bltu	a4,a3,80003cee <readi+0xd2>
  if(off + n > ip->size)
    80003c52:	00e7f463          	bgeu	a5,a4,80003c5a <readi+0x3e>
    n = ip->size - off;
    80003c56:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c5a:	0a0a8963          	beqz	s5,80003d0c <readi+0xf0>
    80003c5e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c60:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c64:	5c7d                	li	s8,-1
    80003c66:	a82d                	j	80003ca0 <readi+0x84>
    80003c68:	020d1d93          	slli	s11,s10,0x20
    80003c6c:	020ddd93          	srli	s11,s11,0x20
    80003c70:	05890793          	addi	a5,s2,88
    80003c74:	86ee                	mv	a3,s11
    80003c76:	963e                	add	a2,a2,a5
    80003c78:	85d2                	mv	a1,s4
    80003c7a:	855e                	mv	a0,s7
    80003c7c:	fffff097          	auipc	ra,0xfffff
    80003c80:	8ae080e7          	jalr	-1874(ra) # 8000252a <either_copyout>
    80003c84:	05850d63          	beq	a0,s8,80003cde <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c88:	854a                	mv	a0,s2
    80003c8a:	fffff097          	auipc	ra,0xfffff
    80003c8e:	5f4080e7          	jalr	1524(ra) # 8000327e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c92:	013d09bb          	addw	s3,s10,s3
    80003c96:	009d04bb          	addw	s1,s10,s1
    80003c9a:	9a6e                	add	s4,s4,s11
    80003c9c:	0559f763          	bgeu	s3,s5,80003cea <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ca0:	00a4d59b          	srliw	a1,s1,0xa
    80003ca4:	855a                	mv	a0,s6
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	8a2080e7          	jalr	-1886(ra) # 80003548 <bmap>
    80003cae:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003cb2:	cd85                	beqz	a1,80003cea <readi+0xce>
    bp = bread(ip->dev, addr);
    80003cb4:	000b2503          	lw	a0,0(s6)
    80003cb8:	fffff097          	auipc	ra,0xfffff
    80003cbc:	496080e7          	jalr	1174(ra) # 8000314e <bread>
    80003cc0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cc2:	3ff4f613          	andi	a2,s1,1023
    80003cc6:	40cc87bb          	subw	a5,s9,a2
    80003cca:	413a873b          	subw	a4,s5,s3
    80003cce:	8d3e                	mv	s10,a5
    80003cd0:	2781                	sext.w	a5,a5
    80003cd2:	0007069b          	sext.w	a3,a4
    80003cd6:	f8f6f9e3          	bgeu	a3,a5,80003c68 <readi+0x4c>
    80003cda:	8d3a                	mv	s10,a4
    80003cdc:	b771                	j	80003c68 <readi+0x4c>
      brelse(bp);
    80003cde:	854a                	mv	a0,s2
    80003ce0:	fffff097          	auipc	ra,0xfffff
    80003ce4:	59e080e7          	jalr	1438(ra) # 8000327e <brelse>
      tot = -1;
    80003ce8:	59fd                	li	s3,-1
  }
  return tot;
    80003cea:	0009851b          	sext.w	a0,s3
}
    80003cee:	70a6                	ld	ra,104(sp)
    80003cf0:	7406                	ld	s0,96(sp)
    80003cf2:	64e6                	ld	s1,88(sp)
    80003cf4:	6946                	ld	s2,80(sp)
    80003cf6:	69a6                	ld	s3,72(sp)
    80003cf8:	6a06                	ld	s4,64(sp)
    80003cfa:	7ae2                	ld	s5,56(sp)
    80003cfc:	7b42                	ld	s6,48(sp)
    80003cfe:	7ba2                	ld	s7,40(sp)
    80003d00:	7c02                	ld	s8,32(sp)
    80003d02:	6ce2                	ld	s9,24(sp)
    80003d04:	6d42                	ld	s10,16(sp)
    80003d06:	6da2                	ld	s11,8(sp)
    80003d08:	6165                	addi	sp,sp,112
    80003d0a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d0c:	89d6                	mv	s3,s5
    80003d0e:	bff1                	j	80003cea <readi+0xce>
    return 0;
    80003d10:	4501                	li	a0,0
}
    80003d12:	8082                	ret

0000000080003d14 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d14:	457c                	lw	a5,76(a0)
    80003d16:	10d7e863          	bltu	a5,a3,80003e26 <writei+0x112>
{
    80003d1a:	7159                	addi	sp,sp,-112
    80003d1c:	f486                	sd	ra,104(sp)
    80003d1e:	f0a2                	sd	s0,96(sp)
    80003d20:	eca6                	sd	s1,88(sp)
    80003d22:	e8ca                	sd	s2,80(sp)
    80003d24:	e4ce                	sd	s3,72(sp)
    80003d26:	e0d2                	sd	s4,64(sp)
    80003d28:	fc56                	sd	s5,56(sp)
    80003d2a:	f85a                	sd	s6,48(sp)
    80003d2c:	f45e                	sd	s7,40(sp)
    80003d2e:	f062                	sd	s8,32(sp)
    80003d30:	ec66                	sd	s9,24(sp)
    80003d32:	e86a                	sd	s10,16(sp)
    80003d34:	e46e                	sd	s11,8(sp)
    80003d36:	1880                	addi	s0,sp,112
    80003d38:	8aaa                	mv	s5,a0
    80003d3a:	8bae                	mv	s7,a1
    80003d3c:	8a32                	mv	s4,a2
    80003d3e:	8936                	mv	s2,a3
    80003d40:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d42:	00e687bb          	addw	a5,a3,a4
    80003d46:	0ed7e263          	bltu	a5,a3,80003e2a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d4a:	00043737          	lui	a4,0x43
    80003d4e:	0ef76063          	bltu	a4,a5,80003e2e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d52:	0c0b0863          	beqz	s6,80003e22 <writei+0x10e>
    80003d56:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d58:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d5c:	5c7d                	li	s8,-1
    80003d5e:	a091                	j	80003da2 <writei+0x8e>
    80003d60:	020d1d93          	slli	s11,s10,0x20
    80003d64:	020ddd93          	srli	s11,s11,0x20
    80003d68:	05848793          	addi	a5,s1,88
    80003d6c:	86ee                	mv	a3,s11
    80003d6e:	8652                	mv	a2,s4
    80003d70:	85de                	mv	a1,s7
    80003d72:	953e                	add	a0,a0,a5
    80003d74:	fffff097          	auipc	ra,0xfffff
    80003d78:	80c080e7          	jalr	-2036(ra) # 80002580 <either_copyin>
    80003d7c:	07850263          	beq	a0,s8,80003de0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d80:	8526                	mv	a0,s1
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	780080e7          	jalr	1920(ra) # 80004502 <log_write>
    brelse(bp);
    80003d8a:	8526                	mv	a0,s1
    80003d8c:	fffff097          	auipc	ra,0xfffff
    80003d90:	4f2080e7          	jalr	1266(ra) # 8000327e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d94:	013d09bb          	addw	s3,s10,s3
    80003d98:	012d093b          	addw	s2,s10,s2
    80003d9c:	9a6e                	add	s4,s4,s11
    80003d9e:	0569f663          	bgeu	s3,s6,80003dea <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003da2:	00a9559b          	srliw	a1,s2,0xa
    80003da6:	8556                	mv	a0,s5
    80003da8:	fffff097          	auipc	ra,0xfffff
    80003dac:	7a0080e7          	jalr	1952(ra) # 80003548 <bmap>
    80003db0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003db4:	c99d                	beqz	a1,80003dea <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003db6:	000aa503          	lw	a0,0(s5)
    80003dba:	fffff097          	auipc	ra,0xfffff
    80003dbe:	394080e7          	jalr	916(ra) # 8000314e <bread>
    80003dc2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dc4:	3ff97513          	andi	a0,s2,1023
    80003dc8:	40ac87bb          	subw	a5,s9,a0
    80003dcc:	413b073b          	subw	a4,s6,s3
    80003dd0:	8d3e                	mv	s10,a5
    80003dd2:	2781                	sext.w	a5,a5
    80003dd4:	0007069b          	sext.w	a3,a4
    80003dd8:	f8f6f4e3          	bgeu	a3,a5,80003d60 <writei+0x4c>
    80003ddc:	8d3a                	mv	s10,a4
    80003dde:	b749                	j	80003d60 <writei+0x4c>
      brelse(bp);
    80003de0:	8526                	mv	a0,s1
    80003de2:	fffff097          	auipc	ra,0xfffff
    80003de6:	49c080e7          	jalr	1180(ra) # 8000327e <brelse>
  }

  if(off > ip->size)
    80003dea:	04caa783          	lw	a5,76(s5)
    80003dee:	0127f463          	bgeu	a5,s2,80003df6 <writei+0xe2>
    ip->size = off;
    80003df2:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003df6:	8556                	mv	a0,s5
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	aa6080e7          	jalr	-1370(ra) # 8000389e <iupdate>

  return tot;
    80003e00:	0009851b          	sext.w	a0,s3
}
    80003e04:	70a6                	ld	ra,104(sp)
    80003e06:	7406                	ld	s0,96(sp)
    80003e08:	64e6                	ld	s1,88(sp)
    80003e0a:	6946                	ld	s2,80(sp)
    80003e0c:	69a6                	ld	s3,72(sp)
    80003e0e:	6a06                	ld	s4,64(sp)
    80003e10:	7ae2                	ld	s5,56(sp)
    80003e12:	7b42                	ld	s6,48(sp)
    80003e14:	7ba2                	ld	s7,40(sp)
    80003e16:	7c02                	ld	s8,32(sp)
    80003e18:	6ce2                	ld	s9,24(sp)
    80003e1a:	6d42                	ld	s10,16(sp)
    80003e1c:	6da2                	ld	s11,8(sp)
    80003e1e:	6165                	addi	sp,sp,112
    80003e20:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e22:	89da                	mv	s3,s6
    80003e24:	bfc9                	j	80003df6 <writei+0xe2>
    return -1;
    80003e26:	557d                	li	a0,-1
}
    80003e28:	8082                	ret
    return -1;
    80003e2a:	557d                	li	a0,-1
    80003e2c:	bfe1                	j	80003e04 <writei+0xf0>
    return -1;
    80003e2e:	557d                	li	a0,-1
    80003e30:	bfd1                	j	80003e04 <writei+0xf0>

0000000080003e32 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e32:	1141                	addi	sp,sp,-16
    80003e34:	e406                	sd	ra,8(sp)
    80003e36:	e022                	sd	s0,0(sp)
    80003e38:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e3a:	4639                	li	a2,14
    80003e3c:	ffffd097          	auipc	ra,0xffffd
    80003e40:	f66080e7          	jalr	-154(ra) # 80000da2 <strncmp>
}
    80003e44:	60a2                	ld	ra,8(sp)
    80003e46:	6402                	ld	s0,0(sp)
    80003e48:	0141                	addi	sp,sp,16
    80003e4a:	8082                	ret

0000000080003e4c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e4c:	7139                	addi	sp,sp,-64
    80003e4e:	fc06                	sd	ra,56(sp)
    80003e50:	f822                	sd	s0,48(sp)
    80003e52:	f426                	sd	s1,40(sp)
    80003e54:	f04a                	sd	s2,32(sp)
    80003e56:	ec4e                	sd	s3,24(sp)
    80003e58:	e852                	sd	s4,16(sp)
    80003e5a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e5c:	04451703          	lh	a4,68(a0)
    80003e60:	4785                	li	a5,1
    80003e62:	00f71a63          	bne	a4,a5,80003e76 <dirlookup+0x2a>
    80003e66:	892a                	mv	s2,a0
    80003e68:	89ae                	mv	s3,a1
    80003e6a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6c:	457c                	lw	a5,76(a0)
    80003e6e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e70:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e72:	e79d                	bnez	a5,80003ea0 <dirlookup+0x54>
    80003e74:	a8a5                	j	80003eec <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e76:	00005517          	auipc	a0,0x5
    80003e7a:	98250513          	addi	a0,a0,-1662 # 800087f8 <syscalls+0x2d8>
    80003e7e:	ffffc097          	auipc	ra,0xffffc
    80003e82:	6c0080e7          	jalr	1728(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e86:	00005517          	auipc	a0,0x5
    80003e8a:	98a50513          	addi	a0,a0,-1654 # 80008810 <syscalls+0x2f0>
    80003e8e:	ffffc097          	auipc	ra,0xffffc
    80003e92:	6b0080e7          	jalr	1712(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e96:	24c1                	addiw	s1,s1,16
    80003e98:	04c92783          	lw	a5,76(s2)
    80003e9c:	04f4f763          	bgeu	s1,a5,80003eea <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea0:	4741                	li	a4,16
    80003ea2:	86a6                	mv	a3,s1
    80003ea4:	fc040613          	addi	a2,s0,-64
    80003ea8:	4581                	li	a1,0
    80003eaa:	854a                	mv	a0,s2
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	d70080e7          	jalr	-656(ra) # 80003c1c <readi>
    80003eb4:	47c1                	li	a5,16
    80003eb6:	fcf518e3          	bne	a0,a5,80003e86 <dirlookup+0x3a>
    if(de.inum == 0)
    80003eba:	fc045783          	lhu	a5,-64(s0)
    80003ebe:	dfe1                	beqz	a5,80003e96 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ec0:	fc240593          	addi	a1,s0,-62
    80003ec4:	854e                	mv	a0,s3
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	f6c080e7          	jalr	-148(ra) # 80003e32 <namecmp>
    80003ece:	f561                	bnez	a0,80003e96 <dirlookup+0x4a>
      if(poff)
    80003ed0:	000a0463          	beqz	s4,80003ed8 <dirlookup+0x8c>
        *poff = off;
    80003ed4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ed8:	fc045583          	lhu	a1,-64(s0)
    80003edc:	00092503          	lw	a0,0(s2)
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	750080e7          	jalr	1872(ra) # 80003630 <iget>
    80003ee8:	a011                	j	80003eec <dirlookup+0xa0>
  return 0;
    80003eea:	4501                	li	a0,0
}
    80003eec:	70e2                	ld	ra,56(sp)
    80003eee:	7442                	ld	s0,48(sp)
    80003ef0:	74a2                	ld	s1,40(sp)
    80003ef2:	7902                	ld	s2,32(sp)
    80003ef4:	69e2                	ld	s3,24(sp)
    80003ef6:	6a42                	ld	s4,16(sp)
    80003ef8:	6121                	addi	sp,sp,64
    80003efa:	8082                	ret

0000000080003efc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003efc:	711d                	addi	sp,sp,-96
    80003efe:	ec86                	sd	ra,88(sp)
    80003f00:	e8a2                	sd	s0,80(sp)
    80003f02:	e4a6                	sd	s1,72(sp)
    80003f04:	e0ca                	sd	s2,64(sp)
    80003f06:	fc4e                	sd	s3,56(sp)
    80003f08:	f852                	sd	s4,48(sp)
    80003f0a:	f456                	sd	s5,40(sp)
    80003f0c:	f05a                	sd	s6,32(sp)
    80003f0e:	ec5e                	sd	s7,24(sp)
    80003f10:	e862                	sd	s8,16(sp)
    80003f12:	e466                	sd	s9,8(sp)
    80003f14:	1080                	addi	s0,sp,96
    80003f16:	84aa                	mv	s1,a0
    80003f18:	8aae                	mv	s5,a1
    80003f1a:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f1c:	00054703          	lbu	a4,0(a0)
    80003f20:	02f00793          	li	a5,47
    80003f24:	02f70363          	beq	a4,a5,80003f4a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f28:	ffffe097          	auipc	ra,0xffffe
    80003f2c:	aba080e7          	jalr	-1350(ra) # 800019e2 <myproc>
    80003f30:	15053503          	ld	a0,336(a0)
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	9f6080e7          	jalr	-1546(ra) # 8000392a <idup>
    80003f3c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f3e:	02f00913          	li	s2,47
  len = path - s;
    80003f42:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f44:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f46:	4b85                	li	s7,1
    80003f48:	a865                	j	80004000 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f4a:	4585                	li	a1,1
    80003f4c:	4505                	li	a0,1
    80003f4e:	fffff097          	auipc	ra,0xfffff
    80003f52:	6e2080e7          	jalr	1762(ra) # 80003630 <iget>
    80003f56:	89aa                	mv	s3,a0
    80003f58:	b7dd                	j	80003f3e <namex+0x42>
      iunlockput(ip);
    80003f5a:	854e                	mv	a0,s3
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	c6e080e7          	jalr	-914(ra) # 80003bca <iunlockput>
      return 0;
    80003f64:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f66:	854e                	mv	a0,s3
    80003f68:	60e6                	ld	ra,88(sp)
    80003f6a:	6446                	ld	s0,80(sp)
    80003f6c:	64a6                	ld	s1,72(sp)
    80003f6e:	6906                	ld	s2,64(sp)
    80003f70:	79e2                	ld	s3,56(sp)
    80003f72:	7a42                	ld	s4,48(sp)
    80003f74:	7aa2                	ld	s5,40(sp)
    80003f76:	7b02                	ld	s6,32(sp)
    80003f78:	6be2                	ld	s7,24(sp)
    80003f7a:	6c42                	ld	s8,16(sp)
    80003f7c:	6ca2                	ld	s9,8(sp)
    80003f7e:	6125                	addi	sp,sp,96
    80003f80:	8082                	ret
      iunlock(ip);
    80003f82:	854e                	mv	a0,s3
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	aa6080e7          	jalr	-1370(ra) # 80003a2a <iunlock>
      return ip;
    80003f8c:	bfe9                	j	80003f66 <namex+0x6a>
      iunlockput(ip);
    80003f8e:	854e                	mv	a0,s3
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	c3a080e7          	jalr	-966(ra) # 80003bca <iunlockput>
      return 0;
    80003f98:	89e6                	mv	s3,s9
    80003f9a:	b7f1                	j	80003f66 <namex+0x6a>
  len = path - s;
    80003f9c:	40b48633          	sub	a2,s1,a1
    80003fa0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003fa4:	099c5463          	bge	s8,s9,8000402c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fa8:	4639                	li	a2,14
    80003faa:	8552                	mv	a0,s4
    80003fac:	ffffd097          	auipc	ra,0xffffd
    80003fb0:	d82080e7          	jalr	-638(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003fb4:	0004c783          	lbu	a5,0(s1)
    80003fb8:	01279763          	bne	a5,s2,80003fc6 <namex+0xca>
    path++;
    80003fbc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fbe:	0004c783          	lbu	a5,0(s1)
    80003fc2:	ff278de3          	beq	a5,s2,80003fbc <namex+0xc0>
    ilock(ip);
    80003fc6:	854e                	mv	a0,s3
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	9a0080e7          	jalr	-1632(ra) # 80003968 <ilock>
    if(ip->type != T_DIR){
    80003fd0:	04499783          	lh	a5,68(s3)
    80003fd4:	f97793e3          	bne	a5,s7,80003f5a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fd8:	000a8563          	beqz	s5,80003fe2 <namex+0xe6>
    80003fdc:	0004c783          	lbu	a5,0(s1)
    80003fe0:	d3cd                	beqz	a5,80003f82 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fe2:	865a                	mv	a2,s6
    80003fe4:	85d2                	mv	a1,s4
    80003fe6:	854e                	mv	a0,s3
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	e64080e7          	jalr	-412(ra) # 80003e4c <dirlookup>
    80003ff0:	8caa                	mv	s9,a0
    80003ff2:	dd51                	beqz	a0,80003f8e <namex+0x92>
    iunlockput(ip);
    80003ff4:	854e                	mv	a0,s3
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	bd4080e7          	jalr	-1068(ra) # 80003bca <iunlockput>
    ip = next;
    80003ffe:	89e6                	mv	s3,s9
  while(*path == '/')
    80004000:	0004c783          	lbu	a5,0(s1)
    80004004:	05279763          	bne	a5,s2,80004052 <namex+0x156>
    path++;
    80004008:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000400a:	0004c783          	lbu	a5,0(s1)
    8000400e:	ff278de3          	beq	a5,s2,80004008 <namex+0x10c>
  if(*path == 0)
    80004012:	c79d                	beqz	a5,80004040 <namex+0x144>
    path++;
    80004014:	85a6                	mv	a1,s1
  len = path - s;
    80004016:	8cda                	mv	s9,s6
    80004018:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000401a:	01278963          	beq	a5,s2,8000402c <namex+0x130>
    8000401e:	dfbd                	beqz	a5,80003f9c <namex+0xa0>
    path++;
    80004020:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004022:	0004c783          	lbu	a5,0(s1)
    80004026:	ff279ce3          	bne	a5,s2,8000401e <namex+0x122>
    8000402a:	bf8d                	j	80003f9c <namex+0xa0>
    memmove(name, s, len);
    8000402c:	2601                	sext.w	a2,a2
    8000402e:	8552                	mv	a0,s4
    80004030:	ffffd097          	auipc	ra,0xffffd
    80004034:	cfe080e7          	jalr	-770(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004038:	9cd2                	add	s9,s9,s4
    8000403a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000403e:	bf9d                	j	80003fb4 <namex+0xb8>
  if(nameiparent){
    80004040:	f20a83e3          	beqz	s5,80003f66 <namex+0x6a>
    iput(ip);
    80004044:	854e                	mv	a0,s3
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	adc080e7          	jalr	-1316(ra) # 80003b22 <iput>
    return 0;
    8000404e:	4981                	li	s3,0
    80004050:	bf19                	j	80003f66 <namex+0x6a>
  if(*path == 0)
    80004052:	d7fd                	beqz	a5,80004040 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004054:	0004c783          	lbu	a5,0(s1)
    80004058:	85a6                	mv	a1,s1
    8000405a:	b7d1                	j	8000401e <namex+0x122>

000000008000405c <dirlink>:
{
    8000405c:	7139                	addi	sp,sp,-64
    8000405e:	fc06                	sd	ra,56(sp)
    80004060:	f822                	sd	s0,48(sp)
    80004062:	f426                	sd	s1,40(sp)
    80004064:	f04a                	sd	s2,32(sp)
    80004066:	ec4e                	sd	s3,24(sp)
    80004068:	e852                	sd	s4,16(sp)
    8000406a:	0080                	addi	s0,sp,64
    8000406c:	892a                	mv	s2,a0
    8000406e:	8a2e                	mv	s4,a1
    80004070:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004072:	4601                	li	a2,0
    80004074:	00000097          	auipc	ra,0x0
    80004078:	dd8080e7          	jalr	-552(ra) # 80003e4c <dirlookup>
    8000407c:	e93d                	bnez	a0,800040f2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000407e:	04c92483          	lw	s1,76(s2)
    80004082:	c49d                	beqz	s1,800040b0 <dirlink+0x54>
    80004084:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004086:	4741                	li	a4,16
    80004088:	86a6                	mv	a3,s1
    8000408a:	fc040613          	addi	a2,s0,-64
    8000408e:	4581                	li	a1,0
    80004090:	854a                	mv	a0,s2
    80004092:	00000097          	auipc	ra,0x0
    80004096:	b8a080e7          	jalr	-1142(ra) # 80003c1c <readi>
    8000409a:	47c1                	li	a5,16
    8000409c:	06f51163          	bne	a0,a5,800040fe <dirlink+0xa2>
    if(de.inum == 0)
    800040a0:	fc045783          	lhu	a5,-64(s0)
    800040a4:	c791                	beqz	a5,800040b0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a6:	24c1                	addiw	s1,s1,16
    800040a8:	04c92783          	lw	a5,76(s2)
    800040ac:	fcf4ede3          	bltu	s1,a5,80004086 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040b0:	4639                	li	a2,14
    800040b2:	85d2                	mv	a1,s4
    800040b4:	fc240513          	addi	a0,s0,-62
    800040b8:	ffffd097          	auipc	ra,0xffffd
    800040bc:	d26080e7          	jalr	-730(ra) # 80000dde <strncpy>
  de.inum = inum;
    800040c0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040c4:	4741                	li	a4,16
    800040c6:	86a6                	mv	a3,s1
    800040c8:	fc040613          	addi	a2,s0,-64
    800040cc:	4581                	li	a1,0
    800040ce:	854a                	mv	a0,s2
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	c44080e7          	jalr	-956(ra) # 80003d14 <writei>
    800040d8:	1541                	addi	a0,a0,-16
    800040da:	00a03533          	snez	a0,a0
    800040de:	40a00533          	neg	a0,a0
}
    800040e2:	70e2                	ld	ra,56(sp)
    800040e4:	7442                	ld	s0,48(sp)
    800040e6:	74a2                	ld	s1,40(sp)
    800040e8:	7902                	ld	s2,32(sp)
    800040ea:	69e2                	ld	s3,24(sp)
    800040ec:	6a42                	ld	s4,16(sp)
    800040ee:	6121                	addi	sp,sp,64
    800040f0:	8082                	ret
    iput(ip);
    800040f2:	00000097          	auipc	ra,0x0
    800040f6:	a30080e7          	jalr	-1488(ra) # 80003b22 <iput>
    return -1;
    800040fa:	557d                	li	a0,-1
    800040fc:	b7dd                	j	800040e2 <dirlink+0x86>
      panic("dirlink read");
    800040fe:	00004517          	auipc	a0,0x4
    80004102:	72250513          	addi	a0,a0,1826 # 80008820 <syscalls+0x300>
    80004106:	ffffc097          	auipc	ra,0xffffc
    8000410a:	438080e7          	jalr	1080(ra) # 8000053e <panic>

000000008000410e <namei>:

struct inode*
namei(char *path)
{
    8000410e:	1101                	addi	sp,sp,-32
    80004110:	ec06                	sd	ra,24(sp)
    80004112:	e822                	sd	s0,16(sp)
    80004114:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004116:	fe040613          	addi	a2,s0,-32
    8000411a:	4581                	li	a1,0
    8000411c:	00000097          	auipc	ra,0x0
    80004120:	de0080e7          	jalr	-544(ra) # 80003efc <namex>
}
    80004124:	60e2                	ld	ra,24(sp)
    80004126:	6442                	ld	s0,16(sp)
    80004128:	6105                	addi	sp,sp,32
    8000412a:	8082                	ret

000000008000412c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000412c:	1141                	addi	sp,sp,-16
    8000412e:	e406                	sd	ra,8(sp)
    80004130:	e022                	sd	s0,0(sp)
    80004132:	0800                	addi	s0,sp,16
    80004134:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004136:	4585                	li	a1,1
    80004138:	00000097          	auipc	ra,0x0
    8000413c:	dc4080e7          	jalr	-572(ra) # 80003efc <namex>
}
    80004140:	60a2                	ld	ra,8(sp)
    80004142:	6402                	ld	s0,0(sp)
    80004144:	0141                	addi	sp,sp,16
    80004146:	8082                	ret

0000000080004148 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004148:	1101                	addi	sp,sp,-32
    8000414a:	ec06                	sd	ra,24(sp)
    8000414c:	e822                	sd	s0,16(sp)
    8000414e:	e426                	sd	s1,8(sp)
    80004150:	e04a                	sd	s2,0(sp)
    80004152:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004154:	0001d917          	auipc	s2,0x1d
    80004158:	73c90913          	addi	s2,s2,1852 # 80021890 <log>
    8000415c:	01892583          	lw	a1,24(s2)
    80004160:	02892503          	lw	a0,40(s2)
    80004164:	fffff097          	auipc	ra,0xfffff
    80004168:	fea080e7          	jalr	-22(ra) # 8000314e <bread>
    8000416c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000416e:	02c92683          	lw	a3,44(s2)
    80004172:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004174:	02d05763          	blez	a3,800041a2 <write_head+0x5a>
    80004178:	0001d797          	auipc	a5,0x1d
    8000417c:	74878793          	addi	a5,a5,1864 # 800218c0 <log+0x30>
    80004180:	05c50713          	addi	a4,a0,92
    80004184:	36fd                	addiw	a3,a3,-1
    80004186:	1682                	slli	a3,a3,0x20
    80004188:	9281                	srli	a3,a3,0x20
    8000418a:	068a                	slli	a3,a3,0x2
    8000418c:	0001d617          	auipc	a2,0x1d
    80004190:	73860613          	addi	a2,a2,1848 # 800218c4 <log+0x34>
    80004194:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004196:	4390                	lw	a2,0(a5)
    80004198:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000419a:	0791                	addi	a5,a5,4
    8000419c:	0711                	addi	a4,a4,4
    8000419e:	fed79ce3          	bne	a5,a3,80004196 <write_head+0x4e>
  }
  bwrite(buf);
    800041a2:	8526                	mv	a0,s1
    800041a4:	fffff097          	auipc	ra,0xfffff
    800041a8:	09c080e7          	jalr	156(ra) # 80003240 <bwrite>
  brelse(buf);
    800041ac:	8526                	mv	a0,s1
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	0d0080e7          	jalr	208(ra) # 8000327e <brelse>
}
    800041b6:	60e2                	ld	ra,24(sp)
    800041b8:	6442                	ld	s0,16(sp)
    800041ba:	64a2                	ld	s1,8(sp)
    800041bc:	6902                	ld	s2,0(sp)
    800041be:	6105                	addi	sp,sp,32
    800041c0:	8082                	ret

00000000800041c2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c2:	0001d797          	auipc	a5,0x1d
    800041c6:	6fa7a783          	lw	a5,1786(a5) # 800218bc <log+0x2c>
    800041ca:	0af05d63          	blez	a5,80004284 <install_trans+0xc2>
{
    800041ce:	7139                	addi	sp,sp,-64
    800041d0:	fc06                	sd	ra,56(sp)
    800041d2:	f822                	sd	s0,48(sp)
    800041d4:	f426                	sd	s1,40(sp)
    800041d6:	f04a                	sd	s2,32(sp)
    800041d8:	ec4e                	sd	s3,24(sp)
    800041da:	e852                	sd	s4,16(sp)
    800041dc:	e456                	sd	s5,8(sp)
    800041de:	e05a                	sd	s6,0(sp)
    800041e0:	0080                	addi	s0,sp,64
    800041e2:	8b2a                	mv	s6,a0
    800041e4:	0001da97          	auipc	s5,0x1d
    800041e8:	6dca8a93          	addi	s5,s5,1756 # 800218c0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ec:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041ee:	0001d997          	auipc	s3,0x1d
    800041f2:	6a298993          	addi	s3,s3,1698 # 80021890 <log>
    800041f6:	a00d                	j	80004218 <install_trans+0x56>
    brelse(lbuf);
    800041f8:	854a                	mv	a0,s2
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	084080e7          	jalr	132(ra) # 8000327e <brelse>
    brelse(dbuf);
    80004202:	8526                	mv	a0,s1
    80004204:	fffff097          	auipc	ra,0xfffff
    80004208:	07a080e7          	jalr	122(ra) # 8000327e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000420c:	2a05                	addiw	s4,s4,1
    8000420e:	0a91                	addi	s5,s5,4
    80004210:	02c9a783          	lw	a5,44(s3)
    80004214:	04fa5e63          	bge	s4,a5,80004270 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004218:	0189a583          	lw	a1,24(s3)
    8000421c:	014585bb          	addw	a1,a1,s4
    80004220:	2585                	addiw	a1,a1,1
    80004222:	0289a503          	lw	a0,40(s3)
    80004226:	fffff097          	auipc	ra,0xfffff
    8000422a:	f28080e7          	jalr	-216(ra) # 8000314e <bread>
    8000422e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004230:	000aa583          	lw	a1,0(s5)
    80004234:	0289a503          	lw	a0,40(s3)
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	f16080e7          	jalr	-234(ra) # 8000314e <bread>
    80004240:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004242:	40000613          	li	a2,1024
    80004246:	05890593          	addi	a1,s2,88
    8000424a:	05850513          	addi	a0,a0,88
    8000424e:	ffffd097          	auipc	ra,0xffffd
    80004252:	ae0080e7          	jalr	-1312(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004256:	8526                	mv	a0,s1
    80004258:	fffff097          	auipc	ra,0xfffff
    8000425c:	fe8080e7          	jalr	-24(ra) # 80003240 <bwrite>
    if(recovering == 0)
    80004260:	f80b1ce3          	bnez	s6,800041f8 <install_trans+0x36>
      bunpin(dbuf);
    80004264:	8526                	mv	a0,s1
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	0f2080e7          	jalr	242(ra) # 80003358 <bunpin>
    8000426e:	b769                	j	800041f8 <install_trans+0x36>
}
    80004270:	70e2                	ld	ra,56(sp)
    80004272:	7442                	ld	s0,48(sp)
    80004274:	74a2                	ld	s1,40(sp)
    80004276:	7902                	ld	s2,32(sp)
    80004278:	69e2                	ld	s3,24(sp)
    8000427a:	6a42                	ld	s4,16(sp)
    8000427c:	6aa2                	ld	s5,8(sp)
    8000427e:	6b02                	ld	s6,0(sp)
    80004280:	6121                	addi	sp,sp,64
    80004282:	8082                	ret
    80004284:	8082                	ret

0000000080004286 <initlog>:
{
    80004286:	7179                	addi	sp,sp,-48
    80004288:	f406                	sd	ra,40(sp)
    8000428a:	f022                	sd	s0,32(sp)
    8000428c:	ec26                	sd	s1,24(sp)
    8000428e:	e84a                	sd	s2,16(sp)
    80004290:	e44e                	sd	s3,8(sp)
    80004292:	1800                	addi	s0,sp,48
    80004294:	892a                	mv	s2,a0
    80004296:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004298:	0001d497          	auipc	s1,0x1d
    8000429c:	5f848493          	addi	s1,s1,1528 # 80021890 <log>
    800042a0:	00004597          	auipc	a1,0x4
    800042a4:	59058593          	addi	a1,a1,1424 # 80008830 <syscalls+0x310>
    800042a8:	8526                	mv	a0,s1
    800042aa:	ffffd097          	auipc	ra,0xffffd
    800042ae:	89c080e7          	jalr	-1892(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800042b2:	0149a583          	lw	a1,20(s3)
    800042b6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042b8:	0109a783          	lw	a5,16(s3)
    800042bc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042be:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042c2:	854a                	mv	a0,s2
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	e8a080e7          	jalr	-374(ra) # 8000314e <bread>
  log.lh.n = lh->n;
    800042cc:	4d34                	lw	a3,88(a0)
    800042ce:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042d0:	02d05563          	blez	a3,800042fa <initlog+0x74>
    800042d4:	05c50793          	addi	a5,a0,92
    800042d8:	0001d717          	auipc	a4,0x1d
    800042dc:	5e870713          	addi	a4,a4,1512 # 800218c0 <log+0x30>
    800042e0:	36fd                	addiw	a3,a3,-1
    800042e2:	1682                	slli	a3,a3,0x20
    800042e4:	9281                	srli	a3,a3,0x20
    800042e6:	068a                	slli	a3,a3,0x2
    800042e8:	06050613          	addi	a2,a0,96
    800042ec:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800042ee:	4390                	lw	a2,0(a5)
    800042f0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042f2:	0791                	addi	a5,a5,4
    800042f4:	0711                	addi	a4,a4,4
    800042f6:	fed79ce3          	bne	a5,a3,800042ee <initlog+0x68>
  brelse(buf);
    800042fa:	fffff097          	auipc	ra,0xfffff
    800042fe:	f84080e7          	jalr	-124(ra) # 8000327e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004302:	4505                	li	a0,1
    80004304:	00000097          	auipc	ra,0x0
    80004308:	ebe080e7          	jalr	-322(ra) # 800041c2 <install_trans>
  log.lh.n = 0;
    8000430c:	0001d797          	auipc	a5,0x1d
    80004310:	5a07a823          	sw	zero,1456(a5) # 800218bc <log+0x2c>
  write_head(); // clear the log
    80004314:	00000097          	auipc	ra,0x0
    80004318:	e34080e7          	jalr	-460(ra) # 80004148 <write_head>
}
    8000431c:	70a2                	ld	ra,40(sp)
    8000431e:	7402                	ld	s0,32(sp)
    80004320:	64e2                	ld	s1,24(sp)
    80004322:	6942                	ld	s2,16(sp)
    80004324:	69a2                	ld	s3,8(sp)
    80004326:	6145                	addi	sp,sp,48
    80004328:	8082                	ret

000000008000432a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000432a:	1101                	addi	sp,sp,-32
    8000432c:	ec06                	sd	ra,24(sp)
    8000432e:	e822                	sd	s0,16(sp)
    80004330:	e426                	sd	s1,8(sp)
    80004332:	e04a                	sd	s2,0(sp)
    80004334:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004336:	0001d517          	auipc	a0,0x1d
    8000433a:	55a50513          	addi	a0,a0,1370 # 80021890 <log>
    8000433e:	ffffd097          	auipc	ra,0xffffd
    80004342:	898080e7          	jalr	-1896(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004346:	0001d497          	auipc	s1,0x1d
    8000434a:	54a48493          	addi	s1,s1,1354 # 80021890 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000434e:	4979                	li	s2,30
    80004350:	a039                	j	8000435e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004352:	85a6                	mv	a1,s1
    80004354:	8526                	mv	a0,s1
    80004356:	ffffe097          	auipc	ra,0xffffe
    8000435a:	dcc080e7          	jalr	-564(ra) # 80002122 <sleep>
    if(log.committing){
    8000435e:	50dc                	lw	a5,36(s1)
    80004360:	fbed                	bnez	a5,80004352 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004362:	509c                	lw	a5,32(s1)
    80004364:	0017871b          	addiw	a4,a5,1
    80004368:	0007069b          	sext.w	a3,a4
    8000436c:	0027179b          	slliw	a5,a4,0x2
    80004370:	9fb9                	addw	a5,a5,a4
    80004372:	0017979b          	slliw	a5,a5,0x1
    80004376:	54d8                	lw	a4,44(s1)
    80004378:	9fb9                	addw	a5,a5,a4
    8000437a:	00f95963          	bge	s2,a5,8000438c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000437e:	85a6                	mv	a1,s1
    80004380:	8526                	mv	a0,s1
    80004382:	ffffe097          	auipc	ra,0xffffe
    80004386:	da0080e7          	jalr	-608(ra) # 80002122 <sleep>
    8000438a:	bfd1                	j	8000435e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000438c:	0001d517          	auipc	a0,0x1d
    80004390:	50450513          	addi	a0,a0,1284 # 80021890 <log>
    80004394:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	8f4080e7          	jalr	-1804(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000439e:	60e2                	ld	ra,24(sp)
    800043a0:	6442                	ld	s0,16(sp)
    800043a2:	64a2                	ld	s1,8(sp)
    800043a4:	6902                	ld	s2,0(sp)
    800043a6:	6105                	addi	sp,sp,32
    800043a8:	8082                	ret

00000000800043aa <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043aa:	7139                	addi	sp,sp,-64
    800043ac:	fc06                	sd	ra,56(sp)
    800043ae:	f822                	sd	s0,48(sp)
    800043b0:	f426                	sd	s1,40(sp)
    800043b2:	f04a                	sd	s2,32(sp)
    800043b4:	ec4e                	sd	s3,24(sp)
    800043b6:	e852                	sd	s4,16(sp)
    800043b8:	e456                	sd	s5,8(sp)
    800043ba:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043bc:	0001d497          	auipc	s1,0x1d
    800043c0:	4d448493          	addi	s1,s1,1236 # 80021890 <log>
    800043c4:	8526                	mv	a0,s1
    800043c6:	ffffd097          	auipc	ra,0xffffd
    800043ca:	810080e7          	jalr	-2032(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800043ce:	509c                	lw	a5,32(s1)
    800043d0:	37fd                	addiw	a5,a5,-1
    800043d2:	0007891b          	sext.w	s2,a5
    800043d6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043d8:	50dc                	lw	a5,36(s1)
    800043da:	e7b9                	bnez	a5,80004428 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043dc:	04091e63          	bnez	s2,80004438 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043e0:	0001d497          	auipc	s1,0x1d
    800043e4:	4b048493          	addi	s1,s1,1200 # 80021890 <log>
    800043e8:	4785                	li	a5,1
    800043ea:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043ec:	8526                	mv	a0,s1
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	89c080e7          	jalr	-1892(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043f6:	54dc                	lw	a5,44(s1)
    800043f8:	06f04763          	bgtz	a5,80004466 <end_op+0xbc>
    acquire(&log.lock);
    800043fc:	0001d497          	auipc	s1,0x1d
    80004400:	49448493          	addi	s1,s1,1172 # 80021890 <log>
    80004404:	8526                	mv	a0,s1
    80004406:	ffffc097          	auipc	ra,0xffffc
    8000440a:	7d0080e7          	jalr	2000(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000440e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004412:	8526                	mv	a0,s1
    80004414:	ffffe097          	auipc	ra,0xffffe
    80004418:	d72080e7          	jalr	-654(ra) # 80002186 <wakeup>
    release(&log.lock);
    8000441c:	8526                	mv	a0,s1
    8000441e:	ffffd097          	auipc	ra,0xffffd
    80004422:	86c080e7          	jalr	-1940(ra) # 80000c8a <release>
}
    80004426:	a03d                	j	80004454 <end_op+0xaa>
    panic("log.committing");
    80004428:	00004517          	auipc	a0,0x4
    8000442c:	41050513          	addi	a0,a0,1040 # 80008838 <syscalls+0x318>
    80004430:	ffffc097          	auipc	ra,0xffffc
    80004434:	10e080e7          	jalr	270(ra) # 8000053e <panic>
    wakeup(&log);
    80004438:	0001d497          	auipc	s1,0x1d
    8000443c:	45848493          	addi	s1,s1,1112 # 80021890 <log>
    80004440:	8526                	mv	a0,s1
    80004442:	ffffe097          	auipc	ra,0xffffe
    80004446:	d44080e7          	jalr	-700(ra) # 80002186 <wakeup>
  release(&log.lock);
    8000444a:	8526                	mv	a0,s1
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	83e080e7          	jalr	-1986(ra) # 80000c8a <release>
}
    80004454:	70e2                	ld	ra,56(sp)
    80004456:	7442                	ld	s0,48(sp)
    80004458:	74a2                	ld	s1,40(sp)
    8000445a:	7902                	ld	s2,32(sp)
    8000445c:	69e2                	ld	s3,24(sp)
    8000445e:	6a42                	ld	s4,16(sp)
    80004460:	6aa2                	ld	s5,8(sp)
    80004462:	6121                	addi	sp,sp,64
    80004464:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004466:	0001da97          	auipc	s5,0x1d
    8000446a:	45aa8a93          	addi	s5,s5,1114 # 800218c0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000446e:	0001da17          	auipc	s4,0x1d
    80004472:	422a0a13          	addi	s4,s4,1058 # 80021890 <log>
    80004476:	018a2583          	lw	a1,24(s4)
    8000447a:	012585bb          	addw	a1,a1,s2
    8000447e:	2585                	addiw	a1,a1,1
    80004480:	028a2503          	lw	a0,40(s4)
    80004484:	fffff097          	auipc	ra,0xfffff
    80004488:	cca080e7          	jalr	-822(ra) # 8000314e <bread>
    8000448c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000448e:	000aa583          	lw	a1,0(s5)
    80004492:	028a2503          	lw	a0,40(s4)
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	cb8080e7          	jalr	-840(ra) # 8000314e <bread>
    8000449e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044a0:	40000613          	li	a2,1024
    800044a4:	05850593          	addi	a1,a0,88
    800044a8:	05848513          	addi	a0,s1,88
    800044ac:	ffffd097          	auipc	ra,0xffffd
    800044b0:	882080e7          	jalr	-1918(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800044b4:	8526                	mv	a0,s1
    800044b6:	fffff097          	auipc	ra,0xfffff
    800044ba:	d8a080e7          	jalr	-630(ra) # 80003240 <bwrite>
    brelse(from);
    800044be:	854e                	mv	a0,s3
    800044c0:	fffff097          	auipc	ra,0xfffff
    800044c4:	dbe080e7          	jalr	-578(ra) # 8000327e <brelse>
    brelse(to);
    800044c8:	8526                	mv	a0,s1
    800044ca:	fffff097          	auipc	ra,0xfffff
    800044ce:	db4080e7          	jalr	-588(ra) # 8000327e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d2:	2905                	addiw	s2,s2,1
    800044d4:	0a91                	addi	s5,s5,4
    800044d6:	02ca2783          	lw	a5,44(s4)
    800044da:	f8f94ee3          	blt	s2,a5,80004476 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044de:	00000097          	auipc	ra,0x0
    800044e2:	c6a080e7          	jalr	-918(ra) # 80004148 <write_head>
    install_trans(0); // Now install writes to home locations
    800044e6:	4501                	li	a0,0
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	cda080e7          	jalr	-806(ra) # 800041c2 <install_trans>
    log.lh.n = 0;
    800044f0:	0001d797          	auipc	a5,0x1d
    800044f4:	3c07a623          	sw	zero,972(a5) # 800218bc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044f8:	00000097          	auipc	ra,0x0
    800044fc:	c50080e7          	jalr	-944(ra) # 80004148 <write_head>
    80004500:	bdf5                	j	800043fc <end_op+0x52>

0000000080004502 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004502:	1101                	addi	sp,sp,-32
    80004504:	ec06                	sd	ra,24(sp)
    80004506:	e822                	sd	s0,16(sp)
    80004508:	e426                	sd	s1,8(sp)
    8000450a:	e04a                	sd	s2,0(sp)
    8000450c:	1000                	addi	s0,sp,32
    8000450e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004510:	0001d917          	auipc	s2,0x1d
    80004514:	38090913          	addi	s2,s2,896 # 80021890 <log>
    80004518:	854a                	mv	a0,s2
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	6bc080e7          	jalr	1724(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004522:	02c92603          	lw	a2,44(s2)
    80004526:	47f5                	li	a5,29
    80004528:	06c7c563          	blt	a5,a2,80004592 <log_write+0x90>
    8000452c:	0001d797          	auipc	a5,0x1d
    80004530:	3807a783          	lw	a5,896(a5) # 800218ac <log+0x1c>
    80004534:	37fd                	addiw	a5,a5,-1
    80004536:	04f65e63          	bge	a2,a5,80004592 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000453a:	0001d797          	auipc	a5,0x1d
    8000453e:	3767a783          	lw	a5,886(a5) # 800218b0 <log+0x20>
    80004542:	06f05063          	blez	a5,800045a2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004546:	4781                	li	a5,0
    80004548:	06c05563          	blez	a2,800045b2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000454c:	44cc                	lw	a1,12(s1)
    8000454e:	0001d717          	auipc	a4,0x1d
    80004552:	37270713          	addi	a4,a4,882 # 800218c0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004556:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004558:	4314                	lw	a3,0(a4)
    8000455a:	04b68c63          	beq	a3,a1,800045b2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000455e:	2785                	addiw	a5,a5,1
    80004560:	0711                	addi	a4,a4,4
    80004562:	fef61be3          	bne	a2,a5,80004558 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004566:	0621                	addi	a2,a2,8
    80004568:	060a                	slli	a2,a2,0x2
    8000456a:	0001d797          	auipc	a5,0x1d
    8000456e:	32678793          	addi	a5,a5,806 # 80021890 <log>
    80004572:	963e                	add	a2,a2,a5
    80004574:	44dc                	lw	a5,12(s1)
    80004576:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004578:	8526                	mv	a0,s1
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	da2080e7          	jalr	-606(ra) # 8000331c <bpin>
    log.lh.n++;
    80004582:	0001d717          	auipc	a4,0x1d
    80004586:	30e70713          	addi	a4,a4,782 # 80021890 <log>
    8000458a:	575c                	lw	a5,44(a4)
    8000458c:	2785                	addiw	a5,a5,1
    8000458e:	d75c                	sw	a5,44(a4)
    80004590:	a835                	j	800045cc <log_write+0xca>
    panic("too big a transaction");
    80004592:	00004517          	auipc	a0,0x4
    80004596:	2b650513          	addi	a0,a0,694 # 80008848 <syscalls+0x328>
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	fa4080e7          	jalr	-92(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800045a2:	00004517          	auipc	a0,0x4
    800045a6:	2be50513          	addi	a0,a0,702 # 80008860 <syscalls+0x340>
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	f94080e7          	jalr	-108(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800045b2:	00878713          	addi	a4,a5,8
    800045b6:	00271693          	slli	a3,a4,0x2
    800045ba:	0001d717          	auipc	a4,0x1d
    800045be:	2d670713          	addi	a4,a4,726 # 80021890 <log>
    800045c2:	9736                	add	a4,a4,a3
    800045c4:	44d4                	lw	a3,12(s1)
    800045c6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045c8:	faf608e3          	beq	a2,a5,80004578 <log_write+0x76>
  }
  release(&log.lock);
    800045cc:	0001d517          	auipc	a0,0x1d
    800045d0:	2c450513          	addi	a0,a0,708 # 80021890 <log>
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	6b6080e7          	jalr	1718(ra) # 80000c8a <release>
}
    800045dc:	60e2                	ld	ra,24(sp)
    800045de:	6442                	ld	s0,16(sp)
    800045e0:	64a2                	ld	s1,8(sp)
    800045e2:	6902                	ld	s2,0(sp)
    800045e4:	6105                	addi	sp,sp,32
    800045e6:	8082                	ret

00000000800045e8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045e8:	1101                	addi	sp,sp,-32
    800045ea:	ec06                	sd	ra,24(sp)
    800045ec:	e822                	sd	s0,16(sp)
    800045ee:	e426                	sd	s1,8(sp)
    800045f0:	e04a                	sd	s2,0(sp)
    800045f2:	1000                	addi	s0,sp,32
    800045f4:	84aa                	mv	s1,a0
    800045f6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045f8:	00004597          	auipc	a1,0x4
    800045fc:	28858593          	addi	a1,a1,648 # 80008880 <syscalls+0x360>
    80004600:	0521                	addi	a0,a0,8
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	544080e7          	jalr	1348(ra) # 80000b46 <initlock>
  lk->name = name;
    8000460a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000460e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004612:	0204a423          	sw	zero,40(s1)
}
    80004616:	60e2                	ld	ra,24(sp)
    80004618:	6442                	ld	s0,16(sp)
    8000461a:	64a2                	ld	s1,8(sp)
    8000461c:	6902                	ld	s2,0(sp)
    8000461e:	6105                	addi	sp,sp,32
    80004620:	8082                	ret

0000000080004622 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004622:	1101                	addi	sp,sp,-32
    80004624:	ec06                	sd	ra,24(sp)
    80004626:	e822                	sd	s0,16(sp)
    80004628:	e426                	sd	s1,8(sp)
    8000462a:	e04a                	sd	s2,0(sp)
    8000462c:	1000                	addi	s0,sp,32
    8000462e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004630:	00850913          	addi	s2,a0,8
    80004634:	854a                	mv	a0,s2
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	5a0080e7          	jalr	1440(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000463e:	409c                	lw	a5,0(s1)
    80004640:	cb89                	beqz	a5,80004652 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004642:	85ca                	mv	a1,s2
    80004644:	8526                	mv	a0,s1
    80004646:	ffffe097          	auipc	ra,0xffffe
    8000464a:	adc080e7          	jalr	-1316(ra) # 80002122 <sleep>
  while (lk->locked) {
    8000464e:	409c                	lw	a5,0(s1)
    80004650:	fbed                	bnez	a5,80004642 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004652:	4785                	li	a5,1
    80004654:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004656:	ffffd097          	auipc	ra,0xffffd
    8000465a:	38c080e7          	jalr	908(ra) # 800019e2 <myproc>
    8000465e:	591c                	lw	a5,48(a0)
    80004660:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004662:	854a                	mv	a0,s2
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	626080e7          	jalr	1574(ra) # 80000c8a <release>
}
    8000466c:	60e2                	ld	ra,24(sp)
    8000466e:	6442                	ld	s0,16(sp)
    80004670:	64a2                	ld	s1,8(sp)
    80004672:	6902                	ld	s2,0(sp)
    80004674:	6105                	addi	sp,sp,32
    80004676:	8082                	ret

0000000080004678 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004678:	1101                	addi	sp,sp,-32
    8000467a:	ec06                	sd	ra,24(sp)
    8000467c:	e822                	sd	s0,16(sp)
    8000467e:	e426                	sd	s1,8(sp)
    80004680:	e04a                	sd	s2,0(sp)
    80004682:	1000                	addi	s0,sp,32
    80004684:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004686:	00850913          	addi	s2,a0,8
    8000468a:	854a                	mv	a0,s2
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	54a080e7          	jalr	1354(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004694:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004698:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000469c:	8526                	mv	a0,s1
    8000469e:	ffffe097          	auipc	ra,0xffffe
    800046a2:	ae8080e7          	jalr	-1304(ra) # 80002186 <wakeup>
  release(&lk->lk);
    800046a6:	854a                	mv	a0,s2
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	5e2080e7          	jalr	1506(ra) # 80000c8a <release>
}
    800046b0:	60e2                	ld	ra,24(sp)
    800046b2:	6442                	ld	s0,16(sp)
    800046b4:	64a2                	ld	s1,8(sp)
    800046b6:	6902                	ld	s2,0(sp)
    800046b8:	6105                	addi	sp,sp,32
    800046ba:	8082                	ret

00000000800046bc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046bc:	7179                	addi	sp,sp,-48
    800046be:	f406                	sd	ra,40(sp)
    800046c0:	f022                	sd	s0,32(sp)
    800046c2:	ec26                	sd	s1,24(sp)
    800046c4:	e84a                	sd	s2,16(sp)
    800046c6:	e44e                	sd	s3,8(sp)
    800046c8:	1800                	addi	s0,sp,48
    800046ca:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046cc:	00850913          	addi	s2,a0,8
    800046d0:	854a                	mv	a0,s2
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	504080e7          	jalr	1284(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046da:	409c                	lw	a5,0(s1)
    800046dc:	ef99                	bnez	a5,800046fa <holdingsleep+0x3e>
    800046de:	4481                	li	s1,0
  release(&lk->lk);
    800046e0:	854a                	mv	a0,s2
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	5a8080e7          	jalr	1448(ra) # 80000c8a <release>
  return r;
}
    800046ea:	8526                	mv	a0,s1
    800046ec:	70a2                	ld	ra,40(sp)
    800046ee:	7402                	ld	s0,32(sp)
    800046f0:	64e2                	ld	s1,24(sp)
    800046f2:	6942                	ld	s2,16(sp)
    800046f4:	69a2                	ld	s3,8(sp)
    800046f6:	6145                	addi	sp,sp,48
    800046f8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046fa:	0284a983          	lw	s3,40(s1)
    800046fe:	ffffd097          	auipc	ra,0xffffd
    80004702:	2e4080e7          	jalr	740(ra) # 800019e2 <myproc>
    80004706:	5904                	lw	s1,48(a0)
    80004708:	413484b3          	sub	s1,s1,s3
    8000470c:	0014b493          	seqz	s1,s1
    80004710:	bfc1                	j	800046e0 <holdingsleep+0x24>

0000000080004712 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004712:	1141                	addi	sp,sp,-16
    80004714:	e406                	sd	ra,8(sp)
    80004716:	e022                	sd	s0,0(sp)
    80004718:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000471a:	00004597          	auipc	a1,0x4
    8000471e:	17658593          	addi	a1,a1,374 # 80008890 <syscalls+0x370>
    80004722:	0001d517          	auipc	a0,0x1d
    80004726:	2b650513          	addi	a0,a0,694 # 800219d8 <ftable>
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	41c080e7          	jalr	1052(ra) # 80000b46 <initlock>
}
    80004732:	60a2                	ld	ra,8(sp)
    80004734:	6402                	ld	s0,0(sp)
    80004736:	0141                	addi	sp,sp,16
    80004738:	8082                	ret

000000008000473a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000473a:	1101                	addi	sp,sp,-32
    8000473c:	ec06                	sd	ra,24(sp)
    8000473e:	e822                	sd	s0,16(sp)
    80004740:	e426                	sd	s1,8(sp)
    80004742:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004744:	0001d517          	auipc	a0,0x1d
    80004748:	29450513          	addi	a0,a0,660 # 800219d8 <ftable>
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	48a080e7          	jalr	1162(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004754:	0001d497          	auipc	s1,0x1d
    80004758:	29c48493          	addi	s1,s1,668 # 800219f0 <ftable+0x18>
    8000475c:	0001e717          	auipc	a4,0x1e
    80004760:	23470713          	addi	a4,a4,564 # 80022990 <disk>
    if(f->ref == 0){
    80004764:	40dc                	lw	a5,4(s1)
    80004766:	cf99                	beqz	a5,80004784 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004768:	02848493          	addi	s1,s1,40
    8000476c:	fee49ce3          	bne	s1,a4,80004764 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004770:	0001d517          	auipc	a0,0x1d
    80004774:	26850513          	addi	a0,a0,616 # 800219d8 <ftable>
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	512080e7          	jalr	1298(ra) # 80000c8a <release>
  return 0;
    80004780:	4481                	li	s1,0
    80004782:	a819                	j	80004798 <filealloc+0x5e>
      f->ref = 1;
    80004784:	4785                	li	a5,1
    80004786:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004788:	0001d517          	auipc	a0,0x1d
    8000478c:	25050513          	addi	a0,a0,592 # 800219d8 <ftable>
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	4fa080e7          	jalr	1274(ra) # 80000c8a <release>
}
    80004798:	8526                	mv	a0,s1
    8000479a:	60e2                	ld	ra,24(sp)
    8000479c:	6442                	ld	s0,16(sp)
    8000479e:	64a2                	ld	s1,8(sp)
    800047a0:	6105                	addi	sp,sp,32
    800047a2:	8082                	ret

00000000800047a4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047a4:	1101                	addi	sp,sp,-32
    800047a6:	ec06                	sd	ra,24(sp)
    800047a8:	e822                	sd	s0,16(sp)
    800047aa:	e426                	sd	s1,8(sp)
    800047ac:	1000                	addi	s0,sp,32
    800047ae:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047b0:	0001d517          	auipc	a0,0x1d
    800047b4:	22850513          	addi	a0,a0,552 # 800219d8 <ftable>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	41e080e7          	jalr	1054(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800047c0:	40dc                	lw	a5,4(s1)
    800047c2:	02f05263          	blez	a5,800047e6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047c6:	2785                	addiw	a5,a5,1
    800047c8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047ca:	0001d517          	auipc	a0,0x1d
    800047ce:	20e50513          	addi	a0,a0,526 # 800219d8 <ftable>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	4b8080e7          	jalr	1208(ra) # 80000c8a <release>
  return f;
}
    800047da:	8526                	mv	a0,s1
    800047dc:	60e2                	ld	ra,24(sp)
    800047de:	6442                	ld	s0,16(sp)
    800047e0:	64a2                	ld	s1,8(sp)
    800047e2:	6105                	addi	sp,sp,32
    800047e4:	8082                	ret
    panic("filedup");
    800047e6:	00004517          	auipc	a0,0x4
    800047ea:	0b250513          	addi	a0,a0,178 # 80008898 <syscalls+0x378>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	d50080e7          	jalr	-688(ra) # 8000053e <panic>

00000000800047f6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047f6:	7139                	addi	sp,sp,-64
    800047f8:	fc06                	sd	ra,56(sp)
    800047fa:	f822                	sd	s0,48(sp)
    800047fc:	f426                	sd	s1,40(sp)
    800047fe:	f04a                	sd	s2,32(sp)
    80004800:	ec4e                	sd	s3,24(sp)
    80004802:	e852                	sd	s4,16(sp)
    80004804:	e456                	sd	s5,8(sp)
    80004806:	0080                	addi	s0,sp,64
    80004808:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000480a:	0001d517          	auipc	a0,0x1d
    8000480e:	1ce50513          	addi	a0,a0,462 # 800219d8 <ftable>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	3c4080e7          	jalr	964(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000481a:	40dc                	lw	a5,4(s1)
    8000481c:	06f05163          	blez	a5,8000487e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004820:	37fd                	addiw	a5,a5,-1
    80004822:	0007871b          	sext.w	a4,a5
    80004826:	c0dc                	sw	a5,4(s1)
    80004828:	06e04363          	bgtz	a4,8000488e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000482c:	0004a903          	lw	s2,0(s1)
    80004830:	0094ca83          	lbu	s5,9(s1)
    80004834:	0104ba03          	ld	s4,16(s1)
    80004838:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000483c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004840:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004844:	0001d517          	auipc	a0,0x1d
    80004848:	19450513          	addi	a0,a0,404 # 800219d8 <ftable>
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	43e080e7          	jalr	1086(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004854:	4785                	li	a5,1
    80004856:	04f90d63          	beq	s2,a5,800048b0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000485a:	3979                	addiw	s2,s2,-2
    8000485c:	4785                	li	a5,1
    8000485e:	0527e063          	bltu	a5,s2,8000489e <fileclose+0xa8>
    begin_op();
    80004862:	00000097          	auipc	ra,0x0
    80004866:	ac8080e7          	jalr	-1336(ra) # 8000432a <begin_op>
    iput(ff.ip);
    8000486a:	854e                	mv	a0,s3
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	2b6080e7          	jalr	694(ra) # 80003b22 <iput>
    end_op();
    80004874:	00000097          	auipc	ra,0x0
    80004878:	b36080e7          	jalr	-1226(ra) # 800043aa <end_op>
    8000487c:	a00d                	j	8000489e <fileclose+0xa8>
    panic("fileclose");
    8000487e:	00004517          	auipc	a0,0x4
    80004882:	02250513          	addi	a0,a0,34 # 800088a0 <syscalls+0x380>
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	cb8080e7          	jalr	-840(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000488e:	0001d517          	auipc	a0,0x1d
    80004892:	14a50513          	addi	a0,a0,330 # 800219d8 <ftable>
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	3f4080e7          	jalr	1012(ra) # 80000c8a <release>
  }
}
    8000489e:	70e2                	ld	ra,56(sp)
    800048a0:	7442                	ld	s0,48(sp)
    800048a2:	74a2                	ld	s1,40(sp)
    800048a4:	7902                	ld	s2,32(sp)
    800048a6:	69e2                	ld	s3,24(sp)
    800048a8:	6a42                	ld	s4,16(sp)
    800048aa:	6aa2                	ld	s5,8(sp)
    800048ac:	6121                	addi	sp,sp,64
    800048ae:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048b0:	85d6                	mv	a1,s5
    800048b2:	8552                	mv	a0,s4
    800048b4:	00000097          	auipc	ra,0x0
    800048b8:	34c080e7          	jalr	844(ra) # 80004c00 <pipeclose>
    800048bc:	b7cd                	j	8000489e <fileclose+0xa8>

00000000800048be <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048be:	715d                	addi	sp,sp,-80
    800048c0:	e486                	sd	ra,72(sp)
    800048c2:	e0a2                	sd	s0,64(sp)
    800048c4:	fc26                	sd	s1,56(sp)
    800048c6:	f84a                	sd	s2,48(sp)
    800048c8:	f44e                	sd	s3,40(sp)
    800048ca:	0880                	addi	s0,sp,80
    800048cc:	84aa                	mv	s1,a0
    800048ce:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048d0:	ffffd097          	auipc	ra,0xffffd
    800048d4:	112080e7          	jalr	274(ra) # 800019e2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048d8:	409c                	lw	a5,0(s1)
    800048da:	37f9                	addiw	a5,a5,-2
    800048dc:	4705                	li	a4,1
    800048de:	04f76763          	bltu	a4,a5,8000492c <filestat+0x6e>
    800048e2:	892a                	mv	s2,a0
    ilock(f->ip);
    800048e4:	6c88                	ld	a0,24(s1)
    800048e6:	fffff097          	auipc	ra,0xfffff
    800048ea:	082080e7          	jalr	130(ra) # 80003968 <ilock>
    stati(f->ip, &st);
    800048ee:	fb840593          	addi	a1,s0,-72
    800048f2:	6c88                	ld	a0,24(s1)
    800048f4:	fffff097          	auipc	ra,0xfffff
    800048f8:	2fe080e7          	jalr	766(ra) # 80003bf2 <stati>
    iunlock(f->ip);
    800048fc:	6c88                	ld	a0,24(s1)
    800048fe:	fffff097          	auipc	ra,0xfffff
    80004902:	12c080e7          	jalr	300(ra) # 80003a2a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004906:	46e1                	li	a3,24
    80004908:	fb840613          	addi	a2,s0,-72
    8000490c:	85ce                	mv	a1,s3
    8000490e:	05093503          	ld	a0,80(s2)
    80004912:	ffffd097          	auipc	ra,0xffffd
    80004916:	d8c080e7          	jalr	-628(ra) # 8000169e <copyout>
    8000491a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000491e:	60a6                	ld	ra,72(sp)
    80004920:	6406                	ld	s0,64(sp)
    80004922:	74e2                	ld	s1,56(sp)
    80004924:	7942                	ld	s2,48(sp)
    80004926:	79a2                	ld	s3,40(sp)
    80004928:	6161                	addi	sp,sp,80
    8000492a:	8082                	ret
  return -1;
    8000492c:	557d                	li	a0,-1
    8000492e:	bfc5                	j	8000491e <filestat+0x60>

0000000080004930 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004930:	7179                	addi	sp,sp,-48
    80004932:	f406                	sd	ra,40(sp)
    80004934:	f022                	sd	s0,32(sp)
    80004936:	ec26                	sd	s1,24(sp)
    80004938:	e84a                	sd	s2,16(sp)
    8000493a:	e44e                	sd	s3,8(sp)
    8000493c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000493e:	00854783          	lbu	a5,8(a0)
    80004942:	c3d5                	beqz	a5,800049e6 <fileread+0xb6>
    80004944:	84aa                	mv	s1,a0
    80004946:	89ae                	mv	s3,a1
    80004948:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000494a:	411c                	lw	a5,0(a0)
    8000494c:	4705                	li	a4,1
    8000494e:	04e78963          	beq	a5,a4,800049a0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004952:	470d                	li	a4,3
    80004954:	04e78d63          	beq	a5,a4,800049ae <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004958:	4709                	li	a4,2
    8000495a:	06e79e63          	bne	a5,a4,800049d6 <fileread+0xa6>
    ilock(f->ip);
    8000495e:	6d08                	ld	a0,24(a0)
    80004960:	fffff097          	auipc	ra,0xfffff
    80004964:	008080e7          	jalr	8(ra) # 80003968 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004968:	874a                	mv	a4,s2
    8000496a:	5094                	lw	a3,32(s1)
    8000496c:	864e                	mv	a2,s3
    8000496e:	4585                	li	a1,1
    80004970:	6c88                	ld	a0,24(s1)
    80004972:	fffff097          	auipc	ra,0xfffff
    80004976:	2aa080e7          	jalr	682(ra) # 80003c1c <readi>
    8000497a:	892a                	mv	s2,a0
    8000497c:	00a05563          	blez	a0,80004986 <fileread+0x56>
      f->off += r;
    80004980:	509c                	lw	a5,32(s1)
    80004982:	9fa9                	addw	a5,a5,a0
    80004984:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004986:	6c88                	ld	a0,24(s1)
    80004988:	fffff097          	auipc	ra,0xfffff
    8000498c:	0a2080e7          	jalr	162(ra) # 80003a2a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004990:	854a                	mv	a0,s2
    80004992:	70a2                	ld	ra,40(sp)
    80004994:	7402                	ld	s0,32(sp)
    80004996:	64e2                	ld	s1,24(sp)
    80004998:	6942                	ld	s2,16(sp)
    8000499a:	69a2                	ld	s3,8(sp)
    8000499c:	6145                	addi	sp,sp,48
    8000499e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049a0:	6908                	ld	a0,16(a0)
    800049a2:	00000097          	auipc	ra,0x0
    800049a6:	3c6080e7          	jalr	966(ra) # 80004d68 <piperead>
    800049aa:	892a                	mv	s2,a0
    800049ac:	b7d5                	j	80004990 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049ae:	02451783          	lh	a5,36(a0)
    800049b2:	03079693          	slli	a3,a5,0x30
    800049b6:	92c1                	srli	a3,a3,0x30
    800049b8:	4725                	li	a4,9
    800049ba:	02d76863          	bltu	a4,a3,800049ea <fileread+0xba>
    800049be:	0792                	slli	a5,a5,0x4
    800049c0:	0001d717          	auipc	a4,0x1d
    800049c4:	f7870713          	addi	a4,a4,-136 # 80021938 <devsw>
    800049c8:	97ba                	add	a5,a5,a4
    800049ca:	639c                	ld	a5,0(a5)
    800049cc:	c38d                	beqz	a5,800049ee <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049ce:	4505                	li	a0,1
    800049d0:	9782                	jalr	a5
    800049d2:	892a                	mv	s2,a0
    800049d4:	bf75                	j	80004990 <fileread+0x60>
    panic("fileread");
    800049d6:	00004517          	auipc	a0,0x4
    800049da:	eda50513          	addi	a0,a0,-294 # 800088b0 <syscalls+0x390>
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	b60080e7          	jalr	-1184(ra) # 8000053e <panic>
    return -1;
    800049e6:	597d                	li	s2,-1
    800049e8:	b765                	j	80004990 <fileread+0x60>
      return -1;
    800049ea:	597d                	li	s2,-1
    800049ec:	b755                	j	80004990 <fileread+0x60>
    800049ee:	597d                	li	s2,-1
    800049f0:	b745                	j	80004990 <fileread+0x60>

00000000800049f2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049f2:	715d                	addi	sp,sp,-80
    800049f4:	e486                	sd	ra,72(sp)
    800049f6:	e0a2                	sd	s0,64(sp)
    800049f8:	fc26                	sd	s1,56(sp)
    800049fa:	f84a                	sd	s2,48(sp)
    800049fc:	f44e                	sd	s3,40(sp)
    800049fe:	f052                	sd	s4,32(sp)
    80004a00:	ec56                	sd	s5,24(sp)
    80004a02:	e85a                	sd	s6,16(sp)
    80004a04:	e45e                	sd	s7,8(sp)
    80004a06:	e062                	sd	s8,0(sp)
    80004a08:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a0a:	00954783          	lbu	a5,9(a0)
    80004a0e:	10078663          	beqz	a5,80004b1a <filewrite+0x128>
    80004a12:	892a                	mv	s2,a0
    80004a14:	8aae                	mv	s5,a1
    80004a16:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a18:	411c                	lw	a5,0(a0)
    80004a1a:	4705                	li	a4,1
    80004a1c:	02e78263          	beq	a5,a4,80004a40 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a20:	470d                	li	a4,3
    80004a22:	02e78663          	beq	a5,a4,80004a4e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a26:	4709                	li	a4,2
    80004a28:	0ee79163          	bne	a5,a4,80004b0a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a2c:	0ac05d63          	blez	a2,80004ae6 <filewrite+0xf4>
    int i = 0;
    80004a30:	4981                	li	s3,0
    80004a32:	6b05                	lui	s6,0x1
    80004a34:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a38:	6b85                	lui	s7,0x1
    80004a3a:	c00b8b9b          	addiw	s7,s7,-1024
    80004a3e:	a861                	j	80004ad6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a40:	6908                	ld	a0,16(a0)
    80004a42:	00000097          	auipc	ra,0x0
    80004a46:	22e080e7          	jalr	558(ra) # 80004c70 <pipewrite>
    80004a4a:	8a2a                	mv	s4,a0
    80004a4c:	a045                	j	80004aec <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a4e:	02451783          	lh	a5,36(a0)
    80004a52:	03079693          	slli	a3,a5,0x30
    80004a56:	92c1                	srli	a3,a3,0x30
    80004a58:	4725                	li	a4,9
    80004a5a:	0cd76263          	bltu	a4,a3,80004b1e <filewrite+0x12c>
    80004a5e:	0792                	slli	a5,a5,0x4
    80004a60:	0001d717          	auipc	a4,0x1d
    80004a64:	ed870713          	addi	a4,a4,-296 # 80021938 <devsw>
    80004a68:	97ba                	add	a5,a5,a4
    80004a6a:	679c                	ld	a5,8(a5)
    80004a6c:	cbdd                	beqz	a5,80004b22 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a6e:	4505                	li	a0,1
    80004a70:	9782                	jalr	a5
    80004a72:	8a2a                	mv	s4,a0
    80004a74:	a8a5                	j	80004aec <filewrite+0xfa>
    80004a76:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a7a:	00000097          	auipc	ra,0x0
    80004a7e:	8b0080e7          	jalr	-1872(ra) # 8000432a <begin_op>
      ilock(f->ip);
    80004a82:	01893503          	ld	a0,24(s2)
    80004a86:	fffff097          	auipc	ra,0xfffff
    80004a8a:	ee2080e7          	jalr	-286(ra) # 80003968 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a8e:	8762                	mv	a4,s8
    80004a90:	02092683          	lw	a3,32(s2)
    80004a94:	01598633          	add	a2,s3,s5
    80004a98:	4585                	li	a1,1
    80004a9a:	01893503          	ld	a0,24(s2)
    80004a9e:	fffff097          	auipc	ra,0xfffff
    80004aa2:	276080e7          	jalr	630(ra) # 80003d14 <writei>
    80004aa6:	84aa                	mv	s1,a0
    80004aa8:	00a05763          	blez	a0,80004ab6 <filewrite+0xc4>
        f->off += r;
    80004aac:	02092783          	lw	a5,32(s2)
    80004ab0:	9fa9                	addw	a5,a5,a0
    80004ab2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ab6:	01893503          	ld	a0,24(s2)
    80004aba:	fffff097          	auipc	ra,0xfffff
    80004abe:	f70080e7          	jalr	-144(ra) # 80003a2a <iunlock>
      end_op();
    80004ac2:	00000097          	auipc	ra,0x0
    80004ac6:	8e8080e7          	jalr	-1816(ra) # 800043aa <end_op>

      if(r != n1){
    80004aca:	009c1f63          	bne	s8,s1,80004ae8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ace:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ad2:	0149db63          	bge	s3,s4,80004ae8 <filewrite+0xf6>
      int n1 = n - i;
    80004ad6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ada:	84be                	mv	s1,a5
    80004adc:	2781                	sext.w	a5,a5
    80004ade:	f8fb5ce3          	bge	s6,a5,80004a76 <filewrite+0x84>
    80004ae2:	84de                	mv	s1,s7
    80004ae4:	bf49                	j	80004a76 <filewrite+0x84>
    int i = 0;
    80004ae6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ae8:	013a1f63          	bne	s4,s3,80004b06 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004aec:	8552                	mv	a0,s4
    80004aee:	60a6                	ld	ra,72(sp)
    80004af0:	6406                	ld	s0,64(sp)
    80004af2:	74e2                	ld	s1,56(sp)
    80004af4:	7942                	ld	s2,48(sp)
    80004af6:	79a2                	ld	s3,40(sp)
    80004af8:	7a02                	ld	s4,32(sp)
    80004afa:	6ae2                	ld	s5,24(sp)
    80004afc:	6b42                	ld	s6,16(sp)
    80004afe:	6ba2                	ld	s7,8(sp)
    80004b00:	6c02                	ld	s8,0(sp)
    80004b02:	6161                	addi	sp,sp,80
    80004b04:	8082                	ret
    ret = (i == n ? n : -1);
    80004b06:	5a7d                	li	s4,-1
    80004b08:	b7d5                	j	80004aec <filewrite+0xfa>
    panic("filewrite");
    80004b0a:	00004517          	auipc	a0,0x4
    80004b0e:	db650513          	addi	a0,a0,-586 # 800088c0 <syscalls+0x3a0>
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	a2c080e7          	jalr	-1492(ra) # 8000053e <panic>
    return -1;
    80004b1a:	5a7d                	li	s4,-1
    80004b1c:	bfc1                	j	80004aec <filewrite+0xfa>
      return -1;
    80004b1e:	5a7d                	li	s4,-1
    80004b20:	b7f1                	j	80004aec <filewrite+0xfa>
    80004b22:	5a7d                	li	s4,-1
    80004b24:	b7e1                	j	80004aec <filewrite+0xfa>

0000000080004b26 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b26:	7179                	addi	sp,sp,-48
    80004b28:	f406                	sd	ra,40(sp)
    80004b2a:	f022                	sd	s0,32(sp)
    80004b2c:	ec26                	sd	s1,24(sp)
    80004b2e:	e84a                	sd	s2,16(sp)
    80004b30:	e44e                	sd	s3,8(sp)
    80004b32:	e052                	sd	s4,0(sp)
    80004b34:	1800                	addi	s0,sp,48
    80004b36:	84aa                	mv	s1,a0
    80004b38:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b3a:	0005b023          	sd	zero,0(a1)
    80004b3e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b42:	00000097          	auipc	ra,0x0
    80004b46:	bf8080e7          	jalr	-1032(ra) # 8000473a <filealloc>
    80004b4a:	e088                	sd	a0,0(s1)
    80004b4c:	c551                	beqz	a0,80004bd8 <pipealloc+0xb2>
    80004b4e:	00000097          	auipc	ra,0x0
    80004b52:	bec080e7          	jalr	-1044(ra) # 8000473a <filealloc>
    80004b56:	00aa3023          	sd	a0,0(s4)
    80004b5a:	c92d                	beqz	a0,80004bcc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	f8a080e7          	jalr	-118(ra) # 80000ae6 <kalloc>
    80004b64:	892a                	mv	s2,a0
    80004b66:	c125                	beqz	a0,80004bc6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b68:	4985                	li	s3,1
    80004b6a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b6e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b72:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b76:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b7a:	00004597          	auipc	a1,0x4
    80004b7e:	d5658593          	addi	a1,a1,-682 # 800088d0 <syscalls+0x3b0>
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	fc4080e7          	jalr	-60(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004b8a:	609c                	ld	a5,0(s1)
    80004b8c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b90:	609c                	ld	a5,0(s1)
    80004b92:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b96:	609c                	ld	a5,0(s1)
    80004b98:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b9c:	609c                	ld	a5,0(s1)
    80004b9e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ba2:	000a3783          	ld	a5,0(s4)
    80004ba6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004baa:	000a3783          	ld	a5,0(s4)
    80004bae:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bb2:	000a3783          	ld	a5,0(s4)
    80004bb6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bba:	000a3783          	ld	a5,0(s4)
    80004bbe:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bc2:	4501                	li	a0,0
    80004bc4:	a025                	j	80004bec <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bc6:	6088                	ld	a0,0(s1)
    80004bc8:	e501                	bnez	a0,80004bd0 <pipealloc+0xaa>
    80004bca:	a039                	j	80004bd8 <pipealloc+0xb2>
    80004bcc:	6088                	ld	a0,0(s1)
    80004bce:	c51d                	beqz	a0,80004bfc <pipealloc+0xd6>
    fileclose(*f0);
    80004bd0:	00000097          	auipc	ra,0x0
    80004bd4:	c26080e7          	jalr	-986(ra) # 800047f6 <fileclose>
  if(*f1)
    80004bd8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bdc:	557d                	li	a0,-1
  if(*f1)
    80004bde:	c799                	beqz	a5,80004bec <pipealloc+0xc6>
    fileclose(*f1);
    80004be0:	853e                	mv	a0,a5
    80004be2:	00000097          	auipc	ra,0x0
    80004be6:	c14080e7          	jalr	-1004(ra) # 800047f6 <fileclose>
  return -1;
    80004bea:	557d                	li	a0,-1
}
    80004bec:	70a2                	ld	ra,40(sp)
    80004bee:	7402                	ld	s0,32(sp)
    80004bf0:	64e2                	ld	s1,24(sp)
    80004bf2:	6942                	ld	s2,16(sp)
    80004bf4:	69a2                	ld	s3,8(sp)
    80004bf6:	6a02                	ld	s4,0(sp)
    80004bf8:	6145                	addi	sp,sp,48
    80004bfa:	8082                	ret
  return -1;
    80004bfc:	557d                	li	a0,-1
    80004bfe:	b7fd                	j	80004bec <pipealloc+0xc6>

0000000080004c00 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c00:	1101                	addi	sp,sp,-32
    80004c02:	ec06                	sd	ra,24(sp)
    80004c04:	e822                	sd	s0,16(sp)
    80004c06:	e426                	sd	s1,8(sp)
    80004c08:	e04a                	sd	s2,0(sp)
    80004c0a:	1000                	addi	s0,sp,32
    80004c0c:	84aa                	mv	s1,a0
    80004c0e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	fc6080e7          	jalr	-58(ra) # 80000bd6 <acquire>
  if(writable){
    80004c18:	02090d63          	beqz	s2,80004c52 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c1c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c20:	21848513          	addi	a0,s1,536
    80004c24:	ffffd097          	auipc	ra,0xffffd
    80004c28:	562080e7          	jalr	1378(ra) # 80002186 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c2c:	2204b783          	ld	a5,544(s1)
    80004c30:	eb95                	bnez	a5,80004c64 <pipeclose+0x64>
    release(&pi->lock);
    80004c32:	8526                	mv	a0,s1
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	056080e7          	jalr	86(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004c3c:	8526                	mv	a0,s1
    80004c3e:	ffffc097          	auipc	ra,0xffffc
    80004c42:	dac080e7          	jalr	-596(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004c46:	60e2                	ld	ra,24(sp)
    80004c48:	6442                	ld	s0,16(sp)
    80004c4a:	64a2                	ld	s1,8(sp)
    80004c4c:	6902                	ld	s2,0(sp)
    80004c4e:	6105                	addi	sp,sp,32
    80004c50:	8082                	ret
    pi->readopen = 0;
    80004c52:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c56:	21c48513          	addi	a0,s1,540
    80004c5a:	ffffd097          	auipc	ra,0xffffd
    80004c5e:	52c080e7          	jalr	1324(ra) # 80002186 <wakeup>
    80004c62:	b7e9                	j	80004c2c <pipeclose+0x2c>
    release(&pi->lock);
    80004c64:	8526                	mv	a0,s1
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	024080e7          	jalr	36(ra) # 80000c8a <release>
}
    80004c6e:	bfe1                	j	80004c46 <pipeclose+0x46>

0000000080004c70 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c70:	711d                	addi	sp,sp,-96
    80004c72:	ec86                	sd	ra,88(sp)
    80004c74:	e8a2                	sd	s0,80(sp)
    80004c76:	e4a6                	sd	s1,72(sp)
    80004c78:	e0ca                	sd	s2,64(sp)
    80004c7a:	fc4e                	sd	s3,56(sp)
    80004c7c:	f852                	sd	s4,48(sp)
    80004c7e:	f456                	sd	s5,40(sp)
    80004c80:	f05a                	sd	s6,32(sp)
    80004c82:	ec5e                	sd	s7,24(sp)
    80004c84:	e862                	sd	s8,16(sp)
    80004c86:	1080                	addi	s0,sp,96
    80004c88:	84aa                	mv	s1,a0
    80004c8a:	8aae                	mv	s5,a1
    80004c8c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c8e:	ffffd097          	auipc	ra,0xffffd
    80004c92:	d54080e7          	jalr	-684(ra) # 800019e2 <myproc>
    80004c96:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c98:	8526                	mv	a0,s1
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	f3c080e7          	jalr	-196(ra) # 80000bd6 <acquire>
  while(i < n){
    80004ca2:	0b405663          	blez	s4,80004d4e <pipewrite+0xde>
  int i = 0;
    80004ca6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ca8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004caa:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cae:	21c48b93          	addi	s7,s1,540
    80004cb2:	a089                	j	80004cf4 <pipewrite+0x84>
      release(&pi->lock);
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	fd4080e7          	jalr	-44(ra) # 80000c8a <release>
      return -1;
    80004cbe:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cc0:	854a                	mv	a0,s2
    80004cc2:	60e6                	ld	ra,88(sp)
    80004cc4:	6446                	ld	s0,80(sp)
    80004cc6:	64a6                	ld	s1,72(sp)
    80004cc8:	6906                	ld	s2,64(sp)
    80004cca:	79e2                	ld	s3,56(sp)
    80004ccc:	7a42                	ld	s4,48(sp)
    80004cce:	7aa2                	ld	s5,40(sp)
    80004cd0:	7b02                	ld	s6,32(sp)
    80004cd2:	6be2                	ld	s7,24(sp)
    80004cd4:	6c42                	ld	s8,16(sp)
    80004cd6:	6125                	addi	sp,sp,96
    80004cd8:	8082                	ret
      wakeup(&pi->nread);
    80004cda:	8562                	mv	a0,s8
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	4aa080e7          	jalr	1194(ra) # 80002186 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ce4:	85a6                	mv	a1,s1
    80004ce6:	855e                	mv	a0,s7
    80004ce8:	ffffd097          	auipc	ra,0xffffd
    80004cec:	43a080e7          	jalr	1082(ra) # 80002122 <sleep>
  while(i < n){
    80004cf0:	07495063          	bge	s2,s4,80004d50 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004cf4:	2204a783          	lw	a5,544(s1)
    80004cf8:	dfd5                	beqz	a5,80004cb4 <pipewrite+0x44>
    80004cfa:	854e                	mv	a0,s3
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	6ce080e7          	jalr	1742(ra) # 800023ca <killed>
    80004d04:	f945                	bnez	a0,80004cb4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d06:	2184a783          	lw	a5,536(s1)
    80004d0a:	21c4a703          	lw	a4,540(s1)
    80004d0e:	2007879b          	addiw	a5,a5,512
    80004d12:	fcf704e3          	beq	a4,a5,80004cda <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d16:	4685                	li	a3,1
    80004d18:	01590633          	add	a2,s2,s5
    80004d1c:	faf40593          	addi	a1,s0,-81
    80004d20:	0509b503          	ld	a0,80(s3)
    80004d24:	ffffd097          	auipc	ra,0xffffd
    80004d28:	a06080e7          	jalr	-1530(ra) # 8000172a <copyin>
    80004d2c:	03650263          	beq	a0,s6,80004d50 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d30:	21c4a783          	lw	a5,540(s1)
    80004d34:	0017871b          	addiw	a4,a5,1
    80004d38:	20e4ae23          	sw	a4,540(s1)
    80004d3c:	1ff7f793          	andi	a5,a5,511
    80004d40:	97a6                	add	a5,a5,s1
    80004d42:	faf44703          	lbu	a4,-81(s0)
    80004d46:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d4a:	2905                	addiw	s2,s2,1
    80004d4c:	b755                	j	80004cf0 <pipewrite+0x80>
  int i = 0;
    80004d4e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004d50:	21848513          	addi	a0,s1,536
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	432080e7          	jalr	1074(ra) # 80002186 <wakeup>
  release(&pi->lock);
    80004d5c:	8526                	mv	a0,s1
    80004d5e:	ffffc097          	auipc	ra,0xffffc
    80004d62:	f2c080e7          	jalr	-212(ra) # 80000c8a <release>
  return i;
    80004d66:	bfa9                	j	80004cc0 <pipewrite+0x50>

0000000080004d68 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d68:	715d                	addi	sp,sp,-80
    80004d6a:	e486                	sd	ra,72(sp)
    80004d6c:	e0a2                	sd	s0,64(sp)
    80004d6e:	fc26                	sd	s1,56(sp)
    80004d70:	f84a                	sd	s2,48(sp)
    80004d72:	f44e                	sd	s3,40(sp)
    80004d74:	f052                	sd	s4,32(sp)
    80004d76:	ec56                	sd	s5,24(sp)
    80004d78:	e85a                	sd	s6,16(sp)
    80004d7a:	0880                	addi	s0,sp,80
    80004d7c:	84aa                	mv	s1,a0
    80004d7e:	892e                	mv	s2,a1
    80004d80:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	c60080e7          	jalr	-928(ra) # 800019e2 <myproc>
    80004d8a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	ffffc097          	auipc	ra,0xffffc
    80004d92:	e48080e7          	jalr	-440(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d96:	2184a703          	lw	a4,536(s1)
    80004d9a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d9e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004da2:	02f71763          	bne	a4,a5,80004dd0 <piperead+0x68>
    80004da6:	2244a783          	lw	a5,548(s1)
    80004daa:	c39d                	beqz	a5,80004dd0 <piperead+0x68>
    if(killed(pr)){
    80004dac:	8552                	mv	a0,s4
    80004dae:	ffffd097          	auipc	ra,0xffffd
    80004db2:	61c080e7          	jalr	1564(ra) # 800023ca <killed>
    80004db6:	e941                	bnez	a0,80004e46 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004db8:	85a6                	mv	a1,s1
    80004dba:	854e                	mv	a0,s3
    80004dbc:	ffffd097          	auipc	ra,0xffffd
    80004dc0:	366080e7          	jalr	870(ra) # 80002122 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dc4:	2184a703          	lw	a4,536(s1)
    80004dc8:	21c4a783          	lw	a5,540(s1)
    80004dcc:	fcf70de3          	beq	a4,a5,80004da6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dd0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dd2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dd4:	05505363          	blez	s5,80004e1a <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004dd8:	2184a783          	lw	a5,536(s1)
    80004ddc:	21c4a703          	lw	a4,540(s1)
    80004de0:	02f70d63          	beq	a4,a5,80004e1a <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004de4:	0017871b          	addiw	a4,a5,1
    80004de8:	20e4ac23          	sw	a4,536(s1)
    80004dec:	1ff7f793          	andi	a5,a5,511
    80004df0:	97a6                	add	a5,a5,s1
    80004df2:	0187c783          	lbu	a5,24(a5)
    80004df6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dfa:	4685                	li	a3,1
    80004dfc:	fbf40613          	addi	a2,s0,-65
    80004e00:	85ca                	mv	a1,s2
    80004e02:	050a3503          	ld	a0,80(s4)
    80004e06:	ffffd097          	auipc	ra,0xffffd
    80004e0a:	898080e7          	jalr	-1896(ra) # 8000169e <copyout>
    80004e0e:	01650663          	beq	a0,s6,80004e1a <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e12:	2985                	addiw	s3,s3,1
    80004e14:	0905                	addi	s2,s2,1
    80004e16:	fd3a91e3          	bne	s5,s3,80004dd8 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e1a:	21c48513          	addi	a0,s1,540
    80004e1e:	ffffd097          	auipc	ra,0xffffd
    80004e22:	368080e7          	jalr	872(ra) # 80002186 <wakeup>
  release(&pi->lock);
    80004e26:	8526                	mv	a0,s1
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	e62080e7          	jalr	-414(ra) # 80000c8a <release>
  return i;
}
    80004e30:	854e                	mv	a0,s3
    80004e32:	60a6                	ld	ra,72(sp)
    80004e34:	6406                	ld	s0,64(sp)
    80004e36:	74e2                	ld	s1,56(sp)
    80004e38:	7942                	ld	s2,48(sp)
    80004e3a:	79a2                	ld	s3,40(sp)
    80004e3c:	7a02                	ld	s4,32(sp)
    80004e3e:	6ae2                	ld	s5,24(sp)
    80004e40:	6b42                	ld	s6,16(sp)
    80004e42:	6161                	addi	sp,sp,80
    80004e44:	8082                	ret
      release(&pi->lock);
    80004e46:	8526                	mv	a0,s1
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
      return -1;
    80004e50:	59fd                	li	s3,-1
    80004e52:	bff9                	j	80004e30 <piperead+0xc8>

0000000080004e54 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e54:	1141                	addi	sp,sp,-16
    80004e56:	e422                	sd	s0,8(sp)
    80004e58:	0800                	addi	s0,sp,16
    80004e5a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e5c:	8905                	andi	a0,a0,1
    80004e5e:	c111                	beqz	a0,80004e62 <flags2perm+0xe>
      perm = PTE_X;
    80004e60:	4521                	li	a0,8
    if(flags & 0x2)
    80004e62:	8b89                	andi	a5,a5,2
    80004e64:	c399                	beqz	a5,80004e6a <flags2perm+0x16>
      perm |= PTE_W;
    80004e66:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e6a:	6422                	ld	s0,8(sp)
    80004e6c:	0141                	addi	sp,sp,16
    80004e6e:	8082                	ret

0000000080004e70 <exec>:

int
exec(char *path, char **argv)
{
    80004e70:	de010113          	addi	sp,sp,-544
    80004e74:	20113c23          	sd	ra,536(sp)
    80004e78:	20813823          	sd	s0,528(sp)
    80004e7c:	20913423          	sd	s1,520(sp)
    80004e80:	21213023          	sd	s2,512(sp)
    80004e84:	ffce                	sd	s3,504(sp)
    80004e86:	fbd2                	sd	s4,496(sp)
    80004e88:	f7d6                	sd	s5,488(sp)
    80004e8a:	f3da                	sd	s6,480(sp)
    80004e8c:	efde                	sd	s7,472(sp)
    80004e8e:	ebe2                	sd	s8,464(sp)
    80004e90:	e7e6                	sd	s9,456(sp)
    80004e92:	e3ea                	sd	s10,448(sp)
    80004e94:	ff6e                	sd	s11,440(sp)
    80004e96:	1400                	addi	s0,sp,544
    80004e98:	892a                	mv	s2,a0
    80004e9a:	dea43423          	sd	a0,-536(s0)
    80004e9e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ea2:	ffffd097          	auipc	ra,0xffffd
    80004ea6:	b40080e7          	jalr	-1216(ra) # 800019e2 <myproc>
    80004eaa:	84aa                	mv	s1,a0

  begin_op();
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	47e080e7          	jalr	1150(ra) # 8000432a <begin_op>

  if((ip = namei(path)) == 0){
    80004eb4:	854a                	mv	a0,s2
    80004eb6:	fffff097          	auipc	ra,0xfffff
    80004eba:	258080e7          	jalr	600(ra) # 8000410e <namei>
    80004ebe:	c93d                	beqz	a0,80004f34 <exec+0xc4>
    80004ec0:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ec2:	fffff097          	auipc	ra,0xfffff
    80004ec6:	aa6080e7          	jalr	-1370(ra) # 80003968 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004eca:	04000713          	li	a4,64
    80004ece:	4681                	li	a3,0
    80004ed0:	e5040613          	addi	a2,s0,-432
    80004ed4:	4581                	li	a1,0
    80004ed6:	8556                	mv	a0,s5
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	d44080e7          	jalr	-700(ra) # 80003c1c <readi>
    80004ee0:	04000793          	li	a5,64
    80004ee4:	00f51a63          	bne	a0,a5,80004ef8 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004ee8:	e5042703          	lw	a4,-432(s0)
    80004eec:	464c47b7          	lui	a5,0x464c4
    80004ef0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ef4:	04f70663          	beq	a4,a5,80004f40 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ef8:	8556                	mv	a0,s5
    80004efa:	fffff097          	auipc	ra,0xfffff
    80004efe:	cd0080e7          	jalr	-816(ra) # 80003bca <iunlockput>
    end_op();
    80004f02:	fffff097          	auipc	ra,0xfffff
    80004f06:	4a8080e7          	jalr	1192(ra) # 800043aa <end_op>
  }
  return -1;
    80004f0a:	557d                	li	a0,-1
}
    80004f0c:	21813083          	ld	ra,536(sp)
    80004f10:	21013403          	ld	s0,528(sp)
    80004f14:	20813483          	ld	s1,520(sp)
    80004f18:	20013903          	ld	s2,512(sp)
    80004f1c:	79fe                	ld	s3,504(sp)
    80004f1e:	7a5e                	ld	s4,496(sp)
    80004f20:	7abe                	ld	s5,488(sp)
    80004f22:	7b1e                	ld	s6,480(sp)
    80004f24:	6bfe                	ld	s7,472(sp)
    80004f26:	6c5e                	ld	s8,464(sp)
    80004f28:	6cbe                	ld	s9,456(sp)
    80004f2a:	6d1e                	ld	s10,448(sp)
    80004f2c:	7dfa                	ld	s11,440(sp)
    80004f2e:	22010113          	addi	sp,sp,544
    80004f32:	8082                	ret
    end_op();
    80004f34:	fffff097          	auipc	ra,0xfffff
    80004f38:	476080e7          	jalr	1142(ra) # 800043aa <end_op>
    return -1;
    80004f3c:	557d                	li	a0,-1
    80004f3e:	b7f9                	j	80004f0c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f40:	8526                	mv	a0,s1
    80004f42:	ffffd097          	auipc	ra,0xffffd
    80004f46:	b64080e7          	jalr	-1180(ra) # 80001aa6 <proc_pagetable>
    80004f4a:	8b2a                	mv	s6,a0
    80004f4c:	d555                	beqz	a0,80004ef8 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f4e:	e7042783          	lw	a5,-400(s0)
    80004f52:	e8845703          	lhu	a4,-376(s0)
    80004f56:	c735                	beqz	a4,80004fc2 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f58:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f5a:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f5e:	6a05                	lui	s4,0x1
    80004f60:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f64:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004f68:	6d85                	lui	s11,0x1
    80004f6a:	7d7d                	lui	s10,0xfffff
    80004f6c:	a481                	j	800051ac <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f6e:	00004517          	auipc	a0,0x4
    80004f72:	96a50513          	addi	a0,a0,-1686 # 800088d8 <syscalls+0x3b8>
    80004f76:	ffffb097          	auipc	ra,0xffffb
    80004f7a:	5c8080e7          	jalr	1480(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f7e:	874a                	mv	a4,s2
    80004f80:	009c86bb          	addw	a3,s9,s1
    80004f84:	4581                	li	a1,0
    80004f86:	8556                	mv	a0,s5
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	c94080e7          	jalr	-876(ra) # 80003c1c <readi>
    80004f90:	2501                	sext.w	a0,a0
    80004f92:	1aa91a63          	bne	s2,a0,80005146 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f96:	009d84bb          	addw	s1,s11,s1
    80004f9a:	013d09bb          	addw	s3,s10,s3
    80004f9e:	1f74f763          	bgeu	s1,s7,8000518c <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004fa2:	02049593          	slli	a1,s1,0x20
    80004fa6:	9181                	srli	a1,a1,0x20
    80004fa8:	95e2                	add	a1,a1,s8
    80004faa:	855a                	mv	a0,s6
    80004fac:	ffffc097          	auipc	ra,0xffffc
    80004fb0:	0d0080e7          	jalr	208(ra) # 8000107c <walkaddr>
    80004fb4:	862a                	mv	a2,a0
    if(pa == 0)
    80004fb6:	dd45                	beqz	a0,80004f6e <exec+0xfe>
      n = PGSIZE;
    80004fb8:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004fba:	fd49f2e3          	bgeu	s3,s4,80004f7e <exec+0x10e>
      n = sz - i;
    80004fbe:	894e                	mv	s2,s3
    80004fc0:	bf7d                	j	80004f7e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fc2:	4901                	li	s2,0
  iunlockput(ip);
    80004fc4:	8556                	mv	a0,s5
    80004fc6:	fffff097          	auipc	ra,0xfffff
    80004fca:	c04080e7          	jalr	-1020(ra) # 80003bca <iunlockput>
  end_op();
    80004fce:	fffff097          	auipc	ra,0xfffff
    80004fd2:	3dc080e7          	jalr	988(ra) # 800043aa <end_op>
  p = myproc();
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	a0c080e7          	jalr	-1524(ra) # 800019e2 <myproc>
    80004fde:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004fe0:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fe4:	6785                	lui	a5,0x1
    80004fe6:	17fd                	addi	a5,a5,-1
    80004fe8:	993e                	add	s2,s2,a5
    80004fea:	77fd                	lui	a5,0xfffff
    80004fec:	00f977b3          	and	a5,s2,a5
    80004ff0:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ff4:	4691                	li	a3,4
    80004ff6:	6609                	lui	a2,0x2
    80004ff8:	963e                	add	a2,a2,a5
    80004ffa:	85be                	mv	a1,a5
    80004ffc:	855a                	mv	a0,s6
    80004ffe:	ffffc097          	auipc	ra,0xffffc
    80005002:	448080e7          	jalr	1096(ra) # 80001446 <uvmalloc>
    80005006:	8c2a                	mv	s8,a0
  ip = 0;
    80005008:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000500a:	12050e63          	beqz	a0,80005146 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000500e:	75f9                	lui	a1,0xffffe
    80005010:	95aa                	add	a1,a1,a0
    80005012:	855a                	mv	a0,s6
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	658080e7          	jalr	1624(ra) # 8000166c <uvmclear>
  stackbase = sp - PGSIZE;
    8000501c:	7afd                	lui	s5,0xfffff
    8000501e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005020:	df043783          	ld	a5,-528(s0)
    80005024:	6388                	ld	a0,0(a5)
    80005026:	c925                	beqz	a0,80005096 <exec+0x226>
    80005028:	e9040993          	addi	s3,s0,-368
    8000502c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005030:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005032:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	e1a080e7          	jalr	-486(ra) # 80000e4e <strlen>
    8000503c:	0015079b          	addiw	a5,a0,1
    80005040:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005044:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005048:	13596663          	bltu	s2,s5,80005174 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000504c:	df043d83          	ld	s11,-528(s0)
    80005050:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005054:	8552                	mv	a0,s4
    80005056:	ffffc097          	auipc	ra,0xffffc
    8000505a:	df8080e7          	jalr	-520(ra) # 80000e4e <strlen>
    8000505e:	0015069b          	addiw	a3,a0,1
    80005062:	8652                	mv	a2,s4
    80005064:	85ca                	mv	a1,s2
    80005066:	855a                	mv	a0,s6
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	636080e7          	jalr	1590(ra) # 8000169e <copyout>
    80005070:	10054663          	bltz	a0,8000517c <exec+0x30c>
    ustack[argc] = sp;
    80005074:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005078:	0485                	addi	s1,s1,1
    8000507a:	008d8793          	addi	a5,s11,8
    8000507e:	def43823          	sd	a5,-528(s0)
    80005082:	008db503          	ld	a0,8(s11)
    80005086:	c911                	beqz	a0,8000509a <exec+0x22a>
    if(argc >= MAXARG)
    80005088:	09a1                	addi	s3,s3,8
    8000508a:	fb3c95e3          	bne	s9,s3,80005034 <exec+0x1c4>
  sz = sz1;
    8000508e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005092:	4a81                	li	s5,0
    80005094:	a84d                	j	80005146 <exec+0x2d6>
  sp = sz;
    80005096:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005098:	4481                	li	s1,0
  ustack[argc] = 0;
    8000509a:	00349793          	slli	a5,s1,0x3
    8000509e:	f9040713          	addi	a4,s0,-112
    800050a2:	97ba                	add	a5,a5,a4
    800050a4:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd8138>
  sp -= (argc+1) * sizeof(uint64);
    800050a8:	00148693          	addi	a3,s1,1
    800050ac:	068e                	slli	a3,a3,0x3
    800050ae:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050b2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050b6:	01597663          	bgeu	s2,s5,800050c2 <exec+0x252>
  sz = sz1;
    800050ba:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050be:	4a81                	li	s5,0
    800050c0:	a059                	j	80005146 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050c2:	e9040613          	addi	a2,s0,-368
    800050c6:	85ca                	mv	a1,s2
    800050c8:	855a                	mv	a0,s6
    800050ca:	ffffc097          	auipc	ra,0xffffc
    800050ce:	5d4080e7          	jalr	1492(ra) # 8000169e <copyout>
    800050d2:	0a054963          	bltz	a0,80005184 <exec+0x314>
  p->trapframe->a1 = sp;
    800050d6:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800050da:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050de:	de843783          	ld	a5,-536(s0)
    800050e2:	0007c703          	lbu	a4,0(a5)
    800050e6:	cf11                	beqz	a4,80005102 <exec+0x292>
    800050e8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050ea:	02f00693          	li	a3,47
    800050ee:	a039                	j	800050fc <exec+0x28c>
      last = s+1;
    800050f0:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800050f4:	0785                	addi	a5,a5,1
    800050f6:	fff7c703          	lbu	a4,-1(a5)
    800050fa:	c701                	beqz	a4,80005102 <exec+0x292>
    if(*s == '/')
    800050fc:	fed71ce3          	bne	a4,a3,800050f4 <exec+0x284>
    80005100:	bfc5                	j	800050f0 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005102:	4641                	li	a2,16
    80005104:	de843583          	ld	a1,-536(s0)
    80005108:	158b8513          	addi	a0,s7,344
    8000510c:	ffffc097          	auipc	ra,0xffffc
    80005110:	d10080e7          	jalr	-752(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005114:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005118:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000511c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005120:	058bb783          	ld	a5,88(s7)
    80005124:	e6843703          	ld	a4,-408(s0)
    80005128:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000512a:	058bb783          	ld	a5,88(s7)
    8000512e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005132:	85ea                	mv	a1,s10
    80005134:	ffffd097          	auipc	ra,0xffffd
    80005138:	a0e080e7          	jalr	-1522(ra) # 80001b42 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000513c:	0004851b          	sext.w	a0,s1
    80005140:	b3f1                	j	80004f0c <exec+0x9c>
    80005142:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005146:	df843583          	ld	a1,-520(s0)
    8000514a:	855a                	mv	a0,s6
    8000514c:	ffffd097          	auipc	ra,0xffffd
    80005150:	9f6080e7          	jalr	-1546(ra) # 80001b42 <proc_freepagetable>
  if(ip){
    80005154:	da0a92e3          	bnez	s5,80004ef8 <exec+0x88>
  return -1;
    80005158:	557d                	li	a0,-1
    8000515a:	bb4d                	j	80004f0c <exec+0x9c>
    8000515c:	df243c23          	sd	s2,-520(s0)
    80005160:	b7dd                	j	80005146 <exec+0x2d6>
    80005162:	df243c23          	sd	s2,-520(s0)
    80005166:	b7c5                	j	80005146 <exec+0x2d6>
    80005168:	df243c23          	sd	s2,-520(s0)
    8000516c:	bfe9                	j	80005146 <exec+0x2d6>
    8000516e:	df243c23          	sd	s2,-520(s0)
    80005172:	bfd1                	j	80005146 <exec+0x2d6>
  sz = sz1;
    80005174:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005178:	4a81                	li	s5,0
    8000517a:	b7f1                	j	80005146 <exec+0x2d6>
  sz = sz1;
    8000517c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005180:	4a81                	li	s5,0
    80005182:	b7d1                	j	80005146 <exec+0x2d6>
  sz = sz1;
    80005184:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005188:	4a81                	li	s5,0
    8000518a:	bf75                	j	80005146 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000518c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005190:	e0843783          	ld	a5,-504(s0)
    80005194:	0017869b          	addiw	a3,a5,1
    80005198:	e0d43423          	sd	a3,-504(s0)
    8000519c:	e0043783          	ld	a5,-512(s0)
    800051a0:	0387879b          	addiw	a5,a5,56
    800051a4:	e8845703          	lhu	a4,-376(s0)
    800051a8:	e0e6dee3          	bge	a3,a4,80004fc4 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051ac:	2781                	sext.w	a5,a5
    800051ae:	e0f43023          	sd	a5,-512(s0)
    800051b2:	03800713          	li	a4,56
    800051b6:	86be                	mv	a3,a5
    800051b8:	e1840613          	addi	a2,s0,-488
    800051bc:	4581                	li	a1,0
    800051be:	8556                	mv	a0,s5
    800051c0:	fffff097          	auipc	ra,0xfffff
    800051c4:	a5c080e7          	jalr	-1444(ra) # 80003c1c <readi>
    800051c8:	03800793          	li	a5,56
    800051cc:	f6f51be3          	bne	a0,a5,80005142 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    800051d0:	e1842783          	lw	a5,-488(s0)
    800051d4:	4705                	li	a4,1
    800051d6:	fae79de3          	bne	a5,a4,80005190 <exec+0x320>
    if(ph.memsz < ph.filesz)
    800051da:	e4043483          	ld	s1,-448(s0)
    800051de:	e3843783          	ld	a5,-456(s0)
    800051e2:	f6f4ede3          	bltu	s1,a5,8000515c <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051e6:	e2843783          	ld	a5,-472(s0)
    800051ea:	94be                	add	s1,s1,a5
    800051ec:	f6f4ebe3          	bltu	s1,a5,80005162 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800051f0:	de043703          	ld	a4,-544(s0)
    800051f4:	8ff9                	and	a5,a5,a4
    800051f6:	fbad                	bnez	a5,80005168 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051f8:	e1c42503          	lw	a0,-484(s0)
    800051fc:	00000097          	auipc	ra,0x0
    80005200:	c58080e7          	jalr	-936(ra) # 80004e54 <flags2perm>
    80005204:	86aa                	mv	a3,a0
    80005206:	8626                	mv	a2,s1
    80005208:	85ca                	mv	a1,s2
    8000520a:	855a                	mv	a0,s6
    8000520c:	ffffc097          	auipc	ra,0xffffc
    80005210:	23a080e7          	jalr	570(ra) # 80001446 <uvmalloc>
    80005214:	dea43c23          	sd	a0,-520(s0)
    80005218:	d939                	beqz	a0,8000516e <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000521a:	e2843c03          	ld	s8,-472(s0)
    8000521e:	e2042c83          	lw	s9,-480(s0)
    80005222:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005226:	f60b83e3          	beqz	s7,8000518c <exec+0x31c>
    8000522a:	89de                	mv	s3,s7
    8000522c:	4481                	li	s1,0
    8000522e:	bb95                	j	80004fa2 <exec+0x132>

0000000080005230 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005230:	7179                	addi	sp,sp,-48
    80005232:	f406                	sd	ra,40(sp)
    80005234:	f022                	sd	s0,32(sp)
    80005236:	ec26                	sd	s1,24(sp)
    80005238:	e84a                	sd	s2,16(sp)
    8000523a:	1800                	addi	s0,sp,48
    8000523c:	892e                	mv	s2,a1
    8000523e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005240:	fdc40593          	addi	a1,s0,-36
    80005244:	ffffe097          	auipc	ra,0xffffe
    80005248:	a96080e7          	jalr	-1386(ra) # 80002cda <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000524c:	fdc42703          	lw	a4,-36(s0)
    80005250:	47bd                	li	a5,15
    80005252:	02e7eb63          	bltu	a5,a4,80005288 <argfd+0x58>
    80005256:	ffffc097          	auipc	ra,0xffffc
    8000525a:	78c080e7          	jalr	1932(ra) # 800019e2 <myproc>
    8000525e:	fdc42703          	lw	a4,-36(s0)
    80005262:	01a70793          	addi	a5,a4,26
    80005266:	078e                	slli	a5,a5,0x3
    80005268:	953e                	add	a0,a0,a5
    8000526a:	611c                	ld	a5,0(a0)
    8000526c:	c385                	beqz	a5,8000528c <argfd+0x5c>
    return -1;
  if(pfd)
    8000526e:	00090463          	beqz	s2,80005276 <argfd+0x46>
    *pfd = fd;
    80005272:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005276:	4501                	li	a0,0
  if(pf)
    80005278:	c091                	beqz	s1,8000527c <argfd+0x4c>
    *pf = f;
    8000527a:	e09c                	sd	a5,0(s1)
}
    8000527c:	70a2                	ld	ra,40(sp)
    8000527e:	7402                	ld	s0,32(sp)
    80005280:	64e2                	ld	s1,24(sp)
    80005282:	6942                	ld	s2,16(sp)
    80005284:	6145                	addi	sp,sp,48
    80005286:	8082                	ret
    return -1;
    80005288:	557d                	li	a0,-1
    8000528a:	bfcd                	j	8000527c <argfd+0x4c>
    8000528c:	557d                	li	a0,-1
    8000528e:	b7fd                	j	8000527c <argfd+0x4c>

0000000080005290 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005290:	1101                	addi	sp,sp,-32
    80005292:	ec06                	sd	ra,24(sp)
    80005294:	e822                	sd	s0,16(sp)
    80005296:	e426                	sd	s1,8(sp)
    80005298:	1000                	addi	s0,sp,32
    8000529a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	746080e7          	jalr	1862(ra) # 800019e2 <myproc>
    800052a4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052a6:	0d050793          	addi	a5,a0,208
    800052aa:	4501                	li	a0,0
    800052ac:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052ae:	6398                	ld	a4,0(a5)
    800052b0:	cb19                	beqz	a4,800052c6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052b2:	2505                	addiw	a0,a0,1
    800052b4:	07a1                	addi	a5,a5,8
    800052b6:	fed51ce3          	bne	a0,a3,800052ae <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052ba:	557d                	li	a0,-1
}
    800052bc:	60e2                	ld	ra,24(sp)
    800052be:	6442                	ld	s0,16(sp)
    800052c0:	64a2                	ld	s1,8(sp)
    800052c2:	6105                	addi	sp,sp,32
    800052c4:	8082                	ret
      p->ofile[fd] = f;
    800052c6:	01a50793          	addi	a5,a0,26
    800052ca:	078e                	slli	a5,a5,0x3
    800052cc:	963e                	add	a2,a2,a5
    800052ce:	e204                	sd	s1,0(a2)
      return fd;
    800052d0:	b7f5                	j	800052bc <fdalloc+0x2c>

00000000800052d2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052d2:	715d                	addi	sp,sp,-80
    800052d4:	e486                	sd	ra,72(sp)
    800052d6:	e0a2                	sd	s0,64(sp)
    800052d8:	fc26                	sd	s1,56(sp)
    800052da:	f84a                	sd	s2,48(sp)
    800052dc:	f44e                	sd	s3,40(sp)
    800052de:	f052                	sd	s4,32(sp)
    800052e0:	ec56                	sd	s5,24(sp)
    800052e2:	e85a                	sd	s6,16(sp)
    800052e4:	0880                	addi	s0,sp,80
    800052e6:	8b2e                	mv	s6,a1
    800052e8:	89b2                	mv	s3,a2
    800052ea:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052ec:	fb040593          	addi	a1,s0,-80
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	e3c080e7          	jalr	-452(ra) # 8000412c <nameiparent>
    800052f8:	84aa                	mv	s1,a0
    800052fa:	14050f63          	beqz	a0,80005458 <create+0x186>
    return 0;

  ilock(dp);
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	66a080e7          	jalr	1642(ra) # 80003968 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005306:	4601                	li	a2,0
    80005308:	fb040593          	addi	a1,s0,-80
    8000530c:	8526                	mv	a0,s1
    8000530e:	fffff097          	auipc	ra,0xfffff
    80005312:	b3e080e7          	jalr	-1218(ra) # 80003e4c <dirlookup>
    80005316:	8aaa                	mv	s5,a0
    80005318:	c931                	beqz	a0,8000536c <create+0x9a>
    iunlockput(dp);
    8000531a:	8526                	mv	a0,s1
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	8ae080e7          	jalr	-1874(ra) # 80003bca <iunlockput>
    ilock(ip);
    80005324:	8556                	mv	a0,s5
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	642080e7          	jalr	1602(ra) # 80003968 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000532e:	000b059b          	sext.w	a1,s6
    80005332:	4789                	li	a5,2
    80005334:	02f59563          	bne	a1,a5,8000535e <create+0x8c>
    80005338:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd827c>
    8000533c:	37f9                	addiw	a5,a5,-2
    8000533e:	17c2                	slli	a5,a5,0x30
    80005340:	93c1                	srli	a5,a5,0x30
    80005342:	4705                	li	a4,1
    80005344:	00f76d63          	bltu	a4,a5,8000535e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005348:	8556                	mv	a0,s5
    8000534a:	60a6                	ld	ra,72(sp)
    8000534c:	6406                	ld	s0,64(sp)
    8000534e:	74e2                	ld	s1,56(sp)
    80005350:	7942                	ld	s2,48(sp)
    80005352:	79a2                	ld	s3,40(sp)
    80005354:	7a02                	ld	s4,32(sp)
    80005356:	6ae2                	ld	s5,24(sp)
    80005358:	6b42                	ld	s6,16(sp)
    8000535a:	6161                	addi	sp,sp,80
    8000535c:	8082                	ret
    iunlockput(ip);
    8000535e:	8556                	mv	a0,s5
    80005360:	fffff097          	auipc	ra,0xfffff
    80005364:	86a080e7          	jalr	-1942(ra) # 80003bca <iunlockput>
    return 0;
    80005368:	4a81                	li	s5,0
    8000536a:	bff9                	j	80005348 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000536c:	85da                	mv	a1,s6
    8000536e:	4088                	lw	a0,0(s1)
    80005370:	ffffe097          	auipc	ra,0xffffe
    80005374:	45c080e7          	jalr	1116(ra) # 800037cc <ialloc>
    80005378:	8a2a                	mv	s4,a0
    8000537a:	c539                	beqz	a0,800053c8 <create+0xf6>
  ilock(ip);
    8000537c:	ffffe097          	auipc	ra,0xffffe
    80005380:	5ec080e7          	jalr	1516(ra) # 80003968 <ilock>
  ip->major = major;
    80005384:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005388:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000538c:	4905                	li	s2,1
    8000538e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005392:	8552                	mv	a0,s4
    80005394:	ffffe097          	auipc	ra,0xffffe
    80005398:	50a080e7          	jalr	1290(ra) # 8000389e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000539c:	000b059b          	sext.w	a1,s6
    800053a0:	03258b63          	beq	a1,s2,800053d6 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800053a4:	004a2603          	lw	a2,4(s4)
    800053a8:	fb040593          	addi	a1,s0,-80
    800053ac:	8526                	mv	a0,s1
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	cae080e7          	jalr	-850(ra) # 8000405c <dirlink>
    800053b6:	06054f63          	bltz	a0,80005434 <create+0x162>
  iunlockput(dp);
    800053ba:	8526                	mv	a0,s1
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	80e080e7          	jalr	-2034(ra) # 80003bca <iunlockput>
  return ip;
    800053c4:	8ad2                	mv	s5,s4
    800053c6:	b749                	j	80005348 <create+0x76>
    iunlockput(dp);
    800053c8:	8526                	mv	a0,s1
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	800080e7          	jalr	-2048(ra) # 80003bca <iunlockput>
    return 0;
    800053d2:	8ad2                	mv	s5,s4
    800053d4:	bf95                	j	80005348 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053d6:	004a2603          	lw	a2,4(s4)
    800053da:	00003597          	auipc	a1,0x3
    800053de:	51e58593          	addi	a1,a1,1310 # 800088f8 <syscalls+0x3d8>
    800053e2:	8552                	mv	a0,s4
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	c78080e7          	jalr	-904(ra) # 8000405c <dirlink>
    800053ec:	04054463          	bltz	a0,80005434 <create+0x162>
    800053f0:	40d0                	lw	a2,4(s1)
    800053f2:	00003597          	auipc	a1,0x3
    800053f6:	50e58593          	addi	a1,a1,1294 # 80008900 <syscalls+0x3e0>
    800053fa:	8552                	mv	a0,s4
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	c60080e7          	jalr	-928(ra) # 8000405c <dirlink>
    80005404:	02054863          	bltz	a0,80005434 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005408:	004a2603          	lw	a2,4(s4)
    8000540c:	fb040593          	addi	a1,s0,-80
    80005410:	8526                	mv	a0,s1
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	c4a080e7          	jalr	-950(ra) # 8000405c <dirlink>
    8000541a:	00054d63          	bltz	a0,80005434 <create+0x162>
    dp->nlink++;  // for ".."
    8000541e:	04a4d783          	lhu	a5,74(s1)
    80005422:	2785                	addiw	a5,a5,1
    80005424:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005428:	8526                	mv	a0,s1
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	474080e7          	jalr	1140(ra) # 8000389e <iupdate>
    80005432:	b761                	j	800053ba <create+0xe8>
  ip->nlink = 0;
    80005434:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005438:	8552                	mv	a0,s4
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	464080e7          	jalr	1124(ra) # 8000389e <iupdate>
  iunlockput(ip);
    80005442:	8552                	mv	a0,s4
    80005444:	ffffe097          	auipc	ra,0xffffe
    80005448:	786080e7          	jalr	1926(ra) # 80003bca <iunlockput>
  iunlockput(dp);
    8000544c:	8526                	mv	a0,s1
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	77c080e7          	jalr	1916(ra) # 80003bca <iunlockput>
  return 0;
    80005456:	bdcd                	j	80005348 <create+0x76>
    return 0;
    80005458:	8aaa                	mv	s5,a0
    8000545a:	b5fd                	j	80005348 <create+0x76>

000000008000545c <sys_dup>:
{
    8000545c:	7179                	addi	sp,sp,-48
    8000545e:	f406                	sd	ra,40(sp)
    80005460:	f022                	sd	s0,32(sp)
    80005462:	ec26                	sd	s1,24(sp)
    80005464:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005466:	fd840613          	addi	a2,s0,-40
    8000546a:	4581                	li	a1,0
    8000546c:	4501                	li	a0,0
    8000546e:	00000097          	auipc	ra,0x0
    80005472:	dc2080e7          	jalr	-574(ra) # 80005230 <argfd>
    return -1;
    80005476:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005478:	02054363          	bltz	a0,8000549e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000547c:	fd843503          	ld	a0,-40(s0)
    80005480:	00000097          	auipc	ra,0x0
    80005484:	e10080e7          	jalr	-496(ra) # 80005290 <fdalloc>
    80005488:	84aa                	mv	s1,a0
    return -1;
    8000548a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000548c:	00054963          	bltz	a0,8000549e <sys_dup+0x42>
  filedup(f);
    80005490:	fd843503          	ld	a0,-40(s0)
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	310080e7          	jalr	784(ra) # 800047a4 <filedup>
  return fd;
    8000549c:	87a6                	mv	a5,s1
}
    8000549e:	853e                	mv	a0,a5
    800054a0:	70a2                	ld	ra,40(sp)
    800054a2:	7402                	ld	s0,32(sp)
    800054a4:	64e2                	ld	s1,24(sp)
    800054a6:	6145                	addi	sp,sp,48
    800054a8:	8082                	ret

00000000800054aa <sys_read>:
{
    800054aa:	7179                	addi	sp,sp,-48
    800054ac:	f406                	sd	ra,40(sp)
    800054ae:	f022                	sd	s0,32(sp)
    800054b0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054b2:	fd840593          	addi	a1,s0,-40
    800054b6:	4505                	li	a0,1
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	842080e7          	jalr	-1982(ra) # 80002cfa <argaddr>
  argint(2, &n);
    800054c0:	fe440593          	addi	a1,s0,-28
    800054c4:	4509                	li	a0,2
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	814080e7          	jalr	-2028(ra) # 80002cda <argint>
  if(argfd(0, 0, &f) < 0)
    800054ce:	fe840613          	addi	a2,s0,-24
    800054d2:	4581                	li	a1,0
    800054d4:	4501                	li	a0,0
    800054d6:	00000097          	auipc	ra,0x0
    800054da:	d5a080e7          	jalr	-678(ra) # 80005230 <argfd>
    800054de:	87aa                	mv	a5,a0
    return -1;
    800054e0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054e2:	0007cc63          	bltz	a5,800054fa <sys_read+0x50>
  return fileread(f, p, n);
    800054e6:	fe442603          	lw	a2,-28(s0)
    800054ea:	fd843583          	ld	a1,-40(s0)
    800054ee:	fe843503          	ld	a0,-24(s0)
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	43e080e7          	jalr	1086(ra) # 80004930 <fileread>
}
    800054fa:	70a2                	ld	ra,40(sp)
    800054fc:	7402                	ld	s0,32(sp)
    800054fe:	6145                	addi	sp,sp,48
    80005500:	8082                	ret

0000000080005502 <sys_write>:
{
    80005502:	7179                	addi	sp,sp,-48
    80005504:	f406                	sd	ra,40(sp)
    80005506:	f022                	sd	s0,32(sp)
    80005508:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000550a:	fd840593          	addi	a1,s0,-40
    8000550e:	4505                	li	a0,1
    80005510:	ffffd097          	auipc	ra,0xffffd
    80005514:	7ea080e7          	jalr	2026(ra) # 80002cfa <argaddr>
  argint(2, &n);
    80005518:	fe440593          	addi	a1,s0,-28
    8000551c:	4509                	li	a0,2
    8000551e:	ffffd097          	auipc	ra,0xffffd
    80005522:	7bc080e7          	jalr	1980(ra) # 80002cda <argint>
  if(argfd(0, 0, &f) < 0)
    80005526:	fe840613          	addi	a2,s0,-24
    8000552a:	4581                	li	a1,0
    8000552c:	4501                	li	a0,0
    8000552e:	00000097          	auipc	ra,0x0
    80005532:	d02080e7          	jalr	-766(ra) # 80005230 <argfd>
    80005536:	87aa                	mv	a5,a0
    return -1;
    80005538:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000553a:	0007cc63          	bltz	a5,80005552 <sys_write+0x50>
  return filewrite(f, p, n);
    8000553e:	fe442603          	lw	a2,-28(s0)
    80005542:	fd843583          	ld	a1,-40(s0)
    80005546:	fe843503          	ld	a0,-24(s0)
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	4a8080e7          	jalr	1192(ra) # 800049f2 <filewrite>
}
    80005552:	70a2                	ld	ra,40(sp)
    80005554:	7402                	ld	s0,32(sp)
    80005556:	6145                	addi	sp,sp,48
    80005558:	8082                	ret

000000008000555a <sys_close>:
{
    8000555a:	1101                	addi	sp,sp,-32
    8000555c:	ec06                	sd	ra,24(sp)
    8000555e:	e822                	sd	s0,16(sp)
    80005560:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005562:	fe040613          	addi	a2,s0,-32
    80005566:	fec40593          	addi	a1,s0,-20
    8000556a:	4501                	li	a0,0
    8000556c:	00000097          	auipc	ra,0x0
    80005570:	cc4080e7          	jalr	-828(ra) # 80005230 <argfd>
    return -1;
    80005574:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005576:	02054463          	bltz	a0,8000559e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000557a:	ffffc097          	auipc	ra,0xffffc
    8000557e:	468080e7          	jalr	1128(ra) # 800019e2 <myproc>
    80005582:	fec42783          	lw	a5,-20(s0)
    80005586:	07e9                	addi	a5,a5,26
    80005588:	078e                	slli	a5,a5,0x3
    8000558a:	97aa                	add	a5,a5,a0
    8000558c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005590:	fe043503          	ld	a0,-32(s0)
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	262080e7          	jalr	610(ra) # 800047f6 <fileclose>
  return 0;
    8000559c:	4781                	li	a5,0
}
    8000559e:	853e                	mv	a0,a5
    800055a0:	60e2                	ld	ra,24(sp)
    800055a2:	6442                	ld	s0,16(sp)
    800055a4:	6105                	addi	sp,sp,32
    800055a6:	8082                	ret

00000000800055a8 <sys_fstat>:
{
    800055a8:	1101                	addi	sp,sp,-32
    800055aa:	ec06                	sd	ra,24(sp)
    800055ac:	e822                	sd	s0,16(sp)
    800055ae:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800055b0:	fe040593          	addi	a1,s0,-32
    800055b4:	4505                	li	a0,1
    800055b6:	ffffd097          	auipc	ra,0xffffd
    800055ba:	744080e7          	jalr	1860(ra) # 80002cfa <argaddr>
  if(argfd(0, 0, &f) < 0)
    800055be:	fe840613          	addi	a2,s0,-24
    800055c2:	4581                	li	a1,0
    800055c4:	4501                	li	a0,0
    800055c6:	00000097          	auipc	ra,0x0
    800055ca:	c6a080e7          	jalr	-918(ra) # 80005230 <argfd>
    800055ce:	87aa                	mv	a5,a0
    return -1;
    800055d0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055d2:	0007ca63          	bltz	a5,800055e6 <sys_fstat+0x3e>
  return filestat(f, st);
    800055d6:	fe043583          	ld	a1,-32(s0)
    800055da:	fe843503          	ld	a0,-24(s0)
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	2e0080e7          	jalr	736(ra) # 800048be <filestat>
}
    800055e6:	60e2                	ld	ra,24(sp)
    800055e8:	6442                	ld	s0,16(sp)
    800055ea:	6105                	addi	sp,sp,32
    800055ec:	8082                	ret

00000000800055ee <sys_link>:
{
    800055ee:	7169                	addi	sp,sp,-304
    800055f0:	f606                	sd	ra,296(sp)
    800055f2:	f222                	sd	s0,288(sp)
    800055f4:	ee26                	sd	s1,280(sp)
    800055f6:	ea4a                	sd	s2,272(sp)
    800055f8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055fa:	08000613          	li	a2,128
    800055fe:	ed040593          	addi	a1,s0,-304
    80005602:	4501                	li	a0,0
    80005604:	ffffd097          	auipc	ra,0xffffd
    80005608:	716080e7          	jalr	1814(ra) # 80002d1a <argstr>
    return -1;
    8000560c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000560e:	10054e63          	bltz	a0,8000572a <sys_link+0x13c>
    80005612:	08000613          	li	a2,128
    80005616:	f5040593          	addi	a1,s0,-176
    8000561a:	4505                	li	a0,1
    8000561c:	ffffd097          	auipc	ra,0xffffd
    80005620:	6fe080e7          	jalr	1790(ra) # 80002d1a <argstr>
    return -1;
    80005624:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005626:	10054263          	bltz	a0,8000572a <sys_link+0x13c>
  begin_op();
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	d00080e7          	jalr	-768(ra) # 8000432a <begin_op>
  if((ip = namei(old)) == 0){
    80005632:	ed040513          	addi	a0,s0,-304
    80005636:	fffff097          	auipc	ra,0xfffff
    8000563a:	ad8080e7          	jalr	-1320(ra) # 8000410e <namei>
    8000563e:	84aa                	mv	s1,a0
    80005640:	c551                	beqz	a0,800056cc <sys_link+0xde>
  ilock(ip);
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	326080e7          	jalr	806(ra) # 80003968 <ilock>
  if(ip->type == T_DIR){
    8000564a:	04449703          	lh	a4,68(s1)
    8000564e:	4785                	li	a5,1
    80005650:	08f70463          	beq	a4,a5,800056d8 <sys_link+0xea>
  ip->nlink++;
    80005654:	04a4d783          	lhu	a5,74(s1)
    80005658:	2785                	addiw	a5,a5,1
    8000565a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000565e:	8526                	mv	a0,s1
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	23e080e7          	jalr	574(ra) # 8000389e <iupdate>
  iunlock(ip);
    80005668:	8526                	mv	a0,s1
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	3c0080e7          	jalr	960(ra) # 80003a2a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005672:	fd040593          	addi	a1,s0,-48
    80005676:	f5040513          	addi	a0,s0,-176
    8000567a:	fffff097          	auipc	ra,0xfffff
    8000567e:	ab2080e7          	jalr	-1358(ra) # 8000412c <nameiparent>
    80005682:	892a                	mv	s2,a0
    80005684:	c935                	beqz	a0,800056f8 <sys_link+0x10a>
  ilock(dp);
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	2e2080e7          	jalr	738(ra) # 80003968 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000568e:	00092703          	lw	a4,0(s2)
    80005692:	409c                	lw	a5,0(s1)
    80005694:	04f71d63          	bne	a4,a5,800056ee <sys_link+0x100>
    80005698:	40d0                	lw	a2,4(s1)
    8000569a:	fd040593          	addi	a1,s0,-48
    8000569e:	854a                	mv	a0,s2
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	9bc080e7          	jalr	-1604(ra) # 8000405c <dirlink>
    800056a8:	04054363          	bltz	a0,800056ee <sys_link+0x100>
  iunlockput(dp);
    800056ac:	854a                	mv	a0,s2
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	51c080e7          	jalr	1308(ra) # 80003bca <iunlockput>
  iput(ip);
    800056b6:	8526                	mv	a0,s1
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	46a080e7          	jalr	1130(ra) # 80003b22 <iput>
  end_op();
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	cea080e7          	jalr	-790(ra) # 800043aa <end_op>
  return 0;
    800056c8:	4781                	li	a5,0
    800056ca:	a085                	j	8000572a <sys_link+0x13c>
    end_op();
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	cde080e7          	jalr	-802(ra) # 800043aa <end_op>
    return -1;
    800056d4:	57fd                	li	a5,-1
    800056d6:	a891                	j	8000572a <sys_link+0x13c>
    iunlockput(ip);
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	4f0080e7          	jalr	1264(ra) # 80003bca <iunlockput>
    end_op();
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	cc8080e7          	jalr	-824(ra) # 800043aa <end_op>
    return -1;
    800056ea:	57fd                	li	a5,-1
    800056ec:	a83d                	j	8000572a <sys_link+0x13c>
    iunlockput(dp);
    800056ee:	854a                	mv	a0,s2
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	4da080e7          	jalr	1242(ra) # 80003bca <iunlockput>
  ilock(ip);
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	26e080e7          	jalr	622(ra) # 80003968 <ilock>
  ip->nlink--;
    80005702:	04a4d783          	lhu	a5,74(s1)
    80005706:	37fd                	addiw	a5,a5,-1
    80005708:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000570c:	8526                	mv	a0,s1
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	190080e7          	jalr	400(ra) # 8000389e <iupdate>
  iunlockput(ip);
    80005716:	8526                	mv	a0,s1
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	4b2080e7          	jalr	1202(ra) # 80003bca <iunlockput>
  end_op();
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	c8a080e7          	jalr	-886(ra) # 800043aa <end_op>
  return -1;
    80005728:	57fd                	li	a5,-1
}
    8000572a:	853e                	mv	a0,a5
    8000572c:	70b2                	ld	ra,296(sp)
    8000572e:	7412                	ld	s0,288(sp)
    80005730:	64f2                	ld	s1,280(sp)
    80005732:	6952                	ld	s2,272(sp)
    80005734:	6155                	addi	sp,sp,304
    80005736:	8082                	ret

0000000080005738 <sys_unlink>:
{
    80005738:	7151                	addi	sp,sp,-240
    8000573a:	f586                	sd	ra,232(sp)
    8000573c:	f1a2                	sd	s0,224(sp)
    8000573e:	eda6                	sd	s1,216(sp)
    80005740:	e9ca                	sd	s2,208(sp)
    80005742:	e5ce                	sd	s3,200(sp)
    80005744:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005746:	08000613          	li	a2,128
    8000574a:	f3040593          	addi	a1,s0,-208
    8000574e:	4501                	li	a0,0
    80005750:	ffffd097          	auipc	ra,0xffffd
    80005754:	5ca080e7          	jalr	1482(ra) # 80002d1a <argstr>
    80005758:	18054163          	bltz	a0,800058da <sys_unlink+0x1a2>
  begin_op();
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	bce080e7          	jalr	-1074(ra) # 8000432a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005764:	fb040593          	addi	a1,s0,-80
    80005768:	f3040513          	addi	a0,s0,-208
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	9c0080e7          	jalr	-1600(ra) # 8000412c <nameiparent>
    80005774:	84aa                	mv	s1,a0
    80005776:	c979                	beqz	a0,8000584c <sys_unlink+0x114>
  ilock(dp);
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	1f0080e7          	jalr	496(ra) # 80003968 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005780:	00003597          	auipc	a1,0x3
    80005784:	17858593          	addi	a1,a1,376 # 800088f8 <syscalls+0x3d8>
    80005788:	fb040513          	addi	a0,s0,-80
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	6a6080e7          	jalr	1702(ra) # 80003e32 <namecmp>
    80005794:	14050a63          	beqz	a0,800058e8 <sys_unlink+0x1b0>
    80005798:	00003597          	auipc	a1,0x3
    8000579c:	16858593          	addi	a1,a1,360 # 80008900 <syscalls+0x3e0>
    800057a0:	fb040513          	addi	a0,s0,-80
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	68e080e7          	jalr	1678(ra) # 80003e32 <namecmp>
    800057ac:	12050e63          	beqz	a0,800058e8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057b0:	f2c40613          	addi	a2,s0,-212
    800057b4:	fb040593          	addi	a1,s0,-80
    800057b8:	8526                	mv	a0,s1
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	692080e7          	jalr	1682(ra) # 80003e4c <dirlookup>
    800057c2:	892a                	mv	s2,a0
    800057c4:	12050263          	beqz	a0,800058e8 <sys_unlink+0x1b0>
  ilock(ip);
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	1a0080e7          	jalr	416(ra) # 80003968 <ilock>
  if(ip->nlink < 1)
    800057d0:	04a91783          	lh	a5,74(s2)
    800057d4:	08f05263          	blez	a5,80005858 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057d8:	04491703          	lh	a4,68(s2)
    800057dc:	4785                	li	a5,1
    800057de:	08f70563          	beq	a4,a5,80005868 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057e2:	4641                	li	a2,16
    800057e4:	4581                	li	a1,0
    800057e6:	fc040513          	addi	a0,s0,-64
    800057ea:	ffffb097          	auipc	ra,0xffffb
    800057ee:	4e8080e7          	jalr	1256(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057f2:	4741                	li	a4,16
    800057f4:	f2c42683          	lw	a3,-212(s0)
    800057f8:	fc040613          	addi	a2,s0,-64
    800057fc:	4581                	li	a1,0
    800057fe:	8526                	mv	a0,s1
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	514080e7          	jalr	1300(ra) # 80003d14 <writei>
    80005808:	47c1                	li	a5,16
    8000580a:	0af51563          	bne	a0,a5,800058b4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000580e:	04491703          	lh	a4,68(s2)
    80005812:	4785                	li	a5,1
    80005814:	0af70863          	beq	a4,a5,800058c4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005818:	8526                	mv	a0,s1
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	3b0080e7          	jalr	944(ra) # 80003bca <iunlockput>
  ip->nlink--;
    80005822:	04a95783          	lhu	a5,74(s2)
    80005826:	37fd                	addiw	a5,a5,-1
    80005828:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000582c:	854a                	mv	a0,s2
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	070080e7          	jalr	112(ra) # 8000389e <iupdate>
  iunlockput(ip);
    80005836:	854a                	mv	a0,s2
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	392080e7          	jalr	914(ra) # 80003bca <iunlockput>
  end_op();
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	b6a080e7          	jalr	-1174(ra) # 800043aa <end_op>
  return 0;
    80005848:	4501                	li	a0,0
    8000584a:	a84d                	j	800058fc <sys_unlink+0x1c4>
    end_op();
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	b5e080e7          	jalr	-1186(ra) # 800043aa <end_op>
    return -1;
    80005854:	557d                	li	a0,-1
    80005856:	a05d                	j	800058fc <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005858:	00003517          	auipc	a0,0x3
    8000585c:	0b050513          	addi	a0,a0,176 # 80008908 <syscalls+0x3e8>
    80005860:	ffffb097          	auipc	ra,0xffffb
    80005864:	cde080e7          	jalr	-802(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005868:	04c92703          	lw	a4,76(s2)
    8000586c:	02000793          	li	a5,32
    80005870:	f6e7f9e3          	bgeu	a5,a4,800057e2 <sys_unlink+0xaa>
    80005874:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005878:	4741                	li	a4,16
    8000587a:	86ce                	mv	a3,s3
    8000587c:	f1840613          	addi	a2,s0,-232
    80005880:	4581                	li	a1,0
    80005882:	854a                	mv	a0,s2
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	398080e7          	jalr	920(ra) # 80003c1c <readi>
    8000588c:	47c1                	li	a5,16
    8000588e:	00f51b63          	bne	a0,a5,800058a4 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005892:	f1845783          	lhu	a5,-232(s0)
    80005896:	e7a1                	bnez	a5,800058de <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005898:	29c1                	addiw	s3,s3,16
    8000589a:	04c92783          	lw	a5,76(s2)
    8000589e:	fcf9ede3          	bltu	s3,a5,80005878 <sys_unlink+0x140>
    800058a2:	b781                	j	800057e2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058a4:	00003517          	auipc	a0,0x3
    800058a8:	07c50513          	addi	a0,a0,124 # 80008920 <syscalls+0x400>
    800058ac:	ffffb097          	auipc	ra,0xffffb
    800058b0:	c92080e7          	jalr	-878(ra) # 8000053e <panic>
    panic("unlink: writei");
    800058b4:	00003517          	auipc	a0,0x3
    800058b8:	08450513          	addi	a0,a0,132 # 80008938 <syscalls+0x418>
    800058bc:	ffffb097          	auipc	ra,0xffffb
    800058c0:	c82080e7          	jalr	-894(ra) # 8000053e <panic>
    dp->nlink--;
    800058c4:	04a4d783          	lhu	a5,74(s1)
    800058c8:	37fd                	addiw	a5,a5,-1
    800058ca:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058ce:	8526                	mv	a0,s1
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	fce080e7          	jalr	-50(ra) # 8000389e <iupdate>
    800058d8:	b781                	j	80005818 <sys_unlink+0xe0>
    return -1;
    800058da:	557d                	li	a0,-1
    800058dc:	a005                	j	800058fc <sys_unlink+0x1c4>
    iunlockput(ip);
    800058de:	854a                	mv	a0,s2
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	2ea080e7          	jalr	746(ra) # 80003bca <iunlockput>
  iunlockput(dp);
    800058e8:	8526                	mv	a0,s1
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	2e0080e7          	jalr	736(ra) # 80003bca <iunlockput>
  end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	ab8080e7          	jalr	-1352(ra) # 800043aa <end_op>
  return -1;
    800058fa:	557d                	li	a0,-1
}
    800058fc:	70ae                	ld	ra,232(sp)
    800058fe:	740e                	ld	s0,224(sp)
    80005900:	64ee                	ld	s1,216(sp)
    80005902:	694e                	ld	s2,208(sp)
    80005904:	69ae                	ld	s3,200(sp)
    80005906:	616d                	addi	sp,sp,240
    80005908:	8082                	ret

000000008000590a <sys_open>:

uint64
sys_open(void)
{
    8000590a:	7131                	addi	sp,sp,-192
    8000590c:	fd06                	sd	ra,184(sp)
    8000590e:	f922                	sd	s0,176(sp)
    80005910:	f526                	sd	s1,168(sp)
    80005912:	f14a                	sd	s2,160(sp)
    80005914:	ed4e                	sd	s3,152(sp)
    80005916:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005918:	f4c40593          	addi	a1,s0,-180
    8000591c:	4505                	li	a0,1
    8000591e:	ffffd097          	auipc	ra,0xffffd
    80005922:	3bc080e7          	jalr	956(ra) # 80002cda <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005926:	08000613          	li	a2,128
    8000592a:	f5040593          	addi	a1,s0,-176
    8000592e:	4501                	li	a0,0
    80005930:	ffffd097          	auipc	ra,0xffffd
    80005934:	3ea080e7          	jalr	1002(ra) # 80002d1a <argstr>
    80005938:	87aa                	mv	a5,a0
    return -1;
    8000593a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000593c:	0a07c963          	bltz	a5,800059ee <sys_open+0xe4>

  begin_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	9ea080e7          	jalr	-1558(ra) # 8000432a <begin_op>

  if(omode & O_CREATE){
    80005948:	f4c42783          	lw	a5,-180(s0)
    8000594c:	2007f793          	andi	a5,a5,512
    80005950:	cfc5                	beqz	a5,80005a08 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005952:	4681                	li	a3,0
    80005954:	4601                	li	a2,0
    80005956:	4589                	li	a1,2
    80005958:	f5040513          	addi	a0,s0,-176
    8000595c:	00000097          	auipc	ra,0x0
    80005960:	976080e7          	jalr	-1674(ra) # 800052d2 <create>
    80005964:	84aa                	mv	s1,a0
    if(ip == 0){
    80005966:	c959                	beqz	a0,800059fc <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005968:	04449703          	lh	a4,68(s1)
    8000596c:	478d                	li	a5,3
    8000596e:	00f71763          	bne	a4,a5,8000597c <sys_open+0x72>
    80005972:	0464d703          	lhu	a4,70(s1)
    80005976:	47a5                	li	a5,9
    80005978:	0ce7ed63          	bltu	a5,a4,80005a52 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	dbe080e7          	jalr	-578(ra) # 8000473a <filealloc>
    80005984:	89aa                	mv	s3,a0
    80005986:	10050363          	beqz	a0,80005a8c <sys_open+0x182>
    8000598a:	00000097          	auipc	ra,0x0
    8000598e:	906080e7          	jalr	-1786(ra) # 80005290 <fdalloc>
    80005992:	892a                	mv	s2,a0
    80005994:	0e054763          	bltz	a0,80005a82 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005998:	04449703          	lh	a4,68(s1)
    8000599c:	478d                	li	a5,3
    8000599e:	0cf70563          	beq	a4,a5,80005a68 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059a2:	4789                	li	a5,2
    800059a4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059a8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059ac:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059b0:	f4c42783          	lw	a5,-180(s0)
    800059b4:	0017c713          	xori	a4,a5,1
    800059b8:	8b05                	andi	a4,a4,1
    800059ba:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059be:	0037f713          	andi	a4,a5,3
    800059c2:	00e03733          	snez	a4,a4
    800059c6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059ca:	4007f793          	andi	a5,a5,1024
    800059ce:	c791                	beqz	a5,800059da <sys_open+0xd0>
    800059d0:	04449703          	lh	a4,68(s1)
    800059d4:	4789                	li	a5,2
    800059d6:	0af70063          	beq	a4,a5,80005a76 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059da:	8526                	mv	a0,s1
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	04e080e7          	jalr	78(ra) # 80003a2a <iunlock>
  end_op();
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	9c6080e7          	jalr	-1594(ra) # 800043aa <end_op>

  return fd;
    800059ec:	854a                	mv	a0,s2
}
    800059ee:	70ea                	ld	ra,184(sp)
    800059f0:	744a                	ld	s0,176(sp)
    800059f2:	74aa                	ld	s1,168(sp)
    800059f4:	790a                	ld	s2,160(sp)
    800059f6:	69ea                	ld	s3,152(sp)
    800059f8:	6129                	addi	sp,sp,192
    800059fa:	8082                	ret
      end_op();
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	9ae080e7          	jalr	-1618(ra) # 800043aa <end_op>
      return -1;
    80005a04:	557d                	li	a0,-1
    80005a06:	b7e5                	j	800059ee <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a08:	f5040513          	addi	a0,s0,-176
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	702080e7          	jalr	1794(ra) # 8000410e <namei>
    80005a14:	84aa                	mv	s1,a0
    80005a16:	c905                	beqz	a0,80005a46 <sys_open+0x13c>
    ilock(ip);
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	f50080e7          	jalr	-176(ra) # 80003968 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a20:	04449703          	lh	a4,68(s1)
    80005a24:	4785                	li	a5,1
    80005a26:	f4f711e3          	bne	a4,a5,80005968 <sys_open+0x5e>
    80005a2a:	f4c42783          	lw	a5,-180(s0)
    80005a2e:	d7b9                	beqz	a5,8000597c <sys_open+0x72>
      iunlockput(ip);
    80005a30:	8526                	mv	a0,s1
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	198080e7          	jalr	408(ra) # 80003bca <iunlockput>
      end_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	970080e7          	jalr	-1680(ra) # 800043aa <end_op>
      return -1;
    80005a42:	557d                	li	a0,-1
    80005a44:	b76d                	j	800059ee <sys_open+0xe4>
      end_op();
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	964080e7          	jalr	-1692(ra) # 800043aa <end_op>
      return -1;
    80005a4e:	557d                	li	a0,-1
    80005a50:	bf79                	j	800059ee <sys_open+0xe4>
    iunlockput(ip);
    80005a52:	8526                	mv	a0,s1
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	176080e7          	jalr	374(ra) # 80003bca <iunlockput>
    end_op();
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	94e080e7          	jalr	-1714(ra) # 800043aa <end_op>
    return -1;
    80005a64:	557d                	li	a0,-1
    80005a66:	b761                	j	800059ee <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a68:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a6c:	04649783          	lh	a5,70(s1)
    80005a70:	02f99223          	sh	a5,36(s3)
    80005a74:	bf25                	j	800059ac <sys_open+0xa2>
    itrunc(ip);
    80005a76:	8526                	mv	a0,s1
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	ffe080e7          	jalr	-2(ra) # 80003a76 <itrunc>
    80005a80:	bfa9                	j	800059da <sys_open+0xd0>
      fileclose(f);
    80005a82:	854e                	mv	a0,s3
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	d72080e7          	jalr	-654(ra) # 800047f6 <fileclose>
    iunlockput(ip);
    80005a8c:	8526                	mv	a0,s1
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	13c080e7          	jalr	316(ra) # 80003bca <iunlockput>
    end_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	914080e7          	jalr	-1772(ra) # 800043aa <end_op>
    return -1;
    80005a9e:	557d                	li	a0,-1
    80005aa0:	b7b9                	j	800059ee <sys_open+0xe4>

0000000080005aa2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005aa2:	7175                	addi	sp,sp,-144
    80005aa4:	e506                	sd	ra,136(sp)
    80005aa6:	e122                	sd	s0,128(sp)
    80005aa8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	880080e7          	jalr	-1920(ra) # 8000432a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ab2:	08000613          	li	a2,128
    80005ab6:	f7040593          	addi	a1,s0,-144
    80005aba:	4501                	li	a0,0
    80005abc:	ffffd097          	auipc	ra,0xffffd
    80005ac0:	25e080e7          	jalr	606(ra) # 80002d1a <argstr>
    80005ac4:	02054963          	bltz	a0,80005af6 <sys_mkdir+0x54>
    80005ac8:	4681                	li	a3,0
    80005aca:	4601                	li	a2,0
    80005acc:	4585                	li	a1,1
    80005ace:	f7040513          	addi	a0,s0,-144
    80005ad2:	00000097          	auipc	ra,0x0
    80005ad6:	800080e7          	jalr	-2048(ra) # 800052d2 <create>
    80005ada:	cd11                	beqz	a0,80005af6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	0ee080e7          	jalr	238(ra) # 80003bca <iunlockput>
  end_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	8c6080e7          	jalr	-1850(ra) # 800043aa <end_op>
  return 0;
    80005aec:	4501                	li	a0,0
}
    80005aee:	60aa                	ld	ra,136(sp)
    80005af0:	640a                	ld	s0,128(sp)
    80005af2:	6149                	addi	sp,sp,144
    80005af4:	8082                	ret
    end_op();
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	8b4080e7          	jalr	-1868(ra) # 800043aa <end_op>
    return -1;
    80005afe:	557d                	li	a0,-1
    80005b00:	b7fd                	j	80005aee <sys_mkdir+0x4c>

0000000080005b02 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b02:	7135                	addi	sp,sp,-160
    80005b04:	ed06                	sd	ra,152(sp)
    80005b06:	e922                	sd	s0,144(sp)
    80005b08:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	820080e7          	jalr	-2016(ra) # 8000432a <begin_op>
  argint(1, &major);
    80005b12:	f6c40593          	addi	a1,s0,-148
    80005b16:	4505                	li	a0,1
    80005b18:	ffffd097          	auipc	ra,0xffffd
    80005b1c:	1c2080e7          	jalr	450(ra) # 80002cda <argint>
  argint(2, &minor);
    80005b20:	f6840593          	addi	a1,s0,-152
    80005b24:	4509                	li	a0,2
    80005b26:	ffffd097          	auipc	ra,0xffffd
    80005b2a:	1b4080e7          	jalr	436(ra) # 80002cda <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b2e:	08000613          	li	a2,128
    80005b32:	f7040593          	addi	a1,s0,-144
    80005b36:	4501                	li	a0,0
    80005b38:	ffffd097          	auipc	ra,0xffffd
    80005b3c:	1e2080e7          	jalr	482(ra) # 80002d1a <argstr>
    80005b40:	02054b63          	bltz	a0,80005b76 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b44:	f6841683          	lh	a3,-152(s0)
    80005b48:	f6c41603          	lh	a2,-148(s0)
    80005b4c:	458d                	li	a1,3
    80005b4e:	f7040513          	addi	a0,s0,-144
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	780080e7          	jalr	1920(ra) # 800052d2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b5a:	cd11                	beqz	a0,80005b76 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	06e080e7          	jalr	110(ra) # 80003bca <iunlockput>
  end_op();
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	846080e7          	jalr	-1978(ra) # 800043aa <end_op>
  return 0;
    80005b6c:	4501                	li	a0,0
}
    80005b6e:	60ea                	ld	ra,152(sp)
    80005b70:	644a                	ld	s0,144(sp)
    80005b72:	610d                	addi	sp,sp,160
    80005b74:	8082                	ret
    end_op();
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	834080e7          	jalr	-1996(ra) # 800043aa <end_op>
    return -1;
    80005b7e:	557d                	li	a0,-1
    80005b80:	b7fd                	j	80005b6e <sys_mknod+0x6c>

0000000080005b82 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b82:	7135                	addi	sp,sp,-160
    80005b84:	ed06                	sd	ra,152(sp)
    80005b86:	e922                	sd	s0,144(sp)
    80005b88:	e526                	sd	s1,136(sp)
    80005b8a:	e14a                	sd	s2,128(sp)
    80005b8c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b8e:	ffffc097          	auipc	ra,0xffffc
    80005b92:	e54080e7          	jalr	-428(ra) # 800019e2 <myproc>
    80005b96:	892a                	mv	s2,a0
  
  begin_op();
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	792080e7          	jalr	1938(ra) # 8000432a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ba0:	08000613          	li	a2,128
    80005ba4:	f6040593          	addi	a1,s0,-160
    80005ba8:	4501                	li	a0,0
    80005baa:	ffffd097          	auipc	ra,0xffffd
    80005bae:	170080e7          	jalr	368(ra) # 80002d1a <argstr>
    80005bb2:	04054b63          	bltz	a0,80005c08 <sys_chdir+0x86>
    80005bb6:	f6040513          	addi	a0,s0,-160
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	554080e7          	jalr	1364(ra) # 8000410e <namei>
    80005bc2:	84aa                	mv	s1,a0
    80005bc4:	c131                	beqz	a0,80005c08 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bc6:	ffffe097          	auipc	ra,0xffffe
    80005bca:	da2080e7          	jalr	-606(ra) # 80003968 <ilock>
  if(ip->type != T_DIR){
    80005bce:	04449703          	lh	a4,68(s1)
    80005bd2:	4785                	li	a5,1
    80005bd4:	04f71063          	bne	a4,a5,80005c14 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bd8:	8526                	mv	a0,s1
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	e50080e7          	jalr	-432(ra) # 80003a2a <iunlock>
  iput(p->cwd);
    80005be2:	15093503          	ld	a0,336(s2)
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	f3c080e7          	jalr	-196(ra) # 80003b22 <iput>
  end_op();
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	7bc080e7          	jalr	1980(ra) # 800043aa <end_op>
  p->cwd = ip;
    80005bf6:	14993823          	sd	s1,336(s2)
  return 0;
    80005bfa:	4501                	li	a0,0
}
    80005bfc:	60ea                	ld	ra,152(sp)
    80005bfe:	644a                	ld	s0,144(sp)
    80005c00:	64aa                	ld	s1,136(sp)
    80005c02:	690a                	ld	s2,128(sp)
    80005c04:	610d                	addi	sp,sp,160
    80005c06:	8082                	ret
    end_op();
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	7a2080e7          	jalr	1954(ra) # 800043aa <end_op>
    return -1;
    80005c10:	557d                	li	a0,-1
    80005c12:	b7ed                	j	80005bfc <sys_chdir+0x7a>
    iunlockput(ip);
    80005c14:	8526                	mv	a0,s1
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	fb4080e7          	jalr	-76(ra) # 80003bca <iunlockput>
    end_op();
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	78c080e7          	jalr	1932(ra) # 800043aa <end_op>
    return -1;
    80005c26:	557d                	li	a0,-1
    80005c28:	bfd1                	j	80005bfc <sys_chdir+0x7a>

0000000080005c2a <sys_exec>:

uint64
sys_exec(void)
{
    80005c2a:	7145                	addi	sp,sp,-464
    80005c2c:	e786                	sd	ra,456(sp)
    80005c2e:	e3a2                	sd	s0,448(sp)
    80005c30:	ff26                	sd	s1,440(sp)
    80005c32:	fb4a                	sd	s2,432(sp)
    80005c34:	f74e                	sd	s3,424(sp)
    80005c36:	f352                	sd	s4,416(sp)
    80005c38:	ef56                	sd	s5,408(sp)
    80005c3a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c3c:	e3840593          	addi	a1,s0,-456
    80005c40:	4505                	li	a0,1
    80005c42:	ffffd097          	auipc	ra,0xffffd
    80005c46:	0b8080e7          	jalr	184(ra) # 80002cfa <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c4a:	08000613          	li	a2,128
    80005c4e:	f4040593          	addi	a1,s0,-192
    80005c52:	4501                	li	a0,0
    80005c54:	ffffd097          	auipc	ra,0xffffd
    80005c58:	0c6080e7          	jalr	198(ra) # 80002d1a <argstr>
    80005c5c:	87aa                	mv	a5,a0
    return -1;
    80005c5e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c60:	0c07c263          	bltz	a5,80005d24 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c64:	10000613          	li	a2,256
    80005c68:	4581                	li	a1,0
    80005c6a:	e4040513          	addi	a0,s0,-448
    80005c6e:	ffffb097          	auipc	ra,0xffffb
    80005c72:	064080e7          	jalr	100(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c76:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c7a:	89a6                	mv	s3,s1
    80005c7c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c7e:	02000a13          	li	s4,32
    80005c82:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c86:	00391793          	slli	a5,s2,0x3
    80005c8a:	e3040593          	addi	a1,s0,-464
    80005c8e:	e3843503          	ld	a0,-456(s0)
    80005c92:	953e                	add	a0,a0,a5
    80005c94:	ffffd097          	auipc	ra,0xffffd
    80005c98:	fa8080e7          	jalr	-88(ra) # 80002c3c <fetchaddr>
    80005c9c:	02054a63          	bltz	a0,80005cd0 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ca0:	e3043783          	ld	a5,-464(s0)
    80005ca4:	c3b9                	beqz	a5,80005cea <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ca6:	ffffb097          	auipc	ra,0xffffb
    80005caa:	e40080e7          	jalr	-448(ra) # 80000ae6 <kalloc>
    80005cae:	85aa                	mv	a1,a0
    80005cb0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cb4:	cd11                	beqz	a0,80005cd0 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cb6:	6605                	lui	a2,0x1
    80005cb8:	e3043503          	ld	a0,-464(s0)
    80005cbc:	ffffd097          	auipc	ra,0xffffd
    80005cc0:	fd2080e7          	jalr	-46(ra) # 80002c8e <fetchstr>
    80005cc4:	00054663          	bltz	a0,80005cd0 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005cc8:	0905                	addi	s2,s2,1
    80005cca:	09a1                	addi	s3,s3,8
    80005ccc:	fb491be3          	bne	s2,s4,80005c82 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cd0:	10048913          	addi	s2,s1,256
    80005cd4:	6088                	ld	a0,0(s1)
    80005cd6:	c531                	beqz	a0,80005d22 <sys_exec+0xf8>
    kfree(argv[i]);
    80005cd8:	ffffb097          	auipc	ra,0xffffb
    80005cdc:	d12080e7          	jalr	-750(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ce0:	04a1                	addi	s1,s1,8
    80005ce2:	ff2499e3          	bne	s1,s2,80005cd4 <sys_exec+0xaa>
  return -1;
    80005ce6:	557d                	li	a0,-1
    80005ce8:	a835                	j	80005d24 <sys_exec+0xfa>
      argv[i] = 0;
    80005cea:	0a8e                	slli	s5,s5,0x3
    80005cec:	fc040793          	addi	a5,s0,-64
    80005cf0:	9abe                	add	s5,s5,a5
    80005cf2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cf6:	e4040593          	addi	a1,s0,-448
    80005cfa:	f4040513          	addi	a0,s0,-192
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	172080e7          	jalr	370(ra) # 80004e70 <exec>
    80005d06:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d08:	10048993          	addi	s3,s1,256
    80005d0c:	6088                	ld	a0,0(s1)
    80005d0e:	c901                	beqz	a0,80005d1e <sys_exec+0xf4>
    kfree(argv[i]);
    80005d10:	ffffb097          	auipc	ra,0xffffb
    80005d14:	cda080e7          	jalr	-806(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d18:	04a1                	addi	s1,s1,8
    80005d1a:	ff3499e3          	bne	s1,s3,80005d0c <sys_exec+0xe2>
  return ret;
    80005d1e:	854a                	mv	a0,s2
    80005d20:	a011                	j	80005d24 <sys_exec+0xfa>
  return -1;
    80005d22:	557d                	li	a0,-1
}
    80005d24:	60be                	ld	ra,456(sp)
    80005d26:	641e                	ld	s0,448(sp)
    80005d28:	74fa                	ld	s1,440(sp)
    80005d2a:	795a                	ld	s2,432(sp)
    80005d2c:	79ba                	ld	s3,424(sp)
    80005d2e:	7a1a                	ld	s4,416(sp)
    80005d30:	6afa                	ld	s5,408(sp)
    80005d32:	6179                	addi	sp,sp,464
    80005d34:	8082                	ret

0000000080005d36 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d36:	7139                	addi	sp,sp,-64
    80005d38:	fc06                	sd	ra,56(sp)
    80005d3a:	f822                	sd	s0,48(sp)
    80005d3c:	f426                	sd	s1,40(sp)
    80005d3e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d40:	ffffc097          	auipc	ra,0xffffc
    80005d44:	ca2080e7          	jalr	-862(ra) # 800019e2 <myproc>
    80005d48:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d4a:	fd840593          	addi	a1,s0,-40
    80005d4e:	4501                	li	a0,0
    80005d50:	ffffd097          	auipc	ra,0xffffd
    80005d54:	faa080e7          	jalr	-86(ra) # 80002cfa <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d58:	fc840593          	addi	a1,s0,-56
    80005d5c:	fd040513          	addi	a0,s0,-48
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	dc6080e7          	jalr	-570(ra) # 80004b26 <pipealloc>
    return -1;
    80005d68:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d6a:	0c054463          	bltz	a0,80005e32 <sys_pipe+0xfc>
  fd0 = -1;
    80005d6e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d72:	fd043503          	ld	a0,-48(s0)
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	51a080e7          	jalr	1306(ra) # 80005290 <fdalloc>
    80005d7e:	fca42223          	sw	a0,-60(s0)
    80005d82:	08054b63          	bltz	a0,80005e18 <sys_pipe+0xe2>
    80005d86:	fc843503          	ld	a0,-56(s0)
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	506080e7          	jalr	1286(ra) # 80005290 <fdalloc>
    80005d92:	fca42023          	sw	a0,-64(s0)
    80005d96:	06054863          	bltz	a0,80005e06 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d9a:	4691                	li	a3,4
    80005d9c:	fc440613          	addi	a2,s0,-60
    80005da0:	fd843583          	ld	a1,-40(s0)
    80005da4:	68a8                	ld	a0,80(s1)
    80005da6:	ffffc097          	auipc	ra,0xffffc
    80005daa:	8f8080e7          	jalr	-1800(ra) # 8000169e <copyout>
    80005dae:	02054063          	bltz	a0,80005dce <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005db2:	4691                	li	a3,4
    80005db4:	fc040613          	addi	a2,s0,-64
    80005db8:	fd843583          	ld	a1,-40(s0)
    80005dbc:	0591                	addi	a1,a1,4
    80005dbe:	68a8                	ld	a0,80(s1)
    80005dc0:	ffffc097          	auipc	ra,0xffffc
    80005dc4:	8de080e7          	jalr	-1826(ra) # 8000169e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dc8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dca:	06055463          	bgez	a0,80005e32 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005dce:	fc442783          	lw	a5,-60(s0)
    80005dd2:	07e9                	addi	a5,a5,26
    80005dd4:	078e                	slli	a5,a5,0x3
    80005dd6:	97a6                	add	a5,a5,s1
    80005dd8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ddc:	fc042503          	lw	a0,-64(s0)
    80005de0:	0569                	addi	a0,a0,26
    80005de2:	050e                	slli	a0,a0,0x3
    80005de4:	94aa                	add	s1,s1,a0
    80005de6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dea:	fd043503          	ld	a0,-48(s0)
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	a08080e7          	jalr	-1528(ra) # 800047f6 <fileclose>
    fileclose(wf);
    80005df6:	fc843503          	ld	a0,-56(s0)
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	9fc080e7          	jalr	-1540(ra) # 800047f6 <fileclose>
    return -1;
    80005e02:	57fd                	li	a5,-1
    80005e04:	a03d                	j	80005e32 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e06:	fc442783          	lw	a5,-60(s0)
    80005e0a:	0007c763          	bltz	a5,80005e18 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e0e:	07e9                	addi	a5,a5,26
    80005e10:	078e                	slli	a5,a5,0x3
    80005e12:	94be                	add	s1,s1,a5
    80005e14:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e18:	fd043503          	ld	a0,-48(s0)
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	9da080e7          	jalr	-1574(ra) # 800047f6 <fileclose>
    fileclose(wf);
    80005e24:	fc843503          	ld	a0,-56(s0)
    80005e28:	fffff097          	auipc	ra,0xfffff
    80005e2c:	9ce080e7          	jalr	-1586(ra) # 800047f6 <fileclose>
    return -1;
    80005e30:	57fd                	li	a5,-1
}
    80005e32:	853e                	mv	a0,a5
    80005e34:	70e2                	ld	ra,56(sp)
    80005e36:	7442                	ld	s0,48(sp)
    80005e38:	74a2                	ld	s1,40(sp)
    80005e3a:	6121                	addi	sp,sp,64
    80005e3c:	8082                	ret
	...

0000000080005e40 <kernelvec>:
    80005e40:	7111                	addi	sp,sp,-256
    80005e42:	e006                	sd	ra,0(sp)
    80005e44:	e40a                	sd	sp,8(sp)
    80005e46:	e80e                	sd	gp,16(sp)
    80005e48:	ec12                	sd	tp,24(sp)
    80005e4a:	f016                	sd	t0,32(sp)
    80005e4c:	f41a                	sd	t1,40(sp)
    80005e4e:	f81e                	sd	t2,48(sp)
    80005e50:	fc22                	sd	s0,56(sp)
    80005e52:	e0a6                	sd	s1,64(sp)
    80005e54:	e4aa                	sd	a0,72(sp)
    80005e56:	e8ae                	sd	a1,80(sp)
    80005e58:	ecb2                	sd	a2,88(sp)
    80005e5a:	f0b6                	sd	a3,96(sp)
    80005e5c:	f4ba                	sd	a4,104(sp)
    80005e5e:	f8be                	sd	a5,112(sp)
    80005e60:	fcc2                	sd	a6,120(sp)
    80005e62:	e146                	sd	a7,128(sp)
    80005e64:	e54a                	sd	s2,136(sp)
    80005e66:	e94e                	sd	s3,144(sp)
    80005e68:	ed52                	sd	s4,152(sp)
    80005e6a:	f156                	sd	s5,160(sp)
    80005e6c:	f55a                	sd	s6,168(sp)
    80005e6e:	f95e                	sd	s7,176(sp)
    80005e70:	fd62                	sd	s8,184(sp)
    80005e72:	e1e6                	sd	s9,192(sp)
    80005e74:	e5ea                	sd	s10,200(sp)
    80005e76:	e9ee                	sd	s11,208(sp)
    80005e78:	edf2                	sd	t3,216(sp)
    80005e7a:	f1f6                	sd	t4,224(sp)
    80005e7c:	f5fa                	sd	t5,232(sp)
    80005e7e:	f9fe                	sd	t6,240(sp)
    80005e80:	c89fc0ef          	jal	ra,80002b08 <kerneltrap>
    80005e84:	6082                	ld	ra,0(sp)
    80005e86:	6122                	ld	sp,8(sp)
    80005e88:	61c2                	ld	gp,16(sp)
    80005e8a:	7282                	ld	t0,32(sp)
    80005e8c:	7322                	ld	t1,40(sp)
    80005e8e:	73c2                	ld	t2,48(sp)
    80005e90:	7462                	ld	s0,56(sp)
    80005e92:	6486                	ld	s1,64(sp)
    80005e94:	6526                	ld	a0,72(sp)
    80005e96:	65c6                	ld	a1,80(sp)
    80005e98:	6666                	ld	a2,88(sp)
    80005e9a:	7686                	ld	a3,96(sp)
    80005e9c:	7726                	ld	a4,104(sp)
    80005e9e:	77c6                	ld	a5,112(sp)
    80005ea0:	7866                	ld	a6,120(sp)
    80005ea2:	688a                	ld	a7,128(sp)
    80005ea4:	692a                	ld	s2,136(sp)
    80005ea6:	69ca                	ld	s3,144(sp)
    80005ea8:	6a6a                	ld	s4,152(sp)
    80005eaa:	7a8a                	ld	s5,160(sp)
    80005eac:	7b2a                	ld	s6,168(sp)
    80005eae:	7bca                	ld	s7,176(sp)
    80005eb0:	7c6a                	ld	s8,184(sp)
    80005eb2:	6c8e                	ld	s9,192(sp)
    80005eb4:	6d2e                	ld	s10,200(sp)
    80005eb6:	6dce                	ld	s11,208(sp)
    80005eb8:	6e6e                	ld	t3,216(sp)
    80005eba:	7e8e                	ld	t4,224(sp)
    80005ebc:	7f2e                	ld	t5,232(sp)
    80005ebe:	7fce                	ld	t6,240(sp)
    80005ec0:	6111                	addi	sp,sp,256
    80005ec2:	10200073          	sret
    80005ec6:	00000013          	nop
    80005eca:	00000013          	nop
    80005ece:	0001                	nop

0000000080005ed0 <timervec>:
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	e10c                	sd	a1,0(a0)
    80005ed6:	e510                	sd	a2,8(a0)
    80005ed8:	e914                	sd	a3,16(a0)
    80005eda:	6d0c                	ld	a1,24(a0)
    80005edc:	7110                	ld	a2,32(a0)
    80005ede:	6194                	ld	a3,0(a1)
    80005ee0:	96b2                	add	a3,a3,a2
    80005ee2:	e194                	sd	a3,0(a1)
    80005ee4:	4589                	li	a1,2
    80005ee6:	14459073          	csrw	sip,a1
    80005eea:	6914                	ld	a3,16(a0)
    80005eec:	6510                	ld	a2,8(a0)
    80005eee:	610c                	ld	a1,0(a0)
    80005ef0:	34051573          	csrrw	a0,mscratch,a0
    80005ef4:	30200073          	mret
	...

0000000080005efa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005efa:	1141                	addi	sp,sp,-16
    80005efc:	e422                	sd	s0,8(sp)
    80005efe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f00:	0c0007b7          	lui	a5,0xc000
    80005f04:	4705                	li	a4,1
    80005f06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f08:	c3d8                	sw	a4,4(a5)
}
    80005f0a:	6422                	ld	s0,8(sp)
    80005f0c:	0141                	addi	sp,sp,16
    80005f0e:	8082                	ret

0000000080005f10 <plicinithart>:

void
plicinithart(void)
{
    80005f10:	1141                	addi	sp,sp,-16
    80005f12:	e406                	sd	ra,8(sp)
    80005f14:	e022                	sd	s0,0(sp)
    80005f16:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f18:	ffffc097          	auipc	ra,0xffffc
    80005f1c:	a9e080e7          	jalr	-1378(ra) # 800019b6 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f20:	0085171b          	slliw	a4,a0,0x8
    80005f24:	0c0027b7          	lui	a5,0xc002
    80005f28:	97ba                	add	a5,a5,a4
    80005f2a:	40200713          	li	a4,1026
    80005f2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f32:	00d5151b          	slliw	a0,a0,0xd
    80005f36:	0c2017b7          	lui	a5,0xc201
    80005f3a:	953e                	add	a0,a0,a5
    80005f3c:	00052023          	sw	zero,0(a0)
}
    80005f40:	60a2                	ld	ra,8(sp)
    80005f42:	6402                	ld	s0,0(sp)
    80005f44:	0141                	addi	sp,sp,16
    80005f46:	8082                	ret

0000000080005f48 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f48:	1141                	addi	sp,sp,-16
    80005f4a:	e406                	sd	ra,8(sp)
    80005f4c:	e022                	sd	s0,0(sp)
    80005f4e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f50:	ffffc097          	auipc	ra,0xffffc
    80005f54:	a66080e7          	jalr	-1434(ra) # 800019b6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f58:	00d5179b          	slliw	a5,a0,0xd
    80005f5c:	0c201537          	lui	a0,0xc201
    80005f60:	953e                	add	a0,a0,a5
  return irq;
}
    80005f62:	4148                	lw	a0,4(a0)
    80005f64:	60a2                	ld	ra,8(sp)
    80005f66:	6402                	ld	s0,0(sp)
    80005f68:	0141                	addi	sp,sp,16
    80005f6a:	8082                	ret

0000000080005f6c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f6c:	1101                	addi	sp,sp,-32
    80005f6e:	ec06                	sd	ra,24(sp)
    80005f70:	e822                	sd	s0,16(sp)
    80005f72:	e426                	sd	s1,8(sp)
    80005f74:	1000                	addi	s0,sp,32
    80005f76:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f78:	ffffc097          	auipc	ra,0xffffc
    80005f7c:	a3e080e7          	jalr	-1474(ra) # 800019b6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f80:	00d5151b          	slliw	a0,a0,0xd
    80005f84:	0c2017b7          	lui	a5,0xc201
    80005f88:	97aa                	add	a5,a5,a0
    80005f8a:	c3c4                	sw	s1,4(a5)
}
    80005f8c:	60e2                	ld	ra,24(sp)
    80005f8e:	6442                	ld	s0,16(sp)
    80005f90:	64a2                	ld	s1,8(sp)
    80005f92:	6105                	addi	sp,sp,32
    80005f94:	8082                	ret

0000000080005f96 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f96:	1141                	addi	sp,sp,-16
    80005f98:	e406                	sd	ra,8(sp)
    80005f9a:	e022                	sd	s0,0(sp)
    80005f9c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f9e:	479d                	li	a5,7
    80005fa0:	04a7cc63          	blt	a5,a0,80005ff8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005fa4:	0001d797          	auipc	a5,0x1d
    80005fa8:	9ec78793          	addi	a5,a5,-1556 # 80022990 <disk>
    80005fac:	97aa                	add	a5,a5,a0
    80005fae:	0187c783          	lbu	a5,24(a5)
    80005fb2:	ebb9                	bnez	a5,80006008 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005fb4:	00451613          	slli	a2,a0,0x4
    80005fb8:	0001d797          	auipc	a5,0x1d
    80005fbc:	9d878793          	addi	a5,a5,-1576 # 80022990 <disk>
    80005fc0:	6394                	ld	a3,0(a5)
    80005fc2:	96b2                	add	a3,a3,a2
    80005fc4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fc8:	6398                	ld	a4,0(a5)
    80005fca:	9732                	add	a4,a4,a2
    80005fcc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005fd0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005fd4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005fd8:	953e                	add	a0,a0,a5
    80005fda:	4785                	li	a5,1
    80005fdc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005fe0:	0001d517          	auipc	a0,0x1d
    80005fe4:	9c850513          	addi	a0,a0,-1592 # 800229a8 <disk+0x18>
    80005fe8:	ffffc097          	auipc	ra,0xffffc
    80005fec:	19e080e7          	jalr	414(ra) # 80002186 <wakeup>
}
    80005ff0:	60a2                	ld	ra,8(sp)
    80005ff2:	6402                	ld	s0,0(sp)
    80005ff4:	0141                	addi	sp,sp,16
    80005ff6:	8082                	ret
    panic("free_desc 1");
    80005ff8:	00003517          	auipc	a0,0x3
    80005ffc:	95050513          	addi	a0,a0,-1712 # 80008948 <syscalls+0x428>
    80006000:	ffffa097          	auipc	ra,0xffffa
    80006004:	53e080e7          	jalr	1342(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006008:	00003517          	auipc	a0,0x3
    8000600c:	95050513          	addi	a0,a0,-1712 # 80008958 <syscalls+0x438>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	52e080e7          	jalr	1326(ra) # 8000053e <panic>

0000000080006018 <virtio_disk_init>:
{
    80006018:	1101                	addi	sp,sp,-32
    8000601a:	ec06                	sd	ra,24(sp)
    8000601c:	e822                	sd	s0,16(sp)
    8000601e:	e426                	sd	s1,8(sp)
    80006020:	e04a                	sd	s2,0(sp)
    80006022:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006024:	00003597          	auipc	a1,0x3
    80006028:	94458593          	addi	a1,a1,-1724 # 80008968 <syscalls+0x448>
    8000602c:	0001d517          	auipc	a0,0x1d
    80006030:	a8c50513          	addi	a0,a0,-1396 # 80022ab8 <disk+0x128>
    80006034:	ffffb097          	auipc	ra,0xffffb
    80006038:	b12080e7          	jalr	-1262(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000603c:	100017b7          	lui	a5,0x10001
    80006040:	4398                	lw	a4,0(a5)
    80006042:	2701                	sext.w	a4,a4
    80006044:	747277b7          	lui	a5,0x74727
    80006048:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000604c:	14f71c63          	bne	a4,a5,800061a4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006050:	100017b7          	lui	a5,0x10001
    80006054:	43dc                	lw	a5,4(a5)
    80006056:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006058:	4709                	li	a4,2
    8000605a:	14e79563          	bne	a5,a4,800061a4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	479c                	lw	a5,8(a5)
    80006064:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006066:	12e79f63          	bne	a5,a4,800061a4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000606a:	100017b7          	lui	a5,0x10001
    8000606e:	47d8                	lw	a4,12(a5)
    80006070:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006072:	554d47b7          	lui	a5,0x554d4
    80006076:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000607a:	12f71563          	bne	a4,a5,800061a4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607e:	100017b7          	lui	a5,0x10001
    80006082:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006086:	4705                	li	a4,1
    80006088:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000608a:	470d                	li	a4,3
    8000608c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000608e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006090:	c7ffe737          	lui	a4,0xc7ffe
    80006094:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd7997>
    80006098:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000609a:	2701                	sext.w	a4,a4
    8000609c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000609e:	472d                	li	a4,11
    800060a0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800060a2:	5bbc                	lw	a5,112(a5)
    800060a4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800060a8:	8ba1                	andi	a5,a5,8
    800060aa:	10078563          	beqz	a5,800061b4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060ae:	100017b7          	lui	a5,0x10001
    800060b2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800060b6:	43fc                	lw	a5,68(a5)
    800060b8:	2781                	sext.w	a5,a5
    800060ba:	10079563          	bnez	a5,800061c4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060be:	100017b7          	lui	a5,0x10001
    800060c2:	5bdc                	lw	a5,52(a5)
    800060c4:	2781                	sext.w	a5,a5
  if(max == 0)
    800060c6:	10078763          	beqz	a5,800061d4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800060ca:	471d                	li	a4,7
    800060cc:	10f77c63          	bgeu	a4,a5,800061e4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	a16080e7          	jalr	-1514(ra) # 80000ae6 <kalloc>
    800060d8:	0001d497          	auipc	s1,0x1d
    800060dc:	8b848493          	addi	s1,s1,-1864 # 80022990 <disk>
    800060e0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800060e2:	ffffb097          	auipc	ra,0xffffb
    800060e6:	a04080e7          	jalr	-1532(ra) # 80000ae6 <kalloc>
    800060ea:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800060ec:	ffffb097          	auipc	ra,0xffffb
    800060f0:	9fa080e7          	jalr	-1542(ra) # 80000ae6 <kalloc>
    800060f4:	87aa                	mv	a5,a0
    800060f6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060f8:	6088                	ld	a0,0(s1)
    800060fa:	cd6d                	beqz	a0,800061f4 <virtio_disk_init+0x1dc>
    800060fc:	0001d717          	auipc	a4,0x1d
    80006100:	89c73703          	ld	a4,-1892(a4) # 80022998 <disk+0x8>
    80006104:	cb65                	beqz	a4,800061f4 <virtio_disk_init+0x1dc>
    80006106:	c7fd                	beqz	a5,800061f4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006108:	6605                	lui	a2,0x1
    8000610a:	4581                	li	a1,0
    8000610c:	ffffb097          	auipc	ra,0xffffb
    80006110:	bc6080e7          	jalr	-1082(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006114:	0001d497          	auipc	s1,0x1d
    80006118:	87c48493          	addi	s1,s1,-1924 # 80022990 <disk>
    8000611c:	6605                	lui	a2,0x1
    8000611e:	4581                	li	a1,0
    80006120:	6488                	ld	a0,8(s1)
    80006122:	ffffb097          	auipc	ra,0xffffb
    80006126:	bb0080e7          	jalr	-1104(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000612a:	6605                	lui	a2,0x1
    8000612c:	4581                	li	a1,0
    8000612e:	6888                	ld	a0,16(s1)
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	ba2080e7          	jalr	-1118(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006138:	100017b7          	lui	a5,0x10001
    8000613c:	4721                	li	a4,8
    8000613e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006140:	4098                	lw	a4,0(s1)
    80006142:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006146:	40d8                	lw	a4,4(s1)
    80006148:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000614c:	6498                	ld	a4,8(s1)
    8000614e:	0007069b          	sext.w	a3,a4
    80006152:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006156:	9701                	srai	a4,a4,0x20
    80006158:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000615c:	6898                	ld	a4,16(s1)
    8000615e:	0007069b          	sext.w	a3,a4
    80006162:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006166:	9701                	srai	a4,a4,0x20
    80006168:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000616c:	4705                	li	a4,1
    8000616e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006170:	00e48c23          	sb	a4,24(s1)
    80006174:	00e48ca3          	sb	a4,25(s1)
    80006178:	00e48d23          	sb	a4,26(s1)
    8000617c:	00e48da3          	sb	a4,27(s1)
    80006180:	00e48e23          	sb	a4,28(s1)
    80006184:	00e48ea3          	sb	a4,29(s1)
    80006188:	00e48f23          	sb	a4,30(s1)
    8000618c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006190:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006194:	0727a823          	sw	s2,112(a5)
}
    80006198:	60e2                	ld	ra,24(sp)
    8000619a:	6442                	ld	s0,16(sp)
    8000619c:	64a2                	ld	s1,8(sp)
    8000619e:	6902                	ld	s2,0(sp)
    800061a0:	6105                	addi	sp,sp,32
    800061a2:	8082                	ret
    panic("could not find virtio disk");
    800061a4:	00002517          	auipc	a0,0x2
    800061a8:	7d450513          	addi	a0,a0,2004 # 80008978 <syscalls+0x458>
    800061ac:	ffffa097          	auipc	ra,0xffffa
    800061b0:	392080e7          	jalr	914(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    800061b4:	00002517          	auipc	a0,0x2
    800061b8:	7e450513          	addi	a0,a0,2020 # 80008998 <syscalls+0x478>
    800061bc:	ffffa097          	auipc	ra,0xffffa
    800061c0:	382080e7          	jalr	898(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    800061c4:	00002517          	auipc	a0,0x2
    800061c8:	7f450513          	addi	a0,a0,2036 # 800089b8 <syscalls+0x498>
    800061cc:	ffffa097          	auipc	ra,0xffffa
    800061d0:	372080e7          	jalr	882(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800061d4:	00003517          	auipc	a0,0x3
    800061d8:	80450513          	addi	a0,a0,-2044 # 800089d8 <syscalls+0x4b8>
    800061dc:	ffffa097          	auipc	ra,0xffffa
    800061e0:	362080e7          	jalr	866(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800061e4:	00003517          	auipc	a0,0x3
    800061e8:	81450513          	addi	a0,a0,-2028 # 800089f8 <syscalls+0x4d8>
    800061ec:	ffffa097          	auipc	ra,0xffffa
    800061f0:	352080e7          	jalr	850(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800061f4:	00003517          	auipc	a0,0x3
    800061f8:	82450513          	addi	a0,a0,-2012 # 80008a18 <syscalls+0x4f8>
    800061fc:	ffffa097          	auipc	ra,0xffffa
    80006200:	342080e7          	jalr	834(ra) # 8000053e <panic>

0000000080006204 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006204:	7119                	addi	sp,sp,-128
    80006206:	fc86                	sd	ra,120(sp)
    80006208:	f8a2                	sd	s0,112(sp)
    8000620a:	f4a6                	sd	s1,104(sp)
    8000620c:	f0ca                	sd	s2,96(sp)
    8000620e:	ecce                	sd	s3,88(sp)
    80006210:	e8d2                	sd	s4,80(sp)
    80006212:	e4d6                	sd	s5,72(sp)
    80006214:	e0da                	sd	s6,64(sp)
    80006216:	fc5e                	sd	s7,56(sp)
    80006218:	f862                	sd	s8,48(sp)
    8000621a:	f466                	sd	s9,40(sp)
    8000621c:	f06a                	sd	s10,32(sp)
    8000621e:	ec6e                	sd	s11,24(sp)
    80006220:	0100                	addi	s0,sp,128
    80006222:	8aaa                	mv	s5,a0
    80006224:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006226:	00c52d03          	lw	s10,12(a0)
    8000622a:	001d1d1b          	slliw	s10,s10,0x1
    8000622e:	1d02                	slli	s10,s10,0x20
    80006230:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006234:	0001d517          	auipc	a0,0x1d
    80006238:	88450513          	addi	a0,a0,-1916 # 80022ab8 <disk+0x128>
    8000623c:	ffffb097          	auipc	ra,0xffffb
    80006240:	99a080e7          	jalr	-1638(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006244:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006246:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006248:	0001cb97          	auipc	s7,0x1c
    8000624c:	748b8b93          	addi	s7,s7,1864 # 80022990 <disk>
  for(int i = 0; i < 3; i++){
    80006250:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006252:	0001dc97          	auipc	s9,0x1d
    80006256:	866c8c93          	addi	s9,s9,-1946 # 80022ab8 <disk+0x128>
    8000625a:	a08d                	j	800062bc <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000625c:	00fb8733          	add	a4,s7,a5
    80006260:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006264:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006266:	0207c563          	bltz	a5,80006290 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000626a:	2905                	addiw	s2,s2,1
    8000626c:	0611                	addi	a2,a2,4
    8000626e:	05690c63          	beq	s2,s6,800062c6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006272:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006274:	0001c717          	auipc	a4,0x1c
    80006278:	71c70713          	addi	a4,a4,1820 # 80022990 <disk>
    8000627c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000627e:	01874683          	lbu	a3,24(a4)
    80006282:	fee9                	bnez	a3,8000625c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006284:	2785                	addiw	a5,a5,1
    80006286:	0705                	addi	a4,a4,1
    80006288:	fe979be3          	bne	a5,s1,8000627e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000628c:	57fd                	li	a5,-1
    8000628e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006290:	01205d63          	blez	s2,800062aa <virtio_disk_rw+0xa6>
    80006294:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006296:	000a2503          	lw	a0,0(s4)
    8000629a:	00000097          	auipc	ra,0x0
    8000629e:	cfc080e7          	jalr	-772(ra) # 80005f96 <free_desc>
      for(int j = 0; j < i; j++)
    800062a2:	2d85                	addiw	s11,s11,1
    800062a4:	0a11                	addi	s4,s4,4
    800062a6:	ffb918e3          	bne	s2,s11,80006296 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062aa:	85e6                	mv	a1,s9
    800062ac:	0001c517          	auipc	a0,0x1c
    800062b0:	6fc50513          	addi	a0,a0,1788 # 800229a8 <disk+0x18>
    800062b4:	ffffc097          	auipc	ra,0xffffc
    800062b8:	e6e080e7          	jalr	-402(ra) # 80002122 <sleep>
  for(int i = 0; i < 3; i++){
    800062bc:	f8040a13          	addi	s4,s0,-128
{
    800062c0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800062c2:	894e                	mv	s2,s3
    800062c4:	b77d                	j	80006272 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062c6:	f8042583          	lw	a1,-128(s0)
    800062ca:	00a58793          	addi	a5,a1,10
    800062ce:	0792                	slli	a5,a5,0x4

  if(write)
    800062d0:	0001c617          	auipc	a2,0x1c
    800062d4:	6c060613          	addi	a2,a2,1728 # 80022990 <disk>
    800062d8:	00f60733          	add	a4,a2,a5
    800062dc:	018036b3          	snez	a3,s8
    800062e0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062e2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800062e6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062ea:	f6078693          	addi	a3,a5,-160
    800062ee:	6218                	ld	a4,0(a2)
    800062f0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062f2:	00878513          	addi	a0,a5,8
    800062f6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062f8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062fa:	6208                	ld	a0,0(a2)
    800062fc:	96aa                	add	a3,a3,a0
    800062fe:	4741                	li	a4,16
    80006300:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006302:	4705                	li	a4,1
    80006304:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006308:	f8442703          	lw	a4,-124(s0)
    8000630c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006310:	0712                	slli	a4,a4,0x4
    80006312:	953a                	add	a0,a0,a4
    80006314:	058a8693          	addi	a3,s5,88
    80006318:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000631a:	6208                	ld	a0,0(a2)
    8000631c:	972a                	add	a4,a4,a0
    8000631e:	40000693          	li	a3,1024
    80006322:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006324:	001c3c13          	seqz	s8,s8
    80006328:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000632a:	001c6c13          	ori	s8,s8,1
    8000632e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006332:	f8842603          	lw	a2,-120(s0)
    80006336:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000633a:	0001c697          	auipc	a3,0x1c
    8000633e:	65668693          	addi	a3,a3,1622 # 80022990 <disk>
    80006342:	00258713          	addi	a4,a1,2
    80006346:	0712                	slli	a4,a4,0x4
    80006348:	9736                	add	a4,a4,a3
    8000634a:	587d                	li	a6,-1
    8000634c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006350:	0612                	slli	a2,a2,0x4
    80006352:	9532                	add	a0,a0,a2
    80006354:	f9078793          	addi	a5,a5,-112
    80006358:	97b6                	add	a5,a5,a3
    8000635a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000635c:	629c                	ld	a5,0(a3)
    8000635e:	97b2                	add	a5,a5,a2
    80006360:	4605                	li	a2,1
    80006362:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006364:	4509                	li	a0,2
    80006366:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000636a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000636e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006372:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006376:	6698                	ld	a4,8(a3)
    80006378:	00275783          	lhu	a5,2(a4)
    8000637c:	8b9d                	andi	a5,a5,7
    8000637e:	0786                	slli	a5,a5,0x1
    80006380:	97ba                	add	a5,a5,a4
    80006382:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006386:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000638a:	6698                	ld	a4,8(a3)
    8000638c:	00275783          	lhu	a5,2(a4)
    80006390:	2785                	addiw	a5,a5,1
    80006392:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006396:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000639a:	100017b7          	lui	a5,0x10001
    8000639e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063a2:	004aa783          	lw	a5,4(s5)
    800063a6:	02c79163          	bne	a5,a2,800063c8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800063aa:	0001c917          	auipc	s2,0x1c
    800063ae:	70e90913          	addi	s2,s2,1806 # 80022ab8 <disk+0x128>
  while(b->disk == 1) {
    800063b2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063b4:	85ca                	mv	a1,s2
    800063b6:	8556                	mv	a0,s5
    800063b8:	ffffc097          	auipc	ra,0xffffc
    800063bc:	d6a080e7          	jalr	-662(ra) # 80002122 <sleep>
  while(b->disk == 1) {
    800063c0:	004aa783          	lw	a5,4(s5)
    800063c4:	fe9788e3          	beq	a5,s1,800063b4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800063c8:	f8042903          	lw	s2,-128(s0)
    800063cc:	00290793          	addi	a5,s2,2
    800063d0:	00479713          	slli	a4,a5,0x4
    800063d4:	0001c797          	auipc	a5,0x1c
    800063d8:	5bc78793          	addi	a5,a5,1468 # 80022990 <disk>
    800063dc:	97ba                	add	a5,a5,a4
    800063de:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800063e2:	0001c997          	auipc	s3,0x1c
    800063e6:	5ae98993          	addi	s3,s3,1454 # 80022990 <disk>
    800063ea:	00491713          	slli	a4,s2,0x4
    800063ee:	0009b783          	ld	a5,0(s3)
    800063f2:	97ba                	add	a5,a5,a4
    800063f4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063f8:	854a                	mv	a0,s2
    800063fa:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063fe:	00000097          	auipc	ra,0x0
    80006402:	b98080e7          	jalr	-1128(ra) # 80005f96 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006406:	8885                	andi	s1,s1,1
    80006408:	f0ed                	bnez	s1,800063ea <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000640a:	0001c517          	auipc	a0,0x1c
    8000640e:	6ae50513          	addi	a0,a0,1710 # 80022ab8 <disk+0x128>
    80006412:	ffffb097          	auipc	ra,0xffffb
    80006416:	878080e7          	jalr	-1928(ra) # 80000c8a <release>
}
    8000641a:	70e6                	ld	ra,120(sp)
    8000641c:	7446                	ld	s0,112(sp)
    8000641e:	74a6                	ld	s1,104(sp)
    80006420:	7906                	ld	s2,96(sp)
    80006422:	69e6                	ld	s3,88(sp)
    80006424:	6a46                	ld	s4,80(sp)
    80006426:	6aa6                	ld	s5,72(sp)
    80006428:	6b06                	ld	s6,64(sp)
    8000642a:	7be2                	ld	s7,56(sp)
    8000642c:	7c42                	ld	s8,48(sp)
    8000642e:	7ca2                	ld	s9,40(sp)
    80006430:	7d02                	ld	s10,32(sp)
    80006432:	6de2                	ld	s11,24(sp)
    80006434:	6109                	addi	sp,sp,128
    80006436:	8082                	ret

0000000080006438 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006438:	1101                	addi	sp,sp,-32
    8000643a:	ec06                	sd	ra,24(sp)
    8000643c:	e822                	sd	s0,16(sp)
    8000643e:	e426                	sd	s1,8(sp)
    80006440:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006442:	0001c497          	auipc	s1,0x1c
    80006446:	54e48493          	addi	s1,s1,1358 # 80022990 <disk>
    8000644a:	0001c517          	auipc	a0,0x1c
    8000644e:	66e50513          	addi	a0,a0,1646 # 80022ab8 <disk+0x128>
    80006452:	ffffa097          	auipc	ra,0xffffa
    80006456:	784080e7          	jalr	1924(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000645a:	10001737          	lui	a4,0x10001
    8000645e:	533c                	lw	a5,96(a4)
    80006460:	8b8d                	andi	a5,a5,3
    80006462:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006464:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006468:	689c                	ld	a5,16(s1)
    8000646a:	0204d703          	lhu	a4,32(s1)
    8000646e:	0027d783          	lhu	a5,2(a5)
    80006472:	04f70863          	beq	a4,a5,800064c2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006476:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000647a:	6898                	ld	a4,16(s1)
    8000647c:	0204d783          	lhu	a5,32(s1)
    80006480:	8b9d                	andi	a5,a5,7
    80006482:	078e                	slli	a5,a5,0x3
    80006484:	97ba                	add	a5,a5,a4
    80006486:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006488:	00278713          	addi	a4,a5,2
    8000648c:	0712                	slli	a4,a4,0x4
    8000648e:	9726                	add	a4,a4,s1
    80006490:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006494:	e721                	bnez	a4,800064dc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006496:	0789                	addi	a5,a5,2
    80006498:	0792                	slli	a5,a5,0x4
    8000649a:	97a6                	add	a5,a5,s1
    8000649c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000649e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064a2:	ffffc097          	auipc	ra,0xffffc
    800064a6:	ce4080e7          	jalr	-796(ra) # 80002186 <wakeup>

    disk.used_idx += 1;
    800064aa:	0204d783          	lhu	a5,32(s1)
    800064ae:	2785                	addiw	a5,a5,1
    800064b0:	17c2                	slli	a5,a5,0x30
    800064b2:	93c1                	srli	a5,a5,0x30
    800064b4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064b8:	6898                	ld	a4,16(s1)
    800064ba:	00275703          	lhu	a4,2(a4)
    800064be:	faf71ce3          	bne	a4,a5,80006476 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800064c2:	0001c517          	auipc	a0,0x1c
    800064c6:	5f650513          	addi	a0,a0,1526 # 80022ab8 <disk+0x128>
    800064ca:	ffffa097          	auipc	ra,0xffffa
    800064ce:	7c0080e7          	jalr	1984(ra) # 80000c8a <release>
}
    800064d2:	60e2                	ld	ra,24(sp)
    800064d4:	6442                	ld	s0,16(sp)
    800064d6:	64a2                	ld	s1,8(sp)
    800064d8:	6105                	addi	sp,sp,32
    800064da:	8082                	ret
      panic("virtio_disk_intr status");
    800064dc:	00002517          	auipc	a0,0x2
    800064e0:	55450513          	addi	a0,a0,1364 # 80008a30 <syscalls+0x510>
    800064e4:	ffffa097          	auipc	ra,0xffffa
    800064e8:	05a080e7          	jalr	90(ra) # 8000053e <panic>

00000000800064ec <free_desc>:
    panic("virtio_gpu: no free descriptors");
}

static void
free_desc(int i)
{
    800064ec:	1141                	addi	sp,sp,-16
    800064ee:	e422                	sd	s0,8(sp)
    800064f0:	0800                	addi	s0,sp,16
    gq.desc[i].addr = 0;
    800064f2:	0001c717          	auipc	a4,0x1c
    800064f6:	5de70713          	addi	a4,a4,1502 # 80022ad0 <gq>
    800064fa:	00451693          	slli	a3,a0,0x4
    800064fe:	631c                	ld	a5,0(a4)
    80006500:	97b6                	add	a5,a5,a3
    80006502:	0007b023          	sd	zero,0(a5)
    gq.desc[i].len = 0;
    80006506:	0007a423          	sw	zero,8(a5)
    gq.desc[i].flags = 0;
    8000650a:	00079623          	sh	zero,12(a5)
    gq.desc[i].next = 0;
    8000650e:	00079723          	sh	zero,14(a5)
    gq.free[i] = 1;
    80006512:	972a                	add	a4,a4,a0
    80006514:	4785                	li	a5,1
    80006516:	00f70c23          	sb	a5,24(a4)
}
    8000651a:	6422                	ld	s0,8(sp)
    8000651c:	0141                	addi	sp,sp,16
    8000651e:	8082                	ret

0000000080006520 <alloc_desc>:
    for (int i = 0; i < GPU_NUM; i++)
    80006520:	0001c797          	auipc	a5,0x1c
    80006524:	5b078793          	addi	a5,a5,1456 # 80022ad0 <gq>
    80006528:	4501                	li	a0,0
    8000652a:	46a1                	li	a3,8
        if (gq.free[i])
    8000652c:	0187c703          	lbu	a4,24(a5)
    80006530:	e30d                	bnez	a4,80006552 <alloc_desc+0x32>
    for (int i = 0; i < GPU_NUM; i++)
    80006532:	2505                	addiw	a0,a0,1
    80006534:	0785                	addi	a5,a5,1
    80006536:	fed51be3          	bne	a0,a3,8000652c <alloc_desc+0xc>
{
    8000653a:	1141                	addi	sp,sp,-16
    8000653c:	e406                	sd	ra,8(sp)
    8000653e:	e022                	sd	s0,0(sp)
    80006540:	0800                	addi	s0,sp,16
    panic("virtio_gpu: no free descriptors");
    80006542:	00002517          	auipc	a0,0x2
    80006546:	50650513          	addi	a0,a0,1286 # 80008a48 <syscalls+0x528>
    8000654a:	ffffa097          	auipc	ra,0xffffa
    8000654e:	ff4080e7          	jalr	-12(ra) # 8000053e <panic>
            gq.free[i] = 0;
    80006552:	0001c797          	auipc	a5,0x1c
    80006556:	57e78793          	addi	a5,a5,1406 # 80022ad0 <gq>
    8000655a:	97aa                	add	a5,a5,a0
    8000655c:	00078c23          	sb	zero,24(a5)
}
    80006560:	8082                	ret

0000000080006562 <gpu_send>:

// Submit a 2-descriptor command (request + shared response) and block
// until the device completes it by advancing the used ring.
static void
gpu_send(void *req, int req_len)
{
    80006562:	7139                	addi	sp,sp,-64
    80006564:	fc06                	sd	ra,56(sp)
    80006566:	f822                	sd	s0,48(sp)
    80006568:	f426                	sd	s1,40(sp)
    8000656a:	f04a                	sd	s2,32(sp)
    8000656c:	ec4e                	sd	s3,24(sp)
    8000656e:	e852                	sd	s4,16(sp)
    80006570:	e456                	sd	s5,8(sp)
    80006572:	0080                	addi	s0,sp,64
    80006574:	8aaa                	mv	s5,a0
    80006576:	8a2e                	mv	s4,a1
    acquire(&gpu_lock);
    80006578:	0001c997          	auipc	s3,0x1c
    8000657c:	55898993          	addi	s3,s3,1368 # 80022ad0 <gq>
    80006580:	0001c517          	auipc	a0,0x1c
    80006584:	57850513          	addi	a0,a0,1400 # 80022af8 <gpu_lock>
    80006588:	ffffa097          	auipc	ra,0xffffa
    8000658c:	64e080e7          	jalr	1614(ra) # 80000bd6 <acquire>
    int d0 = alloc_desc();
    80006590:	00000097          	auipc	ra,0x0
    80006594:	f90080e7          	jalr	-112(ra) # 80006520 <alloc_desc>
    80006598:	892a                	mv	s2,a0
    int d1 = alloc_desc();
    8000659a:	00000097          	auipc	ra,0x0
    8000659e:	f86080e7          	jalr	-122(ra) # 80006520 <alloc_desc>
    800065a2:	84aa                	mv	s1,a0

    gq.desc[d0].addr = (uint64)req;
    800065a4:	00491793          	slli	a5,s2,0x4
    800065a8:	0009b703          	ld	a4,0(s3)
    800065ac:	973e                	add	a4,a4,a5
    800065ae:	01573023          	sd	s5,0(a4)
    gq.desc[d0].len = (uint32)req_len;
    800065b2:	0009b703          	ld	a4,0(s3)
    800065b6:	97ba                	add	a5,a5,a4
    800065b8:	0147a423          	sw	s4,8(a5)
    gq.desc[d0].flags = VRING_DESC_F_NEXT;
    800065bc:	4685                	li	a3,1
    800065be:	00d79623          	sh	a3,12(a5)
    gq.desc[d0].next = d1;
    800065c2:	00a79723          	sh	a0,14(a5)

    gq.desc[d1].addr = (uint64)&cmd_resp;
    800065c6:	00451693          	slli	a3,a0,0x4
    800065ca:	9736                	add	a4,a4,a3
    800065cc:	0001c797          	auipc	a5,0x1c
    800065d0:	54478793          	addi	a5,a5,1348 # 80022b10 <cmd_resp>
    800065d4:	e31c                	sd	a5,0(a4)
    gq.desc[d1].len = sizeof(cmd_resp);
    800065d6:	0009b783          	ld	a5,0(s3)
    800065da:	97b6                	add	a5,a5,a3
    800065dc:	4761                	li	a4,24
    800065de:	c798                	sw	a4,8(a5)
    gq.desc[d1].flags = VRING_DESC_F_WRITE;
    800065e0:	4709                	li	a4,2
    800065e2:	00e79623          	sh	a4,12(a5)
    gq.desc[d1].next = 0;
    800065e6:	00079723          	sh	zero,14(a5)

    // Place head descriptor index in the available ring.
    gq.avail->ring[gq.avail->idx % GPU_NUM] = d0;
    800065ea:	0089b703          	ld	a4,8(s3)
    800065ee:	00275783          	lhu	a5,2(a4)
    800065f2:	8b9d                	andi	a5,a5,7
    800065f4:	0786                	slli	a5,a5,0x1
    800065f6:	97ba                	add	a5,a5,a4
    800065f8:	01279223          	sh	s2,4(a5)
    __sync_synchronize();
    800065fc:	0ff0000f          	fence
    gq.avail->idx++;
    80006600:	0089b703          	ld	a4,8(s3)
    80006604:	00275783          	lhu	a5,2(a4)
    80006608:	2785                	addiw	a5,a5,1
    8000660a:	00f71123          	sh	a5,2(a4)
    __sync_synchronize();
    8000660e:	0ff0000f          	fence

    // Notify device (queue index 0 = controlq).
    *R1(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;
    80006612:	100027b7          	lui	a5,0x10002
    80006616:	0407a823          	sw	zero,80(a5) # 10002050 <_entry-0x6fffdfb0>

    // Poll until the device advances the used ring.
    while (1)
    {
        __sync_synchronize();
        if (gq.used->idx != gq.used_idx)
    8000661a:	874e                	mv	a4,s3
        __sync_synchronize();
    8000661c:	0ff0000f          	fence
        if (gq.used->idx != gq.used_idx)
    80006620:	02075783          	lhu	a5,32(a4)
    80006624:	6b14                	ld	a3,16(a4)
    80006626:	0026d683          	lhu	a3,2(a3)
    8000662a:	fef689e3          	beq	a3,a5,8000661c <gpu_send+0xba>
            break;
    }
    gq.used_idx++;
    8000662e:	2785                	addiw	a5,a5,1
    80006630:	0001c717          	auipc	a4,0x1c
    80006634:	4cf71023          	sh	a5,1216(a4) # 80022af0 <gq+0x20>

    free_desc(d0);
    80006638:	854a                	mv	a0,s2
    8000663a:	00000097          	auipc	ra,0x0
    8000663e:	eb2080e7          	jalr	-334(ra) # 800064ec <free_desc>
    free_desc(d1);
    80006642:	8526                	mv	a0,s1
    80006644:	00000097          	auipc	ra,0x0
    80006648:	ea8080e7          	jalr	-344(ra) # 800064ec <free_desc>
    release(&gpu_lock);
    8000664c:	0001c517          	auipc	a0,0x1c
    80006650:	4ac50513          	addi	a0,a0,1196 # 80022af8 <gpu_lock>
    80006654:	ffffa097          	auipc	ra,0xffffa
    80006658:	636080e7          	jalr	1590(ra) # 80000c8a <release>
}
    8000665c:	70e2                	ld	ra,56(sp)
    8000665e:	7442                	ld	s0,48(sp)
    80006660:	74a2                	ld	s1,40(sp)
    80006662:	7902                	ld	s2,32(sp)
    80006664:	69e2                	ld	s3,24(sp)
    80006666:	6a42                	ld	s4,16(sp)
    80006668:	6aa2                	ld	s5,8(sp)
    8000666a:	6121                	addi	sp,sp,64
    8000666c:	8082                	ret

000000008000666e <gpu_cmd_attach>:
{
    8000666e:	1141                	addi	sp,sp,-16
    80006670:	e406                	sd	ra,8(sp)
    80006672:	e022                	sd	s0,0(sp)
    80006674:	0800                	addi	s0,sp,16
    attach_buf.backing.hdr.type = VIRTIO_GPU_CMD_RESOURCE_ATTACH_BACKING;
    80006676:	0001f797          	auipc	a5,0x1f
    8000667a:	b1278793          	addi	a5,a5,-1262 # 80025188 <attach_buf>
    8000667e:	10600713          	li	a4,262
    80006682:	c398                	sw	a4,0(a5)
    attach_buf.backing.resource_id = RESOURCE_ID;
    80006684:	4705                	li	a4,1
    80006686:	cf98                	sw	a4,24(a5)
    attach_buf.backing.nr_entries = n;
    80006688:	0005861b          	sext.w	a2,a1
    8000668c:	cfd0                	sw	a2,28(a5)
    for (int i = 0; i < n; i++)
    8000668e:	02b05663          	blez	a1,800066ba <gpu_cmd_attach+0x4c>
    80006692:	87aa                	mv	a5,a0
    80006694:	0001f717          	auipc	a4,0x1f
    80006698:	b1470713          	addi	a4,a4,-1260 # 800251a8 <attach_buf+0x20>
    8000669c:	fff6069b          	addiw	a3,a2,-1
    800066a0:	1682                	slli	a3,a3,0x20
    800066a2:	9281                	srli	a3,a3,0x20
    800066a4:	0692                	slli	a3,a3,0x4
    800066a6:	0541                	addi	a0,a0,16
    800066a8:	96aa                	add	a3,a3,a0
        attach_buf.entries[i] = entries[i];
    800066aa:	6390                	ld	a2,0(a5)
    800066ac:	e310                	sd	a2,0(a4)
    800066ae:	6790                	ld	a2,8(a5)
    800066b0:	e710                	sd	a2,8(a4)
    for (int i = 0; i < n; i++)
    800066b2:	07c1                	addi	a5,a5,16
    800066b4:	0741                	addi	a4,a4,16
    800066b6:	fed79ae3          	bne	a5,a3,800066aa <gpu_cmd_attach+0x3c>
    gpu_send(&attach_buf, sizeof(attach_buf));
    800066ba:	6585                	lui	a1,0x1
    800066bc:	2e058593          	addi	a1,a1,736 # 12e0 <_entry-0x7fffed20>
    800066c0:	0001f517          	auipc	a0,0x1f
    800066c4:	ac850513          	addi	a0,a0,-1336 # 80025188 <attach_buf>
    800066c8:	00000097          	auipc	ra,0x0
    800066cc:	e9a080e7          	jalr	-358(ra) # 80006562 <gpu_send>
}
    800066d0:	60a2                	ld	ra,8(sp)
    800066d2:	6402                	ld	s0,0(sp)
    800066d4:	0141                	addi	sp,sp,16
    800066d6:	8082                	ret

00000000800066d8 <gpu_transfer_flush>:
{
    800066d8:	7139                	addi	sp,sp,-64
    800066da:	fc06                	sd	ra,56(sp)
    800066dc:	f822                	sd	s0,48(sp)
    800066de:	f426                	sd	s1,40(sp)
    800066e0:	f04a                	sd	s2,32(sp)
    800066e2:	ec4e                	sd	s3,24(sp)
    800066e4:	e852                	sd	s4,16(sp)
    800066e6:	e456                	sd	s5,8(sp)
    800066e8:	0080                	addi	s0,sp,64
    memset(&xfer, 0, sizeof(xfer));
    800066ea:	0001c497          	auipc	s1,0x1c
    800066ee:	3e648493          	addi	s1,s1,998 # 80022ad0 <gq>
    800066f2:	0001c917          	auipc	s2,0x1c
    800066f6:	43690913          	addi	s2,s2,1078 # 80022b28 <xfer.3>
    800066fa:	03800613          	li	a2,56
    800066fe:	4581                	li	a1,0
    80006700:	854a                	mv	a0,s2
    80006702:	ffffa097          	auipc	ra,0xffffa
    80006706:	5d0080e7          	jalr	1488(ra) # 80000cd2 <memset>
    xfer.hdr.type = VIRTIO_GPU_CMD_TRANSFER_TO_HOST_2D;
    8000670a:	10500793          	li	a5,261
    8000670e:	ccbc                	sw	a5,88(s1)
    xfer.r.x = 0;
    80006710:	0604a823          	sw	zero,112(s1)
    xfer.r.y = 0;
    80006714:	0604aa23          	sw	zero,116(s1)
    xfer.r.width = SCREEN_W;
    80006718:	28000a93          	li	s5,640
    8000671c:	0754ac23          	sw	s5,120(s1)
    xfer.r.height = SCREEN_H;
    80006720:	1e000a13          	li	s4,480
    80006724:	0744ae23          	sw	s4,124(s1)
    xfer.resource_id = RESOURCE_ID;
    80006728:	4985                	li	s3,1
    8000672a:	0934a423          	sw	s3,136(s1)
    gpu_send(&xfer, sizeof(xfer));
    8000672e:	03800593          	li	a1,56
    80006732:	854a                	mv	a0,s2
    80006734:	00000097          	auipc	ra,0x0
    80006738:	e2e080e7          	jalr	-466(ra) # 80006562 <gpu_send>
    memset(&flush, 0, sizeof(flush));
    8000673c:	0001c917          	auipc	s2,0x1c
    80006740:	42490913          	addi	s2,s2,1060 # 80022b60 <flush.2>
    80006744:	03000613          	li	a2,48
    80006748:	4581                	li	a1,0
    8000674a:	854a                	mv	a0,s2
    8000674c:	ffffa097          	auipc	ra,0xffffa
    80006750:	586080e7          	jalr	1414(ra) # 80000cd2 <memset>
    flush.hdr.type = VIRTIO_GPU_CMD_RESOURCE_FLUSH;
    80006754:	10400793          	li	a5,260
    80006758:	08f4a823          	sw	a5,144(s1)
    flush.r.x = 0;
    8000675c:	0a04a423          	sw	zero,168(s1)
    flush.r.y = 0;
    80006760:	0a04a623          	sw	zero,172(s1)
    flush.r.width = SCREEN_W;
    80006764:	0b54a823          	sw	s5,176(s1)
    flush.r.height = SCREEN_H;
    80006768:	0b44aa23          	sw	s4,180(s1)
    flush.resource_id = RESOURCE_ID;
    8000676c:	0b34ac23          	sw	s3,184(s1)
    gpu_send(&flush, sizeof(flush));
    80006770:	03000593          	li	a1,48
    80006774:	854a                	mv	a0,s2
    80006776:	00000097          	auipc	ra,0x0
    8000677a:	dec080e7          	jalr	-532(ra) # 80006562 <gpu_send>
}
    8000677e:	70e2                	ld	ra,56(sp)
    80006780:	7442                	ld	s0,48(sp)
    80006782:	74a2                	ld	s1,40(sp)
    80006784:	7902                	ld	s2,32(sp)
    80006786:	69e2                	ld	s3,24(sp)
    80006788:	6a42                	ld	s4,16(sp)
    8000678a:	6aa2                	ld	s5,8(sp)
    8000678c:	6121                	addi	sp,sp,64
    8000678e:	8082                	ret

0000000080006790 <virtio_gpu_init>:

// ── Public init ───────────────────────────────────────────────────────

void virtio_gpu_init(void)
{
    80006790:	7159                	addi	sp,sp,-112
    80006792:	f486                	sd	ra,104(sp)
    80006794:	f0a2                	sd	s0,96(sp)
    80006796:	eca6                	sd	s1,88(sp)
    80006798:	e8ca                	sd	s2,80(sp)
    8000679a:	e4ce                	sd	s3,72(sp)
    8000679c:	e0d2                	sd	s4,64(sp)
    8000679e:	fc56                	sd	s5,56(sp)
    800067a0:	f85a                	sd	s6,48(sp)
    800067a2:	f45e                	sd	s7,40(sp)
    800067a4:	f062                	sd	s8,32(sp)
    800067a6:	ec66                	sd	s9,24(sp)
    800067a8:	e86a                	sd	s10,16(sp)
    800067aa:	e46e                	sd	s11,8(sp)
    800067ac:	1880                	addi	s0,sp,112
    uint32 status = 0;
    initlock(&gpu_lock, "vgpu");
    800067ae:	00002597          	auipc	a1,0x2
    800067b2:	2ba58593          	addi	a1,a1,698 # 80008a68 <syscalls+0x548>
    800067b6:	0001c517          	auipc	a0,0x1c
    800067ba:	34250513          	addi	a0,a0,834 # 80022af8 <gpu_lock>
    800067be:	ffffa097          	auipc	ra,0xffffa
    800067c2:	388080e7          	jalr	904(ra) # 80000b46 <initlock>

    // ── 1. VirtIO device handshake ──────────────────────────────────────
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067c6:	100027b7          	lui	a5,0x10002
    800067ca:	4398                	lw	a4,0(a5)
    800067cc:	2701                	sext.w	a4,a4
    800067ce:	747277b7          	lui	a5,0x74727
    800067d2:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800067d6:	02f71a63          	bne	a4,a5,8000680a <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    800067da:	100027b7          	lui	a5,0x10002
    800067de:	43dc                	lw	a5,4(a5)
    800067e0:	2781                	sext.w	a5,a5
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067e2:	4709                	li	a4,2
    800067e4:	02e79363          	bne	a5,a4,8000680a <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    800067e8:	100027b7          	lui	a5,0x10002
    800067ec:	479c                	lw	a5,8(a5)
    800067ee:	2781                	sext.w	a5,a5
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    800067f0:	4741                	li	a4,16
    800067f2:	00e79c63          	bne	a5,a4,8000680a <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551)
    800067f6:	100027b7          	lui	a5,0x10002
    800067fa:	47d8                	lw	a4,12(a5)
    800067fc:	2701                	sext.w	a4,a4
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    800067fe:	554d47b7          	lui	a5,0x554d4
    80006802:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006806:	02f70963          	beq	a4,a5,80006838 <virtio_gpu_init+0xa8>
    {
        printf("virtio_gpu_init: GPU not found\n");
    8000680a:	00002517          	auipc	a0,0x2
    8000680e:	26650513          	addi	a0,a0,614 # 80008a70 <syscalls+0x550>
    80006812:	ffffa097          	auipc	ra,0xffffa
    80006816:	d76080e7          	jalr	-650(ra) # 80000588 <printf>
    gpu_send(&scanout_req, sizeof(scanout_req));

    // ── 8. TRANSFER_TO_HOST_2D (upload guest memory -> host GPU) ─────────
    gpu_transfer_flush();
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
}
    8000681a:	70a6                	ld	ra,104(sp)
    8000681c:	7406                	ld	s0,96(sp)
    8000681e:	64e6                	ld	s1,88(sp)
    80006820:	6946                	ld	s2,80(sp)
    80006822:	69a6                	ld	s3,72(sp)
    80006824:	6a06                	ld	s4,64(sp)
    80006826:	7ae2                	ld	s5,56(sp)
    80006828:	7b42                	ld	s6,48(sp)
    8000682a:	7ba2                	ld	s7,40(sp)
    8000682c:	7c02                	ld	s8,32(sp)
    8000682e:	6ce2                	ld	s9,24(sp)
    80006830:	6d42                	ld	s10,16(sp)
    80006832:	6da2                	ld	s11,8(sp)
    80006834:	6165                	addi	sp,sp,112
    80006836:	8082                	ret
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006838:	100027b7          	lui	a5,0x10002
    8000683c:	0607a823          	sw	zero,112(a5) # 10002070 <_entry-0x6fffdf90>
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006840:	4705                	li	a4,1
    80006842:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006844:	470d                	li	a4,3
    80006846:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_DRIVER_FEATURES) = 0;
    80006848:	0207a023          	sw	zero,32(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    8000684c:	472d                	li	a4,11
    8000684e:	dbb8                	sw	a4,112(a5)
    if (!(*R1(VIRTIO_MMIO_STATUS) & VIRTIO_CONFIG_S_FEATURES_OK))
    80006850:	5bbc                	lw	a5,112(a5)
    80006852:	8ba1                	andi	a5,a5,8
    80006854:	1e078963          	beqz	a5,80006a46 <virtio_gpu_init+0x2b6>
    *R1(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006858:	100027b7          	lui	a5,0x10002
    8000685c:	0207a823          	sw	zero,48(a5) # 10002030 <_entry-0x6fffdfd0>
    if (*R1(VIRTIO_MMIO_QUEUE_READY))
    80006860:	43fc                	lw	a5,68(a5)
    80006862:	2781                	sext.w	a5,a5
    80006864:	1e079963          	bnez	a5,80006a56 <virtio_gpu_init+0x2c6>
    if (*R1(VIRTIO_MMIO_QUEUE_NUM_MAX) < GPU_NUM)
    80006868:	100027b7          	lui	a5,0x10002
    8000686c:	5bdc                	lw	a5,52(a5)
    8000686e:	2781                	sext.w	a5,a5
    80006870:	471d                	li	a4,7
    80006872:	1ef77a63          	bgeu	a4,a5,80006a66 <virtio_gpu_init+0x2d6>
    gq.desc = kalloc();
    80006876:	ffffa097          	auipc	ra,0xffffa
    8000687a:	270080e7          	jalr	624(ra) # 80000ae6 <kalloc>
    8000687e:	0001c497          	auipc	s1,0x1c
    80006882:	25248493          	addi	s1,s1,594 # 80022ad0 <gq>
    80006886:	e088                	sd	a0,0(s1)
    gq.avail = kalloc();
    80006888:	ffffa097          	auipc	ra,0xffffa
    8000688c:	25e080e7          	jalr	606(ra) # 80000ae6 <kalloc>
    80006890:	e488                	sd	a0,8(s1)
    gq.used = kalloc();
    80006892:	ffffa097          	auipc	ra,0xffffa
    80006896:	254080e7          	jalr	596(ra) # 80000ae6 <kalloc>
    8000689a:	87aa                	mv	a5,a0
    8000689c:	e888                	sd	a0,16(s1)
    if (!gq.desc || !gq.avail || !gq.used)
    8000689e:	6088                	ld	a0,0(s1)
    800068a0:	1c050b63          	beqz	a0,80006a76 <virtio_gpu_init+0x2e6>
    800068a4:	0001c717          	auipc	a4,0x1c
    800068a8:	23473703          	ld	a4,564(a4) # 80022ad8 <gq+0x8>
    800068ac:	1c070563          	beqz	a4,80006a76 <virtio_gpu_init+0x2e6>
    800068b0:	1c078363          	beqz	a5,80006a76 <virtio_gpu_init+0x2e6>
    memset(gq.desc, 0, PGSIZE);
    800068b4:	6605                	lui	a2,0x1
    800068b6:	4581                	li	a1,0
    800068b8:	ffffa097          	auipc	ra,0xffffa
    800068bc:	41a080e7          	jalr	1050(ra) # 80000cd2 <memset>
    memset(gq.avail, 0, PGSIZE);
    800068c0:	0001c497          	auipc	s1,0x1c
    800068c4:	21048493          	addi	s1,s1,528 # 80022ad0 <gq>
    800068c8:	6605                	lui	a2,0x1
    800068ca:	4581                	li	a1,0
    800068cc:	6488                	ld	a0,8(s1)
    800068ce:	ffffa097          	auipc	ra,0xffffa
    800068d2:	404080e7          	jalr	1028(ra) # 80000cd2 <memset>
    memset(gq.used, 0, PGSIZE);
    800068d6:	6605                	lui	a2,0x1
    800068d8:	4581                	li	a1,0
    800068da:	6888                	ld	a0,16(s1)
    800068dc:	ffffa097          	auipc	ra,0xffffa
    800068e0:	3f6080e7          	jalr	1014(ra) # 80000cd2 <memset>
    *R1(VIRTIO_MMIO_QUEUE_NUM) = GPU_NUM;
    800068e4:	100027b7          	lui	a5,0x10002
    800068e8:	4721                	li	a4,8
    800068ea:	df98                	sw	a4,56(a5)
    *R1(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)gq.desc;
    800068ec:	4098                	lw	a4,0(s1)
    800068ee:	08e7a023          	sw	a4,128(a5) # 10002080 <_entry-0x6fffdf80>
    *R1(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)gq.desc >> 32;
    800068f2:	40d8                	lw	a4,4(s1)
    800068f4:	08e7a223          	sw	a4,132(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)gq.avail;
    800068f8:	6498                	ld	a4,8(s1)
    800068fa:	0007069b          	sext.w	a3,a4
    800068fe:	08d7a823          	sw	a3,144(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)gq.avail >> 32;
    80006902:	9701                	srai	a4,a4,0x20
    80006904:	08e7aa23          	sw	a4,148(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)gq.used;
    80006908:	6898                	ld	a4,16(s1)
    8000690a:	0007069b          	sext.w	a3,a4
    8000690e:	0ad7a023          	sw	a3,160(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)gq.used >> 32;
    80006912:	9701                	srai	a4,a4,0x20
    80006914:	0ae7a223          	sw	a4,164(a5)
    *R1(VIRTIO_MMIO_QUEUE_READY) = 1;
    80006918:	4705                	li	a4,1
    8000691a:	c3f8                	sw	a4,68(a5)
        gq.free[i] = 1;
    8000691c:	00e48c23          	sb	a4,24(s1)
    80006920:	00e48ca3          	sb	a4,25(s1)
    80006924:	00e48d23          	sb	a4,26(s1)
    80006928:	00e48da3          	sb	a4,27(s1)
    8000692c:	00e48e23          	sb	a4,28(s1)
    80006930:	00e48ea3          	sb	a4,29(s1)
    80006934:	00e48f23          	sb	a4,30(s1)
    80006938:	00e48fa3          	sb	a4,31(s1)
    *R1(VIRTIO_MMIO_STATUS) = status;
    8000693c:	473d                	li	a4,15
    8000693e:	dbb8                	sw	a4,112(a5)
    for (int i = 0; i < FB_PAGES; i++)
    80006940:	00020917          	auipc	s2,0x20
    80006944:	b2890913          	addi	s2,s2,-1240 # 80026468 <fb>
    80006948:	00020997          	auipc	s3,0x20
    8000694c:	48098993          	addi	s3,s3,1152 # 80026dc8 <end>
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006950:	84ca                	mv	s1,s2
        fb[i] = kalloc();
    80006952:	ffffa097          	auipc	ra,0xffffa
    80006956:	194080e7          	jalr	404(ra) # 80000ae6 <kalloc>
    8000695a:	e088                	sd	a0,0(s1)
        if (!fb[i])
    8000695c:	12050563          	beqz	a0,80006a86 <virtio_gpu_init+0x2f6>
        memset(fb[i], 0, PGSIZE); // fill with COLOR_BG (0 = black)
    80006960:	6605                	lui	a2,0x1
    80006962:	4581                	li	a1,0
    80006964:	ffffa097          	auipc	ra,0xffffa
    80006968:	36e080e7          	jalr	878(ra) # 80000cd2 <memset>
    for (int i = 0; i < FB_PAGES; i++)
    8000696c:	04a1                	addi	s1,s1,8
    8000696e:	ff3492e3          	bne	s1,s3,80006952 <virtio_gpu_init+0x1c2>
    memset(&create_req, 0, sizeof(create_req));
    80006972:	0001c497          	auipc	s1,0x1c
    80006976:	15e48493          	addi	s1,s1,350 # 80022ad0 <gq>
    8000697a:	0001c997          	auipc	s3,0x1c
    8000697e:	21698993          	addi	s3,s3,534 # 80022b90 <create_req.6>
    80006982:	02800613          	li	a2,40
    80006986:	4581                	li	a1,0
    80006988:	854e                	mv	a0,s3
    8000698a:	ffffa097          	auipc	ra,0xffffa
    8000698e:	348080e7          	jalr	840(ra) # 80000cd2 <memset>
    create_req.hdr.type = VIRTIO_GPU_CMD_RESOURCE_CREATE_2D;
    80006992:	10100793          	li	a5,257
    80006996:	0cf4a023          	sw	a5,192(s1)
    create_req.resource_id = RESOURCE_ID;
    8000699a:	4785                	li	a5,1
    8000699c:	0cf4ac23          	sw	a5,216(s1)
    create_req.format = VIRTIO_GPU_FORMAT_B8G8R8X8_UNORM;
    800069a0:	4789                	li	a5,2
    800069a2:	0cf4ae23          	sw	a5,220(s1)
    create_req.width = SCREEN_W;
    800069a6:	28000793          	li	a5,640
    800069aa:	0ef4a023          	sw	a5,224(s1)
    create_req.height = SCREEN_H;
    800069ae:	1e000793          	li	a5,480
    800069b2:	0ef4a223          	sw	a5,228(s1)
    gpu_send(&create_req, sizeof(create_req));
    800069b6:	02800593          	li	a1,40
    800069ba:	854e                	mv	a0,s3
    800069bc:	00000097          	auipc	ra,0x0
    800069c0:	ba6080e7          	jalr	-1114(ra) # 80006562 <gpu_send>
    for (int i = 0; i < FB_PAGES; i++) {
    800069c4:	0001d797          	auipc	a5,0x1d
    800069c8:	50478793          	addi	a5,a5,1284 # 80023ec8 <fb_entries.5>
    800069cc:	0001e617          	auipc	a2,0x1e
    800069d0:	7bc60613          	addi	a2,a2,1980 # 80025188 <attach_buf>
        fb_entries[i].length = PGSIZE;
    800069d4:	6685                	lui	a3,0x1
        fb_entries[i].addr   = (uint64)fb[i];
    800069d6:	00093703          	ld	a4,0(s2)
    800069da:	e398                	sd	a4,0(a5)
        fb_entries[i].length = PGSIZE;
    800069dc:	c794                	sw	a3,8(a5)
    for (int i = 0; i < FB_PAGES; i++) {
    800069de:	0921                	addi	s2,s2,8
    800069e0:	07c1                	addi	a5,a5,16
    800069e2:	fec79ae3          	bne	a5,a2,800069d6 <virtio_gpu_init+0x246>
    gpu_cmd_attach(fb_entries, FB_PAGES);
    800069e6:	12c00593          	li	a1,300
    800069ea:	0001d517          	auipc	a0,0x1d
    800069ee:	4de50513          	addi	a0,a0,1246 # 80023ec8 <fb_entries.5>
    800069f2:	00000097          	auipc	ra,0x0
    800069f6:	c7c080e7          	jalr	-900(ra) # 8000666e <gpu_cmd_attach>
        for (int i = 0; msg[i]; i++)
    800069fa:	00002c17          	auipc	s8,0x2
    800069fe:	14ec0c13          	addi	s8,s8,334 # 80008b48 <syscalls+0x628>
    gpu_cmd_attach(fb_entries, FB_PAGES);
    80006a02:	0008cbb7          	lui	s7,0x8c
    80006a06:	250b8b93          	addi	s7,s7,592 # 8c250 <_entry-0x7ff73db0>
        for (int i = 0; msg[i]; i++)
    80006a0a:	04800793          	li	a5,72
    const uint8 *rows = font8x8[ch];
    80006a0e:	00002c97          	auipc	s9,0x2
    80006a12:	1a2c8c93          	addi	s9,s9,418 # 80008bb0 <font8x8>
    80006a16:	00024737          	lui	a4,0x24
    80006a1a:	a0070d93          	addi	s11,a4,-1536 # 23a00 <_entry-0x7ffdc600>
        for (int col = 0; col < 8; col++)
    80006a1e:	4d01                	li	s10,0
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006a20:	010004b7          	lui	s1,0x1000
    80006a24:	14fd                	addi	s1,s1,-1
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006a26:	00020897          	auipc	a7,0x20
    80006a2a:	a4288893          	addi	a7,a7,-1470 # 80026468 <fb>
    int off = byte_off % PGSIZE;
    80006a2e:	6805                	lui	a6,0x1
    80006a30:	187d                	addi	a6,a6,-1
            for (int dy = 0; dy < SCALE; dy++)
    80006a32:	6e05                	lui	t3,0x1
    80006a34:	a00e0e1b          	addiw	t3,t3,-1536
        for (int col = 0; col < 8; col++)
    80006a38:	40a1                	li	ra,8
    for (int row = 0; row < 8; row++)
    80006a3a:	6a8d                	lui	s5,0x3
    80006a3c:	800a8a9b          	addiw	s5,s5,-2048
    80006a40:	10000b13          	li	s6,256
    80006a44:	a0f1                	j	80006b10 <virtio_gpu_init+0x380>
        panic("virtio_gpu: FEATURES_OK not set");
    80006a46:	00002517          	auipc	a0,0x2
    80006a4a:	04a50513          	addi	a0,a0,74 # 80008a90 <syscalls+0x570>
    80006a4e:	ffffa097          	auipc	ra,0xffffa
    80006a52:	af0080e7          	jalr	-1296(ra) # 8000053e <panic>
        panic("virtio_gpu: queue already ready");
    80006a56:	00002517          	auipc	a0,0x2
    80006a5a:	05a50513          	addi	a0,a0,90 # 80008ab0 <syscalls+0x590>
    80006a5e:	ffffa097          	auipc	ra,0xffffa
    80006a62:	ae0080e7          	jalr	-1312(ra) # 8000053e <panic>
        panic("virtio_gpu: queue too small");
    80006a66:	00002517          	auipc	a0,0x2
    80006a6a:	06a50513          	addi	a0,a0,106 # 80008ad0 <syscalls+0x5b0>
    80006a6e:	ffffa097          	auipc	ra,0xffffa
    80006a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>
        panic("virtio_gpu: kalloc failed for queue");
    80006a76:	00002517          	auipc	a0,0x2
    80006a7a:	07a50513          	addi	a0,a0,122 # 80008af0 <syscalls+0x5d0>
    80006a7e:	ffffa097          	auipc	ra,0xffffa
    80006a82:	ac0080e7          	jalr	-1344(ra) # 8000053e <panic>
            panic("virtio_gpu: kalloc failed for framebuffer");
    80006a86:	00002517          	auipc	a0,0x2
    80006a8a:	09250513          	addi	a0,a0,146 # 80008b18 <syscalls+0x5f8>
    80006a8e:	ffffa097          	auipc	ra,0xffffa
    80006a92:	ab0080e7          	jalr	-1360(ra) # 8000053e <panic>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006a96:	85fe                	mv	a1,t6
    80006a98:	831e                	mv	t1,t2
                for (int dx = 0; dx < SCALE; dx++)
    80006a9a:	ff05869b          	addiw	a3,a1,-16
    int pg = byte_off / PGSIZE;
    80006a9e:	43f6d613          	srai	a2,a3,0x3f
    80006aa2:	0146561b          	srliw	a2,a2,0x14
    80006aa6:	00d607bb          	addw	a5,a2,a3
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006aaa:	40c7d71b          	sraiw	a4,a5,0xc
    80006aae:	070e                	slli	a4,a4,0x3
    80006ab0:	9746                	add	a4,a4,a7
    int off = byte_off % PGSIZE;
    80006ab2:	0107f7b3          	and	a5,a5,a6
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006ab6:	9f91                	subw	a5,a5,a2
    *p = color;
    80006ab8:	6310                	ld	a2,0(a4)
    80006aba:	97b2                	add	a5,a5,a2
    80006abc:	c388                	sw	a0,0(a5)
                for (int dx = 0; dx < SCALE; dx++)
    80006abe:	2691                	addiw	a3,a3,4
    80006ac0:	fcd59fe3          	bne	a1,a3,80006a9e <virtio_gpu_init+0x30e>
            for (int dy = 0; dy < SCALE; dy++)
    80006ac4:	2803031b          	addiw	t1,t1,640
    80006ac8:	00be05bb          	addw	a1,t3,a1
    80006acc:	fdd317e3          	bne	t1,t4,80006a9a <virtio_gpu_init+0x30a>
        for (int col = 0; col < 8; col++)
    80006ad0:	2f05                	addiw	t5,t5,1
    80006ad2:	2fc1                	addiw	t6,t6,16
    80006ad4:	001f0a63          	beq	t5,ra,80006ae8 <virtio_gpu_init+0x358>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006ad8:	0002c503          	lbu	a0,0(t0)
    80006adc:	01e5553b          	srlw	a0,a0,t5
    80006ae0:	8905                	andi	a0,a0,1
    80006ae2:	d955                	beqz	a0,80006a96 <virtio_gpu_init+0x306>
    80006ae4:	8526                	mv	a0,s1
    80006ae6:	bf45                	j	80006a96 <virtio_gpu_init+0x306>
    for (int row = 0; row < 8; row++)
    80006ae8:	01de0ebb          	addw	t4,t3,t4
    80006aec:	012e093b          	addw	s2,t3,s2
    80006af0:	2991                	addiw	s3,s3,4
    80006af2:	014a8a3b          	addw	s4,s5,s4
    80006af6:	0285                	addi	t0,t0,1
    80006af8:	01698663          	beq	s3,s6,80006b04 <virtio_gpu_init+0x374>
        for (int i = 0; msg[i]; i++)
    80006afc:	8fd2                	mv	t6,s4
        for (int col = 0; col < 8; col++)
    80006afe:	8f6a                	mv	t5,s10
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006b00:	83ca                	mv	t2,s2
    80006b02:	bfd9                	j	80006ad8 <virtio_gpu_init+0x348>
        for (int i = 0; msg[i]; i++)
    80006b04:	001c4783          	lbu	a5,1(s8)
    80006b08:	0c05                	addi	s8,s8,1
    80006b0a:	080b8b9b          	addiw	s7,s7,128
    80006b0e:	cb99                	beqz	a5,80006b24 <virtio_gpu_init+0x394>
    const uint8 *rows = font8x8[ch];
    80006b10:	078e                	slli	a5,a5,0x3
    80006b12:	019782b3          	add	t0,a5,s9
    80006b16:	8a5e                	mv	s4,s7
    80006b18:	0e000993          	li	s3,224
    80006b1c:	00023937          	lui	s2,0x23
    80006b20:	8eee                	mv	t4,s11
    80006b22:	bfe9                	j	80006afc <virtio_gpu_init+0x36c>
    memset(&scanout_req, 0, sizeof(scanout_req));
    80006b24:	0001c497          	auipc	s1,0x1c
    80006b28:	fac48493          	addi	s1,s1,-84 # 80022ad0 <gq>
    80006b2c:	0001c917          	auipc	s2,0x1c
    80006b30:	08c90913          	addi	s2,s2,140 # 80022bb8 <scanout_req.4>
    80006b34:	03000613          	li	a2,48
    80006b38:	4581                	li	a1,0
    80006b3a:	854a                	mv	a0,s2
    80006b3c:	ffffa097          	auipc	ra,0xffffa
    80006b40:	196080e7          	jalr	406(ra) # 80000cd2 <memset>
    scanout_req.hdr.type = VIRTIO_GPU_CMD_SET_SCANOUT;
    80006b44:	10300793          	li	a5,259
    80006b48:	0ef4a423          	sw	a5,232(s1)
    scanout_req.r.x = 0;
    80006b4c:	1004a023          	sw	zero,256(s1)
    scanout_req.r.y = 0;
    80006b50:	1004a223          	sw	zero,260(s1)
    scanout_req.r.width = SCREEN_W;
    80006b54:	28000793          	li	a5,640
    80006b58:	10f4a423          	sw	a5,264(s1)
    scanout_req.r.height = SCREEN_H;
    80006b5c:	1e000793          	li	a5,480
    80006b60:	10f4a623          	sw	a5,268(s1)
    scanout_req.scanout_id = SCANOUT_ID;
    80006b64:	1004a823          	sw	zero,272(s1)
    scanout_req.resource_id = RESOURCE_ID;
    80006b68:	4785                	li	a5,1
    80006b6a:	10f4aa23          	sw	a5,276(s1)
    gpu_send(&scanout_req, sizeof(scanout_req));
    80006b6e:	03000593          	li	a1,48
    80006b72:	854a                	mv	a0,s2
    80006b74:	00000097          	auipc	ra,0x0
    80006b78:	9ee080e7          	jalr	-1554(ra) # 80006562 <gpu_send>
    gpu_transfer_flush();
    80006b7c:	00000097          	auipc	ra,0x0
    80006b80:	b5c080e7          	jalr	-1188(ra) # 800066d8 <gpu_transfer_flush>
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
    80006b84:	00002517          	auipc	a0,0x2
    80006b88:	fd450513          	addi	a0,a0,-44 # 80008b58 <syscalls+0x638>
    80006b8c:	ffffa097          	auipc	ra,0xffffa
    80006b90:	9fc080e7          	jalr	-1540(ra) # 80000588 <printf>
    80006b94:	b159                	j	8000681a <virtio_gpu_init+0x8a>

0000000080006b96 <virtio_gpu_commit>:

// ── Public: flush the kernel fb[] to the display ─────────────────────
// Called by display_daemon.  Sends TRANSFER_TO_HOST_2D + RESOURCE_FLUSH.
void virtio_gpu_commit(void)
{
    80006b96:	1141                	addi	sp,sp,-16
    80006b98:	e406                	sd	ra,8(sp)
    80006b9a:	e022                	sd	s0,0(sp)
    80006b9c:	0800                	addi	s0,sp,16
    gpu_transfer_flush();
    80006b9e:	00000097          	auipc	ra,0x0
    80006ba2:	b3a080e7          	jalr	-1222(ra) # 800066d8 <gpu_transfer_flush>
}
    80006ba6:	60a2                	ld	ra,8(sp)
    80006ba8:	6402                	ld	s0,0(sp)
    80006baa:	0141                	addi	sp,sp,16
    80006bac:	8082                	ret

0000000080006bae <display_daemon>:
// Commit period: DISPLAY_DAEMON_TICKS ticks.  xv6's timer fires every
// ~1/10th of a second at QEMU's default rate, giving ~10fps.
#define DISPLAY_DAEMON_TICKS 1

void display_daemon(void)
{
    80006bae:	7179                	addi	sp,sp,-48
    80006bb0:	f406                	sd	ra,40(sp)
    80006bb2:	f022                	sd	s0,32(sp)
    80006bb4:	ec26                	sd	s1,24(sp)
    80006bb6:	e84a                	sd	s2,16(sp)
    80006bb8:	e44e                	sd	s3,8(sp)
    80006bba:	1800                	addi	s0,sp,48
    // The scheduler holds p->lock across swtch into a new process.
    // Release it here, just like forkret does for user processes.
    struct proc *p = myproc();
    80006bbc:	ffffb097          	auipc	ra,0xffffb
    80006bc0:	e26080e7          	jalr	-474(ra) # 800019e2 <myproc>
    release(&p->lock);
    80006bc4:	ffffa097          	auipc	ra,0xffffa
    80006bc8:	0c6080e7          	jalr	198(ra) # 80000c8a <release>

    acquire(&tickslock);
    80006bcc:	00011517          	auipc	a0,0x11
    80006bd0:	b2450513          	addi	a0,a0,-1244 # 800176f0 <tickslock>
    80006bd4:	ffffa097          	auipc	ra,0xffffa
    80006bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    for (;;)
    {
        // Sleep until DISPLAY_DAEMON_TICKS ticks have elapsed.
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006bdc:	00003917          	auipc	s2,0x3
    80006be0:	87490913          	addi	s2,s2,-1932 # 80009450 <ticks>
        while (ticks < deadline)
            sleep(&ticks, &tickslock);
    80006be4:	00011497          	auipc	s1,0x11
    80006be8:	b0c48493          	addi	s1,s1,-1268 # 800176f0 <tickslock>
    80006bec:	a839                	j	80006c0a <display_daemon+0x5c>

        release(&tickslock);
    80006bee:	8526                	mv	a0,s1
    80006bf0:	ffffa097          	auipc	ra,0xffffa
    80006bf4:	09a080e7          	jalr	154(ra) # 80000c8a <release>
    gpu_transfer_flush();
    80006bf8:	00000097          	auipc	ra,0x0
    80006bfc:	ae0080e7          	jalr	-1312(ra) # 800066d8 <gpu_transfer_flush>
        virtio_gpu_commit();
        acquire(&tickslock);
    80006c00:	8526                	mv	a0,s1
    80006c02:	ffffa097          	auipc	ra,0xffffa
    80006c06:	fd4080e7          	jalr	-44(ra) # 80000bd6 <acquire>
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006c0a:	00092783          	lw	a5,0(s2)
    80006c0e:	0017899b          	addiw	s3,a5,1
        while (ticks < deadline)
    80006c12:	fd37fee3          	bgeu	a5,s3,80006bee <display_daemon+0x40>
            sleep(&ticks, &tickslock);
    80006c16:	85a6                	mv	a1,s1
    80006c18:	854a                	mv	a0,s2
    80006c1a:	ffffb097          	auipc	ra,0xffffb
    80006c1e:	508080e7          	jalr	1288(ra) # 80002122 <sleep>
        while (ticks < deadline)
    80006c22:	00092783          	lw	a5,0(s2)
    80006c26:	ff37e8e3          	bltu	a5,s3,80006c16 <display_daemon+0x68>
    80006c2a:	b7d1                	j	80006bee <display_daemon+0x40>

0000000080006c2c <get_fb_addr>:
    }
}

void*
get_fb_addr(void)
{
    80006c2c:	1141                	addi	sp,sp,-16
    80006c2e:	e422                	sd	s0,8(sp)
    80006c30:	0800                	addi	s0,sp,16
  return (void*)fb;
}
    80006c32:	00020517          	auipc	a0,0x20
    80006c36:	83650513          	addi	a0,a0,-1994 # 80026468 <fb>
    80006c3a:	6422                	ld	s0,8(sp)
    80006c3c:	0141                	addi	sp,sp,16
    80006c3e:	8082                	ret

0000000080006c40 <get_fb_page>:
void*
get_fb_page(int page_index)
{
    80006c40:	1141                	addi	sp,sp,-16
    80006c42:	e422                	sd	s0,8(sp)
    80006c44:	0800                	addi	s0,sp,16
  if (page_index < 0 || page_index >= FB_PAGES) {
    80006c46:	12b00713          	li	a4,299
    80006c4a:	00a76d63          	bltu	a4,a0,80006c64 <get_fb_page+0x24>
    return 0;
  }
  return fb[page_index]; 
    80006c4e:	00351793          	slli	a5,a0,0x3
    80006c52:	00020717          	auipc	a4,0x20
    80006c56:	81670713          	addi	a4,a4,-2026 # 80026468 <fb>
    80006c5a:	97ba                	add	a5,a5,a4
    80006c5c:	6388                	ld	a0,0(a5)
}
    80006c5e:	6422                	ld	s0,8(sp)
    80006c60:	0141                	addi	sp,sp,16
    80006c62:	8082                	ret
    return 0;
    80006c64:	4501                	li	a0,0
    80006c66:	bfe5                	j	80006c5e <get_fb_page+0x1e>

0000000080006c68 <get_entries_from_buf>:


void
get_entries_from_buf(uint64 buf, int n, struct virtio_gpu_mem_entry* entries)
{
    80006c68:	7139                	addi	sp,sp,-64
    80006c6a:	fc06                	sd	ra,56(sp)
    80006c6c:	f822                	sd	s0,48(sp)
    80006c6e:	f426                	sd	s1,40(sp)
    80006c70:	f04a                	sd	s2,32(sp)
    80006c72:	ec4e                	sd	s3,24(sp)
    80006c74:	e852                	sd	s4,16(sp)
    80006c76:	e456                	sd	s5,8(sp)
    80006c78:	e05a                	sd	s6,0(sp)
    80006c7a:	0080                	addi	s0,sp,64
    80006c7c:	892a                	mv	s2,a0
    80006c7e:	8a2e                	mv	s4,a1
    80006c80:	8b32                	mv	s6,a2
    struct proc *p = myproc();
    80006c82:	ffffb097          	auipc	ra,0xffffb
    80006c86:	d60080e7          	jalr	-672(ra) # 800019e2 <myproc>
    for(int i = 0; i < n; i++){
    80006c8a:	03405d63          	blez	s4,80006cc4 <get_entries_from_buf+0x5c>
    80006c8e:	8aaa                	mv	s5,a0
    80006c90:	84da                	mv	s1,s6
    80006c92:	3a7d                	addiw	s4,s4,-1
    80006c94:	1a02                	slli	s4,s4,0x20
    80006c96:	020a5a13          	srli	s4,s4,0x20
    80006c9a:	0a12                	slli	s4,s4,0x4
    80006c9c:	0b41                	addi	s6,s6,16
    80006c9e:	9a5a                	add	s4,s4,s6
        uint64 pa = walkaddr(p->pagetable, va);
        if(pa == 0){
            panic("get_entries_from_buf: failed");
        }
        entries[i].addr = pa;
        entries[i].length = PGSIZE;
    80006ca0:	6985                	lui	s3,0x1
        uint64 pa = walkaddr(p->pagetable, va);
    80006ca2:	85ca                	mv	a1,s2
    80006ca4:	050ab503          	ld	a0,80(s5) # 3050 <_entry-0x7fffcfb0>
    80006ca8:	ffffa097          	auipc	ra,0xffffa
    80006cac:	3d4080e7          	jalr	980(ra) # 8000107c <walkaddr>
        if(pa == 0){
    80006cb0:	c505                	beqz	a0,80006cd8 <get_entries_from_buf+0x70>
        entries[i].addr = pa;
    80006cb2:	e088                	sd	a0,0(s1)
        entries[i].length = PGSIZE;
    80006cb4:	0134a423          	sw	s3,8(s1)
        entries[i].padding = 0;
    80006cb8:	0004a623          	sw	zero,12(s1)
    for(int i = 0; i < n; i++){
    80006cbc:	994e                	add	s2,s2,s3
    80006cbe:	04c1                	addi	s1,s1,16
    80006cc0:	ff4491e3          	bne	s1,s4,80006ca2 <get_entries_from_buf+0x3a>
    }
}
    80006cc4:	70e2                	ld	ra,56(sp)
    80006cc6:	7442                	ld	s0,48(sp)
    80006cc8:	74a2                	ld	s1,40(sp)
    80006cca:	7902                	ld	s2,32(sp)
    80006ccc:	69e2                	ld	s3,24(sp)
    80006cce:	6a42                	ld	s4,16(sp)
    80006cd0:	6aa2                	ld	s5,8(sp)
    80006cd2:	6b02                	ld	s6,0(sp)
    80006cd4:	6121                	addi	sp,sp,64
    80006cd6:	8082                	ret
            panic("get_entries_from_buf: failed");
    80006cd8:	00002517          	auipc	a0,0x2
    80006cdc:	eb850513          	addi	a0,a0,-328 # 80008b90 <syscalls+0x670>
    80006ce0:	ffffa097          	auipc	ra,0xffffa
    80006ce4:	85e080e7          	jalr	-1954(ra) # 8000053e <panic>

0000000080006ce8 <virtio_gpu_flip>:
uint64
virtio_gpu_flip(uint64 buf)
{
    80006ce8:	7179                	addi	sp,sp,-48
    80006cea:	f406                	sd	ra,40(sp)
    80006cec:	f022                	sd	s0,32(sp)
    80006cee:	ec26                	sd	s1,24(sp)
    80006cf0:	e84a                	sd	s2,16(sp)
    80006cf2:	e44e                	sd	s3,8(sp)
    80006cf4:	1800                	addi	s0,sp,48
    80006cf6:	84aa                	mv	s1,a0
    memset(&detach, 0, sizeof(detach));
    80006cf8:	0001c997          	auipc	s3,0x1c
    80006cfc:	dd898993          	addi	s3,s3,-552 # 80022ad0 <gq>
    80006d00:	0001c917          	auipc	s2,0x1c
    80006d04:	ee890913          	addi	s2,s2,-280 # 80022be8 <detach.0>
    80006d08:	02000613          	li	a2,32
    80006d0c:	4581                	li	a1,0
    80006d0e:	854a                	mv	a0,s2
    80006d10:	ffffa097          	auipc	ra,0xffffa
    80006d14:	fc2080e7          	jalr	-62(ra) # 80000cd2 <memset>
    detach.hdr.type = VIRTIO_GPU_CMD_RESOURCE_DETACH_BACKING;
    80006d18:	10700793          	li	a5,263
    80006d1c:	10f9ac23          	sw	a5,280(s3)
    detach.resource_id = RESOURCE_ID;
    80006d20:	4785                	li	a5,1
    80006d22:	12f9a823          	sw	a5,304(s3)
    gpu_send(&detach, sizeof(detach));
    80006d26:	02000593          	li	a1,32
    80006d2a:	854a                	mv	a0,s2
    80006d2c:	00000097          	auipc	ra,0x0
    80006d30:	836080e7          	jalr	-1994(ra) # 80006562 <gpu_send>
    static struct virtio_gpu_mem_entry entries[FB_PAGES];
    gpu_cmd_detach();
    
    get_entries_from_buf(buf, FB_PAGES, entries);
    80006d34:	0001c617          	auipc	a2,0x1c
    80006d38:	ed460613          	addi	a2,a2,-300 # 80022c08 <entries.1>
    80006d3c:	12c00593          	li	a1,300
    80006d40:	8526                	mv	a0,s1
    80006d42:	00000097          	auipc	ra,0x0
    80006d46:	f26080e7          	jalr	-218(ra) # 80006c68 <get_entries_from_buf>
    
    gpu_cmd_attach(entries, FB_PAGES);
    80006d4a:	12c00593          	li	a1,300
    80006d4e:	0001c517          	auipc	a0,0x1c
    80006d52:	eba50513          	addi	a0,a0,-326 # 80022c08 <entries.1>
    80006d56:	00000097          	auipc	ra,0x0
    80006d5a:	918080e7          	jalr	-1768(ra) # 8000666e <gpu_cmd_attach>
            
    return 0;
}
    80006d5e:	4501                	li	a0,0
    80006d60:	70a2                	ld	ra,40(sp)
    80006d62:	7402                	ld	s0,32(sp)
    80006d64:	64e2                	ld	s1,24(sp)
    80006d66:	6942                	ld	s2,16(sp)
    80006d68:	69a2                	ld	s3,8(sp)
    80006d6a:	6145                	addi	sp,sp,48
    80006d6c:	8082                	ret
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
