<p align="center">
  <img src="assets/icon.png" width="96" height="96" alt="Moo">
</p>

<h1 align="center">Moo Plugins</h1>

<p align="center">
  The official plugins for <a href="https://moo.moi">Moo</a>, the keyboard launcher for macOS.<br>
  Written in Tish. Sandboxed. Small enough to read in one sitting.
</p>

<p align="center">
  <a href="https://moo.moi/marketplace">Marketplace</a>
  ·
  <a href="https://moo.moi/docs/first-plugin">Write a plugin</a>
  ·
  <a href="https://moo.moi/docs/plugin-api">Plugin API</a>
</p>

---

Every plugin here ships inside Moo. They're 100% [Tish](https://github.com/tishlang/tish): no
Rust, no JavaScript. Most are **Tier A**, compiled to bytecode and run in their own VM with no
access to files, processes or the network. Their only way out is Moo's host API, and a plugin can
reach only the hosts its manifest lists.

## Plugins

| Plugin | Type | What it does | Network |
| --- | --- | --- | --- |
| [**Dev Toolbox**](devtools) | `dev` | Base64, URL encoding, JWT decoding, JSON pretty/minify, SHA-1/SHA-256, color hex/rgb/hsl, Unix timestamps, lorem ipsum | none |
| [**GitHub**](github) | `gh` | Your pull requests, review requests, issues and notifications; repository search | `api.github.com` |
| [**Package Search**](packages) | `npm` `crate` `brew` `pip` | npm, crates.io, Homebrew and PyPI: open the page or copy the install command | the four registries |
| [**Weather**](weather) | `weather` | Now and the next 7 days, from Open-Meteo (no API key) | `open-meteo.com` |
| [**Slack**](slack) | `slack` | Send messages, search them, open channels | `slack.com` |
| [**Unit Converter**](convert) | | Length, mass, volume, data and temperature | none |
| [**Moo Utils**](utils) | | UUIDs, emoji search, developer links (Tier B: first-party native) | none |
| [**Hello List**](hello-list) | | The example: list views, sections and state with `@moo/ui` | none |

## Build

```sh
bash toolchain/build.sh     # the pinned Tish compiler, into .toolchain/ (prints TISH=...)
TISH=.toolchain/tish/target/release/tish bash build.sh
```

`build.sh` builds every folder with a `moo.json` into `dist/`: `<id>.tishc` for Tier A and
`<id>.lib` for Tier B. To try them, point Moo at that folder:

```sh
MOO_PLUGINS="$PWD/dist" open -a Moo
```

## Write one

```
my-plugin/
  moo.json          { "id": "my-plugin", "tier": "A", "entry": "src/plugin.tish" }
  src/plugin.tish
```

```tish
register({
  manifest: () => ({
    id: "shout",
    title: "Shout",
    commands: [{ name: "shout", title: "Shout", mode: "list", keyword: "shout" }]
  }),
  run: (command) => null,
  list: (command, query) => {
    let loud = query.toUpperCase() + "!"
    return [{ title: loud, subtitle: "Return to copy", action: { copy: loud, hud: "Copied" } }]
  }
})
```

Start from the walkthrough at [moo.moi/docs/first-plugin](https://moo.moi/docs/first-plugin), and
read [weather](weather/src/plugin.tish) for network calls or [github](github/src/plugin.tish) for
sign-in with the Keychain. The full contract (commands, arguments, actions, blockers, the `moo`
host object and time budgets) is at [moo.moi/docs/plugin-api](https://moo.moi/docs/plugin-api).

### Rules of the road

- **Tish only.** Plugins are Tish source, nothing else.
- **Declare your hosts.** `permissions: { network: ["api.example.com"] }`. Anything else is refused.
- **Stay fast.** Each call has a 250 ms budget, and `list` runs on every keystroke. Start a
  request, return "Loading…", and call `moo.refresh()` when the answer arrives.
- **Offer, don't instruct.** When something is needed first, like a token, return it from
  `blocker()` as a row that does it.

## Contributing

Pull requests for new plugins are welcome. A plugin merged here ships in the next Moo release and
appears in the [marketplace](https://moo.moi/marketplace). Keep each plugin to its own folder,
build it with `bash build.sh`, and try it in Moo with `MOO_PLUGINS` before opening the PR.

`sdk/ui` is the `@moo/ui` view toolkit (a copy of Moo's `packages/ui`), and `sdk/lattish` is
[Lattish](https://github.com/tishlang/lattish), which it builds on (its own license is in that
folder).

## License

[MIT](LICENSE), except `sdk/lattish` (see its LICENSE).
