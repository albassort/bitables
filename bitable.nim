import std/[unicode, tables, strformat, sequtils, random, sugar, hashes, typetraits]
proc invertTable*[A,B](a : Table[A,B]) : Table[B,A] =
    if a.len() != 0:
        echo a.len() 
        for x in a.pairs:
            result[x[1]] = x[0]
    else:
        return initTable[B,A]()

type 
    BiTable*[A; B] = ref object
        ATable* : Table[A, B]
        BTable* : Table[B, A]
        classifier* : proc(a : A) : bool

    canPrint = concept x 
        $x is string

#   Credit to beef for this... interesting code
proc hash*[T: distinct](val: T): Hash = distinctBase(val).hash()
proc `==`*[T: distinct](a, b: T): bool = distinctBase(a) == distinctBase(a)
proc `$`*[T: distinct](val: T): string = distinctBase(val)


proc initBiTable*[A; B](a : Table[A, B], classifier : static proc(a : A) : bool = nil) : BiTable[A,B]  =
    ##  Creates bitable, classifier should only be used if between two of the same types
    #   can be buggy if you do not init the ref object manually
    result = new BiTable[A, B]
    when A is B:
        when classifier.isNil:
            {.error: "you must provide a not null classifier if A == B. Alternatively use object holders or distinct classes with ==, Hash, and $ defined".}
        else:
            result.ATable = a
            result.BTable = invertTable(a)
            result.classifier = classifier
    when type(A) isnot type(B):
        result.ATable = a
        result.BTable = invertTable(a)

proc initBiTable*[A; B](classifier : static proc(a : A) : bool = nil) : BiTable[A,B]  =
    initBiTable(initTable[A,B](), classifier)

proc `[]`*[A,B](a : BiTable[A, B] | BiTable[A, A], input: A | B) : A | B =
    when a isnot BiTable[A,A]:
        when input is A: 
            a.ATable[input] 
        else:
            a.BTable[input]
    else:
        if a.classifier(input):
            a.Atable[input] 
        else:
            a.BTable[input] 


proc `[]=`*[A,B](a : BiTable[A, B] | BiTable[A, A], input: A | B, sink : A | B) =
    when a isnot BiTable[A,A]:
        when input is A: 
            a.ATable[input] = sink
            a.BTable[sink] = input
        else:
            a.BTable[input] = sink
            a.ATable[sink] = input
    else:
        if a.classifier(input):
            a.Atable[input] = sink
            a.Btable[sink] = input
        else:
            a.BTable[input] = sink
            a.ATable[sink] = input

proc contains*[A,B](a : BiTable[A, B] | BiTable[A, A], input: A | B) : bool =
    when a isnot BiTable[A,A]:
        when input is A: 
            a.ATable.contains(input)
        else:
            a.BTable.contains(input)
    else:
        if a.classifier(input):
            a.Atable.contains(input)
        else:
            a.BTable.contains(input)


proc `$`*(a : BiTable) : string =
    when a.Atable is canPrint and a.Btable is canPrint:
        return $a.Atable & "\n" & $a.Btable

proc len*[A,B](a : BiTable[A, B]) : int =
    return a.ATable.len()


static:
    echo "Doing static test"
    var rng {.compileTime.} = initRand(0x0)
    var floatTypes = initBiTable(initTable[float32, float64]())
    var a : float32 = 32
    var b : float64 = 64
    floatTypes[a] = b
    let held = floatTypes
    floatTypes[b] = a

    doAssert(held == floatTypes)
    doAssert(floatTypes[a] == b)
    doAssert(floatTypes[b] == a)

    echo "\u001b[32m", "[OK] ", "\u001b[0m", "Alternate types work!"

    proc classify(a : char) : bool =
        return isUpper(Rune(a))
    #   classified is required because they are of the same type
    var caseBiTable = initBiTable(initTable[char, char](), classify)
    var refLower, refUpper = initTable[char, char]()
    let upper = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    let lower = @"abcdefghijklmnopqrstuvwxyz"

    for (uppercase, lowercase) in zip(upper, lower):
        refLower[lowercase] = uppercase
        refUpper[uppercase] = lowercase
        if bool(rng.rand(0 .. 1)):
            caseBiTable[uppercase] = lowercase
        else:
            caseBiTable[lowercase] = uppercase

    doAssert(caseBiTable.Atable == refUpper)
    doAssert(caseBiTable.Btable == refLower)
    doAssert(caseBiTable['a'] == 'A')
    doAssert(caseBiTable['A'] == 'a')

    echo "\u001b[32m", "[OK] ", "\u001b[0m", "Same types with classifier work!"

    when not defined(debug) or defined(danger):
        dump caseBiTable['A'] == 'a'
        dump (caseBiTable['a'] == 'A')
        dump (caseBiTable.Atable == refUpper)
        dump (caseBiTable.Btable == refLower)
        dump (held == floatTypes)
        dump (floatTypes[a] == b)
        dump (floatTypes[b] == a)
