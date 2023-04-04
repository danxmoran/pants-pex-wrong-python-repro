Reproduction of https://github.com/pantsbuild/pants/issues/18662

First, build the container:
```
docker built -t repro-env .
```

Then jump into the container:
```
docker run --rm -it -v $(pwd):/repro -w /repro repro-env
```

Within the container, run:
```
pants package :aldy
```

The command will fail. In the output you will see unexpected references to `cpython-39`.

Things work as expected if you either:
1. Comment out the `:ssw` dependency on the `lib` target
2. Comment out the override of `[pex-cli].version` in `pants.toml`
3. Downgrade `[GLOBAL].pants_version` to `2.16.0a1` in `pants.toml`

In all cases the `package` command still fails, but the error output mentions `cpython-38` instead of `cpython-39`.
