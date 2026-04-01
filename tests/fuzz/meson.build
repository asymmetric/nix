# Fuzz target for the Nix language parser
libexpr_dep = dependency('nix-expr')
libmain_dep = dependency('nix-main')

cxx = meson.get_compiler('cpp')

# Check if fuzzer flag is available
fuzzer_flags = ['-fsanitize=fuzzer']
has_fuzzer = cxx.links(
  'extern "C" int LLVMFuzzerTestOneInput(const char*, unsigned long){return 0;}',
  args : fuzzer_flags,
  name : 'libFuzzer',
)

if has_fuzzer
  fuzz_target = executable(
    'fuzz-nix-parser',
    'libexpr.cc',
    dependencies : [libexpr_dep, libmain_dep],
    cpp_args : fuzzer_flags,
    link_args : fuzzer_flags,
    install : false,
  )
  message('Fuzz target fuzz-nix-parser enabled')
else
  message('WARNING: libFuzzer not available, fuzz targets disabled. Install libFuzzer or use -fsanitize=fuzzer capable compiler.')
endif
