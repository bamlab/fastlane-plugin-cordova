describe Fastlane::Actions::CordovaAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The cordova plugin is working!")

      Fastlane::Actions::CordovaAction.run(nil)
    end
  end
end
