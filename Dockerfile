FROM ruby:3.1.4-bullseye AS base
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN mkdir -p /app/lib
COPY lib/stat.wasm /app/lib/stat.wasm

FROM kingdonb/opernator:base AS app
ADD . /app
WORKDIR /app
# RUN bundle install
# RUN make -C lib test
