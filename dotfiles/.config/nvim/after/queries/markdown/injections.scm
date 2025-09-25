; extends

;; Handle fenced code blocks with ```qrx
(fenced_code_block
  (info_string) @_lang
  (code_fence_content) @injection.content
  (#eq? @_lang "qrx")
  (#set! injection.language "bash"))

