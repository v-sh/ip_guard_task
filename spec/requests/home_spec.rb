require 'rails_helper'

describe "home controller" do
  it 'renders ok' do
    get '/'
    expect(response).to be_successful
    expect(response.body).to eq("ok")
  end
end
