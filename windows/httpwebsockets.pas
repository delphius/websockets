program httpwebsockets;

{$mode delphi}{$H+}
{$codepage UTF8}

uses
  SysUtils,
  Windows,
  WinHttp;

function GetWinHttpErrorDescription(dwError: DWORD): string;
begin
  case dwError of
    12178: Result := 'ERROR_WINHTTP_AUTO_PROXY_SERVICE_ERROR';
    12180: Result := 'ERROR_WINHTTP_AUTODETECTION_FAILED';
    12166: Result := 'ERROR_WINHTTP_BAD_AUTO_PROXY_SCRIPT';
    12103: Result := 'ERROR_WINHTTP_CANNOT_CALL_AFTER_OPEN';
    12102: Result := 'ERROR_WINHTTP_CANNOT_CALL_AFTER_SEND';
    12100: Result := 'ERROR_WINHTTP_CANNOT_CALL_BEFORE_OPEN';
    12101: Result := 'ERROR_WINHTTP_CANNOT_CALL_BEFORE_SEND';
    12029: Result := 'ERROR_WINHTTP_CANNOT_CONNECT';
    12044: Result := 'ERROR_WINHTTP_CLIENT_AUTH_CERT_NEEDED';
    12030: Result := 'ERROR_WINHTTP_CONNECTION_ERROR';
    12183: Result := 'ERROR_WINHTTP_CHUNKED_ENCODING_HEADER_SIZE_OVERFLOW';
    12155: Result := 'ERROR_WINHTTP_HEADER_ALREADY_EXISTS';
    12181: Result := 'ERROR_WINHTTP_HEADER_COUNT_EXCEEDED';
    12150: Result := 'ERROR_WINHTTP_HEADER_NOT_FOUND';
    12182: Result := 'ERROR_WINHTTP_HEADER_SIZE_OVERFLOW';
    12019: Result := 'ERROR_WINHTTP_INCORRECT_HANDLE_STATE';
    12018: Result := 'ERROR_WINHTTP_INCORRECT_HANDLE_TYPE';
    12004: Result := 'ERROR_WINHTTP_INTERNAL_ERROR';
    12009: Result := 'ERROR_WINHTTP_INVALID_OPTION';
    12154: Result := 'ERROR_WINHTTP_INVALID_QUERY_REQUEST';
    12152: Result := 'ERROR_WINHTTP_INVALID_SERVER_RESPONSE';
    12005: Result := 'ERROR_WINHTTP_INVALID_URL';
    12015: Result := 'ERROR_WINHTTP_LOGIN_FAILURE';
    12007: Result := 'ERROR_WINHTTP_NAME_NOT_RESOLVED';
    12172: Result := 'ERROR_WINHTTP_NOT_INITIALIZED';
    12017: Result := 'ERROR_WINHTTP_OPERATION_CANCELLED';
    12011: Result := 'ERROR_WINHTTP_OPTION_NOT_SETTABLE';
    12001: Result := 'ERROR_WINHTTP_OUT_OF_HANDLES';
    12156: Result := 'ERROR_WINHTTP_REDIRECT_FAILED';
    12032: Result := 'ERROR_WINHTTP_RESEND_REQUEST';
    12184: Result := 'ERROR_WINHTTP_RESPONSE_DRAIN_OVERFLOW';
    12177: Result := 'ERROR_WINHTTP_SCRIPT_EXECUTION_ERROR';
    12038: Result := 'ERROR_WINHTTP_SECURE_CERT_CN_INVALID';
    12037: Result := 'ERROR_WINHTTP_SECURE_CERT_DATE_INVALID';
    12057: Result := 'ERROR_WINHTTP_SECURE_CERT_REV_FAILED';
    12170: Result := 'ERROR_WINHTTP_SECURE_CERT_REVOKED';
    12179: Result := 'ERROR_WINHTTP_SECURE_CERT_WRONG_USAGE';
    12157: Result := 'ERROR_WINHTTP_SECURE_CHANNEL_ERROR';
    12175: Result := 'ERROR_WINHTTP_SECURE_FAILURE';
    12045: Result := 'ERROR_WINHTTP_SECURE_INVALID_CA';
    12169: Result := 'ERROR_WINHTTP_SECURE_INVALID_CERT';
    12012: Result := 'ERROR_WINHTTP_SHUTDOWN';
    12002: Result := 'ERROR_WINHTTP_TIMEOUT';
    12167: Result := 'ERROR_WINHTTP_UNABLE_TO_DOWNLOAD_SCRIPT';
    12176: Result := 'ERROR_WINHTTP_UNHANDLED_SCRIPT_TYPE';
    12006: Result := 'ERROR_WINHTTP_UNRECOGNIZED_SCHEME';
    ERROR_INVALID_PARAMETER: Result := 'ERROR_INVALID_PARAMETER';
    ERROR_NOT_ENOUGH_MEMORY: Result := 'ERROR_NOT_ENOUGH_MEMORY';
    ERROR_INSUFFICIENT_BUFFER: Result := 'ERROR_INSUFFICIENT_BUFFER';
    ERROR_INVALID_HANDLE: Result := 'ERROR_INVALID_HANDLE';
    ERROR_NO_MORE_FILES: Result := 'ERROR_NO_MORE_FILES';
    ERROR_NO_MORE_ITEMS: Result := 'ERROR_NO_MORE_ITEMS';
    ERROR_NOT_SUPPORTED: Result := 'ERROR_NOT_SUPPORTED';
    else
      Result := Format('Unknown error code: %u', [dwError]);
  end;
end;

var
  fStatus: BOOL;
  hSessionHandle, hConnectionHandle, hRequestHandle, hWebSocketHandle: HINTERNET;
  rgbBuffer: array[0..1023] of Byte;
  rgbCloseReasonBuffer: array[0..122] of Byte;
  sDataToSend: String;
  dataToSend: array of Byte;
  pbCurrentBufferPointer, pbCloseReasonBufferPointer: PByte;
  dwError, dwBufferLength, dwBytesTransferred, dwCloseReasonLength, pdwReasonLengthConsumed: DWORD;
  usStatus: USHORT;
  eBufferType: WINHTTP_WEB_SOCKET_BUFFER_TYPE;
  Port: INTERNET_PORT;
  pcwszServerName, pcwszPath: PWideChar;
  i: Integer;

begin
  dwError := ERROR_SUCCESS;
  fStatus := FALSE;
  hSessionHandle := nil;
  hConnectionHandle := nil;
  hRequestHandle := nil;
  hWebSocketHandle := nil;
  pbCurrentBufferPointer := @rgbBuffer;
  dwBufferLength := SizeOf(rgbBuffer);
  pbCloseReasonBufferPointer := @rgbCloseReasonBuffer;
  dwCloseReasonLength := SizeOf(rgbCloseReasonBuffer);
  dwBytesTransferred := 0;
  usStatus := 0;
  eBufferType := WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE;
  Port := INTERNET_DEFAULT_HTTPS_PORT;
  pcwszServerName := 'ws.postman-echo.com';
  pcwszPath := '/raw/';
  sDataToSend := 'Hello world again!';
  SetLength(dataToSend, Length(sDataToSend));
  for i := 0 to High(dataToSend) do
    dataToSend[i] := Byte(sDataToSend[i + 1]);

  hSessionHandle := WinHttpOpen('WebSocket sample', WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, nil, nil, 0);
  if hSessionHandle = nil then
  begin
    dwError := GetLastError();
    Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
    ExitCode := -1;
    Exit;
  end;
  
  hConnectionHandle := WinHttpConnect(hSessionHandle, pcwszServerName, Port, 0);
  if hConnectionHandle = nil then
  begin
    dwError := GetLastError();
    Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
    ExitCode := -1;
    Exit;
  end;
  
  // Open secure request (WINHTTP_FLAG_SECURE)
  hRequestHandle := WinHttpOpenRequest(hConnectionHandle, 'GET', pcwszPath, nil, nil, nil, WINHTTP_FLAG_SECURE);
  if hRequestHandle = nil then
  begin
    dwError := GetLastError();
    Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
    ExitCode := -1;
    Exit;
  end;

  fStatus := WinHttpSetOption(hRequestHandle, WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET, nil, 0);

  if not fStatus then
  begin
    dwError := GetLastError();
    Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
    ExitCode := -1;
    Exit;
  end;
  
  fStatus := WinHttpSendRequest(hRequestHandle, nil, 0, nil, 0, 0, 0);
  if not fStatus then
  begin
    dwError := GetLastError();
    Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
    ExitCode := -1;
    Exit;
  end;
  
  fStatus := WinHttpReceiveResponse(hRequestHandle, nil);
  if not fStatus then
  begin
    dwError := GetLastError();
    Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
    ExitCode := -1;
    Exit;
  end;
  
  hWebSocketHandle := WinHttpWebSocketCompleteUpgrade(hRequestHandle, 0);
  if hWebSocketHandle = nil then
  begin
    dwError := GetLastError();
    Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
    ExitCode := -1;
    Exit;
  end;
 
  WinHttpCloseHandle(hRequestHandle);
  hRequestHandle := nil;

  WriteLn('Succesfully upgraded to websocket protocol');
  
  dwError := WinHttpWebSocketSend(hWebSocketHandle, eBufferType, @dataToSend[0], DWord(Length(dataToSend)));
  if dwError <> ERROR_SUCCESS then
  begin
    Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
    ExitCode := -1;
    Exit;
  end;

  WriteLn('Sent message to the server: ', sDataToSend);

  repeat
    if dwBufferLength = 0 then
    begin
      dwError := ERROR_NOT_ENOUGH_MEMORY;
      Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
      ExitCode := -1;
      Exit;
    end;
 
    dwError := WinHttpWebSocketReceive(hWebSocketHandle, pbCurrentBufferPointer, dwBufferLength,
      dwBytesTransferred, eBufferType);
    if dwError <> ERROR_SUCCESS then
    begin
      Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
      ExitCode := -1;
      Exit;
    end;

    pbCurrentBufferPointer := pbCurrentBufferPointer + dwBytesTransferred;
    dwBufferLength := DWord(dwBufferLength - dwBytesTransferred);
  until eBufferType <> WINHTTP_WEB_SOCKET_UTF8_FRAGMENT_BUFFER_TYPE;

  if eBufferType <> WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE then
  begin
    WriteLn('Unexpected buffer type');
    dwError := ERROR_INVALID_PARAMETER;
    Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
    ExitCode := -1;
    Exit;
  end;

  WriteLn('Received message from the server: ', PChar(@rgbBuffer));
  
  dwError := WinHttpWebSocketClose(hWebSocketHandle, UShort(WINHTTP_WEB_SOCKET_SUCCESS_CLOSE_STATUS), nil, 0);
  if dwError <> ERROR_SUCCESS then
  begin
    Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
    ExitCode := -1;
    Exit;
  end;
  
  dwError := WinHttpWebSocketQueryCloseStatus(hWebSocketHandle, usStatus, pbCloseReasonBufferPointer,
    dwCloseReasonLength, pdwReasonLengthConsumed);
  if dwError <> ERROR_SUCCESS then
  begin
    Writeln('Application failed with error: ', GetWinHttpErrorDescription(dwError));
    ExitCode := -1;
    Exit;
  end;
  
  Writeln('The server closed the connection with status code: ', usStatus);
  
  if hRequestHandle <> nil then
    WinHttpCloseHandle(hRequestHandle);

  if hWebSocketHandle <> nil then
    WinHttpCloseHandle(hWebSocketHandle);

  if hConnectionHandle <> nil then
    WinHttpCloseHandle(hConnectionHandle);

  if hSessionHandle <> nil then
    WinHttpCloseHandle(hSessionHandle);

  if dwError <> ERROR_SUCCESS then
  begin
    WriteLn('Application failed with error: ', GetWinHttpErrorDescription(dwError));
    ExitCode := -1;
  end
  else
    WriteLn('Application completed successfully.');
    ExitCode := 0;
end.
