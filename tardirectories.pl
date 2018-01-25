#!/usr/bin/env perl
#===============================================================================
#
#         FILE: tardirectories.pl
#
#        USAGE: ./tardirectories.pl destination/path directory directory ...
#
#  DESCRIPTION: Tars the given directories into the given destination.
#
#    ARGUMENTS:
#				- 1: /destination/path
#				- 2..N: Space separated list of absolute paths to archive.
#
#      OPTIONS: None
# REQUIREMENTS:
#				- Archive::Tar
#				- File::Find
#				- IO:: Zlib (For compression)
#
#         BUGS: It probably doesn't handle relative paths correctly.
#        NOTES: Passed files are ignored. 
#      VERSION: 0.1
#       AUTHOR: Ryan Quinn (RQ)
# ORGANIZATION: dangertoaster.com
#      LICENSE:	BSD 3-Clause 
#      CREATED: 01/17/2018 03:21:49 PM
#===============================================================================

use strict;
use warnings 'all';
use utf8;
use 5.010;

use Archive::Tar; # Requires IO::Zlib for compression
use POSIX qw(strftime);
use File::Find;

use vars qw(*name);
*name = *File::Find::name;

# Usage: tarfiles.pl destination dir dir dir
if (@ARGV < 2) {
	print "Destination dir and/or source dirs are needed.\n";
	print "Usage $0 destination/path /dir /dir /dir/\n";
	exit 1;
}

my $date = strftime "%Y%m%d%H%M%S", localtime;
my $dest = shift @ARGV;
my $src_name = '';  
my $src_path = '';
my @files = ();

# ------- Subroutines Start -------

# Trimming the last '/' from the path, not that it matters.
sub clean_string {
	my $cleaned_string = shift @_;

	if ($cleaned_string =~ /\/\z/ && $cleaned_string !~ /\A\/\z/) {
		chop $cleaned_string;
	}

	return $cleaned_string;
}

sub get_name_path {
	my @string = split "/", (shift @_);
	return (pop(@string), join("/", @string));
}

sub build_archive {
	my ($src_name, $archive_dest, @filelist) = @_;
	my $archive_name = $archive_dest . "/" . $src_name . ".tar.gz";
	my $archive = Archive::Tar->new;

	$archive->add_files(@filelist);
	unless ($archive->write($archive_name, 9)) {
		die "Unable to create $archive_name.\n";
	}
}
# ------- Subroutines End -------

$dest = clean_string($dest);

unless (mkdir "$dest/$date") {
	die "Unable to create $dest/$date\n";
}

print("Destination directory \"$dest/$date\"\n");

foreach my $path (@ARGV) {
	$path = clean_string($path);
	($src_name, $src_path) = get_name_path($path);

	chdir $src_path;

	if (-d $src_name) {
		File::Find::find (sub {push @files, $name}, $src_name);
		if (@files) {
			print("Archiving directory \"" . $path . "\" as \"$dest/$date/$src_name\".\n");
			build_archive($src_name, "$dest/$date", @files);
			@files = ();
		}
	} else {
		print("Skipping directory \"$src_path/$src_name\", path does not exist.\n");
	}
}

__END__
