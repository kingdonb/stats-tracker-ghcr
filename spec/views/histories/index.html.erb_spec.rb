require 'rails_helper'

RSpec.describe "histories/index", type: :view do
  before(:each) do
    assign(:histories, [
      History.create!(
        sticker: nil
      ),
      History.create!(
        sticker: nil
      )
    ])
  end

  xit "renders a list of histories" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
