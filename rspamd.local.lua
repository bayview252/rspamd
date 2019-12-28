--  {header} - header regexp
--  {raw_header} - undecoded header regexp (e.g. without quoted-printable decoding)
--  {mime_header} - MIME header regexp (applied for headers in MIME parts only)
--  {all_header} - full headers content (applied for all headers undecoded and for the message only - not including MIME headers)
--  {body} - raw message regexp
--  {mime} - part regexp without HTML tags
--  {raw_mime} - part regexp with HTML tags
--  {sa_body} - spamassassin BODY regexp analogue(see http://spamassassin.apache.org/full/3.4.x/doc/Mail_SpamAssassin_Conf.txt)
--  {sa_raw_body} - spamassassin RAWBODY regexp analogue
--  {url} - URL regexp
--  {selector} - from 1.8: selectors regular expression (must include name of the registered selector)
--  {words} - unicode normalized and lowercased words extracted from the text (excluding URLs), subject and From displayed name
--  {raw_words} - same but with no normalization (converted to utf8 however)
--  {stem_words} - unicode normalized, lowercased and stemmed words extracted from the text (excluding URLs), subject and From displayed name
--  Each regexp also supports the following flags:
--  
--  i - ignore case
--  u - use utf8 regexp
--  m - multiline regexp - treat string as multiple lines. That is, change “^” and “$” from matching the start of the string’s first line and the end of its last line to matching the start and end of each line within the string
--  x - extended regexp - this flag tells the regular expression parser to ignore most whitespace that is neither backslashed nor within a bracketed character class. You can use this to break up your regular expression into (slightly) more readable parts. Also, the # character is treated as a metacharacter introducing a comment that runs up to the pattern’s closing delimiter, or to the end of the current line if the pattern extends onto the next line.
--  s - dotall regexp - treat string as single line. That is, change . to match any character whatsoever, even a newline, which normally it would not match. Used together, as /ms, they let the . match any character whatsoever, while still allowing ^ and $ to match, respectively, just after and just before newlines within the string.
--  O - do not optimize regexp (rspamd optimizes regexps by default)
--  r - use non-utf8 regular expressions (raw bytes). This is default true if raw_mode is set to true in the options section.



local cnf = config['regexp'] -- Reconfigure or configure NEW Local Symbols (cnf)

-- EXAMPLES
--cnf['FROM_NETFLIX'] = {
--    re = 'From=/.*netflix.com*/i{header}',
--    score = -2.5,
--}
--cnf['HEADER_CONTAINS_NETFLIX'] = {
--    re = 'From=/.*netflix*/i{header}',
--    description = 'From Header contains Netflix somewhere',
--    score = 2.5,
--}

-- Initial Netflix spam Test

local myre1 = 'From=/.*netflix.com*/i{header}' -- Mind local here
local myre2 = 'From=/.*netflix*/i{header}'
local myre3 = '/NETFLIX/i{body}' -- Check the raw body for anycase Netflix

cnf['NETFLIX_YETNOT_NETFLIX'] = {
	re = string.format('!(%s) && ((%s) || (%s))', myre1, myre2, myre3), -- use string.format to create expression
	score = 40,
	description = 'From OR Body Contains Netflix AND NOT Mailed from Netflix.com',
}

-- Extend Netflix to other problematic domains - i.e. Apple - Lazy spammers but won't detect spoofs
local myre11 = 'From=/.*(dhl|fedex|apple|amazon|samsung).com.*/i{header}' 
local myre22 = 'From=/.*(dhl|fedex|apple|amazon|samsung).*/i{header}'

cnf['BOGUS_MAIL_FROM_APPLE'] = {
	re = string.format('!(%s) && (%s)', myre11, myre22), -- use string.format to create expression
	score = 40,
	description = 'From Contains Apple/FedEx/DHL/Amazon/Samsung AND NOT Mailed from that domain',
}



-- Local User Email in Subject
local myren1 = 'Subject=/.*gerry@.*/i{header}' -- local here is 'local variable'
local myren2 = 'Subject=/.*jksharpe@.*/i{header}'
local myren3 = 'Subject=/.*katie@.*/i{header}'
local myren4 = 'Subject=/.*sam@.*/i{header}'
local myren5 = 'Subject=/.*sammi@.*/i{header}'
local myren6 = 'Subject=/.*lochie@.*/i{header}'

cnf['SUBJECT_CONTAINS_LOCALUSEREMAIL'] = {
    re = string.format('(%s) || (%s) || (%s) || (%s) || (%s) || (%s)', myren1, myren2, myren3, myren4, myren5, myren6),
    description = 'Subject contains Local User email address',
    score = 40,
}

-- Polite Intro to User in Body
local myrbn1 = '/(Hi|Hello|Dear) (gerry|jksharpe|katie|lochie|sam|sammi)@.*/i{body}' -- local here is 'local variable'

cnf['BODY_CONTAINS_POLITE_LOCALUSEREMAIL'] = {
    re = string.format('(%s)', myrbn1),
    description = 'Body contains Polite intro & Local User email address',
    score = 40,
}


local ok_langs = {
  ['en'] = true,
  ['ca'] = true,
}

rspamd_config.LANG_FILTER = {
  callback = function(task)
    local any_ok = false
    local parts = task:get_text_parts() or {}
    local ln
    for _,p in ipairs(parts) do
      ln = p:get_language() or ''
      local dash = ln:find('-')
      if dash then
        -- from zh-cn to zh
        ln = ln:sub(1, dash-1)
      end
      if ok_langs[ln] then
        any_ok = true
        break
      end
    end
    if any_ok or not ln or #ln == 0 then
      return false
    end
    return 1.0,ln
  end,
  score = 40.0,
  description = 'no ok languages',
}



