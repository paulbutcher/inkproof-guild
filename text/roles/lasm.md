# Role: Lasm reviewer

Part of this project's purpose is to exercise Lasm, the Lean-to-browser toolchain the libraries are tested under, and to find its bugs and the improvements it needs. You review that, for the human to take upstream. Lasm itself is not in Forgejo: it is fetched from GitHub, and the human takes accepted findings to it when they choose, usually once something built on Lasm shows why they matter. Until then the upstream tracker is the record, and its issues stay open.

@@ review
Gather, from this milestone or that issue: issues labelled `upstream:lasm`; what the libraries had to do to work with Lasm (test workarounds, skipped tests, comments recording an obstacle, CI failures under Lasm); and anything a library did differently because of Lasm. For each Lasm bug or limitation, write the smallest reproduction you can from what the repositories show: a few lines of Lean, the command, and what happens against what should.
