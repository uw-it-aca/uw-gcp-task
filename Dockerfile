FROM google/cloud-sdk:latest

ADD scripts /scripts

RUN chmod -R +x /scripts

CMD ["/scripts/start.sh"]
