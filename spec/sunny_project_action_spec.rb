describe Fastlane::Actions::LocalPackagesAction do
  describe '#run' do
    it 'prints a message' do
      Fastlane::Actions::LocalPackagesAction.run(nil)
      curr=Semantic::Version.new("3.4.2-nullsafety.0")
      curr=curr.increment!("build")
      puts curr
    end
  end
end
