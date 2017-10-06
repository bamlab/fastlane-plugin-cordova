module Fastlane
  module Actions
    module SharedValues
      CORDOVA_IOS_RELEASE_BUILD_PATH = :CORDOVA_IOS_RELEASE_BUILD_PATH
      CORDOVA_ANDROID_RELEASE_BUILD_PATH = :CORDOVA_ANDROID_RELEASE_BUILD_PATH
    end

    class CordovaAction < Action
      ANDROID_ARGS_MAP = {
        keystore_path: 'keystore',
        keystore_password: 'storePassword',
        key_password: 'password',
        keystore_alias: 'alias',
        build_number: 'versionCode'
      }

      IOS_ARGS_MAP = {
        type: 'packageType',
        team_id: 'developmentTeam',
        provisioning_profile: 'provisioningProfile',
      }

      def self.get_platform_args(params, args_map)
        platform_args = []
        args_map.each do |action_key, cli_param|
          param_value = params[action_key]
          unless param_value.to_s.empty?
            platform_args << "--#{cli_param}=#{Shellwords.escape(param_value)}"
          end
        end

        return platform_args.join(' ')
      end

      def self.get_android_args(params)
        if params[:key_password].empty?
          params[:key_password] = params[:keystore_password]
        end

        return self.get_platform_args(params, ANDROID_ARGS_MAP)
      end

      def self.get_ios_args(params)
        app_identifier = CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)

        if params[:provisioning_profile].empty?
          params[:provisioning_profile] = ENV['SIGH_UUID'] || ENV["sigh_#{app_identifier}_#{params[:type].sub("-","")}"]
        end

        if params[:type] == 'adhoc'
          params[:type] = 'ad-hoc'
        end
        if params[:type] == 'appstore'
          params[:type] = 'app-store'
        end

        return self.get_platform_args(params, IOS_ARGS_MAP)
      end

      def self.check_platform(platform)
        if platform && !File.directory?("./platforms/#{platform}")
          sh "cordova platform add #{platform}"
        end
      end

      def self.get_app_name()
        config = REXML::Document.new(File.open('config.xml'))
        return config.elements['widget'].elements['name'].first.value
      end

      def self.build(params)
        args = [params[:release] ? '--release' : '--debug']
        args << '--device' if params[:device]
        args << '--browserify' if params[:browserify]
        android_args = self.get_android_args(params) if params[:platform].to_s == 'android'
        ios_args = self.get_ios_args(params) if params[:platform].to_s == 'ios'

        if params[:cordova_prepare]
          sh "cordova prepare #{params[:platform]} #{args.join(' ')} #{ios_args} -- #{android_args}"
        end

        if params[:platform].to_s == 'ios' && !params[:build_number].to_s.empty?
          cf_bundle_version = params[:build_number].to_s
          Actions::UpdateInfoPlistAction.run(
            xcodeproj: "./platforms/ios/#{self.get_app_name}.xcodeproj",
            plist_path: "#{self.get_app_name}/#{self.get_app_name}-Info.plist",
            block: lambda { |plist|
              plist['CFBundleVersion'] = cf_bundle_version
            }
          )
        end

        sh "cordova compile #{params[:platform]} #{args.join(' ')} #{ios_args} -- #{android_args}"
      end

      def self.set_build_paths(is_release)
        app_name = self.get_app_name()
        build_type = is_release ? 'release' : 'debug'

        ENV['CORDOVA_ANDROID_RELEASE_BUILD_PATH'] = "./platforms/android/build/outputs/apk/android-#{build_type}.apk"
        ENV['CORDOVA_IOS_RELEASE_BUILD_PATH'] = "./platforms/ios/build/device/#{app_name}.ipa"
      end

      def self.run(params)
        self.check_platform(params[:platform])
        self.build(params)
        self.set_build_paths(params[:release])
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Build your Cordova app"
      end

      def self.details
        "Easily integrate your cordova build into a Fastlane setup"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :platform,
            env_name: "CORDOVA_PLATFORM",
            description: "Platform to build on. Should be either android or ios",
            is_string: true,
            default_value: '',
            verify_block: proc do |value|
              UI.user_error!("Platform should be either android or ios") unless ['', 'android', 'ios'].include? value
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :release,
            env_name: "CORDOVA_RELEASE",
            description: "Build for release if true, or for debug if false",
            is_string: false,
            default_value: true,
            verify_block: proc do |value|
              UI.user_error!("Release should be boolean") unless [false, true].include? value
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :device,
            env_name: "CORDOVA_DEVICE",
            description: "Build for device",
            is_string: false,
            default_value: true,
            verify_block: proc do |value|
              UI.user_error!("Device should be boolean") unless [false, true].include? value
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :type,
            env_name: "CORDOVA_IOS_PACKAGE_TYPE",
            description: "This will determine what type of build is generated by Xcode. Valid options are development, enterprise, adhoc, and appstore",
            is_string: true,
            default_value: 'appstore',
            verify_block: proc do |value|
              UI.user_error!("Valid options are development, enterprise, adhoc, and appstore.") unless ['development', 'enterprise', 'adhoc', 'appstore', 'ad-hoc', 'app-store'].include? value
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :team_id,
            env_name: "CORDOVA_IOS_TEAM_ID",
            description: "The development team (Team ID) to use for code signing",
            is_string: true,
            default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_id)
          ),
          FastlaneCore::ConfigItem.new(
            key: :provisioning_profile,
            env_name: "CORDOVA_IOS_PROVISIONING_PROFILE",
            description: "GUID of the provisioning profile to be used for signing",
            is_string: true,
            default_value: ''
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_path,
            env_name: "CORDOVA_ANDROID_KEYSTORE_PATH",
            description: "Path to the Keystore for Android",
            is_string: true,
            default_value: ''
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_password,
            env_name: "CORDOVA_ANDROID_KEYSTORE_PASSWORD",
            description: "Android Keystore password",
            is_string: true,
            default_value: ''
          ),
          FastlaneCore::ConfigItem.new(
            key: :key_password,
            env_name: "CORDOVA_ANDROID_KEY_PASSWORD",
            description: "Android Key password (default is keystore password)",
            is_string: true,
            default_value: ''
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_alias,
            env_name: "CORDOVA_ANDROID_KEYSTORE_ALIAS",
            description: "Android Keystore alias",
            is_string: true,
            default_value: ''
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_number,
            env_name: "CORDOVA_BUILD_NUMBER",
            description: "Build Number for iOS and Android Keystore alias",
            optional: true,
            is_string: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :browserify,
            env_name: "CORDOVA_BROWSERIFY",
            description: "Specifies whether to browserify build or not",
            default_value: false,
            is_string: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :cordova_prepare,
            env_name: "CORDOVA_PREPARE",
            description: "Specifies whether to run `cordova prepare` before building",
            default_value: true,
            is_string: false
          )
        ]
      end

      def self.output
        [
          ['CORDOVA_ANDROID_RELEASE_BUILD_PATH', 'Path to the signed release APK if it was generated'],
          ['CORDOVA_IOS_RELEASE_BUILD_PATH', 'Path to the signed release IPA if it was generated']
        ]
      end

      def self.authors
        ['almouro']
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          "cordova(
            platform: 'ios'
          )",
          "cordova(
            platform: 'android',
            keystore_path: './staging.keystore',
            keystore_alias: 'alias_name',
            keystore_password: 'store_password'
          )"
        ]
      end

      def self.category
        :building
      end
    end
  end
end
