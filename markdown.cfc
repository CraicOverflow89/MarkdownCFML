component name = "markdown" output = "false"
{

	public function markdown(required string path)
	{
		// Convert File to Array<String>
		var result = []; 
		var file = fileOpen(arguments.path, "read");
		while(!fileIsEOF(file)) {arrayAppend(result, fileReadLine(file));}
		fileClose(file);

		// Render Markdown
		return markdownRender(result);
	}

	private string function markdownRender(required array input)
	{
		var output = [];
		var currentLine = [];
		var currentMode = "";
		var linkUrl = "";
		var linkText = "";
		var linkTitle = "";
		var imageSrc = "";
		var imageAlt = "";
		var imageTitle = "";
		for(var line in input)
		{
			// Mode: Code
			if(currentMode == "code")
			{
				// End Code
				if(line == "```")
				{
					//arrayAppend(output, {render:'<code>' & arrayToList(currentLine, "<br>") & '</code>', br:false});
					arrayAppend(output, {render:'<div style = "background-color: ##000000; border: 1px solid ##00CC00; border-radius: 5px; color: ##00CC00; padding: 10px;"><code>' & arrayToList(currentLine, "<br>") & '</code></div>', br:false});
					// NOTE: using inline styles - will make this an optional parameter so we can do [1] basic html or [2] added inline styles
					currentLine = [];
					currentMode = "";
				}

				// Append Code
				else {arrayAppend(currentLine, line);}
			}

			// Mode: None
			else
			{
				// Match Empty Line
				if(!len(line))
				{
					arrayAppend(output, {render:"", br:true});
				}

				// H1 (underline)
				else if(reFindNoCase("^=====[=]*$", line))
				{
					output[arrayLen(output)] = {render:"<h1>" & output[arrayLen(output)].render & "</h1>", br:false};
				}

				// H2 (underline)
				else if(reFindNoCase("^-----[-]*$", line))
				{
					output[arrayLen(output)] = {render:"<h2>" & output[arrayLen(output)].render & "</h2>", br:false};
				}

				// HR
				else if(line == "---" || line == "***" || line == "___")
				{
					arrayAppend(output, {render:"<hr/>", br:false});
				}

				// H6 (inline)
				else if(reFindNoCase("^############[ ].*$", line))
				{
					arrayAppend(output, {render:"<h6>" & trim(right(line, len(line) - 6)) & "</h6>", br:false});
				}

				// H5 (inline)
				else if(reFindNoCase("^##########[ ].*$", line))
				{
					arrayAppend(output, {render:"<h5>" & trim(right(line, len(line) - 5)) & "</h5>", br:false});
				}

				// H4 (inline)
				else if(reFindNoCase("^########[ ].*$", line))
				{
					arrayAppend(output, {render:"<h4>" & trim(right(line, len(line) - 4)) & "</h4>", br:false});
				}

				// H3 (inline)
				else if(reFindNoCase("^######[ ].*$", line))
				{
					arrayAppend(output, {render:"<h3>" & trim(right(line, len(line) - 3)) & "</h3>", br:false});
				}

				// H2 (inline)
				else if(reFindNoCase("^####[ ].*$", line))
				{
					arrayAppend(output, {render:"<h2>" & trim(right(line, len(line) - 2)) & "</h2>", br:false});
				}

				// H1 (inline)
				else if(reFindNoCase("^##[ ].*$", line))
				{
					arrayAppend(output, {render:"<h1>" & trim(right(line, len(line) - 1)) & "</h1>", br:false});
				}

				// Blockquote
				else if(reFindNoCase("^>[ ].*$", line))
				{
					//arrayAppend(output, {render:"<blockquote>" & trim(listLast(line, ">")) & "</blockquote>", br:false});
					arrayAppend(output, {render:'<blockquote style = "background-color: ##BDB76B; border: 1px solid ##000000; border-radius: 5px; color: ##000000; padding: 10px;">' & trim(listLast(line, ">")) & '</blockquote>', br:false});
					// NOTE: should consecutive lines of blockquote be merged?
				}

				// Code (multiple lines)
				else if(reFindNoCase("^```", line))
				{
					currentMode = "code";
				}

				// Code (single line)
				else if(reFindNoCase("^`.*`$", line))
				{
					arrayAppend(output, {render:"<code>" & mid(line, 2, len(line) - 2) & "</code>", br:false});
				}

				// Bold
				else if(reFindNoCase("^\*\*.*\*\*$", line) || reFindNoCase("^__.*__$", line))
				{
					arrayAppend(output, {render:"<b>" & mid(line, 3, len(line) - 4) & "</b>", br:true});
				}

				// NOTE: we need to use reReplace within lines to get first syntax with opening tag
				//       and second occurence of syntax with closing
				//       the current method only matches the syntax surrounding the string
				//       this applies to inline code, too

				// NOTE: when matching bold and italics we need to open a currentMode
				//       so that internal contents can be matched against other style
				//       eg: **bold text with _italics_**

				// NOTE: need to do strikethrough

				// Italics
				else if(reFindNoCase("^\*.*\*$", line) || reFindNoCase("^_.*_$", line))
				{
					arrayAppend(output, {render:"<i>" & mid(line, 2, len(line) - 2) & "</i>", br:true});
				}

				// Links (with title)
				else if(reFindNoCase('^\[.*\]\(.* ".*"\)$', line))
				{
					linkUrl = reMatch('\(.* \"', line);
					linkUrl = trim(replaceNoCase(replaceNoCase(linkUrl[1], "(", "", "all"), '"', '', 'all'));
					linkText = reMatch("^\[.*\]", line);
					linkText = replaceNoCase(replaceNoCase(linkText[1], "[", "", "all"), "]", "", "all");
					linkTitle = reMatch('".*"', line);
					linkTitle = replaceNoCase(linkTitle[1], '"', '', 'all');
					arrayAppend(output, {render:'<a href = "' & linkUrl & '" alt = "' & linkTitle & '" title = "' & linkTitle & '">' & linkText & '</a>', br:true});
				}

				// NOTE: need to use reReplace to shorten the string tidying

				// Links (without title)
				else if(reFindNoCase("^\[.*\]\(.*\)$", line))
				{
					linkUrl = reMatch("\(.*\)$", line);
					linkUrl = replaceNoCase(replaceNoCase(linkUrl[1], "(", ""), ")", "");
					linkText = reMatch("^\[.*\]", line);
					linkText = replaceNoCase(replaceNoCase(linkText[1], "[", ""), "]", "");
					arrayAppend(output, {render:'<a href = "' & linkUrl & '">' & linkText & '</a>', br:true});
				}

				// Links (just url)
				else if(reFindNoCase("^\[.*\]$", line))
				{
					linkUrl = replaceNoCase(replaceNoCase(line, "[", ""), "]", "");
					arrayAppend(output, {render:'<a href = "' & linkUrl & '">' & linkUrl & '</a>', br:true});
				}

				// Image
				else if(reFindNoCase("^!\[.*\]\(.*\)$", line))
				{
					imageSrc = reMatch("\(.*\)$", line);
					imageSrc = replaceNoCase(replaceNoCase(imageSrc[1], "(", ""), ")", "");
					imageAlt = reMatch("\[.*\]", line);
					imageAlt = replaceNoCase(replaceNoCase(imageAlt[1], "[", ""), "]", "");
					arrayAppend(output, {render:'<img src = "' & imageSrc & '" alt = "' & imageAlt & '" />', br:true});
				}

				// NOTE: need to do tables

				// NOTE: need to do lists

				// Standard Content
				else {arrayAppend(output, {render:line, br:true});}
			}
		}

		// Result
		var result = "";
		for(var element in output)
		{
			result &= element.render;
			if(element.br) {result &= "<br>";}
		}
		return result;
	}

}