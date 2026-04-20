#include <cstddef>
#include <cstdint>
#include <cstring>
#include <exception>
#include <string>
#include <sanitizer/lsan_interface.h>

#include "nix/fetchers/fetch-settings.hh"
#include "nix/expr/eval.hh"
#include "nix/expr/eval-gc.hh"
#include "nix/expr/eval-settings.hh"
#include "nix/expr/search-path.hh"
#include "nix/main/shared.hh"
#include "nix/store/store-open.hh"
#include "nix/util/canon-path.hh"
#include "nix/util/error.hh"
#include "nix/util/logging.hh"
#include "nix/util/file-system.hh"

namespace nix {
extern "C" int LLVMFuzzerTestOneInput(const uint8_t * data, size_t size)
{
    static fetchers::Settings fetchSettings;
    static bool readOnlyMode = true;
    static EvalSettings evalSettings{readOnlyMode};
    static EvalState * state = [] {
        initNix();
        initGC();
        verbosity = lvlError;
        __lsan_disable();
        ref<Store> store = openStore("dummy://");
        auto * s = new EvalState({}, store, fetchSettings, evalSettings, nullptr);
        __lsan_enable();
        return s;
    }();

    try {
        auto ptr = reinterpret_cast<const char *>(data);
        std::string input(ptr, size);
        state->parseExprFromString(input, state->rootPath(CanonPath::root));
    } catch (const std::exception &) {
    }

    return 0;
}

} // namespace nix
