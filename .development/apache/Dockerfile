FROM httpd:2.4.68

RUN sed -i \
        -e 's/^#LoadModule proxy_module/LoadModule proxy_module/' \
        -e 's/^#LoadModule proxy_fcgi_module/LoadModule proxy_fcgi_module/' \
        -e 's/^#LoadModule rewrite_module/LoadModule rewrite_module/' \
        conf/httpd.conf \
    && printf '\nInclude conf/extra/iis-project.conf\n' >> conf/httpd.conf

COPY apache/iis-project.conf /usr/local/apache2/conf/extra/iis-project.conf
