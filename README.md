# Lichess Assistant Dylib

Injectable chess assistant for the official Lichess iOS app.

Sideload with injection (no jailbreak required if you use TrollStore / Sideloadly with a decrypted IPA).

## Features

- Draggable floating button (same idea as epic0001/chess-assistant)
- Settings sheet matching the Flutter build (ELO, arrows, auto-play, delay, Maia)
- Arrow overlay with eval-colored best move + secondary arrows
- Engine bridge (Stockfish / Maia stub — wire your UCI binary here)
- Targets `org.lichess.mobileV2`

## Build (Theos)

```bash
export THEOS=~/theos
make package
```

The resulting `.deb` contains `LichessAssistant.dylib`.

## Inject into Lichess IPA

1. Decrypt the official Lichess IPA (or use the one provided).
2. Use one of:
   - **TrollFools** (on-device, TrollStore)
   - **Sideloadly** (PC/Mac, inject dylib option)
   - **optool** + re-sign
3. Install the modified IPA.

The dylib loads via `+load`, creates an overlay window, and shows the floating button.

## Current status

- Floating button + settings UI: working
- Arrow overlay: working (draws from UCI moves)
- Engine: stub (returns sample moves). Replace `EngineBridge.m` with real Stockfish UCI.
- FEN detection: not yet implemented (Flutter board). Next step is to hook the Dart isolate or scan for FEN strings in memory.

## Next steps

1. Link a real Stockfish binary into `EngineBridge`.
2. Add FEN detection from the Flutter process.
3. Wire auto-play (simulate taps on the board once FEN + best move are known).
