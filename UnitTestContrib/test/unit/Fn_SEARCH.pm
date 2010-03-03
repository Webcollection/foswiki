use strict;
use warnings;

# tests for the correct expansion of SEARCH
# SMELL: this test is pathetic, becase SEARCH has dozens of untested modes

package Fn_SEARCH;

use base qw( FoswikiFnTestCase );

use Foswiki;
use Error qw( :try );

# Load locale if UseLocale on;
# otherwise the Ok+Topic Ok-Topic lexical sort order gets reversed
# locale being a pragma, it has to be in a BEGIN block
# but setlocale has to be outside
BEGIN {
    if ( $Foswiki::cfg{UseLocale} && $Foswiki::cfg{Site}{Locale} ) {
        require POSIX;
        require locale;
        locale::import();
    }
}
POSIX::setlocale( &POSIX::LC_COLLATE, $Foswiki::cfg{Site}{Locale} )
  if ( $Foswiki::cfg{UseLocale} && $Foswiki::cfg{Site}{Locale} );

sub new {
    my $self = shift()->SUPER::new( 'SEARCH', @_ );
    return $self;
}

sub set_up {
    my $this = shift;

    $this->SUPER::set_up();
    $this->{twiki}->{store}->saveTopic( $this->{twiki}->{user},
        $this->{test_web}, 'OkTopic', "BLEEGLE blah/matchme.blah" );
    $this->{twiki}->{store}->saveTopic( $this->{twiki}->{user},
        $this->{test_web}, 'Ok-Topic', "BLEEGLE dontmatchme.blah" );
    $this->{twiki}->{store}->saveTopic( $this->{twiki}->{user},
        $this->{test_web}, 'Ok+Topic', "BLEEGLE dont.matchmeblah" );
}

sub fixture_groups {
    my ( %salgs, %qalgs );
    foreach my $dir (@INC) {
        if ( opendir( D, "$dir/Foswiki/Store/SearchAlgorithms" ) ) {
            foreach my $alg ( readdir D ) {
                next unless $alg =~ /^(.*)\.pm$/;
                $alg = $1;
                $salgs{$alg} = 1;
            }
            closedir(D);
        }
        if ( opendir( D, "$dir/Foswiki/Store/QueryAlgorithms" ) ) {
            foreach my $alg ( readdir D ) {
                next unless $alg =~ /^(.*)\.pm$/;
                $alg = $1;
                $qalgs{$alg} = 1;
            }
            closedir(D);
        }
    }
    my @groups;
    foreach my $alg ( keys %salgs ) {
        my $fn = $alg . 'Search';
        push( @groups, $fn );
        next if ( defined(&$fn) );
        eval <<SUB;
sub $fn {
require Foswiki::Store::SearchAlgorithms::$alg;
\$Foswiki::cfg{RCS}{SearchAlgorithm} = 'Foswiki::Store::SearchAlgorithms::$alg'; }
SUB
        die $@ if $@;
    }
    foreach my $alg ( keys %qalgs ) {
        my $fn = $alg . 'Query';
        push( @groups, $fn );
        next if ( defined(&$fn) );
        eval <<SUB;
sub $fn {
require Foswiki::Store::QueryAlgorithms::$alg;
\$Foswiki::cfg{RCS}{QueryAlgorithm} = 'Foswiki::Store::QueryAlgorithms::$alg'; }
SUB
        die $@ if $@;
    }

    return \@groups;
}

sub verify_simple {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"BLEEGLE" topic="Ok+Topic,Ok-Topic,OkTopic" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/,   $result );
    $this->assert_matches( qr/Ok-Topic/,  $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );
}

sub verify_Item4692 {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
        '%SEARCH{"BLEEGLE" topic="NonExistant" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_str_equals( '', $result );
}

sub verify_angleb {
    my $this = shift;

    # Test regex with \< and \>, used in rename searches
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"\<matc[h]me\>" type="regex" topic="Ok+Topic,Ok-Topic,OkTopic" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/, $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );
}

sub verify_topicName {
    my $this = shift;

    # Test topic name search
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"Ok.*" type="regex" scope="topic" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/,   $result );
    $this->assert_matches( qr/Ok-Topic/,  $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );
}

sub verify_regex_trivial {
    my $this   = shift;
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"blah" type="regex" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/,   $result );
    $this->assert_matches( qr/Ok-Topic/,  $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );
}

sub verify_literal {
    my $this = shift;

    # literal
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"blah" type="literal" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/,   $result );
    $this->assert_matches( qr/Ok-Topic/,  $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );
}

sub verify_keyword {
    my $this = shift;

    # keyword
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"blah" type="keyword" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/,   $result );
    $this->assert_matches( qr/Ok-Topic/,  $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );
}

sub verify_word {
    my $this = shift;

    # word
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"blah" type="word" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/,  $result );
    $this->assert_matches( qr/Ok-Topic/, $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );
}

sub verify_separator {
    my $this = shift;

    # word
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"name~\'*Topic\'" type="query" nonoise="on" format="$topic" separator=","}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_str_equals( join( ',', sort qw(OkTopic Ok-Topic Ok+Topic) ),
        $result );
}

sub verify_separator_with_header {
    my $this = shift;

    # word
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"name~\'*Topic\'" type="query" header="RESULT:" nonoise="on" format="$topic" separator=","}%',
        $this->{test_web}, $this->{test_topic}
    );

    # FIXME: The first , shouldn't be there, but Arthur knows why
    # waiting for him to fix, and as I can't put this test into TODO...
    $this->assert_str_equals(
        "RESULT:\n" . join( ',', sort qw(Ok+Topic Ok-Topic OkTopic) ),
        $result );
}

sub verify_footer_with_ntopics {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"name~\'*Topic\'" type="query"  nonoise="on" footer="Total found: $ntopics" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_str_equals(
        join( "\n", sort qw(Ok+Topic Ok-Topic OkTopic) ) . "\nTotal found: 3",
        $result );
}

sub verify_multiple_and_footer_with_ntopics_and_nhits {
    my $this = shift;

    $this->set_up_for_formatted_search();

    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"Bullet" type="regex" multiple="on" nonoise="on" footer="Total found: $ntopics, Hits: $nhits" format="$text - $nhits"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_str_equals(
"   * Bullet 1 - 1\n   * Bullet 2 - 2\n   * Bullet 3 - 3\n   * Bullet 4 - 4\nTotal found: 1, Hits: 4",
        $result
    );
}

sub verify_footer_with_ntopics_empty_format {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"name~\'*Topic\'" type="query"  nonoise="on" footer="Total found: $ntopics" format="" separator=""}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_str_equals( "Total found: 3", $result );
}

sub verify_regex_match {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"match" type="regex" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/,   $result );
    $this->assert_matches( qr/Ok-Topic/,  $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );
}

sub verify_literal_match {
    my $this = shift;

    # literal
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"match" type="literal" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/,   $result );
    $this->assert_matches( qr/Ok-Topic/,  $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );
}

sub verify_keyword_match {
    my $this = shift;

    # keyword
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"match" type="keyword" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/,   $result );
    $this->assert_matches( qr/Ok-Topic/,  $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );
}

sub verify_word_match {
    my $this = shift;

    # word
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"match" type="word" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_does_not_match( qr/OkTopic/,   $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );
}

sub verify_regex_matchme {
    my $this = shift;

    # ---------------------
    # Search string 'matchme'
    # regex
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"matchme" type="regex" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/,   $result );
    $this->assert_matches( qr/Ok-Topic/,  $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );
}

sub verify_literal_matchme {
    my $this = shift;

    # literal
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"matchme" type="literal" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/,   $result );
    $this->assert_matches( qr/Ok-Topic/,  $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );
}

sub verify_keyword_matchme {
    my $this = shift;

    # keyword
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"matchme" type="keyword" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/,   $result );
    $this->assert_matches( qr/Ok-Topic/,  $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );

}

sub verify_word_matchme {
    my $this = shift;

    # word
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"matchme" type="word" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/, $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );

}

sub verify_minus_regex {
    my $this = shift;

    # ---------------------
    # Search string 'matchme -dont'
    # regex
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"matchme -dont" type="regex" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_does_not_match( qr/OkTopic/,   $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );
}

sub verify_minus_literal {
    my $this = shift;

    # literal
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"matchme -dont" type="literal" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_does_not_match( qr/OkTopic/,   $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );

}

sub verify_minus_keyword {
    my $this = shift;

    # keyword
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"matchme -dont" type="keyword" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/, $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );

}

sub verify_minus_word {
    my $this = shift;

    # word
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"matchme -dont" type="word" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/, $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );

}

sub verify_slash_regex {
    my $this = shift;

    # ---------------------
    # Search string 'blah/matchme.blah'
    # regex
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"blah/matchme.blah" type="regex" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/, $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );

}

sub verify_slash_literal {
    my $this = shift;

    # literal
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"blah/matchme.blah" type="literal" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/, $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );

}

sub verify_slash_keyword {
    my $this = shift;

    # keyword
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"blah/matchme.blah" type="keyword" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/, $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );

}

sub verify_slash_word {
    my $this = shift;

    # word
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"blah/matchme.blah" type="word" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_matches( qr/OkTopic/, $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );

}

sub verify_quote_regex {
    my $this = shift;

    # ---------------------
    # Search string 'BLEEGLE dont'
    # regex
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"\"BLEEGLE dont\"" type="regex" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_does_not_match( qr/OkTopic/,   $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );

}

sub verify_quote_literal {
    my $this = shift;

    # literal
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"\"BLEEGLE dont\"" type="literal" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_does_not_match( qr/OkTopic/,   $result );
    $this->assert_does_not_match( qr/Ok\+Topic/, $result );
    $this->assert_does_not_match( qr/Ok-Topic/,  $result );

}

sub verify_quote_keyword {
    my $this = shift;

    # keyword
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"\"BLEEGLE dont\"" type="keyword" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_does_not_match( qr/OkTopic/, $result );
    $this->assert_matches( qr/Ok-Topic/,  $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );

}

sub verify_quote_word {
    my $this = shift;

    # word
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"\"BLEEGLE dont\"" type="word" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );

    $this->assert_does_not_match( qr/OkTopic/,  $result );
    $this->assert_does_not_match( qr/Ok-Topic/, $result );
    $this->assert_matches( qr/Ok\+Topic/, $result );
}

sub verify_SEARCH_3860 {
    my $this = shift;
    my $result =
      $this->{twiki}
      ->handleCommonTags( <<'HERE', $this->{test_web}, $this->{test_topic} );
%SEARCH{"BLEEGLE" topic="OkTopic" format="$wikiname $wikiusername" nonoise="on" }%
HERE
    my $wn = $this->{twiki}->{users}->getWikiName( $this->{twiki}->{user} );
    $this->assert_str_equals( "$wn $this->{users_web}.$wn\n", $result );
    $result =
      $this->{twiki}
      ->handleCommonTags( <<'HERE', $this->{test_web}, $this->{test_topic} );
%SEARCH{"BLEEGLE" topic="OkTopic" format="$createwikiname $createwikiusername" nonoise="on" }%
HERE
    $this->assert_str_equals( "$wn $this->{users_web}.$wn\n", $result );
}

sub verify_search_empty_regex {
    my $this = shift;

    my $result =
      $this->{twiki}->handleCommonTags(
        '%SEARCH{"" type="regex" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( "", $result );
}

sub verify_search_empty_literal {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
        '%SEARCH{"" type="literal" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( "", $result );
}

sub verify_search_empty_keyword {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
        '%SEARCH{"" type="keyword" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( "", $result );
}

sub verify_search_empty_word {
    my $this = shift;

    my $result =
      $this->{twiki}->handleCommonTags(
        '%SEARCH{"" type="word" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( "", $result );
}

sub verify_search_numpty_regex {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"something.Very/unLikelyTo+search-for;-\)" type="regex" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( "", $result );
}

sub verify_search_numpty_literal {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"something.Very/unLikelyTo+search-for;-)" type="literal" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( "", $result );
}

sub verify_search_numpty_keyword {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"something.Very/unLikelyTo+search-for;-)" type="keyword" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( "", $result );
}

sub verify_search_numpty_word {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"something.Very/unLikelyTo+search-for;-)" type="word" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( "", $result );
}

sub set_up_for_formatted_search {
    my $this = shift;

    my $text = <<'HERE';
%META:TOPICINFO{author="ProjectContributor" date="1169714817" format="1.1" version="1.2"}%
%META:TOPICPARENT{name="TestCaseAutoFormattedSearch"}%
!MichaelAnchor and !AnnaAnchor lived in Skagen in !DenmarkEurope!. There is a very nice museum you can visit!

This text is fill in text which is there to ensure that the unique word below does not show up in a summary.

   * Bullet 1
   * Bullet 2
   * Bullet 3
   * Bullet 4

%META:FORM{name="FormattedSearchForm"}%
%META:FIELD{name="Name" attributes="" title="Name" value="!AnnaAnchor"}%
HERE

    $this->{twiki}->{store}->saveTopic(
        $this->{twiki}->{user},  $this->{test_web},
        'FormattedSearchTopic1', $text
    );
}

sub verify_formatted_search_summary_with_exclamation_marks {
    my $this    = shift;
    my $session = $this->{twiki};

    $this->set_up_for_formatted_search();
    my $actual, my $expected;
    $actual = $session->handleCommonTags(
'%SEARCH{"Anna" topic="FormattedSearchTopic1" type="regex" multiple="on" casesensitive="on" nosearch="on" noheader="on" nototal="on" format="$summary"}%',
        $this->{test_web}, $this->{test_topic}
    );
    $actual =
      $session->renderer->getRenderedVersion( $actual, $this->{test_web},
        $this->{test_topic} );
    $expected =
'<nop>MichaelAnchor and <nop>AnnaAnchor lived in Skagen in <nop>DenmarkEurope!. There is a very nice museum you can visit!';
    $this->assert_str_equals( $expected, $actual );

    $actual = $session->handleCommonTags(
'%SEARCH{"Anna" topic="FormattedSearchTopic1" type="regex" multiple="on" casesensitive="on" nosearch="on" noheader="on" nototal="on" format="$formfield(Name)"}%',
        $this->{test_web}, $this->{test_topic}
    );
    $actual =
      $session->renderer->getRenderedVersion( $actual, $this->{test_web},
        $this->{test_topic} );
    $expected = '<nop>AnnaAnchor';
    $this->assert_str_equals( $expected, $actual );
}

sub verify_METASEARCH {
    my $this    = shift;
    my $session = $this->{twiki};

    $this->set_up_for_formatted_search();
    my $actual, my $expected;

    $actual = $session->handleCommonTags(
'%METASEARCH{type="topicmoved" topic="FormattedSearchTopic1" title="This topic used to exist and was moved to: "}%',
        $this->{test_web}, $this->{test_topic}
    );
    $actual =
      $session->renderer->getRenderedVersion( $actual, $this->{test_web},
        $this->{test_topic} );
    $expected = 'This topic used to exist and was moved to: ';
    $this->assert_str_equals( $expected, $actual );

    $actual = $session->handleCommonTags(
'%METASEARCH{type="parent" topic="TestCaseAutoFormattedSearch" title="Children: "}%',
        $this->{test_web}, $this->{test_topic}
    );
    $actual =
      $session->renderer->getRenderedVersion( $actual, $this->{test_web},
        $this->{test_topic} );
    $expected = $session->renderer->getRenderedVersion(
        'Children: FormattedSearchTopic1 ',
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( $expected, $actual );
}

sub set_up_for_queries {
    my $this = shift;
    my $text = <<'HERE';
%META:TOPICINFO{author="TopicUserMapping_guest" date="1178612772" format="1.1" version="1.1"}%
%META:TOPICPARENT{name="WebHome"}%
something before. Another
This is QueryTopic FURTLE
somethig after
%META:FORM{name="TestForm"}%
%META:FIELD{name="Field1" attributes="H" title="A Field" value="A Field"}%
%META:FIELD{name="Field2" attributes="" title="Another Field" value="2"}%
%META:FIELD{name="Firstname" attributes="" title="First Name" value="Emma"}%
%META:FIELD{name="Lastname" attributes="" title="First Name" value="Peel"}%
%META:TOPICMOVED{by="TopicUserMapping_guest" date="1176311052" from="Sandbox.TestETP" to="Sandbox.TestEarlyTimeProtocol"}%
%META:FILEATTACHMENT{name="README" comment="Blah Blah" date="1157965062" size="5504"}%
HERE
    $this->{twiki}->{store}->saveTopic( $this->{twiki}->{user},
        $this->{test_web}, 'QueryTopic', $text );

    $text = <<'HERE';
%META:TOPICINFO{author="TopicUserMapping_guest" date="12" format="1.1" version="1.2"}%
first line
This is QueryTopicTwo SMONG
third line
%META:TOPICPARENT{name="QueryTopic"}%
%META:FORM{name="TestyForm"}%
%META:FIELD{name="FieldA" attributes="H" title="B Field" value="7"}%
%META:FIELD{name="FieldB" attributes="" title="Banother Field" value="8"}%
%META:FIELD{name="Firstname" attributes="" title="Pre Name" value="John"}%
%META:FIELD{name="Lastname" attributes="" title="Post Name" value="Peel"}%
%META:FIELD{name="form" attributes="" title="Blah" value="form good"}%
%META:FIELD{name="FORM" attributes="" title="Blah" value="FORM GOOD"}%
%META:FILEATTACHMENT{name="porn.gif" comment="Cor" date="15062" size="15504"}%
%META:FILEATTACHMENT{name="flib.xml" comment="Cor" date="1157965062" size="1"}%
HERE
    $this->{twiki}->{store}->saveTopic( $this->{twiki}->{user},
        $this->{test_web}, 'QueryTopicTwo', $text );

    $this->{twiki}->finish();
    my $query = new Unit::Request("");
    $query->path_info("/$this->{test_web}/$this->{test_topic}");

    $this->{twiki} = new Foswiki( undef, $query );
    $this->assert_str_equals( $this->{test_web}, $this->{twiki}->{webName} );
    $Foswiki::Plugins::SESSION = $this->{twiki};
}

# NOTE: most query ops are tested in Fn_IF.pm, and are not re-tested here

my $stdCrap = 'type="query" nonoise="on" format="$topic" separator=" "}%';

sub verify_parentQuery {
    my $this = shift;

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"parent.name=\'WebHome\'"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopic', $result );
}

sub verify_attachmentSizeQuery1 {
    my $this = shift;

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"attachments[size > 0]"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopic QueryTopicTwo', $result );
}

sub verify_attachmentSizeQuery2 {
    my $this = shift;

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}->handleCommonTags(
        '%SEARCH{"META:FILEATTACHMENT[size > 10000]"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopicTwo', $result );
}

sub verify_indexQuery {
    my $this = shift;

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"attachments[name=\'flib.xml\']"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopicTwo', $result );
}

sub verify_gropeQuery {
    my $this = shift;

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"Lastname=\'Peel\'"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopic QueryTopicTwo', $result );
}

sub verify_4580Query1 {
    my $this = shift;

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}->handleCommonTags(
        '%SEARCH{"text ~ \'*SMONG*\' AND Lastname=\'Peel\'"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopicTwo', $result );
}

sub verify_4580Query2 {
    my $this = shift;

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}->handleCommonTags(
        '%SEARCH{"text ~ \'*FURTLE*\' AND Lastname=\'Peel\'"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopic', $result );
}

sub verify_gropeQuery2 {
    my $this = shift;

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"Lastname=\'Peel\'"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopic QueryTopicTwo', $result );
}

sub verify_formQuery {
    my $this = shift;

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"form.name=\'TestyForm\'"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopicTwo', $result );
}

sub verify_formQuery2 {
    my $this = shift;

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}->handleCommonTags( '%SEARCH{"TestForm"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopic', $result );
}

sub verify_formQuery3 {
    my $this = shift;

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}->handleCommonTags(
        '%SEARCH{"TestForm[name=\'Field1\'].value=\'A Field\'"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopic', $result );
}

sub verify_formQuery4 {
    my $this = shift;

    if (   $Foswiki::cfg{OS} eq 'WINDOWS'
        && $Foswiki::cfg{DetailedOS} ne 'cygwin' )
    {
        $this->expect_failure();
        $this->annotate("THIS IS WINDOWS; Test will fail because of Item1072");
    }
    $this->set_up_for_queries();
    my $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"TestForm.Field1=\'A Field\'"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopic', $result );
}

sub verify_formQuery5 {
    my $this = shift;

    if (   $Foswiki::cfg{OS} eq 'WINDOWS'
        && $Foswiki::cfg{DetailedOS} ne 'cygwin' )
    {
        $this->expect_failure();
        $this->annotate("THIS IS WINDOWS; Test will fail because of Item1072");
    }

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"TestyForm.form=\'form good\'"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopicTwo', $result );
    $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"TestyForm.FORM=\'FORM GOOD\'"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopicTwo', $result );
}

sub verify_refQuery {
    my $this = shift;

    $this->set_up_for_queries();
    my $result = $this->{twiki}->handleCommonTags(
        '%SEARCH{"parent.name/(Firstname ~ \'*mm?\' AND Field2=2)"' . $stdCrap,
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( 'QueryTopicTwo', $result );
}

# make sure syntax errors are handled cleanly. All the error cases thrown by
# the infix parser are tested more thoroughly in Fn_IF, and don't have to
# be re-tested here.
sub test_badQuery1 {
    my $this = shift;

    $this->set_up_for_queries();
    my $result = $this->{twiki}->handleCommonTags( '%SEARCH{"A * B"' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_matches( qr/Error was: Syntax error in 'A \* B' at ' \* B'/s,
        $result );
}

# Compare performance of an RE versus a query. Only enable this if you are
# interested in benchmarking.
sub benchmarktest_largeQuery {
    my $this = shift;

    # Generate 1000 topics
    # half (500) of these match the first term of the AND
    # 100 match the second
    # 10 match the third
    # 1 matches the fourth

    for my $n ( 1 .. 21 ) {
        my $vA = ( $n <= 500 ) ? 'A' : 'B';
        my $vB = ( $n <= 100 ) ? 'A' : 'B';
        my $vC = ( $n <= 10 )  ? 'A' : 'B';
        my $vD = ( $n == 1 )   ? 'A' : 'B';
        my $vE = ( $n == 2 )   ? 'A' : 'B';
        my $text = <<HERE;
%META:TOPICINFO{author="TopicUserMapping_guest" date="12" format="1.1" version="1.2"}%
---+ Progressive Sexuality
A Symbol Interpreted In American Architecture. Meta-Physics Of Marxism & Poverty In The American Landscape. Exploration Of Crime In Mexican Sculptures: A Study Seen In American Literature. Brief Survey Of Suicide In Italian Art: The Big Picture. Special Studies In Bisexual Female Architecture. Brief Survey Of Suicide In Polytheistic Literature: Analysis, Analysis, and Critical Thinking. Radical Paganism: Modern Theories. Liberal Mexican Religion In The Modern Age. Selected Topics In Global Warming: $vD Policy In Modern America. Survey Of The Aesthetic Minority Revolution In The American Landscape. Populist Perspectives: Myth & Reality. Ethnicity In Modern America: The Bisexual Latino Condition. Postmodern Marxism In Modern America. Female Literature As A Progressive Genre. Horror & Life In Recent Times. The Universe Of Female Values In The Postmodern Era.

---++ Work, Politics, And Conflict In European Drama: A Symbol Interpreted In 20th Century Poetry
Sexuality & Socialism In Modern Society. Special Studies In Early Egyptian Art: A Study Of Globalism In The United States. Meta-Physics Of Synchronized Swimming: The Baxter-Floyd Principle At Work. Ad-Hoc Investigation Of Sex In Middle Eastern Art: Contemporary Theories. Concepts In Eastern Mexican Folklore. The Liberated Dimension Of Western Minority Mythology. French Art Interpretation: A Figure Interpreted In American Drama

---+ Theories Of Liberal Pre-Cubism & The Crowell Law.
We are committed to enhance vertical sub-functionalities and skill sets. Our function is to competently reinvent our mega-relationships. Our responsibility is to expertly engineer content. Our obligation is to continue to zealously simplify our customer-centric paradigms as part of our five-year plan to successfully market an overhyped more expensive line of products and produce more dividends for our serfs. $vA It is our mission to optimize progressive schemas and supply-chains to better serve the country. We are committed to astutely deliver our net-niches, user-centric face time, and assets in order to dominate the economy. It is our goal to conveniently facilitate our e-paradigms, our frictionless skill sets, and our architectures to shore up revenue for our workers. Our goal is to work towards skillfully enabling catalysts for metrics.

We resolve to endeavor to synthesize our sub-partnerships in order that we may intelligently unleash bleeding-edge total quality management as part of our master plan to burgeon our bottom line. It is our business to work to enhance our initiatives in order that we may take $vB over the nation and take over the country. It's our task to reinvent massively-parallel relationships. We execute a strategic plan to quickly facilitate our niches and enthusiastically maximize our extensible perspectives.

Our obligation is to work to spearhead cutting-edge portals so that hopefully we may successfully market an overhyped poor product line.

We have committed to work to effectively facilitate global e-channels as part of a larger $vC strategy to create a higher quality product and create a lot of bucks. Our duty is to work to empower our revolutionary functionalities and simplify our idiot-proof synergies as a component of our plan to beat the snot out of our enemies. We resolve to engage our mega-eyeballs, our e-bandwidth, and intuitive face time in order to earn a lot of scratch. It's our obligation to generate our niches.

---+ It is our job to strive to simplify our bandwidth.
We have committed to enable customer-centric supply-chains and our mega-channels as part of our business plan to meet the wants of our valued customers.
We have committed to take steps towards $vE reinventing our cyber-key players and harnessing frictionless net-communities so that hopefully we may better serve our customers.
%META:FORM{name="TestForm"}%
%META:FIELD{name="FieldA" attributes="" title="Banother Field" value="$vA"}%
%META:FIELD{name="FieldB" attributes="" title="Banother Field" value="$vB"}%
%META:FIELD{name="FieldC" attributes="" title="Banother Field" value="$vC"}%
%META:FIELD{name="FieldD" attributes="" title="Banother Field" value="$vD"}%
%META:FIELD{name="FieldE" attributes="" title="Banother Field" value="$vE"}%
HERE
        $this->{twiki}->{store}->saveTopic( $this->{twiki}->{user},
            $this->{test_web}, "QueryTopic$n", $text );
    }
    require Benchmark;

    # Search using a regular expression
    my $start  = new Benchmark;
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"^[%]META:FIELD{name=\"FieldA\".*\bvalue=\"A\";^[%]META:FIELD{name=\"FieldB\".*\bvalue=\"A\";^[%]META:FIELD{name=\"FieldC\".*\bvalue=\"A\";^[%]META:FIELD{name=\"FieldD\".*\bvalue=\"A\"|^[%]META:FIELD{name=\"FieldE\".*\bvalue=\"A\"" type="regex" nonoise="on" format="$topic" separator=" "}%',
        $this->{test_web}, $this->{test_topic}
    );
    my $retime = Benchmark::timediff( new Benchmark, $start );
    $this->assert_str_equals( 'QueryTopic1 QueryTopic2', $result );

    # Repeat using a query
    $start  = new Benchmark;
    $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"FieldA=\'A\' AND FieldB=\'A\' AND FieldC=\'A\' AND (FieldD=\'A\' OR FieldE=\'A\')" type="query" nonoise="on" format="$topic" separator=" "}%',
        $this->{test_web}, $this->{test_topic}
    );
    my $querytime = Benchmark::timediff( new Benchmark, $start );
    $this->assert_str_equals( 'QueryTopic1 QueryTopic2', $result );
    print STDERR "Query " . Benchmark::timestr($querytime),
      "\nRE " . Benchmark::timestr($retime), "\n";
}

sub verify_4347 {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
"%SEARCH{\"$this->{test_topic}\" scope=\"topic\" nonoise=\"on\" format=\"\$formfield(Blah)\"}%",
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( '', $result );
}

sub verify_likeQuery {
    my $this = shift;

    $this->set_up_for_queries();
    my $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"text ~ \'*SMONG*\'" ' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopicTwo', $result );

    $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"text ~ \'*QueryTopicTwo*\'" ' . $stdCrap,
        $this->{test_web}, $this->{test_topic} );
    $this->assert_str_equals( 'QueryTopicTwo', $result );

    $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"text ~ \'*SMONG*\'" ' . $stdCrap,
        $this->{test_web}, 'QueryTopicTwo' );
    $this->assert_str_equals( 'QueryTopicTwo', $result );

    $result =
      $this->{twiki}
      ->handleCommonTags( '%SEARCH{"text ~ \'*QueryTopicTwo*\'" ' . $stdCrap,
        $this->{test_web}, 'QueryTopicTwo' );
    $this->assert_str_equals( 'QueryTopicTwo', $result );

}

sub verify_likeQuery2 {
    my $this = shift;

    $this->set_up_for_queries();
    my $result = $this->{twiki}->handleCommonTags(
        '%SEARCH{"text ~ \'*SMONG*\'" web="'
          . $this->{test_web} . '" '
          . $stdCrap,
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( 'QueryTopicTwo', $result );

    $result = $this->{twiki}->handleCommonTags(
        '%SEARCH{"text ~ \'*QueryTopicTwo*\'" web="'
          . $this->{test_web} . '" '
          . $stdCrap,
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( 'QueryTopicTwo', $result );

    $result = $this->{twiki}->handleCommonTags(
        '%SEARCH{"text ~ \'*SMONG*\'" web="'
          . $this->{test_web} . '" '
          . $stdCrap,
        $this->{test_web}, 'QueryTopicTwo'
    );
    $this->assert_str_equals( 'QueryTopicTwo', $result );

    $result = $this->{twiki}->handleCommonTags(
        '%SEARCH{"text ~ \'*QueryTopicTwo*\'" web="'
          . $this->{test_web} . '" '
          . $stdCrap,
        $this->{test_web}, 'QueryTopicTwo'
    );
    $this->assert_str_equals( 'QueryTopicTwo', $result );

    $result = $this->{twiki}->handleCommonTags(
        '%SEARCH{"text ~ \'*Notinthetopics*\'" web="'
          . $this->{test_web} . '" '
          . $stdCrap,
        $this->{test_web}, 'QueryTopicTwo'
    );
    $this->assert_str_equals( '', $result );

    $result = $this->{twiki}->handleCommonTags(
        '%SEARCH{"text ~ \'*before. Another*\'" web="'
          . $this->{test_web} . '" '
          . $stdCrap,
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( 'QueryTopic', $result );
}

sub test_pattern {
    my $this = shift;

    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"BLEEGLE" topic="Ok+Topic,Ok-Topic,OkTopic" nonoise="on" format="X$pattern(.*?BLEEGLE (.*?)blah.*)Y"}%',
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_matches( qr/Xdontmatchme\.Y/, $result );
    $this->assert_matches( qr/Xdont.matchmeY/,  $result );
    $this->assert_matches( qr/XY/,              $result );
}

sub test_badpattern {
    my $this = shift;

    # The (??{ pragma cannot be run at runtime since perl 5.5
    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"BLEEGLE" topic="Ok+Topic,Ok-Topic,OkTopic" nonoise="on" format="X$pattern(.*?BL(??{\'E\' x 2})GLE( .*?)blah.*)Y"}%',
        $this->{test_web}, $this->{test_topic}
    );

    # If (??{ is evaluated, the topics should match:
    $this->assert_does_not_match( qr/XdontmatchmeY/,  $result );
    $this->assert_does_not_match( qr/Xdont.matchmeY/, $result );
    $this->assert_does_not_match( qr/X Y/,            $result );

    # If (??{ isn't evaluated, $pattern should return empty
    # and format should be XY for all 3 topics
    $this->assert_equals( 3, $result =~ s/^XY$//gm );
}

sub test_validatepattern {
    my $this = shift;
    my ( $pattern, $temp );

    # Test comment
    $pattern = Foswiki::validatePattern('foo(?#comment)bar');
    $this->assert_matches( qr/$pattern/, 'foobar' );

    # Test clustering and pattern-match modifiers
    $pattern = Foswiki::validatePattern('(?i:foo)(?-i)bar');
    $this->assert_matches( qr/$pattern/, 'FoObar' );
    $this->assert_does_not_match( qr/$pattern/, 'FoObAr' );

    # Test zero-width positive look-ahead
    $pattern = Foswiki::validatePattern('foo(?=bar)');
    $this->assert_matches( qr/$pattern/, 'foobar' );
    $this->assert_does_not_match( qr/$pattern/, 'barfoo bar' );
    $temp = 'foobar';
    $this->assert_equals( 1, $temp =~ s/$pattern// );
    $this->assert_equals( 'bar', $temp );

    # Test zero-width negative look-ahead
    $pattern = Foswiki::validatePattern('foo(?!bar)');
    $this->assert_does_not_match( qr/$pattern/, 'foobar' );
    $this->assert_matches( qr/$pattern/, 'barfoo bar' );
    $this->assert_matches( qr/$pattern/, 'foo' );
    $temp = 'fooblue';
    $this->assert_equals( 1, $temp =~ s/$pattern// );
    $this->assert_equals( 'blue', $temp );

    # Test independent sub-expression
    $pattern = Foswiki::validatePattern('foo(?>blue)bar');
    $this->assert_matches( qr/$pattern/, 'foobluebar' );

}

#Item977
sub verify_formatOfLinks {
    my $this = shift;

    $this->{twiki}->{store}->saveTopic(
        $this->{twiki}->{user},
        $this->{test_web}, 'Item977', "---+ Apache

Apache is the [[http://www.apache.org/httpd/][well known web server]].
"
    );

    my $result =
      $this->{twiki}->handleCommonTags(
        '%SEARCH{"Item977" scope="topic" nonoise="on" format="$summary"}%',
        $this->{test_web}, $this->{test_topic} );

    $this->assert_str_equals( 'Apache Apache is the well known web server.',
        $result );

#TODO: these test should move to a proper testing of Render.pm - will happen during
#extractFormat feature
    $this->assert_str_equals(
        'Apache is the well known web server.',
        $this->{twiki}->{renderer}->TML2PlainText(
'Apache is the [[http://www.apache.org/httpd/][well known web server]].'
        )
    );

    #test a few others to try to not break things
    $this->assert_str_equals(
        'Apache is the well known web server.',
        $this->{twiki}->{renderer}->TML2PlainText(
'Apache is the [[http://www.apache.org/httpd/ well known web server]].'
        )
    );
    $this->assert_str_equals(
        'Apache is the well known web server.',
        $this->{twiki}->{renderer}->TML2PlainText(
            'Apache is the [[ApacheServer][well known web server]].')
    );

    #SMELL: an unexpected result :/
    $this->assert_str_equals( 'Apache is the   well known web server  .',
        $this->{twiki}->{renderer}
          ->TML2PlainText('Apache is the [[well known web server]].') );
    $this->assert_str_equals( 'Apache is the well known web server.',
        $this->{twiki}->{renderer}
          ->TML2PlainText('Apache is the well known web server.') );

}

sub verify_casesensitivesetting {
    my $this    = shift;
    my $session = $this->{session};

    my $actual, my $expected;

    $actual = $this->{twiki}->handleCommonTags(
'%SEARCH{"BLEEGLE" type="regex" multiple="on" casesensitive="on" nosearch="on" noheader="on" nototal="on" format="<nop>$topic" separator=","}%',
        $this->{test_web}, $this->{test_topic}
    );

    #$actual = $this->{test_topicObject}->renderTML($actual);
    $expected = '<nop>' . join ',<nop>',
      sort qw(OkTopic Ok-Topic Ok+Topic TestTopicSEARCH);
    $this->assert_str_equals( $expected, $actual );

    $actual = $this->{twiki}->handleCommonTags(
'%SEARCH{"bleegle" type="regex" multiple="on" casesensitive="on" nosearch="on" noheader="on" nototal="on" format="<nop>$topic" separator=","}%',
        $this->{test_web}, $this->{test_topic}
    );

    #$actual = $this->{test_topicObject}->renderTML($actual);
    $expected = '';
    $this->assert_str_equals( $expected, $actual );

    $actual = $this->{twiki}->handleCommonTags(
'%SEARCH{"BLEEGLE" type="regex" multiple="on" casesensitive="off" nosearch="on" noheader="on" nototal="on" format="<nop>$topic" separator=","}%',
        $this->{test_web}, $this->{test_topic}
    );

    #$actual = $this->{test_topicObject}->renderTML($actual);
    $expected = '<nop>' . join ',<nop>',
      sort qw(OkTopic Ok-Topic Ok+Topic TestTopicSEARCH);
    $this->assert_str_equals( $expected, $actual );

    $actual = $this->{twiki}->handleCommonTags(
'%SEARCH{"bleegle" type="regex" multiple="on" casesensitive="off" nosearch="on" noheader="on" nototal="on" format="<nop>$topic" separator=","}%',
        $this->{test_web}, $this->{test_topic}
    );

    #$actual = $this->{test_topicObject}->renderTML($actual);
    $expected = '<nop>' . join ',<nop>',
      sort qw(OkTopic Ok-Topic Ok+Topic TestTopicSEARCH);
    $this->assert_str_equals( $expected, $actual );

    #topic scope
    $actual = $this->{twiki}->handleCommonTags(
'%SEARCH{"Ok" type="regex" scope="topic" multiple="on" casesensitive="on" nosearch="on" noheader="on" nototal="on" format="<nop>$topic" separator=","}%',
        $this->{test_web}, $this->{test_topic}
    );

    #$actual = $this->{test_topicObject}->renderTML($actual);
    $expected = '<nop>' . join ',<nop>', sort qw(OkTopic Ok-Topic Ok+Topic);
    $this->assert_str_equals( $expected, $actual );

    $actual = $this->{twiki}->handleCommonTags(
'%SEARCH{"ok" type="regex" scope="topic" multiple="on" casesensitive="on" nosearch="on" noheader="on" nototal="on" format="<nop>$topic" separator=","}%',
        $this->{test_web}, $this->{test_topic}
    );

    #$actual = $this->{test_topicObject}->renderTML($actual);
    $expected = '';
    $this->assert_str_equals( $expected, $actual );

    $actual = $this->{twiki}->handleCommonTags(
'%SEARCH{"Ok" type="regex" scope="topic" multiple="on" casesensitive="off" nosearch="on" noheader="on" nototal="on" format="<nop>$topic" separator=","}%',
        $this->{test_web}, $this->{test_topic}
    );

    #$actual = $this->{test_topicObject}->renderTML($actual);
    $expected = '<nop>' . join ',<nop>', sort qw(OkTopic Ok-Topic Ok+Topic);
    $this->assert_str_equals( $expected, $actual );

    $actual = $this->{twiki}->handleCommonTags(
'%SEARCH{"ok" type="regex" scope="topic" multiple="on" casesensitive="off" nosearch="on" noheader="on" nototal="on" format="<nop>$topic" separator=","}%',
        $this->{test_web}, $this->{test_topic}
    );

    #$actual = $this->{test_topicObject}->renderTML($actual);
    $expected = '<nop>' . join ',<nop>', sort qw(OkTopic Ok-Topic Ok+Topic);
    $this->assert_str_equals( $expected, $actual );

}

#####################
sub _septic {
    my ( $this, $head, $foot, $sep, $results, $expected ) = @_;
    my $str = $results ? '*Topic' : 'Septic';
    $head = $head        ? 'header="HEAD"'      : '';
    $foot = $foot        ? 'footer="FOOT"'      : '';
    $sep  = defined $sep ? "separator=\"$sep\"" : '';
    my $result = $this->{twiki}->handleCommonTags(
"%SEARCH{\"name~'$str'\" type=\"query\" nosearch=\"on\" nosummary=\"on\" nototal=\"on\" format=\"\$topic\" $head $foot $sep}%",
        $this->{test_web}, $this->{test_topic}
    );
    $expected =~ s/\n$//s;
    $this->assert_str_equals( $expected, $result );
}

#####################

sub verify_no_header_no_footer_no_separator_with_results {
    my $this = shift;
    $this->_septic( 0, 0, undef, 1, <<EXPECT);
Ok+Topic
Ok-Topic
OkTopic
EXPECT
}

sub verify_no_header_no_footer_no_separator_no_results {
    my $this = shift;
    $this->_septic( 0, 0, undef, 0, <<EXPECT);
EXPECT
}

sub verify_no_header_no_footer_empty_separator_with_results {
    my $this = shift;
    $this->_septic( 0, 0, "", 1, <<EXPECT);
Ok+TopicOk-TopicOkTopic
EXPECT
}

sub verify_no_header_no_footer_empty_separator_no_results {
    my $this = shift;
    $this->_septic( 0, 0, "", 0, <<EXPECT);
EXPECT
}

sub verify_no_header_no_footer_with_separator_with_results {
    my $this = shift;
    $this->_septic( 0, 0, ",", 1, <<EXPECT);
Ok+Topic,Ok-Topic,OkTopic
EXPECT
}

sub verify_no_header_no_footer_with_separator_no_results {
    my $this = shift;
    $this->_septic( 0, 0, ",", 0, <<EXPECT);
EXPECT
}
#####################

sub verify_no_header_with_footer_no_separator_with_results {
    my $this = shift;
    $this->_septic( 0, 1, undef, 1, <<EXPECT);
Ok+Topic
Ok-Topic
OkTopic
FOOT
EXPECT
}

sub verify_no_header_with_footer_no_separator_no_results {
    my $this = shift;
    $this->_septic( 0, 1, undef, 0, <<EXPECT);
EXPECT
}

sub verify_no_header_with_footer_empty_separator_with_results {
    my $this = shift;
    $this->_septic( 0, 1, "", 1, <<EXPECT);
Ok+TopicOk-TopicOkTopicFOOT
EXPECT
}

sub verify_no_header_with_footer_empty_separator_no_results {
    my $this = shift;
    $this->_septic( 0, 1, "", 0, <<EXPECT);
EXPECT
}

sub verify_no_header_with_footer_with_separator_with_results {
    my $this = shift;
    $this->_septic( 0, 1, ",", 1, <<EXPECT);
Ok+Topic,Ok-Topic,OkTopic,FOOT
EXPECT
}

#####################

sub verify_with_header_with_footer_no_separator_with_results {
    my $this = shift;
    $this->_septic( 1, 1, undef, 1, <<EXPECT);
HEAD
Ok+Topic
Ok-Topic
OkTopic
FOOT
EXPECT
}

sub verify_with_header_with_footer_no_separator_no_results {
    my $this = shift;
    $this->_septic( 1, 1, undef, 0, <<EXPECT);
EXPECT
}

sub verify_with_header_with_footer_empty_separator_with_results {
    my $this = shift;
    $this->_septic( 1, 1, "", 1, <<EXPECT);
HEAD
Ok+TopicOk-TopicOkTopicFOOT
EXPECT
}

sub verify_with_header_with_footer_empty_separator_no_results {
    my $this = shift;
    $this->_septic( 1, 1, "", 0, <<EXPECT);
EXPECT
}

sub verify_with_header_with_footer_with_separator_with_results {
    my $this = shift;
    $this->_septic( 1, 1, ",", 1, <<EXPECT);
HEAD
Ok+Topic,Ok-Topic,OkTopic,FOOT
EXPECT
}

sub verify_with_header_with_footer_with_separator_no_results {
    my $this = shift;
    $this->_septic( 1, 1, ",", 0, <<EXPECT);
EXPECT
}

#####################

sub verify_with_header_no_footer_no_separator_with_results {
    my $this = shift;
    $this->_septic( 1, 0, undef, 1, <<EXPECT);
HEAD
Ok+Topic
Ok-Topic
OkTopic
EXPECT
}

sub verify_with_header_no_footer_no_separator_no_results {
    my $this = shift;
    $this->_septic( 1, 0, undef, 0, <<EXPECT);
EXPECT
}

sub verify_with_header_no_footer_empty_separator_with_results {
    my $this = shift;
    $this->_septic( 1, 0, "", 1, <<EXPECT);
HEAD
Ok+TopicOk-TopicOkTopic
EXPECT
}

sub verify_with_header_no_footer_empty_separator_no_results {
    my $this = shift;
    $this->_septic( 1, 0, "", 0, <<EXPECT);
EXPECT
}

sub verify_with_header_no_footer_with_separator_with_results {
    my $this = shift;
    $this->_septic( 1, 0, ",", 1, <<EXPECT);
HEAD
Ok+Topic,Ok-Topic,OkTopic
EXPECT
}

sub verify_with_header_no_footer_with_separator_no_results {
    my $this = shift;
    $this->_septic( 1, 0, ",", 0, <<EXPECT);
EXPECT
}

#####################
#and again for multiple webs. :(
#TODO: rewrite using named params for more flexibility
#need summary, and multiple
sub _multiWebSeptic {
    my ( $this, $head, $foot, $sep, $results, $expected ) = @_;
    my $str = $results ? '*Preferences' : 'Septic';
    $head = $head        ? 'header="HEAD($web)"'            : '';
    $foot = $foot        ? 'footer="FOOT($ntopics,$nhits)"' : '';
    $sep  = defined $sep ? "separator=\"$sep\""             : '';
    my $result = $this->{twiki}->handleCommonTags(
"%SEARCH{\"name~'$str'\" web=\"System,Main\" type=\"query\" nosearch=\"on\" nosummary=\"on\" nototal=\"on\" format=\"\$topic\" $head $foot $sep}%",
        $this->{test_web}, $this->{test_topic}
    );
    $expected =~ s/\n$//s;
    $this->assert_str_equals( $expected, $result );
}

#####################

sub verify_multiWeb_no_header_no_footer_no_separator_with_results {
    my $this = shift;
    $this->_multiWebSeptic( 0, 0, undef, 1, <<EXPECT);
DefaultPreferences
WebPreferences
SitePreferences
WebPreferences
EXPECT
}

sub verify_multiWeb_no_header_no_footer_no_separator_no_results {
    my $this = shift;
    $this->_multiWebSeptic( 0, 0, undef, 0, <<EXPECT);
EXPECT
}

sub verify_multiWeb_no_header_no_footer_empty_separator_with_results {
    my $this = shift;
    $this->_multiWebSeptic( 0, 0, "", 1, <<EXPECT);
DefaultPreferencesWebPreferencesSitePreferencesWebPreferences
EXPECT
}

sub verify_multiWeb_no_header_no_footer_empty_separator_no_results {
    my $this = shift;
    $this->_multiWebSeptic( 0, 0, "", 0, <<EXPECT);
EXPECT
}

sub verify_multiWeb_no_header_no_footer_with_separator_with_results {
    my $this = shift;
    $this->_multiWebSeptic( 0, 0, ",", 1, <<EXPECT);
DefaultPreferences,WebPreferences,SitePreferences,WebPreferences
EXPECT
}

sub verify_multiWeb_no_header_no_footer_with_separator_no_results {
    my $this = shift;
    $this->_multiWebSeptic( 0, 0, ",", 0, <<EXPECT);
EXPECT
}
#####################

sub verify_multiWeb_no_header_with_footer_no_separator_with_results {
    my $this = shift;
    $this->_multiWebSeptic( 0, 1, undef, 1, <<EXPECT);
DefaultPreferences
WebPreferences
FOOT(2,2)SitePreferences
WebPreferences
FOOT(2,2)
EXPECT
}

sub verify_multiWeb_no_header_with_footer_no_separator_no_results {
    my $this = shift;
    $this->_multiWebSeptic( 0, 1, undef, 0, <<EXPECT);
EXPECT
}

sub verify_multiWeb_no_header_with_footer_empty_separator_with_results {
    my $this = shift;
    $this->_multiWebSeptic( 0, 1, "", 1, <<EXPECT);
DefaultPreferencesWebPreferencesFOOT(2,2)SitePreferencesWebPreferencesFOOT(2,2)
EXPECT
}

sub verify_multiWeb_no_header_with_footer_empty_separator_no_results {
    my $this = shift;
    $this->_multiWebSeptic( 0, 1, "", 0, <<EXPECT);
EXPECT
}

sub verify_multiWeb_no_header_with_footer_with_separator_with_results {
    my $this = shift;
    $this->_multiWebSeptic( 0, 1, ",", 1, <<EXPECT);
DefaultPreferences,WebPreferences,FOOT(2,2)SitePreferences,WebPreferences,FOOT(2,2)
EXPECT
}

#####################

sub verify_multiWeb_with_header_with_footer_no_separator_with_results {
    my $this = shift;
    $this->_multiWebSeptic( 1, 1, undef, 1, <<EXPECT);
HEAD(System)
DefaultPreferences
WebPreferences
FOOT(2,2)HEAD(Main)
SitePreferences
WebPreferences
FOOT(2,2)
EXPECT
}

sub verify_multiWeb_with_header_with_footer_no_separator_no_results {
    my $this = shift;
    $this->_multiWebSeptic( 1, 1, undef, 0, <<EXPECT);
EXPECT
}

sub verify_multiWeb_with_header_with_footer_empty_separator_with_results {
    my $this = shift;
    $this->_multiWebSeptic( 1, 1, "", 1, <<EXPECT);
HEAD(System)
DefaultPreferencesWebPreferencesFOOT(2,2)HEAD(Main)
SitePreferencesWebPreferencesFOOT(2,2)
EXPECT
}

sub verify_multiWeb_with_header_with_footer_empty_separator_no_results {
    my $this = shift;
    $this->_multiWebSeptic( 1, 1, "", 0, <<EXPECT);
EXPECT
}

sub verify_multiWeb_with_header_with_footer_with_separator_with_results {
    my $this = shift;
    $this->_multiWebSeptic( 1, 1, ",", 1, <<EXPECT);
HEAD(System)
DefaultPreferences,WebPreferences,FOOT(2,2)HEAD(Main)
SitePreferences,WebPreferences,FOOT(2,2)
EXPECT
}

sub verify_multiWeb_with_header_with_footer_with_separator_no_results {
    my $this = shift;
    $this->_multiWebSeptic( 1, 1, ",", 0, <<EXPECT);
EXPECT
}

#####################

sub verify_multiWeb_with_header_no_footer_no_separator_with_results {
    my $this = shift;
    $this->_multiWebSeptic( 1, 0, undef, 1, <<EXPECT);
HEAD(System)
DefaultPreferences
WebPreferences
HEAD(Main)
SitePreferences
WebPreferences
EXPECT
}

sub verify_multiWeb_with_header_no_footer_no_separator_no_results {
    my $this = shift;
    $this->_multiWebSeptic( 1, 0, undef, 0, <<EXPECT);
EXPECT
}

sub verify_multiWeb_with_header_no_footer_empty_separator_with_results {
    my $this = shift;
    $this->_multiWebSeptic( 1, 0, "", 1, <<EXPECT);
HEAD(System)
DefaultPreferencesWebPreferencesHEAD(Main)
SitePreferencesWebPreferences
EXPECT
}

sub verify_multiWeb_with_header_no_footer_empty_separator_no_results {
    my $this = shift;
    $this->_multiWebSeptic( 1, 0, "", 0, <<EXPECT);
EXPECT
}

sub verify_multiWeb_with_header_no_footer_with_separator_with_results {
    my $this = shift;
    $this->_multiWebSeptic( 1, 0, ",", 1, <<EXPECT);
HEAD(System)
DefaultPreferences,WebPreferences,HEAD(Main)
SitePreferences,WebPreferences
EXPECT
}

sub verify_multiWeb_with_header_no_footer_with_separator_no_results {
    my $this = shift;
    $this->_multiWebSeptic( 1, 0, ",", 0, <<EXPECT);
EXPECT
}

#####################

=pod

Test if search results adhere to the SEARCHSTOPWORDS pref.

=cut

sub verify_stop_words_search_word {
    my $this = shift;

    use Foswiki::Func;
    my $origSetting = Foswiki::Func::getPreferencesValue('SEARCHSTOPWORDS');
    Foswiki::Func::setPreferencesValue( 'SEARCHSTOPWORDS',
        'xxx luv ,kiss, bye' );

    my $TEST_TEXT  = "xxx Shamira";
    my $TEST_TOPIC = 'StopWordTestTopic';
    $this->{twiki}->{store}->saveTopic( $this->{twiki}->{user},
        $this->{test_web}, $TEST_TOPIC, $TEST_TEXT );

    my $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"Shamira" type="word" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_matches( qr/$TEST_TOPIC/, $result );

    $result = $this->{twiki}->handleCommonTags(
        '%SEARCH{"xxx" type="word" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( '', $result );

    $result = $this->{twiki}->handleCommonTags(
'%SEARCH{"+xxx" type="word" scope="text" nonoise="on" format="$topic"}%',
        $this->{test_web}, $this->{test_topic}
    );
    $this->assert_str_equals( '', $result );

    Foswiki::Func::setPreferencesValue( 'SEARCHSTOPWORDS', $origSetting );
}

1;
