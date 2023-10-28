require 'rails_helper'

RSpec.describe "landings/edit", type: :view do
  let(:landing) {
    Landing.create!(
      email: "MyString",
      twitter: "MyString",
      fediverse: "MyString",
      accept_coc: false,
      printed_stickers_already: false
    )
  }

  before(:each) do
    assign(:landing, landing)
  end

  it "renders the edit landing form" do
    render

    assert_select "form[action=?][method=?]", landing_path(landing), "post" do

      assert_select "input[name=?]", "landing[email]"

      assert_select "input[name=?]", "landing[twitter]"

      assert_select "input[name=?]", "landing[fediverse]"

      assert_select "input[name=?]", "landing[accept_coc]"

      assert_select "input[name=?]", "landing[printed_stickers_already]"
    end
  end
end
