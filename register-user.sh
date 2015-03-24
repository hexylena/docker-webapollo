. /bin/common.sh

export PERL5LIB=/webapollo/jbrowse-download/src/perl5
for i in /data/*.fa;
do
    $WEBAPOLLO_ROOT/tools/user/extract_seqids_from_fasta.pl \
        -p Annotations- \
        -i $i \
        -o /tmp/seqids.txt
    $WEBAPOLLO_ROOT/tools/user/add_user.pl \
        -D $WEBAPOLLO_DATABASE \
        -U $PGUSER \
        -P $PGPASSWORD \
        -u $1 \
        -p $APOLLO_PASSWORD \
        -H $DB_PORT_5432_TCP_ADDR
    perl $WEBAPOLLO_ROOT/tools/user/set_track_permissions.pl \
        -H $DB_PORT_5432_TCP_ADDR \
        -D $WEBAPOLLO_DATABASE \
        -U $PGUSER \
        -P $PGPASSWORD \
        -u $1 \
        -t /tmp/seqids.txt \
        -a
done
