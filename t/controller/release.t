use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/release/DOESNTEXIST" ),
        'GET /release/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );

    ok( $res = $cb->( GET "/release/AUTHORDOESNTEXIST/DOESNTEXIST" ),
        'GET /release/AUTHORDOESNTEXIST/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );

    ok( $res = $cb->( GET "/release/PERLER/DOESNTEXIST" ),
        'GET /release/PERLER/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );

    ok( $res = $cb->( GET "/release/Moose" ), 'GET /release/Moose' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    $tx->like( '/html/head/title', qr/Moose/, 'title includes Moose' );
    ok( $tx->find_value('//a[@href="/release/Moose"]'),
        'contains permalink to resource' );

    # Figure out version for Changes test
    my ($author, $module) = split m|/|, $tx->find_value('//strong/big');
    $module =~ s/[^\d\w_.-]//g;
    my ($version) = (reverse split /-/, $module);

    # Confirm that the headings in the content div are in the expected order.
    my @headings = ( 'Documentation', 'Modules', 'Provides', 'Examples', 'Other files' );
    my @anchors = qw(docs modules provides examples other whatsnew);
    push @headings, 'Changes for version ' . $version ;
    my $heading  = 0;

    $tx->ok( '//div[@class="content"]/strong', sub {
        $_->is( '.', $headings[$heading], "heading $headings[$heading] in expected location");
        $heading++;
    } , 'headings in correct order');

    my $anchor = 0;
    $tx->ok( '//div[@class="content"]/a[following-sibling::strong[1]]', sub {
            $_->is('./@name', $anchors[$anchor], "Anchor $anchors[$anchor] in expected location");
            $anchor++;
        }, "anchors are correct..");


    ok( my $this = $tx->find_value('//a[text()="This version"]/@href'),
        'contains link to "this" version' );
    my $latest = $tx->find_value('//div[@class="content"]');
    ok( $res = $cb->( GET $this ), "GET $this" );
    my $tx_latest = tx($res);
    is(
        $latest,
        $tx_latest->find_value('//div[@class="content"]'),
        'content of both urls is exactly the same'
    );

    # get module with lc author
    $this =~ s{(/release/.*?/)}{lc($1)}e; # lc author name
    ok( $res = $cb->( GET $this ), "GET $this" );
    is( $res->code, 301, 'code 301' );


    ok( $res = $cb->( GET '/release/BRICAS/CPAN-Changes-0.21' ), "GET /release/BRICAS/CPAN-Changes-0.21" );
    is( $res->code, 200, "code 200" );
    my $tx_cc = tx($res);
    is(
        $tx_cc->find_value('//a[@href="https://rt.cpan.org/Ticket/Display.html?id=84994"]'),
        'RT #84994',
        "Link to rt is there"
    );

    ok( $res = $cb->( GET '/release/ANDREMAR/WWW-Curl-Simple-0.100187' ) );
    my $tx_cc = tx( $res );
    is (
        $tx_cc->find_value('//a[@href="https://github.com/omega/www-curl-simple/issues/8"]'),
        '#8',
        "link to github issues is there"
    );

};

done_testing;
