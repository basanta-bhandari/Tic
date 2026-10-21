SHELL := /bin/bash
FLAVOR ?= full
ARCHISO_PROFILE ?= /usr/share/archiso/configs/releng

.PHONY: check test-profile profile iso run clean

check:
	./scripts/check.sh

test-profile:
	./build.sh --profile-only --flavor "$(FLAVOR)" --archiso-profile tests/fixtures/releng
	./scripts/check-profile.sh work/profile "$(FLAVOR)"

profile:
	./build.sh --profile-only --flavor "$(FLAVOR)" --archiso-profile "$(ARCHISO_PROFILE)"

iso:
	./build.sh --flavor "$(FLAVOR)" --archiso-profile "$(ARCHISO_PROFILE)"

run:
	@iso="$$(find out -maxdepth 1 -type f -name 'glyph-linux-*.iso' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)"; \
	if [[ -z "$$iso" ]]; then echo "No Glyph ISO found in out/. Run 'make iso' first." >&2; exit 1; fi; \
	if command -v run_archiso >/dev/null 2>&1; then run_archiso -i "$$iso"; \
	elif command -v qemu-system-x86_64 >/dev/null 2>&1; then qemu-system-x86_64 -enable-kvm -m 2048 -smp 2 -cdrom "$$iso"; \
	else echo "Install archiso or qemu-desktop to run the image." >&2; exit 1; fi

clean:
	./scripts/clean.sh
