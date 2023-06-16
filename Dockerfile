#Start with downloading, verifying and unpacking the binaries
#No need to pile all steps together to save on layers/disk space in this initial image
FROM ubuntu:latest AS builder

# Needed for unattended apt installs
ARG DEBIAN_FRONTEND=noninteractive

# Make the version configurable
ENV LTC_VER=0.21.2.2

# Set the verifying key and SHASUM as per https://github.com/litecoin-project/litecoin/releases
ENV KEY=0x3620e9d387e55666
ENV SIGNER="davidburkett38@gmail.com"

# Install needed tools 
RUN apt update \
    && apt install -y curl gpg

# Download biaries and signature file
RUN curl -SLO https://download.litecoin.org/litecoin-${LTC_VER}/linux/litecoin-${LTC_VER}-x86_64-linux-gnu.tar.gz \
    && curl -SLO https://download.litecoin.org/litecoin-${LTC_VER}/linux/litecoin-${LTC_VER}-x86_64-linux-gnu.tar.gz.asc \
    && curl -SLO https://download.litecoin.org/litecoin-${LTC_VER}/SHA256SUMS.asc 
    
# Set up gpg keys and trust (as per the link above, got to trust __someone__)
# Iterate over multiple HKP servers since they aren't always reliably responsive
RUN gpg --no-tty --keyserver hkp://pgpkeys.mit.edu:80 --recv-key $KEY \
    || gpg --no-tty --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-key $KEY \
    || gpg --no-tty --keyserver hkps://keyserver.ubuntu.com --recv-key $KEY 

# Run the signature check, fail the image build if gpg fails
# Exit status will not be 0 if verification fails
RUN gpg --verify litecoin-${LTC_VER}-x86_64-linux-gnu.tar.gz.asc litecoin-${LTC_VER}-x86_64-linux-gnu.tar.gz 
RUN gpg --verify SHA256SUMS.asc

# Run the SHA256 check, fail the image build if it doesn't match the SHA256 checksum from github
RUN grep $(sha256sum litecoin-${LTC_VER}-x86_64-linux-gnu.tar.gz | awk '{ print $1 }') SHA256SUMS.asc

RUN mv litecoin-${LTC_VER}-x86_64-linux-gnu.tar.gz litecoin.tgz

#Runtime image
FROM ubuntu:latest

ENV LTC_VER=0.21.2.2
ENV LTC_DATA=/home/litecoin/.litecoin

#Generated from testuser:testpass using the official generator script under share/rpcauth
ENV RPCAUTH="username=testuser:91c1f4425692408e0824a6ba80debb08$53a4653b2aa9ed230daf8852a5c7865bf23c2ecfc5889811c6cb60751209725a"

#Copy checked binaried from the builder image
COPY --from=builder litecoin.tgz litecoin.tgz

#Update OS in order to minimize Grype vulnerability list
#Create unprivileged user and dir structure
RUN set -ex \
    && apt-get update -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && groupadd -f -g 1001 litecoin \
    && useradd -r -u 1001 -g 1001 -d /home/litecoin -G litecoin -m -s /bin/bash litecoin \
    && mkdir -p $LTC_DATA \
    && chown 1001:1001 $LTC_DATA \
    && tar --strip=2 -xzf litecoin.tgz -C /usr/local/bin \
    && rm -f litecoin.tgz

VOLUME ["$LTC_DATA"]

#List of ports found in other litecoin images on dockerhub, documentation wrt which ports are needed was surprisingly hard to find
EXPOSE 9332 9333 19332 19333 19444

#Switch to unprivileged user
USER litecoin

#Start daemon
CMD ["litecoind","-server=1","-rpcauth=${RPCAUTH}"]

