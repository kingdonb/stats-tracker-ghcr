FactoryBot.define do
  factory :version do
    package { nil }
    version { "MyString" }
    download_count { 1 }
  end
end
