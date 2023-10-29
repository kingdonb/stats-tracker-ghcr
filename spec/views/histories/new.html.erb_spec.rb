require 'rails_helper'

RSpec.describe "histories/new", type: :view do
  before(:each) do
    assign(:history, History.new(
      sticker: nil
    ))
  end

  xit "renders new history form" do
    render

    assert_select "form[action=?][method=?]", histories_path, "post" do

      assert_select "input[name=?]", "history[sticker_id]"
    end
  end
end
