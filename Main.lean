/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import InkproofGuild

open Guild InkproofGuild

def usage : String := "usage: inkproof-guild instructions <agent>"

def main (args : List String) : IO UInt32 := do
  match args with
  | ["instructions", agent] =>
    match ← Settings.fromEnv with
    | .error es => IO.eprintln ("\n".intercalate es); pure 1
    | .ok s => match Protocol.assemble project s text agent with
      | .ok out => IO.print out; pure 0
      | .error e => IO.eprintln e; pure 1
  | _ => IO.eprintln usage; pure 2
