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
