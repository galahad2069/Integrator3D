unit JPLEphemeris;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math, System.UITypes,
  Vcl.Dialogs, RSoftTypes64;

const
  MIN_NUMCONST = 10;

  PINF = 1/0; NINF = -1/0;
  GAUSS    = 0.01720209895;
  GAUSS2   = 0.0002959122082855911025; // = GAUSS^2

  ROTANGVEL        = 6.30038736; // rotational angular velocity of the Earth rad/day
  FLAT2            = 0.9933056213348961; // (1-F)^2 where F=ellipsoidal flattening factor of the Earth
  CAU              = 149597870.691;
  CEARTHRAD        = 6378.140;           //equatorial radius of the Earth
  CCLIGHTKMS       = 299792.458;
  CEMRAT           = 81.3005677535353;
  CGMEARTHAU       = 8.99701134675054100E-10;
  LB               = 1.550519768e-8;
  TDB0             = -7.5810185185185185185185185185185e-10;
  TCB0             = 2443144.5003725;
  TT_UTC_DIFF_BASE = 32.184;

type

  TxVector = array[0..2] of Extended;
  PxVector = ^TxVector;

  THdrStr = array[0..7] of AnsiChar;
  THdrRec = packed record
   case Integer of
   0: (CNAME, CVALUE: THdrStr);
   1: (I32NAME0, I32NAME1, I32VALUE, I32DUMMY: Int32);
   2: (I64NAME, I64VALUE: Int64);
   3: (DNAME, DVALUE: Double);
  end;
  PHdrRec = ^THdrRec;

  THdrID = array[0..47] of AnsiChar;
  THdr = packed record
   ID: THdrID;
   Constants: array[0..67108859] of THdrRec;
  end;
  PHdr = ^THdr;

  TItemName = array[0..15] of AnsiChar;
  TTabRec = packed record
   NAME: TItemName;
   OFFS, NCOEF, NGRAN, NCOMP: Int32;
  end;
  PTabRec = ^TTabRec;

  TTable = array[0..44739241] of TTabRec;
  PTable = ^TTable;

  TLastCompRec = record T0, T1: Extended; F0, F1: TxVector; end;
  TLastCompTbl = array[0..0] of TLastCompRec;
  PLastCompTbl = ^TLastCompTbl;

  TPoleAngles = array[0..1] of Extended;
  PPoleAngles = ^TPoleAngles;

  TCollTable = record
   Names: array[0..9, 1..16] of AnsiChar;
   ImpactIndex: Int32;
   Limits: array[0..9] of Extended; // in km units
   MinDist: array[0..9] of Extended;
   MinDistT: array[0..9] of Extended;
  end;
  PCollTable = ^TCollTable;

  TPertTable = record
   Initialized: Boolean;
   Indexes: array[0..9] of Int32;
   GM: array[0..9] of Extended;
   LimitCheck: Boolean;
   Limits: array[0..9] of Extended; // in AU units; computed internally
   Coll: TCollTable;
  end;
  PPertTable = ^TPertTable;

function InitEphemeris(DENUM: Int32): Boolean;
function FindConstant(Rec: PHdrRec): Boolean;
function GetName(Target: Int32): PChar;
function GetIndex(Target: PChar): Integer;
function InitPertTable(aPertTable: PPertTable): Boolean;
function DecodeJulian(TJD: Double; var Year, Month, Day: Int64; var FracDay: Double): Boolean;
function TJDStr(TJD: Double; Decimals: Int64): string;

var
  F: TFileStream;
  Header: PHdr;
  Table: PTable;
  Data: PDoubleArray;
  DEInit: Int32;
  FDir, FName: string;
  HeaderLoaded, TableLoaded: Boolean;
  FSize, NumConst, NumItems, NumRec, NumLRec, NumCoef, RecLen, ValIntv: Int32;
  EMBIdx, MoonIdx, SunIdx, NutIdx, LibIdx: Int32;
  OData: Int32;
  Epoch0, Epoch1, LEpoch0, LEpoch1: Double;
  RKSS, RKE0, RKE1: Extended;
  LastComp: PLastCompTbl;
  //Options: Cardinal;
  AUKM, AUM, AUKMGAUSS,
  EARTHRAD,
  CLIGHTMS, CLIGHTKMS, CLIGHTKMDAY, CLIGHTAUDAY,
  EMRAT, EMBCOEF, ONEMINUSEMBCOEF,
  GMSUNAU, GMSUNKM, GMSUNM,
  GMEARTHAU, GMEARTHKM, GMEARTHM: Extended;
  CPO: TPoleAngles;
  STDOBL: Extended;  // mean obliquity at standard epoch
  gPertTable: TPertTable;

  RAD2SEC:    Extended = 13750.987083139757010431557155385;
  RAD2ARCSEC: Extended = 206264.80624709635515647335733078;
  RAD2MAS:    Extended = 206264806.24709635515647335733078;
  RAD201MAS:  Extended = 2062648062.4709635515647335733078;
  RAD2UAS:    Extended = 206264806247.09635515647335733078;
  RAD201UAS:  Extended = 2062648062470.9635515647335733078;
  DEG2RAD:    Extended = 1.7453292519943295769236907684886e-2;
  TWOPI:      Extended = 6.283185307179586476925286766559;
  PIPER2:     Extended = 1.5707963267948966192313216916398;
  TWO:        Extended = 2;
  SQRT2PER2:  Extended = 0.70710678118654752440084436210485;
  SQRT3PER2:  Extended = 0.86602540378443864676372317075294;

  TableNames: array[0..15] of TItemName=(
  'Mercury         ',
  'Venus           ',
  'Earth-Moon BC   ',
  'Mars            ',
  'Jupiter BC      ',
  'Saturn BC       ',
  'Uranus BC       ',
  'Neptune BC      ',
  'Pluto BC        ',
  'Moon            ',
  'Sun             ',
  'Nutation angles ',
  'Libration angles',
  'LunMantle angVel',
  'TT-TDB          ',
  '<Next record>   '
  );
  TableComp: array[0..15] of Int32 = (3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 1, 0);


implementation

procedure TryClose;
begin
  try
   if F<>nil then F.Free;
  finally
   F:=nil;
  end;
end;

function TryOpen: Boolean;
begin
  TryClose;
  try
   F:=TFileStream.Create(FDir+FName, fmOpenRead or fmShareDenyWrite);
   Result:=True;
  except
   Result:=False;
  end;
end;

procedure Badformat(N: Int32);
begin
  raise Exception.Create('Bad file format ('+IntToStr(N)+')');
end;

procedure Badfile(N: Int32);
begin
  raise Exception.Create('Cannot read file ('+IntToStr(N)+')');
end;

function InitEphemeris(DENUM: Int32): Boolean;
var
  HSize, TSize, DSize, i, v: Int32;
  //LSize: Int32;
  d: double;
  Rec: THdrRec;
begin
  try
   if DEInit=-1 then
    begin
     FName:=Format('de%djpl.dat', [DENUM]);
     if not TryOpen then raise Exception.Create(Format('Cannot open file ''%s''', [FName]));

     FSize:=F.Seek(0, SoFromEnd); //file size
     if FSize<SizeOf(THdrID)+SizeOf(THdrRec) then Badformat(0);

     F.Seek(SizeOf(THdrID), soFromBeginning);
     if (F.Read(Rec, SizeOf(THdrRec))<>SizeOf(THdrRec)) then Badfile(0);
     if (Rec.I32NAME0<>$4E4F434E) or (Rec.I32NAME1<>$20205453) then Badformat(1); //if the 1st record is not 'NCONST  ';
     NumConst:=Rec.I32VALUE;
     if NumConst<MIN_NUMCONST then Badformat(2);
     //NumConst = total number of constants in the JPL ASCII header file + 9 values (NCONST, NITEMS, NCOEFF, VALINTV, OTABLE, ODATA, FSIZE, EPOCH0, EPOCH1)

     HSize:=SizeOf(THdrID)+NumConst*SizeOf(THdrRec); // header size
     if FSize<HSize then Badformat(3);
     ReallocMem(Header, HSize);
     F.Seek(0, soFromBeginning);
     HeaderLoaded:=(F.Read(THdr(Header^), HSize)=HSize);
     if not HeaderLoaded then Badfile(1);

     Rec.CNAME:='FSIZE   ';
     if not FindConstant(@Rec) then Badformat(4);
     if Rec.I32VALUE<>FSize then Badformat(5);
     Rec.CNAME:='NITEMS  ';
     if not FindConstant(@Rec) then Badformat(6);
     NumItems:=Rec.I32VALUE;
     if (NumItems<=0) or (NumItems>(MaxInt-HSize) shr 16) then Badformat(7);

     TSize:=(NumItems+1) shl 5;  // table size
     if FSize<HSize+TSize then Badformat(8);
     ReallocMem(Table, TSize);
     TableLoaded:=(F.Read(TTable(Table^), TSize)=TSize);
     if not TableLoaded then Badfile(2);
     for i:=0 to NumItems-1 do
      begin
       v:=15;
       while (Table[i].NAME[v]=' ') and (v>=0) do
        begin
         Table[i].NAME[v]:=Chr(0);
         v:=v-1;
        end;
       if PChar(@Table[i].NAME)='Earth-Moon BC' then EMBIdx:=i else
       if PChar(@Table[i].NAME)='Moon' then MoonIdx:=i else
       if PChar(@Table[i].NAME)='Sun' then SunIdx:=i else
       if PChar(@Table[i].NAME)='Nutation angles' then NutIdx:=i else
       if PChar(@Table[i].NAME)='Libration angles' then LibIdx:=i;
      end;
//     FillChar(Table[NumItems].NAME, 16, 0);
     ZeroMemory(@Table[NumItems].NAME, 16);

     Rec.CNAME:='NCOEFF  ';
     if not FindConstant(@Rec) then Badformat(9);
     NumCoef:=Rec.I32Value;
     RecLen:=NumCoef shl 3;
     Rec.CNAME:='VALINTV ';
     if not FindConstant(@Rec) then Badformat(10);
     ValIntv:=Rec.I32VALUE;
     Rec.CNAME:='EPOCH0  ';
     if not FindConstant(@Rec) then Badformat(11);
     Epoch0:=Rec.DVALUE;
     Rec.CNAME:='EPOCH1  ';
     if not FindConstant(@Rec) then Badformat(12);
     Epoch1:=Rec.DVALUE;
     if (Epoch1<=Epoch0) then Badformat(13);
     Rec.CNAME:='ODATA   ';
     if not FindConstant(@Rec) then Badformat(14);
     OData:=Rec.I32VALUE;

     Rec.CNAME:='AU      '; if FindConstant(@Rec) then AUKM:=Rec.DVALUE;
     Rec.CNAME:='RE      '; if FindConstant(@Rec) then EARTHRAD:=Rec.DVALUE;
     Rec.CNAME:='CLIGHT  '; if FindConstant(@Rec) then CLIGHTKMS:=Rec.DVALUE;
     Rec.CNAME:='EMRAT   '; if FindConstant(@Rec) then EMRAT:=Rec.DVALUE;
     Rec.CNAME:='GMB     '; if FindConstant(@Rec) then GMEARTHAU:=Rec.DVALUE;
     Rec.CNAME:='GMS     '; if FindConstant(@Rec) then GMSUNAU:=Rec.DVALUE;

     AUM:=1000*AUKM;
     CLIGHTMS:=1000*CLIGHTKMS;
     CLIGHTKMDAY:=86400*CLIGHTKMS;
     CLIGHTAUDAY:=86400*CLIGHTKMS/AUKM;
     EMBCOEF:= 1/(1+EMRAT); ONEMINUSEMBCOEF:=1-EMBCOEF;
     GMSUNKM:=GMSUNAU*AUKM*AUKM*AUKM/7464960000.0;
     GMSUNM:=1e9*GMSUNKM;
     GMEARTHKM:=GMEARTHAU*AUKM*AUKM*AUKM/7464960000.0;
     GMEARTHM:=1e9*GMEARTHKM;

     d:=(Epoch1-Epoch0)/ValIntv;
     if Frac(d)<>0 then Badformat(15);
     NumRec:=Floor(d);
     DSize:=Reclen*NumRec;
     if FSize<HSize+TSize+DSize then Badformat(16);
     if OData<HSize then Badformat(17);
     if OData+DSize>FSize then Badformat(18);

     {LSize:=NumItems*SizeOf(TLastCompRec);
     ReallocMem(LastComp, LSize); }
//     FillChar(TLastCompTbl(LastComp^), LSize, 0);  // remarked in original
     {ZeroMemory(LastComp, LSize);
     for i:=0 to NumItems-1 do
      begin
       LastComp[i].T0:=PINF;
       LastComp[i].T1:=PINF;
      end;}

     DEInit:=DENUM;
     InitPertTable(@gPertTable);
     Result:=True;
    end else Result:=(DENUM=DEInit);
  except
   on E: Exception do
    begin
     Result:=False;
     TryClose;
     MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

function FindConstant(Rec: PHdrRec): Boolean;
var
  i: Int32;
begin
  Result:=False;
  if HeaderLoaded then
   begin
    i:=0;
    while (not Result) and (i<NumConst) do
     begin
      Result:=(Rec.I32NAME0=Header.Constants[i].I32NAME0) and (Rec.I32NAME1=Header.Constants[i].I32NAME1);
      i:=i+1;
     end;
    if Result then Rec.DVALUE:=Header.Constants[i-1].DVALUE;
   end;
end;

function GetName(Target: Int32): PChar;
begin
  if HeaderLoaded and TableLoaded then
   begin
    if (Target<0) or (Target>NumItems) then Target:=NumItems;
    Result:=@Table[Target].NAME;
   end
   else
   begin
    MessageDlg('Initialization required.', mtError, [mbOK], 0);
    Result:=@TableLoaded;
   end;
end;

function GetIndex(Target: PChar): Int32;
var
  s: string;
begin
  try
   Result:=-1;
   if not (HeaderLoaded and TableLoaded) then raise Exception.Create('Initialization required.');
   repeat
    Result:=Result+1;
    s:=GetName(Result);
   until (Result>=NumItems) or (Target=s);
   if Result>=NumItems then Result:=-1;
  except
   Result:=-1;
  end;
end;

function InitPertTable(aPertTable: PPertTable): Boolean;
var
  i, j: Int32;
  Rec: THdrRec;
const
//  NullIdx = 0;
//  FullIdx = 4;
  E_Idx = 5;
  M_Idx = 9;
  Names: array[0..9] of AnsiString=('Sun', 'Jupiter BC', 'Saturn BC', 'Neptune BC', 'Uranus BC', 'Earth-Moon BC', 'Venus', 'Mars', 'Mercury', 'Moon');
  MassNames: array[0..9] of AnsiString=('GMS     ', 'GM5     ', 'GM6     ', 'GM8     ', 'GM7     ', 'GMB     ', 'GM2     ', 'GM4     ', 'GM1     ', 'EMRAT   ');
  PertNames: array[0..9] of AnsiString=('Sun', 'Jupiter BC', 'Saturn BC', 'Neptune BC', 'Uranus BC', 'Earth', 'Venus', 'Mars', 'Mercury', 'Moon');
// max PertNames string length=15
  Radius: array[0..9] of Extended=(696342, 71492, 60268, 24764, 25559, 6378.1, 6051.8, 3396.2, 2439.7, 1738.14);
begin
  try
   if not aPertTable.Initialized then
    begin

// getting GM constants of the Sun and the perturbing planets (AU^3*Msun/day^2 units)

     for i:=Low(aPertTable.Indexes) to High(aPertTable.Indexes) do
      begin
       aPertTable.Indexes[i]:=GetIndex(@Names[i][1]);
       if aPertTable.Indexes[i]<0 then raise Exception.Create('Function ''GetIndex'' failed.');
       ZeroMemory(@Rec, SizeOf(THdrRec));
       for j:=1 to Length(MassNames[i]) do Rec.CNAME[j-1]:=MassNames[i][j];
       if not FindConstant(@Rec) then raise Exception.Create('Function ''FindConstant'' failed.');
       aPertTable.GM[i]:=Rec.DVALUE;
       for j:=1 to Length(Names[i]) do aPertTable.Coll.Names[i][j]:=PertNames[i][j];
       aPertTable.Coll.Limits[i]:=Radius[i];
       aPertTable.Limits[i]:=Radius[i]/AUKM;
      end;

// adjusting GM values for the Earth and the Moon

     aPertTable.GM[M_Idx]:=aPertTable.GM[E_Idx]*EMBCOEF;
     aPertTable.GM[E_Idx]:=aPertTable.GM[M_Idx]*EMRAT;

     aPertTable.Coll.ImpactIndex:=-1;

     aPertTable.Initialized:=True;
    end;
   for i:=Low(aPertTable.Indexes) to High(aPertTable.Indexes) do
    begin
     aPertTable.Coll.MinDist[i]:=PINF;
     aPertTable.Coll.MinDistT[i]:=PINF;
    end;
   Result:=True;
  except
   Result:=False;
   try aPertTable.Initialized:=False; except end;
  end;
end;

function DecodeJulian(TJD: Double; var Year, Month, Day: Int64; var FracDay: Double): Boolean;
// Converts time from Julian format to Gregorian year/month/day/fraction of day.
var
  k, m, n: Integer;
  djd: Double;
begin
  try
   Result:=True;
   if TJD>=0 then djd:=TJD+0.5 else djd:=0.5-TJD;
   FracDay:=Frac(djd);

   k:=Trunc(djd)+68569;
   n:=(k shl 2) div 146097;

   k:=k-((146097*n+3) div 4);
   m:=4000*(k+1) div 1461001;
   k:=k- (1461*m) shr 2 + 31;

   Month:=80*k div 2447;
   Day  :=k-2447*Month div 80;
   k    :=Month div 11;

   Month:=Month+2-12*k;
   Year :=100*(n-49)+m+k;
  except
   Result:=False;
  end;
end;

function TJDStr(TJD: Double; Decimals: Int64): string;
var
  y, m, d: Int64;
  f: Double;
  s: string;
begin
  if Decimals<1 then Decimals:=1 else
  if Decimals>12 then Decimals:=12;
  s:='.'; while Decimals>0 do begin Decimals:=Decimals-1; s:=s+'0'; end;
  DecodeJulian(TJD, y, m, d, f);
  Result:=Format('%d-%.2d-%.2d%s', [y, m, d, FormatFloat(s, f)]);
end;

initialization
  //Options:=0;
  DEInit:=-1;
  ZeroMemory(@gPertTable, SizeOf(gPertTable));
  FillChar(CPO, SizeOf(TPoleAngles), 0);
  AUKM:=CAU;
  AUKMGAUSS:=AUKM*GAUSS;
  AUM:=1000*CAU;
  EARTHRAD:=CEARTHRAD;
  EMRAT:=CEMRAT;
  CLIGHTKMS:=CCLIGHTKMS;
  CLIGHTMS:=1000*CLIGHTKMS;
  CLIGHTKMDAY:=86400*CLIGHTKMS;
  CLIGHTAUDAY:=86400*CLIGHTKMS/AUKM;
  EMBCOEF:= 1/(1+1/EMRAT); ONEMINUSEMBCOEF:=1-EMBCOEF;
  GMSUNAU:=GAUSS*GAUSS;
  GMSUNKM:=GMSUNAU*AUKM*AUKM*AUKM/7464960000.0;
  GMSUNM:=1e9*GMSUNKM;
  GMEARTHAU:=CGMEARTHAU;
  GMEARTHKM:=GMEARTHAU*AUKM*AUKM*AUKM/7464960000.0;
  GMEARTHM:=1e9*GMEARTHM;
  STDOBL:=23.5*DEG2RAD;
  {asm
   fldpi
   fld st
   fadd st, st
   fstp TWOPI
   fld1
   fadd st, st
   fdiv
   fstp PIPER2
  end;}

end.

