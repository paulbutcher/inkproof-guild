@@ working-in-your-repository
- Your `README.md` is how people find what your repository does: users who come across it on GitHub, and the other agents. Keep a `## What it does` section in it, with one line for each job its public API does, in the words someone looking for that job would use, naming the entry points. A pull request that adds, removes or changes what the public API does updates that list in the same change.

@@ reuse-reasons
Two reasons not to use what exists upstream hold good: it doesn't work under Lasm (PLAT-3), or it adds to the size of a browser build, which ships as WebAssembly, significantly more than writing your own would (a module whose import brings code or initialisation you don't need). Say which in `DESIGN.md`. A library's own version that only repeats a proof, or a definition upstream already has in the form you need, has neither excuse.

@@ cross-cutting
 (floating-point strategy, process, platform, validation, trusted computing base)

@@ definition-of-done
; its most frequent findings are a public pure total function with no theorem stating what it computes, and a comment that refers to a requirement ID, a ticket, a plan or a milestone. Put a `Theorems:` line in the pull request description, next to `Prior art:`: each public pure total function you add or change, with the theorem that states what it computes (an equation for its value or a projection, not only a law such as injectivity or a length), or the comment recording the failed proof attempt; `none new` if there are none

@@ conformance
   For "Protocol: Definition of done", check the pull request's `Theorems:` line against the diff: every public pure total function it adds or changes is named, with a theorem stating what it computes or the comment recording a failed proof attempt.
   For "Protocol: Working in your repository", check that a pull request that adds, removes or changes what the public API does (its `API.lock` diff is the evidence) updates the `## What it does` list in `README.md`.
