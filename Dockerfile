FROM mongo:4

RUN apt-get update && apt-get -y install awscli

RUN mkdir /telecom
WORKDIR /telecom
COPY . /telecom
RUN chmod +x /telecom/run.sh

CMD /telecom/run.sh