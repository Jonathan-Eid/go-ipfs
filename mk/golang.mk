# golang utilities
GO_MIN_VERSION = 1.14.4
export GO111MODULE=on


# pre-definitions
GOCC ?= go
GOTAGS ?=
GOTFLAGS ?=

# These are global go flags that will apply to all commands. This includes random calls to `go fmt`.
export GOFLAGS
ifeq ($(tarball-is),1)
override GOFLAGS += -mod=vendor
endif

# match Go's default GOPATH behaviour
export GOPATH ?= $(shell $(GOCC) env GOPATH)

DEPS_GO :=
TEST_GO :=
TEST_GO_BUILD :=
CHECK_GO :=

go-pkg-name=$(shell $(GOCC) list $(go-tags) github.com/ipfs/go-ipfs/$(1))
go-main-name=$(notdir $(call go-pkg-name,$(1)))$(?exe)
go-curr-pkg-tgt=$(d)/$(call go-main-name,$(d))
go-pkgs=$(shell $(GOCC) list github.com/ipfs/go-ipfs/...)

# Go tags cannot be set in GOFLAGS.
go-tags=$(if $(GOTAGS), -tags="$(call join-with,$(space),$(GOTAGS))")
# These flags _may_ contain spaces so we can't use GOFLAGS either.
go-flags="-asmflags=all='-trimpath=$(GOPATH)'" "-gcflags=all='-trimpath=$(GOPATH)'"
go-flags-with-tags=$(go-flags)$(go-tags)

define go-build-relative
$(GOCC) build $(go-flags-with-tags) -o "$@" "$(call go-pkg-name,$<)"
endef

define go-build
$(GOCC) build $(go-flags-with-tags) -o "$@" "$(1)"
endef

define go-try-build
$(GOCC) build $(go-flags-with-tags) -o /dev/null "$(call go-pkg-name,$<)"
endef

test_go_test: $$(DEPS_GO)
	$(GOCC) test $(go-flags-with-tags) $(GOTFLAGS) ./...
.PHONY: test_go_test

test_go_build: $$(TEST_GO_BUILD)

test_go_short: GOTFLAGS += -test.short
test_go_short: test_go_test
.PHONY: test_go_short

test_go_race: GOTFLAGS += -race
test_go_race: test_go_test
.PHONY: test_go_race

test_go_expensive: test_go_test test_go_build
.PHONY: test_go_expensive
TEST_GO += test_go_expensive

test_go_fmt:
	bin/test-go-fmt
.PHONY: test_go_fmt
TEST_GO += test_go_fmt

test_go_lint: test/bin/golangci-lint
	golangci-lint run ./...
.PHONY: test_go_lint

test_go: $(TEST_GO)

check_go_version:
	@$(GOCC) version
	bin/check_go_version $(GO_MIN_VERSION)
.PHONY: check_go_version
DEPS_GO += check_go_version

TEST += $(TEST_GO)
TEST_SHORT += test_go_fmt test_go_short
