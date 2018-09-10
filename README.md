# Mar

An alternative D standard library.

# Goals

* Work without the C standard library and without druntime

> Note: it should also work with the C standard library via a "version" switch

Note that this also implies it works without the GC.

* Work with "Better C"
* Expose both "platform-specific" and "platform-agnostic" apis.
* Levarage D's type systems to create APIs with strong safety guarantees.

An example of this is the `SentinelPtr` template that results in a pointer to an array that guarantees the array ends with a "sentinel value".  The classic example of this is a "c string" which ends with a null character. By using `SentinelPtr` in an API, it documents this requirement and enforces it at compile time. This also facilitates better interoperation with C as it allows D to work with C strings making it unnecessary to marshal strings to temporary buffers every time they are passed to a C function.

# Build

Currently there's no build.  If you want to use it, you can add the following arguments to your compiler command:
```
-I=<mar_repo>/src -i=mar
```
> `-I=<mar_repo/src`: add mar to the include path
> `-i=mar` compile all imported modules from the mar package

This will cause the compiler to compile any modules from mar alongside your own application.

# Test

```
cd test
./go.d
```

# Versions

#### `-version=NoStdc`

Do not use the standard C library

#### `-version=NoExit`

Do not allow calls to `exit`. Reduces the number of ways the program can quit. Useful if program needs to clean up before exiting.
