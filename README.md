# Cordova Plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-cordova)

## Features

- Build your Cordova project inside a lane
- Automatically handle code signing on iOS, even for XCode 8

## Getting Started

This project is a [fastlane](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-cordova`, add it to your project by running:

```bash
fastlane add_plugin cordova
```

Then you can integrate it into your Fastlane setup:

```ruby
platform :ios do
  desc "Deploy ios app on the appstore"

  lane :deploy do
    match(type: "appstore")
    cordova(platform: 'ios')
    appstore(ipa: ENV['CORDOVA_IOS_RELEASE_BUILD_PATH'])
  end
end

platform :android do
  desc "Deploy android app on play store"

  lane :deploy do
    cordova(
      platform: 'android',
      keystore_path: './prod.keystore',
      keystore_alias: 'prod',
      keystore_password: 'password'
    )
    supply(apk: ENV['CORDOVA_ANDROID_RELEASE_BUILD_PATH'])
  end
end
```

with an `Appfile` such as

```ruby
app_identifier "com.awesome.app"
apple_id "apple@id.com"
team_id "28323HT"
```

## Plugin API

To check what's available in the plugin, install it in a project and run at the root of the project:
```
fastlane actions cordova
```

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://github.com/fastlane/fastlane/blob/master/fastlane/docs/PluginsTroubleshooting.md) doc in the main `fastlane` repo.

## Using `fastlane` Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://github.com/fastlane/fastlane/blob/master/fastlane/docs/Plugins.md).

## About `fastlane`

`fastlane` is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
