package Foswiki::Plugins::EditTablePlugin::Data;

use strict;
use warnings;
use Assert;

=pod

Helper class parses tables to take out table texts, and stores table cell data.

=cut

my $RENDER_HACK            = "\n<nop>\n";

our $PATTERN_EDITTABLEPLUGIN = qr'(%EDITTABLE{([^\n]*)}%)'o
  ; # NOTE: greedy match to catch macros inside the parameters - but this requires special handling of TABLE tags directly follow the EDITTABLE tags (on the same line) - see _placeTABLEtagOnSeparateLine
our $PATTERN_TABLEPLUGIN = qr'%TABLE(?:{(.*?)})?%'o;

=pod

Constructor

=cut

sub new {
    my ($class) = @_;
    my $this = {};
    bless $this, $class;
    return $this;
}

=pod

parseText($text)

The guts of this routine was initially copied from SpreadSheetPlugin.pm
and were used in the ChartPlugin Table object which this was copied from,
but this has been modified to support the functionality needed by the
EditTablePlugin.  One major change is to only count and save tables
following an %EDITTABLE{.*}% tag.

This routine basically returns an array of hashes where each hash
contains the information for a single table.  Thus the first hash in the
array represents the first table found on the topic page, the second hash
in the array represents the second table found on the topic page, etc.

=cut

sub parseText {
    my ( $this, $inText ) = @_;

    my $tableNum = 1;    # Table number (only count tables with EDITTABLE tag)
    my @tableMatrix;     # Currently parsed table.

    my $isInEditTable = 0;     # Flag to keep track if in an EDITTABLE table
    my $isInsidePRE   = 0;
    my @tableLines    = ();    # list of table lines inside edit table
    my $editTableData
      ;    # holds data for each edit table: pretag, tag, posttag, text

    my $tablesTakenOutText = '';
    my $editTableObjects;

    # appended stuff is a hack to handle EDITTABLE correctly if at end
    $inText .= $RENDER_HACK;

    # put TABLE tag (if any) on a separate line for easier parsing
    $inText =~ s/$PATTERN_EDITTABLEPLUGIN/&_placeTABLEtagOnSeparateLine($2)/ge;

    foreach ( split( /\n/, $inText ) ) {

        my $doCopyLine      = 1;
        my $hasEditTableTag = 0;

        # change state:
        m#<(?:pre|verbatim)\b#i && ( $isInsidePRE++ );
        m#</(?:pre|verbatim)>#i && ( $isInsidePRE-- );

        # If we are in a pre or verbatim block, ignore it
        if ($isInsidePRE) {
            $tablesTakenOutText .= "$_\n";
            next;
        }

        if (/(.*?)$PATTERN_EDITTABLEPLUGIN([^\n]*)/) {

            $isInEditTable = 1;
            $editTableData->{'pretag'}  .= $1 if $1;
            $editTableData->{'tag'}     .= $2 if $2;
            $editTableData->{'params'}  .= $3 if $3;
            $editTableData->{'posttag'} .= $4 if $4;

            # create stub to be replaced after table parsing
            $_               = "<!--%EDITTABLESTUB{$tableNum}%-->";
            $hasEditTableTag = 1;
        }
        elsif ( $isInEditTable && /$PATTERN_TABLEPLUGIN/ ) {

            # TABLE on a new line after EDITTABLE
            $doCopyLine = 0;
            $editTableData->{'posttag'} .= "\n"
              if defined $editTableData->{'posttag'};
            $editTableData->{'posttag'} .= $_;
            $hasEditTableTag = 1;
        }
        if ( $isInEditTable && !$hasEditTableTag ) {

            if (/^\s*\|.*\|\s*$/) {

                $doCopyLine = 0;
                push( @tableLines, $_ );

                # inside | table |
                my $line = $_;
                $line =~ s/^(\s*\|)(.*)\|\s*$/$2/o;    # Remove starting '|'
                my @row = split( /\|/o, $line, -1 );
                _trimCellsInRow( \@row );
                push( @tableMatrix, [@row] );

            }
            else {

                # outside | table |
                if ($isInEditTable) {

                    # We were inside a table and are now outside of it so
                    # save the table info into the Table object.
                    $isInEditTable = 0;

                    if ( @tableMatrix != 0 ) {

                        # Save the table via its table number
                        $$this{"TABLE_$tableNum"} = [@tableMatrix];
                    }
                    undef @tableMatrix;    # reset table matrix
                }
                else {

                    # not (or no longer) inside a table
                    $doCopyLine    = 1;
                    $isInEditTable = 0;
                }
                $editTableData->{'text'} = join( "\n", @tableLines );

               # also store everything in one variable so we can deal with TABLE
                $editTableData->{'pretag'}  ||= '';
                $editTableData->{'tag'}     ||= '';
                $editTableData->{'posttag'} ||= '';

                $editTableData->{'tagline'} =
                    $editTableData->{'pretag'}
                  . $editTableData->{'tag'}
                  . $editTableData->{'posttag'};
                push( @{$editTableObjects}, $editTableData );
                $tableNum++;

                @tableLines = ();
                undef $editTableData;
            }
        }

        $tablesTakenOutText .= $_ . "\n" if $doCopyLine;
    }    # foreach

    if ($Foswiki::Plugins::EditTablePlugin::debug) {
        use Data::Dumper;
        Foswiki::Func::writeDebug(
            "- EditTablePlugin::parseText; editTableObjects="
              . Dumper($editTableObjects) );
    }

    $this->{editTableObjects} = $editTableObjects;

    my $text = $tablesTakenOutText;

    # clean up hack that handles EDITTABLE correctly if at end
    $text =~ s/$RENDER_HACK$//;

    return $text;
}

=pod

_trimCellsInRow (\@rowCells)

Trim any leading and trailing white space and/or '*'.

=cut

sub _trimCellsInRow {
    my ($rowCells) = @_;
    for my $cell ( @{$rowCells} ) {
        _trimSpaces($cell);
    }
}

=pod

_trimSpaces( $text ) -> $text

Removes spaces from both sides of the text.

=cut

sub _trimSpaces {

    #my $text = $_[0]

    $_[0] =~ s/^[[:space:]]+//s;    # trim at start
    $_[0] =~ s/[[:space:]]+$//s;    # trim at end
}

=pod

Puts %TABLE{}% tags on a new line to better deal with TablePlugin variables: because $PATTERN_EDITTABLEPLUGIN is greedy this tag would otherwise be grabbed together with the EDITTABLE tag

=cut

sub _placeTABLEtagOnSeparateLine {
    my ($tagLine) = @_;

    # unprotect TABLE and put in on a new line
    $tagLine =~ s/%TABLE{/\n%TABLE{/go;

    return "%EDITTABLE{$tagLine}%";
}

=pod

Return the contents of the specified cell

=cut

sub getCell {
    my ( $this, $tableNum, $row, $column ) = @_;

    my @selectedTable = $this->getTable($tableNum);
    my $value         = $selectedTable[$row][$column];
    return $value;
}

=pod

Return an entire table, or an empty list

=cut

sub getTable {
    my ( $this, $tableNumber ) = @_;
    my $table = $$this{"TABLE_$tableNumber"};
    return @$table if defined($table);
    return ();
}

1;

__DATA__
# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2008-2009 Arthur Clemens, arthur@visiblearea.com and Foswiki contributors
# Copyright (C) 2002-2007 Peter Thoeny, peter@thoeny.org and
# TWiki Contributors.
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
# As per the GPL, removal of this notice is prohibited.
#
# This is the EditTablePlugin used to edit tables in place.
