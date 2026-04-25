{
    email {{acme_email}}
    # Let's Encrypt staging CA (test-acme) — rate-limit 회피용.
    # 인증서는 브라우저에 신뢰되지 않으므로 staging 환경 검증/리허설 전용.
    acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
    servers {
        protocols h1 h2 h3
    }
}

staging.{{proxy_domain}} {
    encode gzip zstd

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
        X-Robots-Tag "noindex, nofollow"
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
