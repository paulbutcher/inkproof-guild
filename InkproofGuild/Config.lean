/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Guild.Config

namespace InkproofGuild

open Guild

private def coordination := "inkproof-coordination"

/-- Each library's agent, kind, repository and the repositories it depends on. -/
private def libraries : List (String × Kind × String × List String) :=
  [("devtools", .library, "tools", []),
   ("float", .library, "float", ["tools"]),
   ("core", .library, "core", ["float", "tools"]),
   ("scale", .library, "scale", ["core", "float", "tools"]),
   ("axis", .library, "axis", ["scale", "float", "tools"]),
   ("viewport", .library, "viewport", ["scale", "tools"]),
   ("scene", .library, "scene", ["core", "scale", "axis", "float", "tools"]),
   ("gpu", .library, "gpu", ["scene", "scale", "float", "tools"]),
   ("export", .library, "export", ["scene", "tools"]),
   ("web", .library, "web", ["gpu", "viewport", "axis", "scene", "tools"]),
   ("demos", .site, "demos",
     ["web", "export", "viewport", "gpu", "scene", "axis", "scale", "core", "float", "tools"]),
   ("consumer-metrics", .library, "consumer-metrics", ["core", "scale", "float", "tools"])]

private def repo (name : String) : String := s!"inkproof-{name}"

def project : Project where
  config :=
    { name := "the Inkproof libraries"
      coordination
      repositories :=
        { name := coordination } ::
        libraries.map fun (_, _, r, deps) => { name := repo r, dependsOn := deps.map repo }
      agents :=
        [{ name := "coordinator", kind := .coordinator, owns := some coordination, filesOn := .all }] ++
        libraries.map (fun (a, k, r, deps) =>
          { name := a, kind := k, owns := some (repo r), filesOn := .only (coordination :: deps.map repo) }) ++
        [{ name := "conformance", kind := .prReviewer, filesOn := .all },
         { name := "architecture", kind := .milestoneReviewer, filesOn := .all },
         { name := "process", kind := .supervisor, filesOn := .all, humanDecides := true },
         { name := "lasm", kind := .milestoneReviewer, filesOn := .all, humanDecides := true }]
      upstreams := [{ name := "lasm", title := "Lasm", tracker := some "lasm" }]
      bounds :=
        { patience := 3
          runBudget := 40
          maxRunsPerDay := 150
          maxCoordinatorRunsPerDay := 250 }
      layers := { lasm := true }
      forge := .forgejo (some { owner := "paulbutcher", formerOwners := ["tentenths"] }) (imported := true)
      template :=
        { namespaceRoot := "Inkproof"
          readmeLine := "Part of Inkproof. Released under the Apache 2.0 license; see `LICENSE`."
          leanOptions :=
            [("autoImplicit", "false"), ("relaxedAutoImplicit", "false"), ("warningAsError", "true")]
          seedFrom := some "inkproof-core" } }

end InkproofGuild
