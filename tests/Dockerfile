FROM monkeydri/reverse-proxy

COPY ./tests.sh /tmp/

# RUN echo "${TEST_BUILD_VAR}"

WORKDIR /tmp

CMD ["sh", "-c", "/tmp/tests.sh ${TEST_BUILD_VAR}"]