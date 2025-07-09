use envoy_proxy_dynamic_modules_rust_sdk::*;
use regex::Regex;
use std::sync::Arc;

const ROUTING_REGEX_PATTERN: &str = r"\pL\d+-(\d+)";

const ROUTING_HEADER: &str = "x-nu-routing";
const HASH_HEADER: &str = "x-nu-hash";
const HASH_HEADER_EVEN_VALUE: &str = "0";
const HASH_HEADER_ODD_VALUE: &str = "1";

pub struct FilterConfig {
    re: Arc<Regex>,
}

impl FilterConfig {
    /// This is the constructor for the [`FilterConfig`].
    ///
    /// filter_config is the filter config from the Envoy config here:
    /// https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/dynamic_modules/v3/dynamic_modules.proto#envoy-v3-api-msg-extensions-dynamic-modules-v3-dynamicmoduleconfig
    pub fn new(_filter_config: &str) -> Self {
        Self {
            re: Arc::new(Regex::new(ROUTING_REGEX_PATTERN).expect("Invalid regex")),
        }
    }
}

impl<EC: EnvoyHttpFilterConfig, EHF: EnvoyHttpFilter> HttpFilterConfig<EC, EHF> for FilterConfig {
    /// This is called for each new HTTP filter.
    fn new_http_filter(&mut self, _envoy: &mut EC) -> Box<dyn HttpFilter<EHF>> {
        Box::new(Filter {
            re: Arc::clone(&self.re),
        })
    }
}

pub struct Filter {
    /// The regex to match against the header.
    re: Arc<Regex>,
}

impl Filter {
    pub fn hash(&self, partition_id: &str) -> Option<&'static str> {
        self.re.captures(partition_id)
            .and_then(|caps| caps.get(1))
            .and_then(|m| m.as_str().parse::<i64>().ok())
            .map(|int| if int % 2 == 0 { HASH_HEADER_EVEN_VALUE } else { HASH_HEADER_ODD_VALUE })
    }
}

impl<EHF: EnvoyHttpFilter> HttpFilter<EHF> for Filter {
    fn on_request_headers(
        &mut self,
        envoy_filter: &mut EHF,
        _end_of_stream: bool,
    ) -> abi::envoy_dynamic_module_type_on_http_filter_request_headers_status {
        let header_value = match envoy_filter.get_request_header_value(ROUTING_HEADER) {
            Some(val) => val,
            None => {
                envoy_filter.send_response(
                    404,
                    vec![],
                    Some(b"Not found: missing routing header"),
                );
                return abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::StopIteration;
            }
        };

        let routing_header = match std::str::from_utf8(header_value.as_slice()) {
            Ok(s) if !s.is_empty() => s,
            _ => {
                envoy_filter.send_response(
                    400,
                    vec![],
                    Some(b"Bad request: empty or invalid routing header"),
                );
                return abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::StopIteration;
            }
        };

        let hash = match self.hash(routing_header) {
            Some(h) => h,
            None => {
                envoy_filter.send_response(
                    400,
                    vec![],
                    Some(b"Bad request: invalid routing header format"),
                );
                return abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::StopIteration;
            }
        };

        envoy_filter.set_request_header(HASH_HEADER, hash.as_bytes());
        envoy_filter.clear_route_cache();
        abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::Continue
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_filter_config_new() {
        let config = FilterConfig::new("some_config");
        // Verify the regex is properly initialized
        assert!(config.re.is_match("s0-123"));
        assert!(!config.re.is_match("invalid"));
    }

    #[test]
    fn test_hash_method() {
        let filter = Filter {
            re: Arc::new(Regex::new(ROUTING_REGEX_PATTERN).unwrap()),
        };

        // Test even numbers
        assert_eq!(filter.hash("s0-1234"), Some(HASH_HEADER_EVEN_VALUE));
        assert_eq!(filter.hash("a1-0"), Some(HASH_HEADER_EVEN_VALUE));

        // Test odd numbers
        assert_eq!(filter.hash("s0-1235"), Some(HASH_HEADER_ODD_VALUE));
        assert_eq!(filter.hash("z9-1"), Some(HASH_HEADER_ODD_VALUE));

        // Test invalid formats
        assert_eq!(filter.hash("invalid"), None);
        assert_eq!(filter.hash("s0-"), None);
        assert_eq!(filter.hash("s0-abc"), None);
        assert_eq!(filter.hash(""), None);
    }

    #[test]
    fn test_filter() {
        let mut envoy_filter = envoy_proxy_dynamic_modules_rust_sdk::MockEnvoyHttpFilter::new();
        let mut filter = Filter {
            re: Arc::new(Regex::new(ROUTING_REGEX_PATTERN).unwrap()),
        };

        // Test with zero
        envoy_filter
            .expect_get_request_header_value()
            .withf(|name| name == ROUTING_HEADER)
            .returning(|_| Some(EnvoyBuffer::new("s0-0")))
            .once();

        envoy_filter
            .expect_set_request_header()
            .withf(|name, value| name == HASH_HEADER && value == HASH_HEADER_EVEN_VALUE.as_bytes())
            .return_const(true)
            .once();

        envoy_filter
            .expect_clear_route_cache()
            .return_const(())
            .once();

        assert_eq!(
            filter.on_request_headers(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::Continue
        );

        // Test with even partition ID
        envoy_filter
            .expect_get_request_header_value()
            .withf(|name| name == ROUTING_HEADER)
            .returning(|_| Some(EnvoyBuffer::new("s0-1234")))
            .once();

        envoy_filter
            .expect_set_request_header()
            .withf(|name, value| name == HASH_HEADER && value == HASH_HEADER_EVEN_VALUE.as_bytes())
            .return_const(true)
            .once();

        envoy_filter
            .expect_clear_route_cache()
            .return_const(())
            .once();

        envoy_filter.expect_send_response().never();

        assert_eq!(
            filter.on_request_headers(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::Continue
        );

        // Test with odd partition ID
        envoy_filter
            .expect_get_request_header_value()
            .withf(|name| name == ROUTING_HEADER)
            .returning(|_| Some(EnvoyBuffer::new("s0-1235")))
            .once();

        envoy_filter
            .expect_set_request_header()
            .withf(|name, value| name == HASH_HEADER && value == HASH_HEADER_ODD_VALUE.as_bytes())
            .return_const(true)
            .once();

        envoy_filter
            .expect_clear_route_cache()
            .return_const(())
            .once();

        envoy_filter
            .expect_send_response()
            .never();

        assert_eq!(
            filter.on_request_headers(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::Continue
        );

        // Test with empty partition ID
        envoy_filter
            .expect_get_request_header_value()
            .withf(|name| name == ROUTING_HEADER)
            .returning(|_| Some(EnvoyBuffer::new("")))
            .once();

        envoy_filter
            .expect_send_response()
            .withf(|status, _, body| {
                *status == 400
                    && *body == Some(b"Bad request: empty or invalid routing header")
            })
            .once()
            .return_const(());

        envoy_filter
            .expect_clear_route_cache()
            .return_const(())
            .never();

        assert_eq!(
            filter.on_request_headers(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::StopIteration
        );

        // Test with invalid partition ID
        envoy_filter
            .expect_get_request_header_value()
            .withf(|name| name == ROUTING_HEADER)
            .returning(|_| Some(EnvoyBuffer::new("s1")))
            .once();

        envoy_filter
            .expect_send_response()
            .withf(|status, _, body| {
                *status == 400
                    && *body == Some(b"Bad request: invalid routing header format")
            })
            .once()
            .return_const(());

        envoy_filter
            .expect_clear_route_cache()
            .return_const(())
            .never();

        assert_eq!(
            filter.on_request_headers(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::StopIteration
        );

        // Test with missing routing header
        envoy_filter
            .expect_get_request_header_value()
            .withf(|name| name == ROUTING_HEADER)
            .returning(|_| None)
            .once();

        envoy_filter
            .expect_send_response()
            .withf(|status, _, body| {
                *status == 404
                    && *body == Some(b"Not found: missing routing header")
            })
            .once()
            .return_const(());

        envoy_filter
            .expect_clear_route_cache()
            .return_const(())
            .never();

        assert_eq!(
            filter.on_request_headers(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::StopIteration
        );
    }
}
