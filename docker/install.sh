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
# merely as slow as it was before. This compares a run against the warmed cache
# with one against an empty one, and insists the warm run be several times
# quicker.
#
# The comparison is against a cold run rather than a fixed number of seconds
# because this same script runs under QEMU when the arm64 half of the image is
# built on an amd64 machine. Emulated, a warm run takes seconds where it takes a
# fraction of one natively, so any threshold that fits one fails the other. A
# ratio holds either way: both runs are slowed by the same emulation.
go_test_seconds()
{
  local -r cache_dir="${1}"
  { TIMEFORMAT='%3R'; time GOCACHE="${cache_dir}" go test > /dev/null 2>&1; } 2>&1
}

readonly COLD_SECONDS=$(go_test_seconds /tmp/cold-cache)
readonly WARM_SECONDS=$(go_test_seconds /go/build-cache)
echo "[go test] cold ${COLD_SECONDS}s, warm ${WARM_SECONDS}s"
rm -rf /tmp/cold-cache

if [ "$(echo "${COLD_SECONDS} > ${WARM_SECONDS} * 3" | bc -l)" != '1' ]; then
  >&2 echo "Expected a warmed cache to be several times quicker than an empty one."
  >&2 echo "The cache is not being hit, so a kata's first press will rebuild."
  exit 42
fi

cd ..
rm -rf warmup
chmod -R 777 /go/build-cache

rm dummy.go
# Note: do NOT run go mod tidy again as it would remove goconvey from go.mod
