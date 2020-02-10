# frozen_string_literal: true

class ShortenerApi < Sinatra::Base
  before do
    content_type :json
  end

  get '/' do
    'Not Implemented'
  end

  get '/:shortcode' do
    halt 400 unless params['shortcode'].present?
    shortcode = params['shortcode']
    halt 404 unless $db[shortcode].present?
    # status 302
    # headers['Location'] = $db[shortcode]['url']
    $db[shortcode][:stats][:redirectCount] += 1
    $db[shortcode][:stats][:lastSeenDate] = Time.now.utc.iso8601
    redirect($db[shortcode][:url])
  end

  get '/:shortcode/stats' do
    halt 400 unless params['shortcode'].present?
    shortcode = params['shortcode']
    halt 404 unless $db[shortcode].present?

    $db[shortcode][:stats].to_json
  end

  post '/shorten' do
    halt 400 unless params['url'].present?
    url = params['url']

    if params['shortcode']
      shortcode = params['shortcode']

      if $db[shortcode]
        halt 409
      elsif !/^[0-9a-zA-Z_]{4,}$/.match?(shortcode)
        halt 422
      end
    else
      shortcode = generate_shortcode
      shortcode = generate_shortcode while $db[shortcode]
    end

    $db[shortcode] = { url: url, stats: {
      startDate: Time.now.utc.iso8601,
      redirectCount: 0

    } }
    status 201
    { shortcode: shortcode }.to_json
  end

  private

  def generate_shortcode
    chars = '0123456789abcdefghijklmnopqrstuvwyz_'.split('')
    code = ''
    10.times { code += chars.sample }
    code
  end
end
