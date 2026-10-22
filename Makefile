.PHONY: site serve deploy

site: elm.lock
	nix build -L

serve: elm.lock
	nix run

deploy: elm.lock
	nix run .#deploy

elm.lock:
	elm2nix lock elm.json review/elm.json review/elm.extra.json
