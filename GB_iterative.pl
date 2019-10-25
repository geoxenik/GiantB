#!/usr/bin/perl -w 

## Script for iterative mapping  
## Note: Reference is indexed with bwa index and samtools faidx. The script works on paired end reads merged with Flash software.
## Required Software: BWA, samtools, angsd, MarkDupsByStartEnd.jar 




use strict;
my $path=$ARGV[0];																						# path to original reference (ref needs ".fasta" extension)
my $Iterations=$ARGV[1];																				# number of iterations

system "bwa aln -t 2 -l 999 $path/*fasta Merged.extendedFrags.fastq.gz > merged.sai"; 					
system "bwa samse $path/*fasta merged.sai Merged.extendedFrags.fastq.gz > merged.sam";
system "samtools view -F 4 -q 25 -uS merged.sam | samtools sort -o merged.sort";
system "java -jar -Xmx2g ~/Applications/BioSoft/MarkDupsByStartEnd.jar -i  merged.sort -o merged_Marked_dup.bam";			# MarkDupsByStartEnd.jar script available at https://github.com/dariober/Java-cafe/tree/master/MarkDupsByStartEnd
system "samtools view -@ 10 -b -F 0x400  merged_Marked_dup.bam   -o  merged.rmdup.bam";
system "samtools flagstat merged.rmdup.bam";
system "samtools index merged.rmdup.bam";
system "angsd -doFasta 2 -nThreads 4 -bam bam.filelist -doCounts 1 -minMapQ 25 -minQ 30 -setMinDepth 3 -basesPerLine 70	 -out out_ref_It0";
system "gunzip out_ref_It0.fa.gz";
system "mkdir It0";																											# output folder for Iteration.X
system "mv merged* It0";																									

foreach my $i (1..$Iterations) {																						
	my $a=$i-1;																							
	system "bwa index out_ref_It$a.fa";
	system "samtools faidx out_ref_It$a.fa";
	system "bwa aln  -t 2 -n 0.01 -l 999 out_ref_It$a.fa Merged.extendedFrags.fastq.gz > merged.sai";	
	system "bwa samse out_ref_It$a.fa merged.sai Merged.extendedFrags.fastq.gz > merged.sam";
	system "samtools view -F 4 -q 25 -uS merged.sam | samtools sort -o merged.sort";
	system "java -jar -Xmx2g ~/Applications/BioSoft/MarkDupsByStartEnd.jar -i  merged.sort -o merged_Marked_dup.bam"; 	
	system "samtools view -@ 10 -b -F 0x400  merged_Marked_dup.bam   -o  merged.rmdup.bam"; 
	system "samtools flagstat merged.rmdup.bam";
	system "samtools index merged.rmdup.bam";							
	system "angsd -doFasta 2 -nThreads 4 -bam bam.filelist -doCounts 1 -minMapQ 25 -minQ 30 -setMinDepth 3 -basesPerLine 70 -out out_ref_It$i";	
	system "gunzip out_ref_It$i.fa.gz";	
	system "mkdir It$i";
	system "mv merged* It$i";
}
	
