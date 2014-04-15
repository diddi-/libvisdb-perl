package Net::VIS;

=head1 phpipam

phpipam - Module to work with the phpIPAM (phpipam.net) database

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use strict;
    use warnings;
    use Data::Dumper;
    use phpipam;

    my $ipam = phpIPAM->new(
        dbhost => 'localhost',
        dbuser => 'phpipam',
        dbpass => 'phpipam',
        dbname => 'phpipam',
        dbport => 3306,
    );

    if(not $ipam) {
        print "ERROR could not create object\n";
        return -1;
    }

    my $ret = $ipam->getAllSubnets();

    print Dumper($ret);

    my $ipv4 = $ipam->getIP("173.194.70.100");
    print Dumper($ipv4);
    my $ipv6 = $ipam->getIP("2a00:1450:4001:c02::66");
    print Dumper($ipv6);
    exit(0);

=head1 INSTALLATION

These are the steps to install the module

    perl Makefile.PL
    make
    make install

=head1 DEPENDENCIES

phpipam have some dependencies to other modules
=head2 Required

    Carp
    DBI
    DBD::mysql
    Net::IP
    Exporter

=head1 DESCRIPTION

phpipam is a helper module to retrieve information from the phpipam database (phpipam.net)

=head2 EXPORT

None by default.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp;
use DBI;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use phpipam ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

=head2 new()

Calling new() with valid options will automatically try and connect to the VIS database. If successful, a blessed object is returned to the user.

    dbhost => [hostname|ip]     - DNS hostname or IP address (IPv4 or IPv6)
                                  of the remote MySQL database.
                                  ( Default: localhost )

    dbport => port              - Port number to connect to (1-65535).
                                  ( Default: 3306 )

    dbuser => string            - Username to use when authenticating to the
                                  MySQL database.
                                  ( Default: visdb )

    dbpass => string            - Password to use when authenticating to the
                                  MySQL database.
                                  ( Default: visdb_password )

    dbname => string            - Name of the MySQL database where VIS
                                  stores all it's data.
                                  ( Default: visdb )
=cut
sub new {

    my $class = shift;
    my $self = {};

    my $supported_phpIPAM = "0.8";

    bless($self, $class);

    my (%args) = @_;
    $self->{ARGS} = \%args;

    $self->{CFG}->{DBHOST}          = $self->_arg("dbhost", "localhost");
    $self->{CFG}->{DBUSER}          = $self->_arg("dbuser", "visdb");
    $self->{CFG}->{DBPASS}          = $self->_arg("dbpass", "visdb_password");
    $self->{CFG}->{DBPORT}          = $self->_arg("dbport", 3306);
    $self->{CFG}->{DBNAME}          = $self->_arg("dbname", "visdb");

    return $self;
}

sub DESTROY {
    my $self = shift;

    $self->_sqldisconnect();
}
sub _arg {
    my $self = shift;
    my $arg = shift;
    my $default = shift;
    my $valid = shift;

    my $base = $self->{ARGS};

    my $val = (exists($base->{$arg}) ? $base->{$arg} : $default);

    if(defined ($valid)) {
        my $pass = 0;
        foreach my $check (@{$valid}) {
            $pass = 1 if($check eq $val);
        }

        if($pass == 0) {
            croak("Invalid value for setting '$arg' = '$val'.  Valid are: ['".join("','",@{$valid})."']");
        }

    }

    return $val;
}

sub _sqlconnect {
    my $self = shift;

    if($self->{DB}->{SOCK} and $self->{DB}->{SOCK}->ping) {
        return 0;
    }

    my $dsn = "DBI:mysql:".$self->{CFG}->{DBNAME}.":".$self->{CFG}->{DBHOST}.":".$self->{CFG}->{DBPORT};
    $self->{DB}->{SOCK} = DBI->connect($dsn, $self->{CFG}->{DBUSER}, $self->{CFG}->{DBPASS});

    if(not $self->{DB}->{SOCK}) {
        croak("Unable to connect to ".$self->{CFG}->{DBUSER}."@".$self->{CFG}->{DBHOST}.":".$self->{CFG}->{DBPORT}.": ".$DBI::errstr."\n");
    }
    return 0;
}
sub _sqldisconnect {
    my $self = shift;

    #$self->{DB}->{SOCK}->disconnect();

    return 0;
}

sub _select {
    my $self = shift;
    my $query = $_[0];
    if(not $query ) {
        carp("Missing argument to _select()\n");
        return -1;
    }

    $self->_sqlconnect();

    my $results = $self->{DB}->{SOCK}->selectall_arrayref($query, { Slice => {} });
    if(not $results) {
        carp("Unable to execute \"$query\": ".$DBI::errstr."\n");
        return -1;
    }

    return $results;
}

sub _insert {
    my $self = shift;
    my $query = $_[0];
    if(not $query) {
        carp("Missing argument to _insert()\n");
        return -1;
    }

    $self->_sqlconnect();

    my $ra = $self->{DB}->{SOCK}->do($query);
    if(not $ra) {
        carp("Unable to execute \"$query\": ".$DBI::errstr."\n");
        return -1;
    }

    return $ra;
}
sub _update {
    my $self = shift;
    my $query = $_[0];
    if(not $query) {
        carp("Missing argument to _update()\n");
        return -1;
    }

    $self->_sqlconnect();

    my $ra = $self->{DB}->{SOCK}->do($query);
    if(not $ra) {
        carp("Unable to execute \"$query\": ".$DBI::errstr."\n");
        return -1;
    }

    return $ra;
}

sub _delete {
    my $self = shift;
    my $query = $_[0];
    if(not $query) {
        carp("Missing argument to _delete()\n");
        return -1;
    }

    $self->_sqlconnect();

    my $ra = $self->{DB}->{SOCK}->do($query);
    if(not $ra) {
        carp("Unable to execute \"$query\": ".$DBI::errstr."\n");
        return -1;
    }

    return $ra;
}

sub _escape {
    my $self = shift;
    my $q = $_[0];

    $q =~ s/'/\'/g;
    $q =~ s/--/\-\-/g;
    $q =~ s/\\/\\\\/g;

    return $q;
}

# subroutines managing Domain information

# Get domain information
sub get_domain {
  my $self = shift;
  my $filter = shift;
  my @where;

  my $query = "SELECT id,domain_serial,domain_name,domain_description FROM Domain";

  push(@where, "domain_serial = ".$filter->{'domain_serial'}) if $filter->{'domain_serial'};
  push(@where, "domain_name = '".$filter->{'domain_name'}."'") if $filter->{'domain_name'};
  push(@where, "id = ".$filter->{'domain_id'}) if $filter->{'domain_id'};

  for ( my $i=0; $i < @where; $i++ ) {
    $query .= $i ? " AND " : " WHERE ";
    $query .= $where[$i];
  }

  $query .= " ORDER BY domain_serial";
  my $domains = $self->_select($query);

  return $domains;
}

# Create a new domain
sub create_domain {
  my $self = shift;
  my $opts = shift;

  if(not defined $opts->{'domain_serial'}) {
    carp("Missing domain_serial attribute\n");
    return -1;
  }

  if(not defined $opts->{'domain_name'}) {
    carp("Missing domain_name attribute\n");
    return -1;
  }

  if(not defined $opts->{'domain_description'}) {
    carp("Missing domain_description attribute");
    return -1;
  }

  if($opts->{'domain_serial'} !~ m/^[0-9]+$/) {
    carp("domain_serial must be a number\n");
    return -1;
  }

  my $d = $self->get_domain({domain_serial => $opts->{'domain_serial'}, domain_name => $opts->{'domain_name'}});
  if(@{$d} > 0) {
    carp("Domain '".$opts->{'domain_name'}."' with ID ".$opts->{'domain_serial'}." already defined!\n");
    return -3;
  }

  my $res = $self->_insert("INSERT INTO Domain (domain_serial, domain_name, domain_description) VALUES(".$self->_escape($opts->{'domain_serial'}).", '".$self->_escape($opts->{'domain_name'})."', '".$self->_escape($opts->{'domain_description'})."')");

  if(not $res) {
    carp("Unable to create new Domain\n");
    return -2;
  }

  return 0;
}

# Delete a domain
sub delete_domain {
  my $self = shift;
  my $domain_serial = shift;

  if(not defined $domain_serial or $domain_serial !~ m/^[0-9]+$/) {
    carp("domain_serial must be defined as an integer\n");
    return -1;
  }

  my $res = $self->_delete("DELETE FROM Domain WHERE domain_serial=".$self->_escape($domain_serial));
  if(not $res) {
    carp("Unable to delete domain with id $domain_serial\n");
    return -2;
  }

  return 0;
}

# Modify the domain_serial attribute
sub mod_domain_serial {
  my $self = shift;
  my $mod_domain_serial = shift;
  my $new_id = shift;

  if(not defined $mod_domain_serial or $mod_domain_serial !~ m/^[0-9]+$/) {
    carp("domain_serial must be defined as an integer\n");
    return -1;
  }

  if(not defined $new_id or $new_id !~ m/^[0-9]+$/) {
    carp("Missing new domain id or not INT\n");
    return -1;
  }

  my $res = $self->_update("UPDATE Domain SET domain_serial=".$self->_escape($new_id)." WHERE domain_serial=".$self->_escape($mod_domain_serial));
  if(not $res) {
    carp("Unable to change domain id $mod_domain_serial -> $new_id\n");
    return -2;
  }

  return 0;
}

# Modify the domain name attribute
sub mod_domain_name {
  my $self = shift;
  my $domain_serial = shift;
  my $new_name = shift;

  if(not defined $domain_serial or $domain_serial !~ m/^[0-9]+$/) {
    carp("domain_serial must be defined as an integer\n");
    return -1;
  }

  if(not defined $new_name) {
    carp("Missing name attribute");
    return -1;
  }

  my $res = $self->_update("UPDATE Domain SET domain_name='".$self->_escape($new_name)."' WHERE domain_serial=".$self->_escape($domain_serial));
  if(not $res) {
    carp("Unable to change domain_name attribute");
    return -2;
  }

  return 0;
}

# Modify the domain description attribute
sub mod_domain_description {
  my $self = shift;
  my $domain_serial = shift;
  my $new_description = shift;

  if(not defined $domain_serial or $domain_serial !~ m/^[0-9]+$/) {
    carp("domain_serial must be defined as an integer\n");
    return -1;
  }

  if(not defined $new_description) {
    carp("Missing domain description attribute");
    return -1;
  }

  my $res = $self->_update("UPDATE Domain SET domain_description='".$self->_escape($new_description)."' WHERE domain_serial=".$self->_escape($domain_serial));
  if(not $res) {
    carp("Unable to change domain_description attribute");
    return -2;
  }

  return 0;
}

# subroutines managing VLAN Allocations

# Check if VLAN tag is already in use
sub is_vlan_alloc {
  my $self = shift;
  my $domain_id = shift;
  my $vlan_tag = shift;

  my $ret = $self->_select("SELECT * FROM VLAN_Allocation WHERE domain_id = ".$self->_escape($domain_id)." AND vlan_tag = ".$self->_escape($vlan_tag));
  if(@{$ret} > 0) {
    return 1;
  }else{
    return 0;
  }
}

# Calculate and return next available vlan
sub get_next_tag {
  my $self = shift;
  my $opts = shift;
  my $new_tag = 0;

  if(not defined $opts->{'domain_id'} or $opts->{'domain_id'} !~ m/^[0-9]+$/) {
    carp("Missing domain_id or not INT");
    return -1;
  }
  if(not defined $opts->{'type_id'} or $opts->{'type_id'} !~ m/^[0-9]+$/) {
    carp("Missing type_id or not INT");
    return -1;
  }

  my $vlans = $self->_select("SELECT vlan_tag FROM VLAN_Allocation WHERE domain_id = ".$self->_escape($opts->{'domain_id'})." ORDER BY vlan_tag");
  my $type = $self->_select("SELECT vlan_low,vlan_high FROM VLAN_Types WHERE id = ".$self->_escape($opts->{'type_id'}));

  if(@{$type} <= 0){
    carp ("No such VLAN Type ID ".$opts->{'type_id'}."\n");
    return -2;
  }

  for(my $i = @{$type}[0]->{'vlan_low'}; $i <= @{$type}[0]->{'vlan_high'}; $i++){
    my $matched = 0;
    foreach my $vlan (@{$vlans}) {
      if($vlan->{'vlan_tag'} == $i) {
        $matched = 1;
        last;
      }
    }
    if($matched == 0) {
      $new_tag = $i;
      last;
    }
  }

  if($new_tag < @{$type}[0]->{'vlan_low'} or $new_tag > @{$type}[0]->{'vlan_high'}) {
    carp("Unable to get next available VLAN tag - scope full?\n");
    return -3;
  }

  return $new_tag;

}
# Get VLAN allocation information
sub get_vlan_alloc {
  my $self = shift;
  my $filter = shift;
  my @where;

  my $query = "SELECT d.domain_serial,d.domain_name,va.vlan_tag,va.vlan_name,va.vlan_description FROM VLAN_Allocation AS va INNER JOIN Domain AS d ON va.domain_id = d.id";

  push(@where, "d.domain_serial = ".$filter->{'domain_serial'}) if $filter->{'domain_serial'};
  push(@where, "d.domain_name = '".$filter->{'domain_name'}."'") if $filter->{'domain_name'};
  push(@where, "va.vlan_name = '".$filter->{'vlan_name'}."'") if $filter->{'vlan_name'};
  push(@where, "va.vlan_tag = ".$filter->{'vlan_tag'}) if $filter->{'vlan_tag'};

  for ( my $i=0; $i < @where; $i++ ) {
    $query .= $i ? " AND " : " WHERE ";
    $query .= $where[$i];
  }

  $query .= " ORDER BY d.domain_serial,va.vlan_tag";
  my $vlans = $self->_select($query);

  return $vlans;
}

# Create new VLAN allocation
sub vlan_alloc {
  my $self = shift;
  my $opts = shift;

  if(not defined $opts->{'domain_id'} or $opts->{'domain_id'} !~ m/^[0-9]+$/) {
    carp("Missing domain_id or not INT");
    return -1;
  }

  if(not defined $opts->{'vlan_tag'} or $opts->{'vlan_tag'} !~ m/^[0-9]+$/ or $opts->{'vlan_tag'} < 0 or $opts->{'vlan_tag'} > 4095) {
    carp("vlan_tag must be an integer between 1 and 4095");
    return -1;
  }

  if(not defined $opts->{'vlan_name'}) {
    carp("Missing argument vlan_name");
    return -1;
  }

  if(not defined $opts->{'vlan_description'}) {
    carp("Missing argument vlan_description");
    return -1;
  }

  if(not $self->vlan_in_range($opts->{'type_id'}, $opts->{'vlan_tag'})) {
    carp("VLAN tag ".$opts->{'vlan_tag'}." is not within VLAN type range\n");
    return -2;
  }

  if($self->is_vlan_alloc($opts->{'domain_id'},$opts->{'vlan_tag'})) {
    carp("Unable to make VLAN allocation, VLAN already exists!\n");
    return -2;
  }

  my $res = $self->_insert("INSERT INTO VLAN_Allocation (domain_id, vlan_tag, vlan_name, vlan_description) VALUES(".$self->_escape($opts->{'domain_id'}).", ".$self->_escape($opts->{'vlan_tag'}).", '".$self->_escape($opts->{'vlan_name'})."', '".$self->_escape($opts->{'vlan_description'})."')");
  if(not $res) {
    carp("Unable to insert new VLAN allocation\n");
    return -2;
  }

  return 0;
}

# Delete VLAN allocation
sub vlan_alloc_free {
  my $self = shift;
  my $opts = shift;

  if(not defined $opts->{'domain_id'} or $opts->{'domain_id'} !~ m/^[0-9]+$/) {
    carp("Missing domain_id or not INT");
    return -1;
  }

  if(not defined $opts->{'vlan_tag'} or $opts->{'vlan_tag'} !~ m/^[0-9]+$/ or $opts->{'vlan_tag'} < 0 or $opts->{'vlan_tag'} > 4095) {
    carp("vlan_tag must be an integer between 1 and 4095");
    return -1;
  }

  my $res = $self->_delete("DELETE FROM VLAN_Allocation WHERE domain_id=".$self->_escape($opts->{'domain_id'})." AND vlan_tag=".$self->_escape($opts->{'vlan_tag'}));
  if(not $res) {
    carp("Unable to delete VLAN alloaction\n");
    return -2;
  }

  return 0;
}

# Modify vlan allocation domain_id attribute
sub mod_vlan_alloc_domain_id {
  my $self = shift;

  return 0;
}

# Modify vlan allocation vlan_tag attribute
sub mod_vlan_alloc_vlan_tag {
  my $self = shift;

  return 0;
}

# Modify vlan allocation vlan_name attribute
sub mod_vlan_alloc_vlan_name {
  my $self = shift;

  return 0;
}

# Modify vlan allocation vlan_description attribute
sub mod_vlan_alloc_vlan_description {
  my $self = shift;

  return 0;
}

# subroutines managing VLAN Types

# Check if tag is within type range
sub vlan_in_range {
  my $self = shift;
  my $type_id = shift;
  my $vlan_tag = shift;

  if(not defined $type_id) {
    carp("Missing type_id\n");
    return -1;
  }
  if(not defined $vlan_tag) {
    carp("Missing vlan_tag\n");
    return -1;
  }

  if($type_id !~ m/^[0-9]+$/) {
    carp("type_id is not INT\n");
    return -1;
  }
  if($vlan_tag !~ m/^[0-9]+$/) {
    carp("vlan_tag is not INT\n");
    return -1;
  }

  my $type = $self->_select("SELECT vlan_low,vlan_high FROM VLAN_Types WHERE id = ".$self->_escape($type_id));
  if(@{$type} <= 0) {
    carp("Could not find VLAN type with ID $type_id\n");
    return -2;
  }

  if($vlan_tag >= @{$type}[0]->{'vlan_low'} and $vlan_tag <= @{$type}[0]->{'vlan_high'}) {
    return 1;
  }else{
    return 0;
  }
}

# Get VLAN type information
sub get_vlan_type {
  my $self = shift;
  my $filter = shift;
  my @where;

  my $query = "SELECT d.domain_serial,d.domain_name,vt.id,vt.name,vt.description,vt.vlan_low,vt.vlan_high FROM VLAN_Types AS vt INNER JOIN Domain AS d ON vt.domain_id = d.id";

  push(@where, "d.id = ".$self->_escape($filter->{'id'})) if $filter->{'id'};
  push(@where, "d.domain_serial = ".$self->_escape($filter->{'domain_serial'})) if $filter->{'domain_serial'};
  push(@where, "(d.domain_name = 'Global' OR d.domain_name = '".$self->_escape($filter->{'domain_name'})."')") if $filter->{'domain_name'};
  push(@where, "vt.name = '".$self->_escape($filter->{'name'})."'") if $filter->{'name'};

  for ( my $i=0; $i < @where; $i++ ) {
    $query .= $i ? " AND " : " WHERE ";
    $query .= $where[$i];
  }

  $query .= " ORDER BY d.domain_serial,vt.vlan_low";
  my $vlans = $self->_select($query);
  return $vlans;
}

# Create VLAN type
sub create_vlan_type {
  my $self = shift;
  my $opts = shift;

  if(not defined $opts->{'domain_id'} or $opts->{'domain_id'} !~ m/^[0-9]+$/) {
    carp("Missing domain_id or not INT");
    return -1;
  }

  if(not defined $opts->{'name'}) {
    carp("Missing name attribute");
    return -1;
  }

  if(not defined $opts->{'description'}) {
    carp("Missing description attribute");
    return -1;
  }

  if(not defined $opts->{'vlan_low'} or $opts->{'vlan_low'} !~ m/^[0-9]+$/ or $opts->{'vlan_low'} < 0 or $opts->{'vlan_low'} > 4095) {
    carp("vlan_low must be an integer between 1 and 4095");
    return -1;
  }

  if(not defined $opts->{'vlan_high'} or $opts->{'vlan_high'} !~ m/^[0-9]+$/ or $opts->{'vlan_high'} < 0 or $opts->{'vlan_high'} > 4095) {
    carp("vlan_high must be an integer between 1 and 4095");
    return -1;
  }

  my $all_types = $self->get_vlan_type({id => $opts->{'domain_id'}});
  foreach my $type (@{$all_types}) {
    if($opts->{'vlan_high'} >= $type->{'vlan_low'} and $opts->{'vlan_low'} <= $type->{'vlan_high'}) {
      carp("VLAN type ".$opts->{'name'}." ".$opts->{'vlan_low'}." - ".$opts->{'vlan_high'}." overlaps with VLAN type ".$type->{'name'}."\n");
      return -3;
    }
  }

  my $res = $self->_insert("INSERT INTO VLAN_Types (domain_id, name, description, vlan_low, vlan_high) VALUES(".$self->_escape($opts->{'domain_id'}).", '".$self->_escape($opts->{'name'})."', '".$self->_escape($opts->{'description'})."', ".$self->_escape($opts->{'vlan_low'}).", ".$self->_escape($opts->{'vlan_high'}).")");

  if(not $res) {
    carp("Unable to create new vlan type\n");
    return -2;
  }

  return 0;
}

# Delete VLAN type
sub delete_vlan_type {
  my $self = shift;
  my $vlan_type_id = shift;

  if(not defined $vlan_type_id or $vlan_type_id !~ m/^[0-9]+$/) {
    carp("Missing vlan type id or not INT");
    return -1;
  }

  my $res = $self->_delete("DELETE FROM VLAN_Types WHERE id = ".$self->_escape($vlan_type_id));
  if(not $res) {
    carp("Unable to delete VLAN Type with ID $vlan_type_id\n");
    return -2;
  }

  return 0;
}

# Modify VLAN_low attribute
sub mod_vlan_type_low {
  my $self = shift;

  return 0;
}

# Modify VLAN_high attribute
sub mod_vlan_type_high {
  my $self = shift;

  return 0;
}

# Modify vlan name attribute
sub mod_vlan_type_name {
  my $self = shift;

  return 0;
}

# Modify vlan description attribute
sub mod_vlan_type_description {
  my $self = shift;

  return 0;
}

