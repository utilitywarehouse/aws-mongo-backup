FROM mongo:4

RUN apt-get update && apt-get -y install awscli

RUN mkdir /telecom
WORKDIR /telecom
ADD run.sh /telecom/run.sh
RUN chmod +x /telecom/run.sh

ENTRYPOINT ["/telecom/run.sh"]