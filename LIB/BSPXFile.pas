unit BSPXFile;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes, System.Math, System.Math.Vectors,
  AsmUtils64, RSoftClasses64, RSoftUtils64, MathPlus64, Vec4D, CelestialMechanics, Chebyshev;

const
  BSPX_ID = 'BSPX';
  BSPX_VER = $00000001;

type
 TBSPXVer = packed record
   case Integer of
    0: (Major, Minor, Release, Build: Byte);
    1: (Ver: Int32);
  end;
  PBSPXVer = ^TBSPXVer;

  TBSPXDesc = packed record
   TargetName, TargetSrc: array[0..31] of AnsiChar;     //idx  0 -  7
   TargetID, CenterID, RefID, TypeID,                   //idx  8 - 11
   DataPtr, DataLen, RecLen, NumRec,                    //idx 12 - 15
   NumComp, NumCoef, RTArrayLen, RTRecLen,              //idx 16 - 19
   RTOffsetX, RTOffsetY, RTOffsetZ, RTDataPtr: Int64;   //idx 20 - 23
   Epoch0, Epoch1, T0, T1,                              //idx 24 - 27
   ValIntv, Radius, InvRadius, GM: Double;              //idx 28 - 31 (GM is the GM of this body as a perturber, not the GM of the center; NB Radius here is the Chebyshev time half-interval, NOT a physical radius)
  end;                                                   // TODO(refactor): GM's logical home is TBSPXBodyConst; the copy here exists only because integrators read Desc.GM in hot paths — relocating it is a separate pass
  PBSPXDesc = ^TBSPXDesc;

  // Curated physical constants for the const section (Hdr.Cnst), one record per descriptor
  // (index-matched, records 0..DescCount-1), with the final record (index DescCount) holding the
  // SS-wide trailer via variant 1. Sourced by the SPKMerge builder from gm_de440.tpc (GM),
  // header.440t (Sun/Earth J + AU/CLIGHT/BETA/GAMMA/GMS), the satellite BSP comment areas
  // (giant-planet Req/J/pole) and Horizons text (asteroid Req). See memory bspx-const-section-sources.
  TBSPXBodyConst = packed record    // fixed 256 bytes (32 doubles), matching the TBSPXDesc stride; the
   case Integer of                  // reserved tail leaves room to add per-body constants without a format break
    0: (GM, Req, J2, J3, J4: Double;                     // per-body: GM (km^3/s^2), equatorial radius (km), zonal harmonics
        PoleRA, PoleDec, PoleW: Double;                  // IAU pole RA/Dec + prime meridian W at POLTIM (deg)
        PoleRARate, PoleDecRate, PoleWRate: Double;      // rates: RA/Dec deg/century, W deg/DAY (SPICE PCK convention) -- 11 doubles used
        ReservedBody: array[0..20] of Double);           // reserved -> 32 doubles total = 256 bytes
    1: (AU, CLIGHT, BETA, GAMMA, GMS, POLTIM: Double;    // final record only: SS-wide constants (same 256-byte slot)
        ReservedGen: array[0..25] of Double);            // reserved -> 32 doubles total = 256 bytes
  end;
  PBSPXBodyConst = ^TBSPXBodyConst;

  TBSPXSectionData = packed record
  // Ptr = base offset of section
  // Size = total size of section (bytes) = must be equal to Num*Len
  // Num = number or records
  // Len = length of records (bytes)
   Ptr, Size, Num, Len: Int64;
  end;
  PBSPXSectionData = ^TBSPXSectionData;

  TBSPXHdr = packed record
   BSPXID: array[0..3] of AnsiChar;
   BSPXVer: TBSPXVer;
   FileSize: Int64;
   BSPXComment: array[0..15] of AnsiChar;
   Data, Cnst, Desc: TBSPXSectionData;
   GM: array[0..10] of Double; // GM values of SSB, planet BC 1-9 and Sun (10)
   Epoch0, Epoch1: Double;
   ReservedI: array[0..2] of Int64;
  end;
  PBSPXHdr = ^TBSPXHdr;

  // Per-body precomputed operation table for GetPerturberStates.
  // AddCount = -1 means the entry is invalid (skip).
  // Add Input[AddIdx[0..AddCount-1]].R, subtract Input[SubIdx[0..SubCount-1]].R.
  TPerturberOpRec = record
    AddCount, SubCount: Int64;
    AddIdx: array[0..6] of Int64;
    SubIdx: array[0..6] of Int64;
  end;

  TBSPXFile = class(TPersistent)
  private
    FFileName: string;
    FHdr: TBSPXHdr;
    FDesc: array of TBSPXDesc;
    FCnst: array of TBSPXBodyConst;   // records 0..DescCount-1 index-matched to FDesc; [DescCount] = SS-wide trailer. Guaranteed complete after Init.
    FStream: TAlignedMemoryStream;
    FError: string;
    FPerturberStateCenterID: Int64;
    FPerturberOps: array of TPerturberOpRec;
    FPerturberIdx: array of Int64;   // dense descriptor indices of the real perturbers (GM>0); built in Init
    FPerturberSoA: TPerturberSoA;    // packed perturber SoA (per node) handed to the PN force kernels; raw columns filled by PackPerturbers
    FMaxThreadCount: Integer;
    function GetDesc(Index: Int64): PBSPXDesc;
    function GetDescCount: Int64;
    function GetBodyConst(Index: Int64): PBSPXBodyConst;
    function GetGeneralConst: PBSPXBodyConst;
    function GetPerturberCount: Int64;
    function GetPerturberSoA: PPerturberSoA;
    procedure InterpolateCore1(DescIndex: Int64; T: Double; R: PVec4D);
    procedure InterpolateCore2(DescIndex: Int64; T: Double; S: PState4D);
    procedure SetPerturberStateCenterID(Value: Int64);
  public
    constructor Create;
    destructor Destroy; override;
    function Init(const FileName: string): Boolean;
    function Open: Boolean;
    procedure Close;
    procedure Finalize;
    function FindDesc(TargetID, CenterID, RefID: Int64): Int64; overload;
    function FindDesc(TargetID, CenterID: Int64): Int64; overload;
    function FindDesc(TargetID: Int64): Int64; overload;
    function GetPerturberName(Code: Int64): AnsiString;
    function GetPerturberGM(Code: Int64): Double;
    function Interpolate1(DescIndex: Int64; T: Double; R: PVec4D): Boolean;
    function Interpolate2(DescIndex: Int64; T: Double; S: PState4D): Boolean;
    function RelativeInterpolate2(TargetID, CenterID, RefID: Int64; T: Double; S: PState4D): Boolean;
    function BatchInterpolate1(T: Double; Output: TState4DArray): Boolean;
    function BatchInterpolate2(T: Double; Output: TState4DArray): Boolean;
    function MultiBatchInterpolate1(const T: TDynDoubleArray; Output: TState4DArrays): Boolean;
    function MultiBatchInterpolate2(const T: TDynDoubleArray; Output: TState4DArrays): Boolean;
    function GetPerturberStates(Input, Output: TState4DArray): Boolean;
    function GetMultiPerturberStates(Input, Output: TState4DArrays): Boolean;
    procedure PackPerturbers(const P: TState4DArrays);   // compact P[node][desc] -> dense per-node SoA (real perturbers only) for the force kernels
    property MaxThreadCount: Integer read FMaxThreadCount write FMaxThreadCount;
    property FileName: string read FFileName;
    property Hdr: TBSPXHdr read FHdr;
    property Desc[Index: Int64]: PBSPXDesc read GetDesc;
    property DescCount: Int64 read GetDescCount;
    property PerturberCount: Int64 read GetPerturberCount;   // number of real perturbers (GM>0) = length of the internal index map
    property PerturberSoA: PPerturberSoA read GetPerturberSoA;   // packed perturber SoA (per node), valid after PackPerturbers -- hand to the force kernel
    property BodyConst[Index: Int64]: PBSPXBodyConst read GetBodyConst;   // per-body physical constants (index-matched to Desc)
    property GeneralConst: PBSPXBodyConst read GetGeneralConst;           // SS-wide trailer (AU/CLIGHT/BETA/GAMMA/GMS/POLTIM)
    property Stream: TAlignedMemoryStream read FStream;
    property PerturberStateCenterID: Int64 read FPerturberStateCenterID write SetPerturberStateCenterID;
    property Error: string read FError;
  end;

function GetCorrectedGM(GM_center, GM_target: Double; isBarycentric: Boolean): Double;
procedure Osculate(S: PState4D);
function BSPXTimeStr(T: Double; Decimals: Int64): string;
function StrBSPXTime(const S: string): Double;   // inverse of BSPXTimeStr: Gregorian '[-]YYYY-MM-DD[.frac]' -> TDB seconds since J2000
function BSPXStr(const S: array of AnsiChar; MaxLength: Int64): string;

// Hardcoded DE440 constant defaults. Base layer for both the builder (per-body base, overridden by any
// value found in the provided header/tpc/BSP) and Open (fills gaps so in-memory FCnst is always complete;
// integrators then read it with no per-use checks). GMs km^3/s^2 (gm_de440.tpc), oblateness from
// header.440t (Sun/Earth) and the satellite comment blocks (giants). See memory bspx-const-section-sources.
function DE440General: TBSPXBodyConst;                             // SS-wide trailer defaults
procedure SeedBodyConst(BodyID: Int64; out C: TBSPXBodyConst);   // per-body const record (GM + figure) from CelestialMechanics.BodyConstants

implementation

// ============================================================================
// TBSPXFile
// ============================================================================

constructor TBSPXFile.Create;
begin
  inherited Create;
  FPerturberStateCenterID:=-1;
end;

destructor TBSPXFile.Destroy;
begin
  Finalize;
  inherited Destroy;
end;

function ValidGM(const g: Double): Boolean; inline;
// A usable GM must be finite and strictly positive. Rejects 0, negatives, +/-INF and NaN
// (NaN fails g>0.0). Everything invalid is replaced by the authoritative DE440 default during Open.
begin
  Result := (g > 0.0) and not IsInfinite(g);
end;

function TBSPXFile.GetDesc(Index: Int64): PBSPXDesc;
begin
  Result:=@FDesc[Index];
end;

function TBSPXFile.GetDescCount: Int64;
begin
  Result:=Length(FDesc);
end;

function TBSPXFile.GetBodyConst(Index: Int64): PBSPXBodyConst;
begin
  Result:=@FCnst[Index];   // FCnst is guaranteed complete after Init; caller uses 0..DescCount-1
end;

function TBSPXFile.GetGeneralConst: PBSPXBodyConst;
begin
  Result:=@FCnst[High(FCnst)];   // last record = SS-wide trailer
end;

function TBSPXFile.GetPerturberCount: Int64;
begin
  Result:=Length(FPerturberIdx);
end;

function TBSPXFile.GetPerturberSoA: PPerturberSoA;
begin
  Result:=@FPerturberSoA;
end;

procedure TBSPXFile.PackPerturbers(const P: TState4DArrays);
// Compact the index-matched, hole-riddled node states P[node][desc] into the dense per-node SoA record (real
// perturbers only), for the force kernels. Call once per step -- right where the aP precompute runs. Rx[n][k]
// holds the k-th real perturber's x-position at node n; buffers are (re)sized only when the counts change.
var n, k, nn, np, pj: Int64;
begin
  nn:=Length(P);
  np:=Length(FPerturberIdx);
  with FPerturberSoA do
   begin
    Count:=np;
    if Length(Rx)<>nn then
     begin
      SetLength(Rx, nn); SetLength(Ry, nn); SetLength(Rz, nn);
      SetLength(Vx, nn); SetLength(Vy, nn); SetLength(Vz, nn); SetLength(GM, nn);
     end;
    for n:=0 to nn-1 do
     begin
      if Length(Rx[n])<>np then
       begin
        SetLength(Rx[n], np); SetLength(Ry[n], np); SetLength(Rz[n], np);
        SetLength(Vx[n], np); SetLength(Vy[n], np); SetLength(Vz[n], np); SetLength(GM[n], np);
       end;
      for k:=0 to np-1 do
       begin
        pj:=FPerturberIdx[k];
        Rx[n][k]:=P[n][pj].R.X;  Ry[n][k]:=P[n][pj].R.Y;  Rz[n][k]:=P[n][pj].R.Z;
        Vx[n][k]:=P[n][pj].V.X;  Vy[n][k]:=P[n][pj].V.Y;  Vz[n][k]:=P[n][pj].V.Z;
        GM[n][k]:=P[n][pj].GM;
       end;
     end;
   end;
end;

function TBSPXFile.Init(const FileName: string): Boolean;
var
  i, j, k, t: Int64;
  Stream: TFileStream;
  nameNonEmpty: Boolean;
  t0, t1: Double;
begin
  Close;
  Stream:=nil;
  t0:=NINF; t1:=PINF;
  try
   Stream:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
   if Stream.Seek(0, soFromBeginning)<>0 then raise Exception.Create('Error seeking file: '+ExtractFileName(FileName));
   if Stream.Read(FHdr, SizeOf(TBSPXHdr))<>SizeOf(TBSPXHdr) then raise Exception.Create('Error reading file: '+ExtractFileName(FileName));
   if FHdr.BSPXID<>BSPX_ID then raise Exception.Create('Invalid file ID: '+ExtractFileName(FileName));
   if FHdr.FileSize<>Stream.Size then raise Exception.Create('Invalid file size tag: '+ExtractFileName(FileName));
   if (FHdr.Data.Ptr<0) or (FHdr.Data.Ptr+FHdr.Data.Size>Stream.Size) or (FHdr.Data.Size<=0) then raise Exception.Create('Invalid data segment position/size: '+ExtractFileName(FileName));
   if (FHdr.Desc.Ptr<0) or (FHdr.Desc.Ptr+FHdr.Desc.Size>Stream.Size) or (FHdr.Desc.Size<=0) then raise Exception.Create('Invalid descriptor segment position/size: '+ExtractFileName(FileName));
   if (FHdr.Cnst.Ptr<0) or (FHdr.Cnst.Ptr+FHdr.Cnst.Size>Stream.Size) or (FHdr.Cnst.Size< 0) then raise Exception.Create('Invalid constants segment position/size: '+ExtractFileName(FileName));
   if (FHdr.Data.Len>=0) and (FHdr.Data.Num*FHdr.Data.Len<>FHdr.Data.Size) then raise Exception.Create('Invalid data segment structure: '+ExtractFileName(FileName));
   if FHdr.Desc.Num*FHdr.Desc.Len<>FHdr.Desc.Size then raise Exception.Create('Invalid descriptor segment structure: '+ExtractFileName(FileName));
   if FHdr.Cnst.Num*FHdr.Cnst.Len<>FHdr.Cnst.Size then raise Exception.Create('Invalid constants segment structure: '+ExtractFileName(FileName));
   if Stream.Seek(FHdr.Desc.Ptr, soFromBeginning)<>FHdr.Desc.Ptr then raise Exception.Create('Error seeking file: '+ExtractFileName(FileName));
   SetLength(FDesc, FHdr.Desc.Num);
   if Stream.Read(FDesc[0], FHdr.Desc.Size)<>FHdr.Desc.Size then raise Exception.Create('Error reading file: '+ExtractFileName(FileName));
   InitBodyConstants;   // allocate CelestialMechanics' canonical table before the reconciliation below reads it to
                        // fill holes (lazy: first file load, never at unit init -- this is BSPXFile's first need of it)
   // Constants section -> FCnst, guaranteed complete after this point (integrators then read with no checks):
   //  - absent (Num=0, legacy pre-const-section file): synthesize DE440 defaults per descriptor + trailer.
   //  - present & consistent (Num = Desc.Num+1): load as-is.
   //  - present but count-mismatched: a descriptor with no matching const record -> corrupted file.
   if FHdr.Cnst.Num=0 then
    begin
     SetLength(FCnst, FHdr.Desc.Num+1);
     for i:=0 to FHdr.Desc.Num-1 do SeedBodyConst(FDesc[i].TargetID, FCnst[i]);
     FCnst[FHdr.Desc.Num]:=DE440General;
    end
   else
    begin
     if FHdr.Cnst.Num<>FHdr.Desc.Num+1 then raise Exception.Create('Corrupted file (constants/descriptor count mismatch): '+ExtractFileName(FileName));
     if FHdr.Cnst.Len<>SizeOf(TBSPXBodyConst) then raise Exception.Create('Unsupported constants record length: '+ExtractFileName(FileName));
     if Stream.Seek(FHdr.Cnst.Ptr, soFromBeginning)<>FHdr.Cnst.Ptr then raise Exception.Create('Error seeking file: '+ExtractFileName(FileName));
     SetLength(FCnst, FHdr.Cnst.Num);
     if Stream.Read(FCnst[0], FHdr.Cnst.Size)<>FHdr.Cnst.Size then raise Exception.Create('Error reading file: '+ExtractFileName(FileName));
    end;
   // Reconcile the file's GM + figure data against the shared default table (CelestialMechanics.BodyConstants):
   // holes in the descriptors/const records are filled from the defaults; where the file brings VALID data it
   // wins and is written back, so the table keeps one version of each constant. Populated on first use here.
   FFileName:=FileName;
   InitBodyConstants;
   // A valid header GM (codes 0..10) overrides the shared default.
   for i:=Low(FHdr.GM) to High(FHdr.GM) do
    if ValidGM(FHdr.GM[i]) then
     begin k:=BodyConstIndex(i); if k>=0 then BodyConstants[k].GM:=FHdr.GM[i]; end;
   for i:=0 to Length(FDesc)-1 do
    begin
     if FDesc[i].Epoch0>t0 then t0:=FDesc[i].Epoch0;
     if FDesc[i].Epoch1<t1 then t1:=FDesc[i].Epoch1;
     t:=SizeOf(FDesc[i].TargetName);
     while (t>0) and ((FDesc[i].TargetName[t-1]=#0) or (FDesc[i].TargetName[t-1]=' ')) do t:=t-1;
     nameNonEmpty:=t>0;
     // Cnst is the logical home of the per-body GM and outranks the descriptor copy: a valid const GM wins.
     if (i<Length(FCnst)) and ValidGM(FCnst[i].GM) then FDesc[i].GM:=FCnst[i].GM;
     j:=FDesc[i].TargetID;
     k:=BodyConstIndex(j);
     if k<0 then
      begin   // body unknown to the table: no default -> neutralise any invalid GM, then APPEND it (one version)
       if not ValidGM(FDesc[i].GM) then FDesc[i].GM:=0.0;
       if (FDesc[i].GM<>0.0) or nameNonEmpty then
        begin
         k:=Length(BodyConstants); SetLength(BodyConstants, k+1);
         BodyConstants[k].NAIFCode:=j; BodyConstants[k].GM:=FDesc[i].GM;
         if nameNonEmpty then SetString(BodyConstants[k].Name, PAnsiChar(@FDesc[i].TargetName[0]), Integer(t));
        end;
      end
     else
      begin   // found: a valid file GM overwrites the default; anything invalid is replaced by the default
       if ValidGM(FDesc[i].GM) then BodyConstants[k].GM:=FDesc[i].GM else FDesc[i].GM:=BodyConstants[k].GM;
       // name: a non-empty file name updates the table; an empty one is back-filled from the table
       if nameNonEmpty then SetString(BodyConstants[k].Name, PAnsiChar(@FDesc[i].TargetName[0]), Integer(t))
       else
        begin
         FillChar(FDesc[i].TargetName, SizeOf(FDesc[i].TargetName), 0);
         t:=Length(BodyConstants[k].Name);
         if t>SizeOf(FDesc[i].TargetName) then t:=SizeOf(FDesc[i].TargetName);
         if t>0 then Move(BodyConstants[k].Name[1], FDesc[i].TargetName[0], t);
        end;
       // oblateness: a valid file figure (J2<>0) wins and is written back; a hole is filled from the default --
       // either a full J2 figure (oblate bodies) OR just the equatorial radius for near-spherical bodies whose
       // file Req is a hole (<=0). Without the Req case, non-oblate bodies (Mercury/Venus/Pluto/Charon/moons)
       // built without a PCK stay Req=0 and never draw a sphere.
       if i<Length(FCnst) then
        if FCnst[i].J2<>0.0 then
         begin
          BodyConstants[k].J2:=FCnst[i].J2; BodyConstants[k].J3:=FCnst[i].J3; BodyConstants[k].J4:=FCnst[i].J4;
          BodyConstants[k].Req:=FCnst[i].Req; BodyConstants[k].PoleRA:=FCnst[i].PoleRA; BodyConstants[k].PoleDec:=FCnst[i].PoleDec;
          BodyConstants[k].PoleW:=FCnst[i].PoleW; BodyConstants[k].PoleRARate:=FCnst[i].PoleRARate; BodyConstants[k].PoleDecRate:=FCnst[i].PoleDecRate; BodyConstants[k].PoleWRate:=FCnst[i].PoleWRate;
         end
        else if (BodyConstants[k].J2<>0.0) or (FCnst[i].Req<=0.0) then
         begin
          FCnst[i].J2:=BodyConstants[k].J2; FCnst[i].J3:=BodyConstants[k].J3; FCnst[i].J4:=BodyConstants[k].J4;
          FCnst[i].Req:=BodyConstants[k].Req; FCnst[i].PoleRA:=BodyConstants[k].PoleRA; FCnst[i].PoleDec:=BodyConstants[k].PoleDec;
          FCnst[i].PoleW:=BodyConstants[k].PoleW; FCnst[i].PoleRARate:=BodyConstants[k].PoleRARate; FCnst[i].PoleDecRate:=BodyConstants[k].PoleDecRate; FCnst[i].PoleWRate:=BodyConstants[k].PoleWRate;
         end;
      end;
    end;
   // Any invalid header GM (codes 0..10) falls back to the (now reconciled) default -> Hdr.GM[code] reads are safe.
   for i:=Low(FHdr.GM) to High(FHdr.GM) do
    if not ValidGM(FHdr.GM[i]) then
     begin k:=BodyConstIndex(i); if k>=0 then FHdr.GM[i]:=BodyConstants[k].GM; end;
   // Mirror the reconciled GM back into the per-body const records so Desc.GM and Cnst.GM always agree
   // (index DescCount is the SS-wide trailer, left untouched).
   for i:=0 to Length(FDesc)-1 do
    if i<Length(FCnst) then FCnst[i].GM:=FDesc[i].GM;
   // Seed the integrator's index-matched figure table (GOblateness) from the reconciled const records.
   for i:=0 to FHdr.Desc.Num-1 do
    if FCnst[i].J2<>0.0 then
     SetOblateness(FDesc[i].TargetID, FCnst[i].J2, FCnst[i].J3, FCnst[i].J4, FCnst[i].Req, FCnst[i].PoleRA, FCnst[i].PoleDec);
   // Dense index map of the real perturbers (GM>0). The raw state/descriptor array is index-matched and riddled
   // with non-perturbers (barycenters, TT-TDB, zero-GM bodies) at arbitrary positions; this lets the force code
   // -- and its future AVX2 kernels -- walk only genuine perturbers and pack them into a contiguous SoA buffer.
   SetLength(FPerturberIdx, 0);
   for i:=0 to Length(FDesc)-1 do
    if FDesc[i].GM > 0.0 then
     begin
      SetLength(FPerturberIdx, Length(FPerturberIdx)+1);
      FPerturberIdx[High(FPerturberIdx)]:=i;
     end;
   FHdr.Epoch0:=t0; FHdr.Epoch1:=t1;
   Result:=True;
  except on E: Exception do begin
   FError:=E.Message;
   Result:=False;
  end; end;
  if Stream<>nil then Stream.Free;
end;

function TBSPXFile.Open: Boolean;
// The coefficient data layout is fixed by the build (standard AoS/SoA terminology):
//   {$IFDEF AVX2}  AoS (array-of-structures) — one padded [X,Y,Z,W] TVec4D per Chebyshev coefficient; the
//                  AVX2 kernels load a whole 32-byte vector per step, so on load the file's native SoA data
//                  is interleaved (transposed) into per-coefficient vectors.
//   {$ELSE}        SoA (structure-of-arrays) — 3 contiguous per-component coefficient runs (all X, then all
//                  Y, then all Z) per record, the file's native layout read as-is; the Pascal path walks
//                  each run by the per-component stride Desc.RTArrayLen.
var
  i, j: Int64;
  FileStream: TFileStream;
  {$IFDEF AVX2}
  r, c, n, numcomp, numcoef, numrec, reclen: Int64;
  Vec4DArray: array of TVec4D;
  DArray: array of Int64;
  {$ENDIF}
begin
  Close;
  FileStream:=nil;
  try
   FileStream:=TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);
   FStream:=TAlignedMemoryStream.Create(32);
   {$IFDEF AVX2}
   j:=0;
   for i:=0 to Length(FDesc)-1 do
    begin
     FDesc[i].RTDataPtr:=j;
     FDesc[i].RTRecLen:=FDesc[i].NumCoef * SizeOf(TVec4D);
     FDesc[i].RTArrayLen:=FDesc[i].RTRecLen;
     FDesc[i].RTOffsetX:=0;
     if FDesc[i].NumComp>1 then FDesc[i].RTOffsetY:=  SizeOf(Double) else FDesc[i].RTOffsetY:=0;
     if FDesc[i].NumComp>2 then FDesc[i].RTOffsetZ:=2*SizeOf(Double) else FDesc[i].RTOffsetZ:=0;
     j:=j+FDesc[i].NumRec*FDesc[i].RTRecLen;
    end;
   FStream.SetSize(j);
   FStream.Seek(0, soFromBeginning);
   for i:=0 to Length(FDesc)-1 do
    begin
     numcomp:=FDesc[i].NumComp;
     numcoef:=FDesc[i].NumCoef;
     numrec:=FDesc[i].NumRec;
     reclen:=numcomp*numcoef;
     if FileStream.Seek(FDesc[i].DataPtr, soFromBeginning)<>FDesc[i].DataPtr then raise Exception.Create('Stream seek error.');
     SetLength(Vec4DArray, numcoef*numrec);
     SetLength(DArray, reclen*numrec);
     FillChar(Vec4DArray[0], Length(Vec4DArray)*SizeOf(TVec4D), 0);
     n:=Length(DArray)*SizeOf(Int64);
     if FileStream.Read(DArray[0], n)<>n then raise Exception.Create('Stream read error.');
     for r:=0 to numrec-1 do for j:=0 to numcoef-1 do for c:=0 to numcomp-1 do
      Vec4DArray[r*numcoef + j].ci[c] := DArray[r*reclen + c*numcoef + j];
     n:=Length(Vec4DArray)*SizeOf(TVec4D);
     if FStream.Write(Vec4DArray[0], n)<>n then raise Exception.Create('Stream write error.');
    end;
   {$ELSE}
   // Recompute the SoA stride fields for the unpadded per-component record layout the file stores (record
   // length = NumComp*NumCoef doubles; the per-component X|Y|Z runs and successive records are contiguous,
   // no padding). We do NOT trust the on-disk RTArrayLen/RTRecLen: an AoS-authored (AVX2-targeted) file
   // leaves them unset (zero), which would collapse C1=C2=C0 and misplace every body.
   j:=0;
   for i:=0 to Length(FDesc)-1 do
    begin
     FDesc[i].RTDataPtr:=j;
     FDesc[i].RTArrayLen:=FDesc[i].NumCoef*SizeOf(Double);       // byte stride between the X/Y/Z coeff arrays
     FDesc[i].RTRecLen:=FDesc[i].NumComp*FDesc[i].RTArrayLen;    // byte length of one full record
     FDesc[i].RTOffsetX:=0;
     if FDesc[i].NumComp>1 then FDesc[i].RTOffsetY:=  FDesc[i].RTArrayLen else FDesc[i].RTOffsetY:=0;
     if FDesc[i].NumComp>2 then FDesc[i].RTOffsetZ:=2*FDesc[i].RTArrayLen else FDesc[i].RTOffsetZ:=0;
     j:=j+FDesc[i].DataLen;
    end;
   if FileStream.Seek(FHdr.Data.Ptr, soFromBeginning)<>FHdr.Data.Ptr then raise Exception.Create('Stream seek error.');
   FStream.SetSize(FHdr.Data.Size);
   FStream.Seek(0, soFromBeginning);
   if FileStream.Read((PByte(FStream.Memory)+FStream.Position)^, FHdr.Data.Size)<>FHdr.Data.Size then raise Exception.Create('Stream read/write error.');
   FStream.Position:=FHdr.Data.Size;
   {$ENDIF}

   Result:=True;
  except on E: Exception do begin
   FError:=E.Message;
   Close;
   Result:=False;
  end; end;
  {$IFDEF AVX2}
  SetLength(DArray, 0);
  SetLength(Vec4DArray, 0);
  {$ENDIF}
  if FileStream<>nil then FileStream.Free;
end;

procedure TBSPXFile.Close;
begin
  try
   if FStream<>nil then FStream.Free;
  except
  end;
  try
   FStream:=nil;
  except
  end;
  FPerturberStateCenterID:=-1;
  SetLength(FPerturberOps, 0);
end;

procedure TBSPXFile.Finalize;
begin
  Close;
  try
   SetLength(FDesc, 0);
   SetLength(FCnst, 0);
  except
  end;
  try
   FillChar(FHdr, SizeOf(TBSPXHdr), 0);
   FFileName:='';
  except
  end;
end;

function TBSPXFile.FindDesc(TargetID, CenterID, RefID: Int64): Int64;
begin
  try
   Result:=Length(FDesc)-1;
   while (Result>=0) and ((FDesc[Result].TargetID<>TargetID) or (FDesc[Result].CenterID<>CenterID) or (FDesc[Result].RefID<>RefID)) do Result:=Result-1;
  except on E: Exception do begin
   FError:=E.Message;
   Result:=-1;
  end; end;
end;

function TBSPXFile.FindDesc(TargetID, CenterID: Int64): Int64;
begin
  try
   Result:=Length(FDesc)-1;
   while (Result>=0) and ((FDesc[Result].TargetID<>TargetID) or (FDesc[Result].CenterID<>CenterID)) do Result:=Result-1;
  except on E: Exception do begin
   FError:=E.Message;
   Result:=-1;
  end; end;
end;

function TBSPXFile.FindDesc(TargetID: Int64): Int64;
begin
  try
   Result:=Length(FDesc)-1;
   while (Result>=0) and (FDesc[Result].TargetID<>TargetID) do Result:=Result-1;
  except on E: Exception do begin
   FError:=E.Message;
   Result:=-1;
  end; end;
end;

function TBSPXFile.GetPerturberName(Code: Int64): AnsiString;
begin
  Result:=BodyName(Code);   // delegate to the shared default table (CelestialMechanics.BodyConstants)
end;

function TBSPXFile.GetPerturberGM(Code: Int64): Double;
begin
  Result:=BodyGM(Code);   // delegate to the shared default table (CelestialMechanics.BodyConstants)
end;

procedure TBSPXFile.InterpolateCore1(DescIndex: Int64; T: Double; R: PVec4D);
var
  Desc: PBSPXDesc;
  TargetRecPtr: Pointer;
  RecIndex: Int64;
  BlockMid, TScaled: Double;
begin
  Desc:=@FDesc[DescIndex];
  if (T<Desc.Epoch0) or (T>Desc.Epoch1) or (Desc.ValIntv<=0.0) or (Desc.Radius<=0.0) then
   raise Exception.Create(Format('Invalid time parameter (T=%g Epoch0=%g Epoch1=%g ValIntv=%g Radius=%g)', [T, Desc.Epoch0, Desc.Epoch1, Desc.ValIntv, Desc.Radius]));
  RecIndex:=Trunc((T-Desc.Epoch0)*Desc.InvRadius*0.5);   // ValIntv = 2*Radius, so 1/ValIntv = 0.5*InvRadius
  if (RecIndex<0) or (RecIndex>=Desc.NumRec) then
   raise Exception.Create(Format('Record index out of bounds (%d/%d)', [RecIndex, Desc.NumRec]));
  BlockMid:=Desc.T0+(RecIndex*Desc.ValIntv);
  TScaled:=(T-BlockMid)*Desc.InvRadius;
  TargetRecPtr:=Pointer(UIntPtr(FStream.Memory)+UIntPtr(Desc.RTDataPtr+RecIndex*Desc.RTRecLen));
  case Desc.NumComp of
   2, 3: EvaluateChebyshev3D(TargetRecPtr, Desc, R, TScaled);
   1:    EvaluateChebyshev1D(TargetRecPtr, Desc, @R.X, TScaled);
   else raise Exception.Create(Format('Invalid component count (%d)', [Desc.NumComp]));
  end;
end;

function TBSPXFile.Interpolate1(DescIndex: Int64; T: Double; R: PVec4D): Boolean;
begin
  try
   InterpolateCore1(DescIndex, T, R);
   Result:=True;
  except on E: Exception do begin
   FError:=E.Message;
   Result:=False;
  end; end;
end;

procedure TBSPXFile.InterpolateCore2(DescIndex: Int64; T: Double; S: PState4D);
var
  Desc: PBSPXDesc;
  TargetRecPtr: Pointer;
  RecIndex: Int64;
  BlockMid, TScaled: Double;
begin
  Desc:=@FDesc[DescIndex];
  if (T<Desc.Epoch0) or (T>Desc.Epoch1) or (Desc.ValIntv<=0.0) or (Desc.Radius<=0.0) then
   raise Exception.Create(Format('Invalid time parameter (T=%g Epoch0=%g Epoch1=%g ValIntv=%g Radius=%g)', [T, Desc.Epoch0, Desc.Epoch1, Desc.ValIntv, Desc.Radius]));
  RecIndex:=Trunc((T-Desc.Epoch0)*Desc.InvRadius*0.5);   // ValIntv = 2*Radius, so 1/ValIntv = 0.5*InvRadius
  if (RecIndex<0) or (RecIndex>=Desc.NumRec) then
   raise Exception.Create(Format('Record index out of bounds (%d/%d)', [RecIndex, Desc.NumRec]));
  BlockMid:=Desc.T0+(RecIndex*Desc.ValIntv);
  TScaled:=(T-BlockMid)*Desc.InvRadius;
  TargetRecPtr:=Pointer(UIntPtr(FStream.Memory)+UIntPtr(Desc.RTDataPtr+RecIndex*Desc.RTRecLen));
  case Desc.NumComp of
   2, 3: EvaluateChebyshev3D_Full(TargetRecPtr, Desc, S, TScaled);
   1:    EvaluateChebyshev1D(TargetRecPtr, Desc, @S.R.X, TScaled);
   else raise Exception.Create(Format('Invalid component count (%d)', [Desc.NumComp]));
  end;
end;

function TBSPXFile.Interpolate2(DescIndex: Int64; T: Double; S: PState4D): Boolean;
begin
  try
   InterpolateCore2(DescIndex, T, S);
   Result:=True;
  except on E: Exception do begin
   FError:=E.Message;
   Result:=False;
  end; end;
end;

function TBSPXFile.RelativeInterpolate2(TargetID, CenterID, RefID: Int64; T: Double; S: PState4D): Boolean;
// Returns TargetID's state relative to CenterID in reference frame RefID.
//   RefID=0  ICRF (J2000 equatorial)
//   RefID=1  J2000 ecliptical (= ICRF rotated by CEPS about the X axis)
//
// Descriptors in the file may be stored in different frames (FDesc[i].RefID).
// All intermediate arithmetic is done in ICRF; each step is normalised to ICRF
// before accumulation if its descriptor has RefID=1.  The single output rotation
// (if RefID=1 was requested) is applied once at the very end.
//
// Algorithm:
//   1. Identity short-circuit  (TargetID = CenterID → zero state)
//   2. Fast path               (exact descriptor Target→Center exists)
//   3. General path            (walk the tree, accumulate via LCA)
//        S = Σ steps(Target→LCA)  −  Σ steps(Center→LCA)
//   Tree depth in practice ≤ 4 (e.g. Moon→EarthBC→SSB); MAX_DEPTH=8 is safe.
const
  MAX_DEPTH = 8;
var
  TDesc, CDesc: array[0..MAX_DEPTH-1] of Int64;  // descriptor index per ancestor step
  TAnc,  CAnc:  array[0..MAX_DEPTH]   of Int64;  // ancestor ID list; [0]=start body
  TLen, CLen: Int64;
  LCA_T, LCA_C: Int64;
  i, j, di: Int64;
  Tmp: TState4D;
  EclToICRF, ICRFToEcl: TMat4D;
begin
  try
   if (RefID < 0) or (RefID > 1) then
    raise Exception.Create(Format('Invalid reference frame (%d): only 0 (ICRF) and 1 (J2000 ecliptical) are supported', [RefID]));

   // Precompute both rotation matrices (cheap; avoids repeated trig in loops)
   EclToICRF := GetRotMat4D( CEPS, 1.0, 0.0, 0.0);   // ecliptical → ICRF
   ICRFToEcl := GetRotMat4D(-CEPS, 1.0, 0.0, 0.0);   // ICRF → ecliptical

   // --- 1. Identity ---
   if TargetID = CenterID then
    begin
     FillChar(S^, SizeOf(TState4D), 0);
     S.R.W := 1.0; S.Epoch := T;
     S.GM  := GetPerturberGM(TargetID);
     Result := True; Exit;
    end;

   // --- 2. Fast path: exact (Target→Center) descriptor ---
   di := FindDesc(TargetID, CenterID);
   if di >= 0 then
    begin
     InterpolateCore2(di, T, S);
     S.R.W := 1.0; S.V.W := 0.0; S.Epoch := T; S.GM := FDesc[di].GM;
     // transform from the descriptor's stored frame to the requested output frame
     if FDesc[di].RefID <> RefID then
      begin
       if FDesc[di].RefID = 0 then begin S.R := S.R * ICRFToEcl; S.V := S.V * ICRFToEcl; end
                               else begin S.R := S.R * EclToICRF; S.V := S.V * EclToICRF; end;
      end;
     Result := True; Exit;
    end;

   // --- 3. General path ---

   // Target chain: TAnc[0]=TargetID, TAnc[1]=its parent, …, TAnc[TLen]=chain root
   TLen := 0; TAnc[0] := TargetID;
   while TLen < MAX_DEPTH do
    begin
     di := FindDesc(TAnc[TLen]);
     if di < 0 then Break;
     TDesc[TLen] := di;
     TAnc[TLen+1] := FDesc[di].CenterID;
     Inc(TLen);
    end;

   // Center chain: CAnc[0]=CenterID, CAnc[1]=its parent, …
   CLen := 0; CAnc[0] := CenterID;
   while CLen < MAX_DEPTH do
    begin
     di := FindDesc(CAnc[CLen]);
     if di < 0 then Break;
     CDesc[CLen] := di;
     CAnc[CLen+1] := FDesc[di].CenterID;
     Inc(CLen);
    end;

   // Find shallowest LCA: first TAnc[i] that also appears in CAnc[j]
   LCA_T := -1; LCA_C := -1;
   for i := 0 to TLen do
    begin
     for j := 0 to CLen do
      if TAnc[i] = CAnc[j] then
       begin LCA_T := i; LCA_C := j; Break; end;
     if LCA_T >= 0 then Break;
    end;
   if LCA_T < 0 then
    raise Exception.Create(Format('No common ancestor found between target %d and center %d', [TargetID, CenterID]));

   // Accumulate in ICRF; normalise each step if its descriptor is stored in ecliptical
   FillChar(S^, SizeOf(TState4D), 0);
   for i := 0 to LCA_T - 1 do
    begin
     InterpolateCore2(TDesc[i], T, @Tmp);
     if FDesc[TDesc[i]].RefID = 1 then
      begin Tmp.R := Tmp.R * EclToICRF; Tmp.V := Tmp.V * EclToICRF; end;
     S.R := S.R + Tmp.R;
     S.V := S.V + Tmp.V;
    end;
   for i := 0 to LCA_C - 1 do
    begin
     InterpolateCore2(CDesc[i], T, @Tmp);
     if FDesc[CDesc[i]].RefID = 1 then
      begin Tmp.R := Tmp.R * EclToICRF; Tmp.V := Tmp.V * EclToICRF; end;
     S.R := S.R - Tmp.R;
     S.V := S.V - Tmp.V;
    end;

   S.R.W := 1.0; S.V.W := 0.0; S.Epoch := T;
   S.GM  := GetPerturberGM(TargetID);

   // Single output rotation from ICRF to the requested frame
   if RefID = 1 then
    begin S.R := S.R * ICRFToEcl; S.V := S.V * ICRFToEcl; end;

   Result := True;
  except on E: Exception do begin
   FError := E.Message;
   Result := False;
  end; end;
end;

function TBSPXFile.BatchInterpolate1(T: Double; Output: TState4DArray): Boolean;
var
  i, n: Int64;
  HasError: Boolean;
begin
  try
   n:=Length(FDesc);
   HasError:=False;
   for i:=0 to n-1 do
   try
    InterpolateCore1(i, T, @Output[i].R);
    Output[i].Epoch:=T;
   except on E: Exception do begin
    HasError:=True;
    FError:=E.Message;
   end; end;
   Result:=not HasError;
  except on E: Exception do begin
   FError:=E.Message;
   Result:=False;
  end; end;
end;

function TBSPXFile.BatchInterpolate2(T: Double; Output: TState4DArray): Boolean;
var
  i, n: Int64;
  HasError: Boolean;
begin
  try
   n:=Length(FDesc);
   HasError:=False;
   for i:=0 to n-1 do
   try
    InterpolateCore2(i, T, @Output[i]);
    Output[i].Epoch:=T;
   except on E: Exception do begin
    HasError:=True;
    FError:=E.Message;
   end; end;
   Result:=not HasError;
  except on E: Exception do begin
   FError:=E.Message;
   Result:=False;
  end; end;
end;

function TBSPXFile.MultiBatchInterpolate1(const T: TDynDoubleArray; Output: TState4DArrays): Boolean;
var
  i, k, n, m: Int64;
  HasError: Boolean;
begin
  try
   m := Length(T);
   n := Length(FDesc);
   HasError := False;
   for k := 0 to m-1 do
    for i := 0 to n-1 do
    try
     InterpolateCore1(i, T[k], @Output[k][i].R);
     Output[k][i].Epoch := T[k];
    except on E: Exception do begin
     HasError := True;
     FError := E.Message;
    end; end;
   Result := not HasError;
  except on E: Exception do begin
   FError := E.Message;
   Result := False;
  end; end;
end;

function TBSPXFile.MultiBatchInterpolate2(const T: TDynDoubleArray; Output: TState4DArrays): Boolean;
// Descriptor-outer / node-inner so the per-record setup (BlockMid, TargetRecPtr) can be hoisted: the
// m node-times of one integrator step almost always fall in the SAME Chebyshev record, so that setup
// is recomputed only when RecIndex actually changes. Output values and error semantics are identical
// to the naive InterpolateCore2 loop. The eval dispatch is inlined here (that is what enables the
// hoist) and MUST be kept in sync with InterpolateCore2 if the core dispatch ever changes.
var
  i, k, n, m: Int64;
  Desc: PBSPXDesc;
  RecIndex, lastRec: Int64;
  Tk, BlockMid, TScaled: Double;
  TargetRecPtr: Pointer;
  HasError: Boolean;
begin
  try
   m := Length(T);
   n := Length(FDesc);
   HasError := False;
   BlockMid := 0.0; TargetRecPtr := nil;              // only ever read after a lastRec-guarded assignment
   for i := 0 to n-1 do
    begin
     Desc := @FDesc[i];
     lastRec := -1;                                    // force the record setup on this descriptor's first node
     for k := 0 to m-1 do
     try
      Tk := T[k];
      if (Tk<Desc.Epoch0) or (Tk>Desc.Epoch1) or (Desc.ValIntv<=0.0) or (Desc.Radius<=0.0) then
       raise Exception.Create(Format('Invalid time parameter (T=%g Epoch0=%g Epoch1=%g ValIntv=%g Radius=%g)', [Tk, Desc.Epoch0, Desc.Epoch1, Desc.ValIntv, Desc.Radius]));
      RecIndex:=Trunc((Tk-Desc.Epoch0)*Desc.InvRadius*0.5);   // ValIntv = 2*Radius, so 1/ValIntv = 0.5*InvRadius
      if (RecIndex<0) or (RecIndex>=Desc.NumRec) then
       raise Exception.Create(Format('Record index out of bounds (%d/%d)', [RecIndex, Desc.NumRec]));
      if RecIndex <> lastRec then                       // *** hoist: record-level setup only on a record change
       begin
        BlockMid:=Desc.T0+(RecIndex*Desc.ValIntv);
        TargetRecPtr:=Pointer(UIntPtr(FStream.Memory)+UIntPtr(Desc.RTDataPtr+RecIndex*Desc.RTRecLen));
        lastRec:=RecIndex;
       end;
      TScaled:=(Tk-BlockMid)*Desc.InvRadius;
      case Desc.NumComp of
       2, 3: EvaluateChebyshev3D_Full(TargetRecPtr, Desc, @Output[k][i], TScaled);
       1:    EvaluateChebyshev1D(TargetRecPtr, Desc, @Output[k][i].R.X, TScaled);
       else raise Exception.Create(Format('Invalid component count (%d)', [Desc.NumComp]));
      end;
      Output[k][i].Epoch := Tk;
     except on E: Exception do begin
      HasError := True;
      FError := E.Message;
     end; end;
    end;
   Result := not HasError;
  except on E: Exception do begin
   FError := E.Message;
   Result := False;
  end; end;
end;

procedure TBSPXFile.SetPerturberStateCenterID(Value: Int64);
var
  i, j, k, n: Int64;
  ti, ci, TLen, CLen: Int64;
  TAnc, CAnc: array[0..7] of Int64;
  TDesc, CDesc: array[0..7] of Int64;
begin
  FPerturberStateCenterID := Value;
  n := Length(FDesc);
  SetLength(FPerturberOps, n);
  for i := 0 to n-1 do FPerturberOps[i].AddCount := -1;
  if n = 0 then Exit;

  // Build center chain once
  CLen := 0;
  CAnc[0] := Value;
  while CLen < 7 do
   begin
    j := -1;
    for k := 0 to n-1 do
     if (FDesc[k].TargetID = CAnc[CLen]) and (FDesc[k].NumComp = 3) then
      begin j := k; Break; end;
    if j < 0 then Break;
    CDesc[CLen] := j;
    Inc(CLen);
    CAnc[CLen] := FDesc[j].CenterID;
   end;

  for i := 0 to n-1 do
   begin
    // TargetID 1..9 are the planet barycenters: reconstruct their R/V too (position-only entries for
    // AccForm centres / re-centring). Their GM is zeroed in the replay (Get[Multi]PerturberStates), so the
    // force still ignores them. SSB (0, no descriptor) and massless bodies (GM=0) stay out.
    if (FDesc[i].NumComp <> 3) or (FDesc[i].TargetID < 1) or (FDesc[i].GM = 0.0) then Continue;

    // Build target ancestor chain
    TLen := 0;
    TAnc[0] := FDesc[i].TargetID;
    while TLen < 7 do
     begin
      j := -1;
      for k := 0 to n-1 do
       if (FDesc[k].TargetID = TAnc[TLen]) and (FDesc[k].NumComp = 3) then
        begin j := k; Break; end;
      if j < 0 then Break;
      TDesc[TLen] := j;
      Inc(TLen);
      TAnc[TLen] := FDesc[j].CenterID;
     end;

    // Find shallowest common ancestor
    ti := -1; ci := -1;
    for j := 0 to TLen do
     begin
      if ti >= 0 then Break;
      for k := 0 to CLen do
       if TAnc[j] = CAnc[k] then
        begin ti := j; ci := k; Break; end;
     end;
    if ti < 0 then Continue; // disconnected — leave AddCount=-1

    // Store the precomputed op table entry for this body
    FPerturberOps[i].AddCount := ti;
    FPerturberOps[i].SubCount := ci;
    for j := 0 to ti-1 do FPerturberOps[i].AddIdx[j] := TDesc[j];
    for j := 0 to ci-1 do FPerturberOps[i].SubIdx[j] := CDesc[j];
   end;
end;

function TBSPXFile.GetPerturberStates(Input, Output: TState4DArray): Boolean;
// Reconstruct every body's state relative to PerturberStateCenterID by replaying the precomputed
// FPerturberOps table (the TargetID->CenterID tree walk is done ONCE, in SetPerturberStateCenterID).
// The integrators always use SSB (PerturberStateCenterID = 0), for which the table is adds-only
// (SubCount = 0 -- no descriptor has TargetID 0, so the common ancestor is SSB for every body). The
// general any-centre capability (the subtract branch) is retained deliberately: it is not needed for
// integration, but lets this yield every body's state relative to an arbitrary body -- e.g. a
// body-relative view or analysis. Cheap either way (a few vector adds/subtracts per body).
var
  i, j, n: Int64;
begin
  try
   n := Length(FDesc);
   if n = 0 then raise Exception.Create('GetPerturberStates: no descriptors loaded');
   if Length(Input) = 0 then raise Exception.Create('GetPerturberStates: Input array is empty');
   if FPerturberStateCenterID < 0 then raise Exception.Create('GetPerturberStates: PerturberStateCenterID not set');

   FillChar(Output[0], n * SizeOf(TState4D), 0);

   for i := 0 to n-1 do
    begin
     if FPerturberOps[i].AddCount < 0 then Continue;
     for j := 0 to FPerturberOps[i].AddCount-1 do
      begin
       Output[i].R := Output[i].R + Input[FPerturberOps[i].AddIdx[j]].R;
       Output[i].V := Output[i].V + Input[FPerturberOps[i].AddIdx[j]].V;
      end;
     for j := 0 to FPerturberOps[i].SubCount-1 do
      begin
       Output[i].R := Output[i].R - Input[FPerturberOps[i].SubIdx[j]].R;
       Output[i].V := Output[i].V - Input[FPerturberOps[i].SubIdx[j]].V;
      end;
     if FDesc[i].TargetID < 10 then Output[i].GM := 0.0    // barycenters: position only, no gravitating mass (keeps them out of the force)
                                else Output[i].GM := FDesc[i].GM;
     Output[i].Epoch := Input[i].Epoch;
    end;

   Result := True;
  except on E: Exception do begin
   FError := E.Message;
   Result := False;
  end; end;
end;

function TBSPXFile.GetMultiPerturberStates(Input, Output: TState4DArrays): Boolean;
var
  i, j, k, n, m: Int64;
  HasError: Boolean;
begin
  try
   n := Length(FDesc);
   if n = 0 then raise Exception.Create('GetMultiPerturberStates: no descriptors loaded');
   if FPerturberStateCenterID < 0 then raise Exception.Create('GetMultiPerturberStates: PerturberStateCenterID not set');
   m := Length(Input);
   HasError := False;
   for k := 0 to m-1 do
   try
    if Length(Input[k]) = 0 then raise Exception.Create('GetMultiPerturberStates: Input[' + IntToStr(k) + '] is empty');
    FillChar(Output[k][0], n * SizeOf(TState4D), 0);
    for i := 0 to n-1 do
     begin
      if FPerturberOps[i].AddCount < 0 then Continue;
      for j := 0 to FPerturberOps[i].AddCount-1 do
       begin
        Output[k][i].R := Output[k][i].R + Input[k][FPerturberOps[i].AddIdx[j]].R;
        Output[k][i].V := Output[k][i].V + Input[k][FPerturberOps[i].AddIdx[j]].V;
       end;
      for j := 0 to FPerturberOps[i].SubCount-1 do
       begin
        Output[k][i].R := Output[k][i].R - Input[k][FPerturberOps[i].SubIdx[j]].R;
        Output[k][i].V := Output[k][i].V - Input[k][FPerturberOps[i].SubIdx[j]].V;
       end;
      if FDesc[i].TargetID < 10 then Output[k][i].GM := 0.0    // barycenters: position only, no gravitating mass (keeps them out of the force)
                                 else Output[k][i].GM := FDesc[i].GM;
      Output[k][i].Epoch := Input[k][i].Epoch;
     end;
   except on E: Exception do begin
    HasError := True;
    FError := E.Message;
   end; end;
   Result := not HasError;
  except on E: Exception do begin
   FError := E.Message;
   Result := False;
  end; end;
end;

//------------------------------------------------------------------------------
// standalone functions
//------------------------------------------------------------------------------

function GetCorrectedGM(GM_center, GM_target: Double; isBarycentric: Boolean): Double;
// This is the GM value the TState4D record must contain if you want to compute barycentric osculating elements
// for a massive body which itself is contributing to the barycentric GM value of the system
// formula = GMeffective = GMtotal * (1-GMtarget/GMtotal)^3
begin
  if IsBarycentric then
   begin
    Result:=1-GM_target/GM_center;
    Result:=(Result*Result)*(Result*GM_center);
   end else Result:=GM_target+GM_center;
end;

procedure Osculate(S: PState4D);
// Computes osculating elements from S.R (position), S.V (velocity) and S.GM.
// Reference frame: angles measured from X axis and XY plane.
// Circular (e=0): Peri=Node, Anom=argument of latitude. Equatorial (i=0): Node=0.
const
  SMALL = 1e-20;
var
  R, V   : TVec4D;
  h      : TVec4D;    // specific angular momentum R × V
  eVec   : TVec4D;    // eccentricity vector
  rMag, v2 : Double;  // |R|, |V|²
  hMag   : Double;    // |h|
  NX, NY : Double;    // node vector K × h = (-h.Y, h.X, 0)
  NMag   : Double;
  eMag   : Double;
  rdotv  : Double;    // R · V
  cv     : Double;
begin
  R := S.R;
  V := S.V;

  h    := R xor V;        // h = R × V  (specific angular momentum)
  hMag := h.Magnitude3D;

  rMag  := R.Magnitude3D;
  v2    := V.SqrMag3D;
  rdotv := R or V;        // R · V

  // Eccentricity vector: e = ((v² - GM/r)·R - (R·V)·V) / GM
  eVec := (R * (v2 - S.GM / rMag) - V * rdotv) * (1.0 / S.GM);
  eMag := eVec.Magnitude3D;
  S.e  := eMag;

  // Periapsis distance — universal formula for all conic sections
  S.q := (hMag * hMag) / (S.GM * (1.0 + eMag));

  // Inclination: i = arccos(h.Z / |h|)
  cv := h.Z / hMag;
  if cv > 1.0 then cv := 1.0 else if cv < -1.0 then cv := -1.0;
  S.Incl := ArcCos(cv);

  // Ascending node vector N = K × h = (-h.Y, h.X, 0)
  NX   := -h.Y;
  NY   :=  h.X;
  NMag := Sqrt(NX * NX + NY * NY);

  // Longitude of ascending node Ω
  if NMag < SMALL * hMag then
    S.Node := 0.0   // equatorial: Ω undefined, set to 0
  else
  begin
    cv := NX / NMag;
    if cv > 1.0 then cv := 1.0 else if cv < -1.0 then cv := -1.0;
    S.Node := ArcCos(cv);
    if NY < 0.0 then S.Node := TWOPI - S.Node;
  end;

  // Argument of periapsis ω and true anomaly ν
  if eMag < SMALL then
  begin
    // Circular: periapsis at ascending node by convention; Anom = argument of latitude
    S.Peri := S.Node;
    if NMag < SMALL * hMag then
    begin
      // Circular equatorial: measure from X axis
      S.Anom := ArcTan2(R.Y, R.X);
      if S.Anom < 0.0 then S.Anom := S.Anom + TWOPI;
    end
    else
    begin
      // Circular inclined: argument of latitude from ascending node
      // cos(u) ∝ N·R,  sin(u) ∝ (h×N)·R / |h|
      cv := NX * R.X + NY * R.Y;   // N · R  (N.Z = 0)
      S.Anom := ArcTan2(
        (-h.Z*NY)*R.X + (h.Z*NX)*R.Y + (h.X*NY - h.Y*NX)*R.Z,
        cv * hMag);
      if S.Anom < 0.0 then S.Anom := S.Anom + TWOPI;
    end;
  end
  else
  begin
    if NMag < SMALL * hMag then
    begin
      // Equatorial: measure ω from X axis via eccentricity vector directly
      S.Peri := ArcTan2(eVec.Y, eVec.X);
      if S.Peri < 0.0 then S.Peri := S.Peri + TWOPI;
    end
    else
    begin
      // General: cos(ω) = (N · eVec) / (|N| · e); quadrant from eVec.Z sign
      cv := (NX * eVec.X + NY * eVec.Y) / (NMag * eMag);
      if cv > 1.0 then cv := 1.0 else if cv < -1.0 then cv := -1.0;
      S.Peri := ArcCos(cv);
      if eVec.Z < 0.0 then S.Peri := TWOPI - S.Peri;
    end;

    // True anomaly ν: cos(ν) = (eVec · R) / (e · |R|); quadrant from sign of R·V
    cv := (eVec or R) / (eMag * rMag);
    if cv > 1.0 then cv := 1.0 else if cv < -1.0 then cv := -1.0;
    S.Anom := ArcCos(cv);
    if rdotv < 0.0 then S.Anom := TWOPI - S.Anom;
  end;
end;

function BSPXTimeStr(T: Double; Decimals: Int64): string;
// T = TDB seconds since J2000 (continuous time scale, no leapseconds etc)
var
  JulianDate: Double;
  JDAjusted: Double;
  J: Int64;
  F: Double;
  f_param, e, g, h: Int64;
  ComputedDay: Int64;
  ComputedMonth: Integer;
  ComputedYear: Integer;
  CombinedDay: Double;
  FormatSettings: TFormatSettings;
  FormatStr: string;
begin
  // 1. Convert SPICE seconds to standard Julian Date
  JulianDate := STANDARD_EPOCH + (T / 86400.0);

  // 2. Safeguard rounding carry-overs (e.g., .9999 rounding up to 1.000)
  // Shift by half of the smallest decimal unit before breaking down components
  if Decimals > 0 then
    JulianDate := JulianDate + (0.5 / Power(10, Decimals));

  // 3. Shift to midnight-start and split integer and fraction
  JDAjusted := JulianDate + 0.5;
  J := Floor(JDAjusted);
  F := JDAjusted - J;

  // 4. Fliegel-Van Flandern Algorithm
  f_param := J + 1401 + FloorDiv(FloorDiv(4 * J + 274277, 146097) * 3, 4) - 38;
  e := 4 * f_param + 3;
  g := FloorDiv(MathMod(e, 1461), 4);
  h := 5 * g + 2;

  // 5. Extract components
  ComputedDay   := FloorDiv(MathMod(h, 153), 5) + 1;
  ComputedMonth := MathMod(FloorDiv(h, 153) + 2, 12) + 1;
  ComputedYear  := FloorDiv(e, 1461) - 4716 + FloorDiv(14 - ComputedMonth, 12);

  // 6. Combine integer day and remaining fraction
  CombinedDay := ComputedDay + F;

  // Truncate if user wants 0 decimals, otherwise add rounding mitigation
  if Decimals <= 0 then
    CombinedDay := Int(CombinedDay);

  // 7. Format string safely without locale interference (ensures '.' separator)
  FormatSettings := TFormatSettings.Create('en-US');

  // Build a formatting pattern like "00.000" based on requested decimals
  if Decimals > 0 then
    FormatStr := '00.' + StringOfChar('0', Decimals)
  else
    FormatStr := '00';

  // Build the final output string: YYYY-MM-DD.frac
  // %0.4d handles negative years correctly (e.g., -0005) or regular padding
  Result := Format('%0.4d-%0.2d-', [ComputedYear, ComputedMonth], FormatSettings) +
            FormatFloat(FormatStr, CombinedDay, FormatSettings);
end;

function StrBSPXTime(const S: string): Double;
// Inverse of BSPXTimeStr: parse a proleptic-Gregorian '[-]YYYY-MM-DD[.frac]' string (frac = fraction of the day
// past midnight -- the layout BSPXTimeStr emits) back to TDB seconds since J2000. Floor-division date math, so it
// round-trips BSPXTimeStr across the whole DE441 span, deep negative years included. Raises on malformed input.
var
  p, sgn, mo, dy: Integer;
  y, a, yy, m, jdn: Int64;
  frac: Double;
  ds: string;
  parts: TArray<string>;
begin
  ds := Trim(S);
  p := Pos('.', ds);
  if p > 0 then begin frac := StrToFloat('0' + Copy(ds, p, Length(ds)), TFormatSettings.Invariant); ds := Copy(ds, 1, p-1); end
           else frac := 0.0;
  sgn := 1;
  if (ds <> '') and (ds[1] = '-') then begin sgn := -1; Delete(ds, 1, 1); end;   // negative (BCE) year, e.g. '-17000-01-01'
  parts := ds.Split(['-']);
  if Length(parts) <> 3 then raise Exception.Create('Invalid Gregorian date: ' + S);
  y := sgn * StrToInt(parts[0]); mo := StrToInt(parts[1]); dy := StrToInt(parts[2]);
  // Proleptic-Gregorian calendar date -> Julian Day Number (noon); JDN-0.5+frac = JD; then to TDB seconds past
  // J2000. Mirror of BSPXTimeStr's constants (2451545.0, 86400.0).
  a   := FloorDiv(14 - mo, 12);
  yy  := y + 4800 - a;
  m   := mo + 12*a - 3;
  jdn := dy + FloorDiv(153*m + 2, 5) + 365*yy + FloorDiv(yy, 4) - FloorDiv(yy, 100) + FloorDiv(yy, 400) - 32045;
  Result := ((jdn - 0.5 + frac) - 2451545.0) * 86400.0;
end;

function BSPXStr(const S: array of AnsiChar; MaxLength: Int64): string;
var
  Len, i: Int64;
begin
  Len := High(S) + 1;
  if Len > MaxLength then Len := MaxLength;
  i := 0;
  while (i < Len) and (S[i] <> #0) do Inc(i);
  Len := i;
  SetLength(Result, Len);
  for i := 0 to Len - 1 do Result[i + 1] := Char(S[i]);
end;

function DE440General: TBSPXBodyConst;
// SS-wide trailer defaults sourced from the single truth (CelestialMechanics), not duplicated literals.
// A non-DE440 build still overrides AU/CLIGHT/BETA/GAMMA from header.4xx (SPKMerge Stage B) and GMS from Hdr.GM[10].
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.AU     := AU_KM;                              // km
  Result.CLIGHT := CLIGHT;                             // km/s
  Result.BETA   := 1.0;                                // PPN (GR: beta=1)
  Result.GAMMA  := 1.0;                                // PPN (GR: gamma=1)
  Result.GMS    := GM_SUN;                             // km^3/s^2 (Sun)
  Result.POLTIM := STANDARD_EPOCH;                     // J2000 pole epoch
end;

procedure SeedBodyConst(BodyID: Int64; out C: TBSPXBodyConst);
// Seed a per-body const record from the shared default table (CelestialMechanics.BodyConstants): GM +
// figure (Req/J2/J3/J4/pole RA/Dec), the exact fields the table holds. Everything else (PoleW, rates,
// reserved) stays 0. Bodies unknown to the table leave C fully zeroed. Replaces the former DE440BodyDefault
// hardcoded GM table -- GM and figure now live in exactly one place (BodyConstants).
var bc: PBodyConstant;
begin
  FillChar(C, SizeOf(C), 0);
  bc := BodyConst(BodyID);
  if bc<>nil then
   begin
    C.GM:=bc.GM; C.Req:=bc.Req;
    C.J2:=bc.J2; C.J3:=bc.J3; C.J4:=bc.J4;
    C.PoleRA:=bc.PoleRA; C.PoleDec:=bc.PoleDec; C.PoleW:=bc.PoleW;
    C.PoleRARate:=bc.PoleRARate; C.PoleDecRate:=bc.PoleDecRate; C.PoleWRate:=bc.PoleWRate;
   end;
end;

end.
