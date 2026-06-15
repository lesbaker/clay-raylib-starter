# Clay GUI w/ Raylib Starter Template

This project gets someone going that wants to use Nic Barker's [Clay](https://github.com/nicbarker/clay) ("C-Layout") GUI library with [Raylib](https://github.com/raysan5/raylib) as the rendering backend.

## Motivation

Clay comes with three examples that integrate with Raylib, but they seem to be detailed demonstrations of all the functionality of Clay rather than starting points. It also has a "cpp-project-example" project that is super bare bones without the Raylib integration. It's my hope this project fills the gap: a Clay/Raylib project that runs right away with a clear place to put one's code.

## How to Use

This project uses the Zig Build System, part of the [Zig language](https://ziglang.org), for building the project code and executing the included utility steps.

### So what's this Zig thing doing in a C language project?

Anyone remember how IBM advertised OS/2 as a "better Windows than Windows"? Zig is trying to be a "better C than C", and they seem to be getting there. The huge advantage Zig has is that its compiler embeds the Clang compiler and an implementation of libc. At least on paper, it's a self-contained environment that can build C projects out-of-the-box with a minimum of configuration. And I think that it makes more sense to implement build logic in a *bona-fide* programming language rather than a tool-specific syntax (especially CMake). The point: **using Zig's build system doesn't obligate the developer (you) to use Zig in application code**.

### Preparation

Install the latest stable version of Zig by using your operating system's package manager or heading to the [Zig download page](https://ziglang.org/download).

### Building Everything

Type the following to perform the default build step, which copies the Clay & Raylib headers and builds the Raylib static library and the starter executable (All examples perfomed using Arch Linux):

```bash
❯ zig build
```

You should find the following files in the "zig-out" subdirectory:

```bash
❯ tree zig-out
zig-out
├── bin
│   └── starter
├── include
│   ├── clay.h
│   ├── raylib.h
│   ├── raymath.h
│   ├── rcamera.h
│   └── rlgl.h
└── lib
    └── libraylib.a
```

### Copying the headers (only)

The build process pulls the headers down from the respective Github repositories and places them into a private (Zig) cache to build the executable, so it's not necessary to have them locally installed. But when you start to implement your program, you may want the headers available in your project for reference and to enable function and type assistance in your IDE. Execute the following to copy the headers into the project root:

```bash
❯ zig build copy-headers --prefix ./
```

The prefix flag (which can be abbreviated "-p") specifies the root path of where to write the headers, which are placed into the "include" subdirectory. The Zig build system requires the user to supply that flag to write to any place besides the default "zig-out" subdirectory.

### Generating a .clangd file

Even when one copies the Clay/Raylib headers to the project, one can encounter spurious errors in IDEs and text editors such as VSCode, Vim, and Helix. This is because such editors use (or can be configured to use) the Clangd language server to perform error checking. If Clangd can't find the headers in global include directories or the same directory as the source code, it flags those functions as errors. Thankfully, one can put a configuration file in the root of the project to point Clangd to the include directory, and the build file has a step to generate this file. Simply execute the following in the project root:

```bash
❯ zig build create-clangd-dotfile --prefix ./
```

> [!WARNING]
> 
> Any existing .clangd file in the project root will be overwritten

## Future improvements

- Document build file

- Test on Windows
