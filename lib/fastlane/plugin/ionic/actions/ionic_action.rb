module Fastlane
  module Actions
    module SharedValues
      CORDOVA_IOS_RELEASE_BUILD_PATH = :CORDOVA_IOS_RELEASE_BUILD_PATH
      CORDOVA_ANDROID_RELEASE_BUILD_PATH = :CORDOVA_ANDROID_RELEASE_BUILD_PATH
    end

    class IonicAction < Action
      # valid action params

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
        provisioning_profile: 'provisioningProfile'
      }

      # do rewriting and copying of action params
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

      # map action params to the cli param they will be used for

      def self.get_android_args(params)
        # TODO document magic in README
        if params[:key_password].empty?
          params[:key_password] = params[:keystore_password]
        end

        return self.get_platform_args(params, ANDROID_ARGS_MAP)
      end

      def self.get_ios_args(params)
        app_identifier = CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)

        if params[:provisioning_profile].empty?
          # If `match` or `sigh` were used before this, use the certificates returned from there
          params[:provisioning_profile] = ENV['SIGH_UUID'] || ENV["sigh_#{app_identifier}_#{params[:type].sub('-', '')}"]
        end

        if params[:type] == 'adhoc'
          params[:type] = 'ad-hoc'
        end
        if params[:type] == 'appstore'
          params[:type] = 'app-store'
        end

        return self.get_platform_args(params, IOS_ARGS_MAP)
      end

      # add cordova platform if missing (run #1)
      def self.check_and_add_platform(platform)
        if platform && !File.directory?("./platforms/#{platform}")
          sh "ionic cordova platform add #{platform}"
        end
      end

      # app_name
      def self.get_app_name
        config = REXML::Document.new(File.open('config.xml'))
        return config.elements['widget'].elements['name'].first.value # TODO: Simplify!? (Check logic in cordova)
      end

      # actual building! (run #2)
      def self.build(params)
        args = [params[:release] ? '--release' : '--debug']
        args << '--device' if params[:device]
        args << '--prod' if params[:prod]
        args << '--browserify' if params[:browserify]
        android_args = self.get_android_args(params) if params[:platform].to_s == 'android'
        ios_args = self.get_ios_args(params) if params[:platform].to_s == 'ios'

        if params[:cordova_prepare]
          # TODO: Remove params not allowed/used for `prepare`
          sh "ionic cordova prepare #{params[:platform]} #{args.join(' ')}"
        end

        # special handling for `build_number` param
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

        if params[:platform].to_s == 'ios'
          sh "ionic cordova compile #{params[:platform]} #{args.join(' ')} -- #{ios_args}" 
        elsif params[:platform].to_s == 'android'
          sh "ionic cordova compile #{params[:platform]} #{args.join(' ')} -- -- #{android_args}" 
        end
      end

      # export build paths (run #3)
      def self.set_build_paths(is_release)
        app_name = self.get_app_name
        build_type = is_release ? 'release' : 'debug'

        ENV['CORDOVA_ANDROID_RELEASE_BUILD_PATH'] = "./platforms/android/build/outputs/apk/android-#{build_type}.apk"
        ENV['CORDOVA_IOS_RELEASE_BUILD_PATH'] = "./platforms/ios/build/device/#{app_name}.ipa"

        # TODO: https://github.com/bamlab/fastlane-plugin-cordova/issues/7
      end

      def self.run(params)
        self.check_and_add_platform(params[:platform])
        self.build(params)
        self.set_build_paths(params[:release])
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Build your Ionic app"
      end

      def self.details
        "Easily integrate your Ionic build into a Fastlane setup"
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
            key: :prod,
            env_name: "IONIC_PROD",
            description: "Build for production",
            is_string: false,
            default_value: false,
            verify_block: proc do |value|
              UI.user_error!("Prod should be boolean") unless [false, true].include? value
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
            description: "Sets the build number for iOS and version code for Android",
            optional: true,
            is_string: false
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
            description: "Specifies whether to run `ionic cordova prepare` before building",
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
        ['Jan Piotrowski']
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          "ionic(
            platform: 'ios'
          )",
          "ionic(
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
