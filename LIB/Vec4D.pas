unit Vec4D;

interface

uses System.Math, MathPlus64;

const
  BATCH_SIZE = 4;
  BATCH_LO = 0;
  BATCH_HI = BATCH_SIZE - 1;
  MACHINE_EPSILON = 2.220446049250313e-16;

type
  {$ALIGN 16}
  TVec4D = packed record
   class operator Add(const Left, Right: TVec4D): TVec4D; inline;
   class operator Subtract(const Left, Right: TVec4D): TVec4D; inline;
   class operator Multiply(const Left, Right: TVec4D): TVec4D; inline;                   // quaternion transform     - Rodrigues formula, assumes unit versor
   class operator Multiply(const Left: TVec4D; Right: Double): TVec4D; inline;           // scalar multiplication
   class operator Multiply(Left: Double; const Right: TVec4D): TVec4D; inline;           // scalar multiplication
   class operator BitwiseAnd(const Left, Right: TVec4D): TVec4D; inline;                 // quaternion product
   class operator BitwiseOr(const Left, Right: TVec4D): Double; inline;                  // dot product
   class operator BitwiseXor(const Left, Right: TVec4D): TVec4D; inline;                 // cross product
   class operator LogicalNot(const Left: TVec4D): TVec4D; inline;                        // Quaternion conjugate
   function Magnitude4D: Double; inline;                                                 // Quaternion magnitude
   function Magnitude3D: Double; inline;                                                 // 3D vector length         - uses sorted sum
   function Normalize4D: TVec4D; inline;                                                 // Quaternion normalization - uses sorted sum
   function Normalize3D: TVec4D; inline;                                                 // 3D vector normalization  - uses sorted sum
   function NormalizeW: TVec4D; inline;                                                  // Homogenous vector normalization
   //function InvCubeScale3D_Hypot(S: Double): TVec4D; inline;                                   // S/r3 * rvec, used in acceleration calculations
   function InvCubeScale3D(S: Double): TVec4D; inline;                                   // S/r3 * rvec, used in acceleration calculations
   function SqrMag4D: Double; inline;                                                    // Square of quaternion (4D) magnitude  - uses sorted sum
   function SqrMag3D: Double; inline;                                                    // Square of vector (3D) magnitude  - uses sorted sum
   function P2V3D: TVec4D;                                                               // Polar to vector
   function V2P3D: TVec4D;                                                               // Vector to polar
   //function Length: Double; inline;                                                      // Vector (3D) magnitude      - uses sorted sum
   //function Scale: Double; inline;                                                       // Vector (3D) magnitude * W  - uses sorted sum
   case Integer of
    0: (X, Y, Z, W: Double);                // as homogenous vector
    1: (pL, pA, pD, pW: Double);            // in polar format
    2: (I, J, K, R: Double);                // as a quaternion
    3: (ci0, ci1, ci2, ci3: Int64);             // as integers
    4: (cf: array[0..3] of Double);         // just an array of scalars
    5: (ci: array[0..3] of Int64);          // an array of integers to access it without floating-point math
  end;
  PVec4D = ^TVec4D;
  //TVec4DArray = array[0..MaxInt div SizeOf(TVec4D) - 1] of TVec4D;
  //PVec4DArray = ^TVec4DArray;

  TMat4D = packed record
   class operator Multiply(const Left, Right: TMat4D): TMat4D; inline;                // matrix multiplication
   class operator Multiply(const Left: TVec4D; const Right: TMat4D): TVec4D; inline;  // transform                   - uses sorted sum (the functions don't)!!! - WIP
   class operator Multiply(const Left: TMat4D; const Right: TVec4D): TVec4D; inline;  // transform                   - uses sorted sum (the functions don't)!!! - WIP
   procedure FromQuat(Q: PVec4D); inline;                                             // create from quaternion      - same as the standalone function but they don't agree with the asm functions
   case Integer of
   0: (X, Y, Z, W: TVec4D);
   1: (V: array[0..3] of TVec4D);
   2: (cf: array[0..15] of Double);
   3: (ci: array[0..15] of Int64);
   4: (ci00, ci01, ci02, ci03, ci10, ci11, ci12, ci13, ci20, ci21, ci22, ci23, ci30, ci31, ci32, ci33: Int64);
   5: (cf00, cf01, cf02, cf03, cf10, cf11, cf12, cf13, cf20, cf21, cf22, cf23, cf30, cf31, cf32, cf33: Double);
  end;
  PMat4D = ^TMat4D;

  TState4D = packed record
    case Integer of
     0: (R, V, RR, VV: TVec4D);
     1: (Vec: array[0..3] of TVec4D);
     2: (Num: array[0..15] of Double);
     3: (Int: array[0..15] of Int64);
     4: (Pos, Vel: TVec4D; Epoch, GM, e, q, Anom, Peri, Node, Incl: Double);
  end;
  PState4D = ^TState4D;
  //TState4DArray = array[0..MaxInt div SizeOf(TState4D) - 1] of TState4D;
  //PState4DArray = ^TVec4DArray;
  TVec4DArray = array of TVec4D;
  TVec4DArrays = array of TVec4DArray;
  TState4DArray = array of TState4D;
  TState4DArrays = array of TState4DArray;
  TDynDoubleArray = array of Double;

  TBatchVectors = array[BATCH_LO..BATCH_HI] of PVec4D;
  PBatchVectors = ^TBatchVectors;
  TBatchPointers = array[BATCH_LO..BATCH_HI] of Pointer;
  PBatchPointes = ^TBatchPointers;
  TMatMulProc = procedure(const Left, Right: TMat4D; var Result: TMat4D);

// ============================================================================
// STANDALONE FUNCTIONS (destructive parameter-format)
// ============================================================================
procedure NormVec4D(V: PVec4D);
procedure AddVec4D(V1, V2: PVec4D);
procedure SubVec4D(V1, V2: PVec4D);
procedure MulVec4D(V1, V2: PVec4D);

procedure NormVec3D(V: PVec4D);
function  LengthVec3D(V: PVec4D): Double;
function  SqrLengthVec3D(V: PVec4D): Double;
function  DotVec3D(V1, V2: PVec4D): Double;

procedure ScalarMulVec3D(V: PVec4D; S: Double);   // 3D: scales X/Y/Z, preserves W
procedure ScalarMulVec4D(V: PVec4D; S: Double);   // 4D: scales X/Y/Z/W (matches the * operator)
procedure AddVec3D(V1, V2: PVec4D);
procedure SubVec3D(V1, V2: PVec4D);
procedure CrossVec3D(V1, V2: PVec4D);

function GetIdentityMat4D: TMat4D; inline;
function GetRotMat4D(Angle, AxisX, AxisY, AxisZ: Double): TMat4D; inline;
procedure MulMat4D(M1, M2: PMat4D);
procedure TransformVec4D(V: PVec4D; M: PMat4D);

procedure NormQuat4D(Q: PVec4D); inline;
function GetIdentityVersor4D: TVec4D; inline;
function GetVersor4D(Angle, AxisX, AxisY, AxisZ: Double): TVec4D; inline;
procedure MulQuat4D(Q1, Q2: PVec4D);
procedure TransformQuat4D(Quat, Versor: PVec4D);               // Rodrigues formula, assumes unit versor
function QuatToMat4D(Quat: PVec4D): TMat4D;

// ============================================================================
// OTHER FUNCTIONS
// ============================================================================
procedure MatMul_SSE2(const Left, Right: TMat4D; var Result: TMat4D);
procedure MatMul_AVX2(const Left, Right: TMat4D; var Result: TMat4D);
function LoadVec4D(X, Y, Z, W: Double): TVec4D;

implementation

function atan2(y, x: Double): Double; inline;
begin
  Result := System.Math.ArcTan2(y, x);
end;

procedure NormVec4D(V: PVec4D); assembler;
asm
  .NOFRAME
  MOV     RAX, [RCX + 24]
  TEST    RAX, RAX
  JZ      @Exit

  MOVQ    XMM3, RAX              // xmm3 = TempZ = W
  MOV     RAX, $3FF0000000000000 // Double 1.0
  MOVQ    XMM4, RAX
  DIVSD   XMM4, XMM3             // xmm4 = 1/W

  MOVSD XMM0, [RCX]
  MOVSD XMM1, [RCX + 8]
  MOVSD XMM2, [RCX + 16]

  MULSD  XMM0, XMM4
  MULSD  XMM1, XMM4
  MULSD  XMM2, XMM4
  MOVQ   XMM3, RAX              // xmm3 = 1.0

  MOVSD [RCX], XMM0
  MOVSD [RCX + 8], XMM1
  MOVSD [RCX + 16], XMM2
  MOVSD [RCX + 24], XMM3
  @Exit:
end;

{$IFDEF AVX2}
procedure AddVec4D(V1, V2: PVec4D); assembler;
asm
  .NOFRAME
  VMOVUPD YMM0, [RCX]
  VMOVUPD YMM1, [RDX]
  VADDPD  YMM0, YMM0, YMM1
  VMOVUPD [RCX], YMM0
  VZEROUPPER
end;
{$ELSE}
procedure AddVec4D(V1, V2: PVec4D); assembler;
asm
  .NOFRAME
  MOVUPD XMM0, [RCX]
  MOVUPD XMM1, [RCX + 16]
  MOVUPD XMM2, [RDX]
  MOVUPD XMM3, [RDX + 16]
  ADDPD  XMM0, XMM2
  ADDPD  XMM1, XMM3
  MOVUPD [RCX], XMM0
  MOVUPD [RCX + 16], XMM1
end;
{$ENDIF}

{$IFDEF AVX2}
procedure SubVec4D(V1, V2: PVec4D); assembler;
asm
  .NOFRAME
  VMOVUPD YMM0, [RCX]
  VMOVUPD YMM1, [RDX]
  VSUBPD  YMM0, YMM0, YMM1
  VMOVUPD [RCX], YMM0
  VZEROUPPER
end;
{$ELSE}
procedure SubVec4D(V1, V2: PVec4D); assembler;
asm
  .NOFRAME
  MOVUPD XMM0, [RCX]
  MOVUPD XMM1, [RCX + 16]
  MOVUPD XMM2, [RDX]
  MOVUPD XMM3, [RDX + 16]
  SUBPD  XMM0, XMM2
  SUBPD  XMM1, XMM3
  MOVUPD [RCX], XMM0
  MOVUPD [RCX + 16], XMM1
end;
{$ENDIF}

{$IFDEF AVX2}
procedure MulVec4D(V1, V2: PVec4D); assembler;   // Hadamard product
asm
  .NOFRAME
  VMOVUPD YMM0, [RCX]
  VMOVUPD YMM1, [RDX]
  VMULPD  YMM0, YMM0, YMM1
  VMOVUPD [RCX], YMM0
  VZEROUPPER
end;
{$ELSE}
procedure MulVec4D(V1, V2: PVec4D); assembler;   // Hadamard product
asm
  .NOFRAME
  MOVUPD XMM0, [RCX]
  MOVUPD XMM1, [RCX + 16]
  MOVUPD XMM2, [RDX]
  MOVUPD XMM3, [RDX + 16]
  MULPD  XMM0, XMM2
  MULPD  XMM1, XMM3
  MOVUPD [RCX], XMM0
  MOVUPD [RCX + 16], XMM1
end;
{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF AVX2}
function DotVec3D(V1, V2: PVec4D): Double; assembler;
asm
  .NOFRAME
  // RCX = @V1, RDX = @V2

  // 1. Fetch scalar components cleanly
  VMOVSD  xmm0, [RCX]       // X1
  VMOVSD  xmm1, [RCX + 8]   // Y1
  VMOVSD  xmm2, [RCX + 16]  // Z1

  // 2. Compute multiplications (SIGNED values remain in xmm0, xmm1, xmm2)
  VMULSD  xmm0, xmm0, [RDX]       // xmm0 = XProduct
  VMULSD  xmm1, xmm1, [RDX + 8]   // xmm1 = YProduct
  VMULSD  xmm2, xmm2, [RDX + 16]  // xmm2 = ZProduct

  // 3. Create absolute magnitude copies in xmm3, xmm4, xmm5 for sorting
  MOV     rax, $7FFFFFFFFFFFFFFF
  MOVQ    xmm5, rax
  VANDPD  xmm3, xmm0, xmm5   // xmm3 = AbsX
  VANDPD  xmm4, xmm1, xmm5   // xmm4 = AbsY
  VANDPD  xmm5, xmm2, xmm5   // xmm5 = AbsZ

  // 4. Exact replication of the Delphi 12 partial sorting tree
  // XOR-swap avoids needing a non-volatile temp register
  VUCOMISD xmm3, xmm4
  JBE     @SkipFirstSwap
  VXORPD  xmm3, xmm3, xmm4; VXORPD xmm4, xmm4, xmm3; VXORPD xmm3, xmm3, xmm4 // Swap absolute
  VXORPD  xmm0, xmm0, xmm1; VXORPD xmm1, xmm1, xmm0; VXORPD xmm0, xmm0, xmm1 // Swap signed
@SkipFirstSwap:

  VUCOMISD xmm4, xmm5
  JBE     @SkipSecondSwap
  VXORPD  xmm4, xmm4, xmm5; VXORPD xmm5, xmm5, xmm4; VXORPD xmm4, xmm4, xmm5 // Swap absolute
  VXORPD  xmm1, xmm1, xmm2; VXORPD xmm2, xmm2, xmm1; VXORPD xmm1, xmm1, xmm2 // Swap signed
@SkipSecondSwap:

  // 5. Check for absolute zero floor on the maximum magnitude slot (AbsZ)
  VXORPD  xmm3, xmm3, xmm3  // xmm3 = 0.0 (free: AbsMin, no longer needed after sort)
  VUCOMISD xmm5, xmm3
  JE      @ReturnZero

  // 6. Left-to-Right Equation Generation using SIGNED registers
  VDIVSD  xmm3, xmm0, xmm2   // XProduct / ZProduct
  VMULSD  xmm3, xmm3, xmm3   // Sqr(XProduct / ZProduct)

  MOV     rax, $3FF0000000000000 // Double 1.0
  MOVQ    xmm0, rax
  VADDSD  xmm0, xmm0, xmm3   // 1 + Sqr(XProduct / ZProduct)

  VDIVSD  xmm3, xmm1, xmm2   // YProduct / ZProduct
  VMULSD  xmm3, xmm3, xmm3   // Sqr(YProduct / ZProduct)

  VADDSD  xmm0, xmm0, xmm3   // Temp = (1 + Sqr) + Sqr

  // 7. Sequential Multiplication: Result = (Temp * ZProduct) * ZProduct
  VMULSD  xmm0, xmm0, xmm2
  VMULSD  xmm0, xmm0, xmm2
  JMP     @Exit

@ReturnZero:
  VXORPD  xmm0, xmm0, xmm0
@Exit:
  VZEROUPPER
end;
{$ELSE}
function DotVec3D(V1, V2: PVec4D): Double; assembler;
asm
  .NOFRAME
  // RCX = @V1, RDX = @V2

  // 1. Fetch raw variables into volatile registers
  MOVSD   xmm0, [RCX]       // X1
  MOVSD   xmm1, [RCX + 8]   // Y1
  MOVSD   xmm2, [RCX + 16]  // Z1

  // 2. Compute multiplications (These hold the true SIGNED products)
  MULSD   xmm0, [RDX]       // xmm0 = XProduct = X1 * X2
  MULSD   xmm1, [RDX + 8]   // xmm1 = YProduct = Y1 * Y2
  MULSD   xmm2, [RDX + 16]  // xmm2 = ZProduct = Z1 * Z2

  // 3. Create absolute magnitude copies purely for sorting comparisons
  MOV     rax, $7FFFFFFFFFFFFFFF
  MOVQ    xmm5, rax         // Sign bit mask

  MOVAPD  xmm3, xmm0
  ANDPD   xmm3, xmm5        // xmm3 = AbsX = Abs(XProduct)
  MOVAPD  xmm4, xmm1
  ANDPD   xmm4, xmm5        // xmm4 = AbsY = Abs(YProduct)
  ANDPD   xmm5, xmm2        // xmm5 = AbsZ = mask AND ZProduct (mask still in xmm5)

  // 4. Exact replication of the Delphi 12 partial sorting tree
  // Swap BOTH absolute and signed registers; XOR-swap avoids needing a temp register
  COMISD  xmm3, xmm4        // if AbsX > AbsY then
  JBE     @SkipFirstSwap
  XORPD   xmm3, xmm4; XORPD xmm4, xmm3; XORPD xmm3, xmm4 // Swap absolute values
  XORPD   xmm0, xmm1; XORPD xmm1, xmm0; XORPD xmm0, xmm1 // Swap signed values
@SkipFirstSwap:

  COMISD  xmm4, xmm5        // if AbsY > AbsZ then
  JBE     @SkipSecondSwap
  XORPD   xmm4, xmm5; XORPD xmm5, xmm4; XORPD xmm4, xmm5 // Swap absolute values
  XORPD   xmm1, xmm2; XORPD xmm2, xmm1; XORPD xmm1, xmm2 // Swap signed values
@SkipSecondSwap:

  // 5. Zero check for the largest absolute element (AbsZ)
  XORPD   xmm3, xmm3        // xmm3 = 0.0 (free: AbsMin, no longer needed after sort)
  UCOMISD xmm5, xmm3        // if AbsZ = 0 then
  JE      @ReturnZero

  // 6. Left-to-Right Equation Accumulation using the SIGNED registers (xmm0, xmm1, xmm2)
  // Step A: XProduct / ZProduct
  MOVAPD  xmm3, xmm0
  DIVSD   xmm3, xmm2        // xmm3 = XProduct / ZProduct
  MULSD   xmm3, xmm3        // xmm3 = Sqr(XProduct / ZProduct)

  // Accumulate: 1.0 + Sqr(...)
  MOV     rax, $3FF0000000000000 // Double 1.0
  MOVQ    xmm0, rax
  ADDSD   xmm0, xmm3        // xmm0 = 1 + Sqr(XProduct / ZProduct)

  // Step B: YProduct / ZProduct
  MOVAPD  xmm3, xmm1
  DIVSD   xmm3, xmm2        // xmm3 = YProduct / ZProduct
  MULSD   xmm3, xmm3        // xmm3 = Sqr(YProduct / ZProduct)

  // Complete addition: Temp = (1 + Sqr) + Sqr
  ADDSD   xmm0, xmm3

  // 7. Sequential Multiplication: Result = (Temp * ZProduct) * ZProduct
  MULSD   xmm0, xmm2
  MULSD   xmm0, xmm2
  JMP     @Exit

@ReturnZero:
  XORPD   xmm0, xmm0        // Result := 0
@Exit:
end;
{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF AVX2}
procedure ScalarMulVec3D(V: PVec4D; S: Double); assembler;   // 3D: scales X/Y/Z, preserves W
asm
  .NOFRAME
  VUNPCKLPD xmm1, xmm1, xmm1
  VMOVUPD   xmm2, [RCX]       // xmm2 = [V.Y, V.X]
  VMOVSD    xmm3, [RCX + 16]  // xmm3 = [0.0, V.Z]
  VMULPD    xmm2, xmm2, xmm1  // xmm2 = [V.Y * Scalar, V.X * Scalar]
  VMULSD    xmm3, xmm3, xmm1  // xmm3 = [0.0, V.Z * Scalar]
  VMOVUPD   [RCX], xmm2       // Overwrites X and Y
  VMOVSD    [RCX + 16], xmm3  // Overwrites Z
end;
{$ELSE}
procedure ScalarMulVec3D(V: PVec4D; S: Double); assembler;
asm
  .NOFRAME
  UNPCKLPD xmm1, xmm1
  MOVUPD   xmm2, [RCX]       // xmm2 = [V.Y, V.X]
  MOVSD    xmm3, [RCX + 16]  // xmm3 = [0.0, V.Z]
  MULPD    xmm2, xmm1        // xmm2 = [V.Y * Scalar, V.X * Scalar]
  MULSD    xmm3, xmm1        // xmm3 = [0.0, V.Z * Scalar]
  MOVUPD   [RCX], xmm2       // Overwrites X and Y
  MOVSD    [RCX + 16], xmm3  // Overwrites Z
end;
{$ENDIF}

{$IFDEF AVX2}
procedure ScalarMulVec4D(V: PVec4D; S: Double); assembler;   // 4D: scales X/Y/Z/W (matches the * operator)
asm
  .NOFRAME
  VPBROADCASTQ ymm1, xmm1     // ymm1 = [S, S, S, S]
  VMULPD    ymm0, ymm1, [RCX] // [W*S, Z*S, Y*S, X*S]
  VMOVUPD   [RCX], ymm0
  VZEROUPPER
end;
{$ELSE}
procedure ScalarMulVec4D(V: PVec4D; S: Double); assembler;   // 4D: scales X/Y/Z/W (matches the * operator)
asm
  .NOFRAME
  UNPCKLPD xmm1, xmm1        // xmm1 = [S, S]
  MOVUPD   xmm2, [RCX]       // [V.Y, V.X]
  MOVUPD   xmm3, [RCX + 16]  // [V.W, V.Z]
  MULPD    xmm2, xmm1        // [V.Y * S, V.X * S]
  MULPD    xmm3, xmm1        // [V.W * S, V.Z * S]
  MOVUPD   [RCX], xmm2       // Overwrites X and Y
  MOVUPD   [RCX + 16], xmm3  // Overwrites Z and W
end;
{$ENDIF}

{$IFDEF AVX2}
procedure AddVec3D(V1, V2: PVec4D); assembler;
asm
  .NOFRAME
  VMOVUPD YMM0, [RCX]
  VMOVUPD YMM1, [RDX]
  VADDPD  YMM2, YMM0, YMM1
  VEXTRACTF128 XMM0, YMM2, 0
  VMOVUPD [RCX], XMM0
  VEXTRACTF128 XMM1, YMM2, 1
  MOVSD [RCX + 16], XMM1
  VZEROUPPER
end;
{$ELSE}
procedure AddVec3D(V1, V2: PVec4D); assembler;
asm
  .NOFRAME
  MOVUPD XMM0, [RCX]
  MOVUPD XMM1, [RDX]
  ADDPD  XMM0, XMM1
  MOVUPD [RCX], XMM0
  MOVSD  XMM2, [RCX + 16]
  ADDSD  XMM2, [RDX + 16]
  MOVSD  [RCX + 16], XMM2
end;
{$ENDIF}

{$IFDEF AVX2}
procedure SubVec3D(V1, V2: PVec4D); assembler;
asm
  .NOFRAME
  VMOVUPD YMM0, [RCX]
  VMOVUPD YMM1, [RDX]
  VSUBPD  YMM2, YMM0, YMM1
  VEXTRACTF128 XMM0, YMM2, 0
  VMOVUPD [RCX], XMM0
  VEXTRACTF128 XMM1, YMM2, 1
  MOVSD [RCX + 16], XMM1
  VZEROUPPER
end;
{$ELSE}
procedure SubVec3D(V1, V2: PVec4D); assembler;
asm
  .NOFRAME
  MOVUPD XMM0, [RCX]
  MOVUPD XMM1, [RDX]
  SUBPD  XMM0, XMM1
  MOVUPD [RCX], XMM0
  MOVSD  XMM2, [RCX + 16]
  SUBSD  XMM2, [RDX + 16]
  MOVSD  [RCX + 16], XMM2
end;
{$ENDIF}

//------------------------------------------------------------------------------

function GetIdentityMat4D: TMat4D;
begin
  FillChar(Result, SizeOf(TMat4D), 0);
  Result.ci00 := $3FF0000000000000;
  Result.ci11 := $3FF0000000000000;
  Result.ci22 := $3FF0000000000000;
  Result.ci33 := $3FF0000000000000;
end;

function GetRotMat4D(Angle, AxisX, AxisY, AxisZ: Double): TMat4D;
var
  len, invLen, x, y, z, s, c, omc: Double;
  xx, yy, zz, xy, xz, yz, xs, ys, zs: Double;
begin
  len := Hypot(AxisX, AxisY, AxisZ);
  if len < 1e-12 then
  begin
    FillChar(Result, SizeOf(TMat4D), 0);
    Result.ci00 := $3FF0000000000000;
    Result.ci11 := $3FF0000000000000;
    Result.ci22 := $3FF0000000000000;
    Result.ci33 := $3FF0000000000000;
  end
  else
  begin
   invLen := 1.0 / len;
   x := AxisX * invLen;
   y := AxisY * invLen;
   z := AxisZ * invLen;

   SinCos(Angle, s, c);
   omc := 1.0 - c;

   xx := x * x; yy := y * y; zz := z * z;
   xy := x * y; xz := x * z; yz := y * z;
   xs := x * s; ys := y * s; zs := z * s;

  // Row 0
   Result.cf00 := xx * omc + c;
   Result.cf01 := xy * omc + zs;
   Result.cf02 := xz * omc - ys;
   Result.cf03 := 0.0;

  // Row 1
   Result.cf10 := xy * omc - zs;
   Result.cf11 := yy * omc + c;
   Result.cf12 := yz * omc + xs;
   Result.cf13 := 0.0;

  // Row 2
   Result.cf20 := xz * omc + ys;
   Result.cf21 := yz * omc - xs;
   Result.cf22 := zz * omc + c;
   Result.cf23 := 0.0;

  // Row 3
   Result.cf30 := 0.0;
   Result.cf31 := 0.0;
   Result.cf32 := 0.0;
   Result.cf33 := 1.0;
  end;
end;

procedure NormQuat4D(Q: PVec4D);
var
  Mag, InvMag: Double;
begin
  Mag := Hypot(Q^.I, Q^.J, Q^.K, Q^.R);
  if Mag = 0.0 then FillChar(Q^, SizeOf(TVec4D), 0) else
   begin
    InvMag := 1.0 / Mag;
    Q^.I := Q^.I * InvMag;
    Q^.J := Q^.J * InvMag;
    Q^.K := Q^.K * InvMag;
    Q^.R := Q^.R * InvMag;
   end;
end;

function GetIdentityVersor4D: TVec4D;
begin
  FillChar(Result, SizeOf(TVec4D), 0);
  Result.R := 1.0;
end;

function GetVersor4D(Angle, AxisX, AxisY, AxisZ: Double): TVec4D;
var
  SinHalf, CosHalf: Double;
  Len, InvLen: Double;
begin
  SinCos(0.5*Angle, SinHalf, CosHalf);
  Len := Hypot(AxisX, AxisY, AxisZ);
  if Len = 0.0 then
   begin
    FillChar(Result, SizeOf(TVec4D)-SizeOf(Double), 0);
    Result.ci3:=$3FF0000000000000;
   end
   else
   begin
    InvLen := 1.0 / Len;
    Result.I := (AxisX * InvLen) * SinHalf;
    Result.J := (AxisY * InvLen) * SinHalf;
    Result.K := (AxisZ * InvLen) * SinHalf;
    Result.R := CosHalf;
   end;
end;

// ============================================================================
// SSE2 - UNIFORM VECTOR OPERATIONS (Vec)
// ============================================================================

procedure NormVec3D(V: PVec4D); assembler;
asm
  .NOFRAME
  // RCX = @V (Source Pointer & Destination Pointer)

  // 1. Fetch raw spatial coordinates into volatile registers
  MOVSD   xmm0, [RCX]       // xmm0 = TempX = X
  MOVSD   xmm1, [RCX + 8]   // xmm1 = TempY = Y
  MOVSD   xmm2, [RCX + 16]  // xmm2 = TempZ = Z

  // 2. Strip sign bits explicitly via a 64-bit integer mask
  MOV     rax, $7FFFFFFFFFFFFFFF
  MOVQ    xmm4, rax         // Sign bit mask
  ANDPD   xmm0, xmm4        // TempX = Abs(X)
  ANDPD   xmm1, xmm4        // TempY = Abs(Y)
  ANDPD   xmm2, xmm4        // TempZ = Abs(Z)

  // 3. Exact replication of the Delphi 12 partial sorting tree
  COMISD  xmm0, xmm1        // if TempX > TempY then
  JBE     @SkipFirstSwap
  MOVAPD  xmm3, xmm0        // Swap TempX and TempY
  MOVAPD  xmm0, xmm1
  MOVAPD  xmm1, xmm3
@SkipFirstSwap:

  COMISD  xmm1, xmm2        // if TempY > TempZ then
  JBE     @SkipSecondSwap
  MOVAPD  xmm3, xmm1        // Swap TempY and TempZ
  MOVAPD  xmm1, xmm2
  MOVAPD  xmm2, xmm3
@SkipSecondSwap:

  // 4. Zero check for TempZ (If Max element is 0, skip calculations)
  XORPD   xmm3, xmm3
  UCOMISD xmm2, xmm3        // if TempZ = 0 then
  JE      @Exit

  // 5. Left-to-Right Equation Accumulation to find the exact Length:
  // Step A: TempX / TempZ
  MOVAPD  xmm3, xmm0
  DIVSD   xmm3, xmm2        // xmm3 = TempX / TempZ
  MULSD   xmm3, xmm3        // xmm3 = Sqr(TempX / TempZ)

  // Accumulate: 1.0 + Sqr(TempX / TempZ)
  MOV     rax, $3FF0000000000000 // Double 1.0
  MOVQ    xmm0, rax
  ADDSD   xmm0, xmm3        // xmm0 = 1 + Sqr(TempX / TempZ)

  // Step B: TempY / TempZ
  MOVAPD  xmm3, xmm1
  DIVSD   xmm3, xmm2        // xmm3 = TempY / TempZ
  MULSD   xmm3, xmm3        // xmm3 = Sqr(TempY / TempZ)

  // Complete addition: (1 + Sqr) + Sqr
  ADDSD   xmm0, xmm3

  // Extract Sqrt and final scale to get true length in xmm0
  SQRTSD  xmm0, xmm0        // Sqrt(...)
  MULSD   xmm0, xmm2        // xmm0 = Length = TempZ * Sqrt(...)

  // 6. Compute Inverse Length: xmm0 = 1.0 / Length
  MOV     rax, $3FF0000000000000
  MOVQ    xmm3, rax         // xmm3 = 1.0
  DIVSD   xmm3, xmm0        // xmm3 = InvLength = 1.0 / Length

  // 7. Reload original raw components from memory pointer to scale them
  MOVSD   xmm0, [RCX]       // Raw X
  MOVSD   xmm1, [RCX + 8]   // Raw Y
  MOVSD   xmm2, [RCX + 16]  // Raw Z
  XORPD   xmm4, xmm4        // W component = 0.0

  // 8. Multiply through by the inverse length factor
  MULSD   xmm0, xmm3        // Normalized X
  MULSD   xmm1, xmm3        // Normalized Y
  MULSD   xmm2, xmm3        // Normalized Z

  // 9. Write the final fields back to memory
  MOVSD   [RCX], xmm0
  MOVSD   [RCX + 8], xmm1
  MOVSD   [RCX + 16], xmm2
  //MOVSD   [RCX + 24], xmm4  // Enforce homogeneous vector rule W = 0.0
@Exit:
end;

function LengthVec3D(V: PVec4D): Double; assembler;
asm
  .NOFRAME
  // RCX = @V

  // 1. Fetch raw variables and apply absolute value masking
  MOVSD   xmm0, [RCX]       // xmm0 = TempX = X
  MOVSD   xmm1, [RCX + 8]   // xmm1 = TempY = Y
  MOVSD   xmm2, [RCX + 16]  // xmm2 = TempZ = Z

  MOV     rax, $7FFFFFFFFFFFFFFF
  MOVQ    xmm4, rax         // Sign bit mask
  ANDPD   xmm0, xmm4        // TempX = Abs(X)
  ANDPD   xmm1, xmm4        // TempY = Abs(Y)
  ANDPD   xmm2, xmm4        // TempZ = Abs(Z)

  // 2. Exact replication of the Delphi 12 partial sorting sorting tree
  COMISD  xmm0, xmm1        // if TempX > TempY then
  JBE     @SkipFirstSwap
  MOVAPD  xmm3, xmm0        // Swap TempX and TempY
  MOVAPD  xmm0, xmm1
  MOVAPD  xmm1, xmm3
@SkipFirstSwap:

  COMISD  xmm1, xmm2        // if TempY > TempZ then
  JBE     @SkipSecondSwap
  MOVAPD  xmm3, xmm1        // Swap TempY and TempZ
  MOVAPD  xmm1, xmm2
  MOVAPD  xmm2, xmm3
@SkipSecondSwap:

  // 3. Zero check for TempZ
  XORPD   xmm3, xmm3
  UCOMISD xmm2, xmm3        // if TempZ = 0 then
  JE      @ReturnZero

  // 4. Exact Left-to-Right Equation Accumulation:
  // Step A: TempX / TempZ
  MOVAPD  xmm3, xmm0
  DIVSD   xmm3, xmm2        // xmm3 = TempX / TempZ
  MULSD   xmm3, xmm3        // xmm3 = Sqr(TempX / TempZ)

  // Accumulate: 1.0 + Sqr(TempX / TempZ)
  MOV     rax, $3FF0000000000000 // Double 1.0
  MOVQ    xmm0, rax
  ADDSD   xmm0, xmm3        // xmm0 = 1 + Sqr(TempX / TempZ)

  // Step B: TempY / TempZ
  MOVAPD  xmm3, xmm1
  DIVSD   xmm3, xmm2        // xmm3 = TempY / TempZ
  MULSD   xmm3, xmm3        // xmm3 = Sqr(TempY / TempZ)

  // Complete addition: (1 + Sqr(TempX / TempZ)) + Sqr(TempY / TempZ)
  ADDSD   xmm0, xmm3

  // 5. Final Root and Scaling
  SQRTSD  xmm0, xmm0        // Sqrt(...)
  MULSD   xmm0, xmm2        // TempZ * Sqrt(...)
  JMP     @Exit

@ReturnZero:
  XORPD   xmm0, xmm0        // Result := 0
@Exit:
end;

function SqrLengthVec3D(V: PVec4D): Double; assembler;
asm
  .NOFRAME
  // RCX = @V

  // 1. Fetch raw variables and apply absolute value masking
  MOVSD   xmm0, [RCX]       // xmm0 = TempX = X
  MOVSD   xmm1, [RCX + 8]   // xmm1 = TempY = Y
  MOVSD   xmm2, [RCX + 16]  // xmm2 = TempZ = Z

  MOV     rax, $7FFFFFFFFFFFFFFF
  MOVQ    xmm4, rax         // Sign bit mask
  ANDPD   xmm0, xmm4        // TempX = Abs(X)
  ANDPD   xmm1, xmm4        // TempY = Abs(Y)
  ANDPD   xmm2, xmm4        // TempZ = Abs(Z)

  // 2. Exact replication of the Delphi 12 partial sorting tree
  COMISD  xmm0, xmm1        // if TempX > TempY then
  JBE     @SkipFirstSwap
  MOVAPD  xmm3, xmm0        // Swap TempX and TempY
  MOVAPD  xmm0, xmm1
  MOVAPD  xmm1, xmm3
@SkipFirstSwap:

  COMISD  xmm1, xmm2        // if TempY > TempZ then
  JBE     @SkipSecondSwap
  MOVAPD  xmm3, xmm1        // Swap TempY and TempZ
  MOVAPD  xmm1, xmm2
  MOVAPD  xmm2, xmm3
@SkipSecondSwap:

  // 3. Zero check for TempZ
  XORPD   xmm3, xmm3
  UCOMISD xmm2, xmm3        // if TempZ = 0 then
  JE      @ReturnZero

  // 4. Exact Left-to-Right Equation Accumulation:
  // Step A: TempX / TempZ
  MOVAPD  xmm3, xmm0
  DIVSD   xmm3, xmm2        // xmm3 = TempX / TempZ
  MULSD   xmm3, xmm3        // xmm3 = Sqr(TempX / TempZ)

  // Accumulate: 1.0 + Sqr(TempX / TempZ)
  MOV     rax, $3FF0000000000000 // Double 1.0
  MOVQ    xmm0, rax
  ADDSD   xmm0, xmm3        // xmm0 = 1 + Sqr(TempX / TempZ)

  // Step B: TempY / TempZ
  MOVAPD  xmm3, xmm1
  DIVSD   xmm3, xmm2        // xmm3 = TempY / TempZ
  MULSD   xmm3, xmm3        // xmm3 = Sqr(TempY / TempZ)

  // Complete addition: (1 + Sqr(TempX / TempZ)) + Sqr(TempY / TempZ)
  ADDSD   xmm0, xmm3

  // 5. Final Scaling for SqrLength: Multiply by TempZ^2
  MULSD   xmm0, xmm2        // xmm0 = InsideRoot * TempZ
  MULSD   xmm0, xmm2        // xmm0 = InsideRoot * TempZ * TempZ
  JMP     @Exit

@ReturnZero:
  XORPD   xmm0, xmm0        // Result := 0
@Exit:
end;

procedure CrossVec3D(V1, V2: PVec4D); assembler;
asm
  .NOFRAME
  // RCX = @V1 (Source and Destination)
  // RDX = @V2 (Modifier)

  // 1. Load V1's coordinates into volatile scratch registers
  MOVSD xmm0, [RCX]       // xmm0 = V1.X
  MOVSD xmm1, [RCX + 8]   // xmm1 = V1.Y
  MOVSD xmm2, [RCX + 16]  // xmm2 = V1.Z

  // 2. Compute X component: (V1.Y * V2.Z) - (V1.Z * V2.Y)
  // We use xmm3 and xmm4 as temporary scratch areas
  MOVSD xmm3, xmm1
  MULSD xmm3, [RDX + 16]  // xmm3 = V1.Y * V2.Z
  MOVSD xmm4, xmm2
  MULSD xmm4, [RDX + 8]   // xmm4 = V1.Z * V2.Y
  SUBSD xmm3, xmm4        // xmm3 = X_Result

  // 3. Compute Y component: (V1.Z * V2.X) - (V1.X * V2.Z)
  MOVSD xmm4, xmm2
  MULSD xmm4, [RDX]       // xmm4 = V1.Z * V2.X
  MOVSD xmm5, xmm0
  MULSD xmm5, [RDX + 16]  // xmm5 = V1.X * V2.Z
  SUBSD xmm4, xmm5        // xmm4 = Y_Result

  // 4. Compute Z component: (V1.X * V2.Y) - (V1.Y * V2.X)
  // xmm2 is no longer needed, so we can overwrite it safely
  MULSD xmm0, [RDX + 8]   // xmm0 = V1.X * V2.Y
  MULSD xmm1, [RDX]       // xmm1 = V1.Y * V2.X
  SUBSD xmm0, xmm1        // xmm0 = Z_Result

  // 5. Explicitly clear a register for W = 0.0
  //XORPD xmm1, xmm1        // xmm1 = 0.0

  // 6. Write the final calculated fields back into V1 memory
  MOVSD [RCX], xmm3       // Overwrite V1.X
  MOVSD [RCX + 8], xmm4   // Overwrite V1.Y
  MOVSD [RCX + 16], xmm0  // Overwrite V1.Z
  //MOVSD [RCX + 24], xmm1  // Overwrite V1.W
end;

//------------------------------------------------------------------------------

{$IFNDEF AVX2}
procedure MulMat4D(M1, M2: PMat4D); assembler;
var
  Temp: TMat4D;
asm
  // Windows x64: RCX = M1, RDX = M2
  lea     rax, [Temp]           // RAX = Address of Temp local frame
  xor     r8, r8                // R8  = Row iteration loop offset tracking

@LoopRowsSSE2:
  // Duplicate X and Y components from M1.V[I]
  movupd  xmm0, [rcx + r8]       // xmm0 = [ Y, X ]
  movapd  xmm1, xmm0
  unpcklpd xmm1, xmm1            // xmm1 = [ X, X ]
  movapd  xmm2, xmm0
  unpckhpd xmm2, xmm2            // xmm2 = [ Y, Y ]

  // Duplicate Z and W components from M1.V[I]
  movupd  xmm0, [rcx + r8 + 16]  // xmm0 = [ W, Z ]
  movapd  xmm3, xmm0
  unpcklpd xmm3, xmm3            // xmm3 = [ Z, Z ]
  movapd  xmm4, xmm0
  unpckhpd xmm4, xmm4            // xmm4 = [ W, W ]

  // Accumulate Low Half [Y, X]
  movupd  xmm5, [rdx + 0]        // Row 0 Low [Y, X]
  mulpd   xmm5, xmm1             // X * M2.Row0.Low
  movupd  xmm0, [rdx + 32]       // Row 1 Low [Y, X]
  mulpd   xmm0, xmm2             // Y * M2.Row1.Low
  addpd   xmm5, xmm0
  movupd  xmm0, [rdx + 64]       // Row 2 Low [Y, X]
  mulpd   xmm0, xmm3             // Z * M2.Row2.Low
  addpd   xmm5, xmm0
  movupd  xmm0, [rdx + 96]       // Row 3 Low [Y, X]
  mulpd   xmm0, xmm4             // W * M2.Row3.Low
  addpd   xmm5, xmm0
  movupd  [rax + r8], xmm5       // Save Low Half to Temp

  // Accumulate High Half [W, Z]
  movupd  xmm5, [rdx + 16]       // Row 0 High [W, Z]
  mulpd   xmm5, xmm1             // X * M2.Row0.High
  movupd  xmm0, [rdx + 48]       // Row 1 High [W, Z]
  mulpd   xmm0, xmm2             // Y * M2.Row1.High
  addpd   xmm5, xmm0
  movupd  xmm0, [rdx + 80]       // Row 2 High [W, Z]
  mulpd   xmm0, xmm3             // Z * M2.Row2.High
  addpd   xmm5, xmm0
  movupd  xmm0, [rdx + 112]      // Row 3 High [W, Z]
  mulpd   xmm0, xmm4             // W * M2.Row3.High
  addpd   xmm5, xmm0
  movupd  [rax + r8 + 16], xmm5  // Save High Half to Temp

  // Advance loop tracking
  add     r8, 32
  cmp     r8, 128
  jl      @LoopRowsSSE2

  // --- COMMIT RESULTS FROM TEMP STORAGE BACK TO M1 ---
  movupd  xmm0, [rax + 0]
  movupd  xmm1, [rax + 16]
  movupd  xmm2, [rax + 32]
  movupd  xmm3, [rax + 48]
  movupd  [rcx + 0], xmm0
  movupd  [rcx + 16], xmm1
  movupd  [rcx + 32], xmm2
  movupd  [rcx + 48], xmm3

  movupd  xmm0, [rax + 64]
  movupd  xmm1, [rax + 80]
  movupd  xmm2, [rax + 96]
  movupd  xmm3, [rax + 112]
  movupd  [rcx + 64], xmm0
  movupd  [rcx + 80], xmm1
  movupd  [rcx + 96], xmm2
  movupd  [rcx + 112], xmm3
end;

procedure TransformVec4D(V: PVec4D; M: PMat4D); assembler;
var
  Temp: TVec4D;
asm
  // Windows x64 ABI: RCX = Pointer V, RDX = Pointer M
  lea     rax, [Temp]           // RAX = Pointer to local stack variable Temp

  // 1. Duplicate X and Y components from V into 128-bit registers
  movupd  xmm0, [rcx]           // xmm0 = [ V.Y, V.X ]
  movapd  xmm1, xmm0
  unpcklpd xmm1, xmm1            // xmm1 = [ V.X, V.X ]
  movapd  xmm2, xmm0
  unpckhpd xmm2, xmm2            // xmm2 = [ V.Y, V.Y ]

  // 2. Duplicate Z and W components from V into 128-bit registers
  movupd  xmm0, [rcx + 16]       // xmm0 = [ V.W, V.Z ]
  movapd  xmm3, xmm0
  unpcklpd xmm3, xmm3            // xmm3 = [ V.Z, V.Z ]
  movapd  xmm4, xmm0
  unpckhpd xmm4, xmm4            // xmm4 = [ V.W, V.W ]

  // 3. Accumulate the Low Half [Y, X] of the output vector
  movupd  xmm5, [rdx + 0]        // M.Row0.Low [Y, X]
  mulpd   xmm5, xmm1             // V.X * M.Row0.Low
  movupd  xmm0, [rdx + 32]       // M.Row1.Low [Y, X]
  mulpd   xmm0, xmm2             // V.Y * M.Row1.Low
  addpd   xmm5, xmm0
  movupd  xmm0, [rdx + 64]       // M.Row2.Low [Y, X]
  mulpd   xmm0, xmm3             // V.Z * M.Row2.Low
  addpd   xmm5, xmm0
  movupd  xmm0, [rdx + 96]       // M.Row3.Low [Y, X]
  mulpd   xmm0, xmm4             // V.W * M.Row3.Low
  addpd   xmm5, xmm0
  movupd  [rax], xmm5            // Save calculated low half to Temp

  // 4. Accumulate the High Half [W, Z] of the output vector
  movupd  xmm5, [rdx + 16]       // M.Row0.High [W, Z]
  mulpd   xmm5, xmm1             // V.X * M.Row0.High
  movupd  xmm0, [rdx + 48]       // M.Row1.High [W, Z]
  mulpd   xmm0, xmm2             // V.Y * M.Row1.High
  addpd   xmm5, xmm0
  movupd  xmm0, [rdx + 80]       // M.Row2.High [W, Z]
  mulpd   xmm0, xmm3             // V.Z * M.Row2.High
  addpd   xmm5, xmm0
  movupd  xmm0, [rdx + 112]      // M.Row3.High [W, Z]
  mulpd   xmm0, xmm4             // V.W * M.Row3.High
  addpd   xmm5, xmm0
  movupd  [rax + 16], xmm5       // Save calculated high half to Temp

  // 5. Commit Temp back into original pointer V
  movupd  xmm0, [rax]
  movupd  xmm1, [rax + 16]
  movupd  [rcx], xmm0
  movupd  [rcx + 16], xmm1
end;

//-------------------------------------------------------------------------------

procedure MulQuat4D(Q1, Q2: PVec4D); assembler;
asm
  .NOFRAME
  // RCX = Q1 [X1, Y1, Z1, W1] (Destination/Source)
  // RDX = Q2 [X2, Y2, Z2, W2] (Source — never written)
  // Uses only volatile registers: xmm0-xmm5
  // Q1 is re-read from [rcx] as needed; it is not overwritten until the final commit

  // Cache sign mask in xmm5 once; all five sign applications derive from it
  pcmpeqd  xmm5, xmm5
  psllq    xmm5, 63             // xmm5 = [-0.0, -0.0]

  // ==========================================================
  // TRACK A: COMPUTE LOW CHANNELS [X3, Y3] -> Result in XMM1
  // ==========================================================

  // Term 1: W1 * [X2, Y2]  (signs +,+)
  movupd   xmm1, [rcx + 16]     // xmm1 = [Z1, W1]
  unpckhpd xmm1, xmm1           // xmm1 = [W1, W1]
  mulpd    xmm1, [rdx]          // xmm1 = [W1*X2, W1*Y2]

  // Term 2: X1 * [W2, Z2]  signs (+,-) -> [X1*W2, -X1*Z2]
  movupd   xmm2, [rcx]          // xmm2 = [X1, Y1]
  unpcklpd xmm2, xmm2           // xmm2 = [X1, X1]
  movupd   xmm3, [rdx + 16]     // xmm3 = [Z2, W2]
  shufpd   xmm3, xmm3, $01      // xmm3 = [W2, Z2]
  mulpd    xmm2, xmm3           // xmm2 = [X1*W2, X1*Z2]
  movapd   xmm3, xmm5           // xmm3 = [-0.0, -0.0]
  pslldq   xmm3, 8              // xmm3 = [0.0, -0.0]  (negate high lane only)
  xorpd    xmm2, xmm3           // xmm2 = [X1*W2, -X1*Z2]
  addpd    xmm1, xmm2

  // Term 3: Y1 * [Z2, W2]  (signs +,+)
  movupd   xmm2, [rcx]          // xmm2 = [X1, Y1]
  unpckhpd xmm2, xmm2           // xmm2 = [Y1, Y1]
  mulpd    xmm2, [rdx + 16]     // xmm2 = [Y1*Z2, Y1*W2]
  addpd    xmm1, xmm2

  // Term 4: Z1 * [Y2, X2]  signs (-,+) -> [-Z1*Y2, Z1*X2]
  movupd   xmm2, [rcx + 16]     // xmm2 = [Z1, W1]
  unpcklpd xmm2, xmm2           // xmm2 = [Z1, Z1]
  movupd   xmm3, [rdx]          // xmm3 = [X2, Y2]
  shufpd   xmm3, xmm3, $01      // xmm3 = [Y2, X2]
  mulpd    xmm2, xmm3           // xmm2 = [Z1*Y2, Z1*X2]
  movapd   xmm3, xmm5           // xmm3 = [-0.0, -0.0]
  psrldq   xmm3, 8              // xmm3 = [-0.0, 0.0]  (negate low lane only)
  xorpd    xmm2, xmm3           // xmm2 = [-Z1*Y2, Z1*X2]
  addpd    xmm1, xmm2           // xmm1 = final [X3, Y3]

  // ==========================================================
  // TRACK B: COMPUTE HIGH CHANNELS [Z3, W3] -> Result in XMM0
  // ==========================================================

  // Term 1: W1 * [Z2, W2]  (signs +,+)
  movupd   xmm0, [rcx + 16]     // xmm0 = [Z1, W1]
  unpckhpd xmm0, xmm0           // xmm0 = [W1, W1]
  mulpd    xmm0, [rdx + 16]     // xmm0 = [W1*Z2, W1*W2]

  // Term 2: X1 * [Y2, X2]  signs (+,-) -> [X1*Y2, -X1*X2]
  movupd   xmm2, [rcx]          // xmm2 = [X1, Y1]
  unpcklpd xmm2, xmm2           // xmm2 = [X1, X1]
  movupd   xmm3, [rdx]          // xmm3 = [X2, Y2]
  shufpd   xmm3, xmm3, $01      // xmm3 = [Y2, X2]
  mulpd    xmm2, xmm3           // xmm2 = [X1*Y2, X1*X2]
  movapd   xmm3, xmm5           // xmm3 = [-0.0, -0.0]
  pslldq   xmm3, 8              // xmm3 = [0.0, -0.0]
  xorpd    xmm2, xmm3           // xmm2 = [X1*Y2, -X1*X2]
  addpd    xmm0, xmm2

  // Term 3: Y1 * [X2, Y2]  (signs -,-) -> [-Y1*X2, -Y1*Y2]
  movupd   xmm2, [rcx]          // xmm2 = [X1, Y1]
  unpckhpd xmm2, xmm2           // xmm2 = [Y1, Y1]
  mulpd    xmm2, [rdx]          // xmm2 = [Y1*X2, Y1*Y2]
  xorpd    xmm2, xmm5           // xmm2 = [-Y1*X2, -Y1*Y2]  (apply cached mask directly)
  addpd    xmm0, xmm2

  // Term 4: Z1 * [W2, Z2]  signs (+,-) -> [Z1*W2, -Z1*Z2]
  movupd   xmm2, [rcx + 16]     // xmm2 = [Z1, W1]
  unpcklpd xmm2, xmm2           // xmm2 = [Z1, Z1]
  movupd   xmm3, [rdx + 16]     // xmm3 = [Z2, W2]
  shufpd   xmm3, xmm3, $01      // xmm3 = [W2, Z2]
  mulpd    xmm2, xmm3           // xmm2 = [Z1*W2, Z1*Z2]
  movapd   xmm3, xmm5           // xmm3 = [-0.0, -0.0]
  pslldq   xmm3, 8              // xmm3 = [0.0, -0.0]
  xorpd    xmm2, xmm3           // xmm2 = [Z1*W2, -Z1*Z2]
  addpd    xmm0, xmm2           // xmm0 = final [Z3, W3]

  // Commit
  movupd   [rcx], xmm1          // Write [X3, Y3]
  movupd   [rcx + 16], xmm0     // Write [Z3, W3]
end;

procedure TransformQuat4D(Quat, Versor: PVec4D); assembler;
asm
  .NOFRAME
  // RCX = Quat   [Qx, Qy, Qz, Qw]  in-place (W not modified)
  // RDX = Versor [vi, vj, vk, vr]   read-only
  //
  // Pure scalar SSE2 — no packing or shuffles; all data dependencies are short.
  // Phase 1: compute t = 2*(V×Q) into XMM0=tx, XMM1=ty, XMM2=tz
  // Phase 2: for each result component compute c_i and store immediately

  // tx = 2*(vj*Qz - vk*Qy)
  MOVSD  XMM0, [RDX + 8]           // vj
  MULSD  XMM0, [RCX + 16]          // vj*Qz
  MOVSD  XMM4, [RDX + 16]          // vk
  MULSD  XMM4, [RCX + 8]           // vk*Qy
  SUBSD  XMM0, XMM4                // vj*Qz - vk*Qy
  ADDSD  XMM0, XMM0                // tx

  // ty = 2*(vk*Qx - vi*Qz)
  MOVSD  XMM1, [RDX + 16]          // vk
  MULSD  XMM1, [RCX]               // vk*Qx
  MOVSD  XMM4, [RDX]               // vi
  MULSD  XMM4, [RCX + 16]          // vi*Qz
  SUBSD  XMM1, XMM4                // vk*Qx - vi*Qz
  ADDSD  XMM1, XMM1                // ty

  // tz = 2*(vi*Qy - vj*Qx)
  MOVSD  XMM2, [RDX]               // vi
  MULSD  XMM2, [RCX + 8]           // vi*Qy
  MOVSD  XMM4, [RDX + 8]           // vj
  MULSD  XMM4, [RCX]               // vj*Qx
  SUBSD  XMM2, XMM4                // vi*Qy - vj*Qx
  ADDSD  XMM2, XMM2                // tz

  MOVSD  XMM3, [RDX + 24]          // vr

  // X: cx = vj*tz - vk*ty;  result = Qx + vr*tx + cx
  MOVSD  XMM4, [RDX + 8]           // vj
  MULSD  XMM4, XMM2                // vj*tz
  MOVSD  XMM5, [RDX + 16]          // vk
  MULSD  XMM5, XMM1                // vk*ty
  SUBSD  XMM4, XMM5                // cx
  MOVSD  XMM5, XMM3
  MULSD  XMM5, XMM0                // vr*tx
  ADDSD  XMM4, XMM5                // cx + vr*tx
  ADDSD  XMM4, [RCX]               // + Qx
  MOVSD  [RCX], XMM4

  // Y: cy = vk*tx - vi*tz;  result = Qy + vr*ty + cy
  MOVSD  XMM4, [RDX + 16]          // vk
  MULSD  XMM4, XMM0                // vk*tx
  MOVSD  XMM5, [RDX]               // vi
  MULSD  XMM5, XMM2                // vi*tz
  SUBSD  XMM4, XMM5                // cy
  MOVSD  XMM5, XMM3
  MULSD  XMM5, XMM1                // vr*ty
  ADDSD  XMM4, XMM5                // cy + vr*ty
  ADDSD  XMM4, [RCX + 8]           // + Qy
  MOVSD  [RCX + 8], XMM4

  // Z: cz = vi*ty - vj*tx;  result = Qz + vr*tz + cz
  MOVSD  XMM4, [RDX]               // vi
  MULSD  XMM4, XMM1                // vi*ty
  MOVSD  XMM5, [RDX + 8]           // vj
  MULSD  XMM5, XMM0                // vj*tx
  SUBSD  XMM4, XMM5                // cz
  MULSD  XMM3, XMM2                // vr*tz  (XMM3=vr no longer needed)
  ADDSD  XMM3, XMM4                // vr*tz + cz
  ADDSD  XMM3, [RCX + 16]          // + Qz
  MOVSD  [RCX + 16], XMM3
end;

function QuatToMat4D(Quat: PVec4D): TMat4D; assembler;
asm
  .NOFRAME

  MOVSD  XMM0, [RDX]      // i
  MOVSD  XMM1, [RDX + 8]  // j
  MOVSD  XMM2, [RDX + 16] // k
  MOVSD  XMM3, [RDX + 24] // r

  // normSq = (i²+j²)+(k²+r²)  — balanced tree, matches Pascal Hypot2
  MULSD  XMM0, XMM0
  MULSD  XMM1, XMM1
  MULSD  XMM2, XMM2
  MULSD  XMM3, XMM3
  ADDSD  XMM0, XMM1       // i²+j²
  ADDSD  XMM2, XMM3       // k²+r²
  ADDSD  XMM0, XMM2       // (i²+j²)+(k²+r²)

  XORPD  XMM4, XMM4
  COMISD XMM0, XMM4
  JE     @IdentityFallback

  MOV    RAX, $4000000000000000
  MOVQ   XMM4, RAX
  DIVSD  XMM4, XMM0       // XMM4 = s = 2.0 / normSq

  MOV    R8, $3FF0000000000000
  MOVQ   XMM5, R8         // XMM5 = 1.0 (anchor)

  // --- BUILD ROW 0 ---
  MOVSD  XMM0, [RDX + 8]  // j
  MULSD  XMM0, XMM0       // j*j
  MULSD  XMM0, XMM4       // jj = j²*s
  MOVSD  XMM1, [RDX + 16] // k
  MULSD  XMM1, XMM1       // k*k
  MULSD  XMM1, XMM4       // kk = k²*s
  ADDSD  XMM0, XMM1       // jj+kk
  MOVAPD XMM1, XMM5
  SUBSD  XMM1, XMM0
  MOVSD  [RCX], XMM1

  MOVSD  XMM0, [RDX]
  MULSD  XMM0, [RDX + 8]
  MULSD  XMM0, XMM4
  MOVSD  XMM1, [RDX + 16]
  MULSD  XMM1, [RDX + 24]
  MULSD  XMM1, XMM4
  ADDSD  XMM0, XMM1
  MOVSD  [RCX + 8], XMM0

  MOVSD  XMM0, [RDX]
  MULSD  XMM0, [RDX + 16]
  MULSD  XMM0, XMM4
  MOVSD  XMM1, [RDX + 8]
  MULSD  XMM1, [RDX + 24]
  MULSD  XMM1, XMM4
  SUBSD  XMM0, XMM1
  MOVSD  [RCX + 16], XMM0
  XORPD  XMM0, XMM0
  MOVSD  [RCX + 24], XMM0

  // --- BUILD ROW 1 ---
  MOVSD  XMM0, [RDX]
  MULSD  XMM0, [RDX + 8]
  MULSD  XMM0, XMM4
  MOVSD  XMM1, [RDX + 16]
  MULSD  XMM1, [RDX + 24]
  MULSD  XMM1, XMM4
  SUBSD  XMM0, XMM1
  MOVSD  [RCX + 32], XMM0

  MOVSD  XMM0, [RDX]
  MULSD  XMM0, XMM0
  MULSD  XMM0, XMM4       // ii = i²*s
  MOVSD  XMM1, [RDX + 16]
  MULSD  XMM1, XMM1
  MULSD  XMM1, XMM4       // kk = k²*s
  ADDSD  XMM0, XMM1       // ii+kk
  MOVAPD XMM1, XMM5
  SUBSD  XMM1, XMM0
  MOVSD  [RCX + 40], XMM1

  MOVSD  XMM0, [RDX + 8]
  MULSD  XMM0, [RDX + 16]
  MULSD  XMM0, XMM4
  MOVSD  XMM1, [RDX]
  MULSD  XMM1, [RDX + 24]
  MULSD  XMM1, XMM4
  ADDSD  XMM0, XMM1
  MOVSD  [RCX + 48], XMM0
  XORPD  XMM0, XMM0
  MOVSD  [RCX + 56], XMM0

  // --- BUILD ROW 2 ---
  MOVSD  XMM0, [RDX]
  MULSD  XMM0, [RDX + 16]
  MULSD  XMM0, XMM4
  MOVSD  XMM1, [RDX + 8]
  MULSD  XMM1, [RDX + 24]
  MULSD  XMM1, XMM4
  ADDSD  XMM0, XMM1
  MOVSD  [RCX + 64], XMM0

  MOVSD  XMM0, [RDX + 8]
  MULSD  XMM0, [RDX + 16]
  MULSD  XMM0, XMM4
  MOVSD  XMM1, [RDX]
  MULSD  XMM1, [RDX + 24]
  MULSD  XMM1, XMM4
  SUBSD  XMM0, XMM1
  MOVSD  [RCX + 72], XMM0

  MOVSD  XMM0, [RDX]
  MULSD  XMM0, XMM0
  MULSD  XMM0, XMM4       // ii = i²*s
  MOVSD  XMM1, [RDX + 8]
  MULSD  XMM1, XMM1
  MULSD  XMM1, XMM4       // jj = j²*s
  ADDSD  XMM0, XMM1       // ii+jj
  MOVAPD XMM1, XMM5
  SUBSD  XMM1, XMM0
  MOVSD  [RCX + 80], XMM1
  XORPD  XMM0, XMM0
  MOVSD  [RCX + 88], XMM0

  // --- BUILD ROW 3 ---
  XORPD  XMM0, XMM0
  MOVSD  [RCX + 96], XMM0
  MOVSD  [RCX + 104], XMM0
  MOVSD  [RCX + 112], XMM0
  MOVSD  [RCX + 120], XMM5
  RET

@IdentityFallback:
  XORPD  XMM0, XMM0
  MOVUPD [RCX], XMM0
  MOVUPD [RCX + 16], XMM0
  MOVUPD [RCX + 32], XMM0
  MOVUPD [RCX + 48], XMM0
  MOVUPD [RCX + 64], XMM0
  MOVUPD [RCX + 80], XMM0
  MOVUPD [RCX + 96], XMM0
  MOVUPD [RCX + 112], XMM0

  MOV    RAX, $3FF0000000000000
  MOV    [RCX], RAX
  MOV    [RCX + 40], RAX
  MOV    [RCX + 80], RAX
  MOV    [RCX + 120], RAX
end;
{$ENDIF}

// ============================================================================
// AVX2 - UNIFORM VECTOR OPERATIONS (Vec)
// ============================================================================

{$IFDEF AVX2}
procedure MulMat4D(M1, M2: PMat4D); assembler;
asm
  .NOFRAME // Completely safe: utilizes only volatile registers (RAX, RCX, RDX, YMM0-YMM5)
  // Windows x64 ABI: RCX = M1, RDX = M2

  // 1. Cache rows of M2 using volatile registers
  vmovupd ymm2, [rdx + 0]       // M2.Row0
  vmovupd ymm3, [rdx + 32]      // M2.Row1
  vmovupd ymm4, [rdx + 64]      // M2.Row2
  vmovupd ymm5, [rdx + 96]      // M2.Row3

  // We reuse RAX as our loop/offset counter for the 4 rows of M1 (0, 32, 64, 96)
  xor rax, rax

@LoopRows:
  // 2. Load the current row of M1 into ymm0
  vmovupd ymm0, [rcx + rax]

  // 3. Broadcast each element horizontally across 256 bits
  vpermpd ymm1, ymm0, $00       // ymm1 = [X, X, X, X]
  vpermpd ymm2, ymm0, $55       // ymm2 = [Y, Y, Y, Y] (destroys old ymm2 cache, which is safe now)
  vpermpd ymm3, ymm0, $AA       // ymm3 = [Z, Z, Z, Z] (destroys old ymm3 cache, which is safe now)
  vpermpd ymm0, ymm0, $FF       // ymm0 = [W, W, W, W] (destroys old ymm0)

  // 4. Perform streaming linear row combinations
  vmulpd  ymm1, ymm1, [rdx + 0]  // X * M2.Row0 (re-read from memory to preserve cache registers)
  vmulpd  ymm2, ymm2, [rdx + 32] // Y * M2.Row1 (re-read from memory to preserve cache registers)
  vmulpd  ymm3, ymm3, ymm4       // Z * M2.Row2
  vmulpd  ymm0, ymm0, ymm5       // W * M2.Row3

  // 5. Accumulate results (forces exact precision rounding order matching Pascal/SSE2)
  vaddpd  ymm1, ymm1, ymm2
  vaddpd  ymm1, ymm1, ymm3
  vaddpd  ymm1, ymm1, ymm0       // ymm1 now holds the finalized output row

  // 6. Write computed row directly back over M1
  vmovupd [rcx + rax], ymm1

  // 7. Step to next row
  add rax, 32
  cmp rax, 128
  jl @LoopRows

  vzeroupper
end;

procedure TransformVec4D(V: PVec4D; M: PMat4D); assembler;
asm
  .NOFRAME // Completely safe: uses only volatile registers (RCX, RDX, YMM0-YMM5)
  // Windows x64 ABI: RCX = Pointer V, RDX = Pointer M

  // 1. Load the incoming 4D vector into ymm0 [W, Z, Y, X]
  vmovupd ymm0, [rcx]

  // 2. Broadcast each vector component horizontally across 256 bits
  vpermpd ymm1, ymm0, $00       // ymm1 = [V.X, V.X, V.X, V.X]
  vpermpd ymm2, ymm0, $55       // ymm2 = [V.Y, V.Y, V.Y, V.Y]
  vpermpd ymm3, ymm0, $AA       // ymm3 = [V.Z, V.Z, V.Z, V.Z]
  vpermpd ymm0, ymm0, $FF       // ymm0 = [V.W, V.W, V.W, V.W]

  // 3. Multiply directly against the linear rows of the Matrix
  vmulpd  ymm1, ymm1, [rdx + 0]  // V.X * M.Row0
  vmulpd  ymm2, ymm2, [rdx + 32] // V.Y * M.Row1
  vmulpd  ymm3, ymm3, [rdx + 64] // V.Z * M.Row2
  vmulpd  ymm0, ymm0, [rdx + 96] // V.W * M.Row3

  // 4. Sequentially accumulate the rows to mirror exact Pascal/SSE2 rounding order
  vaddpd  ymm1, ymm1, ymm2
  vaddpd  ymm1, ymm1, ymm3
  vaddpd  ymm1, ymm1, ymm0       // ymm1 now holds the finalized [W, Z, Y, X] output vector

  // 5. Overwrite the original vector in place
  vmovupd [rcx], ymm1

  vzeroupper
end;

//-------------------------------------------------------------------------------

procedure MulQuat4D(Q1, Q2: PVec4D); assembler;
asm
  .NOFRAME
  // RCX = V1 [X1, Y1, Z1, W1] (Destination)
  // RDX = V2 [X2, Y2, Z2, W2] (Source Operand)

  // RCX = Q1 [X1, Y1, Z1, W1] (Destination/Source)
  // RDX = Q2 [X2, Y2, Z2, W2] (Source — never written)
  // Uses only volatile registers: ymm0-ymm5

  // Stage 1: Broadcast Q1 components from memory; ymm0 becomes W1 broadcast last
  vmovupd ymm0, [rcx]
  vpermpd ymm1, ymm0, $00       // ymm1 = [X1, X1, X1, X1]
  vpermpd ymm2, ymm0, $55       // ymm2 = [Y1, Y1, Y1, Y1]
  vpermpd ymm3, ymm0, $AA       // ymm3 = [Z1, Z1, Z1, Z1]
  vpermpd ymm0, ymm0, $FF       // ymm0 = [W1, W1, W1, W1]

  // Stage 2: Generate [-0.0,-0.0,-0.0,-0.0] mask in ymm4 (reused across all sign steps)
  vpcmpeqq ymm4, ymm4, ymm4     // ymm4 = all-ones
  vpsllq   ymm4, ymm4, 63       // ymm4 = [-0.0, -0.0, -0.0, -0.0]

  // Stage 3 Term 1: accumulator = W1 * Q2  (all signs positive)
  vmulpd ymm0, ymm0, [rdx]      // ymm0 = [W1*X2, W1*Y2, W1*Z2, W1*W2]

  // Stage 3 Term 2: X1 * permuted(Q2)=[W2,Z2,Y2,X2], signs (+,-,+,-) = negate lanes 1,3
  vmovupd  ymm5, [rdx]
  vpermpd  ymm5, ymm5, $1B      // ymm5 = [W2, Z2, Y2, X2]
  vmulpd   ymm1, ymm1, ymm5     // ymm1 = [X1*W2, X1*Z2, X1*Y2, X1*X2]
  vxorpd   ymm5, ymm5, ymm5     // ymm5 = [0.0, 0.0, 0.0, 0.0]
  vblendpd ymm5, ymm5, ymm4, $0A // ymm5 = [0,-0,0,-0]  ($0A = 1010b)
  vxorpd   ymm1, ymm1, ymm5     // Apply signs
  vaddpd   ymm0, ymm0, ymm1     // Accumulate

  // Stage 3 Term 3: Y1 * permuted(Q2)=[Z2,W2,X2,Y2], signs (+,+,-,-) = negate lanes 2,3
  vmovupd  ymm5, [rdx]
  vpermpd  ymm5, ymm5, $4E      // ymm5 = [Z2, W2, X2, Y2]
  vmulpd   ymm2, ymm2, ymm5     // ymm2 = [Y1*Z2, Y1*W2, Y1*X2, Y1*Y2]
  vxorpd   ymm5, ymm5, ymm5
  vblendpd ymm5, ymm5, ymm4, $0C // ymm5 = [0,0,-0,-0]  ($0C = 1100b)
  vxorpd   ymm2, ymm2, ymm5
  vaddpd   ymm0, ymm0, ymm2

  // Stage 3 Term 4: Z1 * permuted(Q2)=[Y2,X2,W2,Z2], signs (-,+,+,-) = negate lanes 0,3
  vmovupd  ymm5, [rdx]
  vpermpd  ymm5, ymm5, $B1      // ymm5 = [Y2, X2, W2, Z2]
  vmulpd   ymm3, ymm3, ymm5     // ymm3 = [Z1*Y2, Z1*X2, Z1*W2, Z1*Z2]
  vxorpd   ymm5, ymm5, ymm5
  vblendpd ymm5, ymm5, ymm4, $09 // ymm5 = [-0,0,0,-0]  ($09 = 1001b)
  vxorpd   ymm3, ymm3, ymm5
  vaddpd   ymm0, ymm0, ymm3     // ymm0 = final result

  // Stage 4: Commit
  vmovupd [rcx], ymm0

  vzeroupper
end;

//-------------------------------------------------------------------------------

procedure TransformQuat4D(Quat, Versor: PVec4D); assembler;
asm
  .NOFRAME
  // RCX = Quat   [Qx, Qy, Qz, Qw]  in-place (W not modified)
  // RDX = Versor [vi, vj, vk, vr]   read-only
  //
  // Scalar VEX + FMA3 — no YMM registers, no vzeroupper overhead.
  // VFMSUB213SD xmm_a, xmm_b, xmm_c: xmm_a = xmm_a*xmm_b - xmm_c
  // VFMADD231SD xmm_a, xmm_b, xmm_c: xmm_a = xmm_a + xmm_b*xmm_c
  // Phase 1: XMM0=tx, XMM1=ty, XMM2=tz, XMM3=vr
  // Phase 2: c_i and result computed and stored one component at a time

  // tx = 2*(vj*Qz - vk*Qy)
  VMOVSD  XMM4, [RDX + 16]         // vk
  VMULSD  XMM4, XMM4, [RCX + 8]   // vk*Qy
  VMOVSD  XMM0, [RDX + 8]          // vj
  VFMSUB132SD XMM0, XMM4, [RCX + 16]  // vj*Qz - vk*Qy
  VADDSD  XMM0, XMM0, XMM0         // tx

  // ty = 2*(vk*Qx - vi*Qz)
  VMOVSD  XMM4, [RDX]              // vi
  VMULSD  XMM4, XMM4, [RCX + 16]  // vi*Qz
  VMOVSD  XMM1, [RDX + 16]         // vk
  VFMSUB132SD XMM1, XMM4, [RCX]
  //VFMSUB213SD XMM1, [RCX], XMM4    // vk*Qx - vi*Qz
  VADDSD  XMM1, XMM1, XMM1         // ty

  // tz = 2*(vi*Qy - vj*Qx)
  VMOVSD  XMM4, [RDX + 8]          // vj
  VMULSD  XMM4, XMM4, [RCX]        // vj*Qx
  VMOVSD  XMM2, [RDX]              // vi
  VFMSUB132SD XMM2, XMM4, [RCX + 8]
  //VFMSUB213SD XMM2, [RCX + 8], XMM4   // vi*Qy - vj*Qx
  VADDSD  XMM2, XMM2, XMM2         // tz

  VMOVSD  XMM3, [RDX + 24]         // vr

  // X: cx = vj*tz - vk*ty;  result = Qx + cx + vr*tx
  VMOVSD  XMM4, [RDX + 16]         // vk
  VMULSD  XMM4, XMM4, XMM1         // vk*ty
  VMOVSD  XMM5, [RDX + 8]          // vj
  VFMSUB213SD XMM5, XMM2, XMM4     // cx = vj*tz - vk*ty
  VFMADD231SD XMM5, XMM3, XMM0     // cx + vr*tx
  VADDSD  XMM5, XMM5, [RCX]        // + Qx
  VMOVSD  [RCX], XMM5

  // Y: cy = vk*tx - vi*tz;  result = Qy + cy + vr*ty
  VMOVSD  XMM4, [RDX]              // vi
  VMULSD  XMM4, XMM4, XMM2         // vi*tz
  VMOVSD  XMM5, [RDX + 16]         // vk
  VFMSUB213SD XMM5, XMM0, XMM4     // cy = vk*tx - vi*tz
  VFMADD231SD XMM5, XMM3, XMM1     // cy + vr*ty
  VADDSD  XMM5, XMM5, [RCX + 8]    // + Qy
  VMOVSD  [RCX + 8], XMM5

  // Z: cz = vi*ty - vj*tx;  result = Qz + cz + vr*tz
  VMOVSD  XMM4, [RDX + 8]          // vj
  VMULSD  XMM4, XMM4, XMM0         // vj*tx
  VMOVSD  XMM5, [RDX]              // vi
  VFMSUB213SD XMM5, XMM1, XMM4     // cz = vi*ty - vj*tx
  VFMADD231SD XMM5, XMM3, XMM2     // cz + vr*tz
  VADDSD  XMM5, XMM5, [RCX + 16]   // + Qz
  VMOVSD  [RCX + 16], XMM5
end;

function QuatToMat4D(Quat: PVec4D): TMat4D; assembler;
asm
  .NOFRAME

  VMOVSD  XMM0, [RDX]      // XMM0 = i
  VMOVSD  XMM1, [RDX + 8]  // XMM1 = j
  VMOVSD  XMM2, [RDX + 16] // XMM2 = k
  VMOVSD  XMM3, [RDX + 24] // XMM3 = r

  // normSq = (i²+j²)+(k²+r²)  — balanced tree, matches Pascal Hypot2
  VMULSD  XMM0, XMM0, XMM0
  VMULSD  XMM1, XMM1, XMM1
  VMULSD  XMM2, XMM2, XMM2
  VMULSD  XMM3, XMM3, XMM3
  VADDSD  XMM0, XMM0, XMM1  // i²+j²
  VADDSD  XMM2, XMM2, XMM3  // k²+r²
  VADDSD  XMM0, XMM0, XMM2  // (i²+j²)+(k²+r²)

  VXORPD  XMM4, XMM4, XMM4
  VCOMISD XMM0, XMM4
  JE      @AVXIdentityFallback

  MOV     RAX, $4000000000000000
  VMOVQ   XMM4, RAX
  VDIVSD  XMM4, XMM4, XMM0  // XMM4 = s = 2.0 / normSq

  MOV     R8, $3FF0000000000000
  VMOVQ   XMM5, R8            // XMM5 = 1.0 (anchor)

  // --- BUILD ROW 0 (Optimized via FMA Pipeline) ---
  // cf00 = 1.0 - (jj + kk)  where jj = j²*s, kk = k²*s
  VMOVSD    XMM0, [RDX + 8]      // j
  VMULSD    XMM0, XMM0, XMM0     // j²
  VMULSD    XMM0, XMM0, XMM4     // jj = j²*s
  VMOVSD    XMM1, [RDX + 16]     // k
  VMULSD    XMM1, XMM1, XMM1     // k²
  VMULSD    XMM1, XMM1, XMM4     // kk = k²*s
  VADDSD    XMM0, XMM0, XMM1     // jj + kk
  VSUBSD    XMM0, XMM5, XMM0     // cf00
  VMOVSD    [RCX], XMM0

  // cf01 = s * i * j - s * k * r
  VMOVSD    XMM0, [RDX]          // i
  VMULSD    XMM0, XMM0, [RDX + 8]
  VMULSD    XMM0, XMM0, XMM4     // ij
  VMOVSD    XMM1, [RDX + 16]     // k
  VMULSD    XMM1, XMM1, [RDX + 24]
  VMULSD    XMM1, XMM1, XMM4     // kr
  VADDSD    XMM0, XMM0, XMM1     // cf01 = ij + kr
  VMOVSD    [RCX + 8], XMM0

  // cf02 = s * i * k + s * j * r
  VMOVSD    XMM0, [RDX]          // i
  VMULSD    XMM0, XMM0, [RDX + 16]
  VMULSD    XMM0, XMM0, XMM4     // ik
  VMOVSD    XMM1, [RDX + 8]      // j
  VMULSD    XMM1, XMM1, [RDX + 24]
  VMULSD    XMM1, XMM1, XMM4     // jr
  VSUBSD    XMM0, XMM0, XMM1     // cf02 = ik - jr
  VMOVSD    [RCX + 16], XMM0
  VXORPD    XMM0, XMM0, XMM0
  VMOVSD    [RCX + 24], XMM0 // cf03 = 0.0

  // --- BUILD ROW 1 ---
  // cf10 = s * i * j + s * k * r
  VMOVSD    XMM0, [RDX]
  VMULSD    XMM0, XMM0, [RDX + 8]
  VMULSD    XMM0, XMM0, XMM4     // ij
  VMOVSD    XMM1, [RDX + 16]     // k
  VMULSD    XMM1, XMM1, [RDX + 24]
  VMULSD    XMM1, XMM1, XMM4     // kr
  VSUBSD    XMM0, XMM0, XMM1     // cf10 = ij - kr
  VMOVSD    [RCX + 32], XMM0

  // cf11 = 1.0 - (ii + kk)  where ii = i²*s, kk = k²*s
  VMOVSD    XMM0, [RDX]          // i
  VMULSD    XMM0, XMM0, XMM0     // i²
  VMULSD    XMM0, XMM0, XMM4     // ii = i²*s
  VMOVSD    XMM1, [RDX + 16]     // k
  VMULSD    XMM1, XMM1, XMM1     // k²
  VMULSD    XMM1, XMM1, XMM4     // kk = k²*s
  VADDSD    XMM0, XMM0, XMM1     // ii + kk
  VSUBSD    XMM0, XMM5, XMM0     // cf11
  VMOVSD    [RCX + 40], XMM0

  // cf12 = s * j * k - s * i * r
  VMOVSD    XMM0, [RDX + 8]      // j
  VMULSD    XMM0, XMM0, [RDX + 16] // j*k
  VMULSD    XMM0, XMM0, XMM4     // jk
  VMOVSD    XMM1, [RDX]          // i
  VMULSD    XMM1, XMM1, [RDX + 24] // i*r
  VMULSD    XMM1, XMM1, XMM4     // ir
  VADDSD    XMM0, XMM0, XMM1     // cf12 = jk + ir
  VMOVSD    [RCX + 48], XMM0
  VXORPD    XMM0, XMM0, XMM0
  VMOVSD    [RCX + 56], XMM0 // cf13 = 0.0

  // --- BUILD ROW 2 ---
  // cf20 = s * i * k - s * j * r
  VMOVSD    XMM0, [RDX]          // i
  VMULSD    XMM0, XMM0, [RDX + 16] // i*k
  VMULSD    XMM0, XMM0, XMM4     // ik
  VMOVSD    XMM1, [RDX + 8]      // j
  VMULSD    XMM1, XMM1, [RDX + 24] // j*r
  VMULSD    XMM1, XMM1, XMM4     // jr
  VADDSD    XMM0, XMM0, XMM1     // cf20 = ik + jr
  VMOVSD    [RCX + 64], XMM0

  // cf21 = s * j * k + s * i * r
  VMOVSD    XMM0, [RDX + 8]      // j
  VMULSD    XMM0, XMM0, [RDX + 16] // j*k
  VMULSD    XMM0, XMM0, XMM4     // jk
  VMOVSD    XMM1, [RDX]          // i
  VMULSD    XMM1, XMM1, [RDX + 24] // i*r
  VMULSD    XMM1, XMM1, XMM4     // ir
  VSUBSD    XMM0, XMM0, XMM1     // cf21 = jk - ir
  VMOVSD    [RCX + 72], XMM0

  // cf22 = 1.0 - (ii + jj)  where ii = i²*s, jj = j²*s
  VMOVSD    XMM0, [RDX]          // i
  VMULSD    XMM0, XMM0, XMM0     // i²
  VMULSD    XMM0, XMM0, XMM4     // ii = i²*s
  VMOVSD    XMM1, [RDX + 8]      // j
  VMULSD    XMM1, XMM1, XMM1     // j²
  VMULSD    XMM1, XMM1, XMM4     // jj = j²*s
  VADDSD    XMM0, XMM0, XMM1     // ii + jj
  VSUBSD    XMM0, XMM5, XMM0     // cf22
  VMOVSD    [RCX + 80], XMM0
  VXORPD    XMM0, XMM0, XMM0
  VMOVSD    [RCX + 88], XMM0 // cf23 = 0.0

  // --- BUILD ROW 3 ---
  VXORPD  XMM0, XMM0, XMM0
  VMOVSD  [RCX + 96], XMM0
  VMOVSD  [RCX + 104], XMM0
  VMOVSD  [RCX + 112], XMM0
  VMOVSD  [RCX + 120], XMM5

  VZEROUPPER
  RET

@AVXIdentityFallback:
  VXORPD  YMM0, YMM0, YMM0
  VMOVUPD [RCX], YMM0
  VMOVUPD [RCX + 32], YMM0
  VMOVUPD [RCX + 64], YMM0
  VMOVUPD [RCX + 96], YMM0
  MOV     RAX, $3FF0000000000000
  MOV     [RCX], RAX
  MOV     [RCX + 40], RAX
  MOV     [RCX + 80], RAX
  MOV     [RCX + 120], RAX
  VZEROUPPER
end;
{$ENDIF}

procedure TransformVec4DArray_AVX2(First: PVec4D; Count: Int64; M: PMat4D);
asm
  .NOFRAME
  // RCX = First, RDX = Count, R8 = M
  test rdx, rdx
  jle @Exit

@LoopVertices:
  // Load current vertex
  vmovupd ymm0, [rcx]

  // We read the matrix directly from memory inside the loop to avoid non-volatile register spills.
  // On modern CPUs, reading matrix blocks repeatedly from L1 cache [R8 + Offset] takes
  // virtually zero penalty and frees up our YMM registers completely.
  vpermpd ymm1, ymm0, $00       // ymm1 = [X, X, X, X]
  vmulpd  ymm1, ymm1, [r8 + 0]  // ymm1 = X * M.Row0

  vpermpd ymm2, ymm0, $55       // ymm2 = [Y, Y, Y, Y]
  vmulpd  ymm2, ymm2, [r8 + 32] // ymm2 = Y * M.Row1
  vaddpd  ymm1, ymm1, ymm2      // Accumulate

  vpermpd ymm2, ymm0, $AA       // ymm2 = [Z, Z, Z, Z]
  vmulpd  ymm2, ymm2, [r8 + 64] // ymm2 = Z * M.Row2
  vaddpd  ymm1, ymm1, ymm2      // Accumulate

  vpermpd ymm0, ymm0, $FF       // ymm0 = [W, W, W, W]
  vmulpd  ymm0, ymm0, [r8 + 96] // ymm0 = W * M.Row3
  vaddpd  ymm1, ymm1, ymm0      // Final output row in ymm1

  // Write back to the array in place
  vmovupd [rcx], ymm1

  // Advance pointer (32 bytes per vector)
  add rcx, 32
  dec rdx
  jnz @LoopVertices

@Exit:
  vzeroupper
end;

procedure MatMul_SSE2(const Left, Right: TMat4D; var Result: TMat4D); assembler;
// Operator-form SSE2 matrix multiply: Result := Left * Right. Same convention/rounding order as
// MatMul_AVX2 and MulMat4D (result row i = Left[i].X*Right.Row0 + Y*Row1 + Z*Row2 + W*Row3).
// Adapted from MulMat4D: RCX=@Left, RDX=@Right, R8=@Result. The row-offset counter moves to R9
// (R8 now holds @Result), and rows commit to [R8] via the Temp buffer (so it is aliasing-safe).
var
  Temp: TMat4D;
asm
  lea     rax, [Temp]           // RAX = &Temp
  xor     r9, r9                // R9 = row offset (0,32,64,96); R8 reserved for @Result
@LoopRowsSSE2:
  movupd  xmm0, [rcx + r9]       // Left row I low [Y, X]
  movapd  xmm1, xmm0
  unpcklpd xmm1, xmm1            // [X, X]
  movapd  xmm2, xmm0
  unpckhpd xmm2, xmm2            // [Y, Y]
  movupd  xmm0, [rcx + r9 + 16]  // Left row I high [W, Z]
  movapd  xmm3, xmm0
  unpcklpd xmm3, xmm3            // [Z, Z]
  movapd  xmm4, xmm0
  unpckhpd xmm4, xmm4            // [W, W]
  // Low half [Y, X]
  movupd  xmm5, [rdx + 0]
  mulpd   xmm5, xmm1
  movupd  xmm0, [rdx + 32]
  mulpd   xmm0, xmm2
  addpd   xmm5, xmm0
  movupd  xmm0, [rdx + 64]
  mulpd   xmm0, xmm3
  addpd   xmm5, xmm0
  movupd  xmm0, [rdx + 96]
  mulpd   xmm0, xmm4
  addpd   xmm5, xmm0
  movupd  [rax + r9], xmm5
  // High half [W, Z]
  movupd  xmm5, [rdx + 16]
  mulpd   xmm5, xmm1
  movupd  xmm0, [rdx + 48]
  mulpd   xmm0, xmm2
  addpd   xmm5, xmm0
  movupd  xmm0, [rdx + 80]
  mulpd   xmm0, xmm3
  addpd   xmm5, xmm0
  movupd  xmm0, [rdx + 112]
  mulpd   xmm0, xmm4
  addpd   xmm5, xmm0
  movupd  [rax + r9 + 16], xmm5
  add     r9, 32
  cmp     r9, 128
  jl      @LoopRowsSSE2
  // commit Temp -> Result [R8]
  movupd  xmm0, [rax + 0]
  movupd  xmm1, [rax + 16]
  movupd  xmm2, [rax + 32]
  movupd  xmm3, [rax + 48]
  movupd  [r8 + 0], xmm0
  movupd  [r8 + 16], xmm1
  movupd  [r8 + 32], xmm2
  movupd  [r8 + 48], xmm3
  movupd  xmm0, [rax + 64]
  movupd  xmm1, [rax + 80]
  movupd  xmm2, [rax + 96]
  movupd  xmm3, [rax + 112]
  movupd  [r8 + 64], xmm0
  movupd  [r8 + 80], xmm1
  movupd  [r8 + 96], xmm2
  movupd  [r8 + 112], xmm3
end;

procedure MatMul_AVX2(const Left, Right: TMat4D; var Result: TMat4D); assembler;
asm
  .NOFRAME // Completely safe: utilizes only volatile registers (RAX, RCX, RDX, YMM0-YMM5)
  // Windows x64 ABI: RCX = M1, RDX = M2

  // 1. Cache rows of M2 using volatile registers
  vmovupd ymm2, [rdx + 0]       // M2.Row0
  vmovupd ymm3, [rdx + 32]      // M2.Row1
  vmovupd ymm4, [rdx + 64]      // M2.Row2
  vmovupd ymm5, [rdx + 96]      // M2.Row3

  // We reuse RAX as our loop/offset counter for the 4 rows of M1 (0, 32, 64, 96)
  xor rax, rax

@LoopRows:
  // 2. Load the current row of M1 into ymm0
  vmovupd ymm0, [rcx + rax]

  // 3. Broadcast each element horizontally across 256 bits
  vpermpd ymm1, ymm0, $00       // ymm1 = [X, X, X, X]
  vpermpd ymm2, ymm0, $55       // ymm2 = [Y, Y, Y, Y] (destroys old ymm2 cache, which is safe now)
  vpermpd ymm3, ymm0, $AA       // ymm3 = [Z, Z, Z, Z] (destroys old ymm3 cache, which is safe now)
  vpermpd ymm0, ymm0, $FF       // ymm0 = [W, W, W, W] (destroys old ymm0)

  // 4. Perform streaming linear row combinations
  vmulpd  ymm1, ymm1, [rdx + 0]  // X * M2.Row0 (re-read from memory to preserve cache registers)
  vmulpd  ymm2, ymm2, [rdx + 32] // Y * M2.Row1 (re-read from memory to preserve cache registers)
  vmulpd  ymm3, ymm3, ymm4       // Z * M2.Row2
  vmulpd  ymm0, ymm0, ymm5       // W * M2.Row3

  // 5. Accumulate results (forces exact precision rounding order matching Pascal/SSE2)
  vaddpd  ymm1, ymm1, ymm2
  vaddpd  ymm1, ymm1, ymm3
  vaddpd  ymm1, ymm1, ymm0       // ymm1 now holds the finalized output row

  // 6. Write computed row directly back over M1
  vmovupd [r8 + rax], ymm1

  // 7. Step to next row
  add rax, 32
  cmp rax, 128
  jl @LoopRows

  vzeroupper
end;

class operator TVec4D.Add(const Left, Right: TVec4D): TVec4D;
begin
  Result.X := Left.X + Right.X;
  Result.Y := Left.Y + Right.Y;
  Result.Z := Left.Z + Right.Z;
  Result.W := Left.W + Right.W;
end;

class operator TVec4D.Subtract(const Left, Right: TVec4D): TVec4D;
begin
  Result.X := Left.X - Right.X;
  Result.Y := Left.Y - Right.Y;
  Result.Z := Left.Z - Right.Z;
  Result.W := Left.W - Right.W;
end;

class operator TVec4D.BitwiseAnd(const Left, Right: TVec4D): TVec4D;
// quaternion product
begin
  Result.I := (Left.R * Right.I) + (Left.I * Right.R) + (Left.J * Right.K) - (Left.Z * Right.J);
  Result.J := (Left.R * Right.J) - (Left.I * Right.K) + (Left.J * Right.R) + (Left.Z * Right.I);
  Result.K := (Left.R * Right.K) + (Left.I * Right.J) - (Left.J * Right.I) + (Left.Z * Right.R);
  Result.R := (Left.R * Right.R) - (Left.I * Right.I) - (Left.J * Right.J) - (Left.Z * Right.K);
end;

class operator TVec4D.Multiply(const Left: TVec4D; Right: Double): TVec4D;
// scalar multiplication
begin
  Result.X := Left.X * Right;
  Result.Y := Left.Y * Right;
  Result.Z := Left.Z * Right;
  Result.W := Left.W * Right;
end;

class operator TVec4D.Multiply(Left: Double; const Right: TVec4D): TVec4D;
// scalar multiplication
begin
  Result.X := Left * Right.X;
  Result.Y := Left * Right.Y;
  Result.Z := Left * Right.Z;
  Result.W := Left * Right.W;
end;

class operator TVec4D.Multiply(const Left, Right: TVec4D): TVec4D;
// quaternion transform (Rodrigues formula, assumes unit versor)
var
  vi, vj, vk, vr: Double;
  tx, ty, tz: Double;
  cx, cy, cz: Double;
begin
  vi := Right.I; vj := Right.J; vk := Right.K; vr := Right.R;

  tx := 2.0 * ((vj * Left.K) - (vk * Left.J));
  ty := 2.0 * ((vk * Left.I) - (vi * Left.K));
  tz := 2.0 * ((vi * Left.J) - (vj * Left.I));

  cx := (vj * tz) - (vk * ty);
  cy := (vk * tx) - (vi * tz);
  cz := (vi * ty) - (vj * tx);

  Result.X := Left.X + (vr * tx) + cx;
  Result.Y := Left.Y + (vr * ty) + cy;
  Result.Z := Left.Z + (vr * tz) + cz;
  Result.W := Left.W;
end;

class operator TVec4D.BitwiseOr(const Left, Right: TVec4D): Double;
// dot product
begin
  Result := Left.X * Right.X + Left.Y * Right.Y + Left.Z * Right.Z;
end;

class operator TVec4D.BitwiseXor(const Left, Right: TVec4D): TVec4D;
// 3D cross product
begin
  Result.X := (Left.Y * Right.Z) - (Left.Z * Right.Y);
  Result.Y := (Left.Z * Right.X) - (Left.X * Right.Z);
  Result.Z := (Left.X * Right.Y) - (Left.Y * Right.X);
  //V.W remains untouched //V1^.W := 0.0;
end;

class operator TVec4D.LogicalNot(const Left: TVec4D): TVec4D;
// quaternion conjugate, invert the imaginary vector components
begin
  Result.I := -Left.I;
  Result.J := -Left.J;
  Result.K := -Left.K;
  Result.R :=  Left.R;
end;

function TVec4D.Magnitude4D: Double;
// quaternion magnitude
begin
  Result:=Hypot(I, J, K, R);
end;

function TVec4D.Magnitude3D: Double;
// 3D vector length
begin
  Result:=Hypot(X, Y, Z);
end;

function TVec4D.Normalize4D: TVec4D;
// quaternion normalization
var
  Mag, InvMag: Double;
begin
  Mag := Hypot(I, J, K, R);
  if Mag = 0.0 then FillChar(Result, SizeOf(TVec4D), 0) else
   begin
    InvMag := 1.0 / Mag;
    Result.X := X * InvMag;
    Result.Y := Y * InvMag;
    Result.Z := Z * InvMag;
    Result.W := W * InvMag;
   end
end;

function TVec4D.Normalize3D: TVec4D;
// 3D vector normalization
var
  Len, InvLen: Double;
begin
  Len := Hypot(X, Y, Z);
  if Len = 0.0 then FillChar(Result, SizeOf(TVec4D)-SizeOf(Double), 0) else
   begin
    InvLen := 1.0 / Len;
    Result.X := X * InvLen;
    Result.Y := Y * InvLen;
    Result.Z := Z * InvLen;
   end
end;

{function TVec4D.InvCubeScale3D_Hypot(S: Double): TVec4D;
// used to compute rvec/r^3 in acceleration calculations
var
  Len, SInvLen3: Double;
begin
  Len := Hypot(X, Y, Z);
  // W MUST be zeroed. This result is a direction/acceleration vector (W=0). Leaving W
  // uninitialised lets stack garbage accumulate through a[i] -> V.W -> a body's position
  // R.W in the integrators; a later rotate (TVec4D*TMat4D) then evaluates R.W*M[..][3], and
  // since the matrix is rotation-only (M[..][3]=0) that is 0*garbage -- which is 0 for a
  // finite value but NaN for a NaN/Inf, poisoning X/Y/Z and ultimately crashing DrawLabels'
  // Round()->Integer narrowing with an ERangeError. Cost is one store on a hot path.
  if Len = 0.0 then FillChar(Result, SizeOf(TVec4D), 0) else
   begin
    SInvLen3 := 1.0 / Len;
    SInvLen3 := SInvLen3*SInvLen3*SInvLen3*S;
    Result.X := X * SInvLen3;
    Result.Y := Y * SInvLen3;
    Result.Z := Z * SInvLen3;
    Result.W := 0.0;
   end
end; }

function TVec4D.InvCubeScale3D(S: Double): TVec4D;
// used to compute rvec/r^3 in acceleration calculations
var
  Len2, InvLen2, SInvLen3: Double;
begin
  Len2 := X*X + Y*Y + Z*Z;
  // W MUST be zeroed. This result is a direction/acceleration vector (W=0). Leaving W
  // uninitialised lets stack garbage accumulate through a[i] -> V.W -> a body's position
  // R.W in the integrators; a later rotate (TVec4D*TMat4D) then evaluates R.W*M[..][3], and
  // since the matrix is rotation-only (M[..][3]=0) that is 0*garbage -- which is 0 for a
  // finite value but NaN for a NaN/Inf, poisoning X/Y/Z and ultimately crashing DrawLabels'
  // Round()->Integer narrowing with an ERangeError. Cost is one store on a hot path.
  if Len2 = 0.0 then FillChar(Result, SizeOf(TVec4D), 0) else
   begin
    InvLen2 := 1 / Len2;
    SInvLen3 := Sqrt(InvLen2) * InvLen2 * S;
    Result.X := X * SInvLen3;
    Result.Y := Y * SInvLen3;
    Result.Z := Z * SInvLen3;
    Result.W := 0.0;
   end
end;

function TVec4D.NormalizeW: TVec4D;
// homogenous vector normalization
var
  InvW: Double;
begin
  if (W = 0.0) or (W = 1.0) then Result:=Self else
   begin
    InvW := 1.0 / W;
    Result.X := X * InvW;
    Result.Y := Y * InvW;
    Result.Z := Z * InvW;
    Result.W := W * InvW;
   end
end;

function TVec4D.SqrMag4D: Double;
// quaternion (4D) magnitude
begin
  Result:=Hypot2(I, J, K, R);
end;

function TVec4D.SqrMag3D: Double;
// vector (3D) magnitude
var
  Temp, TempX, TempY, TempZ: Double;
begin
  TempX := Abs(X);
  TempY := Abs(Y);
  TempZ := Abs(Z);

  // Replicate the exact Delphi 12 partial sorting tree
  if TempX > TempY then
  begin
    Temp := TempX;
    TempX := TempY;
    TempY := Temp;
  end;
  if TempY > TempZ then
  begin
    Temp := TempZ;
    TempZ := TempY;
    TempY := Temp;
  end;

  if TempZ = 0 then
    Result := 0
  else
  begin
    // To preserve bit-for-bit equivalence, we match the exact evaluation steps
    Temp := 1 + Sqr(TempX / TempZ) + Sqr(TempY / TempZ);
    Result := (Temp * TempZ) * TempZ;
  end;
end;

function TVec4D.P2V3D: TVec4D;
var
  sina, cosa, sind, cosd: Double;
begin
  SinCos(pA, sina, cosa);
  SinCos(pD, sind, cosd);
  Result.X:=cosa*cosd*pL;
  Result.Y:=sina*cosd*pL;
  Result.Z:=sind*pL;
  Result.W:=W;
end;

function TVec4D.V2P3D: TVec4D;
begin
  Result.pL:=Hypot(X, Y, Z);
  Result.pA:=Atan2(Y, X);
  Result.pD:=ArcCos(Z/Result.pL);
end;

class operator TMat4D.Multiply(const Left, Right: TMat4D): TMat4D;
// matrix multiplication -- the ONE operator that is not pure Pascal (AVX2 build -> AVX2, else SSE2)
begin
  {$IFDEF AVX2}
  MatMul_AVX2(Left, Right, Result);
  {$ELSE}
  MatMul_SSE2(Left, Right, Result);
  {$ENDIF}
end;

{class operator TMat4D.Multiply(const Left: TVec4D; const Right: TMat4D): TVec4D;
// transform
begin
  Result.X := (Left.X * Right.cf00) + (Left.Y * Right.cf10) + (Left.Z * Right.cf20) + (Left.W * Right.cf30);
  Result.Y := (Left.X * Right.cf01) + (Left.Y * Right.cf11) + (Left.Z * Right.cf21) + (Left.W * Right.cf31);
  Result.Z := (Left.X * Right.cf02) + (Left.Y * Right.cf12) + (Left.Z * Right.cf22) + (Left.W * Right.cf32);
  Result.W := (Left.X * Right.cf03) + (Left.Y * Right.cf13) + (Left.Z * Right.cf23) + (Left.W * Right.cf33);
end;

class operator TMat4D.Multiply(const Left: TMat4D; const Right: TVec4D): TVec4D;
// transform
begin
  Result.X := (Right.X * Left.cf00) + (Right.Y * Left.cf10) + (Right.Z * Left.cf20) + (Right.W * Left.cf30);
  Result.Y := (Right.X * Left.cf01) + (Right.Y * Left.cf11) + (Right.Z * Left.cf21) + (Right.W * Left.cf31);
  Result.Z := (Right.X * Left.cf02) + (Right.Y * Left.cf12) + (Right.Z * Left.cf22) + (Right.W * Left.cf32);
  Result.W := (Right.X * Left.cf03) + (Right.Y * Left.cf13) + (Right.Z * Left.cf23) + (Right.W * Left.cf33);
end;}

class operator TMat4D.Multiply(const Left: TVec4D; const Right: TMat4D): TVec4D;
// transform
begin
  Result.X := Left.X * Right.cf00 + Left.Y * Right.cf10 + Left.Z * Right.cf20 + Left.W * Right.cf30;
  Result.Y := Left.X * Right.cf01 + Left.Y * Right.cf11 + Left.Z * Right.cf21 + Left.W * Right.cf31;
  Result.Z := Left.X * Right.cf02 + Left.Y * Right.cf12 + Left.Z * Right.cf22 + Left.W * Right.cf32;
  Result.W := Left.X * Right.cf03 + Left.Y * Right.cf13 + Left.Z * Right.cf23 + Left.W * Right.cf33;
end;

class operator TMat4D.Multiply(const Left: TMat4D; const Right: TVec4D): TVec4D;
// transform
begin
  Result.X := Right.X * Left.cf00 + Right.Y * Left.cf10 + Right.Z * Left.cf20 + Right.W * Left.cf30;
  Result.Y := Right.X * Left.cf01 + Right.Y * Left.cf11 + Right.Z * Left.cf21 + Right.W * Left.cf31;
  Result.Z := Right.X * Left.cf02 + Right.Y * Left.cf12 + Right.Z * Left.cf22 + Right.W * Left.cf32;
  Result.W := Right.X * Left.cf03 + Right.Y * Left.cf13 + Right.Z * Left.cf23 + Right.W * Left.cf33;
end;

{procedure TMat4D.FromQuat(Q: PVec4D);
var
  x, y, z, w: Double;
  xx, yy, zz: Double;
  xy, xz, yz: Double;
  wx, wy, wz: Double;
begin
  // Extract fields: X,Y,Z are imaginary (I,J,K), W is real (R)
  x := Q^.I; y := Q^.J; z := Q^.K; w := Q^.R;

  xx := x * x; yy := y * y; zz := z * z;
  xy := x * y; xz := x * z; yz := y * z;
  wx := w * x; wy := w * y; wz := w * z;

  // --- Column 0 (V[0]) ---
  cf00 := 1.0 - (2.0 * (yy + zz));
  cf01 := 2.0 * (xy - wz); // Matched to your engine's transposed orientation
  cf02 := 2.0 * (xz + wy);
  cf03 := 0.0;

  // --- Column 1 (V[1]) ---
  cf10 := 2.0 * (xy + wz);
  cf11 := 1.0 - (2.0 * (xx + zz));
  cf12 := 2.0 * (yz - wx);
  cf13 := 0.0;

  // --- Column 2 (V[2]) ---
  cf20 := 2.0 * (xz - wy);
  cf21 := 2.0 * (yz + wx);
  cf22 := 1.0 - (2.0 * (xx + yy));
  cf23 := 0.0;

  // --- Column 3 (V[3] - Homogeneous Translation/Identity Anchor) ---
  cf30 := 0.0;
  cf31 := 0.0;
  cf32 := 0.0;
  cf33 := 1.0;
end;}

procedure TMat4D.FromQuat(Q: PVec4D);
var
  s, i, j, k, r,
  ii, ij, ik, ir, jj, jk, jr, kk, kr, normSq: Double;
begin
  i:=Q.I; j:=Q.J; k:=Q.K; r:=Q.R;

  // Compute the squared norm directly to avoid square root rounding cascades
  normSq := Hypot2(i, j, k, r);

  if normSq < 1e-14 then
  begin
    FillChar(Self, SizeOf(TMat4D), 0);
    ci00 := $3FF0000000000000;
    ci11 := $3FF0000000000000;
    ci22 := $3FF0000000000000;
    ci33 := $3FF0000000000000;
  end
  else
  begin
    // Scaling factor perfectly neutralizes scale for any quaternion
    s  := 2.0 / normSq;
    ii := i * i * s;
    ij := i * j * s;
    ik := i * k * s;
    ir := i * r * s;
    jj := j * j * s;
    jk := j * k * s;
    jr := j * r * s;
    kk := k * k * s;
    kr := k * r * s;

    // --- ROW 0 ---
    cf00 := 1.0 - (jj + kk);
    cf01 := ij + kr;
    cf02 := ik - jr;
    cf03 := 0.0;

    // --- ROW 1 ---
    cf10 := ij - kr;
    cf11 := 1.0 - (ii + kk);
    cf12 := jk + ir;
    cf13 := 0.0;

    // --- ROW 2 ---
    cf20 := ik + jr;
    cf21 := jk - ir;
    cf22 := 1.0 - (ii + jj);
    cf23 := 0.0;

    // --- ROW 3 ---
    cf30 := 0.0;
    cf31 := 0.0;
    cf32 := 0.0;
    cf33 := 1.0;
  end;
end;

{procedure KahanVectorAccumulate(var Total: TVec4D; const Input: TVec4D; var Compensation: TVec4D);
var
  Y, T: TVec4D;
begin
  // 1. Subtract the running error/compensation from the new input
  Y.X := Input.X - Compensation.X;
  Y.Y := Input.Y - Compensation.Y;
  Y.Z := Input.Z - Compensation.Z;
  Y.W := Input.W - Compensation.W;

  // 2. Add the corrected input to the running total
  T.X := Total.X + Y.X;
  T.Y := Total.Y + Y.Y;
  T.Z := Total.Z + Y.Z;
  T.W := Total.W + Y.W;

  // 3. Calculate the lost low-order bits to pass to the next loop step
  Compensation.X := (T.X - Total.X) - Y.X;
  Compensation.Y := (T.Y - Total.Y) - Y.Y;
  Compensation.Z := (T.Z - Total.Z) - Y.Z;
  Compensation.W := (T.W - Total.W) - Y.W;

  Total := T;
end;}

function LoadVec4D(X, Y, Z, W: Double): TVec4D;
begin
  Result.X:=X;
  Result.Y:=Y;
  Result.Z:=Z;
  Result.W:=W;
end;

end.
