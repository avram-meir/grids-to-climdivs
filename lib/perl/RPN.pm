#!/usr/bin/perl

package RPN;

=pod

=head1 NAME

RPN - A very simple Reverse Polish Notation calculator

=head1 SYNOPSIS

 use RPN qw(rpn_calc);
 
 my $temp_degC = 100;
 my $temp_degF = rpn_calc(':',join(':',$temp_degC,9,'*',5,'/',32,'+');  # Returns 212!

=head1 DESCRIPTION

The RPN package provides a very basic and simple Reverse Polish Notation calculator. Only the 4 main arithmetic operators (addition +, subtraction -, multiplication *, division /) are supported.

The algorithm for this calculator was taken from: L<https://perlmaven.com/reverse-polish-calculator-in-perl>

=head1 METHODS

=head2 rpn_calc

 my $value = rpn_calc($delimiter,$rpn_expr);

Given a delimiter value (e.g., a comma, or a colon), and a Reverse Polish Notation expression using that deliminator as separators, returns the resulting value of the calculation.

=head1 AUTHOR

Adam Allgood

This documentation was last updated on: 28MAR2022

=cut

use strict;
use warnings;
use Carp qw(carp cluck croak confess);
use vars qw(@ISA @EXPORT_OK);
use Exporter;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(rpn_calc);

sub rpn_calc {
	confess "Missing required arguments" unless(@_ >= 2);
	my $delimiter  = shift;
	my $rpn_expr   = shift;
	my @statements = split(/$delimiter/,$rpn_expr);
	confess "Invalid input arguments" unless(@statements >= 3);
	push(@statements,'=');
	my @stack;

	EXPR: foreach my $expr (@statements) {

		if ($expr eq '*') {
			confess "Invalid RPN expression" unless(@stack >= 2);
			my $x = pop(@stack);
			my $y = pop(@stack);
			push(@stack, $x*$y);
			next EXPR;
		}
		
		if ($expr eq '+') {
			confess "Invalid RPN expression" unless(@stack >= 2);
			my $x = pop(@stack);
			my $y = pop(@stack);
			push(@stack, $x + $y);
			next EXPR;
		}
		
		if ($expr eq '/') {
			confess "Invalid RPN expression" unless(@stack >= 2);
			my $x = pop(@stack);
			my $y = pop(@stack);
			push(@stack, $y /  $x); 
			next EXPR;
		}
		
		if ($expr eq '-') {
			confess "Invalid RPN expression" unless(@stack >= 2);
			my $x = pop(@stack);
			my $y = pop(@stack);
			push(@stack, $y - $x);
			next;
		}
		
		if ($in eq '=') {
			confess "Invalid RPN expression" unless(@stack >= 2);
			return pop(@stack);
			last;
		}
		
		if(looks_like_number($expr)) { push @stack, $expr; }
		else                         { confess "Invalid RPN expression"; }
	}  # :EXPR

}

1;

