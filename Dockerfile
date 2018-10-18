FROM quay.io/akretion/docky-ruby:latest

RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y postgresql-client \
    && apt-get clean
