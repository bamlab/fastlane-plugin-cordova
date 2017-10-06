module Fastlane
  module Helper
    class IonicHelper
      # class methods that you define here become available in your action
      # as `Helper::IonicHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the ionic plugin helper!")
      end
    end
  end
end
