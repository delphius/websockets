program winwebsockets;

{$mode delphi}{$H+}
{$codepage UTF8}

uses
  SysUtils,
  Windows,
  websocket,
  transport;

procedure DumpHeaders(headers: PWEB_SOCKET_HTTP_HEADER; headerCount: ULONG);
var
  i: ULONG;
begin
  for i := 0 to headerCount - 1 do
  begin
    Writeln(Format('%.*S: %.*S', [headers^.ulNameLength, headers^.pcName,
                                  headers^.ulValueLength, headers^.pcValue]));

    Inc(headers); // Перемещаем указатель на следующую структуру
  end;
  Writeln;
end;


procedure DumpData(data: PByte; dataLength: ULONG);
var
  i: ULONG;
begin
  if data = nil then
  begin
    Writeln('No data to dump');
    Exit;
  end;
  for i := 0 to dataLength - 1 do
  begin
    Write(Format('0x%x ', [data[i]]));
  end;
  Writeln;
  Writeln;
end;

function Initialize(out clientHandle, serverHandle: WEB_SOCKET_HANDLE): HRESULT;
var
  hr: HRESULT;
  clientH, serverH: WEB_SOCKET_HANDLE;
begin
  clientHandle := nil;
  serverHandle := nil;
  
  hr := WebSocketCreateClientHandle(nil, 0, clientH);
  if Failed(hr) then
    Exit(hr);
  
  hr := WebSocketCreateServerHandle(nil, 0, serverH);
  if Failed(hr) then
  begin
    WebSocketDeleteHandle(clientH);
    Exit(hr);
  end;
  
  clientHandle := clientH;
  serverHandle := serverH;
  
  Result := S_OK;
end;

function PerformHandshake(clientHandle, serverHandle: WEB_SOCKET_HANDLE): HRESULT;
const
  MaxClientHeaders = 10; // Максимальное количество заголовков
var
  hr: HRESULT;
  clientAdditionalHeaderCount, serverAdditionalHeaderCount: ULONG;
  clientAdditionalHeaders, serverAdditionalHeaders: PWEB_SOCKET_HTTP_HEADER;
  host: WEB_SOCKET_HTTP_HEADER;
  clientHeaderCount, i, pulSelectedExtensions, pulSelectedExtensionCount, pulSelectedSubprotocol: ULONG;
  clientHeaders: array [0..MaxClientHeaders - 1] of WEB_SOCKET_HTTP_HEADER;
begin
  clientAdditionalHeaderCount := 0;
  serverAdditionalHeaderCount := 0;
  clientAdditionalHeaders := nil;
  serverAdditionalHeaders := nil;

  // Заполните host структуру
  host.pcName := 'Host';
  host.ulNameLength := Length(host.pcName);
  host.pcValue := 'localhost';
  host.ulValueLength := Length(host.pcValue);

  hr := WebSocketBeginClientHandshake(clientHandle, nil, 0, nil, 0, nil, 0,
    clientAdditionalHeaders, clientAdditionalHeaderCount);
  if Failed(hr) then
    Exit(hr);

  // Создайте массив clientHeaders
  clientHeaderCount := clientAdditionalHeaderCount + 1;

  // Копируйте дополнительные заголовки (если есть)
  for i := 0 to clientAdditionalHeaderCount - 1 do
  begin
    clientHeaders[i] := clientAdditionalHeaders^;
    Inc(clientAdditionalHeaders);
  end;

  // Добавьте заголовок "Host"
  clientHeaders[clientAdditionalHeaderCount] := host;

  // Выведите заголовки в консоль
  Writeln('-- Заголовки со стороны клиента, которые будут отправлены с запросом --');
  DumpHeaders(@clientHeaders[0], clientHeaderCount);

  // Вызовите WebSocketBeginServerHandshake
  hr := WebSocketBeginServerHandshake(serverHandle, nil, nil, 0, @clientHeaders[0],
    clientHeaderCount, serverAdditionalHeaders, serverAdditionalHeaderCount);
  if Failed(hr) then
    Exit(hr);

  // Выведите заголовки в консоль
  Writeln('-- Заголовки со стороны сервера, которые будут отправлены с ответом --');
  DumpHeaders(serverAdditionalHeaders, serverAdditionalHeaderCount);

  // Завершите рукопожатие
  hr := WebSocketEndClientHandshake(clientHandle, serverAdditionalHeaders,
    serverAdditionalHeaderCount, pulSelectedExtensions, pulSelectedExtensionCount, pulSelectedSubprotocol);
  if Failed(hr) then
    Exit(hr);

  hr := WebSocketEndServerHandshake(serverHandle);
  if Failed(hr) then
  begin
    Writeln('4');
    Exit(hr);
  end;

  Result := S_OK;
end;


function RunLoop(handle: WEB_SOCKET_HANDLE; transport: TTransport): HRESULT;
var
  hr: HRESULT;
  buffers: array[0..1] of WEB_SOCKET_BUFFER;
  bufferCount, bytesTransferred, i: ULONG;
  bufferType: WEB_SOCKET_BUFFER_TYPE;
  action: WEB_SOCKET_ACTION;
  actionContext, applicationContext: Pointer;

begin
  repeat
    bufferCount := Length(buffers);
    for i := 0 to bufferCount - 1 do
      begin
        buffers[i].Data.pbBuffer := Nil;
        buffers[i].Data.ulBufferLength := 0;
      end;
    bytesTransferred := 0;

    hr := WebSocketGetAction(handle, WEB_SOCKET_ALL_ACTION_QUEUE, buffers[0], bufferCount,
      action, bufferType, applicationContext, actionContext);
    
    if Failed(hr) then
      begin
        WebSocketAbortHandle(handle);
      end;

    case action of
      WEB_SOCKET_NO_ACTION:
        begin
          // No action to perform - exit the loop.
        end;

      WEB_SOCKET_RECEIVE_FROM_NETWORK_ACTION:
        begin
          Writeln('Получение данных из сети:');

          for i := 0 to bufferCount - 1 do
          begin
            hr := transport.ReadData(buffers[i].Data.ulBufferLength, bytesTransferred,
              buffers[i].Data.pbBuffer);
            if Failed(hr) then
              Break;

            DumpData(buffers[i].Data.pbBuffer, bytesTransferred);

            if buffers[i].Data.ulBufferLength > bytesTransferred then
              Break;
          end;
        end;

      WEB_SOCKET_INDICATE_RECEIVE_COMPLETE_ACTION:
        begin
          Writeln('Операция получения завершилась буфером:');

          if bufferCount <> 1 then
          begin
            Result := E_FAIL;
            Exit;
          end;

          DumpData(buffers[0].Data.pbBuffer, buffers[0].Data.ulBufferLength);
        end;

      WEB_SOCKET_SEND_TO_NETWORK_ACTION:
        begin
          Writeln('Отправка данных по сети:');

          for i := 0 to bufferCount - 1 do
          begin
            DumpData(buffers[i].Data.pbBuffer, buffers[i].Data.ulBufferLength);

            hr := transport.WriteData(buffers[i].Data.pbBuffer, buffers[i].Data.ulBufferLength);
            if Failed(hr) then
              Break;

            Inc(bytesTransferred, buffers[i].Data.ulBufferLength);
          end;
        end;

      WEB_SOCKET_INDICATE_SEND_COMPLETE_ACTION:
        begin
          Writeln('Операция отправки завершена');
        end;

      else
        begin
          Result := E_FAIL;
          Exit;
        end;
    end;

    if Failed(hr) then
    begin
      WebSocketAbortHandle(handle);
    end;

    WebSocketCompleteAction(handle, actionContext, bytesTransferred);
  until action = WEB_SOCKET_NO_ACTION;

  Result := S_OK;
end;

function PerformDataExchange(clientHandle, serverHandle: WEB_SOCKET_HANDLE;
  transport: TTransport): HRESULT;
var
  hr: HRESULT;
  dataToSend: array[0..10] of Byte;
  buffer: WEB_SOCKET_BUFFER;
  i: Integer;
begin
  for i := 0 to High(dataToSend) do
    dataToSend[i] := Byte('Hello World'[i + 1]);

  buffer.Data.pbBuffer := @dataToSend;
  buffer.Data.ulBufferLength := Length(dataToSend);

  Writeln('-- Постановка отправки в очередь с использованием буфера --');
  DumpData(buffer.Data.pbBuffer, buffer.Data.ulBufferLength);
  hr := WebSocketSend(clientHandle, WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE, @buffer, nil);
  if Failed(hr) then
    Exit(hr);
  hr := RunLoop(clientHandle, transport);
  if Failed(hr) then
    Exit(hr);

  Writeln('-- Постановка в очередь на получение --');

  hr := WebSocketReceive(serverHandle, nil, nil);
  if Failed(hr) then
    Exit(hr);

  hr := RunLoop(serverHandle, transport);
  if Failed(hr) then
    Exit(hr);

  Result := S_OK;
end;

var
  hr: HRESULT;
  clientHandle, serverHandle: WEB_SOCKET_HANDLE;
  transport: TTransport;
begin
  transport := TTransport.Create;

  hr := Initialize(clientHandle, serverHandle);
  if Failed(hr) then
    Halt;

  try
    hr := PerformHandshake(clientHandle, serverHandle);
    if Failed(hr) then
      Halt;

    hr := PerformDataExchange(clientHandle, serverHandle, transport);
    if Failed(hr) then
      Halt;
  finally
    WebSocketDeleteHandle(clientHandle);
    WebSocketDeleteHandle(serverHandle);
  end;

  if Failed(hr) then
    Writeln(Format('Сбой соединения Websocket с ошибкой 0x%x', [hr]))
  else
    Writeln('Соединение Websocket завершилось успешно');

  if Failed(hr) then
    Halt(0)
  else
    Halt(1);
end.
