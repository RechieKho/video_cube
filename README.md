# `Cube` project template

`Cube` is a C project with a project structure (`Cube` project structure) aim to be modular,
in which `Cube` project could easily embedded into other `Cube` projects with 0 configuration.

What it is:

- Building desktop application and static library on a unix-like environment.
- Targeting Windows, Linux and Mac OS.
- Include other `Cube` projects as thirdparties with 0 configuration.
- Focus on modularity.

## Prerequisite

Basic Unix-like environment with basic C tools installed.
These are the application required:

- `ar`
- `clang`
- `mkdir`
- `cp`
- `echo`
- `make`
- `cat`
- `rm`
- `git`
- `cd`

`Cube` projects must be a `git` repository.

> [!NOTE]
>
> Though Windows is not a Unix-like, there are tools like [Cygwin](https://www.cygwin.com) that
> set up a Unix-like environment.

## `Cube` project structure

| Directory       | Description                                                                                                                                                                                                           |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `build`         | Store distributable files of the project and its thirdparty `Cube` projects.                                                                                                                                          |
| `build/bin`     | Stores built binary of the project and its thirdparty `Cube` projects. The binary has version as suffix (`<BIN_NAME>.<VERSION>`).                                                                                     |
| `build/include` | Stores header files of the project and its thirdparty `Cube` projects. The header files is stored in their own directory with its project's name and version as the name (`build/include/<PROJECT_NAME>/<VERSION>/`). |
| `build/lib`     | Stores built binary with the file with the naming format as `lib<PROJECT_NAME>.<VERSION>.a`.                                                                                                                          |
| `cube`          | Stores all the thirdparty `Cube` projects. It is handled by the `Cube` Makefile.                                                                                                                                      |
| `gen`           | Stores the generated object files of the project.                                                                                                                                                                     |
| `include`       | Stores the header files to be distributed, it will be copied to the `build/include` directory.                                                                                                                        |
| `link`          | Stores `.link` text files record system library to be linked to for each platform.                                                                                                                                    |
| `source`        | Stores all the `.c` source files.                                                                                                                                                                                     |
| `source/bin`    | Stores source files that will be build into executables. Each source file compiles to an executable with the same name and output to `build/bin`. The executable is linked to library in `build/lib`.                 |
| `source/lib`    | Stores source files that will be build into a static library, output to `build/lib`.                                                                                                                                  |

> [!NOTE]
>
> Project name (`<PROJECT_NAME>`) is the name of the directory your project resided.
> Version (`<VERSION>`) is the `git` hash or tag (if available).

## The `Cube` Makefile

The `Cube` Makefile resides at the root of the project.
It should:

- Build in `release` or `debug` mode,
- Output the distributed files to the root `build` directory (more on [`Cube` project structure](#cube-project-structure)),
- Clean the build,
- Signal the thirdparty `Cube` projects.

### Build in `release` or `debug` mode

The `Cube` Makefile should have these phony targets:

- `release` - build in release mode. `DEBUG` macro is defined.
- `debug` - build in debug mode. `RELEASE` macro is defined.

The `Cube` Makefile should build the thirdparty `Cube` projects before building itself.

### Outputing distributed files

All the distributed files are stored in the root `build` directory as stated in the [`Cube` project structure](#cube-project-structure).

### Clean the build

The `Cube` Makefile should have a `clean` phony target that delete the files in its own `gen` directory.
The root `Cube` project should be the one to clean up the root `build` directory.

The `Cube` Makefile should clean the thirdparty `Cube` projects before cleaning itself.

### Signal the thirdparty `Cube` projects

The `Cube` Makefile should have these phony targets:

- `build-cube-release` - signaling to build all the thirdparty `Cube` projects in release mode (calling the `release` phony target).
- `build-cube-debug` - signaling to build all the thirdparty `Cube` projects in release debug (calling the `debug` phony target).
- `clean-cube` - signaling to clean all the thirdparty `Cube` projects (calling the `clean` phony target).

The root `Cube` project pass these Makefile variables to the thirdparty `Cube` projects:

- `ROOT_DIR` - Path of the root `Cube` project.
- `ROOT_BUILD_DIR` - Path of the root `build` directory.
- `ROOT_BUILD_BIN_DIR` - Path of the root `build/bin` directory.
- `ROOT_BUILD_INCLUDE_DIR` - Path of the root `build/include` directory.
- `ROOT_BUILD_LIB_DIR` - Path of the root `build/lib` directory.
- `ROOT_DEPENDENCIES_FILE` - Path of a text file records dependencies and its sequence.
- `ROOT_LINK_FILE` - Path of a text file records shared library to be linked to.

the thirdparty `Cube` projects output to the root `build` directory using the given variables.
The `Cube` Makefile should record the library's output path to `ROOT_DEPENDENCIES_FILE` once it is compiled in order to record the sequence of the dependencies.
Duplicates in `ROOT_DEPENDENCIES_FILE` is prohibited.

The `ROOT_DEPENDENCIES_FILE` is named `<PROJECT_NAME>.<VERSION>.DEPENDENCIES` and reside in `ROOT_BUILD_LIB_DIR`.
In the `ROOT_DEPENDENCIES_FILE`, The libraries depends on the libraries before itself.

The `ROOT_LINK_FILE` is named `<PROJECT_NAME>.<VERSION>.LINK` and reside in `ROOT_BUILD_LIB_DIR`.
In the `ROOT_LINK_FILE`, it stores the list of system shared library to be linked to.

## Versioning

The version of the library is the `git` hash or tag (if available) of the current commit.
It is incorporated into the distributed files' name (as stated in the [`Cube` project structure](#cube-project-structure)).
Unfortunately, the symbols of the library do not automatically incorporate the version.
Given this dependency tree:

```
parent
| - child_a
| | - child_b (version: v1_0_1)
| - child_b (version: v1_0_9)
```

Both `child_b v1_0_9` and `child_b v1_0_1` will output their own static library to the root `build` directory (the `parent`'s `build` directory).
Since they are essentially the same library but different version, it could contain the same functions with the same symbols.
This would lead to duplicate symbol linker error when linking both library together.

To fix this issue, the programmer should consider the version when naming the function.
A macro `VERSION` is also defined when compiling, the programmer could utilize this macro to differentiate function of different version.

```c
#define LITERAL_CONCAT(x, y) x ## y
#define CONCAT(x, y) LITERAL_CONCAT(x, y)
#define AFFIX_VERSION(identifier) CONCAT(identifier, VERSION)

int AFFIX_VERSION(foo)(int a, int b);
#define foo(a, b) (AFFIX_VERSION(foo)(a, b))

```

## Adding a `Cube` project as thirdparty library

Copy the `Cube` project to `cube` folder. Clean the project after adding, removing, modifying thirdparty libraries.

## Linking to a system library

Add the system library name to the `.link` text file under `link` directory according to the platform.

For an example, to link the `pthread` and `m` library for linux build, in `link/linux.link`:

```
pthread
m
```

Clean the project after adding, removing, modifying the `.link` text files.

## Cross-compiling

Cross-compiling isn't in the scope of the `Cube` Makefile, the programmer should install the appropriate tools and set the `Cube` Makefile variables for cross-compiling.
