x86-strlib
==========

String subroutines written in x86 assembly language. Provides DOS and BIOS-level functionality.

To compile using the given scripts requires SCons and the OpenWatcom compiler suite. However, any 
MASM 5.0-compatible assembler should be able to compile it without the use of SCons.

Run "scons -n -Q test > BUILD.BAT" to create a list of commands to be compiled on a target machine
such as an AT or XT-class machine.
