#include <cstddef>
#include <cstdint>
#include <cstring>
#include <exception>
#include <string>

#include "nix/fetchers/fetch-settings.hh"
#include "nix/expr/eval.hh"
#include "nix/expr/eval-gc.hh"
#include "nix/expr/eval-settings.hh"
#include "nix/main/shared.hh"
#include "nix/store/store-open.hh"
#include "nix/util/canon-path.hh"
#include "nix/util/error.hh"
#include "nix/util/logging.hh"

namespace nix {
extern "C" int LLVMFuzzerTestOneInput(const uint8_t * data, size_t size)
{
    static fetchers::Settings fetchSettings;
    static bool readOnlyMode = true;
    static EvalSettings evalSettings{readOnlyMode};
    static ref<Store> store = [] {
        initNix();
        initGC();
        verbosity = lvlError;
        return openStore("dummy://");
    }();

    EvalState state({}, store, fetchSettings, evalSettings, nullptr);

    try {
        auto ptr = reinterpret_cast<const char *>(data);
        std::string input(ptr, size);
        state.parseExprFromString(input, state.rootPath(CanonPath::root));
    } catch (const std::exception &) {
    }

    return 0;
}
} // namespace nix
