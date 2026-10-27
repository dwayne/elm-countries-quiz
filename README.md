# elm-countries-quiz

A browser game to learn the flag of all the countries.

## Usage

You'll need [Nix](https://nixos.org/) with flakes enabled.

```bash
nix run github:dwayne/elm-countries-quiz
```

Open http://localhost:8000/ in your browser to use the application.

## Develop

```bash
nix develop
just
```

Start the development server with `just dev` and develop the application in [`src`](./src).

## Deploy

```bash
just deploy
```

Deploy the application to the `gh-pages` branch.
