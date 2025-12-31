# create-velox-app

Swift CLI to scaffold a new Velox application.

## Usage

```bash
swift run create-velox-app [PROJECTNAME]
```

Common options:

- `-y, --yes` to skip prompts
- `-f, --force` to overwrite a non-empty directory
- `--identifier` to set the app identifier
- `--velox-path` to use a local Velox checkout (for development)

Templates:

- `vanilla`: As simple as it gets.
- `hummingbird`: Using the [Hummingbird HTTP Stack](https://github.com/hummingbird-project/hummingbird) for the backend.
- `vue`: Using Vue for the front-end.
- `vue-ts`: Using Vue with Typescript for the front-end.
- `svelte`: Using Svelte for the front-end.
- `svelte-ts`: Using Svelte with Typescript for the front-end.

## Generated App

The default template is a bundled-assets Velox app based on the HelloWorld2 example. It includes:

- a SwiftPM executable target
- bundled HTML/CSS/JS assets served via `app://`
- an IPC command bridge via `ipc://`

Set `VELOX_DEV_URL` to point the webview at a dev server instead of bundled assets.
