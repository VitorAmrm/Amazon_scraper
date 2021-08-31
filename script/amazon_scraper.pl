use strict;
use Web::Scraper;
use Encode;
use URI;
use DBI;

my $driver = 'SQLite';
my $path_db = './database/amazon_scraper.sqlite';

my $dbh = DBI -> connect("DBI:$driver:dbname=$path_db","","", { RaiseError => 1 } )  or die $DBI::errstr;

print "DataBase Opened";

=a
my $table_create = qq( CREATE TABLE SCRAPER
                        (
                        PRODUCT_NAME TEXT,
                        PRICE TEXT
                        );
                    );

my $migration = $dbh -> do($table_create);


if($migration < 0){
    print $DBI::errstr;
}else{
    print "Table Created";
}
=cut
my $authors = scraper {

    process 'div[class="sg-col-inner"] div[class="a-section a-spacing-none"]', "prices[]" => scraper {

      process 'span[class="a-size-medium a-color-base a-text-normal"]', product_name => 'TEXT';
      process 'span[class="a-price-whole"]', price => 'TEXT';

    };
};
 
my $res = $authors->scrape( URI->new("https://www.amazon.com/s?k=mouse") );

for my $author (@{$res->{prices}}) {
    my $insert = qq(
        INSERT INTO SCRAPER (PRODUCT_NAME, PRICE)
        VALUES (
            "$author->{product_name}",
            "$author->{price}")        
    );
    print Encode::encode("utf8", "$author->{product_name}\t$author->{price}\n");

    my $exec = $dbh -> do($insert) or die $DBI::errstr;
}



$dbh->disconnect();