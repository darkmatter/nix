# Nix Tooling

This directory contains all the nix modules that are used in this repo. We use [devenv](https://devenv.sh) which is a friendlier method to use Nix for non-Nix users, while still being powerful.

## Quick Start

**Run all the apps at once**

```bash
> devenv up
```

**Enter the full development environment**

```bash
# This will take a while to load the first time or after updates are made to it
> devenv shell --profile all
```

**View all details of the devenv**

```bash
> cd path/to/root
> devenv show
```

This will show you every aspect of the dev environments including scripts, tasks, environment variables, etc

## Profiles

There are several profiles which will provide different environments which are compatible with different apps. For example:

- **`devenv shell --profile proto`**: Includes python, go, and typescript with the versions needed by `buf`
- **`devenv shell --profile minimal`**: Loads a stripped down env that excludes large dependencies such as tensorstore, postgres, etc. Expect not all things to work with this profile
- **`devenv shell --profile ci`**: Used by Github Actions
- devenv shell --profile all\`: Enables everything at once, creates multiple venvs

## Running Tasks

```bash
# Run all the code generation plugins on the protocol buffers
> devenv tasks run proto:generate

# Run the apollo web server
> devenv processes up apollo-server

# Run one-off commands in the development environment
> devenv shell -- db-migrate
```

## Scripts v.s. Tasks v.s. Processes

There are 3 types of excutables that can be defined in devenv which can get quite confusing:

**scripts:**
Available as binary executables in the dev shell. The unique thing about scripts is that they can declare their own packages which means they are ideal for situations where you need flexibility on dependencies. For example, let's say we want to `apps/nn` using Metal on OSX - this requires an older version of jax since jax-ml is behind, which also means we need an older python. Here's how you can do that:

```nix

scripts.nn-osx = with pkgs.python310Packages; {
  description = "Run NN with support for Metal on OS X";
  exec = ''
    ${pkgs.uv}/bin/uv run \
      --python ${pkgs.python310}/bin/python \
      --with jax-ml jax
  '';
  packages = [pkgs.uv pkgs.python310 pkgs.python310Packages.jax-ml pkgs.python310Packages.jax];
};

```

You can even create scripts in any language:

```nix

scripts.go-util = {
  description = "Running some golang code";
  exec = ''
    print("Hello World")
  '';
  package = pkgs.python311;
};
```

**Tasks:**

Tasks are similar to steps in Github Actions, and differ from scripts in the following ways:

- Cannot declare arbitrary packages, but you can call scripts in tasks which means you can just combinefd them if neededl
- Can declare dependencies, e.g. `go build` must run before `go run .`
- Can receive inputs and pass outputs to other tasks
- You can configure the `status` attribute which will let you skip the task conditionally. This is used for example to skip `go mod tidy` in the case where you already have the correct dependenciees installed.

```nix
tasks."go:install"
tasks."go:build"
```

**Processes:**
