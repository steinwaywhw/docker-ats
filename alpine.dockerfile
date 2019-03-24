FROM alpine:3.9 AS builder

RUN apk update && \
	apk --no-cache add alpine-sdk make gmp-dev gc-dev gcc json-c pkgconfig wget && \
	rm -rf /var/cache/apk/*

ENV GCC=gcc
ENV ATSVER=0.2.12
ENV ATSPACK=ats-lang-anairiats-${ATSVER}
ENV ATSPACKTGZ=${ATSPACK}.tgz
ENV ATSLANGURL_srcfg=http://sourceforge.net/projects/ats-lang
ENV ATSLANGURL_github=http://ats-lang.github.io

RUN wget -q ${ATSLANGURL_github}/ATS-Anairiats/${ATSPACKTGZ}
RUN tar -zxf ${ATSPACKTGZ}

ENV ATSHOME=${PWD}/${ATSPACK}
ENV ATSHOMERELOC=ATS-${ATSVER}

RUN cd ${ATSHOME} && \
	./configure && \
	make CC=${GCC} all_ngc
RUN cd $ATSHOME/bootstrap1 && \
	rm -f *.o
RUN cd $ATSHOME/ccomp/runtime/GCATS && \
	make && \
	make clean
RUN git clone https://github.com/githwxi/ATS-Postiats ATS2
RUN cd ATS2 && \
	git reset --hard 9b0e88a79641a754f1f55f31d3928d87334919b6 && \
	cd ..
RUN git clone https://github.com/githwxi/ATS-Postiats-contrib.git ATS2-contrib
RUN cd ATS2-contrib && \
	git reset --hard f5ece05bca615bbb7b896b3699c7a3ca5e929149 && \
	cd ..

ENV PATSHOME=${PWD}/ATS2
ENV PATSHOMERELOC=${PWD}/ATS2-contrib
ENV PATH=${PATSHOME}/bin:${PATH}

RUN cd ATS2 && \
	cp ${ATSHOME}/config.h .
RUN cd ATS2 && \
	make -f Makefile_devl
RUN cd ATS2/src && \
	make cleanall
RUN cd ATS2/src/CBOOT && \
	make -C prelude
RUN cd ATS2/src/CBOOT && \
	make -C libc
RUN cd ATS2/src/CBOOT && \
	make -C libats
RUN cd ATS2/utils/libatsopt && \
	make && \
	make clean
RUN cp ATS2/utils/libatsopt/libatsopt.a ${ATSHOME}/ccomp/lib
RUN cd ATS2/utils/libatsynmark && \
	make && \
	make clean
RUN cp ATS2/utils/libatsynmark/libatsynmark.a ${ATSHOME}/ccomp/lib

#-----------------------------------------------------------------------------

FROM alpine:3.9 as runner

RUN apk update && apk --no-cache add gmp

ENV GCC=gcc
ENV ATSVER=0.2.12
ENV ATSPACK=ats-lang-anairiats-${ATSVER}
ENV ATSPACKTGZ=${ATSPACK}.tgz
ENV ATSLANGURL_srcfg=http://sourceforge.net/projects/ats-lang
ENV ATSLANGURL_github=http://ats-lang.github.io
ENV ATSHOME=${PWD}/${ATSPACK}
ENV PATSHOME=${PWD}/ATS2
ENV PATSHOMERELOC=${PWD}/ATS2-contrib
ENV PATH=${PATSHOME}/bin:${PATH}

COPY --from=builder ${ATSHOME} ${ATSHOME}
COPY --from=builder ${PATSHOME} ${PATSHOME}

CMD ["patscc"]