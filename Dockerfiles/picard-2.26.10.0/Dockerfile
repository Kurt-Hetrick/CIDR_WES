FROM ubuntu:16.04

# newer versions of gatk have picard wrapped in, but I don't want to dig up what version of picard this is using
ENV PICARD_URL https://github.com/broadinstitute/picard/releases/download/2.26.10/picard.jar

SHELL ["/bin/bash", "-c"]

RUN mkdir /downloads
RUN mkdir /picard
WORKDIR /downloads

RUN apt-get update -qq && \
	apt-get install -qq \
	bzip2 \
	gcc \
	g++ \
	make \
	zlib1g-dev \
	wget \
	openjdk-8-jdk

RUN wget -nv $PICARD_URL && \
	mv picard.jar /picard/picard.jar && \
	rm -rf /downloads/picard.jar
