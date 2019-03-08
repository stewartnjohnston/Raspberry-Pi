#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);
 
my $filename   = $ARGV[0];

open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
  
  my $fileDate = strftime " %Y-%m-%d", localtime((stat($filename))[9]);
  my $jobTitle;
  my $companyName;
  my $jobLocation;

while (my $row = <$fh>) {
  chomp $row;
  
  my $text;
  
  if (($text) = $row =~ /jobsearch-JobInfoHeader-title\"\>(.*?)<\/h3/) {
    $jobTitle = $text;
    }
    
  if (($text) = $row =~ /icl-u-lg-mr--sm icl-u-xs-mr--xs\"\>(.*?)<\/div/) {
    $companyName = $text;
    }

  if (($text) = $row =~ /icl-JobResult-jobLocation\"\>(.*?)\<\/span/) {
    $jobLocation = $text;
    }
   
}
print "\"$jobTitle\", \"$companyName\", \"$jobLocation\", \"$fileDate\", \"$filename\"\n";
#print "done\n";

