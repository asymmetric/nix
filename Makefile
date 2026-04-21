.PHONY: fuzz

build: build-fuzz/tests/fuzz/fuzz-nix-parser

# Compile the fuzz target (depends on binary existence)
build-fuzz/tests/fuzz/fuzz-nix-parser: build-fuzz/meson-logs/meson-log.txt tests/fuzz/libexpr.cc
	meson compile -C build-fuzz fuzz-nix-parser

# Setup meson build directory with fuzzing enabled
# debug symbols, optimized build
# Boehm GC is invisible to ASAN, so disable it
# fuzzer-no-link adds fuzz-related instrumentation to all libs, without adding fuzzer runtime to each
build-fuzz/meson-logs/meson-log.txt:
	CC=clang CXX=clang++ meson setup build-fuzz -Dfuzz=true

# Run the fuzz target
fuzz: build
	ASAN_OPTIONS=detect_leaks=0 ./build-fuzz/tests/fuzz/fuzz-nix-parser -rss_limit_mb=8192 -jobs=$(shell expr $$(nproc) / 2) outputs tests/fuzz/corpus/
