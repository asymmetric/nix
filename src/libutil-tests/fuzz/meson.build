fuzz_targets = ['parse-dump']

foreach t : fuzz_targets
    executable(
        'fuzz-' + t,
        t + '.cc',
        dependencies: [deps_private_subproject + deps_private + deps_other],
        link_args: ['-fsanitize=fuzzer', '-static-libsan'],
        install: false,
    )
endforeach
