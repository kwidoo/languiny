package main

/*
#cgo CFLAGS: -std=gnu11
#cgo LDFLAGS: 
#include <stdlib.h>
*/
import "C"
import (
	"unsafe"

	"github.com/you/kbd-switch/engine/internal/detect"
	"github.com/you/kbd-switch/engine/internal/remap"
)

//export RemapWord
func RemapWord(cstr *C.char, fromLayout C.int, toLayout C.int) *C.char {
	if cstr == nil {
		return nil
	}
	goStr := C.GoString(cstr)
	res, err := remap.RemapWord(goStr, int(fromLayout), int(toLayout))
	if err != nil {
		return nil
	}
	return C.CString(res)
}

//export ShouldSwitch
func ShouldSwitch(cstr *C.char, currentLayout C.int) C.int {
	if cstr == nil {
		return -1
	}
	goStr := C.GoString(cstr)
	ok, err := detect.ShouldSwitch(goStr, int(currentLayout))
	if err != nil {
		return -1
	}
	if ok {
		return 1
	}
	return 0
}

//export FreeCString
func FreeCString(ptr *C.char) {
	if ptr != nil {
		C.free(unsafe.Pointer(ptr))
	}
}

func main() {}
