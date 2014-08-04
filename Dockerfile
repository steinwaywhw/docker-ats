FROM ubuntu:14.04
MAINTAINER Steinway Wu "http://steinwaywu.com/"

RUN apt-get update
RUN apt-get install -y libgmp3-dev make gcc build-essential wget bash 

RUN mkdir /src

WORKDIR /ats2
RUN wget http://sourceforge.net/projects/ats2-lang/files/latest/download?source=files -O - | tar -zvx --strip-components=1 -f -
RUN ./configure
RUN make install
RUN echo "export PATSHOME=/ats2" > env.sh
RUN echo "export PATH=$PATH:/ats2/bin" >> env.sh
 
ENV PATSHOME /ats2
ENV PATH $PATH:/ats2/bin

ENTRYPOINT /bin/bash