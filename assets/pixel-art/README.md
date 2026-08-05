# Void Trader — Pixel-Art-Assets

Kanonischer Ablageort für Spiel-Grafiken laut Monorepo-Struktur (Phase 0
der Roadmap). Quelle/Status je Asset steht in [`manifest.json`](manifest.json).

## Wichtig: physische Kopie in `apps/void_trader/assets/`

Flutter bündelt nur Assets, die innerhalb des Flutter-Package-Verzeichnisses
liegen — `apps/void_trader/assets/pixel-art/` ist deshalb eine **echte
Kopie** dieses Ordners, kein Symlink (bewusste Entscheidung: keine
Verlinkungen im Repository).

Bei Änderungen an Assets hier **immer** auch nach
`apps/void_trader/assets/pixel-art/` synchronisieren, z.B.:

```bash
rm -rf apps/void_trader/assets/pixel-art
cp -r assets/pixel-art apps/void_trader/assets/pixel-art
```
