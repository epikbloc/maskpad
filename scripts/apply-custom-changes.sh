#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/sources/2ship2harkinian/mm/2s2h/BenPort.cpp"

if [ ! -f "$SRC" ]; then
    echo "BenPort.cpp not found at $SRC" >&2
    exit 1
fi

python3 - "$SRC" << 'PYEOF'
import sys

filepath = sys.argv[1]
with open(filepath, 'r') as f:
    content = f.read()

# 1. Add #include <filesystem> after #include <cstdlib>
content = content.replace(
    '#include <cstdlib>',
    '#include <cstdlib>\n#include <filesystem>',
    1
)

# 2. Change FPS from 20 to 60
content = content.replace(
    'CVarSetInteger("gInterpolationFPS", 20);',
    'CVarSetInteger("gInterpolationFPS", 60);'
)

# 3. Add 4x resolution after the FPS line
content = content.replace(
    'CVarSetInteger("gInterpolationFPS", 60);',
    'CVarSetInteger("gInterpolationFPS", 60);\n        CVarSetFloat(CVAR_INTERNAL_RESOLUTION, 4.0f);'
)

# 4. Add bundle-copy logic before "if (shouldGenerate)"
bundle_code = '''#ifdef __IOS__
        {
            std::string _appDir = Ship::Context::GetAppDirectoryPath(appShortName);
            std::string _o2rDest = _appDir + "/mm.o2r";
            if (!std::filesystem::exists(_o2rDest)) {
                std::string _bundleO2r = Ship::Context::GetAppDirectoryPath("") + "/mm.o2r";
                if (std::filesystem::exists(_bundleO2r)) {
                    std::filesystem::copy_file(_bundleO2r, _o2rDest);
                    shouldGenerate = false;
                }
            } else {
                shouldGenerate = false;
            }
        }
#endif
'''
content = content.replace(
    '        if (shouldGenerate) {',
    bundle_code + '        if (shouldGenerate) {'
)

with open(filepath, 'w') as f:
    f.write(content)

print("Custom changes applied successfully")
PYEOF   