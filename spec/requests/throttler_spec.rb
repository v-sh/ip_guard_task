require 'rails_helper'

describe Throttler do
  it 'is called' do
    expect_any_instance_of(Throttler).to receive('call').and_call_original
    get '/'
  end
end
