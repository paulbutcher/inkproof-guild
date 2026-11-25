/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import InkproofGuild

open Guild InkproofGuild

def settings : Settings :=
  { forgeOrg := "tentenths", human := "paulbutcher", forgeWebUrl := "http://localhost:3000" }

def main : IO UInt32 := do
  let problems := Protocol.check project settings text
  for p in problems do IO.eprintln p
  pure (if problems.isEmpty then 0 else 1)
