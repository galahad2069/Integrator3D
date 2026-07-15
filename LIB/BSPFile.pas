unit BSPFile;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes, System.Math,
  RSoftUtils64;

type

  TBSPTargetCode = record
    Code: Int64;
    Name: AnsiString;
  end;

  TBSPConvCode = record
    JPLCode, BSPCode: Int64;
  end;

  TBSPFTPStr = packed record
   Str0: array[0..6] of AnsiChar;
   Num0: Byte;
   Str1: array[0..0] of AnsiChar;
   Num1: Byte;
   Str2: array[0..0] of AnsiChar;
   Num2: Word;
   Str3: array[0..0] of AnsiChar;
   Num3: Word;
   Str4: array[0..0] of AnsiChar;
   Num4: Byte;
   Str5: array[0..0] of AnsiChar;
   Num5: Word;
   Str6: array[0..6] of AnsiChar;
  end;

  TBSPHeaderRec = packed record
   // file format ID string ('DAF/SPK')
   IDWORD: array[0..7] of AnsiChar;
   // number of Double and Int32 components of descriptors
   ND, NI: Int32;
   // internal name of the program that created this bsp file (e.g. 'SPKMERGE')
   IFNAME: array[0..59] of AnsiChar;
   // forward and backward linked list pointers (???)
   FWD, BWD: Int32;
   // first free DAF address (not an address per se, but a 1-base index in the array of Doubles)
   FREE: Int32;
   // binary file format ID ('LTL-IEEE' for LSB-style floating point numbers)
   BFF: array[0..7] of AnsiChar;
   // padding
   null0: array[0..602] of AnsiChar;
   // ftp corruption test string
   FTP: TBSPFTPStr;
   // padding
   null1: array[0..296] of AnsiChar;
  end;
  PBSPHeaderRec = ^TBSPHeaderRec;

  TBSPDescriptor = packed record
   epoch0, epoch1: Double;
   targetID, centerID, refID, typeID, idx0, idx1: Int32;
  end;
  PBSPDescriptor = ^TBSPDescriptor;

  TBSPDescriptorRec = packed record   // one physical DAF summary record (1024 bytes) -- read buffer only
   N, P, C: Double;                    // NEXT / PREV summary-record numbers; C = NSUM (descriptors in THIS record)
   DESC: array[0..24] of TBSPDescriptor;
  end;
  PBSPDescriptorRec = ^TBSPDescriptorRec;

  TBSPDescriptors = record             // ALL descriptors, accumulated across the whole summary-record chain
   N, P, C: Double;                    // C repurposed = total segment count (N/P retained for the hex viewer)
   DESC: array of TBSPDescriptor;
  end;

  TBSPSegmentID = array[0..39] of AnsiChar;
  PBSPSegmentID = ^TBSPSegmentID;
  TBSPSegmentIDRec = packed record     // one physical DAF name record (1024 bytes) -- read buffer only
   SegmentID: array[0..24] of TBSPSegmentID;
   Number: array[0..2] of Double;
  end;
  PBSPSegmentIDRec = ^TBSPSegmentIDRec;

  TBSPSegmentIDs = record              // ALL segment IDs, accumulated across the summary-record chain
   SegmentID: array of TBSPSegmentID;
   Number: array[0..2] of Double;
  end;

  TBSPSegmentRecordStart = packed record
   MIDPOINT, RADIUS: Double;
  end;
  PBSPSegmentRecordStart = ^TBSPSegmentRecordStart;

  TBSPSegmentDirectory = packed record
    INIT, INTLEN, RSIZE, N: Double;
  end;
  PBSPSegmentDirectory = ^TBSPSegmentDirectory;

  TBSPSegmentDirRec = array of TBSPSegmentDirectory;             // one entry per segment (dynamic)
  PBSPSegmentDirRec = ^TBSPSegmentDirRec;

  TBSPSegmentRecordStartRec = array of TBSPSegmentRecordStart;   // one entry per segment (dynamic)
  PBSPSegmentRecordStartRec = ^TBSPSegmentRecordStartRec;

  TBSPPointers = record
   hdr, com, dsc, sgm, dat: Int64;
   dscptr: array of Int64;             // file offsets, one per segment (dynamic)
   sgmptr: array of Int64;
   dirptr: array of Int64;
   datptr: array of Int64;
  end;

  TBSPRecords = record
   hdr: TBSPHeaderRec;
   dsc: TBSPDescriptors;               // accumulated across the whole summary-record chain (was one record)
   sgm: TBSPSegmentIDs;
   dir: TBSPSegmentDirRec;
   srs: TBSPSegmentRecordStartRec;
  end;

  TBSPFile = record
   FileName: string;
   Stream: TMemoryStream;
   Ptr: TBSPPointers;
   Rec: TBSPRecords;
   TargetCount: Int64;
   TgtIdx: array of Int64;             // one entry per segment (dynamic)
   TgtRecSize: array of Int64; //bytes
   TgtRecCount: array of Int64;
  end;
  PBSPFile = ^TBSPFile;

function BSPGetDataType(Code: Int64): AnsiString;
function BSPGetTargetName(Code: Int64): AnsiString;
function BSPGetFrameName(Code: Int64): AnsiString;
function BSPEpochToTJD(Value: Double): Double;
function TJDToBSPEpoch(Value: Double): Double;
function BSPTargetCode(JPLCode: Int64): Int64;
function BSPInit(BSPFile: PBSPFile; const FileName: string): Boolean;
function BSPOpen(BSPFile: PBSPFile): Boolean;
procedure BSPClose(BSPFile: PBSPFile);
function BSPSort(BSPFile: PBSPFile): Boolean;
function CmpDesc(Data: Pointer; Idx0, Idx1: Int64): Int64;

var
  BSPError: string;

const
  //MAX_SEARCH = 256*SizeOf(TBSPDescriptorRec);
  SPKID: AnsiString = 'DAF/SPK ';
  BSPDataTypes: array[0..21] of AnsiString = (
  '<invalid data type>',
  'Special data type (divided difference arrays, a unique type used by JPL)',
  'Chebyshev polynomials for position (fixed intervals)',
  'Chebyshev polynomials for position and velocity (fixed intervals)',
  'Special data type (used by Hubble Space Telescope)',
  'Discrete states (using weighted 2-body propagation)',
  'Special data type (trigonometric expansion of elements for Phobos and Deimos)',
  'Special data type (precessing elements)',
  'Lagrange interpolation of position and velocity (fixed intervals)',
  'Lagrange interpolation of position and velocity (variable intervals)',
  'Weighted two-line element sets (Space Command)',
  '<Unused data type>',
  'Hermite interpolation of position and velocity (fixed intervals)',
  'Hermite interpolation of position and velocity (variable intervals)',
  'Chebyshev polynomials for position and velocity (variable intervals)',
  'Precessing conic elements propagator',
  'Special data type (used by ESA Infrared Space Observatory)',
  'Equinoctial elements (used for some satellites)',
  'Emulation of ESOC''s ''DDID'' format (used for SMART-1, MEX, VEX, and Rosetta)',
  'Revised emulation of ESOC''s ''DDID format (uses ''mini-segments'')',
  'Chebyshev polynomials for velocity (fixed intervals)',
  'Special data type (modified divided difference arrays, a unique type used by JPL)');

  BSPFrameCodes: array[0..21] of TBSPTargetCode = (
  (Code:  0; Name: '<unknown frame>'),
  (Code:  1; Name: 'J2000 (Earth mean equator, dynamical equinox of J2000)'),
  (Code:  2; Name: 'B1950 (Earth mean equator, dynamical equinox of B1950)'),
  (Code:  3; Name: 'FK4 (Fundamental Catalog 4)'),
  (Code:  4; Name: 'DE-118 (JPL Developmental Ephemeris 118)'),
  (Code:  5; Name: 'DE-96 (JPL Developmental Ephemeris 96)'),
  (Code:  6; Name: 'DE-102 (JPL Developmental Ephemeris 102)'),
  (Code:  7; Name: 'DE-108 (JPL Developmental Ephemeris 108)'),
  (Code:  8; Name: 'DE-111 (JPL Developmental Ephemeris 111)'),
  (Code:  9; Name: 'DE-114 (JPL Developmental Ephemeris 114)'),
  (Code: 10; Name: 'DE-122 (JPL Developmental Ephemeris 122)'),
  (Code: 11; Name: 'DE-125 (JPL Developmental Ephemeris 125)'),
  (Code: 12; Name: 'DE-130 (JPL Developmental Ephemeris 130)'),
  (Code: 13; Name: 'GALACTIC (Galactic System II)'),
  (Code: 14; Name: 'DE-200 (JPL Developmental Ephemeris 200)'),
  (Code: 15; Name: 'DE-202 (JPL Developmental Ephemeris 202)'),
  (Code: 16; Name: 'MARSIAU (Mars Mean Equator and IAU vector of J2000)'),
  (Code: 17; Name: 'ECLIPJ2000 (Ecliptic coordinates based upon the J2000 frame)'),
  (Code: 18; Name: 'ECLIPB1950 (Ecliptic coordinates based upon the B1950 frame)'),
  (Code: 19; Name: 'DE-140 (JPL Developmental Ephemeris 140)'),
  (Code: 20; Name: 'DE-142 (JPL Developmental Ephemeris 142)'),
  (Code: 21; Name: 'DE-143 (JPL Developmental Ephemeris 143)'));

  BSPConversionCodes: array[0..20] of TBSPConvCode = (
   (JPLCode:  0; BSPCode:  -1),  // - Nutation/Libration Center
   (JPLCode:  1; BSPCode:   1),  // - Mercury BC
   (JPLCode:  2; BSPCode:   2),  // - Venus BC
   (JPLCode:  3; BSPCode:   3),  // - Earth-Moon BC
   (JPLCode:  4; BSPCode:   4),  // - Mars BC
   (JPLCode:  5; BSPCode:   5),  // - Jupiter
   (JPLCode:  6; BSPCode:   6),  // - Saturn
   (JPLCode:  7; BSPCode:   7),  // - Uranus
   (JPLCode:  8; BSPCode:   8),  // - Neptune
   (JPLCode:  9; BSPCode:   9),  // - Pluto
   (JPLCode: 10; BSPCode: 301),  // - Moon
   (JPLCode: 11; BSPCode:  10),  // - Sun
   (JPLCode: 12; BSPCode:   0),  // - Solar System BC
   (JPLCode: 13; BSPCode:   3),  // - Earth-Moon BC
   (JPLCode: 14; BSPCode:  -1),  // - Nutations
   (JPLCode: 15; BSPCode:  -1),  // - Librations
   (JPLCode: 16; BSPCode:  -1),  // - TT-TDB
   (JPLCode: 17; BSPCode:  -1),  // - TT-TCD or TT-TDG rate
   (JPLCode: 18; BSPCode:  -1),  // - TCG-TCB
   (JPLCode: 19; BSPCode:  -1),  // - Moon angular velocity
   (JPLCode: 20; BSPCode:  -1)); // - Earth rotation (S parameter / TEO)

implementation

uses
  CelestialMechanics;   // BodyName -- BSPGetTargetName delegates to the shared default table

function BSPGetDataType(Code: Int64): AnsiString;
begin
  if (Code<Low(BSPDataTypes)) or (Code>High(BSPDataTypes)) then Code:=0;
  Result:=BSPDataTypes[Code];
end;

function BSPGetTargetName(Code: Int64): AnsiString;
begin
  Result:=BodyName(Code);   // delegate to the shared default table (CelestialMechanics.BodyConstants)
end;

function BSPGetFrameName(Code: Int64): AnsiString;
var
  i: Int64;
begin
  i:=High(BSPFrameCodes);
  while (i>0) and (Code<>BSPFrameCodes[i].Code) do i:=i-1;
  Result:=BSPFrameCodes[i].Name;
end;

function BSPEpochToTJD(Value: Double): Double;
begin
  Result:=(Value/86400.0)+STANDARD_EPOCH;
end;

function TJDToBSPEpoch(Value: Double): Double;
begin
  Result:=(Value-STANDARD_EPOCH)*86400.0;
end;

function BSPTargetCode(JPLCode: Int64): Int64;
begin
  Result:=High(BSPConversionCodes);
  while (Result>Low(BSPConversionCodes)) and (JPLCode<>BSPConversionCodes[Result].JPLCode) do Result:=Result-1;
  if Result>=0 then Result:=BSPConversionCodes[Result].JPLCode;
end;

function BSPInit(BSPFile: PBSPFile; const FileName: string): Boolean;
// must not be called with a variable that had been opened before (must be closed first)
var
  i, p, q, recno, addr, cnt, base: Int64;
  Stream: TFileStream;
  sumRec: TBSPDescriptorRec;    // physical read buffer for one summary record (25 descriptors)
  nameRec: TBSPSegmentIDRec;    // physical read buffer for its paired name record
begin
  Stream:=nil;
  try
   Finalize(BSPFile^);                        // release any previous file's dynamic arrays + FileName...
   FillChar(BSPFile^, SizeOf(TBSPFile), 0);   // ...then blank every field (managed fields are now nil)
   BSPFile.FileName:=FileName;

   Stream:=TFileStream.Create(BSPFile.FileName, fmOpenRead or fmShareDenyWrite);
   p:=0;
   if Stream.Seek(p, soFromBeginning)<>p then raise Exception.Create('Seek error.');
   if Stream.Read(BSPFile.Rec.hdr, SizeOf(TBSPHeaderRec))<>SizeOf(TBSPHeaderRec) then raise Exception.Create('Read error.');
   if BSPFile.Rec.hdr.IDWORD<>SPKID then raise Exception.Create('Wrong file type.');
   BSPFile.Ptr.hdr:=p;

   // Walk the DAF summary-record linked list (hdr.FWD -> sumRec.N -> ... -> 0), accumulating EVERY segment.
   // Each physical summary record holds up to 25 descriptors (sumRec.C of them); its paired name record
   // immediately follows it. The previous code read only the first record, silently capping files at 25.
   BSPFile.TargetCount:=0;
   BSPFile.Ptr.dsc:=(BSPFile.Rec.hdr.FWD-1)*SizeOf(TBSPHeaderRec);   // first summary/name records (hex viewer)
   BSPFile.Ptr.sgm:=BSPFile.Ptr.dsc+SizeOf(TBSPHeaderRec);
   BSPFile.Ptr.dat:=BSPFile.Ptr.dsc+2*SizeOf(TBSPHeaderRec);
   recno:=BSPFile.Rec.hdr.FWD;
   while recno>0 do
    begin
     addr:=(recno-1)*SizeOf(TBSPHeaderRec);
     if Stream.Seek(addr, soFromBeginning)<>addr then raise Exception.Create('Seek error.');
     if Stream.Read(sumRec, SizeOf(TBSPDescriptorRec))<>SizeOf(TBSPDescriptorRec) then raise Exception.Create('Read error.');
     if Stream.Read(nameRec, SizeOf(TBSPSegmentIDRec))<>SizeOf(TBSPSegmentIDRec) then raise Exception.Create('Read error.');   // name record follows
     if Frac(sumRec.C)<>0 then raise Exception.Create('Non-integer segment descriptor count.');
     cnt:=System.Trunc(sumRec.C);
     if (cnt<0) or (cnt>Length(sumRec.DESC)) then raise Exception.Create('Invalid segment descriptor count.');
     base:=BSPFile.TargetCount;
     SetLength(BSPFile.Rec.dsc.DESC, base+cnt);
     SetLength(BSPFile.Rec.sgm.SegmentID, base+cnt);
     SetLength(BSPFile.Ptr.dscptr, base+cnt);
     SetLength(BSPFile.Ptr.sgmptr, base+cnt);
     for i:=0 to cnt-1 do
      begin
       BSPFile.Rec.dsc.DESC[base+i]:=sumRec.DESC[i];
       BSPFile.Rec.sgm.SegmentID[base+i]:=nameRec.SegmentID[i];
       BSPFile.Ptr.dscptr[base+i]:=addr+3*SizeOf(Double)+i*SizeOf(TBSPDescriptor);      // after N,P,C
       BSPFile.Ptr.sgmptr[base+i]:=addr+SizeOf(TBSPHeaderRec)+i*SizeOf(TBSPSegmentID);  // name record follows the summary
      end;
     BSPFile.TargetCount:=base+cnt;
     recno:=System.Trunc(sumRec.N);   // next summary record; 0 = end of chain
    end;
   BSPFile.Rec.dsc.C:=BSPFile.TargetCount;   // repurpose C = total segment count (hex viewer / callers)
   if BSPFile.TargetCount<1 then raise Exception.Create('No segment descriptors found.');

   SetLength(BSPFile.Rec.dir, BSPFile.TargetCount);
   SetLength(BSPFile.Rec.srs, BSPFile.TargetCount);
   SetLength(BSPFile.Ptr.dirptr, BSPFile.TargetCount);
   SetLength(BSPFile.Ptr.datptr, BSPFile.TargetCount);
   SetLength(BSPFile.TgtIdx, BSPFile.TargetCount);
   SetLength(BSPFile.TgtRecSize, BSPFile.TargetCount);
   SetLength(BSPFile.TgtRecCount, BSPFile.TargetCount);
   for i:=0 to BSPFile.TargetCount-1 do BSPFile.TgtIdx[i]:=i;

   for i:=0 to BSPFile.TargetCount-1 do
    begin
     q:=Int64(BSPFile.Rec.dsc.DESC[i].idx1)*SizeOf(Double)-SizeOf(TBSPSegmentDirectory);
     if Stream.Seek(q, soFromBeginning)<>q then raise Exception.Create('Read error.');
     if Stream.Read(BSPFile.Rec.dir[i], SizeOf(TBSPSegmentDirectory))<>SizeOf(TBSPSegmentDirectory) then raise Exception.Create('Read error.');
     BSPFile.Ptr.dirptr[i]:=q;
    end;

   for i:=0 to BSPFile.TargetCount-1 do
    begin
     q:=BSPFile.Rec.dsc.DESC[i].idx0-1;
     BSPFile.TgtRecSize[i]:=System.Trunc(BSPFile.Rec.dir[i].RSIZE)*SizeOf(Double);
     BSPFile.TgtRecCount[i]:=System.Trunc(BSPFile.Rec.dir[i].N);
     BSPFile.Ptr.datptr[i]:=q*SizeOf(Double);
     if Stream.Seek(BSPFile.Ptr.datptr[i], soFromBeginning)<>BSPFile.Ptr.datptr[i] then raise Exception.Create('Read error.');
     if Stream.Read(BSPFile.Rec.srs[i], SizeOf(TBSPSegmentRecordStart))<>SizeOf(TBSPSegmentRecordStart) then raise Exception.Create('Read error.');
    end;

   Result:=True;
  except on E: Exception do begin
   BSPError:=E.Message;
   Result:=False;
  end; end;
  if Stream<>nil then Stream.Free;
end;

function BSPOpen(BSPFile: PBSPFile): Boolean;
// BSPFile must be initialized first
begin
  BSPFile.Stream:=nil;
  try
   BSPFile.Stream:=TMemoryStream.Create;
   BSPFile.Stream.LoadFromFile(BSPFile.FileName);
   Result:=True;
  except on E: Exception do begin
   BSPClose(BSPFile);
   BSPError:=E.Message;
   Result:=False;
  end; end;
end;

procedure BSPClose(BSPFile: PBSPFile);
// BSPFile must be initialized first
var
  Stream: TMemoryStream;
begin
  try
   Stream:=BSPFile.Stream;
   try
    if Stream<>nil then Stream.Free;
   except on E: Exception do
    BSPError:=E.Message;
   end;
   BSPFile.Stream:=nil;
  except on E: Exception do
   BSPError:=E.Message;
  end;
end;

function CmpDesc(Data: Pointer; Idx0, Idx1: Int64): Int64;
var
  i, i0, i1: Int64;
begin
  i0:=TBSPFile(Data^).TgtIdx[Idx0];
  i1:=TBSPFile(Data^).TgtIdx[Idx1];
  i:=PBSPFile(Data).Rec.dsc.DESC[i0].refID - PBSPFile(Data).Rec.dsc.DESC[i1].refID;
  if i=0 then
   begin
    i:=PBSPFile(Data).Rec.dsc.DESC[i0].centerID - PBSPFile(Data).Rec.dsc.DESC[i1].centerID;
    if i=0 then
     begin
      i:=TBSPFile(Data^).Rec.dsc.DESC[i0].targetID - TBSPFile(Data^).Rec.dsc.DESC[i1].targetID;
      if i=0 then
       begin
        i:=Sign(TBSPFile(Data^).Rec.dsc.DESC[i0].epoch0 - TBSPFile(Data^).Rec.dsc.DESC[i1].epoch0);
        if i=0 then i:=Sign(TBSPFile(Data^).Rec.dsc.DESC[i0].epoch1 - TBSPFile(Data^).Rec.dsc.DESC[i1].epoch1);
       end;
     end;
   end;
  Result:=i;
end;

procedure XChgDesc(Data: Pointer; Idx0, Idx1: Int64);
var
  i: Int64;
begin
  i:=TBSPFile(Data^).TgtIdx[Idx1];
  TBSPFile(Data^).TgtIdx[Idx1]:=TBSPFile(Data^).TgtIdx[Idx0];
  TBSPFile(Data^).TgtIdx[Idx0]:=i;
end;

function BSPSort(BSPFile: PBSPFile): Boolean;
begin
  try
   GenericQuickSort(BSPFile, Low(BSPFile.Rec.dsc.DESC), BSPFile.TargetCount-1, CmpDesc, XChgDesc);
   Result:=True;
  except on E: Exception do begin
   BSPError:=E.Message;
   Result:=False;
  end; end;;
end;

end.
