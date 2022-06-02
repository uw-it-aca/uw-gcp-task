FROM google/cloud-sdk:latest as uw-gcp-task

ADD scripts /scripts

RUN chmod -R +x /scripts

CMD ["/scripts/start.sh"]
