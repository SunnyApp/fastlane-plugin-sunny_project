describe Fastlane::Actions::SunnyProjectAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The sunny_project plugin is working!")

      Fastlane::Actions::SunnyProjectAction.run(nil)
    end
  end
end
