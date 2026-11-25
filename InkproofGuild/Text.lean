/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Guild.Protocol

namespace InkproofGuild

def text : Guild.Protocol.Text where
  roles :=
    [("architecture", include_str "../text/roles/architecture.md"),
     ("axis", include_str "../text/roles/axis.md"),
     ("conformance", include_str "../text/roles/conformance.md"),
     ("consumer-metrics", include_str "../text/roles/consumer-metrics.md"),
     ("coordinator", include_str "../text/roles/coordinator.md"),
     ("core", include_str "../text/roles/core.md"),
     ("demos", include_str "../text/roles/demos.md"),
     ("devtools", include_str "../text/roles/devtools.md"),
     ("export", include_str "../text/roles/export.md"),
     ("float", include_str "../text/roles/float.md"),
     ("gpu", include_str "../text/roles/gpu.md"),
     ("lasm", include_str "../text/roles/lasm.md"),
     ("process", include_str "../text/roles/process.md"),
     ("scale", include_str "../text/roles/scale.md"),
     ("scene", include_str "../text/roles/scene.md"),
     ("viewport", include_str "../text/roles/viewport.md"),
     ("web", include_str "../text/roles/web.md")]
  sections := include_str "../text/protocol.md"

end InkproofGuild
