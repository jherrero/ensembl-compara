#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=pod 

=head1 NAME

Bio::EnsEMBL::Compara::RunnableDB::CreateDefaultPairwiseMlss

=cut

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

Create a list of method_link_species_set ids for the pairwise alignments of the 
low coverage genomes with the reference species in the pairwise_default_location
 database (usually the previous release). Stores the resulting list in the meta table

=cut

=head1 CONTACT

Describe contact details here

=cut

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

package Bio::EnsEMBL::Compara::RunnableDB::EpoLowCoverage::CreateDefaultPairwiseMlss;

use strict;

use base ('Bio::EnsEMBL::Compara::RunnableDB::BaseRunnable');


sub run {
  my $self = shift;

  $self->create_default_mlss();
}


sub create_default_mlss {
    my ($self) = @_;

    #Get all pairwise mlss for pairwise_url
    my $mlss_adaptor = $self->compara_dba->get_MethodLinkSpeciesSetAdaptor;
    my $low_mlss = $mlss_adaptor->fetch_by_dbID($self->param('new_method_link_species_set_id'));
    my $species_set = $low_mlss->species_set;

    my $pairwise_dba = Bio::EnsEMBL::Compara::DBSQL::DBAdaptor->new( -url => $self->param('pairwise_default_location') );
    my $pairwise_genome_db_adaptor = $pairwise_dba->get_GenomeDBAdaptor;
    my $pairwise_mlss_adaptor = $pairwise_dba->get_MethodLinkSpeciesSetAdaptor;

    my $base_dba = Bio::EnsEMBL::Compara::DBSQL::DBAdaptor->new( -url => $self->param('base_location') );
    my $base_mlss_adaptor = $base_dba->get_MethodLinkSpeciesSetAdaptor;
    my $base_mlss = $base_mlss_adaptor->fetch_by_dbID($self->param('base_method_link_species_set_id'));

    my $ref_genome_db;
    my $pairwise_mlsss;

    #Find the genome_db for the reference species
    my $low_coverage_species_set;
    my %all_species_set;
    foreach my $genome_db (@$species_set) {
	if ($genome_db->name eq $self->param('reference_species')) {
	    $ref_genome_db = $genome_db;
	}
	$all_species_set{$genome_db->dbID} = 1;
    }
    if (!defined $ref_genome_db) {
        die( "Unable to find reference species" );
    }

    #Find only low coverage species by removing the high coverage ones from the list of all of them
    foreach my $high_species (@{$base_mlss->species_set}) {
	$all_species_set{$high_species->dbID} = 2;
    }
    foreach my $genome_db_id (keys %all_species_set) {
	if ($all_species_set{$genome_db_id} == 1) {
	    push @$low_coverage_species_set, $genome_db_id;
	}
    }
    foreach my $genome_db_id (@$low_coverage_species_set) {
	if ($genome_db_id ne $ref_genome_db->dbID) {
	    my $pairwise_mlss;
	    $pairwise_mlss = $pairwise_mlss_adaptor->fetch_by_method_link_type_genome_db_ids("BLASTZ_NET", [$genome_db_id, $ref_genome_db->dbID]);
	    if (!defined $pairwise_mlss) {
		#Try lastz
		$pairwise_mlss = $pairwise_mlss_adaptor->fetch_by_method_link_type_genome_db_ids("LASTZ_NET", [$genome_db_id, $ref_genome_db->dbID]);
		if ($pairwise_mlss) {
		    print "LASTZ found mlss " . $pairwise_mlss->dbID . "\n" if ($self->debug);
		    $pairwise_mlsss->{$genome_db_id} = $pairwise_mlss;
		}
	    } else {
		print "BLASTZ found mlss " . $pairwise_mlss->dbID . "\n" if ($self->debug);
		$pairwise_mlsss->{$genome_db_id} = $pairwise_mlss;
	    }
	}
    }

    my $default_mlss = "(";
    foreach my $genome_db_id (keys %$pairwise_mlsss) {
	if (defined $pairwise_mlsss->{$genome_db_id}) {
	    my $name = $pairwise_genome_db_adaptor->fetch_by_dbID($genome_db_id)->name;
	    print "mlss $name $genome_db_id ". $pairwise_mlsss->{$genome_db_id}->dbID . "\n" if ($self->debug);
	    my $mlss_id = $pairwise_mlsss->{$genome_db_id}->dbID;
	    $default_mlss .= $mlss_id . ",";
	} else {
	    print "Unable to find mlss for $genome_db_id\n" if ($self->debug);
	}
    }
    $default_mlss .= ")";

    #Store in meta table
    $self->dataflow_output_id({'meta_key' => 'pairwise_default_mlss',
			       'meta_value' => $default_mlss}, 3);
}

1;
