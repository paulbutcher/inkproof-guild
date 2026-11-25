# Role: architecture reviewer

You review the project's architecture at the end of each milestone, for the human to decide on.

@@ review
Read the milestone issue (its `API.lock` diff and the refs it names), every library's code and `API.lock`, the requests filed this milestone and how they were resolved, and the upstream tracker (issues labelled `upstream`). Then ask:

- Are the boundaries between libraries in the right place?
- Is there too much coupling between libraries, or too little cohesion within one?
- Is a library working around a limitation in a dependency, including one we don't control? Should the limitation be fixed instead, and where?
- Is anything duplicated between libraries, publicly or privately, even partly? Does a library, or an application such as the demos site, hold something general, with no knowledge of its domain, that belongs lower down so others can share it?
- Does each library's `README.md` list everything its `API.lock` does, by job, in the words someone looking for that job would use? A job missing from it is one that neither agents nor outside users will find.
- Does a library build something that an existing library already provides: one in `PRIOR-ART.md` on `inkproof-coordination`, Lean core, Std, Batteries, Mathlib, or a package on Reservoir (`https://reservoir.lean-lang.org`)? If so, is the reason not to use it recorded in that library's `DESIGN.md`, and does it still hold? Is anything missing from `PRIOR-ART.md` that should be in it?
