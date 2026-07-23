unit GravityFieldFile;

// Readers for external spherical-harmonic gravity-field files, used at BUILD TIME (by BSPMerge) to bake a body's
// C̄nm/S̄nm into its BSPX const record (TBSPXBodyConst.Chi). Nothing here runs at integration time -- the runtime only
// ever reads the already-baked Chi. The big source files (EIGEN-6C4 is ~178 MB, degree 2190) are never shipped.
//
// LoadGFC: ICGEM .gfc format (EIGEN-6C4, EGM2008, GOCO, ...). Fills Chi with the fully-normalised coefficients for
// degrees 2..TruncDeg in the shared packing (CelestialMechanics.GravChiIndex). GM/Rref/tide flags are returned raw
// (SI, as the header states) for the caller to convert (m->km) and decide -- we keep DE440 GM but use the file's own
// reference radius (the coefficients are only valid at it), and note the tide system. Static (gfc) and time-variable
// (gfct, whose reference value is taken while the trnd/asin/acos trend lines are ignored) files both parse.

interface

uses
  System.SysUtils, System.Classes,
  Vec4D, CelestialMechanics;

type
  TGravFieldInfo = record
    ModelName:  string;
    GM:         Double;      // header value AS READ (ICGEM: m^3/s^2) -- caller converts/decides
    Rref:       Double;      // header value AS READ (ICGEM: m) -- caller converts to km; the coefficients are normalised to THIS radius
    HdrMaxDeg:  Int64;       // the model's own max degree (>= what we keep)
    FullyNorm:  Boolean;     // norm = fully_normalized (required: Chi is 4pi-normalised)
    TideFree:   Boolean;     // tide_system = tide_free (vs zero_tide / mean_tide)
    Placed:     Int64;       // number of (n,m) coefficient pairs actually stored
  end;

function LoadGFC(const FileName: string; TruncDeg: Int64; var Chi: TDynDoubleArray; out Info: TGravFieldInfo; out Err: string): Boolean;

implementation

var
  GFmt: TFormatSettings;   // '.'-decimal settings, so parsing is locale-proof

function ToFloat(const s: string; out v: Double): Boolean;
var t: string;
begin
  t := s;
  if (Pos('D', t) > 0) or (Pos('d', t) > 0) then   // tolerate a Fortran 'D' exponent
   t := StringReplace(StringReplace(t, 'D', 'E', [rfReplaceAll]), 'd', 'E', [rfReplaceAll]);
  Result := TryStrToFloat(t, v, GFmt);
end;

function LoadGFC(const FileName: string; TruncDeg: Int64; var Chi: TDynDoubleArray; out Info: TGravFieldInfo; out Err: string): Boolean;
var
  rdr: TStreamReader;
  line, kw: string;
  toks: TArray<string>;
  inHead: Boolean;
  n, m, iC, iSin, want: Int64;
  cval, sval: Double;
begin
  Result := False;
  Err := '';
  Info := Default(TGravFieldInfo);
  if TruncDeg < 2 then begin Err := 'truncation degree < 2'; Exit; end;
  if TruncDeg > GRAV_NMAX then TruncDeg := GRAV_NMAX;
  SetLength(Chi, GRAV_NCOEF);
  for n := 0 to GRAV_NCOEF-1 do Chi[n] := 0.0;   // orders/degrees the file omits stay 0
  want := (TruncDeg+1)*(TruncDeg+2) div 2 - 3;    // number of (n,m) pairs for n=2..TruncDeg

  if not FileExists(FileName) then begin Err := 'file not found: '+FileName; Exit; end;
  rdr := TStreamReader.Create(FileName, TEncoding.ASCII);
  try
   inHead := True;
   while not rdr.EndOfStream do
    begin
     line := rdr.ReadLine;
     toks := line.Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
     if Length(toks) = 0 then Continue;
     kw := LowerCase(toks[0]);
     if inHead then
      begin
       if kw = 'end_of_head' then inHead := False
       else if (Length(toks) >= 2) then
        begin
         if      kw = 'earth_gravity_constant' then ToFloat(toks[1], Info.GM)
         else if kw = 'radius'                 then ToFloat(toks[1], Info.Rref)
         else if kw = 'max_degree'             then Info.HdrMaxDeg := StrToInt64Def(toks[1], 0)
         else if kw = 'modelname'              then Info.ModelName := toks[1]
         else if kw = 'norm'                   then Info.FullyNorm := SameText(toks[1], 'fully_normalized')
         else if kw = 'tide_system'            then Info.TideFree  := SameText(toks[1], 'tide_free');
        end;
       Continue;
      end;
     // data section: 'gfc L M C S [sigC sigS]'  (gfct = time-variable: take its reference value, ignore the
     // trnd/asin/acos lines that follow -- see [[bspx-harmonic-field-extension]] on dropping time-variable terms).
     if (kw <> 'gfc') and (kw <> 'gfct') then Continue;
     if Length(toks) < 5 then Continue;
     n := StrToInt64Def(toks[1], -1);
     m := StrToInt64Def(toks[2], -1);
     if (n < 2) or (n > TruncDeg) or (m < 0) or (m > n) then Continue;
     if not ToFloat(toks[3], cval) then Continue;
     if not ToFloat(toks[4], sval) then Continue;
     GravChiIndex(n, m, iC, iSin);
     Chi[iC] := cval;
     if iSin >= 0 then Chi[iSin] := sval;
     Inc(Info.Placed);
     if Info.Placed >= want then Break;   // every (n,m) up to TruncDeg is in -- stop scanning the (huge) file
    end;
  finally
   rdr.Free;
  end;

  if Info.Placed < want then
   begin Err := Format('incomplete field: placed %d of %d coefficients up to degree %d', [Info.Placed, want, TruncDeg]); Exit; end;
  if not Info.FullyNorm then
   begin Err := 'file is not fully_normalized (Chi requires 4pi/geodesy normalisation)'; Exit; end;
  Result := True;
end;

initialization
  GFmt := TFormatSettings.Invariant;

end.
