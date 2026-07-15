unit Chebyshev;

interface

uses RSoftTypes64, AsmUtils64, Vec4D;

{$ALIGN 16}

{$POINTERMATH ON}

procedure EvaluateChebyshev3D_Full(
  Data: Pointer;           // RCX  -> Continuous Coeff array [X0..Xn, Y0..Yn, Z0..Zn]
  Desc: Pointer;           // RDX  -> Pointer to metadata record
  S: PState4D;             // R8   -> Destination Position vector [X, Y, Z, 1.0]
  T: Double                // YMM3 -> low Double = T
);

procedure EvaluateChebyshev3D(
  Data: Pointer;           // RCX -> Continuous Coeff array [X0..Xn, Y0..Yn, Z0..Zn]
  Desc: Pointer;           // RDX -> Pointer to packed metadata descriptor record
  R: PVec4D;               // R8  -> Direct destination Position vector tracking lane
  T: Double                // XMM3 -> Time variable scalar (Natively in register slot 4)
);

procedure EvaluateChebyshev1D(
  Data: Pointer; // RCX -> Pointer to C array
  Desc: Pointer; // RDX -> Pointer to Metadata
  X: PDouble;    // R8  -> Pointer to Output Result
  T: Double      // XMM3 -> Value parameter (Passed automatically in XMM3)
);

procedure ChebyshevNodeEpochs(Mid, Radius: Double; NumCoef: Int64; Epochs: PDouble);   // one record's node epochs, ascending in time -- sample the gap source here
procedure ChebyshevEncode(const States: TState4DArray; NumComp: Int64; Coef: PDouble); // inverse of the decoders: fit SoA coeffs from node-sampled states

const

  IDX_NUMCOMP    = 16;
  IDX_NUMCOEF    = 17;
  IDX_OFFSX      = 20;
  IDX_OFFSY      = 21;
  IDX_OFFSZ      = 22;
  IDX_ARRAYLEN   = 18;
  IDX_VALINTV    = 28;
  IDX_RADIUS     = 29;
  IDX_INVRADIUS  = 30;

  OFFS_NUMCOMP   = IDX_NUMCOMP shl 3;     // Desc.NumComp
  OFFS_NUMCOEF   = IDX_NUMCOEF shl 3;     // Desc.NumCoef
  OFFS_OFFSX     = IDX_OFFSX shl 3;       // Desc.RTOffsetX = 0
  OFFS_OFFSY     = IDX_OFFSY shl 3;       // Desc.RTOffsetY (same as RTArrayLen)
  OFFS_OFFSZ     = IDX_OFFSZ shl 3;       // Desc.RTOffsetZ (same as 2*RTArrayLen)
  OFFS_ARRAYLEN  = IDX_ARRAYLEN shl 3;    // Desc.RTArrayLen (Offset 144)
  OFFS_VALINTV   = IDX_VALINTV shl 3;     // Desc.ValIntv (Offset 216)
  OFFS_RADIUS    = IDX_RADIUS shl 3;      // Desc.Radius (Offset 192)
  OFFS_INVRADIUS = IDX_INVRADIUS shl 3;   // Desc.InvRadius (Offset 224)

implementation

{$IFDEF AVX2}

procedure EvaluateChebyshev3D_Full(
// ============================================================================
// REVERSE CLENSHAW VECTOR PIPELINE WITH DIRECT FORWARD DERIVATIVE
// Array-of-Vectors data format version
// Architecture: x64 AVX2 / FMA3 (Windows ABI / Delphi .noframe Compliant)
// Registers: Loop metrics mapped to YMM0-YMM3. YMM4 contains pristine T vector.
// the FMA3 blocks result in +20 to 50% performance gain vs the non-FMA3 code
// the AVX2+FMA3 code is 1.5 to 2.5 times faster than the best Pascal version
// (which is already 2 or 3 times faster than the old Pascal code
// ============================================================================
// ymm0 = r1
// ymm1 = r2
// ymm2 = v1
// ymm3 = v2
// ymm4 = T
// ymm5 = scratch register
  Data: Pointer;           // RCX  -> Continuous Coeff array [X0..Xn, Y0..Yn, Z0..Zn]
  Desc: Pointer;           // RDX  -> Pointer to metadata record
  S: PState4D;             // R8   -> Destination Position vector [X, Y, Z, 1.0]
  T: Double                // YMM3 -> low Double = T
); assembler;
asm
  .NOFRAME
    // --- PREPARE CONSTANT T REGISTER (NEVER MODIFIED IN LOOP) ---
    vpbroadcastq ymm4, xmm3           // ymm4 = Constant T vector = [T, T, T, T]

    // --- INITIALIZE TRACKING REGISTERS TO ZERO ---
    vxorpd  ymm0, ymm0, ymm0          // ymm0 = Iteration-A Primary Value Vector (r1 = 0.0)
    vxorpd  ymm1, ymm1, ymm1          // ymm1 = Iteration-A History Value Vector (r2 = 0.0)
    vxorpd  ymm2, ymm2, ymm2          // ymm2 = Iteration-A Primary Derivative Vector (v1 = 0.0)
    vxorpd  ymm3, ymm3, ymm3          // ymm3 = Iteration-A History Derivative Vector (v2 = 0.0)

    mov rax, [rdx + OFFS_NUMCOEF]
    dec rax
    shl rax, 5                        // rax = offset of last coeff vector
@loop:
    // ============================================================================
    // STEP 1: Compute Derivative Vector (v1)
    // Formula: New_v1 = 2.0 * r1 + 2.0 * T * v1 - v2;
    // Current input states: ymm0 = r1, ymm1 = r2, ymm2 = v1, ymm3 = v2
    // ============================================================================
    vaddpd      ymm5, ymm0, ymm0                // ymm5 = 2*r1
    vsubpd      ymm3, ymm5, ymm3                // ymm3 = 2*r1 - v2 (destructive rewrite)
    vaddpd      ymm5, ymm4, ymm4                // ymm5 = 2*T
    vfmadd213pd ymm5, ymm2, ymm3                // ymm5 = (v1 * 2*T) + (2*r1 - v2)

    // Update Derivative States for the next round
    vmovaps     ymm3, ymm2                      // ymm3 (v2) = old v1
    vmovaps     ymm2, ymm5                      // ymm2 (v1) = new v1

    // ============================================================================
    // STEP 2: Compute Value Vector (r1)
    // Formula: New_r1 = c[i] + 2.0 * T * r1 - r2;
    // Current input states: ymm0 = r1, ymm1 = r2
    // ============================================================================
    vaddpd      ymm5, ymm4, ymm4                // ymm5 = 2*T
    vfmsub213pd ymm5, ymm0, ymm1                // ymm5 = 2*T * r1 - r2

    // Gather c[i] directly into ymm1 (Since ymm1/r2 is a dead fallback now, we can overwrite it safely)
    //vmovdqa     ymm1, [rcx + rax]             // ymm1 = c[i] = [X, Y, Z, 0.0]  // 32-byte aligned version
    vmovdqu     ymm1, [rcx + rax]               // ymm1 = c[i] = [X, Y, Z, 0.0]

    vaddpd      ymm5, ymm5, ymm1                // ymm5 = c[i] + 2*T * r1 - r2 (This is New_r1)

    // Update Value States for the next round
    vmovaps     ymm1, ymm0                      // ymm1 (r2) = old r1
    vmovaps     ymm0, ymm5                      // ymm0 (r1) = new r1

    sub         rax, 32
    jnz         @loop                           // Loop back if rax > 0

// ============================================================================
// UNIFIED TERMINAL STEP MATHEMATICS (Evaluating c0 at rax = 0)
// Current Active Registers: YMM0=r1, YMM1=r2, YMM2=v1, YMM3=v2, YMM4=T
// Dead Available Registers: YMM5 (Fully Free to use as scratch space)
// ============================================================================
    // 1. COMPUTE FINAL DERIVATIVE (VELOCITY) VALUE
    // Formula := (r1  + T * v1 - v2)*InvRadius;
    vmulpd      ymm5, ymm4, ymm2                // ymm5 = T * v1
    vsubpd      ymm5, ymm5, ymm3                // ymm5 = (T * v1) - v2
    vaddpd      ymm2, ymm5, ymm0                // <-- FIXED: Changed from ymm1 to ymm0 (r1) to cleanly resolve the unscaled velocity vector into ymm2

    // Now that the velocity vector is completed, YMM2 contains unscaled velocity.

    // Construct c0 into scratch register YMM5:
    // vmovdqa     ymm5, [rcx]                  // 32-byte aligned version
    vmovdqu     ymm5, [rcx]                     // ymm5 = c0 = [X0, Y0, Z0, 0.0]

    vsubpd      ymm5, ymm5, ymm1                // ymm5 = c0 - r2
    vfmadd213pd ymm0, ymm4, ymm5                // ymm0 = Final Position Vector!

    // ============================================================================
    // VECTOR POST-PROCESSING
    // ============================================================================

    // Step 1: Scale Velocity Vector (YMM2) by multiplying by 1/radius metadata lookup
    vmovddup    xmm5, qword ptr [rdx + OFFS_INVRADIUS]
    vinsertf128 ymm5, ymm5, xmm5, 1
    vmulpd      ymm2, ymm2, ymm5                // ymm2 = Final Scaled Velocity Vector

    // Step 2a: Force Velocity W Component to 0.0
    vxorpd      ymm5, ymm5, ymm5                // ymm5 = [0.0, 0.0, 0.0, 0.0]
    vblendpd    ymm2, ymm2, ymm5, 8             // ymm2 = [vx, vy, vz, 0.0]

    // Step 2b: Force Position W Component to 1.0 using immediate bit parsing
    mov         rax, $3FF0000000000000
    //vmovq       xmm5, rax
    //vmovddup    xmm5, xmm5
    //vinsertf128 ymm5, ymm5, xmm5, 1
    //vblendpd    ymm0, ymm0, ymm5, 8             // ymm0 = [rx, ry, rz, 1.0]

    // ============================================================================
    // UNALIGNED OUTPUT MEMORY STORAGE
    // ============================================================================
    vmovupd       [r8], ymm0        // Write Position Array: [rx, ry, rz, 1.0]
    mov           [r8 + 24], rax
    vmovupd       [r8 + 32], ymm2   // Write Scaled Velocity Array: [vx, vy, vz, 0.0]
    vzeroupper
end;

//----------------------------------------------------------------------------------

procedure EvaluateChebyshev3D(
// AI-written AVX2+FMA3 PositionOnly code, crazy fast
  Data: Pointer;           // RCX -> Continuous Coeff array [X0..Xn, Y0..Yn, Z0..Zn]
  Desc: Pointer;           // RDX -> Packed metadata descriptor record
  R: PVec4D;               // R8  -> Destination 3D/4D Vector array [X, Y, Z, W]
  T: Double                // XMM3 -> Time variable scalar
); assembler;
// registers
// ymm0, ymm1, ymm2: Clenshaw Recurrence state vectors r1, r2, r3
// ymm3: (T,T,T,T) ymm4 = (2T,2T,2T,2T)
// ymm5: scratch
asm
  .NOFRAME
  // 1. Broadcast the time variable T to create the FMA factor: YMM3 = [T, T, T, T] YMM4 = [2T, 2T, 2T, 2T]
  //vmovddup   xmm3, xmm3
  //vinsertf128 ymm3, ymm3, xmm3, 1
  vpbroadcastq ymm3, xmm3
  vaddpd     ymm4, ymm3, ymm3

  // 3. Initialize Clenshaw Recurrence state vectors to 0.0
  vxorpd     ymm0, ymm0, ymm0   // D_k1
  vxorpd     ymm1, ymm1, ymm1   // D_k2
  vxorpd     ymm2, ymm2, ymm2   // old_D_k2

  // 4. Setup loop counter based on dynamic coefficient count
  mov        rax, [rdx + OFFS_NUMCOEF]                // Load NumCoef from [RDX + 136]
  dec        rax
  shl        rax, 5

@LoopClenshaw:
 // Gather coefficients c_k
  vmovdqu     ymm5, [rcx + rax]

  // Parallel Clenshaw Formula: D_k = (2T * D_k1) - D_k2 + C_k
  vsubpd     ymm5, ymm5, ymm2      // vsubpd (C_k-D_k2), C_k, D_k2  // this frees up D_k2
  vfmadd213pd ymm0, ymm4, ymm5     // vfmqdd213pd D_k1, 2T, (C_k-D_k2)

  vmovapd    ymm2, ymm1
  vmovapd    ymm1, ymm0

  sub        rax, 32
  jnz        @LoopClenshaw

  // 5. Final Step Evaluation for k = 0 (Requires individual T multiplication)
  vmovdqu     ymm5, [rcx]             // Gather final base coefficients (c_0)
  vsubpd     ymm5, ymm5, ymm2         // ymm5 = c_0 - old_D_k2
  vfmadd213pd ymm1, ymm3, ymm5        // ymm1 = final r = T*D_k2 - old_D_k2 + c_0

  // Inject W = 1.0 NATIVELY IN REGISTERS
  //vmovsd     xmm5, qword ptr [rip + OneScalar]
  //vextractf128 xmm4, ymm1, 1
  //vunpcklpd  xmm4, xmm4, xmm5
  //vinsertf128 ymm1, ymm1, xmm4, 1

  // 6. Direct UNALIGNED streaming write to output vector
  mov         rax, $3FF0000000000000
  vmovupd    [r8], ymm1
  mov        [r8 + 24], rax
  vzeroupper
end;

//------------------------------------------------------------------------------

procedure EvaluateChebyshev1D(
  Data: Pointer;           // RCX -> Continuous Coeff array of 4D vectors [X, Y, Z, W]
  Desc: Pointer;           // RDX -> Packed metadata descriptor record
  X: PDouble;              // R8  -> Destination Scalar Output Pointer (R^)
  T: Double                // XMM3 -> Time variable scalar (Passed natively in XMM3)
); assembler;
asm
  .NOFRAME
  // --------------------------------------------------------------------------
  // Register Allocation Strategy:
  // RCX  = Data pointer (Base of C array)
  // RDX  = Desc pointer
  // R8   = Destination pointer (R)
  // RAX  = Loop offset tracker (i * 32 bytes)
  // XMM3 = T (Original scalar time step)
  // XMM4 = TwoT (2.0 * T)
  // XMM0 = d1 (Clenshaw Recurrence state D_k1) -> Initialized to 0.0
  // XMM1 = d2 (Clenshaw Recurrence state D_k2) -> Initialized to 0.0
  // XMM2 = old_d2 (State tracking placeholder) -> Initialized to 0.0
  // XMM5 = Scratch scalar element
  // --------------------------------------------------------------------------

  // 1. Compute TwoT (2.0 * T) safely into XMM4
  VADDSD     XMM4, XMM3, XMM3           // XMM4 = T + T = 2.0 * T (XMM3 remains pure T)

  // 2. Initialize Clenshaw Recurrence scalar registers to 0.0
  VXORPD     XMM0, XMM0, XMM0           // D_k1 = 0.0
  VXORPD     XMM1, XMM1, XMM1           // D_k2 = 0.0
  VXORPD     XMM2, XMM2, XMM2           // old_D_k2 = 0.0

  // 3. Setup loop counter based on dynamic coefficient count
  MOV        RAX, [RDX + OFFS_NUMCOEF]  // Load NumCoef from [RDX + Offset]
  DEC        RAX
  SHL        RAX, 5                     // Multiply by 32 (each 4D vector block is 32 bytes)

@LoopClenshaw:
  // 4. Gather only the 64-bit X coefficient from the current 4D vector memory block
  VMOVSD     XMM5, [RCX + RAX]          // Loads X component; cleanly zeroes upper bits of XMM5

  // Scalar Clenshaw Formula using FMA3 execution pipelines
  VSUBSD     XMM5, XMM5, XMM2           // XMM5 = C_k - old_D_k2
  VFMADD213SD XMM0, XMM4, XMM5          // XMM0 = (TwoT * D_k1) + (C_k - old_D_k2)

  VMOVAPD    XMM2, XMM1                 // old_D_k2 = D_k2
  VMOVAPD    XMM1, XMM0                 // D_k2 = New calculated D_k

  SUB        RAX, 32                    // Advance backward by exactly 1 vector structure size (32 bytes)
  JNZ        @LoopClenshaw

  // 5. Final Step Evaluation for k = 0
  VMOVSD     XMM5, [RCX]                // Gather final base X coefficient (c_0)
  VSUBSD     XMM5, XMM5, XMM2           // XMM5 = c_0 - old_D_k2
  VFMADD213SD XMM1, XMM3, XMM5          // XMM1 = final result = (T * D_k2) + (c_0 - old_D_k2)

  // 6. Direct 64-bit scalar write to output pointer destination
  VMOVSD     [R8], XMM1

  VZEROUPPER
  // Note: vzeroupper is completely optional here because we never polluted any
  // upper YMM/ZMM lanes throughout this entire scalar sequence.
end;

//-------------------------------------------------------------------------------------------

{$ELSE}

procedure EvaluateChebyshev3D_Full(
// main optimized Pascal function of this library
// Strides of Arrays data format
  Data: Pointer;
  Desc: Pointer;
  S: PState4D;
  T: Double
);
var
  NumComp, NumCoef: Int64;
  StrideLen: NativeUInt;
  InvRadius: Double;

  C0, C1, C2: PDouble;
  TwoT: Double;
  I: Integer;

  // Recurrence registers for Component 0 (X)
  dX0, dX1, dX2: Double;
  eV0, eV1, eV2: Double;

  // Recurrence registers for Component 1 (Y)
  dY0, dY1, dY2: Double;
  eV0_y, eV1_y, eV2_y: Double;

  // Recurrence registers for Component 2 (Z)
  dZ0, dZ1, dZ2: Double;
  eV0_z, eV1_z, eV2_z: Double;
begin
  // Extract metadata using clean array indexing
  NumComp   := PInt64Array(Desc)[IDX_NUMCOMP];
  NumCoef   := PInt64Array(Desc)[IDX_NUMCOEF];
  StrideLen := PInt64Array(Desc)[IDX_ARRAYLEN];
  InvRadius := PDoubleArray(Desc)[IDX_INVRADIUS];

  // Fast explicit layout initialization (Setting W coordinates correctly)
  S.R.X := 0.0; S.R.Y := 0.0; S.R.Z := 0.0; S.R.W := 1.0;
  S.V.X := 0.0; S.V.Y := 0.0; S.V.Z := 0.0; S.V.W := 0.0;

  C0 := PDouble(Data);
  C1 := PDouble(PByte(C0) + StrideLen);
  C2 := PDouble(PByte(C1) + StrideLen);

  TwoT := 2.0 * T;

  case NumComp of
    3: begin
         dX1 := 0.0; dX2 := 0.0; eV1 := 0.0; eV2 := 0.0;
         dY1 := 0.0; dY2 := 0.0; eV1_y := 0.0; eV2_y := 0.0;
         dZ1 := 0.0; dZ2 := 0.0; eV1_z := 0.0; eV2_z := 0.0;

         for I := NumCoef - 1 downto 1 do
         begin
           // --- Component 0 (X) ---
           dX0 := C0[I] + TwoT * dX1 - dX2;
           eV0 := 2.0 * dX1 + TwoT * eV1 - eV2;
           dX2 := dX1; dX1 := dX0;
           eV2 := eV1; eV1 := eV0;

           // --- Component 1 (Y) ---
           dY0 := C1[I] + TwoT * dY1 - dY2;
           eV0_y := 2.0 * dY1 + TwoT * eV1_y - eV2_y;
           dY2 := dY1; dY1 := dY0;
           eV2_y := eV1_y; eV1_y := eV0_y;

           // --- Component 2 (Z) ---
           dZ0 := C2[I] + TwoT * dZ1 - dZ2;
           eV0_z := 2.0 * dZ1 + TwoT * eV1_z - eV2_z;
           dZ2 := dZ1; dZ1 := dZ0;
           eV2_z := eV1_z; eV1_z := eV0_z;
         end;

         S.R.X := C0[0] + T * dX1 - dX2;
         S.V.X := dX1 + T * eV1 - eV2;

         S.R.Y := C1[0] + T * dY1 - dY2;
         S.V.Y := dY1 + T * eV1_y - eV2_y;

         S.R.Z := C2[0] + T * dZ1 - dZ2;
         S.V.Z := dZ1 + T * eV1_z - eV2_z;
       end;

    2: begin
         dX1 := 0.0; dX2 := 0.0; eV1 := 0.0; eV2 := 0.0;
         dY1 := 0.0; dY2 := 0.0; eV1_y := 0.0; eV2_y := 0.0;

         for I := NumCoef - 1 downto 1 do
         begin
           dX0 := C0[I] + TwoT * dX1 - dX2;
           eV0 := 2.0 * dX1 + TwoT * eV1 - eV2;
           dX2 := dX1; dX1 := dX0;
           eV2 := eV1; eV1 := eV0;

           dY0 := C1[I] + TwoT * dY1 - dY2;
           eV0_y := 2.0 * dY1 + TwoT * eV1_y - eV2_y;
           dY2 := dY1; dY1 := dY0;
           eV2_y := eV1_y; eV1_y := eV0_y;
         end;

         S.R.X := C0[0] + T * dX1 - dX2;
         S.V.X := dX1 + T * eV1 - eV2;

         S.R.Y := C1[0] + T * dY1 - dY2;
         S.V.Y := dY1 + T * eV1_y - eV2_y;
       end;

    1: begin
         dX1 := 0.0; dX2 := 0.0; eV1 := 0.0; eV2 := 0.0;

         for I := NumCoef - 1 downto 1 do
         begin
           dX0 := C0[I] + TwoT * dX1 - dX2;
           eV0 := 2.0 * dX1 + TwoT * eV1 - eV2;
           dX2 := dX1; dX1 := dX0;
           eV2 := eV1; eV1 := eV0;
         end;

         S.R.X := C0[0] + T * dX1 - dX2;
         S.V.X := dX1 + T * eV1 - eV2;
       end;
  end;

  // Apply final velocity scaling factor via InvRadius
  S.V.X := S.V.X * InvRadius;
  S.V.Y := S.V.Y * InvRadius;
  S.V.Z := S.V.Z * InvRadius;
  // Setting w coordinates
  S.R.W := 1.0;
  S.V.W := 0.0;
end;

// ----------------------------------------------------------------------------

procedure EvaluateChebyshev3D(
// AI-written PositionOnly version of the optimized procedure
  Data: Pointer;
  Desc: Pointer;
  R: PVec4D;
  T: Double
);
var
  NumComp, NumCoef: Int64;
  StrideLen: NativeUInt;

  C0, C1, C2: PDouble;
  TwoT: Double;
  I: Integer;

  // Recurrence registers for Component 0 (X)
  dX0, dX1, dX2: Double;

  // Recurrence registers for Component 1 (Y)
  dY0, dY1, dY2: Double;

  // Recurrence registers for Component 2 (Z)
  dZ0, dZ1, dZ2: Double;
begin
  // Extract metadata using clean array indexing
  NumComp   := PInt64Array(Desc)[IDX_NUMCOMP];
  NumCoef   := PInt64Array(Desc)[IDX_NUMCOEF];
  StrideLen := PInt64Array(Desc)[IDX_ARRAYLEN];

  // Fast explicit layout initialization (Setting W to 1.0)
  R.X := 0.0; R.Y := 0.0; R.Z := 0.0; R.W := 1.0;

  C0 := PDouble(Data);
  C1 := PDouble(PByte(C0) + StrideLen);
  C2 := PDouble(PByte(C1) + StrideLen);

  TwoT := 2.0 * T;

  case NumComp of
    3: begin
         // Initialize states (Half the variables compared to the full version)
         dX1 := 0.0; dX2 := 0.0;
         dY1 := 0.0; dY2 := 0.0;
         dZ1 := 0.0; dZ2 := 0.0;

         // Backward Clenshaw loop without velocity tracking
         for I := NumCoef - 1 downto 1 do
         begin
           dX0 := C0[I] + TwoT * dX1 - dX2;
           dX2 := dX1; dX1 := dX0;

           dY0 := C1[I] + TwoT * dY1 - dY2;
           dY2 := dY1; dY1 := dY0;

           dZ0 := C2[I] + TwoT * dZ1 - dZ2;
           dZ2 := dZ1; dZ1 := dZ0;
         end;

         // Finalize step I = 0
         R.X := C0[0] + T * dX1 - dX2;
         R.Y := C1[0] + T * dY1 - dY2;
         R.Z := C2[0] + T * dZ1 - dZ2;
       end;

    2: begin
         dX1 := 0.0; dX2 := 0.0;
         dY1 := 0.0; dY2 := 0.0;

         for I := NumCoef - 1 downto 1 do
         begin
           dX0 := C0[I] + TwoT * dX1 - dX2;
           dX2 := dX1; dX1 := dX0;

           dY0 := C1[I] + TwoT * dY1 - dY2;
           dY2 := dY1; dY1 := dY0;
         end;

         R.X := C0[0] + T * dX1 - dX2;
         R.Y := C1[0] + T * dY1 - dY2;
       end;

    1: begin
         dX1 := 0.0; dX2 := 0.0;

         for I := NumCoef - 1 downto 1 do
         begin
           dX0 := C0[I] + TwoT * dX1 - dX2;
           dX2 := dX1; dX1 := dX0;
         end;

         R.X := C0[0] + T * dX1 - dX2;
       end;
  end;
end;

//------------------------------------------------------------------------------

procedure EvaluateChebyshev1D(
// AI-written PositionOnly version of the optimized procedure
  Data: Pointer;
  Desc: Pointer;
  X: PDouble;
  T: Double
);
var
  i, NumCoef: Int64;
  C: PDouble;
  TwoT, d0, d1, d2: Double;
begin
  // Extract metadata using clean array indexing
  NumCoef   := PInt64Array(Desc)[IDX_NUMCOEF];

  C := PDouble(Data);

  TwoT := 2.0 * T;

  // Initialize states
  d1 := 0.0; d2 := 0.0;

  // Backward Clenshaw loop without derivative tracking
  for i := NumCoef - 1 downto 1 do
    begin
     d0 := C[i] + TwoT * d1 - d2;
     d2 := d1;
     d1 := d0;
    end;

  // Finalize step I = 0
  X^ := C[0] + T * d1 - d2;
end;

//------------------------------------------------------------------------------

{$ENDIF}

//------------------------------------------------------------------------------
// Chebyshev ENCODER (offline gap-fill; pure Pascal, common to both builds). Exact
// inverse of EvaluateChebyshevXD: fits N = Length(States) coefficients to N state
// samples taken at the Gauss-Chebyshev nodes of a record's time span. Convention
// matches the decoder exactly -- f(tau)=SUM_j C_j*T_j(tau), tau=(t-Mid)/Radius in
// [-1,1], with C_0 the FULL constant (not halved). Only position (State.R) is
// fitted: the _Full decoder derives velocity as the analytic tau-derivative of these
// same coefficients, so State.V is redundant (carry it for a QC cross-check if you
// like). Output is component-major SoA [X0..Xn, Y0..Yn, Z0..Zn] -- the on-disk /
// spkw02 record layout. This is the verified inverse of the SPK type-2 path.
//
// To splice into an existing BSPX segment the new records MUST continue that body's
// grid: same NumCoef (= degree+1), same INTLEN, Radius = INTLEN/2, and midpoint phase
// Mid_k = T0 + k*INTLEN -- otherwise JPLConv's discontinuity checks fire and the
// runtime RecIndex = Trunc((T-Epoch0)/ValIntv) misaligns.
//------------------------------------------------------------------------------

procedure ChebyshevNodeEpochs(Mid, Radius: Double; NumCoef: Int64; Epochs: PDouble);
var
  k: Int64;
begin
  for k := 0 to NumCoef-1 do
    Epochs[k] := Mid + Radius*Cos((NumCoef-1-k + 0.5)*Pi/NumCoef);   // reversed => ascending in time
end;

procedure ChebyshevEncode(const States: TState4DArray; NumComp: Int64; Coef: PDouble);
var
  j, k, c, N: Int64;
  fac, s: Double;
begin
  N := Length(States);   // number of nodes == number of coefficients (exact interpolation)
  for c := 0 to NumComp-1 do
    for j := 0 to N-1 do
     begin
      s := 0.0;
      for k := 0 to N-1 do
        s := s + States[k].R.cf[c] * Cos(j*(N-1-k + 0.5)*Pi/N);   // T_j evaluated at node k
      if j = 0 then fac := 1.0/N else fac := 2.0/N;
      Coef[c*N + j] := fac*s;
     end;
end;

end.
