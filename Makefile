.PHONY: fuzz fuzz-parallel stop build corpus reconfigure

BUILD_DIR    = build-afl
FINDINGS_DIR = outputs
NIX_BIN      = $(BUILD_DIR)/src/nix/nix
NIX_ARGS     = eval --file

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
fuzz: build corpus
	$(AFL_ENV) $(AFL_CMD) -- $(NIX_BIN) $(NIX_ARGS) @@

WORKER = $(AFL_ENV) $(AFL_CMD) -S
LOG    = </dev/null >$(FINDINGS_DIR)

fuzz-parallel: build corpus
	mkdir -p $(FINDINGS_DIR)/fuzz-outputs
	# Main: final sync so secondaries pull from it
	AFL_FINAL_SYNC=1 $(AFL_ENV) $(AFL_CMD) -M main \
		-- $(NIX_BIN) $(NIX_ARGS) @@ $(LOG)/main.log 2>&1 &
	# MOpt mutator
	$(WORKER) mopt      -L 0 \
		-- $(NIX_BIN) $(NIX_ARGS) @@ $(LOG)/mopt.log 2>&1 &
	# Explore, no trim
	AFL_DISABLE_TRIM=1 $(WORKER) explore  -p explore \
		-- $(NIX_BIN) $(NIX_ARGS) @@ $(LOG)/explore.log 2>&1 &
	# Exploit
	$(WORKER) exploit   -p exploit \
		-- $(NIX_BIN) $(NIX_ARGS) @@ $(LOG)/exploit.log 2>&1 &
	# Rare + old queue cycling
	$(WORKER) rare      -p rare -Z \
		-- $(NIX_BIN) $(NIX_ARGS) @@ $(LOG)/rare.log 2>&1 &
	# COE
	$(WORKER) coe       -p coe \
		-- $(NIX_BIN) $(NIX_ARGS) @@ $(LOG)/coe.log 2>&1 &
	# ASCII input format hint
	$(WORKER) ascii     -a ascii -p fast \
		-- $(NIX_BIN) $(NIX_ARGS) @@ $(LOG)/ascii.log 2>&1 &
	# Binary input format hint, no trim
	AFL_DISABLE_TRIM=1 $(WORKER) binary   -a binary -p fast \
		-- $(NIX_BIN) $(NIX_ARGS) @@ $(LOG)/binary.log 2>&1 &
	sleep 2
	watch --color afl-whatsup -s $(FINDINGS_DIR)/fuzz-outputs

stop:
	pkill afl-fuzz || true
