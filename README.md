<div align="center">
  <img src="docs/logo.svg" width="88" alt="">
  <h1>Brighter</h1>
  <p>Unlock the extra brightness of your Mac's XDR display, right from the menu bar.</p>
  <span>
    <a href="#install">Install</a>
    <span>&nbsp;&nbsp;·&nbsp;&nbsp;</span>
    <a href="#usage">Usage</a>
    <span>&nbsp;&nbsp;·&nbsp;&nbsp;</span>
    <a href="#contribute">Contribute</a>
  </span>
</div>
<hr>

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/ridafkih/brighter/main/install.sh | sh
```

Downloads the latest release into `/Applications` and opens it. Requires macOS 15 or later and a Liquid Retina XDR or Pro Display XDR.

## Usage

Click the sun in the menu bar and flip Brighter on. The brightness slider then runs past 100%, up to 160%. Grant Accessibility access and the brightness keys go past 100% too.

## Contribute

Pull requests and issues are welcome. Building needs Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
git clone https://github.com/ridafkih/brighter.git
cd brighter
make run
```

`make test` runs the tests, `make install` builds a release copy into `/Applications`, and `make release` publishes one.
