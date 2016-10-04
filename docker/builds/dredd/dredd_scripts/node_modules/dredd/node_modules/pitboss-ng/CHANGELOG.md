# 0.3.2

- added direct support for memory management at win32/win64 platforms
- using [appVeyor](https://ci.appveyor.com/project/Apiary/pitboss) to test at Windows
- using [gulp](https://www.npmjs.org/package/gulp) for development and tasks, works cross-platform

# 0.3.1

- added npm-debug.log and *.log into gitignore/npmignore
- fixed typo in example code around `options.heartBeatTick`

# 0.3.0

- use [pidusage](https://www.npmjs.org/package/pidusage) to monitor memory footprint (supports *nix, Darwin, Win platform)
- introduce `pitboss.kill()` to be run after `pitboss.run` to cleanly kill sandboxed fork
- updated [README](README.md) with examples how to pass libraries into sandboxed code

# 0.2.1

- little changes to package.json regarding repository entry

# 0.2.0

- package renamed to `pitboss-ng`
- __works with NodeJS 0.10, 0.12, iojs__
- dropped support NodeJS 0.8
- devDependencies bumped
- using `clone` to really avoid any context sharing between fork and parent process
- `coffee-script` is no more production dependency, package is compiled before being published to NPM registry

# 0.1.5 (not released to NPM, only available at GitHub)

- use `coffee-script` from 1.6.3 to 1.8.0, updated postinstall task accordingly

# 0.1.4 (not released to NPM, only available at GitHub)

- guessing command to get sub-process information from `os.platform` = works on *nix/Darwin platforms now (still no Win support)

# 0.1.3 (not released to NPM, only available at GitHub)

- using `coffee-script` as dependency to compile `src/*.coffee` in NPM `postinstall` task

# 0.1.2 (not released to NPM, only available at GitHub)

- added option to pass `libraries` (required modules) to context of used VM (thus alowing to use various core/user-land modules)
- added `options.memoryLimit` (kBytes) to Pitboss, using child_process with `ps` (no Win/Darwin support)
