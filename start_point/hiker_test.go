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
