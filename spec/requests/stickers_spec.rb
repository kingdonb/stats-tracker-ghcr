require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to test the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator. If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails. There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.

RSpec.describe "/stickers", type: :request do
  
  # This should return the minimal set of attributes required to create a valid
  # Sticker. As you add validations to Sticker, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  describe "GET /index" do
    it "renders a successful response" do
      Sticker.create! valid_attributes
      get stickers_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      sticker = Sticker.create! valid_attributes
      get sticker_url(sticker)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    # authenticated
    xit "renders a successful response" do
      get new_sticker_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      sticker = Sticker.create! valid_attributes
      get edit_sticker_url(sticker)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new Sticker" do
        expect {
          post stickers_url, params: { sticker: valid_attributes }
        }.to change(Sticker, :count).by(1)
      end

      it "redirects to the created sticker" do
        post stickers_url, params: { sticker: valid_attributes }
        expect(response).to redirect_to(sticker_url(Sticker.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new Sticker" do
        expect {
          post stickers_url, params: { sticker: invalid_attributes }
        }.to change(Sticker, :count).by(0)
      end

    
      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post stickers_url, params: { sticker: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested sticker" do
        sticker = Sticker.create! valid_attributes
        patch sticker_url(sticker), params: { sticker: new_attributes }
        sticker.reload
        skip("Add assertions for updated state")
      end

      it "redirects to the sticker" do
        sticker = Sticker.create! valid_attributes
        patch sticker_url(sticker), params: { sticker: new_attributes }
        sticker.reload
        expect(response).to redirect_to(sticker_url(sticker))
      end
    end

    context "with invalid parameters" do
    
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        sticker = Sticker.create! valid_attributes
        patch sticker_url(sticker), params: { sticker: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested sticker" do
      sticker = Sticker.create! valid_attributes
      expect {
        delete sticker_url(sticker)
      }.to change(Sticker, :count).by(-1)
    end

    it "redirects to the stickers list" do
      sticker = Sticker.create! valid_attributes
      delete sticker_url(sticker)
      expect(response).to redirect_to(stickers_url)
    end
  end
end
