FactoryBot.define do
  factory :landing do
    email { "MyString" }
    twitter { "MyString" }
    fediverse { "MyString" }
    accept_coc { false }
    printed_stickers_already { false }
  end
end
