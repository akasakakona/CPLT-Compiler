# Code Generator

This part of the project translates parsed code into intermediate representation (IR), so that we can further translate it into assembly language later on.


The generated IR will be in `.mil` format. 


Once IR has been generated, we can run it using the included `mil_run` binary file with the following command: `mil_run mil_code.mil`.
**Note:** Since `mil_run` is an x64 binary, this can only be done on an x64 machine.
