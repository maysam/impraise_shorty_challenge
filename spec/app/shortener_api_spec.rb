# frozen_string_literal: true

require './spec/spec_helper'
require 'time'

def app
  ShortenerApi
end

RSpec.describe 'POST action' do
  let(:app) { ShortenerApi.new }

  it 'creates the shortcode as requested' do
    body = {
      "url": 'http://example.com',
      "shortcode": 'example'
    }

    post '/shorten', body

    expect(last_response.status).to eq(201)
    expect(JSON.parse(last_response.body)['shortcode']).to eq('example')
  end

  it 'returns 400 when url is missing' do
    body = {
      "shortcode": 'example'
    }

    post '/shorten', body

    expect(last_response.status).to eq(400)

    body = {
      "url": 'http://example.com'
    }

    post '/shorten', body

    expect(last_response.status).to eq(201)
  end

  it 'returns 409 when shortcode is already in use, shortcode is case-sensitive' do
    body = {
      "url": 'http://example.com',
      "shortcode": 'example'
    }

    post '/shorten', body

    expect(last_response.status).to eq(201)
    expect(JSON.parse(last_response.body)['shortcode']).to eq('example')

    post '/shorten', body

    expect(last_response.status).to eq(409)

    body = {
      "url": 'http://example.com',
      "shortcode": 'Example'
    }

    post '/shorten', body

    expect(last_response.status).to eq(201)
    expect(JSON.parse(last_response.body)['shortcode']).to eq('Example')
  end

  it 'returns 422 when shortcode doesnt match regexp ^[0-9a-zA-Z_]{4,}$' do
    body = {
      "url": 'http://example.com',
      "shortcode": 'exa'
    }

    post '/shorten', body

    expect(last_response.status).to eq(422)

    body = {
      "url": 'http://example.com',
      "shortcode": 'example*'
    }

    post '/shorten', body

    expect(last_response.status).to eq(422)
  end
end

RSpec.describe 'GET action' do
  let(:url) { 'http://example.com' }
  let(:shortcode) { 'example' }
  before do
    body = {
      "url": url,
      "shortcode": shortcode
    }

    post '/shorten', body
  end

  it 'return the url in location header for corresponding shortcode' do
    get "/#{shortcode}"

    expect(last_response.status).to eq(302)
    expect(last_response.headers['Location']).to eq(url)
  end

  it 'returns 404 if shortcode is not in the system' do
    get "/different#{shortcode}"

    expect(last_response.status).to eq(404)
  end
end

RSpec.describe 'GET stats action' do
  let(:url) { 'http://example.com' }
  let(:shortcode) { 'example' }

  it 'does something' do
    time = Time.now
    time_string = time.utc.iso8601
    allow(Time).to receive(:now).and_return(time)

    body = {
      "url": url,
      "shortcode": shortcode
    }

    post '/shorten', body

    get "/#{shortcode}/stats"

    expect(last_response.status).to eq(200)
    data = JSON.parse(last_response.body)
    expect(data['startDate']).to eq(time_string)
    expect(data['redirectCount']).to eq(0)
    expect(data['lastSeenDate']).to be_nil

    usage_time = Time.now
    usage_time_string = usage_time.utc.iso8601
    allow(Time).to receive(:now).and_return(usage_time)

    get "/#{shortcode}"
    get "/#{shortcode}"
    get "/#{shortcode}"
    get "/#{shortcode}/stats"

    expect(last_response.status).to eq(200)
    data = JSON.parse(last_response.body)
    expect(data['startDate']).to eq(time_string)
    expect(data['redirectCount']).to eq(3)
    expect(data['lastSeenDate']).to eq(usage_time_string)
  end

  it 'returns 404 if shortcode is not in the system' do
    # empty database
    get "/#{shortcode}/stats"
    expect(last_response.status).to eq(404)

    body = {
      "url": url,
      "shortcode": shortcode
    }

    post '/shorten', body

    get "/#{shortcode}/stats"
    expect(last_response.status).to eq(200)

    get "/another#{shortcode}/stats"
    expect(last_response.status).to eq(404)
  end
end
