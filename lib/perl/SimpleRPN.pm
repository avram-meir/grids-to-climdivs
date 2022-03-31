#!/usr/bin/perl

package SimpleRPN;

=pod

=head1 NAME

SimpleRPN - A very simple Reverse Polish Notation calculator

=head1 SYNOPSIS

 use SimpleRPN qw(rpn_calc);
 
 my $temp_degC = 100;
 my $temp_degF = rpn_calc(join(':',$temp_degC,9,'*',5,'/',32,'+'),':');  # Returns 212!

=head1 DESCRIPTION

The SimpleRPN package provides a very basic and simple Reverse Polish Notation calculator. Only the 4 main arithmetic operators (addition +, subtraction -, multiplication *, division /) are supported.

The algorithm for this calculator was taken from: L<https://perlmaven.com/reverse-polish-calculator-in-perl>

=head1 METHODS

=head2 rpn_calc

 my $value = rpn_calc($rpn_expr,$delimiter);

Given a valid expression in Reverse Polish Notation (operator(s) to the right of the operands), returns the resulting value of that expression. The default delimiter between the components of the expression is a comma ',', but can be set to other values by passing a second delimiter argument.

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
	confess "Argument required" unless(@_ >= 1);
	my $rpn_expr   = shift;
	my $delimiter  = ',';
	if(@_) { $delimiter = shift; }
	my @statements = split(/$delimiter/,$rpn_expr);
	confess "Invalid RPN expression" unless(@statements >= 3);
	push(@statements,'=');
	my @stack;

	EXPR: foreach my $expr (@statements) {

		if($expr eq '*') {
			confess "Invalid RPN expression" unless(@stack >= 2);
			my $x = pop(@stack);
			my $y = pop(@stack);
			push(@stack, $x*$y);
			next EXPR;
		}
		
		if($expr eq '+') {
			confess "Invalid RPN expression" unless(@stack >= 2);
			my $x = pop(@stack);
			my $y = pop(@stack);
			push(@stack, $x + $y);
			next EXPR;
		}
		
		if($expr eq '/') {
			confess "Invalid RPN expression" unless(@stack >= 2);
			my $x = pop(@stack);
			my $y = pop(@stack);
			push(@stack, $y /  $x); 
			next EXPR;
		}
		
		if($expr eq '-') {
			confess "Invalid RPN expression" unless(@stack >= 2);
			my $x = pop(@stack);
			my $y = pop(@stack);
			push(@stack, $y - $x);
			next EXPR;
		}

		if($expr eq '^') {
			confess "Invalid RPN expression" unless(@stack >= 2);
			my $x = pop(@stack);
			my $y = pop(@stack);
			push(@stack, $y**$x);
			next EXPR;
		}

		if($expr eq '%') {
			confess "Invalid RPN expression" unless(@stack >= 2)
			my $x = pop(@stack);
			my $y = pop(@stack);
			push(@stack, $y % $x);
			next EXPR;
		}
		
		if($in eq '=') {
			confess "Invalid RPN expression" unless(@stack >= 2);
			return pop(@stack);
			last EXPR;
		}
		
		if(looks_like_number($expr)) { push @stack, $expr; }
		else                         { confess "Invalid RPN expression"; }
	}  # :EXPR

}

1;

