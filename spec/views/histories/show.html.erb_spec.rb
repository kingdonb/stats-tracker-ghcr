require 'rails_helper'

RSpec.describe "histories/show", type: :view do
  before(:each) do
    assign(:history, History.create!(
      sticker: nil
    ))
  end

  xit "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
  end
end
