use envoy_proxy_dynamic_modules_rust_sdk::*;
use regex::Regex;

pub struct FilterConfig {
    re: Regex,
}

impl FilterConfig {
    /// This is the constructor for the [`FilterConfig`].
    ///
    /// filter_config is the filter config from the Envoy config here:
    /// https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/dynamic_modules/v3/dynamic_modules.proto#envoy-v3-api-msg-extensions-dynamic-modules-v3-dynamicmoduleconfig
    pub fn new(_filter_config: &str) -> Self {
        Self {
            re: Regex::new(r"\pL\d+-(\d+)").unwrap(),
        }
    }
}

impl<EC: EnvoyHttpFilterConfig, EHF: EnvoyHttpFilter> HttpFilterConfig<EC, EHF> for FilterConfig {
    /// This is called for each new HTTP filter.
    fn new_http_filter(&mut self, _envoy: &mut EC) -> Box<dyn HttpFilter<EHF>> {
        Box::new(Filter {
            re: self.re.clone(),
        })
    }
}

pub struct Filter {
    /// The regex to match against the header.
    re: Regex,
}

impl Filter {
    pub fn hash(&self, partition_id: &str) -> Option<String> {
        let Some(caps) = self.re.captures(partition_id) else {
            return None;
        };
        let Some(m) = caps.get(1) else {
            return None;
        };
        match m.as_str().to_string().parse::<i64>() {
            Ok(int) => Some((int % 2).to_string()),
            _ => None
        }
    }
}

impl<EHF: EnvoyHttpFilter> HttpFilter<EHF> for Filter {
    fn on_request_headers(
        &mut self,
        envoy_filter: &mut EHF,
        _end_of_stream: bool,
    ) -> abi::envoy_dynamic_module_type_on_http_filter_request_headers_status {
        let Some(header_value) = envoy_filter.get_request_header_value("x-nu-routing") else {
            envoy_filter.send_response(403, vec![], Some(b"Access forbidden: missing routing header"));
            return abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::StopIteration
        };

        let binding = std::str::from_utf8(header_value.as_slice()).unwrap_or("");
        if binding.is_empty() {
            envoy_filter.send_response(400, vec![], Some(b"Bad request: empty routing header"));
            return abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::StopIteration
        }

        let Some(hash) = self.hash(binding) else {
            envoy_filter.send_response(400, vec![], Some(b"Bad request: invalid routing header format"));
            return abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::StopIteration
        };

        envoy_filter.set_request_header("x-nu-hash", hash.as_bytes());
        abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::Continue
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    /// This demonstrates how to write a test without Envoy using a mock provided by the SDK.
    fn test_filter() {
        let mut envoy_filter = envoy_proxy_dynamic_modules_rust_sdk::MockEnvoyHttpFilter::new();
        let mut filter = Filter {
            re: Regex::new(r"\pL\d+-(\d+)").unwrap(),
        };

        envoy_filter
            .expect_get_request_header_value()
            .withf(|name| name == "x-nu-routing")
            .returning(|_| Some(EnvoyBuffer::new("s0-1234")))
            .once();

        envoy_filter
            .expect_set_request_header()
            .withf(|name, value| name == "x-nu-hash" && value == b"0")
            .return_const(true)
            .once();

        assert_eq!(
            filter.on_request_headers(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::Continue
        );
        assert_eq!(
            filter.on_request_body(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_request_body_status::Continue
        );
        assert_eq!(
            filter.on_request_trailers(&mut envoy_filter),
            abi::envoy_dynamic_module_type_on_http_filter_request_trailers_status::Continue
        );
        assert_eq!(
            filter.on_response_headers(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_response_headers_status::Continue
        );
        assert_eq!(
            filter.on_response_body(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_response_body_status::Continue
        );
        assert_eq!(
            filter.on_response_trailers(&mut envoy_filter),
            abi::envoy_dynamic_module_type_on_http_filter_response_trailers_status::Continue
        );
    }
}
