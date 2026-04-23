.PHONY: fuzz fuzz-parallel stop build corpus reconfigure

BUILD_DIR    = build-afl
FINDINGS_DIR = outputs
NIX_BIN      = $(BUILD_DIR)/src/nix/nix
NIX_ARGS     = eval --file --option restrict-eval true

MESON_SETUP = CC=afl-clang-fast CXX=afl-clang-fast++ meson setup -Dafl=true

build: $(BUILD_DIR)/meson-logs/meson-log.txt
	meson compile -C $(BUILD_DIR) nix

$(BUILD_DIR)/meson-logs/meson-log.txt:
	$(MESON_SETUP) $(BUILD_DIR)

corpus: $(FINDINGS_DIR)/corpus
$(FINDINGS_DIR)/corpus:
	mkdir -p $@
	cp tests/functional/lang/*.nix $@/

reconfigure:
	$(MESON_SETUP) --reconfigure $(BUILD_DIR)

AFL_CMD = afl-fuzz -i $(FINDINGS_DIR)/corpus -o $(FINDINGS_DIR)/fuzz-outputs -m 300
AFL_ENV = AFL_SKIP_CPUFREQ=1 \
          AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
          AFL_AUTORESUME=1 \
          GC_INITIAL_HEAP_SIZE=$$((8 * 1024 * 1024))
WORKERS = $(shell expr $$(nproc) / 2)

fuzz: build corpus
	mkdir -p $(FINDINGS_DIR)/fuzz-outputs
	$(AFL_ENV) $(AFL_CMD) -- $(NIX_BIN) $(NIX_ARGS) @@

fuzz-parallel: build corpus
	mkdir -p $(FINDINGS_DIR)/fuzz-outputs
	$(AFL_ENV) $(AFL_CMD) -M main -- $(NIX_BIN) $(NIX_ARGS) @@ </dev/null >$(FINDINGS_DIR)/main.log 2>&1 &
	$(foreach i,$(shell seq 1 $(WORKERS)), \
		$(AFL_ENV) $(AFL_CMD) -S worker$(i) -- $(NIX_BIN) $(NIX_ARGS) @@ </dev/null >$(FINDINGS_DIR)/worker$(i).log 2>&1 &)
	sleep 2
	watch --color afl-whatsup -s $(FINDINGS_DIR)/fuzz-outputs

stop:
	pkill afl-fuzz || true
