#!/bin/sh

# Usage:
#     Update to the latest cmark-gfm version:
#         ./update_cmark.sh
#     Update to the specified cmark-gfm commit:
#         ./update_cmark.sh [commit]

# Clear cmark directory
rm -rf Sources/cmark
mkdir -p Sources/cmark/include

# Create module map
echo "module libcmark [system][extern_c] {
    header \"../node.h\"
    export *
}" > Sources/cmark/include/module.modulemap

# Clone cmark-gfm and checkout a commit if specified
git clone https://github.com/github/cmark-gfm.git
if [ -n "$1" ]; then
    cd cmark-gfm
    git checkout $1 .
    cd ..
fi

# Copy `COPYING`
cp cmark-gfm/COPYING Sources/cmark

# Copy source files
cp cmark-gfm/src/*.c cmark-gfm/src/*.h cmark-gfm/src/*.re cmark-gfm/src/*.inc Sources/cmark

# Delete `main.c` because it causes issues
rm Sources/cmark/main.c

# Create generated files
mkdir cmark-gfm/build
cd cmark-gfm/build
cmake ..
cd ../..

# Copy generated files
cp cmark-gfm/build/src/*.h Sources/cmark

# Clean up
rm -rf cmark-gfm