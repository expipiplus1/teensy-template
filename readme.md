# Teensy Template with Clang and Shake

A template for a project compiling for the teensy 3.1 board with clang.

[Shake][shake] is used to write the build system.

## Prerequisites

A Haskell compiler.

Clang.

[Shake][shake hackage].

[gcc-arm-none-eabi toolchain][gcc-arm-none-eabi] in a directory called gcc-arm-none-eabi. You can see this being explored in the `stdIncludeDirs` expression in build.hs. The contents of `gcc-arm-none-eabi/bin` must be on the path.

## Usage

All the sources for the project are listed in the `sourceFiles` expression in build.hs.

Defines and other flags are listed in build.hs too.

`runhaskell build` in this directory will build the project. You'll need the shake package installed.


[shake]: https://github.com/ndmitchell/shake
[shake hackage]: https://hackage.haskell.org/package/shake
[gcc-arm-none-eabi]: https://launchpad.net/gcc-arm-embedded/+download