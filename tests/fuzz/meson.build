# Fuzz target for the Nix language parser
libexpr_dep = dependency('nix-expr')
libmain_dep = dependency('nix-main')

cxx = meson.get_compiler('cpp')

if get_option('fuzz')
  fuzzer_flags = ['-fsanitize=fuzzer']
  if not cxx.has_argument(fuzzer_flags[0])
    error('fuzz option requires -fsanitize=fuzzer support')
  endif
  coverage_flags = ['-fprofile-instr-generate', '-fcoverage-mapping']
  executable(
    'fuzz-nix-parser',
    'libexpr.cc',
    dependencies : [libexpr_dep, libmain_dep],
    cpp_args : fuzzer_flags + coverage_flags,
    link_args : fuzzer_flags + coverage_flags,
    install : false,
  )
endif
