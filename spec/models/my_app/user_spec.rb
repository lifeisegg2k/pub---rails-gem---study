require 'rails_helper'

module MyApp
  RSpec.describe User, type: :model do
    let(:user) { build(:my_app_user) }

    describe '#name' do
      subject { user.name }

      context 'is_expected' do
        it { is_expected.to match(/^name:\d+/) }
      end
    end
  end
end