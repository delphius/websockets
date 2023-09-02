unit websocket;

{$IFDEF FPC}
  {$MODE OBJFPC}
  {$PACKRECORDS C}
  {$H+}
{$ENDIF}

interface

uses
  ctypes,
  windows;

const
  websock_dll = 'websocket.dll';

  WEB_SOCKET_MAX_CLOSE_REASON_LENGTH = 123;
  
  WEB_SOCKET_SEND_ACTION_QUEUE = $1;
  WEB_SOCKET_RECEIVE_ACTION_QUEUE = $2;
  WEB_SOCKET_ALL_ACTION_QUEUE = WEB_SOCKET_SEND_ACTION_QUEUE or
    WEB_SOCKET_RECEIVE_ACTION_QUEUE;

type
  WEB_SOCKET_HANDLE = Pointer;

  WEB_SOCKET_CLOSE_STATUS = (
  // Close completed successfully.
  WEB_SOCKET_SUCCESS_CLOSE_STATUS = 1000,
  // The endpoint is going away and thus closing the connection.
  WEB_SOCKET_ENDPOINT_UNAVAILABLE_CLOSE_STATUS = 1001,
  // Peer detected protocol error and it is closing the connection.
  WEB_SOCKET_PROTOCOL_ERROR_CLOSE_STATUS = 1002,
  // The endpoint cannot receive this type of data.
  WEB_SOCKET_INVALID_DATA_TYPE_CLOSE_STATUS = 1003,
  // No close status code was provided.
  WEB_SOCKET_EMPTY_CLOSE_STATUS = 1005,
  // The connection was closed without sending or receiving a close frame.
  WEB_SOCKET_ABORTED_CLOSE_STATUS = 1006,
  // Data within a message is not consistent with the type of the message.
  WEB_SOCKET_INVALID_PAYLOAD_CLOSE_STATUS = 1007,
  // The message violates an endpoint's policy.
  WEB_SOCKET_POLICY_VIOLATION_CLOSE_STATUS = 1008,
  // The message sent was too large to process.
  WEB_SOCKET_MESSAGE_TOO_BIG_CLOSE_STATUS = 1009,
  // A client endpoint expected the server to negotiate one or more extensions,
  // but the server didn't return them in the response message of the WebSocket handshake.
  WEB_SOCKET_UNSUPPORTED_EXTENSIONS_CLOSE_STATUS = 1010,
  // An unexpected condition prevented the server from fulfilling the request.
  WEB_SOCKET_SERVER_ERROR_CLOSE_STATUS = 1011,
  // The TLS handshake could not be completed.
  WEB_SOCKET_SECURE_HANDSHAKE_ERROR_CLOSE_STATUS = 1015
);


  WEB_SOCKET_PROPERTY_TYPE = (
    WEB_SOCKET_RECEIVE_BUFFER_SIZE_PROPERTY_TYPE = 0,
    WEB_SOCKET_SEND_BUFFER_SIZE_PROPERTY_TYPE = 1,
    WEB_SOCKET_DISABLE_MASKING_PROPERTY_TYPE = 2,
    WEB_SOCKET_ALLOCATED_BUFFER_PROPERTY_TYPE = 3,
    WEB_SOCKET_DISABLE_UTF8_VERIFICATION_PROPERTY_TYPE = 4,
    WEB_SOCKET_KEEPALIVE_INTERVAL_PROPERTY_TYPE = 5,
    WEB_SOCKET_SUPPORTED_VERSIONS_PROPERTY_TYPE = 6
  );

  WEB_SOCKET_ACTION_QUEUE = cardinal;

  WEB_SOCKET_BUFFER_TYPE = (
    WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE = $80000000,
    WEB_SOCKET_UTF8_FRAGMENT_BUFFER_TYPE = $80000001,
    WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE = $80000002,
    WEB_SOCKET_BINARY_FRAGMENT_BUFFER_TYPE = $80000003,
    WEB_SOCKET_CLOSE_BUFFER_TYPE = $80000004,
    WEB_SOCKET_PING_PONG_BUFFER_TYPE = $80000005,
    WEB_SOCKET_UNSOLICITED_PONG_BUFFER_TYPE = $80000006
  );

  WEB_SOCKET_ACTION = (
    WEB_SOCKET_NO_ACTION = 0,
    WEB_SOCKET_SEND_TO_NETWORK_ACTION = 1,
    WEB_SOCKET_INDICATE_SEND_COMPLETE_ACTION = 2,
    WEB_SOCKET_RECEIVE_FROM_NETWORK_ACTION = 3,
    WEB_SOCKET_INDICATE_RECEIVE_COMPLETE_ACTION = 4
  );

  WEB_SOCKET_PROPERTY = record
    PropType: WEB_SOCKET_PROPERTY_TYPE;
    pvValue: Pointer;
    ulValueSize: ULONG;
  end;
  
  PWEB_SOCKET_PROPERTY = ^WEB_SOCKET_PROPERTY;

  PWEB_SOCKET_HTTP_HEADER = ^WEB_SOCKET_HTTP_HEADER;

  WEB_SOCKET_HTTP_HEADER = record
    pcName: PCHAR;
    ulNameLength: ULONG;
    pcValue: PCHAR;
    ulValueLength: ULONG;
  end;

  PWEB_SOCKET_BUFFER = ^WEB_SOCKET_BUFFER;

  WEB_SOCKET_BUFFER = record
    case Integer of
      0: (
        Data: record
          pbBuffer: PBYTE;
          ulBufferLength: ULONG;
        end);
      1: (
        CloseStatus: record
          pbReason: PBYTE;
          ulReasonLength: ULONG;
          usStatus: USHORT;
        end);
  end; 

function WebSocketCreateClientHandle(
  const pProperties: PWEB_SOCKET_PROPERTY;
  ulPropertyCount: ULONG;
  var phWebSocket: WEB_SOCKET_HANDLE
): HRESULT; stdcall; external websock_dll;

function WebSocketBeginClientHandshake(
  hWebSocket: WEB_SOCKET_HANDLE;
  pszSubprotocols: PCSTR;
  ulSubprotocolCount: ULONG;
  pszExtensions: PCSTR;
  ulExtensionCount: ULONG;
  const pInitialHeaders: PWEB_SOCKET_HTTP_HEADER;
  ulInitialHeaderCount: ULONG;
  var pAdditionalHeaders: PWEB_SOCKET_HTTP_HEADER;
  var pulAdditionalHeaderCount: ULONG
): HRESULT; stdcall; external websock_dll;

function WebSocketEndClientHandshake(
  hWebSocket: WEB_SOCKET_HANDLE;
  const pResponseHeaders: PWEB_SOCKET_HTTP_HEADER;
  ulReponseHeaderCount: ULONG;
  var pulSelectedExtensions: ULONG;
  var pulSelectedExtensionCount: ULONG;
  var pulSelectedSubprotocol: ULONG
): HRESULT; stdcall; external websock_dll;

function WebSocketCreateServerHandle(
  const pProperties: PWEB_SOCKET_PROPERTY;
  ulPropertyCount: ULONG;
  var phWebSocket: WEB_SOCKET_HANDLE
): HRESULT; stdcall; external websock_dll;

function WebSocketBeginServerHandshake(
  hWebSocket: WEB_SOCKET_HANDLE;
  pszSubprotocolSelected: PCSTR;
  pszExtensionSelected: PCSTR;
  ulExtensionSelectedCount: ULONG;
  const pRequestHeaders: PWEB_SOCKET_HTTP_HEADER;
  ulRequestHeaderCount: ULONG;
  var pResponseHeaders: PWEB_SOCKET_HTTP_HEADER;
  var pulResponseHeaderCount: ULONG
): HRESULT; stdcall; external websock_dll;

function WebSocketEndServerHandshake(
  hWebSocket: WEB_SOCKET_HANDLE
): HRESULT; stdcall; external websock_dll;

function WebSocketSend(
  hWebSocket: WEB_SOCKET_HANDLE;
  BufferType: WEB_SOCKET_BUFFER_TYPE;
  pBuffer: PWEB_SOCKET_BUFFER;
  pvContext: PVOID
): HRESULT; stdcall; external websock_dll;

function WebSocketReceive(
  hWebSocket: WEB_SOCKET_HANDLE;
  pBuffer: PWEB_SOCKET_BUFFER;
  pvContext: PVOID
): HRESULT; stdcall; external websock_dll;

function WebSocketGetAction(
  hWebSocket: WEB_SOCKET_HANDLE;
  eActionQueue: WEB_SOCKET_ACTION_QUEUE;
  var pDataBuffers: WEB_SOCKET_BUFFER;
  var pulDataBufferCount: ULONG;
  var pAction: WEB_SOCKET_ACTION;
  var pBufferType: WEB_SOCKET_BUFFER_TYPE;
  var pvApplicationContext: PVOID;
  var pvActionContext: PVOID
): HRESULT; stdcall; external websock_dll;

procedure WebSocketCompleteAction(
  hWebSocket: WEB_SOCKET_HANDLE;
  pvActionContext: PVOID;
  ulBytesTransferred: ULONG
); stdcall; external websock_dll;

procedure WebSocketAbortHandle(
  hWebSocket: WEB_SOCKET_HANDLE
); stdcall; external websock_dll;

procedure WebSocketDeleteHandle(
  hWebSocket: WEB_SOCKET_HANDLE
); stdcall; external websock_dll;

function WebSocketGetGlobalProperty(
  eType: WEB_SOCKET_PROPERTY_TYPE;
  var pvValue: PVOID;
  var ulSize: ULONG
): HRESULT; stdcall; external websock_dll;

implementation

end.
