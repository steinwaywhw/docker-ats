FROM ubuntu
MAINTAINER Steinway Wu "https://github.com/steinwaywhw/docker-ats"

# for installing erlang/elixir
WORKDIR /tmp
RUN apt-get update
RUN apt-get install -y wget curl
RUN wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
RUN dpkg -i erlang-solutions_1.0_all.deb

RUN apt-get update
RUN apt-get install -y libgmp3-dev libgc-dev make gcc build-essential git bash libjson-c-dev esl-erlang elixir pkg-config

# ats2 and contrib source code
WORKDIR /
RUN mkdir ats2 
RUN cd ats2 && wget -qO- https://sourceforge.net/projects/ats2-lang/files/ats2-lang/ats2-postiats-0.2.7/ATS2-Postiats-0.2.7.tgz/download | tar --strip-components=1 -zxf -
RUN git clone https://github.com/githwxi/ATS-Postiats-contrib.git ats2-contrib && cd ats2-contrib && git reset --hard 111737979cba5a0a36ed16758735b477b1ab93ec && cd ..
RUN git clone -b smtlib https://github.com/wdblair/ATS-Postiats-contrib ats2-contrib-smtlib && cd ats2-contrib-smtlib && git reset --hard de1256cd7b850198def6c8e9ef29773ed2775e88 && cd ..

# env
ENV PATSHOME /ats2
ENV PATH ${PATH}:/ats2/bin

# build ats2
WORKDIR /ats2
RUN ./configure
RUN make all

# install z3
WORKDIR /
RUN git clone https://github.com/Z3Prover/z3
WORKDIR /z3
RUN apt-get install -y python
RUN CXX=clang++ CC=clang python scripts/mk_make.py
WORKDIR /z3/build
RUN make
RUN make install

# build smt solve
ENV PATSHOMERELOC /ats2-contrib-smtlib
ENV PATSHOME_contrib /ats2-contrib-smtlib

WORKDIR ${PATSHOMERELOC}/projects/MEDIUM/ATS-extsolve
RUN make DATS_C
WORKDIR ${PATSHOMERELOC}/projects/MEDIUM/ATS-extsolve-smt
RUN make build
RUN mv -f patsolve_smt ${PATSHOME}/bin

# build z3 solve
ENV PATSHOMERELOC /ats2-contrib
ENV PATSHOME_contrib /ats2-contrib

WORKDIR ${PATSHOMERELOC}/projects/MEDIUM/ATS-extsolve
RUN make DATS_C
WORKDIR ${PATSHOMERELOC}/projects/MEDIUM/ATS-extsolve-z3
RUN make build
RUN mv -f patsolve_z3 ${PATSHOME}/bin

# build parse-emit
WORKDIR ${PATSHOMERELOC}/projects/MEDIUM/CATS-parsemit
RUN make DATS_C

# build 2js
WORKDIR ${PATSHOMERELOC}/projects/MEDIUM/CATS-atsccomp/CATS-atscc2js
RUN make build
RUN mv -f atscc2js ${PATSHOME}/bin
WORKDIR ${PATSHOMERELOC}/contrib/libatscc/libatscc2js
RUN make all 
RUN make all_in_one

# build 2erl
WORKDIR ${PATSHOMERELOC}/projects/MEDIUM/CATS-atsccomp/CATS-atscc2erl 
RUN make build
RUN mv -f atscc2erl ${PATSHOME}/bin
WORKDIR ${PATSHOMERELOC}/contrib/libatscc/libatscc2erl
RUN make all 
RUN make all_in_one
WORKDIR ${PATSHOMERELOC}/contrib/libatscc/libatscc2erl/Session 
RUN make all 
RUN make all_in_one

# install em
# RUN apt-get install python-pip
# RUN pip install em

#RUN echo "export PATSHOME=/ats2" > env.sh
#RUN echo "export PATSHOMERELOC=/ats2-contrib" >> env.sh
#RUN echo "export PATH=$PATH:/ats2/bin" >> env.sh
WORKDIR ${HOME}
ENTRYPOINT /bin/bash