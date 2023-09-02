unit Transport;

interface

uses
  Windows, Classes, SysUtils;

type
  PListEntry = ^ListEntry;
  ListEntry = record
    Data: PByte;
    DataLength: ULONG;
    Next: PListEntry;
  end;

  TTransport = class
  private
    FLock: TRTLCriticalSection;
    FList: PListEntry;

  public
    constructor Create;
    destructor Destroy; override;
    function WriteData(data: PByte; dataLength: ULONG): HRESULT;
    function ReadData(dataLength: ULONG; var outputDataLength: ULONG; data: PByte): HRESULT;
  end;

implementation

constructor TTransport.Create;
begin
  InitializeCriticalSection(FLock);
  FList := nil;
end;

destructor TTransport.Destroy;
var
  current, next: PListEntry;
begin
  DeleteCriticalSection(FLock);
  current := FList;
  while current <> nil do
  begin
    next := current^.Next;
    FreeMem(current^.Data);
    Dispose(current);
    current := next;
  end;
  inherited;
end;

function TTransport.WriteData(data: PByte; dataLength: ULONG): HRESULT;
var
  entry: PListEntry;
  buffer: PByte;
begin
  Result := S_OK;
  if data = nil then
    Exit;

  New(entry);
  if entry = nil then
  begin
    Result := E_OUTOFMEMORY;
    Exit;
  end;

  GetMem(buffer, dataLength);
  if buffer = nil then
  begin
    Dispose(entry);
    Result := E_OUTOFMEMORY;
    Exit;
  end;

  Move(data^, buffer^, SizeInt(dataLength));
  entry^.Data := buffer;
  entry^.DataLength := dataLength;
  entry^.Next := nil;

  EnterCriticalSection(FLock);
  if FList = nil then
    FList := entry
  else
  begin
    entry^.Next := FList;
    FList := entry;
  end;
  LeaveCriticalSection(FLock);
end;

function TTransport.ReadData(dataLength: ULONG; var outputDataLength: ULONG; data: PByte): HRESULT;
var
  index: ULONG;
  current, next: PListEntry;
begin
  outputDataLength := 0;
  index := 0;

  if data = nil then
  begin
    Result := E_FAIL;
    Exit;
  end;

  EnterCriticalSection(FLock);

  current := FList;
  while (index < dataLength) and (current <> nil) do
  begin
    Move(current^.Data^, data[index], SizeInt(current^.DataLength));
    Inc(index, current^.DataLength);
    next := current^.Next;

    FreeMem(current^.Data);
    Dispose(current);
    current := next;
  end;

  FList := current;

  LeaveCriticalSection(FLock);

  outputDataLength := index;
  Assert(outputDataLength <> 0);
  Result := S_OK;
end;

end.