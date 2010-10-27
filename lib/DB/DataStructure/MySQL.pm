package DB::DataStructure::MySQL;

use strict;
use warnings;

#use vars qw($SET_SQL $CHECK_TABLE_SQL);

## MySQL freaks out if table name is quoted so we can't use 
## parameter subs
our $SELECT_SQL = 'select serialized from ##TABLE## where data_struct = ?';
our $INSERT_SQL = 'INSERT INTO ##TABLE## (data_struct, serialized) VALUES(?,?)';
our $CHECK_SQL = 'select id from ##TABLE## where data_struct = ?';
our $DELETE_SQL = 'delete from ##TABLE## where data_struct = ?';
our $UPDATE_SQL = 'update ##TABLE## set serialized = ? where data_struct = ?';
our $CHECK_TABLE_SQL = 'show tables like ?';

our $CREATE_TABLE_SQL =<<SCHEMA 
CREATE TABLE ##TABLE## (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
     `data_struct` VARCHAR(48) NOT NULL,
     `serialized`  TEXT,
     `updated_on`  TIMESTAMP(8),
     UNIQUE `idx_data_struct` (`data_struct`)
) TYPE=innodb
SCHEMA
;
                          
1;
