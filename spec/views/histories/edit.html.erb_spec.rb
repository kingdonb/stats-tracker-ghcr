require 'rails_helper'

RSpec.describe "histories/edit", type: :view do
  let(:history) {
    History.create!(
      sticker: nil
    )
  }

  before(:each) do
    assign(:history, history)
  end

  xit "renders the edit history form" do
    render

    assert_select "form[action=?][method=?]", history_path(history), "post" do

      assert_select "input[name=?]", "history[sticker_id]"
    end
  end
end
