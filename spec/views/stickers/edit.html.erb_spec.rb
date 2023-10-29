require 'rails_helper'

RSpec.describe "stickers/edit", type: :view do
  let(:sticker) {
    Sticker.create!(
      image_url: "MyString"
    )
  }

  before(:each) do
    assign(:sticker, sticker)
  end

  it "renders the edit sticker form" do
    render

    assert_select "form[action=?][method=?]", sticker_path(sticker), "post" do

      assert_select "input[name=?]", "sticker[image_url]"
    end
  end
end
