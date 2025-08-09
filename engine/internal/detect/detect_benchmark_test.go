package detect

import "testing"

func BenchmarkShouldSwitch(b *testing.B) {
    for i := 0; i < b.N; i++ {
        ShouldSwitch("abcdefghijkl", 0)
    }
}
