unit RSoftUtils64;

interface

uses
 Winapi.Windows,
 System.Classes, System.SysUtils, System.RegularExpressions, System.Win.Registry,
 Winapi.ShellApi,
 Vcl.Forms,
 RSoftClasses64, AsmUtils64;

type
  TCmpFunc = function(Data: Pointer; Idx0, Idx1: Int64): Int64; // for generic quicksort; must return Value[Idx0]-Value[Idx1] (or at least the sign of it)
  TXChgProc = procedure(Data: Pointer; Idx0, Idx1: Int64);      // for generic quicksort

function ExecuteSimple(const FileName, Params: string): THandle;
function ExecuteFile(const FileName, Params, DefaultDir: string; ShowCmd: Integer): THandle;
function AppIsAlreadyRunning(const sUniqueText: string): Boolean;
function GetFileSize(const FileName: string): Int64;
function IsInteger64(const S: string): Boolean;
function IsNum(const S: string): Boolean;
function GetNum(const S: string; var Value: Double): Boolean;
function PCharToStr(p: PChar): string;
procedure SplitStr(const S, Delimiter: string; Output: TStringList);
function TrimStr(const S: string): string;
function CSVStr(const CSVLine: string; FieldIndex: Int64; const Delimiter: string; SL: TStringList): string;
function CSVInt(const CSVLine: string; FieldIndex: Int64; const Delimiter: string; SL: TStringList): Int64;
function CSVNum(const CSVLine: string; FieldIndex: Int64; const Delimiter: string; SL: TStringList): Double;
function CSVGetStr(const CSVLine: string; FieldIndex: Int64; const Delimiter: string; SL: TStringList; var Output: string): Boolean;
function CSVGetInt(const CSVLine: string; FieldIndex: Int64; const Delimiter: string; SL: TStringList; var Output: Int64): Boolean;
function CSVGetNum(const CSVLine: string; FieldIndex: Int64; const Delimiter: string; SL: TStringList; var Output: Double): Boolean;
procedure CSVQuickSortStr(List: TStrings; L, R, FieldIndex: Int64; const Delimiter: string; SL: TStringList);
procedure CSVQuickSortInt(List: TStrings; L, R, FieldIndex: Int64; const Delimiter: string; SL: TStringList);
procedure CSVQuickSortNum(List: TStrings; L, R, FieldIndex: Int64; const Delimiter: string; SL: TStringList);
function CSVBinarySearchStr(List: TStrings; const Target, Delimiter: string; FieldIndex: Int64; var Output: Int64; SL: TStringList): Boolean;
function CSVBinarySearchInt(List: TStrings; Target: Int64; Delimiter: string; FieldIndex: Int64; var Output: Int64; SL: TStringList): Boolean;
function CSVBinarySearchNum(List: TStrings; Target: Double; Delimiter: string; FieldIndex: Int64; var Output: Int64; SL: TStringList): Boolean;
procedure CSVIResetIndexes(List: TStrings; var Indexes: TDynInt64Array);
function CSVIBinarySearchStr(List: TStrings; const Target, Delimiter: string; FieldIndex: Int64; var Indexes: TDynInt64Array; var Output: Int64; SL: TStringList): Boolean;
function CSVIBinarySearchInt(List: TStrings; Target: Int64; Delimiter: string; FieldIndex: Int64; var Indexes: TDynInt64Array; var Output: Int64; SL: TStringList): Boolean;
function CSVIBinarySearchNum(List: TStrings; Target: Double; Delimiter: string; FieldIndex: Int64; var Indexes: TDynInt64Array; var Output: Int64; SL: TStringList): Boolean;
procedure CSVIQuickSortStr(List: TStrings; L, R, FieldIndex: Int64; const Delimiter: string; var Indexes: TDynInt64Array; SL: TStringList);
procedure CSVIQuickSortInt(List: TStrings; L, R, FieldIndex: Int64; const Delimiter: string; var Indexes: TDynInt64Array; SL: TStringList);
procedure CSVIQuickSortNum(List: TStrings; L, R, FieldIndex: Int64; const Delimiter: string; var Indexes: TDynInt64Array; SL: TStringList);
procedure SplitFileName(const FileName: string; var Path, Name, Ext: string);
function DirStr(const S: string): string;
function ExeFolder: string;
function GetAppTitleVer(FileName: string): string;
function GetLangID(FileName: string): Dword;
function GetLanguageName(FileName: string): string;
function GetMajorVersion(FileName: string): Int32;
function GetMinorVersion(FileName: string): Int32;
function GetReleaseVersion(FileName: string): Int32;
function GetBuildVersion(FileName: string): Int32;
function GetLongVersion(FileName: string): string;
function GetMediumVersion(FileName: string): string;
function GetShortVersion(FileName: string): string;
function GetOrigFileName(FileName: string): string;
function GetCopyrightNotice(FileName: string): string;
function GetLegalTrademarks(FileName: string): string;
function GetFileDescription(FileName: string): string;
function GetInternalName(FileName: string): string;
function GetComments(FileName: string): string;
function Delay(MSec: Cardinal): Boolean;
function AnsiLowerCase(const S: AnsiString): AnsiString;
function AnsiUpperCase(const S: AnsiString): AnsiString;
function AnsiGetStrPos(Stream: TStream; var Index: Int64; Limit: Int64; const SearchStr: AnsiString; DropSpecChars: Boolean): Boolean;
function AnsiGetStrBetween(Stream: TStream; var Index: Int64; Limit: Int64; const BeforeStr, AfterStr: AnsiString; DropSpecChars: Boolean; var Output: AnsiString): Boolean;
function AnsiGetIntBetween(Stream: TStream; var Index: Int64; Limit: Int64; const BeforeStr, AfterStr: AnsiString; DropSpecChars: Boolean; var Output: Int64): Boolean;
function AnsiGetNumBetween(Stream: TStream; var Index: Int64; Limit: Int64; const BeforeStr, AfterStr: AnsiString; DropSpecChars: Boolean; var Output: Double): Boolean;
function AnsiStrBetween(Stream: TStream; var Index: Int64; Limit: Int64; const BeforeStr, AfterStr: AnsiString; DropSpecChars: Boolean): AnsiString;
function AnsiIntBetween(Stream: TStream; var Index: Int64; Limit: Int64; const BeforeStr, AfterStr: AnsiString; DefaultValue: Int64; DropSpecChars: Boolean): Int64;
function AnsiNumBetween(Stream: TStream; var Index: Int64; Limit: Int64; const BeforeStr, AfterStr: AnsiString; DefaultValue: Double; DropSpecChars: Boolean): Double;
function GetStrBetween(const S: string; var Index: Int64; const BeforeStr, AfterStr: string; var Output: string): Boolean;
function GetIntBetween(const S: string; var Index: Int64; const BeforeStr, AfterStr: string; var Output: Int64): Boolean;
function GetNumBetween(const S: string; var Index: Int64; const BeforeStr, AfterStr: string; var Output: Double): Boolean;
function GetStrBefore(const S: string; var Index: Int64; const AfterStr: string; var Output: string): Boolean;
function GetIntBefore(const S: string; var Index: Int64; const AfterStr: string; var Output: Int64): Boolean;
function GetNumBefore(const S: string; var Index: Int64; const AfterStr: string; var Output: Double): Boolean;
procedure StringToShortString(const S: string; var RetVal);
function ShortStringToString(const S: ShortString): string;
function IsInt64(const S: string): Boolean;
procedure TryStrToInt64(const S: string; var Value: Int64; const ErrorMsg: string);
procedure TryStrToNum64(const S: string; var Value: Double; const ErrorMsg: string);
procedure GenericQuickSort(Data: Pointer; L, R: Int64; CmpFunc: TCmpFunc; XChgProc: TXChgProc);
function LoadStrFromIni(const IniFileName, VarNameTag: string): string;
function GetSystemProxy(out AHost: string; out APort: Integer): Boolean;   // the user's manual Windows proxy (see the implementation for why THTTPClient can't be trusted to find it)

implementation

function ExecuteSimple(const FileName, Params: string): THandle;
var
  fDir: string;
begin
  fDir:=ExtractFilePath(FileName);
  Result:=ShellExecute(0, nil, PChar(FileName), PChar(Params), PChar(fDir), SW_SHOW);
end;

function ExecuteFile(const FileName, Params, DefaultDir: string; ShowCmd: Integer): THandle;
begin
  Result:=ShellExecute(0, nil, PChar(FileName), PChar(Params), PChar(DefaultDir), ShowCmd);
end;

function AppIsAlreadyRunning(const sUniqueText: string): Boolean;
begin
  Result:=
  (OpenMutex(MUTEX_ALL_ACCESS, False, PChar(sUniqueText))<>0)
  or
  (CreateMutex(nil, False, PChar(sUniqueText))=0);
end;

function GetFileSize(const FileName: string): Int64;
var
  Stream: TFileStream;
begin
  Stream:=nil;
  try
   Stream:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
   Result:=Stream.Size;
  except
   Result:=0;
  end;
  if Stream<>nil then Stream.Free;
end;

function IsInteger64(const S: string): Boolean;
begin
  try
   StrToInt64(S);
   Result:=True;
  except
   Result:=False;
  end;
end;

function IsNum(const S: string): Boolean;
begin
  try
   StrToFloat(S);
   Result:=True;
  except
   Result:=False;
  end;
end;

function GetNum(const S: string; var Value: Double): Boolean;
begin
  try
   Value:=StrToFloat(S);
   Result:=True;
  except
   Result:=False;
  end;
end;

function PCharToStr(p: PChar): string;
var
  i: Int64;
  b: Byte;
begin
  Result:='';
  i:=0;
  repeat
   b:=PByteArray(p)[i];
   if b>0 then Result:=Result+Chr(b);
   i:=i+1;
  until b<1;
end;

procedure SplitStr(const S, Delimiter: string; Output: TStringList);
var
  i: Int64;
  z: string;
begin
  Output.Clear;
  z:=S;
  repeat
   i:=z.IndexOf(Delimiter);
   if i>=0 then
    begin
     Output.Append(Copy(z, 1, i));
     z:=Copy(z, i+Length(Delimiter)+1, Length(z)-i-Length(Delimiter));
    end;
  until (i<0);
  Output.Append(z);
end;

function TrimStr(const S: string): string;
var
  i, j: Int64;
  Z: string;
begin
  Result:='';
  j:=0;
  Z:=Trim(S);
  for i:=1 to Length(Z) do
   begin
    if Z[i]=' ' then j:=j+1 else j:=0;
    if j<2 then Result:=Result+Z[i];
   end;
end;

function CSVStr(const CSVLine: string; FieldIndex: Int64; const Delimiter: string; SL: TStringList): string;
begin
  //if CSVLine<>'' then
  SplitStr(CSVLine, Delimiter, SL);
  if (FieldIndex>=0) and (FieldIndex<SL.Count) then Result:=SL[FieldIndex] else Result:='';
end;

function CSVInt(const CSVLine: string; FieldIndex: Int64; const Delimiter: string; SL: TStringList): Int64;
begin
  try
   Result:=StrToInt64(CSVStr(CSVLine, FieldIndex, Delimiter, SL));
  except
   Result:=0;
  end;
end;

function CSVNum(const CSVLine: string; FieldIndex: Int64; const Delimiter: string; SL: TStringList): Double;
begin
  try
   Result:=StrToFloat(CSVStr(CSVLine, FieldIndex, Delimiter, SL));
  except
   Result:=0.0;
  end;
end;

function CSVGetStr(const CSVLine: string; FieldIndex: Int64; const Delimiter: string; SL: TStringList; var Output: string): Boolean;
begin
  if CSVLine<>'' then SplitStr(CSVLine, Delimiter, SL);
  Result:=(FieldIndex>=0) and (FieldIndex<SL.Count);
  if Result then Output:=SL[FieldIndex];
end;

function CSVGetInt(const CSVLine: string; FieldIndex: Int64; const Delimiter: string; SL: TStringList; var Output: Int64): Boolean;
var
  s: string;
begin
  Result:=CSVGetStr(CSVLine, FieldIndex, Delimiter, SL, s);
  if Result then
   try
    Output:=StrToInt64(s);
   except
    Result:=False;
   end;
end;

function CSVGetNum(const CSVLine: string; FieldIndex: Int64; const Delimiter: string; SL: TStringList; var Output: Double): Boolean;
var
  s: string;
begin
  Result:=CSVGetStr(CSVLine, FieldIndex, Delimiter, SL, s);
  if Result then
   try
    Output:=StrToFloat(s);
   except
    Result:=False;
   end;
end;

procedure CSVQuickSortStr(List: TStrings; L, R, FieldIndex: Int64; const Delimiter: string; SL: TStringList);
var
  I, J, M: Int64;
  s, z: string;
begin
  repeat
   I:=L; J:=R;
   M:=(L+R) shr 1;
   s:=CSVStr(List[M], FieldIndex, Delimiter, SL);
   repeat
    while CompareText(CSVStr(List[I], FieldIndex, Delimiter, SL), s) < 0 do I:=I+1;
    while CompareText(CSVStr(List[J], FieldIndex, Delimiter, SL), s) > 0 do J:=J-1;
    if I<=J then
     begin
      if I<>J then
       begin
        z:=List[I];
        List[I]:=List[J];
        List[J]:=z;
       end;
      I:=I+1; J:=J-1;
     end;
   until I>J;
   if L<J then CSVQuickSortStr(List, L, J, FieldIndex, Delimiter, SL);
   L:=I;
  until I>=R;
end;

procedure CSVQuickSortInt(List: TStrings; L, R, FieldIndex: Int64; const Delimiter: string; SL: TStringList);
var
  n, I, J, M: Int64;
  z: string;
begin
  repeat
   I:=L; J:=R;
   M:=(L+R) shr 1;
   n:=CSVInt(List[M], FieldIndex, Delimiter, SL);
   repeat
    while CSVInt(List[I], FieldIndex, Delimiter, SL) < n do I:=I+1;
    while CSVInt(List[J], FieldIndex, Delimiter, SL) > n do J:=J-1;
    if I<=J then
     begin
      if I<>J then
       begin
        z:=List[I];
        List[I]:=List[J];
        List[J]:=z;
       end;
      I:=I+1; J:=J-1;
     end;
   until I>J;
   if L<J then CSVQuickSortInt(List, L, J, FieldIndex, Delimiter, SL);
   L:=I;
  until I>=R;
end;

procedure CSVQuickSortNum(List: TStrings; L, R, FieldIndex: Int64; const Delimiter: string; SL: TStringList);
var
  I, J, M: Int64;
  d: Double;
  z: string;
begin
  repeat
   I:=L; J:=R;
   M:=(L+R) shr 1;
   d:=CSVNum(List[M], FieldIndex, Delimiter, SL);
   repeat
    while CSVNum(List[I], FieldIndex, Delimiter, SL) < d do I:=I+1;
    while CSVNum(List[J], FieldIndex, Delimiter, SL) > d do J:=J-1;
    if I<=J then
     begin
      if I<>J then
       begin
        z:=List[I];
        List[I]:=List[J];
        List[J]:=z;
       end;
      I:=I+1; J:=J-1;
     end;
   until I>J;
   if L<J then CSVQuickSortNum(List, L, J, FieldIndex, Delimiter, SL);
   L:=I;
  until I>=R;
end;

function CSVBinarySearchStr(List: TStrings; const Target, Delimiter: string; FieldIndex: Int64; var Output: Int64; SL: TStringList): Boolean;
var
  L, R, M, X: Int64;
  s: string;
begin
  Result:=False; L:=0; R:=List.Count;
  while (R>L) do
   begin
    M:=(L+R) shr 1;
    if not CSVGetStr(List[M], FieldIndex, Delimiter, SL, s) then s:='';
    X:=CompareText(Target, s);
    Result:=(X=0);
    if Result then
     begin
      L:=M;
      R:=M;
     end else if X>0 then L:=M+1 else R:=M;
   end;
  Output:=L;
end;

function CSVBinarySearchInt(List: TStrings; Target: Int64; Delimiter: string; FieldIndex: Int64; var Output: Int64; SL: TStringList): Boolean;
var
  i, L, R, M, X: Int64;
begin
  Result:=False; L:=0; R:=List.Count;
  while (R>L) do
   begin
    M:=(L+R) shr 1;
    if not CSVGetInt(List[M], FieldIndex, Delimiter, SL, i) then i:=0;
    X:=Target-i;
    Result:=(X=0);
    if Result then
     begin
      L:=M;
      R:=M;
     end else if X>0 then L:=M+1 else R:=M;
   end;
  Output:=L;
end;

function CSVBinarySearchNum(List: TStrings; Target: Double; Delimiter: string; FieldIndex: Int64; var Output: Int64; SL: TStringList): Boolean;
var
  L, R, M: Int64;
  d, X: Double;
begin
  Result:=False; L:=0; R:=List.Count;
  while (R>L) do
   begin
    M:=(L+R) shr 1;
    if not CSVGetNum(List[M], FieldIndex, Delimiter, SL, d) then d:=0;
    X:=Target-d;
    Result:=(X=0.0);
    if Result then
     begin
      L:=M;
      R:=M;
     end else if X>0.0 then L:=M+1 else R:=M;
   end;
  Output:=L;
end;

procedure CSVIResetIndexes(List: TStrings; var Indexes: TDynInt64Array);
var
  i: Int64;
begin
  try
   SetLength(Indexes, List.Count);
   for i:=0 to List.Count-1 do Indexes[i]:=i;
  except
   SetLength(Indexes, 0);
  end;
end;

procedure CSVIQuickSortStr(List: TStrings; L, R, FieldIndex: Int64; const Delimiter: string; var Indexes: TDynInt64Array; SL: TStringList);
var
  I, J, M, z: Int64;
  s: string;
begin
  repeat
   I:=L; J:=R;
   M:=(L+R) shr 1;
   s:=CSVStr(List[Indexes[M]], FieldIndex, Delimiter, SL);
   repeat
    while CompareText(CSVStr(List[Indexes[I]], FieldIndex, Delimiter, SL), s) < 0 do I:=I+1;
    while CompareText(CSVStr(List[Indexes[J]], FieldIndex, Delimiter, SL), s) > 0 do J:=J-1;
    if I<=J then
     begin
      if I<>J then
       begin
        z:=Indexes[I];
        Indexes[I]:=Indexes[J];
        Indexes[J]:=z;
       end;
      I:=I+1; J:=J-1;
     end;
   until I>J;
   if L<J then CSVIQuickSortStr(List, L, J, FieldIndex, Delimiter, Indexes, SL);
   L:=I;
  until I>=R;
end;

procedure CSVIQuickSortInt(List: TStrings; L, R, FieldIndex: Int64; const Delimiter: string; var Indexes: TDynInt64Array; SL: TStringList);
var
  n, I, J, M, z: Int64;
begin
  repeat
   I:=L; J:=R;
   M:=(L+R) shr 1;
   n:=CSVInt(List[Indexes[M]], FieldIndex, Delimiter, SL);
   repeat
    while CSVInt(List[Indexes[I]], FieldIndex, Delimiter, SL) < n do I:=I+1;
    while CSVInt(List[Indexes[J]], FieldIndex, Delimiter, SL) > n do J:=J-1;
    if I<=J then
     begin
      if I<>J then
       begin
        z:=Indexes[I];
        Indexes[I]:=Indexes[J];
        Indexes[J]:=z;
       end;
      I:=I+1; J:=J-1;
     end;
   until I>J;
   if L<J then CSVIQuickSortInt(List, L, J, FieldIndex, Delimiter, Indexes, SL);
   L:=I;
  until I>=R;
end;

procedure CSVIQuickSortNum(List: TStrings; L, R, FieldIndex: Int64; const Delimiter: string; var Indexes: TDynInt64Array; SL: TStringList);
var
  I, J, M, z: Int64;
  d: Double;
begin
  repeat
   I:=L; J:=R;
   M:=(L+R) shr 1;
   d:=CSVNum(List[Indexes[M]], FieldIndex, Delimiter, SL);
   repeat
    while CSVNum(List[Indexes[I]], FieldIndex, Delimiter, SL) < d do I:=I+1;
    while CSVNum(List[Indexes[J]], FieldIndex, Delimiter, SL) > d do J:=J-1;
    if I<=J then
     begin
      if I<>J then
       begin
        z:=Indexes[I];
        Indexes[I]:=Indexes[J];
        Indexes[J]:=z;
       end;
      I:=I+1; J:=J-1;
     end;
   until I>J;
   if L<J then CSVIQuickSortNum(List, L, J, FieldIndex, Delimiter, Indexes, SL);
   L:=I;
  until I>=R;
end;

function CSVIBinarySearchStr(List: TStrings; const Target, Delimiter: string; FieldIndex: Int64; var Indexes: TDynInt64Array; var Output: Int64; SL: TStringList): Boolean;
var
  L, R, M, X: Int64;
  s: string;
begin
  Result:=False; L:=0; R:=List.Count;
  while (R>L) do
   begin
    M:=(L+R) shr 1;
    if not CSVGetStr(List[Indexes[M]], FieldIndex, Delimiter, SL, s) then s:='';
    X:=CompareText(Target, s);
    Result:=(X=0);
    if Result then
     begin
      L:=M;
      R:=M;
     end else if X>0 then L:=M+1 else R:=M;
   end;
  Output:=L;
end;

function CSVIBinarySearchInt(List: TStrings; Target: Int64; Delimiter: string; FieldIndex: Int64; var Indexes: TDynInt64Array; var Output: Int64; SL: TStringList): Boolean;
var
  i, L, R, M, X: Int64;
begin
  Result:=False; L:=0; R:=List.Count;
  while (R>L) do
   begin
    M:=(L+R) shr 1;
    if not CSVGetInt(List[Indexes[M]], FieldIndex, Delimiter, SL, i) then i:=0;
    X:=Target-i;
    Result:=(X=0);
    if Result then
     begin
      L:=M;
      R:=M;
     end else if X>0 then L:=M+1 else R:=M;
   end;
  Output:=L;
end;

function CSVIBinarySearchNum(List: TStrings; Target: Double; Delimiter: string; FieldIndex: Int64; var Indexes: TDynInt64Array; var Output: Int64; SL: TStringList): Boolean;
var
  L, R, M: Int64;
  d, X: Double;
begin
  Result:=False; L:=0; R:=List.Count;
  while (R>L) do
   begin
    M:=(L+R) shr 1;
    if not CSVGetNum(List[Indexes[M]], FieldIndex, Delimiter, SL, d) then d:=0;
    X:=Target-d;
    Result:=(X=0.0);
    if Result then
     begin
      L:=M;
      R:=M;
     end else if X>0.0 then L:=M+1 else R:=M;
   end;
  Output:=L;
end;

procedure SplitFileName(const FileName: string; var Path, Name, Ext: string);
var
  i, j, k: Int64;
begin
  Path:=ExtractFilePath(FileName); if (Path<>'') and (Path[Length(Path)]<>'\') then Path:=Path+'\';
  Name:=ExtractFileName(FileName);
  Ext:=ExtractFileExt(FileName);
  i:=0; k:=-1;
  repeat
   j:=Name.IndexOf('.', i);
   if j>=0 then begin i:=j+1; k:=j; end;
  until j<0;
  if k>=0 then Name:=Copy(Name, 1, k);
end;

function DirStr(const S: string): string;
begin
  if (S<>'') and (S[Length(S)]<>'\') then Result:=S+'\' else Result:=S;
end;

function ExeFolder: string;
begin
  Result:=DirStr(ExtractFilePath(Application.ExeName));
end;

function GetAppTitleVer(FileName: string): string;
begin
  Result:=Application.Title+' '+GetShortVersion(Application.ExeName);
end;

function GetLangID(FileName: string): Dword;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:=0;
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     GetFileVersionInfo(PChar(FileName), 0, Size, Pt);
     VerQueryValue(Pt, '\VarFileInfo\Translation', Pt2, Size2);
     Result:=WSWAP32(Dword(Pt2^));
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetLanguageName(FileName: string): string;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
  LangID: Dword;
begin
  Result:='';
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     GetFileVersionInfo(PChar(FileName), 0, Size, Pt);
     VerQueryValue(Pt, '\VarFileInfo\Translation', Pt2, Size2);
     LangID:=Dword(Pt2^); Size2:=255;
     VerLanguageName(LangID, Pt2, Size2);
     Result:=PChar(Pt2);
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetMajorVersion(FileName: string): Int32;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:=-1;
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\', Pt2, Size2)
       then with TVSFixedFileInfo(Pt2^) do
        Result:=HiWord(dwFileVersionMS);
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetMinorVersion(FileName: string): Int32;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:=-1;
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\', Pt2, Size2)
       then with TVSFixedFileInfo(Pt2^) do
        Result:=LoWord(dwFileVersionMS);
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetReleaseVersion(FileName: string): Int32;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:=-1;
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt,Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\', Pt2, Size2)
       then with TVSFixedFileInfo(Pt2^) do
        Result:=HiWord(dwFileVersionLS);
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetBuildVersion(FileName: string): Int32;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:=-1;
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\', Pt2, Size2)
       then with TVSFixedFileInfo(Pt2^) do
        Result:=LoWord(dwFileVersionLS);
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetLongVersion(FileName: string): string;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:='';
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\', Pt2, Size2)
       then with TVSFixedFileInfo(Pt2^) do
        Result:=
         IntToStr(HiWord(dwFileVersionMS))+'.'+
          IntToStr(LoWord(dwFileVersionMS))+'.'+
           IntToStr(HiWord(dwFileVersionLS))+'.'+
            IntToStr(LoWord(dwFileVersionLS));
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetMediumVersion(FileName: string): string;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:='';
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\', Pt2, Size2)
       then with TVSFixedFileInfo(Pt2^) do
        Result:=
         IntToStr(HiWord(dwFileVersionMS))+'.'+
          IntToStr(LoWord(dwFileVersionMS))+'.'+
           IntToStr(HiWord(dwFileVersionLS));
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetShortVersion(FileName: string): string;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:='';
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\', Pt2, Size2)
       then with TVSFixedFileInfo(Pt2^) do
        Result:=
         IntToStr(HiWord(dwFileVersionMS))+'.'+
          IntToStr(LoWord(dwFileVersionMS));
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetOrigFileName(FileName: string): string;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:='';
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\VarFileInfo\Translation', Pt2, Size2)
       and VerQueryValue(Pt, PChar('\StringFileInfo\'+IntToHex(WSWAP32(Dword(Pt2^)), 8)+'\OriginalFilename'), Pt2, Size2)
        then Result:=PChar(Pt2);
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetCopyrightNotice(FileName: string): string;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:='';
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\VarFileInfo\Translation', Pt2, Size2)
       and VerQueryValue(Pt, PChar('\StringFileInfo\'+IntToHex(WSWAP32(Dword(Pt2^)), 8)+'\LegalCopyright'), Pt2, Size2)
        then Result:=PChar(Pt2);
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetLegalTrademarks(FileName: string): string;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:='';
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\VarFileInfo\Translation', Pt2, Size2)
       and VerQueryValue(Pt, PChar('\StringFileInfo\'+IntToHex(WSWAP32(Dword(Pt2^)), 8)+'\LegalTrademarks'), Pt2, Size2)
        then Result:=PChar(Pt2);
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetFileDescription(FileName: string): string;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:='';
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\VarFileInfo\Translation', Pt2, Size2)
       and VerQueryValue(Pt, PChar('\StringFileInfo\'+IntToHex(WSWAP32(Dword(Pt2^)), 8)+'\FileDescription'), Pt2, Size2)
        then Result:=PChar(Pt2);
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetInternalName(FileName: string): string;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:='';
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\VarFileInfo\Translation', Pt2, Size2)
       and VerQueryValue(Pt, PChar('\StringFileInfo\'+IntToHex(WSWAP32(Dword(Pt2^)), 8)+'\InternalName'), Pt2, Size2)
        then Result:=PChar(Pt2);
    finally
     FreeMem(Pt);
    end;
   end;
end;

function GetComments(FileName: string): string;
var
  Size, Size2: Dword;
  Pt, Pt2: Pointer;
begin
  Result:='';
  Size:=GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size>0 then
   begin
    GetMem(Pt, Size);
    try
     if GetFileVersionInfo(PChar(FileName), 0, Size, Pt)
      and VerQueryValue(Pt, '\VarFileInfo\Translation', Pt2, Size2)
       and VerQueryValue(Pt, PChar('\StringFileInfo\'+IntToHex(WSWAP32(Dword(Pt2^)), 8)+'\Comments'), Pt2, Size2)
        then Result:=PChar(Pt2);
    finally
     FreeMem(Pt);
    end;
   end;
end;

function Delay(MSec: Cardinal): Boolean;
var
  vDelay: THandle;
  w: Integer;
begin
  vDelay:=CreateEvent(nil, False, False, 'Delay');
  try
   if vDelay=0 then raise Exception.Create('Function ''CreateEvent()'' failed.');
   w:=WaitForSingleObject(vDelay, MSec);
   Result:=(w=WAIT_TIMEOUT) or (w=WAIT_OBJECT_0);
  except
   Result:=False;
  end;
  if vDelay<>0 then CloseHandle(vDelay);
end;

function AnsiLowerCase(const S: AnsiString): AnsiString;
var
  i: Int64;
  b: Byte;
begin
  Result:='';
  for i:=0 to Length(S)-1 do
   begin
    b:=PByteArray(@S[1])[i];
    if (b>=65) and (b<=90) then b:=b+32;
    Result:=Result+AnsiChar(b);
   end;
end;

function AnsiUpperCase(const S: AnsiString): AnsiString;
var
  i: Int64;
  b: Byte;
begin
  Result:='';
  for i:=0 to Length(S)-1 do
   begin
    b:=PByteArray(@S[1])[i];
    if (b>=97) and (b<=122) then b:=b-32;
    Result:=Result+AnsiChar(b);
   end;
end;

function AnsiGetStrPos(Stream: TStream; var Index: Int64; Limit: Int64; const SearchStr: AnsiString; DropSpecChars: Boolean): Boolean;
var
  i, j, k: Int64;
  b: Byte;
begin
  Result:=False;
  if Limit<1 then Limit:=Stream.Size;
  i:=Stream.Seek(Index, soFromBeginning);
  if i=Index then
   begin
    j:=1; k:=i;
    while (not Result) and (i<=Limit) and (Stream.Read(b, 1)=1) do
     begin
      if ((not DropSpecChars) or ((b<>9) and (b<>10) and (b<>13))) then
       begin
        if b=Ord(SearchStr[j]) then
         begin
          if j=1 then k:=i;
          j:=j+1;
         end else j:=1;
        Result:=(j>Length(SearchStr));
       end;
      i:=i+1;
     end;
    if Result then Index:=k;
   end;
end;

function AnsiGetStrBetween(Stream: TStream; var Index: Int64; Limit: Int64; const BeforeStr, AfterStr: AnsiString; DropSpecChars: Boolean; var Output: AnsiString): Boolean;
var
  i, j, k: Int64;
  b: Byte;
begin
  Result:=False;
  i:=Index;
  if AnsiGetStrPos(Stream, i, Limit, BeforeStr, DropSpecChars) then
   begin
    i:=i+Length(BeforeStr); j:=i; k:=i;
    if AnsiGetStrPos(Stream, j, Limit, AfterStr, DropSpecChars) then
     begin
      Output:='';
      Stream.Seek(i, soFromBeginning);
      while (i<j) and (Stream.Read(b, 1)=1) do
       begin
        if (not DropSpecChars) or ((b<>9) and (b<>10) and (b<>13)) then Output:=Output+AnsiChar(b);
        i:=i+1;
       end;
      Index:=k;
      Result:=True;
     end;
   end;
end;

function AnsiGetIntBetween(Stream: TStream; var Index: Int64; Limit: Int64; const BeforeStr, AfterStr: AnsiString; DropSpecChars: Boolean; var Output: Int64): Boolean;
var
  s: AnsiString;
begin
  try
   Result:=AnsiGetStrBetween(Stream, Index, Limit, BeforeStr, AfterStr, DropSpecChars, s);
   if Result then Output:=StrToInt64(UnicodeString(s));
  except
   Result:=False;
  end;
end;

function AnsiGetNumBetween(Stream: TStream; var Index: Int64; Limit: Int64; const BeforeStr, AfterStr: AnsiString; DropSpecChars: Boolean; var Output: Double): Boolean;
var
  s: AnsiString;
begin
  try
   Result:=AnsiGetStrBetween(Stream, Index, Limit, BeforeStr, AfterStr, DropSpecChars, s);
   if Result then Output:=StrToFloat(UnicodeString(s));
  except
   Result:=False;
  end;
end;

function AnsiStrBetween(Stream: TStream; var Index: Int64; Limit: Int64; const BeforeStr, AfterStr: AnsiString; DropSpecChars: Boolean): AnsiString;
var
  i, j, k: Int64;
  b: Byte;
begin
  Result:='';
  i:=Index;
  if AnsiGetStrPos(Stream, i, Limit, BeforeStr, DropSpecChars) then
   begin
    i:=i+Length(BeforeStr); j:=i; k:=i;
    if AnsiGetStrPos(Stream, j, Limit, AfterStr, DropSpecChars) then
     begin
      Stream.Seek(i, soFromBeginning);
      while (i<j) and (Stream.Read(b, 1)=1) do
       begin
        if (not DropSpecChars) or ((b<>9) and (b<>10) and (b<>13)) then Result:=Result+AnsiChar(b);
        i:=i+1;
       end;
      Index:=k;
     end;
   end;
end;

function AnsiIntBetween(Stream: TStream; var Index: Int64; Limit: Int64; const BeforeStr, AfterStr: AnsiString; DefaultValue: Int64; DropSpecChars: Boolean): Int64;
var
  s: AnsiString;
begin
  s:=AnsiStrBetween(Stream, Index, Limit, BeforeStr, AfterStr, DropSpecChars);
  try
   Result:=StrToInt64(UnicodeString(s));
  except
   Result:=DefaultValue;
  end;
end;

function AnsiNumBetween(Stream: TStream; var Index: Int64; Limit: Int64; const BeforeStr, AfterStr: AnsiString; DefaultValue: Double; DropSpecChars: Boolean): Double;
var
  s: AnsiString;
begin
  s:=AnsiStrBetween(Stream, Index, Limit, BeforeStr, AfterStr, DropSpecChars);
  try
   Result:=StrToFloat(UnicodeString(s));
  except
   Result:=DefaultValue;
  end;
end;

function GetStrBetween(const S: string; var Index: Int64; const BeforeStr, AfterStr: string; var Output: string): Boolean;
var
  i, j: Int64;
begin
  Result:=False;
  i:=S.IndexOf(BeforeStr, Index);
  if i>=0 then
   begin
    i:=i+Length(BeforeStr);
    j:=S.IndexOf(AfterStr, i);
    if j>=i then
     begin
      Index:=i;
      Output:=Copy(S, i+1, j-i);
     end;
   end;
end;

function GetIntBetween(const S: string; var Index: Int64; const BeforeStr, AfterStr: string; var Output: Int64): Boolean;
var
  i: Int64;
  z: string;
begin
  try
   i:=Index;
   Result:=GetStrBetween(S, i, BeforeStr, AfterStr, z);
   if Result then
    begin
     Output:=StrToInt64(z);
     Index:=i;
    end;
  except
   Result:=False;
  end;
end;

function GetNumBetween(const S: string; var Index: Int64; const BeforeStr, AfterStr: string; var Output: Double): Boolean;
var
  i: Int64;
  z: string;
begin
  try
   i:=Index;
   Result:=GetStrBetween(S, i, BeforeStr, AfterStr, z);
   if Result then
    begin
     Output:=StrToFloat(z);
     Index:=i;
    end;
  except
   Result:=False;
  end;
end;

function GetStrBefore(const S: string; var Index: Int64; const AfterStr: string; var Output: string): Boolean;
var
  i: Int64;
begin
  i:=S.IndexOf(AfterStr, Index);
  Result:=(i>=0) and (i>=Index);
  if Result then
   begin
    Output:=Copy(S, Index+1, i-Index);
    Index:=i+Length(AfterStr);
   end;
end;

function GetIntBefore(const S: string; var Index: Int64; const AfterStr: string; var Output: Int64): Boolean;
var
  i: Int64;
  z: string;
begin
  try
   i:=Index;
   Result:=GetStrBefore(S, i, AfterStr, z);
   if Result then
    begin
     Output:=StrToInt64(z);
     Index:=i;
    end;
  except
   Result:=False;
  end;
end;

function GetNumBefore(const S: string; var Index: Int64; const AfterStr: string; var Output: Double): Boolean;
var
  i: Int64;
  z: string;
begin
  try
   i:=Index;
   Result:=GetStrBefore(S, i, AfterStr, z);
   if Result then
    begin
     Output:=StrToFloat(z);
     Index:=i;
    end;
  except
   Result:=False;
  end;
end;

procedure StringToShortString(const S: string; var RetVal);
var
  L: Integer;
  P: PByte;
  B: TBytes;
begin
  L:=Length(S);
  if L>255 then raise Exception.Create('Strings longer than 255 characters cannot be converted');
  SetLength(B, L);
  P:=@RetVal;
  P^:=L;
  Inc(P);
  B:=TEncoding.Ansi.GetBytes(S);
  Move(B[0], P^, L);
end;

function ShortStringToString(const S: ShortString): string;
var
  B: TBytes;
  L: Byte;
begin
  Result:='';
  L:=Byte(S[0]);
  SetLength(B, L);
  Move(S[1], B[0], L);
  Result:=TEncoding.Ansi.GetString(B);
end;

function IsInt64(const S: string): Boolean;
begin
  try
   StrToInt64(S);
   Result:=True;
  except
   Result:=False;
  end;
end;

procedure TryStrToInt64(const S: string; var Value: Int64; const ErrorMsg: string);
begin
  try
   Value:=StrToInt64(S);
  except
   raise Exception.Create(ErrorMsg);
  end;
end;

procedure TryStrToNum64(const S: string; var Value: Double; const ErrorMsg: string);
begin
  try
   Value:=StrToFloat(S);
  except
   raise Exception.Create(ErrorMsg);
  end;
end;

procedure GenericQuickSort(Data: Pointer; L, R: Int64; CmpFunc: TCmpFunc; XChgProc: TXChgProc);
var
  I, J, M: Integer;
begin
  repeat
   I:=L; J:=R; M:=(L+R) shr 1;
   repeat
    while CmpFunc(Data, I, M) < 0 do I:=I+1;
    while CmpFunc(Data, J, M) > 0 do J:=J-1;
    if I<=J then
     begin
      XChgProc(Data, I, J);
      if M=I then M:=J else if M=J then M:=I;
      I:=I+1; J:=J-1;
     end;
   until I>J;
   if L<J then GenericQuickSort(Data, L, J, CmpFunc, XChgProc);
   L:=I;
  until I>=R;
end;

function LoadStrFromIni(const IniFileName, VarNameTag: string): string;
var
  L: TStringList;
begin
  L:=TStringList.Create;
  try
   L.LoadFromFile(IniFileName);
   L.NameValueSeparator:='=';
   Result:=L.Values[VarNameTag];
  except
   Result:='';
  end;
  L.Free;
end;

function GetSystemProxy(out AHost: string; out APort: Integer): Boolean;
// Reads the user's MANUAL proxy straight from the Windows Internet Settings. Do NOT leave this to THTTPClient:
// its own discovery only falls back to the manual entry if there is neither a PAC URL nor "Automatically detect
// settings" (WPAD) configured -- and WPAD is ticked by default. With WPAD ticked but no WPAD server answering,
// that discovery fails and the RTL then issues the request with NO proxy at all; behind a firewall that does not
// fail fast, it hangs until the timeout (and never receives a 407, so no auth prompt either). Assigning the
// result to THTTPClient.ProxySettings takes the RTL's explicit-proxy path and skips that discovery entirely.
// Leave ProxySettings.UserName empty: supplying it up front forces Basic auth, whereas letting the proxy's 407
// arrive lets WinHTTP negotiate whatever it actually offers (Negotiate/NTLM/Digest/Basic).
var
  R: TRegistry; s, entry: string; L: TStringList; i, p: Integer;
begin
  Result:=False; AHost:=''; APort:=0;
  s:='';
  R:=TRegistry.Create(KEY_READ);
  try
   R.RootKey:=HKEY_CURRENT_USER;
   if not R.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Internet Settings') then Exit;
   if (not R.ValueExists('ProxyEnable')) or (R.ReadInteger('ProxyEnable')=0) then Exit;   // proxy switched off: honour that, go direct
   if R.ValueExists('ProxyServer') then s:=Trim(R.ReadString('ProxyServer'));
  finally
   R.Free;
  end;
  if s='' then Exit;
  // ProxyServer is either a bare 'host:port' or a per-protocol list, 'http=host:port;https=host:port;ftp=...'
  if Pos('=', s)>0 then
   begin
    L:=TStringList.Create;
    try
     L.Delimiter:=';'; L.StrictDelimiter:=True; L.DelimitedText:=s;
     s:='';
     for i:=0 to L.Count-1 do
      begin
       entry:=Trim(L[i]);
       if SameText(Copy(entry, 1, 6), 'https=') then begin s:=Trim(Copy(entry, 7, MaxInt)); Break; end;   // prefer the https entry: these callers fetch https
       if SameText(Copy(entry, 1, 5), 'http=') and (s='') then s:=Trim(Copy(entry, 6, MaxInt));           // otherwise the http one (usually the same box)
      end;
    finally
     L.Free;
    end;
    if s='' then Exit;
   end;
  p:=LastDelimiter(':', s);
  if p>0 then
   begin
    AHost:=Trim(Copy(s, 1, p-1));
    APort:=StrToIntDef(Trim(Copy(s, p+1, MaxInt)), 0);
   end
  else AHost:=s;
  Result:=AHost<>'';
end;

end.
