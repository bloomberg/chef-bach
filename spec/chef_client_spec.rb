require_relative '../lib/chef_client'

describe ChefBach::ChefClient do
  # FIXME This needs more tests
  subject do
    ChefBach::ChefClient.new nil, {hostname: 'somehost'}
  end

  describe '#kill' do
    it 'confirms the chef client is down' do
      # TODO move to before when adding newer tests
      fakeshell = double('fake shellout').as_null_object
      allow(Mixlib::ShellOut).to receive(:new).and_return(fakeshell)

      expect(subject).to receive(:confirm_down)

      subject.kill
    end
  end
end
