FROM ruby:2.2.0
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev
RUN gem install bundler
RUN mkdir /stretchy
WORKDIR /stretchy
ADD . /stretchy
RUN bundle install

