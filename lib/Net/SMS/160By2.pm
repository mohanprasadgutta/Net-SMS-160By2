package Net::SMS::160By2;

use warnings;
use strict;
use Data::Dumper;
# Load this to handle exceptions nicely
use Carp;

# Load this to make HTTP Requests
use WWW::Mechanize;

# Load this to uncompress the gzip content of http response.
use Compress::Zlib;

=head1 NAME

Net::SMS::160By2 - Send SMS using your 160By2 account!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our $DEBUG = 1;

our $HOME_URL       = 'http://www.160by2.com/index.aspx';
our $SENDSMS_URL     = 'http://www.160by2.com/publicsms_sendsms.aspx'; 

=head1 SYNOPSIS

This module provides a wrapper around 160By2.com to send an SMS to any mobile number in 

India, Kuwait, UAE, Saudi, Singapore, Philippines & Malaysia at present.

you can use this as follows.

    use Net::SMS::160By2;

    my $obj = Net::SMS::160By2->new($username, $password);
    
    $obj->send_sms($msg, $to);
    
Thats it!
    
=head1 SUBROUTINES/METHODS

=head2 new

This is constructor method.

input: username, password

A new object will be created with username, password attributes.

output: Net::SMS::160By2 object

=cut

sub new {
	my $class = shift;
	
	# read username and password
	my $username = shift;
	my $password = shift;
	
	# Throw error in case of no username or password
	croak("No username provided") unless ($username);
	croak("No password provided") unless ($password);
	
	# return blessed object
	my $self = bless {
		'username' => $username,
		'password' => $password,
		'mobile'   => undef,
		'message'  => undef
	}, $class;
	return $self;
}

=head2 send_sms

This method is used to send an SMS to any mobile number.
input : message, to

where message contains the information you want to send.
      to is the recipient mobile number
      
=cut

sub send_sms {
	my ($self, $msg, $to) = @_;
	croak("Message or mobile number are missing") unless ($msg || $to);
	
	# trim spaces
	$msg =~ s/^\s+|\s+$//;
	$to =~ s/^\s+|\s+$//;

	# set message and mobile number
	$self->{message} = $msg;
	$self->{mobile} = $to;

	# create mechanize object
	my $mech = WWW::Mechanize->new(autocheck => 1);
	
	# Now connect to 160By2 Website login page
	$mech->get($HOME_URL);
	
	# handle gzip content
	my $response = $mech->response->content;
	if ( $mech->response->header('Content-Encoding') eq 'gzip' ) {
		$response = Compress::Zlib::memGunzip($response );
		$mech->update_html( $response ) 
	}

	# login to 160By2
	my $status = $self->_login($mech);
	
	die "Login Failed" unless $status;

	# sendsms from 160by2
	return $self->_send($mech);
}

sub _login {
	my ($self, $mech) = @_;

	# Get login form with htxt_UserName, txt_Passwd
	$mech->form_with_fields('htxt_UserName', 'txt_Passwd');
	
	# set htxt_UserName, txt_Passwd
	$mech->field('htxt_UserName', $self->{username});
	$mech->field('txt_Passwd', $self->{password});
	
	# submit form
	$mech->submit_form();
	
	# Verify login success/failed
	# handle gzip content
	my $response = $mech->response->content;
	if ( $mech->response->header('Content-Encoding') eq 'gzip' ) {
		$response = Compress::Zlib::memGunzip( $response );
		$mech->update_html( $response ) 
	}
	return $mech;
}

sub _send {
	my ($self, $mech) = @_;
	
	# Get content of SendSMS form page
	$mech->get($SENDSMS_URL);

	if ( $mech->response->header('Content-Encoding') eq 'gzip' ) {
		# handle gzip content
		my $response = $mech->response->content;
		$response = Compress::Zlib::memGunzip( $response );
		$mech->update_html( $response ); 
	}
	# Get login form with htxt_UserName, txt_Passwd
	my $form = $mech->form_with_fields('txt_mobileno', 'txt_send_sms', 'act_mnos');
	# set htxt_UserName, txt_Passwd
	$mech->field('txt_mobileno', $self->{mobile});
	$mech->field('txt_send_sms', $self->{message});
	my $mobile = $self->{mobile};
	$mech->field('act_mnos', ($mobile =~ /^91/ && length($mobile) > 10 ? "$mobile," : "91$mobile,"));
	
	# submit form
	$mech->submit_form();
	
	# is URL call Success?
	if ($mech->success()) {
		
		# Check sms sent successfully
		my $response = $mech->response->content;
		if($mech->response->header("Content-Encoding") eq "gzip") {
			$response = Compress::Zlib::memGunzip($response) ;
		}
		# return 1(true) in case of success
		return 1 if($response =~ m/SMS Sent Successfully/sig);
	}
	# return undef as failure
	return;
}

=head1 AUTHOR

Mohan Prasad Gutta, C<< <mohanprasadgutta at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-sms-160by2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SMS-160By2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SMS::160By2


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SMS-160By2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SMS-160By2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SMS-160By2>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SMS-160By2/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Mohan Prasad Gutta.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::SMS::160By2
