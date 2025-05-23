
resource "random_id" "bucket_prefix" {
  byte_length = 8
}

# Bucket for website
resource "google_storage_bucket" "website" {
  provider                    = google
  name                        = "${random_id.bucket_prefix.hex}-mickey-web-app"
  location                    = "US"
  uniform_bucket_level_access = true
  storage_class               = "STANDARD"
  force_destroy               = true
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

# Make the bucket publicly accessible
resource "google_storage_bucket_iam_member" "default" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Upload the website files to the bucket
resource "google_storage_bucket_object" "static_site_src" {
  name         = "index.html"
  source       = "../website/index.html"
  content_type = "text/html"
  bucket       = google_storage_bucket.website.name
}

# Upload a simple 404 / error page to the bucket
resource "google_storage_bucket_object" "errorpage" {
  name         = "404.html"
  source       = "../website/404.html"
  content_type = "text/html"
  bucket       = google_storage_bucket.website.name
}

# reserve an external IP address for the load balancer
resource "google_compute_global_address" "website_ip" {
  provider = google
  name     = "website-lb-ip"
}

# Get managed DNS zone
data "google_dns_managed_zone" "dns_zone" {
  provider = google
  name     = "mickey-web-app"
}

# Add IP to DNS record
resource "google_dns_record_set" "website" {
  provider     = google
  name         = data.google_dns_managed_zone.dns_zone.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  rrdatas      = [google_compute_global_address.website_ip.address]
}

# Add bucket as a CDN backend
resource "google_compute_backend_bucket" "website_backend" {
  provider    = google
  name        = "website-bucket"
  bucket_name = google_storage_bucket.website.name
  description = "Contains the static website files"
  enable_cdn  = true
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    client_ttl        = 3600
    default_ttl       = 3600
    max_ttl           = 86400
    negative_caching  = true
    serve_while_stale = 86400
  }
}

# Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "website" {
  provider = google-beta
  name     = "website-cert"
  managed {
    domains = [google_dns_record_set.website.name]
  }
}

# GCP URL MAP
resource "google_compute_url_map" "website" {
  provider        = google
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website_backend.self_link
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.website_backend.self_link
  }
}

# GCP target HTTP proxy
resource "google_compute_target_https_proxy" "website" {
  provider         = google
  name             = "website-target-proxy"
  url_map          = google_compute_url_map.website.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
}

# GCP global forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  provider              = google
  name                  = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website_ip.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.website.self_link
}