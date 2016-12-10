module Fastlane
  module Helper
    class CordovaHelper
      # class methods that you define here become available in your action
      # as `Helper::CordovaHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the cordova plugin helper!")
      end
    end
  end
end
