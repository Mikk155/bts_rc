```sh
cd src/docs
```

```sh
npm install
```

```sh
npm run build
```

```sh
npm run dev
```

Open the local URL shown by Vite to preview the site.

The build checks TypeScript and bundles the website modules, including dependencies,
into `docs/bts_rc.bundle.js` for static hosting. The dedicated bundle filename keeps
it separate from JavaScript emitted by standalone TypeScript compilation.

To keep the production bundle updated while editing, run the VS Code task
**Website bundle (watch)** or execute `npm run build:watch` from `src/docs`.
The default **Website compile & test** task starts both the Vite development
server and the bundle watcher. **Website dev server** can be run by itself when
you do not need to regenerate the static bundle.

To keep the production bundle updated while editing, run the VS Code task
**Website bundle (watch)** or execute `npm run build:watch` from `src/docs`.
