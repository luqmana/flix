namespace List {

    //
    // ## Basic Operations
    //

    /**
     * Returns true iff `xs` is the empty list, i.e. `Nil`.
     */
    def null(xs: List[A]): Bool = match xs with {
        case Nil => true
        case _ => false
    }

    /**
     * Returns the first element of the list. If the list is empty the semantics are undefined.
     */
    def head(xs: List[A]): A = match xs with {
        case x :: _ => x
    }

    /**
     * Returns the list consisting of everything but the first element of the list.
     * If the list is empty the semantics are undefined.
     */
    def tail(xs: List[A]): List[A] = match xs with {
        case _ :: rs => rs
    }

    /**
     * Returns the list with all the elements except the last.
     * If the list is empty the semantics are undefined.
     */
    def init(xs: List[A]): List[A] = match xs with {
        case Nil => Nil
        case x :: Nil => Nil
        case x :: rs => x :: init(rs)
    }

    /**
     * Returns the last element of the list.
     * If the list is empty the semantics are undefined.
     */
    def last(xs: List[A]): A = match xs with {
        case x :: Nil => x
        case x :: rs => last(rs)
    }

    /**
     * Returns the length of the list.
     */
    def length(xs: List[A]): Int = match xs with {
        case Nil => 0
        case x :: rs => 1 + length(rs)
    }

    /**
     * Appends the second list to the first.
     */
    def append(xs: List[A], ys: List[A]): List[A] = match xs with {
        case Nil => ys
        case x :: rs => x :: append(rs, ys)
    }

    /**
     * Returns the element at the given position in the list.
     */
    def at(pos: Int, xs: List[A]): A = match (pos, xs) with {
        case (0, x :: _) => x
        case (i, x :: rs) => at(i - 1, rs)
    }

    /**
     * Returns true if the list contains the element `x`.
     */
    def memberOf(x: A, xs: List[A]): Bool = match xs with {
        case Nil => false
        case y :: rs => if (x == y) true else memberOf(x, rs)
    }

    /**
     * Returns the position of the element `x` in the list `xs`.
     * If the element does not exist in the list the semantics are undefined.
     */
    def indexOf(x: A, xs: List[A]): Int =
        letrec visit = (i, ys) -> match ys with {
            case Nil => ???
            case y :: rs => if (x == y) i else visit(i + 1, rs)
        }
        in visit(0, xs)

    /**
     * Alias for `findLeft`.
     */
    def find(f: A -> Bool, xs: List[A]): Opt[A] = findLeft(f, xs)

    /**
     * Optionally returns the first element that satisfies the predicate `f`.
     */
    def findLeft(f: A -> Bool, xs: List[A]): Opt[A] = match xs with {
        case Nil => None
        case x :: rs => if (f(x)) Some(x) else findLeft(f, rs)
    }

    /**
     *  Similar to `findLeft` but searches from right to left.
     */
    def findRight(f: A -> Bool, xs: List[A]): Opt[A] = match xs with {
        case Nil => None
        case x :: rs => match findRight(f, xs) with {
            case None => if (f(x)) Some(x) else None
            case Some(v) => Some(v)
        }
    }

    //
    // ## List Building
    //

    /**
     *  Returns a list of all integers between `b` (inclusive) and `e` (exclusive).
     */
    def range(b: Int, e: Int): List[Int] =
        if (b == e)
            Nil
        else
            b :: range(b + 1, e)

    /**
     * Returns a list with the element `x` repeated `n` times.
     */
    def repeat(x: A, n: Int): List[A] =
        if (n == 0)
            Nil
        else
            x :: repeat(x, n - 1)

    /**
     *  Alias for `scanLeft`.
     */
    def scan(f: (B, A) -> B, b: B, xs: List[A]): List[B] = scanLeft(f, b, xs)

    /**
     * Accumulates the result of applying the function `f` to the list going left to right.
     *
     * That is, the result is of the form:
     * `b :: f(b, x1) :: f(f(b, x1), x2)  ...`
     */
    def scanLeft(f: (B, A) -> B, b: B, xs: List[A]): List[B] = ??? // TODO

    /**
     * Similar to `scanLeft` but going right to left.
     */
    def scanRight(f: (A, B) -> B, b: B, xs: List[A]): List[B] = ??? // TODO

    //
    // ## List Transformation
    //

    /**
     * Returns the result of applying the function `f` to every element in the list.
     */
    def map(f: A -> B, xs: List[A]): List[B] = match xs with {
        case Nil => Nil
        case y :: rs => f(y) :: map(f, rs)
    }

    /**
     * Similar to `map` but additionally passes the index of every element to `f`.
     */
    def mapWithIndex(f: (A, Int) -> B, xs: List[A]): List[B] =
        letrec visit = (i, ys) = match ys with {
            case Nil => Nil
            case y :: rs => f(y, i) :: visit(i + 1, rs)
        }
        in visit(0, xs)

//- **flatMap(f: A => List[B], xs: List[A]): List[B]**
//    - Returns the result of applying the function f to every element in the list and concatenating the result. Aliased as concatMap.
//- **reverse(xs: List[A]): List[A]**
//    - Returns the reversed list.
//- **rotateLeft(n: Int, xs: List[A]): List[A]**
//    - Rotates the elements of the list n positions to left. That is, returns a new list where the first n elements in the original list are the last n elements of the new list.
//- **rotateRight(n: Int, xs: List[A]): List[A]**
//    - Similar to rotateLeft, but rotates to the right.
//- **replace(i: Int, x: A, xs: List[A]): List[A]**
//    - Replaces the element at position i with the element x in the list xs.
//    - If the position i does not exist in the list the semantics are undefined.
//- **patch(i: Int, n: Int, xs: List[A], ys: List[A]): List[A]**
//    - Replaces n elements at position i in ys with elements from xs.
//- **permutations(xs: List[A]): List[List[A]]**
//    - Returns all permutations of the list.
//- **subsequences(xs: List[A]): List[List[A]]**
//    - Returns all subsequences of the list.
//- **intersperse(x: A, xs: List[A]): List[A]**
//    - Returns the list with the element x inserted between every element.
//- **intercalate(xs: List[A], ys: List[List[A]]): List[A]**
//    - Returns the concatenation of the list ys with the list xs inserted between every element.
//- **transpose(xs: List[List[A]]): List[List[A]]**
//    - Returns the transpose of the list.
//    - If the dimensions of the lists are mismatched the semantics are undefined.
//

    //
    // ## List Predicates
    //

    /**
     *  Returns `true` if the list `xs` is a prefix of the list `ys`.
     */
    def isPrefixOf(xs: List[A], ys: List[B]): Bool = match (xs, ys) with {
        case (Nil, _) => true
        case (_, Nil) => false
        case (x :: xs1, y :: ys1) => if (x == y) isPrefixOf(xs1, ys1) else false
    }

    /**
     *  Returns `true` if the list `xs` is an infix of the list `ys`.
     */
    def isInfixOf(xs: List[A], ys: List[B]): Bool = ??? : Bool // TODO

    /**
     *  Returns `true` if the list `xs` is a suffix of the list `ys`.
     */
    def isSuffixOf(xs: List[A], ys: List[B]): Bool = isPrefixOf(reverse(xs), reverse(ys))

    //
    // ## Fold And Reduce
    //

    /**
     *  Alias of foldLeft.
     */
    def fold(f: (B, A) -> B, b: B, xs: List[A]): B = foldLeft(f, b, xs)

    /**
     *  Left-associative fold of the list xs.
     */
    def foldLeft(f: (B, A) -> B, b: B, xs: List[A]): B = ??? : B

    //- **foldRight(f: (A, B) => B, b: B, xs: List[A]): B**
    //    - Right-associative fold of the list xs.
    //- **reduce(f: (A, A) => A, xs: List[A]): A**
    //    - Alias for reduceLeft.
    //- **reduceLeft(f: (A, A) => A, xs: List[A]): A**
    //    - Left-associative reduce of the list xs.
    //    - If the list is empty the semantics are undefined.
    //- **reduceOpt(f: (A, A) => A, xs: List[A]): Opt[A]**
    //    - Alias for reduceLeftOpt.
    //- **reduceLeftOpt(f: (A, A) => A, xs: List[A]): Opt[A]**
    //    - Safe variant of reduceLeft that returns None if the list is empty.
    //- **reduceRight(f: (A, A) => A, xs: List[A]): A**
    //    - Right-associative reduce of the list xs.
    //    - If the list is empty the semantics are undefined.
    //- **reduceRightOpt(f: (A, A) => A, xs: List[A]): Opt[A]**
    //    - Safe variant of reduceRight that returns None if the list is empty.
//
//## Special Folds
//- **count(f: A => Bool, xs: List[A]): Int**
//    - Returns the number of elements in the list that satisfy the predicate f.
//- **concat(xs: List[List[A]]): List[A]**
//    - Returns the concatenation of the lists in the list xs.
//- **exists(f: A => Bool, xs: List[A]): Bool**
//    - Returns true iff at least one element in the list satisfies the predicate f.
//    - Returns false if the list is empty.
//- **forall(f: A => Bool, xs: List[A]): Bool**
//    - Returns true iff every element in the list satisfies the predicate f.
//    - Returns true if the list is empty.
//- **and(xs: List[Bool]): Bool**
//    - Returns true iff every element in the list is true. Returns true if the list is empty.
//- **or(xs: List[Bool]): Bool**
//    - Returns true iff at least one element in the list is true. Returns false if the list is empty.
//
//## Sub Lists
//- **filter(f: A => Bool, xs: List[A]): List[A]**
//    - Returns a list of every element in the list xs that satisfy the predicate f.
//- **slice(b: Int, e: Int, xs: List[A]): List[A]**
//    - Returns the sublist from position b (inclusive) until position e (exclusive).
//- **partition(f: A => Bool, xs: List[A]): (List[A], List[A])**
//    - Returns a pair of lists (ys, zs) where are the elements in xs are those that satisfy the predicate f and the elements in zs are those that do not.
//- **span(f: A => Bool, xs: List[A]): (List[A], List[A])**
//    - Returns a pair of lists (ys, zs) where ys is the longest prefix of xs that satisfies the predicate f and zs is the remainder of xs. Functionally equivalent to (takeWhile(f, xs), dropWhile(f, xs)).
//- **drop(n: Int, xs: List[A]): List[A]**
//    - Returns the list except for the first n elements.
//    - Returns the empty list if n is larger than the length of the list.
//- **dropWhile(f: A => Bool, xs: List[A]): List[A]**
//    - Returns the list except for the longest prefix that satisfy the predicate f.
//- **take(n: Int, xs: List[A]): List[A]**
//    - Returns the first n elements of xs.
//    - Returns the entire list if n is larger than the length of the list.
//- **takeWhile(f: A => Bool, xs: List[A]): List[A]**
//    - Returns the longest prefix of xs that satisfy the predicate f.
//
//## Aggregation and Sorting
//- **sum(xs: List[Int]): Int**
//    - Returns the sum of the elements in the list.
//    - Returns zero if the list is empty.
//- **product(xs: List[Int]): Int**
//    - Returns the product of the elements in the list.
//    - Returns one if the list is empty.
//- **min(xs: List[Int]): Int**
//    - Returns the minimum element of a non-empty list.
//    - If the list is empty the semantics are undefined.
//- **max(xs: List[Int]): Int**
//    - Returns the maximum element of a non-empty list.
//    - If the list is empty the semantics are undefined.
//- **minBy(f: (A, A) => Bool, xs: List[Int]): Int**
//    - Returns the minimum element of a non-empty list according the total order defined by the predicate f. That is, if f(x, y) == true then x is smaller or equal to y. Two elements are equal if f(x, y) = f(y, x).
//    - If the list is empty the semantics are undefined.
//- **maxBy(f: (A, A) => Bool, xs: List[Int]): Int**
//    - Similar to minBy but returns the largest element.
//- **sort(xs: List[Int]): Int**
//    - Returns the elements of the list sorted according to the natural order.
//- **sortBy(f: (A, A) => Bool, xs: List[Int]): Int**
//    - Returns the elements of the list sorted according to the total order defined by the predicate f. That is, if f(x, y) == true then x is smaller or equal to y. Two elements are equal if f(x, y) = f(y, x).
//- **groupBy(f: (A, A) => Bool, xs: List[A]): List[List[A]]**
//    - Partitions the list xs into sublists such that for any two elements x and y in a sub list f(x, y) is true.
//
//## Zipping and Unzipping
//- **zip(xs: List[A], ys: List[B]): List[(A, B)]**
//    - Returns a list where each element at index i is the pair (a, b) where a is the element at position i in xs and b is the element at position i in ys.
//- **zipWith(f: (A, B) => C, xs: List[A], ys: List[B]): List[C]**
//    - Like zip but uses the function f to compute each element in the result.
//    - Functionally equivalent to: map(f, zip(xs, ys)).
//- **unzip(xs: List[(A, B)]): (List[A], List[B])**
//    - Returns a pair where the first component is a list of all first components in xs and the second component is a list of all second components in xs.
//
//## Two List Operations
//- **map2(f: (A, B) => C, xs: List[A], ys: List[B]): List[C]**
//    - Pairwise applies the function f to the elements of the lists xs and ys. Functionally equivalent to zipWith.
//- **flatMap2(f: (A, B) => List[C], xs: List[A], ys: List[B]): List[C]**
//    - Pairwise applies the function f to the elements of the lists xs and ys and concatenates the result in one list. Functionally equivalent to flatten(map2(f, xs, ys)).
//- **fold2(f: (C, A, B) => C, c: C, xs: List[A], ys: List[B]): C**
//    - Alias for foldLeft2.
//- **foldLeft2(f: (C, A, B) => C, c: C, xs: List[A], ys: List[B]): C**
//    - Accumulates the result of applying the function f pairwise to the elements of xs and ys starting with the initial value c going from left to right. Functionally similar to foldLeft(f, c, zip(xs, ys)).
//- **foldRight2(f: (A, B, C) => C, c: C, xs: List[A], ys: List[B]): C**
//    - Similar to foldLeft2 but goes from the right to the left.
//
//## Combined Operations
//- **concatMap(f: A => List[B], xs: List[A]): List[B]**
//    - Alias for flatMap.
//- **filterMap(f: A => Opt[B], xs: List[A]): List[B]**
//    - Collects the result of applying the partial function f to each element of the list.
//- **findMap(f: A => Opt[B], xs: List[A]): Opt[B]**
//    - Collects the first result of applying the partial function f to each element of the list.
//
//## List Conversions
//- **toMap(xs: List[(A, B)]): Map[A, B]**
//    - Returns the association list as a map. If the list contains multiple values for the same key, the value appearing latest in the list is used.
//- **toSet(xs: List[A]): Set[A]**
//    - Returns the list as a set.
//
//## Order and Lattice Operations
//- **leq(xs: List[A], ys: List[A]): Bool**
//    - Returns true if every element in xs is pairwise smaller or equal to its corresponding element in ys. That is, for any position i in xs, it must be the case that at(i, xs) is smaller or equal to at(i, ys) (if it exists) according to the partial order on A. Functionally equivalent to to zipWith(leq, xs, ys).and where leq is the partial order on A.
//- **isAscChain(xs: List[A]): Bool**
//    - Returns true iff the elements in xs form an ascending chain. That is, if  according to the partial order on A.
//    - NB: In general, isAscChain is not the negation of isDescChain since a list may fail to be a chain due to two elements being incomparable.
//- **isDescChain(xs: List[A]): Bool**
//    - Returns true iff the elements in xs form a descending chain. That is, if  according to the partial order on A.
//    - NB: In general, isDescChain is not the negation of isAscChain since a list may fail to be a chain due to two elements being incomparable.
//- **join(xs: List[A]): A**
//    - Returns the least upper bound of all element in xs. If the list is empty, returns the bottom element of A. Functionally equivalent to foldLeft(lub, bot, xs) where lub and bot are the least upper bound and bottom element of A, respectively.
//- **meet(xs: List[A]): A**
//    - Similar to lub, but with the greatest lower bound and top element.
//- **widen(xs: List[A]): A**
//    - Similar to lub, but with the widening operator.
//- **narrow(xs: List[A]): A**
//    - Similar to lub, but with the narrowing operator.
//- **zipWithJoin(xs: List[A], ys: List[A]): List[A]**
//    - Returns the pairwise least upper bound of the two lists xs and ys. Functionally equivalent to zipWith(lub, xs, ys) where lub is the least upper bound of A.
//- **zipWithMeet(xs: List[A], ys: List[A]): List[A]**
//    - Similar to zipWithJoin, but with the greatest lower bound.
//


}