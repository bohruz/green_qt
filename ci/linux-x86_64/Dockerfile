FROM ubuntu:focal AS base
COPY ci/linux-x86_64/focal.sh .
RUN ./focal.sh
ENV PREFIX=/depends/linux-x86_64
ENV HOST=linux
ENV ARCH=x86_64
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV CMAKE_INSTALL_PREFIX=$PREFIX
RUN ln -s /usr/bin/python3.8 /usr/bin/python3.10 && rm /usr/bin/python3 && ln -s /usr/bin/python3.8 /usr/bin/python3

FROM base AS hidapi
COPY tools/buildlibusb.sh tools/buildhidapi.sh tools/
RUN tools/buildlibusb.sh && tools/buildhidapi.sh

FROM base AS countly
COPY tools/buildcountly.sh tools/
RUN tools/buildcountly.sh

FROM base AS gdk
COPY tools/buildgdk.sh tools/
RUN . /root/.cargo/env && tools/buildgdk.sh

FROM base AS qt
COPY tools/buildqt.sh tools/
RUN tools/buildqt.sh

FROM qt AS kdsa
COPY tools/buildkdsingleapplication.sh tools/
RUN tools/buildkdsingleapplication.sh

FROM base
COPY --from=hidapi /depends /depends
COPY --from=countly /depends /depends
COPY --from=gdk /depends /depends
COPY --from=kdsa /depends /depends
