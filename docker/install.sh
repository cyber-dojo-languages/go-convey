#!/bin/bash -Eeu

mkdir cdl && cd cdl

go mod init cdl-go-convey

cat > dummy.go << 'EOF'
package cdl
import _ "github.com/smartystreets/goconvey/convey"
EOF

# Download goconvey and all its deps, update go.mod with versions and go.sum with hashes
go mod tidy

# Pre-compile goconvey into a shared build cache accessible by all users
mkdir /go/build-cache
GOCACHE=/go/build-cache go build ./...

# Building the library is not what a kata does. A [test] press runs [go test],
# which additionally compiles the test variant of each package and links a test
# binary, and neither of those is produced by the build above. Without them the
# first press in a fresh container rebuilt them every time, which was most of
# the wait; a kata runs in a container thrown away afterwards, so every press
# was a first press.
#
# The warm-up below is shaped like a real kata, a package and a test asserting
# against it through goconvey, so the entries it leaves are the ones a kata
# reaches for.
mkdir warmup && cd warmup

go mod init cdl-go-convey-warmup

cat > hiker.go << 'EOF'
package hiker

func answer() int {
    return 42
}
EOF

cat > hiker_test.go << 'EOF'
package hiker

import (
    "testing"
    . "github.com/smartystreets/goconvey/convey"
)

func Test_life_the_universe_and_everything(t *testing.T) {
    Convey("A simple example to start you off", t, func() {
        So(answer(), ShouldEqual, 42)
    })
}
EOF

go mod tidy
GOCACHE=/go/build-cache go test

# A cache is keyed on the toolchain and the flags that filled it. If those ever
# drift from what cyber-dojo.sh runs, go silently rebuilds and the press is
# merely as slow as it was before. Timing the second run catches that here
# rather than leaving it to be noticed as a gradual slowdown: against a warm
# cache it is a fraction of a second, and against a cold one it is not.
readonly WARM_SECONDS=$( { TIMEFORMAT='%3R'; time GOCACHE=/go/build-cache go test > /dev/null 2>&1; } 2>&1 )
echo "second [go test] against the warmed cache took ${WARM_SECONDS}s"

if [ "$(echo "${WARM_SECONDS} < 0.5" | bc -l)" != '1' ]; then
  >&2 echo "Expected a warmed cache to answer in well under half a second."
  >&2 echo "The cache is not being hit, so a kata's first press will rebuild."
  exit 42
fi

cd ..
rm -rf warmup
chmod -R 777 /go/build-cache

rm dummy.go
# Note: do NOT run go mod tidy again as it would remove goconvey from go.mod
