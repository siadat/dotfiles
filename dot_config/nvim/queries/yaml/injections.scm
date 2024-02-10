(
  (block_mapping_pair
    key: (flow_node) @language (#any-of? @language "language")
    value:
      (flow_node
        (plain_scalar
        (string_scalar) @injection.language)))
  (block_mapping_pair
    key: (flow_node) @_run (#any-of? @_run "content")
    value:
      (block_node
        (block_scalar) @injection.content
        (#offset! @injection.content 0 1 0 0)))
)
