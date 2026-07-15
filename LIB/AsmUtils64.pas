unit AsmUtils64;

interface

procedure ZeroMemory64(Dst: Pointer; ByteCount: Int64);
procedure FillQword64(Dst: Pointer; ByteCount: Int64; Value: Int64);
function MemCopy64(Src, Dst: Pointer; ByteCount: Int64): Pointer;
function IntLog2(N: Int64; var Log2N: Int64): Boolean;
function RoundUp(X, Mask: Int64): Int64;
function CmpStr(P0, P1: Pointer; Length: Int64): Int64;
function CompareShortString(S0, S1: ShortString): Int64;
function Swap64(X, Shift: Int64): Int64;
function WSWAP32(I: Int32): Int32;
function RoundUp64(I: Int64): Int64;
function CPUID_AVX2_FMA3: Boolean;
function PopCnt(I: Int64): Integer;

implementation

procedure ZeroMemory64(Dst: Pointer; ByteCount: Int64); assembler;
asm
  .NOFRAME
  push rdi
  mov rdi, rcx
  mov rcx, rdx
  and rdx, 7
  shr rcx, 3
  xor rax, rax
  cld
  rep stosq
  mov rcx, rdx
  rep stosb
  pop rdi
end;

procedure FillQword64(Dst: Pointer; ByteCount: Int64; Value: Int64); assembler;
asm
  .NOFRAME
  push rdi
  mov rdi, rcx
  mov rcx, rdx
  mov rax, r8
  rep stosq
  pop rdi
end;

function MemCopy64(Src, Dst: Pointer; ByteCount: Int64): Pointer;  assembler;
asm
  .NOFRAME
  push rsi
  push rdi
  mov rsi, rcx
  mov rdi, rdx
  mov rax, r8
  mov rcx, rax
  and rax, 7
  shr rcx, 3
  cld
  rep movsq
  mov rcx, rax
  rep movsb
  mov rax, rdi
  pop rdi
  pop rsi
end;

function IntLog2(N: Int64; var Log2N: Int64): Boolean; assembler;
asm
  .NOFRAME
  mov rax, rcx
  bsf rcx, rax
  jz @@error
  bsr rax, rax
  mov [rdx], rax
  cmp rax, rcx
  jnz @@error
  mov rax, 1
  jmp @@quit
@@error:
  xor rax, rax
@@quit:
end;

function RoundUp(X, Mask: Int64): Int64; assembler;
asm
  .NOFRAME
@@start:
  mov rax, rcx
  and rax, rdx
  jz @@quit
  inc rcx
  jmp @@start
@@quit:
  mov rax, rcx
end;

function CmpStr(P0, P1: Pointer; Length: Int64): Int64; assembler;
asm
  .NOFRAME
  push rsi
  push rdi
  mov rsi, rcx
  mov rdi, rdx
  mov rcx, r8
  xor rax, rax
  repz cmpsb
  jz @@quit
  ja @@plus
  mov rax, -1
  jmp @@quit
@@plus:
  mov rax, 1
@@quit:
  pop rdi
  pop rsi
end;

function CompareShortString(S0, S1: ShortString): Int64; assembler;
asm
  .NOFRAME
  push rsi
  push rdi
  mov rdi, rcx
  mov rsi, rdx
  xor rax, rax
  lodsb
  mov rcx, rax
  mov r8, rax
  xchg rsi, rdi
  xor rax, rax
  lodsb
  mov rdx, rax
  cmp rax, rcx
  jae @@start
  mov rcx, rax
@@start:
  xor rax, rax
  repz cmpsb
  jb @@minus
  ja @@plus
  cmp rdx, r8
  jz @@quit
  ja @@plus
@@minus:
  mov rax, -1
  jmp @@quit
@@plus:
  mov rax, 1
@@quit:
  pop rdi
  pop rsi
end;

function Swap64(X, Shift: Int64): Int64; assembler;
asm
  .NOFRAME
  mov rax, rcx
  mov rcx, rdx
  bswap rax
  shr rax, cl
end;

function WSWAP32(I: Int32): Int32; assembler;
asm
  .NOFRAME
  rol eax, 16
end;

function RoundUp64(I: Int64): Int64; assembler;
asm
  .NOFRAME
  lea rax, [rcx + 63]         // RAX = input + 63
  and rax, $FFFFFFFFFFFFFFC0  // (bitwise AND with (NOT 63))
end;

function CPUID_AVX2_FMA3: Boolean; assembler;
asm
  .NOFRAME
  {$IFDEF CPUX64}
  // The Win64 ABI dictates that RBX must be preserved.
  // We use volatile registers like R8 and R9 to back up our state safely.
  mov r8, rbx
  mov r9, rdi

  // --- STEP 1: Check FMA3 ---
  mov eax, 1      // Leaf 1: Processor Info and Feature Bits
  cpuid           // Alters EAX, EBX, ECX, EDX

  // FMA3 is stored in ECX, bit 12
  bt ecx, 12      // Test bit 12 of ECX
  jnc @NotSupported

  // --- STEP 2: Check AVX2 ---
  mov eax, 7      // Leaf 7: Structured Extended Feature Flags
  xor ecx, ecx    // Sub-leaf 0
  cpuid           // Alters EAX, EBX, ECX, EDX

  // AVX2 is stored in EBX, bit 5
  bt ebx, 5       // Test bit 5 of EBX
  jnc @NotSupported

  // Both features are supported
  mov al, 1       // Set return value (AL) to True
  jmp @Exit

@NotSupported:
  mov al, 0       // Set return value (AL) to False

@Exit:
  // Restore registers required by the calling convention
  mov rbx, r8
  mov rdi, r9
  {$ELSE}
  // Fallback for 32-bit compilation if target changes accidentally
  mov al, 0
  {$ENDIF}
end;

function PopCnt(I: Int64): Integer; assembler;
// returns the number of nonzero bits in a 64-bit number
asm
  POPCNT  RAX, RCX
end;

end.
