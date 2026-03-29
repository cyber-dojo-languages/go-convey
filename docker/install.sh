#!/bin/bash -Eeu

mkdir cdl && cd cdl

cat > go.mod << 'EOF'
module cdl-go-convey

go 1.26.1

require github.com/smartystreets/goconvey
EOF

# Dummy file so go mod tidy and go build include testify/assert
cat > dummy.go << 'EOF'
package cdl
import _ "github.com/smartystreets/goconvey/convey"
EOF

# Resolve all deps (updates go.mod with indirect deps and populates go.sum)
go mod tidy

# Pre-compile testify into a shared build cache accessible by all users
mkdir /go/build-cache
GOCACHE=/go/build-cache go build ./...
chmod -R 777 /go/build-cache
