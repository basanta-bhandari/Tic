SHELL := /bin/bash
FLAVOR ?= full
ARCHISO_PROFILE ?=
TEST_WORK_DIR ?= $(CURDIR)/work-test-profile
PROFILE_ARG = $(if $(strip $(ARCHISO_PROFILE)),--archiso-profile "$(ARCHISO_PROFILE)",)

.PHONY: check custom-packages test-profile profile iso run clean

check:
	./scripts/check.sh

custom-packages:
	./repo/build-custom.sh

test-profile:
	WORK_DIR="$(TEST_WORK_DIR)" ./build.sh --profile-only --flavor "$(FLAVOR)" --archiso-profile tests/fixtures/releng
	./scripts/check-profile.sh "$(TEST_WORK_DIR)/profile" "$(FLAVOR)"

profile:
	./build.sh --profile-only --flavor "$(FLAVOR)" $(PROFILE_ARG)

iso:
	./build.sh --flavor "$(FLAVOR)" $(PROFILE_ARG)

run:
	./run.sh

clean:
	./scripts/clean.sh
