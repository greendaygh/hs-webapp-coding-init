{
    email {{acme_email}}
    servers {
        protocols h1 h2 h3
    }
}

{{proxy_domain}} {
    encode gzip zstd

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
        -Server
    }

    handle_path {{api_v1_prefix}}* {
        reverse_proxy backend:{{backend_dev_port}}
    }

    handle_path {{health_endpoint}}* {
        reverse_proxy backend:{{backend_dev_port}}
    }

    handle {
        reverse_proxy frontend:80
    }

    log {
        output stdout
        format json
    }
}
