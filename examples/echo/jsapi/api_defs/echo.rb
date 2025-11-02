# frozen_string_literal: true

info title: 'Echo', version: '1'

rescue_from Jsapi::Controller::ParametersInvalid, with: 400

operation path: '/echo' do
  parameter 'call', type: 'string', existence: true
  response 200, type: 'object' do
    property 'echo', type: 'string'
  end
  response 400, type: 'object' do
    property 'status', type: 'integer'
    property 'message', type: 'string'
  end
end
