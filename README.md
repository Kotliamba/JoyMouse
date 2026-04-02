# JoyMouse
Nintendo Joy-Con / Pro Controller Mapper for Apple Silicon (also works on Intel-based macOS Big Sur). It maps gamepad buttons to keyboard and mouse events smoothly and works for games and platforms that do not natively support gamepad input on macOS.

## Demo on YouTube

[Apple Silicon Mac | CrossOver | Playing Witcher 3 with GAMEPAD (Nintendo Joy-Con / Pro Controller)
](https://youtu.be/1jpcuREivmk)

## Advantages v.s. alternatives

|                                                          | Big Sur | Apple silicon native | Mouse working in games | 360° mouse move & acceleration (smooth view angle rotation) | Joystick orientation at 45°s (smooth character moving) | Both Joy Cons as a pair |
| :------------------------------------------------------: | :-----: | :------------------: | :--------------------: | :---------------------------------------------------------: | :----------------------------------------------------: | :---------------------: |
|     [Enjoyable](https://yukkurigames.com/enjoyable/)     |    ✅    |          ❌           |           ✅            |                              ❌                              |                           ✅                            |            ❌            |
|       [Enjoy2](https://github.com/fyhuang/enjoy2/)       |    ❌    |          ❌           |           -            |                              -                              |                           -                            |            -            |
| [JoyKeyMapper](https://github.com/magicien/JoyKeyMapper) |    ✅    |          ❌           |           ❌            |                              ✅                              |                           ❌                            |            ✅            |
|                      JoyMouse (this app)                     |    ✅    |          ✅           |           ✅            |                              ✅                              |                           ✅                            |            ✅            |

## Installation

1. Download the latest `JoyMouse.app` release artifact.

2. Copy `JoyMouse.app` to `/Applications`.

## Usage

![screenshot](https://github.com/qibinc/JoyMapperSilicon/blob/master/resources/screenshot/screenshot_1.png)

See [magicien's How to Use](https://github.com/magicien/JoyKeyMapper#how-to-use).

## Release DMG

Build a signed Release app first, then package it:

```bash
git tag v1.0.0
export NOTARYTOOL_PROFILE="joymouse-notary"
./scripts/build_dmg.sh /path/to/JoyMouse.app
```

Release prerequisites:
- `dmgbuild` installed and available on `PATH`
- Developer ID signing configured in Xcode
- notarization credentials stored with `xcrun notarytool store-credentials` or provided via `APP_API_KEY_PATH`, `APP_API_KEY_ID`, and `APP_API_ISSUER`
- a Git tag in `v*.*.*` format so `scripts/set_build_number.sh` can derive the version

## Acknowledgement

This application is heavily based on [magicien/JoyKeyMapper](https://github.com/magicien/JoyKeyMapper). We thank them a lot for open-sourcing the [JoyKeyMapper](https://apps.apple.com/us/app/joykeymapper/id1511416593?mt=12) app. Please also support them if possible.
