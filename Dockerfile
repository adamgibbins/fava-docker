FROM python:3.8.7-alpine3.11 as build_env

ENV BUILDDEPS "libxml2-dev libxslt-dev gcc musl-dev git npm make g++"
# Short python version.
ENV PV "3.8"

WORKDIR /root
RUN apk add --no-cache ${BUILDDEPS}

RUN git clone https://github.com/beancount/beancount.git
RUN echo "Beancount version:" && cd beancount && git log -1

RUN git clone https://github.com/beancount/fava.git
RUN echo "Fava version:" && cd fava && git log -1

RUN echo "Deleting symlink files as they will cause docker build error" && find ./ -type l -delete -print

RUN echo "Install Beancount..."
RUN python3 -mpip install ./beancount

RUN echo "Install Fava..."
RUN make -C fava
RUN make -C fava mostlyclean
RUN python3 -mpip install ./fava

RUN echo "Strip .so files to reduce image size:"
RUN find /usr/local/lib/python${PV}/site-packages -name '*.so' -print0|xargs -0 strip -v
RUN echo "Remove unused files to reduce image size:"
RUN find /usr/local/lib/python${PV} -name __pycache__ -exec rm -rf -v {} +
RUN find /usr/local/lib/python${PV} -type f -name '*.exe' -delete


FROM python:3.8.7-alpine3.11
ENV PV "3.8"
ENV BEANCOUNT_INPUT_FILE ""
ENV FAVA_OPTIONS "-H 0.0.0.0"
COPY --from=build_env /usr/local/lib/python${PV}/site-packages /usr/local/lib/python${PV}/site-packages
COPY --from=build_env /usr/local/bin/fava /usr/local/bin

# Default fava port number
EXPOSE 5000

CMD ["sh", "-c", "fava $FAVA_OPTIONS $BEANCOUNT_INPUT_FILE"]
