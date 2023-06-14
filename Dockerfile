ARG BASE_IMAGE=ruby:3.1.4-bullseye
ARG CACHE_IMAGE=${BASE_IMAGE}

FROM ${CACHE_IMAGE} AS gem-cache
RUN mkdir -p /usr/local/bundle /root/.cargo

FROM $BASE_IMAGE AS base
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN gem install bundler:2.4.14 && gem install foreman
WORKDIR /usr/src/app
RUN mkdir -p /usr/src/app/lib
COPY lib/stat.wasm /usr/src/app/lib/stat.wasm

FROM base AS gems
COPY --from=gem-cache /usr/local/bundle /usr/local/bundle
COPY --from=gem-cache /root/.cargo /root/.cargo
COPY Gemfile Gemfile.lock ./
RUN bash -i -c 'bundle install'

FROM base AS deploy
COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY . /usr/src/app
RUN make -C lib test

CMD foreman start --no-timestamp
