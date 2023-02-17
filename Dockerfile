FROM alpine:latest as builder
ENV TENGINE_VERSION 2.4.0
ENV NGINX_HOME /home/nginx
ENV HTTP_PORT 80 443 8081

RUN apk update 
RUN apk add --no-cache bash
RUN apk add zlib-dev openssl openssl-dev pcre pcre-dev gcc g++ make wget
RUN cd /opt
RUN wget https://github.com/alibaba/tengine/archive/refs/tags/$TENGINE_VERSION.tar.gz --content-disposition 
RUN tar -zxvf tengine-$TENGINE_VERSION.tar.gz \
    && cd tengine-$TENGINE_VERSION \
    && /bin/bash -c './configure --prefix=$NGINX_HOME \
--with-http_stub_status_module \
--with-stream \
--with-http_realip_module \
--with-http_gzip_static_module \
--with-http_ssl_module \
--add-module=./modules/ngx_http_upstream_dyups_module \
--add-module=./modules/ngx_http_upstream_check_module/ ' \
    && make \
    && make install \
    && /bin/bash -c 'mkdir -p /home/nginx/conf/conf.d' 
COPY nginx.conf /home/nginx/conf/nginx.conf
COPY start.sh auto-reload.sh /home/nginx/sbin/

#二次构建
FROM alpine:latest
WORKDIR $NGINX_HOME
COPY --from=builder /home/nginx /home/nginx
RUN  adduser -S -g www-data www-data
RUN  chown -R www-data:www-data /home/nginx \
	&& chmod +x /home/nginx/sbin/*
ENV TZ=GMT+8
ENV PATH $PATH:$NGINX_HOME/sbin
VOLUME ["/home/nginx/conf.d"]
EXPOSE 80 443 8081
RUN apk add --no-cache bash pcre inotify-tools
CMD ["/home/nginx/sbin/start.sh"]