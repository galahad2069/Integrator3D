unit CPUTopologyService64;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, AsmUtils64;

// Clean 64-bit structure tracking ONLY performance cores
function GetPCoreAffinityMask64: NativeUInt;
function GetPCoreThreadCount(APCoreMask: NativeUInt): Integer;

implementation

const
  RelationProcessorCore = 0;

type
  TGroupAffinity64 = record
    Mask: NativeUInt; // Full 64-bit mask for pure Win64
    Group: WORD;
    Reserved: array[0..2] of WORD;
  end;

  TProcessorRelationship64 = record
    Flags: BYTE;
    EfficiencyClass: BYTE; // 0 = E-Core, 1+ = P-Core
    Reserved: array[0..19] of BYTE;
    GroupCount: WORD;
    GroupMask: array[0..0] of TGroupAffinity64;
  end;

  TLogicalProcessorInformationEx64 = record
    Relationship: DWORD;
    Size: DWORD;
    Processor: TProcessorRelationship64;
  end;
  PLogicalProcessorInformationEx64 = ^TLogicalProcessorInformationEx64;

function GetLogicalProcessorInformationEx(RelationshipType: DWORD;
  Buffer: PLogicalProcessorInformationEx64; var ReturnedLength: DWORD): BOOL; stdcall;
  external 'kernel32.dll' name 'GetLogicalProcessorInformationEx';

function GetPCoreAffinityMask64: NativeUInt;
var
  BufferLen: DWORD;
  Ptr, BasePtr: PByte;
  CurrentInfo: PLogicalProcessorInformationEx64;
  I: Integer;
begin
  Result := 0;
  BufferLen := 0;

  // Query required heap space size
  if not GetLogicalProcessorInformationEx(RelationProcessorCore, nil, BufferLen) then
  begin
    if GetLastError <> ERROR_INSUFFICIENT_BUFFER then
      RaiseLastOSError;
  end;

  if BufferLen = 0 then Exit;

  GetMem(BasePtr, BufferLen);
  try
    if not GetLogicalProcessorInformationEx(RelationProcessorCore,
      PLogicalProcessorInformationEx64(BasePtr), BufferLen) then
      RaiseLastOSError;

    Ptr := BasePtr;
    while Cardinal(Ptr - BasePtr) < BufferLen do
    begin
      CurrentInfo := PLogicalProcessorInformationEx64(Ptr);

      if CurrentInfo.Relationship = RelationProcessorCore then
      begin
        // If EfficiencyClass > 0, it's an Intel P-Core
        if CurrentInfo.Processor.EfficiencyClass > 0 then
        begin
          for I := 0 to CurrentInfo.Processor.GroupCount - 1 do
          begin
            if CurrentInfo.Processor.GroupMask[I].Group = 0 then
              Result := Result or CurrentInfo.Processor.GroupMask[I].Mask;
          end;
        end;
      end;

      Inc(Ptr, CurrentInfo.Size);
    end;

  finally
    FreeMem(BasePtr);
  end;
end;

function GetPCoreThreadCount(APCoreMask: NativeUInt): Integer;
begin
  Result:=PopCnt(APCoreMask);
  if Result=0 then Result:=TThread.ProcessorCount;
end;

end.
