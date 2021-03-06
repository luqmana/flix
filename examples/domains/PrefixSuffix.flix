/**
 * An implementation of Prefix-Suffix domain.
 */
namespace PrefixSuffix {

    /**
     * The elements of the prefix lattice.
     */
    enum PS {
                   case Top,

        case Pre(Int), case Suf(Int),

              case PreSuf(Int, Int),

                   case Bot
    }

    /**
     * Returns `true` iff `e1` is less than or equal to `e2`.
     */
    def leq(e1: PS, e2: PS): Bool = match (e1, e2) with {
        case (PS.Bot, _)                            => true
        case (PS.PreSuf(p1, s1), PS.PreSuf(p2, s2)) => p1 == p2 && s1 == s2
        case (PS.PreSuf(p1, _), PS.Pre(p2))         => p1 == p2
        case (PS.PreSuf(_, s1), PS.Suf(s2))         => s1 == s2
        case (PS.Pre(p1), PS.Pre(p2))               => p1 == p2
        case (PS.Suf(s1), PS.Suf(s2))               => s1 == s2
        case (_, PS.Top)                            => true
        case _                                      => false
    }

    /**
     * Returns the least upper bound of `e1` and `e2`.
     */
    @commutative @associative
    def lub(e1: PS, e2: PS): PS = match (e1, e2) with {
        case (PS.Bot, x)                        => x
        case (x, PS.Bot)                        => x
        case (PS.PreSuf(p1, s1), PS.PreSuf(p2, s2)) => switch {
            case (p1 == p2) && (s1 == s2)       => PS.PreSuf(p1, s1)
            case (p1 == p2) && (s1 != s2)       => PS.Pre(p1)
            case (p1 != p2) && (s1 == s2)       => PS.Suf(s1)
            case true                           => PS.Top
        }
        case (PS.PreSuf(p1, _), PS.Pre(p2))     => if (p1 == p2) PS.Pre(p1) else PS.Top
        case (PS.Pre(p1), PS.PreSuf(p2, _))     => if (p1 == p2) PS.Pre(p1) else PS.Top
        case (PS.PreSuf(_, s1), PS.Suf(s2))     => if (s1 == s2) PS.Suf(s1) else PS.Top
        case (PS.Suf(s1), PS.PreSuf(_, s2))     => if (s1 == s2) PS.Suf(s1) else PS.Top
        case (PS.Pre(p1), PS.Pre(p2))           => if (p1 == p2) PS.Pre(p1) else PS.Top
        case (PS.Suf(s1), PS.Suf(s2))           => if (s1 == s2) PS.Suf(s1) else PS.Top
        case _                                  => PS.Top
    }

    /**
     * Returns the greatest lower bound of `e1` and `e2`.
     */
    @commutative @associative
    def glb(e1: PS, e2: PS): PS = match (e1, e2) with {
        case (PS.Top, x)                        => x
        case (x, PS.Top)                        => x
        case (PS.PreSuf(p1, s1), PS.PreSuf(p2, s2)) =>
            if (p1 == p2 && s1 == s2) PS.PreSuf(p1, s1) else PS.Bot
        case (PS.PreSuf(p1, s1), PS.Pre(p2))    => if (p1 == p2) PS.PreSuf(p1, s1) else PS.Bot
        case (PS.Pre(p1), PS.PreSuf(p2, s2))    => if (p1 == p2) PS.PreSuf(p2, s2) else PS.Bot
        case (PS.PreSuf(p1, s1), PS.Suf(s2))    => if (s1 == s2) PS.PreSuf(p1, s1) else PS.Bot
        case (PS.Suf(s1), PS.PreSuf(p2, s2))    => if (s1 == s2) PS.PreSuf(p2, s2) else PS.Bot
        case (PS.Pre(p1), PS.Pre(p2))           => if (p1 == p2) PS.Pre(p1) else PS.Bot
        case (PS.Suf(s1), PS.Suf(s2))           => if (s1 == s2) PS.Suf(s1) else PS.Bot
        case (PS.Pre(p), PS.Suf(s))             => PS.PreSuf(p, s)
        case (PS.Suf(s), PS.Pre(p))             => PS.PreSuf(p, s)
        case _                                  => PS.Bot
    }

    /**
      * Over-approximates `concatenate`.
      */
    @strict @monotone @associative
    def concatenate(e1: PS, e2: PS): PS = match (e1, e2) with {
        case (PS.Bot, _)                            => PS.Bot
        case (_, PS.Bot)                            => PS.Bot
        case (PS.PreSuf(p1, _), PS.PreSuf(_, s2))   => PS.PreSuf(p1, s2)
        case (PS.PreSuf(p1, _), PS.Suf(s2))         => PS.PreSuf(p1, s2)
        case (PS.Pre(p1), PS.PreSuf(_, s2))         => PS.PreSuf(p1, s2)
        case (PS.Pre(p1), PS.Suf(s2))               => PS.PreSuf(p1, s2)
        case (PS.PreSuf(p1, _), PS.Pre(_))          => PS.Pre(p1)
        case (PS.Pre(p1), PS.Pre(_))                => PS.Pre(p1)
        case (PS.Suf(_), PS.PreSuf(_, s2))          => PS.Suf(s2)
        case (PS.Suf(_), PS.Suf(s2))                => PS.Suf(s2)
        case (PS.Suf(_), PS.Pre(_))                 => PS.Top
        case (PS.Pre(p1), PS.Top)                   => PS.Pre(p1)
        case (PS.PreSuf(p1, _), PS.Top)             => PS.Pre(p1)
        case (PS.Top, PS.Suf(s2))                   => PS.Suf(s2)
        case (PS.Top, PS.PreSuf(_, s2))             => PS.Suf(s2)
        case _                                      => PS.Top
    }

    /**
      * Over-approximates `equal`.
      */
    @strict @monotone @commutative
    def eq(e1: PS, e2: PS): Belnap/Belnap = match (e1, e2) with {
        case (PS.Bot, _)            => Belnap/Belnap.Bot
        case (_, PS.Bot)            => Belnap/Belnap.Bot
        case (PS.PreSuf(p1, s1), PS.PreSuf(p2, s2)) => switch {
            case (p1 != p2) => Belnap/Belnap.False
            case (s1 != s2) => Belnap/Belnap.False
            case true       => Belnap/Belnap.Top
        }
        case (PS.Pre(p1), PS.Pre(p2))           => if (p1 != p2) Belnap/Belnap.False else Belnap/Belnap.Top
        case (PS.Suf(s1), PS.Suf(s2))           => if (s1 != s2) Belnap/Belnap.False else Belnap/Belnap.Top
        case (PS.Pre(p1), PS.PreSuf(p2, _))     => if (p1 != p2) Belnap/Belnap.False else Belnap/Belnap.Top
        case (PS.PreSuf(p1, _), PS.Pre(p2))     => if (p1 != p2) Belnap/Belnap.False else Belnap/Belnap.Top
        case (PS.Suf(s1), PS.PreSuf(_, s2))     => if (s1 != s2) Belnap/Belnap.False else Belnap/Belnap.Top
        case (PS.PreSuf(_, s1), PS.Suf(s2))     => if (s1 != s2) Belnap/Belnap.False else Belnap/Belnap.Top
        case _                                  => Belnap/Belnap.Top
    }

    /**
      * Over-approximates `not equal`.
      */
    @strict @monotone @commutative
    def neq(e1: PS, e2: PS): Belnap/Belnap = Belnap/not(eq(e1, e2))

    // TODO: Less equal?

    let PS<> = (PS.Bot, PS.Top, leq, lub, glb)

}