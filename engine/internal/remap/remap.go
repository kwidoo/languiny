package remap

// RemapWord returns a remapped string from layout `from` to `to`.
func RemapWord(s string, from, to int) (string, error) {
	var table map[rune]rune
	switch {
	case from == LayoutEnUS && to == LayoutRuRU:
		table = enToRu
	case from == LayoutRuRU && to == LayoutEnUS:
		table = ruToEn
	default:
		return s, nil
	}
	return mapString(s, table), nil
}
