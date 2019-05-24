FactoryBot.define do
  factory :my_app_user, class: 'MyApp::User' do
    sequence(:name) { |n| "name:#{n}" }
  end
end
