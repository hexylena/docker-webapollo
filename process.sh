#!/bin/bash

tar xvfz pyu_data.tgz

$WEBAPOLLO_ROOT/tools/user/extract_seqids_from_fasta.pl \
	-p Annotations- \
	-i pyu_data/scf1117875582023.fa \
	-o seqids.txt

$WEBAPOLLO_ROOT/tools/user/add_tracks.pl \
	-H $DB_PORT_5432_TCP_ADDR \
	-D $WEBAPOLLO_DATABASE \
	-U $PGUSER \
	-P $PGPASSWORD \
	-t seqids.txt

$WEBAPOLLO_ROOT/tools/user/set_track_permissions.pl \
	-H $DB_PORT_5432_TCP_ADDR \
	-D $WEBAPOLLO_DATABASE \
	-U $PGUSER \
	-P $PGPASSWORD \
	-u $WEBAPOLLO_USER \
	-t seqids.txt \
	-a


$JBROWSE_DIR/bin/prepare-refseqs.pl --fasta pyu_data/scf1117875582023.fa --out $JBROWSE_DATA_DIR
$WEBAPOLLO_ROOT/client/apollo/bin/add-webapollo-plugin.pl -i $JBROWSE_DATA_DIR/trackList.json

mkdir split_gff
$WEBAPOLLO_ROOT/tools/data/split_gff_by_source.pl -i pyu_data/scf1117875582023.gff -d split_gff
$JBROWSE_DIR/bin/flatfile-to-json.pl --gff split_gff/maker.gff --type mRNA --trackLabel maker --out $JBROWSE_DATA_DIR

$JBROWSE_DIR/bin/flatfile-to-json.pl --gff split_gff/maker.gff   --arrowheadClass trellis-arrowhead  \
	--subfeatureClasses '{"wholeCDS": null, "CDS":"brightgreen-80pct", "UTR": "darkgreen-60pct", "exon":"container-100pct"}' \
	--className container-16px --type mRNA --trackLabel maker --out $JBROWSE_DATA_DIR

$JBROWSE_DIR/bin/flatfile-to-json.pl --gff split_gff/blastn.gff   --arrowheadClass webapollo-arrowhead  \
	--subfeatureClasses '{"match_part": "darkblue-80pct"}' --type match \
	--className container-10px --trackLabel blastn --out $JBROWSE_DATA_DIR

$JBROWSE_DIR/bin/generate-names.pl --verbose --out $JBROWSE_DATA_DIR

mkdir $JBROWSE_DATA_DIR/bam

cp pyu_data/simulated-sorted.bam* $JBROWSE_DATA_DIR/bam

$JBROWSE_DIR/bin/add-bam-track.pl --bam_url bam/simulated-sorted.bam    --label simulated_bam --key "simulated BAM" -i $JBROWSE_DATA_DIR/trackList.json

mkdir $JBROWSE_DATA_DIR/bigwig
cp pyu_data/*.bw $JBROWSE_DATA_DIR/bigwig
$JBROWSE_DIR/bin/add-bw-track.pl --bw_url bigwig/simulated-sorted.coverage.bw --label simulated_bw --key "simulated BigWig" -i $JBROWSE_DATA_DIR/trackList.json
