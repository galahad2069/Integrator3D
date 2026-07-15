unit RSoftClasses64;

interface

uses Winapi.Windows, System.Classes, System.SysUtils,
     RSoftTypes64, AsmUtils64;

type
{TDynInt64Array}

  TDynInt64Array = array of Int64;
  TDynInt64ArrayInitMode = (im_Int64InitNone, im_Int64InitNull, im_Int64InitFull, im_Int64InitIndex);

{TCustomList}

  TCustomList = class;

  TCustomListItemCompareCallback = function(P1, P2: Pointer): Int64; stdcall;
  //must return zero if values are equal, neg value if item[P1]<item[P2], pos value if item[P1]>item[P2]
  TCustomListItemCheckCallback = function(Data, P: Pointer): Int64; stdcall;
  //must return zero if the item at pointer is what you were looking for, neg value if it's smaller, pos value if it's greater than you'd like

  TCustomList = class(TPersistent)
  private
    FRec, FData: Pointer;
    FSize: Int64;           // bytes allocated
    FCount: Int64;          // number of records
    FLastIndex: Int64;      // index of last record
    FRecSize: Int64;        // bytes per record
    FMaxCapacity: Int64;    // absolute maximum number of records possible
    FCapacity: Int64;       // allocated memory can hold this many records
    FAllocCount: Int64;     // allocation happens in blocks of this many records
  protected
    function GetItem(Index: Int64): Pointer;
  public
    constructor Create(RecordSize, AllocCount: Int64);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function LoadFromFile(const FileName: string): Boolean;
    function SaveToFile(const FileName: string): Boolean;
    procedure Clear;
    procedure Append(Value: Pointer);
    procedure Insert(Index: Int64; Value: Pointer);
    procedure Delete(Index: Int64);
    procedure ExchangeItems(Index1, Index2: Int64);
    function InitIndexes(var Indexes: TDynInt64Array): Boolean;
    procedure QuickSort(L, R: Int64; CompareItems: TCustomListItemCompareCallback);
    procedure QuickSortIndexed(L, R: Int64; var Indexes: TDynInt64Array; CompareItems: TCustomListItemCompareCallback);
    function BinarySearch(CheckItem: TCustomListItemCheckCallback; Data: Pointer; var Index: Int64): Boolean;
    function BinarySearchIndexed(CheckItem: TCustomListItemCheckCallback; Data: Pointer; const Indexes: TDynInt64Array; var Index: Int64): Boolean;
    property Item[Index: Int64]: Pointer read GetItem; default;
    property Data: Pointer read FData;
    property Size: Int64 read FSize;
    property Count: Int64 read FCount;
    property LastIndex: Int64 read FLastIndex;
    property RecSize: Int64 read FRecSize;
    property MaxCapacity: Int64 read FMaxCapacity;
    property Capacity: Int64 read FCapacity;
    property AllocCount: Int64 read FAllocCount;
  end;

  TAlignedMemoryStream = class(TStream)
  private
    FMemory: Pointer;
    FSize: Int64;
    FCapacity: Int64;
    FPosition: Int64;
    FAlignment: Int64;
    procedure SetCapacity(NewCapacity: Int64); // Cleaned: Passed by value
  protected
    function Realloc(var NewCapacity: Int64): Pointer; virtual;
  public
    constructor Create(AAlignment: Int64); reintroduce; // Cleaned: Passed by value
    destructor Destroy; override;
    procedure Clear;

    // Virtual overrides: Signatures MUST match TStream exactly
    function Read(var Buffer; Count: NativeInt): NativeInt; override;
    function Write(const Buffer; Count: NativeInt): NativeInt; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    procedure SetSize(const NewSize: Int64); override; // Must keep const to match TStream

    // Public properties
    property Memory: Pointer read FMemory;
    property Capacity: Int64 read FCapacity write SetCapacity;
    property Alignment: Int64 read FAlignment;
  end;

  function SaveDynInt64Array(const FileName: string; const A: TDynInt64Array): Boolean;
  function LoadDynInt64Array(const FileName: string; var A: TDynInt64Array): Boolean;
  function InitDynInt64Array(var A: TDynInt64Array; Count: Int64; Mode: TDynInt64ArrayInitMode): Boolean;
  function AppendDynInt64Array(var A: TDynInt64Array; Value: Int64): Boolean;
  function InsertDynInt64Array(var A: TDynInt64Array; Index, Value: Int64): Boolean;
  function DeleteDynInt64Array(var A: TDynInt64Array; Index: Int64): Boolean;
  procedure QuickSortDynInt64Array(var A: TDynInt64Array; L, R: Int64) ;
  function BinarySearchDynInt64Array(const A: TDynInt64Array; X: Int64; var Index: Int64): Boolean;

implementation

{TDynInt64Array}

{function SaveDynInt64Array(const FileName: string; const A: TDynInt64Array): Boolean;
var
  i: Int64;
  F: File;
begin
  AssignFile(F, FileName);
  try
   i:=Length(A);
   Rewrite(F, SizeOf(Int64));
   BlockWrite(F, A[0], i);
   Result:=True;
  except
   Result:=False;
  end;
  CloseFile(F);
end;}

function SaveDynInt64Array(const FileName: string; const A: TDynInt64Array): Boolean;
var
  j: Int64;
  Stream: TFileStream;
begin
  Stream:=nil;
  try
   j:=Length(A)*SizeOf(Int64);
   Stream:=TFileStream.Create(FileName, fmCreate);
   Stream.Seek(0, soFromBeginning);
   Result:=(Stream.Write(A[0], j)=j);
  except
   Result:=False;
  end;
  if Stream<>nil then Stream.Free;
end;

function LoadDynInt64Array(const FileName: string; var A: TDynInt64Array): Boolean;
var
  i, j: Int64;
  Stream: TFileStream;
begin
  Result:=False;
  Stream:=nil;
  try
   Stream:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
   i:=Stream.Size div SizeOf(Int64);
   j:=i*SizeOf(Int64);
   SetLength(A, i);
   Stream.Seek(0, soFromBeginning);
   Result:=(Stream.Read(A[0], j)=j);
  finally
   if Stream<>nil then Stream.Free;
   if not Result then SetLength(A, 0);
  end;
end;

function InitDynInt64Array(var A: TDynInt64Array; Count: Int64; Mode: TDynInt64ArrayInitMode): Boolean;
var
  i: Int64;
begin
  try
   if Length(A)<>Count then SetLength(A, Count);
   case Mode of
    im_Int64InitNull: ZeroMemory64(@A[0], Count*SizeOf(Int64));
    im_Int64InitFull: FillQword64(@A[0], Count, -1);
    im_Int64InitIndex: for i:=0 to Count-1 do A[i]:=i;
   end;
   Result:=True;
  except
   Result:=False;
  end;
end;

function AppendDynInt64Array(var A: TDynInt64Array; Value: Int64): Boolean;
var
  i: Int64;
begin
  try
   i:=Length(A);
   SetLength(A, i+1);
   A[i]:=Value;
   Result:=True;
  except
   Result:=False;
  end;
end;

function InsertDynInt64Array(var A: TDynInt64Array; Index, Value: Int64): Boolean;
var
  i, j, n: Int64;
begin
  try
   j:=Length(A); n:=j+1;
   if (Index<0) or (Index>n) then raise Exception.Create(Format('Index (%d) out of bounds (0..%d) error in function InsertDynInt64Array().', [Index, n]));
   if Index=n then Result:=AppendDynInt64Array(A, Value) else
    begin
     SetLength(A, n);
     for i:=j downto Index+1 do A[i]:=A[i-1];
     A[Index]:=Value;
     Result:=True;
    end;
  except
   Result:=False;
  end;
end;

function DeleteDynInt64Array(var A: TDynInt64Array; Index: Int64): Boolean;
var
  i, j, n: Int64;
begin
  try
   j:=Length(A); n:=j-1;
   if (Index<0) or (Index>n) then raise Exception.Create(Format('Index (%d) out of bounds (0..%d) error in function DeleteDynInt64Array().', [Index, n]));
   if Index<n then for i:=Index to n-1 do A[i]:=A[i+1];
   SetLength(A, n);
   Result:=True;
  except
   Result:=False;
  end;
end;

procedure QuickSortDynInt64Array(var A: TDynInt64Array; L, R: Int64) ;
 var
   I, J, M, T: Int64;
 begin
   repeat
    I:=L; J:=R;
    M:=A[(I+J) shr 1];
    repeat
     while A[I]<M do I:=I+1;
     while A[J]>M do J:=J-1;
     if I<=J then
      begin
       if I<>J then
        begin
         T:=A[I];
         A[I]:=A[J];
         A[J]:=T;
        end;
       I:=I+1; J:=J-1;
      end;
    until I>J;
    if L<J then QuickSortDynInt64Array(A, L, J) ;
    L:=I;
   until I>=R;
 end;

function BinarySearchDynInt64Array(const A: TDynInt64Array; X: Int64; var Index: Int64): Boolean;
var
  L, R, M, D: Int64;
begin
  Result:=False;
  L:=Low(A);
  R:=High(A)+1;
  while L<R do
   begin
    M:=(L+R) shr 1;
    D:=X-A[M];
    Result:=(D=0);
    if Result then begin L:=M; R:=M; end else if D>0 then L:=M+1 else R:=M;
   end;
  Index:=L;
end;

{TCustomList}

constructor TCustomList.Create(RecordSize, AllocCount: Int64);
begin
  inherited Create;
  FData:=nil;
  FSize:=0;
  FCount:=0;
  FLastIndex:=0;
  FCapacity:=0;
  if RecordSize<1 then FRecSize:=1 else FRecSize:=RecordSize;
  ReallocMem(FRec, FRecSize);
  FMaxCapacity:=High(Int64) div FRecSize;
  if AllocCount>FMaxCapacity then FAllocCount:=FMaxCapacity else FAllocCount:=AllocCount;
end;

destructor TCustomList.Destroy;
begin
  ReallocMem(FData, 0);
  ReallocMem(FRec, 0);
  inherited Destroy;
end;

procedure TCustomList.Assign(Source: TPersistent);
begin
  if Source is TCustomList then
   begin
    if FSize<>TCustomList(Source).Size then ReallocMem(FData, TCustomList(Source).Size);
    FSize:=TCustomList(Source).Size;
    FCapacity:=TCustomList(Source).Capacity;
    FRecSize:=TCustomList(Source).RecSize;
    FMaxCapacity:=TCustomList(Source).MaxCapacity;
    FAllocCount:=TCustomList(Source).AllocCount;
    FCount:=TCustomList(Source).Count;
    FLastIndex:=TCustomList(Source).LastIndex;
    if FSize>0 then MemCopy64(TCustomList(Source).Data, FData, FSize);
   end;
end;

function TCustomList.LoadFromFile(const FileName: string): Boolean;
var
  r, c: Int64;
  Stream: TFileStream;
begin
  Stream:=nil;
  try
   Stream:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
   c:=Stream.Size div FRecSize; // number of records in file
   r:=c*FRecSize;               // number of bytes to read
   Stream.Seek(0, soFromBeginning);
   if c<=FMaxCapacity then
    begin
     if c>FCapacity then
      begin
       FCapacity:=FAllocCount*((c div FAllocCount)+Ord((c mod FAllocCount)<>0));
       FSize:=FCapacity*FRecSize;
       ReallocMem(FData, FSize);
      end;

     if Stream.Read(FData^, r)<r then raise Exception.Create('Read error.');
     FCount:=c;
     FLastIndex:=c-1;
     Result:=True;
    end else raise Exception.Create('File has too many records.');
  except
   Result:=False;
   FCapacity:=0;
   FSize:=0;
   FCount:=0;
   FLastIndex:=-1;
   ReallocMem(FData, 0);
  end;
  if Stream<>nil then Stream.Free;
end;

function TCustomList.SaveToFile(const FileName: string): Boolean;
var
  Stream: TFileStream;
begin
  Stream:=nil;
  try
   Stream:=TFileStream.Create(FileName, fmCreate);
   Stream.Seek(0, soFromBeginning);
   Stream.Write(TByteArray(FData^)[0], FCount*FRecSize);
   Result:=True;
  except
   Result:=False;
  end;
  if Stream<>nil then Stream.Free;
end;

procedure TCustomList.Clear;
begin
  ReallocMem(FData, 0);
  FSize:=0;
  FCapacity:=0;
  FCount:=0;
  FLastIndex:=-1;
end;

procedure TCustomList.Append(Value: Pointer);
var
  NewCount: Int64;
begin
  NewCount:=FCount+1;
  if NewCount<=FMaxCapacity then
   begin
    if NewCount>FCapacity then
     begin
      FCapacity:=FCapacity+FAllocCount;
      FSize:=FCapacity*FRecSize;
      ReallocMem(FData, FSize);
     end;
    MemCopy64(Value, Pointer(Int64(FData)+FCount*FRecSize), FRecSize);
    FLastIndex:=FCount;
    FCount:=NewCount;
   end;
end;

procedure TCustomList.Insert(Index: Int64; Value: Pointer);
var
  NC: Int64;
  NP: Pointer;
begin
  if (Index<0) or (Index>FCount) then raise Exception.Create(Format('Index (%d) out of bounds (0..%d).', [Index, FCount]));
  NC:=FCount+1;
  if NC<=FMaxCapacity then
   begin
    if NC>FCapacity then
     begin
      FCapacity:=FCapacity+FAllocCount;
      FSize:=FCapacity*FRecSize;
      ReallocMem(FData, FSize);
     end;
    NP:=Pointer(Int64(FData)+Index*FRecSize);
    if Index<FCount then MemCopy64(NP, Pointer(Int64(NP)+FRecSize), FRecSize*(FCount-Index));
    MemCopy64(Value, NP, FRecSize);
    FLastIndex:=FCount;
    FCount:=NC;
   end;
end;

procedure TCustomList.Delete(Index: Int64);
var
  i: Int64;
begin
  if (Index<0) or (Index>FLastIndex) then raise Exception.Create(Format('Index (%d) out of bounds (0..%d) error in function TCustomList.Delete().', [Index, FLastIndex]));
  i:=Index*FRecSize;
  if Index<FCount-1 then MemCopy64(Pointer(Int64(FData)+i+FRecSize), Pointer(Int64(FData)+i), (FLastIndex-Index)*FRecSize);
  FCount:=FLastIndex;
  FLastIndex:=FCount-1;
  if (FCount>0) and (FCapacity-FCount>FAllocCount) then
   begin
    FCapacity:=FCapacity-FAllocCount;
    FSize:=FCount*FRecSize;
    ReallocMem(FData, FSize);
   end;
end;

procedure TCustomList.ExchangeItems(Index1, Index2: Int64);
var
  P0, P1, P2: Pointer;
begin
  P0:=nil;
  if (Index1<0) or (Index1>FLastIndex) then raise Exception.Create(Format('Index (%d) out of bounds (0..%d) error in function TCustomList.ExchangeItems().', [Index1, FLastIndex]));
  if (Index2<0) or (Index2>FLastIndex) then raise Exception.Create(Format('Index (%d) out of bounds (0..%d) error in function TCustomList.ExchangeItems().', [Index2, FLastIndex]));
  if Index1<>Index2 then
   begin
    ReallocMem(P0, FRecSize);
    try
     P1:=Pointer(Int64(FData)+Index1*FRecSize);
     P2:=Pointer(Int64(FData)+Index2*FRecSize);
     MemCopy64(P2, P0, FRecSize);
     MemCopy64(P1, P2, FRecSize);
     MemCopy64(P0, P1, FRecSize);
    finally
     ReallocMem(P0, 0);
    end;
   end;
end;

function TCustomList.GetItem(Index: Int64): Pointer;
begin
  if (Index<0) or (Index>FLastIndex) then raise Exception.Create(Format('Index (%d) out of bounds (0..%d) error in function TCustomList.GetItem().', [Index, FLastIndex]));
  Result:=Pointer(Int64(FData)+Index*FRecSize);
end;

function TCustomList.InitIndexes(var Indexes: TDynInt64Array): Boolean;
begin
  Result:=InitDynInt64Array(Indexes, FCount, im_Int64InitIndex);
end;

procedure TCustomList.QuickSort(L, R: Int64; CompareItems: TCustomListItemCompareCallback);
var
  I, J: Int64;
begin
  repeat
   I:=L; J:=R;
   MemCopy64(Item[(L+R) shr 1], FRec, FRecSize);
   repeat
    while CompareItems(Item[I], FRec)<0 do I:=I+1;
    while CompareItems(Item[J], FRec)>0 do J:=J-1;
    if I<=J then
     begin
      ExchangeItems(I, J);
      I:=I+1; J:=J-1;
     end;
   until I>J;
   if L<J then QuickSort(L, J, CompareItems);
   L:=I;
  until I>=R;
end;

{procedure TCustomList.QuickSort(L, R: Int64; CompareItems: TCustomListItemCompareCallback);
var
  I, J, P: Integer;
  M: Pointer;
begin
  while L<R do
   begin
    if (R-L)=1 then
     begin
      if CompareItems(Pointer(Int64(FData)+L*FRecSize), Pointer(Int64(FData)+R*FRecSize))>0 then ExchangeItems(L, R);
      Break;
     end;
     I:=L;
     J:=R;
     P:=(L+R) shr 1;
     M:=Pointer(Int64(FData)+P*FRecSize);
     repeat
      while (I<>P) and (CompareItems(Pointer(Int64(FData)+I*FRecSize), M)<0) do I:=I+1;
      while (J<>P) and (CompareItems(Pointer(Int64(FData)+J*FRecSize), M)>0) do J:=J-1;
      if I<=J then
      begin
       if I<>J then ExchangeItems(I, J);
       if P=I then P:=J else if P=J then P:=I;
       I:=I+1; J:=J-1;
      end;
     until I>J;
    if (J-L)>(R-I) then
     begin
      if I<R then QuickSort(I, R, CompareItems);
      R:=J;
     end
     else
     begin
      if L<J then QuickSort(L, J, CompareItems);
      L:=I;
     end;
   end;
end; }

procedure TCustomList.QuickSortIndexed(L, R: Int64; var Indexes: TDynInt64Array; CompareItems: TCustomListItemCompareCallback);
var
  I, J, K: Int64;
begin
  repeat
   I:=L; J:=R;
   MemCopy64(Item[Indexes[(L+R) shr 1]], FRec, FRecSize);
   repeat
    while CompareItems(Item[Indexes[I]], FRec)<0 do I:=I+1;
    while CompareItems(Item[Indexes[J]], FRec)>0 do J:=J-1;
    if I<=J then
     begin
      if I<>J then
       begin
        K:=Indexes[I];
        Indexes[I]:=Indexes[J];
        Indexes[J]:=K;
       end;
      I:=I+1; J:=J-1;
     end;
   until I>J;
   if L<J then QuickSortIndexed(L, J, Indexes, CompareItems);
   L:=I;
  until I>=R;
end;

function TCustomList.BinarySearch(CheckItem: TCustomListItemCheckCallback; Data: Pointer; var Index: Int64): Boolean;
var
  L, R, M, D: Int64;
begin
  Result:=False;
  L:=0;
  R:=FCount;
  while L<R do
   begin
    M:=(L+R) shr 1;
    D:=CheckItem(Data, Pointer(Int64(FData)+M*FRecSize));
    Result:=(D=0);
    if Result then begin L:=M; R:=M; end else if D>0 then L:=M+1 else R:=M;
   end;
  Index:=L;
end;

function TCustomList.BinarySearchIndexed(CheckItem: TCustomListItemCheckCallback; Data: Pointer; const Indexes: TDynInt64Array; var Index: Int64): Boolean;
var
  L, R, M, D: Int64;
begin
  Result:=False;
  L:=0;
  R:=FCount;
  while L<R do
   begin
    M:=(L+R) shr 1;
    D:=CheckItem(Data, Pointer(Int64(FData)+Indexes[M]*FRecSize));
    Result:=(D=0);
    if Result then begin L:=M; R:=M; end else if D>0 then L:=M+1 else R:=M;
   end;
  Index:=L;
end;

{TAlignedMemoryStream}

function _aligned_malloc(size: NativeUInt; alignment: NativeUInt): Pointer; cdecl; external 'msvcrt.dll' name '_aligned_malloc';
function _aligned_realloc(memblock: Pointer; size: NativeUInt; alignment: NativeUInt): Pointer; cdecl; external 'msvcrt.dll' name '_aligned_realloc';
procedure _aligned_free(memblock: Pointer); cdecl; external 'msvcrt.dll' name '_aligned_free';

constructor TAlignedMemoryStream.Create(AAlignment: Int64);
begin
  inherited Create;
  if (AAlignment <= 0) or ((AAlignment and (AAlignment - 1)) <> 0) then
    raise EStreamError.Create('Alignment value must be a positive power of two (e.g., 32, 64).');

  FAlignment := AAlignment;
  FMemory := nil;
  FSize := 0;
  FCapacity := 0;
  FPosition := 0;
end;

destructor TAlignedMemoryStream.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TAlignedMemoryStream.Clear;
begin
  SetCapacity(0);
  FSize := 0;
  FPosition := 0;
end;

function TAlignedMemoryStream.Realloc(var NewCapacity: Int64): Pointer;
var
  AlignMask: Int64;
begin
  if NewCapacity > 0 then
  begin
    AlignMask := FAlignment - 1;
    NewCapacity := (NewCapacity + AlignMask) and not AlignMask;
  end;

  Result := FMemory;

  if NewCapacity <> FCapacity then
  begin
    if NewCapacity = 0 then
    begin
      if Result <> nil then
      begin
        _aligned_free(Result);
        Result := nil;
      end;
    end
    else
    begin
      if Result = nil then
        Result := _aligned_malloc(NativeUInt(NewCapacity), NativeUInt(FAlignment))
      else
        Result := _aligned_realloc(Result, NativeUInt(NewCapacity), NativeUInt(FAlignment));

      if Result = nil then
        raise EStreamError.Create('Out of memory allocating aligned stream buffer.');
    end;
  end;
end;

procedure TAlignedMemoryStream.SetCapacity(NewCapacity: Int64);
begin
  FMemory := Realloc(NewCapacity); // Clean and direct
  FCapacity := NewCapacity;
end;

procedure TAlignedMemoryStream.SetSize(const NewSize: Int64);
begin
  if NewSize < 0 then
    raise EStreamError.Create('Stream size cannot be negative.');

  if NewSize > FCapacity then
    SetCapacity(NewSize);

  FSize := NewSize;
  if FPosition > FSize then
    FPosition := FSize;
end;

function TAlignedMemoryStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  case Origin of
    soBeginning: FPosition := Offset;
    soCurrent:   FPosition := FPosition + Offset;
    soEnd:       FPosition := FSize + Offset;
  end;

  if FPosition < 0 then
    FPosition := 0;
  if FPosition > FSize then
    FPosition := FSize;

  Result := FPosition;
end;

function TAlignedMemoryStream.Read(var Buffer; Count: NativeInt): NativeInt;
begin
  if (FPosition >= 0) and (Count > 0) then
  begin
    Result := FSize - FPosition;
    if Result > 0 then
    begin
      if Result > Count then
        Result := Count;

      Move((PByte(FMemory) + FPosition)^, Buffer, Result);

      FPosition := FPosition + Result;
      Exit;
    end;
  end;
  Result := 0;
end;

function TAlignedMemoryStream.Write(const Buffer; Count: NativeInt): NativeInt;
var
  NewPos: Int64;
begin
  if (FPosition >= 0) and (Count > 0) then
  begin
    NewPos := FPosition + Count;
    if NewPos > FCapacity then
      SetCapacity(NewPos);

    Move(Buffer, (PByte(FMemory) + FPosition)^, Count);

    FPosition := NewPos;
    if FPosition > FSize then
      FSize := FPosition;

    Result := Count;
    Exit;
  end;
  Result := 0;
end;

end.
