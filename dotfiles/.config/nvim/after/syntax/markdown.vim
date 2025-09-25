" ~/.config/nvim/after/syntax/markdown.vim

syn match todoCheckbox '\v^\s*\[\s\]'hs=e-2 contains=@NoSpell
syn match todoCheckboxDone '\v^\s*\[x\]'hs=e-2 contains=@NoSpell
syn match todoCheckboxPending '\v^\s*\[-\]'hs=e-2 contains=@NoSpell
syn match todoCheckboxCurrent '\v^\s*\[c\].*$' contains=@NoSpell

hi def link todoCheckbox Todo
hi def link todoCheckboxDone StatusLineTerm
hi def link todoCheckboxPending MarkdownError
hi def link todoCheckboxCurrent MarkdownError

syn match fourDigitLineStart '\v^[0-9]{4}\s' contains=@NoSpell
syn match markdownHorizontalRule '\v^(\=\=\=+|-{3,}|\*{3,}|_{3,})$' contains=@NoSpell

hi def link fourDigitLineStart Number
hi def link markdownHorizontalRule MarkdownError

syn region MarkdownCommandLine start=/^>>\$/ end=/$/ oneline contains=@NoSpell
hi def link MarkdownCommandLine ModeMsg
syn region MarkdownNoteLine start=/^>>\([^$]\|$\)/ end=/$/ oneline contains=@NoSpell
hi def link MarkdownNoteLine Todo 

syn region markdownInlineCode matchgroup=markdownCodeDelimiter start=/\v`/ end=/\v`/ oneline
hi def link markdownInlineCode Constant
hi def link markdownCodeDelimiter Special

syn match markdownBlockquoteContent '.*' contained
hi def link markdownBlockquote CursorLine
hi def link markdownBlockquoteContent cursorLine 

syn match markdownConflictMarkerBegin '^<<<<<<< .*$' contains=@NoSpell
syn match markdownConflictMarkerSeparator '^=======$' contains=@NoSpell
syn match markdownConflictMarkerEnd '^>>>>>>> .*$' contains=@NoSpell
hi def link markdownConflictMarkerBegin Error
hi def link markdownConflictMarkerSeparator WarningMsg
hi def link markdownConflictMarkerEnd Error

syn match gitRepoReference '\v\<[^>]+\.git\>' contains=@NoSpell
hi def link gitRepoReference DiffAdd 

syn match atMention '\v\@[a-zA-Z0-9_]+' contains=@NoSpell
hi def link atMention Character 

syn case match
syn keyword allCapsWord TODO FIXME SPRINT FOCUS TODAY TODAYS SLEEP WEIGHT DREAMS LIFE YEARLY SEASON
hi def link allCapsWord Constant
syn case ignore

syn match emailAddress '\v[a-zA-Z0-9._%+-]+\@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' contains=@NoSpell
hi def link emailAddress Underlined

syn match httpUrl '\v(https?:\/\/)[a-zA-Z0-9._~:\/?#\[\]\@!$&''()=;,-]+' contains=@NoSpell
hi def link httpUrl Underlined

syn match numbersInBrackets '\[[0-9]\+\]' contains=@NoSpell
hi def link numbersInBrackets Number

syn region markdownBlockquote matchgroup=markdownBlockquoteChar start=/^\s*>\s\+/ end=/$/ oneline contains=markdownInlineCode,httpUrl,atMention,numbersInBrackets,emailAddress,gitRepoReference,markdownItalic,markdownBold,markdownUnderline,markdownStrikethrough,markdownHeadingDelimiter,markdownCodeBlock,markdownBlockquoteContent
