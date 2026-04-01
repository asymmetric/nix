#include <cstddef>
#include <cstdint>
#include <cstring>
#include <exception>
#include <string>

#include "nix/fetchers/fetch-settings.hh"
#include "nix/expr/eval.hh"
#include "nix/expr/eval-gc.hh"
#include "nix/expr/eval-settings.hh"
#include "nix/expr/search-path.hh"
#include "nix/main/shared.hh"
#include "nix/store/store-open.hh"
#include "nix/util/canon-path.hh"
#include "nix/util/error.hh"
#include "nix/util/file-system.hh"

namespace nix
{
    extern "C" int LLVMFuzzerInitialize(int *, char ***)
    {
        initNix();
        initGC();
        return 0;
    }

    extern "C" int LLVMFuzzerTestOneInput(const uint8_t * data, size_t size)
    {
        static ref<Store> store = openStore("dummy://");
        static fetchers::Settings fetchSettings;
        static bool readOnlyMode = true;
        static EvalSettings evalSettings{readOnlyMode};
        static EvalState state({}, store, fetchSettings, evalSettings, nullptr);

        try
        {
            auto ptr = reinterpret_cast<const char *>(data);
            std::string input(ptr, size);

            state.parseExprFromString(input, state.rootPath(CanonPath::root));
        }
        catch(const std::exception & e)
        {
            // ignore errors
        }

        return 0;
    }
}
