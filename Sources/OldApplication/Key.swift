/// representing keys on a standard american keyboard
/// which means: Key.Y will represent the Key that gives the letter z on german keyboards
/// prefix N for number keys, e.g. N0 --> 0
public enum Key: CaseIterable {

    case arrowUp, arrowRight, arrowDown, arrowLeft

    case `return`, enter, backspace, delete, space, escape

    case leftShift, leftCtrl, leftAlt

    case plus, minus

    case n0, n1, n2, n3, n4, n5, n6, n7, n8, n9
    
    case a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z

    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
}