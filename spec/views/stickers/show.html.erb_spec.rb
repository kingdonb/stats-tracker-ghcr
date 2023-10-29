require 'rails_helper'

RSpec.describe "stickers/show", type: :view do
  before(:each) do
    assign(:sticker, Sticker.create!(
      image_url: "Image Url"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Image Url/)
  end
end
