# Credits typography

Two renamed subsets keep the exact supplied names and biography readable without
installing fonts or accessing the network at runtime. They contain only the
characters used in Credits; no system font is replaced.

- `CreditsSymbols.otf`: GNU FreeSerif, GNU FreeFont 20120503, from the local
  `gnu-free-fonts` package. GPL-3.0-or-later with the original font embedding
  exception; see `LICENSE-CreditsSymbols.txt` and the repository's `LICENSE`.
- `CreditsKana.ttf`: the three kana and punctuation from the locally available
  GoNotoKurrent Regular, with Noto Project copyright. SIL OFL 1.1; see
  `OFL-CreditsKana.txt`. The family is renamed to Velora Credits Kana.
- Emoji use the existing `NotoColorEmoji.ttf`, unchanged.

Regenerate from the original font files using:

```sh
python3 tools/build-credit-fonts.py /path/to/FreeSerif.otf /path/to/GoNotoKurrent-Regular.ttf
```

The helper uses the system HarfBuzz subset library and retains copyright and
license name records. It is not required at runtime.
