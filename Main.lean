/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import InkproofGuild
import Guild.Kit

def main (args : List String) : IO UInt32 :=
  Guild.Kit.main InkproofGuild.project InkproofGuild.text args
