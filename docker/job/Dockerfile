FROM ruby:3.1.1

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

WORKDIR /myapp/rdv-solidarites.fr

ENV NODE_VERSION=16.13.0
ENV BUNDLE_PATH=vendor/bundle
ENV BUNDLE_BIN=vendor/bundle/bin
ENV BUNDLE_DEPLOYMENT=1

RUN apt-get install -y curl
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

RUN npm version && npm install --global yarn

COPY . .

RUN gem install bundler --conservative

RUN gem install foreman --conservative

RUN bundle install -j4

RUN yarn install

RUN yarn run build

ENTRYPOINT ["bundle", "exec", "bin/delayed_job", "run"]
