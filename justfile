[private]
default:
  @just --list --unsorted

# Start the development server
dev:
  pnpm dev

# Run elm-format
format:
  elm-format src review tests

# Run sanity checks
lint:
  elm-format src review tests --validate
  actionlint

# Run elm-review
review:
  elm-review src review tests

# Run Elm tests
test:
  elm-test-rs

# Remove build artifacts
clean:
  rm -rf .parcel-cache dist elm-stuff node_modules

alias s := dev
alias f := format
alias r := review
alias t := test
alias c := clean
