# Logfire query rules

- Query the project `intility-traces`. My services write their telemetry there. `intility-logs` is a different project; no service of mine writes to it.
- Call `query_schema_reference` once per session before the first non-trivial query. It holds the schema, the promoted columns and the function rules. This file does not repeat them.
- Bound every query to a narrow window: hours, not days. The limit is 14 days.
- Filter on indexed columns before text columns: `service_name`, `span_name`, `trace_id`, `exception_type`, `http_response_status_code`, `start_timestamp`.
- .NET log messages store the template, not the rendered text, for example `NITRO request to {Url}`. Match the template with a prefix LIKE, for example `message LIKE 'NITRO request%'`. Read rendered values from attributes or promoted columns.
- Use `text_contains(term, message)` for a substring search on the message. Only the message column has a full-text index.
- Read attributes with exact matches: `attributes->>'key' = 'value'`.
- A leading-wildcard LIKE (`'%term%'`) or an ILIKE cannot use an index. It scans every row the other filters leave. Two such queries timed out on 2026-11-11. Prefix-match, use `text_contains`, or narrow the window.
