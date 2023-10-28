require 'rails_helper'

RSpec.describe "stickers/index", type: :view do
  before(:each) do
    assign(:stickers, [
      Sticker.create!(
        image_url: "Image Url"
      ),
      Sticker.create!(
        image_url: "Image Url"
      )
    ])
  end

  it "renders a list of stickers" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new("Image Url".to_s), count: 2
  end
end
