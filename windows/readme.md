# Windows specific examples

## winhttp.dll - [Overview](https://learn.microsoft.com/en-us/archive/msdn-magazine/2012/december/windows-8-networking-windows-8-and-the-websocket-protocol)

rewriten example from [here](https://github.com/microsoft/Windows-classic-samples/tree/main/Samples/WinhttpWebsocket)

[httpwebsockets.pas](https://github.com/delphius/websockets/blob/main/windows/httpwebsockets.pas) - in plain style

[httpwebsockets_ref.pas](https://github.com/delphius/websockets/blob/main/windows/httpwebsockets_ref.pas) - in procedural style

[winhttp.pp](https://gitlab.com/freepascal.org/fpc/source/-/blob/main/packages/winunits-base/src/winhttp.pp?ref_type=heads) is a pascal wraper to `winhttp.dll` and a part of fpc unit `winutils-base`

## websockets.dll - [Overview](https://learn.microsoft.com/en-us/windows/win32/websock/web-socket-protocol-component-api-portal?source=recommendations)

rewriten example from [here](https://github.com/microsoft/Windows-classic-samples/tree/main/Samples/Websocket)

[winwebsockets.pas](https://github.com/delphius/websockets/blob/main/windows/websockets.dll/winwebsockets.pas) - in procedural style

websocket.dll provides support for client and server handshake related HTTP headers, verifies received handshake data, and parses the WebSocket data stream. It **does not handle** any HTTP-specific operations (redirection, authentication, proxy support) **nor perform any I/O operations** (sending or receiving WebSocket stream bytes).

But based on this example, you can understand how the protocol functions or use it for low-level message encoding/decoding and establishing a connection (handshake)

[websocket.pas](https://github.com/delphius/websockets/blob/main/windows/websockets.dll/websocket.pas) is a pascal wraper to `websocket.dll`
