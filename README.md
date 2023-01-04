# CycloneDDSPrebuild

Adapted from https://github.com/DimaRU/FastDDSPrebuild for use with CycloneDDS

Supported platforms: iOS(arm64), MacOS(arm64, x86_64), Simulator(arm64, x86_64)

### Usage

Add line to you package.swift dependencies:

```
.package(name: "FastDDS", url: "https://github.com/jc211/CycloneDDSPrebuild.git")
```

### Build your own repo from source

#### Requirements 
- Xcode 12.2
- [github cli](https://github.com/cli/cli). GitHub’s official command line tool.
- [xczip](https://github.com/DimaRU/xczip). Create xcframework zip archive for Swift binary package.

1. Install gh: `brew install gh`
2. Install xczip: `brew install DimaRU/formulae/xczip`
3. Authorize gh: `gh auth`
4. Fork and clone this repo
5. Run `./script/build.sh master commit`