use envoy_proxy_dynamic_modules_rust_sdk::*;
use std::sync::LazyLock;
use std::num::ParseIntError;
use regex::Regex;

/// This implements the [`envoy_proxy_dynamic_modules_rust_sdk::HttpFilterConfig`] trait.
///
/// The trait corresponds to an Envoy filter chain configuration.
pub struct FilterConfig {
    _filter_config: String,
}

impl FilterConfig {
    /// This is the constructor for the [`FilterConfig`].
    ///
    /// filter_config is the filter config from the Envoy config here:
    /// https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/dynamic_modules/v3/dynamic_modules.proto#envoy-v3-api-msg-extensions-dynamic-modules-v3-dynamicmoduleconfig
    pub fn new(filter_config: &str) -> Self {
        Self {
            _filter_config: filter_config.to_string(),
        }
    }
}

impl<EC: EnvoyHttpFilterConfig, EHF: EnvoyHttpFilter> HttpFilterConfig<EC, EHF> for FilterConfig {
    /// This is called for each new HTTP filter.
    fn new_http_filter(&mut self, _envoy: &mut EC) -> Box<dyn HttpFilter<EHF>> {
        Box::new(Filter {})
    }
}

static MAPPING_RE: LazyLock<Regex> =
    LazyLock::new(||  Regex::new(r"\pL\d+-(\d+)").unwrap());

pub fn to_part(partition_id: &str) -> Result<String, ParseIntError> {
    let fork_id = match MAPPING_RE.captures(partition_id) {
        Some(caps) => match caps.get(1) {
            Some(m) => m.as_str().to_string(),
            None => format!("unmatchable, insufficient captures found in {partition_id}")
        },
        None => format!("unmatchable: {partition_id}")
    };
    // info!("extracted fork_id: {fork_id}");
    let hash = match fork_id.parse::<i64>() {
        Ok(int) => Ok((int % 2).to_string()),
        Err(e) => Err(e)
    };
    return hash;
}


/// This implements the [`envoy_proxy_dynamic_modules_rust_sdk::HttpFilter`] trait.
///
/// This is a passthrough filter that does nothing.
pub struct Filter {}

/// This implements the [`envoy_proxy_dynamic_modules_rust_sdk::HttpFilter`] trait.
///
/// Default implementation of all methods is to return `Continue`.
impl<EHF: EnvoyHttpFilter> HttpFilter<EHF> for Filter {
    fn on_request_headers(
        &mut self,
        envoy_filter: &mut EHF,
        _end_of_stream: bool,
    ) -> abi::envoy_dynamic_module_type_on_http_filter_request_headers_status {
        let header_value = envoy_filter.get_request_header_value("X-Nu-Routing").unwrap();
        let binding = std::str::from_utf8(header_value.as_slice());
        let hash = match binding {
            Ok(routing) => match to_part(&routing) {
                Ok(hash) => { // info!("calculated hash: {hash}");
                              hash },
                Err(_) => { // warn!("could not parse {routing} to hash");
                            "-2".to_string() },
            },
            Err(_) => { // warn!("no value found for X-Nu-Routing in headers");
                      "-1".to_string() },
        };
        envoy_filter.set_request_header("X-Nu-Hash", hash.as_bytes()); 

        // let reject = rand::rng().random::<bool>();
        // if reject {
        //     envoy_filter.send_response(403, vec![], Some(b"Access forbidden"));
        //     return abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::StopIteration;
        // }
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
        let mut oddeven_filter = Filter {};
        assert_eq!(
            oddeven_filter.on_request_headers(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_request_headers_status::Continue
        );
        assert_eq!(
            oddeven_filter.on_request_body(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_request_body_status::Continue
        );
        assert_eq!(
            oddeven_filter.on_request_trailers(&mut envoy_filter),
            abi::envoy_dynamic_module_type_on_http_filter_request_trailers_status::Continue
        );
        assert_eq!(
            oddeven_filter.on_response_headers(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_response_headers_status::Continue
        );
        assert_eq!(
            oddeven_filter.on_response_body(&mut envoy_filter, false),
            abi::envoy_dynamic_module_type_on_http_filter_response_body_status::Continue
        );
        assert_eq!(
            oddeven_filter.on_response_trailers(&mut envoy_filter),
            abi::envoy_dynamic_module_type_on_http_filter_response_trailers_status::Continue
        );
    }
}
