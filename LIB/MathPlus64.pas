unit MathPlus64;

interface

uses
  System.Math;

const
  PINF                =  1/0;
  NINF                = -1/0;
  BITS_ONE            = $3FF0000000000000;
  BITS_TWO            = $4000000000000000;
  BITS_ONE_OVER_TWOPI = $3FC45F306DC9C883;
  BITS_TWOPI          = $401921FB54442D18;

  ONE_OVER_2PI: Double  = 0.15915494309189533576888376337251;
  TWOPI:        Double  = 6.283185307179586476925286766559;
  ONE_OVER_360: Double  = 1/360.0;
  NUM_360:      Double  = 360.0;
  HALFPI:       Double  = 1.5707963267948966192313216916398;
  SQRT_TWOPI:   Double  = 2.506628274631000502415765284811;
  SQRT_HALFPI:  Double  = 1.2533141373155002512078826424055;
  RAD2ARCSEC:   Double  = 206264.80624709635515647335733078;
  ARCSEC2RAD:   Double  = 4.8481368110953599358991410235795e-6;
  RAD2ARCMIN:   Double  = 3437.7467707849392526078892888463;
  ARCMIN2RAD:   Double  = 2.9088820866572159615394846141477e-4;
  RAD2DEG:      Double  = 57.295779513082320876798154814105;
  DEG2RAD:      Double  = 0.017453292519943295769236907684886;
  RAD2SEC:      Double  = 13750.987083139757010431557155385;
  SEC2RAD:      Double  = 7.2722052166430399038487115353692e-5;
  RAD2MIN:      Double  = 229.18311805232928350719261925642;
  MIN2RAD:      Double  = 0.0043633231299858239423092269212215;
  RAD2HOUR:     Double  = 3.8197186342054880584532103209403;
  HOUR2RAD:     Double  = 0.26179938779914943653855361527329;
  SQRT_TWO:     Double  = 1.4142135623730950488016887242097;
  LN_TWO:       Double  = 0.69314718055994530941723212145818; // = 1 / log2 e


function AbsCeil(X: Double): Int64;
function EqualBits(X, Mask: Int64): Boolean;
function RAD360(X: Double): Double;
function RAD180(X: Double): Double;
function DEG360(X: Double): Double;
function DEG180(X: Double): Double;
function Hypot(const X, Y, Z, W: Double): Double; overload;
function Hypot2(const X, Y, Z, W: Double): Double; overload;
procedure KahanSum(var S, R: Double; const D: Double); inline;
function Sum4Sorted(A, B, C, D: Double): Double; inline;
function Sum4Kahan(const D0, D1, D2, D3: Double): Double; inline;
procedure StumpffCS(z: Double; out C, S: Double);
function FloorDiv(const A, B: Int64): Int64; inline;
function MathMod(const A, B: Int64): Int64; inline;

implementation

function AbsCeil(X: Double): Int64;
begin
  if X<0 then Result:=Floor(X) else Result:=Ceil(X);
end;

function EqualBits(X, Mask: Int64): Boolean;
var
  i: Int64;
begin
  i:=X and Mask;
  Result:=(i=Mask) or (i=0);
end;

function RAD360(X: Double): Double; assembler;
asm
  .NOFRAME
  movsd    xmm1, [ONE_OVER_2PI]
  mulsd    xmm1, xmm0
  vroundsd xmm1, xmm1, xmm1, $01
  movsd    xmm2, [TWOPI]
  mulsd    xmm1, xmm2
  subsd    xmm0, xmm1
  xorpd    xmm3, xmm3
  cmpltsd  xmm3, xmm0
  andnpd   xmm3, xmm2
  addsd    xmm0, xmm3
end;

function RAD180(X: Double): Double; assembler;
asm
  .NOFRAME
  movsd    xmm1, [ONE_OVER_2PI]
  mulsd    xmm1, xmm0
  vroundsd xmm1, xmm1, xmm1, $00
  movsd    xmm2, [TWOPI]
  mulsd    xmm1, xmm2
  subsd    xmm0, xmm1
end;

function DEG360(X: Double): Double; assembler;
asm
  .NOFRAME
  mov      rax, BITS_ONE_OVER_TWOPI
  movq     xmm1, rax
  mulsd    xmm1, xmm0
  vroundsd xmm1, xmm1, xmm1, $01
  mov      rax, BITS_TWOPI
  movq     xmm2, rax
  mulsd    xmm1, xmm2
  subsd    xmm0, xmm1
  xorpd    xmm3, xmm3
  cmpltsd  xmm3, xmm0
  andnpd   xmm3, xmm2
  addsd    xmm0, xmm3
end;

function DEG180(X: Double): Double; assembler;
asm
  .NOFRAME
  mov      rax, BITS_ONE_OVER_TWOPI
  movq     xmm1, rax
  mulsd    xmm1, xmm0
  vroundsd xmm1, xmm1, xmm1, $00
  mov      rax, BITS_TWOPI
  movq     xmm2, rax
  mulsd    xmm1, xmm2
  subsd    xmm0, xmm1
end;

function Hypot(const X, Y, Z, W: Double): Double;
begin
  FClearExcept;
  Result := Sqrt((X*X + Y*Y) + (Z*Z + W*W));
  FCheckExcept;
end;

function Hypot2(const X, Y, Z, W: Double): Double;
begin
  FClearExcept;
  Result := (X*X + Y*Y) + (Z*Z + W*W);
  FCheckExcept;
end;

function Sum4Sorted(A, B, C, D: Double): Double; inline;
var
  AbsA, AbsB, AbsC, AbsD: Double;
  Tmp: Double;
begin
  AbsA := Abs(A); AbsB := Abs(B); AbsC := Abs(C); AbsD := Abs(D);
  if AbsA > AbsB then begin Tmp := A; A := B; B := Tmp; Tmp := AbsA; AbsA := AbsB; AbsB := Tmp; end;
  if AbsC > AbsD then begin Tmp := C; C := D; D := Tmp; Tmp := AbsC; AbsC := AbsD; AbsD := Tmp; end;
  if AbsA > AbsC then begin Tmp := A; A := C; C := Tmp; AbsC := AbsA; end;
  if AbsB > AbsD then begin Tmp := B; B := D; D := Tmp; AbsB := AbsD; end;
  if AbsB > AbsC then begin Tmp := B; B := C; C := Tmp; end;
  Result := ((A + B) + C) + D;
end;

procedure KahanSum(var S, R: Double; const D: Double); inline;
var
  T, U: Double;
begin
  T := D - R;
  U := S + T;
  R := (U - S) - T;
  S := U;
end;

function Sum4Kahan(const D0, D1, D2, D3: Double): Double; inline;
var
  S, E: Double;
begin
  S:=D0;
  E:=0.0;
  KahanSum(S, E, D1);
  KahanSum(S, E, D2);
  KahanSum(S, E, D3);
  Result:=S;
end;

procedure StumpffCS(z: Double; out C, S: Double);
// Stumpff c_2(z) and c_3(z) via converging power series:
//   C(z) = sum_{n>=0} (-z)^n / (2n+2)!   =  1/2! - z/4! + z^2/6! - ...
//   S(z) = sum_{n>=0} (-z)^n / (2n+3)!   =  1/3! - z/5! + z^2/7! - ...
// Equivalent closed forms for z > 0: C = (1 - cos(sqrt(z))) / z
//                                     S = (sqrt(z) - sin(sqrt(z))) / (z*sqrt(z))
//
// Convergence: breaks around k=8 for |z|<=1, k=11 for |z|<=4, k=17 for |z|<=20;
// MaxTerms=25 covers roughly |z|<=50.
//
// Warning: for large positive z (elliptic case, z >> 1) the intermediate terms
// overshoot the final answer and cancel, causing catastrophic precision loss.
// Switch to the trig/hyperbolic closed forms once the realistic input range is known.
const
  MaxTerms = 25;
var
  tc, ts  : Double;
  a, b, k : Integer;
begin
  tc := 0.5;           // n=0 term for C: 1/2!
  ts := 1.0 / 6.0;    // n=0 term for S: 1/3!
  C  := tc;
  S  := ts;
  a  := 3;             // C denom base: pair (a)(a+1) = 3*4 for n=1
  b  := 4;             // S denom base: pair (b)(b+1) = 4*5 for n=1
  for k := 1 to MaxTerms do
  begin
    tc := -tc * z / (a * (a + 1));
    ts := -ts * z / (b * (b + 1));
    C  := C + tc;
    S  := S + ts;
    // +1e-30 guards against a spurious early exit if C or S passes through zero
    if (Abs(tc) < 1e-15 * (Abs(C) + 1e-30)) and
       (Abs(ts) < 1e-15 * (Abs(S) + 1e-30)) then
      Break;
    Inc(a, 2);
    Inc(b, 2);
  end;
end;

function FloorDiv(const A, B: Int64): Int64; inline;
begin
  Result := A div B;
  if ((A xor B) < 0) and (A mod B <> 0) then
    Dec(Result);
end;

function MathMod(const A, B: Int64): Int64; inline;
begin
  Result := A mod B;
  if (Result < 0) then
    Inc(Result, B);
end;

end.
