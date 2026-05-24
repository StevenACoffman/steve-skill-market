# Skill: Information Hiding and Temporal Decomposition

**Source:** *A Philosophy of Software Design*, John Ousterhout (2018), Chapter 5

______________________________________________________________________

## R — Reading (Original Source)

> One common cause of information leakage is a design style I call temporal
> decomposition. In temporal decomposition, the structure of a system corresponds
> to the time order in which operations will occur. [...] Both the file reading and
> file writing steps have knowledge about the file format, which results in
> information leakage. The solution is to combine the core mechanisms for reading
> and writing files into a single class. [...] When designing modules, focus on the
> knowledge that's needed to perform each task, not the order in which tasks occur.
>
> Note: hiding variables and methods in a class by declaring them private isn't the
> same thing as information hiding. [...] information about the private items can still
> be exposed through public methods such as getter and setter methods.

— Chapter 5, §5.3 and §5.1

______________________________________________________________________

## I — Interpretation

**What information hiding actually means.** Information hiding is not about access modifiers. It is about *design decisions*: choices that could change (a file format, a wire protocol, a storage structure, a parsing strategy). A module hides a design decision when that decision is invisible to callers — it does not appear in the interface and is not duplicated in any other module. A private field whose internal structure is exposed through a `getMap()` getter is not hidden; the caller now depends on how parameters are stored, not just that parameters exist.

**What information leakage looks like diagnostically.** Leakage occurs whenever the same design decision is reflected in more than one module. The symptom is that changing the decision requires touching multiple files. It can surface as an interface leak (a type or shape detail in a method signature) or as a back-door leak (two classes that both import the same format knowledge without it appearing in either's API). Back-door leakage is more dangerous because it is invisible until you try to change the decision.

**Why temporal decomposition is the most common cause.** When developers think about what a system *does*, the natural mental model is a sequence: first read, then parse, then process, then write. Splitting the code along that timeline seems obvious. But most design decisions — "what does the file format look like?", "how do headers map to body length?" — manifest at *multiple points* in the sequence. Reading requires knowing the format; writing requires knowing the format. Putting the reader in one class and the writer in another forces both classes to encode the same format knowledge. The time-order decomposition has created two interfaces that share one design decision, which is the definition of leakage. The causal chain is: **temporal decomposition → same decision visible at multiple execution stages → that decision encoded in multiple interfaces → leakage**.

______________________________________________________________________

## A1 — Past Application (Author's Cases)

**Case 1: HTTP request read/parse split (Content-Type leaking).**
A student team created two classes: one to read the raw HTTP request from the socket, another to parse the string. The decomposition follows time order ("first we read, then we parse"). But parsing cannot be deferred: the `Content-Length` header must be read to know when the body ends, so both classes had to understand HTTP message structure. The design decision "how is an HTTP request structured?" leaked into both. Fix: merge into a single class that reads *and* parses, hiding all HTTP format knowledge behind one interface.

**Case 2: `getParams()` vs. `getParameter(name)` (URL parameter storage leaking).**
The `getParams()` method returned `Map<String, String>` — the internal data structure used to store parsed parameters. Any change to how parameters are stored (say, switching to `Map<String, List<String>>` to handle repeated keys) would break every caller. The implementation detail of *how parameters are stored* was leaked through the return type. `getParameter(String name)` hides that decision: callers ask for a value by name and get a string back, regardless of what structure holds the data internally.

**Case 3: HTTP response version field (version as leaked design decision).**
One team required callers to explicitly specify the HTTP protocol version when constructing a response object. The version is not an independent choice — it must match the version from the incoming request, which the HTTP library already has. Forcing the caller to specify it leaks the design decision "HTTP responses must echo the request's protocol version" out of the library and into every call site. The library should derive the version automatically and hide it entirely.

**Bonus: Protocol request signing.**
Consider an HTTP client split into a `RequestBuilder` class and a `RequestSigner` class. If the signing algorithm must inspect headers that were set during building (e.g., `Content-Type`, `Date`, canonical URI form), both classes must understand the structure and naming of HTTP headers — the same design decision in two interfaces. A single class that builds *and* signs the request hides the signing scheme and the header-layout decision together, removing the shared dependency.

______________________________________________________________________

## A2 — Future Trigger

Invoke this skill whenever you encounter these structural patterns:

- **Pipeline class designs**: classes named `XReader`, `XParser`, `XProcessor`, `XWriter` for the same data format. Each boundary is a candidate for temporal decomposition.
- **Step-by-step processing classes**: any decomposition where the class names describe *stages* rather than *responsibilities* (e.g., `RequestReceiver` + `RequestHandler` rather than `RequestProcessor`).
- **"Open → process → close" triads**: a class that opens a resource, a second that consumes it, a third that closes or flushes it. If open and close both require format or protocol knowledge, they belong together.
- **Microservice decompositions that follow workflow steps**: services named after saga steps ("CreateOrder", "ReserveInventory", "ChargePayment") where adjacent services must agree on the shared data schema — the schema is a design decision that both services now encode.
- **Any time you write two classes that both `import` the same format library or both reference the same schema type.** That shared import is a symptom that both classes know the same design decision.

______________________________________________________________________

## E — Execution (Steps)

**Step 1: Name the design decision.**
Before touching any code, write down in one sentence the decision that might be leaking. "How are HTTP headers structured?", "How are URL parameters encoded and stored?", "What signing algorithm do we use for requests?" If you cannot name it, you cannot hide it.

**Step 2: Find every interface that exposes it.**
Search for the decision across all module *interfaces* (method signatures, return types, constructor parameters, thrown exceptions) and across all *implementations* (any class that imports or encodes the same format, schema, or algorithm). List every location. This is the leakage map.

**Step 3: Apply the temporal decomposition test.**
Ask: "Are these modules organized by *when* they run, or by *what knowledge* they own?" If the answer is "by when" — if you could describe the decomposition as a sequence of execution stages — you have temporal decomposition. The fact that execution has stages does not require that modules mirror those stages.

**Step 4: Decide: merge or extract.**
If the leaking modules are small and tightly coupled to the shared decision, merge them. If the decision spans many classes, extract a new class that owns the decision exclusively and has a simple interface that abstracts it away. Do not extract if the new class merely re-exposes the same details through its own interface.

**Step 5: Redesign the interface by knowledge, not by time.**
After merging or extracting, verify that the new interface does not expose the design decision. The method signatures should describe *what callers want* ("give me the value of parameter X"), not *how it is done* ("here is the map of all parameters in the internal representation").

**Step 6: Verify the leakage map is empty.**
Return to the list from Step 2. Confirm that no remaining module's interface or implementation still encodes the design decision you named in Step 1. If any do, the reorganization is incomplete.

______________________________________________________________________

## B — Boundary (When Not to Apply)

**1. Temporal decomposition is intentional: event sourcing and saga patterns.**
In event sourcing, each stage of a workflow is an independent, durable event. The separation is not accidental — it is the architecture. The "design decision" each step embeds is deliberately isolated so that steps can be replayed, retried, or replaced independently. Merging saga steps to hide the shared data schema would destroy compensability and replay semantics. Here, the step boundaries are load-bearing; the information shared between steps (the event schema) is an *explicit contract*, not a leak.

**2. Hiding the information would create deeper coupling elsewhere.**
If two classes share knowledge of a design decision but merging them would make the resulting class responsible for an unrelated concern, the merge trades one leak for a worse violation: a class that knows too much about too many things. Evaluate whether the coupling introduced by merging is greater than the coupling caused by the leakage. Sometimes a thin shared data-transfer object is preferable to a monolithic class.

**3. The "design decision" is a genuine external constraint.**
When the sequence is mandated by an external party — a fixed wire protocol (TLS handshake ordering, SMTP command sequence), a regulatory process, a hardware initialization sequence — the order is not a design decision you could change. Encoding that order in your module structure is not temporal decomposition; it is accurate modeling of a fixed constraint. Hiding it would produce a misleading abstraction. Document the constraint explicitly instead.

**4. Performance boundaries require stage separation.**
When stages must run on different threads, in different processes, or at different rates (producer/consumer with a bounded queue), the stage boundary serves a concurrency or throughput purpose that is independent of information hiding. Merging the stages would eliminate the performance isolation the architecture depends on.

______________________________________________________________________

## Related Skills

- **Deep Module / Classitis Diagnosis (`structural-diagnosis-smells-depth`)** — *composes-with* → Depth requires hiding decisions; leakage causes shallowness. These skills diagnose the same problem from different angles: depth evaluates the outcome; information hiding evaluates the mechanism.
- **[Pass-Through Method / Wrong Layer Count](../pass-through-method-wrong-layer-count/SKILL.md)** — *composes-with* → Two diagnostics for wrong module boundaries: leakage = design decision appearing in multiple interfaces; pass-through = same abstraction at adjacent layers. Apply both when refactoring a layered system.
