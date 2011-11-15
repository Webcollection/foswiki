# ---+ Extensions
# ---++ StringifierContrib

# **STRING**
# Comma seperated list of webs to skip
$Foswiki::cfg{StringifierContrib}{SkipWebs} = 'Trash';

# **STRING**
# List of topics to skip.
# Topics can be in the form of Web.MyTopic, or if you want a topic to be excluded from all webs just enter MyTopic.
# For example: Main.WikiUsers, WebStatistics
$Foswiki::cfg{StringifierContrib}{SkipTopics} = '';

# **SELECT antiword,wv,abiword**
# Select which MS Word indexer to use (you need to have antiword, abiword or wvText installed)
# <dl>
# <dt>wvText</dt><dd>is the default</dd>
# <dt>antiword</dt><dd>chould be used on Linux/Unix but may have problems with doc files generated by OpenOffice</dd>
# <dt>abiword</dt><dd></dd>
# </dl>
$Foswiki::cfg{StringifierContrib}{WordIndexer} = 'wv';

# **COMMAND**
# Path to your abiword command (used to convert MS word documents: .doc)
$Foswiki::cfg{StringifierContrib}{abiwordCmd} = 'abiword';

# **COMMAND**
# Path to your antiword command (used to convert MS word documents: .doc)<br />
# On a hosted server, you might need to tell antiword where to look for
# its mapping files using some environment directives:<br />
# <code>/usr/bin/env ANTIWORDHOME=/home2/mydomain/.antiword /home2/mydomain/bin/antiword</code>
$Foswiki::cfg{StringifierContrib}{antiwordCmd} = 'antiword';

# **COMMAND**
# Path to your wvText command (used to convert MS word documents: .doc)
$Foswiki::cfg{StringifierContrib}{wvTextCmd} = 'wvText';

# **COMMAND**
# Path to your ppthtml command (used to convert MS powerpoint documents: .ppt)
$Foswiki::cfg{StringifierContrib}{ppthtmlCmd} = 'ppthtml';

# **COMMAND**
# Path to your odt2txt command (used to convert OpenDocument and Staroffice documents: .odt, .odp, sxw, sxc, ...)
$Foswiki::cfg{StringifierContrib}{odt2txt} = 'odt2txt';

# **COMMAND**
# Command used to convert HTML to text, also output of commands which output HTML, such as the ones above.<br />
# Usually html2text from <a href="http://www.mbayer.de/html2text/">http://www.mbayer.de/html2text/</a>
$Foswiki::cfg{StringifierContrib}{htmltotextCmd} = 'html2text -nobs';

# **COMMAND**
# Path to your pdftotext command (used to convert PDF files)
$Foswiki::cfg{StringifierContrib}{pdftotextCmd} = 'pdftotext';

# **COMMAND**
# Path to your pptx2txt.pl command (used to convert MS powerpoint recent documents: .pptx)
$Foswiki::cfg{StringifierContrib}{pptx2txtCmd} = '../tools/pptx2txt.pl';

# **COMMAND**
# Path to your docx2txt.pl command (used to convert MS word recent documents: .docx)
$Foswiki::cfg{StringifierContrib}{docx2txtCmd} = '../tools/docx2txt.pl';

# **COMMAND**
# Path to your xlsx2txt.pl command (used to convert MS excel recent documents: .xlsx)
$Foswiki::cfg{StringifierContrib}{xls2txtCmd} = '../tools/xls2txt.pl';

# **BOOLEAN**
# Debug setting
$Foswiki::cfg{StringifierContrib}{Debug} = 0;

1;