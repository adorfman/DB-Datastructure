package DB::DataStructure;

use strict;
use warnings;
use DBI;
use DBD::mysql;
use Data::Dumper;
use JSON;
use DB::DataStructure::MySQL ;
use Time::Local;

our $VERSION = '0.01';

my @DBI_PARAMS = qw( dbtype dbhost db dbuser dbpass port);
my $DEFAULT_TABLE = 'config_options';
my $DEFAULT_PORT = '3306';

# db types must be mapped to their sub class
# here. Sub classes need to contain the following 
# global vars:
#
# SELECT_SQL      - query to select key 
# INSERT_SQL      - query to insert key 
# CHECK_SQL       - query to check if key exists
# UPDATE_SQL      - query to update key
# CHECK_TABLE_SQL - query to check if table exists
# CREATE_TABLESQL - query to create table
#
my %TYPE_MAP = (
    mysql => 'DB::DataStructure::MySQL',
);

sub new {

    my ($class, @options ) = @_ ;

    my $self = {};
    bless $self, $class ;

    $self->{'opts'}  = { $self->_param_check(\ @options ) } ;

    $self->{'dbh'} = 
        ( $self->_dbi_check($self->{'opts'}->{'dbh'} ) )
        ? $self->{'opts'}->{'dbh'}
        : $self->_get_dbh(); 

    $self->{'type_class'} = $TYPE_MAP{$self->{'opts'}->{'dbtype'}};
    $self->{'opts'}->{'table'} ||= $DEFAULT_TABLE; 

    if (! $self->_table_check ) {
        if  ($self->{'opts'}->{'load_schema'} ) { 
            $self->_load_schema 
        } 
        else {
            warn "table does not exist and will not be loaded";
            return;
        }  
    }

    return $self

}


sub freeze {
    
    my ($self, $key, $dstruct, @options) = @_ ;

    my %options = $self->_param_check(\@options);
    
    
    my $deflated = $self->_deflate($dstruct);

    my $table = $self->{'opts'}->{'table'};

    my $query ;

    if ( $self->_check_for_key($key) ) {
        if ($options{'refreeze'} ) {
            $query = $self->_get_query('UPDATE_SQL');
            $self->_run_query($query, $deflated, $key);
        }
        else {
            print "dstruct already exists\n"; 
            return;
        }
    }
    else {
        $query = $self->_get_query('INSERT_SQL');
        $self->_run_query($query, $key, $deflated) ;
    }

    return $key;

}

sub thaw {

    my ($self, $key, @options) = @_ ;

    my %options = $self->_param_check(\@options);
    
    my $query = $self->_get_query('SELECT_SQL');

    my $deflated = $self->_run_select_query($query, $key);

    warn "non-existant dstruct key : $key \n" and return
        unless ($deflated);

    $self->_delete($key)
        unless ( $options{'refreeze'} );

    return  $self->_inflate( $deflated ) ;

}

sub _run_select_query {

    my $self = shift;
    
    my $sth = $self->_run_query(@_);
    
    return $sth->fetchrow_array()
}

sub _run_query {

    my ($self, $query, @vars) = @_;
    
    ($self->_dbi_check($self->{'dbh'}))
        or die 'No database handle';
     
    my $dbh = $self->{'dbh'} ;
    my $sth = $dbh->prepare($query);
    $sth->execute(@vars) ;

    return $sth;
}

sub _get_query {

    my ( $self, $query_type ) = @_;
    my $table = $self->{'opts'}->{'table'};
    my $class_var = sprintf( '$%s::%s', $self->{'type_class'} , $query_type  );
    my $query = eval $class_var;
    die "this shouldn't happen $@" if $@;

    # mysql doesn't like the table name quoted so have do 
    # do this instead of using param subs
    $query =~ s/##TABLE##/$table/;
    return $query;

}

## TODO: for now inflate/deflate just uses JSON
## this could be expanded later to include options
## that trigger other serialization methods

sub _inflate {

    my ($self, $deflated ) = @_;
    return from_json($deflated);
}

sub _deflate {

    my ( $self, $dstruct ) = @_;
    return to_json( $dstruct, { pretty => 0,utf8 => 1 });

}

sub _check_for_key {

    my ($self, $key) = @_;
    my $query = $self->_get_query('CHECK_SQL');
    return $self->_run_select_query($query, $key);
}

sub _delete {

    my ($self, $key) = @_;
    my $query = $self->_get_query('DELETE_SQL');
    return $self->_run_query($query, $key);

}

sub _get_dbh {

    my $self = shift;

    $self->{'opts'}->{'port'}  ||= $DEFAULT_PORT;

    die "We need a dbh or enough params to create one" 
        unless ( 
            @{[ grep { $self->{'opts'}->{$_} } @DBI_PARAMS ] } == @DBI_PARAMS 
        ) ;

    my ( $type, $host, $database, $user, $pass, $port ) =
        map { $self->{'opts'}->{$_} } @DBI_PARAMS;

    my $dns = "dbi:$type:$database:$host:$port";

    return DBI->connect($dns, $user, $pass)
        or die "Database Error $DBI::errstr\n";

}

sub _load_schema {
    
    my ($self, $options ) = @_ ;
    my $query = $self->_get_query('CREATE_TABLE_SQL');
    $self->_run_query( $query );
}

sub _table_check {

    my $self = shift;
    my $query = $self->_get_query('CHECK_TABLE_SQL');
    return $self->_run_select_query($query, $self->{'opts'}->{'table'});

}

sub _param_check {

    my ( $self, $optsref ) = @_;
    ( scalar( @{$optsref} ) % 2 == 0 ) 
        or die 'Uneven config parameters';
    return @{$optsref}; 
}

sub _dbi_check {
   
    my ($self, $dbh ) = @_;

    return 1
        if ( ref( $dbh ) && $dbh =~ /^DBI/ );

    return 0

}

sub _mysql_date_to_epoch {
    my ($self, $date_time ) = @_;
    my ( $date, $time) = split(' ',$date_time);
    my ($year, $mon, $mday) = split('-',$date);
    my ($hour, $min, $sec) = split(':',$time);
    my $epoch = timelocal($sec,$min,$hour,$mday,$mon,$year);
    return $epoch; 
}        


1;
__END__

=head1 NAME

DB::DataStructure 

=head1 SYNOPSIS

use DB::DataStructure;


my $obj = DB::DataStructure->new(
    'dbtype' => 'mysql',
    'dbhost' => 'localhost',
    'db'     => 'database',
    'dbuser' => 'user',
    'dbpass' => 'password',
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

#With refreeze set an existing datastructure with the same key
will be overwritten.  Without it set it will error on trying
to overwrite  
On success freeze returns of the key name you set

my $varname = $obj->freeze( myarray7 => $hashref, refreeze => 1  );

#With thaw when refreeze set the datastructure is not removed from the 
db when thawed 

print Dumper( $obj->thaw($varname, refreeze => 1 ) ); 

=head1 DESCRIPTION

perl module for storing serialized data structures in a database

=head2 EXPORT

None by default.


=head1 AUTHOR

A. Dorfman, E<lt>adorfman@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by A. Dorfman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
