# Frame Position Export Design

> **状态：未实现的设计方案**
> 当前代码仍使用绝对像素坐标，AbsToRel/RelToAbs 转换尚未实现。本文档保留作为未来实现参考。

## Problem

DFUI_FRAMEPOS stores absolute screen coordinates (`GetLeft()`/`GetTop()`). These coordinates depend on screen resolution and UI scale, so exporting a profile from one setup and importing on another results in incorrect frame positions.

## Design Principle

**Convert at the profile boundary, not at runtime.**

- Runtime (`DFUI_FRAMEPOS`): always absolute pixel coordinates
- Storage (`DFUI_PROFILES[name]["_FramePos"]`): always relative proportions (0~1)

This keeps frame dragging, `SaveFramePosition`, and `RestoreFramePositions` untouched.

## Storage Format

Old (absolute):
```lua
{x = 500, y = 400}
```

New (relative):
```lua
{rx = 0.3906, ry = 0.5208, v = 2}
```

- `rx` = x / GetScreenWidth()
- `ry` = y / GetScreenHeight()
- `v = 2` ��� version marker to distinguish from old format

Serialized form: `{rx=0.3906;ry=0.5208;v=2}`

## Conversion Functions (core.lua)

```lua
-- Absolute -> Relative (on save)
AbsToRel(x, y) -> {rx, ry, v=2}

-- Relative -> Absolute (on load)
RelToAbs(pos) -> {x, y}
  - v==2: convert rx/ry back to pixels
  - no v: pass through old {x, y} unchanged
```

## Conversion Points

| Function | Direction | Location |
|----------|-----------|----------|
| SaveTempDB | abs -> rel | core.lua, _FramePos block |
| InitTempDB | rel -> abs | core.lua, _FramePos block |
| LoadProfile | rel -> abs | core.lua |
| CopyProfile | rel -> abs | core.lua |
| Import handler | rel -> abs | prof.lua, via DFUI.RelToAbs |

## Backward Compatibility

| Scenario | Behavior |
|----------|----------|
| Old data on disk (x/y, no v) | RelToAbs passes through unchanged |
| Old export string imported | Same — absolute coords used as-is |
| Old data re-saved | Next PLAYER_LOGOUT auto-migrates to relative |
| New export on different resolution | Relative coords scale correctly |
| Same resolution, new format | rx * width = original x (pixel-perfect) |

## Key Invariants

1. `DFUI_FRAMEPOS` at runtime is ALWAYS `{x = number, y = number}` (absolute)
2. `DFUI_PROFILES[*]["_FramePos"]` after save is ALWAYS `{rx, ry, v=2}` (relative)
3. `frames.lua` (`SaveFramePosition` / `RestoreFramePositions`) is never modified
4. `serialize.lua` is never modified — it handles the new keys automatically
5. `GetScreenWidth()`/`GetScreenHeight()` return UI-scaled coordinates, so UI scale changes are handled transparently
