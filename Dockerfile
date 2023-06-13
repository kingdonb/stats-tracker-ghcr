FROM ruby:3.1.4-bullseye AS base
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN mkdir -p /app/lib
RUN gem install foreman
COPY lib/stat.wasm /app/lib/stat.wasm

FROM kingdonb/opernator:base AS gems
COPY Gemfile Gemfile.lock /app
WORKDIR /app
RUN bash -i -c 'bundle install'

FROM kingdonb/opernator:gems AS app
ADD . /app
RUN make -C lib test

CMD foreman start --no-timestamp
