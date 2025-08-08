import Foundation

let enToRu: [Character: Character] = [
    "`": "ё",
    "q": "й",
    "w": "ц",
    "e": "у",
    "r": "к",
    "t": "е",
    "y": "н",
    "u": "г",
    "i": "ш",
    "o": "щ",
    "p": "з",
    "[": "х",
    "]": "ъ",
    "a": "ф",
    "s": "ы",
    "d": "в",
    "f": "а",
    "g": "п",
    "h": "р",
    "j": "о",
    "k": "л",
    "l": "д",
    ";": "ж",
    "'": "э",
    "z": "я",
    "x": "ч",
    "c": "с",
    "v": "м",
    "b": "и",
    "n": "т",
    "m": "ь",
    ",": "б",
    ".": "ю",
    "/": ".",
]

var ruToEn: [Character: Character] = {
    var dict: [Character: Character] = [:]
    for (k, v) in enToRu {
        dict[v] = k
    }
    return dict
}()

func preserveCase(_ original: Character, mapped: Character) -> Character {
    let s = String(original)
    if s == s.uppercased() && s != s.lowercased() {
        return Character(String(mapped).uppercased())
    }
    return mapped
}

func mapChar(_ c: Character, using table: [Character: Character]) -> Character {
    let lower = Character(String(c).lowercased())
    if let mapped = table[lower] {
        return preserveCase(c, mapped: mapped)
    }
    return c
}

func mapString(_ s: String, using table: [Character: Character]) -> String {
    return String(s.map { mapChar($0, using: table) })
}

