FROM ruby:2.5.1

# Unicode locale fix
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

RUN apt-get install -y nodejs
ENV LANG en_US.UTF-8

RUN gem install bundler

COPY docker/backend/prepare.sh /usr/bin/prepare
RUN chmod +x /usr/bin/prepare

WORKDIR /app
# CMD ['bundle', 'exec', 'rails', 'server', '-b', '0.0.0.0', '-p', '3000']
