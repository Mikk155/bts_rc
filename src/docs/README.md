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
