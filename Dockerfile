FROM ubuntu:16.04
MAINTAINER arizz96@gmail.com

ARG repository="deb http://repo.yandex.ru/clickhouse/deb/stable/ main/"
ARG version=19.3.4

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        cron \
        ruby2.3 \
        ruby2.3-dev \
        build-essential \
        libxml2-dev \
        libxslt-dev \
        liblzma-dev \
        zlib1g-dev \
        lbzip2 \
        patch \
        apt-transport-https \
        dirmngr \
        gnupg \
    && mkdir -p /etc/apt/sources.list.d \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv E0C56BD4 \
    && echo $repository > /etc/apt/sources.list.d/clickhouse.list \
    && apt-get update \
    && env DEBIAN_FRONTEND=noninteractive \
        apt-get install --allow-unauthenticated --yes --no-install-recommends \
            clickhouse-client=$version \
            clickhouse-common-static=$version \
            locales \
            tzdata \
    && rm -rf /var/lib/apt/lists/* /var/cache/debconf \
    && apt-get clean

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create workdir
RUN mkdir /backup
WORKDIR /backup


# Prepare ruby & gems
COPY Gemfile /backup/Gemfile
COPY Gemfile.lock /backup/Gemfile.lock
RUN gem install nokogiri -v 1.8.5 -- --use-system-libraries=true --with-xml2-include=/usr/include/libxml2 && \
    gem install bundler -v 1.10.6 && \
    bundle config build.nokogiri --use-system-libraries=true --with-xml2-include=/usr/include/libxml2 && \
    NOKOGIRI_USE_SYSTEM_LIBRARIES=1 bundle install


# Copy scripts
COPY run_cron.sh /backup/run_cron.sh
RUN chmod 0700 /backup/run_cron.sh
COPY backup.sh /backup/backup.sh
RUN chmod 0700 /backup/backup.sh
COPY s3upload.rb /backup/s3upload.rb
RUN chmod 0700 /backup/s3upload.rb

# Define default CRON_SCHEDULE to 1 your
ENV BACKUP_CRON_SCHEDULE="0 * * * *"
ENV BACKUP_PRIORITY="ionice -c 3 nice -n 10"

# Prepare cron
RUN touch /var/log/cron.log
ADD crontab /etc/cron.d/backup-cron
RUN chmod 0644 /etc/cron.d/backup-cron

# Run the command on container startup
ENTRYPOINT /backup/run_cron.sh
