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
chmod -R 777 /go/build-cache

rm dummy.go
# Note: do NOT run go mod tidy again as it would remove goconvey from go.mod
