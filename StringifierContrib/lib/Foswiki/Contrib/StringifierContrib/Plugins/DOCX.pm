# Copyright (C) 2009 TWIKI.NET (http://www.twiki.net)
# Copyright (C) 2009-2010 Foswiki Contributors
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. For
# more details read LICENSE in the root of this distribution.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# For licensing info read LICENSE file in the Foswiki root.

package Foswiki::Contrib::StringifierContrib::Plugins::DOCX;
use Foswiki::Contrib::StringifierContrib::Base;
our @ISA = qw( Foswiki::Contrib::StringifierContrib::Base );
use File::Temp qw/tmpnam/;
use Encode;
use CharsetDetector;

my $docx2txt = $Foswiki::cfg{StringifierContrib}{docx2txtCmd} || 'docx2txt.pl';

# Only if docx2txt.pl exists, I register myself.
if (__PACKAGE__->_programExists($docx2txt)){
    __PACKAGE__->register_handler("text/docx", ".docx");
}

sub stringForFile {
    my ($self, $filename) = @_;
    
    my $cmd = $docx2txt . ' %FILENAME|F% -';
    my ($output, $exit) = Foswiki::Sandbox->sysCommand($cmd, FILENAME => $filename);
    
    return '' unless ($exit == 0);
   
    # encode text
    my $text = "";
    foreach( split( "\n", $output ) ){
        my $charset = CharsetDetector::detect1($_);
        my $aux_text = "";
        if ($charset =~ "utf") {
            $aux_text = encode("iso-8859-15", decode($charset, $_));
            $aux_text = $_ unless($aux_text);
        } else {
            $aux_text = $_;
        }
        $text .= "\n" . $aux_text;
    }
    return $text;
}

1;
