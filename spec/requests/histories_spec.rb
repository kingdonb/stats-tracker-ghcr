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

RSpec.describe "/histories", type: :request do
  
  # This should return the minimal set of attributes required to create a valid
  # History. As you add validations to History, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  describe "GET /index" do
    it "renders a successful response" do
      History.create! valid_attributes
      get histories_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      history = History.create! valid_attributes
      get history_url(history)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    # authenticated
    xit "renders a successful response" do
      get new_history_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      history = History.create! valid_attributes
      get edit_history_url(history)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new History" do
        expect {
          post histories_url, params: { history: valid_attributes }
        }.to change(History, :count).by(1)
      end

      it "redirects to the created history" do
        post histories_url, params: { history: valid_attributes }
        expect(response).to redirect_to(history_url(History.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new History" do
        expect {
          post histories_url, params: { history: invalid_attributes }
        }.to change(History, :count).by(0)
      end

    
      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post histories_url, params: { history: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested history" do
        history = History.create! valid_attributes
        patch history_url(history), params: { history: new_attributes }
        history.reload
        skip("Add assertions for updated state")
      end

      it "redirects to the history" do
        history = History.create! valid_attributes
        patch history_url(history), params: { history: new_attributes }
        history.reload
        expect(response).to redirect_to(history_url(history))
      end
    end

    context "with invalid parameters" do
    
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        history = History.create! valid_attributes
        patch history_url(history), params: { history: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested history" do
      history = History.create! valid_attributes
      expect {
        delete history_url(history)
      }.to change(History, :count).by(-1)
    end

    it "redirects to the histories list" do
      history = History.create! valid_attributes
      delete history_url(history)
      expect(response).to redirect_to(histories_url)
    end
  end
end
