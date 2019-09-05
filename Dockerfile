FROM ubuntu:18.04

LABEL maintainer="9to6 <ktk0011@gmail.com>"

RUN apt-get update; \
     apt-get -y install make automake libtool flex bison pkg-config g++ libssl1.0-dev libevent-dev git-core wget python-minimal python-setuptools && rm -rf /var/lib/apt/lists/*

# Boost
RUN mkdir src && cd src && wget 'https://sourceforge.net/projects/boost/files/boost/1.55.0/boost_1_55_0.tar.bz2' && tar -xjf boost*.bz2 && rm -f boost*.bz2 && mv boost* boost && \
  cd boost && ./bootstrap.sh && ./b2 link=static; echo 'done' && ./b2 link=static install; cd .. && rm -rf boost

WORKDIR /root/src

# Thrift, FB303, python libs
RUN wget 'http://archive.apache.org/dist/thrift/0.9.3/thrift-0.9.3.tar.gz' && \
  tar -xzf thrift*.gz && rm -f thrift*.gz && mv thrift* thrift && cd thrift && ./configure --with-boost-libdir=/usr/local/lib --with-boost=/usr/local && make && make install && cd .. && \
  cd ~/src/thrift/tutorial && echo -n 'Test 1: '; \
  if thrift -r -v --gen cpp tutorial.thrift 2>&1 >/dev/null; then echo Success; else echo Failure; fi && \
  echo -n 'Test 2: '; \
  if [ -d gen-cpp ]; then echo Success; else echo Failure; fi && \
  cd ~/src/thrift/contrib/fb303 && ./bootstrap.sh && ./configure CPPFLAGS="-DHAVE_INTTYPES_H -DHAVE_NETINET_IN_H" && \
  make && make install && \
  echo '/usr/local/lib' > /etc/ld.so.conf.d/thrift.conf && ldconfig -v && \
  cd ~/src/thrift/lib/py && python setup.py install && cd ~/src/thrift/contrib/fb303/py && python setup.py install && \
  echo -n 'Test Thrift: '; \
  if python -c 'import thrift' 2>/dev/null; then echo Success; else echo Failure; fi && \
  echo -n 'Test FB303: '; \
  if python -c 'import fb303' 2>/dev/null; then echo Success; else echo Failure; fi && \
    cd ~/src && rm -rf thrift

# Scribe
RUN git clone 'https://github.com/9to6/scribe.git' && \
  cd scribe* && ./bootstrap.sh && ./configure CPPFLAGS="-DHAVE_INTTYPES_H -DHAVE_NETINET_IN_H -DBOOST_FILESYSTEM_VERSION=3" \
  LIBS="-lboost_system -lboost_filesystem" && make && make install && cd .. && rm -rf scribe

#RUN echo -n 'Test Scribe: '; \
#  if python -c 'import scribe' 2>/dev/null; then echo Success; else echo Failure; fi && \
#  scribed 2>/dev/null \& && child=$! && sleep 0.5 && echo -n "Checking child PID [$child]..."; \
#  if kill -0 $child 2>/dev/null; then echo Success; else echo Failure; fi && \
#  kill $child 2>/dev/null && echo "Removed child PID [$child]."

RUN mkdir -p /usr/local/scribe
ADD scribe.conf /usr/local/scribe/scribe.conf
ONBUILD ADD scribe.conf /usr/local/scribe/scribe.conf

EXPOSE 1463

ENTRYPOINT ["/usr/local/bin/scribed", "-c", "/usr/local/scribe/scribe.conf"]

#RUN wget 'https://invisible-island.net/datafiles/release/mawk.tar.gz' && tar -xzf mawk*.gz && rm -f mawk*.gz && mv mawk* mawk && cd mawk && ./configure && make all && make install && cd .. && rm -rf mawk

