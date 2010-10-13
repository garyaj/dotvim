
" Function:    Vim filetype plugin for docbk (docbook) files
" Last Change: 2005/07/03
" Maintainer:  David Nebauer <david@nebauer.org>
" License:     Public domain

" ========================================================================

" ORIGINAL CREDIT:
" Vivek Venugopalan's .vimrc tweaks for use with DocBook 4.1.
" This has been revised from Dan York's .vimrc.
" CREDIT:
" Tobias Reif's "Vim as XML Editor".
" See <http://www.pinkjuice.com/howto/vimxml/>.

" ========================================================================

" TODO:

" ========================================================================

" __1. REQUIREMENTS                                                  {{{1

"	Applications:

" 	enscript
" 	fop
" 	ImageMagick
" 	lynx
" 	xmllint
" 	docbook: the definitive guide (db:tdg)
" 	- location hard-coded: '/usr/share/doc/docbook-defguide/html/'
"   - (location as per Debian package)
"   docbook xsl stylesheets
" 	rxp [optional]
" 	Saxon [optional]
" 	Xalan [optional]
" 	xep [optional]
"   RefDB [optional]

" ========================================================================

" __2. CONTROL STATEMENTS                                            {{{1

" Only do this when not done yet for this buffer
" Don't set 'b:did_ftplugin = 1' because that is xml.vim's responsibility.
if exists("b:did_ftplugin") | finish | endif

" Use default cpoptions to avoid unpleasantness from customised
" 'compatible' settings
let s:save_cpo = &cpo
set cpo&vim

" ========================================================================

" _3. FUNCTIONS                                                      {{{1

" These functions were not designed with the objective of being called
" directly by the user.  Rather, they are used by various mappings (see
" section <MAPPINGS>).

" ------------------------------------------------------------------------
" Function:   Dbn_InsertDoctypeDecl                                  {{{2
" Purpose:    Insert document declaration, either 'book' or 'article'
" Parameters: doctype     - doc. type   ( 'book'  | 'article' )
" Returns:    NONE
if !exists( "*s:Dbn_InsertDoctypeDecl" )
function s:Dbn_InsertDoctypeDecl( doctype )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" error check doctype
	if a:doctype != "book" && a:doctype != "article" | return | endif
	" retrieve doctype
	let l:dt_decl = s:Dbn__GetValue( "xml_doctype_decl", a:doctype )
	if l:dt_decl == ""
		let l:msg = "Unable to generate doctype declaration"
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	" insert doctype
	call s:Dbn__InsertString( l:dt_decl, 1 )
	" redraw screen
	execute "redraw!"
	" switch to insert mode
	call s:Dbn__StartInsert( 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertDocStructure                                 {{{2
" Purpose:    Insert document structure, either 'book' or 'article'
" Parameters: doctype     - doc. type   ( 'book'  | 'article' )
"             title       - doc. title  ( <value> | '' | '[NULL]' )
"             titleabbrev - title abbr. ( <value> | '' | '[NULL]' )
"             surname     - author      ( <value> | '' | '[NULL]' )
"             firstname   - author      ( <value> | '' )
"             revnumber   - revision #  ( <value> | '' | '[NULL]' )
" Returns:    NONE
if !exists( "*s:Dbn_InsertDocStructure" )
function s:Dbn_InsertDocStructure( doctype, title, titleabbrev, 
			\ surname, firstname, revnumber )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" error check doctype
	if a:doctype != "book" && a:doctype != "article" | return | endif
	" *** Get user input *** "
	" title
	if a:title == "[NULL]"
		let l:title = a:title
	else
		" get title
		let l:title = s:Dbn__GetInput( "Enter title: ", a:title )
		if l:title == "" | let l:title = "[NULL]" | endif
	endif
	" titleabbrev
	if a:titleabbrev == "[NULL]" || l:title == "[NULL]"
		let l:titleabbrev = a:titleabbrev
	else
		if l:title != "[NULL]"
			" get titleabbrev
			let l:titleabbrev = s:Dbn__GetInput (
						\ "Enter title abbreviation (blank for none): ", 
						\ ( a:titleabbrev != "" ) ? a:titleabbrev : l:title
						\ )
			if l:titleabbrev == "" | let l:titleabbrev = "[NULL]" | endif
		endif
	endif
	" get author surname
	if a:surname == "[NULL]"
		let l:surname = a:surname
	else
		let l:surname = s:Dbn__GetInput( 
					\ 	"Enter author surname (blank for no author): ",
					\ 	a:surname
					\ )
		if l:surname == "" | let l:surname = "[NULL]" | endif
	endif
	" get author forename
	if l:surname != "[NULL]"
		let l:firstname = s:Dbn__GetInput( 
					\ 	"Enter author forename: ",
					\ 	a:firstname
					\ )
	else | let l:firstname = "" | endif
	" get revision
	if a:revnumber == "[NULL]"
		let l:revnumber = a:revnumber
	else
		let l:revnumber = s:Dbn__GetInput(
					\ 	"Enter revision number (blank for no revision): ", 
					\ 	a:revnumber
					\ )
		if l:revnumber == "" | let l:revnumber = "[NULL]" | endif
	endif
	" get revision date
	if l:revnumber != "[NULL]"
		let l:date = s:Dbn__GetInput( 
					\ 	"Enter revision date: ", 
					\ 	strftime( "%d %B %Y" ) 
					\ )
	else | let l:date = "" | endif
	" decide on RCS style keywords (default = No )
	let l:choice = confirm( 
				\ 	"Add RCS-style keywords \"Id\" and \"Log\"? ",
				\ 	"&Yes\n&No",
				\ 	2,
				\	"Question"
				\ )
	if l:choice == 1 | let l:keywords = 1 | else | let l:keywords = 0 | endif
	" *** Output document skeleton *** "
	" [ since some elements optional, always end on following line
	"   -- therefore start most operations with 'O' ]
	" add RCS-style id keyword
	if l:keywords
		silent execute "normal a<!,-,- \<Esc>"
		call s:Dbn_InsertKeyword( "$", "Id" )
		silent execute "normal a ,-,->\<CR>\<Esc>"
	endif
	" add document root element
	silent execute "normal a<" 
				\ . a:doctype 
				\ . ">>\<Esc>dd"
	" add title element
	silent execute "normal O<title>"
	if l:title != "[NULL]"
		silent execute "normal a"
					\ . l:title
					\ . "\<Esc>"
	endif
	silent execute "normal j"
	" add info element if metadata available
	if l:titleabbrev != "[NULL]" || l:surname != "[NULL]" 
				\ || l:revnumber != "[NULL]"
		silent execute "normal O<" . a:doctype . "info>>\<Esc>dd"
		" add titleabbrev element if data present
		if l:titleabbrev != "[NULL]"
			silent execute "normal O<titleabbrev>" 
						\ . l:titleabbrev 
						\ . "\<Esc>j"
		endif
		" add authorgroup element if data present
		if l:surname != "[NULL]"
			silent execute "normal O<authorgroup>><author>><surname>"
						\ . l:surname 
						\ . "\<Esc>o<firstname>"
						\ . l:firstname
						\ . "\<Esc>3j"
		endif
		" add revhistory element if present
		if l:revnumber != "[NULL]"
			silent execute "normal O<revhistory>><revision>><revnumber>" 
						\ . l:revnumber
						\ . "\<Esc>o<date>"
						\ . l:date
						\ . "\<Esc>3j"
		endif
		" position cursor
		silent execute "normal j"
	endif
	" add bibliography entity
	silent execute "normal O\<CR><!,-,- ,&bibliography; ,-,->\<Esc>k"
	" add RCS-style log keyword
	if l:keywords
		silent execute "normal 2jo<!,-,-\<CR>\<Esc>"
		call s:Dbn_InsertKeyword( "$", "Log" )
		silent execute "normal a,-,->\<Esc>4k"
	endif
	" redraw screen
	execute "redraw!"
	" switch to insert mode
	call s:Dbn__StartInsert( 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertKeyword                                      {{{2
" Purpose:    Insert RCS-style keyword
" Parameters: bracket - start and stop character
"             keyword - id|log
" Returns:    NONE
if !exists( "*s:Dbn_InsertKeyword" )
function s:Dbn_InsertKeyword( bracket, keyword )
	" initial bracketing symbol
	if a:bracket != ""
		silent execute "normal a" 
					\ . a:bracket 
					\ . "\<Esc>"
	endif
	" the keyword
	let l:marker = 0
	while l:marker < strlen( a:keyword )
		silent execute "normal a" 
					\ . strpart( a:keyword, l:marker, 1 ) 
					\ . "\<Esc>"
		let l:marker = l:marker + 1
	endwhile
	" final bracketing symbol
	if a:bracket != ""
		silent execute "normal a" 
					\ . a:bracket 
					\ . "\<Esc>"
	endif
	" redraw screen
	execute "redraw!"
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertAuthor                                       {{{2
" Purpose:    Insert author element
" Parameters: NONE
" Returns:    NONE
if !exists( "*s:Dbn_InsertAuthor" )
function s:Dbn_InsertAuthor()
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" get author surname
	let l:surname = s:Dbn__GetInput( "Enter author surname: ", "" )
	if l:surname != ""
		" get author forename
		let l:firstname = s:Dbn__GetInput( "Enter author forename: ", "" )
		" assume adding to existing authorgroup, so start with 'O'
		silent execute "normal O<author>><surname>" 
					\ . l:surname 
					\ . "\<Esc>o<firstname>" 
					\ . l:firstname 
					\ . "\<Esc>2j"
	endif
	" redraw screen
	execute "redraw!"
	" position cursor and switch to insert mode
	call s:Dbn__StartInsert( 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertRevision                                     {{{2
" Purpose:    Insert revision
" Parameters: NONE
" Returns:    NONE
if !exists( "*s:Dbn_InsertRevision" )
function s:Dbn_InsertRevision()
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" get revision
	let l:revnumber = s:Dbn__GetInput(
				\ 	"Enter revision number (blank for no revision): ",
				\ 	""
				\ )
	if l:revnumber != ""
		" get revision date
		let l:date = s:Dbn__GetInput(
					\ 	"Enter revision date: ",
					\	 strftime( "%d %B %Y" )
					\ )
		" assume adding to existing revhistory, so start with 'O'
		silent execute "normal O<revision>><revnumber>" 
					\ . l:revnumber 
					\ . "\<Esc>o<date>" 
					\ . l:date 
					\ . "\<Esc>2j"
	endif
	" redraw screen
	execute "redraw!"
	" position cursor and switch to insert mode
	call s:Dbn__StartInsert( 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertStructure                                    {{{2
" Purpose:    Inserts text structure
" Parameters: pre      - initial structure delimiter
"             post     - terminal structure delimiter
"             prompt   - user prompt
"             complex  - keystrokes for complex case
"             relocate - reposition cursor
" Returns:    NONE
if !exists( "*s:Dbn_InsertStructure" )
function s:Dbn_InsertStructure( pre, post, prompt, complex, relocate )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" if content is complex user must enter entity content manually
	let l:choice = confirm( "Content: ", "&Simple\n&Complex", 1, "Question" )
	if l:choice == 1  " simple content
		" get structure content
		let l:content = s:Dbn__GetInput( a:prompt, "" )
		if l:content != ""
			" build structure
			let l:structure = a:pre 
						\ . l:content 
						\ . a:post
			" insert structure
			call s:Dbn__InsertString( l:structure, 1 )
		endif
	elseif l:choice == 2  " complex content
		silent execute "normal a" 
					\ . a:complex 
					\ . "\<Esc>" 
					\ . a:relocate
	endif
	call s:Dbn__StartInsert( 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertQuoteMark                                    {{{2
" Purpose:    Inserts quote mark
" Parameters: mark - type of quote (= single|double)
" Returns:    string - appropriate quote entity
if !exists( "*s:Dbn_InsertQuoteMark" )
function s:Dbn_InsertQuoteMark( mark )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" proceed only with valid parameter
	if a:mark != "single" && a:mark != "double"
		echo "Error: Invalid parameter -- aborting."
		return
	endif
	" open quote if prev char is space, end of tag or end of entity
	let l:quote = ( getline( "." )[ col(".") - 2 ] =~ ' \|>\|;' ) 
				\ ? "&ldquo;" : "&rdquo;"
	if a:mark == "single"
		let l:quote = strpart( l:quote, 0, 2 ) 
					\ . "s" 
					\ . strpart( l:quote, 3 )
	endif
	return l:quote
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_SurroundSelection                                  {{{2
" Purpose:    Inserts text before and after visual selection
" Credit:     Based on WrapTags fn in Devin Weaver's 'xmledit' ftplugin
" Parameters: selection - selected text
"             pre       - text to precede selection
"             post      - text to follow selection
" Returns:    NONE
" Invocation: "zx:call s:Dbn_SurroundSelection( @z, <pre>, <post> )
if !exists( "*s:Dbn_SurroundSelection" )
function s:Dbn_SurroundSelection( selection, pre, post )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" since text has been deleted by calling function
	" must beware of errors stopping function and so losing text
	try
		" determine insert and eol commands
		if     line( "." ) < line( "'<" ) | let l:insert_cmd = "o"
		elseif col( "." ) < col( "'<" )   | let l:insert_cmd = "a"
		else                              | let l:insert_cmd = "i"
		endif
		if visualmode() ==# 'V'
			let l:selection = strpart( 
						\ 	a:selection,
						\ 	0,
						\ 	strlen( a:selection ) - 1
						\ )
			if ( l:insert_cmd ==# "o" ) | let l:eol_cmd = ""
			else                        | let l:eol_cmd = "\<Cr>"
			endif
		else
			let l:selection = a:selection
			let l:eol_cmd = ""
		endif
		" wrap selection
		let l:selection = a:pre 
					\ . l:selection 
					\ . a:post
		" insert new selection
		let l:paste_setting = &paste
		set paste
		execute "normal! " 
					\ . l:insert_cmd 
					\ . l:selection 
					\ . l:eol_cmd
		if ! l:paste_setting | set nopaste | endif
		" some functions needs success flag
		if exists( "s:flag" ) | let s:flag = 1 | endif
	catch
		" undo deletion by calling mapping
		call s:Dbn__ShowMsg( 
					\	"Aborting -- Unable to alter selection.", 
					\	"Error"
					\ )
		undo
	finally
		" position cursor and enter insert mode
		call s:Dbn__StartInsert( 1 )
	endtry
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertDivision                                     {{{2
" Purpose:    Insert major document division (chapter, section, etc.)
" Parameters: tagname    - tagname
"             descriptor - used in prompts
"             fragment   - initial fragment of label
" Returns:    NONE
if !exists( "*s:Dbn_InsertDivision" )
function s:Dbn_InsertDivision( tagname, descriptor, fragment )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" get title
	let l:title = s:Dbn__GetInput(
				\ 	"Enter " . a:descriptor . " title: ",
				\ 	""
				\ )
	" get label
	if l:title != ""
		" get label
		let l:label = s:Dbn__GetLabel( 
					\ 	"Enter " . a:descriptor . " label: ", 
					\ 	a:fragment, 
					\ 	l:title 
					\ )
		" create element skeleton
		if l:label != ""
			silent execute "normal a<" 
						\ . a:tagname 
						\ . " id=,\",\">><title>\<Esc>o<para>\<Esc>2k^2t\""
			" enter label
			call s:Dbn__InsertString( l:label, 0 )
			silent execute "normal j^t<"
			" enter title
			call s:Dbn__InsertString( l:title, 0 )
			silent execute "normal j^t<"
		endif
	endif
	" redraw screen
	execute "redraw!"
	" enter insert mode
	call s:Dbn__StartInsert( 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_XmlEntity                                          {{{2
" Purpose:    Insert xml element - gets content from user
" Parameters: tagname      - element name
"             attributes   - string holding all attributes and their values
"             prompt       - user prompt (empty string if error/cancel)
"             complex_case - insertion string if is complex case
" Returns:    NONE
if !exists( "*s:Dbn_XmlEntity" )
function s:Dbn_XmlEntity( tagname, attributes, prompt, complex_case )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" if content is simple the macro will handle text insertion
	" if content is complex user must enter entity content manually
	let l:choice = confirm( "Content: ", "&Simple\n&Complex", 1, "Question" )
	if l:choice == 1  " simple content
		let l:entity_content = s:Dbn__GetInput( a:prompt, "" )
		if l:entity_content != ""
			call s:Dbn__InsertXmlEntity(
						\ 	a:tagname,
						\ 	a:attributes,
						\ 	l:entity_content
						\ )
		endif
	elseif l:choice == 2  " complex content
		silent execute "normal a" 
					\ . a:complex_case
	endif
	" redraw screen
	execute "redraw!"
	" enter insert mode
	call s:Dbn__StartInsert( 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertFilePath                                     {{{2
" Purpose:    Get and insert filepath at cursor location
" Parameters: prompt - user prompt
" Returns:    NONE
if !exists( "*s:Dbn_InsertFilePath" )
function s:Dbn_InsertFilePath( prompt )
	let l:filepath = s:Dbn__GetFilePath( a:prompt )
	if l:filepath != ""
		call s:Dbn__InsertString( l:filepath, 1 )
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertXref                                         {{{2
" Purpose:    Get and insert 'xref' docbook element at cursor location
" Parameters: NONE
" Returns:    NONE
if !exists( "*s:Dbn_InsertXref" )
function s:Dbn_InsertXref()
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" save file to get recent linkable elements
	silent execute "update"
	let l:link = s:Dbn__ChooseLinkableElement(
				\ 'You must choose the element id you are cross-referencing.' )
	if l:link == "" | return | endif
	" get style choice
	let l:choice = confirm(
				\ 	"Select style: ",
				\ 	"Label page -> for &Figures\n"
				\ 		. "quotedtitle page -> for &Headings",
				\ 	2,
				\	"Question"
				\ )
	if     l:choice == 1  | let l:style = "label"
	elseif l:choice == 2  | let l:style = "quotedtitle"
	else                  | return
	endif
	" build element
	let l:entity = s:Dbn__BuildXmlEntity(
				\ 	"xref",
				\ 	"linkend=\"" 
				\ 		. l:link 
				\ 		. "\" role=\"select: " 
				\ 		. l:style 
				\ 		. " page\"",
				\ 	""
				\ )
	" insert xref element
	call s:Dbn__InsertString( l:entity, 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertUlink                                        {{{2
" Purpose:    Get and insert 'ulink' docbook element (hyperlink)
"             at cursor location
" Parameters: hottext - (optional) selected text
" Returns:    NONE
" Requires:   external file: 'get-filepath'
if !exists( "*s:Dbn_InsertUlink" )
function s:Dbn_InsertUlink( ... )
	" flag for success of operation
	let s:flag = 0
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	try
		" can link to local file or URL
		let l:choice = confirm(
					\ 	"Select resource type to link to: ",
					\ 	"&File (local)\n&Web page",
					\ 	1,
					\	"Question"
					\ )
		let l:resource = ""
		if l:choice == 1
			let l:resource = s:Dbn__GetFilePath( "Select file to link to" )
		elseif l:choice == 2
			let l:resource = s:Dbn__GetInput( "Enter URL: ", "" )
		else
			return
		endif
		if l:resource != ""
			" if visual mode then use 'Dbn_SurroundSelection'
			if a:0 > 0 && a:1 != ""
				let l:before = "<ulink url=\"" . l:resource . "\">"
				let l:after = "</ulink>"
				call s:Dbn_SurroundSelection( a:1, l:before, l:after )
				if mode() == "i" | execute "normal \<Esc>" | endif
			else
				" insert mode
				" first, get hot text
				let l:fragment = ( l:choice == 1 ) ? "file location" : "URL"
				let l:prompt = "For the 'hot' (viewable) text do you want to: "
				let l:choices = "&Enter text\n&Copy " . l:fragment
				let l:choice = confirm( l:prompt, l:choices, 1, "Question" )
				if l:choice == 1
					let l:hottext = s:Dbn__GetInput( "Enter \"hot\" text: ", "" )
				else
					let l:hottext = l:resource
				endif
				if l:hottext != ""
					" build entity
					let l:entity = s:Dbn__BuildXmlEntity(
								\ 	"ulink",
								\ 	"url=\"" . l:resource . "\"",
								\ 	l:hottext
								\ )
					" insert entity
					call s:Dbn__InsertString( l:entity, 1 )
				endif
			endif
		endif
		" catch error from 'Dbn_SurroundSelection'
		if a:0 > 0 && !s:flag | throw "No replacement made" | endif
	catch
		undo
	endtry
	" redraw screen
	execute "redraw!"
	" position cursor and enter insert mode
	call s:Dbn__StartInsert( 1 )
endfunction	
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertFigure                                       {{{2
" Purpose:    Get and insert 'figure' docbook element at cursor location
" Parameters: NONE
" Returns:    NONE
if !exists( "*s:Dbn_InsertFigure" )
function s:Dbn_InsertFigure()
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" get filename of image
	let l:image = s:Dbn__GetFilePath( "Select image file: " )
	if l:image != ""
		" get image type
		let l:choice = confirm(
					\ 	"Select image format: ",
					\ 	"&png\n&jpeg\n&eps\n&gif",
					\ 	1,
					\	"Question"
					\ )
		if     l:choice == 1    | let l:format = "PNG"
		elseif l:choice == 2    | let l:format = "JPEG"
		elseif l:choice == 3    | let l:format = "EPS"
		elseif l:choice == 4    | let l:format = "GIF"
		else                    | return
		endif
		" determine whether to scale printed output
		let l:choice = confirm(
					\ 	"Scale image in print output to A4? ",
					\ 	"&Yes\n&No",
					\ 	1,
					\	"Question"
					\ )
		if     l:choice == 1        | let l:scale_print = 1
		elseif l:choice == 2        | let l:scale_print = 0
		else                        | return
		endif
		" get figure title
		echo "Title is different to caption.  Optional - leave blank if no title."
		let l:msg = ( has( "gui_running" ) ) 
					\ ? "Enter figure title (see cmdline for help): "
					\ : "Enter figure title: "
		let l:title = s:Dbn__GetInput( msg, "" )
		" get image caption
		let l:msg = ( has( "gui_running" ) ) ? "" : "\n\n"
		let l:msg = l:msg . "Caption is different to title.  Optional - leave blank if no caption."
		echo l:msg
		let l:msg = ( has( "gui_running" ) )
					\ ? "Enter image caption (see cmdline for help): "
					\ : "Enter image caption: "
		let l:caption = s:Dbn__GetInput( l:msg, "" )
		if !has( "gui_running" ) | echo "\n\n" | endif
		" get figure label
		let l:label = s:Dbn__GetLabel(
					\	"Enter internal document label: ",
					\	"fig:",
					\	l:title
					\ )
		" start by inserting on new line
		" add figure element
		silent execute "normal o<figure id=,\""
					\ . l:label
					\ . ",\" float=,\"1,\">>\<Esc>"
		" add title element
		silent execute "normal a<title>"
					\ . l:title
					\ . "\<Esc>"
		" add mediaobject element
		silent execute "normal o<mediaobject>>\<Esc>"
		" add html mediaobject element
		silent execute "normal a<imageobject role=,\"html,\">>" 
					\ . "<imagedata fileref=,\"" 
					\ . l:image 
					\ . ",\" format=,\"" 
					\ . l:format 
					\ . ",\"/>\<Esc>"
		" add fo mediaobject element
		silent execute "normal jo<imageobject role=,\"fo,\">>"
					\ . "<imagedata fileref=,\""
					\ . l:image
					\ . ",\" format=,\"" 
					\ . l:format
					\ . ",\""
		if l:scale_print
			silent execute "normal a contentwidth=,\"150mm,\""
						\ . " contentdepth=,\"233mm,\" scalefit=,\"1,\""
						\ . " align=,\"center,\" valign=,\"middle,\"\<Esc>"
		endif
		silent execute "normal a/>\<Esc>2j"
		" add caption if present
		if l:caption != ""
			silent execute "normal O<caption><para>" 
						\ . l:caption 
						\ . "\<Esc>j"
		endif
		" position cursor
		silent execute "normal 2jO"
	endif
	" redraw screen
	execute "redraw!"
	" switch to insert mode
	call s:Dbn__StartInsert( 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertMediaObject                                  {{{2
" Purpose:    Get and insert '[inline]mediaobject' docbook element
" Parameters: NONE
" Returns:    NONE
if !exists( "*s:Dbn_InsertMediaObject" )
function s:Dbn_InsertMediaObject()
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" get filename of image
	let l:image = s:Dbn__GetFilePath( "Select image file: " )
	if l:image != ""
		" get image type
		let l:choice = confirm(
					\ 	"Select image format: ",
					\ 	"&png\n&jpeg\n&eps\n&gif",
					\ 	1,
					\	"Question"
					\ )
		if     l:choice == 1    | let l:format = "PNG"
		elseif l:choice == 2    | let l:format = "JPEG"
		elseif l:choice == 3    | let l:format = "EPS"
		elseif l:choice == 4    | let l:format = "GIF"
		else                    | return
		endif
		" get mediaobject type
		let l:choice = confirm(
					\ 	"Display image as: ",
					\ 	"&Block\n&Inline",
					\ 	1,
					\	"Question"
					\ )
		if     l:choice == 1 | let l:element = "mediaobject"
		elseif l:choice == 2 | let l:element = "inlinemediaobject"
		else                 | return
		endif
		" for mediaobject only, determine whether to scale printed output
		if l:element == "mediaobject"
			let l:choice = confirm(
						\ 	"Scale image in print output to A4? ",
						\ 	"&Yes\n&No",
						\ 	1,
						\	"Question"
						\ )
			if     l:choice == 1    | let l:scale_print = 1
			elseif l:choice == 2    | let l:scale_print = 0
			else                    | return
			endif
		else | let l:scale_print = 0 | endif
		" for mediaobject only, get image caption
		if l:element == "mediaobject"
			let l:caption = s:Dbn__GetInput(
						\ 	"Enter image caption (leave blank if none): ",
						\ 	""
						\ )
		else | let l:caption = "" | endif
		" get image label
		let l:label = s:Dbn__GetLabel(
					\	"Enter internal document label: ",
					\	"mo:",
					\	l:caption
					\ )
		" mediaobject - insert on next line
		"             - skip over rest of current line
		" inlinemediaobject - rendered on next line
		"                   - push remainder of current line ahead
		" add mediaobject element
		if l:element == "mediaobject"
			silent execute "normal o<" 
						\ . l:element 
						\ . " id=,\"" 
						\ . l:label 
						\ . ",\">>\<Esc>"
		else
			silent execute "normal a\<CR>\<Esc>O<"
						\ . l:element
						\ . " id=,\""
						\ . l:label
						\ . ",\">>\<Esc>"
		endif
		" add html mediaobject element
		silent execute "normal a<imageobject role=,\"html,\">>"
					\ . "<imagedata fileref=,\""
					\ . l:image
					\ . ",\" format=,\""
					\ . l:format
					\ . ",\"/>\<Esc>"
		" add fo mediaobject element
		silent execute "normal jo<imageobject role=,\"fo,\">>"
					\ . "<imagedata fileref=,\""
					\ . l:image
					\ . ",\" format=,\""
					\ . l:format
					\ . ",\""
		if l:scale_print
			silent execute "normal a contentwidth=,\"150mm,\""
						\ . " contentdepth=,\"233mm,\" scalefit=,\"1,\""
						\ . " align=,\"center,\" valign=,\"middle,\"\<Esc>"
		endif
		silent execute "normal a/>\<Esc>2j"
		" add caption if present
		if l:caption != ""
			silent execute "normal O<caption><para>"
						\ . l:caption
						\ . "\<Esc>j"
		endif
		" position cursor
		if l:element == "mediaobject" | silent execute "normal o"
		else                          | silent execute "normal j^h"
		endif
	endif
	" redraw screen
	execute "redraw!"
	" switch to insert mode
	call s:Dbn__StartInsert( 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertImageObject                                  {{{2
" Purpose:    Get and insert 'imageobject' docbook element
" Parameters: NONE
" Returns:    NONE
if !exists( "*s:Dbn_InsertImageObject" )
function s:Dbn_InsertImageObject()
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" get filename of image
	let l:image = s:Dbn__GetFilePath( "Select image file: " )
	if l:image != ""
		" get image type
		let l:choice = confirm(
					\ 	"Select image format: ",
					\ 	"&png\n&jpeg\n&eps\n&gif",
					\ 	1,
					\	"Question"
					\ )
		if     l:choice == 1    | let l:format = "PNG"
		elseif l:choice == 2    | let l:format = "JPEG"
		elseif l:choice == 3    | let l:format = "EPS"
		elseif l:choice == 4    | let l:format = "GIF"
		else                    | return
		endif
		" get imageobject role
		let l:choice = confirm(
					\ 	"Output type (role): ",
					\ 	"&All (actually omit)\n&Html\n&Fo (printed)",
					\ 	1,
					\	"Question"
					\ )
		if     l:choice == 1    | let l:role = ""
		elseif l:choice == 2    | let l:role = "html"
		elseif l:choice == 3    | let l:role = "fo"
		else                    | return
		endif
		" for printed output only, determine whether to scale image
		if l:role == "fo"
			let l:choice = confirm(
						\ 	"Scale image in print output to A4? ",
						\ 	"&Yes\n&No",
						\ 	1,
						\	"Question"
						\ )
			if     l:choice == 1    | let l:scale_print = 1
			elseif l:choice == 2    | let l:scale_print = 0
			else                    | return
			endif
		else | let l:scale_print = 0 | endif
		" insert on previous line
		" add imageobject element
		silent execute "normal O<imageobject\<Esc>"
		if l:role == "html"
			silent execute "normal a role=,\"html,\"\<Esc>"
		elseif l:role == "fo"
			silent execute "normal a role=,\"fo,\"\<Esc>"
		endif
		silent execute "normal a>>\<Esc>"
		" add imagedata element
		silent execute "normal a<imagedata fileref=,\"" 
					\ . l:image 
					\ . ",\" format=,\""
					\ . l:format
					\ . ",\"\<Esc>"
		if l:scale_print
			silent execute "normal a contentwidth=,\"150mm,\""
						\ . " contentdepth=,\"233mm,\" scalefit=,\"1,\""
						\ . " align=,\"center,\" valign=,\"middle,\"\<Esc>"
		endif
		silent execute "normal a/>\<Esc>2j$"
	endif
	" redraw screen
	execute "redraw!"
	" switch to insert mode
	call s:Dbn__StartInsert( 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertList                                         {{{2
" Purpose:    Insert list
" Parameters: list_type - type of list: 'itemized', 'variable' or 'ordered'
" Returns:    NONE
if !exists( "*s:Dbn_InsertList" )
function s:Dbn_InsertList( list_type )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" check parameters
	if a:list_type == "itemized" || a:list_type == "ordered"
				\ || a:list_type == "variable"
		let l:list_tag = a:list_type . "list"
	else | echo "Error: Invalid list type" | return | endif
	" get title
	let l:title = s:Dbn__GetInput(
				\ 	"Enter " . a:list_type . " list title (optional): ",
				\ 	""
				\ )
	" add list type and title
	silent execute "normal a<" 
				\ . l:list_tag
				\ . ">>\<Esc>"
	if l:title != ""
		silent execute "normal a<title>"
		call s:Dbn__InsertString( l:title, 0 )
		silent execute "normal j"
	else | silent execute "normal dd" | endif
	" add first entry/item
	if a:list_type == "itemized" || a:list_type == "ordered"
		let l:item_added = s:Dbn_InsertListItem( "first", "" )
	else  " must be 'variable'
		let l:item_added = s:Dbn_InsertVarListEntry( "first", "" )
	endif
	" delete list if no item inserted
	if ! l:item_added | undo | endif
	" redraw screen
	execute "redraw!"
	" position cursor and enter insert mode
	call s:Dbn__StartInsert( 0 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertListItem                                     {{{2
" Purpose:    Insert list item
" Parameters: item_number - item number, e.g. 'first' or 'second'
"             descriptor  - describe type of item, e.g. 'entry
"                           item' (defaults to 'list item')
"             insert_mode - (optional) [1=goto insert mode on exit]
" Returns:    NONE
if !exists( "*s:Dbn_InsertListItem" )
function s:Dbn_InsertListItem( item_number, descriptor, ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	let l:item_number = a:item_number
	if l:item_number != ""
		let l:item_number = l:item_number . " "
	endif
	let l:descriptor = a:descriptor
	if l:descriptor == ""
		let l:descriptor = "list item"
	endif
	" get list item
	let l:item = s:Dbn__GetInput(
				\ 	"Enter " . l:item_number . l:descriptor . ": ",
				\ 	""
				\ )
	if l:item != ""
		" create element skeleton
		silent execute "normal O<listitem>><para>"
		" enter item
		call s:Dbn__InsertString( l:item, 0 )
		silent execute "normal 2j"
		" position cursor and enter insert mode
		call s:Dbn__StartInsert( 1 )
	endif
	" redraw screen
	execute "redraw!"
	" position cursor and enter insert mode
	if a:0 > 0 && a:1 == 1 | call s:Dbn__StartInsert( 1 ) | endif
	" return exit status
	if l:item == "" | return 0 | else | return 1 | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertVarListEntry                                 {{{2
" Purpose:    Insert variable list entry
" Parameters: item_number - (optional) entry number, e.g. 'first' or 'second'
"             descriptor  - (optional) describe type of term, e.g. 'entry
"                                      item' (default)
" Returns:    NONE
if !exists( "*s:Dbn_InsertVarListEntry" )
function s:Dbn_InsertVarListEntry( item_number, descriptor )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	let l:item_number = a:item_number
	if l:item_number != ""
		let l:item_number = l:item_number . " "
	endif
	let l:descriptor = a:descriptor
	if l:descriptor == ""
		let l:descriptor = "entry term"
	endif
	" get list term
	let l:term = s:Dbn__GetInput(
				\ 	"Enter " . l:item_number . l:descriptor . ": ",
				\ 	""
				\ )
	let l:retval = 0
	if l:term != ""
		" create initial element skeleton
		silent execute "normal O<varlistentry>><term>"
		" enter list term
		call s:Dbn__InsertString( l:term, 0 )
		silent execute "normal j"
		" add listitem
		let l:item_added = s:Dbn_InsertListItem(
					\ 	a:item_number,
					\ 	"entry item"
					\ )
		" if no list item added, undo changes
		if l:item_added | let l:retval = 1 | silent execute "normal j"
		else            | undo
		endif
	endif
	" redraw screen
	execute "redraw!"
	" enter insert mode
	call s:Dbn__StartInsert( 1 )
	" exit with status
	return l:retval
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertTable                                        {{{2
" Purpose:    Insert table skeleton
" Parameters: type        - table type (formal|informal)
" Returns:    NONE
if !exists( "*s:Dbn_InsertTable" )
function s:Dbn_InsertTable( type )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" set type
	let l:type = a:type
	if l:type != "formal" && l:type != "informal"
		let l:choice = confirm(
					\ 	"Select table type: ",
					\ 	"&Formal\n&Informal",
					\ 	1,
					\	"Question"
					\ )
		if     l:choice == 1    | let l:type = "formal"
		elseif l:choice == 2    | let l:type = "informal"
		else                    | return
		endif
	endif
	" set title and titleabbrev
	if l:type == "formal"
		let l:title = s:Dbn__GetInput( "Enter table title: ", "" )
		if l:title == ""
			call s:Dbn__StartInsert( 1 )
			return
		endif
		let l:titleabbrev = s:Dbn__GetInput(
					\ 	"Enter title abbreviation (highly recommended): ",
					\ 	l:title
					\ )
	else | let l:title = "" | let l:titleabbrev = "" | endif
	" set label
	let l:default = ( l:titleabbrev == "" ) ? l:title : l:titleabbrev
	let l:label = s:Dbn__GetLabel(
				\	"Enter table label: ",
				\	"tbl:",
				\	l:default
				\ )
	if l:label == "" | call s:Dbn__StartInsert( 1 ) | return | endif
	" set columns
	let l:columns = ""
	while !s:Dbn__ValidPositiveInteger( l:columns )
		let l:columns = s:Dbn__GetInput(
					\ 	"Enter number of columns: ",
					\ 	l:columns
					\ )
	endwhile
	" set rows
	let l:rows = ""
	while !s:Dbn__ValidPositiveInteger( l:rows )
		let l:rows = s:Dbn__GetInput( "Enter number of rows: ", l:rows )
	endwhile
	" set help
	let l:choice = confirm(
				\	"Add help comments? ",
				\	"&Yes\n&No",
				\	1,
				\	"Question"
				\ )
	if     l:choice == 1  | let l:show_help = 1
	elseif l:choice == 2  | let l:show_help = 0
	else                  | return
	endif
	" call table insertion engine
	call s:Dbn__InsertTableEngine(
				\ 	l:type,
				\ 	l:title,
				\ 	l:titleabbrev,
				\ 	l:label,
				\ 	l:columns,
				\ 	l:rows,
				\ 	l:show_help
				\ )
	" redraw screen
	execute "redraw!"
	" position cursor and enter insert mode
	call s:Dbn__StartInsert( 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertIndexTermInsertMode                          {{{2
" Purpose:    Insert index item in insert mode
" Parameters: NONE
" Returns:    NONE
if !exists( "*s:Dbn_InsertIndexTermInsertMode" )
function s:Dbn_InsertIndexTermInsertMode()
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	try
		" get entry type
		let l:msg = "Select index entry type: "
		let l:choice = confirm( l:msg, "&Simple\n&Zone", 1, "Question" )
		if l:choice == 1     | let l:entry_type = 'simple'
		elseif l:choice == 2 | let l:entry_type = 'zone'
		else                 | return |	endif
		" if user is indexing an element ('zone'), get element id
		if l:entry_type == 'zone'  " zone
			let l:zone_link = s:Dbn__ChooseLinkableElement(
						\ 'You must choose the element (id) to index.' )
			if l:zone_link == "" | return | endif
		endif
		" generate body of index item ('primary'..'tertiary', 'see(also)')
		let l:index_item = s:Dbn__BuildIndexTerm( expand( "<cword>" ) )
		if l:index_item == '' | return | endif
		" determine significance level of index item
		let l:index_item_start_tag = ( s:Dbn__IndexItemPreferred() )
					\ ? '<indexterm significance="preferred"' : '<indexterm'
		" if indexing an element ('zone'), must reference associated element
		if l:entry_type == 'zone'  " zone
			let l:index_item_start_tag = l:index_item_start_tag
						\ . ' zone="' . l:zone_link . '"'
		endif
		" finish with start tag
		let l:index_item_start_tag = l:index_item_start_tag . '>'
		" finish building index term
		let l:index_item = l:index_item_start_tag
					\ . l:index_item . '</indexterm>'
		" insert it
		call s:Dbn__InsertString( l:index_item, 1 )
		" warn user if no index element
		let l:line = line( "." ) | let l:coln = col( "." )
		let l:msg = 'There is no <index/> element in this document.'
					\ . "\n" . 'Without it no index will be generated.'
		if !search( '<index\/\?>', 'w' )
			call s:Dbn__ShowMsg( l:msg, "Warning" )
		endif
		call cursor( l:line, l:coln )
	finally
		execute "redraw!"
		call s:Dbn__StartInsert( 1 )  " ensure finish in insert mode
	endtry
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertIndexTermVisualMode                          {{{2
" Purpose:    Insert index item in visual mode
" Parameters: selection - visual selection
" Returns:    NONE
if !exists( "*s:Dbn_InsertIndexTermVisualMode" )
function s:Dbn_InsertIndexTermVisualMode( selection )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	try
		" if abort operation need to know initial location
		let l:line = line( "." ) | let l:coln = col( "." )
		" get entry type
		let l:msg = "Select index entry type: "
		let l:choice = confirm( l:msg, "&Simple\nS&pan", 1, "Question" )
		if l:choice == 1     | let l:entry_type = 'simple'
		elseif l:choice == 2 | let l:entry_type = 'span'
		else                 | return
		endif
		" use selection as default term if 'simple' item, or
		" 'span' item with no newlines
		if match( a:selection, '\n' ) > -1  " contains newline
			let l:default = ''
		else
			let l:default = a:selection
			" remove newlines and entities
			let l:default = substitute( l:default, '\n', '', 'g' )
			let l:default = s:Dbn__StripEntities( l:default )
		endif
		" now build internals of main indexterm element
		let l:main_indexterm = s:Dbn__BuildIndexTerm( l:default )
		if l:main_indexterm == '' | throw 'No index term' | endif
		" if no default use primary index term as default
		if l:default == ''
			let l:default = matchstr( 
						\ 	l:main_indexterm, 
						\ 	'<primary>\p\{-}</primary>' 
						\ )
			let l:default = substitute( l:default, '</\?primary>', '', 'g' )
		endif
		" generate id if 'span' item
		let l:id = s:Dbn__GetLabel(
					\	"Enter label for index span: ",
					\	"ind:",
					\	l:default
					\ )
		if l:id == '' | throw 'No span id selected' | endif
		" build opening tag of main indexitem element
		let l:main_indexterm_start_tag = ( s:Dbn__IndexItemPreferred() )
					\ ? '<indexterm significance="preferred"' : '<indexterm'
		if l:entry_type == 'span'
			let l:main_indexterm_start_tag = l:main_indexterm_start_tag 
						\ . ' id="' . l:id . '" class="startofrange"'
		endif
		let l:main_indexterm_start_tag = l:main_indexterm_start_tag . '>'
		" now build entire main indexitem element
		let l:main_indexterm = l:main_indexterm_start_tag 
					\ . l:main_indexterm . '</indexterm>'
		" now assign elements to go before and after visual selection
		" if 'simple' item then main index element goes after
		" if 'span' item then main index element goes before (another after)
		if l:entry_type == 'simple'
			let l:before = ''
			let l:after = l:main_indexterm
		elseif l:entry_type == 'span'
			let l:before = l:main_indexterm
			let l:after = '<indexterm startref="' 
						\ . l:id . '" class="endofrange"/>'
		else | throw 'Logic error' | endif
		" now write selection with added elements
		call s:Dbn_SurroundSelection( a:selection, l:before, l:after )
	catch  " undo visual selection deletion
		undo
		call cursor( l:line, l:coln )
		silent! execute "normal h"
	finally
		" redraw screen
		execute "redraw!"
		" enter insert mode
		call s:Dbn__StartInsert( 1 )
	endtry
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertGlossaryTerm                                 {{{2
" Purpose:    Insert glossary term
" Parameters: glossterm - visually selected glossterm
" Returns:    NONE
if !exists( "*s:Dbn_InsertGlossaryTerm" )
function s:Dbn_InsertGlossaryTerm( glossterm )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	try
		" set some variables
		let l:abort = 0  " false
		let l:link_term = '' | let l:line = line( "." ) | let l:coln = col( "." )
		" check for glossary element -- if none, abort
		call cursor( 1, 1 )
		let l:gloss_start = search( '<glossary\p\{-}>', 'W' )
		call cursor( l:line, l:coln )
		if ! l:gloss_start
			call s:Dbn__ShowMsg( 
						\	"No <glossary> element found -- aborting.",
						\	"Error"
						\ )
			throw ''
		endif
		" ensure opening and closing glossary tags are not on same line
		call cursor( 1, 1 )
		let l:gloss_start = search( '<glossary\p\{-}>\p\{-}<\/glossary>', 'W' )
		call cursor( l:line, l:coln )
		if l:gloss_start
			let l:msg = "'glossary' element opening and closing\n"
						\ . 'tags must be on the same line -- aborting.'
			call s:Dbn__ShowMsg( l:msg, "Error" )
			throw ''
		endif
		" get glossary term if in insert mode (no supplied glossterm)
		if a:glossterm == ''
			let l:msg = 'Enter glossary term (leave blank to abort): '
			while 1
				let l:glossterm = s:Dbn__GetInput( l:msg, '' )
				if l:glossterm != '' && s:Dbn__GlossaryTermExists( l:glossterm )
					let l:msg = 'Error! That glossary term already '
								\ . 'has a glossentry.' . "\n"
								\ . 'Enter glossary term (leave blank to abort): '
				else | break | endif
			endwhile
		else | let l:glossterm = a:glossterm | endif
		if l:glossterm != ''
			" select glossary term to reference (or new)
			let l:msg = 'Choose glossary term to reference (or New Entry option):'
			let l:link_term = s:Dbn__SelectGlossaryTerm( l:msg, 1 )
			if l:link_term == '' || l:link_term == '::[New Entry]::'
				let l:link_term = '::[New Entry]::'
				" get refid
				let l:msg = 'Enter id for glossary entry (leave blank to abort): '
				while 1
					let l:id = 'glos:' . s:Dbn__Labelify( l:glossterm )
					let l:id = s:Dbn__GetInput( l:msg, l:id )
					if l:id != '' && s:Dbn__GlossentryIdExists( l:id )
						let l:msg = 'Error! That id already used by a glossentry.'
									\ . "\n" . 'Enter id for glossary entry '
									\ . '(leave blank to abort): '
					else | break | endif
				endwhile
				if l:id != ''
					" get glossentry 'sortas' attribute
					let l:msg = 'You can specify the sort value for this glossary '
								\ . 'term' . "\n"
								\ . '(if blank/unchanged use glossterm): '
					let l:sortas = s:Dbn__GetInput(
								\ 	l:msg,
								\ 	tolower( l:glossterm )
								\ )
					if l:sortas == tolower( l:glossterm ) | let l:sortas = '' | endif
					" get glossterm 'baseform' attribute
					let l:msg = 'You can specify a basic form of this term '
								\ . 'to use for indexing, collating, etc.' . "\n"
								\ . '(if blank/unchanged use glossterm)' . "\n"
								\ . 'Example: term="racing", baseform="race"): '
					let l:baseform = s:Dbn__GetInput(
								\ 	l:msg,
								\ 	tolower( l:glossterm )
								\ )
					if l:baseform == tolower( l:glossterm )
						let l:baseform = ''
					endif
					" get acronym
					let l:msg = 'You can specify an acronym for this glossterm.'
								\ . "\n"
								\ . '(leave blank if none): '
					let l:acronym = s:Dbn__GetInput( l:msg, '' )
					" get abbrev
					let l:msg = 'You can specify an abbreviation for this glossterm.'
								\ . "\n"
								\ . '(leave blank if none): '
					let l:abbrevn = s:Dbn__GetInput( l:msg, '' )
					" can either have glossdef&glossseealso+ or glosssee
					let l:glosssee = ''
					" try for glossdef first
					let l:msg = 'Enter glossary definition '
								\ . '(blank for abort or glosssee): '
					let l:glossdef = s:Dbn__GetInput( l:msg, '' )
					if l:glossdef == ''
						let l:msg = 'Do you want to abort or '
									\ . 'make a "glosssee" entry? '
						let l:choice = confirm(
									\	l:msg,
									\	"&Abort\n&Glosssee",
									\	1,
									\	"Question"
									\ )
						if l:choice == 2
							let l:msg = 'Select glossary term to See '
										\ . '(blank for abort): '
							let l:glosssee = s:Dbn__SelectGlossaryTerm(
										\ 	l:msg, 0 )
						endif
					endif
					if l:glossdef == '' && l:glosssee == ''
						let l:abort == 1
					endif
				else | let l:abort = 1
				endif  " l:id != ''
			endif  " l:link_term == '' or '::[New Entry]::'
		else | let l:abort = 1
		endif  " l:glossterm != ''
		if ! l:abort  " write to document
			" now ready to write to document
			" first: text body glossterm
			let l:open_tag = ( l:link_term == '::[New Entry]::' ) 
						\ ? l:id 
						\ : l:link_term
			let l:open_tag = '<glossterm linkend="' . l:open_tag . '">'
			if a:glossterm == ''  " insert mode
				let l:insert_string = l:open_tag . l:glossterm . '</glossterm>'
				call s:Dbn__InsertString( l:insert_string, 1 )
			else  " visual mode
				call s:Dbn_SurroundSelection(
							\ 	l:glossterm,
							\ 	l:open_tag,
							\ 	'</glossterm>'
							\ )
			endif
			" now, add new glossentry if required
			if l:link_term == '::[New Entry]::'
				" goto insertion point
				call s:Dbn__GotoGlossentryInsertionPoint( l:glossterm )
				" insert: glossentry open tag
				let l:string = '<glossentry'
				if l:sortas != ''
					let l:string = l:string . ' sortas=,"' . l:sortas . ',"'
				endif
				let l:string = l:string . ' id=,"' . l:id . ',">>'
				call s:Dbn__InsertString( l:string, 0 )
				" insert: glossterm
				let l:string = '<glossterm'
				if l:baseform != ''
					let l:string = l:string
								\ . ' baseform=,"' . l:baseform . ',"'
				endif
				let l:string = l:string
							\ . ' linkend=,"' . l:id . ',">' . l:glossterm
				call s:Dbn__InsertString( l:string, 0 )
				silent! execute "normal o"
				" insert: acronym
				if l:acronym != ''
					let l:string = '<acronym>' . l:acronym
					call s:Dbn__InsertString( l:string, 0 )
					silent! execute "normal o"
				endif
				" insert: abbrev
				if l:abbrevn != ''
					let l:string = '<abbrev>' . l:abbrevn
					call s:Dbn__InsertString( l:string, 0 )
					silent! execute "normal o"
				endif
				" either glossdef or glosssee
				if l:glossdef != ''
					" glossdef element
					" first: glossdef opening tag
					call s:Dbn__InsertString( '<glossdef>>', 0 )
					" next: glossdef element content
					let l:string = '<para>' . l:glossdef
					call s:Dbn__InsertString( l:string, 0 )
					" can have multiple glossseealso terms
					let l:msg = 'Do you wish to enter any glossseealso terms? '
					let l:choice = confirm( l:msg,
								\	"&Yes\n&No",
								\	2,
								\	"Question"
								\ )
					if l:choice == 1
						" yes: add glossseealso term(s)
						while 1
							let l:msg = 'Select glossary term to See Also '
										\ . '([Cancel] when done): '
							let l:otherterm = ''
							let l:otherterm = s:Dbn__SelectGlossaryTerm(
										\ 	l:msg, 0 )
							if l:otherterm == '' | break
							else
								let l:string = '<glossseealso otherterm=,"'
											\ . l:otherterm . ',"/>'
								silent! execute "normal o"
								call s:Dbn__InsertString( l:string, 0 )
							endif
						endwhile
					endif  " enter glossseealso terms
				else  " glosssee element
					let l:string = '<glosssee otherterm=,"'
								\ . l:glosssee . ',"/>'
					call s:Dbn__InsertString( l:string, 0 )
				endif  " enter glossdef|glosssee term
			endif  " enter glossary glossentry term
			" position cursor and set mode
			" - am unable to find a way to end in normal mode
			"   if started in visual mode
			call cursor( l:line, l:coln )
			silent! execute "normal 2l%f>"
			call s:Dbn__StartInsert( 1 )
		else  " aborted document write
			throw ''
		endif  " write to document
	catch
		" need to undo deletion if in visual mode
		if a:glossterm != '' | undo | endif
		" position cursor
		" - am unable to find a way to end in normal mode
		"   if started in visual mode
		call cursor( l:line, l:coln )
		call s:Dbn__StartInsert(
					\ 	( a:glossterm == '' ) ? 1 : 0
					\ )
	endtry
	" redraw screen
	execute "redraw!"
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_InsertCitation                                     {{{2
" Purpose:    Get and insert 'citation' docbook element at cursor location
" Parameters: original - indicates whether original function call
" Returns:    NONE
" Requires:   external file: 'dbn-getcitekeys'
if !exists( "*s:Dbn_InsertCitation" )
function s:Dbn_InsertCitation( original )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" get citekeys
	let l:citekeys = s:Dbn__GetCitekeys()
	" proceed if valid citekey(s) selected
	if l:citekeys != "" && l:citekeys != ":ERROR:"
		" determine citation style
		let l:choice = confirm( 
					\ 	"Select citation style: ",
					\ 	"A&uthor Year\n&Author only\n&Year only",
					\ 	1,
					\	"Question"
					\ )
		if l:choice >= 1 && choice <= 3
			if     l:choice == 2 | let l:citekeys = "A:" . l:citekeys
			elseif l:choice == 3 | let l:citekeys = "Y:" . l:citekeys
			endif
			" insert entity
			let l:entity = s:Dbn__BuildXmlEntity(
						\ 	"citation",
						\ 	"role=\"REFDB\"",
						\ 	l:citekeys
						\ )
			call s:Dbn__InsertString( l:entity, 1 )
		endif
	elseif l:citekeys == ":ERROR:"  " Can be caused by menu failure
		echo "WARNING: Error occurred during menu selection!"
		call s:Dbn_InsertCitation( 0 )
	endif
	" redraw screen
	execute "redraw!"
	" position cursor and enter insert mode if original function
	if a:original | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_ShowHelpFile                                       {{{2
" Purpose:    Displays help file
" Parameters: mode - (optional) mode function called from ('i'|other)
" Returns:    NONE
" Requires:   enscript
"             ImageMagick (the 'display' utility)
"             postscript font 'Courier 10'
if !exists( "*s:Dbn_ShowHelpFile" )
function s:Dbn_ShowHelpFile( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" test for needed utilities
	if s:Dbn__UtilityMissing( "groff" ) || s:Dbn__UtilityMissing( "grops" )
		let l:msg = "Unable to locate 'groff' and/or 'grops' "
					\ . "utilities.\n"
					\ . "Aborting."
		call s:Dbn__ShowMsg( l:msg, "Error" ) | return
	endif
	if s:Dbn__UtilityMissing( "display" )
		let l:msg = "Cannot locate 'display' utility.\n"
					\ . "It is part of the ImageMagick suite.\n"
					\ . "Aborting."
		call s:Dbn__ShowMsg( l:msg, "Error" ) | return
	endif
	" proceed if help filepath valid
	if filereadable( s:helpfile )
		" groff options: -dmode=help  = set var 'mode' to 'help'
		"                               (causes additional output),
		"                -drefdb=yes  = set var 'refdb' to 'yes'
		"                               (causes additional output),
		"                -t           = invoke 'tbl' preprocessor,
		"                -m me        = invoke 'me' preprocessor,
		"                -m ms        = invoke 'ms' preprocessor,
		"                -P-pa4       = pass papersize parameter ('-pa4')
		"                               tp 'ps' postprocessor ('grops')
		"                -Tps         = postscript output (use 'grops')
		let l:cmd = "groff "
		if s:use_refdb | let l:cmd = l:cmd . "-drefdb=yes " | endif
		let l:cmd = l:cmd
					\ . "-dmode=help "
					\ . "-t "
					\ . "-m me "
					\ . "-m ms "
					\ . "-P-pa4 "
					\ . "-Tps "
					\ . s:helpfile
					\ . " | display &"
		call system( l:cmd )
		if v:shell_error  " error displaying help file
			let l:msg = "Error occurred during help file display.\n"
						\ . "The shell command was:\n"
						\ . "'" . l:cmd . "'"
			call s:Dbn__ShowMsg( l:msg, "Error" )
		endif
	else  " help file was unreadable
		let l:msg = "Unable to locate help file:\n"
					\ . "'" . s:helpfile . "'"
		call s:Dbn__ShowMsg( l:msg, "Error" )
	endif
	" redraw screen
	execute "redraw!"
	" enter insert mode if that was original mode
	if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_GetElementHelp                                     {{{2
" Purpose:    Find element and invoke help
" Parameters: direction  - indicates which way to search (forward|back)
"             mode       - (optional) mode function was called from 
"                          ['i'|other]
" Returns:    NONE
if !exists( "*s:Dbn_GetElementHelp" )
function s:Dbn_GetElementHelp( direction, ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" check parameter
	if     a:direction == "forward" | let l:flags = "W"
	elseif a:direction == "back"    | let l:flags = "bW"
	else                            | return
	endif
	" set marker
	silent execute "normal mz"
	" move to match
	let l:search_result = search( "<[^/]", l:flags )
	" if found match, invoke help and return to original position
	if l:search_result > 0
		let l:element = expand( "<cword>" )
		call s:Dbn_ShowElementHelp( l:element )		
		call cursor( line( "'z" ), col( "'z" ) )
	else
		call s:Dbn__ShowMsg( "Unable to find an xml element.", "Error" )
	endif
	if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_ShowElementHelp                                    {{{2
" Purpose:    Display help for element
" Parameters: NONE
" Returns:    NONE
" Requires:   local copy of DocBook: The Definitive Guide
"             - the 'dbtdg_root' directory
if !exists( "*s:Dbn_ShowElementHelp" )
function s:Dbn_ShowElementHelp( element )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" set variables
	let l:viewer = s:viewer_html_x
	let l:viewer_arg_pre_url = ""
	let l:viewer_arg_post_url = ""
	let l:element = tolower( a:element )
	let l:tail = ".element.html"
	let l:filename = s:dbtdg_root
				\ . l:element
				\ . l:tail
	" proceed if helpfile exists
	if filereadable( l:filename )
		let l:cmd = l:viewer
					\ . " "
					\ . l:viewer_arg_pre_url
					\ . " "
					\ . "file://"
					\ . l:filename
					\ . " "
					\ . l:viewer_arg_post_url
		call system( l:cmd )
		if v:shell_error
			let l:msg = "Unable to successfully display "
						\ . "help page in viewer.\n"
						\ . "This is the command that failed:\n"
						\ . "'" . l:cmd . "'."
			call s:Dbn__ShowMsg( l:msg, "Error" )
		else
			let l:msg = "Help for element '"
						\ . l:element
						\ . "' has been displayed in " 
						\ . s:viewer_html_x_name
						\ . "."
			call s:Dbn__ShowMsg( l:msg, "Info" )
		endif
	else
		let l:msg = "Unable to find help page:\n"
					\ . "'" . l:filename . "'."
		call s:Dbn__ShowMsg( l:msg, "Error" )
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_ShowOutline                                        {{{2
" Purpose:    Show schematic outline of document
" Parameters: mode - (optional) mode function was called from ['i'|other]
" Returns:    NONE
" Requires:   groff, display
" Assumes:    valid xml file
if !exists( "*s:Dbn_ShowOutline" )
function s:Dbn_ShowOutline( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" test for needed utilities
	if s:Dbn__UtilityMissing( "groff" ) || s:Dbn__UtilityMissing( "grops" )
		let l:msg = "Unable to locate 'groff' and/or 'grops' utilities.\n"
					\ . "Aborting."
		call s:Dbn__ShowMsg( l:msg, "Error" ) | return
	endif
	if s:Dbn__UtilityMissing( "display" )
		let l:msg = "Cannot locate 'display' utility.\n"
					\ . "It is part of the ImageMagick suite.\n"
					\ . "Aborting."
		call s:Dbn__ShowMsg( l:msg, "Error" ) | return
	endif
	" remember initial location and move to top of file
	let l:orig_line = line( '.' ) | let l:orig_col = col( '.' ) | call cursor( 1, 1 )
	" set some variables (0=false)
	let l:exit_flag = 0         | let l:done_first_pass = 0 | let l:awaiting_title = 1
	let l:previous_element = '' | let l:previous_id = ''    | let l:title = ''
	let l:output = '.ps 20' . "\n" 
				\ . '\fB' . expand( '%' ) . '\fP' 
				\ . ' structure' . "\n"
				\ . '.ps 12' 
				\. "\n\n"
	" check file validity
	silent! execute "update"
	if !s:Dbn_ValidateXml( 0 )
		let l:output = l:output 
					\ . '\fBWarning:\fP File is not valid xml.' . "\n" 
					\ . 'This may result in errors.' . "\n\n"
	endif
	if mode() == "i" | execute "normal \<Esc>" | endif
	" now loop through file searching for opening tags
	while ! l:exit_flag
		let l:exit_flag = !
					\ search( '<[^!]\/\?\(\p\{-}\)>', 'W' )
		"                      <                    match '<'
		"                       [^!]                not followed by '!'
		"                                             (exclude comments, etc.)
		"                           \/\?            optionally followed by '/'
	    "                                 \p\{-}    followed by shortest group
		"                                             of printable characters
	    "                                         > followed by '>'
		" mark current position
		let l:cur_line = line( '.' ) | let l:cur_col = col( '.' )
		" get current element
		let l:element = tolower( expand( '<cword>' ) )
		" find last line so don't decrement when we get there
		if ! l:done_first_pass
			let l:last_line = searchpair( 
						\ 	'<' . l:element . '>',
						\ 	'',
						\ 	'</' . l:element . '>'
						\ )
			silent! call cursor( l:cur_line, l:cur_col )
		endif
		" only process if sectioning element or title element
		if l:element =~ '\<set\>\|\<book\>\|\<article\>\|\<dedication\>\|\<preface\>'||
					\ l:element =~ '\<part\>\|\<chapter\>\|\<sect1\>\|\<sect2\>'||
					\ l:element =~ '\<sect3\>\|\<sect4\>\|\<sect5\>\|\<section\>' ||
					\ l:element =~ '\<simplesect\>\|\<appendix\>\|\<colophon\>' ||
					\ l:element =~ '\<title\>\|\<figure\>\|\<table\>' ||
					\ l:element =~ '\<sidebar\>\|\<example\>' ||
					\ l:exit_flag
			" get tag fragment from '<' to next space or '>'
			" use for testing whether opening or closing tag
			" idea is to avoid capturing attribute values in case they
			"   contain a '/' -- we'll use that to identify closing tags
			silent! execute 'normal mz' | call search( ' \|>', 'W' )
			silent! execute 'normal v`z"zy'
			let l:tag_fragment = @z
			" if sectioning element (or last loop iteration)
			if l:exit_flag || l:element != 'title'
				" write previous sectioning element
				" no output for first iteration
				if l:done_first_pass && l:previous_element != ''
					let l:output = l:output . l:previous_element
					if l:title != ''
						let l:output = l:output 
									\ . ': (\,\fItitle\/\fP)\ \ ' 
									\ . '\fB' . l:title . '\fP'
					elseif l:previous_id != ''
						let l:output = l:output 
									\ . ': (\,\fIid\/\fP)\ \ ' 
									\ . '\fB' . l:previous_id . '\fP'
					else
						let l:output = l:output 
									\ . ': (\,\fINo title or id\/\fP)'
					endif
					let l:output = l:output . "\n"
					let l:awaiting_title = 1
				endif
				let l:title = '' | let l:previous_id = '' | let l:previous_element = ''
				" next actions depend on whether opening or closing tag 
				if ! l:exit_flag
					if l:tag_fragment !~ '.*\/.*'  " no contain '/' (open tag)
						let l:previous_element = l:element
						" extract id (need to get full tag)
						silent! execute 'normal vf>\"zy' | let l:tag_full = @z
						let l:previous_id = s:Dbn__ExtractElementAttribute(
									\ l:tag_full, 'id' )
						" increment output
						if l:done_first_pass
							let l:output = l:output . ".RS\n"
						endif
						let l:done_first_pass = 1
					else  " (close tag)
						" decrement output
						if line( "." ) != l:last_line
							let l:output = l:output . ".RE\n"
						endif
					endif
				endif
			else  " element == title
				" only process opening tags
				if l:tag_fragment !~ '.*\/.*'  " no contain '/' (open tag)
					" only get first title after sectioning element
					if l:awaiting_title
						" extract title
						silent! execute 'normal mz'
						let l:target = '</' . l:element . '>'
						silent! call search( l:target, 'W' )    | call search( '>', 'W' )
						silent! execute 'normal v`z"zy' | let l:title_full = @z
						" remove elements and entities
						let l:title = s:Dbn__StripElements( l:title_full )
						let l:title = s:Dbn__StripEntities( l:title )
						" this may result in double spaces, so remove them
						let l:title = substitute( l:title, ' \{1,}', ' ', 'g' )
						" set title flag
						let l:awaiting_title = 0
					endif
				endif
			endif			
		endif
	endwhile
	" return to start point
	silent! call cursor( l:orig_line, l:orig_col )
	" output to file
	let l:file_name = tempname()
	silent! execute 'new'                   | call s:Dbn__InsertString( l:output, 1 )
	silent! execute 'write! ' . l:file_name | silent! execute 'close!'
	" for some reason appending an '&' to the following command
	" causes it to fail
	let l:cmd = 'groff '
				\ . '-m ms '
				\ . '-P-pa4 '
				\ . '-Tps '
				\ . l:file_name
				\ . ' | display'
	silent! call system( l:cmd ) | call delete( l:file_name )
	if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_JumpToId                                           {{{2
" Purpose:    Select and jump to element (by id)
" Parameters: mode - (optional) mode function was called from ['i'|other]
" Returns:    NONE
if !exists( "*s:Dbn_JumpToId" )
function s:Dbn_JumpToId( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" save file to get recent linkable elements
	silent execute "update"
	let l:link = s:Dbn__ChooseLinkableElement(
				\ 'Choose element to jump to (by id).' )
	if l:link != ""
		" jump to line
		let l:target = "<\\p\\{-}id=\"" . l:link . "\"\\p\\{-}>"
		let l:search_result = search( l:target, 'w' )
		if l:search_result == 0
			call s:Dbn__ShowMsg( 
						\	"Unable to find specified element id.", 
						\	'Error' 
						\ )
		endif
	endif
	" go to insert mode if necessary
	if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_ChangeRefdbDb                                      {{{2
" Purpose:    Change default RefDB database (in $HOME/.refdbcrc and Makefile)
" Parameters: mode - (optional) mode function was called from ['i'|other]
" Returns:    NONE
if !exists( "*s:Dbn_ChangeRefdbDb" )
function s:Dbn_ChangeRefdbDb( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" check for refdb access
	if !s:Dbn__RefdbOk()
		call s:Dbn__ShowMsg( "RefDB unavailable -- aborting", "Error" )
		return
	endif
	" get list of dbs and check for refdb access
	let l:full_db_list = s:Dbn__GetFullRefdbDbList()
	if l:full_db_list == ""
		let l:msg = "Unable to retrieve any database names "
					\ . "using refdba/listdb\n"
					\ . "Aborting."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	" determine status of makefile and initfile
	let l:makefile = s:Dbn__StripLastChar( system( "pwd" ) ) . "/Makefile"
	let l:makefile_exists = filereadable( l:makefile ) ? 1 : 0
	let l:makefile_db = s:Dbn__GetDefaultRefdbDb( l:makefile, "makefile" )
	let l:makefile_default = l:makefile_db == "" ? 0 : 1
	let l:initfile = s:Dbn__StripLastChar( system( "echo ~" ) ) . "/.refdbcrc"
	let l:initfile_exists = filereadable( l:initfile ) ? 1 : 0
	let l:initfile_db = s:Dbn__GetDefaultRefdbDb( l:initfile, "initfile" )
	let l:initfile_default = l:initfile_db == "" ? 0 : 1
	" provide summary to user
	let l:msg = "The RefDB default reference database can be set in a local\n"
				\ . "makefile or a global configuration (init) file.\n"
				\ . "For most output tools the makefile default will\n"
				\ . "override the global default.\n\nLocal makefile "
				\ . ( 
				\     l:makefile_exists 
				\     ? "[" . l:makefile . "]: Default " 
				\     : "not detected."
				\   )
	if l:makefile_exists
		let l:msg = l:msg 
					\ . (
					\     l:makefile_default 
					\     ? "is '" . l:makefile_db . "'." 
					\     : "not set."
					\   )
	endif
	let l:msg = l:msg . "\nUser global init file "
				\ . ( 
				\     l:initfile_exists 
				\     ? "[" . l:initfile . "]: Default " 
				\     : "not detected."
				\   )
	if l:initfile_exists
		let l:msg = l:msg 
					\ . ( 
					\     l:initfile_default 
					\     ? "is '" . l:initfile_db . "'." 
					\     : "not set."
					\   )
	endif
	call s:Dbn__ShowMsg( l:msg, "Info" )
	" now deal with makefile and init file
	" 1. makefile
	if l:makefile_exists
		if l:makefile_default  " change existing default
			let l:msg = "Change makefile default db [" . l:makefile_db . "]?"
			let l:choice = confirm( l:msg, "&Yes\n&No", 2, "Question" )
			if l:choice == 1
				" select new db
				let l:new_db = s:Dbn__GetNewRefdbDb( l:full_db_list, l:msg,
							\ l:makefile_db )
				if l:new_db == "" | return | endif  " error selecting new db
				" change makefile
				let l:retval = s:Dbn__ChangeDefaultRefdbDb( l:makefile,
							\ "makefile", l:makefile_db, l:new_db )
			endif
		else  " add default
			let l:msg = "Add default database to makefile?"
			let l:choice = confirm( l:msg, "&Yes\n&No", 2, "Question" )
			if l:choice == 1
				" select new db
				let l:new_db = s:Dbn__GetNewRefdbDb( l:full_db_list, 
							\ l:msg, '' )
				if l:new_db == "" | return | endif  " error selecting new db
				" change makefile
				let l:retval = s:Dbn__AddDefaultRefdbDb( l:makefile, 
							\ "makefile", l:new_db )
				if ! l:retval | return | endif
			endif
		endif
	endif
	" 2. init file
	if l:initfile_exists
		if l:initfile_default  " change existing default
			let l:msg = "Change user global default db [" 
						\ . l:initfile_db . "]?"
			let l:choice = confirm( l:msg, "&Yes\n&No", 2, "Question" )
			if l:choice == 1
				" select new db
				let l:new_db = s:Dbn__GetNewRefdbDb( l:full_db_list, l:msg,
							\ l:initfile_db )
				if l:new_db == "" | return | endif  " error selecting new db
				" change initfile
				let l:retval = s:Dbn__ChangeDefaultRefdbDb( l:initfile,
							\ "initfile", l:initfile_db, l:new_db )
			endif
		else  " add default
			let l:msg = "Add default database to global config file?"
			let l:choice = confirm( l:msg, "&Yes\n&No", 2, "Question" )
			if l:choice == 1
				" select new db
				let l:new_db = s:Dbn__GetNewRefdbDb( l:full_db_list, 
							\ l:msg, '' )
				if l:new_db == "" | return | endif  " error selecting new db
				" change initfile
				let l:retval = s:Dbn__AddDefaultRefdbDb( l:initfile, 
							\ "initfile", l:new_db )
				if ! l:retval | return | endif
			endif
		endif
	endif
	" redraw screen
	execute "redraw!"
	" if called from insert mode, return to it
	if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_Showrefs                                           {{{2
" Purpose:    Show references from default RefDB database
" Parameters: mode - (optional) function called from ['i'|other]
" Returns:    NONE
if !exists( "*s:Dbn_Showrefs" )
function s:Dbn_Showrefs( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" check for refdb access
	if !s:Dbn__RefdbOk()
		call s:Dbn__ShowMsg( "RefDB unavailable -- aborting", "Error" )
		return 0
	endif
	" get db
	let l:db = s:Dbn__GetCurrentRefdbDb()
	if l:db == "" | return 0 | endif  " error displayed by previous fn
	" set variables
	let l:format = "html"
	let l:extension = "html"
	let l:host = hostname()
	let l:refs = "refs." . l:host . l:host . "." . l:extension
	let l:modal = s:Dbn__GetValue( "viewer_html_c_modal" )
	" build shell commands
	let l:cmd_header = "echo \"RefDB database: '" . l:db 
				\ . "'.\" > " . l:refs . " ; echo >> " . l:refs
	let l:cmd_extract = s:refdbc . " -C getref -d " . l:db . " -t " 
				\ . l:format . " -O " . l:refs 
				\ . s:Dbn__GetReferenceFilter( 'refdb' )
	let l:cmd_get_pid = "ps x | grep \"" . s:viewer_html_c 
				\ . "\" | grep -v \"grep\" | sed '1q' | "
				\ . "sed 's/^ *\\([0-9]*\\).*/\\1/'"
	let l:cmd_kill = "kill -s KILL "  " must add PID
	let l:cmd_showrefs = s:viewer_html_c . " " . getcwd() . "/" . l:refs
	if ! l:modal | let l:cmd_showrefs = l:cmd_showrefs . " &" | endif
	" extract references to file
	echo "Writing references to file..."
	call system( l:cmd_header )
	echo "------------------------------------------------------------"
	let l:feedback = system( l:cmd_extract )
	echo l:feedback
	echo "------------------------------------------------------------"
	" kill any existing display
	let l:pid = s:Dbn__StripLastChar( system( l:cmd_get_pid ) )
	if l:pid != ""
		echo "References are already being displayed [pid " . l:pid . "]."
		echo "Killing old reference list..."
		let l:cmd_kill = l:cmd_kill . l:pid
		let l:feedback = s:Dbn__StripLastChar( system( l:cmd_kill ) )
		echo l:feedback
	endif
	" display references file and exit
	" Note: error detection assumes any feedback from
	"       display command is an error
	echo "Displaying references..."
	let l:err_msg = s:Dbn__StripLastChar( system( l:cmd_showrefs ) )
	if ! l:modal | sleep 1 | endif
	if l:err_msg != ""
		let l:msg = "Error: The following display command\n" 
					\ . "  ['" . l:cmd_showrefs . "'].\n"
					\ . "failed with the message\n"
					\ . "  ['" . l:err_msg . "']."
		let l:err = delete( l:refs )
		if l:err != 0
			let l:msg = l:msg 
						\ . "\nError: Unable to delete temporary file ['" 
						\ . l:refs . "']."
		endif
		echo l:msg
	else | echo "References successfully displayed."
	endif
	" redraw screen
	execute "redraw!"
	" if called from insert mode, return to it
	if ( a:0 > 1 && a:1 == "i" ) | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_Killrefs                                           {{{2
" Purpose:    Terminate any display of RefDB databases
" Parameters: mode - (optional) mode function was called from ['i'|other]
" Returns:    NONE
if !exists( "*s:Dbn_Killrefs" )
function s:Dbn_Killrefs( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" set variables
	let l:extension = "html"
	let l:host = hostname()
	let l:refs = "refs." . l:host . l:host . "." . l:extension
	" build shell commands
	let l:cmd_get_pid = "ps x | grep \"" . s:viewer_html_c 
				\ . "\" | grep -v \"grep\" | sed '1q' | "
				\ . "sed 's/^ *\\([0-9]*\\).*/\\1/'"
	let l:cmd_kill = "kill -s KILL "  " must add PID
	" kill any existing display
	let l:pid = s:Dbn__StripLastChar( system( l:cmd_get_pid ) )
	if l:pid != ""
		echo "References are being displayed [pid " . l:pid . "]."
		echo "Killing old reference list..."
		let l:cmd_kill = l:cmd_kill . l:pid
		let l:feedback = s:Dbn__StripLastChar( system( l:cmd_kill ) )
		echo l:feedback
	endif
	" delete display file if present
	if filereadable( l:refs )
		echo "Deleting file [" . l:refs . "]..."
		let l:errval = delete( l:refs )
		if l:errval
			echo "Error: Unable to delete '" . l:refs . "'."
		endif
	else | echo "Couldn't find file [" . l:refs . "]."
	endif
	" redraw screen
	execute "redraw!"
	" if called from insert mode, return to it
	if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_Newref                                             {{{2
" Purpose:    Add reference to default RefDB database
" Requires:   Template file in 'NONE/share/vim-docbk-xml-refdb'
"             Template file name in certain format ('ris'|'risx')
" Parameters: mode - (optional) mode function was called from ['i'|other]
" Returns:    NONE
if !exists( "*s:Dbn_Newref" )
function s:Dbn_Newref( ... )
	" check for refdb access
	if !s:Dbn__RefdbOk()
		call s:Dbn__ShowMsg( "RefDB unavailable -- aborting", "Error" )
		return 0
	endif
	" get db
	let l:db = s:Dbn__GetCurrentRefdbDb()
	if l:db == "" | return 0 | endif  " error displayed by previous fn
	" set variables
	let l:format = "ris"
	let l:extension = "ris"
	let l:template = s:dbn_root
				\ . "/template-reference-"
				\ . l:format
				\ . "."
				\ . l:extension
	let l:workfile = s:Dbn__StripLastChar( system( "date -u +%s" ) ) 
				\ . "." . l:extension
	" build shell commands
	let l:cmd_copy_template = "cp " . l:template . " ./" . l:workfile
	let l:cmd_create_ref = s:editor . " " . l:workfile . " 2> /dev/null"
	let l:cmd_add_ref = s:refdbc . " -C addref -d " . l:db . " -t " 
				\ . l:format . " " . l:workfile
	" make copy of template
	let l:err = s:Dbn__StripLastChar( system( l:cmd_copy_template ) )
	if v:shell_error
		let l:msg = "Error: Unable to copy template file.\n"
					\ . "The shell command\n"
					\ . "  ['" . l:cmd_copy_template . "']\n"
					\ . "failed with the error message\n"
					\ . "  ['" . l:err . "']."
		echo l:msg
		return
	endif
	" create reference using template copy
	let l:err = s:Dbn__StripLastChar( system( l:cmd_create_ref ) )
	sleep 2
	if v:shell_error
		let l:msg = "Error: Unable to create reference.\n"
					\ . "The shell command\n"
					\ . "  ['" . l:l:cmd_create_ref . "']."
					\ . "failed with the error message\n"
					\ . "  ['" . l:err . "']."
		echo l:msg
		if filereadable( l:workfile ) | call delete( l:workfile ) | endif
	endif
	" upload reference and give feedback
	let l:msg = "Upload reference (must have saved changes)?"
	let l:choice = s:Dbn__ConsoleConfirm( l:msg )
	if l:choice == "y"
		let l:feedback = s:Dbn__StripLastChar( system( l:cmd_add_ref ) )
		echo l:feedback
		if v:shell_error | let l:msg = "Error: Failed to add reference."
		else
			if s:use_cache | call s:Dbn__CacheDb( 1 ) | endif  " re-cache
			let l:msg = "Reference added successfully."
		endif
		echo l:msg
		call s:Dbn__ConsoleProceed()
	endif
	" cleanup temporary file
	if filereadable( l:workfile ) | call delete( l:workfile ) | endif
	" redraw screen
	execute "redraw!"
	" if called from insert mode, return to it
	if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_Edref                                              {{{2
" Purpose:    Edit reference in default RefDB database
" Requires:   Shell variable 'DBN_ROOT'
"             Template file in '${DBN_ROOT}/templates'
"             Template file name in certain format (see code)
" Parameters: mode - (optional) mode function was called from ['i'|other]
" Returns:    NONE
if !exists( "*s:Dbn_Edref" )
function s:Dbn_Edref( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" check for refdb access
	if !s:Dbn__RefdbOk()
		call s:Dbn__ShowMsg( "RefDB unavailable -- aborting", "Error" )
		return 0
	endif
	" get db
	let l:db = s:Dbn__GetCurrentRefdbDb()
	if l:db == '' | return 0 | endif
	" get refid to edit
	let l:refid = s:Dbn__GetRefIds( 'edit', l:db )
	if l:refid == '' | return | endif  " empty string if error
	" set variables
	let l:format = "ris"
	let l:extension = "ris"
	let l:host = hostname()
	let l:template = s:dbn_root . "/template-reference-" . l:format 
				\ . "." . l:extension
	let l:workfile = s:Dbn__StripLastChar( system( "date -u +%s" ) ) 
				\ . "." . l:extension
	let l:tmp_workfile = l:workfile . "." . l:host . l:host
	" build shell commands
	let l:cmd_extract = s:refdbc . " -C getref -d " . l:db . " -t " 
				\ . l:format . " -o " . l:workfile . " \":ID:="
				\ .l:refid . "\" &> /dev/null"
	let l:cmd_del_tag = "mv " . l:workfile . " " . l:tmp_workfile 
				\ . " && sed -e '$d' < " . l:tmp_workfile . " > " . l:workfile
	let l:cmd_add_tags = "for x in `awk '{ print $1 }' " . l:template 
				\ . "` ; do found=no ; for y in `awk '{ print $1 } ' " 
				\ . l:workfile . "` ; do [ \"${x}\" = \"${y}\" ] && " 
				\ . "found=yes ; done ; if [ \"${found}\" = \"no\" ] ; " 
				\ . "then echo \"${x}  - \" >> " . l:workfile 
				\ . " ; fi ; done"
	let l:cmd_edit_ref = s:editor . " " . l:workfile . " 2> /dev/null"
	let l:cmd_update = s:refdbc . " -C updateref -d " . l:db . " -t " 
				\ . l:format . " " . l:workfile
	" extract reference
	call system( l:cmd_extract )
	if v:shell_error
		echo "Error: Unable to extract reference " . l:refid 
					\ . " from database '" . l:db . "'."
		if filereadable( l:workfile ) | call delete( l:workfile ) | endif
		return
	endif
	" remove last (end) tag
	call system( l:cmd_del_tag )
	if v:shell_error
		echo "Error occurred while modifying extracted reference."
		if filereadable( l:workfile ) | call delete( l:workfile ) | endif
		if filereadable( l:tmp_workfile )
			call delete( l:tmp_workfile )
		endif
		return
	endif
	let l:errval = delete( l:tmp_workfile )
	if l:errval
		echo "Error occurred while modifying extracted reference."
		if filereadable( l:workfile ) | call delete( l:workfile ) | endif
		if filereadable( l:tmp_workfile )
			call delete( l:tmp_workfile )
		endif
		return
	endif
	" add unused ris tags
	call system( l:cmd_add_tags )
	if v:shell_error
		echo "Error occurred while adding unused ris tags."
		if filereadable( l:workfile ) | call delete( l:workfile ) | endif
		return
	endif
	" edit reference
	echo "You can now edit the reference..."
	let l:err = s:Dbn__StripLastChar( system( l:cmd_edit_ref ) )
	sleep 2
	if v:shell_error
		let l:msg = "Error: Unable to edit reference.\n"
					\ . "The shell command\n"
					\ . "  ['" . l:l:cmd_create_ref . "']."
					\ . "failed with the error message\n"
					\ . "  ['" . l:err . "']."
		echo l:msg
		if filereadable( l:workfile ) | call delete( l:workfile ) | endif
	endif
	" upload reference and give feedback
	let l:msg = "Update reference (must have saved changes)?"
	let l:choice = s:Dbn__ConsoleConfirm( l:msg )
	if l:choice == "y"
		let l:feedback = s:Dbn__StripLastChar( system( l:cmd_update ) )
		echo l:feedback
		if v:shell_error | let l:msg = "Error: Failed to update reference."
		else
			if s:use_cache | call s:Dbn__CacheDb( 1 ) | endif  " re-cache
			let l:msg = "Reference updated successfully."
		endif
		echo l:msg
	endif
	" cleanup temporary file
	if filereadable( l:workfile ) | call delete( l:workfile ) | endif
	" redraw screen
	execute "redraw!"
	" if called from insert mode, return to it
	if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_Delref                                             {{{2
" Purpose:    Delete reference in default RefDB database
" Parameters: mode - (optional) mode function was called from ['i'|other]
" Returns:    NONE
if !exists( "*s:Dbn_Delref" )
function s:Dbn_Delref( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" check for refdb access
	if !s:Dbn__RefdbOk()
		call s:Dbn__ShowMsg( "RefDB unavailable -- aborting", "Error" )
		return 0
	endif
	" get db
	let l:db = s:Dbn__GetCurrentRefdbDb( 1 )
	if l:db == '' | return 0 | endif  " error displayed by previous fn
	" get refids to delete
	let l:refids = s:Dbn__GetRefIds( 'delete', l:db )
	if l:refids == '' | return | endif  " empty string if error
	" build shell commands
	let l:cmd_delete = s:refdbc . " -C deleteref -d " . l:db . " " . l:refids
	" delete reference
	let l:references = ( s:Dbn__ListElementCount( l:refids ) == 1 )
				\ ? 'reference' 
				\ : 'references'
	echo "Deleting " . l:references . "..."
	let l:feedback = s:Dbn__StripLastChar( system( l:cmd_delete ) )
	" must parse feedback to determine success
	let l:cmd = "echo \"" . l:feedback . "\" | tail -n 1 | "
				\ . "cut -d ':' -f 2 | cut -d ' ' -f 1"
	let l:matches = system( l:cmd )
	if l:matches != s:Dbn__ListElementCount( l:refids )  " error!
		let l:cmd = "echo \"" . l:feedback . "\" | tail -n 1 | "
					\ . "cut -d ':' -f 3 | cut -d ' ' -f 1"
		let l:skipped = system( l:cmd )
		let l:cmd = "echo \"" . l:feedback . "\" | tail -n 1 | "
					\ . "cut -d ':' -f 4 | cut -d ' ' -f 1"
		let l:failed = system( l:cmd )
		let l:errors = l:failed + l:skipped
		let l:references = ( l:errors == 1 ) ? 'reference' : 'references'
		let l:msg = "Unable to delete " . l:errors . " " . l:references . "."
		call s:Dbn__ShowMsg( l:msg, 'Error' )
		if has( "gui_running" ) | echo 'Error: ' . l:msg | endif
		echo "Here is the raw feedback from RefDB:"
		echo "-------------------------------------------------------------"
		echo l:feedback
		echo "-------------------------------------------------------------"
	else
		let l:references = ( s:Dbn__ListElementCount( l:refids ) == 1 )
					\ ? 'Reference' 
					\ : 'References'
		let l:msg = l:references . " deleted successfully."
		echo l:msg
	endif
	if s:use_cache | call s:Dbn__CacheDb( 1 ) | endif  " re-cache
	call s:Dbn__ConsoleProceed()
	" redraw screen
	execute "redraw!"
	" if called from insert mode, return to it
	if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_MakefileStyle                                      {{{2
" Purpose:    Change default style (in local Makefile)
" Requires:   RefDB, Perl, sed, awk, tail, grep, tr
" Parameters: mode - (optional) mode function was called from ['i'|other]
" Returns:    NONE
if !exists( "*s:Dbn_MakefileStyle" )
function s:Dbn_MakefileStyle( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" check for refdb access
	if !s:Dbn__RefdbOk()
		call s:Dbn__ShowMsg( "RefDB unavailable -- aborting", "Error" )
		return
	endif
	" get local makefile
	let l:makefile = s:Dbn__StripLastChar( system( "pwd" ) ) . "/Makefile"
	if !filereadable( l:makefile )
		let l:msg = "Unable to locate local makefile:\n"
					\ . "'" . l:makefile . "'.\n"
					\ . "Aborting."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	" get current makefile style
	let l:cmd_get_makefile_style = "grep \"^[[:space:]]*stylename[[:space:]]"
				\ . "\\+\\=[[:space:]]\\+[[:alnum:]\._]\\+"
				\ . "[[:space:]]*$\" "
				\ . l:makefile
				\ . " | tail -n 1 | sed -e 's/	/ /g' | tr -s ' '"
				\ . " | sed -e 's/^ //' | sed -e 's/ $//'"
				\ . " | awk -F \" \" '{ print $3 }'"
	let l:old_style = system( l:cmd_get_makefile_style )
	if l:old_style == ""
		let l:msg = "Error retrieving local makefile"
					\ . " style -- aborting."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	let l:old_style = s:Dbn__StripLastChar( l:old_style )
	" decide whether to change it
	let l:msg = "RefDB local makefile style is currently:\n"
				\ . "'" . l:old_style . "'.\n"
				\ . "Change it? "
	let l:choice = confirm( l:msg, "&Yes\n&No", 2, "Question" )
	if l:choice != 1 | return | endif
	" select new style
	let l:style = s:Dbn__GetNewStyle(
				\ 	"Select new style for makefile: ",
				\ 	l:old_style
				\ )
	if l:style == "" | return | endif
	" do change
	let l:cmd_ch_makefile = "perl -pi\~ -e 's/^\\s*stylename\\s+\\=\\s+"
				\ . "[\\w|\\.]+\\s*$/stylename = "
				\ . l:style
				\ . "\\n/' "
				\ . l:makefile
	call system( l:cmd_ch_makefile )
	let l:new_style = system( l:cmd_get_makefile_style )
	let l:new_style = s:Dbn__StripLastChar( l:new_style )
	" check success
	if l:new_style == l:old_style
		let l:msg = "Unable to change local makefile"
					\ . " style -- aborting."
		call s:Dbn__ShowMsg( l:msg, "Error" )
	else
		let l:msg = "RefDB local makefile style is now:\n"
					\ . "'" . l:new_style . "'."
		call s:Dbn__ShowMsg( l:msg, "Info" )
	endif
	" redraw screen
	execute "redraw!"
	" if called from insert mode, return to it
	if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_ValidateXml                                        {{{2
" Purpose:    Validate document xml
" Requires:   xmllint, dbn-xmllintwrap, rxp
" Parameters: feedback - boolean (1|0) indicating whether to provide
"                        feedback to user
"             mode     - (optional) mode function was called from ['i'|other]
" Returns:    NONE
if !exists( "*s:Dbn_ValidateXml" )
function s:Dbn_ValidateXml( feedback, ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" determine validator (if no feedback, force use of xmllint)
	if a:feedback
		let l:choose = 0
		let l:opts = "&Xmllint"
		if s:use_rxp
			let l:choose = 1
			let l:opts = l:opts . "\n&RXP"
		endif
		if l:choose
			let l:choice = confirm(
						\ 	"Select XML validator: ",
						\ 	l:opts,
						\ 	1,
						\ 	"Question"
						\ )
			if l:choice == "" | return | endif
		else | let l:choice = 1
		endif
		if     l:choice == 1 | let l:validator = "xmllint"
		elseif l:choice == 2 | let l:validator = "rxp"
		else | echo "Invalid XML validator selection" | return
		endif
	else
		let l:validator = "xmllint"
	endif
	" set validate command
	if     l:validator == "xmllint" | let l:cmd = s:xmllint_wrap
	elseif l:validator == "rxp"     | let l:cmd = "rxp -V -N -s -x"
	else
		let l:msg = "Invalid validator value ('" . l:validator . "')."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	let l:cmd = l:cmd . " " . expand( "%" )
	" run validate command
	let l:feedback = system ( l:cmd )
	" provide feedback
	if a:feedback
		if v:shell_error
			let l:feedback = "Invalid XML detected:\n\n" . l:feedback
			call s:Dbn__ShowMsg( l:feedback, "Error" )
		else
			call s:Dbn__ShowMsg( "Valid XML!", "Info" )
		endif
	endif
	" redraw screen
	execute "redraw!"
	" go to insert mode if necessary
	if a:feedback
		if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
	endif
	" return success value
	return ! v:shell_error
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_OutputDbk                                          {{{2
" Purpose:    Create output
" Requires:   Makefile
" Parameters: mode - (optional) mode function was called from ['i'|other]
" Returns:    NONE
if !exists( "*s:Dbn_OutputDbk" )
function s:Dbn_OutputDbk( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" update file
	silent execute "update"
	" check validity
	if !s:Dbn_ValidateXml( 0 )
		let l:msg = "Document contains invalid XML.\n"
					\ . "Unable to proceed with output."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
		return
	endif
	" determine output format and output filename
	let l:opts = "&HTML\n&XHTML\n&PDF\n&Text (plain)"
	let l:choice = confirm( "Select output format: ", l:opts, 1, "Question" )
	if l:choice == "" | return | endif
	let l:outfile = s:Dbn__Basename( expand( "%" ) )
	let l:outfile = strpart( l:outfile, 0, match( l:outfile, '\.xml' ) )
	if     l:choice == 1
		let l:target = "html"
		let l:outfile = l:outfile . ".html"
	elseif l:choice == 2
		let l:target = "xhtml"
		let l:outfile = l:outfile . ".xhtml"
	elseif l:choice == 3
		let l:target = "pdf"
		let l:outfile = l:outfile . ".pdf"
	elseif l:choice == 4
		let l:target = "text"
		let l:outfile = l:outfile . ".txt"
	else | call s:Dbn__ShowMsg( "Invalid target format", "Error" ) | return
	endif
	" if refdb file then use different function
	if s:Dbn__EditingRefdbDoc() && s:use_refdb
		let l:basename = s:Dbn__Basename( expand( "%" ) )
		let l:basename = strpart( 
					\ 	l:basename, 
					\ 	0, 
					\ 	match( l:basename, '\.short\.xml' ) 
					\ )
		if l:target =~ '^html$\|^text$' | let l:outfile = l:basename . ".html"
		elseif l:target == "xhtml"      | let l:outfile = l:basename . ".xhtml"
		elseif l:target == "pdf"        | let l:outfile = l:basename . ".pdf"
		else
			call s:Dbn__ShowMsg( "Invalid output file target.", "Error" )
			return
		endif
		call s:Dbn_OutputRefDb( l:target, l:basename, l:outfile )
		if l:target == "text" | let l:outfile = l:basename . ".txt" | endif
	else
		" determine xslt processor
		let l:choose = 0
		let l:opts = "&Xsltproc"
		if s:use_saxon_xerces
			let l:choose = 1
			let l:opts = l:opts . "\n&Saxon (with Xerces)"
		endif
		if s:use_xalan
			let l:choose = 1
			let l:opts = l:opts . "\nX&alan"
		endif
		if l:choose
			let l:choice = confirm(
						\ 	"Select XSLT processor: ",
						\ 	l:opts,
						\ 	1,
						\ 	"Question"
						\ )
			if l:choice == "" | return | endif
		else | let l:choice = 1
		endif
		if     l:choice == 1 | let l:xsltp = "xsltproc"
		elseif l:choice == 2 | let l:xsltp = "saxonxerces"
		elseif l:choice == 3 | let l:xsltp = "xalan"
		else | echo "Invalid XSLT processor selection" | return
		endif
		" determine fo processor (if outputting pdf)
		if l:target == "pdf"
			let l:choose = 0
			let l:opts = "&FOP"
			if s:use_xep
				let l:choose = 1
				let l:opts = l:opts . "\n&Xep"
			endif
			if l:choose
				let l:choice = confirm(
							\ 	"Select FO processor: ",
							\ 	l:opts,
							\ 	1,
							\ 	"Question"
							\ )
				if l:choice == "" | return | endif
			else | let l:choice = 1
			endif
			if     l:choice == 1 | let l:fop = "fop"
			elseif l:choice == 2 | let l:fop = "xep"
			else | echo "Invalid FO processor selection" | return
			endif
		endif
		" determine stylesheets
		if   s:use_custom_xsl | let l:stylesheet = "custom"
		else                  | let l:stylesheet = "nwalsh"
		endif
		" remove output file if it currently exists
		if filereadable( l:outfile ) | call delete( l:outfile ) | endif
		" build shell command
		let l:cmd = "!make -f " . s:makefile
					\ . " XSLTP=" . l:xsltp
					\ . " SSHEET=" . l:stylesheet
		if l:target == "pdf" | let l:cmd = l:cmd . " FOP=" . l:fop | endif
		let l:cmd = l:cmd . " " . l:outfile
		" execute shell command
		execute l:cmd
	endif
	" view file
	if filereadable( l:outfile )
		echo " "
		call s:Dbn__ViewFile( l:outfile, l:target )
	endif
	" feedback displayed by Dbn__ViewFile() -- pause to read
	call s:Dbn__ConsoleProceed()
	" redraw screen
	execute "redraw!"
	" go to insert mode if necessary
	if a:0 > 0 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_OutputRefDb                                        {{{2
" Purpose:    Create output
" Requires:   Makefile
" Parameters: target   - output format ('html'|'xhtml'|'pdf'|'text')
"             basename - base name of output file
"             outfile   - outfile file name
" Returns:    NONE
if !exists( "*s:Dbn_OutputRefDb" )
function s:Dbn_OutputRefDb( target, basename, outfile )
	" capture variables
	let l:target = a:target
	let l:outfile = a:outfile
	" check for local makefile
	if !filereadable( "Makefile" )
		let l:msg = "Unable to locate local RefDB makefile."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	" determine output file
	" delete output file(s) if already exists
	if filereadable( l:outfile ) | call delete( l:outfile ) | endif
	if l:target == "pdf" | call delete( a:basename . ".fo" ) | endif
	" for html|xhtml|pdf is one step conversion
	" for text is two step conversion: xml -> html -> text
	" let's do first conversion step
	if a:target == "text" | let l:target = "html" | endif
	echo " "
	echo "Converting XML -> " . toupper( l:target ) . "..."
	echo " "
	execute "!make " . l:target
	if !filereadable( l:outfile ) | return | endif
	" let's do second conversion step if needed
	if a:target == "text"
		let l:input = a:outfile
		let l:outfile = a:basename . ".txt"
		if filereadable( l:outfile ) | call delete( l:outfile ) | endif
		echo " "
		echo "Converting HTML -> TEXT..."
		echo " "
		let l:cmd = "!lynx -dump " . l:input . " > " . l:outfile
		execute l:cmd
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn_MapModeWrong                                       {{{2
" Purpose:    Warn user mapping can't be used in this mode
" Parameters: mapping - e.g. 'm1'
"             mode    - (optional) mode function was called from ['i'|'n'|'v']
" Returns:    NONE
if !exists( "*s:Dbn_MapModeWrong" )
function s:Dbn_MapModeWrong( mapping, ... )
	" create message
	if a:0 == 1
		if     a:1 == "i" | let l:msg = "Insert"
		elseif a:1 == "n" | let l:msg = "Normal"
		elseif a:1 == "v" | let l:msg = "Visual"
		else | let l:msg = "this"
		endif
	else | let l:msg = "this"
	endif
	let l:msg = "The mapping '" 
				\ . a:mapping 
				\ . "' cannot be called from '"
				\ . l:msg
				\ . "' mode."
	" display message
	call s:Dbn__ShowMsg( l:msg, "Error" )
	" redraw screen
	execute "redraw!"
	" go to insert mode if necessary
	if a:0 == 1 && a:1 == "i" | call s:Dbn__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetInput                                          {{{2
" Purpose:    Handles user input for gui and console modes
" Parameters: prompt  - user prompt
"             default - default value
" Returns:    string - user input
if !exists( "*s:Dbn__GetInput" )
function s:Dbn__GetInput( prompt, default )
	if has( "gui_running" )
		let l:input = inputdialog( a:prompt, a:default )
	else
		let l:input = input( a:prompt, a:default )
	endif
	return l:input
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ShowMsg                                           {{{2
" Purpose:    Display message to user
" Parameters: msg  - user prompt
"             type - (optional) message type ['generic'|'warning'|'info'|
"                                             'question'|'error']
" Returns:    NONE
if !exists( "*s:Dbn__ShowMsg" )
function s:Dbn__ShowMsg( msg, ... )
	let l:msg = a:msg
	let l:type = ''
	" sanity check
	let l:error = 0
	if l:msg == ''
		let l:msg = "No message supplied to 'ShowMsg()'."
		let l:error = 1
		let l:type = "Error"
	endif
	" set dialog type (if valid type supplied and not overridden by error)
	if ! l:error
		if a:0 > 0 && tolower( a:1 ) =~ '^warning$\|^info$\|^question$\|^error$'
			let l:type = tolower( a:1 )
		endif
	endif
	" for non-gui environment add message type to output
	if !has ( "gui_running" ) && l:type != ""
		let l:msg = toupper( strpart( l:type, 0, 1 ) ) 
					\ . tolower( strpart( l:type, 1 ) )
					\ . ": " 
					\ . l:msg
	endif
	" display message
	call confirm( l:msg, "&OK", 1, l:type )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ConsoleConfirm                                    {{{2
" Purpose:    Requires user to confirm prompt in console mode
" Parameters: prompt  - user prompt
" Returns:    string - user input ('y'|'n')
if !exists( "*s:Dbn__ConsoleConfirm" )
function s:Dbn__ConsoleConfirm( prompt )
	echo a:prompt . " [y/n] "
	while 1
		let l:input = tolower( nr2char( getchar() ) )
		if l:input == "y" || l:input == "n" | break | endif
	endwhile
	echon l:input
	return input
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ConsoleProceed                                    {{{2
" Purpose:    User must press key to proceed (in console mode)
" Parameters: prompt - (optional) prompt message
" Returns:    NONE
if !exists( "*s:Dbn__ConsoleProceed" )
function s:Dbn__ConsoleProceed( ... )
	" determine prompt
	if a:0 >= 1 | let l:msg = a:1
	else        | let l:msg = "Press any key to proceed..."
	endif
	" deliver prompt
	echo l:msg
	" await keypress
	call getchar()
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__InsertString                                      {{{2
" Purpose:    Insert string at current cursor location
" Parameters: inserted_text - string for insertion
"             restrictive   - boolean (1|0) indicating whether 'paste'
"                             setting used
" Returns:    NONE
if !exists( "*s:Dbn__InsertString" )
function s:Dbn__InsertString( inserted_text, restrictive )
	if a:restrictive | let l:paste_setting = &paste | set paste | endif
	silent execute "normal a" . a:inserted_text
	if a:restrictive && ! l:paste_setting | set nopaste | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__StripEntities                                     {{{2
" Purpose:    Remove entities from string
" Parameters: string - text to convert
" Returns:    string - converted text
if !exists( "*s:Dbn__StripEntities" )
function s:Dbn__StripEntities( string )
	" delete entities (&[a-zA-Z0-9_-:.]+;)
	return substitute( 
				\ 	a:string, 
				\ 	'&[a-zA-Z0-9_\-:\.]\{-1,};', 
				\ 	'_', 
				\ 	'g' 
				\ )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__StripElements                                     {{{2
" Purpose:    Remove elements from string
" Parameters: string - text to convert
" Returns:    string - converted text
if !exists( "*s:Dbn__StripElements" )
function s:Dbn__StripElements( string )
	" delete elements ('</?[\p]+>')
	return substitute( 
				\ 	a:string, 
				\ 	'<\/\?\p\{-1,}>', 
				\ 	'', 
				\ 	'g' 
				\ )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetLabel                                          {{{2
" Purpose:    Convert string to legal attribute value syntax
" Parameters: string - user prompt
"             string - initial label fragment (eg. 'fig:')
"             string - base for label default value
" Returns:    string - label
if !exists( "*s:Dbn__GetLabel" )
function s:Dbn__GetLabel( prompt, fragment, default_base )
	" generate unique default label base
	let l:label_base = s:Dbn__Labelify( a:default_base )
	let l:label_default = l:label_base
	let l:increment = 2
	while !s:Dbn__UniqueLabel( a:fragment . l:label_default )
		let l:label_default = l:label_base . "_" . l:increment
		let l:increment = l:increment + 1
	endwhile
	" accept only unique label from user
	while 1
		let l:label = s:Dbn__GetInput(
					\ 	a:prompt,
					\ 	a:fragment . l:label_default
					\ )
		let l:label = s:Dbn__Labelify( l:label )
		if l:label == "" || s:Dbn__UniqueLabel( l:label ) | break | endif
		let l:msg = "Label '" . l:label . "' already exists."
		call s:Dbn__ShowMsg( l:msg, "Error" )
	endwhile
	" done
	return l:label
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__Labelify                                          {{{2
" Purpose:    Convert string to legal attribute value syntax
" Parameters: string - text to convert
" Returns:    string - converted text
if !exists( "*s:Dbn__Labelify" )
function s:Dbn__Labelify( string )
	" force lower case
	let l:label = tolower( a:string )
	" delete entities (&[a-zA-Z0-9_-:.]+;)
	let l:label = s:Dbn__StripEntities( l:label )
	" delete element tags (</?[\p]+>)
	let l:label = s:Dbn__StripElements( l:label )
	" strip any illegal characters, i.e., other than [a-zA-Z0-9_-:. ]
	let l:label = substitute( 
				\ 	l:label, 
				\ 	'[^a-zA-Z0-9_\-:\. ]\{}', 
				\ 	'', 
				\ 	'g' 
				\ )
	" cannot have spaces - replace with underscores
	let l:label = substitute( l:label, " ", "_", "g" )
	" some legal character combinations can cause problems
	"  - multiple dashes map to em|en dashes
	let l:label = substitute( l:label, '\-\{1,}', '_', 'g' )
	"  - multiple periods map to horizontal ellipses
	let l:label = substitute( l:label, '\.\{1,}', '.', 'g' )
	" above conversions can result in multiple underscores - make single
	let l:label = substitute( l:label, '_\{1,}', '_', 'g' )
	" done
	return l:label
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__UniqueLabel                                       {{{2
" Purpose:    Determine whether label is unique (or already exists)
" Parameters: label   - potential label
" Returns:    boolean - '1' (true=unique), '0' (false=not unique)
if !exists( "*s:Dbn__UniqueLabel" )
function s:Dbn__UniqueLabel( label )
	" remember start position
	let l:coln = col( "." )
	let l:line = line( "." )
	" search for matching label
	let l:target = "<[[:print:]]\\{-} id=\"" 
				\ . a:label 
				\ . "\"[[:print:]]\\{}>"
	let l:retval = search( l:target, 'w' )
	" return to start position
	call cursor( l:line, l:coln )
	" return value
	return ! l:retval
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__StartInsert                                       {{{2
" Purpose:    Switch to insert mode
" Parameters: right_skip - can move to right before entering insert mode
" Returns:    NONE
if !exists( "*s:Dbn__StartInsert" )
function s:Dbn__StartInsert( right_skip )
	" override skip if cursor at eol to prevent error beep
	if col( "." ) >= strlen( getline( "." ) )
		let l:right_skip = 0
	else
		let l:right_skip = a:right_skip
	endif
	" skip right if so instructed
	if l:right_skip > 0
		silent execute "normal "
					\ . l:right_skip
					\ . "l"
	endif
	" handle case where cursor at end of line
	if col( "." ) >= strlen( getline( "." ) ) | startinsert!  " ~ 'A'
	else                                      | startinsert   " ~ 'i'
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__StripLastChar                                     {{{2
" Purpose:    Removes last character from string
" Parameters: edit_string - string to edit
" Returns:    string - edited string
if !exists( "*s:Dbn__StripLastChar" )
function s:Dbn__StripLastChar( edit_string )
	return strpart(
				\ 	a:edit_string,
				\ 	0,
				\ 	strlen( a:edit_string ) - 1
				\ )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__TrimChar                                         {{{2
" Purpose:    Removes leading and trailing chars from string
" Parameters: edit_string - string to trim
"             char        - (optional) char to trim [default=' ']
" Returns:    string - trimmed string
if !exists( "*s:Dbn__TrimChar" )
function s:Dbn__TrimChar( edit_string, ... )
	" set trim character
	let l:char = ( a:0 > 0 ) ? a:1 : ' '
	" build match terms
	let l:left_match_str = '^' . l:char . '\+'
	let l:right_match_str = l:char . '\+$'
	" do trimming
	let l:string = substitute( a:edit_string, l:left_match_str, '', '' )
	return substitute( l:string, l:right_match_str, '', '' )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ListElementCount                                  {{{2
" Purpose:    Returns number of items in a list
" Parameters: list      - list to analyse
"             delimiter - (optional) element delimiter [default=' ']
" Returns:    integer - element count
if !exists( "*s:Dbn__ListElementCount" )
function s:Dbn__ListElementCount( list, ... )
	" set delimiter
	let l:delim = ( a:0 > 0 ) ? a:1 : ' '
	" do count
	return strlen( 
				\ 	substitute( s:Dbn__TrimChar( a:list ), 
				\ 		"[^" . l:delim . "]", 
				\ 		'', 
				\ 		'g'
				\ 	)
				\ ) + 1
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ListShift                                  {{{2
" Purpose:    Performs 'shift' operation on a list
" Parameters: list        - list to analyse
"             return_type - whether to return shifted element or shifted
"                           list ('list'|'element')
"             delimiter   - (optional) element delimiter [default=' ']
" Returns:    integer - element count
if !exists( "*s:Dbn__ListShift" )
function s:Dbn__ListShift( list, return_type, ... )
	" check return type
	if a:return_type !~ '^list$\|^element$'
		let l:msg = "Plugin error: Invlid parameter to 'ListShift()'."
		call s:Dbn__ShowMsg( l:msg, "Error" )
	endif
	" set delimiter
	let l:delim = ( a:0 > 0 ) ? a:1 : ' '
	" tidy up input list
	let l:list = s:Dbn__TrimChar( a:list, l:delim )
	" process list
	if s:Dbn__ListElementCount( l:list, l:delim ) == 1  " one-element list
		let l:retval = ( a:return_type == 'list' ) ? '' : l:list
	else  " multiple-element list
		let l:first_delim = stridx(l:list, l:delim )
		if   a:return_type == 'list'  " return list
			let l:retval = strpart( l:list, l:first_delim )
		else                          " return first element
			let l:retval = strpart( l:list, 0, l:first_delim )
		endif
	endif
	" return answer
	return s:Dbn__TrimChar( l:retval )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ValidInteger                                      {{{2
" Purpose:    Determine whether value is a valid integer
" Parameters: candidate - candidate integer
" Returns:    1|0  [ 1 = true , 0 = false ]
if !exists( "*s:Dbn__ValidInteger" )
function s:Dbn__ValidInteger( candidate )
	if a:candidate =~ '^-\=[0-9]\+$'  " only integers
		return 1  " true
	endif
	return 0  " false
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ValidPositiveInteger                              {{{2
" Purpose:    Determine whether value is a valid positive integer
" Parameters: candidate - candidate integer
" Returns:    1|0  [ 1 = true , 0 = false ]
if !exists( "*s:Dbn__ValidPositiveInteger" )
function s:Dbn__ValidPositiveInteger( candidate )
	if a:candidate =~ '^[0-9]\+$'  " only integers
		if strpart( a:candidate, 0, 1 ) != "0"  " non-zero
			return 1  " true
		endif
	endif
	return 0  " false
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetFilePath                                       {{{2
" Purpose:    User selects filepath (can choose relative or absolute)
" Parameters: prompt - user prompt
" Returns:    string - filepath (empty string if error/cancel)
" Requires:   external file: 'get-filepath'
if !exists( "*s:Dbn__GetFilePath" )
function s:Dbn__GetFilePath( prompt )
	" get (absolute) filepath -- abort if user cancels
	let l:init_dir = expand( "%:p" )  " next step = remove file name from end
	let l:init_dir = strpart(
				\ 	l:init_dir,
				\ 	0,
				\ 	strridx( l:init_dir, "/" ) + 1
				\ )
	if has( "browse" )
		let l:filepath = browse( 0, a:prompt, l:init_dir, "" )
	else
		let l:cmd = s:get_filepath 
					\ . " -t \""
					\ . a:prompt
					\ . "\" -d \""
					\ . l:init_dir
					\ . "\""
		let l:filepath = system( l:cmd )
		if v:shell_error
			let l:msg = "Script '" 
						\ . s:Dbn__Basename( s:get_filepath )
						\ . "' failed."
			call s:Dbn__ShowMsg( l:msg, "Error" )
			return ""
		endif
		let l:filepath = s:Dbn__StripLastChar( l:filepath )
	endif
	if l:filepath == "" || !filereadable( l:filepath ) | return | endif
	" user can select type of filepath to return
	let l:type = confirm(
				\ 	"Select type of filepath: ",
				\ 	"&Relative\n&Absolute",
				\ 	1,
				\	"Question"
				\ )
	if     l:type == 1 | let l:filepath = s:Dbn__MakeRelative( l:filepath )
	elseif l:type != 2 | let l:filepath = ""  " neither selected
	endif
	" return result
	return l:filepath
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__Basename                                          {{{2
" Purpose:    Return basename of filepath
" Parameters: absolute filepath
" Returns:    filename
if !exists( "*s:Dbn__Basename" )
function s:Dbn__Basename( fp )
	let l:fp = a:fp
	" only do removal if detect slash
	if match( l:fp, "/" ) != -1
		" extract string following last slash
		let l:fp = strpart(
					\ 	l:fp,
					\ 	strridx( l:fp, "/" ) + 1
					\ )
	endif
	return l:fp
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__MenuSelect                                        {{{2
" Purpose:    Return basename of filepath
" Parameters: title        - dialog title
"             prompt       - dialog prompt
"             options      - menu options
"             silent_fail  - boolean (whether to fail silently)
"             height       - (optional) dialog height
"             width        - (optional) dialog width
" Returns:    selected option
if !exists( "*s:Dbn__MenuSelect" )
function s:Dbn__MenuSelect( title, prompt, options, silent_fail, ... )
	" set height and width
	let l:height = 0
	if a:0 > 0 && s:Dbn__ValidPositiveInteger( a:1 )
		let l:height = a:1
	endif
	let l:width = 0
	if a:0 > 1 && s:Dbn__ValidPositiveInteger( a:2 )
		let l:width = a:2
	endif
	" build menu command
	let l:cmd = s:menu_select
				\ . " -t \"" . a:title . "\""
				\ . " -p \"" . a:prompt . "\""
				\ . " -o '" . a:options . "'"
				\ . " -H " . l:height
				\ . " -w " . l:width
	" execute menu command
	let l:selection = system( l:cmd )
	" check for error
	if v:shell_error
		if !a:silent_fail
			let l:msg = "Script '" 
						\ . s:Dbn__Basename( s:menu_select )
						\ . "' failed."
			call s:Dbn__ShowMsg( l:msg, "Error" )
		endif
		return ""
	endif
	" return menu selection
	return s:Dbn__StripLastChar( l:selection )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__MakeRelative                                      {{{2
" Purpose:    Turns absolute filepath into filepath relative to cwd
" Parameters: absolute filepath
" Returns:    relative filepath
if !exists( "*s:Dbn__MakeRelative" )
function s:Dbn__MakeRelative( chosen_fp )
	let l:chosen_fp = a:chosen_fp
	let l:working_p = expand( "%:p" )
	" remove filename from end of working filepath
	let l:working_p = strpart(
				\ 	l:working_p,
				\ 	0,
				\ 	strridx( l:working_p, "/" ) + 1
				\ )
	" remove common path
	let l:exit_flag = 0  " false
	while ! l:exit_flag
		let l:next_slash = match( l:working_p, "/", 1 )
		if l:next_slash != -1
			if strpart( l:working_p, 0, l:next_slash ) 
						\ == strpart( l:chosen_fp, 0, l:next_slash )
				let l:working_p = strpart( l:working_p, l:next_slash )
				let l:chosen_fp = strpart( l:chosen_fp, l:next_slash )
			else
				let l:exit_flag = 1
			endif
		else | let l:exit_flag = 1 | endif
	endwhile
	" substitute relative for absolute working path parent directories
	let l:relative_fp = ""
	let l:next_slash = match( l:working_p, "/", 1 )
	while l:next_slash != -1
		let l:working_p = strpart( l:working_p, l:next_slash )
		let l:relative_fp = l:relative_fp . "../"
		let l:next_slash = match( l:working_p, "/", 1 )
	endwhile
	" add remaining filepath of chosen file
	" need to remove trailing slash first
	let l:relative_fp = strpart( 
				\	l:relative_fp,
				\	0,
				\	strlen( l:relative_fp ) -1
				\ )
	let l:relative_fp = l:relative_fp . l:chosen_fp
	if strpart( l:relative_fp, 0, 1 ) == "/"
		let l:relative_fp = strpart( l:relative_fp, 1 )
	endif
	return l:relative_fp
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__BuildXmlEntity                                    {{{2
" Purpose:    Assemble xml entity
" Parameters: tagname        - element name
"             attributes     - string holding all attributes and their values
"             entity_content - element content
" Returns:    string - complete xml entity
if !exists( "*s:Dbn__BuildXmlEntity" )
function s:Dbn__BuildXmlEntity( tagname, attributes, entity_content )
	let l:entity = "<" . a:tagname
	if a:attributes != ""  " has attributes
		let l:entity = l:entity
					\ . " "
					\ . a:attributes
	endif
	if a:entity_content == ""  " no content, so '<element/>'
		let l:entity = l:entity . "/>"
	else  " content, so '<element>content</element>'
		let l:entity = l:entity
					\ . ">"
					\ . a:entity_content
					\ . "</"
					\ . a:tagname
					\ . ">"
	endif
	return l:entity
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__BuildIndexTerm                                    {{{2
" Purpose:    Build internal elements for 'indexterm' element
" Parameters: default_primary_term - default primary term
" Returns:    string               - xml elements
if !exists( "*s:Dbn__BuildIndexTerm" )
function s:Dbn__BuildIndexTerm( default_primary_term)
	let l:output = '' | let l:sec = '' | let l:tert = ''
	" get primary term
	let l:msg = 'Enter index primary term '
				\ . '(blank to abort or select previous): '
	let l:primary = s:Dbn__GetInput( l:msg, a:default_primary_term )
	if l:primary == ''  " check whether selecting previous
		let l:msg = "Abort, or copy a previous index term?\n"
					\ . "(Doesn't copy 'see' or 'seealso' parts)"
		let l:choice = confirm(
					\	l:msg,
					\	"&Abort\n&Copy previous",
					\	1,
					\	"Question"
					\ )
		if l:choice == 2  " selecting previous
			let l:index = s:Dbn__SelectIndexEntry()  " select term(s)
			if l:index != ''
				" extract terms
				let l:primary = s:Dbn__ExtractIndexEntry( l:index, ' | ', 1 )
				let l:sec = s:Dbn__ExtractIndexEntry( l:index, ' | ', 2 )
				let l:tert = s:Dbn__ExtractIndexEntry( l:index, ' | ', 3 )
				" give user feedback
				let l:msg = ''
				if l:primary != ''
					let l:msg = l:msg . 'Using primary term: ' . l:primary
				endif
				if l:sec != ''
					let l:msg = l:msg . "\nUsing secondary term: " . l:sec
				endif
				if l:tert != ''
					let l:msg = l:msg . "\nUsing tertiary term: " . l:tert
				endif
				call s:Dbn__ShowMsg( l:msg, "Info" )
			endif
		endif
	endif
	if l:primary != ''
		let l:output = l:output . '<primary>' . l:primary . '</primary>'
		" get secondary term
		if l:sec == ''
			let l:msg = 'Enter secondary index term (leave blank if none): '
			let l:sec = s:Dbn__GetInput( l:msg, '' )
		endif
		if l:sec != ''
			let l:output = l:output . '<secondary>' . l:sec . '</secondary>'
			" get tertiary term
			if l:tert == ''
				let l:msg = 'Enter tertiary index term (leave blank if none): '
				let l:tert = s:Dbn__GetInput( l:msg, '' )
			endif
			if l:tert != ''
				let l:output = l:output . '<tertiary>' . l:tert . '</tertiary>'
			endif
		endif
		" user can enter 'see' or 'seealso' terms
		let l:msg = 'Each index entry can refer to other index entries.'
					\ . "\n"
					\ . 'These will appear in the index as '
					\ . '"See xxx" or "See also xxx".'
					\ . "\n"
					\ . 'Element "see": one only, section/page '
					\ . 'link suppressed.'
					\ . "\n"
					\ . 'Element "seealso": multiple allowed.'
					\ . "\n"
					\ . 'Which referral method do you want to use?'
		let l:choice = confirm( 
					\	l:msg,
					\	"&Neither\n&See\nSee &also",
					\	1,
					\	"Question"
					\ )
		if l:choice == 2  " see
			let l:msg = 'Enter asociated index term (leave blank if none): '
			let l:see = s:Dbn__GetInput( l:msg, '' )
			if l:see != ''
				let l:output = l:output . '<see>' . l:see . '</see>'
			endif
		elseif l:choice == 3  " seealso
			let l:iteration = 1
			while 1
				let l:msg = ( l:iteration == 1 ) ? 'if none' : 'when done'
				let l:msg = 'Enter associated index term (leave blank '
							\ . l:msg . '): '
				let l:seealso = s:Dbn__GetInput( l:msg, '' )
				if l:seealso == '' | break | endif
				let l:output = l:output . '<seealso>' . l:seealso . '</seealso>'
				let l:iteration = l:iteration + 1
			endwhile
		endif
	endif
	" return xml elements
	return l:output
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ChooseLinkableElement                             {{{2
" Purpose:    User selects from element ids
" Parameters: prompt - user prompt
" Returns:    string - element id
if !exists( "*s:Dbn__ChooseLinkableElement" )
function s:Dbn__ChooseLinkableElement( prompt )
	" get current position and jump to top of document
	let l:line = line( "." )
	let l:coln = col( "." )
	call cursor( 1, 1 )
	" process lines containing element ids
	let l:search_string = '<\p\{-}id="\p\{-}"\p\{-}>'
	let l:mnu_options = ''
	while search( l:search_string, 'W' ) > 0
		" for each line process elements in turn
		let l:working_line = getline( "." )
		let l:start_pos = 0
		let l:search_match = matchstr( 
					\ 	l:working_line,
					\ 	l:search_string,
					\ 	l:start_pos
					\ )
		while l:search_match != ''
			" now have match - let's extract id
			let l:id = s:Dbn__ExtractElementAttribute( l:search_match, 'id' )
			" now let's add id to menu options
			let l:mnu_options = l:mnu_options . '"' . l:id . '" "" ' . "\n"
			" reset variables for next loop
			let l:start_pos = matchend( 
						\ 	l:working_line,
						\ 	l:search_string,
						\ 	l:start_pos
						\ )
			let l:search_match = matchstr( 
						\ 	l:working_line,
						\ 	l:search_string,
						\ 	l:start_pos
						\ )
		endwhile
		" jump to end of line to avoid processing it multiple times
		silent! execute "normal $"
	endwhile
	" reposition cursor
	call cursor( l:line, l:coln )
	" sort if necessary
	let l:msg = a:prompt . "\n" . 'Please select order in which to display ids: '
	let l:choice = confirm( l:msg, "&Document\n&Alphabetical", 1, "Question" )
	if l:choice == 2  "alphabetical
		let l:mnu_options = system( "echo '" . l:mnu_options . "' | sort" )
		let l:mnu_options = s:Dbn__StripLastChar( l:mnu_options )
	endif
	" set variables to determine dialog display (quote usage is critical)
	let l:id = s:Dbn__MenuSelect(
				\ 	"ID SELECT",
				\ 	"Select id of target element: ",
				\ 	l:mnu_options,
				\ 	0
				\ )
	" done
	return l:id
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__SelectIndexEntry                                  {{{2
" Purpose:    User selects from current index terms
" Parameters: NONE
" Returns:    string - index term (up to three levels, tab-delimited)
if !exists( "*s:Dbn__SelectIndexEntry" )
function s:Dbn__SelectIndexEntry()
	" get current position and jump to top of document
	let l:line = line( "." )
	let l:coln = col( "." )
	call cursor( 1, 1 )
	" process lines containing index elements
	let l:search_string = '<indexterm>\p\{-}<\/indexterm>'
	let l:mnu_options = ''
	while search( l:search_string, 'W' ) > 0
		" for each line process index elements in turn
		let l:working_line = getline( "." )
		let l:start_pos = 0
		let l:search_match = matchstr( 
					\ 	l:working_line,
					\ 	l:search_string,
					\ 	l:start_pos
					\ )
		while l:search_match != ''
			" now have match - let's extract terms
			let l:primary = s:Dbn__StripElements( 
						\ 	matchstr( 
						\ 		l:search_match,
						\ 		'<primary>\p\{-}<\/primary>'
						\ 	)
						\ )
			let l:sec = s:Dbn__StripElements( 
						\ 	matchstr( 
						\ 		l:search_match,
						\ 		'<secondary>\p\{-}<\/secondary>'
						\ 	)
						\ )
			let l:tert = s:Dbn__StripElements( 
						\ 	matchstr( 
						\ 		l:search_match,
						\ 		'<tertiary>\p\{-}<\/tertiary>'
						\ 	)
						\ )
			" now let's add term(s) to menu options
			let l:mnu_options = l:mnu_options . '"'
						\ . substitute( l:primary, '|', '', 'g' )
			if l:sec != ''
				let l:mnu_options = l:mnu_options . ' | '
							\ . substitute( l:sec, '|', '', 'g' )
			endif
			if l:tert != ''
				let l:mnu_options = l:mnu_options . ' | '
							\ . substitute( l:tert, '|', '', 'g' )
			endif
			let l:mnu_options = l:mnu_options . '" "" '
			" reset variables for next loop
			let l:start_pos = matchend( 
						\ 	l:working_line,
						\ 	l:search_string,
						\ 	l:start_pos
						\ )
			let l:search_match = matchstr( 
						\ 	l:working_line,
						\ 	l:search_string,
						\ 	l:start_pos
						\ )
		endwhile
		" jump to end of line to avoid processing it multiple times
		silent! execute "normal $"
	endwhile
	" reposition cursor
	call cursor( l:line, l:coln )
	" deal with case where no index terms found
	if l:mnu_options == ''
		call s:Dbn__ShowMsg( 'No index terms found.', "Error" )
		let l:indexterm = ''
	else
		" select index term
		let l:msg = 'Index terms can be nested up to three levels deep.\n'
					\ . 'Levels are separated by a vertical bar (|).\n\n'
					\ . 'Choose term to index:'
		let l:indexterm = s:Dbn__MenuSelect(
					\ 	"INDEX SELECT",
					\ 	l:msg,
					\ 	l:mnu_options, 
					\ 	0
					\ )
	endif
	" done
	return l:indexterm
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ExtractIndexEntry                                 {{{2
" Purpose:    Extracts individual terms from delimited list
" Parameters: indexterms - delimited list of index terms
"             delimiter  - term delimiter
"             level      - level of term to extract (1|2|3)
" Returns:    string - index term
if !exists( "*s:Dbn__ExtractIndexEntry" )
function s:Dbn__ExtractIndexEntry( indexterms, delimiter, level )
	let l:iteration = 1 | let l:position = 0 | let l:target = ''
	let l:length = strlen( a:indexterms )
	" loop through list examining terms
	while match( a:indexterms, ' | ', l:position ) != -1
		let l:term_end = match( a:indexterms, a:delimiter, l:position )
		let l:indexterm = strpart(
					\ 	a:indexterms,
					\ 	l:position,
					\ 	l:length - l:position - ( l:length - l:term_end )
					\ )
		" record term if correct level
		if l:iteration == a:level | let l:target = l:indexterm | endif
		" prepare for next iteration
		let l:position = matchend( a:indexterms, a:delimiter, l:position )
		let l:iteration = l:iteration + 1
	endwhile
	" final iteration
	if l:iteration == a:level
		let l:target = strpart( a:indexterms, l:position )
	endif
	" done
	return l:target
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__IndexItemPreferred                                {{{2
" Purpose:    User decides whether index item is preferred
" Parameters: NONE
" Returns:    boolean - indicates whether index item is preferred
if !exists( "*s:Dbn__IndexItemPreferred" )
function s:Dbn__IndexItemPreferred()
	" get user input
	let l:msg = 'What is the significance level of this index item?' . "\n"
				\ . '("Preferred" index items are usually emphasised '
				\ . 'in some way): '
	let l:choice = confirm( l:msg, "&Normal\n&Preferred", 1, "Question" )
	" interpret user choice
	if l:choice == 2 | return 1 | else | return 0 | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__SelectGlossaryTerm                                {{{2
" Purpose:    Choose existing glossary term
" Assumes:    Only 1 'glossentry'|'glossterm' opening tag per line
"             Every glossentry has an id attribute
" Parameters: prompt - selection prompt
"             new    - boolean [1|0]: whether 'New Entry' option added
" Returns:    string - idref of selected glossary term
if !exists( "*s:Dbn__SelectGlossaryTerm" )
function s:Dbn__SelectGlossaryTerm( prompt, new )
	" get current position and jump to top of document
	let l:line = line( "." ) | let l:coln = col( "." ) | call cursor( 1, 1 )
	" search glossaries in sequence
	while search( '<glossary>' )
		let l:mnu_options = ''
		" set search term
		let l:awaiting = 'glossentry'
		let l:search_term = '<glossentry\p\{-}>'
		" search lines sequentially till end of glossary
		while 1
			" break on end of file (indicates non-well-formed document)
			if line( "." ) + 1 == line( "$" ) | break | endif
			" get next line
			call cursor( line( "." ) + 1, 1 )
			let l:working_line = getline( "." )
			" break loop at end of glossary
			if matchstr( l:working_line, '<\/glossary>' ) != '' | break | endif
			" process if line contains 'glossentry' or 'glossterm' opening tags
			let l:search_result = matchstr( l:working_line, l:search_term )
			if l:search_result != ''
				if l:awaiting == 'glossentry'
					" found glossentry: store id in variable
					let l:glossentry_id = s:Dbn__ExtractElementAttribute(
								\ l:search_result, 'id' )
					" change search term
					let l:awaiting = 'glossterm'
					let l:search_term = '<glossterm\p\{-}>\p\{-}<\/glossterm>'
				elseif l:awaiting == 'glossterm'
					" found glossterm: add item to menu
					let l:glossterm = s:Dbn__StripElements( l:search_result )
					let l:mnu_options = l:mnu_options .
								\ ' "' . l:glossentry_id . '" ' .
								\ '"' . l:glossterm . '"'
					" change search term
					let l:awaiting = 'glossentry'
					let l:search_term = '<glossentry\p\{-}>'
					" clear variables
					let l:glossentry_id = ''
					let l:glossterm = ''
				else  " error condition
					call s:Dbn__ShowMsg(
								\	"Fatal error has occurred.",
								\	"Question"
								\ )
					return
				endif
			endif
		endwhile  " sequential search within glossary
		" break on end of file (indicates non-well-formed document)
		if line( "." ) + 1 != line( "$" ) | break | endif
	endwhile  " sequential search for glossaries
	" add menu option for new entry if requested
	if a:new
		let l:mnu_options = 
					\ ' "::[New entry]::" ' .
					\ '"Create new glossary entry"' .
					\ l:mnu_options
	endif
	" reposition cursor
	call cursor( l:line, l:coln )
	" deal with case where no index terms found
	if l:mnu_options == ''
		call s:Dbn__ShowMsg( 'No glossary terms found.', "Error" )
		let l:glosarryterm = ''
	else
		" select previous term or option for new term
		let l:glossaryterm = s:Dbn__MenuSelect(
					\ 	"GLOSSARY SELECT",
					\ 	a:prompt,
					\ 	l:mnu_options,
					\ 	1,
					\ 	15,
					\ 	60
					\ )
	endif
	" done
	return l:glossaryterm
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GotoGlossentryInsertionPoint                      {{{2
" Purpose:    Moves to insertion point for glossentry
" Assumes:    Only 1 'glossentry'|'glossterm' opening tag per line
"             Every glossentry has an id attribute
"             Glossary element present
" Parameters: term - glossterm
" Returns:    NONE
if !exists( "*s:Dbn__GotoGlossentryInsertionPoint" )
function s:Dbn__GotoGlossentryInsertionPoint( term )
	" get current position and jump to top of document
	call cursor( 1, 1 )
	" goto first glossary
	if !search( '<glossary>' )
		call s:Dbn__ShowMsg( "No glossary element found.", "Error" )
		return
	endif
	call search( '>' ) | silent! execute "normal l"
	" set some variables
	let l:glos_line = line( "." ) | let l:glos_coln = col( "." )
	let l:curr_line = l:glos_line | let l:curr_coln = l:glos_coln
	let l:prev_line = 0 | let l:prev_coln = 0
	let l:insertion_pt_found = 0  " false
	let l:search_term = '<glossterm\p\{-}>\p\{-}<\/glossterm>'
	" process lines sequentially till end of glossary
	while 1
		" break on end of file (indicates non-well-formed document)
		if line( "." ) + 1 == line( "$" ) | break | endif
		" get next line
		call cursor( line( "." ) + 1, 1 )
		let l:working_line = getline( "." )
		" break loop at end of glossary
		if matchstr( l:working_line, '<\/glossary>' ) != '' | break | endif
		" process if line contains 'glossentry' or 'glossterm' opening tags
		let l:search_result = matchstr( l:working_line, l:search_term )
		if l:search_result != ''
			let l:prev_line = l:curr_line | let l:prev_coln = l:curr_coln
			let l:curr_line = line( "." ) | let l:curr_coln = col( "." )
			let l:curr_term = s:Dbn__StripElements( l:search_result )
			let l:compare = l:curr_term . "\n" . a:term
			let l:cmd = 'echo "' . l:compare . '" | sort --check --ignore-case'
			if system( l:cmd ) != ''
				" out of sequence, so have passed insertion point
				let l:insertion_pt_found = 1
				break
			endif
		endif
	endwhile  " sequential search within glossary
	" if flag set then glossterms found and is not last entry
	if l:insertion_pt_found
		" go to enclosing glossentry start tag
		call search( '<glossentry\p\{-}>', 'b' )
		silent! execute 'normal O'
	elseif l:prev_line != 0  " last entry
		" go to previous (final) glossentry end tag
		call search( '<\/glossentry>', 'b' )"
		silent! execute 'normal o'
	elseif l:prev_line == 0  " no glossterms found
		" go to glossary element start tag
		call cursor( l:glos_line, l:glos_coln )
		silent! execute 'normal o'
	else | call s:Dbn__ShowMsg( "Fatal error", "Error" ) | return
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GlossaryTermExists                                {{{2
" Purpose:    Checks whether glossterm exists as glossentry (case-insensitive)
" Assumes:    Only 1 'glossentry'|'glossterm' opening tag per line
"             Every glossentry has an id attribute
" Parameters: term    - glossterm
" Returns:    boolean - indicates whether glossentry for glossterm
if !exists( "*s:Dbn__GlossaryTermExists" )
function s:Dbn__GlossaryTermExists( term )
	let l:glossterm_found = 0  " false
	" get current position and jump to top of document
	let l:line = line( "." ) | let l:coln = col( "." ) | call cursor( 1, 1 )
	" search glossaries in sequence
	while search( '<glossary>' )
		let l:mnu_options = ''
		" set search term
		let l:search_term = '<glossterm\p\{-}>' . a:term . '<\/glossterm>'
		" search lines sequentially till end of glossary
		while 1
			" break on end of file (indicates non-well-formed document)
			if line( "." ) + 1 == line( "$" ) | break | endif
			" get next line
			call cursor( line( "." ) + 1, 1 )
			let l:working_line = getline( "." )
			" break loop at end of glossary
			if matchstr( l:working_line, '<\/glossary>' ) != '' | break | endif
			" process if line contains matching glossterm
			let l:search_result = matchstr( l:working_line, l:search_term )
			if l:search_result != ''
				let l:glossterm_found = 1
				break
			endif
		endwhile  " sequential search within glossary
		" break if glossterm found
		if l:glossterm_found | break | endif
		" break on end of file (indicates non-well-formed document)
		if line( "." ) + 1 != line( "$" ) | break | endif
	endwhile  " sequential search for glossaries
	" done
	call cursor( l:line, l:coln )
	return l:glossterm_found
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GlossentryIdExists                                {{{2
" Purpose:    Checks whether glossentry id exists
" Assumes:    Only 1 'glossentry'|'glossterm' opening tag per line
"             Every glossentry has an id attribute
" Parameters: id      - glossterm
" Returns:    boolean - indicates whether glossentry for glossterm
if !exists( "*s:Dbn__GlossentryIdExists" )
function s:Dbn__GlossentryIdExists( id )
	let l:glossentry_found = 0  " false
	" get current position and jump to top of document
	let l:line = line( "." ) | let l:coln = col( "." ) | call cursor( 1, 1 )
	" search glossaries in sequence
	while search( '<glossary>' )
		let l:mnu_options = ''
		" set search term
		let l:search_term = '<glossentry\p\{-}id="' . a:id . '"\p\{-}>'
		" search lines sequentially till end of glossary
		while 1
			" break on end of file (indicates non-well-formed document)
			if line( "." ) + 1 == line( "$" ) | break | endif
			" get next line
			call cursor( line( "." ) + 1, 1 )
			let l:working_line = getline( "." )
			" break loop at end of glossary
			if matchstr( l:working_line, '<\/glossary>' ) != '' | break | endif
			" process if line contains matching glossentry
			let l:search_result = matchstr( l:working_line, l:search_term )
			if l:search_result != ''
				let l:glossentry_found = 1
				break
			endif
		endwhile  " sequential search within glossary
		" break if glossentry found
		if l:glossentry_found | break | endif
		" break on end of file (indicates non-well-formed document)
		if line( "." ) + 1 != line( "$" ) | break | endif
	endwhile  " sequential search for glossaries
	" done
	call cursor( l:line, l:coln )
	return l:glossentry_found
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetGlosstermMatchingGlossentryId                  {{{2
" Purpose:    Finds glossary glossterm matching glossentry refid
" Assumes:    Only 1 'glossentry'|'glossterm' opening tag per line
"             Every glossentry has an id attribute
" Parameters: id - glossentry refid
" Returns:    string - glossterm
if !exists( "*s:Dbn__GetGlosstermMatchingGlossentryId" )
function s:Dbn__GetGlosstermMatchingGlossentryId( id )
	let l:glossterm = ''
	" get current position and jump to top of document
	let l:line = line( "." ) | let l:coln = col( "." ) | call cursor( 1, 1 )
	" search for id
	let l:search_term = '<glossentry\p\{-}id="' . a:id . '"\p\{-}>'
	if search( l:search_term, 'W' )
		" return next glossterm
		let l:search_term = '<glossterm\p\{-}>\p\{-}<\/glossterm>'
		if search( l:search_term, 'W' )
			let l:search_result = matchstr( getline( "." ), l:search_term )
			if l:search_result != ''
				let l:glossterm = s:Dbn__StripElements( l:search_result )
			endif
		endif
	endif
	" done
	call cursor( l:line, l:coln )
	return l:glossterm
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__RefdbOk                                           {{{2
" Purpose:    Checks for RefDB client ('refdba', 'refdbc') access
" Parameters: NONE
" Returns:    bool - success at accessing RefDB clients
if !exists( "*s:Dbn__RefdbOk" )
function s:Dbn__RefdbOk()
	" test clients and return error if fail
	call system( s:refdba . " -C listdb < /dev/null" )
	if   v:shell_error != 0 | return 0 | endif
	call system( s:refdbc . " -C listdb < /dev/null" )
	if   v:shell_error != 0 | return 0 | endif
	" if reached here, both succeeded
	return 1
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__EditingRefdbDoc                                   {{{2
" Purpose:    Determines whether current file is a RefDB document
" Parameters: NONE
" Returns:    bool - whether editing a RefDB document
" Note:       Return true if filename of form 'foo.short.xml'
if !exists( "*s:Dbn__EditingRefdbDoc" )
function s:Dbn__EditingRefdbDoc()
	return match( expand( "%" ), '\.short\.xml' ) != -1 ? 1 : 0
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__IsValidRefdbDb                                    {{{2
" Purpose:    Check whether db is a valid RefDB reference database
" Parameters: db - candidate RefDB reference database
" Returns:    bool - whether valid RefDB db or not
if !exists( "*s:Dbn__IsValidRefdbDb" )
function s:Dbn__IsValidRefdbDb( db )
	" sanity check
	if a:db =~ " " || a:db == "" | return 0 | endif
	" get list of dbs as single line
	let l:db_list = s:Dbn__GetFullRefdbDbList()
	" test for presence of db in list
	let l:cmd = "echo \"" . l:db_list . "\" | grep \"\\b" 
				\ . a:db . "\\b\" | wc -l"
	let l:count = system( l:cmd )
	if   l:count >= 1 | return 1  " success
	else              | return 0  " failure
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetFullRefdbDbList                                {{{2
" Purpose:    Extract full list of RefDB reference databases
" Parameters: NONE
" Returns:    string - list of refdb reference databases
if !exists( "*s:Dbn__GetFullRefdbDbList" )
function s:Dbn__GetFullRefdbDbList()
	" get list of dbs and convert to single line
	let l:cmd = s:refdba . " -C listdb 2> /dev/null | "
				\ . "tr '\n' ' ' | sed -e 's/ $//'"
	return system( l:cmd )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetDefaultRefdbDb                                 {{{2
" Purpose:    Extracts refdb default database from given document
" Requires:   RefDB, sed, tr, tail, grep, awk
" Parameters: filepath  - file to extract db name from
"             file type - ('makefile'|'initfile')
" Returns:    string - name of database ('' if none)
if !exists( "*s:Dbn__GetDefaultRefdbDb" )
function s:Dbn__GetDefaultRefdbDb( filepath, filetype )
	" check file exists
	if !filereadable( a:filepath ) | return "" | endif
	" construct search command
	let l:cmd = "[[:space:]]\\+\\b[[:alpha:]_]\\+"
				\ . "\\b[[:space:]]*$\" "
				\ . a:filepath
				\ . " | tail -n 1 | sed -e 's/	/ /g' | tr -s ' '"
				\ . " | sed -e 's/^ //' | sed -e 's/ $//'"
	if a:filetype == "makefile"
		let l:cmd = "grep \"^[[:space:]]*database[[:space:]]\\+\\="
					\ . l:cmd
					\ . " | awk -F \" \" '{ print $3 }'"
	elseif a:filetype == "initfile"
		let l:cmd = "grep \"^[[:space:]]*defaultdb"
					\ . l:cmd
					\ . " | awk -F \" \" '{ print $2 }'"
	else | return '' | endif
	" execute search command
	return s:Dbn__StripLastChar( system( l:cmd ) )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetCurrentRefdbDb                                 {{{2
" Purpose:    Extracts current refdb default database
"             Tries Makefile first, then init file, then lets user choose
" Requires:   RefDB, sed, tr, tail, grep, awk
" Note:       Will output information to shell ('echo')
" Parameters: silent - (optional) suppress non-error output if = '1'
" Returns:    string - name of database ('' if none)
if !exists( "*s:Dbn__GetCurrentRefdbDb" )
function s:Dbn__GetCurrentRefdbDb( ... )
	" are we in silent running?
	if a:0 > 0 && a:1 == 1 | let l:talky = 0
	else                   | let l:talky = 1
	endif
	" determine status of makefile and initfile
	let l:makefile = s:Dbn__StripLastChar( system( "pwd" ) ) . "/Makefile"
	let l:makefile_exists = filereadable( l:makefile ) ? 1 : 0
	let l:makefile_db = s:Dbn__GetDefaultRefdbDb( l:makefile, "makefile" )
	let l:makefile_default = l:makefile_db == "" ? 0 : 1
	let l:initfile = s:Dbn__StripLastChar( system( "echo ~" ) ) . "/.refdbcrc"
	let l:initfile_exists = filereadable( l:initfile ) ? 1 : 0
	let l:initfile_db = s:Dbn__GetDefaultRefdbDb( l:initfile, "initfile" )
	let l:initfile_default = l:initfile_db == "" ? 0 : 1
	" determine database
	" try to get makefile default first
	if l:makefile_exists && l:makefile_default
		let l:db = l:makefile_db
		if l:talky
			echo "Using refdb database specified in makefile\n"
						\ . "[" . l:makefile . "]."
		endif
	" if that fails, try to get initfile default
	elseif l:initfile_exists && l:initfile_default
		let l:db = l:initfile_db
		if l:talky
			echo "Using refdb database specified in user global "
						\ . "config file\n[" . l:initfile . "]."
		endif
	" if that also fails, get user to choose
	else
		let l:msg = "No default reference database is set.\n"
					\ . "Please select database:"
		let l:db = s:Dbn__GetNewRefdbDb( s:Dbn__GetFullRefdbDbList(), 
					\ l:msg, '' )
	endif
	" provide user feedback
	if l:db != "" && !s:Dbn__IsValidRefdbDb( l:db )
		echo "Error: Invalid database selection: '" . l:db . "'."
		let l:db = ""
	elseif l:db == "" | echo "Error: No database has been set."
	else
		if l:talky | echo "RefDB database: '" . l:db . "'." | endif
	endif
	" return db
	return l:db
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ChangeDefaultRefdbDb                              {{{2
" Purpose:    Changes current refdb default database
" Requires:   RefDB, perl
" Parameters: filepath  - file to extract db name from
"             filetype - ('makefile'|'initfile')
"             old_db    - current default db
"             new_db    - new default db
" Returns:    boolean - indicates success of change
if !exists( "*s:Dbn__ChangeDefaultRefdbDb" )
function s:Dbn__ChangeDefaultRefdbDb( filepath, filetype, old_db, new_db )
	" construct replace command
	let l:cmd = "perl -pi\~ -e 's/^\\s*"
	if a:filetype == "makefile"
		let l:cmd = l:cmd . "database\\s+\\=\\s+\\b\\w+\\b\\s*$/database = "
	elseif a:filetype == "initfile"
		let l:cmd = l:cmd . "defaultdb\\s+\\b\\w+\\b\\s*$/defaultdb\\t"
	else | return 0 | endif  " error
	let l:cmd = l:cmd . a:new_db . "\\n/' " . a:filepath
	" do replacement
	call system( l:cmd )
	" check success
	let l:current_db = s:Dbn__GetDefaultRefdbDb( a:filepath, a:filetype )
	if l:current_db == a:old_db
		let l:msg = "Unable to change reference database -- aborting."
		let l:retval = 0
	else
		let l:msg = "Default reference database is now:\n'" 
					\ . l:current_db . "'."
		let l:retval = 1
	endif
	call s:Dbn__ShowMsg( l:msg, "Info" )
	return l:retval
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__AddDefaultRefdbDb                                 {{{2
" Purpose:    Adds default database option to makefile or init file
" Requires:   RefDB
" Parameters: filepath - file to extract db name from
"             filetype - ('makefile'|'initfile')
"             new_db    - new default db
" Returns:    boolean - indicates success of operation
if !exists( "*s:Dbn__AddDefaultRefdbDb" )
function s:Dbn__AddDefaultRefdbDb( filepath, filetype, new_db )
	" construct add command
	let l:cmd = "echo \""
	if a:filetype == "makefile"
		let l:cmd = l:cmd . "database = "
	elseif a:filetype == "initfile"
		let l:cmd = l:cmd . "defaultdb "
	else | return 0 | endif  " error
	let l:cmd = l:cmd . a:new_db . "\" >> " . a:filepath
	" do addition
	call system( l:cmd )
	" check success
	let l:current_db = s:Dbn__GetDefaultRefdbDb( a:filepath, a:filetype )
	if l:current_db == a:new_db
		let l:msg = "Default reference database is now:\n'" 
					\ . l:current_db . "'."
		let l:retval = 1
	else
		let l:msg = "Unable to set reference database -- aborting."
		let l:retval = 0
	endif
	call s:Dbn__ShowMsg( l:msg, "Info" )
	return l:retval
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetNewRefdbDb                                     {{{2
" Purpose:    User can select new default RefDB reference database
" Requires:   RefDB, sed, tr
" Parameters: full_db_list - full list of dbs
"             excluded_db  - db to exclude from list of choices
"             prompt       - selection prompt
" Returns:    string - name of selected database
if !exists( "*s:Dbn__GetNewRefdbDb" )
function s:Dbn__GetNewRefdbDb( full_db_list, prompt, excluded_db )
	" get list of dbs
	let l:db_list = ""  " list of selectable dbs, e.g. all but excluded db
	let l:marker = 0  " marks place as progress through db list
	let l:choices = ""  " list of db choices
	let l:ascii_handle = 96  " ascii code for menu option (a-z, then A-Z)
	let l:exit_flag = 0
	while ! l:exit_flag
		let l:next_space = match( a:full_db_list, " ", l:marker )
		" get new option
		if l:next_space == -1
			let l:exit_flag = 1
			let l:new_option = strpart( a:full_db_list, l:marker )
		else
			let l:new_option = strpart(
						\ 	a:full_db_list,
						\	l:marker,
						\	l:next_space - l:marker
						\ )
			let l:marker = l:next_space + 1
		endif
		" add if not excluded db
		if l:new_option != a:excluded_db
			" separate choices and dbs
			if l:choices != ""
				let l:choices = l:choices . "\n"
				let l:db_list = l:db_list . " "
			endif
			" work out option label ('a'-'z', then 'A'-'Z')
			let l:ascii_handle = l:ascii_handle + 1
			if l:ascii_handle == 123  " exhausted 'a'-'z'
				let l:ascii_handle = 65  " start on 'A'
			elseif l:ascii_handle == 91  " exhausted 'a'-'z' and 'A'-'Z'
				let l:msg = "Cannot handle more than 52 databases.\n"
							\ . "Aborting."
				call s:Dbn__ShowMsg( l:msg, "Error" )
				return
			endif
			" add new option
			let l:mnu_opt = "&" . nr2char( l:ascii_handle )
			let l:mnu_opt = ( has( "gui_running" ) )
						\ ? "(" . l:mnu_opt . ")" : l:mnu_opt
			let l:choices = l:choices
						\ . l:mnu_opt
						\ . " "
						\ . l:new_option
			" add to list of selectable dbs
			let l:db_list = l:db_list . l:new_option
		endif
	endwhile
	" deal with case of single db already selected
	if l:choices == ""
		let l:msg = "There are no other databases to select from.\n"
					\ . "Aborting."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	" make selection
	let l:choice = confirm( a:prompt, l:choices, 1, "Question" )
	" convert selection to db name
	let l:db = ""
	let l:marker = 0
	let l:count = 1
	let l:exit_flag = 0
	while ! l:exit_flag
		let l:next_space = match( l:db_list, " ", l:marker )
		" get next db
		if l:next_space == -1
			let l:exit_flag = 1
			let l:next_db = strpart( l:db_list, l:marker )
		else
			let l:next_db = strpart(
						\ 	l:db_list,
						\ 	l:marker,
						\ 	l:next_space - l:marker
						\ )
			let l:marker = l:next_space + 1
		endif
		" check to see if reached selection
		if l:count == l:choice | let l:db = l:next_db | endif
		let l:count = l:count + 1
	endwhile
	" selection unsucessful
	if l:db == ""
		let l:msg = "Error occurred making selection -- aborting. "
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	" success, return db name
	return l:db
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetNewStyle                                       {{{2
" Purpose:    User can select new document style
" Requires:   RefDB, sed, tr
" Parameters: excluded_style - style to exclude from list of choices
"             prompt         - selection prompt
" Returns:    string - name of selected style
if !exists( "*s:Dbn__GetNewStyle" )
function s:Dbn__GetNewStyle( prompt, excluded_style )
	" get list of styles
	let l:cmd = s:refdba . " -C liststyle 2> /dev/null | "
				\ . "tr '\n' ' ' | sed -e 's/ $//'"
	let l:full_style_list = system( l:cmd )
	if l:full_style_list == ""
		let l:msg = "Unable to retrieve any styles "
					\ . "using refdba/liststyle\n"
					\ . "Aborting."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	let l:style_list = ""  " list of selectable styles, e.g. all but excluded
	let l:marker = 0  " marks place as progress through style list
	let l:choices = ""  " list of style choices
	let l:ascii_handle = 96  " ascii code for menu option (a-z, then A-Z)
	let l:exit_flag = 0
	while ! l:exit_flag
		let l:next_space = match( l:full_style_list, " ", l:marker )
		" get new option
		if l:next_space == -1
			let l:exit_flag = 1
			let l:new_option = strpart( l:full_style_list, l:marker )
		else
			let l:new_option = strpart(
						\ 	l:full_style_list,
						\	l:marker,
						\	l:next_space - l:marker
						\ )
			let l:marker = l:next_space + 1
		endif
		" add if not excluded style
		if l:new_option != a:excluded_style
			" separate choices and styles
			if l:choices != ""
				let l:choices = l:choices . "\n"
				let l:style_list = l:style_list . " "
			endif
			" work out option label ('a'-'z', then 'A'-'Z')
			let l:ascii_handle = l:ascii_handle + 1
			if l:ascii_handle == 123  " exhausted 'a'-'z'
				let l:ascii_handle = 65  " start on 'A'
			elseif l:ascii_handle == 91  " exhausted 'a'-'z' and 'A'-'Z'
				let l:msg = "Cannot handle more than 52 styles.\n"
							\ . "Aborting."
				call s:Dbn__ShowMsg( l:msg, "Error" )
				return
			endif
			" add new option
			let l:mnu_opt = "&" . nr2char( l:ascii_handle )
			let l:mnu_opt = ( has( "gui_running" ) )
						\ ? "(" . l:mnu_opt . ")" : l:mnu_opt
			let l:choices = l:choices
						\ . l:mnu_opt
						\ . " "
						\ . l:new_option
			" add to list of selectable styles
			let l:style_list = l:style_list . l:new_option
		endif
	endwhile
	" deal with case of single style already selected
	if l:choices == ""
		let l:msg = "There are no other styles to select from.\n"
					\ . "Aborting."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	" make selection
	let l:choice = confirm( a:prompt, l:choices, 1, "Question" )
	" convert selection to style name
	let l:style = ""
	let l:marker = 0
	let l:count = 1
	let l:exit_flag = 0
	while ! l:exit_flag
		let l:next_space = match( l:style_list, " ", l:marker )
		" get next style
		if l:next_space == -1
			let l:exit_flag = 1
			let l:next_style = strpart( l:style_list, l:marker )
		else
			let l:next_style = strpart(
						\ 	l:style_list,
						\ 	l:marker,
						\ 	l:next_space - l:marker
						\ )
			let l:marker = l:next_space + 1
		endif
		" check to see if reached selection
		if l:count == l:choice | let l:style = l:next_style | endif
		let l:count = l:count + 1
	endwhile
	" selection unsucessful
	if l:style == ""
		let l:msg = "Error occurred making selection -- aborting. "
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	" success, return style name
	return l:style
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetReferenceFilter                                {{{2
" Purpose:    Build reference filter suitable for cache client command
"             or refdb client
" Requires:   RefDB
" Parameters: client - client to use filter ['cache'|'refdb']
" Returns:    string - filter parameters for cache client command
if !exists( "*s:Dbn__GetReferenceFilter" )
function s:Dbn__GetReferenceFilter( client )
	" check parameters
	if a:client !~ '^cache$\|^refdb$'
		let l:msg = "Plugin error: Invalid parameter '" . a:client 
					\ . "' for 'GetReferenceFilter()'."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return ''
	endif
	" set variables
	let l:author = ''
	let l:title = ''
	let l:exit_opt = '&Neither'
	" get search strings
	while 1
		let l:msg = 'You can filter displayed references'
		let l:opts = l:exit_opt . "\nby &Author\nby &Title"
		let l:choice = confirm( l:msg, l:opts, 1 )
		if l:choice == 2  " by author
			" get author fragment
			let l:msg2 = 'Enter author fragment'
			let l:input = s:Dbn__GetInput( l:msg2, l:author )
			" error check
			if l:input != '' && l:input =~ '^[[:alnum:]_\-:]\+$'
				let l:author = l:input
				" reset option text
				let l:exit_opt = '&Done'
			else
				let l:msg2 = 'Invalid input.  Must be [A-Za-z0-9_-:]'
				call s:Dbn__ShowMsg( l:msg2, "Error" )
			endif
		elseif l:choice == 3  " by title
			" get title fragment
			let l:msg2 = 'Enter title fragment'
			let l:input = s:Dbn__GetInput( l:msg2, l:title )
			" error check
			if l:input != '' && l:input =~ '^[[:alnum:]_\-: ]\+$'
				let l:title = l:input
				" reset option text
				let l:exit_opt = '&Done'
			else
				let l:msg2 = 'Invalid input.  Must be [A-Za-z0-9_-:]'
				call s:Dbn__ShowMsg( l:msg, "Error" )
			endif
		else | break
		endif
	endwhile
	" assemble options
	let l:opts = ''
	if l:author != ''
		if a:client == 'cache'  " cache client
			let l:author = '-a ' . l:author
			let l:opts = ( l:opts == '' ) ? l:author : l:opts . ' ' . l:author
		else  " refdb client
			let l:author = ":AU:~'%" . l:author . "%'"
			let l:opts = ( l:opts == '' ) ? l:author : l:opts
						\ . ' AND ' . l:author
		endif
	endif
	if l:title != ''
		if a:client == 'cache'  " cache client
			let l:title = '-t ' . l:title
			let l:opts = ( l:opts == '' ) ? l:title : l:opts . ' ' . l:title
		else  " refdb client
			let l:title = ":TA:~'%" . l:title . "%'"
			let l:opts = ( l:opts == '' ) ? l:title : l:opts
						\ . ' AND ' . l:title
		endif
	endif
	" final polish
	if a:client == 'cache'  " cache: prepend space
		let l:opts = ' ' . l:opts
	else  " refdb: set default search; prepend space; enclose in quote marks
		if l:opts == '' | let l:opts = ":ID:>0" | endif
		let l:opts = " \"" . l:opts . "\""
	endif
	" return option list
	return l:opts
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetRefIds                                         {{{2
" Purpose:    User can select reference IDs
" Requires:   RefDB
" Parameters: op - type of db operation ('delete'|'edit')
"             db - RefDB database
" Returns:    string - list of reference IDs
if !exists( "*s:Dbn__GetRefIds" )
function s:Dbn__GetRefIds( op, db )
	" set parameter-dependent variables
	if     a:op == 'delete'  " multiple selections possible
		let l:reference = 'references'
		let l:one = 'ones'
		let l:id = 'ID'
	elseif a:op == 'edit'
		let l:reference = 'reference'
		let l:one = 'one'
		let l:id = 'IDs'
	else  " fatal error
		let l:msg = "Plugin error: Invalid 'op' parameter to "
					\ "function 'GetRefIds()'."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return ''
	endif
	" prefer to use cache, but fall back to vimscript if cache disabled
	if s:use_cache  " use cache
		let l:msg = "Plugin error: No matching 'if' block in "
					\ . "'GetRefIds()' for '" . a:op . "'."
		if     a:op == 'delete' | let l:param = ' -d '
		elseif a:op == 'edit'   | let l:param = ' -e '
		else | call s:Dbn__ShowMsg( l:msg, 'Error' ) | return ''
		endif
		" can filter on author and/or title
		let l:cmd = s:cache_client 
					\ . l:param 
					\ . a:db
					\ . s:Dbn__GetReferenceFilter( 'cache' )
		let l:ids = s:Dbn__StripLastChar( system( l:cmd ) )
		if v:shell_error
			if     v:shell_error == 1
				let l:msg = 'No ' . l:reference . ' selected.'
				call s:Dbn__ShowMsg( l:msg, 'Warning' )
			elseif v:shell_error == 2
				let l:msg = 'No references matched search criteria.'
				call s:Dbn__ShowMsg( l:msg, 'Error' )
			else
				let l:msg = "Plugin error: No matching 'if' block "
							\ . "in 'Dbn__GetCitekeys()'."
				call s:Dbn__ShowMsg( l:msg, 'Error' )
			endif
			" set return value to empty string
			let l:ids = ''
		endif
	else  " use vimscript
		" display references
		let l:msg = "Review " . l:reference . " and decide which one to " 
					\ . a:op . "..."
		echo l:msg
		call s:Dbn_Showrefs()  " user makes mental selection
		call s:Dbn_Killrefs()
		let l:msg = "Enter " . l:id . " of " . l:reference . " to " 
					\ . a:op . ": "
		let l:ids = input( l:msg )
		let l:ids = s:Dbn__TrimChar( l:ids )
		echo " "
		" test validity of selected refid(s)
		if a:op == 'edit'  " single refid
			" check is valid integer
			if !s:Dbn__ValidPositiveInteger( l:ids )  " not an integer
				call s:Dbn__ShowMsg( 'Invalid reference ID.', 'Error' )
				let l:ids = ''
			endif
		else  " multiple refids
			" check is valid integer list
			if l:ids !~ '^[1-9]\d*\( [1-9]\d*\)*$'  " not integer list
				call s:Dbn__ShowMsg( 'Invalid reference ID list.', 'Error' )
				let l:ids = ''
			else  " is integer list - check validity of each id
				let l:valid_ids = ''
				let l:ids_copy = l:ids
				while 1
					let l:id = s:Dbn__ListShift( l:ids_copy, 'element' )
					let l:ids_copy = s:Dbn__ListShift( l:ids_copy, 'list' )
					let l:cmd = s:refdbc . " -C getref -d " . a:db 
								\ . " -t scrn \":ID:=" . l:id . "\" 2>&1"
					let l:feedback = s:Dbn__StripLastChar( system( l:cmd ) )
					let l:cmd = "echo \"" . l:feedback . "\" | tail -n 1 | "
								\ . "cut -d ':' -f 2 | cut -d ' ' -f 1"
					let l:matches = system( l:cmd )
					if l:matches == 1  " found matching reference
						let l:valid_ids = ( l:valid_ids == '' ) 
									\ ? l:id 
									\ : l:valid_ids . ' ' . l:id
					else  " no matching reference found
						let l:msg = "Error: Db '" . a:db 
									\ . "' has no reference ID '" 
									\ . l:id . "' -- dropping."
						echo l:msg
					endif
					if l:ids_copy == '' | break | endif
				endwhile
				if l:valid_ids == ''  " inform user of this situation
					let l:msg = 'All IDs were found to be invalid.'
					call s:Dbn__ShowMsg( l:msg, "Error" )
				endif
				let l:ids = l:valid_ids
			endif  " if l:ids !~ '<regex>'
		endif  " if a:op == 'edit'
	endif  " if s:use_cache
	return l:ids
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetCitekeys                                       {{{2
" Purpose:    User can select citation keys
" Requires:   RefDB
" Parameters: NONE
" Returns:    string - list of citekeys
if !exists( "*s:Dbn__GetCitekeys" )
function s:Dbn__GetCitekeys()
	if s:use_cache
		" get citekeys using cache client
		" can filter on author and/or title
		let l:cmd = s:cache_client 
					\ . ' -i ' . s:Dbn__GetCurrentRefdbDb( 1 )
					\ . s:Dbn__GetReferenceFilter( 'cache' )
		let l:citekeys = system( l:cmd )
		if v:shell_error
			if     v:shell_error == 1
				call s:Dbn__ShowMsg( 'No references selected.', 'Warning' )
			elseif v:shell_error == 2
				let l:msg = 'No references matched search criteria.'
				call s:Dbn__ShowMsg( l:msg, 'Error' )
			else
				let l:msg = "Plugin error: No matching 'if' block "
							\ . "in 'Dbn__GetCitekeys()'."
				call s:Dbn__ShowMsg( l:msg, 'Error' )
			endif
			" set return value to empty string
			let l:citekeys = ''
		endif
		" change delimiter from ' ' to ';'
		let l:citekeys = substitute( l:citekeys, ' ', ';', 'g' )
	else
		" get citekeys using script
		let l:cmd = s:get_citekeys . " -d " . s:Dbn__GetCurrentRefdbDb( 1 )
		let l:citekeys = system( l:cmd )
		if v:shell_error
			let l:msg = "Script '"
						\ . s:Dbn__Basename( s:get_citekeys )
						\ . "' failed."
			call s:Dbn__ShowMsg( l:msg, "Error" )
			let l:citekeys = ''
		endif
	endif
	" tidy up answer
	let l:citekeys = s:Dbn__StripLastChar( l:citekeys )
	return l:citekeys
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__RefdbStartupTasks                             {{{2
" Purpose:    Build RefDB client command invocation stubs
" Parameters: NONE
" Returns:    NONE
" Note:       Designed to be run at ftplugin load time
if !exists( "*s:Dbn__RefdbStartupTasks" )
function s:Dbn__RefdbStartupTasks()
	" check refdbc binary is executable
	let l:refdb_location = system( 'which refdbc' )
	if v:shell_error  " refdbc is not executable
		let l:msg = "RefDB does not appear to be available on this system.\n"
					\ . "Unable to find client binary 'refdbc'."
		call s:Dbn__ShowMsg( l:msg, "Warning" )
	else  " refdbc is executable
		echo "RefDB: enabled."
		" test refdbc configuration
		let l:proceed = 0
		if !s:Dbn__RefdbOk()  " can't run refdbc
			" let's try adding username and password
			let l:msg = "Unable to invoke RefDB clients using default "
						\ . "commands.\nThe most common reason is that "
						\ . "username and/or password are required."
			call s:Dbn__ShowMsg( l:msg, "Warning" )
			let l:changed = 0
			let l:old = s:refdb_username
			let l:refdb_username = s:Dbn__GetInput(
						\ 	"Enter username: ", 
						\ 	s:refdb_username 
						\ )
			if l:refdb_username != l:old && l:refdb_username != ''
				let s:refdb_username = l:refdb_username
				let l:changed = 1
			endif
			let l:old = s:refdb_password
			let l:refdb_password = s:Dbn__GetInput(
						\ 	"Enter password: ", 
						\ 	s:refdb_password 
						\ )
			if l:refdb_password != l:old && l:refdb_password != ''
				let s:refdb_password = l:refdb_password
				let l:changed = 1
			endif
			call s:Dbn__BuildCommandStubs()
			" does that help?
			if l:changed  " do another refdbc check
				echon "\nTesting RefDB configuration again... "
				if s:Dbn__RefdbOk()
					echon "OK."
					let l:proceed = 1
				else
					echon "Failed."
				endif
			else
				echon "\nNo changes made to RefDB username or password."
			endif  " do another refdbc check
		else  " can run refdbc
			let l:proceed = 1
		endif
		if !l:proceed
			" can't run 'refdbc'
			let l:msg = "Unable to run RefDB clients.\n"
						\ . "Commands accessing RefDB may fail unpredictably."
			call s:Dbn__ShowMsg( l:msg, "Warning" )
			let s:use_cache = 0
		else
			" RefDB all good, so now deal with cache server ...
			" check whether configured to use cache server
			let s:use_cache = s:Dbn__CacheConfigSetting()
			if s:use_cache
				" we are, so let's run it ...
				if s:Dbn__CacheServerRunning()  " already running
					let l:cache_running = 1
				else  " not running, so start it
					if s:Dbn__CacheServerStart()
						let s:cache_server_started = 1
					else
						let l:msg = "Unable to start RefDB cache server."
						call s:Dbn__ShowMsg( l:msg, "Warning" )
						let s:use_cache = 0
					endif
				endif  " is cache server running
				" ... and try to cache database in background
				if exists( 'l:cache_running' ) 
							\	|| exists( 's:cache_server_started' )
					echo "Caching: enabled."
					call s:Dbn__CacheSetUsernamePassword()
					call s:Dbn__CacheDb()
				endif
			else  " not using cache
				echo "Caching: disabled."
			endif  " 's:use_cache'
		endif  " 'proceed' - able to start RefDB clients
	endif  " is refdbc executable
	sleep 400m  " pause so user can read
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__BuildCommandStubs                             {{{2
" Purpose:    Build RefDB client command invocation stubs
" Parameters: NONE
" Returns:    NONE
if !exists( "*s:Dbn__BuildCommandStubs" )
function s:Dbn__BuildCommandStubs()
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" basic command stubs
	let s:refdbc = 'refdbc'
	let s:refdba = 'refdba'
	let s:get_citekeys = 'dbn-getcitekeys'
	" if specified, then add username parameter
	if s:refdb_username != ''
		let s:refdbc = s:refdbc . ' -u ' . s:refdb_username
		let s:refdba = s:refdba . ' -u ' . s:refdb_username
		let s:get_citekeys = s:get_citekeys . ' -u ' . s:refdb_username
	endif
	" if specified, then add password parameter
	if s:refdb_password != ''
		let s:refdbc = s:refdbc . ' -w ' . s:refdb_password
		let s:refdba = s:refdba . ' -w ' . s:refdb_password
		let s:get_citekeys = s:get_citekeys . ' -w ' . s:refdb_password
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__CacheServerRunning                                {{{2
" Purpose:    Checks for running cache server
" Parameters: NONE
" Returns:    boolean - whether cache server already running
if !exists( "*s:Dbn__CacheServerRunning" )
function s:Dbn__CacheServerRunning()
	" run cache client with 'servercheck' parameter
	call system( s:cache_client . ' -s &> /dev/null' )
	return !v:shell_error
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__CacheServerStart                                  {{{2
" Purpose:    Starts cache server
" Parameters: NONE
" Returns:    boolean - whether cache server successfully running
if !exists( "*s:Dbn__CacheServerStart" )
function s:Dbn__CacheServerStart()
	" start server and pause for it to load
	call system( s:cache_server . ' &' )
	sleep 400m
	" check that server running
	if s:Dbn__CacheServerRunning()
		return 1
	else
		" ? slow machine
		sleep 2
		return s:Dbn__CacheServerRunning()
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__CacheSetUsernamePassword                          {{{2
" Purpose:    Set cache's RefDB username/password
" Parameters: NONE
" Returns:    NONE
if !exists( "*s:Dbn__CacheSetUsernamePassword" )
function s:Dbn__CacheSetUsernamePassword()
	" update cache server with username/password details
	if s:use_cache
		if s:refdb_username != ''
			call system( s:cache_client . ' -u ' . s:refdb_username )
		endif
		if s:refdb_password != ''
			call system( s:cache_client . ' -w ' . s:refdb_password )
		endif
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__CacheConfigSetting                                {{{2
" Purpose:    Extracts config setting for cache use
" Parameters: NONE
" Returns:    boolean - whether using cache server
if !exists( "*s:Dbn__CacheConfigSetting" )
function s:Dbn__CacheConfigSetting()
	" read config file
	let l:cmd = "cat " . s:conffile . " 2> /dev/null | "
				\ . "grep '^cache[[:space:]]\\+\\b[[:alnum:]]\\+\\b.*$' | " 
				\ . "sed -e 's/^cache[[:space:]]\\+\\b"
				\ . "\\([[:alnum:]]\\+\\)\\b/\\1/'"
	let l:setting = s:Dbn__StripLastChar( system( l:cmd ) )
	" return result -- true ('1') unless negative setting detected
	return l:setting =~? '^off$\|^false$\|^no$\|^0$' ? 0 : 1
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__CacheUsing                                        {{{2
" Purpose:    Returns whether using cache
" Parameters: NONE
" Returns:    boolean - whether using cache server
" Notes:      If cache setting is true but cache not running, try to start
if !exists( "*s:Dbn__CacheUsing" )
function s:Dbn__CacheUsing()
	" default is false
	let l:using = 0
	" must have 'use_cache' set to true
	if s:use_cache
		" cache must be running to be used
		if s:Dbn__CacheServerRunning() | let l:using = 1
		else | let l:using = s:Dbn__CacheServerStart()
		endif
	endif
	return l:using
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__CacheDb                                           {{{2
" Purpose:    Starts caching of current RefDB database
" Parameters: silent - (optional) suppress non-error feedback ['1'=suppress]
" Returns:    NONE
if !exists( "*s:Dbn__CacheDb" )
function s:Dbn__CacheDb( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" are we giving feedback?
	let l:talky = 1
	if a:0 > 0 && a:1 == 1 | let l:talky = 0 | endif
	" check database
	let l:db = s:Dbn__GetCurrentRefdbDb( 1 )
	" start cache
	let l:msg = "Caching database: '" . l:db . "'."
	if l:talky | echo l:msg | endif
	let l:cmd = s:cache_client . ' -c ' . l:db . ' &'
	call system( l:cmd )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__CacheServerKill                                   {{{2
" Purpose:    Stops (kills) cache server
" Parameters: NONE
" Returns:    boolean - whether cache server successfully stopped
if !exists( "*s:Dbn__CacheServerKill" )
function s:Dbn__CacheServerKill()
	echo "Shutting down cache server."
	" send kill instruction
	call system( s:cache_client . ' -k' )
	" exit status determined by checking whether server running
	return !s:Dbn__CacheServerRunning()
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__InsertTableEngine                                 {{{2
" Purpose:    Insert table skeleton
" Parameters: type        - table type (formal|informal)
"             title       - table title
"             titleabbrev - abbreviated title
"             label       - table label
"             columns     - integer number of columns
"             rows        - integer number of rows
"             help        - whether to include help comments (1|0)
" Returns:    NONE
if !exists( "*s:Dbn__InsertTableEngine" )
function s:Dbn__InsertTableEngine( type, title, titleabbrev,
			\ label, columns, rows, help )
	" check parameters
	if a:type != "formal" && a:type != "informal"
		echo "Error: Invalid table type: must be \"formal|informal\""
		return
	elseif a:type == "formal" && a:title == ""
		echo "Error: Formal table must have title"
		return
	elseif a:label == ""
		echo "Error: Table must have label"
		return
	elseif !s:Dbn__ValidPositiveInteger( a:columns )
				\ || !s:Dbn__ValidPositiveInteger( a:rows )
		echo "Error: Row and column numbers must be positive integers"
		return
	elseif a:help != "1" && a:help != "0"
		echo "Error: Invalid help flag: must be \"1|0\""
		return
	endif
	" set tag name
	if a:type == "formal"  | let l:tagname = "table"
	else                   | let l:tagname = "informaltable"
	endif
	" add initial tag
	silent execute "normal o<"
				\ . l:tagname
				\ . " id=,\""
				\ . a:label
				\ . ",\" pgwide=,\"0,\" rowsep=,\"1,\""
				\ . " colsep=,\"0,\" orient=,\"port,\""
				\ . " frame=,\"none,\" shortentry=,\"1,\""
				\ . " tocentry=,\"1,\">>\<Esc>dd"
	" add 'title' and 'titleabbrev' if formal table
	if a:type == "formal"
		silent execute "normal O<title>"
					\ . a:title
					\ . "\<Esc>o<titleabbrev>"
					\ . a:titleabbrev
					\ . "\<Esc>j"
	endif
	" add comments if requested to
	if a:help
		silent execute "normal O<!,-,-\<CR>"
					\ . "TABLE   colsep    rule between columns\<CR>"
					\ . "        frame     ,"
					\ . "'all|bottom|none|sides|top|topnot,'\<CR>"
					\ . "orient    ,'land|port,'\<CR>"
					\ . "pgwide    full page (,'1,')"
					\ . " or text column (,'0,')\<CR>"
					\ . "rowsep    rule between columns\<CR>"
					\ . "shorttoc  use ,'titleabbrev,' instead of ,'title,'"
					\ . " for LoT, etc.\<CR>"
					\ . "tocentry  whether added to generated"
					\ . " List of Tables\<CR>" 
					\ . "\<BS>\<BS>TGROUP  align     horizontal"
					\ . " alignment\<CR>"
					\ . "                  "
					\ . ",'center|justify|right|left|char,'\<CR>"
					\ . "if ,'char,' uses ,'char,' and ,'charoff,'\<CR>"
					\ . "\<BS>\<BS>\<BS>\<BS>char      "
					\ . "horizontal alignment\<CR>"
					\ . "charoff   percent (left) offset"
					\. " of cell contents\<CR>"
					\ . "\<BS>\<BS>COLSPEC colwidth  absolute "
					\ . "(px, em, etc.) or proportional (x*)\<CR>"
					\. ",-,->\<Esc>j"
	endif
	" add 'tgroup'
	silent execute "normal O<tgroup cols=,\""
				\ . a:columns
				\ . ",\" align=,\"left,\">>\<Esc>dd"
	" add 'colspec'
	let l:colnum = 1
	while l:colnum <= a:columns
		silent execute "normal O<colspec colnum=,\""
					\ . l:colnum
					\ . ",\" colname=,\"c"
					\ . l:colnum
					\ . ",\" colwidth=,\"1*,\"/>\<Esc>j"
		let l:colnum = l:colnum + 1
	endwhile
	" add 'thead'
	silent execute "normal O<thead valign=,\"top,\">>\<Esc>dd"
	" add header row and mark first entry to position cursor at end
	silent execute "normal O<row>>\<Esc>dd"
	let l:colnum = 1
	while l:colnum <= a:columns
		silent execute "normal O<entry>"
		if l:colnum == 1 | silent execute "normal mz" | endif
		silent execute "normal j"
		let l:colnum = l:colnum + 1
	endwhile
	silent execute "normal 2j"
	" add 'tbody'
	silent execute "normal O<tbody valign=,\"top,\">>\<Esc>dd"
	let l:rownum = 1
	while l:rownum <= a:rows
		silent execute "normal O<row>>\<Esc>dd"
		let l:colnum = 1
		while l:colnum <= a:columns
			silent execute "normal O<entry>\<Esc>j"
			let l:colnum = l:colnum + 1
		endwhile
		let l:rownum = l:rownum + 1
		silent execute "normal j"
	endwhile
	" position cursor at first header row
	silent execute "normal `z"
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__InsertXmlEntity                                   {{{2
" Purpose:    Insert xml entity at current location
" Parameters: tagname        - element name
"             attributes     - string holding all attributes and their values
"             entity_content - element content
" Returns:    NONE
if !exists( "*s:Dbn__InsertXmlEntity" )
function s:Dbn__InsertXmlEntity( tagname, attributes, content )
	let l:entity = s:Dbn__BuildXmlEntity(
				\ 	a:tagname,
				\ 	a:attributes,
				\ 	a:content
				\ )
	call s:Dbn__InsertString( l:entity, 1 )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ExtractElementAttribute                           {{{2
" Purpose:    Returns value of specified element attribute
" Parameters: element   - element to be searched
"             attribute - name of attribute value to extract
" Returns:    value of specified attribute
if !exists( "*s:Dbn__ExtractElementAttribute" )
function s:Dbn__ExtractElementAttribute( element, attribute )
	" find start of attribute value
	let l:att_start = matchend( a:element, a:attribute . '="' )
	if l:att_start == -1  " attribute not found
		let l:attribute_value = ''
	else  " attribute found
		let l:att_length = match( a:element, '"', l:att_start ) - l:att_start
		let l:attribute_value = strpart( a:element, l:att_start, l:att_length )
	endif
	" report result
	return l:attribute_value
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__UtilityMissing                                    {{{2
" Purpose:    Checks whether program missing
" Parameters: utility - the program to test for
" Returns:    boolean - indicating missing (>0) or present (0)
if !exists( "*s:Dbn__UtilityMissing" )
function s:Dbn__UtilityMissing( utility )
	" get testing command
	if     a:utility == "enscript"    | let l:cmd = "enscript --version"
	elseif a:utility == "display"     | let l:cmd = "display -version"
	elseif a:utility == "groff"       | let l:cmd = "groff --version"
	elseif a:utility == "grops"       | let l:cmd = "grops --version"
	else
		let l:msg = "Fatal error in function "
					\ . "'Dbn_UtilityPresent'\n"
					\ . "No rule for parameter "
					\ . "'" . a:utility . "'."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return 0
	endif
	" run test
	call system( l:cmd )
	" report result
	return v:shell_error
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ViewFile                                          {{{2
" Purpose:    View file in external viewer
" Parameters: file   - filename of file to view
"             format - file format ('html'|'xhtml'|'pdf'|'text'
" Returns:    NONE
if !exists( "*s:Dbn__ViewFile" )
function s:Dbn__ViewFile( file, format )
	" check parameters
	if !filereadable( a:file )
		let l:msg = "Cannot locate file '" . a:file . "'."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	if a:format !~ '^html$\|^xhtml$\|^pdf$\|^text$'
		let l:msg = "Invalid file format ('" . a:format . "')."
		call s:Dbn__ShowMsg( l:msg, "Error" )
		return
	endif
	" determine viewer
	if     a:format =~ '^html$\|^xhtml$'
		let l:viewer = s:viewer_html_x
		let l:viewer_name = s:viewer_html_x_name
	elseif a:format =~ '^pdf$'
		let l:viewer = s:viewer_pdf
		let l:viewer_name = s:viewer_pdf_name
	elseif a:format =~ '^text$'
		let l:viewer = s:viewer_text
		let l:viewer_name = s:viewer_text_name
	else
		let l:msg = "Unable to determine viewer for file '" . a:file . "'."
		call s:Dbn__ShowMsg( l:msg, "Error" )
	endif
	" view file
	let l:msg = "Starting " . a:format . " viewer: " . l:viewer_name . "."
	echo l:msg
	let l:cmd = l:viewer . " " . a:file . " &"
	call system( l:cmd )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__GetValue                                          {{{2
" Purpose:    Retrieve variable value from 'dbn-getvalue' shell script
" Parameters: name       - filename of file to view
"             param1 ... - additional parameters to pass to 'dbn-getvalue'
" Returns:    string     - variable value
if !exists( "*s:Dbn__GetValue" )
function s:Dbn__GetValue( name, ... )
	" build retrieval command
	let l:cmd = "dbn-getvalue -n " . a:name
	" max. of 19 additional arguments can be passed
	if a:0 >= 1  | let l:cmd = l:cmd . ' "' . a:1  . '"' | endif
	if a:0 >= 2  | let l:cmd = l:cmd . ' "' . a:2  . '"' | endif
	if a:0 >= 3  | let l:cmd = l:cmd . ' "' . a:3  . '"' | endif
	if a:0 >= 4  | let l:cmd = l:cmd . ' "' . a:4  . '"' | endif
	if a:0 >= 5  | let l:cmd = l:cmd . ' "' . a:5  . '"' | endif
	if a:0 >= 6  | let l:cmd = l:cmd . ' "' . a:6  . '"' | endif
	if a:0 >= 7  | let l:cmd = l:cmd . ' "' . a:7  . '"' | endif
	if a:0 >= 8  | let l:cmd = l:cmd . ' "' . a:8  . '"' | endif
	if a:0 >= 9  | let l:cmd = l:cmd . ' "' . a:9  . '"' | endif
	if a:0 >= 10 | let l:cmd = l:cmd . ' "' . a:10 . '"' | endif
	if a:0 >= 11 | let l:cmd = l:cmd . ' "' . a:11 . '"' | endif
	if a:0 >= 12 | let l:cmd = l:cmd . ' "' . a:12 . '"' | endif
	if a:0 >= 14 | let l:cmd = l:cmd . ' "' . a:14 . '"' | endif
	if a:0 >= 15 | let l:cmd = l:cmd . ' "' . a:15 . '"' | endif
	if a:0 >= 16 | let l:cmd = l:cmd . ' "' . a:16 . '"' | endif
	if a:0 >= 17 | let l:cmd = l:cmd . ' "' . a:17 . '"' | endif
	if a:0 >= 18 | let l:cmd = l:cmd . ' "' . a:18 . '"' | endif
	if a:0 >= 19 | let l:cmd = l:cmd . ' "' . a:19 . '"' | endif
	" run retrieval command
	return s:Dbn__StripLastChar( system( l:cmd ) )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__InstallDocumentation                              {{{2
" Purpose:    Install help documentation
" Parameters: full_name  - filepath of this vim plugin script
" Returns:    boolean    - indicating whether help doc installed (1|0)
" Credits:    Document installation mechanism copied from 'xml.vim'
"             xml.vim maintainer: Devin Weaver
"             author of 'self-install' code: Guo-Peng Wen
if !exists( "*s:Dbn__InstallDocumentation" )
function s:Dbn__InstallDocumentation( full_name )
    " name of the document path based on the system we use
    if (has("unix"))
		" on *nix systems use '/'
		let l:slash_char = '/'
		let l:mkdir_cmd  = ':silent !mkdir -p '
    else
		" on MS systems (w2k and later) use '\'; also different mkdir syntax
		let l:slash_char = '\'
		let l:mkdir_cmd  = ':silent !mkdir '
    endif
    let l:doc_path = l:slash_char . 'doc'
    let l:doc_home = l:slash_char . '.vim' . l:slash_char . 'doc'
    " figure out document path based on full name of this script
    let l:vim_plugin_path = fnamemodify(a:full_name, ':h')
    let l:vim_doc_path	  = fnamemodify(a:full_name, ':h:h') . l:doc_path
    if ( !( filewritable( l:vim_doc_path ) == 2 ) )
		echomsg "Doc path: " . l:vim_doc_path
		execute l:mkdir_cmd . l:vim_doc_path
		if ( !( filewritable( l:vim_doc_path ) == 2 ) )
			" try a default configuration in user home
			let l:vim_doc_path = expand( "~" ) . l:doc_home
			if ( !( filewritable( l:vim_doc_path ) == 2 ) )
				execute l:mkdir_cmd . l:vim_doc_path
				if ( !( filewritable( l:vim_doc_path ) == 2 ) )
					" give a warning
					echomsg "Unable to open documentation directory"
					echomsg " type :help add-local-help for more informations."
					return 0
				endif
			endif
		endif
    endif
    " exit if we have problem accessing the document directory:
    if ( !isdirectory( l:vim_plugin_path )
				\ || !isdirectory( l:vim_doc_path )
				\ || filewritable( l:vim_doc_path ) != 2 )
		return 0
    endif
    " full name of script and documentation file
    let l:script_name = 'docbk.vim'
    let l:doc_name    = 'docbk-plugin.txt'
    let l:plugin_file = l:vim_plugin_path . l:slash_char . l:script_name
    let l:doc_file    = l:vim_doc_path	  . l:slash_char . l:doc_name
    " bail out if document file is still up to date
    if ( filereadable( l:doc_file )  &&
				\ getftime( l:plugin_file ) < getftime( l:doc_file ) )
		return 0
    endif
    " prepare window position restoring command
    if ( strlen( @% ) )
		let l:go_back = 'b ' . bufnr( "%" )
    else
		let l:go_back = 'enew!'
    endif
    " create a new buffer & read in the plugin file (me)
    setl nomodeline
    exe 'enew!'
    exe 'r ' . l:plugin_file
    setl modeline
    let l:buf = bufnr("%")
    setl noswapfile modifiable
    norm zR
    norm gg
    " delete from first line to a line starts with '=== START_DOC'
    1,/^=\{3,}\s\+START_DOC\C/ d
    " delete from a line starts with '=== END_DOC' to the end of doc
    /^=\{3,}\s\+END_DOC\C/,$ d
    " remove fold marks
    % s/{\{3}[1-9]/    /
    " add modeline for help doc (mangled intentionally)
    call append(line('$'), '')
    call append(line('$'), '')
    call append(line('$'), ' v' . 'im:tw=78:ts=8:ft=help:norl:')
    " save the help document
    exe 'w! ' . l:doc_file
    exe l:go_back
    exe 'bw ' . l:buf
    " build help tags
    exe 'helptags ' . l:vim_doc_path
	" installed doc successfully
    return 1
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Dbn__ShutdownPlugin                                    {{{2
" Purpose:    Run cleanup tasks before shutting down plugin
" Parameters: NONE
" Returns:    NONE
if !exists( "*s:Dbn__ShutdownPlugin" )
function s:Dbn__ShutdownPlugin()
	echo "Shutting down docbook-xml ftplugin..."
	" close any reference displays
	call s:Dbn_Killrefs()
	" shutdown cache server if started by plugin
	if exists( 's:cache_server_started' ) && s:cache_server_started == 1
		call s:Dbn__CacheServerKill()
	endif
endfunction
endif  " function wrapper

" ========================================================================

" __4. SCRIPT VARIABLES                                              {{{1

" Package root directory
let s:dbn_root = s:Dbn__GetValue( "dbn_root" )

" Viewer -- html -- graphical
let s:viewer_html_x = s:Dbn__GetValue( "viewer_html_x" )
let s:viewer_html_x_name = s:Dbn__GetValue( "viewer_html_x_name" )

" Viewer -- html -- console
let s:viewer_html_c = s:Dbn__GetValue( "viewer_html_c", "", "", "" )
let s:viewer_html_c_name = s:Dbn__GetValue( "viewer_html_c" )

" Viewer -- pdf
let s:viewer_pdf = s:Dbn__GetValue( "viewer_pdf" )
let s:viewer_pdf_name = s:Dbn__GetValue( "viewer_pdf_name" )

" Viewer -- text
let s:viewer_text = s:Dbn__GetValue( "viewer_text" )
let s:viewer_text_name = s:Dbn__GetValue( "viewer_text_name" )

" Editor
let s:editor = s:Dbn__GetValue( "editor" )
let s:editor_name = s:Dbn__GetValue( "editor_name" )

" DBTDG (DocBook - The Definitive Guide) -- location
" currently set to default for Debian package 'docbook-defguide'
let s:dbtdg_root = s:Dbn__GetValue( "dbtdg_root" )

" External scripts
let s:get_filepath = "dbn-getfilepath"
let s:menu_select = "dbn-menuselect"
let s:xmllint_wrap = "dbn-xmllintwrap"
let s:get_citekeys = "dbn-getcitekeys"
let s:makefile = s:dbn_root . "/dbn_Makefile"
let s:helpfile = s:dbn_root . "/help.tr"
let s:conffile = "${prefix}/etc/vim-docbk-xml-refdb/config"
let s:cache_server = "refdb-cache-server"
let s:cache_client = "refdb-cache-client"

" Use of additional tools
let s:use_saxon_xerces = 0
let s:use_xalan = 0
let s:use_xep = 0
let s:use_rxp = 0
let s:use_custom_xsl = 0
let s:use_refdb = 1
let s:use_cache = ( s:use_refdb == 1 ) ? 1 : 0  " if using refdb, use cache
let s:refdbc = 'refdbc'
let s:refdba = 'refdba'
let s:refdb_username = ''
let s:refdb_password = ''

" Message strings
let s:no_refdb = "RefDB support is not available.\n"
			\ . "Either the plugin was compiled without RefDB support\n"
			\ . "this is a non-RefDB document."

" ========================================================================

" __5. CONTROL STATEMENTS                                            {{{1

" set the shutdown sequence
augroup xml_helper
"   BufUnload:
"   BufDelete:
"   kill any reference displays
	au! BufUnload,BufDelete *.xml
				\ call s:Dbn__ShutdownPlugin()
augroup END

" restore user's cpoptions
let &cpo = s:save_cpo

" install documentation
let s:installed = s:Dbn__InstallDocumentation( expand( "<sfile>:p" ) )
if ( s:installed == 1 )
    let msg = expand( "<sfile>:t:r" )
  			  \ . "-plugin: Help-documentation installed."
    echom msg
endif

" no refdb mappings if not a refdb file
if !s:Dbn__EditingRefdbDoc() | let s:use_refdb = 0 | endif

" refdb startup checks if appropriate
if s:use_refdb | call s:Dbn__RefdbStartupTasks() | endif

" requires xml ftplugin
runtime ftplugin/xml.vim

" ========================================================================

" _6. MAPPINGS AND MENUS                                            {{{1

" User can prevent mappings by setting these variables
if !exists("no_plugin_maps") && !exists("no_docbk_maps")

" Book Structure:                                                    {{{2
"	Declaration (,dtbk)                                              {{{3
if !hasmapto( '<Plug>DbnDtbkI' )
	imap <buffer> <unique> ,dtbk <Plug>DbnDtbkI
endif
inoremap <buffer> <unique> <Plug>DbnDtbkI <Esc>:call
			\ <SID>Dbn_InsertDoctypeDecl( "book" )<CR>
inoremenu <silent> 500.10.10 
			\ &DocBook.&Main\ Structure.&Book\ Declaration<Tab>,dtbk 
			\ <Esc>:call <SID>Dbn_InsertDoctypeDecl( "book" )<CR>
"	Structure (,bk)                                                  {{{3
"	- requires function: 'Dbn_InsertDocStructure'
if !hasmapto( '<Plug>DbnBkI' )
	imap <buffer> <unique> ,bk <Plug>DbnBkI
endif
inoremap <buffer> <unique> <Plug>DbnBkI <Esc>:call
			\ <SID>Dbn_InsertDocStructure(
			\ "book",	"",	"",	"",	"",	"[NULL]" )<CR>
inoremenu <silent> 500.10.20
			\ &DocBook.&Main\ Structure.B&ook\ Structure<Tab>,bk 
			\ <Esc>:call <SID>Dbn_InsertDocStructure(
			\ "book", "", "", "", "", "[NULL]" )<CR>

" Article Structure:                                                 {{{2
"	Declaration (,dtar)                                              {{{3
if !hasmapto( '<Plug>DbnDtarI' )
	imap <buffer> <unique> ,dtar <Plug>DbnDtarI
endif
inoremap <buffer> <unique> <Plug>DbnDtarI <Esc>:call
			\ <SID>Dbn_InsertDoctypeDecl( "article" )<CR>
inoremenu <silent> 500.10.30
			\ &DocBook.&Main\ Structure.&Article\ Declaration<Tab>,dtar
			\ <Esc>:call <SID>Dbn_InsertDoctypeDecl( "article" )<CR>
"	Structure (,ar)                                                  {{{3
"	- requires function: 'Dbn_InsertDocStructure'
if !hasmapto( '<Plug>DbnArI' )
	imap <buffer> <unique> ,ar <Plug>DbnArI
endif
inoremap <script> <unique> <Plug>DbnArI <Esc>:call 
			\ <SID>Dbn_InsertDocStructure(
			\ "article", "", "", "", "", "[NULL]" )<CR>
inoremenu <silent> 500.10.40
			\ &DocBook.&Main\ Structure.Article\ &Structure<Tab>,ar
			\ <Esc>:call <SID>Dbn_InsertDocStructure(
			\ "article", "", "", "", "", "[NULL]" )<CR>

" Major Document Divisions:                                          {{{2
" - requires function: 'Dbn_InsertDivision'
"   chapter (,ch)                                                    {{{3
if !hasmapto( '<Plug>DbnChI' )
	imap <buffer> <unique> ,ch <Plug>DbnChI
endif
inoremap <script> <unique> <Plug>DbnChI <Esc>:call <SID>Dbn_InsertDivision(
			\ "chapter", "chapter", "ch:" )<CR>
inoremenu <silent> 500.20.10 
			\ &DocBook.Ma&jor\ Divisions.&Chapter<Tab>,ch 
			\ <Esc>:call <SID>Dbn_InsertDivision(
			\ "chapter", "chapter", "ch:" )<CR>
"   section (,se)                                                    {{{3
if !hasmapto( '<Plug>DbnSeI' )
	imap <buffer> <unique> ,se <Plug>DbnSeI
endif
inoremap <script> <unique> <Plug>DbnSeI <Esc>:call <SID>Dbn_InsertDivision(
			\ "section", "section", "se:" )<CR>
inoremenu <silent> 500.20.20 
			\ &DocBook.Ma&jor\ Divisions.&Section<Tab>,se 
			\ <Esc>:call <SID>Dbn_InsertDivision(
			\ "section", "section", "se:" )<CR>
"   sect1 (,s1)                                                      {{{3
if !hasmapto( '<Plug>DbnS1I' )
	imap <buffer> <unique> ,s1 <Plug>DbnS1I
endif
inoremap <script> <unique> <Plug>DbnS1I <Esc>:call <SID>Dbn_InsertDivision(
			\ "sect1", "section", "s1:" )<CR>
inoremenu <silent> 500.20.30 
			\ &DocBook.Ma&jor\ Divisions.Sect&1<Tab>,s1 
			\ <Esc>:call <SID>Dbn_InsertDivision(
			\ "sect1", "section", "s1:" )<CR>
"   sect2 (,s2)                                                      {{{3
if !hasmapto( '<Plug>DbnS2I' )
	imap <buffer> <unique> ,s2 <Plug>DbnS2I
endif
inoremap <script> <unique> <Plug>DbnS2I <Esc>:call <SID>Dbn_InsertDivision(
			\ "sect2", "subsection", "s2:" )<CR>
inoremenu <silent> 500.20.40 
			\ &DocBook.Ma&jor\ Divisions.Sect&2<Tab>,s2 
			\ <Esc>:call <SID>Dbn_InsertDivision(
			\ "sect2", "section", "s2:" )<CR>
"   sect3 (,s3)                                                      {{{3
if !hasmapto( '<Plug>DbnS3I' )
	imap <buffer> <unique> ,s3 <Plug>DbnS3I
endif
inoremap <script> <unique> <Plug>DbnS3I <Esc>:call <SID>Dbn_InsertDivision(
			\ "sect3", "subsubsection", "s3:" )<CR>
inoremenu <silent> 500.20.40 
			\ &DocBook.Ma&jor\ Divisions.Sect&3<Tab>,s3 
			\ <Esc>:call <SID>Dbn_InsertDivision(
			\ "sect3", "section", "s3:" )<CR>

" Minor Structures:                                                  {{{2
"	para (,p)                                                        {{{3
if !hasmapto( '<Plug>DbnPI' )
	imap <buffer> <unique> ,p <Plug>DbnPI
endif
imap <buffer> <unique> <Plug>DbnPI <para>
imenu 500.30.10 &DocBook.M&inor\ Structures.&Para<Tab>,p <para>
if !hasmapto( '<Plug>DbnPV' )
	vmap <buffer> <unique> ,p <Plug>DbnPV
endif
vnoremap <script> <unique> <Plug>DbnPV "zx:call <SID>Dbn_SurroundSelection(
			\ @z, "<para>", "</para>" )<CR>
vnoremenu 500.30.10 &DocBook.M&inor\ Structures.&Para<Tab>,p 
			\ "zx:call <SID>Dbn_SurroundSelection(
			\ @z, "<para>", "</para>" )<CR>
"	comment (,co)                                                    {{{3
"	- requires function: 'Dbn_InsertStructure'
"	- requires function: 'Dbn_SurroundSelection'
if !hasmapto( '<Plug>DbnCoI' )
	imap <buffer> <unique> ,co <Plug>DbnCoI
endif
inoremap <script> <unique> <Plug>DbnCoI <Esc>:call <SID>Dbn_InsertStructure( 
			\ "<!-- ", " -->", "Enter comment: ", "\<!--  --\>", "4h" )<CR>
inoremenu <silent> 500.30.20 
			\ &DocBook.M&inor\ Structures.&Comment<Tab>,co 
			\ <Esc>:call <SID>Dbn_InsertStructure( 
			\ "<!-- ", " -->", "Enter comment: ", "\<!--  --\>", "4h" )<CR>
if !hasmapto( '<Plug>DbnCoV' )
	vmap <buffer> <unique> ,co <Plug>DbnCoV
endif
vnoremap <script> <unique> <Plug>DbnCoV
			\ "zx:call <SID>Dbn_SurroundSelection( @z, "<!-- ", " -->" )<CR>
vnoremenu <silent> 500.30.20 
			\ &DocBook.M&inor\ Structures.&Comment<Tab>,co 
			\ "zx:call <SID>Dbn_SurroundSelection( @z, "<!-- ", " -->" )<CR>
"	blockquote (,qu)                                                 {{{3
if !hasmapto( '<Plug>DbnQuI' )
	imap <buffer> <unique> ,qu <Plug>DbnQuI
endif
imap <buffer> <unique> <Plug>DbnQuI
			\ <blockquote>><attribution><Esc>$a<CR><literallayout><Esc>k$bba
imenu <silent> 500.30.30 
			\ &DocBook.M&inor\ Structures.&Quote<Tab>,qu 
			\ <blockquote>><attribution><Esc>$a<CR><literallayout><Esc>k$bba
"	footnote (,ftn)                                                  {{{3
"	- requires function: 'Dbn_InsertStructure'
"	- requires function: 'Dbn_SurroundSelection'
if !hasmapto( '<Plug>DbnFtnI' )
	imap <buffer> <unique> ,ftn <Plug>DbnFtnI
endif
inoremap <script> <unique> <Plug>DbnFtnI <Esc>:call
			\ <SID>Dbn_InsertStructure(
			\ 	"<footnote><para>",
			\ 	"</para></footnote>",
			\ 	"Enter footnote: ",
			\ 	"\<footnote\>\<para\>",
			\ 	""
			\ )<CR>
inoremenu <silent> 500.30.40 
			\ &DocBook.M&inor\ Structures.&Footnote<Tab>,ftn 
			\ <Esc>:call <SID>Dbn_InsertStructure(
			\ 	"<footnote><para>",
			\ 	"</para></footnote>",
			\ 	"Enter footnote: ",
			\ 	"\<footnote\>\<para\>",
			\ 	""
			\ )<CR>
if !hasmapto( '<Plug>DbnFtnV' )
	vmap <buffer> <unique> ,ftn <Plug>DbnFtnV
endif
vnoremap <script> <unique> <Plug>DbnFtnV "zx:call
			\ <SID>Dbn_SurroundSelection(
			\ @z, "<footnote><para>", "</para></footnote>" )<CR>
vnoremenu <silent> 500.30.40 
			\ &DocBook.M&inor\ Structures.&Footnote<Tab>,ftn 
			\ "zx:call <SID>Dbn_SurroundSelection(
			\ @z, "<footnote><para>", "</para></footnote>" )<CR>
"	author (,au)                                                     {{{3
if !hasmapto( '<Plug>DbnAuI' )
	imap <buffer> <unique> ,au <Plug>DbnAuI
endif
imap <script> <unique> <Plug>DbnAuI <Esc>:call <SID>Dbn_InsertAuthor()<CR>
imenu <silent> 500.30.50 
			\ &DocBook.M&inor\ Structures.&Author<Tab>,au 
			\ <Esc>:call <SID>Dbn_InsertAuthor()<CR>
"	revision (,rv)                                                   {{{3
if !hasmapto( '<Plug>DbnRvI' )
	imap <buffer> <unique> ,rv <Plug>DbnRvI
endif
imap <script> <unique> <Plug>DbnRvI <Esc>:call <SID>Dbn_InsertRevision()<CR>
imenu <silent> 500.30.60 
			\ &DocBook.M&inor\ Structures.&Revision<Tab>,rv 
			\ <Esc>:call <SID>Dbn_InsertRevision()<CR>
"	note (,no)                                                       {{{3
if !hasmapto( '<Plug>DbnNoI' )
	imap <buffer> <unique> ,no <Plug>DbnNoI
endif
inoremap <script> <unique> <Plug>DbnNoI <Esc>:call
			\ <SID>Dbn_InsertStructure(
			\ 	"<note><para>",
			\ 	"</para></note>",
			\ 	"Enter note: ",
			\ 	"\<note\>\>\<para\>",
			\ 	""
			\ )<CR>
inoremenu <silent> 500.30.70 
			\ &DocBook.M&inor\ Structures.&Note<Tab>,no 
			\ <Esc>:call <SID>Dbn_InsertStructure(
			\ 	"<note><para>",
			\ 	"</para></note>",
			\ 	"Enter note: ",
			\ 	"\<note\>\>\<para\>",
			\ 	""
			\ )<CR>
"	warning (,wa)                                                    {{{3
if !hasmapto( '<Plug>DbnWaI' )
	imap <buffer> <unique> ,wa <Plug>DbnWaI
endif
inoremap <script> <unique> <Plug>DbnWaI <Esc>:call
			\ <SID>Dbn_InsertStructure(
			\ 	"<warning><para>",
			\ 	"</para></warning>",
			\ 	"Enter warning: ",
			\ 	"\<warning\>\>\<para\>",
			\ 	""
			\ )<CR>
inoremenu <silent> 500.30.80 
			\ &DocBook.M&inor\ Structures.&Warning<Tab>,wa 
			\ <Esc>:call <SID>Dbn_InsertStructure(
			\ 	"<warning><para>",
			\ 	"</para></warning>",
			\ 	"Enter warning: ",
			\ 	"\<warning\>\>\<para\>",
			\ 	""
			\ )<CR>
"	sidebar (,sb)                                                    {{{3
if !hasmapto( '<Plug>DbnSbI' )
	imap <buffer> <unique> ,sb <Plug>DbnSbI
endif
inoremap <script> <unique> <Plug>DbnSbI <Esc>:call
			\ <SID>Dbn_InsertDivision( "sidebar", "sidebar", "sb:" )<CR>
inoremenu <silent> 500.30.90 
			\ &DocBook.M&inor\ Structures.&Sidebar<Tab>,sb 
			\ <Esc>:call <SID>Dbn_InsertDivision(
			\ "sidebar", "sidebar", "sb:" )<CR>
"	example (,ex)                                                    {{{3
if !hasmapto( '<Plug>DbnExI' )
	imap <buffer> <unique> ,ex <Plug>DbnExI
endif
inoremap <script> <unique> <Plug>DbnExI <Esc>:call
			\ <SID>Dbn_InsertDivision( "example", "example", "ex:" )<CR>
inoremenu <silent> 500.30.100 
			\ &DocBook.M&inor\ Structures.&Example<Tab>,ex 
			\ <Esc>:call <SID>Dbn_InsertDivision(
			\ "example", "example", "ex:" )<CR>
"	filename (,fn)                                                   {{{3
if !hasmapto( '<Plug>DbnFnI' )
	imap <buffer> <unique> ,fn <Plug>DbnFnI
endif
inoremap <script> <unique> <Plug>DbnFnI <Esc>:call
			\ <SID>Dbn_InsertStructure(
			\ 	"<filename>",
			\ 	"</filename>",
			\ 	"Enter filename: ",
			\ 	"\<filename\>",
			\ 	""
			\ )<CR>
inoremenu <silent> 500.30.110 
			\ &DocBook.M&inor\ Structures.&Filename<Tab>,fn 
			\ <Esc>:call <SID>Dbn_InsertStructure(
			\ 	"<filename>",
			\ 	"</filename>",
			\ 	"Enter filename: ",
			\ 	"\<filename\>",
			\ 	""
			\ )<CR>
if !hasmapto( '<Plug>DbnFnV' )
	vmap <buffer> <unique> ,fn <Plug>DbnFnV
endif
vnoremap <script> <unique> <Plug>DbnFnV "zx:silent call
			\ <SID>Dbn_SurroundSelection(
			\ @z, "<filename>", "</filename>" )<CR>
vnoremenu <silent> 500.30.110 
			\ &DocBook.M&inor\ Structures.&Filename<Tab>,fn 
			\ "zx:silent call <SID>Dbn_SurroundSelection(
			\ @z, "<filename>", "</filename>" )<CR>
"	programlisting/"verbatim" (,vb)                                  {{{3
if !hasmapto( '<Plug>DbnVbI' )
	imap <buffer> <unique> ,vb <Plug>DbnVbI
endif
imap <buffer> <unique> <Plug>DbnVbI
			\ <programlisting>><![CDATA[<CR><CR>]]><Esc>kI
imenu <silent> 500.30.120 
			\ &DocBook.M&inor\ Structures.&Verbatim<Tab>,vb 
			\ <programlisting>><![CDATA[<CR><CR>]]><Esc>kI
"	- next mapping results in 'press-enter' message, reason unknown
if !hasmapto( '<Plug>DbnVbV' )
	vmap <buffer> <unique> ,vb <Plug>DbnVbV
endif
vnoremap <script> <unique> <Plug>DbnVbV "zx:silent call
			\ <SID>Dbn_SurroundSelection(
			\ 	@z, "<programlisting><![CDATA[",
			\ 	"]]></programlisting>"
			\ )<CR>
vnoremenu <silent> 500.30.120 
			\ &DocBook.M&inor\ Structures.&Verbatim<Tab>,vb 
			\ "zx:silent call <SID>Dbn_SurroundSelection(
			\ 	@z, "<programlisting><![CDATA[",
			\ 	"]]></programlisting>"
			\ )<CR>
"	emphasis and strong emphasis (em|es)                             {{{3
if !hasmapto( '<Plug>DbnEmI' )
	imap <buffer> <unique> ,em <Plug>DbnEmI
endif
inoremap <script> <unique> <Plug>DbnEmI <Esc>:call
			\ <SID>Dbn_XmlEntity(
			\ 	"emphasis",
			\ 	"",
			\ 	"Enter text to be emphasised: ",
			\ 	"<emphasis>"
			\ )<CR>
inoremenu <silent> 500.30.130 
			\ &DocBook.M&inor\ Structures.&Emphasis<Tab>,em 
			\ <Esc>:call <SID>Dbn_XmlEntity(
			\ 	"emphasis",
			\ 	"",
			\ 	"Enter text to be emphasised: ",
			\ 	"<emphasis>"
			\ )<CR>
if !hasmapto( '<Plug>DbnEmV' )
	vmap <buffer> <unique> ,em <Plug>DbnEmV
endif
vnoremap <script> <unique> <Plug>DbnEmV "zx:call
			\ <SID>Dbn_SurroundSelection( @z,
			\ "<emphasis>", "</emphasis>" )<CR>
vnoremenu <silent> 500.30.130 
			\ &DocBook.M&inor\ Structures.&Emphasis<Tab>,em 
			\ "zx:call <SID>Dbn_SurroundSelection( @z,
			\ "<emphasis>", "</emphasis>" )<CR>
if !hasmapto( '<Plug>DbnEsI' )
	imap <buffer> <unique> ,es <Plug>DbnEsI
endif
inoremap <script> <unique> <Plug>DbnEsI <Esc>:call
			\ <SID>Dbn_XmlEntity(
			\ 	"emphasis",
			\ 	"role=\"strong\"",
			\ 	"Enter text to be emphasised: ",
			\ 	"<emphasis role=,\"strong,\">"
			\ )<CR>
inoremenu <silent> 500.30.140 
			\ &DocBook.M&inor\ Structures.&Strong\ Emphasis<Tab>,es 
			\ <Esc>:call <SID>Dbn_XmlEntity(
			\ 	"emphasis",
			\ 	"role=\"strong\"",
			\ 	"Enter text to be emphasised: ",
			\ 	"<emphasis role=,\"strong,\">"
			\ )<CR>
if !hasmapto( '<Plug>DbnEsV' )
	vmap <buffer> <unique> ,es <Plug>DbnEsV
endif
vnoremap <script> <unique> <Plug>DbnEsV "zx:call
			\ <SID>Dbn_SurroundSelection(
			\ @z, "<emphasis role=\"strong\">", "</emphasis>" )<CR>
vnoremenu <silent> 500.30.140 
			\ &DocBook.M&inor\ Structures.&Strong\ Emphasis<Tab>,es 
			\ "zx:call <SID>Dbn_SurroundSelection(
			\ @z, "<emphasis role=\"strong\">", "</emphasis>" )<CR>
"	index item (,in)                                                 {{{3
if !hasmapto( '<Plug>DbnInI' )
	imap <buffer> <unique> ,in <Plug>DbnInI
endif
inoremap <script> <unique> <Plug>DbnInI <Esc>:call
			\ <SID>Dbn_InsertIndexTermInsertMode()<CR>
inoremenu <silent> 500.30.150 
			\ &DocBook.M&inor\ Structures.&Index\ Item<Tab>,in 
			\ <Esc>:call <SID>Dbn_InsertIndexTermInsertMode()<CR>
if !hasmapto( '<Plug>DbnInV' )
	vmap <buffer> <unique> ,in <Plug>DbnInV
endif
vnoremap <script> <unique> <Plug>DbnInV "zx:call
			\ <SID>Dbn_InsertIndexTermVisualMode( @z )<CR>
vnoremenu <silent> 500.30.150 
			\ &DocBook.M&inor\ Structures.&Index\ Item<Tab>,in 
			\ "zx:call <SID>Dbn_InsertIndexTermVisualMode( @z )<CR>
"	glossary term (,gl)                                              {{{3
if !hasmapto( '<Plug>DbnGlI' )
	imap <buffer> <unique> ,gl <Plug>DbnGlI
endif
inoremap <script> <unique> <Plug>DbnGlI <Esc>:call
			\ <SID>Dbn_InsertGlossaryTerm( '' )<CR>
inoremenu <silent> 500.30.160 
			\ &DocBook.M&inor\ Structures.&Glossary\ Term<Tab>,gl 
			\ <Esc>:call <SID>Dbn_InsertGlossaryTerm( '' )<CR>
if !hasmapto( '<Plug>DbnGlV' )
	vmap <buffer> <unique> ,gl <Plug>DbnGlV
endif
vnoremap <script> <unique> <Plug>DbnGlV "zx:call
			\ <SID>Dbn_InsertGlossaryTerm( @z )<CR>
vnoremenu <silent> 500.30.160 
			\ &DocBook.M&inor\ Structures.&Glossary\ Term<Tab>,gl 
			\ "zx:call <SID>Dbn_InsertGlossaryTerm( @z )<CR>
"	RCS-style id keyword (,id)                                       {{{3
if !hasmapto( '<Plug>DbnIdI' )
	imap <buffer> <unique> ,id <Plug>DbnIdI
endif
inoremap <script> <unique> <Plug>DbnIdI <!-- <Esc>:call
			\ <SID>Dbn_InsertKeyword( "$", "Id" )<CR>a -->
inoremenu <silent> 500.30.170 
			\ &DocBook.M&inor\ Structures.RCS-style\ &ID\ Keyword<Tab>,id 
			\ <!-- <Esc>:call
			\ <SID>Dbn_InsertKeyword( "$", "Id" )<CR>a -->
"	RCS-style log keyword (,lo)                                      {{{3
if !hasmapto( '<Plug>DbnLoI' )
	imap <buffer> <unique> ,lo <Plug>DbnLoI
endif
inoremap <script> <unique> <Plug>DbnLoI <!--<CR><Esc>:call
			\ <SID>Dbn_InsertKeyword( "$", "Log" )<CR>a-->
inoremenu <silent> 500.30.180 
			\ &DocBook.M&inor\ Structures.RCS-style\ &Log\ Keyword<Tab>,lo 
			\ <!--<CR><Esc>:call
			\ <SID>Dbn_InsertKeyword( "$", "Log" )<CR>a-->

" Characters:                                                        {{{2
"	ampersand: '&'                                                   {{{3
if !hasmapto( '<Plug>DbnAmpI' )
	imap <buffer> <unique> & <Plug>DbnAmpI
endif
inoremap <buffer> <unique> <Plug>DbnAmpI &amp;
if !hasmapto( '<Plug>DbnComAmpI' )
	imap <buffer> <unique> ,& <Plug>DbnComAmpI
endif
inoremap <buffer> <unique> <Plug>DbnComAmpI &
"	left angle bracket: '<'                                          {{{3
if !hasmapto( '<Plug>DbnLeftAngleI' )
	imap <buffer> <unique> ,< <Plug>DbnLeftAngleI
endif
inoremap <buffer> <unique> <Plug>DbnLeftAngleI &lt;
"	right angle bracket: '>'                                         {{{3
if !hasmapto( '<Plug>DbnRightAngleI' )
	imap <buffer> <unique> ,> <Plug>DbnRightAngleI
endif
inoremap <buffer> <unique> <Plug>DbnRightAngleI &gt;
"	double quotation marks                                           {{{3
"	- straight ("):
"	- 	= &quot;
"	- curved:
"	- 	requires function: 'Dbn_InsertQuoteMark'
"	- 	left  = &ldquo; = unicode 201C = '“'
"	- 	right = &rdquo; = unicode 201D = '”'
if !hasmapto( '<Plug>DbnDQuoteCharI' )
	imap <buffer> <unique> ," <Plug>DbnDQuoteCharI
endif
inoremap <buffer> <unique> <Plug>DbnDQuoteCharI "
if !hasmapto( '<Plug>DbnDQuoteEntI' )
	imap <buffer> <unique> ,," <Plug>DbnDQuoteEntI
endif
inoremap <buffer> <unique> <Plug>DbnDQuoteEntI &quot;
if !hasmapto( '<Plug>DbnDQuoteMarkI' )
	imap <buffer> <unique> " <Plug>DbnDQuoteMarkI
endif
inoremap <script> <unique> <Plug>DbnDQuoteMarkI
			\ <C-R>=<SID>Dbn_InsertQuoteMark( "double" )<CR>
"	single quotation marks                                           {{{3
"	- straight ('):
"	- 	= &apos;
"	- curved:
"	- 	requires function: 'Dbn_InsertQuoteMark'
"	- 	left  = &lsquo; = unicode 2018 = '‘'
"	- 	right = &rsquo; = unicode 2019 = '’'
if !hasmapto( '<Plug>DbnSQuoteCharI' )
	imap <buffer> <unique> ,' <Plug>DbnSQuoteCharI
endif
inoremap <buffer> <unique> <Plug>DbnSQuoteCharI '
if !hasmapto( '<Plug>DbnSQuoteEntI' )
	imap <buffer> <unique> ,,' <Plug>DbnSQuoteEntI
endif
inoremap <buffer> <unique> <Plug>DbnSQuoteEntI &apos;
if !hasmapto( '<Plug>DbnSQuoteMarkI' )
	imap <buffer> <unique> ' <Plug>DbnSQuoteMarkI
endif
inoremap <script> <unique> <Plug>DbnSQuoteMarkI
			\ <C-R>=<SID>Dbn_InsertQuoteMark( "single" )<CR>
"	em and en dash ('—'|'–')                                         {{{3
"	em = unicode 2014, en = unicode 2013
if !hasmapto( '<Plug>DbnMdashI' )
	imap <buffer> <unique> --- <Plug>DbnMdashI
endif
inoremap <buffer> <unique> <Plug>DbnMdashI &mdash;
if !hasmapto( '<Plug>DbnNdashI' )
	imap <buffer> <unique> -- <Plug>DbnNdashI
endif
inoremap <buffer> <unique> <Plug>DbnNdashI &ndash;
if !hasmapto( '<Plug>DbnDashI' )
	imap <buffer> <unique> ,- <Plug>DbnDashI
endif
inoremap <buffer> <unique> <Plug>DbnDashI -
"	horizontal ellipsis (unicode 2026): '…'                          {{{3
if !hasmapto( '<Plug>DbnHellipI' )
	imap <buffer> <unique> ... <Plug>DbnHellipI
endif
inoremap <buffer> <unique> <Plug>DbnHellipI &hellip;
"	non-breaking backspace (unicode 00A0): ' '                       {{{3
if has( "gui_running")
	if !hasmapto( '<Plug>DbnCspaceI' )
		imap <buffer> <unique> <C-Space> <Plug>DbnCspaceI
	endif
	inoremap <buffer> <unique> <Plug>DbnCspaceI &nbsp;
endif
if !hasmapto( '<Plug>DbnSpI' )
	imap <buffer> <unique> ,sp <Plug>DbnSpI
endif
inoremap <buffer> <unique> <Plug>DbnSpI &nbsp;

" Links:                                                             {{{2
"	Cross-reference <xref> (,cr)                                     {{{3
if !hasmapto( '<Plug>DbnCrI' )
	imap <buffer> <unique> ,cr <Plug>DbnCrI
endif
inoremap <script> <unique> <Plug>DbnCrI <Esc>:call
			\ <SID>Dbn_InsertXref()<CR>a
inoremenu <silent> 500.40.10 
			\ &DocBook.Lin&ks.&Cross\ Reference<Tab>,cr 
			\ <Esc>:call <SID>Dbn_InsertXref()<CR>a
if !hasmapto( '<Plug>DbnXrI' )
	imap <buffer> <unique> ,xr <Plug>DbnXrI
endif
inoremap <buffer> <unique> <Plug>DbnXrI
			\ <xref linkend=,"," role=,"select: label page,"/><Esc>4F"a
"	Hyperlink <ulink> (,hy)                                          {{{3
if !hasmapto( '<Plug>DbnHyI' )
	imap <buffer> <unique> ,hy <Plug>DbnHyI
endif
inoremap <script> <unique> <Plug>DbnHyI <Esc>:call <SID>Dbn_InsertUlink()<CR>
inoremenu <silent> 500.40.20 
			\ &DocBook.Lin&ks.&Hyperlink<Tab>,hy 
			\ <Esc>:call <SID>Dbn_InsertUlink()<CR>
if !hasmapto( '<Plug>DbnHyV' )
	vmap <buffer> <unique> ,hy <Plug>DbnHyV
endif
vnoremap <script> <unique> <Plug>DbnHyV "zx:call
			\ <SID>Dbn_InsertUlink( @z )<CR>
vnoremenu <silent> 500.40.20 
			\ &DocBook.Lin&ks.&Hyperlink<Tab>,hy 
			\ "zx:call <SID>Dbn_InsertUlink( @z )<CR>
"	Hyperlink <link> (,lk)                                           {{{3
if !hasmapto( '<Plug>DbnLkI' )
	imap <buffer> <unique> ,lk <Plug>DbnLkI
endif
inoremap <script> <unique> <Plug>DbnLkI <link linkend=""><esc>2F"a

" External Data:                                                     {{{2
"	Filepath (,fp)                                                   {{{3
if !hasmapto( '<Plug>DbnFpI' )
	imap <buffer> <unique> ,fp <Plug>DbnFpI
endif
inoremap <script> <unique> <Plug>DbnFpI <Esc>:call
			\ <SID>Dbn_InsertFilePath( "Select file" )<CR>a
inoremenu <silent> 500.50.10 
			\ &DocBook.&External\ Data.&Filepath<Tab>,fp 
			\ <Esc>:call <SID>Dbn_InsertFilePath( "Select file" )<CR>a

" Lists:                                                             {{{2
"	itemizedlist (,il)                                               {{{3
if !hasmapto( '<Plug>DbnIlI' )
	imap <buffer> <unique> ,il <Plug>DbnIlI
endif
inoremap <script> <unique> <Plug>DbnIlI <Esc>:call
			\ <SID>Dbn_InsertList( "itemized" )<CR>
inoremenu <silent> 500.60.10 
			\ &DocBook.&Lists.&Itemized<Tab>,il 
			\ <Esc>:call <SID>Dbn_InsertList( "itemized" )<CR>
"	orderedlist (,ol)                                                {{{3
if !hasmapto( '<Plug>DbnOlI' )
	imap <buffer> <unique> ,ol <Plug>DbnOlI
endif
inoremap <script> <unique> <Plug>DbnOlI <Esc>:call
			\ <SID>Dbn_InsertList( "ordered" )<CR>
inoremenu <silent> 500.60.20 
			\ &DocBook.&Lists.&Ordered<Tab>,ol 
			\ <Esc>:call <SID>Dbn_InsertList( "ordered" )<CR>
"	variablelist (,vl)                                               {{{3
if !hasmapto( '<Plug>DbnVlI' )
	imap <buffer> <unique> ,vl <Plug>DbnVlI
endif
inoremap <script> <unique> <Plug>DbnVlI <Esc>:call
			\ <SID>Dbn_InsertList( "variable" )<CR>
inoremenu <silent> 500.60.30 
			\ &DocBook.&Lists.&Variable<Tab>,vl 
			\ <Esc>:call <SID>Dbn_InsertList( "variable" )<CR>
"	listitem (,li)                                                   {{{3
if !hasmapto( '<Plug>DbnLiI' )
	imap <buffer> <unique> ,li <Plug>DbnLiI
endif
inoremap <script> <unique> <Plug>DbnLiI <Esc>:call
			\ <SID>Dbn_InsertListItem( "", "", 1 )<CR>
inoremenu <silent> 500.60.40 
			\ &DocBook.&Lists.&List\ Item<Tab>,li 
			\ <Esc>:call <SID>Dbn_InsertListItem( "", "", 1 )<CR>
"	varlistentry (,ve)                                               {{{3
if !hasmapto( '<Plug>DbnVeI' )
	imap <buffer> <unique> ,ve <Plug>DbnVeI
endif
inoremap <script> <unique> <Plug>DbnVeI <Esc>:call
			\ <SID>Dbn_InsertVarListEntry( "", "" )<CR>
inoremenu <silent> 500.60.50 
			\ &DocBook.&Lists.VarList\ &Entry<Tab>,ve 
			\ <Esc>:call <SID>Dbn_InsertVarListEntry( "", "" )<CR>

" Tables:                                                            {{{2
"   <table> (,ta)                                                    {{{3
if !hasmapto( '<Plug>DbnTaI' )
	imap <buffer> <unique> ,ta <Plug>DbnTaI
endif
inoremap <script> <unique> <Plug>DbnTaI <Esc>:call
			\ <SID>Dbn_InsertTable( "" )<CR>
inoremenu <silent> 500.70.10 
			\ &DocBook.&Tables.&Table<Tab>,ta 
			\ <Esc>:call <SID>Dbn_InsertTable( "" )<CR>
"   <row> (,tr)                                                      {{{3
if !hasmapto( '<Plug>DbnTrI' )
	imap <buffer> <unique> ,tr <Plug>DbnTrI
endif
imap <buffer> <unique> <Plug>DbnTrI <row>>,te
imenu <silent> 500.70.20 
			\ &DocBook.&Tables.&Row<Tab>,tr 
			\ <row>>,te
"   <entry> (,te)                                                    {{{3
if !hasmapto( '<Plug>DbnTeI' )
	imap <buffer> <unique> ,te <Plug>DbnTeI
endif
imap <buffer> <unique> <Plug>DbnTeI <entry>
imenu <silent> 500.70.30 
			\ &DocBook.&Tables.&Entry<Tab>,te 
			\ <entry>

" Graphics:                                                          {{{2
"	imageobject (,im)                                                {{{3
if !hasmapto( '<Plug>DbnImI' )
	imap <buffer> <unique> ,im <Plug>DbnImI
endif
imap <script> <unique> <Plug>DbnImI <Esc>:call
			\ <SID>Dbn_InsertImageObject()<CR>
imenu <silent> 500.80.10 
			\ &DocBook.&Graphics.&Imageobject<Tab>,im 
			\ <Esc>:call <SID>Dbn_InsertImageObject()<CR>
"	mediaobject (,mo)                                                {{{3
if !hasmapto( '<Plug>DbnMoI' )
	imap <buffer> <unique> ,mo <Plug>DbnMoI
endif
imap <script> <unique> <Plug>DbnMoI <Esc>:call
			\ <SID>Dbn_InsertMediaObject()<CR>
imenu <silent> 500.80.20 
			\ &DocBook.&Graphics.&Mediaobject<Tab>,mo 
			\ <Esc>:call <SID>Dbn_InsertMediaObject()<CR>
"	figure (,fig)                                                    {{{3
if !hasmapto( '<Plug>DbnFigI' )
	imap <buffer> <unique> ,fig <Plug>DbnFigI
endif
inoremap <script> <unique> <Plug>DbnFigI <Esc>:call
			\ <SID>Dbn_InsertFigure()<CR>
inoremenu <silent> 500.80.30 
			\ &DocBook.&Graphics.&Figure<Tab>,fig 
			\ <Esc>:call <SID>Dbn_InsertFigure()<CR>

" Citations:                                                         {{{2
" - use RefDB framework, see <refdb.sourceforge.net>
"	insert (,ci)                                                     {{{3
if !hasmapto( '<Plug>DbnCiI' )
	imap <buffer> <unique> ,ci <Plug>DbnCiI
endif
if s:use_refdb
	inoremap <script> <unique> <Plug>DbnCiI <Esc>:call
				\ <SID>Dbn_InsertCitation( 1 )<CR>
	inoremenu <silent> 500.90.10 
				\ &DocBook.&Citations.&Insert<Tab>,ci 
				\ <Esc>:call <SID>Dbn_InsertCitation( 1 )<CR>
else
	inoremap <script> <unique> <plug>DbnCiI <Esc>:call
				\ <SID>Dbn__ShowMsg(
				\ 	s:msg_no_refdb,
				\ 	"Error"
				\ )<CR>:call <SID>Dbn__StartInsert( 1 )<CR>
endif
"	add new (\nr)                                                    {{{3
if !hasmapto( '<Plug>DbnNrN' )
	nmap <buffer> <unique> <LocalLeader>nr <Plug>DbnNrN
endif
if s:use_refdb
	nnoremap <script> <unique> <Plug>DbnNrN :call
				\ <SID>Dbn_Newref()<CR>
	nnoremenu <silent> 500.90.20 
				\ &DocBook.&Citations.&New<Tab><Leader>nr 
				\ :call <SID>Dbn_Newref()<CR>
else
	nnoremap <script> <unique> <plug>DbnNrN :call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
endif
if !hasmapto( '<Plug>DbnNrI' )
	imap <buffer> <unique> <LocalLeader>nr <Plug>DbnNrI
endif
if s:use_refdb
	inoremap <script> <unique> <Plug>DbnNrI <Esc>:call
				\ <SID>Dbn_Newref( "i" )<CR>
	inoremenu <silent> 500.90.20 
				\ &DocBook.&Citations.&New<Tab><Leader>nr 
				\ <Esc>:call <SID>Dbn_Newref( "i" )<CR>
else
	inoremap <script> <unique> <plug>DbnNrI <Esc>:call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
				\ :call <SID>Dbn__StartInsert( 1 )<CR>
endif
"	edit (\er)                                                       {{{3
if !hasmapto( '<Plug>DbnErN' )
	nmap <buffer> <unique> <LocalLeader>er <Plug>DbnErN
endif
if s:use_refdb
	nnoremap <script> <unique> <Plug>DbnErN :call
				\ <SID>Dbn_Edref()<CR>
	nnoremenu <silent> 500.90.30 
				\ &DocBook.&Citations.&Edit<Tab><Leader>er 
				\ :call <SID>Dbn_Edref()<CR>
else
	nnoremap <script> <unique> <plug>DbnErN :call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
endif
if !hasmapto( '<Plug>DbnErI' )
	imap <buffer> <unique> <LocalLeader>er <Plug>DbnErI
endif
if s:use_refdb
	inoremap <script> <unique> <Plug>DbnErI <Esc>:call
				\ <SID>Dbn_Edref( "i" )<CR>
	inoremenu <silent> 500.90.30 
				\ &DocBook.&Citations.&Edit<Tab><Leader>er 
				\ <Esc>:call <SID>Dbn_Edref( "i" )<CR>
else
	inoremap <script> <unique> <plug>DbnErI <Esc>:call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
				\ :call <SID>Dbn__StartInsert( 1 )<CR>
endif
"	delete (\dr)                                                     {{{3
if !hasmapto( '<Plug>DbnDrN' )
	nmap <buffer> <unique> <LocalLeader>dr <Plug>DbnDrN
endif
if s:use_refdb
	nnoremap <script> <unique> <Plug>DbnDrN :call
				\ <SID>Dbn_Delref()<CR>
	nnoremenu <silent> 500.90.40 
				\ &DocBook.&Citations.&Delete<Tab><Leader>dr 
				\ :call <SID>Dbn_Delref()<CR>
else
	nnoremap <script> <unique> <plug>DbnDrN :call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
endif
if !hasmapto( '<Plug>DbnDrI' )
	imap <buffer> <unique> <LocalLeader>dr <Plug>DbnDrI
endif
if s:use_refdb
	inoremap <script> <unique> <Plug>DbnDrI <Esc>:call
				\ <SID>Dbn_Delref( "i" )<CR>
	inoremenu <silent> 500.90.40 
				\ &DocBook.&Citations.&Delete<Tab><Leader>dr 
				\ <Esc>:call <SID>Dbn_Delref( "i" )<CR>
else
	inoremap <script> <unique> <plug>DbnDrI <Esc>:call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
				\ :call <SID>Dbn__StartInsert( 1 )<CR>
endif
"	display all (\sr)                                                {{{3
if !hasmapto( '<Plug>DbnSrN' )
	nmap <buffer> <unique> <LocalLeader>sr <Plug>DbnSrN
endif
if s:use_refdb
	nnoremap <script> <unique> <Plug>DbnSrN :call
				\ <SID>Dbn_Showrefs()<CR>
	nnoremenu <silent> 500.90.50 
				\ &DocBook.&Citations.&Show<Tab><Leader>sr 
				\ :call <SID>Dbn_Showrefs()<CR>
else
	nnoremap <script> <unique> <plug>DbnSrN :call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
endif
if !hasmapto( '<Plug>DbnSrI' )
	imap <buffer> <unique> <LocalLeader>sr <Plug>DbnSrI
endif
if s:use_refdb
	inoremap <script> <unique> <Plug>DbnSrI <Esc>:call
				\ <SID>Dbn_Showrefs( "i" )<CR>
	inoremenu <silent> 500.90.50 
				\ &DocBook.&Citations.&Show<Tab><Leader>sr 
				\ <Esc>:call <SID>Dbn_Showrefs( "i" )<CR>
else
	inoremap <script> <unique> <plug>DbnSrI <Esc>:call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
				\ :call <SID>Dbn__StartInsert( 1 )<CR>
endif
"	kill display (\kr)                                               {{{3
if !hasmapto( '<Plug>DbnKrN' )
	nmap <buffer> <unique> <LocalLeader>kr <Plug>DbnKrN
endif
if s:use_refdb
	nnoremap <script> <unique> <Plug>DbnKrN :call
				\ <SID>Dbn_Killrefs()<CR>
	nnoremenu <silent> 500.90.60 
				\ &DocBook.&Citations.&Kill\ Display<Tab><Leader>kr 
				\ :call <SID>Dbn_Killrefs()<CR>
else
	nnoremap <script> <unique> <plug>DbnKrN :call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
endif
if !hasmapto( '<Plug>DbnKrI' )
	imap <buffer> <unique> <LocalLeader>kr <Plug>DbnKrI
endif
if s:use_refdb
	inoremap <script> <unique> <Plug>DbnKrI <Esc>:call
				\ <SID>Dbn_Killrefs( "i" )<CR>
	inoremenu <silent> 500.90.60 
				\ &DocBook.&Citations.&Kill\ Display<Tab><Leader>kr 
				\ <Esc>:call <SID>Dbn_Killrefs( "i" )<CR>
else
	inoremap <script> <unique> <plug>DbnKrI <Esc>:call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>:
				\ call <SID>Dbn__StartInsert( 1 )<CR>
endif
"	change default reference database (\rd)                          {{{3
"	- requires refdbarc configuration for password-less access
if !hasmapto( '<Plug>DbnRdN' )
	nmap <buffer> <unique> <LocalLeader>rd <Plug>DbnRdN
endif
if s:use_refdb
	nnoremap <script> <unique> <Plug>DbnRdN :call
				\ <SID>Dbn_ChangeRefdbDb()<CR>
	nnoremenu <silent> 500.90.70 
				\ &DocBook.&Citations.&Change\ Db<Tab><Leader>rd 
				\ :call <SID>Dbn_ChangeRefdbDb()<CR>
else
	nnoremap <script> <unique> <plug>DbnRdN :call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
endif
if !hasmapto( '<Plug>DbnRdI' )
	imap <buffer> <unique> <LocalLeader>rd <Plug>DbnRdI
endif
if s:use_refdb
	inoremap <script> <unique> <Plug>DbnRdI <Esc>:call
				\ <SID>Dbn_ChangeRefdbDb( "i" )<CR>
	inoremenu <silent> 500.90.70 
				\ &DocBook.&Citations.Change\ &Db<Tab><Leader>rd 
				\ :call <SID>Dbn_ChangeRefdbDb( "i" )<CR>
else
	inoremap <script> <unique> <plug>DbnRdI <Esc>:call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
				\ :call <SID>Dbn__StartInsert( 1 )<CR>
endif
"	change document RefDb stylesheet (\rs)                           {{{3
"	- requires refdbarc configuration for password-less access
if !hasmapto( '<Plug>DbnRsN' )
	nmap <buffer> <unique> <LocalLeader>rs <Plug>DbnRsN
endif
if s:use_refdb
	nnoremap <script> <unique> <Plug>DbnRsN :call
				\ <SID>Dbn_MakefileStyle()<CR>
	nnoremenu <silent> 500.90.80 
				\ &DocBook.&Citations.Change\ &Stylesheet<Tab><Leader>rs 
				\ :call <SID>Dbn_MakefileStyle()<CR>
else
	nnoremap <script> <unique> <plug>DbnRsN :call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
endif
if !hasmapto( '<Plug>DbnRsI' )
	imap <buffer> <unique> <LocalLeader>rs <Plug>DbnRsI
endif
if s:use_refdb
	inoremap <script> <unique> <Plug>DbnRsI <Esc>:call
				\ <SID>Dbn_MakefileStyle( "i" )<CR>
	inoremenu <silent> 500.90.80 
				\ &DocBook.&Citations.&Change\ Stylesheet<Tab><Leader>rs 
				\ <Esc>:call <SID>Dbn_MakefileStyle( "i" )<CR>
else
	inoremap <script> <unique> <plug>DbnRsI <Esc>:call
				\ <SID>Dbn__ShowMsg( s:msg_no_refdb, "Error" )<CR>
				\ :call <SID>Dbn__StartInsert( 1 )<CR>
endif

" Navigation:                                                        {{{2
"	Jump to element id (\je)                                         {{{3
if !hasmapto( '<Plug>DbnJeN' )
	nmap <buffer> <unique> <LocalLeader>je <Plug>DbnJeN
endif
nnoremap <script> <unique> <Plug>DbnJeN :update<CR>:call
			\ <SID>Dbn_JumpToId()<CR>
nnoremenu <silent> 500.100.10 
			\ &DocBook.&Navigation.&Jump\ to\ ID<Tab><Leader>je 
			\ :update<CR>:call <SID>Dbn_JumpToId()<CR>
if !hasmapto( '<Plug>DbnJeI' )
	imap <buffer> <unique> <LocalLeader>je <Plug>DbnJeI
endif
inoremap <script> <unique> <Plug>DbnJeI <Esc>:up<CR>:call
			\ <SID>Dbn_JumpToId( "i" )<CR>
inoremenu <silent> 500.100.10 
			\ &DocBook.&Navigation.&Jump\ to\ ID<Tab><Leader>je 
			\ <Esc>:up<CR>:call <SID>Dbn_JumpToId( "i" )<CR>

" XML Validation:                                                    {{{2
"	XML Validation (\va)
if !hasmapto( '<Plug>DbnVaN' )
	nmap <buffer> <unique> <LocalLeader>va <Plug>DbnVaN
endif
nnoremap <script> <unique> <plug>DbnVaN :update<CR>:call
			\ <SID>Dbn_ValidateXml( 1 )<CR>
nnoremenu <silent> 500.110 
			\ &DocBook.&Validation<Tab><Leader>va 
			\ :update<CR>:call <SID>Dbn_ValidateXml( 1 )<CR>
if !hasmapto( '<Plug>DbnVaI' )
	imap <buffer> <unique> <LocalLeader>va <Plug>DbnVaI
endif
inoremap <script> <unique> <Plug>DbnVaI <Esc>:up<CR>:call
			\ <SID>Dbn_ValidateXml( 1, "i" )<CR>
inoremenu <silent> 500.110 
			\ &DocBook.&Validation<Tab><Leader>va 
			\ <Esc>:up<CR>:call <SID>Dbn_ValidateXml( 1, "i" )<CR>

" Output:                                                            {{{2
"	output (\op)
if !hasmapto( '<Plug>DbnOpN' )
	nmap <buffer> <unique> <LocalLeader>op <Plug>DbnOpN
endif
nnoremap <buffer> <unique> <Plug>DbnOpN :call
			\ <SID>Dbn_OutputDbk()<CR>
nnoremenu <silent> 500.120 
			\ &DocBook.&Output<Tab><Leader>op 
			\ :call <SID>Dbn_OutputDbk()<CR>
if !hasmapto( '<Plug>DbnOpI' )
	imap <buffer> <unique> <LocalLeader>op <Plug>DbnOpI
endif
inoremap <buffer> <unique> <Plug>DbnOpI <Esc>:call
			\ <SID>Dbn_OutputDbk( "i" )<CR>
inoremenu <silent> 500.120 
			\ &DocBook.&Output<Tab><Leader>op 
			\ <Esc>:call <SID>Dbn_OutputDbk( "i" )<CR>

" Help:                                                              {{{2
"	general (\hh)                                                    {{{3
if !hasmapto( '<Plug>DbnHhN' )
	nmap <buffer> <unique> <LocalLeader>hh <Plug>DbnHhN
endif
nnoremap <script> <unique> <Plug>DbnHhN :call
			\ <SID>Dbn_ShowHelpFile()<CR>
nnoremenu <silent> 500.130.10 
			\ &DocBook.&Help.&Mappings<Tab><Leader>hh 
			\ :call <SID>Dbn_ShowHelpFile()<CR>
if !hasmapto( '<Plug>DbnHhI' )
	imap <buffer> <unique> <LocalLeader>hh <Plug>DbnHhI
endif
inoremap <script> <unique> <Plug>DbnHhI <Esc>:call
			\ <SID>Dbn_ShowHelpFile( "i" )<CR>
inoremenu <silent> 500.130.10 
			\ &DocBook.&Help.&Mappings<Tab><Leader>hh 
			\ <Esc>:call <SID>Dbn_ShowHelpFile( "i" )<CR>
"	for next element (\hn)                                           {{{3
if !hasmapto( '<Plug>DbnHnN' )
	nmap <buffer> <unique> <LocalLeader>hn <Plug>DbnHnN
endif
nnoremap <script> <unique> <Plug>DbnHnN :call
			\ <SID>Dbn_GetElementHelp( "forward" )<CR>
nnoremenu <silent> 500.130.20 
			\ &DocBook.&Help.&Next\ Element<Tab><Leader>hn 
			\ :call <SID>Dbn_GetElementHelp( "forward" )<CR>
if !hasmapto( '<Plug>DbnHnI' )
	imap <buffer> <unique> <LocalLeader>hn <Plug>DbnHnI
endif
inoremap <script> <unique> <Plug>DbnHnI <Esc>:call
			\ <SID>Dbn_GetElementHelp( "forward", "i" )<CR>
inoremenu <silent> 500.130.20 
			\ &DocBook.&Help.&Next\ Element<Tab><Leader>hn 
			\ <Esc>:call <SID>Dbn_GetElementHelp( "forward", "i" )<CR>
"	for previous/current element (\hp)                               {{{3
if !hasmapto( '<Plug>DbnHpN' )
	nmap <buffer> <unique> <LocalLeader>hp <Plug>DbnHpN
endif
nnoremap <script> <unique> <Plug>DbnHpN :call
			\ <SID>Dbn_GetElementHelp( "back" )<CR>
nnoremenu <silent> 500.130.30 
			\ &DocBook.&Help.&Previous/Current\ Element<Tab><Leader>hp 
			\ :call <SID>Dbn_GetElementHelp( "back" )<CR>
if !hasmapto( '<Plug>DbnHpI' )
	imap <buffer> <unique> <LocalLeader>hp <Plug>DbnHpI
endif
inoremap <script> <unique> <Plug>DbnHpI <Esc>:call
			\ <SID>Dbn_GetElementHelp( "back", "i" )<CR>
inoremenu <silent> 500.130.30 
			\ &DocBook.&Help.&Previous/Current\ Element<Tab><Leader>hp 
			\ <Esc>:call <SID>Dbn_GetElementHelp( "back", "i" )<CR>
"	display document outline (\so)                                   {{{3
if !hasmapto( '<Plug>DbnSoN' )
	nmap <buffer> <unique> <LocalLeader>so <Plug>DbnSoN
endif
nnoremap <script> <unique> <Plug>DbnSoN :call
			\ <SID>Dbn_ShowOutline()<CR>
nnoremenu <silent> 500.130.40 
			\ &DocBook.&Help.Show\ &Outline<Tab><Leader>so 
			\ :call <SID>Dbn_ShowOutline()<CR>
if !hasmapto( '<Plug>DbnSoI' )
	imap <buffer> <unique> <LocalLeader>so <Plug>DbnSoI
endif
inoremap <script> <unique> <Plug>DbnSoI <Esc>:call
			\ <SID>Dbn_ShowOutline( "i" )<CR>
inoremenu <silent> 500.130.40 
			\ &DocBook.&Help.Show\ &Outline<Tab><Leader>so 
			\ <Esc>:call <SID>Dbn_ShowOutline( "i" )<CR>

endif  " mappings

" ========================================================================
" }}}1
finish
" __7. DOCUMENTATION                                                 {{{1

=== START_DOC
DocBook XML Plugin {{{2                *vim-docbk-xml* *docbk-xml-plugin*
=========================================================================
1. Contents {{{2

	1. Contents ......................... |docbk-xml-contents|
	2. Overview ......................... |docbk-xml-overview|
	3. Mappings ......................... |docbk-xml-mappings|
	4. New DocBook XML Documents ........ |docbk-xml-new-documents|
	5. Dependencies ..................... |docbk-xml-dependencies|
	6. RefDB support .................... |docbk-xml-refdb|
	7. Limitations ...................... |docbk-xml-limitations|

=========================================================================
2. DocBook XML Overview {{{2                         *docbk-xml-overview*

A filetype plugin to help edit DocBook XML documents.

All functionality is accessed via key mappings.  The key mappings can be viewed on the help screen invoked by the mapping <Leader>hh (default leader is '\', so the mapping would be \hh).  The help screen assumes the <Leader> character is '\'.

All mappings (except special characters) are available via the 'DocBook' menu (see |console-menus| for how to access menus from a console vim).

All features are designed to work on both console ("classic") vim and GUI vims (such as GVim).

Although there is little resemblance now, the starting point for this plugin was Tobias Reif's "Vim as XML Editor" resource <http://www.pinkjuice.com/howto/vimxml/>.

Other components assist the plugin.  These include several helper scripts, a makefile and several help files.

There are nine helper scripts included:

dbn-doc
	Creates a new DocBook XML document which contains a doctype declaration.

dbn-fo2pdf
	Converts FO output to PDF.

dbn-getcitekeys
	Retrieves a list of RefDB citation keys from the database associated
	with the current document.

dbn-getvalue
	A utility script that supplies variable values to the filetype plugin
	and helper scripts.

dbn-menuselect
	A generic menu selector.

dbn-xmllintwrap
	XML validator. A wrapper for xmllint.

refdb-cache-server & refdb-cache-client
	Provide a RefDB database cache.  These scripts depend on the perl module Refdb::Cache which is supplied by the libperl-refdb-cache distribution (and by a Debian package of the same name).

Except for dbn-doc, these scripts are not designed to be called by the user directly (although users may find some of the scripts can be useful in other circumstances). See |new-docbk-documents| for use of dbn-doc.

DocBook documents can be output as html, xhtml, pdf or plain text.  A makefile is used to generate output.  The script 'dbn-getvalue' provides the executable commands required by the makefile.  This system enables different XSL and FO processors to be supported.

The default XSL processor is xsltproc. The makefile also supports Saxon (with Xerces) and Xalan..

The default FO processor is FOP.  The makefile also supports Xep.

If users wish to add support for additional XSL and/or FO processors, the makefile is designed to make this process simple. You will need to edit the filetype plugin, the makefile and, perhaps, the helper script 'dbn-getvalue'.  As an example, the steps required to add Xalan as a supported XSLT processor were:
	Edit makefile to:
	- Add xalan to list of valid_xslt_processors in section "Set valid variable lists"
	- Add section "XSLT processor conversion commands: Xalan", and
	- Add Xalan 'if..endif' block to section "Conversion commands depending on XSLT processor".
	Edit plugin to:
	- Add s:use_xalan variable to "Script Variables" section, 
	- Add xalan if..endif block to function 'Dbn_OutputDbk', section "determine xslt processor", and
	- Add corresponding elseif option for l:choice in same section.

In addition to this installed Vim help, another help file is supplied. It is in groff format and is displayed using ImageMagick. This process is automated by the mapping <Leader>hh. The document provides a summary of the general DocBook XML mappings.

A configuration file ('${prefix}/etc/vim-docbk-xml-refdb/config') is available.  There is a single configurable option -- RefDB database caching support.  See |docbook-xml-refdb| for details.

=========================================================================
3. DocBook XML Mappings {{{2                         *docbk-xml-mappings*


A complete list of mappings and a short description of the associated functionality is available by using the <Leader>hh mapping. Here is an overview.

A skeleton document structure can be generated using ,bk and ,ar mappings. The user will be prompted to supply some details such as author name and document title.

There are mappings for major document divisions: chapter, section, sect1, sect2 and sect3.

Minor structures can also be generated: para, comment, (strong) emphasis, footnote, blockquote, filename, verbatim, note, index term, glossary term, warning, sidebar and example. The user is generally prompted to enter the text to be enclosed by the structure. Some of these mappings work in visual mode, where the selected text will be "wrapped" by the structure.

A mapping is supplied to insert a filepath. The user selects the file from a file selector dialog box. The user can choose whether to insert an absolute or relative filepath.

A number of mappings are supplied for certain characters that are represented by character entities: ampersand (&), quote marks (',"), angle brackets (<,>), em and en dashes (—,–), ellipses (…) and non-breaking spaces ( ). When the user types a single or double quote mark (',") the corresponding character entity (“,‘,’,”) is chosen intelligently. Alternative mappings are supplied for inserting single and double straight quote mark character entities, and for inserting raw single and double quote marks. A mapping is supplied for "raw" ampersands.

Cross-references and hyperlinks can be inserted into the document. For cross-references the user is presented with a list of element IDs to choose from.

Support for lists (itemised, ordered and variable) is supplied.

Tables and images can be inserted. The user is prompted to supply required information such as numbers of rows and columns for tables and image file, captions and titles for images.

A mapping is supplied that enables users to jump to a selected element (chosen from a menu of available element IDs).

Document validation is only a mapping away.

Output as html, xhtml, pdf and text is generated by a single mapping. The resulting output is opened in an external viewer.

Finally, various help is available via mappings. Help on mappings is available. In addition, help on individual DocBook elements is also available. The user can select help on the previous or next element. The relevant page from Walsh and Muellner’s 'DocBook: The Definitive Guide' is opened in an external html viewer. A summary of the document structure can also be displayed.

Build-time options control what mappings are usable.  It is possible at build time to enable Xep, RXP, Saxon, Xalan and RefDB support.

Non-RefDB users can simply ignore RefDB-associated mappings.

=========================================================================
4. DocBook XML New Documents {{{2               *docbk-xml-new-documents*
                                                     *docbk-xml-new-docs*


There is a "chicken-and-egg" problem when it comes to new DocBook XML documents. The filetype plugin provides mappings for book (,dtbk) and article (,dtar) doctype declarations. For the filetype plugin to be loaded, however, vim must recognise the document as DocBook XML — but this can only occur if the document already contains a DocBook doctype declaration.

The helper script 'dbn-doc' overcomes this paradox. It takes as a command-line option the name of the new document. The script asks the user for the doctype (article|book) and then creates a new XML document containing the appropriate doctype declaration. As a final step it opens the document in (G)vim. Since the document contains a DocBook doctype declaration vim will load the docbk-xml plugin.

=========================================================================
5. DocBook XML Dependencies {{{2                 *docbk-xml-dependencies*


Various other tools are used by this plugin. Here is a list of them:

graphical (x)html viewer
	At least one of following must be present: Firefox, Galeon or 
	Konqueror.  On some systems the ‘sensible-browser’ or
	‘x-www-browser’ may be present.  If so, they also can be used.

terminal emulator
	At least one of the following terminal emulators must be present:
	xterm, uxterm or konsole.

console (x)html viewer
	At least one of the following must be present: w3m or Lynx.

editor
	Quite obviously, vim must be present. If GVim is present it will
	be used.

XSL processor
	'xsltproc' is the default XSL processor and must be present.  This
	plugin can be built with support for Saxon (with Xerces).

FO processors
	'fop' is the default FO processor and must be present.  Dbn can be
	built with support for 'xep'.

PDF viewer
	At least one of the following must be present:
	Xpdf, Kpdf or acroread (Acrobat Reader).

DocBook: The Definitive Guide
	The html version of Walsh & Muellner’s 
	'DocBook: The Definitive Guide' must be installed.

Xdialog
	Xdialog is used for menu dialogs when editing with console vim.

XML validators
	'xmllint' is the default XML validator and must be present.  This
	plugin can be built with support for 'rxp'.

Standard unix tools
	These include sed, tr, groff, enscript and cat.

ImageMagick
	ImageMagick is used for document display.

Refdb::Cache
	A Perl module supplied by the libperl-refdb-cache distribution (and by a Debian package of the same name).

Many Java-based applications contain jar files that include the version number in the file name, e.g. 'saxon-644.jar'.  As a general rule, this plugin defaults to jar file names without version numbers, e.g. 'saxon.jar'.  If the java application in question does not include a suitable symlink, the user may have to create one.  This strategy helps to 'future-proof' the configuration, ensuring the plugin will not break when newer application versions of dependent tools are released.

=========================================================================
6. DocBook XML RefDB Support {{{2                       *docbk-xml-refdb*


RefDB <refdb.sourceforge.net> is a reference database and bibliography tool for XML documents.

This plugin assumes RefDB-using DocBook XML documents have been created using RefDB utility 'refdbnd' (or 'dbn-doc' with the '-r' flag, which then acts as a wrapper for 'refdbnd').  Documents created in this way are named 'foo.short.xml' (where 'foo' is the filename base) and have an associated Makefile for generating output.

If the plugin has been built with RefDB support it checks each file at load time to determine whether the file is a RefDB-compliant DocBook XML document (based on its filename).  If so, the plugin goes through a number of startup checks.  It checks that RefDB client binaries are usable (this may require the user to enter RefDB username and/or password).  The plugin also starts the caching server if cache support is enabled (see below for a discussion of the cache) and begins caching the current reference database as a background process.

A number of mappings and scripts provide support for RefDB.  Mappings are provided for citation support (addition, deletion, editing and displaying of references as well as insertion of citations) and reference database management.  A script is provided for citation retrieval from the reference database.

When selecting records for editing and deletion the process of retrieval and transformation can be slow.  To avoid annoying delay a caching server is provided.  The current reference database is held in memory as a perl hash which is queried directly instead of using the RefDB clients.  After any operation that could alter the reference database the cache is rebuilt.  The plugin can be configured to disable the cache by altering the configuration file '${prefix}/etc/vim-docbk-xml-refdb/config'.

RefDB document output is handled not by the plugin's output mechanism but by invoking the document's RefDB-created Makefile.

=========================================================================
7. DocBook XML Limitations {{{2                   *docbk-xml-limitations*


This suite was developed and tested on a Debian Sarge/testing system. It may not work correctly on other operating systems. Windows users, in particular, are likely to experience unpredictable behaviour.

If you encounter any problems, please email me a bug report. Even better would be a patch fixing the problem!
=== END_DOC
 
" ========================================================================
" vim: set foldmethod=marker :
