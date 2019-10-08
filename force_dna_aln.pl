#!/usr/bin/perl -w

# amemded by eric 07/11/2013

use strict;

my $aa_aln_file = $ARGV[0] || die "need aa aln\n";
my $dna_fasta_file = $ARGV[1] || die "need dna fasta\n";
my $dna_aln_file = $ARGV[2] || die "need dna aln file\n";

# read in aa aln
my %seq;
my @seq_order = ();
my $aa_id = "";
open IN, "< $aa_aln_file";
while (<IN>){
	chomp;
	if (/>(\S+)/){
		$aa_id = $1;
		$seq{$aa_id}{desc} = $';
		push (@seq_order, $aa_id);
	} else {
                s/\s+//g;
		$seq{$aa_id}{aa} .= $_;
	}
}
close IN;

# read in dna fasta
my $dna_id = "";
open IN, "< $dna_fasta_file";
while (<IN>){
	chomp;
	if (/>(\S+)/){
		$dna_id = $1;
	} else {
                s/\s+//g;
                s/X/N/g;
                s/x/n/g;
		$seq{$dna_id}{dna} .= $_;
	}
}
close IN;

open OUT, "> $dna_aln_file";
foreach my $id (@seq_order){
	unless ($seq{$id}{aa} && $seq{$id}{dna}){
		print "$id does not have a valid aa and dna\n";
		next;
	}
	my $aa_aln = $seq{$id}{aa};
	my $aa_aln_no_gaps = $aa_aln;
	$aa_aln_no_gaps =~ s/-//g;
	my $dna = $seq{$id}{dna};
	#print "$id\n$aa_aln\n$aa_aln_no_gaps\n$dna\n";
	print $id . "\t" . length($dna) . "\t" . int(length($dna)/3) . "\t" . length($aa_aln_no_gaps) . "\n";
        if (int(length($dna)/3) < length($aa_aln_no_gaps)) {
                 print "$id has dna condon length less than aa length\n";
                 print "skipping....\n";
                 next;
        }
	if (length($dna) % length($aa_aln_no_gaps) != 0){
		# check to see if the last 3 bases are stop codon -> TAA,TAG,TGA
		my $last_codon = substr($dna,-3);
		if ($last_codon eq "TAA" || $last_codon eq "TAG" || $last_codon eq "TGA" || $last_codon eq "taa" || $last_codon eq "tag" || $last_codon eq "tga"){
			$dna = substr($dna, 0, -3);
		} else {
			# not in frame
			print "$id not codon frame\n";
			print "$id aa length = " . length($aa_aln_no_gaps) . "\n";
			print "$id dna length = " . length($dna) . "\n";
                        print "skipping....\n";
			#exit;
                        next;
		}
	}
	my @aa_aln = split("", $aa_aln);
	my @codon = unpack("a3" x int(length($dna)/3) ,$dna);
        print length($aa_aln_no_gaps) . "\t" .  ($#codon + 1) . "\n";
        if (length($aa_aln_no_gaps) != ($#codon + 1)) {
                print "$id not codon frame\n";
                print "$id aa length = " . length($aa_aln_no_gaps) . "\n";
                print "$id dna length = " . length($dna) . "\n";
                print "skipping....\n";
                next;
        }
        print OUT ">$id$seq{$id}{desc}\n";
	my $index = 0;
	foreach my $aa (@aa_aln) {
		if ($aa eq "-") {
			print OUT "---";
		} elsif ($aa eq "?"){
			print OUT "???";
			$index++;
		} else {
			print OUT $codon[$index];
			$index++;
		}
	}
	print OUT "\n";
}
close OUT;
exit;
