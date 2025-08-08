package remap

import "unicode"

const (
	LayoutEnUS = iota
	LayoutRuRU
)

var enToRu = map[rune]rune{
	'`':  'ё',
	'q':  'й',
	'w':  'ц',
	'e':  'у',
	'r':  'к',
	't':  'е',
	'y':  'н',
	'u':  'г',
	'i':  'ш',
	'o':  'щ',
	'p':  'з',
	'[':  'х',
	']':  'ъ',
	'a':  'ф',
	's':  'ы',
	'd':  'в',
	'f':  'а',
	'g':  'п',
	'h':  'р',
	'j':  'о',
	'k':  'л',
	'l':  'д',
	';':  'ж',
	'\'': 'э',
	'z':  'я',
	'x':  'ч',
	'c':  'с',
	'v':  'м',
	'b':  'и',
	'n':  'т',
	'm':  'ь',
	',':  'б',
	'.':  'ю',
	'/':  '.',
}

var ruToEn map[rune]rune

func init() {
	ruToEn = make(map[rune]rune, len(enToRu))
	for k, v := range enToRu {
		ruToEn[v] = k
	}
}

func mapChar(r rune, table map[rune]rune) rune {
	lower := unicode.ToLower(r)
	mapped, ok := table[lower]
	if !ok {
		return r
	}
	return preserveCase(r, mapped)
}

func mapString(s string, table map[rune]rune) string {
	out := make([]rune, 0, len(s))
	for _, r := range s {
		out = append(out, mapChar(r, table))
	}
	return string(out)
}

func preserveCase(src, dst rune) rune {
	if unicode.IsUpper(src) {
		return unicode.ToUpper(dst)
	}
	return dst
}
