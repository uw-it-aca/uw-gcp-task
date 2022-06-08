FROM google/cloud-sdk:latest as uw-gcp-task

RUN apt-get update -y && \
    apt-get install -y cron

RUN echo "# root crontab" | crontab -

ADD scripts /scripts

RUN chmod -R +x /scripts

ENTRYPOINT ["/scripts/start.sh"]
