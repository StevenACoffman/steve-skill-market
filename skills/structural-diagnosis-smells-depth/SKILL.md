---
name: structural-diagnosis-smells-depth
allowed-tools: Bash, Read, Edit
id: structural-diagnosis-smells-depth
description: Use when identifying structural problems in code and deciding whether to split, merge, or restructure — especially when a code review suggests splitting a large class, or when a refactoring proposal needs validation beyond the smell catalog.
type: merged-skill
source_skills:
  - slug: fowler-refactoring/fowler-code-smells
    book: "Refactoring: Improving the Design of Existing Code, 2nd Ed."
    author: Martin Fowler
  - slug: jousterhout/deep-module-classitis-diagnosis
    book: "A Philosophy of Software Design"
    author: John Ousterhout
related_skills:
  - slug: fowler-refactoring/fowler-code-smells
    relation: supersedes
    note: Merged into structural-diagnosis-smells-depth; adds depth ratio as treatment validator
  - slug: jousterhout/deep-module-classitis-diagnosis
    relation: supersedes
    note: Merged into structural-diagnosis-smells-depth; adds smell vocabulary as candidate identifier
tags: []
---

# Structural Diagnosis — Smells and Depth

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Largest Go source files (structural complexity candidates):
!`find . -name '*.go' -not -name '*_test.go' -not -path './.git/*' | xargs wc -l 2>/dev/null | sort -rn | head -15`

Functions over 60 lines:
!`awk '/^func /{fn=$0; lc=0} fn{lc++} lc>60{print FILENAME": "fn" ("lc"+ lines)"; fn=""; lc=0}' $(find . -name '*.go' -not -name '*_test.go' -not -path './.git/*' 2>/dev/null) 2>/dev/null | head -10`

### R — Original Sources

**Fowler & Beck** (Refactoring, Ch. 3):

> "Smells, you say, and that is supposed to be better than vague aesthetics? Well, yes. We have looked at lots of code, written for projects that span the gamut from wildly successful to nearly dead. In doing so, we have learned to look for certain structures in the code that suggest—sometimes, scream for—the possibility of refactoring. One thing we won't try to give you is precise criteria for when a refactoring is overdue. In our experience, no set of metrics rivals informed human intuition."

**Convergence note:** Both frameworks are diagnostic vocabularies for structural problems, and both independently identify the same meta-failure: mechanical application of their own vocabulary becomes counterproductive dogma. Fowler warns against "smell police"; Ousterhout warns against classitis corrective becoming large-class dogma. Each author recognizes that named heuristics need judgment, not compliance.

**Ousterhout** (A Philosophy of Software Design, Ch. 4):

> "The best modules are those whose interfaces are much simpler than their implementations. Such a module has two advantages. First, a simple interface minimizes the complexity that a module imposes on the rest of the system. Second, if a module is modified in a way that does not change its interface, then no other module will be affected by the modification."
>
> **Classitis** is the failure mode of over-splitting: developers treat "small class" as a virtue independent of whether those classes are deep. The single responsibility principle, applied mechanically, produces a proliferation of small classes each doing one obvious thing — but each with an interface nearly as wide as its body. The result is more total interface surface, more concepts for callers to hold in mind, and more files to navigate — with no reduction in overall system complexity.

---

### I — Unified Framework

Structural diagnosis operates across two levels of analysis. The smell vocabulary provides bottom-up, symptom-first identification: you observe something that feels wrong, name it against a catalog, and receive a pointer to the appropriate refactoring. The depth ratio provides top-down, ratio-based validation: given a proposed structural change, does it produce modules whose interfaces are meaningfully simpler than their implementations?

The two levels are complementary, not competing. Applied separately, each has a blind spot. The smell catalog tells you what to fix but not whether the fix improves the structure. The depth ratio tells you whether a structure is good but doesn't give you a vocabulary for identifying candidates. Together they form a two-pass diagnostic workflow:

**Pass 1 — Smell scan (symptom identification):** Apply the ~24-smell catalog at method and class scope. Long Function, Feature Envy, Large Class, Data Clumps, Repeated Switches — each names a structural pattern with a known treatment. The smell scan is fast and bottom-up. It answers: "What is wrong here, and what should we do about it?"

**Pass 2 — Depth ratio validation (treatment validation):** Before acting on a split or restructuring prescription, apply the depth ratio test. Visualize each proposed module as a rectangle: the top edge (width) represents interface complexity — everything a caller must know. The rectangle's area represents hidden functionality. Ask: is the proposed split making both sides deeper (narrower top, rich area), or shallower (wider top, thin area)?

**The override rule:** If a smell identifies a candidate for splitting (e.g., Large Class → Extract Class), but the depth ratio shows the proposed sub-classes would be shallower than the original, the depth ratio overrides the smell. The smell correctly identified a symptom; the treatment is wrong for this case. A Large Class that is deep — narrow interface, rich hidden behavior — should not be split even if the catalog prescribes extraction.

**Scale awareness:** Apply the smell vocabulary at method and class scope (intra-module). Apply the depth ratio at class, module, and API scope (inter-module and cross-boundary). The two tools cover different levels of abstraction, so they are often complementary without conflict — smell identifies the intra-class issue; depth validates the proposed module-level outcome.

**The shared meta-principle:** Neither framework is a compliance checklist. Both require the diagnostician to exercise judgment about context — the domain, the caller needs, the usage pattern. A class diagnosed with Feature Envy may intentionally put behavior apart from data to support the Strategy pattern. A class measured as shallow may be correctly shallow at a trust or security boundary. Named vocabulary enables judgment; it does not replace it.

---

### A1 — Applications

## R — Original Sources

**Fowler & Beck** (Refactoring, Ch. 3):

> "Smells, you say, and that is supposed to be better than vague aesthetics? Well, yes. We have looked at lots of code, written for projects that span the gamut from wildly successful to nearly dead. In doing so, we have learned to look for certain structures in the code that suggest—sometimes, scream for—the possibility of refactoring. One thing we won't try to give you is precise criteria for when a refactoring is overdue. In our experience, no set of metrics rivals informed human intuition."

**Convergence note:** Both frameworks are diagnostic vocabularies for structural problems, and both independently identify the same meta-failure: mechanical application of their own vocabulary becomes counterproductive dogma. Fowler warns against "smell police"; Ousterhout warns against classitis corrective becoming large-class dogma. Each author recognizes that named heuristics need judgment, not compliance.

**Ousterhout** (A Philosophy of Software Design, Ch. 4):

> "The best modules are those whose interfaces are much simpler than their implementations. Such a module has two advantages. First, a simple interface minimizes the complexity that a module imposes on the rest of the system. Second, if a module is modified in a way that does not change its interface, then no other module will be affected by the modification."
>
> **Classitis** is the failure mode of over-splitting: developers treat "small class" as a virtue independent of whether those classes are deep. The single responsibility principle, applied mechanically, produces a proliferation of small classes each doing one obvious thing — but each with an interface nearly as wide as its body. The result is more total interface surface, more concepts for callers to hold in mind, and more files to navigate — with no reduction in overall system complexity.

---

## I — Unified Framework

Structural diagnosis operates across two levels of analysis. The smell vocabulary provides bottom-up, symptom-first identification: you observe something that feels wrong, name it against a catalog, and receive a pointer to the appropriate refactoring. The depth ratio provides top-down, ratio-based validation: given a proposed structural change, does it produce modules whose interfaces are meaningfully simpler than their implementations?

The two levels are complementary, not competing. Applied separately, each has a blind spot. The smell catalog tells you what to fix but not whether the fix improves the structure. The depth ratio tells you whether a structure is good but doesn't give you a vocabulary for identifying candidates. Together they form a two-pass diagnostic workflow:

**Pass 1 — Smell scan (symptom identification):** Apply the ~24-smell catalog at method and class scope. Long Function, Feature Envy, Large Class, Data Clumps, Repeated Switches — each names a structural pattern with a known treatment. The smell scan is fast and bottom-up. It answers: "What is wrong here, and what should we do about it?"

**Pass 2 — Depth ratio validation (treatment validation):** Before acting on a split or restructuring prescription, apply the depth ratio test. Visualize each proposed module as a rectangle: the top edge (width) represents interface complexity — everything a caller must know. The rectangle's area represents hidden functionality. Ask: is the proposed split making both sides deeper (narrower top, rich area), or shallower (wider top, thin area)?

**The override rule:** If a smell identifies a candidate for splitting (e.g., Large Class → Extract Class), but the depth ratio shows the proposed sub-classes would be shallower than the original, the depth ratio overrides the smell. The smell correctly identified a symptom; the treatment is wrong for this case. A Large Class that is deep — narrow interface, rich hidden behavior — should not be split even if the catalog prescribes extraction.

**Scale awareness:** Apply the smell vocabulary at method and class scope (intra-module). Apply the depth ratio at class, module, and API scope (inter-module and cross-boundary). The two tools cover different levels of abstraction, so they are often complementary without conflict — smell identifies the intra-class issue; depth validates the proposed module-level outcome.

**The shared meta-principle:** Neither framework is a compliance checklist. Both require the diagnostician to exercise judgment about context — the domain, the caller needs, the usage pattern. A class diagnosed with Feature Envy may intentionally put behavior apart from data to support the Strategy pattern. A class measured as shallow may be correctly shallow at a trust or security boundary. Named vocabulary enables judgment; it does not replace it.

---

## A1 — Applications

### Case 1: Feature Envy — Smell Identifies Candidate, Depth Confirms Treatment (Fowler Domain: Payment Module)

**Problem:** Reviewing a payment module, you find `calculateFee()` in the `Invoice` class calling six getter methods on `PaymentGateway`: `gateway.getRate()`, `gateway.getCurrency()`, `gateway.getFeeSchedule()`, `gateway.getMinimumCharge()`, `gateway.getRegion()`, `gateway.getTaxMultiplier()`. It references one field from `Invoice` itself.

**Methodology:** Pass 1 (smell scan): Feature Envy — `calculateFee()` interacts with six of `PaymentGateway`'s internals and only one of `Invoice`'s own fields. Treatment pointer: Move Function to `PaymentGateway`. Pass 2 (depth validation): Would the moved function make `PaymentGateway` deeper? Yes — the function encapsulates domain logic that was previously leaked into `Invoice`, hiding it behind `PaymentGateway`'s existing interface. The caller (`Invoice`) would now interact with a narrower surface. Depth improves. Both passes agree → proceed with high confidence.

**Conclusion:** When smell and depth agree, the treatment is confirmed. The two-pass workflow is fastest when both passes point the same direction.

**Result:** `calculateFee()` is moved to `PaymentGateway`. The code review comment is concrete: "Feature Envy — six interactions with `PaymentGateway`'s internals, one with `Invoice`'s own fields — Move Function to `PaymentGateway` where the data lives."

---

### Case 2: Java Three-Object File Open — Classitis Without a Smell (Ousterhout Domain: Library API Design)

**Problem:** To open a file for buffered, deserialized reading in Java, the caller must compose `FileInputStream`, `BufferedInputStream`, and `ObjectInputStream` explicitly. No smell in Fowler's catalog directly names this. The classes are not too large, not obviously envious, not duplicating code.

**Methodology:** Pass 1 (smell scan): no obvious smell fires. Pass 2 (depth ratio): visualize each class as a rectangle. `FileInputStream`'s interface nearly equals its implementation — it exposes almost everything the caller needs to know to operate a raw byte stream. `BufferedInputStream` adds a thin layer. `ObjectInputStream` adds deserialization. The caller must understand and name all three layers — the interface complexity is nearly equal to the combined implementation complexity. The classes are all shallow. The abstraction provides almost no hiding. A single deep wrapper — one call, returning a typed object stream — would reduce interface surface dramatically.

**Conclusion:** The depth ratio catches structural problems that the smell catalog misses. Classes can all be within smell-catalog tolerances and still be collectively shallow. The diagnostic operates at the API design level, above the method and class scope that smells address.

**Result:** Ousterhout prescribes a deeper default: buffering should be automatic, with opt-out only for rare cases. (Note: later JDK APIs such as `Files.newBufferedReader` partially address this.)

---

## A2 — When to Use This Skill

Use this skill — not one of its source skills — when:

- A code review says "this class is too big, extract it," and you need to evaluate whether the extraction would improve or degrade the design (smell identifies candidate; depth validates treatment)
- You are reviewing a PR that increases class count without an obvious reduction in interface complexity
- A refactoring debate uses "single responsibility principle" as the argument, but the proposed sub-classes would each have only one or two public methods and always appear together in usage
- You have scanned a module using the smell vocabulary and identified candidates for splitting, and now need to decide which splits to actually make
- A class is large (triggering Large Class smell) but has a narrow, stable interface that hides complex domain behavior — the depth ratio overrides the smell

**Instead of fowler-code-smells or deep-module-classitis-diagnosis, use this when:** the question crosses both symptom identification and treatment validation. Use `fowler-code-smells` alone for a broad smell scan with no proposed treatment under evaluation. Use `deep-module-classitis-diagnosis` alone for evaluating a proposed class split or merge where no smell scan is needed.

**Language signals:**

- "This class does too many things" — triggers smell scan for Large Class / Divergent Change, then depth check on proposed split
- "Every time I touch X, I have to change Y, Z, and W" — Shotgun Surgery (smell), then depth check on proposed consolidation
- "This should be two classes" — triggers depth validation before accepting the split
- "We have too many small classes that always have to be used together" — classitis diagnostic
- "This class is 800 lines but I can't figure out how to split it" — depth ratio may explain why: it may be deep

---

## E — Execution

**Step 1 — Smell scan at method and class scope.**
Look for: long functions (>20 lines warrants a look), classes with many fields (>7–10 is a signal), functions with many parameters (>3–4), repeated conditional patterns on the same variable, functions that call many methods on another class, fields that are null in certain states. Match each symptom to the smell catalog.

Format findings: "[Smell name] — [specific structural evidence] — treatment pointer: [specific refactoring]."

**Step 2 — For each candidate restructuring, apply the depth ratio test.**
Draw the rectangle for the current structure and for each proposed outcome. For each module under evaluation:

- List everything a caller must know: parameters, types, exceptions, ordering constraints, prerequisite calls. This is the top edge (interface width).
- Estimate the implementation: lines of non-trivial logic, edge cases handled, decisions made. This is the area.
- If the top edge is nearly as wide as the rectangle, the module is shallow. If the proposed split produces modules with top edges nearly as wide as the current one, the split degrades depth.

**Step 3 — Apply the override rule.**

- If smell and depth agree (smell says split, depth improves): proceed with high confidence.
- If smell says split but depth check shows proposed sub-classes would be shallow: override the smell. The smell identified a candidate; the depth ratio vetoes the treatment. Look for an alternative treatment — often the fix is to simplify the interface (better defaults, hide more decisions) rather than to split the class.
- If smell scan finds nothing but depth check shows shallow modules that always appear together: apply the classitis diagnostic. Consider consolidation.

**Step 4 — Apply the merge hypothesis.**
Mentally merge the candidate classes. Does the merged class become harder to understand for callers (more interface surface, more concepts), or easier? If callers pass fewer arguments, handle fewer types, and read fewer files, the merge improves depth. If the merged class genuinely handles two unrelated concerns that different callers care about separately, the split is justified.

**Step 5 — Check for trust boundary and testability exceptions.**
Before finalizing: does the split cross a trust, security, or privilege boundary? If yes, shallowness may be correct — explicit interface at a privilege boundary is an auditable crossing, not a design flaw. Does the proposed depth change affect testability (e.g., hiding a clock or filesystem behind a deeper interface)? If the depth improvement makes the module harder to test in isolation, evaluate whether the testability tradeoff is worth it.

**Step 6 — Communicate with smell name + depth evidence + treatment decision.**
"[Smell name] — [structural evidence] — depth check: [proposed outcome is deeper / shallower] — treatment: [proceed with refactoring / override: alternative treatment]."

---

## B — Boundaries

**Do not apply this skill mechanically:**

- A class diagnosed with "Large Class" that has a narrow, stable interface hiding complex behavior should not be split — it is deep. The smell is overridden.
- A class measured as shallow at a trust or security boundary is correctly shallow — explicit interface at a privilege crossing is auditable by design.
- Sometimes long functions are clearer as one unit: a state machine as a 60-line switch or a table-driven parser may be clearer than a dozen small functions. If naming the pieces adds no clarity, extracting them is ceremony.
- Not every string needs a value object. If a primitive is used in one place and never validated, the object adds overhead without benefit.

**Source A failures (Fowler's smell catalog):**

- The smell police: treating the catalog as a compliance checklist and flagging everything in every review damages team relationships and makes code review adversarial
- Refactoring without tests: applying a refactoring because a smell exists, without a test suite to catch regressions, introduces bugs
- Over-extraction: responding to Long Function by extracting every 3-line block produces a fragmented codebase where understanding one thing requires jumping through a dozen short functions
- Scope limitation: the smell catalog addresses intra-module structure only — it does not cover smells at the service or distributed-system level (chatty inter-service protocols, inappropriate data ownership)

**Source B failures (Ousterhout's depth framework):**

- Classitis corrective becoming large-class dogma: "this class is too small" is not a valid argument on its own; "this class's interface is not simpler than its implementation" is
- Naively applying depth critique at trust/security boundaries: shallowness is correct when the crossing must be auditable
- Testability sometimes justifying shallowness: injecting a clock or filesystem widens the interface for good reasons; the depth ratio must be evaluated against the test surface, not only the production caller surface
- Distributed system context: at service boundaries, deployment independence often matters more than interface simplicity — the depth model applies within a service, not across services

**Synthesis-specific failure mode:** Applying the smell catalog alone and extracting a Large Class into two sub-classes — only to find the sub-classes always appear together in every call site and each has an interface nearly as wide as the original. This is the smell-without-depth-validation failure. The smell correctly identified candidate behavior; the depth check would have revealed that the extraction produces classitis. The symptom-first and ratio-oriented passes must both be applied for restructuring decisions, not either alone.
