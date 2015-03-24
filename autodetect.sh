#!/bin/bash

# Attempt to autodetect files in a folder and load them into WebApollo

process_file(){
	full_filename=$1
	base_filename=$(basename "$1")
	extension="${base_filename##*.}"
	filename="${base_filename%.*}"
	echo "Processing $filename.$extension";
	
	case $extension in
		fa)
			$WEBAPOLLO_ROOT/tools/user/extract_seqids_from_fasta.pl \
				-p Annotations- \
				-i $full_filename \
				-o /tmp/seqids.txt

			$WEBAPOLLO_ROOT/tools/user/add_tracks.pl \
				-H $DB_PORT_5432_TCP_ADDR \
				-D $WEBAPOLLO_DATABASE \
				-U $PGUSER \
				-P $PGPASSWORD \
				-t /tmp/seqids.txt

			$WEBAPOLLO_ROOT/tools/user/set_track_permissions.pl \
				-H $DB_PORT_5432_TCP_ADDR \
				-D $WEBAPOLLO_DATABASE \
				-U $PGUSER \
				-P $PGPASSWORD \
				-u $APOLLO_USERNAME \
				-t /tmp/seqids.txt \
				-a

			$JBROWSE_DIR/bin/prepare-refseqs.pl \
				--fasta $full_filename \
				--out $JBROWSE_DATA_DIR

			$WEBAPOLLO_ROOT/client/apollo/bin/add-webapollo-plugin.pl \
				-i $JBROWSE_DATA_DIR/trackList.json
		;;
		bam)
			echo "BAM File $full_filename"
			mkdir -p $JBROWSE_DATA_DIR/bam
			cp $full_filename $JBROWSE_DATA_DIR/bam
			cp ${full_filename}.bai $JBROWSE_DATA_DIR/bam
			# TODO: figure out a better way of handling this.
			$JBROWSE_DIR/bin/add-bam-track.pl \
				--bam_url bam/${base_filename} \
				--label "BAM_$filename" \
				--key "BAM $filename" \
				-i $JBROWSE_DATA_DIR/trackList.json
		;;
		bw)
			mkdir -p $JBROWSE_DATA_DIR/bigwig
			cp $full_filename $JBROWSE_DATA_DIR/bigwig
			$JBROWSE_DIR/bin/add-bw-track.pl \
				--bw_url bigwig/${base_filename} \
				--label "BigWig_$filename" \
				--key "BigWig $filename" \
				-i $JBROWSE_DATA_DIR/trackList.json
		;;
		gff)
			SPLITDIR=$(mktemp -d)
			$WEBAPOLLO_ROOT/tools/data/split_gff_by_source.pl \
				-i $full_filename -d $SPLITDIR

			echo ">> Split gff data"
			# TODO: better autodiscovery
			for splitfile in $SPLITDIR/*;
			do
				echo ">>>> GFF3 Parser: $splitfile"
				split_basename=$(basename $splitfile .gff)
				case $split_basename in
				blast*)
					echo ">>>> [blast]"
					$JBROWSE_DIR/bin/flatfile-to-json.pl \
						--gff $splitfile \
						--arrowheadClass webapollo-arrowhead  \
						--subfeatureClasses '{"match_part": "darkblue-80pct"}' \
						--type match_part \
						--className container-10px \
						--trackLabel $(basename $splitfile .gff)\
						--out $JBROWSE_DATA_DIR
				;;
				maker*)
					echo ">>>> [maker]"
					$JBROWSE_DIR/bin/flatfile-to-json.pl \
						--gff $splitfile \
						--arrowheadClass trellis-arrowhead \
						--subfeatureClasses '{"wholeCDS": null, "CDS":"brightgreen-80pct", "UTR": "darkgreen-60pct", "exon":"container-100pct"}' \
						--className container-16px \
						--type mRNA \
						--trackLabel $(basename $splitfile .gff) \
						--out $JBROWSE_DATA_DIR
				esac
			done
		;;
	esac
}

# http://stackoverflow.com/q/4321456
export -f process_file
# Must process fasta files before non-fasta files
find $1 -type f -name '*.fa' -exec bash -c 'process_file "$0"' {} \;
# TODO: sort data before processing
find $1 -type f \! -name '*.fa' -exec bash -c 'process_file "$0"' {} \;
