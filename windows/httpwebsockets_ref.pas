program httpwebsockets_ref;

{$mode delphi}{$H+}
{$codepage UTF8}

uses
  SysUtils,
  Windows,
  WinHttp;

const
  SERVER_NAME = 'ws.postman-echo.com';
  SERVER_PATH = '/raw/';
  SERVER_PORT = INTERNET_DEFAULT_HTTPS_PORT;
  USE_SSL = WINHTTP_FLAG_SECURE; // 0 - for ws, WINHTTP_FLAG_SECURE - for wss
  DATA_TO_SEND = 'Hello world again!';

function ConnectToServer(out hSession: HINTERNET; out hRequest: HINTERNET; out hWebSocket: HINTERNET): Boolean;
var
  hConnection: HINTERNET;
  fStatus: BOOL;
begin
  hSession := WinHttpOpen('freepascalapp', WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, nil, nil, 0);
  if hSession = nil then
    Exit(False);

  hConnection := WinHttpConnect(hSession, SERVER_NAME, SERVER_PORT , 0);
  if hConnection = nil then
  begin
    WinHttpCloseHandle(hSession);
    Exit(False);
  end;

  hRequest := WinHttpOpenRequest(hConnection, 'GET', SERVER_PATH, nil, nil, nil, USE_SSL);
  if hRequest = nil then
  begin
    WinHttpCloseHandle(hSession);
    WinHttpCloseHandle(hConnection);
    Exit(False);
  end;

  fStatus := WinHttpSetOption(hRequest, WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET, nil, 0);
  if not fStatus then
  begin
    WinHttpCloseHandle(hSession);
    WinHttpCloseHandle(hConnection);
    WinHttpCloseHandle(hRequest);
    Exit(False);
  end;

  fStatus := WinHttpSendRequest(hRequest, nil, 0, nil, 0, 0, 0);
  if not fStatus then
  begin
    WinHttpCloseHandle(hSession);
    WinHttpCloseHandle(hConnection);
    WinHttpCloseHandle(hRequest);
    Exit(False);
  end;

  fStatus := WinHttpReceiveResponse(hRequest, nil);
  if not fStatus then
  begin
    WinHttpCloseHandle(hSession);
    WinHttpCloseHandle(hConnection);
    WinHttpCloseHandle(hRequest);
    Exit(False);
  end;

  hWebSocket := WinHttpWebSocketCompleteUpgrade(hRequest, 0);
  Result := hWebSocket <> nil;
end;

function SendWebSocketMessage(hWebSocket: HINTERNET; const message: string): Boolean;
var
  dataToSend: TBytes;
  dwError: DWORD;
begin
  dataToSend := TEncoding.UTF8.GetBytes(message);  
  
  dwError := WinHttpWebSocketSend(hWebSocket, WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE,
    @dataToSend[0], DWord(Length(dataToSend)));

  Result := dwError = ERROR_SUCCESS;
end;

function ReceiveWebSocketMessage(hWebSocket: HINTERNET): string;
const
  BUFFER_SIZE = 1024;
var
  buffer: array[0..BUFFER_SIZE - 1] of Byte;
  dwBufferLength, dwBytesRead: DWORD;
  eBufferType: WINHTTP_WEB_SOCKET_BUFFER_TYPE;
  messageBuffer: TBytes;
begin
  SetLength(messageBuffer, 0);
  dwBufferLength := BUFFER_SIZE;

  repeat
    if not WinHttpWebSocketReceive(hWebSocket, @buffer[0], dwBufferLength, dwBytesRead, eBufferType) = NO_ERROR then
      Break;

    SetLength(messageBuffer, Length(messageBuffer) + dwBytesRead);
    Move(buffer[0], messageBuffer[Length(messageBuffer) - dwBytesRead], SizeInt(dwBytesRead));

  until eBufferType <> WINHTTP_WEB_SOCKET_UTF8_FRAGMENT_BUFFER_TYPE;

  Result := PChar(messageBuffer);
end;

procedure CloseWebSocketConnection(hWebSocket: HINTERNET);
begin
  WinHttpWebSocketClose(hWebSocket, UShort(WINHTTP_WEB_SOCKET_SUCCESS_CLOSE_STATUS), nil, 0);
end;

var
  hSessionHandle, hRequestHandle, hWebSocketHandle: HINTERNET;

begin
  hSessionHandle := nil;
  hRequestHandle := nil;
  hWebSocketHandle := nil;

  if not ConnectToServer(hSessionHandle, hRequestHandle, hWebSocketHandle) then
  begin
    Writeln('Failed to establish connection to the server.');
    ExitCode := -1;
    Exit;
  end;

  Writeln('Successfully upgraded to WebSocket protocol.');

  if not SendWebSocketMessage(hWebSocketHandle, DATA_TO_SEND) then
  begin
    Writeln('Failed to send WebSocket message.');
    ExitCode := -1;
    Exit;
  end;

  Writeln('Sent message to the server: ', DATA_TO_SEND);

  try
    Writeln('Waiting for server response...');
    Writeln('Received message from the server: ', ReceiveWebSocketMessage(hWebSocketHandle));
  except
    on E: Exception do
      Writeln('Failed to receive server response: ', E.Message);
  end;

  CloseWebSocketConnection(hWebSocketHandle);
  Writeln('Closed WebSocket connection.');

  if hRequestHandle <> nil then
    WinHttpCloseHandle(hRequestHandle);

  if hSessionHandle <> nil then
    WinHttpCloseHandle(hSessionHandle);

  Writeln('Application completed successfully.');
  ExitCode := 0;
end.
