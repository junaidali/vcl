#!/usr/bin/perl -w
###############################################################################
# $Id:  $
###############################################################################
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

=head1 NAME

VCL::Module::OS::Linux::firewall::iptables.pm

=head1 DESCRIPTION

 This module provides VCL support for iptables-based firewalls.

=cut

##############################################################################
package VCL::Module::OS::Linux::firewall::iptables;

# Specify the lib path using FindBin
use FindBin;
use lib "$FindBin::Bin/../../../../..";

# Configure inheritance
use base qw(VCL::Module::OS::Linux);

# Specify the version of this module
our $VERSION = '2.3';

our @ISA;

# Specify the version of Perl to use
use 5.008000;

use strict;
use warnings;
use diagnostics;

use VCL::utils;

##############################################################################

=head1 OBJECT METHODS

=cut

#/////////////////////////////////////////////////////////////////////////////

=head2 initialize

 Parameters  : none
 Returns     : boolean
 Description : 

=cut

sub initialize {
	my $self = shift;
	if (ref($self) !~ /VCL::Module/i) {
		notify($ERRORS{'CRITICAL'}, 0, "subroutine was called as a function, it must be called as a class method");
		return 0;
	}
	
	my $arguments = shift || {};
	
	# Check if base_package argument was specified
	# This is necessary for ManagementNode OS objects to work
	# Otherwise the base Linux.pm subroutines would be used instead of ManagementNode.pm
	if (defined($arguments->{base_package})) {
		notify($ERRORS{'DEBUG'}, 0, "overriding object package: " . $ISA[0] . " --> $arguments->{base_package}");
		@ISA = ($arguments->{base_package});
	}
	
	my $computer_name = $self->data->get_computer_hostname();
	
	notify($ERRORS{'DEBUG'}, 0, "initializing " . ref($self) . " object to control $computer_name");
	
	if (!$self->service_exists('iptables')) {
		notify($ERRORS{'DEBUG'}, 0, ref($self) . " object not initialized to control $computer_name, iptables service does not exist");
		return 0;
	}
	
	notify($ERRORS{'DEBUG'}, 0, ref($self) . " object initialized to control $computer_name");
	return 1;
}

#/////////////////////////////////////////////////////////////////////////////

=head2 insert_rule

 Parameters  : none
 Returns     : boolean
 Description : 

=cut

sub insert_rule {
	my $self = shift;
	if (ref($self) !~ /VCL::Module/i) {
		notify($ERRORS{'CRITICAL'}, 0, "subroutine was called as a function, it must be called as a class method");
		return 0;
	}
	
	my $arguments = shift;
	if (!$arguments) {
		notify($ERRORS{'WARNING'}, 0, "argument was not supplied");
		return;
	}
	elsif (!ref($arguments) || ref($arguments) ne 'HASH') {
		notify($ERRORS{'WARNING'}, 0, "argument is not a hash reference");
		return;
	}
	my $computer_name = $self->data->get_computer_hostname();
	
	my $command = '/sbin/iptables';
	
	# Add the table argument if specified
	if ($arguments->{table}) {
		$command .= " -t $arguments->{table}";
	}
	
	# Get the chain argument
	my $chain = $arguments->{chain};
	if (!defined($chain)) {
		notify($ERRORS{'WARNING'}, 0, "chain argument was not specified:\n" . format_data($arguments));
		return;
	}
	$command .= " -I $chain";
	
	# Add the parameters to the command
	for my $parameter (sort keys %{$arguments->{parameters}}) {
		my $value = $arguments->{parameters}{$parameter};
		$command .= " --$parameter $value";
	}
	
	# Add the match extension to the command
	for my $match_extension (sort keys %{$arguments->{match_extensions}}) {
		$command .= " --match $match_extension";
		for my $option (sort keys %{$arguments->{match_extensions}{$match_extension}}) {
			my $value = $arguments->{match_extensions}{$match_extension}{$option};
			
			if ($option =~ /(comment)/) {
				$value = "\"$value\"";
			}
			
			$command .= " --$option $value";
		}
	}
	
	# Add the target extensions to the command
	for my $target_extension (sort keys %{$arguments->{target_extensions}}) {
		$command .= " --jump $target_extension";
		for my $option (sort keys %{$arguments->{target_extensions}{$target_extension}}) {
			my $value = $arguments->{target_extensions}{$target_extension}{$option};
			$command .= " --$option $value";
		}
	}
	
	my ($exit_status, $output) = $self->execute($command, 0);
	if (!defined($output)) {
		notify($ERRORS{'WARNING'}, 0, "failed to execute command $computer_name: $command");
		return;
	}
	elsif ($exit_status ne '0') {
		notify($ERRORS{'WARNING'}, 0, "failed to add iptables rule on $computer_name, exit status: $exit_status, command:\n$command\noutput:\n" . join("\n", @$output));
		return 0;
	}
	else {
		notify($ERRORS{'OK'}, 0, "added iptables rule on $computer_name, command: $command");
		return 1;
	}
}

#/////////////////////////////////////////////////////////////////////////////

=head2 delete_rule

 Parameters  : hash reference
               -or-
					$table_name, $chain_name, $rule_specification
 Returns     : boolean
 Description : Deletes a rule.

=cut

sub delete_rule {
	my $self = shift;
	if (ref($self) !~ /VCL::Module/i) {
		notify($ERRORS{'CRITICAL'}, 0, "subroutine was called as a function, it must be called as a class method");
		return 0;
	}
	
	my $argument = shift;
	if (!$argument) {
		notify($ERRORS{'WARNING'}, 0, "argument was not supplied");
		return;
	}
	
	my $computer_name = $self->data->get_computer_hostname();
	
	my $command = '/sbin/iptables';
	
	
	if (ref($argument) && ref($argument) eq 'HASH') {
		# Add the table argument if specified
		if ($argument->{table}) {
			$command .= " -t $argument->{table}";
		}
		
		# Get the chain argument
		my $chain = $argument->{chain};
		if (!defined($chain)) {
			notify($ERRORS{'WARNING'}, 0, "chain argument was not specified:\n" . format_data($argument));
			return;
		}
		$command .= " -D $chain";
		
		# Add the parameters to the command
		for my $parameter (sort keys %{$argument->{parameters}}) {
			my $value = $argument->{parameters}{$parameter};
			$command .= " --$parameter $value";
		}
		
		# Add the match extension to the command
		for my $match_extension (sort keys %{$argument->{match_extensions}}) {
			$command .= " --match $match_extension";
			for my $option (sort keys %{$argument->{match_extensions}{$match_extension}}) {
				my $value = $argument->{match_extensions}{$match_extension}{$option};
				
				if ($option =~ /(comment)/) {
					$value = "\"$value\"";
				}
				
				$command .= " --$option $value";
			}
		}
		
		# Add the target extensions to the command
		for my $target_extension (sort keys %{$argument->{target_extensions}}) {
			$command .= " --jump $target_extension";
			for my $option (sort keys %{$argument->{target_extensions}{$target_extension}}) {
				my $value = $argument->{target_extensions}{$target_extension}{$option};
				$command .= " --$option $value";
			}
		}
	}
	elsif (my $type = ref($argument)) {
		notify($ERRORS{'WARNING'}, 0, "argument $type reference not supported, argument must only be a HASH reference or scalar");
		return;
	}
	else {
		my $table_name = $argument;
		my ($chain_name, $specification) = @_;
		if (!defined($chain_name) || !defined($specification)) {
			notify($ERRORS{'WARNING'}, 0, "1st argument is a scalar, 2nd chain name and 3rd rule specification arguments not provided");
			return;
		}
		$command .= " -D $chain_name -t $table_name $specification";
	}
	
	my ($exit_status, $output) = $self->execute($command, 0);
	if (!defined($output)) {
		notify($ERRORS{'WARNING'}, 0, "failed to execute command $computer_name: $command");
		return;
	}
	elsif ($exit_status ne '0') {
		notify($ERRORS{'WARNING'}, 0, "failed to delete iptables rule on $computer_name, exit status: $exit_status, command:\n$command\noutput:\n" . join("\n", @$output));
		return 0;
	}
	else {
		notify($ERRORS{'OK'}, 0, "deleted iptables rule on $computer_name, command: $command");
		return 1;
	}
}

#/////////////////////////////////////////////////////////////////////////////

=head2 create_chain

 Parameters  : $table_name, $chain_name
 Returns     : boolean
 Description : Creates a new chain. Returns true if the chain was successfully
               created or already exists.

=cut

sub create_chain {
	my $self = shift;
	if (ref($self) !~ /VCL::Module/i) {
		notify($ERRORS{'CRITICAL'}, 0, "subroutine was called as a function, it must be called as a class method");
		return 0;
	}
	
	my ($table_name, $chain_name) = @_;
	if (!defined($table_name)) {
		notify($ERRORS{'WARNING'}, 0, "table name argument was not specified");
		return;
	}
	elsif (!defined($chain_name)) {
		notify($ERRORS{'WARNING'}, 0, "chain name argument was not specified");
		return;
	}
	
	my $computer_name = $self->data->get_computer_hostname();
	
	my $command = "/sbin/iptables --new-chain $chain_name --table $table_name";
	my ($exit_status, $output) = $self->execute($command, 0);
	if (!defined($output)) {
		notify($ERRORS{'WARNING'}, 0, "failed to execute command $computer_name: $command");
		return;
	}
	elsif (grep(/already exists/i, @$output)) {
		notify($ERRORS{'OK'}, 0, "'$chain_name' chain in '$table_name' table already exists on $computer_name");
		return 1;
	}
	elsif ($exit_status ne '0') {
		notify($ERRORS{'WARNING'}, 0, "failed to create '$chain_name' chain in '$table_name' table on $computer_name, exit status: $exit_status, command:\n$command\noutput:\n" . join("\n", @$output));
		return 0;
	}
	else {
		notify($ERRORS{'OK'}, 0, "created '$chain_name' chain in '$table_name' table on $computer_name");
		return 1;
	}
}

#/////////////////////////////////////////////////////////////////////////////

=head2 delete_chain

 Parameters  : $table_name, $chain_name
 Returns     : boolean
 Description : Deletes the specified chain from the specified table. All rules
               which exist in the chain or reference the chain are deleted prior
               to deletion of the chain.

=cut

sub delete_chain {
	my $self = shift;
	if (ref($self) !~ /VCL::Module/i) {
		notify($ERRORS{'CRITICAL'}, 0, "subroutine was called as a function, it must be called as a class method");
		return 0;
	}
	
	my ($table_name, $chain_name) = @_;
	if (!defined($table_name)) {
		notify($ERRORS{'WARNING'}, 0, "table name argument was not specified");
		return;
	}
	elsif (!defined($chain_name)) {
		notify($ERRORS{'WARNING'}, 0, "chain name argument was not specified");
		return;
	}
	
	my $computer_name = $self->data->get_computer_hostname();
	
	my $table_info = $self->get_table_info($table_name);
	if (!defined($table_info->{$chain_name})) {
		notify($ERRORS{'DEBUG'}, 0, "'$chain_name' chain in '$table_name' table does not exist on $computer_name");
		return 1;
	}
	
	# Flush the chain first - delete will fail if the chain still contains rules
	if (!$self->flush_chain($table_name, $chain_name)) {
		notify($ERRORS{'WARNING'}, 0, "unable to delete '$chain_name' chain from '$table_name' table on $computer_name, failed to flush chain prior to deletion");
		return;
	}
	
	# Delete all rules which reference the chain being deleted or else the chain can't be deleted
	if (!$self->delete_chain_references($table_name, $chain_name)) {
		notify($ERRORS{'WARNING'}, 0, "unable to delete '$chain_name' chain from '$table_name' table on $computer_name, failed to delete all rules which reference the chain prior to deletion");
		return;
	}
	
	my $command = "/sbin/iptables --delete-chain $chain_name --table $table_name";
	my ($exit_status, $output) = $self->execute($command, 0);
	if (!defined($output)) {
		notify($ERRORS{'WARNING'}, 0, "failed to execute command $computer_name: $command");
		return;
	}
	elsif (grep(/Too many links/i, @$output)) {
		notify($ERRORS{'WARNING'}, 0, "unable to delete '$chain_name' chain from '$table_name' table on $computer_name, the chain is referenced by another rule");
		return 0;
	}
	elsif ($exit_status ne '0') {
		notify($ERRORS{'WARNING'}, 0, "failed to delete '$chain_name' chain from '$table_name' table on $computer_name, exit status: $exit_status, command:\n$command\noutput:\n" . join("\n", @$output));
		return 0;
	}
	else {
		notify($ERRORS{'OK'}, 0, "deleted '$chain_name' chain from '$table_name' table on $computer_name");
		return 1;
	}
}

#/////////////////////////////////////////////////////////////////////////////

=head2 delete_chain_references

 Parameters  : $table_name, $referenced_chain_name
 Returns     : boolean
 Description : Checks all chains in the specified table for references to the
               $referenced_chain_name argument. If found, the referencing rules
               are deleted.

=cut

sub delete_chain_references {
	my $self = shift;
	if (ref($self) !~ /VCL::Module/i) {
		notify($ERRORS{'CRITICAL'}, 0, "subroutine was called as a function, it must be called as a class method");
		return 0;
	}
	
	my ($table_name, $referenced_chain_name) = @_;
	if (!defined($table_name)) {
		notify($ERRORS{'WARNING'}, 0, "table name argument was not specified");
		return;
	}
	elsif (!defined($referenced_chain_name)) {
		notify($ERRORS{'WARNING'}, 0, "referenced chain name argument was not specified");
		return;
	}
	
	my $computer_name = $self->data->get_computer_hostname();
	
	my $table_info = $self->get_table_info($table_name);
	for my $referencing_chain_name (keys %$table_info) {
		for my $rule_specification (@{$table_info->{$referencing_chain_name}{rules}}) {
			if ($rule_specification =~ /-j $referenced_chain_name(\s|$)/) {
				notify($ERRORS{'DEBUG'}, 0, "rule in '$table_name' table references '$referenced_chain_name' chain, referencing chain: $referencing_chain_name, rule specification: $rule_specification");
				if (!$self->delete_rule($table_name, $referencing_chain_name, $rule_specification)) {
					return;
				}
			}
		}
	}
	
	notify($ERRORS{'DEBUG'}, 0, "deleted all rules in '$table_name' table referencing '$referenced_chain_name' chain on $computer_name");
	return 1;
}

#/////////////////////////////////////////////////////////////////////////////

=head2 flush_chain

 Parameters  : $table_name, $chain_name
 Returns     : boolean
 Description : Flushes (deletes) rules from the specified chain.

=cut

sub flush_chain {
	my $self = shift;
	if (ref($self) !~ /VCL::Module/i) {
		notify($ERRORS{'CRITICAL'}, 0, "subroutine was called as a function, it must be called as a class method");
		return 0;
	}
	
	my ($table_name, $chain_name) = @_;
	if (!defined($table_name)) {
		notify($ERRORS{'WARNING'}, 0, "table name argument was not specified");
		return;
	}
	elsif (!defined($chain_name)) {
		notify($ERRORS{'WARNING'}, 0, "chain name argument was not specified");
		return;
	}
	
	my $computer_name = $self->data->get_computer_hostname();
	
	my $command = "/sbin/iptables --flush";
	my $chain_text = 'all chains';
	if ($chain_name ne '*') {
		$chain_text = "'$chain_name' chain";
		$command .= " $chain_name";
	}
	$command .= " --table $table_name";
	
	my ($exit_status, $output) = $self->execute($command, 0);
	if (!defined($output)) {
		notify($ERRORS{'WARNING'}, 0, "failed to execute command $computer_name: $command");
		return;
	}
	elsif ($exit_status ne '0') {
		notify($ERRORS{'WARNING'}, 0, "failed to flush $chain_text in '$table_name' table on $computer_name, exit status: $exit_status, command:\n$command\noutput:\n" . join("\n", @$output));
		return 0;
	}
	else {
		notify($ERRORS{'OK'}, 0, "flushed $chain_text in '$table_name' table on $computer_name");
		return 1;
	}
}

#/////////////////////////////////////////////////////////////////////////////

=head2 get_table_info

 Parameters  : $table_name, $chain_name (optional)
 Returns     : boolean
 Description : 

=cut

sub get_table_info {
	my $self = shift;
	if (ref($self) !~ /VCL::Module/i) {
		notify($ERRORS{'CRITICAL'}, 0, "subroutine was called as a function, it must be called as a class method");
		return 0;
	}
	
	my ($table_name, $chain_name) = @_;
	if (!defined($table_name)) {
		notify($ERRORS{'WARNING'}, 0, "table name argument was not specified");
		return;
	}
	
	my $computer_name = $self->data->get_computer_hostname();
	
	my $command = "/sbin/iptables --list-rules";
	my $chain_text = '';
	if (defined($chain_name)) {
		$command .= " $chain_name";
		$chain_text = "of '$chain_name' chain ";
	}
	$command .= " --table $table_name";
	
	my ($exit_status, $output) = $self->execute($command, 0);
	if (!defined($output)) {
		notify($ERRORS{'WARNING'}, 0, "failed to execute command $computer_name: $command");
		return;
	}
	elsif ($exit_status ne '0') {
		notify($ERRORS{'WARNING'}, 0, "failed to list rules " . $chain_text . "from '$table_name' table on $computer_name, exit status: $exit_status, command:\n$command\noutput:\n" . join("\n", @$output));
		return 0;
	}
	
	my $table_info = {};
	for my $line (@$output) {
		my ($iptables_command, $chain_name, $specification) = $line =~ /^(-\w) ([^ ]+)\s*(.*)$/;
		if (!defined($iptables_command) || !defined($chain_name)) {
			notify($ERRORS{'WARNING'}, 0, "failed to parse line: '$line'\ncommand: $command");
			next;
		}
		$specification = '' unless defined($specification);
		
		if ($iptables_command eq '-P') {
			# -P, --policy chain target (Set  the policy for the chain to the given target)
			$table_info->{$chain_name}{policy} = $specification;
		}
		elsif ($iptables_command eq '-N') {
			# -N, --new-chain chain
			$table_info->{$chain_name} = {} unless defined($table_info->{$chain_name});
		}
		elsif ($iptables_command eq '-A') {
			# -A, --append chain rule-specification
			push @{$table_info->{$chain_name}{rules}}, $specification;
		}
		else {
			notify($ERRORS{'WARNING'}, 0, "'$iptables_command' command is not supported: $line");
		}
	}
	
	notify($ERRORS{'DEBUG'}, 0, "retrieved rules " . $chain_text . "from '$table_name' table from $computer_name:\n" . format_data($table_info));
	return $table_info;
}


#/////////////////////////////////////////////////////////////////////////////

=head2 configure_nat

 Parameters  : none
 Returns     : boolean
 Description : 

=cut

sub configure_nat {
	my $self = shift;
	if (ref($self) !~ /VCL::Module/i) {
		notify($ERRORS{'CRITICAL'}, 0, "subroutine was called as a function, it must be called as a class method");
		return 0;
	}
	
	my $reservation_id = $self->data->get_reservation_id();
	my $computer_name = $self->data->get_computer_hostname();
	
	my $table_info = $self->get_table_info('nat');
	if (!$table_info) {
		notify($ERRORS{'WARNING'}, 0, "failed to configure NAT on $computer_name, nat table info could not be retrieved");
		return;
	}
	elsif (!defined($table_info->{PREROUTING})) {
		notify($ERRORS{'WARNING'}, 0, "unable to configure NAT on $computer_name, nat table does not contain a PREROUTING chain:\n" . format_data($table_info));
		return;
	}
	elsif (!defined($table_info->{POSTROUTING})) {
		notify($ERRORS{'WARNING'}, 0, "unable to configure NAT on $computer_name, nat table does not contain a POSTROUTING chain:\n" . format_data($table_info));
		return;
	}
	
	# Check if NAT has previously been configured
	my $nat_previously_configured = 0;
	for my $rule_specification (@{$table_info->{POSTROUTING}{rules}}) {
		if ($rule_specification =~ /MASQUERADE/) {
			$nat_previously_configured = 1;
			notify($ERRORS{'DEBUG'}, 0, "POSTROUTING chain in nat table contains a MASQUERADE rule, assuming NAT has already been configured: $rule_specification");
			last;
		}
	}
	if (!$nat_previously_configured) {
		my $private_interface_name = $self->get_private_interface_name();
		my $private_ip_address = $self->get_private_ip_address();
		my $public_interface_name = $self->get_public_interface_name();
		my $public_ip_address = $self->get_public_ip_address();
		
		my $natport_ranges_variable = get_variable('natport_ranges') || '49152-65535';
		my $destination_ports = '';
		for my $natport_range (split(/[,;]+/, $natport_ranges_variable)) {
			my ($start_port, $end_port) = $natport_range =~ /(\d+)-(\d+)/g;
			if (!defined($start_port)) {
				notify($ERRORS{'WARNING'}, 0, "unable to parse NAT port range: '$natport_range'");
				next;
			}
			$destination_ports .= "," if ($destination_ports);
			$destination_ports .= "$start_port:$end_port";
		}
		
		
		if (!$self->insert_rule({
			'table' => 'nat',
			'chain' => 'POSTROUTING',
			'parameters' => {
				'out-interface' => $private_interface_name,
				'jump' => 'MASQUERADE',
			},
			'match_extensions' => {
				'comment' => {
					'comment' => "change IP of outbound private $private_interface_name packets to NAT host private IP address $private_interface_name",
				},
			},
		})) {
			return;
		}
		
		if (!$self->insert_rule({
			'chain' => 'INPUT',
			'parameters' => {
				'in-interface' => $public_interface_name,
				'destination' => $public_ip_address,
				'jump' => 'ACCEPT',
				'protocol' => 'tcp',
			},
			'match_extensions' => {
				'state' => {
					'state' => 'RELATED,ESTABLISHED',
				},
				'multiport' => {
					'destination-ports' => $destination_ports,
				},
			},
		})) {
			return;
		}
		
		if (!$self->insert_rule({
			'chain' => 'INPUT',
			'parameters' => {
				'in-interface' => $public_interface_name,
				'destination' => $public_ip_address,
				'jump' => 'ACCEPT',
				'protocol' => 'udp',
			},
			'match_extensions' => {
				'state' => {
					'state' => 'RELATED,ESTABLISHED',
				},
				'multiport' => {
					'destination-ports' => $destination_ports,
				},
			},
		})) {
			return;
		}
		
		if (!$self->insert_rule({
			'chain' => 'FORWARD',
			'parameters' => {
				'in-interface' => $public_interface_name,
				'out-interface' => $private_interface_name,
				'jump' => 'ACCEPT',
			},
			'match_extensions' => {
				'state' => {
					'state' => 'NEW,RELATED,ESTABLISHED',
				},
				'comment' => {
					'comment' => "forward inbound packets from public $public_interface_name to private $private_interface_name",
				},
			},	
		})) {
			return;
		}
		
		if (!$self->insert_rule({
			'chain' => 'FORWARD',
			'parameters' => {
				'in-interface' => $private_interface_name,
				'out-interface' => $public_interface_name,
				'jump' => 'ACCEPT',
			},
			'match_extensions' => {
				'comment' => {
					'comment' => "forward outbound packets from private $private_interface_name to public $public_interface_name",
				},
			},
		})) {
			return;
		}
		
		#if (!$self->insert_rule({
		#	'chain' => 'INPUT',
		#	'parameters' => {
		#		'in-interface' => $public_interface_name,
		#	},
		#	'target_extensions' => {
		#		'REJECT' => {
		#			'reject-with' => "icmp-host-prohibited",
		#		},
		#	},
		#})) {
		#	return;
		#}
		#
		#if (!$self->insert_rule({
		#	'chain' => 'FORWARD',
		#	'target_extensions' => {
		#		'REJECT' => {
		#			'reject-with' => "icmp-host-prohibited",
		#		},
		#	},
		#})) {
		#	return;
		#}
	}
	
	# Check if chain for reservation has already been created
	if (defined($table_info->{$reservation_id})) {
		notify($ERRORS{'DEBUG'}, 0, "'$reservation_id' chain already exists in nat table on $computer_name for this reservation");
	}
	else {
		if (!$self->create_chain('nat', $reservation_id)) {
			notify($ERRORS{'WARNING'}, 0, "failed to configure NAT on $computer_name, '$reservation_id' chain could not be created in nat table for this reservation");
			return;
		}
	}
	
	# Check if rule to jump to reservation's chain already exists in the PREROUTING table
	my $jump_previously_configured = 0;
	for my $rule_specification (@{$table_info->{PREROUTING}{rules}}) {
		if ($rule_specification =~ /-j $reservation_id(\s|$)/) {
			$jump_previously_configured = 1;
			notify($ERRORS{'DEBUG'}, 0, "PREROUTING chain in nat table on $computer_name already contains a rule to jump to '$reservation_id' chain: $rule_specification");
			last;
		}
	}
	if (!$jump_previously_configured) {
		if (!$self->insert_rule({
			'table' => 'nat',
			'chain' => 'PREROUTING',
			'parameters' => {
				'jump' => $reservation_id,
			},
		})) {
			notify($ERRORS{'WARNING'}, 0, "unable to configure NAT on $computer_name, failed to create rule in PREROUTING chain in nat table to jump to '$reservation_id' chain");
			return;
		}
	}
	
	notify($ERRORS{'DEBUG'}, 0, "successfully configured NAT on $computer_name for reservation");
	return 1;
}

#/////////////////////////////////////////////////////////////////////////////

=head2 add_nat_port_forward

 Parameters  : $protocol, $source_port, $destination_ip_address, $destination_port, $chain_name (optional)
 Returns     : boolean
 Description : 

=cut

sub add_nat_port_forward {
	my $self = shift;
	if (ref($self) !~ /VCL::Module/i) {
		notify($ERRORS{'CRITICAL'}, 0, "subroutine was called as a function, it must be called as a class method");
		return 0;
	}

	my $reservation_id = $self->data->get_reservation_id();
	my $computer_name = $self->data->get_computer_hostname();
	
	my ($protocol, $source_port, $destination_ip_address, $destination_port, $chain_name) = @_;
	if (!defined($protocol)) {
		notify($ERRORS{'WARNING'}, 0, "protocol argument was not provided");
		return;
	}
	elsif (!defined($source_port)) {
		notify($ERRORS{'WARNING'}, 0, "source port argument was not provided");
		return;
	}
	elsif (!defined($destination_ip_address)) {
		notify($ERRORS{'WARNING'}, 0, "destination IP address argument was not provided");
		return;
	}
	elsif (!defined($destination_port)) {
		notify($ERRORS{'WARNING'}, 0, "destination port argument was not provided");
		return;
	}
	$chain_name = 'PREROUTING' unless defined $chain_name;
	
	$protocol = lc($protocol);
	
	my $public_interface_name = $self->get_public_interface_name();
	my $public_ip_address = $self->get_public_ip_address();
	
	if ($self->insert_rule({
		'table' => 'nat',
		'chain' => $chain_name,
		'parameters' => {
			'protocol' => $protocol,
			'in-interface' => $public_interface_name,
			'destination' => $public_ip_address,
		},
		'match_extensions' => {
			'comment' => {
				'comment' => "change destination address: $public_ip_address:$source_port --> $destination_ip_address:$destination_port ($protocol)",
			},
			$protocol => {
				'destination-port' => $source_port,
			},
		},
		'target_extensions' => {
			'DNAT' => {
				'to-destination' => "$destination_ip_address:$destination_port",
			},
		},
	})) {
		notify($ERRORS{'OK'}, 0, "added NAT port forward on $computer_name: $public_interface_name:$source_port --> $destination_ip_address:$destination_port");
		return 1;
	}
	else {
		notify($ERRORS{'WARNING'}, 0, "failed to add NAT port forward on $computer_name: $public_interface_name:$source_port --> $destination_ip_address:$destination_port");
		return;
	}
}

#/////////////////////////////////////////////////////////////////////////////

1;
__END__

=head1 SEE ALSO

L<http://cwiki.apache.org/VCL/>

=cut
