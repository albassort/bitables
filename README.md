# BITABLES
For all of your bi-directional data needs!

```nim
import bitables, tables
let bi = initBiTable[float32, float64]()
bi[32'f32] = 64'f64
#returns true!
doAssert(bi[64'f64] == 32'f32)
```
boom.

# Bidirectional tables between the same type
method 1: classifiers
A classifier is a proc with an input of the type you are creating the bitable, that yields a boolean.

```nim
proc classify(a : char) : bool =
    return isUpper(Rune(a))
# classify will now be used to distinguish between the two tables
var caseBiTable = initBiTable[char, char](classify)
caseBiTable['a'] = 'A'
doAssert(caseBiTable['a'] == 'A')
```

This is my preferred method, because you only need to manage state once, in a single proc. Though the same effect can be achieved with distinct types
method 2: distinct types
```nim
type
  upper = distinct  char
  lower = distinct  char
let x = initBiTable[upper, lower]()
x[upper('A')] = lower('b')
```

credit to ElegantBeef for making this method possible with writing the hashing code


# Creating BiTables from Tables
```nim
let newTable = initBiTable({"a" : 'A'}.toTable())
echo newTable
#{"a": 'A'}  
#{'A': "a"}
```
