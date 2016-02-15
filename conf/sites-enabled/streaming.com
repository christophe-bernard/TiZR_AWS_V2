server {
    listen       80;
#    server_name  streaming.com;

    location / {
        root   /var/www;
        index  index.html index.htm;
    }

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }

}
