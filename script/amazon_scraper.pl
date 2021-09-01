use strict;
use Web::Scraper;
use Encode;
use URI;
use DBI;

my $driver = 'SQLite';
my $path_db = './database/amazon_scraper.sqlite';

my $dbh = DBI -> connect("DBI:$driver:dbname=$path_db","","", { RaiseError => 1 } )  or die $DBI::errstr;

print "DataBase Opened";

# script for create table
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
my $authors = scraper {

    process 'div[class="sg-row"]', "prices[]" => scraper {

      process 'h2', product_name => 'TEXT';
      process 'span[class="a-price"] span[class="a-offscreen"]', price => 'TEXT';
    };
};
 
my $res = $authors->scrape( URI->new("https://www.amazon.com/s?k=mouse&__mk_pt_BR=ÅMÅŽÕÑ&ref=nb_sb_noss_2") );

for my $author (@{$res->{prices}}) {
    my $insert = qq(
        INSERT INTO SCRAPER (PRODUCT_NAME, PRICE)
        VALUES (
            "$author->{product_name}",
            "$author->{price}")        
    );
    print Encode::encode("utf8", "$author->{price}\n");
    print Encode::encode("utf8", "$author->{product_name}\n");

    my $exec = $dbh -> do($insert) or die $DBI::errstr;
}

#script para deletar linhas nulas
my $delete_null = qq( DELETE FROM SCRAPER WHERE PRODUCT_NAME="" OR PRODUCT_NAME IS NULL OR PRICE="" OR PRICE IS NULL);

my $exec_delete = $dbh -> do($delete_null) or die $DBI::errstr;


$dbh->disconnect();