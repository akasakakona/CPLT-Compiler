# Language Features
- [x] Integer scale variables
```bash
itg x
itg y
```
- [x] 1-D array of integers 
`itg a[] = {1, 2, 3}`
- [x] Assignment statements
`itg x = 5`
- [x] Arithmetic operators
```bash
itg x
x = 3 + 2
x = 2 - 1
x = 4 * 4
x = 12 / 6
```
- [x] Relational operators
```bash
itg x
itg y

x = 5
y = 3

x > 6
x != y 
y < 3
x == y
```
- [x] While or do-while loops
```bash
itg x
itg y

x = 5
y = 3

whl x > 6 {
  y = y + 1
}

whl x != y {
  y = y + 1
}
```
- [x] Break statement
- [x] If-then-else statements
- [x] Read and write statements
- [x] Comments
- [x] Function

# Code Generator

This part of the project translates parsed code into intermediate representation (IR), so that we can further translate it into assembly language later on.


The generated IR will be in `.mil` format. 


The following command will generate the compiler binary for our language `compilot`:

You can either manually type the following command OR using our included `compile.sh` file.
```bash
bison -v -d --file-prefix=y compilot.y
flex compilot.lex
g++ -std=c++11 -o cplt y.tab.c lex.yy.c -lfl
```

For MacOS Users:
Replace `-lfl` with `-ll`
```bash
bison -v -d --file-prefix=y compilot.y
flex compilot.lex
g++ -std=c++11 -o cplt y.tab.c lex.yy.c -ll
```

Once the compiler binary has been generated, we can generate the IR using the following command:

`./cplt code.cplt`

Once IR has been generated, we can run it using the included `mil_run` binary file with the following command: 

`./mil_run mil_code.mil`.

**Note:** Since `mil_run` is an x64 binary, this can only be done on an x64 machine.
