package Bencher::Scenario::CBlocks::IO;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::Temp qw(tempfile);

our $infile_path;
our $outfile_path;

our $scenario = {
    summary => 'Benchmark I/O performance of C::Blocks',
    description => <<'_',

Each code reads a 100k-line file, line by line. Some lines (10% of them)
contains `Fred` which will be substituted with `Barney`. The lines are written
back to another file.

_
    precision => 6,
    before_bench => sub {
        (my $fh, $infile_path) = tempfile();
        log_debug("Input temp file is %s", $infile_path);
        for my $i (1..100*1024) {
            if ($i % 10 == 0) {
                print $fh "Fred Fred\n";
            } else {
                print $fh "Elmo Elmo\n";
            }
        }
        close $fh;
        (my $out_fh, $outfile_path) = tempfile();
        log_debug("Output temp file is %s", $outfile_path);
    },
    after_bench => sub {
        if (log_is_debug) {
            log_debug("Keeping input and output temp files");
        } else {
            unlink $infile_path;
            unlink $outfile_path;
        }
    },
    participants => [
        {
            name => 'perl',
            code => sub {
                open my $in_fh, "<", $infile_path or die $!;
                open my $out_fh, ">", $outfile_path or die $!;
                while (<$in_fh>) {
                    s/Fred/Barney/g;
                    print $out_fh $_;
                }
            },
        },
        {
            name => 'C::Blocks',
            module => 'C::Blocks',
            code => sub {
                use C::Blocks;
                use C::Blocks::Types qw(char_array);
                my char_array $in_path  = $infile_path;
                my char_array $out_path = $outfile_path;

                cblock {
                    FILE * in_fh = fopen($in_path, "r");
                    FILE * out_fh = fopen($out_path, "w");
                    char * original = "Fre";

                    int match_length = 0;
                    int curr_char = fgetc(in_fh);
                    while (curr_char != EOF) {
                        if (curr_char == original[match_length]) {
                            /* found character in sequence */
                            match_length++;
                        }
                        else if (match_length == 3 && curr_char == 'd') {
                            /* found full name! print and reset */
                            fprintf(out_fh, "Barney");
                            match_length = 0;
                        }
                        else {
                            /* incomplete match, print what we've skipped */
                            if (match_length) fprintf(out_fh, "%.*s", match_length, original);

                            /* just in case we have FFred or FreFred */
                            if (curr_char == 'F') match_length = 1;
                            else {
                                match_length = 0;
                                fputc(curr_char, out_fh);
                            }
                        }

                        curr_char = fgetc(in_fh);
                    }

                    fclose(in_fh);
                    fclose(out_fh);
                }
            },
        },
    ],
};

1;
# ABSTRACT:

=head1 SEE ALSO
