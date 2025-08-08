package remap

import "testing"

func TestMapStringExamples(t *testing.T) {
	if got := mapString("ghbdtn", enToRu); got != "привет" {
		t.Fatalf("ghbdtn -> %q", got)
	}
	if got := mapString("привет", ruToEn); got != "ghbdtn" {
		t.Fatalf("reverse failed: %q", got)
	}
}

func TestCasePreservation(t *testing.T) {
	if got := mapString("Ghbdtn", enToRu); got != "Привет" {
		t.Fatalf("Ghbdtn -> %q", got)
	}
	if got := mapString("GHBDTN", enToRu); got != "ПРИВЕТ" {
		t.Fatalf("GHBDTN -> %q", got)
	}
}

func TestRoundTripLetters(t *testing.T) {
	en := "`qwertyuiop[]asdfghjkl;'zxcvbnm,./"
	ru := "ёйцукенгшщзхъфывапролджэячсмитьбю."
	if back := mapString(mapString(en, enToRu), ruToEn); back != en {
		t.Fatalf("round trip en->ru->en = %q", back)
	}
	if back := mapString(mapString(ru, ruToEn), enToRu); back != ru {
		t.Fatalf("round trip ru->en->ru = %q", back)
	}
}

func TestPunctuationUnaffected(t *testing.T) {
	input := "12345!@#$% "
	if got := mapString(input, enToRu); got != input {
		t.Fatalf("punctuation changed: %q", got)
	}
}
