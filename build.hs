module Main where

import Development.Shake
import Development.Shake.FilePath
import Development.Shake.Util
import Control.Applicative
import Data.List

main :: IO ()
main =
  shakeArgs shakeOptions $
  do let buildDir = "build"
         sourceFiles =
           [ "src//*.cpp"
           , "src//*.c"
           , "cores/teensy3//*.c"
           , "cores/teensy3//*.cpp"
           ]
         defines =
           [ "USB_SERIAL"
           , "F_CPU=96000000"
           , "__MK20DX256__"
           , "LAYOUT_US_ENGLISH"
           ]
         includeDirs =
           [ "src"
           ]
         stdIncludeDirs =
           [ "cores/teensy3"
           , "gcc-arm-none-eabi/arm-none-eabi/include/c++/4.9.3"
           , "gcc-arm-none-eabi/arm-none-eabi/include/c++/4.9.3/arm-none-eabi"
           , "gcc-arm-none-eabi/arm-none-eabi/include/c++/4.9.3/backward"
           , "gcc-arm-none-eabi/lib/gcc/arm-none-eabi/4.9.3/include"
           , "gcc-arm-none-eabi/lib/gcc/arm-none-eabi/4.9.3/include-fixed"
           , "gcc-arm-none-eabi/arm-none-eabi/include"
           ]
         warningFlags = [ "-Wall"
                        , "-Wno-multichar"
                        , "-Wno-unknown-attributes"
                        ]
         teensyWarningFlags = [ "-Wno-sometimes-uninitialized"
                              , "-Wno-implicit-exception-spec-mismatch"
                              , "-Wno-incompatible-pointer-types"
                              , "-Wno-compare-distinct-pointer-types"
                              , "-Wno-unused-function"
                              , "-Wno-tautological-compare"
                              ]
         optFlags = ["-Os"]
         defineFlags = ("-D" ++) <$> defines
         includeDirFlags = (("-I" ++) <$> includeDirs) ++
                           (("-isystem" ++) <$> stdIncludeDirs)
         targetFlags =
           [ "-march=armv7e-m"
           , "-mthumb"
           , "-m32"
           , "-mfloat-abi=soft"
           , "-target"
           , "arm-none-eabi"
           , "--sysroot=gcc-arm-none-eabi/arm-none-eabi"
           ]
         miscFlags = [ "-nostdinc"
                     , "-fshort-enums"
                     ]
         cFlags = warningFlags ++ targetFlags ++ optFlags ++ includeDirFlags ++ defineFlags ++ miscFlags
         cxxFlags = cFlags ++ [ "-fno-rtti"
                              , "-fno-exceptions"
                              , "-std=gnu++1y"
                              ]
     --
     want [buildDir </> "run.hex"]
     --
     phony "clean" $
       do putNormal $ "Cleaning files in " ++ buildDir
          removeFilesAfter buildDir ["//*"]
     --
     ".clang_complete" %>
       \out -> liftIO $ writeFile out (unlines cxxFlags)
     --
     buildDir </> "run.hex" %>
       \out ->
         do let elf = buildDir </> "run.elf"
            need [elf]
            cmd "arm-none-eabi-objcopy" "-O" "ihex" "-R" ".eeprom" elf out
     --
     buildDir </> "run.elf" %>
       \out ->
         do cs <- getDirectoryFiles "" sourceFiles
            let os =
                  [buildDir </> c <.> "o" | c <- cs]
            need os
            let linkerScript = "cores/teensy3/mk20dx256.ld"
                ldFlags = [ "--gc-sections"
                          , "--defsym=__rtc_localtime=0"
                          ]
                libs = ["m"]
                libFlags = ("-l" ++) <$> libs
                linkFlags = warningFlags ++ optFlags ++ targetFlags ++
                  [ "-Wl," ++ intercalate "," ldFlags
                  , "--specs=nano.specs"
                  , "-T" ++ linkerScript]
            cmd (WithStderr False) "clang" linkFlags "-o" out os libFlags
     --
     buildDir <//> "*.c.o" %>
       \out ->
         do let c = dropDirectory1 . dropExtension $ out
                m = out -<.> "m"
                cFlags' = if "cores/teensy3" `isPrefixOf` c
                            then cFlags ++ teensyWarningFlags
                            else cFlags
            () <- cmd (WithStderr False) "clang" cFlags' "-o" out "-c" c "-MMD" "-MF" m
            needMakefileDependencies m
     --
     buildDir <//> "*.cpp.o" %>
       \out ->
         do let c = dropDirectory1 . dropExtension $ out
                m = out -<.> "m"
                cxxFlags' = if "cores/teensy3" `isPrefixOf` c
                              then cxxFlags ++ teensyWarningFlags
                              else cxxFlags
            () <- cmd (WithStderr False) "clang++" cxxFlags' "-o" out "-c" c "-MMD" "-MF" m
            needMakefileDependencies m
