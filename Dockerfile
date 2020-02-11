FROM ruby:2.6.3

WORKDIR /app

RUN gem install bundler

COPY . /app

RUN bundle install

ENTRYPOINT [ "bundle", "exec", "rackup", "config.ru", "-o", "0.0.0.0", "--port", "3000"]
EXPOSE 3000
