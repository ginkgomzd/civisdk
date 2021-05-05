FROM civisdk/shell

USER root
WORKDIR /root
RUN git clone https://github.com/ginkgomzd/make-do.git
RUN make -C make-do install && rm -rf make-do

ARG LOGIN_UID
USER ${LOGIN_UID}
