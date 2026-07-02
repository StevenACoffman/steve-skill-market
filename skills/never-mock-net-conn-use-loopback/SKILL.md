---
name: never-mock-net-conn-use-loopback
description: |
  Invoke when production code tests networked Go code by mocking net.Conn, net.Listener, or net.Dial. Invoke when choosing between loopback TCP, net.Pipe, and bufconn for testing connection-oriented protocols. Covers the testConn helper pattern, real SSH server in-process testing, and when to use net/http/httptest instead.
tags: [go, testing, networking, tcp, mocking, testable-code]
---

# Never Mock net.Conn — Use Loopback or Pipe

## R — Rule

**Testing networking? Make a real network connection. Don't mock `net.Conn`.**

Mitchell Hashimoto is direct about this: "There is no reason to ever mock `net.Conn`." `net.Conn` is an interface, which makes it a syntactically obvious mock target. Early Go code (circa 2012) frequently mocked it. HashiCorp never did, and the reason is simple: a real loopback TCP pair is approximately 10 lines of code and tests actual protocol behavior. A mock tests the mock.

The canonical helper from the book:

```go
// Error checking omitted for brevity
func testConn(t *testing.T) (client, server net.Conn) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	var server net.Conn
	go func() {
		defer ln.Close()
		server, err = ln.Accept()
	}()
	client, err := net.Dial("tcp", ln.Addr().String())
	return client, server
}
```

Key observations from the book:

- That was a one-connection example; easy to make an N-connection helper
- Easy to test any protocol
- Easy to return the listener as well
- Easy to test IPv6 if needed
- There is no reason to ever mock `net.Conn`

______________________________________________________________________

## I — Insight

`net.Conn` is an interface with `Read`, `Write`, and `Close` methods. That interface definition is visually identical to `io.ReadWriteCloser`. When Go developers see an interface they instinctively think: "I can mock this." The mock is usually a `bytes.Buffer` wrapped in a struct that satisfies the interface.

The instinct is wrong here, and for a specific reason: a `bytes.Buffer` does not behave like a TCP connection. TCP connections have semantics that `bytes.Buffer` cannot reproduce:

- **Partial reads**: TCP may deliver fewer bytes than requested in a single `Read` call; `bytes.Buffer.Read` returns everything available at once.
- **Blocking reads**: A real `net.Conn` blocks on `Read` until data arrives or the connection closes; a `bytes.Buffer` returns `io.EOF` immediately when empty.
- **Connection close semantics**: Writing to a closed `net.Conn` returns an error on the next write; this is not reproduced by a buffer.
- **Half-close**: `net.TCPConn.CloseWrite()` signals EOF to the remote side while the connection remains open for reading. A buffer has no equivalent.

A protocol parser or framing layer that works correctly against a `bytes.Buffer` mock may fail silently against real TCP. The mock tests the mock.

Port 0 is the key that makes the loopback pattern cheap: `net.Listen("tcp", "127.0.0.1:0")` asks the OS to assign any available port. There are no hardcoded port numbers, no port conflicts across parallel test runs (if you use multiple processes), and no cleanup of port reservations needed.

The goroutine structure is also significant: `ln.Accept()` blocks until a client connects, so it runs in a goroutine. `net.Dial` then connects from the main test goroutine. After the goroutine returns the accepted connection, both ends are live and the test can proceed with a real bidirectional TCP channel.

______________________________________________________________________

## A1 — Applications

### Case 1: testConn Helper — Reusable Loopback Pair for Any Protocol (C13)

HashiCorp uses the `testConn` pattern as a general-purpose helper for any code that works with `net.Conn`. A single call returns two live connection ends: the test writes to `client` and reads from `server` (or vice versa) exactly as production code would. Because the helper follows the test helper contract — it accepts `*testing.T`, calls `t.Fatalf` on any error, and never returns an error — the test body contains zero setup boilerplate beyond `client, server := testConn(t)`.

The author notes the pattern composes naturally with the cleanup func pattern: adding `defer client.Close(); defer server.Close()` is all the teardown needed.

### Case 2: Packer SSH Testing — Real SSH Server in-Process (C14)

HashiCorp's Packer project tests SSH connection handling using an extended version of the same pattern. Rather than returning a bare `net.Conn` pair, Packer creates a real in-process SSH server:

1. `net.Listen` on a loopback port
2. A goroutine runs the SSH server handshake on the accepted connection
3. The test dials with a real SSH client
4. Both ends of the authenticated SSH session are returned to the test

This tests actual SSH protocol behavior: key exchange, authentication, channel negotiation. A mock would test nothing real about the protocol. The author quotes this directly: "we actually in Packer for example we have this to test SSH connections and the way we test SSH connections is we create a real SSH server we create a listener we connect to it we shut down the SSH so we return the two connections and so you have a real SSH connection."

The Packer case shows the pattern scales to complex application-layer protocols, not just raw byte streams.

______________________________________________________________________

## A2 — Activation

Apply this skill whenever you see any of the following:

- "I need to test my custom protocol parser. Should I mock `net.Conn` with a `bytes.Buffer`?"
- "How do I test my TCP server/client without starting a real server?"
- "I want to test my gRPC/WebSocket/custom protocol code in unit tests. Should I implement a mock connection?"
- Code that implements a protocol over `net.Conn` (framing, encoding, state machines) where test coverage is being discussed
- A `MockConn` struct or similar type that wraps a `bytes.Buffer` and implements `Read`/`Write`/`Close`
- A test that calls `strings.NewReader` or `bytes.NewBuffer` and casts the result to something that mimics a connection
- The phrase "I'll just mock the connection" when discussing network-protocol unit tests

In all these cases: stop the mock, write `testConn`.

______________________________________________________________________

## E — Execution

### Step 1: Write the testConn Helper

```go
func testConn(t *testing.T) (net.Conn, net.Conn) {
	t.Helper()
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("testConn: listen failed: %v", err)
	}

	// Accept one connection in a goroutine (Accept blocks).
	var server net.Conn
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		var err error
		server, err = ln.Accept()
		if err != nil {
			t.Errorf("testConn: accept failed: %v", err)
		}
		ln.Close()
	}()

	client, err := net.Dial("tcp", ln.Addr().String())
	if err != nil {
		t.Fatalf("testConn: dial failed: %v", err)
	}
	wg.Wait()
	return client, server
}
```

Key points:

- `t.Helper()` marks this as a helper so failure lines point to the call site, not into `testConn`.
- `sync.WaitGroup` ensures `server` is assigned before `testConn` returns. (The original book example omits error checking for brevity; the above is production-quality.)
- `ln.Close()` inside the goroutine ensures the listener is released after one connection.
- Port 0 — OS assigns the port. No hardcoded numbers.

### Step 2: Use It in a Test

```go
func TestMyProtocol_Read(t *testing.T) {
	client, server := testConn(t)
	defer client.Close()
	defer server.Close()

	// Write from the client side.
	msg := []byte("hello\n")
	if _, err := client.Write(msg); err != nil {
		t.Fatalf("write: %v", err)
	}

	// Read on the server side.
	buf := make([]byte, len(msg))
	if _, err := io.ReadFull(server, buf); err != nil {
		t.Fatalf("read: %v", err)
	}

	if string(buf) != string(msg) {
		t.Errorf("got %q, want %q", buf, msg)
	}
}
```

### Step 3: Test Your Actual Protocol Code

Inject the loopback connection into the code under test exactly as production would inject a real network connection:

```go
func TestFrameDecoder(t *testing.T) {
	client, server := testConn(t)
	defer client.Close()
	defer server.Close()

	// Run the frame encoder on one side.
	enc := NewFrameEncoder(client)
	dec := NewFrameDecoder(server)

	want := []byte("payload data")
	if err := enc.WriteFrame(want); err != nil {
		t.Fatalf("encode: %v", err)
	}

	got, err := dec.ReadFrame()
	if err != nil {
		t.Fatalf("decode: %v", err)
	}
	if !bytes.Equal(got, want) {
		t.Errorf("got %q, want %q", got, want)
	}
}
```

The `FrameDecoder` and `FrameEncoder` under test see a real `net.Conn`. Partial read behavior, blocking, and connection-close handling are all exercised.

______________________________________________________________________

## B — Boundaries

### Where This Pattern Applies

This pattern is specifically for **`net.Conn`** (TCP, Unix socket, or any connection-oriented transport). Use it whenever code operates at the `net.Conn` level: custom binary protocols, line-based protocols, framing layers, SSH, custom RPC.

### Where to Use Different Tools Instead

**HTTP**: Do not use `testConn` for HTTP handlers or clients. Use `net/http/httptest.NewServer()` (for server testing) or `httptest.NewRecorder()` (for handler unit tests). These are the standard library's dedicated equivalents for HTTP and handle HTTP-specific concerns (headers, keep-alive, TLS) that a bare `net.Conn` pair does not.

**UDP**: The loopback pattern needs adaptation for UDP. `net.Conn` semantics are connection-oriented; UDP uses `net.PacketConn`. A similar loopback approach works but requires `net.ListenPacket` and `net.DialUDP` rather than `net.Listen`/`net.Dial`.

**gRPC**: gRPC has its own test helpers (`google.golang.org/grpc/test/bufconn`) that create an in-memory connection. For gRPC specifically, `bufconn` is the appropriate tool.

**Confusion with TestHelperProcess**: Both this pattern and `TestHelperProcess` share the same underlying philosophy — reject shallow mocks in favor of real implementations. But they solve different problems. `testConn` mocks nothing; it provides a real TCP channel. `TestHelperProcess` provides a real subprocess (the test binary re-executing itself). Neither pattern creates a simulation; both create a real instance of the thing under test.

### What This Does NOT Cover

- The author did not mention `net/http/httptest` in this talk. It is the correct answer for HTTP and is a blind spot in the source material.
- This pattern does not address TLS testing directly — for that, `crypto/tls.Server` / `crypto/tls.Client` can wrap the loopback `net.Conn` pair, but setup is more involved.
- The ~10-line estimate refers to the bare minimum (as shown in the book). A production-quality version with `sync.WaitGroup` and proper error handling is closer to 20 lines, but still trivially short.

## Related Skills

- **test-helper-contract** (composes-with): The `testConn` helper is the canonical application of the test helper contract in the networking domain — it accepts `*testing.T`, calls `t.Fatalf` on all three failure points (Listen, Accept, Dial), and returns both connection ends with no error. Writing `testConn` requires applying both skills simultaneously.
- **test-helper-process-subprocess-mock** (contrasts-with): Both patterns reject shallow mocks in favor of real implementations. `testConn` rejects `bytes.Buffer` mocks of `net.Conn` by providing a real TCP loopback pair. `TestHelperProcess` rejects OS-level subprocess mocking by providing a real subprocess (the test binary re-executing itself). Same philosophy, different problem domain — networking vs. subprocesses.

______________________________________________________________________

## Provenance

- **Source:** "Advanced Testing with Go" by Mitchell Hashimoto — Part 2 — Writing Testable Code / Networking
