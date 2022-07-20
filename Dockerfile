# TODO: mcr base?
FROM ubuntu:20.04 as debs

# Install ISO from nvidia

WORKDIR /opt/debs
COPY download.sh download.sh 
RUN bash download.sh

FROM ubuntu:20.04

COPY --from=debs /opt/debs /opt/debs
COPY entrypoint.sh /entrypoint.sh 

ENTRYPOINT ["/entrypoint.sh"]


