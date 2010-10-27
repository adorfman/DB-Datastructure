#!/usr/bin/perl 
use strict;
use warnings;
use lib qw( ../lib  );
use Data::Dumper;
use DB::DataStructure;


my $obj = DB::DataStructure->new(
    'dbtype' => 'mysql',
    'dbhost' => 'localhost',
    'db'     => 'addev',
    'dbuser' => 'addev',
    'dbpass' => 'ya23Jkasdv',
    'load_schema' => 1,
    #'table'  => 'configs'
);

my $hashref = {

    name  => 'bleh',
    array => [ 1,2,3],
    hash  => { 
        thas => 'that2',
        that => 'this'
    }

};

my $varname = $obj->freeze( myarray7 => $hashref, refreeze => 1  );

print Dumper( $obj->thaw($varname, refreeze => 1) );
