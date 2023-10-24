require 'rails_helper'

RSpec.describe "landings/index", type: :view do
  before(:each) do
    assign(:landings, [
      Landing.create!(
        email: "Email",
        twitter: "Twitter",
        fediverse: "Fediverse",
        accept_coc: false,
        printed_stickers_already: false
      ),
      Landing.create!(
        email: "Email",
        twitter: "Twitter",
        fediverse: "Fediverse",
        accept_coc: false,
        printed_stickers_already: false
      )
    ])
  end

  it "renders a list of landings" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new("Email".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Twitter".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Fediverse".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
  end
end
