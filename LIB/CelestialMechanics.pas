unit CelestialMechanics;

interface

uses
  System.Classes, System.Math, Vec4D;

const
  GAUSS          = 0.01720209895;     //rad/day; fixed by definition
  GAUSS2         = 0.0002959122082855911025;
  G_CONST        = 6.6743E-20; // km^3/(kg*s^2)
  STANDARD_EPOCH = 2451545.0;

  HOUR2SEC       = 3600.0;
  DAY2SEC        = 86400.0;
  WEEK2DAY       = 7.0;
  WEEK2SEC       = WEEK2DAY*DAY2SEC;
  MONTH2DAY      = 30.0;
  MONTH2SEC      = MONTH2DAY*DAY2SEC;
  TAU2SEC        = DAY2SEC/GAUSS;
  YEAR2DAY       = 365.25;
  YEAR2SEC       = YEAR2DAY*DAY2SEC;
  CENTURY2DAY    = 100.0*YEAR2DAY;   // Julian century in days (36525)
  SEC2HOUR       = 1/HOUR2SEC;
  SEC2DAY        = 1/DAY2SEC;
  SEC2WEEK       = 1/WEEK2SEC;
  SEC2MONTH      = 1/MONTH2SEC;
  SEC2TAU        = 1/TAU2SEC;
  SEC2YEAR       = 1/YEAR2SEC;
  DAY2CENTURY    = 1/CENTURY2DAY;

  //AU_M   = 1.4959787070000000E+11;      // fixed by definition
  //AU_KM  = 1.4959787070000000E+08;      // fixed by definition
  CEPS   = 0.4090928042220000;          // J2000 mean obliquity, rad
  AU_KM  = 1.4959787069100000E+08;      // km
  //GM_SUN = 1.3271244004100000E+20;      // m-based units
  GM_SUN = 1.3271244004127942E+11;      // km-based units
  GM_SSB = 1.3289051866661139E+11;
  GM_SSB_STR = '1.3289051866661139E+11';
  CLIGHT = 299792.458;                  // speed of light, km/s; fixed by definition (IAU)
  INV_C2 = 1.0 / (CLIGHT * CLIGHT);     // 1/c^2 (s^2/km^2): the post-Newtonian prefactor

  KM2AU = 1/AU_KM;
  KMPS2AUPDAY = KM2AU*DAY2SEC;
  KMPS2AUPTAU = KM2AU*DAY2SEC/GAUSS;
  AU2KM = AU_KM;
  AUPDAY2KMPS = 1/KMPS2AUPDAY;
  AUPTAU2KMPS = 1/KMPS2AUPTAU;
  AUPD2_TO_KMPS2 = AU_KM / (DAY2SEC*DAY2SEC);   // SBDB nongrav A1..A3 (au/day^2) -> km/s^2  [see NonGravAccel]

  // The per-body zonal harmonics + reference radii + poles used by the integrators live in the small GOblateness
  // table (oblate bodies only), seeded lazily by TBSPXFile.Init from the file's reconciled const records.
  J2_CUTOFF_RADII = 100.0;   // AccelJ2All/AccelJHiAll skip a body's figure term beyond this many radii
                             // (J2 ~ 1/r^4 => sub-mm there); keeps it ~free away from encounters

  SOLAR_MASS  = 1.0;
  JOVIAN_MASS = 1/1047.35;
  EARTH_MASS  = 1/332946.0;
  LUNAR_MASS  = 1/27068510.0;

  TOLERANCE_LEVEL_NEWTON_RAPHSON     = 1.0E-16;         // 1e-18
  MAX_ITERATION_COUNT_NEWTON_RAPHSON = 9999;

type
  //TRKCallback = function(h: Double; r: TVec4D; Tag: Int64): TVec4D; stdcall;

  // JPL/SBDB small-body nongravitational parameters (radial/transverse/normal), used by NonGravAccel.
  // A1/A2/A3 are exactly the Small-Body DB coefficients in au/day^2; a Yarkovsky-only asteroid sets
  // only A2 (the along-track drift) and leaves A1 = A3 = 0.
  TNonGrav = record
    A1, A2, A3: Double;   // radial, transverse, normal   [au/day^2]
    r0:         Double;   // g(r) reference distance       [au]  (SBDB r_0; default 1.0)
    m:          Double;   // g(r) exponent                       (SBDB m;   default 2.0 = asteroid form)
    Active:     Boolean;  // False => contributes nothing (pure gravitational + 1PN run)
  end;

  // One oblate perturber's figure data for the zonal close-encounter terms (see AccelJ2All/AccelJHiAll).
  TJ2Perturber = record
    Idx:        Int64;    // this body's CENTER slot in the perturber array (TargetID 399/599/699); <0 disables
    J2, J3, J4: Double;   // zonal harmonic coefficients (J3/J4 used only by the opt-in AccelJHiAll)
    Req:        Double;   // equatorial reference radius the J_n are normalised to [km]
    Pole:       TVec4D;   // unit spin axis in the ICRF integration frame
  end;

  // Canonical per-body oblateness figure, keyed by NAIF centre id -- the constant store CelestialMechanics
  // owns (seeded by TBSPXFile.Init from the file's reconciled const records, oblate bodies only). GJ2 below is
  // the descriptor-indexed working set the hot loop uses, assembled from this table
  // at scene load via AddGJ2.
  TOblateness = record
    BodyID:     Int64;    // NAIF centre id (10=Sun, 399=Earth, 499/599/699/799/899)
    J2, J3, J4: Double;
    Req:        Double;
    Pole:       TVec4D;   // ICRF unit spin axis (built from pole RA/Dec by SetOblateness)
  end;

  TBodyConstant = record   // one row of the lazy default table (CelestialMechanics.BodyConstants)
    NAIFCode:        Int64;       // NAIF body/centre code (asteroids appear under BOTH 2000000+N and 20000000+N)
    Name:            AnsiString;
    GM:              Double;      // km^3/s^2 (0 if no DE440 default)
    Req:             Double;      // equatorial radius, km (0 if none)
    J2, J3, J4:      Double;      // zonal harmonics (0 if none)
    PoleRA, PoleDec: Double;      // ICRF pole, deg (0 if none)
    PoleW, PoleRARate, PoleDecRate, PoleWRate: Double;   // prime meridian W0 (deg) + pole/PM rates (deg/century, deg/day)
  end;
  PBodyConstant = ^TBodyConstant;

  TAccelCallback = function(Index: Int64; const S: TState4D; P: PState4D; nPert: NativeInt): TVec4D;   // P = perturber states (raw ptr + count, as NewtonAccel holds them)
  PAccelCallback = ^TAccelCallback;
  TAccelCallbacks = array of TAccelCallback;
  PAccelCallbacks = ^TAccelCallbacks;

  TDoubleArrays = array of TDynDoubleArray;   // per-node arrays of scalars (a column of the packed perturber SoA)

  // Packed perturber SoA -- the "contract" the PN force kernels consume. TBSPXFile owns the raw ephemeris data and
  // fills the state columns (Rx..GM) via PackPerturbers; this unit fills nothing here yet (the aP precompute columns
  // arrive with the SoA-based AccelPN) and reads all of them. Every column is per node: Rx[n][k] = the k-th real
  // perturber's x-position at integration node n. Count = real perturbers per node (holes already compacted out).
  TPerturberSoA = record
    Count: Int64;
    Rx, Ry, Rz, Vx, Vy, Vz, GM: TDoubleArrays;   // raw perturber states  -- filled by TBSPXFile.PackPerturbers
    aX, aY, aZ, U: TDoubleArrays;                 // per-perturber Newtonian accel a_j (aX/aY/aZ) + potential U_j -- filled by PerturberPN_SoA
  end;
  PPerturberSoA = ^TPerturberSoA;

  procedure Leapfrog2(dt: Double; a: TVec4DArray; S, P: TState4DArray);
  procedure McLachlan4(dt: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays);
//  procedure Yoshida6(dt: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays);   // RETIRED (dominated by McLachlan4); impl kept as reference, commented out below
  procedure BlanesMoanMcLachlan6(dt: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays);
  //procedure RungeKutta5(dt: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays);
  function DormandPrince54(dt: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays; TmpR, TmpV, TmpA: TVec4DArray): Double;
  function DormandPrince87(dt: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays; TmpR, TmpV, TmpA: TVec4DArray): Double;
  function GaussRadau15(var dt: Double; dt_last: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays; B, E, Br, Er: TVec4DArrays; csx, csv: TVec4DArray): Boolean;
  function GaussRadau15_PN(var dt: Double; dt_last: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays; B, E, Br, Er: TVec4DArrays; csx, csv: TVec4DArray; Pert: PPerturberSoA): Boolean;
  function KeplerUniv(Time, MU: Double; const Input: TState4D; var Output: TState4D): Boolean;
  function A1PN(S: TState4D; P: TState4DArray): TVec4D;
  function NonGravAccel(const Si, Sun: TState4D; const NG: TNonGrav): TVec4D;
  function OblatenessJ2(const Si, Body: TState4D; J2, Rbody: Double; const Pole: TVec4D): TVec4D;
  function OblatenessJHi(const Si, Body: TState4D; J3, J4, Rbody: Double; const Pole: TVec4D): TVec4D;
  function AccelJ2All(const Si: TState4D; const P: TState4DArray): TVec4D;
  function AccelJHiAll(const Si: TState4D; const P: TState4DArray): TVec4D;
  function  DE440OblatenessDefault(BodyID: Int64; out J2, J3, J4, Req, PoleRA, PoleDec: Double): Boolean;  // the single, pristine source of the DE440 figure literals (seeds GOblateness AND BSPXFile's file defaults)
  function  FindOblateness(BodyID: Int64): Int64;   // index in GOblateness, or -1
  procedure SetOblateness(BodyID: Int64; J2, J3, J4, Req, PoleRA, PoleDec: Double);  // upsert (BSPXFile.Open); pole RA/Dec in deg
  procedure ClearGJ2;                               // reset the descriptor-indexed working set
  function  AddGJ2(BodyID, Idx: Int64): Boolean;    // append a GJ2 entry from GOblateness[BodyID] (Idx = perturber slot); True if a figure exists
  procedure InitBodyConstants;                          // populate the merged default table on first use (idempotent; NOT run at unit init)
  function  BodyConstIndex(NAIFCode: Int64): Int64;     // index into BodyConstants, or -1; auto-inits the table
  function  BodyConst(NAIFCode: Int64): PBodyConstant;  // pointer to the entry, or nil; auto-inits
  function  BodyName(NAIFCode: Int64): AnsiString;      // default name, or '<unknown target code>'
  function  BodyGM(NAIFCode: Int64): Double;            // default GM (km^3/s^2), or 0
var
  ERROR_TOLERANCE_DP: Double = 1.0E-10;
  // Nongravitational-force hook consumed by GaussRadau15_PN -- PER INTEGRAND BODY: GNonGrav[i] holds body
  // i's Yarkovsky coefficients (a fitted per-object property, like the IC, unlike the per-perturber J2).
  // The caller sizes/populates it (test: 1 element; viewer: from IntForm's per-body array); an element
  // left Active=False, or a body with no element (i > High(GNonGrav)), contributes nothing. GSunIdx is
  // the Sun's slot in the perturber arrays P[n] (shared by all bodies -- it's a perturber, not per-object).
  GNonGrav: array of TNonGrav;
  GSunIdx:  Int64 = 0;
  // Zonal-J2 close-encounter hook consumed by GaussRadau15_PN (folded into the two AccelPN call sites).
  // GOblateness is the canonical per-body figure table (default DE440, overwritten by BSPXFile.Open). At
  // scene load the caller does ClearGJ2 then AddGJ2(TargetID, idx) per descriptor to assemble GJ2 -- the
  // descriptor-indexed working set the hot loop reads -- then GJ2Active := True. Left inactive the
  // integrator is bit-for-bit its original self. GJ2 applies to every integrated body (position-only
  // geometry, swarm-safe); nongrav is per-body via GNonGrav[i].
  GJ2Active: Boolean = False;
  GJHiActive: Boolean = False;         // J3/J4 higher-zonal opt-in (IAS15_PN only; see AccelJHiAll)

  PN_SoA_MaxDiff: Double = 0.0;        // PN_SOA_VALIDATE: running max |AccelPN_SoA - AccelPN| component diff (expect ~0; the SoA port is bit-identical)
  GOblateness: array of TOblateness;   // canonical per-body figure table (default DE440, file-overwritable)
  GJ2: array of TJ2Perturber;          // descriptor-indexed working set (assembled from GOblateness at scene load)
  AccelCallbacks: PAccelCallbacks = nil;
  BodyConstants: array of TBodyConstant;   // lazy merged default table (name+GM+figure); Open fills bspx holes from it; freed in finalization. See InitBodyConstants.

implementation

{.$DEFINE PN_SOA_VALIDATE}   // Validation scaffold (leading '.' disables it): dual-computes SoA vs AoS 1PN accel, shows max|diff| as PNdiff. Verified: scalar SoA 0e0, AVX2 Newtonian ~1.7e-20, 1PN kernel ~4.4e-20, aP precompute kernel ~3.2e-20. Re-enable to re-check after edits.
{$DEFINE PN1_ASM}           // AVX2 1PN bulk: defined -> AccelPN1_SoA_AVX2core (assembly); undefined (leading '.') -> the equivalent raw-scalar Pascal blueprint (instant fallback if the asm needs a fix)
{$DEFINE PPN_ASM}           // AVX2 aP precompute (the O(N^2) hotspot): defined -> PerturberPN_SoA_AVX2core (assembly); undefined (leading '.') -> scalar Pascal fallback

{$IFDEF AVX2}
// ============================================================================================
//  AVX2/FMA3 batch acceleration kernel (merged from the former IntegratorsAVX2 sidecar). Computes the
//  whole body array's Newtonian acceleration in one call, SIMD across 4 bodies. Compiled ONLY in the
//  AVX2 build; the AVX2 integrator bodies below call NewtonAccel instead of an inline loop.
// ============================================================================================
const
  AVX_HALF:   Double = 0.5;
  AVX_ONEPT5: Double = 1.5;

procedure NewtonAccel_AVX2core(S, P, A: Pointer; nQuadBodies, nPert: NativeInt);
// nQuadBodies MUST be a positive multiple of 4. Processes 4 bodies per pass, SIMD across bodies.
// Win64: rcx=S rdx=P r8=A r9=nQuadBodies  [rsp+28h]=nPert.  Layout: TState4D=128B, R@0, GM@72; TVec4D=32B.
asm
  .NOFRAME
  mov     r10, qword ptr [rsp+28h]        // r10 = nPert  (read BEFORE moving rsp)
  sub     rsp, 80h
  vmovups [rsp+00h], xmm6
  vmovups [rsp+10h], xmm7
  vmovups [rsp+20h], xmm8
  vmovups [rsp+30h], xmm9
  vmovups [rsp+40h], xmm10
  vmovups [rsp+50h], xmm11
  vmovups [rsp+60h], xmm12
  vmovups [rsp+70h], xmm13

  vbroadcastsd ymm10, qword ptr [AVX_HALF]
  vbroadcastsd ymm11, qword ptr [AVX_ONEPT5]
  shr     r9, 2                           // r9 = body-quads

@BodyQuad:
  // load 4 bodies' R and transpose AoS -> SoA (Xv=ymm0, Yv=ymm1, Zv=ymm2)
  vmovupd ymm6, [rcx+000h]
  vmovupd ymm7, [rcx+080h]
  vmovupd ymm8, [rcx+100h]
  vmovupd ymm9, [rcx+180h]
  vunpcklpd ymm0, ymm6, ymm7
  vunpckhpd ymm1, ymm6, ymm7
  vunpcklpd ymm6, ymm8, ymm9
  vunpckhpd ymm7, ymm8, ymm9
  vperm2f128 ymm2, ymm0, ymm6, 31h
  vperm2f128 ymm0, ymm0, ymm6, 20h
  vperm2f128 ymm1, ymm1, ymm7, 20h

  vxorpd  ymm3, ymm3, ymm3
  vxorpd  ymm4, ymm4, ymm4
  vxorpd  ymm5, ymm5, ymm5

  mov     r11, rdx
  mov     rax, r10
@Pert:
  vmovsd  xmm12, [r11+48h]                // GM
  vxorpd  xmm13, xmm13, xmm13
  vucomisd xmm12, xmm13
  jbe     @NextPert                       // skip GM<=0 (and NaN)
  vbroadcastsd ymm6, [r11+000h]
  vbroadcastsd ymm7, [r11+008h]
  vbroadcastsd ymm8, [r11+010h]
  vsubpd  ymm6, ymm6, ymm0                // dx
  vsubpd  ymm7, ymm7, ymm1                // dy
  vsubpd  ymm8, ymm8, ymm2                // dz
  vmulpd  ymm9, ymm6, ymm6
  vfmadd231pd ymm9, ymm7, ymm7
  vfmadd231pd ymm9, ymm8, ymm8            // r^2
  vcvtpd2ps  xmm12, ymm9                  // rinv: seed then 2 Newton-Raphson (vs the double r^2)
  vrsqrtps   xmm12, xmm12
  vcvtps2pd  ymm12, xmm12
  vmulpd  ymm13, ymm12, ymm12
  vmulpd  ymm13, ymm13, ymm9
  vfnmadd213pd ymm13, ymm10, ymm11        // 1.5 - 0.5*r^2*y^2
  vmulpd  ymm12, ymm12, ymm13
  vmulpd  ymm13, ymm12, ymm12
  vmulpd  ymm13, ymm13, ymm9
  vfnmadd213pd ymm13, ymm10, ymm11
  vmulpd  ymm12, ymm12, ymm13             // y2 = 1/sqrt(r^2)
  vmulpd  ymm13, ymm12, ymm12
  vmulpd  ymm12, ymm13, ymm12             // rinv^3
  vbroadcastsd ymm13, [r11+048h]          // GM
  vmulpd  ymm12, ymm12, ymm13             // w = GM * rinv^3
  vfmadd231pd ymm3, ymm6, ymm12           // ax += dx*w
  vfmadd231pd ymm4, ymm7, ymm12
  vfmadd231pd ymm5, ymm8, ymm12
@NextPert:
  add     r11, 80h
  dec     rax
  jnz     @Pert

  // transpose accel SoA(ax,ay,az,0) -> AoS and store A[i..i+3]
  vxorpd  ymm6, ymm6, ymm6
  vunpcklpd ymm7,  ymm3, ymm4
  vunpckhpd ymm8,  ymm3, ymm4
  vunpcklpd ymm9,  ymm5, ymm6
  vunpckhpd ymm12, ymm5, ymm6
  vperm2f128 ymm13, ymm7, ymm9,  20h
  vmovupd [r8+000h], ymm13
  vperm2f128 ymm13, ymm8, ymm12, 20h
  vmovupd [r8+020h], ymm13
  vperm2f128 ymm13, ymm7, ymm9,  31h
  vmovupd [r8+040h], ymm13
  vperm2f128 ymm13, ymm8, ymm12, 31h
  vmovupd [r8+060h], ymm13

  add     rcx, 200h                       // 4 * 128
  add     r8,  80h                        // 4 * 32
  dec     r9
  jnz     @BodyQuad

  vmovups xmm6,  [rsp+00h]
  vmovups xmm7,  [rsp+10h]
  vmovups xmm8,  [rsp+20h]
  vmovups xmm9,  [rsp+30h]
  vmovups xmm10, [rsp+40h]
  vmovups xmm11, [rsp+50h]
  vmovups xmm12, [rsp+60h]
  vmovups xmm13, [rsp+70h]
  add     rsp, 80h
  vzeroupper
end;

procedure NewtonAccel(S, P, A: Pointer; nBodies, nPert: NativeInt);
// Bulk (multiple-of-4) via the asm core; the 0..3 remainder via the reference loop.
var
  quad, i, j: NativeInt;
  Si, Pj: PState4D;
  Ai: PVec4D;
  GM: Double;
begin
  quad := nBodies and (not NativeInt(3));
  if quad > 0 then NewtonAccel_AVX2core(S, P, A, quad, nPert);
  for i := quad to nBodies-1 do
  begin
    Si := PState4D(PByte(S) + i*SizeOf(TState4D));
    Ai := PVec4D (PByte(A) + i*SizeOf(TVec4D));
    FillChar(Ai^, SizeOf(TVec4D), 0);
    for j := 0 to nPert-1 do
    begin
      Pj := PState4D(PByte(P) + j*SizeOf(TState4D));
      GM := Pj^.GM;
      if GM > 0.0 then Ai^ := Ai^ + (Pj^.R - Si^.R).InvCubeScale3D(GM);
    end;
  end;
  // Extra per-body acceleration term (e.g. thrust from an AccForm), added after the gravitational sum.
  // Assigned() tests the callback VALUE (@element would be the slot address, never nil). Covers all bodies,
  // so it correctly applies to the AVX2-core quad + the scalar remainder above.
  if AccelCallbacks<>nil then
  for i:=0 to nBodies-1 do if Assigned(AccelCallbacks^[i]) then
   begin
    Si := PState4D(PByte(S) + i*SizeOf(TState4D));
    Ai := PVec4D (PByte(A) + i*SizeOf(TVec4D));
    Ai^ := Ai^ + AccelCallbacks^[i](i, Si^, PState4D(P), nPert);
   end;
end;

procedure NewtonAccelJ2(S, P, A: Pointer; nBodies, nPert: NativeInt);
// NewtonAccel + per-body zonal-J2 (oblateness), for the adaptive integrators' AVX2 branch (DP54/DP87
// stages). Same pointer signature as NewtonAccel, so the stage call sites differ only by name. The
// far-field gate (J2_CUTOFF_RADII, no sqrt) keeps it ~free away from a planet; GJ2Active is the master
// switch. Symplectic integrators keep calling NewtonAccel directly -- they cannot resolve close
// encounters and a per-step J2 kick would break their symplecticity.
var
  i, k: NativeInt;
  Si, Bk: PState4D; Ai: PVec4D;
  d: TVec4D; d2: Double;
begin
  NewtonAccel(S, P, A, nBodies, nPert);
  if not GJ2Active then Exit;
  for i := 0 to nBodies-1 do
  begin
    Si := PState4D(PByte(S) + i*SizeOf(TState4D));
    Ai := PVec4D (PByte(A) + i*SizeOf(TVec4D));
    for k := 0 to High(GJ2) do
      if (GJ2[k].Idx >= 0) and (GJ2[k].Idx < nPert) then
      begin
        Bk := PState4D(PByte(P) + GJ2[k].Idx*SizeOf(TState4D));
        d  := Si^.R - Bk^.R;  d2 := d or d;
        if d2 < Sqr(J2_CUTOFF_RADII * GJ2[k].Req) then
          Ai^ := Ai^ + OblatenessJ2(Si^, Bk^, GJ2[k].J2, GJ2[k].Req, GJ2[k].Pole);
      end;
  end;
end;
{$ENDIF}

procedure Leapfrog2(dt: Double; a: TVec4DArray; S, P: TState4DArray);
{$IFDEF AVX2}
// 2nd-order FSAL kick-drift-kick leapfrog. P is a SINGLE perturber snapshot (one accel eval/step).
// dt=0 => first-step init: only (re)fill the acceleration array, don't advance.
var
  i, n, np: Int64;
  hdt: Double;
  b: Boolean;
begin
  b   := (dt <> 0.0);
  hdt := 0.5*dt;
  n   := Length(S); np := Length(P);
  if b then
    for i := 0 to n-1 do S[i].V := S[i].V + a[i]*hdt;      // half-kick with the OLD acceleration
  NewtonAccel(Pointer(S), Pointer(P), Pointer(a), n, np);  // acceleration at the current position
  if not b then Exit;                                       // first call: array primed, done
  for i := 0 to n-1 do
  begin
    S[i].R := S[i].R + S[i].V*dt;                           // drift
    S[i].V := S[i].V + a[i]*hdt;                            // second half-kick (FSAL: a reused next step)
  end;
end;
{$ELSE}
// Simple 2th-Order FSAL Integrator (kick-drift-kick leapfrog / Position Verlet)
// dt = time elapsed since accelerations were last computed
// a  = array of accelerations
// v  = array of half-step velocities (comes as a parameter so that we won't have to allocate it every single time the procedure is called)
// S  = array of last computed states (must have the same number of elements as a)
// P  = array of perturber states (updated before the call of this procedure)
// dt = 0.0 means it's the first step, we only need to initialize the acceleration array
//           (the procedure needs to be called once again afterwards once the new perturber states have been computed,
//            but this time with the actual dt value)
var
  GM, hdt: Double;
  i, j: Int64;
  b: Boolean;
  rvec: TVec4D;
begin
  b:=(dt <> 0.0);                        // initialization
  hdt:=0.5*dt;                           // we'll need this value twice
  if b then                              // only if it's not the first step
  for i:=Low(S) to High(S) do            // for each body
  S[i].V:=S[i].V + hdt*a[i];             // compute half-step velocities
                                         // compute new accelerations
  for i:=Low(S) to High(S) do            // for each body
   begin
    FillChar(a[i], 3*SizeOf(Double), 0); // we don't need to touch W
    rvec:=S[i].R;
    for j:=Low(P) to High(P) do          // for each perturber
     begin
      GM:=P[j].GM;
      if GM > 0.0 then                   // only if they are massive
      a[i] := a[i] + (P[j].R - rvec).InvCubeScale3D(GM);
     end;
   end;

  if not b then Exit;                    // if it was the first call, we are finished for now

  for i:=Low(S) to High(S) do            // for each body
   begin
    S[i].R := S[i].R + S[i].V*dt;          // update position
    S[i].V := S[i].V + hdt*a[i];           // update velocity
   end;
end;
{$ENDIF}

procedure McLachlan4(dt: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays);
{$IFDEF AVX2}
const
  B1 =  0.061758858135626325; B2 = 0.338978022453621400; B3 = 0.614793731877073300;
  B4 = -0.140530130738018260; B5 = 0.125000000000000000;
  A1 =  0.205177661542286380; A2 = 0.403075631662795300; A3 = -0.120928236104595200;
  A4 =  0.512674942899513520;
var
  i, n, np: Int64;
begin
  if dt = 0.0 then Exit;
  n := Length(S); np := Length(P[0]);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B1*dt); S[i].R := S[i].R + S[i].V*(A1*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[3]), Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B2*dt); S[i].R := S[i].R + S[i].V*(A2*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[2]), Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B3*dt); S[i].R := S[i].R + S[i].V*(A3*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[1]), Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B4*dt); S[i].R := S[i].R + S[i].V*(A4*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[0]), Pointer(a), n, np);
  for i := 0 to n-1 do   S[i].V := S[i].V + a[i]*(B5*dt);
end;
{$ELSE}
// 4th-Order McLachlan FSAL Integrator
// a array can be filled before the first call using a Leapfrog call with dt=0.0
const
  { Splitting step weights }
  B1 =  0.061758858135626325;
  B2 =  0.338978022453621400;
  B3 =  0.614793731877073300;
  B4 = -0.140530130738018260;
  B5 =  0.125000000000000000;
  A1 =  0.205177661542286380;
  A2 =  0.403075631662795300;
  A3 = -0.120928236104595200;
  A4 =  0.512674942899513520;
var
  i, j: Int64;
  GM: Double;
begin
  if dt=0.0 then Exit;
  for i:=Low(S) to High(S) do
   begin
    if dt <> 0.0 then begin
// step 0
    S[i].V := S[i].V + a[i]   * (B1 * dt);
    S[i].R := S[i].R + S[i].V * (A1 * dt);

// step 1 (index 3)
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[3]) to High(P[3]) do
     begin
      GM := P[3][j].GM;
      if GM > 0.0 then a[i]:= a[i] + (P[3][j].R - S[i].R).InvCubeScale3D(GM);
     end;
    S[i].V := S[i].V + a[i]   * (B2 * dt);
    S[i].R := S[i].R + S[i].V * (A2 * dt);

// step 2 (index 2)
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[2]) to High(P[2]) do
     begin
      GM := P[2][j].GM;
      if GM > 0.0 then a[i]:= a[i] + (P[2][j].R - S[i].R).InvCubeScale3D(GM);
     end;
    S[i].V := S[i].V + a[i]   * (B3 * dt);
    S[i].R := S[i].R + S[i].V * (A3 * dt);

// step 3 (index 1)
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[1]) to High(P[1]) do
     begin
      GM := P[1][j].GM;
      if GM > 0.0 then a[i]:= a[i] + (P[1][j].R - S[i].R).InvCubeScale3D(GM);
     end;
    S[i].V := S[i].V + a[i]   * (B4 * dt);
    S[i].R := S[i].R + S[i].V * (A4 * dt);

    end;
// step 4 (index 0) (last step)
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[0]) to High(P[0]) do
     begin
      GM := P[0][j].GM;
      if GM > 0.0 then a[i]:= a[i] + (P[0][j].R - S[i].R).InvCubeScale3D(GM);
     end;
    S[i].V := S[i].V + a[i] * (B5 * dt);

   end;
end;
{$ENDIF}

(*  Yoshida6 RETIRED -- testing showed it is consistently dominated by the cheaper McLachlan4 (Yoshida's
    6th order carries a large error constant). Kept as a reference implementation only, NOT compiled.
    It also still has the +-0.16*dt perturber node-overread gap (its cumulative-drift nodes overshoot [0,1]).
procedure Yoshida6(dt: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays);
{$IFDEF AVX2}
const
  // Yoshida (1990) 6th-order symmetric composition, Solution A (palindromic; sum B = sum A = 1).
  // Replaces the earlier constants, which were not actually 6th order (see accuracy test).
  B1 =  0.392256805238780; B2 =  0.510043411918459; B3 = -0.471053385409757;
  B4 =  0.068752168252518; B5 =  0.068752168252518; B6 = -0.471053385409757;
  B7 =  0.510043411918459; B8 =  0.392256805238780;
  A1 =  0.784513610477560; A2 =  0.235573213359357; A3 = -1.17767998417887;
  A4 =  1.315184320683906; A5 = -1.17767998417887;  A6 =  0.235573213359357;
  A7 =  0.784513610477560;
var
  i, n, np: Int64;
begin
  if dt = 0.0 then Exit;
  n := Length(S); np := Length(P[0]);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B1*dt); S[i].R := S[i].R + S[i].V*(A1*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[6]), Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B2*dt); S[i].R := S[i].R + S[i].V*(A2*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[5]), Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B3*dt); S[i].R := S[i].R + S[i].V*(A3*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[4]), Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B4*dt); S[i].R := S[i].R + S[i].V*(A4*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[3]), Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B5*dt); S[i].R := S[i].R + S[i].V*(A5*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[2]), Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B6*dt); S[i].R := S[i].R + S[i].V*(A6*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[1]), Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B7*dt); S[i].R := S[i].R + S[i].V*(A7*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[0]), Pointer(a), n, np);
  for i := 0 to n-1 do   S[i].V := S[i].V + a[i]*(B8*dt);
end;
{$ELSE}
//6th-Order Blanes-Moan-McLachlan FSAL Integrator
const
  { Yoshida (1990) 6th-order symmetric composition, Solution A (palindromic; sum B = sum A = 1).
    Replaces the earlier constants, which were not actually 6th order (see accuracy test). }
  B1 =  0.392256805238780;
  B2 =  0.510043411918459;
  B3 = -0.471053385409757;
  B4 =  0.068752168252518;
  B5 =  0.068752168252518;
  B6 = -0.471053385409757;
  B7 =  0.510043411918459;
  B8 =  0.392256805238780;
  A1 =  0.784513610477560;
  A2 =  0.235573213359357;
  A3 = -1.17767998417887;
  A4 =  1.315184320683906;
  A5 = -1.17767998417887;
  A6 =  0.235573213359357;
  A7 =  0.784513610477560;
var
  i, j: Int64;
  GM: Double;
begin
  if dt=0.0 then Exit;
  for i:=Low(S) to High(S) do
   begin
    if dt <> 0.0 then begin
// step 0
    S[i].V := S[i].V + a[i]   * (B1 * dt);
    S[i].R := S[i].R + S[i].V * (A1 * dt);

// step 1 (index 6)
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[6]) to High(P[6]) do
     begin
      GM := P[6][j].GM;
      if GM > 0.0 then a[i]:= a[i] + (P[6][j].R - S[i].R).InvCubeScale3D(GM);
     end;
    S[i].V := S[i].V + a[i]   * (B2 * dt);
    S[i].R := S[i].R + S[i].V * (A2 * dt);

// step 2 (index 5)
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[5]) to High(P[5]) do
     begin
      GM := P[5][j].GM;
      if GM > 0.0 then a[i]:= a[i] + (P[5][j].R - S[i].R).InvCubeScale3D(GM);
     end;
    S[i].V := S[i].V + a[i]   * (B3 * dt);
    S[i].R := S[i].R + S[i].V * (A3 * dt);

// step 3 (index 4)
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[4]) to High(P[4]) do
     begin
      GM := P[4][j].GM;
      if GM > 0.0 then a[i]:= a[i] + (P[4][j].R - S[i].R).InvCubeScale3D(GM);
     end;
    S[i].V := S[i].V + a[i]   * (B4 * dt);
    S[i].R := S[i].R + S[i].V * (A4 * dt);

// step 4 (index 3)
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[3]) to High(P[3]) do
     begin
      GM := P[3][j].GM;
      if GM > 0.0 then a[i]:= a[i] + (P[3][j].R - S[i].R).InvCubeScale3D(GM);
     end;
    S[i].V := S[i].V + a[i]   * (B5 * dt);
    S[i].R := S[i].R + S[i].V * (A5 * dt);

// step 5 (index 2)
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[2]) to High(P[2]) do
     begin
      GM := P[2][j].GM;
      if GM > 0.0 then a[i]:= a[i] + (P[2][j].R - S[i].R).InvCubeScale3D(GM);
     end;
    S[i].V := S[i].V + a[i]   * (B6 * dt);
    S[i].R := S[i].R + S[i].V * (A6 * dt);

// step 6 (index 1)
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[1]) to High(P[1]) do
     begin
      GM := P[1][j].GM;
      if GM > 0.0 then a[i]:= a[i] + (P[1][j].R - S[i].R).InvCubeScale3D(GM);
     end;
    S[i].V := S[i].V + a[i]   * (B7 * dt);
    S[i].R := S[i].R + S[i].V * (A7 * dt);

// step 7 (index 0) (last step)
    end;
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[0]) to High(P[0]) do
     begin
      GM := P[0][j].GM;
      if GM > 0.0 then a[i]:= a[i] + (P[0][j].R - S[i].R).InvCubeScale3D(GM);
     end;
    S[i].V := S[i].V + a[i] * (B8 * dt);

   end;
end;
{$ENDIF}
*)

procedure BlanesMoanMcLachlan6(dt: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays);
{$IFDEF AVX2}
const
  B1  =  0.041464998518262400; B2  =  0.19812867191806700;  B3  = -0.040006192104153300;
  B4  =  0.075253984301580700; B5  = -0.011511387420687900; B6  =  0.23666992478693110;
  B7  =  0.23666992478693110;  B8  = -0.011511387420687900; B9  =  0.075253984301580700;
  B10 = -0.040006192104153300; B11 =  0.19812867191806700;  B12 =  0.041464998518262400;
  A1  =  0.12322977594627100;  A2  =  0.29055379779955800;  A3  = -0.12704921262541700;
  A4  = -0.24633176106207500;  A5  =  0.35720887279592800;  A6  =  0.2047770542914700;
  A7  =  0.35720887279592800;  A8  = -0.24633176106207500;  A9  = -0.12704921262541700;
  A10 =  0.29055379779955800;  A11 =  0.12322977594627100;
var
  i, n, np: Int64;
begin
  if dt = 0.0 then Exit;
  n := Length(S); np := Length(P[0]);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B1*dt); S[i].R := S[i].R + S[i].V*(A1*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[10]), Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B2*dt);  S[i].R := S[i].R + S[i].V*(A2*dt);  end;
  NewtonAccel(Pointer(S), Pointer(P[9]),  Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B3*dt);  S[i].R := S[i].R + S[i].V*(A3*dt);  end;
  NewtonAccel(Pointer(S), Pointer(P[8]),  Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B4*dt);  S[i].R := S[i].R + S[i].V*(A4*dt);  end;
  NewtonAccel(Pointer(S), Pointer(P[7]),  Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B5*dt);  S[i].R := S[i].R + S[i].V*(A5*dt);  end;
  NewtonAccel(Pointer(S), Pointer(P[6]),  Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B6*dt);  S[i].R := S[i].R + S[i].V*(A6*dt);  end;
  NewtonAccel(Pointer(S), Pointer(P[5]),  Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B7*dt);  S[i].R := S[i].R + S[i].V*(A7*dt);  end;
  NewtonAccel(Pointer(S), Pointer(P[4]),  Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B8*dt);  S[i].R := S[i].R + S[i].V*(A8*dt);  end;
  NewtonAccel(Pointer(S), Pointer(P[3]),  Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B9*dt);  S[i].R := S[i].R + S[i].V*(A9*dt);  end;
  NewtonAccel(Pointer(S), Pointer(P[2]),  Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B10*dt); S[i].R := S[i].R + S[i].V*(A10*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[1]),  Pointer(a), n, np);
  for i := 0 to n-1 do begin S[i].V := S[i].V + a[i]*(B11*dt); S[i].R := S[i].R + S[i].V*(A11*dt); end;
  NewtonAccel(Pointer(S), Pointer(P[0]),  Pointer(a), n, np);
  for i := 0 to n-1 do   S[i].V := S[i].V + a[i]*(B12*dt);
end;
{$ELSE}
// 6th-order symplectic Runge-Kutta-Nystrom — Blanes & Moan (2002), method SRKN_11^6: 11 force
// evaluations per step, BAB composition, time-reversible. More evaluations than Yoshida6 (7)
// but a far smaller error constant, so it stays accurate at much larger dt — favourable on smooth
// high-accuracy runs. FSAL: 'a' must be initialised by a Leapfrog2(dt=0) call and carries the
// end-of-step (= next start) acceleration. Coefficients verified to give clean 6th-order
// convergence with ~1e-14 energy drift on a Kepler orbit. NEWTONIAN, position-only force.
//
// 12 symmetric kick weights B1..B12 (= b[0..11]) and 11 drift weights A1..A11 (= a[0..10]; the
// 12th drift is 0). The 11 force evaluations are at nodes c1..c11 (cumulative drift sums); the
// caller must supply perturber snapshots there as P[10]=c1, P[9]=c2, ... P[0]=c11(=step end):
//   c1 =0.12322977594627100  c2 =0.41378357374582900  c3 =0.28673436112041200
//   c4 =0.04040260005833700  c5 =0.39761147285426500  c6 =0.60238852714573500
//   c7 =0.95959739994166300  c8 =0.71326563887958800  c9 =0.58621642625417100
//   c10=0.87677022405372900  c11=1.0
const
  B1  =  0.041464998518262400; B2  =  0.19812867191806700;  B3  = -0.040006192104153300;
  B4  =  0.075253984301580700; B5  = -0.011511387420687900; B6  =  0.23666992478693110;
  B7  =  0.23666992478693110;  B8  = -0.011511387420687900; B9  =  0.075253984301580700;
  B10 = -0.040006192104153300; B11 =  0.19812867191806700;  B12 =  0.041464998518262400;
  A1  =  0.12322977594627100;  A2  =  0.29055379779955800;  A3  = -0.12704921262541700;
  A4  = -0.24633176106207500;  A5  =  0.35720887279592800;  A6  =  0.2047770542914700;
  A7  =  0.35720887279592800;  A8  = -0.24633176106207500;  A9  = -0.12704921262541700;
  A10 =  0.29055379779955800;  A11 =  0.12322977594627100;
var
  i, j: Int64;
  GM: Double;
begin
  if dt=0.0 then Exit;
  for i:=Low(S) to High(S) do
   begin
// kick 1 (FSAL incoming acceleration) + drift 1
    S[i].V := S[i].V + a[i]   * (B1 * dt);
    S[i].R := S[i].R + S[i].V * (A1 * dt);

// node c1 -> P[10]
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[10]) to High(P[10]) do begin GM:=P[10][j].GM; if GM>0.0 then a[i]:=a[i]+(P[10][j].R-S[i].R).InvCubeScale3D(GM); end;
    S[i].V := S[i].V + a[i]   * (B2 * dt);
    S[i].R := S[i].R + S[i].V * (A2 * dt);

// node c2 -> P[9]
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[9]) to High(P[9]) do begin GM:=P[9][j].GM; if GM>0.0 then a[i]:=a[i]+(P[9][j].R-S[i].R).InvCubeScale3D(GM); end;
    S[i].V := S[i].V + a[i]   * (B3 * dt);
    S[i].R := S[i].R + S[i].V * (A3 * dt);

// node c3 -> P[8]
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[8]) to High(P[8]) do begin GM:=P[8][j].GM; if GM>0.0 then a[i]:=a[i]+(P[8][j].R-S[i].R).InvCubeScale3D(GM); end;
    S[i].V := S[i].V + a[i]   * (B4 * dt);
    S[i].R := S[i].R + S[i].V * (A4 * dt);

// node c4 -> P[7]
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[7]) to High(P[7]) do begin GM:=P[7][j].GM; if GM>0.0 then a[i]:=a[i]+(P[7][j].R-S[i].R).InvCubeScale3D(GM); end;
    S[i].V := S[i].V + a[i]   * (B5 * dt);
    S[i].R := S[i].R + S[i].V * (A5 * dt);

// node c5 -> P[6]
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[6]) to High(P[6]) do begin GM:=P[6][j].GM; if GM>0.0 then a[i]:=a[i]+(P[6][j].R-S[i].R).InvCubeScale3D(GM); end;
    S[i].V := S[i].V + a[i]   * (B6 * dt);
    S[i].R := S[i].R + S[i].V * (A6 * dt);

// node c6 -> P[5]
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[5]) to High(P[5]) do begin GM:=P[5][j].GM; if GM>0.0 then a[i]:=a[i]+(P[5][j].R-S[i].R).InvCubeScale3D(GM); end;
    S[i].V := S[i].V + a[i]   * (B7 * dt);
    S[i].R := S[i].R + S[i].V * (A7 * dt);

// node c7 -> P[4]
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[4]) to High(P[4]) do begin GM:=P[4][j].GM; if GM>0.0 then a[i]:=a[i]+(P[4][j].R-S[i].R).InvCubeScale3D(GM); end;
    S[i].V := S[i].V + a[i]   * (B8 * dt);
    S[i].R := S[i].R + S[i].V * (A8 * dt);

// node c8 -> P[3]
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[3]) to High(P[3]) do begin GM:=P[3][j].GM; if GM>0.0 then a[i]:=a[i]+(P[3][j].R-S[i].R).InvCubeScale3D(GM); end;
    S[i].V := S[i].V + a[i]   * (B9 * dt);
    S[i].R := S[i].R + S[i].V * (A9 * dt);

// node c9 -> P[2]
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[2]) to High(P[2]) do begin GM:=P[2][j].GM; if GM>0.0 then a[i]:=a[i]+(P[2][j].R-S[i].R).InvCubeScale3D(GM); end;
    S[i].V := S[i].V + a[i]   * (B10 * dt);
    S[i].R := S[i].R + S[i].V * (A10 * dt);

// node c10 -> P[1]
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[1]) to High(P[1]) do begin GM:=P[1][j].GM; if GM>0.0 then a[i]:=a[i]+(P[1][j].R-S[i].R).InvCubeScale3D(GM); end;
    S[i].V := S[i].V + a[i]   * (B11 * dt);
    S[i].R := S[i].R + S[i].V * (A11 * dt);

// node c11 -> P[0] (step end); last kick, no drift; a[i] is the FSAL carry to the next step
    FillChar(a[i], SizeOf(TVec4D), 0);
    for j:=Low(P[0]) to High(P[0]) do begin GM:=P[0][j].GM; if GM>0.0 then a[i]:=a[i]+(P[0][j].R-S[i].R).InvCubeScale3D(GM); end;
    S[i].V := S[i].V + a[i]   * (B12 * dt);
   end;
end;
{$ENDIF}

{procedure RungeKutta5(dt: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays);
// non-adaptive Runge-Kutta 5 (basically the non-adaptive version of the 5(4)th-order Dormand-Prince method
// commented out as a pretty useless integrator, since it's neither symplectic nor adaptive
// kept as reference only
var
  // Stage velocity vectors (dr/dt evaluation steps)
  kv1, kv2, kv3, kv4, kv5, kv6,
  // Stage acceleration vectors (dv/dt evaluation steps)
  ka1, ka2, ka3, ka4, ka5, ka6,
  // Intermediate calculation registers
  r_stage, v_stage: TVec4D;
  GM: Double;
  i, j: Int64;
begin
  if dt=0.0 then Exit;
  for i:=Low(S) to High(S) do begin

  // --- STAGE 1 ---
  // FSAL Rule: kv1 is the current velocity. ka1 is the passed-in acceleration.
  kv1 := S[i].V;
  ka1 := a[i];

  // --- STAGE 2 ---
  r_stage := S[i].R + (kv1 * (1.0/5.0 * dt));
  v_stage := S[i].v + (ka1 * (1.0/5.0 * dt));
  kv2     := v_stage;
  //ka2     := GetAccel(r_stage, 4);
  FillChar(ka2, SizeOf(TVec4D), 0);
  for j:=Low(P[4]) to High(P[4]) do
   begin
    GM := P[4][j].GM;
    if GM > 0.0 then ka2:= ka2 + (P[4][j].R - S[i].R).InvCubeScale3D(GM);
   end;

  // --- STAGE 3 ---
  r_stage := S[i].R + ((kv1 * (3.0/40.0) + kv2 * (9.0/40.0)) * dt);
  v_stage := S[i].V + ((ka1 * (3.0/40.0) + ka2 * (9.0/40.0)) * dt);
  kv3     := v_stage;
  //ka3     := GetAccel(r_stage, 3);
  FillChar(ka3, SizeOf(TVec4D), 0);
  for j:=Low(P[3]) to High(P[3]) do
   begin
    GM := P[3][j].GM;
    if GM > 0.0 then ka3:= ka3 + (P[3][j].R - S[i].R).InvCubeScale3D(GM);
   end;

  // --- STAGE 4 ---
  r_stage := S[i].R + ((kv1 * (44.0/45.0) - kv2 * (56.0/15.0) + kv3 * (32.0/9.0)) * dt);
  v_stage := S[i].V + ((ka1 * (44.0/45.0) - ka2 * (56.0/15.0) + ka3 * (32.0/9.0)) * dt);
  kv4     := v_stage;
  //ka4     := GetAccel(r_stage, 2);
  FillChar(ka4, SizeOf(TVec4D), 0);
  for j:=Low(P[2]) to High(P[2]) do
   begin
    GM := P[2][j].GM;
    if GM > 0.0 then ka4:= ka4 + (P[2][j].R - S[i].R).InvCubeScale3D(GM);
   end;

  // --- STAGE 5 ---
  r_stage := S[i].R + ((kv1 * (19372.0/6561.0) - kv2 * (25360.0/2187.0) + kv3 * (64448.0/6561.0) - kv4 * (212.0/729.0)) * dt);
  v_stage := S[i].V + ((ka1 * (19372.0/6561.0) - ka2 * (25360.0/2187.0) + ka3 * (64448.0/6561.0) - ka4 * (212.0/729.0)) * dt);
  kv5     := v_stage;
  //ka5     := GetAccel(r_stage, 1);
  FillChar(ka5, SizeOf(TVec4D), 0);
  for j:=Low(P[1]) to High(P[1]) do
   begin
    GM := P[1][j].GM;
    if GM > 0.0 then ka5:= ka5 + (P[1][j].R - S[i].R).InvCubeScale3D(GM);
   end;

  // --- STAGE 6 ---
  r_stage := S[i].R + ((kv1 * (9017.0/3168.0) - kv2 * (355.0/33.0) + kv3 * (46732.0/5247.0) + kv4 * (49.0/176.0) - kv5 * (5103.0/18656.0)) * dt);
  v_stage := S[i].V + ((ka1 * (9017.0/3168.0) - ka2 * (355.0/33.0) + ka3 * (46732.0/5247.0) + ka4 * (49.0/176.0) - ka5 * (5103.0/18656.0)) * dt);
  kv6     := v_stage;

  //ka6     := GetAccel(r_stage, 0); // tt = 1.0 represents the end of the step (t0 + dt)
  FillChar(ka6, SizeOf(TVec4D), 0);
  for j:=Low(P[0]) to High(P[0]) do
   begin
    GM := P[0][j].GM;
    if GM > 0.0 then ka6:= ka6 + (P[0][j].R - S[i].R).InvCubeScale3D(GM);
   end;

  // --- FINAL 5TH-ORDER UPDATE ---
  S[i].R := S[i].R + ((kv1 * (1.0/90.0) + kv3 * (32.0/90.0) + kv4 * (12.0/90.0) + kv5 * (32.0/90.0) + kv6 * (15.0/90.0)) * dt);
  S[i].V := S[i].V + ((ka1 * (1.0/90.0) + ka3 * (32.0/90.0) + ka4 * (12.0/90.0) + ka5 * (32.0/90.0) + ka6 * (15.0/90.0)) * dt);

  // FSAL Rule: The acceleration at the final boundary becomes the starting acceleration for the next loop execution
  a[i] := ka6;

  end;
end;}

function DormandPrince54(dt: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays; TmpR, TmpV, TmpA: TVec4DArray): Double;
{$IFDEF AVX2}
// Batch (stage-outer) DP5(4): each stage evaluates ALL bodies' acceleration in one NewtonAccel call.
// Same math/controller as the non-AVX2 version. 10 stage scratch arrays + StageS allocated per call
// (cheap vs the O(n*np) force work). kv1 == S.V and ka1 == a are read directly (S untouched until accept).
const
  B1 = 35.0/384.0; B3 = 500.0/1113.0; B4 = 125.0/192.0; B5 = -2187.0/6784.0; B6 = 11.0/84.0;
  E1 = 71.0/57600.0; E3 = -71.0/16695.0; E4 = 71.0/1920.0; E5 = -17253.0/339200.0; E6 = 22.0/525.0; E7 = -1.0/40.0;
  SAFETY = 0.9; MAX_GROWTH = 5.0; MIN_SHRINK = 0.1;
  ATOL_R = 1.0e-6; ATOL_V = 1.0e-12;
var
  kv2, kv3, kv4, kv5, kv6, ka2, ka3, ka4, ka5, ka6: TVec4DArray;
  StageS: TState4DArray;
  err_r, err_v: TVec4D;
  err, errv, err_max, sc_r, sc_v, growth, RTOL: Double;
  accepted: Boolean;
  i, n, np: Int64;
begin
  RTOL := ERROR_TOLERANCE_DP;
  err_max := 0.0;
  n := Length(S); np := Length(P[0]);
  SetLength(kv2, n); SetLength(kv3, n); SetLength(kv4, n); SetLength(kv5, n); SetLength(kv6, n);
  SetLength(ka2, n); SetLength(ka3, n); SetLength(ka4, n); SetLength(ka5, n); SetLength(ka6, n);
  SetLength(StageS, n);

  // Stage 2 (c2 = 1/5) -> P[4]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + S[i].V*(0.2*dt);
    kv2[i]      := S[i].V + a[i]*(0.2*dt);
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[4]), Pointer(ka2), n, np);

  // Stage 3 (c3 = 3/10) -> P[3]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*(3.0/40.0) + kv2[i]*(9.0/40.0))*dt;
    kv3[i]      := S[i].V + (a[i]*(3.0/40.0)   + ka2[i]*(9.0/40.0))*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[3]), Pointer(ka3), n, np);

  // Stage 4 (c4 = 4/5) -> P[2]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*(44.0/45.0) - kv2[i]*(56.0/15.0) + kv3[i]*(32.0/9.0))*dt;
    kv4[i]      := S[i].V + (a[i]*(44.0/45.0)   - ka2[i]*(56.0/15.0) + ka3[i]*(32.0/9.0))*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[2]), Pointer(ka4), n, np);

  // Stage 5 (c5 = 8/9) -> P[1]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*(19372.0/6561.0) - kv2[i]*(25360.0/2187.0) + kv3[i]*(64448.0/6561.0) - kv4[i]*(212.0/729.0))*dt;
    kv5[i]      := S[i].V + (a[i]*(19372.0/6561.0)   - ka2[i]*(25360.0/2187.0) + ka3[i]*(64448.0/6561.0) - ka4[i]*(212.0/729.0))*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[1]), Pointer(ka5), n, np);

  // Stage 6 (c6 = 1) -> P[0]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*(9017.0/3168.0) - kv2[i]*(355.0/33.0) + kv3[i]*(46732.0/5247.0) + kv4[i]*(49.0/176.0) - kv5[i]*(5103.0/18656.0))*dt;
    kv6[i]      := S[i].V + (a[i]*(9017.0/3168.0)   - ka2[i]*(355.0/33.0) + ka3[i]*(46732.0/5247.0) + ka4[i]*(49.0/176.0) - ka5[i]*(5103.0/18656.0))*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[0]), Pointer(ka6), n, np);

  // Final 5th-order state + embedded error (per body). kv1 = S.V, ka1 = a.
  for i := 0 to n-1 do
  begin
    TmpR[i] := S[i].R + (S[i].V*B1 + kv3[i]*B3 + kv4[i]*B4 + kv5[i]*B5 + kv6[i]*B6)*dt;
    TmpV[i] := S[i].V + (a[i]*B1   + ka3[i]*B3 + ka4[i]*B4 + ka5[i]*B5 + ka6[i]*B6)*dt;
    TmpA[i] := ka6[i];
    err_r := (S[i].V*E1 + kv3[i]*E3 + kv4[i]*E4 + kv5[i]*E5 + kv6[i]*E6 + TmpV[i]*E7)*dt;
    err_v := (a[i]*E1   + ka3[i]*E3 + ka4[i]*E4 + ka5[i]*E5 + ka6[i]*(E6 + E7))*dt;
    sc_r  := ATOL_R + RTOL * TmpR[i].Magnitude3D;
    sc_v  := ATOL_V + RTOL * TmpV[i].Magnitude3D;
    err   := err_r.Magnitude3D / sc_r;
    errv  := err_v.Magnitude3D / sc_v;
    if IsNan(errv) or (errv > err) then err := errv;
    if IsNan(err) or (err > err_max) then err_max := err;
  end;

  accepted := (err_max <= 1.0) and not (IsNan(err_max) or IsInfinite(err_max));
  if IsNan(err_max) or IsInfinite(err_max) then growth := MIN_SHRINK
  else if err_max > 0.0 then
  begin
    growth := SAFETY * Power(1.0 / err_max, 0.2);
    if growth < MIN_SHRINK then growth := MIN_SHRINK;
    if growth > MAX_GROWTH then growth := MAX_GROWTH;
  end
  else growth := MAX_GROWTH;

  if accepted then
  begin
    for i := 0 to n-1 do begin S[i].R := TmpR[i]; S[i].V := TmpV[i]; a[i] := TmpA[i]; end;
    Result := dt * growth;
  end
  else Result := -(dt * growth);
end;
{$ELSE}
// Dormand-Prince RK5(4) adaptive-step FSAL integrator.
// Returns the suggested next step size. If the return value >= dt the step was
// accepted and S / a have been updated (FSAL). If < dt the step was rejected
// and S / a are left unchanged; the caller should retry with the returned dt.
// TmpR, TmpV, TmpA must be pre-allocated by the caller to Length(S) elements.
const
  // Dormand-Prince 5th-order weights
  B1 =   35.0/384.0;
  B3 =  500.0/1113.0;
  B4 =  125.0/192.0;
  B5 = -2187.0/6784.0;
  B6 =   11.0/84.0;
  // Error coefficients  e_k = b5th_k - b4th_k  (Dormand-Prince)
  // E7 = 0 - 1/40 for the FSAL 7th stage (b7_5th=0, b7_4th=1/40);
  // kv7 = TmpV[i] (5th-order velocity), no extra force evaluation needed.
  E1 =    71.0/57600.0;
  E3 =   -71.0/16695.0;
  E4 =    71.0/1920.0;
  E5 = -17253.0/339200.0;
  E6 =    22.0/525.0;
  E7 =    -1.0/40.0;
  SAFETY     = 0.9;
  MAX_GROWTH = 5.0;
  MIN_SHRINK = 0.1;
  // Reference-style tolerances: err = max over bodies & {r,v} of |Δ|/(atol + RTOL*|y|), accept at
  // err<=1. RTOL (relative) is the live ERROR_TOLERANCE_DP knob; ATOL_* are absolute floors that
  // only bind when |r| or |v| approaches zero (barycentric orbiters keep them well away), which
  // just prevents a divide-by-near-zero. Units: km and km/s.
  ATOL_R     = 1.0e-6;   // km    position floor (kept << RTOL*|r| so it never binds for orbiters)
  ATOL_V     = 1.0e-12;  // km/s  velocity floor (kept << RTOL*|v|; pure divide-by-zero guard)
var
  kv1, kv2, kv3, kv4, kv5, kv6,
  ka1, ka2, ka3, ka4, ka5, ka6,
  r_stage, v_stage, err_r, err_v: TVec4D;
  GM, err, errv, err_max, sc_r, sc_v, growth, RTOL: Double;
  accepted: Boolean;
  i, j: Int64;
begin
  RTOL := ERROR_TOLERANCE_DP;
  err_max := 0.0;

  for i := Low(S) to High(S) do
   begin
    // Stage 1 — FSAL: incoming acceleration is k1
    kv1 := S[i].V;
    ka1 := a[i];

    // Stage 2  (c2 = 1/5)
    r_stage := S[i].R + kv1 * 0.2*dt;
    v_stage := S[i].V + ka1 * 0.2*dt;
    kv2 := v_stage;
    FillChar(ka2, SizeOf(TVec4D), 0);
    for j := Low(P[4]) to High(P[4]) do
     begin
      GM := P[4][j].GM;
      if GM > 0.0 then ka2 := ka2 + (P[4][j].R - r_stage).InvCubeScale3D(GM);
     end;

    // Stage 3  (c3 = 3/10)
    r_stage := S[i].R + (kv1 * (3.0/40.0) + kv2 * (9.0/40.0)) * dt;
    v_stage := S[i].V + (ka1 * (3.0/40.0) + ka2 * (9.0/40.0)) * dt;
    kv3 := v_stage;
    FillChar(ka3, SizeOf(TVec4D), 0);
    for j := Low(P[3]) to High(P[3]) do
     begin
      GM := P[3][j].GM;
      if GM > 0.0 then ka3 := ka3 + (P[3][j].R - r_stage).InvCubeScale3D(GM);
     end;

    // Stage 4  (c4 = 4/5)
    r_stage := S[i].R + (kv1 * (44.0/45.0) - kv2 * (56.0/15.0) + kv3 * (32.0/9.0)) * dt;
    v_stage := S[i].V + (ka1 * (44.0/45.0) - ka2 * (56.0/15.0) + ka3 * (32.0/9.0)) * dt;
    kv4 := v_stage;
    FillChar(ka4, SizeOf(TVec4D), 0);
    for j := Low(P[2]) to High(P[2]) do
     begin
      GM := P[2][j].GM;
      if GM > 0.0 then ka4 := ka4 + (P[2][j].R - r_stage).InvCubeScale3D(GM);
     end;

    // Stage 5  (c5 = 8/9)
    r_stage := S[i].R + (kv1 * (19372.0/6561.0) - kv2 * (25360.0/2187.0) + kv3 * (64448.0/6561.0) - kv4 * (212.0/729.0)) * dt;
    v_stage := S[i].V + (ka1 * (19372.0/6561.0) - ka2 * (25360.0/2187.0) + ka3 * (64448.0/6561.0) - ka4 * (212.0/729.0)) * dt;
    kv5 := v_stage;
    FillChar(ka5, SizeOf(TVec4D), 0);
    for j := Low(P[1]) to High(P[1]) do
     begin
      GM := P[1][j].GM;
      if GM > 0.0 then ka5 := ka5 + (P[1][j].R - r_stage).InvCubeScale3D(GM);
     end;

    // Stage 6  (c6 = 1)
    r_stage := S[i].R + (kv1 * (9017.0/3168.0) - kv2 * (355.0/33.0) + kv3 * (46732.0/5247.0) + kv4 * (49.0/176.0) - kv5 * (5103.0/18656.0)) * dt;
    v_stage := S[i].V + (ka1 * (9017.0/3168.0) - ka2 * (355.0/33.0) + ka3 * (46732.0/5247.0) + ka4 * (49.0/176.0) - ka5 * (5103.0/18656.0)) * dt;
    kv6 := v_stage;
    FillChar(ka6, SizeOf(TVec4D), 0);
    for j := Low(P[0]) to High(P[0]) do
     begin
      GM := P[0][j].GM;
      if GM > 0.0 then ka6 := ka6 + (P[0][j].R - r_stage).InvCubeScale3D(GM);
     end;

    TmpR[i] := S[i].R + (kv1 * B1 + kv3 * B3 + kv4 * B4 + kv5 * B5 + kv6 * B6) * dt;
    TmpV[i] := S[i].V + (ka1 * B1 + ka3 * B3 + ka4 * B4 + ka5 * B5 + ka6 * B6) * dt;
    TmpA[i] := ka6;

    // Embedded local error over the FULL state (position AND velocity), reference-style
    // (Hairer & Wanner): per-quantity scale sc = atol + RTOL*|y|, err = max over bodies and over
    // {position, velocity} of |Δ|/sc; err<=1 means within tolerance. The velocity term uses the
    // acceleration stages ka; ka7 (accel at the c=1 end node) is not evaluated, so its E7 weight
    // is folded onto ka6 (also a c=1 node) -- which also keeps the velocity weights summing to 0.
    err_r := (kv1 * E1 + kv3 * E3 + kv4 * E4 + kv5 * E5 + kv6 * E6 + TmpV[i] * E7) * dt;
    err_v := (ka1 * E1 + ka3 * E3 + ka4 * E4 + ka5 * E5 + ka6 * (E6 + E7)) * dt;
    sc_r  := ATOL_R + RTOL * TmpR[i].Magnitude3D;
    sc_v  := ATOL_V + RTOL * TmpV[i].Magnitude3D;
    err   := err_r.Magnitude3D / sc_r;
    errv  := err_v.Magnitude3D / sc_v;
    if IsNan(errv) or (errv > err) then err := errv;
    if IsNan(err) or (err > err_max) then err_max := err;   // capture NaN (Inf/Inf overshoot) too
   end;

  // Reference-style controller. err_max is already tolerance-normalised (err<=1 => within tol),
  // so accept on err_max<=1 and choose the next step as dt*SAFETY*(1/err_max)^(1/(q+1)); for the
  // DP5(4) embedded pair q=4 => exponent 1/5. A SINGLE symmetric clamp [MIN_SHRINK, MAX_GROWTH]
  // applies to accepts and rejects alike, so an accepted step sitting on the tolerance boundary
  // may back off to ~0.9 (the reference behaviour) instead of being pinned at >=1 -- avoiding the
  // accept-at-boundary -> next-step-reject churn.
  //
  // Return convention (the caller relies on the SIGN): Result > 0 => ACCEPTED and S/V/a advanced,
  // value = suggested next step (may be < dt). Result < 0 => REJECTED, S untouched, |Result| =
  // shrunk retry step. A 1/r^3 overflow (NaN/Inf err_max) is forced to a hard rejected shrink so
  // it can never masquerade as an accepted step.
  accepted := (err_max <= 1.0) and not (IsNan(err_max) or IsInfinite(err_max));

  if IsNan(err_max) or IsInfinite(err_max) then
   growth := MIN_SHRINK
  else if err_max > 0.0 then
   begin
    growth := SAFETY * Power(1.0 / err_max, 0.2);
    if growth < MIN_SHRINK then growth := MIN_SHRINK;
    if growth > MAX_GROWTH then growth := MAX_GROWTH;
   end
  else
   growth := MAX_GROWTH;   // err_max = 0: essentially exact, grow maximally

  if accepted then
   begin
    for i := Low(S) to High(S) do
     begin
      S[i].R := TmpR[i];
      S[i].V := TmpV[i];
      a[i]   := TmpA[i];
     end;
    Result := dt * growth;        // > 0 : accepted; next-step hint (may back off below dt)
   end
  else
   Result := -(dt * growth);      // < 0 : rejected; |Result| is the retry step
end;
{$ENDIF}

function DormandPrince87(dt: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays; TmpR, TmpV, TmpA: TVec4DArray): Double;
{$IFDEF AVX2}
// Batch (stage-outer) DP8(7): each of the 12 force stages evaluates ALL bodies in one NewtonAccel call.
// Same math/controller/timescale-limiter as the non-AVX2 version. 24 stage scratch arrays + StageS
// allocated per call.
const
  B1  =  14005451.0/335480064;   B6  = -59238493.0/1068277825;  B7  =  181606767.0/758867731;
  B8  =  561292985.0/797845732;  B9  = -1041891430.0/1371343529; B10 =  760417239.0/1151165299;
  B11 =  118820643.0/751138087;  B12 = -528747749.0/2220607170;  B13 =  1.0/4;
  D6  = -808719846.0/976000145;  D7  =  1757004468.0/5645159321; D8  =  656045339.0/265891186;
  D9  = -3867574721.0/1518517206; D10 =  465885868.0/322736535;  D11 =  53011238.0/667516719;
  D12 =  2.0/45;
  E6  = B6 - D6;  E7 = B7 - D7;  E8 = B8 - D8;  E9 = B9 - D9;  E10 = B10 - D10;
  E11 = B11 - D11; E12 = B12 - D12; E13 = B13;
  E1  = -(E6 + E7 + E8 + E9 + E10 + E11 + E12 + E13);
  A21 = 1.0/18;
  A31 = 1.0/48; A32 = 1.0/16;
  A41 = 1.0/32; A43 = 3.0/32;
  A51 = 5.0/16; A53 = -75.0/64; A54 = 75.0/64;
  A61 = 3.0/80; A64 = 3.0/16; A65 = 3.0/20;
  A71 = 29443841.0/614563906; A74 = 77736538.0/692538347; A75 = -28693883.0/1125000000; A76 = 23124283.0/1800000000;
  A81 = 16016141.0/946692911; A84 = 61564180.0/158732637; A85 = 22789713.0/633445777; A86 = 545815736.0/2771057229; A87 = -180193667.0/1043307555;
  A91 = 39632708.0/573591083; A94 = -433636366.0/683701615; A95 = -421739975.0/2616292301; A96 = 100302831.0/723423059; A97 = 790204164.0/839813087; A98 = 800635310.0/3783071287;
  A101 = 246121993.0/1340847787; A104 = -37695042795.0/15268766246; A105 = -309121744.0/1061227803; A106 = -12992083.0/490766935; A107 = 6005943493.0/2108947869; A108 = 393006217.0/1396673457; A109 = 123872331.0/1001029789;
  A111 = -1028468189.0/846180014; A114 = 8478235783.0/508512852; A115 = 1311729495.0/1432422823; A116 = -10304129995.0/1701304382; A117 = -48777925059.0/3047939560; A118 = 15336726248.0/1032824649; A119 = -45442868181.0/3398467696; A1110 = 3065993473.0/597172653;
  A121 = 185892177.0/718116043; A124 = -3185094517.0/667107341; A125 = -477755414.0/1098053517; A126 = -703635378.0/230739211; A127 = 5731566787.0/1027545527; A128 = 5232866602.0/850066563; A129 = -4093664535.0/808688257; A1210 = 3962137247.0/1805957418; A1211 = 65686358.0/487910083;
  A131 = 403863854.0/491063109; A134 = -5068492393.0/434740067; A135 = -411421997.0/543043805; A136 = 652783627.0/914296604; A137 = 11173962825.0/925320556; A138 = -13158990841.0/6184727034; A139 = 3936647629.0/1978049680; A1310 = -160528059.0/685178525; A1311 = 248638103.0/1413531060;
  SAFETY = 0.9; MAX_GROWTH = 5.0; MIN_SHRINK = 0.1;
  ATOL_R = 1.0e-6; ATOL_V = 1.0e-12; TS_FRAC = 0.1;
var
  kv2, kv3, kv4, kv5, kv6, kv7, kv8, kv9, kv10, kv11, kv12, kv13: TVec4DArray;
  ka2, ka3, ka4, ka5, ka6, ka7, ka8, ka9, ka10, ka11, ka12, ka13: TVec4DArray;
  StageS: TState4DArray;
  err_r, err_v: TVec4D;
  err, errv, err_max, sc_r, sc_v, growth, RTOL, min_ts, amag, a_start, ts: Double;
  accepted: Boolean;
  i, n, np: Int64;
begin
  RTOL := ERROR_TOLERANCE_DP;
  err_max := 0.0;
  min_ts  := 1.0E300;
  n := Length(S); np := Length(P[0]);
  SetLength(kv2, n); SetLength(kv3, n); SetLength(kv4, n); SetLength(kv5, n); SetLength(kv6, n);
  SetLength(kv7, n); SetLength(kv8, n); SetLength(kv9, n); SetLength(kv10, n); SetLength(kv11, n);
  SetLength(kv12, n); SetLength(kv13, n);
  SetLength(ka2, n); SetLength(ka3, n); SetLength(ka4, n); SetLength(ka5, n); SetLength(ka6, n);
  SetLength(ka7, n); SetLength(ka8, n); SetLength(ka9, n); SetLength(ka10, n); SetLength(ka11, n);
  SetLength(ka12, n); SetLength(ka13, n);
  SetLength(StageS, n);

  // Stage 2 -> P[10]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + S[i].V*(A21*dt);
    kv2[i]      := S[i].V + a[i]*(A21*dt);
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[10]), Pointer(ka2), n, np);

  // Stage 3 -> P[9]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*A31 + kv2[i]*A32)*dt;
    kv3[i]      := S[i].V + (a[i]*A31   + ka2[i]*A32)*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[9]), Pointer(ka3), n, np);

  // Stage 4 -> P[8]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*A41 + kv3[i]*A43)*dt;
    kv4[i]      := S[i].V + (a[i]*A41   + ka3[i]*A43)*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[8]), Pointer(ka4), n, np);

  // Stage 5 -> P[7]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*A51 + kv3[i]*A53 + kv4[i]*A54)*dt;
    kv5[i]      := S[i].V + (a[i]*A51   + ka3[i]*A53 + ka4[i]*A54)*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[7]), Pointer(ka5), n, np);

  // Stage 6 -> P[6]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*A61 + kv4[i]*A64 + kv5[i]*A65)*dt;
    kv6[i]      := S[i].V + (a[i]*A61   + ka4[i]*A64 + ka5[i]*A65)*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[6]), Pointer(ka6), n, np);

  // Stage 7 -> P[5]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*A71 + kv4[i]*A74 + kv5[i]*A75 + kv6[i]*A76)*dt;
    kv7[i]      := S[i].V + (a[i]*A71   + ka4[i]*A74 + ka5[i]*A75 + ka6[i]*A76)*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[5]), Pointer(ka7), n, np);

  // Stage 8 -> P[4]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*A81 + kv4[i]*A84 + kv5[i]*A85 + kv6[i]*A86 + kv7[i]*A87)*dt;
    kv8[i]      := S[i].V + (a[i]*A81   + ka4[i]*A84 + ka5[i]*A85 + ka6[i]*A86 + ka7[i]*A87)*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[4]), Pointer(ka8), n, np);

  // Stage 9 -> P[3]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*A91 + kv4[i]*A94 + kv5[i]*A95 + kv6[i]*A96 + kv7[i]*A97 + kv8[i]*A98)*dt;
    kv9[i]      := S[i].V + (a[i]*A91   + ka4[i]*A94 + ka5[i]*A95 + ka6[i]*A96 + ka7[i]*A97 + ka8[i]*A98)*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[3]), Pointer(ka9), n, np);

  // Stage 10 -> P[2]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*A101 + kv4[i]*A104 + kv5[i]*A105 + kv6[i]*A106 + kv7[i]*A107 + kv8[i]*A108 + kv9[i]*A109)*dt;
    kv10[i]     := S[i].V + (a[i]*A101   + ka4[i]*A104 + ka5[i]*A105 + ka6[i]*A106 + ka7[i]*A107 + ka8[i]*A108 + ka9[i]*A109)*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[2]), Pointer(ka10), n, np);

  // Stage 11 -> P[1]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*A111 + kv4[i]*A114 + kv5[i]*A115 + kv6[i]*A116 + kv7[i]*A117 + kv8[i]*A118 + kv9[i]*A119 + kv10[i]*A1110)*dt;
    kv11[i]     := S[i].V + (a[i]*A111   + ka4[i]*A114 + ka5[i]*A115 + ka6[i]*A116 + ka7[i]*A117 + ka8[i]*A118 + ka9[i]*A119 + ka10[i]*A1110)*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[1]), Pointer(ka11), n, np);

  // Stage 12 -> P[0]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*A121 + kv4[i]*A124 + kv5[i]*A125 + kv6[i]*A126 + kv7[i]*A127 + kv8[i]*A128 + kv9[i]*A129 + kv10[i]*A1210 + kv11[i]*A1211)*dt;
    kv12[i]     := S[i].V + (a[i]*A121   + ka4[i]*A124 + ka5[i]*A125 + ka6[i]*A126 + ka7[i]*A127 + ka8[i]*A128 + ka9[i]*A129 + ka10[i]*A1210 + ka11[i]*A1211)*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[0]), Pointer(ka12), n, np);

  // Stage 13 -> P[0]
  for i := 0 to n-1 do
  begin
    StageS[i].R := S[i].R + (S[i].V*A131 + kv4[i]*A134 + kv5[i]*A135 + kv6[i]*A136 + kv7[i]*A137 + kv8[i]*A138 + kv9[i]*A139 + kv10[i]*A1310 + kv11[i]*A1311)*dt;
    kv13[i]     := S[i].V + (a[i]*A131   + ka4[i]*A134 + ka5[i]*A135 + ka6[i]*A136 + ka7[i]*A137 + ka8[i]*A138 + ka9[i]*A139 + ka10[i]*A1310 + ka11[i]*A1311)*dt;
  end;
  NewtonAccelJ2(Pointer(StageS), Pointer(P[0]), Pointer(ka13), n, np);

  // Final 8th-order state, timescale sampling, and embedded error (per body). kv1 = S.V, ka1 = a.
  for i := 0 to n-1 do
  begin
    TmpR[i] := S[i].R + (S[i].V*B1 + kv6[i]*B6 + kv7[i]*B7 + kv8[i]*B8 + kv9[i]*B9 + kv10[i]*B10 + kv11[i]*B11 + kv12[i]*B12 + kv13[i]*B13)*dt;
    TmpV[i] := S[i].V + (a[i]*B1   + ka6[i]*B6 + ka7[i]*B7 + ka8[i]*B8 + ka9[i]*B9 + ka10[i]*B10 + ka11[i]*B11 + ka12[i]*B12 + ka13[i]*B13)*dt;
    TmpA[i] := ka13[i];

    // strongest |a|^2 sampled by any stage (approach detector), a_start = step-start |a|^2
    amag := a[i] or a[i];   a_start := amag;
    ts := ka2[i]  or ka2[i];   if ts > amag then amag := ts;
    ts := ka3[i]  or ka3[i];   if ts > amag then amag := ts;
    ts := ka4[i]  or ka4[i];   if ts > amag then amag := ts;
    ts := ka5[i]  or ka5[i];   if ts > amag then amag := ts;
    ts := ka6[i]  or ka6[i];   if ts > amag then amag := ts;
    ts := ka7[i]  or ka7[i];   if ts > amag then amag := ts;
    ts := ka8[i]  or ka8[i];   if ts > amag then amag := ts;
    ts := ka9[i]  or ka9[i];   if ts > amag then amag := ts;
    ts := ka10[i] or ka10[i];  if ts > amag then amag := ts;
    ts := ka11[i] or ka11[i];  if ts > amag then amag := ts;
    ts := ka12[i] or ka12[i];  if ts > amag then amag := ts;
    ts := ka13[i] or ka13[i];  if ts > amag then amag := ts;
    if (amag > a_start) and (amag > 0.0) then
    begin
      ts := Sqrt((S[i].V or S[i].V) / amag);
      if ts < min_ts then min_ts := ts;
    end;

    err_r := (S[i].V*E1 + kv6[i]*E6 + kv7[i]*E7 + kv8[i]*E8 + kv9[i]*E9 + kv10[i]*E10 + kv11[i]*E11 + kv12[i]*E12 + kv13[i]*E13)*dt;
    err_v := (a[i]*E1   + ka6[i]*E6 + ka7[i]*E7 + ka8[i]*E8 + ka9[i]*E9 + ka10[i]*E10 + ka11[i]*E11 + ka12[i]*E12 + ka13[i]*E13)*dt;
    sc_r  := ATOL_R + RTOL * TmpR[i].Magnitude3D;
    sc_v  := ATOL_V + RTOL * TmpV[i].Magnitude3D;
    err   := err_r.Magnitude3D / sc_r;
    errv  := err_v.Magnitude3D / sc_v;
    if IsNan(errv) or (errv > err) then err := errv;
    if IsNan(err) or (err > err_max) then err_max := err;
  end;

  // approach-only dynamical-timescale step limit (see base DP87)
  if (min_ts < 1.0E300) and (min_ts > 0.0) then
  begin
    ts := dt / (TS_FRAC * min_ts);
    if ts > 1.0 then
    begin
      ts := ts*ts;  ts := ts*ts;  ts := ts*ts;
      if ts > err_max then err_max := ts;
    end;
  end;

  accepted := (err_max <= 1.0) and not (IsNan(err_max) or IsInfinite(err_max));
  if IsNan(err_max) or IsInfinite(err_max) then growth := MIN_SHRINK
  else if err_max > 0.0 then
  begin
    growth := SAFETY * Power(1.0 / err_max, 0.125);
    if growth < MIN_SHRINK then growth := MIN_SHRINK;
    if growth > MAX_GROWTH then growth := MAX_GROWTH;
  end
  else growth := MAX_GROWTH;

  if accepted then
  begin
    for i := 0 to n-1 do begin S[i].R := TmpR[i]; S[i].V := TmpV[i]; a[i] := TmpA[i]; end;
    Result := dt * growth;
  end
  else Result := -(dt * growth);
end;
{$ELSE}
const
  B1  =  14005451.0/335480064;
  B2  =  0.0;
  B3  =  0.0;
  B4  =  0.0;
  B5  =  0.0;
	B6  = -59238493.0/1068277825;
	B7  =  181606767.0/758867731;
	B8  =  561292985.0/797845732;
	B9  = -1041891430.0/1371343529;
	B10 =  760417239.0/1151165299;
	B11 =  118820643.0/751138087;
	B12 = -528747749.0/2220607170;
	B13 =  1.0/4;

  // Embedded 7th-order weights (d in the reference). d2..d5 = 0, d13 = 0.
  // Note d1 is intentionally omitted: see E1 below.
	D6  = -808719846.0/976000145;
	D7  =  1757004468.0/5645159321;
	D8  =  656045339.0/265891186;
	D9  = -3867574721.0/1518517206;
	D10 =  465885868.0/322736535;
	D11 =  53011238.0/667516719;
	D12 =  2.0/45;

  // Error weights = b - d (8th-order minus embedded 7th-order): the small
  // differences used for the local truncation error estimate. For a correct
  // estimate they MUST sum to exactly zero, so that sum(E_k*kv_k) reduces to
  // sum(E_k*(kv_k - kv1)) -- a quantity that vanishes like dt^8.
  //
  // The published 7th-order weights only sum to 1 - 5.84e-10 (not exactly 1),
  // so the naive E1 = B1 - D1 leaves sum(E) ~ 6e-10 <> 0. That residual
  // multiplies the (large) stage velocities and injects a spurious term
  // ~ (sum E)*v*dt into the error, which is only O(dt) and swamps the true
  // O(dt^8) signal -- making err scale linearly with dt so every step is
  // rejected and the suggested dt only ever shrinks. We therefore pin E1 as the
  // negative sum of the others, forcing sum(E) = 0 exactly. This shifts E1 by
  // ~6e-10 from B1 - D1 (negligible) and restores dt^8 error scaling.
	E6  = B6  - D6;
	E7  = B7  - D7;
	E8  = B8  - D8;
	E9  = B9  - D9;
	E10 = B10 - D10;
	E11 = B11 - D11;
	E12 = B12 - D12;
	E13 = B13;          // d13 = 0
	E1  = -(E6 + E7 + E8 + E9 + E10 + E11 + E12 + E13);

	A21 = 1.0/18;

	A31 = 1.0/48;
	A32 = 1.0/16;

	A41 = 1.0/32;
	A43 = 3.0/32;

	A51 = 5.0/16;
	A53 = -75.0/64;
	A54 = 75.0/64;

	A61 = 3.0/80;
	A64 = 3.0/16;
	A65 = 3.0/20;

	A71 = 29443841.0/614563906;
	A74 = 77736538.0/692538347;
	A75 = -28693883.0/1125000000;
	A76 = 23124283.0/1800000000;

	A81 = 16016141.0/946692911;
	A84 = 61564180.0/158732637;
	A85 = 22789713.0/633445777;
	A86 = 545815736.0/2771057229;
	A87 = -180193667.0/1043307555;

	A91 = 39632708.0/573591083;
	A94 = -433636366.0/683701615;
	A95 = -421739975.0/2616292301;
	A96 = 100302831.0/723423059;
	A97 = 790204164.0/839813087;
	A98 = 800635310.0/3783071287;

	A101 = 246121993.0/1340847787;
	A104 = -37695042795.0/15268766246;
	A105 = -309121744.0/1061227803;
	A106 = -12992083.0/490766935;
	A107 = 6005943493.0/2108947869;
	A108 = 393006217.0/1396673457;
	A109 = 123872331.0/1001029789;

	A111 = -1028468189.0/846180014;
	A114 = 8478235783.0/508512852;
	A115 = 1311729495.0/1432422823;
	A116 = -10304129995.0/1701304382;
	A117 = -48777925059.0/3047939560;
	A118 =  15336726248.0/1032824649;
	A119 = -45442868181.0/3398467696;
	A1110 = 3065993473.0/597172653;

	A121 = 185892177.0/718116043;
	A124 = -3185094517.0/667107341;
	A125 = -477755414.0/1098053517;
	A126 = -703635378.0/230739211;
	A127 = 5731566787.0/1027545527;
	A128 = 5232866602.0/850066563;
	A129 = -4093664535.0/808688257;
	A1210 = 3962137247.0/1805957418;
	A1211 = 65686358.0/487910083;

	A131 = 403863854.0/491063109;
	A134 = -5068492393.0/434740067;
	A135 = -411421997.0/543043805;
	A136 = 652783627.0/914296604;
	A137 = 11173962825.0/925320556;
	A138 = -13158990841.0/6184727034;
	A139 = 3936647629.0/1978049680;
	A1310 = -160528059.0/685178525;
	A1311 = 248638103.0/1413531060;

  SAFETY     = 0.9;
  MAX_GROWTH = 5.0;
  MIN_SHRINK = 0.1;
  // Reference-style tolerances (see DormandPrince54): err = max over bodies & {r,v} of
  // |Δ|/(atol + RTOL*|y|), accept at err<=1. RTOL is the live ERROR_TOLERANCE_DP knob; ATOL_*
  // are floors kept well below RTOL*|y| so they never bind for orbiters. Units: km and km/s.
  ATOL_R     = 1.0e-6;
  ATOL_V     = 1.0e-12;
  TS_FRAC    = 0.1;  // APPROACH-ONLY step limit: step must not exceed this fraction of |v|/max|a|,
                      // but ONLY while the field is strengthening ahead (see the gate in the loop).
                      // Because the limit no longer fires on departure (Earth climb-out), it can be
                      // this aggressive without throttling the start. The max|a| is sampled from the
                      // trial step's predicted stage positions, which for a coarse step under-sample
                      // the true closest approach, so keep this small. Lower it (0.005, 0.002) if a
                      // flyby is still under-resolved; raise it for less lag on approaches.
var
  kv1, kv2, kv3, kv4, kv5, kv6, kv7, kv8, kv9, kv10, kv11, kv12, kv13: TVec4D;
  ka1, ka2, ka3, ka4, ka5, ka6, ka7, ka8, ka9, ka10, ka11, ka12, ka13: TVec4D;
  r_stage, v_stage, err_r, err_v: TVec4D;
  GM, err, errv, err_max, sc_r, sc_v, growth, RTOL, min_ts, amag, a_start, ts: Double;
  accepted: Boolean;
  i, j: Int64;
begin
  RTOL := ERROR_TOLERANCE_DP;
  err_max := 0.0;
  min_ts  := 1.0E300;   // shortest |v|/|a| dynamical timescale across all bodies (this step)

  for i := Low(S) to High(S) do
  begin
    // Stage 1 — FSAL incoming acceleration from previous step
    kv1 := S[i].V;
    ka1 := a[i];

    // Stage 2 (c2 = 1/18 = 0.0555555555555556) -> Maps to P[10]
    r_stage := S[i].R + kv1 * (A21 * dt);
    v_stage := S[i].V + ka1 * (A21 * dt);
    kv2 := v_stage;
    FillChar(ka2, SizeOf(TVec4D), 0);
    for j := Low(P[10]) to High(P[10]) do
    begin
      GM := P[10][j].GM;
      if GM > 0.0 then ka2 := ka2 + (P[10][j].R - r_stage).InvCubeScale3D(GM);
    end;

    // Stage 3 (c3 = 1/12 = 0.0833333333333333) -> Maps to P[9]
    r_stage := S[i].R + (kv1 * A31 + kv2 * A32) * dt;
    v_stage := S[i].V + (ka1 * A31 + ka2 * A32) * dt;
    kv3 := v_stage;
    FillChar(ka3, SizeOf(TVec4D), 0);
    for j := Low(P[9]) to High(P[9]) do
    begin
      GM := P[9][j].GM;
      if GM > 0.0 then ka3 := ka3 + (P[9][j].R - r_stage).InvCubeScale3D(GM);
    end;

    // Stage 4 (c4 = 1/8 = 0.125) -> Maps to P[8]
    r_stage := S[i].R + (kv1 * A41 + kv3 * A43) * dt;
    v_stage := S[i].V + (ka1 * A41 + ka3 * A43) * dt;
    kv4 := v_stage;
    FillChar(ka4, SizeOf(TVec4D), 0);
    for j := Low(P[8]) to High(P[8]) do
    begin
      GM := P[8][j].GM;
      if GM > 0.0 then ka4 := ka4 + (P[8][j].R - r_stage).InvCubeScale3D(GM);
    end;

    // Stage 5 (c5 = 5/16 = 0.3125) -> Maps to P[7]
    r_stage := S[i].R + (kv1 * A51 + kv3 * A53 + kv4 * A54) * dt;
    v_stage := S[i].V + (ka1 * A51 + ka3 * A53 + ka4 * A54) * dt;
    kv5 := v_stage;
    FillChar(ka5, SizeOf(TVec4D), 0);
    for j := Low(P[7]) to High(P[7]) do
    begin
      GM := P[7][j].GM;
      if GM > 0.0 then ka5 := ka5 + (P[7][j].R - r_stage).InvCubeScale3D(GM);
    end;

    // Stage 6 (c6 = 3/8 = 0.375) -> Maps to P[6]
    r_stage := S[i].R + (kv1 * A61 + kv4 * A64 + kv5 * A65) * dt;
    v_stage := S[i].V + (ka1 * A61 + ka4 * A64 + ka5 * A65) * dt;
    kv6 := v_stage;
    FillChar(ka6, SizeOf(TVec4D), 0);
    for j := Low(P[6]) to High(P[6]) do
    begin
      GM := P[6][j].GM;
      if GM > 0.0 then ka6 := ka6 + (P[6][j].R - r_stage).InvCubeScale3D(GM);
    end;

    // Stage 7 (c7 = 59/400 = 0.1475) -> Maps to P[5]
    r_stage := S[i].R + (kv1 * A71 + kv4 * A74 + kv5 * A75 + kv6 * A76) * dt;
    v_stage := S[i].V + (ka1 * A71 + ka4 * A74 + ka5 * A75 + ka6 * A76) * dt;
    kv7 := v_stage;
    FillChar(ka7, SizeOf(TVec4D), 0);
    for j := Low(P[5]) to High(P[5]) do
    begin
      GM := P[5][j].GM;
      if GM > 0.0 then ka7 := ka7 + (P[5][j].R - r_stage).InvCubeScale3D(GM);
    end;

    // Stage 8 (c8 = 93/200 = 0.465) -> Maps to P[4]
    r_stage := S[i].R + (kv1 * A81 + kv4 * A84 + kv5 * A85 + kv6 * A86 + kv7 * A87) * dt;
    v_stage := S[i].V + (ka1 * A81 + ka4 * A84 + ka5 * A85 + ka6 * A86 + ka7 * A87) * dt;
    kv8 := v_stage;
    FillChar(ka8, SizeOf(TVec4D), 0);
    for j := Low(P[4]) to High(P[4]) do
    begin
      GM := P[4][j].GM;
      if GM > 0.0 then ka8 := ka8 + (P[4][j].R - r_stage).InvCubeScale3D(GM);
    end;

    // Stage 9 (c9 = 5490023248/9719169821 = 0.5648006...) -> Maps to P[3]
    r_stage := S[i].R + (kv1 * A91 + kv4 * A94 + kv5 * A95 + kv6 * A96 + kv7 * A97 + kv8 * A98) * dt;
    v_stage := S[i].V + (ka1 * A91 + ka4 * A94 + ka5 * A95 + ka6 * A96 + ka7 * A97 + ka8 * A98) * dt;
    kv9 := v_stage;
    FillChar(ka9, SizeOf(TVec4D), 0);
    for j := Low(P[3]) to High(P[3]) do
    begin
      GM := P[3][j].GM;
      if GM > 0.0 then ka9 := ka9 + (P[3][j].R - r_stage).InvCubeScale3D(GM);
    end;

    // Stage 10 (c10 = 13/20 = 0.65) -> Maps to P[2]
    r_stage := S[i].R + (kv1 * A101 + kv4 * A104 + kv5 * A105 + kv6 * A106 + kv7 * A107 + kv8 * A108 + kv9 * A109) * dt;
    v_stage := S[i].V + (ka1 * A101 + ka4 * A104 + ka5 * A105 + ka6 * A106 + ka7 * A107 + ka8 * A108 + ka9 * A109) * dt;
    kv10 := v_stage;
    FillChar(ka10, SizeOf(TVec4D), 0);
    for j := Low(P[2]) to High(P[2]) do
    begin
      GM := P[2][j].GM;
      if GM > 0.0 then ka10 := ka10 + (P[2][j].R - r_stage).InvCubeScale3D(GM);
    end;

    // Stage 11 (c11 = 1201146811/1299019798 = 0.9246726...) -> Maps to P[1]
    r_stage := S[i].R + (kv1 * A111 + kv4 * A114 + kv5 * A115 + kv6 * A116 + kv7 * A117 + kv8 * A118 + kv9 * A119 + kv10 * A1110) * dt;
    v_stage := S[i].V + (ka1 * A111 + ka4 * A114 + ka5 * A115 + ka6 * A116 + ka7 * A117 + ka8 * A118 + ka9 * A119 + ka10 * A1110) * dt;
    kv11 := v_stage;
    FillChar(ka11, SizeOf(TVec4D), 0);
    for j := Low(P[1]) to High(P[1]) do
    begin
      GM := P[1][j].GM;
      if GM > 0.0 then ka11 := ka11 + (P[1][j].R - r_stage).InvCubeScale3D(GM);
    end;

    // Stage 12 (c12 = 1.0) -> Maps to P[0]
    r_stage := S[i].R + (kv1 * A121 + kv4 * A124 + kv5 * A125 + kv6 * A126 + kv7 * A127 + kv8 * A128 + kv9 * A129 + kv10 * A1210 + kv11 * A1211) * dt;
    v_stage := S[i].V + (ka1 * A121 + ka4 * A124 + ka5 * A125 + ka6 * A126 + ka7 * A127 + ka8 * A128 + ka9 * A129 + ka10 * A1210 + ka11 * A1211) * dt;
    kv12 := v_stage;
    FillChar(ka12, SizeOf(TVec4D), 0);
    for j := Low(P[0]) to High(P[0]) do
    begin
      GM := P[0][j].GM;
      if GM > 0.0 then ka12 := ka12 + (P[0][j].R - r_stage).InvCubeScale3D(GM);
    end;

    // Stage 13 (c13 = 1.0) -> ALSO maps to P[0] (FSAL property point correction sweep)
    r_stage := S[i].R + (kv1 * A131 + kv4 * A134 + kv5 * A135 + kv6 * A136 + kv7 * A137 + kv8 * A138 + kv9 * A139 + kv10 * A1310 + kv11 * A1311) * dt;
    v_stage := S[i].V + (ka1 * A131 + ka4 * A134 + ka5 * A135 + ka6 * A136 + ka7 * A137 + ka8 * A138 + ka9 * A139 + ka10 * A1310 + ka11 * A1311) * dt;
    kv13 := v_stage;
    FillChar(ka13, SizeOf(TVec4D), 0);
    for j := Low(P[0]) to High(P[0]) do
    begin
      GM := P[0][j].GM;
      if GM > 0.0 then ka13 := ka13 + (P[0][j].R - r_stage).InvCubeScale3D(GM);
    end;

    // Blended final 8th-order solution states
    TmpR[i] := S[i].R + (kv1 * B1 + kv6 * B6 + kv7 * B7 + kv8 * B8 + kv9 * B9 + kv10 * B10 + kv11 * B11 + kv12 * B12 + kv13 * B13) * dt;
    TmpV[i] := S[i].V + (ka1 * B1 + ka6 * B6 + ka7 * B7 + ka8 * B8 + ka9 * B9 + ka10 * B10 + ka11 * B11 + ka12 * B12 + ka13 * B13) * dt;
    TmpA[i] := ka13; // Propagated as Stage 1 vector on next pass

    // Dynamical timescale |v|/|a| using the STRONGEST acceleration sampled by ANY stage of
    // this step (not just the step-start a). The stages reach toward the perturber, so a
    // trial step that would plunge into (or over) a strengthening encounter shows a large
    // |a| here -> short timescale -> the limit below rejects it BEFORE it's taken. Using
    // only the start acceleration sees the encounter a step too late. (amag = max |a|^2.)
    amag := ka1 or ka1;
    a_start := amag;     // step-start |a|^2 (FSAL acceleration where the body actually IS)
    ts := ka2  or ka2;   if ts > amag then amag := ts;
    ts := ka3  or ka3;   if ts > amag then amag := ts;
    ts := ka4  or ka4;   if ts > amag then amag := ts;
    ts := ka5  or ka5;   if ts > amag then amag := ts;
    ts := ka6  or ka6;   if ts > amag then amag := ts;
    ts := ka7  or ka7;   if ts > amag then amag := ts;
    ts := ka8  or ka8;   if ts > amag then amag := ts;
    ts := ka9  or ka9;   if ts > amag then amag := ts;
    ts := ka10 or ka10;  if ts > amag then amag := ts;
    ts := ka11 or ka11;  if ts > amag then amag := ts;
    ts := ka12 or ka12;  if ts > amag then amag := ts;
    ts := ka13 or ka13;  if ts > amag then amag := ts;
    // GATE: only impose the timescale limit when the field STRENGTHENS ahead (a later stage feels
    // more pull than the step-start ka1) = the body is APPROACHING an encounter. That's the only
    // case the embedded error estimate can't police: a coarse step leaps over the encounter peak,
    // 7th & 8th order miss it equally -> tiny error -> wrongly accepted. When LEAVING (start is the
    // strongest, field weakening) or in a smooth region, the step jumps over nothing and the
    // embedded estimate is correct on its own -> skip the limit. This stops the limit from
    // pathologically throttling the initial climb OUT of Earth's well (field weakening = leaving),
    // which was forcing Voyager to crawl and miss the Jupiter rendezvous, while still catching the
    // Jupiter approach. The asymmetry (limit on approach, free on departure) is the whole point.
    if (amag > a_start) and (amag > 0.0) then
    begin
      ts := Sqrt((kv1 or kv1) / amag);   // |v| / max|a|  = shortest dynamical timescale this step
      if ts < min_ts then min_ts := ts;
    end;

    // Embedded local error over the FULL state (position AND velocity), reference-style
    // (Hairer & Wanner): per-quantity scale sc = atol + RTOL*|y|, err = max over bodies and over
    // {position, velocity} of |Δ|/sc; err<=1 means within tolerance. All 13 acceleration stages
    // are evaluated, so the velocity term uses ka13 directly (no end-node fold needed); the shared
    // E weights sum to zero (E1 pinned), so both estimates are clean O(dt^8) differences.
    err_r := (kv1 * E1 + kv6 * E6 + kv7 * E7 + kv8 * E8 + kv9 * E9 + kv10 * E10 + kv11 * E11 + kv12 * E12 + kv13 * E13) * dt;
    err_v := (ka1 * E1 + ka6 * E6 + ka7 * E7 + ka8 * E8 + ka9 * E9 + ka10 * E10 + ka11 * E11 + ka12 * E12 + ka13 * E13) * dt;
    sc_r  := ATOL_R + RTOL * TmpR[i].Magnitude3D;
    sc_v  := ATOL_V + RTOL * TmpV[i].Magnitude3D;
    err   := err_r.Magnitude3D / sc_r;
    errv  := err_v.Magnitude3D / sc_v;
    if IsNan(errv) or (errv > err) then err := errv;
    if IsNan(err) or (err > err_max) then err_max := err;   // capture NaN (Inf/Inf overshoot) too
  end;

  // Dynamical-timescale step limit. The embedded error estimate can't see a close encounter the
  // step jumps OVER (both 7th & 8th order miss it equally -> tiny error -> the too-large step is
  // wrongly accepted and the flyby's energy kick is lost, leaving a sun-bound ellipse instead of
  // the hyperbolic departure). So independently require the step <= TS_FRAC * min(|v|/|a|): if it's
  // bigger, inflate err_max to (ratio)^8 -- in the new normalised units err>1 means reject, so no
  // TOLERANCE factor is needed. With the 1/8 controller exponent this shrinks the step to exactly
  // ~SAFETY*TS_FRAC*min_ts. Comment this block out to get the pure original DP87 back.
  if (min_ts < 1.0E300) and (min_ts > 0.0) then
  begin
    ts := dt / (TS_FRAC * min_ts);               // step / limit; > 1 means too large
    if ts > 1.0 then
    begin
      ts := ts*ts;  ts := ts*ts;  ts := ts*ts;   // ts := (dt / (TS_FRAC*min_ts))^8  (already in err>1 units)
      if ts > err_max then err_max := ts;
    end;
  end;

  // Reference-style controller (see DormandPrince54 for the full rationale). err_max is tolerance-
  // normalised (err<=1 => within tol); accept on err_max<=1, next step = dt*SAFETY*(1/err_max)^(1/8)
  // (q=7 for the DP8(7) pair), single symmetric clamp so an accepted boundary step may back off to
  // ~0.9 instead of churning. Sign-encoded return: Result>0 => accepted (S advanced, value = next
  // step); Result<0 => rejected (S untouched, |Result| = retry step); NaN/Inf forced to a hard
  // rejected shrink so it can never masquerade as an accepted step.
  accepted := (err_max <= 1.0) and not (IsNan(err_max) or IsInfinite(err_max));

  if IsNan(err_max) or IsInfinite(err_max) then
    growth := MIN_SHRINK
  else if err_max > 0.0 then
  begin
    growth := SAFETY * Power(1.0 / err_max, 0.125);
    if growth < MIN_SHRINK then growth := MIN_SHRINK;
    if growth > MAX_GROWTH then growth := MAX_GROWTH;
  end
  else
    growth := MAX_GROWTH;

  if accepted then
  begin
    for i := Low(S) to High(S) do
    begin
      S[i].R := TmpR[i];
      S[i].V := TmpV[i];
      a[i]   := TmpA[i];
    end;
    Result := dt * growth;        // > 0 : accepted; next-step hint (may back off below dt)
  end
  else
    Result := -(dt * growth);     // < 0 : rejected; |Result| is the retry step
end;
{$ENDIF}

// ===========================================================================================
//  Shared post-Newtonian (1PN / EIH, beta=gamma=1) acceleration helpers for the _PN integrators.
//
//  Model: each integrated body in S is a massless TEST PARTICLE moving in the external field of
//  the perturbers P (the same "independent bodies" model as the Newtonian versions). Because the
//  test bodies carry no mass, each perturber's own Newtonian acceleration a_j and potential U_j
//  depend ONLY on the perturber snapshot, not on which body we integrate — so PerturberPN computes
//  them ONCE per snapshot and AccelPN reuses them for every body, instead of rebuilding them per
//  body as a bare A1PN call would.
//
//  NOTE: symplectic _PN integrators (Leapfrog/McLachlan) were tried and dropped — the 1PN term is
//  velocity-dependent, which breaks Stoermer-Verlet's position-only-force assumption and injects a
//  spurious precession of the same order as the real effect unless dt is ~60x smaller than the
//  Newtonian orbit needs. The relativistic effect belongs in a non-symplectic _PN integrator
//  (GaussRadau15_PN), which handles f(r,v) natively at coarse step.
//  1PN is very small but the other post-newtonian terms would be even smaller:
//  0PN   / Newtonian acceleration                      ~ (v/c)^0
//  1PN   / Schwarzschild precession                    ~ (v/c)^2
//  2PN   / high-order conservative orbital corrections ~ (v/c)^4
//  2.5PN / gravitational radiation reaction            ~ (v/c)^5
//  3PN   / conservative tail and memory effects        ~ (v/c)^6
// ===========================================================================================

procedure PerturberPN(const P: TState4DArray; var aP: TVec4DArray);
// Precompute, for each MASSIVE perturber j, its Newtonian acceleration a_j from the OTHER
// perturbers (test bodies are massless -> they don't contribute) packed into aP[j].X/Y/Z, and its
// potential U_j = sum_{k<>j} mu_k/r_jk packed into the otherwise-unused aP[j].W. O(N^2), once per
// snapshot. Massless perturbers get a zero entry (never read).
var
  N, j, k: Int64;
  d, pot: Double;
  dvec, acc: TVec4D;
begin
  N := Length(P);
  if Length(aP) <> N then SetLength(aP, N);
  for j := 0 to N-1 do
   begin
    FillChar(aP[j], SizeOf(TVec4D), 0);
    if P[j].GM <= 0.0 then Continue;
    FillChar(acc, SizeOf(TVec4D), 0);
    pot := 0.0;
    for k := 0 to N-1 do
     if (k <> j) and (P[k].GM > 0.0) then
      begin
       dvec := P[k].R - P[j].R;
       d := dvec.Magnitude3D;
       if d > 0.0 then
        begin
         acc := acc + dvec.InvCubeScale3D(P[k].GM);
         pot := pot + P[k].GM / d;
        end;
      end;
    aP[j]   := acc;
    aP[j].W := pot;        // U_j stored in W (see AccelPN); the 3D dot/scale ops ignore it
   end;
end;

function AccelPN(const Si: TState4D; const P: TState4DArray; const aP: TVec4DArray): TVec4D;
// Full acceleration (Newtonian + 1PN/EIH, beta=gamma=1) of the massless test body Si in the field
// of the perturbers P, given the per-snapshot precompute aP from PerturberPN (aP[j].X/Y/Z = a_j,
// aP[j].W = U_j). Same formula as A1PN, but the perturber quantities are taken as given rather
// than rebuilt for every body. Only U_i (the potential at Si) is recomputed here, O(N).
var
  N, j: Int64;
  rij, dv, newt, pn: TVec4D;
  Ui, vi2, rmag, rij3, ndot, Bj, dotfac: Double;
begin
  N := Length(P);
  FillChar(newt, SizeOf(TVec4D), 0);
  FillChar(pn,   SizeOf(TVec4D), 0);
  vi2 := Si.V or Si.V;

  // Newtonian acceleration of Si and its potential U_i = sum_j mu_j/r_ij (needed fully before B_j)
  Ui := 0.0;
  for j := 0 to N-1 do
   if P[j].GM > 0.0 then
    begin
     rij  := P[j].R - Si.R;                              // r_j - r_i
     rmag := rij.Magnitude3D;
     if rmag > 0.0 then
      begin
       newt := newt + rij.InvCubeScale3D(P[j].GM);
       Ui   := Ui + P[j].GM / rmag;
      end;
    end;

  // 1PN correction (see A1PN for the term-by-term derivation)
  for j := 0 to N-1 do
   if P[j].GM > 0.0 then
    begin
     rij  := Si.R - P[j].R;                              // r_i - r_j
     rmag := rij.Magnitude3D;
     if rmag <= 0.0 then Continue;
     rij3 := rmag*rmag*rmag;
     ndot := (rij or P[j].V) / rmag;
     Bj := -4.0*Ui - aP[j].W + vi2 + 2.0*(P[j].V or P[j].V) - 4.0*(Si.V or P[j].V)
           - 1.5*ndot*ndot + 0.5*((P[j].R - Si.R) or aP[j]);
     pn := pn + (P[j].R - Si.R).InvCubeScale3D(P[j].GM) * Bj;                 // term 1
     dv     := Si.V - P[j].V;
     dotfac := rij or (4.0*Si.V - 3.0*P[j].V);
     pn := pn + dv * (P[j].GM / rij3 * dotfac);                              // term 2
     pn := pn + aP[j] * (3.5 * P[j].GM / rmag);                              // term 3
    end;

  Result := newt + pn * INV_C2;
  Result.W := 0.0;
end;

{$IFDEF AVX2}
const
  PPN_ONE: Double = 1.0;
type
  PPPNArgs = ^TPPNArgs;
  TPPNArgs = packed record
    pRx, pRy, pRz, pGM: Pointer;   // input columns (node n)  @00h,08h,10h,18h
    paX, paY, paZ, pU: Pointer;    // output columns          @20h,28h,30h,38h
    N: NativeInt;                  // total perturbers         @40h
    nQuad: NativeInt;              // N div 4                  @48h
  end;

procedure PerturberPN_SoA_AVX2core(pArgs: PPPNArgs);
// AVX2 form of the O(N^2) aP precompute (PerturberPN), SIMD across 4 perturbers-as-bodies per outer step. For each
// j-quad it sums over ALL sources k:  a_j += GM_k*(R_k-R_j)/|R_k-R_j|^3  and  U_j += GM_k/|R_k-R_j|, masking the
// self term (r^2=0, exactly one lane per k in [j..j+3]) to zero via ~(r2==0). Exact vsqrtpd + one reciprocal.
// WRITES aX/aY/aZ/U[j..j+3]. Win64: rcx=pArgs. (All GP regs used are volatile; only xmm6..15 need saving.)
asm
  .NOFRAME
  sub     rsp, 0A0h
  vmovups [rsp+00h], xmm6
  vmovups [rsp+10h], xmm7
  vmovups [rsp+20h], xmm8
  vmovups [rsp+30h], xmm9
  vmovups [rsp+40h], xmm10
  vmovups [rsp+50h], xmm11
  vmovups [rsp+60h], xmm12
  vmovups [rsp+70h], xmm13
  vmovups [rsp+80h], xmm14
  vmovups [rsp+90h], xmm15
  mov     r9, [rcx+48h]                        // nQuad (outer counter)
  xor     r11, r11                             // joff = 0
@JQuad:
  mov     rax, [rcx+00h]
  vmovupd ymm0, [rax+r11]                      // Rjx (4 lanes)
  mov     rax, [rcx+08h]
  vmovupd ymm1, [rax+r11]                      // Rjy
  mov     rax, [rcx+10h]
  vmovupd ymm2, [rax+r11]                      // Rjz
  vxorpd  ymm3, ymm3, ymm3                     // accx
  vxorpd  ymm4, ymm4, ymm4                     // accy
  vxorpd  ymm5, ymm5, ymm5                     // accz
  vxorpd  ymm6, ymm6, ymm6                     // pot (U)
  mov     r8, [rcx+40h]                        // N (k counter)
  xor     rdx, rdx                             // koff = 0
@KLoop:
  mov     rax, [rcx+00h]
  vbroadcastsd ymm7, [rax+rdx]                 // Rkx
  mov     rax, [rcx+08h]
  vbroadcastsd ymm8, [rax+rdx]                 // Rky
  mov     rax, [rcx+10h]
  vbroadcastsd ymm9, [rax+rdx]                 // Rkz
  vsubpd  ymm7, ymm7, ymm0                     // dvx = Rkx - Rjx
  vsubpd  ymm8, ymm8, ymm1                     // dvy
  vsubpd  ymm9, ymm9, ymm2                     // dvz
  vmulpd  ymm10, ymm7, ymm7
  vfmadd231pd ymm10, ymm8, ymm8
  vfmadd231pd ymm10, ymm9, ymm9                // r2
  vsqrtpd ymm11, ymm10                         // rmag
  vbroadcastsd ymm13, [PPN_ONE]
  vdivpd  ymm13, ymm13, ymm11                  // rinv = 1/rmag  (inf on the self lane)
  mov     rax, [rcx+18h]
  vbroadcastsd ymm12, [rax+rdx]                // GMk
  vmulpd  ymm14, ymm12, ymm13                  // potterm = GMk*rinv
  vmulpd  ymm15, ymm13, ymm13                  // rinv^2
  vmulpd  ymm13, ymm14, ymm15                  // w = potterm*rinv^2 = GMk*rinv^3
  vxorpd  ymm15, ymm15, ymm15
  vcmppd  ymm15, ymm10, ymm15, 0               // eq = (r2 == 0)   self-lane mask
  vandnpd ymm13, ymm15, ymm13                  // w       &= ~eq   (zero the self lane)
  vandnpd ymm14, ymm15, ymm14                  // potterm &= ~eq
  vfmadd231pd ymm3, ymm7, ymm13                // accx += dvx*w
  vfmadd231pd ymm4, ymm8, ymm13                // accy += dvy*w
  vfmadd231pd ymm5, ymm9, ymm13                // accz += dvz*w
  vaddpd  ymm6, ymm6, ymm14                    // U += potterm
  add     rdx, 8
  dec     r8
  jnz     @KLoop
  mov     rax, [rcx+20h]
  vmovupd [rax+r11], ymm3                      // aX[j..j+3]
  mov     rax, [rcx+28h]
  vmovupd [rax+r11], ymm4                      // aY
  mov     rax, [rcx+30h]
  vmovupd [rax+r11], ymm5                      // aZ
  mov     rax, [rcx+38h]
  vmovupd [rax+r11], ymm6                      // U
  add     r11, 20h
  dec     r9
  jnz     @JQuad
  vmovups xmm6,  [rsp+00h]
  vmovups xmm7,  [rsp+10h]
  vmovups xmm8,  [rsp+20h]
  vmovups xmm9,  [rsp+30h]
  vmovups xmm10, [rsp+40h]
  vmovups xmm11, [rsp+50h]
  vmovups xmm12, [rsp+60h]
  vmovups xmm13, [rsp+70h]
  vmovups xmm14, [rsp+80h]
  vmovups xmm15, [rsp+90h]
  add     rsp, 0A0h
  vzeroupper
end;
{$ENDIF}

procedure PerturberPN_SoA(var Pert: TPerturberSoA; n: Int64);
// SoA form of PerturberPN for node n: fills Pert.aX/aY/aZ[n][j] = a_j (Newtonian accel of perturber j from the
// OTHER perturbers) and Pert.U[n][j] = U_j = sum_{k<>j} mu_k/r_jk. Every SoA entry is a real perturber (GM>0),
// so the massless-skip of the AoS version is gone. Reconstructs a TVec4D per body and reuses the exact 3D vector
// ops, so the result is bit-identical to PerturberPN. The precompute columns are (re)sized here on demand.
var
  N0, nn, j, k, jStart: Int64;
  d, pot: Double;
  dvec, acc, Rj: TVec4D;
  {$IFDEF AVX2}{$IFDEF PPN_ASM}
  ppnargs: TPPNArgs;
  {$ENDIF}{$ENDIF}
begin
  N0 := Pert.Count;
  nn := Length(Pert.Rx);
  if Length(Pert.aX) <> nn then
   begin
    SetLength(Pert.aX, nn); SetLength(Pert.aY, nn); SetLength(Pert.aZ, nn); SetLength(Pert.U, nn);
   end;
  if Length(Pert.aX[n]) <> N0 then
   begin
    SetLength(Pert.aX[n], N0); SetLength(Pert.aY[n], N0); SetLength(Pert.aZ[n], N0); SetLength(Pert.U[n], N0);
   end;
  jStart := 0;
  {$IFDEF AVX2}{$IFDEF PPN_ASM}
  if N0 >= 4 then
   begin
    ppnargs.pRx := @Pert.Rx[n][0]; ppnargs.pRy := @Pert.Ry[n][0]; ppnargs.pRz := @Pert.Rz[n][0]; ppnargs.pGM := @Pert.GM[n][0];
    ppnargs.paX := @Pert.aX[n][0]; ppnargs.paY := @Pert.aY[n][0]; ppnargs.paZ := @Pert.aZ[n][0]; ppnargs.pU := @Pert.U[n][0];
    ppnargs.N := N0; ppnargs.nQuad := N0 shr 2;
    PerturberPN_SoA_AVX2core(@ppnargs);
    jStart := (N0 shr 2) shl 2;
   end;
  {$ENDIF}{$ENDIF}
  for j := jStart to N0-1 do
   begin
    Rj.X := Pert.Rx[n][j]; Rj.Y := Pert.Ry[n][j]; Rj.Z := Pert.Rz[n][j]; Rj.W := 0.0;
    FillChar(acc, SizeOf(TVec4D), 0);
    pot := 0.0;
    for k := 0 to N0-1 do
     if k <> j then
      begin
       dvec.X := Pert.Rx[n][k] - Rj.X; dvec.Y := Pert.Ry[n][k] - Rj.Y; dvec.Z := Pert.Rz[n][k] - Rj.Z; dvec.W := 0.0;
       d := dvec.Magnitude3D;
       if d > 0.0 then
        begin
         acc := acc + dvec.InvCubeScale3D(Pert.GM[n][k]);
         pot := pot + Pert.GM[n][k] / d;
        end;
      end;
    Pert.aX[n][j] := acc.X; Pert.aY[n][j] := acc.Y; Pert.aZ[n][j] := acc.Z; Pert.U[n][j] := pot;
   end;
end;

{$IFDEF AVX2}
procedure AccelNewt_SoA_AVX2core(pRx, pRy, pRz, pGM, pSiR, pNewt, pUi: Pointer; nQuad: NativeInt);
// Newtonian pass of AccelPN over a multiple-of-4 block of PACKED perturbers, SIMD across 4 perturbers/iteration
// (the transpose of NewtonAccel_AVX2core: one body broadcast, 4 perturbers in lanes -- and since the SoA columns
// are contiguous, each load is a plain vmovupd, no AoS transpose). Computes
//   newt = sum_j GM_j*(R_j-Si.R)/|R_j-Si.R|^3   and   Ui = sum_j GM_j/|R_j-Si.R|
// then WRITES *pNewt (X,Y,Z,0) and *pUi. Exact vsqrtpd/vdivpd (not rsqrt+NR), so it tracks the scalar path to
// FMA-reassociation noise. No GM<=0 guard is needed -- the packed SoA holds real perturbers only.
// Win64: rcx=pRx rdx=pRy r8=pRz r9=pGM ; stack after the 0A0h prologue: [+0C8h]=pSiR [+0D0h]=pNewt [+0D8h]=pUi [+0E0h]=nQuad
asm
  .NOFRAME
  sub     rsp, 0A0h
  vmovups [rsp+00h], xmm6
  vmovups [rsp+10h], xmm7
  vmovups [rsp+20h], xmm8
  vmovups [rsp+30h], xmm9
  vmovups [rsp+40h], xmm10
  vmovups [rsp+50h], xmm11
  vmovups [rsp+60h], xmm12
  vmovups [rsp+70h], xmm13
  vmovups [rsp+80h], xmm14
  vmovups [rsp+90h], xmm15

  mov     rax, [rsp+0C8h]                 // pSiR
  vbroadcastsd ymm13, [rax+00h]           // Si.R.X
  vbroadcastsd ymm14, [rax+08h]           // Si.R.Y
  vbroadcastsd ymm15, [rax+10h]           // Si.R.Z

  vxorpd  ymm3, ymm3, ymm3                // newt.x partials (4 lanes)
  vxorpd  ymm4, ymm4, ymm4                // newt.y
  vxorpd  ymm5, ymm5, ymm5                // newt.z
  vxorpd  ymm6, ymm6, ymm6                // Ui

  mov     r10, [rsp+0E0h]                 // nQuad
@Loop:
  vmovupd ymm0, [rcx]                     // Rx[4]
  vmovupd ymm1, [rdx]                     // Ry[4]
  vmovupd ymm2, [r8]                      // Rz[4]
  vsubpd  ymm0, ymm0, ymm13               // dx = Rx - Si.X   (r_j - r_i)
  vsubpd  ymm1, ymm1, ymm14               // dy
  vsubpd  ymm2, ymm2, ymm15               // dz
  vmulpd  ymm7, ymm0, ymm0
  vfmadd231pd ymm7, ymm1, ymm1
  vfmadd231pd ymm7, ymm2, ymm2            // r2 = dx^2+dy^2+dz^2
  vsqrtpd ymm8, ymm7                      // rmag = sqrt(r2)
  vmovupd ymm9, [r9]                      // GM[4]
  vdivpd  ymm10, ymm9, ymm8               // GM/rmag
  vaddpd  ymm6, ymm6, ymm10               // Ui += GM/rmag
  vmulpd  ymm11, ymm7, ymm8               // rmag^3 = r2*rmag
  vdivpd  ymm11, ymm9, ymm11              // w = GM / rmag^3
  vfmadd231pd ymm3, ymm0, ymm11           // newt.x += dx*w
  vfmadd231pd ymm4, ymm1, ymm11           // newt.y += dy*w
  vfmadd231pd ymm5, ymm2, ymm11           // newt.z += dz*w
  add     rcx, 20h
  add     rdx, 20h
  add     r8,  20h
  add     r9,  20h
  dec     r10
  jnz     @Loop

  // horizontal-reduce the 4 lanes of ymm3/4/5/6 to scalars
  vextractf128 xmm7, ymm3, 1
  vaddpd  xmm3, xmm3, xmm7
  vhaddpd xmm3, xmm3, xmm3                // newt.x
  vextractf128 xmm7, ymm4, 1
  vaddpd  xmm4, xmm4, xmm7
  vhaddpd xmm4, xmm4, xmm4                // newt.y
  vextractf128 xmm7, ymm5, 1
  vaddpd  xmm5, xmm5, xmm7
  vhaddpd xmm5, xmm5, xmm5                // newt.z
  vextractf128 xmm7, ymm6, 1
  vaddpd  xmm6, xmm6, xmm7
  vhaddpd xmm6, xmm6, xmm6                // Ui

  mov     rax, [rsp+0D0h]                 // pNewt
  vmovsd  [rax+00h], xmm3
  vmovsd  [rax+08h], xmm4
  vmovsd  [rax+10h], xmm5
  xor     r11, r11
  mov     [rax+18h], r11                  // newt.W = 0
  mov     rax, [rsp+0D8h]                 // pUi
  vmovsd  [rax], xmm6

  vmovups xmm6,  [rsp+00h]
  vmovups xmm7,  [rsp+10h]
  vmovups xmm8,  [rsp+20h]
  vmovups xmm9,  [rsp+30h]
  vmovups xmm10, [rsp+40h]
  vmovups xmm11, [rsp+50h]
  vmovups xmm12, [rsp+60h]
  vmovups xmm13, [rsp+70h]
  vmovups xmm14, [rsp+80h]
  vmovups xmm15, [rsp+90h]
  add     rsp, 0A0h
  vzeroupper
end;
{$ENDIF}

{$IFDEF AVX2}
const
  PN_2:    Double = 2.0;
  PN_3:    Double = 3.0;
  PN_4:    Double = 4.0;
  PN_1PT5: Double = 1.5;
  PN_0PT5: Double = 0.5;
  PN_3PT5: Double = 3.5;
type
  PPN1Args = ^TPN1Args;
  TPN1Args = packed record
    pRx, pRy, pRz, pVx, pVy, pVz, paX, paY, paZ, pGM, pU: Pointer;   // @00h..50h : node-n column bases
    SiRx, SiRy, SiRz, SiVx, SiVy, SiVz: Double;                       // @58h..80h
    Ui, vi2: Double;                                                  // @88h, 90h
    pPn: Pointer;                                                     // @98h
    nQuad: NativeInt;                                                 // @0A0h
  end;

procedure AccelPN1_SoA_AVX2core(pArgs: PPN1Args);
// 1PN pass of AccelPN over a multiple-of-4 block of PACKED perturbers, SIMD across 4 perturbers/iteration -- a
// direct translation of the validated raw-scalar 1PN blueprint in AccelPN_SoA. Per lane it forms the three PN
// terms via coefficients cA=g3*Bj (term1: pn-=rij*cA), cB=g3*dotfac (term2: pn+=(SiV-Vj)*cB), cC=3.5*GMj/rmag
// (term3: pn+=aPj*cC), with g3=GMj/rmag^3. Register pressure is high, so rij/Vj/aPj are re-read from the columns
// (L1) and cA/cB/cC/g3/rmag spill to the local frame. WRITES *pPn (X,Y,Z,0). Win64: rcx=pArgs.
asm
  .NOFRAME
  sub     rsp, 140h
  vmovups [rsp+00h], xmm6
  vmovups [rsp+10h], xmm7
  vmovups [rsp+20h], xmm8
  vmovups [rsp+30h], xmm9
  vmovups [rsp+40h], xmm10
  vmovups [rsp+50h], xmm11
  vmovups [rsp+60h], xmm12
  vmovups [rsp+70h], xmm13
  vmovups [rsp+80h], xmm14
  vmovups [rsp+90h], xmm15
  // held across the loop: ymm0/1/2 = pnX/Y/Z ; ymm6/7/8 = SiVx/y/z ; ymm9 = C0 = vi2 - 4*Ui
  vxorpd  ymm0, ymm0, ymm0
  vxorpd  ymm1, ymm1, ymm1
  vxorpd  ymm2, ymm2, ymm2
  vbroadcastsd ymm6, [rcx+70h]                  // SiVx
  vbroadcastsd ymm7, [rcx+78h]                  // SiVy
  vbroadcastsd ymm8, [rcx+80h]                  // SiVz
  vbroadcastsd ymm9,  [rcx+90h]                 // vi2
  vbroadcastsd ymm10, [rcx+88h]                 // Ui
  vbroadcastsd ymm11, [PN_4]
  vfnmadd231pd ymm9, ymm11, ymm10               // C0 = vi2 - 4*Ui
  mov     r10, [rcx+0A0h]                       // nQuad
  xor     r11, r11                              // roff = 0
@Loop:
  // ---- rij = Si.R - Rj  (ymm3/4/5, kept through the whole body) ----
  mov     rax, [rcx+00h]
  vmovupd ymm3, [rax+r11]
  vbroadcastsd ymm12, [rcx+58h]
  vsubpd  ymm3, ymm12, ymm3                     // rijx
  mov     rax, [rcx+08h]
  vmovupd ymm4, [rax+r11]
  vbroadcastsd ymm12, [rcx+60h]
  vsubpd  ymm4, ymm12, ymm4                     // rijy
  mov     rax, [rcx+10h]
  vmovupd ymm5, [rax+r11]
  vbroadcastsd ymm12, [rcx+68h]
  vsubpd  ymm5, ymm12, ymm5                     // rijz
  // ---- r2, rmag, rij3, g3, cC ----
  vmulpd  ymm13, ymm3, ymm3
  vfmadd231pd ymm13, ymm4, ymm4
  vfmadd231pd ymm13, ymm5, ymm5                 // r2
  vsqrtpd ymm14, ymm13                          // rmag
  vmulpd  ymm15, ymm13, ymm14                   // rij3 = r2*rmag
  mov     rax, [rcx+48h]
  vmovupd ymm12, [rax+r11]                      // GMj
  vdivpd  ymm11, ymm12, ymm15                   // g3 = GMj/rij3
  vmovupd [rsp+100h], ymm11                     // spill g3
  vmovupd [rsp+120h], ymm14                     // spill rmag
  vbroadcastsd ymm13, [PN_3PT5]
  vmulpd  ymm13, ymm13, ymm12                   // 3.5*GMj
  vdivpd  ymm13, ymm13, ymm14                   // cC = 3.5*GMj/rmag
  vmovupd [rsp+0E0h], ymm13                     // spill cC
  // ---- Bj (built in ymm10) ----
  mov     rax, [rcx+18h]
  vmovupd ymm10, [rax+r11]                      // Vjx
  mov     rax, [rcx+20h]
  vmovupd ymm11, [rax+r11]                      // Vjy
  mov     rax, [rcx+28h]
  vmovupd ymm12, [rax+r11]                      // Vjz
  vmulpd  ymm13, ymm3, ymm10
  vfmadd231pd ymm13, ymm4, ymm11
  vfmadd231pd ymm13, ymm5, ymm12                // rijV = rij . Vj
  vmovupd ymm14, [rsp+120h]                     // rmag
  vdivpd  ymm13, ymm13, ymm14                   // ndot = rijV/rmag
  vmulpd  ymm13, ymm13, ymm13                   // ndot^2   (kept in ymm13)
  vmulpd  ymm14, ymm10, ymm10
  vfmadd231pd ymm14, ymm11, ymm11
  vfmadd231pd ymm14, ymm12, ymm12               // VjV      (ymm14)
  vmulpd  ymm15, ymm6, ymm10
  vfmadd231pd ymm15, ymm7, ymm11
  vfmadd231pd ymm15, ymm8, ymm12                // SvV      (ymm15)
  vmovapd ymm10, ymm9                           // Bj = C0
  vbroadcastsd ymm12, [PN_2]
  vfmadd231pd ymm10, ymm12, ymm14               // Bj += 2*VjV
  vbroadcastsd ymm12, [PN_4]
  vfnmadd231pd ymm10, ymm12, ymm15              // Bj -= 4*SvV
  vbroadcastsd ymm12, [PN_1PT5]
  vfnmadd231pd ymm10, ymm12, ymm13              // Bj -= 1.5*ndot^2
  mov     rax, [rcx+50h]
  vmovupd ymm14, [rax+r11]                      // Uj
  vsubpd  ymm10, ymm10, ymm14                   // Bj -= Uj
  mov     rax, [rcx+30h]
  vmovupd ymm13, [rax+r11]                      // ajx
  mov     rax, [rcx+38h]
  vmovupd ymm14, [rax+r11]                      // ajy
  mov     rax, [rcx+40h]
  vmovupd ymm15, [rax+r11]                      // ajz
  vmulpd  ymm12, ymm3, ymm13
  vfmadd231pd ymm12, ymm4, ymm14
  vfmadd231pd ymm12, ymm5, ymm15                // rij . aPj
  vbroadcastsd ymm11, [PN_0PT5]
  vfnmadd231pd ymm10, ymm11, ymm12              // Bj -= 0.5*(rij.aPj)   (= Bj + 0.5*dRa)
  vmovupd ymm11, [rsp+100h]                     // g3
  vmulpd  ymm10, ymm10, ymm11                   // cA = g3*Bj
  vmovupd [rsp+0A0h], ymm10                     // spill cA
  // ---- dotfac, cB ----
  mov     rax, [rcx+18h]
  vmovupd ymm10, [rax+r11]                      // Vjx
  mov     rax, [rcx+20h]
  vmovupd ymm11, [rax+r11]                      // Vjy
  mov     rax, [rcx+28h]
  vmovupd ymm12, [rax+r11]                      // Vjz
  vbroadcastsd ymm13, [PN_4]
  vbroadcastsd ymm14, [PN_3]
  vmulpd  ymm15, ymm13, ymm6                    // 4*SiVx
  vfnmadd231pd ymm15, ymm14, ymm10              // 4SiVx - 3Vjx
  vmulpd  ymm10, ymm3, ymm15                    // dotfac  = rijx*(...)
  vmulpd  ymm15, ymm13, ymm7                    // 4*SiVy
  vfnmadd231pd ymm15, ymm14, ymm11              // 4SiVy - 3Vjy
  vfmadd231pd ymm10, ymm4, ymm15                // dotfac += rijy*(...)
  vmulpd  ymm15, ymm13, ymm8                    // 4*SiVz
  vfnmadd231pd ymm15, ymm14, ymm12              // 4SiVz - 3Vjz
  vfmadd231pd ymm10, ymm5, ymm15                // dotfac  (ymm10)
  vmovupd ymm11, [rsp+100h]                     // g3
  vmulpd  ymm10, ymm10, ymm11                   // cB = g3*dotfac
  vmovupd [rsp+0C0h], ymm10                     // spill cB
  // ---- pn update: pn -= rij*cA ; pn += (SiV-Vj)*cB ; pn += aPj*cC ----
  vmovupd ymm13, [rsp+0A0h]                     // cA
  vfnmadd231pd ymm0, ymm3, ymm13                // pnX -= rijx*cA
  vfnmadd231pd ymm1, ymm4, ymm13                // pnY -= rijy*cA
  vfnmadd231pd ymm2, ymm5, ymm13                // pnZ -= rijz*cA
  vmovupd ymm14, [rsp+0C0h]                     // cB
  mov     rax, [rcx+18h]
  vmovupd ymm10, [rax+r11]
  vsubpd  ymm10, ymm6, ymm10                    // dvx = SiVx - Vjx
  vfmadd231pd ymm0, ymm10, ymm14                // pnX += dvx*cB
  mov     rax, [rcx+20h]
  vmovupd ymm10, [rax+r11]
  vsubpd  ymm10, ymm7, ymm10                    // dvy
  vfmadd231pd ymm1, ymm10, ymm14
  mov     rax, [rcx+28h]
  vmovupd ymm10, [rax+r11]
  vsubpd  ymm10, ymm8, ymm10                    // dvz
  vfmadd231pd ymm2, ymm10, ymm14
  vmovupd ymm15, [rsp+0E0h]                     // cC
  mov     rax, [rcx+30h]
  vmovupd ymm10, [rax+r11]                      // ajx
  vfmadd231pd ymm0, ymm10, ymm15                // pnX += ajx*cC
  mov     rax, [rcx+38h]
  vmovupd ymm10, [rax+r11]
  vfmadd231pd ymm1, ymm10, ymm15
  mov     rax, [rcx+40h]
  vmovupd ymm10, [rax+r11]
  vfmadd231pd ymm2, ymm10, ymm15
  add     r11, 20h
  dec     r10
  jnz     @Loop
  // ---- horizontal-reduce pnX/Y/Z (4 lanes each) -> *pPn ----
  mov     rax, [rcx+98h]                        // pPn
  vextractf128 xmm3, ymm0, 1
  vaddpd  xmm0, xmm0, xmm3
  vhaddpd xmm0, xmm0, xmm0
  vmovsd  [rax+00h], xmm0
  vextractf128 xmm3, ymm1, 1
  vaddpd  xmm1, xmm1, xmm3
  vhaddpd xmm1, xmm1, xmm1
  vmovsd  [rax+08h], xmm1
  vextractf128 xmm3, ymm2, 1
  vaddpd  xmm2, xmm2, xmm3
  vhaddpd xmm2, xmm2, xmm2
  vmovsd  [rax+10h], xmm2
  xor     r11, r11
  mov     [rax+18h], r11                        // pn.W = 0
  vmovups xmm6,  [rsp+00h]
  vmovups xmm7,  [rsp+10h]
  vmovups xmm8,  [rsp+20h]
  vmovups xmm9,  [rsp+30h]
  vmovups xmm10, [rsp+40h]
  vmovups xmm11, [rsp+50h]
  vmovups xmm12, [rsp+60h]
  vmovups xmm13, [rsp+70h]
  vmovups xmm14, [rsp+80h]
  vmovups xmm15, [rsp+90h]
  add     rsp, 140h
  vzeroupper
end;
{$ENDIF}

function AccelPN_SoA(const Si: TState4D; const Pert: TPerturberSoA; n: Int64): TVec4D;
// SoA form of AccelPN for node n. Reconstructs each perturber's R/V/a_j/U_j from the packed columns and mirrors
// the AoS expressions term-for-term (all vector ops are 3D; W is set where the physics needs it), so the result
// is bit-identical to AccelPN. Requires PerturberPN_SoA to have filled the aX/aY/aZ/U columns for node n first.
var
  N0, j, jStart: Int64;
  Rj, Vj, aPj, rij, dv, newt, pn: TVec4D;
  Ui, vi2, rmag, rij3, ndot, Bj, dotfac: Double;
  {$IFDEF AVX2}
  {$IFDEF PN1_ASM}
  pn1args: TPN1Args;
  {$ELSE}
  Rjx, Rjy, Rjz, Vjx, Vjy, Vjz, ajx, ajy, ajz, GMj, Uj: Double;   // raw-scalar 1PN blueprint (the AVX2 bulk) locals
  rijx, rijy, rijz, r2, rijV, VjV, SvV, dRa, t1, w2, w3: Double;
  {$ENDIF}
  {$ENDIF}
begin
  N0 := Pert.Count;
  FillChar(newt, SizeOf(TVec4D), 0);
  FillChar(pn,   SizeOf(TVec4D), 0);
  vi2 := Si.V or Si.V;

  // Newtonian acceleration of Si and its potential U_i (needed fully before the B_j terms). The AVX2 build
  // does the multiple-of-4 bulk in the kernel (which WRITES newt/Ui) and the 0..3 remainder in the scalar
  // tail below; the compat build has jStart=0, so the tail loop does everything (identical to before).
  Ui := 0.0;
  jStart := 0;
  {$IFDEF AVX2}
  if N0 >= 4 then
   begin
    AccelNewt_SoA_AVX2core(@Pert.Rx[n][0], @Pert.Ry[n][0], @Pert.Rz[n][0], @Pert.GM[n][0], @Si.R, @newt, @Ui, N0 shr 2);
    jStart := (N0 shr 2) shl 2;                         // = N0 and not 3
   end;
  {$ENDIF}
  for j := jStart to N0-1 do
   begin
    Rj.X := Pert.Rx[n][j]; Rj.Y := Pert.Ry[n][j]; Rj.Z := Pert.Rz[n][j]; Rj.W := 0.0;
    rij  := Rj - Si.R;                                  // r_j - r_i
    rmag := rij.Magnitude3D;
    if rmag > 0.0 then
     begin
      newt := newt + rij.InvCubeScale3D(Pert.GM[n][j]);
      Ui   := Ui + Pert.GM[n][j] / rmag;
     end;
   end;

  // 1PN correction (see AccelPN / A1PN for the term-by-term derivation). AVX2 build: a raw-scalar "blueprint"
  // over the multiple-of-4 bulk -- the TVec4D ops expanded to component math (sqrt-based) so it maps 1:1 onto
  // the coming AVX2 kernel and tracks AoS to ~1e-16; the 0..3 remainder uses the exact TVec4D form (as does
  // the whole compat build, where jStart stays 0).
  //jStart := 0;
  {$IFDEF AVX2}
  jStart := (N0 shr 2) shl 2;
  {$IFDEF PN1_ASM}
  if jStart > 0 then
   begin
    pn1args.pRx := @Pert.Rx[n][0]; pn1args.pRy := @Pert.Ry[n][0]; pn1args.pRz := @Pert.Rz[n][0];
    pn1args.pVx := @Pert.Vx[n][0]; pn1args.pVy := @Pert.Vy[n][0]; pn1args.pVz := @Pert.Vz[n][0];
    pn1args.paX := @Pert.aX[n][0]; pn1args.paY := @Pert.aY[n][0]; pn1args.paZ := @Pert.aZ[n][0];
    pn1args.pGM := @Pert.GM[n][0]; pn1args.pU := @Pert.U[n][0];
    pn1args.SiRx := Si.R.X; pn1args.SiRy := Si.R.Y; pn1args.SiRz := Si.R.Z;
    pn1args.SiVx := Si.V.X; pn1args.SiVy := Si.V.Y; pn1args.SiVz := Si.V.Z;
    pn1args.Ui := Ui; pn1args.vi2 := vi2;
    pn1args.pPn := @pn; pn1args.nQuad := N0 shr 2;
    AccelPN1_SoA_AVX2core(@pn1args);
   end;
  {$ELSE}
  for j := 0 to jStart-1 do
   begin
    Rjx := Pert.Rx[n][j]; Rjy := Pert.Ry[n][j]; Rjz := Pert.Rz[n][j];
    Vjx := Pert.Vx[n][j]; Vjy := Pert.Vy[n][j]; Vjz := Pert.Vz[n][j];
    ajx := Pert.aX[n][j]; ajy := Pert.aY[n][j]; ajz := Pert.aZ[n][j];
    GMj := Pert.GM[n][j]; Uj := Pert.U[n][j];
    rijx := Si.R.X - Rjx; rijy := Si.R.Y - Rjy; rijz := Si.R.Z - Rjz;      // rij = r_i - r_j
    r2   := rijx*rijx + rijy*rijy + rijz*rijz;
    rmag := Sqrt(r2);
    rij3 := r2*rmag;
    rijV := rijx*Vjx + rijy*Vjy + rijz*Vjz;                                // rij . Vj
    ndot := rijV / rmag;
    VjV  := Vjx*Vjx + Vjy*Vjy + Vjz*Vjz;                                   // Vj . Vj
    SvV  := Si.V.X*Vjx + Si.V.Y*Vjy + Si.V.Z*Vjz;                          // Si.V . Vj
    dRa  := (Rjx-Si.R.X)*ajx + (Rjy-Si.R.Y)*ajy + (Rjz-Si.R.Z)*ajz;        // (Rj-Si.R) . aPj
    Bj   := -4.0*Ui - Uj + vi2 + 2.0*VjV - 4.0*SvV - 1.5*ndot*ndot + 0.5*dRa;
    t1   := GMj / rij3 * Bj;
    pn.X := pn.X - rijx*t1;                                                // term 1: GMj*(Rj-Si.R)/rmag^3 * Bj  ((Rj-Si.R) = -rij)
    pn.Y := pn.Y - rijy*t1;
    pn.Z := pn.Z - rijz*t1;
    dotfac := rijx*(4.0*Si.V.X - 3.0*Vjx) + rijy*(4.0*Si.V.Y - 3.0*Vjy) + rijz*(4.0*Si.V.Z - 3.0*Vjz);
    w2   := GMj / rij3 * dotfac;
    pn.X := pn.X + (Si.V.X - Vjx)*w2;                                      // term 2: (Si.V-Vj) * GMj/rij3 * (rij.(4Si.V-3Vj))
    pn.Y := pn.Y + (Si.V.Y - Vjy)*w2;
    pn.Z := pn.Z + (Si.V.Z - Vjz)*w2;
    w3   := 3.5 * GMj / rmag;
    pn.X := pn.X + ajx*w3;                                                 // term 3: aPj * 3.5*GMj/rmag
    pn.Y := pn.Y + ajy*w3;
    pn.Z := pn.Z + ajz*w3;
   end;
  {$ENDIF}
  {$ENDIF}
  for j := jStart to N0-1 do
   begin
    Rj.X := Pert.Rx[n][j]; Rj.Y := Pert.Ry[n][j]; Rj.Z := Pert.Rz[n][j]; Rj.W := 0.0;
    Vj.X := Pert.Vx[n][j]; Vj.Y := Pert.Vy[n][j]; Vj.Z := Pert.Vz[n][j]; Vj.W := 0.0;
    aPj.X := Pert.aX[n][j]; aPj.Y := Pert.aY[n][j]; aPj.Z := Pert.aZ[n][j]; aPj.W := Pert.U[n][j];
    rij  := Si.R - Rj;                                  // r_i - r_j
    rmag := rij.Magnitude3D;
    if rmag <= 0.0 then Continue;
    rij3 := rmag*rmag*rmag;
    ndot := (rij or Vj) / rmag;
    Bj := -4.0*Ui - aPj.W + vi2 + 2.0*(Vj or Vj) - 4.0*(Si.V or Vj)
          - 1.5*ndot*ndot + 0.5*((Rj - Si.R) or aPj);
    pn := pn + (Rj - Si.R).InvCubeScale3D(Pert.GM[n][j]) * Bj;               // term 1
    dv     := Si.V - Vj;
    dotfac := rij or (4.0*Si.V - 3.0*Vj);
    pn := pn + dv * (Pert.GM[n][j] / rij3 * dotfac);                         // term 2
    pn := pn + aPj * (3.5 * Pert.GM[n][j] / rmag);                          // term 3
   end;

  Result := newt + pn * INV_C2;
  Result.W := 0.0;
end;

function PNAccelSelect(const Si: TState4D; const Pn: TState4DArray; const aPn: TVec4DArray; Pert: PPerturberSoA; n: Int64): TVec4D;
// Selector for the perturber 1PN acceleration at node n: Pert=nil -> AoS AccelPN (old path); non-nil -> SoA
// AccelPN_SoA. Under PN_SOA_VALIDATE both run, the known-good AoS result stays active, and the worst component
// difference is folded into the global PN_SoA_MaxDiff (expected ~0 -- the SoA port is bit-identical by design).
{$IFDEF PN_SOA_VALIDATE}
var
  aSoA: TVec4D;
  dmax: Double;
{$ENDIF}
begin
  if Pert = nil then
   Result := AccelPN(Si, Pn, aPn)
  else
   begin
    {$IFDEF PN_SOA_VALIDATE}
    Result := AccelPN(Si, Pn, aPn);
    aSoA   := AccelPN_SoA(Si, Pert^, n);
    dmax := Abs(aSoA.X - Result.X);
    if Abs(aSoA.Y - Result.Y) > dmax then dmax := Abs(aSoA.Y - Result.Y);
    if Abs(aSoA.Z - Result.Z) > dmax then dmax := Abs(aSoA.Z - Result.Z);
    if dmax > PN_SoA_MaxDiff then PN_SoA_MaxDiff := dmax;
    {$ELSE}
    Result := AccelPN_SoA(Si, Pert^, n);
    {$ENDIF}
   end;
end;

procedure AddCS(var Acc, Comp: TVec4D; const Incr: TVec4D);
// Compensated (Kahan) summation of a 3D increment into Acc, carrying the lost
// low-order bits in Comp. This is what lets IAS15 reach machine precision over
// very long integrations. Operates on X,Y,Z only; W is left untouched.
var
  y, t: Double;
begin
  y := Incr.X - Comp.X; t := Acc.X + y; Comp.X := (t - Acc.X) - y; Acc.X := t;
  y := Incr.Y - Comp.Y; t := Acc.Y + y; Comp.Y := (t - Acc.Y) - y; Acc.Y := t;
  y := Incr.Z - Comp.Z; t := Acc.Z + y; Comp.Z := (t - Acc.Z) - y; Acc.Z := t;
end;

function GaussRadau15(var dt: Double; dt_last: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays; B, E, Br, Er: TVec4DArrays; csx, csv: TVec4DArray): Boolean;
// IAS15 — 15th-order Gauss-Radau integrator with adaptive step size
// (Everhart 1985; Rein & Spiegel 2015; timestep per Pham, Rein & Spiegel 2023).
// Ported from REBOUND's integrator_ias15.c to fit the precomputed-perturber model
// used by the other integrators here: every body in S is advanced independently in
// the external field defined by the perturber snapshots in P.
//
// Unlike the explicit integrators this is implicit: the acceleration over the step
// is represented as a 7th-degree polynomial whose coefficients B[0..6] are found by
// a predictor-corrector iteration that re-evaluates the force at the 7 Gauss-Radau
// nodes (2 iterations on a warm step, up to 12 cold). The polynomial state is
// carried across steps (B, E warm-started, Br, Er kept as rejection backups), and
// position/velocity are accumulated with compensated summation (csx, csv).
//
// PARAMETERS (all body-indexed arrays must have Length = Length(S)):
//   dt      in : trial step; out: suggested next step.
//   dt_last : length of the last SUCCESSFULLY completed step (0 on the first call).
//   a       out: end-of-step acceleration of each body (polynomial at s=1); ignored
//                on input. Handy as a display/diagnostic; not required as input.
//   S       in/out: states; advanced in place ONLY when the step is accepted.
//   P       in : P[0] = perturbers at t0; P[1..7] = perturbers at t0 + h[n]*dt.
//                P[0] is unchanged between rejection retries; P[1..7] must be
//                re-sampled at the new node times before each retry.
//   B,E,Br,Er : persistent predictor state, each dimensioned [0..6][0..High(S)].
//               Zero them once before the first call; the routine maintains them.
//   csx, csv : persistent compensated-summation accumulators; zero before first call.
//
// RESULT: True  -> step accepted, S advanced by the *input* dt (caller should set its
//                  own dt_last to that value); dt now holds the suggested next step.
//         False -> step rejected; dt holds a smaller step. Re-sample P[1..7] at the
//                  new nodes and call again (S, dt_last unchanged).
const
  safety_factor = 0.25;        // max step shrink before forced retry / inverse max growth
  EPSILON       = 1.0E-9;      // accuracy control (REBOUND default)
  // Gauss-Radau node spacings
  h: array[0..7] of Double = (
    0.0, 0.0562625605369221464656521910318, 0.180240691736892364987579942780,
    0.352624717113169637373907769648, 0.547153626330555383001448554766,
    0.734210177215410531523210605558, 0.885320946839095768090359771030,
    0.977520613561287501891174488626);
  // Pairwise node differences h[j]-h[k] (used as divisors when building g)
  rr: array[0..27] of Double = (
    0.0562625605369221464656522, 0.1802406917368923649875799, 0.1239781311999702185219278,
    0.3526247171131696373739078, 0.2963621565762474909082556, 0.1723840253762772723863278,
    0.5471536263305553830014486, 0.4908910657936332365357964, 0.3669129345936630180138686,
    0.1945289092173857456275408, 0.7342101772154105315232106, 0.6779476166784883850575584,
    0.5539694854785181665356307, 0.3815854601022408941493028, 0.1870565508848551485217621,
    0.8853209468390957680903598, 0.8290583863021736216247076, 0.7050802551022034031027798,
    0.5326962297259261307164520, 0.3381673205085403850889112, 0.1511107696236852365671492,
    0.9775206135612875018911745, 0.9212580530243653554255223, 0.7972799218243951369035945,
    0.6248958964481178645172667, 0.4303669872307321188897259, 0.2433104363458769703679639,
    0.0921996667221917338008147);
  // g -> b conversion (Newton to Taylor form)
  c: array[0..20] of Double = (
    -0.0562625605369221464656522, 0.0101408028300636299864818, -0.2365032522738145114532321,
    -0.0035758977292516175949345, 0.0935376952594620658957485, -0.5891279693869841488271399,
    0.0019565654099472210769006, -0.0547553868890686864408084, 0.4158812000823068616886219,
    -1.1362815957175395318285885, -0.0014365302363708915424460, 0.0421585277212687077072973,
    -0.3600995965020568122897665, 1.2501507118406910258505441, -1.8704917729329500633517991,
    0.0012717903090268677492943, -0.0387603579159067703699046, 0.3609622434528459832253398,
    -1.4668842084004269643701553, 2.9061362593084293014237913, -2.7558127197720458314421588);
  // b -> g conversion, used to warm-start g from the predicted b
  d: array[0..20] of Double = (
    0.0562625605369221464656522, 0.0031654757181708292499905, 0.2365032522738145114532321,
    0.0001780977692217433881125, 0.0457929855060279188954539, 0.5891279693869841488271399,
    0.0000100202365223291272096, 0.0084318571535257015445000, 0.2535340690545692665214616,
    1.1362815957175395318285885, 0.0000005637641639318207610, 0.0015297840025004658189490,
    0.0978342365324440053653648, 0.8752546646840910912297246, 1.8704917729329500633517991,
    0.0000000317188154017613665, 0.0002762930909826476593130, 0.0360285539837364596003871,
    0.5767330002770787313544596, 2.2485887607691597933926895, 2.7558127197720458314421588);
var
  i, j, n, iter: Int64;
  b0, b1, b2, b3, b4, b5, b6,
  g0, g1, g2, g3, g4, g5, g6,
  csb0, csb1, csb2, csb3, csb4, csb5, csb6,
  a0, v0, term, rNode, aNode, gvec, dg, gOld, vtmp: TVec4D;
  sJ2: TState4D;                                  // scratch state (only .R used) for the J2 term at node n
  GM, hn, dtDone, d2, pcErr, pcErrLast, amag,
  y2, y3, y4, a0sq, timescale2, minTS2, dt_new, ratio, errscale: Double;
  haveTS: Boolean;

  procedure PredictStep(idx: Int64; q: Double; const srcE, srcB: TVec4DArrays);
  // Predict the b coefficients to use at the start of the next sequence, scaling by
  // the step-size ratio q. The not-yet-applied correction (srcB - srcE) is carried
  // forward. Mirrors REBOUND's predict_next_step for a single body.
  var
    q1, q2, q3, q4, q5, q6, q7: Double;
    be0, be1, be2, be3, be4, be5, be6: TVec4D;
  begin
    if q > 20.0 then
    begin
      // Step grew too much to trust the prediction — restart from zero.
      FillChar(E[0][idx], SizeOf(TVec4D), 0); FillChar(E[1][idx], SizeOf(TVec4D), 0);
      FillChar(E[2][idx], SizeOf(TVec4D), 0); FillChar(E[3][idx], SizeOf(TVec4D), 0);
      FillChar(E[4][idx], SizeOf(TVec4D), 0); FillChar(E[5][idx], SizeOf(TVec4D), 0);
      FillChar(E[6][idx], SizeOf(TVec4D), 0);
      FillChar(B[0][idx], SizeOf(TVec4D), 0); FillChar(B[1][idx], SizeOf(TVec4D), 0);
      FillChar(B[2][idx], SizeOf(TVec4D), 0); FillChar(B[3][idx], SizeOf(TVec4D), 0);
      FillChar(B[4][idx], SizeOf(TVec4D), 0); FillChar(B[5][idx], SizeOf(TVec4D), 0);
      FillChar(B[6][idx], SizeOf(TVec4D), 0);
      Exit;
    end;
    q1 := q;       q2 := q1*q1; q3 := q1*q2; q4 := q2*q2;
    q5 := q2*q3;   q6 := q3*q3; q7 := q3*q4;
    be0 := srcB[0][idx] - srcE[0][idx]; be1 := srcB[1][idx] - srcE[1][idx];
    be2 := srcB[2][idx] - srcE[2][idx]; be3 := srcB[3][idx] - srcE[3][idx];
    be4 := srcB[4][idx] - srcE[4][idx]; be5 := srcB[5][idx] - srcE[5][idx];
    be6 := srcB[6][idx] - srcE[6][idx];
    E[0][idx] := q1*(srcB[6][idx]*7.0 + srcB[5][idx]*6.0 + srcB[4][idx]*5.0 + srcB[3][idx]*4.0 + srcB[2][idx]*3.0 + srcB[1][idx]*2.0 + srcB[0][idx]);
    E[1][idx] := q2*(srcB[6][idx]*21.0 + srcB[5][idx]*15.0 + srcB[4][idx]*10.0 + srcB[3][idx]*6.0 + srcB[2][idx]*3.0 + srcB[1][idx]);
    E[2][idx] := q3*(srcB[6][idx]*35.0 + srcB[5][idx]*20.0 + srcB[4][idx]*10.0 + srcB[3][idx]*4.0 + srcB[2][idx]);
    E[3][idx] := q4*(srcB[6][idx]*35.0 + srcB[5][idx]*15.0 + srcB[4][idx]*5.0 + srcB[3][idx]);
    E[4][idx] := q5*(srcB[6][idx]*21.0 + srcB[5][idx]*6.0 + srcB[4][idx]);
    E[5][idx] := q6*(srcB[6][idx]*7.0 + srcB[5][idx]);
    E[6][idx] := q7*srcB[6][idx];
    B[0][idx] := E[0][idx] + be0; B[1][idx] := E[1][idx] + be1; B[2][idx] := E[2][idx] + be2;
    B[3][idx] := E[3][idx] + be3; B[4][idx] := E[4][idx] + be4; B[5][idx] := E[5][idx] + be5;
    B[6][idx] := E[6][idx] + be6;
  end;

begin
  dtDone := dt;
  minTS2 := 0.0;
  haveTS := False;

  // ---- Predictor-corrector: converge B[*][i] for every body --------------------
  for i := Low(S) to High(S) do
  begin
    v0 := S[i].V;

    // Constant term a0 = acceleration at the current state (perturbers at t0 = P[0]).
    FillChar(a0, SizeOf(TVec4D), 0);
    for j := Low(P[0]) to High(P[0]) do
    begin
      GM := P[0][j].GM;
      if GM > 0.0 then a0 := a0 + (P[0][j].R - S[i].R).InvCubeScale3D(GM);
    end;
    a0 := a0 + AccelJ2All(S[i], P[0]);   // + planetary J2 (oblateness); ~free far from a planet
    a[i] := a0;   // stash a0; overwritten with the end-of-step value on acceptance

    // Load predicted b (warm start) and derive g from it.
    b0 := B[0][i]; b1 := B[1][i]; b2 := B[2][i]; b3 := B[3][i];
    b4 := B[4][i]; b5 := B[5][i]; b6 := B[6][i];
    g0 := b6*d[15] + b5*d[10] + b4*d[6] + b3*d[3] + b2*d[1] + b1*d[0] + b0;
    g1 := b6*d[16] + b5*d[11] + b4*d[7] + b3*d[4] + b2*d[2] + b1;
    g2 := b6*d[17] + b5*d[12] + b4*d[8] + b3*d[5] + b2;
    g3 := b6*d[18] + b5*d[13] + b4*d[9] + b3;
    g4 := b6*d[19] + b5*d[14] + b4;
    g5 := b6*d[20] + b5;
    g6 := b6;
    FillChar(csb0, SizeOf(TVec4D), 0); FillChar(csb1, SizeOf(TVec4D), 0);
    FillChar(csb2, SizeOf(TVec4D), 0); FillChar(csb3, SizeOf(TVec4D), 0);
    FillChar(csb4, SizeOf(TVec4D), 0); FillChar(csb5, SizeOf(TVec4D), 0);
    FillChar(csb6, SizeOf(TVec4D), 0);

    pcErr := 1.0E300; pcErrLast := 2.0; iter := 0;
    while True do
    begin
      if pcErr < 1.0E-16 then Break;                     // converged
      if (iter > 2) and (pcErrLast <= pcErr) then Break; // error stopped improving
      if iter >= 12 then Break;                          // give up (step likely too big)
      pcErrLast := pcErr;
      pcErr := 0.0;
      Inc(iter);

      for n := 1 to 7 do
      begin
        hn := h[n];
        // Predict position displacement at node n (Horner form, double integral of
        // the acceleration polynomial). Velocities are not needed: gravity here is
        // position-only. Add a velocity predictor block if velocity-dependent forces
        // are ever introduced.
        term := b6*(7.0*hn/9.0) + b5;
        term := term*(3.0*hn/4.0) + b4;
        term := term*(5.0*hn/7.0) + b3;
        term := term*(2.0*hn/3.0) + b2;
        term := term*(3.0*hn/5.0) + b1;
        term := term*(hn/2.0) + b0;
        term := term*(hn/3.0) + a0;
        term := term*(dtDone*hn*0.5) + v0;
        term := term*(dtDone*hn);
        rNode := S[i].R + (term - csx[i]);

        // Acceleration at node n in the field of the node-n perturbers.
        FillChar(aNode, SizeOf(TVec4D), 0);
        for j := Low(P[n]) to High(P[n]) do
        begin
          GM := P[n][j].GM;
          if GM > 0.0 then aNode := aNode + (P[n][j].R - rNode).InvCubeScale3D(GM);
        end;
        sJ2.R := rNode;  aNode := aNode + AccelJ2All(sJ2, P[n]);   // + planetary J2 (position-only)
        gvec := aNode - a0;

        case n of
          1: begin
               gOld := g0;
               g0 := gvec * (1.0/rr[0]);
               AddCS(b0, csb0, g0 - gOld);
             end;
          2: begin
               gOld := g1;
               g1 := (gvec*(1.0/rr[1]) - g0) * (1.0/rr[2]);
               dg := g1 - gOld;
               AddCS(b0, csb0, dg * c[0]);
               AddCS(b1, csb1, dg);
             end;
          3: begin
               gOld := g2;
               g2 := ((gvec*(1.0/rr[3]) - g0)*(1.0/rr[4]) - g1) * (1.0/rr[5]);
               dg := g2 - gOld;
               AddCS(b0, csb0, dg * c[1]);
               AddCS(b1, csb1, dg * c[2]);
               AddCS(b2, csb2, dg);
             end;
          4: begin
               gOld := g3;
               g3 := (((gvec*(1.0/rr[6]) - g0)*(1.0/rr[7]) - g1)*(1.0/rr[8]) - g2) * (1.0/rr[9]);
               dg := g3 - gOld;
               AddCS(b0, csb0, dg * c[3]);
               AddCS(b1, csb1, dg * c[4]);
               AddCS(b2, csb2, dg * c[5]);
               AddCS(b3, csb3, dg);
             end;
          5: begin
               gOld := g4;
               g4 := ((((gvec*(1.0/rr[10]) - g0)*(1.0/rr[11]) - g1)*(1.0/rr[12]) - g2)*(1.0/rr[13]) - g3) * (1.0/rr[14]);
               dg := g4 - gOld;
               AddCS(b0, csb0, dg * c[6]);
               AddCS(b1, csb1, dg * c[7]);
               AddCS(b2, csb2, dg * c[8]);
               AddCS(b3, csb3, dg * c[9]);
               AddCS(b4, csb4, dg);
             end;
          6: begin
               gOld := g5;
               g5 := (((((gvec*(1.0/rr[15]) - g0)*(1.0/rr[16]) - g1)*(1.0/rr[17]) - g2)*(1.0/rr[18]) - g3)*(1.0/rr[19]) - g4) * (1.0/rr[20]);
               dg := g5 - gOld;
               AddCS(b0, csb0, dg * c[10]);
               AddCS(b1, csb1, dg * c[11]);
               AddCS(b2, csb2, dg * c[12]);
               AddCS(b3, csb3, dg * c[13]);
               AddCS(b4, csb4, dg * c[14]);
               AddCS(b5, csb5, dg);
             end;
          7: begin
               gOld := g6;
               g6 := ((((((gvec*(1.0/rr[21]) - g0)*(1.0/rr[22]) - g1)*(1.0/rr[23]) - g2)*(1.0/rr[24]) - g3)*(1.0/rr[25]) - g4)*(1.0/rr[26]) - g5) * (1.0/rr[27]);
               dg := g6 - gOld;
               AddCS(b0, csb0, dg * c[15]);
               AddCS(b1, csb1, dg * c[16]);
               AddCS(b2, csb2, dg * c[17]);
               AddCS(b3, csb3, dg * c[18]);
               AddCS(b4, csb4, dg * c[19]);
               AddCS(b5, csb5, dg * c[20]);
               AddCS(b6, csb6, dg);
               // Convergence is gauged by the change in the last coefficient b6
               // relative to the acceleration at this node.
               amag := aNode or aNode;
               if amag > 0.0 then pcErr := Sqrt((dg or dg) / amag) else pcErr := 0.0;
             end;
        end;
      end;
    end;

    // Store the converged coefficients for the timestep estimate and (if accepted)
    // the final state update and next-step prediction.
    B[0][i] := b0; B[1][i] := b1; B[2][i] := b2; B[3][i] := b3;
    B[4][i] := b4; B[5][i] := b5; B[6][i] := b6;

    // Per-body PRS23 timescale (Pham, Rein & Spiegel 2023).
    a0sq := a0 or a0;
    if (a0sq > 0.0) and (not IsNan(a0sq)) and (not IsInfinite(a0sq)) then
    begin
      vtmp := a0 + b0 + b1 + b2 + b3 + b4 + b5 + b6;                       // accel at step end
      y2 := vtmp or vtmp;
      vtmp := b0 + b1*2.0 + b2*3.0 + b3*4.0 + b4*5.0 + b5*6.0 + b6*7.0;    // jerk*dt
      y3 := vtmp or vtmp;
      vtmp := b1*2.0 + b2*6.0 + b3*12.0 + b4*20.0 + b5*30.0 + b6*42.0;     // snap*dt^2
      y4 := vtmp or vtmp;
      timescale2 := 2.0*y2 / (y3 + Sqrt(y4*y2));
      if (timescale2 > 0.0) and (not IsNan(timescale2)) and (not IsInfinite(timescale2)) then
        if (not haveTS) or (timescale2 < minTS2) then
        begin
          minTS2 := timescale2;
          haveTS := True;
        end;
    end;
  end;

  // ---- Decide the new step size ------------------------------------------------
  errscale := Power(EPSILON*5040.0, 1.0/7.0);
  if haveTS then dt_new := Sqrt(minTS2) * dtDone * errscale
            else dt_new := dtDone / safety_factor;   // no constraint -> grow a little

  // ---- Reject: step needs to shrink by more than 1/safety_factor ---------------
  if Abs(dt_new/dtDone) < safety_factor then
  begin
    if dt_last <> 0.0 then
    begin
      ratio := dt_new / dt_last;
      for i := Low(S) to High(S) do PredictStep(i, ratio, Er, Br);  // re-predict from last good
    end;
    dt := dt_new;
    Result := False;
    Exit;
  end;

  // Cap growth at 1/safety_factor.
  if (dt_new > dtDone) and (dt_new/dtDone > 1.0/safety_factor) then
    dt_new := dtDone / safety_factor;

  // ---- Accept: commit states and predict the next step's coefficients ----------
  d2 := dtDone*dtDone;
  for i := Low(S) to High(S) do
  begin
    a0 := a[i];   // a0 was stashed during the PC phase; v0 = S[i].V (still unmodified)
    // Position (compensated, term by term to control round-off as in REBOUND).
    AddCS(S[i].R, csx[i], B[6][i]*(d2/72.0));
    AddCS(S[i].R, csx[i], B[5][i]*(d2/56.0));
    AddCS(S[i].R, csx[i], B[4][i]*(d2/42.0));
    AddCS(S[i].R, csx[i], B[3][i]*(d2/30.0));
    AddCS(S[i].R, csx[i], B[2][i]*(d2/20.0));
    AddCS(S[i].R, csx[i], B[1][i]*(d2/12.0));
    AddCS(S[i].R, csx[i], B[0][i]*(d2/6.0));
    AddCS(S[i].R, csx[i], a0*(d2/2.0));
    AddCS(S[i].R, csx[i], S[i].V*dtDone);
    // Velocity (compensated).
    AddCS(S[i].V, csv[i], B[6][i]*(dtDone/8.0));
    AddCS(S[i].V, csv[i], B[5][i]*(dtDone/7.0));
    AddCS(S[i].V, csv[i], B[4][i]*(dtDone/6.0));
    AddCS(S[i].V, csv[i], B[3][i]*(dtDone/5.0));
    AddCS(S[i].V, csv[i], B[2][i]*(dtDone/4.0));
    AddCS(S[i].V, csv[i], B[1][i]*(dtDone/3.0));
    AddCS(S[i].V, csv[i], B[0][i]*(dtDone/2.0));
    AddCS(S[i].V, csv[i], a0*dtDone);
    // End-of-step acceleration (polynomial at s=1) as an FSAL-style output.
    a[i] := a0 + B[0][i] + B[1][i] + B[2][i] + B[3][i] + B[4][i] + B[5][i] + B[6][i];
    // Save converged coefficients as the rejection backup, then predict next step.
    Er[0][i] := E[0][i]; Er[1][i] := E[1][i]; Er[2][i] := E[2][i]; Er[3][i] := E[3][i];
    Er[4][i] := E[4][i]; Er[5][i] := E[5][i]; Er[6][i] := E[6][i];
    Br[0][i] := B[0][i]; Br[1][i] := B[1][i]; Br[2][i] := B[2][i]; Br[3][i] := B[3][i];
    Br[4][i] := B[4][i]; Br[5][i] := B[5][i]; Br[6][i] := B[6][i];
    PredictStep(i, dt_new/dtDone, E, B);
  end;

  dt := dt_new;
  Result := True;
end;

function GaussRadau15_PN(var dt: Double; dt_last: Double; a: TVec4DArray; S: TState4DArray; P: TState4DArrays; B, E, Br, Er: TVec4DArrays; csx, csv: TVec4DArray; Pert: PPerturberSoA): Boolean;
// IAS15_PN: GaussRadau15 plus the 1PN/EIH relativistic term (via AccelPN). Same calling
// contract as GaussRadau15, but it also PREDICTS THE NODE VELOCITY (single integral of the
// acceleration polynomial) so the velocity-dependent 1PN force is sampled self-consistently
// at each Gauss-Radau node; perturber a_j/U_j are precomputed once per node snapshot
// (PerturberPN). The original GaussRadau15 is left untouched.
// IAS15 — 15th-order Gauss-Radau integrator with adaptive step size
// (Everhart 1985; Rein & Spiegel 2015; timestep per Pham, Rein & Spiegel 2023).
// Ported from REBOUND's integrator_ias15.c to fit the precomputed-perturber model
// used by the other integrators here: every body in S is advanced independently in
// the external field defined by the perturber snapshots in P.
//
// Unlike the explicit integrators this is implicit: the acceleration over the step
// is represented as a 7th-degree polynomial whose coefficients B[0..6] are found by
// a predictor-corrector iteration that re-evaluates the force at the 7 Gauss-Radau
// nodes (2 iterations on a warm step, up to 12 cold). The polynomial state is
// carried across steps (B, E warm-started, Br, Er kept as rejection backups), and
// position/velocity are accumulated with compensated summation (csx, csv).
//
// PARAMETERS (all body-indexed arrays must have Length = Length(S)):
//   dt      in : trial step; out: suggested next step.
//   dt_last : length of the last SUCCESSFULLY completed step (0 on the first call).
//   a       out: end-of-step acceleration of each body (polynomial at s=1); ignored
//                on input. Handy as a display/diagnostic; not required as input.
//   S       in/out: states; advanced in place ONLY when the step is accepted.
//   P       in : P[0] = perturbers at t0; P[1..7] = perturbers at t0 + h[n]*dt.
//                P[0] is unchanged between rejection retries; P[1..7] must be
//                re-sampled at the new node times before each retry.
//   B,E,Br,Er : persistent predictor state, each dimensioned [0..6][0..High(S)].
//               Zero them once before the first call; the routine maintains them.
//   csx, csv : persistent compensated-summation accumulators; zero before first call.
//
// RESULT: True  -> step accepted, S advanced by the *input* dt (caller should set its
//                  own dt_last to that value); dt now holds the suggested next step.
//         False -> step rejected; dt holds a smaller step. Re-sample P[1..7] at the
//                  new nodes and call again (S, dt_last unchanged).
const
  safety_factor = 0.25;        // max step shrink before forced retry / inverse max growth
  EPSILON       = 1.0E-9;      // accuracy control (REBOUND default)
  // Gauss-Radau node spacings
  h: array[0..7] of Double = (
    0.0, 0.0562625605369221464656521910318, 0.180240691736892364987579942780,
    0.352624717113169637373907769648, 0.547153626330555383001448554766,
    0.734210177215410531523210605558, 0.885320946839095768090359771030,
    0.977520613561287501891174488626);
  // Pairwise node differences h[j]-h[k] (used as divisors when building g)
  rr: array[0..27] of Double = (
    0.0562625605369221464656522, 0.1802406917368923649875799, 0.1239781311999702185219278,
    0.3526247171131696373739078, 0.2963621565762474909082556, 0.1723840253762772723863278,
    0.5471536263305553830014486, 0.4908910657936332365357964, 0.3669129345936630180138686,
    0.1945289092173857456275408, 0.7342101772154105315232106, 0.6779476166784883850575584,
    0.5539694854785181665356307, 0.3815854601022408941493028, 0.1870565508848551485217621,
    0.8853209468390957680903598, 0.8290583863021736216247076, 0.7050802551022034031027798,
    0.5326962297259261307164520, 0.3381673205085403850889112, 0.1511107696236852365671492,
    0.9775206135612875018911745, 0.9212580530243653554255223, 0.7972799218243951369035945,
    0.6248958964481178645172667, 0.4303669872307321188897259, 0.2433104363458769703679639,
    0.0921996667221917338008147);
  // g -> b conversion (Newton to Taylor form)
  c: array[0..20] of Double = (
    -0.0562625605369221464656522, 0.0101408028300636299864818, -0.2365032522738145114532321,
    -0.0035758977292516175949345, 0.0935376952594620658957485, -0.5891279693869841488271399,
    0.0019565654099472210769006, -0.0547553868890686864408084, 0.4158812000823068616886219,
    -1.1362815957175395318285885, -0.0014365302363708915424460, 0.0421585277212687077072973,
    -0.3600995965020568122897665, 1.2501507118406910258505441, -1.8704917729329500633517991,
    0.0012717903090268677492943, -0.0387603579159067703699046, 0.3609622434528459832253398,
    -1.4668842084004269643701553, 2.9061362593084293014237913, -2.7558127197720458314421588);
  // b -> g conversion, used to warm-start g from the predicted b
  d: array[0..20] of Double = (
    0.0562625605369221464656522, 0.0031654757181708292499905, 0.2365032522738145114532321,
    0.0001780977692217433881125, 0.0457929855060279188954539, 0.5891279693869841488271399,
    0.0000100202365223291272096, 0.0084318571535257015445000, 0.2535340690545692665214616,
    1.1362815957175395318285885, 0.0000005637641639318207610, 0.0015297840025004658189490,
    0.0978342365324440053653648, 0.8752546646840910912297246, 1.8704917729329500633517991,
    0.0000000317188154017613665, 0.0002762930909826476593130, 0.0360285539837364596003871,
    0.5767330002770787313544596, 2.2485887607691597933926895, 2.7558127197720458314421588);
var
  i, n, iter: Int64;
  b0, b1, b2, b3, b4, b5, b6,
  g0, g1, g2, g3, g4, g5, g6,
  csb0, csb1, csb2, csb3, csb4, csb5, csb6,
  a0, v0, term, rNode, aNode, gvec, dg, gOld, vtmp: TVec4D;
  hn, dtDone, d2, pcErr, pcErrLast, amag,
  y2, y3, y4, a0sq, timescale2, minTS2, dt_new, ratio, errscale: Double;
  haveTS: Boolean;
  aP: TVec4DArrays;
  sNode: TState4D;
  NGi: TNonGrav;                                   // this body's Yarkovsky coefficients (per-body hoist)
  vNode, termv: TVec4D;

  procedure PredictStep(idx: Int64; q: Double; const srcE, srcB: TVec4DArrays);
  // Predict the b coefficients to use at the start of the next sequence, scaling by
  // the step-size ratio q. The not-yet-applied correction (srcB - srcE) is carried
  // forward. Mirrors REBOUND's predict_next_step for a single body.
  var
    q1, q2, q3, q4, q5, q6, q7: Double;
    be0, be1, be2, be3, be4, be5, be6: TVec4D;
  begin
    if q > 20.0 then
    begin
      // Step grew too much to trust the prediction — restart from zero.
      FillChar(E[0][idx], SizeOf(TVec4D), 0); FillChar(E[1][idx], SizeOf(TVec4D), 0);
      FillChar(E[2][idx], SizeOf(TVec4D), 0); FillChar(E[3][idx], SizeOf(TVec4D), 0);
      FillChar(E[4][idx], SizeOf(TVec4D), 0); FillChar(E[5][idx], SizeOf(TVec4D), 0);
      FillChar(E[6][idx], SizeOf(TVec4D), 0);
      FillChar(B[0][idx], SizeOf(TVec4D), 0); FillChar(B[1][idx], SizeOf(TVec4D), 0);
      FillChar(B[2][idx], SizeOf(TVec4D), 0); FillChar(B[3][idx], SizeOf(TVec4D), 0);
      FillChar(B[4][idx], SizeOf(TVec4D), 0); FillChar(B[5][idx], SizeOf(TVec4D), 0);
      FillChar(B[6][idx], SizeOf(TVec4D), 0);
      Exit;
    end;
    q1 := q;       q2 := q1*q1; q3 := q1*q2; q4 := q2*q2;
    q5 := q2*q3;   q6 := q3*q3; q7 := q3*q4;
    be0 := srcB[0][idx] - srcE[0][idx]; be1 := srcB[1][idx] - srcE[1][idx];
    be2 := srcB[2][idx] - srcE[2][idx]; be3 := srcB[3][idx] - srcE[3][idx];
    be4 := srcB[4][idx] - srcE[4][idx]; be5 := srcB[5][idx] - srcE[5][idx];
    be6 := srcB[6][idx] - srcE[6][idx];
    E[0][idx] := q1*(srcB[6][idx]*7.0 + srcB[5][idx]*6.0 + srcB[4][idx]*5.0 + srcB[3][idx]*4.0 + srcB[2][idx]*3.0 + srcB[1][idx]*2.0 + srcB[0][idx]);
    E[1][idx] := q2*(srcB[6][idx]*21.0 + srcB[5][idx]*15.0 + srcB[4][idx]*10.0 + srcB[3][idx]*6.0 + srcB[2][idx]*3.0 + srcB[1][idx]);
    E[2][idx] := q3*(srcB[6][idx]*35.0 + srcB[5][idx]*20.0 + srcB[4][idx]*10.0 + srcB[3][idx]*4.0 + srcB[2][idx]);
    E[3][idx] := q4*(srcB[6][idx]*35.0 + srcB[5][idx]*15.0 + srcB[4][idx]*5.0 + srcB[3][idx]);
    E[4][idx] := q5*(srcB[6][idx]*21.0 + srcB[5][idx]*6.0 + srcB[4][idx]);
    E[5][idx] := q6*(srcB[6][idx]*7.0 + srcB[5][idx]);
    E[6][idx] := q7*srcB[6][idx];
    B[0][idx] := E[0][idx] + be0; B[1][idx] := E[1][idx] + be1; B[2][idx] := E[2][idx] + be2;
    B[3][idx] := E[3][idx] + be3; B[4][idx] := E[4][idx] + be4; B[5][idx] := E[5][idx] + be5;
    B[6][idx] := E[6][idx] + be6;
  end;

begin
  dtDone := dt;
  minTS2 := 0.0;
  haveTS := False;

  // Precompute each perturber a_j (in aP[n][j].XYZ) and U_j (in .W) once per node snapshot.
  SetLength(aP, Length(P));
  for n := 0 to High(P) do
   if Pert = nil then PerturberPN(P[n], aP[n])
   else
    begin
     PerturberPN_SoA(Pert^, n);
     {$IFDEF PN_SOA_VALIDATE} PerturberPN(P[n], aP[n]); {$ENDIF}   // aP still needed as the validation oracle
    end;

  // ---- Predictor-corrector: converge B[*][i] for every body --------------------
  for i := Low(S) to High(S) do
  begin
    v0 := S[i].V;
    // Per-body Yarkovsky: pick this body's coefficients (or an inactive record if it has none). NGi is
    // reused for every node of body i below.
    if i <= High(GNonGrav) then NGi := GNonGrav[i] else NGi.Active := False;

    // Constant term a0 = full (Newtonian + 1PN) acceleration at the current state (node 0).
    sNode.R := S[i].R; sNode.V := v0;
    // NONGRAV HOOK (node 0). To restore the original pure-gravitational + 1PN integrator, delete the
    // "+ NonGravAccel(...)" tail here and at the node-n site below (leaving just the AccelPN call), OR
    // simply leave GNonGrav[i] inactive -- with the hook inactive NonGravAccel returns zero and the
    // result is already identical to the original.
    a0 := PNAccelSelect(sNode, P[0], aP[0], Pert, 0) + NonGravAccel(sNode, P[0][GSunIdx], NGi) + AccelJ2All(sNode, P[0]) + AccelJHiAll(sNode, P[0]);
    // Extra per-body acceleration (AccForm thrust). The AccelCallbacks<>nil test bypasses it entirely in the
    // common (99%) no-thrust case; sNode carries the node velocity IAS15_PN already predicts, so the velocity-
    // dependent term (prograde/normal) is evaluated on a consistent state. and-shortcircuit avoids deref-ing nil.
    if (AccelCallbacks<>nil) and Assigned(AccelCallbacks^[i]) then a0 := a0 + AccelCallbacks^[i](i, sNode, Pointer(P[0]), Length(P[0]));
    a[i] := a0;   // stash a0; overwritten with the end-of-step value on acceptance

    // Load predicted b (warm start) and derive g from it.
    b0 := B[0][i]; b1 := B[1][i]; b2 := B[2][i]; b3 := B[3][i];
    b4 := B[4][i]; b5 := B[5][i]; b6 := B[6][i];
    g0 := b6*d[15] + b5*d[10] + b4*d[6] + b3*d[3] + b2*d[1] + b1*d[0] + b0;
    g1 := b6*d[16] + b5*d[11] + b4*d[7] + b3*d[4] + b2*d[2] + b1;
    g2 := b6*d[17] + b5*d[12] + b4*d[8] + b3*d[5] + b2;
    g3 := b6*d[18] + b5*d[13] + b4*d[9] + b3;
    g4 := b6*d[19] + b5*d[14] + b4;
    g5 := b6*d[20] + b5;
    g6 := b6;
    FillChar(csb0, SizeOf(TVec4D), 0); FillChar(csb1, SizeOf(TVec4D), 0);
    FillChar(csb2, SizeOf(TVec4D), 0); FillChar(csb3, SizeOf(TVec4D), 0);
    FillChar(csb4, SizeOf(TVec4D), 0); FillChar(csb5, SizeOf(TVec4D), 0);
    FillChar(csb6, SizeOf(TVec4D), 0);

    pcErr := 1.0E300; pcErrLast := 2.0; iter := 0;
    while True do
    begin
      if pcErr < 1.0E-16 then Break;                     // converged
      if (iter > 2) and (pcErrLast <= pcErr) then Break; // error stopped improving
      if iter >= 12 then Break;                          // give up (step likely too big)
      pcErrLast := pcErr;
      pcErr := 0.0;
      Inc(iter);

      for n := 1 to 7 do
      begin
        hn := h[n];
        // Predict position displacement at node n (Horner, double integral of accel poly).
        term := b6*(7.0*hn/9.0) + b5;
        term := term*(3.0*hn/4.0) + b4;
        term := term*(5.0*hn/7.0) + b3;
        term := term*(2.0*hn/3.0) + b2;
        term := term*(3.0*hn/5.0) + b1;
        term := term*(hn/2.0) + b0;
        term := term*(hn/3.0) + a0;
        term := term*(dtDone*hn*0.5) + v0;
        term := term*(dtDone*hn);
        rNode := S[i].R + (term - csx[i]);

        // Predict the node VELOCITY too (single integral of the accel polynomial): the 1PN
        // force is velocity-dependent, so AccelPN needs a consistent v at the node.
        termv := b6*(7.0*hn/8.0) + b5;
        termv := termv*(6.0*hn/7.0) + b4;
        termv := termv*(5.0*hn/6.0) + b3;
        termv := termv*(4.0*hn/5.0) + b2;
        termv := termv*(3.0*hn/4.0) + b1;
        termv := termv*(2.0*hn/3.0) + b0;
        termv := termv*(hn/2.0) + a0;
        termv := termv*(dtDone*hn);
        vNode := S[i].V + (termv - csv[i]);

        // Full (Newtonian + 1PN) acceleration at node n.
        sNode.R := rNode; sNode.V := vNode;
        // NONGRAV HOOK (node n) -- see the node-0 site above for how to disable/remove it.
        aNode := PNAccelSelect(sNode, P[n], aP[n], Pert, n) + NonGravAccel(sNode, P[n][GSunIdx], NGi) + AccelJ2All(sNode, P[n]) + AccelJHiAll(sNode, P[n]);
        if (AccelCallbacks<>nil) and Assigned(AccelCallbacks^[i]) then aNode := aNode + AccelCallbacks^[i](i, sNode, Pointer(P[n]), Length(P[n]));   // extra thrust (see node-0 site)
        gvec := aNode - a0;

        case n of
          1: begin
               gOld := g0;
               g0 := gvec * (1.0/rr[0]);
               AddCS(b0, csb0, g0 - gOld);
             end;
          2: begin
               gOld := g1;
               g1 := (gvec*(1.0/rr[1]) - g0) * (1.0/rr[2]);
               dg := g1 - gOld;
               AddCS(b0, csb0, dg * c[0]);
               AddCS(b1, csb1, dg);
             end;
          3: begin
               gOld := g2;
               g2 := ((gvec*(1.0/rr[3]) - g0)*(1.0/rr[4]) - g1) * (1.0/rr[5]);
               dg := g2 - gOld;
               AddCS(b0, csb0, dg * c[1]);
               AddCS(b1, csb1, dg * c[2]);
               AddCS(b2, csb2, dg);
             end;
          4: begin
               gOld := g3;
               g3 := (((gvec*(1.0/rr[6]) - g0)*(1.0/rr[7]) - g1)*(1.0/rr[8]) - g2) * (1.0/rr[9]);
               dg := g3 - gOld;
               AddCS(b0, csb0, dg * c[3]);
               AddCS(b1, csb1, dg * c[4]);
               AddCS(b2, csb2, dg * c[5]);
               AddCS(b3, csb3, dg);
             end;
          5: begin
               gOld := g4;
               g4 := ((((gvec*(1.0/rr[10]) - g0)*(1.0/rr[11]) - g1)*(1.0/rr[12]) - g2)*(1.0/rr[13]) - g3) * (1.0/rr[14]);
               dg := g4 - gOld;
               AddCS(b0, csb0, dg * c[6]);
               AddCS(b1, csb1, dg * c[7]);
               AddCS(b2, csb2, dg * c[8]);
               AddCS(b3, csb3, dg * c[9]);
               AddCS(b4, csb4, dg);
             end;
          6: begin
               gOld := g5;
               g5 := (((((gvec*(1.0/rr[15]) - g0)*(1.0/rr[16]) - g1)*(1.0/rr[17]) - g2)*(1.0/rr[18]) - g3)*(1.0/rr[19]) - g4) * (1.0/rr[20]);
               dg := g5 - gOld;
               AddCS(b0, csb0, dg * c[10]);
               AddCS(b1, csb1, dg * c[11]);
               AddCS(b2, csb2, dg * c[12]);
               AddCS(b3, csb3, dg * c[13]);
               AddCS(b4, csb4, dg * c[14]);
               AddCS(b5, csb5, dg);
             end;
          7: begin
               gOld := g6;
               g6 := ((((((gvec*(1.0/rr[21]) - g0)*(1.0/rr[22]) - g1)*(1.0/rr[23]) - g2)*(1.0/rr[24]) - g3)*(1.0/rr[25]) - g4)*(1.0/rr[26]) - g5) * (1.0/rr[27]);
               dg := g6 - gOld;
               AddCS(b0, csb0, dg * c[15]);
               AddCS(b1, csb1, dg * c[16]);
               AddCS(b2, csb2, dg * c[17]);
               AddCS(b3, csb3, dg * c[18]);
               AddCS(b4, csb4, dg * c[19]);
               AddCS(b5, csb5, dg * c[20]);
               AddCS(b6, csb6, dg);
               // Convergence is gauged by the change in the last coefficient b6
               // relative to the acceleration at this node.
               amag := aNode or aNode;
               if amag > 0.0 then pcErr := Sqrt((dg or dg) / amag) else pcErr := 0.0;
             end;
        end;
      end;
    end;

    // Store the converged coefficients for the timestep estimate and (if accepted)
    // the final state update and next-step prediction.
    B[0][i] := b0; B[1][i] := b1; B[2][i] := b2; B[3][i] := b3;
    B[4][i] := b4; B[5][i] := b5; B[6][i] := b6;

    // Per-body PRS23 timescale (Pham, Rein & Spiegel 2023).
    a0sq := a0 or a0;
    if (a0sq > 0.0) and (not IsNan(a0sq)) and (not IsInfinite(a0sq)) then
    begin
      vtmp := a0 + b0 + b1 + b2 + b3 + b4 + b5 + b6;                       // accel at step end
      y2 := vtmp or vtmp;
      vtmp := b0 + b1*2.0 + b2*3.0 + b3*4.0 + b4*5.0 + b5*6.0 + b6*7.0;    // jerk*dt
      y3 := vtmp or vtmp;
      vtmp := b1*2.0 + b2*6.0 + b3*12.0 + b4*20.0 + b5*30.0 + b6*42.0;     // snap*dt^2
      y4 := vtmp or vtmp;
      timescale2 := 2.0*y2 / (y3 + Sqrt(y4*y2));
      if (timescale2 > 0.0) and (not IsNan(timescale2)) and (not IsInfinite(timescale2)) then
        if (not haveTS) or (timescale2 < minTS2) then
        begin
          minTS2 := timescale2;
          haveTS := True;
        end;
    end;
  end;

  // ---- Decide the new step size ------------------------------------------------
  errscale := Power(EPSILON*5040.0, 1.0/7.0);
  if haveTS then dt_new := Sqrt(minTS2) * dtDone * errscale
            else dt_new := dtDone / safety_factor;   // no constraint -> grow a little

  // ---- Reject: step needs to shrink by more than 1/safety_factor ---------------
  if Abs(dt_new/dtDone) < safety_factor then
  begin
    if dt_last <> 0.0 then
    begin
      ratio := dt_new / dt_last;
      for i := Low(S) to High(S) do PredictStep(i, ratio, Er, Br);  // re-predict from last good
    end;
    dt := dt_new;
    Result := False;
    Exit;
  end;

  // Cap growth at 1/safety_factor.
  if (dt_new > dtDone) and (dt_new/dtDone > 1.0/safety_factor) then
    dt_new := dtDone / safety_factor;

  // ---- Accept: commit states and predict the next step's coefficients ----------
  d2 := dtDone*dtDone;
  for i := Low(S) to High(S) do
  begin
    a0 := a[i];   // a0 was stashed during the PC phase; v0 = S[i].V (still unmodified)
    // Position (compensated, term by term to control round-off as in REBOUND).
    AddCS(S[i].R, csx[i], B[6][i]*(d2/72.0));
    AddCS(S[i].R, csx[i], B[5][i]*(d2/56.0));
    AddCS(S[i].R, csx[i], B[4][i]*(d2/42.0));
    AddCS(S[i].R, csx[i], B[3][i]*(d2/30.0));
    AddCS(S[i].R, csx[i], B[2][i]*(d2/20.0));
    AddCS(S[i].R, csx[i], B[1][i]*(d2/12.0));
    AddCS(S[i].R, csx[i], B[0][i]*(d2/6.0));
    AddCS(S[i].R, csx[i], a0*(d2/2.0));
    AddCS(S[i].R, csx[i], S[i].V*dtDone);
    // Velocity (compensated).
    AddCS(S[i].V, csv[i], B[6][i]*(dtDone/8.0));
    AddCS(S[i].V, csv[i], B[5][i]*(dtDone/7.0));
    AddCS(S[i].V, csv[i], B[4][i]*(dtDone/6.0));
    AddCS(S[i].V, csv[i], B[3][i]*(dtDone/5.0));
    AddCS(S[i].V, csv[i], B[2][i]*(dtDone/4.0));
    AddCS(S[i].V, csv[i], B[1][i]*(dtDone/3.0));
    AddCS(S[i].V, csv[i], B[0][i]*(dtDone/2.0));
    AddCS(S[i].V, csv[i], a0*dtDone);
    // End-of-step acceleration (polynomial at s=1) as an FSAL-style output.
    a[i] := a0 + B[0][i] + B[1][i] + B[2][i] + B[3][i] + B[4][i] + B[5][i] + B[6][i];
    // Save converged coefficients as the rejection backup, then predict next step.
    Er[0][i] := E[0][i]; Er[1][i] := E[1][i]; Er[2][i] := E[2][i]; Er[3][i] := E[3][i];
    Er[4][i] := E[4][i]; Er[5][i] := E[5][i]; Er[6][i] := E[6][i];
    Br[0][i] := B[0][i]; Br[1][i] := B[1][i]; Br[2][i] := B[2][i]; Br[3][i] := B[3][i];
    Br[4][i] := B[4][i]; Br[5][i] := B[5][i]; Br[6][i] := B[6][i];
    PredictStep(i, dt_new/dtDone, E, B);
  end;

  dt := dt_new;
  Result := True;
end;

function KeplerUniv(Time, MU: Double; const Input: TState4D; var Output: TState4D): Boolean;
// Propagates a 2-body state (osculating elements as vectors) from Input.Epoch to Time by solving
// the universal Kepler equation with Laguerre's method (n=5). Robust across all conic types incl.
// the e~1 regime (comets), where branch-switched closed-form solutions are unreliable. Units: km,
// km/s, seconds (SPICE ET); MU = combined GM (km^3/s^2) -- native throughout, no rescaling. Both
// stopping tests are RELATIVE (km-magnitude state makes an absolute residual unreachable). Returns
// False if the iteration hit the cap without converging.
// K2 = d²K/dX² = c0·U2 + d0·(1 − z·U1), derived from the Stumpff recurrence
// dU2/dX = c0_stumpff(z·X²) = 1 − z·U1.
// The step is: X := X − 5·K0 / (K1 ± √|16·K1² − 20·K0·K2|)
// with sign chosen to maximise |denominator|. Converges cubically.
const
  REL_SOLVE = 1.0E-13;   // Kepler-residual convergence, relative to the equation scale |W| + r0*|X|
var
  i,
  itc: Int64;
  dt,                // propagation interval (seconds)
  W,
  X,
  XT, XB,
  T0, T1,
  U0, U1, U2,
  K0, K1, K2,        // Kepler equation value and first two derivatives (K1=r)
  delta,             // Laguerre denominator radical
  r0, v0,
  r0v0,
  z,
  c0,
  d0,
  f0, g0,
  f1, g1,
  smu: Double;
begin
  r0:=Input.R.Magnitude3D;
  v0:=Input.V.Magnitude3D;
  r0v0:=(Input.R or Input.V);
  z:=2/r0 - v0*v0/MU;        // z = 1/a  (>0 ellipse, 0 parabola, <0 hyperbola)
  smu:=Sqrt(MU);
  dt:=Time-Input.Epoch;
  W:=smu*dt;
  c0:=1-z*r0;
  d0:=r0v0/smu;

  itc:=0; K0:=0.0; K1:=1.0; K2:=0.0;
  X:=smu*dt*Abs(z);
  repeat
   itc:=itc+1;
   // Laguerre step, n=5: coefficients (n-1)²=16, n·(n-1)=20
   delta:=Sqrt(Abs(16.0*K1*K1 - 20.0*K0*K2));
   if K1>=0.0 then X:=X - 5.0*K0/(K1+delta)
              else X:=X - 5.0*K0/(K1-delta);
   T1:=X*X;
   T0:=T1*X/6.0;
   XT:=-z*T1;
   T1:=T1/2.0;
   U0:=T0;
   U1:=T1;
   if z<>0.0 then
    begin
     i:=2;
     repeat
      i:=i+2;
      XB:=XT/(i-1)/i;      // U1 = X^2*c2(zX^2): term ratio -zX^2/((i-1)*i) = /3.4, /5.6, ...
      T1:=XB*T1;
      T0:=(XT/i/(i+1))*T0; // U0 = X^3*c3(zX^2): term ratio -zX^2/(i*(i+1)) = /4.5, /6.7, ...  (was wrongly XB)
      U0:=U0+T0;
      U1:=U1+T1;
     until ((Abs(T0)<=TOLERANCE_LEVEL_NEWTON_RAPHSON*Abs(U0)) and (Abs(T1)<=TOLERANCE_LEVEL_NEWTON_RAPHSON*Abs(U1))) or (i>MAX_ITERATION_COUNT_NEWTON_RAPHSON);
    end;
   U2:=X-U0*z;
   K0:=r0*X + c0*U0 + d0*U1 - W;
   K1:=r0   + c0*U1 + d0*U2;
   K2:=       c0*U2 + d0*(1.0-z*U1);  // dK1/dX via Stumpff recurrence
   Result:=(itc<=MAX_ITERATION_COUNT_NEWTON_RAPHSON);
  until (Abs(K0)<=REL_SOLVE*(Abs(W)+r0*Abs(X))) or not Result;

  f0 := 1.0 - U1/r0;
  g0 := r0*U2/smu + r0v0*U1/mu;
  f1 := - smu*U2/K1/r0;
  g1 := 1.0 - U1/K1;

  Output.Epoch:=Time;
  Output.GM:=Input.GM;
  Output.R := Input.R*f0 + Input.V*g0;
  Output.V := Input.R*f1 + Input.V*g1;
  Output.R.W:=1.0;
  Output.V.W:=0.0;
end;

function A1PN(S: TState4D; P: TState4DArray): TVec4D;
// First post-Newtonian (1PN) barycentric acceleration correction: the Einstein-Infeld-Hoffmann
// (EIH) relativistic term for body S in the field of the perturbers P, with PPN parameters
// beta = gamma = 1 (general relativity). Returns ONLY the O(1/c^2) correction — add it to the
// Newtonian acceleration of S to get the full EIH acceleration. Units must be consistent with
// CLIGHT (km, km/s, km^3/s^2). Massless S (a test particle) is handled correctly (its own mass
// terms vanish), as are massless perturbers (skipped). Accurate but NOT optimised: each
// perturber's Newtonian acceleration a_j and the potentials are recomputed from scratch, so the
// cost is O(N^2) per call.
//
//   a_1PN = (1/c^2) * sum_j {  [mu_j (r_j-r_i)/r_ij^3] * B_j
//                            + [mu_j/r_ij^3] * [(r_i-r_j).(4 v_i - 3 v_j)] * (v_i - v_j)
//                            + (7/2) mu_j a_j / r_ij  }
//   B_j = -4 U_i - U_j + v_i^2 + 2 v_j^2 - 4 (v_i.v_j)
//         - (3/2) [ (r_i-r_j).v_j / r_ij ]^2 + (1/2) (r_j-r_i).a_j
//   U_i = sum_{k<>i} mu_k/r_ik    U_j = sum_{k<>j} mu_k/r_jk    a_j = sum_{k<>j} mu_k (r_k-r_j)/r_jk^3
// (i = body S; j, k range over the perturbers, but the k-sums for U_j and a_j also include body i.)
var
  N, j, k: Int64;
  rij, aj, dv: TVec4D;
  Ui, Uj, vi2, vj2, rmag, rij3, d, ndot, Bj, dotfac: Double;
begin
  FillChar(Result, SizeOf(TVec4D), 0);
  N := Length(P);
  if N = 0 then Exit;

  vi2 := S.V or S.V;                                   // |v_i|^2

  // U_i = potential at body i from all perturbers: sum_k mu_k / r_ik
  Ui := 0.0;
  for k := 0 to N-1 do
   if P[k].GM > 0.0 then
    begin
     d := (S.R - P[k].R).Magnitude3D;
     if d > 0.0 then Ui := Ui + P[k].GM / d;
    end;

  for j := 0 to N-1 do
   begin
    if P[j].GM <= 0.0 then Continue;                   // massless perturber -> no contribution
    rij  := S.R - P[j].R;                              // r_i - r_j
    rmag := rij.Magnitude3D;
    if rmag <= 0.0 then Continue;
    rij3 := rmag*rmag*rmag;

    // a_j = Newtonian acceleration of perturber j from every OTHER body (body i = S, and the
    // other perturbers). This nested sum is the expensive part.
    aj := (S.R - P[j].R).InvCubeScale3D(S.GM);         // pull of body i (= S) on j
    for k := 0 to N-1 do
     if (k <> j) and (P[k].GM > 0.0) then
      aj := aj + (P[k].R - P[j].R).InvCubeScale3D(P[k].GM);

    // U_j = potential at perturber j from every OTHER body (includes body i): sum_{k<>j} mu_k / r_jk
    Uj := S.GM / rmag;                                 // contribution of body i (r_ji = r_ij)
    for k := 0 to N-1 do
     if (k <> j) and (P[k].GM > 0.0) then
      begin
       d := (P[j].R - P[k].R).Magnitude3D;
       if d > 0.0 then Uj := Uj + P[k].GM / d;
      end;

    vj2  := P[j].V or P[j].V;
    ndot := (rij or P[j].V) / rmag;                    // (r_i - r_j).v_j / r_ij

    // Scalar bracket (the EIH Newtonian '1' is intentionally omitted: this is the correction only).
    Bj := -4.0*Ui - Uj + vi2 + 2.0*vj2 - 4.0*(S.V or P[j].V)
          - 1.5*ndot*ndot + 0.5*((P[j].R - S.R) or aj);

    // term 1:  [mu_j (r_j-r_i)/r_ij^3] * B_j   (Newtonian direction scaled by the bracket)
    Result := Result + (P[j].R - S.R).InvCubeScale3D(P[j].GM) * Bj;
    // term 2:  [mu_j/r_ij^3] * [(r_i-r_j).(4 v_i - 3 v_j)] * (v_i - v_j)
    dv     := S.V - P[j].V;
    dotfac := rij or (4.0*S.V - 3.0*P[j].V);
    Result := Result + dv * (P[j].GM / rij3 * dotfac);
    // term 3:  (7/2) mu_j a_j / r_ij
    Result := Result + aj * (3.5 * P[j].GM / rmag);
   end;

  Result := Result * INV_C2;
  Result.W := 0.0;   // keep the acceleration's W clean (defensive; InvCubeScale3D now zeroes W itself)
end;

function NonGravAccel(const Si, Sun: TState4D; const NG: TNonGrav): TVec4D;
// JPL/Marsden nongravitational acceleration (Yarkovsky + optional radial/normal), evaluated in the
// HELIOCENTRIC radial-transverse-normal (RTN) frame and returned in km/s^2, ready to ADD to the
// Newtonian+1PN acceleration of test body Si. Requires Si's VELOCITY (the transverse and normal axes
// are defined by v), so this is NOT a position-only TRKCallback -- it slots in beside AccelPN.
// Sun = the Sun's state among the perturbers (heliocentric r,v are formed against it).
//
//   a_ng = g(r) * ( A1*u_r + A2*u_t + A3*u_n ),   g(r) = (r0/r)^m
//   u_r = r_hat (Sun->body);  u_n = (r x v)^ (orbit normal);  u_t = u_n x u_r (in-plane, +prograde)
//
// The RTN frame is built from r and v themselves, so it is correct regardless of the coordinate axes
// (ICRF-equatorial vs ecliptic); only the heliocentric origin (the "- Sun") matters. A2 > 0 pushes
// prograde and raises the semimajor axis -- the Yarkovsky sign convention of the SBDB coefficients.
var
  r, v, ur, un, ut: TVec4D;
  rmag, hmag, gr: Double;
begin
  FillChar(Result, SizeOf(TVec4D), 0);
  if not NG.Active then Exit;                    // hook disabled -> zero contribution

  r := Si.R - Sun.R;                             // heliocentric position (km)
  v := Si.V - Sun.V;                             // heliocentric velocity (km/s)
  rmag := r.Magnitude3D;
  if rmag <= 0.0 then Exit;

  ur := r * (1.0 / rmag);                        // radial unit vector
  un := r xor v;                                 // r x v (angular-momentum direction)
  hmag := un.Magnitude3D;
  if hmag <= 0.0 then Exit;                      // v parallel r -> no RTN frame; bail
  un := un * (1.0 / hmag);                       // normal unit vector
  ut := un xor ur;                               // transverse unit vector (in-plane, +along motion)

  gr := Power(NG.r0 / (rmag * KM2AU), NG.m);     // heliocentric distance in au; SBDB r0/m apply directly
                                                 // (for the m=2 default this is just Sqr(NG.r0/(rmag*KM2AU)))

  // Sum the three SBDB components, then convert au/day^2 -> km/s^2.
  Result := (ur * (NG.A1 * gr) + ut * (NG.A2 * gr) + un * (NG.A3 * gr)) * AUPD2_TO_KMPS2;
  Result.W := 0.0;
end;

function OblatenessJ2(const Si, Body: TState4D; J2, Rbody: Double; const Pole: TVec4D): TVec4D;
// Zonal J2 (oblateness) acceleration on test body Si from an oblate Body (mu = Body.GM; symmetry axis
// 'Pole' = UNIT vector in the ICRF integration frame). r = Si - Body. Add to the Newtonian+1PN accel.
// Falls off as 1/r^4, so it only bites within a few Rbody. Verified sign: inward at the equator,
// outward over the poles.
//   a = -(3/2) J2 mu R^2 / r^4 * [ (1 - 5*zeta^2)*rhat + 2*zeta*Pole ],   zeta = (r.Pole)/|r|
var
  r: TVec4D; rmag, zeta, f: Double;
begin
  FillChar(Result, SizeOf(TVec4D), 0);
  if (Body.GM <= 0.0) or (J2 = 0.0) then Exit;
  r := Si.R - Body.R;
  rmag := r.Magnitude3D;
  if rmag <= 0.0 then Exit;
  zeta := (r or Pole) / rmag;                                    // cos(colatitude)
  f    := -1.5 * J2 * Body.GM * Sqr(Rbody) / Sqr(Sqr(rmag));     // -(3/2) J2 mu R^2 / r^4
  Result := r * (f * (1.0 - 5.0*zeta*zeta) / rmag) + Pole * (f * 2.0 * zeta);
  Result.W := 0.0;
end;

function AccelJ2All(const Si: TState4D; const P: TState4DArray): TVec4D;
// Sum the zonal-J2 (oblateness) acceleration on Si from every enabled oblate body in GJ2 (Earth,
// Jupiter, Saturn). Zero when GJ2Active is False. A cheap squared-distance gate skips any body beyond
// J2_CUTOFF_RADII radii: since J2 falls as 1/r^4 it is sub-mm out there, so far from every planet this
// costs only a subtract + dot + compare per body (no sqrt, no figure term evaluated). GJ2Active remains
// the hard master switch to drop even the gate for runs known to have no encounters at all.
var
  k: Integer;
  d: TVec4D; d2: Double;
begin
  FillChar(Result, SizeOf(TVec4D), 0);
  if not GJ2Active then Exit;
  for k := 0 to High(GJ2) do
    if (GJ2[k].Idx >= 0) and (GJ2[k].Idx <= High(P)) then
    begin
      d  := Si.R - P[GJ2[k].Idx].R;
      d2 := d or d;                                       // |r|^2 (no sqrt)
      if d2 < Sqr(J2_CUTOFF_RADII * GJ2[k].Req) then      // within cutoff -> figure term; else skip
        Result := Result + OblatenessJ2(Si, P[GJ2[k].Idx], GJ2[k].J2, GJ2[k].Req, GJ2[k].Pole);
    end;
  Result.W := 0.0;
end;

function OblatenessJHi(const Si, Body: TState4D; J3, J4, Rbody: Double; const Pole: TVec4D): TVec4D;
// Higher zonal-harmonic (J3, J4) acceleration on Si from oblate Body, ICRF frame, km/s^2. Companion to
// OblatenessJ2 for the IAS15_PN path only (opt-in via GJHiActive). Derived from the general zonal a_n
// (same derivation that reproduces OblatenessJ2), with z = zeta = (r.Pole)/|r|:
//   a3 = (J3/2)(mu/r^2)(R/r)^3 [ (35 z^3 - 15 z) rhat + (3 - 15 z^2) Pole ]
//   a4 = (J4/8)(mu/r^2)(R/r)^4 [ (315 z^4 - 210 z^2 + 15) rhat + (60 z - 140 z^3) Pole ]
var
  r, rhat: TVec4D;
  rmag, z, z2, mur2, Rr, base: Double;
begin
  FillChar(Result, SizeOf(TVec4D), 0);
  if Body.GM <= 0.0 then Exit;
  r := Si.R - Body.R;
  rmag := r.Magnitude3D;
  if rmag <= 0.0 then Exit;
  rhat := r * (1.0/rmag);
  z    := (r or Pole) / rmag;                 // cos(colatitude)
  z2   := z*z;
  mur2 := Body.GM / (rmag*rmag);              // mu / r^2
  Rr   := Rbody / rmag;                        // R / r
  if J3 <> 0.0 then
  begin
    base   := 0.5 * J3 * mur2 * (Rr*Rr*Rr);
    Result := Result + rhat * (base * (35.0*z2*z - 15.0*z)) + Pole * (base * (3.0 - 15.0*z2));
  end;
  if J4 <> 0.0 then
  begin
    base   := 0.125 * J4 * mur2 * Sqr(Rr)*Sqr(Rr);
    Result := Result + rhat * (base * (315.0*z2*z2 - 210.0*z2 + 15.0)) + Pole * (base * (60.0*z - 140.0*z2*z));
  end;
  Result.W := 0.0;
end;

function AccelJHiAll(const Si: TState4D; const P: TState4DArray): TVec4D;
// Sum the higher zonal (J3/J4) acceleration on Si from every enabled body in GJ2. Zero unless
// GJHiActive. Same far-field squared-distance gate as AccelJ2All. Folded into the IAS15_PN path only.
var
  k: Integer;
  d: TVec4D; d2: Double;
begin
  FillChar(Result, SizeOf(TVec4D), 0);
  if not GJHiActive then Exit;
  for k := 0 to High(GJ2) do
    if (GJ2[k].Idx >= 0) and (GJ2[k].Idx <= High(P)) then
    begin
      d  := Si.R - P[GJ2[k].Idx].R;
      d2 := d or d;
      if d2 < Sqr(J2_CUTOFF_RADII * GJ2[k].Req) then
        Result := Result + OblatenessJHi(Si, P[GJ2[k].Idx], GJ2[k].J3, GJ2[k].J4, GJ2[k].Req, GJ2[k].Pole);
    end;
  Result.W := 0.0;
end;

function DE440OblatenessDefault(BodyID: Int64; out J2, J3, J4, Req, PoleRA, PoleDec: Double): Boolean;
// Figure defaults now live on the BodyConstants rows (the single source of truth); this is a thin read-back of
// the zonal/radius/pole subset the integrator + BSPXFile seeds want. Result = True if the body carries a figure.
var i: Int64;
begin
  i:=BodyConstIndex(BodyID);
  if i>=0 then
   begin
    J2:=BodyConstants[i].J2; J3:=BodyConstants[i].J3; J4:=BodyConstants[i].J4;
    Req:=BodyConstants[i].Req; PoleRA:=BodyConstants[i].PoleRA; PoleDec:=BodyConstants[i].PoleDec;
    Result:=(Req<>0.0) or (J2<>0.0);
   end
  else begin J2:=0.0; J3:=0.0; J4:=0.0; Req:=0.0; PoleRA:=0.0; PoleDec:=0.0; Result:=False; end;
end;

function FindOblateness(BodyID: Int64): Int64;
begin
  for Result := 0 to High(GOblateness) do
    if GOblateness[Result].BodyID = BodyID then Exit;
  Result := -1;
end;

procedure SetOblateness(BodyID: Int64; J2, J3, J4, Req, PoleRA, PoleDec: Double);
// Upsert a body's figure into GOblateness, building the ICRF pole unit vector from RA/Dec (deg):
//   pole = (cos Dec cos RA, cos Dec sin RA, sin Dec). Used by TBSPXFile.Init when seeding GOblateness.
var
  i: Int64;
  ra, dec, cd: Double;
begin
  i := FindOblateness(BodyID);
  if i < 0 then
   begin i := Length(GOblateness); SetLength(GOblateness, i+1); GOblateness[i].BodyID := BodyID; end;
  GOblateness[i].J2 := J2; GOblateness[i].J3 := J3; GOblateness[i].J4 := J4; GOblateness[i].Req := Req;
  ra := PoleRA*Pi/180.0; dec := PoleDec*Pi/180.0; cd := Cos(dec);
  GOblateness[i].Pole.X := cd*Cos(ra);
  GOblateness[i].Pole.Y := cd*Sin(ra);
  GOblateness[i].Pole.Z := Sin(dec);
  GOblateness[i].Pole.W := 0.0;
end;

procedure ClearGJ2;
begin
  SetLength(GJ2, 0);
end;

function AddGJ2(BodyID, Idx: Int64): Boolean;
// If BodyID has a figure in GOblateness, append a working-set entry pointing at perturber slot Idx.
var
  i, n: Int64;
begin
  i := FindOblateness(BodyID);
  Result := i >= 0;
  if not Result then Exit;
  n := Length(GJ2); SetLength(GJ2, n+1);
  GJ2[n].Idx  := Idx;
  GJ2[n].J2   := GOblateness[i].J2;
  GJ2[n].J3   := GOblateness[i].J3;
  GJ2[n].J4   := GOblateness[i].J4;
  GJ2[n].Req  := GOblateness[i].Req;
  GJ2[n].Pole := GOblateness[i].Pole;
end;

type
  TFig = record Req, J2, J3, J4, PoleRA, PoleRARate, PoleDec, PoleDecRate, PoleW, PoleWRate: Double; end;
var
  BCN: Int64;   // InitBodyConstants fill cursor (single-threaded lazy init)

function Fig(Req, J2, J3, J4, PoleRA, PoleRARate, PoleDec, PoleDecRate, PoleW, PoleWRate: Double): TFig;
begin
  Result.Req:=Req; Result.J2:=J2; Result.J3:=J3; Result.J4:=J4;
  Result.PoleRA:=PoleRA; Result.PoleRARate:=PoleRARate; Result.PoleDec:=PoleDec; Result.PoleDecRate:=PoleDecRate;
  Result.PoleW:=PoleW; Result.PoleWRate:=PoleWRate;
end;

procedure Add(ACode: Int64; const AName: AnsiString; AGM: Double); overload;
begin  // figure fields stay 0 (SetLength zero-fills the array)
  BodyConstants[BCN].NAIFCode:=ACode; BodyConstants[BCN].Name:=AName; BodyConstants[BCN].GM:=AGM; Inc(BCN);
end;

procedure Add(ACode: Int64; const AName: AnsiString; AGM: Double; const F: TFig); overload;
begin
  with BodyConstants[BCN] do
   begin
    NAIFCode:=ACode; Name:=AName; GM:=AGM;
    Req:=F.Req; J2:=F.J2; J3:=F.J3; J4:=F.J4;
    PoleRA:=F.PoleRA; PoleDec:=F.PoleDec; PoleW:=F.PoleW;
    PoleRARate:=F.PoleRARate; PoleDecRate:=F.PoleDecRate; PoleWRate:=F.PoleWRate;
   end;
  Inc(BCN);
end;

procedure InitBodyConstants;
// Lazy single source of default body constants (name + GM + DE440 figure), merged from what used to live in
// three places: names (BSPFile.BSPTargetCodes), GM (BSPXFile perturber table) and J2/3/4/Req/pole
// (DE440OblatenessDefault, pulled in per body below). Populated on first use only -- NOT at unit init -- and
// freed in finalization, so a TBSPXFile created merely to Init/list a file allocates none of it. Asteroid/KBO
// GMs are AU^3/day^2 literals converted at compile time via AU_KM/SEC2DAY. Indices 0..10 stay aligned with
// codes 0..10 for the O(1) lookup path.
begin
  if Length(BodyConstants)>0 then Exit;   // populate once; idempotent
  SetLength(BodyConstants, 1091);
  BCN:=0;
  Add(0, 'Solar System BC', 132890518666.61139);
  Add(1, 'Mercury BC', 22031.868551400003);
  Add(2, 'Venus BC', 324858.592);
  Add(3, 'Earth BC', 403503.2356254802);
  Add(4, 'Mars BC', 42828.3758157561);
  Add(5, 'Jupiter BC', 126712764.09999998);
  Add(6, 'Saturn BC', 37940584.8418);
  Add(7, 'Uranus BC', 5794556.3999999985);
  Add(8, 'Neptune BC', 6836527.100580399);
  Add(9, 'Pluto BC', 975.5);
  Add(10, 'Sun', 132712440041.27942, Fig(696000.0,2.19613915165298e-07,0.0,0.0, 286.13,0.0, 63.87,0.0, 84.176,14.1844));
  Add(199, 'Mercury', 22031.868551400003, Fig(2440.53,0.0,0.0,0.0, 281.0103,-0.0328, 61.4155,-0.0049, 329.5988,6.1385108));
  Add(299, 'Venus', 324858.592, Fig(6051.8,0.0,0.0,0.0, 272.76,0.0, 67.16,0.0, 160.2,-1.4813688));
  Add(399, 'Earth', 398600.43550702266, Fig(6378.1366,0.00108262539,-2.53241e-06,-1.619898e-06, 0.0,-0.641, 90.0,-0.557, 190.147,360.9856235));
  Add(499, 'Mars', 42828.37362069909, Fig(3396.0,0.001956608633534895,3.147611937672662e-05,-1.53876451692e-05, 317.6808573437165,-0.10927547, 52.88644453060407,-0.05827105, 176.049863,350.891982443297));
  Add(599, 'Jupiter', 126686531.9003704, Fig(71492.0,0.0146965063,-4.5e-08,-0.0005866085, 268.0566974810512,-0.006499, 64.49533881439783,0.002413, 284.95,870.536));
  Add(699, 'Saturn', 37931206.23436167, Fig(60330.0,0.01629061510215236,9.519974025353707e-08,-0.0009351185734877162, 40.59487211316282,-0.036, 83.53435144537646,-0.004, 38.9,810.7939024));
  Add(799, 'Uranus', 5793951.256527211, Fig(25559.0,0.003508966976546036,0.0,-3.579347133056984e-05, 77.31186370800411,0.0, 15.17140155748226,0.0, 203.81,-501.1600928));
  Add(899, 'Neptune', 6835103.145462294, Fig(24764.0,0.003536297303482466,0.0,-3.595236402334314e-05, 299.4129156863023,0.0, 43.35186141539896,0.0, 249.978,541.1397757));
  Add(999, 'Pluto', 869.6138177608748, Fig(1188.3,0.0,0.0,0.0, 132.993,0.0, -6.163,0.0, 302.695,56.3625225));
  Add(301, 'Moon', 4902.80011845755, Fig(1737.4,0.0,0.0,0.0, 269.9949,0.0031, 66.5392,0.013, 38.3213,13.17635815));
  Add(401, 'Phobos', 0.0007087546066894452, Fig(13.0,0.0,0.0,0.0, 317.67071657,-0.10844326, 52.88627266,-0.06134706, 35.1877444,1128.84475928));
  Add(402, 'Deimos', 9.615569648120313e-05, Fig(7.8,0.0,0.0,0.0, 316.65705808,-0.10518014, 53.50992033,-0.05979094, 79.39932954,285.16188899));
  Add(501, 'Io', 5959.915466180539, Fig(1829.4,0.0,0.0,0.0, 268.05,-0.009, 64.5,0.003, 200.39,203.4889538));
  Add(502, 'Europa', 3202.712099607295, Fig(1562.6,0.0,0.0,0.0, 268.08,-0.009, 64.51,0.003, 36.022,101.3747235));
  Add(503, 'Ganymede', 9887.832752719638, Fig(2631.2,0.0,0.0,0.0, 268.2,-0.009, 64.57,0.003, 44.064,50.3176081));
  Add(504, 'Callisto', 7179.283402579837, Fig(2410.3,0.0,0.0,0.0, 268.72,-0.009, 64.83,0.003, 259.51,21.5710715));
  Add(505, 'Amalthea', 0.1645634534798259, Fig(125.0,0.0,0.0,0.0, 268.05,-0.009, 64.49,0.003, 231.67,722.631456));
  Add(506, 'Himalia', 0.1515524299611265, Fig(85.0,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(507, 'Elara', 0.0, Fig(40.0,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(508, 'Pasiphae', 0.0, Fig(18.0,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(509, 'Sinope', 0.0, Fig(14.0,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(510, 'Lysithea', 0.0, Fig(12.0,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(511, 'Carme', 0.0, Fig(15.0,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(512, 'Ananke', 0.0, Fig(10.0,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(513, 'Leda', 0.0, Fig(5.0,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(514, 'Thebe', 0.030148, Fig(58.0,0.0,0.0,0.0, 268.05,-0.009, 64.49,0.003, 8.56,533.70041));
  Add(515, 'Adrastea', 0.000139, Fig(10.0,0.0,0.0,0.0, 268.05,-0.009, 64.49,0.003, 33.29,1206.9986602));
  Add(516, 'Metis', 0.002501, Fig(30.0,0.0,0.0,0.0, 268.05,-0.009, 64.49,0.003, 346.09,1221.2547301));
  Add(517, 'Callirrhoe', 0.0);
  Add(518, 'Themisto', 0.0);
  Add(519, 'Megaclite', 0.0);
  Add(520, 'Taygete', 0.0);
  Add(521, 'Chaldene', 0.0);
  Add(522, 'Harpalyke', 0.0);
  Add(523, 'Kalyke', 0.0);
  Add(524, 'Iocaste', 0.0);
  Add(525, 'Erinome', 0.0);
  Add(526, 'Isonoe', 0.0);
  Add(527, 'Praxidike', 0.0);
  Add(528, 'Autonoe', 0.0);
  Add(529, 'Thyone', 0.0);
  Add(530, 'Hermippe', 0.0);
  Add(531, 'Aitne', 0.0);
  Add(532, 'Eurydome', 0.0);
  Add(533, 'Euanthe', 0.0);
  Add(534, 'Euporie', 0.0);
  Add(535, 'Orthosie', 0.0);
  Add(536, 'Sponde', 0.0);
  Add(537, 'Kale', 0.0);
  Add(538, 'Pasithee', 0.0);
  Add(539, 'Hegemone', 0.0);
  Add(540, 'Mneme', 0.0);
  Add(541, 'Aoede', 0.0);
  Add(542, 'Thelxinoe', 0.0);
  Add(543, 'Arche', 0.0);
  Add(544, 'Kallichore', 0.0);
  Add(545, 'Helike', 0.0);
  Add(546, 'Carpo', 0.0);
  Add(547, 'Eukelade', 0.0);
  Add(548, 'Cyllene', 0.0);
  Add(549, 'Kore', 0.0);
  Add(550, 'Herse', 0.0);
  Add(551, 'S/2003 J 2', 0.0);
  Add(552, 'S/2003 J 3', 0.0);
  Add(553, 'S/2003 J 4', 0.0);
  Add(554, 'S/2003 J 5', 0.0);
  Add(555, 'S/2003 J 9', 0.0);
  Add(556, 'S/2003 J 10', 0.0);
  Add(557, 'S/2003 J 12', 0.0);
  Add(558, 'S/2003 J 16', 0.0);
  Add(559, 'S/2003 J 18', 0.0);
  Add(560, 'S/2003 J 19', 0.0);
  Add(561, 'S/2003 J 23', 0.0);
  Add(562, 'Dia', 0.0);
  Add(563, 'S/2011 J 1', 0.0);
  Add(564, 'S/2011 J 2', 0.0);
  Add(565, 'S/2017 J 1', 0.0);
  Add(566, 'S/2017 J 2', 0.0);
  Add(567, 'S/2017 J 3', 0.0);
  Add(568, 'S/2017 J 5', 0.0);
  Add(569, 'S/2017 J 6', 0.0);
  Add(570, 'S/2017 J 7', 0.0);
  Add(571, 'S/2017 J 8', 0.0);
  Add(572, 'S/2017 J 9', 0.0);
  Add(573, 'Ersa', 0.0);
  Add(574, 'Pandia', 0.0);
  Add(575, 'Eirene', 0.0);
  Add(576, 'Philophrosyne', 0.0);
  Add(577, 'Eupheme', 0.0);
  Add(55501, 'S/2003 J 2', 0.0);
  Add(55502, 'S/2003 J 4', 0.0);
  Add(55503, 'S/2003 J 9', 0.0);
  Add(55504, 'S/2003 J 10', 0.0);
  Add(55505, 'S/2003 J 12', 0.0);
  Add(55506, 'S/2003 J 16', 0.0);
  Add(55507, 'S/2003 J 23', 0.0);
  Add(55508, 'S/2003 J 24', 0.0);
  Add(55509, 'S/2011 J 3', 0.0);
  Add(55510, 'S/2018 J 2', 0.0);
  Add(55511, 'S/2018 J 3', 0.0);
  Add(55512, 'S/2021 J 1', 0.0);
  Add(55513, 'S/2021 J 2', 0.0);
  Add(55514, 'S/2021 J 3', 0.0);
  Add(55515, 'S/2021 J 4', 0.0);
  Add(55516, 'S/2021 J 5', 0.0);
  Add(55517, 'S/2021 J 6', 0.0);
  Add(55518, 'S/2016 J 3', 0.0);
  Add(55519, 'S/2016 J 4', 0.0);
  Add(55520, 'S/2018 J 4', 0.0);
  Add(55521, 'S/2022 J 1', 0.0);
  Add(55522, 'S/2022 J 2', 0.0);
  Add(55523, 'S/2022 J 3', 0.0);
  Add(55524, 'S/2025 J 1', 0.0);
  Add(55525, 'S/2017 J 10', 0.0);
  Add(55526, 'S/2017 J 11', 0.0);
  Add(55531, 'S/2010 J 3', 0.0);
  Add(55532, 'S/2010 J 4', 0.0);
  Add(55533, 'S/2010 J 5', 0.0);
  Add(55534, 'S/2010 J 6', 0.0);
  Add(55535, 'S/2011 J 6', 0.0);
  Add(55536, 'S/2017 J 12', 0.0);
  Add(55537, 'S/2017 J 13', 0.0);
  Add(55538, 'S/2017 J 14', 0.0);
  Add(55539, 'S/2017 J 15', 0.0);
  Add(55540, 'S/2017 J 16', 0.0);
  Add(55541, 'S/2017 J 17', 0.0);
  Add(55542, 'S/2017 J 18', 0.0);
  Add(55543, 'S/2021 J 7', 0.0);
  Add(55544, 'S/2021 J 8', 0.0);
  Add(601, 'Mimas', 2.503488768152587, Fig(207.8,0.0,0.0,0.0, 40.66,-0.036, 83.52,-0.004, 333.46,381.994555));
  Add(602, 'Enceladus', 7.210366688598896, Fig(256.6,0.0,0.0,0.0, 40.66,-0.036, 83.52,-0.004, 6.32,262.7318996));
  Add(603, 'Tethys', 41.21352885489587, Fig(538.4,0.0,0.0,0.0, 40.66,-0.036, 83.52,-0.004, 8.95,190.6979085));
  Add(604, 'Dione', 73.11607172482067, Fig(563.4,0.0,0.0,0.0, 40.66,-0.036, 83.52,-0.004, 357.6,131.5349316));
  Add(605, 'Rhea', 153.9417519146563, Fig(765.0,0.0,0.0,0.0, 40.38,-0.036, 83.55,-0.004, 235.16,79.6900478));
  Add(606, 'Titan', 8978.137095521046, Fig(2575.15,0.0,0.0,0.0, 39.4827,0.0, 83.4279,0.0, 186.5855,22.5769768));
  Add(607, 'Hyperion', 0.3704913747932265, Fig(180.1,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(608, 'Iapetus', 120.5151060137642, Fig(745.7,0.0,0.0,0.0, 318.16,-3.949, 75.03,-1.143, 355.2,4.5379572));
  Add(609, 'Phoebe', 0.5547860052791678, Fig(109.4,0.0,0.0,0.0, 356.9,0.0, 77.8,0.0, 178.58,931.639));
  Add(610, 'Janus', 0.1265765099012197, Fig(101.7,0.0,0.0,0.0, 40.58,-0.036, 83.52,-0.004, 58.83,518.2359876));
  Add(611, 'Epimetheus', 0.03512333288208074, Fig(64.9,0.0,0.0,0.0, 40.58,-0.036, 83.52,-0.004, 293.87,518.4907239));
  Add(612, 'Helene', 0.0004757419551776972, Fig(22.5,0.0,0.0,0.0, 40.85,-0.036, 83.34,-0.004, 245.12,131.6174056));
  Add(613, 'Telesto', 0.0, Fig(16.3,0.0,0.0,0.0, 50.51,-0.036, 84.06,-0.004, 56.88,190.6979332));
  Add(614, 'Calypso', 0.0, Fig(15.3,0.0,0.0,0.0, 36.41,-0.036, 85.04,-0.004, 153.51,190.6742373));
  Add(615, 'Atlas', 0.0003718871247516475, Fig(20.5,0.0,0.0,0.0, 40.58,-0.036, 83.53,-0.004, 137.88,598.306));
  Add(616, 'Prometheus', 0.0107520800100761, Fig(68.2,0.0,0.0,0.0, 40.58,-0.036, 83.53,-0.004, 296.14,587.289));
  Add(617, 'Pandora', 0.009290325122028795, Fig(52.2,0.0,0.0,0.0, 40.58,-0.036, 83.53,-0.004, 162.92,572.7891));
  Add(618, 'Pan', 0.0, Fig(17.2,0.0,0.0,0.0, 40.6,-0.036, 83.5,-0.004, 48.8,626.044));
  Add(619, 'Ymir', 0.0);
  Add(620, 'Paaliaq', 0.0);
  Add(621, 'Tarvos', 0.0);
  Add(622, 'Ijiraq', 0.0);
  Add(623, 'Suttungr', 0.0);
  Add(624, 'Kiviuq', 0.0);
  Add(625, 'Mundilfari', 0.0);
  Add(626, 'Albiorix', 0.0);
  Add(627, 'Skathi', 0.0);
  Add(628, 'Erriapus', 0.0);
  Add(629, 'Siarnaq', 0.0);
  Add(630, 'Thrymr', 0.0);
  Add(631, 'Narvi', 0.0);
  Add(632, 'Methone', 0.0, Fig(1.94,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(633, 'Pallene', 0.0, Fig(2.88,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(634, 'Polydeuces', 0.0, Fig(1.5,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(635, 'Daphnis', 0.0, Fig(4.6,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(636, 'Aegir', 0.0);
  Add(637, 'Bebhionn', 0.0);
  Add(638, 'Bergelmir', 0.0);
  Add(639, 'Bestla', 0.0);
  Add(640, 'Farbauti', 0.0);
  Add(641, 'Fenrir', 0.0);
  Add(642, 'Fornjot', 0.0);
  Add(643, 'Hati', 0.0);
  Add(644, 'Hyrrokkin', 0.0);
  Add(645, 'Kari', 0.0);
  Add(646, 'Loge', 0.0);
  Add(647, 'Suttungr', 0.0);
  Add(648, 'Surtur', 0.0);
  Add(649, 'Greip', 0.0, Fig(0.5,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(650, 'Jarnsaxa', 0.0);
  Add(651, 'Mundilfari', 0.0);
  Add(652, 'Tarqeq', 0.0);
  Add(653, 'Aegaeon', 0.0, Fig(0.7,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(654, 'Gridr', 0.0);
  Add(655, 'Angrboda', 0.0);
  Add(656, 'Skrymir', 0.0);
  Add(657, 'Gerd', 0.0);
  Add(658, 'S/2004 S 26', 0.0);
  Add(659, 'Eggther', 0.0);
  Add(660, 'S/2004 S 29', 0.0);
  Add(661, 'Beli', 0.0);
  Add(662, 'Gunnlod', 0.0);
  Add(663, 'Thiazzi', 0.0);
  Add(664, 'S/2004 S 34', 0.0);
  Add(665, 'S/2004 S 36', 0.0);
  Add(666, 'S/2004 S 37', 0.0);
  Add(65093, 'S/2019 S 1', 0.0);
  Add(65094, 'S/2019 S 2', 0.0);
  Add(65095, 'S/2019 S 3', 0.0);
  Add(65096, 'S/2020 S 1', 0.0);
  Add(65097, 'S/2020 S 2', 0.0);
  Add(65098, 'S/2004 S 40', 0.0);
  Add(65099, 'S/2004 S 41', 0.0);
  Add(65100, 'S/2004 S 42', 0.0);
  Add(65101, 'S/2004 S 43', 0.0);
  Add(65102, 'S/2004 S 44', 0.0);
  Add(65103, 'S/2004 S 45', 0.0);
  Add(65104, 'S/2004 S 46', 0.0);
  Add(65105, 'S/2004 S 47', 0.0);
  Add(65106, 'S/2004 S 48', 0.0);
  Add(65107, 'S/2004 S 49', 0.0);
  Add(65108, 'S/2004 S 50', 0.0);
  Add(65109, 'S/2004 S 51', 0.0);
  Add(65110, 'S/2004 S 52', 0.0);
  Add(65111, 'S/2004 S 53', 0.0);
  Add(65112, 'S/2005 S 4', 0.0);
  Add(65113, 'S/2005 S 5', 0.0);
  Add(65114, 'S/2006 S 11', 0.0);
  Add(65115, 'S/2006 S 12', 0.0);
  Add(65116, 'S/2019 S 6', 0.0);
  Add(65117, 'S/2006 S 13', 0.0);
  Add(65118, 'S/2019 S 7', 0.0);
  Add(65158, 'S/2004 S 54', 0.0);
  Add(65159, 'S/2004 S 55', 0.0);
  Add(65160, 'S/2004 S 56', 0.0);
  Add(65161, 'S/2004 S 57', 0.0);
  Add(65162, 'S/2004 S 58', 0.0);
  Add(65163, 'S/2004 S 59', 0.0);
  Add(65164, 'S/2004 S 60', 0.0);
  Add(65165, 'S/2004 S 61', 0.0);
  Add(65166, 'S/2005 S 6', 0.0);
  Add(65167, 'S/2005 S 7', 0.0);
  Add(65168, 'S/2006 S 21', 0.0);
  Add(65169, 'S/2006 S 22', 0.0);
  Add(65170, 'S/2006 S 23', 0.0);
  Add(65171, 'S/2006 S 24', 0.0);
  Add(65172, 'S/2006 S 25', 0.0);
  Add(65173, 'S/2006 S 26', 0.0);
  Add(65174, 'S/2006 S 27', 0.0);
  Add(65175, 'S/2006 S 28', 0.0);
  Add(65176, 'S/2006 S 29', 0.0);
  Add(65177, 'S/2007 S 10', 0.0);
  Add(65178, 'S/2007 S 11', 0.0);
  Add(65501, 'S/2004 S 7', 0.0);
  Add(65502, 'S/2004 S 12', 0.0);
  Add(65503, 'S/2004 S 13', 0.0);
  Add(65504, 'S/2004 S 17', 0.0);
  Add(65505, 'S/2006 S 1', 0.0);
  Add(65506, 'S/2006 S 3', 0.0);
  Add(65507, 'S/2007 S 2', 0.0);
  Add(65508, 'S/2007 S 3', 0.0);
  Add(65509, 'S/2009 S 1', 0.0);
  Add(65510, 'S/2019 S 1', 0.0);
  Add(65511, 'S/2004 S 20', 0.0);
  Add(65512, 'S/2004 S 21', 0.0);
  Add(65513, 'S/2004 S 22', 0.0);
  Add(65514, 'S/2004 S 23', 0.0);
  Add(65515, 'S/2004 S 24', 0.0);
  Add(65516, 'S/2004 S 25', 0.0);
  Add(65517, 'S/2004 S 27', 0.0);
  Add(65518, 'S/2004 S 28', 0.0);
  Add(65519, 'S/2004 S 30', 0.0);
  Add(65520, 'S/2004 S 32', 0.0);
  Add(65521, 'S/2004 S 33', 0.0);
  Add(65522, 'S/2004 S 34', 0.0);
  Add(65523, 'S/2004 S 35', 0.0);
  Add(65524, 'S/2004 S 38', 0.0);
  Add(65525, 'S/2019 S 2', 0.0);
  Add(65526, 'S/2019 S 3', 0.0);
  Add(65527, 'S/2019 S 4', 0.0);
  Add(65528, 'S/2019 S 5', 0.0);
  Add(701, 'Ariel', 83.46344431770477, Fig(581.1,0.0,0.0,0.0, 257.43,0.0, -15.1,0.0, 156.22,-142.8356681));
  Add(702, 'Umbriel', 85.09338094489388, Fig(584.7,0.0,0.0,0.0, 257.43,0.0, -15.1,0.0, 108.05,-86.8688923));
  Add(703, 'Titania', 226.9437003741248, Fig(788.9,0.0,0.0,0.0, 257.43,0.0, -15.1,0.0, 77.74,-41.3514316));
  Add(704, 'Oberon', 205.3234302535623, Fig(761.4,0.0,0.0,0.0, 257.43,0.0, -15.1,0.0, 6.77,-26.7394932));
  Add(705, 'Miranda', 4.3195168992321, Fig(240.4,0.0,0.0,0.0, 257.43,0.0, -15.08,0.0, 30.7,-254.6906892));
  Add(706, 'Cordelia', 0.0, Fig(13.0,0.0,0.0,0.0, 257.31,0.0, -15.18,0.0, 127.69,-1074.520573));
  Add(707, 'Ophelia', 0.0, Fig(15.0,0.0,0.0,0.0, 257.31,0.0, -15.18,0.0, 130.35,-956.406815));
  Add(708, 'Bianca', 0.0, Fig(21.0,0.0,0.0,0.0, 257.31,0.0, -15.18,0.0, 105.46,-828.391476));
  Add(709, 'Cressida', 0.0, Fig(31.0,0.0,0.0,0.0, 257.31,0.0, -15.18,0.0, 59.16,-776.581632));
  Add(710, 'Desdemona', 0.0, Fig(27.0,0.0,0.0,0.0, 257.31,0.0, -15.18,0.0, 95.08,-760.053169));
  Add(711, 'Juliet', 0.0, Fig(42.0,0.0,0.0,0.0, 257.31,0.0, -15.18,0.0, 302.56,-730.125366));
  Add(712, 'Portia', 0.0, Fig(54.0,0.0,0.0,0.0, 257.31,0.0, -15.18,0.0, 25.03,-701.486587));
  Add(713, 'Rosalind', 0.0, Fig(27.0,0.0,0.0,0.0, 257.31,0.0, -15.18,0.0, 314.9,-644.631126));
  Add(714, 'Belinda', 0.0, Fig(33.0,0.0,0.0,0.0, 257.31,0.0, -15.18,0.0, 297.46,-577.362817));
  Add(715, 'Puck', 0.0, Fig(77.0,0.0,0.0,0.0, 257.31,0.0, -15.18,0.0, 91.24,-472.545069));
  Add(716, 'Caliban', 0.0);
  Add(717, 'Sycorax', 0.0);
  Add(718, 'Prospero', 0.0);
  Add(719, 'Setebos', 0.0);
  Add(720, 'Stephano', 0.0);
  Add(721, 'Trinculo', 0.0);
  Add(722, 'Francisco', 0.0);
  Add(723, 'Margaret', 0.0);
  Add(724, 'Ferdinand', 0.0);
  Add(725, 'Perdita', 0.0);
  Add(726, 'Mab', 0.0);
  Add(727, 'Cupid', 0.0);
  Add(75051, 'S/2023 U 1', 0.0);
  Add(75052, 'S/2025 U 1', 0.0);
  Add(801, 'Triton', 1428.495462910464, Fig(1352.6,0.0,0.0,0.0, 299.36,0.0, 41.17,0.0, 296.53,-61.2572637));
  Add(802, 'Nereid', 0.0, Fig(170.0,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(803, 'Naiad', 0.008530281246540886, Fig(29.0,0.0,0.0,0.0, 299.36,0.0, 43.36,0.0, 254.06,1222.8441209));
  Add(804, 'Thalassa', 0.0235887319799217, Fig(40.0,0.0,0.0,0.0, 299.36,0.0, 43.45,0.0, 102.06,1155.7555612));
  Add(805, 'Despina', 0.1167318403814998, Fig(74.0,0.0,0.0,0.0, 299.36,0.0, 43.45,0.0, 306.51,1075.7341562));
  Add(806, 'Galatea', 0.189898503906069, Fig(79.0,0.0,0.0,0.0, 299.36,0.0, 43.43,0.0, 258.09,839.6597686));
  Add(807, 'Larissa', 0.2548437405693583, Fig(104.0,0.0,0.0,0.0, 299.36,0.0, 43.41,0.0, 179.41,649.053447));
  Add(808, 'Proteus', 2.583422379120727, Fig(218.0,0.0,0.0,0.0, 299.27,0.0, 42.91,0.0, 93.38,320.7654228));
  Add(809, 'Halimede', 0.0);
  Add(810, 'Psamathe', 0.0);
  Add(811, 'Sao', 0.0);
  Add(812, 'Laomedeia', 0.0);
  Add(813, 'Neso', 0.0);
  Add(814, 'Hippocamp', 0.0);
  Add(815, 'S/2002 N 5', 0.0);
  Add(816, 'S/2021 N 1', 0.0);
  Add(85051, 'S/2002 N 5', 0.0);
  Add(85052, 'S/2021 N 1', 0.0);
  Add(901, 'Charon', 105.8799888601881, Fig(605.0,0.0,0.0,0.0, 132.993,0.0, -6.163,0.0, 122.695,56.3625225));
  Add(902, 'Nix', 0.00304817564816976);
  Add(903, 'Hydra', 0.003211039206155255);
  Add(904, 'Kerberos', 0.001110040850536676);
  Add(905, 'Styx', 0.0);
  Add(15, 'Libration angles', 0.0);
  Add(14, 'Nutation angles', 0.0);
  Add(16, 'TT-TDB', 0.0);
  Add(1000000000, 'time', 0.0);
  Add(1000000001, 'TT-TDB', 0.0);
  Add(1000000002, 'TCG-TDB', 0.0);
  Add(20000001, '(1) Ceres', 62.62888863310646, Fig(487.3,0.0,0.0,0.0, 291.418,0.0, 66.764,0.0, 170.65,952.1532));
  Add(20000002, '(2) Pallas', 13.665878143500962);
  Add(20000003, '(3) Juno', 1.920570699855958);
  Add(20000004, '(4) Vesta', 17.288232876051275, Fig(289.0,0.0,0.0,0.0, 309.031,0.0, 42.235,0.0, 285.39,1617.3329428));
  Add(20000005, '(5) Astraea', 0.1442417215886809);
  Add(20000006, '(6) Hebe', 0.6468776896909042);
  Add(20000007, '(7) Iris', 1.1398723230126826);
  Add(20000008, '(8) Flora', 0.25744284007660917);
  Add(20000009, '(9) Metis', 0.6498621955314241);
  Add(20000010, '(10) Hygieia', 5.625147644369983);
  Add(20000011, '(11) Parthenope', 0.4600805826409222);
  Add(20000012, '(12) Victoria', 0.14729837506767948);
  Add(20000013, '(13) Egeria', 0.5108001294868831);
  Add(20000014, '(14) Irene', 0.5320744318113718);
  Add(20000015, '(15) Eunomia', 2.023020986744706);
  Add(20000016, '(16) Psyche', 1.5896582438840352, Fig(139.5,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(20000017, '(17) Thetis', 0.06009119857691238);
  Add(20000018, '(18) Melpomene', 0.21608564230145993);
  Add(20000019, '(19) Fortuna', 0.5559509237318434);
  Add(20000020, '(20) Massalia', 0.25623873588356405);
  Add(20000021, '(21) Lutetia', 0.08862093480958468, Fig(62.0,0.0,0.0,0.0, 52.0,0.0, 12.0,0.0, 94.0,1057.7515));
  Add(20000022, '(22) Kalliope', 0.39491397394741007);
  Add(20000023, '(23) Thalia', 0.12410979235105578);
  Add(20000024, '(24) Themis', 0.5879277527438194);
  Add(20000025, '(25) Phocaea', 0.014603058348312145);
  Add(20000026, '(26) Proserpina', 0.07988706698543542);
  Add(20000027, '(27) Euterpe', 0.11487456529274372);
  Add(20000028, '(28) Bellona', 0.15268221640167812);
  Add(20000029, '(29) Amphitrite', 0.7978007062148098);
  Add(20000030, '(30) Urania', 0.025589375774426784);
  Add(20000031, '(31) Euphrosyne', 1.0793714575085473);
  Add(20000032, '(32) Pomona', 0.035316050867928696);
  Add(20000034, '(34) Circe', 0.14078932841848107);
  Add(20000035, '(35) Leukothea', 0.037093920564146614);
  Add(20000036, '(36) Atalante', 0.22485275139043684);
  Add(20000037, '(37) Fides', 0.10889822084376158);
  Add(20000038, '(38) Leda', 0.03662428435392824);
  Add(20000039, '(39) Laetitia', 0.7282549283201174);
  Add(20000040, '(40) Harmonia', 0.1677060234327801);
  Add(20000041, '(41) Daphne', 0.5406773283660081);
  Add(20000042, '(42) Isis', 0.08402498204701775);
  Add(20000043, '(43) Ariadne', 0.05688371682564617);
  Add(20000044, '(44) Nysa', 0.03641704642873519);
  Add(20000045, '(45) Eugenia', 0.3604720840216532);
  Add(20000046, '(46) Hestia', 0.3719029040568716);
  Add(20000047, '(47) Aglaja', 0.42823457500621465);
  Add(20000048, '(48) Doris', 0.8559425195932342);
  Add(20000049, '(49) Pales', 0.36017459378303085);
  Add(20000050, '(50) Virginia', 0.04065889172669595);
  Add(20000051, '(51) Nemausa', 0.25099982773571033);
  Add(20000052, '(52) Europa', 2.6830359237979358, Fig(189.5,0.0,0.0,0.0, 257.0,0.0, 12.0,0.0, 55.0,1534.6472187));
  Add(20000053, '(53) Kalypso', 0.03457632428851217);
  Add(20000054, '(54) Alexandra', 0.11487356988997294);
  Add(20000056, '(56) Melete', 0.19434860670522994);
  Add(20000057, '(57) Mnemosyne', 0.03351373924839519);
  Add(20000058, '(58) Concordia', 0.08078354086759892);
  Add(20000059, '(59) Elpis', 0.2746636814082064);
  Add(20000060, '(60) Echo', 0.006649286535660697);
  Add(20000062, '(62) Erato', 0.06823007378895442);
  Add(20000063, '(63) Ausonia', 0.12826172444086556);
  Add(20000065, '(65) Cybele', 0.9381057562222009);
  Add(20000068, '(68) Leto', 0.05250231152422939);
  Add(20000069, '(69) Hesperia', 0.5029988613995744);
  Add(20000070, '(70) Panopaea', 0.05476071959305498);
  Add(20000071, '(71) Niobe', 0.0588448601533292);
  Add(20000072, '(72) Feronia', 0.06766292625996356);
  Add(20000074, '(74) Galatea', 0.08526486143392442);
  Add(20000075, '(75) Eurydike', 0.026024493406200163);
  Add(20000076, '(76) Freia', 0.32275440997666743);
  Add(20000077, '(77) Frigga', 0.023646237884417852);
  Add(20000078, '(78) Diana', 0.09134803667661505);
  Add(20000079, '(79) Eurynome', 0.021635975386777632);
  Add(20000080, '(80) Sappho', 0.025326513961338133);
  Add(20000081, '(81) Terpsichore', 0.05677507114353181);
  Add(20000082, '(82) Alkmene', 0.01717057594937125);
  Add(20000083, '(83) Beatrix', 0.08279005260303664);
  Add(20000084, '(84) Klio', 0.03361714354694001);
  Add(20000085, '(85) Io', 0.3772020839356195);
  Add(20000086, '(86) Semele', 0.06443655079240503);
  Add(20000087, '(87) Sylvia', 2.168232073308361);
  Add(20000088, '(88) Thisbe', 1.18980770859745);
  Add(20000089, '(89) Julia', 0.2556281136841203);
  Add(20000090, '(90) Antiope', 0.11852950168055826);
  Add(20000091, '(91) Aegina', 0.06366685108544876);
  Add(20000092, '(92) Undina', 0.09069504901622856);
  Add(20000093, '(93) Minerva', 0.2641999845725194);
  Add(20000094, '(94) Aurora', 0.8734934598280102);
  Add(20000095, '(95) Arethusa', 0.20642217236986804);
  Add(20000096, '(96) Aegle', 0.4228962043818653);
  Add(20000097, '(97) Klotho', 0.046050744547608026);
  Add(20000098, '(98) Ianthe', 0.1429069353511502);
  Add(20000099, '(99) Dike', 0.022489804073461368);
  Add(20000100, '(100) Hekate', 0.03834940726357803);
  Add(20000102, '(102) Miriam', 0.03261058205888709);
  Add(20000103, '(103) Hera', 0.057736063222248314);
  Add(20000104, '(104) Klymene', 0.197949376931499);
  Add(20000105, '(105) Artemis', 0.06300931933345291);
  Add(20000106, '(106) Dione', 0.026613083733339527);
  Add(20000107, '(107) Camilla', 1.4437384029260294);
  Add(20000109, '(109) Felicitas', 0.03917206703082162);
  Add(20000110, '(110) Lydia', 0.05055905564501229);
  Add(20000111, '(111) Ate', 0.05689486760123511);
  Add(20000112, '(112) Iphigenia', 0.01368762079538607);
  Add(20000113, '(113) Amalthea', 0.013822300536045886);
  Add(20000114, '(114) Kassandra', 0.11160152090858945);
  Add(20000115, '(115) Thyra', 0.03127534326062746);
  Add(20000117, '(117) Lomia', 0.3944716843228542);
  Add(20000118, '(118) Peitho', 0.005900805171567574);
  Add(20000120, '(120) Lachesis', 0.4506961677179539);
  Add(20000121, '(121) Hermione', 0.13467023663958214);
  Add(20000124, '(124) Alkeste', 0.06315809574988218);
  Add(20000127, '(127) Johanna', 0.11102223119349343);
  Add(20000128, '(128) Nemesis', 0.38501551561425656);
  Add(20000129, '(129) Antigone', 0.06141763221308967);
  Add(20000130, '(130) Elektra', 0.5952679087411857);
  Add(20000132, '(132) Aethra', 0.007850454667648617);
  Add(20000134, '(134) Sophrosyne', 0.05400439647151997);
  Add(20000135, '(135) Hertha', 0.06510244610217412);
  Add(20000137, '(137) Meliboea', 0.11791441034796644);
  Add(20000139, '(139) Juewa', 0.4152779547167332);
  Add(20000140, '(140) Siwa', 0.1500263796601206);
  Add(20000141, '(141) Lumen', 0.09817056625779198);
  Add(20000143, '(143) Adria', 0.11204605344983301);
  Add(20000144, '(144) Vibilia', 0.18270587541601913);
  Add(20000145, '(145) Adeona', 0.14046349851695983);
  Add(20000146, '(146) Lucina', 0.3325321602449659);
  Add(20000147, '(147) Protogeneia', 0.11148720821958306);
  Add(20000148, '(148) Gallia', 0.12393959493200651);
  Add(20000150, '(150) Nuwa', 0.12067253868541669);
  Add(20000154, '(154) Bertha', 0.8549433055354706);
  Add(20000156, '(156) Xanthippe', 0.12516341665780242);
  Add(20000159, '(159) Aemilia', 0.0862717215234575);
  Add(20000160, '(160) Una', 0.029215495842810336);
  Add(20000162, '(162) Laurentia', 0.04440579064996176);
  Add(20000163, '(163) Erigone', 0.06055198201020827);
  Add(20000164, '(164) Eva', 0.12044699065194764);
  Add(20000165, '(165) Loreley', 0.1186437920653443);
  Add(20000168, '(168) Sibylla', 0.371625028203937);
  Add(20000171, '(171) Ophelia', 0.13572317255969055);
  Add(20000172, '(172) Baucis', 0.02089418069565843);
  Add(20000173, '(173) Ino', 0.15672092900917983);
  Add(20000175, '(175) Andromache', 0.03279518808242005);
  Add(20000176, '(176) Iduna', 0.07055554657547039);
  Add(20000177, '(177) Irma', 0.014328610753312414);
  Add(20000181, '(181) Eucharis', 0.2297745479336737);
  Add(20000185, '(185) Eunike', 0.065214744115853);
  Add(20000187, '(187) Lamberta', 0.3138896992959248);
  Add(20000191, '(191) Kolga', 0.04157486739252559);
  Add(20000192, '(192) Nausikaa', 0.03651629756712426);
  Add(20000194, '(194) Prokne', 0.11015497973035704);
  Add(20000195, '(195) Eurykleia', 0.03960891519447059);
  Add(20000196, '(196) Philomela', 0.32238819008672354);
  Add(20000198, '(198) Ampella', 0.01555840710385635);
  Add(20000200, '(200) Dynamene', 0.06755875774765664);
  Add(20000201, '(201) Penelope', 0.07473140345477325);
  Add(20000203, '(203) Pompeja', 0.2323371578167212);
  Add(20000205, '(205) Martha', 0.02348465334838024);
  Add(20000206, '(206) Hersilia', 0.07842183675477082);
  Add(20000209, '(209) Dido', 0.8750411183583628);
  Add(20000210, '(210) Isabella', 0.03436965223288633);
  Add(20000211, '(211) Isolda', 0.033906337314706235);
  Add(20000212, '(212) Medea', 0.2000475954404604);
  Add(20000213, '(213) Lilaea', 0.03265609490609615);
  Add(20000216, '(216) Kleopatra', 0.18579552917386788, Fig(108.5,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(20000221, '(221) Eos', 0.06518770566466095);
  Add(20000223, '(223) Rosa', 0.024761278065777898);
  Add(20000224, '(224) Oceana', 0.020802793632750102);
  Add(20000225, '(225) Henrietta', 0.02757671768125526);
  Add(20000227, '(227) Philosophia', 0.23747204036328348);
  Add(20000230, '(230) Athamantis', 0.11905907514227132);
  Add(20000233, '(233) Asterope', 0.08960578919611353);
  Add(20000236, '(236) Honoria', 0.02803810821966186);
  Add(20000238, '(238) Hypatia', 0.09951255995362335);
  Add(20000240, '(240) Vanadis', 0.04150958722927113);
  Add(20000241, '(241) Germania', 0.3703547710590757);
  Add(20000247, '(247) Eukrate', 0.32365642469894174);
  Add(20000250, '(250) Bettina', 0.210541533700856);
  Add(20000259, '(259) Aletheia', 0.20294473577768876);
  Add(20000266, '(266) Aline', 0.07442301026841437);
  Add(20000268, '(268) Adorea', 0.1732188832586788);
  Add(20000275, '(275) Sapientia', 0.05633168757633783);
  Add(20000276, '(276) Adelheid', 0.08934822742449162);
  Add(20000283, '(283) Emma', 0.17201592145293673);
  Add(20000287, '(287) Nephthys', 0.022902121184837275);
  Add(20000303, '(303) Josephina', 0.05494234611537666);
  Add(20000304, '(304) Olga', 0.035905612617168195);
  Add(20000308, '(308) Polyxo', 0.09708734072672387);
  Add(20000313, '(313) Chaldaea', 0.03223523841826389);
  Add(20000322, '(322) Phaeo', 0.03620553538257493);
  Add(20000324, '(324) Bamberga', 0.6192998380689841);
  Add(20000326, '(326) Tamara', 0.030643505128887957);
  Add(20000328, '(328) Gudrun', 0.22416430081717242);
  Add(20000329, '(329) Svea', 0.022525560546248016);
  Add(20000334, '(334) Chicago', 0.10824753438332348);
  Add(20000335, '(335) Roberta', 0.09347850194766542);
  Add(20000336, '(336) Lacadiera', 0.00639187318191011);
  Add(20000337, '(337) Devosa', 0.03278571879083161);
  Add(20000338, '(338) Budrosa', 0.012849042225961008);
  Add(20000344, '(344) Desiderata', 0.05905206906878371);
  Add(20000345, '(345) Tercidina', 0.07127103761646063);
  Add(20000346, '(346) Hermentaria', 0.049267645130934366);
  Add(20000347, '(347) Pariana', 0.01114134850349183);
  Add(20000349, '(349) Dembowska', 0.34878920855747064);
  Add(20000350, '(350) Ornamenta', 0.12493918591412681);
  Add(20000354, '(354) Eleonora', 0.31304056026690424);
  Add(20000356, '(356) Liguria', 0.11297275833183058);
  Add(20000357, '(357) Ninina', 0.1288108030475659);
  Add(20000358, '(358) Apollonia', 0.04337216298492039);
  Add(20000360, '(360) Carlova', 0.09188572673718012);
  Add(20000362, '(362) Havnia', 0.05057450661721009);
  Add(20000363, '(363) Padua', 0.1004255197869528);
  Add(20000365, '(365) Corduba', 0.037850416149205354);
  Add(20000366, '(366) Vincentina', 0.035784447997446366);
  Add(20000369, '(369) Aeria', 0.03738928995089803);
  Add(20000372, '(372) Palma', 0.553456856950788);
  Add(20000373, '(373) Melusina', 0.05788796847076451);
  Add(20000375, '(375) Ursula', 0.7945767981334785);
  Add(20000377, '(377) Campania', 0.041724504704845636);
  Add(20000381, '(381) Myrrha', 0.20151912122864232);
  Add(20000385, '(385) Ilmatar', 0.044741781506865266);
  Add(20000386, '(386) Siegena', 0.7509680538526182);
  Add(20000387, '(387) Aquitania', 0.15420309141363422);
  Add(20000388, '(388) Charybdis', 0.12049114804467369);
  Add(20000389, '(389) Industria', 0.035905481293376444);
  Add(20000393, '(393) Lampetia', 0.15056692463875918);
  Add(20000404, '(404) Arsinoe', 0.07240696720248063);
  Add(20000405, '(405) Thia', 0.1271163285821423);
  Add(20000407, '(407) Arachne', 0.054534309000590316);
  Add(20000409, '(409) Aspasia', 0.4174116245317017);
  Add(20000410, '(410) Chloris', 0.14139556813493778);
  Add(20000412, '(412) Elisabetha', 0.05638630987210327);
  Add(20000415, '(415) Palatia', 0.03613588561792105);
  Add(20000416, '(416) Vaticana', 0.07405332145243237);
  Add(20000419, '(419) Aurelia', 0.10662113572067125);
  Add(20000420, '(420) Bertholda', 0.10615740274434202);
  Add(20000423, '(423) Diotima', 0.5162723491041672);
  Add(20000424, '(424) Gratia', 0.04942384466628557);
  Add(20000426, '(426) Hippo', 0.14579241416832672);
  Add(20000431, '(431) Nephele', 0.06270431772193653);
  Add(20000432, '(432) Pythia', 0.006100254632501303);
  Add(20000433, '(433) Eros', 0.00044627034279051865, Fig(17.0,0.0,0.0,0.0, 11.35,0.0, 17.22,0.0, 326.07,1639.38864745));
  Add(20000442, '(442) Eichsfeldia', 0.016899411279084096);
  Add(20000444, '(444) Gyptis', 0.1904765668809448);
  Add(20000445, '(445) Edna', 0.03826284663468136);
  Add(20000449, '(449) Hamburga', 0.05104538341159541);
  Add(20000451, '(451) Patientia', 0.5818564473095459);
  Add(20000454, '(454) Mathesis', 0.029958044502398567);
  Add(20000455, '(455) Bruchsalia', 0.051492156126497136);
  Add(20000464, '(464) Megaira', 0.026116688690634486);
  Add(20000465, '(465) Alekto', 0.02326170347298411);
  Add(20000466, '(466) Tisiphone', 0.03376358787382375);
  Add(20000469, '(469) Argentina', 0.16360068921198206);
  Add(20000471, '(471) Papagena', 0.45543497910708175);
  Add(20000476, '(476) Hedwig', 0.41839626484190223);
  Add(20000481, '(481) Emita', 0.06383065489883204);
  Add(20000485, '(485) Genua', 0.02057704580759042);
  Add(20000488, '(488) Kreusa', 0.3566488833637614);
  Add(20000489, '(489) Comacina', 0.1290541811839731);
  Add(20000490, '(490) Veritas', 0.06399026712595751);
  Add(20000491, '(491) Carina', 0.040510477885699045);
  Add(20000498, '(498) Tokio', 0.0725029591402583);
  Add(20000503, '(503) Evelyn', 0.036810262271901435);
  Add(20000505, '(505) Cava', 0.051282226180311356);
  Add(20000506, '(506) Marion', 0.08552553446122142);
  Add(20000508, '(508) Princetonia', 0.11662312746165146);
  Add(20000511, '(511) Davida', 3.894483147467675, Fig(180.0,0.0,0.0,0.0, 297.0,0.0, 5.0,0.0, 268.1,1684.4193549));
  Add(20000514, '(514) Armida', 0.08459024371093411);
  Add(20000516, '(516) Amherstia', 0.02539787797724641);
  Add(20000517, '(517) Edith', 0.07918434704495778);
  Add(20000521, '(521) Brixia', 0.06989254548545604);
  Add(20000532, '(532) Herculina', 0.7916356438660421);
  Add(20000535, '(535) Montague', 0.02713637127222697);
  Add(20000536, '(536) Merapi', 0.12258586030360011);
  Add(20000545, '(545) Messalina', 0.0875437667253121);
  Add(20000547, '(547) Praxedis', 0.014750766412716002);
  Add(20000554, '(554) Peraga', 0.07146856094762323);
  Add(20000566, '(566) Stereoskopia', 0.7627766228489259);
  Add(20000568, '(568) Cheruskia', 0.03576524501389369);
  Add(20000569, '(569) Misa', 0.024977348009045636);
  Add(20000584, '(584) Semiramis', 0.017423336070000957);
  Add(20000585, '(585) Bilkis', 0.004261838217777395);
  Add(20000591, '(591) Irmgard', 0.007018840838741629);
  Add(20000593, '(593) Titania', 0.019353357757733107);
  Add(20000595, '(595) Polyxena', 0.10075248316126649);
  Add(20000596, '(596) Scheila', 0.3924424113955012);
  Add(20000598, '(598) Octavia', 0.04127587401121944);
  Add(20000599, '(599) Luisa', 0.045403709350589995);
  Add(20000602, '(602) Marianna', 0.10229816575431258);
  Add(20000604, '(604) Tekmessa', 0.020835985498590986);
  Add(20000618, '(618) Elfriede', 0.11298796058772044);
  Add(20000623, '(623) Chimaera', 0.004539085696096338);
  Add(20000626, '(626) Notburga', 0.03149302171901793);
  Add(20000635, '(635) Vundtia', 0.04899431650344466);
  Add(20000654, '(654) Zelinda', 0.0819435407131796);
  Add(20000663, '(663) Gerlinde', 0.0884662467278322);
  Add(20000667, '(667) Denise', 0.07702632721773907);
  Add(20000674, '(674) Rachele', 0.04455867203759321);
  Add(20000675, '(675) Ludmilla', 0.04704721015073733);
  Add(20000680, '(680) Genoveva', 0.03655168274724427);
  Add(20000683, '(683) Lanzia', 0.053826585980657066);
  Add(20000690, '(690) Wratislavia', 0.11597435913826022);
  Add(20000691, '(691) Lehigh', 0.022966847904454364);
  Add(20000694, '(694) Ekard', 0.022877172939615175);
  Add(20000696, '(696) Leonora', 0.03037915669746025);
  Add(20000702, '(702) Alauda', 0.7503286051974695);
  Add(20000704, '(704) Interamnia', 2.8304096388191433);
  Add(20000705, '(705) Erminia', 0.17543310179770957);
  Add(20000709, '(709) Fringilla', 0.053513537981472174);
  Add(20000712, '(712) Boliviana', 0.056513009499934354);
  Add(20000713, '(713) Luscinia', 0.050002386392175725);
  Add(20000735, '(735) Marghanna', 0.03393042253849807);
  Add(20000739, '(739) Mandeville', 0.05335055096014606);
  Add(20000740, '(740) Cantabia', 0.05161296870304091);
  Add(20000747, '(747) Winchester', 0.39987967921369183);
  Add(20000751, '(751) Faina', 0.0689549906930189);
  Add(20000752, '(752) Sulamitis', 0.02468012097326306);
  Add(20000760, '(760) Massinga', 0.03051952350967431);
  Add(20000762, '(762) Pulcova', 0.18453501999074295);
  Add(20000769, '(769) Tatjana', 0.05623365025894545);
  Add(20000772, '(772) Tanete', 0.07788157622415269);
  Add(20000773, '(773) Irmintraud', 0.05155801486837559);
  Add(20000776, '(776) Berbericia', 0.31010452980864994);
  Add(20000778, '(778) Theobalda', 0.009235453850366298);
  Add(20000780, '(780) Armenia', 0.2549091916778215);
  Add(20000784, '(784) Pickeringia', 0.023854665520684024);
  Add(20000786, '(786) Bredichina', 0.08760914996359363);
  Add(20000788, '(788) Hohensteina', 0.0794352387249078);
  Add(20000790, '(790) Pretoria', 0.22617806347808855);
  Add(20000791, '(791) Ani', 0.0945232611307791);
  Add(20000804, '(804) Hispania', 0.11448870898817858);
  Add(20000814, '(814) Tauris', 0.025765835717071903);
  Add(20000849, '(849) Ara', 0.042660313313533336);
  Add(20000895, '(895) Helio', 0.08495440329679811);
  Add(20000909, '(909) Ulla', 0.017781088509251246);
  Add(20000914, '(914) Palisana', 0.019954405485075075);
  Add(20000980, '(980) Anacostia', 0.028465521231450408);
  Add(20001015, '(1015) Christa', 0.0662593834374559);
  Add(20001021, '(1021) Flammario', 0.03597048808028916);
  Add(20001036, '(1036) Ganymed', 0.00947543704013434);
  Add(20001093, '(1093) Freda', 0.06177498711050782);
  Add(20001107, '(1107) Lictoria', 0.05796560224683666);
  Add(20001171, '(1171) Rusthawelia', 0.058646845045052146);
  Add(20001467, '(1467) Mashona', 0.04278319866056383);
  Add(20136199, '(136199) Eris', 1114.6882872739886);
  Add(20136108, '(136108) Haumea', 267.3706757830828);
  Add(20136472, '(136472) Makemake', 153.91386516844494);
  Add(20225088, '(225088) Gonggong', 115.96403822478719);
  Add(20050000, '(50000) Quaoar', 68.59536209133562);
  Add(20090482, '(90482) Orcus', 42.200835622212956);
  Add(20120347, '(120347) Salacia', 29.20406280731879);
  Add(20469705, '(469705) |=Kagara', 0.14549974);
  Add(20612095, '(612095) 1999 OJ4', 0.0269975435);
  Add(20612687, '(612687) 2003 UN284', 0.09410763);
  Add(50031846, '1998 WW31', 0.177402894);
  Add(50092534, '2001 QW322', 0.14349745);
  Add(2000001, '(1) Ceres', 62.62888863310646, Fig(487.3,0.0,0.0,0.0, 291.418,0.0, 66.764,0.0, 170.65,952.1532));
  Add(2000002, '(2) Pallas', 13.665878143500962);
  Add(2000003, '(3) Juno', 1.920570699855958);
  Add(2000004, '(4) Vesta', 17.288232876051275, Fig(289.0,0.0,0.0,0.0, 309.031,0.0, 42.235,0.0, 285.39,1617.3329428));
  Add(2000005, '(5) Astraea', 0.1442417215886809);
  Add(2000006, '(6) Hebe', 0.6468776896909042);
  Add(2000007, '(7) Iris', 1.1398723230126826);
  Add(2000008, '(8) Flora', 0.25744284007660917);
  Add(2000009, '(9) Metis', 0.6498621955314241);
  Add(2000010, '(10) Hygieia', 5.625147644369983);
  Add(2000011, '(11) Parthenope', 0.4600805826409222);
  Add(2000012, '(12) Victoria', 0.14729837506767948);
  Add(2000013, '(13) Egeria', 0.5108001294868831);
  Add(2000014, '(14) Irene', 0.5320744318113718);
  Add(2000015, '(15) Eunomia', 2.023020986744706);
  Add(2000016, '(16) Psyche', 1.5896582438840352, Fig(139.5,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(2000017, '(17) Thetis', 0.06009119857691238);
  Add(2000018, '(18) Melpomene', 0.21608564230145993);
  Add(2000019, '(19) Fortuna', 0.5559509237318434);
  Add(2000020, '(20) Massalia', 0.25623873588356405);
  Add(2000021, '(21) Lutetia', 0.08862093480958468, Fig(62.0,0.0,0.0,0.0, 52.0,0.0, 12.0,0.0, 94.0,1057.7515));
  Add(2000022, '(22) Kalliope', 0.39491397394741007);
  Add(2000023, '(23) Thalia', 0.12410979235105578);
  Add(2000024, '(24) Themis', 0.5879277527438194);
  Add(2000025, '(25) Phocaea', 0.014603058348312145);
  Add(2000026, '(26) Proserpina', 0.07988706698543542);
  Add(2000027, '(27) Euterpe', 0.11487456529274372);
  Add(2000028, '(28) Bellona', 0.15268221640167812);
  Add(2000029, '(29) Amphitrite', 0.7978007062148098);
  Add(2000030, '(30) Urania', 0.025589375774426784);
  Add(2000031, '(31) Euphrosyne', 1.0793714575085473);
  Add(2000032, '(32) Pomona', 0.035316050867928696);
  Add(2000034, '(34) Circe', 0.14078932841848107);
  Add(2000035, '(35) Leukothea', 0.037093920564146614);
  Add(2000036, '(36) Atalante', 0.22485275139043684);
  Add(2000037, '(37) Fides', 0.10889822084376158);
  Add(2000038, '(38) Leda', 0.03662428435392824);
  Add(2000039, '(39) Laetitia', 0.7282549283201174);
  Add(2000040, '(40) Harmonia', 0.1677060234327801);
  Add(2000041, '(41) Daphne', 0.5406773283660081);
  Add(2000042, '(42) Isis', 0.08402498204701775);
  Add(2000043, '(43) Ariadne', 0.05688371682564617);
  Add(2000044, '(44) Nysa', 0.03641704642873519);
  Add(2000045, '(45) Eugenia', 0.3604720840216532);
  Add(2000046, '(46) Hestia', 0.3719029040568716);
  Add(2000047, '(47) Aglaja', 0.42823457500621465);
  Add(2000048, '(48) Doris', 0.8559425195932342);
  Add(2000049, '(49) Pales', 0.36017459378303085);
  Add(2000050, '(50) Virginia', 0.04065889172669595);
  Add(2000051, '(51) Nemausa', 0.25099982773571033);
  Add(2000052, '(52) Europa', 2.6830359237979358, Fig(189.5,0.0,0.0,0.0, 257.0,0.0, 12.0,0.0, 55.0,1534.6472187));
  Add(2000053, '(53) Kalypso', 0.03457632428851217);
  Add(2000054, '(54) Alexandra', 0.11487356988997294);
  Add(2000056, '(56) Melete', 0.19434860670522994);
  Add(2000057, '(57) Mnemosyne', 0.03351373924839519);
  Add(2000058, '(58) Concordia', 0.08078354086759892);
  Add(2000059, '(59) Elpis', 0.2746636814082064);
  Add(2000060, '(60) Echo', 0.006649286535660697);
  Add(2000062, '(62) Erato', 0.06823007378895442);
  Add(2000063, '(63) Ausonia', 0.12826172444086556);
  Add(2000065, '(65) Cybele', 0.9381057562222009);
  Add(2000068, '(68) Leto', 0.05250231152422939);
  Add(2000069, '(69) Hesperia', 0.5029988613995744);
  Add(2000070, '(70) Panopaea', 0.05476071959305498);
  Add(2000071, '(71) Niobe', 0.0588448601533292);
  Add(2000072, '(72) Feronia', 0.06766292625996356);
  Add(2000074, '(74) Galatea', 0.08526486143392442);
  Add(2000075, '(75) Eurydike', 0.026024493406200163);
  Add(2000076, '(76) Freia', 0.32275440997666743);
  Add(2000077, '(77) Frigga', 0.023646237884417852);
  Add(2000078, '(78) Diana', 0.09134803667661505);
  Add(2000079, '(79) Eurynome', 0.021635975386777632);
  Add(2000080, '(80) Sappho', 0.025326513961338133);
  Add(2000081, '(81) Terpsichore', 0.05677507114353181);
  Add(2000082, '(82) Alkmene', 0.01717057594937125);
  Add(2000083, '(83) Beatrix', 0.08279005260303664);
  Add(2000084, '(84) Klio', 0.03361714354694001);
  Add(2000085, '(85) Io', 0.3772020839356195);
  Add(2000086, '(86) Semele', 0.06443655079240503);
  Add(2000087, '(87) Sylvia', 2.168232073308361);
  Add(2000088, '(88) Thisbe', 1.18980770859745);
  Add(2000089, '(89) Julia', 0.2556281136841203);
  Add(2000090, '(90) Antiope', 0.11852950168055826);
  Add(2000091, '(91) Aegina', 0.06366685108544876);
  Add(2000092, '(92) Undina', 0.09069504901622856);
  Add(2000093, '(93) Minerva', 0.2641999845725194);
  Add(2000094, '(94) Aurora', 0.8734934598280102);
  Add(2000095, '(95) Arethusa', 0.20642217236986804);
  Add(2000096, '(96) Aegle', 0.4228962043818653);
  Add(2000097, '(97) Klotho', 0.046050744547608026);
  Add(2000098, '(98) Ianthe', 0.1429069353511502);
  Add(2000099, '(99) Dike', 0.022489804073461368);
  Add(2000100, '(100) Hekate', 0.03834940726357803);
  Add(2000102, '(102) Miriam', 0.03261058205888709);
  Add(2000103, '(103) Hera', 0.057736063222248314);
  Add(2000104, '(104) Klymene', 0.197949376931499);
  Add(2000105, '(105) Artemis', 0.06300931933345291);
  Add(2000106, '(106) Dione', 0.026613083733339527);
  Add(2000107, '(107) Camilla', 1.4437384029260294);
  Add(2000109, '(109) Felicitas', 0.03917206703082162);
  Add(2000110, '(110) Lydia', 0.05055905564501229);
  Add(2000111, '(111) Ate', 0.05689486760123511);
  Add(2000112, '(112) Iphigenia', 0.01368762079538607);
  Add(2000113, '(113) Amalthea', 0.013822300536045886);
  Add(2000114, '(114) Kassandra', 0.11160152090858945);
  Add(2000115, '(115) Thyra', 0.03127534326062746);
  Add(2000117, '(117) Lomia', 0.3944716843228542);
  Add(2000118, '(118) Peitho', 0.005900805171567574);
  Add(2000120, '(120) Lachesis', 0.4506961677179539);
  Add(2000121, '(121) Hermione', 0.13467023663958214);
  Add(2000124, '(124) Alkeste', 0.06315809574988218);
  Add(2000127, '(127) Johanna', 0.11102223119349343);
  Add(2000128, '(128) Nemesis', 0.38501551561425656);
  Add(2000129, '(129) Antigone', 0.06141763221308967);
  Add(2000130, '(130) Elektra', 0.5952679087411857);
  Add(2000132, '(132) Aethra', 0.007850454667648617);
  Add(2000134, '(134) Sophrosyne', 0.05400439647151997);
  Add(2000135, '(135) Hertha', 0.06510244610217412);
  Add(2000137, '(137) Meliboea', 0.11791441034796644);
  Add(2000139, '(139) Juewa', 0.4152779547167332);
  Add(2000140, '(140) Siwa', 0.1500263796601206);
  Add(2000141, '(141) Lumen', 0.09817056625779198);
  Add(2000143, '(143) Adria', 0.11204605344983301);
  Add(2000144, '(144) Vibilia', 0.18270587541601913);
  Add(2000145, '(145) Adeona', 0.14046349851695983);
  Add(2000146, '(146) Lucina', 0.3325321602449659);
  Add(2000147, '(147) Protogeneia', 0.11148720821958306);
  Add(2000148, '(148) Gallia', 0.12393959493200651);
  Add(2000150, '(150) Nuwa', 0.12067253868541669);
  Add(2000154, '(154) Bertha', 0.8549433055354706);
  Add(2000156, '(156) Xanthippe', 0.12516341665780242);
  Add(2000159, '(159) Aemilia', 0.0862717215234575);
  Add(2000160, '(160) Una', 0.029215495842810336);
  Add(2000162, '(162) Laurentia', 0.04440579064996176);
  Add(2000163, '(163) Erigone', 0.06055198201020827);
  Add(2000164, '(164) Eva', 0.12044699065194764);
  Add(2000165, '(165) Loreley', 0.1186437920653443);
  Add(2000168, '(168) Sibylla', 0.371625028203937);
  Add(2000171, '(171) Ophelia', 0.13572317255969055);
  Add(2000172, '(172) Baucis', 0.02089418069565843);
  Add(2000173, '(173) Ino', 0.15672092900917983);
  Add(2000175, '(175) Andromache', 0.03279518808242005);
  Add(2000176, '(176) Iduna', 0.07055554657547039);
  Add(2000177, '(177) Irma', 0.014328610753312414);
  Add(2000181, '(181) Eucharis', 0.2297745479336737);
  Add(2000185, '(185) Eunike', 0.065214744115853);
  Add(2000187, '(187) Lamberta', 0.3138896992959248);
  Add(2000191, '(191) Kolga', 0.04157486739252559);
  Add(2000192, '(192) Nausikaa', 0.03651629756712426);
  Add(2000194, '(194) Prokne', 0.11015497973035704);
  Add(2000195, '(195) Eurykleia', 0.03960891519447059);
  Add(2000196, '(196) Philomela', 0.32238819008672354);
  Add(2000198, '(198) Ampella', 0.01555840710385635);
  Add(2000200, '(200) Dynamene', 0.06755875774765664);
  Add(2000201, '(201) Penelope', 0.07473140345477325);
  Add(2000203, '(203) Pompeja', 0.2323371578167212);
  Add(2000205, '(205) Martha', 0.02348465334838024);
  Add(2000206, '(206) Hersilia', 0.07842183675477082);
  Add(2000209, '(209) Dido', 0.8750411183583628);
  Add(2000210, '(210) Isabella', 0.03436965223288633);
  Add(2000211, '(211) Isolda', 0.033906337314706235);
  Add(2000212, '(212) Medea', 0.2000475954404604);
  Add(2000213, '(213) Lilaea', 0.03265609490609615);
  Add(2000216, '(216) Kleopatra', 0.18579552917386788, Fig(108.5,0.0,0.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0));
  Add(2000221, '(221) Eos', 0.06518770566466095);
  Add(2000223, '(223) Rosa', 0.024761278065777898);
  Add(2000224, '(224) Oceana', 0.020802793632750102);
  Add(2000225, '(225) Henrietta', 0.02757671768125526);
  Add(2000227, '(227) Philosophia', 0.23747204036328348);
  Add(2000230, '(230) Athamantis', 0.11905907514227132);
  Add(2000233, '(233) Asterope', 0.08960578919611353);
  Add(2000236, '(236) Honoria', 0.02803810821966186);
  Add(2000238, '(238) Hypatia', 0.09951255995362335);
  Add(2000240, '(240) Vanadis', 0.04150958722927113);
  Add(2000241, '(241) Germania', 0.3703547710590757);
  Add(2000247, '(247) Eukrate', 0.32365642469894174);
  Add(2000250, '(250) Bettina', 0.210541533700856);
  Add(2000259, '(259) Aletheia', 0.20294473577768876);
  Add(2000266, '(266) Aline', 0.07442301026841437);
  Add(2000268, '(268) Adorea', 0.1732188832586788);
  Add(2000275, '(275) Sapientia', 0.05633168757633783);
  Add(2000276, '(276) Adelheid', 0.08934822742449162);
  Add(2000283, '(283) Emma', 0.17201592145293673);
  Add(2000287, '(287) Nephthys', 0.022902121184837275);
  Add(2000303, '(303) Josephina', 0.05494234611537666);
  Add(2000304, '(304) Olga', 0.035905612617168195);
  Add(2000308, '(308) Polyxo', 0.09708734072672387);
  Add(2000313, '(313) Chaldaea', 0.03223523841826389);
  Add(2000322, '(322) Phaeo', 0.03620553538257493);
  Add(2000324, '(324) Bamberga', 0.6192998380689841);
  Add(2000326, '(326) Tamara', 0.030643505128887957);
  Add(2000328, '(328) Gudrun', 0.22416430081717242);
  Add(2000329, '(329) Svea', 0.022525560546248016);
  Add(2000334, '(334) Chicago', 0.10824753438332348);
  Add(2000335, '(335) Roberta', 0.09347850194766542);
  Add(2000336, '(336) Lacadiera', 0.00639187318191011);
  Add(2000337, '(337) Devosa', 0.03278571879083161);
  Add(2000338, '(338) Budrosa', 0.012849042225961008);
  Add(2000344, '(344) Desiderata', 0.05905206906878371);
  Add(2000345, '(345) Tercidina', 0.07127103761646063);
  Add(2000346, '(346) Hermentaria', 0.049267645130934366);
  Add(2000347, '(347) Pariana', 0.01114134850349183);
  Add(2000349, '(349) Dembowska', 0.34878920855747064);
  Add(2000350, '(350) Ornamenta', 0.12493918591412681);
  Add(2000354, '(354) Eleonora', 0.31304056026690424);
  Add(2000356, '(356) Liguria', 0.11297275833183058);
  Add(2000357, '(357) Ninina', 0.1288108030475659);
  Add(2000358, '(358) Apollonia', 0.04337216298492039);
  Add(2000360, '(360) Carlova', 0.09188572673718012);
  Add(2000362, '(362) Havnia', 0.05057450661721009);
  Add(2000363, '(363) Padua', 0.1004255197869528);
  Add(2000365, '(365) Corduba', 0.037850416149205354);
  Add(2000366, '(366) Vincentina', 0.035784447997446366);
  Add(2000369, '(369) Aeria', 0.03738928995089803);
  Add(2000372, '(372) Palma', 0.553456856950788);
  Add(2000373, '(373) Melusina', 0.05788796847076451);
  Add(2000375, '(375) Ursula', 0.7945767981334785);
  Add(2000377, '(377) Campania', 0.041724504704845636);
  Add(2000381, '(381) Myrrha', 0.20151912122864232);
  Add(2000385, '(385) Ilmatar', 0.044741781506865266);
  Add(2000386, '(386) Siegena', 0.7509680538526182);
  Add(2000387, '(387) Aquitania', 0.15420309141363422);
  Add(2000388, '(388) Charybdis', 0.12049114804467369);
  Add(2000389, '(389) Industria', 0.035905481293376444);
  Add(2000393, '(393) Lampetia', 0.15056692463875918);
  Add(2000404, '(404) Arsinoe', 0.07240696720248063);
  Add(2000405, '(405) Thia', 0.1271163285821423);
  Add(2000407, '(407) Arachne', 0.054534309000590316);
  Add(2000409, '(409) Aspasia', 0.4174116245317017);
  Add(2000410, '(410) Chloris', 0.14139556813493778);
  Add(2000412, '(412) Elisabetha', 0.05638630987210327);
  Add(2000415, '(415) Palatia', 0.03613588561792105);
  Add(2000416, '(416) Vaticana', 0.07405332145243237);
  Add(2000419, '(419) Aurelia', 0.10662113572067125);
  Add(2000420, '(420) Bertholda', 0.10615740274434202);
  Add(2000423, '(423) Diotima', 0.5162723491041672);
  Add(2000424, '(424) Gratia', 0.04942384466628557);
  Add(2000426, '(426) Hippo', 0.14579241416832672);
  Add(2000431, '(431) Nephele', 0.06270431772193653);
  Add(2000432, '(432) Pythia', 0.006100254632501303);
  Add(2000433, '(433) Eros', 0.00044627034279051865, Fig(17.0,0.0,0.0,0.0, 11.35,0.0, 17.22,0.0, 326.07,1639.38864745));
  Add(2000442, '(442) Eichsfeldia', 0.016899411279084096);
  Add(2000444, '(444) Gyptis', 0.1904765668809448);
  Add(2000445, '(445) Edna', 0.03826284663468136);
  Add(2000449, '(449) Hamburga', 0.05104538341159541);
  Add(2000451, '(451) Patientia', 0.5818564473095459);
  Add(2000454, '(454) Mathesis', 0.029958044502398567);
  Add(2000455, '(455) Bruchsalia', 0.051492156126497136);
  Add(2000464, '(464) Megaira', 0.026116688690634486);
  Add(2000465, '(465) Alekto', 0.02326170347298411);
  Add(2000466, '(466) Tisiphone', 0.03376358787382375);
  Add(2000469, '(469) Argentina', 0.16360068921198206);
  Add(2000471, '(471) Papagena', 0.45543497910708175);
  Add(2000476, '(476) Hedwig', 0.41839626484190223);
  Add(2000481, '(481) Emita', 0.06383065489883204);
  Add(2000485, '(485) Genua', 0.02057704580759042);
  Add(2000488, '(488) Kreusa', 0.3566488833637614);
  Add(2000489, '(489) Comacina', 0.1290541811839731);
  Add(2000490, '(490) Veritas', 0.06399026712595751);
  Add(2000491, '(491) Carina', 0.040510477885699045);
  Add(2000498, '(498) Tokio', 0.0725029591402583);
  Add(2000503, '(503) Evelyn', 0.036810262271901435);
  Add(2000505, '(505) Cava', 0.051282226180311356);
  Add(2000506, '(506) Marion', 0.08552553446122142);
  Add(2000508, '(508) Princetonia', 0.11662312746165146);
  Add(2000511, '(511) Davida', 3.894483147467675, Fig(180.0,0.0,0.0,0.0, 297.0,0.0, 5.0,0.0, 268.1,1684.4193549));
  Add(2000514, '(514) Armida', 0.08459024371093411);
  Add(2000516, '(516) Amherstia', 0.02539787797724641);
  Add(2000517, '(517) Edith', 0.07918434704495778);
  Add(2000521, '(521) Brixia', 0.06989254548545604);
  Add(2000532, '(532) Herculina', 0.7916356438660421);
  Add(2000535, '(535) Montague', 0.02713637127222697);
  Add(2000536, '(536) Merapi', 0.12258586030360011);
  Add(2000545, '(545) Messalina', 0.0875437667253121);
  Add(2000547, '(547) Praxedis', 0.014750766412716002);
  Add(2000554, '(554) Peraga', 0.07146856094762323);
  Add(2000566, '(566) Stereoskopia', 0.7627766228489259);
  Add(2000568, '(568) Cheruskia', 0.03576524501389369);
  Add(2000569, '(569) Misa', 0.024977348009045636);
  Add(2000584, '(584) Semiramis', 0.017423336070000957);
  Add(2000585, '(585) Bilkis', 0.004261838217777395);
  Add(2000591, '(591) Irmgard', 0.007018840838741629);
  Add(2000593, '(593) Titania', 0.019353357757733107);
  Add(2000595, '(595) Polyxena', 0.10075248316126649);
  Add(2000596, '(596) Scheila', 0.3924424113955012);
  Add(2000598, '(598) Octavia', 0.04127587401121944);
  Add(2000599, '(599) Luisa', 0.045403709350589995);
  Add(2000602, '(602) Marianna', 0.10229816575431258);
  Add(2000604, '(604) Tekmessa', 0.020835985498590986);
  Add(2000618, '(618) Elfriede', 0.11298796058772044);
  Add(2000623, '(623) Chimaera', 0.004539085696096338);
  Add(2000626, '(626) Notburga', 0.03149302171901793);
  Add(2000635, '(635) Vundtia', 0.04899431650344466);
  Add(2000654, '(654) Zelinda', 0.0819435407131796);
  Add(2000663, '(663) Gerlinde', 0.0884662467278322);
  Add(2000667, '(667) Denise', 0.07702632721773907);
  Add(2000674, '(674) Rachele', 0.04455867203759321);
  Add(2000675, '(675) Ludmilla', 0.04704721015073733);
  Add(2000680, '(680) Genoveva', 0.03655168274724427);
  Add(2000683, '(683) Lanzia', 0.053826585980657066);
  Add(2000690, '(690) Wratislavia', 0.11597435913826022);
  Add(2000691, '(691) Lehigh', 0.022966847904454364);
  Add(2000694, '(694) Ekard', 0.022877172939615175);
  Add(2000696, '(696) Leonora', 0.03037915669746025);
  Add(2000702, '(702) Alauda', 0.7503286051974695);
  Add(2000704, '(704) Interamnia', 2.8304096388191433);
  Add(2000705, '(705) Erminia', 0.17543310179770957);
  Add(2000709, '(709) Fringilla', 0.053513537981472174);
  Add(2000712, '(712) Boliviana', 0.056513009499934354);
  Add(2000713, '(713) Luscinia', 0.050002386392175725);
  Add(2000735, '(735) Marghanna', 0.03393042253849807);
  Add(2000739, '(739) Mandeville', 0.05335055096014606);
  Add(2000740, '(740) Cantabia', 0.05161296870304091);
  Add(2000747, '(747) Winchester', 0.39987967921369183);
  Add(2000751, '(751) Faina', 0.0689549906930189);
  Add(2000752, '(752) Sulamitis', 0.02468012097326306);
  Add(2000760, '(760) Massinga', 0.03051952350967431);
  Add(2000762, '(762) Pulcova', 0.18453501999074295);
  Add(2000769, '(769) Tatjana', 0.05623365025894545);
  Add(2000772, '(772) Tanete', 0.07788157622415269);
  Add(2000773, '(773) Irmintraud', 0.05155801486837559);
  Add(2000776, '(776) Berbericia', 0.31010452980864994);
  Add(2000778, '(778) Theobalda', 0.009235453850366298);
  Add(2000780, '(780) Armenia', 0.2549091916778215);
  Add(2000784, '(784) Pickeringia', 0.023854665520684024);
  Add(2000786, '(786) Bredichina', 0.08760914996359363);
  Add(2000788, '(788) Hohensteina', 0.0794352387249078);
  Add(2000790, '(790) Pretoria', 0.22617806347808855);
  Add(2000791, '(791) Ani', 0.0945232611307791);
  Add(2000804, '(804) Hispania', 0.11448870898817858);
  Add(2000814, '(814) Tauris', 0.025765835717071903);
  Add(2000849, '(849) Ara', 0.042660313313533336);
  Add(2000895, '(895) Helio', 0.08495440329679811);
  Add(2000909, '(909) Ulla', 0.017781088509251246);
  Add(2000914, '(914) Palisana', 0.019954405485075075);
  Add(2000980, '(980) Anacostia', 0.028465521231450408);
  Add(2001015, '(1015) Christa', 0.0662593834374559);
  Add(2001021, '(1021) Flammario', 0.03597048808028916);
  Add(2001036, '(1036) Ganymed', 0.00947543704013434);
  Add(2001093, '(1093) Freda', 0.06177498711050782);
  Add(2001107, '(1107) Lictoria', 0.05796560224683666);
  Add(2001171, '(1171) Rusthawelia', 0.058646845045052146);
  Add(2001467, '(1467) Mashona', 0.04278319866056383);
  Add(2136199, '(136199) Eris', 1114.6882872739886);
  Add(2136108, '(136108) Haumea', 267.3706757830828);
  Add(2136472, '(136472) Makemake', 153.91386516844494);
  Add(2225088, '(225088) Gonggong', 115.96403822478719);
  Add(2050000, '(50000) Quaoar', 68.59536209133562);
  Add(2090482, '(90482) Orcus', 42.200835622212956);
  Add(2120347, '(120347) Salacia', 29.20406280731879);
  Add(2469705, '(469705) |=Kagara', 0.14549974);
  Add(2612095, '(612095) 1999 OJ4', 0.0269975435);
  Add(2612687, '(612687) 2003 UN284', 0.09410763);
  Add(5031846, '1998 WW31', 0.177402894);
  Add(5092534, '2001 QW322', 0.14349745);
  Add(2019521, '(19521) Chaos', 11.384273680874633);
  Add(20019521, '(19521) Chaos', 11.384273680874633);
  Add(2020000, '(20000) Varuna', 24.644635150623614);
  Add(20020000, '(20000) Varuna', 24.644635150623614);
  Add(2028978, '(28978) Ixion', 20.261091335914383);
  Add(20028978, '(28978) Ixion', 20.261091335914383);
  Add(2042301, '(42301) 2001 UR163', 12.222109152889832);
  Add(20042301, '(42301) 2001 UR163', 12.222109152889832);
  Add(2055565, '(55565) 2002 AW197', 27.020072782953505);
  Add(20055565, '(55565) 2002 AW197', 27.020072782953505);
  Add(2055637, '(55637) 2523639 2002 UX25', 8.343412202708715);
  Add(20055637, '(55637) 2523639 2002 UX25', 8.343412202708715);
  Add(2084522, '(84522) 2002 TC302', 102.34430832111957);
  Add(20084522, '(84522) 2002 TC302', 102.34430832111957);
  Add(2090377, '(90377) Sedna', 66.98077006513687);
  Add(20090377, '(90377) Sedna', 66.98077006513687);
  Add(2090568, '(90568) 2004 GV9', 16.680759747773415);
  Add(20090568, '(90568) 2004 GV9', 16.680759747773415);
  Add(2145452, '(145452) 2005 RN43', 16.273524519359988);
  Add(20145452, '(145452) 2005 RN43', 16.273524519359988);
  Add(2174567, '(174567) Varda', 17.78594841643044);
  Add(20174567, '(174567) Varda', 17.78594841643044);
  Add(2208996, '(208996) 2003 AZ84', 27.277463766045713);
  Add(20208996, '(208996) 2003 AZ84', 27.277463766045713);
  Add(2230965, '(230965) 2004 XA192', 1.6347410816064516);
  Add(20230965, '(230965) 2004 XA192', 1.6347410816064516);
  Add(2278361, '(278361) 2007 JJ43', 12.005589176022685);
  Add(20278361, '(278361) 2007 JJ43', 12.005589176022685);
  Add(2307261, '(307261) 2002 MS4', 34.32487282918558);
  Add(20307261, '(307261) 2002 MS4', 34.32487282918558);
  Add(2455502, '(455502) 2003 UZ413', 29.07918638862998);
  Add(20455502, '(455502) 2003 UZ413', 29.07918638862998);
  Add(2528381, '(528381) 2008 ST291', 9.570196405662998);
  Add(20528381, '(528381) 2008 ST291', 9.570196405662998);
end;

function BodyConstIndex(NAIFCode: Int64): Int64;
begin
  if Length(BodyConstants)=0 then InitBodyConstants;
  if (NAIFCode>=0) and (NAIFCode<=10) and (Length(BodyConstants)>10) then Result:=NAIFCode
  else
   begin
    Result:=High(BodyConstants);
    while (Result>=0) and (BodyConstants[Result].NAIFCode<>NAIFCode) do Dec(Result);
   end;
end;

function BodyConst(NAIFCode: Int64): PBodyConstant;
var i: Int64;
begin
  i:=BodyConstIndex(NAIFCode);
  if i>=0 then Result:=@BodyConstants[i] else Result:=nil;
end;

function BodyName(NAIFCode: Int64): AnsiString;
var i: Int64;
begin
  i:=BodyConstIndex(NAIFCode);
  if i>=0 then Result:=BodyConstants[i].Name else Result:='<unknown target code>';
end;

function BodyGM(NAIFCode: Int64): Double;
var i: Int64;
begin
  i:=BodyConstIndex(NAIFCode);
  if i>=0 then Result:=BodyConstants[i].GM else Result:=0.0;
end;

initialization
  // No seed here: GOblateness is filled lazily by BSPXFile.Open from the file's reconciled const records (oblate
  // entries only), per the single-source model -- and this keeps BodyConstants lazily allocated, since
  // DE440OblatenessDefault now reads through it.

finalization
  SetLength(BodyConstants, 0);

end.
