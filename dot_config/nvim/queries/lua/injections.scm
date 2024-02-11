(
  (function_call
   name: (dot_index_expression
     table: (identifier) @_table (#any-of? @_table "SinaStuff")
     field: (identifier) @_field (#any-of? @_field "syntax_highlighted_content")
    )
   arguments: (arguments
     (string
      content: (string_content) @injection.language)
     (string
      content: (string_content) @injection.content)
    )
  )
)
