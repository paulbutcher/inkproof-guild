/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lake
open Lake DSL

package «inkproof-guild» where
  version := v!"0.1.0"
  leanOptions := #[⟨`warningAsError, true⟩]
  testDriver := "tests"

require guild from git "https://github.com/paulbutcher/lean-guild" @ "v0.12.0"

input_dir text where
  path := "text"
  text := true

lean_lib InkproofGuild where
  needs := #[text]

@[default_target]
lean_exe «inkproof-guild» where
  root := `Main

lean_exe tests where
  root := `Tests
