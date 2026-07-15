unit MDA;

// SPK Type 21 (Extended Modified Difference Arrays / "difference lines") evaluator -- the analogue of
// Chebyshev.pas for the Type 21 ephemeris format that Horizons emits for KBOs/comets. Ported from the SPICE
// Toolkit routine spke21.f, via whiskie14142/spktype21 (which corrects the record field offsets to match the
// actual data: the stored record has no leading MAXDIM word, so every field is shifted back by one vs the
// Fortran comments). Validated against the Horizons Quaoar SPK (20050000.bsp): each record reproduces its
// reference state at TL exactly, and adjacent records agree to 0.18 m across all 500 record boundaries.
//
// A Type 21 segment is laid out as:
//   [ record 0 .. record N-1 ][ epoch 0 .. epoch N-1 ][ epoch-100 directory ][ MAXDIM ][ N ]
// Each record is DLSIZE = 4*MAXDIM+11 doubles:
//   TL(1)  G(MAXDIM)  {POS_x,VEL_x, POS_y,VEL_y, POS_z,VEL_z}(6)  DT(MAXDIM,3)  KQMAX1(1)  KQ(3)
// The epoch array holds each record's final epoch (ascending); the covering record for time ET is the first
// whose epoch >= ET. States are km / km s^-1, relative to the segment's centre in its inertial frame.

interface

{$POINTERMATH ON}

// Evaluate one Type 21 record at ET. State receives 6 doubles: X, Y, Z, VX, VY, VZ.
procedure MDAEvalRecord(Rec: PDouble; MaxDim: Int64; ET: Double; State: PDouble);
// Pick the covering record (binary search on Epochs) and evaluate. Records -> N records, Epochs -> N epochs.
function  MDAEval(Records, Epochs: PDouble; NRec, MaxDim: Int64; ET: Double; State: PDouble): Boolean;
// Evaluate a whole Type 21 segment: Seg -> the SegLen doubles of the segment; MAXDIM and N read from the tail.
function  MDAEvalSegment(Seg: PDouble; SegLen: Int64; ET: Double; State: PDouble): Boolean;

implementation

const
  MAXTRM = 25;   // SPICE spk21.inc: maximum difference-table dimension per component

procedure MDAEvalRecord(Rec: PDouble; MaxDim: Int64; ET: Double; State: PDouble);
var
  G, DTbase: PDouble;                              // G -> Rec[1], DTbase -> Rec[MaxDim+7]
  REFP, REFV: array[0..2] of Double;
  KQ: array[0..2] of Int64;
  FC, WC, W: array[0..MAXTRM+3] of Double;
  TL, DELTA, TP, SUM: Double;
  KQMAX1, MQ2, KS, KS1, JX, I, J, KQQ: Int64;
begin
  TL     := Rec[0];
  G      := Rec + 1;                               // G[J-1] = G[(J-1)]
  REFP[0]:= Rec[MaxDim+1];  REFV[0]:= Rec[MaxDim+2];
  REFP[1]:= Rec[MaxDim+3];  REFV[1]:= Rec[MaxDim+4];
  REFP[2]:= Rec[MaxDim+5];  REFV[2]:= Rec[MaxDim+6];
  DTbase := Rec + (MaxDim+7);                       // DT[(I-1)*MaxDim + (J-1)] = component I-1, order J-1
  KQMAX1 := Round(Rec[4*MaxDim+7]);
  KQ[0]  := Round(Rec[4*MaxDim+8]);
  KQ[1]  := Round(Rec[4*MaxDim+9]);
  KQ[2]  := Round(Rec[4*MaxDim+10]);

  DELTA := ET - TL;
  TP    := DELTA;
  MQ2   := KQMAX1 - 2;
  KS    := KQMAX1 - 1;

  FC[0] := 1.0;
  for J := 1 to MQ2 do
   begin
    FC[J]   := TP / G[J-1];
    WC[J-1] := DELTA / G[J-1];
    TP      := DELTA + G[J-1];
   end;
  for J := 1 to KQMAX1 do W[J-1] := 1.0 / J;

  // build the W(K) weights for the position interpolation
  JX  := 0;
  KS1 := KS - 1;
  while KS >= 2 do
   begin
    Inc(JX);
    for J := 1 to JX do W[J+KS-1] := FC[J]*W[J+KS1-1] - WC[J-1]*W[J+KS-1];
    KS  := KS1;
    Dec(KS1);
   end;

  // position: STATE[i] = REFP[i] + DELTA*(REFV[i] + DELTA*SUM)   (KS = 1 here)
  for I := 1 to 3 do
   begin
    KQQ := KQ[I-1];
    SUM := 0.0;
    for J := KQQ downto 1 do SUM := SUM + DTbase[(I-1)*MaxDim + (J-1)] * W[J+KS-1];
    State[I-1] := REFP[I-1] + DELTA*(REFV[I-1] + DELTA*SUM);
   end;

  // rebuild the W(K) weights for the velocity interpolation, then drop KS to 0
  for J := 1 to JX do W[J+KS-1] := FC[J]*W[J+KS1-1] - WC[J-1]*W[J+KS-1];
  Dec(KS);

  // velocity: STATE[3+i] = REFV[i] + DELTA*SUM
  for I := 1 to 3 do
   begin
    KQQ := KQ[I-1];
    SUM := 0.0;
    for J := KQQ downto 1 do SUM := SUM + DTbase[(I-1)*MaxDim + (J-1)] * W[J+KS-1];
    State[I+2] := REFV[I-1] + DELTA*SUM;
   end;
end;

function MDAEval(Records, Epochs: PDouble; NRec, MaxDim: Int64; ET: Double; State: PDouble): Boolean;
var lo, hi, mid: Int64;
begin
  Result := (NRec > 0) and (MaxDim > 0);
  if not Result then Exit;
  lo := 0; hi := NRec-1;                            // first record whose epoch >= ET (clamped to the ends)
  while lo < hi do
   begin
    mid := (lo + hi) div 2;
    if Epochs[mid] >= ET then hi := mid else lo := mid + 1;
   end;
  MDAEvalRecord(Records + lo*(4*MaxDim + 11), MaxDim, ET, State);
end;

function MDAEvalSegment(Seg: PDouble; SegLen: Int64; ET: Double; State: PDouble): Boolean;
var MaxDim, NRec: Int64;
begin
  Result := False;
  if SegLen < 2 then Exit;
  MaxDim := Round(Seg[SegLen-2]);
  NRec   := Round(Seg[SegLen-1]);
  if (MaxDim <= 0) or (MaxDim > MAXTRM) or (NRec <= 0) then Exit;
  if NRec*(4*MaxDim + 11) + NRec > SegLen then Exit;   // records + epoch array must fit
  Result := MDAEval(Seg, Seg + NRec*(4*MaxDim + 11), NRec, MaxDim, ET, State);
end;

end.
